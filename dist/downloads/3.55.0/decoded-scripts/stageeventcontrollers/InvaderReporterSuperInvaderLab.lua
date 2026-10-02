local local_class = newclass("InvaderReporterSuperInvaderLabController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.victim = nil

	self.super_invader = nil

	self.scientists = nil

	-- 리소스 홀더
	self.resholder = nil

	-- 고깃덩이 이펙트
	self.meat_part_obj = nil

	-- 중복 감지 방지 플래그
	self.is_detected = false

	-- Shake 중단 플래그
	self.stop_shake = false

	-- 사진 촬영 Effect
	self.scoop_effect = nil

	self.event_state = {
		-- 이벤트 보기 전 상태
		idle = 0,
		-- 피해자와 대화 시작
		is_talk_with_victim = 1,
		-- 과학자들 입장 시작
		enter_scientist = 2,
		-- 플레이어 단차로 올라감
		move_upper = 3,
		-- 이벤트 시작
		event_started = 4,
		-- 종료
		ending = 5
	}

	self.current_event_state = self.event_state.idle

	-- 스테이지 커스텀 State
	self.stage_custom_state = {
		super_invader = 4
	}

	-- 기타 상수
	self.left_door_num = 2
	self.right_door_num = 2
	self.scientist_num = 2

	-- 타일맵 NPC 이름
	self.victim_name = 'invader_victim'
	self.super_invader_name = 'super_invader'
	self.scientist_name = 'super_invader_scientist_'

	-- 타일맵 필드오브젝트 이름
	self.right_door_name = 'lab_right_door_'
	self.left_door_name = 'lab_left_door_'

	-- 타일맵 존 이름
	self.upper_event_zone_name_1 = 'super_invader_lab_upper_1'
	self.upper_event_zone_name_2 = 'super_invader_lab_upper_2'
	self.lab_event_zone_name = 'super_invader_lab_start'
	self.super_invader_attack_zone_name = 'super_invader_attack'

	-- 타일맵 마커 이름
	self.reset_marker_name = 'reset_12'

	-- 커스텀 이벤트 이름
	self.detected_event = 'scientist_detected'
	self.get_photo = 'get_photo12'
	self.cancel_camera_event = 'cancel_camera'
	self.take_picture_super_invader = 'take_picture_super_invader'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.scoop_effect_preset = 'invader_reporter_scoop_target'
end

function local_class:load_resource()
	--unity_object_pool.GetOrCreate("FX_hit")

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.victim = get_character(self.victim_name)
	self.victim.Interactable:AddListener(self.cs_controller)

	self.super_invader = get_character(self.super_invader_name)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local scoop_effect_pool = unity_object_pool.GetOrCreate(self.scoop_effect_preset)

	self.scientists = create_generic_list(CS.Oak.Character)

	for i = 1, self.scientist_num do
		local cur_scientist = get_character(self.scientist_name..i)
		cur_scientist.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		self.scientists:Add(cur_scientist)
	end

	-- 고기조각 이펙트 로드
	self.resholder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_3_futurecastle/effects/futurecastle', 'fx_event_meat_part', function(prefab)
				self.meat_part_obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.meat_part_obj:SetActive(false)
			end)

	-- 이펙트 로드 대기
	while not object_pool_extensions.IsLoaded(scoop_effect_pool) do
		coroutine.yield(nil)
	end

	self.scoop_effect = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(-18, 0, 39))
	self.scoop_effect.transform.gameObject:SetActive(false)

	if stage_progress:GetCustomData(self.stage_custom_state.super_invader, false) then
		self.current_event_state = self.event_state.ending

		self:set_end()
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.victim = nil
	self.super_invader = nil

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.scientists ~= nil and self.scientists == true then
		load_util.dispose_optimized_npcs(self.scientists)
		self.scientists = nil
	end

	if self.scoop_effect ~= nil then
		self.scoop_effect:Dispose()
		self.scoop_effect = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		if self.current_event_state ~= self.event_state.ending then
			character_util.set_anim(self.victim, { name = 'prostrate' })
			character_util.set_emotion(self.victim, { name = 'confused' })
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.upper_event_zone_name_1 or zone_name == self.upper_event_zone_name_2 then
		if self.current_event_state == self.event_state.enter_scientist then
			self.current_event_state = self.event_state.move_upper

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.super_invader_event, self))
		end
	elseif zone_name == self.lab_event_zone_name then
		if self.current_event_state == self.event_state.move_upper then
			self.current_event_state = self.event_state.event_started
		end
	elseif zone_name == self.super_invader_attack_zone_name then
		if self.current_event_state == self.event_state.ending then
			sp_util.play_normal_screenplay(self.super_invader_attack_event, self)
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.victim) then
		self.current_event_state = self.event_state.is_talk_with_victim

		sp_util.play_normal_screenplay(self.talk_with_victim, self)
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 2 then
		if not self.is_detected and e.Params[0] == self.detected_event then
			self.is_detected = true

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.scientist_detect_event, self, e.Sender))
		end
	elseif e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.get_photo then
			self.scoop_effect:Dispose()
			self.scoop_effect = nil
		end
	end
