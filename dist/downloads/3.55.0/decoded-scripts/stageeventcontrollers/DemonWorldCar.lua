local local_class = newclass("DemonWorldCarController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region Car
	-- 전체 차량 정보를 저장하는 테이블
	self.car_infos = {}

	-- 차량 소리 sfx 리스트
	self.car_sfx_list = nil

	-- 차 이름
	self.car_name = 'spawn_car_'

	-- 차 개수
	self.car_num = nil

	-- 차 이동 속도
	self.car_speed = 4.5

	-- 플레이어와 차 충돌 후 무적 시간
	self.car_collision_immune_duration = 2
--endregion

--region Car Spawn Marker
	-- 차 생성 마커의 정보를 저장하는 테이블
	self.car_spawn_markers = {}

	-- 차 생성 마커 이름
	self.car_spawn_marker_name = 'car_spawn_'

	-- 차 경로 마커 이름
	self.car_waypoint_marker_name = 'car_waypoint_'

	-- 차 경로 마커 개수
	self.car_waypoint_marker_num = nil

	--차 생성 마커에서 다음 차 생성까지 대기하는 최소 시간
	self.car_spawn_delay = 5

	-- 차 회전 대기 시간
	self.car_rotate_duration = 0.3

	-- 차 스폰, 웨이포인트 관련 마커 정보 캐싱
	self.field_car_spawn_markers = {}
	self.field_car_spawn_marker_positions = {}
	self.field_car_waypoint_marker_positions = {}
--endregion

	-- Constants
	self.constants = nil

	-- 플레이어가 차에 연속 충돌하지 않도록 방지하는 플래그
	self.is_player_collided_with_car = false

	-- 스테이지 종료 플래그
	-- (controller가 제거되면 코루틴도 꺼지겠지만,
	-- 문제를 미연에 방지하기 위해 controller Dispose할 때 이 값을 true로 하고 코루틴 중단한다)
	self.is_exit_stage = false

	-- 메인 퀘스트 번호
	self.main_quest_id = 216

	-- 이펙트 프리셋 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.butt_bounce_effect_preset = "FX_slime_buttbounce"

	-- 익스클루시브 스테이트 (연속으로 타지 않도록 하기 위해)
	self.car_logic_state = { changing = 1, hide = 2, show = 3 }

	-- 현재 익스클루시브 스테이트
	self.current_car_logic_state = self.car_logic_state.show

	self.hide_car_exclusive_keys = {
		'adultery',
		'pervert',
		'kid_bully_key',
	}

	-- 전투가 끝나도 차량을 복구시키지 않을 경우
	self.battle_end_pause = false
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.butt_bounce_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')

	self.constants = require('minigame/DemonWorldBasicSystem/DemonWorldCarConstants')

	local constant_data = self.constants[stage.Name]

	if constant_data ~= nil then
		-- 차 개수 등록
		self.car_num = constant_data.car_num

		-- 마커 개수 등록
		self.car_waypoint_marker_num = constant_data.marker_num

		-- 마커 정보 테이블에 등록
		for i = 1, #constant_data.waypoint_data do
			self.car_spawn_markers[i] = {
				spawn_marker_index = i,
				waypoints = constant_data.waypoint_data[i],
				is_used = false
			}
		end
	end

	-- 차 생성 마커 정보가 없을 경우 차 생성 루틴 실행하지 않음
	if self.car_spawn_markers ~= nil and #self.car_spawn_markers > 0 then
		-- 차 정보 테이블에 등록
		for i = 1, self.car_num do
			local cur_car = get_field_object(self.car_name..i)
			cur_car.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

			-- 임시로 차량 크기 변경
			cur_car.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(2.8, 1.0, 1.4))
			cur_car.Transform.localScale = unity_class.vector3.one * 0.75

			self.car_infos[i] = {
				-- 차 오브젝트
				car = cur_car,
				-- 지금 활성화되어서 이동 중인지
				activated = false,
				-- 회전 중인지
				is_rotate = false,
				-- 전투 돌입해서 차 오브젝트를 숨긴 상태인지
				battle_hided = false,
				-- 이동 경로
				waypoints = {},
				-- 이동 경로의 인덱스
				waypoint_index = 1,
				-- 차가 스폰된 마커의 인덱스
				spawn_index = -1
			}
		end

		-- 차 스폰 마커 정보 캐싱
		for j = 1, #self.car_spawn_markers do
			self.field_car_spawn_markers[j] = field:GetMarker(self.car_spawn_marker_name .. j)
			self.field_car_spawn_marker_positions[j] = self.field_car_spawn_markers[j].position
		end

		-- 차 웨이포인트 마커 포지션 캐싱
		for j = 1, self.car_waypoint_marker_num do
			self.field_car_waypoint_marker_positions[j] = field:GetMarker(self.car_waypoint_marker_name .. j).position
		end

		-- 차 스폰 루틴 실행
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_car, self))
	end

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	self.car_infos = nil
	self.car_spawn_markers = nil

	self.field_car_spawn_markers = nil
	self.field_car_spawn_marker_positions = nil
	self.field_car_waypoint_marker_positions = nil

	self.is_exit_stage = true

	if self.car_sfx_list ~= nil then
		for i = 0, self.car_sfx_list.Count - 1 do
			if self.car_sfx_list[i] ~= nil then
				self.car_sfx_list[i]:FadeOut()
			end
		end

		self.car_sfx_list = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_car_sfx, self))
