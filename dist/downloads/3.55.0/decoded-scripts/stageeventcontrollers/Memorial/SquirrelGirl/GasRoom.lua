local local_class = newclass('MemorialSquirrelGirlGasRoomController')

function local_class:init()
	self.controller = nil
	self.custom_state_key = nil

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	--state
	self.states = {
		none = 1,
		show_event = 2,
	}

	self.current_state = self.states.none

	--npc
	self.character = {
		citizen_male = function()
			return get_character('citizen_male')
		end,
		tourist_male = function()
			return get_character('tourist_male')
		end,
	}

	--fo
	self.fo = {
		board = function()
			return get_field_object('event_gas_board')
		end
	}

	--marker
	self.marker = {
		event_pos = function(number)
			return field_util.get_marker_pos('event_gas_pos_' .. number)
		end,
	}
end

function local_class:init_controller(controller, custom_state_key)
	self.controller = controller
	self.custom_state_key = custom_state_key

	self:setting_npc()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.custom_state_key = nil
	self.controller = nil
end

function local_class:on_interact_event(e)
	if self.current_state == self.states.none and
			type_util.is_interacted_target(e, self.fo.board()) then
		self.current_state = self.states.show_event
		sp_util.start_scene(self.gas_room_scene, self)

		return true
	end

	return false
end

function local_class:setting_npc()
	--기본 세팅
	--이용객1 (up)
	local citizen_male = self.character.citizen_male()

	character_util.set_position(citizen_male, self.marker.event_pos(1))
	character_util.set_direction(citizen_male, 'up')

	local tourist_male = self.character.tourist_male()

	character_util.set_direction(tourist_male, 'down')
	character_util.spine_set_alpha_fade(tourist_male, 0, 0)
	character_util.force_update_spines(tourist_male, 0.1)

	local sign_board = self.fo.board()

	sign_board.Interactable = CS.Oak.PublishInteractable.Create()
end

