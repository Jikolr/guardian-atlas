local local_class = newclass("AfterWorld1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 시작 구역 npc 세팅
	self.optimized_npcs = {}
	self.dead_npc_list = {}
	self.dead_npc_count = 25
	self.dead_tint_color = unity_color({ 0.4, 0.4, 0.4, 1 })
	self.fade_color = unity_color({ 0, 0, 0, 1 })

	-- tentacle_zone_appear_list
	self.tentacle_zone_list = {
		{
			target = get_character('s17_civilian_2'),
			zone = 'tentacle_appear_zone_1_1',
			tentacle = {
				get_character('event_wall_tentacle_1_1'),
				get_character('event_wall_tentacle_1_2'),
			},
			pos = {
				field:GetMarker('event_tentacle_1_1').position,
				field:GetMarker('event_tentacle_1_2').position,
			},
			appear_check = false
		},
		{
			target = get_character('s17_civilian_2'),
			zone = 'tentacle_appear_zone_1_2',
			tentacle = {
				get_character('event_wall_tentacle_1_3'),
				get_character('event_wall_tentacle_1_4'),
			},
			pos = {
				field:GetMarker('event_tentacle_1_3').position,
				field:GetMarker('event_tentacle_1_4').position,
			},
			appear_check = false
		},
		{
			target = get_character('main_character'),
			zone = 'tentacle_appear_zone_2_1',
			tentacle = {
				get_character('event_wall_tentacle_2_1'),
				get_character('event_wall_tentacle_2_2'),
			},
			pos = {
				field:GetMarker('event_tentacle_2_1').position,
				field:GetMarker('event_tentacle_2_2').position,
			},
			appear_check = false
		},
		{
			target = get_character('main_character'),
			zone = 'tentacle_appear_zone_2_2',
			tentacle = {
				get_character('event_wall_tentacle_2_3'),
				get_character('event_wall_tentacle_2_4'),
			},
			pos = {
				field:GetMarker('event_tentacle_2_3').position,
				field:GetMarker('event_tentacle_2_4').position,
			},
			appear_check = false
		},
		{
			target = get_character('main_character'),
			zone = 'tentacle_appear_zone_2_3',
			tentacle = {
				get_character('event_wall_tentacle_2_5'),
				get_character('event_wall_tentacle_2_6'),
			},
			pos = {
				field:GetMarker('event_tentacle_2_5').position,
				field:GetMarker('event_tentacle_2_6').position,
			},
			appear_check = false
		},
		{
			target = get_character('main_character'),
			zone = 'tentacle_appear_zone_2_4',
			tentacle = {
				get_character('event_wall_tentacle_2_7'),
				get_character('event_wall_tentacle_2_8'),
			},
			pos = {
				field:GetMarker('event_tentacle_2_7').position,
				field:GetMarker('event_tentacle_2_8').position,
			},
			appear_check = false
		},
		{
			target = get_character('main_character'),
			zone = 'tentacle_appear_zone_3_1',
			tentacle = {
				get_character('event_wall_tentacle_3_1'),
				get_character('event_wall_tentacle_3_2'),
				get_character('event_wall_tentacle_3_3'),
				get_character('event_wall_tentacle_3_4'),
			},
			pos = {
				field:GetMarker('event_tentacle_3_1').position,
				field:GetMarker('event_tentacle_3_2').position,
				field:GetMarker('event_tentacle_3_3').position,
				field:GetMarker('event_tentacle_3_4').position,
			},
			appear_check = false
		},
	}

	self.wall_tentacle_list = {
		get_character('wall_tentacle_1_1'),
		get_character('wall_tentacle_1_2'),
		get_character('wall_tentacle_1_3'),
		get_character('wall_tentacle_1_4'),
		get_character('event_wall_tentacle_1_1'),
		get_character('event_wall_tentacle_1_2'),
		get_character('event_wall_tentacle_1_3'),
		get_character('event_wall_tentacle_1_4'),
		get_character('event_wall_tentacle_2_1'),
		get_character('event_wall_tentacle_2_2'),
		get_character('event_wall_tentacle_2_3'),
		get_character('event_wall_tentacle_2_4'),
		get_character('event_wall_tentacle_2_5'),
		get_character('event_wall_tentacle_2_6'),
		get_character('event_wall_tentacle_2_7'),
		get_character('event_wall_tentacle_2_8'),
		get_character('event_wall_tentacle_3_1'),
		get_character('event_wall_tentacle_3_2'),
		get_character('event_wall_tentacle_3_3'),
		get_character('event_wall_tentacle_3_4'),
		get_character('wall_tentacle_2_1'),
		get_character('wall_tentacle_2_2'),
		get_character('event_reaper_tentacle_1'),
		get_character('event_reaper_tentacle_2'),
		get_character('event_reaper_tentacle_3'),
		get_character('event_civilian_tentacle_1'),
		get_character('event_civilian_tentacle_2'),
		get_character('event_civilian_tentacle_3'),
		get_character('event_civilian_tentacle_4'),
		get_character('event_civilian_tentacle_5')
	}

	-- 플레이어 부착할 bone follower
	self.bone_follower = nil

	-- 공격 범위
	self.attack_radius = 1

	-- qte
	self.tentacle_qte_loop = false

	-- qte 시작 변수
	self.is_qte_start = false

	-- 탭 카운트
	self.turbo_tap_count = 0

	-- 중복 방지
	self.req_cnt = 0

	-- 회사 게이트
	self.main_gate_name = 'main_gate_door'

	self.tentacle_loop_sfx_list = {}

	self.start_room_loop_sfx = nil
	self.s20_square_loop_sfx = nil
	self.s20_hall_loop_sfx = nil

	-- ResourceHolder
	self.resource_holder = nil

	-- 동적 로드 배경
	self.bg_corporation = nil
	self.bg_hotel = nil
end

function local_class:load_resource()
	-- 4스테이지에서 2Bone써야해서 설정 바꿔줌
	CS.UnityEngine.QualitySettings.skinWeights = CS.UnityEngine.SkinWeights.TwoBones

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	CS.Oak.CommonScreenplay.PreloadTutorialSpine()

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	-- 단순 배치용 NPC를 동적으로 생성
	self.optimized_npcs = load_util.create_optimized_npcs_async({
		dead_npc_1 = 'aw_ghost_male',
		dead_npc_2 = 'aw_ghost_female',
		dead_npc_3 = 'aw_ghost_teatan_male',
		dead_npc_4 = 'aw_ghost_teatan_female',
		dead_npc_5 = 'aw_ghost_snowman_male',
		dead_npc_6 = 'aw_ghost_china_female',
		dead_npc_7 = 'aw_ghost_civilian_female',
		dead_npc_8 = 'aw_ghost_male',
		dead_npc_9 = 'aw_ghost_female',
		dead_npc_10 = 'aw_ghost_teatan_male',
		dead_npc_11 = 'aw_ghost_teatan_female',
		dead_npc_12 = 'aw_ghost_snowman_male',
		dead_npc_13 = 'aw_ghost_china_female',
		dead_npc_14 = 'aw_ghost_civilian_female',
		dead_npc_15 = 'aw_ghost_male',
		dead_npc_16 = 'aw_ghost_teatan_male',
		dead_npc_17 = 'aw_ghost_teatan_male',
		dead_npc_18 = 'aw_ghost_teatan_male',
		dead_npc_19 = 'aw_ghost_female',
		dead_npc_20 = 'aw_ghost_male',
		dead_npc_21 = 'aw_ghost_female',
		dead_npc_22 = 'aw_ghost_teatan_male',
		dead_npc_23 = 'aw_ghost_teatan_female',
		dead_npc_24 = 'aw_ghost_snowman_male',
		dead_npc_25 = 'aw_ghost_china_female',
	})

	-- 촉수 scale 및 못 넘어가도록 조정
	for i, tentacle in ipairs(self.wall_tentacle_list) do
		character_util.set_scale_factor(tentacle, nil, 0.7)
		tentacle.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		tentacle.Hitbox = CS.Oak.Hitbox(vector(2, 1, 2))
		field_ui_manager:RemoveUI(tentacle, CS.Oak.FieldUiType.CharacterStats)
		tentacle.EntityGroup = CS.Oak.EntityGroups.Enemy
		stage.BattleManager:AddToNoAssassination(tentacle)

		self:play_tentacle_loop_sfx(tentacle, '01_tentacle_03')
	end

	for i = 1, 4 do
		local tentacle = get_character('tentacle_' .. i)
		field_ui_manager:RemoveUI(tentacle, CS.Oak.FieldUiType.CharacterStats)
		tentacle.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	end

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	-- 메인을 클리어 한 상태라면, 심판의 문 상호작용을 불가능하게
	if quest_progress ~= nil and quest_progress.IsComplete then
		local judge_gate = get_field_object('exit_7')
		judge_gate.Interactable = CS.Oak.NonInteractable.Instance
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resource_holder, 'ondemand/afterworld/tilesets', 'bg_aw_corporation', function(prefab)
				self.bg_corporation = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	local exit_corp = get_field_object('exit_6')
	self.bg_corporation.transform.localPosition = exit_corp.Position + vector(0.5, 0, 8.1)
	self.bg_corporation.transform.localScale = unity_class.vector3.one

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resource_holder, 'ondemand/afterworld/tilesets', 'bg_aw_hotel', function(prefab)
				self.bg_hotel = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	local exit_hotel = get_field_object('hotel_entrance_1')
	self.bg_hotel.transform.localPosition = exit_hotel.Position + vector(0.5, 0, 5.5)
	self.bg_hotel.transform.localScale = unity_class.vector3.one
end

function local_class:need_on_launch()
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	local progress_list = {
		15, 16, 17, 18, 19
	}

	if quest_progress ~= nil then
		if not quest_progress.IsComplete then
			for i = 1, #progress_list do
				if quest_progress.InnerProgress == progress_list[i] then
					return true
				end
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	-- 4스테이지: 15 ~ 20
	if quest_progress ~= nil and not quest_progress.IsComplete then
		if quest_progress.InnerProgress == 16 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				music_player_util.set_stage_music_clip_async({ name = 'bgm_suspense_theme', state = 'field' })
				stage_launch_util.default_launch_with_marker_name('section_start_point')
			end))
		elseif quest_progress.InnerProgress == 17 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				music_player_util.set_stage_music_clip_async({ name = 'bgm_suspense_theme', state = 'field' })

				local leader = get_character('main_character')
				character_util.set_position(leader, field:GetMarker('boss_floor').position)
				character_util.set_direction(leader, 'right')
				camera_util.move_async(leader.Position, 0.1, { end_target = leader })
				screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
				screen_util.fade_in_circular(1, 'linear')
				coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
						leader.Direction, game_string:GetString(stage.Name)))
			end))
		end
	end
