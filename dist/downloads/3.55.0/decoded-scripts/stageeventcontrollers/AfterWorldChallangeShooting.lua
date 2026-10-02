local local_class = newclass("AfterWorldChallangeShootingController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.game_name = 'TargetShootingGame'

	self.get_minigame_start_npc = function()
		return get_character('minigame_start_npc')
	end

	self.get_exit_door = function()
		return get_field_object('exit_door')
	end

	self.progress = {
		none = 1,
		talking = 2,
		won = 3
	}
	self.cur_progress = self.progress.none
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	local minigame_start_npc = self.get_minigame_start_npc()
	character_util.remove_relate_event(minigame_start_npc, self)

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.MiniGameEndEvent) then
		return self:on_mini_game_end_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	local minigame_start_npc = self.get_minigame_start_npc()
	character_util.add_listener(minigame_start_npc, self)
	mini_game_manager:GetOrCreate(self.game_name)
	return true
end

function local_class:on_interact_event(e)
	if self.cur_progress == self.progress.none then
		if lua_helper.reference_equals(e.Target, self.get_minigame_start_npc()) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_talk, self))
			return true
		end
	end
	return false
end

function local_class:on_mini_game_end_event(e)
	if e.Name == self.game_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.minigame_end_routine, self, e.Success))
		return true
	end
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'target_shooting_game_hit_target' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hit_target_routine, self, e.Sender))
		return true
	end
	return false
end
--endregion

function local_class:npc_talk()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.cur_progress = self.progress.talking

	local npc = self.get_minigame_start_npc()

	party_util.align_party(npc.Position, 'down', 0.5)

	-- 저승에 있는 다양한 어트랙션에는 사격 게임도 있다는 내용 (임시)
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'aw_challange_shooting_1', skip = true })

	-- 사격 게임을 해보지 않을래요?
	character_util.set_emotion(npc, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'aw_challange_shooting_2', skip = true })

	local result = choose_util.play_choose_event({
		-- 예
		{ 'aw_challange_shooting_3', 'mercy' },
		-- 아니오
		{ 'aw_challange_shooting_4', 'normal' }
	})

	if result == 1 then
		-- 미니게임 시작
		self:play_minigame()
	else
		self.cur_progress = self.progress.none
		party_util.reset_controllers()
		field_ui_manager:Show()
	end

	character_util.remove_emotion(npc)
end


function local_class:play_minigame()
	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.game_name, 'substage_afterworld_1', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield(nil)
	end

	mini_game_manager:StartMiniGame(self.game_name)
end

function local_class:hit_target_routine(target)
	if target ~= nil then
		character_util.air_spin(target)
		wait_for_sec(2)
	end
end

function local_class:minigame_end_routine(is_success)
	local npc = self.get_minigame_start_npc()
	party_util.align_party(npc.Position + vector(-0.5, 0, -1), 'left', 0)
	mini_game_manager:DisposeMiniGame(self.game_name)

	wait_for_sec(0.25)
	music_player_util.play_stage_music({ state = 'field'})
	screen_util.fade_in_circular_async(1, 'linear')

	if is_success then
		local exit_door = self.get_exit_door()

		-- 축하드려요!! 다음에 또 찾아주실 거죠?
		music_player_util.play_sfx_one_shot('01_coop_mvp_01')
		character_util.set_emotion(npc, { name = 'smile' })
		character_util.set_anim(npc, { name = 'cast' })
		speech_bubble_util.show_speech_bubble_async(npc, { key = 'hot_spring_ticket_seller_6', skip = true })

		camera_util.move_async(exit_door.Position, 2)
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('exit_door', false))

		wait_for_sec(3)
		camera_util.return_to_leader(2)

		self.cur_progress = self.progress.won
		character_util.remove_emotion(npc)

		character_util.remove_relate_event(npc, self)
		npc.Interactable.Talk = 'hot_spring_ticket_seller_6'
		npc.Interactable.TalkSfx = '01_coop_mvp_01'
	else
		-- 이런, 제가 더 안타깝네요. 언제든 다시 찾아와 주세요.
		character_util.set_emotion(npc, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(npc, { key = 'hot_spring_ticket_seller_5', skip = true })
		character_util.remove_emotion(npc)

		self.cur_progress = self.progress.none
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