---가스실 앞에 있는 표지판과 상호작용시 컨트롤 빼앗고 연출 진행한다.
function local_class:gas_room_scene()
	music_player_util.change_stage_music_volume('field', 0.6)

	local leader = get_party_leader()
	local sign_board = self.fo.board()
	local citizen_male = self.character.citizen_male()
	local tourist_male = self.character.tourist_male()

	music_player_util.change_stage_music_volume('field', 0.6)

	--아래와 같은 위치에 0.5초간 플레이어 정렬
	do
		local wp_key = 'leader_wp'

		for i = 0, user_party.Count - 1 do
			local wp = sign_board.Position + vector(i, 0, -1)

			wp_util.move_with_end_callback(user_party[i], wp, nil, 0.5,
					self, wp_key, { last_direction = 'up' })
		end

		wp_util.wait_move_end(self, wp_key)
	end

	--다음 나레이션 출력
	--가스실
	field_ui_util.show_narration_async({ key = 'mm_squirrel_girl_event_gas_1' })

	--아래 연출 동시 진행
	--가디언 jump 1회
	character_util.normal_jump(leader, '01_jump_01')

	--가디언 (up, embarrassed) notice 이모티콘. 끝날 때까지 대기
	scene_util.play_emoticon_action(leader, self, nil,
			'embarrassed', nil, 'notice')

	--선택지 재생
	do
		local choose_result = choose_util.play_choose_event({
			--(brutal) 테마파크에 가스실을 넣어놨다고? 제정신이야?!
			{ 'mm_squirrel_girl_event_gas_2', 'brutal' },
			--(intellect) 이건 미친 짓이야. 난 여기서 나가겠어.
			{ 'mm_squirrel_girl_event_gas_3', 'intellect' },
		})

		if choose_result == 1 then
			--가디언 (left, attack, jingak 2회) 끝날 때까지 대기
			scene_util.set_direction(leader, 'left', false)
			scene_util.set_emotion(leader, self, 'attack')
			scene_util.set_anim_async(leader, self, { name = 'jingak', count = 2, sfx_name = '01_jingak_01' })
		else
			--가디언 (left, scared, release 2회) 끝날 때까지 대기
			scene_util.set_direction(leader, 'left', false)
			scene_util.set_emotion(leader, self, 'scared')
			scene_util.set_anim_async(leader, self, { name = 'release', count = 2 })
		end
	end

	--이용객1 (right, tired, question 1회 마지막 프레임 유지) question 이모티콘. 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_emoticon_action(citizen_male, self, { dir = 'right', sfx = false },
			'question', 'tired', 'question')

	--이용객1 (right, tired, idle): 갑자기 왜 그러시는 건가요?
	scene_util.play_normal_speech_action(citizen_male, self, 'right',
			nil, 'tired', 'mm_squirrel_girl_event_gas_4')

	--가디언 (left, attack, release 2회) 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.set_direction(leader, 'left', false)
	scene_util.set_emotion(leader, self, 'attack')
	scene_util.set_anim_async(leader, self, { name = 'release', count = 2 })

	--0.5초 대기
	wait_for_sec(0.5)

	--이용객1 (right, tired, cast): 다짜고짜 들어가지 말라고 말을 하셔도…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(citizen_male, self, 'right',
			'cast', 'tired', 'mm_squirrel_girl_event_gas_5')

	--0.5초 대기
	wait_for_sec(0.5)

	--다음 연출 동시 진행

	--가디언 (up, idle)
	--이용객1 (up, idle)
	character_util.remove_group_anim_and_emotion({ leader, citizen_male })
	scene_util.set_group_direction({ leader, citizen_male }, 'up')
	--아래 위치에 이용객2 (down, idle, idle) 1초간 페이드 인
	music_player_util.play_sfx_one_shot('01_door_push_01')
	character_util.set_position(tourist_male, self.marker.event_pos(2))
	character_util.spine_set_alpha_fade(tourist_male, 1, 1)
	wait_for_sec(1)

	--이용객2 (down, blush, idle): 아으~ 시원~~ 하다…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.play_normal_speech_action(tourist_male, self, 'down',
			nil, 'blush', 'mm_squirrel_girl_event_gas_6')

	--1초간 아래 연출 동시 재생
	--가디언 (left, blush, idle)
	scene_util.set_direction(leader, 'left', false)
	scene_util.set_emotion(leader, self, 'blush')

	--이용객 (right, tired, bomb_idle)
	scene_util.set_direction(citizen_male, 'right', false)
	scene_util.set_emotion(citizen_male, self, 'tired')
	scene_util.set_anim(citizen_male, self, 'bomb_idle')
	wait_for_sec(1)

	--이용객2 4의 속도로 아래 동선을 따라 이동 후
	--도착지점에서 1초간 페이드아웃. 끝날 때까지 대기 안 함.
	do
		local wp = {
			tourist_male.Position + vector(-1, 0, 0),
			tourist_male.Position + vector(-1, 0, -2),
			tourist_male.Position + vector(20, 0, -2),
		}

		wp_util.move(tourist_male, wp, 4)
	end

	--0.5초 대기
	wait_for_sec(0.5)

	--다음 연출 동시에 재생
	--이용객1 (right, tired, bomb_idle): 여기 화장실이거든요…
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.play_normal_speech_action(citizen_male, self, 'right',
			'bomb_idle', 'tired', 'mm_squirrel_girl_event_gas_7')

	--가디언 (left, blush, idle) 상태로 0.5초 대기
	scene_util.set_direction(leader, 'left', false)
	scene_util.set_emotion(leader, self, 'blush')
	wait_for_sec(0.5)

	--0.5초 이후 가디언 (left, blush, nod 3회) 끝날 때까지 대기
	scene_util.set_direction(leader, 'left', false)
	scene_util.set_emotion(leader, self, 'blush')
	scene_util.set_anim_async(leader, self, { name = 'nod', count = 3 })

	character_util.remove_anim_and_emotion(leader)
	--이용객1 (up, idle) 4의 속도로 1칸 이동 후, 1초간 페이드아웃. 끝날 때까지 대기
	wp_util.move_async(citizen_male, self.marker.event_pos(2), 4)

	music_player_util.play_sfx_one_shot('01_door_push_01')
	character_util.spine_set_alpha_fade(citizen_male, 0, 1)
	wait_for_sec(1)

	--1초 대기
	wait_for_sec(1)

	--이용객 1: [화면shake  (0.3, 0.3초)], [shout] 아오 냄새!
	music_player_util.play_sfx_one_shot('01_camera_emphasize_01')
	camera_util.shake(0.3, 0.3)
	--(화면비) x : 0.4 , y: 0.6
	scene_util.show_shout_speech_async(citizen_male, 'mm_squirrel_girl_event_gas_8',
			true, { viewport_pos = vector(0.4, 0.6) })

	--플레이어 컨트롤 돌려줍니다.
	character_util.stop(tourist_male)
	character_util.set_position(citizen_male, vector(999, 0, 999))
	character_util.set_position(tourist_male, vector(999, 0, 999))

	local narration_interactable = CS.Oak.NarrationInteractable()
	narration_interactable.StringKeys = { 'mm_squirrel_girl_event_gas_1' }
	sign_board.Interactable = narration_interactable

	music_player_util.change_stage_music_volume('field', 1)

	self.controller.stage_event:clear_event(self.custom_state_key, 1)

	music_player_util.change_stage_music_volume('field', 1)
end

return {
	create = function()
		return local_class()
	end
}
