local local_class = newclass("NightmareTeatans1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.potato_campfire_name = 'potato_campfire_'

	self.harvester_appeared = false
	self.ran_teatans = false
	self.get_potato = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	CS.Oak.CommonScreenplay.PreloadItemGetEvent()

	for i = 1, 4 do
		local potato_campfire = get_field_object(self.potato_campfire_name .. i)
		potato_campfire.Interactable = CS.Oak.PublishInteractable.Create()
	end
	local harvester_campfire = get_field_object('harvester_campfire')
	harvester_campfire.Interactable = CS.Oak.PublishInteractable.Create()

	local potato_door = get_field_object('potato_door')
	self.is_opened_potato_door = potato_door.FieldObjectBehaviour.IsOpen
	if self.is_opened_potato_door then
		local hungry_teatan = get_character('hungry_teatan')
		hungry_teatan.Position = vector(999, 0, 999)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local hungry_teatan = get_character('hungry_teatan')
	if lua_helper.type_compare(hungry_teatan.Interactable, typeof(CS.Oak.NPCInteractable)) then
		hungry_teatan.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
	self.ifo_util = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == 'harvester_appear' and not self.harvester_appeared then
				self.harvester_appeared = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.harvester_appear_event, self))
			elseif e.Zone.Name == 'run_teatans' and not self.ran_teatans then
				self.ran_teatans = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatans_run_event, self))
			end
		end
	end

	if event_type == typeof(CS.Oak.InteractEvent) then
		local hungry_teatan = get_character('hungry_teatan')
		if lua_helper.reference_equals(e.Target, hungry_teatan) and self.get_potato then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.give_potato, self))
			return true
		end

		local owen = get_character('owen')
		local owen_bed = get_field_object('owen_bed')
		if lua_helper.reference_equals(e.Target, owen_bed) then
			speech_bubble_util.show_speech_bubble(owen, { key = 'nightmare_teatans_3_owen' })
			return true
		end

		for i = 1, 4 do
			-- 메인 쪽에서 캠프파이어를 harvester_campfire로 쓰고 있어서 2개 체크
			local potato_campfire = get_field_object('potato_campfire_' .. i)
			local harvester_campfire = get_field_object('harvester_campfire')

			if lua_helper.reference_equals(e.Target, potato_campfire) or
				lua_helper.reference_equals(e.Target, harvester_campfire) then
				coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.interact_campfire, self, e.Target))
				return true
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then

		-- 악몽티탄왕국 퀘스트 섹션2 상태가 아니라면 하베스터 모닥불 이벤트가 티탄들이 도망가는 이벤트를 못보게 함.
		local main_quest = user_progress:GetStartedQuest(81)
		if main_quest == nil or main_quest.InnerProgress ~= 1 or main_quest.IsComplete then
			self.harvester_appeared = true
			self.ran_teatans = true

			local disable_npcs = {
				get_character('run_teatan_6'),
				get_character('run_teatan_4'),
				get_character('run_teatan_3'),
				get_character('run_teatan_1'),
				get_character('run_teatan_5'),
				get_character('run_teatan_2'),
				get_character('seen_harvester_teatan_1'),
				get_character('seen_harvester_teatan_2'),
				get_character('seen_harvester_teatan_3'),
				get_character('seen_harvester_teatan_4')
			}
			for _, npc in ipairs(disable_npcs) do
				if npc ~= nil then
					npc.ActiveState = active_state('disabled')
				end
			end

			local hungry_teatan = get_character('hungry_teatan')
			if not self.is_opened_potato_door then
				hungry_teatan.Position = hungry_teatan.Position + 4 * unity_class.vector3.right
				character_util.set_direction(hungry_teatan, 'right')
				character_util.set_anim(hungry_teatan, { name = 'prostrate' })
				character_util.set_emotion(hungry_teatan, { name = 'damaged' })
				hungry_teatan.Interactable.Talk = 'hungry_teatan_talk_1'

				local campfire = get_field_object('harvester_campfire')
				command_util.execute_extinguish(hungry_teatan, campfire)
			else
				hungry_teatan.Position = vector(999, 0, 999)
			end
		end
	end

	return false
