local local_class = newclass('QueenShipAMMIController')

local ammi_state_base = newclass('AMMIState')

local ammi_wait_state = newclass('AMMIWaitState', ammi_state_base)
local ammi_appear_state = newclass('AMMIAppearState', ammi_state_base)
local ammi_chasing_state = newclass('AMMIChasingState', ammi_state_base)
local ammi_retreat_state = newclass('AMMIRetreatState', ammi_state_base)
local ammi_qte_attack_state = newclass('AMMIQTEAttackState', ammi_state_base)
local ammi_groggy_state = newclass('AMMIGroggyState', ammi_state_base)
local ammi_screenplay_state = newclass('AMMIScreenPlayState', ammi_state_base)
local ammi_dead_state = newclass('AMMIDeadState', ammi_state_base)

local champion_ammi_chasing_state = newclass('ChampionAMMIChasingState', ammi_state_base)
local champion_ammi_laser_attack_state = newclass('ChampionAMMILaserAttackState', ammi_state_base)

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.ammi = nil

	-- ammi state 풀
	self.ammi_state_pool = nil

	-- ammi 스테이트
	self.ammi_state = nil

	-- 공격 범위
	self.attack_range = nil

	-- emp 스위치 활성화 여부
	self.activate_emp_switch = false

	-- ammi 생존 여부
	self.alive_ammi = true

	-- ammi 활성화 여부
	self.activate_ammi = true

	-- 필드 틴트 활성화 여부
	self.activate_field_tint = false

	-- 줌아웃 상태인지
	self.is_camera_zoom_out = false

	-- ammi 스테이지 음악이 나오고 있는지
	self.is_playing_ammi_bgm = false

	-- qte로 한번 붙잡힌 것을 피할 수 있는지
	self.qte_chance = true

	-- path find 종료 여부
	self.path_find_done = true

	-- ammi state 고유번호. 오버플로우는 거의 불가능하기 때문에 따로 방어 처리하지 않음
	self.ammi_state_id = 0

	-- ammi 데이터
	self.constants_data = nil

	-- 추격존에 포함되어 있는 ifo 목록
	self.chasing_zone_contains_ifo_list = nil

	-- 등장존에 포함되어 있는 ifo 목록
	self.appear_zone_contains_ifo_list = nil

	-- emp존에 포함되어 있는 ifo
	self.emp_zone_contains_ifo = nil

	-- emp존 loop sfx
	self.emp_sfx = nil

	-- queeship 스테이지 데이터 키
	self.custom_keys = nil

	-- 추격존에 있는 exit를 인터랙트했는지
	self.interact_exit_in_chasing_zone = false

	-- emp 필드 이펙트
	self.emp_field_effect = nil

	-- 리셋 마커
	self.reset_marker = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:ammi_pre_setting()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self:stop_field_tint()

	self.alive_ammi = false

	self.custom_keys = nil
	self.constants_data = nil
	self.chasing_zone_contains_ifo_list = nil
	self.appear_zone_contains_ifo_list = nil
	self.emp_zone_contains_ifo = nil

	if self.ammi_state then
		self.ammi_state:exit()
		self.ammi_state = nil
	end

	if self.ammi_state_pool ~= nil then
		for _,state in pairs(self.ammi_state_pool) do
			state:dispose()
			state = nil
		end
		self.ammi_state_pool = nil
	end

	if self.attack_range ~= nil then
		CS.UnityEngine.Object.Destroy(self.attack_range)
		self.attack_range = nil
	end

	if self.emp_field_effect ~= nil then
		self.emp_field_effect:Dispose()
		self.emp_field_effect = nil
	end

	if self.emp_sfx ~= nil then
		self.emp_sfx:Stop()
		self.emp_sfx = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_switch_on_off_event(e)
	local emp_switch = get_field_object(self.constants_data.emp_switch)

	-- emp 존 활성화
	if emp_switch ~= nil and lua_helper.reference_equals(e.SwitchObject, emp_switch) and e.IsTurningOn then
		start_coroutine(self.activate_emp_zone, self)
		return true
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'activate_ammi' then
		self.activate_ammi = true
	elseif e:GetParamAt(0) == 'deactivate_ammi' then
		self.activate_ammi = false
	end
	return false
end

-- 쫒기는 도중에 exit에 인터랙트 했는 경우 타이밍 이슈 방어용
function local_class:on_exit_interact_teleport_start_event(e)
	if not self.alive_ammi then return end

	if self:is_player_contains_chasing_zone() then
		start_coroutine(self.wait_exit_teleport_done, self)
	end
	return false
end

function local_class:wait_exit_teleport_done()
	self.interact_exit_in_chasing_zone = true
	while self:is_player_contains_chasing_zone() do
		coroutine.yield()
	end
	self.interact_exit_in_chasing_zone = false
end

-- emp존 활성화 이벤트r
function local_class:activate_emp_zone()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	wait_for_sec(0.5)

	local emp_pos = field:GetMarker(self.constants_data.emp_pos).position
	local camera_speed = 6
	local distance = unity_class.vector3.Distance(user_party.Leader.Position, emp_pos)
	local duration = distance/camera_speed

	camera_util.move_async(emp_pos, duration)

	local emp_unit = get_field_object(self.constants_data.emp_unit)
	local emp_unit_animator = emp_unit:GetComponent(typeof(CS.UnityEngine.Animator))

	emp_unit_animator:Play('on')
	music_player_util.play_sfx_one_shot('02_emp_03')
	wait_for_sec(0.583)
	emp_unit_animator:Play('on_idle')

	self.emp_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_sun_02', type_priority = 'event', play_pos = emp_pos, loop = true })
	self.emp_field_effect = unity_object_pool.GetOrCreate(
			self.constants_data.effect.emp_field):Instantiate(emp_pos)
	self.emp_field_effect.transform.localScale = unity_class.vector3.one * self.constants_data.emp_effect_scale
	wait_for_sec(2)

	camera_util.return_to_leader(duration)

	self.activate_emp_switch = true

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- ammi 사전 세팅
function local_class:ammi_pre_setting()
	-- ammi 파괴 여부 체크해서 비활성화
	self.custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants').common
	if stage_progress_util.get_custom_data_int(self.custom_keys.ammi_dead, 0) == 1 then
		self.alive_ammi = false
		return
	end

	-- 데이터 가져오기
	local constants_key = stage.Name
	self.constants_data = require('eventcontrollers/QueenShipAMMIConstants')[constants_key]

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')

	if self.constants_data then
		message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')

		-- 이펙트 생성
		for _,effect in pairs(self.constants_data.effect) do
			unity_object_pool.GetOrCreate(effect)
		end

		-- 추격존에 포함된 ifo 해시셋 가져옴
		self.chasing_zone_contains_ifo_list = {}
		for i = 1, #self.constants_data.chasing_zone do
			local zone = field:GetZone(self.constants_data.chasing_zone[i].zone)
			table.insert(self.chasing_zone_contains_ifo_list, zone.ContainsFieldObjects)
		end

		-- 등장존에 포함된 ifo 해시셋 가져옴
		self.appear_zone_contains_ifo_list = {}
		for i = 1, #self.constants_data.appear_zone do
			local zone = field:GetZone(self.constants_data.appear_zone[i])
			table.insert(self.appear_zone_contains_ifo_list, zone.ContainsFieldObjects)
		end

		-- emp존에 포함된 ifo 해시셋 가져옴
		if self.constants_data.emp_zone ~= nil then
			self.emp_zone_contains_ifo = field:GetZone(self.constants_data.emp_zone).ContainsFieldObjects
		end

		-- ammi 공격 범위
		self.attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.constants_data.range_radius,
				CS.Oak.AttackRangeShowType.OverlayForward)
		self.attack_range:Hide()

		-- 챔피언 여부에 따라 ammi state pool 생성
		if self.constants_data.is_champion then
			self.ammi = user_util.get_china_hero_character(self.constants_data.ammi_name.fei, self.constants_data.ammi_name.mei)
			self.ammi_state_pool = {
				wait = ammi_wait_state(self, self.ammi),
				appear = ammi_appear_state(self, self.ammi),
				chasing = champion_ammi_chasing_state(self, self.ammi),
				retreat = ammi_retreat_state(self, self.ammi),
				qte_attack = ammi_qte_attack_state(self, self.ammi),
				laser_attack = champion_ammi_laser_attack_state(self, self.ammi),
				groggy = ammi_groggy_state(self, self.ammi),
				screenplay = ammi_screenplay_state(self, self.ammi),
				dead = ammi_dead_state(self, self.ammi),
			}
		else
			self.ammi = get_character(self.constants_data.ammi_name)
			self.ammi_state_pool = {
				wait = ammi_wait_state(self, self.ammi),
				appear = ammi_appear_state(self, self.ammi),
				chasing = ammi_chasing_state(self, self.ammi),
				retreat = ammi_retreat_state(self, self.ammi),
				qte_attack = ammi_qte_attack_state(self, self.ammi),
				groggy = ammi_groggy_state(self, self.ammi),
				screenplay = ammi_screenplay_state(self, self.ammi),
				dead = ammi_dead_state(self, self.ammi),
			}
		end

		self:change_ammi_state('wait')
		start_coroutine(self.ammi_loop, self)
		screen_util.preload_tutorial_spine()
	end
