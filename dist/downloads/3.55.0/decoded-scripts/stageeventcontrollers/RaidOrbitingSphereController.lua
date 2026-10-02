local local_class = newclass('RaidOrbitingSphereController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = require('stageeventcontrollers/RaidOrbitingSphereData.lua')

	self.current_stage_info = nil
	self.hit_target_list = {}
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.target_boss = get_character(self.current_stage_info.boss_name)

	self.pending_spheres = {}
	self.active_spheres = {}
	if not is_unity_null(self.target_boss) then
		for _, value in ipairs(self.current_stage_info.spheres) do
			local holder = {}
			holder.target_hp_rate = value.target_hp_rate
			holder.orbit_radius = value.orbit_radius
			holder.size_multiplier = value.effect_size_multiplier
			holder.speed = value.speed
			holder.sqr_distance = value.sphere_radius * value.sphere_radius
			holder.sphere_radius = value.sphere_radius
			holder.hit_dic = {}
			table.insert(self.pending_spheres, holder)
		end
	end

	if self.current_stage_info.sphere_projectile then
		self.sphere_pool = unity_object_pool.GetOrCreate(self.current_stage_info.sphere_projectile)
	end

	if self.current_stage_info.sphere_trail then
		self.trail_pool = unity_object_pool.GetOrCreate(self.current_stage_info.sphere_trail)
	end

	if self.current_stage_info.sphere_explosion then
		self.explosion_pool = unity_object_pool.GetOrCreate(self.current_stage_info.sphere_explosion)
	end

	self.time_passed = 0

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.current_progress == self.progress.none then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.current_progress = self.progress.playing
		end
		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress == self.progress.playing then
		if lua_helper.reference_equals(e.FieldObject, self.target_boss) then
			self.current_progress = self.progress.cleared
			self:remove_active_spheres()
		end
		return true
	end

	return false
end

function local_class:on_game_over_event(e)
	if self.current_progress == self.progress.playing then
		self.current_progress = self.progress.none
		self:remove_active_spheres()
		return true
	end

	return false
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame_priority(e)
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	-- 체력 조건 체크
	local hp_rate = self.target_boss.FieldObjectStatsBehaviour.HP / self.target_boss.FieldObjectStatsBehaviour.MaxHP
	for idx = #self.pending_spheres, 1, -1 do
		if self.pending_spheres[idx].target_hp_rate >= hp_rate then
			--새로 생성될때마다 위치 재조정 해준다.
			local sphere = table.remove(self.pending_spheres, idx)
			local init_position = vector_util.get_xy0(self.target_boss.Position, self.target_boss.Position.z - sphere.orbit_radius)
			sphere.ball = self:instantiate_effect(self.sphere_pool, init_position, sphere.size_multiplier)
			sphere.trail = self:instantiate_effect(self.trail_pool, init_position, sphere.size_multiplier)
			sphere.time_passed = 0
			sphere.ingore_target_time = 0
			table.insert(self.active_spheres, sphere)

			--위치 재조정
			for i = 1, #self.active_spheres do
				local sphere = self.active_spheres[i]
				local sphere_count = #self.active_spheres
				local dir = (unity_class.quaternion.Euler(0, i * 360 / sphere_count, 0)
						* unity_class.vector3.forward).normalized
				local target_pos = self.target_boss.Position + dir * sphere.orbit_radius
				sphere.margin_dir = dir
				if not is_unity_null(sphere.ball) then
					CS.Oak.UnityObjectPoolExtensions.UpdateObject(sphere.ball, target_pos)
				end
				if not is_unity_null(sphere.trail) then
					CS.Oak.UnityObjectPoolExtensions.UpdateObject(sphere.trail, target_pos)
				end
			end
		end
	end

	--피격 딜레이 적용
	for i = #self.hit_target_list, 1, -1 do
		self.hit_target_list[i].time_passed = self.hit_target_list[i].time_passed - dt
		if self.hit_target_list[i].time_passed <= 0 then
			table.remove(self.hit_target_list, i)
		end
	end

	-- 궤도 이동 및 판정 체크
	for idx = 1, #self.active_spheres do
		local sphere = self.active_spheres[idx]

		-- 위치 업데이트
		sphere.time_passed = sphere.time_passed + dt
		local dir = (unity_class.quaternion.Euler(0, idx * 360 / #self.active_spheres +
				(self.active_spheres[1].time_passed * sphere.speed * 10), 0) * unity_class.vector3.forward).normalized
		local target_pos = self.target_boss.Position + dir * sphere.orbit_radius
		if not is_unity_null(sphere.ball) then
			CS.Oak.UnityObjectPoolExtensions.UpdateObject(sphere.ball, target_pos)
		end
		if not is_unity_null(sphere.trail) then
			CS.Oak.UnityObjectPoolExtensions.UpdateObject(sphere.trail, target_pos)
		end

		local fo_list = field:GetFieldObjectsInRadius(target_pos, sphere.sphere_radius)
		for _,v in pairs(fo_list) do
			if not CS.Oak.EntityGroupsExtensions.IsHittableTo(self.target_boss.EntityGroup, v.EntityGroup) or
					v.FieldObjectStatsBehaviour.IsDead or lua_helper.reference_equals(self.target_boss, v)
					or self:check_hit_target(v) then
			else
				-- 판정 처리
				local pos_diff = vector_util.get_x0z(v.Position - target_pos)
				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.IgnoreDefense
				damage_info.sender = self.target_boss
				damage_info.target = v
				damage_info.damage = math.floor(v.FieldObjectStatsBehaviour.MaxHP * self.current_stage_info.proportional_damage_rate)
				damage_info.direction = pos_diff.normalized
				damage_info.knockBackFactor = self.current_stage_info.knockback_factor
				damage_info.knockBackDirection = damage_info.direction
				damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.current_stage_info.knockback_modifier

				command_util.execute_damage(damage_info)
				table.insert(self.hit_target_list, {
					target = v,
					time_passed = self.current_stage_info.damage_term
				})
			end
		end
		fo_list:Dispose()
	end
end

function local_class:check_hit_target(target)
	for _,v in pairs(self.hit_target_list) do
		if lua_helper.reference_equals(v.target, target) then
			return true
		end
	end

	return false
end

function local_class:instantiate_effect(pool, position,  multiplier)
	if not is_unity_null(pool) then
		local pooled_object = pool:Instantiate(position)
		pooled_object.transform.localScale = pooled_object.transform.localScale * multiplier
		return pooled_object
	end
	return nil
end

function local_class:remove_active_spheres()
	for idx = 1, #self.active_spheres do
		local sphere = self.active_spheres[idx]
		local target_pos = nil
		if not is_unity_null(sphere.ball) then
			target_pos = sphere.ball.transform.position
			sphere.ball:Dispose()
		end
		if not is_unity_null(sphere.trail) then
			sphere.trail:Dispose()
		end

		if target_pos and not is_unity_null(self.explosion_pool) then
			self:instantiate_effect(self.explosion_pool, target_pos, sphere.size_multiplier)
		end
	end
	self.active_spheres = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

	if self.active_spheres then
		for idx = 1, #self.active_spheres do
			local sphere = self.active_spheres[idx]
			if not is_unity_null(sphere.ball) then
				sphere.ball:Dispose()
			end
			if not is_unity_null(sphere.trail) then
				sphere.trail:Dispose()
			end
		end
		self.active_spheres = nil
	end
	self.pending_spheres = nil

	self.sphere_pool = nil
	self.trail_pool = nil
	self.explosion_pool = nil

	self.stage_battle_info = nil
	self.current_stage_info = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
	self.hit_target_list = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
