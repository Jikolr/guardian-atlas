local local_class = newclass("FutureCastlePartB1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 커스텀 스테이지 State
	self.custom_stage_state =
	{
		save_magiccircle = 0,
		save_magiccircle_hidden = 1
	}

	-- 메인 스크립트
	self.main_script = 'futurecastle_part2_s7_'

	-- 공주
	self.princess = nil

	-- 트리오
	self.trio_list = nil

	-- 라나
	self.lana = nil

	-- 리소스 홀더
	self.resholder = nil

	-- 벌레 이펙트
	self.bug_effect = nil

	-- 경비병 원래 위치 리스트
	self.watch_invader_pos_list = nil

	-- 경비병 원래 방향 리스트
	self.watch_invader_dir_list = nil

	-- 숨길 열쇠 이름 리스트
	self.secret_key_name_list = { '2', '4', '5', '6', '7' }

	-- 숨길 열쇠 리스트
	self.hidden_key_list = nil

	-- 일방통행 표지판
	self.one_way_sign = nil

	-- 일방통행 표지판 이펙트
	self.one_way_sign_effect = nil

	-- 마법진 이펙트 리스트
	self.magiccircle_effect_list = nil

	-- 인베이더들에게 들켰는지 저장
	self.is_detected = false

	-- 인베이더들이 오브젝트 체크 중인지 저장 (중복 허용하지 않음)
	self.is_check_thrown_obj = false

	-- 일방통행 존 안에 있는지 저장
	self.is_in_one_way_zone = false

	-- 일방통행 존에서 길을 벗어났는지 저장
	self.out_of_way = false

	-- 현재 로레인 머리가 밖에 나와 있는지 저장
	self.is_lorain_head_out = false

	-- 로레인 클론 방 이벤트 보았는지 저장
	self.is_see_lorain_clone_event = false

	-- 트리오와 대화
	self.is_talk_with_trio = false

	-- 라나와 대화
	self.is_talk_with_lana = false

	-- 테슬라 코일 체크
	self.room_b_4_check_tesla_coil = 0

	-- 스위치 체크
	self.room_e_5_check_switch = 0

	-- 메인 금 간 바닥 파괴 위치
	self.main_cracked_floor_pos = vector(-1, 0, 161)

	-- 메인 금 간 바닥 파괴되었는지 저장
	self.is_destroyed_main_cracked_floor = false

	-- 비밀 금 간 바닥 파괴 위치 리스트
	self.secret_cracked_floor_pos_list = { vector(22, 0, 178), vector(22, 0, 179),
	                                       vector(23, 0, 178), vector(23, 0, 179) }

	-- 비밀 금 간 바닥 파괴 저장
	self.is_destroyed_secret_cracked_floor = false

	-- 비밀 금 간 바닥 파괴할 블록 위치 올바른지 체크
	self.check_secret_cracked_floor_block = { false, false, false, false }

	-- 로레인 클론 이벤트 위치 리스트
	self.lorain_clone_pos_list =  { vector(61, 0, 96), vector(65, 0, 96),
	                                vector(63, 0, 100) }

	-- 마법진 이동 중인지 저장
	self.warp_magiccircle = false

	-- 게이트 이름 리스트
	self.gate_name_list = { 'lorain_head_door', 'main_hall_door_2', 'room_d_1_main_door' }

	-- 기타 상수
	self.key_num = 7
	self.one_way_lorain_num = 6
	self.watch_invader_num = 4
	self.tesla_coil_num = 4
	self.underground_switch_num = 4
	self.secret_cracked_floor_block_num = 4
	self.fake_spike_num = 2
	self.fake_mine_num = 6
	self.lorain_clone_num = 3

	-- 타일맵 NPC 이름
	self.princess_name = 'princess'
	self.one_way_lorain_name = 'one_way_lorain_'
	self.watch_invader_name = 'watch_invader_'
	self.android_carpenter_name = 'android_carpenter'
	self.android_bunny_name = 'android_bunny'
	self.trio_boss_name = 'trio_boss'
	self.trio_man_name = 'trio_man'
	self.trio_panda_name = 'trio_panda'
	self.lana_name = 'lana'

	-- 타일맵의 필드오브젝트 이름
	self.block_key = 'block'
	self.secret_key_name = 'key_'
	self.room_b_4_tesla_coil_name = 'room_b_4_tesla_coil'
	self.room_e_5_switch_name = 'room_e_5_switch'
	self.room_e_5_reset_switch_name = 'room_e_5_reset_switch'
	self.ice_block_name = 'room_c_2_ice_block'
	self.ice_block_reset_switch_name = 'room_c_2_reset_switch'
	self.one_way_sign_name = 'one_way_sign'
	self.mouse_bomb_rock_name = 'mouse_bomb_rock'
	self.break_rock_door_name = 'room_c_2_mouse_bomb_door'
	self.main_cracked_floor_name = 'main_cracked_floor'
	self.main_cracked_floor_block_name = 'room_d_1_big_block'
	self.secret_cracked_floor_name = 'secret_cracked_floor'
	self.secret_cracked_floor_block_name = 'room_d_4_block_'
	self.fake_spike_name = 'fake_spike_'
	self.fake_mine_name = 'fake_mine_'
	self.lorain_chest_name = 'lorain_head_chest'
	self.lorain_hint_name = 'lorain_hint'
	self.room_e_5_lorain_clone_name = 'room_e_5_lorain_clone'
	self.room_e_5_lorain_clone_left_name = 'room_e_5_lorain_clone_left'
	self.room_e_5_lorain_clone_right_name = 'room_e_5_lorain_clone_right'
	self.room_e_5_lorain_clone_front_name = 'room_e_5_lorain_clone_front'
	self.lorain_clone_star_piece_name = 'lorain_clone_star_piece'
	self.lorain_head_name = 'lorain_head'
	self.bob_desk_name = 'bob_desk'
	self.cracked_wall_name = 'cracked_wall'

	-- 타일맵 존 이름
	self.watch_invader_event_zone_name = 'watch_invader'
	self.one_way_event_zone_name = 'one_way'
	self.one_way_enter_upper_event_zone_name = 'one_way_enter_upper'
	self.one_way_enter_lower_event_zone_name = 'one_way_enter_lower'
	self.one_way_leave_upper_event_zone_name = 'one_way_leave_upper'
	self.one_way_leave_lower_event_zone_name = 'one_way_leave_lower'
	self.magiccircle_upper_event_zone_name = 'magic_circle_upper'
	self.magiccircle_lower_event_zone_name = 'magic_circle_lower'
	self.magiccircle_upper_hidden_event_zone_name = 'magic_circle_upper_hidden'
	self.magiccircle_lower_hidden_event_zone_name = 'magic_circle_lower_hidden'
	self.lorain_clone_room_event_zone_name = 'lorain_clone_room'
	self.stair_enter_event_zone_name_1 = 'stair_enter_1'
	self.stair_enter_event_zone_name_2 = 'stair_enter_2'

	-- 타일맵 마커 이름
	self.one_way_respawn_marker_name = 'one_way_respawn'
	self.invader_respawn_marker_name = 'invader_respawn'

	-- 배틀 그룹 이름
	self.battle_group_name_1 = 'battle_2'
	self.battle_group_name_2 = 'battle_4'
	self.battle_group_name_3 = 'battle_5'

	-- 틴트 이름
	self.tint_key_name = 'futurecastle_2_2'
	self.tint_key_name_curse = 'futurecastle_2_2_curse'

	-- 커스텀 이벤트 이름
	self.detected_event = 'detected_by_invader'
	self.lorain_head_out_event = 'lorain_head_out'
	self.lorain_head_in_event = 'lorain_head_in'

	-- 커스텀 Stage 스테이트 번호
	self.magiccircle_custom_state = self.custom_stage_state.save_magiccircle
	self.magiccircle_hidden_custom_state = self.custom_stage_state.save_magiccircle_hidden

	-- 오브젝트 풀 이름
	self.block_aura_effect_preset = 'FX_Blockaura_Char_black'
	self.magiccircle_effect_preset = 'MagicCircle_AppearIdle'
	self.reset_effect_preset = 'FX_reset_object'
	self.laser_effect_preset = 'laser_dark_scaling_2side'
	self.cracked_wall_effect_preset = 'FX_Common_SmokeScreen'
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.block_aura_effect_preset)
	unity_object_pool.GetOrCreate(self.magiccircle_effect_preset)
	unity_object_pool.GetOrCreate(self.reset_effect_preset)
	unity_object_pool.GetOrCreate(self.laser_effect_preset)
	unity_object_pool.GetOrCreate(self.cracked_wall_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.FallInHoleStartEvent), 'on_fall_in_hole_start_event')

	self.princess = get_character(self.princess_name)

	local main_quest_id = 195
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	local trio_boss = get_character(self.trio_boss_name)
	local trio_panda = get_character(self.trio_panda_name)
	local trio_man = get_character(self.trio_man_name)

	self.trio_list = create_generic_list(CS.Oak.Character)
	self.trio_list:Add(trio_boss)
	self.trio_list:Add(trio_panda)
	self.trio_list:Add(trio_man)

	-- 스테이지 클리어 한 경우, 트리오 안 나옴
	if not user_progress:IsStageCleared(stage.Name) then
		if main_quest ~= nil and main_quest.InnerProgress > 6 then
			character_util.set_position(self.trio_list[0], vector(2, 0, 18))
			character_util.set_position(self.trio_list[1], vector(2, 0, 17))
			character_util.set_position(self.trio_list[2], vector(2.7, 0, 17.5))
		end

		for i = 0, self.trio_list.Count - 1 do
			self.trio_list[i]:HideWeapon(true)
			character_util.set_direction(self.trio_list[i], 'left')
			self.trio_list[i].Interactable:AddListener(self.cs_controller)
		end
	end

	self.lana = get_character(self.lana_name)

	-- 라나 서브스테이지 열면 안 나옴
	if not user_progress:IsStageOpened('substage_11_2') then
		if main_quest ~= nil and main_quest.InnerProgress > 6 then
			character_util.set_position(self.lana, vector(2.5, 0, 13))
			character_util.set_direction(self.lana, 'right')
		end

		self.lana.Interactable:AddListener(self.cs_controller)
	end

	self.watch_invader_pos_list = create_generic_list(unity_class.vector3)
	self.watch_invader_dir_list = create_generic_list(CS.Oak.Direction)

	for i = 1, self.watch_invader_num do
		local cur_invader = get_character(self.watch_invader_name..i)

		self.watch_invader_pos_list:Add(cur_invader.Position)
		self.watch_invader_dir_list:Add(cur_invader.Direction)
	end

	self.one_way_sign = get_field_object(self.one_way_sign_name)

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.resholder = CS.Foundations.ResourceHolder()

	-- 리소스 홀더에서 벌레 이펙트 생성 후 비활성화
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_10_futurecastle_part2/tilesets/futurecastle_part2', 'bug_gimmick', function(prefab)
				self.bug_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.bug_effect:SetActive(false)
			end)
