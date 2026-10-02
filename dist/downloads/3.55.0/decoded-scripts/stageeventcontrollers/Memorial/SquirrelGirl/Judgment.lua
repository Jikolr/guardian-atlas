local local_class = newclass('MemorialSquirrelGirlJudgmentController')

function local_class:init()
	self.controller = nil
	self.custom_state_key = nil

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	--state
	self.states = {
		none = 1,
		zone_event = 2,
		judgment_event = 3
	}

	self.current_state = self.states.none

	--npc
	self.character = {
		squirrel_girl = function()
			return get_character('squirrel_girl')
		end,
		snowman_prosecutor = function()
			return get_character('snowman_prosecutor')
		end,
		innuit_male = function()
			return get_character('innuit_male')
		end,
		innuit_judge = function()
			return get_character('innuit_judge')
		end,
		titantavern_mouse = function()
			return get_character('titantavern_mouse')
		end,
		burning_skull = function()
			return get_character('burning_skull')
		end
	}

	--marker
	self.marker = {
		event_pos = function(number)
			return field_util.get_marker_pos('event_judgment_pos_' .. number)
		end
	}

	self.show_mouse_state_key = 'mouse_costume'
	self.cleared_progress = 4
	self.is_loaded = false
end

function local_class:init_controller(controller, custom_state_key)
	self.controller = controller
	self.custom_state_key = custom_state_key

	--인형탈 이벤트는 메인 퀘스트 4섹션에 귀속된다.
	if self.controller.quest_progress.IsComplete then
		--클리어 시 불타는 전사 세팅
		self:cleared_setting()
		return
	elseif self.controller.quest_progress.InnerProgress >= self.cleared_progress then
		--4섹션 이상 진행 시 이벤트 비활성화
		return
	end

	self.is_loaded = true

	--커스텀스테이트 초기화
	self.controller.stage_event:clear_event(self.custom_state_key, -1)

	self:setting_npc()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:dispose()
	if not self.is_loaded then
		return
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	character_util.remove_lua_listener(self.character.innuit_male(), self)

	self.custom_state_key = nil
	self.controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if self.current_state == self.states.zone_event and
			type_util.is_interacted_target(e, self.character.innuit_male()) then
		self.current_state = self.states.judgment_event
		start_coroutine(self.talk_innuit_male, self)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.current_state == self.states.none and
			type_util.is_zone_full_enter(e, get_party_leader(), 'event_judgment_zone') then
		self.current_state = self.states.zone_event
		sp_util.start_scene(self.show_zone_event, self)

		return true
	end

	return false
end

function local_class:setting_npc()
	local snowman_prosecutor = self.character.snowman_prosecutor()
	local innuit_judge = self.character.innuit_judge()
	local innuit_male = self.character.innuit_male()
	local titantavern_mouse = self.character.titantavern_mouse()
	local burning_skull = self.character.burning_skull()

	--검사 (right, attack, idle)
	character_util.set_position(snowman_prosecutor, self.marker.event_pos(2))
	character_util.set_direction(snowman_prosecutor, 'right')
	scene_util.set_emotion(snowman_prosecutor, self, 'attack')

	--판사 (down, idle, idle)
	character_util.set_position(innuit_judge, self.marker.event_pos(1))
	character_util.set_direction(innuit_judge, 'down')

	--변호사 (left, idle, idle)
	character_util.set_position(innuit_male, self.marker.event_pos(3))
	character_util.set_direction(innuit_male, 'left')

	--쥐 (left, tired, idle)
	character_util.set_position(titantavern_mouse, self.marker.event_pos(4))
	character_util.set_direction(titantavern_mouse, 'left')
	scene_util.set_emotion(titantavern_mouse, self, 'tired')

	--불타는 전사 (up, idle, idle)
	--검은색 틴트 50%  적용
	--원라인 대사 : 긴장해서 온도가 내려갔어….
	character_util.set_position(burning_skull, self.marker.event_pos(7))
	character_util.set_direction(burning_skull, 'up')
	character_util.remove_anim_and_emotion(burning_skull)
	character_util.add_fade_color(burning_skull, burning_skull.Name, unity_class.color.black, 0.9, 0)
	burning_skull.Interactable = CS.Oak.NPCInteractable.Create()
	burning_skull.Interactable.Talk = 'mm_squirrel_girl_event_judgment_oneline_1'
end

