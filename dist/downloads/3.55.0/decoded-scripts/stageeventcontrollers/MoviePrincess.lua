local local_class = newclass("MoviePrincessController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.princess_name = 'movie_princess'
	self.invader_staff_1_name = 'princess_invader_1'
	self.invader_staff_2_name = 'princess_invader_2'

	self.cnt = 0
end

function local_class:load_resource()
	local princess = get_character(self.princess_name)
	-- 스타피스 획득 여부에 따른 처리
	if not CS.Oak.StageProgress.Current:HasStarPiece('movie_princess_star_piece') then
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

		princess.Interactable:AddListener(self.cs_controller)
	else
		princess.ActiveState = active_state('disabled')

		local invader_staff_1 = get_character(self.invader_staff_1_name)
		invader_staff_1.ActiveState = active_state('disabled')
		local invader_staff_2 = get_character(self.invader_staff_2_name)
		invader_staff_2.ActiveState = active_state('disabled')
	end

	self.princess_coroutine = coroutine_class.coroutine(
		stage.StageGameObject, util.cs_generator(self.princess_routine, self))
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	local princess = get_character(self.princess_name)
	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.princess_coroutine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local princess = get_character(self.princess_name)
		if lua_helper.reference_equals(e.Target, princess) then
			sp_util.play_normal_screenplay(self.talk_princess, self)
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then

		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

		if e.CameraGrid.name == 'movie_princess_grid' and self.cnt == 0 then
			coroutine_manager:StartCoroutine(self.princess_coroutine)
			self.cnt = self.cnt + 1
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then

		if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

		if e.CameraGrid.name == 'movie_princess_grid' then
			stop_coroutine(self.princess_coroutine)

			local princess = get_character(self.princess_name)
			speech_bubble_util.remove_bubble(princess)

			local invader_staff = get_character(self.invader_staff_1_name)
			speech_bubble_util.remove_bubble(invader_staff)
			return true
		end
	end

	return false
end

-- 플레이어가 해당 그리드에 들어왔을 때 싸우는 꼬마 공주
function local_class:princess_routine()
	local invader_staff_1 = get_character(self.invader_staff_1_name)
	local invader_staff_2 = get_character(self.invader_staff_2_name)
	local princess = get_character(self.princess_name)

	character_util.set_emotion(princess, { name = 'eyelight' })

	wait_for_sec(2)

	--왠지 누가 엄청 노려보는 듯한 기분이 드는데...
	speech_bubble_util.show_speech_bubble_async(invader_staff_2, { key = 'movie_4_princess_1', bubble_direction = 'lb' })

	--에이... 기분 탓이겠지~
	speech_bubble_util.show_speech_bubble_async(invader_staff_1, { key = 'movie_4_princess_2', bubble_direction = 'rb' })

	--저 못생긴 애들... 무슨 꿍꿍이지?
	--speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_3' })

	invader_staff_2.Interactable.Talk = 'movie_4_princess_1'
	invader_staff_1.Interactable.Talk = 'movie_4_princess_2'
end

-- 공주와 대화 시작
function local_class:talk_princess()
	stop_coroutine(self.princess_coroutine)

	local princess = get_character(self.princess_name)
	princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	--character_util.remove_anim_and_emotion(princess)
	speech_bubble_util.remove_bubble(princess)

	local invader_staff_1 = get_character(self.invader_staff_1_name)
	speech_bubble_util.remove_bubble(invader_staff_1)
	local invader_staff_2 = get_character(self.invader_staff_2_name)
	speech_bubble_util.remove_bubble(invader_staff_2)

	party_util.align_party(princess.Position + vector(-0.25, 0, 0), 'left', 0.5, 'linear')
	character_util.set_direction(princess, 'left')

	--wait_for_sec(0.5)

	character_util.set_emotion(princess, { name = 'surprise' })
	character_util.set_anim(princess, { name = 'success', sfx_name = "01_small_jump_01" })
	-- 앗!! <플레이어 이름>!!
	speech_bubble_util.show_speech_bubble_async(princess,
		{ key = game_string:Format('movie_4_princess_4', user.Name), skip = true })

	character_util.remove_anim_and_emotion(princess)
	character_util.move_to_async(princess, princess.Position + vector(-0.25, 0, 0), 0.5, nil, true, true)

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_anim(princess, { name = 'release', sfx_name = "01_swing_01" })
	-- 너 찾으러 몰래 들어왔다가 이놈들을 찾았지 뭐야!
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_5', skip = true })

	character_util.remove_anim_and_emotion(princess)

	character_util.set_emotion(princess, { name = 'tired' })
	-- 아! 촬영하느라 힘들지? 이거 마시고 힘내!
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_6', skip = true })

	character_util.remove_emotion(princess)

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.set_anim(princess, { name = 'hold', loop = false })
	wait_for_sec(0.15)

	character_util.set_anim(princess, { name = 'release', loop = false })
	music_player:PlaySfxOneShot('01_throw_01')

	-- 물 드랍
	local target_pos = user_party.Leader.Position + 0.5 * unity_class.vector3.right
	local drop_item = drop_item_util.create_item({ pos = princess.Position, target = target_pos,
								 itemid = 20036, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(1)

	character_util.remove_anim_and_emotion(princess)

	character_util.set_anim(user_party.Leader, { name = 'eat' })
	drop_item.ConsumeTarget = user_party.Leader
	wait_for_sec(1)

	character_util.remove_anim(user_party.Leader)

	character_util.set_emotion(princess, { name = 'awesome' })
	character_util.set_anim(princess, { name = 'get' })
	-- 맞다! 촬영장 구석에서 찾은 거야.
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_7', skip = true })

	character_util.remove_anim_and_emotion(princess)

	-- 스타피스 드랍
	local star_piece = get_field_object('movie_princess_star_piece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(princess.Position))

	character_util.set_emotion(princess, { name = 'smile' })
	-- 도움이 됐으면 좋겠다!
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_8', skip = true })

	character_util.remove_emotion(princess)

	character_util.set_emotion(princess, { name = 'mad' })
	character_util.set_anim(princess, { name = 'cast' })
	-- 난 이 못생긴 애들이 무슨 꿍꿍이인지 좀 더 감시해야겠어!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'movie_4_princess_9', skip = true })

	character_util.remove_anim_and_emotion(princess)
	character_util.set_direction(princess, "right")
	character_util.move_to_async(princess, princess.Position + vector(0.25, 0, 0), 0.5, nil, true, true)
	character_util.set_direction(princess, "left")

	character_util.set_emotion(princess, { name = 'eyelight' })

	--저 못생긴 애들... 무슨 꿍꿍이지?
	princess.Interactable.Talk = 'movie_4_princess_3'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
