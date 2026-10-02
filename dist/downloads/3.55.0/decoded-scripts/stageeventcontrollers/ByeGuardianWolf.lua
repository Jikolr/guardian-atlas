local local_class = newclass('ByeGuardianWolfController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.pet_origin_id = 13

	self.is_wolves_runaway = false

	self.is_already_got_star_piece = false

	self.head_wolf_name = "wolf_head"
	self.wolf_1_name = "wolf_1"
	self.wolf_2_name = "wolf_2"
	self.wolf_3_name = "wolf_3"
	self.wolf_4_name = "wolf_4"

	self.star_piece_name = "star_piece_2"

	self.pet_align_marker_name = "pet_align_pos"
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_load_resource_routine, self))
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
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

---[[ on event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and e.Zone.Name == "bye_wolf"
				and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not self.is_wolves_runaway and not self.is_already_got_star_piece then
				self.is_wolves_runaway = true

				local pet_index = self:get_pet_index_in_party()
				if pet_index < 0 then
					sp_util.play_normal_screenplay(self.event_without_pet, self)
				else
					sp_util.play_normal_screenplay(self.event_with_pet, self, pet_index)
				end
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self.is_already_got_star_piece = stage_progress:HasStarPiece(self.star_piece_name)
		if self.is_already_got_star_piece then
			self:set_wolves_position_to_disappear()
		end
	end

	return false
end
---]]

function local_class:event_without_pet()
	local pet_marker_pos = field:GetMarker(self.pet_align_marker_name).position

	music_player_util.play_sfx({sfx_name = "01_pet_ordinary_01"})

	character_util.align_party(pet_marker_pos + vector(1.5, 0, 0),
			"left", 1, "arc")

	wait_for_sec(1)

	yield_return_func(self.wolves_runaway_1, self)
end

function local_class:event_with_pet(pet_index)
	self:align_party_pet_right(pet_index)

	wait_for_sec(1)

	party_util.remove_animation()

	wait_for_sec(0.3)

	user_party[pet_index]:HideWeapon(true)

	local pet_marker_pos = field:GetMarker(self.pet_align_marker_name).position

	character_util.move_waypoint_async(user_party[pet_index], pet_marker_pos + vector(1, 0, 0),
			2, false)
	wait_for_sec(0.3)

	yield_return_func(self.wolves_runaway_2, self, pet_index)
	yield_return_func(self.pet_reunion, self, pet_index)

	user_party[pet_index]:HideWeapon(false)
end

function local_class:get_pet_index_in_party()
	for i = 0, user_party.Count - 1 do
		local origin_id = user_party[i].CharacterStatsBehaviour.CharacterSpec.OriginId

		if origin_id == self.pet_origin_id and not user_party[i].FieldObjectStatsBehaviour.IsDead then
			return i
		end
	end

	return -1
end

--- pet_2를 기준으로 arc 방향으로
function local_class:align_party_pet_right(pet_index)
	local dist = CS.Oak.Constants.DistBetweenPartyMembers
	local pet_marker_pos = field:GetMarker(self.pet_align_marker_name).position

	camera_util.move(pet_marker_pos, 1)

	local pos_table = {
		vector(-dist, 0, dist),
		vector(-dist, 0, -dist),
		vector(-dist * 2, 0, 0),
		vector(-dist, 0, 0),
	}

	local table_index = 1

	party_util.set_direction("right")
	party_util.set_anim({name = "walk"})

	for i = 0, user_party.Count - 1 do
		if i == pet_index then
			character_util.move_to(user_party[i], pet_marker_pos, 1)
		else
			character_util.move_to(user_party[i], pet_marker_pos + pos_table[table_index], 1)
			table_index = table_index + 1
		end
	end
end

function local_class:set_wolves_position_to_disappear()
	local head_wolf = get_character(self.head_wolf_name)
	local wolf_1 = get_character(self.wolf_1_name)
	local wolf_2 = get_character(self.wolf_2_name)
	local wolf_3 = get_character(self.wolf_3_name)
	local wolf_4 = get_character(self.wolf_4_name)

	character_util.set_position(head_wolf, vector(999, 0, 999))
	character_util.set_position(wolf_1, vector(999, 0, 999))
	character_util.set_position(wolf_2, vector(999, 0, 999))
	character_util.set_position(wolf_3, vector(999, 0, 999))
	character_util.set_position(wolf_4, vector(999, 0, 999))
end

