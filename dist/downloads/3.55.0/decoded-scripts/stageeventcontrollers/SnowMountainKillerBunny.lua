local local_class = newclass("SnowMountainKillerBunnyController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.dead_cleric_name = "dead_believer"
	self.knight_name = "heavy_knight"
	self.bunny_name = "killer_bunny"

	self.bunny_zone_name = "bunny_attack"
	self.cave_zone_name = "bunny_cave"

	self.star_piece_name = "killer_bunny_star_piece"

	self.coke_name = "cave_coke"

	self.knight_repeat_talk_keys_1 = {
		"snowmountain_1_4_killer_bunny_3_0",
		"snowmountain_1_4_killer_bunny_3_1"
	}

	self.knight_repeat_talk_keys_2 = {
		"snowmountain_1_4_killer_bunny_3_3",
		"snowmountain_1_4_killer_bunny_3_4"
	}

	self.bunny_nar_key = "snowmountain_1_4_killer_bunny_0_2"

	self.cleric_nar_key_1 = "snowmountain_1_4_killer_bunny_0_0"
	self.cleric_nar_key_2 = "snowmountain_1_4_killer_bunny_0_1"

	self.grenade_id = 20148
	self.grenade_get_title = "snowmountain_1_4_killer_bunny_2_0"
	self.grenade_get_subtitle = "snowmountain_1_4_killer_bunny_2_1"
	self.grenade_get_desc = "snowmountain_1_4_killer_bunny_2_2"

	self.fx_twinkle_name = "FX_Object_Twinkle"
	self.fx_explosion_name = "FX_Explosion_Bomb_new"
	self.fx_hit_name = "FX_hit_me"
	self.fx_boss_explosion_name = 'FX_explosion_boss'

	self.cave_grid_name = "bunny_cave_grid"

	self.is_bunny_dead = false
	self.is_get_star_piece_already = false
	self.is_have_grenade = false
	self.is_seen_bunny_event_once = false
	self.is_seen_knight_talk_once = false
	self.is_seen_cave_event_once = false
	self.is_killed_bunny = false

	self.knight_talk_index = 1

	self.bunny_emoticon = nil

	self.knight_talk_coroutine = nil

	self.twinkle_effect = nil

	self.cave_coroutine = nil

	quest_icon.PreLoad()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	unity_object_pool.GetOrCreate(self.fx_explosion_name)
	unity_object_pool.GetOrCreate(self.fx_hit_name)
	unity_object_pool.GetOrCreate(self.fx_boss_explosion_name)
	unity_object_pool.GetOrCreate(self.fx_twinkle_name)

	local cleric = get_character(self.dead_cleric_name)
	local knight = get_character(self.knight_name)
	local bunny = get_character(self.bunny_name)

	cleric.Interactable = CS.Oak.PublishInteractable.Create()
	if knight.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		knight.Interactable:AddListener(self.cs_controller)
	end

	if bunny.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		bunny.Interactable:AddListener(self.cs_controller)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	local cleric = get_character(self.dead_cleric_name)
	local knight = get_character(self.knight_name)
	local bunny = get_character(self.bunny_name)

	if self.twinkle_effect ~= nil then
		self.twinkle_effect:Dispose()
		self.twinkle_effect = nil
	end

	if self.cave_coroutine ~= nil then
		stop_coroutine(self.cave_coroutine)
		self.cave_coroutine = nil
	end

	self.bunny_emoticon = nil
	self.knight_talk_coroutine = nil

	cleric.Interactable = CS.Oak.NonInteractable.Instance

	if knight.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		knight.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if bunny.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		bunny.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if not self.is_get_star_piece_already then
			self:on_zone_enter_event(e)
		end
	elseif event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
		if e.CameraGrid.name == self.cave_grid_name and self.is_seen_cave_event_once then
			if self.cave_coroutine ~= nil then
				stop_coroutine(self.cave_coroutine)
				self.cave_coroutine = nil
			end
			self:set_all_event_disabled()
		end
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		local coke = get_field_object(self.coke_name)
		local twinkle_pool = unity_object_pool.GetOrCreate(self.fx_twinkle_name)
		self.twinkle_effect = twinkle_pool:Instantiate(coke.Position + vector(0, 0.5, 0))

		self.is_get_star_piece_already = stage_progress:HasStarPiece(self.star_piece_name)
		if self.is_get_star_piece_already then
			self:set_all_event_disabled()
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local cleric = get_character(self.dead_cleric_name)
	local knight = get_character(self.knight_name)
	local bunny = get_character(self.bunny_name)

	if lua_helper.reference_equals(e.Target, cleric) then
		if not self.is_have_grenade then
			self.is_have_grenade = true
			sp_util.play_normal_screenplay(self.get_grenade, self)
		else
			sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.cleric_nar_key_2})
		end
	elseif lua_helper.reference_equals(e.Target, knight) then
		if self.is_seen_bunny_event_once then
			if self.is_have_grenade then
				if self.is_seen_knight_talk_once then
					sp_util.play_normal_screenplay(function()
						character_util.align_party(knight, "left")
						yield_return_func(self.throw_grenade, self)
					end)
				else
					self.is_seen_knight_talk_once = true
					sp_util.play_normal_screenplay(function()
						yield_return_func(self.talk_with_knight, self)
						yield_return_func(self.throw_grenade, self)
					end)
				end
			else
				if self.is_seen_knight_talk_once then
					self:try_stop_knight_talking()

					self.knight_talk_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.knight_double_talk_routine, self))
				else
					self.is_seen_knight_talk_once = true
					self.knight_talk_index = 1
					sp_util.play_normal_screenplay(self.talk_with_knight, self)
				end
			end
		else
			self:try_stop_knight_talking()

			self.knight_talk_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.knight_double_talk_routine, self))
		end
	elseif lua_helper.reference_equals(e.Target, bunny) then
		sp_util.play_normal_screenplay(self.talk_with_bunny, self)
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	if self.is_get_star_piece_already then return end

	local zone_name = e.Zone.Name

	if zone_name == self.bunny_zone_name then
		if not self.is_killed_bunny then
			self:try_stop_knight_talking()
			sp_util.play_normal_screenplay(self.bunny_attack, self)
		end
	elseif zone_name == self.cave_zone_name then
		if not self.is_seen_cave_event_once then
			self.is_seen_cave_event_once = true
			self.cave_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_cave, self))
		end
	end
