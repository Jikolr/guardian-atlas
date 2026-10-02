local local_class = newclass('DemonShirePassage3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.oneline_string_key = 'ds_passage_3_oneline_'
	self.choose_string_key = 'ds_passage_3_choose_'
	self.narration_string_key = 'ds_passage_3_nar_'

	-- npc
	self.get_dungeon_man = function(num) return get_character('dungeon_'..num) end

	self.get_boss_tiger = function() return get_character('boss_tiger') end

	self.get_goblin = function() return get_character('goblin') end

	self.drop_items = {}

	-- fo
	self.sewer_door_name = 'cave_entrance_door'

	self.chest_name = 'chest'

	self.get_enter_ladder_area = function() return get_field_object('enter_ladder_area') end

	self.get_exit_ladder_area = function(num) return get_field_object('exit_ladder_area_'..num) end
	self.get_narration_area = function(num) return get_field_object('nar_event_area_'..num) end

	self.get_boss_room_chest = function() return get_field_object('chest') end

	-- 호랑이 보스 타이틀 이벤트를 보았는지
	self.meet_boss_tiger = false

	self.boss_tiger_battle_zone_name = 'battle8'
	self.boss_tiger_battle_group_name = 'battle8'

	self.battle_gate_name = 'battle_8_gate'
	self.battle_gate_count = 2

	self.end_door_1_name = 'end_door'
	self.end_door_2_name = 'end_door_2'

	-- 공격 연출하는 두 모험가 리스트
	self.adventurers_list = nil

	self.is_adventurers_attack = true

	self.duo_attack_event = false

	-- Zone
	self.duo_attack_event_zone_name = 'duo_attack_event_zone'
	self.stage_music_mute_zone_name = 'stage_music_mute_zone'
	self.stage_music_cave_zone_name = 'stage_music_cave_zone'
	self.stage_music_upper_cave_zone_name = 'stage_music_upper_cave_zone'

	-- effect
	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end
	self.get_fx_last_hit = function() return unity_object_pool.GetOrCreate('FX_lasthit') end
	self.get_sign_decal = function() return unity_object_pool.GetOrCreate('fx_demonshire_sign_decal') end
	self.get_fx_jump_smoke = function() return unity_object_pool.GetOrCreate('FX_Common_Jump_small') end

	-- marker
	-- (effect)
	self.get_effect_pos = function(num) return field:GetMarker('message_'..num).position end
	-- (ladder start pos)
	self.get_ladder_start_pos = function(num) return field:GetMarker('ladder_pos_'..num).position end
	self.get_ladder_out_pos = function() return field:GetMarker('ladder_out').position end
	self.get_ladder_in_pos = function() return field:GetMarker('ladder_in').position end
	self.get_boss_appear_pos = function() return field:GetMarker('boss_appear_pos').position end

	self.sign_effect_list = {}

	self.interact_check = false

	-- 사다리 구역 입장 시 시작한 입구 인덱스 저장
	self.save_entrance_ladder_index = 0

	self.ladder_area_entrance_min = 1
	self.ladder_area_entrance_max = 5

	self.boss_room_chest_interactable = nil

	self.chest_opened = false

	self.boss_clear = false

	self.stage_music_mute = false

	self.stage_music_cave_play = false

	self.cave_in = false
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	screen_util.preload_boss_title()

	self.get_fx_hit()
	self.get_fx_last_hit()
	self.get_sign_decal()
	self.get_fx_jump_smoke()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.adventurers_list = nil

	self.is_adventurers_attack = false

	-- twinkle 이펙트 삭제
	if self.sign_effect_list[1] ~= nil then
		self.sign_effect_list[1]:Dispose()
		self.sign_effect_list[1] = nil
	end

	if self.sign_effect_list[2] ~= nil then
		self.sign_effect_list[2]:Dispose()
		self.sign_effect_list[2] = nil
	end

	if self.sign_effect_list[3] ~= nil then
		self.sign_effect_list[3]:Dispose()
		self.sign_effect_list[3] = nil
	end

	if self.sign_effect_list[4] ~= nil then
		self.sign_effect_list[4]:Dispose()
		self.sign_effect_list[4] = nil
	end

	if self.sign_effect_list[5] ~= nil then
		self.sign_effect_list[5]:Dispose()
		self.sign_effect_list[5] = nil
	end

	if self.sign_effect_list[6] ~= nil then
		self.sign_effect_list[6]:Dispose()
		self.sign_effect_list[6] = nil
	end

	self.cs_controller = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	--
	if event_type == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_loaded_event(_)

	-- 쓸개골 퇴치 == star piece 획득 체크
	if not star_piece_util.has_star_piece('star_1') then
		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

		self.boss_clear = false

		local chest = self.get_boss_room_chest()
		self.chest_opened = chest.FieldObjectBehaviour.IsOpened
		if not self.chest_opened then
			self.boss_room_chest_interactable = self.get_boss_room_chest().Interactable
			self.get_boss_room_chest().Interactable = CS.Oak.PublishInteractable.Create()
		else
			self.get_boss_room_chest().Interactable = CS.Oak.NonInteractable.Instance

			local boss_appear_pos = self.get_boss_appear_pos()
			local boss_tiger = self.get_boss_tiger()
			character_util.set_position(boss_tiger, boss_appear_pos + vector(-3.5, 0, 0))
			character_util.set_direction(boss_tiger, 'down')
		end
	else
		self.get_boss_room_chest().Interactable = CS.Oak.NonInteractable.Instance

		self.boss_clear = true

		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.end_door_1_name, true))
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.end_door_2_name, true))
	end

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	self:event_setting()

	return true
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.duo_attack_event_zone_name and not self.duo_attack_event then
		self.duo_attack_event = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_three_people, self))

		return true
	elseif zone_name == self.stage_music_mute_zone_name and not self.interact_check and not self.stage_music_mute then
		music_player_util.play_stage_music({ state = 'muted' })
		self.interact_check = false
		self.stage_music_mute = true
		self.cave_in = true
		return true
	elseif zone_name == self.stage_music_cave_zone_name and not self.interact_check and self.stage_music_mute then
		music_player_util.play_stage_music({ name = 'bgm_cave_main', state = 'event' })
		self.stage_music_mute = false
		self.interact_check = false
		return true
	elseif zone_name == self.stage_music_upper_cave_zone_name and not self.interact_check and self.cave_in then
		music_player_util.play_stage_music({ state = 'field', mix = 1 })
		self.interact_check = false
		self.cave_in = false
		return true
	elseif zone_name == self.boss_tiger_battle_zone_name and self.boss_clear == false then
		if not star_piece_util.has_star_piece('star_1') and self.chest_opened then
			sp_util.play_normal_screenplay(self.retry_boss_event, self)
			return true
		end
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.boss_tiger_battle_group_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_after_boss_tiger_battle, self))
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_dungeon_man(1)) then
		speech_bubble_util.show_speech_bubble(e.Target, { key = self.oneline_string_key..1, skip = false })
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_dungeon_man(2)) then
		speech_bubble_util.show_speech_bubble(e.Target, { key = self.oneline_string_key..2, skip = false })
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_dungeon_man(3)) then
		speech_bubble_util.show_speech_bubble(e.Target, { key = self.oneline_string_key..3, skip = false })
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(1)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 1)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(2)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 2)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(3)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 3)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(4)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 4)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(5)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 5)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_narration_area(6)) then
		music_player_util.play_sfx_one_shot('01_interact_tower_01')
		self.interact_check = true
		sp_util.play_normal_screenplay(self.show_narration_by_effect, self, 6)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_goblin()) and self.interact_check == false then
		self.interact_check = true
		sp_util.play_normal_screenplay(self.talk_with_goblin, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_enter_ladder_area()) then
		sp_util.play_normal_screenplay(self.enter_random_entrance_pos, self)
		--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_random_entrance_pos, self))
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_exit_ladder_area(1))
			or lua_helper.reference_equals(e.Target, self.get_exit_ladder_area(2))
			or lua_helper.reference_equals(e.Target, self.get_exit_ladder_area(3))
			or lua_helper.reference_equals(e.Target, self.get_exit_ladder_area(4))
			or lua_helper.reference_equals(e.Target, self.get_exit_ladder_area(5)) then
		sp_util.play_normal_screenplay(self.interact_selected_exit, self, e.Target)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_boss_room_chest()) then
		if not e.Target.FieldObjectBehaviour.IsOpened then
			sp_util.play_normal_screenplay(self.boss_appearance_event, self, e.Target)
			return true
		end
	end
	return false
