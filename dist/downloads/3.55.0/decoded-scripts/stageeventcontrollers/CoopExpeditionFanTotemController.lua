-- 토템 자체의 기능은 behaviour로 구분해서 구현
-- 여기서는 자동 활성화 관련 컨트롤
local local_class = newclass('CoopExpeditionFanTotemController')

--todo: sync해야할 부분 - 토템 activate를 커맨드로
function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.fan_totem_prefix = 'FanTotem_'
	self.fan_totem_count = 4

	self.activate_time = 14
	self.time_passed = 0

	self.is_enhanced = false
	self.is_enabled = false
	self.is_coop_ended = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end')
	--todo: fan totem list 받아오기
	self.fan_totem_table = {}
	for i = 1, self.fan_totem_count do
		table.insert(self.fan_totem_table, get_field_object(self.fan_totem_prefix .. i).FieldObjectBehaviour)
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
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'activate_auto_generate' then
			self.sender = e.Sender
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('activate_auto_generate')
			info.Strings:Add(e.Sender.Name)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionFanTotemController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)
			return true

		elseif e:GetParamAt(0) == 'deactivate_auto_generate' then
			self.sender = e.Sender
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('activate_auto_generate')
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionFanTotemController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)
			return true

		elseif e:GetParamAt(0) == 'enhance_auto_generate'	then
			self.sender = e.Sender
			local info = CS.Oak.StageEventControllerSyncInfo()
			info.Strings:Add('enhance_auto_generate')
			info.Strings:Add(e.Sender.Name)
			local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionFanTotemController', info)
			--todo: owner를 보스로?
			command_util.publish_cmd(self.sender.Owner, command)
			return true
		end
	end

	return false
end

function local_class:on_coop_end(e)
	if lua_helper.type_compare(e, CS.Oak.CoopEndEvent) then
		self.is_coop_ended = true
		self.is_enabled = false
		self.is_enhanced = false
	end
end

function local_class:sync(info)
	if info.Strings[0] == 'activate_auto_generate' then
		self.is_enabled = true
		self.active_count = 1
		self.sender = stage:GetCharacter(info.Strings[1])

		for i = 1, #self.fan_totem_table do
			self.fan_totem_table[i].OwnerFo = self.sender
		end
	elseif info.Strings[0] == 'deactivate_auto_generate' then
		self.is_enabled = false
		self.is_enhanced = false

	elseif info.Strings[0] == 'enhance_auto_generate' then
		self.is_enabled = true
		self.is_enhanced = true
		self.sender = stage:GetCharacter(info.Strings[1])

		for i = 1, #self.fan_totem_table do
			self.fan_totem_table[i].OwnerFo = self.sender
		end
	elseif info.Strings[0] == 'activate_totem' then
		local totem1 = get_field_object(info.Strings[1]).FieldObjectBehaviour
		local totem2 = get_field_object(info.Strings[2]).FieldObjectBehaviour

		totem1:ChangeToNextState()
		if self.is_enhanced then
			totem2:ChangeToNextState()
		end
	end

end

function local_class:get_totem_to_activate()
	self:shuffle_totem_table()

	local ret1, ret2 = 999, 999
	local min1, min2 = 999, 999

	for i = 1, #self.fan_totem_table do
		if self.fan_totem_table[i].CurrentLevel < min1 then
			min2 = min1
			min1 = self.fan_totem_table[i].CurrentLevel

			ret2 = ret1
			ret1 = self.fan_totem_table[i]

		elseif self.fan_totem_table[i].CurrentLevel < min2 then
			min2 = self.fan_totem_table[i].CurrentLevel

			ret2 =  self.fan_totem_table[i]
		end
	end
	if min2 - min1 >= 2 then
		ret2 = ret1
	end

	return ret1, ret2
end

function local_class:shuffle_totem_table()
	for i = #self.fan_totem_table, 1, -1 do
		local idx = random_util.get_random_int(1, i)
		self.fan_totem_table[idx], self.fan_totem_table[i] = self.fan_totem_table[i], self.fan_totem_table[idx]
	end
end

function local_class:activate_totem()
	local totem1, totem2 = self:get_totem_to_activate()

	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add('activate_totem')
	info.Strings:Add(totem1.Name)
	info.Strings:Add(totem2.Name)
	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionFanTotemController', info)
	command_util.publish_cmd(self.sender.Owner, command)
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if not self.is_enabled or self.is_coop_ended then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.time_passed > self.activate_time then
		self.time_passed = 0
		self:activate_totem()
	end
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