end

-- 마티 주니어 친구들이 있는쪽에서 도망나오는 티탄들 이벤트
function local_class:teatans_run_event()
	local run_teatans = {
		get_character('run_teatan_6'), --zaco
		get_character('run_teatan_4'), --teatan_robot_female
		get_character('run_teatan_3'), --teatan_male
		get_character('run_teatan_1'), --teatan_female
		get_character('run_teatan_5'), --teatan_robot_male
		get_character('run_teatan_2') --teatan_old
	}

	local run_waypoints = {
		{ vector(37.5, 0, -70), vector(37.5, 0, -71), vector(45.5, 0, -71) },
		{ vector(37, 0, -69), vector(37, 0, -69), vector(37, 0, -72), vector(46, 0, -72) },
		{ vector(36.5, 0, -70), vector(36.5, 0, -71.5), vector(45, 0, -71.5) },
		{ vector(38, 0, -78), vector(38, 0, -73), vector(45, 0, -73) },
		{ vector(37, 0, -78), vector(37, 0, -73), vector(46, 0, -73) },
		{ vector(37.5, 0, -79), vector(37.5, 0, -73), vector(45.5, 0, -73) }
	}

	local speeds = {
		6,
		5.5,
		5.5,
		6,
		5.5,
		5.5
	}

	-- 존 진입시 bgm 변경
	-- bgm_transition: Field(bgm_teatans_main) -> Event(bgm_suspense_theme)
	music_player_util.play_stage_music({
		name = 'bgm_suspense_theme', state = 'event'
	})

	music_player:PlaySfxOneShot('03_npc_runaway_01')
	music_player:PlaySfxOneShot('02_victim_scream_01')
	music_player:PlaySfxOneShot('03_dialogue_sadness_01')

	local talks = { 'run_teatan_shout_1', 'run_teatan_shout_2', nil, nil, 'run_teatan_shout_5', }

	local wait_routines = {}
	for i, runner in ipairs(run_teatans) do
		if talks[i] ~= nil then
			speech_bubble_util.show_speech_bubble(runner, {key = talks[i], life_time = 5})
		end

		wait_routines[i] = util.cs_generator(self.runner_move_routine, self, runner, run_waypoints[i], speeds[i])
	end

	coroutine.yield(coroutine_class.wait_all(table.unpack(wait_routines)))

	for _, runner in ipairs(run_teatans) do
		runner:RemoveEmotion()
		runner.ActiveState = active_state('disabled')
	end
end

function local_class:runner_move_routine(runner, waypoints, speed)
	runner:SetEmotion('scared', true)
	runner:RemoveAnimation()
	character_util.move_waypoint_async(runner, waypoints, speed, true)

	local jump_start_pos = runner.Position:GetXy0(-61)
	character_util.move_waypoint_async(runner, jump_start_pos, speed, true)

	runner:Jump(1, 0.5)

	local end_pos = jump_start_pos + unity_class.vector3.forward * 5
	character_util.move_waypoint_async(runner, end_pos, speed, true)

	runner:RemoveEmotion()
	runner.ActiveState = active_state('disabled')
end

