local local_class = newclass("SnowmountainSixSwitchController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.six_switch_name = 'six_switch_'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		if e.IsTurningOn and not stage_progress:HasStarPiece('six_switch_star_piece') then

			for i = 1, 6 do
				local switch = get_field_object(self.six_switch_name .. i)
				if not switch.FieldObjectBehaviour.IsPressed then return true end
			end

			-- 스위치 6개가 전부 눌린 상태면 스타피스 드랍
			local star_piece = get_field_object('six_switch_star_piece')
			message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))

			return true
		end
	end

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
