local local_class = newclass("InvaderReporterPrisonerController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.prisoners_1 = nil

	self.invaders_1 = nil

	-- 고블린 가방 소녀의 우리
	self.goblin_bag_girl_cage = nil

	-- 고블린 가방 소녀 동생
	self.goblin_bag_sis = nil

	-- 텐트 Exit Interactalbe
	self.tent_exit_interatable = nil

	-- 사진 촬영 Effect
	self.scoop_effect = nil

	-- 스타피스 이펙트
	self.star_piece_effect = nil

	-- 이벤트 체크 플래그
	self.see_prisoner_event = false
	self.see_tent_event = false
	self.see_intro_sis_talk = false

	-- 동적으로 로딩한 캐릭터들을 파괴할것인지 여부
	self.experimental_destroy_character = true

	-- 고블린 가방 소녀 이벤트 state
	self.event_state = {
		-- 고블린 가방 소녀 부탁 받지 않은 상태
		idle = 0,
		-- 동생 찾아서 고블린 가방 소녀에게 돌아가야 하는 상태
		find_sister = 1,
		-- 이벤트 완료
		ending = 2
	}

	self.current_event_state = self.event_state.idle

	self.stage_custom_state = {
		prisoner = 1
	}

	-- 기타 상수
	self.candy_item_id = 20086
	self.paper_item_id = 20102

	-- 타일맵 NPC 이름
	self.goblin_bag_sis_name = 'goblin_bag_sister'
	self.maniac_invader_name = 'maniac_invader'

	-- 타일맵 필드오브젝트 이름
	self.prisoner_cage_1_name = 'prisoner_cage_1'
	self.prisoner_cage_2_name = 'prisoner_cage_2'
	self.goblin_bag_girl_cage_name = 'goblin_bag_girl_cage'
	self.goblin_bag_girl_star_piece_name = 'goblin_bag_girl_star_piece'
	self.tent_exit_name = 'exit_normal_tent'
	self.tent_door_name = 'tent_door'

	-- 타일맵 존 이름
	self.prisoner_event_zone_name = 'prisoner_1'
	self.tent_event_zone_name = 'tent_1'

	-- 타일맵 마커 이름
	self.reset_marker_name = 'exit_normal_tent'

	-- 커스텀 이벤트 이름
	self.maniac_invader_detected = 'maniac_invader_detected'
	self.get_photo = 'get_photo2'
	self.cancel_camera_event = 'cancel_camera'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.star_piece_effect_preset = 'FX_starpiece_in_character'
	self.scoop_effect_preset = 'invader_reporter_scoop_target'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.goblin_bag_sis = get_character(self.goblin_bag_sis_name)
	character_util.set_anim(self.goblin_bag_sis, { name = 'walk4legs' })
	character_util.set_emotion(self.goblin_bag_sis, { name = 'tired' })

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local star_piece_effect_pool = unity_object_pool.GetOrCreate(self.star_piece_effect_preset)
	local scoop_effect_pool = unity_object_pool.GetOrCreate(self.scoop_effect_preset)

	local optimized_npcs_1 = load_util.create_optimized_npcs_async({
		prisoner_1 = 'civilian_male',
		prisoner_2 = 'civilian_female',
		prisoner_3 = 'future_adult_big_sister',
		prisoner_4 = 'future_resistance_male',
		prisoner_5 = 'future_resistance_female',
		prisoner_6 = 'civilian_male',
		prisoner_7 = 'civilian_female',
		prisoner_8 = 'civilian_male'
	})

	self.prisoners_1 = create_generic_list(CS.Oak.Character)
	for i = 1, 8 do
		self.prisoners_1:Add(optimized_npcs_1['prisoner_'..i])
	end

	for i = 0, self.prisoners_1.Count - 1 do
		local val = math.floor(i / 2)
		local mod = i % 2

		if i < (self.prisoners_1.Count / 2) then
			character_util.set_position(self.prisoners_1[i], vector(25.5 + 6 * mod, 0, 5.5 - 2 * val))
		else
			character_util.set_position(self.prisoners_1[i], vector(25.5 + 6 * mod, 0, -2.5 - 2 * (val - 2)))
		end

		if mod == 0 then
			character_util.set_direction(self.prisoners_1[i], 'right')
		else
			character_util.set_direction(self.prisoners_1[i], 'left')
		end

		local anim_emo_mod = i % 3

		if anim_emo_mod == 0 then
			character_util.set_anim(self.prisoners_1[i], { name = 'cast' })
			character_util.set_emotion(self.prisoners_1[i], { name = 'tired' })
		elseif anim_emo_mod == 1 then
			character_util.set_anim(self.prisoners_1[i], { name = 'prostrate' })
			character_util.set_emotion(self.prisoners_1[i], { name = 'damaged' })
		else
			character_util.set_anim(self.prisoners_1[i], { name = 'hurt' })
			character_util.set_emotion(self.prisoners_1[i], { name = 'tired' })
		end
	end

	local optimized_npcs_2 = load_util.create_optimized_npcs_async({
		invader_1 = 'demonwarrior',
		invader_2 = 'demonarcher',
		invader_3 = 'demonwarrior',
		invader_4 = 'demon_hulk',
		invader_5 = 'fat_invader_guard',
	})

	self.invaders_1 = create_generic_list(CS.Oak.Character)
	for i = 1, 5 do
		self.invaders_1:Add(optimized_npcs_2['invader_'..i])
	end

	local invader_1_pos_list = create_generic_list(unity_class.vector3)
	invader_1_pos_list:Add(vector(30, 0, -2))
	invader_1_pos_list:Add(vector(30, 0, -3))
	invader_1_pos_list:Add(vector(30, 0, -4))
	invader_1_pos_list:Add(vector(30, 0, -5))
	invader_1_pos_list:Add(vector(27.5, 0, -4.5))

	local invader_1_dir_list = create_generic_list(CS.System.String)
	invader_1_dir_list:Add('right')
	invader_1_dir_list:Add('right')
	invader_1_dir_list:Add('right')
	invader_1_dir_list:Add('right')
	invader_1_dir_list:Add('left')

	for i = 0, self.invaders_1.Count - 1 do
		character_util.set_position(self.invaders_1[i], invader_1_pos_list[i])
		character_util.set_direction(self.invaders_1[i], invader_1_dir_list[i])
	end

	-- 필드오브젝트 설정
	self.goblin_bag_girl_cage = get_field_object(self.goblin_bag_girl_cage_name)

	if stage_progress:HasStarPiece(self.goblin_bag_girl_star_piece_name) then
		self.current_event_state = self.event_state.ending
	else
		-- 이펙트 로드 대기
		while not object_pool_extensions.IsLoaded(star_piece_effect_pool) do
			coroutine.yield(nil)
		end

		-- 스타피스 미획득 시에는 고블린 가방 소녀에게 스타피스 이펙트 붙여줌
		self.star_piece_effect = unity_object_pool.GetOrCreate(
				self.star_piece_effect_preset):Instantiate(self.prisoners_1[2].Position)
	end

	-- 이펙트 로드 대기
	while not object_pool_extensions.IsLoaded(scoop_effect_pool) do
		coroutine.yield(nil)
	end

	if not stage_progress:GetCustomData(self.stage_custom_state.prisoner, false) then
		self.scoop_effect = unity_object_pool.GetOrCreate(self.scoop_effect_preset):Instantiate(vector(28.5, 0, -4))
		self.scoop_effect.transform.gameObject:SetActive(false)
	else
		self.see_prisoner_event = true
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.prisoners_1 ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.prisoners_1)
		self.prisoners_1 = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.invaders_1 ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(self.invaders_1)
		self.invaders_1 = nil
	end

	self.goblin_bag_girl_cage = nil

	if self.scoop_effect ~= nil then
		self.scoop_effect:Dispose()
		self.scoop_effect = nil
	end

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
		self.star_piece_effect = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		if not stage_progress:GetCustomData(self.stage_custom_state.prisoner, false) then
			self.scoop_effect.transform.gameObject:SetActive(true)
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.goblin_bag_girl_cage) then
			if self.current_event_state == self.event_state.find_sister then
				sp_util.play_normal_screenplay(self.clear_request, self)
			elseif self.current_event_state == self.event_state.ending then
				speech_bubble_util.show_speech_bubble(self.prisoners_1[2], { key = 'invader_reporter_prisoner_20' })
			else
				speech_bubble_util.show_speech_bubble(self.prisoners_1[2], { key = 'invader_reporter_prisoner_9' })
			end
		elseif lua_helper.reference_equals(e.Target, self.goblin_bag_sis) then
			if self.current_event_state == self.event_state.idle then
				sp_util.play_normal_screenplay(self.find_sister, self)
			else
				speech_bubble_util.show_speech_bubble(self.goblin_bag_sis, { key = 'invader_reporter_prisoner_35' })
			end
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.prisoner_event_zone_name then
		if not self.see_prisoner_event then
			self.see_prisoner_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.prisoner_event, self))
		end
	elseif zone_name == self.tent_event_zone_name then
		if not self.see_tent_event then
			self.see_tent_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tent_event, self))
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.get_photo then
			self.scoop_effect:Dispose()
			self.scoop_effect = nil
		end
	end
