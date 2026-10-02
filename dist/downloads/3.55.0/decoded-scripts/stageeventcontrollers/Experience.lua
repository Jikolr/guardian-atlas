local local_class = newclass('ExperienceStageEventController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	self.update_timer = 0
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')

	return util.cs_generator(self.load_experience_character, self, stage.CharacterOriginSpecId, stage.CharacterRank, stage.WeaponSpecId)
end

function local_class:load_experience_character(character_origin_id, character_rank, weapon_id)
	-- 캐릭터 인포 생성 (만렙, 풀초, 풀각)
	local spec_id = CS.Oak.Characters.Value:GetIdByRank(character_origin_id, character_rank)
	local character_info = CS.Oak.CharacterInfo.CreateMaxDummyInfo(nil, spec_id)

	-- 장비 생성
	local weapon = self:get_max_weapon(weapon_id, true)
	local sub_weapon
	local acc = self:get_max_weapon(9110544, false)
	-- 카드는 변동 수치 없으므로 그냥 생성
	local orb1 = CS.Oak.Item.Create(CS.Oak.ItemSpec.GetById(40002))
	local orb2 = CS.Oak.Item.Create(CS.Oak.ItemSpec.GetById(40002))
	local merch = self:get_max_merch(152064)

	-- 캐릭터 인포에 장비 적용
	character_info.Weapon1 = weapon
	-- 보조무기 예외처리
	if spec_id == 481 then -- 481: 미스크롬
		sub_weapon = self:get_max_weapon(9030054, false)
		character_info.Weapon2 = sub_weapon
	-- elseif blabla then
	else
		-- 하드코딩 된 보조무기가 없을 경우, 방패 착용 가능 여부 검사
		local shield = self:get_max_weapon(9080134, false)
		-- 방패 장착 가능 여부는 반드시 주무기 먼저 착용 후에(캐릭터 인포에 Weapon1 세팅 한 후에) 체크해야 한다.
		if shield:IsCompatiableWith(weapon) == true then
			character_info.Weapon2 = shield
			sub_weapon = shield
		end
	end
	character_info.Accessory1 = acc
	character_info.Orb1 = orb1
	character_info.Orb2 = orb2
	character_info.Merch = merch

	-- 인포 업데이트
	character_info:UpdateOptions()

	-- 캐릭터 로드
	local loader = CS.Oak.CharacterLoader(character_info)
	coroutine.yield(loader)

	-- 캐릭터 설정
	local character = loader.Character

	character.Name = 'experience_character'
	character.Owner = CS.Oak.Player.Local
	character.CharacterInfo = character_info

	-- stat behaviour 업데이트
	local exp = character_info.Experience:GetDecrypted()
	character.FieldObjectStatsBehaviour:SetExp(exp)
	character.FieldObjectStatsBehaviour:SetUpgradeNum(0)

	-- 캐릭터에 장비 장착
	character:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, weapon, false)
	if sub_weapon ~= nil then
		character:SetEquipment(CS.Oak.EquipmentSlot.Weapon2, sub_weapon, false)
	end
	character:SetEquipment(CS.Oak.EquipmentSlot.Accessory1, acc, false)
	character:SetOrb(CS.Oak.EquipmentSlot.Orb1, orb1, false)
	character:SetOrb(CS.Oak.EquipmentSlot.Orb2, orb2, false)
	character:SetMerch(CS.Oak.EquipmentSlot.Merch, merch, false)

	-- 무적 기믹 적용
	character_util.set_immortal(character, true)

	-- 배틀액션/옵션 업데이트
	coroutine.yield(character:UpdateAndBattleAndStageOptions())

	-- 캐릭터 캐싱: 실제 캐릭터 교체는 stage load 시점에서 하도록 함.
	self.experience_character = character
	character.EntityGroup = CS.Oak.EntityGroups.Player0

	-- 엔티티 아이디 99 번으로 고정 등록
	-- 테스트 몬스터가 100 번을 가져가기 때문에 플레이어가 해당 엔티티 아이디보다 낮은 순번을 가져갈수 있도록 임시로 고정
	character.EntityId = 99
	CS.Oak.NetworkEntityManager.Instance:RegisterEntity(character.EntityId, character)

	character_manager:RegisterCharacterByName(character)

	-- 약점 속성
	local target_elemental = CS.Oak.ElementalTypeExtensions.GetWeakness(character.FieldObjectStatsBehaviour.FieldObjectSpec.ElementalType)

	-- 몬스터 조작
	local monsters = character_manager:GetAllMonsters()
	for i = 0, monsters.Count - 1 do
		-- 약점 속성으로 변경
		local clone_spec = monsters[i].CharacterStatsBehaviour.CharacterSpec:DeepClone()
		clone_spec.ElementalType = target_elemental
		-- 최대체력 고정 세팅 가능한 비헤이비어로 변경
		local stats_behaviour = CS.Oak.GuildRaid2BossStatsBehaviour()
		stats_behaviour.FieldObjectSpec = clone_spec
		monsters[i].FieldObjectStatsBehaviour = stats_behaviour
		-- 레벨, 무적 설정
		monsters[i].FieldObjectStatsBehaviour:SetExp(exp)
		character_util.set_immortal(monsters[i], true)

		-- UI 갱신 (속성이 바뀌어서 아이콘 갱신 필요)
		field_ui_manager:RemoveUI(monsters[i], CS.Oak.FieldUiType.CharacterStats)
		field_ui_manager:SetUI(monsters[i], CS.Oak.FieldUiType.CharacterStats)
	end

	local my_party = CS.Oak.Party.MyParty
	for i = 0, my_party.Count - 1 do
		my_party[i].Position = vector(999, 0, 999)
	end

	--- 포프 예외 처리
	if spec_id == 508 then
		self.target_hp_ratio = 0.29
	else
		self.target_hp_ratio = 1
	end
