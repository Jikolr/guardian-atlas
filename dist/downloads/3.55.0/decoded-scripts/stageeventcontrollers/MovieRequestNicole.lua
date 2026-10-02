local local_class = newclass("MovieRequestNicoleController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.nicole_name = 'movie_nicole'
	self.actress_name = 'actress_teatan'

	self.staff1_name = 'nicole_staff_1'
	self.staff2_name = 'nicole_staff_2'

	self.progress_enum = {
		--- 초기 상태
		idle = 0,
		--- 니콜의 부탁 수락
		accept = 1,
		--- 여배우가 따라다님
		follow = 2,
		--- 여배우 함정에 빠트림
		trap = 3,
		--- 끝난 후
		after = 4,
	}

	--- 현재 진행도
	self.current_progress = nil

	self.saw_request_nicole = false

	self.request_accept = false
end

function local_class:load_resource()
	-- 스타피스 획득 여부에 따른 처리
	if not CS.Oak.StageProgress.Current:HasStarPiece('how_i_met_star_piece') then
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

		message_system:Publish(CS.Oak.DoorOpenEvent.Create('nicole_door'))

		get_character(self.nicole_name).Interactable:AddListener(self.cs_controller)
		character_util.set_emotion(get_character(self.nicole_name), { name = 'tired' })
		get_character(self.actress_name).Interactable.Talk = 'movie_4_request_actress_1'

		self.current_progress = self.progress_enum.idle

		unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	else
		self.saw_request_nicole = true
		character_util.set_emotion(get_character(self.nicole_name), { name = 'idle' })
		character_util.set_active_state(get_character(self.nicole_name), 'disabled')
		character_util.set_active_state(get_character(self.actress_name), 'disabled')

		message_system:Publish(CS.Oak.DoorCloseEvent.Create('nicole_door'))
	end
	get_field_object('item_wall').ActiveState = active_state('disabled')
	character_util.set_active_state(get_character(self.staff1_name), 'disabled')
	character_util.set_active_state(get_character(self.staff2_name), 'disabled')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	get_character(self.nicole_name).Interactable:RemoveRelatedEvent(self.cs_controller)

	local actress = get_character(self.actress_name)
	if lua_helper.type_compare(actress.Interactable, CS.Oak.NPCInteractable) then
		actress.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.aura_effect ~= nil then
		self.aura_effect:Dispose()
		self.aura_effect = nil
	end

	self.progress_enum = nil
	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if not self.saw_request_nicole then
			if self.current_progress == self.progress_enum.idle then
				if lua_helper.reference_equals(e.Target, get_character(self.nicole_name)) then
					sp_util.play_normal_screenplay(self.nicole_request_talk, self)
					return true
				end
			elseif self.current_progress == self.progress_enum.accept then
				if lua_helper.reference_equals(e.Target, get_character(self.actress_name)) then
					sp_util.play_normal_screenplay(self.actress_talk, self)
					return true
				end
			elseif self.current_progress == self.progress_enum.follow then
				if lua_helper.reference_equals(e.Target, get_field_object('nicole_trap_point')) then
					sp_util.play_normal_screenplay(self.actress_trap, self)
					return true
				end
			elseif self.current_progress == self.progress_enum.trap then
				if lua_helper.reference_equals(e.Target, get_character(self.nicole_name)) then
					sp_util.play_normal_screenplay(self.nicole_talk_last, self)
					return true
				end
			end

		else
			if lua_helper.reference_equals(e.Target, get_field_object('item_wall')) then
				sp_util.play_normal_screenplay(self.get_paper, self)
				return true
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			return false
		end
		if not self.saw_request_nicole then
			if e.Zone.Name == 'request_nicole_zone' and self.current_progress == self.progress_enum.follow then
				sp_util.play_normal_screenplay(self.actress_comeback, self)
				return true
			end
		end
	end
	return false
end

-- 니콜의 부탁을 들어줌
function local_class:nicole_request_talk()
	local nicole = get_character(self.nicole_name)
	local chair = get_field_object('nicole_trap_point')

	local pos = nicole.Position + unity_class.vector3.right * 2
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)

	-- 넌 그때 그 엑스트라…!
	character_util.set_emotion(nicole, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_1', skip = true })

	-- 난 망했어…
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	character_util.set_emotion(nicole, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_2', skip = true })

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(nicole, 0.2, 0.5)
	character_util.move_to_async(nicole, nicole.Position + vector(1, -0.5, 0), 0.5)

	-- 인베이더 감독을 믿고 다리뼈 축소 수술까지 받았는데…
	character_util.set_emotion(nicole, { name = 'idle' })
	character_util.set_anim(nicole, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_3', skip = true })

	-- 망할 배역 도둑놈에게 배역을 뺏기고 말았어.
	character_util.set_emotion(nicole, { name = 'mad' })
	character_util.set_anim(nicole, { name = 'release', sfx_name = '01_swing_01', loop = true  })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_4', skip = true })

	-- 저 티탄 녀석만 사라지면 내가 찍을 수 있을텐데…!
	character_util.set_emotion(nicole, { name = 'mad' })
	character_util.set_anim(nicole, { name = 'release' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_5', skip = true })

	-- 있지, 부탁이 있어.
	character_util.set_emotion(nicole, { name = 'idle' })
	character_util.set_anim(nicole, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_6', skip = true })

	-- 저기 보이지?
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_7', skip = true })

	-- 함정 위치로 카메라 이동
	camera_util.move_async(chair.Position, 1, { end_target = chair })

	-- 저 도둑놈을 저기로 유인해줘.
	speech_bubble_util.show_speech_bubble_async(nicole,
			{ key = 'movie_4_request_nicole_8', skip = true, screen_pos = vector(-350, -200) })

	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })

	-- 그럼 내가 문을 닫아서 가둬버릴 테니까!
	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_9', skip = true })

	-- 계획이 성공하면 꼭 사례할게. 알았지?
	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'nod' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_nicole_10', skip = true })

	self.current_progress = self.progress_enum.accept

	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'idle' })
	nicole.Interactable:RemoveRelatedEvent(self.cs_controller)
	nicole.Interactable.Talk = 'movie_4_request_nicole_10'

	get_character(self.actress_name).Interactable:AddListener(self.cs_controller)
end

-- 티탄족 여배우한테 말걸기
function local_class:actress_talk()
	local actress = get_character(self.actress_name)

	party_util.align_to_target(actress, 'down', 1)

	-- 무슨… 일이시죠?
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_1', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- 감독이 불렀다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	-- 니콜이 불렀다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_2'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 2
		end
	})

	ui_overlay_util.push_overlay(actress, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 1 then
		-- 감독님이… 저를요?
		speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_2', skip = true })
	else
		-- 니콜이… 저를요?
		speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_3', skip = true })
	end

	-- 어서 가보죠.
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(actress, 0.2, 0.5)
	character_util.move_to_async(actress, actress.Position + vector(0, -0.5, -0.5), 0.5)
	character_util.set_anim(actress, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_4', skip = true })

	-- 여배우 따라다님

	character_util.remove_emotion(actress)
	character_util.remove_anim(actress)

	actress.Interactable:RemoveRelatedEvent(self.cs_controller)
	actress.Interactable = CS.Oak.NonInteractable.Instance
	actress.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(actress, user_party, 0, 0, false)
	actress:OnEvent(CS.Oak.StateChangeEvent.Create(clms))

	local chair = get_field_object('nicole_trap_point')
	chair.Interactable = CS.Oak.PublishInteractable.Create()

	self.aura_effect = unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(
			get_field_object('nicole_trap_point').Position)

	character_util.set_direction(actress, 'down')
	self.current_progress = self.progress_enum.follow
end

-- 여배우를 데리고 밖으로 나가려 할 경우
function local_class:actress_comeback()
	local actress = get_character(self.actress_name)

	actress:RemoveEmotion()
	actress:OnEvent(CS.Oak.StateResetEvent.Instance)
	actress.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	actress.Interactable = CS.Oak.NPCInteractable.Create()
	actress.Interactable:AddListener(self.cs_controller)

	-- 감독님이 여기서 대기하라 하셨어요.
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_5', skip = true })

	character_util.move_to_async(actress, vector(49, 0, actress.Position.z), nil, 5, true, true)
	character_util.move_to_async(actress, vector(49, 0, 33), nil, 5, true, true)

	character_util.set_direction(actress, 'down')
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(actress, 0.2, 0.5)
	character_util.move_to_async(actress, vector(49, 0.5, 33.5), 0.5)

	character_util.set_anim(actress, { name = 'seat', loop = true })

	local chair = get_field_object('nicole_trap_point')
	chair.Interactable = CS.Oak.NonInteractable.Instance

	self.aura_effect:Dispose()
	self.aura_effect = nil

	self.current_progress = self.progress_enum.accept
end

-- 여배우를 목적지로 데리고 갈 경우
function local_class:actress_trap()
	local actress = get_character(self.actress_name)
	local chair = get_field_object('nicole_trap_point')

	self.aura_effect:Dispose()
	self.aura_effect = nil

	chair.Interactable = CS.Oak.NonInteractable.Instance

	actress:RemoveEmotion()
	actress:OnEvent(CS.Oak.StateResetEvent.Instance)

	-- 이런 곳에서 보자고 했다니… 특이하네요.
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_6', skip = true })

	-- 플레이어 나옴
	local pos = chair.Position + unity_class.vector3.back * 5 + unity_class.vector3.right
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 2, CS.Oak.Party.AlignType.Linear)

	-- 여배우는 의자로 가서 앉음
	character_util.move_to_async(actress, chair.Position + vector(0, 0, -1), 1, nil, true, true)
	camera_util.move(chair.Position + vector(0, 0.5, -0.5), 1, { end_target = actress })

	character_util.set_direction(actress, 'down')
	character_util.jump(actress, 0.2, 0.5)
	character_util.move_to_async(actress, chair.Position + vector(0, 0.5, -0.5), 0.5)

	character_util.set_anim(actress, { name = 'seat', loop = true })

	wait_for_sec(1.5)

	-- 문 닫힘
	music_player:PlaySfxOneShot('02_gimmick_door_up_02')
	message_system:Publish(CS.Oak.DoorCloseEvent.Create('nicole_door'))

	character_util.set_emotion(actress, { name = 'surprise' })
	character_util.jump(actress, 0.5, 0.3)
	wait_for_sec(1.0)
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(actress, 0.2, 0.5)
	character_util.move_to_async(actress, chair.Position + vector(0, 0, -1), 0.5)

	-- 이게 무슨 일이죠? 어서 열어주세요!
	character_util.set_anim(actress, { name = 'idle' })
	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_7', skip = true })

	-- 혹시 니콜이 시켜서 한 일인가요?
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_8', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	-- 맞다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_3'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
		end
	})
	-- 아니다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_4'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
		end
	})

	ui_overlay_util.push_overlay(actress, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	-- … 니콜이 제 배역을 노리고 있었다는 건 알고 있었어요.
	character_util.set_emotion(actress, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_9', skip = true })

	-- 하지만 이건 목숨이 걸린 정말 위험한 씬이에요.
	character_util.set_emotion(actress, { name = 'scared' })
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_10', skip = true })

	-- 제 빚만 아니었다면… 저도 절대 안찍었을 거라고요!
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_11', skip = true })

	-- 니콜에게 지금이라도 포기하라고 전해주세요. 꼭이요!
	speech_bubble_util.show_speech_bubble_async(actress, { key = 'movie_4_request_actress_12', skip = true })

	self.current_progress = self.progress_enum.trap

	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })

	get_character(self.nicole_name).Interactable:AddListener(self.cs_controller)
