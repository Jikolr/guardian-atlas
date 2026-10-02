local local_class = newclass('SubStageCocoController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 아이템 스펙 이름
	self.coco_journal_item_spec_name = 'diary_ghost'
	self.coco_journal_item_spec_name_2 = 'last_journal'
	self.capsule_item_spec_name = 'capsule_pill'
	self.keycard_item_spec_name = 'invader_card_key'
	self.keycard_red_item_spec_name = 'invader_card_key_red'

	-- 이벤트 존 이름
	self.teleport_zone_name = 'teleport_'
	self.hole_zone_name = 'hole'
	self.jump_from_belt_zone_name = 'jump_from_belt'
	self.fire_trap_zone_name = 'fire_trap'
	self.corpse_release_zone_name = 'corpse_release'
	self.ice_block_release_zone_name = 'ice_block_release'
	self.capsule_teleport_zone_name = 'capsule_teleport'
	self.capsule_release_zone_name = 'capsule_release'
	self.box_teleport_zone_name = 'box_teleport'
	self.ice_block_moving_stop_zone_name = 'ice_block_moving_stop'
	self.box_battle_zone_name = 'box_battle_zone_'
	self.capsule_drop_zone_name = 'capsule_drop_zone'
	self.box_drop_zone_name = 'box_drop_zone'
	self.invader_specimen_talk_zone_name = 'invader_specimen_talk_'
	self.corpse_hole_zone_name = 'corpse_hole'
	self.check_ice_block_zone_name = 'check_ice_block_zone'
	self.close_glasstube_zone_name = 'close_glasstube'
	self.magic_circle_active_loop_zone_name = 'magic_circle_active_loop'
	self.hole_feed_battle_zone_name = 'hole_feed_battle_zone'

	-- 배틀 그룹 이름
	self.box_battle_group_name = 'box_battle_'

	-- 캐릭터를 가져오는 함수
	self.get_researcher = function(num) return get_character('invader_researcher_' .. num) end
	self.get_corpse = function(num) return get_character('corpse_' .. num) end
	self.get_corpse_deco = function(num) return get_character('corpse_deco_' .. num) end
	self.get_ice_block = function(num) return get_character('ice_block_' .. num) end
	self.get_invader_ice_block_mover = function(num) return get_character('invader_ice_block_mover_' .. num) end
	self.get_box_invader = function(num) return get_character('box_invader_' .. num) end
	self.get_invader_guard = function(num) return get_character('invader_guard_' .. num) end
	self.get_ddong = function(num) return get_character('ddong_' .. num) end
	self.get_ice_block_deco = function(num) return get_character('ice_block_deco_' .. num) end
	self.get_invader_keycard_researcher = function(num) return get_character('invader_keycard_researcher_' .. num) end
	self.get_invader_specimen = function(num) return get_character('invader_specimen_' .. num) end
	self.get_sleep_invader = function() return get_character('sleep_invader_guard') end

	-- 오브젝트를 가져오는 함수
	self.get_coco_journal = function(num) return get_field_object('coco_journal_' .. num) end
	self.get_box = function(num) return get_field_object('box_' .. num) end
	self.get_glasstube = function() return get_field_object('glasstube') end
	self.get_keycard_door = function(num) return get_field_object('keycard_door_' .. num) end
	self.get_drop_box = function(num) return get_field_object('drop_box_' .. num) end
	self.get_hole = function(num) return get_field_object('hole_' .. num) end
	self.get_console = function() return get_field_object('console') end
	self.get_invader_specimen_door = function() return get_field_object('invader_specimen_door') end
	self.get_corpse_guard_hole = function() return get_field_object('corpse_guard_hole') end

	-- 마커를 가져오는 함수
	self.get_teleport_marker = function(num) return field:GetMarker('teleport_' .. num) end
	self.get_hole_marker = function(num)
		if num ~= nil then
			return field:GetMarker('hole_' .. num)
		end

		return field:GetMarker('hole')
	end
	self.get_coco_journal_marker = function(num) return field:GetMarker('coco_journal_' .. num) end
	self.get_invader_guard_reset_marker = function() return field:GetMarker('invader_guard_reset_marker') end
	self.get_invader_researcher_reset_marker = function() return field:GetMarker('invader_researcher_reset_marker') end
	self.get_fire_trap_marker = function(num) return field:GetMarker('fire_trap_' .. num) end
	self.get_capsule_marker = function(num) return field:GetMarker('capsule_' .. num) end
	self.get_box_marker = function(num) return field:GetMarker('box_' .. num) end
	self.get_drop_capsule_item_marker = function(num) return field:GetMarker('capsule_item_' .. num) end
	self.get_drop_box_marker = function(num) return field:GetMarker('drop_box_' .. num) end

	-- 존을 가져오는 함수
	self.get_teleport_zone = function(num) return field:GetZone('teleport_' .. num) end
	self.get_belt_animation_zone = function(num) return field:GetZone('belt_animation_' .. num) end

	-- 이펙트 풀을 가져오는 함수
	self.get_magic_circle_effect = function() return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle') end
	self.get_invader_beam_effect = function() return unity_object_pool.GetOrCreate('FX_Event_InvaderBeam') end
	self.get_twinkle_effect = function() return unity_object_pool.GetOrCreate('FX_Object_Twinkle') end
	self.get_flamethrower_effect = function() return unity_object_pool.GetOrCreate('fx_futurecastle_flamethrower') end
	self.get_fire_effect = function() return unity_object_pool.GetOrCreate('FX_field_fire') end
	self.get_stage_item = function() return unity_object_pool.GetOrCreate('stage_item') end
	self.get_dead_effect = function() return unity_object_pool.GetOrCreate('FX_dead') end
	self.get_jump_smoke_effect = function() return unity_object_pool.GetOrCreate('fx_m_taenia_jump_smoke') end

	-- 상수
	self.teleport_num = 5

	-- 이펙트 리스트
	self.teleport_magic_circle_effect_list = nil

	-- QTE 변수
	self.swipe_type = 0
	self.is_qte_start = false

	-- req id
	self.conveyor_belt_coroutine_req_id = {
		up = 0,
		right = 0,
		down = 0,
		left = 0
	}
	self.conveyor_working_count = 0
	self.conveyor_belt_fo_list = {
		up = {},
		right = {},
		down = {},
		left = {}
	}
	self.spine_offset = vector(0, -0.3, -0.1)
	-- 컨베이어 벨트 위에 올라와 있는 FieldObject List
	self.conveyor_working_count_list = {}
	-- 컨베이어 벨트 위에서 spine offset을 적용시키지 않는 FieldObject List
	self.is_ignore_fo_spine_offset_reset_list = {}
	-- 컨베이어 벨트에 밀리지 않는 FieldObject List
	self.ignore_conveyor_belt_moving_list = {}

	self.fire_trap_req_id = 0
	self.fire_trap_corpse_list = {}

	-- item
	self.coco_journal_item_list = nil
	self.drop_capsule_item_list = nil

	-- effect
	self.twinkle_effect_list = nil

	-- bool flag
	self.is_detected = false
	self.is_teleported = false
	self.is_fired = false

	self.attack_range_renderer_list = nil
	self.rest_room_guard_attack_range_renderer_list = nil

	-- corpse pool
	self.corpse_list = {}
	self.is_corpse_used_list = nil

	-- ice_block pool
	self.ice_block_list = {}
	self.is_ice_block_used_list = nil
	self.is_run_ice_block_moving = true

	-- capsule pool
	self.capsule_list = {}
	self.is_capsule_used_list = nil
	self.capsule_item_list = nil

	-- box pool
	self.box_list = {}
	self.is_box_used_list = nil
	self.pass_capsule_list = {}
	self.is_run_capsule_moving = true
	self.is_run_capsule_change_to_box = true

	-- waypoint guard
	self.guard_detect_range_fo_list = {}
	self.guard_detect_range_renderer_list = {}
	self.guard_detect_property_list = {}

	-- keycard
	self.is_get_keycard = false
	self.is_get_keycard_red = false

	-- custom key
	self.custom_key = {
		is_get_keycard = 0,
		is_get_keycard_red = 1
	}

	self.is_battle_box_group_1 = false
	self.is_battle_box_group_2 = false

	self.is_saw_capsule_drop = false
	self.is_saw_box_drop = false

	self.is_moving = {}

	self.is_stop_all_invader_action = false

	-- 사운드 처리용 grid 진입 여부
	self.in_fire_trap_grid = false
	self.leader_in_grid_name = 'start_grid'
	-- 컨테이너 사운드
	self.aircraft_loop = nil
	self.magic_circle_active_loop = nil
	self.console_sfx = nil

	self.is_user_close_glasstube = false

	self.corpse_guard_hole_interactable = nil

	self.typing_sfx = nil

	self.is_jumping_belt_event = false

	self.battle_gate_close = false

	-- 스테이지 나가고 있는지 확인용 플래그
	self.is_leaving_stage = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ClearFlagDestroyedEvent), 'on_clear_flag_destroyed_event')

	for i = 1, 2 do
		local cur_invader_keycard_researcher = self.get_invader_keycard_researcher(i)
		character_util.remove_relate_event(cur_invader_keycard_researcher, self)
	end

	for i = 1, #self.teleport_magic_circle_effect_list do
		self.teleport_magic_circle_effect_list[i]:Dispose()
		self.teleport_magic_circle_effect_list[i] = nil
	end
	self.teleport_magic_circle_effect_list = nil

	if self.coco_journal_item ~= nil then
		for i = 1, #self.coco_journal_item_list do
			self.coco_journal_item_list[i]:ConsumeComplete()
			self.coco_journal_item_list[i] = nil
		end
		self.coco_journal_item_list = nil
	end

	if self.twinkle_effect_list ~= nil then
		for i = 1, #self.twinkle_effect_list do
			self.twinkle_effect_list[i]:Dispose()
			self.twinkle_effect_list[i] = nil
		end
		self.twinkle_effect_list = nil
	end

	if self.attack_range_renderer_list ~= nil then
		for i = 1, #self.attack_range_renderer_list do
			self.attack_range_renderer_list[i]:Dispose()
			self.attack_range_renderer_list[i] = nil
		end

		self.attack_range_renderer_list = nil
	end

	if self.rest_room_guard_attack_range_renderer_list ~= nil then
		for i = 1, #self.rest_room_guard_attack_range_renderer_list do
			self.rest_room_guard_attack_range_renderer_list[i]:Dispose()
			self.rest_room_guard_attack_range_renderer_list[i] = nil
		end

		self.rest_room_guard_attack_range_renderer_list = nil
	end

	self.corpse_list = nil
	self.ice_block_list = nil
	if self.capsule_list ~= nil then
		for i = 1, #self.capsule_list do
			self.capsule_list[i]:Dispose()
			self.capsule_list[i] = nil
		end
		self.capsule_list = nil
	end

	if self.capsule_item_list ~= nil then
		for i = 1, #self.capsule_item_list do
			self.capsule_item_list[i]:ConsumeComplete()
			self.capsule_item_list[i] = nil
		end
		self.capsule_item_list = nil
	end

	if self.drop_capsule_item_list ~= nil then
		for i = 1, #self.drop_capsule_item_list do
			self.drop_capsule_item_list[i]:ConsumeComplete()
			self.drop_capsule_item_list[i] = nil
		end
		self.drop_capsule_item_list = nil
	end

	self.pass_capsule_list = nil

	if self.aircraft_loop ~= nil then
		self.aircraft_loop:Stop()
		self.aircraft_loop = nil
	end

	if self.magic_circle_active_loop ~= nil then
		self.magic_circle_active_loop:Stop()
		self.magic_circle_active_loop = nil
	end

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_enter_conveyor_belt')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_leave_conveyor_belt')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ClearFlagDestroyedEvent), 'on_clear_flag_destroyed_event')


	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.get_magic_circle_effect()
	self.get_invader_beam_effect()
	self.get_twinkle_effect()
	self.get_flamethrower_effect()
	self.get_fire_effect()
	self.get_stage_item()
	self.get_dead_effect()

	CS.Oak.CommonScreenplay.PreloadTutorialSpine()

	yield_return(unity_object_pool, 'WaitAll')

	self.teleport_magic_circle_effect_list = {}

	self:find_and_execute_fo_all(self.get_teleport_zone, function(teleport_zone)
		local teleport_magic_circle_effect = self.get_magic_circle_effect():Instantiate(teleport_zone.Bounds.center)
		table.insert(self.teleport_magic_circle_effect_list, teleport_magic_circle_effect)
	end)
	self.teleport_magic_circle_effect_list[8].transform.localScale = unity_class.vector3.one * 0.5
	self.teleport_magic_circle_effect_list[8].transform.position = self.teleport_magic_circle_effect_list[8].transform.position + vector(0, 0, -0.3)
	self.teleport_magic_circle_effect_list[7].transform.localScale = unity_class.vector3.one * 0.5
	self.teleport_magic_circle_effect_list[7].transform.position = self.teleport_magic_circle_effect_list[7].transform.position + vector(0, 0, -0.3)

	self:conveyor_belt_animation()

	for i = 4, 6 do
		local invader = self.get_researcher(i)
		invader.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.75)
	end

	for i = 1, 2 do
		local invader_ice_block_mover = self.get_invader_ice_block_mover(i)
		invader_ice_block_mover.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.75)
	end

	self:find_and_execute_fo_all(self.get_ddong, function(ddong)
		field_ui_manager:RemoveUI(ddong, CS.Oak.FieldUiType.CharacterStats)
		character_util.set_active_state(ddong, 'visible')
	end)

	local glasstube = self.get_glasstube()
	glasstube.ActiveState = active_state('visible')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fire_trap_routine, self))

	-- 전송 연출에 사용되기 전까지 비활성화
	for i = 1, 4 do
		local drop_box = self.get_drop_box(i)
		drop_box.ActiveState = active_state('disabled')
	end

	self.is_get_keycard = stage_progress:GetCustomData(self.custom_key.is_get_keycard)
	self.is_get_keycard_red = stage_progress:GetCustomData(self.custom_key.is_get_keycard_red)

	if self.is_get_keycard then
		for i = 1, 2 do
			local cur_invader_keycard_researcher = self.get_invader_keycard_researcher(i)
			cur_invader_keycard_researcher.ActiveState = active_state('disabled')
		end
	else
		for i = 1, 2 do
			local cur_invader_keycard_researcher = self.get_invader_keycard_researcher(i)
			character_util.add_listener(cur_invader_keycard_researcher, self)
		end
	end


	if self.is_get_keycard_red then
		local console = self.get_console()
		console.Interactable = CS.Oak.NonInteractable.Instance
	end

	music_player_util.remove_stage_music_clip({ state = 'field' })
	self.aircraft_loop = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01',  fade_in_time = 2,
													  loop = true, type_priority = 'loop', player_priority = 'npc' })

	local corpse_guard_hole = self.get_corpse_guard_hole()
	self.corpse_guard_hole_interactable = corpse_guard_hole.Interactable
	corpse_guard_hole.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:need_on_launch()
	local coco_quest_progress = user_progress:GetStartedQuest(196)

	return not coco_quest_progress.IsComplete
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		return self:on_touch_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		return self:on_damage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		return self:on_item_get_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		return self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		return self:on_camera_grid_leave_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	local item_data = game_data_service.GetData('ItemData')
	local coco_journal_item_id = item_data:GetSpec(self.coco_journal_item_spec_name).Id
	local coco_journal_item_id_2 = item_data:GetSpec(self.coco_journal_item_spec_name_2).Id

	self.coco_journal_item_list = {}
	self.twinkle_effect_list = {}

	local coco_journal_offset = {
		vector(0, 0, 0),
		vector(0, 0, 0),
		vector(0, 0, -0.2)
	}
	for i = 1, 3 do
		local marker = self.get_coco_journal_marker(i)
		local item_id = coco_journal_item_id

		if i == 2 then
			item_id = coco_journal_item_id_2
		end

		local offset = coco_journal_offset[i]
		local coco_journal_item = drop_item_util.create_item({ itemid = item_id, notforinven = true, lootstate = 'dontfindlooter', pos = marker.position + vector(0, 0.7, 0) + offset })
		table.insert(self.coco_journal_item_list, coco_journal_item)

		local coco_journal = self.get_coco_journal(i)
		coco_journal.Position = marker.position

		local twinkle_effect = self.get_twinkle_effect():Instantiate(coco_journal_item.Position)
		table.insert(self.twinkle_effect_list, twinkle_effect)
	end

	local capsule_item_id = item_data:GetSpec(self.capsule_item_spec_name).Id
	self.drop_capsule_item_list = {}
	for i = 1, 16 do
		local capsule_item_marker = self.get_drop_capsule_item_marker(i)
		local drop_capsule_item = drop_item_util.create_item({ itemid = capsule_item_id, notforinven = true, lootstate = 'dontfindlooter', pos = capsule_item_marker.position })

		table.insert(self.drop_capsule_item_list, drop_capsule_item)
	end

	self:init_corpse_list()
	self:init_ice_block_list()
	self:init_capsule_list()
	self:init_box_list()

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attach_capsule_item, self))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.corpse_moving, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ice_block_moving, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.push_corpse_to_capsule_belt, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.capsule_moving, self))

	self:add_corpse_moving_researcher_guard_detect()
	self:add_rest_room_guard_detect()

	self:find_and_execute_fo_all(self.get_corpse_deco, function(corpse_deco)
		field_ui_manager:RemoveUI(corpse_deco, CS.Oak.FieldUiType.CharacterStats)
		corpse_deco.SpineController:AddColor(nil, unity_color({ 0.5, 0.7, 0.7, 0.5 }), 1, 0)
	end)

	self:find_and_execute_fo_all(self.get_ice_block_deco, function(ice_block_deco)
		field_ui_manager:RemoveUI(ice_block_deco, CS.Oak.FieldUiType.CharacterStats)
	end)

	for i = 1, 6 do
		local keycard_door = self.get_keycard_door(i)
		self:set_obstacle_color(keycard_door, unity_color({ 0.5, 0, 0, 0.5 }))
	end

	local glasstube = self.get_glasstube()
	local animator = glasstube.gameObject:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('idle')

	for i = 3, 4 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('coco_battlegate_' .. i))
	end
	for i = 3, 4 do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create('coco_battlegate_' .. i))
	end

	return true
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if not self.is_teleported then
				local i = 1
				while true do
					local zone = self.get_teleport_zone(i)

					if zone == nil then
						break
					end

					if e.Zone.Name == self.teleport_zone_name .. i then
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teleport, self, i))
						return true
					end

					i = i + 1
				end
			end

			if not self.is_fired and e.Zone.Name == self.jump_from_belt_zone_name and not self.is_jumping_belt_event then
				sp_util.play_normal_screenplay(self.jump_from_belt_qte, self)
				return true
			elseif e.Zone.Name == self.hole_zone_name then
				local hole = self.get_hole(2)
				character_util.set_direction(user_party.Leader, 'down')
				local cmd = CS.Oak.InteractCommand.Create(user_party.Leader, hole, user_party.Leader.Position)
				command_util.execute_cmd(cmd)
				return true
			elseif e.Zone.Name == self.fire_trap_zone_name then
				self:player_enter_fire_trap_zone()
				return true
			elseif e.Zone.Name == self.ice_block_moving_stop_zone_name then
				self.is_run_ice_block_moving = false
				return true
			elseif not self.is_saw_capsule_drop and e.Zone.Name == self.capsule_drop_zone_name then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_capsule_drop_zone, self))
				return true
			elseif not self.is_saw_box_drop and e.Zone.Name == self.box_drop_zone_name then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_box_drop_zone, self))
				return true
			elseif e.Zone.Name == self.invader_specimen_talk_zone_name .. 1 then
				self:invader_specimen_talk_1()
				return true
			elseif e.Zone.Name == self.invader_specimen_talk_zone_name .. 2 then
				self:invader_specimen_talk_2()
				return true
			elseif e.Zone.Name == self.invader_specimen_talk_zone_name .. 3 then
				self:invader_specimen_talk_3()
				return true
			elseif e.Zone.Name == 'cave_sound_zone' then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.play_cave_music, self, true))
				return true
			elseif e.Zone.Name == self.close_glasstube_zone_name then
				self.is_user_close_glasstube = true
				return true
			elseif e.Zone.Name == self.magic_circle_active_loop_zone_name then
				self:play_magic_circle_music(true)
				return true
			elseif e.Zone.Name == self.hole_feed_battle_zone_name and self.battle_gate_close == false then
				self.battle_gate_close = true
				for i = 1, 2 do
					message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('hole_battlegate_' .. i))
				end
				return true
			end
		end

		if e.Zone.Name == self.hole_zone_name then
			for i = 1, #self.corpse_list do
				local corpse = self.corpse_list[i]

				if lua_helper.reference_equals(e.FieldObject, corpse) and not self.is_leaving_stage then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_in_the_hole_corpse, self, corpse, e.Zone.Name))
					return true
				end
			end
		elseif e.Zone.Name == self.corpse_release_zone_name then
			for i = 1, #self.corpse_list do
				local corpse = self.corpse_list[i]

				if lua_helper.reference_equals(e.FieldObject, corpse) then
					self:corpse_change_to_capsule(corpse)
					return true
				end
			end
		elseif e.Zone.Name == self.ice_block_release_zone_name then
			for i = 1, #self.ice_block_list do
				local ice_block = self.ice_block_list[i]

				if lua_helper.reference_equals(e.FieldObject, ice_block) then
					self:release_ice_block(ice_block)
					return true
				end
			end
		elseif e.Zone.Name == self.capsule_teleport_zone_name then
			for i = 1, #self.capsule_list do
				local capsule = self.capsule_list[i]

				if lua_helper.reference_equals(e.FieldObject, capsule) then
					for j = 1, #self.pass_capsule_list do
						local pass_capsule = self.pass_capsule_list[j]

						if lua_helper.reference_equals(capsule, pass_capsule) then
							table.remove(self.pass_capsule_list, j)
							break
						end
					end

					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.capsule_into_magic_circle, self, capsule))
					return true
				end
			end
		elseif self.is_run_capsule_change_to_box and not self.is_stop_all_invader_action and e.Zone.Name == self.capsule_release_zone_name then
			for i = 1, #self.capsule_list do
				local capsule = self.capsule_list[i]

				if lua_helper.reference_equals(e.FieldObject, capsule) then
					for j = 1, #self.pass_capsule_list do
						local pass_capsule_1 = self.pass_capsule_list[j]

						if lua_helper.reference_equals(capsule, pass_capsule_1) then
							local pass_capsule_2 = self.pass_capsule_list[j + 1]

							table.remove(self.pass_capsule_list, j + 1)
							table.remove(self.pass_capsule_list, j)
							coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.capsule_change_to_box, self, pass_capsule_1, pass_capsule_2))
							return true
						end
					end
				end
			end
		elseif e.Zone.Name == self.box_teleport_zone_name then
			for i = 1, #self.box_list do
				local box = self.box_list[i]

				if lua_helper.reference_equals(e.FieldObject, box) then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.box_into_magic_circle, self, box))
					return true
				end
			end
		elseif e.Zone.Name == self.check_ice_block_zone_name then
			for i = 1, #self.ice_block_list do
				local ice_block = self.ice_block_list[i]

				if lua_helper.reference_equals(e.FieldObject, ice_block) then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_ice_block, self, ice_block))
					return true
				end
			end
		end
	end

	if self.in_fire_trap_grid and e.Zone.Name == self.fire_trap_zone_name then
		for i = 1, #self.corpse_list do
			local corpse = self.corpse_list[i]

			if lua_helper.reference_equals(e.FieldObject, corpse) then
				self:corpse_enter_fire_trap_zone(corpse)
				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == self.fire_trap_zone_name then
			self:player_leave_fire_trap_zone()
			return true
		elseif e.Zone.Name == 'cave_sound_zone' then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.play_cave_music, self, false))
			return true
		end

		if e.FullLeave then
			if e.Zone.Name == self.close_glasstube_zone_name then
				self.is_user_close_glasstube = false
				return true
			elseif e.Zone.Name == self.magic_circle_active_loop_zone_name then
				self:play_magic_circle_music(false)
				return true
			end
		end
	else
		if e.Zone.Name == self.fire_trap_zone_name then
			for i = 1, #self.corpse_list do
				local corpse = self.corpse_list[i]

				if lua_helper.reference_equals(e.FieldObject, corpse) then
					self:corpse_leave_fire_trap_zone(corpse)
					return true
				end
			end
		end
	end

	return false
