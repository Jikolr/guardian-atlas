local local_class = newclass("TowerDarkness40DebuffController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
	-- Zone Name
	self.zone_name = 'boss'

	-- Buff Name
	self.debuff_name = 'dps_based_poison_5tick_10s'
	-- 독 디버프 레벨
	self.debuff_level = 100
	-- 디버프 갱신 시간
	self.debuff_renewal_time = 15

	-- 처음 zone enter로 디버프를 걸어줬는지
	self.is_set_poison = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	-- 버프 추가 및 해지 등을 명시적으로 하기 위해 있을 홀더
	self.buff_holder = get_character('buff_holder')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then
		return false
	end

	if e.FieldObject ~= user_party_leader then
		return false
	end

	local entered_zone_name = e.Zone.Name
	if entered_zone_name == self.zone_name and not self.is_set_poison then
		self.is_set_poison = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_poison, self))
	end

	return true
end

function local_class:on_game_over_event(e)
	self.is_set_poison = false

	return true
end

function local_class:on_field_object_destroyed_event(e)
	-- FIXME: 전투가 끝나도 ClearFlag를 Interact하지 못하는 현상이 있어 임시 코드 추가
	-- 보스가 죽으면 파티의 BattleInstance의 Active를 false로 바꿈
	local boss = get_character('boss_darkmagician_tower')
	if lua_helper.reference_equals(e.FieldObject, boss) then
		local battle_instance = stage.BattleManager:GetBattleForMyParty()
		if battle_instance ~= nil then
			for i = 0, battle_instance.Allies.Count - 1 do
				local status = battle_instance.Allies[i]
				status.IsActive = false
			end
		end
	end
	return true
end

function local_class:set_poison()
	while self.is_set_poison do
		for i = 0, user_party.Count - 1 do
			buff_manager:AddBuff(self.buff_holder, CS.Oak.EquipmentSlot.None, user_party[i], self.debuff_name,
					self.debuff_level, false, false)
		end

		wait_for_sec(self.debuff_renewal_time)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