end

function local_class:event_setting()
	local goblin = self.get_goblin()

	-- 입구에 있는 NPC 설정
	self.adventurers_list = create_generic_list(CS.Oak.Character)

	local duo_man_1 = self.get_dungeon_man(1)
	--character_util.set_position(duo_man_1, vector(117.5, 0, -32))
	character_util.set_direction(duo_man_1, 'right')
	self.adventurers_list:Add(duo_man_1)

	local duo_man_2 = self.get_dungeon_man(2)
	character_util.set_direction(duo_man_2, 'right')
	character_util.set_anim(duo_man_2, { name = 'prostrate' })
	character_util.set_emotion(duo_man_2, {name = 'hurt'})

	local duo_man_3 = self.get_dungeon_man(3)
	character_util.set_emotion(duo_man_3, {name = 'mad'})
	character_util.set_direction(duo_man_3, 'left')
	self.adventurers_list:Add(duo_man_3)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.two_people_attack, self))

	-- 인터렉트(나레이션) 관련 이펙트 배치
	local effect_pos_1 = self.get_effect_pos(1)
	local effect_pos_2 = self.get_effect_pos(2)
	local effect_pos_3 = self.get_effect_pos(3)
	local effect_pos_4 = self.get_effect_pos(4)
	local effect_pos_5 = self.get_effect_pos(5)
	local effect_pos_6 = self.get_effect_pos(6)

	self.sign_effect_list[1] = self.get_sign_decal():Instantiate(effect_pos_1)
	self.sign_effect_list[2] = self.get_sign_decal():Instantiate(effect_pos_2)
	self.sign_effect_list[3] = self.get_sign_decal():Instantiate(effect_pos_3)
	self.sign_effect_list[4] = self.get_sign_decal():Instantiate(effect_pos_4)
	self.sign_effect_list[5] = self.get_sign_decal():Instantiate(effect_pos_5)
	self.sign_effect_list[5] = self.get_sign_decal():Instantiate(effect_pos_5)
	self.sign_effect_list[6] = self.get_sign_decal():Instantiate(effect_pos_6)

	local fo = nil
	for i = 1, 5 do
		fo = get_field_object('nar_event_area_'..i)
		if fo ~= nil then
			local marker_pos = self.get_effect_pos(i)
			fo.Position = marker_pos
		end
	end

	-- 도어 NPC event setting
	if stage_progress:GetNamedData(self.sewer_door_name) then
		local goblin = self.get_goblin()
		character_util.remove_relate_event(goblin, self)
	else
		character_util.add_listener(goblin, self)
	end
