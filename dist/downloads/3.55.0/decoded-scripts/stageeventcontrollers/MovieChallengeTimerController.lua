local local_class = newclass("MovieChallengeTimerController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.time_limit = 60

	self.is_game_over = false
	self.is_timer_start = false

	self.seen_intro = false
	self.stop_timer_by_switch = false

	self.leader_battle = nil
	self.twinkle = nil

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.HealEvent), 'on_event')

	-- 타이머 로드
	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.EventTimer)

	unity_object_pool.GetOrCreate("FX_Object_Twinkle")

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
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.GlobalTimerAlarmEvent) then
		self:on_timer_alarm_event(e)
	elseif event_type == typeof(CS.Oak.GameOverEvent) then
		self:on_game_over_event(e)
	elseif event_type == typeof(CS.Oak.SwitchOnOffEvent) then
		self:on_switch_on_off_event(e)
	---FieldObjectRevivedEvent는 IsDead 일때만 불리기 때문에 stage.cs에서 무조건 날려주는 HealEvent의 isRival로 부활 체크
	elseif event_type == typeof(CS.Oak.HealEvent) then
		self:on_heal_event(e)
	end

	return false
end

---[[on_event
function local_class:on_stage_start_event(e)
	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.All, false, false)
	self.twinkle = unity_object_pool.GetOrCreate("FX_Object_Twinkle")
			:Instantiate(get_field_object('switch_destination').Position + vector(0, 0.1, 0))
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == 'BATTLE1' and not self.seen_intro then
		self.seen_intro = true
		sp_util.play_normal_screenplay(self.focus_destination, self)
	elseif zone_name == 'battle_end' then
		stage.BattleManager:ForceEndBattles()
	end
end

function local_class:on_zone_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end

	local zone_name = e.Zone.Name
	if zone_name == 'BATTLE1' then
		stage.BattleManager:ForceEndBattles()

		stage.ProjectileManager:ClearProjectiles()
		stage.AreaOfEffectManager:ClearAllAoe()

		for i = 0, user_party.Count - 1 do
			user_party[i].CharacterBehaviour:CancelAllBattleActions(true)
		end
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

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('switch_destination')) and
			not self.stop_timer_by_switch then

		self.stop_timer_by_switch = true

		message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)

		self:stop_timer()

		self.twinkle:Dispose()
	end
end

function local_class:on_heal_event(e)
	if lua_helper.reference_equals(e.Info.target, user_party_leader) and self.is_game_over and e.Info.isRevive then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.on_revived, self))
	end
end

---]]

function local_class:focus_destination()
	for i = 1, user_party.Count - 1 do
		user_party[i].FieldObjectController.DontFight = true
	end

	local switch = get_field_object('switch_destination')

	camera_util.move_async(switch.Position, 2, {ignorecameragrids = true})
	wait_for_sec(1)
	camera_util.move_async(user_party_leader.Position, 2, {end_target = user_party_leader})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.start_timer, self, self.time_limit))

	for i = 1, user_party.Count - 1 do
		user_party[i].FieldObjectController.DontFight = false
	end
end

function local_class:start_timer(duration)
	self.is_timer_start = true
	message_system:Publish(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
			CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, duration, null)))

	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:stop_timer()
	message_system:Publish(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:on_time_over()
	self.is_game_over = true

	character_util.set_immortal(user_party_leader, true)
	user_party_leader.CharacterBehaviour:CancelAllBattleActions()
	stage.FieldUIManager:Hide()
	party_util.stop_and_disable_control()

	self.leader_battle = stage.BattleManager:GetBattleFor(user_party_leader)

	for i = 0, user_party.Count - 1 do
		user_party[i].EntityGroup = CS.Oak.EntityGroups.Enemy;
	end

	stage.BattleManager:ForceEndBattles()

	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.All, false, true)
	message_system:Publish(CS.Oak.GameOverEvent.Instance)

	character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))
	character_util.set_emotion(user_party_leader, {name = 'damaged'})
	character_util.set_anim(user_party_leader, {name = 'frustration', loop = false, scale = 0.4})
end

function local_class:on_revived()
	if self.is_timer_start == false then return end
	self.is_game_over = false

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.start_timer, self, self.time_limit))

	character_util.remove_emotion(user_party_leader)
	character_util.remove_anim(user_party_leader)

	coroutine.yield(character_util.mario_jump(user_party_leader, user_party_leader.Direction))

	for i = 0, user_party.Count - 1 do
		user_party[i].EntityGroup = CS.Oak.EntityGroups.Player;
	end

	stage.FieldUIManager:Show()
	party_util.reset_controllers()
end

function local_class:dispose()
	if self.twinkle ~= nil then
		self.twinkle:Dispose()
	end

	self:stop_timer()

	-- 구독한 이벤트 해지
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HealEvent))

	self.leader_battle = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
