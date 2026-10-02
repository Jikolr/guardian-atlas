local local_class = newclass('TowerEarth45Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.laser_patten = {
		horizontal = 1,
		vertical = 2,
		cross = 3
	}

	self.laser_direction = {
		horizontal = 1,
		vertical = 2
	}

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index)
		return get_field_object('tower_laser_' .. index)
	end

	-- 레이저 기믹 존
	self.get_laser_loop_zone = function(index)
		return field:GetZone('laser_zone_' .. index)
	end

	-- 레이저 기믹의 상태
	-- none : 시작 전 / start : 시작 / game_over : 게임오버 됬을 때 / finish : 전투가 끝났을 때
	self.gimmick_state = { none = 1, start = 2, disabled = 3, game_over = 4, finish = 5 }

	-- 현재 기믹 상태 초기화
	self.current_gimmick_state = self.gimmick_state.none

	-- 현재 레이저 루틴이 돌아가고 있는가?
	self.is_running_laser_gimmick = false

	-- 기믹 루틴 겹치지 않기 위한 방지용
	self.is_active_gimmick_routine = false

	self.damage_type = CS.Oak.DamageType.Melee

	-- 체스트 박스 터지는 이팩트 이름
	self.explosion_effect_name = 'FX_explosion_small'

	self.stage_data = require('stageeventcontrollers/TowerEarth45Data.lua')

	self.buff_table = {
		-- 밀리 이뮨 버프 스펙
		{
			name = 'elite_melee_damage_immune',
			effect = 'FX_Abnormal_Immune_Physic'
		},
		-- 원거리 이뮨 버프 스펙
		{
			name = 'elite_projectile_damage_immune',
			effect = 'FX_Abnormal_Immune_Physic_yellow'
		}
	}

	--레이저 기믹의 데미지 타입
	self.damage_type = CS.Oak.DamageType.Melee

	-- 몇번째 버프가 실행중인가에 대한 값 1 ~ max 값은 #self.buff_table  이 될듯.
	self.buff_count = 1

	-- 현재 들어간 존을 세팅한다.
	self.current_zone = nil

	-- 레이저 진행방향
	self.direction_value = 1

	-- 현재 스테이지 정보
	self.current_stage_info = nil

	-- 현재 기믹 페이즈
	self.current_phase = 1

	-- 현재 레이저 패턴
	self.current_laser_patten = nil

	-- 현재 레이저 방향
	self.current_laser_dir = nil

	-- 현재 레이저 이팩트 타입
	self.current_laser_effect_type = 1

	-- 현재 레이저 스피드
	self.laser_speed = 0

	-- 레이저 부활 시간
	self.revive_time = 0

	-- 보스케릭터
	self.target_boss = nil

	-- phase HpRatio list
	self.phase_hp_list = nil

	--다음사이클의 레이저 변경점이 있는지?
	self.is_change_laser_patten = false

	--다음사이클 레이저 정보
	self.next_patten_info = nil

	-- 레이저 왕복이 완료 되었는지?
	self.is_finish_laser_cycle = false

	self.laser_move_count = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')


	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_data[stage.Name]

	self.revive_time = self.current_stage_info.phase_info[self.current_phase].revive_time
	self.target_boss = get_character(self.current_stage_info.boss_name)
	self.laser_speed = self.current_stage_info.phase_info[self.current_phase].speed

	--phase변경 파라메터
	if self.current_stage_info.phase_hp_rate ~= nil then
		local phase_count = #self.current_stage_info.phase_hp_rate

		self.phase_hp_list = {}
		for i = 1, phase_count do
			local phase_hp = self.current_stage_info.phase_hp_rate[i]
			table.insert(self.phase_hp_list, phase_hp)
		end
	end

	unity_object_pool.GetOrCreate(self.explosion_effect_name)
	-- 필요 값들 초기화
	-- 이펙트 프리로드
	-- 로드 안해두고 했더니 시작시에 이펙트 안나오는 문제가 있어서 미리 생성해둠.
	unity_object_pool.GetOrCreate(self.buff_table[1].effect)
	unity_object_pool.GetOrCreate(self.buff_table[2].effect)
end

function local_class:on_stage_start_event(e)
	-- 캐릭터 버프 루틴 시작
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.begin_buff, self))
	-- 스테이지 시작 시 레이저의 데미지타입을 변경해준다.
	self:init_laser()
end

