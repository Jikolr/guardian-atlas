local local_class = newclass('TowerNone48TimeBombController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.stage_battle_info = require('stageeventcontrollers/TowerNone48TimeBombData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.AddFieldObjectEvent), 'on_add_field_object_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.manual_range =  CS.AttackRange.CreateCircle(user_party_leader.Position, self.current_stage_info.manual_range_radius)
	self.manual_range:Hide()

	self.grouped_objects = {}
	for _, group in ipairs(self.current_stage_info.target_groups) do
		local holder = {}
		holder.zone = group.event_zone

		holder.monsters = {}
		if group.monsters then
			for idx = 1, #group.monsters do
				local monster = get_character(group.monsters[idx])
				if not is_unity_null(monster) then
					local range = CS.AttackRange.CreateCircle(monster.Position, self.current_stage_info.monster_range_radius)
					range:Hide()
					holder.monsters[monster] = range
				end
			end
		end
		holder.field_objects = {}
		if group.field_objects then
			for idx = 1, #group.field_objects do
				local fo = get_field_object(group.field_objects[idx])
				if not is_unity_null(fo) then
					local range = CS.AttackRange.CreateCircle(fo.Position, self.current_stage_info.field_object_range_radius)
					range:Hide()
					holder.field_objects[fo] = range
				end
			end
		end

		table.insert(self.grouped_objects, holder)
	end

	self.monster_intersect_distance = self.current_stage_info.monster_range_radius + self.current_stage_info.manual_range_radius
	self.object_intersect_distance = self.current_stage_info.field_object_range_radius + self.current_stage_info.manual_range_radius

	self.counter_pool = unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	if self.current_stage_info.explosion_vfx then
		self.explosion_pool = unity_object_pool.GetOrCreate(self.current_stage_info.explosion_vfx)
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

function local_class:on_stage_start(e)
	self.current_progress = self.progress.playing

	-- TODO : 나중에 외전도 맵 입장 UI에 부활불가 띄우고, 게임오버 부활 버튼도 ReviveLimit에 따라 분기되도록 고치는게 좋을 것 같다.
	-- 게임오버 팝업에서 부활 아이콘이 인뜨도록 처리함
	if self.current_stage_info.force_ban_revive then
		stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, false)
	end
end

function local_class:on_game_over_event(e)
	self.current_progress = self.progress.none
end

function local_class:on_zone_enter_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.FieldObject == user_party_leader and e.FullEnter then

		for _, group in ipairs(self.grouped_objects) do
			if group.zone == e.Zone.Name then
				self.current_active_group = group
				break
			end
		end
		if self.current_active_group then
			self:activate_current_group()
		end
		return true
	end
end

function local_class:on_zone_leave_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	if e.FieldObject == user_party_leader and e.FullLeave then
		if self.current_active_group and self.current_active_group.zone == e.Zone.Name then
			self:deactivate_current_group()
			self.current_active_group = nil
		end

		return true
	end
end

function local_class:on_add_field_object_event(e)
	if self.current_progress ~= self.progress.playing or self.current_active_group == nil then return false end

	if self.current_active_group.monsters[e.Target] then
		self.current_active_group.monsters[e.Target]:Show()
	elseif self.current_active_group.field_objects[e.Target] then
		self.current_active_group.monsters[e.Target]:Show()
	end

	return true
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress ~= self.progress.playing or self.current_active_group == nil then return false end

	if self.current_active_group.monsters[e.FieldObject] then
		self.current_active_group.monsters[e.FieldObject]:Hide()
	elseif self.current_active_group.field_objects[e.FieldObject] then
		self.current_active_group.monsters[e.FieldObject]:Hide()
	end

	return true
end

function local_class:activate_current_group()
	if self.current_active_group then
		for monster, range in pairs(self.current_active_group.monsters) do
			if monster.ActiveState == CS.Oak.ActiveState.Enabled and not monster.FieldObjectStatsBehaviour.IsDead then
				attack_range_util.setup_by_position(range, monster.Position, field:GetTileInfoAt(monster.Position):GetHeightAt(monster.Position))
				attack_range_util.show(range)
			end
		end
		for fo, range in pairs(self.current_active_group.field_objects) do
			if fo.ActiveState == CS.Oak.ActiveState.Enabled and not fo.FieldObjectStatsBehaviour.IsDead then
				attack_range_util.setup_by_position(range, fo.Position, field:GetTileInfoAt(fo.Position):GetHeightAt(fo.Position))
				attack_range_util.show(range)
			end
		end

		attack_range_util.setup_by_position(self.manual_range, user_party_leader.Position, field:GetTileInfoAt(user_party_leader.Position):GetHeightAt(user_party_leader.Position))
		attack_range_util.show(self.manual_range)

		self.time_passed = 0
	end
