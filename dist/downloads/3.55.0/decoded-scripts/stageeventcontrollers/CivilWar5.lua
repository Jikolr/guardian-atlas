local local_class = newclass('CivilWar5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	-- zone event용
	self.guard_event_check = false
	self.guard_event_string_key = 'cw_main_s23_guard_oneline_1'
	self.guard_zone_name = 'center_out_zone'
	self.get_guard_npc = function(number)
		return get_character('war_zone_guard_' .. number)
	end

	-- 사울 가드용
	self.saul_guards = nil
	self.is_detected = false
	self.detected_by_guard_key = 'detected_by_guard'

	-- light
	self.get_tent_light = function()
		return get_field_object('directional_light_tent_in')
	end

	self.get_forest_light = function()
		return get_field_object('directional_light_forest')
	end

	-- buzz sound 용
	self.can_play_sfx = true
	self.crowd_buzz_sfx = nil

	--region 배경 스크롤링

	---@type CivilWarCustomBackgroundController
	self.background_controller = nil

	self.get_background_scrolling_flower_center_cam_x = function()
		return field_util.get_marker_pos('custom_background_scrolling_flower_center_cam_x').x
	end

	self.background_scrolling_border_yz = {}

	self.black_flower_state = 'close'

	--endregion
end

function local_class:load_resource()
	self.util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')

	self:set_telescope()

	self.saul_guards = {
		get_character('saul_guard_1'),
		get_character('saul_guard_2'),
		get_character('saul_guard_3'),
		get_character('saul_guard_4'),
		get_character('saul_guard_5'),
		get_character('saul_guard_6'),
		get_character('saul_guard_7'),
		get_character('saul_star_piece_guard'),
		get_character('saul_guard_11'),
		get_character('saul_guard_12'),
		get_character('saul_guard_key_hold'),
	}

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	self:light_on_off_check(e)

	if self.guard_event_check and
			type_util.is_zone_full_enter(e, get_party_leader(), self.guard_zone_name) then
		self.util:start_scene(self.war_zone_guard_event, self, e.Zone)

		return true
	end

	if self.can_play_sfx and
			type_util.is_zone_full_enter(e, get_party_leader(), 'crowd_buzz_sound_zone') then
		self:crowd_buzz_sfx_play()

		return true
	end

	if self.background_controller ~= nil and
			e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader()) and
			self.background_scrolling_border_yz[e.Zone.Name] ~= nil then

		self.background_controller:request_activate(e.Zone.Name,
				self.background_scrolling_border_yz[e.Zone.Name],
				self.get_background_scrolling_flower_center_cam_x(),
				self.black_flower_state)

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.can_play_sfx and
			type_util.is_zone_full_leave(e, get_party_leader(), 'crowd_buzz_sound_zone') then
		self:crowd_buzz_sfx_stop()

		return true
	end

	if self.background_controller ~= nil and
			e.FullLeave and lua_helper.reference_equals(e.FieldObject, get_party_leader()) and
			self.background_scrolling_border_yz[e.Zone.Name] ~= nil then

		self.background_controller:request_deactivate(e.Zone.Name)

		return true
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id and e.CurrentProgress == 24 then
		self.can_play_sfx = false
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params[0] == self.detected_by_guard_key and not self.is_detected then
		self.is_detected = true
		start_coroutine(self.player_detected_by_guard_event, self, e.Sender)
		return true
	end

	return false
end

function local_class:on_battle_start_event(e)
	self:battle_start_guard_setting()
	return true
end

function local_class:on_battle_end_event(e)
	start_coroutine(self.battle_end_guard_setting, self)
	return true
end
--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.Last
end

