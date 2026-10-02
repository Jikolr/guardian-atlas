local local_class = newclass('SubStagePixyWorldHellDivers')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch()
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_id = 416
	local quest = quest_util.get_started_quest(quest_id)

	if quest == nil or quest.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	elseif quest.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s2_start'),
				true, true)
	elseif quest.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_start'),
				true, true)
	elseif quest.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s4_start'),
				true, true)
	elseif quest.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s5_start'),
				true, true)
	else
		exception_stage_exit('Unexpected quest progress : ' .. quest.InnerProgress .. ' at PixyWorldHellDivers Quest.')
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
