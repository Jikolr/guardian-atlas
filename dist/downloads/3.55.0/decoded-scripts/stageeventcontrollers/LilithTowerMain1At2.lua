local local_class = newclass("LilithTowerMain1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name = 'lilithtower_1_2'

	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 수트 맨손 기사
	self.get_knight_suit = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit')
		else
			return get_character('knight_female_suit')
		end
	end

	-- 수트 양손 기사
	self.get_knight_suit_bat = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit_bat')
		else
			return get_character('knight_female_suit_bat')
		end
	end

	-- 환풍구 미니게임
	self.vent_mini_game = nil
	self.game_name = 'VentMiniGame'

	-- 파티원들
	self.saved_party = nil

	-- 해결사
	self.odile_name = 'trouble_shooter'
	self.gremory_name = 'mad_scientist'

	-- 공주
	self.pricess_name = 'princess'

	-- 윈도우 브레이커 이벤트 key
	self.windows_breaker_key = 'windows_breaker'

	-- 윈도우 브레이커 받는 이벤트를 보았는지?
	self.is_show_windows_breaker_event = false

	self.rock_break_custom_data_key = 0
	self.is_rock_1_break = false
	self.get_rock = function(num) return get_field_object('rock_' .. num) end

	--region 세이프 하우스 NPC 작업
	self.safe_house_npc = {
		none = 0,
		engineer = 1,
		pickpocket = 2,
		secretary = 4,
		police = 8
	}

	self.current_safe_house_npc = self.safe_house_npc.none

	self.safe_house_active = true

	self.safe_house_zone_name = 'safe_house'

	self.safe_house_zone_count = 3

	self.stew_name = 'princess_stew'

	-- 비서 전용 CustomState 키값
	self.secretary_state_key = 'safe_house_secretary'

	-- 이벤트 봤는지 여부 체크
	self.saw_house_event_list = { false, false, false, false, false, false, false, false, false, false }

	self.paper_item = nil

	-- npc
	self.get_secretary = function() return get_character('house_secretary') end
	self.get_police = function() return get_character('house_police') end
	self.get_pickpocket = function() return get_character('house_pickpocket') end
	self.get_engineer = function() return get_character('house_engineer') end
	self.get_deco_dead_body = function(num) return get_character('deco_dead_body_'..num) end
	self.get_beth = function() return get_character('beth_the_janitor') end
	self.get_janitor_by_idx = function(num) return get_character('janitor_' .. num) end

	-- FieldObject
	self.get_broken_elevator = function() return get_field_object('broken_elevator') end
	self.get_safe_house_entry_cabinet = function() return get_field_object('safe_house_entry_cabinet') end

	-- marker
	self.get_house_marker_pos = function(num) return field:GetMarker('safe_house_npc_pos_'..num).position end

	-- zone
	self.get_house_npc_zone_name = function(num) return 'safe_house_npc_zone_'..num end
	--endregion

	-- HP회복 로직이 도는 중인가
	self.is_recovery_hp = false
	-- 테러리스트 Exclusive 이벤트 키
	self.detected_by_terrorist_key = 'detected_by_terrorist'

	--region 옷장에 숨은 생존자
	self.get_aooni_cabinet = function() return get_field_object('aooni_cabinet') end
	self.get_aooni_survivor = function() return get_character('aooni_survivor') end

	self.aooni_state = {
		none = 0,
		in_room = 1,
		interact_cabinet = 2,
	}
	self.current_aooni_state = self.aooni_state.none

	self.aooni_grid_name = '21'
	--endregion

	self.safe_house_grid = 'safe_01'

	self.reserve_window_breaker = false

	--region 화장실 출입 금지

	self.get_toilet_android = function() return get_character('toilet_move_android') end
	self.get_toilet_npc = function() return get_character('toilet_npc') end

	self.get_toilet_android_reset_button = function() return get_field_object('toilet_android_reset') end
	self.get_toilet_android_gimmick = function() return get_field_object('toilet_android_1') end

	self.get_toiler_reset_pos = function() return field:GetMarker('toiler_reset_pos').position end
	self.get_fx_reset = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	self.toilet_zone_name = 'toilet_enter'

	self.toilet_state = {
		none = 0,
		scene = 1,
	}
	self.current_toilet_state = self.toilet_state.none

	self.toilet_android_lua_table = nil

	self.toilet_android_origin_pos = nil

	--endregion

	--region 세이프하우스 캐비닛

	-- 세이프 하우스 캐비닛 이동 CustomState 키 값
	self.move_safe_house_cabinet_key = 1

	-- 플래그
	self.is_move_safe_house_cabinet = false

	-- 캐비닛 밀리는 소리
	self.cabinet_sfx = nil

	self.open_safe_house_cabinet_zone_name = 'open_safe_house_cabinet'
	--endregion


	self.windows_breaker_on_progress_five = false

	self.stew_sfx = nil
	self.stew_drink_sfx = nil
	self.heal_sfx = nil

	self.main_quest_id = 258
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 바위 터질때 사용할 이팩트 미리 로드
	unity_object_pool.GetOrCreate('FX_Env_SmallRock_lv1_destroy_gray')

	-- 리소스 로드를 기다림
	yield_return(unity_object_pool, 'WaitAll')

	-- 미니게임 로드
	self.vent_mini_game = mini_game_manager:GetOrCreate(self.game_name)

	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.game_name, 'vent_mini_game_stage_2', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield()
	end

	self.is_rock_1_break = stage_progress_util.get_custom_data(self.rock_break_custom_data_key)
	if self.is_rock_1_break then
		local rock_1 = self.get_rock(1)
		rock_1.ActiveState = active_state('disabled')
	end

	for i = 1, 8 do
		local cur_body = self.get_deco_dead_body(i)
		local cur_alpha = CS.UnityEngine.Random.Range(0, 0.2)

		cur_body.SpineController:AddColor(
				cur_body.Name, unity_color({ cur_alpha, cur_alpha, cur_alpha, 1 }), 1, 0)
	end

	if not stage_progress_util.get_custom_data(self.move_safe_house_cabinet_key) then
		self.get_safe_house_entry_cabinet().Position =
			self.get_safe_house_entry_cabinet().Position + vector(0, 0, 2)
	end

	CS.Oak.CommonScreenplay.PreloadTutorialSpine()
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	--TODO: 개발 과정에서 섹션6(세이프하우스 이벤트)에서만 DefaultStart 지점이 아닌곳에서 시작된다. 추후 추가될 수 있다.
	local progress_list = {
		0,
		5,
	}

	--TODO: 특정 섹션에서(4스테이지 이후)는 공주 안보이도록 변경해야함.
	self.is_show_windows_breaker_event = quest_util.get_custom_state(quest_progress, self.windows_breaker_key) >= 1

	-- 리더를 기사로 바꿈
	-- 방망이를 얻었다면 방망이를 든 기사로
	local character_spec_id = 302922
	if user_util.has_knight_male() then
		character_spec_id = 302921
	end

	local leader
	if quest_util.get_custom_state(quest_progress, self.windows_breaker_key) >= 1 then
		leader = self.get_knight_suit_bat()
	else
		leader = self.get_knight_suit()
	end

	character_util.convert_to_manual_character(leader)
	user_party.Leader.CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(user_party_leader.CharacterInfo.User, character_spec_id)

	field_ui_manager:SetUI(leader, CS.Oak.FieldUiType.TopHpBar)

	-- 메인 퀘스트 상황에 따라서 오딜, 그레모리 파티원에 추가
	-- 섹션 6(progress 5)일 때만 그레모리, 오딜 합류
	if quest_progress.InnerProgress == 5 then
		character_util.convert_to_party_member(get_character(self.odile_name), user_party, true)
		character_util.convert_to_party_member(get_character(self.gremory_name), user_party, true)

		-- 세이프 하우스 비서 예외처리 추가
		self.safe_house_active = false
	elseif quest_progress.InnerProgress > 5 then
		if self.is_show_windows_breaker_event then
			self:safe_house_stew_event_setting()
		else
			self:windows_breaker_event_setting()
		end
	end

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	self:safe_house_oni_girl()

	field_ui_manager:RemoveUI(self.get_aooni_survivor(), CS.Oak.FieldUiType.CharacterStats)

	character_util.shake(self.get_toilet_npc(), 0.02, 99999)
	character_util.set_anim(self.get_toilet_npc(), {name = 'cast', upper = true})

	-- 쇼케이스 안드로이드 세팅
	local showcase_androids = {}

	for i = 1, 8 do
		local showcase_android = get_character('showcase_android_' .. i)
		table.insert(showcase_androids, showcase_android)
	end

	local quest_progress = user_progress:GetStartedQuest(260)
	if quest_progress ~= nil and quest_progress.InnerProgress > 0 then
		local android = get_character('android_engineer_android')
		table.insert(showcase_androids, android)
	end

	for _, showcase_android in pairs(showcase_androids) do
		field_ui_manager:RemoveUI(showcase_android, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_anim(showcase_android, { name = 'idle', loop = false })
		character_util.set_active_shadow(showcase_android, false)
		character_util.set_active_state(showcase_android, 'visible')
	end
end

function local_class:on_stage_start_event(e)
	local toilet_android_gimmick = self.get_toilet_android_gimmick()
	self.toilet_android_lua_table = toilet_android_gimmick.FieldObjectBehaviour:GetLuaTable()
	self.toilet_android_origin_pos = toilet_android_gimmick.Position

	-- 베스
	local beth_quest_id = 264
	local quest = user_progress:GetStartedQuest(beth_quest_id)

	if quest ~= nil and quest.IsComplete and quest.Grade == 0 then
		local beth = self.get_beth()
		local janitor_1 = self.get_janitor_by_idx(1)
		local janitor_2 = self.get_janitor_by_idx(2)

		beth.SpineController:SetAttachment('[base]weapon1', 'cwp_invaderknight')
		character_util.set_position(beth, field:GetMarker('safe_house_beth').position)
		character_util.set_emotion(beth, { name = 'normal_eye2' })
		character_util.remove_anim(beth)
		character_util.set_active_state(beth, 'enabled')
		beth.Interactable.Talk = 'safe_house_beth_1'

		character_util.set_position(janitor_1, field:GetMarker('safe_house_janitor_'.. 1).position)
		character_util.set_emotion(janitor_1, { name = 'confused' })
		character_util.set_anim(janitor_1, { name = 'seat', loop = true })
		character_util.set_active_state(janitor_1, 'enabled')
		janitor_1.Interactable.Talk = 'safe_house_beth_2'

		character_util.set_position(janitor_2, field:GetMarker('safe_house_janitor_'.. 2).position)
		character_util.set_emotion(janitor_2, { name = 'confused' })
		character_util.set_anim(janitor_2, { name = 'seat', loop = true })
		character_util.set_active_state(janitor_2, 'enabled')
		janitor_2.Interactable.Talk = 'safe_house_beth_3'
	end

	return false
end

function local_class:on_interact_event(e)
	local princess = get_character(self.pricess_name)
	local stew = get_field_object(self.stew_name)

	if lua_helper.reference_equals(e.Target, princess) then
		if not self.is_show_windows_breaker_event then
			local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
			-- 프로그래스 6 이상이거나 5이면 선행 이벤트를 봐야 야구방망이 이벤트 볼 수 있도록
			if (quest_progress.InnerProgress == 5 and self.windows_breaker_on_progress_five) or
					quest_progress.InnerProgress > 5 then
				sp_util.play_normal_screenplay(self.windows_breaker_event, self, princess)
			end
		end
	elseif lua_helper.reference_equals(e.Target, self.get_aooni_cabinet())
			and self.current_aooni_state == self.aooni_state.in_room then
		self.current_aooni_state = self.aooni_state.interact_cabinet
		sp_util.play_normal_screenplay(self.aooni_interact_with_cabinet, self)
		return true
	elseif lua_helper.reference_equals(e.Target, stew) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.princess_stew_event, self))
	elseif lua_helper.reference_equals(e.Target, self.get_broken_elevator()) then
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.interact_with_broken_elevator, self))
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	local rock_1 = self.get_rock(1)

	if not self.is_rock_1_break and lua_helper.reference_equals(e.FieldObject, rock_1) then
		self.is_rock_1_break = true
		stage_progress_util.set_custom_data(self.rock_break_custom_data_key, true)
	end

	return true
