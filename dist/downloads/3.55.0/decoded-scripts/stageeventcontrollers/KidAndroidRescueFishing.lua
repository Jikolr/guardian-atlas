local local_class = newclass('KidAndroidRescueFishingController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--region 필수 npc
	self.get_kid_android = function()
		return get_character('sm_kid_android')
	end
	--endregion

	--region buoy
	self.buoy_list = nil

	self.buoy_default_pos_list = nil
	self.reset_switch_list = nil

	self.get_reset_switch = function(number)
		return get_field_object('buoy_reset_switch_' .. number)
	end
	--endregion

	--region zone
	-- invisible wall이 깔리는 zone
	self.get_zone = function(number)
		return field:GetZone('rescue_zone_' .. number)
	end

	-- 인덱스 관리를 위해 구역을 감싸는 zone
	self.get_main_zone = function(number)
		return field:GetZone('main_zone_' .. number)
	end

	self.zone_list = nil
	self.main_zone_list = nil
	-- 검사에 판별할 인덱스
	self.target_zone_index = 0
	--endregion

	--region wall
	-- virtual field object용 list
	self.wall_list = nil
	--endregion

	--region ui
	self.button = nil
	self.button_active = false
	self.button_screenplay_state_check = true
	self.button_can_input_check = true
	--endregion

	--region npc
	self.rescue_npc_names = {
		'bad_student_female',
		'dungeon_succubus_a',
		'teatan_ninja',
		'succubus_researcher',
		'monk_disciple'
	}

	self.rescue_npcs = nil
	self.collied_npc = nil
	self.rescue_wait = false
	--

	--region fishing 처리용
	self.collied_target = nil
	self.thrown_loop = false
	self.fishing_radius = 8
	self.stage_exit_check = false
	--endregion

	--region object pool
	self.get_hook_shot = function()
		return unity_object_pool.GetOrCreate('hookshot')
	end

	self.get_fx_common_water_splash_in = function()
		return unity_object_pool.GetOrCreate('fx_common_water_splash_in')
	end

	self.get_fx_common_water_splash_out = function()
		return unity_object_pool.GetOrCreate('fx_common_water_splash_out')
	end
	--endregion

	self.scene_version = scene_util.default_version
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FocusingDoorEndEvent))

	self.button = nil
	self.buoy_list = nil
	self.reset_switch_list = nil
	self.buoy_default_pos_list = nil
	self.collied_target = nil
	self.zone_list = nil
	self.main_zone_list = nil
	self.rescue_npc_names = nil
	self.rescue_npcs = nil

	self.rescue_wait = false
	self.thrown_loop = false
	self.buoy_loop = false
	self.stage_exit_check = true

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent), 'on_reset_switch_turned_on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	message_system:Subscribe(self, typeof(CS.Oak.JoypadEvent), 'on_joypad_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FocusingDoorEndEvent), 'on_focusing_door_end_event')

	quest_util.load_pool_resource('hookshot', 'fx_common_water_splash_out', 'fx_common_water_splash_in')

	self:set_zone()
	self:set_main_zone()
	self:set_buoy()
	self:set_wall()
	self:wall_active()
	self:set_reset_switch()
	self:set_rescue_npc()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_reset_switch_turned_on_event(e)
	for i, switch_info in ipairs(self.reset_switch_list) do
		if lua_helper.reference_equals(e.SwitchObject, switch_info.switch) then
			self:reset_buoy(switch_info.index)
		end
	end
end

function local_class:on_touch_event(e)
	if self.button_screenplay_state_check and
			lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
					CS.Oak.CharacterControllerScreenplayState) then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown and self.button_active then
		if not self.thrown_loop then
			music_player_util.play_sfx_one_shot('01_button_05')
			start_coroutine(self.throw_summer_android, self)
		else
			music_player_util.play_sfx_one_shot('01_button_05')
			self.buoy_loop = false
		end
		return true
	end

	if not self.button_screenplay_state_check and
			CS.Oak.InputManager.IsPC and e.TouchEventType == CS.Oak.TouchEventType.TouchDown then
		music_player_util.play_sfx_one_shot('01_button_05')
		start_coroutine(self.throw_summer_android, self)

		return true
	end

	return false
end

function local_class:on_gamepad_event(e)
	if (self.button_screenplay_state_check and
			lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
					CS.Oak.CharacterControllerScreenplayState)) or not self.button_can_input_check then
		return false
	end

	if e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown and self.button_active then
		if not self.thrown_loop then
			music_player_util.play_sfx_one_shot('01_button_05')
			start_coroutine(self.throw_summer_android, self)
		else
			music_player_util.play_sfx_one_shot('01_button_05')
			self.buoy_loop = false
		end
		return true
	end

	return false
