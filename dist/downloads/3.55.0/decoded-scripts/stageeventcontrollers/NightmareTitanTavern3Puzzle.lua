local local_class = newclass('NightmareTitanTavern3PuzzleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc 이름
	self.mouse_guard_name = 'puzzle_mouse_guard_'
	self.fat_gnome_name = 'fat_gnome'
	self.princess_name = 'princess_gnome_3'

	-- 이벤트 존 이름
	self.tutorial_zone_name = 'puzzle_tutorial_zone'
	self.puzzle_zone_name = 'puzzle_zone_'

	-- 마커 이름
	self.mouse_marker_name = 'puzzle_mouse_pos_'
	self.princess_reset_marker_name = 'puzzle_reset_princess_'
	self.fat_gnome_reset_marker_name = 'puzzle_reset_fat_gnome_'
	self.tutorial_marker_name = 'puzzle_tutorial_pos'

	-- 기믹 이름
	self.brazier_name = 'puzzle_brazier'
	self.bomb_name = 'puzzle_bomb_'
	self.door_name = 'puzzle_door_'
	self.rock_name = 'puzzle_rock_'

	-- 오브젝트 풀 이름
	self.stomp_effect_name = 'FX_minotaur_buttbounce'

	-- 감시 이벤트 이름
	self.detect_event_name = 'detect_mouse_'

	-- 쥐 수
	self.puzzle_mouse_count = { 2, 2, 1, 2 }

	-- 쥐 방향
	self.puzzle_mouse_dir = { 'left', 'right', 'right', 'left' }

	-- 쥐 경비병이 뚱보 노움이 내려찍은 곳으로 가는중인지 (중복 방지)
	self.is_mouse_guard_move_stomp_position_list = {}

	-- 쥐 감시를 멈출 것인지
	self.stop_detecting_list = {}

	-- 쥐 이동을 멈추게 할 것인지
	self.mouse_stop_move_list = {}

	-- 튜토리얼을 봤는지
	self.is_shown_tutorial = false

	-- 쥐한테 들켰는지
	self.detected_party = false

	-- 쥐한테 들킨 캐릭터가 리더인지
	self.detected_leader = true

	self.puzzle_clear_custom_key = 0

	-- 퍼즐을 클리어 했는지
	self.puzzle_clear = false

	-- 쥐 감시 시야, 각도
	self.sight_distance = 4
	self.sight_angle = 60

	-- 퍼즐을 시작했는지
	self.puzzle_start = { false, false, false, false }
end

function local_class:load_resource()
	self.puzzle_clear = stage_progress:GetCustomData(self.puzzle_clear_custom_key)

	if not self.puzzle_clear then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
		message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
		message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
		message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	else
		-- 바위 및 폭탄 제거
		for i = 1, 2 do
			character_util.set_active_state(get_field_object(self.rock_name .. i), 'disabled')
			character_util.set_active_state(get_field_object(self.bomb_name .. i), 'disabled')
		end

		-- 문 열기
		local door_index = { 2, 2, 1 }
		for i = 1, 3 do
			for j = 1, door_index[i] do
				message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name .. i .. '_' .. j))
			end
		end
	end

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	quest_util.load_pool_resource(
		self.stomp_effect_name
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self.puzzle_start = nil

	self.puzzle_mouse_dir = nil
	self.puzzle_mouse_count = nil

	self.is_mouse_guard_move_stomp_position_list = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.tutorial_zone_name) then
		if not self.is_shown_tutorial then
			sp_util.play_normal_screenplay(self.start_tutorial, self)
		end
		return true
	end

	for i = 1, 4 do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.puzzle_zone_name .. i) then
			if self.puzzle_start[i] or not self.is_shown_tutorial then return true end

			self.puzzle_start[i] = true

			self:start_puzzle_setting(vector_util.get_x0z(e.Zone.Bounds.center), i)

			return true
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local zone_name = e.Zone.Name

	for i = 1, 4 do
		if zone_name == self.puzzle_zone_name .. i and e.FullLeave and self.puzzle_start[i] and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			local fat_gnome = get_character(self.fat_gnome_name)
			local princess = get_character(self.princess_name)

			self.puzzle_start[i] = false

			character_util.stop(fat_gnome)

			-- 공주가 나가려고 하면 뚱보 노움 바로 파티원 합류
			if lua_helper.reference_equals(e.FieldObject, princess) then
				character_util.convert_to_party_member(fat_gnome, user_party, true)
			end

			-- 뚱보 노움으로 나가려고 하면 공주가 오길 기다리고 공주를 리더로
			if lua_helper.reference_equals(e.FieldObject, fat_gnome) then
				sp_util.play_normal_screenplay(function()
					character_util.move_to_async(princess, fat_gnome.Position, 0.5, nil,
							true, true)

					local param = CS.Oak.CharacterConvertParam:ManualDefault()
					param.HidePreviousParty = false
					character_util.convert_to_manual_character(princess, param)

					camera_util.return_to_leader(0.1)

					character_util.convert_to_party_member(fat_gnome, user_party, true)
				end)
			end

			fat_gnome.OverrideCrashBehaviour = nil
			princess.OverrideCrashBehaviour = nil

			fat_gnome.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(0.55, 0.75, 0.45))

			field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

			return true
		end
	end

	return true
