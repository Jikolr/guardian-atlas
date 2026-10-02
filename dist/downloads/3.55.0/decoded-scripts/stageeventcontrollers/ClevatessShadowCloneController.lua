local local_class = newclass('ClevatessShadowCloneController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.shadow_clone_active_table = {}

	self.current_shadow_clone_table = nil

	self.constants_data = nil

	--region 버튼 관련
	self.button = nil
	self.button_icon_tf = nil
	self.button_active = false

	self.button_icon_name_table = {
		shadow_clone_1 = 'actbtn_ic_act_shadow_red.png',
		shadow_clone_2 = 'actbtn_ic_act_shadow_purple.png'
	}

	self.shadow_animation_table = {
		shadow_clone_1 = 'unique/red',
		shadow_clone_2 = 'unique/purple'
	}

	self.current_button_icon_name = self.button_icon_name_table.shadow_clone_1
	--endregion

	self.gimmick_level_state = {
		not_activate = 0,
		one_and_not_tp = 1,
		one_and_tp = 2,
		two_and_tp = 3,
	}

	self.fx = {
		shadow = function()
			return unity_object_pool.GetOrCreate('fx_ct_gimmick_shadow_start_loop')
		end,
		fx_loop_shadow_clone_1 = function()
			return unity_object_pool.GetOrCreate('fx_ct_red_aura_start_loop')
		end,
		fx_loop_shadow_clone_2 = function()
			return unity_object_pool.GetOrCreate('fx_ct_purple_aura_start_loop')
		end,
		fx_loop_end_shadow_clone_1 = function()
			return unity_object_pool.GetOrCreate('fx_ct_red_aura_loop_end')
		end,
		fx_loop_end_shadow_clone_2 = function()
			return unity_object_pool.GetOrCreate('fx_ct_purple_aura_loop_end')
		end,
		klen_shadow = function()
			return unity_object_pool.GetOrCreate('fx_ct_clen_shadow_gimmick_start_loop')
		end,
		custom_sprite = function()
			return unity_object_pool.GetOrCreate('custom_sprite')
		end,
		explosion = function()
			return unity_object_pool.GetOrCreate('fx_ct_gimmick_shadow_explosion')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end,
	}

	self.gimmick_level = self.gimmick_level_state.not_activate

	self.quest_id = 7002101

	self.request_spawner = nil

	self.spawner_table = {}

	self.is_custom_screen_play = false
	self.is_reset_button = false

	self.sp_manager = nil
	self.current_select_clone_name = nil

	self.shadow_screen_play = false

	self.is_gamepad_connect = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadConnectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadConnectedEvent), 'on_gamepad_connected_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent), 'on_gamepad_disconnected_event')

	self.sp_manager = get_or_create_global_table('Quest/Main/LaboseWorld/Common/LaboseWorldScreenplayManager')

	self.constants_data = require('stageeventcontrollers/ClevatessShadowCloneControllerData.lua')

	self.fx:load_all()

	if CS.Oak.Game.Instance.InputManager.GamepadEnabled then
		self.is_gamepad_connect = true

		message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	end

	local quest_progress = user_progress:GetStartedQuest(self.quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress > 6 then
			self.gimmick_level = self.gimmick_level_state.two_and_tp
		elseif quest_progress.InnerProgress > 4 then
			self.gimmick_level = self.gimmick_level_state.one_and_tp
		elseif quest_progress.InnerProgress > 2 then
			self.gimmick_level = self.gimmick_level_state.one_and_not_tp
		else
			self.gimmick_level = self.gimmick_level_state.not_activate
		end
	end
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.reference_equals(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	return false
end

function local_class:on_touch_event(e)
	if self.is_gamepad_connect then
		return
	end

	if e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown then

		self:shadow_clone_action()
	end
end

function local_class:on_gamepad_connected_event(e)
	self.is_gamepad_connect = true

	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	return false
end

function local_class:on_gamepad_disconnected_event(e)
	self.is_gamepad_connect = false

	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	return false
end

function local_class:on_gamepad_event(e)
	if e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown then

		self:shadow_clone_action()

		return true
	end

	return false
end

function local_class:on_stage_start_event(e)
	local created, dv_sp_manager = global_table_util.try_create_dream_village_screenplay_manager()
	self.sp_controller = dv_sp_manager:get_sp_controller(self.cs_controller)

	self:create_button()
end

function local_class:on_camera_grid_enter_event(e)
	if (lua_helper.reference_equals(e.FieldObject, get_party_leader()) or lua_helper.reference_equals(e.FieldObject, user_party)) then
		self:action_spawner_table(function(spawner)
			local lua_table = spawner.FieldObjectBehaviour:GetLuaTable()

			lua_table:check_enter_camera_gird(e.CameraGrid)
		end)
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if (lua_helper.reference_equals(e.FieldObject, get_party_leader()) or lua_helper.reference_equals(e.FieldObject, user_party)) then
		self:action_spawner_table(function(spawner)
			local lua_table = spawner.FieldObjectBehaviour:GetLuaTable()

			lua_table:check_leave_camera_gird(e.CameraGrid)
		end)

		self:reset_shadow_clone()
	end

	return false
end

function local_class:on_battle_start_event(e)
	self:reset_shadow_clone()
	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	if not self.is_reset_button then
		local leader = get_party_leader()
		local ui_type = CS.Oak.FieldUiType.CustomButton1

		field_ui_manager:RemoveUI(leader, ui_type)

		self.is_reset_button = true
	end

	return false
end


--endregion

--region 버튼 관련
function local_class:create_button()
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	field_ui_manager:SetUI(leader, ui_type)

	self.button = field_ui_manager:GetUI(leader)[ui_type]
	self.button_icon_tf = CS.Utils.FindChildRecursively(self.button.transform, 'Icon')
	self.button_icon_offset = CS.Utils.FindChildRecursively(self.button.transform, 'offset')
	self.button:SetIcon(self.current_button_icon_name)
	self.button:ToggleIconTintChange(false)

	self.button_active = false
	field_ui_manager:HideTargetUI(ui_type, leader)

	message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
end

function local_class:set_button_active_state(active)
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	if active then
		-- 버튼 킴
		if not self.button_active then
			self.button_active = true

			if self.is_reset_button then
				self.is_reset_button = false

				field_ui_manager:SetUI(leader, ui_type)

				self.button:SetIcon(self.current_button_icon_name)
				self.button:ToggleIconTintChange(false)

				message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
			end

			field_ui_manager:ShowTargetUI(ui_type, leader)
		end
	else
		-- 버튼 끔
		if self.button_active then
			self.button_active = false
			field_ui_manager:HideTargetUI(ui_type, leader)
		end
	end
end

function local_class:set_button_icon(icon_name)
	if self.current_button_icon_name == icon_name then
		return
	end

	self.current_button_icon_name = icon_name

	self.button:SetIcon(icon_name)

	start_coroutine(function()
		self:shake_button_async(1.2, 0.16)
	end)
end

function local_class:button_pressed()
	local tint_key = 'party_color_black'
	local shadow = get_field_object(self.current_select_clone_name)
	local leader = get_party_leader()

	local lua_table = shadow.FieldObjectBehaviour:GetLuaTable()

	if lua_table.current_state ~= lua_table.state.idle then
		return
	end

	if lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerInteractState) then
		return
	end

	field_ui_util.hide_default_single_ui()

	message_system:SendSync(leader.CharacterBehaviour,
			CS.Oak.ActionStateChangeEvent.Create(CS.Oak.CharacterInfiltrationState.Create(leader)))

	local set_shadow_direction = get_party_leader().Direction

	self.shadow_screen_play = true

	music_player_util.play_sfx_one_shot('02_klen_myth_cwp_ready_01')

	field_object_util.set_active_state(leader, active_state_type.visible)

	self:set_button_active_state(false)

	field_ui_util.hide_target_ui({
		show_target = field_ui_type.party_state,
		show_minimap = true,
		show_navigation_bar = true,
		show_ui_quest_marker = true
	})

	party_util.foreach_member(function(index, member)
		field_ui_util.hide_target_ui({
			owner = member,
			hide_target = field_ui_type.character_stats
		})

		if not lua_helper.reference_equals(member, leader) then
			local state_change_event = CS.Oak.StateChangeEvent.Create(CS.Oak.CharacterIdleState.Create(member))

			message_system:SendSync(member.FieldObjectController, state_change_event)
		end
	end)

	camera_util.cancel_move()

	local party_shadow_fx_table = {}
	local fx_end_shadow_loop = nil

	lua_table:dispose_loop_fx()

	local shadow_fx_prefix = 'fx_loop_end_'
	local fx_loop_end = self.fx[shadow_fx_prefix .. shadow.Name]():Instantiate(shadow.Position)

	do
		local scale_facter = 0.3

		fx_end_shadow_loop = self.fx.shadow():Instantiate(shadow.Position)

		--모든 파티원 위치에도 동일하게 이펙트 출력이 필요합니다.
		party_util.foreach_member(function(_, member)
			local fx_start_shadow_loop = self.fx.shadow():Instantiate(member.Position)

			fx_start_shadow_loop.transform.localScale = unity_class.vector3.one * scale_facter
			fx_start_shadow_loop.transform.position = member.Position

			table.insert(party_shadow_fx_table, fx_start_shadow_loop)
		end)

		--최초 크기를 약간 크게 하여, 내려갔을 때 더 자연스럽게 만들려는 의도입니다.

		fx_end_shadow_loop.transform.localScale = unity_class.vector3.one * scale_facter

		fx_end_shadow_loop.transform.position = shadow.Position
	end

	--기믹 실행 동작 (총 0.6초)
	--기믹 버튼 터치 시 컨트롤 빼앗고 아래의 순서대로 연출을 실행
	--1번연출
	--플레이어 파티 현재 방향, 현재 표정, cross_arm 실행. async 아님
	party_util.set_anim({ name = 'cross_arm', loop = false })

	--플레이어 파티 스파인 0.2초 동안 검은색 틴트 100%로 증가. async 아님
	party_util.add_color(tint_key, unity_class.color.black, 1, self.constants_data.party_black_tint_duration)

	wait_for_sec(0.1)

	local origin_leader_pos = leader.Position
	local origin_shadow_pos = shadow.Position

	--플레이어 위치와 전환 예정 좌표에 fx_ct_gimmick_shadow_start_loop 이펙트 출력. async 아님
	--그림자, 플레이어 파티 스파인 0.2초 동안 y값 -1.5로 하강 async
	do
		local duration = self.constants_data.down_fall_duration

		wait_all_lua(
				function()
					local time_passed = 0
					local start_pos_table = {}
					local target_pos_table = {}

					party_util.foreach_member(function(_, member)
						local start_pos = member.Position
						local target_pos = vector(start_pos.x, self.constants_data.teleport_y_offset, start_pos.z)

						start_pos_table[member] = start_pos
						target_pos_table[member] = target_pos
					end)

					while time_passed <= duration do
						local progress = unity_class.mathf.Clamp01(time_passed / duration)

						time_passed = time_passed + unity_class.time.deltaTime

						party_util.foreach_member(function(_, member)
							local cur_pos = start_pos_table[member] * (1 - progress) + target_pos_table[member] * progress

							member.Position = cur_pos
						end)

						coroutine.yield(nil)
					end

					party_util.foreach_member(function(_, member)
						member.Position = target_pos_table[member]
					end)
				end,

				function()
					self:shadow_move_async(
							shadow,
							vector(shadow.Position.x, self.constants_data.teleport_y_offset, shadow.Position.z),
							duration
					)
				end,

				function()
					local time_passed = 0
					local shadow_duration = 0.2
					local end_scale = vector(1, 1, 1)

					while time_passed < shadow_duration do
						local progress = time_passed / shadow_duration

						time_passed = time_passed + unity_class.time.deltaTime

						for _, fx in pairs(party_shadow_fx_table) do
							fx.transform.localScale = unity_class.vector3.zero * (1 - progress) + end_scale * progress
						end

						fx_end_shadow_loop.transform.localScale = unity_class.vector3.zero * (1 - progress) + end_scale * progress

						coroutine.yield(nil)
					end

					for _, fx in pairs(party_shadow_fx_table) do
						fx.transform.localScale = end_scale
					end

					fx_end_shadow_loop.transform.localScale = end_scale
				end
		)
	end

	fx_loop_end:Dispose()

	--2번연출
	--카메라 12의 속도로 위치 전환 예정 좌표로 이동. async
	do
		local speed = self.constants_data.camera_speed
		local end_pos = self:get_round_vector(shadow.Position)
		local start_pos = self:get_round_vector(leader.Position)
		local dist = start_pos - end_pos
		local duration = dist.magnitude / speed

		camera_util.move_async(
				vector(end_pos.x, origin_shadow_pos.y, end_pos.z), duration)
	end

	--3번연출
	do
		local leader_pos = self:get_round_vector(leader.Position)
		local shadow_pos = self:get_round_vector(shadow.Position)
		local party_distance = 0.7
		local dir = character_util.get_look_direction(leader)
		local dir_vec = direction_util.to_vector3_ver2(dir) * party_distance
		local offset = unity_class.vector3.zero

		logger_util.log('x : ' .. leader_pos.x .. 'y : ' .. leader_pos.y .. 'z : ' .. leader_pos.z)
		logger_util.log('x : ' .. shadow_pos.x .. 'y : ' .. shadow_pos.y .. 'z : ' .. shadow_pos.z)

		party_util.foreach_member(function(_, member)
			member.Position = shadow_pos + offset

			self:check_floor(member)

			offset = offset + (-dir_vec)
		end)

		shadow.Position = leader_pos

		self:check_floor(shadow)
	end

	do
		local spine_controller = shadow.transform:GetComponent(typeof(CS.Oak.SpineController))

		spine_controller.Direction = direction_util.to_side_dir(set_shadow_direction)
	end

	do
		local duration = self.constants_data.down_fall_duration

		party_util.remove_color(tint_key, self.constants_data.party_black_tint_duration)

		wait_all_lua(
				function()
					local time_passed = 0
					local start_pos_table = {}
					local target_pos_table = {}

					party_util.foreach_member(function(_, member)
						local start_pos = member.Position
						local target_pos = vector(start_pos.x, origin_shadow_pos.y, start_pos.z)

						start_pos_table[member] = start_pos
						target_pos_table[member] = target_pos
					end)

					while time_passed <= duration do
						local progress = unity_class.mathf.Clamp01(time_passed / duration)

						time_passed = time_passed + unity_class.time.deltaTime

						party_util.foreach_member(function(_, member)
							local cur_pos = start_pos_table[member] * (1 - progress) + target_pos_table[member] * progress

							member.Position = cur_pos
						end)

						coroutine.yield(nil)
					end

					party_util.foreach_member(function(_, member)
						member.Position = target_pos_table[member]
					end)
				end,

				function()
					self:shadow_move_async(shadow, vector(shadow.Position.x, origin_leader_pos.y, shadow.Position.z), duration)
					lua_table:get_or_create_loop_fx()
				end,

				function()
					local time_passed = 0
					local shadow_duration = 0.2
					local start_scale = vector(1, 1, 1)

					while time_passed < shadow_duration do
						local progress = time_passed / shadow_duration

						time_passed = time_passed + unity_class.time.deltaTime

						for _, fx in pairs(party_shadow_fx_table) do
							fx.transform.localScale = start_scale * (1 - progress) + unity_class.vector3.zero * progress
						end

						fx_end_shadow_loop.transform.localScale = start_scale * (1 - progress) + unity_class.vector3.zero * progress

						coroutine.yield(nil)
					end
				end)

		camera_util.return_to_leader(duration)
	end

	do
		for _, fx in pairs(party_shadow_fx_table) do
			fx:Dispose()
		end
	end

	fx_end_shadow_loop:Dispose()

	do
		local function check_switch(fo)
			local search_bounds = CS.UnityEngine.Bounds(fo.Position, vector(1, 1, 1))
			local bounds_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(search_bounds, unity_class.vector3.zero)

			for _, switch in pairs(bounds_list) do
				if lua_helper.type_compare(switch.FieldObjectBehaviour, CS.Oak.FloorSwitchBehaviour) then
					message_system:SendSync(switch, CS.Oak.FloorSwitchStepOnEvent.Create(fo))
				end
			end
		end

		check_switch(shadow)
		check_switch(leader)
	end

	do
		local is_activate_shadow_clone = false

		for _, fo in pairs(self.current_shadow_clone_table) do
			local name = fo.name
			local is_activate_shadow = self.shadow_clone_active_table[name]

			if fo.name ~= self.current_select_clone_name and is_activate_shadow then
				self.current_select_clone_name = name
				is_activate_shadow_clone = true

				self:set_button_icon(self.button_icon_name_table[name])
				break
			end
		end
	end

	-- 스파인 0.2초 동안 y값 0으로 상승 async 아님
	--fx_ct_gimmick_shadow_end 이펙트 출력. async 아님
	--플레이어 파티 스파인 0.2초 동안 검은색 틴트 원복. async
	--플레이어 컨트롤 돌려준다.

	--플레이어는 2일차부터 UI조작을 통해 1기의 그림자 분신과 위치 전환이 가능하다.
	--그림자가 활성화되어 있을 때만 위치 전환이 가능하다.
	--별도의 쿨타임은 존재하지 않으나, 시전 시간 동안은 재동작시킬 수 없다.
	--붉은색 UI 버튼을 조작하면 기믹이 실행된다.
	party_util.remove_anim_and_emotion()

	party_util.foreach_member(function(index, member)
		field_ui_util.show_target_ui({
			owner = member,
			show_target = field_ui_type.character_stats
		})

		if not lua_helper.reference_equals(member, leader) then
			message_system:SendSync(member, CS.Oak.StateResetEvent.Instance)
		end
	end)

	message_system:SendSync(leader.CharacterBehaviour,
			CS.Oak.ActionStateChangeEvent.Create(nil))

	self.shadow_screen_play = false

	field_object_util.set_active_state(leader, active_state_type.enabled)

	self:set_button_active_state(true)

	if lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerInteractState) then

		return
	end

	field_ui_util.show_default_single_ui()
