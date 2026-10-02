local local_class = newclass('Idols1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	--10, 34.5, 44, 68.5, 78, 103, 118))
	self.phase1_start = 10
	self.phase1_end = 34.5
	self.phase2_start = 44
	self.phase2_end = 68.5
	self.phase3_start = 78
	self.phase3_end = 103
	self.song_end = 118

	-- 1페이즈 돌 던지고 나서 따라오는 아이들
	self.get_phase1_kids = function()
		local result = {}
		local i = 1
		while true do
			local tmp = get_character('phase1_kid_'..i)
			i = i + 1
			if tmp == nil then break end
			table.insert(result,tmp)
		end
		return result
	end

	self.get_all_phase1_kids = function()
		local result = self.get_phase1_kids()
		local i = 1
		while true do
			local tmp = get_character('phase1_kid_'..i..'_extra')
			i = i + 1
			if tmp == nil then break end
			table.insert(result,tmp)
		end
		return result
	end

	self.get_phase3_monsters = function()
		local result = {}
		local i = 1
		while true do
			local tmp = get_character('phase3_monster_'..i)
			i = i + 1
			if tmp == nil then break end
			table.insert(result,tmp)
		end
		return result
	end

	--FX효과 프리셋
	self.hit_effect_preset = 'FX_hit'
	self.impact_hit_effect_preset = 'FX_lasthit'

	-- 돌 던지는거 컨트롤 flag
	self.throw_rock_stat = true

	-- 페이즈 3 전투 연출용 딕셔너리
	self.is_battle_dict = nil

	-- 실패시 연출 플래그
	self.first = true

	-- 아이들 위치 초기화
	self.kid_start_pos = nil

	-- 연출용 아이템 담아 놓는 용도
	self.temp_rocks = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.RhythmGameEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	-- 연출용 이펙트 로드
	unity_object_pool.GetOrCreate('fx_cwp_ice_succubus')
	unity_object_pool.GetOrCreate('fx_cwp_ice_succubus_cast')
	unity_object_pool.GetOrCreate('FX_reset_object')
	unity_object_pool:WaitAll()
	CS.MessyText.PreLoad()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	local loop_count = user_party.Count - 1
	for i = 0, loop_count do
		user_party[i].Position = vector(999, 0, 999)
	end

	self.origin_leader = user_party[0]

	local cecil = get_character('idols_member_cecil')

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	CS.Oak.ICharacterExtensions.ConvertToManualCharacter(cecil, param)

	self.current_difficulty = 'normal'

	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	-- 꼬마들 최초 위치 초기화 위해 기억해둬야됨
	local kids = self.get_all_phase1_kids()
	self.kid_start_pos = {}
	for i=1, #kids do
		self.kid_start_pos[i] = kids[i].Position
	end

	-- 페이즈3 몬스터들도 마찬가지
	local monsters = self.get_phase3_monsters()
	self.monsters_start_pos = {}
	for i=1, #monsters do
		self.monsters_start_pos[i] = monsters[i].Position
	end

	-- 전투 연출용 딕셔너리 초기화
	self.is_battle_dict = create_generic_dictionary(CS.System.String, CS.System.Object)

	self.temp_rocks = { }

	local normal_cleared = get_field_object('normal_real_door').FieldObjectBehaviour.IsOpen
	if normal_cleared then
		yield_return_func(self.hq_scene, self, false, false)
	else
		CS.Oak.LoadingScreen.Instance:Hide(0.25, CS.Oak.Interpolations.Linear, true);
		wait_for_sec(0.25)
		coroutine.yield(nil)
		screen_util.fade_out_async(0.0, unity_class.color.black, 'linear')
		coroutine.yield(nil)
		screen_util.fade_in_circular(0.0, screen_util.get_interpolations('linear'))


		yield_return_func(self.story_intro_routine, self)
	end
end

-- 스토리 인트로
function local_class:story_intro_routine()
	field_ui_manager:Hide()

	local bianca_hide = field:GetMarker('bianca_hide').position
	local room1 = field:GetMarker('room_1_center').position
	local room_final = field:GetMarker('room_final_center').position
	local hq = field:GetMarker('hq_start').position + vector(0, 0, 1)

	local bianca = get_character('stalker_bianca')
	bianca.Position = bianca_hide
	bianca.Direction = CS.Oak.Direction.Right
	character_util.set_anim(bianca, { name = 'cast', loop = true })
	bianca.SpineController:ForceUpdateSpines(2.0)

	local knight = get_character('knight_female')
	knight.Position = room1 + vector(0.5, 0, 0.0)
	knight.Direction = CS.Oak.Direction.Left
	character_util.set_emotion(knight, { name = 'smile', loop = false })

	local yuze = get_character('yuze')
	yuze.Position = room1 + vector(-0.5, 0, 0.0)
	yuze.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(yuze, { name = 'smile', loop = false })

	local tinia = get_character('idols_member_tinia')
	local eva = get_character('idols_member_eva')
	local cecil = get_character('idols_member_cecil')

	camera_util.move(room1, 0)
	camera_util.resize_to(3.5, 0, true)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'ease_in_out_sine')
	music_player_util.play_stage_music({
		name = 'theatres/steampunk_rhythm_minigame:bgm_rhythmic_05', state = 'event', mix = 0
	})

	wait_for_sec(1.3)

	music_player:PlaySfxOneShot('02_hit_big_01')
	yield_return_func(CS.MessyText.SetMessyText, game_string:GetString('idols1_intro_label_1'), vector(0, -0.1),
			0, 9999, 30, 0, vector(0, 0), 0, 2, CS.UnityEngine.Color32(255, 255, 255, 255))

	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_intro_1', skip = true })
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_intro_2', skip = true })

	character_util.set_anim(knight, { name = 'nod', loop = true })
	wait_for_sec(0.5)

	camera_util.move(bianca.Position, 1.5)
	wait_for_sec(1.5)

	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_3', skip = true })

	music_player:PlaySfxOneShot('02_hit_big_01')
	yield_return_func(CS.MessyText.SetMessyText, game_string:GetString('idols1_intro_label_2'), vector(0, -0.1),
			0, 9999, 30, 0, vector(0, 0), 0, 2, CS.UnityEngine.Color32(255, 255, 255, 255))

	CS.MessyText.DisposeAll()

	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_4', skip = true })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_5', skip = true })

	character_util.set_anim(bianca, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	music_player:PlaySfxOneShot('02_hit_critical_01')
	camera_util.shake(0.1, 0.15)
	music_player:PlaySfxOneShot('02_hit_critical_01')
	speech_bubble_util.show_speech_bubble_async(cecil, { key = 'idols1_intro_6', skip = true, auto_layout = true, bubble_type = 'shout', screen_pos = vector(-150, 300), bubble_direction = 'ct', type_speed = 0 })

	character_util.set_anim(bianca, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_7', skip = true })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_8', skip = true })
	knight.Position = room_final + vector(0.0, 0, -0.5)
	yuze.Position = room_final + vector(0.0, 0, 0.5)

	-- 유즈의 비명소리
	music_player:PlaySfxOneShot('02_victim_scream_01')
	character_util.normal_jump(bianca)
	--bianca.SpineController:Jump(0.3, 0.3)
	wait_for_sec(0.25)
	local emoticon_pool = unity_object_pool.GetOrCreate('emoticon'):Instantiate(bianca.Position)
	local emoticon = emoticon_pool.transform:GetComponent(typeof(CS.Oak.Emoticon))
	local type = character_util.get_emoticon_type('notice')
	emoticon:Init()
	emoticon:ShowOn(bianca, unity_class.vector3.one, type)
	wait_for_sec(1.0)
	emoticon:Hide()
	wait_for_sec(0.2)
	emoticon:Dispose()

	camera_util.move(bianca.Position + vector(6, 0, 0), 1.0)
	screen_util.fade_out_async(1.0, unity_class.color.black)

	knight.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(knight, { name = 'attack', loop = false })
	character_util.set_anim(knight, { name = 'dagger_idle', loop = true })

	yuze.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(yuze, { name = 'attack', loop = false })
	character_util.set_anim(yuze, { name = 'dagger_idle', loop = true })

	camera_util.move(room_final, 0)

	screen_util.fade_in_async(1.0, unity_class.color.black)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01' })
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_intro_9', skip = true })

	screen_util.fade_out_async(1.0, unity_class.color.black)
	camera_util.move(bianca_hide, 0, { end_target = bianca })
	screen_util.fade_in_async(1.0, unity_class.color.black)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_10', skip = true })

	-- 방 1 을 향해 달려가는 비앙카
	local midpoint = bianca_hide
	midpoint.z = room1.z
	local distance = (midpoint - bianca_hide).magnitude + (midpoint - room1).magnitude
	local run_duration = 1.5
	local way_points = {}
	table.insert(way_points, midpoint)
	table.insert(way_points, room1)

	character_util.remove_anim(bianca, false)
	music_player_util.play_sfx({ sfx_name = '01_dash_01' })
	character_util.move_waypoint_async(bianca, way_points, distance / run_duration, true )

	---[[
	local all_kids = self:get_all_phase1_kids()

	-- 석상 뒤 숨어있는 위치가 원래 8각형 둘러 싼 모양 지점에서 몇 칸 씩 떨어져 있는지
	local statue_hide_points = {
		2 * unity_class.vector3.forward + 1 * unity_class.vector3.right,
		2 * unity_class.vector3.back + 1 * unity_class.vector3.right,
		1 * unity_class.vector3.forward + 1 * unity_class.vector3.right,
		1 * unity_class.vector3.forward + 1 * unity_class.vector3.left,
		2 * unity_class.vector3.forward + 1 * unity_class.vector3.left,
		2 * unity_class.vector3.back + 1 * unity_class.vector3.left,
		1 * unity_class.vector3.back + 1 * unity_class.vector3.right,
		1 * unity_class.vector3.back + 1 * unity_class.vector3.left,
	}

	-- 석상 뒤로 아이들 위치 초기화 및 활성화
	-- 석: 석상, 숫자가 해당 인덱스의 아이의 위치라 할떄 다음과 같이 타일맵에 배치 되어있음:
	-- 석4    3석
	-- 5       1
	-- 6       2
	-- 석8    7석
	-- 최종적으로 저런 모양이 되야됨.
	for i=1, #all_kids do
		all_kids[i].Position = self.kid_start_pos[i] + statue_hide_points[i]
		character_util.set_active_state(all_kids[i], 'enabled')
	end

	music_player_util.play_sfx({ sfx_name = '01_dash_06' })
	-- 비앙카가 room1 포지션에 도달함과 동시에 꼬맹이들도 석상 뒤에서 나타나 포위망 형성
	for i=1,#all_kids do
		if i == 1 or i == 2 or i == 4 or i == 8 then
			character_util.move_to(all_kids[i], all_kids[i].Position + 1 * unity_class.vector3.right, 0.5, nil, true, true )
		else
			character_util.move_to(all_kids[i], all_kids[i].Position + 1 * unity_class.vector3.left, 0.5, nil, true, true )
		end
	end

	wait_for_sec(0.5)

	for i=1,#all_kids do
		if i == 1 or i == 5 then
			character_util.move_to(all_kids[i], all_kids[i].Position + 2 * unity_class.vector3.back, 0.9, nil, true, true )
		elseif i == 3 or i == 4 then
			character_util.move_to(all_kids[i], all_kids[i].Position + 1 * unity_class.vector3.back, 1.9, nil, true, true )
		elseif i == 7 or i == 8 then
			character_util.move_to(all_kids[i], all_kids[i].Position + 1 * unity_class.vector3.forward, 1.9, nil, true, true )
		elseif i == 6 or i == 2 then
			character_util.move_to(all_kids[i], all_kids[i].Position + 2 * unity_class.vector3.forward, 0.9, nil, true, true )
		end
	end

	wait_for_sec(0.9)

	for i=1,#all_kids do
		character_util.move_to(all_kids[i], self.kid_start_pos[i], 1.0, nil, true, true )
	end

	-- 총 석상에서 꼬마들 등장 연출 시간 2.5초 : 0.5+0.8+1.1 = 2.5
	wait_for_sec(1.1)

	for i=1,#all_kids do
		character_util.look_at(all_kids[i], bianca)
	end

	-- 수상한 아줌마..
	speech_bubble_util.show_speech_bubble_async(all_kids[1], { key = 'idols1_intro_11', skip = true })

	bianca.Direction = CS.Oak.Direction.Left

	music_player_util.play_sfx({ sfx_name = '01_kid_girl_shout_01' })
	-- 악당이 틀림없어! 혼내주자!
	speech_bubble_util.show_speech_bubble_async(all_kids[2], { key = 'idols1_intro_12', skip = true })
	--]]

	bianca.Direction = CS.Oak.Direction.Down
	wait_for_sec(0.7)
	bianca.Direction = CS.Oak.Direction.Right

	character_util.set_anim(bianca, { name = 'cast', loop = true})
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02' })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_13', skip = true })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_14', skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	bianca:Shake(0.07, 10000)
	character_util.set_anim(bianca, { name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_15', skip = true })
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_15_2', skip = true })
	wait_for_sec(0.7)

	bianca:CancelShake()

	character_util.set_anim(bianca, { name = 'get', loop = false })
	camera_util.shake(0.1, 0.15)
	music_player_util.play_stage_music({state = 'muted', mix = 1.0})
	music_player:PlaySfxOneShot('01_linda_scream_01')
	music_player:PlaySfxOneShot('01_craft_hit_01')
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_intro_16', skip = true, bubble_type = 'shout' })

	camera_util.move(bianca.Position - vector(0, 0, 6), 1.0)
	screen_util.fade_out_async(1.0, unity_class.color.black)


	wait_for_sec(1.0)

	camera_util.move(hq + vector(0, 0, 6), 0)
	coroutine.yield(nil)

	local side_length = 2.0
	local vertical_length = side_length * 0.5 * unity_class.mathf.Sqrt(3.0)

	tinia.Position = hq + vector(side_length / 2.0, 0, vertical_length / 2.0)
	tinia.Direction = CS.Oak.Direction.Up

	eva.Position = hq + vector(-side_length / 2.0, 0, vertical_length / 2.0)
	eva.Direction = CS.Oak.Direction.Up

	cecil.Position = hq + vector(0, 0, -vertical_length / 2.0)
	cecil.Direction = CS.Oak.Direction.Up

	field:Tint('hq', unity_class.color(0.25, 0.25, 0.25), 0)

	camera_util.move(hq, 1.0)
	screen_util.fade_in_async(1.0, unity_class.color.black)


	speech_bubble_util.show_speech_bubble_async(tinia, { key = 'idols_start_1', skip = true })
	speech_bubble_util.show_speech_bubble_async(eva, { key = 'idols_start_2', skip = true })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	speech_bubble_util.show_speech_bubble_async(cecil, { key = 'idols_start_3', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_swing_01' })
	cecil.Direction = CS.Oak.Direction.Down

	wait_for_sec(0.5)

	tinia.Direction = CS.Oak.Direction.Down
	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01' })
	speech_bubble_util.show_speech_bubble_async(tinia, { key = 'idols_start_4', skip = true })
	eva.Direction = CS.Oak.Direction.Down
	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01' })
	speech_bubble_util.show_speech_bubble_async(eva, { key = 'idols_start_5', skip = true })

	character_util.set_anim(tinia, { name = 'get', loop = false })
	character_util.set_emotion(tinia, { name = 'attack', loop = false })
	character_util.set_anim(eva, { name = 'get', loop = false })
	character_util.set_emotion(eva, { name = 'attack', loop = false })
	character_util.set_anim(cecil, { name = 'get', loop = false })
	character_util.set_emotion(cecil, { name = 'attack', loop = false })

	camera_util.resize_to(2.5, 0.08)
	camera_util.shake(0.1, 0.15, true)
	music_player:PlaySfxOneShot('01_craft_hit_01')
	speech_bubble_util.show_speech_bubble_async(cecil, { key = 'idols_start_6', skip = true, auto_layout = true, bubble_type = 'shout', screen_pos = vector(-150, 300), bubble_direction = 'ct', type_speed = 0, scale = 1.5 })

	screen_util.fade_out_async(0.35, unity_class.color.black, 'linear')

	field:RemoveTint('hq', 0)

	character_util.remove_anim(tinia, false)
	character_util.remove_emotion(tinia)
	character_util.remove_anim(eva, false)
	character_util.remove_emotion(eva)
	character_util.remove_anim(cecil, false)
	character_util.remove_emotion(cecil)

	yield_return_func(self.start_game_routine, self, self.current_difficulty, false)
end

-- 리듬 게임 시작
function local_class:start_game_routine(difficulty, fade)
	if fade then
		music_player_util.play_stage_music( { state = 'muted', mix = 2 })
		screen_util.fade_out_async(0.5, unity_class.color.black)
	end
	field:RemoveTint('fail_tint', 0)
	camera_util.resize_to_default(0)

	self:npc_initialize()

	local bianca_hide = field:GetMarker('bianca_hide').position
	local room1 = field:GetMarker('room_1_center').position
	local room_final = field:GetMarker('room_final_center').position

	local bianca = get_character('stalker_bianca')
	bianca.Position = vector(room1.x, 0, room1.z)

	local knight = get_character('knight_female')
	knight.Position = room_final + vector(0, 0, -0.5)
	knight.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(knight, { name = 'attack', loop = false })

	local yuze = get_character('yuze')
	yuze.Position = room_final + vector(0, 0, 0.5)
	yuze.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(yuze, { name = 'attack', loop = false })

	camera_util.move(bianca.Position, 0)
	camera_util.resize_to(3.5, 0, true)

	self:npc_initialize()

	character_util.set_anim(bianca, { name = 'embarrassed' })
	character_util.set_direction(bianca, 'right')
	bianca.SpineController:ForceUpdateSpines(2.0)

	coroutine.yield(nil)

	message_system:Publish(CS.Oak.RhythmGameEvent.CreateStart('ondemand/v2_5_rhythm_game', 'idols1', difficulty, bianca,
			self.phase1_start, self.phase1_end, self.phase2_start, self.phase2_end, self.phase3_start, self.phase3_end, self.song_end))
end

function local_class:theatre()
	self.game_over = false
	self.game_ended = false
	self.section_ended = false
	yield_return_func(self.prologue, self)

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase1, self)
	end

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase1_ending, self)
	end

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase2, self)
	end

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase2_ending, self)
	end

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase3, self)
	end

	if not self.game_over then
		self.section_ended = false
		yield_return_func(self.phase3_ending, self)
	end

	if self.game_over then
		yield_return_func(self.game_over_routine, self)
	end
