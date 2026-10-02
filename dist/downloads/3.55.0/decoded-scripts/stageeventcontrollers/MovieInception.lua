local local_class = newclass("MovieInceptionController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.cobb_out_name = 'inception_mobb_out'
	self.cobb_in_name = 'inception_mobb'

	self.saito_out_name = 'inception_saido_out'
	self.saito_in_name = 'inception_saido'

	self.machine_out_name = 'inception_machine_out'
	self.machine_in_name = 'inception_machine_'

	self.exit_name = 'inception_manhole_'

	self.coffee_shop_name = 'inception_coffeshop_in'

	self.first_diary_name = 'inception_first_diary'
	self.second_diary_name = 'inception_second_diary'

	self.first_diary_marker_name = 'inception_first_diary_pos'
	self.second_diary_marker_name = 'inception_second_diary_pos'

	self.top_name = 'inception_top'

	self.tint_key = 'inception'

	self.right_route = {
		'right', 'right', 'dream',
		'left', 'left', 'dream',
		'left', 'dream'
	}

	self.current_route_index = 0

	-- 시작하는 위치 지정
	self.start_room_in_floor = {
		2, 5, 4, 1
	}

	-- 각 방의 시작 기준점
	self.center_pos_in_room = {
		vector(-4, 0, -72.5),
		vector(14.5, 0, -72.5),
		vector(37, 0, -72.5),
		vector(60.5, 0, -72.5),
		vector(83.5, 0, -72.5),
	}

	self.current_floor = 0
	self.current_room = 0

	self.is_seen_help_talk = false

	self.is_seen_cobb_sleep = false

	self.leaving_without_move = false

	self.first_diary_item = nil
	self.second_diary_item = nil

	self.is_already_got_star_piece = false

	self.is_saito_cobb_talked = false

	self.party_members = nil

	self.is_jumping = false

	self.is_cobb_mumbled = false

	self.is_seen_dream_once = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
end

function local_class:on_load_resource_routine()
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	local exits = {
		get_field_object(self.exit_name .. 2),
		get_field_object(self.exit_name .. 3),
		get_field_object(self.exit_name .. 4),
		get_field_object(self.exit_name .. 5),
	}

	local machine_out = get_field_object(self.machine_out_name)

	local machines_in = {
		get_field_object(self.machine_in_name .. 3),
		get_field_object(self.machine_in_name .. 4),
	}

	local saito_out = get_character(self.saito_out_name)
	local cobb_out = get_character(self.cobb_out_name)
	local top = get_field_object(self.top_name)

	for _, v in pairs(exits) do
		v.Interactable = CS.Oak.NonInteractable.Instance
	end

	for _, v in pairs(machines_in) do
		v.Interactable = CS.Oak.NonInteractable.Instance
	end

	machine_out.Interactable = CS.Oak.NonInteractable.Instance

	if lua_helper.type_compare(saito_out.Interactable, CS.Oak.NPCInteractable) then
		saito_out.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(cobb_out.Interactable, CS.Oak.NPCInteractable) then
		cobb_out.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.cobb_talk_coroutine ~= nil then
		stop_coroutine(self.cobb_talk_coroutine)
		local cobb_in = get_character(self.cobb_in_name)
		speech_bubble_util.remove_bubble(cobb_in)
		character_util.remove_anim_and_emotion(cobb_in)
	end

	if self.first_diary_item ~= nil then
		self.first_diary_item:ConsumeComplete()
	end
	if self.second_diary_item ~= nil then
		self.second_diary_item:ConsumeComplete()
	end

	local first_diary = get_field_object(self.first_diary_name)
	local second_diary = get_field_object(self.second_diary_name)

	first_diary.Interactable = CS.Oak.NonInteractable.Instance
	second_diary.Interactable = CS.Oak.NonInteractable.Instance

	top.Holdable = CS.Oak.NonHoldable.Instance

	self:stop_top_spin()

	self.spin_sfx = nil
	self.right_route = nil
	self.start_room_in_floor = nil
	self.center_pos_in_room = nil
	self.party_members = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		local machine_out = get_field_object(self.machine_out_name)
		local cobb_out = get_character(self.cobb_out_name)
		local saito_out = get_character(self.saito_out_name)
		local first_diary = get_field_object(self.first_diary_name)
		local second_diary = get_field_object(self.second_diary_name)
		local top = get_field_object(self.top_name)

		if lua_helper.reference_equals(e.Target, machine_out) then
			sp_util.play_normal_screenplay(self.try_get_sleep, self)

		elseif lua_helper.reference_equals(e.Target, cobb_out) then
			if not self.is_seen_cobb_sleep then
				sp_util.play_normal_screenplay(self.cobb_first_meet, self)
			else
				sp_util.play_normal_screenplay(self.try_get_sleep, self)
			end

		elseif lua_helper.reference_equals(e.Target, saito_out) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.saito_show_ways_while_sleeping, self))

		elseif lua_helper.reference_equals(e.Target, first_diary) then
			sp_util.play_normal_screenplay(function()
				self:stop_cobb_talk()
				field_ui_util.show_narration_async({ key = 'movie_3_inception_45'})
				self:play_cobb_talk_func(self.cobb_says_about_time, self)
			end)

		elseif lua_helper.reference_equals(e.Target, second_diary) then
			sp_util.play_normal_screenplay(function()
				self:stop_cobb_talk()
				field_ui_util.show_narration_async({ key = 'movie_3_inception_46'})
				self:play_cobb_talk_func(self.cobb_says_about_fault, self)
			end)

		elseif lua_helper.reference_equals(e.Target, top) then
			sp_util.play_normal_screenplay(self.try_spin_top, self)

		elseif string.find(e.Target.Name, self.machine_in_name) then
			sp_util.play_normal_screenplay(self.try_move_to_next_dream, self, e.Target)

		elseif string.find(e.Target.Name, self.exit_name) then
			sp_util.play_normal_screenplay(self.try_to_wake_up, self, e.Target)
		end

	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader)
				and not self.leaving_without_move and string.find(e.CameraGrid.name, 'inception')then

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.try_move_to_other_room, self))
		end

	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == 'inception_cobb_talk' and not self.is_cobb_mumbled and not self.is_already_got_star_piece then
				self.is_cobb_mumbled = true
				speech_bubble_util.show_speech_bubble(get_character(self.cobb_out_name),
						{key = 'movie_3_inception_0_0'})

			elseif e.Zone.Name == 'inception_jump_zone' and not self.is_jumping then
				self.is_jumping = true
				self:toggle_subscribe_grid_event(false)
				sp_util.play_normal_screenplay(self.cobb_meet_saito_in_dream, self)
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.HoldUpEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object(self.top_name)) then
			self:stop_top_spin()
		end

	elseif lua_helper.type_compare(e, CS.Oak.ThrowEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object(self.top_name)) then
			self:start_top_spin()
		end

	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self.is_already_got_star_piece = stage_progress:HasStarPiece('inception_star_piece')

		if self.is_already_got_star_piece then
			local cobb_out = get_character(self.cobb_out_name)
			local saito_out = get_character(self.saito_out_name)
			character_util.set_active_state(cobb_out, 'disabled')
			character_util.set_active_state(saito_out, 'disabled')

			self:set_top_to_real()
		else
			self:setting()
		end
	end

	return false
