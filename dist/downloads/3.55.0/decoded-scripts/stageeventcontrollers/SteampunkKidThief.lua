local local_class = newclass('SteampunkKidThiefStageController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 음식 아이템 id
	self.food_item_id = 20136

	-- 꼬마 도적 sns 아이디
	self.kid_thief_follow_id = 50

	-- 난민 현재 인원 상황
	self.refugee_count = 8
	self.cur_refugee_count = nil

	self.progress_enum = {
		-- 초기 상태
		idle = 1,
		-- 음식을 전부 나눠준 상태
		end_give_food = 2,
		-- 꼬마가 음식을 훔친 상태
		steal_food = 3,
		-- 꼬마를 구출한 상태
		safe_kid_thief = 4
	}

	self.current_progress = nil

	-- 플레이어가 해당 이벤트 그리드 안에 있는지
	self.player_enter_grid = false
	-- 플레이어가 해당 이벤트 존 안에 있는지
	self.player_enter_zone = false
	-- 줄 서는 연출 루틴이 실행중인지
	self.play_line_up_routine = false
	-- 구타 연출 루틴이 실행중인지
	self.play_assault_routine = false
	-- 구타할 때 대사를 실행할지
	self.play_assault_talk = false
	-- 구타할 때 대사 루틴이 실행중인지
	self.play_assault_talk_routine = false

	self.food_soldier_name = 'kid_thief_soldier'
	self.refugee_name = 'kid_thief_refugee_'
	self.assault_soldier_name = 'assault_soldier_'
	self.kid_thief_name = 'kid_thief'

	self.steal_food_event_zone = 'kid_thief_steal_food'
	self.assault_event_zone = 'kid_thief_assault_zone'
	self.door_name = 'kid_thief_door'
	self.kid_thief_grid_name = 'kid_thief_grid'

	self.fx_hit_name = 'FX_hit'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	self.current_progress = self.progress_enum.idle

	-- 꼬마 포함
	self.cur_refugee_count = self.refugee_count + 1

	if user_progress:IsFollowing(self.kid_thief_follow_id) then
		self.current_progress = self.progress_enum.safe_kid_thief

		for i = 4, self.refugee_count do
			local refugee = get_character(self.refugee_name .. i)
			refugee.ActiveState = active_state('disabled')
		end

		for i = 1, 2 do
			local assault_soldier = get_character(self.assault_soldier_name .. i)
			assault_soldier.ActiveState = active_state('disabled')
		end

		local food_soldier = get_character(self.food_soldier_name)
		food_soldier.Interactable.Talk = 'steampunk_2_kid_thief_1'

		local kid_thief = get_character(self.kid_thief_name)
		-- 의적에 관심이 생겼어?
		kid_thief.Interactable.Talk = 'steampunk_2_kid_thief_16'
		kid_thief.Position = field:GetMarker('kid_thief_assault_pos').position
		character_util.set_direction(kid_thief, 'down')

		message_system:Publish(CS.Oak.DoorOpenEvent.Create('kid_thief_door'))
	else
		unity_object_pool.GetOrCreate('FX_hit')
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		if lua_helper.type_compare(assault_soldier.Interactable, CS.Oak.NPCInteractable) then
			assault_soldier.Interactable:RemoveRelatedEvent(self.cs_controller)
		end
	end

	self.progress_enum = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		for i = 1, 2 do
			if lua_helper.reference_equals(e.Target, get_character(self.assault_soldier_name .. i)) then
				if self.current_progress == self.progress_enum.steal_food then
					self.current_progress = self.current_progress + 1
					self.play_assault_talk = false
					sp_util.play_normal_screenplay(self.safe_kid_thief, self)
					return true
				end
			end
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local zone_name = e.Zone.Name

	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	if zone_name == self.steal_food_event_zone then
		self.player_enter_zone = true

		if self.current_progress == self.progress_enum.end_give_food then
			self.current_progress = self.current_progress + 1
			sp_util.play_normal_screenplay(self.steal_food, self)
		end

		return true
	end

	if zone_name == self.assault_event_zone and self.current_progress == self.progress_enum.steal_food then
		self.play_assault_talk = true

		if not self.play_assault_talk_routine then
			self.play_assault_talk_routine = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.assault_talk_routine, self))
		end

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local zone_name = e.Zone.Name

	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	if zone_name == self.steal_food_event_zone then
		self.player_enter_zone = false
		return true
	end

	if zone_name == self.assault_event_zone then
		self.play_assault_talk = false
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
		not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == self.kid_thief_grid_name and self.current_progress == self.progress_enum.idle then
		self.player_enter_grid = true

		if not self.play_line_up_routine then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.refugee_line_up, self))
		end

		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) and
		not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == self.kid_thief_grid_name then
		self.player_enter_grid = false
		return true
	end

	return false