-- 초기화 루틴 수정
function local_class:init_laser()
	self.lasers = {}
	self.zone = self.get_laser_loop_zone(1)
	self.zone_bound = self.zone.Bounds
	self.current_laser_patten = self:get_laser_pattren(self.current_stage_info.phase_info[1].patten)
	self.current_laser_dir = self:get_laser_dir_for_patten(self.current_laser_patten)
	self.damage_type = self:get_damage_type(self.current_laser_dir)
	self.current_laser_effect_type = {}
	table.insert(self.current_laser_effect_type, self:get_laser_effect_type(self.current_stage_info.horizon_effect_type))
	table.insert(self.current_laser_effect_type, self:get_laser_effect_type(self.current_stage_info.vertical_effect_type))

	local gimmick_count_in_zone = 2
	-- 초기 레이저 기믹에 대한 세팅
	for i = 1, gimmick_count_in_zone do
		local laser = self.get_chest_box(i)
		laser.Position = self:get_laser_position(self.current_laser_dir, i)
		laser.ActiveState = active_state('enabled')
		laser.FieldObjectBehaviour:PauseLaserEffect()
		laser.FieldObjectBehaviour:ChangeLaserType(self:get_laser_effect_type_for_direction())
		laser.FieldObjectBehaviour:SetDamageType(self.damage_type)
		table.insert(self.lasers, laser)
	end
end

function local_class:get_laser_pattren(patten)
	local laser_pattren
	if patten == 'horizontal' then
		laser_pattren = self.laser_patten.horizontal
	elseif patten == 'vertical' then
		laser_pattren = self.laser_patten.vertical
	elseif patten == 'cross' then
		laser_pattren = self.laser_patten.cross
	end

	return laser_pattren
end

function local_class:get_laser_effect_type_for_direction()
	if self.current_laser_dir == self.laser_direction.horizontal then
		return self.current_laser_effect_type[1]
	else
		return self.current_laser_effect_type[2]
	end
end

function local_class:get_laser_effect_type(type)
	local laser_effect_type
	if type == 'purple' then
		laser_effect_type = 1
	elseif type == 'blue' then
		laser_effect_type = 2
	elseif type == 'yellow' then
		laser_effect_type = 3
	else
		laser_effect_type = 1
	end

	return laser_effect_type
end

function local_class:set_laser_for_phase(phase)
	self.zone = self.get_laser_loop_zone(1)
	self.zone_bound = self.zone.Bounds
	local laser_patten = self:get_laser_pattren(self.current_stage_info.phase_info[phase].patten)
	local laser_dir = self:get_laser_dir_for_patten(laser_patten)
	local revive_time = self.current_stage_info.phase_info[phase].revive_time
	local laser_speed = self.current_stage_info.phase_info[phase].speed

	--현재 레이저 사이클이 끝나면 다음패턴의 파라메터값을 넣어줘야된다.
	local laser_pos = {}
	for _,v in pairs(self.lasers) do
		local pos = self:get_laser_position(laser_dir, _, true)
		table.insert(laser_pos, pos)
	end

	self.is_change_laser_patten = true

	self.next_patten_info = {
		laser_dir = laser_dir,
		revive_time = revive_time,
		laser_pos = laser_pos,
		laser_speed = laser_speed,
		laser_patten = laser_patten
	}
end

function local_class:get_laser_dir_for_patten(patten)
	if patten == self.laser_patten.horizontal or patten == self.laser_patten.cross then
		return self.laser_direction.horizontal
	elseif patten == self.laser_patten.vertical then
		return self.laser_direction.vertical
	end
end

function local_class:get_laser_position(dir, index, is_start_laser)
	local laser_dir = unity_class.vector3.zero
	local dir_value = self.direction_value
	if is_start_laser ~= nil then
		dir_value = 1
	end
	if dir == self.laser_direction.horizontal then
		if index == 1 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(-self.zone_bound.extents.x * dir_value , 0, self.zone_bound.extents.z))
		elseif index == 2 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(-self.zone_bound.extents.x * dir_value, 0, -self.zone_bound.extents.z))
		end
	elseif dir == self.laser_direction.vertical then
		if index == 1 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(-self.zone_bound.extents.x, 0, -self.zone_bound.extents.z * dir_value))
		elseif index == 2 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(self.zone_bound.extents.x, 0, -self.zone_bound.extents.z * dir_value))
		end
	end

	return laser_dir
end