end

-- 희생자와 대화
function local_class:talk_with_victim()
	party_util.align_party(self.victim.Position, 'right', 1)

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.shake(self.victim, 0.04, 1)

	wait_for_sec(1)

	camera_util.shake(0.2, 0.3)

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.jump(self.victim, 1, 0.5)
	character_util.set_anim(self.victim, { name = 'embarrassed' })
	character_util.set_emotion(self.victim, { name = 'damaged' })

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_0', skip = true })

	character_util.set_anim(self.victim, { name = 'walk4legs' })

	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_1', skip = true })

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.jump(self.victim, 1, 0.5)
	character_util.set_anim(self.victim, { name = 'cast' })

	wait_for_sec(0.5)

	character_util.set_direction(user_party_leader, 'right')

	camera_util.move(vector(-8, 0, 37.5), 1, { ignorecameragrids = true })

	for i = 0, self.scientists.Count - 1 do
		character_util.set_position(self.scientists[i], vector(-3, 0, 38.5 - 2 * i))
		character_util.set_direction(self.scientists[i], 'left')
		character_util.set_anim(self.scientists[i], { name = 'walk' })

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.move_with_detect, self, self.scientists[i], self.scientists[i].Position + vector(-4, 0, 0), 4))
	end

	wait_for_sec(2)

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.right_door_name..i, false))
	end

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	character_util.set_direction(user_party_leader, 'left')

	character_util.set_anim(self.victim, { name = 'embarrassed' })

	music_player:PlaySfxOneShot('03_runaway_01')
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')

	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_2', skip = true })

	self.current_event_state = self.event_state.enter_scientist

	self.victim.Interactable:RemoveRelatedEvent(self.cs_controller)

	-- 과학자들 이동 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_scientist, self))

	self.stop_shake = false

	-- TimeScale이 0일 때 작동하지 않는 진동 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shake_repeat, self, self.victim))
end

-- 감시 캐릭터 걸어옴
function local_class:move_with_detect(character, pos, duration)
	character.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
			character, self.detected_event, 4.5, 150)

	character_util.set_anim(character, { name = 'walk' })

	local cur_time = unity_class.time.time
	local move_duration = duration

	local start_pos = character.Position
	local end_pos = pos

	while not self.is_detected and self.current_event_state < self.event_state.move_upper and unity_class.time.time - cur_time < move_duration do
		local normalized = (unity_class.time.time - cur_time) / move_duration

		character.Position = vector(start_pos.x + (end_pos.x - start_pos.x) * normalized,
				start_pos.y + (end_pos.y - start_pos.y) * normalized,
				start_pos.z + (end_pos.z - start_pos.z) * normalized)

		coroutine.yield(nil)
	end

	if not self.is_detected and self.current_event_state < self.event_state.move_upper then
		character.Position = end_pos
		character_util.remove_anim(character)
	elseif self.current_event_state >= self.event_state.move_upper then
		character_util.set_position(character, character.Position)
		character_util.remove_anim(character)
	end
end

