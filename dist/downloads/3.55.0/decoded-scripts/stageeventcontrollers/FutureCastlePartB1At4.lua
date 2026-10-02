local local_class = newclass("FutureCastlePartB1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 공주
	self.princess = nil

	-- 숨길 열쇠 이름 리스트
	self.secret_key_name_list = { '1', '2' }

	-- 숨길 열쇠 리스트
	self.hidden_key_list = nil

	-- 거대 열쇠
	self.left_key = nil

	-- 로레인 스위치 눌린 개수 체크
	self.check_lorain_switch = 0

	-- 금 간 벽 데미지 횟수
	self.cracked_wall_damage_num = 0

	-- 마법진 이름 리스트
	self.magiccircle_name_list = { 'magiccircle_a', 'magiccircle_b', 'magiccircle_c', 'magiccircle_d', 'magiccircle_e',
	                               'magiccircle_f', 'magiccircle_g', 'magiccircle_h' }

	-- 마법진 이펙트 리스트
	self.magiccircle_effect_list = nil

	-- 마법진 위치 리스트
	self.magiccircle_pos_list = { vector(-0.5, 0, 69.5), vector(75.5, 0, 111.5),
	                              vector(94.5, 0, 109.5), vector(5.5, 0, 76.5),
	                              vector(21.5, 0, 84.5), vector(-6.5, 0, -16.5),
	                              vector(5.5, 0, -16.5), vector(59.5, 0, 86.5) }

	-- 숨길 마법진 인덱스 리스트
	self.secret_magiccircle_index_list = { 2, 5 }

	-- 숨길 마법진을 막고 있는 오브젝트 이름 리스트, 해당 오브젝트의 NamedData가 true면 로드 시점에 마법진을 활성화한다.
	self.hide_magiccircle_obj_name_list = { 'magiccircle_b_rock', 'magiccircle_e_rock' }

	-- 마법진으로 워프 중인지 저장
	self.warp_magiccircle = false

	-- 현재 로레인 머리가 밖에 나와 있는지 저장
	self.is_lorain_head_out = false

	-- 문에 포커스 갔는지 저장
	self.is_focus_on_door = false

	-- 말 걸 수 있는 로레인의 상태 플래그 리스트
	self.lorain_clone_switch_flag_list = { true, true, true, true }

	-- 로레인 회전 상태 리스트
	self.lorain_clone_switch_direction_list = { 'up', 'right', 'down', 'left' }

	-- 인베이더들에게 들켰는지 저장
	self.is_detected = false

	-- 거대 열쇠의 원래 위치
	self.left_key_origin_pos = nil

	-- 기타 상수
	self.key_num = 2
	self.lorain_clone_switch_num = 4

	-- 타일맵 NPC 이름
	self.princess_name = 'princess'

	-- 타일맵의 필드오브젝트 이름
	self.secret_key_name = 'key_'
	self.lorain_clone_switch_name = 'lorain_clone_switch'
	self.left_gate_name = 'left_gate'
	self.left_key_name = 'left_key'
	self.cracked_wall_name = 'cracked_wall'
	self.puzzle_cracked_wall_name = 'puzzle_cracked_wall'
	self.lorain_head_name = 'lorain_head'
	self.switch_lorain_clone_name = 'switch_lorain_clone_'
	self.hidden_key_door_name = 'lorain_gate'
	self.hidden_key_door_switch_name = 'lorain_gate_switch'

	self.right_name = '_right'
	self.left_name = '_left'
	self.up_name = '_up'
	self.down_name = '_down'

	-- 타일맵 존 이름

	-- 타일맵 마커 이름
	self.invader_respawn_marker_name = 'invader_respawn'
	self.magiccircle_out_marker_name = '_out'

	-- 배틀 그룹 이름
	self.battle_group_name = 'battle_1'

	-- 틴트 이름
	self.tint_key_name = 'futurecastle_2_3'

	-- 커스텀 이벤트 이름
	self.detected_event = 'detected_by_invader'
	self.lorain_head_out_event = 'lorain_head_out'
	self.lorain_head_in_event = 'lorain_head_in'

	-- 커스텀 Stage 스테이트 번호

	-- 오브젝트 풀 이름
	self.magiccircle_effect_preset = 'MagicCircle_AppearIdle'
	self.reset_effect_preset = 'FX_reset_object'
	self.cracked_wall_effect_preset = 'FX_Common_SmokeScreen'
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.magiccircle_effect_preset)
	unity_object_pool.GetOrCreate(self.reset_effect_preset)
	unity_object_pool.GetOrCreate(self.cracked_wall_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	self.princess = get_character(self.princess_name)

	self.left_key = get_field_object(self.left_key_name)
	self.left_key_origin_pos = self.left_key.Position

	return
end

function local_class:need_on_launch()
	local main_quest_id = 195
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return (main_quest ~= nil and (main_quest.InnerProgress == 9))
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.princess = nil

	self.secret_key_name_list = nil

	self.hidden_key_list = nil

	self.magiccircle_effect_list = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ThrowEvent) then
		self:on_throw_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DoorOpenedEvent) then
		self:on_door_opened_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		self:on_switch_on_off_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		self:on_damage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- 열쇠 숨기기, 크기 조절
	for i = 1, #self.secret_key_name_list do
		stage_util.set_fo_active_state(self.secret_key_name .. self.secret_key_name_list[i], 'disabled')
	end

	for i = 1, self.key_num do
		get_field_object(self.secret_key_name .. i).Transform.localScale = unity_class.vector3.one * 0.8
	end

	-- 마법진 설정
	self.magiccircle_effect_list = create_generic_list(CS.Oak.PooledUnityObject)

	for i = 1, #self.magiccircle_pos_list do
		local hide = false

		for j = 1, #self.secret_magiccircle_index_list do
			if i == self.secret_magiccircle_index_list[j] and
					not stage_progress:GetNamedData(self.hide_magiccircle_obj_name_list[j], false) then
				hide = true

				break
			end
		end

		if not hide then
			local cur_magiccircle = unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
					self.magiccircle_pos_list[i])
			cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

			self.magiccircle_effect_list:Add(cur_magiccircle)
		else
			self.magiccircle_effect_list:Add(nil)
		end
	end

	-- 게이트 기본 애니메이션 실행, 열려 있으면 실행 X
	local cur_gate = get_field_object(self.left_gate_name)
	local animator = cur_gate:GetComponent(typeof(CS.UnityEngine.Animator))

	local door_behaviour = cur_gate.FieldObjectBehaviour

	if door_behaviour ~= nil and not door_behaviour.Opened then
		animator:Play('idle', -1)
	else
		cur_gate.Interactable = CS.Oak.NonInteractable.Instance
	end

	-- 로레인 회전 상태 처리
	for i = 1, self.lorain_clone_switch_num do
		-- 맞는 상태만 남기고 전부 비활성화
		self:activate_dir_clone(self.lorain_clone_switch_direction_list[i], i)
	end

	-- 금 간 벽 부순 적 있는지 확인 후 파괴
	if stage_progress:GetNamedData(self.cracked_wall_name) then
		local cracked_wall = get_field_object(self.cracked_wall_name)

		cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
		cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

		cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		cracked_wall.Interactable = CS.Oak.NonInteractable.Instance
	end

	if stage_progress:GetNamedData(self.puzzle_cracked_wall_name) then
		local cracked_wall = get_field_object(self.puzzle_cracked_wall_name)

		cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
		cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

		cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	-- 메인 퀘스트 InnerProgress가 12 이상이면 로레인 클론 반응 ON
	-- 그 외에는 메인 퀘스트가 처리할 것
	local main_quest_id = 195
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil and main_quest.InnerProgress >= 12 then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'lorain_clone_reaction_true' }))
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	local zone_name = e.Zone.Name

	for i = 1, #self.magiccircle_name_list do
		if zone_name == self.magiccircle_name_list[i] then
			if self.magiccircle_effect_list[i - 1] ~= nil and not self.warp_magiccircle then
				self.warp_magiccircle = true

				sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, zone_name)
			end
		end
	end
