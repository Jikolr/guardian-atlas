local local_class = newclass('GoldDiggerController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_alice = function() return get_character('alice') end
	self.get_producer = function() return get_character('producer') end

	self.back_flip_zone_name = 'back_flip_point'

	self.door_name = 'club_door'

	self.get_alice_position_marker = function() return field:GetMarker('alice_position').position end
	self.get_back_flip_marker = function() return field:GetMarker('back_flip').position end

	self.is_event_clear = false
	self.is_cheating_her = false
	self.is_control_her = false
	self.is_back_flip_ready = false
end

function local_class:load_resource()
	local door = get_field_object(self.door_name)
	self.is_event_clear = door.FieldObjectBehaviour.IsOpen

	if not self.is_event_clear then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

		local alice = self:get_alice()
		alice.Interactable:AddListener(self.cs_controller)
		character_util.spine_rotate(alice, -30, 0)
	else
		local alice = self:get_alice()
		character_util.set_active_state(alice, 'disabled')
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	if not self.is_event_clear then
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

		local alice = self:get_alice()
		alice.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local alice = self:get_alice()

	if lua_helper.reference_equals(e.Target, alice) then
		if not self.is_control_her then
			sp_util.play_normal_screenplay(self.interact_gold_digger, self)
			return true
		else
			sp_util.play_normal_screenplay(self.control_her, self)
			return true
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local alice = self:get_alice()

	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, alice) then
		if e.Zone.Name == self.back_flip_zone_name then
			self.is_back_flip_ready = true
			return true
		end
	end
	return false
end

function local_class:on_zone_leave_event(e)
	local alice = self:get_alice()

	if lua_helper.reference_equals(e.FieldObject, alice) then
		if e.Zone.Name == self.back_flip_zone_name then
			self.is_back_flip_ready = false
			return true
		end
	end

	return false
end

