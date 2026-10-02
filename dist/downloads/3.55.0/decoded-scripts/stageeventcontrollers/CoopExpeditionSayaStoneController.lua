local local_class = newclass('CoopExpeditionSayaStoneController')

local stone = {
	state = {
		none = 1,
		activated = 2,
		post = 3
	}
}

function stone:change_state(next_state)
	--exit
	if self.current_state == self.state.activated then
	elseif self.current_state == self.state.post then
	end

	self.time_passed = 0
	self.current_state = next_state

	--enter
	if self.current_state == self.state.activated then
	elseif self.current_state == self.state.post then
	end
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.stage_data = require('stageeventcontrollers/CoopExpeditionSayaStoneData.lua')

	self.marker_list = nil
	self.stone_info_list = {}
	self.marker_group_index_list = nil
	self.boss_character = nil
	self.user_character = nil
	self.saya_stone_list = nil

	self.stone_time_passed = 0
	self.current_spawn_stone_count = 0

	self.state = {
		none = 0,
		battle = 1,
		battle_end = 3
	}

	self.current_state = self.state.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_data[stage.Name]

	self.stone_time_passed = self.current_stage_info.spawn_time

	self.user_character = CS.Oak.CoopClient.Instance.MyCharacter
	self.boss_character = get_character(self.current_stage_info.boss_name)

	self.ailment_info = CS.Oak.AilmentInfo()
	self.ailment_info.Ailment = CS.Oak.Ailment.Aerial--common타입은 협전대만 적용되나?
	self.ailment_info.AilmentGauge = self.current_stage_info.aliment_gauge
	self.marker_group_index_list = self.current_stage_info.marker_group

	self:set_markers()
	self:set_saya_stone()
	unity_object_pool.GetOrCreate('fx_saya_sealstone_smoke')
	unity_object_pool.GetOrCreate('fx_saya_sealstone_attack')
end

function local_class:set_markers()
	self.marker_list = {}
	for i = 1, self.current_stage_info.marker_count do
		local name = self.current_stage_info.marker_name .. i
		local marker = CS.Oak.Stage.Instance.Field:GetMarker(name)
		table.insert(self.marker_list,
				{
					index = i,
					marker = marker,
				 marker_name = name
				})
	end

	self:set_marker_random()
end

function local_class:set_saya_stone()
	self.saya_stone_list = {}
	for i = 1, self.current_stage_info.saya_stone_count do
		local name = self.current_stage_info.saya_stone_name .. i
		local stone = get_field_object(name)
		table.insert(self.saya_stone_list,
				{
					index = i,
					stone = stone,
					name = name
				})
	end

	self:set_marker_random()
end