end

function local_class:setting()
	local exits = {
		get_field_object(self.exit_name .. 2),
		get_field_object(self.exit_name .. 3),
		get_field_object(self.exit_name .. 4),
		get_field_object(self.exit_name .. 5),
	}

	local machines_in = {
		get_field_object(self.machine_in_name .. 3),
		get_field_object(self.machine_in_name .. 4),
	}
	local saito_out = get_character(self.saito_out_name)
	local cobb_out = get_character(self.cobb_out_name)

	for _, v in pairs(exits) do
		v.Interactable = CS.Oak.PublishInteractable.Create()
	end

	for _, v in pairs(machines_in) do
		v.Interactable = CS.Oak.PublishInteractable.Create()
	end

	if lua_helper.type_compare(saito_out.Interactable, CS.Oak.NPCInteractable) then
		saito_out.Interactable:AddListener(self.cs_controller)
	end
	if lua_helper.type_compare(cobb_out.Interactable, CS.Oak.NPCInteractable) then
		cobb_out.Interactable:AddListener(self.cs_controller)
	end

	local first_diary = get_field_object(self.first_diary_name)
	local second_diary = get_field_object(self.second_diary_name)

	first_diary.Interactable = CS.Oak.PublishInteractable.Create()
	second_diary.Interactable = CS.Oak.PublishInteractable.Create()

	first_diary.Position = field:GetMarker(self.first_diary_marker_name).position
	second_diary.Position = field:GetMarker(self.second_diary_marker_name).position

	self.first_diary_item = drop_item_util.create_item({pos = first_diary.Position,
														itemid = 20022, lootstate = 'dontfindlooter',
														notforinven = true})
	self.second_diary_item = drop_item_util.create_item({pos = second_diary.Position,
														 itemid = 20022, lootstate = 'dontfindlooter',
														 notforinven = true})

	-- 다이어리 너무 큰 것 같아서 히트박스 0.7x0.7로
	first_diary.Hitbox = CS.Oak.Hitbox(unity_class.vector3.one * 0.7)
	second_diary.Hitbox = CS.Oak.Hitbox(unity_class.vector3.one * 0.7)
end

function local_class:try_get_sleep()
	local result = choose_util.play_choose_event(
			{{'movie_3_inception_talk_branch_5_1', 'intellect'},
			 {'movie_3_inception_talk_branch_5_2', 'normal'}})

	if result == 1 then
		if self.is_seen_dream_once then
			yield_return_func(self.move_to_bed, self, user_party.Leader, vector(72, 0.5, 49.8), 'right', true)
			yield_return_func(self.get_sleep, self)
		else
			self.is_seen_dream_once = true

			yield_return_func(self.move_to_bed, self, user_party.Leader, vector(72, 0.5, 49.8), 'right', true)

			local machine_out = get_field_object(self.machine_out_name)
			music_player:PlaySfxOneShot('02_bomb_deactivate_01')
			machine_out:Shake(0.04, 3)

			music_player:PlaySfxOneShot('01_fade_out_02')
			music_player_util.play_stage_music({state = 'muted', mix = 2})

			screen_util.fade_out_async(3, unity_class.color.black, 'linear')

			self.current_floor = 1
			self.current_room = self.start_room_in_floor[self.current_floor]
			self.current_route_index = 0

			self:toggle_party_members(false)

			yield_return_func(self.teleport_party_to_room, self)

			local cobb_in = get_character(self.cobb_in_name)

			self:toggle_cobb_in_party(true)

			field_ui_manager:Show()

			coroutine.yield()

			field_ui_manager:Hide()

			character_util.stop(cobb_in)
			cobb_in.Position = user_party.Leader.Position + vector(1.5, 0, 0)

			character_util.set_direction(cobb_in, 'left')
			character_util.remove_anim_and_emotion(user_party.Leader)

			music_player_util.play_stage_music({name = 'bgm_cave_main', state = 'event', mix = 2})
			screen_util.fade_in_async(3, unity_class.color.black, 'linear')

			self:toggle_subscribe_grid_event(true)

			yield_return_func(self.cobb_says_about_dream_at_first_time, self)
		end
	end
