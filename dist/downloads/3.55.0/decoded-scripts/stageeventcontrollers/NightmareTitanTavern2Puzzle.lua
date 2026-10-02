local local_class = newclass('NightMareTitanTavern2PuzzleController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.princess = nil
	self.get_princess = function() return self.princess end
	self.get_princess_origin = function()
		local princess = get_character('princess_gnome_1')
		return princess
	end
	self.get_gnome = function() return get_character('fat_gnome') end

	-- 위쪽 라즈베리 존 관련
	self.puzzle1_zone_name = 'raspberry_zone'
	self.raspberry_bush_name = 'raspberry_bush_'
	self.puzzle1_switch1_name = 'puzzle1_switch_1'
	self.puzzle1_switch2_name = 'puzzle1_switch_2'
	self.puzzle1_door1_name = 'puzzle1_door'
	self.puzzle1_door2_name = 'puzzle1_door_2'

	self.puzzle1_npc_name = 'puzzle2_npc_'
	self.puzzle1_talk_name = 'nightmare_titantavern_2_puzzle1_talk_'

	self.puzzle1_marker_name = 'main_s3_bishop_1'

	-- 아래쪽 테슬라 코일 존 관련
	self.puzzle2_zone_name = 'tesla_zone'

	self.puzzle2_tesla1_name = 'puzzle2_rod_1'
	self.puzzle2_tesla2_name = 'puzzle2_rod_4'
	self.puzzle2_tesla3_name = 'puzzle2_rod_5'
	self.puzzle2_door1_name = 'puzzle2_door_3'
	self.puzzle2_door2_name = 'puzzle2_door_1'
	self.puzzle2_door3_name = 'puzzle2_door_2'

	self.puzzle2_rock_1_name = 'puzzle_clear_rock_1'
	self.puzzle2_rock_2_name = 'puzzle_clear_rock_2'
	self.puzzle2_talk_name = 'nightmare_titantavern_2_puzzle2_talk_'

	self.puzzle2_marker_name = 'tesla_point'

	self.puzzle2_rock1_state = false
	self.puzzle2_rock2_state = false

	self.custom_key = {
		-- 오른쪽 첫 번째 바위를 파괴했는지
		rock_1 = 0,
		-- 왼쪽 마지막 바위를 파괴했는지
		rock_2 = 1
	}

	self.is_camera_moving = false
	self.door_open_wait = nil
	self.switch_wait = false

	self.puzzle1_first_enter = false

	self.started_puzzle1 = false
	self.started_puzzle2 = false

	self.cleared_puzzle1 = false
	self.cleared_puzzle2 = false
	self.is_event_clear = false

	self.detected_check = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_tesla_on_off_event')

end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))

	self.cs_controller = nil
	self.door_open_wait = nil
end

function local_class:on_stage_loaded()
	local puzzle2_rock_1 = get_field_object(self.puzzle2_rock_1_name)
	local puzzle2_rock_2 = get_field_object(self.puzzle2_rock_2_name)

	self.puzzle2_rock1_state = stage_progress:GetCustomData(self.custom_key.rock_1)
	self.puzzle2_rock2_state = stage_progress:GetCustomData(self.custom_key.rock_2)

	local trash_quest = user_progress:GetStartedQuest(125)
	local trash_progress = trash_quest:GetCustomState('has_cleared_trash')
	--- 쓰레기 모으는 퀘스트의 진행도는 bitwise로 처리된다.
	--- + 1(바나나) + 2(노움타임즈) + 4(탄피)
	--- 모든 경우에 -1을 제외하고, 2로 나눈 나머지가 1인 경우 바나나를 먹은 것이다.
	if trash_progress % 2 == 1 and trash_progress > 0 then
		self.cleared_puzzle1 = true
	end

	-- 라즈베리 부쉬 상호작용 비활성화
	for i = 1, 5 do
		local bush = get_field_object(self.raspberry_bush_name .. i)
		bush.Interactable = CS.Oak.NonInteractable.Instance
	end

	self.cleared_puzzle2 = self.puzzle2_rock2_state

	if self.puzzle2_rock2_state then
		puzzle2_rock_2.Position = vector(999, 0, 999)
		puzzle2_rock_2.ActiveState = active_state('disabled')
	end
	if self.puzzle2_rock1_state then
		puzzle2_rock_1.Position = vector(999, 0, 999)
		puzzle2_rock_1.ActiveState = active_state('disabled')
	end

	self.is_event_clear = self.cleared_puzzle1 and self.cleared_puzzle2

	return true