-- 하베스터가 나타나서 모닥불에있던 티탄들이 도망가는 이벤트
function local_class:harvester_appear_event()
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local harvester = get_character('harvester')
	local seen_teatan_1 = get_character('seen_harvester_teatan_1')
	local seen_teatan_2 = get_character('seen_harvester_teatan_2')
	local seen_teatan_3 = get_character('seen_harvester_teatan_3')
	local seen_teatan_4 = get_character('seen_harvester_teatan_4')
	local hungry_teatan = get_character('hungry_teatan')
	local run_teatans = { seen_teatan_1, seen_teatan_2, seen_teatan_3, seen_teatan_4, hungry_teatan }
	local campfire = get_field_object('harvester_campfire')

	harvester.Position = vector(93, 0, -37)
	harvester.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	harvester.SpineController:ResetAllColors()
	harvester.SpineController:AddColor('darken_harvester', unity_color({0,0,0,0.2}), 1, 0)

	seen_teatan_3:SetEmotion('tired', true)
	seen_teatan_3:SetAnimation('idle', true)

	local harvester_speed = 27
	local harvester_target_pos = vector(58,0, -61)

	-- 하베스터 지나가는 sfx
	music_player_util.play_sfx({
		sfx_name = '02_harvester_prepare_01', parent = harvester
	})

	character_util.set_locked_dir(harvester, 'left')
	character_util.move_waypoint_async(harvester, vector(79, 0, -46), harvester_speed, false)

	music_player:PlaySfxOneShot('01_light_turn_off_01')

	command_util.execute_extinguish(harvester, campfire)

	for _, teatan in ipairs(run_teatans) do
		character_util.look_at(teatan, harvester)
		teatan:SetEmotion('surprise', true)
		teatan:RemoveAnimation()
		teatan:Jump(0.5, 0.3)
	end

	character_util.move_waypoint(harvester, harvester_target_pos, harvester_speed, false)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local waypoints = {
		{vector(79, 0, -58.5)},
		{vector(72, 0, -45.5), vector(72, 0, -51.5)},
		{vector(80.5, 0, -41), vector(75.25, 0, -41), vector(75.25, 0, -37)},
		{vector(82, 0, -46), vector(89, 0, -46)}
	}

	local wait_routines = {}

	music_player:PlaySfxOneShot('02_victim_fly_03')
	music_player:PlaySfxOneShot('03_runaway_01')

	speech_bubble_util.show_speech_bubble(seen_teatan_2, {key = 'seen_harvester_teatan_shout_1', bubble_type = 'shout'})
	speech_bubble_util.show_speech_bubble(seen_teatan_4, {key = 'seen_harvester_teatan_shout_2', bubble_type = 'shout'})

	for i, runner in ipairs(run_teatans) do
		if lua_helper.reference_equals(runner, hungry_teatan) then
			if not self.is_opened_potato_door then
				wait_routines[i] = util.cs_generator(self.hungry_teatan_run_event, self)
			end
		elseif lua_helper.reference_equals(runner, seen_teatan_3) then
			wait_routines[i] = util.cs_generator(self.scare_and_run_teatan, self, runner, waypoints[i], 7)
		elseif lua_helper.reference_equals(runner, seen_teatan_1) then
			wait_routines[i] = util.cs_generator(self.move_around_n_run_teatan, self, runner, waypoints[i], 9)
		elseif lua_helper.reference_equals(runner, seen_teatan_4) then
			wait_routines[i] = util.cs_generator(self.normal_run_tetan, self, runner, waypoints[i], CS.Oak.Direction.Right, 6.5)
		elseif lua_helper.reference_equals(runner, seen_teatan_2) then
			wait_routines[i] = util.cs_generator(self.normal_run_tetan, self, runner, waypoints[i], CS.Oak.Direction.Down, 6.5)
		end

		-- hungry_teatan을 제외한 티탄들은 유저와 부딪치지 않게
		if not lua_helper.reference_equals(runner, hungry_teatan) then
			runner.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		end
	end

	coroutine.yield(coroutine_class.wait_all(table.unpack(wait_routines)))

	-- 직후 하베스터 대전 이벤트가 실행될것이므로 그 위치에 놓는다.
	harvester.SpineController:ResetAllColors()
	harvester.Position = vector(-7, 0, -76.5)
	harvester.Direction = character_util.get_direction('left')
	harvester:RemoveAnimation()
	character_util.set_locked_dir(harvester, 'none')

	-- 도망친 티탄들 비활성화
	for _, runner in ipairs(run_teatans) do
		if not lua_helper.reference_equals(runner, hungry_teatan) then
			runner:RemoveEmotion()
			runner.ActiveState = active_state('disabled')
		end
	end
