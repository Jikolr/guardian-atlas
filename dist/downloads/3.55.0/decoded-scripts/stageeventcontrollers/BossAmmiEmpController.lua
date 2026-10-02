local local_class = newclass('BossAmmiEmpController')

-- 악몽 15 강화 AMMI EMP 기믹에 사용되는 컨트롤러
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}

	self.emp_state = {
		none = 1,
		idle = 2,
		prepare = 3,
		active = 4,
		post = 5
	}

	self.battery_state = {
		none = 1,
		appear = 2
	}

	self.remove_cause = {
		none = 1,
		goal_in = 2,
		boss_hit = 3,
		clear = 4
	}

	self.current_boss_character = nil

	self.idle_battery_holder = { }
	self.active_battery_holder = { }
	table.insert(self.idle_battery_holder, get_field_object('battery_1'))
	table.insert(self.idle_battery_holder, get_field_object('battery_2'))
	self.spawn_marker_list = { }
	table.insert(self.spawn_marker_list, field:GetMarker('BatterySpawnArea_1'))
	table.insert(self.spawn_marker_list, field:GetMarker('BatterySpawnArea_2'))
	self.throw_fo_list = { }
	self.hold_up_fo_list = { }

	local zone = field:GetZone('battery_safe_area')
	local bounds = zone.Bounds

	local offset = 0.25
	local s_pos = bounds.center + vector(0, 0, 1) * offset / 2
	local s_size = bounds.size + vector(0, 0, 1) * offset
	self.safe_zone_bounds = CS.UnityEngine.Bounds(s_pos, s_size)

	local size = vector(bounds.size.x, bounds.size.z)
	local inner = CS.UnityEngine.Color32(0, 192, 140, 153)
	local outer = CS.UnityEngine.Color32(0, 188, 133, 128)
	self.safe_zone_ar = CS.AttackRange.CreateRect(bounds.center, size, inner, outer)

	self.emp_unit = get_field_object('emp')
	self.emp_unit_animator = self.emp_unit:GetComponent(typeof(CS.UnityEngine.Animator))

	self.goal_in_count = 0
	self.need_amount = 0
	self.battery_time_passed = 0
	self.emp_time_passed = 0

	self:change_progress(self.progress.none)
	self:change_emp(self.emp_state.none)

	-- params
	-- 배터리 스폰 텀
	self.battery_spawn_term = 10
	-- 배터리 던져넣기 성공에 필요한 수
	self.full_charge_amount = 2
	self.full_charge_amount2 = 3
	-- emp 공격에 맞은 후 자신의 체력을 체크하여 일정 % 이하면 배터리 성공 갯수가 full_charge_amount2 만큼으로 변경
	self.amount_change_hp_ratio = 0.4
	-- emp unit 위에 뜨는 timerbar 관련
	self.timer_bar_width = 180
	self.timer_bar_height = 40
	self.gauge_offset = vector(0, 0, -1.3)

	self.emp_prepare_duration = 1
	self.emp_active_duration = 1
	self.emp_post_duration = 1
end

function local_class:load_resource()
	self.on_custom_stage_event_func = function(e)
		self:on_custom_stage_event(e) end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)

	self.on_field_object_destroyed_event_func = function(e)
		self:on_field_object_destroyed_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_field_object_destroyed_event_func)

	self.on_hold_up_event_func = function(e)
		self:on_hold_up_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.HoldUpEvent), self.on_hold_up_event_func)

	self.on_throw_event_func = function(e)
		self:on_throw_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.ThrowEvent), self.on_throw_event_func)

	self.on_thrown_end_event_func = function(e)
		self:on_thrown_end_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.ThrownEndEvent), self.on_thrown_end_event_func)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx_blink = unity_object_pool.GetOrCreate('FX_Blink')
	self.fx_emp_pool = unity_object_pool.GetOrCreate('fx_emp_explosion_empunit')
	self.fx_spawn = unity_object_pool.GetOrCreate('fx_m_robottanker2_funnel_cast')
	self.fx_explosion_pool = unity_object_pool.GetOrCreate('fx_ammi_explosion_battery')
	return
