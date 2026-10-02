local local_class = newclass("HighSchool1At1Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self:init_timid_student()
	self:init_crystal_students()
	self:init_four_class()
	self:init_fight_class()
	self:init_mad_teacher()
end

function local_class:load_resource()

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:need_on_launch()
	local high_school_main_quest_id = 60001

	local q = user_progress:GetStartedQuest(high_school_main_quest_id)
	return q == nil or q.InnerProgress <= 0 and not q.IsComplete
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:stage_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	coroutine.yield(self:load_resource_crystal_students())
	coroutine.yield(self:load_resource_princess_starpiece())
	coroutine.yield(self:load_resource_four_class())
	coroutine.yield(self:load_resource_fight_class())
	coroutine.yield(self:load_resource_mad_teacher())
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self:dispose_timid_student()
	self:dispose_crystal_students()
	self:dispose_princess_starpiece()
	self:dispose_four_class()
	self:dispose_fight_class()
	self:dispose_mad_teacher()

	self.cs_controller = nil
end


function local_class:on_event(e)
	if self:subscriber_princess_starpiece(e) then
		return true
	end

	if self:subscriber_crystal_students(e) then
		return true
	end

	if self:subscriber_timid_student(e) then
		return true
	end

	if self:subscriber_four_class(e) then
		return true
	end

	if self:subscriber_fight_class(e) then
		return true
	end

	if self:subscriber_mad_teacher(e) then
		return true
	end

	return false
end

-- timid student sns follow event
do
	function local_class:init_timid_student()
		self.timid_student = get_character('timid_student')
		self.timid_student_follow_id = 45
		self:setting_timid_student()

		self.is_talked_timid = false
		self.is_accept_timid = false
	end

	function local_class:subscriber_timid_student(e)
		local event_type = e:GetType(e)
		if not self.is_accept_timid then -- 추후 제거예정
			if lua_helper.reference_equals(e.Target, self.timid_student) and not user_progress:IsFollowing(self.timid_student_follow_id) then
				self.talk_timid_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.talk_timid_student, self))
				return true
			end
		end
	end

	function local_class:dispose_timid_student()
		self.timid_student = nil
		self.talk_timid_coroutine = nil
	end

	function local_class:setting_timid_student()
		if user_progress:IsFollowing(self.timid_student_follow_id) then
			self.timid_student:SetAnimation(self.timid_student,
				CS.Oak.AnimationRequest('sing', CS.Oak.AnimationPriorities.Custom, true))
			self.timid_student:SetEmotion(self.timid_student,
				CS.Oak.AnimationRequest('smile', CS.Oak.AnimationPriorities.Custom, true))

			self.timid_student.Interactable = CS.Oak.NPCInteractable.Create()
			self.timid_student.Interactable.Talk = 'highschool_1_1_timid_student_end'
		else
			self.timid_student:SetAnimation(self.timid_student,
				CS.Oak.AnimationRequest('seat', CS.Oak.AnimationPriorities.Custom, true))
			self.timid_student:SetEmotion(self.timid_student,
				CS.Oak.AnimationRequest('tired', CS.Oak.AnimationPriorities.Custom, true))

			self.timid_student.Interactable:AddListener(self.cs_controller)
		end
	end

	function local_class:talk_timid_student()
		field_ui_manager:Hide()
		user_party:StopAndDisableControl()

		coroutine.yield(align_party(self.timid_student, CS.Oak.Direction.Right, 1.0, CS.Oak.Party.AlignType.Arc))

		if not self.is_talked_timid then
			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_1', skip = true})

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_2', skip = true})

			character_util.remove_anim(self.timid_student)
			character_util.set_emotion(self.timid_student, { name = 'cry' })

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_3', skip = true})

			-- 우는 시간 잠시 대기
			coroutine.yield(coroutine_class.wait_for_sec(1.5))

			character_util.remove_anim(self.timid_student)
			character_util.remove_emotion(self.timid_student)

			coroutine.yield(coroutine_class.wait_for_sec(1.0))

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_4', skip = true})

			character_util.set_anim(self.timid_student, { name = 'sing' })
			character_util.set_emotion(self.timid_student, { name = 'smile' })

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_5', skip = true})
		else
			character_util.set_anim(self.timid_student, { name = 'sing' })
			character_util.set_emotion(self.timid_student, { name = 'smile' })

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_request_1', skip = true})
		end

		local wait = true

		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		branches:Add({
			Text = game_string:GetString('highschool_1_1_timid_student_branchs_1'),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				self.is_accept_timid = true
				wait = false
			end})
		branches:Add({
			Text = game_string:GetString('highschool_1_1_timid_student_branchs_2'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait = false
			end
		})

		local acs = CS.Oak.UI.AnswerChoiceState()
		acs.Talker = user_party_leader
		acs.Branchs = branches
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, acs)

		while wait do
			coroutine.yield(nil)
		end

		if self.is_accept_timid then
			character_util.remove_anim(self.timid_student)
			character_util.remove_emotion(self.timid_student)

			character_util.set_anim(self.timid_student, { name = 'success' })
			character_util.set_emotion(self.timid_student, { name = 'awesome' })

			music_player:PlaySfxOneShot('03_dialogue_positive_01')

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_6_2', skip = true})

			--TODO : SNS등록 이벤트 실행(현재는 임의의 값을 넣은상태 , 추후 서버에 등록한 id로 진행)
			coroutine.yield(CS.Oak.AddSNSCoroutine(self.timid_student_follow_id))

			character_util.remove_anim(self.timid_student)
			character_util.remove_emotion(self.timid_student)

			self.timid_student.Interactable = CS.Oak.NPCInteractable.Create()
			self.timid_student.Interactable.Talk = 'highschool_1_1_timid_student_end'
		else
			character_util.remove_anim(self.timid_student)
			character_util.remove_emotion(self.timid_student)

			character_util.set_anim(self.timid_student, { name = 'seat' })
			character_util.set_emotion(self.timid_student, { name = 'tired' })

			speech_bubble_util.show_speech_bubble_async(self.timid_student,
				{key = 'highschool_1_1_timid_student_6_1', skip = true})
		end

		self.is_talked_timid = true

		field_ui_manager:Show()
		user_party:ResetControllers()
	end
end

