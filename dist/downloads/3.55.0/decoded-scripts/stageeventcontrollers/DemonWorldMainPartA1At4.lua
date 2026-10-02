local local_class = newclass("DemonWorldMainPartA1At4Controller")
demon_world_global_event = get_or_create_global_variable('utils/DemonWorldGlobalEvent')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'demonworld_part1_1_4'

	-- 커스텀 키
	self.custom_key = {
		appear_hidden_hole = 1,
		talk_with_barrel_girl = 2,
		get_pizza = 3,
		give_pizza = 4
	}

	-- 추모 NPC
	self.cherish_npc_list = nil

	-- 추모비 숨은 입구
	self.memorial_hidden_hole = nil

	-- 데모 이벤트
	self.demo_sfx = nil

	-- 화약통 펑크녀 이벤트
	self.barrel_punk_girl = nil
	self.event_barrel = nil

	-- 피자 주문 이벤트
	self.pizza_beggar = nil
	self.pizza_waitress = nil
	self.pizza_interactable = nil

	-- 아이들 이벤트
	self.block_kid_list = nil

	-- 알약 기계 소리
	self.pill_sfx = nil

	-- 게임 종료 플래그
	self.is_exit_stage = false

	-- 추모 이벤트 플래그
	self.see_memorial_event = false

	-- 화약통 펑크 여성과 대화 이벤트 플래그
	self.is_talk_with_barrel_girl = false

	-- 피자 거지 대화 플래그
	self.is_talk_with_pizza_beggar = false

	-- 안드로이드 발각 플래그
	self.is_detected = false

	-- 안드로이드 정찰 존 입장 플래그
	self.is_in_android_detector_zone = false

	-- 기타 상수
	self.main_quest_id = 216
	self.cherish_npc_num = 12
	self.demo_civilian_left_num = 6
	self.demo_civilian_right_num = 6
	self.block_kid_num = 2
	self.bug_controller_num = 6
	self.flower_item_id = 20376
	self.pizza_box_item_id = 20380
	self.pizza_item_id = 20377
	self.pizza_price = 50

	-- 캐릭터 이름
	self.cherish_npc_name = 'cherish_civilian_'
	self.demo_civilian_left_name = 'demo_civilian_left_'
	self.demo_civilian_right_name = 'demo_civilian_right_'
	self.barrel_punk_girl_name = 'barrel_girl'
	self.pizza_beggar_name = 'pizza_store_beggar'
	self.pizza_waitress_name = 'pizza_shop_assistant'
	self.block_kid_name = 'block_kid_'

	-- 필드오브젝트 이름
	self.memorial_stone_left_name = 'memorial_stone_left'
	self.memorial_stone_right_name = 'memorial_stone_right'
	self.memorial_bomb_damage_obj_name = 'memorial_bomb_damaged_obj'
	self.memorial_hidden_hole_name = 'memorial_stone_hole'
	self.barrel_name = 'punk_girl_barrel'
	self.pizza_interactable_name = 'pizza_shop_counter'
	self.bug_controller_name = 'bug_controller_'
	self.child_star_piece_name = 'child_star_piece'
	self.sealstone_name = 'sealstone'
	self.sealstone_damage_obj_name = 'sealstone_damaged_object'

	-- 존 이름
	self.memorial_event_zone_name = 'memorial_stone'
	self.android_detector_event_zone_name = 'android_detector'
	self.pill_machine_event_zone_name = 'pill_machine_zone'

	-- 마커 이름
	self.entry_hole_name = 'entry_hole'
	self.reset_marker_name = 'android_detector_reset_'

	-- 커스텀 이벤트 이름
	self.detected_by_android_1 = 'detected_by_android_1'
	self.detected_by_android_2 = 'detected_by_android_2'

	-- 보이스 분기용 테이블
	self.alt_android_table = {
		android_turing_detector_2 = 1,
		android_turing_detector_4 = 2
	}

	-- 커스텀 데이터 키
	self.dollar_data_key = 'dollar'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	self.cherish_npc_list = create_generic_list(CS.Oak.Character)
	for i = 1, self.cherish_npc_num do
		self.cherish_npc_list:Add(get_character(self.cherish_npc_name..i))
	end

	self.memorial_hidden_hole = get_field_object(self.memorial_hidden_hole_name)

	self.barrel_punk_girl = get_character(self.barrel_punk_girl_name)
	character_util.add_listener(self.barrel_punk_girl, self.cs_controller)

	self.event_barrel = get_field_object(self.barrel_name)

	self.pizza_beggar = get_character(self.pizza_beggar_name)
	character_util.add_listener(self.pizza_beggar, self.cs_controller)

	self.pizza_waitress = get_character(self.pizza_waitress_name)

	self.pizza_interactable = get_field_object(self.pizza_interactable_name)

	self.block_kid_list = create_generic_list(CS.Oak.Character)
	for i = 1, self.block_kid_num do
		self.block_kid_list:Add(get_character(self.block_kid_name..i))
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
		-- 'stage_item'
		)
	end

	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	yield_return_func(demon_world_dollar.load_resource, demon_world_dollar)
end

