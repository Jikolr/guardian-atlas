local local_class = newclass("Cafe1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.dark_succubus = CS.UnityEngine.Color(0.4, 0.4, 0.4, 0.4)

	self.g1_cnt = false
	self.g3_1_cnt = false
	self.g3_2_cnt = false
	self.sec2_cnt = false
	self.battle_1_cnt = false

	self.target_score = 0
end

function local_class:load_resource()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress >= 5 then
		message_system:Subscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent), 'on_event')
	end

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
    if stage.Name == 'cafe_1_1' then
        quest_util.load_pool_resource(
			  'FX_hit',
			  'FX_dead'
        )
     end
end

function local_class:need_on_launch()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	return q ~= nil and not q.IsComplete and q.InnerProgress >= 0 and q.InnerProgress <= 4
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:dispose()
	local yuze = get_character('yuze_emp')
	if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		yuze.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.g1_cnt = nil
	self.g3_1_cnt = nil
	self.battle_1_cnt = nil

	self.target_score = nil
end

function local_class:on_event(e)
	local btl = get_character('battle_1_1')
	local g1 = get_character('g1_1')
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.SuccubusCafeEndEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_event_end, self, e.IsCancelled, e.Sales))

	end

	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		if user_progress:GetStartedQuest(60033).InnerProgress < 22 then
			self:stage_setting_in_quest()
		end
		self:stage_setting()
	end
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if user_progress:GetStartedQuest(60033).InnerProgress < 22 then
			if e.Zone.Name == 'g3_1' and self.g3_1_cnt == false then
				self.g3_1_cnt = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.g3_1, self))
			elseif e.Zone.Name == 'g1' and self.g1_cnt == false then
				self.g1_cnt = true
				-- 카르멘 스튜디오 많이 사랑해주세요!
				music_player:PlaySfxOneShot('01_crowd_clap_03')
				speech_bubble_util.show_speech_bubble(g1, { key = 'cafe_stg1_g1_1', skip = true, bubble_type = 'shout'})
			elseif e.Zone.Name == 'g3_2' and self.g3_2_cnt == false then
				self.g3_2_cnt = true
				music_player:PlaySfxOneShot('01_crowd_shout_03')
			elseif e.Zone.Name == 'BATTLE_1' and self.battle_1_cnt == false then
				self.battle_1_cnt = true
				music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
				speech_bubble_util.show_speech_bubble(btl, { key = 'cafe_stg1_mad', skip = true, bubble_type = 'shout', scale = 1.2, type_speed = 0 })
			end
		end
	end

	if event_type == typeof(CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == 'succubus_dark_zone' then
			if user_party.Leader.Position.x < 40.5 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.succubus_darkened, self, true))
			end
		elseif e.Zone.Name == 'cafe_music' then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
		end
	end

	if event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.FullLeave and e.Zone.Name == 'succubus_dark_zone' then
			if user_party.Leader.Position.x < 40.5 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.succubus_darkened, self, false))
			end
		elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'cafe_music' and e.FullLeave then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_cafe_main', state = 'event', mix = 1.5 })
		end
		return true
	end

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) and lua_helper.reference_equals(e.Target, get_character('yuze_emp')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_manage_start, self))
	end

	return false
end

function local_class:succubus_darkened(is_dark)

	if is_dark then
		if not self.has_dark then
			field:Tint('dark', self.dark_succubus, 1)
			self.has_dark = true
		end
	else
		field:RemoveTint('dark', 1)
		self.has_dark = false
	end

end

