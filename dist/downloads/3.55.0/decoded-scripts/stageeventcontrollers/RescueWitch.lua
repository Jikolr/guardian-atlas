local local_class = newclass('RescueWitchController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.cat_name = 'rw_cat'
	self.dog_name = 'rw_dog'
	self.dog_human_name = 'rw_dog_human'
	self.rat_name = 'rw_rat'
	self.witch_name = 'rw_witch'
	self.cauldron_name = 'witch_cauldron'
	self.cook_book_name = 'cook_book_table'
	self.lizard_table_name = 'lizard_table_left'
	self.lizard_table_2_name = 'lizard_table_right'
	self.flower_name = 'planted_flower'

	self.breakable_pot_name = 'pot1_1'

	self.rat_zone_name = 'rw_rat_zone'

	self.potion_item_id_list = {
		20158, 20159, 20160
	}

	-- -1 : 물약 없음, 1 : 변신 물약, 2 : 정화의 물약, 3 : 에너지 음료
	self.potion_id = -1

	self.potion_count_arr = {
		0, 0, 0
	}

	self.ingredient_id_arr = {
		20041, 20043, 20042	-- 도마뱀, 치즈, 꽃
	}

	self.is_have_ingredient_arr = {
		false, false, false
	}

	self.is_seen_cook_book = false
	self.is_seen_student_talk = false

	self.is_rat_run_away = false
	self.is_dog_run_away = false

	self.is_cat_in_zone = false
	self.cat_leader_attack_duration = 0.5
	self.is_cat_leader_attacking = false
	self.cat_party_duration = 5

	self.cat_timer_coroutine = nil

	self.more_ingredient_nar_key = 'nightmare_magicschool_3_rescue_witch_2'
	self.use_carrying_potion_nar_key = 'nightmare_magicschool_3_rescue_witch_3'
	self.cauldron_repeat_nar_key = 'nightmare_magicschool_3_rescue_witch_1'
	self.cook_book_repeat_nar_key = 'nightmare_magicschool_3_rescue_witch_4'

	self.make_potion_keys = {
		'nightmare_magicschool_3_rescue_witch_8',
		'nightmare_magicschool_3_rescue_witch_9',
		'nightmare_magicschool_3_rescue_witch_10',
	}

	self.put_ingredient_keys = {
		'nightmare_magicschool_3_rescue_witch_29_0',
		'nightmare_magicschool_3_rescue_witch_29_1',
		'nightmare_magicschool_3_rescue_witch_29_2'
	}

	self.feed_potion_keys = {
		'nightmare_magicschool_3_rescue_witch_26_0',
		'nightmare_magicschool_3_rescue_witch_26_1',
		'nightmare_magicschool_3_rescue_witch_26_2'
	}

	self.potion_recipe_bit_arr = {
		10, 12, 14
	}

	self.potion_recipe_arr = {
		{ 1, 3 },	-- 변신
		{ 2, 3 },	-- 정화
		{ 1, 2, 3 }	-- 에너지
	}

	self.potion_taste_nar_keys = {
		'nightmare_magicschool_3_rescue_witch_5',
		'nightmare_magicschool_3_rescue_witch_6',
		'nightmare_magicschool_3_rescue_witch_7'
	}

	self.give_potion_key = 'nightmare_magicschool_3_rescue_witch_13'
	self.dont_give_potion_key = 'nightmare_magicschool_3_rescue_witch_14'

	self.is_already_got_star_piece = false
	self.star_piece_name = 'witch_star_piece'

	self.hissing_sfx = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')

	local cat = get_character(self.cat_name)
	local dog = get_character(self.dog_name)
	local rat = get_character(self.rat_name)
	local witch = get_character(self.witch_name)
	local cauldron = get_field_object(self.cauldron_name)
	local cook_book = get_field_object(self.cook_book_name)
	local lizard_table = get_field_object(self.lizard_table_name)
	local lizard_table_2 = get_field_object(self.lizard_table_2_name)
	local flower = get_field_object(self.flower_name)

	if cat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		cat.Interactable:AddListener(self.cs_controller)
	end

	if dog.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		dog.Interactable:AddListener(self.cs_controller)
	end

	if rat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		rat.Interactable:AddListener(self.cs_controller)
	end

	if witch.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		witch.Interactable:AddListener(self.cs_controller)
	end

	cauldron.Interactable = CS.Oak.PublishInteractable.Create()
	cook_book.Interactable = CS.Oak.PublishInteractable.Create()
	lizard_table.Interactable = CS.Oak.PublishInteractable.Create()
	lizard_table_2.Interactable = CS.Oak.PublishInteractable.Create()
	flower.Interactable = CS.Oak.PublishInteractable.Create()

	unity_object_pool.GetOrCreate('FX_dead')
	unity_object_pool.GetOrCreate('FX_BuffMagic_Target')
	unity_object_pool.GetOrCreate('FX_hit_me')
	unity_object_pool.GetOrCreate('FX_explosion_small')
	unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	unity_object_pool.GetOrCreate('fx_common_event_transform')
end

function local_class:on_load_resource_routine()
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	local cat = get_character(self.cat_name)
	local dog = get_character(self.dog_name)
	local rat = get_character(self.rat_name)
	local witch = get_character(self.witch_name)
	local cauldron = get_field_object(self.cauldron_name)
	local cook_book = get_field_object(self.cook_book_name)
	local lizard_table = get_field_object(self.lizard_table_name)
	local lizard_table_2 = get_field_object(self.lizard_table_2_name)
	local flower = get_field_object(self.flower_name)

	if cat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		cat.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if dog.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		dog.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if rat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		rat.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if witch.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		witch.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	cauldron.Interactable = CS.Oak.NonInteractable.Instance
	cook_book.Interactable = CS.Oak.NonInteractable.Instance
	lizard_table.Interactable = CS.Oak.NonInteractable.Instance
	lizard_table_2.Interactable = CS.Oak.NonInteractable.Instance
	flower.Interactable = CS.Oak.NonInteractable.Instance

	if self.lizards ~= nil then
		self.lizards = nil
	end

	if self.planted_flower ~= nil then
		self.planted_flower = nil
	end

	if self.cat_timer_coroutine ~= nil then
		stop_coroutine(self.cat_timer_coroutine)
		self.cat_timer_coroutine = nil
	end

	self.potion_taste_nar_keys = nil
	self.potion_recipe_bit_arr = nil
	self.potion_recipe_arr = nil
	self.feed_potion_keys = nil
	self.put_ingredient_keys = nil
	self.make_potion_keys = nil
	self.is_have_ingredient_arr = nil
	self.ingredient_id_arr = nil
	self.potion_count_arr = nil
	self.potion_item_id_list = nil
	self.hissing_sfx = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	local is_cat = lua_helper.reference_equals(user_party.Leader, get_character('cat_party_1'))

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(user_party.Leader, e.FieldObject) then
			if e.Zone.Name == self.rat_zone_name then
				if not self.is_rat_run_away and is_cat then
					self.is_cat_in_zone = true
					character_util.shake(get_character(self.rat_name), 0.08, 9999)
				end
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if not self.is_rat_run_away then
			if e.FullLeave and lua_helper.reference_equals(user_party.Leader, e.FieldObject) and is_cat then
				self.is_cat_in_zone = false
				character_util.stop_shake(get_character(self.rat_name))
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)

	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		if string.find(e.FieldObject.Name, self.breakable_pot_name) then
			self:drop_cheese(e.FieldObject.Position)
		end

	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		if e.Item.ItemId == self.ingredient_id_arr[1] then
			self.is_have_ingredient_arr[1] = true
		elseif e.Item.ItemId == self.ingredient_id_arr[2] then
			self.is_have_ingredient_arr[2] = true
		elseif e.Item.ItemId == self.ingredient_id_arr[3] then
			self.is_have_ingredient_arr[3] = true
		end

	elseif lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		if e.TouchEventType == CS.Oak.TouchEventType.Action1TouchDown
				and is_cat then
			if self:try_cat_leader_attack() and self.is_cat_in_zone then
				if not self.is_rat_run_away then
					self.is_rat_run_away = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rat_run_away, self))
				end
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.BattleStartEvent) then
		if is_cat then
			self:restore_origin_party()
		end

	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self.is_already_got_star_piece = stage_progress:HasStarPiece(self.star_piece_name)
		if self.is_already_got_star_piece then
			local cat = get_character(self.cat_name)
			local witch = get_character(self.witch_name)

			character_util.set_position(witch, cat.Position)
			character_util.set_direction(witch, 'down')

			character_util.set_position(cat, vector(999, 0, 999))
		end

		character_util.set_active_state(get_character(self.dog_human_name), 'disabled')

		self:set_items()
	end

	return false
