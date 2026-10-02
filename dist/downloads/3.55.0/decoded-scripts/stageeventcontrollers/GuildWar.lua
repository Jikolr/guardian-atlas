local local_class = newclass("GuildWarController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.GuildWarEndEvent), 'on_event')

	-- FIX: 길드 레이드 프레임 AI 이슈로 60프레임 제한
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
--

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.GuildWarEndEvent) then
		self:on_guild_war_end_event(e)
	end
	return true
end

function local_class:on_guild_war_end_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.end_routine, self, e.ResultState))
end

function local_class:end_routine(result_state)
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted)

	stage.FieldUIManager:Hide()
	user_party:StopAndDisableControl()
	--- 모든 소환수 소환 해제
	stage.SummonableManager:UnsummonAll()

	if (result_state.Result == CS.Oak.GuildWarResultType.Defeat) or user_party_leader.FieldObjectStatsBehaviour.IsDead then
		for i = 0, user_party.Count - 1 do
			local party_member = user_party[i]
			character_util.set_direction(party_member, CS.Oak.DirectionExtensions.GetSideDirection(party_member.Direction))
			character_util.set_anim(party_member, {name = "seat", loop = false})
			character_util.set_emotion(party_member, {name = "tired", loop = false})
		end

		music_player:PlaySfxOneShot("01_drown_02")

		coroutine.yield(coroutine_class.wait_for_sec(2))

	elseif (result_state.Result == CS.Oak.GuildWarResultType.Clear) then
		local temp_dir = CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction)
		local dir = CS.Oak.DirectionExtensions.GetOpposite(temp_dir)
		character_util.align_party(user_party_leader.Position - CS.Oak.DirectionExtensions.ToVector3(dir), dir, 1, "arc")

		wait_for_sec(1)

		music_player:PlaySfxOneShot("03_activity_clear_01")

		for i = 0, user_party.Count - 1 do
			local party_member = user_party[i]

			character_util.set_anim(party_member, {name = "victory_get", loop = false})
			character_util.set_emotion(party_member, {name = "smile", loop = false})
			character_util.set_direction(party_member, CS.Oak.DirectionExtensions.GetSideDirection(party_member.Direction))
		end
	end

	music_player:PlayStageMusic("bgm_result", CS.Oak.StageBgmState.Event, 2)
	coroutine.yield(coroutine_class.wait_for_sec(2))

	--todo: cancel되었을 때 예외 처리 필요

	local transition = CS.Oak.UI.UITransition()
	transition.NextScene = CS.Oak.UI.GuildWarResult.Instance
	transition.TransitionType = CS.Oak.TransitionType.Push
	transition.Animation = CS.Oak.UI.TransitionAnimation.None
	transition.SavedState = result_state

	stage.UISceneManager:SetTransition(transition)
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

	-- 코어, 공성전차 스폰 타이밍 알림
	message_system:PublishSync(CS.Oak.GuildWarStartSpawnEvent.Instance)

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

	message_system:Unsubscribe(self, typeof(CS.Oak.GuildWarEndEvent))

	self.scene = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
