local local_class = newclass("TowerDarkness20BuffController")

--[[ 데이터 관리 ]]
function local_class:set_data()
	--[[ 버프 관련 정보
		{
			name = (str) [Buff Name]
			level = (int) [Buff Level]
		}
		{
			heal_ratio = (float) [Heal Ratio]
		}
	]]
	self.buff_data = {
		{
			name = 'attack_up_permill_persistent',
			level = 500
		},
	}

	--[[ 버프 이펙트 관련 정보
		{
			name = (str) [PresetName]
			range = (int) [이펙트가 생성될 버프 중첩 횟수 범위]
		}
	]]
	self.preset_data = {
		{
			name = 'FX_dash',
			range = { 1, 5 },
			scale = vector(1, 1.5, 1.2)
		},
	}

	-- 최대 버프 중첩 횟수
	self.max_buff_overlap_count = 5

	-- 일반몬스터 Group Name
	self.normal_group_name = 'wave'

	-- 보스 Group Name
	self.boss_group_name = 'boss'

	-- 최대 Wave
	self.max_wave = 3
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.play_state = {
		none = 1,
		playing = 2,
		clear = 3
	}
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self:set_data()

	-- 버프 중첩 횟수
	self.buff_overlap = 0

	-- 현재 사용중인 버프 이펙트
	self.buff_effect = nil

	-- 현재 스테이트
	self.current_state = self.play_state.none

	-- 버프 추가 및 해지 등을 명시적으로 하기 위해 있을 홀더
	self.buff_holder = get_field_object('buff_holder')

	self.battle_group = stage.BattleManager:GetBattleGroup(self.normal_group_name)
	self.battle_group.SpawnNextWaveAutomatically = false

	self.monster_init_pos = { }
	local monsters = self.battle_group:GetMonsters()
	for _, monster in pairs(monsters) do
		self.monster_init_pos[monster] = monster.Position
	end

	yield_return_func(self.preset_is_loaded, self)

	return
end

--[[
	필요한 preset이 모두 로드 되었는지 체킹
]]
function local_class:preset_is_loaded()
	while true do
		local is_loaded = true

		for _, value in pairs(self.preset_data) do
			local pool= unity_object_pool.GetOrCreate(value.name)

			if not CS.Oak.UnityObjectPoolExtensions.IsLoaded(pool) then
				is_loaded = false
				break
			end
		end

		if is_loaded then
			break
		end

		coroutine.yield(nil)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)

end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.boss_group_name) then
		if self.current_state == self.play_state.none then
			self.current_state = self.play_state.playing
		end
	end
end

--[[
	FieldObjectDestroyedEvent 이벤트 처리
]]
function local_class:on_battle_group_wave_clear_event(e)

	-- 다음 웨이브 나오게
	self:set_next_wave()

	-- 버프 적용
	self:buff_apply_routine()

	return true
end

--[[
	BattleGroupEliminatedEvent 이벤트 처리
]]
function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.boss_group_name then
		self.current_state = self.play_state.clear

		-- 보스를 잡으면 몬스터를 모두 죽인다.
		self:kill_all_monsters()

		-- 버프 해지 루틴 수행
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.buff_expired_routine, self))
	elseif e.BattleGroupName == self.normal_group_name then
		-- 다음 웨이브 나오게
		self:set_next_wave()
	end

	return true
end

--[[
	적이 죽었을때, 버프 관련 처리
	FIXME: ZIWON 동시 처리 관련 루틴 추가 할 것
]]
function local_class:buff_apply_routine()
	if self.current_state ~= self.play_state.playing then
		return
	end

	if self.buff_overlap >= self.max_buff_overlap_count then
		return
	end

	-- 중첩 갱신
	self.buff_overlap = self.buff_overlap + 1

	self:update_buff_routine(true)
end

--[[
	배틀 그룹이 전멸했을때, 임시 버프 관련 처리
]]
function local_class:buff_expired_routine()
	-- destory 당시 보낸 커맨드 처리를 위해 한 프레임 쉼
	-- 같은 버프 정보에 대해서 remove부터 우선 수행하기 때문에 expire 루틴을 제대로 수행하려면 한 프레임 쉬어야한다
	coroutine.yield(nil)

	self.buff_overlap = 0

	self:update_buff_routine(false)
end