end

function local_class:deactivate_current_group()
	if self.current_active_group then
		for _, range in pairs(self.current_active_group.monsters) do
			range:Hide()
		end
		for _, range in pairs(self.current_active_group.field_objects) do
			range:Hide()
		end

		self.manual_range:Hide()

		self.time_passed = 0
		self:detach_count_ui()
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame_priority(e)
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing or self.current_active_group == nil then return end

	local is_intersecting = false
	attack_range_util.setup_by_position(self.manual_range, user_party_leader.Position, field:GetTileInfoAt(user_party_leader.Position):GetHeightAt(user_party_leader.Position))

	-- 몬스터 거리 체크
	for monster, range in pairs(self.current_active_group.monsters) do
		if monster.ActiveState == CS.Oak.ActiveState.Enabled and not monster.FieldObjectStatsBehaviour.IsDead then
			attack_range_util.setup_by_position(range, monster.Position, field:GetTileInfoAt(monster.Position):GetHeightAt(monster.Position))
			if not is_intersecting then
				local distance = vector_util.get_x0z(monster.Position - user_party_leader.Position).magnitude--battle_util.distance_xz(user_party_leader, monster)
				if distance <= self.monster_intersect_distance then
					is_intersecting = true
				end
			end

		end
	end

	-- 필드 오브젝트 거리 체크
	for fo, range in pairs(self.current_active_group.field_objects) do
		if fo.ActiveState == CS.Oak.ActiveState.Enabled and not fo.FieldObjectStatsBehaviour.IsDead then
			attack_range_util.setup_by_position(range, fo.Position, field:GetTileInfoAt(fo.Position):GetHeightAt(fo.Position))
			if not is_intersecting then
				local distance = vector_util.get_x0z(fo.Position - user_party_leader.Position).magnitude--battle_util.distance_xz(user_party_leader, fo)
				if distance <= self.object_intersect_distance then
					is_intersecting = true
				end
			end
		end
	end

	if is_intersecting then
		if is_unity_null(self.count_ui) then
			self:attach_count_ui(self.current_stage_info.counter_limit)
		end
		self:update_count_ui(self.current_stage_info.counter_limit - math.floor(self.time_passed + 0.5))

		if self.time_passed >= self.current_stage_info.counter_limit then
			-- 시간 오버시 즉사처리
			if self.explosion_pool then
				self.explosion_pool:Instantiate(user_party_leader.Position)
			end
			self:on_hit()
			self.current_progress = self.progress.none
		end

		self.time_passed = self.time_passed + dt
	else
		if not is_unity_null(self.count_ui) then
			self:detach_count_ui()
		end
		self.time_passed = 0
	end
end

function local_class:on_hit()
	local info = CS.Oak.DamageInfo()
	info.type = CS.Oak.DamageType.Death
	info.sender = user_party_leader
	info.target = user_party_leader
	info.damage = CS.Oak.DamageConstants.InstantKillDamage

	local cmd = CS.Oak.DamageCommand.Create(info)
	command_util.publish_cmd(info.Owner, cmd)
end

function local_class:attach_count_ui(count)
	local target = user_party_leader
	local offest = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = self.counter_pool:Instantiate(target.Position + offest, unity_class.quaternion.identity, target.Transform)
	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	self.count_text = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	self.count_text.text = count
	self.count_text.color = unity_class.color.white
end

function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
		self.count_text = nil
	end
end

function local_class:update_count_ui(count)
	if self.count_text then
		self.count_text.text = count
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.AddFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	if not is_unity_null(self.manual_range) then
		CS.UnityEngine.Object.Destroy(self.manual_range)
	end
	self.manual_range = nil

	for _, group in ipairs(self.grouped_objects) do
		for _, range in pairs(group.monsters) do
			if not is_unity_null(range) then
				CS.UnityEngine.Object.Destroy(range)
			end
		end
		for _, range in pairs(group.field_objects) do
			if not is_unity_null(range) then
				CS.UnityEngine.Object.Destroy(range)
			end
		end
	end
	self.grouped_objects = nil

	self.counter_pool = nil
	self.explosion_pool = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
