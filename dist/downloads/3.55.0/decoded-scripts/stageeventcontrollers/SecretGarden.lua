local local_class = newclass('SecretGardenController')

function local_class:init_scene()
	--- action cache
	self.action = {
		--- character util
		dir = function (x) character_util.set_direction(table.unpack(x)) end,
		emo = function (x) character_util.set_emotion(table.unpack(x)) end,
		ani = function (x) character_util.set_anim(table.unpack(x)) end,
		emoji = function (x) character_util.show_emoticon(table.unpack(x)) end,
		aemoji = function (x) character_util.show_emoticon_async(table.unpack(x)) end,
		remove_emo = function (x) character_util.remove_emotion(table.unpack(x)) end,
		remove_ani = function (x) character_util.remove_anim(table.unpack(x)) end,
		remove_all = function (x) character_util.remove_anim_and_emotion(table.unpack(x)) end,
		mario = function (x) character_util.mario_jump_async(table.unpack(x)) end,
		jump = function (x)
			local fo, height, duration = table.unpack(x)
			if height and duration then
				character_util.jump(fo, height, duration)
			else
				character_util.normal_jump(fo)
			end
		end,
		move = function (x) character_util.move_to(table.unpack(x)) end,
		amove = function (x) character_util.move_to_async(table.unpack(x)) end,
		shake = function (x) character_util.shake(table.unpack(x)) end,
		pos = function (x) character_util.set_position(table.unpack(x)) end,
		alpha = function(x) character_util.spine_set_alpha_fade(table.unpack(x)) end,
		rotate = function(x) character_util.spine_rotate(table.unpack(x)) end,
		talk = function (x) speech_bubble_util.show_speech_bubble_async(table.unpack(x)) end,

		--- ui util
		narration = function (x) field_ui_util.show_narration_async(table.unpack(x)) end,

		--- yield func
		wait = function (x) wait_for_sec(x) end,

		--- screen util
		fade_in = function (x) screen_util.fade_in_async(table.unpack(x)) end,
		fade_out = function (x)
			local duration, color, f = table.unpack(x)
			--- 중간에 다른 색상이 방해하는 것을 막기 위해 setfadecolor
			CS.Oak.FadeScreenTransition.Instance:SetFadeColor(unity_color({color.r, color.g, color.b, 0}))
			screen_util.fade_out(duration, color, f)
		end,
		tint = function (x) field:Tint(table.unpack(x)) end,
		remove_tint = function (x) field:RemoveTint(nil, x) end,

		--- camera_util
		camera_move = function (x) camera_util.move_async(table.unpack(x)) end,
		camera_shake = function (x) camera_util.shake(table.unpack(x)) end,
		camera_resize = function (x) camera_util.resize_to(table.unpack(x)) end,
		camera_reset = function (duration)
			--- fallback
			if duration ~= nil then duration = 0 end

			camera_util.cancel_shake()
			camera_util.move_async(user_party_leader.Position, duration, { end_target = user_party_leader})
			camera_util.resize_to_default(duration)
		end,

		--- music player
		one_shot = function (x) music_player:PlaySfxOneShot(x) end,
		play_sfx = function (x) music_player_util.play_sfx(x) end,
		play_stage_music = function(x) music_player_util.play_stage_music(x) end,

		play_sfx_loop = function(x)
			self.audio_holder = music_player_util.play_sfx(x)
		end,

		fade_sfx_loop = function(x)
			self.audio_holder:FadeOut(x)
		end,

		--- etc util
		fx = function (x)
			local preset_name, target_pos, name = table.unpack(x)
			local preset = unity_object_pool.GetOrCreate(preset_name)
			local fx = preset:Instantiate(target_pos)

			if name then
				self.fx[name] = fx
			end
		end,

		fx_dispose = function(x)
			self.fx[table.unpack(x)]:Dispose()
		end,

		--- Rope Traped State
		rope = function (x)
			self.action['fx'](x)
			self.fx['rope'].transform.localScale = vector(1.7, 1.2, 1.2)

			for index = 1, 5 do
				self.fx['rope'].transform:GetChild(index).gameObject:SetActive(false)
			end
		end,

		add_color = function (x)
			local target, color, magnitude, duration = table.unpack(x)
			target.SpineController:AddColor(target.Name, color, magnitude, duration)
		end,

		mod = function (x)
			CS.GlobalTimeManager.Instance:Mod(table.unpack(x))
		end,

		unmod = function (x)
			CS.GlobalTimeManager.Instance:Unmod(table.unpack(x))
		end
	}

	local heinz = 'heinz'
	local milia = 'milia'
	local villager_1 = 'villager_1'
	local villager_2 = 'villager_2'
	local villager_3 = 'villager_3'
	local kid_1 = 'kid_1'
	local kid_2 = 'kid_2'
	local kid_3 = 'kid_3'

	local name = { heinz, milia, villager_1, villager_2, villager_3, kid_1, kid_2, kid_3 }
	local npc = {}

	for index = 1, #name do
		npc[name[index]] = function() return get_character(name[index]) end
	end

	--- action param
	self.param = {
		{
			'ani', { user_party_leader, { name = 'bomb_attack', remove_after = 0.4 }},
			'wait', 0.2,
			'grave_refresh', nil,
			'wait', 0.8,
			--- 눈보라 종료 요청
			'blizzard_end', nil,
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Field(bgm_shivermore_main) -> Muted, Mix 2
			'play_stage_music', { state = 'muted', mix = 2 },
			--- 회상으로 페이드
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			'camera_move', { vector(-7.5, 0, 83), 0 },
			'camera_resize', { 3.3, 0 },
			--- 하인즈 세팅
			'pos', { npc[heinz](), vector(-7, 0, 83) },
			'dir', { npc[heinz](), 'left' },
			--- 밀리아 세팅
			'pos', { npc[milia](), vector(-8, 0, 83) },
			'dir', { npc[milia](), 'right' },
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(-7.5, 0, 78) },
			'dir', { npc[villager_1](), 'up' },
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(-7, 0, 77) },
			'dir', { npc[villager_2](), 'up' },
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(-8, 0, 77) },
			'dir', { npc[villager_3](), 'up' },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'wait', 0.5 ,
			--- 밀리아 : 들었어? 벌써 5명째 실종 됐대…
			'ani', { npc[milia](), { name = 'push' }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_1_1', skip = true }},
			'remove_ani', { npc[milia]() },
			--- 하인즈 : 당신도 조심해. 한동안은 나가지 않는게 좋겠어.
			'ani', { npc[heinz](), { name = 'nod', remove_after = 0.433 }},
			'talk', { npc[heinz](), { key = 'substage_secret_garden_1_2', skip = true }},
			'remove_ani', { npc[heinz]() },
			--- 밀리아 : 하지만… 우리 꽃밭을 돌보려면 어쩔 수 없는 걸요.
			'talk', { npc[milia](), { key = 'substage_secret_garden_1_2_1', skip = true }},
			--- 밖에서 수상한 소리가 들림
			'camera_shake', { 0.4, 0.3 },
			--- 카메라 셰이크 사운드
			'one_shot', '03_mech_stomp_01',
			'wait', 0.5,
			'dir', { npc[heinz](), 'down' },
			'dir', { npc[milia](), 'down' },
			--- 마을 사람 : 이 안에 있는게 틀림 없어!
			'one_shot', '03_dialogue_negative_01',
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_1_3', bubble_type = 'shout', skip = true, world_pos = vector(-8, 0, 81) }},
			--- 마을 사람 : 부숴!
			'one_shot', '02_boss_sapa_shout_01',
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_1_4', bubble_type = 'shout', skip = true, world_pos = vector(-8, 0, 81) }},
			'camera_shake', { 0.4, 0.3 },
			--- 부서지는 이펙트 생성
			'fx', { 'FX_Common_SmokeScreen', vector(-7.5, 0, 80) },
			--- 부서지는 사운드
			'one_shot', '02_hit_earth_01',
			'wait', 0.4,
			'ani', { npc[heinz](), { name = 'embarrassed' }},
			'emo', { npc[heinz](), { name = 'tired' }},
			'ani', { npc[milia](), { name = 'embarrassed' }},
			'emo', { npc[milia](), { name = 'tired' }},
			'wait', 0.1,
			--- 마을 사람들 입장
			'move', { npc[villager_1](), vector(-7.5, 0, 81), nil, 4, true, true, true }, -- 달려오는 사운드
			'move', { npc[villager_2](), vector(-7, 0, 80), nil,  4, true, true },
			'amove', { npc[villager_3](), vector(-8, 0, 80), nil,  4, true, true },
			--- 당황하는 애니메이션 삭제
			'remove_ani', { npc[heinz]() },
			'remove_emo', { npc[heinz]() },
			'remove_ani', { npc[milia]() },
			'remove_emo', { npc[milia]() },
			--- 마을 사람 : 역시 여기 숨어 있었군.
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_1_5', skip = true, bubble_direction = 'ct' }},
			--- 밀리아 : 여… 여보!
			'one_shot', '03_runaway_01',
			'emo', { npc[milia](), { name = 'scared' }},
			'shake', { npc[milia](), 0.04, 0.5 },
			'talk', { npc[milia](), { key = 'substage_secret_garden_1_6', skip = true }},
			--- 하인즈 : 대체 이게 무슨 일입니까?
			'ani', { npc[heinz](), { name = 'release', sfx_name = '01_swing_01' }},
			'talk', { npc[heinz](), { key = 'substage_secret_garden_1_7', skip = true }},
			'remove_emo', { npc[milia]() },
			'remove_ani', { npc[heinz]() },
			--- 마을사람 : 뻔뻔하긴, 실종 사건 범인… 당신이잖아?
			'one_shot', '03_dialogue_negative_01',
			'ani', { npc[villager_1](), { name = 'taunt', scale = 0.5 }},
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_1_8', skip = true, bubble_direction = 'ct' }},
			'remove_ani', { npc[villager_1]() },
			--- 밀리아 : 그게 무슨 소리예요?!
			'ani', { npc[milia](), { name = 'dualgun_reload_start' }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_1_9', skip = true }},
			'remove_ani', { npc[milia]() },
			--- 마을사람 : 우리 마을은 지난 30년간 이런 일이 한 번도 없었어.
			'ani', { npc[villager_2](), { name = 'attack', sfx_name = '01_swing_01' }},
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_1_10', skip = true, bubble_direction = 'ct' }},
			'remove_ani', { npc[villager_2]() },
			--- 마을사람 : 인간들은 이런 끔찍한 일을 밥 먹듯이 한다며?
			'ani', { npc[villager_3](), { name = 'twohand_attack', remove_after = 1.133 }},
			'talk', { npc[villager_3](), { key = 'substage_secret_garden_1_11', skip = true, bubble_direction = 'ct' }},
			--- 밀리아 : 저는 결백합니다! 그런 말도 안되는 이유로…!
			'jump', { npc[heinz](), '01_jump_01' },
			'talk', { npc[heinz](), { key = 'substage_secret_garden_1_12', skip = true }},
			--- 마을사람 : 흥, 결백한지는 얼음 마녀님이 판단해 주실 거다.
			'ani', { npc[villager_1](), { name = 'cast' }},
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_1_13', skip = true, bubble_direction = 'ct' }},
			--- 마을사람 : 끌고 가!
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_1_14', skip = true, bubble_direction = 'ct' }},
			--- 끌고 가려함
			'ani', { npc[heinz](), { name = 'embarrassed', upper = true }},
			'emo', { npc[heinz](), { name = 'surprise' }},
			'ani', { npc[milia](), { name = 'embarrassed', upper = true }},
			'emo', { npc[milia](), { name = 'tired' }},
			'move', { npc[heinz](), vector(-7, 0, 84), nil, 0.3, false, true },
			'move', { npc[milia](), vector(-8, 0, 84), nil, 0.3, false, true },
			'move', { npc[villager_2](), vector(-7, 0, 83), nil, 2.5, true, true },
			'move', { npc[villager_3](), vector(-8, 0, 83), nil, 2.5, true, true },
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Muted -> Field(bgm_shivermore_main) , Mix 2
			'play_stage_music', { state = 'field', mix = 2 },
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			--- 객체 애니메이션 초기화
			'remove_ani', { npc[heinz](), true },
			'remove_emo', { npc[heinz]() },
			'remove_ani', { npc[milia](), true },
			'remove_emo', { npc[milia]() },
			'remove_ani', { npc[villager_1]() },
			'camera_reset', { },
			--- 필드 눈보라 세팅
			'blizzard_start', { 1, 1 },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'focus_to_brazier', nil,
			'wait', 0.5
		},
		{
			'ani', { user_party_leader, { name = 'bomb_attack', remove_after = 0.4 }},
			'wait', 0.2,
			'grave_refresh', nil,
			'wait', 0.8,
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Field(bgm_shivermore_main) -> Event(bgm_cave_main), Mix 2
			'play_stage_music', { name = 'bgm_cave_main', state = 'event', mix = 2 },
			--- 회상으로 페이드
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			'camera_move', { vector(28, 0, 80), 0 },
			'camera_resize', { 3.3, 0 },
			--- 하인즈 세팅
			'pos', { npc[heinz](), vector(28, 0, 79) },
			'rope', { 'rope_trap', vector(28, 0, 78.7), 'rope' },
			'dir', { npc[heinz](), 'down' },
			'emo', { npc[heinz](), { name = 'tired' }},
			'ani', { npc[heinz](), { name = 'skill_cyclone', scale = 0.2 }},
			--- 밀리아 세팅
			'pos', { npc[milia](), vector(27, 0, 79) },
			'dir', { npc[milia](), 'right' },
			'emo', { npc[milia](), { name = 'scared' }},
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(28, 0, 81) },
			'dir', { npc[villager_1](), 'down' },
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(26.5, 0, 81.7) },
			'dir', { npc[villager_2](), 'down' },
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(29.5, 0, 81.7) },
			'dir', { npc[villager_3](), 'down' },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'wait', 0.5,
			--- 마을사람 1 : 내일 동이 틀때까지 살아남으면, 결백한 걸로 인정하지.
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_2_1', skip = true, bubble_direction = 'ct' }},
			--- 밀리아 : 이 추위에 그게 가능할 거 같아요?!
			'one_shot', '03_dialogue_negative_02',
			'shake', { npc[milia](), 0.04, 0.5 },
			'emo', { npc[milia](), { name = 'mad' }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_2_2', skip = true }},
			--- 마을사람 2 : 정말 결백하면, 얼음 마녀님께서 살려주실 거라고.
			'ani', { npc[villager_2](), { name = 'cast' }},
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_2_3', skip = true, bubble_direction = 'ct' }},
			'remove_ani', { npc[villager_2]() },
			--- 마을사람 3 : 지금 범인이 맞으니까 그러는 거 아냐?
			'emo', { npc[heinz](), { name = 'tired' }},
			'ani', { npc[villager_3](), { name = 'bomb_attack', remove_after = 0.5, sfx_name = '01_swing_01' }},
			'talk', { npc[villager_3](), { key = 'substage_secret_garden_2_4', skip = true, bubble_direction = 'ct' }},
			'amove', { npc[milia](), vector(27, 0, 80), 0.2, nil, true, true, true }, -- 달려오는 사운드
			--- 밀리아 : 뭐라고요?!
			'one_shot', '03_dialogue_negative_01',
			'emo', { npc[milia](), { name = 'surprise' }},
			'ani', { npc[milia](), { name = 'throw' }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_2_5', bubble_type = 'shout', skip = true }},
			'remove_ani', { npc[milia]() },
			'remove_emo', { npc[milia]() },
			'one_shot', '03_runaway_01',
			'ani', { npc[milia](), { name = 'embarrassed', upper = true }},
			'wait', 0.5,

			'fade_out', { 1, unity_class.color.black, 'linear' },
			'wait', 1,
			'move', { npc[villager_1](), vector(28, 0, 89), nil, 12, true, true },
			'move', { npc[villager_2](), vector(26.5, 0, 89), nil, 12, true, true },
			'move', { npc[villager_3](), vector(29.5, 0, 89), 0, 12, true, true },
			'amove', { npc[milia](), vector(29, 0, 79), 0, nil, true, true, true },
			'remove_ani', { npc[milia](), true },
			'remove_emo', { npc[milia]() },
			'dir', { npc[milia](), 'left' },
			'emo', { npc[milia](), { name = 'scared' }},
			'ani', { npc[milia](), { name = 'seat', scale = 1 }},
			'tint', { unity_color({ 0.6, 0.6, 0.6 }), 0 },
			'fade_in', { 1, unity_class.color.black, 'linear' },
			'wait', 0.5,

			--- 하인즈를 점점 파랗게
			'add_color', { npc[heinz](), unity_color({ 0.3, 0.3, 0.7 }), 1, 5 },
			--- 애니메이션 스케일 되돌림
			'ani', { npc[heinz](), { name = 'skill_cyclone', scale = 0.2 }},
			'ani', { npc[milia](), { name = 'seat', scale = 1 }},

			--- 하인즈 : 미안해, 밀리아. 내가 이누이트였다면……
			'one_shot', '01_rustle_01',
			'talk', { npc[heinz](), { key = 'substage_secret_garden_2_6', skip = true, bubble_direction = 'ct' }},
			--- 밀리아 : 조금만… 조금만 참아요! 아침이 얼마 안남았어요.
			'talk', { npc[milia](), { key = 'substage_secret_garden_2_7', skip = true }},

			'wait', 0.5,
			'fade_out', { 1, unity_class.color.black, 'linear' },
			'wait', 1,
			'tint', { unity_color({ 0.2, 0.2, 0.2 }), 0 },
			'fade_in', { 1, unity_class.color.black, 'linear' },
			'wait', 0.5,

			--- 하인즈 : 미안… 난 여기까진 가봐.
			'one_shot', '01_rustle_01',
			'ani', { npc[heinz](), { name = 'skill_cyclone', scale = 0.1 }},
			'talk', { npc[heinz](), { key = 'substage_secret_garden_2_8', skip = true, bubble_direction = 'ct' }},
			'ani', { npc[heinz](), { name = 'skill_cyclone', scale = 0 }},
			--- 밀리아 : 하인즈!!!
			'one_shot', '03_dialogue_negative_01',
			'jump', { npc[milia]() },
			'ani', { npc[milia](), { name = 'throw', sfx_name = '01_swing_01' }},
			'emo', { npc[milia](), { name = 'surprise' }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_2_9', skip = true }},
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Muted -> Field(bgm_shivermore_main) , Mix 2
			'play_stage_music', { state = 'field', mix = 2 },
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			'remove_tint', 0,
			'remove_ani', { npc[milia]() },
			'camera_reset', { },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'focus_to_brazier', nil,
			'wait', 0.5
		},
		{
			'ani', { user_party_leader, { name = 'bomb_attack', remove_after = 0.4 }},
			'wait', 0.2,
			'grave_refresh', nil,
			'wait', 0.8,
			--- 필드 눈보라 삭제
			'blizzard_end', nil,
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Field(bgm_shivermore_main) -> Muted, Mix 2
			'play_stage_music', { state = 'muted', mix = 2 },
			--- 회상으로 페이드
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			'camera_move', { vector(28, 0, 79), 0 },
			'camera_resize', { 3.3, 0 },
			--- 하인즈 세팅
			'add_color', { npc[heinz](), unity_color({ 0.3, 0.3, 0.7 }), 1, 0 },
			'emo', { npc[heinz](), { name = 'damaged' }},
			'ani', { npc[heinz](), { name = 'skill_cyclone', scale = 0 }},
			--- 밀리아 세팅
			'emo', { npc[milia](), { name = 'cry', scale = 0 }},
			'ani', { npc[milia](), { name = 'seat' }},
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(28, 0, 80) },
			'dir', { npc[villager_1](), 'down' },
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(27.5, 0, 80.6) },
			'dir', { npc[villager_2](), 'down' },
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(28.5, 0, 80.6) },
			'dir', { npc[villager_3](), 'down' },
			--- 아이 1 세팅
			'pos', { npc[kid_1](), vector(34.8, 0, 80) },
			'dir', { npc[kid_1](), 'left' },
			'emo', { npc[kid_1](), 'smile' },
			'alpha', { npc[kid_1](), 0, 0 },
			--- 아이 2 세팅
			'pos', { npc[kid_2](), vector(35, 0, 80.6) },
			'dir', { npc[kid_2](), 'left' },
			'alpha', { npc[kid_2](), 0, 0 },
			'emo', { npc[kid_2](), 'tired' },
			--- 아이 3 세팅
			'pos', { npc[kid_3](), vector(35, 0, 79.4) },
			'dir', { npc[kid_3](), 'left' },
			'alpha', { npc[kid_3](), 0, 0 },
			'emo', { npc[kid_3](), 'tired' },
			--- 미리 움직이도록
			'move', { npc[villager_2](), vector(27.5, 0, 80.2), nil, 1.6, true, true },
			'move', { npc[villager_3](), vector(28.5, 0, 80.2), nil, 1.6, true, false },
			'move', { npc[villager_1](), vector(28, 0, 79.5), nil, 1.6, true, true },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'wait', 0.3,
			'play_sfx_loop', { sfx_name = '03_equipping_01' },
			'wait', 0.2,
			--- 하인즈의 죽음을 확인하는 마을사람
			'one_shot', '01_female_cry_02',
			'dir', { npc[villager_1](), 'right'},
			'ani', { npc[villager_1](), { name = 'eat' }},
			'fade_sfx_loop', 0.2,
			'wait', 2,
			'remove_ani', { npc[villager_1]() },
			--- 마을사람 : 역시 죽었군. 범인이었던게 틀림 없어.
			'ani', { npc[villager_1](), { name = 'bomb_attack', remove_after = 0.5 }},
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_3_1', skip = true }},
			--- 마을사람 : 우리 눈은 못 속인다니까!
			'emo', { npc[villager_2](), { name = 'attack' }},
			'ani', { npc[villager_2](), { name = 'throw', sfx_name = '01_swing_01' }},
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_3_2', skip = true }},
			'remove_ani', { npc[villager_2]() },
			'remove_emo', { npc[villager_2]() },
			--- 밀리아 : …….
			'talk', { npc[milia](), { key = 'substage_secret_garden_3_3', skip = true }},

			--- 아이 1 : 아빠? 아저씨? 저희 찾고 계셨던 거예요?
			'one_shot', '03_dialogue_negative_01',
			'camera_shake', { 0.4, 0.3 },
			'talk', { npc[kid_1](), { key = 'substage_secret_garden_3_4', bubble_type = 'shout', skip = true, world_pos = vector(27.5, 0, 78.5) }},
			'dir', { npc[villager_1](), 'right' },
			'dir', { npc[villager_2](), 'right' },
			'dir', { npc[villager_3](), 'right' },
			'dir', { npc[milia](), 'right' },
			--- 밀리아 일어나는 사운드
			'one_shot', '01_rustle_01',
			'remove_ani', { npc[milia]() },
			'remove_emo', { npc[milia]() },
			--- bgm_transition : Muted -> Event(bgm_cave_main), Mix 2
			'play_stage_music', { name = 'bgm_cave_main', state = 'event', mix = 2 },
			--- 그때 아이들이 마을 밖에서 온다
			'camera_move', { vector(29, 0, 79), 1 },
			'alpha', { npc[kid_1](), 1, 0.5 },
			'alpha', { npc[kid_2](), 1, 0.5 },
			'alpha', { npc[kid_3](), 1, 0.5 },
			'move', { npc[kid_2](), vector(30, 0, 80.6), nil, 5, true, true },
			'move', { npc[kid_3](), vector(30, 0, 79.4), nil, 5, true, true },
			'amove', { npc[kid_1](), vector(29.8, 0, 80), nil, 5, true, true, true }, -- 달려오는 사운드
			--- 아이 2 : 미안해요! 눈보라가 그칠 때까지 동굴 속에 숨어있었어요.
			'ani', { npc[kid_1](), { name = 'sing' }},
			'ani', { npc[kid_2](), { name = 'sing' }},
			'ani', { npc[kid_3](), { name = 'sing' }},
			'emo', { npc[kid_1](), { name = 'smile' }},
			'emo', { npc[kid_2](), { name = 'smile' }},
			'emo', { npc[kid_3](), { name = 'smile' }},
			'talk', { npc[kid_2](), { key = 'substage_secret_garden_3_5', skip = true }},
			--- 아이 3 : 혼내지.. 않으실 거죠?
			'one_shot', '03_dialogue_tipsy_01',
			'talk', { npc[kid_3](), { key = 'substage_secret_garden_3_6', skip = true }},
			'emoji', { npc[villager_1](), nil, 'notice' },
			'emoji', { npc[villager_2](), nil, 'notice' },
			'aemoji', { npc[villager_3](), nil, 'notice' },
			--- 마을사람 1 : 그, 그럴리가…!
			'jump', { npc[villager_1](), '01_jump_01' },
			'wait', 0.5,
			'one_shot', '03_dialogue_sadness_01',
			'move', { npc[villager_1](), vector(28, 0, 79.5), nil, 0.1, true, false },
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_3_7', skip = true }},

			--- 밀리아가 부들부들 떨기 시작함
			'one_shot', '01_rustle_01',
			'dir', { npc[milia](), 'down' },
			'shake', { npc[milia](), 0.04, 2 },
			'wait', 2,

			'dir', { npc[villager_1](), 'down' },
			'dir', { npc[villager_3](), 'down' },
			'dir', { npc[kid_1](), 'down' },
			'dir', { npc[kid_2](), 'down' },
			'dir', { npc[kid_3](), 'down' },
			'remove_emo', { npc[kid_1]() },
			'remove_emo', { npc[kid_2]() },
			'remove_emo', { npc[kid_3]() },
			'remove_ani', { npc[kid_1]() },
			'remove_ani', { npc[kid_2]() },
			'remove_ani', { npc[kid_3]() },
			--- bgm_transition : Event(bgm_cave_main) -> Muted, Mix 2
			'play_stage_music', { state = 'muted', mix = 2 },
			--- 밀리아 : 모두 저주할 거예요.
			'camera_shake', { 0.2, 0.3 },
			'dir', { npc[milia](), 'up' },
			'one_shot', '03_dialogue_negative_01',
			'emo', { npc[milia](), { name = 'mad', scale = 0 }},
			'ani', { npc[milia](), { name = 'release', loop = false, remove_after = 0.3 }},
			'shake', { npc[milia](), 0.04, 0.5 },
			'talk', { npc[milia](), { key = 'substage_secret_garden_3_8', bubble_type = 'shout', skip = true }},
			'wait', 0.5,
			--- 밀리아 절벽쪽으로 전진
			'one_shot', '01_rustle_01',
			'amove', { npc[milia](), vector(29, 0, 78), nil, 1, true, true },
			--- 밀리아 : 원혼이 되어 이 마을을 저주할 거예요. 영원히.. 영원히…!
			'one_shot', '01_camera_emphasize_01',
			'dir', { npc[milia](), 'up' },
			'camera_shake', { 0.2, 0.3 },
			'shake', { npc[milia](), 0.04, 0.5 },
			'ani', { npc[milia](), { name = 'release', loop = false, remove_after = 0.3 }},
			'talk', { npc[milia](), { key = 'substage_secret_garden_3_9', bubble_type = 'shout', skip = true }},
			'wait', 0.5,

			--- 시간을 느리게
			'mod', { 0.333, milia },
			'jump', { npc[villager_1]() },
			--- 걷기 시작
			'amove', { npc[milia](), vector(29, 0, 77.7), 0.25, nil, true, true },
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Field(bgm_shivermore_main) -> Muted , Mix 3
			'play_stage_music', { state = 'field', mix = 3 },
			'fade_out', { 2, unity_class.color.white, 'linear' },
			--- 점프
			'jump', { npc[milia](), 1.1, 0.5 },
			'disable_shadow', npc[milia](),
			'move', { npc[milia](), vector(29, -1, 73.5), nil, 5, true, false },
			'wait', 0.1,
			'ani', { npc[milia](), { name = 'cast', scale = 0 }},
			'wait', 0.7,
			'unmod', { milia },
			--- 하인즈 세팅
			'pos', { npc[heinz](), vector(100, 0, 100) },
			--- 밀리아 세팅
			'pos', { npc[milia](), vector(100, 0, 100) },
			--- 아이 1 세팅
			'pos', { npc[kid_1](), vector(100, 0, 100) },
			--- 아이 2 세팅
			'pos', { npc[kid_2](), vector(100, 0, 100) },
			--- 아이 3 세팅
			'pos', { npc[kid_3](), vector(100, 0, 100) },
			--- 필드 눈보라 세팅
			'blizzard_start', { 1, 1 },
			'camera_reset', { },
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'focus_to_brazier', nil,
			'wait', 0.5
		},
		{
			'ani', { user_party_leader, { name = 'bomb_attack', remove_after = 0.4 }},
			'wait', 0.2,
			'grave_refresh', nil,
			'wait', 0.8,
			--- 나레이션 : 비석에서 따뜻한 기운이 흘러나온다.
			'narration', {{ key = 'substage_secret_garden_5_1' }},
			--- 폭발 이펙트 생성
			'fx', { 'FX_explosion_boss', vector(0.5, 0.5, 26.5) },
			--- 카메라 지진
			'camera_shake', { 0.4, 3 },
			'one_shot', '01_earthquake_01',
			--- bgm_transition : Field(bgm_shivermore_main) -> Muted
			'play_stage_music', { state = 'muted', mix = 2 },
			'wait', 2,
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '02_magic_shield_01',
			--- 회상으로 페이드
			'fade_out', { 1, unity_class.color.white, 'linear' },
			'wait', 1,
			'camera_reset', {},
			'fx_dispose', { 'rope' },
			'camera_resize', { 3.3, 0 },
			'camera_move', { vector(28, 0, 82.75), 0 },
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(28, 0, 83.5) },
			'dir', { npc[villager_1](), 'down' },
			'emo', { npc[villager_1](), { name = 'tired' }},
			'ani', { npc[villager_1](), { name = 'cast' }},
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(26.5, 0, 82) },
			'dir', { npc[villager_2](), 'right' },
			'emo', { npc[villager_2](), { name = 'tired' }},
			'ani', { npc[villager_2](), { name = 'cast' }},
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(29.5, 0, 82) },
			'dir', { npc[villager_3](), 'left' },
			'emo', { npc[villager_3](), { name = 'tired' }},
			'ani', { npc[villager_3](), { name = 'cast' }},
			'fade_in', { 1, unity_class.color.white, 'linear' },
			'wait', 0.5,

			--- 마을사람 1 : 저주야. 저주가 틀림 없어.
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_4_1', skip = true }},
			--- 마을사람 3 : 눈보라가 3개월 째 계속 된다는 게 말이 돼?
			'one_shot', '03_runaway_01',
			'shake', { npc[villager_3](), 0.04, 0.5 },
			'talk', { npc[villager_3](), { key = 'substage_secret_garden_4_2', skip = true }},
			--- 마을사람 2 : 어떡해야 저주를 풀 수 있을까?
			'ani', { npc[villager_2](), { name = 'throw', remove_after = 1, sfx_name = '01_swing_01' }},
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_4_3', skip = true }},
			--- 마을사람 1 : 둘을 위해 비석을 세우는 건 어떤가…?
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_4_4', skip = true }},
			--- 마을사람 2 : 진심으로 사죄하는 마음을 담으면 용서해줄지도 몰라.
			'talk', { npc[villager_2](), { key = 'substage_secret_garden_4_5', skip = true }},

			'fade_out', { 1, unity_class.color.black, 'linear' },
			'wait', 1,
			'camera_reset', {},
			'camera_move', { vector(0.5, 0, 25.27505), 0 },
			'party_move', {},
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(0.5, 0, 25.5) },
			'dir', { npc[villager_1](), 'up' },
			'ani', { npc[villager_1](), { name = 'cast' }},
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(0, 0, 24.5) },
			'dir', { npc[villager_2](), 'up' },
			'ani', { npc[villager_2](), { name = 'cast' }},
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(1, 0, 24.5) },
			'dir', { npc[villager_3](), 'up' },
			'ani', { npc[villager_3](), { name = 'cast' }},
			'fade_in', { 1, unity_class.color.black, 'linear' },

			--- 마을사람 1 : 부디 이 비석이 둘의 원혼을 달랠 수 있기를…
			'talk', { npc[villager_1](), { key = 'substage_secret_garden_4_6', skip = true }},

			--- 눈보라 종료 요청
			'blizzard_end', nil,
			--- 회상으로 넘어가는 페이드 사운드
			'one_shot', '01_lights_01',
			--- bgm_transition : Muted -> Field(bgm_shivermore_main), Mix 2
			'play_stage_music', { state = 'field', mix = 2 },
			'fade_out', { 1.5, unity_class.color.white, 'linear' },
			'wait', 1.5,
			--- 꽃 만개
			'flower_blossom', { },
			--- 마을사람 1 세팅
			'pos', { npc[villager_1](), vector(100, 0, 100) },
			--- 마을사람 2 세팅
			'pos', { npc[villager_2](), vector(100, 0, 100) },
			--- 마을사람 3 세팅
			'pos', { npc[villager_3](), vector(100, 0, 100) },
			--- 카메라 리셋
			'camera_reset', {},
			--- 파티 리셋
			'party_reset', {},
			'camera_resize', { 1.5, 0 },
			--- 페이드 인
			'fade_in', { 1.5, unity_class.color.white, 'linear' },
			'camera_resize', { 4, 2 },
			'wait', 3,
			'focus_to_door', {}
		},
		{
			--- 나레이션
			--- 내가 생각하지 말아야 하는데도 생각한 것과
			--- 말하지 말아야 하는데도 말한 것
			--- 행하지 말아야 하는데도 행한 것
			'narration', {{ key = 'substage_secret_garden_5_2' }},
			--- 나레이션
			--- 그리고 내가 생각해야만 하는데도 생각하지 않은 것과,
			--- 말해야만 하는데도 말하지 않은 것
			--- 행해야만 하는데도 행하지 않은 것
			'narration', {{ key = 'substage_secret_garden_5_3' }},
			--- 나레이션 : 그 모든 것들을 용서하소서.
			'narration', {{ key = 'substage_secret_garden_5_4' }},
		},
		{
			--- 나레이션 : 조각난 비석이다. 비석 조각을 모으면, 복원할 수 있을 것 같다.
			'narration', {{ key = 'substage_secret_garden_6_1' }}
		}
	}