end

-- 프롤로그 (노래 시작 ~ 페이즈 1 시작 전)
function local_class:prologue()
	local bianca = get_character('stalker_bianca')
	local room1 = field:GetMarker('room_1_center').position
	local kids = self.get_phase1_kids()
	local all_kids = self.get_all_phase1_kids()
	local flag = { false, false, false }

	bianca.Position = room1
	character_util.set_anim(bianca, { name = 'embarrassed' })
	character_util.set_direction(bianca, 'right')

	--[[
	-- 꼬마들 활성화
	for i=1,#kids do
		character_util.set_active_state(kids[i], 'enabled')
		character_util.remove_anim_and_emotion(kids[i])
		character_util.look_at(kids[i].bianca)
	end
	--]]
	--[[
	for i = 1, #all_kids do
		character_util.remove_emotion(all_kids[i])
		if all_kids[i].Position.x < bianca.Position.x then
			character_util.set_direction(all_kids[i], 'right')
		else
			character_util.set_direction(all_kids[i], 'left')
		end
	end
	--]]

	camera_util.move(bianca.Position, 0)
	-- character_util.move_to(bianca, room1, self.phase1_start, nil, true, true)
	local elapsed_time = 0
	while not self.section_ended do
		local dt = unity_class.time.deltaTime

		--꼬마들 대사 추가
		elapsed_time = elapsed_time + dt
		if elapsed_time > 0.05 * self.phase1_start and not flag[1] then
			flag[1] = true
			music_player_util.play_sfx({ sfx_name = '01_kid_boy_shout_01' })
			-- 수상한 아줌마다!
			speech_bubble_util.show_speech_bubble(kids[1], { key = 'idols1_phase1_prologue_1', skip = false, type_speed = 0 })
		elseif elapsed_time > 0.35 * self.phase1_start and not flag[2] then
			flag[2] = true
			music_player_util.play_sfx({ sfx_name = '01_kid_girl_shout_01' })
			for i = 1, #all_kids do
				character_util.set_anim(all_kids[i], { name = 'hold_loop', scale = 0.3 })
				local rock_item_id = 20019
				local offset = direction_util.to_vector3(CS.Oak.DirectionExtensions.GetCWTurn(all_kids[i].Direction,1))
				if lua_helper.reference_equals(all_kids[i].Direction, CS.Oak.Direction.Left) or lua_helper.reference_equals(all_kids[i].Direction, CS.Oak.Direction.Right) then
					offset = direction_util.to_vector3(direction_util.get_opposite(all_kids[i].Direction))
				end
				self.temp_rocks[i] = drop_item_util.create_item(
						{ itemid = rock_item_id, notforinven = true, pos = all_kids[i].Position + vector(0, 0.3, 0) + 0.2 * offset,
						  lootstate = 'dontfindlooter', sprscale = 0.3, showoncharacter = true })
			end
			-- 돌을 던지자!
			speech_bubble_util.show_speech_bubble(kids[2], { key = 'idols1_phase1_prologue_2_1', skip = false, type_speed = 0 })
		elseif elapsed_time > 0.65 * self.phase1_start and not flag[3] then
			flag[3] = true
			character_util.set_anim(bianca, { name = 'dualsword_idle' })
			-- 질 수 없어…유즈를 위해!
			speech_bubble_util.show_speech_bubble(bianca, { key = 'idols1_phase1_prologue_3_1', skip = false, type_speed = 0 })
		end

		coroutine.yield(nil)
	end
