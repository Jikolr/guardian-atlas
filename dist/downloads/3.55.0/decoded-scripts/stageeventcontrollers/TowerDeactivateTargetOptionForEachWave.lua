local local_class = newclass('TowerDeactivateTargetOptionForEachWave')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 웨이브 카운팅용
	self.wave_count = 1

	-- 웨이브 그룹 이름
	self.wave_group_name = 'wave'

	-- 현재 타겟의 인덱스
	self.current_target_index = 1

	-- 옵션이 정지될 때의 이팩트 이름
	self.deactivate_effect_name = 'fx_obj_event_curse_debuff'

	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- Key : 스테이지 이름
	-- target_name : 옵션을 정지시켜줄 타겟의 이름들 교체해줄 순서대로 넣는다.
	-- deactivate_option_id_list : 정지시켜줄 옵션 Id 리스트 만약 캐릭터를 교체하는 것이라면 change_target로 기입
	-- battle_group_name : 배틀 그룹 이름
	-- battle_zone_name : 배틀 존 이름
	]]--
	self.stage_battle_info = {
		tower_fire_20 = {
			target_names = {
				'invader_director_boss_constant',
				'invader_director_boss',
			},
			deactivate_option_id_list = {
				'change_target',
				200001,
				400003,
				200010,
			},
			battle_group_name = 'boss',
			battle_zone_name = 'boss',
		},
	}

	self.current_stage_info = nil
	self.wave_battle_group = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.deactivate_effect_name)
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.current_target_index = 1

	self.wave_battle_group = stage.BattleManager:GetBattleGroup('wave')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_battle_group_wave_clear_event(e)
	-- 정지해줄 옵션 리스트가 웨이브 카운트보다 작으면 리턴
	if #self.current_stage_info.deactivate_option_id_list < self.wave_count then return false end

	-- 타겟의 옵션을 정지시켜주는 루틴 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.deactivate_target_option, self, self.current_stage_info.deactivate_option_id_list[self.wave_count]))
	self.wave_count = self.wave_count + 1

	-- 특수 케이스 체크
	self:check_special_case()

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	-- 웨이브 마지막이므로 마지막 인덱스에 맞는 옵션을 정지시켜준다.
	if e.BattleGroupName == self.wave_group_name then
		self.wave_count = #self.current_stage_info.deactivate_option_id_list
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.deactivate_target_option, self, self.current_stage_info.deactivate_option_id_list[self.wave_count]))
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_stage_info == nil then return false end

	-- 타겟이 죽었을 때 모든 몬스터 제거 및 모든 배틀을 종료시킨다
	local target = get_character(self.current_stage_info.target_names[self.current_target_index])
	if lua_helper.reference_equals(target, e.FieldObject) then
		self:kill_all_monsters()
		stage.BattleManager:ForceEndBattles()
	end
end

-- 특수 케이스 확인 후 처리
function local_class:check_special_case()
	local stage_name = stage.Name

	-- tower_fire_20이면서 3번째 wave일 때
	if stage_name == 'tower_fire_20' and self.wave_count == 3 then
		-- 웨이브에 소속된 몬스터들을 특정 좌표안으로 이동시킨다.
		local wave_monster_first_name = 'wave_3_'
		local positions = {
			vector(-3.5, 0, 28.5),
			vector(-1.5, 0, 29.5),
			vector(2.5, 0, 29.5),
			vector(4.5, 0, 28.5),
			vector(0.5, 0, 30),
		}

		for i = 1, 5 do
			local monster = get_character(wave_monster_first_name .. i)

			character_util.set_position(monster, positions[i])
			local cmd = CS.Oak.MonsterNoticeCommand.Create(monster, user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
			command_util.publish_cmd(monster.Owner, cmd)
		end
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

function local_class:deactivate_target_option(option_id)
	-- 타겟들 가져오기
	local targets = {}
	local target_count = #self.current_stage_info.target_names
	for i = 1, #self.current_stage_info.target_names do
		local target = get_character(self.current_stage_info.target_names[i])
		table.insert(targets, target)
	end

	-- 타겟들 stage_options 가져오기
	local stage_options = {}
	for i = 1, target_count do
		stage_options[i] = targets[i].FieldObjectBehaviour.StageOptions
	end

	-- 보스 디버프 이팩트 연출
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.monster_lost_power, self, targets[self.current_target_index]))

	-- 옵션 id가 change_target 일경우에는 보스 교체 함수로
	if option_id == 'change_target' then
		self:target_change(targets)
		return
	end

	-- 거대화일 경우에는 크기 조정
	if option_id == 200010 then
		local time_passed = 0
		local duration = 0.3
		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime
			local progress = (time_passed / duration)

			targets[self.current_target_index]:SetGiantFactor('elite_stat', 1.3 - 0.3 * progress)

			coroutine.yield(nil)
		end
	end

	-- 타겟 옵션 정지
	for i = 1, target_count do
		for j = 0, stage_options[i].Count - 1 do
			if stage_options[i][j].Option.Id == option_id then
				stage_options[i][j]:Deactivate()
			end
		end
	end