end

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.main_stage_name = 'snowmountain_1_5'
	self.sub_stage_name = 'substage_3_3'
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	--- 메인 스테이지 처리
	if stage.Name == self.main_stage_name then
		--- 서브 스테이지 오픈을 담당할 npc
		self.opener_npc = function ()
			return get_character('secretgarden_opener')
		end

		--- 서브 스테이지 오픈을 담당할 gimmick
		self.opener = function ()
			return get_field_object('substage_3_3')
		end

		--- 서브 스테이지를 열지 않았다면
		if not user_progress:IsStageOpened(self.sub_stage_name) then
			--- event를 받도록 요청
			self.opener_npc().Interactable:AddListener(self.cs_controller)

			--- fx preload
			quest_icon.PreLoad()

			--- wait for fx load
			while not quest_icon.IsLoaded do
				coroutine.yield(nil)
			end

			--- 서브스테이지 아이콘 띄워줌
			quest_icon.SetSubstageIcon(self.opener_npc())

		end

		return
	end

	--- 타일맵에 있는 무덤 오브젝트를 가져옴
	self.grave = function ()
		return get_field_object('grave')
	end

	--- @param index number 가져올 무덤 파츠
	self.grave_parts = function (index)
		local name = string.format('grave_%i', index)
		return get_field_object(name)
	end

	--- @param index number 현재 progress에 대응하는 화로들
	self.brazier = function (index)
		local name_1 = string.format('brazier_%i', index * 2 - 1)
		local name_2 = string.format('brazier_%i', index * 2)
		return get_field_object(name_1), get_field_object(name_2)
	end

	---- 마지막 도어를 가져옴
	self.get_door = function()
		return get_field_object('final_door')
	end

	--- [StageCustomKey(StageId = 110030002, StageName = 'substage_3_3')]
	self.custom_key =
	{
		--- 마지막 회상을 확인했는지 여부
		view_last_scene = 1
	}

	--- 프로그래스 정리
	self.progress_enum =
	{
		--- 아무 것도 진행되지 않음
		none = 0,
		--- 첫번째 비석을 가져다 줌
		first = 1,
		--- 두번째 비석을 가져다 줌
		second = 2,
		--- 세번째 비석을 가져다 줌
		third = 3,
		--- 네번째 비석을 가져다 줌
		fourth = 4,
		--- 엔딩
		ending = 5,
		--- 비석을 가져와야 할때
		default = 6
	}

	self:init_scene()

	--- event subscribe
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	--- 이미 스테이지를 클리어한 상태
	if CS.Oak.StageProgress.Current:GetCustomData(self.custom_key.view_last_scene) then
		--- stage progress
		self.progress = 4
		--- item progress
		self.item_progress = 0

		--- disable grave parts
		for index = 1, 4 do
			character_util.set_active_state(self.grave_parts(index), 'disabled')

			local brazier_1, brazier_2 = self.brazier(index)
			if brazier_1 and brazier_2 then
				--- burn immediate (sfx mute)
				command_util.execute_burn(user_party_leader, brazier_1, true)
				command_util.execute_burn(user_party_leader, brazier_2, true)
			end
		end

		--- 꽃을 만개
		self:flower_blossom()

		local door = self.get_door()

		if not door.FieldObjectBehaviour.IsOpen then
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(door.Name, true))
		end
	else
		--- event subscribe
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

		--- stage progress
		self.progress = 0
		--- item progress
		self.item_progress = 0

		--- ingame fx cache
		self.fx = {}

		--- audio source holder
		self.audio_holder = nil

		--- twinkle fx
		local twinkle = unity_object_pool.GetOrCreate('FX_Object_Twinkle')
		--- smoke fx
		local smoke = unity_object_pool.GetOrCreate('FX_Common_SmokeScreen')
		--- blizzard fx
		local blizzard = unity_object_pool.GetOrCreate('FX_Blizzard')
		--- rope fx
		local rope = unity_object_pool.GetOrCreate('rope_trap')
		--- explosion fx
		local explosion = unity_object_pool.GetOrCreate('FX_explosion_boss')

		--- CS.Oak.UnityObjectPoolExtensions
		local fx_util = CS.Oak.UnityObjectPoolExtensions

		--- wait for fx load
		while not fx_util.IsLoaded(twinkle) and not fx_util.IsLoaded(smoke) and not fx_util.IsLoaded(blizzard) and
			not fx_util.IsLoaded(rope) and not fx_util.IsLoaded(explosion) and not CS.Oak.FieldUIFloatingText.IsLoaded() do

			coroutine.yield(nil)
		end

		--- Instantiate Twinkle fx
		for index = 1, 4 do
			local part = self.grave_parts(index)
			local pooled_twinkle = twinkle:Instantiate(part.Position + vector(0, 0.5, -0.2))
			self.fx[part.Name] = pooled_twinkle
		end
	end

	self:grave_refresh()

	self:resize_block_hitbox()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	--- 메인 스테이지
	if stage.Name == self.main_stage_name then

		local npc = self.opener_npc()

		if npc then
			--- event를 해지하도록 요청
			npc.Interactable:RemoveRelatedEvent(self.cs_controller)

			self.opener_npc = nil
			self.opener = nil
		end

	--- 서브 스테이지
	elseif stage.Name == self.sub_stage_name then
		--- event unsubscribe
		message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

		-- table dispose
		self.progress_enum = nil
		self.action = nil
		self.param = nil
		self.fx = nil

		-- function dispose
		self.grave = nil
		self.grave_parts = nil
		self.brazier = nil
	end

	-- cs_controller dispose
	self.cs_controller = nil