end

-- ammi 행동 루프
function local_class:ammi_loop()
	while self.alive_ammi do
		if self.activate_ammi then
			self:update_ammi_state(unity_class.time.deltaTime)
		end
		coroutine.yield()
	end

	if self.ammi_state then
		self.ammi_state:exit()
		self.ammi_state = nil
	end

	if self.ammi_state_pool ~= nil then
		for _,state in pairs(self.ammi_state_pool) do
			state:dispose()
			state = nil
		end
		self.ammi_state_pool = nil
	end
end

-- ammi 업데이트
function local_class:update_ammi_state(dt)
	if self.ammi_state then
		self.ammi_state:update(dt)
	end
end

-- ammi state 변경
function local_class:change_ammi_state(next_state, data)
	self.ammi_state_id = self.ammi_state_id + 1

	if self.ammi_state then
		self.ammi_state:exit()
		self.ammi_state = nil
	end

	self.ammi_state = self.ammi_state_pool[next_state]
	self.ammi_state:enter(data)
end

-- 길찾기
function local_class:find_path(pos, speed, key)
	self.path_find_done = false
	local default_anim_scale_speed = 6
	local anim_scale = speed / default_anim_scale_speed
	local waypoint = {}
	field.PathFinder:FindNormalPath(self.ammi, pos, 100, self.ammi, key, nil,
			function(path, req_key)
				-- 현재 state id가 받은 시점과 다르면 실행하지 않고 폐기
				if req_key == self.ammi_state_id then
					self.path_find_done = true
					for i = 1, path.Count - 1 do
						table.insert(waypoint, path[i])
					end
					character_util.remove_anim(self.ammi)
					character_util.set_anim(self.ammi, { name = 'walk', sfx_name = function()
						music_player_util.play_sfx({ sfx_name = '01_walk_robot_06', parent = self.ammi,
						type_priority = 'event', player_priority = 'npc' }) end, scale = anim_scale })
					character_util.move_waypoint(self.ammi, waypoint, speed, false, nil, nil, nil, false, anim_scale)
				end
			end)
end

-- 가장 가까운 등장 마커 찾기
function local_class:get_closest_appear_marker_pos()
	local min_distance = 9999
	local result = nil
	for i = 1, #self.constants_data.appear_marker do
		local marker = field:GetMarker(self.constants_data.appear_marker[i])
		local marker_pos = field:GetMarker(self.constants_data.appear_marker[i]).position
		local cur_distance = unity_class.vector3.Distance(user_party.Leader.Position, marker_pos)
		if min_distance > cur_distance  then
			-- 가장 가까운 마커를 찾을 때 미리 리셋 지점을 캐싱해둠
			self.reset_marker = marker
			result = marker_pos
			min_distance = cur_distance
		end
	end

	return result
end

-- ammi가 enter_zone에 있는지 체크
function local_class:is_ammi_contains_emp_zone()
	if self.emp_zone_contains_ifo == nil then
		return false
	end

	return self.emp_zone_contains_ifo:Contains(self.ammi)
end

-- ammi가 appear_zone에 있는지 체크
function local_class:is_player_contains_appear_zone()
	for i = 1, #self.appear_zone_contains_ifo_list do
		if self.appear_zone_contains_ifo_list[i]:Contains(user_party.Leader) then
			return true
		end
	end
	return false
end

-- 플레이어가 chasing_zone을 떠났는지 체크
function local_class:is_player_contains_chasing_zone()
	for i = 1, #self.chasing_zone_contains_ifo_list do
		if self.chasing_zone_contains_ifo_list[i]:Contains(user_party.Leader) then
			return true
		end
	end
	return false
end

-- 필드 틴트 시작
function local_class:start_field_tint()
	if self.activate_field_tint then
		return
	end
	self.activate_field_tint = true
	start_coroutine(self.field_tint_loop, self)
end

-- 필드 틴트 종료
function local_class:stop_field_tint()
	self.activate_field_tint = false
end

-- 필드 틴트 루틴
function local_class:field_tint_loop()
	local tint_color = unity_color({ 1, 0, 0, 1 })
	local tint_key = 'ammi_tint'
	local tint_period = self.constants_data.field_tint_period

	while self.activate_field_tint do
		field:Tint(tint_key, tint_color, 0.5)

		local time_passed = 0
		while time_passed < tint_period/2 do
			if not self.activate_field_tint then
				field:RemoveTint(tint_key, 0.5)
				return
			end
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end
		field:RemoveTint(tint_key, 0.5)

		time_passed = 0
		while time_passed < tint_period/2 do
			if not self.activate_field_tint then
				return
			end
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end
	end
end

-- 카메라 줌 아웃
function local_class:camera_zoom_out()
	if not self.is_camera_zoom_out then
		self.is_camera_zoom_out = true
		camera_util.resize_by_ratio(self.constants_data.camera_zoom_out_size, 0.5)
	end
end

