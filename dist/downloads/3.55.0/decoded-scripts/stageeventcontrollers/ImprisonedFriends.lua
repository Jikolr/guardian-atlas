local local_class = newclass("ImprisonedFriendsController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.innuit_1_name = 'if_innuit_1'
	self.innuit_2_name = 'if_innuit_2'

	self.diary_name = 'if_diary'

	self.key_door_name = 'if_key_door'

	self.snow_block_name = 'if_melt_snow'

	self.is_snow_block_damaged = false

	self.star_piece_name = 'prison_star_piece'

	self.diary_keys = {
		'snowmountain_5_imprisoned_friends_11',
		'snowmountain_5_imprisoned_friends_12',
		'snowmountain_5_imprisoned_friends_13',
		'snowmountain_5_imprisoned_friends_14',
		'snowmountain_5_imprisoned_friends_15',
		'snowmountain_5_imprisoned_friends_16',
	}

	self.innuit_1_repeat_key = 'snowmountain_5_imprisoned_friends_20'

	self.key_id = 30026	-- 일단은 Desert 챕터의 키를 가져왔음

	self.is_have_key = false
	self.is_door_opened = false
	self.is_talked_dead = false
	self.is_star_piece_found = false
	self.is_girl_crying = false
	self.is_already_got_star_piece = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	local innuit_1 = get_character(self.innuit_1_name)
	local innuit_2 = get_character(self.innuit_2_name)

	if innuit_1.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		innuit_1.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	innuit_2.Interactable = CS.Oak.NonInteractable.Instance

	local door = get_field_object(self.key_door_name)
	door.Interactable = CS.Oak.NonInteractable.Instance

	local diary = get_field_object(self.diary_name)
	diary.Interactable = CS.Oak.NonInteractable.Instance

	self.cs_controller = nil
	self.diary_keys = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local innuit_1 = get_character(self.innuit_1_name)
		local innuit_2 = get_character(self.innuit_2_name)
		local door = get_field_object(self.key_door_name)
		local diary = get_field_object(self.diary_name)

		if lua_helper.reference_equals(e.Target, innuit_1) then
			if self.is_talked_dead then
				if not self.is_girl_crying then
					self.is_girl_crying = true
					sp_util.play_normal_screenplay(self.girl_crying, self)
				end
			else
				if not self.is_have_key then
					sp_util.play_normal_screenplay(self.get_key, self)
				else
					speech_bubble_util.show_speech_bubble(innuit_1,
							{key = 'snowmountain_5_imprisoned_friends_6'})
				end
			end
		elseif lua_helper.reference_equals(e.Target, innuit_2) then
			sp_util.play_normal_screenplay(self.see_friend_dead, self)
		elseif lua_helper.reference_equals(e.Target, diary) then
			sp_util.play_normal_screenplay(self.read_diary, self)
		elseif lua_helper.reference_equals(e.Target, door) then
			if self.is_have_key then
				message_system:Publish(CS.Oak.DoorOpenEvent.Create('if_prison_key', false))
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		local snow = get_field_object(self.snow_block_name)
		if lua_helper.reference_equals(snow, e.FieldObject) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.discovered_innuit, self))
		end

	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self.is_already_got_star_piece = stage_progress:HasStarPiece(self.star_piece_name)
		local door = get_field_object(self.key_door_name)
		local innuit_1 = get_character(self.innuit_1_name)
		local innuit_2 = get_character(self.innuit_2_name)

		message_system:Publish(CS.Oak.DoorOpenEvent.Create('if_prison_key_2'))

		if door.FieldObjectBehaviour:GetType() == typeof(CS.Oak.KeyDoorBehaviour) then
			self.is_door_opened = door.FieldObjectBehaviour.Opened
		end

		if self.is_already_got_star_piece then
			local snow = get_field_object(self.snow_block_name)
			local diary = get_field_object(self.diary_name)

			character_util.set_active_state(innuit_1, 'disabled')
			character_util.set_active_state(innuit_2, 'disabled')
			character_util.set_active_state(snow, 'disabled')

			diary.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			character_util.set_active_state(diary, 'disabled')

		elseif self.is_door_opened then -- 문만 열려있고 스타피스를 안챙겼을 때
			self:setting()

			local snow = get_field_object(self.snow_block_name)
			character_util.set_active_state(snow, 'disabled')

			if innuit_1.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				innuit_1.Interactable:AddListener(self.cs_controller)
			end

			self.is_have_key = true
		else
			self:setting()

			character_util.set_direction(innuit_1, 'right')
			character_util.set_anim(innuit_1, { name = "prostrate" })
			character_util.set_emotion(innuit_1, { name = 'damaged'})
		end
	end

	return false