end

function local_class:on_stage_end_event()
	self.is_exit_stage = true
end

function local_class:set_car_sfx()
	self.car_sfx_list = create_generic_list(CS.Oak.AudioSourceHolder)

	for i = 1, #self.car_infos do
		local cur_car = self.car_infos[i].car

		cur_car.Hitbox = CS.Oak.Hitbox(cur_car.Hitbox.size * 0.7)

		self.car_sfx_list:Add(music_player_util.play_sfx(
				{ sfx_name = '01_car_loop_02', loop = true, parent = cur_car, type_priority = 'loop' }))

		wait_for_sec(0.1)
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'pause_car_logic' then
		if self.current_car_logic_state ~= self.car_logic_state.show then
			return false
		end

		-- 전투가 끝나도 차량을 복구하고 싶지 않을 때
		if e:GetParamAt(1) == 'battle_end_pause' then
			self.battle_end_pause = true
		end
		self.current_car_logic_state = self.car_logic_state.changing
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pause_car_logic, self))
	elseif e:GetParamAt(0) == 'resume_car_logic' then
		if self.current_car_logic_state ~= self.car_logic_state.hide then
			return false
		end

		-- 해당 옵션을 원래대로 복구하기 위해서는 battle_end_resume 필요
		if e:GetParamAt(1) == 'battle_end_resume' then
			self.battle_end_pause = false
		elseif self.battle_end_pause then
			return false
		end

		self.current_car_logic_state = self.car_logic_state.changing
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.resume_car_logic, self))
	end
end

function local_class:on_exclusive_quest_start_event(e)
	if self.current_car_logic_state ~= self.car_logic_state.show then
		return false
	end

	if table_util.contain_value(self.hide_car_exclusive_keys, e.Key) then
		self.current_car_logic_state = self.car_logic_state.changing
		self:pause_car_logic()
	end

	return false
end

function local_class:on_exclusive_quest_end_event(e)
	if self.current_car_logic_state ~= self.car_logic_state.hide then
		return false
	end

	if table_util.contain_value(self.hide_car_exclusive_keys, e.Key) then
		self.current_car_logic_state = self.car_logic_state.changing
		self:resume_car_logic()
	end
	return false
end

--region Car Logic Pause
-- 자동차 로직 일시정지 관련
function local_class:pause_car_logic()
	self.current_car_logic_state = self.car_logic_state.hide
end

function local_class:resume_car_logic()
	self.current_car_logic_state = self.car_logic_state.show
end
--endregion