end

function local_class:on_joypad_event(e)
	if not self.thrown_loop or not self.buoy_loop then
		return false
	end

	if lua_helper.reference_equals(e.JoypadEventType, CS.Oak.JoypadEventType.StickDirection) then
		start_coroutine(self.buoy_move, self, e.Stick4WayDirection)
		return true
	end

	return false
end

function local_class:on_stage_start_event(e)
	self:set_button()
	return true
end

function local_class:on_stage_end_event(e)
	self.rescue_wait = false
	self.thrown_loop = false
	self.buoy_loop = false
	self.stage_exit_check = true
	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'rescue_end' then
		self.rescue_wait = false
		return true
	end

	if e:GetParamAt(0) == 'screenplay_active' then
		self.button_screenplay_state_check = false
		return true
	end

	if e:GetParamAt(0) == 'screenplay_deactive' then
		self.button_screenplay_state_check = true
		return true
	end

	return false
end

function local_class:on_focusing_door_end_event(e)
	if self.thrown_loop and self.buoy_loop then
		self.buoy_loop = false
		return true
	end

	return false
end
--endregion

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

--region setting
function local_class:set_buoy()
	self.buoy_list = {}
	self.buoy_default_pos_list = {}

	local tile_map = field.Tilemap
	local gimmick_layer = tile_map.transform:Find('gimmick')

	for i = 0, gimmick_layer.transform.childCount - 1 do
		local cur_obj = gimmick_layer.transform:GetChild(i):GetComponent(typeof(CS.Oak.FieldObject))
		if lua_helper.type_compare(cur_obj.FieldObjectBehaviour, CS.Oak.LuaGimmickBehaviour) and
				cur_obj.FieldObjectBehaviour.ScriptName == 'Buoy' then

			if (cur_obj.FieldObjectBehaviour.DataKey == 'switch') then
				cur_obj.FieldObjectBehaviour = CS.Oak.FloorSwitchBehaviour()
				cur_obj.CrashBehaviour = CS.Oak.FloorSwitchCrashBehaviour()
			else
				cur_obj.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()
				cur_obj.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			end

			cur_obj.Position = vector_util.get_x0z(cur_obj.Position, 0.5)
			cur_obj.Pushable = CS.Oak.NonPushable.Instance

			for j, zone in ipairs(self.main_zone_list) do
				if CS.BoundsExtensions.ContainsXZ(zone.Bounds, cur_obj.Position) then
					if self.buoy_list[j] == nil then
						self.buoy_list[j] = {}
						self.buoy_default_pos_list[j] = {}
					end
					table.insert(self.buoy_list[j], cur_obj)
					table.insert(self.buoy_default_pos_list[j], cur_obj.Position)
				end
			end

		end
	end
end

function local_class:set_zone()
	self.zone_list = {}
	local index = 1
	while true do
		local zone = self.get_zone(index)
		if zone == nil then
			break
		end

		index = index + 1
		table.insert(self.zone_list, zone)
	end
end

function local_class:set_main_zone()
	self.main_zone_list = {}
	local index = 1
	while true do
		local zone = self.get_main_zone(index)
		if zone == nil then
			break
		end

		index = index + 1
		table.insert(self.main_zone_list, zone)
	end
end

function local_class:set_wall()
	self.wall_list = {}

	for _, zone in ipairs(self.zone_list) do
		local index = 1
		for i, main_zone in ipairs(self.main_zone_list) do
			if CS.BoundsExtensions.ContainsXZ(main_zone.Bounds, zone.Bounds.center) then
				index = i
				break
			end
		end

		if self.wall_list[index] == nil then
			self.wall_list[index] = {}
		end

		local x_size = zone.Bounds.size.x
		local z_size = zone.Bounds.size.z
		local offset = 0.5 -- 맵 가운데 체크용
		local x_start = vector_util.get_x0z(zone.Bounds.center).x - x_size / 2 + offset
		local z_start = vector_util.get_x0z(zone.Bounds.center).z - z_size / 2 + offset
		local x_end = vector_util.get_x0z(zone.Bounds.center).x + x_size / 2 - offset
		local z_end = vector_util.get_x0z(zone.Bounds.center).z + z_size / 2 - offset

		for x = x_start, x_end do
			for z = z_start, z_end do
				if field:IsThereFloorAt(unity_class.vector3(x, 1, z)) then
					table.insert(self.wall_list[index], field_object_util.create_virtual_field_object(vector(x, 1, z)))
				end
			end
		end
	end
end

function local_class:set_button()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	field_ui_manager:SetUI(user_party.Leader, ui_type)

	self.button = field_ui_manager:GetUI(user_party.Leader)[ui_type]
	self.button:SetIcon('actbtn_ic_act_android.png')
	self:set_button_active_state(true)

	message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