end

-- 이벤트 시작 전 혹은 진행 중일 때의 스테이지 실행 전 세팅
function local_class:setting()
	local innuit_1 = get_character(self.innuit_1_name)
	local innuit_2 = get_character(self.innuit_2_name)
	local diary = get_field_object(self.diary_name)

	innuit_2.Interactable = CS.Oak.PublishInteractable.Create()

	innuit_2.SpineController:AddFadeColor(innuit_2.Name, unity_class.color.blue, 0.5, 0)

	diary.Interactable = CS.Oak.PublishInteractable.Create()

	diary.Hitbox = CS.Oak.Hitbox(vector(0.7, 1, 0.7))

	local pos = vector_util.get_x0z(diary.Position)

	diary.Position = vector_util.get_x0z(diary.Position, -0.5)

	drop_item_util.create_item({itemid = 20095, notforinven = true, pos = pos,
								lootstate = 'dontfindlooter'})

	field_ui_manager:RemoveUI(innuit_1, CS.Oak.FieldUiType.CharacterStats)
	field_ui_manager:RemoveUI(innuit_2, CS.Oak.FieldUiType.CharacterStats)
end

-- 눈 속에 파묻힌 이누이트가 드러남
function local_class:discovered_innuit()
	local innuit = get_character(self.innuit_1_name)

	if innuit.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		innuit.Interactable:AddListener(self.cs_controller)
	end
end

-- 눈 속에 파묻힌 이누이트 구해줌
function local_class:get_key()
	local innuit = get_character(self.innuit_1_name)
	local door = get_field_object(self.key_door_name)

	self.is_have_key = true

	door.Interactable = CS.Oak.PublishInteractable.Create()

	music_player_util.play_sfx({ sfx_name = "01_rustle_01", type_priority = "event", player_priority = "npc" })

	character_util.shake(innuit, 0.04, 1)

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = "01_jump_01", type_priority = "event", player_priority = "npc" })

	character_util.remove_anim(innuit)
	character_util.jump(innuit, 1, 0.5)

	wait_for_sec(0.5)

	character_util.remove_emotion(innuit)

	character_util.align_party(innuit, 'right', 1, 'linear')

	character_util.set_anim(innuit, { name = "sing" })
	character_util.set_emotion(innuit, { name = "tired" })

	speech_bubble_util.show_speech_bubble_async(innuit,
			{key = 'snowmountain_5_imprisoned_friends_1', skip = true})

	character_util.remove_anim(innuit)

	speech_bubble_util.show_speech_bubble_async(innuit,
			{key = 'snowmountain_5_imprisoned_friends_2', skip = true})

	character_util.shake(innuit, 0.04, 9999)
	character_util.set_anim(innuit, { name = "cast" })

	speech_bubble_util.show_speech_bubble_async(innuit,
			{key = 'snowmountain_5_imprisoned_friends_3', skip = true})

	innuit:CancelShake()

	character_util.set_anim(innuit, { name = "hurt" })
	character_util.set_emotion(innuit, { name = "cry" })

	speech_bubble_util.show_speech_bubble_async(innuit,
			{key = 'snowmountain_5_imprisoned_friends_4', skip = true})

	character_util.set_anim(innuit, { name = "sing" })
	character_util.set_emotion(innuit, { name = "tired" })

	speech_bubble_util.show_speech_bubble_async(innuit,
			{key = 'snowmountain_5_imprisoned_friends_5', skip = true})

	music_player_util.play_sfx({sfx_name = '01_throw_01'})
	character_util.set_anim(innuit, {name = 'throw', loop = false, remove_after = 0.5})

	local item = drop_item_util.create_item({pos = innuit.Position, sprscale = 0.6,
											 target = user_party_leader.Position + vector(-0.3, 0, 0),
											 itemid = self.key_id, notforinven = true, lootstate = 'findlooter'})
	wait_for_sec(1)
