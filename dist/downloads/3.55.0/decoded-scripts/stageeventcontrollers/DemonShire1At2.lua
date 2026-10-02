local local_class = newclass('DemonShire1At2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end
	-- 소히 받아오기
	self.get_sohee = function()
		return get_character('sohee')
	end
	-- 프리실라 받아오기
	self.get_count_daughter = function()
		return get_character('count_daughter')
	end
	-- 수용소 4번 출구 막는 npc 가져오기
	self.get_blocking_guard = function(idx)
		return get_character('blocking_guard_' .. idx)
	end
	-- 잔해에 깔린 npc 받아오기
	self.get_s4_guard = function(idx)
		return get_character('s4_guard_' .. idx)
	end
	-- 수용소 일반 순찰 간수들 받아오기
	self.get_guards = function(idx)
		return get_character('s5_guard_' .. idx)
	end
	-- 수용소 추가 순찰 간수 받아오기
	self.get_new_guard = function()
		return get_character('s6_guard_1')
	end

	self.get_city_guardpost = function(idx)
		return get_field_object('city_guardpost_' .. idx)
	end
	self.get_prison_inner = function()
		return get_field_object('prison_inner_1')
	end
	self.get_camp_inner = function()
		return get_field_object('camp_inner')
	end
	-- 섹션 6 부터 부술 수 있는 잔해만 받아오기
	self.get_shortcut_wreck = function(idx)
		return get_field_object('shortcut_wreck_' .. idx)
	end
	-- 도망자 감옥 문 받아오기
	self.get_escape_room_door = function()
		return get_field_object('escape_room_door')
	end
	-- 소히 감옥 문 받아오기
	self.get_sohee_prison_door = function()
		return get_field_object('sohee_prison_door')
	end
	-- 감옥 문들 받아오기
	self.get_irongate = function(idx)
		return get_field_object('irongate_' .. idx)
	end
	-- 낙석 받아오기
	self.get_falling_rock = function()
		return get_field_object('falling_rock_oneline_event_4')
	end
	-- 소히 무기상자 받아오기
	self.get_sohee_weapon_box = function()
		return get_field_object('sohee_weapon_box')
	end
	-- 쥐폭탄 받아오기
	self.get_mouse_bomb = function()
		return get_field_object('mouse_bomb_1')
	end
	-- 어두운 방에 있는 돌 받아오기
	self.get_dark_room_rock = function()
		return get_field_object('dark_room_rock')
	end
	-- 잠자는 간수의 열쇠 받아오기
	self.get_sleeping_guard_key = function()
		return get_field_object('sleeping_guard_key')
	end

	self.paper_item = nil

	-- FX
	self.magiton_laser_effect_preset = 'Manual_AssaultRifle_GhostBuster_Magiton'
	self.fx_dead = 'FX_dead'
	self.fx_landslide_brown_small = 'fx_cp11_rock_landslide_brown_small'
	self.fx_smokescreen = 'FX_Common_SmokeScreen'
	self.fx_last_hit = 'FX_lasthit'
	self.fx_hit = 'FX_hit'
	self.twinkle_preset = 'FX_Object_Twinkle'

	self.box_1_twinkle_fx = nil
	self.box_2_twinkle_fx = nil

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	-- Zones
	self.dark_room_event_zone = 's5_dark_room_zone'

	-- Falgs
	self.is_shortcut_wreck_destroyed_once = false
	self.is_lever_pulled = false
	self.is_detected = false
	self.is_prisoner_1_dead = false

	-- Interactable Fos
	self.get_dark_room_lever = function()
		return get_field_object('light_generator_switch')
	end
	self.get_box = function(idx)
		return get_field_object('box_' .. idx)
	end

	-- 원라인 이벤트 커스텀 스테이트 번호
	self.oneline_event_state = {
		event_1 = 1,
		event_2 = 2,
		event_3 = 4,
		event_4 = 8,
		event_5 = 16,
		event_6 = 32,
		event_7 = 64
	}
	self.cur_oneline_event_state = nil
	self.oneline_event_state_key = 'demonshire_1_2_oneline_event'

	self.saw_online_event_8 = false
	self.saw_online_event_9 = false
	self.saw_online_event_10 = false
	self.saw_online_event_12 = false

	self.get_oneline_npc = function(event_idx, npc_idx)
		return get_character('oneline_event_' .. event_idx .. '_npc_' .. npc_idx)
	end

	self.attack_repeat_on = false
	self.guard_loop_condition = true

	-- 리셋 할 때 필요한 마커 저장
	self.detected_reset_marker_name = {
		ds_s5_detected_1 = 's5_detected_reset_1',
		ds_s5_detected_2 = 's5_detected_reset_2',
		ds_s5_detected_3 = 's5_detected_reset_3',
		ds_s5_detected_4 = 's5_detected_reset_4',
		ds_s5_detected_5 = 's5_detected_reset_5',
		ds_s5_detected_6 = 's5_detected_reset_6'
	}

	-- 순찰하는 일반 간수들 캐싱 테이블
	self.detect_guards = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.magiton_laser_effect_preset)
	unity_object_pool.GetOrCreate(self.fx_dead)
	unity_object_pool.GetOrCreate(self.fx_landslide_brown_small)
	unity_object_pool.GetOrCreate(self.fx_smokescreen)
	unity_object_pool.GetOrCreate(self.fx_last_hit)
	unity_object_pool.GetOrCreate(self.fx_hit)
	unity_object_pool.GetOrCreate(self.twinkle_preset)

	yield_return(unity_object_pool, 'WaitAll')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	-- 무조건 on_launch 런치에서 제어
	--TODO: 개발 상황에 따라 다르게 할 수도 있음
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 2 then
		change_leader_character()
		start_stage_event('left', field:GetMarker('s3_start_pos').position, false, false)
	elseif main_quest_progress.InnerProgress == 3 then
		change_leader_character()
		start_stage_event('left', field:GetMarker('s4_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 4 then
		change_leader_character()
		start_stage_event('left', field:GetMarker('s5_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 5 then
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('s6_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 6 then
		-- 섹션 7일 때 입장 하면 소히를 파티원으로 추가
		change_leader_character({ self.get_sohee() })
		start_stage_event('left', field:GetMarker('s7_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 7 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		start_stage_event('left', field:GetMarker('camp_outer').position, true, true)
	else
		--TODO: 나머지 섹션별로 위치 정해줘야 할듯
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 2 then
		-- 원라인 npc들은 퀘스트 클리어 이후 처리하지 않음
		if not main_quest_progress.IsComplete then
			self:set_prison_guard_arguing(main_quest_progress.InnerProgress)
		end

		self.get_prison_inner().ActiveState = CS.Oak.ActiveState.InField
		self.get_camp_inner().ActiveState = CS.Oak.ActiveState.InField

	end

	-- 게이트 열려있으면 열쇠 숨기고 리셋 스위치로 초기화 안되게 처리
	if get_field_object('fourth_floor_key_door').FieldObjectBehaviour.Opened then
		get_field_object('holdable_key_reset_switch').FieldObjectBehaviour.CanResetGimmick = false
		get_field_object('fourth_floor_gate_key').ActiveState = active_state('disabled')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	self.attack_repeat_on = false
	self.guard_loop_condition = false

	if self.paper_item ~= nil then
		self.paper_item:ConsumeComplete()
		self.paper_item = nil
	end

	if self.box_1_twinkle_fx ~= nil then
		self.box_1_twinkle_fx:Dispose()
		self.box_1_twinkle_fx = nil
	end

	if self.box_2_twinkle_fx ~= nil then
		self.box_2_twinkle_fx:Dispose()
		self.box_2_twinkle_fx = nil
	end

	local prisoner_1 = self.get_oneline_npc(1, 1)
	if prisoner_1 ~= nil then
		character_util.remove_relate_event(prisoner_1, self.cs_controller)
	end

	self.cs_controller = nil
	self.scene = nil
end

--region events
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)

	if lua_helper.reference_equals(e.Target, self.get_oneline_npc(1, 1)) and
			not self.is_prisoner_1_dead then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.prisoner_1_dead, self))
	else
		local shortcut_wreck_idx = 1
		while true do
			local shortcut_wreck = self.get_shortcut_wreck(shortcut_wreck_idx)
			if shortcut_wreck == nil then
				break
			end
			shortcut_wreck_idx = shortcut_wreck_idx + 1

			if lua_helper.reference_equals(e.Target, shortcut_wreck) then
				sp_util.play_normal_screenplay(self.destroy_shortcut_wreck, self, shortcut_wreck)
				return true
			end
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.cur_oneline_event_state = quest_util.get_custom_state(main_quest_progress, self.oneline_event_state_key)
	if self.cur_oneline_event_state == -1 then
		self.cur_oneline_event_state = 0
	end

	self:set_played_online_event_npc()
	self:set_patrol_guards_on_start()

	local box_1 = self.get_box(1)
	self.box_1_twinkle_fx = unity_object_pool.GetOrCreate(self.twinkle_preset):Instantiate(box_1.Bounds.center)

	local box_2 = self.get_box(2)
	self.box_2_twinkle_fx = unity_object_pool.GetOrCreate(self.twinkle_preset):Instantiate(box_2.Bounds.center)

	if main_quest_progress ~= nil then
		-- InnerProgress >= 5 소히 무기 있음
		if not main_quest_progress.IsComplete and main_quest_progress.InnerProgress >= 5
				and main_quest_progress.InnerProgress < 7 then
			-- 퀘스트를 깨지 않은 상태에서 6섹션(progress 5) 부터 7섹션(progress 6)까지만 돌을 부술 수 있도록 세팅한다.
			self:dark_room_empty()
			if self:is_character_in_party(self.get_sohee()) then
				self:set_wreck()
				self:set_prison_door()
				self.get_sohee_weapon_box().ActiveState = active_state('disabled')
			end
		elseif main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 7 then
			-- 퀘스트를 깼거나 8섹션 이상일 경우에는 길을 막는 바위 비활성화
			local wreck_count = 4
			for i = 1, wreck_count do
				local shortcut_wreck = self.get_shortcut_wreck(i)
				shortcut_wreck.ActiveState = active_state('disabled')
			end

			-- 어두운 방 부분 레버 땡긴걸로 변경
			self:dark_room_empty()

			-- 감옥 문 비활성화
			self:set_prison_door()

			-- 소히 박스 비활성화
			self.get_sohee_weapon_box().ActiveState = active_state('disabled')
		end

		-- 7섹션 이후로부터는 감옥 문 열어줌
		if main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 7 then
			local top_floor_door = get_field_object('top_floor_room_door_1')
			top_floor_door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			local animator = top_floor_door:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('on', -1)

			-- 도어락은 비활성화
			local door_lock = get_field_object('top_floor_door_lock')
			door_lock.ActiveState = active_state('disabled')
		end

		-- 수용소 4번 출구 막고 있는 npc 활성화
		if main_quest_progress.InnerProgress <= 6 then
			for i = 1, 2 do
				local blocking_guard = self.get_blocking_guard(i)
				character_util.set_active_state(blocking_guard, 'enabled')
			end
		end
	end
end

function local_class:on_stage_loaded_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		if main_quest_progress.InnerProgress >= 3 and main_quest_progress.InnerProgress <= 6 then
			local vampire_officer_1 = get_character('oneline_npc_15')
			local vampire_officer_2 = get_character('oneline_npc_16')
			local demon_officer_1 = get_character('oneline_npc_21')

			vampire_officer_1.SpineController:SetAttachment('[base]weapon1', 'monster_baton_sword')
			vampire_officer_2.SpineController:SetAttachment('[base]weapon1', 'monster_baton_sword')
			demon_officer_1.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
		end
	end

	local key_fo = self.get_sleeping_guard_key()
	key_fo.ActiveState = active_state('disabled')
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil then
		local param_0 = e.Params[0]

		if param_0 == 'destroy_shortcut_wreck_available' then
			self:set_wreck()
		elseif param_0 == 'interacting' then
			local sender = e.Sender
			if lua_helper.reference_equals(sender, self.get_box(1)) then
				sp_util.play_normal_screenplay(self.box_interact, self, 1, sender)
			elseif lua_helper.reference_equals(sender, self.get_box(2)) then
				sp_util.play_normal_screenplay(self.box_interact, self, 2, sender)
			end
		elseif e.Params.Length == 2 then
			if not self.is_detected then
				if param_0 == 'blocking_guard_alert_reset' then
					sp_util.play_normal_screenplay(self.blocking_guard_detect, self, e.Sender)
				else
					local reset_marker_name = self.detected_reset_marker_name[param_0]
					if reset_marker_name ~= nil then
						local reset_marker = field:GetMarker(reset_marker_name)
						sp_util.play_normal_screenplay(self.guard_detect, self, e.Sender, param_0, reset_marker)
					end
				end
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	local leader = user_party.Leader

	if (type_util.is_zone_full_enter(e, leader, self.dark_room_event_zone) or
			type_util.is_zone_full_enter(e, self.get_mouse_bomb(), self.dark_room_event_zone)) and
			self.is_lever_pulled then
		-- 어두운 방
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.toggle_dark_room_tint, self, true))
	elseif self.cur_oneline_event_state ~= nil then
		-- 원라인 이벤트
		if type_util.is_zone_full_enter(e, leader, 'oneline_event_2') and
				self:oneline_event_not_played(self.oneline_event_state.event_2) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_2, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_3') and
				self:oneline_event_not_played(self.oneline_event_state.event_3) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_3, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_4') and
				self:oneline_event_not_played(self.oneline_event_state.event_4) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_4, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_5') and
				self:oneline_event_not_played(self.oneline_event_state.event_5) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_5, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_6') and
				self:oneline_event_not_played(self.oneline_event_state.event_6) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_6, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_7') and
				self:oneline_event_not_played(self.oneline_event_state.event_7) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_7, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_8') and
				not self.saw_online_event_8 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_8, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_9') and
				not self.saw_online_event_9 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_9, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_10') and
				not self.saw_online_event_10 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_10, self))
		elseif type_util.is_zone_full_enter(e, leader, 'oneline_event_12') and
				not self.saw_online_event_12 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.oneline_event_12, self))
		end
	end

	if type_util.is_zone_full_enter(e, leader, 'prisoner_shake_zone_1') then
		local shake_npc_2_1 = self.get_oneline_npc(2, 1)
		if not self:check_npc_disabled(shake_npc_2_1) then
			character_util.shake(shake_npc_2_1, 0.03, 9999)
		end
	elseif type_util.is_zone_full_enter(e, leader, 'prisoner_shake_zone_2') then
		local shake_npc_5_1 = self.get_oneline_npc(5, 1)
		if not self:check_npc_disabled(shake_npc_5_1) then
			character_util.shake(shake_npc_5_1, 0.03, 9999)
		end
	elseif type_util.is_zone_full_enter(e, leader, 'prisoner_shake_zone_3') then
		local shake_npc_7_1 = self.get_oneline_npc(7, 1)
		if not self:check_npc_disabled(shake_npc_7_1) then
			character_util.shake(shake_npc_7_1, 0.03, 9999)
		end

		if not self.is_prisoner_1_dead then
			local shake_npc_1_1 = self.get_oneline_npc(1, 1)
			if not self:check_npc_disabled(shake_npc_1_1) then
				character_util.shake(shake_npc_1_1, 0.03, 9999)
			end
		end
	elseif type_util.is_zone_full_enter(e, leader, 'prisoner_shake_zone_4') then
		local shake_npc_10_1 = self.get_oneline_npc(10, 1)
		if not self:check_npc_disabled(shake_npc_10_1) then
			character_util.shake(shake_npc_10_1, 0.03, 9999)
		end
	elseif type_util.is_zone_full_enter(e, leader, 'attack_repeat_zone') then
		local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		if main_quest_progress ~= nil and
				main_quest_progress.InnerProgress >= 3 and main_quest_progress.InnerProgress <= 6 then
			if not self.attack_repeat_on then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_repeat, self))
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	local leader = user_party.Leader

	if (type_util.is_zone_full_leave(e, leader, self.dark_room_event_zone) or
			type_util.is_zone_full_leave(e, self.get_mouse_bomb(), self.dark_room_event_zone)) and
			self.is_lever_pulled then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.toggle_dark_room_tint, self, false))
	elseif type_util.is_zone_full_leave(e, leader, 'prisoner_shake_zone_1') then
		local shake_npc_2_1 = self.get_oneline_npc(2, 1)
		if shake_npc_2_1 ~= nil then
			character_util.stop_shake(shake_npc_2_1)
		end
	elseif type_util.is_zone_full_leave(e, leader, 'prisoner_shake_zone_2') then
		local shake_npc_5_1 = self.get_oneline_npc(5, 1)
		if shake_npc_5_1 ~= nil then
			character_util.stop_shake(shake_npc_5_1)
		end
	elseif type_util.is_zone_full_leave(e, leader, 'prisoner_shake_zone_3') then
		local shake_npc_7_1 = self.get_oneline_npc(7, 1)
		if shake_npc_7_1 ~= nil then
			character_util.stop_shake(shake_npc_7_1)
		end

		if not self.is_prisoner_1_dead then
			local shake_npc_1_1 = self.get_oneline_npc(1, 1)
			if shake_npc_1_1 ~= nil then
				character_util.stop_shake(shake_npc_1_1)
			end
		end
	elseif type_util.is_zone_full_leave(e, leader, 'prisoner_shake_zone_4') then
		local shake_npc_10_1 = self.get_oneline_npc(10, 1)
		if shake_npc_10_1 ~= nil then
			character_util.stop_shake(shake_npc_10_1)
		end
	elseif type_util.is_zone_full_leave(e, leader, 'attack_repeat_zone') then
		self.attack_repeat_on = false
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		if e.CurrentProgress == 3 then
			local vampire_officer_1 = get_character('oneline_npc_15')
			local vampire_officer_2 = get_character('oneline_npc_16')
			local demon_officer_1 = get_character('oneline_npc_21')

			vampire_officer_1.SpineController:SetAttachment('[base]weapon1', 'monster_baton_sword')
			vampire_officer_2.SpineController:SetAttachment('[base]weapon1', 'monster_baton_sword')
			demon_officer_1.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_repeat, self))
		elseif e.CurrentProgress == 4 then
			-- 순찰도는 일반 가수들 활성화
			for i = 1, #self.detect_guards do
				local guard = self.get_guards(i)
				character_util.set_active_state(guard, 'enabled')
			end
		elseif e.CurrentProgress == 5 then
			-- 추가 순찰 간수 활성화
			local guard_new = self.get_new_guard()
			character_util.set_active_state(guard_new, 'enabled')

			-- 어두운 방에 있는 간수 비활성화
			local dark_room_guards = { 5, 6, 7, 8 }
			for i = 1, #dark_room_guards do
				local guard = self.get_guards(dark_room_guards[i])
				character_util.set_active_state(guard, 'disabled')
			end

			-- 어두운 방 기능 활성화
			self.is_lever_pulled = true

		elseif e.CurrentProgress == 7 then
			-- 순찰도는 일반 간수들 비활성화
			for i = 1, #self.detect_guards do
				local guard = self.get_guards(i)
				character_util.set_active_state(guard, 'disabled')
			end

			-- 추가 순찰 간수 비활성화
			local guard_new = self.get_new_guard()
			character_util.set_active_state(guard_new, 'disabled')
		end
	end
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 304101
	if user_util.has_knight_male() then
		character_spec_id = 304100
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

