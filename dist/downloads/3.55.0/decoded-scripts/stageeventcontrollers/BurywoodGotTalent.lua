local local_class = newclass('BurywoodGotTalentController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.starpiece_name = 'burywood_got_talent_star_piece'

	self.audition_staff_name = 'audition_staff'
	self.audition_host_name = 'audition_host'
	self.idol_captain_name = 'idol_captain'
	self.vampire_idol_name = 'vampire_idol'

	self.audition_rocks_name = 'audition_rock_'

	self.audition_door_name = 'audition_door'

	self.staff_call_coroutine = nil

	self.is_event_done = false

	self.is_already_got_star_piece = false

	self.spectator_left_count = 8
	self.spectator_right_count = 8

	self.spectator_left_name = 'audition_audience_L_'
	self.spectator_right_name = 'audition_audience_R_'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_dead')
	unity_object_pool.GetOrCreate('fx_obj_event_curse_item_loop')

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	local audition_staff = get_character(self.audition_staff_name)

	if audition_staff.Interactable ~= nil
			and audition_staff.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		audition_staff.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil

	if self.staff_call_coroutine ~= nil then
		stop_coroutine(self.staff_call_coroutine)
		self.staff_call_coroutine = nil
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local audition_staff = get_character(self.audition_staff_name)

		if lua_helper.reference_equals(e.Target, audition_staff) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_to_staff, self))
		end
		return true
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		for i = 1, 3 do
			--self.audition_rocks[i] = get_field_object('audition_rock_' .. i)
			--character_util.set_active_state(self.audition_rocks[i], 'disabled')
			character_util.set_active_state(get_field_object(self.audition_rocks_name .. i), 'disabled')
		end

		local audition_staff = get_character(self.audition_staff_name)

		self.is_event_done = CS.Oak.StageProgress.Current:HasStarPiece(self.starpiece_name)
		-- 스타피스 획득 여부에 따른 처리
		if self.is_event_done then
			-- 획득 세팅 사용하지 않을 캐릭터들 disable 처리
			local audition_host = get_character(self.audition_host_name)
			local idol_captain = get_character(self.idol_captain_name)
			local vampire_idol = get_character(self.vampire_idol_name)

			self:disable_all_npc()
		else
			-- 미획득 세팅
			if audition_staff.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				audition_staff.Interactable:AddListener(self.cs_controller)
			end

			get_field_object(self.audition_door_name).ActiveState = active_state('disabled')
		end
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter == false or self.is_event_done then return false end
		local zone_name = e.Zone.Name

		if zone_name == 'help_audition_staff_zone' then
			if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return false end

			if self.staff_call_coroutine == nil then
				self.staff_call_coroutine = coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.staff_call, self))
			end
		end
	end
	return false
end

function local_class:staff_call()
	local audition_staff = get_character(self.audition_staff_name)

	-- (damaged, success, down)거기! 거기요! 잠시만 이리 와주세요!
	character_util.set_emotion(audition_staff, { name = 'smile'})

	speech_bubble_util.show_speech_bubble_async(audition_staff, { key = 'movie_3_burywood_got_talent_1', skip = false})

	character_util.remove_anim_and_emotion(audition_staff)

	self.staff_call_coroutine = nil
end

