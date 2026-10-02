local local_class = newclass('LanaKeyController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_lana = function()
		return get_character('onigirl')
	end

	self.get_key = function()
		return get_field_object('key_2')
	end

	self.inner_progress = -1
	self.complete_quest = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:stage_load_resource()

end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

--region on event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	local lana = self.get_lana()
	local key = self.get_key()

	local quest_id = 197
	if user_progress:GetStartedQuest(quest_id) ~= nil then
		self.inner_progress = user_progress:GetStartedQuest(quest_id).InnerProgress
	end

	self.complete_quest = user_progress:ClearedQuest(quest_id)

	-- 키가 없고, 프로그레스 2 이하
	if self.inner_progress <= 2 and not self.complete_quest then
		character_util.set_with_marker(lana, field:GetMarker('race_onigirl'))

		-- 키 없을때만 이벤트 가능
		if not stage_progress:HasItem(key.Name) then
			character_util.add_listener(lana, self.cs_controller)
			lana.Interactable.Talk = 'futurecastle_oni_girl_2_s3_4'
			--… 네게 도움이 되서 다행이야.
		elseif stage_progress:HasItem(key.Name) and self.inner_progress < 2 then
			lana.Interactable.Talk = 'futurecastle_oni_girl_2_s3_4'
			--… 네게 도움이 되서 다행이야.
		end
	end

	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_lana()) then
		-- 중간에 UI 켜지는것 방지하기 위해 이렇게 사용
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_key, self))
	end

	return false
end
--endregion

function local_class:drop_key()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local lana = self.get_lana()
	local leader = user_party_leader

	quest_icon.RemoveIcon(lana)
	character_util.remove_relate_event(lana, self.cs_controller)
	party_util.align_party_ignore_deactivated_party_member(lana.Position + vector(-0.2, 0, 0), lana.Direction, 1)

	speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_1', skip = true })
	--안녕, 친구!

	character_util.remove_emotion(lana)
	speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_2', skip = true })
	--혹시, 열쇠 필요해?

	character_util.nod_twice(leader)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(lana, 'right')

	wait_for_sec(0.5)

	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(lana, {name = 'eat'})

	speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_3', skip = true })
	--여기있어.

	eat_sfx:Stop()
	character_util.remove_anim(lana)
	character_util.set_direction(lana, 'left')

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_small_key_01')
	-- 열쇠 던져주기
	local fake_key = drop_item_util.create_item(
			{itemid = 30035, notforinven = true, pos = lana.Position, showoncharacter = true,
			 target = leader.Position + vector(0.3, 0, -0.3), sprscale = 0.7, lootstate = 'dontfindlooter'})

	music_player_util.play_sfx_one_shot('01_air_spin_02')
	wait_for_sec(1.1)

	fake_key:ConsumeComplete()

	--실제 열쇠 습득
	local key = self.get_key()
	message_system:SendSync(key, CS.Oak.InteractEvent.Create(leader, key))

	wait_for_sec(0.5)

	if self.inner_progress >= 2 then
		speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_3_0', skip = true })
		--사실 몇 개 더 찾았었는데…

		speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_3_1', skip = true })
		--아까 좀 험한 곳을 빠져나오다 다 흘리고 말았지 뭐야.
	end

	speech_bubble_util.show_speech_bubble_async(lana, { key = 'futurecastle_oni_girl_2_s3_4', skip = true })
	--… 네게 도움이 되서 다행이야.

	if not self.complete_quest then
		if self.inner_progress == 2 then
			lana.Interactable.Talk = ''
			message_system:Publish(CS.Oak.CustomStageEvent.Create(lana, {'ready_for_race'}))
		elseif self.inner_progress < 2 then
			field_ui_manager:Show()
			user_party:ResetControllers()
		end
	end
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
