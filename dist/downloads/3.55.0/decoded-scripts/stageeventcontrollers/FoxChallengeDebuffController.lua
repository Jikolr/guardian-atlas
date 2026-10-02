local local_class = newclass("FoxChallengeDebuffController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- 우물 쿨타임
	self.used_well = false

	-- 처음 zone enter로 디버프를 걸어줬는지
	self.is_set_poison = false

	-- 독 디버프 레벨
	self.debuff_level = 30
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	unity_object_pool.GetOrCreate('FX_Instance_Heal_Circle_C_small_fast')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--region on_event
function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return false end
	if e.FieldObject ~= user_party_leader then return false end

	local zone_name = e.Zone.Name

	if zone_name == 'battle1' and not self.is_set_poison then
		self.is_set_poison = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_poison, self))
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	if not self.used_well then
		for i = 1, 6 do
			if lua_helper.reference_equals(e.Target, get_field_object('well_' .. i)) then
				self.used_well = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.immune_poison, self))
				return true
			end
		end
	end

	return false
end

function local_class:on_event(e)
	return false
end
--endregion


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

function local_class:set_poison()
	while true do
		for i = 0, user_party.Count - 1 do
			buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
					user_party[i], 'dps_based_poison_5tick_10s', self.debuff_level, false, false)
		end

		wait_for_sec(1)

		while self.used_well do
			coroutine.yield()
		end
	end
end

function local_class:immune_poison()
	for i = 0, user_party.Count - 1 do
		unity_object_pool.GetOrCreate('FX_Instance_Heal_Circle_C_small_fast'):Instantiate(user_party[i].Position)
		buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party[i],
				'dps_based_poison_5tick_10s')
	end

	wait_for_sec(3)
	self.used_well = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