-- 차 스폰 루틴
function local_class:spawn_car()
	while not self.is_exit_stage do
		if self.current_car_logic_state == self.car_logic_state.show then
			-- 차량 순회
			for i = 1, #self.car_infos do
				if self.car_infos[i].activated then
					-- 활성화된 차량은 설정된 경로를 따라 이동한다
					self:set_car_position(self.car_infos[i])

					-- 차 앞을 확인해서 특정 캐릭터와 충돌했는지 확인한다, 전투 중에는 작동하지 않음
					if not self.car_infos[i].battle_hided then
						self:check_collision(self.car_infos[i])
					end
				else
					-- 비활성화된 차량은 현재 사용하지 않는 마커에서 생성시켜준다
					local cur_spawn_marker_index = -1

					for j = 1, #self.car_spawn_markers do
						if not self.car_spawn_markers[j].is_used then
							cur_spawn_marker_index = j

							break
						end
					end

					-- 차량 생성
					if cur_spawn_marker_index > 0 then
						local selected_marker_info = self.car_spawn_markers[cur_spawn_marker_index]
						local cur_spawn_marker = self.field_car_spawn_markers[selected_marker_info.spawn_marker_index]

						local cur_waypoints = selected_marker_info.waypoints[
						math.floor(unity_class.random.Range(1, #selected_marker_info.waypoints))]

						self.car_infos[i].activated = true
						self.car_infos[i].car.Position = cur_spawn_marker.position
						self.car_infos[i].car.Direction = cur_spawn_marker.direction
						self.car_infos[i].spawn_index = cur_spawn_marker_index

						for j = 1, #cur_waypoints do
							if cur_waypoints[j] <= self.car_waypoint_marker_num then
								local cur_index = cur_waypoints[j]
								table.insert(self.car_infos[i].waypoints, self.field_car_waypoint_marker_positions[cur_index])
							else
								local cur_waypoint_index = cur_waypoints[j] - self.car_waypoint_marker_num

								table.insert(self.car_infos[i].waypoints, self.field_car_spawn_marker_positions[cur_waypoint_index])
							end
						end

						selected_marker_info.is_used = true

						-- 차 방향에 맞게 회전시킴
						self:rotate_car_immediate(self.car_infos[i])
					end
				end
			end
		elseif self.current_car_logic_state == self.car_logic_state.hide then
			-- 차가 갑자기 튀어나오는 것을 막기 위해 위치 초기화
			-- 차량 순회
			for i = 1, #self.car_infos do
				if self.car_infos[i].activated then
					self:initialize_car(self.car_infos[i])
					self.car_infos[i].car.Position = vector(999, 0, 999)
				end
			end

			-- 마커 초기화
			for i = 1, #self.car_spawn_markers do
				if self.car_spawn_markers[i].is_used then
					self.car_spawn_markers[i].is_used = false
				end
			end
		end

		coroutine.yield(nil)
	end
end

-- 차 이동 루틴
function local_class:set_car_position(car_info)
	-- 회전 중인 경우는 rotate_car에서 위치 설정함
	if car_info.is_rotate then
		return
	end

	-- 이번 프레임 이동 거리 계산
	local final_pos = car_info.car.Position
	local movement = self.car_speed * unity_class.time.deltaTime

	while movement > 0 and car_info.waypoint_index <= #car_info.waypoints do
		local diff = (car_info.waypoints[car_info.waypoint_index] - final_pos):GetX0z()

		if float_util.is_almost_zero(diff.magnitude) then
			car_info.waypoint_index = self:get_next_waypoint_index(car_info)
		else
			if diff.magnitude < movement then
				movement = movement - diff.magnitude
				final_pos = car_info.waypoints[car_info.waypoint_index]
				car_info.waypoint_index = self:get_next_waypoint_index(car_info)

			else
				final_pos = final_pos + diff.normalized * movement

				break
			end
		end
	end

	-- 방향 설정
	local final_diff = (final_pos - car_info.car.Position):GetX0z()
	local dir = final_diff.normalized:ToDirection()

	if dir == CS.Oak.Direction.None then
		dir = car_info.car.Direction
	else
		local next_angle = self:get_dir_vector(dir).y

		car_info.car.Transform.localRotation =
		unity_class.quaternion.Euler(vector(0, next_angle, 0))

		if next_angle == -90 then
			car_info.car.Transform.localRotation =
			unity_class.quaternion.Euler(vector(0, 270, 0))
		elseif next_angle == 360 then
			car_info.car.Transform.localRotation =
			unity_class.quaternion.Euler(vector(0, 0, 0))
		end
	end

	-- 최종 이동 요청
	if not float_util.is_almost_zero(final_diff.magnitude) then
		car_info.car.Position = final_pos

		-- 남은 거리 확인해서 회전 실행
		if (car_info.car.Position - car_info.waypoints[car_info.waypoint_index]).magnitude / self.car_speed <=
				self.car_rotate_duration / 2 then

			local start_angle = car_info.car.Transform.localRotation.eulerAngles.y

			local next_waypoint_index = self:get_next_waypoint_index(car_info)
			local next_dir = (car_info.waypoints[next_waypoint_index] - car_info.waypoints[car_info.waypoint_index]):ToDirection()

			local next_angle = self:get_dir_vector(next_dir).y

			-- 0 -> 270, 270 -> 0 예외 처리
			if start_angle == 0 and next_angle == 270 then
				next_angle = -90
			elseif start_angle == 270 and next_angle == 0 then
				next_angle = 360
			end

			if start_angle ~= next_angle then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.rotate_car, self, car_info, start_angle,
						next_angle - (start_angle % 360), self.car_rotate_duration))
			end
		end
	end
end

-- car_info의 파라미터 초기화 함수
function local_class:initialize_car(car_info)
	car_info.activated = false
	car_info.waypoints = {}
	car_info.waypoint_index = 1
	car_info.spawn_index = -1
end

-- 차 앞을 체크해서 다른 오브젝트와 충돌했는지 확인
function local_class:check_collision(car_info)
	local collided_objs = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(car_info.car.Bounds, unity_class.vector3.zero)

	-- 충돌한 물체 순회하며 처리
	if collided_objs ~= nil and collided_objs.Count - 1 then
		for i = 0, collided_objs.Count - 1 do
			local fo = collided_objs[i]
			-- 충돌체가 플레이어일 경우
			if lua_helper.reference_equals(fo, user_party.Leader) then
				-- 이미 충돌 중이거나, 플레이어가 ScreenplayState가 아니거나 사망 상태가 아니면, 플레이어 에어스핀 루틴 실행
				if not self.is_player_collided_with_car and
						not lua_helper.type_compare(
								user_party.Leader.FieldObjectController.CurrentState,
								CS.Oak.CharacterControllerScreenplayState) and
						not user_party.Leader.FieldObjectStatsBehaviour.IsDead then
					coroutine_manager:StartCoroutine(
							stage.StageGameObject, util.cs_generator(self.player_air_spin, self, car_info.car))
				end
			-- 충돌체가 일반 NPC(EntityGroup으로 체크함), 적인 경우
			elseif fo.EntityGroup == CS.Oak.EntityGroups.Player1 or fo.EntityGroup == CS.Oak.EntityGroups.Monster then
				-- 사망 상태면 무시
				if not fo.FieldObjectStatsBehaviour.IsDead then
					-- 최대 체력 이상의 데미지를 줌
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.Trap
					damage_info.sender = car_info.car
					damage_info.target = fo
					damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * 10)

					command_util.execute_damage(damage_info)
				end
			end
		end
	end

	collided_objs:Dispose()