function local_class:talk_to_staff()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local audition_staff = get_character(self.audition_staff_name)

	character_util.align_party(audition_staff, 'down', 1, 'linear')

	character_util.set_anim_and_emotion(audition_staff,
			{ name = 'idle'}, { name = 'smile'})

	-- (smile, idle, down)시간 내주셔서 감사합니다.
	speech_bubble_util.show_speech_bubble_async(audition_staff,
			{ key = 'movie_3_burywood_got_talent_2', skip = true})

	-- (smile, idle, down)혹시 독설에 자신이 좀 있으신가요?
	speech_bubble_util.show_speech_bubble_async(audition_staff,
			{ key = 'movie_3_burywood_got_talent_3', skip = true})

	local wait = true
	local quit_event = true

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	-- 그래! 이 고릴라야! 딱 보면 안 보이냐? 눈은 장식이야? 뇌에 우동 사리만...(빨간색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_1'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			quit_event = true
			wait = false
		end})
	-- 아니요(초록색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			quit_event = false
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if quit_event == true then
		-- (awesome, success, down)아! 모욕적이야!
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_anim_and_emotion(audition_staff,
				{ name = 'success', sfx_name = '01_player_jump_01'}, { name = 'awesome'})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_5', skip = true})

		-- (dealwithit, clap, down)저희가 필요한 인재입니다!
		character_util.set_anim_and_emotion(audition_staff,
				{ name = 'clap'}, { name = 'dealwithit', loop = false})
		local clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_01', type_priority = 'event', player_priority = 'npc'})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_7', skip = true})

		clap_sfx:FadeOut(0.5)

		--저희 프로그램에 출연하셔서 그 독설을 뽐내주시죠!
		character_util.set_anim_and_emotion(audition_staff,
				{ name = 'idle'}, { name = 'doyagao'})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_8', skip = true})

		character_util.remove_anim_and_emotion(audition_staff)

		-- 오디션 장으로 주인공을 데리고 간다. 페이드 아웃시키고 이동
		yield_return_func(self.audition_routine, self)
	else
		-- (tired, idle, down)아… 시시해...
		character_util.set_anim_and_emotion(audition_staff, { name = 'idle'}, { name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_4', skip = true})

		character_util.remove_anim_and_emotion(audition_staff)
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:break_rock(character, fo)
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
	damage_info.sender = character
	damage_info.target = fo
	damage_info.damage = 100

	command_util.execute_damage(damage_info)
end

function local_class:audition_routine()
	local brutal_cnt = 0 -- 독설횟수
	local audition_staff = get_character(self.audition_staff_name)
	local audition_host = get_character(self.audition_host_name)

	local snow_princess = get_character('snow_princess')
	local demon_sister = get_character('demon_sister')
	local magician = get_character('magician')

	local dog = get_character('magician_dog')
	local cat = get_character('magician_cat')
	character_util.set_anim(cat, {name = 'scratch'})
	local rabbit = get_character('magician_rabbit')

	local idol_captain = get_character(self.idol_captain_name)
	local vampire_idol = get_character(self.vampire_idol_name)
	local stage_mid_pos = vector(102.5, 1, 50)
	local camera_pos = vector(102.5, 1, 48.5)
	local audition_rocks = {}

	local is_bitten = {
		false, false, false
	}

	-- 관중들 저장될 테이블
	local spectator_list = {}
	local direction_list = {}

	-- 왼쪽에 있는 관중들
	for i = 1, self.spectator_left_count do
		table.insert(spectator_list, get_character(self.spectator_left_name .. i))
		table.insert(direction_list, 'right')
	end

	-- 오른쪽에 있는 관중들
	for i = 1, self.spectator_right_count do
		table.insert(spectator_list, get_character(self.spectator_right_name .. i))
		table.insert(direction_list, 'left')
	end

	for i = 1, 3 do
		audition_rocks[i] = get_field_object(self.audition_rocks_name .. i)
	end

	local host_pos = vector(99.5, 1, 51)

	music_player:PlaySfxOneShot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.5, screen_util.get_interpolations('linear'))

	local loop_count = user_party.Count - 1

	for i = 0, loop_count do
		if i > 0 then
			user_party[i].Position = vector(38 + i, 0, 2)
			character_util.set_direction(user_party[i], 'down')
		end

	end

	field:Tint('audition', CS.UnityEngine.Color(0.55, 0.55, 0.55, 1), 0)


	camera_util.move(host_pos, 0)
	camera_util.resize_to(3, 0)
	character_util.set_position(audition_host, host_pos)

	character_util.set_position(idol_captain, vector(100.5, 1, 48.5))
	character_util.set_position(user_party.Leader, vector(102.5, 1, 48.5))
	character_util.set_position(vampire_idol, vector(104.5, 1, 48.5))
	character_util.set_direction(idol_captain, 'down')
	character_util.set_direction(vampire_idol, 'down')
	character_util.set_direction(user_party.Leader, 'down')

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, screen_util.get_interpolations('linear'))

	-- 베리우드 최고의 재능을 찾아라!
	music_player:PlaySfxOneShot('01_gatcha_award_start_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_9', skip = true})

	camera_util.shake(0.2, 999)

	-- 베리우드~~~~
	local sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_10', skip = true})

	stage_camera:CancelShake()

	camera_util.resize_to_default(0.1)
	camera_util.move_async(camera_pos, 0.1)

	camera_util.shake(0.4, 0.2)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'jump'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'jump', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'jump', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
					}))

	-- 갓 탤런트!
	sfx_drum:Stop()
	music_player:PlaySfxOneShot('01_gatcha_trumpet_01')
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')
	music_player:PlaySfxOneShot('01_crowd_arena_exclamation_03')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_11', scale = 2, bubble_type = 'shout', skip = true,
			  bubble_direction = 'cb', world_pos = camera_pos - vector(4.5, 0, 5)})

	--오늘의 심사위원을 소개해드리겠습니다!
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host, {key = 'movie_3_burywood_got_talent_11_0', skip = true})

	--듣는 사람의 힘이 솟아나게 하는 목소리! 아이돌~ 에바!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host, {key = 'movie_3_burywood_got_talent_11_1', skip = true})

	--반갑습니다! 베리우드 여러분!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_anim(idol_captain, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(idol_captain, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(idol_captain, {key = 'movie_3_burywood_got_talent_11_1_0', skip = true})

	--에바! 에바!
	music_player:PlaySfxOneShot('01_crowd_shout_02')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 1, behave = 'jump', delay = 0.3},
		{index = 2, behave = 'clap', delay = 0.15},
		{index = 3, behave = 'cap_1'},
		{index = 4, behave = 'jump'},
		{index = 5, behave = 'jump', delay = 0.3},
		{index = 6, behave = 'clap'},
		{index = 7, behave = 'cap_2'},
		{index = 8, behave = 'jump', delay = 0.1},
	})

	--천사가 노래를 부르면 이런 느낌일까요? 세실!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host, {key = 'movie_3_burywood_got_talent_11_2', skip = true})

	--안녕하세요! 베리우드 여러분!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_anim(vampire_idol, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(vampire_idol, {name = 'smile', loop = true})
	speech_bubble_util.show_speech_bubble_async(vampire_idol, {key = 'movie_3_burywood_got_talent_11_1_1', skip = true})

	music_player:PlaySfxOneShot('01_crowd_shout_02')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 9, behave = 'vam_1', delay = 0.3},
		{index = 10, behave = 'clap', delay = 0.15},
		{index = 11, behave = 'jump'},
		{index = 12, behave = 'jump'},
		{index = 13, behave = 'jump', delay = 0.3},
		{index = 14, behave = 'clap'},
		{index = 15, behave = 'jump'},
		{index = 16, behave = 'vam_2', delay = 0.1},
	})

	--마지막으로 오늘을 위해 특별히 모셔온 분입니다!
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host, {key = 'movie_3_burywood_got_talent_11_3', skip = true})

	--이 시대 최고의 독설가! {0}!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{key = game_string:Format('movie_3_burywood_got_talent_11_4', user.Name), skip = true})

	wait_for_sec(1.0)

	local wait = true
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local choice = 0

	--선택지 : 박수 안 쳐?
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_11_1_2'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			choice = 0
			wait = false
		end})

	-- 기대 됩니다.
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_11_1_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			choice = 1
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if choice == 0 then
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		character_util.set_anim(user_party.Leader, {name = 'release', loop = true, scale = 1})
		character_util.set_emotion(user_party.Leader, {name = 'mad', loop = true})

		--독설
		music_player:PlaySfxOneShot('01_crowd_shout_02')
		music_player:PlaySfxOneShot('01_crowd_shout_03')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'love_1', delay = 0.3},
			{index = 3, behave = 'jump'},
			{index = 4, behave = 'jump'},
			{index = 6, behave = 'clap'},
			{index = 8, behave = 'jump', delay = 0.1},
			{index = 9, behave = 'clap'},
			{index = 10, behave = 'clap'},
			{index = 11, behave = 'jump', delay = 0.2},
			{index = 12, behave = 'love_2', delay = 0.4},
			{index = 14, behave = 'clap'},
			{index = 16, behave = 'clap'},
		})

		character_util.remove_anim_and_emotion(user_party.Leader)
	else
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_anim(user_party.Leader, {name = 'cast', loop = true, scale = 1})
		character_util.set_emotion(user_party.Leader, {name = 'smile', loop = true})

		music_player:PlaySfxOneShot('01_crowd_shout_04')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'hoot_2', delay = 0.3},
			{index = 4, behave = 'jump', delay = 0.2},
			{index = 5, behave = 'jump'},
			{index = 8, behave = 'clap', delay = 0.1},
			{index = 10, behave = 'hoot_1'},
			{index = 11, behave = 'jump'},
			{index = 14, behave = 'jump', delay = 0.5},
		})

		character_util.remove_anim_and_emotion(user_party.Leader)
	end

	--베리우드 갓 탤런트! 지금 시작합니다!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(audition_host, {name = 'idle', loop = true, scale = 1})
	character_util.set_emotion(audition_host, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(audition_host, {key = 'movie_3_burywood_got_talent_11_5', skip = true})

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'jump'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'jump', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'jump', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
					}))

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('01_crowd_clap_02')
	screen_util.fade_out_circular_async(0.5, screen_util.get_interpolations('linear'))

	character_util.move_to(idol_captain, vector(101.5, 0, 46), 0)
	character_util.move_to(vampire_idol, vector(102.5, 0, 46), 0)
	character_util.move_to(user_party.Leader, vector(103.5, 0, 46), 0)
	character_util.set_direction(idol_captain, 'up')
	character_util.set_direction(vampire_idol, 'up')
	character_util.set_direction(user_party.Leader, 'up')
	character_util.set_position(snow_princess, stage_mid_pos)

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, screen_util.get_interpolations('linear'))

	music_player_util.play_stage_music({state = 'muted', mix = 2})

	-- 첫번째 참가자는~
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_12', skip = true})
	-- 쉬버링 산맥에서 온 노래하는 공주! 앤!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_13', skip = true})

	music_player:PlaySfxOneShot('01_crowd_clap_02')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'clap'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'wow'},
						{index = 7, behave = 'clap', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'wow', delay = 0.5},
					})

	-- 참가자 1
	-- (sing, idle, down)반~갑~습~니~다!
	if CS.Foundations.GameEnvironment.IsKongJapan then
		music_player:PlaySfxOneShot('01_holy_01')
	else
		music_player:PlaySfxOneShot('01_let_it_go_01')
	end
	character_util.set_anim_and_emotion(snow_princess, { name = 'idle'}, { name = 'sing'})
	speech_bubble_util.show_speech_bubble_async(snow_princess,
			{ key = 'movie_3_burywood_got_talent_14', skip = true})
	-- 왼쪽 오른쪽으로 왔다갔다 하며 노래를 부른다
	character_util.set_anim_and_emotion(snow_princess, { name = 'sing'}, { name = 'sing'})

	-- (sing, sing, left)let it come! let it come!
	if CS.Foundations.GameEnvironment.IsKongJapan then
		music_player:PlaySfxOneShot('01_holy_01')
	else
		music_player:PlaySfxOneShot('01_let_it_go_02')
	end
	character_util.set_direction(snow_princess, 'left')
	speech_bubble_util.show_speech_bubble_async(snow_princess,
			{ key = 'movie_3_burywood_got_talent_15', skip = true})

	-- (sing, sing, right)can hold back more and more!
	if CS.Foundations.GameEnvironment.IsKongJapan then
		music_player:PlaySfxOneShot('01_holy_01')
	else
		music_player:PlaySfxOneShot('01_let_it_go_02')
	end
	character_util.set_direction(snow_princess, 'right')
	speech_bubble_util.show_speech_bubble_async(snow_princess,
			{ key = 'movie_3_burywood_got_talent_16', skip = true})

	-- 노래 끝나고 아래 보도록
	character_util.set_direction(snow_princess, 'down')

	music_player:PlaySfxOneShot('01_crowd_shout_03')
	music_player:PlaySfxOneShot('01_crowd_clap_02')

	music_player_util.play_stage_music({state = 'event', name = 'bgm_result', mix = 2})

	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 1, behave = 'wow', delay = 0.3},
		{index = 3, behave = 'jump'},
		{index = 4, behave = 'jump'},
		{index = 6, behave = 'clap'},
		{index = 8, behave = 'jump', delay = 0.1},
		{index = 9, behave = 'clap'},
		{index = 10, behave = 'clap'},
		{index = 11, behave = 'great', delay = 0.2},
		{index = 12, behave = 'jump', delay = 0.4},
		{index = 14, behave = 'clap'},
		{index = 16, behave = 'clap'},
	})

	--심사위원 1 : 아름다운 목소리였습니다!
	speech_bubble_util.show_speech_bubble_async(idol_captain,
			{ key = 'movie_3_burywood_got_talent_17', skip = true})

	--심사위원 2 : 완벽한 무대매너였어요!
	speech_bubble_util.show_speech_bubble_async(vampire_idol,
			{ key = 'movie_3_burywood_got_talent_18', skip = true})

	local wait = true
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	-- 돼지가 빙판에서 미끄러지는 소리 같았습니다! 나가!(빨간색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_3'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			is_bitten[1] = true
			brutal_cnt = brutal_cnt + 1
			wait = false
		end})

	-- 가수의 자질이 아주 뛰어나군요!(흰색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_4'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if is_bitten[1] then
		-- (damaged, push, down)어떻게 그렇게 심한 말을…
		music_player:PlaySfxOneShot('03_dialogue_sadness_01')
		character_util.set_anim_and_emotion(snow_princess, { name = 'push'}, { name = 'damaged'})
		speech_bubble_util.show_speech_bubble(snow_princess, { key = 'movie_3_burywood_got_talent_19', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_03')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'love_1', delay = 0.3},
			{index = 3, behave = 'jump'},
			{index = 4, behave = 'jump'},
			{index = 6, behave = 'clap'},
			{index = 8, behave = 'jump', delay = 0.1},
			{index = 9, behave = 'clap'},
			{index = 10, behave = 'clap'},
			{index = 11, behave = 'jump', delay = 0.2},
			{index = 12, behave = 'love_2', delay = 0.4},
			{index = 14, behave = 'clap'},
			{index = 16, behave = 'clap'},
		})
	else
		-- (sing, success, down)감~사~합~니~다!
		if CS.Foundations.GameEnvironment.IsKongJapan then
			music_player:PlaySfxOneShot('01_holy_01')
		else
			music_player:PlaySfxOneShot('01_let_it_go_02')
		end
		character_util.set_anim_and_emotion(snow_princess, { name = 'success'}, { name = 'sing'})
		speech_bubble_util.show_speech_bubble(snow_princess, { key = 'movie_3_burywood_got_talent_20', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_04')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'hoot_2', delay = 0.3},
			{index = 4, behave = 'jump', delay = 0.2},
			{index = 5, behave = 'clap'},
			{index = 8, behave = 'jump', delay = 0.1},
			{index = 10, behave = 'hoot_1'},
			{index = 11, behave = 'jump'},
			{index = 14, behave = 'jump', delay = 0.5},
		})
	end

	music_player_util.play_stage_music({state = 'muted', mix = 2})

	wait_for_sec(1)
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
	character_util.set_position(demon_sister, stage_mid_pos)
	character_util.remove_anim_and_emotion(snow_princess)
	character_util.set_active_state(snow_princess, 'disabled')
	for k, v in pairs(audition_rocks) do
		character_util.set_active_state(v, 'enabled')
	end
	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	-- 참가자 2
	-- 자… 다음 참가자를 모셔보겠습니다!
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_21', skip = true})

	-- 악마의 딸! 라비!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_22', skip = true})

	music_player:PlaySfxOneShot('01_crowd_clap_02')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'wow', delay = 0.3},
						{index = 3, behave = 'clap'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'jump', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'wow'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
					})

	local time_scale = 3
	-- (attack, gauntlet_kick2, left)(왼쪽 바위를 부수면서)흐압!
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	character_util.set_direction(demon_sister, 'left')
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_kid_boy_shout_01')
	speech_bubble_util.show_speech_bubble_async(demon_sister,
			{ key = 'movie_3_burywood_got_talent_23', skip = true})
	character_util.set_anim_and_emotion(demon_sister,
			{ name = 'gauntlet_kick2', loop = false, scale = time_scale}, { name = 'attack'})

	wait_for_sec(0.1)

	self:break_rock(demon_sister, audition_rocks[1])
	character_util.remove_anim_and_emotion(demon_sister)

	sfx_drum:Stop()
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')

	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 1, behave = 'wow', delay = 0.3},
		{index = 4, behave = 'jump'},
		{index = 6, behave = 'clap'},
		{index = 7, behave = 'clap', delay = 0.7},
		{index = 8, behave = 'clap'},
		{index = 11, behave = 'clap', delay = 0.3},
		{index = 14, behave = 'jump'},
		{index = 16, behave = 'wow', delay = 0.2},
	})

	-- (attack, gauntlet_kick2, right)(오른쪽 바위를 부수면서)흐압!
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	character_util.set_direction(demon_sister, 'right')
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_kid_boy_shout_01')
	speech_bubble_util.show_speech_bubble_async(demon_sister,
			{ key = 'movie_3_burywood_got_talent_23', skip = true})
	character_util.set_anim_and_emotion(demon_sister,
			{ name = 'gauntlet_kick2', loop = false, scale = time_scale}, { name = 'attack'})

	wait_for_sec(0.1)

	self:break_rock(demon_sister, audition_rocks[2])
	character_util.remove_anim_and_emotion(demon_sister)

	sfx_drum:Stop()
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')

	music_player:PlaySfxOneShot('01_crowd_clap_02')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 1, behave = 'great', delay = 0.3},
		{index = 4, behave = 'jump'},
		{index = 6, behave = 'clap'},
		{index = 7, behave = 'clap', delay = 0.7},
		{index = 8, behave = 'clap'},
		{index = 11, behave = 'clap', delay = 0.3},
		{index = 14, behave = 'jump'},
		{index = 16, behave = 'wow', delay = 0.2},
	})

	-- (attack, gauntlet_kick2, down)(부셔지지 않는 바위를 부수면서)흐아아아아압!(슬로우 모션)
	time_scale = 5
	character_util.set_direction(demon_sister, 'down')

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})

	speech_bubble_util.show_speech_bubble(demon_sister,
			{ key = 'movie_3_burywood_got_talent_24',
			  skip = false, bubble_type = 'shout', bubble_direction = 'ct'})

	character_util.set_anim_and_emotion(demon_sister,
			{ name = 'gauntlet_kick2', loop = false, scale = time_scale}, { name = 'attack'})

	character_util.move_to_async(demon_sister,
			audition_rocks[3].Position + vector(0,1,0.3), 1.5)

	camera_util.shake(0.1, 0.2)
	self:break_rock(demon_sister, audition_rocks[3])
	character_util.remove_anim_and_emotion(demon_sister)

	sfx_drum:Stop()
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')
	music_player:PlaySfxOneShot('01_crowd_shout_05')

	character_util.set_emotion(audition_host, { name = 'surprise'})
	camera_util.move_async(camera_pos, 1)

	music_player_util.play_stage_music({state = 'event', name = 'bgm_result', mix = 2})

	--수고하셨습니다! 라비!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_25', skip = true})

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'jump', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
					}))

	--엄청난 힘입니다!
	music_player:PlaySfxOneShot('01_crowd_clap_03')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_26', skip = true})

	--심사위원 1 : 대단한 힘입니다!
	speech_bubble_util.show_speech_bubble_async(idol_captain,
			{ key = 'movie_3_burywood_got_talent_27', skip = true})
	--심사위원 2 : 소름이 돋네요!
	speech_bubble_util.show_speech_bubble_async(vampire_idol,
			{ key = 'movie_3_burywood_got_talent_28', skip = true})

	character_util.remove_anim_and_emotion(audition_host)

	wait = true
	branches:Clear()

	-- 진짜 고릴라네요! 바나나 던져봐도 되나요?(빨간색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_5'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			brutal_cnt = brutal_cnt + 1
			is_bitten[2] = true
			wait = false
		end})
	-- 세계 최강의 힘인 것 같습니다!(흰색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_6'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if is_bitten[2] then
		-- (mad, jingak, down)뭐? 너도 박치기로 날려줄까?
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		character_util.set_anim_and_emotion(demon_sister, { name = 'jingak'}, { name = 'mad'})
		speech_bubble_util.show_speech_bubble(demon_sister, { key = 'movie_3_burywood_got_talent_29', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_03')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'jump', delay = 0.3},
			{index = 2, behave = 'jump'},
			{index = 4, behave = 'jump'},
			{index = 3, behave = 'love_1', delay = 0.3},
			{index = 6, behave = 'clap'},
			{index = 8, behave = 'love_2', delay = 0.1},
			{index = 9, behave = 'clap'},
			{index = 10, behave = 'clap'},
			{index = 11, behave = 'jump', delay = 0.2},
			{index = 13, behave = 'jump', delay = 0.4},
			{index = 14, behave = 'clap'},
			{index = 16, behave = 'clap'},
		})
	else
		-- (smile, cross_arm, down)후훗! 뭘 아는 군!
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_anim_and_emotion(demon_sister,
				{ name = 'cross_arm'}, { name = 'smile'})
		speech_bubble_util.show_speech_bubble(demon_sister, { key = 'movie_3_burywood_got_talent_30', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_04')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'jump', delay = 0.3},
			{index = 4, behave = 'jump', delay = 0.2},
			{index = 5, behave = 'hoot_1'},
			{index = 8, behave = 'jump', delay = 0.1},
			{index = 10, behave = 'jump'},
			{index = 11, behave = 'jump'},
			{index = 14, behave = 'hoot_2', delay = 0.5},
		})
	end

	music_player_util.play_stage_music({state = 'muted', mix = 2})

	wait_for_sec(1)
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
	character_util.remove_anim_and_emotion(audition_host)
	character_util.set_active_state(demon_sister, 'disabled')
	character_util.set_position(magician, stage_mid_pos)
	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	local appear_pos = stage_mid_pos + vector(0, 0, -1)

	--오늘의 마지막 참가자를 모셔보겠습니다!
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_21', skip = true})

	-- 머나먼 왕국의 궁정 마법사! 돌프!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_38', skip = true})

	music_player:PlaySfxOneShot('01_crowd_clap_02')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'clap'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'wow'},
						{index = 7, behave = 'clap', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'wow'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
	})

	--늑대를 불러보겠습니다!
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	character_util.set_anim(magician, {name = 'release', loop = true, sfx_name = '01_swing_01'})
	character_util.set_emotion(magician, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(magician,
			{ key = 'movie_3_burywood_got_talent_39', skip = true})
	character_util.remove_anim_and_emotion(magician)

	-- 아브라카타브라!
	character_util.set_anim(magician, {name = 'dance_voodoo', mix_duration = 0.1, loop = false})
	character_util.set_emotion(magician, {name = 'smile'})

	music_player:PlaySfxOneShot('02_cast_magic_02')
	local effect_1 = unity_object_pool.GetOrCreate('fx_obj_event_curse_item_loop'):Instantiate(appear_pos)

	wait_for_sec(2.0)

	effect_1:Dispose()
	character_util.remove_anim_and_emotion(magician)

	-- 멍멍이 등장
	character_util.set_direction(dog, 'right')
	character_util.set_anim(dog, {name = 'happy', loop = true})
	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')
	music_player:PlaySfxOneShot('01_pet_ordinary_01')
	sfx_drum:Stop()
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_position(dog, appear_pos)

	character_util.normal_jump(magician)
	character_util.set_emotion(magician, {name = 'doyagao'})

	music_player:PlaySfxOneShot('01_crowd_shout_05')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'cute', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'clap', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'cute'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 16, behave = 'clap', delay = 0.5},
	})

	local dog_wp = {
		stage_mid_pos + vector(1, 0, -1),
		stage_mid_pos + vector(1.5, 0, 0),
		stage_mid_pos + vector(1, 0, 1),
		stage_mid_pos + vector(0, 0, 1),
		stage_mid_pos + vector(-1, 0, 1),
		stage_mid_pos + vector(-1.5, 0, 0),
		stage_mid_pos + vector(-1, 0, -1),
		stage_mid_pos + vector(0, 0, -1.5),
	}

	character_util.remove_anim_and_emotion(dog)
	music_player:PlaySfxOneShot('01_pet_bark_01')
	wp_util.move_way_points_async(dog, {waypoints = dog_wp, speed = 4})

	music_player:PlaySfxOneShot('01_pet_howl_01')
	character_util.set_anim(dog, {name = 'victory', loop = true})

	wait_for_sec(2.3)

	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_active_state(dog, 'disabled')

	wait_for_sec(0.5)

	--사자를 불러보겠습니다!
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	character_util.set_anim(magician, {name = 'release', loop = true, sfx_name = '01_swing_01'})
	character_util.set_emotion(magician, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(magician,
			{ key = 'movie_3_burywood_got_talent_40', skip = true})
	character_util.remove_anim_and_emotion(magician)

	-- 아브라카타브라!
	character_util.set_anim(magician, {name = 'dance_voodoo', mix_duration = 0.1, loop = false})
	character_util.set_emotion(magician, {name = 'smile'})

	music_player:PlaySfxOneShot('02_cast_magic_02')
	local effect_2 = unity_object_pool.GetOrCreate('fx_obj_event_curse_item_loop'):Instantiate(appear_pos)

	wait_for_sec(2.0)

	effect_2:Dispose()
	character_util.remove_anim_and_emotion(magician)

	-- 고양이 등장
	character_util.remove_anim_and_emotion(cat)
	character_util.set_direction(cat, 'left')

	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')
	music_player:PlaySfxOneShot('01_cat_meow_01')
	sfx_drum:Stop()
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_position(cat, appear_pos)

	character_util.normal_jump(magician)
	character_util.set_emotion(magician, {name = 'doyagao'})

	wait_for_sec(0.5)

	character_util.set_anim(cat, {name = 'scratch', loop = false})

	music_player_util.play_sfx({sfx_name = '01_crowd_arena_exclamation_01', duration = 4.5, fade_out_time = 1.5,
								type_priority = 'event', player_priority = 'npc'})

	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'cute'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 7, behave = 'clap', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'clap'},
						{index = 13, behave = 'cute', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
	})

	music_player:PlaySfxOneShot('01_cat_purr_01')
	character_util.set_emotion(cat, {name = 'tired'})
	character_util.set_anim(cat, {name = 'hurt', mix_duration = 0.1, loop = false})

	wait_for_sec(2)

	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_active_state(cat, 'disabled')

	wait_for_sec(0.5)

	--지상 최강의 생물을 불러보겠습니다!
	sfx_drum = music_player_util.play_sfx({sfx_name = '01_gatcha_drum_roll_01', loop = true, type_priority = 'event', player_priority = 'npc'})
	character_util.set_anim(magician, {name = 'release', loop = true, sfx_name = '01_swing_01'})
	character_util.set_emotion(magician, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(magician,
			{ key = 'movie_3_burywood_got_talent_41', skip = true})
	character_util.remove_anim_and_emotion(magician)

	-- 아브라카타브라!
	character_util.set_anim(magician, {name = 'dance_voodoo', mix_duration = 0.1, loop = false})
	character_util.set_emotion(magician, {name = 'smile'})

	music_player:PlaySfxOneShot('02_cast_magic_02')
	music_player:PlaySfxOneShot('01_earthquake_01')
	local effect_3 = unity_object_pool.GetOrCreate('fx_obj_event_curse_item_loop'):Instantiate(appear_pos)
	effect_3.transform.localScale = unity_class.vector3.one * 1.2

	camera_util.shake(0.2, 2)

	wait_for_sec(2.0)

	effect_3:Dispose()
	character_util.remove_anim_and_emotion(magician)

	character_util.set_direction(rabbit, 'right')
	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	music_player:PlaySfxOneShot('01_gatcha_spotlight_01')
	music_player:PlaySfxOneShot('01_die_ant_01')
	sfx_drum:Stop()
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_position(rabbit, appear_pos)

	character_util.normal_jump(magician)

	character_util.set_emotion(magician, {name = 'doyagao'})

	wait_for_sec(0.5)

	wp_util.move_way_points(rabbit,
			{waypoints = rabbit.Position + vector(1.5, 0, 0), speed = 3})

	character_util.jump(rabbit, 0.4, 0.2)
	wait_for_sec(0.25)

	character_util.jump(rabbit, 0.4, 0.2)

	music_player:PlaySfxOneShot('01_crowd_shout_05')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'clap'},
						{index = 4, behave = 'jump', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 8, behave = 'cute'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 13, behave = 'cute', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
	})

	wait_for_sec(0.5)

	wp_util.move_way_points(rabbit,
			{waypoints = rabbit.Position - vector(1.5, 0, 0), speed = 3})

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(rabbit, 0.4, 0.2)
	wait_for_sec(0.25)

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(rabbit, 0.4, 0.2)
	wait_for_sec(0.25)

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(appear_pos)
	character_util.set_active_state(rabbit, 'disabled')

	wait_for_sec(0.5)

	music_player_util.play_stage_music({state = 'event', name = 'bgm_result', mix = 2})

	--수고하셨습니다! 돌프!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_42', skip = true})
	--뛰어난 마법!
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_43', skip = true})

	-- 정말 무시무시한 생물들이었어요!
	speech_bubble_util.show_speech_bubble_async(idol_captain,
			{ key = 'movie_3_burywood_got_talent_44', skip = true})
	-- 너무 무서웠어요...
	speech_bubble_util.show_speech_bubble_async(vampire_idol,
			{ key = 'movie_3_burywood_got_talent_45', skip = true})

	wait = true
	branches:Clear()

	-- 제대로 하는 게 하나도 없는데?
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_9'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			brutal_cnt = brutal_cnt + 1
			is_bitten[3] = true
			wait = false
		end})
	-- 왕국 마법사 ㅇㅈ
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_10'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if is_bitten[3] then
		--(dealwithit, cross_arm, down)훗, 시기와 질투는 항상 나를 따라다니는 군...
		character_util.set_emotion(magician, {name = 'dealwithit', loop = false})
		character_util.set_anim(magician, {name = 'cross_arm', loop = true})
		speech_bubble_util.show_speech_bubble(magician,
				{ key = 'movie_3_burywood_got_talent_46', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_03')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'jump', delay = 0.3},
			{index = 2, behave = 'jump'},
			--{index = 3, behave = 'clap'},
			{index = 4, behave = 'jump'},
			{index = 3, behave = 'love_1', delay = 0.3},
			{index = 6, behave = 'clap'},
			--{index = 7, behave = 'clap'},
			{index = 8, behave = 'love_2', delay = 0.1},
			{index = 9, behave = 'clap'},
			{index = 10, behave = 'clap'},
			{index = 11, behave = 'jump', delay = 0.2},
			--{index = 12, behave = 'clap'},
			{index = 13, behave = 'jump', delay = 0.4},
			{index = 14, behave = 'clap'},
			--{index = 15, behave = 'clap'},
			{index = 16, behave = 'clap'},
		})
	else
		--(smile, cross_arm, down)후훗! 뭘 아는 군!
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_emotion(magician, {name = 'smile'})
		character_util.set_anim(magician, {name = 'cross_arm', loop = true})
		speech_bubble_util.show_speech_bubble(magician,
				{ key = 'movie_3_burywood_got_talent_30', skip = true})

		music_player:PlaySfxOneShot('01_crowd_shout_04')
		yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
			{index = 1, behave = 'jump', delay = 0.3},
			{index = 4, behave = 'jump', delay = 0.2},
			{index = 5, behave = 'jump'},
			{index = 8, behave = 'jump', delay = 0.1},
			{index = 10, behave = 'hoot_1'},
			{index = 11, behave = 'jump'},
			{index = 14, behave = 'hoot_2', delay = 0.5},
		})
	end

	music_player_util.play_stage_music({state = 'muted', mix = 1.5})

	wait_for_sec(1)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
	character_util.set_active_state(magician, 'disabled')

	-- 참여자들 전부 불러냄

	-- 위치
	character_util.set_position(audition_host, vector(99.5, 1, 51))
	character_util.set_position(idol_captain, vector(100.5, 1, 48.5))
	character_util.set_position(user_party.Leader, vector(102.5, 1, 48.5))
	character_util.set_position(vampire_idol, vector(104.5, 1, 48.5))

	character_util.set_direction(audition_host, 'down')
	character_util.set_direction(idol_captain, 'down')
	character_util.set_direction(user_party.Leader, 'down')
	character_util.set_direction(vampire_idol, 'down')

	character_util.set_emotion(idol_captain, {name = 'smile'})
	character_util.set_emotion(vampire_idol, {name = 'smile'})

	character_util.set_active_state(snow_princess, 'enabled')
	character_util.remove_anim_and_emotion(snow_princess)
	character_util.set_position(snow_princess, vector(101.5, 1, 50.5))
	character_util.set_direction(snow_princess, 'down')
	character_util.set_emotion(snow_princess, 'attack')

	character_util.set_active_state(demon_sister, 'enabled')
	character_util.remove_anim_and_emotion(demon_sister)
	character_util.set_position(demon_sister, vector(102.5, 1, 50.5))
	character_util.set_direction(demon_sister, 'down')
	character_util.set_emotion(demon_sister, 'attack')

	character_util.set_active_state(magician, 'enabled')
	character_util.remove_anim_and_emotion(magician)
	character_util.set_position(magician, vector(103.5, 1, 50.5))
	character_util.set_direction(magician, 'down')
	character_util.set_emotion(magician, 'attack')

	music_player_util.play_stage_music({state = 'field', mix = 2})
	music_player_util.play_sfx({sfx_name = '01_crowd_clap_02', type_priority = 'event', player_priority = 'npc'})

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
						{index = 1, behave = 'jump', delay = 0.5},
						{index = 2, behave = 'clap', delay = 0.3},
						{index = 3, behave = 'clap'},
						{index = 4, behave = 'wow', delay = 0.3},
						{index = 5, behave = 'jump', delay = 0.1},
						{index = 6, behave = 'clap'},
						{index = 7, behave = 'clap', delay = 0.7},
						{index = 8, behave = 'clap'},
						{index = 9, behave = 'jump', delay = 0.5},
						{index = 10, behave = 'jump'},
						{index = 11, behave = 'jump'},
						{index = 12, behave = 'wow'},
						{index = 13, behave = 'clap', delay = 0.3},
						{index = 14, behave = 'jump'},
						{index = 15, behave = 'clap', delay = 0.2},
						{index = 16, behave = 'clap', delay = 0.5},
	})

	-- 오늘의 오디션은 여기까지 입니다!
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_31', skip = true})

	-- 심사위원 분들의 의견을 한번 들어볼까요?
	speech_bubble_util.show_speech_bubble_async(audition_host,
			{ key = 'movie_3_burywood_got_talent_32', skip = true})

	--심사위원 1 : 베리우드에는 정말 대단하신 분들이 많은 것 같아요!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_anim(idol_captain, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(idol_captain,
			{ key = 'movie_3_burywood_got_talent_32_0', skip = true})

	music_player:PlaySfxOneShot('01_crowd_shout_02')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 1, behave = 'jump', delay = 0.3},
		{index = 2, behave = 'clap', delay = 0.15},
		{index = 3, behave = 'cap_1'},
		{index = 4, behave = 'jump'},
		{index = 5, behave = 'jump', delay = 0.3},
		{index = 6, behave = 'clap'},
		{index = 7, behave = 'cap_2'},
		{index = 8, behave = 'jump', delay = 0.1},
	})

	character_util.remove_anim(idol_captain)

	--심사위원 2 : 베리우드는 정말 엄청난 곳인 것 같습니다!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_anim(vampire_idol, {name = 'success', loop = true})
	speech_bubble_util.show_speech_bubble_async(vampire_idol,
			{ key = 'movie_3_burywood_got_talent_32_1', skip = true})

	music_player:PlaySfxOneShot('01_crowd_shout_02')
	music_player:PlaySfxOneShot('01_crowd_shout_03')
	yield_return_func(self.spectator_action, self, spectator_list, direction_list, {
		{index = 9, behave = 'vam_1', delay = 0.3},
		{index = 10, behave = 'clap', delay = 0.15},
		{index = 11, behave = 'jump'},
		{index = 12, behave = 'jump'},
		{index = 13, behave = 'jump', delay = 0.3},
		{index = 14, behave = 'clap'},
		{index = 15, behave = 'jump'},
		{index = 16, behave = 'vam_2', delay = 0.1},
	})

	character_util.remove_anim(vampire_idol)

	wait = true
	local branch
	branches:Clear()

	-- 제가 본 사람들 중 가장 시시한 사람들만 모아놓은 것 같네요. 이딴 걸 심사하라고 날 섭외하다니… 다 해고야! 해고! 해고!...(빨간색)
	if brutal_cnt > 0 then
		branches:Add({
			Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_7'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				brutal_cnt = brutal_cnt + 1
				branch = 0
				wait = false
			end})
	end
	-- 정말 좋은 기회였던 것 같습니다. 섭외해주셔서 감사합니다.(흰색)
	branches:Add({
		Text = game_string:GetString('movie_3_burywood_got_talent_talk_branch_8'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			branch = 1
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if branch == 0 then
		character_util.set_anim(user_party.Leader, {name = 'release', loop = true})
		character_util.set_emotion(user_party.Leader, {name = 'mad'})

	else
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_emotion(user_party.Leader, {name = 'smile'})

	end

	wait_for_sec(0.5)

	if brutal_cnt > 0 then
		camera_util.move_async(vector(102.5, 1, 49.5), 0.3)

		if is_bitten[1] then
			if CS.Foundations.GameEnvironment.IsKongJapan then
				music_player:PlaySfxOneShot('01_holy_01')
			else
				music_player:PlaySfxOneShot('01_let_it_go_01')
			end
			character_util.set_anim(snow_princess, {name = 'sing', loop = true})
			speech_bubble_util.show_speech_bubble_async(snow_princess,
					{key = 'movie_3_burywood_got_talent_47', skip = true})
			character_util.remove_anim(snow_princess)
		end

		if is_bitten[2] then
			character_util.set_anim(demon_sister, {name = 'release', loop = true, sfx_name = '01_swing_01'})
			speech_bubble_util.show_speech_bubble_async(demon_sister,
					{key = 'movie_3_burywood_got_talent_48', skip = true})
			character_util.remove_anim(demon_sister)
		end

		if is_bitten[3] then
			music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
			character_util.set_anim(magician, {name = 'sing', loop = true})
			speech_bubble_util.show_speech_bubble_async(magician,
					{key = 'movie_3_burywood_got_talent_49', skip = true})
			character_util.remove_anim(magician)
		end

		camera_util.resize_to(3.5, 2)

		character_util.remove_emotion(idol_captain)
		character_util.remove_emotion(vampire_idol)

		character_util.set_direction(idol_captain, 'right')
		character_util.set_direction(vampire_idol, 'left')

		character_util.set_emotion(idol_captain, {name = 'surprise'})
		character_util.set_emotion(vampire_idol, {name = 'surprise'})

		music_player:PlaySfxOneShot('01_slowmotion_01')

		if is_bitten[1] then
			character_util.set_emotion(snow_princess, {name = 'mad'})
			snow_princess.SpineController:SetAttachment('[base]weapon2', 'head_crusher')
			character_util.set_anim(snow_princess, {name = 'bow_attack', loop = false, scale = 0.25})
			character_util.jump(snow_princess, 1.5, 3)
			character_util.move_to(snow_princess, user_party.Leader.Position, 3, nil, true)
		else

			character_util.set_emotion(snow_princess, {name = 'surprise'})
		end

		if is_bitten[2] then
			character_util.set_emotion(demon_sister, {name = 'mad'})
			demon_sister.SpineController:SetAttachment('[base]weapon1', 'head_crusher')
			character_util.set_anim(demon_sister, {name = 'twohand_attack2', loop = false, scale = 0.2})
			character_util.jump(demon_sister, 1.5, 3)
			character_util.move_to(demon_sister, user_party.Leader.Position, 3, nil, true)
		else

			character_util.set_emotion(demon_sister, {name = 'surprise'})
		end

		if is_bitten[3] then
			character_util.set_emotion(magician, {name = 'mad'})
			magician.SpineController:SetAttachment('[base]weapon2', 'head_crusher')
			character_util.set_anim(magician, {name = 'bow_attack', loop = false, scale = 0.25})
			character_util.jump(magician, 1.5, 3)
			character_util.move_to(magician, user_party.Leader.Position, 3, nil, true)
		else

			character_util.set_emotion(magician, {name = 'surprise'})
		end

		wait_for_sec(0.5)
	end

	wait_for_sec(1)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	if brutal_cnt > 0 then
		music_player:PlaySfxOneShot('02_hit_critical_01')
	end

	self.is_event_done = true

	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.remove_emotion(snow_princess)
	character_util.remove_emotion(demon_sister)
	character_util.remove_emotion(magician)
	camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})
	character_util.set_position(user_party.Leader, audition_staff.Position - vector(0, 0, 2))
	camera_util.resize_to_default()
	character_util.set_active_state(audition_host, 'disabled')

	character_util.remove_emotion(idol_captain)
	character_util.remove_emotion(vampire_idol)

	character_util.set_active_state(idol_captain, 'disabled')
	character_util.set_active_state(vampire_idol, 'disabled')

	snow_princess.SpineController:SetAttachment('[base]weapon2', 'empty')
	demon_sister.SpineController:SetAttachment('[base]weapon1', 'empty')
	magician.SpineController:SetAttachment('[base]weapon2', 'empty')

	field:RemoveTint('audition', 0)

	if brutal_cnt > 0 then
		character_util.set_direction(user_party.Leader, 'left')
		character_util.set_emotion(user_party.Leader, {name = 'damaged'})
		character_util.set_anim(user_party.Leader, {name = 'prostrate', loop = true, scale = 1})
	else
		character_util.set_direction(user_party.Leader, 'up')
	end

	wait_for_sec(1.0)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	if brutal_cnt > 0 then

		wait_for_sec(1.0)

		music_player:PlaySfxOneShot('01_rustle_01')
		character_util.shake(user_party.Leader, 0.04, 0.2)

		wait_for_sec(0.2)

		character_util.remove_emotion(user_party.Leader)

		music_player:PlaySfxOneShot('01_player_popup_01')
		character_util.mario_jump_async(user_party.Leader, user_party.Leader.Direction, 0.5, 0.3)

		wait_for_sec(0.3)
	end

	character_util.align_party(audition_staff.Position - vector(0, 0, 1), 'down', 1, 'arc')

	if brutal_cnt == 0 then
		-- (tired, idle, down)독설을 하나도 안 하다니…
		-- (tired, idle, down)시청률도 그대로네요…
		-- (tired, idle, down)이거나 받고 갈 길 가세요!
		music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
		character_util.set_anim_and_emotion(audition_staff, { name = 'idle'}, { name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_33', skip = true})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_34', skip = true})
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_35', skip = true})
	else
		-- (smile, clap, down)고맙습니다! 당신의 독설 덕에 시청률이 (독설횟수)*5%나 증가했어요!
		local clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_01', type_priority = 'event', player_priority = 'npc'})
		character_util.set_anim_and_emotion(audition_staff,
				{ name = 'clap', loop = true}, { name = 'smile'})
		local text = game_string:Format('movie_3_burywood_got_talent_36', brutal_cnt * 5)
		speech_bubble_util.show_speech_bubble_async(audition_staff, { key = text, skip = true})
		clap_sfx:FadeOut(0.5)

		-- (smile, clap, down)여기 보상입니다!
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		speech_bubble_util.show_speech_bubble_async(audition_staff,
				{ key = 'movie_3_burywood_got_talent_37', skip = true})
	end

	get_field_object(self.audition_door_name).ActiveState = active_state('enabled')

	character_util.set_anim(audition_staff, {name = 'cast2', loop = false})
	-- 스타피스 지급
	local star_piece = get_field_object(self.starpiece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(audition_staff.Position + vector(0, 1, 0)))

	if audition_staff.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		audition_staff.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	wait_for_sec(2)

	character_util.remove_anim_and_emotion(audition_staff)

	character_util.spine_set_alpha_fade(audition_staff, 0, 0.7)
	wp_util.move_way_points_async(audition_staff,
			{waypoints = audition_staff.Position + vector(0, 0, 0.7), speed = 1})
	character_util.set_position(audition_staff, vector(999, 0, 999))

	self:disable_all_npc()
end

function local_class:jump_to_player(character)
	character_util.set_emotion(character, {name = 'mad'})
	character.SpineController:SetAttachment('[base]weapon2', 'head_crusher')
	character_util.set_anim(character, {name = 'bow_attack', loop = false, scale = 0.25})
	character_util.jump(character, 1.5, 3)
	character_util.move_to(character, user_party.Leader.Position, 3, nil, true)
end

-- data : {{index, behave}, ... }
function local_class:spectator_action(spectator_list, direction_list, data)
	local count = #data

	if count == 16 then
		camera_util.shake(0.05, 0.5)
	end

	local cb = function()
		count = count - 1
	end

	for _, info in pairs(data) do
		local index = lua_helper.get_value(info, 'index')

		if index <= #spectator_list and index >= 1 then
			local spectator = spectator_list[index]
			local direction = direction_list[index]
			local behave = lua_helper.get_value(info, 'behave')
			local delay = lua_helper.get_value(info, 'delay', 0)

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.spectator_behave, self, spectator, behave, direction, delay, cb))
		else
			cb()
		end
	end

	while count > 0 do
		coroutine.yield(nil)
	end