end

function local_class:need_on_launch()
	local main_quest_id = 195
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return (main_quest ~= nil and main_quest.InnerProgress == 6)
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleStartEvent))

	self.princess = nil

	self.one_way_sign = nil

	self.one_way_sign_effect = nil

	self.secret_key_name_list = nil

	self.hidden_key_list = nil

	self.magiccircle_effect_list = nil

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	if self.bug_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.bug_effect)
		self.bug_effect = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.MoveFieldObjectEvent) then
		self:on_move_field_object_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ThrowEvent) then
		self:on_throw_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DoorOpenedEvent) then
		self:on_door_opened_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		self:on_switch_on_off_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TeslaCoilOnOffEvent) then
		self:on_tesla_coil_on_off_event(e)
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
		stage_util.set_fo_active_state(self.secret_key_name..self.secret_key_name_list[i], 'disabled')
	end

	for i = 1, self.key_num do
		get_field_object(self.secret_key_name..i).Transform.localScale = unity_class.vector3.one * 0.8
	end

	-- 표지판 태운 적 있는 지 확인 후에 표지판에 이펙트 부착
	if not stage_progress:GetNamedData(self.one_way_sign_name) then
		self.one_way_sign_effect = unity_object_pool.GetOrCreate(self.block_aura_effect_preset):Instantiate(
				self.one_way_sign.Position)
		self.one_way_sign_effect.transform.localScale = unity_class.vector3.one * 2
	else
		stage_util.set_fo_active_state(self.one_way_sign_name, 'disabled')
	end

	-- 블록으로 부순 구멍들 확인 후 처리
	if stage_progress:GetNamedData(self.main_cracked_floor_name) then
		local main_cracked_floor = get_field_object(self.main_cracked_floor_name)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
		damage_info.sender = main_cracked_floor
		damage_info.target = main_cracked_floor
		damage_info.modifier = 1000
		damage_info.direction = vector(0, -1, 0)

		command_util.execute_damage(damage_info)

		self.is_destroyed_main_cracked_floor = true

		-- 블록 위치 설정
		local cur_block = get_field_object(self.main_cracked_floor_block_name)
		cur_block.Position = vector(65, 0, 114)

		-- 블록의 defaultPos를 수정할 방법이 없어서 어쩔 수 없이 이렇게 함
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_main_block, self))
	end

	if stage_progress:GetNamedData(self.secret_cracked_floor_name) then
		local secret_cracked_floor = get_field_object(self.secret_cracked_floor_name)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
		damage_info.sender = secret_cracked_floor
		damage_info.target = secret_cracked_floor
		damage_info.modifier = 1000
		damage_info.direction = vector(0, -1, 0)

		command_util.execute_damage(damage_info)

		self.is_destroyed_secret_cracked_floor = true

		-- 블록 위치 설정
		local secret_block_pos_list = create_generic_list(unity_class.vector3)
		secret_block_pos_list:Add(vector(88, 1, 131))
		secret_block_pos_list:Add(vector(88, 1, 130))
		secret_block_pos_list:Add(vector(91, 1, 131))
		secret_block_pos_list:Add(vector(91, 1, 130))

		for i = 1, self.secret_cracked_floor_block_num do
			local cur_block = get_field_object(self.secret_cracked_floor_block_name..i)

			cur_block.Position = secret_block_pos_list[i - 1]
		end

		-- 블록의 defaultPos를 수정할 방법이 없어서 어쩔 수 없이 이렇게 함
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_secret_block, self))
	end

	-- PS-8046 금이 간 바닥 기믹 위에 푸셔블 오브젝트를 밀고 지나갈 때 캐릭터가 푸셔블 오브젝트를 통과하는 버그 때문에 금이 간 바닥 기믹을 Visible 처리
	local main_cracked_floor = get_field_object(self.main_cracked_floor_name)
	main_cracked_floor.ActiveState = active_state('visible')

	local secret_cracked_floor = get_field_object(self.secret_cracked_floor_name)
	secret_cracked_floor.ActiveState = active_state('visible')

	-- 가짜 오브젝트 설정
	for i = 1, self.fake_spike_num do
		local cur_obj = get_field_object(self.fake_spike_name..i)

		cur_obj.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	for i = 1, self.fake_mine_num do
		local cur_obj = get_field_object(self.fake_mine_name..i)

		cur_obj.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	-- 마법진 설정
	self.magiccircle_effect_list = create_generic_list(CS.Oak.PooledUnityObject)

	self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
			vector(3, 0, 179)))

	if stage_progress:GetCustomData(self.magiccircle_custom_state, false) then
		self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
				vector(6, 0, 17)))
	end

	self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
			vector(-24, 0, 182.5)))

	if stage_progress:GetCustomData(self.magiccircle_hidden_custom_state, false) then
		self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
				vector(45.5, 0, 41)))
	end

	-- 게이트 기본 애니메이션 실행, 열려 있으면 실행 X
	for i = 1, #self.gate_name_list do
		local cur_gate = get_field_object(self.gate_name_list[i])
		local animator = cur_gate:GetComponent(typeof(CS.UnityEngine.Animator))

		local door_behaviour = cur_gate.FieldObjectBehaviour

		if door_behaviour ~= nil and not door_behaviour.Opened then
			animator:Play('idle', -1)
		else
			cur_gate.Interactable = CS.Oak.NonInteractable.Instance
		end
	end

	-- 금 간 벽 부순 적 있는지 확인 후 파괴
	if stage_progress:GetNamedData(self.cracked_wall_name) then
		local cracked_wall = get_field_object(self.cracked_wall_name)

		cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
		cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

		cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		cracked_wall.Interactable = CS.Oak.NonInteractable.Instance
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	local zone_name = e.Zone.Name

	-- Exit 이동으로 Princess의 위치가 이상해지는 버그 수정
	-- 안드로이드 버니가 파티원에 있을 경우 같이 처리
	local android_bunny = get_character(self.android_bunny_name)

	if zone_name == self.stair_enter_event_zone_name_1 then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.princess.Position = user_party_leader.Position + vector(-0.7, 0, 0)

			if user_party:Contains(android_bunny) then
				android_bunny.Position = user_party_leader.Position + vector(-1.4, 0, 0)
			end
		end
	elseif zone_name == self.stair_enter_event_zone_name_2 then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.princess.Position = user_party_leader.Position + vector(0.7, 0, 0)

			if user_party:Contains(android_bunny) then
				android_bunny.Position = user_party_leader.Position + vector(1.4, 0, 0)
			end
		end
	end

	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end

	if zone_name == self.magiccircle_upper_event_zone_name then
		if not self.warp_magiccircle then
			self.warp_magiccircle = true

			sp_util.play_normal_screenplay(self.enter_magiccircle_upper_event, self)
		end
	elseif zone_name == self.magiccircle_lower_event_zone_name then
		if stage_progress:GetCustomData(self.magiccircle_custom_state, false) then
			if not self.warp_magiccircle then
				self.warp_magiccircle = true

				sp_util.play_normal_screenplay(self.enter_magiccircle_lower_event, self)
			end
		end
	elseif zone_name == self.magiccircle_upper_hidden_event_zone_name then
		if not self.warp_magiccircle then
			self.warp_magiccircle = true

			sp_util.play_normal_screenplay(self.enter_magiccircle_upper_hidden_event, self)
		end
	elseif zone_name == self.magiccircle_lower_hidden_event_zone_name then
		if stage_progress:GetCustomData(self.magiccircle_hidden_custom_state, false) then
			if not self.warp_magiccircle then
				self.warp_magiccircle = true

				sp_util.play_normal_screenplay(self.enter_magiccircle_lower_hidden_event, self)
			end
		end
	elseif zone_name == self.lorain_clone_room_event_zone_name then
		if not self.is_see_lorain_clone_event then
			self.is_see_lorain_clone_event = true
			local head_on_princess = not self.is_lorain_head_out

			if self.is_lorain_head_out then
				local lorain_head = get_field_object(self.lorain_head_name)
				if field:IsInSameCameraGrid(user_party.Leader.Position, lorain_head.Position) then
					speech_bubble_util.show_speech_bubble(lorain_head, { key = 'futurecastle_2_2_lorain_clone' })
				else
					-- 카메라 그리드 밖에 있으면 공주에게 복귀시킨다.
					message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'press_lorain_button', 'true' }))
					head_on_princess = true
				end
			end

			if head_on_princess then
				if self.princess.Direction == CS.Oak.Direction.Up then
					speech_bubble_util.show_speech_bubble(self.princess,
							{ key = 'futurecastle_2_2_lorain_clone', offset = vector(1.8, 0, 1.2) })
				elseif self.princess.Direction == CS.Oak.Direction.Down then
					speech_bubble_util.show_speech_bubble(self.princess,
							{ key = 'futurecastle_2_2_lorain_clone', offset = vector(1.8, 0, 0.9) })
				elseif self.princess.Direction == CS.Oak.Direction.Left then
					speech_bubble_util.show_speech_bubble(self.princess,
							{ key = 'futurecastle_2_2_lorain_clone', offset = vector(2.1, 0, 0.9) })
				elseif self.princess.Direction == CS.Oak.Direction.Right then
					speech_bubble_util.show_speech_bubble(self.princess,
							{ key = 'futurecastle_2_2_lorain_clone', offset = vector(1.9, 0, 0.9) })
				end
			end
		end
	end

	local upper_enter_center = vector(-0.5, 0, 126)
	local upper_leave_center = vector(-81.5, 0, 177)

	local lower_enter_center = vector(-0.5, 0, 114)
	local lower_leave_center = vector(-81.5, 0, 99)

	if not self.is_in_one_way_zone then
		if zone_name == self.one_way_enter_lower_event_zone_name then
			self.is_in_one_way_zone = true

			if self.one_way_sign.ActiveState ~= active_state('disabled') then
				music_player_util.play_sfx({ sfx_name = '03_vignette_01', type_priority = 'event', player_priority = 'npc' })

				field:Tint(self.tint_key_name, unity_color({0.75, 0.5, 0.5, 1}), 0.3)
			end

			for i = 0, user_party.Count - 1 do
				local diff = user_party[i].Position - lower_enter_center
				user_party[i].Position = lower_leave_center + diff

				if i ~= 0 then
					user_party[i]:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			camera_util.move(user_party_leader.Position, 0, { ignorecameragrids = true, end_target = user_party_leader })

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.one_way_zone_event, self))
		elseif zone_name == self.one_way_enter_upper_event_zone_name then
			self.is_in_one_way_zone = true

			if self.one_way_sign.ActiveState ~= active_state('disabled') then
				music_player_util.play_sfx({ sfx_name = '03_vignette_01', type_priority = 'event', player_priority = 'npc' })

				field:Tint(self.tint_key_name, unity_color({0.75, 0.5, 0.5, 1}), 0.3)
			end

			for i = 0, user_party.Count - 1 do
				local diff = user_party[i].Position - upper_enter_center
				user_party[i].Position = upper_leave_center + diff

				if i ~= 0 then
					user_party[i]:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			camera_util.move(user_party_leader.Position, 0, { ignorecameragrids = true, end_target = user_party_leader })

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.one_way_zone_event, self))
		end
	end

	if self.is_in_one_way_zone then
		if zone_name == self.one_way_leave_lower_event_zone_name then
			self.is_in_one_way_zone = false

			field:RemoveTint(self.tint_key_name, 0.3)

			for i = 0, user_party.Count - 1 do
				local diff = user_party[i].Position - lower_leave_center
				user_party[i].Position = lower_enter_center + diff

				if i ~= 0 then
					user_party[i]:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			camera_util.move(user_party_leader.Position, 0, { ignorecameragrids = true, end_target = user_party_leader })
		elseif zone_name == self.one_way_leave_upper_event_zone_name then
			self.is_in_one_way_zone = false

			field:RemoveTint(self.tint_key_name, 0.3)

			for i = 0, user_party.Count - 1 do
				local diff = user_party[i].Position - upper_leave_center
				user_party[i].Position = upper_enter_center + diff

				if i ~= 0 then
					user_party[i]:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			camera_util.move(user_party_leader.Position, 0, { ignorecameragrids = true, end_target = user_party_leader })
		end
	end
