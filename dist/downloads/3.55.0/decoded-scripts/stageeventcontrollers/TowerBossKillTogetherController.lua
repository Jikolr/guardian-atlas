local local_class = newclass('TowerBossKillTogetherController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 데이터 불러오기
	self.boss_kill_together_data = require('stageeventcontrollers/TowerBossKillTogetherData.lua')
	self.stage_data = self.boss_kill_together_data[stage.Name]

	-- 해당 테이블의 몬스터가 전멸했는지
	self.is_all_dead_table = {}

	-- 해당 보스가 부활 중인지
	self.is_reviving_boss = {}

	if self.stage_data ~= nil and self.stage_data.pattern_data ~= nil then
		-- 테이블 생성
		for i = 1, #self.stage_data.pattern_data do
			table.insert(self.is_all_dead_table, false)

			local boss_table = {}
			for j = 1, #self.stage_data.pattern_data[i].boss_table do
				table.insert(boss_table, false)
			end
			table.insert(self.is_reviving_boss, boss_table)
		end
	end
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	-- 이펙트 미리 로드
	unity_object_pool.GetOrCreate('FX_levelup_new')
	self:set_boss_immortal()
	return
end

function local_class:on_stage_start_event(e)
	-- 유효성 체크
	if self.stage_data == nil then return false end

	-- TODO : 나중에 외전도 맵 입장 UI에 부활불가 띄우고, 게임오버 부활 버튼도 ReviveLimit에 따라 분기되도록 고치는게 좋을 것 같다.
	-- 게임오버 팝업에서 부활 아이콘이 인뜨도록 처리함
	if self.stage_data.force_ban_revive then
		stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, false)
	end
end

-- immortal이 걸려 있기 때문에 죽지 않는다. 체력이 1이면 그로기 상태를 연출하고 다시 부활, 둘다 그로기면 immortal을 해제하고 데미지를 준다.
function local_class:on_damage_event(e)
	if e.HpBefore - e.Info:GetTotalDamage() < 1 then
		for i = 1, #self.stage_data.pattern_data do
			for j = 1, #self.stage_data.pattern_data[i].boss_table do
				local boss = get_character(self.stage_data.pattern_data[i].boss_table[j].boss_name)
				if lua_helper.reference_equals(e.Info.target, boss) and self.is_all_dead_table[i] == false then
					-- 전멸했으면 동시에 죽도록 처리
					if self:check_all_boss_dead(i,j) then
						self.is_all_dead_table[i] = true
						self:kill_all_boss(i)
						return false
					else
						-- visible 상태여도 부상 데미지가 들어가기 때문에 1번만 실행하는 방어코드 추가
						if self.is_reviving_boss[i][j] == false then
							-- 전멸한게 아니면 부활 코루틴 실행
							coroutine_manager:StartCoroutine(stage.StageGameObject,
									util.cs_generator(self.waiting_revive, self, i,j))
							boss.CharacterStatsBehaviour:ResetAllAilments()
							return true
						end
					end
				end
			end
		end
	end
end

-- 해당 보스 테이블의 보스가 모두 죽었는지 체크
function local_class:check_all_boss_dead(idx, idx_j)
	for i = 1, #self.stage_data.pattern_data[idx].boss_table do
		if self.is_reviving_boss[idx][i] == false then
			if i ~= idx_j then
				return false
			end
		end
	end
	return true
end

-- 부활 대기
function local_class:waiting_revive(idx, idx_j)
	self.is_reviving_boss[idx][idx_j] = true

	local timer = 0
	local boss_info = self.stage_data.pattern_data[idx].boss_table[idx_j]
	local revive_time = lua_helper.get_or_default(self.stage_data.pattern_data[idx].revive_time, 5)
	local revive_hp = lua_helper.get_or_default(self.stage_data.pattern_data[idx].revive_hp, 0.5)
	local revive_tint = lua_helper.get_or_default(self.stage_data.pattern_data[idx].revive_tint, { 0.3, 0.3, 0.3})
	local revive_boss = get_character(boss_info.boss_name)
	local boss_group = lua_helper.get_or_default(self.stage_data.pattern_data[idx].boss_group, 'boss')
	local revive_boss_group = stage.BattleManager:GetBattleGroup(boss_group)

	-- 비전투 상태로 변경
	revive_boss_group:Remove(revive_boss)
	revive_boss.CharacterBehaviour:CancelAllBattleActions(true)
	revive_boss.ActiveState = active_state('visible')
	revive_boss.FieldObjectController.DontFight = true

	-- 그로기 상태 연출
	local dir_locked = false
	character_util.remove_anim(revive_boss)
	if boss_info.revive_dir ~= nil then
		dir_locked = true
		character_util.set_direction(revive_boss, boss_info.revive_dir)
		character_util.set_locked_dir(revive_boss, boss_info.revive_dir)
	end

	if boss_info.revive_anim ~= nil then
		character_util.set_anim(revive_boss, { name = boss_info.revive_anim})
	end

	revive_boss.SpineController:AddColor(boss_info.boss_name,
			unity_class.color(revive_tint[1] , revive_tint[2], revive_tint[3], 1), 1, 0.3)

	while self.is_all_dead_table[idx] == false do
		timer = timer + unity_class.time.deltaTime

		if timer >= revive_time then
			-- 플레이어가 이미 죽은 상태면 부활하지 않고 끝내기
			if user_party.Leader.CharacterStatsBehaviour.IsDead then
				break
			end

			timer = 0

			unity_object_pool.GetOrCreate('FX_levelup_new'):Instantiate(revive_boss.Position)

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
			revive_boss_group:AddToCurrentWave(revive_boss)
			revive_boss.ActiveState = active_state('enabled')
			revive_boss.FieldObjectController.DontFight = false

			-- 바로 플레이어를 Notice하도록
			message_system:Send(revive_boss.FieldObjectController, CS.Oak.MonsterNoticeEvent.Create(revive_boss,
					user_party[0], CS.Oak.MonsterNoticeLevel.Battle))
			self.is_reviving_boss[idx][idx_j] = false
			break
		end
		coroutine.yield(nil)
	end

	if dir_locked then
		character_util.reset_locked_dir(revive_boss)
	end
end

-- 보스 무적 세팅
function local_class:set_boss_immortal()
	if self.stage_data == nil or self.stage_data.pattern_data == nil then
		return
	end
	for i = 1, #self.stage_data.pattern_data do
		for j = 1, #self.stage_data.pattern_data[i].boss_table do
			local boss = get_character(self.stage_data.pattern_data[i].boss_table[j].boss_name)
			character_util.set_immortal(boss, true)
		end
	end
end

-- 동시 처치 시 동일 테이블의 모든 보스 죽임
function local_class:kill_all_boss(idx)
	for i = 1, #self.stage_data.pattern_data[idx].boss_table do
		local boss = get_character(self.stage_data.pattern_data[idx].boss_table[i].boss_name)

		character_util.remove_anim(boss)
		boss.ActiveState = active_state('enabled')
		boss.SpineController:ResetAllColors()
		character_util.set_immortal(boss, false)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.notMortal = false
		damage_info.sender = user_party.Leader
		damage_info.target = boss
		damage_info.damage = boss.CharacterStatsBehaviour.MaxHP

		command_util.execute_damage(damage_info)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_stage_loaded_event(e)
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
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