end

function local_class:on_interact_event(e)
	local cat = get_character(self.cat_name)
	local dog = get_character(self.dog_name)
	local rat = get_character(self.rat_name)
	local witch = get_character(self.witch_name)
	local cauldron = get_field_object(self.cauldron_name)
	local cook_book = get_field_object(self.cook_book_name)
	local lizard_table = get_field_object(self.lizard_table_name)
	local lizard_table_2 = get_field_object(self.lizard_table_2_name)
	local flower = get_field_object(self.flower_name)

	local carrying_types = self:cur_carrying_potion_types()
	local type_count = #carrying_types

	if lua_helper.reference_equals(e.Target, cat) then
		if  type_count > 0 then
			sp_util.play_normal_screenplay(self.try_give_to_cat, self, carrying_types)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_with_cat, self))
		end

	elseif lua_helper.reference_equals(e.Target, dog) then
		if type_count > 0 then
			sp_util.play_normal_screenplay(self.try_give_to_dog, self, carrying_types)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_with_dog, self))
		end

	elseif lua_helper.reference_equals(e.Target, rat) then
		if type_count > 0 then
			sp_util.play_normal_screenplay(self.try_give_to_rat, self, carrying_types)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_with_rat, self))
		end

	elseif lua_helper.reference_equals(e.Target, witch) then
		speech_bubble_util.show_speech_bubble(witch, {key = 'nightmare_magicschool_3_rescue_witch_23'})

	elseif lua_helper.reference_equals(e.Target, cauldron) then
		local ingredient_count = 0
		for k, v in pairs(self.is_have_ingredient_arr) do
			if v then
				ingredient_count = ingredient_count + 1
			end
		end

		if self.is_seen_cook_book and ingredient_count >= 2 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.make_potion, self))
		elseif not self.is_seen_cook_book then
			sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.cauldron_repeat_nar_key})
		else
			sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.more_ingredient_nar_key})
		end

	elseif lua_helper.reference_equals(e.Target, cook_book) then
		self.is_seen_cook_book = true
		sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.cook_book_repeat_nar_key})

	elseif lua_helper.reference_equals(e.Target, lizard_table)
		or lua_helper.reference_equals(e.Target, lizard_table_2) then
		self:drop_lizard()

	elseif lua_helper.reference_equals(e.Target, flower) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_flower, self))
	end
end

