local local_class = newclass('TowerDeactivateSharedBuffForEachWaveController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.buff_state = {
		none = 1,
		activate = 2,
		deactivate = 3
	}

	self.vfx_dispose = function(pooled_effect)
		if not is_unity_null(pooled_effect) then
			pooled_effect:Dispose()
		end
	end

	self.stage_battle_info = require('stageeventcontrollers/TowerDeactivateSharedBuffForEachWaveData.lua')

	self.current_stage_info = nil
	self.wave_battle_group = nil
	self.is_on_boss_buff = false
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	-- 이펙트 풀
	local boss_pool_name = self.current_stage_info.boss_buff_vfx
	if boss_pool_name then
		self.boss_effect_pool = unity_object_pool.GetOrCreate(boss_pool_name)
	else
		self.boss_effect_pool = nil
	end

	local share_pool_name = self.current_stage_info.share_buff_vfx
	if share_pool_name then
		self.share_effect_pool = unity_object_pool.GetOrCreate(share_pool_name)
	else
		self.share_effect_pool = nil
	end

	local range_pool_name = self.current_stage_info.share_range_vfx
	if range_pool_name then
		self.range_effect_pool = unity_object_pool.GetOrCreate(range_pool_name)
	else
		self.range_effect_pool = nil
	end

	local range_end_pool_name = self.current_stage_info.share_range_end_vfx
	if range_end_pool_name then
		self.range_end_effect_pool = unity_object_pool.GetOrCreate(range_end_pool_name)
	else
		self.range_end_effect_pool = nil
	end

	-- 보스로부터 거리 비교용 값
	self.sqr_share_area_radius = self.current_stage_info.share_area_radius * self.current_stage_info.share_area_radius

	self.wave_battle_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.battle_group_name)
	self.wave_battle_group.SpawnNextWaveAutomatically = false
	self.wave_battle_group.Enabled = self.current_stage_info.wave_start_immediate
	-- 배틀그룹 활성화 중 플레이어 파티 배틀존 존 진입시 비정상적으로 동작하는 상황 방지
	self.wave_battle_group.IgnoreZoneEvent = not self.current_stage_info.wave_start_immediate
	self.target = get_character(self.current_stage_info.boss_name)

	self.monster_init_pos = { }
	local monsters = self.wave_battle_group:GetMonsters()
	for _, monster in pairs(monsters) do
		self.monster_init_pos[monster] = monster.Position
		monster.FieldObjectController.PatrolAI = CS.Oak.PatrolAI.None
	end
	monsters:Dispose()

	-- key = 이펙트가 붙은 몬스터, value = 몬스터에 붙은 이펙트
	self.shared_monsters_dic = {}

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start(e)
	-- 타이머 스테이지 시작시 동작안함
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStopEvent.Instance)
end

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing
	self:change_buff_state(self.wave_battle_group.Enabled and self.buff_state.activate or self.buff_state.deactivate)
	local cmd = CS.Oak.MonsterNoticeCommand.Create(self.target, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
	command_util.publish_cmd(self.target.Owner, cmd)
	-- 전투 시작시 타이머 시작
	message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

	self.wave_battle_group.IgnoreZoneEvent = true
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none
end

function local_class:on_battle_group_wave_clear_event(e)
	-- 다음 웨이브 나오게
	self:change_buff_state(self.buff_state.deactivate)

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_progress == self.progress.playing then
		if e.BattleGroupName == self.current_stage_info.boss_group_name then
			-- 보스를 잡으면 몬스터를 모두 죽인다.
			self:kill_all_monsters()
			self.current_progress = self.progress.cleared
		elseif e.BattleGroupName == self.current_stage_info.battle_group_name then
			self.wave_reset_require = true
			-- 다음 웨이브 나오게
			self:change_buff_state(self.buff_state.deactivate)
		end
	end
	return true
end

-- 버프 상태 변경 함수
function local_class:change_buff_state(next_state)
	if self.current_buff_state == next_state then
		return
	end

	-- 상태 이탈 처리
	if self.current_buff_state == self.buff_state.activate then
		self:remove_boss_buff()
		-- 몬스터에 붙은 pooledUnityObject dispose
		if self.shared_monsters_dic ~= nil then
			for monster, _ in pairs(self.shared_monsters_dic) do
				self.vfx_dispose(self.shared_monsters_dic[monster])
				self.shared_monsters_dic[monster] = nil
			end
		end
	elseif self.current_buff_state == self.buff_state.deactivate and self.current_progress == self.progress.playing then
		if not self.wave_battle_group.Enabled then
			self.wave_battle_group.Enabled = true
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.current_stage_info.battle_group_name))
		elseif self.wave_reset_require then
			-- 회복되는거 안보이게 위치 999,999로 보내줌.
			self:send_monster_far()
			-- 맨 마지막 웨이브니까 배틀그룹 리셋(죽어있는 애들만 힐, BattleGroup.cs:514-565 참조)
			message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(self.current_stage_info.battle_group_name, true))
			-- 다음 웨이브 몬스터 위치 리셋
			self:reset_monster_pos(0)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.current_stage_info.battle_group_name))
			self.wave_reset_require = false
		else
			-- 다음 웨이브 몬스터 위치 리셋
			-- PublishSync이후 CurrentWave를 해도 갱신이 되어있지 않다.
			self:reset_monster_pos(self.wave_battle_group.CurrentWave + 1)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.current_stage_info.battle_group_name))
		end
	end

	-- 상태 진입 처리
	if next_state == self.buff_state.activate then
		self:add_boss_buff()
	elseif next_state == self.buff_state.deactivate then

	end

	self.current_buff_state = next_state
	self.state_time_passed = 0
