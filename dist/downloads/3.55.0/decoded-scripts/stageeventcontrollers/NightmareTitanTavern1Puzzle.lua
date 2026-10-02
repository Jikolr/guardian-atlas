local local_class = newclass('NightMareTitanTavern1PuzzleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_gnome = function() return get_character('fat_gnome') end

	-- npc 이름
	self.princess_name = 'princess'
	self.fat_gnome_name = 'fat_gnome'
	self.flying_bug_name = 'puzzle_flying_bug'
	self.flying_gnome_name = 'puzzle_flying_gnome'

	-- 마커 이름
	self.flying_pos_name = 'puzzle_flying_pos'

	-- 존 이름
	self.leave_puzzle_1_name = 'leave_puzzle_1'
	self.leave_puzzle_2_name = 'leave_puzzle_2'
	self.jump_tile_zone_name = 'jump_tile_zone'
	self.princess_leave_puzzle_2_name = 'princess_leave_puzzle_2'

	self.puzzle1_zone_name = 'puzzle1'
	self.puzzle2_zone_name = 'puzzle2'

	self.puzzle1_door_name = 'puzzle1_door'
	self.puzzle2_door_name = 'puzzle2_door_'

	self.puzzle1_switch_name = 'puzzle1_switch'
	self.puzzle2_jump_name = 'puzzle2_jump'

	self.puzzle1_rock_name = 'puzzle1_rock'
	self.puzzle2_rock_1_name = 'puzzle2_rock_1'
	self.puzzle2_rock_2_name = 'puzzle2_rock_2'

	self.is_puzzle1_clear = false
	self.is_puzzle2_clear = false
	self.is_event_clear = false

	self.started_puzzle1 = false
	self.started_puzzle2 = false
	self.half_done_flag = false

	-- 퍼즐1 문이 열렸는지
	self.is_puzzle1_door_open = false

	-- 퍼즐용 커스텀 키
	self.custom_key = {
		-- 퍼즐1을 클리어 했는지
		clear_puzzle_1 = 0,
		-- 퍼즐2를 클리어 했는지
		clear_puzzle_2 = 1
	}

	-- 퍼즐 클리어 연출중인지
	self.puzzle_clear_event = false
	-- 리더 변경 연출중인지
	self.switch_mode_playing = false
end

function local_class:load_resource()
	self.is_puzzle1_clear = stage_progress:GetCustomData(self.custom_key.clear_puzzle_1)
	self.is_puzzle2_clear = stage_progress:GetCustomData(self.custom_key.clear_puzzle_2)

	local main_quest_progress = user_progress:GetStartedQuest(124)

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 2 and not self.is_puzzle1_clear then
		self.is_puzzle1_clear = true

		stage_progress_util.set_custom_data(self.custom_key.clear_puzzle_1, true)
	end

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 2 and not self.is_puzzle2_clear then
		self.is_puzzle2_clear = true

		stage_progress_util.set_custom_data(self.custom_key.clear_puzzle_2, true)
	end


	self.is_event_clear = self.is_puzzle1_clear and self.is_puzzle2_clear

	if self.is_puzzle1_clear then
		get_field_object(self.puzzle1_rock_name).ActiveState = active_state('disabled')
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.puzzle1_door_name))

		local princess = get_character(self.princess_name)

		field_ui_manager:SetUI(princess, CS.Oak.FieldUiType.TransformationButton)
		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)
	end

	if self.is_puzzle2_clear then
		get_field_object(self.puzzle2_rock_1_name).ActiveState = active_state('disabled')
		get_field_object(self.puzzle2_rock_2_name).ActiveState = active_state('disabled')

		for i = 2, 4 do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.puzzle2_door_name .. i))
		end
	end

	if not self.is_event_clear then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		return self:on_switch_on_off_event(e)
	end
	return false
end