end

function local_class:shadow_move_async(fo, target_pos, duration)
	local time_passed = 0
	local start_pos = fo.Position

	while time_passed <= duration do
		local progress = unity_class.mathf.Clamp01(time_passed / duration)
		local cur_pos = start_pos * (1 - progress) + target_pos * progress

		time_passed = time_passed + unity_class.time.deltaTime

		fo.Position = cur_pos

		coroutine.yield(nil)
	end

	fo.Position = target_pos
end

function local_class:shake_button_async(max_scale, dur)
	local time_passed = 0
	local start_scale = unity_class.vector3.one
	local end_scale = unity_class.vector3.one * max_scale

	while time_passed < dur do
		local progress = time_passed / dur

		self.button_icon_tf.localScale = unity_class.vector3.Lerp(start_scale, end_scale, progress)
		self.button_icon_offset.localScale = unity_class.vector3.Lerp(start_scale, end_scale, progress)

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	time_passed = 0

	while time_passed < dur do
		local progress = time_passed / dur

		self.button_icon_tf.localScale = unity_class.vector3.Lerp(end_scale, start_scale, progress)
		self.button_icon_offset.localScale = unity_class.vector3.Lerp(end_scale, start_scale, progress)

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield(nil)
	end
end
--endregion

--region 클론 관련
--클론 제거
function local_class:disabled_clone_data(clone_name)
	if self.current_shadow_clone_table ~= nil then
		for _, fo in pairs(self.current_shadow_clone_table) do
			if clone_name == fo.name then
				self.shadow_clone_active_table[fo.name] = false
			end
		end

		self:check_active_clone_button()
	end

	if self.request_spawner ~= nil then
		local lua_table = self.request_spawner.FieldObjectBehaviour:GetLuaTable()

		lua_table:set_clear_shadow_clone_flag(true)
	end