end

-- 줄 서있는 난민들
function local_class:refugee_line_up()
	self.play_line_up_routine = true

	local food_soldier = get_character(self.food_soldier_name)

	local refugees = {}
	for i = 1, self.refugee_count do
		local refugee = get_character(self.refugee_name .. i)
		table.insert(refugees, refugee)
	end

	local kid_thief = get_character(self.kid_thief_name)
	table.insert(refugees, kid_thief)

	-- 꼬마까지 포함한 난민 인원
	local total_refugee_count = self.refugee_count + 1

	-- 군인이 난민에게 음식을 주고 음식을 들고 나가는 난민 루틴
	while self.player_enter_grid and self.cur_refugee_count > 4 do
		local first_line_up_index = total_refugee_count - self.cur_refugee_count + 1
		local first_refugee = refugees[first_line_up_index]

		character_util.set_animation_n_times(food_soldier, { name = 'release' })

		-- 음식 드랍
		local food_item = drop_item_util.create_item({ pos = food_soldier.Position,
													   target = first_refugee.Position,
													   itemid = self.food_item_id, notforinven = true,
													   lootstate = 'dontfindlooter', sprscale = 0.5 })

		wait_for_sec(0.7)

		food_item.ConsumeTarget = first_refugee
		food_item:Fly()

		-- 난민들 앞으로 이동
		for i = first_line_up_index + 1, #refugees do
			character_util.move_to(refugees[i], refugees[i - 1].Position, 0.5,
				nil, true, true)
		end

		local refugee_way_point = {
			first_refugee.Position + vector(0, 0, 2),
			first_refugee.Position + vector(-4, 0, 2),
			first_refugee.Position + vector(-4, 0, 6)
		}

		-- 나가는 난민
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			character_util.move_waypoint(first_refugee, refugee_way_point, 4)
			first_refugee.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

			wait_for_sec(2)

			character_util.spine_set_alpha_fade(first_refugee, 0, 0.5)
			wait_for_sec(0.5)

			first_refugee.ActiveState = active_state('disabled')
		end))

		wait_for_sec(0.5)

		character_util.set_direction(refugees[first_line_up_index + 1], 'left')

		self.cur_refugee_count = self.cur_refugee_count - 1
		wait_for_sec(1)
	end

	-- 특정 인원만큼 난민이 남았으면 다음 progress
	if self.cur_refugee_count <= 4 then
		-- 음식이 다 떨어졌으니 다음 보급을 기다려라.
		speech_bubble_util.show_speech_bubble_async(food_soldier, { key = 'steampunk_2_kid_thief_1' })

		self.current_progress = self.current_progress + 1

		-- 플레이어가 해당 이벤트 존 안에 있으면 실행 시켜줌
		if self.player_enter_zone then
			self.current_progress = self.current_progress + 1
			sp_util.play_normal_screenplay(self.steal_food, self)
		end
	end

	self.play_line_up_routine = false
end

