local local_class = newclass('TowerAdvancedLaserGimmickController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index) return get_field_object('tower_laser_' .. index) end

	-- 레이저 기믹 존
	self.get_laser_loop_zone = function(index) return field:GetZone('laser_zone_' .. index) end

	-- 레이저 기믹의 상태
	-- none : 시작 전 / start : 시작 / next_phase : 다음페이즈로 바꾸는중 / game_over : 게임오버 됬을 때 / finish : 전투가 끝났을 때
	self.gimmick_state = { none = 1, start = 2, next_phase = 3, game_over = 4, finish = 5,  }

	-- 현재 기믹 상태 초기화
	self.current_gimmick_state = self.gimmick_state.none

	-- 현재 레이저 루틴이 돌아가고 있는가?
	self.is_running_laser_gimmick = false

	-- 기믹 루틴 겹치지 않기 위한 방지용
	self.is_active_gimmick_routine = false

	-- 레이저 기믹이 시작되는 존 이름
	self.gimmick_zone_names = { }

	-- 현재 진행중인 존 인덱스
	self.current_zone_index = -1

	-- 현재 존
	self.current_zone = nil

	-- 현재 진행중인 페이즈 인덱스
	self.current_phase_index = -1

	-- 현재 진행중인 페이즈 정보
	self.current_phase = nil

	-- 체스트 박스 터지는 이팩트 이름
	self.explosion_effect_name = 'FX_explosion_small'

	-- 현재 작동 중인 레이저 인덱스
	self.current_laser_index = -1

	-- 스테이지 데이터들
	self.stage_battle_info = require('stageeventcontrollers/TowerAdvancedLaserGimmickData.lua')

	-- 각 존당 쓰이고 있는 레이저 카운트
	self.laser_count_for_each_zones = {}

	-- 현재맵 hp 체크할 보스
	self.boss = nil

	-- 보스 가져오는 함수
	self.get_boss = nil

	--리스폰 딜레이
	self.respawn_delay = 0

	-- 리스폰 대기시간
	self.time_passed = 0

	--데미지타입
	self.damage_type = CS.Oak.DamageType.Melee

	--회전 방향값
	self.direction_value = 1

	--공격범위 표시기
	self.attack_ranges = {}
	for i = 1, 2 do
		local range = CS.AttackRange.CreateRect(vector(0,0,0), unity_class.vector2(0.5, 20))
		range:Hide(0)
		table.insert(self.attack_ranges, range)
	end
	self.current_stage_info = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	--스테이지 정보
	self.current_stage_info = self.stage_battle_info[stage.Name]

	--배틀존 이름 정보
	for i = 1, #self.current_stage_info do
		local name = self.current_stage_info[i].zone_name
		table.insert(self.gimmick_zone_names, name)

		--존당 레이저 몇개씩 쓰는지에 대한 정보
		local laser_count = 0
		for j = 1, #self.current_stage_info[i].phase do
			if laser_count < self.current_stage_info[i].phase[j].gimmick_count * 2 then
				laser_count = self.current_stage_info[i].phase[j].gimmick_count * 2
			end
		end
		table.insert(self.laser_count_for_each_zones, laser_count)
	end

	unity_object_pool.GetOrCreate(self.explosion_effect_name)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_zone_enter_event(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
	local zone_name = e.Zone.Name

	for i = 1, #self.gimmick_zone_names do
		-- 레이저 기믹 존에 도착했으면서 current_gimmick_state가 none(시작 안했을 때)
		if zone_name == self.gimmick_zone_names[i] and self.current_gimmick_state == self.gimmick_state.none
				and self.current_laser_index < i then
			self.current_gimmick_state = self.gimmick_state.start
			self.current_phase_index = 1
			self.current_zone_index = i
			self.is_running_laser_gimmick = true

			self.current_zone = self.current_stage_info[self.current_zone_index]
			self.current_phase = self.current_zone.phase[self.current_phase_index]

			self.respawn_delay = self.current_zone.respawn_delay
			self.get_boss = function() return get_character(self.current_zone.boss_name) end
			self.boss = self.get_boss()

			if self.current_zone.damage_type == 'Melee' then
				self.damage_type = CS.Oak.DamageType.Melee
			elseif self.current_zone.damage_type == 'Projectile' then
				self.damage_type = CS.Oak.DamageType.Projectile
			else
				self.damage_type = CS.Oak.DamageType.Death
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_target_hp, self))
			return true
		end
	end
	return false