end

function local_class:get_sleep()
	local machine_out = get_field_object(self.machine_out_name)
	music_player:PlaySfxOneShot('02_bomb_deactivate_01')
	machine_out:Shake(0.04, 3)

	music_player:PlaySfxOneShot('01_fade_out_02')
	music_player_util.play_stage_music({state = 'muted', mix = 2})

	screen_util.fade_out_async(3, unity_class.color.black, 'linear')

	self:toggle_party_members(false)

	self:toggle_cobb_in_party(true)

	coroutine.yield()

	party_util.reset_controllers()
	party_util.stop_and_disable_control()

	self.current_floor = 1
	self.current_room = self.start_room_in_floor[self.current_floor]
	self.current_route_index = 0

	yield_return_func(self.teleport_party_to_room, self)

	music_player_util.play_stage_music({name = 'bgm_cave_main', state = 'event', mix = 2})
	screen_util.fade_in_async(3, unity_class.color.black, 'linear')

	self:toggle_subscribe_grid_event(true)
end

function local_class:toggle_cobb_in_party(in_party)
	local cobb_in = get_character(self.cobb_in_name)

	if in_party then
		character_util.convert_to_party_member(cobb_in, user_party, true)
	else
		character_util.convert_to_npc(cobb_in)
	end
end

function local_class:toggle_party_members(in_party)
	if in_party then
		if self.party_members == nil then return end

		for _, v in pairs(self.party_members) do
			character_util.convert_to_party_member(v, user_party, false)
		end

		self.party_members = nil

	else
		self.party_members = {}

		for i = 1, user_party.Count - 1 do
			table.insert(self.party_members, user_party[i])
		end

		for _, v in pairs(self.party_members) do
			character_util.convert_to_npc(v)
		end
	end
end

function local_class:toggle_subscribe_grid_event(active)
	if active then
		self.leaving_without_move = false
	else
		self.leaving_without_move = true
	end
end

function local_class:try_move_to_next_dream(machine)
	-- 더 깊은 꿈에 들어간다. / 그만 둔다.
	local result = choose_util.play_choose_event(
			{{'movie_3_inception_47', 'intellect'}, {'movie_3_inception_48', 'normal'}})

	if result == 1 then
		local is_right_way, was_1st_floor = self:check_go_right_way('dream')

		self:stop_cobb_talk()

		if is_right_way then
			yield_return_func(self.move_to_next_dream, self, machine)
		else
			if was_1st_floor then
				yield_return_func(self.reset_from_1st_floor, self, machine)
				self:play_cobb_talk_func(self.cobb_says_about_wrong_machine_first_floor, self)
			else
				yield_return_func(self.reset_to_1st_floor, self, machine)
				self:play_cobb_talk_func(self.cobb_says_about_wrong_machine_upper_floor, self)
			end
		end
	end
end

function local_class:try_move_to_other_room()
	local route = self.center_pos_in_room[self.current_room].x < user_party.Leader.Position.x
			and 'right' or 'left'

	local is_right_way, was_1st_floor = self:check_go_right_way(route)
	if not is_right_way then
		party_util.stop_and_disable_control()
		field_ui_manager:Hide()

		if was_1st_floor then
			yield_return_func(self.reset_from_1st_floor, self)
			self:play_cobb_talk_func(self.cobb_says_about_wrong_way_first_floor, self)
		else
			yield_return_func(self.reset_to_1st_floor, self)
			self:play_cobb_talk_func(self.cobb_says_about_wrong_way_upper_floor, self)
		end

		field_ui_manager:Show()
		party_util.reset_controllers()
	end
end

-- 정보 세팅된 후에 움직여야함
function local_class:teleport_party_to_room()
	self:setting_floor()
	party_util.remove_emotion()
	party_util.remove_animation()
	--character_util.remove_anim_and_emotion(user_party.Leader)
	party_util.position_party(self.center_pos_in_room[self.current_room], 'right')
	camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})
end

-- 맞는 길로 가고 있는지와 원래 1층이었는지 아닌지 반환
function local_class:check_go_right_way(way)
	if self.right_route[self.current_route_index + 1] == way then
		-- 맞는 길이면 현재 위치 정보 수정

		self.current_route_index = self.current_route_index + 1
		if way == 'dream' then
			self.current_floor = self.current_floor + 1
			self.current_room = self.start_room_in_floor[self.current_floor]

		elseif way == 'right' then
			self.current_room = self.current_room + 1
		elseif way == 'left' then
			self.current_room = self.current_room - 1
		end

		return true
	else
		-- 틀리면 1층 첫 방으로 초기화

		local is_1st_floor = self.current_floor == 1

		self.current_route_index = 0
		self.current_floor = 1
		self.current_room = self.start_room_in_floor[self.current_floor]

		return false, is_1st_floor
	end
end

-- 다음 꿈으로 넘어감
function local_class:move_to_next_dream(machine)
	self:toggle_subscribe_grid_event(false)

	music_player:PlaySfxOneShot('02_bomb_deactivate_01')
	machine:Shake(0.04, 2)

	music_player:PlaySfxOneShot('01_fade_out_02')
	wait_all({
		util.cs_generator(self.party_seat_to_sleep, self),
		util.cs_generator(screen_util.fade_out_async, 2, unity_class.color.black, 'linear')
	})

	machine:CancelShake()

	yield_return_func(self.teleport_party_to_room, self)

	wait_for_sec(0.3)

	screen_util.fade_in_async(2, unity_class.color.black, 'linear')

	self:toggle_subscribe_grid_event(true)
end

