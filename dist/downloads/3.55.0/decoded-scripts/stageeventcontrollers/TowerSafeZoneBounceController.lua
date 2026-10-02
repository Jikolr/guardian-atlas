local local_class = newclass('TowerSafeZoneBounceController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		stop = 3,
		cleared = 4,
	}
	local stage_name = stage.Name
	self.stage_data = require('stageeventcontrollers/TowerSafeZoneBounceData.lua')

	-- 현재 플레이 상태
	self.current_progress = self.progress.none
	-- 현재 스테이지 정보
	self.current_stage_info = self.stage_data[stage_name]
	-- 맵 전역에서 쓰이는 카운팅 정보
	self.count_down = self.current_stage_info.count_down
	-- 현재 스테이지 내 이벤트존 이름
	self.battle_zone_names = self.current_stage_info.battle_zone_names
	-- 클리어한 존 이름
	self.cleared_zone_names = {}
	--안전지대 레인지 색상
	self.range_light_color = CS.UnityEngine.Color32(53, 70, 255, 76)
	self.range_dark_color = CS.UnityEngine.Color32(53, 70, 255, 153)
	-- 전체적으로 안전지역에 대해 설정된 테이블, 범위표시기 및 동작 정보
	self.safe_zones_info = {}
	-- 카운트다운 타이머 체크용
	self.count_down_time_passed = 0
	-- 안전 지역 들어왔는지 값
	self.is_safe_zone = false

	-- 변경이 되지 않아야 할 데이터라 하드코딩 --
	-- 속도 변경 최대 / 최소값
	self.max_speed = 21
	self.min_speed = 0.5
	-- 사이즈 변경 최소값, 사이즈 늘어나는 일 없을거라 최소값만 있음.
	self.min_radius = 0.0001 -- 최소값 0 이면 exception 발생하니까 작은 수로 둠.
	--끝 --
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 머리위 타이머용 ui 미리 로드
	self.count_ui_pool = unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	-- 현재 스테이지 상의 배틀존을 전부 검사해서 테이블 정보 생성해둠.
	for i = 1, #self.battle_zone_names do
		-- 정보 넣을 테이블
		local make_info = {}
		-- 배틀존 이름으로 데이터 파싱
		local battle_zone_name = self.battle_zone_names[i]
		-- 배틀존내 정보
		local info = self.current_stage_info[battle_zone_name]
		-- 배틀존에 포함된 안전지역 정보 로 실제 사용될 테이블 생성
		for j = 1, #info.safe_zones do
			-- hack : 바로 만들지 않고 캐싱 후 사이즈 조정하여 사용 되므로,
			-- 테두리에 차이가 발생하여 사용 가능한 최대크기로 만들어 작은 사이즈로 resizing 하여 사용하도록 함.
			local safe_zone = CS.AttackRange.CreateCircle(unity_class.vector3.zero, 10, self.range_light_color, self.range_dark_color)
			-- 일단 숨김 처리
			safe_zone:Hide(0)

			-- 테이블에 range 와 해당 range 에 대한 정보를 포함
			table.insert(make_info, {
				zone = safe_zone, -- 범위표시기
				info = info.safe_zones[j], -- 정보
				direction = unity_class.vector3.zero, -- 진행방향
				speed = info.safe_zones[j].speed, -- 변경된 이동 속도 저장용
				active = false -- 활성화 상태
			})
		end
		-- 전체 리스트는 배틀존 이름을 키로 해서 안전지역 정보를 포함.
		self.safe_zones_info[battle_zone_name] = make_info
	end

	-- 기본 어택레인지는 4개 만들어두고 돌려 쓰도록 한다. ResizeCircle 로 사이즈 조정 가능함.
	self.basic_attack_ranges = {}
	for i = 1, 4 do
		-- hack : 위와 동일한 이슈
		local range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, 10, self.range_light_color, self.range_dark_color)
		range:Hide(0)
		-- 레인지 저장
		table.insert(self.basic_attack_ranges, { zone = range, active = false })
	end
	-- 활성화된 이동하는 범위
	self.active_move_ranges = {}
	return
end

-- 나레이션 출력
function local_class:on_stage_start_event(e)
	local key = lua_helper.get_or_default(self.current_stage_info.narration_info, nil)
	if key == nil then return end

	sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.current_stage_info.narration_info })
end