end

function local_class:dispose()
	load_util.dispose_optimized_npcs(self.optimized_npcs)
	self.optimized_npcs = nil

	self.dead_npc_list = nil
	self.wall_tentacle_list = nil
	self.tentacle_zone_list = nil

	self:all_stop_tentacle_loop_sfx()
	self.tentacle_loop_sfx_list = nil

	if self.start_room_loop_sfx then
		self.start_room_loop_sfx:Stop()
		self.start_room_loop_sfx = nil
	end

	if self.s20_square_loop_sfx then
		self.s20_square_loop_sfx:Stop()
		self.s20_square_loop_sfx = nil
	end

	if self.s20_hall_loop_sfx then
		self.s20_hall_loop_sfx:Stop()
		self.s20_hall_loop_sfx = nil
	end

	if self.bg_corporation then
		CS.UnityEngine.GameObject.Destroy(self.bg_corporation)
		self.bg_corporation = nil
	end

	if self.bg_hotel then
		CS.UnityEngine.GameObject.Destroy(self.bg_hotel)
		self.bg_hotel = nil
	end

	if self.resource_holder then
		self.resource_holder:Dispose()
		self.resource_holder = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.bone_follower ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.bone_follower)
		self.bone_follower = nil
	end

	self.cs_controller = nil

	-- OneBone으로 다시 복구
	CS.UnityEngine.QualitySettings.skinWeights = CS.UnityEngine.SkinWeights.OneBone
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		return self:on_touch_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	self:setting_npc()
	self:set_one_line_npc()

	-- 문 기본적으로 열려 있도록 수정
	local gate = get_field_object(self.main_gate_name)
	local animator = gate.Transform:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('open', -1, 1)

	return false
