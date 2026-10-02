-- 선택 버프 주기
local local_class = newclass("TowerTwinBossController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.day_state = {
		none = 1,
		day = 2,
		night = 3,
	}

	self.is_battle_start = false

	self.current_day = self.day_state.none

	self.narration_key = nil

	self.day_duration = nil
	self.night_duration = nil
	self.time_penalty = nil

	self.heal_interval = 1
	self.heal_ratio_a = nil
	self.heal_ratio_b = nil

	self.atk_buff_id_a = nil
	self.atk_buff_lv_a = nil
	self.def_buff_id_a = nil
	self.def_buff_lv_a = nil

	self.atk_buff_id_b = nil
	self.atk_buff_lv_b = nil
	self.def_buff_id_b = nil
	self.def_buff_lv_b = nil

	self.tint_key = 'tower_twin_boss'
	self.tint_color = unity_class.color.black
	self.tint_duration = 1

	self.boss = { }

	self.time_passed = 0
	self.heal_time_passed = 0
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_alarm')

	local temp_data = require('stageeventcontrollers/TowerTwinBossData.lua')
	local data = temp_data[stage.Name]

	self.narration_key = data.NarrationKey

	self.day_duration = data.DayDuration
	self.night_duration = data.NightDuration
	self.time_penalty = data.OnHitTimePenalty

	self.heal_interval = data.HealInterval
	self.heal_ratio_a = data.HealRatio_A
	self.heal_ratio_b = data.HealRatio_B

	self.atk_buff_id_a = data.AtkBuffId_A
	self.atk_buff_lv_a = data.AtkBuffLv_A
	self.def_buff_id_a = data.DefBuffId_A
	self.def_buff_lv_a = data.DefBuffLv_A

	self.atk_buff_id_b = data.AtkBuffId_B
	self.atk_buff_lv_b = data.AtkBuffLv_B
	self.def_buff_id_b = data.DefBuffId_B
	self.def_buff_lv_b = data.DefBuffLv_B

	local rgba = data.TintColor
	self.tint_color = unity_class.color(rgba[1] / 255, rgba[2] / 255, rgba[3] / 255, rgba[4] / 255)

	return
end

function local_class:late_update_frame(dt)
	if self.is_battle_start == false then
		return
	end

	self.time_passed = self.time_passed + dt

	self:update_heal(dt)
end

function local_class:update_heal(dt)
	if self.current_day ~= self.day_state.night then
		return
	end

	self.heal_time_passed = self.heal_time_passed + dt

	if self.heal_time_passed >= self.heal_interval then
		self.heal_time_passed = 0
		self:publish_heal()
	end
end

function local_class:change_day(new_day)
	if new_day == nil or self.new_day == self.day_state.none or self.current_day == new_day then
		return
	end

	if self.current_day == self.day_state.day then

	elseif self.current_day == self.day_state.night then
		self:remove_buff()
	end

	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

	local game_timer = nil
	if new_day == self.day_state.day then
		game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.day_duration, nil)

	elseif new_day == self.day_state.night then
		game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.night_duration, nil)
		self:add_buff()
	end

	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, game_timer))
	message_system:Publish(CS.Oak.TowerTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

	self.current_day = new_day
	self.time_passed = 0
	self.heal_time_passed = 0
end

function local_class:toggle_tint()
	if self.current_day == self.day_state.day then
		field:RemoveTint(self.tint_key, self.tint_duration)

	elseif self.current_day == self.day_state.night then
		field:Tint(self.tint_key, self.tint_color, self.tint_duration)
	end
end

function local_class:publish_heal()
	if self.boss[1] == nil or self.boss[1].FieldObjectStatsBehaviour.IsDead then
		return
	end

	local heal_info = CS.Oak.HealInfo()
	if self.boss[1] ~= nil and self.boss[1].FieldObjectStatsBehaviour.IsDead == false then
		heal_info.sender = self.boss[1]
		heal_info.target = self.boss[1]
		heal_info.heal = math.floor(self.boss[1].FieldObjectStatsBehaviour.MaxHpWoMod * self.heal_ratio_a)
		command_util.execute_heal(heal_info)
	end

	if self.boss[2] ~= nil and self.boss[2].FieldObjectStatsBehaviour.IsDead == false then
		heal_info.sender = self.boss[2]
		heal_info.target = self.boss[2]
		heal_info.heal = math.floor(self.boss[2].FieldObjectStatsBehaviour.MaxHpWoMod * self.heal_ratio_b)
		command_util.execute_heal(heal_info)
	end
end

function local_class:add_buff()
	if self.boss[1] ~= nil then
		buff_manager:AddBuff(self.boss[1], CS.Oak.EquipmentSlot.None, self.boss[1], self.atk_buff_id_a, self.atk_buff_lv_a, true, false)
		buff_manager:AddBuff(self.boss[1], CS.Oak.EquipmentSlot.None, self.boss[1], self.def_buff_id_a, self.def_buff_lv_a, true, false)
	end

	if self.boss[2] ~= nil then
		buff_manager:AddBuff(self.boss[2], CS.Oak.EquipmentSlot.None, self.boss[2], self.atk_buff_id_b, self.atk_buff_lv_b, true, false)
		buff_manager:AddBuff(self.boss[2], CS.Oak.EquipmentSlot.None, self.boss[2], self.def_buff_id_b, self.def_buff_lv_b, true, false)
	end
end

function local_class:remove_buff()
	if self.boss[1] ~= nil then
		buff_manager:RemoveBuff(self.boss[1], CS.Oak.EquipmentSlot.None, self.boss[1], self.atk_buff_id_a)
		buff_manager:RemoveBuff(self.boss[1], CS.Oak.EquipmentSlot.None, self.boss[1], self.def_buff_id_a)
	end

	if self.boss[2] ~= nil then
		buff_manager:RemoveBuff(self.boss[2], CS.Oak.EquipmentSlot.None, self.boss[2], self.atk_buff_id_b)
		buff_manager:RemoveBuff(self.boss[2], CS.Oak.EquipmentSlot.None, self.boss[2], self.def_buff_id_b)
	end
end

function local_class:on_stage_loaded(e)
	table.insert(self.boss, get_character('boss_1'))
	table.insert(self.boss, get_character('boss_2'))

	local ui = field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.TowerTimer)
	ui:Init(user_party_leader)
end

function local_class:on_stage_start(e)
	-- 클리어 조건 안내
	local show_narration = function()
		field_ui_manager:Hide()
		field_ui_util.show_narration_async({ key = self.narration_key })
		field_ui_manager:Show()
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(show_narration))
end

function local_class:on_battle_start(e)
	if self.is_battle_start == false then
		self.is_battle_start = true
		self:change_day(self.day_state.day)
	end
end

function local_class:on_damage_event(e)
	if lua_helper.reference_equals(e.Info.target, get_party_leader()) and self.current_day == self.day_state.day then
		message_system:Publish(CS.Oak.GlobalTimerModifiedEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, -self.time_penalty))
	end
end

function local_class:on_alarm(e)
	if e.TimerId ~= CS.Oak.GlobalTimerId.SingleGameTimer then
		return
	end

	if e.IsComplete == false then
		return
	end

	if self.current_day == self.day_state.day then
		self:change_day(self.day_state.night)

	elseif self.current_day == self.day_state.night then
		self:change_day(self.day_state.day)
	end

	self:toggle_tint()
end

function local_class:use_late_update_frame()
	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
