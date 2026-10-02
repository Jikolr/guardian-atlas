local local_class = newclass('TowerRegenShieldController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = {
		tower_fire_48 = {
			--적용할 버프 리스트
			buffs = {
				{id = 20000, level = 99999}
			},
			debuffs = {
				{id = 20000, level = -99999},
				{id = 30000, level = -999}
			},
			--디버프 유지 시간
			debuff_duration = 3,
		},
		herotower_adela_noble_3 = {
			--적용할 버프 리스트
			buffs = {
				{id = 20000, level = 99999},
				{id = 320567, level = -100}
			},
			debuffs = {
				{id = 20000, level = -100},
				{id = 320567, level = 100}
			},
			--디버프 유지 시간
			debuff_duration = 5,
		}
	}

	self.shield_effect_name = 'fx_common_protection_shield_loop'
	self.shield_effect = nil

	-- 시간 경과 변수
	self.time_passed = 0
	self.effect_sync_time_passed = 0
	self.is_add_buff = false
	self.is_add_debuff = false
	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	unity_object_pool.GetOrCreate(self.shield_effect_name)
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_stage_start_event(e)
	if self.current_progress == self.progress.playing then return end

	self.current_progress = self.progress.playing
	self.time_passed = 0
	self:add_buff()
end

function local_class:on_damage_event(e)
	--데미지를 입었을 경우 방어 버프를 해제하고 디버프 부여
	if lua_helper.reference_equals(e.Info.target, user_party_leader) and self.is_add_buff then
		self:remove_buff()
		self:add_debuff()
		self.is_add_buff = false
		self.is_add_debuff = true
		self.time_passed = 0
	end

	return false
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end

	--쉴드 해제 후 일정 시간 후 쉴드를 다시 부여 해 준다.
	if self.is_add_debuff then
		if self.time_passed >= self.current_stage_info.debuff_duration then
			self:remove_Debuff()
			self:add_buff()
			self.is_add_debuff = false
			self.is_add_buff = true
			self.time_passed = 0
		else
			self.time_passed = self.time_passed + dt
		end
	end
end

function local_class:add_buff()
	for _,v in pairs(self.current_stage_info.buffs) do
		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
				user_party_leader, v.id, v.level, false, false)
	end

	self.shield_effect = unity_object_pool.GetOrCreate(self.shield_effect_name):Instantiate(
			user_party_leader.Position, unity_class.quaternion.identity,
			user_party_leader.transform)

	self.is_add_buff = true
end

function local_class:remove_buff()
	for _,v in pairs(self.current_stage_info.buffs) do
		buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party_leader,
				v.id)
	end

	if self.shield_effect ~= nil then
		self.shield_effect:Dispose()
	end
end

function local_class:add_debuff()
	for _,v in pairs(self.current_stage_info.debuffs) do
		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None,
				user_party_leader, v.id, v.level, false, false)
	end
end

function local_class:remove_Debuff()
	for _,v in pairs(self.current_stage_info.debuffs) do
		buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party_leader,
				v.id)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

	self.stage_battle_info = nil

	if self.shield_effect ~= nil then
		self.shield_effect:Dispose()
	end

	self.shield_effect = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
