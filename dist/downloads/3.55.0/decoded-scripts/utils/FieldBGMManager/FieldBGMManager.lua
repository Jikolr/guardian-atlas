local local_class = newclass('FieldBGMManager')

function local_class:init()
	-- 이 스테이지에 대한 데이터가 없더라도 이 유틸은 동작해야하기 때문에, 없으면 빈 테이블을 하나 만들어줌
	self.legacy_stage_data = get_or_create_global_variable('utils/FieldBGMManager/FieldBGMLegacyStage')

	local contain_value = table_util.contain_value(self.legacy_stage_data, stage.Name)

	-- contain_value는 레가시 데이터 인지 체크 유무
	local constants_data = self:get_bgm_data(contain_value)

	-- 이 스테이지에 대한 데이터가 없더라도 이 유틸은 동작해야하기 때문에, 없으면 빈 테이블을 하나 만들어줌
	self.constants = self:build_to_usable_constants(constants_data[stage.Name] or {})

	-- bgm 변경 요청이 들어 왔는지
	self.has_new_bgm_change_request = false

	-- 변경 요청된 bgm data
	self.request_bgm_data = nil

	-- 현재 플레이어가 속해 있는 존 // zone에서 나갈 경우에는 확인 할수 없으니 nil 처리
	self.current_zone_name = nil

	-- bgm 변경 코루틴은 요청만 계속 받을 뿐 한번만 돌도록 처리
	self.is_changed_bgm_unique_logic = false

	self.sfx_data = {
		play_sfx_table = {},

		create_sfx = function(this, arg, mix_duration, volume)
			local sfx_table = {}

			if type_util.is_string(arg) then
				table.insert(sfx_table, arg)
			else
				sfx_table = arg
			end

			if table_util.is_empty(sfx_table) then
				return false
			end

			for _, sfx_name in ipairs(sfx_table) do
				local sfx = music_player_util.play_sfx({
					sfx_name = sfx_name,
					loop = true,
					type_priority = 'event',
					fade_in_time = mix_duration,
					volume = volume
				})

				table.insert(this.play_sfx_table, sfx)
			end
		end,

		fade_out = function(this, mix_duration)
			if not table_util.is_empty(this.play_sfx_table) then
				for _, sfx in ipairs(this.play_sfx_table) do
					sfx:FadeOut(mix_duration)
					sfx = nil
				end
			end
		end,

		dispose = function(this)
			if not table_util.is_empty(this.play_sfx_table) then
				for _, sfx in ipairs(this.play_sfx_table) do
					sfx:Stop()
					sfx = nil
				end
			end
		end
	}

	self.state = {
		initialize = 1,
		wait = 2,
		in_progress = 3,
		progress_zone_enter = 4,
		progress_zone_leave = 5
	}

	self.before_battle_state = nil

	self.current_state = self.state.initialize

	-- 사용할 때에만 ZoneEnterEvent를 구독해둬야 하지만, 동프레임 구독/구독해제 순서가 무시되는 고질적인 문제로 일단 패스
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	--스테이지에서 사용될 BGM 프리로드
	self:preload_music_clip_table()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self.sfx_data:dispose()

	self:dispose_music_clip_table()

	self.constants = nil
end

function local_class:on_zone_enter_event(e)
	if self.constants[e.Zone.Name] == nil or not type_util.is_zone_full_enter(e, get_party_leader(), e.Zone.Name) then
		return false
	end

	if self:check_is_changed_bgm(e.Zone.Name, self.constants[e.Zone.Name].zone_data.zone_in_quest_data) then

		self.current_zone_name = e.Zone.Name

		self.current_state = self.state.progress_zone_enter

		self:changed_bgm_data(self.constants[e.Zone.Name])
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.constants[e.Zone.Name] == nil or not type_util.is_zone_full_leave(e, get_party_leader(), e.Zone.Name) then
		return false
	end

	self.current_zone_name = nil

	if self:check_is_changed_bgm(e.Zone.Name, self.constants[e.Zone.Name].zone_out_quest_data) and
			self.constants[e.Zone.Name].zone_data.zone_out_bgm_name ~= nil then

		self.current_state = self.state.progress_zone_leave

		self:changed_bgm_data(self.constants[e.Zone.Name])
	end

	return false
end

function local_class:on_stage_end_event(e)
	self:stop_bgm_manager()
end

function local_class:on_battle_end_event(e)
	if self.before_battle_state ~= nil then
		self.current_state = self.before_battle_state
		self.before_battle_state = nil
	end
end

function local_class:on_battle_start_event(e)
	if self.current_state ~= self.state.wait then
		self.before_battle_state = self.current_state
		self.current_state = self.state.wait
	end
end

