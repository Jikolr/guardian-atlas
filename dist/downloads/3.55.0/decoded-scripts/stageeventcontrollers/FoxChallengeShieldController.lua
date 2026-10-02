local local_class = newclass("FoxChallengeShieldController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.effects = nil
	self.is_regeneration = nil

	-- 실드 재생성 시간
	self.shield_regeneration_time = 15
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	unity_object_pool.GetOrCreate('fx_common_protection_shield_loop')
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--region on_event
function local_class:on_stage_start_event(e)
	self.effects = {}
	self.is_regeneration = {}
	for i = 0, user_party.Count - 1 do
		self.is_regeneration[i + 1] = false
		self.effects[i + 1] = unity_object_pool.GetOrCreate('fx_common_protection_shield_loop'):Instantiate(user_party[i].Position,
				unity_class.quaternion.identity, user_party[i].SpineController.SpineContainerTransform)

		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
				user_party[i], 'defense_up_permill_persistent', 99999, false, false)
	end

	return false
end

function local_class:on_damage_event(e)
	for i = 0, user_party.Count - 1 do
		if lua_helper.reference_equals(e.Info.target, user_party[i]) and not self.is_regeneration[i + 1] then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shield_break, self, i))
		end
	end

	return false
end

--FIXME: BattleInstance들을 받아올 방법이 없어 몬스터들을 통해 모두 순회하도록 하였으니 나중에 변경해야함
function local_class:on_field_object_revived_event(e)
	-- 체크가 끝난 BattleInstance
	local checking_completed_instance = {}

	-- 몬스터들을 받아와서
	local monsters = character_manager:GetAllMonsters()
	-- 몬스터들을 순회하면서
	for monster_index = 0, monsters.Count - 1 do
		-- 해당 몬스터가 속해 있는 BattleInstance를 받아온다
		local battle_instance = stage.BattleManager:GetBattleFor(monsters[monster_index])
		if battle_instance ~= nil then
			-- 체크하지 않은 BattleInstance 이면
			if table_util.contain_value(checking_completed_instance, battle_instance) == false then
				-- 해당 몬스터가 속해 있는 BattleInstance에 적들의 Active상태를 체크
				local is_alive_monster = false
				for enemy_index = 0, battle_instance.Enemies.Count - 1 do
					local status = battle_instance.Enemies[enemy_index]
					if status.IsActive then
						is_alive_monster = true
						break
					end
				end

				-- 모든 몬스터의 Active상태가 false라면
				if is_alive_monster == false then
					for i = 0, battle_instance.Allies.Count - 1 do
						local status = battle_instance.Allies[i]
						status.IsActive = false
					end
				end

				table.insert(checking_completed_instance, battle_instance)
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.cs_controller = nil

	if self.effects ~= nil then
		for i = 1, #self.effects do
			self.effects[i]:Dispose()
		end
		self.effects = nil
	end

	self.is_regeneration = nil
end

function local_class:shield_break(index)
	self.is_regeneration[index + 1] = true

	self.effects[index + 1]:Dispose()

	-- 기존에 걸려있는 방어력 버프 해제
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party[index],
			'defense_up_permill_persistent')

	-- 기존에 걸려있는 hp 버프 해제
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party[index],
			'hp_up_permill_persistent')

	-- 방어력 디버프
	buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
			user_party[index], 'defense_up_permill_persistent', -99999, false, false)

	-- hp 디버프
	buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
			user_party[index], 'hp_up_permill_persistent', -999, false, false)

	wait_for_sec(self.shield_regeneration_time)

	self.effects[index + 1] = unity_object_pool.GetOrCreate('fx_common_protection_shield_loop'):Instantiate(user_party[index].Position,
			unity_class.quaternion.identity, user_party[index].Transform)

	-- hp 디버프 해제
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party[index],
			'hp_up_permill_persistent')

	-- 방어력 디버프 해제
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party[index],
			'defense_up_permill_persistent')

	-- 다시 방어력 버프
	buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
			user_party[index], 'defense_up_permill_persistent', 99999, false, false)

	self.is_regeneration[index + 1] = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