end

-- 두 모험가들이 뱀파이어 하나에게 공격 연출
function local_class:two_people_attack()
	local timer = 0.3
	local adventurers_index = 0
	local delay = 1

	local vampire = self.get_dungeon_man(2)

	local deviate_pos_list = create_generic_list(unity_class.vector3)
	deviate_pos_list:Add(vector(1, 0, 0))
	deviate_pos_list:Add(vector(-1, 0, 0))

	while self.is_adventurers_attack do
		timer = timer + unity_class.time.deltaTime

		if timer > delay then
			timer = 0

			adventurers_index = adventurers_index + 1

			if adventurers_index > 1 then
				adventurers_index = 0
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.attack_routine, self, self.adventurers_list[adventurers_index], vampire,
					deviate_pos_list[adventurers_index]))
		end

		coroutine.yield(nil)
	end
end

-- 두 모험가 공격 세부 연출
function local_class:attack_routine(attacker, victim, deviate_pos)
	character_util.spine_deviate_local(attacker, deviate_pos * 0.5, 0.3, 0.2)
	character_util.set_anim(attacker, { name = 'attack', loop = false })
	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = attacker })

	wait_for_sec(0.3)

	self.get_fx_hit():Instantiate(victim.Position + vector(0, 0.3, 0))
	self.get_fx_last_hit():Instantiate(victim.Position + vector(0, 0.3, 0))

	character_util.spine_deviate_local(victim, deviate_pos * 0.3, 0.2, 0.1)
	--music_player_util.play_sfx_one_shot('01_hit_npc_01')
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', loop = false, parent = victim })
	character_util.spine_damage_red_pulse(victim)
	character_util.spine_damage_squish(victim, 1.3, 0.7, 1, 0.3)

	character_util.remove_anim(attacker)

	wait_for_sec(0.2)
end

