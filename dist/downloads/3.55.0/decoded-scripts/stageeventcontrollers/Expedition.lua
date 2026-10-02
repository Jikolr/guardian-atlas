local local_class = newclass("ExpeditionController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	--- 추가 리소스 로드 및 대기
	unity_object_pool.GetOrCreate('fx_expedition_party_switch')
	unity_object_pool.GetOrCreate('fx_expedition_event_wave_monster')
	unity_object_pool.GetOrCreate('fx_expedition_event_zone')
	unity_object_pool.GetOrCreate('fx_expedition_event_zone_end')
	-- 4지역 맵에서 사용하는 이펙트 프리로드
	unity_object_pool.GetOrCreate('fx_expedition_event_zone_b')
	unity_object_pool.GetOrCreate('fx_expedition_event_zone_end_b')
	unity_object_pool.GetOrCreate('fx_expedition_bomb_monster_spawn')
	unity_object_pool.GetOrCreate('fx_expedition_bomb_monster_alert')
	unity_object_pool.GetOrCreate('fx_expedition_bomb_monster_explosion')
	unity_object_pool.GetOrCreate('expedition_title')

	music_player:PreloadSfx("01_guild_warp_01")
	music_player:PreloadSfx("02_stomp_fire_02")
	music_player:PreloadSfx("02_octo_explosion_01")
	music_player:PreloadSfx("02_die_graboid_01")
	music_player:PreloadSfx("01_creature_01")
	music_player:PreloadSfx("02_lord_explosion_01")
	music_player:PreloadSfx("01_explosion_gas_02")
	music_player:PreloadSfx("01_princess_magic_03")
	music_player:PreloadSfx("02_princess_shoot_01")
	music_player:PreloadSfx("01_cast_rune_01")
	music_player:PreloadSfx("02_spider_appear_01")
	music_player:PreloadSfx('01_mirror_witch_01')

	CS.Oak.ExpeditionDropOrb.PreLoad('fx_expedition_orb_orange_lv1', 'fx_expedition_orb_orange_lv2', 'fx_expedition_orb_orange_lv3', 'fx_expedition_orb_get_orange')
	CS.Oak.ExpeditionSwitchingDropOrb.PreLoad('fx_expedition_switching_orb', 'fx_expedition_get_switching_orb')

	-- 런치루틴 제거하여 이 시점에 이벤트 구독하도록 함.
	message_system:Subscribe(self, typeof(CS.Oak.ExpeditionEndEvent), 'on_expedition_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExpeditionClearStateReceivedEvent), 'on_clear_state_received_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent), 'on_monster_spawned_event')

	if stage.StageSpec.BossId > 0 then
		self.check_boss_destroy = true
	end

	return
end

function local_class:on_expedition_end_event(e)
	local play_result = e.PlayResult

	if play_result == CS.Oak.ExpeditionStage.Result.TimeOutClear then
		local active_monster_list = {}

		for _,v in pairs(e.ActiveMonsterList) do
			if not stage.BattleManager:IsBoss(v) then
				table.insert(active_monster_list, v)
			end
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.time_out_clear_routine, self, active_monster_list))
	elseif play_result == CS.Oak.ExpeditionStage.Result.TimeOutFail then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.time_out_fail_routine, self))
	elseif play_result == CS.Oak.ExpeditionStage.Result.Clear then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.clear_routine, self))
	elseif play_result == CS.Oak.ExpeditionStage.Result.Defeated then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_routine, self))
	end
end

function local_class:on_clear_state_received_event(e)
	self.clear_state = e.ClearState
end

function local_class:on_monster_spawned_event(e)
	-- 얼음정령 등장 사운드
	if e.Spec.EventType == CS.Oak.ExpeditionMonsterEventType.Freezer then
		local sfx_info = CS.Oak.SfxInfo()
		sfx_info.sfxName = '01_mirror_witch_01'
		sfx_info.playPosition = e.Position
		music_player:PlaySfx(sfx_info)
	end
end

function local_class:on_dying_end_event(e)
	if self.explosion_state_fo and lua_helper.reference_equals(e.character, self.explosion_state_fo) then
		self.explosion_state_fo = nil
	end
end