function local_class:stage_setting_in_quest()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	local g1_1 = get_character('g1_1')
	local g1_2 = get_character('g1_2')
	local g1_3 = get_character('g1_3')
	local g1_4 = get_character('g1_4')
	local g1_5 = get_character('g1_5')
	local g1_6 = get_character('g1_6')
	local g1_7 = get_character('g1_7')

	character_util.set_position(g1_1, g1_1.Position + vector(-19, 0, 0))
	character_util.set_position(g1_2, g1_2.Position + vector(-19, 0, 0))
	character_util.set_position(g1_3, g1_3.Position + vector(-19, 0, 0))
	character_util.set_position(g1_4, g1_4.Position + vector(-19, 0, 0))
	character_util.set_position(g1_5, g1_5.Position + vector(-19, 0, 0))
	character_util.set_position(g1_6, g1_6.Position + vector(-19, 0, 0))
	character_util.set_position(g1_7, g1_7.Position + vector(-18, 0, 0))

	g1_1.Interactable.Talk = 'cafe_stg1_g1_1'
	g1_2.Interactable.Talk = 'cafe_stg1_g1_2'
	g1_3.Interactable.Talk = 'cafe_stg1_g1_2'
	g1_4.Interactable.Talk = 'cafe_stg1_g1_2'
	g1_5.Interactable.Talk = 'cafe_stg1_g1_3'
	g1_6.Interactable.Talk = 'cafe_stg1_g1_4'
	g1_7.Interactable.Talk = 'cafe_stg1_g1_1'

	local g3_1_1 = get_character('g3_1_1')
	local g3_1_2 = get_character('g3_1_2')
	local g3_1_3 = get_character('g3_1_3')

	character_util.set_position(g3_1_1, vector(-16, 0, 22))
	character_util.set_position(g3_1_2, vector(-12, 0, 23))
	character_util.set_position(g3_1_3, vector(-20, 0, 21))

	character_util.set_direction(g3_1_1, 'right')
	character_util.set_direction(g3_1_2, 'left')
	character_util.set_direction(g3_1_3, 'right')

	character_util.set_emotion(g3_1_1, {name = 'tired'})
	character_util.set_emotion(g3_1_2, {name = 'love'})
	character_util.set_emotion(g3_1_3, {name = 'love'})

	character_util.set_anim(g3_1_1, {name = 'sing', loop = true})
	character_util.set_anim(g3_1_2, {name = 'cross_arm', loop = true, upper = true })
	character_util.set_anim(g3_1_3, {name = 'cross_arm', loop = true, upper = true })
	g3_1_2.Interactable.Talk = 'cafe_stg1_smombie_1'
	g3_1_3.Interactable.Talk = 'cafe_stg1_smombie_4'

	local g3_2_1 = get_character('g3_2_1')
	local g3_2_2 = get_character('g3_2_2')
	local g3_2_3 = get_character('g3_2_3')
	local g3_2_4 = get_character('g3_2_4')

	g3_2_1.Interactable.Talk = 'cafe_stg1_grid3_2_1'
	g3_2_2.Interactable.Talk = 'cafe_stg1_grid3_2_2'
	g3_2_4.Interactable.Talk = 'cafe_stg1_grid3_2_3'

	character_util.set_position(g3_2_1, g3_2_1.Position + vector(40, 0, 0))
	character_util.set_position(g3_2_2, g3_2_2.Position + vector(40, 0, 0))
	character_util.set_position(g3_2_3, g3_2_3.Position + vector(40, 0, 0))
	character_util.set_position(g3_2_4, g3_2_4.Position + vector(40, 0, 0))

	local g3_3_1 = get_character('g3_3_1')
	local g3_3_2 = get_character('g3_3_2')
	local g3_3_3 = get_character('g3_3_3')

	character_util.set_position(g3_3_1, g3_3_1.Position + vector(40, 0, 0))
	character_util.set_position(g3_3_2, g3_3_2.Position + vector(40, 0, 0))
	character_util.set_position(g3_3_3, g3_3_3.Position + vector(40, 0, 0))

	g3_3_1.Interactable.Talk = 'cafe_stg1_grid3_3_1'
	g3_3_2.Interactable.Talk = 'cafe_stg1_grid3_3_3'
	g3_3_3.Interactable.Talk = 'cafe_stg1_grid3_3_2'

	local g7_1 = get_character('g7_1')
	local g7_2 = get_character('g7_2')
	local g7_3 = get_character('g7_3')

	character_util.set_position(g7_1, g7_1.Position + vector(40, 0, 0))
	character_util.set_position(g7_2, g7_2.Position + vector(40, 0, 0))
	character_util.set_position(g7_3, g7_3.Position + vector(40, 0, 0))

	g7_1.Interactable.Talk = 'cafe_stg1_grid7_1'
	g7_2.Interactable.Talk = 'cafe_stg1_grid7_2'
	g7_3.Interactable.Talk = 'cafe_stg1_grid7_3'

	if q.InnerProgress <= 2 then
		local cafe_old = get_field_object('cafe_entrance_old')
		cafe_old.Position = vector(-1, 0, 76)

		local cafe_new = get_field_object('cafe_entrance_new')
		cafe_new.Position = vector(18, 0, 76)

		local cafe_old_invisible = get_field_object('cafe_entrance_invisible_old')
		cafe_old_invisible.Position = vector(0.5, 0, 76)

		local cafe_new_invisible = get_field_object('cafe_entrance_invisible_new')
		cafe_new_invisible.Position = vector(30, 0, 76)

		for i = 1, 36 do
			local temp = get_field_object('cafe_obj_'..i)
			temp.ActiveState = active_state('disabled')
		end
		for i = 1, 30 do
			local temp = get_field_object('cafe_break_'..i)
			temp.Position = temp.Position + vector(0, 0, -20)
		end
	else
		local cafe_old = get_field_object('cafe_entrance_old')
		cafe_old.Position = vector(18, 0, 76)

		local cafe_new = get_field_object('cafe_entrance_new')
		cafe_new.Position = vector(-1, 0, 76)

		local cafe_old_invisible = get_field_object('cafe_entrance_invisible_old')
		cafe_old_invisible.Position = vector(30, 0, 76.2)

		local cafe_new_invisible = get_field_object('cafe_entrance_invisible_new')
		cafe_new_invisible.Position = vector(0.5, 0, 76.2)
	end

	if q.InnerProgress >= 3 then
		local stu_1 = get_character('stu_1')
		local stu_2 = get_character('stu_2')
		local stu_3 = get_character('stu_3')
		local stu_4 = get_character('stu_4')
		local teacher = get_character('succu_teacher')

		stu_1.Interactable.Talk = 'cafe_stg1_stu_after_1'
		stu_2.Interactable.Talk = 'cafe_stg1_stu_after_2'
		stu_3.Interactable.Talk = 'cafe_stg1_stu_after_3'
		stu_4.Interactable.Talk = 'cafe_stg1_stu_after_1'
		teacher.Interactable.Talk = 'cafe_stg1_stu_after_4'

		local succu_1 = get_character('succu_1_emp')
		local succu_2 = get_character('succu_2_emp')
		local succu_3 = get_character('succu_3_emp')
		local succu_4 = get_character('succu_4_emp')
		local succu_5 = get_character('succu_5_emp')
		local succu_6 = get_character('succu_6_emp')
		local yuze = get_character('yuze_emp')

		succu_1.Interactable.Talk = 'cafe_s3_58'
		succu_2.Interactable.Talk = 'cafe_s3_59'
		succu_3.Interactable.Talk = 'cafe_stg1_succu_after_1'
		succu_4.Interactable.Talk = 'cafe_stg1_succu_after_2'
		succu_5.Interactable.Talk = 'cafe_stg1_succu_after_3'
		succu_6.Interactable.Talk = 'cafe_stg1_succu_after_1'

		for i = 1, 16 do
			local temp = get_field_object('cafe_rock_'..i)
			if temp.ActiveState ~= CS.Oak.ActiveState.Disabled then
				temp.ActiveState = active_state('disabled')
			end
		end
	else
		local stu_1 = get_character('stu_1')
		local stu_2 = get_character('stu_2')
		local stu_3 = get_character('stu_3')
		local stu_4 = get_character('stu_4')
		local teacher = get_character('succu_teacher')

		character_util.set_direction(stu_1, 'right')
		character_util.set_direction(stu_2, 'right')
		character_util.set_direction(stu_3, 'left')
		character_util.set_direction(stu_4, 'left')
		character_util.set_direction(teacher, 'down')

		character_util.remove_anim_and_emotion(teacher)

		character_util.set_emotion(stu_1, {name = 'tired'})
		character_util.set_emotion(stu_2, {name = 'tired'})
		character_util.set_emotion(stu_3, {name = 'tired'})
		character_util.set_emotion(stu_4, {name = 'tired'})

		character_util.set_anim(stu_1, {name = 'seat', loop = true})
		character_util.set_anim(stu_2, {name = 'seat', loop = true})
		character_util.set_anim(stu_3, {name = 'seat', loop = true})
		character_util.set_anim(stu_4, {name = 'seat', loop = true})

		character_util.set_position(stu_1, vector(-25, 0.5, 56))
		character_util.set_position(stu_2, vector(-22, 0.5, 52))
		character_util.set_position(stu_3, vector(-26, 0.5, 55))
		character_util.set_position(stu_4, vector(-21, 0.5, 55))

		stu_1.Interactable.Talk = 'cafe_stg1_stu_before_1'
		stu_2.Interactable.Talk = 'cafe_stg1_stu_before_2'
		stu_3.Interactable.Talk = 'cafe_stg1_stu_before_3'
		stu_4.Interactable.Talk = 'cafe_stg1_stu_before_1'
		teacher.Interactable.Talk = 'cafe_stg1_stu_before_4'

		for i = 1, 18 do
			local temp = get_field_object('cafe_school_'..i)
			temp.Position = temp.Position + vector(25, 0, 0)
		end
	end
