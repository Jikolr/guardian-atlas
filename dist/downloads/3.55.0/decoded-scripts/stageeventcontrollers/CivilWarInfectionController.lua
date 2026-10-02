local local_class = newclass('CivilWarInfectionController')

-- 월드 17 보스 전투용 신규 디버프 감염 기믹
-- 단계 별로 메뉴얼 캐릭터(이하 PC)에게 지정된 효과(버프/디버프, 시각적 효과, 게임 오버 처리)를 부여
function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.infection_state = {
		none = 1,
		first_stage = 2,
		second_stage = 3,
		third_stage = 4
	}

	self.current_infection_value = 0
	self.max_infection_value = 100

	self.infection_character_list = {}

	self.is_on = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:init_fx()
	self:init_sfx()
	self:init_gauge_ui()
end

function local_class:init_fx()
	--unity_object_pool.GetOrCreate('')
end

function local_class:init_sfx()
	--self.sfx_infection = ''
	--music_player:PreloadSfx(self.sfx_infection)
end

function local_class:init_gauge_ui()
	local res_holder = CS.Foundations.ResourceHolder()

	coroutine.yield(CS.Oak.UI.CivilWarInfectionUI.LoadCivilWarInfectionUI(res_holder))

	self:reset_infection_value()
	self:deactivate_infection()
end

function local_class:activate_infection()
	self.is_on = true
	self:show_ui()
end

function local_class:deactivate_infection()
	self.is_on = false
	self:hide_ui()
end

function local_class:show_ui()
	if not self.is_on then
		return
	end

	self:update_infection_state()
	CS.Oak.UI.CivilWarInfectionUI.Instance:UIOnOff(true)
	self:update_infection_ui(0)

	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
end

function local_class:hide_ui()
	if not self.is_on then
		self:change_infection_state(self.infection_state.none)
	end

	CS.Oak.UI.CivilWarInfectionUI.Instance:UIOnOff(false)

	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
end

function local_class:reset_infection_value()
	self:set_infection_value(0, 0)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'add_infection_value' then
		local add_value = tonumber(e:GetParamAt(1))
		self:set_infection_value(self.current_infection_value + add_value)
	elseif e:GetParamAt(0) == 'set_infection_value' then
		local set_value = tonumber(e:GetParamAt(1))
		self:set_infection_value(set_value)
	elseif e:GetParamAt(0) == 'reset_ui' then
		self:reset_infection_value()
	elseif e:GetParamAt(0) == 'register_infection_fo' then
		local fo_name = e:GetParamAt(1)

		if self.infection_character_list[fo_name] == nil then
			local character = get_character(fo_name)

			if character then
				self.infection_character_list[fo_name] = character
			end
		end
	elseif e:GetParamAt(0) == 'show_ui' then
		self:activate_infection()
	elseif e:GetParamAt(0) == 'hide_ui' then
		self:deactivate_infection()
	end
end

-- 감염도 값 변경
function local_class:set_infection_value(value, time)
	local new_value = unity_class.mathf.Clamp(value, 0, self.max_infection_value)

	if new_value == self.current_infection_value then
		return
	end

	self.current_infection_value = new_value
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.owner, {
		'infection_value_changed',
		self.current_infection_value
	}))

	if not self.is_on then
		return
	end

	self:update_infection_ui(time and time or 0.2)
	self:update_infection_state()
end

function local_class:get_current_infection()
	if not self.is_on then
		return self.infection_state.none
	end

	local current_infection_index = CS.Oak.UI.CivilWarInfectionUI.Instance:GetCurrentInfection()

	if current_infection_index == 0 then
		return self.infection_state.first_stage
	elseif current_infection_index == 1 then
		return self.infection_state.second_stage
	elseif current_infection_index == 2 then
		return self.infection_state.third_stage
	else
		return self.infection_state.none
	end
end

function local_class:update_infection_state()
	self:change_infection_state(self:get_current_infection())
end

function local_class:change_infection_state(new_state)
	if self.current_infection_state == new_state then
		return
	end

	if self.current_infection_state == self.infection_state.first_stage then
	elseif self.current_infection_state == self.infection_state.second_stage then
		buff_manager:RemoveBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party.Leader, 10000)
	elseif self.current_infection_state == self.infection_state.third_stage then
		user_party.Leader.SpineController:RemoveFadeColor('infection', 0.6)
	end

	if new_state == self.infection_state.first_stage then
	elseif new_state == self.infection_state.second_stage then
		buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party.Leader, 10000, 200, true, false)
	elseif new_state == self.infection_state.third_stage then
		if self.current_infection_value == self.max_infection_value then
			self:kill_player()
		end

		user_party.Leader.SpineController:AddFadeColor('infection', unity_class.color.black, 1, 0.6)
	end

	self.current_infection_state = new_state
end

-- 감염도 아이콘, 미터기 ui 상태 최신화
function local_class:update_infection_ui(time)
	CS.Oak.UI.CivilWarInfectionUI.Instance:SetUI(math.floor(self.current_infection_value), time)
end

-- 100% 도달 시 플레이어 즉사
function local_class:kill_player()
	local target = user_party.Leader

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Death
	damage_info.sender = target
	damage_info.target = target
	damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	command_util.publish_cmd(damage_info.Owner, cmd)
end

function local_class:on_player_dead_routine()
	if self.current_infection_value ~= self.max_infection_value then
		self:hide_ui()
		return
	end

	local delay = 0.5

	while delay > 0 do
		delay = delay - unity_class.time.deltaTime

		coroutine.yield()

		if self.current_infection_value ~= self.max_infection_value then
			return
		end
	end

	self:hide_ui()
end

function local_class:is_infection_fo_in_battle(battle)
	if battle == nil then
		return false
	end

	for _,fo in pairs(self.infection_character_list) do
		if CS.Oak.BattleCharacterStatusExtensions.IsAliveInBattle(battle.Enemies, fo) then
			return true
		end
	end

	return false
end

function local_class:on_battle_start_event(e)
	local battle = e.StartedBattle
	if self:is_infection_fo_in_battle(battle) then
		self:activate_infection()
	end
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_player_dead_routine, self))
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
	else
		local player_battle = stage.BattleManager:GetBattleFor(user_party.Leader)

		if not self:is_infection_fo_in_battle(player_battle) then
			self:deactivate_infection()
		end
	end

	return false
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.current_infection_value == self.max_infection_value then
			self:reset_infection_value()
		end
		self:show_ui()
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.cs_controller = nil
	self.scene = nil
	self.infection_state = nil

	for name,_ in pairs(self.infection_character_list) do
		self.infection_character_list[name] = nil
	end
	self.infection_character_list = nil

	CS.Oak.UI.CivilWarInfectionUI.Instance:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
