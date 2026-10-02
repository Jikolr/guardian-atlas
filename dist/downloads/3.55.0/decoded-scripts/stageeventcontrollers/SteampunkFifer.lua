local local_class = newclass("SteampunkFiferController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')

	self.left_1 = create_generic_list(CS.System.Single)
	self.left_1:Add(6.000000)
	self.left_1:Add(10.000000)
	self.left_1:Add(13.000000)
	self.left_1:Add(18.000000)
	self.left_1:Add(22.000000)
	self.left_1:Add(26.000000)
	self.left_1:Add(30.000000)
	self.left_1:Add(35.000000)

	self.right_1 = create_generic_list(CS.System.Single)
	self.right_1:Add(4.000000)
	self.right_1:Add(8.000000)
	self.right_1:Add(12.000000)
	self.right_1:Add(15.500000)
	self.right_1:Add(20.000000)
	self.right_1:Add(24.000000)
	self.right_1:Add(28.000000)
	self.right_1:Add(33.000000)
	self.right_1:Add(37.000000)

	self.both_1 = create_generic_list(CS.System.Single)
	self.both_1:Add(16.000000)
	self.both_1:Add(32.000000)
	self.both_1:Add(36.000000)
	self.both_1:Add(39.500000)

	self.left_2 = create_generic_list(CS.System.Single)
	self.left_2:Add(4.838700)
	self.left_2:Add(6.774180)
	self.left_2:Add(8.709660)
	self.left_2:Add(10.645140)
	self.left_2:Add(14.516100)
	self.left_2:Add(17.419320)
	self.left_2:Add(19.354800)
	self.left_2:Add(21.290280)
	self.left_2:Add(24.193500)
	self.left_2:Add(26.128980)
	self.left_2:Add(28.064460)
	self.left_2:Add(29.999940)
	self.left_2:Add(31.935420)
	self.left_2:Add(34.354770)
	self.left_2:Add(37.257990)

	self.right_2 = create_generic_list(CS.System.Single)
	self.right_2:Add(3.870960)
	self.right_2:Add(5.806440)
	self.right_2:Add(7.741920)
	self.right_2:Add(9.677400)
	self.right_2:Add(13.548360)
	self.right_2:Add(16.451580)
	self.right_2:Add(18.387060)
	self.right_2:Add(20.322540)
	self.right_2:Add(22.258020)
	self.right_2:Add(25.161240)
	self.right_2:Add(27.096720)
	self.right_2:Add(29.032200)
	self.right_2:Add(32.419290)
	self.right_2:Add(33.870900)
	self.right_2:Add(36.774120)
	self.right_2:Add(37.741860)

	self.both_2 = create_generic_list(CS.System.Single)
	self.both_2:Add(11.612880)
	self.both_2:Add(15.483840)
	self.both_2:Add(23.225760)
	self.both_2:Add(30.967680)
	self.both_2:Add(38.225730)

	self.left_3 = create_generic_list(CS.System.Single)
	self.left_3:Add(6.614160)
	self.left_3:Add(7.086600)
	self.left_3:Add(10.393680)
	self.left_3:Add(10.866120)
	self.left_3:Add(12.283440)
	self.left_3:Add(13.464540)
	self.left_3:Add(13.936980)
	self.left_3:Add(14.409420)
	self.left_3:Add(16.062960)
	self.left_3:Add(17.480280)
	self.left_3:Add(18.425160)
	self.left_3:Add(19.842480)
	self.left_3:Add(21.259800)
	self.left_3:Add(22.204680)
	self.left_3:Add(23.622000)
	self.left_3:Add(25.039320)
	self.left_3:Add(25.984200)
	self.left_3:Add(27.401520)
	self.left_3:Add(28.818840)
	self.left_3:Add(29.763720)
	self.left_3:Add(33.070800)
	self.left_3:Add(33.543240)
	self.left_3:Add(35.905440)
	self.left_3:Add(36.850320)

	self.right_3 = create_generic_list(CS.System.Single)
	self.right_3:Add(4.724400)
	self.right_3:Add(5.196840)
	self.right_3:Add(8.503920)
	self.right_3:Add(8.976360)
	self.right_3:Add(11.338560)
	self.right_3:Add(13.228320)
	self.right_3:Add(13.700760)
	self.right_3:Add(14.173200)
	self.right_3:Add(14.645640)
	self.right_3:Add(15.590520)
	self.right_3:Add(16.535400)
	self.right_3:Add(17.952720)
	self.right_3:Add(19.370040)
	self.right_3:Add(20.314920)
	self.right_3:Add(21.732240)
	self.right_3:Add(23.149560)
	self.right_3:Add(24.094440)
	self.right_3:Add(25.511760)
	self.right_3:Add(26.929080)
	self.right_3:Add(27.873960)
	self.right_3:Add(29.291280)
	self.right_3:Add(31.181040)
	self.right_3:Add(31.653480)
	self.right_3:Add(34.960560)
	self.right_3:Add(35.433000)
	self.right_3:Add(36.377880)

	self.both_3 = create_generic_list(CS.System.Single)
	self.both_3:Add(3.779520)
	self.both_3:Add(5.669280)
	self.both_3:Add(7.559040)
	self.both_3:Add(9.448800)
	self.both_3:Add(15.118080)
	self.both_3:Add(17.007840)
	self.both_3:Add(18.897600)
	self.both_3:Add(20.787360)
	self.both_3:Add(22.677120)
	self.both_3:Add(24.566880)
	self.both_3:Add(26.456640)
	self.both_3:Add(28.346400)
	self.both_3:Add(30.236160)
	self.both_3:Add(32.125920)
	self.both_3:Add(34.015680)
	self.both_3:Add(37.322760)

	self.get_trio_boss = function() return get_character('trio_boss') end
	self.get_trio_man = function() return get_character('trio_man') end
	self.get_trio_panda = function() return get_character('trio_panda') end
	self.get_rhythm_boss = function() return get_character('rhythm_boss') end
	self.get_rhythm_man = function() return get_character('rhythm_man') end
	self.get_rhythm_panda = function() return get_character('rhythm_panda') end
	self.get_original_fifer = function() return get_character('original_fifer') end
	self.get_rat = function(num) return get_character('rat_' .. num) end

	self.get_jump_pad = function(num) return get_field_object('jump_' .. num) end

	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end
	self.get_fx_lasthit = function() return unity_object_pool.GetOrCreate('FX_lasthit') end

	self.follower_state = {
		idle = 0,
		--come = 1,
		move = 1
	}

	self.rat_list = {}
	self.following_list = {}

	self.follow_rat_infos = {}

	self.rat_index = 0
	self.follower_index = 0

	self.follower_offset_info = {
		{
			vector(-1, 0, 0),
			vector(-2, 0, 0),
			vector(-3, 0, 0),
			vector(-4, 0, 0),
			vector(-5, 0, 0),
		},
		{
			vector(-1, 0, 0.5), vector(-1, 0, -0.5),
			vector(-2, 0, 0.5), vector(-2, 0, -0.5),
			vector(-3, 0, 0.5), -- 대니
			vector(-2.6, 0, 0.5 + 0.15), 	-- 대장
			vector(-2.6, 0, 0.5 - 0.15),		-- 팬더
			vector(-3, 0, -0.5),
			vector(-4, 0, 0.5), vector(-4, 0, -0.5),
		},
		{
			vector(-1, 0, 0.7), vector(-1, 0, 0), vector(-1, 0, -0.7),
			vector(-2, 0, 0.7), vector(-2, 0, 0), vector(-2, 0, -0.7),
			vector(-3, 0, 0.7), vector(-3, 0, 0), vector(-3, 0, -0.7),
			vector(-4, 0, 0.7), vector(-4, 0, 0), vector(-4, 0, -0.7),
			vector(-5, 0, 0.7), vector(-5, 0, 0), vector(-5, 0, -0.7),
		}
	}

	self.is_talked_fifer_once = false

	self.current_phase = 0

	self.rat_angry_request_idx = 0
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_event')

	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_button")
	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_red_node")
	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_blue_node")
	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_both_node")
	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_red")
	unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_blue")
	unity_object_pool.GetOrCreate('stage_item')
	self.get_fx_hit()
	self.get_fx_lasthit()

	CS.Oak.CommonScreenplay.PreloadStageTitle()

	self.get_original_fifer().Interactable:AddListener(self.cs_controller)

	yield_return(unity_object_pool, 'WaitAll')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_launch_routine()
end

function local_class:set_rat_list()
	for i = 1, 12 do
		local rat = get_character('rat_' .. i)
		rat.ActiveState = active_state('disabled')
		rat:SetScale(unity_class.vector3.one * 0.4, 0)
		rat.SpineController.ShadowScale = 1 / 3.0

		table.insert(self.rat_list, rat)
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.get_original_fifer()) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_music, self))

		elseif type_util.is_interacted_target(e,
				{ self.get_trio_man(), self.get_trio_panda(), self.get_trio_boss()}) then
			sp_util.play_normal_screenplay(self.talk_with_trio, self)
		end

	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.GamepadEvent) then
		if e.GamepadEventType == CS.Oak.GamepadEventType.LeftTriggerDown
				or e.GamepadEventType == CS.Oak.GamepadEventType.LeftShoulderDown then
			self.gamepad_left_button_pressed = true
		elseif e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown
				or e.GamepadEventType == CS.Oak.GamepadEventType.RightShoulderDown then
			self.gamepad_right_button_pressed = true
		end

	end

	return false