function local_class:wolves_runaway_1()
	local head_wolf = get_character(self.head_wolf_name)
	local wolf_1 = get_character(self.wolf_1_name)
	local wolf_2 = get_character(self.wolf_2_name)
	local wolf_3 = get_character(self.wolf_3_name)
	local wolf_4 = get_character(self.wolf_4_name)

	music_player_util.play_sfx({sfx_name = "01_rustle_01"})

	wait_for_sec(0.05)

	character_util.set_direction(head_wolf, "left")
	character_util.set_anim(head_wolf, {name = "angry"})
	character_util.remove_anim(head_wolf)

	character_util.set_direction(wolf_3, "left")
	character_util.set_anim(wolf_3, {name = "angry"})
	character_util.remove_anim(wolf_3)

	character_util.set_direction(wolf_2, "left")
	character_util.set_anim(wolf_2, {name = "angry"})
	character_util.remove_anim(wolf_2)

	character_util.set_direction(wolf_4, "left")
	character_util.set_anim(wolf_4, {name = "angry"})
	character_util.remove_anim(wolf_4)

	character_util.set_direction(wolf_1, "left")
	character_util.set_emotion(wolf_1, {name = "angry"})
	character_util.remove_anim(wolf_1)

	wait_for_sec(1)

	local wolf_speed = 6

	-- 2 + 2 + 5 + a
	local head_waypoint = create_generic_list(unity_class.vector3)
	head_waypoint:Add(vector(39, 0, -39))
	head_waypoint:Add(vector(39, 0, -37))
	head_waypoint:Add(vector(45, 0, -37))

	-- 2 + 3 + a
	local wolf_1_waypoint = create_generic_list(unity_class.vector3)
	wolf_1_waypoint:Add(vector(38, 0, -36))
	wolf_1_waypoint:Add(vector(45, 0, -36))

	-- 2 + 4 + a
	local wolf_2_waypoint = create_generic_list(unity_class.vector3)
	wolf_2_waypoint:Add(vector(37, 0, -37))
	wolf_2_waypoint:Add(vector(45, 0, -37))

	-- 3 + a
	local wolf_3_waypoint = create_generic_list(unity_class.vector3)
	wolf_3_waypoint:Add(vector(45, 0, -36))

	-- 5 + a
	local wolf_4_waypoint = create_generic_list(unity_class.vector3)
	wolf_4_waypoint:Add(vector(45, 0, -38))

	music_player_util.play_sfx({sfx_name = "01_wolves_running_01"})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, head_wolf, head_waypoint, 9 - 1))

	wait_for_sec(4 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_4, wolf_4_waypoint, 5 - 0.5))

	--wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_2, wolf_2_waypoint, 6 - 0.5))

	wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_3, wolf_3_waypoint, 3 - 0.5))

	wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_1, wolf_1_waypoint, 5 - 0.5))

	wait_for_sec(2)

	self:set_wolves_position_to_disappear()
end

function local_class:wolves_runaway_2(pet_index)
	local head_wolf = get_character(self.head_wolf_name)
	local wolf_1 = get_character(self.wolf_1_name)
	local wolf_2 = get_character(self.wolf_2_name)
	local wolf_3 = get_character(self.wolf_3_name)
	local wolf_4 = get_character(self.wolf_4_name)
	local pet = user_party[pet_index]

	music_player_util.play_sfx({sfx_name = "01_rustle_01"})

	wait_for_sec(0.05)

	character_util.set_direction(head_wolf, "left")
	character_util.set_anim(head_wolf, {name = "angry"})
	character_util.remove_anim(head_wolf)

	character_util.set_direction(wolf_3, "left")
	character_util.set_anim(wolf_3, {name = "angry"})
	character_util.remove_anim(wolf_3)

	character_util.set_direction(wolf_2, "left")
	character_util.set_anim(wolf_2, {name = "angry"})
	character_util.remove_anim(wolf_2)

	character_util.set_direction(wolf_4, "left")
	character_util.set_anim(wolf_4, {name = "angry"})
	character_util.remove_anim(wolf_4)

	character_util.set_direction(wolf_1, "left")
	character_util.set_anim(wolf_1, {name = "angry"})
	character_util.remove_anim(wolf_1)

	wait_for_sec(1)

	local wolf_speed = 6
	local pet_marker_pos = field:GetMarker(self.pet_align_marker_name).position

	local head_waypoint_1 = create_generic_list(unity_class.vector3)
	head_waypoint_1:Add(vector(35, 0, pet_marker_pos.z))
	head_waypoint_1:Add(vector(pet_marker_pos.x + 2, 0, pet_marker_pos.z))

	--music_player_util.play_sfx({sfx_name = "01_wolves_running_01", duration = 4 / 3, fade_out_time = 0.3})

	character_util.move_waypoint_async(head_wolf, head_waypoint_1, 3, false)

	character_util.set_anim(head_wolf, {name = "happy", loop = true})

	wait_for_sec(0.4)

	character_util.remove_anim(head_wolf)

	wait_for_sec(0.3)

	music_player_util.play_sfx({sfx_name = "01_pet_howl_01", volume = 1.5})

	character_util.set_anim(head_wolf, {name = "victory", loop = true})

	character_util.set_anim(pet, {name = "victory", loop = true})

	wait_for_sec(2.35)

	character_util.remove_anim(head_wolf)
	character_util.remove_anim(pet)

	wait_for_sec(0.6)

	-- 2 + 2 + 5 + a
	local head_waypoint_2 = create_generic_list(unity_class.vector3)
	--head_waypoint_2:Add(vector(39, 0, -39))
	head_waypoint_2:Add(vector(39, 0, -37))
	head_waypoint_2:Add(vector(45, 0, -37))

	-- 2 + 3 + a
	local wolf_1_waypoint = create_generic_list(unity_class.vector3)
	wolf_1_waypoint:Add(vector(38, 0, -36))
	wolf_1_waypoint:Add(vector(45, 0, -36))

	-- 2 + 4 + a
	local wolf_2_waypoint = create_generic_list(unity_class.vector3)
	wolf_2_waypoint:Add(vector(37, 0, -37))
	wolf_2_waypoint:Add(vector(45, 0, -37))

	-- 3 + a
	local wolf_3_waypoint = create_generic_list(unity_class.vector3)
	wolf_3_waypoint:Add(vector(45, 0, -36))

	-- 5 + a
	local wolf_4_waypoint = create_generic_list(unity_class.vector3)
	wolf_4_waypoint:Add(vector(45, 0, -38))

	local pet_waypoint = create_generic_list(unity_class.vector3)
	pet_waypoint:Add(vector(45, 0, -37))

	music_player_util.play_sfx({sfx_name = "01_wolves_running_01"})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, head_wolf, head_waypoint_2, 8 - 1))

	wait_for_sec(3 / wolf_speed)

	music_player_util.play_sfx({sfx_name = "01_pet_ordinary_01"})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, pet, pet_waypoint, 8 - 1))

	wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_4, wolf_4_waypoint, 5 - 0.5))

	--wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_2, wolf_2_waypoint, 6 - 0.5))

	wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_3, wolf_3_waypoint, 3 - 0.5))

	wait_for_sec(1 / wolf_speed)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.move_wolf, self, wolf_1, wolf_1_waypoint, 5 - 0.5))

