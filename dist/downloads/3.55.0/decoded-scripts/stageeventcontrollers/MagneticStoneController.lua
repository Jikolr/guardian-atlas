local local_class = newclass('MagneticStoneController')

-------- 자성 바위 --------
local magnetic_stone_class = {
	parent_class = nil,

	-- 바위 기본 정보
	index = nil,
	start_pos = nil,
	destination_pos = nil,
	is_activated = false,

	fall_duration = nil,
	fall_height = nil,

	state = nil,
	current_state = nil,

	current_position = nil,
	fall_time_passed = nil,
	time_passed = nil,

	impact_attack_range = nil,


	vfo = nil,
	fx_magnetic_stone = nil,

	fx_magnetic_stone_name = nil,
	fx_stone_destroy_name = nil,
}
magnetic_stone_class.mt = { __index = magnetic_stone_class }
function magnetic_stone_class:new(parent_class, index)
	local obj = {}
	setmetatable(obj, self.mt)
	-- 기본 정보
	obj.parent_class = parent_class
	obj.owner = parent_class.character

	-- 드랍할 위치의 절대 index. 3번이면 3번 자리에만 드랍됨. 순서 아님. drop_zone_index 기준으로 모두 매핑 되어있음.
	obj.index = index
	obj.has_magnet = false

	obj.vfo_hitbox_pivot = parent_class.vfo_hitbox_pivot
	obj.vfo_hitbox_size = parent_class.vfo_hitbox_size

	obj.falling_init_velocity = parent_class.falling_init_velocity
	obj.falling_acceleration = parent_class.falling_acceleration
	obj.fall_duration = parent_class.fall_duration
	obj.fall_height = parent_class.fall_height

	obj.current_velocity = parent_class.falling_init_velocity

	obj.state = parent_class.stone_state
	obj.current_state = parent_class.stone_state.prepare

	obj.time_passed = 0
	obj.fall_time_passed = 0.0

	-- 공격 범위
	obj.impact_attack_range = parent_class:get_impact_attack_range(index)

	-- 떨어진 바위 가상 필드 오브젝트
	obj.vfo = obj:create_vfo(index)
	obj.fx_magnetic_stone = nil
	obj.fx_impact = nil
	obj.fx_destroy = nil

	self.fx_normal_stone_name = parent_class.fx_normal_stone_name    --바위 fx
	self.fx_magnetic_stone_name = parent_class.fx_magnetic_stone_name    --바위 fx
	self.fx_stone_destroy_name = parent_class.fx_stone_destroy_name        -- 낙하 충격 vfx

	-- 낙하 데미지
	self.impact_damage_calculator = parent_class.impact_damage_calculator
	self.impact_damage_modifier = parent_class.impact_damage_modifier
	self.impact_knockback_force = parent_class.impact_knockback_force

	return obj
end
function magnetic_stone_class:set_drop_position(drop_pos)
	self.start_pos = drop_pos + vector_util.up * self.parent_class.fall_height
	self.destination_pos = vector_util.get_x0z(drop_pos)
	self.current_position = self.start_pos
	self.vfo.Position = vector_util.get_x0z(drop_pos)

end
function magnetic_stone_class:is_droped()
	return self.current_state > self.state.prepare
end

-- state change
function magnetic_stone_class:change_state(next_state)
	if next_state == self.current_state then
		return
	end

	if self.current_state == self.state.prepare then
	end

	-- enter
	if next_state == self.state.prepare then	-- 기본 정보 세팅후 언제든 낙하 처리가 가능한 상태.
		self.is_activated = false
		self.has_magnet = false
		self.vfo.ActiveState = CS.Oak.ActiveState.Disabled

	elseif next_state == self.state.falling then	-- 낙하 시작
		self:create_stone_fx()
		self:attack_range_start(self.impact_attack_range, self.destination_pos, self.fall_duration)

	elseif next_state == self.state.landing then	--착지하는 순간 데미지를 준다.
		self:create_impact_fx()
		self:give_impact_damage()
		self.vfo.ActiveState = CS.Oak.ActiveState.Enabled
		self:attack_range_hide(self.impact_attack_range)

		music_player_util.play_sfx_one_shot(self.parent_class.sfx_stone_landing_name)

		if self.has_magnet == true then
			self.field_magnet_obj.transform.parent = self.parent_class.magent_origin_parent
			self.field_magnet_obj.Position = self.destination_pos + vector(0, self.parent_class.magnet_offset, 0)
			CS.Oak.UIQuestMarkersController.Instance:AddQuestMarkerToIFO('magnetic_obj', 0, false, self.field_magnet_obj)
		end

	elseif next_state == self.state.action then		--충격파 시작

	elseif next_state == self.state.stanby then
		self.is_activated = true
		self.parent_class:on_stone_install(self.index)

	else

	end

	self.time_passed = 0
	self.current_state = next_state
end


-------- Update --------
function magnetic_stone_class:update_frame(dt)
	if self.current_state == nil or self.current_state <= self.state.prepare then return end
	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.falling then
		self:update_position(dt)    -- 낙하 위치를 갱신한다

	elseif self.current_state == self.state.landing then
		self:change_state(self.state.action)

	elseif self.current_state == self.state.action then
			self:change_state(self.state.stanby)
	end
end
function magnetic_stone_class:update_position(dt)
	-- 지면에 도달하면
	if self.time_passed >= self.fall_duration then
		if self.fx_magnetic_stone ~= nil then
			CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx_magnetic_stone, self.destination_pos, vector_util.zero)    --정확한 드랍존 위치로 바위를 옮긴다.
		end
		self:change_state(self.state.landing)    -- 착륙상태로 변경
		return
	end

	if self.fx_magnetic_stone ~= nil then
		local parabola_value = (self.time_passed / self.fall_duration) -- 낙하하는 포물선 그래프
		local current_height = (1 - parabola_value) * self.fall_height
		local current_pos = self.destination_pos + current_height * vector_util.up
		CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx_magnetic_stone, current_pos, vector_util.zero)
	end
