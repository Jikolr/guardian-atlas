local local_class = newclass('TowerDeactivateInvincibilityForEachWave')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	-- 웨이브 카운팅용
	self.wave_count = 1

	-- 현재 타겟의 인덱스
	self.current_target_index = 1

	-- 무적버프
	-- 오브젝트 풀
	self.get_fx_immune = function() return unity_object_pool.GetOrCreate('fx_abnormal_immune_all') end
	self.fx_immune_dispose = function()
		if not is_unity_null(self.fx_immune) then
			self.fx_immune:Dispose()
		end
	end

	self.boss_buff_name = 'persistent_no_damage'

	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- boss_name : 무적 버프를 받는 보스 이름
	-- battle_group_name : 웨이브 배틀 그룹 이름
	-- battle_zone_name : 배틀 존 이름
	-- wave_interval : 웨이브 생성 간격
	-- last_wave_index : 웨이브 수
	]]--
	self.stage_battle_info = {
		tower_ice_30 = {
			boss_name = 'boss_nine_tailed_fox',
			battle_group_name = 'wave',
			boss_group_name = 'boss',
			wave_interval = 10,
			last_wave_index = 1
		},
		tower_135 = {
			boss_name = 'boss_1',
			battle_group_name = 'wave',
			boss_group_name = 'boss',
			wave_interval = 8.5,
			last_wave_index = 1
		}
	}

	self.current_stage_info = nil
	self.wave_battle_group = nil
	self.is_on_boss_buff = false
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.current_target_index = 1

	self.wave_battle_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.battle_group_name)
	self.wave_battle_group.SpawnNextWaveAutomatically = false
	self.target = get_character(self.current_stage_info.boss_name)

	self.monster_init_pos = { }
	local monsters = self.wave_battle_group:GetMonsters()
	for _, monster in pairs(monsters) do
		self.monster_init_pos[monster] = monster.Position
		monster.FieldObjectController.PatrolAI = CS.Oak.PatrolAI.None
	end

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

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing
	self:add_boss_buff()
	local cmd = CS.Oak.MonsterNoticeCommand.Create(self.target, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
	command_util.publish_cmd(self.target.Owner, cmd)
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none
end

function local_class:on_battle_group_wave_clear_event(e)
	-- 다음 웨이브 나오게
	self:set_next_wave()

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_progress == self.progress.playing then
		if e.BattleGroupName == self.current_stage_info.boss_group_name then
			-- 보스를 잡으면 몬스터를 모두 죽인다.
			self:kill_all_monsters()
			self.current_progress = self.progress.cleared
		elseif e.BattleGroupName == self.current_stage_info.battle_group_name then
			-- 다음 웨이브 나오게
			self:set_next_wave()
		end
	end
	return true
end

function local_class:set_next_wave()
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.spawn_wave_monster_routine, self,
					self.current_stage_info.wave_interval,
			self.current_stage_info.battle_group_name))
end

function local_class:spawn_wave_monster_routine(time, group_name)
	self:remove_boss_buff()

	wait_for_sec(time)

	if self.current_progress == self.progress.playing then
		self:add_boss_buff()
		if self.wave_battle_group.CurrentWave == self.current_stage_info.last_wave_index - 1 then
			-- 회복되는거 안보이게 위치 999,999로 보내줌.
			self:send_monster_far()
			-- 맨 마지막 웨이브니까 배틀그룹 리셋(죽어있는 애들만 힐, BattleGroup.cs:514-565 참조)
			message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(
					self.current_stage_info.battle_group_name, true))
			-- 위치 리셋
			self:reset_monster_pos(0)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(group_name))
		else
			-- 다음 웨이브 몬스터 위치 리셋
			self:reset_monster_pos(self.wave_battle_group.CurrentWave + 1)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(group_name))
		end
	end
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
end

function local_class:remove_boss_buff()
	if self.is_on_boss_buff then
		self.fx_immune_dispose()
		stage.BuffManager:RemoveBuff(self.target, CS.Oak.EquipmentSlot.None, self.target, self.boss_buff_name)
		self.is_on_boss_buff = false
	end
end

function local_class:add_boss_buff()
	if not self.is_on_boss_buff then
		self.fx_immune = self.get_fx_immune():Instantiate(self.target.Position + vector(0, 0.01, 1.85),
				unity_class.quaternion.identity, self.target.Transform)
		self.fx_immune.transform.localScale = vector(2.8, 0, 2.85)
		stage.BuffManager:AddBuff(self.target, CS.Oak.EquipmentSlot.None, self.target, self.boss_buff_name, 0, false, false)
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
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

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
