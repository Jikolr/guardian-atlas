local local_class = newclass('SubStageFarmController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	self.get_sport_uniform_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_sport_uniform')
		else
			return get_character('knight_female_sport_uniform')
		end
	end

	-- 공주 가져오기
	self.get_princess = function()
		return get_character('princess')
	end

	self.get_oni_girl = function()
		return get_character('runner_3')
	end

	self.get_moving_horse = function(index)
		return get_character('moving_horse_npc_' .. index)
	end

	self.get_qs_moving_horse = function(index)
		return get_character('qs_moving_horse_npc_' .. index)
	end

	-- Forest 자루
	self.get_forest_sack = function(index)
		return get_field_object('s8_sack_' .. index)
	end

	-- Queenship 자루
	self.get_queenship_sack = function(index)
		return get_field_object('queenship_sack_' .. index)
	end

	self.horse_racing_quest_id = 314

	self.talk_zone_name = {
		zone_3_1 = 'horse_talk_zone_3_1'
	}

	self.is_talk_horse = {}

	-- 자유롭게 움직이는 말들 멈출 것인지
	self.stop_move_horse_routine = false

	-- 자유롭게 움직이는 말들
	self.free_moving_horse_data = {}

--region Interact With Sack Event
	-- Forest, Queenship 어느 타일셋 위치인지 저장
	self.current_tileset_info = {
		forest = 0,
		queenship = 1
	}

	self.current_tileset = self.current_tileset_info.forest

	-- 마커 이름
	self.queenship_sack_pos_marker_name = 'queenship_sack_pos'
	self.forest_sack_pos_marker_name = 'forest_sack_pos'

	-- Custom Stage Event 이름
	self.activate_sack_interactable_event_name = 'activate_sace_interactable'

	-- 이펙트
	self.get_smoke_effect = function()
		return unity_object_pool.GetOrCreate('FX_Screen_Blizzard_Cloud')
	end

	self.gradient = CS.UnityEngine.ParticleSystem.MinMaxGradient(unity_class.color.black)

	-- DropItem
	self.drop_item_list = {}
	self.green_ticket_id = 20253
	self.potion_id = 20758
--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	self.get_smoke_effect()

	for _, v in pairs(self.talk_zone_name) do
		self.is_talk_horse[v] = false
	end

	-- CCTV HitBox 크기 줄임
	local cctvs = {}
	table.insert(cctvs, get_character('cctv_1'))
	table.insert(cctvs, get_character('cctv_2'))

	for i = 1, #cctvs do
		local cctv = cctvs[i]
		if cctv ~= nil then
			cctv.Hitbox = CS.Oak.Hitbox(vector(0.7, cctv.Hitbox.size.y, 0.7))
		end
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	for i = 1, 4 do
		local horse = self.get_moving_horse(i)
		character_util.stop(horse)
	end

	if self.dash_sfx then
		music_player_util.stop_sfx(self.dash_sfx)
		self.dash_sfx = nil
	end

	self.stop_move_horse_routine = true

	if self.smoke_effect then
		self.smoke_effect:Dispose()
		self.smoke_effect = nil
	end

	if self.drop_item_list then
		for i = 1, #self.drop_item_list do
			self.drop_item_list[i]:Dispose()
			self.drop_item_list[i] = nil
		end

		self.drop_item_list = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if not self.is_talk_horse[self.talk_zone_name.zone_3_1] and
		type_util.is_zone_full_enter(e, user_party.Leader, self.talk_zone_name.zone_3_1) then

		self.is_talk_horse[self.talk_zone_name.zone_3_1] = true

		start_coroutine(function()
			-- 말 1 (smile, run) : 히히힝!! 달리기 너무 신나!
			local horse_1 = get_character('horse_npc_3_1')
			speech_bubble_util.show_speech_bubble(horse_1, { key = 'qs_horse_racing_s4_1' })

			wait_for_sec(1)

			-- 말 4 (smile, run) : 1착, 1착!!
			local horse_4 = get_character('horse_npc_3_4')
			speech_bubble_util.show_speech_bubble(horse_4, { key = 'qs_horse_racing_s4_2' })
		end)

		return true
	end

	return false