function local_class:on_zone_enter_event(e)
	local princess = get_character(self.princess_name)

	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, princess) then
		if e.Zone.Name == self.puzzle1_zone_name and not self.is_puzzle1_clear and not self.started_puzzle1 then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.puzzle1_start, self))
			return true
		elseif e.Zone.Name == self.jump_tile_zone_name and not self.is_puzzle2_clear and not self.started_puzzle2 then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.puzzle2_start, self))
			return true
		end
	end

	local fat_gnome = get_character(self.fat_gnome_name)
	if type_util.is_zone_full_enter(e, fat_gnome, self.leave_puzzle_1_name) and not self.is_puzzle1_clear then
		sp_util.play_normal_screenplay(function()
			character_util.set_direction(princess, 'left')
			character_util.set_emotion(princess, { name = 'tired' })

			-- 저기!
			speech_bubble_util.show_speech_bubble_async(princess,
				{ key = 'nightmare_titantavern_1_puzzle1_5', skip = true, bubble_type = 'shout',
				  world_pos = fat_gnome.Position + vector(4, 0, -3) })

			camera_util.move_async(princess.Position, 1)

			-- 날 두고가지 마!
			speech_bubble_util.show_speech_bubble_async(princess,
				{ key = 'nightmare_titantavern_1_puzzle1_6', skip = true })

			camera_util.return_to_leader(1)
			character_util.remove_emotion(princess)
			character_util.move_to_async(fat_gnome, fat_gnome.Position + unity_class.vector3.right,
				1, nil, true, true)
		end)
		return true
	elseif type_util.is_zone_full_enter(e, fat_gnome, 'leave_puzzle_1_2')
			and not self.is_puzzle1_clear and self.started_puzzle1 then
		sp_util.play_normal_screenplay(function()
			character_util.set_direction(princess, 'right')
			character_util.set_emotion(princess, { name = 'tired' })

			-- 저기!
			speech_bubble_util.show_speech_bubble_async(princess,
					{ key = 'nightmare_titantavern_1_puzzle1_5', skip = true, bubble_type = 'shout',
					  world_pos = fat_gnome.Position + vector(-4, 0, -3) })

			camera_util.move_async(princess.Position, 1)

			-- 날 두고가지 마!
			speech_bubble_util.show_speech_bubble_async(princess,
					{ key = 'nightmare_titantavern_1_puzzle1_6', skip = true })

			camera_util.return_to_leader(1)
			character_util.remove_emotion(princess)
			character_util.move_to_async(fat_gnome, fat_gnome.Position + unity_class.vector3.left,
					1, nil, true, true)
		end)
		return true
	end

	if type_util.is_zone_full_enter(e, fat_gnome, self.leave_puzzle_2_name) and not self.is_puzzle2_clear then
		sp_util.play_normal_screenplay(function()
			character_util.set_direction(fat_gnome, 'right')
			character_util.set_emotion(fat_gnome, { name = 'depressed' })
			-- 나 혼자 갈 수는 없지…
			speech_bubble_util.show_speech_bubble_async(fat_gnome,
				{ key = 'nightmare_titantavern_1_puzzle2_18', skip = true, offset = vector(2.5, 3, 0) })

			character_util.remove_emotion(fat_gnome)

			character_util.move_to_async(fat_gnome, fat_gnome.Position + unity_class.vector3.left,
				1, nil, true, true)

		end)
		return true
	end

	if type_util.is_zone_full_enter(e, princess, 'leave_puzzle_1_2')
			and not self.is_puzzle1_clear and self.started_puzzle1 then
		sp_util.play_normal_screenplay(function()
			character_util.set_direction(princess, 'left')
			-- 잭이랑 같이 갈 거야.
			speech_bubble_util.show_speech_bubble_async(princess,
					{ key = 'nightmare_titantavern_1_puzzle2_19', skip = true })

			character_util.move_to_async(princess, princess.Position + unity_class.vector3.left,
					1, nil, true, true)

		end)
		return true
	end

	if type_util.is_zone_full_enter(e, princess, self.princess_leave_puzzle_2_name) then
		if self.started_puzzle2 and not self.is_puzzle2_clear then
			sp_util.play_normal_screenplay(function()
				character_util.set_direction(princess, 'up')
				-- 잭이랑 같이 갈 거야.
				speech_bubble_util.show_speech_bubble_async(princess,
					{ key = 'nightmare_titantavern_1_puzzle2_19', skip = true })

				character_util.move_to_async(princess, princess.Position + unity_class.vector3.back,
					1, nil, true, true)

			end)
			return true
		end
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn then
		if e.SwitchObject == get_field_object(self.puzzle1_switch_name) then
			if self.started_puzzle1 and not self.is_puzzle1_clear and not self.is_puzzle1_door_open then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.first_puzzle_door_open, self))
				return true
			end
		end
	end

	return false