-- 꼬마가 음식을 뺏음
function local_class:steal_food()
	local kid_thief = get_character(self.kid_thief_name)
	local food_soldier = get_character(self.food_soldier_name)

	local assault_soldiers = {}
	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		table.insert(assault_soldiers, assault_soldier)
	end

	camera_util.move_async(food_soldier.Position + unity_class.vector3.back, 0.5)

	music_player:PlaySfxOneShot('01_kid_boy_shout_01')
	-- 이얍!
	speech_bubble_util.show_speech_bubble(kid_thief, { key = 'steampunk_2_kid_thief_2', bubble_type = 'shout' })

	music_player:PlaySfxOneShot('01_player_jump_01')
	character_util.jump(kid_thief, 1, 0.4)
	character_util.set_anim(kid_thief, { name = 'attack', scale = 1.5 })
	-- 꼬마가 음식 주는 군인 밀침
	character_util.move_to_async(kid_thief, food_soldier.Position + 0.5 * unity_class.vector3.back,
		0.4, nil, true)

	character_util.remove_anim(kid_thief)
	camera_util.shake(0.4, 0.2)

	for i = 1, self.refugee_count do
		local refugee = get_character(self.refugee_name .. i)
		character_util.set_direction(refugee, 'left')
		character_util.set_emotion(refugee, { name = 'surprise' })
	end

	local fx_hit_pool = unity_object_pool.GetOrCreate('FX_hit')
	fx_hit_pool:Instantiate(food_soldier.Position)

	character_util.spine_damage_squish_default(food_soldier)
	character_util.spine_damage_red_pulse(food_soldier)
	music_player:PlaySfxOneShot('01_trip_01')
	character_util.set_anim(food_soldier, { name = 'prostrate' })

	-- 군인이 음식 떨어뜨림
	local food_item = drop_item_util.create_item({ pos = food_soldier.Position,
												   target = food_soldier.Position + 2 * unity_class.vector3.left,
												   itemid = self.food_item_id, notforinven = true,
												   lootstate = 'dontfindlooter' })

	food_item.SpriteTransform.localScale = 0.5 * unity_class.vector3.one
	food_item.ShadowTransform.localScale = 0.5 * unity_class.vector3.one
	wait_for_sec(1.5)

	-- 음식 가져가는 꼬마
	character_util.move_to_async(kid_thief, food_soldier.Position + 1.5 * unity_class.vector3.left,
		nil, 7, true, true)

	food_item.ConsumeTarget = kid_thief
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '01_eat_01' })
	character_util.set_direction(kid_thief, 'left')
	character_util.set_anim(kid_thief, { name = 'eat' })
	wait_for_sec(1)

	eat_sfx:Stop()
	character_util.remove_anim(kid_thief)

	-- 도망가는 꼬마
	local kid_way_point = {
		kid_thief.Position + vector(0, 0, -4),
		kid_thief.Position + vector(-16, 0, -4)
	}

	character_util.move_waypoint(kid_thief, kid_way_point, 7, true, nil,
		nil, nil, true)

	character_util.normal_jump(assault_soldiers[1])
	character_util.normal_jump_async(assault_soldiers[2])

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	-- 저 꼬마 잡아!
	speech_bubble_util.show_speech_bubble_async(food_soldier, { key = 'steampunk_2_kid_thief_3', skip = true })

	music_player:PlaySfxOneShot('01_male_shout_01')
	character_util.set_anim(assault_soldiers[1], { name = 'attack' })
	-- 너 뭐야! 거기 서!
	speech_bubble_util.show_speech_bubble_async(assault_soldiers[1],
		{ key = 'steampunk_2_kid_thief_4', skip = true })

	character_util.remove_anim(assault_soldiers[1])

	-- 쫒아가는 군인들
	local soldier_way_points = {
		{
			assault_soldiers[1].Position + vector(0, 0, -5),
			assault_soldiers[1].Position + vector(-16, 0, -5)
		},
		{
			assault_soldiers[2].Position + vector(-2, 0, 0),
			assault_soldiers[2].Position + vector(-2, 0, -5),
			assault_soldiers[2].Position + vector(-18, 0, -5)
		}
	}

	character_util.move_waypoint(assault_soldiers[1], soldier_way_points[1], 7, true,
		nil, nil, nil, true)
	character_util.move_waypoint_async(assault_soldiers[2], soldier_way_points[2], 7, true,
		nil, nil, nil, true)

	local marker = field:GetMarker('kid_thief_assault_pos').position
	kid_thief.Position = marker
	character_util.set_anim(kid_thief, { name = 'prostrate' })
	character_util.set_emotion(kid_thief, { name = 'damaged' })

	assault_soldiers[1].Position = marker + unity_class.vector3.left
	character_util.set_direction(assault_soldiers[1], 'right')
	assault_soldiers[2].Position = marker + unity_class.vector3.right

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('kid_thief_door'))

	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		assault_soldier.Interactable:AddListener(self.cs_controller)
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.assault_routine, self))

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })
end