end
-------- create --------
function magnetic_stone_class:create_vfo(idx)
	local vfo = CS.Oak.VirtualFieldObject()
	vfo.Name = string.format('%s', 'magnetic_stone_' .. idx)
	vfo.EntityGroup = CS.Oak.EntityGroups.Neutral
	vfo.Hitbox = CS.Oak.Hitbox(self.vfo_hitbox_pivot, self.vfo_hitbox_size)
	vfo.ActiveState = CS.Oak.ActiveState.Disabled
	return vfo
end

function magnetic_stone_class:create_stone_fx()
	if self.fx_magnetic_stone == nil then
		if self.has_magnet == true then
			self.fx_magnetic_stone = self.parent_class.fx_normal_stone_pool:Instantiate(self.start_pos)    -- 자성 오브젝트 찾아두기

			-- 퀘스트 마커 표시
			if self.field_magnet_obj == nil then
				self.field_magnet_obj = get_field_object('magnetic_obj')
			end

			self.field_magnet_obj.Position = self.destination_pos
			self.field_magnet_obj.transform.parent = self.fx_magnetic_stone.transform
			self.field_magnet_obj.transform.position = vector(0,self.parent_class.magnet_offset, 0)
		else
			self.fx_magnetic_stone = self.parent_class.fx_normal_stone_pool:Instantiate(self.start_pos)
		end
	end
end
function magnetic_stone_class:create_impact_fx()
	self.fx_impact = self.parent_class.fx_stone_impact_pool:Instantiate(self.destination_pos)
end
-- clear fx
function magnetic_stone_class:clear_stone_fx()
	if self.fx_magnetic_stone ~= nil then
		self.fx_magnetic_stone:Dispose()
	end
	self.fx_magnetic_stone = nil
end
function magnetic_stone_class:clear_stone_destory_fx()
	if self.fx_magnetic_stone_destroy ~= nil then
		self.fx_magnetic_stone_destroy:Dispose()
	end
	self.fx_magnetic_stone_destroy = nil

	if self.sfx_magnetic_stone_destroy ~= nil then
		self.sfx_magnetic_stone_destroy:Dispose()
	end
	self.sfx_magnetic_stone_destroy = nil
end
-------- Damage --------
function magnetic_stone_class:give_impact_damage()
	if not self.impact_damage_calculator.IsStarted then
		self.impact_damage_calculator:Start()
	end

	self.impact_damage_calculator.Position = self.destination_pos
	local objects = self.impact_damage_calculator:UpdateFrame(0)
	for index = 0, objects.Count - 1 do
		local field_object = objects[index]
		if field_object ~= nil and battle_util.is_hittable_target(self.owner, field_object) then
			self:publish_impact_damage_info(field_object)
		end
	end
	objects:Dispose()
	self.impact_damage_calculator:End()
end

function magnetic_stone_class:publish_impact_damage_info(field_object)
	local knockback_direction = direction_util.to_4way_vector3(field_object.Direction) * -1
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Melee
	damage_info.sender = self.owner
	damage_info.target = field_object
	damage_info.modifier = self.impact_damage_modifier
	damage_info.direction = knockback_direction
	damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
	damage_info.knockBackDirection = knockback_direction
	damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.impact_knockback_force
	command_util.publish_damage(damage_info)
end

-- 공격 범위 관련
function magnetic_stone_class:attack_range_start(attack_range, pos, duration)
	if attack_range ~= nil then
		attack_range_util.setup_by_position(attack_range, pos, 0)
		attack_range:Show(duration)
		message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.owner, attack_range))
	end
end
function magnetic_stone_class:attack_range_hide(attack_range)
	if attack_range ~= nil then
		attack_range:Hide()
		message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.owner, attack_range))
	end
end

-- 초기화
function magnetic_stone_class:clear()
	self:change_state(self.state.prepare)

	self:clear_stone_fx()
	self:clear_stone_destory_fx()

	self:attack_range_hide(self.impact_attack_range)
end
-- 바위 파괴 (이펙트도 출력되고 충격파도 살려줌)
function magnetic_stone_class:destroy(cause)
	if self.has_magnet == true then
		self.has_magnet = false
	end
	-- play stone destroy fx
	self.parent_class.fx_magnetic_stone_destroy_pool:Instantiate(self.destination_pos)

	self:change_state(self.state.prepare)

	self:clear_stone_fx()

	self:attack_range_hide(self.impact_attack_range)

	-- cuase가 붙어있는 경우는 보통 각 패턴에 의해 뽀개질때 이다(한번에 리스트 순회하며 뽀개는거 아닐때)
	-- 순회하며 뽀개는 경우 해당 부분에서 소리 재생을 하자(한번만 재생하기 위해)
	if cause == 'drill' then
		music_player_util.play_sfx({ sfx_name = self.parent_class.sfx_stone_destroy_by_drill_name,
									 loop = false, type_priority = 'event',
									 player_priority = 'default',
									 play_pos = self.destination_pos })
	end

	if cause == 'charge' then
		music_player_util.play_sfx({ sfx_name = self.parent_class.sfx_stone_destroy_name,
									 loop = false, type_priority = 'event',
									 player_priority = 'default',
									 play_pos = self.destination_pos })
	end
end
function magnetic_stone_class:force_destroy()
	self:destroy()
end
function magnetic_stone_class:dispose()
	if self.vfo ~= nil then
		self.vfo.ActiveState = CS.Oak.ActiveState.Disabled
		self.vfo = nil
	end

	if self.fx_magnetic_stone ~= nil then
		self.fx_magnetic_stone:Dispose()
		self.fx_magnetic_stone = nil
	end

	self.action = nil
	self.cs_action = nil

	self.start_pos = nil
	self.destination_pos = nil

	self.impact_attack_range = nil
	self.state = nil
	self.current_state = nil
	self.current_position = nil
	self.fx_magnetic_stone = nil
	self.field_magnet_obj = nil

	self.vfo = nil
end

