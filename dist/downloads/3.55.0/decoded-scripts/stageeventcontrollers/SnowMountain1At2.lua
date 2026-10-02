local local_class = newclass("SnowMountain1At2Controller")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.substage_name = 'substage_3_1'
	self.substage_snowman_name = 'substage_snowman'

	-- 얼음 공주 이벤트 변수
	self.ice_princess_name = "ice_princess"
	self.ice_princess_guard_name = "ice_princess_guard"
	self.ddong_name = "ddong"
	self.jp_ddong_id = 20547
	self.jp_ddong = nil

	self.ice_princess_star_piece_name = "star_piece_2"
	self.ice_princess_box_name = "ice_princess_box"
	self.prison_door_name = "prison_door_3"

	self.ice_princess_intro_zone_name_1 = "ice_princess_intro_1"
	self.ice_princess_intro_zone_name_2 = "ice_princess_intro_2"
	self.ice_princess_end_zone_name = "ice_princess_end"
	self.penance_zone_name = 'penance_zone'

	self.hidden_star_piece_effect_preset = "FX_starpiece_in_character"

	-- NPC
    self.ice_princess = nil
	self.ice_princess_guard = nil
	self.ddong = nil

	-- FieldObject
	self.ice_princess_box = nil

	-- Effect
	self.hidden_star_piece_effect = nil

	-- Flag
	self.is_enter_princess_intro_zone = false
	self.is_talk_with_guard = false
	self.is_enter_princess_end_zone = false
	self.is_penance_zone = false

	-- coroutine
	self.sing_and_dance_coroutine = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')

	self.ice_princess = get_character(self.ice_princess_name)
	self.ice_princess_guard = get_character(self.ice_princess_guard_name)
	self.ddong = get_character(self.ddong_name)
	self.ice_princess_box = get_field_object(self.ice_princess_box_name)

	self.ice_princess_guard:HideWeapon(true)

	if stage_progress:HasStarPiece(self.ice_princess_star_piece_name) then
		character_util.remove_emotion(self.ice_princess)
		character_util.set_active_state(self.ice_princess, "disabled")

		character_util.set_direction(self.ice_princess_guard, "left")
		character_util.set_anim(self.ice_princess_guard, { name = "sleep" })
		character_util.set_emotion(self.ice_princess_guard, { name = "sleep" })

		self.ice_princess_box.ActiveState = CS.Oak.ActiveState.Disabled

		self.is_enter_princess_intro_zone = true
		self.is_enter_princess_end_zone = true
	else
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.prison_door_name))
		character_util.set_direction(self.ice_princess, "left")
		character_util.set_anim(self.ice_princess, { name = "sing" })
		character_util.set_emotion(self.ice_princess, { name = "sing" })

		character_util.shake(self.ice_princess_guard, 0.04, 99999)
		character_util.set_anim(self.ice_princess_guard, { name = "cast" })
		character_util.set_emotion(self.ice_princess_guard, { name = "damaged" })
	end

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	quest_icon.PreLoad()

	--- load check
	if not stage_progress:HasStarPiece(self.ice_princess_star_piece_name) then
		local pool = unity_object_pool.GetOrCreate(self.hidden_star_piece_effect_preset)

		while not CS.Oak.UnityObjectPoolExtensions.IsLoaded(pool) do
			coroutine.yield(nil)
		end

		self.hidden_star_piece_effect = pool:Instantiate(
				self.ice_princess_box.Position, unity_class.quaternion.identity, self.ice_princess_box.transform)

		-- 문 열리고 닫히는 설정
		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.prison_door_name))
	end

	while not quest_icon.IsLoaded do
		coroutine.yield(nil)
	end

	--- substage setup
	if not user_progress:IsStageOpened(self.substage_name) then
		local substage_snowman = get_character(self.substage_snowman_name)
		substage_snowman.Interactable:AddListener(self.cs_controller)
		quest_icon.SetSubstageIcon(substage_snowman)
	end

	return
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	--- substage dispose
	local substage_snowman = get_character(self.substage_snowman_name)
	if substage_snowman ~= nil and lua_helper.type_compare(substage_snowman.Interactable, CS.Oak.NPCInteractable) then
		substage_snowman.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.jp_ddong ~= nil then
		self.jp_ddong:ConsumeComplete()
		self.jp_ddong = nil
	end

	self.ice_princess = nil
	self.ice_princess_guard = nil
	self.ddong = nil
	self.ice_princess_box = nil

	if self.hidden_star_piece_effect ~= nil then
		self.hidden_star_piece_effect:Dispose()
		self.hidden_star_piece_effect = nil
	end

	self.sing_and_dance_coroutine = nil

	self.cs_controller = nil
end

--[[
	입장 연출 함수를 부를 필요가 있는지
	]]