end

function local_class:on_stage_start()
	self.princess = self:get_princess_origin()

	field_ui_manager:SetUI(self.princess, CS.Oak.FieldUiType.TransformationButton)
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, self.princess)

	return true
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.on_field_object_destroyed_event, self, e))
		return true
	end
	return false
end

function local_class:on_touch_event(e)
	if e.TouchEventType == CS.Oak.TouchEventType.TransformationTouchDown then
		sp_util.play_normal_screenplay(self.switch_mode, self)
		return true
	end
	return false
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_field_object(self.puzzle2_rock_1_name)) then
		self.puzzle2_rock1_state = true
		local stage_custom = stage_progress:SetCustomData(self.custom_key.rock_1, true)
		local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
		coroutine.yield(req)
	end
	if lua_helper.reference_equals(e.FieldObject, get_field_object(self.puzzle2_rock_2_name)) then
		self.puzzle2_rock2_state = true
		local stage_custom = stage_progress:SetCustomData(self.custom_key.rock_2, true)
		local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
		coroutine.yield(req)
		sp_util.play_normal_screenplay(self.puzzle2_clear, self)
		--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle2_clear_new, self))
	end
end

-- 문 개방시 버튼 비활성화 되지 않는 현상 수정용 이벤트 체크
function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn then
		if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.puzzle1_switch1_name)) then
			local door = get_field_object(self.puzzle1_door1_name)
			if not door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_button_on_switch, self, self.cleared_puzzle1))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_open, self, self.puzzle1_door1_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.puzzle1_switch2_name)) then
			local door = get_field_object(self.puzzle1_door2_name)
			if not door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_button_on_switch, self, self.cleared_puzzle1))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_open, self, self.puzzle1_door2_name))
				return true
			end
		end
	end
	if not e.IsTurningOn then
		if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.puzzle1_switch1_name)) then
			local door = get_field_object(self.puzzle1_door1_name)
			if door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_close, self, self.puzzle1_door1_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.puzzle1_switch2_name)) then
			local door = get_field_object(self.puzzle1_door2_name)
			if door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_close, self, self.puzzle1_door2_name))
				return true
			end
		end
	end
	return false
end

-- 문 개방시 버튼 비활성화 되지 않는 현상 수정용 이벤트 체크
function local_class:on_tesla_on_off_event(e)
	if e.IsTurningOn then
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla1_name)) then
			local door = get_field_object(self.puzzle2_door1_name)
			if not door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_button_on_switch, self, self.cleared_puzzle2))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_open, self, self.puzzle2_door1_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla2_name)) then
			local door = get_field_object(self.puzzle2_door2_name)
			if not door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_button_on_switch, self, self.cleared_puzzle2))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_open, self, self.puzzle2_door2_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla3_name)) then
			local door = get_field_object(self.puzzle2_door3_name)
			if not door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_open, self, self.puzzle2_door3_name))
				return true
			end
		end
	end
	if not e.IsTurningOn then
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla1_name)) then
			local door = get_field_object(self.puzzle2_door1_name)
			if door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_close, self, self.puzzle2_door1_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla2_name)) then
			local door = get_field_object(self.puzzle2_door2_name)
			if door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_close, self, self.puzzle2_door2_name))
				return true
			end
		end
		if lua_helper.reference_equals(e.CoilObject, get_field_object(self.puzzle2_tesla3_name)) then
			local door = get_field_object(self.puzzle2_door3_name)
			if door.FieldObjectBehaviour.IsOpen then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.yield_door_close, self, self.puzzle2_door3_name))
				return true
			end
		end
	end
	return false
end

function local_class:hide_button_on_switch(cleared)
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, self.princess)
	wait_for_sec(3.8)
	if not cleared then
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.TransformationButton, self.princess)
	end
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, self.princess) then return false end
	if not e.FullEnter then return false end

	if e.Zone.Name == self.puzzle1_zone_name and not self.cleared_puzzle1 and not self.started_puzzle1 then
		--sp_util.play_normal_screenplay(self.puzzle1_enter, self)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle1_enter_new, self))
		return true
	end

	if e.Zone.Name == self.puzzle2_zone_name and not self.cleared_puzzle2 and not self.started_puzzle2 then
		--sp_util.play_normal_screenplay(self.puzzle2_enter, self)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle2_enter_new, self))
		return true
	end
	return false
