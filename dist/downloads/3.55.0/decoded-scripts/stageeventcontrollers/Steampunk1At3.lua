local local_class = newclass("Steampunk1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- [StageCustomKey(StageId = 100090003, StageName = 'steampunk_1_3')]
	self.custom_key = {
	}

	-- 기타 상수
	self.train_num = 3

	-- NPC 이름
	self.train_name = 'train_'

	-- 존 이름
	self.gas_room_zone_name = 'gas_room'

	-- 틴트 이름
	self.tint_key = 'steampunk_1_3'

	-- 개츠비 이름
	self.gatsby_name = 'gatsby'

	-- 개츠비 주변 스팀펑크 시민들 이름
	self.gatsby_people_name_1 = 'gatsby_people_1'
	self.gatsby_people_name_2 = 'gatsby_people_2'
	-- 개츠비 sns 번호
	self.gatsby_follower_id = 50
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	if not CS.Oak.UserProgress.Instance.Followers:Contains(self.gatsby_follower_id) then
		local gatsby = get_character(self.gatsby_name)
		character_util.set_position(gatsby, vector(124,0,106))
		character_util.set_direction(gatsby, 'left')
		character_util.set_emotion(gatsby, { name = 'doyagao' })
		gatsby.Interactable:AddListener(self.cs_controller)

		local gatsby_people_1 = get_character(self.gatsby_people_name_1)
		character_util.set_position(gatsby_people_1, vector(125,0,105))
		character_util.set_direction(gatsby_people_1, 'left')
		character_util.set_emotion(gatsby_people_1, { name = 'love' })
		character_util.set_anim(gatsby_people_1, { name = 'sing', loop = true })
		-- 위대해…
		gatsby_people_1.Interactable.Talk = 'steampunk_gatsby_talk_9'

		local gatsby_people_2 = get_character(self.gatsby_people_name_2)
		character_util.set_position(gatsby_people_2, vector(125,0,107))
		character_util.set_direction(gatsby_people_2, 'left')
		character_util.set_emotion(gatsby_people_2, { name = 'love' })
		character_util.set_anim(gatsby_people_2, { name = 'sing', loop = true })
		-- 캐츠비 씨…
		gatsby_people_2.Interactable.Talk = 'steampunk_gatsby_talk_10'
	end

	return
end

function local_class:need_on_launch()
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and main_quest.InnerProgress == 9
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	-- 기차 설정
	for i = 1, self.train_num do
		local cur_train = get_character(self.train_name..i)

		field_ui_manager:RemoveUI(cur_train, CS.Oak.FieldUiType.CharacterStats)
		cur_train.SpineController.IsShadowActive = false
	end
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.gas_room_zone_name then
		field:Tint(self.tint_key, unity_color({ 0.3, 0.5, 0.9, 1}), 0)
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.gas_room_zone_name then
		field:RemoveTint(self.tint_key)
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_character(self.gatsby_name)) then
		sp_util.play_normal_screenplay(self.talk_gatsby, self)
	end
end

function local_class:talk_gatsby()
	local gatsby = get_character(self.gatsby_name)
	party_util.align_party(gatsby, 'left', 1.5, 'arc')

	-- 안녕하신가 old sport.
	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.set_emotion(gatsby, { name = 'doyagao'})
	character_util.set_anim(gatsby, { name = 'cross_arm', loop = true })
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_1', skip = true })

	-- 혹시 큰 돈을 벌고 싶은건가?
	character_util.set_emotion(gatsby, { name = 'smile'})
	character_util.set_anim(gatsby, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_2', skip = true })

	-- 신께 맹세코 내 말을 들으면 부자가 될 수 있어.
	character_util.set_emotion(gatsby, { name = 'doyagao'})
	character_util.set_anim(gatsby, { name = 'victory_get', loop = false, sfx_name = '01_jingak_01' })
	wait_for_sec(0.5)
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_3', skip = true })

	-- 나는 중부의 아주 부자 가문에서 태어났어.
	character_util.set_anim(gatsby, { name = 'cross_arm', loop = true })
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_4', skip = true })

	-- 옥슨에서 공부를 했고 전쟁 영웅이기도 하지.
	character_util.set_anim(gatsby, { name = 'cross_arm', loop = true })
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_5', skip = true })

	-- 그런 내가 좋은 주식을 추천해줄테니 꼭 투자하라고.
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_emotion(gatsby, { name = 'doyagao'})
	character_util.set_anim(gatsby, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_6', skip = true })
	character_util.remove_anim(gatsby)

	-- SNS 추가
	yield_return_func(CS.Oak.AddSNSCoroutine, self.gatsby_follower_id)

	-- 그럼 또 보세 old sport
	music_player:PlaySfxOneShot('01_coop_mvp_01')
	character_util.set_emotion(gatsby, { name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_7', skip = true })

	-- 난 이미 결혼한 전여친을 스토킹해야해서 이만.
	character_util.set_emotion(gatsby, { name = 'doyagao'})
	speech_bubble_util.show_speech_bubble_async(gatsby, { key = 'steampunk_gatsby_talk_8', skip = true })

	gatsby.Interactable:RemoveRelatedEvent(self.cs_controller)

	local gatsby_people_1 = get_character(self.gatsby_people_name_1)
	local gatsby_people_2 = get_character(self.gatsby_people_name_2)
	gatsby_people_1.Interactable.Talk = nil
	gatsby_people_2.Interactable.Talk = nil

	character_util.set_anim(gatsby_people_1, { name = 'walk', loop = true })
	character_util.set_anim(gatsby_people_2, { name = 'walk', loop = true })
	character_util.move_to(gatsby_people_1, vector(125,0,107), 0.4, nil, true)
	character_util.move_to(gatsby_people_2, vector(125,0,108), 0.4, nil, true)
	character_util.move_to_async(gatsby, vector(124,0,108), 0.4, nil, true, true)

	character_util.move_to(gatsby_people_1, vector(125,0,108), 0.2, nil, true)
	character_util.move_to(gatsby_people_2, vector(124,0,108), 0.2, nil, true)
	character_util.move_to_async(gatsby, vector(123,0,108), 0.2, nil, true, true)

	character_util.move_to(gatsby, vector(115,0,108), 1.0, nil, true, true)
	character_util.move_to(gatsby_people_2, vector(116,0,108), 1.0, nil, true)
	character_util.move_to_async(gatsby_people_1, vector(117,0,108), 1.0, nil, true)

	character_util.move_to(gatsby, vector(115,0,109), 0.2, nil, true, true)
	character_util.move_to(gatsby_people_2, vector(115,0,108), 0.2, nil, true)
	character_util.move_to_async(gatsby_people_1, vector(116,0,108), 0.2, nil, true)

	character_util.move_to(gatsby, vector(115,1,114), 1, nil, true, true)
	character_util.move_to(gatsby_people_2, vector(115,1,113), 1, nil, true)
	character_util.move_to_async(gatsby_people_1, vector(116,1,113), 1, nil, true)

	wait_for_sec(0.3)

	character_util.set_position(gatsby, vector(999,0,999))
	character_util.set_position(gatsby_people_1, vector(999,0,999))
	character_util.set_position(gatsby_people_2, vector(999,0,999))
end

function local_class:on_stage_loaded(_)
	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local gatsby = get_character(self.gatsby_name)
	if type_util.is_npc_interactable(gatsby) then
		gatsby.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}