function local_class:change_stage_bgm_clip(bgm_data)
	self.request_bgm_data = bgm_data

	local clip_name = nil

	if self.current_state == self.state.progress_zone_leave then
		clip_name = bgm_data.zone_data.zone_out_bgm_name
	else
		clip_name = bgm_data.zone_data.zone_in_bgm_name
	end

	if clip_name == nil or not type_util.is_string(clip_name) then
		clip_name = music_player.CurrentStageMusicName
	end

	if music_player.StageBgmState ~= stage_bgm_state.muted and
			music_player.CurrentStageMusicName ~= clip_name then
		music_player_util.change_stage_music_volume(bgm_data.state, 0, bgm_data.mix_duration)
	end

	self.sfx_data:fade_out(bgm_data.mix_duration)

	self.has_new_bgm_change_request = true

	local time_passed = 0

	while time_passed < bgm_data.mix_duration and self.current_state ~= self.state.wait do
		if self.has_new_bgm_change_request then
			time_passed = 0
			bgm_data = self.request_bgm_data
			self.has_new_bgm_change_request = false
		end

		time_passed = time_passed + unity_class.time.unscaledDeltaTime
		coroutine.yield()
	end

	if self.current_state == self.state.wait then
		music_player_util.change_stage_music_volume('field', 1, bgm_data.mix_duration)
		return
	end

	bgm_data = self.request_bgm_data
	local is_sfx = false

	if self.current_state == self.state.progress_zone_leave then
		if bgm_data.zone_data.zone_out_type == 'sfx' then
			is_sfx = true
		end

		clip_name = bgm_data.zone_data.zone_out_bgm_name
	else
		if bgm_data.zone_data.zone_in_type == 'sfx' then
			is_sfx = true
		end

		clip_name = bgm_data.zone_data.zone_in_bgm_name
	end

	music_player_util.play_stage_music({ state = 'muted', mix = 0 })

	if is_sfx then
		self.sfx_data:create_sfx(clip_name, bgm_data.mix_duration, bgm_data.volume)
		return
	end

	-- 클립 이름이 muted면 세팅 안함
	if clip_name == 'muted' then
		return
	end

	if clip_name == nil or not type_util.is_string(clip_name) then
		clip_name = music_player.CurrentStageMusicName
	end

	if music_player.CurrentStageMusicName ~= clip_name then
		music_player_util.play_stage_music({ state = bgm_data.state, name = clip_name, mix = 0, volume = 0 })
		coroutine.yield(nil)
		coroutine.yield(nil)
		coroutine.yield(nil)
	end

	music_player_util.change_stage_music_volume(bgm_data.state, bgm_data.volume, bgm_data.mix_duration)
end

function local_class:build_to_usable_constants(constants)
	local data_table = {}

	for zone_name, data in pairs(constants) do
		data_table[zone_name] = {
			zone_data = {},
			state = data.state,
			mix_duration = data.mix_duration,
			volume = data.volume,
		}

		local zone_in_type = 'bgm'
		local zone_out_type = 'bgm'
		local zone_in_bgm_name
		local zone_out_bgm_name
		local zone_in_quest_data
		local zone_out_quest_data

		for _, target_data in pairs(data.zone_data) do
			zone_in_type = lua_helper.get_or_default(target_data.zone_in_type, zone_in_type)
			zone_out_type = lua_helper.get_or_default(target_data.zone_out_type, zone_out_type)
			zone_in_bgm_name = lua_helper.get_or_default(target_data.zone_in_bgm_name, zone_in_bgm_name)
			zone_out_bgm_name = lua_helper.get_or_default(target_data.zone_out_bgm_name, zone_out_bgm_name)
			zone_in_quest_data = lua_helper.get_or_default(target_data.zone_in_quest_data, zone_in_quest_data)
			zone_out_quest_data = lua_helper.get_or_default(target_data.zone_out_quest_data, zone_out_quest_data)
		end

		local result = {
			zone_in_type = zone_in_type,
			zone_out_type = zone_out_type,
			zone_in_bgm_name = zone_in_bgm_name,
			zone_out_bgm_name = zone_out_bgm_name,
			zone_in_quest_data = zone_in_quest_data,
			zone_out_quest_data = zone_out_quest_data
		}

		data_table[zone_name].zone_data = result
	end

	return data_table
end