end

function local_class:on_zone_leave_event(e)
	local fat_gnome = self:get_gnome()
	local is_gnome = false
	if not lua_helper.reference_equals(e.FieldObject, self.princess) and not lua_helper.reference_equals(e.FieldObject, fat_gnome) then return false end
	if lua_helper.reference_equals(e.FieldObject, fat_gnome) then is_gnome = true end
	if not e.FullLeave then return false end

	if e.Zone.Name == self.puzzle1_zone_name and self.started_puzzle1 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle1_leave, self, is_gnome))
		return true
	end

	if e.Zone.Name == self.puzzle2_zone_name and self.started_puzzle2 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle2_leave, self, is_gnome))
		return true
	end
	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params[0] == 'gnome_detect' and user_party.Leader == self.princess and not self.detected_check then
		self.detected_check = true
		sp_util.play_normal_screenplay(self.gnome_detected, self, e.Sender)
		return true
	end
	return false
end

function local_class:puzzle1_enter()
	local gnome_offset = vector(-2.5, 3, 0)
	local marker_pos = field:GetMarker(self.puzzle1_marker_name).position
	local npc1 = get_character(self.puzzle1_npc_name .. 1)
	local npc2 = get_character(self.puzzle1_npc_name .. 2)
	local npc3 = get_character(self.puzzle1_npc_name .. 3)
	camera_util.move(marker_pos + vector(-4, 0, 1), 0.5)
	camera_util.resize_to(5, 0.5)
	character_util.move_to(self:get_gnome(), marker_pos + vector(-1.5, 0, 1), 0.5, nil, true, true)
	character_util.move_to_async(self.princess, marker_pos + vector(-1.5, 0, -1), 0.5, nil, true, true)
	character_util.set_direction(self:get_gnome(), 'left')
	character_util.set_direction(self.princess, 'left')

	if not self.puzzle1_first_enter then
		-- 웃는 얼굴님을 거역하는자... 교화하라!
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		speech_bubble_util.show_speech_bubble_async(npc1, {
			key = self.puzzle1_talk_name .. 1, skip = true
		})

		-- 웃는 얼굴님을 거역하는자... 처단하라!
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		speech_bubble_util.show_speech_bubble_async(npc2, {
			key = self.puzzle1_talk_name .. 2, skip = true
		})

		-- 으으... 교화가 뭐야? 처단은?
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_emotion(self.princess, {name = 'scared'})
		speech_bubble_util.show_speech_bubble_async(self.princess, {
			key = self.puzzle1_talk_name .. 3, skip = true
		})

		-- 응, 모르는게 더 좋을 것 같아...
		character_util.set_direction(self:get_gnome(), 'down')
		character_util.set_emotion(self.get_gnome(), {name = 'depressed'})
		speech_bubble_util.show_speech_bubble_async(self:get_gnome(), {
			key = self.puzzle1_talk_name .. 4, skip = true, offset = gnome_offset, bubble_direction = 'lt'
		})
		self.puzzle1_first_enter = true
	end

	-- 아무래도 그냥 지나가게 해주지는 않을 것 같네.
	character_util.set_direction(self:get_gnome(), 'left')
	speech_bubble_util.show_speech_bubble_async(self:get_gnome(), {
		key = self.puzzle1_talk_name .. 5, skip = true, offset = gnome_offset, bubble_direction = 'lt'
	})

	character_util.remove_anim_and_emotion(self.princess)
	character_util.remove_anim_and_emotion(self.get_gnome())

	self.started_puzzle1 = true

	camera_util.resize_to_default(0.5)
	camera_util.return_to_leader(0.5)

	npc1.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc1, nil, 0, 'gnome_detect', 5.5, 45)
	npc2.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc2, nil, 0, 'gnome_detect', 5.5, 45)
	npc3.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc3, nil, 0, 'gnome_detect', 5.5, 45)

	-- 협동 퍼즐 모드 돌입
	yield_return_func(self.cowork_start, self)
end

