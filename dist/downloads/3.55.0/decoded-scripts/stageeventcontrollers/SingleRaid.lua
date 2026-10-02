local local_class = newclass("SingleRaidController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	self.boss_hashset = create_generic_hashset(CS.Oak.IFieldObject)
	local monster_list = character_manager:GetAllMonsters()

	for _, character in pairs(monster_list) do
		if character ~= nil and stage.BattleManager:IsBoss(character) == true then
			self.boss_hashset:Add(character)
		end
	end

	self.dying_end = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SingleRaidEndEvent), 'on_single_raid_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.DyingEndEvent), 'on_dying_end_event')

	-- FIX: 레이드 프레임 AI 이슈로 60프레임 제한
	local frame_rate = CS.UnityEngine.Application.targetFrameRate
	if frame_rate > 60 then
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	return
end

-- 중간에 옵션창에서 프레임 바꿨을 경우 처리를 위해 updateFrame 추가
function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	-- 프레임 레이트 60 초과로 설정 됐을 경우 다시 강제로 60으로 낮춤
	local frame_rate = CS.UnityEngine.Application.targetFrameRate
	if frame_rate > 60 then
		CS.UnityEngine.Application.targetFrameRate = 60
	end


end

function local_class:on_event(e)
	return false
end

-- single raid 가 끝났을때 처리할 이벤트
function local_class:on_single_raid_end_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.raid_end_routine, self, e.PlayResult, e.Damages, e.RemainBossHp, e.RemainTime, e.PrevChallengeHighestScore, e.SingleRaidResult, e.RuleScoreRate, e.IsLeaderDead))
end

function local_class:on_dying_end_event(e)
	local character = e.character
	if character == nil or character.FieldObjectStatsBehaviour.IsDead == false then return false end

	if self:remove_monster(character) == true and self.boss_hashset.Count <= 0 then
		self.dying_end = true
		return false

	end

	if self.boss_hashset.Count > 0 then
		local is_boss_all_dead = true
		for _, boss in pairs(self.boss_hashset) do
			if boss.FieldObjectStatsBehaviour.IsDead == false then
				is_boss_all_dead = false
				break;
			end
		end

		if is_boss_all_dead == true then
			self.dying_end = true
		end
	end
	return false
end

