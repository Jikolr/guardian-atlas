local local_class = newclass("NightmareMagicSchool1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.book_name = 'flying_book'
	self.otaku_name = 'otaku_student'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_starpiece_in_character')

	local otaku = get_character(self.otaku_name)
	otaku.Interactable:AddListener(self.cs_controller)

	unity_object_pool.GetOrCreate('FX_hit')

	-- 책 레벨 UI 제거
	local book = get_character(self.book_name)
	field_ui_manager:RemoveUI(book, CS.Oak.FieldUiType.CharacterStats)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	local otaku = get_character(self.otaku_name)
	if lua_helper.type_compare(otaku.Interactable, CS.Oak.NPCInteractable) then
		otaku.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local otaku = get_character(self.otaku_name)
		if lua_helper.reference_equals(e.Target, otaku) then
			sp_util.play_normal_screenplay(self.talk_otaku, self)
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		if not stage_progress:HasStarPiece('book_star_piece') then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.book_action_check, self))
		else
			local book = get_character(self.book_name)
			book.ActiveState = active_state('disabled')
		end
		return true
	end

	return false
end

-- 책이 해야할 액션 체크
function local_class:book_action_check()
	local book = get_character(self.book_name)
	local marker = field:GetMarker('book_point_11').position + vector(0, 1.5, -0.5)
	local fx_star_piece_effect_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	local star_piece_effect = fx_star_piece_effect_pool:Instantiate(marker)

	-- 방해물 웨이포인트 분기
	local branch_point = { 1, 5, 6, 7, 9, 11 }

	-- 방해물
	local obstruct_objs = {}
	for i = 1, 5 do
		local obstruct_obj = get_field_object('obstruct_object_' .. i)
		table.insert(obstruct_objs, obstruct_obj)
	end

	self.is_crash_book_routine_stop = true
	self.play_crash_book_routine = false

	-- 방해물이 사라지면 다음 지점으로 이동
	for i = 1, #obstruct_objs do
		-- 책 출발 사운드를 출력할 것인지 체크용
		local play_sound = false

		if obstruct_objs[i].ActiveState == active_state('enabled') then
			coroutine_manager:StartCoroutine(stage.StageGameObject, coroutine_class.coroutine(util.cs_generator(self.crash_book_routine, self)))
		end

		while obstruct_objs[i].ActiveState == active_state('enabled') do
			play_sound = true
			-- 네 번째 방해물은 문
			if i == 4 and obstruct_objs[i].FieldObjectBehaviour.IsOpen then wait_for_sec(1) break end
			-- 다섯 번째 방해불은 바위를 밀어서 처리
			if i == 5 and obstruct_objs[i].Position.x - book.Position.x > 1.8 then break end
			coroutine.yield(nil)
		end

		self.play_crash_book_routine = false

		while not self.is_crash_book_routine_stop do
			coroutine.yield(nil)
		end

		local dir = CS.Oak.Direction.Right
		if i == 3 then
			-- 네 번째 방해물의 방향은 아래
			dir = CS.Oak.Direction.Down
		elseif i == 5 then
			-- 마지막은 위를 향하도록
			dir = CS.Oak.Direction.Up
		end

		yield_return_func(self.move_book, self, book, branch_point[i], branch_point[i + 1], dir, play_sound)
	end

	-- 책 사라짐
	character_util.spine_set_alpha_fade(book, 0, 0.5)
	wait_for_sec(0.5)

	-- 스타피스 드랍
	star_piece_effect:Dispose()
	local star_piece = get_field_object('book_star_piece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(marker, false))
end

-- 웨이포인트를 따라 이동하는 책
function local_class:move_book(fo, start_index, end_index, dir, play_sound)
	local way_points = {}
	for i = start_index, end_index do
		local marker = field:GetMarker('book_point_' .. i).position
		table.insert(way_points, marker)
	end

	-- 출발 사운드
	if play_sound then
		music_player_util.play_sfx({ sfx_name = '01_flying_book_01', max_distance = 10,
									 type_priority = 'default', player_priority = 'default' })
	end

	character_util.set_anim(fo, { name = 'walk' })
	character_util.move_waypoint_async(fo, way_points, 5, false, 'stop', 'floor', dir)
end

-- 벽에 충돌하는 책 루틴
function local_class:crash_book_routine()
	self.play_crash_book_routine = true
	self.is_crash_book_routine_stop = false

	local book = get_character(self.book_name)
	local fx_hit_pool = unity_object_pool.GetOrCreate('FX_hit')
	while self.play_crash_book_routine do
		-- 방향에 따른 연출 변경
		local deviation = vector(0.7, 0, 0)
		local effect_pos = book.Position + 0.7 * unity_class.vector3.right
		if book.Direction == CS.Oak.Direction.Down then
			deviation = vector(0, 0, -0.7)
			effect_pos = book.Position + 0.7 * unity_class.vector3.back
		end

		character_util.spine_deviate_local(book, deviation, 0.2, 0.3)
		wait_for_sec(0.2)

		if not self.play_crash_book_routine then
			break
		end

		-- 충돌 이펙트
		local hit_effect = fx_hit_pool:Instantiate(effect_pos + 0.6 * unity_class.vector3.up)
		hit_effect.transform.localScale = 0.3 * unity_class.vector3.one

		-- 충돌 사운드
		music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = book, max_distance = 10,
									 type_priority = 'default', player_priority = 'default' })

		-- 책 충동 연출
		book.SpineController:DamageRedPulse()
		-- 디폴트 값 사용
		book.SpineController:DamageSquish(1)
		wait_for_sec(1.3)

		if not self.play_crash_book_routine then
			break
		end

		character_util.set_anim(book, { name = 'idle' })
		wait_for_sec(1)
	end

	self.is_crash_book_routine_stop = true