end

function local_class:on_stage_start_event(e)
	return false
end

function local_class:on_touch_event(e)
	if not self.is_qte_start then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.TouchDown then
		if self.tap_sfx_name then
			music_player_util.play_sfx_one_shot(self.tap_sfx_name)
		end
		self.turbo_tap_count = self.turbo_tap_count + 1
		return true
	end

	return false
end

-- section에서 요청을 받아 fade 연출
function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'dead_npc_fade_out' then
		for i, npc in ipairs(self.dead_npc_list) do
			character_util.spine_set_alpha_fade(npc, 0, 0)
		end
		return true
	elseif e:GetParamAt(0) == 'dead_npc_fade_in' then
		for i, npc in ipairs(self.dead_npc_list) do
			character_util.spine_set_alpha_fade(npc, 1, 1)
		end
		return true
	end
	return false
end

function local_class:on_zone_enter_event(e)
	-- 촉수 등장 로직
	for i = 1, #self.tentacle_zone_list do
		local target = self.tentacle_zone_list[i].target
		if type_util.is_zone_full_enter(e, target, self.tentacle_zone_list[i].zone) and
				not self.tentacle_zone_list[i].appear_check then
			self.tentacle_zone_list[i].appear_check = true

			-- 촉수 등장
			for j = 1, #self.tentacle_zone_list[i].tentacle do
				local tentacle = self.tentacle_zone_list[i].tentacle[j]
				character_util.set_position(tentacle, self.tentacle_zone_list[i].pos[j])
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tentacle_appear, self, tentacle))
			end

			-- shake
			if screen_util.is_fo_in_screen(target.Position) then
				camera_util.shake(0.2, 0.5)
			end
			return true
		end
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, 'tentacle_qte_zone') then
		self.tentacle_qte_loop = true
		self.req_cnt = self.req_cnt + 1
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.qte_zone_routine, self))
		return true
	elseif type_util.is_zone_full_enter(e, user_party.Leader, 'start_room') then
		if self.start_room_loop_sfx then
			self.start_room_loop_sfx:Stop()
			self.start_room_loop_sfx = nil
		end
		local zone = field:GetZone('start_room')
		self.start_room_loop_sfx = music_player_util.play_sfx({ sfx_name = '01_effect_beth_01', play_pos = zone.Bounds.center, loop = true, type_priority = 'loop', player_priority = 'default' })
		return true
	elseif type_util.is_zone_full_enter(e, user_party.Leader, 's20_square') then
		local zone = field:GetZone('s20_square')

		if self.s20_square_loop_sfx then
			self.s20_square_loop_sfx:Stop()
		end

		self.s20_square_loop_sfx = music_player_util.play_sfx({ sfx_name = '01_crowd_buzz_03', play_pos = zone.Bounds.center, loop = true, type_priority = 'loop', player_priority = 'default' })
		return true
	elseif type_util.is_zone_full_enter(e, user_party.Leader, 's20_hall') then
		local zone = field:GetZone('s20_hall')

		if self.s20_hall_loop_sfx then
			self.s20_hall_loop_sfx:Stop()
		end

		self.s20_hall_loop_sfx = music_player_util.play_sfx({ sfx_name = '01_crowd_buzz_03', play_pos = zone.Bounds.center, min_distance = 10, max_distance = 14, loop = true, type_priority = 'loop', player_priority = 'default' })
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, 'tentacle_qte_zone') then
		self.tentacle_qte_loop = false
		return true
	elseif type_util.is_zone_full_leave(e, user_party.Leader, 'start_room') then
		if self.start_room_loop_sfx then
			self.start_room_loop_sfx:Stop()
			self.start_room_loop_sfx = nil
		end
		return true
	elseif type_util.is_zone_full_leave(e, user_party.Leader, 's20_square') then
		if self.s20_square_loop_sfx then
			self.s20_square_loop_sfx:Stop()
			self.s20_square_loop_sfx = nil
		end
	elseif type_util.is_zone_full_leave(e, user_party.Leader, 's20_hall') then
		if self.s20_hall_loop_sfx then
			self.s20_hall_loop_sfx:Stop()
			self.s20_hall_loop_sfx = nil
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for i, tentacle in ipairs(self.wall_tentacle_list) do
		if lua_helper.reference_equals(tentacle, e.FieldObject) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tentacle_hidden, self, tentacle))
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 'office_inner_grid') then
		local shake_reaper = get_character('s20_oneline_npc_inner_4')
		character_util.stop_shake(shake_reaper)
		character_util.shake(shake_reaper, 0.02, 9999)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reaper_moving, self))
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'office_inner_grid') then
		local shake_reaper = get_character('s20_oneline_npc_inner_4')
		character_util.stop_shake(shake_reaper)
		self.is_reaper_moving = false
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	local exit_hotel = get_field_object('hotel_entrance_1')
	local exit_corp = get_field_object('exit_6')

	if lua_helper.reference_equals(e.Target, exit_hotel) then
		sp_util.play_normal_screenplay(self.interact_exit_to_background, self, e.Target, 's20_hotel_in_pos', vector(0, 0, 6.5))
	elseif lua_helper.reference_equals(e.Target, exit_corp) then
		sp_util.play_normal_screenplay(self.interact_exit_to_background, self, e.Target, 's20_company_in_pos', vector(0, 0, 9))
	end