end

-- 페이즈 1
function local_class:phase1()
	local bianca = get_character('stalker_bianca')
	character_util.remove_anim(bianca)

	-- character_util.set_anim(bianca, { name = 'run', loop = true })

	local duration = self.phase1_end - self.phase1_start

	local kids = self.get_phase1_kids()
	local all_kids = self.get_all_phase1_kids()
	--[[
	local start_pos = bianca.Position
	local end_pos = field:GetMarker('bridge_start').position
	local distance = (end_pos - start_pos).magnitude
	local dir = (end_pos - start_pos).normalized
	local speed = distance / duration

	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		bianca.Position = bianca.Position + dir * speed * dt
		coroutine.yield(nil)
	end
	--]]

	local init_pos = bianca.Position
	local wps ={
		2 * unity_class.vector3.forward + 1 * unity_class.vector3.left,
		2 * unity_class.vector3.left + 1 * unity_class.vector3.forward,
		2 * unity_class.vector3.left + 1 * unity_class.vector3.back,
		2 * unity_class.vector3.back + 1 * unity_class.vector3.left,
		2 * unity_class.vector3.back + 1 * unity_class.vector3.right,
		2 * unity_class.vector3.right + 1 * unity_class.vector3.back,
		2 * unity_class.vector3.right + 1 * unity_class.vector3.forward,
		2 * unity_class.vector3.forward + 1 * unity_class.vector3.right
	}

	local fx_1, fx_2 = nil

	local elapsed_time = 0
	local index = 0
	-- local dir = unity_class.vector3.right
	local interval = 0.1
	-- local flag = false
	self.throw_rock_stat = true
	-- coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.loop_rock_throw, self, kids, bianca, interval))

	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		elapsed_time = elapsed_time + dt

		for i = 1, #all_kids do
			character_util.look_at(all_kids[i], bianca)
		end

		if elapsed_time > duration - 0.8 then
			--텔레포트 연출
			interval = 0.03
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.loop_rock_throw, self, all_kids, bianca, interval))

			wait_for_sec(0.4)
			self.throw_rock_stat = false

			fx_1 = unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(bianca.Position)
			bianca.Position = vector(999,0,999)

			wait_for_sec(0.4)

			bianca.Position = init_pos
			bianca.Direction = CS.Oak.Direction.Right
			fx_2 = unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(bianca.Position)
			character_util.set_active_state(bianca, 'enabled')

			for i = 1, #all_kids do
				character_util.look_at(all_kids[i], bianca)
				character_util.set_emotion(all_kids[i], { name = 'surprise' })
			end
			camera_util.move(bianca.Position, 0, { end_target = bianca })

			character_util.set_anim(bianca, { name = 'victory_extra', loop = true })

			self.throw_rock_stat = false

			while not self.section_ended do
				coroutine.yield(nil)
			end

			break
		end

		if elapsed_time > index * 1.9 then
			if self.temp_rocks[(index%#all_kids)+1] ~= nil then
				self.temp_rocks[(index%#all_kids)+1].SpriteTransform.localPosition = vector(0,0,0)
				self.temp_rocks[(index%#all_kids)+1]:ConsumeComplete()
				self.temp_rocks[(index%#all_kids)+1] = nil
			end
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.random_wait_throw, self, all_kids[(index%#all_kids)+1], bianca))
			index = index + 1
			-- 점프
			character_util.remove_anim(bianca)
			music_player:PlaySfxOneShot('01_player_jump_01')
			bianca.Direction = (init_pos + wps[(index%#wps)+1] - bianca.Position):ToDirection()
			character_util.spine_rotate(bianca, 360, 0.8)
			character_util.set_anim(bianca, { name = 'jump', loop = false, scale = 0.5/0.8 })
			character_util.jump(bianca, 2, 0.8)
			character_util.move_to_async(bianca, init_pos + wps[(index%#wps)+1], 0.8, nil, false, false)
			character_util.spine_rotate(bianca, 0, 0)
			music_player_util.play_sfx({ sfx_name = '01_land_01' })
			character_util.set_anim(bianca, { name = 'boong_attack_ready', loop = false, next_anim = 'boong_attack_ready_loop' })
			elapsed_time = elapsed_time + 0.8
		end

		coroutine.yield(nil)
	end

	if fx_1 ~= nil then
		fx_1:Dispose()
	end
	if fx_2 ~= nil then
		fx_2:Dispose()
	end

	for i = 1, #all_kids do
		if self.temp_rocks[i] ~= nil then
			self.temp_rocks[i].SpriteTransform.localPosition = vector(0,0,0)
			self.temp_rocks[i]:ConsumeComplete()
			self.temp_rocks[i] = nil
		end
	end
end

-- 페이즈 1 엔딩
function local_class:phase1_ending()
	local bianca = get_character('stalker_bianca')
	local kids = self.get_phase1_kids()
	local all_kids = self.get_all_phase1_kids()

	character_util.set_direction(bianca, 'right')

	character_util.set_anim(bianca, { name = 'victory_extra', loop = true })

	-- 돌던지는 애니메이션 코루틴이랑 안겹치게
	coroutine.yield(nil)
	coroutine.yield(nil)
	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_03' })
	for i = 1, #all_kids do
		character_util.remove_emotion(all_kids[i])
		if all_kids[i].Position.x < bianca.Position.x then
			character_util.set_direction(all_kids[i], 'right')
		else
			character_util.set_direction(all_kids[i], 'left')
		end
		character_util.set_emotion(all_kids[i], { name = 'surprise' })
		-- all_kids[i].SpineController:ForceUpdateSpines(2.0)
	end

	---[[
	for i = 1, #kids do
		character_util.remove_anim_and_emotion(kids[i])
		character_util.look_at(kids[i],bianca)
		character_util.set_emotion(kids[i], { name = 'surprise' })
	end
	--]]

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01' })
	-- 대, 대단해...!
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = 'idols1_phase1_end_0', skip = false, type_speed = 0 })

	-- 이렇게 강한 언니가 나쁜 사람일리가 없어...!!
	speech_bubble_util.show_speech_bubble_async(kids[2], { key = 'idols1_phase1_end_0_1', skip = false, type_speed = 0 })

	character_util.remove_anim(bianca)

	for i=1,#all_kids do
		character_util.remove_emotion(all_kids[i])
		character_util.set_anim(all_kids[i], { name = 'victory_extra', loop = true })
	end
	character_util.set_anim(bianca, { name = 'run', loop = true })

	local elapsed_time = 0
	local duration = self.phase2_start - self.phase1_end - 7
	local end_pos = field:GetMarker('bridge_start').position
	local speed = (end_pos - bianca.Position).magnitude / duration
	local flag = false

	music_player_util.play_sfx({ sfx_name = '01_dash_01' })
	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		elapsed_time = elapsed_time + dt

		for i=1,#all_kids do
			character_util.look_at(all_kids[i], bianca)
		end

		if (bianca.Position - end_pos).magnitude < 18 and not flag then
			flag = true
			music_player_util.play_sfx({ sfx_name = '01_crowd_shout_03' })
			-- 힘내요 멋진 누나!
			speech_bubble_util.show_speech_bubble(kids[1], { key = 'idols1_phase1_end_1', skip = false, type_speed = 0, bubble_type = 'shout' })
		end

		if bianca.Position.x > end_pos.x - 0.2 then
			character_util.remove_anim(bianca)

			local center = field:GetMarker('lava1').position
			local bound = CS.UnityEngine.Bounds(center, vector(2, 3, 4))
			local lava_tiles = self:get_lava_tile_within_bound(bound)
			for _,lava in ipairs(lava_tiles) do
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.activate_lava, self, lava))
			end

			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })
			-- 함정이...!
			speech_bubble_util.show_speech_bubble(bianca, { key = 'idols1_phase1_end_2', skip = false, type_speed = 0 })

			while not self.section_ended do
				coroutine.yield(nil)
			end
			break
		end

		bianca.Position = bianca.Position + unity_class.vector3.right * speed * dt

		coroutine.yield(nil)
	end
end

-- 페이즈 2
function local_class:phase2()
	local bianca = get_character('stalker_bianca')
	character_util.set_anim(bianca, { name = 'run', loop = true })

	local duration = self.phase2_end - self.phase2_start - 7 * 1

	local start_pos = bianca.Position
	local end_pos = field:GetMarker('bridge_end').position
	local distance = (end_pos - start_pos).magnitude - 28
	local dir = (end_pos - start_pos).normalized
	local speed = distance / duration

	local jump_index = 0
	local elapsed_time = 0

	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		elapsed_time = elapsed_time + dt

		if (bianca.Position - start_pos).magnitude > jump_index * 10 + 0.2 and jump_index < 7 then
			jump_index = jump_index + 1
			local center = field:GetMarker('lava'..(jump_index)).position
			local bound = CS.UnityEngine.Bounds(center, vector(2, 3, 4))
			local lava_tiles = self:get_lava_tile_within_bound(bound)

			if self.section_ended then break end

			for _,lava in ipairs(lava_tiles) do
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.activate_lava, self, lava))
			end

			if self.section_ended then break end

			character_util.remove_anim(bianca)
			music_player:PlaySfxOneShot('01_player_jump_01')
			bianca.LockedDirection = bianca.Direction
			character_util.spine_rotate(bianca, 720, 1)
			character_util.jump(bianca, 4, 1)

			if self.section_ended then break end

			character_util.move_to_async(bianca, bianca.Position + 4 * unity_class.vector3.right, 1, nil, false, false)

			if self.section_ended then break end

			character_util.spine_rotate(bianca, 0, 0)
			character_util.set_locked_dir(bianca, 'none')
			character_util.remove_anim(bianca)
			character_util.set_anim(bianca, { name = 'run', loop = true })

			if jump_index < 7 then
				center = field:GetMarker('lava'..(jump_index+1)).position
				bound = CS.UnityEngine.Bounds(center, vector(2, 3, 4))
				lava_tiles = self:get_lava_tile_within_bound(bound)

				for _,lava in ipairs(lava_tiles) do
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.deactivate_lava, self, lava))
				end
			end
		else
			bianca.Position = bianca.Position + dir * speed * dt
		end
		coroutine.yield(nil)
	end
end

-- 페이즈 2 엔딩
function local_class:phase2_ending()
	local bianca = get_character('stalker_bianca')

	character_util.remove_anim_and_emotion(bianca)
	character_util.normal_jump(bianca)

	local elapsed_time = 0
	local duration = self.phase3_start - self.phase2_end - 8
	local end_pos = field:GetMarker('room_final_center').position
	local speed = (end_pos - bianca.Position).magnitude / duration

	local knight = get_character('knight_female')
	local yuze = get_character('yuze')
	local monsters = self.get_phase3_monsters()

	local knight_weapon_name = 'cwp_knight'
	local yuze_weapon_name = 'cwp_succubus'

	knight.SpineController:SetAttachment('[base]weapon1', knight_weapon_name)
	yuze.SpineController:SetAttachment('[base]weapon1', yuze_weapon_name)

	character_util.set_emotion(knight, { name = 'attack' })
	character_util.set_emotion(yuze, { name = 'attack' })

	character_util.set_position(knight, knight.Position + 1 * unity_class.vector3.back, nil, 3, true, true)
	character_util.set_position(yuze, yuze.Position + 1 * unity_class.vector3.forward, nil, 3, true, true)

	character_util.set_direction(knight, 'down')
	character_util.set_direction(yuze, 'up')

	character_util.set_emotion(knight, { name = 'attack' })
	character_util.set_emotion(yuze, { name = 'attack' })

	local a_list = create_generic_list(CS.Oak.Character)
	local a_list_foe = create_generic_list(CS.Oak.Character)

	-- 유즈와 기사가 동시에 공격
	for i = 1, #monsters do
		a_list:Add((i%2 == 1) and yuze or knight)
		a_list_foe:Add(monsters[(i%2 == 1) and (math.floor(i/2)+1) or (#monsters - (math.floor(i/2)-1))])
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.battle_template_defense_list, self, 'init_battle', a_list_foe, a_list))


	wait_for_sec(2)

	music_player_util.play_sfx({ sfx_name = '02_die_hulk_01' })
	music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', parent = knight })
	camera_util.move_async(end_pos, 1)

	wait_for_sec(1)

	camera_util.move_async(bianca.Position, 1, { end_target = bianca })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	-- 기다려, 도와줄께!
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_phase2_end_2', skip = false, type_speed = 0 })

	music_player_util.play_sfx({ sfx_name = '01_dash_01' })
	character_util.set_anim(bianca, { name = 'run' })
	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		elapsed_time = elapsed_time + dt

		if (bianca.Position - end_pos).magnitude < 1.5 then
			self:stop_battle('init_battle')

			coroutine.yield(nil)

			self.is_battle_dict:Remove('init_battle')

			character_util.remove_anim(bianca)
			music_player:PlaySfxOneShot('01_player_jump_01')
			bianca.LockedDirection = bianca.Direction
			character_util.spine_rotate(bianca, 720, 0.5)
			character_util.jump(bianca, 3, 0.5)
			character_util.move_to_async(bianca, bianca.Position + 2.5 * unity_class.vector3.right, 0.5, nil, false, false)
			character_util.spine_rotate(bianca, 0, 0)
			character_util.set_locked_dir(bianca, 'none')
			character_util.set_direction(bianca, 'right')
			character_util.remove_anim(bianca)

			local weapon_name = 'cwp_succubusnoble'

			bianca.SpineController:SetAttachment('[base]weapon1', weapon_name)

			character_util.set_anim(bianca, { name = 'twohand_idle' })

			while not self.section_ended do
				coroutine.yield(nil)
			end

			break
		end

		bianca.Position = bianca.Position + unity_class.vector3.right * speed * dt

		coroutine.yield(nil)
	end
end

-- 페이즈 3
function local_class:phase3()
	local bianca = get_character('stalker_bianca')
	local knight = get_character('knight_female')
	local yuze = get_character('yuze')

	local monsters = self.get_phase3_monsters()

	local duration = self.phase3_end - self.phase3_start

	local start_pos = bianca.Position
	local end_pos = field:GetMarker('room_final_center').position
	local distance = (end_pos - start_pos).magnitude


	local weapon_name = 'cwp_succubusnoble'
	local knight_weapon_name = 'cwp_knight'
	local yuze_weapon_name = 'cwp_succubus'

	bianca.SpineController:SetAttachment('[base]weapon1', weapon_name)

	knight.SpineController:SetAttachment('[base]weapon1', knight_weapon_name)

	yuze.SpineController:SetAttachment('[base]weapon1', yuze_weapon_name)

	local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = tmp
	damage_info.notMortal = false

	-- character_util.move_to(knight, knight.Position + 1 * unity_class.vector3.back, nil, 3, true, true)
	-- character_util.move_to_async(yuze, yuze.Position + 1 * unity_class.vector3.forward, nil, 3, true, true)

	character_util.set_direction(knight, 'down')
	character_util.set_direction(yuze, 'up')

	character_util.set_emotion(knight, { name = 'attack' })
	character_util.set_anim(knight, { name = 'twohand_idle' })
	character_util.set_emotion(yuze, { name = 'attack' })
	character_util.set_anim(yuze, { name = 'twohand_idle' })

	local bianca_list = create_generic_list(CS.Oak.Character)
	local bianca_list_foe = create_generic_list(CS.Oak.Character)

	-- 유즈 -> 비앙카 -> 기사
	for i = 1, (#monsters-2) * 3 do
		bianca_list:Add((i%3 == 1) and yuze or ((i%3 == 0) and knight or bianca))
		bianca_list_foe:Add(monsters[(i%3 == 1) and 1 or ((i%3 == 0) and #monsters or (math.floor(i/3)%(#monsters - 2) + 2))])
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.battle_template_defense_list, self, 'bianca_battle', bianca_list_foe, bianca_list))

	local elapsed_time = 0
	while not self.section_ended do
		local dt = unity_class.time.deltaTime
		elapsed_time = elapsed_time + dt
		if elapsed_time > duration - 1 then
			self:stop_battle('bianca_battle')

			-- 배틀 애니메이션 코루틴이랑 안겹치게
			coroutine.yield(nil)
			self.is_battle_dict:Remove('bianca_battle')

			coroutine.yield(nil)

			character_util.remove_anim(bianca)

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.bianca_super_attack, self))

			wait_for_sec(1.2667)

			for i =1, #monsters do
				music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01' })
				character_util.air_spin(monsters[i], { offset = 3 * direction_util.to_vector3(direction_util.get_opposite(monsters[i].Direction)) })
			end

			while not self.section_ended do
				coroutine.yield(nil)
			end
			break
		end
		coroutine.yield(nil)
	end

	self:stop_battle('bianca_battle')

	coroutine.yield(nil)

	self.is_battle_dict:Remove('bianca_battle')
	-- character_util.set_anim(bianca, { name = 'success', loop = true })
end

-- 페이즈 3 엔딩
function local_class:phase3_ending()
	local bianca = get_character('stalker_bianca')
	local yuze = get_character('yuze')
	local knight = get_character('knight_female')

	wait_for_sec(2.5)

	character_util.set_direction(bianca, 'left')
	character_util.remove_anim_and_emotion(bianca)

	character_util.set_direction(yuze, 'right')
	character_util.remove_anim_and_emotion(yuze)

	character_util.set_direction(knight, 'right')
	character_util.remove_anim_and_emotion(knight)

	character_util.move_to_async(yuze, bianca.Position + 1 * unity_class.vector3.left, 1, nil, true, true)

	character_util.look_at(yuze, bianca)
	character_util.set_anim(yuze, { name = 'question', loop = false })
	music_player_util.play_sfx({ sfx_name = '01_rustle_01' })
	-- …비앙카?
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_1_new', skip = false, type_speed = 0 })

	character_util.remove_anim_and_emotion(yuze)

	character_util.show_emoticon_async(bianca, unity_class.vector3.one, 'notice')

	-- 비앙카, 맞지…??
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_2_new', skip = false, type_speed = 0 })

	character_util.set_anim(bianca, { name = 'embarrassed' })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })
	-- 아, 아니, 그게…
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_phase3_end_2_new_1', skip = false, type_speed = 0 })

	music_player_util.play_stage_music( { state = 'muted', mix = 1.5 })

	-- 너…정말…
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_3_new', skip = false, type_speed = 0 })

	character_util.set_emotion(knight, { name = 'smile' })
	character_util.set_anim_and_emotion(yuze, { name = 'push' }, { name = 'awesome' } )
	music_player:PlayStageMusic('theatres/steampunk_rhythm_minigame:bgm_rhythmic_05', CS.Oak.StageBgmState.Event, 0.5, 0)
	character_util.move_to_async(yuze, bianca.Position + 0.4 * unity_class.vector3.left, 0.2, nil, false, false)
	-- music_player_util.play_stage_music( { name = 'bgm_heroic_moment', state = 'event', mix = 2 })
	-- music_player:PlayStageMusic('bgm_heroic_moment', CS.Oak.StageBgmState.Event, 2, 1)


	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01' })

	-- 좋은 애구나!!
	speech_bubble_util.show_speech_bubble(yuze, { key = 'idols1_phase3_end_4_new', skip = false, type_speed = 0 })
	wait_for_sec(1)
	music_player_util.play_stage_music( { name = 'bgm_heroic_moment', state = 'event', mix = 1 })
	wait_for_sec(1)

	-- music_player_util.play_stage_music( { name = 'bgm_heroic_moment', state = 'event', mix = 2 })

	character_util.remove_anim_and_emotion(bianca)

	-- 이런 던전 깊숙히까지 우리를 구해주러 오다니…
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_5_new', skip = false, type_speed = 0 })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	-- 너같은 친구는 없을거야!!
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_6_new', skip = false, type_speed = 0 })

	character_util.set_emotion(bianca, { name = 'blush' })
	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01' })
	character_util.show_emoticon_async(bianca, unity_class.vector3.one, 'heart')

	character_util.set_direction(bianca, 'down')
	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01' })
	-- 고마워…
	speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_phase3_end_7_new', skip = false, type_speed = 0 })

	character_util.set_anim(bianca, { name = 'get', loop = false })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	-- 어딘가에서 들려온 이름 모를 노래!
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_phase3_end_8_new', skip = false, type_speed = 0, bubble_type = 'shout' })

	local tinia = get_character('idols_member_tinia')
	local eva = get_character('idols_member_eva')
	local cecil = get_character('idols_member_cecil')

	screen_util.fade_out_async(1.0, unity_class.color.black)
	music_player_util.play_stage_music( { state = 'muted', mix = 2 })
	-- music_player_util.play_stage_music( { name = 'theatres/steampunk_rhythm_minigame:bgm_rhythmic_05', state = 'event', mix = 2 })

	wait_for_sec(1.0)
	local hq = field:GetMarker('hq_start').position + vector(0, 0, 1)

	camera_util.move(hq + vector(0, 0, 6), 0)
	coroutine.yield(nil)

	local side_length = 2.0
	local vertical_length = side_length * 0.5 * unity_class.mathf.Sqrt(3.0)

	tinia.Position = hq + vector(side_length / 2.0, 0, vertical_length / 2.0)
	tinia.Direction = CS.Oak.Direction.Up

	eva.Position = hq + vector(-side_length / 2.0, 0, vertical_length / 2.0)
	eva.Direction = CS.Oak.Direction.Up

	cecil.Position = hq + vector(0, 0, -vertical_length / 2.0)
	cecil.Direction = CS.Oak.Direction.Up

	field:Tint('hq', unity_class.color(0.25, 0.25, 0.25), 0)

	camera_util.move(hq, 1.0)
	screen_util.fade_in_async(1.0, unity_class.color.black)

	-- 미션…
	speech_bubble_util.show_speech_bubble_async(cecil, { key = 'idols1_phase3_end_9_new', skip = false, type_speed = 0 })

	cecil.Direction = CS.Oak.Direction.Down
	tinia.Direction = CS.Oak.Direction.Down
	eva.Direction = CS.Oak.Direction.Down

	character_util.set_anim(tinia, { name = 'get', loop = false })
	character_util.set_emotion(tinia, { name = 'attack', loop = false })
	character_util.set_anim(eva, { name = 'get', loop = false })
	character_util.set_emotion(eva, { name = 'attack', loop = false })
	character_util.set_anim(cecil, { name = 'get', loop = false })
	character_util.set_emotion(cecil, { name = 'attack', loop = false })

	camera_util.resize_to(2.5, 0.08)
	camera_util.shake(0.1, 0.15, true)
	music_player:PlaySfxOneShot('01_craft_hit_01')
	-- 대~! 성~! 공~!!
	speech_bubble_util.show_speech_bubble_async(cecil, { key = 'idols1_phase3_end_10_new', skip = false, type_speed = 0 , auto_layout = true, bubble_type = 'shout', screen_pos = vector(-150, 300), bubble_direction = 'ct', type_speed = 0, scale = 1.5 })

	screen_util.fade_out_async(0.35, unity_class.color.black, 'linear')

	field:RemoveTint('hq', 0)

	character_util.remove_anim(tinia, false)
	character_util.remove_emotion(tinia)
	character_util.remove_anim(eva, false)
	character_util.remove_emotion(eva)
	character_util.remove_anim(cecil, false)
	character_util.remove_emotion(cecil)

	while not self.game_ended do
		coroutine.yield(nil)
	end

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
	yield_return_func(self.hq_scene, self, true, self.full_combo)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.RhythmGameEvent) then
		if e.Type == CS.Oak.RhythmGameEventType.End then
			self.full_combo = e.IsFullCombo
			self.game_ended = true
		elseif e.Type == CS.Oak.RhythmGameEventType.GameOver then
			self.section_ended = true
			self.game_over = true
		elseif e.Type == CS.Oak.RhythmGameEventType.Restart then
			if e.Phase == 99 then
				-- HACK
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hq_scene, self, false, false, true))
			else
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.restart_routine, self))
			end
		elseif e.Type == CS.Oak.RhythmGameEventType.PhaseStart then
			if e.Phase == 0 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.theatre, self))
			else
				self.section_ended = true
			end
		elseif e.Type == CS.Oak.RhythmGameEventType.PhaseEnd then
			self.section_ended = true
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object('computer')) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.computer_routine, self))
		end
	end

	return false
