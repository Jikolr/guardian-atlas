local local_class = newclass('KanterburyNinjaWarriorController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stunt_brazier_name = 'stunt_brazier_'

	self.star_piece_name = 'stuntman_star_piece'

	self.stunt_entry_zone_name = 'stunt_entry'
	self.stunt_exit_zone_name = 'stunt_exit'

	self.is_start_stunt_action = false
	self.is_end = false

	self.listening_damage_event = false

	self.time_to_stunt = 20

	self.get_narrator = function() return get_character('narrator') end
	self.get_guest_1 = function() return get_character('ninja_warrior_guest_' .. 1) end
	self.get_guest_2 = function() return get_character('ninja_warrior_guest_' .. 2) end
	self.get_guest_3 = function() return get_character('ninja_warrior_guest_' .. 3) end
	self.get_guest_4 = function() return get_character('ninja_warrior_guest_' .. 4) end
	self.get_start_position = function() return field:GetMarker('stunt_start').position end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StarPieceGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_event')

	self.is_end = CS.Oak.StageProgress.Current:HasStarPiece(self.star_piece_name)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StarPieceGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	if self.listening_damage_event then
		message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if self.is_end then
		return false
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		self:on_damage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StarPieceGetEvent) then
		self:on_star_piece_get_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.GlobalTimerAlarmEvent) then
		self:on_global_timer_alarm_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectRevivedEvent) then
		self:on_field_object_revived_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if not self.is_start_stunt_action and e.Zone.Name == self.stunt_entry_zone_name then
			self:ninja_warrior_start()
		elseif self.is_start_stunt_action and e.Zone.Name == self.stunt_exit_zone_name then
			self:ninja_warrior_fail()
		end
	end

	return false
end

function local_class:on_damage_event(e)
	if lua_helper.reference_equals(e.Info.target, user_party_leader) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.return_to_start_position, self))
	end
end

function local_class:on_star_piece_get_event(e)
	if CS.Oak.StageProgress.Current:HasStarPiece(self.star_piece_name) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ninja_warrior_clear, self))
	end
end

function local_class:on_global_timer_alarm_event(e)
	if e.IsComplete then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.return_to_start_position, self))
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.is_start_stunt_action and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		self:stop_timer()
	end
end

function local_class:on_field_object_revived_event(e)
	if self.is_start_stunt_action and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		self:resume_timer()
	end
end

-- 연출
-- 닌자워리어 시작. 타이머 흐르기 시작함.
function local_class:ninja_warrior_start()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	self.listening_damage_event = true
	self.is_start_stunt_action = true

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_timer, self))
end

-- 닌자워리어 실패. 타이머 삭제
function local_class:ninja_warrior_fail()
	if self.listening_damage_event then
		message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
		self.listening_damage_event = false
		self.is_start_stunt_action = false
	end

	self:end_timer()
end

-- 실패해서 돌아간다.
function local_class:return_to_start_position()
	-- 만약 유저가 이미 죽었다면, 게임오버 연출이 뜨고 있을테니 무시한다.
	if user_party_leader.FieldObjectStatsBehaviour.IsDead then
		return
	end

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local star_piece = get_field_object(self.star_piece_name)

	-- 연출중에 리더가 가시 기믹에 피격되지 않도록, EtherealCrashBehaviour로 잠시 바꿔준다.
	user_party_leader.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	self:ninja_warrior_fail()

	music_player:PlaySfxOneShot('01_drown_01')
	star_piece.CrashBehaviour = CS.Oak.DefaultCrashBehaviour.Instance
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	local start_position = self:get_start_position()
	party_util.position_party(start_position, 'left', 'linear')

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	star_piece.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	user_party_leader.CrashBehaviour = CS.Oak.DefaultCrashBehaviour.Instance

	self:brazier_off()

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:brazier_off()
	for i = 1, 2 do
		local bust_cs = CS.Oak.LuaICombustibleBehaviour()
		local brazier = get_field_object(self.stunt_brazier_name .. i)
		bust_cs:GetExtinguishedBy(brazier, nil)
	end
end

