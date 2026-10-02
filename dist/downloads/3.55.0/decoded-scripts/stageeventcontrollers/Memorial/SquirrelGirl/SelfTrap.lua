local local_class = newclass('MemorialSquirrelGirlSelfTrapController')

function local_class:init()
	self.controller = nil
	self.custom_state_key = nil

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	--state
	self.states = {
		none = 1,
		zone_event = 2,
		close_door = 3
	}

	self.current_state = self.states.none

	--npc
	self.character = {
		squirrel_girl = function()
			return get_character('squirrel_girl')
		end
	}

	--fo
	self.fo = {
		switch = function()
			return get_field_object('teatan_switch')
		end,
		door = function()
			return get_field_object('self_trap_door')
		end,
		open_door = function()
			return get_field_object('self_trap_door_open')
		end,
	}

	--marker
	self.marker = {
		self_trap_pos = function(number)
			return field_util.get_marker_pos('event_self_trap_pos_' .. number)
		end
	}

	self.fx = setmetatable({
		reset = function()
			return unity_object_pool.GetOrCreate('FX_reset_object')
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

	--크루시엘이 특수항 상황에 말하는 이벤트
	self.speech_event = setmetatable({
		-- 작은 바위
		small_rock_name = 'self_trap_small_rock_',
		small_rock_count = 3,
		-- 큰 바위
		big_rock_name = 'self_trap_big_rock',
		-- 테슬라 코일
		tesla_coil_name = 'self_trap_tesla_coil_',
		tesla_coil_count = 2,
		zone_name = 'self_trap_tesla_zone',
		-- 대사를 했는지 체크용
		show_event = { false, false, false }
	}, {
		__index = {
			broken_small_rock = function(this, fo)
				if this.show_event[1] then
					return
				end

				for i = 1, this.small_rock_count do
					if lua_helper.reference_equals(fo, get_field_object(this.small_rock_name .. i)) then
						this.show_event[1] = true
						start_coroutine(function()
							--1번 中 1종이라도 파괴 -> 크루시엘 : 헤헤, 위치가 너무 뻔한가.
							scene_util.show_portrait_speech_async(self.character.squirrel_girl(),
									'mm_squirrel_girl_event_self_trap_7', false)
						end)
						return
					end
				end
			end,
			broken_big_rock = function(this, fo)
				if this.show_event[2] then
					return
				end

				if lua_helper.reference_equals(fo, get_field_object(this.big_rock_name)) then
					this.show_event[2] = true
					start_coroutine(function()
						--2번 파괴 -> 크루시엘 : 잘한다, $name!
						scene_util.show_portrait_speech_async(self.character.squirrel_girl(),
								'mm_squirrel_girl_event_self_trap_8', false)
					end)
				end
			end,
			zone_enter_tesla = function(this, e)
				if this.show_event[3] then
					return
				end

				for i = 1, this.tesla_coil_count do
					if type_util.is_zone_full_enter(e, get_field_object(this.tesla_coil_name .. i), this.zone_name) then
						this.show_event[3] = true
						start_coroutine(function()
							--크루시엘 : 에휴, 거기다가 밀면 위로는 어떻게 옮기게?
							scene_util.show_portrait_speech_async(self.character.squirrel_girl(),
									'mm_squirrel_girl_event_self_trap_8_1', false)
						end)
						return
					end
				end
			end
		}
	})

	self.is_advice = false
end

function local_class:init_controller(controller, custom_state_key)
	self.controller = controller
	self.custom_state_key = custom_state_key

	local custom_state = quest_util.get_custom_state(self.controller.quest_progress, self.custom_state_key)

	if custom_state == 0 then
		self.current_state = self.states.zone_event
	end

	local open_door = self.fo.open_door()
	self.fo.door().Position = open_door.Position
	open_door.Position = vector(999, 0, 999)

	self.fx:create_all()

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.DoorClosedEvent), 'on_door_closed_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorClosedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.custom_state_key = nil
	self.controller = nil
end

function local_class:on_zone_enter_event(e)
	if self.current_state == self.states.none and
			type_util.is_zone_full_enter(e, get_party_leader(), 'self_trap_zone_1') then
		self.current_state = self.states.zone_event
		sp_util.start_scene(self.event_zone_scene, self)

		return true
	end

	if not self.is_advice and
			type_util.is_zone_full_enter(e, get_party_leader(), 'self_trap_advice_zone') then
		self.is_advice = true
		start_coroutine(function()
			--크루시엘 : 저기 뭔가 들어가고 싶게 생기지 않았어?
			scene_util.play_normal_speech_action(self.character.squirrel_girl(), self, nil,
					nil, nil, 'mm_squirrel_girl_event_self_trap_advice')
		end)

		return true
	end

	self.speech_event:zone_enter_tesla(e)

	return false
end

function local_class:on_door_closed_event(e)
	if self.current_state < self.states.close_door and e.DoorHandleName == self.fo.door().Name and
			field:GetZone('self_trap_zone_2'):Contains(get_party_leader().Position) then
		self.current_state = self.states.close_door
		sp_util.start_scene(self.door_zone_scene, self)

		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	self.speech_event:broken_small_rock(e.FieldObject)
	self.speech_event:broken_big_rock(e.FieldObject)

	return false
end

---크루시엘과 파티인 상태로 트리거존1 진입시 플레이어 컨트롤 빼앗고 강제로 아래 연출 진행
function local_class:event_zone_scene()
	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()

	music_player_util.change_stage_music_volume('field', 0.6)

	--카메라 포커스는 가디언
	speech_bubble_util.remove_bubble(squirrel_girl)
	--가디언과 크루시엘 현재 위치에서 아래 위치까지 1.5초간 이동 후 정렬.
	do
		local wp_key = 'leader_wp'

		wp_util.move_with_end_callback(leader, self.marker.self_trap_pos(1),
				nil, 1.5, self, wp_key, { last_direction = 'right' })
		wp_util.move_with_end_callback(squirrel_girl, self.marker.self_trap_pos(1) + vector(-1, 0, 0),
				nil, 1.5, self, wp_key, { last_direction = 'right' })

		wp_util.wait_move_end(self, wp_key)
	end

	--크루시엘 (right, tired, idle)
	scene_util.set_emotion(squirrel_girl, self, 'tired')
	--0.5초 대기
	wait_for_sec(0.5)

	--크루시엘 (left, tired, idle)
	scene_util.set_direction(squirrel_girl, 'left')
	--0.5초 대기
	wait_for_sec(0.5)

	--크루시엘 (right, tired, question 1회, 마지막 프레임 유지 ) question 이모티콘 출력. 끝날때까지 대기
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_emoticon_action(squirrel_girl, self, 'right',
			'question', 'tired', 'question')

	character_util.set_direction(leader, 'left')
	--크루시엘 (right, idle, idle): 이거 참 이상하다? $name, 나는 요 근처에 바위를 가져다 둔 기억이 없거든?
	scene_util.show_portrait_speech_async(squirrel_girl, 'mm_squirrel_girl_event_self_trap_1')

	--크루시엘 (right, tired, idle): 인부들한테 이런 걸 지시한 적도 없는데…
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			nil, 'tired', 'mm_squirrel_girl_event_self_trap_2')

	--크루시엘 (right, tired, question 1회, 마지막 프레임 유지) silence 이모티콘 출력. 끝날때까지 대기
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_emoticon_action(squirrel_girl, self, 'right',
			'question', 'tired', 'silence')

	--크루시엘 (right, idle, idle): 생각해보면 이 세상은 참 이상해, 그치? 왜 우리 주변엔 항상 커다란 바위들과 돌덩이들이 제멋대로 널브러져 있는 걸까?
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			nil, nil, 'mm_squirrel_girl_event_self_trap_3')

	--가디언 (left, tired, bomb_idle)
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.set_emotion(leader, self, 'tired')
	scene_util.set_anim(leader, self, 'bomb_idle')
	--1초 대기
	wait_for_sec(1)

	--가디언 (left, idle, idle)
	character_util.remove_anim_and_emotion(leader)
	--크루시엘 (right, tired, idle): 나는 철저하게 데카르트 변증법적 사고의 첫 단계를 이행하고 있을 뿐이야. 의심을 통한 확신의 탐구만이 진리없는 이 세상에 확실한 걸 남겨두는 법이니까.
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			nil, 'tired', 'mm_squirrel_girl_event_self_trap_4')

	--크루시엘 (right, smile, idle, jump 2회 끝날 때까지 대기) 저길 봐, $name! 저기 엄청 수상하게 생겼다!!
	start_coroutine(character_util.normal_double_jump, squirrel_girl, true)
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			nil, 'smile', 'mm_squirrel_girl_event_self_trap_5')

	--카메라 2초간 이미지의 노란 마름모 지점으로 이동
	camera_util.move_async(self.marker.self_trap_pos(3), 2)

	--2초 대기
	wait_for_sec(2)

	--다시 가디언으로 1초간 카메라 포커싱 이동
	camera_util.return_to_leader(1)

	--크루시엘 (right, doyagao, idle): 그럼 잘 부탁해! 나는 폭탄도 못 들고 바위도 못 부수걸랑.
	music_player_util.play_sfx_one_shot('01_fade_out_03')
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			nil, 'doyagao', 'mm_squirrel_girl_event_self_trap_6')

	music_player_util.change_stage_music_volume('field', 1)

	self.controller.stage_event:clear_event(self.custom_state_key, 0)
