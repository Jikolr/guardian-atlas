local local_class = newclass("Movie1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()

	return
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60005)
	return main_quest.InnerProgress >= 15
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()


	return false
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}