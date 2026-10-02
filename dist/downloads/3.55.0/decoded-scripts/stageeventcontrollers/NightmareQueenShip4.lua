local local_class = newclass('NightmareQueenShip4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 435

	-- character
	self.characters = {
		s12_patrol_invader = function(idx)
			return get_character('s12_patrol_invader_' .. idx)
		end,

		s13_patrol_invader = function(idx)
			return get_character('s13_patrol_invader_' .. idx)
		end,

		little_girl = function()
			return get_character('little_girl')
		end,
	}

	-- marker
	self.markers = {
		s12_captured_reset_pos = function()
			return field_util.get_marker_pos('s12_captured_reset_pos')
		end,

		captured_reset_pos = function()
			return field_util.get_marker_pos('captured_reset_pos')
		end,
	}

	self.prologue_data = {
		jamming_wave = {
			zone = 'prologue_jamming_wave_enter_zone',
			entered = false,
			scene_end = false,
			cb = self.jamming_wave_scene,
		},

		frog = {
			zone = 'prologue_frog_enter_zone',
			entered = false,
			scene_end = false,
			cb = self.frog_scene,
			custom_state_key = 'prologue_frog',
		},
	}

	self.vent = {
		crawling = false,

		data = {

			--region Section 11

			s11_vent_wall_1 = {
				enter_dir = 'right',
				exit_dir = 'left',
			},
			s11_vent_wall_2 = {
				enter_dir = 'left',
				exit_dir = 'right',
			},

			--region Section 12

			s12_vent_wall_1 = {
				enter_dir = 'up',
				exit_dir = 'down',
			},
			s12_vent_wall_2 = {
				enter_dir = 'down',
				exit_dir = 'up',
			},

			--region Section 13

			s13_vent_wall_1 = {
				enter_dir = 'down',
				exit_dir = 'up',
			},
			s13_vent_wall_2 = {
				enter_dir = 'right',
				exit_dir = 'left',
			},

			--endregion
		},
	}

	self.fx = {
		cached_inst = {},

		portal = function()
			return unity_object_pool.GetOrCreate('fx_obj_event_portal')
		end,

		portal_wind_land = function()
			return unity_object_pool.GetOrCreate('fx_obj_event_portal_wind_land')
		end,

		cache = function(this, fx)
			table.insert(this.cached_inst, fx)
		end,

		load_all = function(this)
			for name, load_func in pairs(this) do
				if type_util.is_function(load_func) and
						name ~= 'load_all' and
						name ~= 'cache' and
						name ~= 'dispose' then

					load_func()
				end
			end
		end,

		dispose = function(this)
			for i = 1, #this.cached_inst do
				this.cached_inst[i]:Dispose()
				this.cached_inst[i] = nil
			end

			this.cached_inst = nil
		end
	}

	--eat 3d sfx
	self.eat_3d_sfx = nil

	--스테이지 종료 체크
	self.stage_ended = false
	self.is_jamming_hide_npc = false

	-- 개구리 전일담 연출 포탈 관련
	self.portal_effect = nil
	self.portal_wind_land_effect = nil
	self.portal_open_sfx = nil

	--퍼즐 패트롤
	self.is_detected = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	start_coroutine(self.pre_setting, self)
end

function local_class:on_interact_event(e)
	for wall_name, info in pairs(self.vent.data) do
		local wall = get_field_object(wall_name)

		if lua_helper.reference_equals(e.Target, wall) then
			if self.vent.crawling then
				self.vent.crawling = false
				start_coroutine(self.exit_hole_event, self, e.Target, info.exit_dir)
			else
				self.vent.crawling = true
				start_coroutine(self.enter_hole_event, self, e.Target, info.enter_dir)
			end

			return true
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	for _, data in pairs(self.prologue_data) do
		if type_util.is_zone_full_enter(e, get_party_leader(), data.zone) and
				not data.entered then
			data.entered = true
			start_coroutine(data.cb, self)

			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if self.prologue_data.jamming_wave.scene_end and not self.is_jamming_hide_npc and
			type_util.is_player_enter_to_cam_grid(e, 'jamming_wave_grid') then
		self.jamming_hide_npc = true
		self:hide_jamming_npc()

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if not self.is_detected and e.Params[0] == 'detected_by_invaders' then
		self.is_detected = true
		sp_util.start_scene(self.on_party_detected_by_invaders, self, e.Sender)

		return true
	end

	return false
end

function local_class:on_stage_end_event()
	self.stage_ended = true
end

--endregion event

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 섹션 상태에 따른 link door 상태
	if self.quest_progress == nil or self.quest_progress.IsComplete then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true))
	elseif self.quest_progress.InnerProgress > 13 then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true))
	elseif self.quest_progress.InnerProgress > 11 then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
	end

	-- 시작 연출
	if self.quest_progress == nil or self.quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s11_1_camera_1'), false, false)
	elseif self.quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s12_start'), true, true)
	elseif self.quest_progress.InnerProgress == 12 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s13_start_pos'), true, true)
	elseif self.quest_progress.InnerProgress == 13 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s13_hacking_console_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:pre_setting_by_progress()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil and quest_progress.InnerProgress > 11 then
		-- 순찰 인베이더 암살 가능 셋팅
		self:convert_only_assassinate(self.characters.s12_patrol_invader(1))
		self:convert_only_assassinate(self.characters.s12_patrol_invader(2))
	end

	if quest_progress.InnerProgress > 13 then
		--13섹션 순찰 인베이더 암살 가능 세팅
		local count = 4

		for i = 1, count do
			self:convert_only_assassinate(self.characters.s13_patrol_invader(i))
		end
	end

	-- check custom state
	-- 전일담 개구리 이벤트 다 봤는지 확인
	local custom_state = quest_util.get_custom_state(quest_progress, self.prologue_data.frog.custom_state_key)

	if custom_state == 1 then
		self.prologue_data.frog.entered = true
	end