--endregion

function local_class:set_patrol_guards_on_start()
	-- 순찰하는 일반 간수들 캐싱
	local guard_idx = 1
	while true do
		local guard = self.get_guards(guard_idx)
		if guard == nil then
			break
		end
		guard_idx = guard_idx + 1
		table.insert(self.detect_guards, guard)
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		if main_quest_progress.InnerProgress == 4 then
			-- 순찰도는 일반 가수들 활성화
			for i = 1, #self.detect_guards do
				local guard = self.get_guards(i)
				character_util.set_active_state(guard, 'enabled')
			end
		elseif main_quest_progress.InnerProgress == 5 or
				main_quest_progress.InnerProgress == 6 then
			-- 순찰도는 일반 가수들 활성화
			-- 4 섹션 연출로 사라진 것으로 간주된 간수들은 활성화 하지 않음
			for i = 1, #self.detect_guards do
				local guard = self.get_guards(i)
				character_util.set_active_state(guard, 'enabled')
			end

			local removed_guards = { 5, 6, 7, 8, 15, 16 }
			for i = 1, #removed_guards do
				local guard = self.get_guards(removed_guards[i])
				character_util.set_active_state(guard, 'disabled')
			end

			-- 추가 순찰 간수 활성화
			local guard_new = self.get_new_guard()
			character_util.set_active_state(guard_new, 'enabled')
		end
	end