end

--- InteractEvent
function local_class:on_interact_event(e)
	for i = 1, 2 do
		if lua_helper.reference_equals(e.Target, self.get_forest_sack(i)) then
			if i == 1 then
				sp_util.play_normal_screenplay(self.interact_with_green_ticket_sack, self)
			else
				sp_util.play_normal_screenplay(self.interact_with_potion_sack, self)
			end
		elseif lua_helper.reference_equals(e.Target, self.get_queenship_sack(i)) then
			if i == 1 then
				sp_util.play_normal_screenplay(self.interact_with_green_ticket_sack, self)
			else
				sp_util.play_normal_screenplay(self.interact_with_potion_sack, self)
			end
		end
	end
end

--- StageLoadedEvent
function local_class:on_stage_loaded_event(_)
	for i = 1, 4 do
		local horse = self.get_moving_horse(i)
		self:add_free_moving_horse(horse, 'horse_move_bounds_' .. i)

		local qs_horse = self.get_qs_moving_horse(i)
		self:add_free_moving_horse(qs_horse, 'qs_horse_move_bounds_' .. i)
	end

	start_coroutine(self.free_move_horse_update, self)

	for i = 1, 2 do
		local qs_sack = self.get_queenship_sack(i)
		qs_sack.Hitbox = CS.Oak.Hitbox(vector(2, 1, 2))

		local forest_sack = self.get_forest_sack(i)
		forest_sack.Hitbox = CS.Oak.Hitbox(vector(2, 1, 2))
	end

	return true
end

--- StageEndEvent
function local_class:on_stage_end_event(_)
	self.stop_move_horse_routine = true
	return true
end

--- CustomStageEvent
function local_class:on_custom_stage_event(e)
	-- 메인 퀘스트를 진행하면서 Sack Interact가 가능하도록 수정
	if e:GetParamAt(0) == self.activate_sack_interactable_event_name then
		self.current_tileset = self.current_tileset_info.queenship

		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	end
end