end

function local_class:on_enter_conveyor_belt(e)
	if string.sub(e.Zone.Name, 1, 13) == 'conveyor_belt' then
		-- 이벤트 존 안에 들어온 객체가 캐릭터 인지 & 점프중이 아닌지
		local is_character = self:is_character(e.FieldObject)
		if is_character and not lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) then
			local direction = string.sub(e.Zone.Name, 15, string.len(e.Zone.Name))

			local is_find = false
			for i = 1, #self.conveyor_belt_fo_list[direction] do
				if lua_helper.reference_equals(e.FieldObject, self.conveyor_belt_fo_list[direction][i]) then
					is_find = true
					break
				end
			end

			if not is_find then
				if self.conveyor_working_count_list[e.FieldObject] == nil then
					self.conveyor_working_count_list[e.FieldObject] = 0
				end
				if self.conveyor_working_count_list[e.FieldObject] == 0 then
					if not self.is_ignore_fo_spine_offset_reset_list[e.FieldObject] then
						e.FieldObject.SpineController.SpineOffset = e.FieldObject.SpineController.SpineOffset + self.spine_offset

						-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 끔(플레이어 한정)
						if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
							e.FieldObject.SpineController.IsShadowActive = false
						end
					end

					local stat_ui = field_ui_manager:GetUIByKey(CS.Oak.FieldUiType.CharacterStats, e.FieldObject)
					if stat_ui ~= nil then
						stat_ui.transform.position = stat_ui.transform.position + self.spine_offset
					end
				end
				self.conveyor_working_count_list[e.FieldObject] = self.conveyor_working_count_list[e.FieldObject] + 1
				table.insert(self.conveyor_belt_fo_list[direction], e.FieldObject)

				if #self.conveyor_belt_fo_list[direction] == 1 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.conveyor_belt, self, direction))
				end
			end
			return true
		end
	end

	return false
end

