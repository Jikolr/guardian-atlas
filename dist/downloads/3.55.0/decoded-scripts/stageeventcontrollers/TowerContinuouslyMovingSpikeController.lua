local local_class = newclass('TowerContinuouslyMovingSpikeController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = require('stageeventcontrollers/TowerContinuouslyMovingSpikeData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.current_wave = self.current_stage_info.waves[1]

	-- 가시블럭, 미리 전부 갖고 있다가 필요할 때 빼내면서 사용
	self.spike_pool = {}
	for idx = 1, self.current_stage_info.spike_total_count do
		local spike_block = get_field_object(self.current_stage_info.spike_name .. idx)
		spike_block.Position = unity_class.vector3(999, 0, 999)
		spike_block.ActiveState = CS.Oak.ActiveState.Disabled
		table.insert(self.spike_pool, spike_block)
	end

	CS.UnityEngine.Object.Destroy(tileset)

	-- 레이저 기믹
	self.chest_list = {}
	self.virtual_walls = {}
	if self.current_stage_info.chest_box_group then
		for _, group in ipairs(self.current_stage_info.chest_box_group) do
			local l_chest = get_field_object(group.chest_box_1)
			local r_chest = get_field_object(group.chest_box_2)
			local dir = character_util.get_direction(group.wall_direction)

			l_chest.FieldObjectBehaviour:PauseLaserEffect()
			r_chest.FieldObjectBehaviour:PauseLaserEffect()

			local wall = self:create_virtual_wall(l_chest.Position, r_chest.Position, dir)

			table.insert(self.chest_list, l_chest)
			table.insert(self.chest_list, r_chest)
			table.insert(self.virtual_walls, wall)
		end
	end

	-- 가시블럭 소환 위치 마커
	self.marker_list = {}
	for idx = 1, self.current_stage_info.marker_total_count do
		local marker_name = self.current_stage_info.spawn_marker_name .. idx
		local spawn_marker = field:GetMarker(marker_name)
		if spawn_marker ~= nil then
			table.insert(self.marker_list, spawn_marker)
		end
	end

	-- 이펙트 오브젝트 풀
	if self.current_stage_info.spike_destroy_vfx ~= nil then
		self.spike_destroy_pool = unity_object_pool.GetOrCreate(self.current_stage_info.spike_destroy_vfx)
	end
	if self.current_stage_info.spike_warp_vfx ~= nil then
		self.spike_warp_pool = unity_object_pool.GetOrCreate(self.current_stage_info.spike_warp_vfx)
	end
	if self.current_stage_info.chest_destroy_vfx ~= nil then
		self.chest_destroy_pool = unity_object_pool.GetOrCreate(self.current_stage_info.chest_destroy_vfx)
	end

	-- 효과음 로드
	if self.current_stage_info.spike_destroy_sfx ~= nil then
		self.spike_sfx_info = CS.Oak.SfxInfo()
		self.spike_sfx_info.sfxName = self.current_stage_info.spike_destroy_sfx
		self.spike_sfx_info.loop = false
		self.spike_sfx_info.typePriority = CS.Oak.SfxTypePriority.Gimmick

		music_player:PreloadSfx(self.spike_sfx_info.sfxName)
	end
	if self.current_stage_info.chest_destroy_sfx ~= nil then
		self.chest_sfx_info = CS.Oak.SfxInfo()
		self.chest_sfx_info.sfxName = self.current_stage_info.chest_destroy_sfx
		self.chest_sfx_info.loop = false
		self.chest_sfx_info.typePriority = CS.Oak.SfxTypePriority.Gimmick

		music_player:PreloadSfx(self.chest_sfx_info.sfxName)
	end

	self.active_spikes = {}
	self.pending_spikes = {}
	self.pattern_count = 0
	self.time_passed = 0

	return
end

function local_class:instantiate_virtual_spike(position, direction)
	local spike_block = table.remove(self.spike_pool)

	spike_block.Position = position
	spike_block.Direction = direction
	spike_block.ActiveState =  CS.Oak.ActiveState.Enabled

	return spike_block
end

function local_class:return_virtual_spike(spike_block)
	if spike_block then
		spike_block.Position =  unity_class.vector3(999, 0, 999)
		spike_block.ActiveState = CS.Oak.ActiveState.Disabled

		table.insert(self.spike_pool, spike_block)
	end
end

function local_class:move_spike(spike_block, dt)
	local magnitude = self.current_wave.speed * dt
	local direction = direction_util.to_vector3(spike_block.Direction)
	CS.Oak.MoveOneFrameStageLogic.ExecuteMove(spike_block, direction, magnitude)
end

function local_class:create_virtual_wall(position1, position2, direction)
	local pos_diff = position1 - position2
	local hitbox_size = vector(1, 1, 1)

	if (direction & CS.Oak.Direction.Side) ~= CS.Oak.Direction.None then
		hitbox_size.z = math.abs(pos_diff.z)
	else
		hitbox_size.x = math.abs(pos_diff.x)
	end

	local wall = CS.Oak.VirtualFieldObject()
	wall.Name = 'block_character_wall'
	wall.Hitbox = CS.Oak.Hitbox(hitbox_size)
	wall.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	wall.EntityGroup = CS.Oak.EntityGroups.Obstacle
	wall.ActiveState = CS.Oak.ActiveState.Disabled
	local pos = vector_util.lerp(position1, position2, 0.5)
	wall.Position = pos + direction_util.to_vector3(direction) * 0.5

	return wall
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	if self.current_stage_info.narration then
		sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
				{key = self.current_stage_info.narration, stop_timer = true })
	end
end