end

function local_class:check_active_clone_button()
	local is_activate_shadow_clone = false

	if self.current_shadow_clone_table == nil then
		return
	end

	for _, fo in pairs(self.current_shadow_clone_table) do
		local name = fo.name

		if self.shadow_clone_active_table[name] then
			self.current_select_clone_name = name
			is_activate_shadow_clone = true

			self:set_button_icon(self.button_icon_name_table[name])
		end
	end

	if not is_activate_shadow_clone then
		self:set_button_active_state(false)
	end
end

--클론 리셋
function local_class:reset_shadow_clone(request_spawner_fo)
	if self.current_shadow_clone_table == nil then
		return false
	end

	if request_spawner_fo ~= nil and not lua_helper.reference_equals(self.request_spawner, request_spawner_fo) then
		self.request_spawner = request_spawner_fo
	end

	do
		local is_clone_active = false

		for _, is_active in pairs(self.shadow_clone_active_table) do
			if is_active then
				is_clone_active = true
			end
		end

		if is_clone_active then
			music_player_util.play_sfx_one_shot('02_klen_myth_attack_01')
		end
	end

	for _, fo in pairs(self.current_shadow_clone_table) do
		if self.shadow_clone_active_table[fo.Name] then
			local lua_table = fo.FieldObjectBehaviour:GetLuaTable()

			if lua_table ~= nil then
				lua_table:change_state(lua_table.state.remove)
			end
		end

		self:disabled_clone_data(fo.Name)
	end
