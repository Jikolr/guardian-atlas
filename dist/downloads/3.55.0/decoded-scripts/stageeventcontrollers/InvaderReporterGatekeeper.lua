local local_class = newclass("InvaderReporterGatekeeperController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.gatekeepers = nil

	self.dead_bodies = nil

	self.bikini_invaders = nil

	self.android_head = nil

	-- 사진 촬영 Effect
	self.scoop_effect_1 = nil

	-- 인트로 부분 대사 한 번만 나오도록 저장하는 플래그
	self.see_intro = false

	-- 시체 존에 들어갔는지 저장
	self.enter_dead_body_zone = false

	-- 비키니 인베이더 존에 들어갔는지 저장
	self.enter_bikini_invader_zone = false

	-- 비키니 인베이더 사진 찍었는지 저장
	self.get_bikini_invader_photo = false

	-- 스테이지 커스텀 State
	self.stage_custom_state = {
		dead_body = 0,
		bikini_invader = 7
	}

	-- 기타 상수
	self.gatekeepers_num = 2
	self.ball_dist = 0.3

	-- 타일맵 NPC 이름
	self.gatekeeper_name = 'guard_1_'

	-- 타일맵 존 이름
	self.dead_body_event_zone_name = 'dead_body'
	self.bikini_invader_event_zone_name = 'bikini_invader'

	-- 틴트 키
	self.tint_key = 'invader_reporter_gatekeeper'

	-- 타임스케일 키
	self.time_scale_key = 'invader_reporter_gatekeeper'

	-- 커스텀 이벤트 이름
	self.get_photo_dead_body = 'get_photo4'
	self.get_photo_bikini_invader_event = 'get_photo_bikini_invader'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.scoop_effect_preset = 'invader_reporter_scoop_target'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	self.gatekeepers = create_generic_list(CS.Oak.Character)

	for i = 1, self.gatekeepers_num do
		local cur_guard = get_character(self.gatekeeper_name..i)
		cur_guard.Interactable:AddListener(self.cs_controller)

		self.gatekeepers:Add(cur_guard)
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local scoop_effect_pool = unity_object_pool.GetOrCreate(self.scoop_effect_preset)

	local optimized_npcs = load_util.create_optimized_npcs_async({
		dead_body_1 = 'civilian_male',
		dead_body_2 = 'civilian_female',
		dead_body_3 = 'future_resistance_male',
		dead_body_4 = 'future_resistance_female',
		dead_body_5 = 'future_resistance_female',
		dead_body_6 = 'future_resistance_male',
		dead_body_7 = 'future_snowman_male',
		dead_body_8 = 'future_snowman_female',
		dead_body_9 = 'future_steampunk_citizen_male',
		dead_body_10 = 'future_steampunk_citizen_female',
		dead_body_11 = 'future_innuit_male',
		dead_body_12 = 'future_innuit_female',
		dead_body_13 = 'future_china_male',
		dead_body_14 = 'future_china_female',
		dead_body_15 = 'future_dungeon_male',
		dead_body_16 = 'future_dungeon_female',
		dead_body_17 = 'future_teatan_male',
		dead_body_18 = 'future_teatan_female',
		dead_body_19 = 'future_jungpa_male',
		dead_body_20 = 'future_ms_student_female',
		dead_body_21 = 'future_succubus_b',
		dead_body_22 = 'future_ms_student_male',
		dead_body_23 = 'future_desertelf_mad_male',
		dead_body_24 = 'future_desertelf_mad_female',

		bikini_invader_1 = 'invader_bikini',
		bikini_invader_2 = 'invader_bikini',
		bikini_invader_3 = 'invader_bikini',
		bikini_invader_4 = 'invader_bikini',
		bikini_invader_5 = 'invader_bikini',
		bikini_invader_6 = 'invader_bikini',

		android_head = 'future_broken_worker_a'
	})

	self.dead_bodies = create_generic_list(CS.Oak.Character)
	for i = 1, 24 do
		self.dead_bodies:Add(optimized_npcs['dead_body_'..i])
	end

	local index = 0
	local index_max = 8
	local index_sub = 2
	local count = 0
	local add_y = 0.5

	for i = 0, self.dead_bodies.Count - 1 do
		field_ui_manager:RemoveUI(self.dead_bodies[i], CS.Oak.FieldUiType.CharacterStats)
		self.dead_bodies[i].SpineController:AddColor(self.dead_bodies[i].Name, unity_color({0.2, 0.2, 0.2, 1}), 1, 0)

		index = index + 1

		if index > index_max then
			index = 0

			index_max = index_max - index_sub

			count = count + 1
		end

		local mod2 = i % 2
		local mod3 = i % 3

		local cur_x = 5 + 0.5 * count + 0.5 * index
		local cur_y = add_y * count
		local cur_z = 16

		if mod2 == 0 then
			character_util.set_position(self.dead_bodies[i], vector(cur_x, cur_y, cur_z))
		else
			local rand_z = unity_class.random.Range(-0.1, 0.1)

			character_util.set_position(self.dead_bodies[i], vector(cur_x, cur_y, cur_z + rand_z))
		end

		if mod3 == 2 then
			character_util.set_direction(self.dead_bodies[i], 'left')
		else
			character_util.set_direction(self.dead_bodies[i], 'right')
		end

		character_util.set_anim(self.dead_bodies[i], { name = 'prostrate' })
		character_util.set_emotion(self.dead_bodies[i], { name = 'damaged' })
	end

	self.bikini_invaders = create_generic_list(CS.Oak.Character)
	for i = 1, 6 do
		self.bikini_invaders:Add(optimized_npcs['bikini_invader_'..i])
	end

	local invader_pos_list = create_generic_list(unity_class.vector3)
	invader_pos_list:Add(vector(9, 0, -14))
	invader_pos_list:Add(vector(10.5, 0, -15.5))
	invader_pos_list:Add(vector(9.7, 0, -17))
	invader_pos_list:Add(vector(5.5, 0, -14.5))
	invader_pos_list:Add(vector(4.5, 0, -15))
	invader_pos_list:Add(vector(6, 0, -16.5))

	for i = 0, self.bikini_invaders.Count - 1 do
		local val = math.floor(i / 3)

		character_util.set_position(self.bikini_invaders[i], invader_pos_list[i])

		if val == 0 then
			character_util.set_direction(self.bikini_invaders[i], 'left')
		else
			character_util.set_direction(self.bikini_invaders[i], 'right')
		end

		character_util.set_anim(self.bikini_invaders[i], { name = 'victory_extra' })
	end

	self.android_head = optimized_npcs['android_head']

	field_ui_manager:RemoveUI(self.android_head, CS.Oak.FieldUiType.CharacterStats)
	self.android_head.SpineController:SetSortingLayer("Default", 1)
	character_util.set_position(self.android_head,
			self.bikini_invaders[0].Position + vector(-self.ball_dist, self.ball_dist, 0))

	-- 이펙트 로드 대기
	while not object_pool_extensions.IsLoaded(scoop_effect_pool) do
		coroutine.yield(nil)
	end

	if not stage_progress:GetCustomData(self.stage_custom_state.dead_body, false) then
		self.scoop_effect_1 = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(7, 0, 17.5))
	end

	if stage_progress:GetCustomData(self.stage_custom_state.bikini_invader, false) then
		for i = 0, self.gatekeepers.Count - 1 do
			self.gatekeepers[i].Interactable:RemoveRelatedEvent(self.cs_controller)
			character_util.set_position(self.gatekeepers[i], vector(3, 0, -15 - i))
			character_util.set_direction(self.gatekeepers[i], 'right')
			character_util.set_anim(self.gatekeepers[i], { name = 'sing' })
			character_util.set_emotion(self.gatekeepers[i], { name = 'love' })
		end
	end

	-- 시체 충돌 처리를 위해 가상 오브젝트를 만들어서 Field에 추가함
	local dead_body_virtual_obj = CS.Oak.VirtualFieldObject()
	dead_body_virtual_obj.Position = vector(7.2, 0, 16.3)
	dead_body_virtual_obj.Hitbox = CS.Oak.Hitbox(vector(3.6, 3, 1.3))
	dead_body_virtual_obj.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	dead_body_virtual_obj.ActiveState = CS.Oak.ActiveState.InField
	message_system:Send(dead_body_virtual_obj, CS.Oak.AddFieldObjectEvent.Create(dead_body_virtual_obj))
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.android_head = nil

	if self.gatekeepers ~= nil then
		for i = 0, self.gatekeepers.Count - 1 do
			if self.gatekeepers[i].Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				self.gatekeepers[i].Interactable:RemoveRelatedEvent(self.cs_controller)
			end
		end

		self.gatekeepers = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.dead_bodies ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.dead_bodies)
		self.dead_bodies = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.bikini_invaders ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.bikini_invaders)
		self.bikini_invaders = nil
	end

	if self.scoop_effect_1 ~= nil then
		self.scoop_effect_1:Dispose()
		self.scoop_effect_1 = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ball_event, self))
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.dead_body_event_zone_name then
		if not self.enter_dead_body_zone then
			self.enter_dead_body_zone = true
		end
	elseif zone_name == self.bikini_invader_event_zone_name then
		if not self.enter_bikini_invader_zone then
			music_player_util.play_sfx({ sfx_name = '01_crowd_shout_03' })

			self.enter_bikini_invader_zone = true

			speech_bubble_util.show_speech_bubble(self.bikini_invaders[3], { key = 'invader_gatekeeper_16' })
		end
	end
