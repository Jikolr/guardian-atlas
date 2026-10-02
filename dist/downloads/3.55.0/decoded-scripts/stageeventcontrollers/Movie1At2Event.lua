local local_class = newclass("Movie1At2EventController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스타피스 표지판
	self.starpiece_board_list = {}
	self.starpiece_board_name = 'movie_starpiece_board_'
	self.starpiece_board_num = 12

	-- 프로포즈 스타피스
	self.propose_starpiece_name = 'movie_propose_starpiece'

	-- 실패한 프로포즈
	self.saw_propose = false
	self.couple_woman_name = 'couple1'
	self.couple_man_name = 'couple2'

	self.propose_coroutine = nil

	self.couple_man_loop = true
	self.couple_man_begin = false
	self.couple_woman_begin = false

	self.board_talk_1 = 'movie_2_board_talk_1'

	self.woman_talk_1 = 'movie_2_propose_woman_1'
	self.woman_talk_2 = 'movie_2_propose_woman_2'
	self.woman_talk_3 = 'movie_2_propose_woman_3'

	self.man_talk_1 = 'movie_2_propose_man_1'
	self.man_talk_2 = 'movie_2_propose_man_2'
	self.man_talk_3 = 'movie_2_propose_man_3'
	self.man_talk_4 = 'movie_2_propose_man_4'
	self.man_talk_5 = 'movie_2_propose_man_5'
	self.man_talk_6 = 'movie_2_propose_man_6'
	self.man_talk_7 = 'movie_2_propose_man_7'
	self.man_talk_8 = 'movie_2_propose_man_8'
	self.man_talk_9 = 'movie_2_propose_man_9'
	self.man_talk_10 = 'movie_2_propose_man_10'
	self.man_talk_11 = 'movie_2_propose_man_11'
	self.man_talk_12 = 'movie_2_propose_man_12'

	-- 영화촬영 스타피스
	self.shooting_starpiece_name = 'movie_shooting_starpiece'
	-- 영화촬영?
	self.saw_movie_shooting = false
	self.battle_start = false

	self.interact_count = 1

	self.blackguard1_name = 'blackguard1'
	self.blackguard2_name = 'blackguard2'
	self.blackguard3_name = 'blackguard3'
	self.blackguard4_name = 'blackguard4'
	self.blackguard5_name = 'blackguard5'
	self.food_truck_npc_name = 'food3'
	self.store_name = 'mv2_store'

	self.blackguard_talk_1 = 'movie_2_blackguard_talk_1'
	self.blackguard_talk_2 = 'movie_2_blackguard_talk_2'
	self.blackguard_talk_3 = 'movie_2_blackguard_talk_3'
	self.blackguard_talk_4 = 'movie_2_blackguard_talk_4'
	self.blackguard_talk_5 = 'movie_2_blackguard_talk_5'
	self.blackguard_talk_6 = 'movie_2_blackguard_talk_6'
	self.blackguard_talk_7 = 'movie_2_blackguard_talk_7'
	self.blackguard_talk_8 = 'movie_2_blackguard_talk_8'
	self.blackguard_talk_9 = 'movie_2_blackguard_talk_9'
	self.blackguard_talk_10 = 'movie_2_blackguard_talk_10'
	self.blackguard_talk_11 = 'movie_2_blackguard_talk_11'
	self.blackguard_talk_12 = 'movie_2_blackguard_talk_12'
	self.blackguard_talk_13 = 'movie_2_blackguard_talk_13'
	self.blackguard_talk_14 = 'movie_2_blackguard_talk_14'
	self.blackguard_talk_15 = 'movie_2_blackguard_talk_15'
	self.blackguard_talk_16 = 'movie_2_blackguard_talk_16'

	self.food_truck_npc_talk_1 = 'movie_2_food_npc_talk_1'
	self.food_truck_npc_talk_2 = 'movie_2_food_npc_talk_2'
	self.food_truck_npc_talk_3 = 'movie_2_food_npc_talk_3'
	self.food_truck_npc_talk_4 = 'movie_2_food_npc_talk_4'

	self.blackguard_branch_1 = 'movie_2_blackguard_branch_1'
	self.blackguard_branch_2 = 'movie_2_blackguard_branch_2'
	self.blackguard_branch_3 = 'movie_2_blackguard_branch_3'
	self.blackguard_branch_4 = 'movie_2_blackguard_branch_4'
	self.blackguard_branch_5 = 'movie_2_blackguard_branch_5'
	self.blackguard_branch_6 = 'movie_2_blackguard_branch_6'
	self.blackguard_branch_7 = 'movie_2_blackguard_branch_7'

	-- 사생팬의 부탁
	self.donate_npc_name = 'donate'
	self.request_fan_zone_name = 'section_2_5'
	self.donate_zone_name = 'section_2_6'
	self.donate_zone_in = false

	self.donate_npc_talk_1 = 'movie_2_donate_npc_talk_1'
	self.donate_npc_talk_2 = 'movie_2_donate_npc_talk_2'
	self.donate_npc_talk_3 = 'movie_2_donate_npc_talk_3'
	self.donate_npc_talk_4 = 'movie_2_donate_npc_talk_4'
	self.donate_npc_talk_5 = 'movie_2_donate_npc_talk_5'
	self.donate_npc_talk_6 = 'movie_2_donate_npc_talk_6'
	self.donate_npc_talk_7 = 'movie_2_donate_npc_talk_7'
	self.donate_npc_talk_8 = 'movie_2_donate_npc_talk_8'

	self.donate_branch_1 = 'movie_2_donate_branch_1'
	self.donate_branch_2 = 'movie_2_donate_branch_2'

	self.request_star_piece_name = 'movie_request_fan_starpiece'

	self.saw_request_fan = false

	self.request_fan_first = false

	self.request_success_1 = false
	self.request_success_2 = false
	self.request_success_3 = false

	self.get_sign_item = false
	self.get_rifle_item = false
	self.get_handkerchief_item = false

	self.sign_drop_item_name = 'sign_drop_item'
	self.rifle_drop_item_name = 'rifle_drop_item'
	self.handkerchief_drop_item_name = 'handkerchief_drop_item'

	self.sign_item_name = 'movie_2_sign_item_name_1'
	self.rifle_item_name = 'movie_2_rifle_item_name_1'
	self.handkerchief_item_name = 'movie_2_handkerchief_item_name_1'

	self.request_fan1_name = 'fan1'
	self.request_fan2_name = 'fan2'
	self.request_fan3_name = 'fan3'

	self.request_fan_talk_1 = 'movie_2_request_fan_talk_1'
	self.request_fan_talk_2 = 'movie_2_request_fan_talk_2'
	self.request_fan_talk_3 = 'movie_2_request_fan_talk_3'
	self.request_fan_talk_4 = 'movie_2_request_fan_talk_4'
	self.request_fan_talk_5 = 'movie_2_request_fan_talk_5'
	self.request_fan_talk_6 = 'movie_2_request_fan_talk_6'
	self.request_fan_talk_7 = 'movie_2_request_fan_talk_7'
	self.request_fan_talk_8 = 'movie_2_request_fan_talk_8'
	self.request_fan_talk_9 = 'movie_2_request_fan_talk_9'
	self.request_fan_talk_10 = 'movie_2_request_fan_talk_10'
	self.request_fan_talk_11 = 'movie_2_request_fan_talk_11'
	self.request_fan_talk_12 = 'movie_2_request_fan_talk_12'
	self.request_fan_talk_13 = 'movie_2_request_fan_talk_13'
	self.request_fan_talk_14 = 'movie_2_request_fan_talk_14'
	self.request_fan_talk_15 = 'movie_2_request_fan_talk_15'
	self.request_fan_talk_16 = 'movie_2_request_fan_talk_16'
	self.request_fan_talk_17 = 'movie_2_request_fan_talk_17'
	self.request_fan_talk_18 = 'movie_2_request_fan_talk_18'
	self.request_fan_talk_19 = 'movie_2_request_fan_talk_19'
	self.request_fan_talk_20 = 'movie_2_request_fan_talk_20'

	self.sign_item_subtitle = 'movie_2_request_fan_sign_subtitle_1'
	self.sign_item_desc = 'movie_2_request_fan_sign_desc_1'

	self.rifle_item_subtitle = 'movie_2_request_fan_rifle_subtitle_1'
	self.rifle_item_desc = 'movie_2_request_fan_rifle_desc_1'

	self.handkerchief_item_subtitle = 'movie_2_request_fan_handkerchief_subtitle_1'
	self.handkerchief_item_desc = 'movie_2_request_fan_handkerchief_desc_1'

	self.give_sign_fail_talk_1 = 'movie_2_give_sign_fail_talk_1'
	self.give_sign_fail_talk_2 = 'movie_2_give_sign_fail_talk_2'
	self.give_sign_fail_talk_3 = 'movie_2_give_sign_fail_talk_3'

	self.give_sign_success_talk_1 = 'movie_2_give_sign_success_talk_1'
	self.give_sign_success_talk_2 = 'movie_2_give_sign_success_talk_2'
	self.give_sign_success_talk_3 = 'movie_2_give_sign_success_talk_3'

	self.give_rifle_fail_talk_1 = 'movie_2_give_rifle_fail_talk_1'
	self.give_rifle_fail_talk_2 = 'movie_2_give_rifle_fail_talk_2'
	self.give_rifle_fail_talk_3 = 'movie_2_give_rifle_fail_talk_3'
	self.give_rifle_fail_talk_4 = 'movie_2_give_rifle_fail_talk_4'

	self.give_rifle_success_talk_1 = 'movie_2_give_rifle_success_talk_1'
	self.give_rifle_success_talk_2 = 'movie_2_give_rifle_success_talk_2'
	self.give_rifle_success_talk_3 = 'movie_2_give_rifle_success_talk_3'

	self.give_handkerchief_fail_talk_1 = 'movie_2_give_handkerchief_fail_talk_1'
	self.give_handkerchief_fail_talk_2 = 'movie_2_give_handkerchief_fail_talk_2'
	self.give_handkerchief_fail_talk_3 = 'movie_2_give_handkerchief_fail_talk_3'

	self.give_handkerchief_success_talk_1 = 'movie_2_give_handkerchief_success_talk_1'
	self.give_handkerchief_success_talk_2 = 'movie_2_give_handkerchief_success_talk_2'
	self.give_handkerchief_success_talk_3 = 'movie_2_give_handkerchief_success_talk_3'
	self.give_handkerchief_success_talk_4 = 'movie_2_give_handkerchief_success_talk_4'
	self.give_handkerchief_success_talk_5 = 'movie_2_give_handkerchief_success_talk_5'

	self.find_item_talk_1 = 'movie_2_request_fan_find_talk_1'
	self.find_item_talk_2 = 'movie_2_request_fan_find_talk_2'
	self.find_item_talk_3 = 'movie_2_request_fan_find_talk_3'
	self.find_item_talk_4 = 'movie_2_request_fan_find_talk_4'

	-- 푸드트럭
	self.food_sell_npc_name_2 = 'food2'

	self.icecream_sell_npc_talk_1 = 'movie_2_icecream_sell_npc_talk_1'
	self.icecream_sell_npc_talk_2 = 'movie_2_icecream_sell_npc_talk_2'
	self.icecream_sell_npc_talk_3 = 'movie_2_icecream_sell_npc_talk_3'

	self.hotdog_sell_npc_talk_1 = 'movie_2_hotdog_sell_npc_talk_1'
	self.hotdog_sell_npc_talk_2 = 'movie_2_hotdog_sell_npc_talk_2'
	self.hotdog_sell_npc_talk_3 = 'movie_2_hotdog_sell_npc_talk_3'

	self.icecream_sell_price = 'movie_2_icecream_sell_price_1'
	self.hotdog_sell_price = 'movie_2_hotdog_sell_price_1'
	self.not_buy_food = 'movie_2_not_buy_food_1'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BurnEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	CS.Oak.CommonScreenplay.PreloadItemGetEvent()

	-- 프로포즈 이벤트를 봤는지 체크
	if CS.Oak.StageProgress.Current:HasStarPiece(self.propose_starpiece_name) then
		self.saw_propose = true
		local couple_man = get_character(self.couple_man_name)
		character_util.set_emotion(couple_man, { name = 'idle' })
		character_util.set_active_state(get_character(self.couple_woman_name), "disabled")
		character_util.set_active_state(couple_man, "disabled")
	else
		get_character(self.couple_man_name).Interactable:AddListener(self.cs_controller)

		for i = 1, self.starpiece_board_num do
			local board = get_field_object(self.starpiece_board_name .. i)
			table.insert(self.starpiece_board_list, board)
			board.Interactable.Message = self.board_talk_1
		end

		self.propose_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.propose_begin, self))
	end

	-- 영화촬영 이벤트를 봤는지 체크
	if CS.Oak.StageProgress.Current:HasStarPiece(self.shooting_starpiece_name) then
		self.saw_movie_shooting = true

		character_util.set_active_state(get_character(self.blackguard1_name), "disabled")
		character_util.set_active_state(get_character(self.blackguard2_name), "disabled")

		local food_npc = get_character(self.food_truck_npc_name)
		character_util.set_emotion(food_npc, { name = 'idle' })
		character_util.set_anim(food_npc, { name = 'idle', loop = true })
	else
		get_character(self.food_truck_npc_name).Interactable:AddListener(self.cs_controller)
		self.movie_coroutine = coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.attack_store, self))
	end

	character_util.set_active_state(get_character(self.blackguard3_name), "disabled")
	character_util.set_active_state(get_character(self.blackguard4_name), "disabled")
	character_util.set_active_state(get_character(self.blackguard5_name), "disabled")

	-- 사생팬의 부탁 이벤트를 봤는지 체크
	if CS.Oak.StageProgress.Current:HasStarPiece(self.request_star_piece_name) then
		self.saw_request_fan = true
		self.request_fan_first = true

		local fan1 = get_character(self.request_fan1_name)
		local fan2 = get_character(self.request_fan2_name)
		local fan3 = get_character(self.request_fan3_name)

		character_util.set_emotion(fan1, { name = 'idle' })
		character_util.set_emotion(fan2, { name = 'idle' })
		character_util.set_emotion(fan3, { name = 'idle' })

		character_util.set_active_state(fan1, "disabled")
		character_util.set_active_state(fan2, "disabled")
		character_util.set_active_state(fan3, "disabled")

		get_field_object(self.rifle_drop_item_name).Interactable = CS.Oak.NonInteractable.Instance
	else
		get_field_object(self.rifle_drop_item_name).Interactable = CS.Oak.PublishInteractable.Create()

		get_character(self.request_fan1_name).Interactable:AddListener(self.cs_controller)
		get_character(self.request_fan2_name).Interactable:AddListener(self.cs_controller)
		get_character(self.request_fan3_name).Interactable:AddListener(self.cs_controller)

		get_character(self.donate_npc_name).Interactable:AddListener(self.cs_controller)
		unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	end

	-- 푸드트럭 NPC
	get_character(self.food_sell_npc_name_2).Interactable:AddListener(self.cs_controller)

	return