end

function local_class:on_interact_event(e)
	for i = 1, self.lorain_clone_switch_num do
		local cur_clone = get_field_object(
				self.switch_lorain_clone_name..i..'_'..self.lorain_clone_switch_direction_list[i])

		if lua_helper.reference_equals(e.Target, cur_clone) then
			-- 클론이 달려가는 중에는 이벤트 발생 X
			if self.lorain_clone_switch_flag_list[i] then
				self:rotate_lorain_clone(cur_clone, i)
			end

			break
		end
	end
end

function local_class:on_throw_event(e)
	if lua_helper.reference_equals(e.Target, self.left_key) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.check_left_key, self))
	end
end

function local_class:on_door_opened_event(e)
	if e.DoorHandleName == self.left_gate_name then
		local cur_gate = get_field_object(self.left_gate_name)

		cur_gate.Interactable = CS.Oak.NonInteractable.Instance
	end
end

function local_class:on_switch_on_off_event(e)
	if string.find(e.SwitchObject.Name, self.lorain_clone_switch_name) then
		local key = get_field_object(self.secret_key_name .. 2)

		-- 한 번이라도 스위치 4개 누르게 하면 이벤트 다시 실행하지 않음
		if self.check_lorain_switch ~= self.lorain_clone_switch_num and not key.FieldObjectBehaviour.IsGetted then
			if e.IsTurningOn then
				self.check_lorain_switch = self.check_lorain_switch + 1

				if self.check_lorain_switch == self.lorain_clone_switch_num then
					sp_util.play_normal_screenplay(self.activate_key_event, self, key, 1)
				end
			else
				self.check_lorain_switch = self.check_lorain_switch - 1
			end
		end
	elseif not self.is_focus_on_door and e.SwitchObject.Name == self.hidden_key_door_switch_name and
			lua_helper.reference_equals(e.Stepper, user_party_leader) then
		self.is_focus_on_door = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.focus_hidden_key_door, self))
	end