-- 이벤트 존에 들어왔을때부터 동작하기 시작함.
function local_class:on_zone_enter_event(e)
	if self.current_progress ~= self.progress.playing then
		-- 파티리더가 완전히 들어왔을때
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			-- 이미 클리어된 존이라면 동작 하지 않음.
			for i = 1, #self.cleared_zone_names do
				if e.Zone.Name == self.cleared_zone_names[i] then
					return
				end
			end

			-- 현재 스테이지의 존 이름 중에 내가 들어온 존이 포함되어있다면 시작함.
			for i = #self.battle_zone_names, 1, -1  do
				if e.Zone.Name == self.battle_zone_names[i] then
					-- 타겟으로 하는 배틀존에 들어옴
					self.current_progress = self.progress.playing
					-- 지정된 배틀존에서 이름 빼서 현재 존에 할당 하고 이후 버림.
					self.current_zone_name = self.battle_zone_names[i]
					-- 카운트 다운 시작
					-- 여기부터 다시 작업 재개
					self:start_count_down()
					-- 들어온 배틀존에 있는 범위의 활성화
					self:start_battle_zone()
				end
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	if self.current_progress == self.progress.playing then
		if e.Zone.Name == self.current_zone_name and lua_helper.reference_equals(e.FieldObject, user_party_leader)
				and e.FullLeave then
			-- 동작 중지
			self.current_progress = self.progress.stop
			self:detach_count_ui()
			-- 현재 배틀존에 대한 안전지역 테이블에서 동작중인 지역을 숨김 처리
			local safe_zones = self.safe_zones_info[self.current_zone_name]
			for i = 1, #safe_zones do
				-- 세이프존 숨김 처리
				safe_zones[i].zone:Hide(0)
			end

			-- 기본 안전지대 업데이트
			for i = 1, #self.basic_attack_ranges do
				local zone_data = self.basic_attack_ranges[i]
				-- 존이 활성화 되어있으면 하이딩
				if zone_data.active then
					zone_data.zone:Hide(0)
					zone_data.active = false
				end
			end

			-- 현재 존 이름 비움 : 한번 지나온 구역이 다시 동작하지 않도록
			table.insert(self.cleared_zone_names, self.current_zone_name)
			self.current_zone_name = ''
		end
	end
end

function local_class:need_on_launch()
	return false
end

-- 업데이트 프레임 사용
function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame_priority(e)
	return CS.Oak.UpdatePriorities.StageEvent
end

-- 업데이트 프레임
function local_class:late_update_frame(dt)
	-- 플레이중이 아니라면 업데이트 돌지 않음
	if self.current_progress ~= self.progress.playing then return end

	-- 안전지역 이동 업데이트
	self:update_battle_zone(dt)
	-- 플레이어가 안전지역에 들어가 있는지 판단
	self:check_safe_zone()
	-- 카운트 다운 타이머 동작
	self:count_down_timer(dt)
end

function local_class:get_current_zone_bound(position)
	-- 현재 배틀존 이름으로 존 검색
	local zone = field:GetZone(self.current_zone_name)
	if zone ~= nil and zone:Contains(position) then
		return zone.Bounds
	end

	-- 위에서 이름으로 존 찾지 못했다면 위치로 재검색
	local zone_list = field:GetZoneListFor(position)
	local candidate = nil
	for _, v in pairs(zone_list) do
		if v:Contains(user.Position) and v:GetType() == typeof(CS.Oak.Zone) then
			candidate = v
			break
		end
	end
	zone_list:Dispose()

	return candidate.Bounds
end

