local local_class = newclass("Cafe1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	return
end

function local_class:need_on_launch()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)
	self:stage_event_setting(q.IsComplete)

	if q ~= nil and q.InnerProgress <= 20 and q.InnerProgress >=19 and not q.IsComplete then
		return true
	else
		for i = 1, 9 do
			local prisoner = get_character('prisoner_'..i)

			character_util.set_position(prisoner, vector(999, 0, 999))
		end
	end
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.cs_controller = nil
end

function local_class:on_event(e)
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	return false
end

function local_class:stage_event_setting(q_complete)
	if q_complete then
		local boss = get_character('boss_karmen')
		boss.ActiveState = active_state('disabled')
		character_util.set_active_state(boss, 'disabled')
		character_util.set_position(boss, vector(920, 0, 999), false)

		for i = 1, 9 do
			local temp = get_character('prisoner_' .. i)
			character_util.set_active_state(temp, 'disabled')

		end

	end

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}