end

function local_class:on_stage_loaded(_)
	self.fifer = get_character("fifer")

	self:set_rat_list()

	self.get_rhythm_man().Holdable = CS.Oak.Holdable()

	if self:is_quest_done() then
		self.get_trio_boss().ActiveState = active_state('disabled')
		self.get_trio_panda().ActiveState = active_state('disabled')
		self.get_trio_man().ActiveState = active_state('disabled')

		self.is_talked_fifer_once = true
	else
		character_util.set_direction(self.get_original_fifer(), 'right')

		if type_util.is_npc_interactable(self.get_trio_boss()) then
			self.get_trio_boss().Interactable:AddListener(self.cs_controller)
		end

		if type_util.is_npc_interactable(self.get_trio_panda()) then
			self.get_trio_panda().Interactable:AddListener(self.cs_controller)
		end

		if type_util.is_npc_interactable(self.get_trio_man()) then
			self.get_trio_man().Interactable:AddListener(self.cs_controller)
		end

	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, self.fifer) then return end

	local zone_name = e.Zone.Name

	if string.find(zone_name, 'appear_') then
		if not self.dead then
			-- 대니가 나타나는 존이라면
			if string.find(zone_name, 'appear_man_') then
				self.follower_index = self.follower_index + 1

				local trio_man = self.get_rhythm_man()
				local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
				local target_pos = self.fifer.Position + pos_dif

				local z_dif = 0

				if self.current_phase == 2 then	-- 1번째 줄
					local val_list = { 0, 1.5 }
					z_dif = val_list[random_util.get_random_int(1, 2)]
				elseif self.current_phase == 3 then	-- 2번째 줄
					z_dif = 0
				end

				local spawn_pos = vector(target_pos.x - 5.5, 0, target_pos.z + z_dif)

				character_util.spine_set_alpha_fade(trio_man, 0, 0)
				character_util.set_position(trio_man, spawn_pos)

				table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = trio_man })

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.rat_move_process, self, trio_man, pos_dif, 4.5))

			-- 여자 보스가 나타나는 존이라면
			elseif string.find(zone_name, 'appear_boss_') then
				if self.current_phase == 2 then
					self.follower_index = self.follower_index + 1

					local trio_boss = self.get_rhythm_boss()
					local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
					local target_pos = self.fifer.Position + pos_dif
					local spawn_pos = vector(target_pos.x - 10, 0, target_pos.z)

					--character_util.spine_set_alpha_fade(trio_boss, 0, 0)
					character_util.set_position(trio_boss, spawn_pos)

					table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = trio_boss })

					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.trio_blocker_move_process, self, trio_boss, pos_dif, 7))
				else
					self.follower_index = self.follower_index + 1

					local trio_boss = self.get_rhythm_boss()
					local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
					local target_pos = self.fifer.Position + pos_dif

					local val_list = { 0, 1 }
					local z_dif = val_list[random_util.get_random_int(1, 2)]

					local spawn_pos = vector(target_pos.x - 2, 0, target_pos.z + z_dif)

					character_util.spine_set_alpha_fade(trio_boss, 0, 0)
					character_util.set_position(trio_boss, spawn_pos)

					table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = trio_boss })

					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.rat_move_process, self, trio_boss, pos_dif, 4.5))
				end

			-- 판다가 나타나는 존이라면
			elseif string.find(zone_name, 'appear_panda_') then
				if self.current_phase == 2 then
					self.follower_index = self.follower_index + 1

					local trio_panda = self.get_rhythm_panda()
					local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
					local target_pos = self.fifer.Position + pos_dif
					local spawn_pos = vector(target_pos.x - 10, 0, target_pos.z)

					character_util.set_position(trio_panda, spawn_pos)

					table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = trio_panda })

					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.trio_blocker_move_process, self, trio_panda, pos_dif, 7))
				else
					self.follower_index = self.follower_index + 1

					local trio_panda = self.get_rhythm_panda()
					local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
					local target_pos = self.fifer.Position + pos_dif

					local val_list = { 0, 1 }
					local z_dif = val_list[random_util.get_random_int(1, 2)]

					local spawn_pos = vector(target_pos.x - 2, 0, target_pos.z + z_dif)

					character_util.spine_set_alpha_fade(trio_panda, 0, 0)
					character_util.set_position(trio_panda, spawn_pos)

					table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = trio_panda })

					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.rat_move_process, self, trio_panda, pos_dif, 4.5))
				end
			-- 이외의 경우는 전부 쥐가 나타나게 함.
			else
				self.rat_index = self.rat_index + 1
				self.follower_index = self.follower_index + 1

				local rat = self.rat_list[self.rat_index]
				local pos_dif = self.follower_offset_info[self.current_phase][self.follower_index]
				local target_pos = self.fifer.Position + pos_dif

				local line = (self.follower_index + self.current_phase - 1) % self.current_phase + 1

				local z_dif = 0

				if self.current_phase == 1 then
					if line == 1 then
						local val_list = { -1.5, 0, 1.5 }
						z_dif = val_list[random_util.get_random_int(1, 3)]
					end
				elseif self.current_phase == 2 then
					if line == 1 then
						local val_list = { 0, 1.5 }
						z_dif = val_list[random_util.get_random_int(1, 2)]
					elseif line == 2 then
						local val_list = { -1.5, 0 }
						z_dif = val_list[random_util.get_random_int(1, 2)]
					end
				elseif self.current_phase == 3 then
					if line == 1 then
						local val_list = { 0, 1 }
						z_dif = val_list[random_util.get_random_int(1, 2)]
					elseif line == 2 then
						z_dif = 0
					elseif line == 3 then
						local val_list = { -1, 0 }
						z_dif = val_list[random_util.get_random_int(1, 2)]
					end
				end

				local x_spawn_offset = 7
				local spawn_pos = vector(target_pos.x - x_spawn_offset, 0, target_pos.z + z_dif)

				character_util.spine_set_alpha_fade(rat, 0, 0)
				character_util.set_position(rat, spawn_pos)

				table.insert(self.follow_rat_infos, { state = self.follower_state.move, mover = rat })

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.rat_move_process, self, rat, pos_dif, 4.5))
			end
		end
	end
