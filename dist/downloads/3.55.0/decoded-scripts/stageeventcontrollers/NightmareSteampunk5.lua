local local_class = newclass('NightmareSteampunk5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.battle_4_door_name = 'cafe_door_'

	self.get_clock_signboard = function() return get_field_object('clock_signboard') end
	self.get_clock_paper_piece = function() return get_field_object('clock_paper_piece') end

	self.is_battle_4 = false

	self.cup_stew_id = 20192
	self.paper_piece_id = 20247

	self.drink_id_table = { 20255, 20165, 20186, 20186, 20165 }
	self.drink_vector_table = { vector(39, 1, 48.5), vector(40, 1, 48.5),
	                            vector(46, 1, 53.5), vector(60, 1, 48.5),
	                            vector(72.5, 1, 48.5) }
	self.drink_scale_table = { 1, 0.9, 0.8, 0.8, 0.9}
	self.drink_table = { nil, nil, nil, nil, nil}

	self.stew_pos_table = { vector(23.7, 0, 18), vector(28.1, 0, 18), vector(28.1, 0, 14) }
	self.stew_table = { nil, nil, nil }
	self.clock_paper = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	for i = 1, 3 do
		if self.stew_table[i] ~= nil then
			self.stew_table[i]:ConsumeComplete()
			self.stew_table[i] = nil
		end
	end

	for i = 1, 5 do
		if self.drink_table[i] ~= nil then
			self.drink_table[i]:ConsumeComplete()
			self.drink_table[i] = nil
		end
	end

	if self.clock_paper ~= nil then
		self.clock_paper:ConsumeComplete()
		self.clock_paper = nil
	end

	self.drink_id_table = nil
	self.drink_vector_table = nil
	self.drink_scale_table = nil
	self.drink_table = nil

	self.stew_pos_table = nil
	self.stew_table = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	local clock_signboard = self.get_clock_signboard()

	if lua_helper.reference_equals(e.Target, clock_signboard) then
		sp_util.play_normal_screenplay(self.inter_clock_signboard, self)
		return true
	end

	local clock_paper_piece = self.get_clock_paper_piece()
	if lua_helper.reference_equals(e.Target, clock_paper_piece) then
		sp_util.play_normal_screenplay(self.inter_clock_paper_piece, self)
		return true
	end

	return false
end

function local_class:on_stage_loaded_event()
	for i = 1, 3 do
		self.stew_table[i] = drop_item_util.create_item( { pos = self.stew_pos_table[i], itemid = self.cup_stew_id,
		                                                   lootstate = 'dontfindlooter', notforinven = true, skip_text = true })
	end
	self.clock_paper = drop_item_util.create_item( { pos = vector(46,1,-1), itemid = self.paper_piece_id,
	                                                 lootstate = 'dontfindlooter', notforinven = true, skip_text = true })

	for i = 1, 5 do
		self.drink_table[i] = drop_item_util.create_item( { pos = self.drink_vector_table[i], itemid = self.drink_id_table[i],
		                                                    lootstate = 'dontfindlooter', notforinven = true, skip_text = true })
		self.drink_table[i].SpriteTransform.localScale = unity_class.vector3.one * self.drink_scale_table[i]
	end

	return true
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, 'BATTLE_4') and not self.is_battle_4 then
		self.is_battle_4 = true

		for i = 1, 2 do
			message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.battle_4_door_name .. i, false))
		end

		return true
	end

	return false
end

--- BattleGroupEliminatedEvent
function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 'battle_4' then
		for i = 1, 2 do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.battle_4_door_name .. i, false))
		end
		return true
	end

	return false
end

function local_class:inter_clock_signboard()
	-- 광장 시계로 장난치는 인원이 적발되어, 시계 레버를 압수함.
	field_ui_util.show_narration_async({ key = 'nigtmare_steampunk_5_later_clock_1' })
	-- 추후 같은 문제 발생 시, 군법에 따라 엄중히 처벌하겠음.
	field_ui_util.show_narration_async({ key = 'nigtmare_steampunk_5_later_clock_2' })
end

function local_class:inter_clock_paper_piece()
	-- 오후 교대자들, 니들 자꾸 늦는데, 교대 시간 똑바로 지켜라. - 오전조
	field_ui_util.show_narration_async({ key = 'nigtmare_steampunk_5_later_clock_3' })
	-- 늦긴 뭘 늦어, 우리가 시계 핑계 대고 농땡이 피운 니들이랑 같냐? - 오후조
	field_ui_util.show_narration_async({ key = 'nigtmare_steampunk_5_later_clock_4' })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
