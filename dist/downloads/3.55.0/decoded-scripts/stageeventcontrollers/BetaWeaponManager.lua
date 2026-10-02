local local_class = newclass("BetaWeaponManagerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 현재 선택중인 베타 웨폰 인덱스
	self.select_index = 1

	-- 선택중이지 않은 베타 웨폰 인덱스
	self.un_select_index = 2

	-- 베타 웨폰이 루프를 순회 중인가?
	self.is_start_looping_beta_weapon = false

	-- 베타 웨폰 캐릭터 이름 베이스
	self.beta_weapon_name = 'beta_weapon_'

	-- 어택 레인지 렌더러
	self.attack_range_renderer = nil

	-- 배틀 그룹 이름
	self.battle_group_name = 'beta_weapon'

	-- 이벤트 존, 그리드 이름
	self.event_grid_name = 'beta_weapon_grid'

	self.event_zone_name = 'beta_weapon_zone'

	-- 감시 방향
	self.directions = { 'left', 'down', 'right', 'up' }

	-- 감시 인덱스
	self.current_looping_index = 1

	-- 베타 웨폰 존 밖에 있는지?
	self.is_leave_beta_weapon_zone = true

	-- 감시 거리
	self.sight_distance = 5

	-- 감시 각도
	self.sight_angle = 70

	-- 그리드 안에 있는가?
	self.in_grid = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self.is_start_looping_beta_weapon = false
	self.directions = nil

	if self.attack_range_renderer ~= nil then
		self.attack_range_renderer:Dispose()
		self.attack_range_renderer = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		self:on_item_get_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DoorOpenedEvent) then
		self:on_door_opened_event(e)
	end
	return false
end

function local_class:on_custom_stage_event(e)
	local param = e:GetParamAt(0)

	-- 베타 웨폰 루핑 추가 기능 및 약한 베타 웨폰으로 변경 함수 호출
	if param == 'start_loop_weak' or param == 'start_loop' then
		self.is_start_looping_beta_weapon = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.beta_weapon_area_looping, self, param == 'start_loop_weak'))
	elseif param == 'weak_battle_weapon' then
		self:change_weak_beta_weapon()
	end
end

function local_class:on_damage_event(e)
	-- 베타 웨폰이 영역을 돌아다니고 있는지?
	if not self.is_start_looping_beta_weapon then
		return false
	end

	-- 베타 웨폰 존 밖에 있는지?
	if self.is_leave_beta_weapon_zone then
		return false
	end

	-- 베타 웨폰을 공격할 경우 바로 전투
	local current_beta_weapon = get_character(self.beta_weapon_name .. self.select_index)
	if lua_helper.reference_equals(e.Info.target, current_beta_weapon) and lua_helper.reference_equals(e.Info.sender, user_party_leader) then
		self:battle_start_beta_weapon(current_beta_weapon)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if not self.is_start_looping_beta_weapon then
		return false
	end

	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	local zone_name = e.Zone.Name
	if zone_name == self.event_zone_name then
		local is_beta_weapon_dead = false
		for i = 1, 2 do
			local beta_weapon = get_character(self.beta_weapon_name .. i)
			if beta_weapon.FieldObjectStatsBehaviour.IsDead then
				is_beta_weapon_dead = true
				break
			end

			beta_weapon.FieldObjectController.DontFight = false
			beta_weapon.OverrideCrashBehaviour = nil
			beta_weapon.DamagedBehaviour = i == 2 and CS.Oak.NoneAttackableDamagedBehaviour.Instance or CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.SmallExplosion)
		end

		if is_beta_weapon_dead then
			return false
		end

		self.is_leave_beta_weapon_zone = false
		if self.attack_range_renderer ~= nil then
			self.attack_range_renderer.AttackRange:Show(0)
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not self.is_start_looping_beta_weapon then
		return false
	end

	if not e.FullLeave or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
	local zone_name = e.Zone.Name
	if zone_name == self.event_zone_name then
		local is_beta_weapon_dead = false
		for i = 1, 2 do
			local beta_weapon = get_character(self.beta_weapon_name .. i)
			if beta_weapon.FieldObjectStatsBehaviour.IsDead then
				is_beta_weapon_dead = true
				break
			end

			beta_weapon.FieldObjectController.DontFight = true
			beta_weapon.OverrideCrashBehaviour = CS.Oak.NullCrashBehaviour.Instance
			beta_weapon.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		end

		if is_beta_weapon_dead then
			return false
		end

		self.is_leave_beta_weapon_zone = true
		if self.attack_range_renderer ~= nil then
			self.attack_range_renderer.AttackRange:Hide()
		end
	end
