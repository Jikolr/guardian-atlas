local local_class = newclass('TowerBossSwitchingController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 데이터 불러오기
	self.data = require('stageeventcontrollers/TowerBossSwitchingData.lua')
	self.stage_data = self.data[stage.Name][1]

	-- 보스들이 조건을 충족하며 전멸했는지
	self.is_all_dead_table = false

	-- 해당 보스가 부활 중인지
	self.is_reviving_boss = {}

	-- 현재 활성화된 보스의 이름
	self.current_boss_info = {}

	if self.stage_data ~= nil then
		-- 테이블 생성
		for i = 1, #self.stage_data.boss_table do
			table.insert(self.is_reviving_boss, false)
			table.insert(self.current_boss_info,
					{
						index = 1,
						name = self.stage_data.boss_table[i].boss_info[1].boss_name,
						type = self.stage_data.boss_table[i].boss_info[1].boss_type,
						is_switch = self.stage_data.boss_table[i].is_switching
					})
		end
	end

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	-- 보스 그룹 변경하면서 다음 스폰 체크 하지 않도록 함.
	local boss_group = lua_helper.get_or_default(self.stage_data.boss_group, 'boss')
	local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)
	revive_boss_group.SpawnNextWaveAutomatically = false
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	-- 이펙트 미리 로드
	unity_object_pool.GetOrCreate('FX_levelup_new')
	self:set_boss_immortal()
	return
end

-- immortal이 걸려 있기 때문에 죽지 않는다. 체력이 1이면 그로기 상태를 연출하고 다시 부활, 둘다 그로기면 immortal을 해제하고 데미지를 준다.
function local_class:on_damage_event(e)
	if e.HpBefore - e.Info:GetTotalDamage() < 1 then
		local boss
		for i = 1, #self.current_boss_info do
			boss = get_character(self.current_boss_info[i].name)

			if lua_helper.reference_equals(e.Info.target, boss) and self.is_all_dead_table == false then
				-- TODO: 보스 매칭조건이 모두 맞고 다른보스들이 그로기상태면 몬든 보스 사망
				if self:check_all_boss_dead(i) then
					self.is_all_dead_table = true
					self:kill_all_boss()
					return false
				else
					-- visible 상태여도 부상 데미지가 들어가기 때문에 1번만 실행하는 방어코드 추가
					if self.is_reviving_boss[i] == false then
						-- 전멸한게 아니면 부활 코루틴 실행
						coroutine_manager:StartCoroutine(stage.StageGameObject,
								util.cs_generator(self.waiting_revive, self, i))
						boss.CharacterStatsBehaviour:ResetAllAilments()
						return true
					end
				end
			end
		end
	end
end

-- 해당 보스 테이블의 보스가 매칭조건을 충족한채로 죽었는지 체크
function local_class:check_all_boss_dead(idx)
	local type = 0
	for i = 1, #self.current_boss_info do
		--현재 보스들의 타입이 같은지 체크
		if type == 0 then
			type = self.current_boss_info[i].type
		else
			if type ~= self.current_boss_info[i].type then
				return false
			end
		end
	end

	-- 보스의 부활대기상태 채크
	for i = 1, #self.is_reviving_boss do
		if i == idx then
		else
			if not self.is_reviving_boss[i] then
				return false
			end
		end
	end

	--매칭조건이 모두 맞고 다른 두 보스가 부활 대기 상태라면
	if self.is_reviving_boss[idx] == false then
		return true
	else
		return false
	end
end