end

function local_class:normal_run_tetan(runner, wp, jump_dir, speed)
	runner:SetEmotion('scared', true)

	character_util.move_waypoint_async(runner, wp, speed, true)

	runner.Direction = jump_dir

	runner:Jump(0.5, 0.25)
	character_util.move_to_async(runner, runner.Position + direction_util.to_vector3(jump_dir) + unity_class.vector3.up, 0.25)

	character_util.move_waypoint_async(runner, runner.Position + direction_util.to_vector3(jump_dir) * 2, speed, true)

	runner.SpineController:SetAlphaFade(0, 0.25)
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	runner:RemoveEmotion()
	runner:RemoveAnimation()
	runner.ActiveState = active_state('disabled')
end

-- 조금 주위를 움지깅다 도망가는 티탄
function local_class:move_around_n_run_teatan(runner, wp, speed)

	runner:SetEmotion('scared', true)
	runner:RemoveAnimation()
	character_util.move_waypoint_async(runner, runner.Position + unity_class.vector3.left * 3.5, 6.5, false)

	runner:SetAnimation('embarrassed', true)
	runner:Jump(0.5, 0.3)
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	runner:RemoveAnimation()
	runner:SetEmotion('scared', true)
	character_util.move_waypoint_async(runner, runner.Position + unity_class.vector3.right * 3.5, 6.5, false)

	runner:SetAnimation('embarrassed', true)
	runner:Jump(0.5, 0.3)
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	character_util.move_waypoint_async(runner, wp, speed, true)

	runner:RemoveEmotion()
	runner:RemoveAnimation()
	runner.ActiveState = active_state('disabled')
end

-- 하베스터를 보고 겁난 표정으로 주위를 둘러보다가 도망가는 티탄
function local_class:scare_and_run_teatan(runner, wp, speed)
	runner:SetEmotion('scared', true)
	runner:SetAnimation('embarrassed', true)

	runner.Direction = character_util.get_direction('down')
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	runner.Direction = character_util.get_direction('right')
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	runner.Direction = character_util.get_direction('left')
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	runner.Direction = character_util.get_direction('up')
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	speech_bubble_util.show_speech_bubble(runner, {key = 'seen_harvester_teatan_shout_3'})

	self:normal_run_tetan(runner, wp, CS.Oak.Direction.Up, speed)
end

function local_class:hungry_teatan_run_event()
	local hungry_teatan = get_character('hungry_teatan')

	hungry_teatan.Direction = character_util.get_direction('right')
	hungry_teatan:SetEmotion('surprise', true)
	hungry_teatan:Jump(0.5, 0.3)
	coroutine.yield(coroutine_class.wait_for_sec(0.6))

	speech_bubble_util.show_speech_bubble(hungry_teatan, { key = 'hungry_teatan_talk_1_0', skip = true })
	character_util.move_waypoint_async(hungry_teatan, hungry_teatan.Position + unity_class.vector3.right * 3, 4, false)

	hungry_teatan:SetEmotion('damaged', true)
	hungry_teatan:SetAnimation('prostrate', true)
	character_util.move_to_async(hungry_teatan, hungry_teatan.Position + unity_class.vector3.right, 0.25)
	hungry_teatan.SpineController:DamageRedPulse()
	speech_bubble_util.show_speech_bubble(hungry_teatan, { key = 'hungry_teatan_talk_1_1', bubble_type = 'shout'})

	hungry_teatan:Shake(0.05, 99)
	coroutine.yield(coroutine_class.wait_for_sec(2.0))

	speech_bubble_util.show_speech_bubble_async(hungry_teatan, {key = 'hungry_teatan_talk_1', skip = true})
	hungry_teatan:CancelShake()

	hungry_teatan.Interactable.Talk = 'hungry_teatan_talk_1'