end

function local_class:on_stage_loaded_event(e)
	for i = 1, 4 do
		self:puzzle_setting(i)
	end

	local princess = get_character(self.princess_name)

	field_ui_manager:SetUI(princess, CS.Oak.FieldUiType.TransformationButton)

	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

	return true
end

function local_class:on_touch_event(e)
	if lua_helper.reference_equals(user_party.Leader, get_character(self.fat_gnome_name)) then
		if e.TouchEventType == CS.Oak.TouchEventType.Action3TouchDown then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.stomp_check, self))
			return true
		end
	end

	if e.TouchEventType == CS.Oak.TouchEventType.TransformationTouchDown then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.switch_mode, self))
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	for i = 1, 4 do
		if e.Params[0] == self.detect_event_name .. i and not self.detected_party then

			if i == 4 and self.puzzle_clear then
				return true
			end

			local mouse = get_character(e.Params[1])
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.get_caught_leader, self, mouse, i))
			return true
		end
	end

	return false
end

function local_class:on_damage_event(e)
	for i = 1, 2 do
		local mouse_guard = get_character(self.mouse_guard_name .. 4 .. '_' .. i)
		if lua_helper.reference_equals(e.Info.target, mouse_guard) and not self.puzzle_clear and
			lua_helper.reference_equals(e.Info.sender, get_field_object(self.bomb_name .. i)) then

			self.puzzle_clear = true
			music_player:PlaySfxOneShot('01_die_mouse_01')
			for index = 1, 2 do
				mouse_guard = get_character(self.mouse_guard_name .. 4 .. '_' .. index)
				self.stop_detecting_list[mouse_guard] = true
				character_util.air_spin(mouse_guard, { offset = 3 * unity_class.vector3.left })
			end

			-- 클리어 저장
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				local stage_custom = stage_progress:SetCustomData(self.puzzle_clear_custom_key, true)
				local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
				coroutine.yield(req)
			end))

			return true
		end
	end

	return false
end

function local_class:puzzle_setting(index)
	for i = 1, self.puzzle_mouse_count[index] do
		local mouse_guard = get_character(self.mouse_guard_name .. index .. '_' .. i)
		-- 위치 설정
		mouse_guard.Position = field:GetMarker(self.mouse_marker_name .. index .. '_' .. i ).position
		-- 방향 설정
		character_util.set_direction(mouse_guard, self.puzzle_mouse_dir[index])
		-- 감시 설정
		self.stop_detecting_list[mouse_guard] = false
		self.mouse_stop_move_list[mouse_guard] = false

		coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.detect_update, self, mouse_guard, index))

		self.is_mouse_guard_move_stomp_position_list[mouse_guard] = false

		mouse_guard.Interactable = CS.Oak.NonInteractable.Instance

		if index ~= 4 then
			mouse_guard.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		end
	end
end