end

function local_class:set_button_active_state(active)
	if active then
		-- 버튼 킴
		self.button_active = true
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CustomButton1, user_party.Leader)
	else
		-- 버튼 끔
		self.button_active = false
		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CustomButton1, user_party.Leader)
	end
end

function local_class:set_reset_switch()
	self.reset_switch_list = {}
	for i = 1, #self.main_zone_list do
		local cur_switch = self.get_reset_switch(i)

		if cur_switch ~= nil then
			table.insert(self.reset_switch_list, { index = i, switch = cur_switch })
		end
	end
end

function local_class:set_rescue_npc()
	self.rescue_npcs = {}

	local quest_id = 340
	local inner_progress = user_progress:GetStartedQuest(quest_id).InnerProgress

	for i = math.min(inner_progress, 4), 1, -1 do
		table.remove(self.rescue_npc_names, i)
	end

	for _, name in ipairs(self.rescue_npc_names) do
		local cur_npc = get_character(name)

		if cur_npc ~= nil then
			table.insert(self.rescue_npcs, cur_npc)
		end
	end
end
--endregion

--region 로직
function local_class:throw_summer_android()
	sp_util.enter_scene()
	self.thrown_loop = true

	music_player_util.change_stage_music_volume('field', 0.5, 1)

	local leader = get_party_leader()
	local kid_android = self.get_kid_android()
	local offset = direction_util.to_vector3(leader.Direction)

	character_util.convert_to_npc(kid_android)
	wp_util.move_async(kid_android, leader.Position, 3,
			nil, { run = true, last_direction = leader.Direction })

	music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
	scene_util.set_anim(leader, self, 'hold_loop')
	scene_util.set_emotion(kid_android, self, 'attack')
	character_util.move_to_async(kid_android, leader.Position + vector(0, 0.7, 0), 0.3)

	wait_for_sec(0.5)

	local thrown_end_state = {
		thrown = 0,
		ground = 1,
		water = 2,
		buoy = 3,
		npc = 4
	}

	local current_thrown_state = thrown_end_state.thrown

	music_player_util.play_sfx_one_shot('01_hookshot_pull_02')
	character_util.set_anim(leader, { name = 'push' })
	character_util.set_direction(kid_android, leader.Direction)
	character_util.set_anim(kid_android, { name = 'prostrate' })

	self.collied_target = nil
	start_coroutine(self.hook_shot_routine, self, kid_android)

	local move_distance = 4
	local move_time = 0.5
	local start_pos = kid_android.Position
	local end_pos = leader.Position + offset * move_distance

	-- 벽에 던지는 현상 방지
	while not field:IsThereFloorAt(end_pos) do
		end_pos = end_pos - offset
		move_distance = move_distance - 1
	end

	local zone_check = false
	local zone_check_start_pos = leader.Position
	local zone_check_end_pos = end_pos
	local check_distance = 0.15

	while not (vector_util.magnitude(zone_check_end_pos - zone_check_start_pos) < check_distance) do
		zone_check_start_pos = zone_check_start_pos + offset
		if self:main_zone_check(zone_check_start_pos) and self:zone_check(zone_check_start_pos) then
			zone_check = true
			break
		end
	end

	if zone_check then
		local npc_check_start_pos = leader.Position
		local npc_check_end_pos = end_pos
		while not (vector_util.magnitude(npc_check_end_pos - npc_check_start_pos) < check_distance) do
			npc_check_start_pos = npc_check_start_pos + offset
			if self:npc_android_check(npc_check_start_pos) then
				current_thrown_state = thrown_end_state.npc
				break
			end
		end
	end

	if zone_check and current_thrown_state == thrown_end_state.thrown then
		--TODO 반복문이 너무 많이 중첩되었음
		-- 1칸 offset마다 검사
		local check_pos = leader.Position + offset
		local check_count = 0
		local check_max_count = move_distance + 1
		while check_count < check_max_count and self.collied_target == nil do
			local bounds_size = vector(0.1, 2, 0.1)
			local bounds = CS.UnityEngine.Bounds(check_pos, bounds_size)
			local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(bounds, unity_class.vector3.zero)
			-- offset 지점에 걸리는 object 순회
			for i = 0, fo_list.Count - 1 do
				local obj = fo_list[i]
				-- 깔린 virtual field object 판별
				for j, wall in ipairs(self.wall_list[self.target_zone_index]) do
					if lua_helper.reference_equals(obj, wall) and
							wall.ActiveState == active_state('enabled') then
						check_pos = wall.Position + offset
						check_count = check_count + 1
						-- 해당 wall 기준으로 부표 검사(바깥 반복문과 식은 똑같음)
						while check_count < check_max_count do
							-- 부표를 순회해서 해당하는 지 검사
							for _, buoy in ipairs(self.buoy_list[self.target_zone_index]) do
								local buoy_bounds = buoy.Bounds
								if CS.BoundsExtensions.ContainsXZ(buoy_bounds, check_pos) then
									self.collied_target = buoy
									goto continue
								end
							end
							check_pos = check_pos + offset
							check_count = check_count + 1
						end
					end
				end
			end

			:: continue ::
			fo_list:Dispose()
			check_pos = check_pos + offset
			check_count = check_count + 1
		end
	end

	if self.collied_target ~= nil then
		current_thrown_state = thrown_end_state.buoy

		local move_pos = self:find_buoy_pos(kid_android, kid_android.Direction)
		local jump_height = 1
		local time_passed = 0
		while time_passed < move_time and self.thrown_loop do
			time_passed = time_passed + unity_class.time.deltaTime

			local cur_y = math.sin(time_passed / move_time * math.pi) * jump_height
			local cur_pos = unity_class.vector3.Lerp(start_pos, move_pos - offset * 0.5, time_passed / move_time)
			kid_android.Position = cur_pos + vector(0, cur_y, 0)
			coroutine.yield()
		end

		music_player_util.play_sfx_one_shot('01_water_splash_02')
		self.get_fx_common_water_splash_in():Instantiate(kid_android.Position)

		character_util.move_to_async(kid_android, move_pos, move_time)
	else
		local jump_height = 1
		local time_passed = 0
		while time_passed < move_time and self.thrown_loop do
			time_passed = time_passed + unity_class.time.deltaTime

			local cur_y = math.sin(time_passed / move_time * math.pi) * jump_height
			local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, time_passed / move_time)
			kid_android.Position = cur_pos + vector(0, cur_y, 0)
			coroutine.yield()
		end
	end

	if current_thrown_state == thrown_end_state.thrown then
		if self:buoy_check_pos(kid_android.Position) then
			current_thrown_state = thrown_end_state.ground
		elseif self:zone_check(kid_android.Position) then
			current_thrown_state = thrown_end_state.water
		elseif field:IsThereFloorAt(kid_android.Position) then
			current_thrown_state = thrown_end_state.ground
		else
			current_thrown_state = thrown_end_state.water
		end
	end

	local return_leader_routine = function()
		music_player_util.play_sfx_one_shot('01_fish_catch_01')
		self.get_fx_common_water_splash_out():Instantiate(kid_android.Position)
		scene_util.set_direction(kid_android, 'down', false)
		scene_util.set_emotion(kid_android, self, 'surprise')
		scene_util.set_anim(kid_android, self, 'embarrassed')
		character_util.set_active_shadow(kid_android, true)

		jump_height = 3
		start_pos = kid_android.Position
		end_pos = leader.Position - offset
		time_passed = 0
		move_time = 1

		character_util.spine_rotate(kid_android, 360, move_time)
		while time_passed < move_time do
			time_passed = time_passed + unity_class.time.deltaTime

			local cur_y = math.sin(time_passed / move_time * math.pi) * jump_height
			local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, time_passed / move_time)
			kid_android.Position = cur_pos + vector(0, cur_y, 0)
			coroutine.yield()
		end

		character_util.set_position(kid_android, end_pos)
		character_util.spine_rotate(kid_android, 0, 0)
		character_util.remove_anim_and_emotion(kid_android)
		camera_util.return_to_leader(0.5)
	end

	-- 땅에 착지했을 경우
	if current_thrown_state == thrown_end_state.ground then
		music_player_util.play_sfx_one_shot('01_hit_npc_01')
		character_util.set_side_direction(kid_android)
		character_util.set_anim(kid_android, { name = 'seat' })
		character_util.set_emotion(kid_android, { name = 'tired' })
		camera_util.move_async(kid_android.Position, 1, { end_target = kid_android })

		wait_for_sec(0.5)

		character_util.remove_anim_and_emotion(kid_android)
		wp_util.move(kid_android,
				leader.Position - offset, nil, 1, { run = true })

		camera_util.return_to_leader(1)
	end

	-- 물에 빠졌을 경우
	if current_thrown_state == thrown_end_state.water then
		music_player_util.play_sfx_one_shot('01_water_splash_02')
		character_util.set_direction(kid_android, 'down')
		character_util.set_anim(kid_android, { name = 'idle' })
		character_util.set_emotion(kid_android, { name = 'tired' })
		self.get_fx_common_water_splash_in():Instantiate(kid_android.Position)
		character_util.set_active_shadow(kid_android, false)
		camera_util.move_async(kid_android.Position, 1, { end_target = kid_android })

		wait_for_sec(1)

		return_leader_routine()
	end

	-- 부표에 충돌했을 경우
	if current_thrown_state == thrown_end_state.buoy then
		character_util.set_anim(kid_android, { name = 'push' })
		character_util.set_emotion(kid_android, { name = 'attack' })
		character_util.set_active_shadow(kid_android, false)
		camera_util.move_async(kid_android.Position, 1, { end_target = kid_android })

		self:buoy_routine()

		--조작 중 스테이지 종료 시 강제 종료
		if self.stage_exit_check then
			return
		end

		return_leader_routine()
	end

	if current_thrown_state == thrown_end_state.npc then
		self.get_fx_common_water_splash_in():Instantiate(kid_android.Position)
		character_util.set_direction(kid_android, 'left')
		character_util.set_anim(kid_android, { name = 'push' })
		character_util.set_emotion(kid_android, { name = 'attack' })
		camera_util.move_async(kid_android.Position, 1, { end_target = kid_android })

		for i, npc in ipairs(self.rescue_npcs) do
			if npc.Name == self.collied_npc.Name then
				table.remove(self.rescue_npcs, i)
			end
		end

		self.rescue_wait = true
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'rescue_active' }))

		while self.rescue_wait do
			coroutine.yield()
		end
	end

	self.thrown_loop = false
	self.collied_target = nil
	self.collied_npc = nil

	character_util.convert_to_following_npc(kid_android, user_party)
	party_util.remove_animation()

	if current_thrown_state ~= thrown_end_state.npc then
		music_player_util.change_stage_music_volume('field', 1, 1)
		sp_util.exit_scene(nil, leader)
	end
