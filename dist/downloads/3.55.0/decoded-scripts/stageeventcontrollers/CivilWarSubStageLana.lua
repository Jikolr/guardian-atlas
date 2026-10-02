local local_class = newclass('CivilWarSubStageLanaController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(364)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			false, true)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