end

function local_class:on_touch_event(e)
	if e.TouchEventType == CS.Oak.TouchEventType.TransformationTouchDown
		and not self.puzzle_clear_event then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.switch_mode, self))
		return true
	end
	return false
end

function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_field_object(self.puzzle1_rock_name)) then
		if self.started_puzzle1 and not self.is_puzzle1_clear and self.is_puzzle1_door_open then
			self.puzzle_clear_event = true
			sp_util.play_normal_screenplay(self.puzzle1_end, self)
			return true
		end
	end

	if lua_helper.reference_equals(e.FieldObject, get_field_object(self.puzzle2_rock_1_name)) then
		if self.started_puzzle2 and not self.is_puzzle2_clear then
			self.puzzle_clear_event = true
			sp_util.play_normal_screenplay(self.puzzle2_end, self)
			return true
		end
	end
	return false
end

-- 첫번째 퍼즐 시작
function local_class:puzzle1_start()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local princess = get_character(self.princess_name)
	local fat_gnome = self:get_gnome()
	local puzzle1_door = get_field_object(self.puzzle1_door_name)
	local puzzle1_switch = get_field_object(self.puzzle1_switch_name)

	self.started_puzzle1 = true

	fat_gnome.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	party_util.align_party(vector_util.get_x0z(puzzle1_door.Bounds.center) + vector(3.5,0,-1.5),
		'up', 1, 'linear')

	character_util.set_direction(princess, 'down')

	camera_util.move_async(puzzle1_switch.Position + vector(1, 0, 2.5), 1)

	character_util.remove_anim_and_emotion(fat_gnome)

	-- 저쪽에 스위치가 있긴 하지만 가는 길이 너무 좁아.
	speech_bubble_util.show_speech_bubble_async(fat_gnome,
		{ key = 'nightmare_titantavern_1_puzzle1_1', skip = true, offset = vector(-2.5, -1, 0), bubble_direction = 'lb' })

	-- 나한테 맡겨!
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'nightmare_titantavern_1_puzzle1_2', skip = true})

	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })

	character_util.convert_to_npc(fat_gnome)

	character_util.remove_anim_and_emotion(princess)
	character_util.remove_anim_and_emotion(fat_gnome)

	field_ui_manager:SetUI(princess, CS.Oak.FieldUiType.TransformationButton)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 첫 번째 퍼즐 문을 열었을 때
function local_class:first_puzzle_door_open()
	self.is_puzzle1_door_open = true

	-- 문 열림
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.puzzle1_door_name, false))
end

-- 폭탄 벌레 내리는 연출
function local_class:take_off_bug(target)
	local duration = 0.35
	local start_offset = target.SpineController.SpineOffset
	local end_offset = unity_class.vector3.zero

	local time_passed = 0

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		local cur_offset = unity_class.vector3.Lerp(start_offset, end_offset, time_passed / duration)

		target.SpineController.SpineOffset = cur_offset

		coroutine.yield(nil)
	end
end