function local_class:start_battle_zone()
	self.zone_bound = self:get_current_zone_bound(user_party_leader.Position)
	-- 해당 배틀존에 설정된 안전지역 설정
	for i = 1, #self.safe_zones_info[self.current_zone_name] do
		-- 배틀존 zones[i] = {zone, info, active}
		local zone = self.safe_zones_info[self.current_zone_name][i]
		local start_marker = field:GetMarker(zone.info.start_marker)
		-- 시작 위치 지정
		attack_range_util.setup_by_position(zone.zone, start_marker.position, 1)
		-- 진행방향
		zone.direction = unity_class.quaternion.AngleAxis(zone.info.angle, unity_class.vector3.up) * unity_class.vector3.forward
		-- 시작 크기로 리사이징
		zone.zone:ResizeCircle(zone.info.radius, 0)
		-- 보여주기
		zone.zone:Show(0)
		zone.active = true
	end

	-- 파티원들에게 안전지역 설정
	local basic_zone_data = self.current_stage_info[self.current_zone_name].party_safe_zone_radius
	for i = 1, #basic_zone_data do
		local radius = basic_zone_data[i]
		-- 범위가 0 이상일 경우에만 세팅 하도록 함.
		if radius > 0 and user_party[i-1] ~= nil and not user_party[i-1].FieldObjectStatsBehaviour.IsDead then
			-- 어택레인지 사이즈 재설정
			attack_range_util.setup_by_position(self.basic_attack_ranges[i].zone, user_party[i - 1].Position, 1)
			self.basic_attack_ranges[i].zone:ResizeCircle(radius, 0)
			self.basic_attack_ranges[i].zone:Show(0)
			self.basic_attack_ranges[i].active = true
		end
	end
end

-- 배틀존 진행시 업데이트 되어야 할 내용
function local_class:update_battle_zone(dt)
	for i = 1, #self.safe_zones_info[self.current_zone_name] do
		local zone_data = self.safe_zones_info[self.current_zone_name][i]
		local current_position = zone_data.zone.CacheTransform.position
		-- 다음 위치
		local next_position = current_position + (zone_data.direction * zone_data.speed * dt)

		-- 다음 위치가 현재 배틀존을 빠져나가는 경우
		if not CS.BoundsExtensions.ContainCircle(self.zone_bound, next_position, zone_data.zone.Radius) then
			-- 상하좌우 검사해서 방향 / 각도 변경 여기부터 재개
			local up_position = next_position + unity_class.vector3.forward * zone_data.zone.Radius
			local down_position = next_position + unity_class.vector3.back * zone_data.zone.Radius
			local right_position = next_position + unity_class.vector3.right * zone_data.zone.Radius
			local left_position = next_position + unity_class.vector3.left * zone_data.zone.Radius
			-- 존 위치에서 범위만큼 떨어진 상하좌우가 배틀존 밖으로 벗어나있다면 해당 점이 부딛힌것.

			-- 위와 부딛힌건지
			local is_up = not self.zone_bound:Contains(up_position)
			-- 아래와 부딛힌건지
			local is_down = not self.zone_bound:Contains(down_position)
			-- 오른쪽이 부딛힌건지
			local is_right = not self.zone_bound:Contains(right_position)
			-- 왼쪽이 부딛힌건지
			local is_left = not self.zone_bound:Contains(left_position)

			-- 입사각과 노말 방향으로 반사된 벡터를 구한다.
			if is_up or is_down or is_right or is_left then
				-- 바운스 후 범위 계산
				self.target_radius = zone_data.zone.Radius + zone_data.info.radius_per_bounce
				-- 줄어들기만 할거라 최소 사이즈 제한만 체크
				if self.target_radius < self.min_radius then
					self.target_radius = self.min_radius
				end

				zone_data.zone:ResizeCircle(self.target_radius, zone_data.info.duration)
				-- 바운스 후 속도 계산
				zone_data.speed = zone_data.speed + zone_data.info.speed_per_bounce
				-- 최대, 최소 제한
				if zone_data.speed > self.max_speed then
					zone_data.speed = self.max_speed
				elseif zone_data.speed < self.min_speed then
					zone_data.speed = self.min_speed
				end

				-- 네군데중 부딛힌 곳 있는지 확인
				if is_up then
					zone_data.direction = unity_class.vector3.Reflect(zone_data.direction, unity_class.vector3.back)
				elseif is_down then
					zone_data.direction = unity_class.vector3.Reflect(zone_data.direction, unity_class.vector3.forward)
				elseif is_right then
					zone_data.direction = unity_class.vector3.Reflect(zone_data.direction, unity_class.vector3.left)
				elseif is_left then
					zone_data.direction = unity_class.vector3.Reflect(zone_data.direction, unity_class.vector3.right)
				end
			end

			-- 노말라이즈
			zone_data.direction = vector_util.normalized(zone_data.direction)
		end

		--- y 축 고정해두면 됨.SetupByPosition에서 y 축에 값 보정해주기 때문에..
		attack_range_util.setup_by_position(zone_data.zone, next_position, 1)
	end

	-- 기본 안전지대 업데이트
	for i = 1, #self.basic_attack_ranges do
		local zone_data = self.basic_attack_ranges[i]
		-- 존이 활성화 되어있고, 파티원이 생존해 있는 상황이면 위치 업데이트
		if zone_data.active then
			if user_party[i-1] ~= nil and not user_party[i-1].FieldObjectStatsBehaviour.IsDead then
				attack_range_util.setup_by_position(zone_data.zone, user_party[i - 1].Position, 1)
			else
				-- 파티원이 없는데 액티브 되어있거나, 파티원 사망했는데 액티브 되어있다면
				zone_data.zone:Hide(0)
				-- 비활성화
				zone_data.active = false
			end
		end
	end