end

---
--- LuaStageEventController의 IEventListener 처리
function local_class:on_event(e)
	--- AddListener로 요청한 InteractEvent만 처리함
	if not lua_helper.type_compare(e, CS.Oak.InteractEvent) then return false end

	--- 상호작용의 주체가 leader가 아니라면 무시
	if not lua_helper.reference_equals(e.Interactor, user_party_leader) then return false end

	--- 타겟이 open을 담당하는 npc가 아니라면 무시
	if not lua_helper.reference_equals(e.Target, self.opener_npc()) then return false end

	sp_util.play_normal_screenplay(self.play_open_scene_routine, self)

	return true
end

---
--- 서브스테이지를 열어주는 연출
function local_class:play_open_scene_routine()
	--- 대상 npc 캐싱
	local npc = self.opener_npc()
	--- quest icon 삭제
	quest_icon.RemoveIcon(npc)
	--- event를 해지하도록 요청
	npc.Interactable:RemoveRelatedEvent(self.cs_controller)

	--- 파티 정렬
	party_util.align_to_target(npc, 'down', 1, 'arc')

	--- 노인 : 이보게, 젊은이,
	character_util.set_anim(npc, { name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'substage_secretgarden_1', skip = true })
	character_util.remove_anim(npc)
	--- 노인 : 이 설산 어딘가에 꽃밭이 있다는 전설… 들어 보았나?
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'substage_secretgarden_2', skip = true })
	--- 노인 : 그곳엔 한 겨울에도, 파릇파릇한 꽃이 한가득 피어있다고 하네.
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'substage_secretgarden_3', skip = true })
	--- 노인 : 전설에 따르면 이 산 깊숙한 곳에 있다 하니, 관심 있으면 한 번 찾아보게나.
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'substage_secretgarden_4', skip = true })

	--- 서브스테이지 오픈 요청
	yield_return(self.opener().FieldObjectBehaviour, 'OpenStage')