end

-- 게임 오버 당했을 때
function local_class:game_over_routine()
	local bianca = get_character('stalker_bianca')
	local yuze = get_character('yuze')
	local knight = get_character('knight_female')
	local monsters = self.get_phase3_monsters()

	music_player_util.play_sfx({ sfx_name = '01_drown_02' })
	music_player_util.play_sfx({ sfx_name = '01_fade_out_01' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')
	for _,v in ipairs(monsters) do
		v.ActiveState = CS.Oak.ActiveState.Disabled
	end
	local final_pos = field:GetMarker('room_final_center').position
	bianca.Position = final_pos
	character_util.set_direction(bianca, 'right')
	yuze.Position = bianca.Position + 2 * unity_class.vector3.right + 1 * unity_class.vector3.forward
	knight.Position = bianca.Position + 2 * unity_class.vector3.right + 1 * unity_class.vector3.back

	character_util.set_direction(yuze, 'left')
	character_util.set_direction(knight, 'left')
	character_util.remove_anim_and_emotion(yuze)
	character_util.remove_anim_and_emotion(knight)

	if self.first then
		self.first = false
		character_util.set_anim(bianca, { name = 'idle' })

		wait_for_sec(1.0)
		camera_util.move(bianca.Position, 0, { end_target = bianca })

		bianca.SpineController:ForceUpdateSpines(2.0)
		music_player_util.play_stage_music( { name = 'bgm_trickery_theme', state = 'event', mix = 2 })
		screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

		wait_for_sec(0.5)

		character_util.move_to_async(yuze, bianca.Position + 1 * unity_class.vector3.right, nil, 3, true, true)
		character_util.look_at(yuze, bianca)
		character_util.set_emotion(yuze, { name = 'tired' })

		-- …비, 비앙카…?
		speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_game_over_1', skip = false, type_speed = 0 })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02' })
		-- 설마 우리를 미행한거야…?
		speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_game_over_2', skip = false, type_speed = 0 })

		music_player_util.play_sfx({ sfx_name = '03_runaway_01' })
		character_util.set_anim(bianca, { name = 'embarrassed' })

		-- 뭐야 그거…
		speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_game_over_3', skip = false, type_speed = 0 })

		character_util.set_emotion(knight, { name = 'doyagao' })

		character_util.set_locked_dir(yuze, 'left')
		character_util.set_emotion(yuze, { name = 'scared' })
		music_player_util.play_sfx({ sfx_name = '01_rustle_01' })
		character_util.move_to_async(yuze, yuze.Position + 1 * unity_class.vector3.right, nil, 2, false, true)

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })
		-- 무서워……!!
		speech_bubble_util.show_speech_bubble_async(yuze, { key = 'idols1_game_over_4', skip = false, type_speed = 0 })

		music_player_util.play_sfx({ sfx_name = '03_runaway_01' })
		-- N…N……
		speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_game_over_5', skip = false, type_speed = 0 })

		character_util.set_anim(bianca, { name = 'frustration', loop = false})
		field:Tint('fail_tint', unity_class.color(0.3, 0.3, 0.3), 0)
		camera_util.resize_to(2.5, 0.15)
		camera_util.shake(0.1, 0.15, true)
		music_player_util.play_sfx({ sfx_name = '02_hit_critical_01' })
		music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_02' })
		-- NOOOOOOOOOOOOOOOOOOOOOOOO!!
		speech_bubble_util.show_speech_bubble_async(bianca, { key = 'idols1_game_over_6', skip = false, type_speed = 0, bubble_type = 'shout' })
	else
		field:Tint('fail_tint', unity_class.color(0.3, 0.3, 0.3), 0)
		camera_util.resize_to(2.5, 0.15)

		character_util.set_direction(bianca, 'right')
		character_util.set_anim(bianca, { name = 'frustration', loop = false })
		wait_for_sec(1.0)
		camera_util.move(bianca.Position, 0, { end_target = bianca })

		bianca.SpineController:ForceUpdateSpines(2.0)
		music_player_util.play_stage_music( { name = 'bgm_trickery_theme', state = 'event', mix = 2 })
		screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')
	end
	character_util.set_locked_dir(yuze, 'none')
	message_system:Publish(CS.Oak.RhythmGameEvent.CreateGameOverEnd())