end

function local_class:hook_shot_routine(target)
	local leader = get_party_leader()
	local pooled_hook_shot = self.get_hook_shot():Instantiate(unity_class.vector3.zero)
	local hook_shot = pooled_hook_shot:GetComponent(typeof(CS.Oak.HookShot))
	hook_shot.Head.gameObject:SetActive(false)

	while self.thrown_loop do
		local target_position = target.Position + vector(0, 0.3, 0)
		local leader_position = leader.Position + vector(0, 0.3, 0)

		local diff = (target_position - leader_position)
		local direction = diff.normalized
		hook_shot:SetFromTo(leader_position, target_position + direction * 1)
		coroutine.yield()
	end

	pooled_hook_shot:Dispose()
end

function local_class:buoy_routine()
	local leader = get_party_leader()

	-- attack range 재활용 방법으로 변경 필요
	local attack_range = CS.AttackRange.CreateCircle(
			vector_util.get_x0z(leader.Position, leader.Position.y + 0.1), self.fishing_radius)

	attack_range:Show()

	party_util.reset_controllers()

	-- 모든 조작을 막아놓음
	local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
	manual_touch_state:DisableControls(CS.Oak.DisabledControls.All)

	local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
	message_system:SendSync(user_party.Leader.FieldObjectController, state_change_event)

	coroutine.yield(nil)

	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.SkillButton
			| CS.Oak.FieldUiType.ClassButton | CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.ModeChangeButton
			| CS.Oak.FieldUiType.TeamCombinationButton | CS.Oak.FieldUiType.ActionButton)

	field_ui_manager:Show()

	self.buoy_loop = true
	while self.buoy_loop do
		coroutine.yield()
	end

	attack_range.gameObject:SetActive(false)
	CS.UnityEngine.Object.Destroy(attack_range)

	if self.stage_exit_check then
		return
	end

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()
end

