local local_class = newclass("InvaderReporterSoupController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.soup_invader = nil

	self.super_invader = nil

	self.prisoners = nil

	self.soup_cusomters = nil

	-- 수프 이벤트 중복 실행 방지 플래그
	self.see_soup_event = false

	-- 동적으로 로딩한 캐릭터들을 파괴할것인지 여부
	self.experimental_destroy_character = true

	-- 연출용 수프
	self.hold_soup = nil

	-- 연출용 수프 Transform parent 원본
	self.hold_soup_transform_parent = nil

	-- consume 되지 않은 연출용 수프
	self.soup_1 = nil
	self.soup_2 = nil

	-- 사진 촬영 Effect
	self.scoop_effect = nil

	-- 수프 이벤트 state
	self.event_state = {
		-- 수프 없는 상태
		idle = 0,
		-- 수프 받은 상태
		get_soup = 1,
		-- 샛길 지나간 후
		bypass = 2,
		-- 포로들에게 수프 준 상태
		ending = 3
	}

	self.current_event_state = self.event_state.idle

	-- 스테이지 커스텀 State
	self.stage_custom_state = {
		soup = 2
	}

	-- 기타 상수
	self.soup_item_id = 20192

	-- NPC 이름
	self.soup_invader_name = 'soup_invader'

	-- 타일맵 존 이름
	self.soup_event_zone_name = 'soup_'

	-- 커스텀 이벤트 이름
	self.get_photo = 'get_photo3'
	self.give_soup_event = 'give_soup'

	-- 오브젝트 풀 이름
	self.scoop_effect_preset = 'invader_reporter_scoop_target'
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.soup_invader = get_character(self.soup_invader_name)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local scoop_effect_pool = unity_object_pool.GetOrCreate(self.scoop_effect_preset)

	local optimized_npcs_1 = load_util.create_optimized_npcs_async({
		invader_1 = 'demonwarrior',
		invader_2 = 'demonarcher',
		invader_3 = 'demon_hulk',
		invader_4 = 'demon_hulk',
		invader_5 = 'demonarcher',
		invader_6 = 'invader_priestess',
		invader_7 = 'demonwarrior_assassin',
		invader_8 = 'demonwarrior',
		invader_9 = 'demonwarrior_assassin',
		invader_10 = 'demon_hulk',
		invader_11 = 'invader_priestess',
		invader_12 = 'demon_hulk',
	})


	self.soup_cusomters = create_generic_list(CS.Oak.Character)
	for i = 1, 12 do
		self.soup_cusomters:Add(optimized_npcs_1['invader_'..i])
	end

	local row_start = vector(51, 0, -3)

	local curve_index_1 = 3
	local curve_index_2 = 9
	local curve_index_3 = 12

	character_util.set_position(self.soup_invader, row_start)
	character_util.set_direction(self.soup_invader, 'right')

	for i = 0, self.soup_cusomters.Count - 1 do
		if i < curve_index_1 then
			row_start = row_start + vector(0, 0, -1)
			character_util.set_direction(self.soup_cusomters[i], 'up')
		elseif i < curve_index_2 then
			row_start = row_start + vector(1, 0, 0)
			character_util.set_direction(self.soup_cusomters[i], 'left')
		elseif i < curve_index_3 then
			row_start = row_start + vector(0, 0, 1)
			character_util.set_direction(self.soup_cusomters[i], 'down')
		end

		character_util.set_position(self.soup_cusomters[i], row_start)
	end

	local soup_giver = get_character('soup_giver')
	character_util.set_position(soup_giver, self.soup_invader.Position + vector(3, 0, 0))
	character_util.set_direction(soup_giver, 'left')

	local optimized_npcs_2 = load_util.create_optimized_npcs_async({
		prisoner_1 = 'civilian_female',
		prisoner_2 = 'civilian_male'
	})

	self.prisoners = create_generic_list(CS.Oak.Character)
	for i = 1, 2 do
		self.prisoners:Add(optimized_npcs_2['prisoner_'..i])
	end

	character_util.set_position(self.prisoners[0], vector(50.5, 0, 4.5))
	character_util.set_direction(self.prisoners[0], 'down')
	character_util.set_anim(self.prisoners[0], { name = 'cast' })
	character_util.set_emotion(self.prisoners[0], { name = 'tired' })

	character_util.set_position(self.prisoners[1], vector(54.5, 0, 4.5))
	character_util.set_direction(self.prisoners[1], 'down')
	character_util.set_anim(self.prisoners[1], { name = 'cast' })
	character_util.set_emotion(self.prisoners[1], { name = 'tired' })

	-- 이펙트 로드 대기
	while not object_pool_extensions.IsLoaded(scoop_effect_pool) do
		coroutine.yield(nil)
	end

	self.scoop_effect = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(52.5, 0, 4.5))
	self.scoop_effect.transform.gameObject:SetActive(false)
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.soup_cusomters ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.soup_cusomters)
		self.soup_cusomters = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.prisoners ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.prisoners)
		self.prisoners = nil
	end

	if self.scoop_effect ~= nil then
		self.scoop_effect:Dispose()
		self.scoop_effect = nil
	end

	if self.hold_soup ~= nil then
		self.hold_soup:ConsumeComplete()
		self.hold_soup = nil
	end

	self.hold_soup_transform_parent = nil

	if self.soup_1 ~= nil then
		self.soup_1:ConsumeComplete()
		self.soup_1 = nil
	end

	if self.soup_2 ~= nil then
		self.soup_2:ConsumeComplete()
		self.soup_2 = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		if stage_progress:GetCustomData(self.stage_custom_state.soup, false) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_ending, self))
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	-- 캐릭터가 점프대로 날아오는 중이면 이벤트 발생하지 않게 넘어감
	if  lua_helper.type_compare(
			user_party_leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) then
		return false
	end

	if not self.see_soup_event then
		if zone_name == self.soup_event_zone_name .. 1 then
			if self.current_event_state == self.event_state.idle then
				self.see_soup_event = true
				self.current_event_state = self.event_state.get_soup

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.invader_get_soup_event, self))
			end
		elseif zone_name == self.soup_event_zone_name .. 2 then
			if self.current_event_state == self.event_state.get_soup then
				self.see_soup_event = true
				self.current_event_state = self.event_state.bypass

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.invader_passing_by_event, self))
			end
		elseif zone_name == self.soup_event_zone_name .. 3 then
			if self.current_event_state == self.event_state.bypass then
				self.see_soup_event = true
				self.current_event_state = self.event_state.ending

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.invader_give_soup_event, self))
			end
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.get_photo and self.scoop_effect ~= nil then
			self.scoop_effect:Dispose()
			self.scoop_effect = nil
		end
	end