function local_class:set_items()
	local lizard_id = self.ingredient_id_arr[1]
	self.lizards = {
		drop_item_util.create_item({ pos = { 48, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id }),
		drop_item_util.create_item({ pos = { 48.5, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id }),
		drop_item_util.create_item({ pos = { 49, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id }),
		drop_item_util.create_item({ pos = { 50, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id }),
		drop_item_util.create_item({ pos = { 50.5, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id }),
		drop_item_util.create_item({ pos = { 51, 0.8, 33 }, notforinven = true,
									 lootstate = 'dontfindlooter', itemid = lizard_id })
	}

	local flower = get_field_object(self.flower_name)
	flower.Hitbox = CS.Oak.Hitbox(vector(0.7, 1, 0.7))
	flower.Position = vector_util.get_x0z(flower.Position)
	self.planted_flower = drop_item_util.create_item({ notforinven = true, itemid = self.ingredient_id_arr[3],
								pos = vector_util.get_x0z(flower.Position),
								lootstate = 'dontfindlooter'})

	-- 괴식 요리 책 얹음
	drop_item_util.create_item(
			{pos = vector_util.get_x0z(get_field_object(self.cook_book_name).Position, 0),
			 notforinven = true, lootstate = 'dontfindlooter', itemid = 20044})

	local pots = {
		'pot1_1_1',
		'pot1_1_2',
		'pot1_1_3',
		'pot1_1_4',
	}

	for i = 1, 4 do
		local pot = get_field_object(pots[i])
		unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(pot.Position + vector(0, 0.5, 0),
				unity_class.quaternion.identity, pot.Transform)
	end
end

function local_class:drop_lizard()
	if self.lizards ~= nil then
		for i = 1, #self.lizards do
			self.lizards[i].State = CS.Oak.DropItem.LootState.FindLooter
			self.lizards[i].ConsumeTarget = user_party_leader
		end
		self.lizards = nil
	end

	local table = get_field_object(self.lizard_table_name)
	local table_2 = get_field_object(self.lizard_table_2_name)
	table.Interactable = CS.Oak.NonInteractable.Instance
	table_2.Interactable = CS.Oak.NonInteractable.Instance
end

function local_class:drop_flower()
	party_util.stop_and_disable_control()

	local flower = get_field_object(self.flower_name)
	if flower.Position.x < user_party_leader.Position.x then
		character_util.set_direction(user_party_leader, 'left')
	else
		character_util.set_direction(user_party_leader, 'right')
	end

	music_player_util.play_sfx({sfx_name = '03_equipping_01', duration = 1.5, fade_out_time = 0.5})
	character_util.set_anim(user_party_leader, {name = 'eat', loop = true})

	flower.Interactable = CS.Oak.NonInteractable.Instance
	flower.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	flower.ActiveState = active_state('disabled')

	wait_for_sec(1)

	character_util.remove_anim(user_party_leader)

	if self.planted_flower ~= nil then
		self.planted_flower:ConsumeComplete()
		self.planted_flower = nil
	end

	local x0z = vector_util.get_x0z(flower.Position)

	music_player_util.play_sfx({sfx_name = '01_bubble_pop_01'})
	drop_item_util.create_item({ pos = x0z, target = x0z,
										 notforinven = true, itemid = self.ingredient_id_arr[3] })

	party_util.reset_controllers()
end

function local_class:drop_cheese(drop_pos)
	local drop_item = drop_item_util.create_item({ pos = drop_pos, target = drop_pos,
												   notforinven = true, itemid = self.ingredient_id_arr[2]})
	drop_item.ConsumeTarget = user_party_leader
end

function local_class:talk_with_cat()
	local cat = get_character(self.cat_name)

	if cat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		cat.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	music_player_util.play_sfx({sfx_name = '01_cat_meow_01', parent = cat})
	speech_bubble_util.show_speech_bubble_async(cat, {key = 'nightmare_magicschool_3_rescue_witch_15'})

	if cat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		cat.Interactable:AddListener(self.cs_controller)
	end
end

function local_class:cur_carrying_potion_types()
	local carrying_types = {}

	for k, v in pairs(self.potion_count_arr) do
		if v > 0 then
			table.insert(carrying_types, k)
		end
	end

	return carrying_types
end

function local_class:talk_with_rat()
	local rat = get_character(self.rat_name)

	if rat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		rat.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	music_player_util.play_sfx({sfx_name = '01_mouse_01', parent = rat})

	speech_bubble_util.show_speech_bubble(rat, {key = 'nightmare_magicschool_3_rescue_witch_16'})
	character_util.set_anim(rat, {name = 'jingak', loop = false, sfx_name = '01_hit_npc_01'})
	character_util.set_emotion(rat, {name = 'mad'})

	wait_for_sec(1)

	character_util.remove_anim_and_emotion(rat)
	speech_bubble_util.remove_bubble(rat)

	if rat.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		rat.Interactable:AddListener(self.cs_controller)
	end
end

function local_class:talk_with_dog()
	local dog = get_character(self.dog_name)

	if dog.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		dog.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	character_util.set_anim(dog, {name = 'happy', loop = true})
	character_util.set_emotion(dog, {name = 'smile'})
	music_player_util.play_sfx({sfx_name = '01_pet_bark_01', parent = dog})

	speech_bubble_util.show_speech_bubble_async(dog, {key = 'nightmare_magicschool_3_rescue_witch_17'})

	character_util.remove_anim_and_emotion(dog)

	if dog.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		dog.Interactable:AddListener(self.cs_controller)
	end
end

-- 포션 만들기 시작
function local_class:make_potion()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local cauldron = get_field_object(self.cauldron_name)
	party_util.align_party(cauldron.Position, 'left')

	local data = {}
	local ingredient_list = {}
	local put_bit = 0
	local cauldron_pos = cauldron.Position + vector(0.8, 0.5, 0)
	local leader_pos = user_party_leader.Position

	for k, v in pairs(self.is_have_ingredient_arr) do
		if v then
			local branch = { self.put_ingredient_keys[k] }
			table.insert(data, branch)
			table.insert(ingredient_list, k)
		end
	end

	local result_1 = choose_util.play_choose_event(data)
	local ingredient_1 = ingredient_list[result_1]
	put_bit = put_bit + 2 ^ ingredient_1

	music_player_util.play_sfx({sfx_name = '01_throw_01'})
	character_util.set_anim(user_party_leader, {name = 'throw', remove_after = 0.3})
	drop_item_util.create_item({pos = leader_pos, target = cauldron_pos,
								itemid = self.ingredient_id_arr[ingredient_1],
								notforinven = true}).ConsumeTarget = cauldron

	table.remove(data, result_1)
	table.remove(ingredient_list, result_1)

	wait_for_sec(0.5)

	local result_2 = choose_util.play_choose_event(data)
	local ingredient_2 = ingredient_list[result_2]
	put_bit = put_bit + 2 ^ ingredient_2

	music_player_util.play_sfx({sfx_name = '01_throw_01'})
	character_util.set_anim(user_party_leader, {name = 'throw', remove_after = 0.3})
	drop_item_util.create_item({pos = leader_pos, target = cauldron_pos,
								itemid = self.ingredient_id_arr[ingredient_2],
								notforinven = true}).ConsumeTarget = cauldron

	table.remove(data, result_2)
	table.remove(ingredient_list, result_2)
	-- 요리를 시작한다.
	table.insert(data, { 'nightmare_magicschool_3_rescue_witch_30' })

	wait_for_sec(0.5)

	local result_3 = choose_util.play_choose_event(data)

	if result_3 ~= #data then
		local ingredient_3 = ingredient_list[result_3]
		put_bit = put_bit + 2 ^ ingredient_3

		music_player_util.play_sfx({sfx_name = '01_throw_01'})
		character_util.set_anim(user_party_leader, {name = 'throw', remove_after = 0.3})
		drop_item_util.create_item({pos = leader_pos, target = cauldron_pos,
									itemid = self.ingredient_id_arr[ingredient_3],
									notforinven = true}).ConsumeTarget = cauldron

		table.remove(data, result_3)
		table.remove(ingredient_list, result_3)

		wait_for_sec(0.5)

		choose_util.play_choose_event(data)
	end

	local potion_index = -1
	-- 현재 만든 결과물이 레시피 중에 일치하는 것이 있는지 확인
	for k, v in pairs(self.potion_recipe_bit_arr) do
		if v == put_bit then
			potion_index = k
			break
		end
	end

	music_player_util.play_sfx({sfx_name = '01_boiling_01', duration = 2, fade_out_time = 0.3})
	character_util.set_anim(user_party_leader, {name = 'eat', loop = true})
	yield_return_func(self.shake_cauldron, self, 2)
	character_util.remove_anim(user_party_leader)

	if potion_index > 0 then
		music_player_util.play_sfx({sfx_name = '03_treasure_item_popup_01'})

		local effect = unity_object_pool.GetOrCreate('FX_BuffMagic_Target')
				:Instantiate(vector_util.get_x0z(cauldron.Position) + vector(0.5, 1, 0.2))
		effect.transform.localScale = vector(1, 1, 0.7)

		local item_data = game_data_service.GetData('ItemData')
		drop_item_util.create_item({pos = cauldron_pos,
									target = user_party_leader.Position + vector(0.3, 0, 0),
									notforinven = true,
									itemid = self.potion_item_id_list[potion_index]}).ConsumeTarget = user_party_leader

		wait_for_sec(2)

		yield_return_func(self.try_give_to_me, self, potion_index)
	else	-- 일치하는 레시피가 없을 때(잘못 만든 경우)
		music_player_util.play_sfx({sfx_name = '02_explosion_water_01'})
		local effect = unity_object_pool.GetOrCreate('FX_explosion_small')
				:Instantiate(vector_util.get_x0z(cauldron.Position) + vector(0.5, 1, 0.2))
		effect.transform.localScale = vector(1, 1, 0.7)

		party_util.set_emotion({name = 'surprise'})
		party_util.set_anim({name = 'embarrassed', loop = true})

		music_player_util.play_sfx({sfx_name = '03_runaway_01'})
		for i = 0, user_party.Count - 1 do
			character_util.normal_jump(user_party[i])
		end

		wait_for_sec(1)

		party_util.remove_emotion()
		party_util.remove_animation()

		field_ui_util.show_narration_async({ key = 'nightmare_magicschool_3_rescue_witch_31'})

		party_util.reset_controllers()
		field_ui_manager:Show()
	end
end

-- 3d인 친구라 직접 흔들어줬음
function local_class:shake_cauldron(duration)
	coroutine.yield(nil)

	local cauldron = get_field_object(self.cauldron_name)

	local origin_pos = cauldron.Position

	local pos_list = {
		vector(-0.02, 0, 0),
		vector(-0.01, 0, 0),
		vector(0, 0, 0),
		vector(0.01, 0, 0),
		vector(0.02, 0, 0)
	}

	local cur_idx = 3
	local dif = 1
	local cur_time = unity_class.time.time

	while unity_class.time.time - cur_time < duration do
		cur_idx = cur_idx + dif
		if cur_idx > 5 then
			cur_idx = 5
			dif = -1
		elseif cur_idx < 1 then
			cur_idx = 1
			dif = 1
		end

		cauldron.Position = origin_pos + pos_list[cur_idx]
		coroutine.yield(nil)
	end

	cauldron.Position = origin_pos
end

-- 내가 먹음
function local_class:try_give_to_me(potion_index)
	-- 물약을 마셔본다. / 물약을 마시지 않는다.
	local result = choose_util.play_choose_event({
		{'nightmare_magicschool_3_rescue_witch_11', 'brutal'}, {'nightmare_magicschool_3_rescue_witch_12', 'mercy'}
	})

	if result == 1 then
		music_player_util.play_sfx({sfx_name = '01_drinking_01'})
		character_util.set_anim(user_party_leader, {name = 'eat', loop = true})
		wait_for_sec(1)

		field_ui_util.show_narration_async({ key = self.potion_taste_nar_keys[potion_index]})

		character_util.remove_anim(user_party_leader)

		music_player_util.play_sfx({sfx_name = '01_rustle_01'})
		character_util.shake(user_party_leader, 0.05, 2)

		-- 변신 물약을 먹었을 때만 변신 이펙트 보여줌
		if potion_index == 1 then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.fade_color, self, user_party_leader, 2, true))
		end

		music_player_util.play_sfx({sfx_name = '03_dialogue_tipsy_01'})
		character_util.show_emoticon(user_party_leader, nil, 'annoyed')

		wait_for_sec(1.5)

		-- 변신 물약 먹음
		if potion_index == 1 then
			yield_return_func(self.change_party_to_cat, self)

		-- 정화의 물약 먹음
		elseif potion_index == 2 then
			wait_for_sec(0.5)

			field_ui_util.show_narration_async({ key = 'nightmare_magicschool_3_rescue_witch_25'})

			party_util.reset_controllers()
			field_ui_manager:Show()

		-- 에너지 음료 먹음
		elseif potion_index == 3 then
			music_player_util.play_sfx({sfx_name = '01_potion_01'})
			screen_util.fade_out_async(0.5, unity_class.color.red, 'linear')

			party_util.set_anim({name = 'prostrate'})
			party_util.set_emotion({name = 'damaged'})

			wait_for_sec(0.3)

			music_player_util.play_sfx({sfx_name = '01_fade_out_02'})
			screen_util.fade_in_async(0.5, unity_class.color.red, 'linear')

			wait_for_sec(1.5)

			music_player_util.play_sfx({sfx_name = '01_rustle_01'})
			character_util.shake(user_party_leader, 0.05, 0.7)

			wait_for_sec(0.7)

			music_player_util.play_sfx({sfx_name = '01_player_popup_01'})
			party_util.remove_emotion()
			party_util.remove_animation()

			party_util.reset_controllers()
			field_ui_manager:Show()
		end
	else
		self.potion_count_arr[potion_index] = self.potion_count_arr[potion_index] + 1
		party_util.reset_controllers()
		field_ui_manager:Show()
	end
end

-- 동물들에게 물약을 먹일지 말지, 먹인다면 어떤 물약을 먹일지 결정해서 리턴
function local_class:choose_behaviour(potion_types)
	-- 물약 줄까 말까
	local result_1 = choose_util.play_choose_event(
			{{self.give_potion_key, 'brutal'},{self.dont_give_potion_key, 'mercy'}})

	if result_1 == 2 then return -1 end

	local data = {}
	for k, v in pairs(potion_types) do
		table.insert(data, {self.feed_potion_keys[v], 'brutal'})
	end

	-- 어떤 물약을 줄까
	local result_2 = choose_util.play_choose_event(data)

	local potion_type = potion_types[result_2]
	self.potion_count_arr[potion_type] = self.potion_count_arr[potion_type] - 1

	return result_2
end

-- 캐릭터 하얗게 변했다가 원래대로 돌아옴.
function local_class:fade_color(fo, duration, effect_on)
	local pos = fo.Bounds.center
	local sfx = nil
	if effect_on then
		sfx = music_player_util.play_sfx({sfx_name = '01_boss_die_01'})
		unity_object_pool.GetOrCreate('fx_common_event_transform'):Instantiate(pos)
	end

	local start_time = unity_class.time.time

	while true do
		local cur_time = unity_class.time.time

		if cur_time - start_time > duration then
			break
		end

		local normal = (cur_time - start_time) / duration
		fo.SpineController:AddFadeColor(fo.Name, CS.UnityEngine.Color(1, 1, 1, normal), normal, 0)

		coroutine.yield(nil)
	end

	if sfx ~= nil then
		sfx:Stop()
	end

	fo.SpineController:RemoveFadeColor(fo.Name, 0)
end

-- 고양이한테 포션 주려고 함
function local_class:try_give_to_cat(potion_types)
	local cat = get_character(self.cat_name)

	party_util.align_party(cat, 'down')

	local result = self:choose_behaviour(potion_types)

	if result < 0 then return end

	local potion_index = potion_types[result]

	if potion_index == 2 then
		character_util.shake(cat, 0.04, 2)
		music_player_util.play_sfx({sfx_name = '01_bad_fairy_01'})
		character_util.show_emoticon(cat, nil, 'heart')

		party_util.set_anim({name = 'embarrassed', loop = true})

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fade_color, self, cat, 2, true))

		wait_for_sec(2)

		party_util.remove_animation()

		yield_return_func(self.cat_change_to_witch, self)
	elseif potion_index == 1 or potion_index == 3 then
		music_player_util.play_sfx({sfx_name = '03_dialogue_tipsy_01'})
		character_util.show_emoticon_async(cat, nil, 'annoyed')
	end
end

-- 멍멍이한테 포션 주려고 함.
function local_class:try_give_to_dog(potion_types)
	local dog = get_character(self.dog_name)

	party_util.align_party(dog, 'right', 1, 'arc')

	local result = self:choose_behaviour(potion_types)

	if result < 0 then return end

	if potion_types[result] ~= 1 then

		-- 변신 물약이 아니면 랜덤한 반응 보여줌
		local flag = random_util.get_random_int(1, 3)
		character_util.remove_emotion(dog)

		if flag == 1 then
			music_player_util.play_sfx({sfx_name = '01_pet_howl_01'})
			character_util.set_anim(dog, {name = 'victory', remove_after = 1.1})

			music_player_util.play_sfx({sfx_name = '01_bad_fairy_01'})
			character_util.show_emoticon_async(dog, nil, 'heart')

		elseif flag == 2 then
			music_player_util.play_sfx({sfx_name = '01_pet_hurt_01', volume = 2})
			character_util.set_emotion(dog, {name = 'surprise'})
			character_util.set_anim(dog, {name = 'dead', remove_after = 2})

			music_player_util.play_sfx({sfx_name = '03_dialogue_tipsy_01'})
			character_util.show_emoticon_async(dog, nil, 'annoyed')

			character_util.remove_emotion(dog)
		else
			music_player_util.play_sfx({sfx_name = '01_bad_fairy_01'})
			character_util.show_emoticon(dog, nil, 'heart')

			music_player_util.play_sfx({sfx_name = '01_small_jump_01'})
			character_util.mario_jump_new(dog, 'right', 0.5, 0.5)
			wait_for_sec(0.7)

			music_player_util.play_sfx({sfx_name = '01_small_jump_01'})
			character_util.mario_jump_new(dog, 'right', 0.5, 0.5)
			wait_for_sec(1.3)
		end
	else
		local dog_human = get_character(self.dog_human_name)
		local dog_pos = dog.Position

		character_util.shake(dog, 0.04, 2)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fade_color, self, dog, 2, true))

		wait_for_sec(2)

		music_player_util.play_sfx({sfx_name = '02_wolf_boss_bomb_01'})
		unity_object_pool.GetOrCreate('FX_dead'):Instantiate(dog_pos)
		character_util.set_position(dog_human, dog_pos)
		character_util.set_active_state(dog_human, 'enabled')
		character_util.set_emotion(dog_human, {name = 'surprise'})
		character_util.set_active_state(dog, 'disabled')

		wait_for_sec(0.3)
		party_util.set_emotion({name = 'surprise'})

		wait_for_sec(1)

		music_player_util.play_sfx({sfx_name = '01_swing_01'})
		character_util.set_direction(dog_human, 'left')

		wait_for_sec(1)

		music_player_util.play_sfx({sfx_name = '01_swing_01'})
		character_util.set_direction(dog_human, 'right')

		wait_for_sec(1)

		character_util.remove_emotion(dog_human)
		party_util.remove_emotion()

		character_util.set_anim(dog_human, {name = 'dead4', loop = false})

		music_player_util.play_sfx({sfx_name = '01_pet_hurt_01'})
		speech_bubble_util.show_speech_bubble(dog_human, {key = 'nightmare_magicschool_3_rescue_witch_27'})

		wait_for_sec(2.5)

		local sfx_1 = music_player_util.play_sfx({sfx_name = '01_dash_04', loop = true})
		character_util.set_anim(dog_human, {name = 'walk4legs', loop = false, mix_duration = 0.3})
		character_util.move_to(dog_human, vector(dog_pos.x, 0, dog_pos.z + 2),
				nil, 2, true, false)

		wait_for_sec(1)

		character_util.remove_anim(dog_human)
		character_util.set_anim(dog_human, {name = 'walk4legs', loop = false})
		character_util.move_to(dog_human, vector(dog_pos.x - 2, 0, dog_pos.z + 2),
				nil, 2, true, false)

		wait_for_sec(1)

		sfx_1:Stop()

		wait_for_sec(1)

		character_util.remove_anim(dog_human)

		local sfx_2 = music_player_util.play_sfx({sfx_name = '01_dash_04', loop = true})
		character_util.set_anim(dog_human, {name = 'walk4legs', loop = false})
		character_util.move_to(dog_human, vector(dog_pos.x, 0, dog_pos.z + 2),
				nil, 2, true, false)

		wait_for_sec(1)

		sfx_2:Stop()

		wait_for_sec(1)

		local waypoints = {
			vector(54, 0, dog_pos.z + 2),
			vector(54, 0, 16)
		}

		music_player_util.play_sfx({sfx_name = '01_pet_bark_01', parent = dog_human})
		character_util.set_emotion(dog_human, {name = 'smile'})
		speech_bubble_util.show_speech_bubble(dog_human, {key = 'nightmare_magicschool_3_rescue_witch_28'})

		character_util.remove_anim(dog_human)
		character_util.set_anim(dog_human, {name = 'walk4legs', loop = true, scale = 5})

		for k, v in pairs(waypoints) do
			character_util.move_to_async(dog_human, v, nil, 5, true, false)
		end

		character_util.remove_anim_and_emotion(dog_human)
		character_util.set_active_state(dog_human, 'disabled')

		party_util.remove_emotion()
	end
