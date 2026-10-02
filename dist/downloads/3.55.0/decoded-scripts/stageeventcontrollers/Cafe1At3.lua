local local_class = newclass("Cafe1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.target_score = 0
end

function local_class:load_resource()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress >= 14 then
		message_system:Subscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent), 'on_event')
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress <= 13 and q.InnerProgress >= 10 and not q.IsComplete then
		if q==nil then

		end

		return true
	end

	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:dispose()
	local yuze = get_character('yuze')
	if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		yuze.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.target_score = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.SuccubusCafeEndEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_event_end, self, e.IsCancelled, e.Sales))

	end


	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		if user_progress:GetStartedQuest(60033).InnerProgress < 14 then
			self:stage_setting_in_quest()
		elseif user_progress:GetStartedQuest(60033).InnerProgress < 22 then
			self:stage_setting()
		end
	end
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) and e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, get_field_object('school_brazier')) then
			if e.Zone.Name == 'school_fire_spot' and not e.FieldObject.CombustibleBehaviour.IsBurning then
				command_util.execute_burn(user_party.Leader, e.FieldObject, false)
			end
		elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'cafe' then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
		end
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'cafe' and e.FullLeave then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_cafe_main', state = 'event', mix = 1.5 })
		end
	end

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) and lua_helper.reference_equals(e.Target, get_character('yuze')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_manage_start, self))
	end

	return false
end

--카페 이벤트 시작
 --카페 운영 파트 시작
 function local_class:cafe_manage_start()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q.InnerProgress <= 13 then
		return true
	end


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

function local_class:stage_setting_in_quest()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	local cam = get_character('camera')

	get_field_object('camera').Transform.localRotation = unity_class.quaternion.Euler(vector(0, 90, 0))
	command_util.execute_holdup(cam, get_field_object('camera'), cam.Position)

	local trash_pos= vector(13, 0, -67)
	self.trash_list = {}
	local count = 0
	while count < 35 do
		local x = CS.UnityEngine.Random.Range(-4, 5)
		local z = CS.UnityEngine.Random.Range(-1, 3)
		local x2 = CS.UnityEngine.Random.Range(-1.5, 1.5)
		local z2 = CS.UnityEngine.Random.Range(-1.5, 1.5)

		local throw_pos = trash_pos + vector(x, 0, z2)
		local throw_pos2 = throw_pos + vector(x2, 0, z)
		local random_count = count % 5 + 1
		local itemid
		if random_count == 1 then
			itemid = 20154
		elseif random_count == 2 then
			itemid = 20184
		elseif random_count == 3 then
			itemid = 20154
		elseif random_count == 4 then
			itemid = 20154
		elseif random_count == 5 then
			itemid = 20154
		else
			itemid = 20154
		end

		local trash_item = drop_item_util.create_item(
				{ pos = throw_pos2, itemid = itemid, lootstate = 'dontfindlooter'
				, notforinven = true, skip_text = true })

		local rotation = CS.UnityEngine.Random.Range(0, 360)
		trash_item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, rotation, 0)
		trash_item.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, rotation, 0)
		table.insert(self.trash_list, trash_item)

		count = count + 1
	end

	local trash_pos= vector(17, 0, -97)
	self.trash_list = {}
	local count = 0
	while count < 30 do
		local x = CS.UnityEngine.Random.Range(-3, 5)
		local z = CS.UnityEngine.Random.Range(-2, 4)
		local x2 = CS.UnityEngine.Random.Range(-1.5, 1.5)
		local z2 = CS.UnityEngine.Random.Range(-1.5, 1.5)

		local throw_pos = trash_pos + vector(x, 0, z2)
		local throw_pos2 = throw_pos + vector(x2, 0, z)
		local random_count = count % 5 + 1
		local itemid
		if random_count == 1 then
			itemid = 20154
		elseif random_count == 2 then
			itemid = 20184
		elseif random_count == 3 then
			itemid = 20154
		elseif random_count == 4 then
			itemid = 20154
		elseif random_count == 5 then
			itemid = 20154
		else
			itemid = 20154
		end

		local trash_item = drop_item_util.create_item(
				{ pos = throw_pos2, itemid = itemid, lootstate = 'dontfindlooter'
				, notforinven = true, skip_text = true })

		local rotation = CS.UnityEngine.Random.Range(0, 360)
		trash_item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, rotation, 0)
		trash_item.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, rotation, 0)
		table.insert(self.trash_list, trash_item)

		count = count + 1
	end

	local g3_1 = get_character('g3_1')
	local g3_2 = get_character('g3_2')

	character_util.set_position(g3_1, g3_1.Position + vector(30, 0, 0))
	character_util.set_position(g3_2, g3_2.Position + vector(30, 0, 0))

	g3_1.Interactable.Talk = 'cafe_stg3_g3_1'
	g3_2.Interactable.Talk = 'cafe_stg3_g3_2'

	for i = 1, 5 do
		local guard = get_character('bianca_guard_'..i)

		if i <= 2 then
			guard.Interactable.Talk = 'cafe_stg3_guard_1'
		else
			guard.Interactable.Talk = 'cafe_stg3_guard_2'
		end

	end

	if q.InnerProgress ~= 11 then
		for i = 1, 6 do
			local temp = get_field_object('school_fire_'..i)
			temp.ActiveState = active_state('disabled')
		end
	end
end

function local_class:stage_setting()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q.InnerProgress ~= 11 then
		for i = 1, 6 do
			local temp = get_field_object('school_fire_'..i)
			temp.ActiveState = active_state('disabled')
		end
	end

	if q.InnerProgress >= 13 then
		local yuze = get_character('yuze')

		character_util.set_position(yuze, vector(0.5, 0, 9))

		if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			yuze.Interactable:AddListener(self.cs_controller)
		end
	end
end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	local start_marker = field:GetMarker('default_start')

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

	character_util.set_position(user_party.Leader, start_marker.position)

	screen_util.fade_in_async(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	if q.InnerProgress ~= 13 then
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(start_marker.position,
			CS.Oak.Direction.Up, game_string:GetString(stage.Name)))
	end

	end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}