function local_class:get_laser_destination(dir, index)
	local laser_dir = unity_class.vector3.zero
	if dir == self.laser_direction.horizontal then
		if index == 1 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(self.zone_bound.extents.x * self.direction_value , 0, self.zone_bound.extents.z))
		elseif index == 2 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(self.zone_bound.extents.x * self.direction_value, 0, -self.zone_bound.extents.z))
		end
	elseif dir == self.laser_direction.vertical then
		if index == 1 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(-self.zone_bound.extents.x, 0, self.zone_bound.extents.z * self.direction_value))
		elseif index == 2 then
			laser_dir = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
					vector(self.zone_bound.extents.x, 0, self.zone_bound.extents.z * self.direction_value))
		end
	end

	return laser_dir
end

function local_class:on_zone_enter_event(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
	local zone_name = e.Zone.Name

	--현재의 존이름이 지정되어있는 존 이름과 같다면
	for i = 1, #self.current_stage_info.gimmick_start_zone_names do
		if zone_name == self.current_stage_info.gimmick_start_zone_names[i] then
			self.current_zone = e.Zone
			--기믹이 시작되지 않았을때 시작하도록 함.
			if self.current_gimmick_state == self.gimmick_state.none then
				self.current_gimmick_state = self.gimmick_state.start
				self.is_running_laser_gimmick = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_update_routine, self))

				return true
			end
		end
	end

	return false
end

function local_class:gimmick_update_routine()
	local time_passed = 0
	while(true) do
		if not self.is_active_gimmick_routine then
			if self.current_gimmick_state == self.gimmick_state.disabled then
				time_passed = time_passed + unity_class.time.deltaTime
				if time_passed > self.revive_time then
					self.current_gimmick_state = self.gimmick_state.start
					self.is_running_laser_gimmick = true
					time_passed = 0
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
				end
			end
		end
		coroutine.yield(nil)
	end
end
-- 게임오버 됬을 때 기믹 루프를 꺼준다.
function local_class:on_game_over_event(e)
	-- 레이저 기믹을 더이상 돌지 않게 하고
	-- current_gimmick_state를 game_over로 변경한다.
	self.is_running_laser_gimmick = false
	self.current_gimmick_state = self.gimmick_state.game_over
	return true
end

-- 보스의 체력에 따라 페이즈 전환
function local_class:on_damage_event(e)
	if self.target_boss == nil then return end

	if e:GetType() == typeof(CS.Oak.DamageEvent) then
		if lua_helper.reference_equals(self.target_boss, e.Info.target) then
			if self.phase_hp_list ~= nil and self.current_phase <= #self.phase_hp_list then
				if self.target_boss.CharacterStatsBehaviour.HpRatio * 100 < self.phase_hp_list[self.current_phase] then
					self.current_phase = self.current_phase + 1
					self:set_laser_for_phase(self.current_phase)
				end
			end
		end
	end

	return false
end

-- 전투가 끝났을 때 레이저 기믹꺼지도록
function local_class:on_battle_group_eliminated_event(e)
	-- 보스와의 전투가 끝날 때 레이저 기믹을 disabled 해준다.
	-- FIXME: 터지는 연출이라면 이팩트 재생 후 사라지게 해야할 것
	for i = 1, #self.current_stage_info.battle_end_group_names do
		if e.BattleGroupName == self.current_stage_info.battle_end_group_names[i] then
			self.current_gimmick_state = self.gimmick_state.finish
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_chest_box, self, self.gimmick_state.finish))
		end
	end

	return true
end

function local_class:get_damage_type(laser_dir)
	local damage_type = CS.Oak.DamageType.Trap

	if laser_dir == self.laser_direction.horizontal then
		if self.current_stage_info.horizon_damage_type == 'Melee' then
			damage_type = CS.Oak.DamageType.Melee
		elseif self.current_stage_info.horizon_damage_type == 'Projectile' then
			damage_type = CS.Oak.DamageType.Projectile
		end
	elseif laser_dir == self.laser_direction.vertical then
		if self.current_stage_info.vertical_damage_type == 'Melee' then
			damage_type = CS.Oak.DamageType.Melee
		elseif self.current_stage_info.vertical_damage_type == 'Projectile' then
			damage_type = CS.Oak.DamageType.Projectile
		end
	end

	return damage_type
end