-- 카메라 줌 아웃 초기화
function local_class:reset_camera_zoom()
	if self.is_camera_zoom_out then
		self.is_camera_zoom_out = false
		camera_util.resize_to_default(0.5)
	end
end

-- ammi 스테이지 음악 재생
function local_class:play_ammi_stage_music()
	if not self.is_playing_ammi_bgm then
		self.is_playing_ammi_bgm = true
		music_player_util.play_stage_music({ name = self.constants_data.sound.chasing_zone_bgm, state = 'event' })
	end
end

-- 디폴트 스테이지 음악 재생
function local_class:play_field_stage_music()
	if self.is_playing_ammi_bgm then
		self.is_playing_ammi_bgm = false
		music_player_util.play_stage_music({state = 'field'})
	end
end

-- ammi 진입 세팅
function local_class:ammi_field_setting()
	self:camera_zoom_out()
	self:play_ammi_stage_music()
end

-- ammi 진입 세팅 초기화
function local_class:reset_ammi_field_setting()
	self:reset_camera_zoom()
	self:play_field_stage_music()
	self.qte_chance = true
end

--region ammi_state_base
function ammi_state_base:init(controller, character)
	self.controller = controller
	self.ammi = character

	self.time_passed = 0
end

function ammi_state_base:dispose()
	self.controller = nil
	self.character = nil
end

function ammi_state_base:exit()
	self.time_passed = 0
end

function ammi_state_base:update(dt)
	self.time_passed = self.time_passed + dt
end
--endregion

--region ammi_wait_state
function ammi_wait_state:init(controller, character)
	self.super:init(controller, character)
	self.ammi = character
end

function ammi_wait_state:dispose()
	self.super:dispose()
end

function ammi_wait_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.wait

	-- 위치 초기화
	self.ammi.Position = vector(999, 0, 999)
end

function ammi_wait_state:exit()
	self.super:exit()
end

function ammi_wait_state:update(dt)
	self.super:update(dt)

	if self.controller:is_player_contains_chasing_zone() then
		self.controller:ammi_field_setting()
	else
		self.controller:reset_ammi_field_setting()
	end

	if self.controller:is_player_contains_appear_zone() then
		self.controller:change_ammi_state('appear')
	end
end
--endregion

--region ammi_appear_state
function ammi_appear_state:init(controller, character)
	self.super:init(controller, character)

	-- ammi 등장 위치
	self.appear_pos = nil

	self.appear_delay = 0
end

function ammi_appear_state:dispose()
	self.super:dispose()
end

function ammi_appear_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.appear

	self.is_appear_start = false

	self.ammi.Position = vector(999, 0, 999)
	-- 등장 위치 지정해줬으면 해당 위치로 이동
	self.appear_pos = lua_helper.get_value(data, 'pos', nil)

	if self.appear_pos == nil then
		self.appear_delay = self.state_data.falling_wait_time
		-- 가장 가까운 마커 탐색
		self.appear_pos = self.controller:get_closest_appear_marker_pos()
	else
		-- 지정된 곳이 아닌 다른 위치에서 습격하는 경우 appear_attack_delay만큼 더 대기한다.
		self.appear_delay = self.state_data.falling_wait_time + self.state_data.appear_attack_delay
	end

	attack_range_util.show(self.controller.attack_range, self.appear_delay + self.state_data.falling_duration)
	attack_range_util.setup_by_position(self.controller.attack_range, self.appear_pos, 0)

	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', type_priority = 'event', play_pos = self.appear_pos })

	character_util.remove_emotion(self.ammi)
end

function ammi_appear_state:exit()
	self.super:exit()
	self.appear_pos = nil
	character_util.remove_anim(self.ammi)
end

function ammi_appear_state:update(dt)
	self.super:update(dt)

	if self.time_passed < self.appear_delay then
		if not self.controller:is_player_contains_chasing_zone() then
			self.controller.attack_range:Hide()
			self.controller:stop_field_tint()
			self.controller:change_ammi_state('wait')
			return
		end
		return
	end

	if not self.is_appear_start then
		self.is_appear_start = true

		-- 천장 먼지 이펙트
		local ceiling_dust_effect_pos = self.appear_pos + vector(0, 5, 0)
		local ceiling_dust = unity_object_pool.GetOrCreate(
				self.controller.constants_data.effect.ceiling_dust):Instantiate(ceiling_dust_effect_pos)
		ceiling_dust.transform.localScale = unity_class.vector3.one * 0.8

		local look_dir = vector_util.to_direction(user_party.Leader.Position - self.appear_pos)
		character_util.set_direction(self.ammi, look_dir)

		character_util.set_position(self.ammi, self.appear_pos +
				vector(0, self.state_data.falling_height, 0))
		character_util.set_anim(self.ammi, { name = 'stomp_loop' })
	end

	local progress = (self.time_passed - self.appear_delay) / self.state_data.falling_duration

	-- 낙하 완료되면 chase 상태 시작
	if progress > 1 then
		character_util.remove_anim(self.ammi)
		music_player_util.play_sfx({ sfx_name = '02_stomp_robot_01', parent = self.ammi,
			type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '01_ammi_01', parent = self.ammi,
			type_priority = 'event', player_priority = 'npc' })
		-- 땅 먼지 이펙트
		unity_object_pool.GetOrCreate(
				self.controller.constants_data.effect.ground_dust):Instantiate(self.appear_pos)

		-- 떨어진 곳이 EMP존일 경우 방어 코드
		if self.controller:is_ammi_contains_emp_zone() and self.controller.activate_emp_switch then
			self.controller.attack_range:Hide()
			self.controller:change_ammi_state('dead')
			return
		end

		-- 떨어지는 중 플레이어가 추격존을 이미 떠났다면 retreat 상태로 진입
		if not self.controller:is_player_contains_chasing_zone() then
			self.controller.attack_range:Hide()
			self.controller:change_ammi_state('retreat')
			return
		end

		-- 그 외 일반적인 경우 chasing 상태로 진입
		character_util.set_position(self.ammi, self.appear_pos)
		camera_util.shake(0.3, 0.4)
		self.controller:change_ammi_state('chasing')
		return
	end

	local pos = unity_class.vector3.Lerp(self.appear_pos +
			vector(0, self.state_data.falling_height, 0), self.appear_pos, progress)
	character_util.set_position(self.ammi, pos)
end
--endregion

--region ammi_chasing_state
function ammi_chasing_state:init(controller, character)
	self.super:init(controller, character)

	-- ammi 추격 state
	self.chasing_state = {
		-- 일반적인 등속 이동
		normal_chasing = 1,
		-- 느린 상태에서 가속하는 이동
		acceleration_chasing = 2,
		-- 빠른 상태에서 감속하는 이동
		deceleration_chasing = 3,
		-- 빠르게 달려오는 이동
		fast_chasing = 4
	}
	self.current_chasing_state = self.chasing_state.normal_chasing
	self.chasing_speed = 6
	self.chasing_state_time_passed = 0
	self.recent_chasing_state = nil
end

function ammi_chasing_state:dispose()
	self.super:dispose()
end