end

--endregion

-- 쓰러저 있는 NPC들은 아무 기능도 하지 않으므로 동적할당으로 생성하였음
function local_class:setting_npc()
	self.dead_npc_list = {}
	for i = 1, self.dead_npc_count do
		table.insert(self.dead_npc_list, self.optimized_npcs['dead_npc_' .. i])
	end

	for i, npc in ipairs(self.dead_npc_list) do
		character_util.set_direction(npc, field:GetMarker('dead_npc_pos_' .. i).direction)
		character_util.set_position(npc, field:GetMarker('dead_npc_pos_' .. i).position)
		field_ui_manager:RemoveUI(npc, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_anim_and_emotion(npc, { name = 'prostrate', loop = false }, { name = 'damaged' })
		npc.SpineController:AddColor(nil, self.dead_tint_color, 1, 0)
	end
end

function local_class:set_one_line_npc()
	-- 통로 방 사신이 돌 들고 있도록 세팅
	local move_reaper = get_character('s20_move_reaper')
	move_reaper.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	local chair = get_field_object('s20_move_chair')
	command_util.execute_holdup(move_reaper, chair, move_reaper.Position, 0, false)

	-- 퀘스트를 클리어 한 후에만 타오 및 어그로걸 마티 롤링넘버를 스테이지 컨트롤러에서 처리
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	if quest_progress.IsComplete then
		local tao = get_character('tao_one_line')
		character_util.set_rolling_number(tao.Transform, 652000, nil, 0
		, unity_color({ 0, 0.7, 1, 1 }))

		local marty = get_character('marty_one_line')
		character_util.set_rolling_number(marty.Transform, 475200, nil, 0
		, unity_color({ 0, 0.7, 1, 1 }))

		local aggro_girl = get_character('aggro_girl_one_line')
		character_util.set_rolling_number(aggro_girl.Transform, 454000, nil, 0
		, unity_class.color.red)
	end

	-- 남은 일반 npc 롤링넘버 세팅
	local numbers = {
		54225, 12485, 25348, 88542, 0, 75423, 22485, 35264, 87513, 48224, 56125, 55247, 73148
	}

	for i = 1, 13 do
		local one_line_npc = get_character('s20_oneline_npc_' .. i)
		if i ~= 5 then
			character_util.set_rolling_number(one_line_npc.Transform, numbers[i], nil, 0
			, unity_color({ 0, 0.7, 1, 1 }))
		end
	end

	numbers = { 34252, 83622, 26734 }
	for i = 1, 3 do
		local one_line_npc = get_character('s20_oneline_hotel_npc_' .. i)
		character_util.set_rolling_number(one_line_npc.Transform, numbers[i], nil, 0
		, unity_color({ 0, 0.7, 1, 1 }))
	end

	self.is_right_move = true
end

-- 촉수 등장 로직
function local_class:tentacle_appear(tentacle, attach_target)
	local duration = 0.5
	local attach_timing = 0.2
	local is_attach = false
	local is_camera_up = false

	if attach_target then
		self.bone_follower = nil
		tentacle.Position = vector_util.get_x0z(attach_target.Position)
	else
		tentacle.Position = vector_util.get_x0z(tentacle.Position)
	end

	local animation_duration = spine_util.get_animation_duration(tentacle, 'in')
	local animation_scale = animation_duration / duration

	music_player_util.play_sfx({ sfx_name = '01_tentacle_01', parent = tentacle, type_priority = 'event', player_priority = 'npc' })
	character_util.set_animation_n_times(tentacle, { name = 'in', scale = animation_scale, mix_duration = 0 })
	tentacle.SpineController:ForceUpdateSpines(0)

	local time_passed = 0
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		if attach_target then
			if not is_attach and time_passed >= attach_timing then
				is_attach = true

				attach_target.SpineController.IsShadowActive = false

				music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = attach_target, type_priority = 'event', player_priority = 'npc' })
				character_util.set_anim_and_emotion(attach_target,
						{ name = 'embarrassed' }, { name = 'damaged' })

				self.bone_follower = attach_target.UnityGameObject:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
				self.bone_follower.followBoneRotation = false
				self.bone_follower.SkeletonRenderer = tentacle.SpineController.SkeletonAnimation
				self.bone_follower:SetBone('bone15')
			end

			if not is_camera_up and is_attach then
				is_camera_up = true

				camera_util.move(
						vector_util.get_x0z(attach_target.Position) + vector(0, 3, 0), 3 / 11)
			end
		end

		coroutine.yield()
	end

	self:play_tentacle_loop_sfx(tentacle, '01_effect_beth_01')
	tentacle.Position = vector_util.get_x0z(tentacle.Position)