end

-- 캠프파이어 상호작용
function local_class:interact_campfire(campfire)
	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	-- 해당 캠프파이어가 불이 꺼진 캠프파이어면 파티원 중에 컨틀렛이나 클로가 장착 가능한 캐릭터를 체크할 필요 없음
	local correct_campfire = get_field_object('harvester_campfire')
	local is_burning_campfire = correct_campfire.CombustibleBehaviour.IsBurning
	if lua_helper.reference_equals(correct_campfire, campfire) and not is_burning_campfire then
		local direction = (user_party_leader.Position - campfire.Position):ToDirection()
		local campfire_pos = campfire.Position + 0.5 * unity_class.vector3.right

		-- 방향 값 (default = left)
		local dir = -1
		if direction == CS.Oak.Direction.Right then
			dir = 1
		else
			direction = CS.Oak.Direction.Left
		end

		-- 캠프파이어 x값 중심
		local pos = campfire_pos + vector(dir, 0, 0)

		-- 반대 방향 구하기
		local opposite_dir = CS.Oak.DirectionExtensions.GetOpposite(direction)
		user_party:PositionParty(pos, opposite_dir, 1, CS.Oak.Party.AlignType.Arc)
		coroutine.yield(coroutine_class.wait_for_sec(1.5))

		-- 뒤적거리는 sfx 루프 재생
		local search_sfx = music_player_util.play_sfx({
			sfx_name = '03_equipping_01', loop = true, type_priority = 'loop', player_priority = 'player'
		})

		character_util.set_anim(user_party_leader, { name = 'eat' })
		coroutine.yield(coroutine_class.wait_for_sec(1))

		-- 뒤적거리는 sfx 루프 중지
		search_sfx:FadeOut(0.2)

		character_util.remove_anim(user_party_leader)

		if self.is_opened_potato_door then
			-- 내레이션 - 모닥불 안에는 아무것도 없다.
			stage.FieldUINarrationBox:Show()
			local string_key = 'nightmare_teatans_3_potato_8'
			coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(string_key), 0, 1))
			stage.FieldUINarrationBox:Hide()
		else
			-- 내레이션 - 누군가 남겨둔 감자가 있지만 전혀 익지 않았다. 불을 피우면 맛있게 익을 것 같다.
			stage.FieldUINarrationBox:Show()
			local string_key = 'nightmare_teatans_3_potato_9'
			coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(string_key), 0, 1))
			stage.FieldUINarrationBox:Hide()
		end
		coroutine.yield(coroutine_class.wait_for_sec(0.5))

		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	-- 파티원 중에 건틀렛이나 클로가 장착 가능한 캐릭터가 있는지 체크
	for index = 0, user_party.Count - 1 do
		local get_weapon_util = CS.Oak.CharacterSpecExtensions.GetCompatibleWeapons
		-- 캐릭터 스펙 가져오기
		local character_spec = user_party[index].CharacterStatsBehaviour.CharacterSpec
		-- 무기 슬롯 1번에 장착 가능한 무기가 무엇인지 가져오기
		local weapons = get_weapon_util(character_spec, CS.Oak.EquipmentSlot.Weapon1)
		-- 건틀레이나 클로가 장착 가능한지 체크
		for k, v in pairs(weapons) do
			if lua_helper.reference_equals(v, CS.Oak.WeaponType.Gauntlet) or
				lua_helper.reference_equals(v, CS.Oak.WeaponType.Claw) then

				coroutine_manager:StartCoroutine(
					stage.StageGameObject,util.cs_generator(self.dig_campfire, self, user_party[index], campfire))
				return
			end
		end
	end

	-- 내레이션 - 모닥불이 활활 타고 있다. 장갑 같은 것을 낀다면 안을 뒤질 수 있을 것 같다.
	stage.FieldUINarrationBox:Show()
	local string_key = 'nightmare_teatans_3_potato_7'
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(string_key), 0, 1))
	stage.FieldUINarrationBox:Hide()
	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 캠프파이어 파기