function local_class:pre_setting()
	local horse_racing_quest_progress = user_progress:GetStartedQuest(self.horse_racing_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		if horse_racing_quest_progress.InnerProgress ~= nil and horse_racing_quest_progress.InnerProgress > 1 and
			horse_racing_quest_progress.InnerProgress < 8 then

			leader = self.get_sport_uniform_knight()
		end

		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')

			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
				leader.Direction, game_string:GetString(stage.Name)))

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	self:change_3d_sound(false)

	if horse_racing_quest_progress ~= nil and horse_racing_quest_progress.IsComplete then
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field_util.get_marker_pos('default_start'),
			true, true)

		self.current_tileset = self.current_tileset_info.queenship
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	elseif horse_racing_quest_progress.InnerProgress == 2 then
		self:change_bgm(true)
		change_leader_character()
		start_stage_event('right', field_util.get_marker_pos('horse_racing_3_start'),
			false, true)

	elseif horse_racing_quest_progress.InnerProgress == 3 then
		self:change_bgm(true)
		self:change_3d_sound(true)
		change_leader_character()
		start_stage_event('right', field_util.get_marker_pos('horse_racing_4_start'),
			true, true)

	elseif horse_racing_quest_progress.InnerProgress == 4 then
		self:change_bgm(true)
		self:change_3d_sound(true)
		change_leader_character()
		start_stage_event('left', field_util.get_marker_pos('horse_racing_5_start'),
			true, true)

	elseif horse_racing_quest_progress.InnerProgress == 5 then
		self:change_bgm(true)
		self:change_3d_sound(true)
		change_leader_character()
		start_stage_event('left', field_util.get_marker_pos('horse_racing_6_start'),
			true, true)

	elseif horse_racing_quest_progress.InnerProgress == 6 then
		self:change_bgm(true)
		self:change_3d_sound(true)
		change_leader_character()
		start_stage_event('down', field_util.get_marker_pos('horse_racing_7_start'),
			true, true)

	elseif horse_racing_quest_progress.InnerProgress == 7 then
		self:change_bgm(true)
		self:change_3d_sound(true)
		change_leader_character({ self.get_oni_girl() })
		start_stage_event('right', field_util.get_marker_pos('horse_racing_8_start'),
			true, true)

	else
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field_util.get_marker_pos('default_start'),
			true, true)

		if horse_racing_quest_progress.InnerProgress > 7 then
			self.current_tileset = self.current_tileset_info.queenship
			message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
		end
	end

	if horse_racing_quest_progress ~= nil and horse_racing_quest_progress.InnerProgress > 6 then
		for i = 1, 2 do
			local rice_straw = get_field_object('s8_rice_straw_' .. i)
			character_util.set_active_state(rice_straw, 'disabled')
		end
	end

	-- DropItem 설치
	local sack_center_pos = field_util.get_marker_pos('queenship_sack_pos')
	local sack_center_pos_forest = field_util.get_marker_pos('forest_sack_pos')

	local sack_center_pos_left = sack_center_pos + vector(-2, 0, 0)
	local sack_center_pos_right = sack_center_pos + vector(2, 0, 0)

	local sack_center_pos_forest_left = sack_center_pos_forest + vector(-2, 0, 0)
	local sack_center_pos_forest_right = sack_center_pos_forest + vector(2, 0, 0)

	local green_ticket_pos = { vector(1, 0, -1), vector(1.3, 0, -0.4),
	                           vector(-0.1, 0, 1.2), vector(-1.2, 0, 0.6),
	                           vector(1.2, 0, 0.4), vector(-0.8, 0, -0.9),
	                           vector(-0.9, 0, 1.1), vector(1, 0, 1) }
	local green_ticket_angle = { 30, 0, -20, 60, 15, 0, 20, -40 }

	for i = 1, #green_ticket_pos do
		local green_ticket = drop_item_util.create_item({ pos = sack_center_pos_left + green_ticket_pos[i],
		                             itemid = self.green_ticket_id, notforinven = true, sprscale = 0.75,
		                             lootstate = 'dontfindlooter' })

		local sprite = green_ticket.SpriteTransform:GetComponent(typeof(CS.CustomSprite))
		if sprite ~= nil then
			sprite.TintColor = unity_color({ 0, 1, 0, 1 })
			sprite:Rebuild()
		end

		drop_item_util.move_item(green_ticket, green_ticket.Position, { angle = green_ticket_angle[i] })
	end

	for i = 1, #green_ticket_pos do
		local green_ticket = drop_item_util.create_item({ pos = sack_center_pos_forest_left + green_ticket_pos[i],
		                                                  itemid = self.green_ticket_id, notforinven = true, sprscale = 0.75,
		                                                  lootstate = 'dontfindlooter' })

		local sprite = green_ticket.SpriteTransform:GetComponent(typeof(CS.CustomSprite))
		if sprite ~= nil then
			sprite.TintColor = unity_color({ 0, 1, 0, 1 })
			sprite:Rebuild()
		end

		drop_item_util.move_item(green_ticket, green_ticket.Position, { angle = green_ticket_angle[i] })
	end

	local potion_pos = { vector(0.9, 0, -1), vector(1.2, 0, -0.5),
	                           vector(-0.8, 0, -0.9), vector(-0.9, 0, 1.4),
	                           vector(-0.1, 0, -0.8), vector(-1.3, 0, 0),
	                           vector(-1.1, 0, 1), vector(1, 0, 1) }
	local potion_angle = { 0, 0, 0, 0, 0, 0, 0, 0 }

	for i = 1, #potion_pos do
		local potion = drop_item_util.create_item({ pos = sack_center_pos_right + potion_pos[i],
		                                                  itemid = self.potion_id, notforinven = true, sprscale = 1,
		                                                  lootstate = 'dontfindlooter' })

		drop_item_util.move_item(potion, potion.Position, { angle = potion_angle[i] })
	end

	for i = 1, #potion_pos do
		local potion = drop_item_util.create_item({ pos = sack_center_pos_forest_right + potion_pos[i],
		                                            itemid = self.potion_id, notforinven = true, sprscale = 1,
		                                            lootstate = 'dontfindlooter' })

		drop_item_util.move_item(potion, potion.Position, { angle = potion_angle[i] })
	end
