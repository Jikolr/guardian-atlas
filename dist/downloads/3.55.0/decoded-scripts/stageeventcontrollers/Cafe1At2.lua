local local_class = newclass("Cafe1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.dark_succubus = CS.UnityEngine.Color(0.4, 0.4, 0.4, 0.4)
	self.drained_color = CS.UnityEngine.Color(0.2, 0.2, 0.2)

	self.is_healing_list = {false, false, false, false}

	--정기를 다 주고 쓰러져있는 사람들
	self.power_drained_pos = {vector(12, 0, 14), vector(21, 0, 17), vector(35, 0, 14), vector(40, 0, 16),
	vector(17, 0, 18)}

	--정기를 다 준 사람들 치료해주는 서큐버스
	self.healing_succubus_pos = {vector(13, 0, 14), vector(20, 0, 17), vector(34, 0, 14), vector(41, 0, 16)}

	--정기 빨린 후 틴트
	self.drained_color = CS.UnityEngine.Color(0.2, 0.2, 0.2)

	self.target_score = 0

	self.has_dark = false

end

function local_class:load_resource()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress >= 10 then
		message_system:Subscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent), 'on_event')
	end

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == 'cafe_1_2' then
		quest_util.load_pool_resource(
			  'FX_heal_a'
		)
	 end
end

function local_class:need_on_launch()

	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress <= 8 and q.InnerProgress >= 5 and not q.IsComplete then
		if q==nil then

		end
		message_system:Publish(CS.Oak.DoorCloseEvent.Create('cafe_door_1', false))
		self:drained_people_setting()

	else
		local yuze = get_character('yuze')
		if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			yuze.Interactable:AddListener(self.cs_controller)
		end
	end
	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object('cafe_table_1')) then
		speech_bubble_util.show_speech_bubble(get_character('succubus_2'), {key = 'cafe_s6_22'})

	elseif lua_helper.reference_equals(e.Target, get_field_object('cafe_table_2')) then
		speech_bubble_util.show_speech_bubble(get_character('succubus_1'), {key = 'cafe_s6_22'})

	elseif lua_helper.reference_equals(e.Target, get_character('yuze')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_manage_start, self))

	else
		for i = 1, 4 do
			local healing_succubus = get_character('healing_succubus_'..i)
			local power_drained = get_character('power_drained_'..i)
			if lua_helper.reference_equals(e.Target, healing_succubus) or lua_helper.reference_equals(e.Target, power_drained) then
				if self.is_healing_list[i] == false then
					self.is_healing_list[i] = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.healing_succubus, self, healing_succubus, power_drained, i))
				end
				break

			end

		end

	end

	return true
end

function local_class:healing_succubus(healing_succubus, target, i)
	character_util.shake(target, 0.02, 999)
	speech_bubble_util.show_speech_bubble_async(target, { key = 'cafe_s6_'..(i + 6), skip = false })
	character_util.stop_shake(target)

	character_util.set_emotion(healing_succubus, { name = 'attack', loop = true })
	character_util.set_anim(healing_succubus, { name = 'cast2', loop = true })

	if i % 2 == 0 then
		speech_bubble_util.show_speech_bubble_async(healing_succubus, {key = 'cafe_s6_11', skip = false})
	else
		speech_bubble_util.show_speech_bubble_async(healing_succubus, {key = 'cafe_s6_12', skip = false})
	end

	target.SpineController:HealGreenPulse()

	local heal_fx = unity_object_pool.GetOrCreate('FX_heal_a'):Instantiate(target.Position)
	heal_fx.transform.localScale = vector(0.5, 0.5, 0.5)
	target.SpineController:AddFadeColor(target.Name, CS.UnityEngine.Color(0, 1, 0, 1), 1, 0)
	target.SpineController:RemoveFadeColor(target.Name, 0.3)
	wait_for_sec(0.5)
	heal_fx:Dispose()

	heal_fx = unity_object_pool.GetOrCreate('FX_heal_a'):Instantiate(target.Position)
	heal_fx.transform.localScale = vector(0.5, 0.5, 0.5)
	target.SpineController:AddFadeColor(target.Name, CS.UnityEngine.Color(0, 1, 0, 1), 1, 0)
	target.SpineController:RemoveFadeColor(target.Name, 0.3)
	wait_for_sec(0.5)
	heal_fx:Dispose()

	character_util.set_emotion(healing_succubus, { name = 'tired', loop = true })
	character_util.set_anim(healing_succubus, { name = 'seat', loop = true })

	self.is_healing_list[i] = false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))

end

function local_class:dispose()
	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	for i = 1, 4 do
		local succubus = get_character('healing_succubus_'..i)
		if succubus.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			succubus.Interactable:RemoveRelatedEvent(self.cs_controller)
		end

		local power_drained = get_character('power_drained_'..i)
		if power_drained.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			power_drained.Interactable:RemoveRelatedEvent(self.cs_controller)
		end
	end

	local yuze = get_character('yuze')
	if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		yuze.Interactable:RemoveRelatedEvent(self.cs_controller)
	end