end

function local_class:on_damage_event(e)
	local require_damage_type = CS.Oak.DamageType.Explosion
	local cracked_wall = get_field_object(self.cracked_wall_name)

	if not stage_progress:GetNamedData(self.cracked_wall_name) and
			lua_helper.reference_equals(e.Info.target, cracked_wall) then
		if e.Info.type & require_damage_type == require_damage_type then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_cracked_wall, self))
		end
	end

	local puzzle_cracked_wall = get_field_object(self.puzzle_cracked_wall_name)

	if not stage_progress:GetNamedData(self.puzzle_cracked_wall_name) and
			lua_helper.reference_equals(e.Info.target, puzzle_cracked_wall) then
		if e.Info.type & require_damage_type == require_damage_type then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.destroy_cracked_wall, self, self.puzzle_cracked_wall_name))
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for i = 1, #self.hide_magiccircle_obj_name_list do
		if lua_helper.reference_equals(e.FieldObject, get_field_object(self.hide_magiccircle_obj_name_list[i])) then
			local secret_magiccircle_index = self.secret_magiccircle_index_list[i]

			local cur_magiccircle = unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
					self.magiccircle_pos_list[secret_magiccircle_index])
			cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

			self.magiccircle_effect_list[secret_magiccircle_index - 1] = cur_magiccircle
		end
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.battle_group_name then
		local key = get_field_object(self.secret_key_name .. 1)

		if not key.FieldObjectBehaviour.IsGetted then
			sp_util.play_normal_screenplay(self.activate_key_event, self, key, 0.5)
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil then
		if e.Params.Length == 1 then
			if e.Params[0] == self.lorain_head_out_event then
				self.is_lorain_head_out = true
			elseif e.Params[0] == self.lorain_head_in_event then
				self.is_lorain_head_out = false
			end
		elseif e.Params.Length == 2 then
			if e.Params[0] == 'is_react_lorain_clone' then
				for i = 1, self.lorain_clone_switch_num do
					local cur_clone = get_field_object(
							self.switch_lorain_clone_name..i..'_'..self.lorain_clone_switch_direction_list[i])

					if lua_helper.reference_equals(e.Sender, cur_clone) then
						if e.Params[1] == 'true' then
							self.lorain_clone_switch_flag_list[i] = false
						else
							self.lorain_clone_switch_flag_list[i] = true
						end

						break
					end
				end
			end
		end
	end
