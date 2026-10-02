local local_class = newclass('MovingWallPuzzleController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 움직이는 벽 퍼즐 스위치 이름
	self.get_moving_wall_switch = function(index) return get_field_object('moving_wall_switch_' .. index) end

	-- 움직이는 벽 퍼즐의 데이터 캐싱
	self.moving_wall_data = nil

	-- 움직이는 벽 퍼즐의 갯수
	self.max_moving_wall_count = 0

	-- 활성화된 움직이는 벽 퍼즐의 종류
	self.activate_moving_wall = { }

	-- 움직이는 벽 퍼즐의 이동 속도
	self.moving_wall_speed = 4
end

function local_class:load_resource()
	-- 움직이는 벽 세팅
	self:init_moving_wall_data()

	-- 이벤트 구독
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
end

function local_class:on_event(_)
	return false
end

function local_class:on_switch_on_off_event(e)
	for i = 1, self.max_moving_wall_count do
		local switch = self.get_moving_wall_switch(i)
		if lua_helper.reference_equals(e.SwitchObject, switch) then
			self:set_activate_moving_wall(switch.Name, e.IsTurningOn)
			return true
		end
	end

	return false
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
	for i = #self.activate_moving_wall, 1, -1 do
		local cur_moving_wall = self.activate_moving_wall[i]

		local fo = cur_moving_wall.spike_fo
		local start_pos = fo.Position
		local end_pos = cur_moving_wall.is_switch_on and cur_moving_wall.end_pos or cur_moving_wall.start_pos

		-- end_pos로 이동
		local diff = vector_util.get_x0z(end_pos - start_pos)
		local dir = diff.normalized
		if vector_util.is_almost_zero(dir) == false then
			CS.Oak.MoveOneFrameStageLogic.ExecuteMove(fo, dir, self.moving_wall_speed * dt)
		end

		-- 이동 완료 했으면 거리 비교하고 도착했으면 멈춤
		local magnitude = vector_util.magnitude(diff)
		if math.abs(magnitude) < 0.05 then
			fo.Position = end_pos
			self:stop_sfx(cur_moving_wall.move_sfx)
			table.remove(self.activate_moving_wall, i)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	if self.activate_moving_wall ~= nil then
		for i = #self.activate_moving_wall, 1, -1 do
			self:stop_sfx(self.activate_moving_wall[i].move_sfx)
		end

		self.activate_moving_wall = nil
	end

	self.moving_wall_data = nil

	self.cs_controller = nil
end

-- 움직이는 벽 데이터 세팅
function local_class:init_moving_wall_data()
	local constants_data = require('stageeventcontrollers/MovingWallPuzzleConstants')
	local target_constants_data = constants_data[stage.Name]

	-- 움직이는 벽 퍼즐의 속도 세팅
	self.moving_wall_speed = target_constants_data.speed

	-- 움직이는 벽 퍼즐의 데이터 세팅
	self.moving_wall_data = {}
	for key, value in pairs(target_constants_data.spec) do
		local moving_wall_data = {}

		-- 필드 오브젝트 세팅
		moving_wall_data.fo_list = {}
		moving_wall_data.start_pos = {}
		moving_wall_data.end_pos = {}

		for i = 1, #value.fo_name_list do
			local spike_fo = get_field_object(value.fo_name_list[i])
			table.insert(moving_wall_data.fo_list, spike_fo)
			table.insert(moving_wall_data.start_pos, spike_fo.Position)
			table.insert(moving_wall_data.end_pos, field_util.get_marker_pos(value.end_pos_marker_name[i]))
		end

		self.moving_wall_data[key] = moving_wall_data

		-- 움직이는 벽 퍼즐의 갯수 세팅
		self.max_moving_wall_count = self.max_moving_wall_count + 1
	end

	self.activate_moving_wall = {}
end

-- 움직이는 벽 로직 활성화
function local_class:set_activate_moving_wall(switch_name, is_switch_on)
	local target_data = self.moving_wall_data[switch_name]
	local spike_count = #target_data.fo_list

	for i = 1, spike_count do
		local cur_spike_fo = target_data.fo_list[i]
		local is_already_active = false

		for j = 1, #self.activate_moving_wall do
			-- 이미 활성화 된 상태라면 is_switch_on만 바꿔준다.
			if self.activate_moving_wall[j].spike_fo.Name == cur_spike_fo.Name then
				is_already_active = true
				self.activate_moving_wall[j].is_switch_on = is_switch_on
				break
			end
		end

		-- 활성화가 되어 있지 않은 상태라면 activate 쪽에 포함시킨다.
		if is_already_active == false then
			local activate_data = {}
			activate_data.spike_fo = cur_spike_fo
			activate_data.is_switch_on = is_switch_on
			activate_data.start_pos = target_data.start_pos[i]
			activate_data.end_pos = target_data.end_pos[i]
			activate_data.move_sfx = music_player_util.play_sfx({ sfx_name = '01_push_rock_01', parent = cur_spike_fo
			, type_priority = 'gimmick', player_priority = 'object' })

			table.insert(self.activate_moving_wall, activate_data)
		end
	end
end

function local_class:stop_sfx(sfx)
	if sfx ~= nil then
		sfx:Stop()
		sfx = nil
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