end

function local_class:get_following_rat_state(mover)
	for _, info in pairs(self.follow_rat_infos) do
		if lua_helper.reference_equals(info.mover, mover) then
			return info.state
		end
	end
end

function local_class:rat_move_process(mover, pos_dif, speed)
	character_util.set_active_state(mover, 'enabled')
	character_util.spine_set_alpha_fade(mover, 1, 0.5)
	character_util.set_anim(mover, {name = 'walk'})

	if string.match(mover.Name, 'rat') then
		character_util.set_emotion(mover, { name = 'smile' })
	else
		character_util.set_emotion(mover, { name = 'love' })
	end

	local current_state = self:get_following_rat_state(mover)

	while current_state == self.follower_state.move do
		local target_pos = self.fifer.Position + pos_dif

		local rest_dist = vector_util.get_x0z(target_pos - mover.Position).magnitude
		local dir = vector_util.get_x0z(target_pos - mover.Position).normalized
		local movement = math.min(speed * unity_class.time.deltaTime, rest_dist)

		mover.Position = mover.Position + dir * movement

		coroutine.yield()
		current_state = self:get_following_rat_state(mover)
	end
end

function local_class:trio_blocker_move_process(mover, pos_dif, speed)
	character_util.set_active_state(mover, 'enabled')
	character_util.set_anim(mover, {name = 'run'})

	local current_state = self:get_following_rat_state(mover)

	while current_state == self.follower_state.move do
		local target_pos = self.fifer.Position + pos_dif

		local rest_dist = vector_util.get_x0z(target_pos - mover.Position).magnitude
		local dir = vector_util.get_x0z(target_pos - mover.Position).normalized

		local movement = 0
		if speed * unity_class.time.deltaTime < rest_dist then
			movement = speed * unity_class.time.deltaTime
		else
			character_util.set_direction(mover, 'left')
			character_util.set_anim(mover, {name = 'push'})
			character_util.set_emotion(mover, {name = 'damaged'})
			movement = rest_dist
		end

		mover.Position = mover.Position + dir * movement

		coroutine.yield()
		current_state = self:get_following_rat_state(mover)
	end
end

function local_class:stop_all_follower(keep_anim)
	for i = 1, #self.follow_rat_infos do
		self.follow_rat_infos[i].state = self.follower_state.idle
		if keep_anim ~= true then
			character_util.remove_anim(self.follow_rat_infos[i].mover)
		end
	end
end

function local_class:reset_after_game()
	self.follower_index = 0
	self.rat_index = 0

	character_util.remove_anim_and_emotion(self.fifer)

	for _, info in pairs(self.follow_rat_infos) do
		local follower = info.mover
		if follower ~= nil then
			character_util.remove_anim_and_emotion(follower)
			character_util.set_direction(follower, 'right')
			character_util.spine_set_alpha_fade(follower, 1, 0)
			character_util.spine_rotate(follower, 0, 0)
			follower.ActiveState = active_state('disabled')

			-- 쥐만 3분의 1크기로 돌려주고 매드판다 트리오들은 1로 돌려준다.
			if string.match(follower.Name, 'rat') then
				follower:SetScale(unity_class.vector3.one * 0.4, 0)
			else
				follower:SetScale(unity_class.vector3.one, 0)
			end
		end
	end

	self.follow_rat_infos = {}
end

function local_class:is_quest_done()
	return user_progress:IsStageCleared(stage.Name)
end