function local_class:need_on_launch()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local progress_list = {
		-1
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	self.is_exit_stage = true

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cherish_npc_list = nil
	self.block_kid_list = nil

	self.barrel_punk_girl = nil
	self.pizza_beggar = nil
	self.pizza_waitress = nil

	self.memorial_hidden_hole = nil
	self.event_barrel = nil
	self.pizza_interactable = nil

	if self.demo_sfx ~= nil then
		self.demo_sfx:FadeOut(0)
		self.demo_sfx = nil
	end

	if self.pill_sfx ~= nil then
		self.pill_sfx:FadeOut(0)
		self.pill_sfx = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.QuestProgressedEvent) then
		self:on_quest_progressed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	---- 메인 퀘스트 진행 상태에 따라 벌레 설정
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress > 10 then
		self:activate_bug(self.bug_controller_name..1, false)
		self:activate_bug(self.bug_controller_name..2, false)
	end

	if quest_progress.InnerProgress < 12 then
		self:activate_bug(self.bug_controller_name..3, false)
		self:activate_bug(self.bug_controller_name..4, false)
		self:activate_bug(self.bug_controller_name..5, false)
	end

	if quest_progress.InnerProgress > 12 then
		self:activate_bug(self.bug_controller_name..6, false)
	end
end

function local_class:on_stage_start_event(e)
	-- 숨겨진 구멍 설정
	if not stage_progress:GetCustomData(self.custom_key.appear_hidden_hole) then
		stage_util.set_fo_active_state(self.memorial_hidden_hole_name, 'disabled')
	else
		stage_util.set_fo_active_state(self.memorial_bomb_damage_obj_name, 'disabled')
	end

	-- 데모 이벤트 설정
	for i = 1, self.demo_civilian_left_num do
		local cur_civilian = get_character(self.demo_civilian_left_name..i)

		character_util.set_anim(cur_civilian, { name = 'strike_idle' })
		character_util.set_emotion(cur_civilian, { name = 'attack' })

		cur_civilian.SpineController:SetAttachment('[base]weapon1', 'succubus_picket')
	end

	for i = 1, self.demo_civilian_right_num do
		local cur_civilian = get_character(self.demo_civilian_right_name..i)

		local mod = i % 2

		if i ~= 1 then
			if mod == 0 then
				character_util.set_anim(cur_civilian, { name = 'cast2' })
			else
				character_util.set_anim(cur_civilian, { name = 'cross_arm' })
			end
		else
			character_util.set_anim(cur_civilian, { name = 'gauntlet_combo_attack' })
		end

		character_util.set_emotion(cur_civilian, { name = 'attack' })
	end

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress > 10 then
		self.demo_sfx = music_player_util.play_sfx(
				{ sfx_name = "01_crowd_buzz_01",
				  play_pos = get_character(self.demo_civilian_left_name..4).Position + vector(1.5, 0, 0),
				  loop = true, type_priority = 'loop' })
	end

	-- 추모비 주변에 꽃 설치
	local memorial_stone_left = get_field_object(self.memorial_stone_left_name)

	local angle = 0
	local add_angle = 40

	while angle < 360 do
		local rad = angle * unity_class.mathf.Deg2Rad

		drop_item_util.create_item({
			pos = memorial_stone_left.Position + vector(math.sin(rad), 0, math.cos(rad)) * 1.5,
			itemid = self.flower_item_id, notforinven = true, lootstate = 'dontfindlooter'
		})

		angle = angle + add_angle
	end

	local memorial_stone_right = get_field_object(self.memorial_stone_right_name)

	angle = 30
	add_angle = 35

	while angle < 360 do
		local rad = angle * unity_class.mathf.Deg2Rad

		drop_item_util.create_item({
			pos = memorial_stone_right.Position + vector(math.sin(rad), 0, math.cos(rad)) * 1.5,
			itemid = self.flower_item_id, notforinven = true, lootstate = 'dontfindlooter'
		})

		angle = angle + add_angle
	end

	-- 화약통 들고 있는 펑크 여성
	if not stage_progress:GetCustomData(self.custom_key.talk_with_barrel_girl) then
		character_util.set_anim(self.barrel_punk_girl, { name = 'cast2' })
		self.event_barrel.Position = self.barrel_punk_girl.Position + vector(0, 1.4, 0)
	else
		stage_util.set_fo_active_state(self.barrel_name, 'disabled')
	end

	-- 거지 앞에 피자 아이템 배치
	if stage_progress:GetCustomData(self.custom_key.give_pizza) then
		drop_item_util.create_item({ pos = self.pizza_beggar.Position + vector(0.5, 0, 0),
		                             itemid = self.pizza_item_id, sprscale = 0.7, notforinven = true,
		                             lootstate = 'dontfindlooter', })

		character_util.set_anim(self.pizza_beggar, { name = 'eat' })
		character_util.set_emotion(self.pizza_beggar, { name = 'greed' })
	else
		character_util.set_anim(self.pizza_beggar, { name = 'seat' })
	end

	-- 아이들 설정
	if quest_progress.InnerProgress > 11 then
		if not stage_progress:HasStarPiece(self.child_star_piece_name) then
			for i = 0, self.block_kid_list.Count - 1 do
				field_ui_manager:RemoveUI(self.block_kid_list[i], CS.Oak.FieldUiType.CharacterStats)

				self.block_kid_list[i].Interactable = CS.Oak.PublishInteractable.Create()
				character_util.shake(self.block_kid_list[i], 0.04, 9999)
			end

			character_util.set_position(self.block_kid_list[0], vector(105.4, 0, 221))
			character_util.set_direction(self.block_kid_list[0], 'down')

			character_util.set_position(self.block_kid_list[1], vector(107.5, 0, 221.6))
			character_util.set_direction(self.block_kid_list[1], 'down')
		else
			self.block_kid_list[0].Interactable.Talk = 'demonworld_part1_1_4_kid_10'
			self.block_kid_list[1].Interactable.Talk = 'demonworld_part1_1_4_kid_10_alt'
		end
	end

	-- 봉인석 비활성화
	stage_util.set_fo_active_state(self.sealstone_name, 'disabled')

	if quest_progress.InnerProgress > 12 then
		stage_util.set_fo_active_state(self.sealstone_damage_obj_name, 'disabled')
	end
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	if not e.FullEnter then return end

	if not self.see_memorial_event and e.Zone.Name == self.memorial_event_zone_name then
		self.see_memorial_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.memorial_event, self))
	elseif not self.is_in_android_detector_zone and e.Zone.Name == self.android_detector_event_zone_name then
		self.is_in_android_detector_zone = true

		music_player_util.play_sfx({ sfx_name = '01_bugs_oneshot_01', volume = 0.5 })
	elseif e.Zone.Name == self.pill_machine_event_zone_name then
		if self.pill_sfx == nil then
			self.pill_sfx = music_player_util.play_sfx(
					{ sfx_name = "01_aircraft_loop_01", loop = true, type_priority = 'loop' })
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	if not e.FullLeave then return end

	if self.see_memorial_event and e.Zone.Name == self.memorial_event_zone_name then
		self.see_memorial_event = false
	elseif e.Zone.Name == self.pill_machine_event_zone_name then
		if self.pill_sfx ~= nil then
			self.pill_sfx:FadeOut(1)
		end
	end
