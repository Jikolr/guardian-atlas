local local_class = newclass("AfterWorld1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region MiniGame
	-- 컨베이어 벨트 미니게임
	self.conveyorbelt_minigame = nil
	self.conveyorbelt_minigame_name = 'AfterWorldConveyorBeltMiniGame'
--endregion

	-- 이벤트 영혼들
	self.event_prisoner_num = 24
	self.event_prisoner_name = 'event_prisoner_'

	-- 파티 영혼들
	self.marty_name = 'marty'
	self.tao_name = 'tao'
	self.aggro_girl_name = 'aggro_girl'

	-- 영혼 에너지 최소, 최대값
	self.soul_energy_min = 1000
	self.soul_energy_max = 99999

	-- 피자 아이템 리스트
	self.pizza_item_list = nil

	-- 필드오브젝트
	self.block_jump_box_num = 4
	self.block_jump_box_name = 'block_jump_box_'

	self.hide_box_gate_name = 'hide_box_gate'

	self.main_block_door_name = 'main_block_door'

	self.pizza_holdable_list = nil
	self.pizza_holdable_num = 12
	self.pizza_holdable_name = 'pineapple_pizza_'

	self.destroyed_box_num = 0

	self.star_piece_box_num = 4
	self.star_piece_box_name = 'star_piece_box_'

	self.box_star_piece_name = 'box_hidden_star_piece'

	-- Sound FX
	self.factory_sfx = nil
	self.crowd_sfx = nil

	-- 아이템 ID
	self.hell_pie_item_id = 20495
	self.dough_item_id = 20532
	self.flat_dough_item_id = 20533

--region Conveyor Belt Event
	-- Flag
	self.is_in_zone = { false, false, false }
	self.is_dough_flatten = {}
	self.is_dough_fall_down = {}

	-- NPC
	self.conveyor_belt_npc_list_1 = nil
	self.conveyor_belt_npc_num_1 = 4
	self.conveyor_belt_npc_name_1 = 'conveyor_belt_1_worker_'

	self.conveyor_belt_npc_list_2 = nil
	self.conveyor_belt_npc_num_2 = 4
	self.conveyor_belt_npc_name_2 = 'conveyor_belt_2_worker_'

	self.conveyor_belt_npc_list_3 = nil
	self.conveyor_belt_npc_num_3 = 4
	self.conveyor_belt_npc_name_3 = 'conveyor_belt_3_worker_'

	self.walk_around_npc_num = 6
	self.walk_around_npc_name = 'factory_walk_around_'

	-- FieldObject
	self.conveyor_belt_fo_list_1 = nil
	self.conveyor_belt_fo_num_1 = 4
	self.conveyor_belt_fo_name_1 = 'conveyor_belt_1_box_'

	self.conveyor_belt_item_list = nil

	self.conveyor_belt_fo_list_3 = nil
	self.conveyor_belt_fo_num_3 = 4
	self.conveyor_belt_fo_name_3 = 'conveyor_belt_3_box_'

	self.walk_around_holded_fo_num = 6
	self.walk_around_holded_fo_name = 'walk_around_holded_box_'

	-- 밀가루 반죽 아이템 리스트
	self.dough_item_list = nil

	-- Zone Name
	self.conveyor_belt_zone_name_1 = 'hold_conveyor_belt_zone_1'
	self.conveyor_belt_zone_name_2 = 'hold_conveyor_belt_zone_2'
	self.conveyor_belt_zone_name_3 = 'hold_conveyor_belt_zone_3'

	-- 커스텀 이벤트
	self.hit_hammer_custom_event = 'hit_hammer'

	-- 오브젝트 풀 프리셋
	self.small_explosion_effect_preset = "FX_dead"
--endregion

--region Sub Event
	-- Flag
	self.sub_event_flags = { false, false, false, false, false }
	self.sub_event_index = {
		rest_1 = 0,
		rest_2 = 1,
		rest_3 = 2,
		fight = 3,
		ceo = 4
	}

	self.is_fight_loop = false

	-- NPC
	self.rest_1_spine_list = nil
	self.rest_1_spine_num = 5
	self.rest_1_spine_name = 'rest_ghost_1_'

	self.rest_2_spine_list = nil
	self.rest_2_spine_num = 4
	self.rest_2_spine_name = 'rest_ghost_2_'

	self.rest_3_spine_list = nil
	self.rest_3_spine_num = 3
	self.rest_3_spine_name = 'rest_ghost_3_'

	self.fight_spine_list = nil
	self.fight_spine_num = 2
	self.fight_spine_name = 'fight_ghost_'
	self.watcher_spine_num = 8
	self.watcher_spine_name = 'rest_ghost_4_'

	self.ceo = nil
	self.ceo_name = 'ceo'

	self.ceo_reaper_list = nil
	self.ceo_reaper_leader_name = 'ceo_reaper_leader'
	self.ceo_reaper_num = 4
	self.ceo_reaper_name = 'ceo_reaper_'

	-- Zone
	self.rest_1_event_zone_name = 'rest_ghost_event_1'
	self.rest_2_event_zone_name = 'rest_ghost_event_2'
	self.rest_3_event_zone_name = 'rest_ghost_event_3'
	self.fight_event_zone_name = 'fight_ghost_event'
	self.ceo_event_zone_name = 'ceo_event'

	-- 오브젝트 풀 프리셋
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"

--endregion
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomSendValueEvent), 'on_event')

	-- 미니게임 로드
	self.conveyorbelt_minigame = mini_game_manager:GetOrCreate(self.conveyorbelt_minigame_name)

	local is_mini_game_load_complete = false

	mini_game_manager:LoadResource(self.conveyorbelt_minigame_name, 'default', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield()
	end

	-- 컨베이어 벨트 NPC 설정
	self.conveyor_belt_npc_list_1 = create_generic_list(CS.Oak.Character)
	for i = 1, self.conveyor_belt_npc_num_1 do
		self.conveyor_belt_npc_list_1:Add(get_character(self.conveyor_belt_npc_name_1..i))
	end

	self.conveyor_belt_npc_list_2 = create_generic_list(CS.Oak.Character)
	for i = 1, self.conveyor_belt_npc_num_2 do
		self.conveyor_belt_npc_list_2:Add(get_character(self.conveyor_belt_npc_name_2..i))
	end

	self.conveyor_belt_npc_list_3 = create_generic_list(CS.Oak.Character)
	for i = 1, self.conveyor_belt_npc_num_3 do
		self.conveyor_belt_npc_list_3:Add(get_character(self.conveyor_belt_npc_name_3..i))
	end

	self.conveyor_belt_fo_list_1 = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.conveyor_belt_fo_num_1 do
		self.conveyor_belt_fo_list_1:Add(get_field_object(self.conveyor_belt_fo_name_1..i))
	end

	self.conveyor_belt_fo_list_3 = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.conveyor_belt_fo_num_3 do
		self.conveyor_belt_fo_list_3:Add(get_field_object(self.conveyor_belt_fo_name_3..i))
	end

	-- Walk Around NPC 설정
	local walk_around_waypoints = {}
	walk_around_waypoints[1] = { vector(53, 0, 2), vector(50, 0, 2),
	                             vector(50, 0, 24), vector(53, 0, 24) }
	walk_around_waypoints[2] = { vector(31, 0, 0), vector(31, 0, 3),
	                             vector(29, 0, 3), vector(29, 0, 17),
	                             vector(20, 0, 17), vector(20, 0, 37),
	                             vector(39, 0, 37), vector(39, 0, 17),
	                             vector(31, 0, 17), vector(31, 0, 3) }
	walk_around_waypoints[3] = { vector(-53, 0, 16), vector(-53, 0, 24),
	                             vector(-54, 0, 24), vector(-54, 0, 16),
	                             vector(-57, 0, 16), vector(-54, 0, 16),
	                             vector(-54, 0, 24), vector(-53, 0, 24),
	                             vector(-53, 0, 16), vector(-50, 0, 16) }
	walk_around_waypoints[4] = { vector(-2.5, 0, 101), vector(-10.5, 0, 101),
	                             vector(-10.5, 0, 106), vector(-10.5, 0, 101),
	                             vector(-2.5, 0, 101), vector(-2.5, 0, 85) }
	walk_around_waypoints[5] = { vector(-23, 0, 130), vector(-15, 0, 130),
	                             vector(-15, 0, 133), vector(-6, 0, 133),
	                             vector(-6, 0, 126), vector(-15, 0, 126),
	                             vector(-15, 0, 129), vector(-23, 0, 129)}
	walk_around_waypoints[6] = { vector(-17, 0, 153), vector(-17, 0, 148),
	                             vector(-6, 0, 148), vector(-6, 0, 152),
	                             vector(-6, 0, 148), vector(-17, 0, 148),
	                             vector(-17, 0, 153), vector(-28, 0, 153)}

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	local screen_size = screen_util.get_world_screen_size() / 2
	self.screen_size = vector(screen_size.x + 5, screen_size.y + 5)
	self.check_npcs = {}
	self.check_hold_up_fo = {}

	for i = 1, self.walk_around_npc_num do
		local cur_npc = get_character(self.walk_around_npc_name..i)
		local cur_fo = get_field_object(self.walk_around_holded_fo_name..i)

		if quest_progress ~= nil and quest_progress.InnerProgress < 7 then
			character_util.set_active_state(cur_npc, 'disabled')
			stage_util.set_fo_active_state(self.walk_around_holded_fo_name..i, 'disabled')
		else
			cur_npc.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			character_util.move_waypoint(cur_npc, walk_around_waypoints[i],
					2, false, 'loop', 'floor', 'down')

			command_util.execute_holdup(cur_npc, cur_fo, cur_npc.Position)
		end

		table.insert(self.check_npcs, cur_npc)
		table.insert(self.check_hold_up_fo, cur_fo)
	end

	if quest_progress ~= nil and quest_progress.InnerProgress == 8 then
		self:get_main_hold_up_npc(8)
	end

	if quest_progress ~= nil and quest_progress.InnerProgress > 5 then
		self.factory_sfx =  music_player_util.play_sfx(
				{ sfx_name = "01_amb_factory_01", loop = true, type_priority = 'loop' })
	end
end

function local_class:need_on_launch()
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	local progress_list = {
		5, 6, 7, 8, 9, 10
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomSendValueEvent))

	self.cs_controller = nil

	self.pizza_item_list = nil
	self.pizza_holdable_list = nil

	self.conveyor_belt_npc_list_1 = nil
	self.conveyor_belt_npc_list_2 = nil
	self.conveyor_belt_npc_list_3 = nil

	self.conveyor_belt_fo_list_1 = nil
	self.conveyor_belt_item_list = nil
	self.conveyor_belt_fo_list_3 = nil

	self.rest_1_spine_list = nil
	self.rest_2_spine_list = nil
	self.rest_3_spine_list = nil
	self.fight_spine_list = nil
	self.ceo = nil
	self.ceo_reaper_list = nil

	if self.factory_sfx ~= nil then
		self.factory_sfx:FadeOut()
		self.factory_sfx = nil
	end

	if self.crowd_sfx ~= nil then
		self.crowd_sfx:FadeOut()
		self.crowd_sfx = nil
	end
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.MoveFieldObjectEvent) then
		self:on_move_fo_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.QuestProgressedEvent) then
		self:on_quest_progressed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomSendValueEvent) then
		self:on_custom_send_value_event(e)
	end
	return true