end

-- 회복되는거 안보이게 몬스터 999,0,999로 보내줌
function local_class:send_monster_far()
	for monster, init_pos in pairs(self.monster_init_pos) do
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = vector(999,0,999)
		end
	end
end

-- 특정 웨이브에 속한 몬스터들중 죽어있던 애들의 위치 초기화
function local_class:reset_monster_pos(wave_num)
	local monsters = self.wave_battle_group:GetMonsters(wave_num)
	for _, monster in pairs(monsters) do
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = self.monster_init_pos[monster]

			-- notice로 새로운 BattleInstance생성을 막기 위해 기존 BattleInstance에다 재활성시 몬스터 추가.
			-- BattleManager.cs:644-665 참고
			local thebattle = stage.BattleManager:GetBattleForMyParty()
			thebattle:AddEnemy(monster)

			-- 이벤트 IsPublish안하면 MonsterBattleAIState에서 타겟이 지정안되는 오류 발생
			local cmd = CS.Oak.MonsterNoticeCommand.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
			command_util.publish_cmd(monster.Owner, cmd)
		end
	end
	monsters:Dispose()
end

function local_class:remove_boss_buff()
	if self.is_on_boss_buff then
		-- 범위 이펙트 종료
		self.vfx_dispose(self.share_range_effect)
		self.range_end_effect_pool:Instantiate(self.target.Position)

		self.vfx_dispose(self.fx_immune)
		stage.BuffManager:RemoveBuff(self.target, CS.Oak.EquipmentSlot.None, self.target, self.current_stage_info.boss_buff_name)
		self.is_on_boss_buff = false
	end
end

function local_class:add_boss_buff()
	if not self.is_on_boss_buff then
		-- 범위 이펙트 시작
		self.share_range_effect = self.range_effect_pool:Instantiate(self.target.Position,
				unity_class.quaternion.identity, self.target.Transform)

		self.fx_immune = self.boss_effect_pool:Instantiate(self.target.Position + vector(0, 0.01, 0.25),
				unity_class.quaternion.identity, self.target.Transform)
		self.fx_immune.transform.localScale = vector(1.5, 0, 1.5)
		stage.BuffManager:AddBuff(self.target, CS.Oak.EquipmentSlot.None, self.target, self.current_stage_info.boss_buff_name, 0, false, false)
		self.is_on_boss_buff = true
	end
end

-- 현재 웨이브 상태의 모든 몬스터를 죽인다.
function local_class:kill_all_monsters()
	local monsters = self.wave_battle_group:GetMonsters()
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for _, monster in pairs(monsters) do
		damage_info.sender = monster
		damage_info.target = monster
		damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

		command_util.execute_damage(damage_info)
	end
	monsters:Dispose()
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	-- 플레이 중에만 업데이트 처리
	if self.current_progress ~= self.progress.playing then
		return
	end

	if self.current_buff_state == self.buff_state.activate then
		local current_battle = stage.BattleManager:GetBattleForMyParty()
		if current_battle ~= nil then
			local enemies = current_battle.Enemies
			for i = 0, enemies.Count -1 do
				local target_character = enemies[i].Character
				if target_character ~= self.target and stage.BattleManager:IsCharacterInActiveBattle(target_character) then
					-- 전투에 속한 몬스터만 체크
					if vector_util.sqr_xz_distance(self.target.Position, target_character.Position) > self.sqr_share_area_radius then
						-- 보스 근처에 있지 않으면 버프 제거
						self.vfx_dispose(self.shared_monsters_dic[target_character])
						self.shared_monsters_dic[target_character] = nil
						if target_character.FieldObjectStatsBehaviour:IsActiveBuff(self.current_stage_info.share_buff_name) then
							stage.BuffManager:RemoveBuff(self.target, CS.Oak.EquipmentSlot.None, target_character, self.current_stage_info.boss_buff_name)
						end
					else
						-- 보스 근처에 있으면 버프 적용
						if is_unity_null(self.shared_monsters_dic[target_character]) then
							self.shared_monsters_dic[target_character] = self.share_effect_pool:Instantiate(target_character.Position,
									unity_class.quaternion.identity, target_character.Transform)
						end
						if not target_character.FieldObjectStatsBehaviour:IsActiveBuff(self.current_stage_info.share_buff_name) then
							stage.BuffManager:AddBuff(self.target, CS.Oak.EquipmentSlot.None, target_character, self.current_stage_info.share_buff_name, 0, false, false)
						end
					end
				end
			end
		end
	elseif self.current_buff_state == self.buff_state.deactivate then
		if self.state_time_passed >= self.current_stage_info.wave_interval then
			self:change_buff_state(self.buff_state.activate)
		end

		self.state_time_passed = self.state_time_passed + dt
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self.boss_effect_pool = nil
	self.share_effect_pool = nil
	self.range_effect_pool = nil
	self.range_end_effect_pool = nil

	self.shared_monsters_dic = nil

	self.current_stage_info = nil
	self.wave_battle_group = nil
	self.monster_init_pos = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