function local_class:show_zone_event()
	music_player_util.stop_bgm_manager()
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	local snowman_prosecutor = self.character.snowman_prosecutor()
	local innuit_judge = self.character.innuit_judge()
	local innuit_male = self.character.innuit_male()

	--재판장 진입시 1.5초간 검게 페이드아웃
	screen_util.fade_out_async(1.5, unity_class.color.black, 'linear')

	camera_util.resize_by_ratio_async(2.5, 0)
	camera_util.move_to_target_async(snowman_prosecutor, 0)

	local objection_bgm_name = lua_helper.get_conditional_value(CS.Foundations.GameEnvironment.IsKongJapan,
			'bgm_shivermore_objection_kong', 'bgm_shivermore_objection')

	music_player_util.play_stage_music({
		name = objection_bgm_name, state = 'event', mix = 2, volume = 0.6
	})

	--화면 1.5초간 검게 페이드 인
	screen_util.fade_in_async(1.5, unity_class.color.black)

	--검사 (right, attack, release 2회): 변호사, 테마파크는 어린이들을 위한 꿈의 공간입니다!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			{ name = 'release', count = 2 }, 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_1', skip = true, bubble_direction = 'cb' })

	--검사 (right, idle, cross_arm): 피고는 마스코트임에도 자기 본분에 충실하지 못하고 꼬마 아이에게 화를 냈습니다.
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			'cross_arm', nil,
			{ key = 'mm_squirrel_girl_event_judgment_2', skip = true, bubble_direction = 'cb' })

	--검사 (right, attack, idle): 아무리 사고를 치고 다닌다고 해도 어린 아이한테 으름장을 놓다니요!
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			'idle', 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_3', skip = true, bubble_direction = 'cb' })

	--검사 (right, attack, attack 3회): 말도 안 되는 소립니다. 유죄예욧!
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			{ name = 'attack', count = 3 }, 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_4', skip = true, bubble_direction = 'cb' })

	--검사 (right, attack, idle)
	scene_util.set_direction(snowman_prosecutor, 'right', false)
	scene_util.set_emotion(snowman_prosecutor, self, 'attack')

	--카메라 0.7초간 변호사 위치로 이동, 포커스는 변호사
	camera_util.move_to_target_async(innuit_male, 0.7)

	--변호사 (left, attack, release 2회): 검사 측은 그 꼬마가 피고인을 비롯한 쥐 마스코트들을 상습적으로 폭행한 사실도 알고 있습니까?
	scene_util.play_normal_speech_action(innuit_male, self, 'left',
			{ name = 'release', count = 2 }, 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_5', skip = true, bubble_direction = 'cb' })

	--다음 연출 동시에 진행
	--[화면 0.3값으로 0.3초 shake]
	camera_util.shake(0.3, 0.3)

	--변호사 (left, attack, idle): [shout] 이는 정당방위란 말입니다!
	music_player_util.play_sfx_one_shot('01_count_final_01')
	scene_util.play_shout_speech_action(innuit_male, self, 'left',
			nil, 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_6', skip = true, bubble_direction = 'cb' })

	--카메라 0.7초간 검사 위치로 이동, 포커스는 검사
	camera_util.move_to_target_async(snowman_prosecutor, 0.7)

	--다음 연출 동시에 진행

	--[화면 0.3값으로 0.5초 shake]
	camera_util.shake(0.3, 0.5)

	--검사 (right, attack, release 2회) : [shout]  애가 좀 그럴 수도 있지! 때리면 얼마나 세게 때린다고!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_shout_speech_action(snowman_prosecutor, self, 'right',
			{ name = 'release', count = 2 }, 'attack',
			{ key = 'mm_squirrel_girl_event_judgment_7', skip = true, bubble_direction = 'cb' })

	--검사 (right, attack, bomb_idle): 애초에 때렸다는 증거라도 있습니까?
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			{ name = 'bomb_idle', keep = true }, { name = 'attack', keep = true },
			{ key = 'mm_squirrel_girl_event_judgment_8', skip = true, bubble_direction = 'cb' })

	--카메라 0.7초간 판사 위치로 이동, 포커스는 판사
	camera_util.move_to_target_async(innuit_judge, 0.7)

	--판사 (down, idle, nod 2회) 끝날 때까지 대기
	scene_util.set_anim_async(innuit_judge, self, { name = 'nod', count = 2 })

	--판사 (down, smile, idle): 뭐 사실 인형탈을 쓰고 있어서 맞아도 별로 안 아플 것 같긴 하네요…
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, 'smile',
			{ key = 'mm_squirrel_girl_event_judgment_9', skip = true, bubble_direction = 'cb' })

	--판사 (down, smile, question 1회, 마지막프레임 유지) 변호사, 검사 말대로 증거가 있습니까?
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			{ name = 'question', keep = true }, { name = 'smile', keep = true },
			{ key = 'mm_squirrel_girl_event_judgment_10', skip = true, bubble_direction = 'cb' })

	--카메라 0.7초간 변호사 위치로 이동, 포커스는 변호사
	camera_util.move_to_target_async(innuit_male, 0.7)

	--변호사 (left, tired, idle): 윽…
	scene_util.play_normal_speech_action(innuit_male, self, 'left',
			nil, { name = 'tired', keep = true },
			{ key = 'mm_squirrel_girl_event_judgment_11', skip = true, bubble_direction = 'cb' })

	--이후 검사, 판사, 변호사 npc 마지막 대사 원라인으로 유지
	snowman_prosecutor.Interactable.Talk = 'mm_squirrel_girl_event_judgment_8'
	innuit_judge.Interactable.Talk = 'mm_squirrel_girl_event_judgment_10'
	character_util.add_lua_listener(innuit_male, self)

	--다음 연출 동시에 진행
	--카메라 크기 4로 줌아웃
	camera_util.resize_to_default(1)

	--카메라 1초간 가디언 위치로 이동, 포커스는 가디언
	camera_util.return_to_leader(1)

	--컨트롤 돌려준다.
	self.controller.stage_event:clear_event(self.custom_state_key, 0)

	music_player_util.play_stage_music({ name = 'bgm_shivermore_main', state = 'field' })
	coroutine.yield(nil)
	coroutine.yield(nil)
	coroutine.yield(nil)

	music_player_util.start_bgm_manager()
