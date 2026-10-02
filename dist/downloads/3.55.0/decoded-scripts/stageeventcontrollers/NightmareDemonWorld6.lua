local local_class = newclass('NightmareDemonWorld6Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- 스파이크 리셋 스위치
	self.get_spike_switch = function() return get_field_object('paparazzi_spike_switch') end

	self.is_play_spike_routine = false

	self.spike_push_speed = 8.5

	self.spike_lower = -27

	self.spike_upper = -30
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	end

	return false
end

function local_class:on_stage_loaded(_)
	self.spikes = {}
	for i = 1, 5 do
		table.insert(self.spikes, get_field_object('paparazzi_spike_' .. i))
	end

	-- 큐블리 세팅
	local vloger = get_character('vloger_1')
	vloger.SpineController:SetAttachment('[base]weapon1', 'selfie_stick')
	character_util.set_anim(vloger, { name = 'sword_idle' })
end

function local_class:on_switch_on_off_event(e)
	local spike_switch = self.get_spike_switch()
	if lua_helper.reference_equals(e.SwitchObject, spike_switch) then
		if e.IsTurningOn and not self.is_play_spike_routine then
			-- 스위치를 켜는 이벤트가 왔을 때는 로직 시작
			self.is_play_spike_routine = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spike_routine, self))
			return true
		end
	end

	return false
end

-- 스파이크 움직이는 로직 시작
function local_class:spike_routine()
	self.is_play_spike_routine = false
	coroutine.yield(nil)
	self.is_play_spike_routine = true

	-- 스파이크가 왼쪽으로 이동
	music_player_util.play_sfx_one_shot('01_push_rock_unit_01')
	local is_move = true
	while is_move and self.is_play_spike_routine do
		local dt = unity_class.time.deltaTime
		local count = 0
		for i = 1, #self.spikes do
			if self.spikes[i].Position.x <= self.spike_upper then
				count = count + 1
			else
				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.spikes[i], vector(-1, 0, 0), self.spike_push_speed * dt)
			end
		end

		if count >= 3 then
			is_move = false
			break
		end

		coroutine.yield(nil)
	end

	-- 스파이크가 돌아감
	is_move = true
	while is_move and self.is_play_spike_routine do
		local dt = unity_class.time.deltaTime
		local count = 0
		for i = 1, #self.spikes do
			if self.spikes[i].Position.x >= self.spike_lower then
				count = count + 1
			else
				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.spikes[i], vector(1, 0, 0), self.spike_push_speed * dt)
			end
		end

		if count >= 3 then
			is_move = false
			break
		end

		coroutine.yield(nil)
	end

	-- 초기 좌표로 리셋
	for i = 1, #self.spikes do
		self.spikes[i].Position = vector(self.spike_lower, 0, -75 - i)
	end

	self.is_play_spike_routine = false
end

function local_class:use_late_update_frame()
	return false
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self.spikes = nil
	self.is_play_spike_routine = false
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