end

function local_class:on_zone_enter_event(e)
	if not stage_progress_util.get_custom_data(self.move_safe_house_cabinet_key) then
		if not self.is_move_safe_house_cabinet and
				type_util.is_zone_full_enter(e, user_party.Leader, self.open_safe_house_cabinet_zone_name) then
			self.is_move_safe_house_cabinet = true

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.open_safe_house_cabinet, self))
		end
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, self.safe_house_zone_name) and self.safe_house_active then
		self:update_safe_house_npc()
		self:setting_safe_house_npc()
		return true
	elseif type_util.is_zone_full_enter(e, user_party.Leader, self.toilet_zone_name)
			and lua_helper.reference_equals(user_party.Leader, self.get_toilet_android()) == false
			and self.current_toilet_state == self.toilet_state.none then
		self.current_toilet_state = self.toilet_state.scene
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.player_enter_toilet, self))
		return true
	elseif self.safe_house_active then
		for i = 1, self.safe_house_zone_count do
			if type_util.is_zone_full_enter(e, user_party.Leader, self.get_house_npc_zone_name(i)) then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.safe_house_zone_event, self, i))
				return true
			end
		end
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == 258 then
		if e.CurrentProgress == 6 then
			self.safe_house_active = true
			if self.reserve_window_breaker then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
							local quest_progress = user_progress:GetStartedQuest(e.QuestId)
							quest_util.set_custom_state(quest_progress, self.windows_breaker_key, 1)
						end))
			end
			return true
		end
	end
	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.aooni_grid_name) then
		self.current_aooni_state = self.aooni_state.in_room
		self.get_aooni_cabinet():Shake(0.02, 999999)
		return true
		-- 야구 방망이 얻었고, 세이프 하우드 입장했으면
	elseif type_util.is_player_enter_to_cam_grid(e, self.safe_house_grid) then
		if self.is_show_windows_breaker_event then
			self:safe_house_stew_event_setting()
		else
			self:windows_breaker_event_setting()
		end

		-- 세이프 하우스 bgm 변경
		local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		if quest_progress.InnerProgress > 5 then
			music_player_util.play_stage_music({
				name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_safehouse', state = 'event', mix = 2
			})
		end
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.aooni_grid_name) then
		self.current_aooni_state = self.aooni_state.none
		self.get_aooni_cabinet():CancelShake()
		return true
	elseif  type_util.is_player_leave_to_cam_grid(e, self.safe_house_grid) then
		if self.stew_sfx ~= nil then
			self.stew_sfx:Stop()
			self.stew_sfx = nil
		end

		-- 필드 bgm 변경
		music_player_util.play_stage_music({
			name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_tower', state = 'field', mix = 2
		})
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	-- 섹션 6에서 넘어가지 않은 상태에서 세이프하우스 나가지 않은 상황에서 공주에게 interact 하기위한 용도
	if e:GetParamAt(0) == 'lilithtower_make_princess_interactable' then
		local princess = get_character(self.pricess_name)
		princess.Interactable = CS.Oak.NPCInteractable.Create()
		character_util.add_listener(princess, self.cs_controller)
		self.windows_breaker_on_progress_five = true
	end
end

