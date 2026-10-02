local local_class = newclass('HighSchool1At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.statue_break_count = {0, 0}
	self.battle_check = {false, false}

	self.get_statue_star_piece = false
	self.saw_quiz_intro = false
	self.answer = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageControlStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

	self.student = get_character('student_1_0')

	if stage_progress:HasStarPiece('incorrect_note_star_piece') then
		character_util.set_emotion(self.student, {name = 'burning'})
		self.student.Interactable.Talk = 'highschool_1_4_dropout_12'
		--이제부턴 정말 공부 뿐이야.
	else
		self.student.Interactable:AddListener(self.cs_controller)
	end

	self.statue_1 = get_field_object('sohee_statue_1')
	self.statue_2 = get_field_object('sohee_statue_2')

	unity_object_pool.GetOrCreate('FX_Env_SmallRock_lv1_destroy')
	unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	unity_object_pool.GetOrCreate('FX_reset_object')

	return
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60001)
	return main_quest ~= nil and main_quest.InnerProgress >= 13 and main_quest.InnerProgress <= 15
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageControlStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
	end

	self.student.Interactable:RemoveRelatedEvent(self.cs_controller)
	self.student = nil

	self.statue_1 = nil
	self.statue_2 = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif event_type == typeof(CS.Oak.StageControlStartEvent) then
		self:on_stage_control_start_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.DamageEvent) then
		self:on_damage_event(e)
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destoryed_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	end

	return false
end

---[ on event
function local_class:on_stage_loaded_event(e)
	self:set_poster()

	local target_list = create_generic_list(typeof(CS.Oak.IFieldObject))

	target_list:Add(self.statue_1)
	target_list:Add(self.statue_2)

	for i = 1, 13 do
		local lover = get_character(string.format('student_follower_%d', i))
		local clms = CS.Oak.CharacterControllerFollowSoheeState.Create(lover, target_list)
		lover:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
	end

	local skull = get_character('burning_skull')
	clms = CS.Oak.CharacterControllerFollowSoheeState.Create(skull, target_list)
	skull:OnEvent(CS.Oak.StateChangeEvent.Create(clms))

	self.get_statue_star_piece = stage_progress:HasStarPiece('statue_star_piece')

	if not self.get_statue_star_piece then
		self.star_piece_effect = unity_object_pool.GetOrCreate('FX_starpiece_in_character'):Instantiate(
			self.statue_1.Bounds.center + vector(0, 0.6, -0.6), unity_class.quaternion.identity, self.statue_1.transform)
	end

	for i = 1, 2 do
		for j = 1, 4 do
			local monster = get_character(string.format('battle_%d_%d', i, j))
			character_util.set_emotion(monster, {name = 'love'})
			local start_marker = field:GetMarker(string.format('monster_marker_start_%d', i))
			local end_marker = field:GetMarker(string.format('monster_marker_end_%d', i))
			local start_pos = vector(start_marker.position.x, 0, monster.Position.z)
			local end_pos = vector(end_marker.position.x, 0, monster.Position.z)
			local info = CS.Oak.WaypointMoveInfo.Create(start_pos, end_pos, 1, false)
			info.endType = CS.Oak.WaypointMoveEndType.Loop
			CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(monster, info)
		end
	end
end

function local_class:on_stage_control_start_event(e)
	for i = 4, 5 do
		local student = get_character(string.format('student_entrance_%d', i))
		local start_marker = field:GetMarker('entrance_zombie_start')
		local end_marker = field:GetMarker('entrance_zombie_end')
		local start_pos = vector(student.Position.x, 0, start_marker.position.z)
		local end_pos = vector(student.Position.x, 0, end_marker.position.z)
		local info = CS.Oak.WaypointMoveInfo.Create(start_pos, end_pos, 0.5, false)
		character_util.set_direction(student, 'down')
		character_util.set_anim(student, {name = 'walk'})
		character_util.set_anim(student, {name = 'push', upper = 'true'})
		character_util.set_emotion(student, {name = 'love'})
		student.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		info.endType = CS.Oak.WaypointMoveEndType.Loop
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(student, info)
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.sohee_sama, self, student,
						string.format('highschool_1_4_sohee_love_npc_%d', i)))
	end
end