-- 과학자들 이동 처리, 플레이어가 단차로 올라가기 전에는 맵 끝까지 이동, 단차로 올라가거나 발각 시 이동 종료
function local_class:move_scientist()
	for i = 0, self.scientists.Count - 1 do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.move_with_detect, self, self.scientists[i], self.scientists[i].Position + vector(-4, 0, 0), 2))
	end

	wait_for_sec(2)

	coroutine.yield(nil)

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.right_door_name..i, false))
	end

	wait_for_sec(2.5)

	if self.current_event_state < self.event_state.move_upper then
		for i = 0, self.scientists.Count - 1 do
			character_util.set_anim(self.scientists[i], { name = 'walk' })

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.move_with_detect, self, self.scientists[i], self.scientists[i].Position + vector(-10, 0, 0), 5))
		end
	end
end

-- 진동 반복
function local_class:shake_repeat(character)
	local base_pos = character.Position

	local timer = 0
	local duration = 0

	while not self.stop_shake do
		timer = timer + unity_class.time.deltaTime

		if timer > duration then
			timer = 0

			local rand_x = unity_class.random.Range(0, 0.04)
			local rand_z = unity_class.random.Range(0, 0.04)

			local cur_pos = base_pos + vector(rand_x, 0, rand_z)

			character_util.set_position(character, cur_pos)
		end

		coroutine.yield(nil)
	end

	character_util.set_position(character, base_pos)
end

-- 인베이더 과학자에게 발각된 경우 발생하는 이벤트
function local_class:scientist_detect_event(detector)
	local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

	user_party:StopAndDisableControl()

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.cancel_camera_event }))

	field:Tint("alert_max", unity_class.color(1, 0, 0), 0.25)

	camera_util.shake(0.07, 0.25)

	for i = 0, user_party.Count -1 do
		character_util.set_anim(user_party[i], { name = "embarrassed", loop = true })
		character_util.set_emotion(user_party[i], { name = "surprise", loop = true})

		if i == 0 then
			user_party[i].SpineController:Jump(0.3, 0.2)
		end
	end

	character_util.set_anim(detector, { name = "embarrassed" })

	speech_bubble_util.show_speech_bubble_async(detector,
			{ key = "invader_reporter_super_invader_lab_guard_alert", skip = "true", bubble_type = "shout", skip = true })

	wait_for_sec(0.25)

	screen_util.fade_out_circular(0.5, 'linear')

	wait_for_sec(1.0)
	siren:FadeOut(0.5)

	field:RemoveTint("alert_max", 0)

	local respawn_pos = field:GetMarker(self.reset_marker_name).position
	local respawn_dir = field:GetMarker(self.reset_marker_name).direction

	user_party:PositionParty(respawn_pos, respawn_dir, 0, 'linear')

	for i = 0, user_party.Count -1 do
		character_util.remove_anim(user_party[i], false)
		character_util.remove_emotion(user_party[i])
	end

	stage_camera:SetTarget(user_party_leader)

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.right_door_name..i))
	end

	for i = 1, self.left_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.left_door_name..i))
	end

	self.victim.Interactable:AddListener(self.cs_controller)
	character_util.set_anim(self.victim, { name = 'prostrate' })
	character_util.set_emotion(self.victim, { name = 'confused' })

	for i = 0, self.scientists.Count - 1 do
		character_util.set_position(self.scientists[i], vector(999, 0, 999))
	end

	wait_for_sec(0.5)

	screen_util.fade_in_circular(0.5, 'linear')

	wait_for_sec(0.5)

	self.is_detected = false

	self.stop_shake = true

	self.current_event_state = self.event_state.idle

	user_party:ResetControllers()
end