-- 시간 안에 스타피스를 획득하여 클리어 했을 때의 연출
function local_class:ninja_warrior_clear()
	local narrator = self:get_narrator()
	local guest_1 = self:get_guest_1()
	local guest_2 = self:get_guest_2()
	local guest_3 = self:get_guest_3()
	local guest_4 = self:get_guest_4()

	self.is_end = true
	self:end_timer()
	self:brazier_off()
	wait_for_sec(0.75)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	party_util.align_to_target(vector(19.5, 0, 15), 'right', 1, 'arc')

	-- 스타피스를 먹고 착지하면 사람들이 몰려들고 박수친다.
	-- 나래이터가 달려와서 인터뷰를 한다.
	music_player:PlaySfxOneShot('01_crowd_clap_02')
	wait_all({
		util.cs_generator(character_util.move_waypoint_async, guest_1, vector(20, 0, 16), 4, false, nil, nil, 'down'),
		util.cs_generator(character_util.move_waypoint_async, guest_2, { vector(19, 0, 17), vector(19, 0, 16) }, 4, false, nil, nil, 'down'),
		util.cs_generator(character_util.move_waypoint_async, guest_3, { vector(21, 0, 16.5), vector(21, 0, 16) }, 4, false, nil, nil, 'down'),
		util.cs_generator(character_util.move_waypoint_async, guest_4, { vector(22, 0, 17.5), vector(22, 0, 16) }, 4, false, nil, nil, 'down')
	})
	character_util.set_anim(guest_1, { name = 'clap' })
	character_util.set_anim(guest_2, { name = 'clap' })
	character_util.set_anim(guest_3, { name = 'clap' })
	character_util.set_anim(guest_4, { name = 'clap' })

	character_util.move_waypoint_async(narrator, { vector(18, 0, 15), vector(19, 0, 15) }, 4, false, nil, nil, 'right')

	-- 캔터버리 닌자 워리어 스테이지 8 통과를 축하드립니다!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.look_at(user_party_leader, narrator)
	character_util.set_emotion(narrator, { name = 'smile' })
	character_util.set_anim(narrator, { name = 'clap' })
	speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_1', skip = true })

	-- 닌자 워리어의 이름은 뭔가요?!
	character_util.set_anim(narrator, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_2', skip = true })

	local choose_result = choose_util.play_choose_event({ { game_string:Format('kanterbury_ninja_warrior_2_1', user.Name), 'normal' }, { 'kanterbury_ninja_warrior_2_2', 'mercy' }, { 'kanterbury_ninja_warrior_2_3', 'brutal' } })
	if choose_result == 1 then
		-- {주인공이름}
		-- 축하합니다. {주인공이름}.
		character_util.set_anim(narrator, { name = 'victory_extra' })
		speech_bubble_util.show_speech_bubble_async(narrator, { key = game_string:Format('kanterbury_ninja_warrior_3', user.Name), skip = true })

		-- 고향의 가족과 친구들이 기뻐할거에요.
		character_util.set_anim(narrator, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_4', skip = true })
	elseif choose_result == 2 then
		-- 가디언입니다.
		-- ...가디언이요?
		character_util.remove_emotion(narrator)
		character_util.remove_anim(narrator)
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_5', skip = true })

		-- 영화 보니 그거 순 인간 우월주의자 집단이라던데..
		character_util.set_emotion(narrator, { name = 'tired' })
		character_util.set_anim(narrator, { name = 'question', loop = false })
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_6', skip = true })

		-- 에이 뭐 아무렴 어때.
		character_util.set_emotion(narrator, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_7', skip = true })
	else
		-- 네놈들에게 알려줄 이름 따윈 없다.
		-- 자기소개조차 닌자답게!
		character_util.normal_jump(narrator, true)
		character_util.remove_anim(narrator)
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_8', skip = true })

		-- 훌륭합니다 워리어!
		character_util.set_anim(narrator, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_9', skip = true })
	end

	-- 자 인터뷰는 여기까지.
	character_util.set_anim(narrator, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_10', skip = true })

	-- 방송은 오늘 오후 9 시에 나갈거에요.
	character_util.remove_anim(narrator)
	speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_11', skip = true })

	-- 본방 사수 잊지 마세요!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(narrator, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(narrator, { key = 'kanterbury_ninja_warrior_12', skip = true })

	character_util.remove_anim(narrator)

	field_ui_manager:Show()
	party_util.reset_controllers()
end

function local_class:start_timer()
	music_player:PlaySfxOneShot('02_gimmick_ticking_01')
	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.EventTimer)
	coroutine.yield()

	local game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.time_to_stunt, nil)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, game_timer))
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')
	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, true))
end

function local_class:stop_timer()
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:resume_timer()
	message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:end_timer()
	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}