function local_class:wait_til_dying_end()
	local monsters = character_manager:GetAllMonsters()
	self.explosion_state_fo = nil
	local count = monsters.Count
	local index = 0

	--- 보스 사망 연출 대기
	local get_boss = function()
		while index < count do
			local monster = monsters[index]
			index = index + 1
			if monster.CharacterBehaviour.CurrentState:GetType() == typeof(CS.Oak.CharacterBossExplosionState)
					and monster.ActiveState == CS.Oak.ActiveState.Enabled then
				return monster
			end
		end
	end

	message_system:Subscribe(self, typeof(CS.Oak.DyingEndEvent), 'on_dying_end_event')
	repeat
		while self.explosion_state_fo ~= nil do
			if self.explosion_state_fo.ActiveState ~= CS.Oak.ActiveState.Enabled then
				self.explosion_state_fo = nil
			end
			coroutine.yield(nil)
		end
		self.explosion_state_fo = get_boss()
	until self.explosion_state_fo == nil
	message_system:Unsubscribe(self, typeof(CS.Oak.DyingEndEvent))
end

function local_class:time_out_clear_routine(active_monster_list)
	coroutine.yield(nil)

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)
	music_player:PlaySfxOneShot("01_whistle_01")

	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	--- FIXME: 현재 사용중인 파티 0번
	local party = CS.Oak.PartyManager.Instance[0]
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character then
			--- 타임오버시에 죽는 것을 방지
			character_util.set_immortal(character, true)

			--- 디버프 및 상태이상 제거
			message_system:SendSync(character, CS.Oak.CharacterAilmentResetEvent.Instance)
			buff_manager:CureAllDebuffs(character, character)
		end
	end

	coroutine.yield(nil)

	for _,fo in pairs(active_monster_list) do
		if fo.DamagedBehaviour.ShowDamageNumber ~= nil then
			fo.DamagedBehaviour.ShowDamageNumber = false
		else
			CS.UnityEngine.Debug.LogError('[Expedition] fo: '.. fo.Name ..'damageBehaviour is different.')
		end

		--- 타임오버시에 죽는 것을 방지
		character_util.set_immortal(fo, true)

		CS.Oak.CharacterControllerScreenplayState.Stop(fo)
	end

	--- 타임아웃 타이틀
	local pool = unity_object_pool.GetOrCreate('expedition_title')

	local garage_title = pool:Instantiate(vector(0, 100, 0))

	garage_title.transform.parent = stage.UIRoot.transform
	garage_title.transform.localPosition = vector(0, 100,0)
	garage_title.transform.localScale = unity_class.vector3.one

	local garage_title_component = garage_title:GetComponent(typeof(CS.Oak.UIGarageTitle))

	garage_title_component:Show(CS.Oak.UIGarageTitle.GarageTitleType.TimeOver)

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	--- 현재 나와있는 몬스터 전부 제거, 보스 제외
	for _,fo in pairs(active_monster_list) do
		--- 무적 설정돼 있더라도 DamageType이 Death면 죽지만, 일단 무적 품
		character_util.set_immortal(fo, false)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = fo
		damage_info.target = fo
		damage_info.damage = fo.CharacterStatsBehaviour.MaxHP

		command_util.execute_damage(damage_info)
	end

	coroutine.yield(coroutine_class.wait_for_sec(1.7))

	--- 임시 위치 조정
	local direction = direction_util.to_side_dir(direction_util.get_opposite(party.Leader.Direction))
	local direction_vector = direction_util.to_vector3(direction)
	local align_pos = party.Leader.Position - direction_vector

	--- 파티 정렬
	coroutine.yield(party:AlignPartyNew(align_pos, direction, 1, CS.Oak.Party.AlignType.Arc))

	music_player:PlaySfxOneShot("03_activity_clear_01")
	music_player:PlaySfxOneShot("01_stage_intro_jump_01")
	for i = 0, party.Count - 1 do
		local character = party[i]

		character_util.set_anim_and_emotion(character,
				{name = 'victory_get', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
				{name = 'smile', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
	end

	--- victory_get 시간 1.233
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	while self.clear_state == nil do
		coroutine.yield(nil)
	end

	--- 결과창 표시
	ui_scene_manager:PushOverlay(CS.Oak.UI.ExpeditionStageClear.Instance, self.clear_state, typeof(CS.Oak.UI.ExpeditionStageClear))
	self.clear_state = nil
end

function local_class:time_out_fail_routine()
	coroutine.yield(nil)

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)
	music_player:PlaySfxOneShot("01_drown_02")

	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	local party = CS.Oak.PartyManager.Instance[0]
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character and not character.FieldObjectStatsBehaviour.IsDead
				and (character.ActiveState & CS.Oak.ActiveState.InField) ~= 0
				and CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(character, typeof(CS.Oak.Character))then
			--- 타임오버시에 죽는 것을 방지
			character_util.set_immortal(character, true)

			--- 디버프 및 상태이상 제거
			message_system:SendSync(character, CS.Oak.CharacterAilmentResetEvent.Instance)
			buff_manager:CureAllDebuffs(character, character)

			character_util.set_direction(character, direction_util.to_side_dir(character.Direction))
			character_util.set_anim_and_emotion(character,
					{name = 'hurt', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
					{name = 'tired', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(0.3))

	--- 게임오버 타이틀
	local pool = unity_object_pool.GetOrCreate('expedition_title')

	local garage_title = pool:Instantiate(vector(0, 100, 0))

	garage_title.transform.parent = stage.UIRoot.transform
	garage_title.transform.localPosition = vector(0, 100,0)
	garage_title.transform.localScale = unity_class.vector3.one

	local garage_title_component = garage_title:GetComponent(typeof(CS.Oak.UIGarageTitle))

	garage_title_component:Show(CS.Oak.UIGarageTitle.GarageTitleType.GameOver)

	--- 타이틀 재생 최대 시간 2.4
	coroutine.yield(coroutine_class.wait_for_sec(2.7))

	--- 결과창 표시
	ui_scene_manager:PushOverlay(CS.Oak.UI.ExpeditionStageClear.Instance, self.clear_state, typeof(CS.Oak.UI.ExpeditionStageClear))
	self.clear_state = nil
end

function local_class:clear_routine()
	coroutine.yield(nil)

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)

	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	local party = CS.Oak.PartyManager.Instance[0]
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character then
			--- 타임오버시에 죽는 것을 방지
			character_util.set_immortal(character, true)

			--- 디버프 및 상태이상 제거
			message_system:SendSync(character, CS.Oak.CharacterAilmentResetEvent.Instance)
			buff_manager:CureAllDebuffs(character, character)
		end
	end

	--- 팡파레 사운드 종료 대기
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	coroutine.yield(self:wait_til_dying_end())

	--- 위치 조정
	local direction = direction_util.to_side_dir(direction_util.get_opposite(party.Leader.Direction))
	local direction_vector = direction_util.to_vector3(direction)
	local align_pos = party.Leader.Position - direction_vector

	--- 파티 정렬
	coroutine.yield(party:AlignPartyNew(align_pos, direction, 1, CS.Oak.Party.AlignType.Arc))

	music_player:PlaySfxOneShot("03_activity_clear_01")
	music_player:PlaySfxOneShot("01_stage_intro_jump_01")
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character and CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(character, typeof(CS.Oak.Character)) then
			character_util.set_direction(character, direction_util.to_side_dir(character.Direction))
			character_util.set_anim_and_emotion(character,
					{name = 'victory_get', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
					{name = 'smile', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
		end
	end

	--- victory_get 시간 1.233
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	while self.clear_state == nil do
		coroutine.yield(nil)
	end

	--- 결과창 표시
	ui_scene_manager:PushOverlay(CS.Oak.UI.ExpeditionStageClear.Instance, self.clear_state, typeof(CS.Oak.UI.ExpeditionStageClear))
	self.clear_state = nil
end

function local_class:defeat_routine()
	music_player:PlaySfxOneShot("01_hit_npc_01")

	coroutine.yield(nil)

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)
	music_player:PlaySfxOneShot("01_drown_02")

	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	local party = CS.Oak.PartyManager.Instance[0]
	for i = 0, party.Count - 1 do
		local character = party[i]

		if character and not character.FieldObjectStatsBehaviour.IsDead
				and (character.ActiveState & CS.Oak.ActiveState.InField) ~= 0
				and CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(character, typeof(CS.Oak.Character))then
			--- 타임오버시에 죽는 것을 방지
			character_util.set_immortal(character, true)

			--- 디버프 및 상태이상 제거
			message_system:SendSync(character, CS.Oak.CharacterAilmentResetEvent.Instance)
			buff_manager:CureAllDebuffs(character, character)

			character_util.set_direction(character, direction_util.to_side_dir(character.Direction))
			character_util.set_anim_and_emotion(character,
					{name = 'hurt', priority = CS.Oak.AnimationPriorities.Custom, loop = false},
					{name = 'tired', priority = CS.Oak.AnimationPriorities.Custom, loop = false})
		end
	end

	--- 리더 사망 모션 최대 시간 2.367
	coroutine.yield(coroutine_class.wait_for_sec(2.5))

	--- 결과창 표시
	ui_scene_manager:PushOverlay(CS.Oak.UI.ExpeditionStageClear.Instance, self.clear_state, typeof(CS.Oak.UI.ExpeditionStageClear))
	self.clear_state = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	-- 이벤트 리스너 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionClearStateReceivedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DyingEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))

	self.scene = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