end

function local_class:spectator_behave(spectator, behave, direction, delay, callback)
	wait_for_sec(delay)

	if behave == 'clap' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'clap', loop = true})
		wait_for_sec(1)

	elseif behave == 'hoot_1' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'release', loop = true})
		character_util.set_emotion(spectator, {name = 'attack'})
		-- 우우~~
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_50', skip = true})

	elseif behave == 'hoot_2' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'cross_arm', loop = true})
		character_util.set_emotion(spectator, {name = 'attack'})
		-- 재미없어!!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_51', skip = true})

	elseif behave == 'love_1' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'sing', loop = true})
		character_util.set_emotion(spectator, {name = 'love'})
		-- 소신있어!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_52', skip = true})

	elseif behave == 'love_2' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'cast', loop = true})
		character_util.set_emotion(spectator, {name = 'love'})
		-- 저 시크함...!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_53', skip = true})

	elseif behave == 'cap_1' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'success', loop = true})
		--character_util.set_emotion(spectator, {name = 'love'})
		-- 에바! 에바!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_54', skip = true})

	elseif behave == 'cap_2' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'cast2', loop = true})
		--character_util.set_emotion(spectator, {name = 'love'})
		-- 에바 사랑해요!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_55', skip = true})

	elseif behave == 'vam_1' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'success', loop = true})
		--character_util.set_emotion(spectator, {name = 'love'})
		-- 세실! 세실!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_56', skip = true})

	elseif behave == 'vam_2' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'cast2', loop = true})
		--character_util.set_emotion(spectator, {name = 'love'})
		-- 세실 너무좋아!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_57', skip = true})

	elseif behave == 'jump' then
		character_util.normal_jump_async(spectator)
		character_util.normal_jump_async(spectator)

	elseif behave == 'amaze' then
		character_util.set_direction(spectator, 'up')
		character_util.set_anim(spectator, {name = 'embarrassed', loop = true})
		character_util.normal_jump(spectator)
		-- 헉!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_58', skip = true})

	elseif behave == 'wow' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'sing', loop = true})
		character_util.set_emotion(spectator, {name = 'love'})
		-- 와아아!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_59', skip = true})

	elseif behave == 'great' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'sing', loop = true})
		character_util.set_emotion(spectator, {name = 'love'})
		-- 대단해!!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_60', skip = true})

	elseif behave == 'cute' then
		character_util.set_direction(spectator, direction)
		character_util.set_anim(spectator, {name = 'sing', loop = true})
		character_util.set_emotion(spectator, {name = 'love'})
		-- 귀여워!!
		speech_bubble_util.show_speech_bubble_async(spectator, {key = 'movie_3_burywood_got_talent_61', skip = true})
	end

	character_util.remove_anim_and_emotion(spectator)
	character_util.set_direction(spectator, 'up')
	callback()