end

---
--- CS.Oak.InteractEvent 처리
--- @return boolean interactEvent 가 완료되었는지
function local_class:on_interact_event(e)
	if not lua_helper.reference_equals(e.Interactor, user_party_leader) then return false end

	--- target cache
	local target = e.Target

	--- 현재 상호 작용한 대상이 무덤 석판인지 판단
	if lua_helper.reference_equals(target, self.grave()) then
		--- 현재 상황에 맞는 아이템을 얻고 석판에게 말을 걸었을 경우
		if self.progress + 1 == self.item_progress then
			--- 진행도 갱신
			self.progress = self.progress + 1
			--- 상황에 맞는 씬을 재생
			sp_util.play_normal_screenplay(self.play_scene_routine, self, self.progress)

		--- 모든 것을 마무리 했을 경우 (네번째 비석을 가져다 준 이후에 다시 말을 걸었을 경우)
		elseif self.progress == self.progress_enum.fourth then
			sp_util.play_normal_screenplay(self.play_scene_routine, self, self.progress_enum.ending)

		--- 아이템과 프로그래스가 맞지 않는 경우
		else
			sp_util.play_normal_screenplay(self.play_scene_routine, self, self.progress_enum.default)
		end

		return true
	end

	--- 현재 상호 작용한 대상이 석판 조각인지 판단
	if self.grave_parts(self.item_progress + 1) and
		lua_helper.reference_equals(target, self.grave_parts(self.item_progress + 1)) then

		--- 진행도 갱신
		self.item_progress = self.item_progress + 1

		--- 대상 fo, fx 비활성화
		local part = self.grave_parts(self.item_progress)
		character_util.set_active_state(part, 'disabled')
		self.fx[part.Name]:Dispose()

		--- 비석 조각 습득 ui 표기
		CS.Oak.FieldUIFloatingText.Get(user_party_leader):JustPrintItemName(
			game_string:GetString('substage_secret_garden_grave'), 0)

		--- 비석 조각 습득 사운드
		music_player:PlaySfxOneShot('03_get_drop_item_01')

		return true
	end

	return false
