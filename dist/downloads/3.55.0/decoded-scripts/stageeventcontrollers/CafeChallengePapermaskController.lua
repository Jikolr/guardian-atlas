local local_class = newclass('CafeChallengePapermaskController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.progress = {
		none = 0,
		wave_1 = 1,
		wave_2 = 2,
		wave_3 = 3,
		wave_4 = 4,
		wave_5 = 5,
		cleared = 6
	}

	self.current_progress = self.progress.none

	-- npc 이름
	self.spawn_mob_name_prefix = 'faker_'
	self.paper_name = 'paper'
	self.succubus_name = 'succubus_'
	self.succubus_paper_name = 'succubus_paper'

	-- 마커 이름
	self.spawn_marker_prefix = 'spawn_point_'

	-- 이펙트 이름
	self.destroy_effect_name = 'FX_dead'
	self.hit_effect_name = 'FX_hit'
	self.reset_effect_name = 'FX_reset_object'

	-- 기믹 이름
	self.door_name = 'cafe_door'
	self.battle_gate_name = 'battlegate_'

	-- faker 스폰 수
	self.faker_spawn_count = { 3, 6, 9, 9, 9 }

	-- succubus 스폰 수
	self.succubus_spawn_count = { 1, 3, 5, 5, 5 }

	-- 미션이 끝났는지
	self.mission_end = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource(
		self.reset_effect_name,
		self.destroy_effect_name,
		self.hit_effect_name
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	for i = 1, self.faker_spawn_count[5] do
		character_util.remove_relate_event(get_character(self.spawn_mob_name_prefix .. i), self.cs_controller)
	end

	character_util.remove_relate_event(get_character(self.paper_name), self.cs_controller)

	self.cs_controller = nil
end

function local_class:on_stage_loaded_event(_)
	-- 퀘스트 마커 표시
	ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(-4, 0, 24.5))

	-- 서큐버스 충돌 제거
	for i = 1, self.succubus_spawn_count[5] do
		local succubus = get_character(self.succubus_name .. i)
		succubus.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	local succubus_paper = get_character(self.succubus_paper_name)
	succubus_paper.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	return true
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, 'mini_game_trigger') then
		if self.current_progress == self.progress.none then
			self.current_progress = self.current_progress + 1
			sp_util.play_normal_screenplay(self.start_mini_game, self)
			return true
		end
	end

	return false
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local paper = get_character(self.paper_name)
		if type_util.is_interacted_target(e, paper) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.paper_touch, self))
			return true
		end

		if string.find(e.Target.Transform.name, self.spawn_mob_name_prefix) ~= nil then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.faker_touch, self, e.Target))
			return true
		end
	end
	return false
end

function local_class:on_global_timer_alarm_event(e)
	if e.IsComplete and not self.mission_end then
		self.mission_end = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			party_util.stop_and_disable_control()
			field_ui_manager:Hide()

			self:end_timer()

			self.end_pattern = true

			camera_util.return_to_leader(0.5)

			self:game_over(true)
		end))
		return true
	end

	return false
end

-- 미니게임 시작
function local_class:start_mini_game()
	-- 퀘스트 마커 제거
	ui_quest_marker:RemoveQuestMarker('game_start')

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	character_util.remove_anim_and_emotion(user_party.Leader)

	local game_position = stage.Field:GetMarker('mini_game_start').position

	-- 파티원들 제외
	for i = user_party.Count - 1, 1, -1 do
		local member = user_party[i]
		character_util.convert_to_npc(member)
		member.ActiveState = active_state('disabled')
	end

	-- 리더 위치 변경
	character_util.set_position(user_party.Leader, game_position)
	character_util.set_direction(user_party.Leader, 'left')

	-- 미니게임 게이트 닫기
	for i = 1, 2 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('battlegate_' .. i))
	end

	self:wave_spawn_mob()

	wait_for_sec(0.5)

	-- bgm_transition: Field(ondemand/cafe/audio:bgm_world_map_06) -> Event(bgm_trickery_theme)
	music_player_util.play_stage_music({ name = 'bgm_trickery_theme', state = 'event' })

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	music_player:PlaySfxOneShot('01_stage_intro_jump_01')

	character_util.set_anim(user_party.Leader, { name = 'victory_get', loop = false })
	wait_for_sec(1.5)

	character_util.remove_anim(user_party.Leader)

	self:start_timer()
