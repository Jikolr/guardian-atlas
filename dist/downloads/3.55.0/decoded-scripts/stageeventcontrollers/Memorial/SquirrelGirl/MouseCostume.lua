local local_class = newclass('MemorialSquirrelGirlMouseCostumeController')

function local_class:init()
	self.controller = nil
	self.custom_state_key = nil

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	--state
	self.states = {
		none = 1,
		talk_mouse = 2,
		zone_event = 3
	}

	self.current_state = self.states.none

	--npc
	self.character = {
		squirrel_girl = function()
			return get_character('squirrel_girl')
		end,
		mouse_nari = function()
			return get_character('mouse_nari')
		end,
		dokkaebi_mouse = function()
			return get_character('dokkaebi_mouse')
		end,
		snowman_kid_boy = function()
			return get_character('snowman_kid_boy')
		end,
		snowman_prosecutor = function()
			return get_character('snowman_prosecutor')
		end
	}

	--marker
	self.marker = {
		mouse_nari_pos = function(number)
			return field_util.get_marker_pos('event_mouse_nari_pos_' .. number)
		end,
		dokkaebi_mouse_pos = function(number)
			return field_util.get_marker_pos('event_dokkaebi_mouse_pos_' .. number)
		end,
	}

	-- fx
	self.fx = setmetatable({
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
	}, {
		__index = {
			create_all = function(this)
				for _, creator in pairs(this) do
					creator()
				end
			end
		}
	})

	self.sleep_sfx = nil
	self.is_quest_exit = false
	self.cleared_progress = 4
	self.is_loaded = false
end

function local_class:init_controller(controller, custom_state_key)
	self.controller = controller
	self.custom_state_key = custom_state_key

	--인형탈 이벤트는 메인 퀘스트 4섹션에 귀속된다.
	if self.controller.quest_progress.IsComplete then
		--메인 퀘스트 클리어 시 이벤트 비활성화
		return
	elseif self.controller.quest_progress.InnerProgress >= self.cleared_progress then
		--4섹션 이상 진행 시 이벤트 비활성화
		return
	end

	self.is_loaded = true

	--커스텀스테이트 초기화
	self.controller.stage_event:clear_event(self.custom_state_key, -1)

	self.fx:create_all()
	self:setting_npc()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end

function local_class:dispose()
	if not self.is_loaded then
		return
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	character_util.remove_lua_listener(self.character.mouse_nari(), self)

	self:stop_sleep_sfx()
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
	if self.current_state == self.states.none and
			type_util.is_interacted_target(e, self.character.mouse_nari()) then
		self.current_state = self.states.talk_mouse
		sp_util.start_scene(self.talk_mouse_nari_scene, self)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.current_state == self.states.talk_mouse and
			type_util.is_zone_full_enter(e, get_party_leader(), 'event_mouse_nari_zone') then
		self.current_state = self.states.zone_event
		start_coroutine(self.snowman_kid_boy_scene, self)

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'mouse_costume_clear' then
		start_coroutine(self.clear_setting, self)

		return true
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.is_quest_exit = true
	return true
end

