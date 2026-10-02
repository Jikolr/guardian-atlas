local local_class = newclass("MovieKissSceneController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스타피스 이름
	self.kiss_star_piece_name = 'movie_kiss_scene_starpiece'

	-- 키스신을 거부하는 여배우
	self.saw_movie_kiss_scene = false
	self.first_talk_1 = false
	self.first_talk_2 = false
	self.first_talk_3 = false

	self.movie_actor_name = 'actor1'
	self.movie_actress_name = 'actor2'
	self.movie_director_name = 'director_sub'

	self.actor_first_talk = false
	self.actress_first_talk = false

	self.kiss_scene_begin = false

	-- 인베이더 배우와 대화
	self.persuade_actor = false

	-- 여배우와 대화
	self.persuade_actress = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')


	-- 키스신 이벤트를 보았는지 체크
	if CS.Oak.StageProgress.Current:HasStarPiece(self.kiss_star_piece_name) then
		self.saw_movie_kiss_scene = true

		character_util.set_active_state(get_character(self.movie_actor_name), "disabled")
		character_util.remove_emotion(get_character(self.movie_actress_name))
		character_util.set_active_state(get_character(self.movie_actress_name), "disabled")
		character_util.set_active_state(get_character(self.movie_director_name), "disabled")
	else
		local actor = get_character(self.movie_actor_name)
		local actress = get_character(self.movie_actress_name)
		local director = get_character(self.movie_director_name)
		actor.Interactable:AddListener(self.cs_controller)
		actress.Interactable:AddListener(self.cs_controller)
		director.Interactable:AddListener(self.cs_controller)

		character_util.set_position(actor, vector(26, 0, 70))
		character_util.set_position(actress, vector(27, 0, 70))

		character_util.set_direction(actor, 'right')
		character_util.set_direction(actress, 'left')

		character_util.set_emotion(actor, { name = 'blush' })
		character_util.set_emotion(actress, { name = 'scared' })

		character_util.set_anim(actor, { name = 'idle', loop = true })
		character_util.set_anim(actress, { name = 'idle', loop = true })
		character_util.set_anim(director, { name = 'idle', loop = true })

		character_util.set_direction(director, 'up')

	end

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	get_character(self.movie_actor_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.movie_actress_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	get_character(self.movie_director_name).Interactable:RemoveRelatedEvent(self.cs_controller)
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			-- 키스신 이벤트 존 입장 시
			if self.kiss_scene_begin and
					not self.saw_movie_kiss_scene and not self.persuade_actress and not self.persuade_actor then
				if e.Zone.Name == 'section_2_7' and not self.first_talk_1 then
					self.first_talk_1 = true
					self:zone_kiss_scene_speech(1)
				elseif e.Zone.Name == 'section_2_8' and not self.first_talk_2 then
					self.first_talk_2 = true
					self:zone_kiss_scene_speech(2)
				elseif e.Zone.Name == 'section_2_9' and not self.first_talk_3 then
					self.first_talk_3 = true
					self:zone_kiss_scene_speech(3)
				end
			end
		end
		return true
	elseif event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
		self.first_talk_1 = false
		self.first_talk_2 = false
		self.first_talk_3 = false
		return true
	elseif event_type == typeof(CS.Oak.InteractEvent) then

		-- 키스신 이벤트를 진행하지 않았을 경우
		if not self.saw_movie_kiss_scene then
			if not self.kiss_scene_begin then
				if lua_helper.reference_equals(e.Target, get_character(self.movie_actor_name)) or
						lua_helper.reference_equals(e.Target, get_character(self.movie_actress_name)) or
						lua_helper.reference_equals(e.Target, get_character(self.movie_director_name)) then
					coroutine_manager:StartCoroutine(
							stage.StageGameObject, util.cs_generator(self.kiss_scene_begin_talk, self))
				end
			else
				-- 인베이더 배우
				if lua_helper.reference_equals(e.Target, get_character(self.movie_actor_name)) then
					-- 여배우가 설득 되었다면
					if self.persuade_actress then
						coroutine_manager:StartCoroutine(
								stage.StageGameObject, util.cs_generator(self.accept_movie_actor, self))
					elseif not self.persuade_actor then
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_actor, self))
					end
				end

				-- 여배우
				if lua_helper.reference_equals(e.Target, get_character(self.movie_actress_name)) then
					-- 인베이더 배우가 설득 되었다면
					if self.persuade_actor then
						coroutine_manager:StartCoroutine(
								stage.StageGameObject, util.cs_generator(self.accept_movie_actress, self))
					elseif not self.persuade_actress then
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_actress, self))
					end
				end

				-- 감독
				if lua_helper.reference_equals(e.Target, get_character(self.movie_director_name)) then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shooting_movie, self))
				end
			end
		end
		return true
	end

	return false