-- crystal students sub event
do
	function local_class:init_crystal_students()
		self.crystal_item_id = 20142

		-- 첫 창고로 들어가는 학생들을 보았는지
		self.is_see_intro_crystal = false

		self.is_guard_check = false
		self.is_see_crystal_students = false
		self.is_eat_crystal = false

		-- 플레이어가 창고 안 학생들을 보고있는지
		self.is_player_see = false

		-- 크리스탈을 섭취중인 학생들을 발견하여 전투를 했는지
		self.is_revealed = false

		self.crystal_student_num = 4

		self.crystal_eat_coroutine = nil
		self.crystal_not_eat_coroutine = nil
		self.battle_crystal_students = nil

		-- 스타피스 이름
		self.crystal_event_star_piece_name = "warehouse_star_piece"

		-- 스타피스 획득하면 이벤트 다시 나오지 않게
		self.get_crystal_event_star_piece = false

		if stage_progress:HasStarPiece(self.crystal_event_star_piece_name) then
			self.get_crystal_event_star_piece = true
		end

		self.scout_student = get_character('drug_scout_student')
		self.crystal_student_list = create_generic_list(CS.Oak.Character)

		self.crystal_intro_student_1 = get_character('drug_student_intro_1')
		self.crystal_intro_student_2 = get_character('drug_student_intro_2')

		for i = 1, self.crystal_student_num do
			local cur_crystal_student = get_character('drug_student_' .. i)
			self.crystal_student_list:Add(cur_crystal_student)

			if self.get_crystal_event_star_piece then
				cur_crystal_student.ActiveState = CS.Oak.ActiveState.Disabled
			end
		end

		if self.get_crystal_event_star_piece then
			self.scout_student.ActiveState = CS.Oak.ActiveState.Disabled
			self.crystal_intro_student_1.ActiveState = CS.Oak.ActiveState.Disabled
			self.crystal_intro_student_2.ActiveState = CS.Oak.ActiveState.Disabled
		else
			self.crystal_student_list[0].Position = vector(-25, 0, 66)
			self.crystal_student_list[0].Direction = CS.Oak.Direction.Left
			self.crystal_student_list[1].Position = vector(-19, 0, 66)
			self.crystal_student_list[1].Direction = CS.Oak.Direction.Right
			self.crystal_student_list[2].Position = vector(-18, 0, 64)
			self.crystal_student_list[2].Direction = CS.Oak.Direction.Right
			self.crystal_student_list[3].Position = vector(-24, 0, 63)
			self.crystal_student_list[3].Direction = CS.Oak.Direction.Left
		end
	end

	function local_class:load_resource_crystal_students()
		self.emoticonPool = unity_object_pool.GetOrCreate('emoticon');

		message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'subscriber_crystal_students')
	end

	function local_class:dispose_crystal_students()
		message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))

		self.battle_crystal_students = nil
		self.crystal_not_eat_coroutine = nil
		self.crystal_eat_coroutine = nil

		self.crystal_student_list:Clear()
		self.crystal_student_list = nil

		self.crystal_intro_student_1 = nil
		self.crystal_intro_student_2 = nil

		self.scout_student = nil

		self.emoticonPool = nil
	end

	-- 크리스탈을 섭취중인 학생들
	function local_class:eat_crystal_students()
		self.is_eat_crystal = true

		for i = 0, self.crystal_student_num - 1 do
			character_util.remove_anim(self.crystal_student_list[i])
			character_util.remove_emotion(self.crystal_student_list[i])

			character_util.set_anim(self.crystal_student_list[i], { name = 'eat' })
			character_util.set_emotion(self.crystal_student_list[i], { name = 'greed' })
		end

		self.crystal_student_list[2].Direction = CS.Oak.Direction.Right

		-- 학생들 한테 크리스탈 아이템 배치
		self.crystal_1 = drop_item_util.create_item({pos = self.crystal_student_list[0].Position + vector(-0.3, 0, 0.05),
			 target = nil, itemid = self.crystal_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true})
		self.crystal_1.SpriteTransform.localScale = vector(1, 1, 1) * 0.5
		self.crystal_1.ShadowTransform.localScale = vector(1, 1, 1) * 0.5

		self.crystal_2 = drop_item_util.create_item({pos = self.crystal_student_list[1].Position + vector(0.3, 0, 0.05),
			 target = nil, itemid = self.crystal_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true})
		self.crystal_2.SpriteTransform.localScale = vector(1, 1, 1) * 0.5
		self.crystal_2.ShadowTransform.localScale = vector(1, 1, 1) * 0.5

		self.crystal_3 = drop_item_util.create_item({pos = self.crystal_student_list[2].Position + vector(0.3, 0, 0.05),
			 target = nil, itemid = self.crystal_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true})
		self.crystal_3.SpriteTransform.localScale = vector(1, 1, 1) * 0.5
		self.crystal_3.ShadowTransform.localScale = vector(1, 1, 1) * 0.5

		self.crystal_4 = drop_item_util.create_item({pos = self.crystal_student_list[3].Position + vector(-0.3, 0, 0.05),
			 target = nil, itemid = self.crystal_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true})
		self.crystal_4.SpriteTransform.localScale = vector(1, 1, 1) * 0.5
		self.crystal_4.ShadowTransform.localScale = vector(1, 1, 1) * 0.5

		coroutine.yield(nil)
	end

	-- 플레이어가 온다는 사실을 알고 딴청을 피우는 학생들
	function local_class:look_away_students()
		self.crystal_1.ConsumeTarget = self.crystal_student_list[0]
		self.crystal_1:Fly()
		self.crystal_1:ConsumeComplete()

		self.crystal_2.ConsumeTarget = self.crystal_student_list[1]
		self.crystal_2:Fly()
		self.crystal_2:ConsumeComplete()

		self.crystal_3.ConsumeTarget = self.crystal_student_list[2]
		self.crystal_3:Fly()
		self.crystal_3:ConsumeComplete()

		self.crystal_4.ConsumeTarget = self.crystal_student_list[3]
		self.crystal_4:Fly()
		self.crystal_4:ConsumeComplete()

		self.is_guard_check = true
		self.is_eat_crystal = false

		for i = 0, self.crystal_student_num - 1 do
			character_util.remove_anim(self.crystal_student_list[i])
			character_util.remove_emotion(self.crystal_student_list[i])
		end

		character_util.set_anim(self.crystal_student_list[0], { name = 'dance' })
		character_util.set_emotion(self.crystal_student_list[0], { name = 'smile' })

		self.crystal_student_list[0].Interactable = CS.Oak.NPCInteractable.Create()
		self.crystal_student_list[0].Interactable.Talk = 'highschool_1_1_crystal_student_before_1'

		character_util.set_anim(self.crystal_student_list[1], {name = "question", loop = false})

		self.crystal_student_list[1].Interactable = CS.Oak.NPCInteractable.Create()
		self.crystal_student_list[1].Interactable.Talk = 'highschool_1_1_crystal_student_before_2'

		self.crystal_student_list[2].Direction = CS.Oak.Direction.Down
		character_util.set_anim(self.crystal_student_list[2], { name = 'dance_voodoo' })

		self.crystal_student_list[2].Interactable = CS.Oak.NPCInteractable.Create()
		self.crystal_student_list[2].Interactable.Talk = 'highschool_1_1_crystal_student_before_3'

		character_util.set_anim(self.crystal_student_list[3], {name = "question", loop = false})

		self.crystal_student_list[3].Interactable = CS.Oak.NPCInteractable.Create()
		self.crystal_student_list[3].Interactable.Talk = 'highschool_1_1_crystal_student_before_4'
	end

	function local_class:subscriber_crystal_students(e)
		-- 스타피스 획득 시에는 어떤 이벤트에도 반응하지 않음
		if self.get_crystal_event_star_piece then
			return false
		end

		local event_type = e:GetType()

		if event_type == typeof(CS.Oak.ZoneEnterEvent) and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not e.FullEnter then
				return false
			end

			if e.Zone.Name == 'crystal_prologue' and not self.is_see_intro_crystal then
				self.is_see_intro_crystal = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.crystal_student_intro, self))
				return true
			end

			if e.Zone.Name == 'crystal_discover' then
				self.is_player_see = true
				return true
			end

			-- 크리스탈 섭취중인 학생들한테 가까이 다가갔을때 전투 발생
			if e.Zone.Name == 'crystal_final' and self.is_eat_crystal and not self.is_revealed then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.battle_crystal_students_event, self))
				return true
			end
		end

		if event_type == typeof(CS.Oak.ZoneLeaveEvent) and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not e.FullLeave then
				return false
			end

			if e.Zone.Name == 'guard_leave_check' and self.is_guard_check then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.move_up_scout, self))
				self.is_guard_check = false
				return true
			end

			if e.Zone.Name == 'crystal_discover' and user_party_leader.Direction == CS.Oak.Direction.Up then
				self.is_player_see = false
				return true
			end
		end

		if event_type == typeof(CS.Oak.CustomStageEvent) then
			if e.Params[0] == 'discovered' and not self.is_player_see and not self.is_revealed then
				self.crystal_not_eat_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.move_down_scout, self))
			end
		end

		return false
	end

	-- 창고쪽으로 수상한 대화를 하며 내려가 시선을 집중시켜주는 인트로 학생들 이벤트
	function local_class:crystal_student_intro()
		-- 크리스탈 섭취 코루틴 시작
		self.crystal_eat_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.eat_crystal_students, self))

		self.crystal_intro_student_1.Interactable = CS.Oak.NonInteractable.Instance
		self.crystal_intro_student_1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		self.crystal_intro_student_2.Interactable = CS.Oak.NonInteractable.Instance
		self.crystal_intro_student_2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		local move_info = CS.Oak.WaypointMoveInfo.Create(vector(-22, 0, 72), 7.0, true, CS.Oak.Direction.Down)
		local move_duration = move_info:GetDuration(self.crystal_intro_student_2.Position)

		local waypoints1 = create_generic_list(unity_class.vector3)
		waypoints1:Add(vector(-22, 0, 72))

		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.crystal_intro_student_1, move_info)

		move_info = CS.Oak.WaypointMoveInfo.Create(vector(-21, 0, 72),
			7.0, true, CS.Oak.Direction.Down)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.crystal_intro_student_2, move_info)

		coroutine.yield(coroutine_class.wait_for_sec(move_duration))

		self.crystal_intro_student_1.Position = vector(999, 0, 999)
		self.crystal_intro_student_2.Position = vector(999, 0, 999)
	end

	-- 크리스탈 섭취중인 학생들과의 전투 이벤트
	function local_class:battle_crystal_students_event()
		field_ui_manager:Hide()
		user_party:StopAndDisableControl()

		coroutine.yield(align_party(vector(-20, 0, 66), CS.Oak.Direction.Left, 1.0, CS.Oak.Party.AlignType.Arc))

		self.is_revealed = true

		-- 망보는학생 감시 그만두도록.
		self.scout_student.FieldObjectController = CS.Oak.NPCCharacterController()
		self.scout_student.Direction = CS.Oak.Direction.Left

		character_util.set_anim(self.scout_student, { name = 'seat' })
		character_util.set_emotion(self.scout_student, { name = 'tired' })

		-- 아이템 섭취
		self.crystal_1.ConsumeTarget = self.crystal_student_list[0]
		self.crystal_1:Fly()

		self.crystal_2.ConsumeTarget = self.crystal_student_list[1]
		self.crystal_2:Fly()

		self.crystal_3.ConsumeTarget = self.crystal_student_list[2]
		self.crystal_3:Fly()

		self.crystal_4.ConsumeTarget = self.crystal_student_list[3]
		self.crystal_4:Fly()

		local emoticon_object = self.emoticonPool:Instantiate(self.crystal_student_list[1].Position)
		local emoticon = emoticon_object:GetComponent(typeof(CS.Oak.Emoticon))
		emoticon:Init()
		emoticon:ShowOn(self.crystal_student_list[1], vector(1, 1, 1), CS.Oak.EmoticonType.Question)

		for i = 0, self.crystal_student_num - 1 do
			self.crystal_student_list[i]:RemoveAnimation(self.crystal_student_list[i])
			self.crystal_student_list[i]:RemoveEmotion(self.crystal_student_list[i])
		end

		-- 잠시 동안 대기
		coroutine.yield(coroutine_class.wait_for_sec(1.0))

		-- 첫번째 학생이 눈치채고 뒤를 돌아본다.
		self.crystal_student_list[1].Direction = CS.Oak.Direction.Left

		coroutine.yield(coroutine_class.wait_for_sec(0.5))

		character_util.set_anim(self.crystal_student_list[1], { name = 'tired' })

		local param = CS.Oak.SpeechBubbleGenerateParam(self.crystal_student_list[1],
			game_string:Format('highschool_1_1_crystal_student_reveal_1'))
		param.ClickToProceed = true

		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		-- 눈치챈 학생들 플레이어에게 접근
		local move_info = CS.Oak.WaypointMoveInfo.Create(vector(-24, 0, 66), 2.0, false, CS.Oak.Direction.Right)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.crystal_student_list[0], move_info)

		move_info = CS.Oak.WaypointMoveInfo.Create(vector(-19, 0, 64), 2.0, false, CS.Oak.Direction.Left)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.crystal_student_list[2], move_info)

		move_info = CS.Oak.WaypointMoveInfo.Create(vector(-22, 0, 63), 2.0, false, CS.Oak.Direction.Up)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.crystal_student_list[3], move_info)

		local move_duration = move_info:GetDuration(self.crystal_student_list[3].Position)

		coroutine.yield(coroutine_class.wait_for_sec(move_duration))

		character_util.remove_anim(self.crystal_student_list[1])

		character_util.set_emotion(self.crystal_student_list[1], { name = 'eyelight' })

		music_player:PlaySfxOneShot('01_fade_out_03')

		param = CS.Oak.SpeechBubbleGenerateParam(self.crystal_student_list[1],
			game_string:Format('highschool_1_1_crystal_student_reveal_2'))
		param.ClickToProceed = true

		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		character_util.remove_emotion(self.crystal_student_list[1])

		character_util.set_emotion(self.crystal_student_list[1], { name = 'mad' })

		music_player:PlaySfxOneShot('03_dialogue_negative_01')

		param = CS.Oak.SpeechBubbleGenerateParam(self.crystal_student_list[1],
			game_string:Format('highschool_1_1_crystal_student_reveal_3'))
		param.ClickToProceed = true
		param.BubbleType = CS.Oak.SpeechBubbleNew.BubbleType.Shout

		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		character_util.remove_emotion(self.crystal_student_list[1])

		-- 전투 시작시 배틀게이트 강제 닫음
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('crystal_battlegate'))

		for i = 0, self.crystal_student_num - 1 do
			CS.Oak.ICharacterExtensions.ConvertToMonster(self.crystal_student_list[i], 'battle_4')
			self.crystal_student_list[i].DamagedBehaviour.DeathType = CS.Oak.DeathType.AirSpin
		end

		command_util.execute_monster_notice(self.crystal_student_list[1], user_party_leader, 'battle')

		field_ui_manager:Show()
		user_party:ResetControllers()
	end

	-- 망보던 학생이 아래로 이동하는 코루틴
	function local_class:move_down_scout()

		-- 눈치채는 동안 잠시 플레이어 파티 경직
		for i = 0, user_party.Count - 1 do
			CS.Oak.CharacterControllerScreenplayState.Stop(user_party[i])
		end

		-- 이모티콘 ! 재생
		local emoticon_object = self.emoticonPool:Instantiate(self.scout_student.Position)
		local emoticon = emoticon_object:GetComponent(typeof(CS.Oak.Emoticon))
		emoticon:Init()

		music_player:PlaySfxOneShot('03_dialogue_negative_01')

		speech_bubble_util.show_speech_bubble(self.scout_student, {key = 'highschool_1_1_crystal_scout_student_1', skip = true})

		-- ! 이모티콘 시간을 임의로 0.5 ,1.0, 0.2 간격으로 조정
		emoticon:ShowOn(self.scout_student, vector(1, 1, 1), CS.Oak.EmoticonType.Notice, nil, 1.0, {0.5, 1.0, 0.2}, false)

		coroutine.yield(coroutine_class.wait_for_sec(1.0))

		-- 크리스탈 섭취 행동 멈춤
		stop_coroutine(self.crystal_eat_coroutine)

		-- 딴청 피우는 학생들 시작
		self:look_away_students()

		-- 플레이어와 충돌 하지 못하도록
		self.scout_student.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		-- 망보던 학생 아래로 내려가도록 한다.
		move_info = CS.Oak.WaypointMoveInfo.Create(vector(-21, 0, 65), 9.0, true, CS.Oak.Direction.Left)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.scout_student, move_info)
		local move_duration = move_info:GetDuration(self.scout_student.Position)
		coroutine.yield(coroutine_class.wait_for_sec(move_duration))

		-- 망보는 학생이 아래에 도착한 후 움직임 가능하도록
		user_party:ResetControllers()

		self.scout_student.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	end

	-- 플레이어가 어느정도 위로 올라가면 망보던 학생이 다시 위로 올라오는 코루틴
	function local_class:move_up_scout()

		-- 딴청 피우는 행동 멈춤
		stop_coroutine(self.crystal_not_eat_coroutine)

		-- 크리스탈 섭취 행동 시작
		self.crystal_eat_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.eat_crystal_students, self))

		self.scout_student.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		-- 망보던 학생 다시 복귀
		move_info = CS.Oak.WaypointMoveInfo.Create(vector(-21, 0, 76), 8.0, true, CS.Oak.Direction.Up)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.scout_student, move_info)
		local move_duration = move_info:GetDuration(self.scout_student.Position)
		coroutine.yield(coroutine_class.wait_for_sec(move_duration))

		self.scout_student.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

		-- 다시 감시시작.
		self.scout_student:OnEvent(CS.Oak.StateResetEvent.Instance)
	end