end

function local_class:need_on_launch()
	--- movie main quest id
	local main_quest_id = 60005

	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	--- progress 4 (Section 5) 일때만 launch를 뺏음
	if quest_progress.InnerProgress == 4 then
		return true
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BurnEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if not self.saw_movie_shooting and not self.battle_start then
		get_character(self.blackguard1_name).Interactable:RemoveRelatedEvent(self.cs_controller)
		get_character(self.blackguard2_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.aura_effect ~= nil then
		self.aura_effect:Dispose()
		self.aura_effect = nil
	end

	get_character(self.couple_man_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	get_character(self.food_truck_npc_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	get_character(self.request_fan1_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.request_fan2_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.request_fan3_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.donate_npc_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	get_character(self.food_sell_npc_name_2).Interactable:RemoveRelatedEvent(self.cs_controller)

	if self.starpiece_board_list ~= nil then
		for key, value in pairs(self.starpiece_board_list) do
			value = nil
		end
		self.starpiece_board_list = nil
	end

	self.propose_coroutine = nil
	self.movie_coroutine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then

		if not self.saw_movie_shooting then
			if lua_helper.reference_equals(e.Target, get_character(self.food_truck_npc_name)) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.movie_shooting, self))
			end
		end

		if not self.saw_request_fan then
			if self.request_fan_first then
				if lua_helper.reference_equals(e.Target, get_character(self.request_fan1_name)) then
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.give_item, self, self.request_fan1_name, 1))
				elseif lua_helper.reference_equals(e.Target, get_character(self.request_fan2_name)) then
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.give_item, self, self.request_fan2_name, 2))
				elseif lua_helper.reference_equals(e.Target, get_character(self.request_fan3_name)) then
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.give_item, self, self.request_fan3_name, 3))
				end
			end

			if lua_helper.reference_equals(e.Target, get_character(self.donate_npc_name)) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sell_sign, self))
			end

			if lua_helper.reference_equals(e.Target, get_field_object(self.rifle_drop_item_name)) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_item_box, self))
			end
		end

		if not self.saw_propose and lua_helper.reference_equals(e.Target, get_character(self.couple_man_name)) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.propose_man_talk, self))
		end

		if lua_helper.reference_equals(e.Target, get_character(self.food_sell_npc_name_2)) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.sell_food, self, self.food_sell_npc_name_2, 2))
		end

		return true
	elseif event_type == typeof(CS.Oak.BurnEvent) and not self.saw_propose then
		for key, value in pairs(self.starpiece_board_list) do
			if lua_helper.reference_equals(e.Target, value) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.success_propose, self))
			end
		end
		return true
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == "BATTLE_5" and not self.saw_movie_shooting then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.food_truck_npc_talk, self))
		end
		return true
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and
				lua_helper.reference_equals(e.FieldObject, user_party_leader) and not self.saw_request_fan then
			if e.Zone.Name == self.donate_zone_name and not self.donate_zone_in then
				self.donate_zone_in = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.donate_npc_zone, self))
			end
		end
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) and not self.request_fan_first
				and not self.saw_request_fan and e.Zone.Name == self.request_fan_zone_name then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.request_fan_first_talk, self))
		end
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) and not self.saw_propose and
				e.Zone.Name == 'section_2_10' and not self.couple_woman_begin then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.propose_woman_talk, self))
		end
		return true
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		if not self.saw_request_fan and not self.get_handkerchief_item and
				lua_helper.reference_equals(e.FieldObject, get_field_object(self.handkerchief_drop_item_name)) then
			local pos = get_field_object(self.handkerchief_drop_item_name).Position
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_handkerchief, self, pos))
		end
		return true
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		if not self.saw_request_fan then
			self.aura_effect = unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(
					get_field_object(self.rifle_drop_item_name).Position + vector(0, 0.5, 0))
		end

		if not self.saw_propose then
			coroutine_manager:StartCoroutine(self.propose_coroutine)
		end
		return true
	end

	return false