end

function local_class:stage_setting()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	local guard_1 = get_character('bianca_guard_1')
	local guard_2 = get_character('bianca_guard_2')
	local guard_3 = get_character('bianca_guard_3')
	local guard_4 = get_character('bianca_guard_4')

	guard_1.Interactable.Talk = 'cafe_stg1_guard'
	guard_2.Interactable.Talk = 'cafe_stg1_guard'
	guard_3.Interactable.Talk = 'cafe_stg1_guard'
	guard_4.Interactable.Talk = 'cafe_stg1_guard'

	if q.InnerProgress >= 3 then
		local yuze = get_character('yuze_emp')
		if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			yuze.Interactable:AddListener(self.cs_controller)
		end
	end
end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	local party_list = {}

	local yuze = get_character('yuze')

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

	-- 메인퀘스트가 섹션1일때는 오프닝 연출을 메인퀘스트에게 위임한다.
	if q.InnerProgress == 0 then return end

	if q.InnerProgress == 0 or q.InnerProgress == 1 then
		character_util.set_direction(user_party.Leader, "down")
		character_util.set_emotion(user_party.Leader, {name = 'blush'})
	end

	if q.InnerProgress == 2 then
		character_util.set_position(yuze, vector(0, 0, -1))
		character_util.remove_anim_and_emotion(yuze)
		character_util.set_direction(yuze, "up")
		character_util.convert_to_party_member(yuze, user_party)
		yuze.FieldObjectStatsBehaviour.Immortal = true
	end

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	if q.InnerProgress ~= 4 then
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(0, 0, 0),
			CS.Oak.Direction.Up, game_string:GetString(stage.Name)))


		user_party:StopAndDisableControl()
		stage.FieldUIManager:Hide()

		if q.InnerProgress == 1 then
			field_ui_util.show_narration_async({ key = 'succubus_town_enter_narration' })
		end

		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end