end

-- princess star piece event
do
	function local_class:load_resource_princess_starpiece()
		self.obento_item_id = 20098

		self.princess = get_character('princess')
		self.princess_move_coroutine = nil
		self.princess.Interactable = CS.Oak.NPCInteractable.Create()
		self.has_starpiece = false
	end

	function local_class:dispose_princess_starpiece()
		self.princess_move_coroutine = nil
		self.princess = nil
	end

	function local_class:subscriber_princess_starpiece(e)
		local event_type = e:GetType()

		if event_type == typeof(CS.Oak.InteractEvent) then
			if lua_helper.reference_equals(e.Target, self.princess) and not self.has_starpiece then
				CS.Oak.SpeechBubbleManager.Instance:Return(self.princess.transform)
				stop_coroutine(self.princess_move_coroutine)
				self.princess.Interactable:RemoveRelatedEvent(self.cs_controller)
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.princess_give_starpiece, self))
				return true
			end
		end

		if event_type == typeof(CS.Oak.StageLoadedEvent) then
			self.has_starpiece = stage_progress:HasStarPiece('princess_star_piece')

			local near_student_list = create_generic_list(CS.Oak.Character)
			local near_student_num = 2

			for i = 1, near_student_num do
				local cur_near_student = get_character('princess_student_' .. i)
				near_student_list:Add(cur_near_student)
			end

			-- 공주 스타피스를 이미 먹었다면 해당 이벤트 NPC를 전부 비활성화 처리
			if self.has_starpiece then
				for i = 0, near_student_num - 1 do
					near_student_list[i].ActiveState = CS.Oak.ActiveState.Disabled
				end
			elseif not self.has_starpiece then
				self.princess.Position = vector(47, 0, 69)
				self.princess.Direction = CS.Oak.Direction.Right

				near_student_list[0].Position = vector(48, 0, 69)
				near_student_list[0].Direction = CS.Oak.Direction.Left
				near_student_list[1].Position = vector(45, 0, 69)
				near_student_list[1].Direction = CS.Oak.Direction.Right

				near_student_list[0].Interactable.Talk = 'highschool_princess_student_1'
				near_student_list[1].Interactable.Talk = 'highschool_princess_student_2'

				self.princess_move_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.princess_move_around, self))
			end
		end

		return false
	end

	function local_class:princess_move_around()
		-- 공주는 왼쪽 오른쪽 왔다갔다 움직인다.
		while true do
			self.princess.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			local move_info = CS.Oak.WaypointMoveInfo.Create(self.princess.Position + vector(-1, 0, 0),
				2.0, false, CS.Oak.Direction.Left)
			CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.princess, move_info)
			local move_duration = move_info:GetDuration(self.princess.Position)
			coroutine.yield(coroutine_class.wait_for_sec(move_duration))

			self.princess.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

			character_util.remove_anim(self.princess)
			character_util.remove_emotion(self.princess)

			param = CS.Oak.SpeechBubbleGenerateParam(game_string:GetString('highschool_princess_event_0_1'),
				CS.Oak.SpeechBubbleNew.BubbleType.Talk, self.princess.transform)
			CS.Oak.SpeechBubbleManager.Instance:ShowSpeechBubble(param)

			self.princess.Interactable:AddListener(self.cs_controller)

			character_util.set_anim(self.princess, { name = 'hurt' })
			character_util.set_emotion(self.princess, { name = 'tired' })

			coroutine.yield(coroutine_class.wait_for_sec(3.0))

			self.princess.Interactable:RemoveRelatedEvent(self.cs_controller)
			self.princess.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

			character_util.remove_anim(self.princess)
			character_util.remove_emotion(self.princess)

			move_info = CS.Oak.WaypointMoveInfo.Create(self.princess.Position + vector(1, 0, 0), 2.0, false, CS.Oak.Direction.Right)
			CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.princess, move_info)
			move_duration = move_info:GetDuration(self.princess.Position)
			coroutine.yield(coroutine_class.wait_for_sec(move_duration))

			self.princess.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

			character_util.remove_anim(self.princess)
			character_util.remove_emotion(self.princess)

			param = CS.Oak.SpeechBubbleGenerateParam(game_string:GetString('highschool_princess_event_0_2'), CS.Oak.SpeechBubbleNew.BubbleType.Talk,
				self.princess.transform)
			CS.Oak.SpeechBubbleManager.Instance:ShowSpeechBubble(param)

			self.princess.Interactable:AddListener(self.cs_controller)

			character_util.set_anim(self.princess, { name = 'attack', sfx_name = '01_hit_npc_01' })
			character_util.set_emotion(self.princess, { name = 'mad' })

			coroutine.yield(coroutine_class.wait_for_sec(3.0))

			self.princess.Interactable:RemoveRelatedEvent(self.cs_controller)

			character_util.remove_anim(self.princess)
			character_util.remove_emotion(self.princess)
		end
	end

	function local_class:princess_give_starpiece()
		self.has_starpiece = true

		field_ui_manager:Hide()
		user_party:StopAndDisableControl()

		coroutine.yield(align_party(self.princess, CS.Oak.Direction.Down, 1.0, CS.Oak.Party.AlignType.Arc))

		character_util.set_direction(self.princess, 'down')
		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = 'highschool_princess_event_1', skip = true})

		character_util.set_emotion(self.princess, { name = 'cry2' })

		music_player:PlaySfxOneShot('03_dialogue_sadness_01')

		local param = CS.Oak.SpeechBubbleGenerateParam(self.princess, game_string:Format('highschool_princess_event_2', user.Name))
		param.ClickToProceed = true
		param.BubbleType = CS.Oak.SpeechBubbleNew.BubbleType.Shout
		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = 'highschool_princess_event_3', skip = true})

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'attack' })
		character_util.set_emotion(self.princess, { name = 'attack' })

		music_player:PlaySfxOneShot('03_dialogue_tipsy_01')

		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = 'highschool_princess_event_4', skip = true})

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'sing' })
		character_util.set_emotion(self.princess, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = 'highschool_princess_event_5', skip = true})

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'throw' , loop = false })
		character_util.set_emotion(self.princess, { name = 'attack' })

		music_player:PlaySfxOneShot('01_throw_01')

		local drop_item = drop_item_util.create_item({pos = self.princess.Position, target = user_party_leader.Position,
			itemid = self.obento_item_id, notforinven = true})
		drop_item.SpriteTransform.localScale = vector(1, 1, 1) * 0.5
		drop_item.ShadowTransform.localScale = vector(1, 1, 1) * 0.5
		drop_item.ConsumeTarget = user_party_leader

		coroutine.yield(coroutine_class.wait_for_sec(0.65))

		drop_item:ConsumeComplete()

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'release', sfx_name = '01_swing_01' })
		character_util.set_emotion(self.princess, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = "highschool_princess_event_6", skip = true})

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'success', sfx_name = '01_small_jump_01' })
		character_util.set_emotion(self.princess, { name = 'awesome' })
		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = "highschool_princess_event_7", skip = true})

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_anim(self.princess, { name = 'sing' })
		character_util.set_emotion(self.princess, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = "highschool_princess_event_8", skip = true})

		-- 공주가 스타피스를 플레이어한테 준다.
		local starpiece = get_field_object('princess_star_piece')
		starpiece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.princess.Position + vector(0,0.5,0), false))
		coroutine.yield(coroutine_class.wait_for_sec(0.7))

		if (user_party_leader.Direction & CS.Oak.Direction.Side) == 0 then
			user_party_leader.Direction = CS.Oak.Direction.Left
		end

		user_party_leader:SetAnimation(user_party_leader, CS.Oak.AnimationRequest('victory_get', CS.Oak.AnimationPriorities.Custom, false))

		--승리 포즈 취하는중 여유시간을 줌
		coroutine.yield(coroutine_class.wait_for_sec(2.0))

		user_party_leader.Direction = (self.princess.Position - user_party_leader.Position):ToDirection()
		user_party_leader.RemoveAnimation(user_party_leader)

		character_util.remove_anim(self.princess)
		character_util.remove_emotion(self.princess)

		character_util.set_emotion(self.princess, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(self.princess,
			{key = "highschool_princess_event_9", skip = true})

		self.princess.Interactable.Talk = 'highschool_princess_event_9'

		field_ui_manager:Show()
		user_party:ResetControllers()
	end
end

-- fight students
do
	function local_class:init_fight_class()
		self.fight_grid_name = "fight_grid"

		self.fight_student_pos_marker = "fight_student_pos"

		self.fight_student_win_name = "fight_student_win"
		self.fight_student_lose_name = "fight_student_lose"
		self.fight_student_see_name = "fight_student_see_"

		self.secret_class_rock_name = "secret_class_rock"

		self.hit_effect_name = "FX_hit"
		self.hit_power_effect_name = "FX_hit_power"
		self.hit_small_effect_name = "FX_Dash_Smoke"
		self.destroy_rock_effect_name = "FX_Env_BigRock_lv1_destroy"

		self.fight_student_win = nil
		self.fight_student_lose = nil

		self.fight_student_see = nil

		self.secret_class_rock = nil

		self.hit_effect_pool = nil
		self.hit_power_effect_pool = nil
		self.hit_small_effect_pool = nil
		self.destroy_rock_effect_pool = nil

		self.is_fight_student = false
		self.is_fight = true

		self.fight_class_custom_state = 1
	end

	function local_class:load_resource_fight_class()
		self.fight_student_win = get_character(self.fight_student_win_name)
		self.fight_student_lose = get_character(self.fight_student_lose_name)

		self.fight_student_see = create_generic_list(CS.Oak.Character)
		for i = 0, 6 do
			self.fight_student_see:Add(get_character(self.fight_student_see_name .. i))
		end

		self.secret_class_rock = get_field_object(self.secret_class_rock_name)

		if stage_progress:GetCustomData(self.fight_class_custom_state) then
			self.fight_student_lose.ActiveState = CS.Oak.ActiveState.Disabled
			self.secret_class_rock.ActiveState = CS.Oak.ActiveState.Disabled

			self.is_fight_student = true
			self.is_fight = false

			character_util.set_anim(self.fight_student_win, { name = 'cast2' })
			character_util.set_emotion(self.fight_student_win, { name = 'awesome' })

			for i = 0, self.fight_student_see.Count - 1 do
				character_util.remove_anim(self.fight_student_see[i])
				character_util.remove_emotion(self.fight_student_see[i])
				character_util.set_anim(self.fight_student_see[i], { name = 'success' })
				character_util.set_emotion(self.fight_student_see[i], { name = 'love' })
			end
		end

		self.hit_effect_pool = unity_object_pool.GetOrCreate(self.hit_effect_name)
		self.hit_power_effect_pool = unity_object_pool.GetOrCreate(self.hit_power_effect_name)
		self.hit_small_effect_pool = unity_object_pool.GetOrCreate(self.hit_small_effect_name)
		self.destroy_rock_effect_pool = unity_object_pool.GetOrCreate(self.destroy_rock_effect_name)

		self.fight_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.fight_students, self))
		self.fight_see_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.see_fight_students, self))
	end

	function local_class:dispose_fight_class()
		self.destroy_rock_effect_pool = nil
		self.hit_small_effect_pool = nil
		self.hit_power_effect_pool = nil
		self.hit_effect_pool = nil

		self.secret_class_rock = nil

		self.fight_student_see:Clear()

		self.fight_student_see = nil

		self.fight_student_win = nil
		self.fight_student_lose = nil
	end

	function local_class:subscriber_fight_class(e)
		local event_type = e:GetType()

		if event_type == typeof(CS.Oak.CameraGridEnterEvent) then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.fight_grid_name then return false end

			if self.is_fight_student then return false end

			self.is_fight_student = true
			coroutine_manager:StartCoroutine(self.fight_coroutine);
			coroutine_manager:StartCoroutine(self.fight_see_coroutine);

			return true
		end

		if event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.fight_grid_name then return false end

			if not self.is_fight_student or stage_progress:GetCustomData(self.fight_class_custom_state) then
				return false
			end

			self.is_fight_student = false
			stop_coroutine(self.fight_coroutine)
			stop_coroutine(self.fight_see_coroutine)

			return true
		end

		return false
	end

	-- 싸우는 학생 두명
	function local_class:fight_students()
		local count = 0

		local marker = field:GetMarker(self.fight_student_pos_marker).position

		local speech_num = 1

		-- 싸우는 학생 위치에서 한번만 재생 (3d)
		music_player_util.play_sfx({
			sfx_name = '01_crowd_clap_03', play_pos = self.fight_student_win.Position
		})

		while true do
			character_util.remove_anim(self.fight_student_win)
			character_util.set_anim(self.fight_student_win, { name = 'run' })
			coroutine.yield(self.ifo_util.MoveTo(self.fight_student_win,
				marker + unity_class.vector3.left * 0.5, nil, 10, true, false))

			self.fight_student_win.SpineController:DeviateLocal(vector(0.1, 0, 0), 0.3, 0.2)
			character_util.remove_anim(self.fight_student_win)
			character_util.set_anim(self.fight_student_win, { name = 'attack' })

			coroutine.yield(coroutine_class.wait_for_sec(0.3))

			-- 가장 낮은 우선순위로 3d 재생
			music_player_util.play_sfx({
				sfx_name = '02_hit_critical_01', play_pos = self.fight_student_lose.Position
			})

			if count < 3 then
				self.hit_effect_pool:Instantiate(self.fight_student_lose.Position)
			else
				self.hit_power_effect_pool:Instantiate(self.fight_student_lose.Position)
			end

			character_util.remove_anim(self.fight_student_win)

			-- 지는 학생 피격
			character_util.set_emotion(self.fight_student_lose, { name = 'hurt' })

			self.fight_student_lose.SpineController:DeviateLocalAngle(15, 0.3, 0.2)
			self.fight_student_lose.SpineController:DeviateLocal(vector(0.5, 0, 0), 0.3, 0.2)
			self.fight_student_lose.SpineController:DamageSquish(1)
			self.fight_student_lose.SpineController:DamageRedPulse()

			count = count + 1

			if count > 2 then
				break
			end

			self.fight_student_win.SpineController:Jump(0.5, 0.5)
			coroutine.yield(self.ifo_util.MoveTo(self.fight_student_win,
				marker + unity_class.vector3.left * 3.5, nil, 7, false, true))

			-- 지는 학생 반격
			character_util.remove_emotion(self.fight_student_lose)
			character_util.set_emotion(self.fight_student_lose, { name = 'mad' })

			character_util.remove_anim(self.fight_student_lose)
			character_util.set_anim(self.fight_student_lose, { name = 'run' })
			coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.fight_student_lose,
				marker + 3.5 * unity_class.vector3.left, 0.5, nil, true, false))

			coroutine.yield(coroutine_class.wait_for_sec(0.2))

			self.fight_student_lose.SpineController:Jump(0.5, 0.6)

			coroutine.yield(coroutine_class.wait_for_sec(0.2))

			character_util.remove_anim(self.fight_student_lose)
			character_util.set_anim(self.fight_student_lose, { name = 'attack' })

			self.fight_student_win.SpineController:DeviateLocal(vector(-1, 0, 0), 0.2, 0.4)

			coroutine.yield(coroutine_class.wait_for_sec(0.2))

			-- 가장 낮은 우선순위로 3d 재생
			music_player_util.play_sfx({
				sfx_name = '02_hit_critical_01', play_pos = self.fight_student_lose.Position
			})

			self.hit_small_effect_pool:Instantiate(self.fight_student_lose.Position)

			coroutine.yield(coroutine_class.wait_for_sec(0.2))

			coroutine.yield(self.ifo_util.MoveTo(self.fight_student_lose,
				marker, nil, 6, false, true))

			character_util.remove_emotion(self.fight_student_lose)

			character_util.set_emotion(self.fight_student_win, { name = 'awesome' })
			speech_bubble_util.show_speech_bubble(
				self.fight_student_win, { key = 'highschool_1_1_fight_students_' .. speech_num })

			speech_num = speech_num + 1
			wait_for_sec(2)

			character_util.remove_emotion(self.fight_student_win)

			coroutine.yield(coroutine_class.wait_for_sec(0.5))
		end

		-- 지는 학생 패배
		self.is_fight = false

		character_util.remove_anim(self.fight_student_win)
		character_util.set_anim(self.fight_student_win, { name = 'cast2' })
		character_util.set_emotion(self.fight_student_win, { name = 'awesome' })

		for i = 0, self.fight_student_see.Count - 1 do
			character_util.remove_anim(self.fight_student_see[i])
			character_util.remove_emotion(self.fight_student_see[i])
			character_util.set_anim(self.fight_student_see[i], { name = 'success' })
			character_util.set_emotion(self.fight_student_see[i], { name = 'love' })
		end

		-- 날아가는 지는 학생
		coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.fight_student_lose,
			marker + 16 * unity_class.vector3.right, nil, 16))

		coroutine.yield(coroutine_class.wait_for_sec(0.2))

		-- 바위 부서지는 소리
		music_player_util.play_sfx({
			sfx_name = '03_rock_break_01', play_pos = self.secret_class_rock.Position
		})

		self.destroy_rock_effect_pool:Instantiate(self.secret_class_rock.Position)

		coroutine.yield(coroutine_class.wait_for_sec(0.1))

		self.secret_class_rock.ActiveState = CS.Oak.ActiveState.Disabled

		coroutine.yield(coroutine_class.wait_for_sec(0.7))

		stage_progress:SendCustomData(self.fight_class_custom_state, true)

		character_util.remove_anim(self.fight_student_lose)
		character_util.remove_emotion(self.fight_student_lose)
		character_util.set_anim(self.fight_student_lose, { name = 'hurt' })
		character_util.set_emotion(self.fight_student_lose, { name = 'confused' })
	end

	-- 싸움 관중들 행동
	function local_class:see_fight_students()
		for i = 0, self.fight_student_see.Count - 1 do
			character_util.set_anim(self.fight_student_see[i], { name = 'success' })
			character_util.set_emotion(self.fight_student_see[i], { name = 'burning' })
			coroutine.yield(coroutine_class.wait_for_sec(0.1))
		end

		while self.is_fight do
			local rand = math.floor(CS.UnityEngine.Random.Range(0, self.fight_student_see.Count - 1))
			speech_bubble_util.show_speech_bubble(self.fight_student_see[rand], { key = 'highschool_battle_talk_1' })
			wait_for_sec(6)
		end
	end