-- 뚱보 노움이 공격으로 땅바닥을 내려 찍었을 때, 주변 쥐 경비병 체크
function local_class:stomp_check()
	local is_check_end = false
	local is_not_stomp_action = false
	local fat_gnome_action_check = function()
		while not is_check_end do
			-- 튜토리얼을 이미 본 상태이고, 스톰프를 찍는 도중에 리더를 변경하면, 캔슬 시킴.
			local fat_gnome = get_character(self.fat_gnome_name)
			if self.is_shown_tutorial and not lua_helper.reference_equals(user_party.Leader, fat_gnome) then
				is_not_stomp_action = true
				break
			end

			coroutine.yield()
		end
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(fat_gnome_action_check))
	wait_for_sec(0.7)
	is_check_end = true

	-- 찍기 상태가 아닌 경우, 취소함
	if is_not_stomp_action then
		return
	end

	local index

	for i = 1, 3 do
		if self.puzzle_start[i] then
			index = i
		end
	end

	if not index then return end

	local detect_distance = 7 * 7
	local stomp_position = get_character(self.fat_gnome_name).Position

	for i = 1, self.puzzle_mouse_count[index] do
		local mouse_guard = get_character(self.mouse_guard_name .. index .. '_' .. i)
		local distance = (stomp_position - mouse_guard.Position).sqrMagnitude

		if not self.is_mouse_guard_move_stomp_position_list[mouse_guard] and distance <= detect_distance then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.mouse_guard_move_stomp_position, self, mouse_guard, stomp_position, index))
		end
	end
end

-- 쥐 경비병이 소리가 난 지점으로 확인해보러 감
function local_class:mouse_guard_move_stomp_position(fo, stomp_position, index)
	self.is_mouse_guard_move_stomp_position_list[fo] = true

	self.stop_detecting_list[fo] = true

	-- 경로 찾기
	local plan_path_done = false
	local plan_path

	field.PathFinder:FindNormalPath(fo, stomp_position, 20, fo, 0, nil, function(path, req_key)
		if req_key == 0 then
			plan_path_done = true
			plan_path = path
		end
	end)

	while not plan_path_done do
		coroutine.yield(nil)
	end

	-- 해당 지점으로 이동하는 경로
	local go_waypoints = {}
	-- 해당 지점에서 다시 돌아오는 경로
	local return_waypoints = {}

	for i = 0, plan_path.Count - 1 do
		table.insert(go_waypoints, plan_path[i])
		table.insert(return_waypoints, 1, plan_path[i])
	end

	-- 처음에 보고 있던 방향 저장
	local restore_direction = fo.Direction

	-- 해당 위치로 쥐 이동
	character_util.move_waypoint_async(fo, go_waypoints, 4)

	if self.mouse_stop_move_list[fo] then
		return
	end

	local rotate_time = 2

	local look_dir = vector_util.to_direction(stomp_position - fo.Position)
	fo.Direction = look_dir == CS.Oak.Direction.None and fo.Direction or look_dir
	wait_for_sec(0.5)

	if self.mouse_stop_move_list[fo] then
		return
	end

	-- 반시계 방향으로 회전
	local rotate_mouse = function()
		if fo.Direction == CS.Oak.Direction.Up then
			return CS.Oak.Direction.Left
		end
		if fo.Direction == CS.Oak.Direction.Left then
			return CS.Oak.Direction.Down
		end
		if fo.Direction == CS.Oak.Direction.Down then
			return CS.Oak.Direction.Right
		end
		if fo.Direction == CS.Oak.Direction.Right then
			return CS.Oak.Direction.Up
		end
	end

	-- 오른쪽 회전
	character_util.set_direction(fo, vector_util.to_direction(-1 * direction_util.to_vector3(rotate_mouse())))

	self.stop_detecting_list[fo] = false
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detect_update, self, fo, index))

	wait_for_sec(rotate_time)

	if self.mouse_stop_move_list[fo] then
		return
	end

	-- 정면 -> 왼쪽 회전
	for _ = 1, 2 do
		character_util.set_direction(fo, rotate_mouse())
		wait_for_sec(rotate_time)

		if self.mouse_stop_move_list[fo] then
			return
		end
	end

	self.stop_detecting_list[fo] = true

	-- 다시 돌아가는 쥐 이동
	character_util.move_waypoint_async(fo, return_waypoints, 4)

	if self.mouse_stop_move_list[fo] then
		return
	end

	fo.Direction = restore_direction
	self.stop_detecting_list[fo] = false
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.detect_update, self, fo, index))

	self.is_mouse_guard_move_stomp_position_list[fo] = false
