local local_class = newclass('LaboseWorld6Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.operator_ui = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	do
		local operator_ui = get_or_create_global_table('Quest/Main/CivilWar/Common/OperatorUI')

		operator_ui:load_async()
	end

	do
		local background_attacher = get_or_create_global_table(
				'Quest/Main/LaboseWorld/Common/OtherSideBackgroundAttacher'
		)

		background_attacher:load_async()
	end
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

function local_class:launch_routine()
	local main_quest_id = 386
	local quest_progress = quest_util.get_started_quest(main_quest_id)

	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)

	elseif quest_progress.InnerProgress == 21 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	elseif quest_progress.InnerProgress == 22 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('main_s23_start'),
				true, true)

	elseif quest_progress.InnerProgress == 23 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('main_s24_start'),
				false, false)

	elseif quest_progress.InnerProgress == 24 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('main_s25_start'),
				true, true)

	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