-- 플레이어가 단차 올라오면 이벤트 진행
function local_class:super_invader_event()
	for i = 1, self.left_door_num do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.left_door_name..i))
	end

	coroutine.yield(nil)

	-- 순찰 종료
	local waypoint_list_1 = create_generic_list(unity_class.vector3)
	waypoint_list_1:Add(vector(-17, 0, 38.5))
	waypoint_list_1:Add(vector(-17, 0, 37.5))

	character_util.set_anim(self.scientists[0], { name = 'walk' })
	character_util.move_waypoint(self.scientists[0], waypoint_list_1,
			3, false, 'stop', 'floor', 'left')

	local waypoint_list_2 = create_generic_list(unity_class.vector3)
	waypoint_list_2:Add(vector(-19, 0, 36.5))
	waypoint_list_2:Add(vector(-19, 0, 37.5))

	character_util.set_anim(self.scientists[1], { name = 'walk' })
	character_util.move_waypoint(self.scientists[1], waypoint_list_2,
			3, false, 'stop', 'floor', 'right')

	character_util.set_anim(self.victim, { name = 'cast' })

	wait_for_sec(0.5)

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.right_door_name..i))
	end

	local move_finished = false

	while not move_finished do
		move_finished = true

		for i = 0, self.scientists.Count - 1 do
			if self.scientists[i].CharacterBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped then
				move_finished = false
			end
		end

		coroutine.yield(nil)
	end

	for i = 0, self.scientists.Count - 1 do
		self.scientists[i].CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		character_util.remove_anim(self.scientists[i])
	end

	-- 카메라 포인터가 이벤트 위치에 올 때까지 대기
	while self.current_event_state ~= self.event_state.event_started do
		coroutine.yield(nil)
	end

	character_util.set_direction(self.victim, 'left')

	wait_for_sec(0.7)

	character_util.set_direction(self.victim, 'right')

	wait_for_sec(0.7)

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_3' })

	character_util.set_anim(self.scientists[0], { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_4' })

	character_util.remove_anim(self.scientists[0])

	character_util.set_anim(self.scientists[1], { name = 'cast' })
	character_util.set_emotion(self.scientists[1], { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_5' })

	character_util.set_anim(self.scientists[0], { name = 'shoot' })
	character_util.set_emotion(self.scientists[0], { name = 'attack' })

	character_util.jump(self.scientists[1], 0.5, 0.3)
	character_util.remove_anim(self.scientists[1])
	character_util.remove_emotion(self.scientists[1])

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = self.scientists[0]})
	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_6' })

	character_util.set_anim(self.scientists[0], { name = 'cast' })
	character_util.set_emotion(self.scientists[0], { name = 'tired' })

	character_util.set_anim(self.scientists[1], { name = 'cast' })
	character_util.set_emotion(self.scientists[1], { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_7' })

	character_util.set_anim(self.scientists[0], { name = 'release', sfx_name = '01_swing_01' })
	character_util.remove_emotion(self.scientists[0])

	character_util.set_anim(self.scientists[1], { name = 'nod' })
	character_util.remove_emotion(self.scientists[1])

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_8' })

	character_util.remove_anim(self.scientists[0])
	character_util.remove_emotion(self.scientists[0])

	character_util.move_to_async(self.scientists[1], self.scientists[1].Position + vector(0.5, 0, 0),
			0.5, nil, true, true)

	character_util.set_anim(self.scientists[1], { name = 'push' })

	self.stop_shake = true

	character_util.jump(self.victim, 0.5, 0.3)
	character_util.set_anim(self.victim, { name = 'embarrassed' })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = self.victim})
	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = self.victim})
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_9' })

	character_util.set_anim(self.scientists[0], { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_10' })

	music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = self.victim})
	character_util.jump(self.victim, 0.5, 0.3)

	wait_for_sec(0.3)

	music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = self.victim})
	character_util.jump(self.victim, 0.5, 0.3)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.victim})
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_11' })

	character_util.set_direction(self.scientists[0], 'right')
	character_util.set_anim(self.scientists[0], { name = 'eat' })
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true,
									 type_priority = 'event', player_priority = 'npc', parent = self.scientists[0] })

	wait_for_sec(1)

	eat_sfx:Stop()
	character_util.set_direction(self.scientists[0], 'left')
	character_util.set_anim(self.scientists[0], { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_12' })

	character_util.spine_deviate_local(self.scientists[0], vector(-0.5, 0, 0), 0.3, 0.2)
	character_util.set_anim(self.scientists[0], { name = 'spear_attack', loop = false, scale = 0.3, next_anim = 'idle' })

	wait_for_sec(0.3)

	music_player_util.play_sfx({ sfx_name = '02_magic_heal_02', parent = self.victim})
	character_util.spine_pulse_color(self.victim, CS.Oak.Constants.DamageColor, 1, 3, 1)
	character_util.spine_damage_squish(self.victim, 1.5, 0.7, 1, 1)

	wait_for_sec(0.5)

	character_util.move_to_async(self.scientists[1], self.scientists[1].Position + vector(-0.5, 0, 0),
			0.5, nil, false, true)

	character_util.set_anim(self.victim, { name = 'embarrassed', scale = 0.7 })

	wait_for_sec(0.5)

	character_util.set_anim(self.victim, { name = 'embarrassed', scale = 0.5 })

	wait_for_sec(0.75)

	character_util.set_anim(self.victim, { name = 'embarrassed', scale = 0.3 })

	wait_for_sec(0.5)

	character_util.set_anim(self.victim, { name = 'dead', loop = false })

	wait_for_sec(2)

	music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = self.victim})

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = self.scientists[1]})
	character_util.set_anim(self.scientists[1], { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_13' })

	music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = self.scientists[0]})
	character_util.jump(self.scientists[0], 1, 0.5)
	character_util.set_anim(self.scientists[0], { name = 'cast2' })
	character_util.set_emotion(self.scientists[0], { name = 'attack' })

	character_util.remove_anim(self.scientists[1])

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_14' })

	wait_for_sec(0.5)

	camera_util.shake(0.1, 9999)

	for i = 0, self.scientists.Count - 1 do
		character_util.jump(self.scientists[i], 0.5, 0.3)
		character_util.set_anim(self.scientists[i], { name = 'cast' })
		character_util.set_emotion(self.scientists[i], { name = 'damaged' })
	end

	self.stop_shake = false

	character_util.jump(self.victim, 1, 0.5)

	-- TimeScale이 0일 때 작동하지 않는 진동 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shake_repeat, self, self.victim))

	music_player_util.play_stage_music({state = 'muted', mix = 2})
	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_02', parent = self.victim})
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_15', bubble_type = 'shout' })

	camera_util.cancel_shake()

	local earthquake_sfx = music_player_util.play_sfx(
			{sfx_name = '01_earthquake_03', loop = true, type_priority = 'event', player_priority = 'npc'})

	camera_util.shake(0.2, 9999)

	self.victim.SpineController:AddColor(self.victim.Name, unity_color({0, 0, 0, 1}), 1, 1)
	character_util.set_anim(self.victim, { name = 'embarrassed' })
	character_util.set_emotion(self.victim, { name = 'mad' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.meat_part_obj_repeat, self))

	music_player_util.play_sfx({ sfx_name = '01_villain_scream_03', parent = self.victim})
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_16', bubble_type = 'shout' })

	music_player_util.play_sfx({ sfx_name = '01_camera_emphasize_01', parent = self.victim})
	speech_bubble_util.show_speech_bubble_async(self.victim, { key = 'invader_reporter_super_invader_lab_17', bubble_type = 'shout' })

	wait_for_sec(0.5)

	music_player_util.play_stage_music({state = 'field', mix = 2})
	earthquake_sfx:FadeOut(2)
	screen_util.fade_out_async(0.5, unity_class.color.red, 'linear')

	self.stop_shake = true

	camera_util.cancel_shake()

	character_util.set_position(self.super_invader, self.victim.Position)
	character_util.set_direction(self.super_invader, 'right')

	character_util.set_position(self.scientists[0], vector(-15, 0, 37.5))

	character_util.set_position(self.scientists[1], vector(-20, 0, 37.5))

	character_util.set_active_state(self.victim, 'disabled')

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.red, 'linear')

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_18' })

	character_util.set_anim(self.scientists[0], { name = 'sing' })
	character_util.set_emotion(self.scientists[0], { name = 'smile' })

	character_util.set_anim(self.scientists[1], { name = 'cast' })
	character_util.set_emotion(self.scientists[1], { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_19' })

	character_util.move_to_async(self.scientists[0], self.scientists[0].Position + vector(-1, 0, 0),
			1, nil, true, true)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = self.victim})
	character_util.set_anim(self.scientists[0], { name = 'success', sfx_name = '01_jump_01' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_20' })

	character_util.set_direction(self.scientists[0], 'right')
	character_util.set_anim(self.scientists[0], { name = 'victory_get', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.scientists[0], { key = 'invader_reporter_super_invader_lab_21' })

	character_util.set_anim(self.super_invader, { name = 'attack1', loop = false, next_anim = 'idle' })

	wait_for_sec(0.7)

	self.scoop_effect.transform.gameObject:SetActive(true)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.take_picture_super_invader }))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_meat_effect, self, self.scientists[0].Position))

	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_02', parent = self.super_invader})
	music_player_util.play_sfx({ sfx_name = '02_hit_harvester_01', parent = self.super_invader})
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			self.scientists[0].Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			self.scientists[0].Position + vector(0, 0.3, 0))

	camera_util.shake(0.4, 0.5)

	field_ui_manager:RemoveUI(self.scientists[0], CS.Oak.FieldUiType.CharacterStats)
	self.scientists[0].SpineController:SetSortingLayer('Default', -1)
	self.scientists[0].SpineController:AddColor(self.scientists[0].Name, unity_color({0, 0, 0, 1}), 1, 0.3)
	character_util.set_anim(self.scientists[0], { name = 'frustration', loop = false })
	character_util.set_emotion(self.scientists[0], { name = 'damaged' })

	local knock_back_info = character_util.knockback_info('physics', true, {1, 0, 0},
			50000, 0.05, CS.Oak.Constants.DefaultFrictionCoefficient)

	command_util.publish_knock_back(user_party_leader.Owner, self.scientists[0], knock_back_info, nil)

	character_util.jump(self.scientists[1], 1, 0.5)
	character_util.set_anim(self.scientists[1], { name = 'embarrassed' })
	character_util.set_emotion(self.scientists[1], { name = 'damaged' })

	wait_for_sec(0.8)

	character_util.move_to_async(self.super_invader, self.super_invader.Position + vector(2.5, 0, 0),
			1, nil, true, true)

	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_03', parent = self.super_invader})
	character_util.set_anim(self.super_invader, { name = 'eat' })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = self.scientists[1]})
	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_22' })

	character_util.set_anim(self.scientists[1], { name = 'run' })
	character_util.move_to_async(self.scientists[1], self.scientists[1].Position + vector(-2, 0, 0),
			nil, 6, true, false, true)

	character_util.set_direction(self.super_invader, 'left')
	character_util.remove_anim(self.super_invader)

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', parent = self.scientists[1]})
	character_util.jump(self.scientists[1], 1, 0.5)
	character_util.set_anim(self.scientists[1], { name = 'attack', sfx_name = '01_hit_dummy_02' })
	character_util.set_emotion(self.super_invader[1], { name = 'cry' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.scientists[1]})
	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_23' })

	local waypoint_list = create_generic_list(unity_class.vector3)
	waypoint_list:Add(self.super_invader.Position + vector(-1.5, 0, 0))

	character_util.move_waypoint(self.super_invader, waypoint_list,
			1.5, false, 'stop', 'floor', 'left')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.scientists[1]})
	character_util.jump(self.scientists[1], 1, 0.5)
	character_util.set_anim(self.scientists[1], { name = 'cast2' })

	speech_bubble_util.show_speech_bubble_async(self.scientists[1], { key = 'invader_reporter_super_invader_lab_24' })

	move_finished = false

	while not move_finished do
		if self.super_invader.CharacterBehaviour.CurrentAction == CS.Oak.FieldObjectAction.Stopped then
			move_finished = true
		end

		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_03', parent = self.super_invader})
	character_util.set_anim(self.super_invader, { name = 'charging', loop = false, next_anim = 'eat' })
	character_util.move_to(self.super_invader, self.super_invader.Position + vector(-3.5, 0, 0),
			0.5, nil, true, false)

	wait_for_sec(0.3)

	self.stop_shake = true

	coroutine.yield(nil)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_meat_effect, self, self.scientists[1].Position))

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			self.scientists[1].Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			self.scientists[1].Position + vector(0, 0.3, 0))

	camera_util.shake(0.4, 0.5)

	field_ui_manager:RemoveUI(self.scientists[1], CS.Oak.FieldUiType.CharacterStats)
	self.scientists[1].SpineController:SetSortingLayer('Default', -1)
	self.scientists[1].SpineController:AddColor(self.scientists[1].Name, unity_color({0, 0, 0, 1}), 1, 0.3)
	character_util.set_anim(self.scientists[1], { name = 'frustration', loop = false })
	character_util.set_emotion(self.scientists[1], { name = 'damaged' })

	wait_for_sec(1)

	self.current_event_state = self.event_state.ending

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.right_door_name..i, false))
	end

	for i = 0, self.scientists.Count - 1 do
		self.scientists[i].CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end
