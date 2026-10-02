local local_class = newclass("NightmareDesert1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.lamp_star_piece_name = "lamp_star_piece"
	self.star_piece_appeared = false
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent), 'on_event')

	self.consumed_cave_items = {}
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	self.cs_controller = nil
	if self.watch_lamp_quicksand_coroutine ~= nil then
		stop_coroutine(self.watch_lamp_quicksand_coroutine)
		self.watch_lamp_quicksand_coroutine = nil
	end

	if self.caveItems ~= nil then
		self.caveItems:Clear()
		self.caveItems = nil
		self.caveItemsId:Clear()
		self.caveItemsId = nil
	end

	self.consumed_cave_items = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent), 'on_event')
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		if not stage_progress:HasStarPiece(self.lamp_star_piece_name) then
			local keydoor = get_field_object("keydoor_desert")
			if keydoor.FieldObjectBehaviour.Opened == false then
				local opener = get_character("lamp_opener")
				opener.Interactable:AddListener(self.cs_controller)
			end

			local genie_box = get_field_object("genie_box")
			local genie = get_character("lamp_genie")
			local genie_offset = vector(-0.5, 0.1, -1)
			genie.Position = genie_box.Position + genie_offset
			genie.Direction = CS.Oak.Direction.Right
			genie.Interactable = CS.Oak.NonInteractable.Instance
			character_util.set_anim(genie, { name = "sleep" })
			character_util.set_emotion(genie, { name = "sleep_deep" })
			field_ui_manager:RemoveUI(genie, CS.Oak.FieldUiType.CharacterStats)
			self:respawn_cave_items()

			if genie_box.FieldObjectBehaviour.IsOpened then
				genie_box.Interactable = CS.Oak.PublishInteractable.Create()
			end
		else
			local opener = get_character("lamp_opener")
			opener.ActiveState = CS.Oak.ActiveState.Disabled
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		local opener = get_character("lamp_opener")
		local genie = get_character("lamp_genie")
		local box1 = get_field_object("box_1")
		local box2 = get_field_object("box_2")
		local box3 = get_field_object("box_3")
		if lua_helper.reference_equals(e.Target, opener) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.open_door, self))
		elseif lua_helper.reference_equals(e.Target, genie) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_to_genie, self))
		elseif lua_helper.reference_equals(e.Target, box1) or lua_helper.reference_equals(e.Target, box2) or lua_helper.reference_equals(e.Target, box3) then
			if self.punish_greed_coroutine == nil then
				self.punish_greed_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.punish_greed, self))
			end
		elseif lua_helper.reference_equals(e.Target, get_field_object("genie_box")) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.genie_box_open, self))
		end
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if not stage_progress:HasStarPiece(self.lamp_star_piece_name) and self.star_piece_appeared == false then
			if e.Zone.Name == "lamp_teleport" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				if self.watch_lamp_quicksand_coroutine == nil then
					self.watch_lamp_quicksand_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.watch_lamp_quicksand, self))
				end
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if e.Zone.Name == "lamp_teleport" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if self.watch_lamp_quicksand_coroutine ~= nil then
				stop_coroutine(self.watch_lamp_quicksand_coroutine)
				self.watch_lamp_quicksand_coroutine = nil
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		if self.caveItemsId ~= nil and self.caveItemsId:Contains(e.Item.ItemId) and lua_helper.reference_equals(e.Getter, user_party_leader) then
			table.insert(self.consumed_cave_items, self.caveItems[e.Item.Level])
			if self.punish_greed_coroutine == nil then
				self.punish_greed_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.punish_greed, self))
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.TreasureOpenScreenPlayEndEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object("genie_box")) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.genie_box_open, self))
		end
	end

	return false
end