function local_class:on_switch_on_off_event(e)
	if lua_helper.reference_equals(e.SwitchObject, self.get_toilet_android_reset_button())
			and e.IsTurningOn and not self:using_toilet_android() then
		self:reset_toilet_android()
		return true
	end

	return false
end

function local_class:on_touch_event_safe_house_cabinet(e)
	if e.TouchEventType == CS.Oak.TouchEventType.SwipeDown then
		self.qte_complete = true
	end
end

function local_class:windows_breaker_event_setting()
	local food_box = get_field_object('safe_house_food_box')
	food_box.Position = field:GetMarker('safe_house_princess_food_box_pos').position

	local princess = get_character(self.pricess_name)

	if not lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable = CS.Oak.NPCInteractable.Create()
	end
	character_util.add_listener(princess, self.cs_controller)

	character_util.set_position(princess, field:GetMarker('safe_house_princess_pos').position)
	character_util.set_direction(princess, 'left')
	character_util.set_anim(princess, { name = 'seat', loop = true })
	character_util.set_emotion(princess, { name = 'tired' })
end

-- 야구 방망이 얻고 다시 세이프 하우스 입장하면 해야하는 세팅
function local_class:safe_house_stew_event_setting()
	local stew = get_field_object('princess_stew')
	stew.Interactable = CS.Oak.PublishInteractable.Create()
	stew.Position = field:GetMarker('safe_house_princess_stew_pos').position

	local food_box = get_field_object('safe_house_food_box')
	food_box.Position = vector(999, 0, 999)

	local princess = get_character(self.pricess_name)

	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		character_util.remove_relate_event(princess, self.cs_controller)
		-- 다치면 일단 먹어야 해! 에바가 그랬어.
		princess.Interactable.Talk = 'lilithtower_main_s6_146'
	end

	character_util.set_position(princess, field:GetMarker('safe_house_princess_pos').position)
	character_util.set_direction(princess, 'left')
	character_util.remove_emotion(princess)
	character_util.set_anim(princess, { name = 'eat', loop = true })

	if self.stew_sfx == nil then
		self.stew_sfx = music_player_util.play_sfx({
			sfx_name = '01_boiling_01', loop = true, play_pos = stew.Position,
			min_distance = 3, max_distance = 6
		})
	end
end

-- 공주의 특제 스튜 얻기 이벤트
function local_class:princess_stew_event()
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = user_party.Leader
	heal_info.isRevive = false
	heal_info.heal = user_party.Leader.FieldObjectStatsBehaviour.MaxHP

	for i = 0, user_party.Count - 1 do
		heal_info.target = user_party[i]
		heal_info.heal = user_party[i].FieldObjectStatsBehaviour.MaxHP
		command_util.execute_heal(heal_info)
	end

	if self.stew_drink_sfx ~= nil then
		self.stew_drink_sfx:Stop()
		self.stew_drink_sfx = nil
	end

	if self.heal_sfx ~= nil then
		self.heal_sfx:Stop()
		self.heal_sfx = nil
	end

	self.stew_drink_sfx = music_player_util.play_sfx({sfx_name = '01_drinking_02', loop = false})
	self.heal_sfx = music_player_util.play_sfx({sfx_name = '02_magic_heal_02', loop = false})
end

-- 이벤트 이후 공주와 상호작용
function local_class:windows_breaker_event(princess)
	local main_script = 'lilithtower_main_s6_'

	-- 공주 왼쪽으로 정렬
	party_util.align_party(princess.Position, 'right', 0.5, 'arc')
	character_util.set_direction(princess, 'right')

	-- ....
	music_player_util.play_sfx_one_shot('01_swing_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 112, skip = true })

	-- 아....헤실미소.
	character_util.remove_anim(princess)
	character_util.set_emotion(princess, { name = 'smile' })
	music_player_util.play_sfx_one_shot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 113, skip = true })

	character_util.set_anim(user_party.Leader, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	wait_for_sec(0.9)
	character_util.remove_anim(user_party.Leader)

	-- 아니...
	character_util.set_emotion(princess, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 114, skip = true })

	-- 옆방에서 사람들이
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 115, skip = true })

	character_util.show_emoticon_async(princess, nil, 'silence')

	-- 이 일의 주동자가..
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 141, skip = true })

	-- ....
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 116, skip = true })

	-- 아니야. 그냥 잘못 들은거겠지.
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 117, skip = true })

	-- 아 참. 여왕님에게 들었어.
	character_util.set_emotion(princess, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 118, skip = true })

	-- 세이프 하우스를 지키기 위해 중요한 임무를 맡게 되었다면서?!
	character_util.set_anim(princess, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 119, skip = true })
	character_util.remove_anim(princess)

	-- 나도 협력할게!
	character_util.set_anim(princess, { name = 'victory_get', loop = false })
	music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 120, skip = true })

	-- 일단 이것부터...!
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 121, skip = true })

	-- 공주가 윈도우 브레이커를 던저 준다.
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_anim(princess, { name = 'throw', loop = false, next_anim = 'idle' })
	local windows_breaker = drop_item_util.create_item({ pos = princess.Position, target = user_party.Leader.Position
	, itemid = 20434, notforinven = true, lootstate = 'dontfindlooter', sprscale = 0.7, skip_text = true })
	windows_breaker:SetSortingLayer(true)

	music_player_util.play_sfx_one_shot('01_air_spin_02')
	wait_for_sec(1)

	local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true})
	character_util.set_anim(user_party.Leader, { name = 'eat' })
	wait_for_sec(0.5)
	equipping_sfx:Stop()

	windows_breaker.ConsumeTarget = user_party.Leader
	windows_breaker:Fly()
	wait_for_sec(0.5)
	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent,
			{ItemId = 20434},
			'lilithtower_window_breaker_title',
			'lilithtower_window_breaker_subtitle',
			'lilithtower_window_breaker_desc', 1)

	character_util.remove_anim(user_party.Leader)

	local suit_bat = self:get_knight_suit_bat()
	character_util.set_position(suit_bat, user_party.Leader.Position)
	character_util.set_direction(suit_bat, user_party.Leader.Direction)

	local character_spec_id = 302922
	if user_util.has_knight_male() then
		character_spec_id = 302921
	end

	character_util.convert_to_manual_character(suit_bat)
	user_party.Leader.CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(user_party_leader.CharacterInfo.User, character_spec_id)

	field_ui_manager:SetUI(suit_bat, CS.Oak.FieldUiType.TopHpBar)

	party_util.stop_and_disable_control()

	-- 플레이어 시작 포즈
	character_util.set_emotion(princess, { name = 'smile' })
	music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'victory_get', loop = false }, { name = 'smile' })
	wait_for_sec(2)
	character_util.remove_anim(user_party.Leader)

	-- 내 비장의 무기야.
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 142, skip = true })

	-- 인베이더들과의 결전을 위해 숨겨놓으려 했지만..
	character_util.set_anim_and_emotion(princess, { name = 'question', loop = false }, { name = 'tired' })
	music_player_util.play_sfx_one_shot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 143, skip = true })

	-- 특별히 빌려줄게!
	character_util.remove_anim(princess)
	character_util.set_emotion(princess, { name = 'smile' })
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 123, skip = true })

	-- 그리고 혹시 다치면 이곳으로 와. 내가 특제 스튜를 준비해놓을테니까!
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 124, skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.nod_twice(user_party.Leader)

	-- 함께 살아남자.
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 125, skip = true })

	-- 분명 선조님들도 지켜봐주시고 계실거야!
	speech_bubble_util.show_speech_bubble_async(princess, { key = main_script .. 145, skip = true })

	character_util.set_direction(princess, 'left')
	character_util.remove_emotion(princess)
	character_util.set_anim(princess, { name = 'eat', loop = true })

	character_util.remove_relate_event(princess, self.cs_controller)

	-- 조금만 기다려줘.. 최고의 스튜를 만들테니까!
	princess.Interactable.Talk = 'lilithtower_main_s6_126'

	self.is_show_windows_breaker_event = true
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.remove_emotion(princess)

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if quest_progress.InnerProgress > 5 then
		quest_util.set_custom_state(quest_progress, self.windows_breaker_key, 1)
	elseif quest_progress.InnerProgress == 5 then
		self.reserve_window_breaker = true
	end
