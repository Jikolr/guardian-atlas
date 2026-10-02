local local_class = newclass('Movie1At4Controller')

function local_class:init(cs_controller)
    self.cs_controller = cs_controller

	-- 얼음 박스 리스트
	self.ice_block_list = nil

	-- 얼음 박스 옆의 스태프 리스트
	self.ice_staff_list = nil

	--조명 리스트
	self.spotlight_list = nil

	-- 조명 옆의 스태프 리스트
	self.spotlight_staff_list = nil

	-- 스타피스
	self.spotlight_star_piece = nil

	-- 조명이 가운데 얼음을 비출 때의 각도 y좌표 리스트
	self.spotlight_correct_angle_list = create_generic_list(CS.System.Int32)
	self.spotlight_correct_angle_list:Add(0)
	self.spotlight_correct_angle_list:Add(270)
	self.spotlight_correct_angle_list:Add(180)
	self.spotlight_correct_angle_list:Add(90)

	-- 얼음이 녹았는지 저장
	self.is_melted = false

	self.in_battle_1 = false

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.ice_block_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, 4 do
		self.ice_block_list:Add(get_field_object('ice_block_'..i))
	end

	self.ice_staff_list = create_generic_list(CS.Oak.Character)
	for i = 1, 2 do
		local cur_staff = get_character('ice_staff_'..i)
		cur_staff.Interactable:AddListener(self.cs_controller)

		self.ice_staff_list:Add(cur_staff)
	end

	self.spotlight_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, 4 do
		self.spotlight_list:Add(get_field_object('spotlight_'..i))
	end

	self.spotlight_staff_list = create_generic_list(CS.Oak.Character)
	for i = 1, 4 do
		local cur_staff = get_character('spotlight_staff_'..i)
		cur_staff.Interactable:AddListener(self.cs_controller)

		self.spotlight_staff_list:Add(cur_staff)
	end

	self.spotlight_star_piece = get_field_object('spotlight_star_piece')

	-- 스타피스 먹었을 경우 설정
	if stage_progress:HasStarPiece('spotlight_star_piece') then
		self.is_melted = true
	end

	if self.is_melted then
		for i = 0, self.ice_block_list.Count - 1 do
			self.ice_block_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end

		for i = 0, self.ice_staff_list.Count - 1 do
			character_util.set_direction(self.ice_staff_list[i], 'down')
			character_util.set_anim(self.ice_staff_list[i],{ name = 'embarrassed' })
			character_util.set_emotion(self.ice_staff_list[i],{ name = 'scared' })
		end
	end

	-- 인베이더 대기실 스태프/배우
	self.waiting_room_staff_1 = get_character('waiting_room_staff_1')
	-- 뿔을 1센티만 더 다듬어 보자!
	self.waiting_room_staff_1.Interactable.Talk = 'movie_s12_23'
	self.waiting_room_staff_2 = get_character('waiting_room_staff_2')
	-- 몸에 좋다는 해독주스입니다~
	self.waiting_room_staff_2.Interactable.Talk = 'movie_s12_24'
	self.waiting_room_staff_3 = get_character('waiting_room_staff_3')
	-- 스스로를 믿고 몸을 던져봐!
	self.waiting_room_staff_3.Interactable.Talk = 'movie_s12_25'
	self.waiting_room_actor_1 = get_character('waiting_room_actor_1')
	-- 흠… 그럴까?
	self.waiting_room_actor_1.Interactable.Talk = 'movie_s12_26'
	self.waiting_room_actor_2 = get_character('waiting_room_actor_2')
	-- 오~ 역시! 사회생활 참 잘해.
	self.waiting_room_actor_2.Interactable.Talk = 'movie_s12_27'
	self.waiting_room_actor_3 = get_character('waiting_room_actor_3')
	-- 하아… 자신이 없어…
	self.waiting_room_actor_3.Interactable.Talk = 'movie_s12_28'

	return
end

function local_class:need_on_launch()
	--return false
	return user_progress:GetStartedQuest(60005).InnerProgress < 12
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil

	self.ice_block_list = nil
	self.ice_staff_list = nil
end

function local_class:on_event(e)
	local quest_progress = user_progress:GetStartedQuest(60005)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		for i = 0, self.ice_staff_list.Count - 1 do
			if lua_helper.reference_equals(e.Target, self.ice_staff_list[i]) then
				if self.is_melted then
					speech_bubble_util.show_speech_bubble(
							self.ice_staff_list[i], { key = 'movie_1_4_ice_staff_end', skip = false })
				else
					if i == 0 then
						speech_bubble_util.show_speech_bubble(
								self.ice_staff_list[i], { key = 'movie_1_4_ice_staff_1', skip = false })
					else
						speech_bubble_util.show_speech_bubble(
								self.ice_staff_list[i], { key = 'movie_1_4_ice_staff_2', skip = false })
					end
				end

				break
			end
		end

		for i = 0, self.spotlight_staff_list.Count - 1 do
			if lua_helper.reference_equals(e.Target, self.spotlight_staff_list[i]) then
				coroutine_manager:StartCoroutine(
						stage.StageGameObject,
						util.cs_generator(self.talk_with_spolight_staff, self, i))
				break
			end
		end

	end

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		local zone_name = e.Zone.Name

		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return false end

		if quest_progress ~= nil and quest_progress.InnerProgress < 13 then
			if zone_name == 'battle_1' and not self.in_battle_1 then
				self.in_battle_1 = true
				sp_util.play_normal_screenplay(self.battle_1_scene, self)
				return true
			end
		end
	end

	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		-- 13섹션 이상이면 적으로 변경 변경
		if quest_progress ~= nil and quest_progress.InnerProgress > 12 then
			for i = 1, 5 do
				local enemy = get_character('battle_1_' .. i)
				character_util.convert_to_monster(enemy, 'battle_1', 'battle_1')
			end
		end
		return true
	end

	return false