end

function local_class:on_party_detected_by_invaders(detecting_invader)
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')

	character_util.look_at(detecting_invader, user_party.Leader)
	party_util.look_at(detecting_invader)
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	scene_util.set_anim(detecting_invader, self, { name = 'release' })
	scene_util.set_emotion(detecting_invader, self, 'attack')

	music_player_util.play_sfx_one_shot('02_goblin_appear_01')

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local main_quest_inner_progress = main_quest_progress.InnerProgress

	local string_key = 'nm_qs_main_s12_patrol_invader_2'
	for i = 0, user_party.Count - 1 do
		if lua_helper.reference_equals(user_party[i], self.characters.little_girl()) then
			string_key = 'nm_qs_main_s12_patrol_invader_1'
		end
	end

	speech_bubble_util.show_speech_bubble_async(detecting_invader, { key = string_key,
																	 bubble_type = 'shout', type_speed = 0, skip = true })

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.75, 'linear')
	wait_for_sec(0.5)

	--리셋 위치 설정
	do
		local is_s12_patrol = false
		local reset_pos = field_util.get_marker_pos('s13_reset_pos')
		local reset_dir = 'down'

		for i = 1, 2 do
			local npc = self.characters.s12_patrol_invader(i)

			if lua_helper.reference_equals(detecting_invader, npc) then
				is_s12_patrol = true
				break
			end
		end

		if is_s12_patrol then
			reset_pos = (main_quest_inner_progress == 11) and
					self.markers.s12_captured_reset_pos() or self.markers.captured_reset_pos()

			reset_dir = (main_quest_inner_progress == 11) and
					'right' or 'left'
		else
			local count = 4

			for i = 1, count do
				local npc = self.characters.s13_patrol_invader(i)
				message_system:SendSync(npc, CS.Oak.StateResetEvent.Instance)
			end
		end

		party_util.position_party(reset_pos, reset_dir, 'linear')
	end

	camera_util.return_to_leader(0)
	character_util.remove_anim_and_emotion(detecting_invader)
	party_util.remove_emotion()
	party_util.remove_animation()

	screen_util.fade_in_circular_async(0.75, 'linear')

	self.is_detected = false

	message_system:Publish(CS.Oak.CustomStageEvent.Create(get_party_leader(), { 'reset', 'detected_by_invaders' }))
end

function local_class:siren_tint_off()
	self.is_siren_tint = false
end