function local_class:talk_with_trio()
	local boss = self.get_trio_boss()
	local panda = self.get_trio_panda()
	local man = self.get_trio_man()

	if type_util.is_npc_interactable(self.get_trio_boss()) then
		self.get_trio_boss().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if type_util.is_npc_interactable(self.get_trio_panda()) then
		self.get_trio_panda().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if type_util.is_npc_interactable(self.get_trio_man()) then
		self.get_trio_man().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	party_util.align_to_target(vector(boss.Position.x - 0.3, 0, (boss.Position.z + panda.Position.z) / 2),
			'left', 1, 'linear')

	character_util.set_direction(boss, 'left')
	character_util.set_direction(panda, 'left')
	character_util.set_direction(man, 'left')

	--또 너야?!
	music_player_util.play_stage_music({ state = 'event', name = 'bgm_trio_non_fight' })
	music_player_util.play_sfx({sfx_name = '03_dialogue_negative_01'})
	character_util.set_emotion(boss, {name = 'attack'})
	character_util.set_emotion(boss, {name = 'mad'})
	character_util.set_emotion(man, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(boss, { key = 'steampunk_fifer_1', skip = true })

	--이 오우거 같은게 또 우리 먹이를 가로채려고!
	speech_bubble_util.show_speech_bubble_async(panda, { key = 'steampunk_fifer_2', skip = true })
	character_util.set_emotion(panda, {name = 'attack'})

	--대니 배고프다. 이 사람 나쁘다!
	character_util.set_anim(man, {name = 'release'})
	character_util.add_animation_sfx(man, '01_swing_01')
	speech_bubble_util.show_speech_bubble_async(man, { key = 'steampunk_fifer_3', skip = true })
	character_util.remove_anim(man)

	--헛수고 하지 말고 집에 가시지?
	character_util.set_anim(boss, {name = 'cross_arm'})
	speech_bubble_util.show_speech_bubble_async(boss, { key = 'steampunk_fifer_4', skip = true })

	--이번 쥐 퇴치 의뢰 보수는 우리 매드 팬더단의 것이니까!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	speech_bubble_util.show_speech_bubble_async(boss, { key = 'steampunk_fifer_5', skip = true })

	music_player_util.play_stage_music({ state = 'field' })

	boss.Interactable.Talk = 'steampunk_fifer_4'
	panda.Interactable.Talk = 'steampunk_fifer_2'
	man.Interactable.Talk = 'steampunk_fifer_3'
end

-- 번지점프 하려는 대니를 막는 트리오
function local_class:trio_drag()
	local man = self.get_rhythm_man()
	local boss = self.get_rhythm_boss()
	local panda = self.get_rhythm_panda()

	boss:Shake(0.05, 999)
	panda:Shake(0.05, 999)

	local speed = 2
	while not float_util.is_almost_zero(speed) do
		local movement = speed * unity_class.time.deltaTime
		local dir = unity_class.vector3.right

		man.Position = man.Position + dir * movement
		boss.Position = boss.Position + dir * movement
		panda.Position = panda.Position + dir * movement

		speed = speed * 0.97

		coroutine.yield()
	end

	boss:CancelShake()
	panda:CancelShake()
end

function local_class:start_music()
	self.dead = false

	local original_fifer = self.get_original_fifer()

	--local action_button = field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton)
	--local action_button_pos = action_button.transform.position

	field_ui_manager:Hide()
	character_util.align_party(original_fifer, "left", 1.0)
	wait_for_sec(0.5)

	local reset_pos = original_fifer.Position - vector(2, 0, 0)
	local start_pos = field:GetMarker("start_1").position
	local end_pos = field:GetMarker("end").position

	if not self.is_talked_fifer_once then
		self.is_talked_fifer_once = true

		--노인 : 이렇게 사나운 쥐떼라니…
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_6', skip = true })

		--노인 : 이대로 가면 도시가…
		character_util.set_emotion(original_fifer, {name = 'tired'})
		character_util.set_anim(original_fifer, {name = 'question', loop = false})
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_7', skip = true })
		character_util.remove_anim_and_emotion(original_fifer)

		--(머리 위에 ! 띄우고 주인공 쪽을 돌아보며)
		--노인 : ...자네는?
		character_util.show_emoticon_async(original_fifer, nil, 'notice')

		character_util.set_direction(original_fifer, 'left')
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_8', skip = true })

		--(주인공 삿대질)
		character_util.set_anim(user_party_leader, { name = 'release'})
		character_util.add_animation_sfx(user_party_leader, '01_swing_01')

		wait_for_sec(1.5)
		character_util.remove_anim(user_party_leader)

		--노인 : ...전설의 음악가..?
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_9', skip = true })

		--노인 : 그거 참 과대한 호칭이구먼..
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_10', skip = true })

		--노인 : 그래. 한 때는 내 악기로 쥐떼를 퇴치한 적이 있었지..
		character_util.set_direction(original_fifer, 'right')
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_11', skip = true })

		--노인 : 하지만 그것도 옛말이야…
		character_util.set_emotion(original_fifer, { name = 'tired '})
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_12', skip = true })

		--노인 : 이 나이엔 악기를 쥐는 것도 쉽지 않아..
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_13', skip = true })
		character_util.remove_emotion(original_fifer)

		--노인 : …
		character_util.set_direction(original_fifer, 'left')
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_14', skip = true })
		character_util.remove_emotion(original_fifer)

		--노인 : 쥐떼를 물리칠 생각이라면…
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_15', skip = true })

		--노인 : 혹시 자네가 한번 해보지 않겠나?
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_16', skip = true })

		--(주인공 고민하는 포즈 + ?)
		music_player_util.play_sfx({sfx_name = '01_rustle_01'})
		character_util.set_anim(user_party_leader, {name = 'question', loop = false})
		character_util.show_emoticon_async(user_party_leader, nil, 'question')

		screen_util.fade_out_async(1.0, unity_class.color.black)
		character_util.remove_anim(user_party_leader)

	else
		speech_bubble_util.show_speech_bubble_async(original_fifer, { key = 'steampunk_fifer_17', skip = true })

		screen_util.fade_out_async(1.0, unity_class.color.black)
	end

	screen_util.fade_out_async(1.0, unity_class.color.black)

	-- 카메라 셋업
	stage_camera:ResizeTo(3.0, 0)

	-- UI 버튼 셋업
	local aspect = CS.UnityEngine.Screen.safeArea.width / CS.UnityEngine.Screen.height;
	local target_size = vector(CS.Oak.FieldUIManager.UIHeight * aspect, CS.Oak.FieldUIManager.UIHeight);
	local left_button = nil
	local right_button = nil
	--local left_button_pos = vector(-math.abs(action_button_pos.x) + 50, action_button_pos.y + 15, 0)
	--local right_button_pos = vector(math.abs(action_button_pos.x) - 50, action_button_pos.y + 15, 0)
	local left_button_pos = vector(0 - 250, -target_size.y / 2.0 + 140, 0)
	local right_button_pos = vector(0 + 250, -target_size.y / 2.0 + 140, 0)

	local stage_item_obj = unity_object_pool.GetOrCreate('steampunk_rhythm_minigame_button'):Instantiate(start_pos)
	CS.Utils.ChangeLayersRecursively(stage_item_obj.transform, "FieldUI")
	stage_item_obj.transform.localPosition = left_button_pos
	stage_item_obj.transform.localScale = vector(60, 60, 60)
	left_button = stage_item_obj
	left_button:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).state:SetAnimation(0, "blue_idle", true)

	stage_item_obj = unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_button"):Instantiate(start_pos)
	CS.Utils.ChangeLayersRecursively(stage_item_obj.transform, "FieldUI")
	stage_item_obj.transform.localPosition = right_button_pos
	stage_item_obj.transform.localScale = vector(60, 60, 60)
	right_button = stage_item_obj
	right_button:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).state:SetAnimation(0, "red_idle", true)

	-- UI hp 게이지 셋업
	local hp_max = 5
	local h_space = 0.35
	local hp_list = create_generic_list(CS.Oak.PooledUnityObject)
	for i = 0, hp_max - 1 do
		local pos = self.fifer.Position + vector((- (hp_max - 1) / 2.0 + i) * h_space, 1.75, -0.1)
		stage_item_obj = unity_object_pool.GetOrCreate('stage_item'):Instantiate(pos, unity_class.quaternion.identity, self.fifer.Transform)
		stage_item = stage_item_obj:GetComponent(typeof(CS.Oak.StageItem))
		stage_item:SetItem("knight_badge")
		stage_item.ShadowActive = false
		stage_item_obj.transform.localScale = vector(0.65, 0.65, 0.65)
		hp_list:Add(stage_item_obj)
	end

	music_player_util.play_stage_music({ state = 'muted', mix = 1 })

	character_util.set_direction(self.get_rhythm_boss(), 'right')
	character_util.set_direction(self.get_rhythm_man(), 'right')
	character_util.set_direction(self.get_rhythm_panda(), 'right')

	character_util.set_active_state(self.get_rhythm_boss(), 'disabled')
	character_util.set_active_state(self.get_rhythm_panda(), 'disabled')
	character_util.set_active_state(self.get_rhythm_man(), 'disabled')

	local jump_tile_animators = {}

	for i = 1, 3 do
		local jump_tile_animator = self.get_jump_pad(i):GetComponent(typeof(CS.UnityEngine.Animator))
		jump_tile_animator.speed = 3
		table.insert(jump_tile_animators, jump_tile_animator)
	end

	local player_last_move = function(z_pos)
		character_util.move_to_async(self.fifer, vector(self.fifer.Position.x, 0, z_pos), nil, 1, true)
		--character_util.remove_anim(self.fifer, true)
		character_util.remove_anim(self.fifer)

		character_util.set_direction(self.fifer, 'right')
		character_util.set_anim(self.fifer, {name = 'unique/play_drum_loop'})
	end

	-- 페이즈 1
	self.current_phase = 1
	character_util.set_anim(self.fifer, { name = "unique/play_drum_strong", loop = true })

	local spos = field:GetMarker("start_1").position
	local epos = field:GetMarker("jump_1").position

	yield_return_func(self.play_game, self, "bgm_rhythmic_01", self.left_1, self.right_1, self.both_1, left_button, right_button, target_size, hp_list, spos, epos, "steampunk_fifer_songtitle_1", 40.5)

	if self.dead then
		yield_return_func(self.dead_sequence, self, 0)
	else
		--region 1페이즈 끝날 때 쥐들 뛰어내림
		self:stop_all_follower(true)

		-- 성공 함성
		music_player_util.play_sfx({ sfx_name = '01_crowd_shout_03' })

		camera_util.move(epos, 1)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(player_last_move, 2))

		local wait_list_1 = {}

		local jump_x_1 = epos.x - 0.8

		for i = 1, 5 do
			local mover = self.follow_rat_infos[i].mover
			table.insert(wait_list_1, util.cs_generator(function()
				character_util.move_to_async(mover, vector(jump_x_1, 0, mover.Position.z),
						nil, 2, true, true)
				--jump_tile_animators[1]:Play('on')
				self:jump_and_fall(mover, jump_tile_animators[1])
			end))
		end

		wait_all(wait_list_1)

		--endregion

		screen_util.fade_out_async(1.0, unity_class.color.black)

		self:reset_after_game()

		for i = 0, hp_list.Count - 1 do
			hp_list[i].gameObject:SetActive(true)
			hp_list[i].transform.localScale = vector(0.65, 0.65, 0.65)
		end
		character_util.remove_anim(self.fifer, true)
		character_util.remove_emotion(self.fifer)
		character_util.set_anim(self.fifer, { name = "unique/play_drum_strong", loop = true })

		-- 페이즈 2
		self.current_phase = 2
		spos = field:GetMarker("start_2").position
		epos = field:GetMarker("jump_2").position
		yield_return_func(self.play_game, self, "bgm_rhythmic_02", self.left_2, self.right_2, self.both_2, left_button, right_button, target_size, hp_list, spos, epos, "steampunk_fifer_songtitle_2", 39.5)

		if self.dead then
			yield_return_func(self.dead_sequence, self, 1)
		else
			--region 2페이즈 끝날 때 쥐들 뛰어내림
			self:stop_all_follower(true)

			-- 성공 함성
			music_player_util.play_sfx({ sfx_name = '01_crowd_clap_03' })

			camera_util.move(epos, 1)
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(player_last_move, 2))

			local wait_list_2 = {}

			local jump_on_flag_list = {
				true, false,
				true, false,
				false, false,
				false, true,
				true, false
			}
			local jump_x_2 = epos.x - 0.8

			for i = 1, 10 do
				local mover = self.follow_rat_infos[i].mover
				if i < 5 or i > 7 then
					table.insert(wait_list_2, util.cs_generator(function()
						character_util.move_to_async(mover, vector(jump_x_2, 0, mover.Position.z),
								nil, 2, true, true)
						if jump_on_flag_list[i] then
							--jump_tile_animators[2]:Play('on')
							self:jump_and_fall(mover, jump_tile_animators[2])
						else
							self:jump_and_fall(mover)
						end
					end))
				end
			end

			-- 트리오가 대니를 저지하는 연출도 넣어줌.
			table.insert(wait_list_2, util.cs_generator(self.trio_drag, self))

			wait_all(wait_list_2)

			screen_util.fade_out_async(1.0, unity_class.color.black)

			self:reset_after_game()

			for i = 0, hp_list.Count - 1 do
				hp_list[i].gameObject:SetActive(true)
				hp_list[i].transform.localScale = vector(0.65, 0.65, 0.65)
			end
			character_util.remove_anim(self.fifer, true)
			character_util.remove_emotion(self.fifer)
			character_util.set_anim(self.fifer, { name = "unique/play_drum_strong", loop = true })

			-- 페이즈 3
			self.current_phase = 3
			spos = field:GetMarker("start_3").position
			epos = field:GetMarker("jump_3").position
			yield_return_func(self.play_game, self, "bgm_rhythmic_03", self.left_3, self.right_3, self.both_3, left_button, right_button, target_size, hp_list, spos, epos, "steampunk_fifer_songtitle_3", 39.5)

			if self.dead then
				yield_return_func(self.dead_sequence, self, 2)
			else
				--region 3페이즈 끝날 때 쥐들 뛰어내림

				--쥐들 뛰어내림
				self:stop_all_follower(true)

				camera_util.move(epos, 1)
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(player_last_move, 29))

				local wait_list_3 = {}
				local jump_x_3 = epos.x - 0.8

				for i = 1, 15 do
					local mover = self.follow_rat_infos[i].mover
					table.insert(wait_list_3, util.cs_generator(function()
						character_util.move_to_async(mover, vector(jump_x_3, 0, mover.Position.z),
								nil, 2, true, true)

						if i % 3 == 1 then
							--jump_tile_animators[3]:Play('on')
							self:jump_and_fall(mover, jump_tile_animators[3])
						else
							self:jump_and_fall(mover)
						end
					end))
				end

				wait_all(wait_list_3)

				--endregion

				screen_util.fade_out_async(1.0, unity_class.color.black)
			end
		end
	end

	--screen_util.fade_out_async(1.0, unity_class.color.black)

	if self.dead then
		self:reset_after_game()

		party_util.position_party(reset_pos, CS.Oak.Direction.Right)
		party_util.set_anim({name = 'prostrate'})
		party_util.set_emotion({name = 'damaged'})
		camera_util.move(reset_pos, 0, { end_target = user_party_leader })
	else
		party_util.position_party(end_pos, CS.Oak.Direction.Right)
		camera_util.move(end_pos, 0, { end_target = user_party_leader })
	end

	stage_camera:ResizeTo(CS.Oak.StageCamera.DefaultCameraSize, 0)

	music_player_util.play_stage_music({
		state = 'field', mix = 1
	})

	-- UI 해제
	left_button:Dispose()
	right_button:Dispose()

	for i = 0, hp_list.Count - 1 do
		hp_list[i]:Dispose()
	end
	hp_list:Clear()

	screen_util.fade_in_async(1.0, unity_class.color.black)

	if self.dead then
		party_util.shake(0.04, 1)
		wait_for_sec(1)

		party_util.remove_emotion()
		party_util.remove_animation()
		for i = 0, user_party.Count - 1 do
			character_util.mario_jump(user_party[i], 'right', 0.5, 0.3)
		end

		wait_for_sec(0.5)
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:jump_and_fall(fo, animator)
	character_util.move_to(fo, fo.Position + vector(2.5 + 0.8, 0, 0), 1, nil, true)

	local jump_sfx_name = string.match(fo.Name, 'rat') and '01_small_jump_01' or '01_player_jump_01'
	music_player_util.play_sfx({sfx_name = jump_sfx_name})
	character_util.jump(fo, 3, 1)

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_fall_down_01' })
	local factor_list = { -1, 1 }
	local factor = factor_list[random_util.get_random_int(1, 2)]
	fo:SetEmotion('damaged', true)
	character_util.spine_rotate(fo, 720 * factor, 0.7)
	character_util.spine_set_alpha_fade(fo, 0, 0.7)
	fo:SetScale(unity_class.vector3.zero, 0.7)

	wait_for_sec(0.7)
