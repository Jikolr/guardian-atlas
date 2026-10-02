local local_class = newclass('TowerMonsterShieldController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 현재 스테이지용 데이터 불러오기
	local stage_data = require('stageeventcontrollers/TowerMonsterShieldData.lua')
	local current_stage_data = stage_data[stage.Name]

	self.effects = {}
	self.shield_regeneration_time = current_stage_data.shield_regeneration_time
	self.battle_group = stage.BattleManager:GetBattleGroup(current_stage_data.battle_group_name)
	self.buff_melee_immune = 'elite_melee_damage_immune'
	self.buff_projectile_immune = 'elite_projectile_damage_immune'
	self.buff_level = 0
	self.regenerating = {}
	self.battle_zone_entered = false
	self.get_effect_pool = function()
		return unity_object_pool.GetOrCreate('fx_common_protection_shield_loop')
	end
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_event(e)
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupSpawnNextWaveEvent), 'on_spawn_next_wave_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	-- 쉴드 이펙트의 오브젝트풀 미리 로딩 해놓기.
	unity_object_pool.GetOrCreate('fx_common_protection_shield_loop')
end

function local_class:on_spawn_next_wave_event(e)
	local current_wave = self.battle_group.CurrentWave
	local monsters = self.battle_group:GetMonsters(current_wave + 1)

	local triggered_event = util.cs_generator(self.add_shield_to_monsters, self, monsters)
	coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
end

function local_class:on_field_object_destroyed_event(e)
	local fo_name = e.FieldObject.Name

	if self.effects[fo_name] ~= nil then
		self.effects[fo_name]:Dispose()
	end
end

function local_class:on_zone_enter_event(e)
	if e.FieldObject ~= user_party_leader or e.FullEnter == false then return end
	if self.battle_zone_entered then return end
	self.battle_zone_entered = true
	local monsters = self.battle_group:GetMonsters(self.battle_group.CurrentWave)

	local triggered_event = util.cs_generator(self.add_shield_to_monsters, self, monsters)
	coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
end

--[[
	몬스터들이 활성화 될 시 원거리, 근거리 무적 방어 버프를 부여하는 루틴.
]]
function local_class:add_shield_to_monsters(monsters)
	-- 웨이브마다 0.5초씩 기다린 후 몬스터가 생기니 그때까지 대기.
	wait_for_sec(0.5)

	-- 스테이지 시작시 모든 몬스터들에게 싸울때 아프지 않게 쉴드 하나씩 쥐어줌.
	for i = 0, monsters.Count - 1 do
		local position = monsters[i].Position
		local rotation = unity_class.quaternion.identity
		local transform = monsters[i].SpineController.SpineContainerTransform

		self.effects[monsters[i].Name] = self.get_effect_pool():Instantiate(position, rotation, transform)

		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, monsters[i],
				self.buff_melee_immune, self.buff_level, false, false)

		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, monsters[i],
				self.buff_projectile_immune, self.buff_level, false, false)

		self.regenerating[monsters[i].Name] = false
	end
end

function local_class:on_damage_event(e)
	local target = e.Info.target

	if self:monster_has_shield(target) and self.regenerating[target.Name] == false then
		local triggered_event = util.cs_generator(self.break_shield, self, target)
		coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
	end
end

--[[
	실드가 부서지고, 일정 시간후 다시 생성하는 루틴.
]]
function local_class:break_shield(target)
	self.effects[target.Name]:Dispose()
	self.regenerating[target.Name] = true

	-- 쉴드 제거
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, target, self.buff_melee_immune)
	buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, target, self.buff_projectile_immune)

	wait_for_sec(self.shield_regeneration_time)

	-- 그 사이 타겟이 죽었다면 탈출.
	if target.FieldObjectStatsBehaviour.IsDead then return end
	-- 다시 방어력 버프

	buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, target,
			self.buff_melee_immune, self.buff_level, false, false)

	buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, target,
			self.buff_projectile_immune, self.buff_level, false, false)

	local position = target.Position
	local rotation = unity_class.quaternion.identity
	local transform = target.SpineController.SpineContainerTransform

	self.effects[target.Name] = self.get_effect_pool():Instantiate(position, rotation, transform)
	self.regenerating[target.Name] = false
end

--[[
	몬스터가 원거리, 밀리 면역 버프를 가지고 있는지 확인하는 루틴
]]
function local_class:monster_has_shield(monster)
	local monster_buffs = monster.CharacterStatsBehaviour:GetActiveBuffs()
	local found = false

	for i = 0, monster_buffs.Count-1 do
		if monster_buffs[i].BuffSpec.Name == self.buff_melee_immune
				or monster_buffs[i].BuffSpec.Name == self.buff_projectile_immune then
			found = true
			break
		end
	end

	monster_buffs:Dispose()
	return found
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupSpawnNextWaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.effects = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
