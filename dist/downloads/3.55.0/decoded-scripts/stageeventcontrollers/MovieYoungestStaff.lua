local local_class = newclass("MovieYoungestStaffController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.staff_name = 'youngest_staff'
	self.invader_staff_name = 'invader_youngest_staff'

	self.staff_talk_begin = false
	self.saw_staff_talk = false
	self.saw_youngest_staff = false

	self.youngest_staff_follower_id = 47
	self.select_number = 0

	self.staff_coroutine = nil
end

function local_class:load_resource()
	-- 팔로우 안되어있을때만
	if not CS.Oak.UserProgress.Instance.Followers:Contains(self.youngest_staff_follower_id) then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

		staff = get_character(self.staff_name)

		self.staff_coroutine = coroutine_class.coroutine(
				stage.StageGameObject, util.cs_generator(self.staff_routine, self))

		staff.Interactable:AddListener(self.cs_controller)

		character_util.set_direction(get_character(self.invader_staff_name), 'right')

		-- 저걸 어떡하지?
		get_character(self.invader_staff_name).Interactable.Talk = 'movie_4_youngest_staff_27'
	else
		self.saw_staff_talk = true

		character_util.set_active_state(get_character(self.staff_name), 'disabled')
		character_util.set_active_state(get_character(self.invader_staff_name), 'disabled')
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	get_character(self.staff_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	self.staff_coroutine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, get_character(self.staff_name)) then
			if not self.saw_youngest_staff and not self.saw_staff_talk then
				sp_util.play_normal_screenplay(self.youngest_staff_talk, self)
			end
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then

		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
				not lua_helper.reference_equals(e.FieldObject, user_party) then
			return false
		end

		if e.CameraGrid.name == 'movie_youngest_staff_grid' then
			if not self.saw_youngest_staff and not self.saw_staff_talk then
				coroutine_manager:StartCoroutine(self.staff_coroutine)
			end
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then

		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
				not lua_helper.reference_equals(e.FieldObject, user_party) then
			return false
		end

		if e.CameraGrid.name == 'movie_youngest_staff_grid' then
			if not self.saw_youngest_staff and not self.saw_staff_talk then
				stop_coroutine(self.staff_coroutine)

				local staff = get_character(self.staff_name)
				speech_bubble_util.remove_bubble(staff)

				local invader_staff = get_character(self.invader_staff_name)
				speech_bubble_util.remove_bubble(invader_staff)
			end
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) and e.Zone.Name == 'waiting_room_1'
			and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.saw_staff_talk and not self.saw_youngest_staff then
			sp_util.play_normal_screenplay(self.invader_staff_talk, self)
		end
	end

	return false
end