end

function local_class:play_game(bg_name, left_notes, right_notes, both_notes, left_button, right_button, target_size, hp_list, start_pos, end_pos, songtitle, end_time)

	start_pos = start_pos + vector(10, 0, 0)
	end_pos = end_pos - vector(4, 0, 0)

	self.fifer.Position = start_pos
	self.fifer.Direction = CS.Oak.Direction.Right
	camera_util.move(start_pos, 0, { end_target = self.fifer })

	local note_speed = target_size.y / 1.0
	local note_appear_dist = target_size.y + 120
	local note_appear_time = note_appear_dist / note_speed
	local time_threshold = 0.085
	local note_disappear_time = 300 / note_speed
	local left_button_pos = left_button.transform.localPosition
	local right_button_pos = right_button.transform.localPosition
	local left_button_scale = left_button.transform.localScale
	local right_button_scale = right_button.transform.localScale
	local left_state = left_button:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).state
	local right_state = right_button:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation)).state

	local left_button_touch_handler = CS.Oak.FieldUIButtonTouchHandler()
	left_button_touch_handler.buttonCollider = left_button:GetComponent(typeof(CS.UnityEngine.BoxCollider2D))
	left_button_touch_handler.buttonCollider.offset = vector(0, 0)

	local right_button_touch_handler = CS.Oak.FieldUIButtonTouchHandler()
	right_button_touch_handler.buttonCollider = right_button:GetComponent(typeof(CS.UnityEngine.BoxCollider2D))
	right_button_touch_handler.buttonCollider.offset = vector(0, 0)

	local left_max = left_button_pos.x + left_button_scale.x * 6
	local right_min = right_button_pos.x - right_button_scale.x * 6

	if left_max > right_min then
		local to_move = left_max
		local x_scale = left_button.transform.localScale.x
		left_button_touch_handler.buttonCollider.offset = vector(-to_move / x_scale, 0)
		right_button_touch_handler.buttonCollider.offset = vector(to_move / x_scale, 0)
	end

	screen_util.fade_in_async(1.0, unity_class.color.black)

	if not self.is_show_pc_narration then
		self.is_show_pc_narration = true
		field_ui_util.show_pc_control_narration('tip_keyboard_two')
	end

	local current_hp = hp_list.Count

	music_player_util.play_stage_music({
		name = bg_name, state = 'event', mix = 0, volume = 0.5
	})

	CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(songtitle), 1.2)

	local left_note_objects = create_generic_list(CS.Oak.PooledUnityObject)
	local left_note_hits = create_generic_list(CS.System.Int32)
	for i = 0, left_notes.Count - 1 do
		left_note_objects:Add(nil)
		left_note_hits:Add(0)
	end

	local right_note_objects = create_generic_list(CS.Oak.PooledUnityObject)
	local right_note_hits = create_generic_list(CS.System.Int32)
	for i = 0, right_notes.Count - 1 do
		right_note_objects:Add(nil)
		right_note_hits:Add(0)
	end

	local both_note_objects = create_generic_list(CS.Oak.PooledUnityObject)
	local both_note_hits = create_generic_list(CS.System.Int32)
	for i = 0, both_notes.Count - 1 do
		both_note_objects:Add(nil)
		both_note_hits:Add(0)
	end

	local time_passed = 0

	local left_pressed = left_button_touch_handler.Pressed
	local right_pressed = right_button_touch_handler.Pressed

	local started_drumming = false
	local started_walking = false
	local start_drum_time = 1.8
	local start_walk_time = 3.7

	local walk_speed = (end_pos - start_pos).magnitude / (end_time - start_walk_time)

	local awesome_emo_on = true
	local awesome_emo_time = -1

	local turned_on_cheer_sfx = false

	while true do
		time_passed = time_passed + unity_class.time.deltaTime

		if awesome_emo_on and time_passed - awesome_emo_time > 0.6 then
			character_util.remove_emotion(self.fifer)
			awesome_emo_on = false
		end

		if started_walking then
			self.fifer.Position = self.fifer.Position + vector(walk_speed * unity_class.time.deltaTime, 0, 0)
		end

		if time_passed >= start_drum_time and not started_drumming then
			started_drumming = true
			character_util.set_anim(self.fifer, { name = "unique/play_drum_loop", loop = true, upper = true})
		end

		if time_passed >= start_walk_time and not started_walking then
			started_walking = true
			character_util.set_anim(self.fifer, { name = "walk", loop = true})
		end

		if time_passed >= end_time then
			music_player_util.play_stage_music({ state = 'muted', mix = 0.5 })
			break
		end

		-- 페이즈3 에서 38초가 지났으면 환호 소리를 들려준다.
		if bg_name == 'bgm_rhythmic_03' and time_passed >= 38 and not turned_on_cheer_sfx then
			turned_on_cheer_sfx = true
			music_player_util.play_sfx({ sfx_name = '01_crowd_clap_02' })
			music_player_util.play_sfx({ sfx_name = '01_crowd_clap_03' })
		end

		local left_down = false
		local left_up = false
		local right_down = false
		local right_up = false
		local both_down = false

		local current_left_pressed =
			left_button_touch_handler.Pressed
					or CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.A)
					or self.gamepad_left_button_pressed == true

		local current_right_pressed =
			right_button_touch_handler.Pressed
					or CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.D)
					or self.gamepad_right_button_pressed == true

		self.gamepad_left_button_pressed = false
		self.gamepad_right_button_pressed = false

		left_button_touch_handler:Update()
		right_button_touch_handler:Update()

		if current_left_pressed ~= left_pressed then
			if current_left_pressed then
				left_down = true
			else
				left_up = true
			end
			left_pressed = current_left_pressed
		end

		if current_right_pressed ~= right_pressed then
			if current_right_pressed then
				right_down = true
			else
				right_up = true
			end
			right_pressed = current_right_pressed
		end

		local hit_left = false
		if left_down then
			left_button.transform.localPosition = left_button_pos + vector(0, -10, 0)
			music_player_util.play_sfx({sfx_name = "01_rhythm_o_01", fade_in_time = 0, type_priority = 'event'})
			left_state:SetAnimation(0, "blue_touch_on", false)
			hit_left = true
		elseif left_up then
			left_button.transform.localPosition = left_button_pos
			left_state:SetAnimation(0, "blue_idle", true)
		end

		local hit_right = false
		if right_down then
			right_button.transform.localPosition = right_button_pos + vector(0, -10, 0)
			music_player_util.play_sfx({sfx_name = "01_rhythm_o_01", fade_in_time = 0, type_priority = 'event'})
			right_state:SetAnimation(0, "red_touch_on", false)
			hit_right = true
		elseif right_up then
			right_button.transform.localPosition = right_button_pos
			right_state:SetAnimation(0, "red_idle", true)
		end

		if right_down and left_pressed then
			both_down = true
		elseif left_down and right_pressed then
			both_down = true
		elseif right_down and left_down then
			both_down = true
		end

		local hit_both = false
		if both_down then
			hit_both = true
		end

		local damaged = false

		for i = 0, left_notes.Count -1 do
			local left_pos = left_button_pos + vector(0, note_speed * (left_notes[i] - time_passed), 0)
			if left_note_objects[i] ~= nil and (left_note_hits[i] == 0 or left_note_hits[i] == -1) then
				if time_passed >= left_notes[i] + note_disappear_time then
					left_note_objects[i]:Dispose()
					left_note_hits[i] = -2
				elseif time_passed >= left_notes[i] + time_threshold and left_note_hits[i] == 0 then
					damaged = true
					left_note_hits[i] = -1
				elseif hit_left and unity_class.mathf.Abs(time_passed - left_notes[i]) <= time_threshold then
					left_note_objects[i]:Dispose()
					left_note_hits[i] = 1

					-- 왼쪽 적중
					bluehit = unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_blue"):Instantiate(left_button.transform.position)
					bluehit.transform.localScale = vector(360, 360, 360)
				else
					left_note_objects[i].transform.localPosition = left_pos
				end
			else
				if time_passed <= left_notes[i] and time_passed >= left_notes[i] - note_appear_time then
					if left_note_hits[i] == 0 then
						local stage_item_obj = unity_object_pool.GetOrCreate('steampunk_rhythm_minigame_blue_node'):Instantiate(left_pos)
						stage_item_obj.transform.localPosition = left_pos
						stage_item_obj.transform.localScale = vector(125, 125, 125)
						left_note_objects[i] = stage_item_obj
					end
				end
			end
		end

		for i = 0, right_notes.Count -1 do
			local right_pos = right_button_pos + vector(0, note_speed * (right_notes[i] - time_passed), 0)
			if right_note_objects[i] ~= nil and (right_note_hits[i] == 0 or right_note_hits[i] == -1) then
				if time_passed >= right_notes[i] + note_disappear_time then
					right_note_objects[i]:Dispose()
					right_note_hits[i] = -2
				elseif time_passed >= right_notes[i] + time_threshold and right_note_hits[i] == 0 then
					damaged = true
					right_note_hits[i] = -1
				elseif hit_right and unity_class.mathf.Abs(time_passed - right_notes[i]) <= time_threshold then
					right_note_objects[i]:Dispose()
					right_note_hits[i] = 1

					-- 왼쪽 적중
					redhit = unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_red"):Instantiate(right_button.transform.position)
					redhit.transform.localScale = vector(360, 360, 360)
				else
					right_note_objects[i].transform.localPosition = right_pos
				end
			else
				if time_passed <= right_notes[i] and time_passed >= right_notes[i] - note_appear_time then
					if right_note_hits[i] == 0 then
						local stage_item_obj = unity_object_pool.GetOrCreate('steampunk_rhythm_minigame_red_node'):Instantiate(right_pos)
						stage_item_obj.transform.localPosition = right_pos
						stage_item_obj.transform.localScale = vector(125, 125, 125)
						right_note_objects[i] = stage_item_obj
					end
				end
			end
		end

		for i = 0, both_notes.Count -1 do
			local both_pos = (right_button_pos + left_button_pos) / 2 + vector(0, note_speed * (both_notes[i] - time_passed), 0)
			if both_note_objects[i] ~= nil and (both_note_hits[i] == 0 or both_note_hits[i] == -1) then
				if time_passed >= both_notes[i] + note_disappear_time then
					both_note_objects[i]:Dispose()
					both_note_hits[i] = -2
				elseif time_passed >= both_notes[i] + time_threshold and both_note_hits[i] == 0 then
					damaged = true
					both_note_hits[i] = -1
				elseif hit_both and unity_class.mathf.Abs(time_passed - both_notes[i]) <= time_threshold then
					both_note_objects[i]:Dispose()
					both_note_hits[i] = 1

					-- 양쪽 적중
					self.fifer.SpineController:Jump(0.5, 0.3)
					character_util.set_emotion(self.fifer, { name = "awesome", loop = false })

					-- TODO
					-- 따라오던 쥐들(state가 move인 애들)은 점프해야됨
					for _, info in pairs(self.follow_rat_infos) do
						if info.mover ~= nil then
							if self.current_phase ~= 2
									or not table_util.contain_value(
									{self.get_rhythm_panda(), self.get_rhythm_boss()}, info.mover) then
								character_util.set_anim(info.mover, {name = 'get', upper = true, remove_after = 0.3})
							end
							character_util.normal_jump(info.mover)
						end
					end

					awesome_emo_on = true
					awesome_emo_time = time_passed

					music_player_util.play_sfx({sfx_name = "01_rhythm_b_01", fade_in_time = 0, type_priority = 'event', volume = 0.8})
					redhit = unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_red"):Instantiate(right_button.transform.position)
					redhit.transform.localScale = vector(360, 360, 360)
					bluehit = unity_object_pool.GetOrCreate("steampunk_rhythm_minigame_hit_blue"):Instantiate(left_button.transform.position)
					bluehit.transform.localScale = vector(360, 360, 360)
				else
					both_note_objects[i].transform.localPosition = both_pos
				end
			else
				if time_passed <= both_notes[i] and time_passed >= both_notes[i] - note_appear_time then
					if both_note_hits[i] == 0 then
						local stage_item_obj = unity_object_pool.GetOrCreate('steampunk_rhythm_minigame_both_node'):Instantiate(both_pos)
						stage_item_obj.transform.localPosition = both_pos
						stage_item_obj.transform.localScale = vector(125, 125, 125)
						both_note_objects[i] = stage_item_obj
					end
				end
			end
		end

		if damaged then
			music_player_util.play_sfx({ sfx_name = '01_hit_comic_01' })
			current_hp = current_hp - 1
			if current_hp >= 0 then
				--if current_hp % 2 == 1 then
				--	local hp_index = (current_hp - 1) / 2
				--	hp_list[hp_index].transform.localScale = vector(0.4, 0.4, 0.4)
				--else
				--	local hp_index = current_hp / 2
				--	hp_list[hp_index].gameObject:SetActive(false)
				--end
				hp_list[current_hp].gameObject:SetActive(false)
			end
			self.fifer.SpineController:DamageRedPulse()
			self.fifer.SpineController:DamageSquish(1)
			CS.DamageNumber.ShowDamageNumber(self.fifer, 1, unity_class.color.red, self.fifer.Position)

			if current_hp <= 0 then
				music_player_util.play_stage_music({ state = 'muted', mix = 1.5 })
				break
			else
				self.rat_angry_request_idx = self.rat_angry_request_idx + 1 >= 100 and 0 or self.rat_angry_request_idx + 1
				self:rats_angry_when_damaged()
			end
		end
		coroutine.yield(nil)
	end

	for i = 0, left_note_objects.Count -1 do
		if left_note_objects[i] ~= nil and (left_note_hits[i] == 0 or left_note_hits[i] == -1) then
			left_note_objects[i]:Dispose()
		end
	end
	left_note_objects:Clear()
	left_note_hits:Clear()

	for i = 0, right_note_objects.Count -1 do
		if right_note_objects[i] ~= nil and (right_note_hits[i] == 0 or right_note_hits[i] == -1) then
			right_note_objects[i]:Dispose()
		end
	end
	right_note_objects:Clear()
	right_note_hits:Clear()

	for i = 0, both_note_objects.Count -1 do
		if both_note_objects[i] ~= nil and (both_note_hits[i] == 0 or both_note_hits[i] == -1) then
			both_note_objects[i]:Dispose()
		end
	end
	both_note_objects:Clear()
	both_note_hits:Clear()

	left_button_touch_handler.buttonCollider = nil
	left_button_touch_handler = nil

	right_button_touch_handler.buttonCollider = nil
	right_button_touch_handler = nil

	self.dead = current_hp <= 0