end
--endregion

function local_class:get_round_vector(ver)
	local rounded_pos = vector(
			unity_class.mathf.Round(ver.x),
			ver.y,
			unity_class.mathf.Round(ver.z)
	)

	return rounded_pos
end

function local_class:set_shadow_clone_manager(clone_name)
	local new_shadow = get_field_object(clone_name)

	if self.current_shadow_clone_table == nil then
		self.current_shadow_clone_table = {}
	end

	if new_shadow.ActiveState == active_state('enabled') then
		self.shadow_clone_active_table[clone_name] = true
	else
		self.shadow_clone_active_table[clone_name] = false
	end

	local is_not_table_in_fo = true

	for _, fo in pairs(self.current_shadow_clone_table) do
		if lua_helper.reference_equals(new_shadow, fo) then
			is_not_table_in_fo = false
		end
	end

	if is_not_table_in_fo or table_util.is_empty(self.current_shadow_clone_table) then
		table.insert(self.current_shadow_clone_table, new_shadow)
	end

	local spine_controller = new_shadow:GetComponent(typeof(CS.Oak.SpineController))
	spine_controller:SetAnimation(1, self.shadow_animation_table[clone_name], true)

	self.current_select_clone_name = clone_name
	self:set_button_icon(self.button_icon_name_table[clone_name])