end

-- 현재 웨이브 몹 생성 및 이전 웨이브 몹 제거
function local_class:wave_spawn_mob()
	local current_wave = self.current_progress
	local previous_wave = self.current_progress - 1

	-- 서큐버스 제외 faker + paper
	local only_mobs = {}

	-- 현재 웨이브에서 생성할 몹들
	local current_mobs = {}
	for i = 1, self.faker_spawn_count[current_wave] do
		local current_mob = get_character(self.spawn_mob_name_prefix .. i)
		character_util.add_listener(current_mob, self.cs_controller)
		table.insert(current_mobs, current_mob)
		table.insert(only_mobs, current_mob)
	end

	-- 랜덤 위치에 서큐버스 추가
	for i = 1, self.succubus_spawn_count[current_wave] do
		local succubus_index = random_util.get_random_int(1, #current_mobs + 1)
		local succubus = get_character(self.succubus_name .. i)
		table.insert(current_mobs, succubus_index, succubus)
	end

	-- 랜덤 위치에 paper 추가
	local paper_index = random_util.get_random_int(1, #current_mobs + 1)
	local paper = get_character(self.paper_name)
	character_util.add_listener(paper, self.cs_controller)
	table.insert(current_mobs, paper_index, paper)
	table.insert(only_mobs, paper)

	local succubus_paper = get_character(self.succubus_paper_name)

	-- 이전 웨이브 몹들 제거
	if current_wave ~= 1 then
		music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
		music_player:PlaySfxOneShot('01_guild_warp_01')

		for i = 1, self.faker_spawn_count[previous_wave] do
			local previous_mob = get_character(self.spawn_mob_name_prefix .. i)
			unity_object_pool.GetOrCreate(self.destroy_effect_name):Instantiate(previous_mob.Position)
		end

		for i = 1, self.succubus_spawn_count[previous_wave] do
			local previous_succubus = get_character(self.succubus_name .. i)
			unity_object_pool.GetOrCreate(self.destroy_effect_name):Instantiate(previous_succubus.Position)
		end

		unity_object_pool.GetOrCreate(self.reset_effect_name):Instantiate(paper.Position)
		unity_object_pool.GetOrCreate(self.destroy_effect_name):Instantiate(succubus_paper.Position)
	end

	-- 현재 웨이브 몹들 생성
	for k, current_mob in pairs(current_mobs) do
		local current_mob_pos = field:GetMarker(self.spawn_marker_prefix .. current_wave .. '_' .. k).position
		current_mob.Position = current_mob_pos
		unity_object_pool.GetOrCreate(self.reset_effect_name):Instantiate(current_mob.Position)
	end

	succubus_paper.Position = paper.Position + 1.5 * unity_class.vector3.right
	unity_object_pool.GetOrCreate(self.reset_effect_name):Instantiate(succubus_paper.Position)

	-- 4웨이브 패턴
	if current_wave == 4 then
		self.end_pattern = false

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			while not self.end_pattern do
				wait_for_sec(1)

				if self.end_pattern then
					return
				end

				for _, only_mob in pairs(only_mobs) do
					character_util.set_direction(only_mob, 'up')
				end

				wait_for_sec(3)

				if self.end_pattern then
					return
				end

				for _, only_mob in pairs(only_mobs) do
					character_util.set_direction(only_mob, 'down')
				end
			end
		end))
	end

	-- 5웨이브 패턴
	if current_wave == 5 then
		for _, only_mob in pairs(only_mobs) do
			character_util.set_direction(only_mob, 'up')
		end
	end
end

