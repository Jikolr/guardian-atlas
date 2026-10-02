local local_class = newclass("NightmareChina1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	local pot_merchant = get_character("pot_merchant")
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	pot_merchant.Interactable:AddListener(self.cs_controller)

	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	return user_progress:GetStartedQuest(93).InnerProgress == 3
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)

	local event_type = e:GetType()
	if(event_type == typeof(CS.Oak.InteractEvent)) then -- pot_merchant 대사

		self:interact_event(e)
	end
	return false
end
function local_class:interact_event(e)

	local character = get_character("pot_merchant")
	if lua_helper.reference_equals(e.Target, character) then

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pot_merchant_talk, self))
	end
end
function local_class:pot_merchant_talk() -- pot_merchant 대사

	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	local pot_merchant = get_character("pot_merchant")
	character_util.set_direction(pot_merchant, "left")
	party_util.align_to_target(pot_merchant.Position, 'left', 1, "linear")

	speech_bubble_util.show_speech_bubble_async(pot_merchant, {key = "nightmare_china_3_pot_merchant_1", skip =  true })

	character_util.set_anim(pot_merchant, {name = 'release', loop = true, sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(pot_merchant, {key = "nightmare_china_3_pot_merchant_2", skip =  true })

	character_util.set_anim(pot_merchant, {name = 'cast2', loop = true})
	speech_bubble_util.show_speech_bubble_async(pot_merchant, {key = "nightmare_china_3_pot_merchant_3", skip =  true })

	music_player:PlaySfxOneShot('01_clap_01')
	character_util.set_anim(pot_merchant, {name = 'clap', loop = true})
	speech_bubble_util.show_speech_bubble_async(pot_merchant, {key = "nightmare_china_3_pot_merchant_4", skip =  true })

	character_util.remove_anim(pot_merchant)
	character_util.set_direction(pot_merchant, "down")
	wait_for_sec(0.5)

	user_party:ResetControllers()
	stage.FieldUIManager:Show()

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}