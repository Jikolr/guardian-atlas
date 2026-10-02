local local_class = newclass('TowerConstantRecoveryController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	--- 0 ~ 2
	self.current_hp_level = 0
	self.stage_battle_info = require('stageeventcontrollers/TowerConstantRecoveryData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none
	-- monster spawn effect
	self.spawn_effect_name = "FX_Obj_Box_spawner"
	self.spawn_effect_name2 = "FX_dead"

	self.narration_key = 'tower_light_boss_7_narration'

	self.hide_position = vector(999, 0, 999)
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- stage info
	self.current_stage_info = self.stage_battle_info[stage.Name]
	-- 보스
	self.target_boss = get_character(self.current_stage_info.boss_name)

	self.show_range = self.current_stage_info.show_range
	-- 어택레인지 저장
	self.attack_ranges = {}
	-- 어택레인지 색상 커스텀
	local range_light_color = CS.UnityEngine.Color32(53, 70, 255, 76)
	local range_dark_color = CS.UnityEngine.Color32(53, 70, 255, 153)

	self.pending_robots = {}
	self.active_robots = {}
	-- 로봇 캐릭터 초기화
	if not is_unity_null(self.target_boss) then
		for _, value in ipairs(self.current_stage_info.recovery_robots) do
			local robot = get_character(value)
			robot.ActiveState = CS.Oak.ActiveState.Disabled
			robot.Position = self.hide_position
			table.insert(self.pending_robots, robot)

			if self.show_range then
				local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero,
						self.current_stage_info.recovery_range, range_light_color, range_dark_color)
				attack_range:Hide()
				-- 테이블에 할당
				table.insert(self.attack_ranges, attack_range)
			end
		end
	end

	-- 리스폰용 마커 지정
	self.respawn_marker = {}
	for i = 1, #self.current_stage_info.respawn_point do
		local marker = field:GetMarker(self.current_stage_info.marker_name..i)
		table.insert(self.respawn_marker, marker)
	end

	-- 웨이포인트용 마커 지정
	self.waypoint_marker = {}
	for i = 1, 12 do
		local marker = field:GetMarker(self.current_stage_info.marker_name..i)
		table.insert(self.waypoint_marker, marker)
	end

	-- 로봇과 보스가 곂칠때 츨어줄 이펙트
	self.explosion_pool = unity_object_pool.GetOrCreate('FX_reset_object')

	self.time_passed = 0
	self.cool_down_time = 0
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

-- 나레이션 출력
function local_class:on_stage_start_event(e)
	-- 나레이션 출력
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.narration_key })
end

-- 보스 존에 들어갔을때부터 플레이 시작
function local_class:on_zone_enter_event(e)
	if self.current_progress == self.progress.none then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.current_progress = self.progress.playing
		end
		return true
	end

	return false
end

-- 보스 사망시 동작 종료
function local_class:on_field_object_destroyed_event(e)
	if self.current_progress == self.progress.playing then
		if lua_helper.reference_equals(e.FieldObject, self.target_boss) then
			self.current_progress = self.progress.cleared
			self:remove_active_robots()
			return true
		else
			-- 만약 사망한것이 로봇중의 하나라면
			for i = #self.active_robots, 1, -1 do
				if lua_helper.reference_equals(e.FieldObject, self.active_robots[i].fo) then
					local robot_data = table.remove(self.active_robots, i)
					if self.show_range then
						robot_data.attack_range:Hide(0)
					end
					ui_quest_marker:RemoveQuestMarker(robot_data.fo.Name)
					-- 펜딩으로 상태 변경
					table.insert(self.pending_robots, robot_data.fo)
				end
			end
			return false
		end
	end

	return false
end

-- 게임 오버 된 경우에도 종료
function local_class:on_game_over_event(e)
	if self.current_progress == self.progress.playing then
		self.current_progress = self.progress.none
		self:remove_active_robots()
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
	--- 플레이중 아니면 업데이트 하지 않음.
	if self.current_progress ~= self.progress.playing then return end

	self.time_passed = self.time_passed + dt

	-- 살아있는 로봇이 있다면 업데이트 하지 않음?
	if #self.active_robots > 0 then
		-- 웨이포인트 따라서 이동 하도록 함.
		self:update_robot_moves(dt)
		-- 보스가 범위내에 들어왔는지 체크
		self:is_inside_range()
	else
		self.cool_down_time = self.cool_down_time + dt
		-- 쿨타임 재서 리스폰 시켜줌
		if self.current_stage_info.cool_down_time <= self.cool_down_time then
			-- 체력 조건 체크
			local hp_rate = self.target_boss.FieldObjectStatsBehaviour.HpRatio
			if hp_rate <= self.current_stage_info.level_1hp and hp_rate > self.current_stage_info.level_2hp then
				-- summon 1 robot
				self:summon_robot(1)
			elseif hp_rate <= self.current_stage_info.level_2hp and hp_rate > self.current_stage_info.level_3hp then
				-- summon 2 robot
				self:summon_robot(2)
			else
				-- summon 3 robot
				self:summon_robot(3)
			end
		end
	end
