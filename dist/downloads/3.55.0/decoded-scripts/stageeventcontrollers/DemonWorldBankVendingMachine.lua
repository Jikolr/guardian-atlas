local local_class = newclass("DemonWorldBankVendingMachine")
demon_world_global_event = get_or_create_global_variable('utils/DemonWorldGlobalEvent')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.vending_machine_name = 'demonworld_bank_vendingmachine_'

	self.talk_name = 'demonworld_bank_vending_machine_'

	self.vending_machine_key = 'demonworld_vendingmachine_exclusive_key'

	-- 'water'
	self.water_sprite = 'water_90'

	self.active_machine = {}

	self.price = 10
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_stage_loaded_event()
	for i = 1, 10 do
		local v = get_field_object(self.vending_machine_name .. i)
		if v ~= nil then
			v.Interactable = CS.Oak.PublishInteractable.Create()
			table.insert(self.active_machine, v)
		end
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local target = e.Target
		for i = 1, 10 do
			if target.Name == self.vending_machine_name .. i then
				--TODO 다른 이벤트 (악명 시스템 및 타 퀘스트)와 꼬이지 않도록 처리해주어야 함
				sp_util.play_normal_screenplay(self.interact_vending_machine, self, target, i)
				return true
			end
		end
	end
	return false
end

function local_class:on_exclusive_quest_start_event(e)
	if e.Key ~= self.vending_machine_key then
		for _, v in ipairs(self.active_machine) do
			v.Interactable = CS.Oak.NonInteractable.Instance
		end
	end
end