end

-- 조명 스태프와 대화하여 조명을 회전시키는 이벤트
function local_class:talk_with_spolight_staff(index)
	local talker = self.spotlight_staff_list[index]
	local spotlight = self.spotlight_list[index]

	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	party_util.align_party(talker.Position, talker.Direction,
			((user_party.Leader.Position - talker.Position).magnitude) / 3, 'arc')

	speech_bubble_util.show_speech_bubble_async(talker, { key = 'movie_1_4_spotlight_staff', skip = true })

	local origin_dir = talker.Direction

	character_util.look_at(talker, spotlight)
	character_util.set_anim(talker, { name = 'push' })

	local cur_time = unity_class.time.time
	local rotate_time = 1

	local origin_rotate = math.floor(spotlight.Transform.localRotation.eulerAngles.y)
	local rotate_diff = 90

	music_player:PlaySfxOneShot('01_push_rock_unit_02')

	while unity_class.time.time - cur_time < rotate_time do
		local normalized = (unity_class.time.time - cur_time) / rotate_time

		spotlight.Transform.localRotation = unity_class.quaternion.Euler(0, origin_rotate + rotate_diff * normalized, 0)

		coroutine.yield(nil)
	end

	if math.floor(origin_rotate + rotate_diff) < 360 then
		spotlight.Transform.localRotation = unity_class.quaternion.Euler(0, math.floor(origin_rotate + rotate_diff), 0)
	else
		spotlight.Transform.localRotation = unity_class.quaternion.Euler(0, math.floor(origin_rotate + rotate_diff - 360), 0)
	end

	if not self.is_melted then
		local correct = true

		for i = 0, self.spotlight_list.Count - 1 do
			if math.floor(self.spotlight_list[i].Transform.localRotation.eulerAngles.y) ~=
					self.spotlight_correct_angle_list[i] then
				correct = false

				break
			end
		end

		if correct then
			camera_util.resize_to(4.5, 1)
			camera_util.move_async(vector(0.5, 0, 50.5), 1)

			for i = 0, self.ice_staff_list.Count - 1 do
				character_util.set_direction(self.ice_staff_list[i], 'down')
				character_util.set_anim(self.ice_staff_list[i],{ name = 'embarrassed' })
				character_util.set_emotion(self.ice_staff_list[i],{ name = 'scared' })
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.melt_ice_block, self))

			music_player:PlaySfxOneShot('03_runaway_01')

			speech_bubble_util.show_speech_bubble_async(
					self.ice_staff_list[0], { key = 'movie_1_4_ice_staff_surprised', skip = true })

			camera_util.resize_to_default(1)
			camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })
		end
	end

	character_util.set_direction(talker, origin_dir)
	character_util.remove_anim(talker)

	user_party:ResetControllers()
	field_ui_manager:Show()
end

-- 얼음 블록이 녹아서 스타피스가 나오는 이벤트
function local_class:melt_ice_block()
	self.is_melted = true

	for i = 0, self.ice_block_list.Count - 1 do
		command_util.execute_burn(self.spotlight_list[i], self.ice_block_list[i], false)
	end

	wait_for_sec(1.5)

	message_system:Send(self.spotlight_star_piece, CS.Oak.StarPieceAppearEvent.Create(self.spotlight_star_piece.Position))

	wait_for_sec(0.5)
end

-- 13섹션에서만 나오는 연출
function local_class:battle_1_scene()
	local leader = user_party.Leader
	local battle_1_enemies = {}
	for i = 1, 5 do
		local enemy = get_character('battle_1_' .. i)
		table.insert(battle_1_enemies, enemy)
	end

	camera_util.move(battle_1_enemies[2].Position + unity_class.vector3.back, 1)
	character_util.move_to_async(leader, battle_1_enemies[2].Position + 4 * unity_class.vector3.back,
		1, nil, true, true)

	-- 인간 주제에 무슨 낯짝으로 여길 기어들어와?!
	music_player_util.play_sfx({ sfx_name = '02_die_hulk_01', type_priority = 'event', player_priority = 'npc' })

	speech_bubble_util.show_speech_bubble_async(battle_1_enemies[2], {key = 'movie_s12_20', skip = true})

	-- 주제를 알아야지!
	speech_bubble_util.show_speech_bubble_async(battle_1_enemies[1], {key = 'movie_s12_21', skip = true})

	camera_util.move_async(leader.Position, 1, { end_target = leader })

	for _, v in pairs(battle_1_enemies) do
		character_util.convert_to_monster(v, 'battle_1', 'battle_1')
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}