-- 부활 대기
function local_class:waiting_revive(idx)
	self.is_reviving_boss[idx] = true

	local is_switch = self.stage_data.boss_table[idx].is_switching
	local timer = 0
	local boss_info = self.stage_data.boss_table[idx].boss_info[self.current_boss_info[idx].index]
	local revive_time = lua_helper.get_or_default(self.stage_data.revive_time, 5)
	local revive_hp = lua_helper.get_or_default(self.stage_data.revive_hp, 0.5)
	local revive_tint = lua_helper.get_or_default(self.stage_data.revive_tint, { 0.3, 0.3, 0.3})
	local waiting_boss_name = self.current_boss_info[idx].name
	local revive_boss = get_character(waiting_boss_name)
	local switch_boss_info = nil
	local switch_boss = nil
	local switch_pos = revive_boss.Position
	local switch_idx
	if is_switch then
		local switch_count = #self.stage_data.boss_table[idx].boss_info
		switch_idx = (self.current_boss_info[idx].index + 1)
		if switch_idx > switch_count then
			switch_idx = 1
		end
		switch_boss_info = self.stage_data.boss_table[idx].boss_info[switch_idx]
		local switch_boss_name = switch_boss_info.boss_name
		switch_boss = get_character(switch_boss_name)
	end
	local boss_group = lua_helper.get_or_default(self.stage_data.boss_group, 'boss')
	local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)

	-- 비전투 상태로 변경
	revive_boss.CharacterBehaviour:CancelAllBattleActions(true)
	revive_boss.ActiveState = active_state('visible')
	revive_boss.FieldObjectController.DontFight = true
	revive_boss.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	revive_boss_group:Remove(revive_boss)

	message_system:Send(revive_boss.FieldObjectController, CS.Oak.StateResetEvent.Instance)
	message_system:Publish(CS.Oak.AttackQueueStartEvent.Create(revive_boss, revive_time))

	-- 그로기 상태 연출
	character_util.remove_anim(revive_boss)
	if boss_info.revive_dir ~= nil then
		character_util.set_direction(revive_boss, boss_info.revive_dir)
	end

	if boss_info.revive_anim ~= nil then
		character_util.set_anim(revive_boss, { name = boss_info.revive_anim})
	end

	revive_boss.SpineController:AddColor(boss_info.boss_name,
			unity_class.color(revive_tint[1] , revive_tint[2], revive_tint[3], 1), 1, 0.3)

	if is_switch then
		switch_boss.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.BossExplosion)
		--보스가 스위칭 됐을 때 설정한 체력으로 회복하기 위해 체력을 1로 만들어준다.
		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = switch_boss
		damage_info.target = switch_boss
		damage_info.type = CS.Oak.DamageType.Trap
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)
	end

	while self.is_all_dead_table == false do
		timer = timer + unity_class.time.deltaTime

		if timer >= revive_time then
			-- 플레이어가 이미 죽은 상태면 부활하지 않고 끝내기
			if user_party.Leader.CharacterStatsBehaviour.IsDead then
				return
			end

			timer = 0

			unity_object_pool.GetOrCreate('FX_levelup_new'):Instantiate(revive_boss.Position)
			CS.Oak.MessageSystem.Instance:Publish(CS.Oak.AttackQueueEndEvent.Create(revive_boss))

			--교체되는 보스일 경우 기존보스는 안보이는곳으로 보낸 뒤 교체될보스를 가져온다.
			if is_switch then
				revive_boss.Position = vector(999, 0, 999)
				revive_boss = switch_boss
				switch_boss.Position = switch_pos
				boss_info = switch_boss_info
				self.current_boss_info[idx].index = switch_idx
				self.current_boss_info[idx].name = switch_boss_info.boss_name
				self.current_boss_info[idx].type = switch_boss_info.boss_type
			end
			-- 부활시간이 다 되었으면 부활시키기
			local heal_info = CS.Oak.HealInfo()
			heal_info.type = CS.Oak.HealType.Normal
			heal_info.heal = math.floor(revive_boss.CharacterStatsBehaviour.MaxHP * revive_hp)
			heal_info.isRevive = true
			heal_info.sender = nil
			heal_info.target = revive_boss

			command_util.execute_heal(heal_info)

			character_util.remove_anim(revive_boss)

			-- 틴트 제거하고 다시 전투 상태로 돌입
			revive_boss.SpineController:RemoveColor(boss_info.boss_name, 0)

			-- 캐싱된거 들고 있는거니까 여기서 다시 가져와서 갱신 먼저 해줌.
			revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)
			-- FIXME: 이미 그룹에 포함된 경우 다시 포함시키지 않음 (remove 되었는데 남아있는 경우에 대한 예외처리)
			if not revive_boss_group:IsMonsterInCurrentWave(revive_boss) then
				revive_boss_group:Add(revive_boss, 1)
			end
			revive_boss.ActiveState = active_state('enabled')
			revive_boss.FieldObjectController.DontFight = false

			-- 바로 플레이어를 Notice하도록
			message_system:Send(revive_boss.FieldObjectController, CS.Oak.MonsterNoticeEvent.Create(revive_boss,
					user_party[0], CS.Oak.MonsterNoticeLevel.Battle))
			self.is_reviving_boss[idx] = false
			return
		end
		coroutine.yield(nil)
	end