-- 정답을 건드렸을 때
function local_class:paper_touch()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local paper = get_character(self.paper_name)
	character_util.remove_relate_event(paper, self.cs_controller)

	for i = 1, self.faker_spawn_count[self.current_progress] do
		local mob = get_character(self.spawn_mob_name_prefix .. i)
		character_util.remove_relate_event(mob, self.cs_controller)
	end

	self.current_progress = self.current_progress + 1

	self:touch_npc(paper, true)

	-- 미션 성공했을 때 (최종 웨이브까지 성공)
	if self.current_progress == self.progress.cleared then
		-- bgm_transition: Event(bgm_trickery_theme) -> Field(ondemand/cafe/audio:bgm_world_map_06)
		music_player_util.play_stage_music({ state = 'field', mix = 2 })

		for i = 1, self.faker_spawn_count[self.current_progress - 1] do
			local mob = get_character(self.spawn_mob_name_prefix .. i)
			unity_object_pool.GetOrCreate(self.destroy_effect_name):Instantiate(mob.Position)
			character_util.set_active_state(mob, 'disabled')
		end

		-- 문 열림
		local door = get_field_object(self.door_name)
		camera_util.move_async(door.Bounds.center, 1)

		music_player:PlaySfxOneShot('03_gimmick_jingle_01')
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name, false))

		-- 배틀게이트 열림
		for i = 1, 2 do
			message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.battle_gate_name .. i))
		end

		wait_for_sec(2.5)

		camera_util.return_to_leader(1)

		field_ui_manager:Show()
		party_util.reset_controllers()

		return
	end

	character_util.set_direction(paper, 'down')
	character_util.remove_anim(paper)

	self:wave_spawn_mob()

	self.mission_end = false
	self:start_timer()

	character_util.add_listener(paper, self.cs_controller)
end

-- 실패를 건드렸을 때
function local_class:faker_touch(target)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local paper = get_character(self.paper_name)
	character_util.remove_relate_event(target, self.cs_controller)

	self:touch_npc(target, false)

	camera_util.move_async(paper.Position, 1)

	music_player:PlaySfxOneShot('01_ghost_laugh_evil_01')
	character_util.set_direction(paper, 'down')
	character_util.set_anim(paper, { name = 'success', sfx_name = '01_player_jump_01' })
	wait_for_sec(2)

	camera_util.return_to_leader(1)

	character_util.remove_anim(paper)

	self:game_over(false)
end

-- npc 건드렸을 때 발생하는 공용 연출
function local_class:touch_npc(target, success)
	self.mission_end = true

	self:end_timer()

	self.end_pattern = true

	camera_util.shake(0.2, 0.4)

	unity_object_pool.GetOrCreate(self.hit_effect_name):Instantiate(target.Position)

	character_util.spine_damage_squish_default(target)
	character_util.spine_damage_red_pulse(target)

	character_util.set_direction(target, 'right')
	character_util.set_anim(target, { name = 'frustration', loop = false })
	character_util.set_animation_n_times(user_party_leader, { name = 'attack' })
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('02_hit_big_01')
	wait_for_sec(0.6)

	music_player:PlaySfxOneShot('01_hit_npc_01')

	if success and self.current_progress ~= self.progress.cleared then
		field_ui_manager:Show()
		party_util.reset_controllers()
	end

	wait_for_sec(1)
end

-- 타이머 시작
function local_class:start_timer()
	music_player:PlaySfxOneShot('02_gimmick_ticking_01')

	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.EventTimer)

	local game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, 6, nil)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, game_timer))
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_global_timer_alarm_event')
	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, true))
end

-- 타이머 종료
function local_class:end_timer()
	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)
end

-- 게임 오버 연출
function local_class:game_over(time_over)
	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, time_over)
	message_system:Publish(CS.Oak.GameOverEvent.Instance)

	music_player:PlaySfxOneShot('01_drown_01')

	character_util.set_direction(user_party_leader, direction_util.to_side_dir(user_party_leader.Direction))
	character_util.set_emotion(user_party_leader, { name = 'damaged' })
	character_util.set_anim(user_party_leader, { name = 'frustration', loop = false, scale = 0.4 })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