-- 첫 번째 퍼즐 끝
function local_class:puzzle1_end()
	self.is_puzzle1_clear = true

	local princess = get_character(self.princess_name)
	local fat_gnome = get_character(self.fat_gnome_name)
	local rock = get_field_object(self.puzzle1_rock_name)

	local rock_pos = vector_util.get_x0z(rock.Bounds.center)

	character_util.set_direction(princess, 'left')
	character_util.set_emotion(princess, { name = 'surprise' })

	wait_for_sec(0.5)

	character_util.remove_emotion(princess)

	wp_util.move_way_points(fat_gnome, { waypoints = rock_pos + 1.5 * unity_class.vector3.forward,
										 speed = 5, last_direction = CS.Oak.Direction.Down })

	if princess.Position.z > -3.7 then
		wp_util.move_way_points_async(princess, { waypoints = { vector(princess.Position.x, 0, -4) },
		                                          speed = 5, run = true })
	end

	local way_point = {
		vector(rock_pos.x, 0, princess.Position.z),
		rock_pos + 0.5 * unity_class.vector3.forward
	}

	wp_util.move_way_points_async(princess, { waypoints = way_point, speed = 5, run = true })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 해냈어!
	speech_bubble_util.show_speech_bubble_async(princess,
			{ key = 'nightmare_titantavern_1_puzzle1_3', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	-- 우리가 함께하면, 이정도 쯤은 식은 죽 먹기지!
	speech_bubble_util.show_speech_bubble_async(fat_gnome,
			{ key = 'nightmare_titantavern_1_puzzle1_4', skip = true, offset = vector(2.5, 3, 0) })

	character_util.set_direction(princess, 'left')
	character_util.set_direction(fat_gnome, 'left')

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_emotion(fat_gnome, { name = 'smile' })

	character_util.mario_jump_new(princess, 'left', 0.3, 0.3)
	character_util.mario_jump_async(fat_gnome, 'left', 0.3, 0.3)

	character_util.remove_emotion(princess)
	character_util.remove_emotion(fat_gnome)

	camera_util.move_async(princess.Position, 1, { end_target = princess })

	fat_gnome.OverrideCrashBehaviour = nil
	princess.OverrideCrashBehaviour = nil

	fat_gnome.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(0.55, 0.75, 0.45))

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(princess, param)

	character_util.convert_to_party_member(fat_gnome, user_party)

	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

	local stage_custom = stage_progress:SetCustomData(self.custom_key.clear_puzzle_1, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)

	self.puzzle_clear_event = false
end

-- 두번째 퍼즐 시작
function local_class:puzzle2_start()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local princess = get_character(self.princess_name)
	local fat_gnome = self:get_gnome()
	local puzzle2_jump = get_field_object(self.puzzle2_jump_name)
	local puzzle2_jump_animator = puzzle2_jump:GetComponent(typeof(CS.UnityEngine.Animator))

	self.started_puzzle2 = true

	character_util.convert_to_npc(fat_gnome)

	character_util.move_to(fat_gnome, puzzle2_jump.Position + 0.5 * unity_class.vector3.forward - 0.5 * unity_class.vector3.right + 0.2 * unity_class.vector3.up, 0.2, nil, true,true)
	character_util.move_to(princess, puzzle2_jump.Position + 0.5 * unity_class.vector3.forward - 0.5 * unity_class.vector3.right + 0.2 * unity_class.vector3.up, 0.1, nil, true,true)
	wait_for_sec(0.1)

	puzzle2_jump_animator:Play('on')

	character_util.set_direction(princess, 'right')

	local jumping_sound = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true })

	-- 공주 점프
	local dir = 9 * unity_class.vector3.right + 13.475 * unity_class.vector3.up

	local jumpInfo = CS.Oak.JumpInfo()
	jumpInfo.jumper = princess
	jumpInfo.jumpSource = puzzle2_jump
	jumpInfo.jumpType = CS.Oak.JumpType.JumpTileJump
	jumpInfo.speed = dir.magnitude
	jumpInfo.direction = dir.normalized
	jumpInfo.jumpStartPos = princess.Position
	jumpInfo.jumpTimeScale = 3
	jumpInfo.gravity = CS.Oak.Constants.JumpGravity

	local cmd = CS.Oak.JumpCommand.Create(jumpInfo)

	command_util.publish_cmd(jumpInfo.jumper.Owner, cmd)

	wait_for_sec(0.1)
	character_util.set_direction(fat_gnome, 'right')

	-- 잭 점프
	local dir = 13.7 * unity_class.vector3.right + 13.475 * unity_class.vector3.up

	local jumpInfo = CS.Oak.JumpInfo()
	jumpInfo.jumper = fat_gnome
	jumpInfo.jumpSource = puzzle2_jump
	jumpInfo.jumpType = CS.Oak.JumpType.JumpTileJump
	jumpInfo.speed = dir.magnitude
	jumpInfo.direction = dir.normalized
	jumpInfo.jumpStartPos = fat_gnome.Position
	jumpInfo.jumpTimeScale = 2.75
	jumpInfo.gravity = CS.Oak.Constants.JumpGravity

	local cmd = CS.Oak.JumpCommand.Create(jumpInfo)

	command_util.publish_cmd(jumpInfo.jumper.Owner, cmd)

	wait_for_sec(0.5)
	puzzle2_jump_animator:Play('off')
	wait_for_sec(1)

	jumping_sound:Stop()

	character_util.set_direction(fat_gnome, 'left')

	character_util.set_emotion(princess, { name = 'surprise'})
	character_util.set_direction(princess, 'right')

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')

	wait_for_sec(1)

	character_util.remove_anim_and_emotion(fat_gnome)
	character_util.remove_anim_and_emotion(princess)

	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

	field_ui_manager:Show()
	user_party:ResetControllers()
	puzzle2_jump.FieldObjectBehaviour.HorizontalSpeed = 6
