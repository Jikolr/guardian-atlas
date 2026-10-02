local local_class = newclass('PastureTutorial')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 몬스터 매니저
	self.monster_manager = CS.Oak.HeavenHoldPastureSystem.Instance.MonsterManager

	-- 목장 시스템
	self.pasture_system = CS.Oak.Game.GetCurrentSubSystem()

	-- 함정 걸린 여부 체크(첫 튜토리얼)
	self.first_trapped = false

	-- 오랫동안 접속 안 했을 때 함정 발동
	self.long_time_trap = false

	-- 너굴걸 핸들네임
	self.raccoon_handle_name = 'npc_raccoon'

	-- 경비 몬스터 핸들네임(뒤에 1~2가 붙음)
	self.guard_handle_name = 'npc_guard'

	-- 몬스터 핸들네임(뒤에 1~4가 붙음)
	self.monster_handle_name = 'npc_monster'

	-- 목장 코인 아이템ID
	self.pasture_coin_id = 70027

	-- 트랩존 핸들 핸들네임
	self.trap_zone_name = 'trap_zone'

	-- 석상 위치
	self.egg_pos = vector(24, 0, 31)

	-- 로프 이펙트 핸들네임
	self.fx_rope_effect_name = 'rope_trap_top'

	-- 목장 존
	self.pasture_zone_handle_name = 'bigZone_1'

	-- 메인 BGM
	self.main_bgm_name = 'ondemand/pasture/audio:bgm_pasture_monster'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self:ambient_sound_off()

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource(
			self.fx_rope_effect_name
	)

	-- 튜토리얼 종료 여부 검사
	self.first_trapped = self.pasture_system.IsTutorialCleared

	-- 장기 미접속 여부 확인 
	if self.first_trapped == true and CS.UnityEngine.PlayerPrefs.GetInt('PastureLongTime', 0) == 1 then
		self.long_time_trap = true
	end

	-- 너굴걸 숨김 여부
	local npc = get_character(self.raccoon_handle_name)
	if self.first_trapped == false then
		npc.ActiveState = active_state('disabled')
	end

	-- 농장 중앙 좌표(최초 소환 몬스터 좌표 이동시 사용)
	self.pasture_center_pos = field_util.get_zone(self.pasture_zone_handle_name).Bounds.center

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

-------------------------------------------------

--region Main