end

function local_class:on_stage_loaded_event(e)
	-- SpineController Load
	self.rest_1_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.rest_1_spine_num do
		self.rest_1_spine_list:Add(self:get_spine_controller(self.rest_1_spine_name..i))
	end

	self.rest_2_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.rest_2_spine_num do
		self.rest_2_spine_list:Add(self:get_spine_controller(self.rest_2_spine_name..i))
	end

	self.rest_3_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.rest_3_spine_num do
		self.rest_3_spine_list:Add(self:get_spine_controller(self.rest_3_spine_name..i))
	end

	self.fight_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.fight_spine_num do
		self.fight_spine_list:Add(self:get_spine_controller(self.fight_spine_name..i))
	end

	for i = 1, self.watcher_spine_num do
		self.fight_spine_list:Add(self:get_spine_controller(self.watcher_spine_name..i))
	end

	self.ceo = self:get_spine_controller(self.ceo_name)

	self.ceo_reaper_list = create_generic_list(CS.Oak.SpineController)
	self.ceo_reaper_list:Add(self:get_spine_controller(self.ceo_reaper_leader_name))
	for i = 1, self.ceo_reaper_num do
		self.ceo_reaper_list:Add(self:get_spine_controller(self.ceo_reaper_name..i))
	end
end

function local_class:on_stage_start_event(e)
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress > 7 then
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.main_block_door_name, false))
		end

		if quest_progress.InnerProgress > 8 then
			for i = 1, self.block_jump_box_num do
				stage_util.set_fo_active_state(self.block_jump_box_name..i, 'disabled')
			end
		end
	end

	message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.hide_box_gate_name))

	-- Rolling Number 설정
	for i = 1, self.event_prisoner_num do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))

		character_util.set_rolling_number(get_character(self.event_prisoner_name..i).Transform,
				cur_energy, nil, 0, unity_class.color.red)
	end

	for i = 1, self.walk_around_npc_num do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(get_character(self.walk_around_npc_name..i).Transform,
				cur_energy, nil, 0, unity_class.color.red)

		if quest_progress ~= nil and quest_progress.InnerProgress < 7 then
			character_util.hide_rolling_number(get_character(self.walk_around_npc_name..i).Transform)
		end
	end

	for i = 0, self.conveyor_belt_npc_list_1.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.conveyor_belt_npc_list_1[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)
	end

	for i = 0, self.conveyor_belt_npc_list_2.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.conveyor_belt_npc_list_2[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)
	end

	for i = 0, self.conveyor_belt_npc_list_3.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.conveyor_belt_npc_list_3[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)
	end

	for i = 0, self.rest_1_spine_list.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.rest_1_spine_list[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)
	end

	for i = 0, self.rest_2_spine_list.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.rest_2_spine_list[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)

		if quest_progress ~= nil and quest_progress.InnerProgress < 7 then
			character_util.hide_rolling_number(self.rest_2_spine_list[i].Transform)

			self.rest_2_spine_list[i].gameObject:SetActive(false)
		end
	end

	for i = 0, self.rest_3_spine_list.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.rest_3_spine_list[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)

		if quest_progress ~= nil and quest_progress.InnerProgress < 7 then
			character_util.hide_rolling_number(self.rest_3_spine_list[i].Transform)

			self.rest_3_spine_list[i].gameObject:SetActive(false)
		end
	end

	for i = 0, self.fight_spine_list.Count - 1 do
		local cur_energy = math.floor(unity_class.random.Range(self.soul_energy_min, self.soul_energy_max))
		character_util.set_rolling_number(self.fight_spine_list[i].Transform,
				cur_energy, nil, 0, unity_class.color.red)

		if quest_progress ~= nil and quest_progress.InnerProgress < 7 then
			character_util.hide_rolling_number(self.fight_spine_list[i].Transform)

			self.fight_spine_list[i].gameObject:SetActive(false)
		end
	end

	self.pizza_holdable_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.pizza_holdable_num do
		self.pizza_holdable_list:Add(get_field_object(self.pizza_holdable_name..i))
	end

	self.pizza_item_list = create_generic_list(CS.Oak.DropItem)
	for i = 1, self.pizza_holdable_num do
		self.pizza_item_list:Add(drop_item_util.create_item({
			pos = self.pizza_holdable_list[i - 1].Position, itemid = self.hell_pie_item_id,
			notforinven = true, sprscale = 0.7, lootstate = 'dontfindlooter' }))
	end

	self.dough_item_list = create_generic_list(CS.Oak.DropItem)
	for i = 1, 12 do
		self.dough_item_list:Add(drop_item_util.create_item({
			pos = vector(5, 0, 108), itemid = self.dough_item_id,
			notforinven = true, sprscale = 1.3, lootstate = 'dontfindlooter' }))

		self.is_dough_flatten[i] = false
		self.is_dough_fall_down[i] = false
	end

	drop_item_util.create_item({
		pos = vector(33.3, 0, 3.7), itemid = self.hell_pie_item_id,
		notforinven = true, sprscale = 0.7, lootstate = 'dontfindlooter' })

	drop_item_util.create_item({
		pos = vector(25.3, 0, -2), itemid = self.hell_pie_item_id,
		notforinven = true, sprscale = 0.7, lootstate = 'dontfindlooter' })

	drop_item_util.create_item({
		pos = vector(25.5, 0, -2.6), itemid = self.hell_pie_item_id,
		notforinven = true, sprscale = 0.7, lootstate = 'dontfindlooter' })

	drop_item_util.create_item({
		pos = vector(25.1, 0, -3.3), itemid = self.hell_pie_item_id,
		notforinven = true, sprscale = 0.7, lootstate = 'dontfindlooter' })
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return end
	if not e.FullEnter then return end

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	local activate_rest_room = quest_progress ~= nil and quest_progress.InnerProgress > 6

	if e.Zone.Name == 'ghost_box_reset' then
		for i = 1,4 do
			message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(get_field_object('ghost_pizza_reset_'..i)))
		end
		message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(get_field_object('pizza_box_left_reset_switch')))
		message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(get_field_object('pizza_box_right_reset_switch')))
		message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(get_field_object('wasted_pizza_reset_switch')))
	end

	if not self.is_in_zone[1] and e.Zone.Name == self.conveyor_belt_zone_name_1 then
		self.is_in_zone[1] = true

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.conveyor_belt_event_1, self))
	elseif not self.is_in_zone[2] and e.Zone.Name == self.conveyor_belt_zone_name_2 then
		self.is_in_zone[2] = true

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.conveyor_belt_event_2, self))
	elseif not self.is_in_zone[3] and e.Zone.Name == self.conveyor_belt_zone_name_3 then
		self.is_in_zone[3] = true

		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.conveyor_belt_event_3, self))
	end

	if not self.sub_event_flags[self.sub_event_index.rest_1] and
			e.Zone.Name == self.rest_1_event_zone_name then
		self.sub_event_flags[self.sub_event_index.rest_1] = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rest_event_1, self))
	elseif not self.sub_event_flags[self.sub_event_index.rest_2] and
			e.Zone.Name == self.rest_2_event_zone_name then
		self.sub_event_flags[self.sub_event_index.rest_2] = true

		if activate_rest_room then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rest_event_2, self))
		end
	elseif not self.sub_event_flags[self.sub_event_index.rest_3] and
			e.Zone.Name == self.rest_3_event_zone_name then

		if activate_rest_room then
			self.sub_event_flags[self.sub_event_index.rest_3] = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rest_event_3, self))
		end
	elseif e.Zone.Name == self.fight_event_zone_name then
		if not self.sub_event_flags[self.sub_event_index.fight] then
			if activate_rest_room then
				self.sub_event_flags[self.sub_event_index.fight] = true

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fight_event, self))
			end
		end

		if not self.is_fight_loop then
			if activate_rest_room then
				self.is_fight_loop = true

				if self.crowd_sfx == nil then
					self.crowd_sfx = music_player_util.play_sfx(
							{ sfx_name = "01_crowd_buzz_03", loop = true,
							  play_pos = vector(27.5, 0, 0.5), type_priority = 'loop' })
				end

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fight_loop, self))
			end
		end
	elseif not self.sub_event_flags[self.sub_event_index.ceo] and
			e.Zone.Name == self.ceo_event_zone_name then
		self.sub_event_flags[self.sub_event_index.ceo] = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ceo_event, self))
	end