end

-- 쥐한테 포션 주려고 함
function local_class:try_give_to_rat(potion_types)
	local rat = get_character(self.rat_name)

	party_util.align_party(rat.Position, 'right')

	local result = self:choose_behaviour(potion_types)

	if result < 0 then return end

	character_util.set_emotion(rat, {name = 'mad'})
	music_player_util.play_sfx({sfx_name = '01_die_mouse_01'})
	speech_bubble_util.show_speech_bubble_async(rat,
			{key = 'nightmare_magicschool_3_rescue_witch_18', skip = true})

	character_util.set_anim(rat, {name = 'jingak', sfx_name = '03_mech_stomp_01', loop = false})

	wait_for_sec(0.6)

	camera_util.shake(0.4, 0.5)

	local effect = unity_object_pool.GetOrCreate('FX_hit_me')
			:Instantiate(user_party_leader.Position + vector(-0.1, 0, 0))
	effect.transform.localScale = unity_class.vector3.one * 2
	-- 파티원들 뒤로 밀어냄
	for i = 0, user_party.Count - 1 do
		local knock_back_info = character_util.knockback_info(
				'physics', true, vector(1, 0, 0), 10000, 0.05,
				CS.Oak.Constants.DefaultFrictionCoefficient)

		local ckms = CS.Oak.CharacterKnockBackState.Create(user_party[i], knock_back_info)
		user_party[i].FieldObjectBehaviour:OnEvent(CS.Oak.StateChangeEvent.Create(ckms))

		user_party[i].SpineController:DamageSquish(1)
		user_party[i].SpineController:DamageRedPulse()
	end

	music_player_util.play_sfx({sfx_name = '01_trip_01'})
	party_util.set_emotion({name = 'hurt'})
	party_util.set_anim({ name = 'damaged' })

	wait_for_sec(0.3)

	character_util.remove_anim(rat)

	music_player_util.play_sfx({sfx_name = '03_dialogue_tipsy_01'})
	character_util.show_emoticon(rat, nil, 'annoyed')

	wait_for_sec(0.3)

	party_util.set_emotion({name = 'hurt'})
	party_util.set_anim({ name = 'prostrate' })

	wait_for_sec(0.5)

	music_player_util.play_sfx({sfx_name = '01_rustle_01'})
	for i = 0, user_party.Count - 1 do
		character_util.shake(user_party[i], 0.05, 1)
	end

	wait_for_sec(1)

	music_player_util.play_sfx({sfx_name = '01_player_popup_01'})
	for i = 0, user_party.Count - 1 do
		character_util.normal_jump(user_party[i])
	end

	party_util.remove_emotion()
	party_util.remove_animation()
	character_util.remove_emotion(rat)

	wait_for_sec(0.3)