end

-- 두 번째 퍼즐 끝
function local_class:puzzle2_end()
	self.is_puzzle2_clear = true

	while self.switch_mode_playing do
		coroutine.yield()
	end

	wait_for_sec(0.5)

	local princess = get_character(self.princess_name)
	local fat_gnome = get_character(self.fat_gnome_name)

	local rock = get_field_object(self.puzzle2_rock_1_name)

	local rock_pos = vector_util.get_x0z(rock.Bounds.center)

	wp_util.move_way_points(fat_gnome, { waypoints = rock_pos + 1.5 * unity_class.vector3.right,
	                                     speed = 5, last_direction = CS.Oak.Direction.Left })

	local way_point = {
		vector(princess.Position.x, 0, rock_pos.z - 2.5),
		rock_pos + vector(0.5, 0, -2.5),
		rock_pos + 0.5 * unity_class.vector3.right
	}

	wp_util.move_way_points_async(princess, { waypoints = way_point, speed = 5, run = true, play_sfx = true })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_direction(princess, 'right')
	character_util.set_direction(fat_gnome, 'left')

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_emotion(fat_gnome, { name = 'smile' })

	character_util.mario_jump_new(princess, 'right', 0.3, 0.3)
	character_util.mario_jump_async(fat_gnome, 'left', 0.3, 0.3)

	character_util.remove_emotion(princess)
	character_util.remove_emotion(fat_gnome)

	camera_util.move_async(princess.Position, 1, { end_target = princess })

	fat_gnome.OverrideCrashBehaviour = nil
	princess.OverrideCrashBehaviour = nil

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(princess, param)

	character_util.convert_to_party_member(fat_gnome, user_party)

	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, princess)

	local stage_custom = stage_progress:SetCustomData(self.custom_key.clear_puzzle_2, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)

	self.puzzle_clear_event = false
end

-- 리더를 변경하는 모드
function local_class:switch_mode()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.switch_mode_playing = true

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
		fat_gnome.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.2, 0.7, 0.7))
	end

	if not self.puzzle_clear_event then
		field_ui_manager:Show()
		party_util.reset_controllers()
	end
	self.switch_mode_playing = false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