end

function local_class:set_all_event_disabled()
	local cleric = get_character(self.dead_cleric_name)
	local knight = get_character(self.knight_name)
	local bunny = get_character(self.bunny_name)
	local coke = get_field_object(self.coke_name)

	if self.twinkle_effect ~= nil then
		self.twinkle_effect:Dispose()
	end

	--coke:SetPosition(vector(999, 0, 999))
	coke.Position = vector(999, 0, 999)
	character_util.set_position(cleric, vector(999, 0, 999))
	character_util.set_position(knight, vector(999, 0, 999))
	character_util.set_position(bunny, vector(999, 0, 999))

	self.is_killed_bunny = true
end

function local_class:get_grenade()
	local cleric = get_character(self.dead_cleric_name)
	field_ui_util.show_narration_async({ key = self.cleric_nar_key_1})

	if cleric.Position.x < user_party_leader.Position.x then
		character_util.set_direction(user_party_leader, "left")
	else
		character_util.set_direction(user_party_leader, "right")
	end

	music_player_util.play_sfx({sfx_name = "03_equipping_01"})
	character_util.set_anim(user_party_leader, {name = "eat", loop = true})

	wait_for_sec(1.5)

	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent({ItemId = self.grenade_id}, self.grenade_get_title,
			self.grenade_get_subtitle, self.grenade_get_desc))
end

function local_class:talk_with_bunny()
	local bunny = get_character(self.bunny_name)

	if bunny.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		bunny.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	field_ui_util.show_narration_async({ key = self.bunny_nar_key})

	local emoticon_pool = unity_object_pool.GetOrCreate('emoticon'):Instantiate(bunny.Position)
	self.bunny_emoticon = emoticon_pool.transform:GetComponent(typeof(CS.Oak.Emoticon))

	self.bunny_emoticon:Init()
	music_player_util.play_sfx({sfx_name = "01_bad_fairy_01"})
	self.bunny_emoticon:ShowOn(bunny, unity_class.vector3.one, CS.Oak.EmoticonType.Heart)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wait_for_sec(2)

		self.bunny_emoticon = nil

		if bunny.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			bunny.Interactable:AddListener(self.cs_controller)
		end
	end))
end


