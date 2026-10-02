local local_class = newclass("NightmareDesert1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.torture_thief_name = 'torture_thief_'
	self.torture_gimmick_name = 'torture_gimmick_'
	self.torture_brazier_name = 'torture_brazier'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	local thief_2 = get_character(self.torture_thief_name .. 2)
	thief_2.Interactable:AddListener(self.cs_controller)

	self.talk_coroutine = coroutine_class.coroutine(stage.StageGameObject, util.cs_generator(function()
		local thief_1 = get_character(self.torture_thief_name .. 1)

		while true do
			speech_bubble_util.show_speech_bubble_async(thief_1, { key = 'nightmare_desert_3_circus_1' })

			wait_for_sec(3)
		end
	end))
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	local thief_2 = get_character(self.torture_thief_name .. 2)
	if lua_helper.reference_equals(thief_2.Interactable, CS.Oak.NPCInteractable) then
		thief_2.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.talk_coroutine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local thief_2 = get_character(self.torture_thief_name .. 2)
		if lua_helper.reference_equals(e.Target, thief_2) then
			speech_bubble_util.show_speech_bubble(thief_2, { key = 'nightmare_desert_3_circus_2' })
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		for i = 1, 2 do
			local torture_thief = get_character(self.torture_thief_name .. i)
			local torture_gimmick = get_field_object(self.torture_gimmick_name .. i)

			if lua_helper.reference_equals(e.Info.target, torture_thief) and
				lua_helper.reference_equals(e.Info.sender, torture_gimmick) then

				-- 대미지 1 보여줌
				CS.DamageNumber.ShowDamageNumber(torture_thief, 1, unity_class.color.red, torture_thief.Position)

				return true
			end

		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

		if e.CameraGrid.name == 'torture_thief_grid' then
			local marker = field:GetMarker('torture_thief_pos').position
			local thief_pos = {
				marker + 3 * unity_class.vector3.forward,
				marker + 3 * unity_class.vector3.right
			}
			for i = 1, 2 do
				local torture_thief = get_character(self.torture_thief_name .. i)
				torture_thief.Position = thief_pos[i]
			end

			coroutine_manager:StartCoroutine(self.talk_coroutine)

			-- 폭탄이 터지도록 불을 켜줌
			local brazier = get_field_object(self.torture_brazier_name)
			command_util.execute_burn(brazier, brazier, true)

			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

		if e.CameraGrid.name == 'torture_thief_grid' then
			for i = 1, 2 do
				local torture_thief = get_character(self.torture_thief_name .. i)
				torture_thief.Position = vector(999, 0, 999)
			end

			stop_coroutine(self.talk_coroutine)

			-- 폭탄이 터지지 않도록 불을 꺼줌
			local brazier = get_field_object(self.torture_brazier_name)
			command_util.execute_extinguish(brazier, brazier)

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
