local local_class = newclass("HideAndSeekController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress_enum = {
		-- 숨바꼭질 시작
		start_hide_and_seek = 0,
		-- 표지판 뒤에 숨은 학생 찾음
		find_sign_board_boy = 1,
		-- 사다리 뒤에 숨은 학생 찾음
		find_ladder_boy = 2,
		-- 도망가는 학생
		runaway_boy = 3,
		-- 숨바꼭질 종료
		end_hide_and_seek = 4
	}

	-- 현재 진행도
	self.current_progress = nil

	self.talk_skip = false

	self.invisible_boy_name = 'invisible_boy'
	self.hide_sign_board_name = 'hide_sign_board'
	self.hide_ladder_name = 'hide_ladder'
	self.hide_pot_name = 'hide_pot_'
	self.break_pot_effect_name = 'break_library_pot'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate(self.break_pot_effect_name)

	-- 투명한 학생 세팅
	local invisible_boy = get_character(self.invisible_boy_name)
	invisible_boy.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.spine_set_alpha_fade(invisible_boy, 0.5, 1)
	-- 투명한 학생 레벨 UI 제거
	field_ui_manager:RemoveUI(invisible_boy, CS.Oak.FieldUiType.CharacterStats)

	-- 스타피스 획득 여부 체크
	if stage_progress:HasStarPiece('hide_and_seek_star_piece') then
		invisible_boy.Position = vector(99, 0, 99)
		self.current_progress = self.progress_enum.end_hide_and_seek
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.progress_enum = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local invisible_boy = get_character(self.invisible_boy_name)

	if lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == 'battle2' and self.current_progress == nil then
			invisible_boy.Interactable = CS.Oak.PublishInteractable.Create()
			invisible_boy.OverrideCrashBehaviour = nil
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, invisible_boy) then
			if self.current_progress == nil then
				sp_util.play_normal_screenplay(self.start_hide_and_seek, self)
				return true
			end
		end

		local hide_sign_board = get_field_object(self.hide_sign_board_name)
		if lua_helper.reference_equals(e.Target, hide_sign_board) then
			if self.current_progress == self.progress_enum.start_hide_and_seek then
				sp_util.play_normal_screenplay(self.find_sign_board_boy, self)
				return true
			end
		end

		local hide_ladder = get_field_object(self.hide_ladder_name)
		if lua_helper.reference_equals(e.Target, hide_ladder) then
			if self.current_progress == self.progress_enum.find_sign_board_boy then
				sp_util.play_normal_screenplay(self.find_ladder_boy, self)
				return true
			end
		end

		local hide_pot = get_field_object(self.hide_pot_name .. 1)
		if lua_helper.reference_equals(e.Target, hide_pot) then
			if self.current_progress == self.progress_enum.runaway_boy then
				sp_util.play_normal_screenplay(self.end_hide_and_seek, self)
				return true
			end
		end
	end

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if not lua_helper.reference_equals(e.FieldObject, user_party_leader) or not e.FullEnter then return false end

		local zone_name = e.Zone.Name

		if zone_name == 'runaway_invisible_boy' and self.current_progress == self.progress_enum.find_ladder_boy then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.runaway_invisible_boy, self))
			return true
		end
	end

	return false
end