end

function local_class:set_prison_guard_arguing(progress)
	local civ2_pos = field:GetMarker('s3_guards_block_pos_2').position + vector(2, 0, -2)
	local demon_civilians = {}
	local reporters = {}
	local guard_right = {}

	for i = 1, 4 do
		local reporter = get_character('s3_reporter_' .. i)
		table.insert(reporters, reporter)
	end

	for i = 1, 7 do
		local demon = get_character('s3_demon_civilian_' .. i)
		table.insert(demon_civilians, demon)
	end

	for i = 1, 11 do
		local guard = get_character('s3_guard_right_' .. i)
		table.insert(guard_right, guard)
		guard.Hitbox = CS.Oak.Hitbox(vector(0.8, 1, 0.8))
	end

	local onelines = {
		get_character('oneline_event_6_npc_1'),
		get_character('oneline_event_6_npc_2')
	}

	if progress == 2 then
	elseif progress < 7 then
		-- 이벤트 한번 보고난 다음
		character_util.set_anim_and_emotion(demon_civilians[1], {name = 'prostrate'}, {name = 'damaged'})
		character_util.set_position(demon_civilians[1], civ2_pos + vector(1, 0, 0))
		character_util.set_position(demon_civilians[2], civ2_pos + vector(0.5, 0, 0))
		for i = 2, 4 do
			character_util.remove_anim(demon_civilians[i])
			character_util.set_emotion(demon_civilians[i], {name = 'surprise'})
			character_util.set_direction(demon_civilians[i], 'right')
		end
		local talk_name = 'demonshire_main_s3_'

		character_util.set_direction(demon_civilians[5], 'right')
		character_util.set_direction(demon_civilians[6], 'left')
		character_util.set_direction(demon_civilians[7], 'left')
		character_util.set_anim_and_emotion(demon_civilians[5], {name = 'question', loop = false}, {name = 'tired'})
		character_util.set_anim_and_emotion(demon_civilians[6], {name = 'idle'}, {name = 'mad'})
		character_util.set_anim_and_emotion(demon_civilians[7], {name = 'cast'}, {name = 'cry'})

		demon_civilians[5].Interactable.Talk = talk_name .. '6_1'
		demon_civilians[6].Interactable.Talk = talk_name .. '6_2'
		demon_civilians[7].Interactable.Talk = talk_name .. '6_3'

		reporters[1].Interactable.Talk = talk_name .. 2
		reporters[4].Interactable.Talk = talk_name .. 3

	else	-- 조건이 애매하게 겹쳐서 수동 처리가 필요할 것 같음.
		--수용소의 무너진 문 처리
		local city_guardpost = self.get_city_guardpost(2)
		local on_object = CS.Utils.FindChildRecursively(city_guardpost.Transform, 'on')
		on_object.gameObject:SetActive(true)
		local off_object = CS.Utils.FindChildRecursively(city_guardpost.Transform, 'off')
		off_object.gameObject:SetActive(false)
		-- 수용소 밖 길을 막고있는 NPC들 치워줌
		--s3_reporter_1~4
		--s3_demon_civilian_1~4
		--s3_guard_9~16
		--s3_guard_right_1~11
		for i = 1, 4 do
			character_util.remove_anim_and_emotion(reporters[i])
			character_util.set_position(reporters[i], vector(999, 0, 999))
			character_util.set_active_state(reporters[i], 'disabled')
		end

		for i = 1, 7 do
			character_util.remove_anim_and_emotion(demon_civilians[i])
			character_util.set_position(demon_civilians[i], vector(999, 0, 999))
			character_util.set_active_state(demon_civilians[i], 'disabled')
		end

		for i = 1, 16 do
			local guard = get_character('s3_guard_' .. i)

			character_util.stop(guard)
			character_util.remove_anim_and_emotion(guard)
			character_util.set_position(guard, vector(999, 0, 999))
			character_util.set_active_state(guard, 'disabled')
		end

		for i = 1, 11 do
			local guard = guard_right[i]

			character_util.remove_anim_and_emotion(guard)
			character_util.set_position(guard, vector(999, 0, 999))
			character_util.set_active_state(guard, 'disabled')
		end

		for i = 1, 2 do
			local oneline = get_character('oneline_event_6_npc_' .. i)

			character_util.remove_anim_and_emotion(oneline)
			character_util.set_position(oneline, vector(999, 0, 999))
			character_util.set_active_state(oneline, 'disabled')
		end

	end