function local_class:open_door()
	local opener = get_character("lamp_opener")
	local door = get_field_object("keydoor_desert")

	field_ui_manager:Hide()

	character_util.align_party(opener, "down")
	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(opener, { key = "nightmare_desert_lamp_start_1", skip = true })
	character_util.set_anim(opener, { name = "hold_loop", loop = true })
	speech_bubble_util.show_speech_bubble_async(opener, { key = "nightmare_desert_lamp_start_2", skip = true })
	speech_bubble_util.show_speech_bubble_async(opener, { key = "nightmare_desert_lamp_start_3", skip = true })
	character_util.set_anim(opener, { name = "cast", loop = true })
	speech_bubble_util.show_speech_bubble_async(opener, { key = "nightmare_desert_lamp_start_4", skip = true })

	camera_util.move(door.Position, 1.0)
	message_system:Publish(CS.Oak.DoorOpenEvent.Create("keydoor_desert", false))

	wait_for_sec(6)
	character_util.set_anim(opener, { name = "idle", loop = true })

	camera_util.move(user_party_leader.Position, 1.0, { end_target = user_party_leader })
	wait_for_sec(1)

	field_ui_manager:Show()
	opener.Interactable:RemoveRelatedEvent(self.cs_controller)
	user_party:ResetControllers()
end

function local_class:watch_lamp_quicksand()
	while true do
		if user_party_leader.Position.y <= -1.0 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teleport_to_lamp_cave, self))
			break
		end
		coroutine.yield(nil)
	end
end

function local_class:teleport_to_lamp_cave()
	user_party:StopAndDisableControl()
	local marker = field:GetMarker('lamp_cave_in')
	CS.Oak.TeleportPartyStageLogic.Execute(marker)
	music_player_util.play_stage_music({
		name = 'bgm_cave_main', state = 'event', mix = 2.0
	})
end

function local_class:respawn_cave_items()
	if self.caveItemsId == nil then
		local item_data = game_data_service.GetData("ItemData")
		local items = create_generic_list(CS.System.Int32)
		items:Add(item_data:GetSpec("cwp_plitvice_epic").Id)
		items:Add(item_data:GetSpec("cwp_admiral_epic").Id)
		items:Add(item_data:GetSpec("cwp_villainredhood_epic").Id)
		items:Add(item_data:GetSpec("cwp_eugene_epic").Id)
		items:Add(item_data:GetSpec("cwp_uptowngirl_epic").Id)
		items:Add(item_data:GetSpec("cwp_idolcaptain_epic").Id)
		items:Add(item_data:GetSpec("cwp_flowergirl_epic").Id)
		self.caveItemsId = items
	end

	if self.caveItems == nil then
		self.caveItems = create_generic_list(CS.Oak.DropItem)
	elseif self.caveItems.Count > 0 then
		for i = 0, self.caveItems.Count - 1 do
			-- 먹지않은 동굴 아이템이라면 디스포징 해줌.
			if not table_util.contain_value(self.consumed_cave_items, self.caveItems[i]) then
				self.caveItems[i]:ConsumeComplete()
			end
		end
		self.caveItems:Clear()
	end

	local numItems = 7

	-- 바닥에 아이템을 깐다.
	for i = 0, numItems - 1 do
		local m = field:GetMarker(string.format("cave_item_%d", (i+1)))
		local item = {}
		item.ItemId = self.caveItemsId[i % self.caveItemsId.Count]
		item.NotForInventory = true
		item.Level = i
		local dropItem = CS.Oak.DropItem.Create(m.position, item, false, CS.Oak.DropItem.LootState.FindLooter, 0.7)
		dropItem.PickFlyDistance = 1.25
		self.caveItems:Add(dropItem)
	end

	self.consumed_cave_items = {}
end

