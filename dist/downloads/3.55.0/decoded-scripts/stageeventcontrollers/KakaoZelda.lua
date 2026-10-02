local local_class = newclass("KakaoZelda")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate("FX_explosion_boss")
	unity_object_pool.GetOrCreate("stage_item")
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		self.alter = get_field_object("alter")

		local master_sword_pos = vector(self.alter.Position.x, 0.65, self.alter.Position.z + 0.2)
		local master_sword_object = unity_object_pool.GetOrCreate("stage_item"):Instantiate(master_sword_pos)
		local master_sword = master_sword_object:GetComponent(typeof(CS.Oak.StageItem))

		master_sword.ShadowActive = false
		master_sword.Position = master_sword_pos
		master_sword.Item.localScale = vector(0.7, 0.7, 0.7)
		master_sword:SetItem("master_sword")
		master_sword.Item.localRotation = unity_class.quaternion.Euler(vector(30, 0, -135))

		self.master_sword = master_sword
		self.master_sword_object = master_sword_object

	elseif event_type == typeof(CS.Oak.InteractEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pull_sword, self))
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if e.Zone.Name == "animals" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not self.animals_started then
				self.animals_started = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_animals, self))
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if e.Zone.Name == "lamp_teleport" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then

		end
	end

	return false
end

function local_class:pull_sword()
	local leader_waypoints = create_generic_list(unity_class.vector3)
	leader_waypoints:Add(self.alter.Position + vector(0, 0, 1))
	character_util.move_waypoint(user_party_leader, leader_waypoints, 1, false, "stop", "floor", CS.Oak.Direction.Down)
	wait_for_sec(0.5)

	character_util.set_anim(user_party_leader, { name = "cast", loop = true })
	character_util.set_emotion(user_party_leader, { name = "attack"})
	--screenplay_operations.call(self, "MasterSwordEffect")
	local effect = unity_object_pool.GetOrCreate("FX_explosion_boss"):Instantiate(self.alter.Position);
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sword_move, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rings_move, self))

	screenplay_operations.focus_camera(self, { position = { self.alter.Position.x, 0, self.alter.Position.z + 1 }, duration = 1, ignore_grid = true, wait = false })
	screenplay_operations.resize_camera({ size = 2, duration = 3 })

	wait_for_sec(0.5)
	screen_util.fade_out(1, unity_class.color.white)

	wait_for_sec(1)


	effect:Dispose()
	user_party_leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, CS.Oak.Item.Create(CS.Oak.ItemSpec.GetByName("master_sword_normal")), false)
	screenplay_operations.resize_camera({ size = 3, duration = 0 })
	self.ring1_object:Dispose()
	self.ring2_object:Dispose()
	self.ring3_object:Dispose()

	screen_util.fade_in(1, unity_class.color.white)

	self.master_sword_object:Dispose()
	user_party_leader.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(user_party_leader, { name = "happy"})
	character_util.set_anim(user_party_leader, { name = "victory_get", loop = false })

end

function local_class:sword_move()
	local cur_time = unity_class.time.time
	local start_y = self.master_sword.Position.y
	local end_y = self.master_sword.Position.y + 0.4
	local move_time = 4.5

	while (unity_class.time.time - cur_time) < move_time do
		local normalized_time = (unity_class.time.time - cur_time) / move_time;
		local cur_y = CS.UnityEngine.Mathf.Lerp(start_y, end_y, normalized_time)
		self.master_sword.Position = vector(self.master_sword.Position.x, cur_y, self.master_sword.Position.z)
		coroutine.yield(nil)
	end
end

function local_class:rings_move()
	local ring_center = user_party_leader.Bounds.center

	local ring1_object = unity_object_pool.GetOrCreate("stage_item"):Instantiate(ring_center)
	local ring1 = ring1_object:GetComponent(typeof(CS.Oak.StageItem))
	ring1.ShadowActive = false
	ring1.Position = ring_center
	ring1.Item.localScale = vector(0.5, 0.5, 0.5)
	ring1:SetItem("heat_ring_accessory")
	local vector1 = vector(0, 0, 1)
	self.ring1_object = ring1_object

	local ring2_object = unity_object_pool.GetOrCreate("stage_item"):Instantiate(ring_center)
	local ring2 = ring2_object:GetComponent(typeof(CS.Oak.StageItem))
	ring2.ShadowActive = false
	ring2.Position = ring_center
	ring2.Item.localScale = vector(0.5, 0.5, 0.5)
	ring2:SetItem("emerald_ring_accessory")
	local vector2  = vector(-1, 0, 0)
	self.ring2_object = ring2_object

	local ring3_object = unity_object_pool.GetOrCreate("stage_item"):Instantiate(ring_center)
	local ring3 = ring3_object:GetComponent(typeof(CS.Oak.StageItem))
	ring3.ShadowActive = false
	ring3.Position = ring_center
	ring3.Item.localScale = vector(0.5, 0.5, 0.5)
	ring3:SetItem("pearl_ring_accessory")
	local vector3  = vector(1, 0, 0)
	self.ring3_object = ring3_object

	local move_duration = 3.25
	local move_dist = 1.5
	local move_height = 0.5

	local time_passed = 0
	while time_passed < move_duration do
		time_passed = time_passed + unity_class.time.deltaTime
		progress = time_passed / move_duration
		if progress > 1 then
			progress = 1
		end

		local pip = math.pi * progress
		ring1.Position = ring_center + vector1 * move_dist * progress + vector(0, math.sin(pip) * move_height, 0)
		ring2.Position = ring_center + vector2 * move_dist * progress + vector(0, math.sin(pip) * move_height, 0)
		ring3.Position = ring_center + vector3 * move_dist * progress + vector(0, math.sin(pip) * move_height, 0)

		if time_passed >= move_duration then
			break
		end

		coroutine.yield(nil)
	end
end

function local_class:move_animals()
	local move_speed = 3.5
	local move_duration = 4

	local left1 = get_character("left1")
	left1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_anim(left1, { name = "run", loop = true })
	local left2 = get_character("left2")
	left2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_anim(left2, { name = "run", loop = true })
	local left3 = get_character("left3")
	left3.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_anim(left3, { name = "run", loop = true })

	local right1 = get_character("right1")
	right1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_anim(right1, { name = "run", loop = true })
	local right2 = get_character("right2")
	right2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_anim(right2, { name = "run", loop = true })

	local time_passed = 0

	while time_passed < move_duration do
		time_passed = time_passed + unity_class.time.deltaTime

		left1.Position = left1.Position + vector(move_speed * unity_class.time.deltaTime, 0, 0)
		left2.Position = left2.Position + vector(move_speed * unity_class.time.deltaTime, 0, 0)
		left3.Position = left3.Position + vector(move_speed * unity_class.time.deltaTime, 0, 0)

		right1.Position = right1.Position - vector(move_speed * unity_class.time.deltaTime, 0, 0)
		right2.Position = right2.Position - vector(move_speed * unity_class.time.deltaTime, 0, 0)
		coroutine.yield(nil)
	end

end


return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