-- target = 건틀렛이나 클로가 장착 가능한 캐릭터
function local_class:dig_campfire(target, campfire)
	local direction = (user_party_leader.Position - campfire.Position):ToDirection()
	-- 캠프파이어 x값 중심
	local pos = campfire.Position + 0.5 * unity_class.vector3.right

	coroutine.yield(self:party_move(target, pos, 1, direction, 1))

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	-- 뒤적거리는 sfx 루프 재생
	local search_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', loop = true, type_priority = 'loop', player_priority = 'player'
	})

	character_util.set_anim(target, { name = 'eat' })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 뒤적거리는 sfx 루프 중지
	search_sfx:FadeOut(0.2)

	character_util.remove_anim(target)

	-- 해당 캠프파이어가 정답이 아닌지 체크 또는 감자를 이미 얻었는지 또는 스타피스 문 열렸는지
	local correct_campfire = get_field_object('harvester_campfire')
	if not lua_helper.reference_equals(campfire, correct_campfire) or self.get_potato or self.is_opened_potato_door then
		-- 내레이션 - 모닥불 안에는 아무것도 없다.
		stage.FieldUINarrationBox:Show()
		local string_key = 'nightmare_teatans_3_potato_8'
		coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(string_key), 0, 1))
		stage.FieldUINarrationBox:Hide()
		coroutine.yield(coroutine_class.wait_for_sec(0.5))

		field_ui_manager:Show()
		user_party:ResetControllers()
		return
	end

	--  방향 값
	local dir = -1
	if direction == CS.Oak.Direction.Right then
		dir = 1
	end

	-- 감자 나오는 소리
	music_player:PlaySfxOneShot('01_player_popup_01')

	local potato_id = 20136
	-- 감자 드롭
	local drop_item = drop_item_util.create_item(
		{pos = pos, target = user_party_leader.Position, itemid = potato_id, notforinven = true})
	drop_item.ConsumeTarget = user_party_leader

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	-- 아이템 획득 연출
	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = potato_id
	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder,
		'nightmare_teatans_3_potato_subtitle', 'nightmare_teatans_3_potato_desc'))

	local hungry_teatan = get_character('hungry_teatan')
	hungry_teatan.Interactable:AddListener(self.cs_controller)
	self.get_potato = true

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 파티원 특정 정렬 (리더가 중심이 아닌 특정 캐릭터를 중심으로 정렬)
-- target = 중심이 되는 캐릭터
-- pos = 정렬할 위치
-- dist = 정렬할 위치로 부터 거리
-- direction = 이동 방향
-- move_duration = 이동 시간
function local_class:party_move(target, pos, dist, direction, move_duration)
	-- 방향 값 (default = left)
	local dir = -1
	if direction == CS.Oak.Direction.Right then
		dir = 1
	end

	local target_pos = pos + vector(dir * dist, 0, 0)

	-- 중심 캐릭터 이동
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		self.ifo_util.MoveTo(target, target_pos, move_duration, nil, true, true))

	-- 파티원들 지정 위치로 이동
	local party_pos = {
		target_pos + vector(0.5 * dir, 0, -0.5),
		target_pos + vector(0.5 * dir, 0, 0.5),
		target_pos + vector(1 * dir, 0, 0),
		target_pos + vector(1.5 * dir, 0, 0.5)}

	-- 중심이 아닌 캐릭터는 지나가기 때문에 새로운 index 값 사용 (continue가 없어서)
	local party_pos_index = 1
	for k, v in pairs(user_party) do
		-- 중심이 아닌 캐릭터들 이동
		if not lua_helper.reference_equals(v, target) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				self.ifo_util.MoveTo(v, party_pos[party_pos_index], move_duration, nil, true, true))
			party_pos_index = party_pos_index + 1
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(move_duration))

	-- 캐릭터들 방향 바꾸기
	for k, v in pairs(user_party) do
		if dir == 1 then
			character_util.set_direction(v, 'left')
		else
			character_util.set_direction(v, 'right')
		end
	end