--################################################################################
local laser_class = {
	parent_class = nil,
	start_pos = nil,
	end_pos = nil,

	preaction_time = nil,
	postaction_time = nil,

	length_type = nil,
	damage_calculator = nil,
	fx_laser = nil,
	index = nil
}
laser_class.mt = {__index = laser_class}
function laser_class:new(parent_class)
	local obj = {}
	setmetatable(obj, laser_class.mt)
	obj.parent_class = parent_class
	obj.damage_calculator = nil

	obj.start_stone = nil
	obj.end_stone = nil

	obj.start_pos = nil
	obj.end_pos = nil

	obj.preaction_time = parent_class.laser_preaction_time
	obj.postaction_time = parent_class.laser_postaction_time

	obj.fx_laser_pool = parent_class.laser_pool
	obj.fx_laser = nil

	obj.state = parent_class.laser_state
	obj.current_state = parent_class.laser_state.none
	obj.time_passed = 0
	return obj
end

function laser_class:change_state(next_state)
	if next_state == self.current_state then
		return
	end

	-- enter
	if next_state == self.state.prepare then

	elseif next_state == self.state.action then
		self:start_area_collision()
		self:fx_laser_on()
	elseif next_state == self.state.post then
		self:stop_area_collision()
		self:fx_laser_off()
	elseif next_state == self.state.none then
	end

	self.time_passed = 0
	self.current_state = next_state
end

function laser_class:start(start_stone, end_stone)
	self.start_stone = start_stone
	self.end_stone = end_stone

	self.start_pos = vector_util.get_x0z(start_stone.destination_pos)
	self.end_pos = vector_util.get_x0z(end_stone.destination_pos)
	local diff = self.end_pos - self.start_pos
	self.distance = vector_util.magnitude(diff)
	self.direction = vector_util.normalized(diff)

	local size = vector(self.distance, self.parent_class.laser_height, self.parent_class.laser_width)
	local collision_info = collision_info_util.create_rotatable_cube(size, nil, self.parent_class.laser_damage_term, true)
	self.damage_calculator = CS.Oak.AreaBattleCollision(self.parent_class.character, collision_info)

	area_collision_util.set_position(self.damage_calculator, self.start_pos)
	area_collision_util.set_direction(self.damage_calculator, self.direction)

	self:change_state(self.state.prepare)
end
function laser_class:stop()
	self:change_state(self.state.post)
	self.start_stone = nil
	self.end_stone = nil
end
function laser_class:update_frame(dt)
	if self.current_state == self.state.none then return end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.prepare then
		if self.time_passed > self.preaction_time then
			self:change_state(self.state.action)
		end

	elseif self.current_state == self.state.action then
		self:update_area_collision(dt)

	elseif self.current_state == self.state.post then
		if self.time_passed > self.postaction_time then
			self:change_state(self.state.none)

		end
	end
end

-- fx start/end
function laser_class:fx_laser_on()
	self.fx_laser = self.parent_class.fx_laser_pool:Instantiate(self.start_pos)
	-- 시작점과 끝 좌표에 대해 레이저 이펙트 길이 크기 조정.
	local diff = self.start_pos - self.end_pos
	local magnitude = vector_util.magnitude(diff)
	self.fx_laser.transform.localScale = vector(magnitude / 20, 1, 1)

	CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx_laser, self.start_pos + self.parent_class.laser_fence_offsetY, self.direction + self.parent_class.laser_fence_offsetY)

	music_player_util.play_sfx_one_shot(self.parent_class.sfx_laser_fence_on_name)
end
function laser_class:fx_laser_off()
	if self.fx_laser ~= nil then
		self.fx_laser:Dispose()
	end
	self.fx_laser = nil
end

-- 충돌체 판정 시작/종료/업데이트
function laser_class:start_area_collision()
	if self.damage_calculator.is_started == true then return end
	area_collision_util.start(self.damage_calculator)
end
function laser_class:stop_area_collision()
	if self.damage_calculator.is_started == false then
		return
	end
	area_collision_util.calc_end(self.damage_calculator)
end
function laser_class:update_area_collision(dt)
	if not area_collision_util.is_started(self.damage_calculator) then
		area_collision_util.start(self.damage_calculator)
	end

	local targets = area_collision_util.update(self.damage_calculator, dt)
	for _, target in pairs(targets) do
		self:give_laser_damage(target)
	end
end

function laser_class:give_laser_damage(field_object)
	local knockback_direction = direction_util.to_4way_vector3(field_object.Direction) * -1
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Melee
	damage_info.sender = self.parent_class.character
	damage_info.target = field_object
	damage_info.modifier = self.parent_class.laser_damage_modifier
	damage_info.direction = knockback_direction
	damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
	damage_info.knockBackDirection = knockback_direction
	damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.parent_class.laser_knockback_force
	command_util.publish_damage(damage_info)
end

function laser_class:dispose()
	self.start_pos = nil
	self.end_pos = nil

	if self.fx_laser ~= nil then
		self.fx_laser:Dispose()
	end
	self.fx_laser = nil
	self.scaling_effect = nil
	self.start_stone = nil
	self.end_stone = nil
end
--################################################################################
function local_class:init(cs_controller)
    self.cs_controller = cs_controller
	-- 상태 관련
	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}
	self.stone_state = {
		none = 1,
		prepare = 2, -- pool에서 대기중인 상태
		falling = 3, -- 떨어지는 중
		landing = 4, -- 착지함
		action = 5, -- 충격파 발생
		stanby = 6,		-- 낙뢰 드랍 대기
	}
	self.laser_state = {
		none = 1,
		prepare = 2,
		action = 3,
		post = 4
	}
	self.phase = {
		none = 0,
		one = 1,
		two = 2
	}
	self.length_type = {
		short = 1,
		middle = 2,
		long = 3
	}
	self.mode = {
		one = 1,
		two = 2
	}

	local a = vector(1,1,1)

	require('base/battle_init')
	_G.init()
	command_util = _G.command_util
	vector_util = _G.vector_util
	self:init_data()

	-- 컨트롤러 소지 캐릭터
	self.character = nil

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_receive_custom_event')

	-- 낙하 위치와 자석 범위
	self.stones = {}
	-- 공격 범위
	self.impact_attack_ranges = {}

	self.active_lasers = {}
	self.active_laser_attackranges = {}

	self.current_progress = self.progress.none
	self.current_phase = self.phase.none

	self.current_stone_count = 0		-- 필드 내에 존재하는 모든 자성 바위 수
	self.installed_stone_count = 0		-- 땅에 떨어지고 빵빵 터져서 완전히 설치가 완료된 자성 바위

	self.laser_count = 1
	self.initialized = false

	self.order_by_drop_indexes = {}
	self.drop_order_count = 0
	self.max_magnet_count = 0
	self.magnet_life_time = 35
	self.current_magnet_life_time = 0.0
	self.laser_fence_offsetY = vector(0, 0.6, 0)
	self.exist_magnet_in_field = false

	self.magnet_drop_state = false

	self.is_qte_activated = false

	self.current_mode = self.mode.one

	self.bomb_explosion_pool = unity_object_pool.GetOrCreate('FX_Explosion_Bomb_new');

