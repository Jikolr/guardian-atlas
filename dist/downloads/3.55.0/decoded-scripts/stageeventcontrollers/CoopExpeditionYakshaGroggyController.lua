local local_class = newclass('CoopExpeditionYakshaGroggyController')

local groggy_info = {
	groggy_remove_message_name = 'remove_groggy'
}

function groggy_info:update_frame(dt)
	if not self.disposed then
		self.time_passed = self.time_passed + dt
		if self.time_passed > self.duration then
			self:publish_remove_groggy()
			self:dispose()
		end
	end
end

function groggy_info:dispose()
	self.owner = nil
	self.duration = nil
	self.disposed = true
end

function groggy_info:new(owner, duration)
	local t = {}
	t.owner = owner
	t.duration = duration
	t.time_passed = 0
	setmetatable(t, {__index = groggy_info})

	return t
end

function groggy_info:publish_remove_groggy()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.groggy_remove_message_name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.owner.Owner, command)
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	local data = require('stageeventcontrollers/CoopExpeditionYakshaGroggyData.lua')[stage.Name]
	self:set_params(data)

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.boss_name = 'boss_phase_1'
	self.add_groggy_message = 'add_groggy'
	self.groggy_started_message_name = 'groggy_started'
	self.groggy_ended_message_name = 'groggy_ended'
	self.try_groggy_trigger_message_name = 'try_groggy_trigger'
	self.groggy_trigger_message_name = 'groggy_trigger'
	self.pattern_cancel_message_name=  'pattern_canceled'
	self.change_boss_message_name = 'change_boss'
	self.set_groggy_zero_message_name = 'set_groggy_zero'

	self.groggy_gauge = 0

	self.current_groggy_info = nil
	self.anim_req_groggy =  CS.Oak.AnimationRequest(self.groggy_ani_name, CS.Oak.AnimationPriorities.Custom, false, 1, -1, nil, nil, 'groggy_loop')
end

function local_class:set_params(data)
	self.gauge_groggy_time = data.gauge_groggy_time
	self.cancel_groggy_time = data.cancel_groggy_time
	self.cancel_gauge_groggy_time = data.cancel_gauge_groggy_time

	self.max_groggy_gauge = data.max_groggy_gauge
	self.groggy_ani_name = 'groggy'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end_event')

	self.boss = get_character(self.boss_name)
end

function local_class:on_coop_end_event(e)
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_custom_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == self.add_groggy_message and self.current_groggy_info == nil then
			self:publish_add_gauge(tonumber(e:GetParamAt(1)))
			return true
		elseif e:GetParamAt(0) == self.try_groggy_trigger_message_name and self:can_trigger_groggy() then
			self:publish_start_groggy()
			return true
		elseif e:GetParamAt(0) == self.pattern_cancel_message_name then
			self:publish_pattern_cancel_info()
			return true
		elseif e:GetParamAt(0) == self.change_boss_message_name then
			self:publish_change_boss(e:GetParamAt(1))
			return true
		elseif e:GetParamAt(0) == 'init_groggy_info' then
			local is_in_groggy = self.current_groggy_info ~= nil
			message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'groggy_sync', tostring(is_in_groggy) }))
		elseif e:GetParamAt(0) == self.set_groggy_zero_message_name then
			self:publish_set_groggy_zero()
		end
	end

	return false
end

function local_class:publish_set_groggy_zero()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.set_groggy_zero_message_name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.boss.Owner, command)
end

function local_class:publish_add_gauge(gauge)
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.add_groggy_message)
	info.Ints:Add(gauge)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.boss.Owner, command)
end

function local_class:publish_start_groggy()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.groggy_trigger_message_name)
	info.Floats:Add(self:determine_groggy_time())

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.boss.Owner, command)
end

function local_class:publish_pattern_cancel_info()
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.pattern_cancel_message_name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.boss.Owner, command)
end

function local_class:publish_change_boss(name)
	local info = CS.Oak.StageEventControllerSyncInfo()
	info.Strings:Add(self.change_boss_message_name)
	info.Strings:Add(name)

	local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionYakshaGroggyController', info)
	command_util.publish_cmd(self.boss.Owner, command)
end


function local_class:sync(info)
	if info.Strings[0] == self.add_groggy_message then
		self.groggy_gauge = self.groggy_gauge + info.Ints[0]

	elseif info.Strings[0] == self.groggy_trigger_message_name  then
		self.groggy_gauge = 0
		self.is_pattern_canceled = false
		self.current_groggy_info = groggy_info:new(self.boss, info.Floats[0])
		self:process_groggy_act()

	elseif info.Strings[0] == self.pattern_cancel_message_name then
		self.is_pattern_canceled = true

	elseif info.Strings[0] == self.change_boss_message_name then
		self.groggy_gauge = 0
		self.is_pattern_canceled = false
		if self.current_groggy_info ~= nil then

			self.current_groggy_info:dispose()
			self.current_groggy_info = nil

			self:process_remove_groggy_act()
		end
		self.boss_name = info.Strings[1]
		self.boss = get_character(self.boss_name)

	elseif info.Strings[0] == groggy_info.groggy_remove_message_name then
		self.groggy_gauge = 0
		self.is_pattern_canceled = false
		self:process_remove_groggy_act()

	elseif info.Strings[0] == self.set_groggy_zero_message_name then
		self.groggy_gauge = 0
		self.is_pattern_canceled = false
	end

end

function local_class:process_groggy_act()
	self.boss:SetAnimation(self.cs_controller, self.anim_req_groggy)

	self.boss.LockedDirection = self.boss.Direction
	self.boss.CharacterBehaviour:CancelAllBattleActions()

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { self.groggy_started_message_name }))
end

function local_class:process_remove_groggy_act()
	self.boss:RemoveAnimation(self.cs_controller)

	self.boss.LockedDirection = CS.Oak.Direction.None

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { self.groggy_ended_message_name }))
end

function local_class:can_trigger_groggy()
	return self.current_groggy_info == nil and (self.is_pattern_canceled or self.groggy_gauge >= self.max_groggy_gauge)
end

function local_class:determine_groggy_time()
	if self.is_pattern_canceled and self.groggy_gauge >= self.max_groggy_gauge then
		return self.cancel_gauge_groggy_time
	elseif self.is_pattern_canceled then
		return self.cancel_groggy_time
	elseif self.groggy_gauge >= self.max_groggy_gauge then
		return self.gauge_groggy_time
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

function local_class:late_update_frame(dt)
	if self.current_groggy_info ~= nil then
		self.current_groggy_info:update_frame(dt)
		if self.current_groggy_info.disposed then
			self.current_groggy_info = nil
		end
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