end

-- 고장난 엘리베이터 상호작용
function local_class:interact_with_broken_elevator()
	for i = 0, user_party.Count - 1 do
		character_util.set_immortal(user_party[i], true)
	end

	field_ui_manager:Hide()

	party_util.stop_and_disable_control()

	field_ui_util.show_narration_async({ key = 'liilthtower_broken_elevator' })

	coroutine.yield(nil)

	for i = 0, user_party.Count - 1 do
		character_util.set_immortal(user_party[i], false)
	end

	field_ui_manager:Show()

	party_util.reset_controllers()
end

-- 세이프 하우스 캐비닛 상호작용
function local_class:open_safe_house_cabinet()
	self.cabinet_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_earthquake_03', loop = true, volume = 2, type_priority = 'loop', player_priority = 'object' })

	local timer = 0
	local duration = 2

	local start_pos = self.get_safe_house_entry_cabinet().Position
	local end_pos = start_pos + vector(0, 0, -2)

	while timer < duration do
		timer = timer + unity_class.time.deltaTime

		local progress = 1 - ((duration - timer) / duration)
		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		self.get_safe_house_entry_cabinet().Position = cur_pos

		coroutine.yield(nil)
	end

	if self.cabinet_sfx ~= nil then
		self.cabinet_sfx:FadeOut()
		self.cabinet_sfx = nil
	end

	self.get_safe_house_entry_cabinet().Position = end_pos

	stage_progress:SendCustomData(self.move_safe_house_cabinet_key, true)
end

--region 세이프 하우스 NPC 작업

-- NPC 갱신
function local_class:update_safe_house_npc()
	self.current_safe_house_npc = self.safe_house_npc.none

	local main_quest_id = self.main_quest_id
	local police_quest_id = 259
	local engineer_quest_id = 260
	local pickpocket_quest_id = 261
	local beth_quest_id = 264

	-- 비서
	local quest = user_progress:GetStartedQuest(main_quest_id)
	if quest ~= nil and quest_util.get_custom_state(quest, self.secretary_state_key) ~= 1 then
		self.current_safe_house_npc = self.current_safe_house_npc | self.safe_house_npc.secretary
	end

	-- 기술자
	quest = user_progress:GetStartedQuest(engineer_quest_id)
	if quest ~= nil and quest.IsComplete then
		self.current_safe_house_npc = self.current_safe_house_npc | self.safe_house_npc.engineer
	end

	-- 소매치기
	quest = user_progress:GetStartedQuest(pickpocket_quest_id)
	if quest ~= nil and quest.IsComplete then
		self.current_safe_house_npc = self.current_safe_house_npc | self.safe_house_npc.pickpocket
	end

	-- 경관
	quest = user_progress:GetStartedQuest(police_quest_id)
	if quest ~= nil and quest.IsComplete and quest.Grade == 0 then
		self.current_safe_house_npc = self.current_safe_house_npc | self.safe_house_npc.police
	end
end

-- NPC 위치 배치
function local_class:setting_safe_house_npc()
	local secretary = self.get_secretary()
	local police = self.get_police()
	local engineer = self.get_engineer()
	local pickpocket = self.get_pickpocket()

	local reset_npc = function()
		character_util.set_position(secretary, vector(999, 0, 999))
		character_util.set_position(police, vector(999, 0, 999))
		character_util.set_position(engineer, vector(999, 0, 999))
		character_util.set_position(pickpocket, vector(999, 0, 999))

		secretary.Interactable.Talk = nil
		police.Interactable.Talk = nil
		engineer.Interactable.Talk = nil
		pickpocket.Interactable.Talk = nil
	end

	if self.current_safe_house_npc == self.safe_house_npc.secretary then
		reset_npc()
		-- 비서
		character_util.set_position(secretary, self.get_house_marker_pos(1))

		character_util.set_direction(secretary, 'left')

		character_util.set_anim_and_emotion(secretary, { name = 'idle' }, { name = 'tired' })

		-- 각하께서 총에 맞으시다니…
		secretary.Interactable.TalkSfx = ''
		secretary.Interactable.Talk = 'lilithtower_safe_house_npc_1'

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.police | self.safe_house_npc.engineer)
			and not self.saw_house_event_list[1] then
		reset_npc()
		-- 비서 경관 기술자
		character_util.set_position(secretary, self.get_house_marker_pos(1))
		character_util.set_position(engineer, self.get_house_marker_pos(2))
		character_util.set_position(police, self.get_house_marker_pos(3))

		character_util.set_direction(secretary, 'down')
		character_util.set_direction(engineer, 'right')
		character_util.set_direction(police, 'left')

		character_util.set_anim_and_emotion(secretary, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(engineer, { name = 'eat' }, { name = 'idle' })
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'idle' })

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.engineer)
			and not self.saw_house_event_list[2] then
		reset_npc()
		-- 비서 기술자
		character_util.set_position(secretary, self.get_house_marker_pos(1))
		character_util.set_position(engineer, self.get_house_marker_pos(3))

		character_util.set_direction(engineer, 'left')
		character_util.set_direction(secretary, 'left')

		character_util.set_anim_and_emotion(engineer, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(secretary, { name = 'idle' }, { name = 'idle' })

	elseif self.current_safe_house_npc == (self.safe_house_npc.secretary |
			self.safe_house_npc.engineer | self.safe_house_npc.police | self.safe_house_npc.pickpocket)
			and not self.saw_house_event_list[3] then
		-- 비서 경관 기술자 소매치기
		reset_npc()

		character_util.set_position(pickpocket, self.get_house_marker_pos(4))
		character_util.set_position(police, self.get_house_marker_pos(5))
		character_util.set_position(secretary, self.get_house_marker_pos(1))
		character_util.set_position(engineer, self.get_house_marker_pos(3))

		character_util.set_direction(pickpocket, 'left')
		character_util.set_direction(police, 'left')
		character_util.set_direction(secretary, 'right')
		character_util.set_direction(engineer, 'left')

		character_util.set_anim_and_emotion(pickpocket, { name = 'eat' }, { name = 'idle' })
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'mad' })
		character_util.set_anim_and_emotion(secretary, { name = 'question', loop = false }, { name = 'idle' })
		character_util.set_anim_and_emotion(engineer, { name = 'bomb_idle' }, { name = 'idle' })

		-- 비서 : (question)세이프 하우스 창고 쪽 비품이 자꾸 사라진다는 이야기가 들리는데…
		secretary.Interactable.Talk = 'lilithtower_safe_house_npc_33'
		-- 기술자(bomb_idle) : 감시용 안드로이드라도 만들어 볼까요?
		engineer.Interactable.Talk = 'lilithtower_safe_house_npc_34'

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.engineer | self.safe_house_npc.pickpocket) then

		if not self.saw_house_event_list[4] then
			reset_npc()
			character_util.set_position(police, vector(999, 0, 999))
			character_util.set_position(engineer, vector(999, 0, 999))
			character_util.set_position(pickpocket, vector(999, 0, 999))

			police.Interactable.Talk = nil
			engineer.Interactable.Talk = nil
			pickpocket.Interactable.Talk = nil

			-- 비서 기술자 소매치기
			character_util.set_position(engineer, self.get_house_marker_pos(4))
			character_util.set_position(pickpocket, self.get_house_marker_pos(5))

			character_util.set_direction(engineer, 'left')
			character_util.set_direction(pickpocket, 'left')

			character_util.set_anim_and_emotion(engineer, { name = 'push' }, { name = 'idle' })
			character_util.set_anim_and_emotion(pickpocket, { name = 'idle' }, { name = 'idle' })

			if self.paper_item == nil then
				self.paper_item = drop_item_util.create_item(
						{ pos = engineer.Position + vector(-0.2,0.5,0)
						, skip_text = true, itemid = 20022, notforinven = true, lootstate = 'dontfindlooter' })
			end
		end
		if not self.saw_house_event_list[5] then
			character_util.set_position(police, vector(999, 0, 999))

			secretary.Interactable.Talk = nil
			police.Interactable.Talk = nil

			character_util.set_position(secretary, self.get_house_marker_pos(7))
			character_util.set_direction(secretary, 'left')

			character_util.set_anim_and_emotion(secretary, { name = 'idle' }, { name = 'idle' })
		end

	elseif self.current_safe_house_npc == self.safe_house_npc.engineer
			and not self.saw_house_event_list[6] then
		reset_npc()
		-- 기술자
		character_util.set_position(engineer, self.get_house_marker_pos(2))

		character_util.set_direction(engineer, 'left')

		character_util.set_anim_and_emotion(engineer, { name = 'seat' }, { name = 'idle' })

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.police | self.safe_house_npc.engineer)
			and not self.saw_house_event_list[7] then
		reset_npc()
		-- 경관 기술자
		character_util.set_position(engineer, self.get_house_marker_pos(1))
		character_util.set_position(police, self.get_house_marker_pos(3))

		character_util.set_direction(engineer, 'right')
		character_util.set_direction(police, 'left')

		character_util.set_anim_and_emotion(engineer, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'idle' })

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.engineer | self.safe_house_npc.pickpocket)
			and not self.saw_house_event_list[8] then
		reset_npc()
		-- 기술자 소매치기
		character_util.set_position(engineer, self.get_house_marker_pos(6))
		character_util.set_position(pickpocket, self.get_house_marker_pos(7))

		character_util.set_direction(engineer, 'right')
		character_util.set_direction(pickpocket, 'left')

		character_util.set_anim_and_emotion(engineer, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(pickpocket, { name = 'idle' }, { name = 'sleep_deep' })

	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.police | self.safe_house_npc.engineer | self.safe_house_npc.pickpocket)
			and not self.saw_house_event_list[9] then
		reset_npc()
		-- 경관 기술자 소매치기

		character_util.set_position(engineer, self.get_house_marker_pos(9))
		character_util.set_position(police, self.get_house_marker_pos(1))
		character_util.set_position(pickpocket, self.get_house_marker_pos(8))

		character_util.set_direction(engineer, 'down')
		character_util.set_direction(police, 'right')
		character_util.set_direction(pickpocket, 'left')

		character_util.set_anim_and_emotion(engineer, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'idle' })
		character_util.set_anim_and_emotion(pickpocket, { name = 'idle' }, { name = 'idle' })
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.police) and not self.saw_house_event_list[10] then
		reset_npc()
		-- 비서 경관
		character_util.set_position(secretary, self.get_house_marker_pos(1))
		character_util.set_position(police, self.get_house_marker_pos(3))

		character_util.set_direction(secretary, 'right')
		character_util.set_direction(police, 'left')

		character_util.set_anim_and_emotion(secretary, { name = 'question', loop = false }, { name = 'idle' })
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'idle' })
	elseif self.current_safe_house_npc == self.safe_house_npc.police then
		reset_npc()
		-- 경관
		character_util.set_position(police, self.get_house_marker_pos(1))

		character_util.set_direction(police, 'left')

		character_util.set_anim_and_emotion(secretary, { name = 'idle' }, { name = 'attack' })

		-- 빌어먹을 테러범 놈들…! 사태가 진압되면 전부 감방에 처넣어줄 테다!
		police.Interactable.Talk = 'lilithtower_safe_house_npc_78'
	end
