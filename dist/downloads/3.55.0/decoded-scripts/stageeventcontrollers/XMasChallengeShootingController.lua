local local_class = newclass('XMasChallengeShootingController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.progress = {
		none = 0,
		talk_to_rudolf = 1,
		clear = 2
	}

	self.current_progress = self.progress.none

	-- npc 이름
	self.rudolf_name = 'rudolf'

	self.get_clear_door_1 = function() return get_field_object('door_1') end
	self.get_clear_door_2 = function() return get_field_object('door_2') end

	-- HACK: 해당 코드는 아래 Hack 루틴이 모두 사라지면 삭제 필요!
	local csg_type = typeof(CS.Oak.ChristmasShooterGame)
	xlua.private_accessible(csg_type)
	self.is_game_playing = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
end

function local_class:need_on_launch()
end

function local_class:on_launch(_)
end

function local_class:hack_exception_prevent_routine()

	while CS.Oak.Game.Instance.CurrentGameMode ~= CS.Oak.GameMode.Lobby do
		coroutine.yield(nil)
	end

	-- Game Mode 가 로비 라면 모든 리스트를 지워 버린다.
	local g = CS.Oak.ChristmasShooterGame.instance

	-- 정상 적인 해제 라면 무시한다
	if g == nil or g.monsterPoolMap == nil then return end
	xlua.private_accessible(typeof(CS.Oak.MessageSystem))

	if g.bossMoveCoroutine ~= nil then
		stop_coroutine(g.bossMoveCoroutine)
		g.bossMoveCoroutine = nil
	end

	if g.bossShotCoroutine ~= nil then
		stop_coroutine(g.bossShotCoroutine)
		g.bossShotCoroutine = nil
	end

	-- 게임 패드 상태를 다시 원복
	self:recover_game_pad_state()

	-- HACK: Super Hack - 가장 마지막에 해당 메시지를 구독 할수 밖에 없는 구조로 날려 버린다.
	local touch_callbacks = CS.Oak.MessageSystem.Instance.subscribeCallbacks[typeof(CS.Oak.TouchEvent)]
	-- pause event 뒤에 존재함. 그래서 -2
	touch_callbacks:RemoveAt(touch_callbacks.Count - 1)

	if touch_callbacks.Count == 0 then
		CS.Oak.MessageSystem.Instance.subscribeCallbacks:Remove(typeof(CS.Oak.TouchEvent))
	end

	local joypad_callbacks = CS.Oak.MessageSystem.Instance.subscribeCallbacks[typeof(CS.Oak.JoypadEvent)]
	joypad_callbacks:RemoveAt(joypad_callbacks.Count - 1)

	if joypad_callbacks.Count == 0 then
		CS.Oak.MessageSystem.Instance.subscribeCallbacks:Remove(typeof(CS.Oak.JoypadEvent))
	end
	CS.UnityEngine.Object.DestroyImmediate(g.gameObject)
	CS.Oak.ChristmasShooterGame.instance = nil
end