function local_class:on_interact_event(e)
	local poster = get_field_object('flipped_sohee_poster')

	if lua_helper.reference_equals(e.Target, poster) then
		poster.Transform.localScale = vector(1, 1, 1)
		poster.Interactable = CS.Oak.NonInteractable.Instance
		local star_piece = get_field_object('poster_star_piece')
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(poster.Position + vector(0, 0, -0.5)))
	elseif lua_helper.reference_equals(e.Target, self.student) then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.sohee_quiz_start, self))
	end
end

function local_class:on_damage_event(e)
	local statues = {self.statue_1, self.statue_2}
	local markers = {field:GetMarker('sohee_statue_1'), field:GetMarker('sohee_statue_2')}

	for i = 1, 2 do
		if lua_helper.reference_equals(e.Info.target, statues[i]) and
				lua_helper.reference_equals(e.Info.sender, statues[i]) then
			self.statue_break_count[i] = self.statue_break_count[i] + 1

			if self.statue_break_count[i] >= 9 then
				if i == 1 and not self.get_statue_star_piece then
					--스타피스 등장
					local star_piece = get_field_object('statue_star_piece')
					star_piece.Position = statues[i].Position
					star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(statues[i].Position))
					self.get_statue_star_piece = true
					self.star_piece_effect:Dispose()
				end

				self.statue_break_count[i] = 0

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.statue_break, self, statues[i], markers[i].position))
			end
		end
	end
end

function local_class:on_field_object_destoryed_event(e)
	if string.find(e.FieldObject.Name, 'battle') then
		character_util.remove_emotion(e.FieldObject)
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return	end
	if e.FieldObject ~= user_party_leader then return end

	local zone_name = e.Zone.Name

	--소히가 방송으로 뭐라고 하는건 section 15에서 <- 삭제
	--local mainInnerProgress = user_progress:GetStartedQuest(60001).InnerProgress

	for i = 1, 2 do

		if zone_name == string.format('BATTLE_%d', i) and not self.battle_check[i] then
			self.battle_check[i] = true
			--if i ~= 1 or mainInnerProgress ~= 14 then
				for j = 1, 4 do
					local monster = get_character(string.format('battle_%d_%d', i, j))
					command_util.execute_cmd(CS.Oak.MonsterNoticeCommand.Create(monster,
							user_party_leader, CS.Oak.MonsterNoticeLevel.Battle))
				end
				message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(string.format('battle_gate_%d_1', i)))
			--end
		end
	end
end
---]