end

function local_class:on_zone_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return end
	if not e.FullLeave then return end

	if self.is_in_zone[1] and e.Zone.Name == self.conveyor_belt_zone_name_1 then
		self.is_in_zone[1] = false

		self:conveyor_belt_end_event_1()
	elseif self.is_in_zone[2] and e.Zone.Name == self.conveyor_belt_zone_name_2 then
		self.is_in_zone[2] = false

		self:conveyor_belt_end_event_2()
	elseif self.is_in_zone[3] and e.Zone.Name == self.conveyor_belt_zone_name_3 then
		self.is_in_zone[3] = false

		self:conveyor_belt_end_event_3()
	end

	if self.is_fight_loop and e.Zone.Name == self.fight_event_zone_name then
		self.is_fight_loop = false

		if self.crowd_sfx ~= nil then
			self.crowd_sfx:FadeOut()
			self.crowd_sfx = nil
		end
	end
end

function local_class:on_move_fo_event(e)
	if self.pizza_holdable_list ~= nil then
		for i = 0, self.pizza_holdable_list.Count - 1 do
			if lua_helper.reference_equals(e.FieldObject, self.pizza_holdable_list[i]) then
				self.pizza_item_list[i].Position = self.pizza_holdable_list[i].Position

				if e.FieldObject.Holdable.IsHeld then
					self.pizza_item_list[i]:SetSortingLayer(true)
				else
					self.pizza_item_list[i]:SetSortingLayer(false)
				end
			end
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	for i = 1, self.star_piece_box_num do
		if lua_helper.reference_equals(e.FieldObject, get_field_object(self.star_piece_box_name..i)) then
			self.destroyed_box_num = self.destroyed_box_num + 1

			CS.UnityEngine.Debug.LogError(self.destroyed_box_num)

			if self.destroyed_box_num == self.star_piece_box_num then
				local star_piece = get_field_object(self.box_star_piece_name)
				message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
			end

			break
		end
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == 60049 then
		if e.CurrentProgress == 6 then
			self.factory_sfx =  music_player_util.play_sfx(
					{ sfx_name = "01_amb_factory_01", loop = true, type_priority = 'loop' })
		elseif e.CurrentProgress == 7 then
			-- Walk Around NPC 설정
			local walk_around_waypoints = {}
			walk_around_waypoints[1] = { vector(53, 0, 2), vector(50, 0, 2),
			                             vector(50, 0, 24), vector(53, 0, 24) }
			walk_around_waypoints[2] = { vector(31, 0, 0), vector(31, 0, 3),
			                             vector(29, 0, 3), vector(29, 0, 17),
			                             vector(20, 0, 17), vector(20, 0, 37),
			                             vector(39, 0, 37), vector(39, 0, 17),
			                             vector(31, 0, 17), vector(31, 0, 3) }
			walk_around_waypoints[3] = { vector(-53, 0, 16), vector(-53, 0, 24),
			                             vector(-54, 0, 24), vector(-54, 0, 16),
			                             vector(-57, 0, 16), vector(-54, 0, 16),
			                             vector(-54, 0, 24), vector(-53, 0, 24),
			                             vector(-53, 0, 16), vector(-50, 0, 16) }
			walk_around_waypoints[4] = { vector(-2.5, 0, 101), vector(-10.5, 0, 101),
			                             vector(-10.5, 0, 106), vector(-10.5, 0, 101),
			                             vector(-2.5, 0, 101), vector(-2.5, 0, 85) }
			walk_around_waypoints[5] = { vector(-23, 0, 130), vector(-15, 0, 130),
			                             vector(-15, 0, 133), vector(-6, 0, 133),
			                             vector(-6, 0, 126), vector(-15, 0, 126),
			                             vector(-15, 0, 129), vector(-23, 0, 129)}
			walk_around_waypoints[6] = { vector(-17, 0, 153), vector(-17, 0, 148),
			                             vector(-6, 0, 148), vector(-6, 0, 152),
			                             vector(-6, 0, 148), vector(-17, 0, 148),
			                             vector(-17, 0, 153), vector(-28, 0, 153)}

			for i = 1, self.walk_around_npc_num do
				local cur_npc = get_character(self.walk_around_npc_name..i)

				cur_npc.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
				character_util.set_active_state(cur_npc, 'enabled')
				stage_util.set_fo_active_state(self.walk_around_holded_fo_name..i, 'enabled')

				local cur_fo = get_field_object(self.walk_around_holded_fo_name..i)
				command_util.execute_holdup(cur_npc, cur_fo, cur_npc.Position)

				character_util.show_rolling_number(cur_npc.Transform)
				character_util.move_waypoint(cur_npc, walk_around_waypoints[i],
						2, false, 'loop', 'floor', 'down')
			end

			for i = 0, self.rest_2_spine_list.Count - 1 do
				character_util.show_rolling_number(self.rest_2_spine_list[i].Transform)

				self.rest_2_spine_list[i].gameObject:SetActive(true)
			end

			for i = 0, self.rest_3_spine_list.Count - 1 do
				character_util.show_rolling_number(self.rest_3_spine_list[i].Transform)

				self.rest_3_spine_list[i].gameObject:SetActive(true)
			end

			for i = 0, self.fight_spine_list.Count - 1 do
				character_util.show_rolling_number(self.fight_spine_list[i].Transform)

				self.fight_spine_list[i].gameObject:SetActive(true)
			end
		elseif e.CurrentProgress == 8 then
			self:get_main_hold_up_npc(8)
		elseif e.CurrentProgress == 9 then
			self.main_check_npcs = nil
			self.main_check_hold_up_fo = nil
		end
	end