-- 2층 이상에서 1층으로 원위치
-- machine은 현재 사용한 기계(nil이면 기계 사용이 아님)
function local_class:reset_to_1st_floor(machine)
	self:toggle_subscribe_grid_event(false)

	if machine ~= nil then
		music_player:PlaySfxOneShot('02_bomb_deactivate_01')
		machine:Shake(0.04, 1.5)
		wait_for_sec(1)
	end

	music_player:PlaySfxOneShot('01_fade_out_02')
	screen_util.fade_out_async(0.3, unity_class.color.white, 'linear')

	yield_return_func(self.teleport_party_to_room, self)

	local cobb_in = get_character(self.cobb_in_name)
	party_util.set_anim({name = 'prostrate', loop = true})
	party_util.set_emotion({name = 'sleep'})
	character_util.set_emotion(cobb_in, {name = 'sleep_deep'})

	wait_for_sec(1)

	screen_util.fade_in_async(0.3, unity_class.color.white, 'linear')

	yield_return_func(self.party_waking_up, self)

	self:toggle_subscribe_grid_event(true)
end

-- 1층에서 1층 첫번째 위치로 원위치
-- machine은 현재 사용한 기계(nil이면 기계 사용이 아님)
function local_class:reset_from_1st_floor(machine)
	self:toggle_subscribe_grid_event(false)

	if machine ~= nil then
		music_player:PlaySfxOneShot('02_bomb_deactivate_01')
		machine:Shake(0.04, 1.5)
		wait_for_sec(1)
	end

	music_player:PlaySfxOneShot('01_fade_out_02')
	screen_util.fade_out_async(0.3, unity_class.color.white, 'linear')

	party_util.remove_animation()
	party_util.remove_emotion()

	yield_return_func(self.teleport_party_to_room, self)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.3, unity_class.color.white, 'linear')

	self:toggle_subscribe_grid_event(true)
end

function local_class:try_to_wake_up(manhole)
	-- 꿈에서 깬다. / 그만 둔다.
	local result = choose_util.play_choose_event(
			{{'movie_3_inception_49', 'intellect'}, {'movie_3_inception_50', 'normal'}})

	if result == 1 then
		self:stop_cobb_talk()

		self:toggle_cobb_in_party(false)

		local fall_dur = 1
		local is_left = user_party.Leader.Position.x > manhole.Position.x

		character_util.set_direction(user_party.Leader, is_left and 'left' or 'right')
		character_util.set_emotion(user_party.Leader, {name = 'damaged'})
		--character_util.set_anim(user_party.Leader, {name = 'embarrassed'})

		character_util.move_to(user_party.Leader, manhole.Position + vector(0, 0, -0.3), fall_dur)
		user_party.Leader.SpineController:Scale(unity_class.vector3.one * 0.3, fall_dur)
		character_util.spine_rotate(user_party.Leader, 360 * 3, fall_dur)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			wait_for_sec(fall_dur / 2)
			character_util.spine_set_alpha_fade(user_party.Leader, 0, fall_dur / 2)
		end))

		yield_return_func(self.wake_up, self)
	end
end

-- setting_func에 페이드 아웃 된 동안 실행할 함수 넣음
function local_class:wake_up(setting_func)
	self:toggle_subscribe_grid_event(false)

	music_player:PlaySfxOneShot('01_fade_out_02')

	music_player_util.play_stage_music({state = 'muted', mix = 2})

	screen_util.fade_out_async(2, unity_class.color.black, 'linear')

	field:RemoveTint(self.tint_key, 0)
	character_util.spine_rotate(user_party.Leader, 0, 0)
	user_party.Leader.SpineController:Scale(unity_class.vector3.one, 0)
	character_util.set_position(user_party.Leader, vector(72, 0.5, 49.8))
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim(user_party.Leader, {name = 'seat', loop = true})
	character_util.set_emotion(user_party.Leader, {name = 'sleep', loop = true})
	character_util.spine_set_alpha_fade(user_party.Leader, 1, 0)

	self:toggle_party_members(true)

	if setting_func ~= nil then
		setting_func(self)
	end

	wait_for_sec(0.5)

	music_player_util.play_stage_music({state = 'field', mix = 2})

	screen_util.fade_in_async(2, unity_class.color.black, 'linear')

	character_util.set_emotion(user_party.Leader, {name = 'tired', loop = true})

	wait_for_sec(1)

	character_util.remove_emotion(user_party.Leader)

	wait_for_sec(1)

	character_util.move_to(user_party.Leader, user_party.Leader.Position + vector(0, 0, -1),
			0.3, nil, false, false, false)
	character_util.remove_anim(user_party.Leader)
	music_player:PlaySfxOneShot('01_jump_01')
	character_util.mario_jump_async(user_party.Leader, 'right')

	self:toggle_party_members(true)
end

function local_class:toggle_diary(num, is_enabled)
	if num == 1 then
		local first_diary = get_field_object(self.first_diary_name)

		if is_enabled then
			character_util.set_active_state(first_diary, 'enabled')
			self.first_diary_item.Position = first_diary.Position + vector(0, 0.1, 0)
		else
			character_util.set_active_state(first_diary, 'disabled')
			self.first_diary_item.Position = vector(999, 0, 999)
		end

	elseif num == 2 then
		local second_diary = get_field_object(self.second_diary_name)

		if is_enabled then
			character_util.set_active_state(second_diary, 'enabled')
			self.second_diary_item.Position = second_diary.Position + vector(0, 0.1, 0)
		else
			character_util.set_active_state(second_diary, 'disabled')
			self.second_diary_item.Position = vector(999, 0, 999)
		end
	end
end

