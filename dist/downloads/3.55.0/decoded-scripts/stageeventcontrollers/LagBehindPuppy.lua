local local_class = newclass('LagBehindPuppyController')

local EventProgress = {
	need_help_1 = 0,
	move_to_help_2 = 1,
	need_help_2 = 2,
	move_to_goal = 3,
	wait_to_come_goal = 4,
	event_end = 5
}

function local_class:init(cs_controller)
	self.dog_name = 'dog'
	self.puppy_name = 'puppy_'
	self.animal_lovers_name = 'animal_lovers_'

	self.help_zone_name = 'lag_behind_puppy_help_'

	self.star_piece_name = 'lag_behind_puppy_star_piece'
	self.get_star_piece = function() return get_field_object(self.star_piece_name) end

	self.event_progress = EventProgress.need_help_1

	self.is_first_entry = true
	self.is_puppy_in_the_help_zone = false
	self.is_user_in_the_help_zone = false
	self.is_event_clear = false

	self.help_puppy_1_coroutine = nil

	self.move_speed = 3

	self.cs_controller = cs_controller
end

function local_class:load_resource()
	self.is_event_clear = stage_progress:HasStarPiece(self.star_piece_name)

	if not self.is_event_clear then
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

		local puppy_3 = get_character(self.puppy_name .. 3)
		puppy_3.Holdable = CS.Oak.Holdable()
		character_util.set_emotion(puppy_3, { name = 'scared' })

		for i = 1, 3 do
			local puppy = get_character(self.puppy_name .. i)
			puppy:SetGiantFactor('puppy_' .. i, 0.7)
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wait_puppy, self))
	else
		local dog = get_character(self.dog_name)
		character_util.set_active_state(dog, 'disabled')

		for i = 1, 3 do
			local puppy = get_character(self.puppy_name .. i)
			character_util.set_active_state(puppy, 'disabled')
		end
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	if not self.is_event_clear then
		message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	end

	self.help_puppy_1_coroutine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		return self:on_damage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	end

	return false
end

function local_class:on_damage_event(e)
	if self.event_progress == EventProgress.need_help_1 then
		-- 강아지가 단차에서 내려오지 못할 때
		local puppy_3 = get_character(self.puppy_name .. 3)

		if self.is_puppy_in_the_help_zone and lua_helper.reference_equals(e.Info.target, puppy_3) then
			self.help_puppy_1_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.help_puppy_1, self))
			return true
		end
	elseif self.event_progress == EventProgress.need_help_2 then
		-- 강아지가 동물 애호가에게 붙잡혔을 때
		local animal_lovers_1 = get_character(self.animal_lovers_name .. 1)
		local animal_lovers_2 = get_character(self.animal_lovers_name .. 2)

		if lua_helper.reference_equals(e.Info.target, animal_lovers_1) or lua_helper.reference_equals(e.Info.target, animal_lovers_2) then
			if self.help_puppy_1_coroutine ~= nil then
				stop_coroutine(self.help_puppy_1_coroutine)
				self.help_puppy_1_coroutine = nil
			end
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.help_puppy_2, self, e.Info.target))
			return true
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.event_progress == EventProgress.need_help_1 then
		-- 강아지가 단차에서 내려오지 못할 때
		if e.FullEnter and e.Zone.Name == self.help_zone_name .. 1 then
			local puppy_3 = get_character(self.puppy_name .. 3)

			if lua_helper.reference_equals(e.FieldObject, puppy_3) then
				self.is_puppy_in_the_help_zone = true
				return true
			elseif self.is_first_entry and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				-- 플레이어가 첫 진입시 sfx 재생
				self.is_first_entry = false
				music_player:PlaySfxOneShot('01_guild_dog_01')
			end
		end
	elseif self.event_progress >= EventProgress.move_to_goal then
		-- 강아지가 바위 앞에서 플레이어를 기다릴 때
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == self.help_zone_name .. 2 then
				self.is_user_in_the_help_zone = true
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.event_progress == EventProgress.need_help_1 then
		-- 강아지가 단차에서 내려오지 못할 때
		local puppy_3 = get_character(self.puppy_name .. 3)

		if e.FullLeave and lua_helper.reference_equals(e.FieldObject, puppy_3) then
			if e.Zone.Name == self.help_zone_name .. 1 then
				self.is_puppy_in_the_help_zone = false
				return true
			end
		end
	elseif self.event_progress >= EventProgress.move_to_goal then
		-- 강아지가 바위 앞에서 플레이어를 기다릴 때
		if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == self.help_zone_name .. 2 then
				self.is_user_in_the_help_zone = false
				return true
			end
		end
	end

	return false
end

