local local_class = newclass('AfterWorldConveyorBeltController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region Conveyor Belt
	-- 존을 가져오는 함수
	self.get_belt_animation_zone = function(num) return field:GetZone('belt_animation_' .. num) end
	self.get_belt_animation_zone_by_name = function(name) return field:GetZone(name) end

	-- 존 이름
	self.conveyor_belt_zone_name = 'conveyor_belt'

	self.conveyor_belt_sound_zone_name = 'conveyor_belt_sound_'

	-- req id
	self.conveyor_belt_coroutine_req_id = {
		up = 0,
		right = 0,
		down = 0,
		left = 0
	}

	self.conveyor_working_count = 0
	self.conveyor_belt_fo_list = {
		up = {},
		right = {},
		down = {},
		left = {}
	}

	self.spine_offset = vector(0, -0.3, -0.1)

	-- 컨베이어 벨트 위에 올라와 있는 FieldObject List
	self.conveyor_working_count_list = {}
	-- 컨베이어 벨트 위에서 spine offset을 적용시키지 않는 FieldObject List
	self.is_ignore_fo_spine_offset_reset_list = {}
	-- 컨베이어 벨트에 밀리지 않는 FieldObject List
	self.ignore_conveyor_belt_moving_list = {}
	-- 컨베이어 벨트를 탑승할 NPC 리스트
	self.conveyor_belt_moving_npc_list = {}
	-- 애니메이션 작동 중인 컨베이어 벨트 리스트
	self.animated_conveyor_belt_list = {}

	-- 리셋 스위치 이름 리스트
	self.reset_switch_list = {}
	-- 무시할 사운드 존 이름 리스트
	self.ignore_sound_zone_list = {}

	-- Sound FX
	self.conveyor_belt_sfx = nil
--endregion
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil

	if self.conveyor_belt_sfx ~= nil then
		self.conveyor_belt_sfx:FadeOut()
		self.conveyor_belt_sfx = nil
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_enter_conveyor_belt')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_leave_conveyor_belt')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:conveyor_belt_animation()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_enter_conveyor_belt(e)
	local is_playable_character = self:is_playable_character(e.FieldObject)

	if string.sub(e.Zone.Name, 1, 13) == self.conveyor_belt_zone_name and
			string.sub(e.Zone.Name, 1, 20) ~= self.conveyor_belt_sound_zone_name then
		-- 이벤트 존 안에 들어온 객체가 플레이어블 캐릭터인지, 필드오브젝트인지, 이동 가능 처리가 된 NPC인지
		local is_field_object = self:is_field_object(e.FieldObject)
		local is_moving_npc = self.conveyor_belt_moving_npc_list[e.FieldObject]

		local is_purple_coin = lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.PurpleCoinBehaviour)

		if (is_field_object and e.FieldObject.ActiveState == active_state('enabled') and not is_purple_coin)
				or is_playable_character or is_moving_npc then
			local direction = string.sub(e.Zone.Name, 15, string.len(e.Zone.Name))

			local is_find = false
			for i = 1, #self.conveyor_belt_fo_list[direction] do
				if lua_helper.reference_equals(e.FieldObject, self.conveyor_belt_fo_list[direction][i]) then
					is_find = true
					break
				end
			end

			if not is_find then
				if self.conveyor_working_count_list[e.FieldObject] == nil then
					self.conveyor_working_count_list[e.FieldObject] = 0
				end

				if self.conveyor_working_count_list[e.FieldObject] == 0 then
					if is_playable_character then
						if not self.is_ignore_fo_spine_offset_reset_list[e.FieldObject] then
							if (e.FieldObject.CharacterBehaviour ~= nil and
									lua_helper.type_compare(e.FieldObject.CharacterBehaviour.CurrentState, typeof(CS.Oak.CharacterJumpState))) then
								coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
										self.set_linear_spine_offset, self, e.FieldObject, self.spine_offset, 0.5))
							else
								e.FieldObject.SpineController.SpineOffset = self.spine_offset
							end

							-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 끔(플레이어 한정)
							if lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
								e.FieldObject.SpineController.IsShadowActive = false
							end
						end

						local stat_ui = field_ui_manager:GetUIByKey(CS.Oak.FieldUiType.CharacterStats, e.FieldObject)
						if stat_ui ~= nil then
							stat_ui.transform.position = stat_ui.transform.position + self.spine_offset
						end
					end
				end

				self.conveyor_working_count_list[e.FieldObject] = self.conveyor_working_count_list[e.FieldObject] + 1
				table.insert(self.conveyor_belt_fo_list[direction], e.FieldObject)

				if #self.conveyor_belt_fo_list[direction] == 1 then
					coroutine_manager:StartCoroutine(
							stage.StageGameObject, util.cs_generator(self.conveyor_belt, self, direction))
				end
			end
			return true
		end
	elseif is_playable_character and string.sub(e.Zone.Name, 1, 20) == self.conveyor_belt_sound_zone_name then
		if (self.ignore_sound_zone_list[e.Zone.Name] == nil or not self.ignore_sound_zone_list[e.Zone.Name]) and
				self.conveyor_belt_sfx == nil then
			self.conveyor_belt_sfx = music_player_util.play_sfx(
					{ sfx_name = "01_belt_01", loop = true, volume = 0.5, type_priority = 'loop' })
		end
	end

	return false