end

-- 다음 타겟하는 마커로 이동 처리
-- 여기서부터 작업 재개
function local_class:update_robot_moves(dt)
	for i = #self.active_robots, 1, -1 do
		local robot_data = self.active_robots[i]
		-- 시작 지점에 따른 웨이포인트 정보
		local waypoints = self.current_stage_info.waypoints[robot_data.start_point]
		-- 웨이포인트 번호 정보에서 실제 타겟되는 마커 숫자를 가져옴
		local next_point = waypoints[robot_data.current_point + 1]
		-- 다음 마커
		local next_marker = self.waypoint_marker[next_point]
		local move_info = CS.Oak.MoveOneFrameInfo()
		local current_position = robot_data.fo.Position
		-- 다음 포인트로의 이동 방향
		local dir = vector_util.get_x0z(next_marker.position - current_position)
		if self.show_range then
			-- 공격 범위 이동
			attack_range_util.setup_by_position(robot_data.attack_range, current_position, current_position.y)
		end
		move_info.direction = vector_util.normalized(dir)
		-- 이동 속도
		move_info.magnitude = vector_util.magnitude(vector_util.normalized(dir)) * self.current_stage_info.move_speed * dt
		-- 주어진 방향으로의 이동
		local move_event = CS.Oak.AtomicMoveEvent.Create(move_info, vector_util.to_direction(move_info.direction), false)
		message_system:SendSync(robot_data.fo, move_event)

		local dist = vector_util.distance(robot_data.fo.Position, next_marker.position)
		-- 다음거리와 충분히 가까워 졌다면
		if dist <= move_info.magnitude then
			-- 다음 위치로
			robot_data.current_point = robot_data.current_point + 1
		end

		if robot_data.current_point >= #waypoints then
			-- 마지막 위치까지 진행 되었으므로 삭제
			self:kill_robot(i)
		end
	end
end

function local_class:kill_robot(index)
	local robot_data = table.remove(self.active_robots, index)
	local robot = robot_data.fo
	robot.DamagedBehaviour.ShowDamageNumber = false
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Death
	damage_info.sender = robot
	damage_info.target = robot
	damage_info.damage = robot.FieldObjectStatsBehaviour.MaxHP * 10
	--tower_light_55
	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	--- 커맨드 발행
	command_util.publish_cmd(damage_info.Owner, cmd)
	robot.DamagedBehaviour.ShowDamageNumber = true
	-- 퀘스트 마커 삭제
	ui_quest_marker:RemoveQuestMarker(robot.Name)
	-- 공격범위 삭제
	if self.show_range then
		robot_data.attack_range:Hide(0)
	end
	-- active -> pending 으로 전환
	table.insert(self.pending_robots, robot)
end

-- 보스가 범위내에 들어왔는지 ?
function local_class:is_inside_range()
	local target_pos = self.target_boss.Position
	for i = #self.active_robots, 1, -1 do
		local robot = self.active_robots[i].fo
		local robot_pos = robot.Position
		local dist = vector_util.distance(robot_pos, target_pos)
		if dist < self.current_stage_info.recovery_range then
			self:heal_boss(i)
		end
	end
end

-- 보스를 치유하고 해당 로봇은 사망처리
function local_class:heal_boss(index)
	local heal_info = CS.Oak.HealInfo()
	heal_info.type = CS.Oak.HealType.Normal
	heal_info.sender = self.target_boss
	heal_info.target = self.target_boss
	-- 최대 체력 대비 회복량
	heal_info.heal = math.floor(self.target_boss.CharacterStatsBehaviour.MaxHP * self.current_stage_info.recovery_amount)
	local cmd = CS.Oak.HealCommand.Create(heal_info)
	command_util.publish_cmd(heal_info.Owner, cmd)
	-- 로봇이 할일을 다 했으므로 사망처리
	self:kill_robot(index)
end