-- 연출
-- 강아지3 이 아래로 내려오길 기다리는 동안, 강아지1~2가 어미 주변을 맴도는 연출
function local_class:wait_puppy()
	local dog_position = get_character(self.dog_name).Position
	local puppy_1 = get_character(self.puppy_name .. 1)
	local puppy_2 = get_character(self.puppy_name .. 2)
	local position_list = { dog_position + vector(-1, 0, 1), dog_position + vector(1, 0, 1), dog_position + vector(1, 0, -1), dog_position + vector(-1, 0, -1) }

	puppy_1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	puppy_2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	character_util.move_waypoint(puppy_1, position_list, 4, nil, 'loop', nil, nil)

	for i = 1, 2 do
		local next_index = ((i + 1) % 4) + 1
		position_list[i], position_list[next_index] = position_list[next_index], position_list[i]
	end

	character_util.move_waypoint(puppy_2, position_list, 4, nil, 'loop', nil, nil)
end

-- 강아지 구해주기 1 / 2층 단차 위에 있는 강아지를 아래로 던져준 이후
function local_class:help_puppy_1()
	local dog = get_character(self.dog_name)
	local puppy_1 = get_character(self.puppy_name .. 1)
	local puppy_2 = get_character(self.puppy_name .. 2)
	local puppy_3 = get_character(self.puppy_name .. 3)

	-- 1층(y == 0)이 아닐 경우, 진행하지 않음.
	if puppy_3.Position.y >= 0.1 then
		return
	end

	self.event_progress = EventProgress.move_to_help_2

	-- 들지 못하게 / 부딪히지 않게
	self:set_dog_and_puppies_crash('ethereal')
	puppy_3.Holdable = CS.Oak.NonHoldable.Instance

	wait_for_sec(1)

	character_util.stop(puppy_1)
	character_util.stop(puppy_2)

	-- 어미가 있는 무리로 돌아감.
	music_player_util.play_sfx({ sfx_name = '01_pet_ordinary_01', parent = dog, type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_wolves_running_01', parent = dog, type_priority = 'event', player_priority = 'npc' })
	character_util.remove_emotion(puppy_3)
	character_util.set_direction(dog, 'right')
	wait_all({
		util.cs_generator(character_util.move_waypoint_async, puppy_1, vector(72, 0, 31), self.move_speed, false, nil, nil, 'right'),
		util.cs_generator(character_util.move_waypoint_async, puppy_2, vector(71, 0, 31), self.move_speed, false, nil, nil, 'right'),
		util.cs_generator(character_util.move_waypoint_async, puppy_3, { vector(73, 0, 31), vector(70, 0, 31) }, self.move_speed, false, nil, nil, 'right')
	})

	-- 출발
	music_player_util.play_sfx({ sfx_name = '01_pet_bark_01', parent = dog, type_priority = 'event', player_priority = 'npc' })
	wait_all({
		util.cs_generator(character_util.move_waypoint_async, dog, { vector(74, 0, 31), vector(74, 0, 17), vector(71, 0, 17), vector(71, 0, -1), vector(66, 0, -1) }, self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_1, { vector(74, 0, 31), vector(74, 0, 17), vector(71, 0, 17), vector(71, 0, -1), vector(67, 0, -1) }, self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_2, { vector(74, 0, 31), vector(74, 0, 17), vector(71, 0, 17), vector(71, 0, -1), vector(68, 0, -1) }, self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_3, { vector(74, 0, 31), vector(74, 0, 17), vector(71, 0, 17), vector(71, 0, -1), vector(69, 0, -1) }, self.move_speed, false, nil, nil, nil)
	})
	puppy_3.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance;

	-- 3번째 강아지 남기고, 어미 뒤로 이동
	character_util.set_direction(dog, 'right')
	character_util.move_waypoint(dog, vector(64, 0, -1), self.move_speed, false, nil, nil, 'right')
	character_util.move_waypoint(puppy_1, { vector(64, 0, -1), vector(64, 0, 0) }, self.move_speed, false, nil, nil, 'right')
	character_util.move_waypoint(puppy_2, { vector(64, 0, -1), vector(64, 0, -2) }, self.move_speed, false, nil, nil, 'right')
	character_util.move_waypoint_async(puppy_3, vector(68.5, 0, -1), self.move_speed, false, nil, nil, nil)

	local animal_lovers_1 = get_character(self.animal_lovers_name .. 1)
	local animal_lovers_2 = get_character(self.animal_lovers_name .. 2)

	self.event_progress = EventProgress.need_help_2

	-- 이거봐! 강아지야!
	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', parent = animal_lovers_1, type_priority = 'event', player_priority = 'npc' })
	character_util.normal_jump(animal_lovers_1)
	character_util.set_emotion(animal_lovers_1, { name = 'greed' })
	character_util.set_anim(animal_lovers_1, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(animal_lovers_1, { key = 'lag_behind_puppy_1' })

	character_util.remove_anim(animal_lovers_1)
	character_util.move_waypoint_async(animal_lovers_2, animal_lovers_2.Position + vector(0, 0, -0.5), 4, false, nil, nil, nil)

	-- 조그맣고 귀엽다...
	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', parent = animal_lovers_2, type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(animal_lovers_2, { name = 'smile' })
	character_util.set_anim(animal_lovers_2, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(animal_lovers_2, { key = 'lag_behind_puppy_2' })

	character_util.move_waypoint_async(animal_lovers_1, animal_lovers_1.Position + vector(0, 0, -0.5), 4, false, nil, nil, nil)

	-- 내가 동물 애호가거든! 봐봐, 이렇게 쓰다듬어주면 좋아한다고 들었어.
	character_util.set_emotion(animal_lovers_1, { name = 'doyagao' })
	character_util.set_anim(animal_lovers_1, { name = 'cast' })
	character_util.set_emotion(puppy_3, { name = 'scared' })
	character_util.set_anim(puppy_3, { name = 'hurt' })
	speech_bubble_util.show_speech_bubble_async(animal_lovers_1, { key = 'lag_behind_puppy_3' })

	-- 끼잉...
	speech_bubble_util.show_speech_bubble_async(puppy_3, { key = 'lag_behind_puppy_4' })

	animal_lovers_1.Interactable.Talk = 'lag_behind_puppy_3'
	animal_lovers_2.Interactable.Talk = 'lag_behind_puppy_2'

	self.help_puppy_1_coroutine = nil
end

-- 동물 애호가에게 쓰레기통을 던져서 개를 구해준 이후
function local_class:help_puppy_2(damaged_target)
	local dog = get_character(self.dog_name)
	local puppy_1 = get_character(self.puppy_name .. 1)
	local puppy_2 = get_character(self.puppy_name .. 2)
	local puppy_3 = get_character(self.puppy_name .. 3)

	self.event_progress = EventProgress.move_to_goal

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_animal_lovers, self, damaged_target))

	-- 무리와 합류
	self:set_dog_and_puppies_crash('ethereal')
	character_util.remove_emotion(puppy_3)
	character_util.remove_anim(puppy_3)
	character_util.move_waypoint_async(puppy_3, vector(65, 0, -1), self.move_speed, false, nil, nil, 'right')

	wait_for_sec(2)

	-- 출발
	character_util.move_waypoint(dog, vector(62, 0, -1), self.move_speed, false, nil, nil, nil)
	character_util.move_waypoint_async(puppy_1, vector(64, 0, -1), self.move_speed, false, nil, nil, nil)

	character_util.move_waypoint(puppy_1, vector(63, 0, -1), self.move_speed, false, nil, nil, nil)
	character_util.move_waypoint_async(puppy_2, vector(64, 0, -1), self.move_speed, false, nil, nil, nil)

	wait_all({
		util.cs_generator(character_util.move_waypoint_async, dog, vector(2, 0, -1), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_1, vector(3, 0, -1), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_2, vector(4, 0, -1), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_3, vector(5, 0, -1), self.move_speed, false, nil, nil, nil)
	})

	self.event_progress = EventProgress.wait_to_come_goal

	-- 플레이어가 바위 앞으로 올떄까지 기다린다.
	while not self.is_user_in_the_help_zone do
		coroutine.yield(nil)
	end

	-- 바위앞
	-- 어미부터 한마리씩 땅을 파고 바위 건너편으로 넘어간다.
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dig_under_rock, self, dog, vector(-3, 0, -1)))
	wait_for_sec(2)

	wait_all({
		util.cs_generator(character_util.move_waypoint_async, puppy_1, puppy_1.Position + vector(-1, 0, 0), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_2, puppy_2.Position + vector(-1, 0, 0), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_3, puppy_3.Position + vector(-1, 0, 0), self.move_speed, false, nil, nil, nil)
	})
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dig_under_rock, self, puppy_1, { vector(-1, 0, -2), vector(-3, 0, -2) }))
	wait_for_sec(2)

	wait_all({
		util.cs_generator(character_util.move_waypoint_async, puppy_2, puppy_2.Position + vector(-1, 0, 0), self.move_speed, false, nil, nil, nil),
		util.cs_generator(character_util.move_waypoint_async, puppy_3, puppy_3.Position + vector(-1, 0, 0), self.move_speed, false, nil, nil, nil)
	})
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dig_under_rock, self, puppy_2, { vector(-1, 0, -3), vector(-3, 0, -3) }))
	wait_for_sec(2)

	character_util.move_waypoint_async(puppy_3, puppy_3.Position + vector(-1, 0, 0), 4, false, nil, nil, nil)

	character_util.set_anim(puppy_3, { name = 'release', scale = 2.5 })
	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_pet_ordinary_01', parent = puppy_3, type_priority = 'event', player_priority = 'npc' })
	character_util.spine_set_alpha_fade(puppy_3, 0, 2)
	character_util.move_waypoint_async(puppy_3, puppy_3.Position + vector(-1.5, -0.5, 0), 1, false, nil, nil, nil)

	wait_for_sec(2)

	character_util.spine_set_alpha_fade(puppy_3, 1, 2)
	character_util.move_waypoint(puppy_3, puppy_3.Position + vector(-1.5, 0.5, 0), 1, false, nil, nil, nil)
	wait_for_sec(1)

	-- 마지막 강아지3이 땅을 파고 바위 건너편으로 나온 타이밍과 동시에, 바위 아래에 숨겨져있던 스타피스가 등장
	local star_piece = self:get_star_piece()
	local throw_position = star_piece.Position
	star_piece.Position = vector(2, 0, -1.5)
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(throw_position))

	character_util.remove_anim(puppy_3)

	self.event_progress = EventProgress.event_end