function local_class:player_damage_routine()

	local player_rudolph = CS.Oak.ChristmasShooterGame.instance.playerFighter.gameObject.transform:Find('rudolph')
	local rudolph_spine = player_rudolph.transform:GetComponent(typeof(CS.Oak.SpineController))

	local rudolph_spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)
	rudolph_spine:ClearTrack(rudolph_spine_track)
	rudolph_spine:SetAnimation(rudolph_spine_track, 'idle', true)

	local player_knight = CS.Oak.ChristmasShooterGame.instance.playerFighter.gameObject.transform:Find('knight_female_1')
	local knight_spine = player_knight.transform:GetComponent(typeof(CS.Oak.SpineController))

	local knight_spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)
	knight_spine:ClearTrack(knight_spine_track)
	knight_spine:SetEmotion('attack', true)
	knight_spine:SetAnimation(knight_spine_track, 'eat', true)

	local player_princess = CS.Oak.ChristmasShooterGame.instance.playerFighter.gameObject.transform:Find('princess')
	local princess_spine = player_princess.transform:GetComponent(typeof(CS.Oak.SpineController))

	local princess_spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)
	princess_spine:ClearTrack(princess_spine_track)
	princess_spine:SetAnimation(princess_spine_track, 'success', true)

	while CS.Oak.ChristmasShooterGame.instance == nil or
			CS.Oak.ChristmasShooterGame.instance.miniGameState ~= CS.Oak.ChristmasShooterGameState.Playing do

		coroutine.yield(nil)

		if self.is_game_playing == false then
			return
		end
	end

	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Show()

		-- 보물상자, 환경설정, 대화창 제거 (루아에서 NavigationBar GetChild 코드 안쓰게 수정)
		CS.Oak.UI.NavigationBar.Instance:SetActiveFieldResourceBoxAndSettingAndChatButton(false)
	end

	knight_spine:ClearTrack(knight_spine_track)
	knight_spine:SetEmotion('attack', true)
	knight_spine:SetAnimation(knight_spine_track, 'eat', true)

	princess_spine:ClearTrack(princess_spine_track)
	princess_spine:SetAnimation(princess_spine_track, 'success', true)

	local cur_hp = CS.Oak.ChristmasShooterGame.instance.playerInfo.playerHp

	-- 해당 상태가 True 이면 계속 돈다
	while self.is_game_playing == true and CS.Oak.ChristmasShooterGame.instance ~= nil do

		if not is_unity_null(stage.FieldUIMiniMap) then
			stage.FieldUIMiniMap.gameObject:SetActive(false)
		end

		if cur_hp ~= CS.Oak.ChristmasShooterGame.instance.playerInfo.playerHp then
			cur_hp = CS.Oak.ChristmasShooterGame.instance.playerInfo.playerHp

			if cur_hp <= 0 then
				return
			end

			rudolph_spine:DamageRedPulse()
			rudolph_spine:DamageSquish(1.0)

			knight_spine:ClearTrack(knight_spine_track)
			knight_spine:SetEmotion('damaged', true)
			knight_spine:SetAnimation(knight_spine_track, 'embarrassed', true)
			knight_spine:DamageRedPulse()
			knight_spine:DamageSquish(1.0)

			princess_spine:ClearTrack(princess_spine_track)
			princess_spine:SetAnimation(princess_spine_track, 'embarrassed', true)
			princess_spine:DamageRedPulse()
			princess_spine:DamageSquish(1.0)

			wait_for_sec(1)
			knight_spine:ClearTrack(knight_spine_track)
			knight_spine:SetEmotion('attack', true)
			knight_spine:SetAnimation(knight_spine_track, 'eat', true)

			princess_spine:ClearTrack(princess_spine_track)
			princess_spine:SetAnimation(princess_spine_track, 'success', true)
		end

		if CS.Oak.ChristmasShooterGame.instance.miniGameState ~= CS.Oak.ChristmasShooterGameState.Playing then
			self.is_game_playing = false
		end
		coroutine.yield(nil)
	end
end


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	local rudolf = get_character('rudolf')
	character_util.remove_relate_event(rudolf, self.cs_controller)

	self.cs_controller = nil

	local shooting_game_instance = CS.Oak.ChristmasShooterGame.instance
	if not is_unity_null(shooting_game_instance) then
		CS.UnityEngine.Object.DestroyImmediate(shooting_game_instance.gameObject)
	end

	CS.Oak.ChristmasShooterGame.instance = nil
end


function local_class:on_stage_loaded_event(_)
	local rudolf = get_character('rudolf')

	character_util.set_position(rudolf, vector(-0.5, 0, 6))

	-- 퀘스트 마커 표시
	ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(-0.5, 1, 6))
	character_util.add_listener(rudolf, self.cs_controller)

	return true
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local rudolf = get_character(self.rudolf_name)
		if type_util.is_interacted_target(e, rudolf) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_mini_game, self))
			return true
		end

	end

	if lua_helper.type_compare(e, CS.Oak.MiniGameEndEvent) and e.Name == 'ChristmasShooterGame' then

		if e.Success then
			sp_util.play_normal_screenplay(self.stage_clear, self)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.game_over, self))
		end

		return true
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e.Params ~= nil and e.Params[0] == "ChristmasShooterGame" and  e.Params[1] == "GameOver" and e.Params[2] then
			self.wave_num = tonumber(e.Params[2])
		elseif e.Params ~= nil and e.Params[0] == 'ChristmasShooterGameLoaded' then
			self.is_game_playing = true
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.player_damage_routine, self))
			return true
		end
	end

	return false
end