end

function local_class:on_interact_event(e)
	local lorain_hint = get_field_object(self.lorain_hint_name)
	local bob_desk = get_field_object(self.bob_desk_name)

	if lua_helper.reference_equals(e.Target, lorain_hint) then
		sp_util.play_normal_screenplay(self.interact_with_lorain_hint, self)
	elseif lua_helper.reference_equals(e.Target, bob_desk) then
		sp_util.play_normal_screenplay(self.interact_with_bob_desk, self, bob_desk)
	else
		for i = 0, self.trio_list.Count - 1 do
			if lua_helper.reference_equals(e.Target, self.trio_list[i]) then
				if not self.is_talk_with_trio then
					self.is_talk_with_trio = true

					sp_util.play_normal_screenplay(self.talk_with_trio_event, self)

					break
				else
					if i == 0 then
						speech_bubble_util.show_speech_bubble(self.trio_list[i], { key = self.main_script..45 })
					elseif i == 1 then
						speech_bubble_util.show_speech_bubble(self.trio_list[i], { key = self.main_script..51 })
					else
						speech_bubble_util.show_speech_bubble(self.trio_list[i], { key = self.main_script..47 })
					end
				end
			end
		end

		if lua_helper.reference_equals(e.Target, self.lana) then
			if not self.is_talk_with_lana then
				self.is_talk_with_lana = true

				sp_util.play_normal_screenplay(self.talk_with_lana_event, self)
			else
				speech_bubble_util.show_speech_bubble(self.lana, { key = self.main_script..62 })
			end
		end
	end
end

function local_class:on_move_field_object_event(e)
	if e.FieldObject.Name ~= nil and string.find(e.FieldObject.Name, self.block_key) then
		local main_cracked_floor_block = get_field_object(self.main_cracked_floor_block_name)

		if lua_helper.reference_equals(e.FieldObject, main_cracked_floor_block) and
				not self.is_destroyed_main_cracked_floor then
			if (main_cracked_floor_block.Position - self.main_cracked_floor_pos):IsAlmostZero() then
				self.is_destroyed_main_cracked_floor = true

				self:break_main_cracked_floor()
			end
		elseif not self.is_destroyed_secret_cracked_floor then
			local secret_cracked_floor_block_list = create_generic_list(CS.Oak.FieldObject)

			for i = 1, self.secret_cracked_floor_block_num do
				secret_cracked_floor_block_list:Add(get_field_object(self.secret_cracked_floor_block_name..i))
			end

			local check = 0

			for i = 0, secret_cracked_floor_block_list.Count - 1 do
				for j = 1, self.secret_cracked_floor_block_num do
					if (secret_cracked_floor_block_list[i].Position - self.secret_cracked_floor_pos_list[j]):IsAlmostZero() then
						check = check + 1

						break
					end
				end
			end

			if check == self.secret_cracked_floor_block_num then
				self:break_secret_cracked_floor()
			end
		end
	end

	if e.FieldObject.Name ~= nil and string.find(e.FieldObject.Name, self.room_e_5_lorain_clone_name) then
		-- 로레인 클론 스타피스가 이미 나와 있거나 획득한 경우 넘어감
		local lorain_star_piece = get_field_object(self.lorain_clone_star_piece_name)

		if stage_progress:HasStarPiece(self.lorain_clone_star_piece_name) or
				lorain_star_piece.ActiveState == active_state('enabled') then
			return
		end

		local lorain_clone_list = create_generic_list(CS.Oak.FieldObject)

		local lorain_clone_right = get_field_object(self.room_e_5_lorain_clone_right_name)
		local lorain_clone_left = get_field_object(self.room_e_5_lorain_clone_left_name)
		local lorain_clone_front = get_field_object(self.room_e_5_lorain_clone_front_name)

		lorain_clone_list:Add(lorain_clone_right)
		lorain_clone_list:Add(lorain_clone_left)
		lorain_clone_list:Add(lorain_clone_front)

		local check = 0

		for i = 0, lorain_clone_list.Count - 1 do
			if (lorain_clone_list[i].Position - self.lorain_clone_pos_list[i + 1]):IsAlmostZero() then
				check = check + 1
			end
		end

		if check == self.lorain_clone_num then
			sp_util.play_normal_screenplay(self.show_lorain_clone_star_piece_event, self)
		end
	end