function local_class:sohee_quiz_start()
	-- 정답 초기화
	self.answer = 0

	field_ui_manager:Hide()
	CS.Oak.Party.MyParty:StopAndDisableControl()

	character_util.align_party(self.student, 'right', 1, 'arc')
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	if not self.saw_quiz_intro then
		self.saw_quiz_intro = true
		character_util.set_emotion(self.student, {name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(self.student,
				{key = 'highschool_1_4_dropout_1', skip = true})
		--또 떨어졌어...

		character_util.set_anim(self.student, {name = 'question', loop = false})
		speech_bubble_util.show_speech_bubble_async(self.student,
				{key = 'highschool_1_4_dropout_2', skip = true})
		--이러다간 평생 카페테리아로 못가겠어....

		character_util.set_anim(self.student, {name = 'release', sfx_name = '01_swing_01'})
		speech_bubble_util.show_speech_bubble_async(self.student,
				{key = 'highschool_1_4_dropout_3', skip = true})
		--아까보니까 너 소히님에 대해 잘 알고있는것 같던데,
	end

	character_util.set_emotion(self.student, {name = 'smile'})
	character_util.set_anim(self.student, {name = 'sing'})
	speech_bubble_util.show_speech_bubble_async(self.student,
			{key = 'highschool_1_4_dropout_4', skip = true})
	--기출문제 푸는것좀 도와줄래?

	local wait = true
	local select = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString('highschool_1_4_dropout_5'),
		--도와준다.
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
			select = 1
		end})
	branches:Add({
		Text = game_string:GetString('highschool_1_4_dropout_6'),
		--도와주지 않는다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			select = 2
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	character_util.remove_anim(self.student)

	if select == 2 then
		character_util.set_emotion(self.student, {name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(self.student,
				{key = 'highschool_1_4_dropout_7', skip = true})
		--소히님 처럼 차갑구나....
	elseif select == 1 then
		local clapSfx = music_player_util.play_sfx({
			sfx_name = '01_clap_01', loop = true
		})

		character_util.set_anim(self.student, {name = 'clap'})
		speech_bubble_util.show_speech_bubble_async(self.student,
				{key = 'highschool_1_4_dropout_8', skip = true})
		--고마워! 총 다섯문제야!

		clapSfx:FadeOut(0.2)

		character_util.remove_anim(self.student)


		for i = 1, 5 do
			local before_ans = self.answer
			yield_return_func(self.sohee_quiz, self, i)
			if before_ans == self.answer then
				break
			end
		end

		if self.answer < 5 then
			character_util.set_emotion(self.student, {name = 'attack'})
			speech_bubble_util.show_speech_bubble_async(self.student,
					{key = 'highschool_1_4_dropout_9', skip = true})
			--너.. 찍어서 통과한건 아니겠지..?
			character_util.remove_emotion(self.student)
		else
			music_player:PlaySfxOneShot('03_dialogue_positive_01')

			character_util.set_anim(self.student, {name = 'clap'})
			speech_bubble_util.show_speech_bubble_async(self.student,
					{key = 'highschool_1_4_dropout_10', skip = true})
			--역시 합격생은 다르구나!
			character_util.remove_anim(self.student)

			speech_bubble_util.show_speech_bubble_async(self.student,
					{key = 'highschool_1_4_dropout_11', skip = true})
			--고마워! 이건 내 선물이야.

			local star_piece = get_field_object('incorrect_note_star_piece')
			star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.student.Bounds.center))

			self.student.Interactable:RemoveRelatedEvent(self.cs_controller)

			character_util.set_emotion(self.student, {name = 'burning'})
			self.student.Interactable.Talk = 'highschool_1_4_dropout_12'
			--이제부턴 정말 공부 뿐이야.
		end
	end

	field_ui_manager:Show()
	CS.Oak.Party.MyParty:ResetControllers()
end

function local_class:sohee_quiz(index)
	local answer_sheet = {2, 3, 1, 3, 1}

	local wait = true
	local select = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString('highschool_sohee_quiz_' .. index .. '_1'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			select = 1
		end})
	branches:Add({
		Text = game_string:GetString('highschool_sohee_quiz_' .. index .. '_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			select = 2
		end})
	branches:Add({
		Text = game_string:GetString('highschool_sohee_quiz_' .. index .. '_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			select = 3
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, 'SetNarration',
			game_string:GetString('highschool_sohee_quiz_' .. index), 0, 1.0, false)

	while wait do
		coroutine.yield(nil)
	end

	yield_return(stage.FieldUINarrationBox, 'HideAnimation')

	if answer_sheet[index] == select then
		self.answer = self.answer + 1
		music_player:PlaySfxOneShot('01_quiz_o_01')
		character_util.show_emoticon(self.student, nil, CS.Oak.EmoticonType.Heart)
		character_util.show_emoticon_async(user_party_leader, nil, CS.Oak.EmoticonType.Heart)
	else
		music_player:PlaySfxOneShot('01_quiz_x_01')
		character_util.show_emoticon(self.student, nil, CS.Oak.EmoticonType.Annoyed)
		character_util.show_emoticon_async(user_party_leader, nil, CS.Oak.EmoticonType.Annoyed)
	end
end

--스타피스가 없는경우 포스터 세팅
function local_class:set_poster()
	if not stage_progress:HasStarPiece('poster_star_piece') then
		local poster = get_field_object('flipped_sohee_poster')
		poster.Transform.localScale = vector(-1, 1, 1)
		poster.Interactable = CS.Oak.PublishInteractable.Create()
	end
end

--동상 부서지는 연출
function local_class:statue_break(statue, pos)
	statue:OnEvent(CS.Oak.StateChangeEvent.Create(CS.Oak.FieldObjectIdleState.Instance))

	music_player_util.play_sfx({
		sfx_name = '02_break_wood_02', play_pos = statue.Bounds.center
	})

	unity_object_pool.GetOrCreate('FX_Env_SmallRock_lv1_destroy'):Instantiate(statue.Bounds.center)
	statue.Position = vector(99, 0, 99)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player_util.play_sfx({
		sfx_name = '01_guild_warp_01', play_pos = pos
	})

	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(pos)
	statue.Position = pos
end

function local_class:sohee_sama(character, key)
	while true do
		speech_bubble_util.show_speech_bubble_async(character,
				{key = key})
		-- 소히니이이이임~
		-- 헤헤헤... 소히님... 사랑해요... 소히님...
		wait_for_sec(0.5)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