end

function local_class:cat_change_to_witch()
	local cat = get_character(self.cat_name)
	local witch = get_character(self.witch_name)

	music_player_util.play_sfx({sfx_name = '03_runaway_01'})
	music_player_util.play_sfx({sfx_name = '02_wolf_boss_bomb_01'})
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(cat.Position)

	character_util.set_position(witch, cat.Position)
	character_util.set_position(cat, vector(999, 0, 999))
	character_util.set_active_state(cat, 'disabled')

	character_util.set_emotion(witch, {name = 'surprise'})
	character_util.set_anim(witch, {name = 'embarrassed'})
	character_util.set_direction(witch, 'down')

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	wait_for_sec(0.5)

	character_util.remove_anim(witch)

	music_player_util.play_sfx({sfx_name = '03_dialogue_negative_02'})
	speech_bubble_util.show_speech_bubble_async(witch,
			{key = 'nightmare_magicschool_3_rescue_witch_19', skip = true})

	character_util.set_emotion(witch, {name = 'idle'})

	speech_bubble_util.show_speech_bubble_async(witch,
			{key = 'nightmare_magicschool_3_rescue_witch_20', skip = true})

	character_util.set_anim(user_party_leader, {name = 'nod', loop = true})
	wait_for_sec(0.87)
	character_util.remove_anim(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(witch,
			{key = 'nightmare_magicschool_3_rescue_witch_21', skip = true})

	character_util.set_anim(witch, {name = 'release', loop = true, sfx_name = '01_swing_01'})

	speech_bubble_util.show_speech_bubble_async(witch,
			{key = 'nightmare_magicschool_3_rescue_witch_22', skip = true})

	character_util.remove_anim_and_emotion(witch)

	local star_piece = get_field_object(self.star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(witch.Position + vector(0, 1, 0)))
end

function local_class:change_party_to_cat()
	local cats = {
		get_character('cat_party_1'),
		get_character('cat_party_2'),
		get_character('cat_party_3'),
		get_character('cat_party_4')
	}

	local cauldron = get_field_object(self.cauldron_name)
	cauldron.Interactable = CS.Oak.NonInteractable.Instance

	wait_for_sec(0.5)

	local sohee = get_character('sohee')
	local follow_friends = user_party:Contains(sohee)

	local pos_arr = {}
	local array_count = follow_friends and user_party.Count - 3 or user_party.Count

	for i = 1, array_count do
		pos_arr[i] = user_party[i - 1].Position
	end

	music_player_util.play_sfx({sfx_name = '01_cat_meow_01'})
	music_player_util.play_sfx({sfx_name = '02_wolf_boss_bomb_01'})
	for i = 1, #pos_arr do
		local cat = cats[i]
		character_util.set_position(cat, pos_arr[i])
		unity_object_pool.GetOrCreate('FX_dead'):Instantiate(pos_arr[i])

		character_util.set_active_state(cat, 'enabled')
		character_util.set_direction(cat, 'right')

		if i == 1 then
			character_util.convert_to_manual_character(cat)
		else
			character_util.convert_to_party_member(cat, user_party)
		end
	end

	if follow_friends then
		local friends = {
			get_character('sohee'),
			get_character('lavi'),
			get_character('favi')
		}

		local cat_friends = {
			get_character('cat_friend_1'),
			get_character('cat_friend_2'),
			get_character('cat_friend_3')
		}

		for i = 1, 3 do
			local cat = cat_friends[i]
			character_util.set_position(cat, friends[i].Position)
			character_util.set_direction(cat, 'right')
			character_util.set_active_state(cat, 'enabled')
			unity_object_pool.GetOrCreate('FX_dead'):Instantiate(friends[i].Position)

			character_util.convert_to_party_member(cat, user_party)
		end
	end

	character_util.remove_anim_and_emotion(cats[1])

	self.cat_timer_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.cat_party_timer_process, self))

	wait_for_sec(0.5)

	--  StateChangeEvent 받아올 수 있게 enabled
	self:toggle_control(cats[1], true)

	party_util.reset_controllers()

	coroutine.yield(nil)

	-- 달리기, 인터랙트, 공격, 들기, 스킬 전부 막아놓음
	local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
	manual_touch_state:DisableControls(CS.Oak.DisabledControls.Dash | CS.Oak.DisabledControls.Interact |
			CS.Oak.DisabledControls.Attack | CS.Oak.DisabledControls.Super | CS.Oak.DisabledControls.Hold)

	local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
	message_system:SendSync(user_party.Leader.FieldObjectController, state_change_event)

	coroutine.yield(nil)

	field_ui_manager:Show()

	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.SkillButton
			| CS.Oak.FieldUiType.ClassButton | CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.ModeChangeButton
			| CS.Oak.FieldUiType.TeamCombinationButton)

	-- 달리기 버튼이 공격버튼처럼 보이게.
	field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction
			= CS.Oak.CharacterControllerManualTouchState.Button1Action.CustomAttack