end

-- four class
do
	function local_class:init_four_class()
		self.stage_load = false
		-- 쫒고 쫒기는 학생들
		self.four_class_grid_name = "four_class_grid"

		self.run_away_follow_marker_name = "run_away_follow"

		self.run_away_student_name = "run_away_student"
		self.follow_student_name = "follow_student"

		self.follow_student = nil
		self.run_away_student = nil

		-- 청소하는 학생들
		self.cleaning_students_name = "cleaning_student_"
		self.sleep_student_name = "sleep_student"

		self.cleaning_pos_0 = "cleaning_pos_0"
		self.cleaning_pos_1 = "cleaning_pos_1"

		self.cleaning_students = nil

		-- 외로운 학생
		self.lonely_student_name = "lonely_student"
		self.lonely_run_students_name = "lonely_run_student_"

		self.move_run_student_marker_name = "move_run_student_"

		self.lonely_student = nil
		self.lonely_run_students = nil

		self.lonely_class_custom_state = 0

		self.crystal = nil

		self.hit_effect_pool = nil

		self.is_four_class = false
		self.is_lonely_class = false
	end

	function local_class:load_resource_four_class()
		self.follow_student = get_character(self.follow_student_name)
		self.run_away_student = get_character(self.run_away_student_name)

		self.cleaning_students = create_generic_list(CS.Oak.Character)
		for i = 0, 2 do
			self.cleaning_students:Add(get_character(self.cleaning_students_name .. i))
		end

		self.lonely_student = get_character(self.lonely_student_name)

		self.lonely_run_students = create_generic_list(CS.Oak.Character)
		for i = 0, 3 do
			self.lonely_run_students:Add(get_character(self.lonely_run_students_name .. i))
		end

		if stage_progress:GetCustomData(self.lonely_class_custom_state) then
			self.is_lonely_class = true

			for i = 0, self.lonely_run_students.Count - 1 do
				self.lonely_run_students[i].ActiveState = CS.Oak.ActiveState.Disabled
			end
		end

		self.hit_effect_pool = unity_object_pool.GetOrCreate(self.hit_effect_name)

		self.lonely_student.Interactable.Talk = "highschool_1_1_lonely_student_1"
	end

	function local_class:dispose_four_class()
		self.cleaning_students:Clear()

		self.hit_effect_pool = nil

		self.crystal = nil

		self.lonely_run_students = nil
		self.lonely_student = nil

		self.cleaning_students = nil

		self.run_away_student = nil
		self.follow_student = nil
	end

	function local_class:subscriber_four_class(e)
		local event_type = e:GetType()

		if event_type == typeof(CS.Oak.StageLoadedEvent) then
			self.stage_load = true

			self.run_away_follow_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.run_away_follow, self))

			self.cleaning_class_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.cleaning_class, self))
		end

		if event_type == typeof(CS.Oak.CameraGridEnterEvent) and self.stage_load then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.four_class_grid_name then return false end

			if self.is_four_class then return false end
			self.is_four_class = true
			self:start_four_class()

			return true
		end

		if event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.four_class_grid_name then return false end

			if not self.is_four_class then return false end
			self.is_four_class = false
			self:stop_four_class()

			return true
		end

		if event_type == typeof(CS.Oak.ZoneEnterEvent) then
			if not e.FullEnter then return false end
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

			local zone_name = e.Zone.Name

			if zone_name == "lonely_class" and not self.is_lonely_class then
				self.is_lonely_class = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lonely_class, self))
				return true
			end
		end

		return false
	end

	function local_class:start_four_class()
		coroutine_manager:StartCoroutine(self.run_away_follow_coroutine);
		coroutine_manager:StartCoroutine(self.cleaning_class_coroutine);
	end

	function local_class:stop_four_class()
		stop_coroutine(self.run_away_follow_coroutine)
		stop_coroutine(self.cleaning_class_coroutine)
	end

	-- 쫒고 쫒기는 학생들
	function local_class:run_away_follow()
		local marker = field:GetMarker(self.run_away_follow_marker_name).position

		local waypoint_list = create_generic_list(unity_class.vector3)
		waypoint_list:Add(marker)
		waypoint_list:Add(marker + 6.5 * vector(-1, 0, 0))
		waypoint_list:Add(marker + 6.5 * vector(-1, 0, 1))
		waypoint_list:Add(marker + 6.5 * vector(0, 0, 1))

		character_util.move_waypoint(
				self.run_away_student, waypoint_list, 6, true,
				'loop', 'floor', nil, true)

		character_util.move_waypoint(
				self.follow_student, waypoint_list, 6, true,
				'loop', 'floor', nil, true)

		while true do
			speech_bubble_util.show_speech_bubble_async(self.follow_student, { key = 'highschool_1_1_run_away_follow_1' })
			speech_bubble_util.show_speech_bubble_async(self.run_away_student, { key = 'highschool_1_1_run_away_follow_2' })

			coroutine.yield(coroutine_class.wait_for_sec(2))
		end
	end

	-- 청소하는 학생들
	function local_class:cleaning_class()
		local marker_0 = field:GetMarker(self.cleaning_pos_0).position
		local marker_1 = field:GetMarker(self.cleaning_pos_1).position
		while true do
			coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.cleaning_students[1],
				marker_0 + 3 * unity_class.vector3.right, 3, nil, true, false))
			coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.cleaning_students[2],
				marker_1 + 3 * unity_class.vector3.left, 3, nil, true, false))

			coroutine.yield(coroutine_class.wait_for_sec(3.5))

			speech_bubble_util.show_speech_bubble(self.cleaning_students[0], { key = 'highschool_1_1_cleaning_class_1' })

			coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.cleaning_students[1],
				marker_0, 3, nil, true, false))
			coroutine_manager:StartCoroutine(stage.StageGameObject, self.ifo_util.MoveTo(self.cleaning_students[2],
				marker_1, 3, nil, true, false))

			coroutine.yield(coroutine_class.wait_for_sec(3.5))
		end
	end

	-- 외로운 학생
	function local_class:lonely_class()
		stage_progress:SendCustomData(self.lonely_class_custom_state, true)

		local waypoint_list_list = create_generic_list(unity_class.list(unity_class.vector3))

		speech_bubble_util.show_speech_bubble(self.lonely_run_students[0], { key = 'highschool_1_1_lonely_class_1' })

		for i = 0, 3 do
			local marker = field:GetMarker(self.move_run_student_marker_name .. i).position

			local waypoint_list = create_generic_list(unity_class.vector3)
			waypoint_list:Add(marker)
			waypoint_list:Add(marker + 30 * unity_class.vector3.forward)

			waypoint_list_list:Add(waypoint_list)

			character_util.move_waypoint(self.lonely_run_students[i], waypoint_list_list[i],
					9, true, 'stop', 'floor', nil, true)

			coroutine.yield(coroutine_class.wait_for_sec(0.1))
		end

		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		for i = 0, self.lonely_run_students.Count - 1 do
			self.lonely_run_students[i].SpineController:SetAlphaFade(0, 1)
		end

		coroutine.yield(coroutine_class.wait_for_sec(1))

		for i = 0, self.lonely_run_students.Count - 1 do
			self.lonely_run_students[i].SpineController:SetAlphaFade(1, 0)
			character_util.stop(self.lonely_run_students[i])
			character_util.set_position(self.lonely_run_students[i], vector(999, 0, 999))
		end
	end