end

function local_class:progress_gimmick_level()
	if self.gimmick_level ~= self.gimmick_level_state.two_and_tp then
		self.gimmick_level = self.gimmick_level + 1
	end

	self:action_spawner_table(function(fo)
		self:set_spawner_gimmick_level(fo)
	end)

	if self.gimmick_level > self.gimmick_level_state.one_and_not_tp and self.current_shadow_clone_table ~= nil then
		local is_activate_shadow_clone = false

		for _, fo in pairs(self.current_shadow_clone_table) do
			local name = fo.name
			local is_activate_shadow = self.shadow_clone_active_table[name]

			if fo.name ~= self.current_select_clone_name and is_activate_shadow then
				self.current_select_clone_name = name
				is_activate_shadow_clone = true

				self:set_button_icon(self.button_icon_name_table[name])
				break
			end
		end

		self:set_button_active_state(true)
	end
end

function local_class:set_spawner_table(spawner_fo)
	if spawner_fo == nil then
		return
	end

	local is_not_contain_spawner = true

	self:action_spawner_table(function(fo)
		if lua_helper.reference_equals(fo, spawner_fo) then
			is_not_contain_spawner = false
		end
	end)

	if is_not_contain_spawner then
		self:set_spawner_gimmick_level(spawner_fo)

		table.insert(self.spawner_table, spawner_fo)
	end