function local_class:need_on_launch()
	local snow_mountain_main_quest_id = 19

	local main_quest = user_progress:GetStartedQuest(snow_mountain_main_quest_id)
	return main_quest ~= nil and not main_quest.IsComplete and (main_quest.InnerProgress == 2 or main_quest.InnerProgress == 3 or
		main_quest.InnerProgress == 10 or main_quest.InnerProgress == 11)
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

--[[
	스테이지 시작시에 입장 연출을 위해 불리는 함수
--]]
function local_class:on_launch_routine()
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		return self:on_damage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return self:on_field_object_destroyed_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return false
	end

	if e.Zone.Name == self.ice_princess_intro_zone_name_1 or e.Zone.Name == self.ice_princess_intro_zone_name_2 then
		if not self.is_enter_princess_intro_zone then
			self.is_enter_princess_intro_zone = true

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.ice_princess_intro_event, self))
		end
	elseif e.Zone.Name == self.ice_princess_end_zone_name then
		if not self.is_enter_princess_end_zone then
			self.is_enter_princess_end_zone = true

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.ice_princess_end_event, self))
		end
	elseif e.Zone.Name == self.penance_zone_name then
		self.is_penance_zone = true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return false
	end

	if e.Zone.Name == self.penance_zone_name then
		self.is_penance_zone = false
	end

	return false
end

function local_class:on_interact_event(e)
	local target = e.Target

	if lua_helper.reference_equals(target, get_character(self.substage_snowman_name))
			and not user_progress:IsStageOpened(self.substage_name) then

		sp_util.play_normal_screenplay(self.substage_open_routine, self, target)
	elseif lua_helper.reference_equals(target, self.ice_princess_guard) then
		if not self.is_enter_princess_end_zone then
			if not self.is_talk_with_guard then
				self.is_talk_with_guard = true

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.talk_with_ice_princess_guard, self))
			else
				speech_bubble_util.show_speech_bubble(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_7' })
			end
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.ice_princess_guard_give_star_piece, self))
		end
	elseif lua_helper.reference_equals(target, self.ddong) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.interact_with_ddong, self))
	end

	return false
end

function local_class:on_damage_event(e)
	if self.is_penance_zone and lua_helper.reference_equals(e.Info.target, user_party_leader) and
			e.Info.type == CS.Oak.DamageType.Trap and e.HpBefore - e.Info:GetTotalDamage() > 0 then
		sp_util.play_normal_screenplay(self.reset_player, self)
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.ice_princess_box) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.appear_ddong_event, self))
	end

	return false
end

