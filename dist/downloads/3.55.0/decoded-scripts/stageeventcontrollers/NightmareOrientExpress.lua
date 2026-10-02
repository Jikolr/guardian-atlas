local local_class = newclass('NightmareOrientExpressController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc
	self.get_train = function() return get_character('orient_express') end
	self.get_gentleman = function() return get_character('orient_express_gentleman') end
	self.get_npc = function(index) return get_character('orient_npc_' .. index) end

	-- 마커
	self.get_train_marker = function() return field:GetMarker('orient_express_pos').position end
	self.get_gentleman_marker = function() return field:GetMarker('orient_gentleman_pos').position end
	self.get_npc_marker = function(index) return field:GetMarker('orient_npc_pos_' .. index).position end

	self.gentleman_follow_id = 60
end

function local_class:load_resource()
	local gentleman = self.get_gentleman()
	local train = self.get_train()

	-- 팔로잉 여부에 따른 처리
	if not user_progress:IsFollowing(self.gentleman_follow_id) then
		-- 신사 세팅
		character_util.set_active_state(gentleman, 'enabled')
		gentleman.Position = self.get_gentleman_marker()

		-- 열차 세팅
		character_util.set_active_state(train, 'enabled')
		train.Position = self.get_train_marker()

		-- 주변 npc 세팅
		for i = 1, 6 do
			local npc = self.get_npc(i)
			character_util.set_active_state(npc, 'enabled')
			npc.Position = self.get_npc_marker(i)
		end

		character_util.add_listener(gentleman, self.cs_controller)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	character_util.remove_relate_event(self.get_gentleman(), self.cs_controller)

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(e)
	if type_util.is_interacted_target(e, self.get_gentleman()) then
		sp_util.play_normal_screenplay(self.talk_gentleman, self)
		return true
	end

	return false
end

--- 신사와 대화했을 때
function local_class:talk_gentleman()
	local gentleman = self.get_gentleman()
	character_util.remove_relate_event(gentleman, self.cs_controller)

	-- 주변 npc 대화 제거
	local npcs = {}
	for i = 1, 6 do
		local npc = self.get_npc(i)
		speech_bubble_util.remove_bubble(npc)
		table.insert(npcs, npc)
	end

	camera_util.move(gentleman.Position, 1)

	party_util.align_to_target(gentleman, 'down', 1, 'linear')

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_anim(gentleman, { name = 'question', loop = false })
	-- 아하, 그 헤실거리는 얼굴…
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_1', skip = true })

	character_util.remove_anim(gentleman)

	character_util.set_emotion(gentleman, { name = 'attack' })
	-- 무슈, 당신은 아마도 캔터베리인이지요?
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_2', skip = true })

	character_util.remove_emotion(gentleman)

	choose_util.play_choose_event({
		-- 그걸 어떻게!
		{ 'nightmare_orient_express_3' },
		-- 아닙니다만?
		{ 'nightmare_orient_express_4' }
	})

	-- 이런, 제가 초면에 다짜고짜 무례했군요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_5', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	character_util.set_direction(gentleman, 'left')
	-- 저는 제르퀼 피에로, 세계 최고의 명탐정입니다.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_6', skip = true })

	character_util.set_direction(gentleman, 'down')
	character_util.set_anim(gentleman, { name = 'cast' })
	-- 작은 회색 뇌세포를 이용해 진실을 찾아내는 것이 제 일이라고 할 수 있지요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_7', skip = true })

	character_util.remove_anim(gentleman)

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_anim(gentleman, { name = 'question', loop = false })
	-- 가령, 지금 열차를 기다리는 승객들에 대해 한 번 이야기해 볼까요?
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_8', skip = true })

	character_util.remove_anim(gentleman)

	character_util.set_direction(gentleman, 'up')
	-- 수다쟁이 부인에, 간호사, 가정교사, 그리고 군인.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_9', skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_direction(gentleman, 'down')
	character_util.set_anim(gentleman, { name = 'question', loop = false })
	-- 평범하기 짝이 없는 구성의 승객들이로군요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_10', skip = true })

	character_util.remove_anim(gentleman)

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	character_util.set_emotion(gentleman, { name = 'attack' })
	character_util.set_anim(gentleman, { name = 'cast2' })
	-- 지금 당장 살인 사건이 일어나도 이상하지 않아요!
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_11', skip = true })

	character_util.remove_anim_and_emotion(gentleman)

	-- 주변 npc들 ... 이모티콘
	music_player:PlaySfxOneShot('01_rustle_01')
	local npc_dir = { 'right', 'right', 'right', 'down', 'left', 'left' }
	for k, v in pairs(npcs) do
		character_util.set_direction(v, npc_dir[k])
		character_util.show_emoticon(v, nil, 'silence')
	end

	wait_for_sec(2)

	character_util.set_anim(gentleman, { name = 'release', sfx_name = '01_swing_01' })
	-- 말하자면 이런 식인 것입니다.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_12', skip = true })

	character_util.remove_anim(gentleman)

	-- 왼쪽으로 이동하며 대사
	music_player:PlaySfxOneShot('01_walk_02')
	wait_all({
		-- 아무 일도 없을 것처럼 평범한 승객들과 평화로운 열차…
		util.cs_generator(speech_bubble_util.show_speech_bubble_async, gentleman, { key = 'nightmare_orient_express_13' }),
		util.cs_generator(character_util.move_waypoint_async, gentleman, gentleman.Position + 2.5 * unity_class.vector3.left, 1)
	})

	-- 오른쪽으로 이동하며 대사
	music_player:PlaySfxOneShot('01_walk_02')
	wait_all({
		-- 밤 사이 폭설로 열차는 고립. 다음날 객실 문을 열어 보니…
		util.cs_generator(speech_bubble_util.show_speech_bubble_async, gentleman, { key = 'nightmare_orient_express_14' }),
		util.cs_generator(character_util.move_waypoint_async, gentleman, gentleman.Position + 2.5 * unity_class.vector3.right, 1)
	})

	music_player:PlaySfxOneShot('01_count_01')
	character_util.set_direction(gentleman, 'down')
	character_util.set_emotion(gentleman, { name = 'attack' })
	character_util.set_anim(gentleman, { name = 'cast2' })
	-- 앙콰야블! 피를 흘리며 식어가는 싸늘한 시체!
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_15', skip = true })

	character_util.remove_anim_and_emotion(gentleman)

	-- 이런, 이런. 열차 외부에 범인이 있을 수는 없는 상황…
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_16', skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_anim(gentleman, { name = 'question', loop = false })
	-- 그렇다면 이들 중 범인은 누구일까요? 그리고 그 동기는? 푸쿠와?
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_17', skip = true })

	local player_choice = choose_util.play_choose_event({
		-- 수다쟁이
		{ 'nightmare_orient_express_18' },
		-- 가정교사
		{ 'nightmare_orient_express_19' },
		-- 군인
		{ 'nightmare_orient_express_20' }
	})

	if player_choice == 1 then
		-- 말 많은 중년 부인의 탈을 쓴 살인범이라…
		speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_21', skip = true })

	elseif player_choice == 2 then
		-- 찔러도 피 한 방울 흘리지 않을 것 같은 단정한 가정교사 살인범이라…
		speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_22', skip = true })

	elseif player_choice == 3 then
		-- 신사다운 용모의 군인 살인범이라…
		speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_23', skip = true })
	end

	character_util.remove_anim(gentleman)

	-- 일리가 있군요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_24', skip = true })

	character_util.set_direction(gentleman, 'left')
	-- 하지만 무슈, 어쩌면 우리는 중요한 가능성 하나를 무시하고 있는지도 모릅니다.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_25', skip = true })

	-- 카메라 줌인하며 대사
	-- bgm_transition: Field(bgm_steampunk_main) -> Muted
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	local camera_duration = 1
	camera_util.resize_to(3, camera_duration)
	character_util.set_direction(gentleman, 'down')
	character_util.set_anim(gentleman, { name = 'question', loop = false })
	music_player:PlaySfxOneShot('01_rustle_01')
	wait_all({
		-- 그래요, 예를 들면…
		util.cs_generator(speech_bubble_util.show_speech_bubble_async, gentleman, { key = 'nightmare_orient_express_26' }),
		util.cs_generator(camera_util.move_async, gentleman.Position, camera_duration)
	})

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	character_util.set_emotion(gentleman, { name = 'attack' })
	-- 여기 있는 모두가 범인일 가능성이라든지.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_27', skip = true })

	character_util.remove_emotion(gentleman)

	-- 주변 npc들 놀람
	music_player:PlaySfxOneShot('01_crowd_shout_05')
	music_player:PlaySfxOneShot('01_jump_01')
	for _, v in pairs(npcs) do
		character_util.set_emotion(v, { name = 'surprise' })
		character_util.normal_jump(v)
	end

	wait_for_sec(1.5)

	-- 주변 npc들 두려움
	for _, v in pairs(npcs) do
		character_util.remove_emotion(v)
		character_util.set_emotion(v, { name = 'scared' })
	end

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	music_player:PlaySfxOneShot('01_clap_01')
	camera_util.shake(0.2, 0.3)
	character_util.set_emotion(gentleman, { name = 'awesome' })
	character_util.set_anim(gentleman, { name = 'clap' })
	-- 하하, 농담입니다!
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_28', skip = true })

	for _, v in pairs(npcs) do
		character_util.remove_emotion(v)
	end

	-- bgm_transition: Muted -> Field(bgm_steampunk_main)
	music_player_util.play_stage_music({ state = 'field', mix = 2 })
	camera_util.resize_to_default(1)
	wait_for_sec(1)

	character_util.remove_anim_and_emotion(gentleman)

	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.set_emotion(gentleman, { name = 'smile' })
	-- 그럴 리가 있겠습니까, 미스테리 소설 속이라면 모를까.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_29', skip = true })

	character_util.remove_emotion(gentleman)

	local train_sfx = music_player_util.play_sfx({ sfx_name = '01_train_02', loop = true, fade_in_time = 2 })
	character_util.set_direction(gentleman, 'left')
	character_util.normal_jump_async(gentleman, '01_jump_01')

	-- 쥐스트 아 뗌! 마침 열차가 들어오는군요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_30', skip = true })

	-- 들어오는 열차
	local train = self.get_train()
	local train_waypoint = {
		train.Position + vector(0, 0, -8),
		train.Position + vector(3.5, 0, -8)
	}
	character_util.move_waypoint_async(train, train_waypoint, 5)

	character_util.set_direction(gentleman, 'down')
	-- 무슈, 안타깝지만 우리의 대화는 여기서 줄여야겠습니다.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_31', skip = true })

	character_util.set_emotion(gentleman, { name = 'smile' })
	character_util.set_anim(gentleman, { name = 'release', sfx_name = '01_swing_01' })
	-- 대신 이것도 인연인데 연락처라도 서로 교환하시지요.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_34', skip = true })

	character_util.remove_anim(gentleman)

	yield_return_func(CS.Oak.AddSNSCoroutine, self.gentleman_follow_id)

	-- 메르시. 아주 좋습니다.
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_35', skip = true })

	character_util.set_animation_n_times(gentleman, { name = 'nod', count = 2, keep_anim = true })
	-- 그럼, 언젠가 또 볼 수 있기를. 아듀!
	speech_bubble_util.show_speech_bubble_async(gentleman, { key = 'nightmare_orient_express_36', skip = true })

	character_util.remove_anim(gentleman)

	character_util.move_waypoint_async(gentleman, train.Position + 2.2 * unity_class.vector3.right, 3)

	-- 열차 탑승하는 연출
	local ride_train = function(target)
		local ride_duration = 0.25
		character_util.spine_set_alpha_fade(target, 0, ride_duration)
		character_util.set_anim(target, { name = 'get' })

		local start_pos = target.Position
		local end_pos = target.Position + 0.7 * unity_class.vector3.left
		local time_passed = 0

		while time_passed < ride_duration do
			time_passed = time_passed + unity_class.time.deltaTime

			local progress = time_passed / ride_duration

			local cur_xz = unity_class.vector3.Lerp(start_pos, end_pos, progress)
			local cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress / 2) * 0.7

			target.Position = vector_util.get_x0z(cur_xz, cur_y)

			coroutine.yield(nil)
		end

		target.Position = vector(99, 0, 99)
		character_util.set_active_state(target, 'disabled')
	end

	wait_for_sec(0.5)

	-- 신사 열차 탑승
	music_player:PlaySfxOneShot('01_jump_01')
	ride_train(gentleman)

	music_player:PlaySfxOneShot('01_swing_01')
	for _, v in pairs(npcs) do
		character_util.set_direction(v, 'left')
	end

	wait_for_sec(1)

	-- 주변 npc들 쳐다보고 ... 이모티콘
	music_player:PlaySfxOneShot('01_rustle_01')
	npc_dir = { 'right', 'right', 'left', 'down', 'right', 'left' }
	for k, v in pairs(npcs) do
		character_util.set_direction(v, npc_dir[k])
		character_util.show_emoticon(v, nil, 'silence')
	end
	wait_for_sec(2)

	local all_riding = false

	-- npc들 이동 및 열차 탑승
	music_player:PlaySfxOneShot('01_dash_06')
	for k, v in pairs(npcs) do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			local waypoint = {
				vector(v.Position.x, 0, train.Position.z),
				train.Position + 2.2 * unity_class.vector3.right
			}
			character_util.move_waypoint_async(v, waypoint, 5)

			music_player:PlaySfxOneShot('01_jump_01')
			ride_train(v)

			if k == 6 then
				all_riding = true
			end
		end))

		wait_for_sec(0.2)
	end

	-- 열차에 전원 탑승까지 대기
	while not all_riding do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('01_train_01')
	-- 던전 왕국행 오리엔트 특급 열차. 지금 출발합니다.
	speech_bubble_util.show_speech_bubble_async(train,
		{ key = 'nightmare_orient_express_37', skip = true, bubble_type = 'shout', offset = vector(3, 0, 2.5) })

	-- 나가는 열차
	train_sfx:FadeOut(2)
	train_waypoint = {
		train.Position + vector(-3.5, 0, 0),
		train.Position + vector(-3.5, 0, 8)
	}
	character_util.move_waypoint_async(train, train_waypoint, 7)

	train.Position = vector(99, 0, 99)
	character_util.set_active_state(train, 'disabled')

	camera_util.return_to_leader(1)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