end

function local_class:dead_sequence(phase)
	self:stop_all_follower()

	local count = 0

	local hit_routine = function(hitter)
		local dir_vec = (self.fifer.Position - hitter.Position).normalized
		local hit_pos = hitter.Position + dir_vec * 0.4 + vector(0, 0.3, 0)

		for i = 1, 5 do
			character_util.remove_anim(hitter)
			character_util.set_anim(hitter, { name = 'attack', loop = false })

			wait_for_sec(0.3)

			music_player_util.play_sfx({sfx_name = '01_die_mouse_01'})
			music_player_util.play_sfx({sfx_name = '02_hit_big_01'})
			self.get_fx_hit():Instantiate(hit_pos)
			self.get_fx_lasthit():Instantiate(hit_pos)

			camera_util.shake(0.3, 0.1)
			character_util.spine_damage_red_pulse(self.fifer)
			character_util.spine_damage_squish_default(self.fifer)

			wait_for_sec(0.2)
		end

		count = count - 1
	end

	music_player_util.play_sfx({sfx_name = '01_player_jump_01'})
	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })
	character_util.remove_anim_and_emotion(self.fifer, true)
	character_util.remove_anim(self.fifer)
	character_util.set_direction(self.fifer, 'left')
	character_util.set_anim(self.fifer, {name = 'embarrassed'})
	character_util.set_emotion(self.fifer, {name = 'surprise'})
	character_util.normal_jump(self.fifer)

	for _, info in pairs(self.follow_rat_infos) do
		character_util.set_direction(info.mover, 'right')
		character_util.set_emotion(info.mover, {name = 'mad'})
	end

	wait_for_sec(1)

	if phase == 0 then
		local rat_pos_list = {
			self.fifer.Position + vector(-0.7, 0, 0),
			self.fifer.Position + vector(0.35, 0, 0.5),
			self.fifer.Position + vector(0.35, 0, -0.5),
			self.fifer.Position + vector(-0.35, 0, 0.5),
			self.fifer.Position + vector(-0.35, 0, -0.5),
		}
		local last_dir_list = {
			'right',
			'down',
			'up',
			'down',
			'up',
		}

		for i = 1, #self.follow_rat_infos do
			local hitter = self.follow_rat_infos[i].mover
			count = count + 1
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				wp_util.move_way_points_async(hitter, {waypoints = rat_pos_list[i], speed = 6})
				character_util.set_direction(hitter, last_dir_list[i])
				hit_routine(hitter)
			end))
		end

		wait_for_sec(0.4)

		character_util.set_anim(self.fifer, {name = 'prostrate'})
		character_util.set_emotion(self.fifer, {name = 'damaged'})

		wait_for_sec(1)

	elseif phase == 1 then
		local rat_pos_list = {
			self.fifer.Position + vector(0.5, 0, 0.35),
			self.fifer.Position + vector(0.5, 0, -0.35),
			self.fifer.Position + vector(0, 0, 0.7),
			self.fifer.Position + vector(0, 0, -0.7),
			self.fifer.Position + vector(-0.5, 0, 0.35),
			self.fifer.Position + vector(-0.5, 0, -0.35),
		}

		local last_dir_list = {
			'left',
			'left',
			'down',
			'up',
			'right',
			'right',
		}

		local hitter_list = {}
		local loop_count = math.min(#self.follow_rat_infos, 4)

		for i = 1, loop_count do
			table.insert(hitter_list, self.follow_rat_infos[i].mover)
		end

		if #self.follow_rat_infos >= 6 then
			table.insert(hitter_list, self.follow_rat_infos[6].mover)

			if #self.follow_rat_infos >= 7 then
				table.insert(hitter_list, self.follow_rat_infos[7].mover)
			end
		end

		for i = 1, #hitter_list do
			local hitter = hitter_list[i]
			count = count + 1
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				wp_util.move_way_points_async(hitter, {waypoints = rat_pos_list[i], speed = 6})
				character_util.set_direction(hitter, last_dir_list[i])
				hit_routine(hitter)
			end))
		end

		wait_for_sec(0.4)

		character_util.set_anim(self.fifer, {name = 'prostrate'})
		character_util.set_emotion(self.fifer, {name = 'damaged'})

		wait_for_sec(1)

	elseif phase == 2 then
		local rat_pos_list = {
			self.fifer.Position + vector(0.5, 0, 0.35),
			self.fifer.Position + vector(-0.5, 0, 0.35),
			self.fifer.Position + vector(0.5, 0, -0.35),
			self.fifer.Position + vector(0, 0, 0.7),
			self.fifer.Position + vector(-0.5, 0, -0.35),
			self.fifer.Position + vector(0, 0, -0.7),
		}

		local last_dir_list = {
			'left',
			'right',
			'left',
			'down',
			'right',
			'up',
		}

		local loop_count = math.min(#self.follow_rat_infos, #rat_pos_list)


		for i = 1, loop_count do
			local hitter = self.follow_rat_infos[i].mover
			count = count + 1
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				wp_util.move_way_points_async(hitter, {waypoints = rat_pos_list[i], speed = 6})
				character_util.set_direction(hitter, last_dir_list[i])
				hit_routine(hitter)
			end))
		end

		wait_for_sec(0.4)

		character_util.set_anim(self.fifer, {name = 'prostrate'})
		character_util.set_emotion(self.fifer, {name = 'damaged'})

		wait_for_sec(1)
	end

	screen_util.fade_out_async(1.0, unity_class.color.black)

	while count > 0 do
		coroutine.yield()
	end

	self:reset_after_game()

	coroutine.yield(nil)