function local_class:setting_npc()
	local mouse_nari = self.character.mouse_nari()
	local dokkaebi_mouse = self.character.dokkaebi_mouse()
	local snowman_kid_boy = self.character.snowman_kid_boy()

	local custom_state = quest_util.get_custom_state(self.controller.quest_progress, self.custom_state_key)

	if custom_state < 0 then
		character_util.set_position(mouse_nari, self.marker.mouse_nari_pos(1))
		character_util.set_direction(mouse_nari, 'right')
		scene_util.set_emotion(mouse_nari, self, 'sleep')
		scene_util.set_anim(mouse_nari, self, 'hurt')
		character_util.add_lua_listener(mouse_nari, self)
		self:set_sleep_sfx(mouse_nari)

		character_util.set_position(dokkaebi_mouse, self.marker.dokkaebi_mouse_pos(1))
		character_util.set_direction(dokkaebi_mouse, 'left')
		scene_util.set_emotion(dokkaebi_mouse, self, 'sleep')
		scene_util.set_anim(dokkaebi_mouse, self, 'sleep')
		dokkaebi_mouse.Interactable.Talk = 'mm_squirrel_girl_event_mouse_costume_1'
	else
		character_util.set_position(mouse_nari, self.marker.mouse_nari_pos(2))
		character_util.set_direction(mouse_nari, 'left')
		scene_util.set_emotion(mouse_nari, self, 'awesome')
		scene_util.set_anim(mouse_nari, self, 'dance')
		mouse_nari.Interactable.Talk = 'mm_squirrel_girl_event_mouse_costume_16'

		character_util.set_position(dokkaebi_mouse, self.marker.dokkaebi_mouse_pos(2))
		character_util.set_direction(dokkaebi_mouse, 'right')
		scene_util.set_emotion(dokkaebi_mouse, self, 'awesome')
		scene_util.set_anim(dokkaebi_mouse, self, 'dance')
		dokkaebi_mouse.Interactable.Talk = 'mm_squirrel_girl_event_mouse_costume_17'

		character_util.spine_set_alpha_fade(snowman_kid_boy, 0, 0)
		character_util.force_update_spines(snowman_kid_boy, 0.1)

		self.current_state = self.states.talk_mouse

		if custom_state == 1 then
			self.current_state = self.states.zone_event
			self:snowman_kid_boy_routine()
		end
	end
end