function local_class:check_is_changed_bgm(zone_name, quest_data)
	local is_not_same_zone = self.current_zone_name ~= zone_name
	local is_new_request = not self.has_new_bgm_change_request
	local is_progress_bgm_manager = not (self.current_state < self.state.in_progress)

	if quest_data ~= nil and table_util.get_size(quest_data) > 0 then
		local quest_progress = user_progress:GetStartedQuest(quest_data.quest_id)
		local is_after_section = true

		if quest_data.is_before_progress then
			is_after_section = quest_progress.InnerProgress < quest_data.progress and true or false
		else
			is_after_section = quest_progress.InnerProgress >= quest_data.progress and true or false
		end

		return (is_not_same_zone and is_new_request and is_progress_bgm_manager and is_after_section)
	end

	return (is_not_same_zone and is_new_request and is_progress_bgm_manager)
end

function local_class:get_default_bgm_data(bgm_data)
	local data = {}

	local default_bgm = music_player.CurrentStageMusicName

	data = {
		zone_data = {
			zone_in_type = lua_helper.get_or_default(bgm_data.zone_data.zone_in_type, 'bgm'),
			zone_out_type = lua_helper.get_or_default(bgm_data.zone_data.zone_out_type, 'bgm'),
			zone_in_bgm_name = lua_helper.get_or_default(bgm_data.zone_data.zone_in_bgm_name, default_bgm),
			zone_out_bgm_name = lua_helper.get_or_default(bgm_data.zone_data.zone_out_bgm_name, default_bgm),
		},
		state = lua_helper.get_or_default(bgm_data.state, 'field'),
		mix_duration = lua_helper.get_or_default(bgm_data.mix_duration, 0.75),
		volume = lua_helper.get_or_default(bgm_data.volume, 1),
	}

	return data
end

function local_class:changed_bgm_data(constants)
	if self.is_changed_bgm_unique_logic then
		--코루틴이 돌아가고 있을 때는 데이터만 갱신

		self.request_bgm_data = self:get_default_bgm_data(constants)
	else
		local bgm_data = self:get_default_bgm_data(constants)
		local clip_name = self.current_state == self.state.progress_zone_leave and
				bgm_data.zone_data.zone_out_bgm_name or bgm_data.zone_data.zone_in_bgm_name

		-- 같은 클립이면 굳이 교체해줄 필요 없음
		if music_player.CurrentStageMusicName == clip_name then
			return
		end

		self.is_changed_bgm_unique_logic = true

		start_coroutine(function()
			yield_return_func(self.change_stage_bgm_clip, self, bgm_data)

			self.is_changed_bgm_unique_logic = false
			self.has_new_bgm_change_request = false
			self.current_state = self.state.in_progress
		end)
	end
end

function local_class:check_contains_zone()
	for zone_name, valve in pairs(self.constants) do
		if zone_util.contains_fo(zone_name, get_party_leader(), true) then
			if self:check_is_changed_bgm(zone_name, self.constants[zone_name].zone_in_quest_data) then
				self.current_zone_name = zone_name

				self.current_state = self.state.progress_zone_enter

				self:changed_bgm_data(self.constants[zone_name])
			end

			return true
		end
	end

	return false
end

function local_class:start_bgm_manager()
	if self.current_state < self.state.in_progress then
		self.current_state = self.state.in_progress
	end

	--bgm 시작시 플레이어 위치에 변경되어야하는 존이 있을 경우 바뀌도록 수정
	--두개의 존이 겹쳐있을 경우 constants에 세팅되어있는 존 리스트에서 먼저 설정되있는 것이 우선순위가 높도록 설정
	self:check_contains_zone()
end

function local_class:stop_bgm_manager()
	if self.current_state ~= self.state.wait then
		self.current_state = self.state.wait

		self.sfx_data:dispose()
	end
end

function local_class:preload_music_clip_table()
	if not table_util.is_empty(self.constants) then
		for _, zone_data_name in pairs(self.constants) do
			if type_util.is_string(zone_data_name.zone_data.zone_in_bgm_name) then
				music_player:PreloadMusic(zone_data_name.zone_data.zone_in_bgm_name)
			end

			if type_util.is_string(zone_data_name.zone_data.zone_out_bgm_name) then
				music_player:PreloadMusic(zone_data_name.zone_data.zone_out_bgm_name)
			end
		end
	end
end

function local_class:dispose_music_clip_table()
	if not table_util.is_empty(self.constants) then
		music_player:ClearAudioSystem()
	end
end

function local_class:get_bgm_data(contain_value)
	local data_path
	local bgm_data

	-- contain_value 가 true이면 레가시 데이터 이므로 이전 Constant 데이터
	if contain_value then
		data_path = 'utils/FieldBGMManager/FieldBGMManagerConstants'
	else
		local chapter_code = stage.Spec.ChapterCode.Value

		-- 새로 만들어진 데이터 경로
		data_path = 'utils/FieldBGMManager/FieldBGM'..chapter_code
	end

	bgm_data = get_or_create_global_variable(data_path)

	return bgm_data
end

return {
	create = function()
		return local_class()
	end
}