function local_class:talk_three_people()
	local dungeon_man_1 = self.get_dungeon_man(1)
	local dungeon_man_2 = self.get_dungeon_man(2)
	local dungeon_man_3 = self.get_dungeon_man(3)

	character_util.remove_relate_event(dungeon_man_1, self)
	character_util.remove_relate_event(dungeon_man_2, self)
	character_util.remove_relate_event(dungeon_man_3, self)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', loop = false, parent = dungeon_man_1 })
	speech_bubble_util.show_speech_bubble_async(dungeon_man_1, { key = self.oneline_string_key..1, skip = false })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', loop = false, parent = dungeon_man_2 })
	speech_bubble_util.show_speech_bubble_async(dungeon_man_2, { key = self.oneline_string_key..2, skip = false })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_angry_01', loop = false, parent = dungeon_man_3 })
	speech_bubble_util.show_speech_bubble_async(dungeon_man_3, { key = self.oneline_string_key..3, skip = false })

	character_util.add_listener(dungeon_man_1, self)
	character_util.add_listener(dungeon_man_2, self)
	character_util.add_listener(dungeon_man_3, self)
end

function local_class:talk_with_goblin()

	local goblin = self.get_goblin()

	-- party align
	party_util.align_party(goblin.Position, 'down')

	-- 도어 npc (down, idle, idle): 이곳은 <b>하수로의 밑바닥<b>! 도전 하시겠습니까?
	speech_bubble_util.show_speech_bubble_async(goblin, { key = self.oneline_string_key..7, skip = true })

	local choose_list = {
		-- 물론이지!
		{ self.choose_string_key..1, 'mercy' },
		-- 그만둘래…
		{ self.choose_string_key..2, 'brutal' },
	}

	local choose_result = choose_util.play_choose_event(choose_list)

	if choose_result == 1 then
		-- (down, smile, release x2)자! 들어가시죠
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		character_util.set_emotion(goblin, { name = 'smile' })
		character_util.set_animation_n_times(goblin, { name = 'release', count = 2,
																		sfx = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(goblin, { key = self.oneline_string_key..8, skip = true })

		-- 문 열림, 열림 이벤트 포커싱, 열림 상태 저장
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.sewer_door_name, false))

		character_util.remove_anim_and_emotion(goblin)

		character_util.remove_relate_event(goblin, self)

		wait_for_sec(4.5)
	end

	self.interact_check = false
end

function local_class:show_narration_by_effect(index)
	-- 나레이션 박스 표시.
	field_ui_util.show_narration_async({ key = self.narration_string_key..index })
	self.interact_check = false
end

-- 사다리 이벤트 구역
function local_class:enter_random_entrance_pos()

	-- fade out circular
	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	local random_entrance_index = random_util.get_random_int(self.ladder_area_entrance_min, self.ladder_area_entrance_max)

	self.save_entrance_ladder_index = random_entrance_index

	local party_pos = self.get_ladder_start_pos(random_entrance_index)

	party_util.position_party(party_pos, 'down', 'linear')

	wait_for_sec(1)

	-- fade in circular
	music_player_util.play_stage_music({state = 'event', name = 'bgm_chasing'})
	screen_util.fade_in_circular_async(0.5, 'linear')
end

function local_class:interact_selected_exit(select_exit)
	local arrive_pos = unity_class.vector3.zero

	-- fade out circular
	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	if string.find(select_exit.Name, 'exit_ladder_area_'..self.save_entrance_ladder_index) then
		self.save_entrance_ladder_index = 0
		arrive_pos = self.get_ladder_in_pos()
	else
		arrive_pos = self.get_ladder_out_pos()
	end

	party_util.position_party(arrive_pos, 'up', 'linear')

	wait_for_sec(1)

	-- fade in circular
	music_player_util.play_stage_music({ name = 'bgm_cave_main', state = 'event' })
	screen_util.fade_in_circular_async(0.5, 'linear')
end

function local_class:set_after_boss_tiger_battle()

	self.boss_clear = true

	wait_for_sec(3)

	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.end_door_1_name, true))
	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.end_door_2_name, true))

	message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.battle_gate_name))

	if not self.chest_opened then
		self.get_boss_room_chest().Interactable = self.boss_room_chest_interactable
	end

	music_player_util.play_stage_music({ name = 'bgm_cave_main', state = 'event' })
end