function local_class:bunny_attack()
	if self.bunny_emoticon ~= nil then
		self.bunny_emoticon:Dispose()
		self.bunny_emoticon = nil
	end

	local bunny = get_character(self.bunny_name)

	local first_bunny_pos = bunny.Position

	local bunny_speed = 7
	local dist = unity_class.vector3.Distance(bunny.Position, user_party_leader.Position)

	local bl_vector = user_party_leader.Position - bunny.Position

	character_util.set_direction(bunny, vector_util.to_direction(vector_util.get_x0z(bl_vector)))

	camera_util.resize_to(3, dist / bunny_speed)

	music_player_util.play_sfx({sfx_name = "02_minotaurs_jump_01"})

	character_util.jump(bunny, 1.5, dist / bunny_speed)
	wp_util.move_way_points_async(bunny, {waypoints = user_party_leader.Position, speed = 7})

	character_util.set_direction(bunny, "right")

	music_player_util.play_sfx({sfx_name = "02_hit_harvester_01"})

	local explosion = unity_object_pool.GetOrCreate(self.fx_hit_name):Instantiate(user_party_leader.Position)
	explosion.transform.localScale = unity_class.vector3.one

	character_util.spine_damage_squish(user_party_leader, 1.3, 0.7, 1, 0.5)
	character_util.spine_pulse_color(user_party_leader, CS.Oak.Constants.DamageColor,
			1, 1, 0.5)

	--@@ 데미지 띄움
	CS.DamageNumber.ShowDamageNumber(user_party_leader, 99999, unity_class.color.red, user_party_leader.Position)

	--local dir_vector = unity_class.vector3.Normalize(bl_vector)
	local dir_vector = vector(1, 0, 0)
	local knockback_info = character_util.knockback_info("physics", false, dir_vector,
			12000, 0.05, CS.Oak.Constants.DefaultFrictionCoefficient)
	local ckms = CS.Oak.CharacterKnockBackState.Create(user_party_leader, knockback_info)
	user_party_leader.FieldObjectBehaviour:OnEvent(CS.Oak.StateChangeEvent.Create(ckms))

	character_util.set_direction(user_party_leader, "left")
	character_util.set_anim(user_party_leader, {name = "prostrate"})
	character_util.set_emotion(user_party_leader, {name = "damaged"})

	for i = 1, user_party.Count - 1 do
		if user_party[i].Position.x < bunny.Position.x then
			character_util.set_direction(user_party[i], "right")
		else
			character_util.set_direction(user_party[i], "left")
		end
		character_util.normal_jump(user_party[i])
		character_util.set_emotion(user_party[i], {name = "surprise"})
	end

	wait_for_sec(0.5 + 0.2)

	music_player_util.play_sfx({sfx_name = "01_slowmotion_01", })
	music_player_util.play_stage_music({ state = 'muted', mix = 0.5 })

	character_util.jump(bunny, 1.5, 2)

	for i = 1, user_party.Count - 1 do
		character_util.set_anim(user_party[i], {name = "embarrassed", loop = true})
	end

	local dist_2 = unity_class.vector3.Distance(bunny.Position, user_party_leader.Position)

	camera_util.resize_to(1.5, 1.2)
	--stage_camera:ResizeTo(4, 1)

	character_util.set_anim(bunny, {name = "walk", scale = 0.3})
	wp_util.move_way_points(bunny, {waypoints = user_party_leader.Position, speed = dist_2 / 2})

	wait_for_sec(1)

	music_player_util.play_sfx({sfx_name = "01_dark_magician_01"})
	screen_util.fade_out_async(0.5, unity_class.color.red, "linear")

	local marker_pos = field:GetMarker("killer_bunny_party_respawn").position

	character_util.remove_anim_and_emotion(user_party_leader)
	party_util.position_party(marker_pos, "left")

	character_util.remove_anim(bunny)

	character_util.set_position(bunny, first_bunny_pos)
	character_util.set_direction(bunny, "right")

	music_player_util.play_sfx({sfx_name = "02_hit_harvester_01"})

	wait_for_sec(0.3)

	camera_util.resize_to_default(0)

	party_util.remove_animation()
	party_util.remove_emotion()

	party_util.set_anim({name = "prostrate"})
	party_util.set_emotion({name = "damaged"})

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.red, "linear")

	music_player_util.play_sfx({sfx_name = "01_rustle_01"})
	character_util.shake(user_party_leader, 0.05, 0.7)

	wait_for_sec(0.7)

	music_player_util.play_stage_music({ state = 'field' })
	music_player_util.play_sfx({sfx_name = "01_player_popup_01"})
	party_util.remove_emotion()
	party_util.remove_animation()

	if not self.is_seen_bunny_event_once then
		local knight = get_character(self.knight_name)
		quest_icon.SetQuestNotice(knight)
	end

	self.is_seen_bunny_event_once = true