end

-- 감자를 줌
function local_class:give_potato()
	local hungry_teatan = get_character('hungry_teatan')
	hungry_teatan.Interactable:RemoveRelatedEvent(self.cs_controller)

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local pos = hungry_teatan.Position + unity_class.vector3.left
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 감자 나오는 소리
	music_player:PlaySfxOneShot('01_throw_01')

	local drop_pos = hungry_teatan.Position + 0.5 * unity_class.vector3.left
	local drop_item = drop_item_util.create_item(
		{ pos = user_party_leader.Position, target = drop_pos, itemid = 20136, notforinven = true })
	drop_item.ConsumeTarget = hungry_teatan
	coroutine.yield(coroutine_class.wait_for_sec(1))

	character_util.set_direction(hungry_teatan, 'left')
	character_util.set_anim(hungry_teatan, { name = 'seat' })
	character_util.set_emotion(hungry_teatan, { name = 'surprise' })
	-- 가, 감자…? 이거, 주는 거야?
	local string_key = 'nightmare_teatans_3_potato_2'
	speech_bubble_util.show_speech_bubble_async(hungry_teatan, { key = string_key, skip = true })

	character_util.set_anim(user_party_leader, { name = 'nod' })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(hungry_teatan)
	character_util.set_emotion(hungry_teatan, { name = 'smile' })
	-- 고마워…!
	string_key = 'nightmare_teatans_3_potato_3'
	speech_bubble_util.show_speech_bubble_async(hungry_teatan, { key = string_key, skip = true })

	-- 먹는 sfx 루프 재생
	local eat_sfx = music_player_util.play_sfx({
		sfx_name = '01_eat_01', loop = true, type_priority = 'loop', player_priority = 'npc'
	})

	character_util.remove_anim(hungry_teatan)
	character_util.remove_emotion(hungry_teatan)
	character_util.set_anim(hungry_teatan, { name = 'eat' })
	character_util.set_emotion(hungry_teatan, { name = 'damaged' })
	coroutine.yield(coroutine_class.wait_for_sec(2))

	-- 먹는 sfx 루프 중지
	eat_sfx:FadeOut(0.2)

	character_util.remove_anim(hungry_teatan)
	character_util.remove_emotion(hungry_teatan)
	-- 흐아… 이제 좀 살 것 같아.
	string_key = 'nightmare_teatans_3_potato_6'
	speech_bubble_util.show_speech_bubble_async(hungry_teatan, { key = string_key, skip = true })

	-- 덕분에 살았어. 이거라도 받아 줘!
	string_key = 'nightmare_teatans_3_potato_4'
	speech_bubble_util.show_speech_bubble_async(hungry_teatan, { key = string_key, skip = true })

	local potato_door = get_field_object('potato_door')
	camera_util.move_async(potato_door.Position, 1)

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('potato_door', false))
	coroutine.yield(coroutine_class.wait_for_sec(2))

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	-- 이제 나도 어서 도망가야겠어!
	string_key = 'nightmare_teatans_3_potato_5'
	speech_bubble_util.show_speech_bubble_async(hungry_teatan, { key = string_key, skip = true })

	-- 배고픈 태탄 아래로 내려감
	character_util.remove_anim(hungry_teatan)
	character_util.set_anim(hungry_teatan, { name = 'run' })
	coroutine.yield(self.ifo_util.MoveTo(hungry_teatan, hungry_teatan.Position + 5 * unity_class.vector3.back,
		nil, 8, true, false, true))

	hungry_teatan.Position = vector(999, 0, 999)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