end

function local_class:on_interact_event(e)
	for i = 0, self.gatekeepers.Count - 1 do
		if lua_helper.reference_equals(e.Target, self.gatekeepers[i]) then
			sp_util.play_normal_screenplay(self.talk_with_gatekeeper, self)
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if not self.get_bikini_invader_photo and e.Params[0] == self.get_photo_bikini_invader_event then
			self.get_bikini_invader_photo = true
		elseif e.Params[0] == self.get_photo_dead_body then
			self.scoop_effect_1:Dispose()
			self.scoop_effect_1 = nil
		end
	end
end

-- 인베이더 경비병들과 대화하는 이벤트
function local_class:talk_with_gatekeeper()
	party_util.align_party(vector(12, 0, 0.5), 'left', 1)

	if not self.see_intro then
		self.see_intro = true

		music_player_util.play_sfx({ sfx_name = '02_goblin_hit_01' })

		character_util.set_anim(self.gatekeepers[0], { name = 'shoot' })
		character_util.set_emotion(self.gatekeepers[0], { name = 'attack' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_0', skip = true })

		character_util.remove_anim(self.gatekeepers[0])
		character_util.remove_emotion(self.gatekeepers[0])
	end

	-- 선택지
	local wait_for_branch = true
	local selection = 0

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	local talk_branch_1 = {
		Text = game_string:GetString("invader_gatekeeper_1"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
		end}

	local talk_branch_2

	if self.enter_dead_body_zone then
		talk_branch_2 = {
			Text = game_string:GetString("invader_gatekeeper_4"),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait_for_branch = false
				selection = 1
			end}

		branches:Add(talk_branch_2)
	end

	local talk_branch_3

	if self.enter_bikini_invader_zone then
		talk_branch_3 = {
			Text = game_string:GetString("invader_gatekeeper_7"),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait_for_branch = false
				selection = 2
			end}

		branches:Add(talk_branch_3)
	end

	branches:Add(talk_branch_1)

	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = user_party_leader
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	if selection == 0 then
		character_util.set_emotion(self.gatekeepers[0], { name = 'attack' })

		character_util.set_anim(self.gatekeepers[1], { name = 'release', sfx_name = '01_swing_01' })
		character_util.set_emotion(self.gatekeepers[1], { name = 'attack' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_2', skip = true })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

		character_util.set_anim(self.gatekeepers[0], { name = 'attack', sfx_name = '01_swing_01' })

		character_util.remove_anim(self.gatekeepers[1])

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_3', skip = true })

		self:go_back()
	elseif selection == 1 then
		character_util.set_emotion(self.gatekeepers[0], { name = 'attack' })

		character_util.set_emotion(self.gatekeepers[1], { name = 'attack' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_5', skip = true })

		character_util.set_anim(self.gatekeepers[0], { name = 'bomb_idle' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_6', skip = true })

		self:go_back()
	else
		for i = 0, self.gatekeepers.Count - 1 do
			character_util.set_emotion(self.gatekeepers[i], { name = 'attack' })
		end

		character_util.set_anim(self.gatekeepers[1], { name = 'cast2' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_8', skip = true })

		character_util.set_anim(self.gatekeepers[0], { name = 'cross_arm' })

		speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_9', skip = true })

		for i = 0, self.gatekeepers.Count - 1 do
			character_util.remove_anim(self.gatekeepers[i])
		end

		-- 선택지
		wait_for_branch = true
		selection = 0

		branches:Clear()

		talk_branch_1 = {
			Text = game_string:GetString("invader_gatekeeper_9_1"),
			Tendency = CS.Oak.TalkTendency.Force,
			Callback = function()
				wait_for_branch = false
			end}

		branches:Add(talk_branch_1)

		talk_branch_2 = nil

		if self.get_bikini_invader_photo then
			talk_branch_2 = {
				Text = game_string:GetString("invader_gatekeeper_10"),
				Tendency = CS.Oak.TalkTendency.Intellect,
				Callback = function()
					selection = 1
					wait_for_branch = false
				end}

			branches:Add(talk_branch_2)
		end

		talk_branch_3 = {
			Text = game_string:GetString("invader_gatekeeper_12_1"),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				selection = 2
				wait_for_branch = false
			end}

		branches:Add(talk_branch_3)

		choice_state = CS.Oak.UI.AnswerChoiceState()
		choice_state.Branchs = branches
		choice_state.Talker = user_party_leader
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		if selection == 0 then
			character_util.set_anim(user_party_leader, { name = 'sing' })

			wait_for_sec(1)

			character_util.set_anim(user_party_leader, { name = 'cast' })
			character_util.set_emotion(user_party_leader, { name = 'tired' })

			for i = 0, self.gatekeepers.Count - 1 do
				character_util.set_emotion(self.gatekeepers[i], { name = 'attack' })
			end

			character_util.set_anim(self.gatekeepers[0], { name = 'cross_arm' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_9_2', skip = true })

			character_util.set_anim(self.gatekeepers[1], { name = 'release', sfx_name = '01_swing_01' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_9_3', skip = true })

			self:go_back()
		elseif selection == 1 then
			music_player_util.play_sfx({ sfx_name = '01_turn_page_02' })

			character_util.set_anim(user_party_leader, { name = 'push' })

			for i = 0, self.gatekeepers.Count - 1 do
				character_util.set_anim(self.gatekeepers[i], { name = 'push' })
				character_util.remove_emotion(self.gatekeepers[i])
			end

			wait_for_sec(1)

			character_util.set_anim(user_party_leader, { name = 'cast' })
			character_util.set_emotion(user_party_leader, { name = 'tired' })

			for i = 0, self.gatekeepers.Count - 1 do
				character_util.set_emotion(self.gatekeepers[i], { name = 'attack' })
			end

			character_util.set_anim(self.gatekeepers[0], { name = 'release', sfx_name = '01_swing_01' })

			character_util.set_anim(self.gatekeepers[1], { name = 'cross_arm' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_11', skip = true })

			character_util.remove_anim(self.gatekeepers[0])

			character_util.set_anim(self.gatekeepers[1], { name = 'cross_arm' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_12', skip = true })

			self:go_back()
		else
			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02' })

			for i = 0, self.gatekeepers.Count - 1 do
				character_util.set_anim(self.gatekeepers[i], { name = 'cast' })
				character_util.set_emotion(self.gatekeepers[i], { name = 'surprise' })
			end

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_12_2', skip = true })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_12_3', skip = true })

			for i = 0, self.gatekeepers.Count - 1 do
				character_util.remove_anim(self.gatekeepers[i])
				character_util.remove_emotion(self.gatekeepers[i])
			end

			character_util.show_emoticon(self.gatekeepers[0], nil, 'silence')
			character_util.show_emoticon_async(self.gatekeepers[1], nil, 'silence')

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_12_4', skip = true })

			character_util.set_anim(self.gatekeepers[0], { name = 'release', sfx_name = '01_swing_01' })
			character_util.set_emotion(self.gatekeepers[0], { name = 'attack' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[0], { key = 'invader_gatekeeper_12_5', skip = true })

			character_util.set_anim(self.gatekeepers[0], { name = 'walk' })
			character_util.remove_emotion(self.gatekeepers[0])

			local waypoint_list_1 = create_generic_list(unity_class.vector3)
			waypoint_list_1:Add(self.gatekeepers[0].Position + vector(-5.5, 0, 0))
			waypoint_list_1:Add(self.gatekeepers[0].Position + vector(-5.5, 0, -6))

			character_util.set_anim(self.gatekeepers[0], { name = 'run' })
			character_util.move_waypoint(self.gatekeepers[0], waypoint_list_1,
					6, false, 'stop', 'floor', 'down', true)

			wait_for_sec(1)

			music_player_util.play_sfx({ sfx_name = '01_player_jump_01' })

			character_util.jump(self.gatekeepers[1], 1, 0.5)
			character_util.set_anim(self.gatekeepers[1], { name = 'cast2' })
			character_util.set_emotion(self.gatekeepers[1], { name = 'attack' })

			speech_bubble_util.show_speech_bubble_async(self.gatekeepers[1], { key = 'invader_gatekeeper_12_6', skip = true })

			character_util.set_anim(self.gatekeepers[1], { name = 'walk' })
			character_util.remove_emotion(self.gatekeepers[1])

			local waypoint_list_2 = create_generic_list(unity_class.vector3)
			waypoint_list_2:Add(self.gatekeepers[1].Position + vector(-5.5, 0, 0))
			waypoint_list_2:Add(self.gatekeepers[1].Position + vector(-5.5, 0, -6))

			character_util.set_anim(self.gatekeepers[1], { name = 'run' })
			character_util.move_waypoint_async(self.gatekeepers[1], waypoint_list_2,
					6, false, 'stop', 'floor', 'down', true)

			for i = 0, self.gatekeepers.Count - 1 do
				self.gatekeepers[i].Interactable:RemoveRelatedEvent(self.cs_controller)
				character_util.set_position(self.gatekeepers[i], vector(3, 0, -15 - i))
				character_util.set_direction(self.gatekeepers[i], 'right')
				character_util.set_anim(self.gatekeepers[i], { name = 'sing' })
				character_util.set_emotion(self.gatekeepers[i], { name = 'love' })
			end

			-- 스테이지 커스텀 스테이트 저장
			stage_progress:SendCustomData(self.stage_custom_state.bikini_invader, true)
		end
	end
end

-- 퇴장당하는 연출
function local_class:go_back()
	character_util.remove_emotion(user_party_leader)

	for i = 0, self.gatekeepers.Count - 1 do
		character_util.remove_anim(self.gatekeepers[i])
		character_util.remove_emotion(self.gatekeepers[i])
	end

	character_util.move_to_async(user_party_leader, user_party_leader.Position + vector(-1, 0, 0),
			0.5, nil, true, true)
end

-- 인베이더들이 공 차는 이벤트
function local_class:ball_event()
	local start_index = 0
	local end_index
	local forward = true

	local talk_count = 0
	local talk_count_max = 7

	local talk_first = false

	while true do
		-- 공 찰 상대 설정
		if forward then
			end_index = math.floor(unity_class.random.Range(3, 6))
		else
			end_index = math.floor(unity_class.random.Range(0, 3))
		end

		-- 공 높이 설정
		local ball_height = 3 + unity_class.random.Range(-0.5, 2)

		-- 대화 처리
		talk_count = talk_count + 1

		-- 대화 중복 막기
		if not talk_first and self.enter_bikini_invader_zone then
			talk_first = true
		else
			if talk_count == math.floor(talk_count_max / 2) then
				speech_bubble_util.show_speech_bubble(self.bikini_invaders[start_index], { key = 'invader_gatekeeper_14' })
			end
		end

		coroutine.yield(self:kick_ball(self.bikini_invaders[start_index], self.bikini_invaders[end_index], ball_height, forward))

		start_index = end_index

		if forward then
			forward = false
		else
			forward = true
		end

		-- 대화 중복 막기
		if not talk_first and self.enter_bikini_invader_zone then
			talk_first = true
		else
			if talk_count == talk_count_max then
				talk_count = 0

				speech_bubble_util.show_speech_bubble(self.bikini_invaders[start_index], { key = 'invader_gatekeeper_15' })
			end
		end

		wait_for_sec(0.3)
	end
end

-- 공 차는 연출
function local_class:kick_ball(kicker, getter, height, forward)
	local cur_time = unity_class.time.time
	local kick_duration = 1

	local mod

	if forward then
		mod = -1
	else
		mod = 1
	end

	local start_pos = kicker.Position + vector(self.ball_dist * mod, 0, 0)
	local end_pos = getter.Position + vector(self.ball_dist * -mod, 0, 0)

	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', parent = kicker })

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			self.android_head.Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			self.android_head.Position + vector(0, 0.3, 0))

	character_util.set_anim(kicker, { name = 'bomb_attack', loop = false, next_anim = 'victory_extra' })

	local rand_angle = unity_class.random.Range(0, 90)

	character_util.spine_rotate(self.android_head, rand_angle * mod, kick_duration)

	while unity_class.time.time - cur_time < kick_duration do
		local normalized = (unity_class.time.time - cur_time) / kick_duration

		local cur_x = start_pos.x + (end_pos.x - start_pos.x) * normalized
		local cur_y = self.ball_dist + normalized * (normalized - kick_duration) * -4 * height / (kick_duration * kick_duration)
		local cur_z = start_pos.z + (end_pos.z - start_pos.z) * normalized

		character_util.set_position(self.android_head, vector(cur_x, cur_y, cur_z), true)

		coroutine.yield(nil)
	end

	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			self.android_head.Position + vector(0, 0.3, 0))

	character_util.set_position(self.android_head, end_pos)

	character_util.set_anim(getter, { name = 'push' })
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
