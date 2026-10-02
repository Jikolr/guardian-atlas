local local_class = newclass("Fox1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	return
end

function local_class:need_on_launch()
	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)

	local diary = get_field_object('fairy_diary_3')
	local diary2 = get_field_object('fairy_diary_4')
	if diary ~= nil and diary2 ~= nil then
		self.effect_1 = unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(diary.Position)
		self.effect_2 = unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(diary2.Position)
		self.diary = drop_item_util.create_item(
				{ pos = diary.Position
				, itemid = 20091, lootstate = 'dontfindlooter'
				, notforinven = true, skip_text = true })

		self.diary2 = drop_item_util.create_item(
				{ pos = diary2.Position
				, itemid = 20091, lootstate = 'dontfindlooter'
				, notforinven = true, skip_text = true })
	end

	local to_past =  get_character('to_past')
	local to_present = get_character('to_present')

	local to_past_wall = get_field_object('to_past_wall')
	local to_present_wall = get_field_object('to_present_wall')

	to_past_wall.Hitbox = CS.Oak.Hitbox(vector(1.5, 1, 1.5))
	to_present_wall.Hitbox = CS.Oak.Hitbox(vector(1.5, 1, 1.5))

	to_past:SetGiantFactor('to_past', 1.5)
	to_past.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	to_past.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(to_past, CS.Oak.FieldUiType.CharacterStats)

	to_present:SetGiantFactor('to_present', 1.5)
	to_present.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	to_present.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(to_present, CS.Oak.FieldUiType.CharacterStats)

	character_util.set_anim(to_past, { name = 'nari_idle', loop = true })
	character_util.set_anim(to_present, { name = 'nari_idle', loop = true })

	if q ~= nil and q.InnerProgress <= 18 and q.InnerProgress >=13 and not q.IsComplete then
		return true
	end
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if self.diary ~= nil then
		self.diary:ConsumeComplete()
		self.diary = nil
	end

	if self.diary2 ~= nil then
		self.diary2:ConsumeComplete()
		self.diary2 = nil
	end

	if self.effect_1 ~= nil then
		self.effect_1:Dispose()
		self.effect_1 = nil
	end

	if self.effect_2 ~= nil then
		self.effect_2:Dispose()
		self.effect_2 = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)

	if  lua_helper.reference_equals(e.Target, get_field_object('fairy_diary_3'))
			or lua_helper.reference_equals(e.Target, get_field_object('fairy_diary_4')) then
		sp_util.play_normal_screenplay(self.diary_talk, self, e.Target)
		return true
	end

	return false
end

function local_class:diary_talk(diary)
	fairy = get_character('fairy_basic2')
	fairy2 = get_character('fairy_basic3')

	local back_tint = CS.UnityEngine.Color(0, 0, 0, 1)
	field:Tint(nil, back_tint, 1)
	for i = 1, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 1)
		user_party[i]:HideWeapon(true)
	end
	if diary == get_field_object('fairy_diary_3') then
		camera_util.move(diary.Position + vector(0,0,0.7), 1)

		character_util.move_to_async(user_party.Leader, diary.Position + vector(-1.2,-0.5,0), 1, nil, true, true)
		character_util.set_direction(user_party.Leader, 'right')

		character_util.remove_emotion(fairy)
		character_util.remove_anim(fairy)
		character_util.spine_set_alpha_fade(fairy, 0, 0)
		character_util.set_position(fairy, diary.Position + vector(0,0,0.7))
		character_util.spine_set_alpha_fade(fairy, 1, 1)
		character_util.set_direction(fairy, 'down')
		wait_for_sec(1)

		-- 새 후임이 들어왔다.
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_58", skip = true})
		-- 오랜만에 들어온 후임이라 조금 떨리지만, 잘 가르쳐야지.
		character_util.set_emotion(fairy, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_59", skip = true})
		character_util.spine_set_alpha_fade(fairy, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_direction(fairy, 'right')
		character_util.set_emotion(fairy, { name = 'idle' })
		character_util.spine_set_alpha_fade(fairy, 1, 0.5)
		wait_for_sec(0.5)
		-- 새 후임에게 소리를 치고 말았다.
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_60", skip = true})
		-- 무서운 선임이라고 싫어하지 않을까 걱정이다.
		character_util.set_emotion(fairy, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_61", skip = true})
		character_util.spine_set_alpha_fade(fairy, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_direction(fairy, 'left')
		character_util.set_emotion(fairy, { name = 'idle' })
		character_util.spine_set_alpha_fade(fairy, 1, 0.5)
		wait_for_sec(0.5)

		-- 동생들과 이슬을 마셨다.
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_62", skip = true})
		-- 그냥 이렇게… 우리 세 명이 행복하게 살 수 있으면...
		character_util.set_emotion(fairy, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(fairy, {key="fox_main_s19_63", skip = true})
		character_util.spine_set_alpha_fade(fairy, 0, 1)
		wait_for_sec(1)
		character_util.set_position(fairy, vector(99,0,99))

	elseif diary == get_field_object('fairy_diary_4') then
		camera_util.move(diary.Position + vector(0,0,0.7), 1)

		character_util.move_to_async(user_party.Leader, diary.Position + vector(1.2,-0.5,0), 1, nil, true, true)
		character_util.set_direction(user_party.Leader, 'left')

		character_util.remove_emotion(fairy2)
		character_util.remove_anim(fairy2)
		character_util.spine_set_alpha_fade(fairy2, 0, 0)
		character_util.set_position(fairy2, diary.Position + vector(0,0,0.7))
		character_util.spine_set_alpha_fade(fairy2, 1, 1)
		character_util.set_direction(fairy2, 'down')
		wait_for_sec(1)

		-- … 나의 첫 후임이 생겼다!
		character_util.set_emotion(fairy2, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_64", skip = true})
		-- 정말 잘 해드려야지.
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_65", skip = true})
		character_util.spine_set_alpha_fade(fairy2, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_direction(fairy2, 'left')
		character_util.set_emotion(fairy2, { name = 'awesome' })
		character_util.spine_set_alpha_fade(fairy2, 1, 0.5)
		wait_for_sec(0.5)
		-- … 힘들다고 투정부리는 후임 선녀님이 너무 귀여웠다! 나도 처음에 그랬는데…
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_66", skip = true})

		character_util.set_emotion(fairy2, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_67", skip = true})

		character_util.spine_set_alpha_fade(fairy2, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_direction(fairy2, 'right')
		character_util.set_emotion(fairy2, { name = 'idle' })
		character_util.spine_set_alpha_fade(fairy2, 1, 0.5)
		wait_for_sec(0.5)

		-- … 후임 선녀님 앞에서 슈퍼 천둥 번개 킥을 선보였다.
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_68", skip = true})
		-- 후임 선녀님과 많이 친해진 것 같아 기쁘다.
		character_util.set_emotion(fairy2, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(fairy2, {key="fox_main_s19_69", skip = true})

		character_util.spine_set_alpha_fade(fairy2, 0, 1)
		wait_for_sec(1)
		character_util.set_position(fairy2, vector(99,0,99))
	end

	field:Tint(nil, CS.UnityEngine.Color(1, 1, 1, 1), 1)
	for i = 1, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 1)
		user_party[i]:HideWeapon(false)
	end
	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}