-- 대화 후 숨바꼭질 시작
function local_class:start_hide_and_seek()
	local invisible_boy = get_character(self.invisible_boy_name)
	invisible_boy.Interactable = CS.Oak.NPCInteractable.Create()

	local marker = field:GetMarker('talk_invisible_boy').position
	character_util.set_anim(invisible_boy, { name = 'idle' })
	if not self.talk_skip then
		character_util.move_to(invisible_boy, marker, 1, 0, false, true)
	end
	character_util.align_party(marker, 'right', 1, 'linear')

	wait_for_sec(0.5)

	if not self.talk_skip then
		character_util.set_anim(invisible_boy, { name = 'release', sfx_name = '01_swing_01' })
		-- 엇! 뭐야… 너 내가 보이는거야?
		speech_bubble_util.show_speech_bubble_async(invisible_boy,
			{ key = 'nightmare_magicschool_1_hideandseek_1', skip = true })

		character_util.remove_anim(invisible_boy)

		-- 투명 망토를 썼는데 알아차리다니 감이 좋은 걸?
		speech_bubble_util.show_speech_bubble_async(invisible_boy,
			{ key = 'nightmare_magicschool_1_hideandseek_2', skip = true })

		-- 이제 유령들 사이에 숨어 있는 것도 질렸어.
		speech_bubble_util.show_speech_bubble_async(invisible_boy,
			{ key = 'nightmare_magicschool_1_hideandseek_3', skip = true })
	end

	-- 나랑 숨바꼭질 해볼래?
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_4', skip = true })

	self.talk_skip = true

	-- 좋아! / 싫어!
	local player_choice = choose_util.play_choose_event(
		{{ 'nightmare_magicschool_1_hideandseek_5', 'mercy' },
		 { 'nightmare_magicschool_1_hideandseek_6', 'brutal' }})

	-- 선택: 싫어!
	if player_choice == 2 then
		-- 그래. 난 여기 있을테니 심심하면 말해줘.
		speech_bubble_util.show_speech_bubble_async(invisible_boy,
			{ key = 'nightmare_magicschool_1_hideandseek_7', skip = true })

		invisible_boy.Interactable = CS.Oak.PublishInteractable.Create()
		return
	end

	music_player:PlaySfxOneShot('01_small_jump_01')
	character_util.normal_jump_async(invisible_boy)
	-- 좋아!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_8', skip = true })

	-- 그럼 시작이다!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_9', skip = true })

	-- 도망침
	character_util.remove_anim(invisible_boy)
	local pos = invisible_boy.Position + unity_class.vector3.forward
	character_util.move_waypoint_async(invisible_boy, pos, 9, true, nil,
		nil, nil, true)

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.jump(invisible_boy, 1.3, 0.7)
	pos = invisible_boy.Position + 2 * unity_class.vector3.forward
	character_util.move_to_async(invisible_boy, pos, 0.7, nil, true, false)

	local way_points = {invisible_boy.Position + vector(5, 0, 0),
						invisible_boy.Position + vector(5, 0, 4)}

	character_util.move_waypoint_async(invisible_boy, way_points, 9, true, nil,
		nil, nil, true)

	-- 표지판 뒤에 숨은 학생으로 세팅
	marker = field:GetMarker('hide_sign_board').position
	invisible_boy.Position = marker
	character_util.set_direction(invisible_boy, 'down')
	character_util.set_anim(invisible_boy, { name = 'idle' })
	character_util.set_emotion(invisible_boy, { name = 'idle' })

	local hide_sign_board = get_field_object(self.hide_sign_board_name)
	hide_sign_board.Interactable = CS.Oak.PublishInteractable.Create()

	self.current_progress = self.progress_enum.start_hide_and_seek
end

-- 표지판 뒤에 숨은 학생 찾음
function local_class:find_sign_board_boy()
	local hide_sign_board = get_field_object(self.hide_sign_board_name)
	hide_sign_board.Interactable = CS.Oak.SignboardInteractable()
	hide_sign_board.Interactable.Message = 'magicschool_1_1_signboard_4'

	local invisible_boy = get_character(self.invisible_boy_name)
	-- 플레이어의 상호작용 위치에 따른 연출
	local pos = invisible_boy.Position + unity_class.vector3.left
	local dir = (user_party_leader.Position - invisible_boy.Position):ToDirection()
	if dir == CS.Oak.Direction.Right then
		pos = invisible_boy.Position + unity_class.vector3.right
	else
		dir = 'left'
	end
	character_util.move_to(invisible_boy, pos, 1, 0, true, true)
	character_util.align_party(pos, dir, 1, 'linear')

	wait_for_sec(0.5)

	-- 엇!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_10', skip = true })

	-- 대단한 걸?
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_11', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_emotion(invisible_boy, { name = 'doyagao' })
	-- 이번에도 쉽지 않을 꺼야!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_12', skip = true })

	character_util.remove_emotion(invisible_boy)

	-- 자! 출발한다!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_13', skip = true })

	-- 도망침
	character_util.remove_anim(invisible_boy)
	local way_points = {invisible_boy.Position + vector(0, 0, -1),
						invisible_boy.Position + vector(8, 0, -1)}

	character_util.move_waypoint_async(invisible_boy, way_points, 9, true, nil,
		nil, nil, true)

	-- 사다리 뒤에 숨은 학생 위치로 세팅
	local marker = field:GetMarker('hide_ladder').position
	invisible_boy.Position = marker
	character_util.set_direction(invisible_boy, 'left')
	character_util.set_anim(invisible_boy, { name = 'walk4legs', loop = false })

	local hide_ladder = get_field_object(self.hide_ladder_name)
	hide_ladder.Interactable = CS.Oak.PublishInteractable.Create()

	self.current_progress = self.progress_enum.find_sign_board_boy
end