function local_class:puzzle1_enter_new()
	local npc1 = get_character(self.puzzle1_npc_name .. 1)
	local npc2 = get_character(self.puzzle1_npc_name .. 2)
	local npc3 = get_character(self.puzzle1_npc_name .. 3)

	self.started_puzzle1 = true

	npc1.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc1, nil, 0, 'gnome_detect', 5.5, 45)
	npc2.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc2, nil, 0, 'gnome_detect', 5.5, 45)
	npc3.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(npc3, nil, 0, 'gnome_detect', 5.5, 45)

	-- 협동 퍼즐 모드 돌입
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cowork_start, self))
end

function local_class:puzzle2_enter()
	local gnome_offset = vector(-2.5, 3, 0)
	local marker_pos = field:GetMarker(self.puzzle2_marker_name).position
	party_util.align_party(marker_pos + vector(-1.5, 0, 0), 'right', 0.5, 'linear')
	camera_util.resize_to(6, 1)
	music_player:PlaySfxOneShot('02_lightning_strike_01')
	camera_util.move_async(marker_pos + vector(-7, 0, -2), 1)
	wait_for_sec(1)
	camera_util.resize_to_default(1)
	camera_util.move_async(user_party.Leader.Position, 1, {end_target = user_party.Leader})

	-- 으아... 이번에도 좁은 길 투성이네.
	character_util.set_emotion(self.get_gnome(), {name = 'depressed'})
	speech_bubble_util.show_speech_bubble_async(self:get_gnome(), {
		key = self.puzzle2_talk_name .. 1, skip = true, offset = gnome_offset, bubble_direction = 'lt'
	})

	-- 걱정 마! 내가 길을 뚫어줄게!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_direction(self.princess, 'right')
	character_util.set_emotion(self.princess, {name = 'smile'})
	character_util.set_anim(self.princess, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(self.princess, {
		key = self.puzzle2_talk_name .. 2, skip = true
	})

	character_util.set_direction(self.princess, 'left')
	character_util.remove_anim_and_emotion(self.princess)
	character_util.remove_anim_and_emotion(self.get_gnome())

	self.started_puzzle2 = true
	-- 협동 퍼즐 모드 돌입
	yield_return_func(self.cowork_start, self)
end

function local_class:puzzle2_enter_new()
	self.started_puzzle2 = true
	-- 협동 퍼즐 모드 돌입
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cowork_start, self))
end

function local_class:gnome_detected(sender)
	local fat_gnome = self:get_gnome()

	local marker_pos = field:GetMarker(self.puzzle1_marker_name).position
	coroutine.yield(nil)
	character_util.set_anim_and_emotion(self.princess, {name = 'embarrassed'}, {name = 'scared'})
	character_util.set_anim_and_emotion(sender, {name = 'release'}, {name = 'greed'})
	coroutine.yield(nil)
	character_util.set_anim_and_emotion(self.princess, {name = 'embarrassed'}, {name = 'scared'})

	-- 교화하라!
	music_player:PlaySfxOneShot('03_runaway_01')
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(sender, {
		key = self.puzzle1_talk_name .. 'detected', skip = true
	})

	wait_for_sec(0.5)
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	fat_gnome.EntityGroup = CS.Oak.EntityGroups.Neutral

	character_util.set_position(fat_gnome, marker_pos + vector(-1.5, 0, 1), false)
	character_util.set_position(self.princess, marker_pos + vector(-1.5, 0, -1), false)

	character_util.set_direction(fat_gnome, 'left')
	character_util.set_direction(self.princess, 'left')

	-- 1칸 길은 못 가도록 Hitbox 조절
	if changed_leader == fat_gnome then
		fat_gnome.EntityGroup = CS.Oak.EntityGroups.Player0
	else
		fat_gnome.EntityGroup = CS.Oak.EntityGroups.Obstacle
	end

	character_util.remove_anim_and_emotion(self.princess)
	character_util.remove_anim_and_emotion(fat_gnome)
	character_util.remove_anim_and_emotion(sender)
	-- 디텍션 초기화
	message_system:SendSync(sender.FieldObjectController, CS.Oak.StateResetEvent.Instance)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	self.detected_check = false
end

