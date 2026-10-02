local local_class = newclass("DemonWorldBgmSystemController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.bgm_swap_zone_name = {
		'underpass_bgm_zone', -- 지하도
		'store_bgm_zone', -- 편의점
		'restaurant_bgm_zone', -- 셔큐버스 바
	}

	self.party_in_bgm_zone = false

	self.bgm_names = {
		main_field = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_main', -- 메인 field
		underpass = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_event_7', -- 지하도
		store = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_store', -- 편의점
		restaurant = 'bgm_restaurant', -- 서큐버스 바
	}
	self.underpass_intro_sfx_name = '01_intro_shivermore_01'

	-- 진입 시 특수 효과음 처리용
	self.field_zone_sfx_name = nil
	self.field_zone_sfx_volume = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	-- 해당 스테이지 기본 BGM으로 갱신
	self.bgm_names.main_field = music_player.StageFieldMusicName

	-- 지하도에서 시작일 경우
	local underpass_zone = field:GetZone(self.bgm_swap_zone_name[1])
	if underpass_zone ~= nil and underpass_zone:Contains(user_party.Leader.Position) then
		self.party_in_bgm_zone = true
		music_player.StageIntroSfxHandleName = self.underpass_intro_sfx_name
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				music_player_util.set_stage_music_clip_async, {state = 'field', name = self.bgm_names.underpass}))
	end

	-- 특수 스테이지 일반 field 진입 시 처리용
	if stage.Name == 'demonworld_part1_1_4' then
		self.field_zone_sfx_name = '01_bugs_oneshot_01'
		self.field_zone_sfx_volume = 0.5
	end

	return false
end

function local_class:on_zone_enter_event(e)
	for i = 1, #self.bgm_swap_zone_name do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.bgm_swap_zone_name[i]) then
			if self.party_in_bgm_zone == false then
				self.party_in_bgm_zone = true

				if self.bgm_swap_zone_name[i] == 'underpass_bgm_zone' then
					self:swap_bgm(self.bgm_names.underpass)
				elseif self.bgm_swap_zone_name[i] == 'store_bgm_zone' then
					self:swap_bgm(self.bgm_names.store)
					music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
				elseif self.bgm_swap_zone_name[i] == 'restaurant_bgm_zone' then
					self:swap_bgm(self.bgm_names.restaurant)
				end
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	for i = 1, #self.bgm_swap_zone_name do
		if type_util.is_zone_full_leave(e, user_party.Leader, self.bgm_swap_zone_name[i]) then
			if self.party_in_bgm_zone == true then
				self.party_in_bgm_zone = false

				if self.field_zone_sfx_name ~= nil then
					music_player_util.play_sfx(
							{ sfx_name = self.field_zone_sfx_name, volume = self.field_zone_sfx_volume })
				end

				-- 현재는 BGM 변경 구역 간에 이동처리가 안되어있음
				self:swap_bgm(self.bgm_names.main_field)

				return true
			end
		end
	end
	return false
end

function local_class:swap_bgm(next_bgm_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.swap_bgm_routine, self, next_bgm_name))
end

function local_class:swap_bgm_routine(next_bgm_name)
	local is_field_state = music_player.StageBgmState == CS.Oak.StageBgmState.Field

	music_player_util.play_stage_music({state = 'event', name = next_bgm_name, mix = 1})

	-- Field에서 Event로 전환되는 경우 바로 Field의 클립을 바꾸면 Mix가 제대로 동작하지 않음.
	-- 따라서 해당 경우에 Fade가 끝난 이후에 동작하도록 변경
	if is_field_state then
		wait_for_sec(1)
	end

	music_player_util.set_stage_music_clip_async({state = 'field', name = next_bgm_name})
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
