local local_class = newclass('NightmareFutureCastle4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 퀘스트 id
	self.main_quest_id = 208

	-- 아이템 스펙 이름
	self.ham_item_spec_name = 'ham'

	-- 이벤트 존 이름
	self.valentino_event_zone_name = 'valentino_graboid'

	-- 문 이름
	self.door_name = 'keydoor_1'

	-- 캐릭터를 가져오는 함수
	self.get_valentino = function() return get_character('valentino') end
	self.get_graboid = function() return get_character('valentino_graboid') end

	self.is_saw_valentino_event = false

	---커스텀 데이터 0번 -> 발렌티노 이벤트
	self.valentino_event_index = 0
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name))

	--region valentino init
	local valentino = self.get_valentino()
	character_util.set_emotion(valentino, { name = 'smile' })
	character_util.set_anim(valentino, { name = 'seat' })

	local graboid = self.get_graboid()
	character_util.set_anim(graboid, { name = 'groggy' })
	character_util.set_scale_factor(graboid, nil, 0.3)

	self.is_saw_valentino_event = stage_progress:GetCustomData(self.valentino_event_index)
	if self.is_saw_valentino_event then
		-- 사람은 아무도 먹으면 안 돼, 알았지?!
		valentino.Interactable.Talk = 'nightmare_futurecastle_valentino_5'
	end
	--endregion

	local believer = get_character('believer_2')
	believer.Interactable.Talk = game_string:Format("nightmare_futurecastle_believer_3", user.Name)
end
--endregion

--region launch
function local_class:need_on_launch()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	return main_quest_progress ~= nil and main_quest_progress.InnerProgress == 5
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if not self.is_saw_valentino_event and e.Zone.Name == self.valentino_event_zone_name then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.valentino_event, self))
				return true
			end
		end
	end

	return false
end
--endregion

--region valentino
-- 사막 황소 벌레를 키우는 발렌티노
function local_class:valentino_event()
	local valentino = self.get_valentino()
	local graboid = self.get_graboid()

	self.is_saw_valentino_event = true
	local stage_custom = stage_progress:SetCustomData(self.valentino_event_index, self.is_saw_valentino_event)
	coroutine.yield(CS.Oak.NetworkManager.ApiConnection:SendSetCustom(stage.StageId, stage_custom))

	-- tremors_valentino: (smile, attack으로 ham 던져준 후 표정 유지하고 nodx2하며 대사) 그래, 봉봉아. 맛있지?
	character_util.set_emotion(valentino, { name = 'smile' })
	character_util.set_animation_n_times(valentino, { name = 'eat', upper = true })
	wait_for_sec(0.2)

	-- ham 던져줌
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec('green_ticket_recipe_ham').Id
	local ham = drop_item_util.create_item({ pos = valentino.Position, target = graboid.Position, itemid = item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true })

	music_player_util.play_sfx({ sfx_name = '01_throw_01', parent = valentino, type_priority = 'event', player_priority = 'npc' })
	ham.ConsumeTarget = graboid
	wait_for_sec(1.5)

	-- boss_graboid: spin_cast x2 후 emoticon_bubble_love 띄움.
	music_player_util.play_sfx({ sfx_name = '02_die_graboid_01', parent = graboid, type_priority = 'event', player_priority = 'npc' })
	character_util.set_animation_n_times_async(graboid, { name = 'spin_cast_ready', count = 2 })

	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', parent = graboid, type_priority = 'event', player_priority = 'npc' })
	character_util.show_emoticon_async(graboid.Position + vector(0, 2, 0), nil, 'heart')

	character_util.set_anim(valentino, { name = 'seat' })
	character_util.set_animation_n_times(valentino, { name = 'nod', count = 2, upper = true })
	speech_bubble_util.show_speech_bubble_async(valentino, { key = 'nightmare_futurecastle_valentino_1' })

	-- tremors_valentino: (tired) 에휴… 너희 황소 벌레들 잡으려고 얼마나 고생했는데, 어쩌다가 키우게 됐는지…
	character_util.set_emotion(valentino, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(valentino, { key = 'nightmare_futurecastle_valentino_2' })

	-- boss_graboid: (groggy 유지)
	character_util.set_anim(graboid, { name = 'groggy' })
	wait_for_sec(1)

	-- tremors_valentino: (smile) 그래도, 봉봉이 네가 알에서 깨고 나오자마자 날 보고 재롱 부리던 거 생각하면…
	character_util.set_emotion(valentino, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(valentino, { key = 'nightmare_futurecastle_valentino_3' })

	-- tremors_valentino: (smile) 봉봉아, 우리 오늘은 밖으로 산책 나갈까?!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = valentino, type_priority = 'event', player_priority = 'npc' })
	character_util.remove_anim(valentino)
	wait_all({
		util.cs_generator(function()
			for i = 1, 2 do
				music_player_util.play_sfx({ sfx_name = '01_small_jump_01', parent = valentino, type_priority = 'event', player_priority = 'npc' })
				character_util.normal_jump_async(valentino)
			end
		end),
		util.cs_generator(speech_bubble_util.show_speech_bubble_async, valentino, { key = 'nightmare_futurecastle_valentino_4' })
	})

	-- boss_graboid: (attack 모션 후 emoticon_bubble_happy)
	music_player_util.play_sfx({ sfx_name = '02_die_graboid_01', parent = graboid, type_priority = 'event', player_priority = 'npc' })
	character_util.set_animation_n_times_async(graboid, { name = 'attack' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', parent = graboid, type_priority = 'event', player_priority = 'npc' })
	character_util.show_emoticon_async(graboid.Position + vector(0, 2, 0), nil, 'happy')

	-- tremors_valentino: (smile, nodx2) 사람은 아무도 먹으면 안 돼, 알았지?!
	character_util.set_animation_n_times(valentino, { name = 'nod', count = 2 })
	speech_bubble_util.show_speech_bubble_async(valentino, { key = 'nightmare_futurecastle_valentino_5' })

	-- 사람은 아무도 먹으면 안 돼, 알았지?!
	valentino.Interactable.Talk = 'nightmare_futurecastle_valentino_5'
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