-- 퍼즐2 왼쪽 바위가 부서지는 순간 호출
function local_class:puzzle2_clear()
	yield_return_func(self.yield_door_open, self, nil)
	local princess = self.princess
	local fat_gnome = self:get_gnome()

	local gnome_offset = vector(2.5, 3, 0)
	camera_util.move(self:get_gnome().Position, 0.5)
	if princess.Position.x < 1 then
		character_util.move_waypoint_async(self.princess, {
			vector(-0.5, 0, self:get_gnome().Position.z)
		}, 9, true, 'stop', 'floor', 'right', true)
	elseif princess.Position.z > -50 then
		character_util.move_waypoint_async(self.princess, {
			vector(-0.5, 0, -49),
			vector(-0.5, 0, self:get_gnome().Position.z)
		}, 9, true, 'stop', 'floor', 'right', true)
	else
		character_util.move_waypoint_async(self.princess, {
			vector(9, 0, -52),
			vector(9, 0, -49),
			vector(-0.5, 0, -49),
			vector(-0.5, 0, self:get_gnome().Position.z)
		}, 9, true, 'stop', 'floor', 'right', true)
	end
	character_util.set_direction(self:get_gnome(), 'left')
	character_util.remove_anim_and_emotion(self.get_gnome())

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_direction(princess, 'right')
	character_util.set_direction(fat_gnome, 'left')

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_emotion(fat_gnome, { name = 'smile' })

	character_util.mario_jump_new(princess, 'right', 0.3, 0.3)
	character_util.mario_jump_async(fat_gnome, 'left', 0.3, 0.3)

	character_util.remove_emotion(princess)
	character_util.remove_emotion(fat_gnome)

	self.cleared_puzzle2 = true

	--camera_util.return_to_leader(0.5)
	yield_return_func(self.puzzle2_leave, self, true)
end

function local_class:puzzle2_clear_new()
	yield_return_func(self.yield_door_open, self, nil)
	self.cleared_puzzle2 = true

	--camera_util.return_to_leader(0.5)
	yield_return_func(self.puzzle2_leave, self, true)
end

function local_class:puzzle1_leave(is_gnome)
	-- 협동 퍼즐 모드 해제
	self:cowork_end()

	local trash_quest = user_progress:GetStartedQuest(125)
	if trash_quest:GetCustomState("has_cleared_trash") % 2 == 1 then
		self.cleared_puzzle1 = true
	end

	if self.cleared_puzzle1 then
		local npc1 = get_character(self.puzzle1_npc_name .. 1)
		local npc2 = get_character(self.puzzle1_npc_name .. 2)
		local npc3 = get_character(self.puzzle1_npc_name .. 3)
		npc1.FieldObjectController = CS.Oak.NPCCharacterController()
		npc2.FieldObjectController = CS.Oak.NPCCharacterController()
		npc3.FieldObjectController = CS.Oak.NPCCharacterController()
	end

	if is_gnome then
		coroutine.yield(nil)

		field_ui_manager:Hide()
		user_party:StopAndDisableControl()

		--camera_util.move(self:get_gnome().Position, 0, {end_target = self:get_gnome()})
		character_util.move_to_async(self.princess, self:get_gnome().Position, nil, 6, true, true)
		camera_util.return_to_leader(0.5)

		field_ui_manager:Show()
		user_party:ResetControllers()
	end

	self.started_puzzle1 = false
end

function local_class:puzzle2_leave(is_gnome)
	-- 협동 퍼즐 모드 해제
	self:cowork_end()

	if is_gnome then
		coroutine.yield(nil)

		field_ui_manager:Hide()
		user_party:StopAndDisableControl()

		--camera_util.move(self:get_gnome().Position, 0, {end_target = self:get_gnome()})
		character_util.move_to_async(self.princess, self:get_gnome().Position, nil, 6, true, true)
		camera_util.return_to_leader(0.5)

		field_ui_manager:Show()
		user_party:ResetControllers()
	end

	self.started_puzzle2 = false
end

function local_class:cowork_start()
	local fat_gnome = self:get_gnome()
	self.switch_wait = true

	character_util.convert_to_npc(fat_gnome)

	character_util.remove_anim_and_emotion(self.princess)
	character_util.remove_anim_and_emotion(fat_gnome)

	fat_gnome.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.move_to_async(self:get_gnome(), self.princess.Position + vector(-0.5, 0, 0), nil, 7, true, true)

	field_ui_manager:SetUI(self.princess, CS.Oak.FieldUiType.TransformationButton)

	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.TransformationButton, self.princess)
	self.switch_wait = false
end