-- single raid 가 끝날을때 연출 루틴
function local_class:raid_end_routine(playResult, damages, remain_hp, remain_time, prev_challenge_highest_socre, single_raid_result, rule_score_rate, is_leader_dead)
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)

	--- 모든 일반 몬스터 처리
	local monsters = character_manager:GetAllMonsters()
	for i = 0, monsters.Count - 1 do
		local monster = monsters[i]

		if not stage.BattleManager:IsBoss(monster) then
			monster.DamagedBehaviour.ShowDamageNumber = false
			local damage_info = CS.Oak.DamageInfo()

			damage_info.type = CS.Oak.DamageType.Death
			damage_info.sender = monster
			damage_info.target = monster
			damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

			command_util.execute_damage(damage_info)
		end
	end

	stage.FieldUIManager:Hide()
	user_party:StopAndDisableControl()
	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	--- 파티 캐릭터 엔티티를 바꿔 재인식 방지
	for i = 0, user_party.Count - 1 do
		local character = user_party[i]

		if character then
			character.EntityGroup = CS.Oak.EntityGroups.Enemy;
		end
	end

	if (playResult == CS.Oak.SingleRaidPlayResult.TimeOut) then
		music_player:PlaySfxOneShot("01_drown_02")

		for i = 0, user_party.Count - 1 do
			local party_member = user_party[i]
			character_util.set_direction(party_member, CS.Oak.DirectionExtensions.GetSideDirection(party_member.Direction))
			character_util.set_anim(party_member, {name = "seat", loop = false})
			character_util.set_emotion(party_member, {name = "tired", loop = false})
		end

		coroutine.yield(coroutine_class.wait_for_sec(1.7))

		local pool = unity_object_pool.GetOrCreate('garage_title')

		local garage_title = pool:Instantiate(vector(0, 100, 0))

		garage_title.transform.parent = stage.UIRoot.transform
		garage_title.transform.localPosition = vector(0, 100,0)
		garage_title.transform.localScale = unity_class.vector3.one

		local garage_title_component = garage_title:GetComponent(typeof(CS.Oak.UIGarageTitle))

		garage_title_component:Show(CS.Oak.UIGarageTitle.GarageTitleType.TimeOver)

		coroutine.yield(coroutine_class.wait_for_sec(0.4))

	elseif (playResult == CS.Oak.SingleRaidPlayResult.Defeat) then
		for i = 1, user_party.Count - 1 do
			local party_member = user_party[i]
			character_util.set_direction(party_member, CS.Oak.DirectionExtensions.GetSideDirection(party_member.Direction))
			character_util.set_anim(party_member, {name = "seat", loop = false})
			character_util.set_emotion(party_member, {name = "tired", loop = false})
		end

		music_player:PlaySfxOneShot("01_drown_02")

		coroutine.yield(coroutine_class.wait_for_sec(2))

	elseif (playResult == CS.Oak.SingleRaidPlayResult.Clear) then

		--보스 연출이 모종의 이유로 지연될 경우, 무한 대기를 막기 위해 최대 5.5초까진 기다린다. (연출은 대략 4.5~5초)
		local wait_time_passed = 0
		while self.dying_end == false and wait_time_passed < 5.5 do
			wait_time_passed = wait_time_passed + unity_class.time.deltaTime
			coroutine.yield(nil)
		end

		local temp_dir = CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction)
		local dir = CS.Oak.DirectionExtensions.GetOpposite(temp_dir)
		character_util.align_party(user_party_leader.Position - CS.Oak.DirectionExtensions.ToVector3(dir), dir, 1, "arc")
		coroutine.yield(coroutine_class.wait_for_sec(1))

		music_player:PlaySfxOneShot("03_activity_clear_01")

		for i = 0, user_party.Count - 1 do
			local party_member = user_party[i]
			character_util.set_direction(party_member, CS.Oak.DirectionExtensions.GetSideDirection(party_member.Direction))
			character_util.set_anim(party_member, {name = "victory_get", loop = false})
			character_util.set_emotion(party_member, {name = "smile", loop = false})
		end

	end

	-- (이 땐 결과 연출 및 결과창 안떠도 에러팝업을 통해 로비로 이동 됨)
	if remain_hp ~= nil then
		music_player:PlayStageMusic("bgm_result", CS.Oak.StageBgmState.Event, 2)
		coroutine.yield(coroutine_class.wait_for_sec(2))

		local challenge_spec = stage.ChallengeSpec
		local kill_score = 0

		-- 보스 처치 점수 <- 처치를 못하면 획득을 못함
		if single_raid_result.Killed then
			kill_score = challenge_spec.KillBonusScore
		end

		local ui_state = CS.Oak.UI.SingleRaidStageResultState()
		ui_state.BossSpecId = challenge_spec.BossId
		ui_state.BossLevel = challenge_spec.BossLevel
		ui_state.BossHp = stage.AllBossesHp
		ui_state.RemainHp = remain_hp
		ui_state.PartyMemberDamages = damages
		ui_state.Result = playResult
		ui_state.KillScore = kill_score
		ui_state.StageScore = single_raid_result.StageScore
		ui_state.TimeScore = single_raid_result.TimeScore
		ui_state.TotalScore = single_raid_result.Score
		ui_state.XScore = rule_score_rate
		-- 남은 시간
		ui_state.RemainTime = remain_time
		ui_state.PrevChallengeHighestScore = prev_challenge_highest_socre
		ui_state.IsLeaderDead = is_leader_dead

		local transition = CS.Oak.UI.UITransition()
		transition.NextScene = CS.Oak.UI.SingleRaidStageResult.Instance
		transition.TransitionType = CS.Oak.TransitionType.Push
		transition.Animation = CS.Oak.UI.TransitionAnimation.None
		transition.SavedState = ui_state

		stage.UISceneManager:SetTransition(transition)
	end