end

function local_class:check_safe_zone()
	-- 안전지역 안에 있는지 판단.
	local checked = self:is_in_safe_zone()
	if self.is_safe_zone ~= checked then
		self.is_safe_zone = checked
		if checked then
			if self.count_ui ~= nil then
				-- 안전지역 다시 들어왔을때 카운트 다운 타임 초기화
				self.count_down_time_passed = 0
				self.count_ui.gameObject:SetActive(false)
			end
		else
			if self.count_ui ~= nil then
				self.count_ui.gameObject:SetActive(true)
			end
		end
	end

end

-- 파티 리더에게 카운트 다운 ui 세팅
function local_class:start_count_down()
	-- 카운트 다운 수치 초기화
	self.count_down = self.current_stage_info.count_down
	self.count_down_time_passed = 0
	self:attach_count_ui(user_party_leader, self.count_down)
end

function local_class:count_down_timer(dt)
	-- 안전지역에 들어가 있지 않은 경우에
	if not self.is_safe_zone then
		self:update_count_ui(self.count_down - math.floor(self.count_down_time_passed + 0.5))

		if self.count_down_time_passed >= self.count_down then
			-- 카운트 다운 시간 만큼 지났다면 데미지를 보냄
			self:apply_damage()
			--safezone 체크
			self.count_down_time_passed = 0
		end

		self.count_down_time_passed = self.count_down_time_passed + dt
	end

end

function local_class:is_in_safe_zone()
	-- 움직이는 안전지역에서 찾음
	for i = 1, #self.safe_zones_info[self.current_zone_name] do
		local zone_data = self.safe_zones_info[self.current_zone_name][i]
		if zone_data.active then
			local zone_position = zone_data.zone.CacheTransform.position
			local distance = vector_util.distance(vector_util.get_x0z(zone_position), vector_util.get_x0z(user_party_leader.Position))
			if distance <= zone_data.zone.Radius then -- 데이터가 아니라 실제 존 사이즈 가지고 체크 하도록 수정
				return true
			end
		end
	end

	-- 해당사항 없으면 일반(파티원 고정) 범위에서도 다시 찾음
	for i = 1, #self.basic_attack_ranges do
		local zone_data = self.basic_attack_ranges[i]
		if zone_data.active then
			local zone_position = zone_data.zone.CacheTransform.position
			local distance = vector_util.distance(vector_util.get_x0z(zone_position), vector_util.get_x0z(user_party_leader.Position))
			if distance <= zone_data.zone.Radius then
				return true
			end
		end
	end

	-- 못찾았으면 안전지역 안이 아님
	return false
end

function local_class:apply_damage()
	if not self.is_safe_zone then
		--안전지대 밖이라면 즉사 데미지를 입는다.
		--모든 버프를 지운다.
--[[		for i = 0, user_party.Count - 1 do
			buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party_leader)
		end]]

		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party_leader
		damage_info.target = user_party_leader
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)

		self:detach_count_ui()
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
	--message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.range_light_color = nil
	self.range_dark_color = nil

	self.resize_points = nil
	self.rally_points = nil
	self.rally_point_names = nil
	self.current_stage_info = nil
	self.stage_data = nil
	self.is_end_zone_complete = nil

	for i = #self.basic_attack_ranges, 1, -1 do
		local range = table.remove(self.basic_attack_ranges, i)
		if not is_unity_null(range.zone) then
			CS.UnityEngine.Object.Destroy(range.zone)
		end
	end
	self.basic_attack_ranges = nil

	for _, v in pairs(self.safe_zones_info) do
		for i, zone in pairs(v) do
			if not is_unity_null(zone.zone) then
				CS.UnityEngine.Object.Destroy(zone.zone)
			end
		end
	end
	self.safe_zones_info = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