function local_class:cowork_end()
	local fat_gnome = self:get_gnome()

	while self.switch_wait do coroutine.yield(nil) end

	--camera_util.move(self.princess.Position, 1, { end_target = self.princess })

	fat_gnome.OverrideCrashBehaviour = nil
	self.princess.OverrideCrashBehaviour = nil

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	param.MoveCamera = false
	character_util.convert_to_manual_character(self.princess, param)

	character_util.convert_to_party_member(fat_gnome, user_party)

	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.TransformationButton, self.princess)
end

-- 리더를 변경하는 모드
function local_class:switch_mode()
	local fat_gnome = self:get_gnome()

	local changed_leader

	if user_party.Leader == self.princess then
		changed_leader = fat_gnome
		fat_gnome.OverrideCrashBehaviour = CS.Oak.SuperGnomeCrashBehaviour.Instance
		self.princess.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	elseif user_party.Leader == fat_gnome then
		changed_leader = self.princess
		fat_gnome.OverrideCrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		self.princess.OverrideCrashBehaviour = nil
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

	self.is_camera_moving = true
	camera_util.return_to_leader(self:distance_to_time(self.princess, fat_gnome))
	self.is_camera_moving = false

	-- 1칸 길은 못 가도록 Hitbox 조절
	if changed_leader == fat_gnome then
		fat_gnome.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1.2, 0.7, 1.2))
		fat_gnome.EntityGroup = CS.Oak.EntityGroups.Player0
	else
		fat_gnome.EntityGroup = CS.Oak.EntityGroups.Obstacle
	end
end

function local_class:distance_to_time(a, b)
	local ax = a.Position.x
	local az = a.Position.z
	local bx = b.Position.x
	local bz = b.Position.z

	--local dx = (ax - bx) / 1.414
	local dx = ax - bx
	local dz = az - bz

	return (vector(dx, 0, dz).magnitude / 14)

end

function local_class:yield_door_open(name)
	self.door_open_wait = name
	while self.is_camera_moving do
		coroutine.yield(nil)
	end
	if name ~= nil then
		coroutine.yield(nil)
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(name, false))
		self.door_open_wait = nil
	end
end

function local_class:yield_door_close(name)
	while self.is_camera_moving do
		coroutine.yield(nil)
	end
	if name ~= nil then
		local door = get_field_object(name)
		while self:is_something_on_door(door) do coroutine.yield(nil) end
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(name, false))
	end
end

function local_class:is_something_on_door(door)
	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(door.Bounds, unity_class.vector3.up * 0.5)

	for i = 0, obj_list.Count - 1 do
		local fo = obj_list[i]
		if fo.Bounds ~= nil then
			local overlap_size = self:get_overlapped_xz_area(door.Bounds, fo.Bounds)
			if overlap_size > 0.0001 then
				return true
			end
		end
	end

	obj_list:Dispose()

	return false
end

function local_class:get_overlapped_xz_area(a, b)
	local minA = a.min
	local maxA = a.max
	local minB = b.min
	local maxB = b.max

	local minX = math.max(minA.x, minB.x)
	local minZ = math.max(minA.z, minB.z)
	local maxX = math.max(maxA.x, maxB.x)
	local maxZ = math.max(maxA.z, maxB.z)

	return math.max(0, maxX - minX) * math.max(0, maxZ - minZ)
end

--- FIXME: 뚱보가 guard sight 을 막아주지 못해서 급히 사용한 코드. 올바른 방향이 아니므로 수정이 필요하다.
--- EntityGroup 수정에 성공하여 필요 없게됨
--[[
function local_class:check_blocked(npc)
    local npc_pos = npc.Position
    local princess_pos = self:get_princess().Position
    local gnome_pos = self:get_gnome().Position

    local gnome_horizontal_point =
        vector(((princess_pos.x - npc_pos.x) / (princess_pos.z - npc_pos.z)) * (gnome_pos.z - npc_pos.z) + npc_pos.x, 0, gnome_pos.z)
    if gnome_horizontal_point.x < gnome_pos.x + 0.6 and gnome_horizontal_point.x > gnome_pos.x - 0.6 then
        if npc_pos.z > gnome_pos.z and princess_pos.z < npc_pos.z and princess_pos.z > gnome_pos.z then
            return true
        end
        if npc_pos.z < gnome_pos.z and princess_pos.z > npc_pos.z and princess_pos.z < gnome_pos.z then
            return true
        end
    end
    return false
end
]]

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
