local local_class = newclass('CoopExpeditionNpcController')

--todo: sync해야할 부분 - npc 위치 이동
function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--search
	self.search_time = 18
	self.alert_time = 2.5

	--teleport
	self.teleport_time = 0.05

	--buff
	self.buff_cast_time = 0
	self.buff_radius = 2.1

	self.state = {
		none = 0,
		search = 1,
		teleport = 2,
		buff = 3,
	}

	self.time_passed = 0
	self.current_state = self.state.none

	self.marker_prefix = 'npc_spawn_'
	self.marker_count = 4
	self.current_marker_idx = 1
	self.target_marker_idx = 1

	--- [FIX] 파티버프랑 겹쳐서 별도의 버프를 추가함
	local buff_name = 'coopexpedition_boss_pan_npc_buff'
	-- TODO : stage_init 측에서도 버프 정보 가져오는게 필요하지 않을까..?
	--- 스펙에서 버프를 받아온 버프
	self.buff_id = game_data_service.GetData('BuffData'):GetBuffSpecFromName(buff_name).Id
	--- Base에 0.15를 때려박았기 때문에 레벨이 필요 없다.
	self.buff_level = 0

	self.alert_fx_name = 'fx_boss_pan_npc_buffzone_alert'

	self.is_buff_started = false
	self.buff_fx_postfix = {'down', 'up', 'left', 'right'}
	self.get_buff_fx_name = function(zone_idx) return 'fx_boss_pan_npc_buffzone_' .. self.buff_fx_postfix[zone_idx] end
	self.get_buff_end_fx_name = function(zone_idx) return self.get_buff_fx_name(zone_idx) .. '_end'  end

	self.buffed_fo = {}

	self.get_random_marker = function()
		local rand = random_util.get_random_int(1, self.marker_count)
		while rand == self.current_marker_idx do
			rand = random_util.get_random_int(1, self.marker_count)
		end
		return field:GetMarker(self.marker_prefix .. rand), rand
	end
	self.get_marker = function(number) return field:GetMarker(self.marker_prefix .. number)  end

	self.search_target = nil

	--npc는 character일 필요 없이 그냥 fx로 관리
	end

function local_class:load_resource()
	--fx 로드
	--todo: 임시
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end')
	unity_object_pool.GetOrCreate(self.alert_fx_name)
	for i = 1, self.marker_count do
		unity_object_pool.GetOrCreate(self.get_buff_fx_name(i))
		unity_object_pool.GetOrCreate(self.get_buff_end_fx_name(i))
	end
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	--1페이즈 시작 이벤트 받아서 NPCspawn_1에 생성 후 버프 전개 state로 변경

	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'generate_npc' then
			self.sender = e.Sender
			self.character_pos = vector(999,0,999)

			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Positions:Add(self.get_marker(1).position)
			info.Ints:Add(self.current_marker_idx)
			info.Strings:Add('sync_pos')
			info.Strings:Add(e.Sender.Name)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionNpcController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)

			self:change_state(self.state.buff)

		elseif e:GetParamAt(0) == 'remove_npc' then
			self:change_state(self.state.none)
		end
	end

	return false
end

function local_class:on_coop_end(e)
	if lua_helper.type_compare(e, CS.Oak.CoopEndEvent) then
		self:change_state(self.state.none)
	end
end