end

function local_class:disable_all_npc()
	stage_util.set_character_active_state(self.audition_host_name, 'disabled')
	stage_util.set_character_active_state(self.idol_captain_name, 'disabled')
	stage_util.set_character_active_state(self.vampire_idol_name, 'disabled')
	stage_util.set_character_active_state(self.audition_staff_name, 'disabled')

	stage_util.set_character_active_state('snow_princess', 'disabled')
	stage_util.set_character_active_state('demon_sister', 'disabled')
	stage_util.set_character_active_state('magician', 'disabled')

	stage_util.set_character_active_state('magician_dog', 'disabled')
	stage_util.set_character_active_state('magician_cat', 'disabled')
	stage_util.set_character_active_state('magician_rabbit', 'disabled')

	for i = 1, 3 do
		stage_util.set_fo_active_state(self.audition_rocks_name .. i, 'disabled')
	end

	-- 관중들
	for i = 1, self.spectator_left_count do
		stage_util.set_character_active_state(self.spectator_left_name .. i, 'disabled')
	end

	for i = 1, self.spectator_right_count do
		stage_util.set_character_active_state(self.spectator_right_name .. i, 'disabled')
	end

	for i = 1, 5 do
		stage_util.set_character_active_state('audition_staff_' .. i, 'disabled')
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