end

function local_class:set_spawner_gimmick_level(fo)
	local lua_table = fo.FieldObjectBehaviour:GetLuaTable()

	if lua_table.custom_day_lv == nil or lua_table.custom_day_lv == 0 then
		lua_table.spawn_lv = self.gimmick_level

		if lua_table.spawn_lv == 1 then
			local leader_camera_gird = field_util.get_camera_grid_contains_point(get_party_leader().Position)

			if leader_camera_gird:Contains(fo.Position) then
				lua_table:change_state(lua_table.state.idle)
			end
		end
	end
end

function local_class:action_spawner_table(action)
	if self.spawner_table == nil or table_util.is_empty(self.spawner_table) then
		return
	end

	for _, fo in pairs(self.spawner_table) do
		action(fo)
	end
end

function local_class:set_custom_screen_play_state(boolean)
	self.is_custom_screen_play = boolean
end

function local_class:is_spawner_in_shadow_clone(bounds)
	local bounds_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(bounds, unity_class.vector3.zero)

	if self.current_shadow_clone_table == nil or table_util.is_empty(self.current_shadow_clone_table) then
		return false
	end

	for _, fo in pairs(bounds_list) do
		for _, shadow in pairs(self.current_shadow_clone_table) do
			if lua_helper.reference_equals(fo, shadow) then
				return true
			end
		end
	end

	return false