function local_class:set_marker_random()
	--마커 그룹(1그룹, 2그룹)을 섞어 준다.
	self.marker_group_index_list[1] = random_util.get_values_in_array(self.marker_group_index_list[1],
			{count = #self.marker_group_index_list[1]})
	self.marker_group_index_list[2] = random_util.get_values_in_array(self.marker_group_index_list[2],
			{count = #self.marker_group_index_list[2]})
end

function local_class:get_markers_names()
	if self.current_spawn_stone_count < self.current_stage_info.max_spawn_count then
		local marker_names = {}
		for i = 1, self.current_stage_info.spawn_count do
			local marker_info = self:get_marker(i)
			table.insert(marker_names, marker_info.marker_name)
		end

		return marker_names
	end

	return nil
end

function local_class:get_marker_for_name(marker_name)
	for _,v in pairs(self.marker_list) do
		if v.marker_name == marker_name then
			return table.remove(self.marker_list, _)
		end
	end
end

function local_class:spawn_stone(marker_names)
	--TODO: 대응되는 쌍이 있음
	--거기에 맞춰서 생성되도록 변경 필요

	if self.current_spawn_stone_count < self.current_stage_info.max_spawn_count then
		for i = 1, self.current_stage_info.spawn_count do
			local marker_info = self:get_marker_for_name(marker_names[i])--self:get_marker(i)
			marker_info.group_index = i

			if marker_info == nil then
				return
			end

			local saya_stone_info = self:get_stone_fo()

			if saya_stone_info == nil then return end

			local stone_start_pos = marker_info.marker.position + vector(-0.5, 10, -0.5)
			saya_stone_info.stone.Position = stone_start_pos

			table.insert(self.stone_info_list, {
				pos = stone_start_pos,
				marker_info = marker_info,
				saya_stone_info = saya_stone_info,
				start_pos = stone_start_pos,
				dest_pos = marker_info.marker.position + vector(-0.5, 0, -0.5),
				is_drop = true,
				is_active = true
			})

			self.current_spawn_stone_count = self.current_spawn_stone_count + 1

			message_system:Publish(CS.Oak.CustomStageEvent.Create(self.boss_character, { 'update_stone_count', tostring(self.current_spawn_stone_count) }))
		end
	end
end

function local_class:explosion_stone(stone_name)
	--TODO: 이팩트필요하면 이팩트 추가
	--폭발 범위내에 보스가 있다면 그로기 수치 추가해준다.

	for i = #self.stone_info_list, 1, -1 do
		local info = self.stone_info_list[i]
		if info.saya_stone_info.name == stone_name then
			local ifo_list = field:GetFieldObjectsInRadius(info.pos, self.current_stage_info.attack_radius)

			for _,fo in pairs(ifo_list) do
				--- 대상이 몬스터 일 경우
				if (fo.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then
					--터지는 봉인석 범위안에 있다면
					self:apply_aliment()
				end
			end
			ifo_list:Dispose()

			unity_object_pool.GetOrCreate('fx_saya_sealstone_attack'):Instantiate(info.pos)
			music_player_util.play_sfx({ sfx_name = '03_rock_break_05' })
			music_player_util.play_sfx({ sfx_name = '01_firefly_04' })

			self.current_spawn_stone_count = self.current_spawn_stone_count - 1

			self:remove_marker(info.marker_info)
			self:remove_pool_stone_fo(info.saya_stone_info)

			table.remove(self.stone_info_list, i)

			message_system:Publish(CS.Oak.CustomStageEvent.Create(self.boss_character,
					{ 'update_stone_count', tostring(self.current_spawn_stone_count) }))
		end
	end
end

function local_class:get_stone_fo()
	return table.remove(self.saya_stone_list)
end

function local_class:remove_pool_stone_fo(saya_stone_info)
	saya_stone_info.stone.Position = vector(999, 0, 999)
	table.insert(self.saya_stone_list, saya_stone_info)
end

function local_class:get_marker(group_index)
	--1그룹일 경우 그냥 빼주고 2그룹일 경우 조건체크 후 빼준다.
	self.first_get_marker_index = nil
	local marker_info = nil
	if group_index == 1 and #self.marker_list > 0 then
		for _,v in pairs(self.marker_group_index_list[group_index]) do
			for _2,v2 in pairs(self.marker_list) do
				if v2.index == self.marker_group_index_list[group_index][_] then
					self.first_get_marker_index = self.marker_group_index_list[group_index][_]
					table.remove(self.marker_group_index_list[group_index], _)
					marker_info = self.marker_list[_2]--table.remove(self.marker_list, _2)

					if marker_info ~= nil then
						marker_info.group_index = group_index
					end

					return marker_info
				end
			end
		end
	else
		for _,v in pairs(self.marker_group_index_list[group_index]) do
			if self:check_ignore_group(self.first_get_marker_index, v) or self.first_get_marker_index == nil then
				--같은 그룹이 아니거나 그룹1이 비어있다면...
				for _2,v2 in pairs(self.marker_list) do
					if v2.index == self.marker_group_index_list[group_index][_] then
						self.first_get_marker_index = self.marker_group_index_list[group_index][_]
						table.remove(self.marker_group_index_list[group_index], _)
						marker_info = self.marker_list[_2]--table.remove(self.marker_list, _2)

						if marker_info ~= nil then
							marker_info.group_index = group_index
						end

						return marker_info
					end
				end
			end
		end
	end
end

function local_class:check_ignore_group(a, b)
	for _,v in pairs(self.current_stage_info.ignore_group) do
		if v[1] == a then
			if v[2] == b then
				return false
			end
		end
	end

	return true
end

function local_class:remove_marker(marker)
	table.insert(self.marker_group_index_list[marker.group_index], marker.index)
	table.insert(self.marker_list, marker)
end

function local_class:on_damage_event(e)
	if self.sender == nil then
		return
	end

	if not is_unity_null(self.large_orb)
			and self.large_orb_fx ~= nil
			and self.large_orb == e.Info.target
			and (e.Info.sender.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None
			and self.damage_shake_count < self.max_damage_shake_count then
		self.damage_shake_count = self.damage_shake_count + 1
		self.shake_calculator:Shake(0.1, 0.5)
	end
end

function local_class:on_custom_stage_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'start_saya_stone_event' then
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('start_controller')
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionSayaStoneController', info)
			command_util.publish_cmd(self.boss_character.Owner, command)
		elseif e:GetParamAt(0) == 'hit_saya_stone' then
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('hit_saya_stone')
			info.Strings:Add(e:GetParamAt(1))
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionSayaStoneController', info)
			command_util.publish_cmd(self.boss_character.Owner, command)
		elseif e:GetParamAt(0) == 'init_stone_count' then
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'update_stone_count', tostring(self.current_spawn_stone_count) }))
		end
	end
end

--- 보스에게 CC 피해
function local_class:apply_aliment()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.boss_character, { 'add_groggy', self.current_stage_info.aliment_gauge }))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.boss_character, { 'try_groggy_trigger' }))
end