end

function local_class:rats_angry_when_damaged()
	if table_util.get_size(self.follow_rat_infos) == 0 then return end

	local routine = function(mover, use_emoticon, requested_idx)
		local shake_duration = 0.5
		local emoticon_time = 2.5

		mover:CancelShake()
		mover:SetEmotion('mad', true)

		local emoticon
		if use_emoticon then
			emoticon = character_util.show_emoticon(mover, nil, 'angry')
		end

		character_util.shake(mover, 0.05, 0.5)

		local time_passed = 0
		while time_passed < shake_duration do
			if self.rat_angry_request_idx ~= requested_idx then
				if use_emoticon then
					emoticon:Clear()
				end
				return
			end

			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end

		if not self.dead then
			if string.match(mover.Name, 'rat') then
				mover:SetEmotion('smile', true)
			else
				mover:SetEmotion('love', true)
			end
		end

		-- 이모티콘을 부른 경우는 이모티콘이 끝날때까지 기다려줌.
		if use_emoticon then
			time_passed = 0
			local wait_duration = emoticon_time - shake_duration
			while time_passed < wait_duration do
				if self.rat_angry_request_idx ~= requested_idx then
					emoticon:Clear()
					return
				end

				time_passed = time_passed + unity_class.time.deltaTime
				coroutine.yield()
			end
		end
	end

	music_player_util.play_sfx({ sfx_name = '01_mouse_01' })

	for i, info in ipairs(self.follow_rat_infos) do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(routine, info.mover, i == 1, self.rat_angry_request_idx))
	end
end

function local_class:dispose()
	self.cs_controller = nil

	if type_util.is_npc_interactable(self.get_trio_boss()) then
		self.get_trio_boss().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if type_util.is_npc_interactable(self.get_trio_panda()) then
		self.get_trio_panda().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if type_util.is_npc_interactable(self.get_trio_man()) then
		self.get_trio_man().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if type_util.is_npc_interactable(self.get_original_fifer()) then
		self.get_original_fifer().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.fifer = nil
	self.follower_state = nil
	self.rat_list = nil
	self.following_list = nil
	self.follow_rat_infos = nil
	self.follower_offset_info = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent), 'on_event')
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
