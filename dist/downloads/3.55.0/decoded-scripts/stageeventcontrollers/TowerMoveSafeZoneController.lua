local local_class = newclass('TowerMoveSafeZoneController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
	}
	local stage_name = stage.Name
	self.stage_data = require('stageeventcontrollers/TowerMoveSafeZoneData.lua')

	self.current_progress = self.progress.none

	self.current_stage_info = self.stage_data[stage_name]

	self.count_down = self.current_stage_info.count_down
	self.range_radius = self.current_stage_info.radius

	--세이프존 움직이는 랠리포인트
	self.rally_point_names = self.current_stage_info.safe_zone_rally_markers

	self.rally_points = {}
	for i = 1, #self.rally_point_names do
		local name = self.rally_point_names[i]
		local obj = field:GetMarker(name)
		table.insert(self.rally_points, obj)
	end

	--원 크기 재지정 포인트
	self.resize_points = {}

	for i = 1, #self.current_stage_info.safe_zone_change_markers do
		local marker = self.current_stage_info.safe_zone_change_markers[i]
		table.insert(self.resize_points, {
			marker = field:GetMarker(marker.name),
			radius = marker.radius,
			duration = marker.duration,
			is_done = false
		})
	end


	self.current_position_index = 1
	self.current_position = self.rally_points[self.current_position_index].position

	--안전지대 레인지
	self.range_light_color = CS.UnityEngine.Color32(53, 70, 255, 76)
	self.range_dark_color = CS.UnityEngine.Color32(53, 70, 255, 153)

	self.safe_zone = CS.AttackRange.CreateCircle(self.current_position, self.range_radius,
	self.range_light_color, self.range_dark_color)
	self.safe_zone:Hide(0)

	self.time_passed = 0
	self.is_end_zone_complete = false
	self.is_safe_zone = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	return
end

function local_class:on_stage_start_event(e)
	local key = lua_helper.get_or_default(self.current_stage_info.narration_info, nil)
	if key == nil then return end

	sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.current_stage_info.narration_info })
end

function local_class:on_zone_enter_event(e)
	if self.current_progress == self.progress.none then
		if e.Zone.Name == self.current_stage_info.start_zone_name and e.FieldObject == user_party_leader and e.FullEnter then
			self.is_end_zone_complete = false
			self.current_progress = self.progress.playing
			self.is_safe_zone = true
			self:start_count_down()
			coroutine_manager:StartCoroutine(self.safe_zone, util.cs_generator(self.show_safe_zone, self))
			coroutine_manager:StartCoroutine(self.safe_zone, util.cs_generator(self.check_safe_zone_routine, self))
			coroutine_manager:StartCoroutine(self.safe_zone, util.cs_generator(self.resize_safe_zone, self))
		end
	end

end

function local_class:on_zone_leave_event(e)
	if self.current_progress == self.progress.playing then
		if e.Zone.Name == self.current_stage_info.end_zone_name and e.FieldObject == user_party_leader and e.FullLeave and self.is_end_zone_complete then
			self.current_progress = self.progress.cleared
			self:detach_count_ui()
			self.safe_zone:Hide(0)
		end
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.current_stage_info.end_zone_name then
		self.is_end_zone_complete = true
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:check_safe_zone_routine()
	while self.current_progress == self.progress.playing do
		local checked = self:is_in_safe_zone()
		if self.is_safe_zone ~= checked then
			self.is_safe_zone = checked
			if checked then
				if self.count_ui ~= nil then
					self.count_ui.gameObject:SetActive(false)
				end
			else
				if self.count_ui ~= nil then
					self.count_ui.gameObject:SetActive(true)
				end
				coroutine_manager:StartCoroutine(self.safe_zone, util.cs_generator(self.count_down_timer, self))
			end
		end
		coroutine.yield(nil)
	end
end
function local_class:resize_safe_zone()
	if self.current_progress == self.progress.playing then
		while true do
			for i = 1, #self.resize_points do
				local marker = self.resize_points[i]
				if marker ~= nil and marker.is_done == false then
					local resize_destination = vector_util.get_x0z(marker.marker.position, 0)
					local cur_pos = vector_util.get_x0z(self.current_position, 0)
					local dist = vector_util.distance(resize_destination, cur_pos)
					if dist < 0.09 then
						self.safe_zone:ResizeCircle(marker.radius, marker.duration)
						marker.is_done = true
					end
				end
			end
			self.range_radius = self.safe_zone.Radius
			coroutine.yield(nil)
		end
	end
end
function local_class:show_safe_zone()
	self.safe_zone:Show(0)
	while true do
		local dt = unity_class.time.deltaTime
		if self.current_progress == self.progress.playing then
			-- 여기서 타겟 포지션에서 이동..
			-- 이동속도
			local movement = dt * self.current_stage_info.speed
			local next_destination = self.rally_points[self.current_position_index + 1]
			local diff = vector_util.get_x0z(next_destination.position - self.current_position, 0)
			local direction = vector_util.normalized(diff)
			local next_position = direction * movement

			if vector_util.magnitude(diff) < 0.09 then
				--목적지 도달
				self.current_position_index = self.current_position_index + 1
				attack_range_util.setup_by_position(self.safe_zone, next_destination.position, 0)
				--마지막 랠리포인트라면
				if self.current_position_index >= #self.rally_points then
					break
				end
			else
				self.current_position = self.current_position + next_position
				attack_range_util.setup_by_position(self.safe_zone, self.current_position, 0)
			end
			coroutine.yield(nil)
		else
			break
		end
	end
end

function local_class:start_count_down()
	self:attach_count_ui(user_party.Leader, 0)
	coroutine_manager:StartCoroutine(self.safe_zone, util.cs_generator(self.count_down_timer, self))
end

function local_class:count_down_timer()
	self.passed_time = 0

	while self.current_progress == self.progress.playing do
		if not self.is_safe_zone then
			self:update_count_ui(self.count_down - math.floor(self.passed_time + 0.5))

			if self.passed_time >= self.count_down then
				--safezone 체크
				self:check_safe_zone()
				self.passed_time = 0
			end

			self.passed_time = self.passed_time + unity_class.time.deltaTime
			coroutine.yield(nil)
		else
			break
		end
	end
end

function local_class:is_in_safe_zone()
	local distance = vector_util.get_x0z(self.current_position - user_party_leader.Position).magnitude
	if distance > self.range_radius then
		return false
	else
		return true
	end
end

function local_class:check_safe_zone()
	if not self:is_in_safe_zone() then
		--안전지대 밖이라면 즉사 데미지를 입는다.

		--모든 버프를 지운다.
		for i = 0, user_party.Count - 1 do
			buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party.Leader)
		end

		coroutine.yield(nil)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party_leader
		damage_info.target = user_party_leader
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)

		self.current_progress = self.progress.none
	end
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
	tmp.color = unity_class.color.red
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

-- 카운트 UI 해제
function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

    -- 이 기믹에 달려있는 코루틴 종료
    -- 시점 차이을 없에기 위해 직접 종료함수 호출
	coroutine_manager:StopCoroutinesOf(self.safe_zone);

	self.range_light_color = nil
	self.range_dark_color = nil

	self.resize_points = nil
	self.rally_points = nil
	self.rally_point_names = nil
	self.current_stage_info = nil
	self.stage_data = nil
	self.is_end_zone_complete = nil
	if not is_unity_null(self.safe_zone) then
		CS.UnityEngine.Object.Destroy(self.safe_zone)
	end

	self.safe_zone = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