---땃쥐 npc와 인터랙트할 경우 즉시 컨트롤 빼앗습니다.
function local_class:talk_mouse_nari_scene()
	music_player_util.change_stage_music_volume('field', 0.6)
	quest_marker_util.remove_auto_control('nari_quest')

	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()
	local mouse_nari = self.character.mouse_nari()
	local dokkaebi_mouse = self.character.dokkaebi_mouse()
	--카메라 포커스는 가디언
	--1초에 걸쳐 크루시엘과 가디언 아래와 같이 정렬
	do
		local wp_key = 'leader_wp'

		wp_util.move_with_end_callback(leader, mouse_nari.Position + vector(2, 0, 0),
				nil, 1.5, self, wp_key, { last_direction = 'left' })
		wp_util.move_with_end_callback(squirrel_girl, mouse_nari.Position + vector(2, 0, -1),
				nil, 1.5, self, wp_key, { last_direction = 'left' })

		wp_util.wait_move_end(self, wp_key)
	end

	--아래 연출 진행
	--가디언 (left, idle, release 2회) 끝날 때까지 대기
	scene_util.set_anim_async(leader, self, { name = 'release', count = 2 })

	--가디언 (left, idle, idle)
	--땃쥐 (right, sleep, hurt) silence 이모티콘 출력, 끝날 때까지 대기
	scene_util.play_emoticon_action(mouse_nari, self, 'right',
			'hurt', 'sleep', 'silence')

	--땃쥐 (right, tired, seat): 우읏… 한참 좋았었는데…
	self:stop_sleep_sfx()
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			'seat', 'tired', 'mm_squirrel_girl_event_mouse_costume_2')

	--땃쥐 (right, attack): 0.5초간 높이 1 점프로 기상
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	scene_util.set_emotion(mouse_nari, self, 'attack')
	character_util.mario_jump_async(mouse_nari, 'right', 0.3, 0.4)

	--땃쥐 (right, mad, release) :[shout] 왜 자는 사람을 깨우고 난리야?!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_shout_speech_action(mouse_nari, self, 'right',
			'release', { name = 'mad', keep = true },
			'mm_squirrel_girl_event_mouse_costume_3')

	--선택지
	do
		local choose_result = choose_util.play_choose_event({
			--(mercy) 너희들은 왜 일을 안 해?
			{ 'mm_squirrel_girl_event_mouse_costume_4', 'mercy' },
			--(intellect) 무슨 쥐가 이렇게 커?!
			{ 'mm_squirrel_girl_event_mouse_costume_5', 'intellect' },
		})

		if choose_result == 1 then
			music_player_util.play_sfx_one_shot('01_rustle_01')
			--가디언 (left, tired, bomb_idle) question 이모티콘 출력 끝날 때까지 대기
			scene_util.play_emoticon_action(leader, self, 'left',
					'bomb_idle', 'tired', 'question')
		else

			--가디언 (left, tired, bomb_idle) question 이모티콘 출력 끝날 때까지 대기
			music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
			scene_util.play_emoticon_action(leader, self, 'left',
					'bomb_idle', 'tired', 'question')

			--땃쥐 (right, mad, jingak 2회): 인형탈이거든!
			music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
			scene_util.play_normal_speech_action(mouse_nari, self, 'right',
					{ name = 'jingak', count = 2, sfx_name = '01_jingak_01' }, 'mad',
					'mm_squirrel_girl_event_mouse_costume_6')
		end
	end

	--땃쥐 (right, tired, idle) annoyed 이모티콘 출력, 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')
	scene_util.play_emoticon_action(mouse_nari, self, 'right',
			nil, 'tired', 'annoyed')

	--땃쥐 (right, tired, idle): 우리는 파업할거야. 이제 지쳤어.
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			nil, 'tired', 'mm_squirrel_girl_event_mouse_costume_7')

	--땃쥐 (right, damaged, idle): 매일 오는 꼬마녀석이 우리만 보면 주먹질을 해 댄다고.
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			nil, 'damaged', 'mm_squirrel_girl_event_mouse_costume_8')

	--땃쥐 (right, damaged, release 2회): 아파 죽겠다니까!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			{ name = 'release', count = 2 }, 'damaged',
			'mm_squirrel_girl_event_mouse_costume_9')

	--땃쥐 (right, idle, bomb_idle): 뭐, 우리 두 명 인형탈 안 쓴다고 놀이공원이 안 돌아가는 것도 아니고…
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			'bomb_idle', nil,
			'mm_squirrel_girl_event_mouse_costume_10')

	--땃쥐 (right, doyagao, cross_arm): 오늘은 여기서 적당히 꿀좀 빨다가 퇴근할거야.
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			'cross_arm', 'doyagao',
			'mm_squirrel_girl_event_mouse_costume_11')

	--아래 연출 동시진행
	--jump 2회
	--크루시엘 (left, mad, cast2): 우씨… 듣자듣자 하니까!
	music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
	start_coroutine(character_util.normal_double_jump, squirrel_girl, '01_small_jump_01')
	scene_util.play_normal_speech_action(squirrel_girl, self, 'left',
			'cast2', 'mad', 'mm_squirrel_girl_event_mouse_costume_12')

	--아래 연출 동시에 진행
	--[화면 0.3값으로 0.3초 shake]
	camera_util.shake(0.3, 0.3)

	--가디언 (left, surprised,embarrassed) jump 1회
	scene_util.set_direction(leader, 'left', false)
	scene_util.set_emotion(leader, self, 'surprise')
	scene_util.set_anim(leader, self, 'embarrassed')
	character_util.normal_jump(leader)

	--땃쥐 (right, surprised, embarrassed) jump 1회
	scene_util.set_direction(mouse_nari, 'right', false)
	scene_util.set_emotion(mouse_nari, self, 'surprise')
	scene_util.set_anim(mouse_nari, self, 'embarrassed')
	character_util.normal_jump(mouse_nari)

	--멧쥐 (right, surprised, embarrassed) jump 1회
	scene_util.set_direction(dokkaebi_mouse, 'right', false)
	scene_util.set_emotion(dokkaebi_mouse, self, 'surprise')
	scene_util.set_anim(dokkaebi_mouse, self, 'embarrassed')
	character_util.normal_jump(dokkaebi_mouse)

	--크루시엘 (left, mad, release 2회) :  [shout]  야! 너네! 왜 농땡이 피워!
	music_player_util.play_sfx_one_shot('01_camera_emphasize_01')
	scene_util.play_shout_speech_action(squirrel_girl, self, 'left',
			{ name = 'release', count = 2 }, 'mad',
			'mm_squirrel_girl_event_mouse_costume_13')

	--아래 동시에 진행
	--가디언 (left, idle, idle)
	scene_util.set_direction(leader, 'left', false)
	character_util.remove_anim_and_emotion(leader)

	--멧쥐 (right, tired, idle)
	scene_util.set_direction(dokkaebi_mouse, 'right', false)
	scene_util.set_emotion(dokkaebi_mouse, self, 'tired')
	character_util.remove_anim(dokkaebi_mouse)

	--땃쥐 (right, surprised, cast): 헉! 크루시엘님..!
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			'cast', 'surprise',
			'mm_squirrel_girl_event_mouse_costume_14')

	--땃쥐 (right, surprised, cast2): 죄송해요! 작아서 계신 줄 몰랐어요!
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			'cast2', 'surprise',
			'mm_squirrel_girl_event_mouse_costume_14_1')

	--크루시엘 (left, mad, cast2) : 뭐뭐뭐… 뭣?!!
	--표정, 애니 유지
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(squirrel_girl, self, 'left',
			{ name = 'cast2', keep = true }, { name = 'mad', keep = true },
			'mm_squirrel_girl_event_mouse_costume_14_2')

	--땃쥐 (right, tired, idle): 죄송해요… 지금 나갈게요…
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	scene_util.play_normal_speech_action(mouse_nari, self, 'right',
			nil, { name = 'tired', keep = true },
			'mm_squirrel_girl_event_mouse_costume_15')

	--멧쥐, 땃쥐 1초간 아래 동선을 따라 이동
	do
		local wp_key = 'mouse_wp'
		local exit_pos = get_field_object('exit_6_2').Position
		local nari_fade_flag = true
		local dokkaebi_fade_flag = true

		wp_util.move_with_end_callback(mouse_nari, exit_pos + vector(-0.5, 0, 1),
				4, nil, self, wp_key, { callback = function()
					start_coroutine(function()
						character_util.spine_set_alpha_fade(mouse_nari, 0, 1)
						wait_for_sec(1)

						nari_fade_flag = false
					end)
				end })
		wp_util.move_with_end_callback(dokkaebi_mouse, exit_pos + vector(0.5, 0, 1),
				4, nil, self, wp_key, { callback = function()
					start_coroutine(function()
						character_util.spine_set_alpha_fade(dokkaebi_mouse, 0, 1)
						wait_for_sec(1)

						dokkaebi_fade_flag = false
					end)
				end })

		wp_util.wait_move_end(self, wp_key)

		while nari_fade_flag and dokkaebi_fade_flag do
			coroutine.yield(nil)
		end
	end

	--크루시엘 (left, attack, jingak 2회): 날 뭘로 보는거야! 정말…!
	scene_util.play_normal_speech_action(squirrel_girl, self,
			'left',
			{ name = 'jingak', count = 2, sfx_name = '01_jingak_01' },
			{ name = 'attack' },
			'mm_squirrel_girl_event_mouse_costume_15_1')

	character_util.remove_lua_listener(mouse_nari, self)
	self.controller.stage_event:clear_event(self.custom_state_key, 0)
	self:setting_npc()

	character_util.spine_set_alpha_fade(mouse_nari, 1, 0)
	character_util.spine_set_alpha_fade(dokkaebi_mouse, 1, 0)

	music_player_util.change_stage_music_volume('field', 1)