end
function local_class:init_data()
	if self.initialized == true then
		return
	end
	self.initialized = true

	self.stage_data = require('stageeventcontrollers/MagneticStoneControllerData.lua')
	self.data = self.stage_data[stage.Name]
	if self.data == nil then
		self.data = self.stage_data['magnetic_stone_default']    --더미 겸 최초 데이터
	end

	self.drop_distance = self.data.drop_distance
	self.drop_interval = self.data.drop_interval

	self.magnet_offset = self.data.magnet_offset
	self.stone_angle = self.data.stone_angle

	self.vfo_hitbox_pivot = vector(self.data.vfo_hitbox_pivot[1], self.data.vfo_hitbox_pivot[2], self.data.vfo_hitbox_pivot[3])
	self.vfo_hitbox_size = vector(self.data.vfo_hitbox_size[1], self.data.vfo_hitbox_size[2], self.data.vfo_hitbox_size[3])

	self.falling_init_velocity = self.data.falling_init_velocity
	self.falling_acceleration = self.data.falling_acceleration
	self.fall_duration = self.data.fall_duration
	self.fall_height = self.data.fall_height

	self.magnet_life_time = self.data.magnet_life_time

	self.impact_radius = self.data.impact_radius
	self.impact_damage_modifier = self.data.impact_damage_modifier
	self.impact_knockback_force = self.data.impact_knockback_force

	--펜스
	self.laser_preaction_time = self.data.laser_preaction_time
	self.laser_postaction_time = self.data.laser_postaction_time

	self.laser_width = self.data.laser_width
	self.laser_height = self.data.laser_height

	self.laser_damage_modifier = self.data.laser_damage_modifier
	self.laser_knockback_force = self.data.laser_knockback_force
	self.laser_damage_term = self.data.laser_damage_term

	self.laser_fence_offsetY = vector(0, self.data.laser_fence_offsetY, 0)

	-- fx
	self.fx_normal_stone_name = self.data.fx_normal_stone_name
	self.fx_magnetic_stone_name = self.data.fx_magnetic_stone_name

	self.fx_stone_destroy_name = self.data.fx_stone_destroy_name


	self.fx_laser_name = self.data.fx_laser_name

	-- sfx
	self.sfx_stone_landing_name = self.data.sfx_stone_landing_name
	self.sfx_stone_destroy_name = self.data.sfx_stone_destroy_name
	self.sfx_stone_destroy_by_drill_name = self.data.sfx_stone_destroy_by_drill_name
	self.sfx_laser_fence_on_name = self.data.sfx_laser_fence_on_name

	self.laser_pattern1 = self.data.laser_pattern1
	self.laser_pattern2 = self.data.laser_pattern2
	self.laser_pattern3 = self.data.laser_pattern3

	self.stone_offset_list1 = self.data.stone_offset_list1
	self.stone_offset_list2 = self.data.stone_offset_list2
	self.magnetic_drop_ignore_indexes = self.data.magnetic_drop_ignore_indexes
end

function local_class:init_battle_enter(e)
	self.character = get_character(e:GetParamAt(1))
	self.current_battle_zone = battle_util.get_zone(self.character.Position)

	self.max_stone_count = tonumber(e:GetParamAt(2))
	self.drop_count_at_once = tonumber(e:GetParamAt(3))
	self.drop_order_count = tonumber(e:GetParamAt(4))
	self.max_magnet_count = tonumber(e:GetParamAt(5))
	local phase = tonumber(e:GetParamAt(6))
	self:phase_change(phase)
	local offsets = { 0, 0, 0 }

	if self.current_phase == self.phase.one then
		self.stone_offset_list = self.stone_offset_list1
		self.laser_pattern_check_box = self.data.laser_pattern_check_box1
		offsets = self.data.center_pos_offset1
	else
		self.laser_pattern_check_box = self.data.laser_pattern_check_box2
		self.stone_offset_list = self.stone_offset_list2
		offsets = self.data.center_pos_offset2
	end



	self.current_progress = self.progress.playing
	--stage_camera:ResizeTo(7,0.8)
	-- 낙하 범위 피격 피해
	local impact_collision_info = collision_info_util.create_sphere(self.impact_radius, 1, -1)
	self.impact_damage_calculator = CS.Oak.AreaBattleCollision(self.character, impact_collision_info, false, 0, 0)

	-- 바위를 모자른 만큼 생성한다.
	local stone_pool_count = #self.stones
	if stone_pool_count < self.max_stone_count then
		for idx = stone_pool_count + 1 , self.max_stone_count do
			local magnetic_stone = magnetic_stone_class:new(self, idx)
			table.insert(self.stones, magnetic_stone)
		end

	elseif stone_pool_count > self.max_stone_count then -- 이미 생성된 바위수가 최대 바위보다 더 많은 경우
		-- 뒤에서부터 그 차이만큼 찾아서 지운다.
	end

	self.center_pos_offset = vector(offsets[1], offsets[2], offsets[3])
	local center_pos = self.current_battle_zone.Bounds.center + vector(0, -0.5, 0) + self.center_pos_offset
	local drop_zone_angle = 360 / self.max_stone_count
	self.laser_pattern_check_zone = CS.UnityEngine.Bounds(vector_util.get_x0z(center_pos), vector(self.laser_pattern_check_box[1], 0, self.laser_pattern_check_box[2]))

	-- 바위들의 드랍 위치 재조정
	for idx = 1, #self.stones do
		local rotation = (unity_class.quaternion.AngleAxis(drop_zone_angle * idx + self.stone_angle, vector_util.up) * vector_util.forward).normalized
		local offset = vector(0,0,0)
		if #self.stone_offset_list >= idx then
			offset = self.stone_offset_list[idx]
		end
		local drop_position = center_pos + rotation * self.drop_distance + vector(offset[1], 0, offset[2])
		local magnetic_stone = self.stones[idx]:set_drop_position(drop_position)
	end

	-- 어택 레인지 풀 모자란 만큼 추가 생성
	for idx = stone_pool_count + 1, self.max_stone_count do
		-- 낙하 위치
		local impact_attack_range = CS.AttackRange.CreateCircle(vector_util.zero, self.impact_radius, CS.Oak.AttackRangeShowType.OverlayForward)
		impact_attack_range:Hide()
		table.insert(self.impact_attack_ranges, impact_attack_range)
	end

	-- 레이저 펜스 충돌체
	self:create_laser_collisions()

	-- 자성 오브젝트 찾아두기
	if self.field_magnet_obj == nil then
		self.field_magnet_obj = get_field_object('magnetic_obj')
		self.magent_origin_parent = self.field_magnet_obj.transform.parent
	end

	self.manual_character = party_manager.UserParty.Leader