end

-- 게임오버 됬을 때 기믹 루프를 꺼준다.
function local_class:on_game_over_event(e)
	-- 레이저 기믹을 더이상 돌지 않게 하고
	-- current_gimmick_state를 game_over로 변경한다.
	self.is_running_laser_gimmick = false
	self.current_gimmick_state = self.gimmick_state.game_over
	return true
end

-- 전투가 끝났을 때 레이저 기믹꺼지도록
function local_class:on_battle_group_eliminated_event(e)
	-- 보스와의 전투가 끝날 때 레이저 기믹을 disabled 해준다.
	if e.BattleGroupName == self.current_zone.zone_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.disabled_chest_box, self, self.current_phase.gimmick_count * 2, self.gimmick_state.finish))
	end
	return true
end

--현재 활성화된 레이저 캐운트 및 다음 전환될 스테이트를 받아옴.
function local_class:disabled_chest_box(count, state)
	-- 이미 끝났으면 로직 타지 않도록
	if self.current_gimmick_state == self.gimmick_state.finish then
		return
	end

	self.is_running_laser_gimmick = false
	local chest_count = count
	self.current_gimmick_state = state

	local chest_1 = self.get_chest_box(self.current_laser_index + 1)
	local chest_2 = self.get_chest_box(self.current_laser_index + 2)
	local chest_3 = nil
	local chest_4 = nil
	if chest_count == 4 then
		chest_3 = self.get_chest_box(self.current_laser_index + 3)
		chest_4 = self.get_chest_box(self.current_laser_index + 4)
	end

	if state == self.gimmick_state.next_phase then
		chest_1.FieldObjectBehaviour:PauseLaserEffect()
		if chest_count == 4 then
			chest_3.FieldObjectBehaviour:PauseLaserEffect()
		end
	elseif state == self.gimmick_state.finish then
		chest_1.FieldObjectBehaviour:DeactiveLaserEffect()
		if chest_count == 4 then
			chest_3.FieldObjectBehaviour:DeactiveLaserEffect()
		end
	end

	music_player_util.play_sfx_one_shot('02_explosion_water_01')
	-- 각 박스 좌표에서 폭발 이팩트 재생
	unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(chest_1.Position)
	unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(chest_2.Position)

	if chest_count == 4 then
		unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(chest_3.Position)
		unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(chest_4.Position)
	end
	-- 0.25초 딜레이 후
	wait_for_sec(0.25)

	--끝나는 경우 일반 종료루틴으로 폭파시키고 disabled 시킴
	if state == self.gimmick_state.finish then
		-- 남은 어택레인지 꺼주기
		for i = 1, #self.attack_ranges do
			self.attack_ranges[i]:Hide(0)
		end

		-- 체스트 박스들 Disabled
		chest_1.ActiveState = active_state('disabled')
		chest_2.ActiveState = active_state('disabled')
		if chest_count == 4 then
			chest_3.ActiveState = active_state('disabled')
			chest_4.ActiveState = active_state('disabled')
		end
		-- 다음페이즈의 경우 paused 시켰다가 일정 시간 이후 다시 gimmick_routine 으로 돌아감.
	elseif state == self.gimmick_state.next_phase then
		chest_1.ActiveState = active_state('infield')
		chest_2.ActiveState = active_state('infield')
		if chest_count == 4 then
			chest_3.ActiveState = active_state('infield')
			chest_4.ActiveState = active_state('infield')
		end

		--다음페이즈의 활성화를 준비
		local rad = unity_class.time.deltaTime * self.direction_value * CS.UnityEngine.Mathf.PI * self.current_phase.speed
		local dir = vector(CS.UnityEngine.Mathf.Cos(rad), 0, CS.UnityEngine.Mathf.Sin(rad))
		local rot = CS.UnityEngine.Quaternion.Euler(0, -45, 0)
		local rotate_dir = rot * dir

		attack_range_util.setup_by_direction(self.attack_ranges[1], self.get_laser_loop_zone(self.current_zone_index).Bounds.center,
				rotate_dir, 0)
		self.attack_ranges[1]:Show(self.respawn_delay)
		message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.boss, self.attack_ranges[1]))

		if self.current_phase.gimmick_count == 2 then
			local rot2 = CS.UnityEngine.Quaternion.Euler(0, 90, 0)
			local rotate_dir2 = rot2 * rotate_dir
			attack_range_util.setup_by_direction(self.attack_ranges[2], self.get_laser_loop_zone(self.current_zone_index).Bounds.center,
					rotate_dir2, 0)
			self.attack_ranges[2]:Show(self.respawn_delay)
			message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.boss, self.attack_ranges[2]))
		end

		wait_for_sec(self.respawn_delay)
		if self.current_gimmick_state == self.gimmick_state.finish then
			return
		end

		self.is_running_laser_gimmick = true
		self.current_gimmick_state = self.gimmick_state.start
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_target_hp, self))
	end