end

function local_class:on_custom_send_value_event(e)
	if self.dough_item_list ~= nil and self.is_in_zone[2] and e.Key == self.hit_hammer_custom_event then
		for i = 0, self.dough_item_list.Count - 1 do
			if not self.is_dough_flatten[i + 1] and (self.dough_item_list[i].Position - e.VectorParam).magnitude < 0.7 then
				self.is_dough_flatten[i + 1] = true

				local past_item = self.dough_item_list[i]

				unity_object_pool.GetOrCreate(self.small_explosion_effect_preset):Instantiate(
						past_item.Position + vector(0, 0.1, 0))

				self.dough_item_list[i] = drop_item_util.create_item({
					pos = past_item.Position, itemid = self.flat_dough_item_id,
					notforinven = true, sprscale = 1.3, lootstate = 'dontfindlooter' })
				self.dough_item_list[i].Position = past_item.Position

				past_item:ConsumeComplete()
			end
		end
	end
end
--endregion

--region SpineController Macro Function
-- 스파인 컨트롤러 이름으로 찾아서 리턴
function local_class:get_spine_controller(name)
	return CS.Oak.Stage.Instance.StageTransform:Find(name):GetComponent(typeof(CS.Oak.SpineController))
end

-- 스파인 컨트롤러에 말풍선 표시
function local_class:show_speech_bubble_spine_controller(target, string_key, shout, world_pos, skip)
	local is_shout = lua_helper.get_or_default(shout, false)
	local world_pos_val = lua_helper.get_or_default(world_pos, nil)
	local is_skip = lua_helper.get_or_default(skip, false)

	param = speech_bubble.generate_param(get_party_leader(), game_string:GetString(string_key))
	param.Speaker = target.Transform
	param.ClickToProceed = is_skip

	if is_shout then
		param.BubbleType = CS.Oak.SpeechBubbleNew.BubbleType.Shout
	else
		param.BubbleType = CS.Oak.SpeechBubbleNew.BubbleType.Talk
	end

	if world_pos_val ~= nil then
		param.ArrowDirection = CS.Oak.ArrowController.Directions.None
		param.WorldPosition = world_pos_val
	end

	coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))