end

function local_class:on_leave_conveyor_belt(e)
	local is_playable_character = self:is_playable_character(e.FieldObject)

	if e.FullLeave then
		if string.sub(e.Zone.Name, 1, 13) == self.conveyor_belt_zone_name and
				string.sub(e.Zone.Name, 1, 20) ~= self.conveyor_belt_sound_zone_name then
			-- 이벤트 존 안에 들어온 객체가 플레이어블 캐릭터인지, 필드오브젝트인지, 이동 가능 처리가 된 NPC인지
			local is_field_object = self:is_field_object(e.FieldObject)
			local is_moving_npc = self.conveyor_belt_moving_npc_list[e.FieldObject]

			if is_playable_character or is_field_object or is_moving_npc then
				local direction = string.sub(e.Zone.Name, 15, string.len(e.Zone.Name))

				for i = 1, #self.conveyor_belt_fo_list[direction] do
					if lua_helper.reference_equals(e.FieldObject, self.conveyor_belt_fo_list[direction][i]) then
						self.conveyor_working_count_list[e.FieldObject] =
						self.conveyor_working_count_list[e.FieldObject] - 1

						if self.conveyor_working_count_list[e.FieldObject] == 0 then
							if is_playable_character then
								if not self.is_ignore_fo_spine_offset_reset_list[e.FieldObject] then
									if (e.FieldObject.CharacterBehaviour ~= nil and
											lua_helper.type_compare(e.FieldObject.CharacterBehaviour.CurrentState, typeof(CS.Oak.CharacterJumpState))) then
										coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
												self.set_linear_spine_offset, self, e.FieldObject, -self.spine_offset, 0.5))
									else
										e.FieldObject.SpineController.SpineOffset = unity_class.vector3.zero
									end

									-- 이동 중에는 그림자 off 조절이 불가능해서,
									-- 컨베이어 벨트 위에 있을 때는 그림자를 껐던 것을 되돌림(플레이어 한정)
									if lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
										e.FieldObject.SpineController.IsShadowActive = true
									end
								end

								local stat_ui = field_ui_manager:GetUIByKey(
										CS.Oak.FieldUiType.CharacterStats, e.FieldObject)
								if stat_ui ~= nil then
									stat_ui.transform.position = stat_ui.transform.position - self.spine_offset
								end
							end
						end

						table.remove(self.conveyor_belt_fo_list[direction], i)
						break
					end
				end

				if #self.conveyor_belt_fo_list[direction] == 0 then
					self.conveyor_belt_coroutine_req_id[direction] = self.conveyor_belt_coroutine_req_id[direction] + 1
				end

				return true
			end
		elseif is_playable_character and
				string.sub(e.Zone.Name, 1, 20) == self.conveyor_belt_sound_zone_name then
			if self.conveyor_belt_sfx ~= nil then
				self.conveyor_belt_sfx:FadeOut()
				self.conveyor_belt_sfx = nil
			end
		end
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	if lua_helper.type_compare(e.SwitchObject.FieldObjectBehaviour, CS.Oak.FloorSwitchBehaviour) then
		if e.SwitchObject.FieldObjectBehaviour.CanResetGimmick then
			if e.IsTurningOn then
				self.reset_switch_list[e.SwitchObject.Name] = true
			else
				if table_util.contain_key(self.reset_switch_list, e.SwitchObject.Name) then
					self.reset_switch_list[e.SwitchObject.Name] = false
				end
			end
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'add_ignore_conveyor_belt_moving' then
		if e:GetParamAt(1) ~= nil then
			local fo_name = e:GetParamAt(1)
			local fo = self:get_ifo(fo_name)

			self:add_ignore_conveyor_belt_moving(fo)
		else
			self:add_ignore_conveyor_belt_moving(e.Sender)
		end

		return true
	elseif e:GetParamAt(0) == 'remove_ignore_conveyor_belt_moving' then
		if e:GetParamAt(1) ~= nil then
			local fo_name = e:GetParamAt(1)
			local fo = self:get_ifo(fo_name)
			self:remove_ignore_conveyor_belt_moving(fo)
		else
			self:remove_ignore_conveyor_belt_moving(e.Sender)
		end

		return true
	elseif e:GetParamAt(0) == 'add_npc_belt_moving' then
		if e:GetParamAt(1) ~= nil then
			local character_name = e:GetParamAt(1)
			local character = get_character(character_name)

			self:add_npc_belt_moving(character)
		else
			self:add_npc_belt_moving(e.Sender)
		end

		return true
	elseif e:GetParamAt(0) == 'remove_npc_belt_moving' then
		if e:GetParamAt(1) ~= nil then
			local character_name = e:GetParamAt(1)
			local character = get_character(character_name)
			self:remove_npc_belt_moving(character)
		else
			self:remove_npc_belt_moving(e.Sender)
		end

		return true
	elseif e:GetParamAt(0) == 'add_ignore_fo_spine_offset_reset' then
		local fo_name = e:GetParamAt(1)
		local fo = self:get_ifo(fo_name)
		self.is_ignore_fo_spine_offset_reset_list[fo] = true

		return true
	elseif e:GetParamAt(0) == 'remove_ignore_fo_spine_offset_reset' then
		local fo_name = e:GetParamAt(1)
		local fo = self:get_ifo(fo_name)
		self.is_ignore_fo_spine_offset_reset_list[fo] = false

		return true
	elseif e:GetParamAt(0) == 'pause_animation' then
		local zone_name = e:GetParamAt(1)

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.pause_animation, self, zone_name))

		return true
	elseif e:GetParamAt(0) == 'resume_animation' then
		local zone_name = e:GetParamAt(1)

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.resume_animation, self, zone_name))

		return true
	elseif e:GetParamAt(0) == 'deactivate_sound_zone' then
		local zone_name = e:GetParamAt(1)

		self.ignore_sound_zone_list[zone_name] = true

		return true
	elseif e:GetParamAt(0) == 'activate_sound_zone' then
		local zone_name = e:GetParamAt(1)

		self.ignore_sound_zone_list[zone_name] = false

		return true
	end

	return false