end

-- 촉수 퇴장 로직
function local_class:tentacle_hidden(tentacle, attach_target)
	local duration = 0.5
	local target_y = 0

	local animation_duration = spine_util.get_animation_duration(tentacle, 'out')
	local animation_scale = animation_duration / duration

	self:stop_tentacle_loop_sfx(tentacle)
	music_player_util.play_sfx({ sfx_name = '01_tentacle_02', play_pos = tentacle.Position, type_priority = 'event', player_priority = 'npc' })
	character_util.set_animation_n_times(tentacle, { name = 'out', scale = animation_scale })

	if attach_target then
		CS.UnityEngine.GameObject.Destroy(self.bone_follower)
		self.bone_follower = nil

		target_y = attach_target.Position.y
		attach_target.SpineController.IsShadowActive = true
		character_util.spine_rotate(attach_target, 0, duration)
		character_util.stop_shake(attach_target)
		character_util.set_anim_and_emotion(attach_target, { name = 'embarrassed' }, { name = 'surprise' })
	end

	local time_passed = 0
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseOutSine(time_passed, 0, 1, duration))

		if attach_target then
			progress = CS.Oak.Interpolations.Linear(time_passed, 0, target_y, duration)
			local cur_target_y = target_y - progress
			local cur_pos = vector_util.get_x0z(attach_target.Position, cur_target_y)
			attach_target.Position = cur_pos
		end

		coroutine.yield()
	end

	tentacle.Position = vector(999, 0, 999)
