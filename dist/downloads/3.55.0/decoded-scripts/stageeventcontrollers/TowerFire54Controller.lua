local local_class = newclass('TowerFire54Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.box_fo_list = { }
	self.laser_fo_list = { }

	-- 리젠 대기 박스 풀
	self.box_spawn_pool = { }

	-- 레이저 디스에이블 풀
	self.laser_pool = { }

	self.box_regen_duration = nil
	self.disable_laser_duration = nil

	self.buff_id_list = { }
	self.buff_level_list = { }
	self.heal_hp_ratio = nil

	self.guide_zone_list = nil
	self.guide_fo_name_list = nil

	self.switch_gimmick_list = nil

	self.narration_key = nil

	self.is_battle = false

	--effect
	self.fx_box_spawn = nil
	self.fx_box_remove = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')

	message_system:Subscribe(self, typeof(CS.Oak.BattleEnterEvent), 'on_battle_enter')
	message_system:Subscribe(self, typeof(CS.Oak.BattleLeaveEvent), 'on_battle_leave')

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage')

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave')

	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local temp_data = require('stageeventcontrollers/TowerFire54Data.lua')
	local data = temp_data[stage.Name]

	self.box_regen_duration = data.BoxRegenDuration
	self.disable_laser_duration = data.DisableLaserDuration

	self.buff_id_list = data.BuffIdList
	self.buff_level_list = data.BuffLevelList
	self.heal_hp_ratio = data.HealHpRatio

	local box_names = data.BoxName
	for _, v in pairs(box_names) do
		local fo = get_field_object(v)
		if fo ~= nil then
			table.insert(self.box_fo_list, fo)
		end
	end

	local laser_names = data.LaserName
	for _, v in pairs(laser_names) do
		local fo = get_field_object(v)
		if fo ~= nil then
			table.insert(self.laser_fo_list, fo)
		end
	end

	self.guide_zone_list = data.GuideMarkerZone
	self.switch_gimmick_list = data.SwitchGimmick

	self.narration_key = data.NarrationKey

	self.fx_box_spawn = unity_object_pool.GetOrCreate('FX_Obj_Box_spawner')
	self.fx_box_remove = unity_object_pool.GetOrCreate('FX_dead')
	return
end

function local_class:late_update_frame(dt)
	self:update_box_regen_pool(dt)
	self:update_laser_pool(dt)
end

function local_class:update_box_regen_pool(dt)
	for i = #self.box_spawn_pool, 1, -1 do
		local data = self.box_spawn_pool[i]
		data.elapsed_time = data.elapsed_time + dt

		if data.elapsed_time >= self.box_regen_duration then
			self:regen_box(data.fo, data.pos)
			table.remove(self.box_spawn_pool, i)
		end
	end
end

function local_class:update_laser_pool(dt)
	for i = #self.laser_pool, 1, -1 do
		local data = self.laser_pool[i]
		data.elapsed_time = data.elapsed_time + dt

		if data.elapsed_time >= self.disable_laser_duration then
			for _, v in pairs(data.targets) do
				self:resume_laser(v)
			end
			table.remove(self.laser_pool, i)
		end
	end
end

function local_class:regen_box(fo, pos)
	fo.Position = pos
	self:add_guide(fo)
end

function local_class:remove_box(fo)
	table.insert(self.box_spawn_pool, { fo = fo, pos = fo.Position, elapsed_time = 0 })
	self.fx_box_remove:Instantiate(fo.Position)

	fo.Position = vector(999, 0, 999)
end

function local_class:add_buff()
	for _, fo in pairs(user_party) do
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = fo
		heal_info.target = fo
		heal_info.heal = math.floor(fo.FieldObjectStatsBehaviour.MaxHpWoMod * self.heal_hp_ratio)
		command_util.execute_heal(heal_info)

		for i, buff_id in pairs(self.buff_id_list) do
			local buff_lv = self.buff_level_list[i]
			buff_manager:AddBuff(fo, CS.Oak.EquipmentSlot.None, fo, buff_id, buff_lv, true, false)
		end
	end
end

function local_class:add_guide(fo)
	if table_util.contain_value(self.guide_fo_name_list, fo.Name) and self.is_battle then
		CS.Oak.UIQuestMarkersController.Instance:AddQuestMarkerToIFO(fo.Name, 0, false, fo)
	end
end

function local_class:pause_laser(fo)
	fo.FieldObjectBehaviour:PauseLaserEffect()
end

function local_class:resume_laser(fo)
	fo.FieldObjectBehaviour:ResumeLaserEffect()
end

function local_class:remove_guide(fo)
	CS.Oak.UIQuestMarkersController.Instance:RemoveQuestMarker(fo.Name)
end

function local_class:clear_guide()
	for _, v in pairs(self.box_fo_list) do
		self:remove_guide(v)
	end
end

function local_class:on_stage_start(e)
	-- 클리어 조건 안내
	local show_narration = function()
		field_ui_manager:Hide()
		field_ui_util.show_narration_async({ key = self.narration_key })
		field_ui_manager:Show()
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(show_narration))
end

function local_class:on_battle_enter(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) == false then
		return
	end

	self.is_battle = true

	for _, v in pairs(self.box_fo_list) do
		self:add_guide(v)
	end
end

function local_class:on_battle_leave(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) == false then
		return
	end

	self.is_battle = false

	self:clear_guide()
end

function local_class:on_custom_stage(e)
	if e:GetParamAt(0) ~= 'interacting' then
		return
	end

	for _, v in pairs(self.box_fo_list) do
		if lua_helper.reference_equals(v, e.Sender) then
			self:remove_box(v)
			self:remove_guide(v)
			self:add_buff()
		end
	end
end

function local_class:on_zone_enter(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) == false then
		return
	end

	if string.match(e.Zone.Name, 'battle') == false then
		return
	end

	local data = self.guide_zone_list[e.Zone.Name]
	if data == nil then
		return
	end

	self.guide_fo_name_list = data
end

function local_class:on_zone_leave(e)
	if lua_helper.reference_equals(e.FieldObject, user_party_leader) == false then
		return
	end

	if string.match(e.Zone.Name, 'battle') == false then
		return
	end

	self.guide_fo_name_list = { }
end

function local_class:on_switch_on_off(e)
	if e.IsTurningOn == false then
		return
	end

	local data = self.switch_gimmick_list[e.SwitchObject.Name]
	if data == nil then
		return
	end

	local temp_target = { }
	for _, v1 in pairs(data) do
		for _, v2 in pairs(self.laser_fo_list) do
			if v1 == v2.Name then
				-- pause 시키고 넣자
				self:pause_laser(v2)
				table.insert(temp_target, v2)
			end
		end
	end

	-- contain check
	local contain_idx = nil
	for i, v in pairs(self.laser_pool) do
		if v.switch_fo.Name == e.SwitchObject.Name then
			contain_idx = i
			break
		end
	end

	if contain_idx == nil then
		local val = {
			switch_fo = e.SwitchObject,
			targets = temp_target,
			elapsed_time = 0
		}
		table.insert(self.laser_pool, val)
	else
		self.laser_pool[contain_idx].elapsed_time = 0
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleLeaveEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