end

function local_class:on_load_resource_routine()
	return
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	CS.Oak.FadeScreenTransition.Instance:FadeIn(0, CS.Oak.Interpolations.EaseInOutSine)
	CS.Oak.CircularScreenTransition.Instance:FadeIn(1, CS.Oak.Interpolations.EaseInOutSine)

	local field = stage.Field

	local start_marker =  field:GetMarker("default_start")

	local pool = unity_object_pool.GetOrCreate('garage_title')

	local walk_speed = 1.0
	local walk_duration = 0.5
	local direction_vector = CS.Oak.DirectionExtensions.ToVector3(start_marker.direction)
	local startPos = start_marker.position - direction_vector * (walk_duration * walk_speed)

	for i = 1, user_party.Count do
		local index = i - 1

		user_party[index].Direction = start_marker.direction
		user_party[index].Position = startPos - direction_vector * (CS.Oak.Constants.DistBetweenPartyMembers * index)

		local waypoints = create_generic_list(unity_class.vector3)
		waypoints:Add(start_marker.position - direction_vector * (CS.Oak.Constants.DistBetweenPartyMembers * index))

		local move_info = CS.Oak.WaypointMoveInfo()
		move_info.waypoints = waypoints
		move_info.speed = walk_speed
		move_info.lastDirection = start_marker.direction
		move_info.run = false
		move_info.endType = CS.Oak.WaypointMoveEndType.Stop
		move_info.yMode = CS.Oak.CharacterYMode.Floor

		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(user_party[index], move_info)
	end

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)

	coroutine.yield(coroutine_class.wait_for_sec(walk_duration))

	local originDir = user_party_leader.Direction
	character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(originDir))
	character_util.set_anim(user_party_leader, {name = "victory_get", loop = false})

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	coroutine.yield(unity_object_pool.WaitUntilLoaded(pool))

	music_player:PlaySfxOneShot("03_activity_clear_01")
	music_player:PlaySfxOneShot("01_count_01")

	local garage_title = pool:Instantiate(vector(0, 100, 0))
	garage_title.transform.parent = stage.UIRoot.transform
	garage_title.transform.localPosition = vector(0, 100,0)
	garage_title.transform.localScale = unity_class.vector3.one
	local garage_title_component = garage_title:GetComponent(typeof(CS.Oak.UIGarageTitle))

	garage_title_component:Show(CS.Oak.UIGarageTitle.GarageTitleType.Start)

	music_player:PlaySfxOneShot("01_stage_intro_jump_01")

	coroutine.yield(coroutine_class.wait_for_sec(2.1))

	character_util.remove_anim(user_party_leader)
	character_util.set_direction(user_party_leader, originDir)
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Combat)

	user_party:ResetControllers()

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	-- FIX: 프레임 복구 - 도중에 옵션창에서 변경 된 경우 등에 대비해 설정값 읽어서 되돌림
	-- Low = 1, Mid, High
	local frame_option = CS.UnityEngine.PlayerPrefs.GetInt('FrameRateOption', 2)
	if frame_option == 1 then
		CS.UnityEngine.Application.targetFrameRate = 30
	elseif frame_option == 3 then
		CS.UnityEngine.Application.targetFrameRate = CS.Oak.UI.OptionsFrameRate.MaximumFps
	else
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.SingleRaidEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DyingEndEvent))
	self.scene = nil
	self.cs_controller = nil

	if self.boss_hashset ~= nil then
		self.boss_hashset:Clear()
	end

	self.resource_holder = nil
end

function local_class:remove_monster(character)
	return self.boss_hashset:Remove(character)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