end

-- 스파인 컨트롤러의 애니메이션 실행
function local_class:set_animation_spine_controller(target, args)
	local anim_name = args.name
	local loop = lua_helper.get_value(args, "loop", true)
	local upper = lua_helper.get_value(args, "upper", false)
	local scale = lua_helper.get_value(args, "scale", 1)
	local mix_duration = lua_helper.get_value(args, "mix_duration", nil)
	local sfx_name = lua_helper.get_value(args, "sfx_name", nil)
	local sfx_key = lua_helper.get_value(args, "sfx_key", nil)
	local next_anim = lua_helper.get_value(args, "next_anim", nil)

	local spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)

	if upper then
		spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Upper)
	end

	local sfx_handler = CS.Oak.LuaScriptOperationHelper.KeyframeSoundPlayDelegate(
			target.Transform.localPosition, sfx_key, sfx_name)

	target:ClearTrack(spine_track)
	target:SetAnimation(spine_track, anim_name, loop, scale, mix_duration, sfx_handler, next_anim)
end

-- 스파인 컨트롤러의 이모션 실행
function local_class:set_emotion_spine_controller(target, name, loop)
	local is_loop = lua_helper.get_or_default(loop, true)
	target:SetEmotion(name, is_loop)
end

-- 스파인 컨트롤러 애니메이션 제거
function local_class:remove_animation_spine_controller(target, upper)
	local is_upper = lua_helper.get_or_default(upper, false)

	local spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Base)

	if is_upper then
		spine_track = CS.System.Convert.ToInt32(CS.Oak.Character.SpineAnimationTrack.Upper)
	end

	target:ClearTrack(spine_track)
	target:SetAnimation(spine_track, 'idle', true)
