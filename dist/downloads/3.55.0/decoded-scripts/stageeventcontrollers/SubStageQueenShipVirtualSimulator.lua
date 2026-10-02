local local_class = newclass('SubStageQueenShipVirtualSimulatorController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	start_coroutine(self.opening_routine, self)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:opening_routine()
	local knight = user_util.get_knight_character('knight_female', 'knight_male')
	local princess = get_character('princess')

	character_util.convert_to_manual_character(knight)
	character_util.convert_to_party_member(princess, user_party, true)

	stage_launch_util.default_launch_with_marker_name('default_start', true)

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