end

-- 포로들 있는 이벤트 존 입장하면 실행되는 포로 괴롭히는 인베이더들 이벤트
function local_class:prisoner_event()
	local invader_a = self.invaders_1[0]
	local invader_b = self.invaders_1[1]
	local invader_c = self.invaders_1[4]

	local prisoner_a = self.prisoners_1[5]
	local prisoner_b = self.prisoners_1[6]

	local prisoner_cage_1 = get_field_object(self.prisoner_cage_1_name)
	local prisoner_cage_2 = get_field_object(self.prisoner_cage_2_name)

	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = prisoner_a })

	character_util.set_anim(prisoner_a, { name = 'embarrassed' })
	character_util.set_emotion(prisoner_a, { name = 'scared' })

	speech_bubble_util.show_speech_bubble_async(prisoner_a, { key = 'invader_reporter_prisoner_0' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = invader_a })

	character_util.set_anim(prisoner_a, { name = 'cast' })

	character_util.set_anim(invader_a, { name = 'cross_arm' })
	character_util.set_emotion(invader_a, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(invader_a, { key = 'invader_reporter_prisoner_1' })

	character_util.set_anim(invader_a, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(invader_a, { key = 'invader_reporter_prisoner_1_1' })

	character_util.spine_deviate_local(invader_a, vector(0.7, 0, 0), 0.3, 0.2)
	character_util.set_anim(invader_a, { name = 'attack', loop = false })

	wait_for_sec(0.3)

	music_player_util.play_sfx({ sfx_name = '01_hit_dummy_02', parent = invader_a })

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			invader_a.Position + vector(0.5, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			invader_a.Position + vector(0.5, 0.3, 0))

	prisoner_cage_1:Shake(0.04, 0.3)

	character_util.jump(prisoner_a, 1, 0.5)
	character_util.set_anim(prisoner_a, { name = 'embarrassed' })

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = prisoner_a })

	character_util.set_anim(prisoner_a, { name = 'cast' })
	character_util.set_emotion(prisoner_a, { name = 'damaged' })

	character_util.remove_anim(invader_a)
	character_util.remove_emotion(invader_a)

	speech_bubble_util.show_speech_bubble_async(prisoner_a, { key = 'invader_reporter_prisoner_2' })

	character_util.remove_anim(invader_a)

	speech_bubble_util.show_speech_bubble_async(invader_b, { key = 'invader_reporter_prisoner_3' })

	character_util.set_anim(invader_b, { name  = 'cross_arm' })

	speech_bubble_util.show_speech_bubble_async(invader_b, { key = 'invader_reporter_prisoner_4' })

	character_util.remove_anim(invader_b)

	wait_for_sec(0.5)

	character_util.set_anim(prisoner_b, { name = 'success' })
	character_util.set_emotion(prisoner_b, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(prisoner_b, { key = 'invader_reporter_prisoner_5' })

	character_util.set_direction(invader_a, 'left')

	character_util.set_direction(invader_b, 'left')

	character_util.set_direction(invader_c, 'right')

	speech_bubble_util.show_speech_bubble_async(invader_c, { key = 'invader_reporter_prisoner_6' })

	character_util.set_anim(invader_a, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(invader_a, { key = 'invader_reporter_prisoner_7' })

	character_util.set_anim(invader_b, { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(invader_b, { key = 'invader_reporter_prisoner_8' })

	character_util.remove_anim(invader_b)

	speech_bubble_util.show_speech_bubble_async(invader_b, { key = 'invader_reporter_prisoner_8_1' })

	character_util.set_direction(invader_a, 'right')
	character_util.remove_anim(invader_a)

	character_util.set_direction(invader_b, 'right')

	character_util.set_direction(invader_c, 'left')
end

-- 고블린 가방 소녀의 부탁 완료
function local_class:clear_request()
	local goblin_bag_girl = self.prisoners_1[2]
	local star_piece = get_field_object(self.goblin_bag_girl_star_piece_name)

	-- 이동 중에 Guard NPC에게 걸리지 않도록 히트박스 조정
	local saved_hitbox = user_party_leader.Hitbox
	user_party_leader.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), unity_class.vector3.zero)

	coroutine.yield(nil)

	party_util.align_party(goblin_bag_girl.Position + vector(0.5, 0, 0), 'right', 1)

	user_party_leader.Hitbox = saved_hitbox

	speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_9', skip = true })

	choose_result = choose_util.play_choose_event({ { 'invader_reporter_prisoner_12', 'mercy' },
	                                                { 'invader_reporter_prisoner_13', 'brutal' } })

	if choose_result == 1 then
		self.current_event_state = self.event_state.ending

		character_util.set_anim(goblin_bag_girl, { name = 'cast' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_14', skip = true })

		character_util.set_anim(user_party_leader, { name = 'throw', loop = false, sfx_name = '01_swing_01' })

		wait_for_sec(0.3)

		music_player_util.play_sfx({ sfx_name = '01_paper_01' })

		local item_2 = drop_item_util.create_item({ pos = user_party_leader.Position, target = goblin_bag_girl.Position + vector(0.3, 0, 0),
		                                          itemid = self.paper_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true })

		wait_for_sec(0.2)

		character_util.remove_anim(user_party_leader)

		character_util.jump(goblin_bag_girl, 1, 0.5)
		character_util.set_anim(goblin_bag_girl, { name = 'cast' })
		character_util.set_emotion(goblin_bag_girl, { name = 'surprise' })

		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_15', skip = true })

		character_util.set_anim(goblin_bag_girl, { name = 'eat' })
		character_util.remove_emotion(goblin_bag_girl)

		item_2.ConsumeTarget = goblin_bag_girl
		item_2:Fly()

		wait_for_sec(1)

		character_util.set_anim(goblin_bag_girl, { name = 'cast' })
		character_util.set_emotion(goblin_bag_girl, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_16', skip = true })

		character_util.set_emotion(goblin_bag_girl, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_16_1', skip = true })

		character_util.set_emotion(goblin_bag_girl, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_16_2', skip = true })

		character_util.set_anim(goblin_bag_girl, { name = 'sing' })
		character_util.set_emotion(goblin_bag_girl, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_17', skip = true })

		character_util.set_anim(goblin_bag_girl, { name = 'cast' })
		character_util.set_emotion(goblin_bag_girl, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_18', skip = true })

		character_util.set_emotion(goblin_bag_girl, { name = 'attack' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_18_1', skip = true })

		character_util.set_anim(goblin_bag_girl, { name = 'sing' })
		character_util.remove_emotion(goblin_bag_girl)

		speech_bubble_util.show_speech_bubble_async(goblin_bag_girl, { key = 'invader_reporter_prisoner_19', skip = true })

		self.star_piece_effect:Dispose()
		self.star_piece_effect = nil

		message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(goblin_bag_girl.Position))

		wait_for_sec(0.5)

		character_util.set_anim(goblin_bag_girl, { name = 'seat' })
		character_util.set_emotion(goblin_bag_girl, { name = 'tired' })
	end
end

-- 텐트 안에서 실행되는 이벤트
function local_class:tent_event()
	local tent_exit = get_field_object(self.tent_exit_name)
	self.tent_exit_interatable = tent_exit.Interactable
	tent_exit.Interactable = CS.Oak.NonInteractable.Instance

	local maniac_invader = get_character(self.maniac_invader_name)

	character_util.set_anim(maniac_invader, { name = 'sing' })
	character_util.set_emotion(maniac_invader, { name = 'smile' })

	wait_for_sec(1)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(-2, 0, 0),
			1, nil, true, false)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(0, 0, 2),
			1, nil, true, false)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(2, 0, 0),
			1, nil, true, false)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(0, 0, -2),
			1, nil, true, false)

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01' })

	character_util.set_direction(self.goblin_bag_sis, 'right')
	character_util.jump(self.goblin_bag_sis, 1, 0.5)

	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01' })

	speech_bubble_util.show_speech_bubble_async(maniac_invader, { key = 'invader_reporter_prisoner_36' })

	speech_bubble_util.show_speech_bubble_async(self.goblin_bag_sis, { key = 'invader_reporter_prisoner_37' })

	music_player_util.play_sfx({ sfx_name = '01_swing_01' })

	character_util.set_anim(maniac_invader, { name = 'throw', loop = false, next_anim = 'idle' })

	wait_for_sec(0.3)

	local item = drop_item_util.create_item({ pos = maniac_invader.Position, target = maniac_invader.Position + vector(-6, 0, 0),
	                                          itemid = self.candy_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(0.3)

	character_util.set_direction(self.goblin_bag_sis, 'left')

	wait_for_sec(0.7)

	character_util.set_anim(maniac_invader, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(maniac_invader, { key = 'invader_reporter_prisoner_38' })

	character_util.remove_anim(maniac_invader)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(-4.5, 0, 0),
			2.5, nil, true, false)

	character_util.set_anim(self.goblin_bag_sis, { name = 'eat' })

	item.ConsumeTarget = self.goblin_bag_sis
	item:Fly()

	wait_for_sec(0.7)

	character_util.set_anim(self.goblin_bag_sis, { name = 'walk4legs' })

	wait_for_sec(0.3)

	character_util.move_to_async(self.goblin_bag_sis, self.goblin_bag_sis.Position + vector(4.5, 0, 0),
			2.5, nil, true, false)

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01' })

	character_util.set_anim(maniac_invader, { name = 'sing' })

	character_util.jump(self.goblin_bag_sis, 1, 0.5)

	item = drop_item_util.create_item({ pos = self.goblin_bag_sis.Position, target = maniac_invader.Position + vector(-0.3, 0, 0),
	                                    itemid = self.candy_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(1)

	item.ConsumeTarget = maniac_invader
	item:Fly()

	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01' })
	music_player_util.play_sfx({ sfx_name = '01_clap_02' })

	character_util.set_anim(maniac_invader, { name = 'push' })
	character_util.set_emotion(maniac_invader, { name = 'awesome' })

	speech_bubble_util.show_speech_bubble_async(maniac_invader, { key = 'invader_reporter_prisoner_39' })

	character_util.set_anim(maniac_invader, { name = 'sing' })
	character_util.set_emotion(maniac_invader, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(maniac_invader, { key = 'invader_reporter_prisoner_40' })

	character_util.set_direction(maniac_invader, 'down')
	character_util.remove_anim(maniac_invader)
	character_util.remove_emotion(maniac_invader)

	character_util.set_direction(self.goblin_bag_sis, 'up')

	speech_bubble_util.show_speech_bubble(self.goblin_bag_sis, { key = 'invader_reporter_prisoner_41' })

	character_util.move_to_async(maniac_invader, maniac_invader.Position + vector(-0.5, 0, 0),
			nil, 3, true, true)

	character_util.move_to_async(maniac_invader, maniac_invader.Position + vector(0, 0, 7),
			nil, 3, true, true)

	character_util.spine_set_alpha_fade(maniac_invader, 0, 1)

	wait_for_sec(1)

	character_util.set_active_state(maniac_invader, 'disabled')

	character_util.set_direction(self.goblin_bag_sis, 'right')
	character_util.set_anim(self.goblin_bag_sis, { name = 'hurt' })
	self.goblin_bag_sis.Interactable:AddListener(self.cs_controller)

	tent_exit.Interactable = self.tent_exit_interatable

	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.tent_door_name, false))
end

-- 고블린 소녀 동생과 대화
function local_class:find_sister()
	local goblin_bag_sis = self.goblin_bag_sis

	party_util.align_party(goblin_bag_sis.Position, 'right', 1)

	if not self.see_intro_sis_talk then
		self.see_intro_sis_talk = true

		music_player_util.play_sfx({ sfx_name = '01_player_jump_01' })

		character_util.jump(goblin_bag_sis, 1, 0.5)
		character_util.set_anim(goblin_bag_sis, { name = 'embarrassed' })
		character_util.set_emotion(goblin_bag_sis, { name = 'scared' })

		wait_for_sec(0.5)

		music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_24', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'walk4legs' })
		character_util.set_emotion(goblin_bag_sis, { name = 'damaged' })
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01' })

	speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_37', skip = true })

	choose_result = choose_util.play_choose_event({ { 'invader_reporter_prisoner_25', 'mercy' },
	                                                { 'invader_reporter_prisoner_26', 'brutal' } })

	if choose_result == 1 then
		self.current_event_state = self.event_state.find_sister

		character_util.set_anim(user_party_leader, { name = 'release', sfx_name = '01_swing_01' })

		music_player_util.play_sfx({ sfx_name = '01_player_jump_01' })

		character_util.jump(goblin_bag_sis, 1, 0.5)
		character_util.set_anim(goblin_bag_sis, { name = 'cast' })
		character_util.set_emotion(goblin_bag_sis, { name = 'surprise' })

		wait_for_sec(1)

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02' })

		character_util.remove_anim(user_party_leader)

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_27', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'sing' })
		character_util.set_emotion(goblin_bag_sis, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_28', skip = true })

		character_util.set_anim(user_party_leader, { name = 'nod' })

		wait_for_sec(1)

		character_util.remove_anim(user_party_leader)

		character_util.set_anim(goblin_bag_sis, { name = 'cast' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_29', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'sing' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_30', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'cast' })
		character_util.set_emotion(goblin_bag_sis, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_31', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'question', loop = false })

		wait_for_sec(1)

		character_util.set_anim(goblin_bag_sis, { name = 'release', sfx_name = '01_swing_01' })
		character_util.remove_emotion(goblin_bag_sis)

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_32', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'sing' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_33', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'throw', loop = false, sfx_name = '01_swing_01' })

		wait_for_sec(0.3)

		local item = drop_item_util.create_item({ pos = goblin_bag_sis.Position, target = user_party_leader.Position + vector(-0.3, 0, 0),
		                                          itemid = self.paper_item_id, notforinven = true, lootstate = 'dontfindlooter', skip_text = true })

		character_util.remove_anim(goblin_bag_sis)

		wait_for_sec(1)

		item.ConsumeTarget = user_party_leader
		item:Fly()

		wait_for_sec(1)

		character_util.set_anim(goblin_bag_sis, { name = 'cast' })
		character_util.set_emotion(goblin_bag_sis, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_34', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'sing' })

		speech_bubble_util.show_speech_bubble_async(goblin_bag_sis, { key = 'invader_reporter_prisoner_35', skip = true })

		character_util.set_anim(goblin_bag_sis, { name = 'hurt' })
		character_util.set_emotion(goblin_bag_sis, { name = 'tired' })
	else
		music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01' })

		character_util.shake(goblin_bag_sis, 0.04, 1)
		character_util.set_emotion(goblin_bag_sis, { name = 'damaged' })

		character_util.set_anim(user_party_leader, { name = 'sing' })
		character_util.set_emotion(user_party_leader, { name = 'smile' })

		wait_for_sec(1)

		character_util.set_emotion(goblin_bag_sis, { name = 'tired' })

		character_util.remove_anim(user_party_leader)
		character_util.remove_emotion(user_party_leader)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