function local_class:on_leave_conveyor_belt(e)
	if e.FullLeave then
		if string.sub(e.Zone.Name, 1, 13) == 'conveyor_belt' then
			-- 이벤트 존 안에 들어온 객체가 캐릭터 인지 & 점프중이 아닌지
			local is_character = self:is_character(e.FieldObject)
			if is_character then
				local direction = string.sub(e.Zone.Name, 15, string.len(e.Zone.Name))

				for i = 1, #self.conveyor_belt_fo_list[direction] do
					if lua_helper.reference_equals(e.FieldObject, self.conveyor_belt_fo_list[direction][i]) then
						self.conveyor_working_count_list[e.FieldObject] = self.conveyor_working_count_list[e.FieldObject] - 1
						if self.conveyor_working_count_list[e.FieldObject] == 0 then
							if not self.is_ignore_fo_spine_offset_reset_list[e.FieldObject] then
								e.FieldObject.SpineController.SpineOffset = e.FieldObject.SpineController.SpineOffset - self.spine_offset

								-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 껐던 것을 되돌림(플레이어 한정)
								if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
									e.FieldObject.SpineController.IsShadowActive = true
								end
							end

							local stat_ui = field_ui_manager:GetUIByKey(CS.Oak.FieldUiType.CharacterStats, e.FieldObject)
							if stat_ui ~= nil then
								stat_ui.transform.position = stat_ui.transform.position - self.spine_offset
							end
						end
						table.remove(self.conveyor_belt_fo_list[direction], i)
						break
					end
				end

				if #self.conveyor_belt_fo_list[direction] == 0 then
					self.conveyor_belt_coroutine_req_id[direction] = self.conveyor_belt_coroutine_req_id[direction] + 1
				end
				return true
			end
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local coco_journal_1 = self.get_coco_journal(1)
	local coco_journal_2 = self.get_coco_journal(2)
	local coco_journal_3 = self.get_coco_journal(3)
	local console = self.get_console()
	local corpse_guard_hole = self.get_corpse_guard_hole()

	if lua_helper.reference_equals(e.Target, coco_journal_1) then
		sp_util.play_normal_screenplay(self.interact_coco_journal_1, self)
		return true
	elseif lua_helper.reference_equals(e.Target, coco_journal_2) then
		sp_util.play_normal_screenplay(self.interact_coco_journal_2, self)
		return true
	elseif lua_helper.reference_equals(e.Target, coco_journal_3) then
		sp_util.play_normal_screenplay(self.interact_coco_journal_3, self)
		return true
	elseif lua_helper.reference_equals(e.Target, console) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_console, self))
		return true
	elseif lua_helper.reference_equals(e.Target, corpse_guard_hole) then
		self:interact_corpse_guard_hole()
		return true
	end

	local keycard_door_list_1 = {
		self.get_keycard_door(1),
		self.get_keycard_door(2)
	}
	for i = 1, #keycard_door_list_1 do
		local keycard_door = keycard_door_list_1[i]

		if lua_helper.reference_equals(e.Target, keycard_door) then
			sp_util.play_normal_screenplay(self.interact_keycard_door, self, keycard_door_list_1)
			return true
		end
	end

	local keycard_door_list_2 = {
		self.get_keycard_door(3),
		self.get_keycard_door(4),
		self.get_keycard_door(5),
		self.get_keycard_door(6)
	}
	for i = 1, #keycard_door_list_2 do
		local keycard_door = keycard_door_list_2[i]

		if lua_helper.reference_equals(e.Target, keycard_door) then
			sp_util.play_normal_screenplay(self.interact_keycard_door, self, keycard_door_list_2)
			return true
		end
	end

	for i = 1, 2 do
		local invader_keycard_researcher = self.get_invader_keycard_researcher(i)
		if lua_helper.reference_equals(e.Target, invader_keycard_researcher) then
			speech_bubble_util.show_speech_bubble(invader_keycard_researcher, {key = 'futurecastle_coco_researcher_busy'})
			if self.typing_sfx ~= nil then
				self.typing_sfx:Stop()
				self.typing_sfx = nil
			end
			self.typing_sfx = music_player_util.play_sfx(
					{sfx_name = '01_typing_01', type_priority = 'gimmick', player_priority = 'npc'
					, play_pos = invader_keycard_researcher.Position })
			return true
		end
	end

	return false
end

function local_class:on_touch_event(e)
	if not self.is_qte_start then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.SwipeLeft then
		self.swipe_type = 'left'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeRight then
		self.swipe_type = 'right'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeUp then
		self.swipe_type = 'up'
		return true
	elseif e.TouchEventType == CS.Oak.TouchEventType.SwipeDown then
		self.swipe_type = 'down'
		return true
	end

	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'invader_guard' and not self.is_detected then
		local invader_guard = get_character(e:GetParamAt(1))

		-- 만약 리더가 뛰어들었다면 제외
		if lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
				typeof(CS.Oak.CharacterControllerScreenplayState)) then
			return false
		end

		sp_util.play_normal_screenplay(self.detect_guard, self, invader_guard)
		return true
	elseif e:GetParamAt(0) == 'invader_researcher' and not self.is_detected then
		local invader_researcher = get_character(e:GetParamAt(1))
		sp_util.play_normal_screenplay(self.detect_researcher, self, invader_researcher)
		return true
	elseif e:GetParamAt(0) == 'invader_rest_room_guard' and not self.is_detected then
		local invader_rest_room_guard = get_character(e:GetParamAt(1))
		sp_util.play_normal_screenplay(self.detect_rest_room_guard, self, invader_rest_room_guard)
		return true
	elseif e:GetParamAt(0) == 'add_ignore_conveyor_belt_moving' then
		local fo_name = e:GetParamAt(1)
		local fo = get_character(fo_name)
		self:add_ignore_conveyor_belt_moving(fo)
		return true
	elseif e:GetParamAt(0) == 'remove_ignore_conveyor_belt_moving' then
		local fo_name = e:GetParamAt(1)
		local fo = get_character(fo_name)
		self:remove_ignore_conveyor_belt_moving(fo)
		return true
	elseif e:GetParamAt(0) == 'add_ignore_fo_spine_offset_reset' then
		local fo_name = e:GetParamAt(1)
		local fo = get_character(fo_name)
		self.is_ignore_fo_spine_offset_reset_list[fo] = true
		return true
	elseif e:GetParamAt(0) == 'remove_ignore_fo_spine_offset_reset' then
		local fo_name = e:GetParamAt(1)
		local fo = get_character(fo_name)
		self.is_ignore_fo_spine_offset_reset_list[fo] = false
		return true
	elseif e:GetParamAt(0) == 'quest_clear_coco_alive' then
		self:stop_all_invader_action()
		return true
	elseif e:GetParamAt(0) == 'aircraft_loop_fade_out' then
		if self.aircraft_loop ~= nil then
			self.aircraft_loop:FadeOut(1.5)
		end
		return true
	elseif e:GetParamAt(0) == 'aircraft_loop_fade_in' then
		local fade_in_time = 2

		if e.Params.Length >= 2 then
			fade_in_time = tonumber(e:GetParamAt(1))
		end

		if self.aircraft_loop ~= nil then
			self.aircraft_loop:Stop()
			self.aircraft_loop = nil
		end
		self.aircraft_loop = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01',  fade_in_time = fade_in_time,
														  loop = true, type_priority = 'loop', player_priority = 'npc' })
		return true
	end

	return false
end

function local_class:on_damage_event(e)
	if e.Info.type & CS.Oak.DamageType.Explosion ~= CS.Oak.DamageType.None then
		for i = 1, 2 do
			local invader_keycard_researcher = self.get_invader_keycard_researcher(i)

			if lua_helper.reference_equals(e.Info.target, invader_keycard_researcher) then
				invader_keycard_researcher.FieldObjectController = CS.Oak.NPCCharacterController()
				local cur_character = get_character('corpse_deco_'..i)
				speech_bubble_util.show_speech_bubble(cur_character,
						{ key = 'futurecastle_coco_invader_bomb', bubble_type = 'shout'
						, world_pos = invader_keycard_researcher.Position })

				character_util.air_spin(invader_keycard_researcher)

				if i == 1 then
					self:drop_keycard()
				end
				return true
			end
		end

		for i = 1, 8 do
			local invader = self.get_invader_guard(i)

			if lua_helper.reference_equals(e.Info.target, invader) then
				invader.FieldObjectController = CS.Oak.NPCCharacterController()

				local cur_character = get_character('corpse_deco_'..i)
				speech_bubble_util.show_speech_bubble(cur_character,
						{ key = 'futurecastle_coco_invader_bomb', bubble_type = 'shout'
						, world_pos = invader.Position })
				character_util.air_spin(invader)
				return true
			end
		end

		if lua_helper.reference_equals(e.Info.target, get_character('invader_researcher_7')) then
			local invader = get_character('invader_researcher_7')
			invader.FieldObjectController = CS.Oak.NPCCharacterController()

			local cur_character = get_character('corpse_deco_'..1)
			speech_bubble_util.show_speech_bubble(cur_character,
					{ key = 'futurecastle_coco_invader_bomb', bubble_type = 'shout'
					, world_pos = invader.Position })
			character_util.air_spin(invader)

			local corpse_guard_hole = self.get_corpse_guard_hole()
			corpse_guard_hole.Interactable = self.corpse_guard_hole_interactable
			return true
		end
	end

	return false
end

function local_class:on_item_get_event(e)
	local item_data = CS.Oak.GameDataService.GetData('ItemData')
	local keycard_item_id = item_data:GetSpec(self.keycard_item_spec_name).Id

	if lua_helper.reference_equals(e.Getter, user_party.Leader) then
		if e.Item.ItemId == keycard_item_id then
			sp_util.play_normal_screenplay(self.get_keycard_item, self)
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'fire_grid' then
			self.in_fire_trap_grid = true
			return true
		else
			self.leader_in_grid_name = e.CameraGrid.name
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'fire_grid' then
			self.in_fire_trap_grid = false
			return true
		end
	end

	return false
end

function local_class:on_clear_flag_destroyed_event(e)
	self.is_leaving_stage = true
end

--endregion

--region teleport
function local_class:teleport(num)
	local teleport_zone = self.get_teleport_zone(num)
	local teleport_marker = self.get_teleport_marker(num)

	self.is_teleported = true

	local leader_state = user_party.Leader.FieldObjectController.CurrentState
	if not lua_helper.type_compare(leader_state, CS.Oak.CharacterControllerScreenplayState) then
		field_ui_manager:Hide()
		party_util.stop_and_disable_control()
	end

	party_util.align_party(teleport_zone.Bounds.center + vector(0, 0, -1.5), 'up', 0.7, 'arc')
	music_player:PlaySfxOneShot('02_cast_magic_02')
	party_util.spine_set_alpha_fade(0, 0.5)
	
	wait_for_sec(0.2)

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	party_util.position_party(teleport_marker.position, 'down', 'arc')
	wait_for_sec(0.5)

	party_util.spine_set_alpha_fade(1, 0.5)
	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	if not lua_helper.type_compare(leader_state, CS.Oak.CharacterControllerScreenplayState) then
		party_util.reset_controllers()
		field_ui_manager:Show()
	end

	self.is_teleported = false
end
--endregion

--region hole
function local_class:fall_in_the_hole_corpse(corpse, zone_name)
	local hole_zone = field:GetZone(zone_name)

	-- 구멍에 떨어지는 연출
	character_util.spine_rotate(corpse, 360 * 6, 1.5)
	character_util.spine_scale(corpse, unity_class.vector3.zero, 1.5)
	character_util.move_to_async(corpse, hole_zone.Bounds.center, 0.5, nil, false, false, false)
	if self.leader_in_grid_name == 'corpse_grid' then
		music_player_util.play_sfx({ sfx_name = '01_fall_down_01', play_pos = corpse.Position,
									 type_priority = 'event', player_priority = 'npc'})
	end

	wait_for_sec(0.5)

	character_util.spine_rotate(corpse, 0, 0)
	character_util.spine_scale(corpse, unity_class.vector3.one, 0)
	self:release_corpse(corpse)
end

-- 일정 시간 동안 자유낙하하는 캐릭터 연출
function local_class:freefall_character(character, fall_time, offset_y)
	local curtime = unity_class.time.time
	local falltime = fall_time
	local curpos = character.Position
	local freefall = CS.CalculatorFreeFall(falltime, curpos.y, 0);
	offset_y = lua_helper.get_or_default(offset_y, 0)

	local shadow_offset = character.SpineController.ShadowTransform.localPosition

	self:add_ignore_conveyor_belt_moving(character)

	while unity_class.time.time - curtime < falltime do
		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		local y = curpos.y + dist_y + offset_y
		if y < offset_y then
			y = offset_y
		end
		character_util.set_position(character, vector(curpos.x, y, curpos.z), true)
		character.SpineController.ShadowTransform.localPosition = shadow_offset + self.spine_offset + vector(0, -y + 1, 0)
		coroutine.yield(nil)
	end

	self.get_jump_smoke_effect():Instantiate(character.Position + self.spine_offset)
	self:remove_ignore_conveyor_belt_moving(character)
	character_util.set_position(character, vector(curpos.x, offset_y, curpos.z))
	character.SpineController.ShadowTransform.localPosition = shadow_offset
	character.SpineController.IsShadowActive = false
end
--endregion

--region interact_coco_journal
-- 코코 일지 1에 상호작용 했을 때
function local_class:interact_coco_journal_1()
	local coco_journal_1 = self.get_coco_journal(1)

	-- 나레이션 박스1
	party_util.align_to_target(coco_journal_1, 'right', 1, 'arc')

	-- 암흑 마법사의 이름
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_1_1' })

	-- 암흑 마법사 베스는 자신의 이름을 불리는 것을 극도로 싫어한다.
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_1_2' })

	-- 아마 정체를 숨기는 일을 즐겨서 그런 것일까?
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_1_3' })

	-- 아니면 베스라는 이름에 특별한 무언가가 있는 것일까?
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_1_4' })

	-- 하나 확실한 것은, 베스라 불릴 때마다 후드 안에서도 꿈틀거리는 것이 꽤나 재밌다는 점이다.
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_1_5' })
end

