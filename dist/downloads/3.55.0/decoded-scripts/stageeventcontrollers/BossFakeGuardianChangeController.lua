local local_class = newclass('BossFakeGuardianChangeController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.boss_names = {'boss_1_1', 'boss_2_1', 'boss_3_1'}
	self.boss_group = 'boss'

	self.boss_type = {
		one_hand = 1,
		two_hand = 2,
		bow = 3
	}

	self.current_boss_character = nil
	self.boss_character_list = {}

	--test
	self.switch_count = 2
	self.test_change_idx = 1
	self.test_hp_list = {70, 40}
	--test
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	--todo:보스들 캐럭터 가져와야된다.

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	for i = 1, #self.boss_names do
		local boss = get_character(self.boss_names[i])
		if i > 1 then
			--다른 보스들은 안보이고 전투 안하도록 세팅
			boss.Position = vector(999, 0, 999)
			local boss_group = lua_helper.get_or_default(self.boss_group)
			local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)
			revive_boss_group:Remove(boss)
			boss.CharacterBehaviour:CancelAllBattleActions(true)
			boss.ActiveState = active_state('visible')
			boss.FieldObjectController.DontFight = true
		end
		table.insert(self.boss_character_list, boss)
	end

	--현재 보스 세팅
	self.current_boss_character = self.boss_character_list[1]
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
end

function local_class:on_damage_event(e)
	--각 보스들의 체력 싱크
	--현재 활동중인 보스가 데미지를 받았다면 이외에 보스들에게도 같은 데미지를 보내준다.
	if lua_helper.reference_equals(self.current_boss_character, e.Info.target) then
		for _,v in pairs(self.boss_character_list) do
			if not lua_helper.reference_equals(v, self.current_boss_character) then
				v.DamagedBehaviour.ShowDamageNumber = false

				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Trap
				damage_info.sender = e.Info.sender
				damage_info.target = v
				damage_info.damage = e.Info.damage
				damage_info.fireDamage = e.Info.fireDamage
				damage_info.iceDamage = e.Info.iceDamage
				damage_info.earthDamage = e.Info.earthDamage
				damage_info.lightDamage = e.Info.lightDamage
				damage_info.darkDamage = e.Info.darkDamage
				local cmd = CS.Oak.DamageCommand.Create(damage_info)
				command_util.publish_cmd(damage_info.Owner, cmd)

				v.DamagedBehaviour.ShowDamageNumber = true
			end
		end
	end

	--test code
	if self.test_change_idx > self.switch_count then return false end

	if lua_helper.reference_equals(e.Info.target, self.current_boss_character) then
		if self.current_boss_character.CharacterStatsBehaviour.HpRatio * 100 < self.test_hp_list[self.test_change_idx] then
			self.test_change_idx = self.test_change_idx + 1
			message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, {
				'boss_fakeguardian_change', self.test_change_idx }))
		end
	end
	--test code

	return false
end

function local_class:test_damage(e)
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Trap
	damage_info.sender = e.Info.sender
	damage_info.target = self.current_boss_character
	damage_info.damage = e.Info.damage
	damage_info.fireDamage = e.Info.fireDamage
	damage_info.iceDamage = e.Info.iceDamage
	damage_info.earthDamage = e.Info.earthDamage
	damage_info.lightDamage = e.Info.lightDamage
	damage_info.darkDamage = e.Info.darkDamage

	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	CS.Oak.CommandDispatcher.Publish(damage_info.Owner, cmd)
	cmd:Dispose()
end

function local_class:on_custom_stage_event(e)
	--보스교체 이벤트가 오면 보스 교체 + 체력싱크
	--이벤트 인자를 뭘로 받을지?
	if e:GetParamAt(0) == 'boss_fakeguardian_change' then
		--coroutine_manager:StartCoroutine(stage.StageGameObject,
		--		util.cs_generator(self.change_boss, self, e:GetParamAt(1)))
		self:change_boss(tonumber(e:GetParamAt(1)))
		return true
	end
end

function local_class:change_boss(type)
	--현재 보스 비전투 상태로 변경하고 교체될 보스를 현재보스 위치에 셋팅 해준다.
	local boss_group = lua_helper.get_or_default(self.boss_group, 'boss')
	local change_boss_group = stage.BattleManager:GetBattleGroup(boss_group)

	--현재 보스 비활성화
	change_boss_group:Remove(self.current_boss_character)
	self.current_boss_character.CharacterBehaviour:CancelAllBattleActions(true)
	self.current_boss_character.ActiveState = active_state('visible')
	self.current_boss_character.FieldObjectController.DontFight = true
	--교환될 위치 저장한뒤 기존보스는 안보이는곳으로 이동 시킨다.
	local boss_pos = self.current_boss_character.Position
	self.current_boss_character.Position = vector(999, 0, 999)

	--교환될 보스 셋팅
	self.current_boss_character = self.boss_character_list[type]
	self.current_boss_character.Position = boss_pos
	change_boss_group:Add(self.current_boss_character)
	self.current_boss_character.ActiveState = active_state('enabled')
	self.current_boss_character.FieldObjectController.DontFight = false

	-- 바로 플레이어를 Notice하도록
	message_system:Send(self.current_boss_character.FieldObjectController, CS.Oak.MonsterNoticeEvent.Create(self.current_boss_character,
			user_party_leader, CS.Oak.MonsterNoticeLevel.Battle))
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
