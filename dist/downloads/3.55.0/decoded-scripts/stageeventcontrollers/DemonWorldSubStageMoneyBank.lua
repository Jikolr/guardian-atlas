local local_class = newclass("DemonWorldSubStageMoneyBank")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	yield_return_func(demon_world_dollar.load_resource, demon_world_dollar)
end

function local_class:need_on_launch()

	local robbery_quest_id = 232
	local q = user_progress:GetStartedQuest(robbery_quest_id)

	return q ~= nil and not q.IsComplete and q.InnerProgress > 1 and q.InnerProgress <= 4
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
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