end

-- 쓰레기통을 동물 애호가에게 던졌을 때의 연출
function local_class:attack_animal_lovers(damaged_target)
	local animal_lovers_1 = get_character(self.animal_lovers_name .. 1)
	local animal_lovers_2 = get_character(self.animal_lovers_name .. 2)
	local non_damaged_target = nil

	-- 쓰레기통을 맞은 쪽과, 맞지 않은 쪽을 구분
	-- 각자에 알맞은 리액션을 취한다.
	if lua_helper.reference_equals(damaged_target, animal_lovers_1) then
		non_damaged_target = animal_lovers_2
	else
		non_damaged_target = animal_lovers_1
	end

	damaged_target.Interactable.Talk = ''
	non_damaged_target.Interactable.Talk = ''

	speech_bubble_util.remove_bubble(damaged_target)
	speech_bubble_util.remove_bubble(non_damaged_target)

	-- 으악!
	character_util.set_emotion(non_damaged_target, { name = 'attack' })
	character_util.remove_anim(non_damaged_target)
	character_util.normal_jump(non_damaged_target, true)
	character_util.look_at(non_damaged_target, damaged_target)
	damaged_target.Direction = vector_util.to_direction(damaged_target.Position - non_damaged_target.Position)
	character_util.set_emotion(damaged_target, { name = 'confused' })
	character_util.set_anim(damaged_target, { name = 'prostrate' })
	speech_bubble_util.show_speech_bubble_async(damaged_target, { key = 'lag_behind_puppy_5' })

	-- 뭐... 뭐야!
	character_util.look_at(non_damaged_target, damaged_target)
	character_util.set_anim(non_damaged_target, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(non_damaged_target, { key = 'lag_behind_puppy_6' })

	character_util.remove_anim(non_damaged_target)

	damaged_target.Interactable.Talk = 'lag_behind_puppy_7'
	non_damaged_target.Interactable.Talk = 'lag_behind_puppy_8'
end

-- 땅을 파고 바위 뒤편으로 넘어가는 연출
function local_class:dig_under_rock(target, move_route)
	character_util.set_anim(target, { name = 'release', scale = 2.5 })
	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_pet_ordinary_01', parent = target, type_priority = 'event', player_priority = 'npc' })
	character_util.spine_set_alpha_fade(target, 0, 2)
	character_util.move_waypoint_async(target, target.Position + vector(-1.5, -0.5, 0), 1, false, nil, nil, nil)

	wait_for_sec(2)

	character_util.spine_set_alpha_fade(target, 1, 2)
	character_util.move_waypoint_async(target, target.Position + vector(-1.5, 0.5, 0), 1, false, nil, nil, nil)

	character_util.remove_anim(target)
	character_util.move_waypoint_async(target, move_route, 1, false, nil, nil, 'right')
end

-- 충돌 타입 설정
function local_class:set_dog_and_puppies_crash(type)
	local crash_behaviour = CS.Oak.NullCrashBehaviour.Instance;

	if type == 'npc' then
		crash_behaviour = CS.Oak.NPCCrashBehaviour.Instance
	elseif type == 'ethereal' then
		crash_behaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	local dog = get_character(self.dog_name)
	dog.CrashBehaviour = crash_behaviour

	for i = 1, 3 do
		local puppy = get_character(self.puppy_name .. i)
		puppy.CrashBehaviour = crash_behaviour
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}