-- 꼬마 구출하는 이벤트
function local_class:safe_kid_thief()
	local assault_soldiers = {}
	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		assault_soldier.Interactable:RemoveRelatedEvent(self.cs_controller)
		speech_bubble_util.remove_bubble(assault_soldier)
		table.insert(assault_soldiers, assault_soldier)
	end

	local marker = field:GetMarker('kid_thief_assault_pos').position
	party_util.align_party(marker, 'down', 1, 'linear')

	-- 구타 루틴이 끝날 때까지 기다림
	while self.play_assault_routine do
		coroutine.yield(nil)
	end

	for _, v in pairs(assault_soldiers) do
		character_util.remove_anim_and_emotion(v)
		character_util.set_direction(v, 'down')
	end

	wait_for_sec(0.3)

	for _, v in pairs(assault_soldiers) do
		character_util.set_anim(v, { name = 'salute', loop = false })
	end
	music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')
	-- 충성!
	speech_bubble_util.show_speech_bubble_async(assault_soldiers[2],
		{ key = 'steampunk_2_kid_thief_7', skip = true })

	for _, v in pairs(assault_soldiers) do
		character_util.remove_anim_and_emotion(v)
	end

	-- 여긴 무슨 일이십니까?
	speech_bubble_util.show_speech_bubble_async(assault_soldiers[2],
		{ key = 'steampunk_2_kid_thief_8', skip = true })

	local player_choice = choose_util.play_choose_event({
		-- 아무것도 아니다.
		{ 'steampunk_2_kid_thief_9' },
		-- 이 꼬마는 내가 처리하겠다.
		{ 'steampunk_2_kid_thief_10' }
	}, 'release')

	if player_choice == 1 then
		character_util.set_direction(assault_soldiers[1], 'right')
		character_util.set_direction(assault_soldiers[2], 'left')

		for _, v in pairs(assault_soldiers) do
			v.Interactable:AddListener(self.cs_controller)
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.assault_routine, self))

		self.play_assault_talk = true
		self.play_assault_talk_routine = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.assault_talk_routine, self))

		self.current_progress = self.current_progress - 1
		return
	end

	-- 그럼 부탁 드리겠습니다.
	speech_bubble_util.show_speech_bubble_async(assault_soldiers[2],
		{ key = 'steampunk_2_kid_thief_11', skip = true })

	for _, v in pairs(assault_soldiers) do
		character_util.set_anim(v, { name = 'salute', loop = false })
	end
	music_player:PlaySfxOneShot('02_twohand_stomp_jump_01')
	-- 충성!
	speech_bubble_util.show_speech_bubble_async(assault_soldiers[2],
		{ key = 'steampunk_2_kid_thief_7', skip = true })

	for _, v in pairs(assault_soldiers) do
		character_util.remove_anim_and_emotion(v)
	end

	-- 밖으로 나가는 군인 2명
	local soldier_way_points = {
		{
			vector(0, 0, -0.5),
			vector(12, 0, -0.5)
		},
		{
			vector(0, 0, -0.5),
			vector(10, 0, -0.5)
		}
	}

	for k, v in pairs(assault_soldiers) do
		for i = 1, #soldier_way_points[k] do
			soldier_way_points[k][i] = v.Position + soldier_way_points[k][i]
		end

		character_util.move_waypoint(v, soldier_way_points[k], 6, true, nil,
			nil, nil, true)
	end

	wait_for_sec(wp_util.get_duration(assault_soldiers[1].Position, soldier_way_points[1], 7))

	for _, v in pairs(assault_soldiers) do
		v.ActiveState = active_state('disabled')
	end

	local kid_thief = get_character(self.kid_thief_name)
	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.remove_anim_and_emotion(kid_thief)
	character_util.set_direction(kid_thief, 'down')
	wait_for_sec(0.3)

	-- 고마워.
	speech_bubble_util.show_speech_bubble_async(kid_thief, { key = 'steampunk_2_kid_thief_12', skip = true })

	character_util.set_direction(kid_thief, 'left')
	character_util.set_anim(kid_thief, { name = 'victory_get', sfx_name = '01_small_jump_01'})
	-- 어른이 되면 나는 멋있는 의적이 될 거야!
	speech_bubble_util.show_speech_bubble_async(kid_thief, { key = 'steampunk_2_kid_thief_13', skip = true })

	character_util.remove_anim(kid_thief)
	character_util.set_direction(kid_thief, 'down')

	-- 너도 의적에 관심 있으면 연락줘.
	speech_bubble_util.show_speech_bubble_async(kid_thief, { key = 'steampunk_2_kid_thief_14', skip = true })

	yield_return_func(CS.Oak.AddSNSCoroutine, self.kid_thief_follow_id)

	-- 여기 내 페이스 브레이커야.
	speech_bubble_util.show_speech_bubble_async(kid_thief, { key = 'steampunk_2_kid_thief_15', skip = true })

	-- 의적에 관심이 생겼어?
	kid_thief.Interactable.Talk = 'steampunk_2_kid_thief_16'
