local local_class = newclass('TowerRoundTripLaserController2')

local chest = {
	state = {
		none = 1,
		wait = 2,
		patrol = 3
	},

	chest = nil,
	patrol_idx = nil,
	patrol_info_list = nil,
	move_info = nil,
	velocity = nil,
	current_state = nil,
	patrol_time_remain = nil,
	time_passed = nil,
}
chest.mt = { __index = chest }

function chest:new(chest_fo, patrol_info_list, dispose_fx)
	local obj = {}
	setmetatable(obj, self.mt)

	chest_fo.ActiveState = CS.Oak.ActiveState.Enabled
	obj.chest = chest_fo
	obj.patrol_info_list = {}
	for _, info in pairs(patrol_info_list) do
		local markers = info.patrol_markers
		local patrol_table = {}
		for _, marker in pairs(markers) do
			table.insert(patrol_table, field_util.get_marker_pos(marker))
		end
		local patrol_info = {
			patrol_table = patrol_table,
			stop_point = field_util.get_marker_pos(info.stop_point),
			delay = info.delay,
			duration = info.duration,
			velocity = info.velocity,
			damage_rate = info.damage_rate,
			laser_type = info.laser_type
		}

		if info.velocity > 0 then
			table.insert(obj.patrol_info_list, patrol_info)
		end
	end

	obj.current_state = self.state.none
	obj:init()

	obj.dispose_fx = dispose_fx
	unity_object_pool.GetOrCreate(dispose_fx)

	return obj
end

function chest:init()
	local initial_pos = self.patrol_info_list[1].patrol_table[1]
	self.move_info = {
		idx = 1,
		start = initial_pos,
		dest = initial_pos,
		estimate_time = nil
	}
	self.patrol_idx = 0

	self:set_next_patrol_route()
	self:set_next_move_info()

	self.velocity = self.patrol_info_list[1].velocity
	self.current_state = self.state.patrol
	self.time_passed = 0
end

function chest:update_frame(dt)
	if self.current_state == self.state.none then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.patrol then
		self.patrol_time_remain = self.patrol_time_remain - dt

		if self.patrol_time_remain < 0 then
			self.time_passed = self.time_passed + self.patrol_time_remain
			local progress = CS.Oak.Interpolations.Linear(self.time_passed, 0, 1, self.move_info.estimate_time)
			local position = unity_class.vector3.Lerp(self.move_info.start, self.move_info.dest, progress)
			self.chest.Position = position
			self:wait_stop_point(- self.patrol_time_remain)
			return
		end

		if self.time_passed >= self.move_info.estimate_time then
			self.chest.Position = self.move_info.dest
			self:set_next_move_info(self.time_passed - self.move_info.estimate_time)
		else
			local progress = CS.Oak.Interpolations.Linear(self.time_passed, 0, 1, self.move_info.estimate_time)
			local position = unity_class.vector3.Lerp(self.move_info.start, self.move_info.dest, progress)
			self.chest.Position = position
		end
	elseif self.current_state == self.state.wait then
		if self.time_passed >= self.move_info.estimate_time then
			self.chest.Position = self.move_info.dest
			self:set_next_patrol_route()
			self:set_next_move_info(self.time_passed - self.move_info.estimate_time)
		else
			local progress = CS.Oak.Interpolations.Linear(self.time_passed, 0, 1, self.move_info.estimate_time)
			local position = unity_class.vector3.Lerp(self.move_info.start, self.move_info.dest, progress)
			self.chest.Position = position
		end
	end
end

function chest:wait_stop_point(time_passed)
	local patrol_info = self.patrol_info_list[self.patrol_idx]
	self.move_info.idx = 0
	self.move_info.start = self.chest.Position
	self.move_info.dest = patrol_info.stop_point
	self.move_info.estimate_time = patrol_info.delay

	self.current_state = self.state.wait
	self.time_passed = time_passed and time_passed or 0
end

