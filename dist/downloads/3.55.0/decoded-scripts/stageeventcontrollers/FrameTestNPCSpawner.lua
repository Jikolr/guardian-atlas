local local_class = newclass("FrameTestNPCSpawnerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.optimized_npcs = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local spec_names = {}

	for i = 1, 100 do
		local mod = i % 5

		if mod == 0 then
			spec_names[tostring(i)] = 'demon1_civilian_male'
		elseif mod == 1 then
			spec_names[tostring(i)] = 'demon1_civilian_female'
		elseif mod == 2 then
			spec_names[tostring(i)] = 'demon1_civilian_business_male'
		elseif mod == 3 then
			spec_names[tostring(i)] = 'demon1_civilian_business_female'
		elseif mod == 4 then
			spec_names[tostring(i)] = 'demon1_police_android'
		end
	end

	self.optimized_npcs = load_util.create_optimized_npcs_async(spec_names)

	local pos_1 = vector(-5, 0, -49)
	local pos_2 = vector(3, 0, -78)

	local range_x_1 = 10
	local range_z_1 = 7

	local range_x_2 = 21
	local range_z_2 = 10

	local rand_distance_limit = 20

	for i = 1, 100 do
		local cur_npc = self.optimized_npcs[tostring(i)]

		local val = math.floor(i / 100)

		if val == 0 then
			local cur_x = unity_class.random.Range(-range_x_1, range_x_1)
			local cur_z = unity_class.random.Range(-range_z_1, range_z_1)

			character_util.set_position(cur_npc, pos_1 + vector(cur_x, 0, cur_z))
		else
			local cur_x = unity_class.random.Range(-range_x_2, range_x_2)
			local cur_z = unity_class.random.Range(-range_z_2, range_z_2)

			character_util.set_position(cur_npc, pos_2 + vector(cur_x, 0, cur_z))
		end

		character_util.set_anim(cur_npc, { name = 'walk' })

		local mod = i % 2

		if mod == 0 then
			local cur_distance = unity_class.random.Range(-rand_distance_limit, rand_distance_limit)

			local waypoint_list = create_generic_list(unity_class.vector3)
			waypoint_list:Add(cur_npc.Position)
			waypoint_list:Add(cur_npc.Position + vector(cur_distance, 0, 0))

			character_util.move_waypoint(cur_npc, waypoint_list, 3,
					false, 'loop', 'floor', 'down')
		else
			local cur_distance_x = unity_class.random.Range(-rand_distance_limit, rand_distance_limit)
			local cur_distance_z = unity_class.random.Range(-rand_distance_limit, rand_distance_limit)

			local waypoint_list = create_generic_list(unity_class.vector3)
			waypoint_list:Add(cur_npc.Position)
			waypoint_list:Add(cur_npc.Position + vector(cur_distance_x, 0, 0))
			waypoint_list:Add(cur_npc.Position + vector(cur_distance_x, 0, cur_distance_z))
			waypoint_list:Add(cur_npc.Position + vector(0, 0, cur_distance_z))

			character_util.move_waypoint(cur_npc, waypoint_list, 3,
					false, 'loop', 'floor', 'down')
		end
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	return false
end

function local_class:dispose()
	-- 동적 로딩한 캐릭터들 제거
	if self.optimized_npcs ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_npcs)

		self.optimized_npcs = nil
	end

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}