end

---
--- CS.Oak.ZoneEnterEvent 처리
function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	if e.Zone.Name == 'blizzard' then
		--- 현재 눈보라가 활성화 되어 있지 않다면
		if not self.blizzard then
			--- 눈보라 요청
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.blizzard_routine, self, 1, 1))
		end

		return true
	end

	return false
end

---
--- CS.Oak.ZoneLeaveEvent 처리
function local_class:on_zone_leave_event(e)
	--- 대상 검증
	if not e.FullLeave or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	--- zone 검증
	if e.Zone.Name ~= 'blizzard' then return false end

	self:blizzard_end()
	return true
end

---
--- 상황에 맞는 씬을 재생
--- @param index number 재생할 씬
function local_class:play_scene_routine(index)
	local scene = self.param[index]

	party_util.align_to_target(self.grave(), 'down', 1, 'arc')

	for inner_index = 1, #scene, 2 do
		if self.action[scene[inner_index]] then
			self.action[scene[inner_index]](scene[inner_index + 1])
		else
			self[scene[inner_index]](self, scene[inner_index + 1])
		end
	end

	--- 마지막 네번째 비석을 가져다준 progress에 도달했고, custom key가 할당되어 있지 않다면, custom key를 set해줌
	if self.progress == self.progress_enum.fourth and
		not CS.Oak.StageProgress.Current:GetCustomData(self.custom_key.view_last_scene) then

		coroutine.yield(stage_progress:SendCustomDataAsync(self.custom_key.view_last_scene, true))

		--- 이 이벤트에 관한 처리를 더이상하지 않아도 됨
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	end
end