end

-- 피해자 몸에서 육편 연달아서 튀는 이펙트
function local_class:meat_part_obj_repeat()
	local timer = 1
	local delay = 1

	while not self.stop_shake do
		timer = timer + unity_class.time.deltaTime

		if timer >= delay then
			timer = 0

			music_player_util.play_sfx({ sfx_name = '02_hit_harvester_01', parent = self.victim})
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_meat_effect, self, self.victim.Position))

			character_util.jump(self.victim, 1, 0.5)
		end

		coroutine.yield(nil)
	end
end

-- 육편 튀는 이펙트
function local_class:show_meat_effect(pos)
	self.meat_part_obj.transform.localPosition = pos + vector(0, 0.5, 0)
	self.meat_part_obj:SetActive(true)

	wait_for_sec(0.7)

	self.meat_part_obj:SetActive(false)
end

-- 슈퍼 인베이더 공격 이벤트
function local_class:super_invader_attack_event()
	local super_invader_pos = self.super_invader.Position

	music_player_util.play_sfx({ sfx_name = "03_runaway_01" })

	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_anim(user_party_leader, { name = 'embarrassed' })
	character_util.set_emotion(user_party_leader, { name = 'damaged' })

	character_util.set_direction(self.super_invader, 'right')
	character_util.remove_anim(self.super_invader)

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_03', parent = self.super_invader})
	character_util.set_anim(self.super_invader, { name = 'charging', loop = false })
	character_util.move_to(self.super_invader, user_party_leader.Position, 0.3, nil, true, false)

	screen_util.fade_out_async(0.3, unity_class.color.red, 'linear')

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	screen_util.fade_out_circular_async(0, 'linear')
	screen_util.fade_in_async(0, unity_class.color.black, 'linear')

	character_util.set_position(self.super_invader, super_invader_pos)
	character_util.set_direction(self.super_invader, 'left')
	character_util.set_anim(self.super_invader, { name = 'eat' })

	local respawn_pos = field:GetMarker(self.reset_marker_name).position
	local respawn_dir = field:GetMarker(self.reset_marker_name).direction

	user_party:PositionParty(respawn_pos, respawn_dir, 0, 'linear')

	for i = 0, user_party.Count -1 do
		character_util.remove_anim(user_party[i], false)
		character_util.remove_emotion(user_party[i])
	end

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	user_party:ResetControllers()
end