function local_class:buoy_move(input_direction)
	field_ui_manager:Hide()
	self.button_can_input_check = false

	local leader = get_party_leader()
	local kid_android = self.get_kid_android()
	local dir = direction_util.to_vector3(input_direction)

	local dont_move_speech = function(emotion, speech_key)
		music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
		scene_util.set_emotion(kid_android, self, emotion)
		scene_util.show_normal_speech_async(kid_android, speech_key)

		scene_util.set_emotion(kid_android, self, 'attack')
		field_ui_manager:Show()
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CustomButton1, kid_android)
		self.button_can_input_check = true
	end

	-- 다음 위치 계산
	local bounds = self.collied_target.Bounds
	local buoy_check_pos = bounds.center + dir

	local dist = vector_util.distance(
			vector_util.get_x0z(buoy_check_pos, 0), vector_util.get_x0z(leader.Position, 0))

	if dist > self.fishing_radius then
		dont_move_speech('tired', 'qc_sm_rescued_1')
		return
	end

	if self.collied_target.Name == '[gimmick]buoy_2' then
		local offset = dir.x < 0.1 and vector(0.5, 0, 0) or vector(0, 0, 0.5)
		local zone_check_pos = bounds.center + dir * 1.5 + offset
		local zone_check_pos_2 = bounds.center + dir * 1.5 - offset

		if not self:zone_check(zone_check_pos) or not self:zone_check(zone_check_pos_2) then
			dont_move_speech('tired', 'qc_sm_rescued_1')
			return
		end
	else
		if not self:zone_check(bounds.center + dir) then
			dont_move_speech('tired', 'qc_sm_rescued_1')
			return
		end
	end

	if self:buoy_check(buoy_check_pos) then
		dont_move_speech('tired', 'qc_sm_rescued_1')
		return
	end

	if self:npc_bound_check(buoy_check_pos) then
		dont_move_speech('attack', 'qc_sm_rescued_3')
		return
	end

	if self:move_android_check(kid_android, dir) then

		local water_sound = music_player_util.play_sfx({
			sfx_name = '01_water_loop_06', parent = maam, fade_in_time = 0.5,
			loop = true, type_priority = 'loop', player_priority = 'npc' })

		character_util.move_to(kid_android, kid_android.Position + dir, 1)
		character_util.move_to(self.collied_target, self.collied_target.Position + dir, 1)
		wait_for_sec(0.7)

		water_sound:FadeOut()
		wait_for_sec(0.3)

		character_util.look_at(leader, kid_android)
		-- 부표 위치에 invisible wall 있으면 지나갈 수 있도록 처리
		self:wall_active()

		field_ui_manager:Show()
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CustomButton1, kid_android)
		self.button_can_input_check = true
	else
		dont_move_speech('tired', 'qc_sm_rescued_1')
	end