end

-- 촉수 qte
function local_class:tentacle_qte()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local leader = get_party_leader()
	local tentacle = get_character('tentacle_1')
	local position = leader.Position

	camera_util.shake(0.2, 0.5)
	self:tentacle_appear(tentacle, leader)
	--주인공 : 으아아아!!!
	speech_bubble_util.show_speech_bubble(leader, { key = 'afterworld_main_s16_8' })
	self:turbo_tap({ count = 20, tap_sfx = '01_rustle_01' })

	camera_util.shake(0.2, 0.5)
	self:tentacle_hidden(tentacle, leader)

	character_util.set_position(leader, vector_util.get_x0z(leader.Position))

	character_util.set_emotion(leader, { name = 'damaged' })
	character_util.set_anim(leader, { name = 'prostrate' })
	camera_util.return_to_leader(0.5)

	music_player_util.play_sfx_one_shot('01_player_popup_01')
	local direction = vector_util.to_direction(position - leader.Position)
	character_util.remove_emotion(leader)
	character_util.mario_jump_new(leader, direction)
	character_util.move_to_async(leader, position, 0.3, nil)

	party_util.reset_controllers()
	field_ui_manager:Show()
end

--- 터치 연타함수
--- @param is_wait boolean key: 성공 시에도 duration 시간만큼 기다려줄지
--- @param pre_delay number key: qte 연타 시작 시 일정 시간동안 입력을 받지 않고 싶을 때 사용
--- @param count number key: qte 연타 성공을 위한 횟수
--- @param animation_time_scale number key: qte 스파인 손가락 애니메이션 빠르기
--- @param tap_sfx nil key: qte 터치 시 마다 재생할 sfx
function local_class:turbo_tap(data)
	local delay = lua_helper.get_value(data, 'pre_delay', nil)
	local count = lua_helper.get_value(data, 'count', 1)
	local animation_time_scale = lua_helper.get_value(data, 'animation_time_scale', 1)
	self.tap_sfx_name = lua_helper.get_value(data, 'tap_sfx', nil)

	music_player_util.play_sfx_one_shot('01_tap_guide_01')
	CS.Oak.CommonScreenplay.ShowTurboTap(animation_time_scale)

	if delay then wait_for_sec(delay) end

	local shake_scale = 1
	self.turbo_tap_count = 0
	self.is_qte_start = true

	while self.is_qte_start and self.turbo_tap_count < count do

		if self.turbo_tap_count >= shake_scale then
			character_util.shake(get_party_leader(), shake_scale * 0.02, 999)
		end
		coroutine.yield()
	end

	self.is_qte_start = false
	CS.Oak.CommonScreenplay.CloseTutorialSpine()