-- 리스폰 포인트중 가장 가까운 한군데 제외한 나머지 중에 카운트 조건에 맞춰서 리스폰 시킴
function local_class:summon_robot(count)
	self.cool_down_time = 0
	local target_pos = self.target_boss.Position
	local closet_point = 0
	local max_dist = 999
	local candidate = {}

	-- 제일 가까운 포인트가 어느곳인지 찾음
	for i = 1, #self.respawn_marker do
		local dist = vector_util.distance(target_pos, self.respawn_marker[i].position)
		if dist <= max_dist then
			-- 가까운 포인트 갱신
			closet_point = i
		end
	end

	-- 제일 가까운 마커를 제외한 나머지 후보군 추림
	for i = 1, #self.respawn_marker do
		if i ~= closet_point then
			table.insert(candidate, i)
		end
	end

	-- 후보군 리스트에서 지정된 갯수만큼 뽑아서
	local pick_values = random_util.get_values_in_array(candidate, { count = count })

	for i = #pick_values, 1, -1 do
		-- pick_values 는 이미 랜덤하게 뽑혀져 나온 값이므로
		local robot = table.remove(self.pending_robots, i)
		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.sender = self.target_boss
		heal_info.target = robot
		heal_info.heal = robot.FieldObjectStatsBehaviour.MaxHP
		heal_info.isRevive = true
		local cmd = CS.Oak.HealCommand.Create(heal_info)
		command_util.publish_cmd(heal_info.Owner, cmd)

		-- 위치 이동
		robot.Position = self.respawn_marker[pick_values[i]].position

		-- 웨이포인트 돌아다니도록 설정
		--robot.FieldObjectController = CS.Oak.MonsterCharacterController('boss', CS.Oak.PatrolAI.Waypoints, waypoints)
		robot.FieldObjectController.DontFight = true
		robot.FieldObjectController.PatrolSight = 0
		robot.FieldObjectController.PatrolAngle = 0
		-- 상태 변경
		robot.ActiveState = CS.Oak.ActiveState.Enabled
		local attack_range_index = 0
		-- 로봇 컨트롤러 크래시비헤비어 변경.
		robot.CrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance
		local state = CS.Oak.CharacterAnalogueState.Create(robot)
		local state_change_event = CS.Oak.StateChangeEvent.Create(state)
		-- 힐 커맨드에서 발행된 idle state 로의 변경이 send 라, sendsync 하면 이쪽이 먼저 도착하여 최종적으로 idle 이 되므로 send 로 변경
		message_system:Send(robot.CharacterBehaviour, state_change_event)
		-- 로봇에 퀘스트 마커 추가
		ui_quest_marker:AddQuestMarkerToIFO(robot.Name, i, false, robot)

		if self.show_range then
			if robot.Name == 'recovery_robot_1' then
				attack_range_index = 1
			elseif robot.Name == 'recovery_robot_2' then
				attack_range_index = 2
			else
				attack_range_index = 3
			end
			local range = self.attack_ranges[attack_range_index]
			attack_range_util.setup_by_position(range, robot.Position, robot.Position.y)
			range:Show(0)

			-- 실행중인 로봇 리스트에 집어넣음, 시작한 위치도 같이 (웨이포인트 지정용), 현재 위치도 같이
			table.insert(self.active_robots, {
				fo = robot,
				start_point = pick_values[i],
				-- 각 로봇당 공격범위 할당 하여 보여주도록 한다.
				attack_range = range,
				current_point = 1
			})
		else
			-- 범위 표시기 없는 경우
			table.insert(self.active_robots, {
				fo = robot,
				start_point = pick_values[i],
				current_point = 1
			})
		end

	end

	self.cool_down_time = 0
end

function local_class:get_waypoints(index)
	local waypoint_marker = {}
	-- 인덱스로 웨이포인트 넘버 가져옴
	local waypoints = self.current_stage_info.waypoints[index]
	-- 웨이포인트 번호 정보에서 실제 타겟되는 마커 숫자를 가져옴
	for i = 1, #waypoints do
		-- 웨이포인트 배열에서 실제로 가야할 마커 위치를 가져옴
		local next_point = waypoints[i]
		-- 정의된 마커 리스트에서 해당 위치에 대한 마커 정보를 가져옴
		local next_marker = self.waypoint_marker[next_point]
		table.insert(waypoint_marker, next_marker.position)
	end
	--- 순서대로 정렬된 웨이포인트 마커 리턴
	return waypoint_marker
end

function local_class:instantiate_effect(pool, position,  multiplier)
	if not is_unity_null(pool) then
		local pooled_object = pool:Instantiate(position)
		pooled_object.transform.localScale = pooled_object.transform.localScale * multiplier
		return pooled_object
	end
	return nil
end

function local_class:remove_active_robots()
	-- 활성화된 모든 로봇들 제거
	for idx = #self.active_robots, 1, -1 do
		local robot_data = table.remove(self.active_robots, idx)
		local robot = robot_data.fo
		robot.DamagedBehaviour.ShowDamageNumber = false
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = robot
		damage_info.target = robot
		damage_info.damage = robot.FieldObjectStatsBehaviour.MaxHP * 10
		--tower_light_55
		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		--- 커맨드 발행
		command_util.publish_cmd(damage_info.Owner, cmd)
		robot.DamagedBehaviour.ShowDamageNumber = true
		-- 공격범위 삭제
		if self.show_range then
			robot_data.attack_range:Hide(0)
		end
		ui_quest_marker:RemoveQuestMarker(robot.Name)
		-- active -> pending 으로 전환
		table.insert(self.pending_robots, robot)
	end
	-- 테이블 초기화
	self.active_robots = { }
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

	self.active_robots = nil
	self.pending_robots = nil

	self.explosion_pool = nil

	self.stage_battle_info = nil
	self.current_stage_info = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