end

function local_class:safe_house_zone_event(zone_number)
	local secretary = self.get_secretary()
	local police = self.get_police()
	local engineer = self.get_engineer()
	local pickpocket = self.get_pickpocket()

	if self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.police | self.safe_house_npc.engineer) then
		-- 비서 경관 기술자
		if zone_number == 1 and not self.saw_house_event_list[1] then
			self.saw_house_event_list[1] = true
			-- 경관 : 지금 뭐 하시는 겁니까? 바닥은 왜 뒤져요?
			music_player_util.play_sfx_one_shot('03_equipping_01')
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_2' })

			--기술자(eat) : 아이디어가 생각났어…
			music_player_util.play_sfx( { sfx_name = '01_gatcha_point_01', play_pos = engineer.Position })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_3' })

			--기술자(eat) : 지금 당장 안드로이드 죠니 3세를 만들 재료가 필요해.
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_4' })

			--비서(tired, bomb_idle) : 글쎄 여기는 그런 재료가 딱히 없다니까요?
			character_util.set_anim_and_emotion(secretary, { name = 'bomb_idle' }, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_5' })
			character_util.remove_anim_and_emotion(secretary)

			--기술자(eat) : …그, 그럴 리가…
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_6' })

			--경관(nodx2) : 비서님 말이 맞아. 내가 이미 한 번 조사해봤다고.
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = engineer.Position })
			character_util.set_animation_n_times(police, { name = 'nod', count = 2 })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_7' })

			--경관 : 안드로이드 관련된 물건은 단 한개도 없을걸.
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_8' })

			--기술자 : 으…
			music_player_util.play_sfx( { sfx_name = '01_swing_01', play_pos = engineer.Position })
			character_util.set_anim(engineer, { name = 'idle' })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_9' })

			--기술자 살짝 몸을 떤다.
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = engineer.Position })
			character_util.shake(engineer, 0.02, 1)
			wait_for_sec(1)

			--기술자 : …말도 안 돼…
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_10' })

			--기술자(dead) : 죽더라도 안드로이드 사이에 파묻혀 죽고 싶다는 내 꿈이…!!!
			music_player_util.play_sfx( { sfx_name = '03_dialogue_sadness_01', play_pos = engineer.Position })
			character_util.set_anim(engineer, { name = 'dead', loop = false, sfx_name = '01_trip_01' })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_11' })

			--경관 (tired) : 에휴… 별난 친구네 정말…
			music_player_util.play_sfx( { sfx_name = '03_dialogue_tipsy_01', play_pos = engineer.Position })
			character_util.set_emotion(police, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_12' })

			secretary.Interactable.Talk = 'lilithtower_safe_house_npc_46_2'
			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_11'
			police.Interactable.Talk = 'lilithtower_safe_house_npc_12'
		end
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.engineer) then

		-- 비서 기술자
		if zone_number == 1 and not self.saw_house_event_list[2] then
			self.saw_house_event_list[2] = true

			-- 비서 : 우리 리리스 각하…
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_15' })

			-- 비서 (love, sing) : 부상 상태임에도 자국민들을 생각하는 모습이 너무 멋있지 않아요?
			music_player_util.play_sfx({ sfx_name = '01_gatcha_point_01', play_pos = secretary.Position })
			character_util.set_anim_and_emotion(secretary, { name = 'sing' }, { name = 'love' })
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_16' })
			character_util.set_emotion(secretary, { name = 'smile' })

			-- 기술자(nodx2) : 확실히 기품 자체가 다르달까… (비서 smile)
			character_util.set_animation_n_times(engineer, { name = 'nod', count = 2 })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_17' })

			-- 기술자(cross_arm) : …각하를 본따 안드로이드를 만들면 훌륭한 작품이 탄생할 텐데…
			music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = secretary.Position })
			character_util.set_anim(engineer, { name = 'cross_arm' })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_18' })

			-- 비서 : (기술자쪽을 쳐다보며)…네? 뭐라고 하셨어요?
			music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = secretary.Position })
			character_util.look_at(secretary, engineer)
			character_util.remove_anim_and_emotion(secretary)
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_19' })

			-- 기술자 : 아…아무것도 아니에요.
			character_util.remove_anim(engineer)
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_20' })

			secretary.Interactable.Talk = 'lilithtower_safe_house_npc_19'
			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_20'
		end
	elseif self.current_safe_house_npc == (self.safe_house_npc.secretary |
			self.safe_house_npc.engineer | self.safe_house_npc.police | self.safe_house_npc.pickpocket) then
		-- 비서 경관 기술자 소매치기
		if zone_number == 2 and not self.saw_house_event_list[3] then
			self.saw_house_event_list[3] = true
			-- 소매치기 창고에서 eat 모션중이고 경관이 뒤에서 attack
			music_player_util.play_sfx({ sfx_name = '01_hit_comic_01', play_pos = police.Position })
			character_util.set_animation_n_times(police, { name = 'attack' })
			wait_for_sec(0.2)

			--소매치기 : 아얏! (mad 였다가 뒤돌아서 surprise)
			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', play_pos = pickpocket.Position })
			character_util.normal_jump(pickpocket)
			music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = pickpocket, type_priority = 'event' })
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'embarrassed' }, { name = 'mad' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_21' })

			music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = pickpocket.Position })
			character_util.remove_anim(pickpocket)
			character_util.look_at(pickpocket, police)
			wait_for_sec(0.5)

			--소매치기 : …오잉? 아저씨?
			music_player_util.play_sfx({ sfx_name = '01_small_jump_01', play_pos = pickpocket.Position })
			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', play_pos = pickpocket.Position })
			character_util.normal_jump(pickpocket)
			character_util.set_emotion(pickpocket, { name = 'surprise' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_22' })

			--경관 : 아저씨가 아니라 경관님이라고 했지!
			character_util.set_emotion(police, { name = 'mad' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_23' })

			--경관 : 너 설마 여기서도 물건 훔치고 다니는 거냐?
			music_player_util.play_sfx({ sfx_name = '01_male_shout_01', play_pos = police.Position })
			character_util.set_anim(police, { name = 'cast2' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_24' })
			character_util.remove_anim(police)

			--소매치기 : 아…아냐!
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_25' })

			--소매치기 : (attack, release)여기서 훔치는 건 오히려 사람을 돕는 일이라고!
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'release', sfx_name = '01_swing_01'}, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_26' })

			--소매치기 : 테러범 놈들이 가진 걸 훔쳐서 시민을 도왔단 말야!
			character_util.set_anim(pickpocket, { name = 'cast2' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_27' })

			--경관 : (question)그럼 창고는 왜 털고 있는 건데?
			character_util.set_emotion(police, { name = 'attack' })
			character_util.set_anim(police, { name = 'idle' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_28' })

			--소매치기 : 이건…
			character_util.remove_anim(pickpocket)
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_29' })

			--소매치기 : 이건… 그러니까.
			music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = pickpocket.Position })
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'question', loop = false }, { name = 'sleep_deep' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_30' })

			--소매치기 : (smile, sing) 예행 연습 같은 거지!
			music_player_util.play_sfx({ sfx_name = '01_gatcha_point_01', play_pos = pickpocket.Position })

			character_util.set_anim_and_emotion(pickpocket, { name = 'sing'}, { name = 'smile' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_31' })

			--경관 : 이 녀석이 진짜…
			music_player_util.play_sfx({ sfx_name = '03_dialogue_angry_01', play_pos = police.Position })

			character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'mad' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_32' })

			pickpocket.Interactable.Talk = 'lilithtower_safe_house_npc_31'
			police.Interactable.Talk = 'lilithtower_safe_house_npc_32'
		end
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.secretary | self.safe_house_npc.engineer | self.safe_house_npc.pickpocket) then
		-- 비서 기술자 소매치기
		if zone_number == 2 and not self.saw_house_event_list[4] then
			self.saw_house_event_list[4] = true

			-- 기술자 열심히 구석에서 무언가 읽고 있고, 소매치기가 옆으로 다가가서 eat모션으로 훔치는 연출
			character_util.move_to_async(pickpocket, pickpocket.Position - vector(0.5, 0, 0),
					1, nil, true, true)

			local drag_sfx = music_player_util.play_sfx( {
				sfx_name = '01_grass_slide_01', play_pos = pickpocket.Position })
			character_util.set_animation_n_times_async(pickpocket, { name = 'eat', count = 3 })
			drag_sfx:Stop()
			self.paper_item.Position = vector(999,0,999)

			music_player_util.play_sfx( { sfx_name = '01_player_jump_01', play_pos = engineer.Position })
			character_util.look_at(engineer, pickpocket)
			character_util.normal_jump(engineer)
			character_util.remove_anim(engineer)
			character_util.set_emotion(engineer,{ name = 'surprise'})

			character_util.move_to_async(pickpocket, pickpocket.Position + vector(0.5, 0, 0),
					1, nil, true, true)

			--소매치기 ? 말풍선
			character_util.set_anim(pickpocket, { name = 'question', loop = false })
			character_util.show_emoticon_async(pickpocket, nil, 'question')

			--소매치기 : …뭐야 이건?
			music_player_util.play_sfx( { sfx_name = '01_paper_01', play_pos = pickpocket.Position })
			music_player_util.play_sfx( { sfx_name = '03_dialogue_negative_02', play_pos = pickpocket.Position })
			self.paper_item.Position = pickpocket.Position + vector(0.2,0.5,0)
			character_util.set_anim(pickpocket, { name = 'push' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_35' })

			--소매치기 : 연상녀를 꼬시는 24가지 방법?
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_36' })

			--기술자 : 도…돌려줘!
			music_player_util.play_sfx( { sfx_name = '03_dialogue_negative_01', play_pos = engineer.Position })
			character_util.set_anim_and_emotion(engineer, { name = 'cast' }, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_37' })
			self.paper_item:ConsumeComplete()
			self.paper_item = nil

			--소매치기 : (attack)왜 구석에서 음침하게 이런 걸 읽고 있어?
			music_player_util.play_sfx( { sfx_name = '01_swing_01', play_pos = pickpocket.Position })
			character_util.look_at(pickpocket, engineer)
			character_util.remove_anim(pickpocket)
			character_util.set_emotion(pickpocket, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_38' })

			--소매치기 : (idle, cross_arm)당신 설마…(기술자 blush)
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = pickpocket.Position })
			character_util.set_emotion(engineer, { name = 'blood' })
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'cross_arm' }, { name = 'idle' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_39' })

			--소매치기 : (smile, victory_get)나한테 관심 있구나?!
			music_player_util.play_sfx( { sfx_name = '01_stage_intro_jump_01', play_pos = pickpocket.Position })
			music_player_util.play_sfx( { sfx_name = '03_dialogue_positive_01', play_pos = pickpocket.Position })
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'victory_get', loop = false }, { name = 'awesome' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_40' })

			--기술자 : ? 말풍선
			music_player_util.play_sfx( { sfx_name = '03_dialogue_negative_02', play_pos = engineer.Position })
			character_util.remove_anim_and_emotion(engineer)
			character_util.show_emoticon_async(engineer, nil, 'question')
			character_util.remove_anim_and_emotion(pickpocket)

			--기술자 : 그게 무슨 소리야? 어서 돌려줘.
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_41' })

			--기술자 : 미안하지만 물렁한 인간의 생체에는 관심 없다고.
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = engineer.Position })
			character_util.set_anim(engineer, { name = 'bomb_idle' })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_42' })
			character_util.remove_anim(engineer)

			--소매치기(attack, release) : 그, 그럼 이 책은 뭔데?!
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'release', sfx_name = '01_swing_01' }, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_43' })
			character_util.remove_anim(pickpocket)

			--기술자 : 최근에 발명 중인 ‘연상 타입의 안드로이드’ AI에 도움이 될까 해서 찾아본 것뿐이야.
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_44' })

			--기술자(question) : 혹시 관심 있으면 하나 만들어줄까?
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = engineer.Position })
			character_util.set_anim(engineer, { name = 'question', loop = false })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_45' })

			--소매치기(mad, cast2) : …어이없어 진짜!
			music_player_util.play_sfx( { sfx_name = '03_dialogue_negative_01', play_pos = pickpocket.Position })
			character_util.set_emotion(pickpocket,{ name = 'mad' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_46' })

			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_45'
			pickpocket.Interactable.Talk = 'lilithtower_safe_house_npc_46'
		elseif zone_number == 3 and not self.saw_house_event_list[5] then
			self.saw_house_event_list[5] = true
			-- 비서 : 불편하거나 다친 곳이 있다면 언제든지 말씀해 주세요!
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_46_1' })

			--비서 : …
			music_player_util.play_sfx( { sfx_name = '01_rustle_01', play_pos = secretary.Position })
			character_util.set_anim(secretary, { name = 'question', loop = false })
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_46_2' })

			--비서 : (tired)무고한 시민들이 이렇게나 많이 다치다니…
			character_util.set_emotion(secretary, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_46_3' })

			secretary.Interactable.Talk = 'lilithtower_safe_house_npc_46_3'
		end
	elseif self.current_safe_house_npc == self.safe_house_npc.engineer then
		-- 기술자
		if zone_number == 1 and not self.saw_house_event_list[6] then
			self.saw_house_event_list[6] = true
			-- 기술자 : 여긴 안드로이드도 없고…
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_47' })

			-- 기술자 : …조금 지루한걸.
			music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = engineer.Position })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_48' })

			-- 기술자 : {0}… 잘 하고 있으려나.
			speech_bubble_util.show_speech_bubble_async(engineer,
					{ key = { 'lilithtower_safe_house_npc_49', user.Name } })

			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_48'
		end
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.police | self.safe_house_npc.engineer) then
		-- 경관 기술자
		if zone_number == 1 and not self.saw_house_event_list[7] then
			self.saw_house_event_list[7] = true
			-- 경관 : 타워의 안드로이드를 만들었다고?
			music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = police.Position })
			character_util.set_anim(police, { name = 'question', loop = false })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_50' })

			--기술자 : (nodx2)다…다룰 줄도 알고…
			character_util.set_animation_n_times(engineer, { name = 'nod', count = 2 })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_51' })

			--경관 : (smile, clap) 어린 나이에 대단하네 이 친구! (기술자 cast)
			character_util.set_anim(engineer, { name = 'cast' })
			music_player_util.play_sfx({sfx_name = '01_clap_02', parent = police, loop = false})
			character_util.set_anim_and_emotion(police, { name = 'clap' }, { name = 'smile' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_52' })

			--경관 : …
			character_util.remove_anim_and_emotion(police)
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_53' })

			--경관 : (cross_arm)내 동료중에도 멋진 안드로이드가 있어.
			character_util.set_anim(police, { name = 'cross_arm' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_54' })

			--경관 : 지금은 사정이 있어 잠시 정비소 신세를 지고 있지만…
			character_util.set_emotion(police, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_55' })

			--경관 : 금방 돌아올 거야. 동료들이 기다리고 있으니까.
			character_util.remove_anim_and_emotion(police)
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_56' })

			police.Interactable.Talk = 'lilithtower_safe_house_npc_56'
			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_53'
		end
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.engineer | self.safe_house_npc.pickpocket) then
		-- 기술자 소매치기
		if zone_number == 3 and not self.saw_house_event_list[8] then
			self.saw_house_event_list[8] = true
			-- 소매치기 : 여기에 오기 전까지 인질로 잡혀가는 중이었는데…
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_57' })

			-- 소매치기 : 테러범 놈들, 천둥신이니 뭐니 하면서 인질들을 무자비하게 다루더라.
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'release', sfx_name = '01_swing_01' }, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_58' })
			character_util.remove_anim(pickpocket)

			-- 소매치기 : {0}가 아니었으면 끔찍한 최후를 맞았을지도 몰라.
			character_util.set_emotion(pickpocket, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(pickpocket,
					{ key = { 'lilithtower_safe_house_npc_59', user.Name } })

			-- 기술자(nodx2) : 나도.. {0}덕에 이 곳에 올 수 있었어.
			music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = engineer.Position })
			character_util.set_animation_n_times(engineer, { name = 'nod', count = 2 })
			speech_bubble_util.show_speech_bubble_async(engineer,
					{ key = { 'lilithtower_safe_house_npc_60', user.Name } })

			-- 기술자 : 안드로이드보다 감정이 결여된 놈들이 있다니…
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_63' })

			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_63'
			-- FIXME : Talk에 Format 처리된 스트링이 들어가면 보이스가 안나옴, 일단 보이스가 없으니 냅두나 주석은 추가함
			pickpocket.Interactable.Talk = game_string:Format('lilithtower_safe_house_npc_59', user.Name)
		end
	elseif self.current_safe_house_npc ==
			(self.safe_house_npc.police | self.safe_house_npc.engineer | self.safe_house_npc.pickpocket) then
		-- 경관 기술자 소매치기
		if zone_number == 1 and not self.saw_house_event_list[9] then
			self.saw_house_event_list[9] = true
			-- 경관 : (attack, release)무사히 집으로 귀환하게 되면 이제 도둑질은 그만둬.
			character_util.set_anim_and_emotion(police,
					{ name = 'release', sfx_name = '01_swing_01' }, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_64' })
			character_util.remove_anim(police)

			--소매치기 : 뭐? 아저씨. (attack)생업을 끊으라는 건 너무 가혹한 말 아냐?
			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', play_pos = pickpocket.Position })
			character_util.set_emotion(pickpocket, { name = 'attack' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_65' })

			--경관 : (attack) 다른 일을 찾으면 되잖아!
			music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', play_pos = police.Position })

			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_66' })

			--경관 : 이 친구한테 안드로이드 관련 기술을 배워도 되고.
			character_util.remove_emotion(police)
			character_util.set_anim(police, { name = 'release', sfx_name = '01_swing_01' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_67' })
			character_util.remove_anim(police)

			--소매치기 : 뭐-어?
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_68' })

			--소매치기 : (mad, cast2)저런 너드 같은 남자랑 어떻게 같이 일을 해!
			music_player_util.play_sfx({ sfx_name = '01_female_shout_01', play_pos = pickpocket.Position })
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'cast2' }, { name = 'mad' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_69' })

			--소매치기 : 딱 봐도 여자친구 없게 생겼는데.
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_70' })

			-- 경관 : 듣자 하니 같은 젊은 친구한테 말이 심하네!
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_71' })

			--소매치기 : ...말풍선
			character_util.show_emoticon_async(pickpocket, nil, 'silence')

			--소매치기 : (sleep_deep, cross_arm)바, 방금 말은 사과할게.
			music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = pickpocket.Position })
			character_util.set_direction(pickpocket, 'right')
			character_util.set_anim_and_emotion(pickpocket,
					{ name = 'cross_arm' }, { name = 'sleep_deep' })
			speech_bubble_util.show_speech_bubble_async(pickpocket, { key = 'lilithtower_safe_house_npc_72' })

			-- 기술자 : 난 아무렇지도 않은데 왜…?
			music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', play_pos = engineer.Position })
			speech_bubble_util.show_speech_bubble_async(engineer, { key = 'lilithtower_safe_house_npc_73' })

			engineer.Interactable.Talk = 'lilithtower_safe_house_npc_73'
			police.Interactable.Talk = 'lilithtower_safe_house_npc_71'
			pickpocket.Interactable.Talk = 'lilithtower_safe_house_npc_72'
		end
	elseif self.current_safe_house_npc == (self.safe_house_npc.secretary | self.safe_house_npc.police) then
		if zone_number == 1 and not self.saw_house_event_list[10] then
			self.saw_house_event_list[10] = true
			-- 비서 : (question)요새 마계 치안은 어때요?
			speech_bubble_util.show_speech_bubble_async(secretary, { key = 'lilithtower_safe_house_npc_74' })
			character_util.remove_anim(secretary)

			-- 경관 : 늘 똑같죠. 범죄율은 하늘을 치솟는데 월급은 박봉이고…
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_75' })

			-- 경관 : (tried) 마누라는 돈 벌어 오라고 난리고.
			music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', play_pos = police.Position })
			character_util.set_emotion(police, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_76' })

			-- 경관 : …마트 코인이라도 해야 하나.
			speech_bubble_util.show_speech_bubble_async(police, { key = 'lilithtower_safe_house_npc_77' })

			secretary.Interactable.Talk = 'lilithtower_safe_house_npc_74'
			police.Interactable.Talk = 'lilithtower_safe_house_npc_75'
		end
	end
end

--endregion

--endregion 옷장에 숨은 생존자
function local_class:aooni_interact_with_cabinet()
	local cabinet = self.get_aooni_cabinet()
	local survivor = self.get_aooni_survivor()

	party_util.align_to_target(vector_util.get_x0z(cabinet.Bounds.center), 'down', 1, 'linear')

	cabinet:CancelShake()

	survivor.ActiveState = active_state('enabled')
	character_util.set_emotion(survivor, {name = 'scared'})
	character_util.shake(survivor, 0.03, 999)

	music_player_util.play_sfx_one_shot('01_interact_greenland_01')
	animator_util.play_async(cabinet, 'lilithtower_cabinet_on', 0.5)

	--덜덜덜덜덜덜
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(survivor, {key = 'lilithtower_aooni_shake_1', skip = true})

	music_player_util.play_sfx_one_shot('01_interact_greenland_01')
	animator_util.play_async(cabinet, 'lilithtower_cabinet_off', 0.5)
	character_util.stop_shake(survivor)
	character_util.remove_emotion(survivor)
	survivor.ActiveState = active_state('disabled')

	cabinet:Shake(0.02, 999999)

	self.current_aooni_state = self.aooni_state.in_room
end
--region

--region 화장실 출입 금지

function local_class:reset_toilet_android()
	local android = self.get_toilet_android()

	self.get_fx_reset():Instantiate(android.Position)

	android.Position = self.toilet_android_origin_pos
	self.get_toilet_android_gimmick().Position = self.toilet_android_origin_pos

	self.get_fx_reset():Instantiate(android.Position)
end

function local_class:using_toilet_android()
	return self.toilet_android_lua_table ~= nil and
			(self.toilet_android_lua_table.cur_android_state == self.toilet_android_lua_table.android_state.move
					or self.toilet_android_lua_table.activated)
end

function local_class:player_enter_toilet()
	while self:using_toilet_android() do
		coroutine.yield()
	end

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local npc = self.get_toilet_npc()
	local reset_pos = self.get_toiler_reset_pos()

	--플레이어 들어가면 화장실에 사람이 있는데 들어오냐면서 나가라고 소리치고 플레이어 쫓겨나감
	character_util.remove_emotion(npc)
	character_util.remove_anim(npc, true)
	character_util.stop_shake(npc)

	character_util.look_at(user_party.Leader, npc)

	--생존자 (남) : 당신 미쳤어? 안에 사람 있는 거 안 보여?
	character_util.set_emotion(npc, {name = 'attack'})
	character_util.normal_jump(npc, '01_small_jump_01')
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	speech_bubble_util.show_speech_bubble_async(npc, {key = 'lilithtower_safe_house_toilet_1', skip = true})

	--생존자 (남) : 설마 중증 변비 환자에게 양보를 바라는 건 아니겠지?
	speech_bubble_util.show_speech_bubble_async(npc, {key = 'lilithtower_safe_house_toilet_2', skip = true})

	--생존자 (남) : 내가 나갈 때 까지 화장실 근처엔 얼씬도 하지 마!
	character_util.set_emotion(npc, {name = 'mad'})
	character_util.set_emotion(user_party.Leader, {name = 'surprise'})
	camera_util.shake(0.3, 0.3)
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	music_player_util.play_sfx_one_shot('01_count_final_01')
	speech_bubble_util.show_speech_bubble_async(npc,
			{key = 'lilithtower_safe_house_toilet_3', skip = true, scale = 1.1})
	character_util.remove_emotion(user_party.Leader)

	wp_util.move_way_points_async(user_party.Leader,
			{waypoints = reset_pos, speed = 3, last_direction = CS.Oak.Direction.Up})

	character_util.set_emotion(npc, {name = 'damaged'})
	character_util.shake(npc, 0.02, 99999)
	character_util.set_anim(npc, {name = 'cast', upper = true})

	self.current_toilet_state = self.toilet_state.none

	party_util.reset_controllers()
	field_ui_manager:Show()
end

--endregion

--- 라이트닝 카운터 세이프 하우스 세팅
function local_class:safe_house_oni_girl()
	local quest_progress = user_progress:GetStartedQuest(268)

	if quest_progress ~= nil and quest_progress.IsComplete then
		return
	end

	local npcs = {
		get_character('safe_house_onigirl'),
		get_character('safe_house_onigirl_npc_1'),
		get_character('safe_house_onigirl_npc_2')
	}

	for _, npc in pairs(npcs) do
		character_util.set_active_state(npc, 'disabled')
		npc.Position = vector(999, 0, 999)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	local princess = get_character(self.pricess_name)
	character_util.remove_relate_event(princess, self.cs_controller)

	if self.paper_item ~= nil then
		self.paper_item:ConsumeComplete()
		self.paper_item = nil
	end

	self.vent_mini_game = nil
	self.toilet_android_lua_table = nil
	self.toilet_android_origin_pos = nil

	self.saved_party = nil

	if self.cabinet_sfx ~= nil then
		self.cabinet_sfx:FadeOut()
		self.cabinet_sfx = nil
	end

	self.cs_controller = nil
end

function local_class:on_stage_end_event(e)
	self.is_recovery_hp = false
end

function local_class:on_exclusive_quest_start_event(e)
	if e.Key == self.detected_by_terrorist_key then
		self.is_recovery_hp = false
	end
end

function local_class:on_exclusive_quest_end_event(e)
	if not self.is_recovery_hp and e.Key == self.detected_by_terrorist_key then
		self.is_recovery_hp = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.recovery_hp, self))
	end
end

function local_class:on_battle_start_event(e)
	self.is_recovery_hp = false
end

function local_class:on_battle_end_event(e)
	if not self.is_recovery_hp then
		self.is_recovery_hp = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.recovery_hp, self))
	end
end

function local_class:recovery_hp()
	local current_time = 0
	local recovery_time = 5
	while self.is_recovery_hp do
		if user_party.Leader.FieldObjectStatsBehaviour.HpRatio >= 1.0 then
			return
		end

		if current_time <= recovery_time then
			current_time = current_time + unity_class.time.deltaTime
		else
			current_time = 0

			local heal_info = CS.Oak.HealInfo()
			heal_info.type = CS.Oak.HealType.Normal
			heal_info.heal = math.floor(user_party.Leader.CharacterStatsBehaviour.MaxHP * 0.01)
			heal_info.sender = user_party.Leader
			heal_info.target = user_party.Leader
			heal_info.skipEffect = true

			command_util.execute_heal(heal_info)
		end

		coroutine.yield(nil)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
