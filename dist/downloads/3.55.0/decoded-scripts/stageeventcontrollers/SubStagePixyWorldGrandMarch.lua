local local_class = newclass('SubStagePixyWorldGrandMarch')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
	local created, game_manager = global_table_util.try_create('Quest/Main/PixyWorld/GrandMarch/Game/GameManager')

	if created then
		game_manager:pre_load()
	end
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

function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local normal_quest_id = 413
	local normal_quest = quest_util.get_started_quest(normal_quest_id)

	local hard_quest_id = 430
	local hard_quest = quest_util.get_started_quest(hard_quest_id)

	if normal_quest == nil then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
		return
	end

	if normal_quest.IsComplete and
			hard_quest ~= nil and hard_quest.InnerProgress == 1 and not hard_quest.IsComplete then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)

		return
	end

	if normal_quest.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif normal_quest.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif normal_quest.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif normal_quest.InnerProgress == 2 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		exception_stage_exit('Unexpected quest progress : ' .. normal_quest.InnerProgress .. ' at PixyWorldGrandMarch Quest.')
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