end

function local_class:cat_party_timer_process()
	message_system:Publish(CS.Oak.AttackQueueStartEvent.Create(user_party.Leader, self.cat_party_duration))

	local time_passed = 0

	while time_passed <= self.cat_party_duration do
		local leader_state = user_party.Leader.FieldObjectController.CurrentState
		if leader_state == nil
				or not lua_helper.type_compare(leader_state, CS.Oak.CharacterControllerScreenplayState) then
			time_passed = time_passed + unity_class.time.deltaTime
		end

		coroutine.yield(nil)
	end

	self.cat_timer_coroutine = nil

	if lua_helper.reference_equals(user_party.Leader, get_character('cat_party_1')) then
		self:restore_origin_party()
	end
end

function local_class:restore_origin_party()
	party_util.stop_and_disable_control()

	if self.hissing_sfx ~= nil then
		self.hissing_sfx:Stop()
		self.hissing_sfx = nil
	end

	if self.cat_timer_coroutine ~= nil then
		stop_coroutine(self.cat_timer_coroutine)
		self.cat_timer_coroutine = nil
	end

	if not self.is_rat_run_away then
		self.is_cat_in_zone = false
		character_util.stop_shake(get_character(self.rat_name))
	end

	character_util.remove_anim(get_character('cat_party_1'))

	local selected_party = CS.Oak.User.Me.Party
	local current_battle = stage.BattleManager:GetBattleFor(user_party.Leader)
	local sohee = get_character('cat_friend_1')
	local follow_friends = user_party:Contains(sohee)

	music_player_util.play_sfx({sfx_name = '02_wolf_boss_bomb_01'})

	local cat_party_count = follow_friends and user_party.Count - 4 or user_party.Count - 1
	for i = 0, cat_party_count do
		local info = selected_party[i]
		local member_name = CS.Oak.PartyUtil.GeneratePartyName(selected_party, info)
		local origin_member = get_character(member_name)
		local current_member = user_party[i]

		unity_object_pool.GetOrCreate('FX_dead'):Instantiate(current_member.Position)
		current_member.ActiveState = active_state('disabled')
		origin_member.Position = current_member.Position
	end

	party_manager:RestorePlayerParty(false)

	--소히 등등이 파티에 붙어있으면
	if follow_friends then
		local friends = {
			get_character('sohee'),
			get_character('lavi'),
			get_character('favi')
		}

		local cat_friends = {
			get_character('cat_friend_1'),
			get_character('cat_friend_2'),
			get_character('cat_friend_3')
		}

		for i = 1, 3 do
			character_util.set_position(friends[i], cat_friends[i].Position)
			unity_object_pool.GetOrCreate('FX_dead'):Instantiate(cat_friends[i].Position)

			character_util.set_active_state(cat_friends[i], 'disabled')
			character_util.set_active_state(friends[i], 'enabled')
			character_util.convert_to_party_member(friends[i], user_party)
		end
	end

	-- 전투중이였다면 현재 리더에게로 어그로 변경
	local is_in_battle = current_battle ~= nil
	if is_in_battle == true then
		for i = 0, current_battle.Enemies.Count - 1 do
			local monster = current_battle.Enemies[i].Character

			if monster ~= nil and monster.ActiveState == active_state('enabled') then
				command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
			end
		end
	end

	local cauldron = get_field_object(self.cauldron_name)
	cauldron.Interactable = CS.Oak.PublishInteractable.Create()

	party_util.reset_controllers()
	field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction = nil