end

function local_class:propose_begin()
	local man = get_character(self.couple_man_name)

	while self.couple_man_loop do
		character_util.set_direction(man, 'left')
		character_util.move_to_async(man, vector(28, 0, 16), nil, 7, true, true)

		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'eat', loop = true })

		-- 아이씨, 여기 분명 챙겨 놨었는데…
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_1 })
		--wait_for_sec(2)

		character_util.set_direction(man, 'right')
		character_util.move_to_async(man, vector(31, 0, 16), nil, 7, true, true)

		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'eat', loop = true })

		-- 라이터가…
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_2 })
		--wait_for_sec(2)

		character_util.set_direction(man, 'left')
		character_util.move_to_async(man, vector(28, 0, 16), nil, 7, true, true)

		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'eat', loop = true })

		-- 성냥이…
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_3 })
		--wait_for_sec(2)

		character_util.set_direction(man, 'right')
		character_util.move_to_async(man, vector(31, 0, 16), nil, 7, true, true)

		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'eat', loop = true })

		-- 하다못해 부싯돌이라도…
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_4 })
		--wait_for_sec(2)
	end
end

function local_class:propose_woman_talk()
	self.couple_woman_begin = true
	local woman = get_character(self.couple_woman_name)

	-- 오빠… 나 언제까지 기다려야돼?
	speech_bubble_util.show_speech_bubble_async(woman, { key = self.woman_talk_1, skip = false })
	self.couple_woman_begin = false
end

function local_class:propose_man_talk()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local man = get_character(self.couple_man_name)

	stop_coroutine(self.propose_coroutine)
	speech_bubble_util.remove_bubble(man)

	if user_party_leader.Position.x - man.Position.x < 0 then
		character_util.move_to(man, vector(31, 0, 16), 0.5, nil)
		party_util.align_party(vector(31, 0, 16), 'left', 0.5, 'arc')
		character_util.set_direction(man, 'right')
		character_util.set_direction(man, 'left')
		wait_for_sec(0.5)
	else

		character_util.move_to(man, vector(28, 0, 16), 0.5, nil)
		party_util.align_party(vector(28, 0, 16), 'right', 0.5, 'arc')
		character_util.set_direction(man, 'left')
		character_util.set_direction(man, 'right')
		wait_for_sec(0.5)
	end

	if not self.couple_man_begin then
		music_player:PlaySfxOneShot('03_dialogue_sadness_01')
		-- 저기… 저 좀 도와주세요…
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'sing', loop = true })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_5, skip = true })

		--[[
		-- 오늘 프러포즈를 하려고 표지판 촛불 이벤트를 준비했는데…
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'cross_arm', loop = false })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_6, skip = true })
		]]

		music_player:PlaySfxOneShot('03_runaway_01')
		-- 준비해온 라이터가 갑자기 안보이는거에요!
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_7, skip = true })

		-- 부탁드립니다… 뭐라도 불 붙일 물건을 찾아와 주세요…
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'sing', loop = true })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_8, skip = true })

		--[[
		-- 아니면 저 오늘 차일지도 몰라요…
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'sing', loop = true })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_9, skip = true })
		]]

		self.couple_man_begin = true
	else
		-- 부탁드립니다… 저 오늘 차일지도 몰라요…
		character_util.set_emotion(man, { name = 'scared' })
		character_util.set_anim(man, { name = 'sing', loop = true })
		speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_10, skip = true })
	end

	self.propose_coroutine = coroutine_manager:StartCoroutine(
			stage.StageGameObject, util.cs_generator(self.propose_begin, self))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 표지판에 불이 붙었을 때