end

--- 자유롭게 움직이는 말 추가
function local_class:add_free_moving_horse(target, zone_name)
	target.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

	local cool_time = random_util.get_random_int(3, 5)
	local zone_bounds = field_util.get_zone(zone_name).Bounds

	local bounds = {
		min_x = zone_bounds.min.x,
		max_x = zone_bounds.max.x,
		min_z = zone_bounds.min.z,
		max_z = zone_bounds.max.z
	}

	local horse_data = {
		horse = target,
		bounds = bounds,
		last_move_time = 0,
		cool_time = cool_time
	}

	table.insert(self.free_moving_horse_data, horse_data)
end

--- 자유롭게 움직이는 말 업데이트
function local_class:free_move_horse_update()
	local move_list = {
		vector(1, 0, 0),
		vector(-1, 0, 0),
		vector(0, 0, 1),
		vector(0, 0, -1)
	}

	while not self.stop_move_horse_routine do
		for i = 1, #self.free_moving_horse_data do
			local current_data = self.free_moving_horse_data[i]
			local horse = current_data.horse

			if unity_class.time.time - current_data.last_move_time > current_data.cool_time then
				local move_dist = move_list[random_util.get_random_int(1, 4)]

				local cur_pos = horse.Position + move_dist

				if cur_pos.x < current_data.bounds.min_x or cur_pos.x > current_data.bounds.max_x or
					cur_pos.z < current_data.bounds.min_z or cur_pos.z > current_data.bounds.max_z then

					cur_pos = horse.Position - move_dist
				end

				scene_util.set_anim_loop(horse, 'walk4legs')
				wp_util.move(horse, cur_pos, 1)

				current_data.last_move_time = unity_class.time.time
				current_data.cool_time = random_util.get_random_int(3, 5)
			end
		end

		coroutine.yield(nil)
	end
end

--region Interact With Sack Event
--- 그린 티켓 자루 상호작용 이벤트
function local_class:interact_with_green_ticket_sack()
	field_ui_util.show_narration_async({ key = 'qs_horse_racing_s8_1' })

	if self.current_tileset == self.current_tileset_info.queenship then
		field_ui_util.show_narration_async({ key = 'qs_substage_farm_green_ticket_1' })

		local choose_result = choose_util.play_choose_event({ { 'qs_substage_farm_green_ticket_2', 'mercy' }
		, { 'qs_substage_farm_green_ticket_3', 'brutal' } })

		if choose_result == 1 then
			music_player_util.play_stage_music({ state = 'muted', mix = 2 })
			local gas_loop_sfx = music_player_util.play_sfx({ sfx_name = '01_gas_01', loop = true, fade_in_time = 1 })

			local leader = get_party_leader()

			local camera = stage_camera
			self.smoke_effect = self.get_smoke_effect():Instantiate(
				camera.Transform.position, unity_class.quaternion.identity, camera.Transform)

			local main_module = self                  .smoke_effect.transform:GetComponentInChildren(
				typeof(CS.UnityEngine.ParticleSystem)).main

			self.gradient.color = unity_color({ 0.2, 0.6, 0.3, 0 })
			main_module.startColor = self.gradient
			local color = main_module.startColor.color

			local smoke_duration = 2
			local time_passed = 0

			local start_alpha = 0
			local end_alpha = 0.6

			while time_passed < smoke_duration do
				time_passed = time_passed + unity_class.time.deltaTime

				local cur_alpha = unity_class.mathf.Lerp(start_alpha, end_alpha, time_passed / smoke_duration)

				self.gradient.color = unity_color({ color.r, color.g, color.b, cur_alpha })
				main_module.startColor = self.gradient

				coroutine.yield(nil)
			end

			scene_util.set_emotion_loop(leader, 'damaged')
			scene_util.set_dead_anim(leader)

			wait_for_sec(1.5)

			music_player_util.fade_out_sfx(gas_loop_sfx, 1)
			screen_util.fade_out_async(1, unity_class.color.black, 'linear')

			if self.smoke_effect then
				self.smoke_effect:Dispose()
				self.smoke_effect = nil
			end

			self:change_leader(self.get_sport_uniform_knight())

			party_util.align_party(
				field_util.get_marker_pos(self.forest_sack_pos_marker_name) + vector(1.5, 0, 0),
				'left', 0)

			party_util.set_anim({ name = 'prostrate' })
			party_util.set_emotion({ name = 'damaged' })

			wait_for_sec(1)

			music_player_util.play_sfx_one_shot('01_intro_forest_01')
			screen_util.fade_in_async(1, unity_class.color.black, 'linear')

			music_player_util.play_sfx_one_shot('01_rustle_01')
			character_util.shake(get_party_leader(), 0.04, 1)

			wait_for_sec(1)

			party_util.remove_emotion()

			music_player_util.play_sfx_one_shot('01_player_popup_01')
			party_util.mario_jump_async('right')

			self:change_3d_sound(true)
			self:change_bgm(true)
			music_player_util.play_stage_music({ state = 'field' })

			self.current_tileset = self.current_tileset_info.forest
		end
	end