function local_class:sync(info)
	if info.Strings[0] == 'sync_pos' then
		self.character_pos = info.Positions[0]
		self.current_marker_idx = info.Ints[0]

		if self.alert_fx ~= nil then
			self.alert_fx:Dispose()
			self.alert_fx = nil
		end
	elseif info.Strings[0] == 'sync_trigger_buff' then
		if info.Ints[0] == 0 then
			if self.buff_fx ~= nil then
				self.buff_fx:TriggeredDispose()
			end
			unity_object_pool.GetOrCreate(
					self.get_buff_end_fx_name(self.current_marker_idx)):Instantiate(self.character_pos)
			self.is_buff_started = false
			self:remove_buff_all()
		else
			self.buff_fx = unity_object_pool.GetOrCreate(
					self.get_buff_fx_name(self.current_marker_idx)):Instantiate(self.character_pos)
			music_player_util.play_sfx({ sfx_name = '02_pan_statue_01', play_pos = self.character_pos })
			self.is_buff_started = true
		end
	elseif info.Strings[0] == 'sync_alert' then
		self.target_marker_idx = info.Ints[0]
		self.alert_fx = unity_object_pool.GetOrCreate(self.alert_fx_name):Instantiate(
				self.get_marker(self.target_marker_idx).position)
	end
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:change_state(next_state)
	--exit
	if self.current_state == self.state.search then

	elseif self.current_state == self.state.teleport then

	elseif self.current_state == self.state.buff then
	end

	self.current_state = next_state
	self.time_passed = 0

	--enter
	if self.current_state == self.state.search then
		--determine where to move -> sync 필요
		self.search_target, self.target_marker_idx = self.get_random_marker()
		self.search_target = self.search_target.position

	elseif self.current_state == self.state.teleport then
		if self.sender ~= nil then
			self:publish_sync_trigger_buff(false)

			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('sync_pos')
			info.Ints:Add(self.target_marker_idx)
			info.Positions:Add(self.search_target)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionNpcController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)
		end

	elseif self.current_state == self.state.buff then
	else
		self:publish_sync_trigger_buff(false)
	end
end

function local_class:late_update_frame(dt)
	self:cast_buff()

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.search then
		if self.time_passed > self.search_time then
			self:change_state(self.state.teleport)
		elseif self.time_passed > self.search_time - self.alert_time and self.time_passed - dt < self.search_time - self.alert_time then
			if self.sender ~= nil then
				local info = CS.Oak.StageEventControllerSyncInfo()
				info.Strings:Add('sync_alert')
				info.Ints:Add(self.target_marker_idx)
				local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionNpcController', info)
				--todo: owner를 보스로?
				command_util.publish_cmd(self.sender.Owner, command)
			end
		end

	elseif self.current_state == self.state.teleport then
		if self.time_passed > self.teleport_time then
			self:change_state(self.state.buff)
		end

	elseif self.current_state == self.state.buff then
		if self.time_passed > self.buff_cast_time then
			self:publish_sync_trigger_buff(true)
			self:change_state(self.state.search)
		end
	end
end

function local_class:cast_buff()
	if not self.is_buff_started then
		return
	end

	local fo_list = field:GetFieldObjectsInRadius(self.character_pos, self.buff_radius)

	self:remove_buffs(fo_list)
	self:add_buffs(fo_list)
end

function local_class:remove_buffs(fo_list)
	for i = #self.buffed_fo, 1, -1 do
		local removed = true
		for j = 0, fo_list.Count - 1 do
			if lua_helper.reference_equals(self.buffed_fo[i], fo_list[j]) then
				removed = false
				break
			end
		end

		if removed then
			buff_manager:RemoveBuff(self.buffed_fo[i], CS.Oak.EquipmentSlot.None, self.buffed_fo[i], self.buff_id)
			table.remove(self.buffed_fo, i)
		end
	end
end

function local_class:remove_buff_all()
	for i = #self.buffed_fo, 1, -1 do
		buff_manager:RemoveBuff(self.buffed_fo[i], CS.Oak.EquipmentSlot.None, self.buffed_fo[i], self.buff_id)
		table.remove(self.buffed_fo, i)
	end
end

function local_class:add_buffs(fo_list)
	for i = 0, fo_list.Count - 1 do
		local fo = fo_list[i]

		if fo:GetType() == typeof(CS.Oak.VirtualFieldObject) then
			return
		end

		local duplicated = false
		for j = 1, #self.buffed_fo do
			if lua_helper.reference_equals(fo, self.buffed_fo[j]) then
				duplicated = true
				break
			end
		end

		if not duplicated then
			if CS.Oak.EntityGroupsExtensions.IsFriendlyTo(user_party.Leader.EntityGroup, fo.EntityGroup) then
				if self.buff_id ~= -1 then
					buff_manager:AddBuff(fo, CS.Oak.EquipmentSlot.None, fo, self.buff_id, self.buff_level, true, true)
				end
				table.insert(self.buffed_fo, fo)
			end
		end
	end
end

function local_class:publish_sync_trigger_buff(trigger)
	if self.sender == nil then
		return
	end

	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add('sync_trigger_buff')
	info.Ints:Add(trigger and 1 or 0)
	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionNpcController', info)
	--todo: owner를 보스로?
	command_util.publish_cmd(self.sender.Owner, command)
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