end

function local_class:on_throw_event(e)
	-- 던진 물체와 순찰 인베이더가 같은 카메라 그리드 안에 있으면 진행
	local cur_invader = get_character(self.watch_invader_name..1)

	if field:IsInSameCameraGrid(e.Target.Position, cur_invader.Position) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.check_throw_object, self, e.Target))
	end
end

function local_class:on_door_opened_event(e)
	for i = 1, #self.gate_name_list do
		if e.DoorHandleName == self.gate_name_list[i] then
			local cur_gate = get_field_object(self.gate_name_list[i])

			cur_gate.Interactable = CS.Oak.NonInteractable.Instance
		end
	end
end

function local_class:on_switch_on_off_event(e)
	if string.find(e.SwitchObject.Name, self.room_e_5_switch_name) then
		local key = get_field_object(self.secret_key_name..7)

		-- 한 번이라도 스위치 4개 누르게 하면 이벤트 다시 실행하지 않음
		if self.room_e_5_check_switch ~= self.underground_switch_num and not key.FieldObjectBehaviour.IsGetted then
			if e.IsTurningOn then
				self.room_e_5_check_switch = self.room_e_5_check_switch + 1

				if self.room_e_5_check_switch == self.underground_switch_num then
					sp_util.play_normal_screenplay(self.activate_key_event, self, key)
				end
			else
				self.room_e_5_check_switch = self.room_e_5_check_switch - 1
			end
		end
	else
		if e.IsTurningOn then
			if lua_helper.reference_equals(e.SwitchObject, get_field_object(self.ice_block_reset_switch_name)) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_ice_block, self))
			elseif lua_helper.reference_equals(e.SwitchObject, get_field_object(self.room_e_5_reset_switch_name)) then
				-- 로레인 클론 원위치로
				local lorain_clone_right = get_field_object(self.room_e_5_lorain_clone_right_name)
				local lorain_clone_left = get_field_object(self.room_e_5_lorain_clone_left_name)
				local lorain_clone_front = get_field_object(self.room_e_5_lorain_clone_front_name)

				local lorain_clone_right_pos = vector(61, 0, 97)
				local lorain_clone_left_pos = vector(64, 0, 98)
				local lorain_clone_front_pos = vector(62, 0, 100)

				if not (lorain_clone_right.Position - lorain_clone_right_pos):IsAlmostZero() then
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_right.Position)
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_right_pos)

					lorain_clone_right.Position = lorain_clone_right_pos
				end

				if not (lorain_clone_left.Position - lorain_clone_left_pos):IsAlmostZero() then
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_left.Position)
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_left_pos)

					lorain_clone_left.Position = lorain_clone_left_pos
				end

				if not (lorain_clone_front.Position - lorain_clone_front_pos):IsAlmostZero() then
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_front.Position)
					unity_object_pool.GetOrCreate(self.reset_effect_preset):Instantiate(lorain_clone_front_pos)

					lorain_clone_front.Position = lorain_clone_front_pos
				end
			end
		end
	end
end

function local_class:on_tesla_coil_on_off_event(e)
	if string.find(e.CoilObject.Name, self.room_b_4_tesla_coil_name) then
		-- 한 번이라도 테슬라 코일 4개 불 들어오게 하면 이벤트 다시 실행하지 않음
		local key = get_field_object(self.secret_key_name..2)

		if self.room_b_4_check_tesla_coil ~= self.tesla_coil_num and not key.FieldObjectBehaviour.IsGetted then
			if e.IsTurningOn then
				self.room_b_4_check_tesla_coil = self.room_b_4_check_tesla_coil + 1

				if self.room_b_4_check_tesla_coil == self.tesla_coil_num then
					sp_util.play_normal_screenplay(self.activate_key_event, self, key)
				end
			else
				self.room_b_4_check_tesla_coil = self.room_b_4_check_tesla_coil - 1
			end
		end
	end

	return false
end

function local_class:on_damage_event(e)
	local require_damage_type = CS.Oak.DamageType.Explosion
	local cracked_wall = get_field_object(self.cracked_wall_name)

	if not stage_progress:GetNamedData(self.cracked_wall_name) and
			lua_helper.reference_equals(e.Info.target, cracked_wall) then
		if e.Info.type & require_damage_type == require_damage_type then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.destroy_cracked_wall, self))
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	local mouse_bomb_rock = get_field_object(self.mouse_bomb_rock_name)

	if lua_helper.reference_equals(e.FieldObject, mouse_bomb_rock) then
		stage_progress:SetNamedData(self.mouse_bomb_rock_name, true)
	elseif lua_helper.reference_equals(e.FieldObject, self.one_way_sign) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.destroy_one_way_sign_event, self))
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.battle_group_name_1 then
		local key = get_field_object(self.secret_key_name..4)

		if not key.FieldObjectBehaviour.IsGetted then
			sp_util.play_normal_screenplay(self.activate_key_event, self, key)
		end
	elseif e.BattleGroupName == self.battle_group_name_2 then
		local key = get_field_object(self.secret_key_name..5)

		if not key.FieldObjectBehaviour.IsGetted then
			sp_util.play_normal_screenplay(self.activate_key_event, self, key)
		end
	elseif e.BattleGroupName == self.battle_group_name_3 then
		local key = get_field_object(self.secret_key_name..6)

		if not key.FieldObjectBehaviour.IsGetted then
			sp_util.play_normal_screenplay(self.activate_key_event, self, key)
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil then
		if e.Params.Length == 2 then
			if not self.is_detected and e.Params[0] == self.detected_event then
				self.is_detected = true

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.player_detected, self, e.Sender))
			end
		elseif e.Params.Length == 1 then
			if e.Params[0] == self.lorain_head_out_event then
				self.is_lorain_head_out = true
			elseif e.Params[0] == self.lorain_head_in_event then
				self.is_lorain_head_out = false
			end
		end
	end
end

--region Magic Circle
-- 상단 마법진 진입 이벤트
function local_class:enter_magiccircle_upper_event()
	-- 스테이지 커스텀 스테이트 저장
	if not stage_progress:GetCustomData(self.magiccircle_custom_state, false) then
		stage_progress:SendCustomData(self.magiccircle_custom_state, true)

		self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
				vector(6, 0, 17)))
	end

	character_util.move_to(self.princess, vector(2.5, 0, 179), 0.7, nil, true, true)

	character_util.move_to_async(user_party_leader, vector(3.5, 0, 179),
			0.7, nil, true, true)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(user_party_leader, 'down')
	character_util.spine_set_alpha_fade(user_party_leader, 0, 0.5)

	character_util.set_direction(self.princess, 'down')
	character_util.spine_set_alpha_fade(self.princess, 0, 0.5)

	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party_leader, vector(6.5, 0, 17))
	character_util.set_direction(user_party_leader, 'down')

	character_util.set_position(self.princess, vector(5.5, 0, 17))
	character_util.set_direction(self.princess, 'down')

	-- 안드로이드 버니가 파티원에 있을 경우 같이 처리
	local android_bunny = get_character(self.android_bunny_name)

	if user_party:Contains(android_bunny) then
		character_util.set_position(android_bunny, vector(6, 0, 17.7))
		character_util.set_direction(android_bunny, 'down')
	end

	-- 나머지 파티원들도 보이지 않지만 이동시켜준다 (웨이포인트 사용 시 멀리서부터 걸어오게 되어 게임이 멈추는 것처럼 보임)
	for i = 0, user_party.Count - 1 do
		if user_party[i].ActiveState == active_state('disabled') then
			character_util.set_position(user_party[i],
					user_party_leader.Position + vector(0, 0, i))
		end
	end

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party_leader, 1, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end