end

-- 배식 줄 1칸 씩 당기기
function local_class:process_row(immediate)
	local curve_index_1 = 3
	local curve_index_2 = 9
	local curve_index_3 = 12

	local duration = 1
	if immediate ~= nil and immediate then
		duration = 0
	end

	for i = 0, self.soup_cusomters.Count - 1 do
		if i < curve_index_1 then
			character_util.move_to(self.soup_cusomters[i], self.soup_cusomters[i].Position + vector(0, 0, 1),
					duration, nil, true, true)
		elseif i < curve_index_2 then
			character_util.move_to(self.soup_cusomters[i], self.soup_cusomters[i].Position + vector(-1, 0, 0),
					duration, nil, true, true)
		elseif i < curve_index_3 then
			character_util.move_to(self.soup_cusomters[i], self.soup_cusomters[i].Position + vector(0, 0, -1),
					duration, nil, true, true)
		end
	end

	wait_for_sec(duration)

	coroutine.yield(nil)

	character_util.set_direction(self.soup_cusomters[0], 'right')
	character_util.set_direction(self.soup_cusomters[curve_index_1 - 1], 'up')
	character_util.set_direction(self.soup_cusomters[curve_index_2 - 1], 'left')
	character_util.set_direction(self.soup_cusomters[curve_index_3 - 1], 'down')
end

function local_class:invader_get_soup_event()
	local soup_giver = get_character('soup_giver')

	-- 줄을 서세요! 많이 있어요!
	music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', parent = soup_giver})
	speech_bubble_util.show_speech_bubble_async(soup_giver, {key = 'invader_reporter_soup_0'})

	-- 수프 던져줌
	yield_return_func(self.throw_soup, self, soup_giver, self.soup_invader)

	-- 수프를 캐릭터 머리 위에 두기
	self.hold_soup.SpriteTransform.parent = self.soup_invader.Transform
	self.hold_soup.ShadowTransform.parent = self.soup_invader.Transform

	-- 수프 받고 1차 이동 동선
	wait_for_sec(0.3)

	character_util.set_anim(self.soup_invader, { name = 'walk' })
	character_util.move_to_async(self.soup_invader, self.soup_invader.Position + vector(-3, 0, 0),
			1, nil, true, true)

	character_util.set_direction(self.soup_invader, 'right')
	character_util.remove_anim(self.soup_invader)

	yield_return_func(self.process_row, self)

	-- ... 하더니 왼쪽 샛길로 나감.
	speech_bubble_util.show_speech_bubble_async(self.soup_invader, {key = 'invader_reporter_soup_1'})

	-- 2차 이동 동선
	character_util.set_anim(self.soup_invader, { name = 'walk' })
	character_util.move_waypoint_async(self.soup_invader, {
		self.soup_invader.Position + vector(0, 0, -1.5),
		self.soup_invader.Position + vector(-4, 0, -1.5)}, 5, false)

	-- 수프 페이드 아웃
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fade_soup, self, false))

	character_util.spine_set_alpha_fade(self.soup_invader, 0, 0.5)
	character_util.remove_anim(self.soup_invader)

	character_util.move_to_async(self.soup_invader, self.soup_invader.Position + vector(-3, 0, 0),
			0.5, nil, true, true)

	self.soup_invader.Position = vector(29, 0, 20.5)
	character_util.set_direction(self.soup_invader, 'right')

	-- 수프 페이드 인
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fade_soup, self, true))

	character_util.spine_set_alpha_fade(self.soup_invader, 1, 0.5)

	wait_for_sec(0.5)

	self.see_soup_event = false
