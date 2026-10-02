local local_class = newclass('SubStageRacetrackController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 공주 가져오기
	self.get_princess = function()
		return get_character('princess')
	end

	-- 디스플레이 가져오기
	self.get_big_display = function(num)
		return get_field_object('big_display_'.. num)
	end

	-- 레이스 매니아 가져오기
	self.get_race_lover = function()
		return get_character('race_lover')
	end

	-- 레이스 매니아 데코 가져오기
	self.get_race_lover_deco = function(index)
		return get_character('race_lover_deco_' .. index)
	end

	-- 레이스 매니아 스타피스
	self.race_lover_star_piece_name = 'race_lover_star_piece'

	self.horse_racing_quest_id = 314

	self.get_detecting_invader = function(index)
		return get_character('detecting_invader_' .. index)
	end

	-- 감시에 걸렸을 때 CustomStageEvent에 날라오는 이름
	self.detect_event_name = 'detected_with_invader'

	-- 감시에 걸렸을 때 리셋 위치
	self.reset_pos = {
		ticket_office = 'reset_ticket_office',
		puzzle_room = 'reset_puzzle_room'
	}

	-- 사이렌을 멈출 것인지
	self.stop_siren = false

	self.is_detected = false

	-- 존 이름
	self.race_lover_event_zone_name = 'race_lover_zone'
	self.race_track_event_zone_name = 'race_track'
	self.race_track_bgm_event_zone_name = 'race_track_bgm'

	-- 존 엔터 플래그
	self.is_in_race_event_zone = false

	-- 섹션 1 이상에서 재입장 시 열어놓을 문 이름
	self.racetrack_door_name = 'racetrack_door'

	-- 레이스 마니아 스타피스 획득 여부
	self.is_get_race_lover_star_piece = false

	-- 레이스 종료 여부 저장, 섹션 1에서만 사용함
	self.is_finished_race = false
	self.finished_race_custom_event = 'end_racing'

	-- 레이스 마니아 loop 사운드 fx
	self.race_lover_sfx = nil

	-- 경기장 내부 loop 사운드 fx
	self.crowd_sfx = nil

	-- 마지막 위치 문
	self.last_door_name = 'last_door'

	-- 서브 퀘스트
	self.sub_quest_id = 314
	self.sub_quest_progress = -1
	self.sub_quest_completed = false

	-- 오브젝트 풀
	self.fx_star_piece_char = nil

	self.get_fx_star_piece_char = function()
		return unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.get_fx_star_piece_char()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.fx_star_piece_char ~= nil then
		self.fx_star_piece_char:Dispose()
		self.fx_star_piece_char = nil
	end

	if self.race_lover_sfx ~= nil then
		self.race_lover_sfx:FadeOut()
		self.race_lover_sfx = nil
	end

	if self.crowd_sfx ~= nil then
		self.crowd_sfx:FadeOut()
		self.crowd_sfx = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

--- StageLoadedEvent
function local_class:on_stage_loaded_event(_)
	local ticket_office_invader_index = { 32, 21, 5, 11, 12, 23, 24, 35, 36 }
	for i = 1, #ticket_office_invader_index do
		local invader = get_character('ticket_office_invader_' .. ticket_office_invader_index[i])
		field_ui_manager:RemoveUI(invader, CS.Oak.FieldUiType.CharacterStats)
	end

	-- 디스플레이 켜기
	for i = 1, 2 do
		local display_transform = self.get_big_display(i).Transform
		display_transform:GetChild(1).gameObject:SetActive(true)
	end

	-- 오염생물 매니아
	character_util.add_listener(self.get_race_lover(), self.cs_controller)
	character_util.set_anim(self.get_race_lover(), { name = 'success', sfx_name = '01_jump_01' })
	character_util.set_emotion(self.get_race_lover(), { name = 'smile' })

	self:detecting_invader_setting()

	self.is_get_race_lover_star_piece = star_piece_util.has_star_piece(self.race_lover_star_piece_name)

	local sub_quest = user_progress:GetStartedQuest(self.sub_quest_id)

	if sub_quest ~= nil then
		self.sub_quest_progress = sub_quest.InnerProgress
		self.sub_quest_completed = sub_quest.IsComplete
	end

	return true
end

--- StageStartEvent
function local_class:on_stage_start_event(e)
	if not self.is_get_race_lover_star_piece then
		self.fx_star_piece_char = self.get_fx_star_piece_char():Instantiate(self.get_race_lover().Position)
	end

	if self.sub_quest_completed then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.last_door_name, true))
	end

	if self.sub_quest_progress >= 1 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.racetrack_door_name, true))
	end

	start_coroutine(self.set_race_lover_deco_animation, self)
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if sub_quest ~= nil then
		self.sub_quest_progress = sub_quest.InnerProgress
		self.sub_quest_completed = sub_quest.IsComplete
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), self.race_lover_event_zone_name) then
		if not self.is_in_race_event_zone then
			self.is_in_race_event_zone = true

			if self.race_lover_sfx == nil then
				self.race_lover_sfx = music_player_util.play_sfx(
						{ sfx_name = "01_crowd_buzz_01", loop = true, type_priority = 'loop' })
			end

			start_coroutine(self.race_lover_loop_event, self)
		end
	elseif not self.sub_quest_completed and (self.is_finished_race or
			(self.sub_quest_progress >= 1 and self.sub_quest_progress < 8)) then
		if type_util.is_zone_full_enter(e, get_party_leader(), self.race_track_event_zone_name) then
			if self.crowd_sfx == nil then
				self.crowd_sfx = music_player_util.play_sfx(
						{ sfx_name = "01_crowd_clap_01", fade_in_time = 1, loop = true, type_priority = 'loop' })
			end
		elseif type_util.is_zone_full_enter(e, get_party_leader(), self.race_track_bgm_event_zone_name) then
			music_player_util.play_stage_music(
					{ name = 'ondemand/v2_49_queenship/audio:bgm_queenship_derby',
					  state = 'event', mix = 2, volume = 0.5 })
		end
	end
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)
	if sub_quest ~= nil then
		self.sub_quest_progress = sub_quest.InnerProgress
		self.sub_quest_completed = sub_quest.IsComplete
	end

	if type_util.is_zone_full_leave(e, get_party_leader(), self.race_lover_event_zone_name) then
		if self.is_in_race_event_zone then
			self.is_in_race_event_zone = false

			if self.race_lover_sfx ~= nil then
				self.race_lover_sfx:FadeOut()
				self.race_lover_sfx = nil
			end
		end
	elseif not self.sub_quest_completed and (self.is_finished_race or
			(self.sub_quest_progress >= 1 and self.sub_quest_progress < 8)) then
		if type_util.is_zone_full_leave(e, get_party_leader(), self.race_track_event_zone_name) then
			if self.crowd_sfx ~= nil then
				self.crowd_sfx:FadeOut()
				self.crowd_sfx = nil
			end
		elseif type_util.is_zone_full_leave(e, get_party_leader(), self.race_track_bgm_event_zone_name) then
			music_player_util.play_stage_music({ state = 'field' })
		end
	end
