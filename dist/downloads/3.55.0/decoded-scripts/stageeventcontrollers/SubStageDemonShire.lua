local local_class = newclass('SubStageDemonShireController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 해당 스테이지의 퀘스트 id
	self.target_sub_quest_id = 392
end

function local_class:dispose()
	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.target_sub_quest_id)

	self:set_event_key_door(quest_progress)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s1_half_vampire_pos_1'),
				false, false)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s2_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s5_start_pos'),
				false, false)
	elseif quest_progress.InnerProgress == 5 then
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		stage_launch_util.directional_stage_entry(field_util.get_marker_pos('s6_start_pos'),
				CS.Oak.Direction.Left, game_string:GetString(stage.Name), true, false)

		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:set_event_key_door(quest_progress)
	if quest_progress == nil or quest_progress.InnerProgress < 4 then
		return
	end

	local door_first_name = 's4_door_'
	local door_count = 2

	for i = 1, door_count do
		local door = get_field_object(door_first_name .. i)
		local animator = door:GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('open', -1, 1)
		door.ActiveState = active_state('visible')
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