function local_class:enter_hole_event(target, party_dir)
	sp_util.enter_scene(nil)

	for i = 0, user_party.Count - 1 do
		scene_util.set_direction(user_party[i], party_dir, false)
	end

	local dir = direction_util.to_vector3_ver2(user_party.Leader.Direction)

	local move_end_key = 'party_align'
	wp_util.move_with_end_callback(user_party.Leader, target.Position + (dir * -1), 1.5, nil, self, move_end_key,
			{ last_direction = party_dir })

	wp_util.wait_move_end(self, move_end_key)

	dir = dir * 1.7

	local party = {}
	for i = 0, user_party.Count - 1 do
		local c = user_party[i]

		table.insert(party, { npc = c, origin = c.Position })
	end

	local timer = 0
	local duration = 1.2
	local stamps = {
		0, 0.5, 1
	}
	local states = {
		false, false, false
	}

	music_player_util.play_sfx_one_shot('01_grass_slide_02')

	while timer < duration do
		local progress = timer / duration
		local dt = unity_class.time.deltaTime

		for i, data in ipairs(party) do
			if stamps[i] < timer and not states[i] then
				states[i] = true

				music_player_util.play_sfx_one_shot('01_rustle_01')
				character_util.set_anim(data.npc, { name = 'walk4legs' })
			end

			character_util.set_position(data.npc, data.origin + dir * progress)
		end

		coroutine.yield()
		timer = timer + dt
	end

	for _, data in pairs(party) do
		character_util.set_position(data.npc, data.origin + dir)
	end

	party_util.remove_animation()

	local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
	manual_touch_state:DisableControls(CS.Oak.DisabledControls.Dash | CS.Oak.DisabledControls.Attack | CS.Oak.DisabledControls.Super)

	local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
	message_system:SendSync(user_party.Leader.FieldObjectController, state_change_event)

	sp_util.exit_scene(nil, get_party_leader())

	coroutine.yield(nil)

	self:change_party_member_4legs(true)
end

function local_class:exit_hole_event(target, party_dir)
	sp_util.enter_scene(nil)

	local dir = direction_util.to_vector3_ver2(direction_constants[party_dir])

	character_util.set_anim(user_party.Leader, { name = 'walk4legs' })

	character_util.move_to_async(user_party.Leader, target.Position + (dir * -1),
			nil, 1.5, true, false)

	for i = 0, user_party.Count - 1 do
		scene_util.set_direction(user_party[i], party_dir, false)
	end

	dir = dir * 1.7

	self:change_party_member_4legs(false)

	local party = {}
	for i = 0, user_party.Count - 1 do
		local c = user_party[i]

		table.insert(party, { npc = c, origin = c.Position })
		character_util.set_anim(c, { name = 'walk4legs' })
	end

	local timer = 0
	local duration = 1.5
	local stamps = {
		0.3, 0.8, 1.3
	}
	local states = {
		false, false, false
	}

	music_player_util.play_sfx_one_shot('01_grass_slide_02')

	while timer < duration do
		local progress = timer / duration
		local dt = unity_class.time.deltaTime

		for i, data in ipairs(party) do
			if stamps[i] < timer and not states[i] then
				states[i] = true
				music_player_util.play_sfx_one_shot('01_rustle_01')
			end

			character_util.set_position(data.npc, data.origin + dir * progress)
		end

		coroutine.yield()
		timer = timer + dt
	end

	for _, data in pairs(party) do
		character_util.set_position(data.npc, data.origin + dir)
	end

	party_util.remove_animation()

	sp_util.exit_scene(nil, get_party_leader())
end

function local_class:change_party_member_4legs(to_walk_4legs)
	for i = 0, user_party.Count - 1 do
		local character = user_party[i]
		if to_walk_4legs then
			character.CustomIdleAnimationName = 'meditation'
			character.CustomWalkAnimationName = 'walk4legs'

			buff_manager:AddBuff(character, CS.Oak.EquipmentSlot.None, character, 'speed_down_persistent', 60, false, false)

		else
			character.CustomIdleAnimationName = ''
			character.CustomWalkAnimationName = ''

			buff_manager:RemoveBuff(character, CS.Oak.EquipmentSlot.None, character, 'speed_down_persistent')
		end
	end
end