-- 사다리 뒤에 숨은 학생 찾음
function local_class:find_ladder_boy()
	local hide_ladder = get_field_object(self.hide_ladder_name)
	hide_ladder.Interactable = CS.Oak.NonInteractable.Instance

	local invisible_boy = get_character(self.invisible_boy_name)

	local pos = invisible_boy.Position + 0.5 * unity_class.vector3.back
	coroutine_manager:StartCoroutine(
		stage.StageGameObject, util.cs_generator(party_util.align_party, pos, 'right', 1, 'linear'))

	pos = invisible_boy.Position + unity_class.vector3.left
	character_util.set_anim(invisible_boy, { name = 'walk4legs' })
	character_util.move_to_async(invisible_boy, pos, nil, 2.5, false, false)

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.remove_anim(invisible_boy)
	character_util.normal_jump(invisible_boy)
	pos = invisible_boy.Position + vector(0, -1, -0.5)
	character_util.move_to_async(invisible_boy, pos, nil, 2.5, true, true)

	pos = invisible_boy.Position + unity_class.vector3.right
	character_util.move_to_async(invisible_boy, pos, nil, 2.5, true, true)

	wait_for_sec(0.5)

	-- 눈썰미가 좋은데?
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_18', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	-- 좋아! 이번엔 절대 찾을 수 없을 걸?!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_19', skip = true })

	-- 만약에 나를 찾는다면 특별한 선물을 줄게!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_20', skip = true })

	-- 잘 찾아보라고!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_21', skip = true })

	-- 도망침
	local way_points = {invisible_boy.Position + vector(0, 0, -2),
						invisible_boy.Position + vector(-12, 0, -2)}

	character_util.move_waypoint_async(invisible_boy, way_points, 9, true, nil,
		nil, nil, true)

	-- 도망 준비중인 위치로 세팅
	local marker = field:GetMarker('run_invisible_boy').position
	invisible_boy.Position = marker
	character_util.set_direction(invisible_boy, 'left')
	character_util.set_anim(invisible_boy, { name = 'idle' })
	character_util.set_emotion(invisible_boy, { name = 'idle' })

	self.current_progress = self.progress_enum.find_ladder_boy
end

-- 도망가는 투명 학생
function local_class:runaway_invisible_boy()
	local invisible_boy = get_character(self.invisible_boy_name)
	local pos = invisible_boy.Position + 9 * unity_class.vector3.left
	character_util.remove_anim(invisible_boy)
	character_util.move_waypoint_async(invisible_boy, pos, 7, true, nil,
		nil, nil, true)

	-- 마지막 위치로 세팅
	local marker = field:GetMarker('end_invisible_boy').position
	invisible_boy.Position = marker
	character_util.set_direction(invisible_boy, 'up')
	character_util.set_anim(invisible_boy, { name = 'idle' })
	character_util.set_emotion(invisible_boy, { name = 'idle' })

	-- 항아리 세팅
	local pots_pos = { marker, marker + vector(-1, 0, 0), marker + vector(-1, 0, -1) }
	local hide_pots = {}
	for i = 1, 3 do
		local hide_pot = get_field_object(self.hide_pot_name .. i)
		table.insert(hide_pots, hide_pot)
		hide_pot.Position = pots_pos[i]
	end

	hide_pots[1].Interactable = CS.Oak.PublishInteractable.Create()

	self.current_progress = self.progress_enum.runaway_boy
end

-- 숨바꼭질 종료
function local_class:end_hide_and_seek()
	local hide_pot = get_field_object(self.hide_pot_name .. 1)
	hide_pot.Interactable = CS.Oak.NonInteractable.Instance

	local invisible_boy = get_character(self.invisible_boy_name)
	character_util.align_party(invisible_boy, 'down', 1, 'linear')
	wait_for_sec(0.5)

	character_util.set_anim(user_party_leader, { name = 'attack', loop = false })
	wait_for_sec(0.2)

	-- 항아리 깨짐
	hide_pot.ActiveState = active_state('disabled')
	local break_pot_effect_pool = unity_object_pool.GetOrCreate(self.break_pot_effect_name)
	break_pot_effect_pool:Instantiate(hide_pot.Position)
	music_player:PlaySfxOneShot('02_break_bottle_01')
	wait_for_sec(0.2)

	character_util.remove_anim(user_party_leader)

	character_util.set_direction(invisible_boy, 'down')
	character_util.set_anim(invisible_boy, { name = 'embarrassed' })
	character_util.set_emotion(invisible_boy, { name = 'surprise' })
	character_util.normal_jump_async(invisible_boy)

	character_util.remove_anim(user_party_leader)

	music_player:PlaySfxOneShot('03_runaway_01')
	-- 뭐... 뭐야?! 너!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_14', skip = true })

	character_util.remove_anim_and_emotion(invisible_boy)

	music_player:PlaySfxOneShot('01_harry_01')
	-- 9와 3/4 책장을 찾아낸거야?!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_15', skip = true })

	-- 정말 대단한데? 네 덕분에 잘 놀았어!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_16', skip = true })

	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 자! 아까 말했던 숨바꼭질 보상이야!
	speech_bubble_util.show_speech_bubble_async(invisible_boy,
		{ key = 'nightmare_magicschool_1_hideandseek_17', skip = true })

	local star_piece = get_field_object('hide_and_seek_star_piece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(invisible_boy.Position))
	wait_for_sec(2)

	invisible_boy.Interactable.Talk = 'nightmare_magicschool_1_hideandseek_16'

	self.current_progress = self.progress_enum.end_hide_and_seek
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