end

function local_class:toggle_control(fo, is_enabled)
	local controller = fo.FieldObjectController
	cast(controller, typeof(CS.Oak.IFieldObjectController))

	controller.FieldObjectControllerState
			= is_enabled and CS.Oak.FieldObjectControllerState.Enabled or CS.Oak.FieldObjectControllerState.Disabled
end

function local_class:try_cat_leader_attack()
	if not self.is_cat_leader_attacking then
		self.is_cat_leader_attacking = true

		local cat_leader = get_character('cat_party_1')
		self:toggle_control(cat_leader, false)
		field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction
		= CS.Oak.CharacterControllerManualTouchState.Button1Action.EndAction

		self.hissing_sfx = music_player_util.play_sfx({sfx_name = '01_cat_hiss_01'})
		character_util.set_anim(cat_leader, {name = 'hissing', loop = false})
		character_util.set_emotion(cat_leader, {name = 'mad'})

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()

			wait_for_sec(self.cat_leader_attack_duration)

			if lua_helper.reference_equals(user_party.Leader, cat_leader) then
				self.hissing_sfx:Stop()
				self.hissing_sfx = nil
				character_util.remove_anim_and_emotion(cat_leader)

				field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction
							= CS.Oak.CharacterControllerManualTouchState.Button1Action.CustomAttack
				self:toggle_control(cat_leader, true)
			end
			self.is_cat_leader_attacking = false
		end))

		return true
	end

	return false