end

-- 캐릭터에게 수프 던져주는 연출
function local_class:throw_soup(giver, getter)
	character_util.set_anim(giver, { name = 'throw', loop = false, sfx_name = '01_swing_01' })

	wait_for_sec(0.3)

	self.hold_soup = drop_item_util.create_item({ pos = giver.Position, target = getter.Position,
	                                              itemid = self.soup_item_id, notforinven = true,
	                                              lootstate = 'dontfindlooter', skip_text = true })

	self.hold_soup_transform_parent = self.hold_soup.SpriteTransform.parent
	self.hold_soup:SetSortingLayer(true)

	character_util.remove_anim(giver)

	wait_for_sec(1)

	coroutine.yield(self:soup_hold())
end

-- 수프 들기
function local_class:soup_hold()
	character_util.set_anim(self.soup_invader, { name = 'hold', scale = 0.3, loop = false })

	wait_for_sec(0.1)

	local cur_time = unity_class.time.time
	local hold_duration = 0.5

	local start_pos = self.hold_soup.Position
	local end_pos = self.soup_invader.Position + vector(0, 1.2, 0)

	while unity_class.time.time - cur_time < hold_duration do
		self.hold_soup:SetPosition(
				unity_class.vector3.Lerp(start_pos, end_pos, (unity_class.time.time - cur_time) / hold_duration), true)

		coroutine.yield(nil)
	end

	self.hold_soup:SetPosition(end_pos, true)

	character_util.set_anim(self.soup_invader, { name = 'hold_loop', upper = true })
	character_util.remove_anim(self.soup_invader)
end

-- 수프 페이드 인, 아웃
function local_class:fade_soup(fade_in)
	if fade_in then
		drop_item_util.alpha_fade_in_async(self.hold_soup, 0.5)
	else
		drop_item_util.alpha_fade_async(self.hold_soup, 0, 0.5)
	end
end

function local_class:invader_passing_by_event()
	local guard_1 = get_character('byway_guard_1')
	local guard_2 = get_character('byway_guard_2')

	character_util.set_anim(self.soup_invader, { name = 'walk' })
	character_util.move_to_async(self.soup_invader, self.soup_invader.Position + vector(3, 0, 0), nil,
			3, true, true)

	character_util.remove_anim(self.soup_invader)

	-- 알았지, 이번에도 부탁할게.
	speech_bubble_util.show_speech_bubble_async(self.soup_invader, {key = 'invader_reporter_soup_2'})

	-- 거 참... 이상한 녀석일세.
	speech_bubble_util.show_speech_bubble_async(guard_1, {key = 'invader_reporter_soup_3'})

	-- 신관님이 알게 되시면 큰일 나니까 적당히 해.
	speech_bubble_util.show_speech_bubble_async(guard_2, {key = 'invader_reporter_soup_4'})

	-- 길을 터주는 가드들
	character_util.move_to(guard_1, guard_1.Position + vector(0, 0, 0.3),
			nil, 1, false, true)
	character_util.move_to(guard_2, guard_2.Position + vector(0, 0, -0.3),
			nil, 1, false, true)

	wait_for_sec(0.5)

	character_util.set_anim(self.soup_invader, { name = 'walk' })
	character_util.move_to_async(self.soup_invader, self.soup_invader.Position + vector(10, 0, 0),
			nil, 3, true, true)

	character_util.spine_set_alpha_fade(self.soup_invader, 0, 0)
	character_util.remove_anim(self.soup_invader)

	-- 가드들 다시 위치로 복귀
	character_util.move_to(guard_1, guard_1.Position + vector(0, 0, -0.3),
			nil, 1, false, true)
	character_util.move_to(guard_2, guard_2.Position + vector(0, 0, 0.3),
			nil, 1, false, true)

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(self.soup_invader, 1, 0.5)
	self.soup_invader.Position = vector(52.5, 0, 4.5)

	character_util.set_direction(self.prisoners[0], 'right')
	character_util.set_direction(self.prisoners[1], 'left')

	self.see_soup_event = false