--[[
	실제 버프 갱신 처리
]]
function local_class:update_buff_routine(apply_heal)
	-- 버프, 힐 정보 순회
	for _, value in pairs(self.buff_data) do
		-- buff Routine
		if value['name'] ~= nil then
			local buff_name = value['name']
			local buff_level = value['level']

			-- 현재 stackable 기능을 쓰지 않기 때문에, 버프 해지후 새로운 레벨로 적용
			for index = 0, user_party.Count - 1 do
				local member = user_party[index]

				-- 기존에 걸어준 버프 해제
				buff_manager:RemoveBuff(
						self.buff_holder, CS.Oak.EquipmentSlot.None, member, buff_name)

				-- 새로운 버프 추가
				if buff_level * self.buff_overlap > 0 then
					buff_manager:AddBuff(self.buff_holder, CS.Oak.EquipmentSlot.None,
							member, buff_name, buff_level * self.buff_overlap, true, false)
				end
			end
		end

		-- Heal Routine (힐을 적용할 때만)
		if apply_heal and value['heal_ratio'] ~= nil then
			for index = 0, user_party.Count - 1 do
				local member = user_party[index]

				-- 파티 멤버가 죽지 않았을때 수행
				if not member.FieldObjectStatsBehaviour.IsDead then
					local heal_info = CS.Oak.HealInfo()
					heal_info.sender = nil
					heal_info.target = user_party[index]
					heal_info.heal = math.floor(user_party[index].FieldObjectStatsBehaviour.MaxHP * value['heal_ratio'])

					command_util.execute_heal(heal_info)
				end
			end
		end
	end

	self:update_buff_effect_routine()
end

--[[
	프리셋 데이터 기반으로 버프 이펙트 갱신
]]
function local_class:update_buff_effect_routine()
	-- 버프 이펙트 높이 오프셋
	local height_offset = -0.1

	-- 버프 이펙트가 생성되지 말아야할 조건에 버프 이펙트가 있을 경우
	if self.buff_overlap < self.preset_data[1].range[1] and self.buff_effect ~= nil then
		self.buff_effect:Dispose()
		self.buff_effect = nil

		return
	end

	-- 프리셋 데이터를 순회하며 이펙트 관련 정보를 체킹
	for _, value in pairs(self.preset_data) do
		-- 현재 중첩 횟수가 범위안이라면
		if value.range[1] <= self.buff_overlap and self.buff_overlap <= value.range[2] then
			-- 새로운 이펙트를 생성해야 하는지 여부
			local init_new_effect = self.buff_effect == nil

			-- 현재 버프 이펙트가 보여져야할 이펙트와 다르다면
			if self.buff_effect ~= nil and (self.buff_effect.ObjectPool.PresetName ~= value.name or
					self.buff_effect.transform.localScale ~= value.scale) then
				-- 현재 이펙트 해지
				self.buff_effect:Dispose()
				self.buff_effect = nil

				-- 새로운 이펙트를 생성해야함
				init_new_effect = true
			end

			-- 새로운 버프가 필요하다면
			if init_new_effect then
				local pool = unity_object_pool.GetOrCreate(value.name)

				-- nil check
				if pool == nil then
					return
				end

				local target_pos = user_party_leader.Position +
						user_party_leader.SpineController.SpineTotalOffset + height_offset * unity_class.vector3.up

				-- 새로운 버프 이펙트 생성
				self.buff_effect = CS.Oak.UnityObjectPoolExtensions.Instantiate(pool, target_pos,
						unity_class.vector3.back, user_party_leader.SpineController.SpineContainerTransform)

				self.buff_effect.transform.localScale = value.scale
			end

			break
		end
	end
end

function local_class:set_next_wave()
	if self.play_state.playing ~= self.current_state then
		return
	end

	if self.battle_group.CurrentWave == self.max_wave - 1 then
		-- 회복되는거 안보이게 위치 999,999로 보내줌.
		self:send_monster_far()
		-- 맨 마지막 웨이브니까 배틀그룹 리셋(죽어있는 애들만 힐, BattleGroup.cs:514-565 참조)
		message_system:PublishSync(CS.Oak.BattleGroupResetEvent.Create(self.normal_group_name, true))
		-- 위치 리셋
		self:reset_monster_pos(0)
		message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.normal_group_name))
	else
		-- 다음 웨이브 몬스터 위치 리셋
		self:reset_monster_pos(self.battle_group.CurrentWave + 1)
		message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create(self.normal_group_name))
	end
end

-- 특정 웨이브에 속한 몬스터들중 죽어있던 애들의 위치 초기화
function local_class:reset_monster_pos(wave_num)
	local monsters = self.battle_group:GetMonsters(wave_num)

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

-- 회복되는거 안보이게 몬스터 999,0,999로 보내줌
function local_class:send_monster_far()
	for monster, init_pos in pairs(self.monster_init_pos) do
		if is_unity_null(stage.BattleManager:GetBattleFor(monster)) then
			monster.Position = vector(999,0,999)
		end
	end
end

function local_class:kill_all_monsters()
	local monsters = self.battle_group:GetMonsters()
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
	-- 구독한 이벤트 해지
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	-- 생성한 이펙트 dispose
	if self.buff_effect ~= nil then
		self.buff_effect:Dispose()
		self.buff_effect = nil
	end

	self.monster_init_pos = nil
	self.battle_group = nil

	self.buff_data = nil
	self.zone_data = nil
	self.preset_data = nil
	self.buff_holder = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