---
--- progress에 대응하여 무덤의 상황을 알맞게 바꿔줌
function local_class:grave_refresh()
	local grave = self.grave()

	--- 이 이벤트에 맞춰져서 제작된 오브젝트 항상 4개의 자식이 존재
	for index = 0, 3 do
		grave.transform:GetChild(index).gameObject:SetActive(false)
	end

	if 0 < self.progress and self.progress < 5 then
		grave.transform:GetChild(self.progress - 1).gameObject:SetActive(true)
	end

	--- 스테이지 로드 중 들어오는 요청은 무시 (초기 세팅을 위한 요청이므로)
	if stage.StageStarted then
		--- 비석 조각 올려놓는 사운드
		music_player:PlaySfxOneShot('02_hit_projectile_01')
	end
end

---
--- progress에 대응하여 화로를 켜줌
function local_class:focus_to_brazier()
	--- target brazier
	local brazier_1, brazier_2 = self.brazier(self.progress)
	local target_pos = (brazier_1.Position + brazier_2.Position) * 0.5

	camera_util.move_async(target_pos, 1, { ignorecameragrids = true })

	--- publish burn
	command_util.execute_burn(user_party_leader, brazier_1)
	command_util.execute_burn(user_party_leader, brazier_2)

	wait_for_sec(1)

	camera_util.move_async(user_party_leader.Position, 1,
		{ ignorecameragrids = true, end_target = user_party_leader })
