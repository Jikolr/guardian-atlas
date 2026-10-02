local local_class = newclass('OniGirlRunningParkingLotController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.oni_girl_name = 'oni_girl'

	self.oni_girl_running_zone_name = 'oni_girl_running'

	self.is_saw_oni_girl_running = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) and e.Zone.Name == self.oni_girl_running_zone_name and not self.is_saw_oni_girl_running then
		self.is_saw_oni_girl_running = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.running_oni_girl, self))
		return true
	end

	return false
end

function local_class:running_oni_girl()
	local oni_girl = get_character(self.oni_girl_name)

	oni_girl.Position = vector(45, 0, 34.5)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oni_girl_speech, self, oni_girl))

	local way_points = {
		vector(36.5, 0, 34.5),
		vector(36.5, 0, 46),
		vector(42, 0, 46),
		vector(42, 0, 56),
		vector(35, 0, 56),
		vector(35, 0, 46),
		vector(26, 0, 46),
		vector(26, 0, 56)
	}
	character_util.move_waypoint_async(oni_girl, way_points, 7, true, nil, nil, nil, true)

	way_points = {
		vector(26, 0, 56),
		vector(26, 0, 46),
		vector(42, 0, 46),
		vector(42, 0, 56)
	}
	character_util.move_waypoint(oni_girl, way_points, 7, true, 'loop', nil, nil, true)
end

function local_class:oni_girl_speech(fo)
	while true do
		speech_bubble_util.show_speech_bubble_async(fo, { key = 'oni_girl_running_1' })
		wait_for_sec(2)
		speech_bubble_util.show_speech_bubble_async(fo, { key = 'oni_girl_running_2' })
		wait_for_sec(2)
		speech_bubble_util.show_speech_bubble_async(fo, { key = 'oni_girl_running_3' })
		wait_for_sec(2)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}