end

-- 리더가 잡혔을 때 연출
function local_class:get_caught_leader(finder, index)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.detected_party = true

	local target = user_party.Leader

	-- 리더가 걸린 게 아니면 리더가 아닌 캐릭터가 타겟
	if not self.detected_leader then
		if lua_helper.reference_equals(target, get_character(self.princess_name)) then
			target = get_character(self.fat_gnome_name)
		else
			target = get_character(self.princess_name)
		end
	end

	self.detected_leader = true

	-- 쥐들을 멈추게 함
	for i = 1, 3 do
		for j = 1, self.puzzle_mouse_count[i] do
			local mouse_guard = get_character(self.mouse_guard_name .. i .. '_' .. j)
			character_util.stop(mouse_guard)
		end
	end

	for i = 1, self.puzzle_mouse_count[index] do
		local mouse_guard = get_character(self.mouse_guard_name .. index .. '_' .. i)
		self.stop_detecting_list[mouse_guard] = true
		self.mouse_stop_move_list[mouse_guard] = true
	end

	character_util.normal_jump(finder, true)
	character_util.normal_jump_async(target)

	character_util.set_emotion(finder, { name = 'mad' })
	character_util.set_anim(finder, { name = 'release' })

	local fat_gnome = get_character(self.fat_gnome_name)
	if not lua_helper.reference_equals(target, fat_gnome) then
		character_util.set_emotion(target, { name = 'scared' })
		character_util.set_anim(target, { name = 'embarrassed' })
	end

	music_player:PlaySfxOneShot('01_die_mouse_01')

	-- 찍찍!
	speech_bubble_util.show_speech_bubble_async(finder, { key = 'discovered_by_mouse', skip = true })

	-- 페이드 아웃 후 리셋
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	character_util.remove_anim_and_emotion(finder)

	character_util.remove_anim_and_emotion(get_character(self.princess_name))
	character_util.remove_anim_and_emotion(get_character(self.fat_gnome_name))

	-- 공주 리셋
	local marker = field:GetMarker(self.princess_reset_marker_name .. index)
	local princess = get_character(self.princess_name)
	princess.Position = marker.position
	character_util.set_direction(princess, marker.direction)

	-- 뚱보 노움 리셋
	marker = field:GetMarker(self.fat_gnome_reset_marker_name .. index)
	fat_gnome.Position = marker.position
	character_util.set_direction(fat_gnome, marker.direction)

	wait_for_sec(0.5)

	-- 생쥐 원위치
	self:puzzle_setting(index)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self.detected_party = false
	self.is_mouse_guard_move_stomp_position_list[finder] = false

	party_util.reset_controllers()

	if lua_helper.reference_equals(user_party.Leader, fat_gnome)  then
		local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
		manual_touch_state:DisableControls(CS.Oak.DisabledControls.Hold)
		local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
		message_system:SendSync(fat_gnome.FieldObjectController, state_change_event)
	end
	field_ui_manager:Show()
end

