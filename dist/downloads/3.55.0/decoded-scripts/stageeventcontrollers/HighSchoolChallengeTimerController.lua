local local_class = newclass("HighSchoolChallengeTimerController")
--TODO: HighSchoolChallengeTimerController -> ChallengeTimerController 이름 변경 예정
--[[ 데이터 관리 ]]
function local_class:set_data()
	self.stage_data = {
		{
			stage_name = 'substage_highschool_1',
			stage_time_limit = 120,
			zone_name = 'BOSS',
			battle_group_name = 'boss',
			game_over_type = CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint,
			show_boss = false,
			boss = nil
		},
		{
			stage_name = 'substage_highschool_3',
			stage_time_limit = 150,
			zone_name = 'battle1',
			battle_group_name = 'battle3',
			game_over_type = CS.Oak.UIGameOver.UIGameOverButtonType.All,
			show_boss = false,
			boss = nil
		},
		{
			stage_name = 'substage_movie_1',
			stage_time_limit = 70,
			zone_name = 'boss',
			battle_group_name = 'boss',
			game_over_type = CS.Oak.UIGameOver.UIGameOverButtonType.All,
			show_boss = false,
			boss = nil
		},
		{
			stage_name = 'substage_fox_2',
			stage_time_limit = 90,
			zone_name = 'timer_start',
			battle_group_name = 'boss',
			game_over_type = CS.Oak.UIGameOver.UIGameOverButtonType.All,
			show_boss = true,
			boss = get_character('boss')
		},
		{
			stage_name = 'substage_afterworld_2',
			stage_time_limit = 150,
			zone_name = 'battle1',
			battle_group_name = 'battle5',
			game_over_type = CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint,
			show_boss = false,
			boss = nil
		}
	}
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self:set_data()

	self.is_game_over = false
	self.is_timer_start = false

	self.current_stage_index = -1
	for i = 1, #self.stage_data do
		if stage.Name == self.stage_data[i].stage_name then
			self.current_stage_index = i
		end
	end

	self.leader_battle = nil

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.HealEvent), 'on_event')

	-- 타이머 로드
	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.EventTimer)

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.GlobalTimerAlarmEvent) then
		self:on_timer_alarm_event(e)
	elseif event_type == typeof(CS.Oak.GameOverEvent) then
		self:on_game_over_event(e)
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
		---FieldObjectRevivedEvent는 IsDead 일때만 불리기 때문에 stage.cs에서 무조건 날려주는 HealEvent의 isRival로 부활 체크
	elseif event_type == typeof(CS.Oak.HealEvent) then
		self:on_heal_event(e)
	end

	return false
end

---[[on_event
function local_class:on_stage_start_event(e)
	stage:SetGameOver(self.stage_data[self.current_stage_index].game_over_type, false, false)
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.stage_data[self.current_stage_index].zone_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.start_timer, self, self.stage_data[self.current_stage_index].stage_time_limit, true))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	end
end

-- 시간이 오버 되면 불리는 루틴
function local_class:on_timer_alarm_event(e)
	if e.TimerId ~= CS.Oak.GlobalTimerId.SingleGameTimer or not e.IsComplete then return end
	self:on_time_over()
end

function local_class:on_game_over_event(e)
	self.is_game_over = true
	self:stop_timer()
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.stage_data[self.current_stage_index].battle_group_name then
		message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)
		self:stop_timer()
	end
end

function local_class:on_heal_event(e)
	if lua_helper.reference_equals(e.Info.target, user_party_leader) and self.is_game_over and e.Info.isRevive then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.on_revived, self))
	end
end

---]]

function local_class:start_timer(duration, show_boss)
	if show_boss and self.stage_data[self.current_stage_index].show_boss then
		party_util.stop_and_disable_control()

		camera_util.move_async(self.stage_data[self.current_stage_index].boss.Position, 1)

		wait_for_sec(2)

		camera_util.return_to_leader(1)

		party_util.reset_controllers()
	end

	self.is_timer_start = true
	message_system:Publish(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
			CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, duration, null)))

	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:stop_timer()
	message_system:Publish(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:on_time_over()
	self.is_time_over = true

	user_party_leader.CharacterStatsBehaviour:AddStatsOptionRequest(self.cs_controller, CS.Oak.CharacterStatsOptions.Immortal)
	-- 가시블럭에 충돌되지 않도록 OverrideCrashBehaviour에 설정
	user_party_leader.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	user_party_leader.CharacterBehaviour:CancelAllBattleActions()

	-- 리더가 물체를 들고있는 생태라면 물건을 놓아줌 (CharacterBehaviour (472) 참고)
	if lua_helper.type_compare(user_party_leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState) then
		local held_fo = user_party_leader.CharacterBehaviour.CurrentActionState.HoldTarget
		character_util.clear_holdup_state(user_party_leader, held_fo)
		local height = field:GetTileInfoAt(held_fo.Position).y
		held_fo.Position = vector_util.get_x0z(held_fo.Position, height)
	end

	party_util.stop_and_disable_control()

	self.leader_battle = stage.BattleManager:GetBattleFor(user_party_leader)

	for i = 0, user_party.Count - 1 do
		user_party[i].EntityGroup = CS.Oak.EntityGroups.Enemy;
	end

	stage.BattleManager:ForceEndBattles()

	stage:SetGameOver(self.stage_data[self.current_stage_index].game_over_type, false, true)
	message_system:Publish(CS.Oak.GameOverEvent.Instance)

	character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))
	character_util.set_emotion(user_party_leader, {name = 'damaged'})
	character_util.set_anim(user_party_leader, {name = 'frustration', loop = false, scale = 0.4})
end

function local_class:on_revived()
	if self.is_timer_start == false then return end
	self.is_game_over = false

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.start_timer, self, self.stage_data[self.current_stage_index].stage_time_limit, false))

	-- 타임오버가 아니면 생략한다.
	if not self.is_time_over then return end
	self.is_time_over = false

	-- HACK : 게임오버를 부르는 쪽에서 하는것이 원직적으론 맞을듯, 뭔가 좋은 수정안 없을까..?
	stage:SetGameOver(self.stage_data[self.current_stage_index].game_over_type, false, false)

	user_party_leader.CharacterStatsBehaviour:RemoveStatsOptionRequest(self.cs_controller)
	-- OverrideCrashBehaviour 변경했던 것 해제
	user_party_leader.OverrideCrashBehaviour = nil

	character_util.remove_emotion(user_party_leader)
	character_util.remove_anim(user_party_leader)

	-- 리더 부활 연출
	music_player_util.play_sfx({sfx_name = '01_revive_01',
								parent = user_party_leader,
								type_priority = sfx_type_priority.battle_hit,
								player_priority = CS.Oak.SfxPlayerPriorityExtensions.GetPlayerType(user_party_leader)})
	message_system:Send(user_party_leader.CharacterBehaviour,
			CS.Oak.StateChangeEvent.Create(CS.Oak.ManualCharacterReviveState.Create(user_party_leader)))

	for i = 0, user_party.Count - 1 do
		user_party[i].EntityGroup = CS.Oak.EntityGroups.Player;
	end

	-- 컨트롤러 리셋 (ScreenPlay로 정지시켰기 때문에 수동으로 리셋해야함)
	wait_for_sec(0.3)
	party_util.reset_controllers()
end

function local_class:dispose()
	self:stop_timer()

	-- 구독한 이벤트 해지
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HealEvent))

	self.leader_battle = nil
	self.stage_data = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