end

function local_class:talk_innuit_male()
	music_player_util.change_stage_music_volume('field', 0.6)

	sp_util.enter_scene(nil)

	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()
	local innuit_male = self.character.innuit_male()

	--카메라 포커스는 가디언
	do
		local wp_key = 'leader_wp'

		wp_util.move_with_end_callback(leader, innuit_male.Position + vector(1, 0, 0),
				nil, 1.5, self, wp_key, { last_direction = 'left' })
		wp_util.move_with_end_callback(squirrel_girl, innuit_male.Position + vector(1, 0, -1),
				nil, 1.5, self, wp_key, { last_direction = 'left' })

		wp_util.wait_move_end(self, wp_key)
	end

	--가디언과 크루시엘 위치 1초간 아래와 같이 세팅

	--선택지
	local choose_list = {
		--(intellect) 증인 있음!
		{ 'mm_squirrel_girl_event_judgment_14', 'intellect' },
		--(mercy) 화이팅 하세요~
		{ 'mm_squirrel_girl_event_judgment_12', 'mercy' },
	}

	local custom_state = quest_util.get_custom_state(self.controller.quest_progress, self.show_mouse_state_key)
	if custom_state < 1 then
		table.remove(choose_list, 1)
	end

	local choose_result = choose_util.play_choose_event(choose_list)

	if custom_state < 1 or choose_result == 2 then
		character_util.set_direction(innuit_male, 'right')

		--가디언 (left, smile, sing)
		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		scene_util.set_emotion(leader, self, 'smile')
		scene_util.set_anim(leader, self, 'sing')
		--1초 대기
		wait_for_sec(1)

		character_util.remove_anim_and_emotion(leader)

		--변호사 (right, tired, idle): 어, 음… 그래.
		music_player_util.play_sfx_one_shot('01_rustle_01')
		scene_util.show_normal_speech_async(innuit_male, 'mm_squirrel_girl_event_judgment_13')

		--변호사 (left, tired, idle)
		character_util.set_direction(innuit_male, 'left')

		--인형탈 이벤트 클리어 이전일 경우,
		if custom_state < 1 then
			--크루시엘 (up, idle) : 이곳 어딘가에 단서가 있을 거야!
			scene_util.set_direction(squirrel_girl, 'up', false)
			scene_util.play_normal_speech_action(squirrel_girl, self, 'up',
					'idle', 'idle', 'mm_squirrel_girl_event_judgment_13_1')
		end

		--플레이어 파티 현 위치에서 컨트롤 돌려준다.
		self.current_state = self.states.zone_event

		sp_util.exit_scene(nil, leader)
		music_player_util.change_stage_music_volume('field', 1)
		return
	end

	--이후 변호사 npc에게 재인터렉트할 시 즉시 선택지 선택이 가능하다.
	--왼쪽 방 땃쥐 이벤트 볼 경우 아래 선택지 추가
	self:play_judgment_scene()
	music_player_util.change_stage_music_volume('field', 1)
end