end

-- 구타하는 연출 루틴
function local_class:assault_routine()
	local assault_soldiers = {}
	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		table.insert(assault_soldiers, assault_soldier)
	end

	local kid_thief = get_character(self.kid_thief_name)

	local current_soldier_index = 1

	wait_for_sec(0.5)

	self.play_assault_routine = true

	while self.current_progress == self.progress_enum.steal_food do
		current_soldier_index = current_soldier_index == 1 and 2 or 1
		local cur_soldier = assault_soldiers[current_soldier_index]
		local offset = current_soldier_index == 1 and 1 or -1

		-- 때리는 연출
		character_util.spine_deviate_local(cur_soldier,
			vector(0.5 * offset, 0, 0), 0.3, 0.2)
		character_util.set_anim(cur_soldier, { name = 'attack', loop = false })
		wait_for_sec(0.3)

		character_util.remove_anim(cur_soldier)

		-- 꼬마 피격 연출
		local fx_hit_pool = unity_object_pool.GetOrCreate('FX_hit')
		fx_hit_pool:Instantiate(kid_thief.Position)
		music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = kid_thief })

		character_util.shake(kid_thief, 0.04, 0.2)
		character_util.spine_damage_squish_default(kid_thief)
		character_util.spine_damage_red_pulse(kid_thief)
		character_util.spine_deviate_local(kid_thief,
			vector(0.5 * offset, 0, 0), 0.3, 0.2)
		wait_for_sec(0.8)
	end

	self.play_assault_routine = false
end

-- 군인이 꼬마 때리면서 하는 반복 대사
function local_class:assault_talk_routine()
	local assault_soldiers = {}
	for i = 1, 2 do
		local assault_soldier = get_character(self.assault_soldier_name .. i)
		table.insert(assault_soldiers, assault_soldier)
	end

	while true do
		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })
		-- 어린 녀석이 벌써부터 도둑질이나 하고 말이야!
		speech_bubble_util.show_speech_bubble_async(assault_soldiers[1],
			{ key = 'steampunk_2_kid_thief_5', bubble_type = 'shout' })

		if not self.play_assault_talk then
			self.play_assault_talk_routine = false
			break
		end

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })
		-- 감히 제국군한테 덤벼?
		speech_bubble_util.show_speech_bubble_async(assault_soldiers[2],
			{ key = 'steampunk_2_kid_thief_6', bubble_type = 'shout' })

		if not self.play_assault_talk then
			self.play_assault_talk_routine = false
			break
		end

		wait_for_sec(2)

		if not self.play_assault_talk then
			self.play_assault_talk_routine = false
			break
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
