local local_class = newclass('SiegeWithLaserController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress =
	{
		none = 1,
		playing = 2,
		done = 3
	}

	self.laser_state =
	{
		none = 1,
		prepare = 2,
		shoot = 3,
		post = 4
	}

	self.stage_data = require('stageeventcontrollers/SiegeWithLaserControllerData.lua')
	self.current_stage_info = nil

	self.current_battle_zone = nil

	self.current_progress = self.progress.none

	self.current_attack_count = 0

	self.laser_data_list = {}
	self.selected_laser = nil

	self.marker_ui_name = "laser_tower_"

	self:change_laser_state(self.laser_state.none)

end

function local_class:load_resource(key, load_end_callback)
	return util.cs_generator(self.on_load_resource, self, load_end_callback)
end

function local_class:on_load_resource(load_end_callback)

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	self.current_stage_info = self.stage_data[stage.Name]
	self.laser_prepare_duration = self.current_stage_info.laser_prepare_duration
	self.laser_shoot_duration = self.current_stage_info.laser_shoot_duration
	self.laser_post_duration = self.current_stage_info.laser_post_duration

	self.laser_fx_pool = unity_object_pool.GetOrCreate(self.current_stage_info.laser_fx_name)
	self.tower_on_fx_pool = unity_object_pool.GetOrCreate(self.current_stage_info.tower_on_fx_name)
	self.tower_off_fx_pool = unity_object_pool.GetOrCreate(self.current_stage_info.tower_off_fx_name)

	if load_end_callback then
		load_end_callback()
	end

end

function local_class:on_stage_start_event(e)

	self:set_lasers()

end

function local_class:set_lasers()
	local prefix = self.current_stage_info.laser_prefix

	local index = 1

	while true do
		local name = prefix..index
		local laser = get_field_object(name)

		if(laser == nil) then
			break
		end

		local laser_info =
		{
			name = name,
			can_activate = false,
			laser = laser,
			cache_interactable = laser.Interactable,
			on_fx = object_pool_extensions.Instantiate(
				self.tower_on_fx_pool,
				laser.Position + unity_class.vector3.up
				),
			off_fx = object_pool_extensions.Instantiate(
				self.tower_off_fx_pool,
				laser.Position + unity_class.vector3.up
			)
		}

		table.insert(self.laser_data_list, laser_info)

		index = index + 1
	end

	self:active_lasers(false)
end


function local_class:on_launch(_)
end

function local_class:on_custom_stage_event(e)
	local event_name = e:GetParamAt(0)

	if(e.Sender == nil) then
		return
	end

	local sender_name = e.Sender.Name

	if event_name == 'interacting' then
		self:prepare_laser(sender_name)
	elseif event_name == 'laser_recharge' then
		self:active_lasers(true)
	end
end

function local_class:change_laser_state(next_state)

	if next_state == self.current_laser_state then
		return
	end

	-- 현재 스테이트 exit 처리
	if self.current_laser_state == self.laser_state.prepare then
	elseif self.current_laser_state == self.laser_state.shoot then

		self.laser_fx:Dispose()
		self.laser_fx = nil

	elseif self.current_state == self.laser_state.post then
	end

	-- 다음 스테이트 enter 처리
	if next_state == self.laser_state.prepare then
	elseif next_state == self.laser_state.shoot then

		local target = get_character(self.current_stage_info.laser_target_name)

		local diff = target.Position - self.selected_laser.Position
		local dir_vector = diff.normalized;

		self.laser_fx = object_pool_extensions.Instantiate(
			self.laser_fx_pool,
			self.selected_laser.Position + unity_class.vector3.up,
			dir_vector
		)

		local base_scale = 10
		local rotation = unity_class.quaternion.LookRotation(dir_vector) * unity_class.quaternion.Euler(0, 90, 0)
		self.laser_fx.transform.rotation = rotation
		self.laser_fx.transform.localScale = unity_class.vector3(diff.magnitude / base_scale, 1, 1)

		music_player:PlaySfxOneShot(self.current_stage_info.laser_sfx_name)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = user_party.Leader
		damage_info.target = target
		damage_info.damage = math.floor(target.FieldObjectStatsBehaviour.MaxHP * self.current_stage_info.laser_damage_ratio)
		command_util.execute_damage(damage_info)

		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'laser_activated' }))

	elseif next_state == self.laser_state.post then
	else
	end

	self.time_passed = 0
	self.current_laser_state = next_state
end

function local_class:prepare_laser(selected_name)

	for _, laser_data in pairs(self.laser_data_list) do
		if selected_name == laser_data.name then

			if(laser_data.can_activate == false) then
				return
			end

			self.selected_laser = laser_data.laser
			self:change_laser_state(self.laser_state.prepare)
			self:active_lasers(false)
			return
		end
	end

end

function local_class:active_lasers(value)

	for _, laser_data in pairs(self.laser_data_list) do
		laser_data.can_activate = value
		local marker_name = self.marker_ui_name.._
		if value then
			laser_data.laser.Interactable = laser_data.cache_interactable
			laser_data.on_fx.transform.gameObject:SetActive(true)
			laser_data.off_fx.transform.gameObject:SetActive(false)

			ui_quest_marker:AddQuestMarkerToPoint(
				marker_name,
				-1,
				false,
				laser_data.laser.Position + vector(0, 0, self.current_stage_info.laser_market_offset)
			)

		else
			laser_data.laser.Interactable = CS.Oak.NonInteractable.Instance
			laser_data.on_fx.transform.gameObject:SetActive(false)
			laser_data.off_fx.transform.gameObject:SetActive(true)

			ui_quest_marker:RemoveQuestMarker(marker_name)
		end
	end

end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)

	if self.current_laser_state == nil or self.current_laser_state == self.laser_state.none then
		return
	end

	self.time_passed = self.time_passed + dt

	-- 각 스테이트 별 업데이트
	if self.current_laser_state == self.laser_state.prepare then
		if self.time_passed >= self.laser_prepare_duration then
			self:change_laser_state(self.laser_state.shoot)
		end
	elseif self.current_laser_state == self.laser_state.shoot then
		if self.time_passed >= self.laser_shoot_duration then
			self:change_laser_state(self.laser_state.post)
		end
	elseif self.current_laser_state == self.laser_state.post then
		if self.time_passed >= self.laser_post_duration then
			self:change_laser_state(self.laser_state.none)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