end

-- 오타쿠 학생과 대화
function local_class:talk_otaku()
	local otaku = get_character(self.otaku_name)
	otaku.Interactable:RemoveRelatedEvent(self.cs_controller)

	character_util.align_party(otaku, 'right')

	character_util.set_emotion(otaku, { name = 'smile' })
	-- 여어 히사시부리!
	local string_key = 'nightmare_nightmare_5_otaku_1'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	character_util.remove_emotion(otaku)

	-- 플레이어 점프 후 release
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_emotion(user_party_leader, { name = 'surprised' })
	character_util.normal_jump(user_party_leader)
	wait_for_sec(0.3)

	character_util.set_anim(user_party_leader, { name = 'release', sfx_name = '01_swing_01' })
	wait_for_sec(1)

	character_util.remove_anim_and_emotion(user_party_leader)

	character_util.set_anim(otaku, { name = 'question', loop = false })
	-- 나니? 널 어떻게 알아봤냐고?
	string_key = 'nightmare_nightmare_5_otaku_2'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	character_util.remove_anim(otaku)

	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.set_anim(otaku, { name = 'cast' })
	character_util.set_emotion(otaku, { name = 'smile' })
	-- 알아 봤을 리가! 젠젠 모르겠는 걸.
	string_key = 'nightmare_nightmare_5_otaku_3'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.remove_anim(otaku)
	character_util.set_anim(otaku, { name = 'dance' })
	-- 단지 셀러브리티로서 약간의 팬 서비스… 랄까?
	string_key = 'nightmare_nightmare_5_otaku_4'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	character_util.remove_anim_and_emotion(otaku)
	character_util.set_emotion(otaku, { name = 'tired' })
	-- 미안하지만 FB 친구가 되고 싶은 거라면 무리무리.
	string_key = 'nightmare_nightmare_5_otaku_5'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	character_util.set_anim(otaku, { name = 'cast' })
	-- 오레, 팔로워 수가 이미 2000명을 넘어버려서 당분간은 받지 않을 거라능.
	string_key = 'nightmare_nightmare_5_otaku_6'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	character_util.remove_anim_and_emotion(otaku)
	character_util.set_emotion(otaku, { name = 'smile' })
	-- 그럼, 마타네!
	string_key = 'nightmare_nightmare_5_otaku_7'
	speech_bubble_util.show_speech_bubble_async(otaku, { key = string_key, skip = true })

	-- 후후… ‘앤과 비밀의 방’ 리액션 영상으로 FB스타가 된다라… 오레의 취향, 역시 메이저였던 거라능!
	otaku.Interactable.Talk = 'nightmare_nightmare_5_otaku_8'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