-- 하단 마법진 진입 이벤트
function local_class:enter_magiccircle_lower_event()
	character_util.move_to(self.princess, vector(5.5, 0, 17), 0.7, nil, true, true)

	character_util.move_to_async(user_party_leader, vector(6.5, 0, 17),
			0.7, nil, true, true)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(user_party_leader, 'down')
	character_util.spine_set_alpha_fade(user_party_leader, 0, 0.5)

	character_util.set_direction(self.princess, 'down')
	character_util.spine_set_alpha_fade(self.princess, 0, 0.5)

	wait_for_sec(0.5)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party_leader, vector(3.5, 0, 179))
	character_util.set_direction(user_party_leader, 'down')

	character_util.set_position(self.princess, vector(2.5, 0, 179))
	character_util.set_direction(self.princess, 'down')

	-- 안드로이드 버니가 파티원에 있을 경우 같이 처리
	local android_bunny = get_character(self.android_bunny_name)

	if user_party:Contains(android_bunny) then
		character_util.set_position(android_bunny, vector(3, 0, 179.7))
		character_util.set_direction(android_bunny, 'down')
	end

	-- 나머지 파티원들도 보이지 않지만 이동시켜준다 (웨이포인트 사용 시 멀리서부터 걸어오게 되어 게임이 멈추는 것처럼 보임)
	for i = 0, user_party.Count - 1 do
		if user_party[i].ActiveState == active_state('disabled') then
			character_util.set_position(user_party[i],
					user_party_leader.Position + vector(0, 0, i))
		end
	end

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party_leader, 1, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end

-- 상단 비밀 마법진 진입 이벤트
function local_class:enter_magiccircle_upper_hidden_event()
	-- 스테이지 커스텀 스테이트 저장
	if not stage_progress:GetCustomData(self.magiccircle_hidden_custom_state, false) then
		stage_progress:SendCustomData(self.magiccircle_hidden_custom_state, true)

		self.magiccircle_effect_list:Add(unity_object_pool.GetOrCreate(self.magiccircle_effect_preset):Instantiate(
				vector(45.5, 0, 41)))
	end

	character_util.move_to(self.princess, vector(-24.5, 0, 182.5), 0.7, nil, true, true)

	character_util.move_to_async(user_party_leader, vector(-23.5, 0, 182.5),
			0.7, nil, true, true)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(user_party_leader, 'down')
	character_util.spine_set_alpha_fade(user_party_leader, 0, 0.5)

	character_util.set_direction(self.princess, 'down')
	character_util.spine_set_alpha_fade(self.princess, 0, 0.5)

	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party_leader, vector(46, 0, 41))
	character_util.set_direction(user_party_leader, 'down')

	character_util.set_position(self.princess, vector(45, 0, 41))
	character_util.set_direction(self.princess, 'down')

	-- 안드로이드 버니가 파티원에 있을 경우 같이 처리
	local android_bunny = get_character(self.android_bunny_name)

	if user_party:Contains(android_bunny) then
		character_util.set_position(android_bunny, vector(45.5, 0, 41.7))
		character_util.set_direction(android_bunny, 'down')
	end

	-- 나머지 파티원들도 보이지 않지만 이동시켜준다 (웨이포인트 사용 시 멀리서부터 걸어오게 되어 게임이 멈추는 것처럼 보임)
	for i = 0, user_party.Count - 1 do
		if user_party[i].ActiveState == active_state('disabled') then
			character_util.set_position(user_party[i],
					user_party_leader.Position + vector(0, 0, i))
		end
	end

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party_leader, 1, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end

-- 하단 마법진 진입 이벤트
function local_class:enter_magiccircle_lower_hidden_event()
	character_util.move_to(self.princess, vector(45, 0, 41), 0.7, nil, true, true)

	character_util.move_to_async(user_party_leader, vector(46, 0, 41),
			0.7, nil, true, true)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(user_party_leader, 'down')
	character_util.spine_set_alpha_fade(user_party_leader, 0, 0.5)

	character_util.set_direction(self.princess, 'down')
	character_util.spine_set_alpha_fade(self.princess, 0, 0.5)

	wait_for_sec(0.5)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party_leader, vector(-23.5, 0, 182.5))
	character_util.set_direction(user_party_leader, 'down')

	character_util.set_position(self.princess, vector(-24.5, 0, 182.5))
	character_util.set_direction(self.princess, 'down')

	-- 안드로이드 버니가 파티원에 있을 경우 같이 처리
	local android_bunny = get_character(self.android_bunny_name)

	if user_party:Contains(android_bunny) then
		character_util.set_position(android_bunny, vector(-25, 0, 183.2))
		character_util.set_direction(android_bunny, 'down')
	end

	-- 나머지 파티원들도 보이지 않지만 이동시켜준다 (웨이포인트 사용 시 멀리서부터 걸어오게 되어 게임이 멈추는 것처럼 보임)
	for i = 0, user_party.Count - 1 do
		if user_party[i].ActiveState == active_state('disabled') then
			character_util.set_position(user_party[i],
					user_party_leader.Position + vector(0, 0, i))
		end
	end

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party_leader, 1, 0.5)

	character_util.spine_set_alpha_fade(self.princess, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion


--region Cracked Floor
-- 메인 금 간 바닥 무너지는 이벤트
function local_class:break_main_cracked_floor()
	stage_progress:SetNamedData(self.main_cracked_floor_name, true)

	local main_cracked_floor = get_field_object(self.main_cracked_floor_name)

	local obj_list = create_generic_list(CS.Oak.FieldObject)
	obj_list:Add(get_field_object(self.main_cracked_floor_block_name))

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.break_cracked_floor, self, main_cracked_floor, obj_list, false))
end

-- 비밀 금 간 바닥 무너지는 이벤트
function local_class:break_secret_cracked_floor()
	stage_progress:SetNamedData(self.secret_cracked_floor_name, true)

	local secret_cracked_floor = get_field_object(self.secret_cracked_floor_name)

	local obj_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.secret_cracked_floor_block_num do
		obj_list:Add(get_field_object(self.secret_cracked_floor_block_name..i))
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.break_cracked_floor, self, secret_cracked_floor, obj_list, true))
end