end

function local_class:knight_double_talk_routine()
	local knight = get_character(self.knight_name)

	if self.is_seen_bunny_event_once then
		speech_bubble_util.show_speech_bubble_async(knight, {key = self.knight_repeat_talk_keys_2[1]})
		speech_bubble_util.show_speech_bubble_async(knight, {key = self.knight_repeat_talk_keys_2[2]})
	else
		speech_bubble_util.show_speech_bubble_async(knight, {key = self.knight_repeat_talk_keys_1[1]})
		speech_bubble_util.show_speech_bubble_async(knight, {key = self.knight_repeat_talk_keys_1[2]})
	end

	self.knight_talk_coroutine = nil
end

function local_class:try_stop_knight_talking()
	local knight = get_character(self.knight_name)
	if self.knight_talk_coroutine ~= nil then
		stop_coroutine(self.knight_talk_coroutine)
		self.knight_talk_coroutine = nil
	end
	speech_bubble_util.remove_bubble(knight)
end

function local_class:talk_with_knight()
	local knight = get_character(self.knight_name)

	quest_icon.RemoveIcon(knight)

	character_util.align_party(knight, "left")

	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_2", skip = true})
	speech_bubble_util.show_speech_bubble_async(knight,
			{key = self.knight_repeat_talk_keys_2[1], skip = true})

	speech_bubble_util.show_speech_bubble_async(knight,
			{key = self.knight_repeat_talk_keys_2[2], skip = true})
end

function local_class:throw_grenade()
	local choice = choose_util.play_choose_event(
			{{"snowmountain_1_4_killer_bunny_1_0", "mercy"},
			 {"snowmountain_1_4_killer_bunny_1_1", "brutal"}})

	if choice == 2 then
		return
	end

	self.is_killed_bunny = true

	local bunny = get_character(self.bunny_name)
	local knight = get_character(self.knight_name)

	if bunny.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		bunny.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if knight.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		knight.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	music_player_util.play_sfx({sfx_name = "01_holy_01"})
	character_util.set_anim(user_party_leader, {name = "get", loop = true})

	yield_return_func(self.item_floating_routine, self)

	character_util.remove_anim(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_5", skip = true})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_6", skip = true})

	local pos = bunny.Position + vector(5, 0 ,0)

	local wait = true

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wp_util.move_way_points_async(knight, {waypoints = pos + vector(0, 0, 1), speed = 3})
		character_util.set_direction(knight, "left")
		wait = false
	end))

	character_util.align_party(pos + vector(-1.5, 0, 0), "right")

	while wait do
		coroutine.yield(nil)
	end

	speech_bubble_util.show_speech_bubble_async(knight,
			{key = "snowmountain_1_4_killer_bunny_3_7", skip = true})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_8", skip = true})

	choose_util.play_choose_event({{"snowmountain_1_4_killer_bunny_1_2", "normal"},
								   {"snowmountain_1_4_killer_bunny_1_3", "normal"}})

	-- 수류탄 던짐
	character_util.set_anim(user_party_leader, {name = "throw", loop = false, sfx_name = "01_throw_01"})

	local grenade = drop_item_util.create_item({pos = user_party_leader.Position,
												target = bunny.Position + vector(2, 0, 0),
												lootstate = "dontfindlooter", bounce = true, itemid = self.grenade_id,
												notforinven = true})

	wait_for_sec(0.5)

	character_util.remove_anim(user_party_leader)

	music_player_util.play_sfx({sfx_name = "01_mining_01", delayed_time = 0.15})
	music_player_util.play_sfx({sfx_name = "01_mining_01", delayed_time = 0.55})

	wait_for_sec(1)

	music_player_util.play_sfx({sfx_name = "02_wolf_boss_bomb_01"})
	music_player_util.play_sfx({sfx_name = "01_boss_die_01", duration = 5, fade_out_time = 0.3})
	local explosion = unity_object_pool.GetOrCreate("FX_Explosion_Bomb_new"):Instantiate(bunny.Position)
	explosion.transform.localScale = unity_class.vector3.one
	grenade:ConsumeComplete()

	character_util.spine_pulse_color(bunny, CS.Oak.Constants.DamageColor, 1, 1, 0.5)
	character_util.set_anim(bunny, {name = "damaged"})

	local fX_explosion_boss_pool = unity_object_pool.GetOrCreate(self.fx_boss_explosion_name)
	fX_explosion_boss_pool:Instantiate(bunny.Position)
	character_util.shake(bunny, 0.05, 1000)

	stage_camera:SetTarget(bunny)
	camera_util.shake(0.04, 5)
	camera_util.resize_to(3, 4)

	wait_for_sec(5)

	music_player_util.play_sfx({sfx_name = "02_explosion_02"})

	bunny.SpineController:CancelShake()
	character_util.set_active_state(bunny, "disabled")
	camera_util.cancel_shake()
	camera_util.resize_to_default(0.5)

	--wait_for_sec(0.5)

	camera_util.return_to_leader(0.8)

	--stage_camera:SetTarget(user_party_leader)

	--character_util.air_spin(bunny, {offset = vector(-3, 0, 0)})

	wait_for_sec(1)

	music_player_util.play_sfx({sfx_name = "03_dialogue_emphasize_01"})

	speech_bubble_util.show_speech_bubble_async(knight,
			{key = "snowmountain_1_4_killer_bunny_3_9", skip = true})

	speech_bubble_util.show_speech_bubble_async(knight,
			{key = "snowmountain_1_4_killer_bunny_3_10", skip = true})

	local cave_pos = field:GetMarker("killer_bunny_cave_exit").position + vector(0, 0, 1)
	local z_pos = knight.Position.z

	local waypoints = create_generic_list(unity_class.vector3)
	waypoints:Add(vector(cave_pos.x, 0, z_pos))
	waypoints:Add(cave_pos)

	wp_util.move_way_points(knight, {waypoints = waypoints, speed = 4})

	wait_for_sec(1)

	character_util.spine_set_alpha_fade(knight, 0, 0.3)

	wait_for_sec(0.5)

	local coke = get_field_object(self.coke_name)

	character_util.set_position(knight, coke.Position + vector(0.5, 0, 0))
	character_util.set_direction(knight, "left")

	character_util.spine_set_alpha_fade(knight, 1, 0)