end

-- 일기장 읽어봄
function local_class:read_diary()
	local diary = get_field_object(self.diary_name)
	diary.Interactable = CS.Oak.NonInteractable.Instance

	for k, v in pairs(self.diary_keys) do
		field_ui_util.show_narration_async({ key = v})
	end
end

-- 시체에 인터랙트 시
function local_class:see_friend_dead()
	if not self.is_talked_dead or self.is_star_piece_found then
		self.is_talked_dead = true
		field_ui_util.show_narration_async({ key = 'snowmountain_5_imprisoned_friends_7'})

		if self.is_star_piece_found then
			return
		end
	end

	wait_for_sec(0.5)

	yield_return_func(self.try_get_star_piece, self)
end

-- 시체를 뒤져보았을 때
function local_class:try_get_star_piece()
	field_ui_util.show_narration_async({ key = 'snowmountain_5_imprisoned_friends_8'})
	local result = choose_util.play_choose_event(
			{{'snowmountain_5_imprisoned_friends_9'}, {'snowmountain_5_imprisoned_friends_10'}})

	if result == 2 then return end

	self.is_star_piece_found = true

	local innuit_2 = get_character(self.innuit_2_name)

	if innuit_2.Position.x < user_party_leader.Position.x then
		character_util.set_direction(user_party_leader, 'left')
	else
		character_util.set_direction(user_party_leader, 'right')
	end

	music_player_util.play_sfx({sfx_name = '03_equipping_01', duration = 1.2, fade_out_time = 0.3})
	character_util.set_anim(user_party_leader, {name = 'eat', loop = true})

	character_util.shake(innuit_2, 0.04, 1.2)

	wait_for_sec(1.2)

	character_util.remove_anim(user_party_leader)

	local star_piece = get_field_object(self.star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(innuit_2.Position + vector(0, 0.5, 0)))
end

-- 친구의 죽음을 알렸을 때i
function local_class:girl_crying()
	local innuit_1 = get_character(self.innuit_1_name)

	if innuit_1.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		innuit_1.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	innuit_1.Interactable.Talk = self.innuit_1_repeat_key

	character_util.align_party(innuit_1, 'right', 1, 'linear')

	character_util.set_emotion(innuit_1, {name = 'surprise'})
	character_util.set_anim(innuit_1, {name = 'cast', loop = true})

	speech_bubble_util.show_speech_bubble_async(innuit_1,
			{key = 'snowmountain_5_imprisoned_friends_17', skip = true})

	speech_bubble_util.show_speech_bubble_async(innuit_1,
			{key = 'snowmountain_5_imprisoned_friends_18', skip = true})

	character_util.remove_emotion(innuit_1)
	character_util.set_emotion(innuit_1, {name = 'tired'})

	speech_bubble_util.show_speech_bubble_async(innuit_1,
			{key = 'snowmountain_5_imprisoned_friends_19', skip = true})

	character_util.set_direction(innuit_1, 'up')
	music_player_util.play_sfx({sfx_name = '01_female_cry_01', duration = 1.7, fade_out_time = 0.5})

	wait_for_sec(1.5)

	character_util.remove_anim(innuit_1)

	character_util.set_direction(innuit_1, 'right')

	speech_bubble_util.show_speech_bubble_async(innuit_1, {key = self.innuit_1_repeat_key, skip = true})
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