function ammi_chasing_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.chasing

	self.path_find_time_passed = self.state_data.find_path_term

	attack_range_util.show(self.controller.attack_range, 0)
	attack_range_util.setup_by_position(self.controller.attack_range, self.ammi.Position, 0)

	self.attack_range_parent = self.controller.attack_range.transform.parent
	self.controller.attack_range.transform:SetParent(self.ammi.Transform)

	self.current_chasing_state = self.chasing_state.normal_chasing
	self.chasing_speed = self.state_data.normal_chasing_speed
	self.chasing_state_time_passed = 0
	self.recent_chasing_state = nil

	self.controller.path_find_done = true

	self.controller:start_field_tint()

	character_util.set_emotion(self.ammi, { name = 'attack' })
end

function ammi_chasing_state:exit()
	self.super:exit()
	character_util.stop(self.ammi)
	self.controller.attack_range:Hide()

	self.controller.attack_range.transform:SetParent(self.attack_range_parent)

	self.controller.path_find_done = true

	character_util.remove_anim(self.ammi)
end

function ammi_chasing_state:update(dt)
	self.super:update(dt)

	-- 플레이어가 추격존을 떠났다면 retreat 상태 전환
	if self.controller.interact_exit_in_chasing_zone or not self.controller:is_player_contains_chasing_zone() then
		self.controller:change_ammi_state('retreat')
		return
	end

	-- ammi가 emp존에 들어가면 dead 상태 전환
	if self.controller:is_ammi_contains_emp_zone() and self.controller.activate_emp_switch then
		self.controller:change_ammi_state('dead')
		return
	end

	local player_distance = unity_class.vector3.Distance(user_party.Leader.Position, self.ammi.Position)
	-- 플레이어와의 거리가 공격 범위보다 짧으면 attack 상태 전환
	if player_distance <= self.controller.constants_data.range_radius then
		self.controller:change_ammi_state('qte_attack')
		return
	end

	-- chasing state 처리
	if self.current_chasing_state == self.chasing_state.normal_chasing then
		self.chasing_state_time_passed = self.chasing_state_time_passed + dt

		self.chasing_speed = self.state_data.normal_chasing_speed

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.normal_chasing_duration then
			self.chasing_state_time_passed = 0

			-- 화면에 AMMI가 안보이면 빠른 추격 보이면 가속 추격으로 변경
			if screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
				-- 최근 가속 추격 패턴을 사용했으면 감속으로 그 외 상황에서는 가속으로
				if self.recent_chasing_state == self.chasing_state.acceleration_chasing then
					self.current_chasing_state = self.chasing_state.deceleration_chasing
				else
					self.current_chasing_state = self.chasing_state.acceleration_chasing
				end
			else
				self.current_chasing_state = self.chasing_state.fast_chasing
			end
		end

	elseif self.current_chasing_state == self.chasing_state.acceleration_chasing then
		self.chasing_state_time_passed = self.chasing_state_time_passed + dt

		-- 아직 가속 첫번째 패턴의 duration이 남아있으면 첫번째 스피드로 아니면 두번째 패턴 스피드
		if self.chasing_state_time_passed <= self.state_data.acceleration_chasing_1_duration then
			self.chasing_speed = self.state_data.acceleration_chasing_1_speed
		else
			self.chasing_speed = self.state_data.acceleration_chasing_2_speed
		end

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.acceleration_chasing_1_duration +
				self.state_data.acceleration_chasing_2_duration then
			self.chasing_state_time_passed = 0

			self.recent_chasing_state = self.chasing_state.acceleration_chasing

			-- 화면에 AMMI가 안보이면 빠른 추격 보이면 일반 추격으로 변경
			if screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
				self.current_chasing_state = self.chasing_state.normal_chasing
			else
				self.current_chasing_state = self.chasing_state.fast_chasing
			end
		end

	elseif self.current_chasing_state == self.chasing_state.deceleration_chasing then
		self.chasing_state_time_passed = self.chasing_state_time_passed + dt

		-- 아직 감속 첫번째 패턴의 duration이 남아있으면 첫번째 스피드로 아니면 두번째 패턴 스피드
		if self.chasing_state_time_passed <= self.state_data.deceleration_chasing_1_duration then
			self.chasing_speed = self.state_data.deceleration_chasing_1_speed
		else
			self.chasing_speed = self.state_data.deceleration_chasing_2_speed
		end

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.deceleration_chasing_2_duration +
				self.state_data.acceleration_chasing_2_duration then
			self.chasing_state_time_passed = 0

			self.recent_chasing_state = self.chasing_state.deceleration_chasing

			-- 화면에 AMMI가 안보이면 빠른 추격 보이면 일반 추격으로 변경
			if screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
				self.current_chasing_state = self.chasing_state.normal_chasing
			else
				self.current_chasing_state = self.chasing_state.fast_chasing
			end
		end

	elseif self.current_chasing_state == self.chasing_state.fast_chasing then
		self.chasing_speed = self.state_data.fast_chasing_speed

		-- AMMI가 화면에 보이는 동안만 시간을 세서 1초 카운트
		if screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
			self.chasing_state_time_passed = self.chasing_state_time_passed + dt
		else
			self.chasing_state_time_passed = 0
		end

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.fast_chasing_duration then
			self.chasing_state_time_passed = 0
			self.current_chasing_state = self.chasing_state.normal_chasing
			self.recent_chasing_state = self.chasing_state.fast_chasing
		end
	end

	-- path_find 완료 시점부터 시간 증가
	if self.controller.path_find_done then
		self.path_find_time_passed = self.path_find_time_passed + dt

		if self.path_find_time_passed >= self.state_data.find_path_term then
			start_coroutine(self.controller.find_path, self.controller,
					user_party.Leader.Position, self.chasing_speed, self.controller.ammi_state_id)
			self.path_find_time_passed = 0
		end
	end
end
--endregion

--region ammi_retreat_state
function ammi_retreat_state:init(controller, character)
	self.super:init(controller, character)
end

function ammi_retreat_state:dispose()
	self.super:dispose()
end

function ammi_retreat_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.retreat

	self.controller:stop_field_tint()

	self.controller.path_find_done = true

	self.controller:reset_ammi_field_setting()

	-- 가장 가까운 chasing_zone 중심으로 이동
	local min_distance = 9999
	self.retreat_pos = self.ammi.Position
	for i = 1, #self.controller.constants_data.chasing_zone do
		local marker_pos = field:GetMarker(self.controller.constants_data.chasing_zone[i].center).position
		local cur_distance = unity_class.vector3.Distance(user_party.Leader.Position, marker_pos)
		if min_distance > cur_distance  then
			self.retreat_pos = marker_pos
			min_distance = cur_distance
		end
	end
	start_coroutine(self.controller.find_path, self.controller, self.retreat_pos,
			self.state_data.retreat_speed, self.controller.ammi_state_id)

	character_util.remove_emotion(self.ammi)
end

function ammi_retreat_state:exit()
	self.super:exit()
	character_util.stop(self.ammi)
	character_util.remove_anim(self.ammi)
	self.controller.path_find_done = true
end