end

function local_class:zone_check(target_pos)
	for i, zone in ipairs(self.zone_list) do
		if CS.BoundsExtensions.ContainsXZ(zone.Bounds, target_pos) then
			return true
		end
	end
	return false
end

function local_class:main_zone_check(target_pos)
	for i, zone in ipairs(self.main_zone_list) do
		if CS.BoundsExtensions.ContainsXZ(zone.Bounds, target_pos) then
			self.target_zone_index = i
			return true
		end
	end

	self.target_zone_index = 0
	return false
end

--- 사이즈가 다른 Bounds가 겹쳐지는 판정을 위해 scale 적용
function local_class:buoy_check(target_pos)
	if self.target_zone_index == 0 then
		return false
	end

	local bounds_scale = 0.9
	local temp_bounds = CS.UnityEngine.Bounds(target_pos,
			self.collied_target.Bounds.size * bounds_scale)

	for _, buoy in ipairs(self.buoy_list[self.target_zone_index]) do
		if not lua_helper.reference_equals(self.collied_target, buoy) and
				bounds_util.is_overlapping_xz(buoy.Bounds, temp_bounds) then
			return true
		end
	end

	return false
end

-- 대상 위치가 부표 위에 있는지
function local_class:buoy_check_pos(target_pos)
	if self.target_zone_index == 0 then
		return false
	end

	for _, buoy in ipairs(self.buoy_list[self.target_zone_index]) do
		if not lua_helper.reference_equals(self.collied_target, buoy) and
				CS.BoundsExtensions.ContainsXZ(buoy.Bounds, target_pos) then
			return true
		end
	end

	return false
end

--- 길막는 virtual field object 체크
function local_class:wall_active()
	-- 최초 1회는 전체 체크
	if self.target_zone_index == 0 then
		for i = 1, #self.wall_list do
			for j, wall in ipairs(self.wall_list[i]) do
				wall.ActiveState = active_state('enabled')
				for k, buoy in ipairs(self.buoy_list[i]) do
					if CS.BoundsExtensions.ContainsXZ(buoy.Bounds, wall.Position) then
						wall.ActiveState = active_state('disabled')
						break
					end
				end
			end
		end
	else
		for i, wall in ipairs(self.wall_list[self.target_zone_index]) do
			wall.ActiveState = active_state('enabled')
			for j, buoy in ipairs(self.buoy_list[self.target_zone_index]) do
				if CS.BoundsExtensions.ContainsXZ(buoy.Bounds, wall.Position) then
					wall.ActiveState = active_state('disabled')
					break
				end
			end
		end
	end
end