end

function local_class:change_progress(new_state)
	if self.current_progress == new_state then
		return
	end

	if new_state == self.progress.playing then
		self.battery_time_passed = 0
		self:update_full_charge_amount()

		-- apply emp ui
		if self.timer_bar == nil then
			local ui_dic = stage.FieldUIManager:SetUI(self.emp_unit, CS.Oak.FieldUiType.TimerBar)
			self.timer_bar = ui_dic[CS.Oak.FieldUiType.TimerBar]
			self.timer_bar.BarSprite.Bar.color = unity_class.color.yellow
			self.timer_bar.BarSprite.Background.color = unity_class.color.black
			self.timer_bar.BarSprite:SetWidth(self.timer_bar_width)
			self.timer_bar.BarSprite:SetHeight(self.timer_bar_height)
			self.timer_bar.BarSprite:SetMinMax(0, 1)
			self.timer_bar.BarSprite:SetValue((self.goal_in_count / self.need_amount), 0)
			self.timer_bar:SetPosition(self.emp_unit.Position + self.gauge_offset)
		end

	elseif new_state == self.progress.done then
		-- remove emp ui
		stage.FieldUIManager:RemoveUI(self.boss, CS.Oak.FieldUiType.TimerBar)
		self.timer_bar = nil

		self:clear_battery()

		if self.goal_in_count >= self.need_amount then
			self:change_emp(self.emp_state.post)
		else
			self:change_emp(self.emp_state.idle)
		end

		self:toggle_safe_zone()
	end

	self.current_progress = new_state
end

-- 모든 배터리(들고 있는거 포함)를 지운다
function local_class:clear_battery()
	for i = #self.hold_up_fo_list, 1, -1 do
		local fo = self.hold_up_fo_list[i]
		table.remove(self.hold_up_fo_list, i)
		character_util.clear_holdup_state(user_party.Leader, fo)
	end

	for i = #self.throw_fo_list, 1, -1 do
		local fo = self.throw_fo_list[i]
		table.remove(self.throw_fo_list, i)
		message_system:SendSync(fo, CS.Oak.GetThrownEndEvent.Instance)
	end

	local manual_character = user_party.Leader
	local leader_state = manual_character.CharacterBehaviour.CurrentActionState
	if lua_helper.type_compare(leader_state, CS.Oak.CharacterHoldUpState) then
		local held = manual_character.CharacterBehaviour.CurrentActionState.HoldTarget
		character_util.clear_holdup_state(user_party.Leader, held)
	end

	for i = #self.active_battery_holder, 1, -1 do
		self:remove_battery(table.remove(self.active_battery_holder, i), self.remove_cause.clear)
	end
end

function local_class:change_emp(new_state)
	if self.current_emp == new_state then
		return
	end

	if new_state == self.emp_state.idle then
		self.emp_unit_animator:Play('unit_on')
		music_player_util.play_sfx({ sfx_name = '01_die_robot_02', max_distance = 4 })

	elseif new_state == self.emp_state.prepare then

	elseif new_state == self.emp_state.active then
		self.fx_emp_pool:Instantiate(self.emp_unit.Position)
		music_player_util.play_sfx({ sfx_name = '02_lightning_strike_01', max_distance = 4 })

		self:update_full_charge_amount()
		self:clear_battery()
		self.battery_time_passed = 0
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.boss, { 'gimmick_emp_active' }))

	elseif new_state == self.emp_state.post then
		self.emp_unit_animator:Play('unit_off')
		self.goal_in_count = 0
	end

	self.current_emp = new_state
	self.emp_time_passed = 0
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then
		return true
	end

	self:update_battery(dt)
	self:update_emp(dt)
	self:update_emp_ui(dt)
end