function ammi_retreat_state:update(dt)
	self.super:update(dt)

	-- ammi가 emp존에 들어가면 dead 상태 전환
	if self.controller:is_ammi_contains_emp_zone() and self.controller.activate_emp_switch then
		-- exit 인터랙트 상태면 dead 무시
		if not self.controller.interact_exit_in_chasing_zone then
			self.controller:change_ammi_state('dead')
		end
		return
	end

	-- 플레이어가 추격존에 들어왔으면 chasing 상태로 전환
	if not self.controller.interact_exit_in_chasing_zone and self.controller:is_player_contains_chasing_zone() then
		self.controller:ammi_field_setting()
		self.controller:change_ammi_state('chasing')
		return
	end

	-- 화면 밖으로 이동했으면 awake state로 전환
	if not screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
		self.controller:change_ammi_state('wait')
	end
end
--endregion

--region ammi_qte_attack_state
function ammi_qte_attack_state:init(controller, character)
	self.super:init(controller, character)
end

function ammi_qte_attack_state:dispose()
	self.super:dispose()
end

function ammi_qte_attack_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.qte_attack

	-- qte 관련
	self.swipe_type = ''
	self.is_qte_start = false
	self.fail_qte = false

	character_util.set_emotion(self.ammi, { name = 'attack' })

	start_coroutine(self.qte_event, self)
end

function ammi_qte_attack_state:exit()
	self.super:exit()

	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	self.fail_qte = false

	character_util.remove_emotion(self.ammi)
	character_util.remove_anim_and_emotion(user_party.Leader)
end

function ammi_qte_attack_state:update(dt)
	self.super:update(dt)
end

function ammi_qte_attack_state:on_touch_event(e)
	if not self.is_qte_start then
		return false
	end

	if self.is_qte_start then
		if e.TouchEventType == CS.Oak.TouchEventType.SwipeLeft then
			self.swipe_type = 'left'
			return true
		elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeRight then
			self.swipe_type = 'right'
			return true
		elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeUp then
			self.swipe_type = 'up'
			return true
		elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeDown then
			self.swipe_type = 'down'
			return true
		end
	end

	return true
end

function ammi_qte_attack_state:qte_swipe(dir)
	self.swipe_type = ''
	self.is_qte_start = true
	local time_passed = 0
	local pass = false

	screen_util.qte_swipe(dir)
	while time_passed < self.state_data.qte_duration do
		coroutine.yield()
		time_passed = time_passed + unity_class.time.deltaTime
		if self.swipe_type == dir then
			pass = true
			yield_return_func(CS.Oak.CommonScreenplay.QTEComplete, 1)
			break
		end
	end

	if pass then
		self.is_qte_start = false
		return true
	else
		screen_util.close_tutorial_spine()
		self.fail_qte = true
		self.is_qte_start = false
		return false
	end
end