end

-- 보스 무적 세팅
function local_class:set_boss_immortal()
	if self.stage_data == nil then
		return
	end
	for i = 1, #self.stage_data.boss_table do
		for j = 1, #self.stage_data.boss_table[i].boss_info do
			local boss = get_character(self.stage_data.boss_table[i].boss_info[j].boss_name)
			character_util.set_immortal(boss, true)
			if j > 1 then
				boss.Position = vector(999, 0, 999)

				--교체용 보스들은 비전투상태로 변경
				local boss_group = lua_helper.get_or_default(self.stage_data.boss_group, 'boss')
				local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)

				-- 비전투 상태로 변경
				revive_boss_group:Remove(boss)
				boss.CharacterBehaviour:CancelAllBattleActions(true)
				boss.ActiveState = active_state('visible')
				boss.FieldObjectController.DontFight = true
			end
		end
	end
end

-- 동시 처치 시 동일 테이블의 모든 보스 죽임
function local_class:kill_all_boss()

	-- FIXME : 임시처방으로 본질적으로는 배틀그룹에서 제거 되었는데 몬스터 남아있는 경우를 찾아서 수정해야 함.
	local boss_group = lua_helper.get_or_default(self.stage_data.boss_group, 'boss')
	local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)
	local monsters = revive_boss_group:GetMonsters()
	--- 배틀그룹에 현재 보스테이블상에 없는 몬스터가 존재하는 경우 그룹에서 제거 우선.
	for i = monsters.Count - 1, 0, -1 do

		local find = false
		for j = 1, #self.current_boss_info do
			local boss = get_character(self.current_boss_info[j].name)
			if lua_helper.reference_equals(monsters[i], boss) then
				find = true
				break
			end
		end

		if not find then
			revive_boss_group:Remove(monsters[i])
		end
	end
	-- PooledList 이므로 사용 끝나고 해제해줌
	monsters:Dispose()

	for i = 1, #self.current_boss_info do
		local boss = get_character(self.current_boss_info[i].name)

		CS.Oak.MessageSystem.Instance:Publish(CS.Oak.AttackQueueEndEvent.Create(boss))
		-- 데미지 비헤비어 설정
		boss.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.BossExplosion)
		character_util.remove_anim(boss)
		boss.ActiveState = active_state('enabled')
		boss.SpineController:ResetAllColors()
		character_util.set_immortal(boss, false)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.None
		damage_info.notMortal = false
		damage_info.sender = user_party.Leader
		damage_info.target = boss
		damage_info.damage = boss.CharacterStatsBehaviour.MaxHP

		command_util.execute_damage(damage_info)
	end
	--전투 종료
	stage.BattleManager:ForceEndBattles()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_stage_start_event(e)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{key = self.stage_data.narration_key, stop_timer = true })
	return false
end

function local_class:on_battle_end_event(e)
	--self:kill_all_boss()
	self.is_all_dead_table = true
end

function local_class:on_stage_loaded_event(e)
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