-- 코코 일지 2에 상호작용 했을 때
function local_class:interact_coco_journal_2()
	local coco_journal_2 = self.get_coco_journal(2)

	-- 나레이션 박스2
	party_util.align_to_target(coco_journal_2, 'right', 1, 'arc')

	-- 인베이더의 변이
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_2_1' })

	-- 인베이더를 슈퍼 인베이더로 변이시키는 실험은 이미 확실한 결과를 얻었다.
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_2_2' })

	-- 하지만 여전히 실험은 계속되고 있다.
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_2_3' })

	-- 슈퍼 인베이더는 그들이 바라던 결과가 아니었던 것일까?
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_2_4' })

	-- 그렇다면 그 결과는 대체 뭘까?
	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_2_5' })
end

-- 코코 일지 3에 상호작용 했을 때
function local_class:interact_coco_journal_3()
	local coco_journal_3 = self.get_coco_journal(3)

	-- 나레이션 박스3
	party_util.align_to_target(coco_journal_3, 'down', 1, 'arc')

	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_3_1' })

	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_3_2' })

	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_3_3' })

	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_3_4' })

	field_ui_util.show_narration_async( { key = 'futurecastle_coco_journal_3_5' })
end
--endregion

--region conveyor_belt
function local_class:conveyor_belt_animation()
	self:find_and_execute_fo_all(self.get_belt_animation_zone, function(target_zone)
		local belts = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)

		--- 해당 존에 있는 모든 오브젝트를 순회
		for index = 0, belts.Count - 1 do
			local belt = belts[index]

			if string.sub(belt.Name, 1, 13) == '[gimmick]belt' then
				local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
				animator:Play('xmas_belt_rolling')
				belt.ActiveState = active_state('visible')
			end
		end

		belts:Dispose()
	end)
end

function local_class:conveyor_belt(direction_str)
	local direction = self:string_to_direction(direction_str)
	local direction_vector = direction_util.to_vector3(direction)
	local speed = 3

	self.conveyor_belt_coroutine_req_id[direction_str] = self.conveyor_belt_coroutine_req_id[direction_str] + 1
	local req_id = self.conveyor_belt_coroutine_req_id[direction_str]

	if self.conveyor_working_count == 0 then
	end
	self.conveyor_working_count = self.conveyor_working_count + 1

	while req_id == self.conveyor_belt_coroutine_req_id[direction_str] and not self.is_leaving_stage do
		for i = 1, #self.conveyor_belt_fo_list[direction_str] do
			local fo = self.conveyor_belt_fo_list[direction_str][i]

			if not self.ignore_conveyor_belt_moving_list[fo] then
				fo.Position = fo.Position + (direction_vector * (speed * unity_class.time.deltaTime))
				--CS.Oak.MoveOneFrameStageLogic.ExecuteMove(fo, direction_vector, speed * unity_class.time.deltaTime)
			end
		end

		coroutine.yield()
	end

	self.conveyor_working_count = self.conveyor_working_count - 1
	if self.conveyor_working_count == 0 then
	end
end

function local_class:add_ignore_conveyor_belt_moving(fo)
	self.ignore_conveyor_belt_moving_list[fo] = true
end

function local_class:remove_ignore_conveyor_belt_moving(fo)
	self.ignore_conveyor_belt_moving_list[fo] = false
end
--endregion

--region jump_from_belt
function local_class:jump_from_belt_qte()
	local qte_type = 'down'
	self.is_jumping_belt_event = true

	time_util.mod('jump_qte', 0.2)

	music_player_util.play_sfx_one_shot('01_qte_action_wind_02')
	self:qte_swipe(qte_type, 1)

	time_util.unmod('jump_qte')

	if self.swipe_type == qte_type then
		self.is_ignore_fo_spine_offset_reset_list[user_party.Leader] = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			local spine_offset = user_party.Leader.SpineController.SpineOffset
			local duration = 0.3
			local time_passed = 0

			-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 껏던 것을 되돌림(플레이어 한정)
			user_party.Leader.SpineController.IsShadowActive = true

			while time_passed < duration do
				time_passed = time_passed + unity_class.time.deltaTime

				local progress = time_passed / duration
				user_party.Leader.SpineController.SpineOffset = spine_offset - (self.spine_offset * progress)

				coroutine.yield()
			end

			user_party.Leader.SpineController.SpineOffset = spine_offset - self.spine_offset
		end))
		character_util.normal_jump(user_party.Leader, true)
		character_util.move_to_async(user_party.Leader, vector_util.get_x0z(user_party.Leader.Position) + vector(0, 0, -2), 0.3, nil, true, true)
		music_player_util.play_sfx_one_shot('01_land_01')

		self.is_ignore_fo_spine_offset_reset_list[user_party.Leader] = false
	else
		yield_return_func(self.end_of_belt, self)
	end
	self.is_jumping_belt_event = false
end

function local_class:end_of_belt()
	local glasstube = self.get_glasstube()

	while self.conveyor_working_count_list[user_party.Leader] > 0 do
		coroutine.yield()
	end

	user_party.Leader.SpineController.SpineOffset = user_party.Leader.SpineController.SpineOffset + self.spine_offset
	-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 끔(플레이어 한정)
	user_party.Leader.SpineController.IsShadowActive = false

	character_util.spine_rotate(user_party.Leader, 360 * 2, 1)
	character_util.spine_scale(user_party.Leader, unity_class.vector3.zero, 1)
	wait_for_sec(1)

	camera_util.shake(0.2, 2)
	glasstube:Shake(0.1, 2.5)
	wait_for_sec(2)

	wait_for_sec(0.5)

	screen_util.fade_out_circular_async(1, 'linear')

	wait_for_sec(0.5)

	local restart_marker = self.get_hole_marker(1)
	user_party.Leader.Position = restart_marker.position
	character_util.set_direction(user_party.Leader, restart_marker.direction)
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.spine_rotate(user_party.Leader, 0, 0)
	character_util.spine_scale(user_party.Leader, unity_class.vector3.one, 0)

	user_party.Leader.SpineController.SpineOffset = user_party.Leader.SpineController.SpineOffset - self.spine_offset
	-- 이동 중에는 그림자 off 조절이 불가능해서, 컨베이어 벨트 위에 있을 때는 그림자를 껏던 것을 되돌림(플레이어 한정)
	user_party.Leader.SpineController.IsShadowActive = true

	screen_util.fade_in_circular_async(1, 'linear')
end
--endregion

--region fire_trap
function local_class:fire_trap_routine()
	local trap_count = 17
	local working_duration = 2.3
	local delay = 2
	local fire_effect_list = {}

	self.is_fire_trap_working = false

	while not self.is_leaving_stage do
		self.is_fire_trap_working = true
		if self.in_fire_trap_grid then
			for i = 1, trap_count do
				local fire_trap_marker = self.get_fire_trap_marker(i)
				local position = fire_trap_marker.position
				local direction = fire_trap_marker.direction
				local angle = 0
				local offset = unity_class.vector3.zero

				if direction == self:string_to_direction('up') then
					angle = 0
					offset = vector(0, 0, 0.75+0.35)
				elseif direction == self:string_to_direction('right') then
					angle = 90
					offset = vector(0.75, 0, 0.25)
				elseif direction == self:string_to_direction('down') then
					angle = 180
					offset = vector(0, 0, -0.35)
				else
					angle = 270
					offset = vector(0.75, 0, 0.25-0.35)
				end

				local fire_effect = self.get_flamethrower_effect():Instantiate(position + offset, unity_class.quaternion.Euler(0, angle, 0), nil)

				table.insert(fire_effect_list, fire_effect)
			end

			music_player_util.play_sfx_one_shot('02_fire_slash_03')
		end
		wait_for_sec(working_duration)

		for i = #fire_effect_list, 1, -1 do
			table.remove(fire_effect_list, i)
		end

		self.is_fire_trap_working = false

		wait_for_sec(delay)
	end
end

function local_class:player_enter_fire_trap_zone()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fire_trap_working, self))
end

function local_class:player_leave_fire_trap_zone()
	self.fire_trap_req_id = self.fire_trap_req_id + 1
end

function local_class:fire_trap_working()
	self.fire_trap_req_id = self.fire_trap_req_id + 1
	local req_id = self.fire_trap_req_id

	while req_id == self.fire_trap_req_id do
		if self.is_fire_trap_working then
			-- 실패 처리가 중복 실행되지 않게
			if self.is_fired then
				break
			end

			self.is_fired = true

			-- 실패 처리
			field_ui_manager:Hide()
			party_util.stop_and_disable_control()

			-- 불이 붙는다.
			music_player_util.play_sfx_one_shot('02_dash_fire_01')
			music_player:PlaySfxOneShot('01_catch_fire_01')
			local fire_effect = self.get_fire_effect():Instantiate(user_party.Leader.Position, unity_class.quaternion.identity, user_party.Leader.transform)
			fire_effect.transform.localScale = unity_class.vector3.one * 0.5

			music_player_util.play_sfx_one_shot('03_runaway_01')
			character_util.set_emotion(user_party.Leader, { name = 'hurt' })
			character_util.set_anim(user_party.Leader, { name = 'embarrassed' })
			character_util.normal_jump_async(user_party.Leader, true)

			music_player_util.play_sfx_one_shot('01_drown_01')
			screen_util.fade_out_circular_async(1, 'linear')

			user_party.Leader.Position = vector(999, 0, 999)

			wait_for_sec(0.5)
			local restart_marker = self.get_hole_marker(1)
			user_party.Leader.Position = restart_marker.position
			character_util.set_direction(user_party.Leader, restart_marker.direction)
			character_util.remove_anim_and_emotion(user_party.Leader)
			camera_util.return_to_leader(0.01)

			fire_effect:Dispose()

			screen_util.fade_in_circular_async(1, 'linear')

			party_util.reset_controllers()
			field_ui_manager:Show()

			self.is_fired = false

			break
		end

		coroutine.yield()
	end
end

function local_class:corpse_enter_fire_trap_zone(corpse)
	local is_in_list = false
	local corpse_list_num = #self.fire_trap_corpse_list

	for i = 1, #self.fire_trap_corpse_list do
		if lua_helper.reference_equals(corpse, self.fire_trap_corpse_list[i]) then
			is_in_list = true
			break
		end
	end

	if not is_in_list then
		table.insert(self.fire_trap_corpse_list, corpse)
	end

	if corpse_list_num == 0 then
		music_player_util.play_sfx({sfx_name = '01_interact_chickenhouse_01',
									play_pos = corpse.Position, type_priority = 'default', player_priority = 'npc'})
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fire_trap_corpse_working, self))
	end
end

function local_class:corpse_leave_fire_trap_zone(corpse)
	for i = 1, #self.fire_trap_corpse_list do
		if lua_helper.reference_equals(corpse, self.fire_trap_corpse_list[i]) then
			table.remove(self.fire_trap_corpse_list, i)
			break
		end
	end
end

function local_class:fire_trap_corpse_working()
	while #self.fire_trap_corpse_list > 0 do
		if self.is_fire_trap_working then
			for i = 1, #self.fire_trap_corpse_list do
				local corpse = self.fire_trap_corpse_list[i]
				character_util.spine_damage_squish_default(corpse)
				corpse.SpineController:AddColor(nil, unity_color({ 0, 0, 0, 1 }), 1, 0.2)
			end
		end

		coroutine.yield()
	end
end
--endregion

--region waypoint_guard
function local_class:add_guard_detect_range(fo, distance, angle, event_name, attack_range_offset)
	local attack_range_renderer = CS.Oak.GhostGuardAttackRangeRenderer(fo, distance, angle)
	attack_range_renderer.AttackRange:Show(0)
	attack_range_renderer:Update(fo)
	if attack_range_offset then
		attack_range_renderer.AttackRange.CacheTransform.position = attack_range_renderer.AttackRange.CacheTransform.position + attack_range_offset
	end

	local guard_detect_range_fo_num = #self.guard_detect_range_fo_list

	table.insert(self.guard_detect_range_fo_list, fo)
	self.guard_detect_range_renderer_list[fo] = attack_range_renderer
	self.guard_detect_property_list[fo] = {
		distance = distance,
		angle = angle,
		event_name = event_name
	}

	if guard_detect_range_fo_num == 0 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.guard_detect_range_routine, self))
	end
end

function local_class:remove_guard_detect_range(fo)
	for i = 1, #self.guard_detect_range_fo_list do
		local guard = self.guard_detect_range_fo_list[i]

		if lua_helper.reference_equals(fo, guard) then
			table.remove(self.guard_detect_range_fo_list, i)
			self.guard_detect_range_renderer_list[fo]:Dispose()
			self.guard_detect_range_renderer_list[fo] = nil
			self.guard_detect_property_list[fo] = nil
			break
		end
	end
end

function local_class:guard_detect_range_routine()
	local vps = CS.ViewportScaler.Instance
	local sc = stage.StageCamera

	while #self.guard_detect_range_fo_list > 0 do
		for i = 1, #self.guard_detect_range_fo_list do
			local guard = self.guard_detect_range_fo_list[i]
			local detect_range_renderer = self.guard_detect_range_renderer_list[guard]
			local property = self.guard_detect_property_list[guard]

			local vp_point;
			if vps.IsEnabled and vps.CurrentCamera == sc then
				vp_point = vps:WorldToViewportPoint(guard.Position)
			else
				vp_point = sc.Camera:WorldToViewportPoint(guard.Position)
			end

			local visible = (vp_point.x > -0.2 and vp_point.x < 1.2 and vp_point.y > -0.3 and vp_point.y < 1.03)

			if visible == true then
				detect_range_renderer:Update(guard)

				if not self.is_detected then
					local is_in_sight = self:is_in_sight(guard, user_party.Leader, property.distance, property.angle, height)
					if is_in_sight then
						message_system:Publish(CS.Oak.CustomStageEvent.Create(guard, { property.event_name, guard.Name }))
					end
				end
			end

		end

		coroutine.yield()
	end