end

function local_class:on_camera_grid_enter_event(e)
	if not self.is_start_looping_beta_weapon then
		return false
	end

	-- 카메라 그리드 안으로 들어왔을 때 걸어가는 애니메이션 연출
	if type_util.is_player_enter_to_cam_grid(e, self.event_grid_name) then
		self.in_grid = true
		local beta_weapon = get_character(self.beta_weapon_name .. self.select_index)
		if beta_weapon ~= nil and not beta_weapon.FieldObjectStatsBehaviour.IsDead then
			character_util.set_anim(beta_weapon, { name = 'walk', sfx_name = '01_walk_robot_01', loop = true })
		end
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if not self.is_start_looping_beta_weapon then
		return false
	end

	-- 카메라 그리드 밖으로 나갔을 때 베타 애니메이션 false 및 이동하지 않도록
	if type_util.is_player_leave_to_cam_grid(e, self.event_grid_name) then
		self.in_grid = false
		local beta_weapon = get_character(self.beta_weapon_name .. self.select_index)
		if beta_weapon ~= nil and not beta_weapon.FieldObjectStatsBehaviour.IsDead then
			character_util.remove_anim(beta_weapon)
		end
		return true
	end

	return false
end

-- 베타 웨폰이 일정 영역을 순회하며 체크한다.
function local_class:beta_weapon_area_looping(is_weak)
	-- 베타 웨폰 세팅
	local beta_weapons = {}
	for i = 1, 2 do
		local beta_weapon = get_character(self.beta_weapon_name .. i)
		stage.BattleManager:AddToNoAssassination(beta_weapon)
		beta_weapon:SetLockedDirection(beta_weapon, CS.Oak.LockDirectionRequest.Create(CS.Oak.Direction.Down, 11))
		beta_weapon.OverrideCrashBehaviour = CS.Oak.NullCrashBehaviour.Instance
		beta_weapon.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		beta_weapon.FieldObjectController.DontFight = true
		table.insert(beta_weapons, beta_weapon)
	end

	self.select_index = is_weak and 1 or 2
	self.un_select_index = self.select_index == 1 and 2 or 1

	if is_weak then
		self:change_battle_group(beta_weapons[self.select_index], beta_weapons[self.un_select_index])
	end

	-- 베타 웨폰 enable
	character_util.set_active_state(beta_weapons[self.select_index], 'enabled')
	character_util.set_position(beta_weapons[self.select_index], vector(16.25, 0, 88.5))

	-- 어택 레인지 체크 함수
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.update_attack_range, self, beta_weapons))

	local area_size_x = 11.6
	local area_size_y = 10.2

	local speed = 3
	self.current_looping_index = 1

	while self.is_start_looping_beta_weapon do
		if self.in_grid then
			local pos
			if self.current_looping_index % 2 == 0 then
				pos = vector(0, 0, area_size_y * (self.current_looping_index < 3 and -1 or 1))
			else
				pos = vector(area_size_x * (self.current_looping_index < 2 and -1 or 1), 0, 0)
			end

			character_util.set_direction(beta_weapons[self.un_select_index], self.directions[self.current_looping_index])

			local time_passed = 0
			local target_pos = beta_weapons[self.select_index].Position + pos
			local start_pos = beta_weapons[self.select_index].Position
			local final_duration = (target_pos - start_pos).magnitude / speed
			while self.is_start_looping_beta_weapon do
				time_passed = time_passed + unity_class.time.deltaTime
				if time_passed >= final_duration then
					break
				end

				beta_weapons[self.select_index].Position = unity_class.vector3.Lerp(start_pos, target_pos, time_passed / final_duration)
				coroutine.yield(nil)
			end

			self.current_looping_index = self.current_looping_index + 1
			if self.current_looping_index > 4 then self.current_looping_index = 1 end
		end
		coroutine.yield(nil)
	end
end