end

function local_class:move_wolf(wolf, way_points, dist_to_jump)
	character_util.move_waypoint(wolf, way_points, 6, false)

	wait_for_sec(dist_to_jump / 6)

	--- 4칸정도 뜀
	character_util.jump(wolf, 2, 4 / 6)
end

function local_class:pet_reunion(pet_index)
	--pet:HideWeapon(true)

	local pet = user_party[pet_index]

	music_player_util.play_sfx({sfx_name = "03_runaway_01"})

	if user_party.Count > 1 then
		music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
	end

	for i = 0, user_party.Count - 1 do
		if i ~= pet_index then
			character_util.set_anim(user_party[i], {name = "embarrassed", loop = true})
			character_util.set_emotion(user_party[i], {name = "surprise"})

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])

				wait_for_sec(0.35)

				--music_player_util.play_sfx({sfx_name = "01_player_jump_01", duration = 0.4, fade_out_time = 0.1})
				character_util.normal_jump(user_party[i])
			end))
		end
	end

	wait_for_sec(3)

	local head_wolf = get_character(self.head_wolf_name)
	character_util.set_position(head_wolf, vector(47, 0, -38))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wait_for_sec(0.7)

		for i = 0, user_party.Count - 1 do
			if i ~= pet_index then
				character_util.set_anim(user_party[i], {name = "idle"})
				character_util.set_emotion(user_party[i], {name = "smile"})
			end
		end
	end))

	music_player_util.play_sfx({sfx_name = "01_pet_ordinary_01"})

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_wolf,
			self, pet, vector(37, 0, -37), 0))

	yield_return_func(self.move_wolf, self, head_wolf, vector(39, 0, -38), 2)

	wait_for_sec(8 / 6 + 0.5)

	local star_piece = get_field_object(self.star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(head_wolf.Position + vector(0, 0.5, 0)))

	wait_for_sec(1)

	character_util.set_anim(pet, {name = "happy"})
	character_util.set_anim(head_wolf, {name = "happy"})

	wait_for_sec(2)

	character_util.set_direction(pet, "right")

	wait_for_sec(0.2)

	music_player_util.play_sfx({sfx_name = "01_pet_howl_01", volume = 1.5})

	character_util.set_anim(head_wolf, {name = "victory", loop = true})

	character_util.set_anim(pet, {name = "victory", loop = true})

	wait_for_sec(2.35)

	--character_util.set_anim(pet, {name = "victory", loop = true})
	--character_util.set_anim(head_wolf, {name = "victory", loop = true})
	--
	--wait_for_sec(2.35)

	character_util.remove_anim(pet)
	character_util.remove_anim(head_wolf)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.move_wolf, self, head_wolf, vector(45, 0, -38), 2))

	wait_for_sec(0.3)

	music_player_util.play_sfx({sfx_name = "01_jump_01"})

	wait_for_sec(0.7)

	local pet_marker_pos = field:GetMarker(self.pet_align_marker_name).position

	character_util.move_waypoint_async(pet, pet_marker_pos, 6, false)

	camera_util.move_async(user_party_leader.Position, 0.5, {end_target = user_party_leader})

	self:set_wolves_position_to_disappear()

	party_util.remove_animation()
	party_util.remove_emotion()
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}