end

--- 해독제 자루 상호작용 이벤트
function local_class:interact_with_potion_sack()
	field_ui_util.show_narration_async({ key = 'qs_horse_racing_s8_2' })

	if self.current_tileset == self.current_tileset_info.forest then
		field_ui_util.show_narration_async({ key = 'qs_substage_farm_green_ticket_4' })

		local choose_result = choose_util.play_choose_event({ { 'qs_substage_farm_green_ticket_5', 'mercy' }
		, { 'qs_substage_farm_green_ticket_6', 'brutal' } })

		if choose_result == 1 then
			music_player_util.play_stage_music({ state = 'muted', mix = 2 })
			music_player_util.play_sfx_one_shot('02_magic_shield_01')
			screen_util.fade_out_async(1, unity_class.color.white, 'linear')

			self:change_leader(self.get_knight())

			party_util.align_party(
				field_util.get_marker_pos(self.queenship_sack_pos_marker_name) + vector(1.5, 0, 0),
				'left', 0)

			wait_for_sec(1)

			screen_util.fade_in_async(1, unity_class.color.white, 'linear')

			self:change_3d_sound(false)
			self:change_bgm(false)
			music_player_util.play_stage_music({ state = 'field' })

			self.current_tileset = self.current_tileset_info.queenship
		end
	end
end

function local_class:change_leader(changed_character)
	local origin_leader = get_party_leader()
	character_util.remove_anim_and_emotion(origin_leader)
	character_util.convert_to_npc(origin_leader)
	character_util.set_active_state(origin_leader, 'disabled')

	character_util.set_active_state(changed_character, 'enabled')
	character_util.remove_anim_and_emotion(changed_character)
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.KeepParty = true
	character_util.convert_to_manual_character(changed_character, param, true)
end

function local_class:change_bgm(enter_forest)
	if enter_forest then
		music_player_util.set_stage_music_clip_async({ name = 'bgm_inn', state = 'field' })
	else
		music_player_util.set_stage_music_clip_async(
			{ name = 'ondemand/v2_49_queenship/audio:bgm_queenship_main', state = 'field' })
	end
end

function local_class:change_3d_sound(enter_forest)
	if enter_forest then
		local parent_npc = get_character('horse_npc_1_1')

		if self.dash_sfx then
			music_player_util.stop_sfx(self.dash_sfx)
			self.dash_sfx = nil
		end

		self.dash_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_dash_01', parent = parent_npc, loop = true,
			  type_priority = 'event', player_priority = 'npc' })

	else
		local parent_npc = get_character('qs_horse_npc_1_1')

		if self.dash_sfx then
			music_player_util.stop_sfx(self.dash_sfx)
			self.dash_sfx = nil
		end

		self.dash_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_dash_01', parent = parent_npc, loop = true,
			  type_priority = 'event', player_priority = 'npc' })

	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