end

function local_class:on_interact_event(e)
	-- 일반적인 상황에선 발생이 불가능하지만 디버그 상황 고려해서 메인 퀘스트 InnerProgress가 10 이하면 실행 X
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress <= 10 then
		return
	end

	if lua_helper.reference_equals(e.Target, self.memorial_hidden_hole) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_down_hole, self))
	elseif lua_helper.reference_equals(e.Target, self.barrel_punk_girl) then
		if not stage_progress:GetCustomData(self.custom_key.talk_with_barrel_girl) then
			sp_util.play_normal_screenplay(self.talk_with_barrel_girl, self)
		else
			sp_util.play_normal_screenplay(self.talk_with_barrel_girl_skip, self)
		end
	elseif lua_helper.reference_equals(e.Target, self.pizza_beggar) then
		if not stage_progress:GetCustomData(self.custom_key.give_pizza) then
			if not stage_progress:GetCustomData(self.custom_key.get_pizza) then
				if not self.is_talk_with_pizza_beggar then
					self.is_talk_with_pizza_beggar = true

					sp_util.play_normal_screenplay(self.talk_with_pizza_beggar, self)
				else
					speech_bubble_util.show_speech_bubble(
							self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_6' })
				end
			else
				if not self.is_talk_with_pizza_beggar then
					self.is_talk_with_pizza_beggar = true

					sp_util.play_normal_screenplay(self.talk_with_pizza_beggar, self)
				else
					sp_util.play_normal_screenplay(self.give_pizza, self)
				end
			end
		else
			speech_bubble_util.show_speech_bubble(self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_12' })
		end
	elseif lua_helper.reference_equals(e.Target, self.pizza_interactable) then
		if not stage_progress:GetCustomData(self.custom_key.get_pizza) then
			sp_util.play_normal_screenplay(self.interact_with_pizza_counter, self)
		else
			speech_bubble_util.show_speech_bubble(self.pizza_waitress, { key = 'demonworld_part1_1_4_pizza_6', bubble_direction = 'rb' })
		end
	end

	for i = 0, self.block_kid_list.Count - 1 do
		if lua_helper.reference_equals(e.Target, self.block_kid_list[i]) then
			sp_util.play_normal_screenplay(self.find_children_event, self)

			break
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if not stage_progress:GetCustomData(self.custom_key.appear_hidden_hole) then
		local memorial_bomb_damaged_obj = get_field_object(self.memorial_bomb_damage_obj_name)

		if lua_helper.reference_equals(e.FieldObject, memorial_bomb_damaged_obj) then
			stage_util.set_fo_active_state(self.memorial_hidden_hole_name, 'enabled')

			stage_progress:SendCustomData(self.custom_key.appear_hidden_hole, true)
		end
	end
end

function local_class:on_quest_progressed_event(e)
	-- 섹션 12로 넘어왔을 때
	if e.QuestId == self.main_quest_id and e.CurrentProgress == 11 then
		self.demo_sfx = music_player_util.play_sfx({ sfx_name = "01_crowd_buzz_01",
		                                             parent = get_character(self.demo_civilian_left_name..4),
		                                             loop = true, type_priority = 'loop' })
	-- 섹션 13으로 넘어왔을 때
	elseif e.QuestId == self.main_quest_id and e.CurrentProgress == 12 then
		for i = 0, self.block_kid_list.Count - 1 do
			field_ui_manager:RemoveUI(self.block_kid_list[i], CS.Oak.FieldUiType.CharacterStats)
			self.block_kid_list[i].Interactable = CS.Oak.PublishInteractable.Create()

			character_util.shake(self.block_kid_list[i], 0.04, 9999)
		end

		character_util.set_position(self.block_kid_list[0], vector(105.4, 0, 221))
		character_util.set_direction(self.block_kid_list[0], 'down')

		character_util.set_position(self.block_kid_list[1], vector(107.5, 0, 221.6))
		character_util.set_direction(self.block_kid_list[1], 'down')
	end
end

function local_class:on_custom_stage_event(e)
	if not self.is_detected then
		if e:GetParamAt(0) == self.detected_by_android_1 then
			sp_util.play_normal_screenplay(self.detected_by_android_event, self, e.Sender, self.detected_by_android_1)
		elseif e:GetParamAt(0) == self.detected_by_android_2 then
			sp_util.play_normal_screenplay(self.detected_by_android_event, self, e.Sender, self.detected_by_android_2)
		end
	end
end

-- 벌레 FieldObject 켜고 끄기
function local_class:activate_bug(name, is_active)
	local cur_field_object_behaviour = get_field_object(name).FieldObjectBehaviour:GetLuaTable()

	cur_field_object_behaviour:set_active(is_active)
end

-- 추모 이벤트
function local_class:memorial_event()
	local left_memorial_civilian_list = {}

	for i = 1, 5 do
		base_anim = 'cast'

		if i == 5 then
			base_anim = 'sing'
		end

		left_memorial_civilian_list[i] = {
			character = self.cherish_npc_list[i],
			base_anim = base_anim
		}
	end

	local right_memorial_civilian_list = {}

	for i = 7, 11 do
		base_anim = 'cast'

		if i == 11 then
			base_anim = 'sing'
		end

		right_memorial_civilian_list[i - 6] = {
			character = self.cherish_npc_list[i],
			base_anim = base_anim
		}
	end

	music_player_util.play_sfx_one_shot('01_female_cry_02')

	local delay_base = 2
	local delay_rand_max = 0.5

	local timer = delay_base
	local cur_delay = delay_base + unity_class.random.Range(-delay_rand_max, delay_rand_max)

	local is_left = true

	while not self.is_exit_stage and self.see_memorial_event do
		timer = timer + unity_class.time.deltaTime

		if timer >= cur_delay then
			timer = 0

			cur_delay = delay_base + unity_class.random.Range(-delay_rand_max, delay_rand_max)

			if not is_left then
				local index = math.floor(unity_class.random.Range(1, #right_memorial_civilian_list + 1))

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.throw_flower, self, right_memorial_civilian_list[index].character,
								right_memorial_civilian_list[index].base_anim, false))
			else
				local index = math.floor(unity_class.random.Range(1, #left_memorial_civilian_list + 1))

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.throw_flower, self, left_memorial_civilian_list[index].character,
								left_memorial_civilian_list[index].base_anim, true))
			end

			if is_left then
				is_left = false
			else
				is_left = true
			end
		end

		coroutine.yield(nil)
	end

	if self.is_exit_stage then
		return
	end

	for i = 1, #left_memorial_civilian_list do
		character_util.set_anim(left_memorial_civilian_list[i].character,
				{ name = left_memorial_civilian_list[i].next_anim })
	end

	for i = 1, #right_memorial_civilian_list do
		character_util.set_anim(right_memorial_civilian_list[i].character,
				{ name = right_memorial_civilian_list[i].next_anim })
	end
end

-- NPC가 추모비 근처에 꽃 던지는 이벤트
function local_class:throw_flower(npc, next_anim, is_left)
	local memorial_stone_left = get_field_object(self.memorial_stone_left_name)
	local memorial_stone_right = get_field_object(self.memorial_stone_right_name)

	character_util.set_anim(npc,
			{ name = 'throw', loop = false, sfx_name = '01_swing_01', next_anim = next_anim })

	local target_pos

	if is_left then
		local dir = (npc.Position - memorial_stone_left.Position).normalized * 1.5
		target_pos = memorial_stone_left.Position + dir
	else
		local dir = (npc.Position - memorial_stone_right.Position).normalized * 1.5
		target_pos = memorial_stone_right.Position + dir
	end

	local flower = drop_item_util.create_item({ pos = npc.Position,
	                                            target = target_pos,
	                                            itemid = self.flower_item_id, notforinven = true,
	                                            lootstate = 'dontfindlooter' })
	flower:SetSortingLayer(true)

	wait_for_sec(2)

	drop_item_util.alpha_fade_async(flower, 0, 1)
end

-- 구멍 아래로 떨어지는 이벤트
function local_class:fall_down_hole()
	party_util.stop_and_disable_control()

	local fall_down_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_fall_down_01', type_priority = 'event', player_priority = 'npc' })

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	local move_duration = 0.5

	character_util.jump(user_party_leader, 1, move_duration)
	character_util.set_anim(user_party_leader, { name = 'get' })
	character_util.move_to(user_party_leader, self.memorial_hidden_hole.Position + vector(0, 0, -0.3),
			move_duration, nil, false, false)

	wait_for_unscaled_sec(move_duration)

	user_party_leader.SpineController:Scale(unity_class.vector3.zero, 0.3)

	screen_util.fade_out_circular_async(0.5, 'linear')

	fall_down_sfx:FadeOut(0)

	-- 플레이어 위치 설정
	local target_marker = field:GetMarker(self.entry_hole_name)

	user_party_leader.SpineController:Scale(unity_class.vector3.one, 0)

	for i = 0, user_party.Count - 1 do
		user_party[i].Position = target_marker.position + vector(0, 10, 0) -
				CS.Oak.DirectionExtensions.ToVector3(target_marker.direction) * CS.Oak.Constants.DistBetweenPartyMembers * i
		character_util.set_direction(user_party[i], target_marker.direction)
		character_util.remove_anim(user_party[i])
	end

	wait_for_unscaled_sec(0.6)

	camera_util.move_async(target_marker.position, 0)

	screen_util.fade_in_circular_async(0.6, 'linear')

	for i = 0, user_party.Count - 1 do
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.free_fall_with_bounce, self, user_party[i]))

		wait_for_sec(0.2)
	end

	wait_for_sec(1.7)

	stage_camera:SetTarget(user_party_leader)

	party_util.reset_controllers()