end

-- npc들 위치/방향/표정/애니메이션 초기화
function local_class:npc_initialize()
	local bianca = get_character('stalker_bianca')
	local kids = self.get_all_phase1_kids()
	local monsters = self.get_phase3_monsters()
	local yuze = get_character('yuze')
	local knight = get_character('knight_female')
	local room1 = field:GetMarker('room_1_center').position

	bianca.Position = room1
	character_util.set_direction(bianca, 'right')
	-- 꼬마들 초기화
	for i=1,#kids do
		character_util.set_active_state(kids[i], 'enabled')
		kids[i].Position = self.kid_start_pos[i]
		character_util.remove_anim_and_emotion(kids[i])
		character_util.look_at(kids[i], bianca)
	end

	-- 몬스터들 초기화
	local dir = CS.Oak.Direction.Down
	for i=1,#monsters do
		-- character_util.convert_to_npc(monsters[i])
		monsters[i].Position = self.monsters_start_pos[i]
		character_util.remove_anim_and_emotion(monsters[i])

		if monsters[i].FieldObjectStatsBehaviour.HP ~= monsters[i].FieldObjectStatsBehaviour.MaxHP then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = monsters[i]
			heal_info.target = monsters[i]
			heal_info.isRevive = true
			heal_info.heal = monsters[i].FieldObjectStatsBehaviour.MaxHP
			command_util.execute_heal(heal_info)
		end

		if i > 4 then
			character_util.look_at(monsters[i], knight)
		else
			character_util.look_at(monsters[i], yuze)
		end
		character_util.spine_rotate(monsters[i], 0, 0)

		character_util.set_active_state(monsters[i], 'enabled')
	end



	character_util.remove_anim_and_emotion(yuze)
	yuze.SpineController:SetAttachment('[base]weapon1', 'empty')

	character_util.remove_anim_and_emotion(knight)
	knight.SpineController:SetAttachment('[base]weapon1', 'empty')

	character_util.remove_anim_and_emotion(bianca)
	bianca.SpineController:SetAttachment('[base]weapon1', 'empty')

	character_util.set_direction(bianca, 'none')