end

function local_class:oneline_event_not_played(oneline_event_state)
	local cur_oneline_event_state = self.cur_oneline_event_state

	if cur_oneline_event_state == nil or cur_oneline_event_state == -1 then
		return false
	end

	return (cur_oneline_event_state & oneline_event_state) ~= oneline_event_state
end

function local_class:set_oneline_event_played(oneline_event_state)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	self.cur_oneline_event_state = self.cur_oneline_event_state | oneline_event_state
	quest_util.set_custom_state(main_quest_progress,
			self.oneline_event_state_key, self.cur_oneline_event_state)
end

function local_class:set_played_online_event_npc()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress == nil or (main_quest_progress ~= nil and main_quest_progress.InnerProgress > 6) then
		return
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_1) then
		local prisoner_1 = self.get_oneline_npc(1, 1)
		if prisoner_1 ~= nil then
			character_util.add_color(prisoner_1, 'dead_tint_prisoner_1', unity_class.color.black, 1, 0)
			field_ui_manager:RemoveUI(prisoner_1, CS.Oak.FieldUiType.CharacterStats)
			self.is_prisoner_1_dead = true
		end
	else
		local prisoner_1 = self.get_oneline_npc(1, 1)
		if prisoner_1 ~= nil then
			character_util.add_listener(prisoner_1, self.cs_controller)
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_2) then
		local prisoner = self.get_oneline_npc(2, 1)
		if prisoner ~= nil then
			-- 여, 열어줘…! 수용소가 무너지고 있다고…!
			prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_10'
			prisoner.Interactable.TalkSfx = '03_dialogue_sadness_01'
			prisoner.Hitbox = CS.Oak.Hitbox(vector(1, 1, 2))
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_3) then
		local prisoner = self.get_oneline_npc(3, 1)
		if prisoner ~= nil then
			-- 경비병 자식들… 들은 체도 안 하다니…
			prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_11'
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_4) then
		local prisoner = self.get_oneline_npc(4, 1)
		if prisoner ~= nil then
			local falling_rock = self.get_falling_rock()
			falling_rock.Position = field:GetMarker('oneline_event_4_npc_1_pos').position
			field_ui_manager:RemoveUI(prisoner, CS.Oak.FieldUiType.CharacterStats)
			character_util.set_emotion(prisoner, { name = 'confused' })
			character_util.set_anim(prisoner, { name = 'prostrate' })
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_5) then
		local prisoner = self.get_oneline_npc(5, 1)
		if prisoner ~= nil then
			-- 나도 좀 살려줘! 제발!!
			prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_13'
			prisoner.Interactable.TalkSfx = '03_runaway_01'
			prisoner.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1))
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_6) then
		local guard_1 = self.get_oneline_npc(6, 1)
		if guard_1 ~= nil then
			character_util.set_direction(guard_1, 'down')
			-- …프리실라 님이 다치셨을까 걱정 되신 걸까?
			guard_1.Interactable.Talk = 'ds_main_stage_2_oneline_18'
		end

		local guard_2 = self.get_oneline_npc(6, 2)
		if guard_2 ~= nil then
			character_util.set_direction(guard_2, 'up')
			-- 에이… 애초에 프리실라 님을 가둔 분이 누군데…
			guard_2.Interactable.Talk = 'ds_main_stage_2_oneline_19'
		end
	end

	if not self:oneline_event_not_played(self.oneline_event_state.event_7) then
		local prisoner_3 = self.get_oneline_npc(7, 1)
		if prisoner_3 ~= nil then
			-- 저리가…!  들킨다고!
			prisoner_3.Interactable.Talk = 'ds_main_stage_2_oneline_28'
		end
	end