function local_class:update_emp(dt)
	self.emp_time_passed = self.emp_time_passed + dt

	if self.current_emp == self.emp_state.idle then
		if self.goal_in_count >= self.need_amount then
			self:change_emp(self.emp_state.prepare)
		end

	elseif self.current_emp == self.emp_state.prepare then
		if self.emp_time_passed >= self.emp_prepare_duration then
			self:change_emp(self.emp_state.active)
		end

	elseif self.current_emp == self.emp_state.active then
		if self.emp_time_passed >= self.emp_active_duration then
			self:change_emp(self.emp_state.post)
		end

	elseif self.current_emp == self.emp_state.post then
		if self.emp_time_passed >= self.emp_post_duration then
			self:change_emp(self.emp_state.none)
		end
	end
end

function local_class:update_emp_ui(dt)
	if self.timer_bar == nil then
		return
	end

	self.timer_bar.BarSprite:SetValue((self.goal_in_count / self.need_amount), 0);
end

function local_class:update_battery(dt)
	-- spwan update
	if self.battery_time_passed < self.battery_spawn_term then
		self.battery_time_passed = self.battery_time_passed + dt
		return
	end

	for i = #self.idle_battery_holder, 1, -1 do
		local fo = self.idle_battery_holder[i]
		local pos = fo.Name == 'battery_1' and self.spawn_marker_list[1].position or self.spawn_marker_list[2].position
		fo.Position = pos
		self:appear_battery(table.remove(self.idle_battery_holder, i))
	end

	self.battery_time_passed = 0
end

function local_class:update_full_charge_amount()
	if self.boss == nil then
		return
	end

	if self.boss.CharacterStatsBehaviour.HpRatio > self.amount_change_hp_ratio then
		self.need_amount = self.full_charge_amount
	else
		self.need_amount = self.full_charge_amount2
	end
end

function local_class:appear_battery(fo)
	self.fx_spawn:Instantiate(fo.Position)
	table.insert(self.active_battery_holder, fo)

	CS.Oak.UIQuestMarkersController.Instance:AddQuestMarkerToIFO(fo.Name, 0, false, fo)

	music_player_util.play_sfx({ sfx_name = '01_bounce_iron_03', max_distance = 4 })
end

function local_class:remove_battery(fo, cause)
	if fo == nil then
		return
	end

	if cause == self.remove_cause.goal_in then
		self.fx_blink:Instantiate(fo.Position)

	elseif cause == self.remove_cause.boss_hit then
		self.fx_explosion_pool:Instantiate(fo.Position)

		local held = nil
		local manual_character = user_party.Leader
		local leader_state = manual_character.CharacterBehaviour.CurrentActionState
		if lua_helper.type_compare(leader_state, CS.Oak.CharacterHoldUpState) then
			held = manual_character.CharacterBehaviour.CurrentActionState.HoldTarget
		end


		-- 들고있었거나 던져 날아가는 도중에 히트 당했을 수 있다
		for i = #self.hold_up_fo_list, 1, -1 do
			local b = self.hold_up_fo_list[i]
			if lua_helper.reference_equals(b, fo) then
				table.remove(self.hold_up_fo_list, i)
				if lua_helper.reference_equals(fo, held) then
					character_util.clear_holdup_state(user_party.Leader, fo)
				end
			end
		end

		for i = #self.throw_fo_list, 1, -1 do
			local b = self.throw_fo_list[i]
			if lua_helper.reference_equals(b, fo) then
				table.remove(self.throw_fo_list, i)
				message_system:SendSync(fo, CS.Oak.GetThrownEndEvent.Instance)
			end
		end

	elseif cause == self.remove_cause.clear then

	end

	self:toggle_safe_zone()
	fo.Position = vector(999, -999, 999)
	table.insert(self.idle_battery_holder, fo)
	CS.Oak.UIQuestMarkersController.Instance:RemoveQuestMarker(fo.Name)
end