end

-- 스파인 컨트롤러 이모션 제거
function local_class:remove_emotion_spine_controller(target)
	target:SetEmotion('idle', true)
end

-- 스파인 컨트롤러가 다른 대상 바라봄
function local_class:look_at_spine_controller(looker, target)
	local look_dir = vector_util.to_direction(target.Transform.localPosition - looker.Transform.localPosition)
	looker.Direction = look_dir == CS.Oak.Direction.None and looker.Direction or look_dir
end

-- 스파인 컨트롤러 이동
function local_class:move_to_spine_controller(
		target, pos, speed, duration, auto_dir, auto_anim_start, auto_anim_end, last_dir)
	local timer = 0
	local start_pos = target.Transform.localPosition
	local dist = pos - start_pos

	local move_duration

	if speed ~= nil then
		move_duration = dist.magnitude / speed
	else
		move_duration = duration
	end

	if auto_dir then
		target.Direction = dist:ToDirection()
	end

	if auto_anim_start then
		self:set_animation_spine_controller(target, { name = 'walk' })
	end

	while timer < move_duration do
		timer = timer + unity_class.time.deltaTime

		local cur_pos = unity_class.vector3.Lerp(start_pos, pos, timer / move_duration)

		target.Transform.localPosition = cur_pos

		coroutine.yield(nil)
	end

	if auto_anim_end then
		self:remove_animation_spine_controller(target)
	end

	if last_dir ~= nil then
		target.Direction = last_dir
	end
end
--endregion

-- 컨베이어 벨트에 올라간 상자 잡아서 던지기
function local_class:hold_box_and_throw(box, holder, box_pos, compare_axis, throw_dir, throw_speed, flag_index)
	box.Position = box_pos
	box.Holdable = CS.Oak.NonHoldable.Instance

	local start_dist

	if compare_axis == 'x' then
		start_dist = box.Position.x - holder.Position.x
	elseif compare_axis == 'z' then
		start_dist = box.Position.z - holder.Position.z
	end

	while self.is_in_zone[flag_index] do
		local cur_dist

		if compare_axis == 'x' then
			cur_dist = box.Position.x - holder.Position.x

			if start_dist * cur_dist <= 0 then
				break
			end
		elseif compare_axis == 'z' then
			cur_dist = box.Position.z - holder.Position.z

			if start_dist * cur_dist <= 0 then
				break
			end
		end

		coroutine.yield(nil)
	end

	if self.is_in_zone[flag_index] then
		box.Holdable = CS.Oak.Holdable()
		box.Holdable.BounceSfxHandleName = '01_gatcha_box_02'
		box.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		command_util.execute_holdup(holder, box, holder.Position)

		local timer = 0
		local wait_duration = 1

		while self.is_in_zone[flag_index] and timer < wait_duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if self.is_in_zone[flag_index] then
			local past_dir = holder.Direction
			character_util.set_direction(holder, throw_dir:ToDirection())

			command_util.execute_throw(holder, box, throw_dir,
					holder.Position, throw_speed, true)

			coroutine.yield(nil)

			box.Holdable = CS.Oak.NonHoldable.Instance

			wait_for_sec(0.5)

			box.CrashBehaviour = CS.Oak.PortableCrashBehaviour()

			character_util.set_direction(holder, past_dir)
		end
	end
end

-- 컨베이어 벨트 이벤트 1
function local_class:conveyor_belt_event_1()
	wait_for_sec(1)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.hold_box_and_throw, self, self.conveyor_belt_fo_list_1[0], self.conveyor_belt_npc_list_1[1],
			vector(-68, 1, 13), 'x', vector(0, 1, 1), 6, 1))

	local timer = 0
	local wait_duration = 2

	while self.is_in_zone[1] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[1] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_1[1], self.conveyor_belt_npc_list_1[2],
				vector(-68, 1, 13), 'x', vector(0, 1, 1), 6, 1))
	end

	timer = 0
	wait_duration = 2

	while self.is_in_zone[1] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[1] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_1[2], self.conveyor_belt_npc_list_1[0],
				vector(-68, 1, 13), 'x', vector(0, 1, 1), 6, 1))
	end

	timer = 0
	wait_duration = 2

	while self.is_in_zone[1] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[1] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_1[3], self.conveyor_belt_npc_list_1[3],
				vector(-68, 1, 13), 'x', vector(0, 1, 1), 6, 1))
	end
end