-- 미니게임 시작
function local_class:start_mini_game()
	local choose
	local rudolf = get_character(self.rudolf_name)

	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	character_util.align_party(rudolf, 'down', 0.5, 'arc')
	character_util.set_direction(rudolf, 'down')

	if self.current_progress == self.progress.none then
		self.current_progress = self.progress.talk_to_rudolf

		character_util.set_emotion(rudolf, { name = 'idle' })
		character_util.set_anim(rudolf, { name = 'cross_arm'})
		speech_bubble_util.show_speech_bubble_async(rudolf, {key="xmas_challenge_3_1", skip=true})

		character_util.set_anim(rudolf, { name = 'idle'})
		speech_bubble_util.show_speech_bubble_async(rudolf, {key="xmas_challenge_3_2", skip=true})

		choose = choose_util.play_choose_event({{'xmas_challenge_3_3', 'mercy'}, {'xmas_challenge_3_4', 'brutal'}})

	else
		character_util.set_anim(rudolf, { name = 'idle'})
		speech_bubble_util.show_speech_bubble_async(rudolf, {key="xmas_challenge_3_2", skip=true})

		choose = choose_util.play_choose_event({{'xmas_challenge_3_3', 'mercy'}, {'xmas_challenge_3_4', 'brutal'}})

	end

	if choose == 1 then
		-- 슈팅 게임 시작
		speech_bubble_util.show_speech_bubble_async(rudolf, {key="xmas_challenge_3_6", skip=true})
		quest_marker_util.remove('game_start')
		character_util.remove_anim_and_emotion(rudolf)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_game, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hack_exception_prevent_routine, self))
	else
		character_util.remove_anim_and_emotion(rudolf)
		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end

end

function local_class:start_game()

	field_ui_manager:Hide()
	screen_util.fade_out_circular_async(0.5, 'linear')
	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
	camera_util.move_async(vector(99999,0,99999), 0.01)

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 0)
		field_ui_manager:RemoveUI(user_party[i], CS.Oak.FieldUiType.CharacterStats)
		user_party[i]:HideWeapon(true)
	end

	self:force_disable_game_pad_state()

	yield_return_func(CS.Oak.ChristmasShooterGame.Play, 2)

	self:recover_game_pad_state()
end

function local_class:game_over()
	camera_util.resize_to_default(0.5)
	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader})
	music_player_util.play_stage_music({ state = 'field', mix = 1 })

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0)
		user_party[i]:HideWeapon(false)
	end

	self.is_game_playing = false

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	CS.Oak.UI.NavigationBar.Instance:SetActiveFieldResourceBoxAndSettingAndChatButton(true)

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

function local_class:stage_clear()
	CS.Oak.ChristmasShooterGame.instance:SendClearNoDamaged()

	local rudolf = get_character('rudolf')

	camera_util.resize_to_default(0.5)
	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader})

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0)
	end
	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	self.current_progress = self.progress.none
	character_util.remove_relate_event(rudolf, self.cs_controller)
	rudolf.Interactable.Talk = 'xmas_challenge_3_5'

	camera_util.move_async(user_party.Position + vector(0, 0, 5), 1)

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('door_1', false))
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('door_2', false))
	wait_for_sec(2)

	camera_util.return_to_leader(1)

	CS.Oak.UI.NavigationBar.Instance:SetActiveFieldResourceBoxAndSettingAndChatButton(true)
end

function local_class:force_disable_game_pad_state()
	-- FIXME : 게임패드로 정상적으로 플레이 할 수 있게 하고, 강제로 컨트롤 유형 변경하는 코드 척살할 것
	-- GamePad == 2
	if CS.UnityEngine.PlayerPrefs.GetInt('ControllerType', 0) == 2 then
		local controller_type = CS.Oak.Game.Instance.InputManager.IsPC
				and CS.Oak.UI.OptionsControllerSettings.ControllerType.KeyboardAndMouse
				or CS.Oak.UI.OptionsControllerSettings.ControllerType.None
		message_system:Publish(CS.Oak.ControllerLinkChangedEvent.Create(controller_type))
	end
end

function local_class:recover_game_pad_state()
	-- FIXME : 게임패드로 정상적으로 플레이 할 수 있게 하고, 강제로 컨트롤 유형 변경하는 코드 척살할 것
	-- GamePad == 2
	if CS.UnityEngine.PlayerPrefs.GetInt('ControllerType', 0) == 2 then
		message_system:Publish(CS.Oak.ControllerLinkChangedEvent.Create(CS.Oak.UI.OptionsControllerSettings.ControllerType.GamePad))
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