end

-- 재도전 처리
function local_class:restart_routine()
	self:npc_initialize()

	music_player_util.play_stage_music( { state = 'muted', mix = 2 })

	yield_return_func(self.start_game_routine, self, self.current_difficulty, false)
end

function local_class:computer_routine()
	character_util.align_party(get_field_object('computer'), 'down')

	local normal_cleared = get_field_object('normal_real_door').FieldObjectBehaviour.IsOpen

	if self.computer_branches == nil then
		self.computer_branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	end
	self.computer_branches:Clear()

	local branches = self.computer_branches
	local wait_for_branch = true
	local choice = 0
	branches:Add({
		-- 노멀
		Text = game_string:GetString('rhythm_game_play_normal'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	if normal_cleared then
		branches:Add({
			-- 하드
			Text = game_string:GetString('rhythm_game_play_hard'),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				wait_for_branch = false
				choice = 2
			end
		})
	end
	branches:Add({
		-- 캔슬
		Text = game_string:GetString('rhythm_game_cancel'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 3
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = user_party[0]

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 1 or choice == 2 then
		if choice == 1 then
			self.current_difficulty = 'normal'
		else
			self.current_difficulty = 'hard'
		end
		yield_return_func(self.start_game_routine, self, self.current_difficulty, true)
	else
		user_party:ResetControllers()
	end
end

-- 본부 셋업
function local_class:hq_scene(cleared, cleared_full_combo, from_retry)
	local normal_cleared = get_field_object('normal_real_door').FieldObjectBehaviour.IsOpen
	local normal_perfected = get_field_object('normal_perfect_real_door').FieldObjectBehaviour.IsOpen
	local hard_cleared = get_field_object('hard_real_door').FieldObjectBehaviour.IsOpen
	local hard_perfected = get_field_object('hard_perfect_real_door').FieldObjectBehaviour.IsOpen

	if normal_cleared then
		get_field_object('normal_door_1').ActiveState = CS.Oak.ActiveState.Disabled
		get_field_object('normal_door_2').ActiveState = CS.Oak.ActiveState.Disabled
	end

	if normal_perfected then
		get_field_object('normal_perfect_door_1').ActiveState = CS.Oak.ActiveState.Disabled
		get_field_object('normal_perfect_door_2').ActiveState = CS.Oak.ActiveState.Disabled
	end

	if hard_cleared then
		get_field_object('hard_door_1').ActiveState = CS.Oak.ActiveState.Disabled
		get_field_object('hard_door_2').ActiveState = CS.Oak.ActiveState.Disabled
	end

	if hard_perfected then
		get_field_object('hard_perfect_door_1').ActiveState = CS.Oak.ActiveState.Disabled
		get_field_object('hard_perfect_door_2').ActiveState = CS.Oak.ActiveState.Disabled
	end

	if cleared then
		if self.current_difficulty == 'normal' then
			message_system:Publish(CS.Oak.DoorOpenEvent.Create('normal_real_door', true))
			if cleared_full_combo then
				message_system:Publish(CS.Oak.DoorOpenEvent.Create('normal_perfect_real_door', true))
			end
		else
			message_system:Publish(CS.Oak.DoorOpenEvent.Create('hard_real_door', true))
			if cleared_full_combo then
				message_system:Publish(CS.Oak.DoorOpenEvent.Create('hard_perfect_real_door', true))
			end
		end
	end

	local computer = get_field_object('computer')

	local hq_start  = field:GetMarker('hq_start').position
	user_party[0].Position = hq_start
	user_party[0].Direction = CS.Oak.Direction.Up

	local tinia = get_character('idols_member_tinia')
	tinia.Position = computer.Position + vector(1.5, 0, 0)
	tinia.Direction = CS.Oak.Direction.Down

	local eva = get_character('idols_member_eva')
	eva.Position = computer.Position + vector(-1.5, 0, 0)
	eva.Direction = CS.Oak.Direction.Down

	camera_util.resize_to_default(0)

	music_player_util.play_stage_music( { name = 'theatres/steampunk_rhythm_minigame:bgm_rhythmic_05', state = 'event', mix = 2 })

	if cleared then
		camera_util.move(computer.Position, 0)
		screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

		local computer_key = nil
		if self.current_difficulty == 'normal' then
			if cleared_full_combo then
				computer_key = 'rhythm_game_normal_perfect_clear'
			else
				computer_key = 'rhythm_game_normal_clear'
			end
		else
			if cleared_full_combo then
				computer_key = 'rhythm_game_hard_perfect_clear'
			else
				computer_key = 'rhythm_game_hard_clear'
			end
		end

		speech_bubble_util.show_speech_bubble_async(computer, { key = computer_key, skip = true })

		-- 문 부숴지는 연출
		local camera_moved = false
		if self.current_difficulty == 'normal' then
			if not normal_cleared then
				yield_return_func(self.unlock_door, self, self.current_difficulty, false)
				camera_moved = true
			end

			if not normal_perfected and cleared_full_combo then
				yield_return_func(self.unlock_door, self, self.current_difficulty, true)
				camera_moved = true
			end
		else
			if not hard_cleared then
				yield_return_func(self.unlock_door, self, self.current_difficulty, false)
				camera_moved = true
			end

			if not hard_perfected and cleared_full_combo then
				yield_return_func(self.unlock_door, self, self.current_difficulty, true)
				camera_moved = true
			end
		end

		local back_duration = 1.0
		if camera_moved then
			back_duration = 1.5
		end

		camera_util.move(user_party[0].Position, back_duration, { end_target = user_party[0] })
		wait_for_sec(back_duration)

		field_ui_manager:Show()
		user_party:ResetControllers()
	else
		if from_retry then
			wait_for_sec(0.5)
		end

		field:RemoveTint('fail_tint', 0)

		camera_util.move(user_party[0].Position, 0, { end_target = user_party[0] })
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'ease_in_out_sine')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(
				hq_start, CS.Oak.Direction.Up, game_string:GetString('rhythm_game_hq'), true))

		if from_retry then
			field_ui_manager:Show()
			user_party:ResetControllers()
		end
	end
end

-- 본부 문 열리는 연출
function local_class:unlock_door(difficulty, full_combo)
	local d1_name = nil
	local d2_name = nil

	if difficulty == 'normal' then
		if full_combo then
			d1_name = 'normal_perfect_door_1'
			d2_name = 'normal_perfect_door_2'
		else
			d1_name = 'normal_door_1'
			d2_name = 'normal_door_2'
		end
	else
		if full_combo then
			d1_name = 'hard_perfect_door_1'
			d2_name = 'hard_perfect_door_2'
		else
			d1_name = 'hard_door_1'
			d2_name = 'hard_door_2'
		end
	end

	local d1 = get_field_object(d1_name)
	local d2 = get_field_object(d2_name)

	local pos = (d1.Position + d2.Position) / 2.0

	camera_util.move(pos, 1.5)

	wait_for_sec(1.5)

	music_player:PlaySfxOneShot('02_explosion_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(d1.Position)
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(d2.Position)
	d1.ActiveState = CS.Oak.ActiveState.Disabled
	d2.ActiveState = CS.Oak.ActiveState.Disabled

	wait_for_sec(0.75)
end

-- 돌 던지는 코루틴 (CafeMainSection19.lua:134-190 참조)
function local_class:throw_rock_to_target(thrower, target)
	music_player:PlaySfxOneShot('01_swing_01')
	character_util.look_at(thrower, target)
	character_util.set_anim(thrower, { name = 'attack', loop = false })
	local rock_item_id = 20019
	local rock = drop_item_util.create_item(
			{ itemid = rock_item_id, notforinven = true, pos = thrower.Position + vector(0, 0, 0.5),
			  target = target.Position, lootstate = 'dontfindlooter', sprscale = 0.3, showoncharacter = true })

	wait_for_sec(0.5)

	character_util.remove_anim(thrower)

	wait_for_sec(0.5)
	rock.SpriteTransform.localPosition = vector(0,0,0)
	rock:ConsumeComplete()
end

function local_class:loop_rock_throw(fo, target, interval)
	while self.throw_rock_stat do
		for i = 1, #fo do
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.random_wait_throw, self, fo[i], target))
			wait_for_sec(interval)
		end
		-- wait_for_sec(interval)
	end
end

function local_class:random_wait_throw(fo, target)
	if not self.throw_rock_stat then return end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.throw_rock_to_target, self, fo, target))
end

-- 전투 연출 부분
-- FutureCastleMainPartA.lua 참조
-- 해당하는 키의 전투 연출 시작
function local_class:play_battle(key)
	if not self.is_battle_dict:ContainsKey(key) then
		self.is_battle_dict:Add(key, true)
	else
		-- 중복 키 오류 검출
		CS.UnityEngine.Debug.LogError('Battle Dictionary already has same key')
		CS.UnityEngine.Debug.LogError(key)
	end
end

-- 해당하는 키의 전투 연출 중단
function local_class:stop_battle(key)
	if self.is_battle_dict:ContainsKey(key) then
		self.is_battle_dict:Remove(key)
		self.is_battle_dict:Add(key, false)
	end
end

-- 1대1 전투 연출 (A가 B를 때리고 B가 공격으로 그걸 막는걸 반복)
function local_class:battle_template_attack_repeat(key, char_1, char_2)
	self:play_battle(key)

	while CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) do
		coroutine.yield(self:attack_normal(key, char_1, char_2))

		-- coroutine.yield(self:attack_normal(key, char_2, char_1))
	end