end
--endregion

--region conveyor_belt
function local_class:conveyor_belt_animation()
	self:find_and_execute_fo_all(self.get_belt_animation_zone, function(target_zone)
		local belts = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)

		--- 해당 존에 있는 모든 오브젝트를 순회
		for index = 0, belts.Count - 1 do
			local belt = belts[index]

			if string.sub(belt.Name, 1, 13) == '[gimmick]belt' and string.len(belt.Name) < 18 then
				local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
				animator:Play('afterworld_belt_on')
				belt.ActiveState = active_state('visible')

				table.insert(self.animated_conveyor_belt_list, belt)
			end
		end

		belts:Dispose()
	end)
end

function local_class:conveyor_belt(direction_str)
	local direction = self:string_to_direction(direction_str)
	local direction_vector = direction_util.to_vector3(direction)
	local speed = 3

	self.conveyor_belt_coroutine_req_id[direction_str] = self.conveyor_belt_coroutine_req_id[direction_str] + 1
	local req_id = self.conveyor_belt_coroutine_req_id[direction_str]

	if self.conveyor_working_count == 0 then
	end
	self.conveyor_working_count = self.conveyor_working_count + 1

	while req_id == self.conveyor_belt_coroutine_req_id[direction_str] do
		local remove_indexes = {}

		for i = 1, #self.conveyor_belt_fo_list[direction_str] do
			local fo = self.conveyor_belt_fo_list[direction_str][i]

			if not self.ignore_conveyor_belt_moving_list[fo] and not (fo.CharacterBehaviour ~= nil and
					lua_helper.type_compare(fo.CharacterBehaviour.CurrentState, typeof(CS.Oak.CharacterJumpState))) then
				local target_pos = fo.Position + (direction_vector * (speed * unity_class.time.deltaTime))

				if stage_util.get_height(target_pos) == stage_util.get_height(fo.Position) then
					fo.Position = target_pos
				elseif self:is_field_object(fo) and not fo.Holdable.IsHeld and
						not lua_helper.type_compare(
								fo.FieldObjectBehaviour.CurrentState, CS.Oak.FieldObjectThrownState) and
						stage_util.get_height(target_pos) < stage_util.get_height(fo.Position) and
						field:IsThereFloorAt(target_pos + direction_vector) then
					-- FieldObject는 컨베이어 벨트에 의해 움직이는 다음 위치의 y값이 더 작을 경우 바닥으로 떨어짐
					self.conveyor_working_count_list[fo] =
					self.conveyor_working_count_list[fo] - 1

					table.insert(remove_indexes, i)

					if #self.conveyor_belt_fo_list[direction_str] == 0 then
						self.conveyor_belt_coroutine_req_id[direction_str] =
						self.conveyor_belt_coroutine_req_id[direction_str] + 1
					end

					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
							self.fall_down_conveyor_belt, self, fo, direction_str, stage_util.get_height(target_pos)))
				end

				-- 파티 리더가 컨베이어 벨트 타고 움직일 때 퍼플 코인 습득 처리
				if lua_helper.reference_equals(fo, get_party_leader()) then
					local bounds = get_party_leader().Bounds
					local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(
							bounds, target_pos - get_party_leader().Position)

					for n = 0, fo_list.Count - 1 do
						local obj = fo_list[n]

						-- 퍼플코인이면 획득
						if lua_helper.type_compare(obj.FieldObjectBehaviour, CS.Oak.PurpleCoinBehaviour)
								and obj.ActiveState == active_state('enabled') then
							message_system:SendSync(
									obj.FieldObjectBehaviour, CS.Oak.GotCrashedEvent.Create(get_party_leader()))
						end
					end
				end
			end
		end

		local remove_num = 0

		for i = 1, #remove_indexes do
			table.remove(self.conveyor_belt_fo_list[direction_str], remove_indexes[i] - remove_num)

			remove_num = remove_num + 1
		end

		coroutine.yield()
	end