end

function local_class:item_floating_routine()
	local start_time = unity_class.time.time
	local duration = 1.5

	local start_pos = user_party_leader.Position + vector(0, 1.5, 0)
	local end_pos = user_party_leader.Position + vector(0, 2, 0)

	local grenade = drop_item_util.create_item({pos = user_party_leader.Position, showoncharacter = true,
												lootstate = "dontfindlooter", itemid = self.grenade_id,
												notforinven = true})

	while unity_class.time.time - start_time < duration do
		local time_passed = (unity_class.time.time - start_time) / duration
		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, time_passed)
		grenade:SetPosition(cur_pos)
		coroutine.yield(nil)
	end

	grenade:ConsumeComplete()
end

function local_class:enter_cave()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local knight = get_character(self.knight_name)
	local coke = get_field_object(self.coke_name)

	character_util.align_party(coke, "down", 1, "linear")

	wait_for_sec(0.5)

	character_util.set_direction(knight, "left")
	character_util.set_anim(knight, {name = "sing", loop = true})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_11", skip = true})
	character_util.remove_anim(knight)

	wait_for_sec(0.3)

	character_util.set_direction(knight, "down")

	wait_for_sec(0.3)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_12", skip = true})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_13", skip = true})

	local star_piece = get_field_object(self.star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(knight.Position + vector(0, 1, 0)))

	wait_for_sec(2)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_14", skip = true})

	field_ui_manager:Show()
	user_party:ResetControllers()

	wait_for_sec(0.5)

	character_util.set_direction(knight, "left")

	wait_for_sec(0.3)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_15"})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_16"})

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_17"})

	character_util.set_anim(knight, {name = "eat", loop = true })

	wait_for_sec(1)

	if self.twinkle_effect ~= nil then
		self.twinkle_effect:Dispose()
		self.twinkle_effect = nil
	end

	--coke.Position = vector(999, 0, 999) --@@ 임시방편
	coke.ActiveState = active_state('disabled')

	local text = CS.Oak.FieldUIFloatingText.Get(knight)
	text:JustPrintItemName(game_string:GetString("snowmountain_1_4_killer_bunny_2_3"))

	wait_for_sec(0.3)

	character_util.remove_anim(knight)

	wait_for_sec(0.3)

	character_util.set_direction(knight, "down")

	wait_for_sec(0.3)

	speech_bubble_util.show_speech_bubble_async(knight, {key = "snowmountain_1_4_killer_bunny_3_18"})

	self.cave_coroutine = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