-- 컨베이어 벨트 이벤트 2
function local_class:conveyor_belt_event_2()
	-- 도우 위치에 배치
	for i = 0, self.dough_item_list.Count - 1 do
		local mod = i % 5

		if mod % 2 == 0 then
			self.dough_item_list[i]:SetPosition(vector(-28 - i * 2, 1, 108.7))
		else
			self.dough_item_list[i]:SetPosition(vector(-28 - i * 2, 1, 108))
		end
	end

	local move_speed = 2
	local target_pos_list = { vector(-6.7, 0, 108.7), vector(-6.2, 0, 108.7),
	                          vector(-6.7, 0, 108.2), vector(-6.2, 0, 108.2), }

	while self.is_in_zone[2] do
		for i = 0, self.dough_item_list.Count - 1 do
			if self.dough_item_list[i].Position.x >= -7.7 then
				self.is_dough_fall_down[i] = true

				local val_4 = math.floor(i / 4)
				local mod_4 = i % 4

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.dough_fall_down, self, self.dough_item_list[i],
						target_pos_list[mod_4 + 1] + vector(0, 0.3 * val_4 + 0.1, 0)))
			else
				if not self.is_dough_fall_down[i + 1] then
					self.dough_item_list[i].Position = self.dough_item_list[i].Position +
							vector(1, 0, 0) * unity_class.time.deltaTime * move_speed
				end
			end
		end

		coroutine.yield(nil)
	end
end

-- 도우 추락 처리
function local_class:dough_fall_down(dough, end_pos)
	local timer = 0

	local start_pos = dough.Position
	local duration = (end_pos - start_pos).magnitude / 6

	while self.is_in_zone[2] and timer < duration do
		timer = timer + unity_class.time.deltaTime

		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, timer / duration)

		dough:SetPosition(cur_pos, true)

		coroutine.yield(nil)
	end

	dough:SetPosition(end_pos)
end

-- 컨베이어 벨트 이벤트 3
function local_class:conveyor_belt_event_3()
	wait_for_sec(1)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.hold_box_and_throw, self, self.conveyor_belt_fo_list_3[0], self.conveyor_belt_npc_list_3[3],
			vector(-10, 1, 164), 'z', vector(1, 1, 0), 6, 3))

	local timer = 0
	local wait_duration = 2

	while self.is_in_zone[3] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[3] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_3[1], self.conveyor_belt_npc_list_3[2],
				vector(-11, 1, 164), 'z', vector(-1, 1, 0), 6, 3))
	end

	timer = 0
	wait_duration = 2

	while self.is_in_zone[3] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[3] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_3[2], self.conveyor_belt_npc_list_3[1],
				vector(-10, 1, 164), 'z', vector(1, 1, 0), 6, 3))
	end

	timer = 0
	wait_duration = 2

	while self.is_in_zone[3] and timer < wait_duration do
		timer = timer + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	if self.is_in_zone[3] then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.hold_box_and_throw, self, self.conveyor_belt_fo_list_3[3], self.conveyor_belt_npc_list_3[0],
				vector(-11, 1, 164), 'z', vector(-1, 1, 0), 6, 3))
	end
end

-- 들린 오브젝트 상태 리셋
function local_class:obj_state_reset(cur_fo)
	-- 들려있다면 관련 상태 리셋
	if cur_fo.Holdable.IsHeld then
		local holder = cur_fo.Holdable.Holder
		character_util.clear_holdup_state(holder, cur_fo)
	-- 날아가고 있다면 관련 상태 리셋
	elseif lua_helper.type_compare(cur_fo.FieldObjectBehaviour.CurrentState, CS.Oak.FieldObjectThrownState) then
		message_system:SendSync(cur_fo, CS.Oak.GetThrownEndEvent.Instance)
	end
end

-- 컨베이어 벨트 종료 처리 1
function local_class:conveyor_belt_end_event_1()
	for i = 0, self.conveyor_belt_fo_list_1.Count - 1 do
		local val = math.floor(i / 2)
		local mod = i % 2

		local cur_fo = self.conveyor_belt_fo_list_1[i]
		self:obj_state_reset(cur_fo)

		cur_fo.Position = vector(-72 + val, 0, 13 - mod)
	end
end

-- 컨베이어 벨트 종료 처리 2
function local_class:conveyor_belt_end_event_2()
	for i = 0, self.dough_item_list.Count - 1 do
		self.dough_item_list[i]:ConsumeComplete()
	end

	self.dough_item_list:Clear()

	for i = 1, 12 do
		self.dough_item_list:Add(drop_item_util.create_item({
			pos = vector(5, 0, 108), itemid = self.dough_item_id,
			notforinven = true, sprscale = 1.3, lootstate = 'dontfindlooter' }))

		self.is_dough_flatten[i] = false
		self.is_dough_fall_down[i] = false
	end
end

-- 컨베이어 벨트 종료 처리 3
function local_class:conveyor_belt_end_event_3()
	for i = 0, self.conveyor_belt_fo_list_3.Count - 1 do
		local cur_fo = self.conveyor_belt_fo_list_3[i]
		self:obj_state_reset(cur_fo)

		cur_fo.Position = vector(-12 + i, 0, 168)
	end
end

-- 휴식 이벤트 1
function local_class:rest_event_1()
	self:show_speech_bubble_spine_controller(self.rest_1_spine_list[3], 'afterworld_1_2_rest_1')

	self:show_speech_bubble_spine_controller(self.rest_1_spine_list[1], 'afterworld_1_2_rest_2')

	self:show_speech_bubble_spine_controller(self.rest_1_spine_list[0], 'afterworld_1_2_rest_3')
end

-- 휴식 이벤트 2
function local_class:rest_event_2()
	self:show_speech_bubble_spine_controller(self.rest_2_spine_list[0], 'afterworld_1_2_rest_4')
end

-- 휴식 이벤트 3
function local_class:rest_event_3()
	self:show_speech_bubble_spine_controller(self.rest_3_spine_list[0], 'afterworld_1_2_rest_5')
end

-- 싸우는 이벤트
function local_class:fight_event()
	wait_for_sec(1.5)

	self:show_speech_bubble_spine_controller(self.fight_spine_list[4], 'afterworld_1_2_fight_1')

	self:show_speech_bubble_spine_controller(self.fight_spine_list[6], 'afterworld_1_2_fight_2')