end

function local_class:add_ignore_conveyor_belt_moving(fo)
	self.ignore_conveyor_belt_moving_list[fo] = true
end

function local_class:remove_ignore_conveyor_belt_moving(fo)
	self.ignore_conveyor_belt_moving_list[fo] = false
end

function local_class:add_npc_belt_moving(character)
	self.conveyor_belt_moving_npc_list[character] = true
end

function local_class:remove_npc_belt_moving(character)
	self.conveyor_belt_moving_npc_list[character] = false
end

function local_class:pause_animation(zone_name)
	-- 애니메이션 중인 컨베이어 벨트는 1프레임 동안 ActiveState를 Enabled로 변경해서 오브젝트 충돌이 가능하도록 수정
	for i = 1, #self.animated_conveyor_belt_list do
		self.animated_conveyor_belt_list[i].ActiveState = active_state('enabled')
	end

	coroutine.yield(nil)

	self:find_and_execute_fo_all_by_name(
			self.get_belt_animation_zone_by_name, zone_name, function(target_zone)
				local belts = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(
						target_zone.Bounds, unity_class.vector3.zero)

				--- 해당 존에 있는 모든 오브젝트를 순회
				for index = 0, belts.Count - 1 do
					local belt = belts[index]

					if string.sub(belt.Name, 1, 13) == '[gimmick]belt' and string.len(belt.Name) < 18 then
						local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
						animator.enabled = false
					end
				end

				belts:Dispose()
			end)

	coroutine.yield(nil)

	-- 컨베이어 벨트 ActiveState 복구
	for i = 1, #self.animated_conveyor_belt_list do
		self.animated_conveyor_belt_list[i].ActiveState = active_state('visible')
	end
end

function local_class:resume_animation(zone_name)
	-- 애니메이션 중인 컨베이어 벨트는 1프레임 동안 ActiveState를 Enabled로 변경해서 오브젝트 충돌이 가능하도록 수정
	for i = 1, #self.animated_conveyor_belt_list do
		self.animated_conveyor_belt_list[i].ActiveState = active_state('enabled')
	end

	coroutine.yield(nil)

	self:find_and_execute_fo_all_by_name(
			self.get_belt_animation_zone_by_name, zone_name, function(target_zone)
				local belts = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(
						target_zone.Bounds, unity_class.vector3.zero)

				--- 해당 존에 있는 모든 오브젝트를 순회
				for index = 0, belts.Count - 1 do
					local belt = belts[index]

					if string.sub(belt.Name, 1, 13) == '[gimmick]belt' and string.len(belt.Name) < 18 then
						local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
						animator.enabled = true
						animator:Play('afterworld_belt_on')
					end
				end

				belts:Dispose()
			end)

	coroutine.yield(nil)

	-- 컨베이어 벨트 ActiveState 복구
	for i = 1, #self.animated_conveyor_belt_list do
		self.animated_conveyor_belt_list[i].ActiveState = active_state('visible')
	end