function local_class:on_battle_start_event(e)
	if self.current_stage_info ~= nil and self.current_stage_info.is_active then
		local info = CS.Oak.StageEventControllerSyncInfo()
		info.Strings:Add('start_controller')
		local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionSayaStoneController', info)
		command_util.publish_cmd(self.boss_character.Owner, command)
	end
end

function local_class:on_battle_end_event(e)
	if self.stone_info_list ~= nil then
		for i = #self.stone_info_list, 1, -1 do
			local info = self.stone_info_list[i]

			self:remove_marker(info.marker_info)
			self:remove_pool_stone_fo(info.saya_stone_info)

			table.remove(self.stone_info_list, i)
		end

		self.current_spawn_stone_count = 0
	end

	self.current_state = self.state.none

	return false
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:sync(info)
	if info.Strings[0] == 'spawn_stone' then
		local marker_names = {}
		for i = 1, self.current_stage_info.spawn_count do
			table.insert(marker_names, info.Strings[i + 1])
		end
		self:spawn_stone(marker_names)
	elseif info.Strings[0] == 'hit_saya_stone' then
		self:explosion_stone(info.Strings[1])
	elseif info.Strings[0] == 'start_controller' then--ai에서 활성화 이벤트 받아서 시작
		self.current_state = self.state.battle
	end
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame(dt)
	if self.current_state ~= self.state.battle then return end

	self:update_saya_stone(dt)

	if self.current_spawn_stone_count == 0 and self.stone_time_passed > 0 then
		self.stone_time_passed = self.stone_time_passed - dt
	elseif self.current_spawn_stone_count == 0 then
		self.stone_time_passed = self.current_stage_info.spawn_time

		local info = CS.Oak.StageEventControllerSyncInfo()
		info.Strings:Add('spawn_stone')
		info.Strings:Add(self.user_character.Name)
		local marker_names = self:get_markers_names()
		for _,v in pairs(marker_names) do
			info.Strings:Add(v)
		end
		local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionSayaStoneController', info)
		command_util.publish_cmd(self.boss_character.Owner, command)
	end
end

function local_class:update_saya_stone(dt)
	if self.stone_info_list ~= nil then
		for _,v in pairs(self.stone_info_list) do
			if v.is_active and v.is_drop then
				local move_pos = v.pos + unity_class.vector3.down * 20 * dt
				v.saya_stone_info.stone.Position = move_pos
				v.pos = move_pos

				if v.pos.y < v.dest_pos.y then
					v.saya_stone_info.stone.Position = v.dest_pos
					v.is_drop = false
					unity_object_pool.GetOrCreate('fx_saya_sealstone_smoke'):Instantiate(v.dest_pos)
					music_player_util.play_sfx({ sfx_name = '03_mech_stomp_01' })
					music_player_util.play_sfx({ sfx_name = '01_firefly_01' })
				end
			end
		end
	end
end

function local_class:on_coop_end(e)
	if lua_helper.type_compare(e, CS.Oak.CoopEndEvent) then
		self.current_state = self.state.none

		if self.stone_info_list ~= nil then
			for i = #self.stone_info_list, 1, -1 do
				local info = self.stone_info_list[i]

				self:remove_marker(info.marker_info)
				self:remove_pool_stone_fo(info.saya_stone_info)

				table.remove(self.stone_info_list, i)
			end

			self.current_spawn_stone_count = 0
		end
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}