end

function local_class:battle_end()
	self.current_progress = self.progress.none
end

function local_class:create_laser_collisions()
	-- 길이 유형은 드랍 위치를 꼭지점으로, 각 꼭지점마다의 중복되는 길이들을 유형화 한것이다.
	-- (length_type = 1 = 1번 index와 2번 index 사이의 길이)
	-- (length_type = 3 = 1번 index와 4번 index 사이의 길이)

	-- 1. N각형에서 몇개의 대각선 유형이 필요한지 계산한다.
	self.length_type_count = math.floor(self.max_stone_count / 2)
	local is_odd_number = self.max_stone_count % 2 ~= 0
	local angle = 360/self.max_stone_count

	local sample_points = {}
	local sample_lengths = {}

	-- 2. 대각선 유형별 길이를 샘플링 하기 위해 N각형에 대한 더미 좌표를 모은다. 대충 절반 넘어가는 꼭지점은 중복임으로 필요 없다.
	for idx = 1, (self.length_type_count + 1) do
		local rotation = (unity_class.quaternion.AngleAxis(angle * idx + angle/2, vector_util.up) * vector_util.forward).normalized
		local point = rotation * self.drop_distance		--각 꼭지점의 좌표
		sample_points[idx] = point
	end

	-- 3. 기준 꼭지점으로부터 각 위치의 꼭지점 거리를 계산하여 대각선 길이들을 구한다.
	local start_pos = sample_points[1]
	local end_pos = vector_util.zero

	for idx = 1, self.length_type_count do
		end_pos = sample_points[idx + 1]
		local diagonal_length = vector_util.distance(start_pos, end_pos)
		sample_lengths[idx] = diagonal_length
	end

	-- 4. 대각선 길이 유형별로 충돌체를 만들고 이를 캐싱해둔다.
	-- 캐싱된 정보는 laser_pool[길이유형][n개]
	self.laser_pool = {}

	local laser_distance = sample_lengths[length_type]
	local laser_size = vector(0, self.laser_height, self.laser_width)

	self.laser_pool = {}

	for idx = 1, 20 do
		local collision_info = collision_info_util.create_rotatable_cube(laser_size, nil, self.laser_damage_term, true)
		local laser = laser_class:new(self)

		table.insert(self.laser_pool, laser)
		laser.index = self.laser_count
		self.laser_count = self.laser_count + 1
	end
end

function local_class:phase_change(next_phase)
	if self.current_phase == next_phase then return end

	if next_phase == self.phase.two then

	end
	self.current_phase = next_phase
end

function local_class:change_mode(next_mode)
	if self.current_mode == next_mode then
		return
	end

	if self.current_mode == self.mode.one then
	elseif self.current_mode == self.mode.two then
	else
	end

	if next_mode == self.mode.one then

	elseif next_mode == self.mode.two then

	else
	end

	self.current_mode = next_mode
end

-------- Update Frame --------
function local_class:use_late_update_frame(e)
    return true
end
function local_class:late_update_frame(dt)
    if self.current_progress ~= self.progress.playing then return true end

	self:update_magnetic_stone(dt)
	self:update_laser(dt)
end

-- 바위들 업데이트
function local_class:update_magnetic_stone(dt)
	if self.stones == nil or #self.stones < 1 then
		return
	end

	for idx = 1, #self.stones do
		local stone = self.stones[idx]
		if stone ~= nil and stone.current_state ~= self.stone_state.none then
			stone:update_frame(dt)
		end
	end
end
-- 레이저 업데이트
function local_class:update_laser(dt)
	if self.active_lasers == nil or #self.active_lasers < 1 then
		return
	end

	for idx = 1, #self.active_lasers do
		local laser = self.active_lasers[idx]
		if laser ~= nil then
			laser:update_frame(dt)
		end
	end
end

function local_class:notify_create_stone(index)
    message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'magnetic_stone_created' }))
end

--  바위가 설치됨
function local_class:on_stone_install(idx)
	self:notify_create_stone()
	self.installed_stone_count = self.installed_stone_count + 1
end