end

-- 공격 연출 (A가 B를 때리고 B가 공격으로 그걸 막음)
function local_class:attack_normal(key, char_1, char_2, no_anim)
	local no_anim_val = lua_helper.get_or_default(no_anim, false)

	local dir = (char_2.Position - char_1.Position).normalized

	local cur_time = unity_class.time.time
	local duration = 0.3

	--[[
	while unity_class.time.time - cur_time < duration/2 do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end
	--]]
	if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
		return
	end

	character_util.set_direction(char_2, direction_util.get_opposite(char_1.Direction))
	if char_2.Name == 'knight' then
		character_util.set_anim(char_2, { name = 'sword_attack', loop = false })
	else
		character_util.set_anim(char_2, { name = 'twohand_attack', loop = false })
		if char_2.Name == 'stalker_bianca' then
			music_player_util.play_sfx({ sfx_name = '02_onehand_slash_02', parent = char_2 })
		end
	end

	while unity_class.time.time - cur_time < duration/2 do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end

	character_util.spine_deviate_local(char_1, dir, 0.3, 0.2)
	character_util.set_anim(char_1, { name = 'attack', loop = false })

	while unity_class.time.time - cur_time < duration/2 do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end

	duration = 0.4
	while unity_class.time.time - cur_time < duration do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', parent = char_1, type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(char_2.Position - dir + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(char_2.Position - dir + vector(0, 0.3, 0))

	character_util.spine_pulse_color(char_1, CS.Oak.Constants.DamageColor, 1, 1, 1)
	character_util.spine_damage_squish(char_1, 1.3, 0.7, 1, 0.3)
	character_util.spine_deviate_local(char_1, dir * -0.5, 0.3, 0.2)

	if not no_anim_val then
		character_util.set_anim(char_1, { name = 'damaged' })
		character_util.set_emotion(char_1, { name = 'damaged' })
	end

	cur_time = unity_class.time.time
	duration = 0.1

	while unity_class.time.time - cur_time < duration do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end

	-- character_util.remove_anim(char_1)
	---[[
	if char_2.Name == 'knight' then
		character_util.set_anim(char_2, { name = 'sword_idle' })
	else
		character_util.set_anim(char_2, { name = 'twohand_idle' })
	end
	--]]

	cur_time = unity_class.time.time
	duration = 0.3

	while unity_class.time.time - cur_time < duration do
		if not CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) then
			return
		end

		coroutine.yield(nil)
	end

	if not no_anim_val then
		character_util.remove_anim(char_1)
		character_util.set_emotion(char_1, { name = 'attack' })
	end