end

--- 장비 만렙, 풀초, 풀옵 세팅
function local_class:get_max_weapon(weapon_id, is_main_weapon)
	local weapon_spec = CS.Oak.ItemSpec.GetById(weapon_id)
	local level_cap = CS.Oak.ExpsDataMaxLevelExtensions.HighestMaxLevel(CS.Oak.ExpsData.Value, CS.Oak.MaxLevelDataType.Weapon)
	local limit_break = CS.Oak.WeaponEnhanceData.Value.Constants.WeaponMaxLimitBreak
	local weapon_max_level = level_cap + CS.Oak.WeaponEnhanceData.Value:GetAddedCoefLevel(limit_break, weapon_spec.IsMythSpec, is_main_weapon)

	local item = CS.Oak.Item.Create(weapon_spec, -1, nil, weapon_max_level)
	item.LimitBreaks = limit_break

	-- 생성 가능한 옵션 모두 밀어 넣음
	for i = 0, weapon_spec.OptionPlaceholders.Count - 1 do
		local holder = weapon_spec.OptionPlaceholders[i]
		local option = CS.Oak.OptionManager.CreateOption(holder.optionId, holder.levelMax)
		local new_option = CS.Oak.OptionManager.PostOptionProcess(option, item, true)

		item.Options:Add(new_option)
	end

	return item
end

--- 굿즈 최대 레벨 세팅
function local_class:get_max_merch(weapon_id)
	local merch_spec = CS.Oak.ItemSpec.GetById(weapon_id)
	local merch_max_level = CS.Oak.MerchData.Value:GetMaxLevel()

	return CS.Oak.Item.Create(merch_spec, -1, nil, merch_max_level)
end

function local_class:on_stage_loaded(e)
	-- 로드 완료 시점에 캐릭터 교체
	local param = CS.Oak.CharacterConvertParam:ManualDefault()

	-- 파라미터 변경이 필요하다면 여기서 컨버트 파라미터 수정 또는
	character_util.convert_to_manual_character(self.experience_character, param, true)
	-- 컨버트 후에 캐릭터에 직접 수정

	character_util.set_active_state(self.experience_character, 'enabled')

	--- 타겟 체력이 낮아져야 할때
	if self.target_hp_ratio < 1 then
		--- 데미지 정보 생성
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death | CS.Oak.DamageType.Passive | CS.Oak.DamageType.DotDamage
		damage_info.sender = self.experience_character
		damage_info.target = self.experience_character
		damage_info.damage = self.experience_character.CharacterStatsBehaviour.MaxHP * 2
		damage_info.notMortal = true

		--- 기본 사운드 mute
		damage_info.hitSfxInfo = CS.Oak.HitSfxInfo(true)

		--- 데미지 커맨드 발행
		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)

		--- 목표 체력
		local target_hp = self.experience_character.CharacterStatsBehaviour.MaxHP * self.target_hp_ratio
		--- 힐량
		local heal_amount = math.max(target_hp - self.experience_character.CharacterStatsBehaviour.HP, 0)

		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = math.floor(heal_amount)
		heal_info.isRevive = false
		heal_info.sender = self.experience_character
		heal_info.target = self.experience_character
		heal_info.skipEffect = true

		cmd = CS.Oak.HealCommand.Create(heal_info)
		command_util.publish_cmd(heal_info.Owner, cmd)
	end
end

--- 업데이트 프레임 사용
function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

--- 10초마다 체력 회복
function local_class:late_update_frame(dt)
	self.update_timer = self.update_timer + dt

	if self.update_timer >= 30 then
		self.update_timer = 0

		local monsters = character_manager:GetAllMonsters()
		for i = 0, monsters.Count - 1 do
			local monster_heal_info = CS.Oak.HealInfo()
			monster_heal_info.type = CS.Oak.HealType.Normal
			monster_heal_info.heal = monsters[i].CharacterStatsBehaviour.MaxHP
			monster_heal_info.isRevive = false
			monster_heal_info.sender = monsters[i]
			monster_heal_info.target = monsters[i]
			monster_heal_info.skipEffect = true

			local cmd = CS.Oak.HealCommand.Create(monster_heal_info)
			command_util.publish_cmd(monster_heal_info.Owner, cmd)
		end

		--- 목표 체력
		local target_hp = self.experience_character.CharacterStatsBehaviour.MaxHP * self.target_hp_ratio
		--- 힐량
		local heal_amount = math.max(target_hp - self.experience_character.CharacterStatsBehaviour.HP, 0)

		if heal_amount > 0 then
			local heal_info = CS.Oak.HealInfo()
			heal_info.type = CS.Oak.HealType.Normal
			heal_info.heal = math.floor(heal_amount)
			heal_info.isRevive = false
			heal_info.sender = self.experience_character
			heal_info.target = self.experience_character
			heal_info.skipEffect = true

			local cmd = CS.Oak.HealCommand.Create(heal_info)
			command_util.publish_cmd(heal_info.Owner, cmd)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.experience_character = nil
	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