end

function local_class:attack_repeat()
	local vampire_officer_1 = get_character('oneline_npc_15')
	local vampire_officer_2 = get_character('oneline_npc_16')
	local demon_prisoner_3 = get_character('oneline_npc_17')

	if self:check_npc_disabled(vampire_officer_1) or
			self:check_npc_disabled(vampire_officer_2) or
			self:check_npc_disabled(demon_prisoner_3) then
		return
	end

	self.attack_repeat_on = true
	local conditional_timer = function(duration)
		local time_passed = 0
		while time_passed < duration and self.attack_repeat_on do
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end
	end

	local fx_pos_1 = demon_prisoner_3.Bounds.center + vector(-0.15, 0, 0)
	local fx_pos_2 = demon_prisoner_3.Bounds.center + vector(0.15, 0, 0)

	while self.attack_repeat_on do
		character_util.set_anim(vampire_officer_1, { name = 'attack', loop = false })
		conditional_timer(0.3)
		character_util.spine_damage_squish(demon_prisoner_3, 1.3, 0.7, 1, 0.3)
		character_util.spine_damage_red_pulse(demon_prisoner_3)
		music_player_util.play_sfx({
			sfx_name = '02_hit_big_01', parent = demon_prisoner_3,
			loop = false, type_priority = 'event', player_priority = 'npc',
			max_distance = 3
		})
		local fx_hit_1 = unity_object_pool.GetOrCreate(self.fx_hit):Instantiate(fx_pos_1)
		conditional_timer(0.2)
		character_util.set_anim(vampire_officer_1, { name = 'sword_idle' })
		conditional_timer(0.3)
		fx_hit_1:Dispose()

		character_util.set_anim(vampire_officer_2, { name = 'attack', loop = false })
		conditional_timer(0.3)
		character_util.spine_damage_squish(demon_prisoner_3, 1.3, 0.7, 1, 0.3)
		character_util.spine_damage_red_pulse(demon_prisoner_3)
		music_player_util.play_sfx({
			sfx_name = '02_hit_big_01', parent = demon_prisoner_3,
			loop = false, type_priority = 'event', player_priority = 'npc',
			max_distance = 3
		})
		local fx_hit_2 = unity_object_pool.GetOrCreate(self.fx_hit):Instantiate(fx_pos_2)
		conditional_timer(0.2)
		character_util.set_anim(vampire_officer_2, { name = 'sword_idle' })
		conditional_timer(0.3)
		fx_hit_2:Dispose()
	end
end

function local_class:oneline_event_2()
	local prisoner = self.get_oneline_npc(2, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_2)

	-- 마족 죄수 (down, scared, cast +shake) : 여, 열어줘…! 수용소가 무너지고 있다고…!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = prisoner })
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_10' })

	-- 여, 열어줘…! 수용소가 무너지고 있다고…!
	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_10'
	prisoner.Interactable.TalkSfx = '03_dialogue_sadness_01'
	prisoner.Hitbox = CS.Oak.Hitbox(vector(1, 1, 2))
end

function local_class:oneline_event_3()
	local prisoner = self.get_oneline_npc(3, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_3)

	-- 마족 남성 죄수(left, scared, seat) : 경비병 자식들… 들은 체도 안 하다니…
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_11' })

	-- 경비병 자식들… 들은 체도 안 하다니…
	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_11'
end

function local_class:oneline_event_4()
	local prisoner = self.get_oneline_npc(4, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_4)

	-- 마족 남성 죄수(right, scared, release) : [shout] 저, 저기! 나 좀 꺼내줘! 이러다 깔려 죽겠어!!
	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = prisoner })
	speech_bubble_util.show_speech_bubble_async(prisoner,
			{ key = 'ds_main_stage_2_oneline_12', bubble_type = 'shout' })

	local falling_rock = self.get_falling_rock()
	local rock_pos = field:GetMarker('oneline_event_4_npc_1_pos').position + vector(0, 15, -0.1)
	falling_rock.Position = rock_pos

	music_player_util.play_sfx({ sfx_name = '01_earthquake_02', parent = prisoner })

	local fx_pos = vector_util.get_x0z(falling_rock.Bounds.center) + vector(-0.2, 0, 0)
	unity_object_pool.GetOrCreate(self.fx_landslide_brown_small):Instantiate(fx_pos)

	-- 낙석 세팅
	local rock_start_pos = falling_rock.Position
	local rock_end_pos = vector_util.get_x0z(rock_start_pos)
	local falling_time = 1.5
	local time_passed = 0

	-- 그림자 세팅
	local rock_shadow = falling_rock.Transform:GetChild(0)
	rock_shadow.position = vector(rock_shadow.position.x, 0.3, rock_shadow.position.z)
	rock_shadow.localScale = unity_class.vector3.zero

	-- 떨어지는 낙석 가속도 이동 (EaseInQuart)
	while time_passed < falling_time do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = CS.Oak.Interpolations.EaseInExpo(time_passed, 0, 1, falling_time)
		local cur_pos = unity_class.vector3.Lerp(rock_start_pos, rock_end_pos, progress)
		falling_rock.Position = cur_pos
		rock_shadow.position = vector(rock_shadow.position.x, 0.3, rock_shadow.position.z)

		if progress > 0.2 then
			rock_shadow.localScale = vector(2, 1, 2) * progress
		end
		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '02_stomp_01', parent = prisoner })
	music_player_util.play_sfx({ sfx_name = '01_villain_scream_04', parent = prisoner })

	unity_object_pool.GetOrCreate(self.fx_smokescreen):Instantiate(fx_pos)
	unity_object_pool.GetOrCreate(self.fx_last_hit):Instantiate(prisoner.Position)
	unity_object_pool.GetOrCreate(self.fx_hit):Instantiate(prisoner.Position)

	field_ui_manager:RemoveUI(prisoner, CS.Oak.FieldUiType.CharacterStats)
	character_util.set_emotion(prisoner, { name = 'confused' })
	character_util.set_anim(prisoner, { name = 'prostrate' })

	-- 화면 안에 보이면 화면 쉐이크
	if screen_util.is_fo_in_screen(prisoner.Bounds.center, { bonus_distance = -1 }) then
		stage_camera:Shake(0.25, 0.3)
	end
	wait_for_sec(0.3)