function local_class:play_judgment_scene()
	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()
	local snowman_prosecutor = self.character.snowman_prosecutor()
	local innuit_judge = self.character.innuit_judge()
	local innuit_male = self.character.innuit_male()
	local titantavern_mouse = self.character.titantavern_mouse()

	quest_marker_util.remove_auto_control('main_quest')

	--가디언 (left, attack, victory_get) 끝날 때까지 대기
	scene_util.set_emotion(leader, self, 'smile')
	scene_util.set_anim(leader, self, 'victory_get')
	wait_for_sec(1.5)

	music_player_util.stop_bgm_manager()
	music_player_util.play_stage_music({ state = 'muted' })
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	local brazier = get_field_object('judgement_brazier')

	message_system:SendSync(brazier.FieldObjectBehaviour, CS.Oak.GimmickResetEvent.Instance)

	--가디언 (down, sleep_deep, idle)
	character_util.set_position(leader, self.marker.event_pos(6))
	character_util.set_direction(leader, 'down')
	scene_util.set_emotion(leader, self, 'sleep_deep')
	character_util.remove_anim(leader)

	--크루시엘 (left, idle, idle)
	character_util.set_position(squirrel_girl, self.marker.event_pos(5))

	--검사 (right, attack, idle)
	character_util.remove_anim(snowman_prosecutor)
	--판사 (down, idle, idle)
	character_util.remove_anim_and_emotion(innuit_judge)
	--변호사 (left, idle, idle)
	character_util.remove_anim_and_emotion(innuit_male)
	--카메라 포커스는 가디언
	--카메라 2.5 으로 줌 인
	camera_util.resize_by_ratio_async(2.5, 0)

	local riddle_bgm_name = lua_helper.get_conditional_value(CS.Foundations.GameEnvironment.IsKongJapan,
			'bgm_agora_01', 'bgm_shivermore_riddle_01')

	music_player_util.play_stage_music({
		name = riddle_bgm_name, state = 'event', volume = 0.6,
	})

	--1초에 걸쳐 화면 검게 페이드 인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	--아래 이미지와 같이 텍스트 출력, 끝날 때까지 대기

	--내용 : ‘증언: 폭력적인 꼬마아이’
	screen_util.show_stage_title('mm_squirrel_girl_event_judgment_15')

	--텍스트 출력 끝난 뒤 0.5초 대기
	wait_for_sec(3.5)

	--가디언 (down, sleep_deep, nod 2회) 끝날 때까지 대기
	scene_util.set_direction(leader, 'down', false)
	scene_util.set_emotion(leader, self, 'sleep_deep')
	scene_util.set_anim_async(leader, self, { name = 'nod', count = 2 })

	--가디언 (right, idle, idle)
	character_util.remove_emotion(leader)

	--1차 증언 선택지 출력
	do
		local choose_result = choose_util.play_choose_event({
			--(normal) 제가 본 마스코트들은 건실하게 일을 하고 있었습니다.
			{ 'mm_squirrel_girl_event_judgment_16', 'normal' },
			--(normal) 제가 본 마스코트들은 쿨쿨 자고 있었습니다.
			{ 'mm_squirrel_girl_event_judgment_20', 'normal' },
		})

		if choose_result == 1 then
			--가디언 (right, smile, dance)
			music_player_util.play_sfx_one_shot('01_bad_fairy_01')
			scene_util.set_direction(leader, 'right', false)
			scene_util.set_emotion(leader, self, 'smile')
			scene_util.set_anim(leader, self, 'dance')

			--2초 대기
			wait_for_sec(2)

			--다음 연출 동시에 진행
			wait_all_lua(
					function()
						--화면 shake (0.3 , 0.3)
						camera_util.shake(0.3, 0.3)

						--검사 (right, mad, release 2회) [shout] 이의 있음!
						music_player_util.play_sfx_one_shot('01_shivermore_suchinsolence_01')
						scene_util.play_shout_speech_action(snowman_prosecutor, self, 'right',
								{ name = 'release', count = 2 }, { name = 'mad', keep = true },
								{ key = 'mm_squirrel_girl_event_judgment_17', skip = true, bubble_direction = 'cb' })
					end,
					function()
						--카메라 0.5초에 걸쳐 검사에게 이동, 포커스 검사
						camera_util.move_to_target_async(snowman_prosecutor, 0.5)
					end
			)

			--검사 (right, doyagao, bomb_idle): 그 쥐들은 욕먹기 전까지는 절대 일을 하지 않아요.
			scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
					'bomb_idle', 'doyagao',
					{ key = 'mm_squirrel_girl_event_judgment_18', skip = true, bubble_direction = 'cb' })

			--화면 shake (0.3 , 0.3)
			camera_util.shake(0.3, 0.3)

			--검사 (right, attack, release 2회): 당신 증언에는 모순이 있어!
			music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
			scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
					{ name = 'release', count = 2 }, 'attack',
					{ key = 'mm_squirrel_girl_event_judgment_19', skip = true, bubble_direction = 'cb' })

			--1초간 페이드아웃
			screen_util.fade_out_async(1, unity_class.color.black, 'linear')

			--1차 증언 선택지로 돌아가며, 해당 선택지 삭제.
			character_util.remove_anim_and_emotion(leader)
			scene_util.set_direction(leader, 'down', false)
			camera_util.return_to_leader(0)

			screen_util.fade_in_async(1, unity_class.color.black, 'linear')

			choose_util.play_choose_event({
				--(normal) 제가 본 마스코트들은 쿨쿨 자고 있었습니다.
				{ 'mm_squirrel_girl_event_judgment_20', 'normal' },
			})
		end

		--가디언 (right, sleep, seat)
		music_player_util.play_sfx_one_shot('01_sleep_02')
		scene_util.set_direction(leader, 'right', false)
		scene_util.set_emotion(leader, self, 'sleep')
		scene_util.set_anim(leader, self, 'seat')

		--2초 대기
		wait_for_sec(2)

		--가디언 (down, idle, idle)
		scene_util.set_direction(leader, 'down', false)
		character_util.remove_anim_and_emotion(leader)
	end

	--2차 증언 선택지 출력
	do
		local choose_result = choose_util.play_choose_event({
			--(normal) 그래도 중간에 깨어난 뒤에는 정신차리고 일하러 나갔어요.
			{ 'mm_squirrel_girl_event_judgment_21', 'normal' },
			--(normal) 잘 자길래 그냥 두고 나왔어요.
			{ 'mm_squirrel_girl_event_judgment_22', 'normal' },
		})

		if choose_result == 2 then
			--가디언 (down, smile, idle)
			music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
			scene_util.set_direction(leader, 'down', false)
			scene_util.set_emotion(leader, self, 'smile')

			--0.3초 대기
			wait_for_sec(0.3)

			--다음 연출 동시에 진행
			wait_all_lua(
					function()
						--화면 shake (0.3 , 0.3)
						camera_util.shake(0.3, 0.3)
						--검사 (right, mad, release 2회) [shout] 이의 있음!
						music_player_util.play_sfx_one_shot('01_shivermore_suchinsolence_01')
						scene_util.play_shout_speech_action(snowman_prosecutor, self, 'right',
								{ name = 'release', count = 2 }, { name = 'mad', keep = true },
								{ key = 'mm_squirrel_girl_event_judgment_23', skip = true, bubble_direction = 'cb' })
					end,
					function()
						--카메라 0.5초에 걸쳐 검사에게 이동, 포커스 검사
						camera_util.move_to_target_async(snowman_prosecutor, 0.5)
					end
			)

			--검사 (right, doyagao, bomb_idle): 그렇다면 도대체 당신은 언제 쥐들이 폭행당하는 걸 봤다는 말인가요?
			scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
					'bomb_idle', 'doyagao',
					{ key = 'mm_squirrel_girl_event_judgment_24', skip = true, bubble_direction = 'cb' })

			--화면 shake (0.3 , 0.3)
			camera_util.shake(0.3, 0.3)

			--검사 (right, attack, release 2회): 당신 증언에는 모순이 있어!
			music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
			scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
					{ name = 'release', count = 2 }, 'attack',
					{ key = 'mm_squirrel_girl_event_judgment_25', skip = true, bubble_direction = 'cb' })

			screen_util.fade_out_async(1, unity_class.color.black, 'linear')

			--2차 증언 선택지로 돌아가며, 해당 선택지 삭제.
			scene_util.set_direction(leader, 'down', false)
			character_util.remove_anim_and_emotion(leader)
			camera_util.return_to_leader(0)

			screen_util.fade_in_async(1, unity_class.color.black, 'linear')

			choose_util.play_choose_event({
				--(normal) 그래도 중간에 깨어난 뒤에는 정신차리고 일하러 나갔어요.
				{ 'mm_squirrel_girl_event_judgment_21', 'normal' },
			})

		end

		--가디언 (down, idle, nod 2회) 끝날 때까지 대기
		scene_util.set_direction(leader, 'down', false)
		scene_util.set_anim_async(leader, self, { name = 'nod', count = 2 })

		--0.5초 대기
		wait_for_sec(0.5)
	end

	--카메라 포커스 1초에 걸쳐 판사 위치로 변경
	camera_util.move_to_target_async(innuit_judge, 1)

	--판사 (down, sleep_deep, idle) : 흥미롭군요.
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, 'sleep_deep',
			{ key = 'mm_squirrel_girl_event_judgment_26', skip = true, bubble_direction = 'cb' })

	--판사 (down, idle, idle) : 증인, 그 뒤에는? 그 뒤에는 어떻게 됐나요?
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_27', skip = true, bubble_direction = 'cb' })

	--카메라 포커스 1초에 걸쳐 가디언 위치로 변경
	camera_util.return_to_leader(1)

	--3차 증언 선택지 출력
	do
		local choose_result = choose_util.play_choose_event({
			--(normal) 꼬마아이가 마스코트를 폭행했습니다.
			{ 'mm_squirrel_girl_event_judgment_28', 'normal' },
			--(normal) 마스코트가 저급한 춤을 췄습니다.
			{ 'mm_squirrel_girl_event_judgment_29', 'normal' },
		})

		if choose_result == 2 then
			--가디언 (right, blush, dance3)
			music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
			scene_util.set_direction(leader, 'right', false)
			scene_util.set_emotion(leader, self, 'blush')
			scene_util.set_anim(leader, self, 'dance3')

			--1초 대기
			wait_for_sec(1)

			--다음 연출 동시에 진행
			wait_all_lua(
					function()
						--화면 shake (0.3 , 0.3)
						camera_util.shake(0.3, 0.3)

						--검사 (right, mad, release 2회) [shout] 이의 있음!
						music_player_util.play_sfx_one_shot('01_shivermore_suchinsolence_01')
						scene_util.play_shout_speech_action(snowman_prosecutor, self, 'right',
								{ name = 'release', count = 2 }, { name = 'mad', keep = true },
								{ key = 'mm_squirrel_girl_event_judgment_30', skip = true, bubble_direction = 'cb' })
					end,
					function()
						--카메라 0.5초에 걸쳐 검사에게 이동, 포커스 검사
						camera_util.move_to_target_async(snowman_prosecutor, 0.5)
					end
			)

			--검사 (right, doyagao, bomb_idle): 웃기지도 않는군요.
			scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
					'bomb_idle', 'doyagao',
					{ key = 'mm_squirrel_girl_event_judgment_31', skip = true, bubble_direction = 'cb' })

			--화면 shake (0.3 , 0.3)
			camera_util.shake(0.3, 0.3)

			--검사 (right, attack, release 2회) [shout] 증인은 지금 법정을 모독하고 있습니다!
			music_player_util.play_sfx_one_shot('01_count_final_01')
			scene_util.play_shout_speech_action(snowman_prosecutor, self, 'right',
					{ name = 'release', count = 2 }, 'attack',
					{ key = 'mm_squirrel_girl_event_judgment_32', skip = true, bubble_direction = 'cb' })

			screen_util.fade_out_async(1, unity_class.color.black, 'linear')

			scene_util.set_direction(leader, 'down', false)
			character_util.remove_anim_and_emotion(leader)
			camera_util.return_to_leader(0)

			screen_util.fade_in_async(1, unity_class.color.black, 'linear')

			--3차 증언 선택지로 돌아가며, 해당 선택지 삭제.
			choose_result = choose_util.play_choose_event({
				--(normal) 꼬마아이가 마스코트를 폭행했습니다.
				{ 'mm_squirrel_girl_event_judgment_28', 'normal' },
			})
		end

		--가디언 (left, attack, gauntlet_combo_attack 2회)
		scene_util.set_direction(leader, 'left', false)
		scene_util.set_emotion(leader, self, 'attack')
		scene_util.set_anim_async(leader, self, { name = 'gauntlet_combo_attack', count = 2, sfx_name = '02_slash_loop_01' })

		--0.5초 대기
		wait_for_sec(0.5)

		--가디언 (down, tired, bomb_idle)
		music_player_util.play_sfx_one_shot('01_rustle_01')
		scene_util.set_direction(leader, 'down', false)
		scene_util.set_emotion(leader, self, 'tired')
		scene_util.set_anim(leader, self, 'bomb_idle')

		--1.5초 대기
		wait_for_sec(1.5)
	end

	--0.5초간 카메라 포커스 판사에게 이동
	camera_util.move_to_target_async(innuit_judge, 0.5)

	--판사 (down, tired, idle) : 어쩐지 쥐들이 출근하기 싫어 하더라니…
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, 'tired',
			{ key = 'mm_squirrel_girl_event_judgment_33', skip = true, bubble_direction = 'cb' })

	--판사 (down, idle, idle) : 이거 이거 아주 충격적입니다.
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_34', skip = true, bubble_direction = 'cb' })

	--판사 (down, idle, idle) : 판결은 내려진 것 같군요.
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_35', skip = true, bubble_direction = 'cb' })

	--판사 (left, idle, idle) : 검사측, 증언에 반박할 내용이 있나요?
	scene_util.play_normal_speech_action(innuit_judge, self, 'left',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_36', skip = true, bubble_direction = 'cb' })

	--0.5초간 카메라 포커스 검사에게 이동
	camera_util.move_to_target_async(snowman_prosecutor, 0.5)

	--검사 (right, tired, cast): 크윽… 없습니다.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			'cast', 'tired',
			{ key = 'mm_squirrel_girl_event_judgment_37', skip = true, bubble_direction = 'cb' })

	--0.5초간 카메라 포커스 판사에게 이동
	camera_util.move_to_target_async(innuit_judge, 0.5)

	local blizzard_loop_sfx = music_player_util.play_sfx({
		sfx_name = '01_blizzard_03', loop = true,
		type_priority = 'loop',
		fade_in_time = 3,
		volume = 0.5
	})

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	--판사 (down, idle, idle) : 그렇다면 제 판결은 다음과 같습니다.
	music_player_util.play_sfx_one_shot('01_shivermore_cough_01')
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_38', skip = true, bubble_direction = 'cb' })

	--판사 (down, idle, idle) : 본 법정은 피고인 쥐돌이에게…
	scene_util.play_normal_speech_action(innuit_judge, self, 'down',
			nil, nil,
			{ key = 'mm_squirrel_girl_event_judgment_39', skip = true, bubble_direction = 'cb' })

	--아래 연출 동시 진행
	wait_all_lua(
			function()
				--판사 포커스 유지한채 0.3초간 카메라 4.5로 줌 아웃

				camera_util.resize_by_ratio(4.5, 0.3)

				--화면 shake (0.3, 0.5)
				camera_util.shake(0.3, 0.5)

				--[Shout] 3초간 출력 무죄를 선고합니다!
				--화면비 (x: 0.5 / y: 0.2)
				music_player_util.play_sfx_one_shot('01_coop_mvp_01')
				scene_util.play_shout_speech_action(innuit_judge, self, 'down',
						nil, nil,
						{ key = 'mm_squirrel_girl_event_judgment_40', skip = true, viewport_pos = vector(0.5, 0.2) })
			end,
			function()
				--가디언 (down, smile, success)
				scene_util.set_direction(leader, 'down', false)
				scene_util.set_emotion(leader, self, 'smile')
				scene_util.set_anim(leader, self, { name = 'success', sfx_name = false })

				--검사 (right, tired, idle)
				scene_util.set_direction(snowman_prosecutor, 'right', false)
				scene_util.set_emotion(snowman_prosecutor, self, 'tired')

				--쥐 (left, smile, victory_extra)
				scene_util.set_direction(titantavern_mouse, 'left', false)
				scene_util.set_emotion(titantavern_mouse, self, 'smile')
				scene_util.set_anim(titantavern_mouse, self, 'victory_extra')

				--변호사 (left, smile, dance)
				scene_util.set_direction(innuit_male, 'left', false)
				scene_util.set_emotion(innuit_male, self, 'smile')
				scene_util.set_anim(innuit_male, self, 'dance')

				--크루시엘 (left, smile, clap)
				scene_util.set_direction(squirrel_girl, 'left', false)
				scene_util.set_emotion(squirrel_girl, self, 'smile')
				scene_util.set_anim(squirrel_girl, self, 'clap')
			end
	)

	--0.5초 대기 후 아래 출력
	wait_for_sec(0.5)

	--변호사 (left, smile, dance): 아싸! 꽁으로 이겼다~!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(innuit_male, self, 'left',
			{ name = 'dance', keep = true }, { name = 'smile', keep = true },
			'mm_squirrel_girl_event_judgment_41')

	--크루시엘 (left, smile, clap): 좀 하는데, $name!
	scene_util.play_normal_speech_action(squirrel_girl, self, 'left',
			'clap', 'smile', 'mm_squirrel_girl_event_judgment_42')

	--아래 카메라 연출 동시 진행
	--카메라 크기 2.5로 줌 인
	camera_util.resize_by_ratio(2.5, 1)

	--1초간 포커스 검사로 변경
	camera_util.move_async(snowman_prosecutor.Position, 1)

	--아래 연출 동시진행
	--검사 jump 2회
	start_coroutine(character_util.normal_double_jump, snowman_prosecutor, '01_small_jump_01')

	--검사 (right, mad, idle): 으휴! 이 사고뭉치 녀석!
	music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
	scene_util.play_normal_speech_action(snowman_prosecutor, self, 'right',
			nil, { name = 'mad', keep = true },
			{ key = 'mm_squirrel_girl_event_judgment_43', skip = true, bubble_direction = 'cb' })

	--검사 (left, mad, idle)
	--검사 아래 동선 7의 속도로 이동
	wp_util.move(snowman_prosecutor, snowman_prosecutor.Position + vector(-7, 0, 0), 7)

	--0.5초 대기
	wait_for_sec(0.5)

	--가디언 (down, idle, idle)
	--크루시엘 (left, idle, idle)
	--변호사 (left, idle, idle)
	--쥐 (left, idle, idle)
	scene_util.set_direction(leader, 'down', false)
	scene_util.set_direction(squirrel_girl, 'left', false)
	scene_util.set_direction(snowman_prosecutor, 'left', false)
	scene_util.set_direction(titantavern_mouse, 'left', false)
	character_util.remove_group_anim_and_emotion({ squirrel_girl, leader, snowman_prosecutor, titantavern_mouse, innuit_male })

	--0.5초에 걸쳐 카메라 포커스 판사로 전환
	camera_util.move_async(innuit_judge.Position, 0.5)

	--판사 (down, idle, idle) : 음… 검사가 자리를 비웠으니 다음 재판까지는 휴정입니다.
	scene_util.play_normal_speech_action(innuit_judge, self,
			'down',
			nil,
			nil,
			{ key = 'mm_squirrel_girl_event_judgment_43_1', skip = true, bubble_direction = 'cb' })

	--판사 (down, idle, idle) : 다음 재판은… 어디보자.
	scene_util.play_normal_speech_action(innuit_judge, self,
			'down',
			nil,
			nil,
			{ key = 'mm_squirrel_girl_event_judgment_43_2', skip = true, bubble_direction = 'cb' })

	--판사 (down, tired, idle) : 쉬버링 테마의 아이스크림을 몽땅 녹였다고?
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.play_normal_speech_action(innuit_judge, self,
			'down',
			nil,
			'tired',
			{ key = 'mm_squirrel_girl_event_judgment_43_3', skip = true, bubble_direction = 'cb' })

	--판사 (down, smile, idle) : 아니, 이건 또 누굽니까? 얼굴 좀 봅시다.
	scene_util.play_normal_speech_action(innuit_judge, self,
			'down',
			nil,
			'smile',
			{ key = 'mm_squirrel_girl_event_judgment_43_4', skip = true, bubble_direction = 'cb' })

	--카메라 1초간 이동하여 아래 불타는 전사 포커스
	local burning_skull = self.character.burning_skull()
	camera_util.move_to_target_async(burning_skull, 1, { end_target = burning_skull })

	--1초에 걸쳐 불타는 전사 틴트 원상복구. 끝날 때까지 대기
	do
		local duration = 1

		music_player_util.play_stage_music({ name = 'bgm_trickery_theme', state = 'event', mix = 3, volume = 0.6 })
		music_player_util.play_sfx_one_shot('01_catch_fire_01')
		character_util.remove_fade_color(burning_skull, burning_skull.Name, duration)
		wait_for_sec(duration)
	end

	--불타는 전사 (up, idle, walk) 4의 속도로 이동하여 위 위치에 정렬 끝날 때까지 대기
	character_util.remove_anim(burning_skull)
	wp_util.move_async(burning_skull, burning_skull.Position + vector(0, 0, 3.5), nil, 4)

	--불타는 전사 도착 이후 (right, tired, cast) 상태로 전환
	scene_util.set_direction(burning_skull, 'right', false)
	scene_util.set_emotion(burning_skull, self, 'tired')
	scene_util.set_anim(burning_skull, self, 'cast')

	--0.5초 대기
	wait_for_sec(0.5)

	--불타는 전사 (right, tired, cast) sweat 이모티콘 출력, 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('01_gell_fall_down_01')
	scene_util.play_emoticon_action(burning_skull, self,
			'down',
			nil,
			'smile',
			'sweat')

	--불타는 전사 (right, tired, bomb_idle) : 내 머리에 불꽃만 없었다면 말이야….
	scene_util.play_normal_speech_action(burning_skull, self,
			'down',
			'bomb_idle',
			'smile',
			{ key = 'mm_squirrel_girl_event_judgment_43_5', skip = true, bubble_direction = 'cb' })

	--화면 1초에 걸쳐 전체 검게 페이드아웃
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	blizzard_loop_sfx:FadeOut(2)
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	--페이드 인 전 세팅

	--불타는 전사 화로와 상호작용 가능한 상태로 전환
	burning_skull.CombustibleBehaviour = CS.Oak.BurningSkullCombustibleBehaviour()
	burning_skull.Interactable.Talk = 'mm_squirrel_girl_event_judgment_43_5'

	--플레이어 파티 위치는 가디언 증언석 위치로 고정,
	camera_util.resize_to_default(0)
	camera_util.return_to_leader(0)
	party_util.remove_anim_and_emotion()
	party_util.align_party(self.marker.event_pos(6), 'left', 0, 'linear')

	--판사, 변호사 마지막 대사 원라인으로 전환
	character_util.remove_anim_and_emotion(innuit_male)
	character_util.remove_lua_listener(innuit_male, self)
	innuit_male.Interactable.Talk = 'mm_squirrel_girl_event_judgment_41_1'

	character_util.remove_anim_and_emotion(innuit_judge)
	innuit_judge.Interactable.Talk = 'mm_squirrel_girl_event_judgment_40_1'

	--화면 검게 페이드인
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self.controller.stage_event:clear_event(self.custom_state_key, 1)

	music_player_util.play_stage_music({ name = 'bgm_shivermore_main', state = 'field' })
	coroutine.yield(nil)
	coroutine.yield(nil)
	coroutine.yield(nil)

	quest_marker_util.add_auto_control('main_quest', {
		{ zone = 'forest_field', target = get_field_object('exit_1_1') },
		{ zone = 'teatan_field', target = get_field_object('exit_4_1') },
		{ zone = 'cave_field', target = get_field_object('exit_6_2') },
		{ zone = 'magic_school_field', target = get_field_object('exit_3_2') },
		{ zone = 'snow_field', target = get_character('adventurer_chris') },
	})

	music_player_util.start_bgm_manager()

	--플레이어 컨트롤 돌려준다.
	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(leader, { 'mouse_costume_clear' }))
