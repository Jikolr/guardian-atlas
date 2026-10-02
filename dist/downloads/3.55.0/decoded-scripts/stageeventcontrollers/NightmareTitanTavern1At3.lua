local local_class = newclass('NightmareTitanTavern1At3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

end

function local_class:load_resource()
end

function local_class:need_on_launch()
	local main_quest_id = 124
	local q = user_progress:GetStartedQuest(main_quest_id)

	if q ~= nil and q.IsComplete then
		character_util.set_active_state(get_character('door_keeper_1'), 'disabled')
		character_util.set_active_state(get_character('door_keeper_2'), 'disabled')
		get_field_object('last_exit').ActiveState = active_state('disabled')
	end
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}