end

function local_class:oneline_event_5()
	local prisoner = self.get_oneline_npc(5, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_5)

	-- 마족 여성 죄수(left, scared, cast+shake) : 나도 좀 살려줘!
	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = prisoner })
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_13' })
	prisoner.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1))

	-- 나도 좀 살려줘! 제발!!
	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_13'
	prisoner.Interactable.TalkSfx = '03_runaway_01'
end

function local_class:oneline_event_6()
	local guard_1 = self.get_oneline_npc(6, 1)
	local guard_2 = self.get_oneline_npc(6, 2)

	if self:check_npc_disabled(guard_1) or self:check_npc_disabled(guard_2) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_6)

	local dir = {
		'down'
	}
	for i = 1, #dir do
		wait_for_sec(0.75)
		character_util.set_direction(guard_1, dir[i])
	end
	wait_for_sec(0.75)

	--빨간점(down, idle, bomb_idle) : 방금 백작님 여기 계시지 않았어?
	speech_bubble_util.show_speech_bubble_async(guard_1, { key = 'ds_main_stage_2_oneline_14' })

	--파란점(up, idle, bomb_idle) : 수용소 확인만 하고 어디론가 급히 가시던데?
	speech_bubble_util.show_speech_bubble_async(guard_2, { key = 'ds_main_stage_2_oneline_15' })

	--이후 원라인 상태
	--빨간점 : …프리실라 님이 다치셨을까 걱정 되신 걸까?
	guard_1.Interactable.Talk = 'ds_main_stage_2_oneline_18'

	--파란점(up, idle, idle) : 에이… 애초에 프리실라 님을 가둔 분이 누군데…
	guard_2.Interactable.Talk = 'ds_main_stage_2_oneline_19'
end

