local local_class = newclass('NightmareTitanTavern1At2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	local bomb_grass = get_field_object('bomb_grass_1')
	bomb_grass.Holdable = CS.Oak.NonHoldable.Instance
	bomb_grass.Interactable = CS.Oak.PublishInteractable.Create()

	bomb_grass = get_field_object('bomb_grass_2')
	bomb_grass.Holdable = CS.Oak.NonHoldable.Instance
	bomb_grass.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent)  then
		if lua_helper.reference_equals(e.Target, get_field_object('bomb_grass_1')) or
				lua_helper.reference_equals(e.Target, get_field_object('bomb_grass_2')) then
			sp_util.play_normal_screenplay(self.show_narration, self)
			return true
		end
	end

	return false
end

function local_class:show_narration()
	field_ui_util.show_narration_async({ key = 'nightmare_titantavern_3_bomb_1' })
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			e.Zone.Name == 'bomb_zone' then
		local bomb_grass = get_field_object('bomb_grass_1')
		bomb_grass.Holdable = CS.Oak.Holdable()
		bomb_grass.Interactable = CS.Oak.NonInteractable.Instance

		bomb_grass = get_field_object('bomb_grass_2')
		bomb_grass.Holdable = CS.Oak.Holdable()
		bomb_grass.Interactable = CS.Oak.NonInteractable.Instance
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == 'bomb_zone' then
				local bomb_grass = get_field_object('bomb_grass_1')
				bomb_grass.Holdable = CS.Oak.NonHoldable.Instance
				bomb_grass.Interactable = CS.Oak.PublishInteractable.Create()

				bomb_grass = get_field_object('bomb_grass_2')
				bomb_grass.Holdable = CS.Oak.NonHoldable.Instance
				bomb_grass.Interactable = CS.Oak.PublishInteractable.Create()
				return true
			end
		end
	end

	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