function local_class:start_tutorial()
	self.puzzle_start[1] = true

	local fat_gnome = get_character(self.fat_gnome_name)
	local princess = user_party.Leader

	-- 벽 뒤로 이동
	local marker = field:GetMarker(self.tutorial_marker_name).position
	character_util.move_waypoint(fat_gnome, marker + unity_class.vector3.forward, 5, false,
		nil, nil, 'right')
	character_util.move_waypoint_async(princess, marker, 5, true, nil,
		nil, 'right')

	camera_util.move_async(get_character(self.mouse_guard_name .. 1 .. '_' .. 1).Position, 1)

	wait_for_sec(1)

	camera_util.move_async(fat_gnome.Position, 1, { end_target = fat_gnome })

	-- 저기 쥐들이 길을 막고 있어!
	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = 'nightmare_titantavern_3_puzzle_1', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	-- 내게 좋은 생각이 있어!
	speech_bubble_util.show_speech_bubble_async(fat_gnome,
		{ key = 'nightmare_titantavern_3_puzzle_2', skip = true, offset = vector(2.5, 3, 0) })

	local waypoints = {
		marker + vector(0, 0, -2.5),
		marker + vector(3, 0, -2.5)
	}

	character_util.move_waypoint_async(fat_gnome, waypoints, 5, false, nil,
		nil, 'right')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.stomp_check, self))

	-- 뚱보 노움이 내려찍는 연출
	local animation_duration = 1.067
	local jump_duration = 0.2
	local stop_duration = 0.2
	local fall_duration = 0.2
	local total_duration = jump_duration + stop_duration + fall_duration

	local free_fall = CS.CalculatorFreeFall(12, 12, 0, 0)

	free_fall:ScaleTime(1.4)

	character_util.set_anim(fat_gnome,
		{ name = 'devour_pratfall', loop = false, scale = animation_duration / total_duration })

	local time_passed = 0
	-- JumpState
	while true do
		local old_time_passed = time_passed
		time_passed = time_passed + unity_class.time.deltaTime

		free_fall:Proceed(unity_class.time.deltaTime)

		fat_gnome.SpineController.SpineOffset = unity_class.vector3.up * free_fall:GetDistance()

		if old_time_passed < jump_duration and jump_duration <= time_passed then
			fat_gnome.SpineController:Shake(0.2, unity_class.time.deltaTime)
			break
		end

		coroutine.yield(nil)
	end

	-- WaitForStompState
	time_passed = 0
	while true do
		local old_time_passed = time_passed
		time_passed = time_passed + unity_class.time.deltaTime

		if old_time_passed < stop_duration and stop_duration <= time_passed then
			break
		end

		coroutine.yield()
	end

	-- StompState
	free_fall = CS.CalculatorFreeFall(-5, CS.Oak.Constants.DefaultGravity, fat_gnome.SpineController.SpineOffset.y, 0)
	free_fall:ScaleTime(3)
	while true do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance()

		fat_gnome.SpineController.SpineOffset = vector(0, unity_class.mathf.Max(cur_y, 0), 0)

		if free_fall:IsDone() then
			music_player_util.play_sfx({ sfx_name = '03_mech_stomp_01', parent = fat_gnome,
										 type_priority = 'battle_attack', player_priority = 'npc' })

			fat_gnome.SpineController:Shake(0.2, unity_class.time.deltaTime)

			camera_util.shake(0.5, 0.4)

			local target_pos = fat_gnome.Position

			unity_object_pool.GetOrCreate(self.stomp_effect_name):Instantiate(target_pos)

			fat_gnome.SpineController.SpineOffset = unity_class.vector3.zero
			break
		end

		coroutine.yield()
	end

	wait_for_sec(0.3)

	character_util.remove_anim_and_emotion(fat_gnome)
	music_player:PlaySfxOneShot('01_mouse_01')
	-- 다시 돌아옴
	waypoints = {
		marker + vector(0, 0, -2.5),
		marker + vector(0, 0, 1)
	}

	character_util.move_waypoint_async(fat_gnome, waypoints, 5, false, nil,
		nil, 'right')

	-- 내가 큰 소리를 내면, 쥐들이 놀라서 뛰어나올 거야.
	speech_bubble_util.show_speech_bubble_async(fat_gnome,
		{ key = 'nightmare_titantavern_3_puzzle_3', skip = true, offset = vector(2.5, 3, 0) })

	-- 그때 지나가면 된다는 거구나?!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = 'nightmare_titantavern_3_puzzle_4', skip = true })

	-- 헤헤, 맞아. 역시 꼬마는 똑똑하구나!
	music_player:PlaySfxOneShot('01_fat_gnome_03')
	speech_bubble_util.show_speech_bubble_async(fat_gnome,
		{ key = 'nightmare_titantavern_3_puzzle_5', skip = true, offset = vector(2.5, 3, 0) })

	character_util.convert_to_npc(fat_gnome)

	fat_gnome.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

	camera_util.return_to_leader(1)

	self.is_shown_tutorial = true