end

-- 캐릭터 자유낙하 + 바운스 연출
function local_class:free_fall_with_bounce(target)
	character_util.set_anim(target, { name = 'embarrassed' })
	character_util.set_emotion(target, { name = 'damaged' })

	local free_fall = CS.CalculatorFreeFall(1, target.Position.y, 3)
	local end_pos = vector(target.Position.x, 0, target.Position.z)
	local is_bounce = false
	local bounce_num = 0

	while not free_fall:IsDone() do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance()

		if not is_bounce and cur_y < 0 then
			target.Position = vector(end_pos.x, 10 + cur_y, end_pos.z)
		else
			if not is_bounce then
				is_bounce = true
			end

			target.Position = vector(end_pos.x, cur_y, end_pos.z)
		end

		if bounce_num < free_fall:NumBounced() then
			bounce_num = bounce_num + 1

			music_player_util.play_sfx(
					{ sfx_name = '01_land_01', type_priority = 'event', player_priority = 'object' })
		end

		coroutine.yield(nil)
	end

	target.Position = end_pos
	character_util.remove_anim(target)
	character_util.remove_emotion(target)
end

-- 통 주는 펑크 여자 대화 이벤트
function local_class:talk_with_barrel_girl()
	party_util.align_party(self.barrel_punk_girl.Position + vector(1, 0, 0), 'right', 1)

	if not self.is_talk_with_barrel_girl then
		self.is_talk_with_barrel_girl = true

		character_util.set_emotion(self.barrel_punk_girl, { name = 'attack' })

		speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
				{ key = 'demonworld_part1_1_4_barrel_1', skip = true })

		music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')

		character_util.set_emotion(self.barrel_punk_girl, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
				{ key = 'demonworld_part1_1_4_barrel_2', skip = true })

		music_player_util.play_sfx_one_shot('03_runaway_01')

		character_util.shake(self.barrel_punk_girl, 0.04, 9999)
		character_util.set_emotion(self.barrel_punk_girl, { name = 'scared' })

		speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
				{ key = 'demonworld_part1_1_4_barrel_3', skip = true })

		speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
				{ key = 'demonworld_part1_1_4_barrel_4', skip = true })

		character_util.stop_shake(self.barrel_punk_girl)
		character_util.remove_emotion(self.barrel_punk_girl)
	end

	speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
			{ key = 'demonworld_part1_1_4_barrel_5', skip = true })

	local choose_result = choose_util.play_choose_event(
			{ { 'demonworld_part1_1_4_barrel_6', 'mercy' }, { 'demonworld_part1_1_4_barrel_7', 'brutal' } })

	if choose_result == 1 then
		character_util.set_emotion(self.barrel_punk_girl, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
				{ key = 'demonworld_part1_1_4_barrel_8', skip = true })

		character_util.remove_emotion(self.barrel_punk_girl)

		coroutine.yield(self:give_barrel())

		stage_progress:SendCustomData(self.custom_key.talk_with_barrel_girl, true)
	end