end

---
--- progress에 대응하여 문을 열어줌
function local_class:focus_to_door()
	--- 열어줄 문
	local door = self.get_door()

	camera_util.move_async(door.Position, 1, { ignorecameragrids = true })

	--- 문을 여는 이벤트 발행
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(door.Name, false))

	wait_for_sec(2)

	camera_util.move_async(user_party_leader.Position, 1,
		{ ignorecameragrids = true, end_target = user_party_leader })
end

---
--- 눈보라 연출 시작 요청
--- @param param table 눈보라 연출을 위한 데이터
function local_class:blizzard_start(param)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.blizzard_routine, self, table.unpack(param)))
end

---
--- 눈보라 연출 종료 요청
---
--- flag를 바꾸면 돌고 있던 루틴에서 알아서 종료처리를 함
function local_class:blizzard_end()
	-- boolean flag set
	self.blizzard = false
end

---
--- 눈보라 연출 실제 실행하는 부분
---
--- 연출을 끝내려면 blizzard_end 를 사용해야 함
--- @param fade_in_duration number 페이드 인에 걸릴 시간
--- @param fade_out_duration number 페이드 아웃에 걸릴 시간
function local_class:blizzard_routine(fade_in_duration, fade_out_duration)
	-- boolean flag set
	self.blizzard = true

	local camera = stage_camera
	local property_name = '_TintColor'

	--- blizzard preset
	local blizzard_preset = unity_object_pool.GetOrCreate('FX_Blizzard')
	--- instantiate fx
	local blizzard = blizzard_preset:Instantiate(
		camera.Transform.position + vector(0, 5, 10), unity_class.quaternion.identity, camera.Transform)
	--- fx material
	local material = blizzard.transform:GetComponentInChildren(typeof(CS.UnityEngine.Renderer)).material
	--- cached origin color
	local origin_color = material:GetColor(property_name)

	--- cached audio source
	local audio_holder = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = duration, type_priority = 'event' })
	local time_passed = 0

	--- fade in routine
	while self.blizzard do
		time_passed = time_passed + unity_class.time.deltaTime

		local alpha =  math.min(time_passed / fade_in_duration, 1) * 128 / 255
		material:SetColor(property_name, unity_color({ origin_color.r, origin_color.g, origin_color.b, alpha}))

		coroutine.yield(nil)
	end

	time_passed = fade_out_duration

	--- audio source fade out
	audio_holder:FadeOut(math.max(fade_out_duration, 0.2))

	--- fade out routine
	while 0 < time_passed do
		time_passed = time_passed - unity_class.time.deltaTime

		local alpha =  math.min(time_passed / fade_out_duration, 1)
		material:SetColor(property_name, unity_color({ origin_color.r, origin_color.g, origin_color.b, alpha}))

		coroutine.yield(nil)
	end

	--- restore material to origin color
	material:SetColor(property_name, origin_color)
	--- dispose fx
	blizzard:Dispose()