end

--- InteractEvent
function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_race_lover()) then
		sp_util.play_normal_screenplay(self.talk_race_lover_event, self)
	end
end

--- CustomStageEvent
function local_class:on_custom_stage_event(e)
	if self.is_detected then
		return false
	end

	if e.Params[0] == self.detect_event_name .. 1 then
		self.is_detected = true
		sp_util.play_normal_screenplay_hide_weapon(self.on_detected_with_ticket_office_invader, self, e.Sender)
		return true
	end

	if e.Params[0] == self.detect_event_name .. 2 then
		self.is_detected = true
		sp_util.play_normal_screenplay_hide_weapon(self.on_detected_with_puzzle_room_invader, self, e.Sender)
		return true
	end

	if e.Params[0] == self.finished_race_custom_event then
		self.is_finished_race = true

		return true
	end

	return false
end

function local_class:pre_setting()
	local horse_racing_quest_progress = user_progress:GetStartedQuest(self.horse_racing_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')

			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
				leader.Direction, game_string:GetString(stage.Name)))

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	if horse_racing_quest_progress == nil or horse_racing_quest_progress.IsComplete then
		change_leader_character({ self.get_princess() })
		start_stage_event('up', field_util.get_marker_pos('default_start'),
			true, true)

	elseif horse_racing_quest_progress.InnerProgress == 8 then
		change_leader_character()
		start_stage_event('left', field_util.get_marker_pos('horse_racing_9_start'),
			false, true)

	else
		change_leader_character({ self.get_princess() })
		start_stage_event('up', field_util.get_marker_pos('default_start'),
			true, true)
	end
end

--- 티켓 인베이더 감시에 걸렸을 때
function local_class:on_detected_with_ticket_office_invader(finder)
	local detecting_invaders = {}
	for i = 1, 2 do
		local invader = self.get_detecting_invader(i)
		table.insert(detecting_invaders, invader)
	end

	local setting = function()
		for i = 1, #detecting_invaders do
			message_system:SendSync(detecting_invaders[i], CS.Oak.StateResetEvent.Instance)
		end
	end

	self:on_detected(finder, detecting_invaders, self.reset_pos.ticket_office, setting)