function local_class:oneline_event_7()
	local prisoner = self.get_oneline_npc(7, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end
	self:set_oneline_event_played(self.oneline_event_state.event_7)

	--죄수 (left, scared, idle) : 저리가…!  들킨다고!
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_28', skip = true })

	--이후 인터랙트시 원라인 대사 반복.
	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_28'
end

function local_class:oneline_event_8()
	self.saw_online_event_8 = true

	local prisoner = self.get_oneline_npc(8, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_02')
	--1번 죄수 (left, scared, idle) : 폭발을 틈타 겨우 탈출했는데…
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_34' })

	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_34'
end

function local_class:oneline_event_9()
	self.saw_online_event_9 = true

	local guard_1 = self.get_oneline_npc(9, 1)
	local guard_2 = self.get_oneline_npc(9, 2)

	if self:check_npc_disabled(guard_1) or self:check_npc_disabled(guard_2) then
		return
	end

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	--3번 간수 (left, attack, release) : 우리까지 갇혀버렸는데 어떡해…!
	speech_bubble_util.show_speech_bubble_async(guard_1, { key = 'ds_main_stage_2_oneline_35' })

	--4번 간수 (right, attack, question) : 백작님의 병력 지원이 오면 다 해결될 거야.
	speech_bubble_util.show_speech_bubble_async(guard_2, { key = 'ds_main_stage_2_oneline_36' })

	guard_1.Hitbox = CS.Oak.Hitbox(vector(3, 1, 3))
	guard_2.Hitbox = CS.Oak.Hitbox(vector(1, 1, 3))

	guard_1.Interactable.Talk = 'ds_main_stage_2_oneline_35'
	guard_2.Interactable.Talk = 'ds_main_stage_2_oneline_36'
end

function local_class:oneline_event_10()
	self.saw_online_event_10 = true

	local prisoner = self.get_oneline_npc(10, 1)

	if self:check_npc_disabled(prisoner) then
		return
	end

	--나는 살아남을거야…
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_37' })

	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_37'
end

function local_class:oneline_event_12()
	self.saw_online_event_12 = true

	local prisoner = get_character('oneline_npc_36')

	if self:check_npc_disabled(prisoner) then
		return
	end

	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_33' })

	prisoner.Interactable.Talk = 'ds_main_stage_2_oneline_33'
end

function local_class:check_npc_disabled(npc)
	if npc == nil or (npc ~= nil and npc.ActiveState == active_state('disabled')) then
		return true
	end
	return false
end

--- 순찰하는 간수 플레이어 감지 반응 함수
function local_class:guard_detect(guard, reset_event_name, reset_marker)
	self.is_detected = true

	-- 플레이어 일행 surprise, embarrassed
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_anim({ name = 'embarrassed' })
	party_util.set_emotion('surprise')

	-- 간수(attack표정) : 침입자 발견!!!
	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	character_util.set_anim(guard, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(guard, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(guard,
			{ key = 'ds_main_s5_1', skip = true,
			  bubble_type = 'shout', scale = 1.15 })

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	local reset_switch = get_field_object('dark_room_barrel_reset_switch')
	message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(reset_switch))

	character_util.remove_anim_and_emotion(guard)

	party_util.remove_animation()
	party_util.remove_emotion()

	local reset_dir = direction_util.get_opposite(reset_marker.direction)
	local reset_pos = reset_marker.position + direction_util.to_vector3(reset_marker.direction)
	party_util.align_party(reset_pos, reset_dir, 0)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	self.is_detected = false

	for i = 1, #self.detect_guards do
		local detect_guard = self.detect_guards[i]
		if detect_guard.ActiveState == active_state('enabled') then
			message_system:SendSync(detect_guard, CS.Oak.CustomStageEvent.Create(guard, { 'reset', reset_event_name }))
		end
	end
end

--- 수용소 4번 출구 막고 있는 가드에게 발각되어 리셋하는 함수
function local_class:blocking_guard_detect()
	self.is_detected = true

	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_anim({ name = 'embarrassed' })
	party_util.set_emotion('surprise')

	for i = 1, 2 do
		local blocking_guard = self.get_blocking_guard(i)
		character_util.set_anim(blocking_guard, { name = 'release', sfx_name = '01_swing_01' })
	end

	local guard_shouter = self.get_blocking_guard(1)
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	wait_all({
		-- [shout] 웬 놈이냐!
		util.cs_generator(	speech_bubble_util.show_speech_bubble_async, guard_shouter,
				{ key = 'ds_main_s5_1', skip = true, bubble_type = 'shout',
				  world_pos = guard_shouter.Position + vector(-0.5, 0, 0), scale = 1.15 }),
		util.cs_generator(function()
			wait_for_sec(1)
		end)
	})

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	party_util.remove_animation()
	party_util.remove_emotion()

	for i = 1, 2 do
		local blocking_guard = self.get_blocking_guard(i)
		character_util.remove_anim_and_emotion(blocking_guard)
	end

	local reset_marker = field:GetMarker('blocking_guard_alert_reset')
	local reset_dir = direction_util.get_opposite(reset_marker.direction)
	local reset_pos = reset_marker.position + vector(-1, 0, 0)
	party_util.align_party(reset_pos, reset_dir, 0)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	self.is_detected = false
end

--- 인자 character가 파티 맴버인지 알아내는 함수
function local_class:is_character_in_party(character)
	for i = 0, user_party.Count - 1 do
		local member = user_party[i]
		if lua_helper.reference_equals(member, character) then
			return true
		end
	end
	return false
end

function local_class:box_interact(idx, box)
	local leader = user_party.Leader

	unity_object_pool.GetOrCreate(self.fx_dead):Instantiate( box.Position)
	box.ActiveState = active_state('disabled')

	music_player_util.play_sfx_one_shot('01_turn_page_02')

	local drop_item = function(id)
		return drop_item_util.create_item({
			itemid = id,
			pos =  box.Position,
			target = leader.Position + vector(0, 0, -0.5),
			notforinven = true,
			showoncharacter = true,
			lootstate = 'dontfindlooter',
			skip_text = true
		})
	end

	if idx == 1 then
		self.box_1_twinkle_fx:Dispose()
		self.box_1_twinkle_fx = nil

		local book_1 = drop_item(20590)
		wait_for_sec(0.75)
		book_1.ConsumeTarget = leader
		book_1:Fly()
		wait_for_sec(0.5)

		-- 고급 유머 모음집. /n
		-- 우주인이 술을 마시는 곳은?)
		field_ui_util.show_narration_async({ key = 'ds_main_s5_35' })

		-- [스페이스바! 깔깔!] 이라고 적혀져 있다.
		field_ui_util.show_narration_async({ key = 'ds_main_s5_36' })
	elseif idx == 2 then
		self.box_2_twinkle_fx:Dispose()
		self.box_2_twinkle_fx = nil

		local book_2 = drop_item(20630)
		wait_for_sec(0.75)
		book_2.ConsumeTarget = leader
		book_2:Fly()
		wait_for_sec(0.5)

		-- 아가씨는 그날 밤 어디로 도망갔을까. /n
		-- 수상해 보이는 제목의 책이다.
		field_ui_util.show_narration_async({ key = 'ds_main_s5_37' })

		-- 특정 페이지만 자주 읽은 듯 종이가 낡아 헤져 있다.
		field_ui_util.show_narration_async({ key = 'ds_main_s5_38' })
	end
end

function local_class:dark_room_empty()
	local lever = self.get_dark_room_lever()
	if lever ~= nil then
		lever.Interactable = CS.Oak.NonInteractable.Instance

		local animator = lever:GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('pull')

		self.is_lever_pulled = true

		message_system:Publish(CS.Oak.PowerSourceTurnOffEvent.Create('dark_room_power_source'))
	end

	local dark_room_rock = self.get_dark_room_rock()
	if dark_room_rock ~= nil then
		dark_room_rock.ActiveState = active_state('disabled')
	end
end

function local_class:toggle_dark_room_tint(darken)
	local dark_room_tint_key = 'dark_room_light_off_key'

	if darken then
		field:Tint(dark_room_tint_key, unity_color({ 0.25, 0.25, 0.25, 1 }), 1)
	else
		field:RemoveTint(dark_room_tint_key, 1)
	end
end

function local_class:prisoner_1_dead()
	local prisoner = self.get_oneline_npc(1, 1)

	self.is_prisoner_1_dead = true
	self:set_oneline_event_played(self.oneline_event_state.event_1)

	-- 죽기 싫어… 죽기 싫어… 죽기 싫…
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(prisoner, { key = 'ds_main_stage_2_oneline_29' })

	character_util.stop_shake(prisoner)

	music_player_util.play_sfx_one_shot('01_fade_out_02')
	character_util.add_color(prisoner, 'dead_tint_prisoner_1', unity_class.color.black, 1, 1)
	field_ui_manager:RemoveUI(prisoner, CS.Oak.FieldUiType.CharacterStats)

	character_util.remove_relate_event(prisoner, self.cs_controller)
end

function local_class:destroy_shortcut_wreck(shortcut_wreck)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		local sohee = self.get_sohee()

		-- InnerProgress < 5면 소히 무기 없음
		if main_quest_progress.InnerProgress < 5 then
			-- 지저분한 잔해들로 인해 길이 막혀 있다.
			field_ui_util.show_narration_async({ key = 'ds_main_s5_28' })

			-- 소히 : …이런 고철쯤은 마기톤 에너지 한 방감인데…
			music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
			character_util.set_emotion(sohee, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s5_26', skip = true })
			character_util.remove_emotion(sohee)

			-- 소히 : 여기 어딘가에 내 마기톤 버스터를 보관 중일 거야.
			speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s5_27', skip = true })
		else
			local leader = user_party.Leader
			local original_dir = leader.Direction
			local wreck_pos = vector_util.get_x0z(shortcut_wreck.Bounds.center)
			local dir = direction_util.to_4way_vector3(user_party.Leader.Direction)

			if not self.is_shortcut_wreck_destroyed_once and main_quest_progress.InnerProgress == 5 then
				-- 지저분한 잔해들로 인해 길이 막혀 있다.
				field_ui_util.show_narration_async({ key = 'ds_main_s5_28' })
			end

			camera_util.move_async(leader.Position, 0)

			local sohee_move_to = wreck_pos + (dir * 0.3) - (dir * 2)
			local leader_move_to = wreck_pos - (dir * 0.3) - (dir * 2)
			wait_all({
				util.cs_generator(character_util.move_to_async, sohee, sohee_move_to, nil, 2.5, true, true),
				util.cs_generator(character_util.move_to_async, leader, leader_move_to, nil, 2.5, true, true)
			})

			character_util.set_group_direction({ leader, sohee }, direction_util.to_str(original_dir))

			if not self.is_shortcut_wreck_destroyed_once and main_quest_progress.InnerProgress == 5  then
				-- 소히(스킬 사용시 대사) : 시간 끌 것 없이 부숴버리자고!
				music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1', skip = true })
			end

			-- 소히가 마기톤 버스터를 이용해 잔해를 부순다.
			character_util.set_anim(sohee, { name = 'rifle_shoot2' })
			character_util.set_emotion(sohee, { name = 'attack' })
			wait_for_sec(0.05)
			local loop_sound = music_player_util.play_sfx({sfx_name = '02_hyper_laser_01', loop = true})
			local laser = CS.Oak.UnityObjectPoolExtensions.Instantiate(unity_object_pool.GetOrCreate(self.magiton_laser_effect_preset),
					sohee.Bounds.center, direction_util.to_vector3(sohee.Direction))

			self:fo_shake(shortcut_wreck, 0.03, 0.75)
			stage_camera:Shake(0.3, 0.5)

			loop_sound:Stop()
			music_player_util.play_sfx_one_shot('02_explosion_01')
			music_player_util.play_sfx_one_shot('03_rock_break_02')
			unity_object_pool.GetOrCreate(self.fx_dead):Instantiate(shortcut_wreck.Bounds.center)
			shortcut_wreck.ActiveState = active_state('disabled')


			if not self.is_shortcut_wreck_destroyed_once and main_quest_progress.InnerProgress == 5 then
				character_util.set_direction(leader, 'right')
				character_util.set_emotion(leader, { name = 'surprise' })
				character_util.normal_jump(leader, true)
			end

			wait_for_sec(0.75)
			laser:Dispose()

			wait_for_sec(0.05)
			character_util.remove_anim(sohee)
			wait_for_sec(0.5)
			if not self.is_shortcut_wreck_destroyed_once and main_quest_progress.InnerProgress == 5 then
				self.is_shortcut_wreck_destroyed_once = true

				character_util.set_direction(sohee, 'left')
				character_util.set_emotion(sohee, { name = 'attack' })
				character_util.move_to(sohee, sohee.Position + vector(0.5, 0, 0),
			nil, 3, false, true)

				character_util.move_to_async(leader, sohee.Position + vector(-0.5, 0, 0),
						nil, 3, true, true)
				character_util.set_direction(leader, 'right')

				-- 뭐야 고릴라. 갑자기 왜 튀어올라?
				music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_1', skip = true })

				local wait = true
				local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
				local choice_mercy = true

				-- 갑자기 강해졌다
				branches:Add({
					Text = game_string:GetString('ds_main_s6_1_2'),
					Tendency = CS.Oak.TalkTendency.Mercy,
					Callback = function()
						wait = false
					end })

				-- 언제 힘캐로 전직한거야?
				branches:Add({
					Text = game_string:GetString('ds_main_s6_1_3'),
					Tendency = CS.Oak.TalkTendency.Brutal,
					Callback = function()
						wait = false
						choice_mercy = false
					end })

				ui_overlay_util.push_overlay(leader, branches)

				while wait do
					coroutine.yield(nil)
				end

				if choice_mercy then
					character_util.set_animation_n_times_async(leader, { name = 'release', count = 2, sfx = '01_swing_01' })
				else
					character_util.remove_emotion(leader)
					music_player_util.play_sfx_one_shot('01_swing_01')
					character_util.set_anim(leader, { name = 'bomb_idle' })
					wait_for_sec(1)
					character_util.remove_anim(leader)
				end

				character_util.remove_emotion(leader)
				character_util.set_emotion(sohee, { name = 'tired' })
				character_util.show_emoticon_async(sohee, nil, 'silence')

				music_player_util.play_sfx_one_shot('01_rustle_01')
				character_util.remove_emotion(sohee)
				character_util.set_anim(sohee, { name = 'cross_arm', loop = false })
				-- 사실 이 곳에 들어온 이후부터 좀 특별한 기운이 느껴지긴 해.
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_4', skip = true })
				-- 내가 아까 말했지. 이곳의 시간선은 조금 특이한 흐름이 있다고.
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_5', skip = true })

				music_player_util.play_sfx_one_shot('01_rustle_01')
				character_util.set_anim(sohee, { name = 'question', loop = false })
				-- 프루스트 법칙에 따르면 일정 성분을 가진 개체들은 모두 고용체 이상의 능력을 낼 수가 없다는 것이 일반적인 원칙인데…
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_6', skip = true })

				character_util.remove_anim(sohee)
				character_util.set_emotion(sohee, { name = 'attack' })
				-- 이 곳은 이상해. 여기 있는 시간이 길어질수록… 그 법칙을 깨부순단 느낌이야.
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_7', skip = true })

				character_util.remove_emotion(sohee)
				character_util.set_anim(sohee, { name = 'bomb_idle' })
				-- …뭐 덕분에 새로운 기술도 연마할 수 있었고…
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_8', skip = true })

				character_util.set_anim(sohee, { name = 'release', sfx_name = '01_swing_01' })
				-- 우선 여길 탈출하는 것에 집중하자고.
				music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
				speech_bubble_util.show_speech_bubble_async(sohee, { key = 'ds_main_s6_1_9', skip = true })
				character_util.remove_anim(sohee)
			end
			character_util.remove_emotion(sohee)

			camera_util.return_to_leader(0.33)
		end
	end
end

--- 잔해 설정
function local_class:set_wreck()
	local shortcut_wreck_idx = 1
	while true do
		local shortcut_wreck = self.get_shortcut_wreck(shortcut_wreck_idx)
		if shortcut_wreck == nil then
			break
		end
		shortcut_wreck_idx = shortcut_wreck_idx + 1
		shortcut_wreck.Interactable = CS.Oak.PublishInteractable.Create()
	end
end

--- 감옥 문 설정
function local_class:set_prison_door()
	local open_prison_door = function(fo)
		local fo_anim = fo:GetComponent(typeof(CS.UnityEngine.Animator))
		fo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		fo.Interactable = CS.Oak.NonInteractable.Instance
		fo_anim:Play('on')
	end

	local escape_room_door = self.get_escape_room_door()
	open_prison_door(escape_room_door)

	local sohee_prison_door = self.get_sohee_prison_door()
	open_prison_door(sohee_prison_door)

	local irongate_1 = self.get_irongate(1)
	open_prison_door(irongate_1)
end

function local_class:fo_shake(fo, amplitude, duration)
	local pos = fo.Position
	local time = 0
	while time < duration do
		local rand_1 = unity_class.random.Range(-amplitude, amplitude)
		local rand_2 = unity_class.random.Range(-amplitude, amplitude)

		fo.Position = pos + vector(rand_1, 0, rand_2)

		time = time + unity_class.time.deltaTime
		coroutine.yield(nil)
	end

	fo.Position = pos
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