function local_class:late_update_frame(dt)
	if self.background_controller ~= nil then
		self.background_controller:update_background()
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	if self.crowd_buzz_sfx ~= nil then
		self.crowd_buzz_sfx:Stop()
		self.crowd_buzz_sfx = nil
	end

	self.saul_guards = nil

	self.util = nil

	self.background_controller = nil
	self.background_scrolling_border_yz = nil

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.background_controller = get_or_create_global_table(
			'Quest/Main/CivilWar/Common/CustomBackgroundController'
	)

	self.background_controller:request_turn_on()

	self.background_scrolling_border_yz = {
		custom_background_scrolling_region = field_util.get_marker_pos(
				'custom_background_scrolling_border_yz'
		),
	}

	if quest_progress ~= nil and (quest_progress.IsComplete or quest_progress.InnerProgress > 26) then
		self.black_flower_state = 'open'
	end

	-- 문지기 npc 세팅
	self:guard_event_setting(quest_progress)

	-- 사운드 구역 세팅
	self:crowd_buzz_sfx_setting(quest_progress)

	-- 마나 캐논 세팅
	self:setting_mana_cannon(quest_progress)

	-- Key door 스타피스 세팅
	if not stage_progress_util.has_star_piece('key_door_star_piece') then
		self:key_hold_action()
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 22 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 23 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s24_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 24 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s25_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 25 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s26_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 26 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s26_start_pos'),
				false, false)
	else
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

--region 길 통제용 가드 event
function local_class:guard_event_setting(quest_progress)
	if quest_progress == nil or quest_progress.IsComplete or quest_progress.InnerProgress >= 27 then
		self.guard_event_check = false
	else
		self.guard_event_check = true
	end


	stage.BattleManager:AddToNoAssassination(get_character('saul_guard_6'))
end

function local_class:war_zone_guard_event(zone)
	local guards = { self.get_guard_npc(1), self.get_guard_npc(2) }
	local leader = get_party_leader()

	--1, 2번이 가디언을 바라본다.
	character_util.look_at(guards[1], leader)
	character_util.look_at(guards[2], leader)

	--1번 대사 : 이쪽은 위험하니 지나가시면 안됩니다.
	music_player_util.play_sfx_one_shot('01_land_01')
	scene_util.show_normal_speech_async(guards[1], self.guard_event_string_key)

	--가디언 존 오른쪽 바깥으로 2칸 속도 4로 걸어나온다.
	local return_pos = zone_util.get_return_pos_on_enter(zone, leader, 'right', 1)

	wp_util.move_async(leader, return_pos, 4)

	character_util.set_group_direction(guards, 'left')
end
--endregion 길 통제용 가드 event

--region 사울 가드 구역 event
function local_class:battle_start_guard_setting()
	for _, soldier in pairs(self.saul_guards) do
		soldier.EntityGroup = CS.Oak.EntityGroups.Neutral0
		soldier.CharacterStatsBehaviour:AddStatsOptionRequest(stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
	end
end

function local_class:battle_end_guard_setting()
	for _, soldier in pairs(self.saul_guards) do
		soldier.EntityGroup = CS.Oak.EntityGroups.Enemy0
		soldier.CharacterStatsBehaviour:RemoveStatsOptionRequest(stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
	end
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_character('saul_guard_key_hold')) then
		music_player_util.play_sfx_one_shot('01_villain_scream_03')

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			wait_for_sec(0.15)
			music_player_util.play_sfx_one_shot('01_bounce_iron_01', 5)
		end))
		return true
	end

	if lua_helper.reference_equals(e.FieldObject, get_character('saul_star_piece_guard')) then
		music_player_util.play_sfx_one_shot('01_villain_scream_03')
		return true
	end
	return false
end

