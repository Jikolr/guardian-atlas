local local_class = newclass("DemonWorldMainPartA1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'demonworld_part1_1_1'

end

function local_class:load_resource()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
			-- 'stage_item'
		)
	end
end

function local_class:need_on_launch()
	local main_quest_id = 216
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		0,
		1,
		2,
		3
	}

	if quest_progress ~= nil then
		return true
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	--공주 파티 합류 및 파티원 전원 날리기
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:opening_routine(innerprogress, IsComplete)
	local main_quest_id = 216
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}