function local_class:disabled_chest_box(state)
	--기믹 작동중이 아니라면...
	if not self.is_running_laser_gimmick then return end

	self.is_running_laser_gimmick = false
	self.current_gimmick_state = state

	-- chest 1에서 레이저롤 쏘고 있으니 1에서 이팩트 Deactive
	if  self.current_gimmick_state == self.gimmick_state.disabled then
		self.lasers[1].FieldObjectBehaviour:PauseLaserEffect()
	elseif self.current_gimmick_state == self.gimmick_state.finish then
		self.lasers[1].FieldObjectBehaviour:DeactiveLaserEffect()
	end

	music_player_util.play_sfx_one_shot('02_explosion_water_01')
	-- 각 박스 좌표에서 폭발 이팩트 재생
	unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(self.lasers[1].Position)
	unity_object_pool.GetOrCreate(self.explosion_effect_name):Instantiate(self.lasers[2].Position)

	-- 0.25초 딜레이 후
	wait_for_sec(0.25)

	-- disabled 상태에서는 동작이 끝나지 않았으나 필드에서 보이지 않아야 하므로 enabled 에서 visible 을 뺀 infield 로 변경한다.
	if  self.current_gimmick_state == self.gimmick_state.disabled then
		self.lasers[1].ActiveState = active_state('infield')
		self.lasers[2].ActiveState = active_state('infield')
	elseif self.current_gimmick_state == self.gimmick_state.finish then
		-- 체스트 박스들 Disabled
		self.lasers[1].ActiveState = active_state('disabled')
		self.lasers[2].ActiveState = active_state('disabled')
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

	while #self.lasers < 0 do
		coroutine.yield(nil)
	end
	self.is_active_gimmick_routine = true

	self.lasers[1].ActiveState = active_state('enabled')
	self.lasers[2].ActiveState = active_state('enabled')

	-- 레이저 1번에서 레이저를 사용..
	self.lasers[1].FieldObjectBehaviour.DamageRate = self.current_stage_info.phase_info[self.current_phase].damage
	self.lasers[1].FieldObjectBehaviour:SetDamageType(self.damage_type)
	self.lasers[1].FieldObjectBehaviour:ResumeLaserEffect()
	self.lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true

	local sfx_loop = music_player_util.play_sfx({ sfx_name = '02_light_laser_loop_01', loop = true,
	                                              type_priority = 'gimmick', player_priority = 'player', fade_in_time = 2 })

	local move_progress_time = 0
	local move_time = self:get_laser_move_time()

	while self.is_running_laser_gimmick do
		-- 레이저 기믹 박스 위치 세팅
		local dt = unity_class.time.deltaTime
		local final_pos1 = self.lasers[1].Position
		local final_pos2 = self.lasers[2].Position
		local destination1 = final_pos1
		local destination2 = final_pos2

		destination1 = self:get_laser_destination(self.current_laser_dir, 1)
		destination2 = self:get_laser_destination(self.current_laser_dir, 2)

		local movement = dt * self.laser_speed * 3

		local diff1 = vector_util.get_x0z(destination1 - self.lasers[1].Position, 0)
		local diff2 = vector_util.get_x0z(destination2 - self.lasers[2].Position, 0)

		-- 존의 반대쪽까지 도달하면 레이저 기믹의 방향이 변경된다.
		if movement > 0 then
			if vector_util.magnitude(diff1) > movement then
				final_pos1 = vector_util.normalized(diff1) * movement
				final_pos2 = vector_util.normalized(diff2) * movement

				self.lasers[1].Position = vector_util.get_x0z(self.lasers[1].Position + final_pos1, 0)
				self.lasers[2].Position = vector_util.get_x0z(self.lasers[2].Position + final_pos2, 0)
			end
		end

		coroutine.yield(nil)

		if vector_util.magnitude(diff1) < 0.09 and vector_util.magnitude(diff2) <0.09  then
			self.direction_value = self.direction_value * -1
			break
		end

		move_progress_time = move_progress_time + dt
		if move_progress_time > move_time then
			self.direction_value = self.direction_value * -1
			break
		end
	end
	sfx_loop:Stop()

	-- 레이저 체크 활성화 해제
	self.lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = false
	self.is_active_gimmick_routine = false

	--오브젝트 폭파
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.disabled_chest_box, self, self.gimmick_state.disabled))

	self.laser_move_count = self.laser_move_count + 1
	if self.current_laser_patten == self.laser_patten.cross then
		if self.laser_move_count % 2 == 1 then
		else
			self:change_laser_dir()
		end
	end
	--변경할 패턴이 있다면 새로 셋팅을 해준다.
	if self.is_change_laser_patten then
		self:change_laser_patten()
		self.is_change_laser_patten = false
	end
end

function local_class:get_laser_move_time()
	if self.current_laser_dir == self.laser_direction.horizontal then
		return self.zone_bound.size.x / (self.laser_speed * 3)
	elseif self.current_laser_dir == self.laser_direction.vertical then
		return self.zone_bound.size.z / (self.laser_speed * 3)
	end

	return self.zone_bound.size.x / (self.laser_speed * 3)
