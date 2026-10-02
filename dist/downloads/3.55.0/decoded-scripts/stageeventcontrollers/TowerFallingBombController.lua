local local_class = newclass('TowerFallingBombController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.bomb_state = {
		none = 1,
		prepare = 2,
		fall = 3,
		explosion = 4
	}

	self.stage_battle_info = require('stageeventcontrollers/TowerFallingBombData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	local tileset = nil
	local bomb = nil

	if self.current_stage_info.missile_vfx then
		-- 설정해둔 사용할 오브젝트 풀 명칭이 있을경우 오브젝트 풀 사용
		self.missile_effect = unity_object_pool.GetOrCreate(self.current_stage_info.missile_vfx)
		self.use_resource_holder = false
	else
		self.res_holder = CS.Foundations.ResourceHolder()
		tileset = load_util.load_prefab_async(self.res_holder, 'tilesets/gimmick', 'gimmick.tileset')
		bomb = tileset.transform:Find('[GIMMICK]bomb1')
		self.use_resource_holder = true
	end

	self.bomb_groups = {}
	if self.current_stage_info.target_groups then
		for _, group in ipairs(self.current_stage_info.target_groups) do
			local temp_group = {}

			if group.markers then
				for idx = 1, #group.markers do
					-- 폭탄 초기 설정
					local spawn_marker = field:GetMarker(group.markers[idx].name)
					if spawn_marker then
						local bomb_holder = {}
						if self.use_resource_holder then
							local bomb_transform = CS.UnityEngine.GameObject.Instantiate(bomb.gameObject).transform
							bomb_transform.gameObject:SetActive(false)
							bomb_transform:Find('mesh/bomb1/root_wick/wick/FX_BombSpark_mesh').gameObject:SetActive(false)
							bomb_holder.transform = bomb_transform
						end
						bomb_holder.delay = group.markers[idx].delay_time
						bomb_holder.state = self.bomb_state.none
						bomb_holder.time_passed = 0
						bomb_holder.destination = spawn_marker.position
						bomb_holder.radius = self.current_stage_info.explosion_radius
						table.insert(temp_group, bomb_holder)
					end
				end
			end

			if #temp_group > 0 then
				self.bomb_groups[group.event_zone] = temp_group
			end
		end
	end

	if self.use_resource_holder then
		CS.UnityEngine.Object.Destroy(tileset)
	end

	if self.current_stage_info.explosion_vfx then
		self.explosion_effect = unity_object_pool.GetOrCreate(self.current_stage_info.explosion_vfx)
	end
	if self.current_stage_info.bomb_warp_vfx then
		self.warp_effect = unity_object_pool.GetOrCreate(self.current_stage_info.bomb_warp_vfx)
	end
	if self.current_stage_info.explosion_sfx then
		self.explosion_sfx_info = CS.Oak.SfxInfo()
		self.explosion_sfx_info.sfxName = self.current_stage_info.explosion_sfx
		self.explosion_sfx_info.loop = false
		self.explosion_sfx_info.typePriority = CS.Oak.SfxTypePriority.Gimmick
		music_player:PreloadSfx(self.explosion_sfx_info.sfxName)
	end

	self.current_active_groups = {}

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

function local_class:on_stage_start(e)
	self.current_progress = self.progress.playing
end

function local_class:on_game_over_event(e)
	self.current_progress = self.progress.none

	self:terminate_bomb_group()
end

function local_class:on_zone_enter_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.FieldObject == user_party_leader and e.FullEnter then
		self:begin_bomb_group(e.Zone.Name)
	end
end

function local_class:on_zone_leave_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.FieldObject == user_party_leader and e.FullLeave then
		self:end_bomb_group(e.Zone.Name)
	end
end

function local_class:begin_bomb_group(zone_name)
	local target_group = self.bomb_groups[zone_name]

	if target_group and not table_util.contain_value(self.current_active_groups) then
		for _, bomb_holder in ipairs(target_group) do
			self:change_bomb_state(bomb_holder, self.bomb_state.prepare)
		end
		table.insert(self.current_active_groups, target_group)
	end
end

function local_class:end_bomb_group(zone_name)
	local target_group = self.bomb_groups[zone_name]
	if target_group then
		for idx, group in ipairs(self.current_active_groups) do
			if target_group == group then
				for _, bomb_holder in ipairs(target_group) do
					self:change_bomb_state(bomb_holder, self.bomb_state.none)
				end
				table.remove(self.current_active_groups, idx)
				return
			end
		end
	end
end

function local_class:terminate_bomb_group()
	if self.current_active_groups then
		for idx = #self.current_active_groups, 1, -1 do
			local target_group = self.current_active_groups[idx]
			for _, bomb_holder in ipairs(target_group) do
				self:change_bomb_state(bomb_holder, self.bomb_state.none)
			end
			table.remove(self.current_active_groups, idx)
		end
	end
end

function local_class:change_bomb_state(holder, next_state)
	if holder.state == next_state then return end

	-- 상태 이탈 처리
	if holder.state == self.bomb_state.prepare then

	elseif holder.state == self.bomb_state.fall then
		local warp_pos = nil
		if self.use_resource_holder then
			warp_pos = holder.transform.position
			holder.transform.gameObject:SetActive(false)
		elseif not is_unity_null(holder.missile) then
			warp_pos = holder.missile.transform.position
			holder.missile:Dispose()
			holder.missile = nil
		end

		if next_state ~= self.bomb_state.explosion and not is_unity_null(self.warp_effect) then
			-- 폭발하지 못하고 상태 변경시 워프 이펙트 출력
			if not warp_pos and is_unity_null(self.warp_effect) then
				self.warp_effect:Instantiate(warp_pos)
			end
		end
	elseif holder.state == self.bomb_state.explosion then

	end

	-- 상태 진입 처리
	if next_state == self.bomb_state.prepare then

	elseif next_state == self.bomb_state.fall then
		local target_pos = vector_util.get_x0z(holder.destination, holder.destination.y + self.current_stage_info.bomb_height)
		if self.use_resource_holder then
			holder.transform.position = target_pos
			holder.transform.gameObject:SetActive(true)
		elseif not is_unity_null(self.missile_effect) then
			holder.missile = self.missile_effect:Instantiate(target_pos)
		end
		if not is_unity_null(self.warp_effect) then
			self.warp_effect:Instantiate(target_pos)
		end
	elseif next_state == self.bomb_state.explosion then
		if not is_unity_null(self.explosion_effect) then
			self.explosion_effect:Instantiate(holder.destination)
		end
		if self.explosion_sfx_info then
			CS.Oak.SfxInfoExtensions.ReplacePlayPosition(self.explosion_sfx_info, holder.destination)
			music_player:PlaySfx(self.explosion_sfx_info)
		end
	end

	holder.time_passed = 0
	holder.state = next_state
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame_priority(e)
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	-- 현재 동작중인 그룹 업데이트
	for _, update_group in ipairs(self.current_active_groups) do
		for _, holder in ipairs(update_group) do
			if holder.state == self.bomb_state.prepare then
				holder.time_passed = holder.time_passed + dt
				if holder.time_passed > holder.delay then
					self:change_bomb_state(holder, self.bomb_state.fall)
				end
			elseif holder.state == self.bomb_state.fall then
				self:on_fall_state(holder)
				holder.time_passed = holder.time_passed + dt
				if holder.time_passed > self.current_stage_info.fall_duration then
					self:change_bomb_state(holder, self.bomb_state.explosion)
				end
			elseif holder.state == self.bomb_state.explosion then
				self:on_explosion_state(holder)
				self:change_bomb_state(holder, self.bomb_state.prepare)
			end
		end
	end
end

-- 폭탄 낙하중 처리
function local_class:on_fall_state(holder)
	local progress = 1 - CS.Oak.Interpolations.Linear(holder.time_passed, 0, 1, self.current_stage_info.fall_duration)
	local next_height = holder.destination.y + progress * self.current_stage_info.bomb_height
	local final_pos = vector_util.get_x0z(holder.destination, next_height)
	if self.use_resource_holder then
		holder.transform.position = final_pos
	elseif not is_unity_null(holder.missile) then
		CS.Oak.UnityObjectPoolExtensions.UpdateObject(holder.missile, final_pos)
	end
end

-- 폭발 판정 / 대미지 처리, 한번만 체크할것
function local_class:on_explosion_state(holder)
	local fo_list = field:GetFieldObjectsInRadius(holder.destination, self.current_stage_info.explosion_radius)
	for _,fo in pairs(fo_list) do
		if fo.ActiveState == CS.Oak.ActiveState.Enabled
				and not fo.FieldObjectStatsBehaviour.IsDead
				and lua_helper.type_compare(fo, typeof(CS.Oak.Character)) then

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
			damage_info.sender = fo
			damage_info.target = fo
			damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * self.current_stage_info.proportional_damage_rate)
			damage_info.direction = (fo.Position - holder.destination).normalized

			command_util.execute_damage(damage_info)
		end
	end
	fo_list:Dispose()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	if self.res_holder then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.current_active_groups = nil
	self.prev_group = nil

	if self.bomb_groups then
		for _, group in pairs(self.bomb_groups) do
			if not is_unity_null(group.transform) then
				CS.UnityEngine.GameObject.Destroy(group.transform.gameObject)
			elseif not is_unity_null(group.missile) then
				group.missile:Dispose()
			end
		end
		self.bomb_groups = nil
	end

	self.explosion_effect = nil
	self.warp_effect = nil
	self.explosion_sfx_info = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