end

-- 전투 연출
function local_class:fight_loop()
	local timer = 0

	local attack_left = true
	local attack_left_duration = 1
	local attack_right_duration = 1

	while self.is_fight_loop do
		timer = timer + unity_class.time.deltaTime

		if attack_left and timer >= attack_left_duration then
			attack_left = false
			timer = 0

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.attack_and_hit, self, self.fight_spine_list[0], self.fight_spine_list[1]))
		elseif not attack_left and timer >= attack_right_duration then
			attack_left = true
			timer = 0

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.attack_and_hit, self, self.fight_spine_list[1], self.fight_spine_list[0]))
		end

		coroutine.yield(nil)
	end
end

-- 공격, 피격
function local_class:attack_and_hit(attacker, hitter)
	local dir = hitter.Transform.localPosition - attacker.Transform.localPosition

	attacker:DeviateLocal(dir.normalized * 0.3, 0.3, 0.2)
	self:set_animation_spine_controller(attacker,
			{ name = 'gauntlet_right_jap_attack', loop = false, scale = 0.7, next_anim = 'gauntlet_idle' })

	wait_for_sec(0.3)

	music_player_util.play_sfx(
			{ sfx_name = "02_hit_big_01", play_pos = hitter.Transform.localPosition })

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			hitter.Transform.localPosition + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			hitter.Transform.localPosition + vector(0, 0.3, 0))

	hitter:DeviateLocal(dir.normalized * 0.3, 0.3, 0.2)
	hitter:PulseColor(CS.Oak.Constants.DamageColor, 1, 1, 1)
	hitter:DamageSquish(1.3, 0.7, 1, 0.3)
	self:set_animation_spine_controller(hitter, { name = 'damaged' })
	self:set_emotion_spine_controller(hitter, 'damaged')

	wait_for_sec(0.2)

	self:set_animation_spine_controller(hitter, { name = 'gauntlet_idle' })
	self:set_emotion_spine_controller(hitter, 'attack')
end

-- CEO 이벤트
function local_class:ceo_event()
	self:set_animation_spine_controller(self.ceo, { name = 'question', loop = false })

	self:show_speech_bubble_spine_controller(self.ceo, 'afterworld_1_2_ceo_1')

	self:remove_animation_spine_controller(self.ceo)

	self:set_animation_spine_controller(self.ceo_reaper_list[0], { name = 'sing' })

	self:show_speech_bubble_spine_controller(self.ceo_reaper_list[0], 'afterworld_1_2_ceo_2')

	self:set_animation_spine_controller(self.ceo, { name = 'cross_arm' })

	self.ceo_reaper_list[0]:Jump(1, 0.5)
	self:set_animation_spine_controller(self.ceo_reaper_list[0], { name = 'cast' })
	self:set_emotion_spine_controller(self.ceo_reaper_list[0], 'scared')

	self:show_speech_bubble_spine_controller(self.ceo, 'afterworld_1_2_ceo_3')

	self:remove_animation_spine_controller(self.ceo)

	self:set_emotion_spine_controller(self.ceo_reaper_list[0], 'tired')

	self:show_speech_bubble_spine_controller(self.ceo, 'afterworld_1_2_ceo_4')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.move_to_spine_controller, self, self.ceo,
			self.ceo.Transform.localPosition + vector(0, 0, -8),
			3, nil, true, true, true, CS.Oak.Direction.Down))

	wait_for_sec(1)

	for i = 0, self.ceo_reaper_list.Count - 1 do
		self.ceo_reaper_list[i].Direction = CS.Oak.Direction.Down
	end

	wait_for_sec(2)

	self.ceo.Transform.localPosition = vector(999, 0, 999)
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	local check_npc_fo_func = function(npc, hold_up_fo)
		if not self:is_in_screen(npc.Position) then
			if npc.ActiveState ~= CS.Oak.ActiveState.Visible then
				npc.ActiveState = CS.Oak.ActiveState.Visible
				hold_up_fo.ActiveState = CS.Oak.ActiveState.Disabled
			end
		else
			if npc.ActiveState ~= CS.Oak.ActiveState.Enabled then
				hold_up_fo.Position = npc.Position
				hold_up_fo.ActiveState = CS.Oak.ActiveState.Enabled
				npc.ActiveState = CS.Oak.ActiveState.Enabled
				command_util.execute_holdup(npc, hold_up_fo, npc.Position, 0, false)
			end
		end
	end

	local count = #self.check_npcs
	for i = 1, count do
		local npc = self.check_npcs[i]
		local hold_up_fo = self.check_hold_up_fo[i]
		check_npc_fo_func(npc, hold_up_fo)
	end

	if self.main_check_npcs then
		local main_count = #self.main_check_npcs
		for i = 1, main_count do
			local npc = self.main_check_npcs[i]
			local hold_up_fo = self.main_check_hold_up_fo[i]
			check_npc_fo_func(npc, hold_up_fo)
		end
	end
end

function local_class:is_in_screen(pos)
	local center_pos = stage_camera.LookAtPosition
	local x_gap = math.abs(center_pos.x - pos.x)
	local y_gap = math.abs(center_pos.z - pos.z)

	if x_gap >= self.screen_size.x or y_gap >= self.screen_size.y then
		return false
	end

	return true
end

function local_class:get_main_hold_up_npc(progress)
	self.main_check_npcs = {}
	self.main_check_hold_up_fo = {}

	if progress == 8 then
		for i = 7, 11 do
			local npc = get_character('event_prisoner_' .. i)
			local hold_up_fo = get_field_object('holded_box_' .. (i - 6))

			table.insert(self.main_check_npcs, npc)
			table.insert(self.main_check_hold_up_fo, hold_up_fo)
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