end

--카페 이벤트 시작
 --카페 운영 파트 시작
 function local_class:cafe_manage_start()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q.InnerProgress <= 4 then
		return true
	end


	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	local yuze = get_character('yuze_emp')
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

function local_class:g3_1()
	local g3_1_1 = get_character('g3_1_1')
	local g3_1_2 = get_character('g3_1_2')
	local g3_1_3 = get_character('g3_1_3')

	-- 거기, 오빠! 테라피 안 받으실래요?
	character_util.set_direction(g3_1_1, 'right')
	speech_bubble_util.show_speech_bubble(g3_1_1, { key = 'cafe_stg1_grid3_1_1', skip = false })
	character_util.move_to_async(g3_1_2, vector(-20, 0, 23), nil, 2, true, true)

	-- 응? 핸드폰만 보지 말고~
	character_util.set_direction(g3_1_1, 'left')
	speech_bubble_util.show_speech_bubble(g3_1_1, { key = 'cafe_stg1_grid3_1_3', skip = false })
	character_util.move_to_async(g3_1_3, vector(-12, 0, 21), nil, 2, true, true)


	character_util.set_anim(g3_1_1, {name = 'hurt', loop = true})
	character_util.set_emotion(g3_1_1, { name = 'tired', loop = true })

	-- 흑... 이제 아무도 우리 서큐버스에 관심을 가져주질 않아.
	g3_1_1.Interactable.Talk = 'cafe_stg1_grid3_1_5'
end

function local_class:rotate(target, duration)
	local time_passed = 0
	local final_duration = duration

	while true do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= final_duration then
			break
		end

		local progress = unity_class.mathf.Clamp01(time_passed / final_duration)

		target.Transform.localRotation = unity_class.quaternion.Euler(vector(90, 0, 360 * 30 * progress))

		coroutine.yield(nil)
	end

	target.Transform.localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