function local_class:boss_appearance_event(chest)
	local boss_appear_pos = self.get_boss_appear_pos()
	local boss_tiger = self.get_boss_tiger()

	-- party align
	party_util.align_party(chest.Position + vector(-0.5, 0, -1.5), 'down', 1, 'linear')

	wait_for_sec(1)

	--chest:Shake(0.1, 0.3)

	-- 보물 상자 열기
	message_system:Publish(CS.Oak.TreasureOpenEvent.Create(user_party.Leader, self.chest_name,
			CS.Oak.TreasureOpenType.OnlyTreasureOpen))

	wait_for_sec(4)

	character_util.set_direction(user_party.Leader, 'right')
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim(user_party.Leader, {name = 'question', loop = false})
	character_util.set_emotion(user_party.Leader, { name = 'tired' })
	character_util.show_emoticon_async(user_party.Leader, nil, 'question')

	--character_util.remove_anim_and_emotion(user_party.Leader)

	wait_for_sec(0.5)

	character_util.set_position(boss_tiger, boss_appear_pos + vector(7, 5, 0))

	wait_for_sec(0.1)

	character_util.set_anim(boss_tiger, { name = 'pounce', loop = false})

	--02_druid_ready_02 + 02_twohand_stomp_jump_01
	music_player_util.play_sfx_one_shot('02_druid_ready_02')
	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	character_util.jump_move(boss_tiger, boss_appear_pos, 9.3, 0.5, true)

	wait_for_sec(0.05)

	camera_util.shake(0.15, 0.5)

	character_util.remove_anim(user_party.Leader)

	music_player_util.play_sfx_one_shot('03_mech_stomp_01')
	music_player_util.play_stage_music({ state = 'muted', mix = 0 })
	self.get_fx_jump_smoke():Instantiate(boss_appear_pos)

	character_util.remove_anim(boss_tiger)

	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	character_util.set_direction(user_party.Leader, 'right')

	wait_for_sec(0.3)

	camera_util.move_async(boss_tiger.Position, 0.5)

	wait_for_sec(0.3)

	character_util.set_anim(boss_tiger, { name = 'unique/shout', loop = false, sfx_name = '01_roar_01'})

	local anim_duration = spine_util.get_animation_duration(boss_tiger, 'unique/shout') / 1

	wait_for_sec(anim_duration)

	character_util.remove_anim(boss_tiger)

	screen_util.show_boss_title('ds_passage_3_boss_title',
			'ds_passage_3_boss_subtitle', 2, false)

	character_util.set_emotion(user_party.Leader, { name = 'attack' })

	wait_for_sec(2)

	music_player_util.play_stage_music({name = 'bgm_battle_boss', state = 'combat', mix = 0})

	camera_util.return_to_leader(0.5)

	character_util.convert_to_monster(boss_tiger, self.boss_tiger_battle_group_name, self.boss_tiger_battle_zone_name)

	command_util.execute_monster_notice(boss_tiger, get_party_leader(), 'battle')

	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(boss_tiger))

	message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.battle_gate_name))

	self.get_boss_room_chest().Interactable = CS.Oak.NonInteractable.Instance

	character_util.remove_emotion(user_party.Leader)
end

function local_class:retry_boss_event()
	local boss_appear_pos = self.get_boss_appear_pos()
	local boss_tiger = self.get_boss_tiger()

	-- party align
	party_util.align_party(boss_tiger.Position + vector(0, 0, -1.5), 'down', 1, 'linear')

	wait_for_sec(0.5)

	camera_util.move_async(boss_tiger.Position, 0.5)

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	wait_for_sec(0.5)

	character_util.set_direction(boss_tiger, 'left')

	character_util.set_anim(boss_tiger, { name = 'unique/shout', loop = false })
	music_player_util.play_sfx({ sfx_name = '01_roar_01', loop = false, duration = 1.5 })

	local anim_duration = spine_util.get_animation_duration(boss_tiger, 'unique/shout') / 1

	wait_for_sec(anim_duration * 0.1)

	camera_util.shake(0.15, 0.5)

	wait_for_sec(anim_duration * 0.9)

	wait_for_sec(0.05)

	character_util.set_direction(boss_tiger, 'down')

	character_util.remove_anim(boss_tiger)

	wait_for_sec(0.7)

	screen_util.show_boss_title('ds_passage_3_boss_title',
			'ds_passage_3_boss_subtitle', 2, false)

	character_util.set_emotion(user_party.Leader, { name = 'attack' })

	wait_for_sec(2)

	music_player_util.play_stage_music({name = 'bgm_battle_boss', state = 'combat', mix = 0})

	camera_util.return_to_leader(0.5)

	character_util.convert_to_monster(boss_tiger, self.boss_tiger_battle_group_name, self.boss_tiger_battle_zone_name)

	command_util.execute_monster_notice(boss_tiger, get_party_leader(), 'battle')

	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(boss_tiger))

	message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.battle_gate_name))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