end

-- n대n 전투 연출 리스트 처리 (한 쪽은 일반 공격을 하고 다른 쪽이 계속 막고 있음)
function local_class:battle_template_defense_list(key, char_1_list, char_2_list)
	self:play_battle(key)

	while CS.Utils.GetBoolFromDictionary(self.is_battle_dict, key) do
		coroutine.yield(self:attack_and_defense_list(key, char_1_list, char_2_list))
	end
	--[[
	for i=0,char_2_list.Count-1 do
		if char_2_list.Name == 'stalker_bianca' then
			character_util.set_anim_and_emotion(char_2_list[i], { name = 'twohand_attack3', loop = false }, { name = 'idle' })
		else
			character_util.set_anim_and_emotion(char_2_list[i], { name = 'twohand_idle'}, { name = 'idle' })
		end
	end
	--]]
end

-- 공격 연출 리스트 처리 (A 그룹이 차례대로 B 그룹을 때리고 B 그룹은 공격을 방어함)
function local_class:attack_and_defense_list(key, char_1_list, char_2_list)
	for i = 0, char_1_list.Count - 1 do
		coroutine.yield(self:attack_normal(key, char_1_list[i], char_2_list[i]))
	end
end

-- SurvivalChallengeController.lua 참조
function local_class:get_lava_tile_within_bound(bound)
	local tile_name ='floor2_4'
	local move = unity_class.vector3.zero
	local list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(bound, move)

	local result = { }

	for i = 0, list.Count - 1 do
		local v = list[i]
		if string.find(v.Name, tile_name) then
			table.insert(result, v)
		end
	end

	list:Dispose()

	return result
end

--- 상태에 관계 없이 즉시 용암을 분출할 수 있는 열림 상태로 전환
--- duration 값을 받으면 해당 시간 이후 용암을 분출하지 않는 열림 상태로 전환
function local_class:activate_lava(lava, duration)
	local behav = lava.FieldObjectBehaviour
	if not lua_helper.type_compare(behav, CS.Oak.LavaTrapFieldObjectBehaviour) then return end

	behav:Open(true, true)
	behav:Activate(true)

	if duration ~= nil then
		wait_for_sec(duration)
		self:deactivate_lava(lava)
	end
end

--- 상태에 관계 없이 즉시 용암을 분출하지 않는 열림 상태로 전환
--- duration 값을 받으면 해당 시간 이후 용암을 분출할 수 있는 상태로 전환
function local_class:deactivate_lava(lava, duration)
	local behav = lava.FieldObjectBehaviour
	if not lua_helper.type_compare(behav, CS.Oak.LavaTrapFieldObjectBehaviour) then return end

	--behav:Close(false)
	behav:Close(true)
	behav:Open(true, false)

	if duration ~= nil then
		wait_for_sec(duration)
		if self.progress_state == self.progress_enum.clear then return end
		self:activate_lava(lava)
	end
end

-- 비앙카 필살기
-- 이 부분은 연출 코드는 CwpSuccubusNobleIceShockWaveBattleAction.lua:400-431 참조
function local_class:bianca_super_attack()
	local bianca = get_character('stalker_bianca')
	character_util.set_direction(bianca, 'right')
	-- character_util.remove_anim(bianca)
	character_util.set_anim(bianca, { name = 'twohand_attack4' , loop = false })
	local effect_1 = unity_object_pool.GetOrCreate('fx_cwp_ice_succubus_cast'):Instantiate(bianca.Position)

	wait_for_sec(1.1667)

	-- 이 부분은 연출 코드는 CwpSuccubusNobleIceShockWaveBattleAction.lua:400-431 참조
	local loop = 0
	local time_passed = 0
	local explosion_position = bianca.Position + 2 * unity_class.vector3.right
	local explosion_distance = 2
	local explosion_term = 0.1
	local explosion_fx = {}

	music_player_util.play_sfx({ sfx_name = '02_ice_ridge_01' })
	-- 폭발 판정
	while loop < 5 do
		local old_time_passed = time_passed
		time_passed = time_passed + unity_class.time.deltaTime

		-- check explosion term
		while float_util.is_almost_zero(explosion_term) and float_util.is_almost_zero(old_time_passed) or
				old_time_passed < explosion_term and explosion_term <= time_passed do
			local pos = explosion_position:GetX0z(field:GetTileInfoAt(explosion_position):GetHeightAt(explosion_position))

			local effect = object_pool_extensions.Instantiate(unity_object_pool.GetOrCreate('fx_cwp_ice_succubus'), pos, unity_class.vector3.right, nil)
			table.insert(explosion_fx,effect)
			-- shake camera
			stage_camera:Shake(0.1, 0.3)

			-- update time passed
			time_passed = time_passed - explosion_term
			loop = loop + 1

			-- check limit
			if loop >= 5 then
				break
			end

			explosion_position = explosion_position + explosion_distance * unity_class.vector3.right
		end
		coroutine.yield(nil)
	end

	wait_for_sec(1)

	character_util.set_anim(bianca, { name = 'twohand_idle' })

	effect_1:Dispose()
	for i=1,#explosion_fx do
		explosion_fx[i]:Dispose()
	end
end

function local_class:dispose()
	self.hit_effect_preset = nil
	self.throw_rock_stat = nil
	self.kid_start_pos = nil
	self.monsters_start_pos = nil
	self.is_battle_dict = nil
	self.temp_rocks = nil

	self.first = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.RhythmGameEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	self.cs_controller = nil
	self.origin_leader = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