-- 막내 스탭 반복 행동
function local_class:staff_routine()
	local staff = get_character(self.staff_name)
	character_util.set_emotion(staff, { name = 'tired' })

	while true do
		character_util.move_to_async(staff, vector(25, 0, 49), nil, 1, true, true)

		-- 큰일이야. 이러다 늦겠어…!
		character_util.set_emotion(staff, { name = 'tired' })
		character_util.set_anim(staff, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_1' })
		wait_for_sec(2)

		character_util.move_to_async(staff, vector(27, 0, 49), nil, 1, true, true)

		-- 큰일이야. 이러다 늦겠어…!
		character_util.set_emotion(staff, { name = 'tired' })
		character_util.set_anim(staff, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_1' })
		wait_for_sec(2)
	end
end

-- 막내 스탭과의 대화
function local_class:youngest_staff_talk()
	stop_coroutine(self.staff_coroutine)

	local staff = get_character(self.staff_name)
	character_util.remove_anim_and_emotion(staff)
	speech_bubble_util.remove_bubble(staff)

	party_util.align_to_target(staff, 'left', 1, 'linear')
	character_util.set_direction(staff, 'left')


	if not self.staff_talk_begin then
		-- 이제 곧 점심시간이라 도시락을 시켜야 하는데…
		character_util.set_emotion(staff, { name = 'tired' })
		character_util.set_anim(staff, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_2', skip = true })

		--오늘 촬영장에 몇 명이 왔는지 모르겠어.
		character_util.set_emotion(staff, { name = 'tired' })
		character_util.set_anim(staff, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_3', skip = true })

		--도시락이 부족하거나 남으면 또 왕창 깨지고 말 거야…!
		character_util.set_emotion(staff, { name = 'scared' })
		character_util.set_anim(staff, { name = 'embarrassed' })
		music_player:PlaySfxOneShot('03_runaway_01')
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_4', skip = true })

		-- 저기, 지금 촬영장에 몇 명 있는지 네가 확인해 주지 않을래?
		character_util.set_emotion(staff, { name = 'scared' })
		character_util.set_anim(staff, { name = 'sing' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_5', skip = true })

		-- 부탁할게!
		character_util.set_emotion(staff, { name = 'scared' })
		character_util.set_anim(staff, { name = 'sing' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_6', skip = true })

		self.staff_talk_begin = true
		self.staff_coroutine = coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.staff_routine, self))
		return
	end

	if self.staff_talk_begin then
		-- 몇 명인지 알아 봤어?
		character_util.set_emotion(staff, { name = 'idle' })
		character_util.set_anim(staff, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_7', skip = true })

		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		local wait_for_branch = true
		local choice = 0
		-- 6명
		branches:Add({
			Text = game_string:GetString('movie_4_youngest_staff_branch_1'),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				wait_for_branch = false
				choice = 6
			end
		})
		-- 7명
		branches:Add({
			Text = game_string:GetString('movie_4_youngest_staff_branch_2'),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait_for_branch = false
				choice = 7
			end
		})

		-- 13명
		branches:Add({
			Text = game_string:GetString('movie_4_youngest_staff_branch_3'),
			Tendency = CS.Oak.TalkTendency.Forced,
			Callback = function()
				wait_for_branch = false
				choice = 13
			end
		})

		-- 아직 세는 중이다
		branches:Add({
			Text = game_string:GetString('movie_4_youngest_staff_branch_4'),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				wait_for_branch = false
				choice = 0
			end
		})

		ui_overlay_util.push_overlay(staff, branches)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		if choice == 0 then
			-- 미안한데, 조금만 서둘러줘.
			character_util.set_emotion(staff, { name = 'tired' })
			character_util.set_anim(staff, { name = 'idle' })
			speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_8', skip = true })


			self.staff_coroutine = coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.staff_routine, self))
			return
		end

		self.select_number = choice

		-- 고마워, 덕분에 이번엔 안 혼날 거 같아!
		character_util.set_emotion(staff, { name = 'smile' })
		character_util.set_anim(staff, { name = 'idle', loop = true })
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_9', skip = true })

		-- 아, 여기 내 FB 주소야!
		character_util.set_emotion(staff, { name = 'smile' })
		character_util.set_anim(staff, { name = 'idle', loop = true })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_10', skip = true })

		yield_return_func(CS.Oak.AddSNSCoroutine, self.youngest_staff_follower_id)

		-- 다음에 내가 촬영장 구경시켜줄게. 꼭 연락 해!
		character_util.set_emotion(staff, { name = 'smile' })
		character_util.set_anim(staff, { name = 'nod', loop = false })
		speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_11', skip = true })

		self.saw_staff_talk = true
		staff.Interactable:RemoveRelatedEvent(self.cs_controller)
		staff.Interactable.Talk = 'movie_4_youngest_staff_11'

		character_util.remove_anim(staff)
	end
end

-- 스탭과 대화 후 나갈 때
function local_class:invader_staff_talk()
	local staff = get_character(self.staff_name)
	local invader = get_character(self.invader_staff_name)

	camera_util.move_async(invader.Position, 1, { end_target = invader })

	-- 오늘 도시락 주문한 사람 누구야!
	character_util.set_direction(invader, 'right')
	character_util.set_anim(invader, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_12', skip = true })

	character_util.set_direction(staff, 'left')
	character_util.set_emotion(staff, { name = 'scared' })

	-- 저… 전데요.
	speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_13', skip = true })

	-- 또 너냐?!
	music_player:PlaySfxOneShot('01_jump_01')
	character_util.jump(invader, 0.4,0.4)
	speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_14', skip = true })

	-- 또 쟤야?
	speech_bubble_util.show_speech_bubble(get_character('waiting_room_actor_1'),
			{ key = 'movie_4_youngest_staff_15', bubble_direction = 'rb' })

	character_util.move_to(invader, staff.Position - vector(1, 0, 0), 1.5, nil, true, true)

	wait_for_sec(0.5)

	-- 어휴 맨날 저러네
	speech_bubble_util.show_speech_bubble(get_character('waiting_room_actor_2'),
			{ key = 'movie_4_youngest_staff_16', bubble_direction = 'rb' })

	wait_for_sec(1.0)

	if self.select_number == 6 then
		-- 야! 니가 인간이라고 인간들 것만 주문했냐!
		music_player:PlaySfxOneShot('02_die_hulk_01')
		character_util.set_anim(invader, { name = 'embarrassed' })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_17', skip = true })
		-- 이 자식이 빠져가지고 진짜!
		character_util.set_anim(invader, { name = 'release', sfx_name = '01_swing_01', loop = true })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_18', skip = true })
	elseif self.select_number == 7 then
		-- 7개면 우리 인베이더가 먹으라고 시킨거 같은데.
		character_util.set_anim(invader, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_19', skip = true })
		-- 천민 도시락? 우리보고 이런 걸 먹으라고?
		character_util.set_anim(invader, { name = 'release', sfx_name = '01_swing_01', loop = true })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_20', skip = true })
	elseif self.select_number == 13 then
		-- 13개를 전부 황제 도시락으로 시키면 어떡해!
		music_player:PlaySfxOneShot('02_die_hulk_01')
		character_util.set_anim(invader, { name = 'embarrassed' })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_21', skip = true })
		-- 인베이더 것만 황제인게 당연하잖아!
		character_util.set_anim(invader, { name = 'release', sfx_name = '01_swing_01', loop = true })
		speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_22', skip = true })
	end

	-- 죄, 죄송합니다……
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	character_util.set_emotion(staff, { name = 'scared' })
	speech_bubble_util.show_speech_bubble_async(staff, { key = 'movie_4_youngest_staff_23', skip = true })

	-- 아오, 이런걸 스탭이라고.
	music_player:PlaySfxOneShot('02_die_hulk_01')
	character_util.set_anim(invader, { name = 'embarrassed' })
	speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_24', skip = true })

	-- 넌 일주일 간 밥 없을 줄 알아!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	character_util.set_anim(invader, { name = 'release', sfx_name = '01_swing_01', loop = true })
	speech_bubble_util.show_speech_bubble_async(invader, { key = 'movie_4_youngest_staff_25', skip = true })

	character_util.remove_anim(invader)
	character_util.remove_anim(staff)

	self.saw_youngest_staff = true

	character_util.set_anim(staff, { name = 'hurt', loop = true })

	-- 마, 망했어……
	staff.Interactable.Talk = 'movie_4_youngest_staff_26'

	-- 저걸 어떡하지?
	invader.Interactable.Talk = 'movie_4_youngest_staff_27'

	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