end

-- 타겟을 변경해주는 함수 다음 인덱스의 타겟으로 몬스터를 변경한다.
function local_class:target_change(targets)
	-- current_target_index가 타겟의 count보다 클 경우 값이 벗어나니 아무것도 하지 않고 리턴
	if #targets < self.current_target_index then return end

	local hide_target_index = self.current_target_index
	local show_target_index = self.current_target_index + 1

	-- show_target_index가 타겟의 count보다 클 경우 값이 벗어나니 아무것도 하지 않고 리턴
	if #targets < show_target_index then return end

	-- 이전 타겟의 디버프들을 지워준다. (부상 등의 디버프가 남아있다면 밖으로 날라가도 데미지를 받기에)
	targets[hide_target_index].FieldObjectStatsBehaviour:RemoveAllDebuffs(targets[hide_target_index])

	-- 교체될 타겟의 Hp를 이전 타겟의 Hp 비율에 맞춰 조정해준다.
	local current_hp = targets[show_target_index].FieldObjectStatsBehaviour.MaxHP * targets[hide_target_index].FieldObjectStatsBehaviour.HpRatio
	targets[show_target_index].CharacterStatsBehaviour:ChangeHpToFixedValue(math.floor(current_hp))

	-- 다음 타겟 타겟의 알파값을 끄고
	character_util.convert_to_npc(targets[show_target_index])
	character_util.spine_set_alpha_fade(targets[show_target_index], 0, 0)
	targets[show_target_index].Position = targets[hide_target_index].Position

	-- 등장과 동시에 현재 타겟 그룹에 배치
	character_util.spine_set_alpha_fade(targets[hide_target_index], 0, 0.5)
	character_util.spine_set_alpha_fade(targets[show_target_index], 1, 0.5)
	wait_for_sec(1)
	character_util.convert_to_monster(targets[show_target_index], self.current_stage_info.battle_group_name, self.current_stage_info.battle_zone_name)

	-- 기존 타겟은 999로 날려보내고 disabled 시켜준다.
	character_util.set_position(targets[hide_target_index], vector(999, 0, 999))
	character_util.set_active_state(targets[hide_target_index], 'disabled')

	-- 새로운 타겟에게 전투 알림
	local cmd = CS.Oak.MonsterNoticeCommand.Create(targets[show_target_index], user_party_leader, CS.Oak.MonsterNoticeLevel.Battle)
	command_util.publish_cmd(targets[show_target_index].Owner, cmd)

	-- 이전 타겟을 마지막으로 쳤으면서 바뀔 타겟의 레벨이 더 낮으면 TopHpBar가 변경되지 않으므로 제거했다가 다시 세팅해준다.
	field_ui_manager:RemoveUI(user_party_leader, CS.Oak.FieldUiType.TopHpBar)

	-- 현재 타겟 인덱스 ++
	self.current_target_index = self.current_target_index + 1

	coroutine.yield(nil)
	coroutine.yield(nil)

	-- 기존 타겟을 비전투 상태로 돌입 시키고 배틀 그룹에서 제외 시킨다.
	local target_battle_group = stage.BattleManager:GetBattleGroup(self.current_stage_info.battle_group_name)
	target_battle_group:Remove(targets[hide_target_index])
	targets[hide_target_index].CharacterBehaviour:CancelAllBattleActions(true)
	targets[hide_target_index].FieldObjectController.DontFight = true

	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.TopHpBar)
end

function local_class:monster_lost_power(target)
	local effect = unity_object_pool.GetOrCreate(self.deactivate_effect_name):Instantiate(target.Position, unity_class.quaternion.identity, target.Transform)
	effect.transform.localScale = vector(2, 2, 2)

	music_player_util.play_sfx_one_shot('01_fade_out_01')

	wait_for_sec(2)

	effect:Dispose()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	self.current_stage_info = nil
	self.wave_battle_group = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