end

function local_class:detect_guard(invader_guard)
	self.is_detected = true
	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'detected_invader', invader_guard.Name }))
	music_player_util.play_sfx_one_shot('01_siren_oneshot_01')

	speech_bubble_util.show_speech_bubble(invader_guard, { key = 'futurecastle_coco_guard_shout', bubble_type = 'shout', screen_pos = vector(-50, 250), type_speed = 0 })

	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)
	wait_for_sec(0.8)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	wait_for_sec(0.5)

	local marker = self.get_invader_guard_reset_marker()
	camera_util.move_async(marker.position, 0.01)
	party_util.position_party(marker.position, marker.direction, 'arc')
	party_util.remove_emotion()
	party_util.remove_animation()

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'reset', 'invader_guard' }))
	camera_util.move_async(user_party.Leader.Position, 0.01, { end_target = user_party.Leader })
	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false
end

function local_class:detect_researcher(invader_researcher)
	self.is_detected = true
	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { 'detected_invader', invader_researcher.Name }))

	music_player_util.play_sfx_one_shot('01_siren_oneshot_01')
	speech_bubble_util.show_speech_bubble(invader_researcher, { key = 'futurecastle_coco_guard_shout', bubble_type = 'shout', screen_pos = vector(-50, 250), type_speed = 0 })

	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)
	wait_for_sec(0.8)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	wait_for_sec(0.5)

	local marker = field:GetMarker('hole_outer')
	if user_party.Leader.Position.y >= 1 then
		marker = self.get_invader_researcher_reset_marker()
	end

	party_util.position_party(vector(999, 0, 999), marker.direction, 'arc')
	coroutine.yield()

	party_util.position_party(marker.position, marker.direction, 'arc')
	party_util.remove_emotion()

	party_util.remove_animation()

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'reset', 'invader_researcher' }))

	speech_bubble_util.remove_bubble(invader_researcher)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false
end

function local_class:detect_rest_room_guard(invader_rest_room_guard, marker_name)
	self.is_detected = true

	music_player_util.play_sfx_one_shot('01_siren_oneshot_01')
	character_util.remove_anim(invader_rest_room_guard)
	character_util.normal_jump(invader_rest_room_guard, true)
	speech_bubble_util.show_speech_bubble(invader_rest_room_guard, { key = 'futurecastle_coco_guard_shout', bubble_type = 'shout', screen_pos = vector(-50, 250), type_speed = 0 })

	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)
	wait_for_sec(0.8)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	wait_for_sec(0.5)

	local reset_marker_name = lua_helper.get_or_default(marker_name, nil)
	if reset_marker_name == nil then
		local marker = self.get_hole_marker(2)
		party_util.position_party(marker.position, marker.direction, 'arc')
	else
		local marker = field:GetMarker(reset_marker_name)
		party_util.position_party(marker.position, marker.direction, 'arc')
	end
	party_util.remove_emotion()
	party_util.remove_animation()
	camera_util.return_to_leader(0.01)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'reset', 'invader_rest_room_guard' }))

	speech_bubble_util.remove_bubble(invader_rest_room_guard)
	character_util.set_anim(invader_rest_room_guard, { name = 'seat' })

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false
end

--- 플레이어가 감시에 보이는지 체크
function local_class:is_in_sight(fo, target, distance, angle, height)
	if fo.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	height = lua_helper.get_or_default(height, 0)

	local offset = unity_class.vector3.zero
	if user_party.Leader.Position.y >= 1 then
		offset = vector(0, 1, -0.7)
	end

	local diff = target.Bounds.center - vector_util.get_x0z(fo.Bounds.center + offset)

	if diff.magnitude > distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > angle / 2 then
		return false
	end

	return true
end
--endregion

--region corpse
function local_class:init_corpse_list()
	self.corpse_list = {}
	self.is_corpse_used_list = {}

	self:find_and_execute_fo_all(self.get_corpse, function(corpse)
		corpse.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.9)
		corpse.CrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance
		corpse.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		field_ui_manager:RemoveUI(corpse, CS.Oak.FieldUiType.CharacterStats)

		table.insert(self.corpse_list, corpse)
		table.insert(self.is_corpse_used_list, false)
	end)
end

function local_class:get_corpse_from_pool()
	local corpse = nil

	for i = 1, #self.corpse_list do
		if not self.is_corpse_used_list[i] then
			self.is_corpse_used_list[i] = true
			corpse = self.corpse_list[i]
			corpse.SpineController:ResetAllColors()
			character_util.set_active_state(corpse, 'enabled')
			character_util.set_emotion(corpse, { name = 'hurt' })
			corpse.OverrideCrashBehaviour = nil
			corpse.SpineController.IsShadowActive = true
			break
		end
	end

	return corpse
end

function local_class:release_corpse(corpse)
	for i = 1, #self.corpse_list do
		if lua_helper.reference_equals(corpse, self.corpse_list[i]) then
			self.is_corpse_used_list[i] = false
			corpse.Position = vector(999, 0, 999)
			character_util.remove_emotion(corpse)
			character_util.set_active_state(corpse, 'disabled')
			break
		end
	end
end
--endregion

--region corpse_moving
function local_class:add_corpse_moving_researcher_guard_detect()
	for i = 4, 6 do
		local researcher = self.get_researcher(i)
		self:add_guard_detect_range(researcher, 4, 60, 'invader_researcher', vector(0, 1, -0.7))
	end
end

function local_class:corpse_drop()
	local researcher = self.get_researcher(7)

	while not self.is_stop_all_invader_action do
		character_util.set_direction(researcher, 'up')
		wait_for_sec(0.75)

		local corpse = self:get_corpse_from_pool()
		while not corpse do
			corpse = self:get_corpse_from_pool()
			coroutine.yield()
		end

		corpse.Holdable = CS.Oak.Holdable()
		corpse.Position = researcher.Position + direction_util.to_vector3(researcher.Direction)
		corpse.SpineController:AddColor(nil, unity_color({ 0.5, 0.7, 0.7, 0.5 }), 1, 0)

		command_util.execute_holdup(researcher, corpse, researcher.Position, 0.12, true)
		wait_for_sec(0.75 + 0.12)

		corpse.SpineController.IsShadowActive = false

		character_util.set_direction(researcher, 'down')
		wait_for_sec(0.75)

		corpse.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		command_util.execute_throw(researcher, corpse, direction_util.to_vector3(researcher.Direction), researcher.Position, 8, true)

		coroutine.yield()
		message_system:SendSync(corpse, CS.Oak.GetThrownEndEvent.Instance)
		coroutine.yield()
		corpse.Holdable = CS.Oak.NonHoldable.Instance

		local hole_zone = field:GetZone(self.corpse_hole_zone_name)

		-- 구멍에 떨어지는 연출
		character_util.spine_rotate(corpse, 360 * 6, 1.5)
		character_util.spine_scale(corpse, unity_class.vector3.zero, 1.5)
		character_util.move_to_async(corpse, hole_zone.Bounds.center, 0.5, nil, false, false, false)

		wait_for_sec(0.5)

		character_util.spine_rotate(corpse, 0, 0)
		character_util.spine_scale(corpse, unity_class.vector3.one, 0)
		corpse.Position = vector(999, 0, 999)
		coroutine.yield()
		self:release_corpse(corpse)

		wait_for_sec(0.75)
	end

	if self.is_stop_all_invader_action then
		character_util.set_anim(researcher, { name = 'unique/ice' })
	end
end

function local_class:interact_corpse_guard_hole()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(guard, { 'invader_guard', 'invader_researcher_7' }))
end

function local_class:corpse_moving()
	local researcher_4 = self.get_researcher(4)
	local researcher_5 = self.get_researcher(5)
	local researcher_6 = self.get_researcher(6)

	while not self.is_stop_all_invader_action do
		wait_all({
			util.cs_generator(character_util.move_waypoint_async, researcher_4, researcher_4.Position + vector(1, 0, 0), 2, false, nil, nil, nil),
			util.cs_generator(character_util.move_waypoint_async, researcher_5, researcher_5.Position + vector(0, 0, 1), 2, false, nil, nil, nil),
			util.cs_generator(character_util.move_waypoint_async, researcher_6, researcher_6.Position + vector(0, 0, 1), 2, false, nil, nil, nil),
		})
		wait_for_sec(0.75)

		local corpse_1 = self:get_corpse_from_pool()
		while not corpse_1 do
			corpse_1 = self:get_corpse_from_pool()
			coroutine.yield()
		end
		local corpse_2 = self:get_corpse_from_pool()
		while not corpse_2 do
			corpse_2 = self:get_corpse_from_pool()
			coroutine.yield()
		end
		local corpse_3 = self:get_corpse_from_pool()
		while not corpse_3 do
			corpse_3 = self:get_corpse_from_pool()
			coroutine.yield()
		end

		corpse_1.Holdable = CS.Oak.Holdable()
		corpse_2.Holdable = CS.Oak.Holdable()
		corpse_3.Holdable = CS.Oak.Holdable()
		corpse_1.Position = researcher_4.Position + direction_util.to_vector3(researcher_4.Direction)
		corpse_2.Position = researcher_5.Position + direction_util.to_vector3(researcher_5.Direction)
		corpse_3.Position = researcher_6.Position + direction_util.to_vector3(researcher_6.Direction)
		corpse_1.SpineController:AddColor(nil, unity_color({ 0.5, 0.7, 0.7, 0.5 }), 1, 0)
		corpse_2.SpineController:AddColor(nil, unity_color({ 0.5, 0.7, 0.7, 0.5 }), 1, 0)
		corpse_3.SpineController:AddColor(nil, unity_color({ 0.5, 0.7, 0.7, 0.5 }), 1, 0)

		command_util.execute_holdup(researcher_4, corpse_1, researcher_4.Position, 0.12, true)
		command_util.execute_holdup(researcher_5, corpse_2, researcher_5.Position, 0.12, true)
		command_util.execute_holdup(researcher_6, corpse_3, researcher_6.Position, 0.12, true)
		wait_for_sec(0.75 + 0.12)

		self.is_ignore_fo_spine_offset_reset_list[corpse_1] = true
		self.is_ignore_fo_spine_offset_reset_list[corpse_2] = true
		self.is_ignore_fo_spine_offset_reset_list[corpse_3] = true
		corpse_1.SpineController.IsShadowActive = false
		corpse_2.SpineController.IsShadowActive = false
		corpse_3.SpineController.IsShadowActive = false

		wait_all({
			util.cs_generator(character_util.move_waypoint_async, researcher_4, researcher_4.Position + vector(-1, 0, 0), 2, false, nil, nil, nil),
			util.cs_generator(character_util.move_waypoint_async, researcher_5, researcher_5.Position + vector(0, 0, -1), 2, false, nil, nil, nil),
			util.cs_generator(character_util.move_waypoint_async, researcher_6, researcher_6.Position + vector(0, 0, -1), 2, false, nil, nil, nil),
		})
		wait_for_sec(0.75)

		command_util.execute_throw(researcher_4, corpse_1, direction_util.to_vector3(researcher_4.Direction), researcher_4.Position, 4, true)
		command_util.execute_throw(researcher_5, corpse_2, direction_util.to_vector3(researcher_5.Direction), researcher_5.Position, 4, true)
		command_util.execute_throw(researcher_6, corpse_3, direction_util.to_vector3(researcher_6.Direction), researcher_6.Position, 4, true)
		coroutine.yield()

		message_system:SendSync(corpse_1, CS.Oak.GetThrownEndEvent.Instance)
		message_system:SendSync(corpse_2, CS.Oak.GetThrownEndEvent.Instance)
		message_system:SendSync(corpse_3, CS.Oak.GetThrownEndEvent.Instance)

		corpse_1.Holdable = CS.Oak.NonHoldable.Instance
		corpse_2.Holdable = CS.Oak.NonHoldable.Instance
		corpse_3.Holdable = CS.Oak.NonHoldable.Instance

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to, self, corpse_1, 0.5))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to, self, corpse_2, 0.5))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to, self, corpse_3, 0.5))
		character_util.move_to(corpse_1, researcher_4.Position + direction_util.to_vector3(researcher_4.Direction) + vector(0, 1, 0), 0.5, nil, false, false)
		character_util.move_to(corpse_2, researcher_5.Position + direction_util.to_vector3(researcher_5.Direction) + vector(0, 1, 0), 0.5, nil, false, false)
		character_util.move_to(corpse_3, researcher_6.Position + direction_util.to_vector3(researcher_6.Direction) + vector(0, 1, 0), 0.5, nil, false, false)
		wait_for_sec(0.75)
	end

	if self.is_stop_all_invader_action then
		character_util.set_anim(researcher_4, { name = 'unique/ice' })
		character_util.set_anim(researcher_5, { name = 'unique/ice' })
		character_util.set_anim(researcher_6, { name = 'unique/ice' })
	end
end
--endregion

--region ice_block
function local_class:init_ice_block_list()
	self.ice_block_list = {}
	self.is_ice_block_used_list = {}

	self:find_and_execute_fo_all(self.get_ice_block, function(ice_block)
		ice_block.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.75)
		ice_block.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		ice_block.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		field_ui_manager:RemoveUI(ice_block, CS.Oak.FieldUiType.CharacterStats)

		table.insert(self.ice_block_list, ice_block)
		table.insert(self.is_ice_block_used_list, false)
	end)