function local_class:add_goal_in()
	-- 최초 골인 이라면 emp state를 idle로 변경해주자
	if self.goal_in_count == 0 then
		self:update_full_charge_amount()
		self:change_emp(self.emp_state.idle)
	end

	music_player_util.play_sfx({ sfx_name = '01_walk_robot_06', max_distance = 4 })
	music_player_util.play_sfx({ sfx_name = '01_object_warp_01', max_distance = 4 })

	self.goal_in_count = self.goal_in_count + 1
end

function local_class:toggle_safe_zone()
	local active = #self.hold_up_fo_list + #self.throw_fo_list > 0
	if active then
		self.safe_zone_ar:Show()
	else
		self.safe_zone_ar:Hide()
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'init_boss_ammi_emp_controller' then
		self.boss = get_character(e:GetParamAt(1))
		self:change_progress(self.progress.playing)

	elseif e:GetParamAt(0) == 'done_boss_ammi_emp_controller' then
		self:change_progress(self.progress.done)

	elseif e:GetParamAt(0) == 'gimmick_battery_hit' then
		local fo = get_field_object(e:GetParamAt(1))
		if fo == nil then
			return
		end

		for i = #self.active_battery_holder, 1, -1 do
			local v = self.active_battery_holder[i]
			if v.Name == fo.Name then
				self:remove_battery(table.remove(self.active_battery_holder, i), self.remove_cause.boss_hit)
			end
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if not lua_helper.reference_equals(self.boss, e.FieldObject) then
		return
	end

	self:change_progress(self.progress.done)
end

function local_class:on_hold_up_event(e)
	if not string.match(e.Target.Name, 'battery') then
		return
	end

	if not table_util.contain_value(self.hold_up_fo_list, e.Target) then
		table.insert(self.hold_up_fo_list, e.Target)
	end

	self:toggle_safe_zone()
end

function local_class:on_throw_event(e)
	if not string.match(e.Target.Name, 'battery') then
		return
	end

	if not table_util.contain_value(self.throw_fo_list, e.Target) then
		table.insert(self.throw_fo_list, e.Target)
	end

	for i = #self.hold_up_fo_list, 1, -1 do
		local v = self.hold_up_fo_list[i]
		if v == e.Target then
			table.remove(self.hold_up_fo_list, i)
		end
	end
end

function local_class:on_thrown_end_event(e)
	local is_contain = false
	local idx = nil
	for i = #self.active_battery_holder, 1, -1 do
		local b = self.active_battery_holder[i]
		if lua_helper.reference_equals(b, e.Target) then
			is_contain = true
			idx = i
		end
	end

	if not is_contain then
		return
	end

	-- 던진 물체 리스트에서 삭제
	for i = #self.throw_fo_list, 1, -1 do
		local b = self.throw_fo_list[i]
		if lua_helper.reference_equals(b, e.Target) then
			table.remove(self.throw_fo_list, i)
		end
	end

	if CS.BoundsExtensions.ContainsXZ(self.safe_zone_bounds, e.Target.Position) then
		self:add_goal_in()
		self:remove_battery(table.remove(self.active_battery_holder, idx), self.remove_cause.goal_in)
	end

	self:toggle_safe_zone()
end

function local_class:dispose()
	if self.on_custom_stage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
		self.on_custom_stage_event_func = nil
	end

	if self.on_field_object_destroyed_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_field_object_destroyed_event_func)
		self.on_field_object_destroyed_event_func = nil
	end

	if self.on_hold_up_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.HoldUpEvent), self.on_hold_up_event_func)
		self.on_hold_up_event_func = nil
	end

	if self.on_throw_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.ThrowEvent), self.on_throw_event_func)
		self.on_throw_event_func = nil
	end

	if self.on_thrown_end_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.ThrownEndEvent), self.on_thrown_end_event_func)
		self.on_thrown_end_event_func = nil
	end

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)

end

function local_class:use_late_update_frame(e)
	return true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