end

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)
	local center = field:GetZone(zone_name).Bounds.center + vector(0, -0.5, 0)

	local out_marker_name = zone_name .. self.magiccircle_out_marker_name
	local out_marker = field:GetMarker(out_marker_name)

	self.warp_magiccircle = true

	local diff_1 = user_party_leader.Position - center

	character_util.spine_set_alpha_fade(user_party_leader, 0, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 0, 0.5)

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party_leader, out_marker.position + diff_1)

	self.princess.Position = user_party_leader.Position + CS.Oak.DirectionExtensions.ToVector3(
			CS.Oak.DirectionExtensions.GetOpposite(user_party_leader.Direction))

	self.princess:OnEvent(CS.Oak.StateResetEvent.Instance)

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party_leader, 1, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion

-- 로레인 클론 회전 이벤트
function local_class:rotate_lorain_clone(cur_clone, index)
	music_player:PlaySfxOneShot('01_push_rock_unit_02')

	-- 회전 = 바꿔치기
	if self.lorain_clone_switch_direction_list[index] == 'up' then
		self.lorain_clone_switch_direction_list[index] = 'right'
	elseif self.lorain_clone_switch_direction_list[index] == 'right' then
		self.lorain_clone_switch_direction_list[index] = 'down'
	elseif self.lorain_clone_switch_direction_list[index] == 'down' then
		self.lorain_clone_switch_direction_list[index] = 'left'
	elseif self.lorain_clone_switch_direction_list[index] == 'left' then
		self.lorain_clone_switch_direction_list[index] = 'up'
	end

	self:activate_dir_clone(self.lorain_clone_switch_direction_list[index], index)
end

-- 해당 방향의 클론 제외하고 전부 비활성화
function local_class:activate_dir_clone(dir, index)
	local cur_lorain_up = get_field_object(self.switch_lorain_clone_name..index..self.up_name)
	local cur_lorain_right = get_field_object(self.switch_lorain_clone_name..index..self.right_name)
	local cur_lorain_down = get_field_object(self.switch_lorain_clone_name..index..self.down_name)
	local cur_lorain_left = get_field_object(self.switch_lorain_clone_name..index..self.left_name)

	cur_lorain_up.ActiveState = active_state('disabled')
	cur_lorain_right.ActiveState = active_state('disabled')
	cur_lorain_down.ActiveState = active_state('disabled')
	cur_lorain_left.ActiveState = active_state('disabled')

	if dir == 'up' then
		cur_lorain_up.ActiveState = active_state('enabled')
	elseif dir == 'right' then
		cur_lorain_right.ActiveState = active_state('enabled')
	elseif dir == 'down' then
		cur_lorain_down.ActiveState = active_state('enabled')
	elseif dir == 'left' then
		cur_lorain_left.ActiveState = active_state('enabled')
	end
end