end

function local_class:get_ice_block_from_pool()
	local ice_block = nil

	for i = 1, #self.ice_block_list do
		if not self.is_ice_block_used_list[i] then
			self.is_ice_block_used_list[i] = true
			ice_block = self.ice_block_list[i]
			character_util.set_active_state(ice_block, 'enabled')
			break
		end
	end

	return ice_block
end

function local_class:release_ice_block(ice_block)
	for i = 1, #self.ice_block_list do
		if lua_helper.reference_equals(ice_block, self.ice_block_list[i]) then
			self.is_ice_block_used_list[i] = false
			ice_block.Position = vector(999, 0, 999)
			character_util.set_active_state(ice_block, 'disabled')
			break
		end
	end
end

function local_class:release_all_ice_block()
	for i = 1, #self.ice_block_list do
		self.is_ice_block_used_list[i] = false
		self.ice_block_list[i].Position = vector(999, 0, 999)
		character_util.set_active_state(self.ice_block_list[i], 'disabled')
	end
end
--endregion

--region ice_block_moving
function local_class:ice_block_moving()
	local coco_quest_progress = user_progress:GetStartedQuest(196)
	local is_coco_alive = coco_quest_progress.IsComplete and coco_quest_progress.Grade == 1

	if not is_coco_alive then
		wait_for_sec(7)
	end

	if not is_coco_alive then
		while true do
			local ice_block = self:get_ice_block_from_pool()
			while not ice_block do
				ice_block = self:get_ice_block_from_pool()
				coroutine.yield()
			end

			ice_block.Position = vector(3, 1, -8)

			wait_for_sec(10)
		end
	end

	local mover_1 = self.get_invader_ice_block_mover(1)
	local mover_2 = self.get_invader_ice_block_mover(2)
	character_util.set_anim(mover_1, { name = 'unique/ice' })
	character_util.set_anim(mover_2, { name = 'unique/ice' })
end

function local_class:check_ice_block(ice_block)
	local mover_1 = self.get_invader_ice_block_mover(1)
	local mover_2 = self.get_invader_ice_block_mover(2)

	self:add_ignore_conveyor_belt_moving(ice_block)
	command_util.execute_holdup(mover_1, ice_block, mover_1.Position, 0.12, true)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to_minus, self, ice_block, 0.12, false))
	wait_for_sec(0.75 + 0.12)

	character_util.set_direction(mover_1, 'right')
	wait_for_sec(0.75)

	ice_block.Holdable = CS.Oak.Holdable()
	command_util.execute_throw(mover_1, ice_block, direction_util.to_vector3(mover_1.Direction), mover_1.Position, 4, true)

	message_system:SendSync(ice_block, CS.Oak.GetThrownEndEvent.Instance)
	coroutine.yield()
	ice_block.Holdable = CS.Oak.NonHoldable.Instance

	character_util.set_direction(mover_2, 'left')
	character_util.move_to(ice_block, mover_1.Position + direction_util.to_vector3(mover_1.Direction), 0.5, nil, false, false)
	wait_for_sec(0.5)
	if self.leader_in_grid_name == 'start_grid' then
		music_player_util.play_sfx( { sfx_name = '01_interact_plitvice_01',
									  type_priority = 'default', player_priority = 'npc', play_pos = ice_block.Position })
	end
	wait_for_sec(0.25)

	self.is_ignore_fo_spine_offset_reset_list[ice_block] = false
	character_util.set_direction(mover_1, 'left')

	-- 이거 좋네. 통과.
	-- 이건 못 쓰겠네. 폐기.
	local key_index = random_util.get_random_int(1, 2)
	if self.leader_in_grid_name == 'start_grid' then
		music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01',
									 type_priority = 'default', player_priority = 'npc', play_pos = mover_2.Position })
	end
	speech_bubble_util.show_speech_bubble(mover_2, { key = 'futurecastle_coco_check_ice_block_' .. key_index })

	ice_block.Holdable = CS.Oak.Holdable()
	command_util.execute_holdup(mover_2, ice_block, mover_2.Position, 0.12, true)
	wait_for_sec(0.75 + 0.12)

	if key_index == 1 then
		character_util.set_direction(mover_2, 'right')
		wait_for_sec(0.75)

		command_util.execute_throw(mover_2, ice_block, direction_util.to_vector3(mover_2.Direction), mover_2.Position, 4, true)

		message_system:SendSync(ice_block, CS.Oak.GetThrownEndEvent.Instance)
		coroutine.yield()
		ice_block.Holdable = CS.Oak.NonHoldable.Instance

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to, self, ice_block, 0.5))
		character_util.move_to(ice_block, mover_2.Position + direction_util.to_vector3(mover_2.Direction) + vector(0, 1, 0), 0.5, nil, false, false)
		wait_for_sec(0.5)
		self:remove_ignore_conveyor_belt_moving(ice_block)

		wait_for_sec(0.25)
	else
		character_util.move_waypoint_async(mover_2, { mover_2.Position + vector(0, 0, 1), mover_2.Position + vector(-2, 0, 1) }, 4, false, nil, nil, 'left')
		wait_for_sec(0.75)

		command_util.execute_throw(mover_2, ice_block, direction_util.to_vector3(mover_2.Direction), mover_2.Position, 4, true)

		message_system:SendSync(ice_block, CS.Oak.GetThrownEndEvent.Instance)
		coroutine.yield()
		ice_block.Holdable = CS.Oak.NonHoldable.Instance

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spine_offset_move_to, self, ice_block, 0.5))
		character_util.move_to(ice_block, mover_2.Position + direction_util.to_vector3(mover_2.Direction) + vector(0, 1, 0), 0.5, nil, false, false)
		wait_for_sec(0.5)
		self:remove_ignore_conveyor_belt_moving(ice_block)

		character_util.move_waypoint_async(mover_2, { mover_2.Position + vector(2, 0, 0), mover_2.Position + vector(2, 0, -1) }, 4, false, nil, nil, 'right')
	end
end
--endregion

--region capsule
function local_class:init_capsule_list()
	self.capsule_list = {}
	self.is_capsule_used_list = {}

	for i = 1, 10 do
		local capsule = CS.Oak.VirtualFieldObject()
		capsule.ActiveState = active_state('disabled')
		capsule.Name = 'capsule_' .. i
		capsule.Position = vector(999, 0, 999)
		capsule.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.75)
		capsule.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		message_system:Send(capsule, CS.Oak.AddFieldObjectEvent.Create(capsule))

		table.insert(self.capsule_list, capsule)
		table.insert(self.is_capsule_used_list, false)
	end
end

function local_class:get_capsule_from_pool()
	local capsule = nil

	for i = 1, #self.capsule_list do
		if not self.is_capsule_used_list[i] then
			self.is_capsule_used_list[i] = true
			capsule = self.capsule_list[i]
			self.capsule_item_list[i].SpriteTransform.localScale = unity_class.vector3.one
			character_util.set_active_state(capsule, 'enabled')
			break
		end
	end

	return capsule
end

function local_class:release_capsule(capsule)
	for i = 1, #self.capsule_list do
		if lua_helper.reference_equals(capsule, self.capsule_list[i]) then
			self.is_capsule_used_list[i] = false
			capsule.Position = vector(999, 0, 999)
			character_util.set_active_state(capsule, 'disabled')
			break
		end
	end
end

function local_class:attach_capsule_item()
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.capsule_item_spec_name).Id

	self.capsule_item_list = {}

	for i = 1, #self.capsule_list do
		local capsule_item = drop_item_util.create_item({ itemid = item_id, notforinven = true, lootstate = 'dontfindlooter', pos = vector(999, 0, 999) })
		table.insert(self.capsule_item_list, capsule_item)
	end

	while true do
		for i = 1, #self.capsule_list do
			local capsule = self.capsule_list[i]

			if capsule.ActiveState == active_state('enabled') then
				self.capsule_item_list[i].Position = capsule.Position
			else
				self.capsule_item_list[i].Position = vector(999, 0, 999)
			end
		end

		coroutine.yield()
	end
end
--endregion

--region corpse_to_capsule
function local_class:push_corpse_to_capsule_belt()
	local hole_marker = self.get_hole_marker(1)

	while true do
		local corpse = self:get_corpse_from_pool()
		while not corpse do
			corpse = self:get_corpse_from_pool()
			coroutine.yield()
		end

		corpse.Position = hole_marker.position + vector(0, 14, 0)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.freefall_character, self, corpse, 1, 1))
		wait_for_sec(1)

		wait_for_sec(5)
	end
end

function local_class:corpse_change_to_capsule(corpse)
	local capsule = self:get_capsule_from_pool()
	while not capsule do
		capsule = self:get_capsule_from_pool()
		coroutine.yield()
	end

	self:release_corpse(corpse)

	local start_marker = self.get_capsule_marker(1)
	local end_marker = self.get_capsule_marker(2)

	local glasstube = self.get_glasstube()

	if self.in_fire_trap_grid then
		music_player_util.play_sfx({ sfx_name = '01_fly_hit_01', parent = glasstube,
									 type_priority = 'default', player_priority = 'npc'})
		music_player_util.play_sfx({ sfx_name = '01_villain_scream_02', parent = glasstube,
									 type_priority = 'battle_attack', player_priority = 'npc'})

		speech_bubble_util.show_speech_bubble(glasstube, { key = 'futurecastle_coco_change_capsule_shout', bubble_type = 'shout', world_pos = glasstube.Position, type_speed = 0 })
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(function(cur_glasstube, cur_capsule, cur_start_marker, cur_end_marker)
		for i = 1, 3 do
			if self.in_fire_trap_grid then
				music_player_util.play_sfx({ sfx_name = '01_interact_greenland_01', parent = cur_glasstube,
											 type_priority = 'default', player_priority = 'npc'})
			end
			cur_glasstube:Shake(0.08, 0.2)
			if self.is_user_close_glasstube then
				camera_util.shake(0.1, 0.2)
			end
			wait_for_sec(0.6)
		end

		cur_capsule.Position = cur_start_marker.position

		if self.in_fire_trap_grid then
			music_player_util.play_sfx({ sfx_name = '01_fly_hit_01', play_pos = cur_capsule.Position,
										 type_priority = 'default', player_priority = 'npc' })
		end
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.move_to, self, cur_capsule, cur_end_marker.position, nil, 3, false, false, false))
	end, glasstube, capsule, start_marker, end_marker))
end

function local_class:capsule_into_magic_circle(capsule)
	-- 떨어지는 연출
	local free_fall = CS.CalculatorFreeFall(0, 2, 1, 0)
	local start_position = capsule.Position
	local end_position = capsule.Position + vector(1, 0, -0.5)

	local time_passed = 0
	local duration = CS.CalculatorFreeFall.CalculateDurationIncludingBounces(0, 2, 1, 0)

	local capsule_index = tonumber(string.sub(capsule.Name, 9, string.len(capsule.Name)))
	local capsule_item = self.capsule_item_list[capsule_index]

	if self.leader_in_grid_name == 'box_gird' then
		music_player_util.play_sfx({ sfx_name = '01_fly_hit_01', play_pos = capsule.Position,
									 type_priority = 'event', player_priority = 'npc'})
	end

	while time_passed < duration and not free_fall:IsDone() do
		time_passed = time_passed + unity_class.time.deltaTime
		free_fall:Proceed(unity_class.time.deltaTime)

		local y = free_fall:GetDistance()
		local progress = time_passed / duration

		capsule.Position = unity_class.vector3.Lerp(start_position, end_position, progress)
		capsule.Position = vector_util.get_x0z(capsule.Position, y)
		capsule_item.SpriteTransform.localScale = unity_class.vector3.one * CS.UnityEngine.Mathf.Clamp01(1.2 - progress)

		coroutine.yield()
	end

	capsule_item.SpriteTransform.localScale = unity_class.vector3.one * 0.2
	capsule.Position = vector_util.get_x0z(capsule.Position, 0)

	self:release_capsule(capsule)
end

function local_class:enter_capsule_drop_zone()
	local item_data = game_data_service.GetData('ItemData')
	local capsule_item_id = item_data:GetSpec(self.capsule_item_spec_name).Id

	self.is_saw_capsule_drop = true

	wait_for_sec(0.25)

	for i = 17, 20 do
		local capsule_item_marker = self.get_drop_capsule_item_marker(i)

		local drop_capsule_item = drop_item_util.create_item({ pos = vector_util.get_x0z(capsule_item_marker.position, 15), itemid = capsule_item_id, notforinven = true, lootstate = 'dontfindlooter' })
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.freefall_fo, self, drop_capsule_item, 1, 0))

		table.insert(self.drop_capsule_item_list, drop_capsule_item)
		wait_for_sec(1.8)
		wait_for_sec(2)
	end
end

function local_class:enter_box_drop_zone()
	self.is_saw_box_drop = true

	wait_for_sec(0.25)

	for i = 1, 4 do
		local box_marker = self.get_drop_box_marker(i)

		local drop_box = self.get_drop_box(i)
		drop_box.ActiveState = active_state('enabled')
		drop_box.Position = vector_util.get_x0z(box_marker.position, 15 + box_marker.position.y)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.freefall_fo, self, drop_box, 1, box_marker.position.y, false))

		wait_for_sec(1.8)
		wait_for_sec(2)
	end
end