end

-- 차 회전 연출
function local_class:rotate_car(car_info, start_angle, rotate_angle, duration)
	car_info.is_rotate = true

	local timer = 0

	-- 커브 이동 처리
	local car_pos_start = car_info.car.Transform.localPosition
	local car_pos_middle = car_info.waypoints[car_info.waypoint_index]

	local next_waypoint_index = self:get_next_waypoint_index(car_info)
	local next_dir = (car_info.waypoints[next_waypoint_index] - car_pos_middle).normalized
	local car_pos_end = car_pos_middle + (next_dir * self.car_speed * self.car_rotate_duration / 2)

	local calculator = CS.Oak.BezierCurveCalculator()
	local curve_type = CS.Oak.BezierCurveType.Quadratic

	local spline_list = create_generic_list(unity_class.vector3)
	spline_list:Add(car_pos_start)
	spline_list:Add(car_pos_middle)
	spline_list:Add(car_pos_end)

	calculator:Add(spline_list, duration, curve_type)

	local is_update_waypoint_index = false

	while timer < duration and car_info.activated do
		if self.is_exit_stage then
			return
		end

		timer = timer + unity_class.time.deltaTime

		local cur_angle = start_angle + rotate_angle * (math.min(1 - (duration - timer) / duration, 1))

		car_info.car.Transform.localRotation = unity_class.quaternion.Euler(vector(0, cur_angle, 0))

		-- 커브 이동 처리
		calculator:UpdateFrame(unity_class.time.deltaTime)
		local cur_pos = calculator.CurrentPosition
		car_info.car.Position = cur_pos

		if not is_update_waypoint_index and timer >= duration / 2 then
			is_update_waypoint_index = true

			car_info.waypoint_index = self:get_next_waypoint_index(car_info)
		end

		coroutine.yield(nil)
	end

	car_info.is_rotate = false

	-- 회전중에 activated가 false가 됐다면 종료함.
	if not car_info.activated then
		return
	end

	car_info.car.Transform.localRotation =
		unity_class.quaternion.Euler(vector(0, start_angle + rotate_angle, 0))
	car_info.car.Position = car_pos_end

	-- 회전 값 복구
	if start_angle + rotate_angle == -90 then
		car_info.car.Transform.localRotation =
			unity_class.quaternion.Euler(vector(0, 270, 0))
	elseif start_angle + rotate_angle == 360 then
		car_info.car.Transform.localRotation =
			unity_class.quaternion.Euler(vector(0, 0, 0))
	end