--- 해당 구역 부표 리셋
function local_class:reset_buoy(switch_index)
	for i, buoy in ipairs(self.buoy_list[switch_index]) do
		local buoy_bounds = buoy.Bounds
		local prev_effect_pos = buoy_bounds.center
		local effect_size = buoy_bounds.size

		if buoy.Position ~= self.buoy_default_pos_list[switch_index][i] then
			buoy.Position = self.buoy_default_pos_list[switch_index][i]

			local effect_pool = unity_object_pool.GetOrCreate('FX_reset_object')

			local prev_pos_effect = effect_pool:Instantiate(prev_effect_pos)
			prev_pos_effect.transform.localScale = effect_size

			local reset_pos_effect = effect_pool:Instantiate(buoy_bounds.center)
			reset_pos_effect.transform.localScale = effect_size
		end
	end

	self.target_zone_index = switch_index
	self:wall_active()
	self.target_zone_index = 0
end

--- 부표 안착 위치를 가져옴
function local_class:find_buoy_pos(target, dir)
	local size_offset = vector(0, 0, 0)
	local plus_offset = vector(0, 0, 0)
	self.conner_offset = vector(0, 0, 0)

	-- 2 x 2 부표 처리
	if self.collied_target.Name == '[gimmick]buoy_2' then
		-- AA 72가 오른쪽에 있을 때
		if dir == character_util.get_direction('left') then
			size_offset = vector(1.3, 0, 0)
			if self.collied_target.Bounds.center.z < target.Position.z then
				plus_offset = vector(0, 0, 0)
				self.conner_offset = vector(1.4, 0, 0.4)
			else
				plus_offset = vector(0, 0, -1)
				self.conner_offset = vector(1.4, 0, -0.4)
			end
		elseif dir == character_util.get_direction('right') then
			size_offset = vector(-1.3, 0, 0)
			if self.collied_target.Bounds.center.z < target.Position.z then
				plus_offset = vector(0, 0, 0)
				self.conner_offset = vector(-1.4, 0, 0.4)
			else
				plus_offset = vector(0, 0, -1)
				self.conner_offset = vector(-1.4, 0, -0.4)
			end
		elseif dir == character_util.get_direction('up') then
			size_offset = vector(0, 0, -1.5)

			if self.collied_target.Bounds.center.x < target.Position.x then
				plus_offset = vector(0.5, 0, 0)
				self.conner_offset = vector(0.4, 0, -1.4)
			else
				plus_offset = vector(-0.5, 0, 0)
				self.conner_offset = vector(-0.4, 0, -1.4)
			end
		elseif dir == character_util.get_direction('down') then
			size_offset = vector(0, 0, 0.9)

			if self.collied_target.Bounds.center.x < target.Position.x then
				plus_offset = vector(0.5, 0, 0)
				self.conner_offset = vector(0.4, 0, 1.4)
			else
				plus_offset = vector(-0.5, 0, 0)
				self.conner_offset = vector(-0.4, 0, 1.4)
			end
		end
	else
		if dir == character_util.get_direction('left') then
			size_offset = vector(0.6, 0, -0.3)
			self.conner_offset = vector(1, 0, 0)
		elseif dir == character_util.get_direction('right') then
			size_offset = vector(-0.6, 0, -0.3)
			self.conner_offset = vector(-1, 0, 0)
		elseif dir == character_util.get_direction('up') then
			size_offset = vector(0, 0, -1)
			self.conner_offset = vector(0, 0, -1)
		elseif dir == character_util.get_direction('down') then
			size_offset = vector(0, 0, 0.4)
			self.conner_offset = vector(0, 0, 1)
		end
	end

	return self.collied_target.Bounds.center + size_offset + plus_offset
end

--- 부표 모서리 좌표를 가져옴
function local_class:find_corner_pos(target, move_dir)
	local plus_offset = vector(0, 0, 0)
	local offset = self:find_buoy_pos(target, target.Direction)

	-- 2 x 2 부표 처리
	if self.collied_target.Name == '[gimmick]buoy_2' then
		if move_dir == 'up' then
			plus_offset = vector(0, 0, 1.4)
		elseif move_dir == 'down' then
			plus_offset = vector(0, 0, -0.5)
		elseif move_dir == 'left' then
			plus_offset = vector(-0.8, 0, 0)
		elseif move_dir == 'right' then
			plus_offset = vector(0.8, 0, 0)
		end
	else
		if move_dir == 'up' then
			plus_offset = vector(0, 0, 0.7)
		elseif move_dir == 'down' then
			plus_offset = vector(0, 0, -0.7)
		elseif move_dir == 'left' then
			plus_offset = vector(-0.6, 0, 0)
		elseif move_dir == 'right' then
			plus_offset = vector(0.6, 0, 0)
		end
	end

	return offset + plus_offset
end