-- 일정 시간 동안 자유낙하하는 오브젝트 연출
function local_class:freefall_fo(fo, fall_time, offset_y, is_item)
	local check_item = lua_helper.get_or_default(is_item, true)
	local curtime = unity_class.time.time
	local falltime = fall_time
	local curpos = fo.Position
	local freefall = CS.CalculatorFreeFall(falltime, curpos.y, 0);
	offset_y = lua_helper.get_or_default(offset_y, 0)
	local shadow = nil
	if not check_item then
		shadow = fo.Transform:Find('shadow')
	end

	while unity_class.time.time - curtime < falltime do
		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		local y = curpos.y + dist_y + offset_y
		if y < offset_y then
			y = offset_y
		end
		fo.Position = vector(curpos.x, y, curpos.z)
		if not check_item then
			shadow.transform.localPosition = vector(0, -y,0)
		end
		coroutine.yield(nil)
	end
	if not check_item then
		shadow.transform.localPosition = vector(0,0,0)
		if self.leader_in_grid_name == 'box_drop_grid' then
			music_player_util.play_sfx({ sfx_name = '01_gatcha_box_01', play_pos = fo.Position,
										 type_priority = 'battle_attack', player_priority = 'object' })
		end
	else
		if self.leader_in_grid_name == 'box_grid' then
			music_player_util.play_sfx({ sfx_name = '02_hit_projectile_01', play_pos = fo.Position,
										 type_priority = 'battle_attack', player_priority = 'object' })
		end
	end
	fo.Position = vector(curpos.x, offset_y, curpos.z)
end
--endregion

--region box
function local_class:init_box_list()
	self.box_list = {}
	self.is_box_used_list = {}

	self:find_and_execute_fo_all(self.get_box, function(box)
		box.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1) * 0.75)
		box.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

		table.insert(self.box_list, box)
		table.insert(self.is_box_used_list, false)
	end)
end

function local_class:get_box_from_pool()
	local box = nil

	for i = 1, #self.box_list do
		if not self.is_box_used_list[i] then
			self.is_box_used_list[i] = true
			box = self.box_list[i]
			box.ActiveState = active_state('enabled')
			box.Transform.localScale = unity_class.vector3.one
			character_util.set_active_state(box, 'enabled')
			break
		end
	end

	return box
end

function local_class:release_box(box)
	for i = 1, #self.box_list do
		if lua_helper.reference_equals(box, self.box_list[i]) then
			self.is_box_used_list[i] = false
			box.Position = vector(999, 0, 999)
			box.ActiveState = active_state('disabled')
			break
		end
	end
end
--endregion

--region pack_to_box
function local_class:capsule_moving()
	local box_invader_1 = self.get_box_invader(1)
	local box_invader_2 = self.get_box_invader(2)

	local is_run_capsule_moving = function() return self.is_run_capsule_moving and not self.is_stop_all_invader_action end
	local is_detected = function()
		while self.is_detected do
			coroutine.yield()
		end
	end

	while is_run_capsule_moving() do
		character_util.remove_anim(box_invader_1)
		character_util.remove_anim(box_invader_2)
		wait_all({
			util.cs_generator(self.move_to, self, box_invader_1, box_invader_1.Position + vector(0, 0, 0.5), nil, 2, true, true, false),
			util.cs_generator(self.move_to, self, box_invader_2, box_invader_2.Position + vector(0, 0, 0.5), nil, 2, true, true, false),
		})
		if not is_run_capsule_moving() then break end
		is_detected()

		if self.leader_in_grid_name == 'box_grid' then
			music_player_util.play_sfx({ sfx_name = '01_throw_01'
			, loop = false, parent = box_invader_1, type_priority = 'default', player_priority = 'npc'})
		end
		character_util.set_animation_n_times(box_invader_1, { name = 'attack' })
		character_util.set_animation_n_times(box_invader_2, { name = 'attack' })
		wait_for_sec(0.35)
		if not is_run_capsule_moving() then break end
		is_detected()

		local capsule_1 = self:get_capsule_from_pool()
		while not capsule_1 do
			corpse_1 = self:get_capsule_from_pool()
			coroutine.yield()
		end
		local capsule_2 = self:get_capsule_from_pool()
		while not capsule_2 do
			capsule_2 = self:get_capsule_from_pool()
			coroutine.yield()
		end
		if not is_run_capsule_moving() then break end
		is_detected()

		local end_marker = self.get_box_marker(3)

		table.insert(self.pass_capsule_list, capsule_1)
		table.insert(self.pass_capsule_list, capsule_2)
		capsule_2.Position = box_invader_1.Position + direction_util.to_vector3(box_invader_1.Direction) + vector(-0.1, 1, 0)
		capsule_1.Position = box_invader_2.Position + direction_util.to_vector3(box_invader_2.Direction) + vector(-0.1, 1, 0)
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, capsule_1, end_marker.position, nil, 3, false, false, false))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, capsule_2, end_marker.position, nil, 3, false, false, false))
		wait_for_sec(0.4)
		if not is_run_capsule_moving() then break end
		is_detected()

		character_util.set_locked_dir(box_invader_1, 'up')
		character_util.set_locked_dir(box_invader_2, 'up')
		wait_all({
			util.cs_generator(self.move_to, self, box_invader_1, box_invader_1.Position + vector(0, 0, -0.5), nil, 2, false, true, false),
			util.cs_generator(self.move_to, self, box_invader_2, box_invader_2.Position + vector(0, 0, -0.5), nil, 2, false, true, false),
		})
		if not is_run_capsule_moving() then break end
		is_detected()

		local equipping_sfx = nil
		if self.leader_in_grid_name == 'box_grid' then
			equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01'
			, loop = true, parent = box_invader_1, type_priority = 'loop', player_priority = 'npc'})
		end
		character_util.set_locked_dir(box_invader_1, 'none')
		character_util.set_locked_dir(box_invader_2, 'none')
		character_util.set_direction(box_invader_1, 'right')
		character_util.set_direction(box_invader_2, 'right')
		character_util.set_anim(box_invader_1, { name = 'eat' })
		character_util.set_anim(box_invader_2, { name = 'eat' })
		wait_for_sec(3)
		if equipping_sfx ~= nil then
			equipping_sfx:Stop()
		end

		if not is_run_capsule_moving() then break end
		is_detected()
	end

	if self.is_stop_all_invader_action then
		character_util.set_anim(box_invader_1, { name = 'unique/ice' })
		character_util.set_anim(box_invader_2, { name = 'unique/ice' })
	end
end

function local_class:capsule_change_to_box(capsule_1, capsule_2)
	local box_invader_3 = self.get_box_invader(3)
	local box_invader_4 = self.get_box_invader(4)

	local is_run_capsule_change_to_box = function() return self.is_run_capsule_change_to_box end

	character_util.set_locked_dir(box_invader_3, 'up')
	character_util.set_locked_dir(box_invader_4, 'up')

	wait_all({
		util.cs_generator(self.move_to, self, box_invader_3, box_invader_3.Position + vector(0, 0, 0.5), nil, 2, false, true, false),
		util.cs_generator(self.move_to, self, box_invader_4, box_invader_4.Position + vector(0, 0, 0.5), nil, 2, false, true, false),
	})
	if not is_run_capsule_change_to_box() then return end

	local box_1 = self:get_box_from_pool()
	local box_2 = self:get_box_from_pool()

	if self.leader_in_grid_name == 'box_grid' then
		music_player_util.play_sfx({ sfx_name = '02_wolf_boss_bomb_01', loop = false,
									 play_pos = capsule_1.Position, type_priority = 'battle_attack', player_priority = 'object' })
	end

	self.get_dead_effect():Instantiate(capsule_1.Position)
	self.get_dead_effect():Instantiate(capsule_2.Position)
	if box_1 ~= nil then
		box_1.Position = capsule_1.Position
	end
	if box_2 ~= nil then
		box_2.Position = capsule_2.Position
	end

	self.is_moving[capsule_1] = false
	self.is_moving[capsule_2] = false
	coroutine.yield()
	if not is_run_capsule_change_to_box() then return end

	self:release_capsule(capsule_1)
	self:release_capsule(capsule_2)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, box_invader_3, box_invader_3.Position + vector(0, 0, -0.5), nil, 2, false, true, false))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, box_invader_4, box_invader_4.Position + vector(0, 0, -0.5), nil, 2, false, true, false))
	if not is_run_capsule_change_to_box() then return end

	local end_marker = self.get_box_marker(3)
	if box_1 ~= nil then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, box_1, end_marker.position, nil, 3, false, false, false))
	end
	if box_2 ~= nil then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to, self, box_2, end_marker.position, nil, 3, false, false, false))
	end

	if self.is_stop_all_invader_action then
		character_util.set_anim(box_invader_3, { name = 'unique/ice' })
		character_util.set_anim(box_invader_4, { name = 'unique/ice' })
	end
end

function local_class:box_into_magic_circle(box)
	-- 떨어지는 연출
	local free_fall = CS.CalculatorFreeFall(0, 2, 1, 0)
	local start_position = box.Position
	local end_position = box.Position + vector(1, 0, 0)

	local time_passed = 0
	local duration = CS.CalculatorFreeFall.CalculateDurationIncludingBounces(0, 2, 1, 0)

	if self.leader_in_grid_name == 'box_grid' then
	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', play_pos = box.Position,
								 type_priority = 'event', player_priority = 'npc'})
	end

	while time_passed < duration and not free_fall:IsDone() do
		time_passed = time_passed + unity_class.time.deltaTime
		free_fall:Proceed(unity_class.time.deltaTime)

		local y = free_fall:GetDistance()
		local progress = time_passed / duration

		box.Position = unity_class.vector3.Lerp(start_position, end_position, progress)
		box.Position = vector_util.get_x0z(box.Position, y)
		box.Transform.localScale = unity_class.vector3.one * CS.UnityEngine.Mathf.Clamp01(1.2 - progress)

		coroutine.yield()
	end

	box.Transform.localScale = unity_class.vector3.one * 0.2
	box.Position = vector_util.get_x0z(box.Position, 0)

	self:release_box(box)
end

function local_class:battle_start_box_group_1()
	-- 무기가 없으면, 전투에 들어가지 않음
	if user_party.Leader.Weapon1 == nil then
		return
	end

	self.is_battle_box_group_1 = true

	-- 캡슐 나르기 종료
	self.is_run_capsule_moving = false

	local box_invader_1 = self.get_box_invader(1)
	local box_invader_2 = self.get_box_invader(2)

	-- 이동중이였다면, 이동도 종료
	self.is_moving[box_invader_1] = false
	self.is_moving[box_invader_2] = false

	character_util.remove_anim_and_emotion(box_invader_1)
	character_util.remove_anim_and_emotion(box_invader_2)

	-- 몬스터 화
	character_util.convert_to_monster(box_invader_1, self.box_battle_group_name .. 1)
	character_util.convert_to_monster(box_invader_2, self.box_battle_group_name .. 1)

	command_util.execute_monster_notice(box_invader_1, user_party.Leader, 'battle')
	command_util.execute_monster_notice(box_invader_2, user_party.Leader, 'battle')

	-- TODO: 배틀 게이트 닫기
end

function local_class:battle_start_box_group_2()
	-- 무기가 없으면, 전투에 들어가지 않음
	if user_party.Leader.Weapon1 == nil then
		return
	end

	self.is_battle_box_group_2 = true

	-- 캡슐 포장 종료
	self.is_run_capsule_change_to_box = false

	local box_invader_3 = self.get_box_invader(3)
	local box_invader_4 = self.get_box_invader(4)

	-- 이동중이였다면, 이동도 종료
	self.is_moving[box_invader_3] = false
	self.is_moving[box_invader_4] = false

	character_util.remove_anim_and_emotion(box_invader_3)
	character_util.remove_anim_and_emotion(box_invader_4)
	character_util.set_locked_dir(box_invader_3, 'none')
	character_util.set_locked_dir(box_invader_4, 'none')

	-- 몬스터 화
	character_util.convert_to_monster(box_invader_3, self.box_battle_group_name .. 1)
	character_util.convert_to_monster(box_invader_4, self.box_battle_group_name .. 1)

	command_util.execute_monster_notice(box_invader_3, user_party.Leader, 'battle')
	command_util.execute_monster_notice(box_invader_4, user_party.Leader, 'battle')

	-- TODO: 배틀 게이트 닫기
end
--endregion

--region rest_room_guard
function local_class:add_rest_room_guard_detect()
	for i = 9, 12 do
		local invader = self.get_invader_guard(i)
		self:add_guard_detect_range(invader, 4, 60, 'invader_rest_room_guard')
	end

	for i = 1, 4 do
		local cur_box_invader = self.get_box_invader(i)
		self:add_guard_detect_range(cur_box_invader, 4, 60, 'invader_rest_room_guard')
	end
end
--endregion

