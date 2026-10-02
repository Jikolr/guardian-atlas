local local_class = newclass("CharacterTestMapController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.cc_list = {}
	self.heal_list = {}

	for _, char in pairs(character_manager:GetAll()) do
		if string.match(char.Name, 'scarecrow') then
			table.insert(self.heal_list, char)
		end


		if string.match(char.Name, '_cc') then
			table.insert(self.cc_list, char)
		end
	end

	self.cc_time_passed = 0
	self.heal_time_passed = 0
	self.revive_time_passed = 0

	self.cc_interval = 1
	self.hp_reset_interval = 5
	self.revive_reset_delay = 5

	self.is_cc_mode = true
	if CS.Oak.Editor.CharacterTestMap.Instance ~= nil then
		self.is_cc_mode = CS.Oak.Editor.CharacterTestMap.Instance.IsCcMode
	end

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	--message_system:Subscribe(self, typeof(CS.Oak.HealEvent), 'on_heal_event')	-- 수동 컨트롤 하도록 빼둠
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.fo_scarecrow_cc = get_character('scarecrow_cc')
	self.fo_heal = get_character('player_member_heal')
	self.fo_revive = get_character('player_member_revive')

	return
end

function local_class:dispose()
	self.scene = nil
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	--message_system:Unsubscribe(self, typeof(CS.Oak.HealEvent))
end


-- 중간에 옵션창에서 프레임 바꿨을 경우 처리를 위해 updateFrame 추가
function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if user_party.Leader == nil then return end

	--- cc 관련 처리
	--- 2.5초마다만 cc 부여 기능 작동
	self.cc_time_passed = self.cc_time_passed + dt
	if self.cc_time_passed > self.cc_interval then
		if self.is_cc_mode == false then return end
		self.cc_time_passed = self.cc_time_passed - self.cc_interval


		--- 리더 서포트 액션에 맞춰서 CC를 부여해준다.
		local support_action = CS.Oak.ICharacterBehaviourExtensions.GetSupportAction(user_party.Leader.CharacterBehaviour)
		if support_action ~= nil then

			--- cc 걸어야할 개체들 마다
			for _, target in pairs(self.cc_list) do
				repeat
					--- 대상이 없거나 cc가 이미 걸린 상태라면 스킵
					if target == nil or target.CharacterStatsBehaviour:HasAilment(CS.Oak.Ailment.All) == true then
						break
					end

					--- 대상에게 cc를 건다
					self:apply_cc(target, support_action.Ailment)
				until true
			end
		end
	end

	--- 힐 관련 처리

	--[[
	if self.fo_heal.FieldObjectStatsBehaviour.HpRatio * 100 > 91 then
		self.heal_time_passed = self.heal_time_passed + dt
		if self.heal_time_passed > self.hp_reset_interval then
			self.heal_time_passed = self.heal_time_passed - self.hp_reset_interval

		end


		self:apply_damage(self.fo_heal, self.fo_heal.FieldObjectStatsBehaviour.MaxHpWoMod * 0.9)
	end

	--- 부활 관련 처리
	if self.fo_heal.FieldObjectStatsBehaviour.HpRatio * 100 > 90 then
		self.revive_time_passed = self.revive_time_passed + dt
		if self.revive_time_passed > self.revive_reset_delay then
			self.revive_time_passed = self.revive_time_passed - self.revive_reset_delay

			self:apply_damage(self.fo_revive, self.fo_heal.FieldObjectStatsBehaviour.MaxHpWoMod * 1.1)
		end
	end]]
end

function local_class:on_event(e)
	return false
end

--- 스테이지 시작 시 처리
function local_class:on_stage_start_event(e)
	-- TODO : 좀 더 스마트하게 C#쪽에서 처리할 것
	local full_immune_characters = {}
	table.insert(full_immune_characters, get_character('sandbag1'))
	table.insert(full_immune_characters, get_character('sandbag2'))
	table.insert(full_immune_characters, get_character('sandbag3'))

	for _, fo in pairs(full_immune_characters) do
		if not is_unity_null(fo) then
			fo.CharacterStatsBehaviour:AddCharacterStatsOption(CS.Oak.CharacterStatsOptions.All)
		end
	end
end

---
function local_class:on_damage_event(e)
	local character = e.Info.target
	if lua_helper.reference_equals(character, user_party.Leader) then
		return false
	end

	if (character.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then
		if character.FieldObjectStatsBehaviour.HpRatio * 100 < 1 then
			self:apply_heal(character, character.FieldObjectStatsBehaviour.MaxHpWoMod)
		end
	end

	return false
end

---
function local_class:on_heal_event(e)
	local character = e.Info.target
	if lua_helper.reference_equals(character, user_party.Leader) then
		return false
	end

	if e.Info.isRevive == true or e.Info.type ~= CS.Oak.HealType.Normal then return end

	if character == self.fo_heal or character == self.fo_revive then
		if character.FieldObjectStatsBehaviour.HpRatio * 100 > 90 then
			self:apply_self_damage(character)
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'cc_mode' then
		self.is_cc_mode = e:GetParamAt(1) == 'True'
	end

	return false
end

--- 딸피인 경우 자동 힐
function local_class:apply_heal(target, heal_amount)
	local heal_info = CS.Oak.HealInfo()
	heal_info.type = CS.Oak.HealType.Normal
	heal_info.sender = target
	heal_info.target = target
	heal_info.heal = math.floor(heal_amount)
	heal_info.skipEffect = true


	command_util.execute_heal(heal_info)
end

--- 데미지 처리
function local_class:apply_self_damage(target, modifier)
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Melee
	damage_info.sender = target
	damage_info.target = target
	damage_info.damage = target.FieldObjectStatsBehaviour.MaxHpWoMod * 90 / 100

	command_util.execute_damage(damage_info)
end

--- cc용 커맨드
function local_class:apply_cc(target, ailment_type)
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Melee
	damage_info.sender = target
	damage_info.target = target
	damage_info.damage = 0

	local ailment_info = CS.Oak.AilmentInfo()

	ailment_info.Ailment = ailment_type == CS.Oak.Ailment.All and CS.Oak.Ailment.Aerial or ailment_type
	ailment_info.AilmentGauge = 100
	damage_info:FillAilmentGauge(ailment_info, 1)

	damage_info.forceAilment = true

	command_util.execute_damage(damage_info)
end

function local_class:on_load_resource_routine()
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end
return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