-- 금 간 바닥 무너지는 연출
function local_class:break_cracked_floor(target, obj_list, is_secret)
	local behaviour_list = create_generic_list(CS.Oak.IFieldObjectBehaviour)
	local pushable_list = create_generic_list(CS.Oak.IPushable)

	for i = 0, obj_list.Count - 1 do
		behaviour_list:Add(obj_list[i].FieldObjectBehaviour)
		pushable_list:Add(obj_list[i].Pushable)

		obj_list[i].FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()
		obj_list[i].Pushable = CS.Oak.NonPushable.Instance
	end

	local shake_sfx = music_player_util.play_sfx({ sfx_name = '01_earthquake_04', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.3, 1)

	wait_for_sec(1)

	for i = 0, obj_list.Count - 1 do
		obj_list[i].Pushable = pushable_list[i]
	end

	coroutine.yield(nil)

	shake_sfx:FadeOut(1.5)

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
	damage_info.sender = target
	damage_info.target = target
	damage_info.modifier = 1000
	damage_info.direction = vector(0, -1, 0)

	command_util.execute_damage(damage_info)

	wait_for_sec(0.5)

	if is_secret then
		-- 블록 위치 설정
		local secret_block_pos_list = create_generic_list(unity_class.vector3)
		secret_block_pos_list:Add(vector(88, 1, 131))
		secret_block_pos_list:Add(vector(88, 1, 130))
		secret_block_pos_list:Add(vector(91, 1, 131))
		secret_block_pos_list:Add(vector(91, 1, 130))

		for i = 0, obj_list.Count - 1 do
			obj_list[i].Position = secret_block_pos_list[i]
		end
	else
		obj_list[0].Position = vector(65, 0, 114)
	end

	wait_for_sec(0.5)

	coroutine.yield(nil)

	-- HoleBehaviour의 요청과 겹치지 않도록 더 대기한 뒤 작동
	for i = 0, obj_list.Count - 1 do
		obj_list[i].FieldObjectBehaviour = behaviour_list[i]
		obj_list[i].Pushable = CS.Oak.UnitPushable()
	end
end

-- 메인 블록의 DefaultPosition 재설정, 리셋 버튼을 밟으면 지하 오브젝트가 지상으로 올라오는 버그 수정
function local_class:reset_main_block()
	local cur_block = get_field_object(self.main_cracked_floor_block_name)
	local saved_behaviour = cur_block.FieldObjectBehaviour
	cur_block.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()

	coroutine.yield(nil)

	cur_block.FieldObjectBehaviour = saved_behaviour
end

-- 비밀 블록의 DefaultPosition 재설정, 리셋 버튼을 밟으면 지하 오브젝트가 지상으로 올라오는 버그 수정
function local_class:reset_secret_block()
	local block_list = create_generic_list(CS.Oak.FieldObject)

	local saved_behaviour_list = create_generic_list(CS.Oak.IFieldObjectBehaviour)

	for i = 1, self.secret_cracked_floor_block_num do
		local cur_block = get_field_object(self.secret_cracked_floor_block_name..i)

		saved_behaviour_list:Add(cur_block.FieldObjectBehaviour)
		cur_block.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()

		block_list:Add(cur_block)
	end

	coroutine.yield(nil)

	for i = 0, block_list.Count - 1 do
		block_list[i].FieldObjectBehaviour = saved_behaviour_list[i]
	end
end
--endregion

-- 로레인 클론 스타피스 등장 이벤트
function local_class:show_lorain_clone_star_piece_event()
	camera_util.move_async(vector(63, 0, 98), 0.5)

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	local lorain_clone_list = create_generic_list(CS.Oak.FieldObject)

	local lorain_clone_right = get_field_object(self.room_e_5_lorain_clone_right_name)
	local lorain_clone_left = get_field_object(self.room_e_5_lorain_clone_left_name)
	local lorain_clone_front = get_field_object(self.room_e_5_lorain_clone_front_name)

	lorain_clone_list:Add(lorain_clone_right)
	lorain_clone_list:Add(lorain_clone_left)
	lorain_clone_list:Add(lorain_clone_front)

	for i = 0, lorain_clone_list.Count - 1 do
		lorain_clone_list[i]:Shake(0.04, 1)
	end

	wait_for_sec(1)

	music_player_util.play_sfx(
			{ sfx_name = '01_earthquake_04', volume = 0.8, type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_light_laser_01', type_priority = 'event', player_priority = 'npc' })

	local laser_sfx = music_player_util.play_sfx(
			{ sfx_name = '02_light_laser_loop_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.2, 2)

	local pos_list = create_generic_list(unity_class.vector3)
	pos_list:Add(vector(61.2, 0, 96.3))
	pos_list:Add(vector(64.8, 0, 96.3))
	pos_list:Add(vector(63, 0, 99.85))

	local angle_list = create_generic_list(CS.System.Single)
	angle_list:Add(140)
	angle_list:Add(40)
	angle_list:Add(-90)

	local laser_list = create_generic_list(CS.Oak.PooledUnityObject)

	for i = 0, lorain_clone_list.Count - 1 do
		local laser = unity_object_pool.GetOrCreate(self.laser_effect_preset):Instantiate(pos_list[i])

		laser.transform.localRotation = unity_class.quaternion.Euler(vector(0, angle_list[i], 0))
		laser.transform.localScale = vector(0, 1, 1)

		laser_list:Add(laser)
	end

	local cur_time = unity_class.time.time
	local expand_duration = 0.5

	local start_scale_x = 0
	local end_scale_x = 0.13

	while unity_class.time.time - cur_time < expand_duration do
		local cur_scale_x = CS.Oak.Interpolations.Linear(
				unity_class.time.time - cur_time, start_scale_x, end_scale_x - start_scale_x, expand_duration)

		for i = 0, laser_list.Count - 1 do
			laser_list[i].transform.localScale = vector(cur_scale_x, 1, 1)
		end

		coroutine.yield(nil)
	end

	for i = 0, laser_list.Count - 1 do
		laser_list[i].transform.localScale = vector(end_scale_x, 1, 1)
	end

	wait_for_sec(1.5)

	camera_util.shake(0.1, 1.5)

	local star_piece = get_field_object(self.lorain_clone_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(star_piece.Position, false))

	wait_for_sec(1.5)

	laser_sfx:FadeOut(1)

	camera_util.shake(0.05, 0.5)

	cur_time = unity_class.time.time
	local shrink_duration = 0.5

	start_scale_x = 0.13
	end_scale_x = 0

	while unity_class.time.time - cur_time < shrink_duration do
		local cur_scale_x = CS.Oak.Interpolations.Linear(
				unity_class.time.time - cur_time, start_scale_x, end_scale_x - start_scale_x, shrink_duration)

		for i = 0, laser_list.Count - 1 do
			laser_list[i].transform.localScale = vector(cur_scale_x, 1, 1)
		end

		coroutine.yield(nil)
	end

	for i = 0, laser_list.Count - 1 do
		laser_list[i]:Dispose()
	end

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })
end

--region One Way
-- 일방통행 이벤트 처리
function local_class:one_way_zone_event()
	local saved_pos = user_party_leader.Position

	-- 표지판이 부서진 경우 그냥 넘어감
	while not self.out_of_way and self.is_in_one_way_zone do
		-- x축 이동 = 일방통행 벗어남
		if not float_util.is_almost_zero(user_party_leader.Position.x - saved_pos.x) then
			-- 표지판 부서진 경우 무시
			if self.one_way_sign.ActiveState ~= active_state('disabled') then
				self.out_of_way = true
			-- 도중에 표지판 부서진 경우 틴트 제거
			else
				field:RemoveTint(self.tint_key_name, 0.3)
			end
		end

		coroutine.yield(nil)
	end

	if self.out_of_way then
		self.is_in_one_way_zone = false

		field_ui_manager:Hide()
		party_util.stop_and_disable_control()

		music_player_util.play_stage_music({ state = 'muted', mix = 2 })

		character_util.set_direction(user_party_leader, 'up')

		character_util.set_direction(self.princess, 'up')

		wait_for_sec(0.5)

		camera_util.move_async(user_party_leader.Position + vector(0, 0, 2), 1)

		wait_for_sec(1)

		-- 벌레 이펙트 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.activate_bug_effect, self))

		music_player_util.play_sfx({ sfx_name = '01_camera_emphasize_01', type_priority = 'event', player_priority = 'npc' })

		field:Tint(self.tint_key_name_curse, unity_color({ 1, 0, 0, 1 }), 0.5)

		camera_util.resize_to(2, 0.5)

		character_util.set_anim(user_party_leader, { name = 'embarrassed' })
		character_util.set_anim(self.princess, { name = 'embarrassed' })

		wait_for_sec(0.2)

		music_player_util.play_sfx({ sfx_name = '01_horror_01', type_priority = 'event', player_priority = 'npc' })

		wait_for_sec(0.8)

		camera_util.move_async(user_party_leader.Position, 0.25)

		wait_for_sec(0.25)

		screen_util.fade_out_async(0.3, unity_class.color.red, 'linear')

		field:RemoveTint(self.tint_key_name_curse)
		field:RemoveTint(self.tint_key_name)

		camera_util.resize_to_default(0)
		stage_camera:SetTarget(user_party_leader)

		local respawn_marker = field:GetMarker(self.one_way_respawn_marker_name)

		character_util.set_direction(user_party_leader, 'right')
		character_util.set_anim(user_party_leader, { name = 'prostrate' })
		character_util.set_emotion(user_party_leader, { name = 'damaged' })

		party_util.position_party(respawn_marker.position, 'right', 'linear')

		character_util.set_position(self.princess, respawn_marker.position +
				0.7 * CS.Oak.DirectionExtensions.ToVector3(CS.Oak.DirectionExtensions.GetOpposite(respawn_marker.direction)))
		character_util.set_direction(self.princess, 'right')
		character_util.set_anim(self.princess, { name = 'prostrate' })
		character_util.set_emotion(self.princess, { name = 'damaged' })

		wait_for_sec(0.5)

		screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

		wait_for_sec(0.5)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

		character_util.shake(user_party_leader, 0.04, 1)

		character_util.shake(self.princess, 0.04, 1)

		wait_for_sec(1)

		music_player_util.play_stage_music({ state = 'field', mix = 2 })

		music_player_util.play_sfx({ sfx_name = '01_player_popup_01', type_priority = 'event', player_priority = 'npc' })

		for i = 0, user_party.Count - 1 do
			if user_party[i].ActiveState ~= active_state('disabled') then
				character_util.remove_emotion(user_party[i])
				character_util.mario_jump_new(user_party[i], user_party[i].Direction)
			end
		end

		self.out_of_way = false

		character_util.set_direction(user_party_leader, 'up')

		character_util.set_direction(self.princess, 'up')

		field_ui_manager:Show()
		party_util.reset_controllers()
	end
end

-- 저주받은 복도 벌레 생성 이벤트
function local_class:activate_bug_effect()
	self.bug_effect:SetActive(true)
	self.bug_effect.transform.localPosition = user_party_leader.Position + vector(0, 0, 7.5)

	local bug_sfx = music_player_util.play_sfx({ sfx_name = '01_bugs_loop_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	local timer = 0
	local move_duration = 1.25

	local start_pos = self.bug_effect.transform.localPosition
	local end_pos = user_party_leader.Position

	while timer < move_duration do
		timer = timer + unity_class.time.deltaTime

		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, timer / move_duration)

		self.bug_effect.transform.localPosition = cur_pos

		coroutine.yield(nil)
	end

	self.bug_effect.transform.localPosition = end_pos

	wait_for_sec(0.5)

	bug_sfx:FadeOut()

	-- 비활성화
	self.bug_effect:SetActive(false)
end

-- 저주받은 복도 표지판 제거 이벤트
function local_class:destroy_one_way_sign_event()
	-- 일방통행 실패 이벤트가 진행 중인 경우는 이벤트가 끝날 때까지 대기함
	while self.out_of_way do
		coroutine.yield(nil)
	end

	coroutine.yield(nil)

	field_ui_manager:Hide()

	party_util.stop_and_disable_control()

	stage_progress:SetNamedData(self.one_way_sign_name, true)

	self.one_way_sign_effect:Dispose()

	music_player_util.play_sfx({ sfx_name = '01_holy_03', type_priority = 'event', player_priority = 'object' })

	camera_util.shake(0.2, 1)

	screen_util.fade_out_async(1, unity_class.color.white, 'linear')

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.white, 'linear')

	field_ui_util.show_narration_async( { key = 'futurecastle_2_2_destroy_one_way_sign' })

	field_ui_manager:Show()

	party_util.reset_controllers()
end
--endregion

-- 로레인 힌트 상호작용 이벤트
function local_class:interact_with_lorain_hint()
	field_ui_util.show_narration_async( { key = 'futurecastle_2_2_lorain_clone_description' })

	field_ui_util.show_narration_async( { key = 'futurecastle_2_2_lorain_right' })

	field_ui_util.show_narration_async( { key = 'futurecastle_2_2_lorain_left' })

	field_ui_util.show_narration_async( { key = 'futurecastle_2_2_lorain_front' })
end

-- 밥 책상과 상호작용 이벤트
function local_class:interact_with_bob_desk(bob_desk)
	speech_bubble_util.show_speech_bubble_async(bob_desk, { key = 'futurecastle_2_2_bob_desk_1', skip = true })

	speech_bubble_util.show_speech_bubble_async(bob_desk, { key = 'futurecastle_2_2_bob_desk_2', skip = true })

	speech_bubble_util.show_speech_bubble_async(bob_desk, { key = 'futurecastle_2_2_bob_desk_3', skip = true })
end

-- 트리오 대화 이벤트
function local_class:talk_with_trio_event()
	user_party_leader:HideWeapon(true)

	party_util.align_party_ignore_deactivated_party_member(
			self.trio_list[0].Position + vector(0, 0, -0.5), 'left', 1)

	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.trio_list[1], { name = 'victory_get', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[1], { key = self.main_script..44, skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.trio_list[0], { name = 'victory_extra' })
	character_util.set_emotion(self.trio_list[0], { name = 'doyagao' })

	character_util.remove_anim(self.trio_list[1])

	speech_bubble_util.show_speech_bubble_async(self.trio_list[0], { key = self.main_script..45, skip = true })

	character_util.set_anim(self.trio_list[0], { name = 'cast2' })
	character_util.set_emotion(self.trio_list[0], { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[0], { key = self.main_script..46, skip = true })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })

	character_util.look_at(self.trio_list[0], self.trio_list[2])
	character_util.remove_anim(self.trio_list[0])
	character_util.remove_emotion(self.trio_list[0])

	character_util.look_at(self.trio_list[1], self.trio_list[2])

	character_util.shake(self.trio_list[2], 0.04, 9999)
	character_util.set_anim(self.trio_list[2], { name = 'cast' })
	character_util.set_emotion(self.trio_list[2], { name = 'scared' })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[2], { key = self.main_script..47, skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_emotion(self.trio_list[0], { name = 'tired' })

	character_util.set_emotion(self.trio_list[1], { name = 'tired' })

	character_util.stop_shake(self.trio_list[2])
	character_util.set_anim(self.trio_list[2], { name = 'sing' })
	character_util.set_emotion(self.trio_list[2], { name = 'blush' })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[2], { key = self.main_script..48, skip = true })

	character_util.set_direction(self.trio_list[0], 'left')

	character_util.set_direction(self.trio_list[1], 'left')
	character_util.set_anim(self.trio_list[1], { name = 'cross_arm' })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[1], { key = self.main_script..49, skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(self.trio_list[0])
	character_util.remove_emotion(self.trio_list[0])

	character_util.set_anim(self.trio_list[1], { name = 'shoot' })
	character_util.remove_emotion(self.trio_list[1])

	character_util.remove_anim(self.trio_list[2])
	character_util.remove_emotion(self.trio_list[2])

	speech_bubble_util.show_speech_bubble_async(self.trio_list[1], { key = self.main_script..50, skip = true })

	character_util.set_anim(self.trio_list[1], { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(self.trio_list[1], { key = self.main_script..51, skip = true })

	character_util.remove_anim(self.trio_list[1])

	user_party_leader:HideWeapon(false)
end

-- 라나 대화 이벤트
function local_class:talk_with_lana_event()
	user_party_leader:HideWeapon(true)

	party_util.align_party_ignore_deactivated_party_member(self.lana.Position, 'right', 1)

	character_util.set_emotion(self.lana, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..52, skip = true })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.lana, 'left')

	speech_bubble_util.show_speech_bubble_async(
			self.lana, { key = { self.main_script..53, user.Name }, skip = true })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..54, skip = true })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.lana, 'right')
	character_util.remove_emotion(self.lana)

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..55, skip = true })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..56, skip = true })

	character_util.set_emotion(self.lana, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..57, skip = true })

	character_util.set_emotion(self.lana, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..58, skip = true })

	character_util.set_emotion(self.lana, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..59, skip = true })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..60, skip = true })

	character_util.set_emotion(self.lana, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..61, skip = true })

	speech_bubble_util.show_speech_bubble_async(self.lana, { key = self.main_script..62, skip = true })

	character_util.remove_emotion(self.lana)

	user_party_leader:HideWeapon(false)