end

-- mad teacher
do
	function local_class:init_mad_teacher()
		self.mad_teacher_grid_name = "mad_teacher_grid"

		self.mad_teacher_name = "mad_teacher"
		self.smile_student_0_name = "smile_student_0"
		self.smile_student_1_name = "smile_student_1"
		self.bad_student_name = "bad_student_2"

		self.mad_teacher_male = nil
		self.smile_student_0 = nil
		self.smile_student_1 = nil
		self.bad_student = nil

		self.is_mad_teacher = false
	end

	function local_class:load_resource_mad_teacher()
		self.mad_teacher_male = get_character(self.mad_teacher_name)
		self.bad_student = get_character(self.bad_student_name)
		self.bad_student.Interactable.Talk = "highschool_1_1_mad_teacher_5"

		self.mad_teacher_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.mad_teacher, self))
	end

	function local_class:dispose_mad_teacher()

		self.bad_student = nil
		self.mad_teacher_male = nil
	end

	function local_class:subscriber_mad_teacher(e)
		local event_type = e:GetType()

		if event_type == typeof(CS.Oak.CameraGridEnterEvent) then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.mad_teacher_grid_name then return false end

			if self.is_mad_teacher then return false end

			self.is_mad_teacher = true
			coroutine_manager:StartCoroutine(self.mad_teacher_coroutine);

			return true
		end

		if event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
			if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
					not lua_helper.reference_equals(e.FieldObject, user_party) then
				return false
			end

			if e.CameraGrid.name ~= self.mad_teacher_grid_name then return false end

			if not self.is_mad_teacher then return false end

			self.is_mad_teacher = false
			stop_coroutine(self.mad_teacher_coroutine)

			return true
		end

		return false
	end

	function local_class:mad_teacher()
		while true do
			speech_bubble_util.show_speech_bubble_async(
					self.mad_teacher_male, { key = 'highschool_1_1_mad_teacher_1', bubble_type = 'shout' })

			coroutine.yield(coroutine_class.wait_for_sec(1))

			speech_bubble_util.show_speech_bubble_async(
					self.mad_teacher_male, { key = 'highschool_1_1_mad_teacher_2', bubble_type = 'shout' })

			coroutine.yield(coroutine_class.wait_for_sec(1))
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
