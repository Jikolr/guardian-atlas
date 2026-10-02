local local_class = newclass("NightmareTeatans1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.seen_fix_event = false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == 'teatan_fix_event' and not self.seen_fix_event then
				self.seen_fix_event = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatan_fix_event, self))
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		local main_quest = user_progress:GetStartedQuest(81)
		self.seen_fix_event = main_quest == nil or main_quest.InnerProgress ~= 2 or main_quest.IsComplete

		if self.seen_fix_event then
			local npcs = {
				get_character('marty_junior'),
				get_character('marian'),
				get_character('junior_mekasuit')
			}

			for _, npc in ipairs(npcs) do
				npc.ActiveState = active_state('disabled')
			end
		else
			local junior_suit = get_character('junior_mekasuit')
			field_ui_manager:RemoveUI(junior_suit, CS.Oak.FieldUiType.CharacterStats)
		end
	end

	return false
end

-- 마리안과 마티 주니어가 티탄 로봇을 고쳐주는 이벤트
function local_class:teatan_fix_event()
	local marian = get_character('marian')
	local junior = get_character('marty_junior')

	-- 자동반사에 반응할 수 있는 축으로… 여기, 여기.
	speech_bubble_util.show_speech_bubble_async(marian, { key = 'fix_junior_suit_1', portraitname = 'teatan_hero' })

	coroutine.yield(coroutine_class.wait_all(
			util.cs_generator(character_util.move_to_async, marian, marian.Position + unity_class.vector3.left * 0.4, 0.25, nil, nil, true),
			util.cs_generator(character_util.move_to_async, junior, junior.Position + unity_class.vector3.left * 0.4, 0.25, nil, nil, true)
	))

	junior:SetAnimation('eat', true)
	-- 여기, 여기.
	speech_bubble_util.show_speech_bubble_async(junior, { key = 'fix_junior_suit_2' })

	junior:RemoveAnimation()
	character_util.show_emoticon_async(junior, nil, CS.Oak.EmoticonType.Notice)

	junior:SetAnimation('release', true)
	-- 이쪽을 마이크로 케이블로 교체하면 시스템이 더 섬세해지지 않을까요?
	speech_bubble_util.show_speech_bubble_async(junior, { key = 'fix_junior_suit_3' })
	junior:RemoveAnimation()

	marian:SetEmotion('smile', true)
	marian:SetAnimation('nod', true)
	-- 그렇지. 똘똘하네.
	speech_bubble_util.show_speech_bubble_async(marian, { key = 'fix_junior_suit_4', portraitname = 'teatan_hero' })

	junior:SetAnimation('eat', true)
	-- 여기, 이렇게…
	junior.Interactable.Talk = 'fix_junior_suit_oneline_2'

	-- 그렇지. 똘똘하네.
	marian.Interactable.Talk = 'fix_junior_suit_4'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