end

function local_class:rat_run_away()
	local rat = get_character(self.rat_name)

	character_util.stop_shake(rat)

	music_player_util.play_sfx({sfx_name = '01_mouse_01'})
	speech_bubble_util.show_speech_bubble(rat, {key = 'nightmare_magicschool_3_rescue_witch_24'})
	character_util.set_anim(rat, {name = 'embarrassed', loop = true})

	music_player_util.play_sfx({sfx_name = '01_player_jump_01'})
	character_util.normal_jump_async(rat)
	music_player_util.play_sfx({sfx_name = '01_player_jump_01'})
	character_util.normal_jump_async(rat)

	speech_bubble_util.remove_bubble(rat)
	character_util.remove_anim(rat)

	rat.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	music_player_util.play_sfx({sfx_name = '01_dash_01', parent = rat})

	-- xz 평면에서 z = x - rat.x + rat.z 선 기준으로 리더가 밑에 있는지 아래에 있는지 검사하여 반대로 도망감
	if user_party.Leader.Position.x - rat.Position.x + rat.Position.z < user_party.Leader.Position.z then
		wp_util.move_way_points_async(rat, {waypoints = {vector(53, 0, rat.Position.z),
														 vector(53, 0, 16)}, speed = 10, run = true})
	else
		wp_util.move_way_points_async(rat, {waypoints = {vector(rat.Position.x, 0, 27),
														 vector(42, 0, 27)}, speed = 10, run = true})
	end

	character_util.set_active_state(rat, 'disabled')
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