-------- Create or Destory --------
function local_class:create_magnetic_stone(drop_order_count)
	if self:is_stone_full_in_field() == false then
		return
	end

	-- 드랍 가능한 위치를 수집한다
	-- TODO: 2페이즈 보스가 이동할때 낙하지점에 있는지 확인하는 코드 추가 필요
	local droppable_idxs = {}
	local magnetic_stone_count = 0
	for idx = 1, #self.stones do
		local magnetic_stone = self.stones[idx]
		if magnetic_stone ~= nil and magnetic_stone.current_state == self.stone_state.prepare then
			table.insert(droppable_idxs, idx)
		end
	end

	-- 가능한 위치중 2개를 무작위로 선정한다.
	local selected_idxs = {}
	for idx = 1, drop_order_count do --self.drop_count_at_once do
		-- 떨어뜨리다가 중단 사유가 발생하면 중단한다.
		if self:is_stone_full_in_field() == false then return end

		if droppable_idxs == nil or #droppable_idxs < 1 then
			return
		end

		local random_idx = math.floor(unity_class.random.Range(1, #droppable_idxs + 1))    --선택된 랜덤 인덱스, 한번 선택할때마다 목록이 줄어든다.
		local drop_zone_idx = droppable_idxs[random_idx]                            --드랍 가능 슬롯의 1 ㅁ 4 ㅁ
		table.remove(droppable_idxs, random_idx)

		local stone = self.stones[drop_zone_idx]
		if stone ~= nil then
			-- 필드에 자석이 하나도 없다면 바위에 자석을 심어준다.
			if self.magnet_drop_state == true and self.exist_magnet_in_field == false then
				if self:is_match_ignore_magnet_stone(stone.index) == false then
					stone.has_magnet = true
					self.exist_magnet_in_field = true
				end
			end


			stone:change_state(self.stone_state.falling)


			self.current_stone_count = self.current_stone_count + 1
		end
	end
end
function local_class:is_match_ignore_magnet_stone(index)
	for _,ignore_idx in pairs(self.magnetic_drop_ignore_indexes) do
		if ignore_idx == index then
			return true
		end
	end
	return false
end

function local_class:is_stone_full_in_field()
	-- 필드내 바위가 가득 찼다. 드랍하지 않는다.
	local stone_in_field = self.current_stone_count
	-- 가득 찼다면 그만 떨군다.
	if stone_in_field >= self.max_stone_count then
		return false
	end

	return true
end

function local_class:destroy_magnetic_stone(stone_index, cause)
    local magnetic_stone = self.stones[stone_index]
    if magnetic_stone == nil then
        return
    end

	-- 이미 부셔졌는데 또 부수라는 명령 방지
	if magnetic_stone.current_state == self.stone_state.prepare or magnetic_stone.current_state == self.stone_state.none then
		return
	end

	if magnetic_stone.has_magnet and self.magnet_drop_state == true then
		if self.field_magnet_obj == nil then
			self.field_magnet_obj = get_field_object('magnetic_obj')
		end

		if self.field_magnet_obj ~=nil then
			self.field_magnet_obj.transform.parent = self.magent_origin_parent
			self.field_magnet_obj.Position = magnetic_stone.destination_pos
			message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'magnet_created' }))
		end
	end

    magnetic_stone:destroy(cause)
    self.current_stone_count = self.current_stone_count - 1
	self.installed_stone_count = self.installed_stone_count - 1

	local custom_event = CS.Oak.CustomStageEvent.Create(self.character, { 'magnetic_stone_destroyed' })
	message_system:SendSync(self.character, custom_event)

	self:disable_unlinked_fence()
end

--현재 활성중인 레이저를 모두 순회하면서 비활성 시켜야하는지 확인하는 로직 (아무리 많이 돌아도 6번임)
function local_class:disable_unlinked_fence()
	if self.active_lasers == nil or #self.active_lasers < 1 then
		return
	end

	local actived_laser_count = #self.active_lasers

	for idx = actived_laser_count, 1, -1 do
		local laser = self.active_lasers[idx]
		-- 레이저의 양 끝단을 검사후 비활성화 시켜야한다면 꺼버리고 반환한다.
		if laser.start_stone.is_activated == false or laser.end_stone.is_activated == false then
			if laser ~= nil then
				laser:stop()

				local atk_range = self.active_laser_attackranges[idx]
				if atk_range ~= nil then
					message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.character, atk_range))
				end

				self:release_laser(laser)
			end
			table.remove(self.active_lasers, idx)
			table.remove(self.active_laser_attackranges, idx)
		end
	end
end

-- 공격 범위 획득(풀 아님 그냥 idx기준으로 고정해서 가져옴)
function local_class:get_impact_attack_range(idx)
	if self.impact_attack_ranges == nil then
		self.impact_attack_ranges = {}
	end

	if #self.impact_attack_ranges < idx then
		for index = #self.impact_attack_ranges, idx do
			local attack_range = CS.AttackRange.CreateCircle(vector_util.zero, self.impact_radius, CS.Oak.AttackRangeShowType.OverlayForward)
			attack_range:Hide()
			table.insert(self.impact_attack_ranges, attack_range)
		end
	end

	return self.impact_attack_ranges[idx]
end


-- 레이저 풀에서 획득/반환 (idx기준 고정 불가능해서 풀로 만듦)
function local_class:get_laser()
	if self.laser_pool == nil or #self.laser_pool < 1 then return nil 	end
	local last_idx = #self.laser_pool
	local laser = self.laser_pool[last_idx]
	if laser == nil then return nil end

	table.remove(self.laser_pool, last_idx)
	return laser
end

function local_class:release_laser(laser)
	if self.laser_pool == nil then
		return
	end

	table.insert(self.laser_pool, laser)
end


-- 펜스 재연결 및 초기화
function local_class:fence_reconnect()
	self:clear_all_laser()

	local check_pattern = self:get_laser_pattern()

	for _, pair in pairs(check_pattern) do
		local connectable_idxs = pair

		-- 모두 연결한다
		for idx = 1, #connectable_idxs do
			local start_idx = connectable_idxs[idx]
			local end_idx = connectable_idxs[idx + 1]
			-- idx가 마지막 꺼면 순환형태로 만들기 위해 마지막꺼는 첫 idx로 만들어줌
			if idx == #connectable_idxs then
				end_idx = connectable_idxs[1]
			end

			-- 2개인 경우는 하나만 만들어버린다.
			if #connectable_idxs > 2 or idx < 2then
				if self.stones[start_idx].is_activated == true and self.stones[end_idx].is_activated then

					local start_pos = self.stones[start_idx].destination_pos
					local end_pos = self.stones[end_idx].destination_pos

					local length_type = math.abs(start_idx - end_idx)
					if length_type >= self.length_type_count then
						length_type = #self.stones - length_type
					end

					--레이저 설정
					local laser = self:get_laser()
					if laser ~= nil then
						laser:start(self.stones[start_idx], self.stones[end_idx])
						table.insert(self.active_lasers, laser)
						--레이저 리스크맵 등록
						local atk_range_size = unity_class.vector2(laser.distance, self.laser_width)
						local attackrange = CS.Oak.VirtualAttackRange.CreateRect(unity_class.vector3.zero, laser.distance, self.laser_width, 0)

						if attackrange ~= nil then
							local dir = vector_util.normalized(end_pos - start_pos)
							battle_range_util.setup_by_direction(attackrange, start_pos, dir)
							message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.character, attackrange))
							table.insert(self.active_laser_attackranges, attackrange)
						end
					end
				end
			end
		end
	end