end

function local_class:qte_zone_routine()
	local req_cnt = self.req_cnt
	local tentacle = get_character('tentacle_1')

	while self.tentacle_qte_loop and req_cnt == self.req_cnt do
		local attack_pos = user_party.Leader.Position
		local bombard_range = CS.AttackRange.CreateCircle(attack_pos + vector(0, 0.1, 0), self.attack_radius)

		bombard_range:Show()

		music_player_util.play_sfx({ sfx_name = '01_creature_02', play_pos = attack_pos, type_priority = 'event', player_priority = 'npc' })
		wait_for_sec(1.2)

		bombard_range:Hide()

		local collide_objs = field:GetFieldObjectsInRadius(attack_pos, self.attack_radius)
		local check_player = false

		for i = 0, collide_objs.Count - 1 do
			local fo = collide_objs[i]

			if lua_helper.reference_equals(fo, user_party.Leader) then
				if not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
					check_player = true
					self:tentacle_qte()

					wait_for_sec(1)
				end
			end
		end

		if not check_player then
			character_util.set_position(tentacle, vector_util.get_x0z(attack_pos, -10))
			if screen_util.is_fo_in_screen(tentacle.Position) then
				camera_util.shake(0.2, 0.5)
			end
			self:tentacle_appear(tentacle, nil)

			wait_for_sec(0.5)

			if screen_util.is_fo_in_screen(tentacle.Position) then
				camera_util.shake(0.2, 0.5)
			end

			self:tentacle_hidden(tentacle)
		end

		wait_for_sec(1.5)
	end