function ammi_qte_attack_state:qte_event()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	coroutine.yield()
	coroutine.yield()
	if self.controller.interact_exit_in_chasing_zone or not self.controller:is_player_contains_chasing_zone() then
		field_ui_manager:Show()
		self.controller:change_ammi_state('retreat')
		return
	end
	user_party.Leader.CharacterBehaviour:CancelAllBattleActions(true)
	character_util.stop(self.ammi)

	character_util.look_at(user_party.Leader)
	if user_party.Leader.Position.x > self.ammi.Position.x then
		for i = 0, user_party.Count - 1 do
			character_util.set_direction(user_party[i], 'left')
			character_util.set_emotion(user_party[i], { name = 'attack' })
		end
	else
		for i = 0, user_party.Count - 1 do
			character_util.set_direction(user_party[i], 'right')
			character_util.set_emotion(user_party[i], { name = 'attack' })
		end
	end
	character_util.set_emotion(self.ammi, { name = 'attack' })

	self.controller:reset_camera_zoom()
	character_util.set_anim(self.ammi, { name = 'attack_ready', loop = false, next_anim = 'attack_ready_loop' })
	wait_for_sec(0.7)
	music_player_util.play_sfx({ sfx_name = '01_ammi_05', parent = self.ammi,
		type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx_one_shot('01_slowmotion_01')

	if self.controller.qte_chance then
		self.controller.qte_chance = false
		message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')

		music_player_util.play_sfx_one_shot('01_tap_guide_01')
		self:qte_swipe('up')
		self.controller:camera_zoom_out()

		-- qte 실패했으면 리셋 후 wait 상태로 변경
		if self.fail_qte then
			self:reset_player()
			self.controller:change_ammi_state('wait')
		else
			self:success_qte()
			-- qte 성공했으면 그로기 상태로 변경
			self.controller:change_ammi_state('groggy')
		end
	else
		wait_for_sec(0.5)
		self.controller:camera_zoom_out()
		self:reset_player()
		self.controller:change_ammi_state('wait')
	end
end

-- 플레이어 리셋
function ammi_qte_attack_state:reset_player()
	local fade_duration = 1
	local wait_duration = 0.5

	-- qte 다시 가능하도록 초기화
	self.controller.qte_chance = true

	character_util.set_animation_n_times(self.ammi, { name = 'attack', count = 1, sfx = '01_ammi_06' })

	music_player_util.play_sfx_one_shot('01_hit_npc_01')
	music_player_util.play_sfx_one_shot('01_drown_01')

	for i = 0, user_party.Count - 1 do
		character_util.set_anim(user_party[i], { name = 'dead', loop = false, sfx_name = '01_hit_npc_01' })
		character_util.set_emotion(user_party[i], { name = 'damaged' })
		character_util.spine_pulse_color(user_party[i], CS.Oak.Constants.DamageColor, 1,
				1, 0.5)
		character_util.spine_damage_squish(user_party[i], 1.3, 0.7, 1, 0.2)
	end

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_impact_05')
	screen_util.fade_out_async(fade_duration, unity_class.color.red, 'linear')

	self.controller:stop_field_tint()
	self.ammi.Position = vector(999, 0, 999)

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim_and_emotion(user_party[i])
	end

	party_util.align_party(self.controller.reset_marker.position, self.controller.reset_marker.direction, 0, 'linear')
	wait_for_sec(wait_duration)

	screen_util.fade_in_async(fade_duration, unity_class.color.red, 'linear')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- qte 성공
function ammi_qte_attack_state:success_qte()
	local qte_mod = 'ammi_qte_mod'

	for i = 0, user_party.Count - 1 do
		character_util.set_anim(user_party[i], { name = 'get' })
	end

	local time_passed = 0
	local duration = 0.6
	local height = 2
	local start_height = 0

	time_util.mod(qte_mod, 0.5)

	character_util.set_anim(self.ammi, { name = 'attack', loop = false, sfx_name = '01_ammi_06' })
	music_player_util.play_sfx_one_shot('02_boss_rise_01')
	for i = 0, user_party.Count - 1 do
		character_util.mario_jump_new(user_party[i], user_party[i].Direction, duration, height)
	end
	wait_for_sec(duration/2)

	time_util.unmod(qte_mod)

	wait_for_sec(duration/2)

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim_and_emotion(user_party[i])
	end
	character_util.remove_anim(self.ammi)
	self.controller:ammi_field_setting()

	field_ui_manager:Show()
	user_party:ResetControllers()
end

--endregion

--region ammi_groggy_state
function ammi_groggy_state:init(controller, character)
	self.super:init(controller, character)

	self.groggy_time = 0
end

function ammi_groggy_state:dispose()
	self.super:dispose()
end

function ammi_groggy_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.groggy

	self.groggy_time = self.state_data.groggy_time

	-- 이미 exit 나가는 경우의 그로기 시간을 세팅했는지
	self.already_set_exit_groggy_time = false

	-- exit 나가는 경우의 그로기 시간
	self.exit_groggy_time = 0.7

	character_util.set_emotion(self.ammi, { name = 'empty' })
end

function ammi_groggy_state:exit()
	self.super:exit()
	character_util.remove_anim_and_emotion(self.ammi)
end

function ammi_groggy_state:update(dt)
	self.super:update(dt)

	-- 플레이어가 그로기 중 exit로 퇴장한다면 무조건 fade까지 기다린다.
	if self.controller.interact_exit_in_chasing_zone and not self.already_set_exit_groggy_time then
		self.already_set_exit_groggy_time = true
		self.groggy_time = self.time_passed + self.exit_groggy_time
	end

	if self.time_passed >= self.groggy_time then
		-- 플레이어가 추격존을 이미 떠났다면 retreat 상태로 진입
		if not self.controller:is_player_contains_chasing_zone() then
			self.controller:change_ammi_state('retreat')
			return
		end

		-- 그 외 일반적인 경우 chasing 상태 진입
		self.controller:change_ammi_state('chasing')
	end
end
--endregion

--region ammi_screenplay_state
function ammi_screenplay_state:init(controller, character)
	self.super:init(controller, character)
end

function ammi_screenplay_state:dispose()
	self.super:dispose()
end

function ammi_screenplay_state:enter(data)
	local call_back = lua_helper.get_value(data, 'cb', nil)
	local next_state = lua_helper.get_value(data, 'next_state', nil)
	local next_state_data = lua_helper.get_value(data, 'data', nil)

	if call_back ~= nil then
		start_coroutine(function()
			self[call_back](self)
			if next_state ~= nil then
				self.controller:change_ammi_state(next_state, next_state_data)
			end
		end)
	end
end

function ammi_screenplay_state:exit()
	self.super:exit()
end

function ammi_screenplay_state:update(dt)
	self.super:update(dt)
end
--endregion

--region ammi_dead_state
function ammi_dead_state:init(controller, character)
	self.super:init(controller, character)

	self.wait_before_get_item = true
end

function ammi_dead_state:dispose()
	self.super:dispose()
end

function ammi_dead_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.dead
	start_coroutine(self.destroy_ammi, self)
end

function ammi_dead_state:exit()
	self.super:exit()
end

function ammi_dead_state:update(dt)
	self.super:update(dt)
end

-- Champion AMMI는 맵에 emp존이 없어 dead state가 될 수 없으니 따로 예외 처리하지 않음
function ammi_dead_state:destroy_ammi()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.ammi.Direction = direction_util.to_side_dir(self.ammi.Direction)
	character_util.set_anim(self.ammi, { name = 'damaged' })
	character_util.set_emotion(self.ammi, { name = 'attack' })

	self.controller:stop_field_tint()

	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')

	local distance = unity_class.vector3.Distance(user_party.Leader.Position, self.ammi.Position)
	local camera_speed = distance > 5 and 6 or 3
	local duration = distance/camera_speed

	camera_util.move_async(self.ammi.Position, duration)

	music_player_util.play_sfx({ sfx_name = '02_emp_02', parent = self.ammi,
		type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_ammi_04', parent = self.ammi,
		type_priority = 'event', player_priority = 'npc' })

	unity_object_pool.GetOrCreate(self.controller.constants_data.effect.emp_explosion):Instantiate(self.ammi.Position)

	wait_for_sec(1)
	music_player_util.play_sfx({ sfx_name = '01_walk_robot_03', parent = self.ammi,
		type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(self.ammi, { name = 'dead', loop = false })
	wait_for_sec(1)

	local emp_unit = get_field_object(self.controller.constants_data.emp_unit)
	local emp_unit_animator = emp_unit:GetComponent(typeof(CS.UnityEngine.Animator))

	if self.controller.emp_sfx ~= nil then
		self.controller.emp_sfx:Stop()
		self.controller.emp_sfx = nil
	end
	music_player_util.play_sfx_one_shot('02_emp_04')
	start_coroutine(function()
		local progress = 0
		local time_passed = 0
		local duration = 0.5
		local start_scale = self.controller.emp_field_effect.transform.localScale
		local end_scale = vector(0, 1, 0)
		while progress < 1 do
			progress = time_passed / duration

			local scale = unity_class.vector3.Lerp(start_scale, end_scale, progress)
			self.controller.emp_field_effect.transform.localScale = scale

			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield(nil)
		end
		self.controller.emp_field_effect:Dispose()
		self.controller.emp_field_effect = nil
	end)

	music_player_util.play_sfx({ sfx_name = '02_explosion_dark_02', parent = self.ammi,
		type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate(self.controller.constants_data.effect.ammi_explosion):Instantiate(self.ammi.Position)
	wait_for_sec(0.15)
	emp_unit_animator:Play('off')

	music_player_util.play_sfx_one_shot('01_air_spin_02')
	local item = drop_item_util.create_item({
		pos = self.ammi.Position, target = self.ammi.Position, itemid = self.state_data.item_id,
		notforinven = true, lootstate = 'FixLooter', skip_text = true
	})

	character_util.set_position(self.ammi, vector(999, 0, 999))

	wait_for_sec(0.5)
	music_player_util.play_sfx_one_shot('02_lina_lb_stomp_01')
	wait_for_sec(0.5)
	item.ConsumeTarget = user_party.Leader

	if unity_class.vector3.Distance(user_party.Leader.Position, item.Position) < 5 then
		camera_util.return_to_leader(0.5)
		while self.wait_before_get_item do
			coroutine.yield()
		end
	else
		while self.wait_before_get_item do
			camera_util.move(item.Position, 0)
			coroutine.yield()
		end
		camera_util.return_to_leader(0.5)
	end

	wait_for_sec(0.5)
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	screen_util.item_get_event(self.state_data.item_sprite,
			self.state_data.item_name, self.state_data.item_sub_name, self.state_data.item_info)

	stage_progress_util.set_custom_data_async(self.controller.custom_keys.ammi_dead, 1)

	self.controller.alive_ammi = false

	self.controller:reset_ammi_field_setting()

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function ammi_dead_state:on_item_get_event(e)
	if lua_helper.reference_equals(e.Getter, user_party.Leader) and e.Item.ItemId == self.state_data.item_id then
		self.wait_before_get_item = false
		return true
	end

	return false
end
--endregion

--region champion_ammi_chasing_state
function champion_ammi_chasing_state:init(controller, character)
	self.super:init(controller, character)

	-- ammi 추격 state
	self.chasing_state = {
		-- 일반적인 등속 이동 1
		normal_chasing_1 = 1,
		-- 느린 상태에서 가속하는 이동
		acceleration_chasing = 2,
		-- 일반적인 등속 운동 2
		normal_chasing_2 = 3,
		-- 빠른 상태에서 감속하는 이동
		deceleration_chasing = 4
	}
	self.current_chasing_state = self.chasing_state.normal_chasing_1
	self.chasing_speed = 6
	self.chasing_state_time_passed = 0
	self.recent_chasing_state = nil
end

function champion_ammi_chasing_state:dispose()
	self.super:dispose()
end

function champion_ammi_chasing_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.champion_chasing

	self.path_find_time_passed = self.state_data.find_path_term

	attack_range_util.show(self.controller.attack_range, 0)
	attack_range_util.setup_by_position(self.controller.attack_range, self.ammi.Position, 0)

	self.attack_range_parent = self.controller.attack_range.transform.parent
	self.controller.attack_range.transform:SetParent(self.ammi.Transform)

	-- 이전 state가 레이저 공격이면 다음 추격으로 넘어감 아니면 처음부터 다시 시작
	local reset_state = lua_helper.get_value(data, 'reset_state', true)
	if reset_state then
		self.current_chasing_state = self.chasing_state.normal_chasing_1
		self.chasing_speed = self.state_data.normal_chasing_speed
	end

	self.chasing_state_time_passed = 0
	self.recent_chasing_state = nil

	self.controller.path_find_done = true

	character_util.set_emotion(self.ammi, { name = 'attack' })

	self.controller:start_field_tint()
end

function champion_ammi_chasing_state:exit()
	self.super:exit()
	character_util.stop(self.ammi)
	self.controller.attack_range:Hide()

	self.controller.attack_range.transform:SetParent(self.attack_range_parent)

	self.controller.path_find_done = true
end

function champion_ammi_chasing_state:update(dt)
	self.super:update(dt)

	-- 플레이어가 추격존을 떠났다면 retreat 상태 전환
	if self.controller.interact_exit_in_chasing_zone or not self.controller:is_player_contains_chasing_zone() then
		self.controller:change_ammi_state('retreat')
		return
	end

	-- ammi가 emp존에 들어가면 dead 상태 전환
	if self.controller:is_ammi_contains_emp_zone() and self.controller.activate_emp_switch then
		self.controller:change_ammi_state('dead')
		return
	end

	local player_distance = unity_class.vector3.Distance(user_party.Leader.Position, self.ammi.Position)
	-- 플레이어와의 거리가 공격 범위보다 짧으면 attack 상태 전환
	if player_distance <= self.controller.constants_data.range_radius then
		self.controller:change_ammi_state('qte_attack')
		return
	end

	-- chasing state 처리
	self.chasing_state_time_passed = self.chasing_state_time_passed + dt
	if self.current_chasing_state == self.chasing_state.normal_chasing_1 then
		self.chasing_speed = self.state_data.normal_chasing_speed

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.normal_chasing_duration then
			self.chasing_state_time_passed = 0
			self.current_chasing_state = self.chasing_state.acceleration_chasing
			self.controller:change_ammi_state('laser_attack')
			return
		end

	elseif self.current_chasing_state == self.chasing_state.acceleration_chasing then
		-- 아직 가속 첫번째 패턴의 duration이 남아있으면 첫번째 스피드로 아니면 두번째 패턴 스피드
		if self.chasing_state_time_passed <= self.state_data.acceleration_chasing_1_duration then
			self.chasing_speed = self.state_data.acceleration_chasing_1_speed
		else
			self.chasing_speed = self.state_data.acceleration_chasing_2_speed
		end

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.acceleration_chasing_1_duration +
				self.state_data.acceleration_chasing_2_duration then
			self.chasing_state_time_passed = 0
			self.current_chasing_state = self.chasing_state.normal_chasing_2
			self.controller:change_ammi_state('laser_attack')
			return
		end

	elseif self.current_chasing_state == self.chasing_state.normal_chasing_2 then
		self.chasing_speed = self.state_data.normal_chasing_speed

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.normal_chasing_duration then
			self.chasing_state_time_passed = 0
			self.current_chasing_state = self.chasing_state.deceleration_chasing
			self.controller:change_ammi_state('laser_attack')
			return
		end

	elseif self.current_chasing_state == self.chasing_state.deceleration_chasing then
		-- 아직 감속 첫번째 패턴의 duration이 남아있으면 첫번째 스피드로 아니면 두번째 패턴 스피드
		if self.chasing_state_time_passed <= self.state_data.deceleration_chasing_1_duration then
			self.chasing_speed = self.state_data.deceleration_chasing_1_speed
		else
			self.chasing_speed = self.state_data.deceleration_chasing_2_speed
		end

		-- 해당 chasing state의 지속 시간이 지났으면
		if self.chasing_state_time_passed >= self.state_data.deceleration_chasing_2_duration +
				self.state_data.acceleration_chasing_2_duration then
			self.chasing_state_time_passed = 0
			self.current_chasing_state = self.chasing_state.normal_chasing_1
			self.controller:change_ammi_state('laser_attack')
			return
		end
	end

	-- path_find 완료 시점부터 시간 증가
	if self.controller.path_find_done then
		self.path_find_time_passed = self.path_find_time_passed + dt

		if self.path_find_time_passed >= self.state_data.find_path_term then
			local state_id = self.controller.ammi_state_id
			start_coroutine(self.controller.find_path, self.controller,
					user_party.Leader.Position, self.chasing_speed, state_id)
			self.path_find_time_passed = 0
		end
	end
end
--endregion

--region champion_ammi_laser_attack_state
function champion_ammi_laser_attack_state:init(controller, character)
	self.super:init(controller, character)
	self.state_data = self.controller.constants_data.state_data.champion_laser_attack

	-- 공격 범위 표시기 생성
	self.attack_range = CS.AttackRange.CreateRect(unity_class.vector3.zero,
			unity_class.vector2(self.state_data.distance, self.state_data.width),
			CS.Oak.AttackRangeShowType.OverlayForward)
	self.attack_range:Hide()
end

function champion_ammi_laser_attack_state:dispose()
	self.super:dispose()
	if self.attack_range ~= nil then
		CS.UnityEngine.Object.Destroy(self.attack_range)
		self.attack_range = nil
	end
	if self.laser_effect ~= nil then
		self.laser_effect:Dispose()
		self.laser_effect = nil
	end
	if self.laser_ready_effect ~= nil then
		self.laser_ready_effect:Dispose()
		self.laser_ready_effect = nil
	end
end

function champion_ammi_laser_attack_state:enter(data)
	self.state_data = self.controller.constants_data.state_data.champion_laser_attack

	-- 플레이어 reset이 끝났는지 여부
	self.reset_done = false

	-- 플레이어가 맞았는지
	self.hit_player = false

	-- 레이저 이펙트
	self.laser_effect = nil

	self.laser_sfx = music_player_util.play_sfx({ sfx_name = '02_plasma_loop_01', parent = self.ammi, type_priority = 'event', player_priority = 'npc' })

	-- 레이저 준비 이펙트
	self.laser_ready_effect = unity_object_pool.GetOrCreate(self.controller.constants_data.effect.laser_ready):Instantiate(self.ammi.Bounds.center)

	character_util.stop(self.ammi)

	local dir = vector_util.get_x0z(user_party.Leader.Position - self.ammi.Position).normalized
	local attack_duration = self.state_data.aiming_time + self.state_data.ready_to_launch_time

	attack_range_util.setup_by_direction(self.attack_range, self.ammi.Position, dir, self.ammi.Position.y)
	attack_range_util.show(self.attack_range, attack_duration)

	character_util.set_anim(self.ammi, { name = 'unique/railgun_shoot', loop = false, next_anim = 'unique/railgun_shoot_loop' })

	music_player_util.play_sfx({ sfx_name = '01_ammi_04', parent = self.ammi, type_priority = 'event', player_priority = 'npc' })

	character_util.set_emotion(self.ammi, { name = 'attack' })
end

function champion_ammi_laser_attack_state:exit()
	self.super:exit()

	character_util.remove_anim(self.ammi)

	if self.laser_effect ~= nil then
		self.laser_effect:Dispose()
		self.laser_effect = nil
	end

	if self.laser_ready_effect ~= nil then
		self.laser_ready_effect:Dispose()
		self.laser_ready_effect = nil
	end

	if self.laser_sfx ~= nil then
		self.laser_sfx:Stop()
		self.laser_sfx = nil
	end

	self.attack_range:Hide()

	character_util.remove_anim(self.ammi)
end

function champion_ammi_laser_attack_state:update(dt)
	self.super:update(dt)
	-- 플레이어에 타격했으면 리셋 후 wait 상태로 변경
	if self.hit_player then
		if self.reset_done then
			self.controller:change_ammi_state('wait')
		end
		return
	end

	if self.time_passed < self.state_data.aiming_time then
		-- 발사 준비 중 추적존을 떠났다면 발사 종료
		if not self.controller:is_player_contains_chasing_zone() then
			self.controller:change_ammi_state('retreat')
			return
		end

		character_util.look_at(self.ammi, user_party.Leader)
		local dir = vector_util.get_x0z(user_party.Leader.Position - self.ammi.Position).normalized

		attack_range_util.setup_by_direction(self.attack_range, self.ammi.Position, dir, self.ammi.Position.y)
		return
	end

	if self.time_passed < self.state_data.aiming_time + self.state_data.ready_to_launch_time then
		-- 발사 준비 중 추적존을 떠났다면 발사 종료
		if self.controller.interact_exit_in_chasing_zone or not self.controller:is_player_contains_chasing_zone() then
			self.controller:change_ammi_state('retreat')
		end
		return
	end

	-- 레이저 이펙트 생성, 공격 범위 숨기기
	if self.laser_effect == nil then
		if self.laser_ready_effect ~= nil then
			self.laser_ready_effect:Dispose()
			self.laser_ready_effect = nil
		end
		if self.laser_sfx ~= nil then
			self.laser_sfx:Stop()
			self.laser_sfx = nil
		end
		music_player_util.play_sfx_one_shot('02_light_laser_03')
		self.laser_effect = unity_object_pool.GetOrCreate(self.controller.constants_data.effect.laser):Instantiate(self.ammi.Bounds.center)
		self.laser_effect.transform.rotation = unity_class.quaternion.Euler(
				0, self.attack_range.transform.localRotation.eulerAngles.y, 0)
		self.attack_range:Hide()
	end

	-- 플레이어에게 타격했는지 체크
	if self.time_passed < self.state_data.aiming_time + self.state_data.ready_to_launch_time + self.state_data.launch_time then
		-- 플레이어가 exit 인터랙트했으면 바로 꺼버리고 retreat
		if self.controller.interact_exit_in_chasing_zone then
			self.time_passed = self.state_data.aiming_time + self.state_data.ready_to_launch_time + self.state_data.launch_time
			return
		end
		if self:is_player_contains_attack_range() then
			self.hit_player = true
			start_coroutine(self.reset_player, self)
		end
		return
	end

	if self.controller.interact_exit_in_chasing_zone or not self.controller:is_player_contains_chasing_zone() then
		music_player_util.play_sfx({ sfx_name = '01_ammi_02', parent = self.ammi, type_priority = 'event', player_priority = 'npc' })
		-- 플레이어가 추격존을 이미 떠났다면 retreat 상태로 진입
		self.controller:change_ammi_state('retreat')
	elseif not screen_util.is_fo_in_screen(self.ammi.Position, { bonus_distance = 2 }) then
		-- 플레이어가 시야에 없다면 플레이어 자리로 appear
		self.controller:change_ammi_state('appear',
				{ pos = user_party.Leader.Position })
	else
		music_player_util.play_sfx({ sfx_name = '01_ammi_02', parent = self.ammi, type_priority = 'event', player_priority = 'npc' })
		-- 그 외 상황에서는 chasing 상태로 진입
		self.controller:change_ammi_state('chasing', { reset_state = false })
	end
end

-- 플레이어가 attack_range에 포함되어 있는지 체크
function champion_ammi_laser_attack_state:is_player_contains_attack_range()
	local dir_vec = user_party.Leader.Position - self.ammi.Position
	local correction_angle = -90
	local player_relative_coordinates = unity_class.quaternion.Euler(0,
			-self.attack_range.transform.localRotation.eulerAngles.y + correction_angle, 0) * dir_vec
	local attack_range_p1 = vector(-self.state_data.width/2, 0, 0)
	local attack_range_p2 = vector(self.state_data.width/2, 0, self.state_data.distance)

	return attack_range_p1.x <= player_relative_coordinates.x and attack_range_p1.z <= player_relative_coordinates.z
			and attack_range_p2.x >= player_relative_coordinates.x and attack_range_p2.z >= player_relative_coordinates.z
end

-- 플레이어 리셋
function champion_ammi_laser_attack_state:reset_player()
	local fade_duration = 1
	local wait_duration = 0.5

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- qte 다시 가능하도록 초기화
	self.controller.qte_chance = true

	for i = 0, user_party.Count - 1 do
		character_util.spine_pulse_color(user_party[i], CS.Oak.Constants.DamageColor, 1,
				1, 0.5)
		character_util.spine_damage_squish(user_party[i], 1.3, 0.7, 1, 0.2)
		user_party[i].Direction = direction_util.to_side_dir(user_party[i].Direction)
		character_util.set_anim(user_party[i], { name = 'dead', loop = false })
		character_util.set_emotion(user_party[i], { name = 'damaged' })
	end

	wait_for_sec(1)

	screen_util.fade_out_circular_async(fade_duration, 'linear')

	self.controller:stop_field_tint()
	if self.laser_effect ~= nil then
		self.laser_effect:Dispose()
		self.laser_effect = nil
	end

	self.ammi.Position = vector(999, 0, 999)
	for i = 0, user_party.Count - 1 do
		character_util.remove_anim_and_emotion(user_party[i])
	end
	party_util.align_party(self.controller.reset_marker.position, self.controller.reset_marker.direction, 0, 'linear')

	wait_for_sec(wait_duration)
	screen_util.fade_in_circular_async(fade_duration, 'linear')

	field_ui_manager:Show()
	user_party:ResetControllers()

	self.reset_done = true
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
