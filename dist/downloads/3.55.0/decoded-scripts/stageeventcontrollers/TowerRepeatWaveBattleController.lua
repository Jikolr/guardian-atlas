local local_class = newclass('TowerRepeatWaveBattleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = {
		tower_darkness_50 = {
			boss_group_name = 'boss',
			battle_group_name = 'wave',
			last_wave_index = 3,
			wave_duration = 30,
			wave_interval = 10
		},
		tower_115 = {
			boss_group_name = 'boss',
			battle_group_name = 'wave',
			last_wave_index = 3,
			wave_duration = 30,
			wave_interval = 5
		},
		herotower_kamael_5 = {
			boss_group_name = 'boss',
			battle_group_name = 'wave',
			last_wave_index = 2,
			wave_duration = 20,
			wave_interval = 3,
			contains_group_name = 'boss'
		}
}

	-- 시간 경과 변수
	self.boss = nil
	self.time_passed = 0
	self.current_stage_info = nil
	self.wave_battle_group = nil
	self.is_spawn_wave = false
	self.is_clear_wave = false
	self.monster_init_pos = {}
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'timeover')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_stage_loaded_event(_)
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.wave_battle_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.battle_group_name)
	self.wave_battle_group.SpawnNextWaveAutomatically = false

	self.monster_init_pos = {}
	local monsters = self.wave_battle_group:GetMonsters()
	for _, monster in pairs(monsters) do
		self.monster_init_pos[monster] = monster.Position
		monster.FieldObjectController.PatrolAI = CS.Oak.PatrolAI.None
	end

	local boss_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.boss_group_name)
	self.boss = boss_group:GetMonsters()
	return
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_progress == self.progress.playing then
		if e.BattleGroupName == self.current_stage_info.boss_group_name then
			-- 보스를 잡으면 몬스터를 모두 죽인다.
			self:kill_all_monsters()
			self.current_progress = self.progress.cleared
		elseif e.BattleGroupName == self.current_stage_info.battle_group_name then
			-- 다음 웨이브 나오게
			self.is_clear_wave = true
			self.is_spawn_wave = false
			self.time_passed = 0
		end
	end
	return true
end

function local_class:on_battle_group_wave_clear_event(e)
	self.is_clear_wave = true
	self.is_spawn_wave = false
	self.time_passed = 0
end

function local_class:on_battle_start_event(e)
	if self.current_progress == self.progress.playing then
		return
	end

	local battle = e.StartedBattle

	--- 웨이브가 특정 배틀 그룹을 타겟으로 한다면 여기서 배틀존을 체크해준다.
	if self.current_stage_info.contains_group_name then
		local contains_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.contains_group_name):GetMonsters()
		local is_contains = false

		--- 이벤트의 배틀이 배틀 그룹의 인원을 하나라도 포함하고 있는지 체크
		for _, monster in pairs(contains_group) do
			if CS.Oak.BattleCharacterStatusExtensions.Contains(battle.Enemies, monster) then
				is_contains = true
				break
			end
		end

		if not is_contains then
			return
		end
	end

	self.current_progress = self.progress.playing
	self.is_spawn_wave = true
end

function local_class:on_battle_end_event(e)
	if self.current_progress ~= self.progress.playing then return end
	self.current_progress = self.progress.none
end

function local_class:timeover(e)
	if e.TimerId ~= CS.Oak.GlobalTimerId.SingleGameTimer or not e.IsComplete then return end
	local a = stage.BattleManager:GetBattleFor(user_party_leader)
	self:current_wave_kill_monster()
	for _,v in pairs(self.boss) do
		v.CharacterBehaviour:CancelAllBattleActions(true)
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end
	if self.is_spawn_wave then
		if self.time_passed >= self.current_stage_info.wave_duration then
			self:current_wave_kill_monster()
			self.time_passed = 0
		else
			self.time_passed = self.time_passed + dt
		end
	end

	if self.is_clear_wave then
		if self.time_passed >= self.current_stage_info.wave_interval then
			self:set_next_wave()
			self.is_clear_wave = false
			self.time_passed = 0
		else
			self.time_passed = self.time_passed + dt
		end
	end
end

function local_class:set_next_wave()
	if self.current_progress == self.progress.playing then
		if self.wave_battle_group.CurrentWave == self.current_stage_info.last_wave_index - 1 then
			-- 회복되는거 안보이게 위치 999,999로 보내줌.
			self:send_monster_far()
			message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(
					self.current_stage_info.battle_group_name, true))
			-- 위치 리셋
			self:reset_monster_pos(0)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.current_stage_info.battle_group_name))
		else
			-- 다음 웨이브 몬스터 위치 리셋
			self:reset_monster_pos(self.wave_battle_group.CurrentWave + 1)
			message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.current_stage_info.battle_group_name))
		end
	end

	self.is_spawn_wave = true
end

-- 특정 웨이브에 속한 몬스터들중 죽어있던 애들의 위치 초기화
function local_class:reset_monster_pos(wave_num)
	local monsters = self.wave_battle_group:GetMonsters(wave_num)

	for _, monster in pairs(monsters) do
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = self.monster_init_pos[monster]
			local thebattle = stage.BattleManager:GetBattleForMyParty()
			thebattle:AddEnemy(monster)
			local cmd = CS.Oak.MonsterNoticeCommand.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
			command_util.publish_cmd(monster.Owner, cmd)
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

function local_class:current_wave_kill_monster()
	local monsters = self.wave_battle_group:GetMonsters(self.wave_battle_group.CurrentWave)
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for _, monster in pairs(monsters) do
		if not monster.FieldObjectStatsBehaviour.IsDead then
			damage_info.sender = monster
			damage_info.target = monster
			damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

			command_util.execute_damage(damage_info)
		end
	end
end

-- 현재 웨이브 상태의 모든 몬스터를 죽인다.
function local_class:kill_all_monsters()
	local monsters = self.wave_battle_group:GetMonsters()
	local current_wave_monsters = self.wave_battle_group:GetMonsters(self.wave_battle_group.CurrentWave)
	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	for _, monster in pairs(monsters) do
		if not monster.FieldObjectStatsBehaviour.IsDead then
			--현재 웨이브가 아닌 몬스터는 죽는이펙트가 안보이도록 멀리 보냄
			if not current_wave_monsters:Contains(monster) then
				monster.Position = vector(999, 0, 999)
			end

			damage_info.sender = monster
			damage_info.target = monster
			damage_info.damage = monster.FieldObjectStatsBehaviour.MaxHP * 2

			command_util.execute_damage(damage_info)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

	self.current_stage_info = nil
	self.current_progress = nil
	self.wave_battle_group = nil
	self.monster_init_pos = nil
	self.boss = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
