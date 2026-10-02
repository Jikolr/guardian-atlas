local local_class = newclass("UnderTheCorpseController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.bomb_name = 'bomb_under'
	self.star_piece_name = 'star_piece_under'
	self.star_piece_zone_name = 'under_bomb_area'

	self.is_already_got_star_piece = false
	self.is_bomb_inside_zone = false
end

function local_class:load_resource()
	self.is_already_got_star_piece = stage_progress:HasStarPiece(self.star_piece_name)

	if self.is_already_got_star_piece then
		return
	end

	local main_quest = user_progress:GetStartedQuest(19)

	-- 설인 장군이 사라졌는지
	if main_quest ~= nil and main_quest.InnerProgress > 8 then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	end

	return
end

function local_class:dispose()
	if self.is_already_got_star_piece then
		self.cs_controller = nil

		return
	end

	local main_quest = user_progress:GetStartedQuest(19)

	if main_quest ~= nil and main_quest.InnerProgress > 8 then
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	end

	self.cs_controller = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local bomb = get_field_object(self.bomb_name)

	if e.FullEnter == true and lua_helper.reference_equals(e.FieldObject, bomb) and e.Zone.Name == self.star_piece_zone_name then
		self.is_bomb_inside_zone = true
	end
end

function local_class:on_zone_leave_event(e)
	local bomb = get_field_object(self.bomb_name)

	if e.FullLeave == true and lua_helper.reference_equals(e.FieldObject, bomb) and e.Zone.Name == self.star_piece_zone_name then
		self.is_bomb_inside_zone = false
	end
end

function local_class:on_field_object_destroyed_event(e)
	local bomb = get_field_object(self.bomb_name)

	if lua_helper.reference_equals(e.FieldObject, bomb) and self.is_bomb_inside_zone then
		local star_piece = get_field_object(self.star_piece_name)

		message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