function local_class:setting_floor()
	self:toggle_diary(1, false)
	self:toggle_diary(2, false)

	local table = {
		unity_color({0.9451, 0.8627, 1}),
		unity_color({0.8863, 0.7255, 1}),
		unity_color({0.8196, 0.5843, 1}),
		unity_color({0.7412, 0.4431, 1}),
	}

	local normal = (self.current_floor / 20)
	local red = 0.55 * normal
	local blue = 1 * normal

	if self.current_floor >= 1 and self.current_floor <= #table then
		field:Tint(self.tint_key, table[self.current_floor], 0)
	end

	if self.current_floor == 0 then

	elseif self.current_floor == 1 then
		self:disable_dream_objects(1)

	elseif self.current_floor == 2 then
		self:toggle_diary(1, true)
		self:disable_dream_objects(2)

	elseif self.current_floor == 3 then
		self:toggle_diary(2, true)
		self:disable_dream_objects(3)

	elseif self.current_floor == 4 then

	end
end

-- 활성화할 층의
function local_class:disable_dream_objects(index)
	for i = 2, 5 do
		for j = 2, index do 	-- 1층의 오브젝트들은 항상 존재해야 함
			stage_util.set_fo_active_state('dream_' .. i .. '_' .. j, 'enabled')
		end

		for j = index + 1, 3 do
			stage_util.set_fo_active_state('dream_' .. i .. '_' .. j, 'disabled')
		end
	end
end