--region keycard
function local_class:drop_keycard()
	local invader = self.get_invader_keycard_researcher(1)

	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.keycard_item_spec_name).Id
	local keycard = drop_item_util.create_item({ pos = invader.Position, target = vector(111, 0, 55), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' })

	keycard.ConsumeTarget = user_party.Leader
end

function local_class:interact_keycard_door(keycard_door_list)
	if self.is_get_keycard then
		local align_position = unity_class.vector3.zero

		for i = 1, #keycard_door_list do
			local keycard_door = keycard_door_list[i]
			align_position = align_position + keycard_door.Position
		end
		align_position = align_position / #keycard_door_list

		party_util.align_party(align_position, 'down', 1, 'arc')

		-- 인증이 필요합니다.
		field_ui_util.show_narration_async({ key = 'futurecastle_coco_need_keycard' })

		-- 카드키를 갖다 댄다.
		choose_util.play_choose_event({ { 'futurecastle_coco_touch_keycard', 'normal' } })

		character_util.set_animation_n_times(user_party.Leader, { name = 'dualgun_attack_right' })
		wait_for_sec(0.5)

		-- obstacle 애니메이션
		for i = 1, #keycard_door_list - 1 do
			local keycard_door = keycard_door_list[i]
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.open_obstacle_door, self, keycard_door))
		end
		yield_return_func(self.open_obstacle_door, self, keycard_door_list[#keycard_door_list])

		for i = 1, #keycard_door_list do
			local keycard_door = keycard_door_list[i]
			keycard_door.Interactable = CS.Oak.NonInteractable.Instance
		end
	else
		-- 인증이 필요합니다.
		field_ui_util.show_narration_async({ key = 'futurecastle_coco_need_keycard' })
	end
end

function local_class:get_keycard_item()
	local item_data = CS.Oak.GameDataService.GetData('ItemData')
	local keycard_item_id = item_data:GetSpec(self.keycard_item_spec_name).Id

	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent, { ItemId = keycard_item_id }, 'futurecastle_coco_invader_card_key_title', 'futurecastle_coco_invader_card_key_subtitle', 'futurecastle_coco_invader_card_key_desc')

	self.is_get_keycard = true

	stage_progress_util.set_custom_data_async(self.custom_key.is_get_keycard, self.is_get_keycard)
	coroutine.yield()
end

-- door 열리는 루틴
function local_class:open_obstacle_door(door)
	music_player_util.play_sfx({ sfx_name = '01_interact_tower_02' })
	self:obstacle_color_a_to_b(door, unity_color({ 0.5, 0, 0, 0.5 }), unity_color({ 0, 0.5, 0, 0.5 }), 1)

	wait_for_sec(0.8)
	door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
end

function local_class:obstacle_color_a_to_b(fo, a, b, duration)
	local mesh = CS.Utils.FindChildRecursively(fo.Transform, '[GIMMICK]obstacle_ray')
	local renderer = mesh:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
	local material = renderer.material

	local time_passed = 0

	while time_passed < duration do
		local progress = (time_passed / duration)
		local color = CS.UnityEngine.Color.Lerp(a, b, progress);

		material:SetColor("_TintColor", color)

		coroutine.yield()

		time_passed = time_passed + unity_class.time.deltaTime
	end

	material:SetColor("_TintColor", b)
end

function local_class:set_obstacle_color(fo, color)
	local mesh = CS.Utils.FindChildRecursively(fo.Transform, '[GIMMICK]obstacle_ray')
	local renderer = mesh:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
	local material = renderer.material

	material:SetColor("_TintColor", color)
end
--endregion

--region console
function local_class:interact_console()
	local console = self.get_console()

	if not self.is_get_keycard_red then
		field_ui_manager:Hide()
		party_util.stop_and_disable_control()

		party_util.align_to_target(console.Position + vector(0.5, 0, 0), 'down', 1)

		-- 궤도 엘리베이터 사용자 ID 등록

		music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
		speech_bubble_util.show_speech_bubble_async(console, { key = 'futurecastle_coco_console_1', skip = true })

		speech_bubble_util.show_speech_bubble_async(console, { key = 'futurecastle_coco_console_2', skip = true })

		-- 등록한다 / 돌아간다
		local choose_result = choose_util.play_choose_event({ { 'futurecastle_coco_console_3', 'mercy' }, { 'futurecastle_coco_console_4', 'brutal' } })
		if choose_result == 1 then
			music_player_util.play_sfx_one_shot('01_tower_clear_button_01')
			wait_for_sec(1)

			-- 등록이 완료 되었습니다.
			music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
			speech_bubble_util.show_speech_bubble_async(console, { key = 'futurecastle_coco_console_5', skip = true })

			-- 레드 카드키 획득
			local item_data = game_data_service.GetData('ItemData')
			local item_id = item_data:GetSpec(self.keycard_red_item_spec_name).Id
			local keycard = drop_item_util.create_item({ pos = console.Position + vector(0.5, 0, 0), target = user_party.Leader.Position, itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' })

			music_player_util.play_sfx_one_shot('01_throw_01')
			keycard.ConsumeTarget = user_party.Leader
			wait_for_sec(1.5)

			yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent, { ItemId = item_id }, 'futurecastle_coco_invader_card_key_red_title', 'futurecastle_coco_invader_card_key_red_subtitle', 'futurecastle_coco_invader_card_key_red_desc')

			self.is_get_keycard_red = true
			
			stage_progress_util.set_custom_data_async(self.custom_key.is_get_keycard_red, self.is_get_keycard_red)
			coroutine.yield()
		end

		party_util.reset_controllers()
		field_ui_manager:Show()
	else
		if self.console_sfx ~= nil then
			self.console_sfx:Stop()
			self.console_sfx = nil
		end

		self.console_sfx = music_player_util.play_sfx({ sfx_name = '03_dialogue_worker_01', type_priority = 'event', player_priority = 'object' })

		-- 등록이 완료 되었습니다.
		speech_bubble_util.show_speech_bubble(console, { key = 'futurecastle_coco_console_5', skip = true })
	end
end
--endregion

--region invader_specimen_talk
function local_class:invader_specimen_talk_1()
	local invader_1 = self.get_invader_specimen(1)

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble(invader_1, { key = 'futurecastle_coco_invader_specimen_1' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local invader_specimen_door = self.get_invader_specimen_door()
		for i = 1, 5 do
			music_player_util.play_sfx({ sfx_name = '01_hit_dummy_02', parent = invader_specimen_door, type_priority = 'event', player_priority = 'object' })
			invader_specimen_door:Shake(0.04, 0.1)
			wait_for_sec(0.2)
		end
	end))
end

function local_class:invader_specimen_talk_2()
	local invader_3 = self.get_invader_specimen(3)

	speech_bubble_util.show_speech_bubble(invader_3, { key = 'futurecastle_coco_invader_specimen_2' })
end

function local_class:invader_specimen_talk_3()
	local invader_4 = self.get_invader_specimen(4)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble(invader_4, { key = 'futurecastle_coco_invader_specimen_3' })
end
--endregion

--region stop_all_invader_action
function local_class:stop_all_invader_action()
	self.is_stop_all_invader_action = true

	-- 박스 인베이더
	for i = 1, 4 do
		local invader = self.get_box_invader(i)
		self:remove_guard_detect_range(invader)

		if i >= 3 then
			character_util.set_anim(invader, { name = 'unique/ice' })
		end
	end

	-- 휴게실 인베이더
	for i = 9, 12 do
		local invader = self.get_invader_guard(i)
		self:remove_guard_detect_range(invader)
		character_util.set_anim(invader, { name = 'unique/ice' })
	end

	-- 잠자는 인베이더
	local sleep_invader = self.get_sleep_invader(i)
	character_util.set_anim(sleep_invader, { name = 'unique/ice' })

	-- 시체 인베이더
	for i = 4, 6 do
		local invader = self.get_researcher(i)
		self:remove_guard_detect_range(invader)
	end

	-- 경비 인베이더
	for i = 1, 8 do
		local invader = self.get_invader_guard(i)
		character_util.stop(invader)
		character_util.set_anim(invader, { name = 'unique/ice' })
	end

	-- 시체 인베이더 2
	local invader = self.get_researcher(7)
	character_util.stop(invader)
	character_util.set_anim(invader, { name = 'unique/ice' })

	-- 얼음상 인베이더는 따로 스테이지 진입시에 ice_block_moving 체크해서 얼려줌

	local corpse_guard_hole = self.get_corpse_guard_hole()
	corpse_guard_hole.Interactable = self.corpse_guard_hole_interactable
end
--endregion

--region qte
-- QTE 함수
function local_class:qte_swipe(type, duration)
	duration = lua_helper.get_or_default(duration, 9999)

	CS.Oak.CommonScreenplay.QTESwipe(type)

	self.swipe_type = ''
	self.is_qte_start = true
	local time_passed = 0

	while self.is_qte_start and self.swipe_type ~= type and time_passed < duration do
		coroutine.yield()

		time_passed = time_passed + unity_class.time.deltaTime
	end

	self.is_qte_start = false
	CS.Oak.CommonScreenplay.CloseTutorialSpine()
end
--endregion

--region util
function local_class:string_to_direction(direction_str)
	if type_util.is_string(direction_str) then
		if direction_str == 'left' then
			return CS.Oak.Direction.Left
		elseif direction_str == 'right' then
			return CS.Oak.Direction.Right
		elseif direction_str == 'up' then
			return CS.Oak.Direction.Up
		elseif direction_str == 'down' then
			return CS.Oak.Direction.Down
		elseif direction_str == 'none' then
			return CS.Oak.Direction.None
		end
	end

	return nil
end

function local_class:is_character(fo)
	local type = fo:GetType()
	local result = false

	cast(fo, typeof(CS.Oak.Character))

	if lua_helper.type_compare(fo, typeof(CS.Oak.Character)) then
		result = true
	end

	cast(fo, type)

	return result
end

function local_class:move_to(fo, position, duration, speed, auto_direction, auto_animation, play_sfx)
	local time_passed = 0
	local start_pos = fo.Position

	local final_duration = 1
	if duration ~= nil then
		final_duration = duration
	elseif speed ~= nil then
		final_duration = (position - start_pos).magnitude / speed
	end

	if auto_direction ~= nil and auto_direction then
		local dir = (position - fo.Position):ToDirection()
		if dir ~= CS.Oak.Direction.None then
			fo.Direction = dir
		end
	end

	if auto_animation ~= nil and auto_animation and lua_helper.type_compare(fo, CS.Oak.Character) then
		character_util.set_anim(fo, { name = 'walk' })
	end

	local dash_sfx = nil

	if play_sfx ~= nil and play_sfx then
		dash_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = fo, loop = true, max_distance = 10, type_priority = 'loop', player_priority = 'npc' })
	end

	self.is_moving[fo] = true
	while self.is_moving[fo] and not self.is_leaving_stage do
		time_passed = time_passed + unity_class.time.deltaTime
		if time_passed >= final_duration then
			break
		end

		fo.Position = unity_class.vector3.Lerp(start_pos, position, time_passed / final_duration)
		coroutine.yield()
	end

	if self.is_moving[fo] then
		fo.Position = position
	end
	self.is_moving[fo] = false

	if dash_sfx ~= nil then
		dash_sfx:FadeOut(0.2)
	end

	if auto_animation ~= nil and auto_animation and lua_helper.type_compare(fo, CS.Oak.Character) then
		character_util.remove_anim(fo)
	end
end

function local_class:spine_offset_move_to(fo, duration, is_ignore_release)
	is_ignore_release = lua_helper.get_or_default(is_ignore_release, true)

	self.is_ignore_fo_spine_offset_reset_list[fo] = true

	local time_passed = 0
	local spine_offset = fo.SpineController.SpineOffset

	while time_passed < duration and not self.is_leaving_stage do
		time_passed = time_passed + unity_class.time.deltaTime

		local progress = time_passed / duration
		fo.SpineController.SpineOffset = spine_offset + (self.spine_offset * progress)

		coroutine.yield()
	end

	fo.SpineController.SpineOffset = spine_offset + self.spine_offset

	if is_ignore_release then
		self.is_ignore_fo_spine_offset_reset_list[fo] = false
	end
end

function local_class:spine_offset_move_to_minus(fo, duration, is_ignore_release)
	is_ignore_release = lua_helper.get_or_default(is_ignore_release, true)

	self.is_ignore_fo_spine_offset_reset_list[fo] = true

	local time_passed = 0
	local spine_offset = fo.SpineController.SpineOffset

	while time_passed < duration and not self.is_leaving_stage do
		time_passed = time_passed + unity_class.time.deltaTime

		local progress = time_passed / duration
		fo.SpineController.SpineOffset = spine_offset - (self.spine_offset * progress)

		coroutine.yield()
	end

	fo.SpineController.SpineOffset = spine_offset - self.spine_offset

	if is_ignore_release then
		self.is_ignore_fo_spine_offset_reset_list[fo] = false
	end
end

function local_class:find_and_execute_fo_all(find_fo_func, execute_func)
	local i = 1
	while true do
		local fo = find_fo_func(i)

		if fo == nil then
			break
		end

		execute_func(fo)

		i = i + 1
	end
end
--endregion

function local_class:play_cave_music(option)
	if option then
		self.aircraft_loop:FadeOut(1)
		music_player_util.play_stage_music({name = 'bgm_cave_main', state = 'field', mix = 2})
		wait_for_sec(2)
		music_player_util.set_stage_music_clip_async({ state = 'field', name = 'bgm_cave_main' })
	else
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })
		self.aircraft_loop = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01',  fade_in_time = 2,
														  loop = true, type_priority = 'loop', player_priority = 'npc' })
		wait_for_sec(2)
		music_player_util.remove_stage_music_clip({ state = 'field' })
	end
end

function local_class:play_magic_circle_music(option)
	if option then
		if self.aircraft_loop ~= nil then
			self.aircraft_loop:FadeOut(2)
			self.aircraft_loop = nil
		end

		self.magic_circle_active_loop = music_player_util.play_sfx({ sfx_name = '01_magic_circle_active_01',  fade_in_time = 2,
																	 loop = true, type_priority = 'loop', player_priority = 'npc' })
	else
		if self.magic_circle_active_loop ~= nil then
			self.magic_circle_active_loop:FadeOut(2)
			self.magic_circle_active_loop = nil
		end

		self.aircraft_loop = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01',  fade_in_time = 2,
														  loop = true, type_priority = 'loop', player_priority = 'npc' })
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