-- 어택 레인지 표시 및 확인 영역에 들어왔는지 체크 하는 함수
function local_class:update_attack_range(beta_weapons)
	-- 어택 레인지 UI 세팅
	self:set_attack_range(beta_weapons[self.select_index])

	while self.is_start_looping_beta_weapon do
		if self.in_grid then
			local is_sight = self:is_in_sight(beta_weapons[self.select_index], beta_weapons[self.un_select_index])
			if is_sight then
				-- 리더가 CharacterControllerScreenplayState가 아닐 때만 전투로 들어간다.
				if not lua_helper.type_compare(user_party_leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
					self:battle_start_beta_weapon(beta_weapons[self.select_index])
				end
			end

			if self.attack_range_renderer ~= nil then
				self.attack_range_renderer:Update(beta_weapons[self.un_select_index])
			end
		end
		coroutine.yield(nil)
	end

	self.attack_range_renderer:Dispose()
	self.attack_range_renderer = nil
end

function local_class:is_in_sight(patrol, direction_patrol)
	-- 존에 없다면 확인해볼 필요가 없음
	if self.is_leave_beta_weapon_zone then
		return false
	end

	-- 순찰자가 죽었으면 돌 필요 없다.
	if patrol.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	-- 거리가 멀면 확인할 필요가 없다.
	local full_diff = user_party_leader.Bounds.center - patrol.Bounds.center;
	local diff = user_party_leader.Bounds.center - patrol.Bounds.center;
	if diff.magnitude > 5 then
		return false
	end

	diff.y = 0
	diff:Normalize()

	-- 시야각 안에 없다면 돌필요 없음.
	if unity_class.vector3.Angle(diff, direction_util.to_vector3(direction_patrol.Direction)) > 60 / 2.0 then
		return false
	end

	-- 앞에 장애물이 있다면 찾지 못함
	if field:IsAnythingBlocking(CS.UnityEngine.Bounds(patrol.Bounds.center, vector(0.05, 0.05, 0.05)), CS.Oak.EntityGroups.Obstacle, vector_util.get_x0z(full_diff)) then
		return false
	end

	return true
end
function local_class:battle_start_beta_weapon(beta_weapon)
	self.is_start_looping_beta_weapon = false

	character_util.remove_anim(beta_weapon)
	beta_weapon.OverrideCrashBehaviour = CS.Oak.PassChargeCrashBehaviour(false, false, false)
	character_util.convert_to_monster(beta_weapon, 'beta_weapon')
	command_util.execute_monster_notice(beta_weapon, user_party_leader, 'battle')
end

-- 베타 웨폰 약한 객체로 변경
function local_class:change_weak_beta_weapon()
	self.select_index = 1
	self.un_select_index = 2

	local weak_beta_weapon = get_character('beta_weapon_1')
	local beta_weapon = get_character('beta_weapon_2')

	-- 강한 베타 웨폰이 죽었을 때에는 하지 않는다.
	if beta_weapon.FieldObjectStatsBehaviour.IsDead then
		return
	end

	-- 약한 베타 웨폰을 기존 베타 웨폰 자리로 이동
	character_util.set_position(weak_beta_weapon, beta_weapon.Position)
	character_util.set_direction(weak_beta_weapon, 'down')
	character_util.set_active_state(weak_beta_weapon, 'enabled')

	-- 강한 베타 웨폰을 기존 베타 웨폰 자리로 이동
	if self.current_looping_index > 4 then self.current_looping_index = 1 end
	character_util.set_position(beta_weapon, vector(999, 0, 999))
	character_util.set_direction(beta_weapon, self.directions[self.current_looping_index])
	character_util.set_active_state(beta_weapon, 'disabled')
	character_util.remove_anim(beta_weapon)

	-- 어택 레인지 재설정
	self:set_attack_range(weak_beta_weapon)

	-- 강한 베타 웨폰을 배틀 그룹에서 제거한다
	self:change_battle_group(weak_beta_weapon, beta_weapon)
end

function local_class:set_attack_range(target)
	if self.attack_range_renderer ~= nil then
		self.attack_range_renderer:Dispose()
	end
	self.attack_range_renderer = CS.Oak.GhostGuardAttackRangeRenderer(target, self.sight_distance, self.sight_angle)
end

function local_class:change_battle_group(target, un_select_target)
	local target_battle_group = stage.BattleManager:GetBattleGroup(self.battle_group_name)

	target_battle_group:Remove(un_select_target)
	un_select_target.CharacterBehaviour:CancelAllBattleActions(true)
	un_select_target.FieldObjectController.DontFight = true

	target_battle_group:Add(target, 0)
	target.FieldObjectStatsBehaviour.NoticeLinkName = self.battle_group_name
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