end

function local_class:cleared_setting()
	local burning_skull = self.character.burning_skull()
	local innuit_male = self.character.innuit_male()
	local innuit_judge = self.character.innuit_judge()

	character_util.set_position(burning_skull, self.marker.event_pos(7) + vector(0, 0, 3.5))
	character_util.set_direction(burning_skull, 'down')
	character_util.remove_anim_and_emotion(burning_skull)
	burning_skull.Interactable = CS.Oak.NPCInteractable.Create()
	burning_skull.CombustibleBehaviour = CS.Oak.BurningSkullCombustibleBehaviour()
	burning_skull.Interactable.Talk = 'mm_squirrel_girl_event_judgment_43_5'

	character_util.set_position(innuit_male, self.marker.event_pos(3))
	character_util.set_direction(innuit_male, 'left')
	character_util.remove_anim_and_emotion(innuit_male)
	innuit_male.Interactable.Talk = 'mm_squirrel_girl_event_judgment_41_1'

	character_util.set_position(innuit_judge, self.marker.event_pos(1))
	character_util.set_direction(innuit_judge, 'down')
	character_util.remove_anim_and_emotion(innuit_judge)
	innuit_judge.Interactable.Talk = 'mm_squirrel_girl_event_judgment_40_1'
end

return {
	create = function()
		return local_class()
	end
}