function local_class:on_exclusive_quest_end_event(e)
	if e.Key ~= self.vending_machine_key then
		for _, v in ipairs(self.active_machine) do
			v.Interactable = CS.Oak.PublishInteractable.Create()
		end
	end
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:interact_vending_machine(target, index)
	local player = user_party.Leader
	local save_weapon = user_party.Leader.Weapon2
	party_util.align_party(target.Position + vector(0.5, 0, -0.5), 'down', 0.5, 'arc')

	wait_for_sec(0.5)

	character_util.move_to_async(player, player.Position + vector(0, 0, 0.5),
			0.5, nil, true, true)

	--"XX 한 XX 를 팔고 있다"
	field_ui_util.show_narration_async({key = game_string:Format(self.talk_name .. 'start',
			game_string:Format(self.talk_name .. 'name_' .. index)), mintotalduration = 1})

	--"구매하시겠습니까? (1 마계 달라)"
	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:Format(self.talk_name .. 'ask', self.price), 0, 1)

	--선택지 - 예 / 아니오
	local result = choose_util.play_choose_event({
		{self.talk_name .. 'yes', 'mercy'},
		{self.talk_name .. 'no', 'normal'}
	})

	yield_return(stage.FieldUINarrationBox, "HideAnimation")

	if result == 2 then return end

	-- 돈이 충분한지 확인
	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	if demon_world_dollar:get_dollar() < self.price then
		--"돈이 없다.."
		field_ui_util.show_narration_async({key = self.talk_name .. 'fail', mintotalduration = 1})
		return
	end

	demon_world_dollar:remove_dollar(self.price)

	character_util.spine_deviate_local(player, vector(0, 0, 0.3), 0.3, 0.3)
	character_util.set_animation_n_times(player, {name = 'attack', count = 1})
	wait_for_sec(0.25)

	music_player_util.play_sfx_one_shot('01_interact_greenland_01')
	music_player_util.play_sfx_one_shot('02_hit_big_01')
	target:Shake(0.05, 0.2)
	wait_for_sec(0.25)
	wait_for_sec(0.5)
	music_player_util.play_sfx_one_shot('01_interact_candyshop_01')
	field_ui_util.show_narration_async({key = game_string:Format(self.talk_name .. 'drink',
			game_string:Format(self.talk_name .. 'name_' .. index)), mintotalduration = 1})

	character_util.set_direction(player, 'left')

	character_util.set_anim(player, { name = 'dualgun_attack_right', loop = false, scale = 0.3 })
	music_player:PlaySfxOneShot('01_drinking_01')
	player.SpineController:SetAttachment('[base]weapon2', self.water_sprite)
	wait_for_sec(1)
	character_util.remove_anim_and_emotion(player)
	character_util.set_anim(player, {name = 'idle'})
	player.SpineController:SetAttachment('[base]weapon2', 'empty')

	if index == 1 then
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_emotion(player, {name = 'sleep_deep'})
		character_util.shake(player, 0.03, 1)
		wait_for_sec(1)
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		character_util.set_anim_and_emotion(player, {name = 'cast2'}, {name = 'awesome'})
		character_util.normal_double_jump(player, '01_player_jump_01')
		wait_for_sec(0.5)
	elseif index == 2 then
		music_player_util.play_sfx_one_shot('01_fat_gnome_03')
		character_util.set_anim_and_emotion(player, {name = 'dead4', loop = false}, {name = 'confused'})
		wait_for_sec(1.35)
		music_player_util.play_sfx_one_shot('01_hit_npc_01')
		wait_for_sec(0.65)
	elseif index == 3 then
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		character_util.set_emotion(player, {name = 'attack'})
		wait_for_sec(0.5)
		music_player_util.play_sfx_one_shot('01_throw_01')
		character_util.set_animation_n_times(player, {name = 'attack', count = 1})
		wait_for_sec(0.1)
		music_player_util.play_sfx_one_shot('01_air_spin_02')
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			local init_pos = player.Position + vector(-0.2, 1, 0)
			local item = drop_item_util.create_item({pos = init_pos, itemid = 20036,
													 lootstate = 'dontfindlooter', skip_text = true})
			local item_sprite = item.SpriteTransform:GetComponent(typeof(CS.CustomSprite))
			local item_start_color = item_sprite.TintColor
			item.ShadowTransform.localScale = unity_class.vector3.zero
			local timer = 0.6
			--drop_item_util.alpha_fade_async(item, 0, 1.5)
			while timer > 0 do
				local dt = unity_class.time.deltaTime
				local p = 1 - (timer / 0.6)
				local y = 1 - (p - 1)*(p - 1)

				item.SpriteTransform.localPosition = vector(p * -5, 5 * y, 0)
				item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 0, p * 720)

				item_sprite.TintColor = item_start_color * unity_class.mathf.Lerp(item_start_color.a, 0, (math.max(0.5, p) - 0.5) * 2)
				item_sprite:Rebuild()

				timer = timer - dt
				coroutine.yield(nil)
			end
			drop_item_util.alpha_fade_async(item, 1, 0)
			item.SpriteTransform.localPosition = unity_class.vector3.zero
			item.SpriteTransform.localRotation = unity_class.quaternion.identity
			item.ShadowTransform.localScale = unity_class.vector3.one
			item:ConsumeComplete()
		end))
		wait_for_sec(1)
	elseif index == 4 then
		character_util.set_emotion(player, {name = 'tired'})
		character_util.show_emoticon_async(player, nil, 'question')
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		character_util.set_anim_and_emotion(player, {name = 'jingak', loop = false, sfx_name = '03_mech_stomp_02'}, {name = 'mad'})
		wait_for_sec(1)
	elseif index == 5 then
		character_util.set_emotion(player, {name = 'sleep_deep'})
		character_util.set_anim(player, 'idle')
		wait_for_sec(0.2)
		character_util.nod_twice(player)
		character_util.set_anim(player, { name = 'idle' })
		wait_for_sec(0.3)
		music_player_util.play_sfx_one_shot('01_clap_01')
		music_player_util.play_sfx_one_shot('01_coop_mvp_01')
		character_util.set_anim_and_emotion(player, {name = 'clap'}, {name = 'smile'})
		wait_for_sec(1)
	elseif index == 6 then
		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		character_util.set_anim_and_emotion(player, {name = 'victory_get', loop = false}, {name = 'awesome'})
		wait_for_sec(1.5)
		character_util.set_emotion(player, {name = 'smile'})
		character_util.nod_twice(player)
		wait_for_sec(0.2)
	elseif index == 7 then
		music_player_util.play_sfx_one_shot('03_runaway_01')
		character_util.set_anim_and_emotion(player, {name = 'cross_arm'}, {name = 'scared'})
		character_util.shake(player, 0.05, 1.5)
		wait_for_sec(1.5)
	elseif index == 8 then
		character_util.set_emotion(player, {name = 'surprise'})
		character_util.set_anim(player, 'idle')
		music_player_util.play_sfx_one_shot('01_small_jump_01')
		player.SpineController:Jump(0.7, 0.3)
		wait_for_sec(0.7)
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		character_util.set_emotion(player, {name = 'damaged'})
		character_util.shake(player, 0.05, 1)
		wait_for_sec(1)
	elseif index == 9 then
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(player, {name = 'question', loop = false}, {name = 'sleep_deep'})
		wait_for_sec(1.5)
	elseif index == 10 then
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		character_util.set_anim_and_emotion(player, {name = 'sing'}, {name = 'smile'})
		wait_for_sec(1.5)
		music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
		character_util.remove_anim_and_emotion(player)
		character_util.set_emotion(player, {name = 'attack'})
		character_util.show_emoticon_async(player, nil, 'notice')
	end
	field_ui_util.show_narration_async({key = self.talk_name .. 'reaction_' .. index, mintotalduration = 1})

	field_ui_util.show_narration_async({key = game_string:Format(self.talk_name .. 'cap'), mintotalduration = 1})

	field_ui_util.show_narration_async({key = game_string:Format(self.talk_name .. 'cap_' .. index), mintotalduration = 1})

	user_party.Leader:SetEquipment(CS.Oak.EquipmentSlot.Weapon2, save_weapon)
	user_party.Leader:RefreshWeaponAttachments()

	character_util.remove_anim_and_emotion(player)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}