end

-- 얼음 블록 리셋
function local_class:reset_ice_block()
	local ice_block = get_field_object(self.ice_block_name)

	-- Ice Block이 완전히 사라지지 않은 경우 작동하지 않음
	if ice_block.ActiveState ~= active_state('disabled') then
		return
	end

	ice_block.Transform.localScale = unity_class.vector3.one

	stage_util.set_fo_active_state(self.ice_block_name, 'enabled')

	-- Ice Block에 힐 보내서 원상복구
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = nil
	heal_info.target = ice_block
	heal_info.heal = ice_block.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true

	command_util.execute_heal(heal_info)
end

-- 공중에서 작은 열쇠가 떨어지는 이벤트, 컨트롤 빼앗아서 보여줌
function local_class:activate_key_event(key)
	camera_util.move_async(vector(key.Position.x, 0, key.Position.z), 0.5, { ignorecameragrids = true})

	wait_for_sec(0.5)

	stage_util.set_fo_active_state(key.Name, 'enabled')
	key.Position = vector(key.Position.x, 10, key.Position.z)

	local shadow_transform = key.Transform:Find("shadow")
	shadow_transform.localPosition = vector(0, -10 + 0.03, 0)

	-- 낙하 계산
	local free_fall = CS.CalculatorFreeFall(0.5, key.Position.y, 3)
	local end_pos = vector(key.Position.x, stage_util.get_height(key.Position), key.Position.z)
	local is_bounce = false
	local bounce_num = 0

	local time_passed = 0
	local start_angle = 0
	local end_angle = 1080

	local rotate_duration = free_fall:GetTotalTime()

	while not free_fall:IsDone() do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance()

		if not is_bounce and cur_y < stage_util.get_height(key.Position) then
			key.Position = vector(end_pos.x, 10 + cur_y, end_pos.z)
		else
			if not is_bounce then
				is_bounce = true
			end

			key.Position = vector(end_pos.x, cur_y, end_pos.z)
		end

		shadow_transform.localPosition = vector(0, -key.Position.y + 0.03, 0)

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

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })
end

--region Watch Invader
-- 순찰 중인 인베이더 주변에 떨어진 오브젝트가 인베이더 체크 범위 내부로 들어갔는지 확인
function local_class:check_throw_object(thrown_obj)
	coroutine.yield(nil)

	-- 던져지는 물체 움직임이 멈출 때까지 대기
	local past_pos = thrown_obj.Position
	local cur_pos = past_pos

	while true do
		coroutine.yield(nil)

		past_pos = cur_pos
		cur_pos = thrown_obj.Position

		if (past_pos - cur_pos):IsAlmostZero() then
			break
		end
	end

	-- 던지는 것 완료된 뒤에 obj가 내부로 들어온 경우
	if not self.is_check_thrown_obj and self:watch_zone_in_obj(thrown_obj) and
			thrown_obj.ActiveState ~= active_state("disabled") then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.notice_invader, self, thrown_obj))
	end