function local_class:success_propose()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	stop_coroutine(self.propose_coroutine)

	local woman = get_character(self.couple_woman_name)
	local man = get_character(self.couple_man_name)

	character_util.set_emotion(woman, { name = 'love' })
	character_util.set_anim(woman, { name = 'sing', loop = true })

	character_util.set_emotion(man, { name = 'doyagao' })
	character_util.set_anim(man, { name = 'idle', loop = true })

	speech_bubble_util.remove_bubble(woman)
	speech_bubble_util.remove_bubble(man)
	camera_util.move_async(woman.Position, 1, { end_target = woman })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 어머, 오빠! 너무 로맨틱해!
	speech_bubble_util.show_speech_bubble(woman, { key = self.woman_talk_2, skip = true })
	wait_for_sec(2)

	--character_util.move_to(woman, vector(29, 0, 11), 2, nil, true, true)
	character_util.move_to_async(man, vector(29, 0, 16), nil, 4, true, true)
	character_util.move_to_async(man, vector(29, 0, 11), nil, 4, true, true)

	character_util.set_direction(woman, 'left')
	character_util.set_direction(man, 'right')

	-- 이 순간만을 기다렸어…
	character_util.set_emotion(man, { name = 'doyagao' })
	character_util.set_anim(man, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(man, { key = self.man_talk_11, skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	-- 나와… 결혼해 주겠어?
	character_util.set_emotion(man, { name = 'love' })
	character_util.set_anim(man, { name = 'slaute_china', loop = false, scale = 0.3 })
	speech_bubble_util.show_speech_bubble(man, { key = self.man_talk_12, skip = true })
	wait_for_sec(1.2)

	speech_bubble_util.remove_bubble(man)

	-- 물론이지! 자기야, 사랑해!
	character_util.set_emotion(woman, { name = 'love' })
	character_util.set_anim(woman, { name = 'sing', loop = true })
	speech_bubble_util.show_speech_bubble(woman, { key = self.woman_talk_3, skip = true })

	wait_for_sec(2)

	character_util.move_to(woman, vector(29.7, 0, 11), 0.2, nil, true, true)
	character_util.move_to_async(man, vector(29.2, 0, 11), 0.5, nil, true, true)

	character_util.set_anim(woman, { name = 'push', loop = false })
	character_util.set_anim(man, { name = 'push', loop = false })

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	self.saw_propose = true
	man.Interactable:RemoveRelatedEvent(self.cs_controller)
	woman.Interactable:RemoveRelatedEvent(self.cs_controller)

	man.Interactable.Talk = 'movie_2_propose_man_13'
	woman.Interactable.Talk = 'movie_2_propose_woman_4'

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 불량배들이 상점을 공격함
function local_class:attack_store()

	local blackguard1 = get_character(self.blackguard1_name)
	local blackguard2 = get_character(self.blackguard2_name)
	local food_npc = get_character(self.food_truck_npc_name)
	local store = get_field_object(self.store_name)

	character_util.set_emotion(food_npc, { name = 'damaged' })
	character_util.set_anim(food_npc, { name = 'embarrassed' })
	character_util.set_emotion(blackguard1, { name = 'doyagao' })
	character_util.set_emotion(blackguard2, { name = 'doyagao' })
	character_util.set_direction(blackguard1, 'right')
	character_util.set_direction(blackguard2, 'left')
	character_util.set_anim(blackguard1, { name = 'idle', loop = true })
	character_util.set_anim(blackguard2, { name = 'idle', loop = true })

	while true do
		character_util.set_anim(blackguard1, { name = 'attack', loop = false })
		wait_for_sec(0.3)
		music_player_util.play_sfx({ sfx_name = '01_hit_dummy_02', parent = blackguard1, max_distance = 20 })

		character_util.move_to_async(store, store.Position + vector(0.1, 0, 0), 0.05)
		character_util.move_to_async(store, store.Position - vector(0.1, 0, 0), 0.05)
		character_util.set_anim(blackguard1, { name = 'idle', loop = true })
		wait_for_sec(0.8)

		character_util.set_anim(blackguard2, { name = 'attack', loop = false })
		wait_for_sec(0.3)
		music_player_util.play_sfx({ sfx_name = '01_hit_dummy_02', parent = blackguard2, max_distance = 20 })
		character_util.set_anim(blackguard2, { name = 'idle', loop = true })

		character_util.move_to_async(store, store.Position - vector(0.1, 0, 0), 0.05)
		character_util.move_to_async(store, store.Position + vector(0.1, 0, 0), 0.05)
		wait_for_sec(0.8)
	end
end

-- 불량배에게 인터렉트 했을 때
function local_class:movie_shooting()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local blackguard1 = get_character(self.blackguard1_name)
	local blackguard2 = get_character(self.blackguard2_name)
	local food_npc = get_character(self.food_truck_npc_name)

	local pos = food_npc.Position + unity_class.vector3.back * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 1, CS.Oak.Party.AlignType.Linear)
	wait_for_sec(1)
	stop_coroutine(self.movie_coroutine)
	character_util.move_to(get_field_object(self.store_name), vector(65, 0, 51), 0.05)

	if self.interact_count == 1 then
		-- 오늘 여기 장사 안합니다~ 가세요~
		character_util.set_anim(blackguard1, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(blackguard1,
				{ key = self.blackguard_talk_1, skip = true })

		-- 가지 마세요…
		character_util.set_emotion(food_npc, { name = 'scared' })
		character_util.set_anim(food_npc, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(food_npc,
				{ key = self.food_truck_npc_talk_3, skip = true, scale = 0.5 })

		self.movie_coroutine = coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.attack_store, self))

		self.interact_count = 2
		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	if self.interact_count == 2 then
		-- 아, 가라고 좀…
		character_util.set_emotion(blackguard2, { name = 'tired' })
		character_util.set_anim(blackguard2, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(blackguard2,
				{ key = self.blackguard_talk_2, skip = true })

		-- 제발요…
		character_util.set_emotion(food_npc, { name = 'scared' })
		character_util.set_anim(food_npc, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(food_npc,
				{ key = self.food_truck_npc_talk_4, skip = true, scale = 0.5 })

		self.movie_coroutine = coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.attack_store, self))

		self.interact_count = 3
		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	-- 아직도 안갔네… 맘대로 해라, 그래…
	character_util.set_emotion(blackguard1, { name = 'tired' })
	character_util.set_anim(blackguard1, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard1,
			{ key = self.blackguard_talk_3, skip = true })

	music_player:PlaySfxOneShot('02_die_goblin_01')
	music_player:PlaySfxOneShot('01_player_jump_01')
	-- 형씨, 우린 하던 얘기 마저 해야지?
	character_util.set_emotion(blackguard2, { name = 'doyagao' })
	character_util.set_anim(blackguard2, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard2,
			{ key = self.blackguard_talk_4, skip = true })

	-- 도와주세요…
	character_util.set_emotion(food_npc, { name = 'scared' })
	character_util.set_anim(food_npc, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(food_npc,
			{ key = self.food_truck_npc_talk_1, skip = true, scale = 0.5 })

	-- 이 깡패들! 경찰에 신고할거야! / 그냥 간다
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local choise = 0

	branches:Add({
		Text = game_string:GetString(self.blackguard_branch_1),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString(self.blackguard_branch_2),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			choise = 1
		end })

	ui_overlay_util.push_overlay(blackguard1, branches)

	while wait do
		coroutine.yield(nil)
	end

	if choise == 1 then
		self.movie_coroutine = coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.attack_store, self))

		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	-- 어허, 이 녀석이! 깡패라니! 아니야, 임마!
	character_util.set_direction(blackguard1, 'down')
	character_util.set_emotion(blackguard1, { name = 'attack' })
	character_util.set_anim(blackguard1, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard1,
			{ key = self.blackguard_talk_5, skip = true })

	-- 그래! 우리는 그 뭐야… 영화 촬영 중이라고! 그지?
	character_util.set_direction(blackguard2, 'down')
	character_util.set_emotion(blackguard2, { name = 'mad' })
	character_util.set_anim(blackguard2, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard2,
			{ key = self.blackguard_talk_6, skip = true })

	character_util.set_direction(food_npc, 'right')
	character_util.move_to_async(food_npc, food_npc.Position - vector(0.5, 0, 0), 1, nil, false, true)

	character_util.set_direction(food_npc, 'left')
	character_util.move_to_async(food_npc, food_npc.Position + vector(0.5, 0, 0), 1, nil, false, true)

	music_player:PlaySfxOneShot('02_goblin_hit_01')
	music_player:PlaySfxOneShot('01_player_jump_01')
	-- 똑바로 말해, 임마!
	character_util.set_direction(blackguard2, 'left')
	character_util.set_emotion(blackguard2, { name = 'mad' })
	character_util.set_anim(blackguard2, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard2,
			{ key = self.blackguard_talk_7, skip = true })

	character_util.set_direction(food_npc, 'down')
	character_util.set_anim(food_npc, { name = 'nod', loop = false })

	wait_for_sec(0.5)

	character_util.set_anim(food_npc, { name = 'idle', loop = true })

	wait_for_sec(0.5)

	local checklist = { true, true, true, true }

	while true do
		branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		wait = true
		local choice = 0
		local out = true

		for i = 1, 4 do
			if checklist[i] then
				out = false
				if i == 1 then
					-- 어떤 영환데?
					branches:Add({
						Text = game_string:GetString(self.blackguard_branch_3),
						Tendency = CS.Oak.TalkTendency.Intellect,
						Callback = function()
							wait = false
							choice = 1
						end })
				elseif i == 2 then
					-- 제작비는 얼마 정돈데?
					branches:Add({
						Text = game_string:GetString(self.blackguard_branch_4),
						Tendency = CS.Oak.TalkTendency.Intellect,
						Callback = function()
							wait = false
							choice = 2
						end })
				elseif i == 3 then
					-- 주인공은 어떤 캐릭터인데?
					branches:Add({
						Text = game_string:GetString(self.blackguard_branch_5),
						Tendency = CS.Oak.TalkTendency.Intellect,
						Callback = function()
							wait = false
							choice = 3
						end })
				elseif i == 4 then
					-- 지금 찍고 있는건 무슨 장면인데?
					branches:Add({
						Text = game_string:GetString(self.blackguard_branch_6),
						Tendency = CS.Oak.TalkTendency.Intellect,
						Callback = function()
							wait = false
							choice = 4
						end })
				end
			end
		end

		if out then
			break
		end

		ui_overlay_util.push_overlay(blackguard1, branches)

		while wait do
			coroutine.yield(nil)
		end
		character_util.set_direction(blackguard1, 'down')
		character_util.set_direction(blackguard2, 'down')

		character_util.set_emotion(blackguard1, { name = 'doyagao' })
		character_util.set_emotion(blackguard2, { name = 'doyagao' })

		character_util.set_anim(blackguard1, { name = 'idle', loop = true })
		character_util.set_anim(blackguard2, { name = 'idle', loop = true })

		checklist[choice] = false

		if choice == 1 then
			-- 슈퍼파워를 가진 히어로가 악당들을 무찌른다는 내용의 화려한 볼거리로 무장한 블록버스터 액션 영화지!
			speech_bubble_util.show_speech_bubble_async(blackguard2,
					{ key = self.blackguard_talk_8, skip = true })
		elseif choice == 2 then
			-- 알게 뭐야… 한 1000골드쯤 하겠지…
			speech_bubble_util.show_speech_bubble_async(blackguard1,
					{ key = self.blackguard_talk_9, skip = true })
		elseif choice == 3 then
			-- 정의감 넘치는 남자중의 상남자! 그게 바로 내 배역이지!
			speech_bubble_util.show_speech_bubble_async(blackguard2,
					{ key = self.blackguard_talk_10, skip = true })
		elseif choice == 4 then
			-- 보면 몰라? 자릿세 내라고 위협하는 장면이지 뭐…
			speech_bubble_util.show_speech_bubble_async(blackguard1,
					{ key = self.blackguard_talk_11, skip = true })
		end
	end


	-- 그러니까 정리를 하자면…
	branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	wait = true

	branches:Add({
		Text = game_string:GetString(self.blackguard_branch_7),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(blackguard1, branches)

	while wait do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('01_jump_01')
	-- 제작비 1000골드짜리 블록버스터 히어로 영화에서…
	character_util.set_direction(blackguard1, 'right')
	character_util.set_emotion(blackguard1, { name = 'doyagao' })
	character_util.set_anim(blackguard1, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(blackguard1,
			{ key = self.blackguard_talk_16, skip = true })

	music_player:PlaySfxOneShot('01_jump_01')
	-- 정의의 히어로가 자릿세 내라고 위협하고 있는 씬을 찍고 있다는거지!
	character_util.set_direction(blackguard2, 'left')
	character_util.set_emotion(blackguard2, { name = 'doyagao' })
	character_util.set_anim(blackguard2, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(blackguard2,
			{ key = self.blackguard_talk_12, skip = true })

	wait_for_sec(2)

	-- 너가 생각해도 말도 안되지?
	character_util.set_direction(blackguard1, 'right')
	character_util.set_emotion(blackguard1, { name = 'idle' })
	character_util.set_anim(blackguard1, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard1,
			{ key = self.blackguard_talk_13, skip = true })

	character_util.set_direction(user_party_leader, 'left')
	character_util.set_anim(user_party_leader, { name = 'nod', loop = true })
	wait_for_sec(1)
	character_util.set_direction(user_party_leader, 'right')
	character_util.set_anim(user_party_leader, { name = 'nod', loop = true })
	wait_for_sec(1)

	character_util.remove_anim(user_party_leader)

	-- 에이씨… 그럴거 같더라…
	character_util.set_direction(blackguard2, 'left')
	character_util.set_emotion(blackguard2, { name = 'idle' })
	character_util.set_anim(blackguard2, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(blackguard2,
			{ key = self.blackguard_talk_14, skip = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	-- 에잇, 들켰다! 얘들아! 조져!
	character_util.set_direction(blackguard1, 'down')
	character_util.set_emotion(blackguard1, { name = 'mad' })
	character_util.set_anim(blackguard1, { name = 'idle', loop = true })
	character_util.set_direction(blackguard2, 'down')
	character_util.set_emotion(blackguard2, { name = 'mad' })
	character_util.set_anim(blackguard2, { name = 'idle', loop = true })

	speech_bubble_util.show_speech_bubble_async(blackguard1, {
		key = self.blackguard_talk_15, skip = true, bubble_type = 'shout', screen_pos = vector(-100, -100) })

	get_character(self.blackguard1_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.blackguard2_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	self.battle_start = true

	local blackguard3 = get_character(self.blackguard3_name)
	local blackguard4 = get_character(self.blackguard4_name)
	local blackguard5 = get_character(self.blackguard5_name)

	character_util.set_active_state(blackguard3, "enabled")
	character_util.set_active_state(blackguard4, "enabled")
	character_util.set_active_state(blackguard5, "enabled")

	music_player:PlaySfx({ sfxName = '01_dash_01', loop = true, duration = 1 })
	character_util.move_to(blackguard3, blackguard3.Position + vector(10, 0, 0), 1, nil)
	character_util.move_to(blackguard4, blackguard4.Position + vector(10, 0, 0), 1, nil)
	character_util.move_to(blackguard5, blackguard5.Position + vector(10, 0, 0), 1, nil)

	wait_for_sec(1)

	character_util.remove_anim(blackguard1)
	character_util.remove_anim(blackguard2)
	character_util.remove_anim(blackguard3)
	character_util.remove_anim(blackguard4)
	character_util.remove_anim(blackguard5)

	--전투전환
	character_util.convert_to_monster(blackguard1, 'BATTLE_5')
	character_util.convert_to_monster(blackguard2, 'BATTLE_5')
	character_util.convert_to_monster(blackguard3, 'BATTLE_5')
	character_util.convert_to_monster(blackguard4, 'BATTLE_5')
	character_util.convert_to_monster(blackguard5, 'BATTLE_5')
	command_util.execute_monster_notice(blackguard1, user_party.Leader, "battle")
	command_util.execute_monster_notice(blackguard2, user_party.Leader, "battle")
	command_util.execute_monster_notice(blackguard3, user_party.Leader, "battle")
	command_util.execute_monster_notice(blackguard4, user_party.Leader, "battle")
	command_util.execute_monster_notice(blackguard5, user_party.Leader, "battle")

	-- npc 인터렉트 해제
	get_character(self.food_truck_npc_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	for i = 1, 8 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('door_battle_' .. i))
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 푸드트럭 상인 스타피스 보상
function local_class:food_truck_npc_talk()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local food_npc = get_character(self.food_truck_npc_name)
	character_util.set_emotion(food_npc, { name = 'awesome' })
	character_util.set_anim(food_npc, { name = 'clap', loop = true })

	camera_util.move(food_npc.Position)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 구해주셔서 정말 고마워요!
	speech_bubble_util.show_speech_bubble_async(food_npc,
			{ key = self.food_truck_npc_talk_2, skip = true })

	-- 스타피스 등장
	local star_piece = get_field_object(self.shooting_starpiece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(food_npc.Position))
	coroutine.yield(coroutine_class.wait_for_sec(2.0))

	self.saw_movie_shooting = true
	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	food_npc.Interactable.Talk = self.food_truck_npc_talk_2

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 기부 NPC
function local_class:donate_npc_zone()
	local donate_npc = get_character(self.donate_npc_name)
	local i = 1
	while self.donate_zone_in do

		if i % 2 == 1 then
			-- 기부 행사에 참여하세요~
			speech_bubble_util.show_speech_bubble_async(donate_npc,
					{ key = self.donate_npc_talk_1 })
		else
			-- 스타들의 애장품을 구매해서 불우한 이웃을 도우세요~
			speech_bubble_util.show_speech_bubble_async(donate_npc,
					{ key = self.donate_npc_talk_2 })
		end
		i = i + 1
		wait_for_sec(1)
	end
end

-- 사인을 파는 NPC
function local_class:sell_sign()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	self.donate_zone_in = false

	local donate_npc = get_character(self.donate_npc_name)
	speech_bubble_util.remove_bubble(donate_npc)

	local pos = donate_npc.Position + unity_class.vector3.right * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	-- 어서 오세요! 스타들의 애장품을 구매해서 불우한 이웃을 도와주세요!
	speech_bubble_util.show_speech_bubble_async(donate_npc,
			{ key = self.donate_npc_talk_3, skip = true })

	-- 지금 남은 물건이… 친필 사인이 된 포스터가 남았네요!
	speech_bubble_util.show_speech_bubble_async(donate_npc,
			{ key = self.donate_npc_talk_4, skip = true })

	-- 500골드 입니다. 구매 하시겠어요?
	speech_bubble_util.show_speech_bubble_async(donate_npc,
			{ key = self.donate_npc_talk_5, skip = true })

	-- 구매한다 / 그만둔다
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local buy = false

	-- 구매한다
	branches:Add({
		Text = game_string:GetString(self.donate_branch_1),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
			buy = true
		end })

	-- 그만둔다
	branches:Add({
		Text = game_string:GetString(self.donate_branch_2),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			buy = false
		end })

	ui_overlay_util.push_overlay(donate_npc, branches)

	while wait do
		coroutine.yield(nil)
	end

	if buy then
		if CS.Oak.User.Me.Gold >= 500 then
			coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, 500))

			music_player:PlaySfxOneShot('03_drop_gold_01')
			-- 네, 여깄습니다!
			speech_bubble_util.show_speech_bubble_async(donate_npc,
					{ key = self.donate_npc_talk_6, skip = true })
			music_player:PlaySfxOneShot('01_throw_01')

			local sign_id = 20167
			-- 사인 드롭
			local drop_item = drop_item_util.create_item(
					{ pos = donate_npc.Position,
					  target = user_party_leader.Position, itemid = sign_id, notforinven = true })
			drop_item.ConsumeTarget = user_party_leader

			coroutine.yield(coroutine_class.wait_for_sec(1.5))

			-- 아이템 획득 연출
			local item_place_holder = CS.Oak.ItemPlaceholder()
			item_place_holder.ItemId = sign_id
			coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder,
					self.sign_item_subtitle, self.sign_item_desc))

			-- 참여해주셔서 감사합니다!
			speech_bubble_util.show_speech_bubble_async(donate_npc,
					{ key = self.donate_npc_talk_7, skip = true })

			self.get_sign_item = true
			get_character(self.donate_npc_name).Interactable:RemoveRelatedEvent(self.cs_controller)
		else
			-- 죄송해요… 돈이 부족하시네요.
			speech_bubble_util.show_speech_bubble_async(donate_npc,
					{ key = self.donate_npc_talk_8, skip = true })
		end
	end

	self.donate_zone_in = true
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.donate_npc_zone, self))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 소총 드랍 상자
function local_class:drop_item_box()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	-- 무엇인가 들어있을 것 같다.
	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(self.find_item_talk_1), 0, 1))
	stage.FieldUINarrationBox:Hide()
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local select = 0

	-- 뒤져본다
	branches:Add({
		Text = game_string:GetString(self.find_item_talk_2),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
			select = 1
		end })

	-- 그만둔다
	branches:Add({
		Text = game_string:GetString(self.find_item_talk_3),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			select = 2
		end })

	ui_overlay_util.push_overlay(fan, branches)

	while wait do
		coroutine.yield(nil)
	end

	if select == 1 then
		local get_success = false
		local pos = get_field_object(self.rifle_drop_item_name).Position

		if not self.get_rifle_item then

			music_player:PlaySfx({ sfxName = '03_equipping_01', loop = true, duration = 1 })
			character_util.set_anim(user_party_leader, { name = 'eat' })
			coroutine.yield(coroutine_class.wait_for_sec(1))

			character_util.remove_anim(user_party_leader)

			music_player:PlaySfxOneShot('03_field_item_popup_01')
			local sign_id = 20168
			-- 소품 총 드롭
			local drop_item = drop_item_util.create_item(
					{ pos = pos, target = user_party_leader.Position, itemid = sign_id, notforinven = true })
			drop_item.ConsumeTarget = user_party_leader

			coroutine.yield(coroutine_class.wait_for_sec(1.5))

			-- 아이템 획득 연출
			local item_place_holder = CS.Oak.ItemPlaceholder()
			item_place_holder.ItemId = sign_id
			coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder,
					self.rifle_item_subtitle, self.rifle_item_desc))

			self.aura_effect:Dispose()
			self.aura_effect = nil
			self.get_rifle_item = true
			get_success = true

			get_field_object(self.rifle_drop_item_name).Interactable = CS.Oak.NonInteractable.Instance
		end
		-- 아무것도 없었다...
		if not get_success then
			stage.FieldUINarrationBox:Show()
			coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(self.find_item_talk_4), 0, 1))
			stage.FieldUINarrationBox:Hide()
			coroutine.yield(coroutine_class.wait_for_sec(0.5))
		end
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 손수건 드롭
function local_class:drop_handkerchief(pos)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local sign_id = 20169
	-- 손수건 드롭
	local drop_item = drop_item_util.create_item(
			{ pos = pos, target = user_party_leader.Position, itemid = sign_id, notforinven = true })
	drop_item.ConsumeTarget = user_party_leader

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	-- 아이템 획득 연출
	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = sign_id
	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder,
			self.handkerchief_item_subtitle, self.handkerchief_item_desc))

	self.get_handkerchief_item = true

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 사생팬 존 입장 시
function local_class:request_fan_first_talk()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local request_fan1 = get_character(self.request_fan1_name)
	local request_fan2 = get_character(self.request_fan2_name)
	local request_fan3 = get_character(self.request_fan3_name)

	character_util.set_direction(request_fan1, 'right')
	character_util.set_direction(request_fan2, 'up')
	character_util.set_direction(request_fan3, 'left')
	character_util.set_anim(request_fan1, { name = 'idle', loop = true })
	character_util.set_anim(request_fan2, { name = 'idle', loop = true })
	character_util.set_anim(request_fan3, { name = 'idle', loop = true })

	music_player:PlaySfxOneShot('01_gatcha_point_01')
	character_util.show_emoticon(request_fan1, nil, 'notice')
	character_util.show_emoticon(request_fan2, nil, 'notice')
	character_util.show_emoticon_async(request_fan3, nil, 'notice')

	local pos1 = vector(25, 0, 53)
	local pos2 = vector(25, 0, 50)
	local pos3 = vector(25, 0, 47)

	local move_pos1 = vector(user_party_leader.Position.x - 1, 0, user_party_leader.Position.z)
	local move_pos2 = vector(user_party_leader.Position.x, 0, user_party_leader.Position.z - 1)
	local move_pos3 = vector(user_party_leader.Position.x + 1, 0, user_party_leader.Position.z)

	character_util.set_anim(request_fan1, { name = 'run', loop = true })
	character_util.set_anim(request_fan2, { name = 'run', loop = true })
	character_util.set_anim(request_fan3, { name = 'run', loop = true })

	music_player:PlaySfx({ sfxName = '01_dash_01', loop = true, duration = 1 })
	character_util.move_to(request_fan1, vector(request_fan1.Position.x, 0, user_party_leader.Position.z), 0.5, nil, true)
	character_util.move_to(request_fan2, vector(user_party_leader.Position.x, 0, request_fan2.Position.z), 0.5, nil, true)
	character_util.move_to_async(request_fan3, vector(request_fan3.Position.x, 0, user_party_leader.Position.z), 0.5, nil, true)

	character_util.move_to(request_fan1, move_pos1, 0.5, nil, true)
	character_util.move_to(request_fan2, move_pos2, 0.5, nil, true)
	character_util.move_to_async(request_fan3, move_pos3, 0.5, nil, true)

	character_util.set_direction(request_fan1, 'right')
	character_util.set_direction(request_fan2, 'right')
	character_util.set_direction(request_fan3, 'left')

	character_util.set_emotion(user_party_leader, { name = 'surprise' })
	character_util.set_anim(user_party_leader, { name = 'idle', loop = true })

	character_util.set_emotion(request_fan1, { name = 'smile' })
	character_util.set_emotion(request_fan2, { name = 'smile' })
	character_util.set_emotion(request_fan3, { name = 'smile' })
	character_util.set_anim(request_fan1, { name = 'sing', loop = true })
	character_util.set_anim(request_fan2, { name = 'sing', loop = true })
	character_util.set_anim(request_fan3, { name = 'sing', loop = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 저기, 혹시 영화쪽 사람이신가요?
	camera_util.resize_to(3.5, 0.3)
	character_util.jump(request_fan2, 0.5, 0.3)
	character_util.move_to(request_fan2, request_fan2.Position + unity_class.vector3.forward * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan2,
			{ key = self.request_fan_talk_1, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 그럼 부탁 좀 들어주세요!
	camera_util.resize_to(3.4, 0.3)
	character_util.jump(request_fan3, 0.5, 0.3)
	character_util.move_to(request_fan3, request_fan3.Position + unity_class.vector3.left * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_2, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 저흰 영화와 배우들을 너무 사랑해서 이 멀고 먼 베리우드까지 여행을 왔는데…
	camera_util.resize_to(3.3, 0.3)
	character_util.jump(request_fan1, 0.5, 0.3)
	character_util.move_to(request_fan1, request_fan1.Position + unity_class.vector3.right * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan1,
			{ key = self.request_fan_talk_3, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 막상 오니까 진짜 영화 촬영은 제대로 구경도 못하고… 촬영장에서 쫓겨나기나 하고…
	camera_util.resize_to(3.2, 0.3)
	character_util.jump(request_fan2, 0.5, 0.3)
	character_util.move_to(request_fan2, request_fan2.Position + unity_class.vector3.forward * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan2,
			{ key = self.request_fan_talk_4, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 이렇게 허무하게 갈 순 없어서, 뭔가 기념할만한 물건을 가져가고 싶단 말이죠?
	camera_util.resize_to(3.1, 0.3)
	character_util.jump(request_fan3, 0.5, 0.3)
	character_util.move_to(request_fan3, request_fan3.Position + unity_class.vector3.left * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_5, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 친필 사인이 된 영화 포스터라거나?
	camera_util.resize_to(3.0, 0.3)
	character_util.jump(request_fan1, 0.5, 0.3)
	character_util.move_to(request_fan1, request_fan1.Position + unity_class.vector3.right * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan1,
			{ key = self.request_fan_talk_6, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 실제 영화에 사용되었던 소품들이라거나?
	camera_util.resize_to(2.9, 0.3)
	character_util.jump(request_fan2, 0.5, 0.3)
	character_util.move_to(request_fan2, request_fan2.Position + unity_class.vector3.forward * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan2,
			{ key = self.request_fan_talk_7, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 우리 오빠의 흔적이 남은 물건들이라거나… 쿠후후…
	camera_util.resize_to(2.8, 0.3)
	character_util.jump(request_fan3, 0.5, 0.3)
	character_util.move_to(request_fan3, request_fan3.Position + unity_class.vector3.left * 0.1, 0.3, 1)
	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_8, skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	-- 이런 물건들을 찾으시면 저희한테 가져다 주시면 안될까요?
	camera_util.resize_to(2.6, 0.3)

	character_util.jump(request_fan1, 0.5, 0.3)
	character_util.move_to(request_fan1, request_fan1.Position + unity_class.vector3.right * 0.1, 0.3, 1)

	character_util.jump(request_fan2, 0.5, 0.3)
	character_util.move_to(request_fan2, request_fan2.Position + unity_class.vector3.forward * 0.1, 0.3, 1)

	character_util.jump(request_fan3, 0.5, 0.3)
	character_util.move_to(request_fan3, request_fan3.Position + unity_class.vector3.left * 0.1, 0.3, 1)

	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_9, skip = true, scale = 0.8, screen_pos = vector(-100, -150) })

	music_player:PlaySfxOneShot('01_small_jump_01')
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	-- 이렇게 부탁드릴게요~
	camera_util.resize_to(2.4, 0.3)

	character_util.jump(request_fan1, 0.5, 0.3)
	character_util.move_to(request_fan1, request_fan1.Position + unity_class.vector3.right * 0.1, 0.3, 1)

	character_util.jump(request_fan2, 0.5, 0.3)
	character_util.move_to(request_fan2, request_fan2.Position + unity_class.vector3.forward * 0.1, 0.3, 1)

	character_util.jump(request_fan3, 0.5, 0.3)
	character_util.move_to(request_fan3, request_fan3.Position + unity_class.vector3.left * 0.1, 0.3, 1)

	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_10, skip = true, scale = 0.8, screen_pos = vector(-100, -150) })

	character_util.set_direction(user_party_leader, 'left')
	character_util.set_anim(user_party_leader, { name = 'nod', loop = true })
	wait_for_sec(1)
	character_util.set_direction(user_party_leader, 'right')
	character_util.set_anim(user_party_leader, { name = 'nod', loop = true })
	wait_for_sec(1)

	character_util.set_direction(user_party_leader, 'down')
	character_util.remove_anim(user_party_leader)

	character_util.set_emotion(request_fan1, { name = 'awesome' })
	character_util.set_emotion(request_fan2, { name = 'awesome' })
	character_util.set_emotion(request_fan3, { name = 'awesome' })

	character_util.jump(request_fan1, 0.5, 0.5)
	character_util.jump(request_fan2, 0.5, 0.5)
	character_util.jump(request_fan3, 0.5, 0.5)

	camera_util.resize_to_default(0.5)

	character_util.move_to(request_fan1, move_pos1, 0.5)
	character_util.move_to(request_fan2, move_pos2, 0.5)
	character_util.move_to(request_fan3, move_pos3, 0.5)

	music_player:PlaySfxOneShot('01_jump_01')
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 야호!
	speech_bubble_util.show_speech_bubble(request_fan1,
			{ key = self.request_fan_talk_11, skip = true, screen_pos = vector(-100, 100) })

	wait_for_sec(1.5)

	speech_bubble_util.remove_bubble(request_fan1)
	speech_bubble_util.remove_bubble(request_fan2)
	speech_bubble_util.remove_bubble(request_fan3)

	-- 역시 해줄 줄 알았어!
	speech_bubble_util.show_speech_bubble_async(request_fan1,
			{ key = self.request_fan_talk_12, skip = true })

	-- 진짜 고마워요!
	speech_bubble_util.show_speech_bubble_async(request_fan2,
			{ key = self.request_fan_talk_13, skip = true })

	-- 그럼 저흰 여기서 기다리고 있을게요!
	speech_bubble_util.show_speech_bubble_async(request_fan3,
			{ key = self.request_fan_talk_14, skip = true })

	music_player:PlaySfx({ sfxName = '01_dash_01', loop = true, duration = 2 })
	-- 원래대로
	character_util.set_anim(request_fan1, { name = 'run', loop = true })
	character_util.set_anim(request_fan2, { name = 'run', loop = true })
	character_util.set_anim(request_fan3, { name = 'run', loop = true })

	character_util.move_to(request_fan1, pos1, 1.8, nil, true, true)
	character_util.move_to(request_fan2, vector(user_party_leader.Position.x, 0, pos2.z), 1, nil, true)
	character_util.move_to_async(request_fan3, vector(user_party_leader.Position.x + 1, 0, pos3.z), 1, nil, true)

	character_util.move_to(request_fan2, pos2, 1, nil, true)
	character_util.move_to_async(request_fan3, pos3, 1, nil, true)

	character_util.set_emotion(request_fan1, { name = 'greed' })
	character_util.set_anim(request_fan1, { name = 'eat', loop = true })

	character_util.set_emotion(request_fan2, { name = 'greed' })
	character_util.set_anim(request_fan2, { name = 'eat', loop = true })

	character_util.set_emotion(request_fan3, { name = 'greed' })
	character_util.set_anim(request_fan3, { name = 'eat', loop = true })

	self.request_fan_first = true

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 아이템을 팬에게 줌
function local_class:give_item(fan_name, select_number)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local fan = get_character(fan_name)

	local pos = fan.Position + unity_class.vector3.right * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	character_util.set_direction(fan, 'right')

	-- 오오오! 저희 오빠 물건을 가져오신 건가요?
	character_util.set_emotion(fan, { name = 'smile' })
	character_util.set_anim(fan, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(fan,
			{ key = self.request_fan_talk_15, skip = true })

	while true do
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		local wait = true
		local select = 0

		-- 사인을 가지고 있을 경우
		if self.get_sign_item then
			branches:Add({
				Text = game_string:GetString(self.sign_item_name),
				Tendency = CS.Oak.TalkTendency.Intellect,
				Callback = function()
					wait = false
					select = 1
				end })
		end

		-- 소품 총을 가지고 있을 경우
		if self.get_rifle_item then
			branches:Add({
				Text = game_string:GetString(self.rifle_item_name),
				Tendency = CS.Oak.TalkTendency.Mercy,
				Callback = function()
					wait = false
					select = 2
				end })
		end

		-- 손수건을 가지고 있을 경우
		if self.get_handkerchief_item then
			branches:Add({
				Text = game_string:GetString(self.handkerchief_item_name),
				Tendency = CS.Oak.TalkTendency.Brutal,
				Callback = function()
					wait = false
					select = 3
				end })
		end

		-- 그만 둔다.
		branches:Add({
			Text = game_string:GetString('movie_2_request_fan_find_talk_3'),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				wait = false
				select = 4
			end })

		ui_overlay_util.push_overlay(fan, branches)

		while wait do
			coroutine.yield(nil)
		end

		if select ~= 4 then
			-- 오오, 이것은…?
			camera_util.resize_to(3, 2)
			music_player:PlaySfxOneShot('01_gatcha_point_01')
			character_util.set_emotion(fan, { name = 'greed' })
			character_util.set_anim(fan, { name = 'sing', loop = true })
			speech_bubble_util.show_speech_bubble_async(fan,
					{ key = self.request_fan_talk_18, skip = false })

			camera_util.resize_to_default(0.3)
		end

		local success_check = false

		-- 사인을 줬을 때
		if select == 1 then
			if select ~= select_number then
				-- 사인 포스터?
				music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
				character_util.set_emotion(fan, { name = 'idle' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_fail_talk_1, skip = true, bubble_direction = 'rb' })

				-- 에이, 뭐야… 이런건 집에 10개도 넘게 있다고요.
				music_player:PlaySfxOneShot('03_dialogue_negative_02')
				character_util.set_emotion(fan, { name = 'tired' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_fail_talk_2, skip = true })

				-- 혹시 다른 물건은 없나요?
				character_util.set_emotion(fan, { name = 'smile' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_fail_talk_3, skip = true })
			else
				-- 사인 포스터?
				music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_success_talk_1, skip = true, bubble_direction = 'rb' })

				-- 와우! 이 귀한걸…!
				music_player:PlaySfxOneShot('03_dialogue_positive_01')
				character_util.set_emotion(fan, { name = 'awesome' })
				character_util.set_anim(fan, { name = 'victory_extra', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_success_talk_2, skip = true })

				-- 정말 고마워요!
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'sing', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_sign_success_talk_3, skip = true })

				success_check = true
				self.request_success_1 = true
				self.get_sign_item = false
				fan.Interactable:RemoveRelatedEvent(self.cs_controller)
				fan.Interactable.Talk = self.request_fan_talk_20
			end
		end

		-- 소품 총을 줬을 때
		if select == 2 then
			if select ~= select_number then
				-- 소품 총?
				music_player:PlaySfxOneShot('03_dialogue_negative_02')
				character_util.set_emotion(fan, { name = 'idle' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_fail_talk_1, skip = true, bubble_direction = 'rb' })

				-- 이 반질반질한 사용감… 확실히 a급이지만…
				character_util.set_anim(fan, { name = 'cross_arm', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_fail_talk_2, skip = true })

				-- 그래도 이런건 집에 5개나 있어요.
				character_util.set_emotion(fan, { name = 'tired' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_fail_talk_3, skip = true })

				-- 혹시 다른 물건은 없나요?
				character_util.set_emotion(fan, { name = 'smile' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_fail_talk_4, skip = true })
			else
				-- 소품 총?
				music_player:PlaySfxOneShot('03_dialogue_negative_02')
				character_util.set_emotion(fan, { name = 'surprise' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_success_talk_1, skip = true, bubble_direction = 'rb' })

				-- 이 반질반질한 손잡이… 확실히 a급이야!
				character_util.set_emotion(fan, { name = 'awesome' })
				character_util.set_anim(fan, { name = 'victory_extra', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_success_talk_2, skip = true })

				-- 정말 고마워요!
				music_player:PlaySfxOneShot('03_dialogue_positive_01')
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'sing', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_rifle_success_talk_3, skip = true })

				success_check = true
				self.request_success_2 = true
				self.get_rifle_item = false
				fan.Interactable:RemoveRelatedEvent(self.cs_controller)
				fan.Interactable.Talk = self.request_fan_talk_20
			end
		end

		-- 손수건을 줬을 때
		if select == 3 then
			if select ~= select_number then
				-- 손수건?
				character_util.set_emotion(fan, { name = 'idle' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_fail_talk_1, skip = true, bubble_direction = 'rb' })

				music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
				-- 뭐가 묻은거야? 으윽, 더러워...
				character_util.set_emotion(fan, { name = 'tired' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_fail_talk_2, skip = true })

				-- 이런거 말고… 다른 물건은 없나요?
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_fail_talk_3, skip = true })
			else
				-- 손수건?
				character_util.set_emotion(fan, { name = 'idle' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_success_talk_1, skip = true, bubble_direction = 'rb' })

				music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
				-- 뭐가 묻은거야? 으윽, 더러워...
				character_util.set_emotion(fan, { name = 'tired' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_success_talk_2, skip = true })

				-- 잠깐, 이 냄새는…?
				music_player:PlaySfxOneShot('01_gatcha_point_01')

				local eat = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
				character_util.set_emotion(fan, { name = 'idle' })
				character_util.set_anim(fan, { name = 'eat', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_success_talk_3, skip = true })
				eat:Stop()

				-- 우리 오빠가 쓴 손수건이잖아?!
				music_player:PlaySfxOneShot('01_gatcha_point_01')
				character_util.set_emotion(fan, { name = 'greed' })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_success_talk_4, skip = true })

				-- 그래! 바로 이런 걸 원했어!
				character_util.set_emotion(fan, { name = 'awesome' })
				character_util.set_anim(fan, { name = 'success', loop = true, sfx_name = "01_player_jump_01" })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = self.give_handkerchief_success_talk_5, skip = true })

				success_check = true
				self.request_success_3 = true
				self.get_handkerchief_item = false
				fan.Interactable:RemoveRelatedEvent(self.cs_controller)

				fan.Interactable.Talk = self.request_fan_talk_20
			end
		end

		if success_check then
			break
		elseif select ~= 4 then
			if select_number == 1 then
				-- 혹시 친필 사인이 된 영화 포스터같은건 없나요?
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = 'movie_2_request_fan_want_1', skip = true })
			elseif select_number == 2 then
				-- 실제 영화에 사용된 소품같은건 없나요?
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = 'movie_2_request_fan_want_2', skip = true })
			elseif select_number == 3 then
				-- 우리 오빠의 흔적이 남은 물건같은건 없나요?
				character_util.set_emotion(fan, { name = 'smile' })
				character_util.set_anim(fan, { name = 'idle', loop = true })
				speech_bubble_util.show_speech_bubble_async(fan,
						{ key = 'movie_2_request_fan_want_3', skip = true })
			end
		end

		if select == 4 then
			-- 에이, 뭐야…
			character_util.set_emotion(fan, { name = 'tired' })
			speech_bubble_util.show_speech_bubble_async(fan,
					{ key = self.request_fan_talk_16, skip = true })

			--[[
			-- 괜히 귀찮게 하지 마요.
			character_util.set_direction(fan, 'left')
			speech_bubble_util.show_speech_bubble_async(fan,
					{ key = self.request_fan_talk_17, skip = true })
			]]
			break
		end
	end
	character_util.set_direction(fan, 'left')
	character_util.set_emotion(fan, { name = 'greed' })
	character_util.set_anim(fan, { name = 'eat', loop = true })

	-- 3명에게 올바른 아이템을 줬을 때
	if self.request_success_1 and self.request_success_2 and self.request_success_3 then

		local request_fan1 = get_character(self.request_fan1_name)
		local request_fan2 = get_character(self.request_fan2_name)
		local request_fan3 = get_character(self.request_fan3_name)

		local move_pos = request_fan2.Position + unity_class.vector3.right * 1.5
		user_party:PositionParty(move_pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		character_util.set_direction(request_fan1, 'right')
		character_util.set_direction(request_fan2, 'right')
		character_util.set_direction(request_fan3, 'right')

		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		-- 정말 고마워요! 보답으로 이거 드릴게요!
		character_util.set_emotion(request_fan1, { name = 'smile' })
		character_util.set_anim(request_fan1, { name = 'sing', loop = true })

		character_util.set_emotion(request_fan2, { name = 'smile' })
		character_util.set_anim(request_fan2, { name = 'sing', loop = true })

		character_util.set_emotion(request_fan3, { name = 'smile' })
		character_util.set_anim(request_fan3, { name = 'sing', loop = true })

		speech_bubble_util.show_speech_bubble_async(request_fan2,
				{ key = self.request_fan_talk_19, skip = true })

		-- 스타피스 등장
		local star_piece = get_field_object(self.request_star_piece_name)
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(request_fan2.Position))
		coroutine.yield(coroutine_class.wait_for_sec(2.0))

		character_util.set_direction(request_fan1, 'left')
		character_util.set_direction(request_fan2, 'left')
		character_util.set_direction(request_fan3, 'left')

		character_util.set_emotion(request_fan1, { name = 'greed' })
		character_util.set_anim(request_fan1, { name = 'eat', loop = true })

		character_util.set_emotion(request_fan2, { name = 'greed' })
		character_util.set_anim(request_fan2, { name = 'eat', loop = true })

		character_util.set_emotion(request_fan3, { name = 'greed' })
		character_util.set_anim(request_fan3, { name = 'eat', loop = true })

		-- 어디, 다른건 없나...?
		request_fan1.Interactable.Talk = self.request_fan_talk_20
		request_fan2.Interactable.Talk = self.request_fan_talk_20
		request_fan3.Interactable.Talk = self.request_fan_talk_20

		self.saw_request_fan = true
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 음식 파는 상인과 대화
function local_class:sell_food(npc_name, food_select)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local food_npc = get_character(npc_name)

	local pos = food_npc.Position + unity_class.vector3.back * 2
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 0.5, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	character_util.set_emotion(food_npc, { name = 'smile' })
	character_util.set_anim(food_npc, { name = 'idle', loop = true })

	if food_select == 1 then
		-- 어서오세요! 맛있는 아이스크림 하나 어떠세요?
		speech_bubble_util.show_speech_bubble_async(food_npc,
				{ key = self.icecream_sell_npc_talk_1, skip = true })


		-- 선택지: 아이스크림(500골드) / 그만둔다.
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		local wait = true
		local buy = false

		branches:Add({
			Text = game_string:GetString(self.icecream_sell_price),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait = false
				buy = true
			end })

		branches:Add({
			Text = game_string:GetString(self.not_buy_food),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				wait = false
				buy = false
			end })

		ui_overlay_util.push_overlay(food_npc, branches)

		while wait do
			coroutine.yield(nil)
		end

		if buy then
			if CS.Oak.User.Me.Gold >= 500 then
				coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, 500))

				music_player:PlaySfxOneShot('03_drop_gold_01')
				-- 감사합니다! 또 오세요!
				speech_bubble_util.show_speech_bubble(food_npc,
						{ key = self.icecream_sell_npc_talk_2, skip = true })

				character_util.set_direction(user_party_leader, 'left')
				character_util.set_emotion(user_party_leader, { name = 'smile' })
				character_util.set_anim(user_party_leader, { name = 'eat', loop = true })
				coroutine.yield(coroutine_class.wait_for_sec(2))

				character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })
				coroutine.yield(coroutine_class.wait_for_sec(1.5))

				-- 플레이어 체력 회복
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = nil
				heal_info.target = user_party_leader
				heal_info.heal = math.floor(user_party_leader.FieldObjectStatsBehaviour.HP * 0.1)

				command_util.execute_heal(heal_info)
			else
				-- 죄송해요… 아이스크림은 500골드랍니다.
				speech_bubble_util.show_speech_bubble_async(food_npc,
						{ key = self.icecream_sell_npc_talk_3, skip = true })
			end
		end
	end

	if food_select == 2 then
		-- 어서오세요! 맛있는 레몬주스 하나 어떠세요?
		speech_bubble_util.show_speech_bubble_async(food_npc,
				{ key = self.hotdog_sell_npc_talk_1, skip = true })

		-- 선택지: 핫도그(500골드) / 그만둔다.
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		local wait = true
		local buy = false

		branches:Add({
			Text = game_string:GetString(self.hotdog_sell_price),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait = false
				buy = true
			end })

		branches:Add({
			Text = game_string:GetString(self.not_buy_food),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				wait = false
				buy = false
			end })

		ui_overlay_util.push_overlay(food_npc, branches)

		while wait do
			coroutine.yield(nil)
		end

		if buy then
			if CS.Oak.User.Me.Gold >= 500 then
				coroutine.yield(CS.Oak.StageApiRouter.SendPayGold(stage.StageId, 500))

				music_player:PlaySfxOneShot('03_drop_gold_01')

				local sign_id = 20165
				-- 주스 드롭
				local drop_item = drop_item_util.create_item(
						{ pos = food_npc.Position,
						  target = user_party_leader.Position + vector(-0.5, 0, 0.3),
						  itemid = sign_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true })

				coroutine.yield(coroutine_class.wait_for_sec(1.5))

				-- 감사합니다! 또 오세요!
				speech_bubble_util.show_speech_bubble(food_npc,
						{ key = self.hotdog_sell_npc_talk_2, skip = true })

				music_player:PlaySfxOneShot('01_drinking_01')
				character_util.set_direction(user_party_leader, 'left')
				character_util.set_emotion(user_party_leader, { name = 'smile' })
				character_util.set_anim(user_party_leader, { name = 'eat', loop = true })
				coroutine.yield(coroutine_class.wait_for_sec(2))

				drop_item.ConsumeTarget = user_party_leader

				music_player:PlaySfxOneShot('01_stage_intro_jump_01')
				character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })
				coroutine.yield(coroutine_class.wait_for_sec(1.5))

				music_player:PlaySfxOneShot('02_magic_heal_02')
				-- 플레이어 체력 회복
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = nil
				heal_info.target = user_party_leader
				heal_info.heal = math.floor(user_party_leader.FieldObjectStatsBehaviour.HP * 0.1)

				command_util.execute_heal(heal_info)
			else
				-- 죄송해요… 핫도그는 500골드랍니다.
				speech_bubble_util.show_speech_bubble_async(food_npc,
						{ key = self.hotdog_sell_npc_talk_3, skip = true })
			end
		end
	end

	character_util.set_emotion(food_npc, { name = 'idle' })

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