-- 말 걸었을 때
function local_class:interact_gold_digger()
	local alice = self:get_alice()

	party_util.align_to_target(self:get_alice_position_marker() + vector(-0.5, 0, 0), 'left', 1, 'arc')

	if not self.is_cheating_her then
		-- 히익!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.spine_rotate(alice, 0, 0)
		character_util.normal_jump(alice, true)
		character_util.set_emotion(alice, { name = 'surprise' })
		character_util.set_anim(alice, { name = 'embarrassed' })
		speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_1', skip = true })

		character_util.remove_anim(alice)
		character_util.move_waypoint_async(alice, self:get_alice_position_marker(), 4, false, nil, nil, nil)

		-- 까, 깜짝 놀랐잖아..
		character_util.look_at(alice, user_party_leader)
		character_util.remove_emotion(alice)
		speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_2', skip = true })

		-- 여기 오면 잘 나가는 프로듀서나 캐스팅 디렉터랑 만날 수 있다고 해서 숨어들어왔는데..
		character_util.set_emotion(alice, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_3', skip = true })

		-- 잘 나가는 사람 하나 물어서 데뷔하고 말거야!
		music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
		character_util.set_emotion(alice, { name = 'burning' })
		speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_4', skip = true })

		local choose_result = choose_util.play_choose_event({ { 'movie_sub_gold_digger_5_1', 'brutal' }, { 'movie_sub_gold_digger_5_2', 'mercy' } })

		if choose_result == 1 then
			-- 에헴.
			-- 서, 설마…?!
			character_util.set_emotion(alice, { name = 'surprise' })
			character_util.remove_anim(alice)
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_9', skip = true })

			-- 당신 프로듀서..?
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_10', skip = true })
		else
			-- 이런 방법은 좋지 않아.
			-- 누가 그걸 몰라?!
			music_player:PlaySfxOneShot('03_dialogue_negative_02')
			character_util.set_emotion(alice, { name = 'attack' })
			character_util.remove_anim(alice)
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_6', skip = true })

			-- 베리우드에서 웨이트리스만 3 년이야.
			character_util.set_anim(alice, { name = 'release', sfx_name = '01_swing_01' })
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_7', skip = true })

			-- 이제 수단 방법 가리지 않을거야.
			character_util.remove_anim(alice)
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_8', skip = true })

			character_util.remove_emotion(alice)
			character_util.move_waypoint_async(alice, vector(-28.7, 0, 145.49), 4, false, nil, nil, 'down')
			character_util.spine_rotate(alice, -30, 0.1)
			return
		end

		choose_result = choose_util.play_choose_event({ { 'movie_sub_gold_digger_10_1', 'brutal' }, { 'movie_sub_gold_digger_10_2', 'mercy' } })

		if choose_result == 1 then
			-- …..
			self.is_cheating_her = true
		else
			-- 오해야
			-- 헷갈리게 하지마!
			character_util.set_emotion(alice, { name = 'attack' })
			character_util.set_anim(alice, { name = 'release', sfx_name = '01_swing_01' })
			speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_11', skip = true })

			character_util.remove_emotion(alice)
			character_util.remove_anim(alice)
			character_util.move_waypoint_async(alice, vector(-28.7, 0, 145.49), 4, false, nil, nil, 'down')
			character_util.spine_rotate(alice, -30, 0.1)
			return
		end
	end

	character_util.remove_anim(alice)
	character_util.move_waypoint_async(alice, alice.Position + vector(-0.5, 0, 0), 4, false, nil, nil, nil)

	-- (주인공에게 달라붙어서) 저, 저 뭐든지 할 수 있어요..!
	music_player:PlaySfxOneShot('01_bad_fairy_01')
	character_util.set_emotion(alice, { name = 'awesome' })
	character_util.set_anim(alice, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_12', skip = true })

	-- 뭐라도 좋으니까...배역 하나만..
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_13', skip = true })

	-- 뭐든지?
	choose_util.play_choose_event({ { 'movie_sub_gold_digger_13_1' } })

	-- (슬픈 표정 지으며 뒷걸음질)
	character_util.set_emotion(alice, { name = 'surprise' })
	character_util.remove_anim(alice)
	wait_for_sec(0.5)

	alice.LockedDirection = alice.Direction
	character_util.move_waypoint_async(alice, alice.Position + vector(0.5, 0, 0), 0.5, false, nil, nil, 'left')

	character_util.shake(alice, 0.02, 2)
	wait_for_sec(2)

	character_util.set_locked_dir(alice, 'none')
	character_util.set_emotion(alice, { name = 'tired' })
	wait_for_sec(1)

	character_util.set_anim(alice, { name = 'nod' })
	wait_for_sec(0.9)

	-- (끄덕끄덕) ...네. 뭐든지요.
	character_util.remove_anim(alice)
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_14', skip = true })

	choose_result = choose_util.play_choose_event({ { 'movie_sub_gold_digger_14_1', 'brutal' }, { 'movie_sub_gold_digger_14_2', 'mercy' } })

	if choose_result == 1 then
		-- 그녀를 이용한다 (Exploit her).
		-- (주인공 doyagao + 끄덕끄덕)
		character_util.set_emotion(user_party_leader, { name = 'doyagao' })
		character_util.set_anim(user_party_leader, { name = 'nod' })
		wait_for_sec(0.9)

		character_util.remove_emotion(user_party_leader)
		character_util.remove_anim(user_party_leader)
		character_util.remove_emotion(alice)

		self.is_control_her = true

		yield_return_func(self.control_her, self)
	else
		-- 이런건 옳지 않아.
		-- 선생님 제발 저 좀 살려주세요!
		music_player:PlaySfxOneShot('03_dialogue_sadness_01')
		character_util.set_emotion(alice, { name = 'tired' })
		character_util.set_anim(alice, { name = 'sing' })
		speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_15', skip = true })

		-- (대화 종료 - 이후 말을 걸면 주인공에게 달라붙는 씬부터 다시)
		return
	end
end

function local_class:is_crash_other_object(field_objects)
	for i = 1, field_objects.Count - 1 do
		local fo = field_objects[i]
		local is_party = false

		for j = 0, user_party.Count - 1 do
			local party = user_party[j]

			if lua_helper.reference_equals(fo, party) then
				is_party = true
			end
		end

		if not is_party then
			return true
		end
	end

	return false
end

-- 여자를 조종한다.
function local_class:control_her()
	local alice = self:get_alice()
	local hitbox = alice.Hitbox

	-- 적절한 위치로 이동
	local alice_position_marker = self:get_alice_position_marker()
	party_util.align_to_target(alice_position_marker, 'up', 1, 'arc')
	camera_util.move(alice.Position, 1, { end_target = alice })

	-- 앞으로! 하면서 셋업
	choose_util.play_choose_event({ { 'movie_sub_gold_digger_27_1' } })

	-- 네!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_emotion(alice, { name = 'attack' })
	speech_bubble_util.show_speech_bubble(alice, { key = 'movie_sub_gold_digger_27', skip = true, bubble_type = 'shout' })
	character_util.move_waypoint_async(alice, vector(-31, 0, 146), 4, false, nil, nil, nil)
	character_util.remove_emotion(alice)

	-- 방향 리스트
	local direction_index = 1
	local direction_list = { vector(-3, 0, 0), vector(0, 0, 3), vector(3, 0, 0), vector(0, 0, -3) }

	-- NPC의 히트박스를 이동 충돌체크를 위한 크기로 만든다.
	local move_hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(0.55, 0.75, 0.45))
	alice.Hitbox = move_hitbox

	while true do
		local choose_result = -1
		local branch_datas = {
			{ 'movie_sub_gold_digger_command_1', 'normal', function() choose_result = 1 end },
			{ 'movie_sub_gold_digger_command_2', 'forced', function() choose_result = 2 end },
			{ 'movie_sub_gold_digger_command_3', 'intellect', function() choose_result = 3 end },
			{ 'movie_sub_gold_digger_command_4', 'brutal', function() choose_result = 4 end  },
			{ 'movie_sub_gold_digger_command_5', 'mercy', function() choose_result = 5 end  } }

		-- 전진할 수 없거나, 백플립이 안되는 장소에서는 선택지가 뜨지 않는다.
		-- 앞으로 이동하지 못할 경우, '앞으로 전진!' 선택지는 제외한다.
		local field_objects = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(alice.Bounds, direction_list[direction_index])

		if self:is_crash_other_object(field_objects) then
			table.remove(branch_datas, 3)
		end

		field_objects:Dispose()

		-- 백플립으로 이동하지 못할 경우, '백플립!' 선택지는 제외한다.
		-- 이외에도 통상적인 백플립으로는 이동할 수 없지만, 이벤트 연출로서 스위치를 밟을 수 있는 존에 들어와 있는 경우에도 활성화 시킨다.
		local reverse_direction_index = self:get_reverse_direction_index(direction_index)
		field_objects = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(alice.Bounds, direction_list[reverse_direction_index])

		if self:is_crash_other_object(field_objects) and not (self.is_back_flip_ready and alice.Direction == CS.Oak.Direction.Right) then
			table.remove(branch_datas, #branch_datas - 1)
		end

		field_objects:Dispose()

		choose_util.play_choose_event(branch_datas)

		-- "이제 그만 됐어." 는 따라 말하지 않게.
		if choose_result ~= 5 then
			-- 네!
			character_util.set_emotion(alice, { name = 'attack' })
			speech_bubble_util.show_speech_bubble(alice, { key = 'movie_sub_gold_digger_command_' .. choose_result, skip = true, bubble_type = 'shout' })
		end

		if choose_result == 1 then
			-- 좌향좌!
			direction_index = self:sub_direction_index(direction_index)
			local direction = vector_util.to_direction(direction_list[direction_index])
			music_player:PlaySfxOneShot('03_dialogue_negative_01')
			character_util.set_direction(alice, direction)
		elseif choose_result == 2 then
			-- 우향우!
			direction_index = self:add_direction_index(direction_index)
			local direction = vector_util.to_direction(direction_list[direction_index])
			music_player:PlaySfxOneShot('03_dialogue_negative_01')
			character_util.set_direction(alice, direction)
		elseif choose_result == 3 then
			-- 앞으로 전진!
			music_player:PlaySfxOneShot('03_dialogue_negative_01')
			character_util.move_waypoint_async(alice, alice.Position + direction_list[direction_index], 4, false, nil, nil, nil)
		elseif choose_result == 4 then
			-- 백플립!
			if self.is_back_flip_ready and alice.Direction == CS.Oak.Direction.Right then
				yield_return_func(self.back_flip, self)
				return
			else
				local rotate_angle = 720

				-- 방향 따라서, 회전 방향도 다르게
				if alice.Direction == CS.Oak.Direction.Left or alice.Direction == CS.Oak.Direction.Down then
					rotate_angle = -rotate_angle
				end

				music_player:PlaySfxOneShot('01_player_jump_01')
				alice.LockedDirection = alice.Direction
				character_util.spine_rotate(alice, rotate_angle, 0.5)
				character_util.jump(alice, 1.5, 0.5)
				character_util.move_to_async(alice, alice.Position + direction_list[reverse_direction_index], 0.5, nil, false, false)
				character_util.spine_rotate(alice, 0, 0)
				character_util.set_locked_dir(alice, 'none')
			end
		else
			-- 이제 그만 됐어.
			break
		end

		character_util.remove_emotion(alice)
	end

	-- 원래 히트박스 크기로 복구
	alice.Hitbox = hitbox
	screen_util.fade_out_async(1, unity_class.color.black)

	alice.Position = alice_position_marker
	party_util.position_party(alice_position_marker + vector(-1.5, 0, 0), 'right', 'arc')
	character_util.look_at(alice, user_party_leader)
	camera_util.move(user_party_leader.Position, 0, { end_target = user_party_leader })

	screen_util.fade_in_async(1, unity_class.color.black)

	-- 선생님! 또 뭘 하면 될까요?!
	character_util.set_emotion(alice, { name = 'attack' })
	character_util.set_anim(alice, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_16', skip = true })

	character_util.remove_anim(alice)
	character_util.remove_emotion(alice)
end

-- 백플립 성공 / 스위치를 눌러서 문을 열었다.
function local_class:back_flip()
	local alice = self:get_alice()
	local producer = self:get_producer()
	local back_flip_marker = self:get_back_flip_marker()

	-- 백플립
	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.set_locked_dir(alice, 'right')
	character_util.spine_rotate(alice, 720, 0.5)
	character_util.jump(alice, 1.5, 0.5)
	character_util.move_to_async(alice, back_flip_marker, 0.5, nil, false, false)

	character_util.set_locked_dir(alice, 'none')
	character_util.set_emotion(alice, { name = 'tired' })
	character_util.set_anim(alice, { name = 'bomb_idle' })

	-- 문열림
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name, false))
	wait_for_sec(2)

	party_util.set_direction('down')

	-- (bomb_idle 포즈로) 헉헉.. 보셨어요?!
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_17', skip = true })

	-- 저 배역을 위해서라면 뭐든…
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_18', skip = true })

	-- (위에서 프로듀서 하나가 나타난다)
	camera_util.move_async(alice.Position + vector(0, 0, 3), 1)
	producer.Position = vector(-35, 1, 148)
	character_util.move_waypoint_async(producer, vector(-35, 1, 146), 4, false, nil, nil, nil)--142

	-- 다, 당신! 방금 그 몸놀림…
	character_util.set_emotion(producer, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(producer, { key = 'movie_sub_gold_digger_19', skip = true })

	character_util.move_waypoint_async(producer, producer.Position + vector(0, 0, -3), 4, false, nil, nil, nil)
	camera_util.move_async(producer.Position, 0.001, { end_target = producer }) -- FIXME: duration을 0으로 줄 경우, 카메라 그리드 밖으로 벗어나서 임시로 0.001초를 준 상태.

	character_util.move_waypoint_async(producer, vector(-35, 1, 140), 4, false, nil, nil, 'right')

	-- 우리가 찾고있던 인재야!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	camera_util.move(producer.Position, 0.001) -- FIXME: duration을 0으로 줄 경우, 카메라 그리드 밖으로 벗어나서 임시로 0.001초를 준 상태.
	character_util.look_at(alice, producer)
	character_util.set_anim(producer, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(producer, { key = 'movie_sub_gold_digger_20', skip = true })

	-- 엑…?
	character_util.remove_anim(producer)
	character_util.remove_anim(alice)
	character_util.set_emotion(alice, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_21', skip = true })

	-- S 스쿼드 라는 영화를 만들려 하는데..
	character_util.remove_emotion(alice)
	speech_bubble_util.show_speech_bubble_async(producer, { key = 'movie_sub_gold_digger_22', skip = true })

	-- 졸리퀸을 맡을 수 있는 배우는 당신밖에 없어!!
	character_util.set_anim(producer, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(producer, { key = 'movie_sub_gold_digger_23', skip = true })

	-- ….
	character_util.remove_anim(producer)
	character_util.set_direction(alice, 'right')
	character_util.remove_emotion(alice)
	character_util.set_anim(alice, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_24', skip = true })

	character_util.look_at(alice, producer)
	character_util.set_anim(alice, { name = 'nod' })
	wait_for_sec(0.9)

	character_util.remove_emotion(producer)
	character_util.remove_anim(alice)

	wait_all({
		util.cs_generator(character_util.move_waypoint_async, alice, alice.Position + vector(-1, 0, 0), 4, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, producer, producer.Position + vector(0, 0, 1), 4, false, nil, nil, nil)
	})
	camera_util.move_async(alice.Position, 0.001, { end_target = alice }) -- FIXME: duration을 0으로 줄 경우, 카메라 그리드 밖으로 벗어나서 임시로 0.001초를 준 상태.

	-- 프로듀서를 따라가다 멈춤
	wait_all({
		util.cs_generator(character_util.move_waypoint_async, alice, alice.Position + vector(0, 0, 5), 4, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, producer, producer.Position + vector(0, 0, 7), 4, false, nil, nil, 'down')
	})
	camera_util.move(alice.Position, 0.001) -- FIXME: duration을 0으로 줄 경우, 카메라 그리드 밖으로 벗어나서 임시로 0.001초를 준 상태.

	party_util.look_at(alice)
	character_util.look_at(alice, user_party_leader)
	wait_for_sec(1)

	-- (주인공 바라보며 doyagao) 미안해 달링.
	character_util.set_emotion(alice, { name = 'doyagao' })
	character_util.set_anim(alice, { name = 'cross_arm' })
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_25', skip = true })

	-- 이건 그냥 비지니스일 뿐이야.
	speech_bubble_util.show_speech_bubble_async(alice, { key = 'movie_sub_gold_digger_26', skip = true })

	-- (여자, 프로듀서 같이 걸어나간다. 카메라 주인공에게 돌아오며 리셋)
	character_util.remove_anim(alice)
	character_util.move_waypoint_async(alice, alice.Position + vector(0, 0, 2), 4, false, nil, nil, nil)
	wait_all({
		util.cs_generator(character_util.move_waypoint_async, alice, alice.Position + vector(0, 0, 5), 4, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, producer, producer.Position + vector(0, 0, 5), 4, false, nil, nil, nil)
	})

	character_util.set_active_state(alice, 'disabled')
	character_util.set_active_state(producer, 'disabled')
	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })
end

function local_class:add_direction_index(index)
	local result = (index % 4) + 1

	return result
end

function local_class:sub_direction_index(index)
	local result = index - 1

	if result < 1 then
		result = 4
	end

	return result
end

function local_class:get_reverse_direction_index(index)
	index = self:add_direction_index(index)
	index = self:add_direction_index(index)

	return index
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}