end

function local_class:invader_give_soup_event()
	-- 자, 어서 드세요.
	character_util.set_emotion(self.prisoners[0], {name = 'surprise'})
	character_util.set_emotion(self.prisoners[1], {name = 'surprise'})

	speech_bubble_util.show_speech_bubble_async(self.soup_invader, {key = 'invader_reporter_soup_5'})

	-- 수프 페이드 아웃
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fade_soup, self, false))

	wait_for_sec(0.3)

	character_util.remove_anim(self.soup_invader, true)

	wait_for_sec(0.2)

	coroutine.yield(nil)

	-- 들고 있던 수프 Transform parent 복구
	self.hold_soup.SpriteTransform.parent = self.hold_soup_transform_parent
	self.hold_soup.ShadowTransform.parent = self.hold_soup_transform_parent

	coroutine.yield(nil)

	self.hold_soup:ConsumeComplete()

	character_util.set_anim(self.soup_invader, { name = 'throw', loop = false, sfx_name = '01_swing_01' })

	wait_for_sec(0.3)

	-- 메인 컨트롤러에게 수프 주었다는 이벤트 보냄
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.give_soup_event }))

	-- 스쿠프 켜짐
	self.scoop_effect.transform.gameObject:SetActive(true)

	self.soup_1 = drop_item_util.create_item({ pos = self.soup_invader.Position,
											   target = self.prisoners[1].Position + vector(-0.3, 0, 0),
											  itemid = self.soup_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(0.5)
	character_util.remove_anim(self.soup_invader)
	wait_for_sec(1)
	-- 저... 정말 감사합니다!!
	character_util.set_emotion(self.prisoners[1], {name = 'damaged'})
	speech_bubble_util.show_speech_bubble_async(self.prisoners[1], {key = 'invader_reporter_soup_6'})
	music_player_util.play_sfx({ sfx_name = '01_eat_01', parent = self.prisoners[1]})
	character_util.set_anim(self.prisoners[1], {name = 'eat'})

	character_util.set_direction(self.soup_invader, 'left')
	wait_for_sec(0.5)

	character_util.set_anim(self.soup_invader, { name = 'throw', loop = false, sfx_name = '01_swing_01' })

	wait_for_sec(0.3)

	self.soup_2 = drop_item_util.create_item({ pos = self.soup_invader.Position,
											   target = self.prisoners[0].Position + vector(0.3, 0, 0),
											   itemid = self.soup_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(0.5)
	character_util.remove_anim(self.soup_invader)
	wait_for_sec(1)
	-- 인베이더들은 다 나쁜 사람들만 있는 줄 알았어요.
	character_util.set_emotion(self.prisoners[0], {name = 'damaged'})
	speech_bubble_util.show_speech_bubble_async(self.prisoners[0], {key = 'invader_reporter_soup_7'})
	music_player_util.play_sfx({ sfx_name = '01_eat_01', parent = self.prisoners[0]})
	character_util.set_anim(self.prisoners[0], {name = 'eat'})

	self.see_soup_event = false
end

function local_class:set_ending()
	if self.current_event_state < self.event_state.get_soup then
		yield_return_func(self.process_row, self, true)
	end

	character_util.set_position(self.soup_invader, vector(52.5, 0, self.prisoners[1].Position.z))
	character_util.set_direction(self.soup_invader, 'left')

	if self.soup_1 == nil then
		self.soup_1 = drop_item_util.create_item({ pos = self.soup_invader.Position,
												   target = self.prisoners[1].Position + vector(-0.3, 0, 0),
												   itemid = self.soup_item_id, notforinven = true, lootstate = 'dontfindlooter' })
	end

	if self.soup_2 == nil then
		self.soup_2 = drop_item_util.create_item({ pos = self.soup_invader.Position,
												   target = self.prisoners[0].Position + vector(0.3, 0, 0),
												   itemid = self.soup_item_id, notforinven = true, lootstate = 'dontfindlooter' })
	end

	character_util.set_direction(self.prisoners[0], 'right')
	character_util.set_direction(self.prisoners[1], 'left')

	character_util.set_emotion(self.prisoners[1], {name = 'damaged'})
	character_util.set_anim(self.prisoners[1], {name = 'eat'})

	character_util.set_emotion(self.prisoners[0], {name = 'damaged'})
	character_util.set_anim(self.prisoners[0], {name = 'eat'})

	self.current_event_state = self.event_state.ending
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