function local_class:genie_box_open()
	field_ui_manager:Hide()
	local genie = get_character("lamp_genie")
	local align_pos = genie.Position
	align_pos.y = 1
	align_pos.z = align_pos.z - 0.4
	character_util.align_party(align_pos, "down")

	wait_for_sec(1.0)

	music_player:PlaySfxOneShot('03_dialogue_worker_01')
	character_util.remove_emotion(genie)

	wait_for_sec(1.5)

	music_player:PlaySfxOneShot('01_clang_01')
	character_util.set_anim(genie, { name = "idle", loop = true })

	wait_for_sec(1.0)

	genie.Direction = CS.Oak.Direction.Down

	wait_for_sec(1.0)

	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_1", skip = true })
	genie.Direction = CS.Oak.Direction.Right
	character_util.set_anim(genie, { name = "cross_arm", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_2", skip = true })
	genie.Direction = CS.Oak.Direction.Down
	character_util.set_anim(genie, { name = "idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_3", skip = true })
	character_util.set_anim(genie, { name = "bomb_idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_4", skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_5"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_6"),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = genie

	wait_for_branch = true
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	character_util.set_anim(genie, { name = "idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_7", skip = true })
	character_util.set_anim(genie, { name = "bomb_idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_8", skip = true })
	character_util.set_anim(genie, { name = "idle", loop = true })

	branches:Clear()
	wait_for_branch = true
	choice = 0
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_9"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_10"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	choice_state.Branchs = branches

	wait_for_branch = true
	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.set_emotion(genie, { name = "mad"})
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_11", skip = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_12", skip = true })

	character_util.remove_emotion(genie)
	character_util.set_anim(genie, { name = "bomb_idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_13", skip = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_14", skip = true })
	character_util.set_anim(genie, { name = "get", loop = false })
	music_player:PlaySfxOneShot('01_gatcha_award_start_01')
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_15", skip = true })

	music_player:PlaySfxOneShot('01_earthquake_01')
	music_player_util.play_stage_music({
		state = 'field', mix = 1.5
	})

	screen_util.fade_out_async(0.5, unity_class.color.white)

	local opener = get_character("lamp_opener")
	opener.ActiveState = CS.Oak.ActiveState.Disabled

	local center = opener.Position

	local height = 3

	genie.Direction = CS.Oak.Direction.Right
	genie.Position = center - vector(0.5, height, 0)
	character_util.set_anim(genie, { name = "hold" })

	for i = 0, user_party.Count - 1 do
		user_party[i].Position = center + vector(0.5 + i * CS.Oak.Constants.DistBetweenPartyMembers, height, 0)
		user_party[i].Direction = CS.Oak.Direction.Left
		character_util.set_anim(user_party[i], { name = "embarrassed", loop = true})
		character_util.set_emotion(user_party[i], { name = "surprise"})
	end

	-- 사막 메인퀘스트를 클리어하지않아 스폰지밥이 뒤에 붙어있을때만 스폰지밥 위치 세팅
	local main_quest = user_progress:GetStartedQuest(90)
	local sponge_bob = get_character('sponge_bob')
	if main_quest ~= nil and not main_quest.IsComplete  then
		character_util.stop(sponge_bob)
		sponge_bob.Position = vector_util.get_x0z(user_party[user_party.Count - 1].Position) + unity_class.vector3.right * CS.Oak.Constants.DistBetweenPartyMembers
		sponge_bob.Direction = character_util.get_direction('left')
	end

	camera_util.move(user_party_leader.Position, 0, { end_target = user_party_leader })

	screen_util.fade_in(0.5, unity_class.color.white)

	--music_player:PlaySfxOneShot('01_jump_01')
	local free_fall = CS.CalculatorFreeFall(0, 30, height, 1)
	local free_fall_genie = CS.CalculatorFreeFall(0, 20, height, 0)
	local genie_landed = false
	local land_shaken = false
	while true do
		coroutine.yield(nil)
		free_fall:Proceed(unity_class.time.deltaTime)
		free_fall_genie:Proceed(unity_class.time.deltaTime)
		local new_y = free_fall:GetDistance()
		if new_y < 0 then
			new_y = 0
		end
		local new_y_genie = free_fall_genie:GetDistance()
		if new_y_genie < 0 then
			new_y_genie = 0
		end

		for i = 0, user_party.Count - 1 do
			local p = user_party[i].Position
			p.y = new_y
			user_party[i].Position = p
		end

		local gp = genie.Position
		gp.y = new_y_genie
		genie.Position = gp

		if free_fall_genie:IsDone() and not genie_landed then
			genie_landed = true
			character_util.set_anim(genie, { name = "idle", loop = true})
		end

		if free_fall:NumBounced() > 0 and not land_shaken then
			land_shaken = true
			camera_util.shake(0.07, 0.15)
			--music_player:PlaySfxOneShot('03_mech_stomp_01')
		end

		if free_fall:IsDone() then
			break
		end
	end

	for i = 0, user_party.Count - 1 do
		character_util.set_anim(user_party[i], { name = "seat", loop = true})
	end

	wait_for_sec(1.0)

	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_16", skip = true })

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
	end

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('01_clap_01')
	character_util.set_anim(genie, { name = "clap", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_17", skip = true })

	branches:Clear()
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_18"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_22"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_25"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 2
		end
	})
	branches:Add({
		Text = game_string:GetString("nightmare_desert_lamp_genie_27"),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 3
		end
	})
	choice_state.Branchs = branches

	while true do
		wait_for_branch = true
		choice = 0
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
		while wait_for_branch do
			coroutine.yield(nil)
		end

		if choice == 0 then
			character_util.set_anim(genie, { name = "idle", loop = true })
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_19", skip = true })
			music_player:PlaySfxOneShot('01_gatcha_award_start_01')
			character_util.set_anim(genie, { name = "dance", loop = true })
			wait_for_sec(0.5)
			local go = unity_object_pool.GetOrCreate("emoticon"):Instantiate(genie.Position)
			local emoticon = go:GetComponent(typeof(CS.Oak.Emoticon))
			emoticon:Init()
			emoticon:ShowOn(genie, vector(1, 1, 1), CS.Oak.EmoticonType.Silence)

			wait_for_sec(2.5)

			character_util.set_anim(genie, { name = "bomb_idle", loop = true })
			music_player:PlaySfxOneShot('03_dialogue_sadness_01')
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_20", skip = true })
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_21", skip = true })
			character_util.set_anim(genie, { name = "idle", loop = true })
		elseif choice == 1 then
			character_util.set_anim(genie, { name = "idle", loop = true })
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_23", skip = true })
			genie.Direction = CS.Oak.Direction.Left
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_24", skip = true })
			genie.Direction = CS.Oak.Direction.Right
		elseif choice == 2 then
			character_util.set_anim(genie, { name = "bomb_idle", loop = true })
			character_util.set_emotion(genie, { name = "damaged"})
			speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_26", skip = true })
			character_util.set_anim(genie, { name = "idle", loop = true })
			character_util.remove_emotion(genie)
		else
			break
		end
	end

	character_util.set_anim(genie, { name = "idle", loop = true })
	character_util.set_emotion(genie, { name = "smile" })
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_28", skip = true })
	character_util.remove_emotion(genie)
	character_util.set_anim(genie, { name = "get", loop = false })

	local star_piece = get_field_object("lamp_star_piece")
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
	self.star_piece_appeared = true
	wait_for_sec(2.0)

	character_util.set_anim(genie, { name = "idle", loop = true })
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_29", skip = true })
	genie.Direction = CS.Oak.Direction.Left
	wait_for_sec(1.0)
	genie.Direction = CS.Oak.Direction.Right
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_30", skip = true })
	character_util.set_emotion(genie, { name = "mad"})
	music_player:PlaySfxOneShot('03_dialogue_worker_01')
	speech_bubble_util.show_speech_bubble_async(genie, { key = "nightmare_desert_lamp_genie_31", skip = true })
	character_util.remove_emotion(genie)
	music_player:PlaySfxOneShot('01_teleport_01')
	unity_object_pool.GetOrCreate("FX_reset_object"):Instantiate(genie.Bounds.center)
	genie.SpineController:SetAlphaFade(0, 0.75)
	wait_for_sec(1.0)
	genie.ActiveState = CS.Oak.ActiveState.Disabled

	-- 스폰지밥이 다시 파티를 따라갈수있도록함.
	if main_quest ~= nil and not main_quest.IsComplete then
		local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(sponge_bob, user_party, 0, 0, true,
				CS.Oak.NpcFollowingStateInBattle.Keep)
		sponge_bob:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
		sponge_bob.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:punish_greed()
	music_player:PlaySfxOneShot('01_earthquake_01')
	camera_util.shake(0.07, 0.15)
	screen_util.fade_out_async(0.15, unity_class.color.white)
	user_party:StopAndDisableControl()

	local m = field:GetMarker("lamp_cave_in")

	character_util.align_party(m.position + vector(1, 0, 0), 'left')
	for i = 0, user_party.Count - 1 do
		character_util.set_emotion(user_party[i], { name = "surprise"})
		character_util.set_anim(user_party[i], { name = "embarrassed"})
	end
	self:respawn_cave_items()

	wait_for_sec(0.2)
	screen_util.fade_in_async(0.25, unity_class.color.white)

	camera_util.shake(0.07, 0.15)
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = "nightmare_desert_lamp_greed_1", bubble_type = "shout", skip = true, offset = vector(0, 0, 1.5)})

	for i = 0, user_party.Count - 1 do
		character_util.remove_emotion(user_party[i])
		character_util.remove_anim(user_party[i], false)
	end

	user_party:ResetControllers()
	self.punish_greed_coroutine = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
