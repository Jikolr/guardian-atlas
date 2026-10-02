local local_class = newclass('TowerRoundTripLaserController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index)
		return get_field_object('tower_laser_' .. index)
	end

	self.stage_data = require('stageeventcontrollers/TowerRoundTripLaserData.lua')

	-- 현재 스테이지 정보
	self.current_stage_info = nil
	self.move_info = {}
	self.damage_type = CS.Oak.DamageType.Trap
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_data[stage.Name]
	self.laser_info_table = self.current_stage_info.laser_info
	self:init_lasers()
end

function local_class:init_lasers()
	local last_laser_index = 1
	for _, info in pairs(self.laser_info_table) do
		local chest_1 = self.get_chest_box(last_laser_index)
		local chest_2 = self.get_chest_box(last_laser_index + 1)
		last_laser_index = last_laser_index + 2
		self:set_chest_move_info(chest_1, info.chest_1.patrol_markers, info.chest_1.velocity)
		self:set_chest_move_info(chest_2, info.chest_2.patrol_markers, info.chest_2.velocity)
		chest_1.FieldObjectBehaviour.DamageRate = info.damage_rate
		chest_2.FieldObjectBehaviour.DamageRate = 0
		chest_1.FieldObjectBehaviour:ChangeLaserType(info.laser_type)
		chest_2.FieldObjectBehaviour:ChangeLaserType(info.laser_type)
		chest_1.FieldObjectBehaviour:SetDamageType(self.damage_type)
		chest_2.FieldObjectBehaviour:SetDamageType(self.damage_type)
	end
end

function local_class:set_chest_move_info(chest, markers, velocity)
	self.move_info[chest] = {
		start = nil,
		dest = nil,
		patrol_table = {},
		velocity = velocity,
		current_dir = nil,
		current_idx = 0,
		update_move_info = function(move_info)
			move_info.current_idx = move_info.current_idx % #move_info.patrol_table + 1
			move_info.start = move_info.patrol_table[move_info.current_idx]
			move_info.dest = move_info.patrol_table[move_info.current_idx % #move_info.patrol_table + 1]
			move_info.current_dir = vector_util.normalized(move_info.dest - move_info.start)
		end
	}
	for _, marker in pairs(markers) do
		table.insert(self.move_info[chest].patrol_table, field_util.get_marker_pos(marker))
	end
	self.move_info[chest]:update_move_info()
	chest.Position = self.move_info[chest].start
end

function local_class:on_stage_start_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.activate_chests, self))
end

function local_class:activate_chests()
	while true do
		for chest, move_info in pairs(self.move_info) do
			local dt = unity_class.time.deltaTime
			chest.Position = chest.Position + move_info.current_dir * (move_info.velocity * dt)
			if self.dot_product(move_info.dest - chest.Position, move_info.current_dir) < 0 then
				chest.Position = move_info.dest
				move_info:update_move_info()
			end
		end
		coroutine.yield(nil)
	end
end

function local_class.dot_product(v1, v2)
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
	self.get_chest_box = nil
	self.stage_data = nil
	self.current_stage_info = nil
	self.move_info = nil
	self.current_stage_info = nil
	self.laser_info_table = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