end

function local_class:snowman_kid_boy_scene()
	local snowman_kid_boy = self.character.snowman_kid_boy()
	local mouse_nari = self.character.mouse_nari()

	character_util.set_position(snowman_kid_boy, get_field_object('exit_4_2').Position)
	character_util.spine_set_alpha_fade(snowman_kid_boy, 1, 0.5)
	self.controller.stage_event:clear_event(self.custom_state_key, 1)
	--설꼬 7의 속도로 아래 위치로 정렬, 끝날 때까지 대기
	do
		local wp = wp_util.get_turn_once_wp(snowman_kid_boy,
				mouse_nari.Position + vector(-1, 0, -1), true)

		wp_util.move_async(snowman_kid_boy, wp, 7, nil, { run = true, last_direction = 'right' })
	end

	if self.is_quest_exit then
		return
	end

	--설꼬 (right, awesome, success 반복): 와! 찍찍이들아! 돌아왔구나!!
	scene_util.play_normal_speech_action(snowman_kid_boy, self, 'right',
			'success', { name = 'awesome', keep = true },
			'mm_squirrel_girl_event_mouse_costume_18')

	if self.is_quest_exit then
		return
	end

	do
		local wp = wp_util.get_turn_once_wp(snowman_kid_boy,
				mouse_nari.Position + vector(0.8, 0, 0), true)

		wp_util.move_async(snowman_kid_boy, wp, 7, nil, { run = true, last_direction = 'left' })
	end

	if self.is_quest_exit then
		return
	end

	--설꼬 (left, awesome, gauntlet_combo_attack 반복): 쥐엔장~ 한참 찾았다구~!
	self:snowman_kid_boy_routine()
	scene_util.show_normal_speech_async(snowman_kid_boy, 'mm_squirrel_girl_event_mouse_costume_19')