end

-- 인베이더 순찰 존 내부로 오브젝트가 들어왔는지 확인
function local_class:watch_zone_in_obj(thrown_obj)
	local center = vector(-25.5, 0, 78.5)
	local dist_x = 3
	local dist_z = 3

	return math.abs(thrown_obj.Position.x - center.x) < dist_x and
			math.abs(thrown_obj.Position.z - center.z) < dist_z
end

-- 특정 오브젝트를 발견하고 그 곳으로 향하는 인베이더들
function local_class:notice_invader(thrown_obj)
	-- 던져진 오브젝트 이벤트 시작
	self.is_check_thrown_obj = true

	music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	local invader_list = create_generic_list(CS.Oak.Character)

	-- 초기 방향 저장
	local origin_dir_list = create_generic_list(CS.Oak.Direction)

	for i = 1, self.watch_invader_num do
		local cur_invader = get_character(self.watch_invader_name..i)

		origin_dir_list:Add(cur_invader.Direction)
		invader_list:Add(cur_invader)
	end

	-- 던져진 오브젝트 위치 저장.
	-- 중간에 참조하면 오브젝트 위치가 바꼈을 때 엉뚱한 곳으로 쫓아감
	local thrown_obj_pos = thrown_obj.Position

	-- 인식
	for i = 0, invader_list.Count - 1 do
		-- 방향 설정
		character_util.look_at(invader_list[i], thrown_obj)
		character_util.jump(invader_list[i], 0.5, 0.3)

		-- 이모티콘
		character_util.show_emoticon(invader_list[i], nil, 'notice')
	end

	wait_for_sec(0.5)

	-- 현재 시간, 이동 시간
	local cur_time = unity_class.time.time
	local move_duration = 2

	-- 한계 거리
	local dist_limit = 1

	-- 인베이더들의 시작, 도착 목적지, 이동 거리 계산
	local start_pos_list = create_generic_list(unity_class.vector3)
	local end_pos_list = create_generic_list(unity_class.vector3)
	local dist_list = create_generic_list(CS.System.Single)

	for i = 0, invader_list.Count - 1 do
		start_pos_list:Add(invader_list[i].Position)

		local dir = thrown_obj_pos - invader_list[i].Position
		local dist = dir.magnitude

		if dist < dist_limit then
			end_pos_list:Add(invader_list[i].Position)
		else
			end_pos_list:Add(invader_list[i].Position + dir * ((dist - dist_limit) / dist))
		end

		dist_list:Add(dist)

		-- 이동 거리가 일정 이상이면 달리기, 0 이상이면 걷기
		if dist / move_duration > 5 then
			character_util.set_anim(invader_list[i], { name = 'run' })
		elseif dist > 0 then
			character_util.set_anim(invader_list[i], { name = 'walk' })
		end
	end

	-- 이동 진행
	while not self.is_detected and unity_class.time.time - cur_time < move_duration do
		local normalized = (unity_class.time.time - cur_time) / move_duration

		for i = 0, invader_list.Count - 1 do
			character_util.set_position(invader_list[i],
					unity_class.vector3.Lerp(start_pos_list[i], end_pos_list[i], normalized))
		end

		coroutine.yield(nil)
	end

	for i = 0, invader_list.Count - 1 do
		character_util.remove_anim(invader_list[i])
	end

	-- 이동 종료 / 오브젝트가 사라져서 종료된 것이 아니라면 인베이더들 4초 대기 후 이상 없음 확인
	cur_time = unity_class.time.time
	local wait_duration = 4

	local is_emoticon = false
	local emoticon_duration = 2

	while not self.is_detected and unity_class.time.time - cur_time < wait_duration do
		if not is_emoticon and unity_class.time.time - cur_time >= emoticon_duration then
			is_emoticon = true

			for i = 0, invader_list.Count - 1 do
				character_util.show_emoticon(invader_list[i], nil, 'question')
			end
		end

		coroutine.yield(nil)
	end

	-- 원위치로 복귀
	end_pos_list:Clear()

	for i = 0, start_pos_list.Count - 1 do
		end_pos_list:Add(start_pos_list[i])
	end

	start_pos_list:Clear()

	for i = 0, invader_list.Count - 1 do
		character_util.set_direction(invader_list[i],
				(end_pos_list[i] - invader_list[i].Position):ToDirection())
		character_util.set_anim(invader_list[i], { name = 'walk' })

		start_pos_list:Add(invader_list[i].Position)
	end

	-- 복귀 진행
	cur_time = unity_class.time.time

	while not self.is_detected and unity_class.time.time - cur_time < move_duration do
		local normalized = (unity_class.time.time - cur_time) / move_duration

		for i = 0, invader_list.Count - 1 do
			character_util.set_position(invader_list[i],
					unity_class.vector3.Lerp(start_pos_list[i], end_pos_list[i], normalized))
		end

		coroutine.yield(nil)
	end

	-- 복귀 완료
	if not self.is_detected then
		for i = 0, invader_list.Count - 1 do
			invader_list[i].FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
					invader_list[i], nil, 0, self.detected_event, 4, 60)
			invader_list[i].Position = end_pos_list[i]
			invader_list[i].Direction = origin_dir_list[i]

			character_util.remove_anim(invader_list[i])
		end
	end

	-- 던져진 오브젝트 이벤트 종료
	self.is_check_thrown_obj = false
end

-- 플레이어가 순찰 중인 인베이더에게 발각 시 실행되는 이벤트
function local_class:player_detected(detector)
	local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

	user_party:StopAndDisableControl()

	field:Tint("alert_max", unity_class.color(1, 0, 0), 0.25)

	camera_util.shake(0.07, 0.25)

	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

	character_util.set_anim(user_party_leader, { name = "embarrassed", loop = true })
	character_util.set_emotion(user_party_leader, { name = "surprise", loop = true})
	character_util.jump(user_party_leader, 0.3, 0.2)

	character_util.set_anim(self.princess, { name = "embarrassed", loop = true })
	character_util.set_emotion(self.princess, { name = "surprise", loop = true})

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	character_util.set_anim(detector, { name = "attack" })

	speech_bubble_util.show_speech_bubble_async(detector,
			{ key = "futurecastle_2_detected", skip = "true", bubble_type = "shout" })

	wait_for_sec(0.25)

	music_player_util.play_sfx({ sfx_name = '01_drown_01', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_circular(0.5, 'linear')

	wait_for_sec(1.0)

	-- 경비병들 리셋
	for i = 1, self.watch_invader_num do
		local cur_invader = get_character(self.watch_invader_name..i)

		cur_invader.Position = self.watch_invader_pos_list[i - 1]
		cur_invader.Direction = self.watch_invader_dir_list[i - 1]
		character_util.remove_anim(cur_invader)
	end

	siren:FadeOut(0.5)

	field:RemoveTint("alert_max", 0)

	local respawn_marker = field:GetMarker(self.invader_respawn_marker_name)

	character_util.set_position(user_party_leader, respawn_marker.position)
	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	character_util.set_position(self.princess, respawn_marker.position +
			0.7 * CS.Oak.DirectionExtensions.ToVector3(CS.Oak.DirectionExtensions.GetOpposite(respawn_marker.direction)))
	character_util.remove_anim(self.princess)
	character_util.remove_emotion(self.princess)

	wait_for_sec(0.5)

	character_util.remove_anim(detector)
	character_util.remove_emotion(detector)

	screen_util.fade_in_circular(0.5, 'linear')

	wait_for_sec(0.5)

	self.is_detected = false

	party_util.reset_controllers()
end
--endregion

-- 금간 벽 부수는 이벤트
function local_class:destroy_cracked_wall()
	stage_progress:SetNamedData(self.cracked_wall_name, true)

	local cracked_wall = get_field_object(self.cracked_wall_name)

	unity_object_pool.GetOrCreate(self.cracked_wall_effect_preset):Instantiate(
			cracked_wall.Position + vector(0, 1, 0))

	music_player_util.play_sfx({ sfx_name = '02_explosion_02', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.3, 0.5)

	wait_for_sec(0.2)

	cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
	cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

	cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	cracked_wall.Interactable = CS.Oak.NonInteractable.Instance
end

function local_class:on_fall_in_hole_start_event(e)
	if not lua_helper.reference_equals(e.Target, user_party.Leader) then
		user_party:ResetControllers()
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
