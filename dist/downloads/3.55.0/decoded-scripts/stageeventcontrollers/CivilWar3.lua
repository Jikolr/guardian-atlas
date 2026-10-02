local local_class = newclass('CivilWar3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	--크로셀 ui
	self.operator_ui = nil

	--봉인된 비네트 랜드마크 sfx
	self.sealed_loop_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.operator_ui = get_or_create_global_table('Quest/Main/CivilWar/Common/OperatorUI')
	self.operator_ui:load_async()

	return true
end
--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)

	self:pre_setting()
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 's17_demon_engineer_sfx_end' then
		if self.sealed_loop_sfx ~= nil then
			self.sealed_loop_sfx:Stop()
			self.sealed_loop_sfx = nil
		end
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 's14_sealed_demon_engineer_grid') then
		start_coroutine(self.sealed_grid_enter_routine, self)
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 's14_sealed_demon_engineer_grid') then
		start_coroutine(self.sealed_grid_leave_routine, self)
		return true
	end

	return false
end
--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self.cs_controller = nil
	self.scene = nil

	if self.sealed_loop_sfx ~= nil then
		self.sealed_loop_sfx:Stop()
		self.sealed_loop_sfx = nil
	end
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 12 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 13 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s14_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 14 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s15_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 15 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s16_exit_marker_pos_1'),
				true, true)
	elseif quest_progress.InnerProgress == 16 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s17_start_pos'),
				false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:sealed_grid_enter_routine()
	camera_util.cancel_resize_to()

	camera_util.resize_by_ratio(5, 0.5)
end

function local_class:sealed_grid_leave_routine()
	camera_util.cancel_resize_to()

	camera_util.resize_to_default(0.5)
end

function local_class:pre_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress == nil then
		return
	end

	local npc = get_character('s14_living_space_npc_5')
	scene_util.set_anim(npc, self, 'release')

	--봉인된 비네트 설정
	if quest_progress.InnerProgress > 10 and
			quest_progress.InnerProgress < 17 then
		local sfx_pos = field_util.get_marker_pos('s14_land_center_pos')
		self.sealed_loop_sfx = music_player_util.play_sfx(
				{ sfx_name = '02_light_loop_05', play_pos = sfx_pos, loop = true, volume = 0.7,
				  type_priority = 'gimmick', player_priority = 'object' })

		local demon_engineer = get_character('seal_demon_engineer_npc')
		field_ui_manager:RemoveUI(demon_engineer, CS.Oak.FieldUiType.CharacterStats)
		demon_engineer.Position = vector(20.55, 2.1, 33.2)
		--연출상 위치 폴리싱
	end

	--비네트 구출 후 비네트 베이스 조명 끄기
	if quest_progress.InnerProgress > 17 or quest_progress.IsComplete then
		local sealed_base = get_field_object('sealed_demon_engineer_base')
		local on = CS.Utils.FindChildRecursively(sealed_base.Transform, 'on')
		on.gameObject:SetActive(false)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