end

-- 처음으로 여배우나 인베이더한테 인터렉트 했을 때
function local_class:kiss_scene_begin_talk()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_director = get_character(self.movie_director_name)
	local movie_actor = get_character(self.movie_actor_name)
	local movie_actress = get_character(self.movie_actress_name)

	local pos = movie_director.Position + unity_class.vector3.forward * 2.5
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 1, 'arc')
	camera_util.move_async(movie_actress.Position, 1, {end_target = movie_actress })

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_kiss_begin_2', skip = true })


	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_kiss_begin_3', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(movie_director, {
		key = 'movie_2_kiss_begin_4', skip = true, bubble_type = 'shout', screen_pos = vector(0, -300) })

	pos = movie_director.Position + unity_class.vector3.right * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	camera_util.move_async(movie_director.Position, 1, { end_target = movie_director })


	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shooting_first, self))
end

-- 설득 전 키스신 촬영 시도
function local_class:shooting_first()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_director = get_character(self.movie_director_name)
	local movie_actor = get_character(self.movie_actor_name)
	local movie_actress = get_character(self.movie_actress_name)

	character_util.set_position(movie_actor, vector(26.4, 0, 70))
	character_util.set_position(movie_actress, vector(27, 0, 70))

	character_util.set_direction(movie_actor, 'right')
	character_util.set_direction(movie_actress, 'left')
	character_util.set_direction(movie_director, 'up')

	character_util.set_emotion(movie_actor, { name = 'idle' })
	character_util.set_emotion(movie_actress, { name = 'idle' })

	character_util.set_anim(movie_actor, { name = 'idle', loop = true })
	character_util.set_anim(movie_actress, { name = 'idle', loop = true })



	-- 자~ 크리스틴과 제임스의 키스신~
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_6', skip = true })

	-- 하이~ 큐!
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_7', skip = true })

	camera_util.move_async(movie_actress.Position, 1)

	-- 사랑해, 크리스틴…
	character_util.set_emotion(movie_actor, { name = 'idle' })
	character_util.set_anim(movie_actor, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_22', skip = true })

	-- 저도요, 제임스!
	character_util.set_emotion(movie_actress, { name = 'idle' })
	character_util.set_anim(movie_actress, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_22', skip = true })

	character_util.move_to_async(movie_actor, vector(26.6, 0, 70), 0.3, nil, nil, true)

	-- 아니, 잠깐만…
	character_util.set_emotion(movie_actress, { name = 'scared' })
	character_util.set_anim(movie_actress, { name = 'push', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_25', skip = true })
	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.move_to(movie_actress, movie_actress.Position + vector(-0.1, 0, 0), 0.5, nil)
	character_util.move_to_async(movie_actor, movie_actor.Position + vector(-0.1, 0, 0), 0.5, nil)
	character_util.move_to_async(movie_actress, movie_actress.Position + vector(0.1, 0, 0), 0.3, nil)

	wait_for_sec(0.5)

	character_util.move_to_async(movie_actor, vector(26.6, 0, 70), 0.3, nil, nil, true)

	-- 아직 마음의 준비가…
	character_util.set_emotion(movie_actress, { name = 'scared' })
	character_util.set_anim(movie_actress, { name = 'push', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_26', skip = true })
	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.move_to(movie_actress, movie_actress.Position + vector(-0.1, 0, 0), 0.5, nil)
	character_util.move_to_async(movie_actor, movie_actor.Position + vector(-0.1, 0, 0), 0.5, nil)
	character_util.move_to_async(movie_actress, movie_actress.Position + vector(0.1, 0, 0), 0.3, nil)

	wait_for_sec(0.5)

	character_util.move_to_async(movie_actor, vector(26.7, 0, 70), 0.3, nil, nil, true)

	-- 아, 그만하라고!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	character_util.set_emotion(movie_actress, { name = 'mad' })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_27', skip = true })
	character_util.set_anim(movie_actress, { name = 'attack', loop = false })
	wait_for_sec(0.2)

	music_player:PlaySfxOneShot('02_hit_critical_01')
	camera_util.shake(0.3, 0.1)
	movie_actor.SpineController:AddFadeColor(movie_actor.Name, CS.UnityEngine.Color(1, 0, 0, 1), 1, 0)
	movie_actor.SpineController:RemoveFadeColor(movie_actor.Name, 1)
	unity_object_pool.GetOrCreate("FX_hit"):Instantiate(movie_actor.Position)
	unity_object_pool.GetOrCreate("FX_lasthit"):Instantiate(movie_actor.Position)
	character_util.set_anim(movie_actor, { name = 'prostrate', loop = false })
	character_util.move_to(movie_actor, vector(25, 0, 70), 0.3)

	wait_for_sec(1)
	character_util.remove_anim(movie_actress)

	-- 커어어어어엇!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_8', skip = true, bubble_type = 'shout', screen_pos = vector(-100, -250) })

	-- 아니, 이게 지금 몇번째 NG야?
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_9', skip = true, bubble_type = 'shout', screen_pos = vector(-100, -250) })

	-- 감독님! 저 진짜 못하겠어요!
	music_player:PlaySfxOneShot('03_runaway_01')
	character_util.set_emotion(movie_actress, { name = 'scared' })
	character_util.set_anim(movie_actress, { name = 'embarrassed', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_28', skip = true })

	-- 포옹 같은걸로 바꾸면 안되요? 이 씬 원래 대본에도 없었잖아요!
	character_util.set_emotion(movie_actress, { name = 'scared' })
	character_util.set_anim(movie_actress, { name = 'release', loop = true, sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_29', skip = true })

	-- 무슨 소리야? 로맨스 영화의 하이라이트는 당연히 키스신이지!
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_25', skip = true })

	--[[
	-- 이것만은 양보 못하지! 이 프로의식 없는 여자야!
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_26', skip = true })
	]]

	camera_util.move_async(movie_director.Position, 1, { end_target = movie_director })

	character_util.set_direction(movie_director, 'right')

	-- 하… 이거 큰일인데…
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_begin', skip = true })

	movie_director.Interactable:RemoveRelatedEvent(self.cs_controller)
	movie_director.Interactable.Talk = 'movie_2_director_talk_begin'

	self.kiss_scene_begin = true

	character_util.move_to(movie_actor, vector(24, 0, 69), 0.9, nil, true, true)
	character_util.move_to(movie_actress, vector(28, 0, 69), 0.9, nil, true, true)

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	character_util.set_direction(movie_actor, 'left')
	character_util.set_direction(movie_actress, 'right')

	character_util.set_emotion(movie_actor, { name = 'idle' })
	character_util.set_emotion(movie_actress, { name = 'scared' })

	character_util.set_anim(movie_actor, { name = 'hurt', loop = true })
	character_util.set_anim(movie_actress, { name = 'seat', loop = true })

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 키스신 이벤트 존 입장 시
function local_class:zone_kiss_scene_speech(case)
	if case == 1 then
		speech_bubble_util.show_speech_bubble(get_character(self.movie_actor_name),
				{ key = 'movie_2_actor_talk_begin', skip = false })
	elseif case == 2 then
		speech_bubble_util.show_speech_bubble(get_character(self.movie_actress_name),
				{ key = 'movie_2_actress_talk_begin', skip = false })
	elseif case == 3 then
		speech_bubble_util.show_speech_bubble(get_character(self.movie_director_name),
				{ key = 'movie_2_director_talk_begin', skip = false })
	end
end

-- 인베이더 배우와 대화
function local_class:talk_actor()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_actress = get_character(self.movie_actress_name)
	local movie_actor = get_character(self.movie_actor_name)

	speech_bubble_util.remove_bubble(movie_actress)
	speech_bubble_util.remove_bubble(movie_actor)

	local pos = movie_actor.Position + unity_class.vector3.right * 1
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	if not self.actor_first_talk then
		-- 플레이어의 위치에 따라 인베이더 배우가 보는 방향 변경
		local direction = (user_party_leader.Position - movie_actor.Position):ToDirection()
		character_util.set_direction(movie_actor, direction)

		-- 저기 저기, 내 말 좀 들어봐!
		character_util.set_anim(movie_actor, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_1', skip = true })

		-- 지금 우리는 로맨스 영화를 찍는 중이거든?
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_2', skip = true })

		-- 그리고 지금 영화의 하이라이트인 키스신을 찍어야 하는데…
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_3', skip = true })

		-- 아니 글쎄 저 여자가 도저히 못하겠다고 버티는거야!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_anim(movie_actor, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_4', skip = true })

		-- 물론 우리가 보편적으로 호감가는 외모는 아니긴 하지만…
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_5', skip = true })

		-- 아니 이게 지금 애들 장난이야?
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_6', skip = true })

		--[[

		-- 돈 받고 일하는거면서… 프로정신이 부족하다 이거야!
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_7', skip = true })

		-- 프로라면 어떤 주문에도 의연해야 되는거 아니야?
		character_util.set_anim(movie_actor, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_8', skip = true })

		]]
	end

	self.actor_first_talk = true

	-- 넌 어떻게 생각해?
	character_util.set_anim(movie_actor, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_9', skip = true })


	-- 선택지: 저 여자가 잘못했네! / 네가 잘못했네!
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local persuade = false

	branches:Add({
		Text = game_string:GetString('movie_2_actor_branch_1'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			persuade = false
		end })

	branches:Add({
		Text = game_string:GetString('movie_2_actor_branch_2'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			persuade = true
		end })

	ui_overlay_util.push_overlay(movie_actor, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 저 여자가 잘못했네!
	if not persuade then

		-- 그치? 너도 그렇게 생각하지?
		character_util.set_anim(movie_actor, { name = 'nod', loop = false })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_10', skip = true })

		-- 그럼 가서 저 여자 좀 설득해 줄래?
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_11', skip = true })

	end

	-- 네가 잘못했네!
	if persuade then

		-- 뭐, 뭐! 진짜로?!
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		character_util.set_anim(movie_actor, { name = 'jump', loop = false })
		character_util.jump(movie_actor, 0.5, 0.3)
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_12', skip = true })

		-- 아니, 대본대로 충실하게 가자는게 뭐가 나빠?!
		character_util.set_anim(movie_actor, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_13', skip = true })

		-- 자기 욕심 때문에 억지로 넣은거면서!
		branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		wait = true

		branches:Add({
			Text = game_string:GetString('movie_2_actor_branch_3'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait = false
			end })

		ui_overlay_util.push_overlay(movie_actor, branches)

		while wait do
			coroutine.yield(nil)
		end

		character_util.set_emotion(user_party_leader, { name = 'attack' })
		character_util.set_anim(user_party_leader, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		character_util.set_emotion(user_party_leader, { name = 'idle' })
		character_util.set_anim(user_party_leader, { name = 'idle', true })

		-- 뭐, 뭐야?
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_anim(movie_actor, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_14', skip = true })

		-- 어떻게 알았… 아니, 이게 아니라.
		character_util.set_anim(movie_actor, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_15', skip = true })

		-- 설사 그렇다 해도 대본은 대본이야! 프로라면 마땅히 소화해야지!
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_16', skip = true })

		-- FB에 올려서 공론화 시킬거야!
		branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		wait = true

		branches:Add({
			Text = game_string:GetString('movie_2_actor_branch_4'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait = false
			end })

		ui_overlay_util.push_overlay(movie_actor, branches)

		while wait do
			coroutine.yield(nil)
		end

		character_util.set_emotion(user_party_leader, { name = 'attack' })
		character_util.set_anim(user_party_leader, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		character_util.set_emotion(user_party_leader, { name = 'idle' })
		character_util.set_anim(user_party_leader, { name = 'idle', true })

		-- 으엑, FB!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_anim(movie_actor, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_17', skip = true })

		-- 그게 올라가면 내 배우생활은… 으으윽!
		character_util.set_anim(movie_actor, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_18', skip = true })

		-- 알았어, 포옹 정도로 타협 보지 뭐...
		character_util.set_anim(movie_actor, { name = 'hurt', loop = false })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_19', skip = true })

		self.persuade_actor = true

		get_character(self.movie_director_name).Interactable:AddListener(self.cs_controller)
		movie_actor.Interactable:RemoveRelatedEvent(self.cs_controller)

		movie_actor.Interactable.Talk = 'movie_2_actor_talk_19'
	end

	character_util.remove_anim(user_party_leader)
	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 여배우와 대화
function local_class:talk_actress()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_actress = get_character(self.movie_actress_name)
	local movie_actor = get_character(self.movie_actor_name)

	speech_bubble_util.remove_bubble(movie_actress)
	speech_bubble_util.remove_bubble(movie_actor)

	local pos = movie_actress.Position + unity_class.vector3.left * 1
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	if not self.actress_first_talk then
		-- 플레이어의 위치에 따라 여배우가 보는 방향 변경
		local direction = (user_party_leader.Position - movie_actress.Position):ToDirection()
		character_util.set_direction(movie_actress, direction)

		-- 저기 저기, 내 말 좀 들어봐!
		character_util.set_emotion(movie_actress, { name = 'mad' })
		character_util.set_anim(movie_actress, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_1', skip = true })

		-- 지금 우리는 로맨스 영화를 찍는 중이거든?
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_2', skip = true })

		-- 그리고 지금 영화의 하이라이트인 키스신을 찍어야 하는데…
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_3', skip = true })

		-- 아니, 저 괴물하고 진짜로 키스를 해야 한다고?
		character_util.set_emotion(movie_actress, { name = 'mad' })
		character_util.set_anim(movie_actress, { name = 'success', loop = true, sfx_name = "01_jump_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_4', skip = true })

		-- 못해, 못해! 아무리 일이라지만...
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_5', skip = true })

		--[[

		-- 분명 처음에 대본 받았을땐 그런 장면은 없었단 말이야!
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_6', skip = true })

		-- 분명히 같은 인베이더라고, 저 괴물놈이 감독하고 짜서 억지로 넣은걸거야!
		character_util.set_emotion(movie_actress, { name = 'mad' })
		character_util.set_anim(movie_actress, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_7', skip = true })

		-- 저 자식 음흉하게 웃고 있는거 봐봐! 으윽, 기분나빠...
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_8', skip = true })

		]]
	end

	self.actress_first_talk = true

	-- 넌 어떻게 생각해?
	character_util.set_emotion(movie_actress, { name = 'idle' })
	character_util.set_anim(movie_actress, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_9', skip = true })

	-- 선택지: 저 놈이 잘못했네! / 네가 잘못했네!
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local persuade = false

	branches:Add({
		Text = game_string:GetString('movie_2_actress_branch_1'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			persuade = false
		end })

	branches:Add({
		Text = game_string:GetString('movie_2_actress_branch_2'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			persuade = true
		end })

	ui_overlay_util.push_overlay(movie_actress, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 저 놈이 잘못했네!
	if not persuade then

		-- 그치? 너도 그렇게 생각하지?
		character_util.set_emotion(movie_actress, { name = 'smile' })
		character_util.set_anim(movie_actress, { name = 'nod', loop = false })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_10', skip = true })

		-- 그럼 가서 저 놈 좀 설득해 줄래?
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_11', skip = true })

	end

	-- 네가 잘못했네!
	if persuade then

		-- 뭐, 뭐! 진짜로?!
		music_player:PlaySfxOneShot('03_dialogue_negative_02')
		character_util.set_emotion(movie_actress, { name = 'surprise' })
		character_util.set_anim(movie_actress, { name = 'jump', loop = false })
		character_util.jump(movie_actress, 0.5, 0.3)
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_12', skip = true })

		-- 아니, 그럼 넌 저 괴물이랑 키스할 수 있어?
		character_util.set_emotion(movie_actress, { name = 'mad' })
		character_util.set_anim(movie_actress, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_13', skip = true })

		-- 이 인베이더 차별주의자!
		branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		wait = true

		branches:Add({
			Text = game_string:GetString('movie_2_actress_branch_3'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait = false
			end })

		ui_overlay_util.push_overlay(movie_actress, branches)

		while wait do
			coroutine.yield(nil)
		end

		character_util.set_emotion(user_party_leader, { name = 'attack' })
		character_util.set_anim(user_party_leader, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		character_util.set_emotion(user_party_leader, { name = 'idle' })
		character_util.set_anim(user_party_leader, { name = 'idle', true })

		-- 허억! 차, 차별…!
		character_util.set_emotion(movie_actress, { name = 'surprise' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_14', skip = true })

		-- 조용히 해…! 누가 듣고 기사라도 나면 어쩔라고 그래!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_15', skip = true })

		-- 인권단체에 제보할거야!
		branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		wait = true

		branches:Add({
			Text = game_string:GetString('movie_2_actress_branch_4'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait = false
			end })

		ui_overlay_util.push_overlay(movie_actress, branches)

		while wait do
			coroutine.yield(nil)
		end

		character_util.set_emotion(user_party_leader, { name = 'attack' })
		character_util.set_anim(user_party_leader, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		character_util.set_emotion(user_party_leader, { name = 'idle' })
		character_util.set_anim(user_party_leader, { name = 'idle', true })

		-- 미쳤어, 미쳤어! 요즘 그런거에 얼마나 민감한데…!
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'embarrassed', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_16', skip = true })

		-- 알았어, 할게! 하면 되잖아! 키스!
		character_util.set_emotion(movie_actress, { name = 'mad' })
		character_util.set_anim(movie_actress, { name = 'release', loop = true, sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_17', skip = true })

		--[[
		-- 우웁, 상상했더니 속이...
		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_18', skip = true })
		]]

		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })

		self.persuade_actress = true

		get_character(self.movie_director_name).Interactable:AddListener(self.cs_controller)
		movie_actress.Interactable:RemoveRelatedEvent(self.cs_controller)

		movie_actress.Interactable.Talk = 'movie_2_actress_talk_18'
	end

	character_util.remove_anim(user_party_leader)
	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 여배우가 설득된 경우 인베이더 배우와 대화
function local_class:accept_movie_actor()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_actor = get_character(self.movie_actor_name)

	local pos = movie_actor.Position + unity_class.vector3.right * 1
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 플레이어의 위치에 따라 인베이더 배우가 보는 방향 변경
	local direction = (user_party_leader.Position - movie_actor.Position):ToDirection()
	character_util.set_direction(movie_actor, direction)

	-- 진짜?! 그대로 촬영 하자고 했다고?
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_anim(movie_actor, { name = 'jump', loop = false })
	character_util.jump(movie_actor, 0.5, 0.3)
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_20', skip = true })

	-- 랄랄라~ 가글이라도 해야지~
	character_util.set_anim(movie_actor, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actor,
			{ key = 'movie_2_actor_talk_21', skip = true })

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 인베이더가 설득된 경우 여배우와 대화
function local_class:accept_movie_actress()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_actress = get_character(self.movie_actress_name)

	local pos = movie_actress.Position + unity_class.vector3.left * 1
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 1, CS.Oak.Party.AlignType.Arc)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 플레이어의 위치에 따라 여배우가 보는 방향 변경
	local direction = (user_party_leader.Position - movie_actress.Position):ToDirection()
	character_util.set_direction(movie_actress, direction)

	-- 진짜?! 포옹으로 바뀌었다고?
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_emotion(movie_actress, { name = 'surprise' })
	character_util.set_anim(movie_actress, { name = 'jump', loop = false })
	character_util.jump(movie_actress, 0.5, 0.3)
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_19', skip = true })

	-- 뭐 그정도는… 할 수 있지.
	character_util.set_emotion(movie_actress, { name = 'idle' })
	character_util.set_anim(movie_actress, { name = 'nod', loop = false })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_20', skip = true })

	-- 알았어. 바로 준비할게.
	character_util.set_emotion(movie_actress, { name = 'idle' })
	character_util.set_anim(movie_actress, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_actress,
			{ key = 'movie_2_actress_talk_21', skip = true })

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 촬영 재개
function local_class:shooting_movie()
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local movie_director = get_character(self.movie_director_name)
	local movie_actor = get_character(self.movie_actor_name)
	local movie_actress = get_character(self.movie_actress_name)

	local pos = movie_director.Position + unity_class.vector3.right * 1.5
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 플레이어의 위치에 따라 감독이 보는 방향 변경
	local direction = (user_party_leader.Position - movie_director.Position):ToDirection()
	character_util.set_direction(movie_director, direction)

	-- 진짜?! 설득을 했다고?
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_anim(movie_director, { name = 'jump', loop = false })
	character_util.jump(movie_director, 0.5, 0.3)
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_1', skip = true })

	-- 좋았어! 바로 촬영 재개다!
	music_player:PlaySfxOneShot('01_jump_01')
	character_util.set_anim(movie_director, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_2', skip = true })

	-- 화면 전환
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted, 2)
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 여배우를 설득한 경우
	if self.persuade_actress then
		character_util.set_position(movie_actor, vector(27, 0, 70))
		character_util.set_direction(movie_actor, 'left')
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })

		character_util.set_position(movie_actress, vector(26.6, 0, 70))
		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
	end

	-- 인베이더 배우를 설득한 경우
	if self.persuade_actor then
		character_util.set_position(movie_actor, vector(27, 0, 70))
		character_util.set_direction(movie_actor, 'left')
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })

		character_util.set_position(movie_actress, vector(26.5, 0, 70))
		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
	end

	character_util.set_position(movie_director, movie_director.Position + vector(0, 0, 1))
	character_util.set_direction(movie_director, 'up')
	character_util.set_emotion(movie_director, { name = 'idle' })
	character_util.set_anim(movie_director, { name = 'idle', loop = true })

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	camera_util.move_async(movie_director.Position, 1, { end_target = movie_director })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 자, 촬영 들어갑니다~ 하이~ 큐!
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_3', skip = true })

	camera_util.move_async(movie_actress.Position, 1, { end_target = movie_actress })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 여배우를 설득한 경우
	if self.persuade_actress then

		-- 사랑해, 크리스틴…
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_22', skip = true })

		-- 저도요, 제임스!
		character_util.set_emotion(movie_actress, { name = 'idle' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_22', skip = true })

		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'push', loop = false })

		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'push', loop = false })

		--coroutine.yield(coroutine_class.wait_for_sec(3))
		music_player:PlaySfxOneShot('01_keyitem_effect_01')
		music_player:PlaySfxOneShot('01_kiss_01')
		screen_util.fade_out_async(1, unity_class.color(1, 0.6, 0.8, 1), 'linear')
		coroutine.yield(coroutine_class.wait_for_sec(1))
	end

	-- 인베이더 배우를 설득한 경우
	if self.persuade_actor then

		-- 사랑해, 크리스틴…
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actor,
				{ key = 'movie_2_actor_talk_22', skip = true })

		-- 저도요, 제임스!
		music_player:PlaySfxOneShot('01_gatcha_point_01')
		character_util.set_emotion(movie_actress, { name = 'love' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_actress,
				{ key = 'movie_2_actress_talk_22', skip = true })

		character_util.set_direction(movie_actor, 'left')
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'push', loop = false })

		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'scared' })
		character_util.set_anim(movie_actress, { name = 'push', loop = false })

		music_player:PlaySfxOneShot('01_rustle_01')

		coroutine.yield(coroutine_class.wait_for_sec(3))

		-- 컷트! 좋았어~
		music_player:PlaySfxOneShot('01_clap_01')
		character_util.set_direction(movie_director, 'up')
		character_util.set_anim(movie_director, { name = 'clap', loop = true })
		speech_bubble_util.show_speech_bubble_async(movie_director,
				{ key = 'movie_2_director_talk_4', skip = true })

		screen_util.fade_out_async(1, unity_class.color.black, 'linear')
		coroutine.yield(coroutine_class.wait_for_sec(1.5))
	end

	character_util.set_position(movie_actor, vector(24, 0, 69))
	character_util.set_position(movie_actress, vector(28, 0, 69))
	character_util.set_position(movie_director, movie_director.Position - vector(0, 0, 1))
	character_util.set_direction(movie_director, 'right')
	character_util.set_anim(movie_director, { name = 'idle', loop = true })

	-- 여배우를 설득한 경우
	if self.persuade_actress then
		character_util.set_direction(movie_actor, 'left')
		character_util.set_emotion(movie_actor, { name = 'blush' })
		character_util.set_anim(movie_actor, { name = 'idle', loop = true })
		-- 쿠헤헤… 감촉이 남아있는 것 같아…
		movie_actor.Interactable.Talk = 'movie_2_actor_talk_24'

		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'cry' })
		character_util.set_anim(movie_actress, { name = 'hurt', loop = true })
		-- 으앙~ 난 시집 다갔어~
		movie_actress.Interactable.Talk = 'movie_2_actress_talk_24'

		music_player:PlayStageMusic("ondemand/movie/preload:bgm_burywood_main", CS.Oak.StageBgmState.Field, 2)
		screen_util.fade_in_async(1, unity_class.color(1, 0.6, 0.8, 1), 'linear')
	end

	-- 인베이더 배우를 설득한 경우
	if self.persuade_actor then
		character_util.set_direction(movie_actor, 'left')
		character_util.set_emotion(movie_actor, { name = 'idle' })
		character_util.set_anim(movie_actor, { name = 'hurt', loop = true })
		-- 쳇... 아쉬워라...
		movie_actor.Interactable.Talk = 'movie_2_actor_talk_23'

		character_util.set_direction(movie_actress, 'right')
		character_util.set_emotion(movie_actress, { name = 'smile' })
		character_util.set_anim(movie_actress, { name = 'idle', loop = true })
		-- 휴~! 하마터면 진짜 키스 할 뻔했네!
		movie_actress.Interactable.Talk = 'movie_2_actress_talk_23'

		music_player:PlayStageMusic("ondemand/movie/preload:bgm_burywood_main", CS.Oak.StageBgmState.Field, 2)
		screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	end

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 고마워! 덕분에 무사히 촬영을 마쳤어!
	character_util.set_direction(movie_director, 'right')
	character_util.set_anim(movie_director, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(movie_director,
			{ key = 'movie_2_director_talk_5', skip = true })

	character_util.set_anim(movie_director, { name = 'get' })

	-- 스타피스 등장
	local star_piece = get_field_object(self.kiss_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(movie_director.Position))
	coroutine.yield(coroutine_class.wait_for_sec(2.0))

	character_util.set_anim(movie_director, { name = 'idle', loop = true })

	movie_actor.Interactable:RemoveRelatedEvent(self.cs_controller)
	movie_actress.Interactable:RemoveRelatedEvent(self.cs_controller)
	movie_director.Interactable:RemoveRelatedEvent(self.cs_controller)

	movie_director.Interactable.Talk = 'movie_2_director_talk_5'

	self.saw_movie_kiss_scene = true

	field_ui_manager:Show()
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
