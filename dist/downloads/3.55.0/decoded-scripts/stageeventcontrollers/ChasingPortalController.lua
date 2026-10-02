local local_class = newclass('ChasingPortalController')

-- 6성재화 균열에서 맵 끝에서 쫓아오는 포탈
-- 아마 다른데서는 안쓰이지 않을까?
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local datas = require('stageeventcontrollers/ChasingPortalData.lua')
	local params = datas[stage.Name];
	if params == nil then
		params = datas['default']
	end

	self.state = {
		none = 1,
		prepare = 2,
		move = 3,
		arrive = 4,
		post = 5
	}

	-- prepare
	self.prepare_duration = params.prepare_duration

	-- move
	self.move_speed = params.move_speed
	self.damage_hp_ratio = params.damage_hp_ratio
	local damage_term = params.damage_term
	self.knockback_force = params.knockback_force

	local start_marker = field:GetMarker(params.start_marker_name)
	self.start_pos = start_marker.position
	local end_marker = field:GetMarker(params.end_marker_name)
	self.end_pos = end_marker.position
	self.position = self.start_pos
	self.move_dir_v = direction_util.to_vector3(vector_util.to_side_dir(self.end_pos - self.start_pos))

	local size = vector(params.calc_size_x, 1, params.calc_size_z)
	local info = collision_info_util.create_rotatable_cube(size, 9999, damage_term, true)
	self.calc = CS.Oak.AreaBattleCollision(user_party_leader, info)

	self.move_duration = (self.start_pos - self.end_pos).magnitude / self.move_speed

	-- arrive

	-- post

	-- etc
	self.fx_portal_pool = unity_object_pool.GetOrCreate(params.fx_portal_name)
	self.fx_hit_pool = unity_object_pool.GetOrCreate(params.fx_hit_name)

	-- event sub
	self.on_stage_end_event_func = function(e)
		self:on_stage_end_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.StageEndEvent), self.on_stage_end_event_func)

	self:change_state(self.state.none)
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx_portal = self.fx_portal_pool:Instantiate(self.start_pos)
	return
end

function local_class:on_launch(_)
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:change_state(next_state)
	-- exit
	if self.current_state == self.state.prepare then

	elseif self.current_state == self.state.move then
		self.calc:End()

	elseif self.current_state == self.state.arrive then

	elseif self.current_state == self.state.post then

	end

	-- enter
	if next_state == self.state.prepare then

	elseif next_state == self.state.move then
		self.calc:Start()

	elseif next_state == self.state.arrive then

	elseif next_state == self.state.post then

	end

	self.time_passed = 0
	self.current_state = next_state
end

function local_class:late_update_frame(dt)
	if self.current_state == self.state.none then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.prepare then
		if self.time_passed >= self.prepare_duration then
			self:change_state(self.state.move)
		end

	elseif self.current_state == self.state.move then
		self:publish_damage(dt)
		if self:update_move(dt) then
			self:change_state(self.state.arrive)
		end

	elseif self.current_state == self.state.arrive then
		self:change_state(self.state.post)

	elseif self.current_state == self.state.post then

	end
end

function local_class:update_move(dt)
	local progress = CS.Oak.Interpolations.Linear(self.time_passed, 0, 1, self.move_duration)
	self.position = vector_util.lerp(self.start_pos, self.end_pos, progress)
	CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx_portal, self.position, self.move_dir_v)
	return progress >= 1
end

function local_class:publish_damage(dt)
	self.calc.Position = self.position
	self.calc.Direction = -self.move_dir_v

	local objects = self.attack_calculator:UpdateFrame(dt)
	for _, fo in pairs(objects) do
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = user_party_leader
		damage_info.target = fo
		damage_info.knockBackDirection = self.move_dir_v
		damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
		damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.knockback_force
		self.fx_hit_pool:Instantiate(fo.Position)
	end
end

function local_class:on_stage_end_event(e)
end

function local_class:dispose()
	self.cs_controller = nil

	if self.on_stage_loaded_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)
		self.on_stage_loaded_event_func = nil
	end

	if self.on_battle_start_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.BattleStartEvent), self.on_battle_start_event_func)
		self.on_battle_start_event_func = nil
	end

	if self.on_custom_stage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
		self.on_custom_stage_event_func = nil
	end

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