end

function local_class:check_target_hp()
	if self.boss ~= nil then
		-- 페이즈 인댁스 안에서 루프
		while self.is_running_laser_gimmick do
			if self.current_phase_index < #self.current_zone.phase then
				local hp = self.boss.FieldObjectStatsBehaviour.HpRatio * 100
				--현재 hp 퍼센트가 다음페이즈보다 낮으면
				if hp < self.current_zone.phase[self.current_phase_index + 1].remain_hp_percent then
					local current_enabled_chestbox_count = self.current_phase.gimmick_count * 2
					self.current_phase_index = self.current_phase_index + 1
					self.current_phase = self.current_zone.phase[self.current_phase_index]
					--다음페이즈 스테이트로 이동.
					self.current_gimmick_state = self.gimmick_state.next_phase

					self.is_running_laser_gimmick = false
					-- 체스트 박스 pause
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.disabled_chest_box, self, current_enabled_chestbox_count, self.gimmick_state.next_phase))
				end
			else
				break
			end
			coroutine.yield(nil)
		end
	end
end

-- 레이저 기믹 루틴
function local_class:gimmick_routine()
	while self.is_active_gimmick_routine do
		if not self.is_running_laser_gimmick then
			return
		end
		coroutine.yield(nil)
	end

	self.is_active_gimmick_routine = true

	local zone = self.get_laser_loop_zone(self.current_zone_index)

	local lasers = {}
	local room = zone.Bounds
	local room_center = room.center

	self.current_laser_index = 0
	for i = 1, #self.laser_count_for_each_zones do
		--현재 존 이전까지의 레이저 갯수를 파악
		if i < self.current_zone_index then
			self.current_laser_index = self.current_laser_index + self.laser_count_for_each_zones[i]
		end
	end

	--현재 사용된 레이저 인덱스 이후 부터 시작 되어 위치를 잡게 된다.
	local start_index = 1 + self.current_laser_index

	-- 이번페이즈에 사용할 체스트박스를 활성화
	local current_phase_laser_count = self.current_phase.gimmick_count * 2
	room_center.y = 0
	for i = start_index, self.current_laser_index + current_phase_laser_count do
		local laser = self.get_chest_box(i)

		if current_phase_laser_count == 2 then
			if i % current_phase_laser_count == 1 then
				laser.Position = (room_center + vector(room.extents.x, 0, room.extents.z))
				--아래 왼쪽a
			elseif i % current_phase_laser_count == 0 then
				laser.Position = (room_center + vector(-room.extents.x, 0, -room.extents.z))
			end
		elseif current_phase_laser_count == 4 then
			-- 위 오른쪽
			if i % current_phase_laser_count == 3 then
				laser.Position = (room_center + vector(room.extents.x, 0, room.extents.z))
				--아래 왼쪽
			elseif i % current_phase_laser_count == 0 then
				laser.Position = (room_center + vector(-room.extents.x, 0, -room.extents.z))
				--위 왼쪽
			elseif i % current_phase_laser_count == 1 then
				laser.Position = (room_center + vector(-room.extents.x, 0, room.extents.z))
				--아래 오른쪽
			elseif i % current_phase_laser_count == 2 then
				laser.Position = (room_center + vector(room.extents.x, 0, -room.extents.z))
			end
		end
		laser.ActiveState = active_state('enabled')
		laser.FieldObjectBehaviour:PauseLaserEffect()
		table.insert(lasers, laser)
	end

	local change_time = 0
	local time_passed = 0

	lasers[1].FieldObjectBehaviour.DamageRate = self.current_phase.damage
	lasers[1].FieldObjectBehaviour:SetDamageType(self.damage_type)
	lasers[1].FieldObjectBehaviour:ResumeLaserEffect()
	lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true
	self.attack_ranges[1]:Hide(0)
	message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.character, self.attack_ranges[1]))

	if #lasers == 4 then
		lasers[3].FieldObjectBehaviour.DamageRate = self.current_phase.damage
		lasers[3].FieldObjectBehaviour:SetDamageType(self.damage_type)
		lasers[3].FieldObjectBehaviour:ResumeLaserEffect()
		lasers[3].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true
		self.attack_ranges[2]:Hide(0)
		message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.character, self.attack_ranges[2]))
	end

	-- 사운드는 하나만
	local sfx_loop = music_player_util.play_sfx({ sfx_name = '02_light_laser_loop_01', loop = true, type_priority = 'gimmick', player_priority = 'player', fade_in_time = 2 })
	while self.is_running_laser_gimmick do
		-- 레이저 기믹 박스 위치 세팅
		local dt = unity_class.time.deltaTime
		time_passed = time_passed + dt * self.direction_value

		local rad = time_passed * CS.UnityEngine.Mathf.PI * self.current_phase.speed
		local dir = vector(CS.UnityEngine.Mathf.Cos(rad), 0, CS.UnityEngine.Mathf.Sin(rad))
		local rot = CS.UnityEngine.Quaternion.Euler(0, 45, 0)
		local rotate_dir = rot * dir

		local r1 = CS.UnityEngine.Ray(room.center, rotate_dir)
		local r2 = CS.UnityEngine.Ray(room.center, -rotate_dir)

		local dist1 = CS.BoundsExtensions.RayIntersectDistance(room, r1)
		local dist2 = CS.BoundsExtensions.RayIntersectDistance(room, r2)

		-- 레이저 기믹 위치 이동
		lasers[1].Position = room_center + rotate_dir * dist1
		lasers[2].Position = room_center - rotate_dir * dist2

		if #lasers == 4 then

			local rot2 = CS.UnityEngine.Quaternion.Euler(0, 90, 0)
			local rotate_dir2 = rot2 * rotate_dir

			local r3 = CS.UnityEngine.Ray(room.center, rotate_dir2)
			local r4 = CS.UnityEngine.Ray(room.center, -rotate_dir2)

			local dist3 = CS.BoundsExtensions.RayIntersectDistance(room, r3)
			local dist4 = CS.BoundsExtensions.RayIntersectDistance(room, r4)

			lasers[3].Position = room_center + rotate_dir2 * dist3
			lasers[4].Position = room_center - rotate_dir2 * dist4
		end

		-- change_directing_time때 마다 레이저 기믹의 방향이 변경된다.
		change_time = change_time + unity_class.time.deltaTime
		if change_time > self.current_phase.change_directing_time
				and self.current_phase.change_directing_time ~= 0 then
			self.direction_value = self.direction_value * -1
			change_time = 0
		end
		coroutine.yield(nil)
	end
	sfx_loop:Stop()

	-- 레이저 체크 활성화 해제
	lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = false

	if #lasers == 4 then
		lasers[3].FieldObjectBehaviour.IsActiveLaserIntersectCheck = false
	end

	self.is_active_gimmick_routine = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.current_stage_info = nil
	self.stage_battle_info = nil
	self.is_running_laser_gimmick = false

	for i = #self.attack_ranges, 1, -1 do
		if self.attack_ranges[i] ~= nil then
			if not is_unity_null(self.attack_ranges[i]) then
				CS.UnityEngine.Object.Destroy(self.attack_ranges[i])
			end
		end
		table.remove(self.attack_ranges, i)
	end
	self.attack_ranges = nil
	self.cs_controller = nil
	self.get_chest_box = nil
	self.get_laser_loop_zone = nil
	self.gimmick_state = nil
	self.current_gimmick_state = nil
	self.is_active_gimmick_routine = nil
	self.gimmick_zone_names = nil
	self.current_zone_index = nil
	self.current_zone = nil
	self.current_phase_index = nil
	self.current_phase = nil
	self.explosion_effect_name = nil
	self.current_laser_index = nil
	self.laser_count_for_each_zones = nil
	self.boss = nil
	self.get_boss = nil
	self.respawn_delay = nil
	self.time_passed = nil
	self.damage_type = nil
	self.direction_value = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