end

-- 바닥으로 떨어지는 오브젝트 처리
function local_class:fall_down_conveyor_belt(fo, dir, floor_y)
	local timer = 0
	local duration = 0.3

	local dir_vector = direction_util.to_vector3(dir)
	local start_pos = fo.Position
	local end_pos = vector(fo.Position.x + dir_vector.x, floor_y, fo.Position.z + dir_vector.z)

	local is_holdable_obj = lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.HoldableObjectBehaviour)

	local loop_out = false

	local is_holdable = false

	if lua_helper.type_compare(fo.Holdable, CS.Oak.Holdable) then
		is_holdable = true

		fo.Holdable = CS.Oak.NonHoldable.Instance
	end

	while timer < duration do
		-- 해당 오브젝트가 리셋 가능한 경우, 리셋되면 취소
		if is_holdable_obj then
			local fo_behaviour = fo.FieldObjectBehaviour

			if table_util.contain_key(self.reset_switch_list, fo_behaviour.ResetSwitchName) and
					fo_behaviour.ResetType == CS.Oak.ResetEvent.Switch then
				if self.reset_switch_list[fo_behaviour.ResetSwitchName] then
					loop_out = true
				end
			end
		end

		if loop_out then
			break
		end

		timer = timer + unity_class.time.deltaTime

		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, timer / duration)

		fo.Position = cur_pos

		coroutine.yield(nil)
	end

	if not loop_out then
		fo.Position = end_pos
	end

	if is_holdable_obj then
		fo.Holdable = CS.Oak.Holdable()
	end
end

-- 캐릭터 점프 시 스파인 Offset 순차 적용
function local_class:set_linear_spine_offset(fo, val, duration)
	local timer = 0

	local start_offset = fo.SpineController.SpineOffset
	local end_offset = start_offset + val

	while timer < duration do
		timer = timer + unity_class.time.deltaTime

		local cur_spine_offset = unity_class.vector3.Lerp(start_offset, end_offset, timer / duration)
		fo.SpineController.SpineOffset = cur_spine_offset

		coroutine.yield(nil)
	end

	fo.SpineController.SpineOffset = end_offset
end
--endregion

--region util
-- String을 Direction으로 변환
function local_class:string_to_direction(direction_str)
	if type_util.is_string(direction_str) then
		if direction_str == 'left' then
			return CS.Oak.Direction.Left
		elseif direction_str == 'right' then
			return CS.Oak.Direction.Right
		elseif direction_str == 'up' then
			return CS.Oak.Direction.Up
		elseif direction_str == 'down' then
			return CS.Oak.Direction.Down
		elseif direction_str == 'none' then
			return CS.Oak.Direction.None
		end
	end

	return nil
end

-- 플레이어블 캐릭터인지 return
function local_class:is_playable_character(fo)
	local type = fo:GetType()
	local result = false

	cast(fo, typeof(CS.Oak.Character))

	if lua_helper.type_compare(fo, typeof(CS.Oak.Character)) and
			(fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
		result = true
	end

	cast(fo, type)

	return result
end

-- 필드오브젝트인지 return
function local_class:is_field_object(fo)
	local type = fo:GetType()
	local result = false

	cast(fo, typeof(CS.Oak.FieldObject))

	if lua_helper.type_compare(fo, typeof(CS.Oak.FieldObject)) then
		result = true
	end

	cast(fo, type)

	return result
end

-- 캐릭터 혹은 필드오브젝트 리턴
function local_class:get_ifo(fo_name)
	local fo = get_character(fo_name)

	if fo == nil then
		fo = get_field_object(fo_name)
	end

	return fo
end

-- 1번 파라미터 함수로 찾은 오브젝트들에 2번 파라미터 함수 적용
function local_class:find_and_execute_fo_all(find_fo_func, execute_func)
	local i = 1
	while true do
		local fo = find_fo_func(i)

		if fo == nil then
			break
		end

		execute_func(fo)

		i = i + 1
	end
end

-- 위 함수 존 이름으로 찾는 버전
function local_class:find_and_execute_fo_all_by_name(find_fo_func, zone_name, execute_func)
	local fo = find_fo_func(zone_name)

	if fo ~= nil then
		execute_func(fo)
	end
end
--endregion

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