end

-- 통 주는 펑크 여자 대화 이벤트 스킵
function local_class:talk_with_barrel_girl_skip()
	party_util.align_party(self.barrel_punk_girl.Position + vector(1, 0, 0), 'right', 1)

	speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
			{ key = 'demonworld_part1_1_4_barrel_9', skip = true })

	local choose_result = choose_util.play_choose_event(
			{ { 'demonworld_part1_1_4_barrel_6', 'mercy' }, { 'demonworld_part1_1_4_barrel_7', 'brutal' } })

	if choose_result == 1 then
		if self.event_barrel.ActiveState == active_state('enabled') then
			music_player_util.play_sfx_one_shot('03_dialogue_negative_02')

			character_util.set_emotion(self.barrel_punk_girl, { name = 'attack' })

			speech_bubble_util.show_speech_bubble_async(self.barrel_punk_girl,
					{ key = 'demonworld_part1_1_4_barrel_10', skip = true })

			character_util.remove_emotion(self.barrel_punk_girl)
		else
			coroutine.yield(self:give_barrel())
		end
	end
end

-- 화약통 주기
function local_class:give_barrel()
	local timer = 0
	local scale_time = 0.5
	local hold_down_time = 0.2

	character_util.set_anim(self.barrel_punk_girl, { name = 'hold_loop' })
	character_util.set_emotion(self.barrel_punk_girl, { name = 'smile' })

	wait_for_sec(0.1)

	if self.event_barrel.ActiveState ~= active_state('enabled') then
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = self.barrel_punk_girl
		heal_info.target = self.event_barrel
		heal_info.heal = self.event_barrel.FieldObjectStatsBehaviour.MaxHP
		heal_info.isRevive = true

		command_util.execute_heal(heal_info)

		self.event_barrel.Position = self.barrel_punk_girl.Position + unity_class.vector3.up * 1.4

		music_player_util.play_sfx_one_shot('02_bomb_respawn_01')

		while timer < scale_time do
			local progress = unity_class.mathf.Clamp01(timer / scale_time)

			self.event_barrel.Transform.localScale = unity_class.vector3.one * progress

			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		self.event_barrel.Transform.localScale = unity_class.vector3.one
	end

	character_util.set_anim(self.barrel_punk_girl,
			{ name = 'throw', loop = false, next_anim = 'idle', sfx_name = '01_swing_01' })

	timer = 0

	local start_pos = self.event_barrel.Position
	local end_pos = self.barrel_punk_girl.Position +
			CS.Oak.DirectionExtensions.ToVector3(self.barrel_punk_girl.Direction) * 0.9

	while timer < hold_down_time do
		local progress = unity_class.mathf.Clamp01(timer / hold_down_time)

		self.event_barrel.Position = start_pos * (1 - progress) + end_pos * progress

		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	self.event_barrel.Position = end_pos

	character_util.remove_emotion(self.barrel_punk_girl)