end

function local_class:door_zone_scene()
	local leader = get_party_leader()
	local squirrel_girl = self.character.squirrel_girl()
	local switch = self.fo.switch()
	local door = self.fo.door()
	local open_door = self.fo.open_door()

	music_player_util.change_stage_music_volume('field', 0.6)

	--가디언 (down, attack) run 애니 상태로 닫힌 door에 박치기 3회 반복
	character_util.set_direction(leader, 'down')
	scene_util.set_emotion(leader, self, 'attack')
	wait_for_sec(0.5)

	message_system:Publish(CS.Oak.DoorCloseEvent.Create(open_door.Name))

	local knock_back = function(target, duration, move_vector)
		local time_passed = 0
		local start_pos = target.Position
		local end_pos = target.Position + move_vector
		while true do
			local progress = CS.Oak.Interpolations.EaseOutCubic(time_passed, 0, 1, duration)
			if progress >= 1 then
				break
			end

			target.Position = unity_class.vector3.Lerp(start_pos, end_pos, progress)
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield(nil)
		end
	end

	local move_knight = function()
		local count = 3
		for i = 1, count do
			wp_util.move_async(leader, vector(leader.Position.x, 0, door.Position.z + 1.3),
					7, nil, { run = true })

			music_player_util.play_sfx_one_shot('01_hit_comic_01')
			scene_util.set_anim(leader, self, 'damaged')
			knock_back(leader, 0.5, vector(0, 0, 1))

			character_util.remove_anim(leader)
		end
	end

	move_knight()

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	character_util.set_direction(leader, 'right')
	scene_util.set_emotion(leader, self, 'cry')
	scene_util.set_anim(leader, self, 'seat')

	--0.5초 대기
	wait_for_sec(0.5)

	--크루시엘 파티 현 위치 (right , doyagao, cross_arm) tease 이모티콘 출력, 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('01_ghost_laugh_evil_01')
	scene_util.play_emoticon_action(squirrel_girl, self, 'right',
			{ name = 'cross_arm', one_shot_sfx = false }, 'doyagao', 'tease')

	--크루시엘 파티 현 위치에서 (right, attack, jump 1회) 1의 높이로 점프한다.
	character_util.set_direction(squirrel_girl, 'right')
	scene_util.set_emotion(squirrel_girl, self, 'attack')
	scene_util.set_anim(squirrel_girl, self, 'get')

	local jump_duration = 0.3
	local height = 1

	music_player_util.play_sfx_one_shot('01_jump_01')
	character_util.move_to_async(squirrel_girl, squirrel_girl.Position + unity_class.vector3.up * height, jump_duration)

	--점프 y축 최대치에 도달했을 때 아래 연출 동시 재생
	--크루시엘 위치에 FX_reset_object 출력한다.
	music_player_util.play_sfx_one_shot('01_character_warp_01')
	self.fx.reset():Instantiate(squirrel_girl.Position)
	--크루시엘 0.01초만에 알파페이드아웃되어 사라진다.
	character_util.spine_set_alpha_fade(squirrel_girl, 0, 0.01)
	--0.3초 대기
	wait_for_sec(0.3)

	--아래 연출 동시 재생
	--크루시엘 표시한 위치 + 동일한 y좌표에서 0.01초만에 알파페이드인 되어 나타난다.
	character_util.set_position(squirrel_girl, self.marker.self_trap_pos(2) + unity_class.vector3.up * height)
	character_util.spine_set_alpha_fade(squirrel_girl, 1, 0.01)
	self.fx.reset():Instantiate(squirrel_girl.Position)
	--자세는 (right, attack, jump)
	-- 나타나는 위치에 FX_reset_object 출력한다.
	--크루시엘 바닥에 착지 시 (right, idle, idle)
	character_util.move_to_async(squirrel_girl, vector_util.get_x0z(squirrel_girl.Position), jump_duration)

	--크루시엘 바닥에 착지 시 크루시엘 (right, idle, idle)
	character_util.remove_anim_and_emotion(squirrel_girl)

	--가디언 (down, surprised, cast) question 이모티콘 출력, 끝날 때까지 대기
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_emoticon_action(leader, self, 'down',
			'cast', 'surprise', 'question')

	--가디언 (down, confused, cast)
	scene_util.set_emotion(leader, self, 'confused')
	scene_util.set_anim(leader, self, 'cast')
	--크루시엘 (right, doyagao, bomb_idle): 왜? 순간이동하는 다람쥐 처음 봐?
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'bomb_idle', 'doyagao', 'mm_squirrel_girl_event_self_trap_8_2')

	--크루시엘 (right, idle, question 1회, 마지막 프레임 유지): 그나저나…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'question', 'idle', 'mm_squirrel_girl_event_self_trap_8_3')

	--크루시엘 (left, awesome, jump2회)  끝날 때까지 대기
	scene_util.set_emotion(squirrel_girl, self, 'awesome')
	character_util.normal_double_jump(squirrel_girl, true)

	--크루시엘 (right, doyagao, idle): 설마했는데 진짜 들어갈 줄이야!
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'idle', 'doyagao', 'mm_squirrel_girl_event_self_trap_9')

	--크루시엘 (right, doyagao, attack 반복): 바보야! 안에 아무것도 없거든~!
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'attack', 'doyagao', 'mm_squirrel_girl_event_self_trap_10')

	--크루시엘 (right, doyagao, bomb_idle): 아하하하, 이걸 코앞에서 직관하네.
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'bomb_idle', 'doyagao', 'mm_squirrel_girl_event_self_trap_11')

	--크루시엘 (right, doyagao, nod 2회 끝날 때까지 대기
	scene_util.set_emotion(squirrel_girl, self, 'doyagao')
	scene_util.set_anim_async(squirrel_girl, self, { name = 'nod', count = 2 })

	--크루시엘 (right, smile, bomb_idle): 덕분에 잘 웃었어! 이제 열어줄게.
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(squirrel_girl, self, 'right',
			'bomb_idle', 'smile', 'mm_squirrel_girl_event_self_trap_12')

	--크루시엘 up상태, 4의 속도로 걸어가 파란 버튼 활성화
	wp_util.move_async(squirrel_girl, self.marker.self_trap_pos(4), 4)

	--크루시엘의 인터랙트 이후 door는 계속 open 상태 유지
	open_door.Position = door.Position
	door.Position = vector(999, 0, 999)
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(open_door.Name, false))
	coroutine.yield()

	--크루시엘 (left, smile, idle)
	character_util.set_direction(squirrel_girl, 'left')
	scene_util.set_emotion(squirrel_girl, self, 'smile')
	--가디언 (right, smile, victory_extra)
	character_util.set_direction(leader, 'right')
	scene_util.set_emotion(leader, self, 'smile')
	scene_util.set_anim(leader, self, 'victory_extra')
	--2초 대기
	wait_for_sec(2)

	--가디언 (down, idle, idle)
	party_util.remove_anim_and_emotion()
	--가디언 4의 속도로 아래 이미지대로 이동
	wp_util.move_async(leader, leader.Position + vector(0, 0, -3), 4)

	music_player_util.change_stage_music_volume('field', 1)

	self.controller.stage_event:clear_event(self.custom_state_key, 1)
end

return {
	create = function()
		return local_class()
	end
}