end

function local_class:create_arrow_sprite(sprite_name)
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()
	end

	local leader = get_party_leader()

	local custom_atlas
	coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName('spritesheets/battle', 'battle_custom'), function(prefab)
		custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
		custom_atlas:Initialize()
	end))

	local sprite = self.fx.custom_sprite():Instantiate(
			leader.transform.position, unity_class.quaternion.identity, leader.transform)

	local sprite_component = sprite.transform:GetComponent(typeof(CS.CustomSprite))

	sprite_component.Atlas = custom_atlas
	sprite_component.SpriteName = sprite_name
	sprite_component.LocalScale = unity_class.vector2.one * 0.5
	sprite_component:Rebuild()

	return sprite
end

function local_class:get_is_screen_play()
	return self.shadow_screen_play
end

function local_class:check_floor(fo)
	-- 기본 거리값이 없는 경우 1로 설정
	local distance = 1
	local position = fo.Position

	-- 8방향: 상, 우상, 우, 우하, 하, 좌하, 좌, 좌상
	local directions = {
		{ x = 0, z = distance }, -- 상
		{ x = distance, z = distance }, -- 우상
		{ x = distance, z = 0 }, -- 우
		{ x = distance, z = -distance }, -- 우하
		{ x = 0, z = -distance }, -- 하
		{ x = -distance, z = -distance }, -- 좌하
		{ x = -distance, z = 0 }, -- 좌
		{ x = -distance, z = distance }  -- 좌상
	}

	if field:IsThereFloorAt(position) then
		return
	end

	-- 각 방향에 대해 바닥 존재 여부 확인
	for i, dir in ipairs(directions) do
		local check_pos = {
			x = position.x + dir.x,
			y = position.y,
			z = position.z + dir.z,
		}

		-- 방향별 바닥 존재 여부 저장
		if field:IsThereFloorAt(check_pos) then
			fo.Position = check_pos
			return
		end
	end

	if not lua_helper.reference_equals(fo, get_party_leader()) and user_party:Contains(fo) then
		fo.Position = get_party_leader().Position
	end
end

function local_class:set_all_shadow_fx_arrow(is_active)
	for _, shadow in pairs(self.current_shadow_clone_table) do
		local lua_table = shadow.FieldObjectBehaviour:GetLuaTable()

		if lua_table.current_state ~= lua_table.state.deactivate then
			lua_table.arrow_renderer.enabled = is_active
		end
	end
end

function local_class:shadow_clone_action()
	local leader = get_party_leader()
	local current_action_state = leader.FieldObjectBehaviour.CurrentActionState
	local field_object_current_state = leader.FieldObjectBehaviour.CurrentState
	local character_current_state = leader.CharacterBehaviour.CurrentState

	if not self.button_active or lua_helper.type_compare(current_action_state, CS.Oak.CharacterHoldUpState) or
			lua_helper.type_compare(current_action_state, CS.Oak.CharacterThrowState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterUnitPushState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterPushState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterKnockBackState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterCrushState) then
		return
	end

	start_coroutine(self.button_pressed, self)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}