--- 부표 움직일 때 코너링이 필요한 경우 움직여주는 함수
function local_class:move_android_check(target, next_dir)
	local center = self.collied_target.Bounds.center + self.conner_offset
	if not self:buoy_check_pos(center + next_dir) and self:zone_check(center + next_dir) then
		return true
	end

	local check_pos_list = {
		center + vector(1, 0, 0),
		center - vector(1, 0, 0),
		center + vector(0, 0, 1),
		center - vector(0, 0, 1)
	}

	local conner_pos = nil
	local conner_dir = nil
	for i, check_pos in ipairs(check_pos_list) do
		-- 4방향 검사
		if not self:buoy_check_pos(check_pos) and self:zone_check(check_pos) then
			if target.Direction == character_util.get_direction('up') or
					target.Direction == character_util.get_direction('down') then
				if i == 1 then
					conner_dir = 'left'
					-- self.conner_offset 재설정
					self:find_buoy_pos(target, character_util.get_direction(conner_dir))
					local conner_check_pos = self.collied_target.Bounds.center + self.conner_offset

					-- 코너로 위치할 위치 4방향 검사
					if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
						-- 사각형 기준 크기 1은 ㄱ ㄴ 자 형식으로 3곳을 체크해야 하지만 크기 2는 최대 4곳을 체크해줘야 함
						if self.collied_target.Name == '[gimmick]buoy_2' then
							conner_check_pos = conner_check_pos + next_dir
							if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
								conner_pos = self:find_corner_pos(target, 'right')
								break
							end
						else
							conner_pos = self:find_corner_pos(target, 'right')
							break
						end
					end
				elseif i == 2 then
					conner_dir = 'right'
					self:find_buoy_pos(target, character_util.get_direction(conner_dir))
					local conner_check_pos = self.collied_target.Bounds.center + self.conner_offset

					if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
						if self.collied_target.Name == '[gimmick]buoy_2' then
							conner_check_pos = conner_check_pos + next_dir
							if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
								conner_pos = self:find_corner_pos(target, 'left')
								break
							end
						else
							conner_pos = self:find_corner_pos(target, 'left')
							break
						end
					end
				end
			elseif target.Direction == character_util.get_direction('left') or
					target.Direction == character_util.get_direction('right') then
				if i == 3 then
					conner_dir = 'down'
					self:find_buoy_pos(target, character_util.get_direction(conner_dir))
					local conner_check_pos = self.collied_target.Bounds.center + self.conner_offset

					if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
						if self.collied_target.Name == '[gimmick]buoy_2' then
							conner_check_pos = conner_check_pos + next_dir
							if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
								conner_pos = self:find_corner_pos(target, 'up')
								break
							end
						else
							conner_pos = self:find_corner_pos(target, 'up')
							break
						end
					end
				elseif i == 4 then
					conner_dir = 'up'
					self:find_buoy_pos(target, character_util.get_direction(conner_dir))
					local conner_check_pos = self.collied_target.Bounds.center + self.conner_offset

					--if not self:buoy_check_pos(conner_check_pos) and self:zone_check(check_pos) then
					--	conner_pos = self:find_corner_pos(target, 'down')
					--	break
					--end
					if not self:buoy_check_pos(conner_check_pos) and self:zone_check(conner_check_pos) then
						if self.collied_target.Name == '[gimmick]buoy_2' then
							conner_check_pos = conner_check_pos + next_dir
							if not self:buoy_check_pos(conner_check_pos) and self:zone_check(check_pos) then
								conner_pos = self:find_corner_pos(target, 'down')
								break
							end
						else
							conner_pos = self:find_corner_pos(target, 'down')
							break
						end
					end
				end
			end
		end
	end

	if conner_pos ~= nil then
		character_util.move_to_async(target, conner_pos, 0.5)

		character_util.set_direction(target, conner_dir)
		character_util.move_to_async(target, self:find_buoy_pos(target, target.Direction))
		return true
	end

	return false
end

--- npc와 부표가 너무 가까이에 있는지 체크
function local_class:npc_bound_check(buoy_check_pos)
	if self.collied_target == nil then
		return false
	end

	for _, npc in ipairs(self.rescue_npcs) do
		local bounds_size = vector(2, 2, 2)
		local temp_bounds = CS.UnityEngine.Bounds(npc.Position, bounds_size)
		local buoy_bounds = CS.UnityEngine.Bounds(buoy_check_pos, self.collied_target.Bounds.size)

		if bounds_util.is_overlapping_xz(buoy_bounds, temp_bounds) then
			return true
		end
	end

	return false
end

--- npc와 sm_android가 만나는지 체크용
function local_class:npc_android_check(target_pos)
	for _, npc in ipairs(self.rescue_npcs) do
		local bounds_size = vector(2, 2, 2)
		local temp_bounds = CS.UnityEngine.Bounds(npc.Position, bounds_size)

		if CS.BoundsExtensions.ContainsXZ(temp_bounds, target_pos) then
			self.collied_npc = npc
			return true
		end
	end

	return false
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