end

function local_class:snowman_kid_boy_routine()
	local snowman_kid_boy = self.character.snowman_kid_boy()
	local mouse_nari = self.character.mouse_nari()

	character_util.spine_set_alpha_fade(snowman_kid_boy, 1, 0)
	character_util.set_position(snowman_kid_boy, mouse_nari.Position + vector(0.8, 0, 0))
	character_util.set_direction(snowman_kid_boy, 'left')
	scene_util.set_emotion(snowman_kid_boy, self, 'awesome')
	snowman_kid_boy.Interactable.Talk = 'mm_squirrel_girl_event_mouse_costume_19'

	scene_util.set_anim(snowman_kid_boy, self, { name = 'gauntlet_combo_attack', sfx_name = function()
		--땃쥐 설꼬의  gauntlet_combo_attack 간격에 맞추어 피격연출, fx_hit 출력
		scene_util.set_emotion(mouse_nari, self, 'damaged')
		character_util.spine_damage_red_pulse(mouse_nari)
		character_util.spine_damage_squish_default(mouse_nari)
		music_player_util.play_sfx({ sfx_name = '01_hit_comic_01', parent = mouse_nari, volume = 0.5, loop = false })
		self.fx.hit():Instantiate(mouse_nari.Position + vector(0.3, 0.3, 0))
	end })
end

function local_class:clear_setting()
	local snowman_kid_boy = self.character.snowman_kid_boy()
	local mouse_nari = self.character.mouse_nari()
	local dokkaebi_mouse = self.character.dokkaebi_mouse()
	local snowman_prosecutor = self.character.snowman_prosecutor()

	--왼쪽 방 원라인 npc 세팅 다음과같이 변경
	--설꼬 (right, cry, seat): 우에엥… 아빠 죄송해요…
	character_util.set_position(snowman_kid_boy, dokkaebi_mouse.Position + vector(1, 0, -1))
	character_util.set_direction(snowman_kid_boy, 'right')
	scene_util.set_emotion(snowman_kid_boy, self, 'cry')
	scene_util.set_anim(snowman_kid_boy, self, 'seat')
	snowman_kid_boy.Interactable.Talk = 'mm_squirrel_girl_event_judgment_45'
	snowman_kid_boy.Interactable.TalkSfx = '03_dialogue_sadness_01'

	--땃쥐 (left, smile, victory_extra)
	scene_util.set_emotion(mouse_nari, self, 'smile')
	scene_util.set_anim(mouse_nari, self, 'victory_extra')
	mouse_nari.Interactable.Talk = nil

	--멧쥐 (right, smile, victory_extra)
	scene_util.set_emotion(dokkaebi_mouse, self, 'smile')
	scene_util.set_anim(dokkaebi_mouse, self, 'victory_extra')
	dokkaebi_mouse.Interactable.Talk = nil

	--검사 (left, attack, release 반복): 아빠 일하는 동안 사고치지 말라니깐!
	character_util.set_position(snowman_prosecutor, dokkaebi_mouse.Position + vector(2, 0, -1))
	scene_util.set_emotion(snowman_prosecutor, self, 'attack')
	scene_util.set_anim(snowman_prosecutor, self, 'release')
	snowman_prosecutor.Interactable.Talk = 'mm_squirrel_girl_event_judgment_44'

	self.controller.stage_event:clear_event(self.custom_state_key, 2)

	sp_util.exit_scene(nil, get_party_leader())
end

function local_class:set_sleep_sfx(parent)
	if self.sleep_sfx ~= nil then
		return
	end

	self.sleep_sfx = music_player_util.play_sfx({ sfx_name = '01_sleep_02', parent = parent, volume = 0.5, loop = true })
end

function local_class:stop_sleep_sfx()
	if self.sleep_sfx == nil then
		return
	end

	self.sleep_sfx:Stop()
end

return {
	create = function()
		return local_class()
	end
}