end

-- 리더를 변경하는 모드
function local_class:switch_mode()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local princess = get_character(self.princess_name)
	local fat_gnome = get_character(self.fat_gnome_name)

	local changed_leader

	if user_party.Leader == princess then
		changed_leader = fat_gnome
		fat_gnome.OverrideCrashBehaviour = CS.Oak.SuperGnomeCrashBehaviour.Instance
		princess.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	elseif user_party.Leader == fat_gnome then
		changed_leader = princess
		fat_gnome.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		princess.OverrideCrashBehaviour = nil
	end

	local current_state = user_party.Leader.FieldObjectBehaviour.CurrentActionState

	if lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local target = current_state.HoldTarget
		command_util.execute_throw(user_party.Leader, target, CS.Oak.DirectionExtensions.ToVector3(user_party.Leader.Direction),
			user_party.Leader.Position, 0, false)
	end


	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(changed_leader, param)

	camera_util.return_to_leader((princess.Position - fat_gnome.Position).magnitude / 14)

	-- 1칸 길은 못 가도록 Hitbox 조절
	if changed_leader == fat_gnome then
		party_util.reset_controllers()
		fat_gnome.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.2, 0.7, 1.2))
		local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
		manual_touch_state:DisableControls(CS.Oak.DisabledControls.Hold)
		local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
		message_system:SendSync(fat_gnome.FieldObjectController, state_change_event)
		field_ui_manager:Show()
	else
		field_ui_manager:Show()
		party_util.reset_controllers()
	end
end

-- 퍼즐 시작 세팅
function local_class:start_puzzle_setting(zone_center, index)
	local fat_gnome = get_character(self.fat_gnome_name)
	local princess = get_character(self.princess_name)

	character_util.convert_to_npc(fat_gnome)

	fat_gnome.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	-- 살짝 앞으로 이동
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		character_util.move_waypoint_async(fat_gnome, princess.Position,
			(fat_gnome.Position - princess.Position).magnitude / 0.2)

		if self.puzzle_start[index] then
			field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)
		end
	end))
end

function local_class:detect_update(fo, index)
	local princess = get_character(self.princess_name)
	local fat_gnome = get_character(self.fat_gnome_name)

	local target = { princess, fat_gnome }

	local attack_range_renderer = CS.Oak.GhostGuardAttackRangeRenderer(fo, self.sight_distance, self.sight_angle)
	attack_range_renderer.AttackRange:Show(0)

	while not self.stop_detecting_list[fo] do
		for _, v in pairs(target) do
			if self:is_in_sight(fo, v) and self.puzzle_start[index] then
				if not lua_helper.reference_equals(user_party.Leader, v) then
					self.detected_leader = false
				end

				message_system:Publish(CS.Oak.CustomStageEvent.Create(fo,
					{ self.detect_event_name .. index, fo.Transform.name }))
				self.stop_detecting_list[fo] = true
				self.mouse_stop_move_list[fo] = true
				break
			end
		end

		attack_range_renderer:Update(fo)

		coroutine.yield(nil)
	end

	attack_range_renderer:Dispose()
end

-- 플레이어가 감시에 보이는지 체크
function local_class:is_in_sight(fo, target)
	if fo.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	local full_diff = target.Bounds.center - fo.Bounds.center
	local diff = target.Bounds.center - fo.Bounds.center

	if diff.magnitude > self.sight_distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > self.sight_angle / 2 then
		return false
	end

	if field:IsAnythingBlocking(CS.UnityEngine.Bounds(fo.Bounds.center, vector(0.05, 0.05, 0.05)),
		CS.Oak.EntityGroups.Obstacle, vector_util.get_x0z(full_diff)) then
		return false
	end

	return true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