end

---
--- 석판 주변에 꽃이 생기는 연출
function local_class:flower_blossom()
	local target_zone = field:GetZone('flower')
	--- CS.Oak.PooledSortedFieldObjectList 사용한 이후 dispose 해야함
	local flowers = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)

	--- 해당 존에 있는 모든 오브젝트를 순회
	for index = 0, flowers.Count - 1 do
		--- 개별 오브젝트
		local fo = flowers[index]
		--- 위치를 교체
		fo.Position = fo.Position + vector(0, 0.015, -100)
		--- 충돌하지 않도록
		fo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	--- Dipose PooledSortedFieldObjectList
	flowers:Dispose()
end

function local_class:party_move()
	party_util.position_party(vector(40, 0, 60), 'up')
end

function local_class:party_reset()
	party_util.align_to_target(self.grave(), 'down', 0, 'arc')
end

function local_class:disable_shadow(fo)
	fo.SpineController.IsShadowActive = false
end

function local_class:resize_block_hitbox()
	local target_bound = CS.UnityEngine.Bounds(vector(0, 0, 48.5), vector(8, 0, 8))
	local target_name = '[GIMMICK]push_block_indoor2'
	local target_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_bound, unity_class.vector3.zero)

	for i = 0, target_list.Count - 1 do
		local fo = target_list[i]
		if fo.Name == target_name then
			fo.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.75), vector(2, 1, 2))
		end
	end
	target_list:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