end

--
function local_class:reaper_moving()
	self.is_reaper_moving = false
	coroutine.yield(nil)
	coroutine.yield(nil)
	self.is_reaper_moving = true

	local reaper = get_character('s20_move_reaper')
	local start_pos = vector(125.5, 0, -0.5)
	local end_pos = vector(150.5, 0, -0.5)
	while self.is_reaper_moving do
		wait_for_sec(0.5)
		local target_pos = self.is_right_move and end_pos or start_pos
		character_util.move_to_async(reaper, target_pos, nil, 4, true, true)
		if not self.is_reaper_moving then break end
		self.is_right_move = self.is_right_move == false
	end
	character_util.stop(reaper)
end

--region tentacle_loop_sfx
function local_class:play_tentacle_loop_sfx(tentacle, sfx_name)
	self:stop_tentacle_loop_sfx()

	self.tentacle_loop_sfx_list[tentacle] = music_player_util.play_sfx({ sfx_name = sfx_name, parent = tentacle, loop = true, type_priority = 'loop', player_priority = 'npc' })
end

function local_class:stop_tentacle_loop_sfx(tentacle)
	if self.tentacle_loop_sfx_list[tentacle] then
		self.tentacle_loop_sfx_list[tentacle]:Stop()
		self.tentacle_loop_sfx_list[tentacle] = nil
	end
end

function local_class:all_stop_tentacle_loop_sfx()
	for key, value in pairs(self.tentacle_loop_sfx_list) do
		value:Stop()
		self.tentacle_loop_sfx_list[key] = nil
	end
end
--endregion

-- 호텔 / 회사로 이동
function local_class:interact_exit_to_background(exit_object, marker_name, camera_offset)
	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 2)
		character_util.move_to(user_party[i], user_party[i].Position + vector(0, 0, 2),
				2, nil, true, true)
	end

	camera_util.resize_to(3.5, 3)
	camera_util.move(exit_object.Position + camera_offset, 3)

	wait_for_sec(2)

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'disabled')
	end

	wait_for_sec(2)

	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')

	screen_util.fade_out_circular_async(0.6, 'linear')

	camera_util.resize_to_default(0)
	stage_camera:SetTarget(get_party_leader())

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'enabled')
		character_util.spine_set_alpha_fade(user_party[i], 1, 0)
	end

	local cur_marker = field:GetMarker(marker_name)

	party_util.align_party(cur_marker.position + CS.Oak.DirectionExtensions.ToVector3(cur_marker.direction),
			CS.Oak.DirectionExtensions.GetOpposite(cur_marker.direction), 0, 'linear')

	wait_for_sec(0.6)

	screen_util.fade_in_circular_async(0.6, 'linear')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