function local_class:on_battle_start_event(e)
	if self.current_progress ~= self.progress.playing then
		self.current_progress = self.progress.playing
		for idx = 1, #self.chest_list, 2 do
			self.chest_list[idx].FieldObjectBehaviour.DamageRate = 100
			self.chest_list[idx].FieldObjectBehaviour:SetDamageType(CS.Oak.DamageType.Death)
			self.chest_list[idx].FieldObjectBehaviour:ResumeLaserEffect()
			self.chest_list[idx].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true
		end
		for idx = 1, #self.virtual_walls do
			self.virtual_walls[idx].ActiveState = CS.Oak.ActiveState.Enabled
		end
		self:spawn_spikes()
		return true
	end

	return false
end

function local_class:on_battle_group_wave_clear_event(e)
	if self.current_progress == self.progress.playing then
		self:reset_spikes()
		local idx = (e.CurrentWave + 1) % #self.current_stage_info.waves + 1
		self.current_wave = self.current_stage_info.waves[idx]
		self.pattern_count = 0
		self:spawn_spikes()
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_progress == self.progress.playing then
		-- 스테이지 클리어로 판정, 가시, 레이저를 소멸시킨다.
		self.current_progress = self.progress.cleared
		self:reset_spikes()
		for _, chest in ipairs(self.chest_list) do
			chest.FieldObjectBehaviour:PauseLaserEffect()
			chest.ActiveState = CS.Oak.ActiveState.Disabled
			if not is_unity_null(self.chest_destroy_pool) then
				self.chest_destroy_pool:Instantiate(chest.Position)
			end
			if self.chest_sfx_info then
				CS.Oak.SfxInfoExtensions.ReplacePlayPosition(self.chest_sfx_info, position)
				music_player:PlaySfx(self.chest_sfx_info)
			end
		end
		for idx = 1, #self.virtual_walls do
			self.virtual_walls[idx].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end
end

function local_class:on_damage_event(e)
	if (e.Info.type & CS.Oak.DamageType.Trap) == CS.Oak.DamageType.Trap then
		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party_leader
		damage_info.target = e.Info.target
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage
		damage_info.type = CS.Oak.DamageType.Death
		command_util.execute_damage(damage_info)
	end
end

function local_class:on_game_over_event(e)
	self.current_progress = self.progress.none
end

function local_class:on_zone_enter_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.Zone.Name == self.current_stage_info.spike_end_zone and
			lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.SpikeBehaviour) then
		local target = e.FieldObject

		for idx = 1, #self.active_spikes do
			if target == self.active_spikes[idx] then
				-- 이동중인 가시블럭 제거
				local spike_block = table.remove(self.active_spikes, idx)
				if not is_unity_null(self.spike_warp_pool) then
					self.spike_warp_pool:Instantiate(target.Position)
				end
				self:return_virtual_spike(spike_block)
				break
			end
		end
	end

	return true
end

function local_class:on_zone_leave_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.Zone.Name == self.current_stage_info.spike_start_zone and e.FullLeave and
			lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.SpikeBehaviour)
			and #self.pending_spikes == 0 then
		self:spawn_spikes()
	end

	return true
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame_priority(e)
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:spawn_spikes()
	local pattern = self.current_wave.patterns[self.pattern_count + 1]

	for _, idx in ipairs(pattern) do
		local marker = self.marker_list[idx]
		local spike_block = self:instantiate_virtual_spike(marker.position, marker.direction)
		if not is_unity_null(self.spike_warp_pool) then
			self.spike_warp_pool:Instantiate(marker.position)
		end
		table.insert(self.pending_spikes, spike_block)
	end

	self.time_passed = 0
	self.pattern_count = (self.pattern_count + 1) % #self.current_wave.patterns
end

function local_class:reset_spikes()
	-- 움직이고 있는 가시블럭 제거
	self:reset_spikes_by_group(self.active_spikes)
	-- 대기중인 가시블럭 제거
	self:reset_spikes_by_group(self.pending_spikes)
end

function local_class:reset_spikes_by_group(spike_list)
	for idx = #spike_list, 1, -1 do
		-- 가시블럭 제거 및 연출
		local spike_block = table.remove(spike_list, idx)
		if self.spike_destroy_pool then
			self.spike_destroy_pool:Instantiate(spike_block.Position)
		end
		if self.spike_sfx_info then
			CS.Oak.SfxInfoExtensions.ReplacePlayPosition(self.spike_sfx_info, spike_block.Position)
			music_player:PlaySfx(self.spike_sfx_info)
		end
		self:return_virtual_spike(spike_block)
	end
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	-- update moving spikes
	for _, spike_block in ipairs(self.active_spikes) do
		self:move_spike(spike_block, dt)
	end

	self.time_passed = self.time_passed + dt

	-- wait til time passes
	if self.time_passed > self.current_wave.interval then
		for idx = #self.pending_spikes, 1, -1 do
			local spike_block = table.remove(self.pending_spikes, idx)
			table.insert(self.active_spikes, spike_block)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.stage_battle_info = nil
	self.current_stage_info = nil
	self.current_wave = nil

	self.spike_pool = nil
	self.chest_list = nil
	if self.virtual_walls then
		for idx = 1, #self.virtual_walls do
			if not is_unity_null(self.virtual_walls[idx]) then
				self.virtual_walls[idx]:Dispose()
			end
		end
		self.virtual_walls = nil
	end
	self.marker_list = nil

	self.spike_destroy_pool = nil
	self.spike_warp_pool = nil
	self.chest_destroy_pool = nil

	self.spike_sfx_info = nil
	self.chest_sfx_info = nil

	self.pending_spikes = nil
	self.active_spikes = nil

	self.pattern_count = nil
	self.time_passed = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