-- 목장 입구에 처음 들어갔을 때, 함정 발동
function local_class:trapped()
	-- 로컬 상수
	local move_speed = 3

	-- 답변
	local answer

	-- 너굴걸 초기 위치 기억
	local npc = get_character(self.raccoon_handle_name)
	npc.ActiveState = active_state('enabled')
	self.raccoon_init_pos = npc.Position

	-- 너굴걸 위치 이동
	local npc_x = user_party.Leader.Position.x + 1
	local trap_dir = 'left'
	local jump_dir = 'right'
	local speech_dir = 'rt'
	local trap_zone_bounds = field_util.get_zone(self.trap_zone_name).Bounds
	if user_party.Leader.Position.x > trap_zone_bounds.center.x + 0.5 then
		npc_x = user_party.Leader.Position.x - 1
		trap_dir = 'right'
		jump_dir = 'left'
		speech_dir = 'lt'
	end
	npc.Position = vector(npc_x, 0, trap_zone_bounds.min.z + 6)

	-- 환경음 뮤트
	self:ambient_sound_off()
	self.trap_bgm_sfx = music_player_util.play_sfx({ sfx_name = '03_pet_bite_loop_01', loop = true, fade_in_time = 0 })

	-- 함정 애니메이션
	music_player:PlaySfxOneShot('01_ropetrap_activate_01')
	self.rope_state = CS.Oak.CharacterRopeTrappedState(user_party.Leader,
			character_util.get_direction(trap_dir), user_party.Leader.Position, self.fx_rope_effect_name)
	message_system:SendSync(user_party.Leader, CS.Oak.StateChangeEvent.Create(self.rope_state))

	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	character_util.hide_weapon(user_party.Leader, true)

	-- 경비견 좋아함
	local guard1 = get_character(self.guard_handle_name .. '1')
	local guard2 = get_character(self.guard_handle_name .. '2')
	character_util.set_direction(guard1, 'right')
	character_util.set_direction(guard2, 'left')
	character_util.set_anim_and_emotion(guard1, { name = 'happy' }, { name = 'smile' })
	character_util.set_anim_and_emotion(guard2, { name = 'happy' }, { name = 'smile' })

	wait_for_sec(1)

	-- 너굴걸이 걸어 나옴
	-- 귀여운 몬스터들아, 사악한 인베이더는 너굴걸이 처리했으니 안심하라구~
	character_util.move_to_async(npc, npc.Position + vector(0, 0, -5), nil,
			move_speed * 2, true, true)

	-- 플레이어 잡히고 나서 너굴걸 등장 이후, 멈춘 자리에서 hold_loop 상태로 double jump 먼저 해주고 대사
	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'smile' })
	character_util.normal_double_jump(npc, true)

	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech1')

	-- 플레이어에게 접근
	-- 어떤 나쁜 녀석인지 얼굴이나 볼까?
	character_util.set_anim(npc, { name = 'cast' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech2')
	self.trap_bgm_sfx:FadeOut(0.5)
	self.ambient_sound = music_player_util.play_sfx(
			{ sfx_name = '01_amb_village_02', loop = true, type_priority = 'loop', volume = 0.7 })
	character_util.remove_anim(npc)
	character_util.move_to_async(npc, vector(npc.Position.x, npc.Position.y, user_party.Leader.Position.z), nil,
			move_speed, true, true)
	self:face_to(npc, user_party.Leader.Position)

	-- 플레이어 얼굴을 봄
	wait_for_sec(0.5)
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.show_emoticon_async(npc, nil, 'question')
	character_util.set_anim_and_emotion(npc, { name = 'question', loop = false }, { name = 'tired' })
	character_util.remove_anim_and_emotion(guard1)
	character_util.remove_anim_and_emotion(guard2)

	-- 근데 이 헤실헤실한 얼굴은 인베이더가 아닌거 같은데?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech3', true, { bubble_direction = speech_dir })

	--선택지
	-- 1) 선량한 농부입니다. / 2) 강태공입니다.
	choose_util.play_choose_event({
		{ 'pasture_tutorial_speech4', 'mercy' },
		{ 'pasture_tutorial_speech5', 'intellect' }
	})

	-- 함정 풀어줌
	-- 뭐야, 몬스터를 노리는 인베이더가 아니었던 거야?
	character_util.remove_anim(npc)
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_anim_and_emotion(guard1, { name = 'hurt' }, { name = 'doyagao' })
	character_util.set_anim_and_emotion(guard2, { name = 'hurt' }, { name = 'doyagao' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech6', true, { bubble_direction = speech_dir })
	character_util.remove_emotion(npc)
	character_util.set_anim_and_emotion(guard1, { name = 'attack', loop = false }, { name = 'empty' })
	character_util.set_anim_and_emotion(guard2, { name = 'attack', loop = false }, { name = 'empty' })
	character_util.set_animation_n_times(npc, { name = 'attack', count = 1, end_call_func = function()
		character_util.set_anim(npc, { name = 'idle' })
	end })

	-- 풀려남
	character_util.remove_anim_and_emotion(user_party.Leader)
	self.rope_state:Fall()
	music_player_util.play_sfx_one_shot('01_pet_trap_deactivate_01')

	wait_for_sec(1)

	self.rope_state:End()
	self.rope_state = nil
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	character_util.mario_jump_async(user_party.Leader, jump_dir)
	self:face_to(user_party.Leader, npc.Position)

	-- 너굴걸 대사
	-- 오해해서 미안해. 여기를 노리는 나쁜 녀석들이 있거든.
	character_util.remove_anim_and_emotion(npc)
	character_util.remove_anim_and_emotion(guard1)
	character_util.remove_anim_and_emotion(guard2)
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech7')

	-- 그래서 다리까지 끊어놨는데, 어떻게 들어 온 거지?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim_and_emotion(npc, { name = 'question', loop = false }, { name = 'tired' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech8')

	-- 잠깐 침묵
	character_util.show_emoticon_async(npc, nil, 'silence')

	-- 그나저나 곤란하게 됐네..~ >> 너굴걸 cross_arm 모션 + sleep_deep 이모션
	character_util.set_anim_and_emotion(npc, { name = 'cross_arm' }, { name = 'sleep_deep' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech9')

	character_util.remove_anim_and_emotion(npc)

	-- 일단 날 따라와 줘.
	music_player_util.play_sfx_one_shot('01_swing_01')
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech10')
	character_util.set_direction(guard1, 'down')
	character_util.set_direction(guard2, 'down')

	-- 목장 본부까지 이동
	character_util.move_to(npc, npc.Position + vector(0, 0, 13), nil,
			move_speed, true, true)
	character_util.set_direction(user_party.Leader, 'up')
	wait_for_sec(0.5)
	character_util.move_to_async(user_party.Leader, user_party.Leader.Position + vector(0, 0, 13), nil,
			move_speed, true, true)

	-- 너굴걸의 목장 주제가
	self:face_to(npc, user_party.Leader.Position)
	self:face_to(user_party.Leader, npc.Position)
	wait_for_sec(0.5)

	-- Welcome to 어서와~♪ 몬스터 목장에~♪
	self.ambient_sound:FadeOut(0.5)
	music_player_util.play_stage_music({ name = self.main_bgm_name, state = 'field', volume = 0.5 })
	character_util.set_anim_and_emotion(npc, { name = 'bomb_idle' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech11')

	-- 귀여운 몬스터들이 한 가득~♪
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.set_anim_and_emotion(npc, { name = 'sing' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech12')

	-- 오늘도 우당탕탕 대소동이야~♪
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech13')

	-- 플레이어 ? 이모티콘 띄울 때 >> question 모션
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.set_anim(user_party.Leader, { name = 'question', loop = false })
	character_util.show_emoticon_async(user_party.Leader, nil, 'question')
	character_util.remove_anim(user_party.Leader)

	--선택지
	-- 1) 몬스터가 안 보이는데? / 2) 투명 드래곤 키우시나요?
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'question', loop = false })
	choose_util.play_choose_event({
		{ 'pasture_tutorial_speech14', 'mercy' },
		{ 'pasture_tutorial_speech15', 'brutal' }
	})

	character_util.set_anim_and_emotion(user_party.Leader, { name = 'bomb_idle' }, { name = 'doyagao' })
	wait_for_sec(0.5)

	-- 그건 네가 원인이야.
	character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
	character_util.set_emotion(npc, { name = 'attack' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech16')

	-- 이 섬은 외부에서 침입자가 들어오면 경보가 울리거든.
	music_player_util.play_sfx_one_shot('01_siren_oneshot_01')
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'idle' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech17')

	-- 경보를 듣고 몬스터들이 모두 뿔뿔이 도망가 버렸어…
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_anim_and_emotion(npc, { name = 'bomb_idle' }, { name = 'tired' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech18')

	-- 다시 몬스터를 불러 모아서 예전의 시끌벅적한 목장으로 돌아가고 싶어…
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	character_util.set_anim_and_emotion(npc, { name = 'seat', loop = false }, { name = 'tired' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech19')

	-- 좀 도와주지 않겠어?
	character_util.remove_anim(npc)
	character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech20')

	-- 선택지
	-- 1) 물론이지!! / 2) 어림도 없다. 암~
	answer = choose_util.play_choose_event({
		{ 'pasture_tutorial_speech21', 'mercy' },
		{ 'pasture_tutorial_speech22', 'brutal' }
	})

	if answer == 1 then
		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		character_util.set_anim_and_emotion(user_party.Leader, { name = 'victory_get', loop = false }, { name = 'smile' })
		wait_for_sec(2.5)
	elseif answer == 2 then
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		character_util.set_animation_n_times(user_party.Leader, { name = 'release', count = 2, sfx = '01_swing_01' })
		character_util.set_emotion(user_party.Leader, { name = 'attack' })
		wait_for_sec(1.5)

		-- 그러지말고 좀 도와줘. 네 잘못도 있잖아.
		character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
		character_util.set_emotion(npc, { name = 'attack' })
		scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech23')

		-- 0:34 씁, 어쩔수 없지. >> 선택지 빼고, 플레이어 tired 이모션 + 땀방울 이모티콘 노출 (emoticon_bubble_sweat)
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		character_util.set_emotion(user_party.Leader, { name = 'tired' })
		character_util.show_emoticon_async(user_party.Leader, nil, 'sweat')
	end

	-- 그럼 따라와.
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.remove_anim_and_emotion(npc)
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech25')
	wait_for_sec(0.1)

	-- 석상으로 이동
	character_util.move_to(npc, vector(self.egg_pos.x + 1, 0, npc.Position.z), nil,
			move_speed, true, true)
	while vector_util.distance(npc.Position, user_party.Leader.Position) < 2 do
		self:face_to(user_party.Leader, npc.Position)
		wait_for_sec(0.1)
	end
	character_util.move_to_async(user_party.Leader, vector(self.egg_pos.x - 1, 0, user_party.Leader.Position.z), nil,
			move_speed, true, true)
	character_util.move_to(user_party.Leader, vector(user_party.Leader.Position.x, 0, self.egg_pos.z - 1), nil,
			move_speed, true, true)
	character_util.move_to_async(npc, vector(npc.Position.x, 0, self.egg_pos.z - 1), nil,
			move_speed, true, true)

	wait_for_sec(1)

	-- 이 석상은 몬스터를 불러내는 힘이 있어.
	character_util.set_direction(npc, 'up')
	character_util.set_direction(user_party.Leader, 'up')
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech26')

	-- 네가 애정을 담아서 기도하면 먼 곳에 도망친 몬스터를 불러와 줄거야.
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_direction(npc, 'left')
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim(npc, { name = 'sing' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech27')

	-- 한 번 기도 해볼래?
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_anim(npc, { name = 'bomb_idle' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech28')
	character_util.remove_anim(npc)

	-- 한번 기도해볼래 대사 >> 플레이어 sing대신 smile 이모션 / nod 애니메이션 2회 이후 선택지 출력.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	character_util.nod_twice(user_party.Leader)
	wait_for_sec(0.3)

	--선택지
	-- 1) (내 동료가 되어줘…) / 2) (오늘 저녁은 뭘까?)
	answer = choose_util.play_choose_event({
		{ 'pasture_tutorial_speech29', 'mercy' },
		{ 'pasture_tutorial_speech30', 'brutal' }
	})

	-- 선택지 고르면, sing 모션으로 기도
	music_player_util.play_sfx_one_shot('01_rustle_02')
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'sing', scale = 0 }, { name = 'sleep_deep' })
	wait_for_sec(0.5)

	if answer == 2 then
		camera_util.resize_to(3, 2)
		wait_for_sec(2.5)

		character_util.remove_anim_and_emotion(user_party.Leader)
		character_util.set_emotion(npc, { name = 'tired' })
		character_util.show_emoticon_async(npc, nil, 'silence')

		camera_util.resize_to_default(1)
		wait_for_sec(1.25)

		-- 반응이 없네…
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(npc, { name = 'question', loop = false }, { name = 'tired' })
		scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech31')

		-- 너 딴 생각했지! 대사 칠 때 >> shoot 애니메이션
		music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
		character_util.set_anim_and_emotion(npc, { name = 'shoot' }, { name = 'attack' })
		character_util.set_emotion(user_party.Leader, { name = 'tired' })
		scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech32')

		-- 다시 한 번 기도 해봐.
		-- 0:57 다시 한번 기도 해봐. >> release 2회 애니메이션
		character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
		scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech33')
		character_util.remove_anim_and_emotion(npc)
		character_util.remove_emotion(user_party.Leader)

		-- (내 동료가 되어줘…)
		answer = choose_util.play_choose_event({
			{ 'pasture_tutorial_speech29', 'mercy' }
		})

		-- 선택지 고르면, sing 모션으로 기도
		music_player_util.play_sfx_one_shot('01_rustle_02')
		character_util.set_anim_and_emotion(user_party.Leader, { name = 'sing', scale = 0 }, { name = 'sleep_deep' })
		wait_for_sec(0.5)
	end

	camera_util.resize_to(3, 2)
	wait_for_sec(3)

	-- 클리어 처리
	coroutine.yield(self.pasture_system:ClearTutorial())

	-- 첫 소환
	local monsterInfo = CS.Oak.UserPasture.Me.Monsters[0];
	local monster = self.monster_manager:GetCharacterById(monsterInfo.Id);
	monster.Position = self.egg_pos + vector(0, 0, -1)
	character_util.set_direction(monster, 'down')
	monster.ActiveState = active_state('enabled')
	CS.Oak.HeavenHoldPastureSystem.Instance.ResourceManager:MonsterSummon(monster)
	wait_for_sec(5)
	CS.Oak.HeavenHoldPastureSystem.Instance.ResourceManager:DeactiveSummonVFX()
	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 너굴걸의 말
	camera_util.resize_to_default(1)
	wait_for_sec(1)

	-- 몬스터와 처음으로 동료가 된 것을 축하해!
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech34')

	-- 몬스터는 예민한 생물이니까 사랑으로 보듬어 줘야 해.
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_anim_and_emotion(npc, { name = 'bomb_idle' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech35')

	-- 삐지지 않게 매일 매일 돌봐주라구.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim_and_emotion(npc, { name = 'shoot' }, { name = 'attack' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech35_1')

	-- 1:57 먹는 것도 까다로워서~ >> attack 이모션이 아니라, smile 이모션 / release 애니메이션 2회
	-- 먹는 것도 까다로워서 자기가 먹는 것만 먹으니까 주의해야 해.
	character_util.set_emotion(npc, { name = 'smile' })
	character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech36')

	-- 이거 받아. 이 아이가 먹는 먹이야.
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech37')

	-- 먹이 크기
	local food = self.monster_manager:GetCorrespondingFoodId(monsterInfo)
	local food_scale = 1

	-- 맨드레이크
	if food.Id == 260001 then
		food_scale = 0.5
	-- 보석
	elseif food.Id == 260002 then
		food_scale = 0.75
	-- 에너지
	elseif food.Id == 260003 then
		food_scale = 0.75
	-- 고기
	elseif food.Id == 260004 then
		food_scale = 0.75
	end

	-- 먹이 던져줌
	character_util.set_emotion(npc, { name = 'attack' })
	character_util.set_animation_n_times(npc, { name = 'attack', count = 1 })
	music_player_util.play_sfx_one_shot('01_throw_01')
	drop_item_util.create_item({ pos = npc.Position, target = user_party.Leader.Position,
								itemid = food.Id, notforinven = true, lootstate = 'findlooter', sprscale = food_scale, showoncharacter = true })
	wait_for_sec(0.5)

	-- 마무리 멘트
	-- 그럼 곤란한 일이 있다면 언제든지 이 너굴걸을 찾아오라구~
	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'pasture_tutorial_speech38')
	character_util.remove_anim_and_emotion(npc)
	wait_for_sec(0.1)

	-- 초기 위치로 돌아감
	character_util.move_to_async(npc, vector(npc.Position.x, 0, self.raccoon_init_pos.z), nil, move_speed, true, true)
	character_util.move_to_async(npc, self.raccoon_init_pos, nil, move_speed, true, true)
	character_util.set_direction(npc, 'down')
	character_util.hide_weapon(user_party.Leader, false)

	-- 페이드 인 아웃 후 몬스터 로밍 시작
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	monster.Position = self.pasture_center_pos
	self.monster_manager:InitializeToMoveStateAll()
	wait_for_sec(0.3)
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	music_player_util.change_stage_music_volume('field', 1, 0)
end

-- 몬스터 등장
function local_class:monster_fly(number, start_pos, target_pos)
	local monster = get_character(self.monster_handle_name .. tostring(number))
	monster.Position = start_pos
	monster.SpineController:AddFadeColor('black', unity_color({ 0, 0, 0, 1 }), 1, 0)
	character_util.jump_move(monster, target_pos, 4, 4, true)
	coroutine.yield()
	character_util.set_direction(monster, 'down')
end

-- 몬스터 퇴장
function local_class:monster_back(number, move_vector, selected_number)
	if number == selected_number then
		return
	end

	local monster = get_character(self.monster_handle_name .. tostring(number))
	character_util.jump_move(monster, monster.Position + move_vector, 8, 4, true)
	monster.ActiveState = active_state('disabled')
end

-- 특정 위치를 바라봄
function local_class:face_to(fo, target_pos)
	local dir = vector_util.to_direction(target_pos - fo.Position)
	if dir ~= CS.Oak.Direction.None then
		fo.Direction = dir
	end
end

-- 어질리티 가이드
function local_class:agility_guide()
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	local npc = get_character(self.raccoon_handle_name)
	user_party.Leader.Position = npc.Position + vector(-2, 0, 0)
	self:face_to(npc, user_party.Leader.Position)
	self:face_to(user_party.Leader, npc.Position)
	character_util.set_emotion(npc, { name = 'tired' })
	character_util.set_emotion(user_party.Leader, { name = 'tired' })
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	scene_util.show_normal_speech_async(npc, 'agility_tutorial_speech1')
	scene_util.show_normal_speech_async(npc, 'agility_tutorial_speech2')
	character_util.remove_anim_and_emotion(npc)
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.set_direction(npc, 'down')
end

-- 어질리티 가이드 2단계
function local_class:agility_guide_expert()
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	local npc = get_character(self.raccoon_handle_name)
	user_party.Leader.Position = npc.Position + vector(-2, 0, 0)
	self:face_to(npc, user_party.Leader.Position)
	self:face_to(user_party.Leader, npc.Position)
	character_util.set_emotion(npc, { name = 'smile' })
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	character_util.set_anim_and_emotion(npc, { name = 'hold_loop' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'agility_tutorial_speech2_1')
	character_util.set_anim_and_emotion(npc, { name = 'bomb_idle' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'agility_tutorial_speech2_2')
	character_util.set_anim_and_emotion(npc, { name = 'idle' }, { name = 'smile' })
	scene_util.show_normal_speech_async(npc, 'agility_tutorial_speech2_3')
	character_util.remove_anim_and_emotion(npc)
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.set_direction(npc, 'down')
end

-- 장기 미접속시 이벤트
function local_class:long_time_event()
	-- 로컬 상수
	local move_speed = 3

	-- 너굴걸 초기 위치 기억
	local npc = get_character(self.raccoon_handle_name)
	npc.ActiveState = active_state('enabled')
	self.raccoon_init_pos = npc.Position

	-- 너굴걸 위치 이동
	local npc_x = user_party.Leader.Position.x + 1
	local trap_dir = 'left'
	local jump_dir = 'right'
	local speech_dir = 'rt'
	local trap_zone_bounds = field_util.get_zone(self.trap_zone_name).Bounds
	if user_party.Leader.Position.x > trap_zone_bounds.center.x + 0.5 then
		npc_x = user_party.Leader.Position.x - 1
		trap_dir = 'right'
		jump_dir = 'left'
		speech_dir = 'lt'
	end
	npc.Position = vector(npc_x, 0, trap_zone_bounds.min.z + 6)
	local npc_start_pos = npc.Position

	-- BGM 뮤트, 이벤트 BGM 재생
	music_player_util.play_stage_music({ state = 'muted' })
	self.trap_bgm_sfx = music_player_util.play_sfx({ sfx_name = '03_pet_bite_loop_01', loop = true, fade_in_time = 0 })

	-- 함정 애니메이션
	music_player:PlaySfxOneShot('01_ropetrap_activate_01')
	self.rope_state = CS.Oak.CharacterRopeTrappedState(user_party.Leader,
			character_util.get_direction(trap_dir), user_party.Leader.Position, self.fx_rope_effect_name)
	message_system:SendSync(user_party.Leader, CS.Oak.StateChangeEvent.Create(self.rope_state))

	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	character_util.hide_weapon(user_party.Leader, true)

	-- 경비견 좋아함
	local guard1 = get_character(self.guard_handle_name .. '1')
	local guard2 = get_character(self.guard_handle_name .. '2')
	character_util.set_direction(guard1, 'right')
	character_util.set_direction(guard2, 'left')
	character_util.set_anim_and_emotion(guard1, { name = 'happy' }, { name = 'smile' })
	character_util.set_anim_and_emotion(guard2, { name = 'happy' }, { name = 'smile' })

	wait_for_sec(1)

	-- 너굴걸이 걸어 나옴
	character_util.set_emotion(npc, { name = 'attack' })
	character_util.move_to_async(npc, vector(npc.Position.x, 0, user_party.Leader.Position.z), nil,
			move_speed * 2, true, true)

	-- 플레이어에게 접근
	self:face_to(npc, user_party.Leader.Position)
	wait_for_sec(0.5)
	-- 아아... 인베이더인줄 알았네.
	character_util.set_anim(npc, { name = 'cross_arm' })
	scene_util.show_normal_speech_async(npc, 'pasture_longtime_speech1')

	-- 너무 오랜만이라 얼굴을 까먹었지 뭐야.
	scene_util.show_normal_speech_async(npc, 'pasture_longtime_speech2')

	-- 애들도 네 얼굴 잊었을지 몰라
	character_util.set_emotion(npc, { name = 'tired' })
	character_util.set_anim(npc, { name = 'bomb_idle' })
	scene_util.show_normal_speech_async(npc, 'pasture_longtime_speech3')
	character_util.remove_emotion(npc)

	-- 함정 풀어줌
	character_util.remove_emotion(guard1)
	character_util.remove_emotion(guard2)
	character_util.set_anim(guard1, { name = 'attack', loop = false })
	character_util.set_anim(guard2, { name = 'attack', loop = false })
	character_util.set_animation_n_times(npc, { name = 'attack', count = 1, end_call_func = function()
		character_util.set_anim(npc, { name = 'idle' })
	end })

	-- 풀려남
	self.trap_bgm_sfx:FadeOut(2)
	character_util.remove_anim_and_emotion(user_party.Leader)
	self.rope_state:Fall()
	music_player_util.play_sfx_one_shot('01_pet_trap_deactivate_01')

	wait_for_sec(1)

	self.rope_state:End()
	self.rope_state = nil
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	character_util.mario_jump_async(user_party.Leader, jump_dir)
	self:face_to(user_party.Leader, npc.Position)
	character_util.hide_weapon(user_party.Leader, false)

	-- 너굴걸이 돌아감
	character_util.set_animation_n_times(npc, { name = 'release', count = 2, sfx = '01_swing_01' })
	character_util.set_emotion(npc, { name = 'attack' })
	-- 얼굴 잊지 않게 자주 찾아와 달라구
	scene_util.show_normal_speech_async(npc, 'pasture_longtime_speech4', true, { bubble_direction = speech_dir })
	character_util.move_to_async(npc, npc_start_pos, nil, move_speed * 2, true, true)
	coroutine.yield()
	npc.Position = self.raccoon_init_pos
	character_util.remove_anim_and_emotion(npc)
	character_util.remove_anim_and_emotion(guard1)
	character_util.remove_anim_and_emotion(guard2)
	character_util.set_direction(npc, 'down')
	character_util.set_direction(guard1, 'down')
	character_util.set_direction(guard2, 'down')

	music_player_util.play_stage_music({ name = self.main_bgm_name, state = 'field' })
end

-- 환경음 끄기
function local_class:ambient_sound_off()
	if self.ambient_sound ~= nil then
		self.ambient_sound:Stop()
		self.ambient_sound = nil
	end
end

-- endregion

-----------------------------------------------------------------------------------------------------------------

--region Event

function local_class:on_zone_enter_event(e)
	-- 함정 존에 들어왔을 때
	if type_util.is_zone_full_enter(e, user_party.Leader, 'trap_zone') then
		-- 튜토리얼 트랩
		if self.first_trapped == false then
			sp_util.play_normal_screenplay(self.trapped, self)
			self.first_trapped = true
		-- 오랜만에 들어와서 트랩
		elseif self.long_time_trap == true then
			sp_util.play_normal_screenplay(self.long_time_event, self)
			self.long_time_trap = false
			CS.UnityEngine.PlayerPrefs.SetInt('PastureLongTime', 0)
			CS.UnityEngine.PlayerPrefs.Save()
		end
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'agility_guide' then
		sp_util.play_normal_screenplay(self.agility_guide, self)
	elseif e:GetParamAt(0) == 'agility_guide_expert' then
		sp_util.play_normal_screenplay(self.agility_guide_expert, self)
	end

	return false
end

function local_class:on_stage_loaded()
	-- 튜토리얼 진행 안 한 상태에서 BGM 뮤트
	if self.first_trapped == false then
		CS.Oak.MusicPlayer.Instance:RemoveStageMusicClip(CS.Oak.StageBgmState.Field)
	end

	return false
end

function local_class:on_stage_start()
	-- 환경음 재생
	if self.first_trapped == false then
		self.ambient_sound = music_player_util.play_sfx(
				{ sfx_name = '01_amb_village_02', loop = true, type_priority = 'loop', volume = 0.7 })
	end
	return false
end

--endregion

return {
	create = function(data_path, data_key, cs_behaviour)
		return local_class(data_path, data_key, cs_behaviour)
	end
}