function local_class:player_detected_by_guard_event(guard)
	local leader = get_party_leader()
	local dir = vector_util.to_direction(guard.Position - leader.Position)

	-- 발견한 가드는 임시로 폭탄 데미지 받지 않도록 설정
	guard.DamagedBehaviour.ApplyBombDamage = false

	-- 쥐폭탄 관련 예외처리 필요
	if lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
		while lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
			coroutine.yield()
		end
	end

	coroutine.yield()

	-- 타이밍 이슈로 감시병이 죽었다면 연출 전에 탈출
	if guard.ActiveState == active_state('disabled') then
		return
	end

	self.util:enter_scene(nil)

	party_util.set_direction(dir)
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_anim({ name = 'embarrassed' })
	party_util.set_emotion({ name = 'scared' })

	music_player_util.play_sfx_one_shot('01_whistle_01')
	scene_util.set_anim(guard, self, 'release')
	scene_util.set_emotion(guard, self, 'attack')
	scene_util.show_shout_speech_async(guard, 'cw_main_s25_1')

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	party_util.remove_emotion()
	party_util.remove_animation()

	local reset_marker_name = guard.FieldObjectController.ResetMarkerName
	local reset_marker = field:GetMarker(reset_marker_name)

	party_util.align_party(reset_marker.position, reset_marker.direction, 0, 'linear')

	message_system:Publish(CS.Oak.CustomStageEvent.Create(leader, { 'reset', self.detected_by_guard_key }))
	character_util.remove_anim_and_emotion(guard)


	for _, soldier in pairs(self.saul_guards) do
		message_system:SendSync(soldier, CS.Oak.StateResetEvent.Instance)
	end

	coroutine.yield()

	camera_util.return_to_leader()

	guard.DamagedBehaviour.ApplyBombDamage = true

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	self.is_detected = false

	self.util:exit_scene(nil, leader)
end
--endregion 사울 가드 구역 event

--region Key Door 의 열쇠 들고 있는 npc 세팅
function local_class:key_hold_action()
	local npc = get_character('saul_guard_key_hold')
	local key = get_field_object('star_piece_door_key')

	command_util.publish_holdup(npc, key, npc.Position, nil, false)
end
--endregion Key Door 의 열쇠 들고 있는 npc 세팅

function local_class:set_telescope()
	local black_flower_telescope = get_or_create_global_table('Quest/Main/CivilWar/Common/CustomTelescope')

	black_flower_telescope:initialize(
			'saul_telescope_1',
			function()
				local duration = 0.5
				local target_pos = field_util.get_marker_pos('puzzle_custom_telescope_focus')

				--동일한 시간동안 카메라 사이즈 6으로 줌아웃.
				camera_util.resize_by_ratio(6, duration)

				--망원경 인터랙트하면 0.5초간 (-113, 0, -7)로 카메라 이동.
				camera_util.move_async(target_pos, duration)
			end,
			function()
				local duration = 0.5

				--동일한 시간동안 카메라 사이즈 4로 복귀.
				camera_util.resize_to_default(duration)

				--터치 입력되면 다시 카메라 가디언에게로 0.5초만에 복귀
				camera_util.return_to_leader(duration)
			end
	)
end

--region directional light on off
function local_class:light_on_off_check(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_enter(e, leader, 'main_zone') then
		self.get_forest_light().ActiveState = active_state('enabled')
		self.get_tent_light().ActiveState = active_state('disabled')
	end

	if type_util.is_zone_full_enter(e, leader, 'demon_tent_zone') or
			type_util.is_zone_full_enter(e, leader, 'saul_tent_zone') then
		self.get_forest_light().ActiveState = active_state('disabled')
		self.get_tent_light().ActiveState = active_state('enabled')
	end
end
--endregion directional light on off

--region sound 구역
function local_class:crowd_buzz_sfx_setting(quest_progress)
	if quest_progress == nil or quest_progress.IsComplete or quest_progress.InnerProgress >= 24 then
		self.can_play_sfx = false
	else
		self.can_play_sfx = true
	end
end

function local_class:crowd_buzz_sfx_play()
	if self.crowd_buzz_sfx == nil then
		self.crowd_buzz_sfx = music_player_util.play_sfx({
			sfx_name = '01_crowd_buzz_02',
			player_priority = 'npc',
			loop = true,
			play_pos = vector(-40.5, 0, 2)
		})
	end
end

function local_class:crowd_buzz_sfx_stop()
	if self.crowd_buzz_sfx ~= nil then
		self.crowd_buzz_sfx:FadeOut()
		self.crowd_buzz_sfx = nil
	end
end
--endregion sound 구역

--region 마나 캐논 처리
function local_class:setting_mana_cannon(quest_progress)
	if quest_progress == nil or quest_progress.IsComplete or quest_progress.InnerProgress >= 25 then
		get_field_object('s25_mana_cannon').ActiveState = active_state('disabled')
		get_field_object('mana_cannon_broken').Position = field_util.get_marker_pos('s25_mana_cannon_pos')
	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