end

function local_class:get_laser_pattern()
	if self.manual_character == nil then
		self.manual_character = party_manager.UserParty.Leader
	end
	if self.manual_character == nil then
		return self.laser_pattern1
	end

	local player_pos = self.manual_character.Position
	local is_in_check_zone = self.laser_pattern_check_zone:Contains(player_pos)

	if self.current_mode == self.mode.two or self.current_phase == self.phase.two then
		local connectable_idxs = {}
		for idx = 1, #self.stones do
			local magnetic_stone = self.stones[idx]
			if magnetic_stone ~= nil and magnetic_stone.is_activated == true then
				table.insert(connectable_idxs, idx)
			end
		end
		local pattern = {}
		table.insert(pattern, connectable_idxs)
		return pattern
	else
		if is_in_check_zone == true then
			return self.laser_pattern2
		else
			return self.laser_pattern1
		end
	end
end


function local_class:clear_all_laser()
	if self.active_lasers == nil or #self.active_lasers < 1 then return end

	local actived_laser_count = #self.active_lasers

	for idx = actived_laser_count, 1 , -1 do
		local laser = self.active_lasers[idx]
		local atk_range = self.active_laser_attackranges[idx]

		if laser ~= nil then
			laser:stop()

			if atk_range ~= nil then
				message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.character, atk_range))
			end

			self:release_laser(laser)
		end
		table.remove(self.active_lasers, idx)
		table.remove(self.active_laser_attackranges, idx)
	end
end
function local_class:destroy_magnet()
	if self.exist_magnet_in_field == true then
		self.exist_magnet_in_field = false
		CS.Oak.UIQuestMarkersController.Instance:RemoveQuestMarker('magnetic_obj')

		local manual_character = party_manager.UserParty.Leader
		local leader_state = manual_character.CharacterBehaviour.CurrentActionState
		if lua_helper.type_compare(leader_state, CS.Oak.CharacterHoldUpState) then
			local held = manual_character.CharacterBehaviour.CurrentActionState.HoldTarget
			character_util.clear_holdup_state(user_party.Leader, held)
		end

		if self.field_magnet_obj == nil then
			self.field_magnet_obj = get_field_object('magnetic_obj')
		end

		self.bomb_explosion_pool:Instantiate(self.field_magnet_obj.Position)

		if self.field_magnet_obj ~= nil then
			self.field_magnet_obj.Position = vector(999, 0, 999)
			message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(self.field_magnet_obj))
		end


		self.current_magnet_life_time = 0
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'magnet_destroyed' }))
	end
end
-- util
function local_class:get_index_from_name(name)
	local string_cnt = string.len(name)
	local idx = tonumber(string.sub(name, string_cnt, string_cnt))
	return idx

end
-- 필드위 모든 자성바위 관련 요소를 제거한다.
function local_class:destroy_all_stone()
	if self.stones == nil then
		return
	end

	for idx = 1, #self.stones do
		local stone = self.stones[idx]
		if stone ~= nil and stone:is_droped() == true then
			stone:destroy(nil)
		end
	end
	self:clear_all_laser()

	music_player_util.play_sfx({ sfx_name = self.sfx_stone_destroy_name,
								 loop = false, type_priority = 'event',
								 player_priority = 'default',
								 play_pos = self.current_battle_zone.Bounds.center })

	self.current_stone_count = 0
	self.installed_stone_count = 0
	CS.Oak.UIQuestMarkersController.Instance:RemoveQuestMarker('magnetic_obj')
end

function local_class:load_resource()
    return util.cs_generator(self.on_load_resource, self)
end
function local_class:on_load_resource()

    self.data = self.stage_data[stage.Name]
    if self.data == nil then
        self.data = self.stage_data['magnetic_stone_default']
    end
    if self.data ~= nil then
        self.fx_normal_stone_name = self.data.fx_normal_stone_name
        self.fx_magnetic_stone_name = self.data.fx_magnetic_stone_name

		self.fx_normal_stone_destroy_name = self.data.fx_normal_stone_destroy_name
		self.fx_magnetic_stone_destroy_name = self.data.fx_magnetic_stone_destroy_name

		self.fx_stone_impact_name = self.data.fx_stone_impact_name

        self.fx_laser_name = self.data.fx_laser_name
    end

    -- 오브젝트 풀 미리 로드
    self.fx_normal_stone_pool = unity_object_pool.GetOrCreate(self.fx_normal_stone_name)
	self.fx_magnetic_stone_pool = unity_object_pool.GetOrCreate(self.fx_magnetic_stone_name)

	self.fx_normal_stone_destroy_pool = unity_object_pool.GetOrCreate(self.fx_normal_stone_destroy_name)
	self.fx_magnetic_stone_destroy_pool = unity_object_pool.GetOrCreate(self.fx_magnetic_stone_destroy_name)

	self.fx_stone_impact_pool = unity_object_pool.GetOrCreate(self.fx_stone_impact_name)

	self.fx_laser_pool = unity_object_pool.GetOrCreate(self.fx_laser_name)

    return
end
function local_class:need_on_launch()
    return false