end

--- 퍼즐방 인베이더 감시에 걸렸을 때
function local_class:on_detected_with_puzzle_room_invader(finder)
	local detecting_invaders = {}
	for i = 3, 4 do
		local invader = self.get_detecting_invader(i)
		table.insert(detecting_invaders, invader)
	end

	local setting = function()
		for i = 1, #detecting_invaders do
			if detecting_invaders[i].ActiveState == active_state('enabled') then
				message_system:SendSync(detecting_invaders[i], CS.Oak.StateResetEvent.Instance)
			end
		end
	end

	self:on_detected(finder, { finder }, self.reset_pos.puzzle_room, setting)
end

--- 감시에 걸렸을 때
function local_class:on_detected(finder, detecting_invaders, reset_marker_name, setting)
	start_coroutine(self.siren_tint, self)

	party_util.look_at(finder)
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	music_player_util.play_sfx_one_shot('03_runaway_01')
	wait_for_sec(0.2)

	-- 누구냐!
	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	scene_util.show_shout_speech_async(finder, 'qs_horse_racing_s1_12')

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	self.stop_siren = true

	-- 파티 리셋 세팅
	party_util.remove_emotion()
	party_util.remove_animation()

	local reset_marker = field:GetMarker(reset_marker_name)
	party_util.align_party(reset_marker.position, reset_marker.direction, 0, 'linear')

	if setting then
		setting()
	end

	wait_for_sec(0.5)

	self.is_detected = false

	screen_util.fade_in_circular_async(0.5, 'linear')
end

-- 사이렌 틴트 연출
function local_class:siren_tint()
	local siren_tint_key = 'siren_tint'

	local tint_duration = 0.5
	local current_time = unity_class.time.time
	local is_tint = false

	self.stop_siren = false

	while not self.stop_siren do
		if unity_class.time.time - current_time > tint_duration then
			current_time = unity_class.time.time

			if is_tint then
				is_tint = false

				field:RemoveTint(siren_tint_key, tint_duration)
			else
				is_tint = true

				field:Tint(siren_tint_key, unity_color({ 1, 0, 0, 0.8 }), tint_duration)
			end
		end

		coroutine.yield(nil)
	end

	if is_tint then
		field:RemoveTint(siren_tint_key, 0)
	end
end

--- 감시 인베이더 세팅
function local_class:detecting_invader_setting()
	-- 첫 번째 구역
	for i = 1, 2 do
		local invader = self.get_detecting_invader(i)
		invader.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
			invader, self.detect_event_name .. 1, 3, 60)
	end

	-- 두 번째 구역
	local invader_3 = self.get_detecting_invader(3)
	local wp_3 = create_generic_list(unity_class.vector3)
	wp_3:Add(invader_3.Position)
	wp_3:Add(invader_3.Position + vector(0, 0, -5))
	wp_3:Add(invader_3.Position + vector(8, 0, -5))
	wp_3:Add(invader_3.Position + vector(8, 0, 0))
	wp_3:Add(invader_3.Position)

	invader_3.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
		invader_3, wp_3, self.detect_event_name .. 2)

	local invader_4 = self.get_detecting_invader(4)
	local wp_4 = create_generic_list(unity_class.vector3)
	wp_4:Add(invader_4.Position)
	wp_4:Add(invader_4.Position + vector(0, 0, 5))
	wp_4:Add(invader_4.Position + vector(-8, 0, 5))
	wp_4:Add(invader_4.Position + vector(-8, 0, 0))
	wp_4:Add(invader_4.Position)

	invader_4.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
		invader_3, wp_4, self.detect_event_name .. 2)

	-- 공용 처리
	for i = 1, 4 do
		local invader = self.get_detecting_invader(i)
		invader.EntityGroup = CS.Oak.EntityGroups.Enemy0
		invader.DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
		invader.DamagedBehaviour.DeathCount = 1
		invader.DamagedBehaviour.ShowDamageNumber = false
		invader.DamagedBehaviour.ApplyOtherDamage = false
		invader.DamagedBehaviour.ApplyAilment = false
		invader.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(invader, true))
	end
end