end

-- 함정에 빠트린 후 니콜에게 다시 말을 걸면
function local_class:nicole_talk_last()
	local nicole = get_character(self.nicole_name)
	local staff1 = get_character(self.staff1_name)
	local staff2 = get_character(self.staff2_name)

	character_util.set_position(staff1, vector(62, 0, 32))
	character_util.set_position(staff2, vector(62, 0, 31))

	party_util.align_to_target(nicole, 'right', 1, 'arc')


	-- 좋아, 드디어 저 도둑놈을 치웠네.
	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'success', sfx_name = "01_small_jump_01", loop = true })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_1', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	local choice = 0
	-- 여배우의 말을 전한다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_5'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	-- 아무 말도 하지 않는다.
	branches:Add({
		Text = game_string:GetString('movie_4_request_branch_6'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
			choice = 2
		end
	})

	ui_overlay_util.push_overlay(nicole, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	if choice == 1 then
		-- 흥, 그런 거짓말엔 3살짜리 애도 안 속겠다.
		character_util.set_emotion(nicole, { name = 'mad' })
		character_util.set_anim(nicole, { name = 'idle' })
		music_player:PlaySfxOneShot('03_dialogue_negative_02')
		speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_2', skip = true })
	end

	-- 아무튼 잘했어. 여기 약속했던 보상이야.
	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_3', skip = true })

	-- 스타피스 등장
	local star_piece = get_field_object('how_i_met_star_piece')
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(nicole.Position))
	wait_for_sec(2.0)

	-- 이제 좀만 기다리면…
	character_util.set_emotion(nicole, { name = 'smile' })
	character_util.set_anim(nicole, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_4', skip = true })

	-- 인베이더 스탭 등장
	character_util.set_active_state(get_character(self.staff1_name), 'enabled')
	character_util.set_active_state(get_character(self.staff2_name), 'enabled')

	character_util.move_to(staff1, vector(47, 0, staff1.Position.z), nil, 5, true, true)
	character_util.move_to_async(staff2, vector(47, 0, staff2.Position.z), nil, 5, true, true)

	-- 여기 티탄 배우가 있다고 들었는데……
	music_player:PlaySfxOneShot('02_die_hulk_01')
	speech_bubble_util.show_speech_bubble_async(staff1, { key = 'movie_4_request_talk_5', skip = true })

	character_util.move_to_async(nicole, vector(nicole.Position.x, 0, 32), nil, 4, true, true)
	character_util.move_to_async(nicole, vector(nicole.Position.x + 1, 0, 32), nil, 4, true, true)

	-- 저예요! 저!
	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.jump(nicole, 0.4, 0.3)
	wait_for_sec(0.3)
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_6', skip = true })

	-- 듣던거랑은 좀 다른데…
	character_util.set_anim(staff1, { 'cross_arm', loop = true })
	speech_bubble_util.show_speech_bubble_async(staff1, { key = 'movie_4_request_talk_7', skip = true })

	-- 뭐 상관 없지.
	speech_bubble_util.show_speech_bubble_async(staff2, { key = 'movie_4_request_talk_8', skip = true })

	-- 자 여기 사인 해!
	speech_bubble_util.show_speech_bubble_async(staff1, { key = 'movie_4_request_talk_9', skip = true })

	-- 종이를 던져 준다.
	character_util.set_anim(staff1, { name = 'throw', loop = false })
	wait_for_sec(0.2)
	music_player:PlaySfxOneShot('01_throw_01')
	character_util.set_anim(staff1, { name = 'idle', loop = true })

	local sign_id = 20167
	local drop_position = staff1.Position
	-- 종이 드롭
	local drop_item = drop_item_util.create_item(
			{ pos = drop_position,
			  target = nicole.Position + vector(0.2, 0 , 0), itemid = sign_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true })

	wait_for_sec(1.5)

	-- 뭐, 내용은 다 알테니 아래 싸인 하라고.
	speech_bubble_util.show_speech_bubble_async(staff2, { key = 'movie_4_request_talk_10', skip = true })

	-- 네!
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_11', skip = true })


	character_util.set_anim(nicole, { name = 'eat', loop = true })
	wait_for_sec(0.2)
	music_player:PlaySfx({ sfxName = '01_turn_page_01', loop = true, duration = 0.8})
	wait_for_sec(0.8)

	-- 흠… 좋아. 그럼 가지.
	speech_bubble_util.show_speech_bubble_async(staff1, { key = 'movie_4_request_talk_12', skip = true })

	-- 이걸로 대배우 니콜의 시대가 다시 시작되는 거야!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(nicole, { name = 'victory_get', loop = false })
	speech_bubble_util.show_speech_bubble_async(nicole, { key = 'movie_4_request_talk_13', skip = true })

	character_util.remove_anim(nicole)
	character_util.set_direction(staff1, 'right')
	character_util.set_anim(staff1, { name = 'walk', loop = true })
	character_util.move_to_async(staff1, vector(47, 0, staff1.Position.z), nil, 4, true, true)
	character_util.move_to(nicole, nicole.Position + vector(13, 0, 0), nil, 4, true, true)
	character_util.move_to(staff1, staff1.Position + vector(13, 0, 0), nil, 4, true, true)
	character_util.move_to_async(staff2, staff2.Position + vector(13, 0, 0), nil, 4, true, true)

	local item = get_field_object('item_wall')
	item.ActiveState = active_state('enabled')
	item.Position = drop_item.Position
	item.Interactable = CS.Oak.PublishInteractable.Create()

	character_util.set_active_state(get_character(self.nicole_name), 'disabled')
	character_util.set_active_state(get_character(self.staff1_name), 'disabled')
	character_util.set_active_state(get_character(self.staff2_name), 'disabled')

	self.current_progress = self.progress_enum.after
	self.saw_request_nicole = true
end

function local_class:get_paper()
	-- 촬영 동의서
	-- 본 촬영의 위험성에 대해 사전에 충분히 설명을 듣고 이해했습니다.
	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString('movie_4_request_talk_14'), 0, 1))
	stage.FieldUINarrationBox:Hide()
	wait_for_sec(0.5)
	-- 촬영 중 발생할 수 있는 신체 절단, 사망 등의 사고에 그 어떤 보상도 요구하지 않겠습니다.
	-- 서명: 니콜
	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString('movie_4_request_talk_15'), 0, 1))
	stage.FieldUINarrationBox:Hide()
	wait_for_sec(0.5)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