-- 엔딩 상황 설정
function local_class:set_end()
	character_util.set_active_state(self.victim, 'disabled')

	character_util.set_position(self.super_invader, vector(-20.5, 0, 37.5))
	character_util.set_direction(self.super_invader, 'left')
	character_util.set_anim(self.super_invader, { name = 'eat' })

	for i = 0, self.scientists.Count - 1 do
		field_ui_manager:RemoveUI(self.scientists[i], CS.Oak.FieldUiType.CharacterStats)
		self.scientists[i].SpineController:SetSortingLayer('Default', -1)
		self.scientists[i].SpineController:AddColor(self.scientists[i].Name, unity_color({0, 0, 0, 1}), 1, 0.3)
		character_util.set_anim(self.scientists[i], { name = 'frustration', loop = false })
		character_util.set_emotion(self.scientists[i], { name = 'damaged' })
	end

	character_util.set_position(self.scientists[0], vector(-14, 0, 37.5))
	character_util.set_direction(self.scientists[0], 'right')

	character_util.set_position(self.scientists[1], vector(-22, 0, 37.5))
	character_util.set_direction(self.scientists[1], 'left')

	for i = 1, self.right_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.right_door_name..i))
	end

	for i = 1, self.left_door_num do
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.left_door_name..i))
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