end

function local_class:change_laser_patten()
	if self.current_gimmick_state == self.gimmick_state.finish then
		return
	end

	self.lasers[1].Position = self.next_patten_info.laser_pos[1]
	self.lasers[2].Position = self.next_patten_info.laser_pos[2]
	self.current_laser_patten = self.next_patten_info.laser_patten
	self.current_laser_dir = self.next_patten_info.laser_dir
	self.lasers[1].FieldObjectBehaviour:ChangeLaserType(self:get_laser_effect_type_for_direction())
	self.lasers[2].FieldObjectBehaviour:ChangeLaserType(self:get_laser_effect_type_for_direction())
	self.damage_type = self:get_damage_type(self.current_laser_dir)
	self.revive_time = self.next_patten_info.revive_time
	self.laser_speed = self.next_patten_info.laser_speed
	self.direction_value = 1
	self.laser_move_count = 0
	self.next_patten_info = nil
end

function local_class:change_laser_dir()
	if self.current_gimmick_state == self.gimmick_state.finish then
		return
	end

	local dir = self.current_laser_dir

	if self.current_laser_dir == self.laser_direction.horizontal then
		dir = self.laser_direction.vertical
	elseif self.current_laser_dir == self.laser_direction.vertical then
		dir = self.laser_direction.horizontal
	end

	self.current_laser_dir = dir
	for i = 1, 2 do
		self.lasers[i].Position = self:get_laser_position(dir, i)
		self.lasers[i].FieldObjectBehaviour:ChangeLaserType(self:get_laser_effect_type_for_direction())
	end

	self.damage_type = self:get_damage_type(dir)
	self.direction_value = 1
end

-- 파티원들에게 버프 실행
function local_class:begin_buff()
	--target_name : 플레이어
	--buff_table : 버프 정보테이블
	for i = 0, user_party.Characters.Count -1 do
		local target_name = user_party.Characters[i].Name
		local triggered_event = util.cs_generator(self.repeat_apply_withdraw, self, target_name)
		coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
	end
end

-- 일정 간격으로 버프를 키고, 끄고 반복하는 루틴.
function local_class:repeat_apply_withdraw(target_name)
	local cool_time = self.current_stage_info.buff_initial_waiting_duration
	local activation_duration = self.current_stage_info.buff_activation_duration
	local target = get_character(target_name)
	while true do
		-- 해당 캐릭터가 필드 내에 존재해야함.
		if target == nil then return end
		cool_time = cool_time - unity_class.time.deltaTime
		--쿨타임이 다 되었으면 실행함.
		if cool_time <= 0 then
			-- 버프를 실행
			self:activate_buff_for_seconds(target, self.buff_table[self.buff_count])
			cool_time = self.current_stage_info.buff_waiting_duration - activation_duration
		end

		coroutine.yield(nil)
	end
end

function local_class:activate_buff_for_seconds(target, buff_data)
	-- 실행 후 일정 시간이 지나면 버프를 해제하는 루틴
	local buff_spec_name = buff_data.name
	buff_manager:AddBuff(target, CS.Oak.EquipmentSlot.None, target, buff_spec_name, 0, false, false)

	local effect_pool = unity_object_pool.GetOrCreate(buff_data.effect)
	local target_scale = (target.Hitbox.size.x > 1) and target.Hitbox.size.x or 1
	local pooled_effect = effect_pool:Instantiate(target.Position, unity_class.quaternion.identity, target.transform)
	pooled_effect.transform.localScale = unity_class.vector3(target_scale, 1, target_scale)

	--발동 시간동안 대기
	wait_for_sec(self.current_stage_info.buff_activation_duration)
	buff_manager:RemoveBuff(target, CS.Oak.EquipmentSlot.None, target, buff_spec_name)
	pooled_effect:Dispose()

	--버프 꺼졌을때 이거 해야 할듯.. 다음 버프로 세팅하기 위함.
	self.buff_count = self.buff_count + 1
	if self.buff_count > #self.buff_table then
		self.buff_count = 1
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self.current_stage_info = nil
	self.stage_data = nil
	self.is_running_laser_gimmick = false
	self.lasers = nil
	self.zone = nil
	self.zone_bound = nil
	self.cs_controller = nil
	self.current_laser_patten = nil
	self.current_laser_dir = nil
	self.target_boss = nil
	self.phase_hp_list = nil
	self.next_patten_info = nil
	self.current_laser_effect_type = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
