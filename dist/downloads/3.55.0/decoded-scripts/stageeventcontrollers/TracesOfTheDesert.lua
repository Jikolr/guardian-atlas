local local_class = newclass("TracesOfTheDesertController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.archeologist_name = 'dungeon_archeologist'
	self.desertelf_name = 'desertelf_female'

	self.ice_block_name = 'ice_cube_cactus'
	self.snowball_door_name = 'snowball_door'

	self.item_spec_name = 'snowmountain_cactus'

	self.is_event_clear = false
	self.is_get_cactus = false
	self.is_gift_cactus = false

	self.emoticon_pool = nil
end

function local_class:load_resource()
	local snowball_door = get_field_object(self.snowball_door_name)
	self.is_event_clear = snowball_door.FieldObjectBehaviour.IsOpen

	if self.is_event_clear == false then
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')

		local archeologist = get_character(self.archeologist_name)
		archeologist.Interactable:AddListener(self.cs_controller)
		character_util.set_position(archeologist, vector(21, 0, -46))

		local desertelf = get_character(self.desertelf_name)
		desertelf.Interactable.Talk = 'traces_of_the_desert_13'
		character_util.set_position(desertelf, vector(30, 0, -45))
		character_util.set_direction(desertelf, 'left')

		self.emoticon_pool = unity_object_pool.GetOrCreate('emoticon');
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.event_clear_setting, self))
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	local snowball_door = get_field_object(self.snowball_door_name)

	if self.is_event_clear == false then
		message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

		local archeologist = get_character(self.archeologist_name)
		archeologist.Interactable:RemoveRelatedEvent(self.cs_controller)

		self.emoticon_pool = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif event_type == typeof(CS.Oak.ItemGetEvent) then
		self:on_item_get_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local archeologist = get_character(self.archeologist_name)

	if lua_helper.reference_equals(e.Target, archeologist) then
		if self.is_get_cactus == false then
			sp_util.play_normal_screenplay(self.talk_archeologist, self)
		else
			sp_util.play_normal_screenplay(self.show_cactus, self)
		end
	end
end

function local_class:on_damage_event(e)
	local ice_block = get_field_object(self.ice_block_name)

	if lua_helper.reference_equals(e.Info.target, ice_block) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.get_cactus, self))
	end
end

function local_class:on_field_object_destroyed_event(e)
	local ice_block = get_field_object(self.ice_block_name)

	if lua_helper.reference_equals(e.FieldObject, ice_block) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.get_cactus, self))
	end
end

function local_class:on_item_get_event(e)
	local item_data = CS.Oak.GameDataService.GetData("ItemData")
	local archeologist = get_character(self.archeologist_name)

	if e.Getter == user_party_leader then
		if e.Item.ItemId == item_data:GetSpec(self.item_spec_name).Id then
			self.is_get_cactus = true
		end
	elseif e.Getter == archeologist then
		if e.Item.ItemId == item_data:GetSpec(self.item_spec_name).Id then
			self.is_gift_cactus = true
		end
	end
end

function local_class:talk_archeologist()
	local archeologist = get_character(self.archeologist_name)

	party_util.align_party(archeologist, 'right', 1, 'arc')

	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_1', skip = true })
	character_util.set_anim(archeologist, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_2', skip = true })
	character_util.set_anim(archeologist, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_3', skip = true })
	character_util.remove_anim(archeologist)
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_4', skip = true })
end

function local_class:get_cactus()
	local ice_block = get_field_object(self.ice_block_name)

	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.item_spec_name).Id
	local item = drop_item_util.create_item({ pos = ice_block.Position, target = user_party_leader.Position, itemid = item_id, notforinven = true, bounce = true })
	item.ConsumeTarget = user_party_leader

	music_player:PlaySfxOneShot("01_player_popup_01")

	while not self.is_get_cactus do
		coroutine.yield(nil)
	end

	wait_for_sec(0.2)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 무언가 들고있던 도중이었다면 내려놓게함.
	local current_state = user_party_leader.FieldObjectBehaviour.CurrentActionState

	if lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local target = current_state.HoldTarget
		command_util.execute_throw(user_party_leader, target, CS.Oak.DirectionExtensions.ToVector3(user_party_leader.Direction), user_party_leader.Position, 4, false)
	end

	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent, { ItemId = item_data:GetSpec('snowmountain_cactus').Id }, 'snowmountain_cactus_title', 'snowmountain_cactus_subtitle', 'snowmountain_cactus_desc')

	field_ui_manager:Show()
	party_util.reset_controllers()
end

function local_class:show_cactus()
	local archeologist = get_character(self.archeologist_name)

	party_util.align_party(archeologist, 'right', 1, 'arc')

	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.item_spec_name).Id
	local item = drop_item_util.create_item({ pos = user_party_leader.Position, target = archeologist.Position, itemid = item_id, skip_text = true })
	item.ConsumeTarget = archeologist

	music_player:PlaySfxOneShot("01_throw_01")

	while not self.is_gift_cactus do
		coroutine.yield(nil)
	end

	wait_for_sec(0.2)

	character_util.set_emotion(archeologist, { name = 'surprise' })
	character_util.shake(archeologist, 0.05, 0.5)
	music_player:PlaySfxOneShot("03_dialogue_negative_01")
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_5', skip = true, bubble_type = 'shout' })

	camera_util.shake(0.1, 0.3)
	camera_util.resize_to(3, 0.5)

	character_util.normal_double_jump(archeologist, "01_player_jump_01")
	music_player:PlaySfxOneShot("03_dialogue_emphasize_01")
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_6', skip = true, bubble_type = 'shout' })
	character_util.remove_emotion(archeologist)
	character_util.set_anim(archeologist, { name = 'victory_get', loop = false, sfx_name = "01_jump_01" })
	music_player:PlaySfxOneShot("03_dialogue_positive_01")
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_7', skip = true, bubble_type = 'shout' })
	character_util.set_emotion(archeologist, { name = 'greed' })
	character_util.set_anim(archeologist, { name = 'cast2' })
	music_player:PlaySfxOneShot("01_gatcha_point_01")
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_8', skip = true })

	camera_util.resize_to_default()
	wait_for_sec(0.5)

	character_util.remove_emotion(archeologist)
	character_util.set_anim(archeologist, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_9', skip = true })
	character_util.remove_anim(archeologist)
	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_10', skip = true })
	character_util.set_anim(archeologist, { name = 'release', loop = false, sfx_name = "01_swing_01" })
	wait_for_sec(0.5)
	character_util.remove_anim(archeologist)

	local snowball_door = get_field_object(self.snowball_door_name)
	camera_util.move_async(snowball_door.Position, 1)
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.snowball_door_name, false))
	wait_for_sec(2)
	camera_util.move_async(user_party_leader.Position, 1)
	stage_camera:SetTarget(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(archeologist, { key = 'traces_of_the_desert_11', skip = true })
	character_util.move_to_async(archeologist, vector(21, 0, -38), nil, 4, true, true)
	archeologist.ActiveState = active_state('disabled')

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	yield_return(self, 'event_clear_setting')
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
end

function local_class:event_clear_setting()
	local desertelf = get_character(self.desertelf_name)

	character_util.set_position(desertelf, vector(25, 0, -47))
	character_util.set_direction(desertelf, 'down')
	character_util.set_anim(desertelf, { name = 'question', loop = false })
	desertelf.Interactable.Talk = 'traces_of_the_desert_12'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
