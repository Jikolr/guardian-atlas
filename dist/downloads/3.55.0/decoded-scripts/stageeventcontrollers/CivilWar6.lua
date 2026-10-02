local local_class = newclass('CivilWar6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.scene_version = scene_util.default_version

	-- 섹션30 연출용 라보스 벽 (투명)
	self.get_labose_invisible_wall = function(idx)
		return get_field_object('labose_wall_' .. idx)
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	-- 환경음 컨트롤을 위한 enum
	self.ambient_sfx_control_state = {
		disabled = 1,
		enabled_off = 2,
		enabled_on = 3,
	}

	self.current_ambient_sfx_state = self.ambient_sfx_control_state.disabled

	-- 환경음
	self.amb_1_sfx = nil
	self.amb_2_sfx = nil

	self.once_fade_out_amb_sfx = false

	---@type CivilWarBossBattleCommon
	self.boss_common = nil

	---@type CivilWarCustomBackgroundController
	self.background_controller = nil

	self.black_flower_state = 'open'

	---@type CivilWarStage6PlayerLoopingSystem
	self.player_looping_system = nil

	---@type CivilWarUtil
	self.cw_util = nil

	self.background_zone_infos = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.cw_util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil and not quest_progress.IsComplete and quest_progress.InnerProgress <= 32 then
		self.boss_common = get_or_create_global_table('Quest/Main/CivilWar/Main/BossBattle/Common')

		self.boss_common:load_async()
	end

	if quest_progress ~= nil and not quest_progress.IsComplete then
		---@type SpineCharacterDissolver
		local dissolver = get_or_create_global_table('utils/SpineCharacterDissolver')

		dissolver:load_async('ondemand/v2_75_civilwar/theatres/dissolve',
				'dissolve_material_container')
	end
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

--region event
function local_class:on_event(e)
	return true
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		return false
	end

	local info = self.background_zone_infos[e.Zone.Name]

	if info ~= nil then
		self.background_controller:request_activate(e.Zone.Name,
				info.border_yz, info.flower_center_cam_x, self.black_flower_state)

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave or not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		return false
	end

	if self.background_zone_infos[e.Zone.Name] ~= nil then
		self.background_controller:request_deactivate(e.Zone.Name)

		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if self.current_ambient_sfx_state == self.ambient_sfx_control_state.enabled_on and
			type_util.is_player_enter_to_cam_grid(e, 'first_battle') then
		self:fade_out_section_28_ambient_sound()

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'play_section_28_ambient_sfx' then
		self:play_section_28_ambient_sound()
	elseif e:GetParamAt(0) == 'set_volume_section_28_ambient_sfx' then
		local set_value_1 = tonumber(e:GetParamAt(1))
		local set_value_2 = tonumber(e:GetParamAt(2))

		self:control_volume_section_28_ambient_sound(set_value_1, set_value_2)
	end
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
	local prev_loop_cycle_move_x_diff

	if self.player_looping_system ~= nil then
		self.player_looping_system:update_loop(dt)

		prev_loop_cycle_move_x_diff = self.player_looping_system.prev_cycling_move_x_diff
	end

	if self.background_controller ~= nil then
		self.background_controller:update_background(prev_loop_cycle_move_x_diff)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.boss_common ~= nil then
		self.boss_common:dispose_loaded()
	end

	if self.amb_1_sfx ~= nil then
		self.amb_1_sfx:Stop()
		self.amb_1_sfx = nil
	end
	if self.amb_2_sfx ~= nil then
		self.amb_2_sfx:Stop()
		self.amb_2_sfx = nil
	end

	self.boss_common = nil

	self.background_controller = nil
	self.player_looping_system = nil

	self.background_zone_infos = nil

	self.cw_util = nil

	self.cs_controller = nil
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.background_controller = get_or_create_global_table(
			'Quest/Main/CivilWar/Common/CustomBackgroundController'
	)

	local boss_room_center_x = field_util.get_marker_pos('custom_background_boss_border_yz').x

	self.background_zone_infos = {
		custom_background_region_entry = {
			border_yz = field_util.get_marker_pos('custom_background_entry_border_yz'),
			flower_center_cam_x = boss_room_center_x
		},
		custom_background_region_boss_entry = {
			border_yz = field_util.get_marker_pos('custom_background_boss_entry_border_yz'),
			flower_center_cam_x = boss_room_center_x
		},
		custom_background_region_boss = {
			border_yz = field_util.get_marker_pos('custom_background_boss_border_yz'),
			flower_center_cam_x = boss_room_center_x
		},
	}

	self.cw_util:activate_manual_directional_light(
			{
				main_field = 'main_field_light',
				heavenhold_center_area = 'heavenhold_light',
				throne_area = 'main_field_light',
			}
	)

	self.cw_util:set_directinal_light('main_field_light')

	local function play_custom_launch_stage(dir, pos, directional_stage_entry,
											play_stage_music, activate_background_scroller)
		activate_background_scroller = lua_helper.get_or_default(activate_background_scroller, true)

		-- 리더를 시작 좌표로 이동
		local leader = get_party_leader()
		character_util.set_position(leader, pos)
		character_util.set_direction(leader, dir)

		-- 카메라 이동 완료 대기
		wait_for_sec(0.1)

		if activate_background_scroller then
			local border_yz = field_util.get_marker_pos('custom_background_entry_border_yz')
			local flower_center_cam_x = boss_room_center_x
			local request_key = 'custom_background_region_entry'

			for zone_name, info in pairs(self.background_zone_infos) do
				local zone = field_util.get_zone(zone_name)

				if zone:Contains(pos) then
					border_yz = info.border_yz
					flower_center_cam_x = info.flower_center_cam_x
				end
			end

			self.background_controller:request_turn_on()
			self.background_controller:request_activate(request_key,
					border_yz, flower_center_cam_x, self.black_flower_state)
		end

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, 'linear')
			screen_util.fade_in_circular(1, 'linear')

			yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, leader.Position,
					leader.Direction, game_string:GetString(stage.Name))

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	if quest_progress == nil or not quest_progress.IsComplete then
		local purple_coins = field:GetFieldObjectsWithBehaviour(typeof(CS.Oak.PurpleCoinBehaviour))

		for i = 1, purple_coins.Count do
			local fo = purple_coins[i - 1]

			fo.ActiveState = active_state_type.disabled
		end

		purple_coins:Dispose()
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		self:clean_up_objects_after_clearing_stage()

		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, false)
	elseif quest_progress.InnerProgress == 27 then
		self.current_ambient_sfx_state = self.ambient_sfx_control_state.enabled_off

		self.player_looping_system = get_or_create_global_table(
				'Quest/Main/CivilWar/Common/Stage6/PlayerLoopingSystem'
		)

		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true, false)
	elseif quest_progress.InnerProgress == 28 then
		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 29 then
		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 30 then
		play_custom_launch_stage('left', field_util.get_marker_pos('s30_boss_room_knight_align'),
				false, false)
	elseif quest_progress.InnerProgress == 31 then
		play_custom_launch_stage('left', field_util.get_marker_pos('s32_boss_room_knight_align'),
				false, true)
	elseif quest_progress.InnerProgress == 32 then
		play_custom_launch_stage('left', field_util.get_marker_pos('main_s33_1_knight_1'),
				false, true)
	else
		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:clean_up_objects_after_clearing_stage()
	for i = 1, 10 do
		local labose_wall = self.get_labose_invisible_wall(i)

		labose_wall.ActiveState = active_state('disabled')
	end