function local_class:jamming_wave_scene()
	local jamming_npc_1 = get_character('prologue_jamming_wave_npc_1')
	local jamming_npc_2 = get_character('prologue_jamming_wave_npc_2')
	local jamming_npc_3 = get_character('prologue_jamming_wave_npc_3')

	-- 1번 NPC (right, idle, eat): 여기 전선만 연결을 마무리 하면….
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'right', sfx = false },
			{ name = 'eat' },
			nil,
			{ key = 'nm_qs_prologue_jamming_1', skip = false })

	music_player_util.stop_sfx(self.eat_3d_sfx)
	self.eat_3d_sfx = nil

	if self.stage_ended then
		return
	end

	--1번 NPC (right, idle, walk) 0.5초 간 뒷걸음질로 왼쪽으로 0.5타일 이동
	wp_util.move_async(jamming_npc_1, jamming_npc_1.Position + vector(-0.5, 0, 0),
			nil, 0.5, { locked_dir = 'right' })

	if self.stage_ended then
		return
	end

	-- 1번 NPC (right, idle, idle):  휴… 다 만들었다.
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'right', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_2', skip = false })

	if self.stage_ended then
		return
	end

	-- 2번 NPC (right idle, clap): 고생했어.
	scene_util.play_normal_speech_action(jamming_npc_2, self,
			nil,
			{ name = 'clap' },
			nil,
			{ key = 'nm_qs_prologue_jamming_3', skip = false })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_swing_01', parent = jamming_npc_1, max_distance = 8 })
	scene_util.set_direction(jamming_npc_1, 'left', false)
	character_util.remove_anim_and_emotion(jamming_npc_1)

	--2번 NPC (right idle, idle): 그런데 왜 갑자기 일정을 빠듯하게 잡는거지…?
	scene_util.play_normal_speech_action(jamming_npc_2, self,
			nil,
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_3_1', skip = false })

	-- 1번 NPC (left, idle, bomb_idle): 볼트가 갑자기 빨리 만들어야 한다고 쪼더라고.
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'left', sfx = false },
			{ name = 'bomb_idle' },
			nil,
			{ key = 'nm_qs_prologue_jamming_4', skip = false })

	if self.stage_ended then
		return
	end

	-- 1번 NPC (left, idle, idle): 근데 이걸 우리가 옮겨야 한다는 거지?
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'left', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_5', skip = false })

	if self.stage_ended then
		return
	end

	-- 2번 NPC (right, idle, idle): 지금 다른 기술병들도 다른 데로 지원 나가서 우리가 옮겨야 된다던데….
	scene_util.play_normal_speech_action(jamming_npc_2, self,
			{ dir = 'right', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_6', skip = false })

	if self.stage_ended then
		return
	end

	-- 1번 NPC (left, idle, cross_arm): 이걸 어떻게 셋이서 옮겨….
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'left', sfx = false },
			{ name = 'cross_arm', keep = true },
			nil,
			{ key = 'nm_qs_prologue_jamming_7', skip = false })

	if self.stage_ended then
		return
	end

	-- 3번 NPC (right, idle, cross_arm) 상태로 (silence) 버블 이모티콘 출력
	scene_util.play_emoticon_action(jamming_npc_3, self,
			'right',
			'cross_arm',
			nil,
			'silence')

	if self.stage_ended then
		return
	end

	-- 1번 NPC (left, mad, idle) 상태로 1회 jump
	scene_util.set_direction(jamming_npc_1, 'left', false)
	scene_util.set_emotion(jamming_npc_1, self, 'mad')
	character_util.remove_anim(jamming_npc_1)
	character_util.normal_jump(jamming_npc_1, true)

	-- 3번 NPC (right, idle, idle): 그럼 일단 전파기 옮기는 통로 쪽에 문 열어 놓을게!
	scene_util.play_normal_speech_action(jamming_npc_3, self,
			{ dir = 'right', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_8', skip = false })

	if self.stage_ended then
		return
	end

	-- 3번 NPC 아래로 6의 속도로 이동
	do
		local speed = 6

		character_util.remove_anim(jamming_npc_3)
		wp_util.move(jamming_npc_3, jamming_npc_3.Position + vector(0, 0, -9), speed)
	end

	do
		local wait = true

		start_coroutine(function()
			scene_util.set_direction(jamming_npc_1, 'left', false)
			scene_util.set_anim_async(jamming_npc_1, self, { name = 'release', count = 1 })

			if self.stage_ended then
				return
			end

			scene_util.set_direction(jamming_npc_1, 'down', false)
			scene_util.set_anim_async(jamming_npc_1, self, { name = 'release', count = 1 })

			wait = false
		end)

		-- 1번 NPC (left, idle, release 1회): 잠깐!
		character_util.remove_emotion(jamming_npc_1)
		scene_util.play_normal_speech_action(jamming_npc_1, self,
				nil,
				nil,
				nil,
				{ key = 'nm_qs_prologue_jamming_9', skip = false })

		if self.stage_ended then
			return
		end

		while wait do
			coroutine.yield(nil)
		end
	end

	if self.stage_ended then
		return
	end

	--1번 NPC (down, mad, idle) 상태 shake 출력
	--1번 NPC(down, mad, idle): 아오…!
	music_player_util.play_sfx({
		sfx_name = '01_evolution_01', loop = false, parent = jamming_npc_1, maxDistance = 8 })
	scene_util.normal_shake(jamming_npc_1, 1, false)
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'down', sfx = false },
			nil,
			{ name = 'mad' },
			{ key = 'nm_qs_prologue_jamming_9_1', skip = false })

	-- 2번 NPC (right, idle, idle): 왜 그래?
	scene_util.play_normal_speech_action(jamming_npc_2, self,
			{ dir = 'right', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_10', skip = false })

	if self.stage_ended then
		return
	end

	-- 1번 NPC (left, idle, idle): 쟤 또 작업하기 싫어서 저러는 거잖아….
	music_player_util.play_sfx({ sfx_name = '01_swing_01', parent = jamming_npc_1, max_distance = 8 })
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'left', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_jamming_11', skip = false })

	if self.stage_ended then
		return
	end

	--1번 NPC (left, mad, idle) 상태 shake 출력
	-- 1번 NPC (left, mad, idle): 문 안 열려 있으면 진짜 문 부숴버릴 거야.

	start_coroutine(function()
		local attack_duration = spine_util.get_animation_duration(jamming_npc_1, 'attack')

		wait_for_sec(attack_duration * 2)

		music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = jamming_npc_1, max_distance = 8 })
	end)
	scene_util.normal_shake(jamming_npc_1)
	character_util.shake(jamming_npc_1, 0.03, 99999)
	scene_util.play_normal_speech_action(jamming_npc_1, self,
			{ dir = 'left', sfx = false },
			{ name = 'attack', count = 2 },
			{ name = 'mad' },
			{ key = 'nm_qs_prologue_jamming_12', skip = false })

	character_util.stop_shake(jamming_npc_1)

	if self.stage_ended then
		return
	end

	--1번 NPC (down, mad, run) 상태로 아래로 5의 속도로 이동
	do
		local wp_key = 'group_run'
		local speed = 5

		--1번 NPC (down, mad, run) 상태로 아래로 5의 속도로 이동
		character_util.remove_anim(jamming_npc_1)
		wp_util.move_with_end_callback(jamming_npc_1, jamming_npc_1.Position + vector(0, 0, -9),
				speed, nil, self, wp_key, { run = true })

		--0.3초 대기
		wait_for_sec(0.3)

		if self.stage_ended then
			return
		end

		--2번 NPC (down, idle, run) 상태로 아래로 5의 속로 이동
		character_util.remove_anim(jamming_npc_2)
		wp_util.move_with_end_callback(jamming_npc_2, jamming_npc_2.Position + vector(0, 0, -9),
				speed, nil, self, wp_key, { run = true })

		--같이 가!
		speech_bubble_util.show_speech_bubble(jamming_npc_2, {
			key = 'nm_qs_prologue_jamming_13',
			skip = false,
		})

		wp_util.wait_move_end(self, wp_key)

		if self.stage_ended then
			return
		end

		character_util.stop(jamming_npc_2)
	end

	self.prologue_data.jamming_wave.scene_end = true