end

-- 차 즉시 회전
function local_class:rotate_car_immediate(car_info)
	car_info.car.Transform.localRotation = unity_class.quaternion.Euler(self:get_dir_vector(car_info.car.Direction))
end

-- 방향을 회전 벡터로 리턴해줌
function local_class:get_dir_vector(dir)
	if dir == CS.Oak.Direction.Up then
		return unity_class.vector3(0, 90, 0)
	elseif dir == CS.Oak.Direction.Down then
		return unity_class.vector3(0, 270, 0)
	elseif dir == CS.Oak.Direction.Left then
		return unity_class.vector3(0, 0, 0)
	elseif dir == CS.Oak.Direction.Right then
		return unity_class.vector3(0, 180, 0)
	end

	return unity_class.vector3(0, 0, 0)
end

-- 플레이어 에어 스핀 루틴
function local_class:player_air_spin(car)
	self.is_player_collided_with_car = true

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	music_player_util.play_sfx_one_shot('01_fall_down_01')
	music_player_util.play_sfx_one_shot('03_runaway_01')
	music_player_util.play_sfx(
			{ sfx_name = '02_car_damaged_01', volume = 1.5, type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.25, 0.5)

	unity_object_pool.GetOrCreate(
			self.hit_effect_preset):Instantiate(user_party.Leader.Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(
			self.impact_hit_effect_preset):Instantiate(user_party.Leader.Position + vector(0, 0.3, 0))

	local cur_time = unity_class.time.time
	local fall_time = 1.5
	local free_fall = CS.CalculatorFreeFall(15, 20, 0, 0)

	local start_pos_list = create_generic_list(unity_class.vector3)
	for i = 0, user_party.Count - 1 do
		start_pos_list:Add(user_party[i].Position)

		character_util.spine_rotate(user_party[i], 360, fall_time)
		character_util.spine_damage_squish_default(user_party[i])
		character_util.spine_damage_red_pulse(user_party[i])
		character_util.set_direction(user_party[i], CS.Oak.DirectionExtensions.GetSideDirection(user_party[i].Direction))
		character_util.set_anim(user_party[i], { name = 'embarrassed' })
		character_util.set_emotion(user_party[i], { name = 'damaged' })

		-- 체력 비례 데미지를 줌, 이 데미지로는 죽지 않음
		-- 최대 체력 이상의 데미지를 줌
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Trap
		damage_info.sender = car
		damage_info.target = user_party[i]
		damage_info.damage = math.floor(user_party[i].FieldObjectStatsBehaviour.MaxHP * 0.3)
		damage_info.notMortal = true

		command_util.execute_damage(damage_info)
	end

	while (unity_class.time.time - cur_time < fall_time) do
		free_fall:Proceed(unity_class.time.deltaTime)
		local dist_y = free_fall:GetDistance()

		for i = 0, user_party.Count - 1 do
			character_util.set_position(
					user_party[i], start_pos_list[i] + vector(0, dist_y, 0), true)
		end

		coroutine.yield(nil)
	end

	music_player_util.play_sfx_one_shot('03_mech_stomp_01')

	camera_util.shake(0.4, 0.5)

	unity_object_pool.GetOrCreate(self.butt_bounce_effect_preset):Instantiate(user_party.Leader.Position)

	for i = 0, user_party.Count - 1 do
		character_util.spine_rotate(user_party[i], 0, 0)
		character_util.set_position(user_party[i], start_pos_list[i])
		character_util.set_anim(user_party[i], { name = 'prostrate' })
	end

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_rustle_01')

	for i = 0, user_party.Count - 1 do
		character_util.shake(user_party[i], 0.04, 1)
	end

	wait_for_sec(1)

	music_player_util.play_sfx({sfx_name = '01_player_popup_01'})

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim_and_emotion(user_party[i])
		character_util.mario_jump_new(user_party[i], user_party[i].Direction)
	end

	wait_for_sec(0.5)

	field_ui_manager:Show()
	party_util.reset_controllers()

	-- 무적 시간 대기
	local immune_duration = 1

	wait_for_sec(immune_duration)

	self.is_player_collided_with_car = false
end

function local_class:get_next_waypoint_index(car_info)
	local max_index = #car_info.waypoints
	local now_index = car_info.waypoint_index
	local next_index = (now_index % max_index) + 1

	return next_index
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