end

function local_class:play_section_28_ambient_sound()
	self.current_ambient_sfx_state = self.ambient_sfx_control_state.enabled_on

	-- 화면 페이드인과 함께 환경음 볼륨 0.4으로 루프 재생, 믹스 3초
	self.amb_1_sfx = music_player_util.play_sfx(
			{
				sfx_name = '01_war_loop_01', mix = 3, volume = 0.4, loop = true, type_priority = 'default'
			}
	)
	-- 화면 페이드인과 함꼐 환경음 볼륨 0.7로 재생, 믹스 3초
	self.amb_2_sfx = music_player_util.play_sfx(
			{
				sfx_name = '01_blizzard_04', mix = 3, volume = 0.7, loop = true, type_priority = 'default'
			}
	)
end

function local_class:fade_out_section_28_ambient_sound()
	self.current_ambient_sfx_state = self.ambient_sfx_control_state.enabled_off

	-- 그리드 넘어감과 함께 두 환경음 루프 종료, 믹스 디폴트값
	if self.amb_1_sfx ~= nil then
		self.amb_1_sfx:FadeOut(1)
	end

	if self.amb_2_sfx ~= nil then
		self.amb_2_sfx:FadeOut(1)
	end
end

function local_class:control_volume_section_28_ambient_sound(amb_1_volume, amb_2_volume)
	-- 그리드 넘어감과 함께 두 환경음 루프 종료, 믹스 디폴트값
	if self.amb_1_sfx ~= nil then
		self.amb_1_sfx.Volume = amb_1_volume
	end

	if self.amb_2_sfx ~= nil then
		self.amb_2_sfx.Volume = amb_2_volume
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
