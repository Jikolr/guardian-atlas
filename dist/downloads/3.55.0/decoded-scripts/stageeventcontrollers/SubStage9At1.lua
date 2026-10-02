local local_class = newclass("SubStage9At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	local drug_dealear_quest = user_progress:GetStartedQuest(103)
	return drug_dealear_quest ~= nil and not drug_dealear_quest.IsComplete
end

function local_class:on_launch(_)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_launch_routine()
end

function local_class:on_event(_)
	return false
end

function local_class:dispose()
	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}