function local_class:ice_princess_intro_event()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	camera_util.move_async(vector(87.5, 0, 5), 2)

	character_util.move_to_async(self.ice_princess, vector(85, 0, 5.5), 0.5, nil, true, true)

	character_util.set_anim(self.ice_princess, { name = "sing" })

	local is_kong_japan = CS.Foundations.GameEnvironment.IsKongJapan
	local sfx_to_play = lua_helper.get_conditional_value(is_kong_japan, '01_holy_01', '01_let_it_go_01')
	music_player_util.play_sfx({sfx_name = sfx_to_play})

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_0', skip = true })

	character_util.move_to_async(self.ice_princess, vector(90, 0, 5.5), 1, nil, true, true)

	character_util.set_anim(self.ice_princess, { name = "dance" })

	if CS.Foundations.GameEnvironment.IsKongJapan then
		music_player_util.play_sfx({sfx_name = "01_holy_01"})
	else
		music_player_util.play_sfx({sfx_name = "01_let_it_go_01"})
	end

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_1', skip = true })

	self.sing_and_dance_coroutine = coroutine_manager:StartCoroutine(
			stage.StageGameObject, util.cs_generator(self.sing_and_dance_event, self))

	camera_util.move_async(vector(89, 0, -3), 1)

	wait_for_sec(1)

	character_util.set_direction(self.ice_princess_guard, "up")
	character_util.jump(self.ice_princess_guard, 1, 0.5)
	character_util.set_anim(self.ice_princess_guard, { name = "embarrassed" })

	music_player_util.play_sfx({sfx_name = "03_dialogue_negative_01"})

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_2', skip = true })

	self.ice_princess_guard:CancelShake()
	character_util.set_anim(self.ice_princess_guard, { name = "run" })

	camera_util.move(vector(88, 0, -1.5), 0.7)

	character_util.move_to_async(self.ice_princess_guard, vector(88, 0, -4), nil, 6, true)

	character_util.move_to_async(self.ice_princess_guard, vector(88, 0, -1), nil, 6, true)

	music_player_util.play_sfx({sfx_name = "03_dialogue_sadness_01"})

	character_util.set_anim(self.ice_princess_guard, { name = "attack", sfx_name = "02_heavy_slash_01" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_3', skip = true })

	character_util.set_direction(self.ice_princess_guard, "down")
	character_util.set_anim(self.ice_princess_guard, { name = "cast" })

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	self.ice_princess_guard.Interactable:AddListener(self.cs_controller)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:sing_and_dance_event()
	while true do
		character_util.move_to_async(self.ice_princess, vector(85, 0, 5.5), 1, nil, true, true)

		character_util.set_anim(self.ice_princess, { name = "sing" })

		if screen_util.is_fo_in_screen(self.ice_princess.Position, { bonus_distance = 2 }) or
				screen_util.is_fo_in_screen(vector(90, 0, 5.5), { bonus_distance = 2 }) then
			speech_bubble_util.show_speech_bubble(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_0' })
		end

		wait_for_sec(3)

		character_util.move_to_async(self.ice_princess, vector(90, 0, 5.5), 1, nil, true, true)

		character_util.set_anim(self.ice_princess, { name = "dance" })

		if screen_util.is_fo_in_screen(self.ice_princess.Position, { bonus_distance = 2 }) then
			speech_bubble_util.show_speech_bubble(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_1' })
		end

		wait_for_sec(3)
	end
end

function local_class:talk_with_ice_princess_guard()
	field_ui_manager:Hide()

	character_util.align_party(self.ice_princess_guard, "down", 1, "arc")

	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_4', skip = true })

	character_util.set_emotion(self.ice_princess_guard, { name = "damaged" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_5', skip = true })

	character_util.set_anim(self.ice_princess_guard, { name = "throw" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_6', skip = true })

	character_util.set_anim(self.ice_princess_guard, { name = "cast" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_7', skip = true })

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:ice_princess_end_event()
	stop_coroutine(self.sing_and_dance_coroutine)

	speech_bubble_util.remove_bubble(self.ice_princess)
	character_util.remove_anim(self.ice_princess)

	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	camera_util.move_async(vector(89, 0, 4), 0.5)

	character_util.look_at(self.ice_princess, user_party_leader)
	character_util.jump(self.ice_princess, 1, 0.5)
	character_util.remove_anim(self.ice_princess)

	wait_for_sec(0.5)

	music_player_util.play_sfx({sfx_name = "03_dialogue_positive_01"})
	character_util.set_direction(self.ice_princess, CS.Oak.DirectionExtensions.GetSideDirection(self.ice_princess.Direction))
	character_util.set_anim(self.ice_princess, { name = "victory_get", loop = false })
	character_util.set_emotion(self.ice_princess, { name = "smile" })

	wait_for_sec(1.5)

	character_util.remove_anim(self.ice_princess)

	character_util.align_party(vector(89, 0, 4), "right", 1, "arc")

	character_util.move_to_async(self.ice_princess, vector(89, 0, 4), nil, 4, true, true)

	character_util.set_direction(self.ice_princess, "right")
	character_util.set_anim(self.ice_princess, { name = "sing" })
	character_util.set_emotion(self.ice_princess, { name = "sing" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_8', skip = true })

	character_util.set_emotion(self.ice_princess, { name = "smile" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_9', skip = true })

	character_util.set_anim(user_party_leader, { name = "release", sfx_name = "01_swing_01" })

	wait_for_sec(1)

	camera_util.move(vector(87, 0, 4), 1)

	character_util.remove_anim(user_party_leader)

	character_util.move_to_async(self.ice_princess, vector(86, 0, 4), 1, nil, true, true)

	character_util.set_anim(self.ice_princess, { name = "sing" })
	character_util.set_emotion(self.ice_princess, { name = "sing" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_10', skip = true })

	camera_util.move(vector(88, 0, 6), 1)

	character_util.move_to_async(self.ice_princess, vector(87.5, 0, 6), 1, nil, true, true)

	character_util.set_direction(self.ice_princess, "right")
	character_util.set_anim(self.ice_princess, { name = "sing" })
	character_util.set_emotion(self.ice_princess, { name = "tired" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_11', skip = true })

	camera_util.move(vector(89, 0, 4), 1)

	character_util.move_to_async(self.ice_princess, vector(89, 0, 4), 1, nil, true, true)

	character_util.set_direction(self.ice_princess, "right")
	character_util.set_anim(self.ice_princess, { name = "sing" })
	character_util.set_emotion(self.ice_princess, { name = "sing" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_12', skip = true })

	camera_util.move(vector(88, 0, 4), 0.5)

	character_util.move_to_async(self.ice_princess, vector(87.5, 0, 3), 0.5, nil, true, true)

	character_util.set_direction(self.ice_princess, "right")

	if CS.Foundations.GameEnvironment.IsKongJapan then
		character_util.set_anim(self.ice_princess, { name = "victory_get", loop = false, sfx_name = "01_holy_01" })
	else
		character_util.set_anim(self.ice_princess, { name = "victory_get", loop = false, sfx_name = "01_let_it_go_02" })
	end
	character_util.set_emotion(self.ice_princess, { name = "sing" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess, { key = 'snowmountain_1_2_ice_princess_13', skip = true })

	character_util.move_to_async(self.ice_princess, vector(98, 0, 3), nil, 4, true, true)

	character_util.remove_emotion(self.ice_princess)
	character_util.set_active_state(self.ice_princess, "disabled")

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:appear_ddong_event()
	local is_kong_japan = CS.Foundations.GameEnvironment.IsKongJapan
	if is_kong_japan then
		character_util.spine_set_alpha_fade(self.ddong, 0, 0)
	end
	self.hidden_star_piece_effect:Dispose()

	self.ddong.Interactable:AddListener(self.cs_controller)
	stage.FieldUIManager:RemoveUI(self.ddong, CS.Oak.FieldUiType.CharacterStats)
	character_util.set_position(self.ddong, vector_util.get_x0z(self.ice_princess_box.Position))

	coroutine.yield(nil)

	character_util.jump(self.ddong, 1, 0.5)

	if is_kong_japan then
		self.jp_ddong = drop_item_util.create_item({ pos = self.ddong.Position, target = self.ddong.Position,
									 itemid = self.jp_ddong_id, notforinven = true,
									                 lootstate = 'dontfindlooter', sprscale = 0.7})
	end
end

function local_class:interact_with_ddong()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local key = 'snowmountain_1_2_ice_princess_17'

	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(
			game_string:GetString(key), 0, 1))

	stage.FieldUINarrationBox:Hide()

	wait_for_sec(0.3)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:ice_princess_guard_give_star_piece()
	field_ui_manager:Hide()

	character_util.align_party(self.ice_princess_guard, "down", 1, "arc")

	wait_for_sec(0.5)

	character_util.normal_jump(self.ice_princess_guard, true)
	character_util.set_anim(self.ice_princess_guard, { name = "cast" })
	character_util.set_emotion(self.ice_princess_guard, { name = "surprise" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_14', skip = true })

	character_util.set_anim(self.ice_princess_guard, { name = "clap" })
	character_util.set_emotion(self.ice_princess_guard, { name = "smile" })

	speech_bubble_util.show_speech_bubble_async(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_15', skip = true })

	speech_bubble_util.show_speech_bubble(self.ice_princess_guard, { key = 'snowmountain_1_2_ice_princess_16' })

	character_util.set_direction(self.ice_princess_guard, "left")
	character_util.set_anim(self.ice_princess_guard, { name = "dead", loop = false })

	local star_piece = get_field_object(self.ice_princess_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.ice_princess_guard.Position))

	wait_for_sec(0.3)

	self.ice_princess_guard.Interactable:RemoveRelatedEvent(self.cs_controller)

	field_ui_manager:Show()
	user_party:ResetControllers()

	character_util.set_emotion(self.ice_princess_guard, { name = "sleep" })

	music_player_util.play_sfx({sfx_name = "01_sleep_01", play_pos = self.ice_princess_guard.Position})
end

function local_class:substage_open_routine(target)
	quest_icon.RemoveIcon(target)
	target.Interactable:RemoveRelatedEvent(self.cs_controller)

	character_util.set_direction(target, "down")

	character_util.align_party(target, target.Direction, 1, "arc")

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('03_dialogue_sadness_01')

	character_util.set_emotion(target, { name = 'tired' })
	character_util.set_anim(target, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_giantyeti_open_1', skip = true, bubble_type = 'shout' })

	character_util.remove_anim(target)
	character_util.set_anim(target, { name = 'cross_arm' })

	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_giantyeti_open_2', skip = true })

	character_util.set_anim(target, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_giantyeti_open_3', skip = true })

	character_util.remove_anim_and_emotion(target)

	character_util.set_direction(target, 'up')

	speech_bubble_util.show_speech_bubble_async(target, { key = 'substage_giantyeti_open_4', skip = true })

	local substage_map = get_field_object(self.substage_name).FieldObjectBehaviour
	-- quest와 연관이 없기때문에 이런식으로 열어도 무방
	coroutine.yield(substage_map:OpenStage())

	target.Interactable.Talk = 'substage_giantyeti_open_4'
end

function local_class:reset_player()
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	music_player:PlaySfxOneShot('01_fade_out_02')

	local player_marker = field:GetMarker('reset')
	local brazier_marker = field:GetMarker('holdable')

	party_util.position_party(player_marker.position, player_marker.direction, 'linear')
	local brazier = get_field_object('penance_brazier')
	brazier.Position = brazier_marker.position
	command_util.execute_extinguish(user_party_leader, brazier)
	command_util.execute_extinguish(user_party_leader, get_field_object('trial_brz1'))
	command_util.execute_extinguish(user_party_leader, get_field_object('trial_brz2'))

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