end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	if event_type == typeof(CS.Oak.SuccubusCafeEndEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_event_end, self, e.IsCancelled, e.Sales))
	end
	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'succubus_cafe' then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
		end
	end
	if event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'succubus_cafe' and e.FullLeave then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_cafe_main', state = 'event', mix = 1.5 })
		end
	end

	return false
end

--카페 이벤트 시작
 --카페 운영 파트 시작
function local_class:cafe_manage_start()
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	local yuze = get_character('yuze')
	local choice = 0

	character_util.align_party(yuze.Position, 'down', 1, 'linear')

	--어때, 이제 장사 시작할 준비 됐어?
	character_util.set_anim(yuze, { name = 'bomb_idle', loop = true })
	character_util.set_emotion(yuze, { name = 'smile', loop = true })
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'cafe_s9_14', skip = true })

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	--네
	branches:Add({
		Text = game_string:GetString('cafe_s9_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	--아니오
	branches:Add({
		Text = game_string:GetString('cafe_s9_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = yuze

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end
	character_util.remove_anim_and_emotion(yuze)

	--선택지 준비 됐어?
	if choice == 1 then
		--카페 운영 시작.
		message_system:Publish(CS.Oak.SuccubusCafeStartEvent.Create(self.target_score))

	else
		--인터랙트 종료.
		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end

 end

--카페 이벤트 끝
function local_class:cafe_event_end(iscancelled, score)

	music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
	if score >= self.target_score then
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()

	elseif iscancelled then
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()

	else
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end
 end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine()
	local party_list = {}

	for i = 0, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		if i ~= 1 then
			character_util.convert_to_npc(party_list[i])
			party_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end

	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress >= 8 then
		if q==nil then

		end

		local bianca_door = get_field_object('bianca_door')

		bianca_door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		local door_animator = bianca_door.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

		door_animator:Play('open')

		for i = 1, 2 do
			local guard = get_character('bianca_guard_'..i)
			local guard_2 = get_character('bianca_guard_1_'..i)

			guard_2.Interactable.Talk = 'cafe_s7_14'
			guard.Interactable.Talk = 'cafe_s7_14'

			if i == 1 then
				character_util.set_position(guard, vector(50, 0, 48))
				character_util.set_position(guard_2, vector(49, 0, 48))
			else
				character_util.set_position(guard, vector(53, 0, 48))
				character_util.set_position(guard_2, vector(54, 0, 48))
			end

		end

	end

	if q ~= nil and q.InnerProgress == 9 and not q.IsComplete then
		if q==nil then

		end

	elseif q ~= nil and q.InnerProgress == 7 and not q.IsComplete then
		character_util.set_position(user_party.Leader, vector(17.5, 0, 102))
		camera_util.move(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(18.5, 0, 102),
				CS.Oak.Direction.Right, game_string:GetString(stage.Name)))

	elseif q ~= nil and q.InnerProgress == 8 and not q.IsComplete then
		local bianca = get_character('bianca')
		bianca.Interactable.Talk = ''
		character_util.convert_to_party_member(bianca, user_party, true)
		character_util.remove_anim_and_emotion(bianca)
		character_util.set_position(bianca, vector(77.5, 0, 115.5))
		character_util.set_position(user_party.Leader, vector(77.5, 0, 115.5))
		camera_util.move(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(78.5, 0, 115.5),
				CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
	else
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(-16.5, 0, 0.5),
				CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
	end

	local cafe_table_1 = get_field_object('cafe_table_1')

	cafe_table_1.Interactable = CS.Oak.PublishInteractable.Create()

	local cafe_table_2 = get_field_object('cafe_table_2')

	cafe_table_2.Interactable = CS.Oak.PublishInteractable.Create()

end

function local_class:drained_people_setting()
	for i = 1, 4 do
		local succubus = get_character('healing_succubus_'..i)
		if succubus.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			succubus.Interactable:AddListener(self.cs_controller)
		end

		character_util.set_position(succubus, self.healing_succubus_pos[i])
		character_util.remove_anim_and_emotion(succubus)

		if i == 1 or i == 4 then
			character_util.set_direction(succubus, 'left')
		else
			character_util.set_direction(succubus, 'right')
		end
		character_util.set_emotion(succubus, { name = 'tired', loop = true })
		character_util.set_anim(succubus, { name = 'seat', loop = true })
	end

	for i = 1, 5 do
		local power_drained = get_character('power_drained_'..i)

		power_drained.SpineController:AddColor(power_drained.Name, self.drained_color, 1, 0)

		character_util.set_position(power_drained, self.power_drained_pos[i])
		if i > 4 then
			character_util.set_direction(power_drained, 'left')
			character_util.set_emotion(power_drained, { name = 'damaged', loop = true })
			character_util.set_anim(power_drained, { name = 'prostrate', loop = true })
			power_drained.Interactable.Talk = 'cafe_s6_'..(9)
		else
			character_util.set_direction(power_drained, 'right')
			character_util.set_emotion(power_drained, { name = 'confused', loop = true })
			character_util.set_anim(power_drained, { name = 'prostrate', loop = true })
			power_drained.Interactable.Talk = 'cafe_s6_'..(i + 6)
			if power_drained.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				power_drained.Interactable:AddListener(self.cs_controller)
			end
		end


	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}