local local_class = newclass('TowerChasingLaser2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.state = {
		none = 1,
		delay = 2,
		move = 3,
		arrive = 4,
	}

	self.laser = { }
	self.wall = { }

	self.virtual_wall_offset = 0.5
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over')

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	local temp_data = require('stageeventcontrollers/TowerChasingLaser2Data.lua')
	local data = temp_data[stage.Name]

	for zone_name, v in pairs(data) do
		local laser_data = { }
		local delay = v.Delay
		local speed = v.Speed
		local dir = self:get_dir(v.Direction)
		local distance = v.Distance

		for _, name in pairs(v.LaserNames) do
			local fo = field:GetFieldObject(name)
			if fo == nil then goto continue end

			local start_pos = fo.Position
			local end_pos = start_pos + dir * distance

			local info =
			{
				fo = fo,
				dir = dir,
				distance = distance,
				start_pos = start_pos,
				end_pos = end_pos,
				delay = delay,
				speed = speed,
				current_state = self.state.none,
				time_passed = 0,
			}

			fo.FieldObjectBehaviour:SetDamageType(CS.Oak.DamageType.Death)
			fo.FieldObjectBehaviour:PauseLaserEffect()
			table.insert(laser_data, info)

			::continue::
		end

		local hitbox_size_x = 1
		local hitbox_size_z = 1
		local l1_pos = laser_data[1].fo.Position
		local l2_pos = laser_data[2].fo.Position

		if v.Direction == 'Right' or v.Direction == 'Left' then
			hitbox_size_z = vector_util.distance(l1_pos, l2_pos)
		else
			hitbox_size_x = vector_util.distance(l1_pos, l2_pos)
		end

		local virtual_wall = CS.Oak.VirtualFieldObject()
		virtual_wall.Name = 'block_character_wall'
		virtual_wall.Hitbox = CS.Oak.Hitbox(vector(hitbox_size_x, 1, hitbox_size_z))
		virtual_wall.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		virtual_wall.EntityGroup = CS.Oak.EntityGroups.Obstacle
		virtual_wall.ActiveState = CS.Oak.ActiveState.Disabled

		local v_start_pos = vector_util.lerp(l1_pos, l2_pos, 0.5)
		v_start_pos = v_start_pos + -dir * self.virtual_wall_offset
		local v_end_pos = v_start_pos + dir * distance

		local virtual_wall_data =
		{
			fo = virtual_wall,
			dir = dir,
			distance = distance,
			start_pos = v_start_pos,
			end_pos = v_end_pos,
			delay = delay,
			speed = speed,
			current_state = self.state.none,
			time_passed = 0,
		}

		self.laser[zone_name] = laser_data
		self.wall[zone_name] = virtual_wall_data
	end

	return
end

function local_class:late_update_frame(dt)
	self:update_laser(dt)
	self:update_wall(dt)
end

function local_class:change_state_laser(laser, new_state)
	-- exit
	if laser.current_state == self.state.delay then

	elseif laser.current_state == self.state.move then

	elseif laser.current_state == self.state.arrive then

	end

	-- enter

	if new_state == self.state.delay then

	elseif new_state == self.state.move then
		laser.fo.FieldObjectBehaviour:ResumeLaserEffect()

	elseif new_state == self.state.arrive then

	end

	laser.current_state = new_state
	laser.time_passed = 0
end

function local_class:update_laser(dt)
	for _, zone_lasers in pairs(self.laser) do
		for _, laser in pairs(zone_lasers) do
			laser.time_passed = laser.time_passed + dt

			if laser.current_state == self.state.delay then
				self:delay_laser(laser)

			elseif laser.current_state == self.state.move then
				self:move_laser(laser)

			elseif laser.current_state == self.state.arrive then

			end
		end
	end
end

function local_class:move_laser(laser)
	local start_pos = laser.start_pos
	local end_pos = laser.end_pos
	local speed = laser.speed
	local distance = laser.distance
	local dir = laser.dir
	local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.Linear(laser.time_passed, 0, 1, distance / speed))

	local curr_pos = start_pos + dir * (distance * progress)
	laser.fo.Position = curr_pos

	if progress >= 1 then
		laser.fo.Position = end_pos
		self:change_state_laser(laser, self.state.arrive)
	end
end

function local_class:delay_laser(laser)
	if laser.time_passed >= laser.delay then
		self:change_state_laser(laser, self.state.move)
	end
end

function local_class:dispose_laser(laser)
	laser.fo.FieldObjectBehaviour:DeactiveLaserEffect()
	laser.fo.ActiveState = active_state('disabled')
end

function local_class:change_state_wall(wall, new_state)
	-- exit
	if wall.current_state == self.state.delay then

	elseif wall.current_state == self.state.move then

	elseif wall.current_state == self.state.arrive then

	end

	-- enter
	if new_state == self.state.delay then
		wall.ActiveState = active_state('disabled')

	elseif new_state == self.state.move then
		wall.ActiveState = active_state('enabled')

	elseif new_state == self.state.arrive then
		wall.ActiveState = active_state('disabled')

	end

	wall.current_state = new_state
	wall.time_passed = 0
end

function local_class:update_wall(dt)
	for _, wall in pairs(self.wall) do
		wall.time_passed = wall.time_passed + dt

		if wall.current_state == self.state.delay then
			self:delay_wall(wall)

		elseif wall.current_state == self.state.move then
			self:move_wall(wall)

		elseif wall.current_state == self.state.arrive then

		end
	end
end

function local_class:move_wall(wall)
	local start_pos = wall.start_pos
	local end_pos = wall.end_pos
	local speed = wall.speed
	local distance = wall.distance
	local dir = wall.dir
	local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.Linear(wall.time_passed, 0, 1, distance / speed))

	local curr_pos = start_pos + dir * (distance * progress)
	wall.fo.Position = curr_pos

	if progress >= 1 then
		wall.fo.Position = end_pos
		self:change_state_wall(wall, self.state.arrive)
	end
end

function local_class:delay_wall(wall)
	if wall.time_passed >= wall.delay then
		self:change_state_wall(wall, self.state.move)
	end
end

function local_class:dispose_wall(wall)
	wall.fo:Dispose()
end

function local_class:on_zone_enter(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return false
	end

	local zone_name = e.Zone.Name
	local laser = self.laser[zone_name]
	if laser ~= nil then
		for _, v in pairs(laser) do
			if v.current_state == self.state.none then
				self:change_state_laser(v, self.state.delay)
			end
		end
	end

	local wall = self.wall[zone_name]
	if wall ~= nil then
		if wall.current_state == self.state.none then
			self:change_state_wall(wall, self.state.delay)
		end
	end

	return false
end

function local_class:on_game_over(e)
	for _, zone_lasers in pairs(self.laser) do
		for _, laser in pairs(zone_lasers) do
			self:change_state_laser(laser, self.state.none)
		end
	end

	for _, wall in pairs(self.wall) do
		self:change_state_wall(wall, self.state.none)
	end

	return true
end

function local_class:get_dir(str)
	if str == 'Up' then
		return vector(0, 0, 1)
	elseif str == 'Right' then
		return vector(1, 0, 0)
	elseif str == 'Down' then
		return vector(0, 0, -1)
	elseif str == 'Left' then
		return vector(-1, 0, 0)
	end

	return nil
end

function local_class:use_late_update_frame()
	return true
end

function local_class:dispose()
	for _, wall in pairs(self.wall) do
		self:dispose_wall(wall)
	end

	self.laser = nil
	self.wall = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
