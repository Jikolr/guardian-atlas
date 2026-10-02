local local_class = newclass('PixyWorld4Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 412

	-- 메모 오브젝트 상호작용 시 나타낼 나레이션 스트링
	self.event_memo_narration = {}
	self.event_memo_count = 3

	-- field object
	self.field_object = {
		memo_object   = function(idx) return get_field_object('stage_4_memo_' .. idx) end,
		hint_brazier   = function(idx) return get_field_object('hint_brazier_' .. idx) end,
		eastworld_door   = function() return get_field_object('eastworld_enter_door') end,
		background_town   = function() return get_field_object('background_town') end,
	}

	self.grid = {
		brazier_area   = 'brazier_grid',
	}

	self.brazier_operation_interval = {
		{ on_duration = 7, off_duration = 1, brazier_on = true },
		{ on_duration = 4, off_duration = 4, brazier_on = true },
		{ on_duration = 5, off_duration = 3, brazier_on = true },
		{ on_duration = 6, off_duration = 2, brazier_on = true },
	}

	self.periodic_brazier_operation_enabled = false

	self.brazier_count = 4

	-- 동굴 버튼 퍼즐
	self.cave_puzzle_button_info = {
		clear_button_order = { 'cave_puzzle_switch_2', 'cave_puzzle_switch_3', 'cave_puzzle_switch_4', 'cave_puzzle_switch_1' },
		input_match_button_order = {},

		cur_input_order = 0,

		button_match = false
	}

	self.events = {
		current_event_info = nil,

		['zone_enter'] = {
			{ zone_name = 'brazier_event', once = false, passed = false, func = self.start_periodic_brazier_movement, control = true },
			{ zone_name = 'cave_field', once = false, passed = false, func = self.update_background_state, control = true }
		},

		['zone_leave'] = {
			{ zone_name = 'brazier_event', once = false, passed = false, func = self.end_periodic_brazier_movement, control = true },
			{ zone_name = 'cave_field', once = false, passed = false, func = self.update_background_state, control = true }
		},

		['interact'] = {
			{ target = self.field_object.eastworld_door(), func = self.interact_eastworld_door, control = true },
		},
	}

	self.zone_name = {
		cave_field = 'cave_field',
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	-- 파티멤버 전투 시에만 등장 로직 / 전투 팔로우 배틀 로직
	custom_stage_option_util.register_option({
		break_in_party_member = {},
		follow_npc_battle_logic = { quest_id = 412 },
	})

	self:set_memo_obj_state()
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
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local interact_event = self.events['interact']

	if interact_event ~= nil then
		for i = 1, #interact_event do
			if type_util.is_interacted_target(e, interact_event[i].target) then
				self.events.current_event_info = e

				if interact_event[i].control then
					start_coroutine(interact_event[i].func, self)
				else
					sp_util.start_scene(interact_event[i].func, self)
				end

				return true
			end
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local zone_event = self.events['zone_enter']

	if zone_event ~= nil then
		for i = 1, #zone_event do
			if type_util.is_zone_full_enter(e, user_party.Leader, zone_event[i].zone_name) then
				self.events.current_event_info = e

				if zone_event[i].control then
					if zone_event[i].once and not zone_event[i].passed then
						zone_event[i].passed = true

						start_coroutine(zone_event[i].func, self)
					elseif not zone_event[i].once then
						start_coroutine(zone_event[i].func, self)
					end
				else
					if zone_event[i].once and not zone_event[i].passed then
						zone_event[i].passed = true

						sp_util.start_scene(zone_event[i].func, self)
					elseif not zone_event[i].once then
						sp_util.start_scene(zone_event[i].func, self)
					end
				end

				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local zone_event = self.events['zone_leave']

	if zone_event ~= nil then
		for i = 1, #zone_event do
			if type_util.is_zone_full_leave(e, user_party.Leader, zone_event[i].zone_name) then
				self.events.current_event_info = e

				if zone_event[i].control then
					if zone_event[i].once and not zone_event[i].passed then
						zone_event[i].passed = true

						start_coroutine(zone_event[i].func, self)
					elseif not zone_event[i].once then
						start_coroutine(zone_event[i].func, self)
					end
				else
					if zone_event[i].once and not zone_event[i].passed then
						zone_event[i].passed = true

						sp_util.start_scene(zone_event[i].func, self)
					elseif not zone_event[i].once then
						sp_util.start_scene(zone_event[i].func, self)
					end
				end

				return true
			end
		end
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	local switch_object = e.SwitchObject

	if not self.cave_puzzle_button_info.button_match then
		start_coroutine(self.save_input_button_info, self, switch_object.Name)
	end
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

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local boomerang_controller = get_stage_event_controller('PixyWorldBoomerangController')

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 11 then
		boomerang_controller:boomerang_active_setting(false)
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s12_knight_1'), false, false)
	elseif quest_progress.InnerProgress == 12 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 13 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 14 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:set_memo_obj_state()
	-- 진입 섹션에 따라 활성화할 메모 오브젝트 셋팅
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- key값은 InnerProgress 값
	self.event_memo_narration[1] = {
		'pw_main_s13_2', 'pw_main_s13_3', 'pw_main_s13_4',
		'pw_main_s13_5', 'pw_main_s13_6'
	}

	self.event_memo_narration[2] = {
		'pw_main_s14_2', 'pw_main_s14_3', 'pw_main_s14_4',
		'pw_main_s14_5', 'pw_main_s14_6', 'pw_main_s14_7'
	}

	self.event_memo_narration[3] = {
		'pw_main_s15_2', 'pw_main_s15_5', 'pw_main_s15_6',
		'pw_main_s15_7', 'pw_main_s15_8'
	}

	-- 셋팅
	if quest_progress == nil or quest_progress.IsComplete or quest_progress.InnerProgress > 14 then
		self:active_memo_interacting({ 1, 2, 3 })
	elseif quest_progress.InnerProgress == 13 then
		self:active_memo_interacting(1)
	elseif quest_progress.InnerProgress == 14 then
		self:active_memo_interacting({ 1, 2 })
	end
end

function local_class:active_memo_interacting(obj_idx)
	local memo_count = 1
	if type_util.is_array(obj_idx) then
		memo_count = #obj_idx
	end

	for i = 1, memo_count do
		local idx
		if type_util.is_array(obj_idx) then
			idx = obj_idx[i]
		else
			idx = obj_idx
		end

		local memo_obj = self.field_object.memo_object(idx)

		if memo_obj ~= nil then
			local nar_interactable = CS.Oak.NarrationInteractable()
			nar_interactable.StringKeys = self.event_memo_narration[i]

			memo_obj.Interactable = nar_interactable
		end
	end
end

function local_class:start_periodic_brazier_movement()
	if not self.periodic_brazier_operation_enabled then
		self.periodic_brazier_operation_enabled = true

		for i = 1, self.brazier_count do
			start_coroutine(self.operate_brazier_periodically, self, i)
		end
	end
end

function local_class:end_periodic_brazier_movement()
	if self.periodic_brazier_operation_enabled then
		self.periodic_brazier_operation_enabled = false

		for i = 1, self.brazier_count do
			local brazier = self.field_object.hint_brazier(i)

			command_util.publish_extinguish(user_party.Leader, brazier)
		end
	end
end

function local_class:operate_brazier_periodically(brazier_idx)
	local brazier = self.field_object.hint_brazier(brazier_idx)

	if brazier ~= nil then
		local bust_cs = CS.Oak.LuaICombustibleBehaviour()
		local brazier_interval_info = self.brazier_operation_interval[brazier_idx]

		command_util.publish_burn(user_party.Leader, brazier, true)

		local time_passed = 0
		while self.periodic_brazier_operation_enabled do
			time_passed = time_passed + unity_class.time.deltaTime

			if time_passed > brazier_interval_info.on_duration and brazier_interval_info.brazier_on == true then
				command_util.publish_extinguish(user_party.Leader, brazier)

				brazier_interval_info.brazier_on = false

				time_passed = 0
			end

			if time_passed > brazier_interval_info.off_duration and brazier_interval_info.brazier_on == false then
				command_util.publish_burn(user_party.Leader, brazier, true)

				brazier_interval_info.brazier_on = true

				time_passed = 0
			end

			coroutine.yield()
		end
	end
end

function local_class:save_input_button_info(button_name)
	local info = self.cave_puzzle_button_info

	if #info.input_match_button_order > 0 and info.input_match_button_order[info.cur_input_order] == button_name then
		return
	end

	-- 입력받은 button이 8개 이상이 되면 이전 4개는 지움
	if #info.input_match_button_order >= (#info.clear_button_order * 2) then
		for i = 1, #info.clear_button_order do
			table.remove(info.input_match_button_order, 1)
		end

		info.cur_input_order = info.cur_input_order - 4
	end

	info.cur_input_order = info.cur_input_order + 1

	info.input_match_button_order[info.cur_input_order] = button_name

	self:check_button_order(info)
end

function local_class:check_button_order(info)
	if #info.input_match_button_order >= 4 then
		for i = 1, info.cur_input_order - 3 do
			if (i + 3) <= #info.input_match_button_order then
				if info.input_match_button_order[i] == info.clear_button_order[1] and
						info.input_match_button_order[i + 1] == info.clear_button_order[2] and
						info.input_match_button_order[i + 2] == info.clear_button_order[3] and
						info.input_match_button_order[i + 3] == info.clear_button_order[4] then
					info.button_match = true

					message_system:Publish(CS.Oak.DoorOpenEvent.Create('cave_center_door', false))
				end
			else
				info.button_match = false
			end
		end
	end
end

function local_class:interact_eastworld_door()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress == nil or quest_progress.IsComplete then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('eastworld_enter_door', false))
	else
		sp_util.enter_scene(nil)

		-- 나레이션 : 선택받은 픽시만이 이 문을 열 수 있을 것 같습니다.
		field_ui_util.show_narration_async({ key = 'pw_eastworld_door_open' })

		sp_util.exit_scene(nil, get_party_leader())
	end
end

function local_class:update_background_state()
	local obj_state = nil

	if lua_helper.type_compare(self.events.current_event_info, CS.Oak.ZoneEnterEvent) then
		obj_state = active_state_type.disabled
	elseif lua_helper.type_compare(self.events.current_event_info, CS.Oak.ZoneLeaveEvent) then
		obj_state = active_state_type.visible
	end

	if obj_state ~= nil then
		local background = self.field_object.background_town()

		field_object_util.set_active_state(background, obj_state)
	end
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
