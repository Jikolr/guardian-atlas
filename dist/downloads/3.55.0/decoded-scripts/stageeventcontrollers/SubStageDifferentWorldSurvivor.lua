local local_class = newclass("SubStageDifferentWorldSurvivorStageController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
end

function local_class:need_on_launch()
	local q = user_progress:GetStartedQuest(23)
	return q ~= nil and q.InnerProgress == 1
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