--코브랑 처음 말을 걸었을 때 연출
function local_class:cobb_first_meet()
	user_party:StopAndDisableControl()

	local cobb_out = get_character(self.cobb_out_name)
	speech_bubble_util.remove_bubble(cobb_out)

	character_util.align_party(cobb_out, 'left', 1, 'arc')

	if not self.is_seen_help_talk then
		self.is_seen_help_talk = true

		speech_bubble_util.show_speech_bubble_async(cobb_out,
						{key = 'movie_3_inception_0_0', skip = true})

		character_util.show_emoticon_async(user_party.Leader, nil, 'question')

		character_util.remove_anim_and_emotion(cobb_out)

		character_util.set_anim(cobb_out, {name = 'release', loop = true, sfx_name = '01_swing_01'})
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_4', skip = true})
		character_util.remove_anim_and_emotion(cobb_out)

		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_4_0', skip = true})

		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_4_1', skip = true})

		--사이도 씨가 꿈 속에 꿈 속에 꿈 속에 꿈. 림보에 갇혀버렸어.
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_5', skip = true})

		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_5_0', skip = true})

		--선택지 잠에서 깨면?
		local result_1 = choose_util.play_choose_event(
				{{'movie_3_inception_talk_branch_1_1', 'intellect'},
				 {'movie_3_inception_talk_branch_1_2', 'forced'},
				 {'movie_3_inception_talk_branch_1_3', 'brutal'}})

		if result_1 == 1 then
			--림보에 갇히면 빠져 나올 방법은 하나밖에 없어.
			character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_6', skip = true})

			--우리가 직접 그 꿈 속에 들어가서 깨워주는 것.
			character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_7', skip = true})

			--하지만 나 혼자서는 구할 수 없어.
			character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'tired', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_8', skip = true})

			--네가 날 도와주면 나도 보답을 할게. 어때?
			character_util.set_anim(cobb_out, {name = 'question', loop = false, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_9', skip = true})

		else
			--그런 태평한 소리를 할 때가 아니야!
			music_player:PlaySfxOneShot('03_dialogue_negative_02')
			character_util.set_anim(cobb_out, {name = 'bomb_idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'attack', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_10', skip = true})

			--이대로 림보에서 빠져 나오지 못하면...
			character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_11', skip = true})

			--사이도 씨는 영원히 잠들어 버려.
			character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'tired', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_12', skip = true})

			--네가 날 도와주면 나도 보답을 할게. 어때?
			character_util.set_anim(cobb_out, {name = 'question', loop = false, scale = 1})
			character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
			speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_9', skip = true})

		end
	else
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_13_0', skip = true})
	end

	--선택지 도와준다 / 안 도와준다
	local result_2 = choose_util.play_choose_event(	{{'movie_3_inception_talk_branch_2_1', 'mercy'},
														{'movie_3_inception_talk_branch_2_2', 'brutal'}})

	if result_2 == 1 then
		self.is_seen_cobb_sleep = true

		--좋아.
		character_util.set_anim(cobb_out, {name = 'nod', loop = true, scale = 1})
		character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_13', skip = true})

		--그럼 당장 사이도 씨의 꿈 속으로 들어가자.
		character_util.set_anim(cobb_out, {name = 'release', loop = true, scale = 1, sfx_name = '01_swing_01'})
		character_util.set_emotion(cobb_out, {name = 'idle', loop = true})
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_14', skip = true})

		character_util.remove_anim_and_emotion(cobb_out)

		get_field_object(self.machine_out_name).Interactable = CS.Oak.PublishInteractable.Create()

		-- 코브 잠에 듦
		yield_return_func(self.move_to_bed, self, cobb_out, vector(73, 0.5, 49.8), 'left', false)

		local machine_out = get_field_object(self.machine_out_name)
		music_player:PlaySfxOneShot('02_bomb_deactivate_01')
		machine_out:Shake(0.04, 1)

		wait_for_sec(0.1)

	else
		--그래. 꿈 속에 들어간다는 게 무서울지도 모르지.
		character_util.set_anim(cobb_out, {name = 'idle', loop = true, scale = 1})
		character_util.set_emotion(cobb_out, {name = 'tired', loop = true})
		speech_bubble_util.show_speech_bubble_async(cobb_out, {key = 'movie_3_inception_15', skip = true})
		character_util.remove_anim_and_emotion(cobb_out)
	end
end

function local_class:move_to_bed(character, sleep_pos, seat_dir, is_just_sleep)
	character_util.move_to_async(character, sleep_pos - vector(0, 0.5, 0.5),
			nil, 3, true, true, true)
	character_util.set_direction(character, seat_dir)

	wait_for_sec(0.1)

	character_util.move_to(character, sleep_pos,
			0.3, nil, false, false, false)

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.mario_jump_async(character, seat_dir, 0.3, 0.5)

	character_util.set_anim(character, {name = 'meditation', loop = true})

	wait_for_sec(0.3)

	character_util.set_emotion(character, {name = 'tired'})

	wait_for_sec(0.7)

	if is_just_sleep then
		character_util.set_emotion(character, {name = 'sleep'})
	else
		character_util.set_emotion(character, {name = 'sleep_deep'})
	end
end

function local_class:party_seat_to_sleep()
	local cobb_in = get_character(self.cobb_in_name)

	party_util.set_direction('right')
	party_util.set_anim({name = 'meditation', loop = true, mix_duration = 0.3})

	wait_for_sec(0.2)

	party_util.set_emotion({name = 'tired'})

	wait_for_sec(0.5)

	character_util.set_emotion(user_party.Leader, {name = 'sleep'})
	character_util.set_emotion(cobb_in, {name = 'sleep_deep'})
end

-- 파티원들 prostrate, sleep 상태에서 원래대로 변하는 연출
function local_class:party_waking_up()
	music_player_util.play_sfx({sfx_name = '01_sleep_01', duration = 2})

	wait_for_sec(1)

	party_util.set_emotion({name = 'tired'})

	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_rustle_01')

	party_util.remove_emotion()
	party_util.remove_animation()
end

--모브와 처음 꿈으로 들어갔을 때 연출.
function local_class:cobb_says_about_dream_at_first_time()
	local cobb_in = get_character(self.cobb_in_name)

	character_util.set_emotion(user_party.Leader, {name = 'surprise'})
	wait_for_sec(0.8)

	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(user_party.Leader, 'left')

	wait_for_sec(0.8)

	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(user_party.Leader, 'right')

	wait_for_sec(0.8)

	character_util.remove_emotion(user_party.Leader)

	--이 곳이 사이도 씨의 첫 번째 꿈이야.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_16', skip = true})

	--꿈 속 세상은 바깥 세상과는 달라.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_17', skip = true})

	-- 현실에서 불가능 한 일들이 일어나지
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_18', skip = true})

	-- 올바른 길을 알아내지 못하면 다음 꿈으로 들어갈 수 없어.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_19', skip = true})

	-- 어딘가 단서가 있을거야.
	character_util.set_anim(cobb_in, {name = 'question', loop = false})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_22', skip = true})

	character_util.remove_anim_and_emotion(cobb_in)

	--꿈 밖에 있을 수도 있고, 꿈 속에 있을 수도 있어.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_23', skip = true})

	character_util.remove_anim_and_emotion(cobb_in)
end

function local_class:play_cobb_talk_func(func, arg_self)
	self:stop_cobb_talk()

	self.cobb_talk_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(func, arg_self))
end

function local_class:stop_cobb_talk()
	if self.cobb_talk_coroutine ~= nil then
		stop_coroutine(self.cobb_talk_coroutine)
		local cobb_in = get_character(self.cobb_in_name)
		speech_bubble_util.remove_bubble(cobb_in)
		character_util.remove_anim_and_emotion(cobb_in)
		self.cobb_talk_coroutine = nil
	end
end

-- 2층 다이어리에 인터랙트 시
function local_class:cobb_says_about_time()
	local cobb_in = get_character(self.cobb_in_name)

	--현실의 1초가 림보에서는 약 20일이야.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_51'})

	--사이도 씨가 림보에 빠진 지 20분 정도 지났을 테니까...
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_52'})

	--60년을 넘는 시간을 보낸거야.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_53'})
end

-- 3층 다이어리에 인터랙트 시
function local_class:cobb_says_about_fault()
	local cobb_in = get_character(self.cobb_in_name)

	--꿈 여행 중의 사고는 모두 내 책임이야.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_54'})

	--내가 사이도 씨를 구해내야만 해.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_55'})
end

--1단계 꿈에서 잘못된 길을 들었을 때 코브 연출
function local_class:cobb_says_about_wrong_way_first_floor()
	local cobb_in = get_character(self.cobb_in_name)

	--처음으로 돌아와 버렸군.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_42'})

	--잘못된 길이었어.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_43'})
end

--2단계 이상의 꿈에서 잘못된 길을 들었을 때 코브 연출
function local_class:cobb_says_about_wrong_way_upper_floor()
	local cobb_in = get_character(self.cobb_in_name)

	--첫번째 꿈으로 돌아와 버렸군.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_44'})

	--잘못된 길이었어.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_43'})
end

--1단계에서 잘못된 꿈 기계를 사용했을 경우 코브 연출//위와 동일
function local_class:cobb_says_about_wrong_machine_first_floor()
	local cobb_in = get_character(self.cobb_in_name)

	--처음으로 돌아와 버렸군.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_42'})

	--사이도 씨의 기계가 아니었어...
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_21'})
end

--2단계 이상의 꿈에서 잘못된 꿈 기계를 사용했을 경우 코브 연출
function local_class:cobb_says_about_wrong_machine_upper_floor()
	local cobb_in = get_character(self.cobb_in_name)

	--첫번째 꿈으로 돌아와 버렸군.
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_44'})

	--사이도 씨의 기계가 아니었어...
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_21'})
end

function local_class:jump_to_door(character)
	local jump_tile = get_field_object('inception_jump_tile')
	local jump_animator = jump_tile.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	jump_animator.speed = 0.5
	jump_animator:Play('on')

	local target_pos = vector(-9, 4.5, -74.5)

	character_util.remove_anim(character)

	music_player:PlaySfxOneShot('03_jumptile_01')
	character_util.move_to(character, vector_util.get_x0z(target_pos),
			nil, 13 / 1.1, true, false, false)
	character_util.jump(character, 5, 1)
	character_util.set_anim(character, {name = 'jump', loop = false, scale = 0.7})

	wait_for_sec(0.2)

	jump_animator:Play('off')

	wait_for_sec(0.2)

	character_util.spine_set_alpha_fade(character,  0, 0.2)

	wait_for_sec(0.3)

end

--코브가 사이도를 꿈속에서 만났을 때 연출
function local_class:cobb_meet_saito_in_dream()
	local cobb_in = get_character(self.cobb_in_name)
	local saito_in = get_character(self.saito_in_name)
	local top = get_field_object(self.top_name)
	local animator = top.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	camera_util.move(vector(-5, 0, -73), 1)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.jump_to_door, self, user_party.Leader))

	wait_for_sec(0.7)

	wait_all({
		util.cs_generator(character_util.normal_jump_async, cobb_in),
		util.cs_generator(character_util.move_to_async, cobb_in, vector(-1.5, 0, -74.5), 0.3, nil, true, true)
	})

	yield_return_func(self.jump_to_door, self, cobb_in)

	music_player:PlaySfxOneShot('01_fade_out_03')
	music_player_util.play_stage_music({state = 'muted', mix = 2})
	screen_util.fade_out_circular_async(0.5, CS.Oak.Interpolations.Linear)
	screen_util.fade_out_async(0, unity_class.color.black)

	self:toggle_subscribe_grid_event(false)

	self:toggle_cobb_in_party(false)
	character_util.remove_anim_and_emotion(cobb_in)
	character_util.remove_anim_and_emotion(user_party.Leader)

	character_util.set_position(cobb_in, vector(-39, 0.5, -70))
	character_util.set_direction(cobb_in, 'left')
	character_util.set_anim(cobb_in, {name = 'meditation', loop = true})
	top.Position = vector(-40.5, 0.4, -70)

	cobb_in.Interactable = CS.Oak.NPCInteractable.Create()
	cobb_in.Interactable.Talk = 'movie_3_inception_57'
	saito_in.Interactable.Talk = 'movie_3_inception_56'

	field:RemoveTint(self.tint_key, 0)

	party_util.position_party(vector(-39, 0, -71), 'left', 'arc')

	character_util.spine_set_alpha_fade(user_party.Leader,  1, 0)
	character_util.spine_set_alpha_fade(cobb_in,  1, 0)

	camera_util.move(vector(-5, 0, -73), 0, {end_target = user_party.Leader})

	animator:Play('top_stopped')
	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_async(2, unity_class.color.black)

	--테이블과 의자를 놓고, 의자 위에 앉혀놓고, 팽이는 테이블과 의자 앞에 위치.

	--꿈 속에서 본 남자가 저런 팽이를 가지고 있었지.
	character_util.set_emotion(saito_in, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_27_0', skip = true})

	--나는... 날 찾아올 사람을 기다리고 있다네...
	character_util.set_emotion(saito_in, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_28', skip = true})

	--반쯤 기억나는 꿈에서 만난 사람을 기다리는 거죠?
	character_util.set_emotion(cobb_in, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_28_0', skip = true})

	--모브?
	character_util.set_emotion(saito_in, {name = 'surprise', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_29', skip = true})

	--아니야... 불가능해.
	character_util.set_emotion(saito_in, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_30', skip = true})

	--우린 둘 다 젊었었는데...
	character_util.set_emotion(saito_in, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_31', skip = true})

	--나만 늙어버렸군...
	character_util.set_emotion(saito_in, {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_32', skip = true})

	--당신을 데리러 왔어요.
	character_util.set_emotion(cobb_in, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_33', skip = true})

	--이 곳 세상은 진짜가 아니에요.
	character_util.set_anim(cobb_in, {name = 'release', loop = true, scale = 1, upper = true})
	character_util.set_emotion(cobb_in, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_34', skip = true})

	--character_util.remove_emotion(cobb_in)
	character_util.remove_anim(cobb_in, true)

	--내가... 자네를 어떻게 믿지?
	character_util.set_emotion(saito_in, {name = 'idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_35', skip = true})

	--character_util.set_anim(cobb_in, {name = 'question', loop = false, upper = true})
	character_util.set_emotion(cobb_in, {name = 'tired', loop = true})

	top.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:try_spin_top()
	-- 팽이를 돌린다. / 그만 둔다.
	local result = choose_util.play_choose_event({{'movie_3_inception_talk_branch_4_1', 'intellect'},
												  {'movie_3_inception_talk_branch_4_2', 'normal'}})

	if result == 1 then
		local top = get_field_object(self.top_name)
		local animator = top.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

		top.Holdable = CS.Oak.Holdable()
		top.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		top.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()

		local dir = user_party.Leader.Position.z < top.Position.z
				and vector(0, 0, 1) or vector(0, 0, -1)

		character_util.look_at(user_party.Leader, top)
		--character_util.set_anim(user_party.Leader, {name = 'release', remove_after = 0.5})
		command_util.execute_holdup(user_party.Leader, top, user_party.Leader.Position, nil, true)

		wait_for_sec(0.5)


		command_util.execute_throw(user_party.Leader, top, dir, user_party.Leader.Position, 0, true)

		--animator:Play('top_spinning')

		local cal = CS.CalculatorFreeFall(0, CS.Oak.Constants.DefaultGravity, top.Position.y - 0.5, 0)
		local start_pos = top.Position
		local target_pos = vector(-40.5, 0.5, -70)

		self.spin_sfx = music_player_util.play_sfx({sfx_name = '01_top_01', loop = true, parent = top,
													type_priority = 'event', player_priority = 'object'})

		cal:ScaleTime(0.8)

		while not cal:IsDone() do
			cal:Proceed(unity_class.time.deltaTime)
			local progress = cal:GetProgress()
			local move_pos = unity_class.vector3.Lerp(start_pos, target_pos, progress)
			move_pos.y = cal:GetDistance() + 0.5
			top.Position = move_pos
			coroutine.yield(nil)
		end
		top.Position = target_pos

		yield_return_func(self.cobb_take_saito_out, self)
	end
end

function local_class:cobb_take_saito_out()
	local cobb_in = get_character(self.cobb_in_name)
	local saito_in = get_character(self.saito_in_name)

	character_util.remove_emotion(cobb_in)
	character_util.remove_anim(cobb_in, true)

	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_35_0', skip = true})

	wait_for_sec(2)

	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.set_emotion(saito_in, {name = 'surprise', loop = true})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_35_1', skip = true})

	character_util.set_emotion(saito_in, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(saito_in, {key = 'movie_3_inception_58', skip = true})
	character_util.remove_emotion(saito_in)

	--돌아가요.
	character_util.set_anim(cobb_in, {name = 'release', loop = true, scale = 1, upper = true, sfx_name = '01_swing_01'})
	character_util.set_emotion(cobb_in, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_36', skip = true})

	character_util.remove_emotion(saito_in)

	--둘 다 다시 젊어질 수 있어요
	character_util.set_emotion(cobb_in, {name = 'attack', loop = true})
	speech_bubble_util.show_speech_bubble_async(cobb_in, {key = 'movie_3_inception_37', skip = true})

	--사이도가 고개를 끄덕이며 페이드 아웃(흰색)
	character_util.set_anim(saito_in, {name = 'nod', loop = true, scale = 1, upper = true})
	character_util.set_emotion(saito_in, {name = 'idle', loop = true})

	local machine_out = get_field_object(self.machine_out_name)
	machine_out.Interactable = CS.Oak.NonInteractable.Instance

	local cobb_out = get_character(self.cobb_out_name)
	local saito_out = get_character(self.saito_out_name)

	self:toggle_cobb_in_party(false)

	character_util.remove_anim_and_emotion(cobb_out)
	character_util.remove_anim_and_emotion(saito_out)
	character_util.set_active_state(cobb_out, 'disabled')
	character_util.set_active_state(saito_out, 'disabled')

	get_field_object('inception_star_piece').ActiveState = active_state('enabled')

	self.is_saito_cobb_talked = true

	if self.spin_sfx ~= nil then
		self.spin_sfx:FadeOut(2)
		self.spin_sfx = nil
	end

	--방으로 돌아온다.
	--스타피스만 방에 남아있고, 사이도와 모브는 없는 상태로 엔딩.
	yield_return_func(self.wake_up, self, self.set_top_to_real)
end

-- 현실에 팽이 추가
function local_class:set_top_to_real()
	local top = get_field_object(self.top_name)
	local animator = top.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	top.Position = vector(70.5, 0, 45)
	animator:Play('top_stopped')

	top.Interactable = CS.Oak.NonInteractable.Instance
	top.Holdable = CS.Oak.Holdable()
	top.Holdable.BounceSfxHandleName = '01_top_03'
	self.is_saito_cobb_talked = true
	top.CrashBehaviour = CS.Oak.PortableCrashBehaviour()
	top.FieldObjectBehaviour = CS.Oak.HoldableObjectBehaviour()
end

function local_class:start_top_spin()
	--self:stop_top_spin()

	self.top_spin_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.top_spin_routine, self))
end

function local_class:stop_top_spin()
	if self.top_spin_coroutine ~= nil then
		stop_coroutine(self.top_spin_coroutine)
		self.top_spin_coroutine = nil
	end

	if self.spin_sfx ~= nil then
		self.spin_sfx:Stop()
		self.spin_sfx = nil
	end

	local top = get_field_object(self.top_name)
	local animator = top.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	animator:Play('top_holding')
end

function local_class:top_spin_routine()
	local top = get_field_object(self.top_name)
	local animator = top.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	animator.enabled = true

	animator:Play('top_spinning')

	if not self.is_saito_cobb_talked then return end

	self.spin_sfx = music_player_util.play_sfx({sfx_name = '01_top_02', parent = top,
												type_priority = 'event', player_priority = 'object'})

	wait_for_sec(2)

	animator:Play('top_tumbling')

	wait_for_sec(1.33)

	animator:Play('top_stopping')

	wait_for_sec(0.5)

	animator:Play('top_stopped')

	self.spin_sfx = nil

end

--잠꼬대로 사이토가 길을 알려준다.
function local_class:saito_show_ways_while_sleeping()
	local saito_out = get_character(self.saito_out_name)
	if lua_helper.type_compare(saito_out.Interactable, CS.Oak.NPCInteractable) then
		saito_out.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	--오른쪽...
	speech_bubble_util.show_speech_bubble_async(saito_out, {key = 'movie_3_inception_2'})

	--오른쪽...
	speech_bubble_util.show_speech_bubble_async(saito_out, {key = 'movie_3_inception_2'})

	--꿈...속으로...
	speech_bubble_util.show_speech_bubble_async(saito_out, {key = 'movie_3_inception_3'})

	if lua_helper.type_compare(saito_out.Interactable, CS.Oak.NPCInteractable) then
		saito_out.Interactable:AddListener(self.cs_controller)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
