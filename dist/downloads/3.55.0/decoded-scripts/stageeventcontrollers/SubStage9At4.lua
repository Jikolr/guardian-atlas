local local_class = newclass("SubStage9At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	local colosseum_quest = user_progress:GetStartedQuest(108)
	return colosseum_quest ~= nil and (colosseum_quest.InnerProgress == 1 or colosseum_quest.InnerProgress == 2)
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