local local_class = newclass('HighSchool1At6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	local high_school_main_quest_id = 60001
	local q = user_progress:GetStartedQuest(high_school_main_quest_id)
	return q ~= nil and q.InnerProgress == 18 and not q.IsComplete
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()

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