end
function local_class:on_launch(_)
end
function local_class:dispose()
	self:dispose_data()
	self.cs_controller = nil
	-- 상태 관련
	self.progress = nil
	self.stone_state = nil
	self.laser_state = nil
	self.phase = nil
	self.length_type = nil

	self.character = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	-- 낙하 위치와 자석 범위
	self.stones = nil
	-- 공격 범위
	self.impact_attack_ranges = nil

	self.active_lasers = nil
	self.active_laser_attackranges = nil

	self.laser_fence_offsetY = nil


	if self.fx_normal_stone_pool ~= nil then
		self.fx_normal_stone_pool:Dispose()
		self.fx_normal_stone_pool = nil
	end
	if self.fx_magnetic_stone_pool ~= nil then
		self.fx_magnetic_stone_pool:Dispose()
		self.fx_magnetic_stone_pool = nil
	end

	if self.fx_normal_stone_destroy_pool then
		self.fx_normal_stone_destroy_pool:Dispose()
		self.fx_normal_stone_destroy_pool = nil
	end
	if self.fx_magnetic_stone_destroy_pool ~= nil then
		self.fx_magnetic_stone_destroy_pool:Dispose()
		self.fx_magnetic_stone_destroy_pool = nil
	end

	if self.fx_stone_impact_pool ~= nil then
		self.fx_stone_impact_pool:Dispose()
		self.fx_stone_impact_pool = nil
	end

	if self.fx_laser_pool ~= nil then
		self.fx_laser_pool:Dispose()
		self.fx_laser_pool = nil
	end

	_G.finish()
	self.center_pos_offset = nil
	self.current_battle_zone = nil
	self.field_magnet_obj = nil
	self.fx_magnetic_stone_destroy_name = nil
	self.fx_normal_stone_destroy_name = nil
	self.fx_stone_impact_name = nil

	if self.impact_damage_calculator ~= nil then
		self.impact_damage_calculator:End()
		self.impact_damage_calculator = nil
	end

	self.stone_offset_list = nil
	self.stone_offset_list1 = nil
	self.stone_offset_list2 = nil
	self.laser_pattern1 = nil
	self.laser_pattern2 = nil
	self.laser_pattern3 = nil
	self.laser_pattern_check_box = nil
	self.laser_pattern_check_zone = nil

	if self.laser_pool ~= nil then
		if #self.laser_pool > 0 then
			for _, laser in pairs(self.laser_pool) do
				laser:dispose()
			end
		end
		self.laser_pool = nil
	end
	self.magent_origin_parent = nil
	self.magnetic_drop_ignore_indexes = nil
	self.manual_character = nil
	self.mode = nil
	self.bomb_explosion_pool = nil
end

function local_class:dispose_data()
	self.stage_data = nil
	self.data = nil

	self.magnet_offset = nil

	self.vfo_hitbox_pivot = nil
	self.vfo_hitbox_size = nil

	self.laser_fence_offsetY = nil

	-- fx
	self.fx_normal_stone_name = nil
	self.fx_magnetic_stone_name = nil

	self.fx_stone_destroy_name = nil

	self.fx_laser_name = nil

	self.sfx_stone_landing_name = nil
	self.sfx_stone_destroy_name = nil
	self.sfx_stone_destroy_by_drill_name = nil
	self.sfx_laser_fence_on_name = nil
end

-------- 메세지 이벤트 수신 및 발송 --------
function local_class:on_receive_custom_event(e)
	if e:GetParamAt(0) == 'magnetic_stone_create_request' then
		local param1 = e:GetParamAt(1)
		local stone_count = 1
		if param1 ~= nil then
			local value = tonumber(param1)
			if value ~= nil then
				stone_count = value
			end
		end

		self:create_magnetic_stone(stone_count)

	elseif e:GetParamAt(0) == 'magnetic_stone_destroy_request' then
		local stone_name = e:GetParamAt(1)
		if stone_name == nil then
			return
		end
		local index = self:get_index_from_name(stone_name)
		if index == nil or index < 1 then
			return
		end

		local cause = e:GetParamAt(2)
		self:destroy_magnetic_stone(index, cause)

	elseif e:GetParamAt(0) == 'magnetic_stone_init' then
		self.is_qte_activated = false
		self:init_battle_enter(e)

	elseif e:GetParamAt(0) == 'magnetic_stone_battle_end' then
		self.is_qte_activated = false
		self:destroy_all_stone()
		self:battle_end()

	elseif e:GetParamAt(0) == 'boss_magwi_qte_prepare' then
		self.is_qte_activated = true
		self:clear_all_laser()

	elseif e:GetParamAt(0) == 'boss_magwi_qte_success' then
		self.is_qte_activated = false

	elseif e:GetParamAt(0) == 'boss_magwi_qte_fail' then
		self.is_qte_activated = false

	elseif e:GetParamAt(0) == 'magwi_phase2_event' then
		self.is_qte_activated = false
		self:phase_change(self.phase.two)

	elseif e:GetParamAt(0) == 'magnet_drop_on' then
		self.magnet_drop_state = true
		self:destroy_all_stone()


	elseif e:GetParamAt(0) == 'magnet_drop_off' then
		self.magnet_drop_state = false
		self.is_qte_activated = false
		self:destroy_all_stone()
		-- 혹시 타이밍이나 그런 문제로 자석이 해제 안되는걸 방지하고자 한번 더 해제한다.
		self:destroy_magnet()

	elseif e:GetParamAt(0) == 'magwi_mode2_start' then
		self:change_mode(self.mode.two)

	elseif e:GetParamAt(0) == 'magwi_mode2_end' then
		self:change_mode(self.mode.one)
		self:destroy_magnet()

	elseif e:GetParamAt(0) == 'boss_magwi_get_remain_stones' then
		-- 타이밍 보장하기 위해 sync
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(self.character, { 'boss_magwi_remain_stones', tostring(self.current_stone_count) }))

	elseif e:GetParamAt(0) == 'boss_magwi_active_fence' then
		self:fence_reconnect()

	elseif e:GetParamAt(0) == 'boss_magwi_destroy_all_stone' then
		self:destroy_all_stone()
	end
end


return {
    create = function(cs_controller, scene)
        return local_class(cs_controller, scene)
    end
}