function chest:set_next_patrol_route()
	self.patrol_idx = math.fmod(self.patrol_idx, #self.patrol_info_list) + 1
	local patrol_info = self.patrol_info_list[self.patrol_idx]
	self.velocity = patrol_info.velocity
	self.patrol_time_remain = patrol_info.duration

	self.chest.FieldObjectBehaviour.DamageRate = patrol_info.damage_rate
	self.chest.FieldObjectBehaviour:ChangeLaserType(patrol_info.laser_type)

	self.current_state = self.state.patrol
end

function chest:set_next_move_info(time_passed)
	local patrol_info = self.patrol_info_list[self.patrol_idx]
	local patrol_table = patrol_info.patrol_table
	local mod = math.fmod(self.move_info.idx, #patrol_table)

	self.move_info.start = self.move_info.dest
	self.move_info.dest = patrol_table[mod + 1]

	local estimate_time = (self.move_info.dest - self.move_info.start).magnitude / self.velocity
	self.move_info.estimate_time = estimate_time
	self.move_info.idx = mod + 1

	self.chest.Position = self.move_info.start
	local progress = time_passed and CS.Oak.Interpolations.Linear(time_passed, 0, 1, estimate_time) or 0
	local position = unity_class.vector3.Lerp(self.move_info.start, self.move_info.dest, progress)
	self.chest.Position = position

	self.time_passed = 0
end

function chest:dispose()
	unity_object_pool.GetOrCreate(self.dispose_fx):Instantiate(self.chest.Position)
	self.chest.ActiveState = CS.Oak.ActiveState.Disabled

	self.chest = nil
	self.patrol_info_list = nil
	self.move_info = nil
	self.current_state = nil
end

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index)
		return get_field_object('tower_laser_' .. index)
	end

	self.stage_data = require('stageeventcontrollers/TowerRoundTripLaser2Data.lua')

	-- 현재 스테이지 정보
	self.current_stage_info = nil
	self.chest_list = {}
	self.damage_type = CS.Oak.DamageType.Trap
	self.time_passed = 0
	self.gimmick_active = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_data[stage.Name]
	self.owner = get_character(self.current_stage_info.gimmick_owner)
	self.laser_info_table = self.current_stage_info.laser_info
	self:init_lasers()
end

function local_class:init_lasers()
	local last_laser_index = 1
	for _, info in pairs(self.laser_info_table) do
		local chest_1 = self.get_chest_box(last_laser_index)
		local chest_2 = self.get_chest_box(last_laser_index + 1)
		last_laser_index = last_laser_index + 2
		self:set_chest_move_info(chest_1, info.chest_1.patrol_infos, info.chest_1.dispose_effect)
		self:set_chest_move_info(chest_2, info.chest_2.patrol_infos, info.chest_1.dispose_effect)
		chest_1.FieldObjectBehaviour:SetDamageType(self.damage_type)
		chest_2.FieldObjectBehaviour:SetDamageType(self.damage_type)
	end
	self.gimmick_active = true
end

function local_class:set_chest_move_info(fo, patrol_info_list, dispose_effect)
	local chest_mover = chest:new(fo, patrol_info_list, dispose_effect)
	table.insert(self.chest_list, chest_mover)
end

function local_class:on_field_object_destroyed_event(e)
	if self.owner == nil then
		return
	end

	if lua_helper.reference_equals(e.FieldObject, self.owner) then
		self:deactivate_chests()
		self.owner = nil
	end
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame(dt)
	if not self.gimmick_active then
		return
	end

	for _, chest_mover in ipairs(self.chest_list) do
		chest_mover:update_frame(dt)
	end
end

function local_class:deactivate_chests()
	if self.chest_list == nil or #self.chest_list == 0 then
		return
	end

	for i, v in ipairs(self.chest_list) do
		v.chest.FieldObjectBehaviour:DeactiveLaserEffect()
		v:dispose()
		self.chest_list[i] = nil
	end
	self.chest_list = nil
	self.gimmick_active = false

	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
end

function local_class:dispose()
	self:deactivate_chests()
	self.cs_controller = nil
	self.get_chest_box = nil
	self.stage_data = nil
	self.current_stage_info = nil
	self.laser_info_table = nil
	self.owner = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