-- 오염생물 마니아 반복 이벤트
function local_class:race_lover_loop_event()
	local timer = 4
	local duration = 5

	local talk_num = 1

	while self.is_in_race_event_zone do
		timer = timer + unity_class.time.deltaTime

		if timer >= duration then
			timer = 0

			speech_bubble_util.show_speech_bubble(
					self.get_race_lover(), { key = 'qs_horse_racing_race_lover_'..talk_num })

			if talk_num == 1 then
				music_player_util.play_sfx_one_shot('01_bad_fairy_01')

				talk_num = 2

				character_util.set_direction(self.get_race_lover(), 'right')
				character_util.set_anim(self.get_race_lover(), { name = 'dance' })
			else
				music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
				music_player_util.play_sfx_one_shot('01_player_jump_01')

				talk_num = 1

				character_util.set_direction(self.get_race_lover(), 'up')
				character_util.set_anim(self.get_race_lover(), { name = 'success', sfx_name = '01_jump_01' })
			end
		end

		coroutine.yield(nil)
	end
end

-- 오염생물 마니아 대화 이벤트
function local_class:talk_race_lover_event()
	self.is_in_race_event_zone = false

	coroutine.yield(nil)

	speech_bubble_util.remove_bubble(self.get_race_lover())

	character_util.set_direction(self.get_race_lover(), 'down')
	character_util.remove_anim(self.get_race_lover())

	party_util.align_party(self.get_race_lover(), 'down', 1)

	if not self.is_get_race_lover_star_piece then
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		music_player_util.play_sfx_one_shot('01_player_jump_01')

		character_util.jump(self.get_race_lover(), 1, 0.5)
		character_util.set_anim(self.get_race_lover(), { name = 'embarrassed' })
		character_util.set_emotion(self.get_race_lover(), { name = 'surprise' })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_3', skip = true })

		character_util.set_anim(self.get_race_lover(), { name = 'sing' })
		character_util.set_emotion(self.get_race_lover(), { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_4', skip = true })

		character_util.set_anim(self.get_race_lover(), { name = 'release', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_5', skip = true })

		if self.fx_star_piece_char ~= nil then
			self.fx_star_piece_char:Dispose()
			self.fx_star_piece_char = nil
		end

		character_util.set_anim(self.get_race_lover(), { name = 'cast2' })

		local star_piece = get_field_object(self.race_lover_star_piece_name)
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.get_race_lover().Position))

		wait_for_sec(2)

		character_util.set_anim(self.get_race_lover(), { name = 'sing' })
		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_6', skip = true })

		self.is_get_race_lover_star_piece = true
	else
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')

		character_util.jump(self.get_race_lover(), 1, 0.5)
		character_util.set_anim(self.get_race_lover(), { name = 'sing' })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_7', skip = true })

		character_util.set_anim(self.get_race_lover(), { name = 'cross_arm' })
		character_util.remove_emotion(self.get_race_lover())

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_8', skip = true })

		character_util.set_anim(self.get_race_lover(),
				{ name = 'throw', loop = false, sfx_name = '01_swing_01', next_anim = 'idle' })
		character_util.set_emotion(self.get_race_lover(), { name = 'smile' })

		wait_for_sec(0.1)

		local carrot = drop_item_util.create_item({ pos = self.get_race_lover().Position,
		                                                 target = get_party_leader().Position,
		                                                 itemid = 20753, notforinven = true, sprscale = 1,
		                                                 lootstate = 'dontfindlooter' })
		carrot:SetSortingLayer(true)

		wait_for_sec(0.7)

		carrot.ConsumeTarget = get_party_leader()
		carrot:Fly()

		wait_for_sec(1)

		music_player_util.play_sfx_one_shot('01_clap_02')

		character_util.set_anim(self.get_race_lover(), { name = 'clap', skip = true })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_9', skip = true })

		music_player_util.play_sfx_one_shot('01_bad_fairy_01')

		character_util.set_anim(self.get_race_lover(), { name = 'sing' })

		speech_bubble_util.show_speech_bubble_async(
				self.get_race_lover(), { key = 'qs_horse_racing_race_lover_10', skip = true })
	end

	character_util.set_direction(self.get_race_lover(), 'up')
	character_util.set_anim(self.get_race_lover(), { name = 'success' })

	self.is_in_race_event_zone = true

	start_coroutine(self.race_lover_loop_event, self)
end

-- 오염생물 마니아 애니메이션 설정
function local_class:set_race_lover_deco_animation()
	local min_duration = 0.05
	local max_duration = 0.2

	for i = 1, 8 do
		local cur_duration = unity_class.random.Range(min_duration, max_duration)

		character_util.set_anim(self.get_race_lover_deco(i), { name = 'success' })

		wait_for_sec(cur_duration)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