end

function local_class:hide_jamming_npc()
	local jamming_npc_1 = get_character('prologue_jamming_wave_npc_1')
	local jamming_npc_2 = get_character('prologue_jamming_wave_npc_2')
	local jamming_npc_3 = get_character('prologue_jamming_wave_npc_3')
	local npc_3_pos = field_util.get_marker_pos('jamming_wave_npc_pos')

	field_object_util.set_active_state(jamming_npc_1, active_state_type.disabled)
	field_object_util.set_active_state(jamming_npc_2, active_state_type.disabled)
	field_object_util.set_active_state(jamming_npc_3, active_state_type.visible)

	--3번 NPC (left, idle, prostarte) 상태로 검정 틴트 60%로 출력
	scene_util.set_direction(jamming_npc_3, 'left', false)
	character_util.set_anim(jamming_npc_3, { name = 'prostrate' })
	jamming_npc_3.Position = npc_3_pos
	character_util.add_color(jamming_npc_3, jamming_npc_3.Name, unity_class.color.black, 0.6, 0)
	field_ui_manager:RemoveUI(jamming_npc_3, field_ui_type.character_stats)

	--door
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('jamming_wave_door', true))
end

function local_class:frog_scene()
	local green_frog = get_character('prologue_frog_green')
	local event_center_pos = field_util.get_marker_pos('prologue_frog_center_pos')

	-- a 위치에 fx_obj_event_protal 스케일 0에서 1까지 1초에 걸쳐 출력 (async)
	self:open_portal(event_center_pos)

	field_object_util.set_active_state(green_frog, active_state_type.enabled)

	coroutine.yield()

	character_util.spine_set_alpha_fade(green_frog, 0, 0)
	character_util.set_position(green_frog, event_center_pos)
	scene_util.set_direction(green_frog, 'down', false)

	-- 1초 대기
	wait_for_sec(1)

	-- 동시 출력
	-- 초록색 개구리 (down, idle, walk)로  a 위치에서 아래로 1타일 1초간 이동
	-- 도착하면 (left, idle, idle) 출력
	-- 초록 개구리 알파값 0에서 1까지 1초간 출력
	music_player_util.play_sfx({ sfx_name = '01_frog_02', loop = false, parent = green_frog, max_distance = 6 })
	character_util.spine_set_alpha_fade(green_frog, 1, 1)
	wp_util.move_async(green_frog, green_frog.Position + vector(0, 0, -1),
			nil, 1, { last_direction = 'left' })

	-- 1초 대기
	wait_for_sec(1)

	-- fx_obj_event_protal 스케일 1에서 0으로 1초간 출력
	-- 0이 되면 사라짐
	self:close_portal()

	wait_for_sec(1)

	-- 초록색 개구리 (right, idle, idle) 출력
	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.set_direction(green_frog, 'right', false)

	-- 1초 대기
	wait_for_sec(1)

	-- 초록색 개구리 (left, idle, idle) 출력
	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.set_direction(green_frog, 'left', false)

	-- 1초 대기
	wait_for_sec(1)

	-- 초록색 개구리 (left, idle, idle) 상태에서 silence 이모티콘 출력
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.play_emoticon_action(green_frog, self,
			nil,
			nil,
			nil,
			'silence')

	-- 초록색 개구리 (left, idle, idle): 실수인 척 좌표를 잘 못 입력하긴 했는데…
	music_player_util.play_sfx({ sfx_name = '01_frog_03', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.play_normal_speech_action(green_frog, self,
			{ dir = 'left', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_frog_1', skip = false })

	if self.stage_ended then
		return
	end

	-- 초록색 개구리 (left, idle, idle): 일부러 여기에 온 걸 알면 가만히 두지 않을 거야….
	music_player_util.play_sfx({ sfx_name = '01_frog_03', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.play_normal_speech_action(green_frog, self,
			{ dir = 'left', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_frog_2', skip = false })

	if self.stage_ended then
		return
	end

	-- 초록색 개구리 (left, idle, idle): 다른 소대원을 만나기 전에 얼른 피규어를 구해야 해.
	music_player_util.play_sfx({ sfx_name = '01_frog_03', loop = false, parent = green_frog, max_distance = 6 })
	scene_util.play_normal_speech_action(green_frog, self,
			{ dir = 'left', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_prologue_frog_3', skip = false })

	if self.stage_ended then
		return
	end

	-- 초록색 개구리 4의 속도로 위로 이동
	music_player_util.play_sfx({ sfx_name = '01_frog_02', loop = false, parent = green_frog, max_distance = 6 })
	wp_util.move_async(green_frog, green_frog.Position + vector(-8, 0, 0),
			4, nil)

	-- 그리드 밖으로 나가면 초록색 개구리 제거 상태
	field_object_util.set_active_state(green_frog, active_state_type.disabled)

	self.prologue_data.frog.scene_end = true

	--현재 스테이트 저장
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	quest_util.set_custom_state(quest_progress, self.prologue_data.frog.custom_state_key, 1)
end

function local_class:pre_setting()
	-- 섹션 프로그레스에 따른 초기 셋팅
	self:pre_setting_by_progress()

	self.fx:load_all()

	--region 전파 방해 전일담

	--1번 NPC: nightmare_qs_invader_soldier (right, idle, eat)
	local jamming_npc_1 = get_character('prologue_jamming_wave_npc_1')
	character_util.set_active_state(jamming_npc_1, 'enabled')
	character_util.set_direction(jamming_npc_1, 'right')
	character_util.set_anim_and_emotion(jamming_npc_1, { name = 'eat' }, { name = 'idle' })

	--2번 NPC: nightmare_qs_invader_soldier (right, idle, idle)
	local jamming_npc_2 = get_character('prologue_jamming_wave_npc_2')
	character_util.set_active_state(jamming_npc_2, 'enabled')
	character_util.set_direction(jamming_npc_2, 'right')
	character_util.set_anim_and_emotion(jamming_npc_2, { name = 'idle' }, { name = 'idle' })

	--3번 NPC: nightmare_qs_invader_soldier (right, idle, idle)
	local jamming_npc_3 = get_character('prologue_jamming_wave_npc_3')
	character_util.set_active_state(jamming_npc_3, 'enabled')
	character_util.set_direction(jamming_npc_3, 'right')
	character_util.set_anim_and_emotion(jamming_npc_3, { name = 'idle' }, { name = 'idle' })

	self.eat_3d_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', parent = jamming_npc_1,
		loop = true, type_priority = 'loop', player_priority = 'npc',
		max_distance = 8
	})
	--endregion
end

-- 포탈이 열리는 연출 (나리 퀘스트 코드에서 참조)
function local_class:open_portal(pos)
	-- 좌우 대칭이라 factor 사용 없이 위치를 오른쪽 기준으로 잡음
	local portal_effect = self.fx:portal():Instantiate(pos + vector(0, 0, 0))
	self.portal_effect = portal_effect

	portal_effect.transform.localScale = unity_class.vector3.zero

	local open_dur = 1

	self.portal_open_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_portal_01', type_priority = 'event', play_pos = pos, max_distance = 6 })

	self:portal_appear(portal_effect.transform, open_dur, vector(1.5, 1.5, 1.5), -2)
	self.portal_wind_land_effect = self.fx:portal_wind_land():Instantiate(pos)
	self.portal_wind_land_effect.transform.localScale = vector(0.58, 1, 1)
end

-- 포탈이 닫히는 연출
function local_class:close_portal()
	local close_dur = 1
	field:RemoveTint('exit_portal', close_dur)

	music_player_util.play_sfx(
			{ sfx_name = '01_portal_02', type_priority = 'event', play_pos = field_util.get_marker_pos('prologue_frog_center_pos'), max_distance = 6 })
	music_player_util.fade_out_sfx(self.portal_open_sfx, 1.5)

	self:portal_disappear(self.portal_effect.transform, close_dur, 2)
	self.portal_effect:Dispose()
	self.portal_wind_land_effect:Dispose()
	self.portal_effect = nil
	self.portal_wind_land_effect = nil
	self.portal_open_sfx = nil
end

--- 포탈 커지는 연출
--- @param transform any 포탈 이펙트 오브젝트의 Transform
--- @param duration number 커지는 시간
--- @param target any 마지막에 세팅될 포탈 사이즈
--- @param y_dif number 커지면서 변할 y 좌표
function local_class:portal_appear(transform, duration, target, y_dif)
	local start_time = unity_class.time.time
	local origin_pos = transform.localPosition

	while unity_class.time.time - start_time < duration do
		local normalized = (unity_class.time.time - start_time) / duration
		transform.localScale = target * normalized

		coroutine.yield()
	end

	transform.localScale = target
end

--- 포탈 작아지면서 사라지는 연출. 끝나고 Dispose 잊지 말기
--- @param transform any 포탈 이펙트 오브젝트의 Transform
--- @param duration number 사라질 시간
function local_class:portal_disappear(transform, duration, y_dif)
	local start_time = unity_class.time.time
	local origin_scale = transform.localScale
	local origin_pos = transform.localPosition

	while unity_class.time.time - start_time < duration do
		local normalized = (unity_class.time.time - start_time) / duration
		transform.localScale = origin_scale * (1 - normalized)

		coroutine.yield()
	end

	transform.localScale = unity_class.vector3.zero
end

function local_class:convert_only_assassinate(fo)
	fo.EntityGroup = CS.Oak.EntityGroups.Enemy0
	fo.DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
	fo.DamagedBehaviour.ShowDamageNumber = false
	fo.DamagedBehaviour.PlayDeathSfx = false
	fo.DamagedBehaviour.ApplyOtherDamage = false
	fo.DamagedBehaviour.ApplyBombDamage = false
	fo.DamagedBehaviour.ApplyAilment = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