end

-- 피자 거지와 대화
function local_class:talk_with_pizza_beggar()
	party_util.align_party(self.pizza_beggar.Position, 'right', 1)

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_1', skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.set_anim(self.pizza_beggar, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.pizza_beggar, { name = 'doyagao' })

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_2', skip = true })

	character_util.set_anim(self.pizza_beggar, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_3', skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.set_direction(self.pizza_beggar, 'left')
	character_util.remove_anim(self.pizza_beggar)

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_4', skip = true })

	character_util.set_direction(self.pizza_beggar, 'right')
	character_util.set_anim(self.pizza_beggar, { name = 'cast2' })

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_5', skip = true })

	character_util.set_anim(self.pizza_beggar, { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_6', skip = true })

	character_util.set_anim(self.pizza_beggar, { name = 'seat' })
	character_util.remove_emotion(self.pizza_beggar)
end

-- 거지에게 피자 주는 이벤트
function local_class:give_pizza()
	party_util.align_party(self.pizza_beggar.Position, 'right', 1)

	local choose_result = choose_util.play_choose_event(
			{ { 'demonworld_part1_1_4_beggar_7', 'mercy' }, { 'demonworld_part1_1_4_beggar_8', 'brutal' } })

	if choose_result == 1 then
		character_util.set_anim(user_party_leader,
				{ name = 'throw', loop = false, sfx_name = '01_swing_01' })

		local pizza = drop_item_util.create_item({ pos = user_party_leader.Position, itemid = self.pizza_item_id,
		                                           notforinven = true,
		                                           lootstate = 'dontfindlooter', sprscale = 0.7 })

		local duration = 0.3
		local timer = 0

		local start_pos = user_party_leader.Position
		local end_pos = self.pizza_beggar.Position + vector(0.5, 0, 0)

		while timer < duration do
			local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, timer / duration)
			local cur_y = (duration * timer - timer * timer) * 20

			pizza.Position = cur_pos + vector(0, cur_y, 0)

			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		pizza.Position = end_pos

		wait_for_sec(0.2)

		character_util.remove_anim(user_party_leader)

		wait_for_sec(0.3)

		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		music_player_util.play_sfx_one_shot('01_player_jump_01')

		character_util.jump(self.pizza_beggar, 1, 0.5)
		character_util.set_anim(self.pizza_beggar, { name = 'cast2' })
		character_util.set_emotion(self.pizza_beggar, { name = 'greed' })

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_9', skip = true })

		local eat_sfx = music_player_util.play_sfx({ sfx_name = "01_eat_01",
		                             parent = self.pizza_beggar,
		                             loop = true, type_priority = 'loop' })

		character_util.set_anim(self.pizza_beggar, { name = 'eat' })

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_10', skip = true })

		wait_for_sec(1)

		eat_sfx:FadeOut(1)

		character_util.remove_anim(self.pizza_beggar)
		character_util.remove_emotion(self.pizza_beggar)

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_11', skip = true })

		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_12', skip = true })

		character_util.set_anim(self.pizza_beggar, { name = 'release', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_13', skip = true })

		character_util.set_anim(self.pizza_beggar, { name = 'cross_arm' })
		character_util.set_emotion(self.pizza_beggar, { name = 'doyagao' })

		speech_bubble_util.show_speech_bubble_async(
				self.pizza_beggar, { key = 'demonworld_part1_1_4_beggar_14', skip = true })

		character_util.set_anim(self.pizza_beggar, { name = 'eat' })
		character_util.set_emotion(self.pizza_beggar, { name = 'greed' })

		stage_progress:SendCustomData(self.custom_key.give_pizza, true)
	end
end

-- 피자 주문
function local_class:interact_with_pizza_counter()
	party_util.align_party(self.pizza_interactable.Position, 'down', 1, 'arc')

	music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')

	character_util.set_anim(self.pizza_waitress, { name = 'sing' })
	character_util.set_emotion(self.pizza_waitress, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(
			self.pizza_waitress, { key = 'demonworld_part1_1_4_pizza_1', skip = true })

	character_util.remove_anim(self.pizza_waitress)

	local choose_result = choose_util.play_choose_event(
			{ { 'demonworld_part1_1_4_pizza_2', 'mercy' }, { 'demonworld_part1_1_4_pizza_3', 'brutal' } })

	if choose_result == 1 then
		local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
		if demon_world_dollar:get_dollar() >= self.pizza_price then
			demon_world_dollar:remove_dollar(self.pizza_price)

			music_player_util.play_sfx_one_shot('01_air_spin_02')

			character_util.set_anim(self.pizza_waitress,
					{ name = 'throw', loop = false, sfx_name = '01_swing_01', next_anim = 'clap' })

			drop_item_util.create_item({ pos = self.pizza_waitress.Position,
			                             target = user_party_leader.Position,
			                             itemid = self.pizza_box_item_id, notforinven = true })

			wait_for_sec(1)

			music_player_util.play_sfx_one_shot('01_clap_02')
			music_player_util.play_sfx_one_shot('03_dialogue_positive_01')

			speech_bubble_util.show_speech_bubble_async(
					self.pizza_waitress, { key = 'demonworld_part1_1_4_pizza_4', skip = true })

			stage_progress:SendCustomData(self.custom_key.get_pizza, true)
		else
			character_util.set_anim(self.pizza_waitress, { name = 'bomb_idle' })
			character_util.set_emotion(self.pizza_waitress, { name = 'tired' })

			speech_bubble_util.show_speech_bubble_async(
					self.pizza_waitress, { key = 'demonworld_part1_1_4_pizza_5', skip = true })
		end
	end

	character_util.remove_anim(self.pizza_waitress)
	character_util.remove_emotion(self.pizza_waitress)
end

-- 안드로이드에게 발각된 이벤트
function local_class:detected_by_android_event(detector, event_name)
	character_util.set_immortal(user_party_leader, true)

	self.is_detected = true

	local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

	field:Tint("alert_max", unity_class.color(1, 0, 0), 0.25)

	camera_util.shake(0.07, 0.25)

	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

	for i = 0, user_party.Count - 1 do
		character_util.set_anim(user_party[i], { name = "embarrassed" })
		character_util.set_emotion(user_party[i], { name = "surprise" })
		character_util.jump(user_party[i], 0.3, 0.2)
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	character_util.set_anim(detector, { name = "attack" })

	if self.alt_android_table[detector.Name] ~= nil then
		speech_bubble_util.show_speech_bubble_async(detector,
				{ key = "demonworld_part1_s13_1", skip = "true", bubble_type = "shout", override_key = 'demonworld_part1_s13_1_alt' })
	else
		speech_bubble_util.show_speech_bubble_async(detector,
				{ key = "demonworld_part1_s13_1", skip = "true", bubble_type = "shout" })
	end

	wait_for_sec(0.25)

	music_player_util.play_sfx({ sfx_name = '01_drown_01', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_circular(0.5, 'linear')

	wait_for_sec(1.0)

	-- 경비병들 리셋
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { 'reset', event_name }))

	character_util.remove_anim(detector)
	character_util.remove_emotion(detector)

	siren:FadeOut(0.5)

	field:RemoveTint("alert_max", 0)

	local respawn_marker

	if event_name == self.detected_by_android_1 then
		respawn_marker = field:GetMarker(self.reset_marker_name..1)
	else
		respawn_marker = field:GetMarker(self.reset_marker_name..2)
	end

	party_util.align_party(respawn_marker.position + CS.Oak.DirectionExtensions.ToVector3(
			CS.Oak.DirectionExtensions.GetOpposite(respawn_marker.direction)),
			CS.Oak.DirectionExtensions.GetOpposite(respawn_marker.direction), 0, 'arc')

	for i = 0, user_party.Count - 1 do
		character_util.set_direction(user_party[i], respawn_marker.direction)
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
	end

	wait_for_sec(0.5)

	screen_util.fade_in_circular(0.5, 'linear')

	wait_for_sec(0.5)

	character_util.set_immortal(user_party_leader, false)

	self.is_detected = false
end

-- 아이들 찾아낸 이벤트
function local_class:find_children_event()
	party_util.align_party(vector(107, 0, 219), 'down', 1, 'arc')

	camera_util.move_async(vector(107, 0, 220), 1)

	music_player_util.play_sfx_one_shot('03_runaway_01')

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.remove_relate_event(self.block_kid_list[i], self.cs_controller)
		character_util.jump(self.block_kid_list[i], 0.5, 0.3)
		character_util.set_anim(self.block_kid_list[i], { name = 'embarrassed' })
		character_util.set_emotion(self.block_kid_list[i], { name = 'scared' })
	end

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[1], { key = 'demonworld_part1_1_4_kid_1', bubble_type = 'shout', skip = true })

	wait_for_sec(1)

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.stop_shake(self.block_kid_list[i])
	end

	character_util.show_emoticon(self.block_kid_list[0], nil, 'question')
	character_util.show_emoticon_async(self.block_kid_list[1], nil, 'question')

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.set_anim(self.block_kid_list[i], { name = 'cast' })
		character_util.set_emotion(self.block_kid_list[i], { name = 'tired' })
	end

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[1], { key = 'demonworld_part1_1_4_kid_2', skip = true })

	camera_util.move(vector(107, 0, 218), 1.5)

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.remove_anim(self.block_kid_list[i])
	end

	local waypoint_list_1 = create_generic_list(unity_class.vector3)
	waypoint_list_1:Add(self.block_kid_list[0].Position + vector(-0.9, 0, 0))
	waypoint_list_1:Add(self.block_kid_list[0].Position + vector(-0.9, 0, -3))
	waypoint_list_1:Add(self.block_kid_list[0].Position + vector(1.1, 0, -3))

	character_util.move_waypoint(self.block_kid_list[0], waypoint_list_1,
			3, false, 'stop', 'floor', 'down')

	local waypoint_list_2 = create_generic_list(unity_class.vector3)
	waypoint_list_2:Add(self.block_kid_list[1].Position + vector(0, 0, -0.6))
	waypoint_list_2:Add(self.block_kid_list[1].Position + vector(2, 0, -0.6))
	waypoint_list_2:Add(self.block_kid_list[1].Position + vector(2, 0, -3.6))
	waypoint_list_2:Add(self.block_kid_list[1].Position + vector(0, 0, -3.6))

	character_util.move_waypoint(self.block_kid_list[1], waypoint_list_2,
			3, false, 'stop', 'floor', 'down')

	wait_for_sec(1)

	for i = 0, user_party.Count - 1 do
		character_util.move_to(user_party[i], user_party[i].Position + vector(0, 0, -1),
				1, nil, false, true)
	end

	while self.block_kid_list[1].CharacterBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped do
		coroutine.yield(nil)
	end

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[0], { key = 'demonworld_part1_1_4_kid_3', skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')

	character_util.set_direction(self.block_kid_list[1], 'up')

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[1], { key = 'demonworld_part1_1_4_kid_4', skip = true })

	music_player_util.play_sfx_one_shot('03_runaway_01')

	character_util.shake(self.block_kid_list[0], 0.04, 1)
	character_util.set_emotion(self.block_kid_list[0], { name = 'scared' })

	character_util.set_direction(self.block_kid_list[1], 'down')

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[0], { key = 'demonworld_part1_1_4_kid_5', skip = true })

	music_player_util.play_sfx_one_shot('01_small_jump_01')

	character_util.jump(self.block_kid_list[0], 1, 0.5)
	character_util.remove_emotion(self.block_kid_list[0])

	if user_util.has_knight_male() then
		speech_bubble_util.show_speech_bubble_async(
				self.block_kid_list[0], { key = 'demonworld_part1_1_4_kid_6', skip = true })
	else
		speech_bubble_util.show_speech_bubble_async(
				self.block_kid_list[0], { key = 'demonworld_part1_1_4_kid_7', skip = true })
	end

	character_util.remove_emotion(self.block_kid_list[0])

	character_util.set_anim(self.block_kid_list[1], { name = 'cast2' })
	character_util.remove_emotion(self.block_kid_list[1])

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[1], { key = 'demonworld_part1_1_4_kid_8', skip = true })

	character_util.set_anim(self.block_kid_list[0], { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(
			self.block_kid_list[0], { key = 'demonworld_part1_1_4_kid_9', skip = true })

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.set_anim(self.block_kid_list[i], { name = 'cast2' })
	end

	local star_piece = get_field_object(self.child_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(
			self.block_kid_list[0].Position + vector(0.5, 0, 0), false))

	wait_for_sec(1.5)

	for i = 0, self.block_kid_list.Count - 1 do
		character_util.remove_anim(self.block_kid_list[i])
		character_util.remove_emotion(self.block_kid_list[i])
		self.block_kid_list[i].CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		self.block_kid_list[i].Interactable = CS.Oak.NPCInteractable.Create()
	end

	self.block_kid_list[0].Interactable.Talk = 'demonworld_part1_1_4_kid_10'
	self.block_kid_list[1].Interactable.Talk = 'demonworld_part1_1_4_kid_10_alt'

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