-- 공중에서 작은 열쇠가 떨어지는 이벤트, 컨트롤 빼앗아서 보여줌
function local_class:activate_key_event(key, duration)
	camera_util.move_async(vector(key.Position.x, 0, key.Position.z), duration, { ignorecameragrids = true })

	wait_for_sec(0.5)

	local height = stage_util.get_height(key.Position)

	stage_util.set_fo_active_state(key.Name, 'enabled')
	key.Position = vector(key.Position.x, 10 + height, key.Position.z)

	local shadow_transform = key.Transform:Find("shadow")
	shadow_transform.localPosition = vector(0, -10 + 0.03, 0)

	-- 낙하 계산
	local free_fall = CS.CalculatorFreeFall(0.5, 10, 3)
	local end_pos = vector(key.Position.x, stage_util.get_height(key.Position), key.Position.z)

	local time_passed = 0
	local start_angle = 0
	local end_angle = 1080
	local is_bounce = false
	local bounce_num = 0

	local rotate_duration = free_fall:GetTotalTime()

	while not free_fall:IsDone() do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance()

		if not is_bounce and cur_y < 0 then
			key.Position = vector(end_pos.x, 10 + height + cur_y, end_pos.z)
		else
			if not is_bounce then
				is_bounce = true
			end

			key.Position = vector(end_pos.x, height + cur_y, end_pos.z)
		end

		shadow_transform.localPosition = vector(0, -key.Position.y + height + 0.03, 0)

		if time_passed < rotate_duration then
			time_passed = time_passed + unity_class.time.deltaTime

			local cur_angle = CS.Oak.Interpolations.Linear(
					time_passed, start_angle, end_angle - start_angle, rotate_duration)

			key.Transform.localRotation = unity_class.quaternion.Euler(0, cur_angle, 0)
		else
			key.Transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
		end

		if bounce_num < free_fall:NumBounced() then
			bounce_num = bounce_num + 1

			music_player_util.play_sfx({ sfx_name = '01_small_key_01', type_priority = 'event', player_priority = 'object' })
		end

		coroutine.yield(nil)
	end

	key.Position = end_pos
	shadow_transform.localPosition = vector(0, 0.03, 0)
	key.Transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)

	wait_for_sec(1)

	camera_util.move_async(user_party_leader.Position, duration, { end_target = user_party_leader })
end

-- 열쇠가 마법진 구역에 떨어지면 리셋시킴
function local_class:check_left_key()
	coroutine.yield(nil)

	-- 던져지는 물체 움직임이 멈출 때까지 대기
	local past_pos = self.left_key.Position
	local cur_pos = past_pos

	while true do
		coroutine.yield(nil)

		past_pos = cur_pos
		cur_pos = self.left_key.Position

		if (past_pos - cur_pos):IsAlmostZero() then
			break
		end
	end

	-- 던지기 완전히 끝날 때까지 대기
	wait_for_sec(0.3)

	-- 거대 열쇠가 마법진에 너무 가까이 가면 리셋
	local magiccircle_dist_limit = 2

	for i = 1, #self.magiccircle_pos_list do
		if (self.left_key.Position - self.magiccircle_pos_list[i]).magnitude < magiccircle_dist_limit then
			unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(self.left_key.Position)
			unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(self.left_key_origin_pos)

			self.left_key.Position = self.left_key_origin_pos

			break
		end
	end
end

-- 플레이어가 스위치 누르면 문 보여주기
function local_class:focus_hidden_key_door()
	party_util.stop_and_disable_control()

	local focus_door = get_field_object(self.hidden_key_door_name)

	camera_util.move_async(focus_door.Position, 0.5)

	wait_for_sec(1.5)

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	party_util.reset_controllers()
end

-- 금간 벽 확인
function local_class:check_cracked_wall()
	-- 일정 시간 내에 폭발이 두 번 일어나면 금간 벽 부순다
	self.cracked_wall_damage_num = self.cracked_wall_damage_num + 1

	local timer = 0
	local wait_duration = 0.2

	while self.cracked_wall_damage_num < 2 and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if not stage_progress:GetNamedData(self.cracked_wall_name) and self.cracked_wall_damage_num >= 2 then
		coroutine.yield(self:destroy_cracked_wall(self.cracked_wall_name))
	else
		self.cracked_wall_damage_num = 0
	end
end

-- 금간 벽 부수는 이벤트
function local_class:destroy_cracked_wall(wall_name)
	stage_progress:SetNamedData(wall_name, true)

	local cracked_wall = get_field_object(wall_name)

	unity_object_pool.GetOrCreate(self.cracked_wall_effect_preset):Instantiate(
			cracked_wall.Position + vector(0, 1, 0))

	music_player_util.play_sfx({ sfx_name = '02_explosion_02', type_priority = 'event', player_priority = 'object' })

	camera_util.shake(0.3, 0.5)

	wait_for_sec(0.2)

	cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
	cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

	cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	cracked_wall.Interactable = CS.Oak.NonInteractable.Instance
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}