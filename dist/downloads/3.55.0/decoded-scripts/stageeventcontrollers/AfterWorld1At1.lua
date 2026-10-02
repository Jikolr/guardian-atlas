local local_class = newclass("AfterWorld1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region MiniGame
	-- 심판의 방 미니게임
	self.judgement_minigame = nil
	self.judgement_minigame_name = 'JudgementMiniGame'
--endregion

--region Company Simple Event
	-- 플래그
	self.company_simple_event_flags = { false, false, false, false, false }
	self.company_simple_event_index = {
		new_employee = 1,
		yuna_news = 2,
		worry_branch = 3,
		angry_guide = 4,
		invader = 5
	}

	-- NPC 이름
	self.new_employee_leader_name = 'new_employee_leader'
	self.new_employee_num = 6
	self.new_employee_name = 'new_employee_reaper_'

	self.yuna_news_reaper_num = 8
	self.yuna_news_reaper_name = 'yuna_news_reaper_'

	self.worry_branch_reaper_num = 6
	self.worry_branch_reaper_name = 'worry_branch_reaper_'

	self.angry_guide_num = 8
	self.angry_guide_name = 'angry_guide_'

	self.invader_reaper_num = 5
	self.invader_reaper_name = 'invader_reaper_'

	self.hotel_sleeper_name = 'hotel_sleeper'

	-- 필드 오브젝트
	self.exit_corp = nil
	self.exit_corp_name = 'exit_corp_outer'
	self.exit_corp_marker_name = 'enter_corp'

	self.exit_hotel = nil
	self.exit_hotel_name = 'hotel_entrance_1'
	self.exit_hotel_marker_name = 'entry_hotel_1'

	self.judgement_gate = nil
	self.judgement_gate_name = 'judgement_gate'

	self.main_gate_name = 'afterworld_main_gate'

	self.book_info_num = 6
	self.book_info_name = 'book_info_'

	self.mouse_hole = 'hole_'

	self.hole_interact_1 = 'hole_interact_1'
	self.hole_interact_2 = 'hole_interact_2'

	self.rainbow_hot_spring_name = 'rainbow_hot_spring'

	self.duck_boat_num = 2
	self.duck_boat_name = 'duck_boat_gimmick_'

	-- SFX
	self.loop_sfx_zone_name = nil
	self.loop_sfx = nil

	-- Resource Holder
	self.res_holder = nil
	self.bg_corporation = nil
	self.bg_hotel = nil

	-- 이벤트 존 이름
	self.new_employee_event_zone_name = 'company_new_employee'
	self.yuna_news_event_zone_name = 'company_yuna_news'
	self.worry_branch_event_zone_name = 'company_worry_branch'
	self.angry_guide_event_zone_name = 'company_angry_guide'
	self.invader_event_zone_name = 'company_invader'

	self.corps_corridor_zone_name = 'corps_corridor'
	self.main_hall_zone_name = 'main_hall'
	self.ticket_sell_zone_name_1 = 'ticket_sell_1'
	self.ticket_sell_zone_name_2 = 'ticket_sell_2'
	self.changing_booth_zone_name = 'changing_booth'
	self.hotel_zone_name = 'hotel_1'

	self.hot_spring_zone_name = 'hot_spring'

	self.hotel_entrance_zone_name = 'section_5_hotel_entrance'
--endregion

--region Main Hall Simple Event
	-- 플래그
	self.main_hall_simple_event_flags = { false, false, false, false }
	self.main_hall_simple_event_index = {
		warning = 1,
		hot_spring_guide = 2,
		river_guide = 3,
		runaway = 4
	}

	-- NPC 이름
	self.warning_reaper_num = 2
	self.warning_reaper_name = 'warning_reaper_'
	self.warning_ghost_num = 6
	self.warning_ghost_name = 'warning_ghost_'

	self.hot_spring_guide_name = 'main_hall_hot_spring_guide'
	self.hot_spring_ghost_num = 2
	self.hot_spring_ghost_name = 'main_hall_hot_spring_ghost_'

	self.river_guide_name = 'main_hall_river_guide'
	self.river_ghost_num = 3
	self.river_ghost_name = 'main_hall_river_ghost_'

	self.reincarnation_ghost_num = 3
	self.reincarnation_ghost_name = 'main_hall_reincarnation_ghost_'

	self.runaway_ghost_name = 'main_hall_runaway_ghost'
	self.runaway_reaper_name = 'main_hall_runaway_reaper'

	self.oneline_ghost_num = 2
	self.oneline_ghost_name = 'main_hall_oneline_'

	-- 이벤트 존 이름
	self.warning_event_zone_name = 'main_hall_warning'
	self.hot_spring_guide_event_zone_name = 'main_hall_hot_spring_guide'
	self.river_guide_event_zone_name = 'main_hall_river_guide'
	self.runaway_event_zone_name = 'main_hall_runaway'

	-- 오브젝트 풀 프리셋
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
--endregion

--region Alley Simple Event
	-- 플래그
	self.see_massive_energy_event = false

	-- NPC 이름
	self.treasure_ghost_num = 3
	self.treasure_ghost_name = 'alley_treasure_ghost_'

	self.bad_guide_ghost_num = 3
	self.bad_guide_ghost_name = 'alley_bad_guide_ghost_'

	self.massive_energy_ghost_num = 8
	self.massive_energy_ghost_name = 'alley_massive_energy_ghost_'

	-- 이벤트 존 이름
	self.massive_energy_event_zone_name = 'alley_massive_energy'
--endregion

--region Hotel Entrance Event
	-- 플래그
	self.hotel_entrance_event_flags = { false, false }
	self.hotel_entrance_event_index = {
		envy = 1,
		greed = 2
	}

	-- NPC 이름
	self.hotel_greed_num = 4
	self.hotel_greed_name = 'hotel_greed_'

	self.hotel_rich_name = 'hotel_rich'

	self.hotel_envy_num = 8
	self.hotel_envy_name = 'hotel_envy_'

	self.hotel_rest_num = 4
	self.hotel_rest_name = 'hotel_rest_'

	-- 이벤트 존 이름
	self.hotel_entrance_greed_event_zone_name = 'hotel_entrance_greed'
	self.hotel_entrance_envy_event_zone_name = 'hotel_entrance_envy'
--endregion

--region Hotel Event
	-- 플래그
	self.see_walk_around_event = false
	self.enter_hotel = false

	-- NPC 이름
	self.hotel_walk_around_num = 4
	self.hotel_walk_around_name = 'hotel_walk_around_'

	self.hotel_inside_seat_num = 4
	self.hotel_inside_seat_name = 'hotel_inside_seat_'

	self.hotel_inside_inner_seat_num = 2
	self.hotel_inside_inner_seat_name = 'hotel_inside_inner_seat_'

	-- 이벤트 존 이름
	self.hotel_event_zone_name = 'hotel_1'
--endregion

--region Rainbow Hot Spring
	-- 필드오브젝트
	self.rainbow_hot_spring = get_field_object(self.rainbow_hot_spring_name)

	-- 카메라 그리드 이름
	self.rainbow_hot_spring_camera_grid_name = 'rainbow_hot_spring_grid'

	-- 플래그
	self.is_in_rainbow_hot_spring_grid = false
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
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	-- 미니게임 로드
	self.judgement_minigame = mini_game_manager:GetOrCreate(self.judgement_minigame_name)

	local is_mini_game_load_complete = false

	mini_game_manager:LoadResource(self.judgement_minigame_name, 'default', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield()
	end

	-- 리소스 홀더 백그라운드 로드
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/afterworld/tilesets', 'bg_aw_corporation', function(prefab)
				self.bg_corporation = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	self.bg_corporation.transform.localPosition = vector(0, 0, 16)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/afterworld/tilesets', 'bg_aw_hotel', function(prefab)
				self.bg_hotel = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	self.bg_hotel.transform.localPosition = vector(74, 0, 1.5)

	-- 화난 가이드에 아이템 장착
	for i = 1, self.angry_guide_num - 2 do
		local cur_guide = self:get_spine_controller(self.angry_guide_name..i)
		cur_guide:SetAttachment('[base]weapon1', 'succubus_picket')
	end

	self.judgement_gate = get_field_object(self.judgement_gate_name)

	self.exit_corp = get_field_object(self.exit_corp_name)
	self.exit_corp.Hitbox = CS.Oak.Hitbox(vector(4, 1, 2))

	self.exit_hotel = get_field_object(self.exit_hotel_name)

	local hole_1 = get_field_object('hole_1')
	local hole_2 = get_field_object('hole_2')
	local hole_interact_1 = get_field_object('hole_interact_1')
	local hole_interact_2 = get_field_object('hole_interact_2')

	hole_1.transform.localScale = vector(0.6, 0.6, 0.6)
	hole_2.transform.localScale = vector(0.6, 0.6, 0.6)

	hole_interact_1.Interactable = CS.Oak.PublishInteractable.Create()
	hole_interact_2.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:need_on_launch()
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	local progress_list = {
		0, 1, 2, 3, 4
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
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.judgement_gate = nil

	if self.loop_sfx ~= nil then
		self.loop_sfx:FadeOut()
		self.loop_sfx = nil
	end

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	if self.bg_corporation ~= nil then
		CS.UnityEngine.Object.Destroy(self.bg_corporation.gameObject)
		self.bg_corporation = nil
	end

	if self.bg_hotel ~= nil then
		CS.UnityEngine.Object.Destroy(self.bg_hotel.gameObject)
		self.bg_hotel = nil
	end

	self.cs_controller = nil
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
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		self:on_camera_grid_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
end

function local_class:on_stage_start_event(e)
	-- 메인 퀘스트의 InnerProgress가 4 이상이면 문 열어둠
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	if quest_progress ~= nil and quest_progress.InnerProgress > 3 then
		local gate = get_field_object(self.main_gate_name)
		local animator = gate.Transform:GetComponent(typeof(CS.UnityEngine.Animator))

		animator:Play('open', -1, 1)
		gate.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	-- Rolling Number 설정
	local warning_number_list = create_generic_list(CS.System.Single)
	warning_number_list:Add(438457)
	warning_number_list:Add(169326)
	warning_number_list:Add(268743)
	warning_number_list:Add(95612)
	warning_number_list:Add(154739)
	warning_number_list:Add(134158)

	for i = 1, self.warning_ghost_num do
		local cur_character = self:get_spine_controller(self.warning_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, warning_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hot_spring_number_list = create_generic_list(CS.System.Single)
	hot_spring_number_list:Add(348215)
	hot_spring_number_list:Add(169326)

	for i = 1, self.hot_spring_ghost_num do
		local cur_character = self:get_spine_controller(self.hot_spring_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, hot_spring_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local river_number_list = create_generic_list(CS.System.Single)
	river_number_list:Add(285614)
	river_number_list:Add(243877)
	river_number_list:Add(312643)

	for i = 1, self.river_ghost_num do
		local cur_character = self:get_spine_controller(self.river_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, river_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	character_util.set_rolling_number(
			self:get_spine_controller('main_hall_hotel_ghost').Transform, 62451,
			nil, 0, unity_color({ 0, 0.7, 1, 1 }))

	local reincarnation_number_list = create_generic_list(CS.System.Single)
	reincarnation_number_list:Add(914)
	reincarnation_number_list:Add(23517)
	reincarnation_number_list:Add(67452)

	for i = 1, self.reincarnation_ghost_num do
		local cur_character = self:get_spine_controller(self.reincarnation_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, reincarnation_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	character_util.set_rolling_number(
			get_character(self.runaway_ghost_name).Transform, 874516,
			nil, 0, unity_class.color.red)

	local oneline_number_list = create_generic_list(CS.System.Single)
	oneline_number_list:Add(694513)
	oneline_number_list:Add(71630)

	for i = 1, self.oneline_ghost_num do
		local cur_character = self:get_spine_controller(self.oneline_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, oneline_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local treasure_number_list = create_generic_list(CS.System.Single)
	treasure_number_list:Add(264919)
	treasure_number_list:Add(156832)
	treasure_number_list:Add(336894)

	for i = 1, self.treasure_ghost_num do
		local cur_character = self:get_spine_controller(self.treasure_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, treasure_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local bad_guide_number_list = create_generic_list(CS.System.Single)
	bad_guide_number_list:Add(86735)
	bad_guide_number_list:Add(100249)
	bad_guide_number_list:Add(67352)

	for i = 1, self.bad_guide_ghost_num do
		local cur_character = self:get_spine_controller(self.bad_guide_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, bad_guide_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local massive_energy_number_list = create_generic_list(CS.System.Single)
	massive_energy_number_list:Add(175632)
	massive_energy_number_list:Add(79651)
	massive_energy_number_list:Add(145248)
	massive_energy_number_list:Add(247173)
	massive_energy_number_list:Add(99436)
	massive_energy_number_list:Add(354174)
	massive_energy_number_list:Add(81645)
	massive_energy_number_list:Add(165007)

	for i = 1, self.massive_energy_ghost_num do
		local cur_character = self:get_spine_controller(self.massive_energy_ghost_name..i)

		character_util.set_rolling_number(cur_character.Transform, massive_energy_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_greed_number_list = create_generic_list(CS.System.Single)
	hotel_greed_number_list:Add(5367819)
	hotel_greed_number_list:Add(7482304)
	hotel_greed_number_list:Add(6810502)
	hotel_greed_number_list:Add(4956771)

	for i = 1, self.hotel_greed_num do
		local cur_character = self:get_spine_controller(self.hotel_greed_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_greed_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	character_util.set_rolling_number(self:get_spine_controller(self.hotel_rich_name).Transform, 37810546,
			nil, 0, unity_color({ 0, 0.7, 1, 1 }))

	local hotel_envy_number_list = create_generic_list(CS.System.Single)
	hotel_envy_number_list:Add(50671)
	hotel_envy_number_list:Add(38624)
	hotel_envy_number_list:Add(95173)
	hotel_envy_number_list:Add(84006)
	hotel_envy_number_list:Add(64932)
	hotel_envy_number_list:Add(77519)
	hotel_envy_number_list:Add(58957)
	hotel_envy_number_list:Add(82640)

	for i = 1, self.hotel_envy_num do
		local cur_character = self:get_spine_controller(self.hotel_envy_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_envy_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_rest_number_list = create_generic_list(CS.System.Single)
	hotel_rest_number_list:Add(10934187)
	hotel_rest_number_list:Add(8956014)
	hotel_rest_number_list:Add(7004825)
	hotel_rest_number_list:Add(9136829)

	for i = 1, self.hotel_rest_num do
		local cur_character = self:get_spine_controller(self.hotel_rest_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_rest_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_walk_around_number_list = create_generic_list(CS.System.Single)
	hotel_walk_around_number_list:Add(6702052)
	hotel_walk_around_number_list:Add(7561034)
	hotel_walk_around_number_list:Add(8027519)
	hotel_walk_around_number_list:Add(5923746)

	for i = 1, self.hotel_walk_around_num do
		local cur_character = self:get_spine_controller(self.hotel_walk_around_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_walk_around_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_inside_seat_number_list = create_generic_list(CS.System.Single)
	hotel_inside_seat_number_list:Add(3745095)
	hotel_inside_seat_number_list:Add(5687431)
	hotel_inside_seat_number_list:Add(8802743)
	hotel_inside_seat_number_list:Add(6093456)

	for i = 1, self.hotel_inside_inner_seat_num do
		local cur_character = self:get_spine_controller(self.hotel_inside_seat_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_inside_seat_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_inside_inner_seat_number_list = create_generic_list(CS.System.Single)
	hotel_inside_inner_seat_number_list:Add(21830446)
	hotel_inside_inner_seat_number_list:Add(17845312)

	for i = 1, self.hotel_inside_inner_seat_num do
		local cur_character = self:get_spine_controller(self.hotel_inside_inner_seat_name..i)

		character_util.set_rolling_number(cur_character.Transform, hotel_inside_inner_seat_number_list[i-1],
				nil, 0, unity_color({ 0, 0.7, 1, 1 }))
	end

	local hotel_sleeper = self:get_spine_controller(self.hotel_sleeper_name)
	hotel_sleeper.IsShadowActive = false
	self:set_emotion_spine_controller(hotel_sleeper, 'sleep')

	get_field_object(self.duck_boat_name..1).transform.localRotation = unity_class.quaternion.Euler(0, 90, 0)
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if e.Zone.Name == self.new_employee_event_zone_name then
			if not self.company_simple_event_flags[self.company_simple_event_index.new_employee] then
				self.company_simple_event_flags[self.company_simple_event_index.new_employee] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.new_employee_event, self))
			end
		elseif e.Zone.Name == self.yuna_news_event_zone_name then
			if not self.company_simple_event_flags[self.company_simple_event_index.yuna_news] then
				self.company_simple_event_flags[self.company_simple_event_index.yuna_news] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.yuna_news_event, self))
			end
		elseif e.Zone.Name == self.worry_branch_event_zone_name then
			if not self.company_simple_event_flags[self.company_simple_event_index.worry_branch] then
				self.company_simple_event_flags[self.company_simple_event_index.worry_branch] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.worry_branch_event, self))
			end
		elseif e.Zone.Name == self.angry_guide_event_zone_name then
			if not self.company_simple_event_flags[self.company_simple_event_index.angry_guide] then
				self.company_simple_event_flags[self.company_simple_event_index.angry_guide] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.angry_guide_event, self))
			end
		elseif e.Zone.Name == self.invader_event_zone_name then
			if not self.company_simple_event_flags[self.company_simple_event_index.invader] then
				self.company_simple_event_flags[self.company_simple_event_index.invader] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.invader_event, self))
			end
		end

		if e.Zone.Name == self.warning_event_zone_name then
			if not self.main_hall_simple_event_flags[self.main_hall_simple_event_index.warning] then
				self.main_hall_simple_event_flags[self.main_hall_simple_event_index.warning] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.warning_event, self))
			end
		elseif e.Zone.Name == self.hot_spring_guide_event_zone_name then
			if not self.main_hall_simple_event_flags[self.main_hall_simple_event_index.hot_spring_guide] then
				self.main_hall_simple_event_flags[self.main_hall_simple_event_index.hot_spring_guide] = true

				local talker = get_character(self.hot_spring_guide_name)
				speech_bubble_util.show_speech_bubble(
						talker, { key = 'afterworld_main_hall_hot_spring_guide_1' })
			end
		elseif e.Zone.Name == self.river_guide_event_zone_name then
			if not self.main_hall_simple_event_flags[self.main_hall_simple_event_index.river_guide] then
				self.main_hall_simple_event_flags[self.main_hall_simple_event_index.river_guide] = true

				local talker = get_character(self.river_guide_name)
				speech_bubble_util.show_speech_bubble(
						talker, { key = 'afterworld_main_hall_river_guide_1' })
			end
		elseif e.Zone.Name == self.runaway_event_zone_name then
			if not self.main_hall_simple_event_flags[self.main_hall_simple_event_index.runaway] then
				self.main_hall_simple_event_flags[self.main_hall_simple_event_index.runaway] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.runaway_event, self))
			end
		end

		if e.Zone.Name == self.massive_energy_event_zone_name then
			if not self.see_massive_energy_event then
				self.see_massive_energy_event = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.massive_energy_event, self))
			end
		end

		if e.Zone.Name == self.hotel_entrance_greed_event_zone_name then
			if not self.hotel_entrance_event_flags[self.hotel_entrance_event_index.greed] then
				self.hotel_entrance_event_flags[self.hotel_entrance_event_index.greed] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.hotel_greed_event, self))
			end
		elseif e.Zone.Name == self.hotel_entrance_envy_event_zone_name then
			if not self.hotel_entrance_event_flags[self.hotel_entrance_event_index.envy] then
				self.hotel_entrance_event_flags[self.hotel_entrance_event_index.envy] = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.hotel_envy_event, self))
			end
		end

		if e.Zone.Name == self.hotel_event_zone_name then
			if not self.see_walk_around_event then
				self.see_walk_around_event = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.hotel_walk_around_event, self))
			end
		elseif self.enter_hotel and e.Zone.Name == self.hotel_entrance_zone_name then
			self.enter_hotel = false

			coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.hotel_bgm_reset, self))
		end

		if self.loop_sfx == nil then
			if e.Zone.Name == self.corps_corridor_zone_name or e.Zone.Name == self.main_hall_zone_name or
					e.Zone.Name == self.ticket_sell_zone_name_1 or e.Zone.Name == self.ticket_sell_zone_name_2 or
					e.Zone.Name == self.changing_booth_zone_name or e.Zone.Name == self.hotel_zone_name then
				self.loop_sfx_zone_name = e.Zone.Name

				self.loop_sfx = music_player_util.play_sfx(
						{ sfx_name = "01_crowd_buzz_03", loop = true, type_priority = 'loop' })
			elseif e.Zone.Name == self.hotel_entrance_zone_name then
				self.loop_sfx_zone_name = e.Zone.Name

				self.loop_sfx = music_player_util.play_sfx(
						{ sfx_name = "01_crowd_buzz_02", loop = true, type_priority = 'loop' })
			elseif e.Zone.Name == self.hot_spring_zone_name then
				self.loop_sfx_zone_name = e.Zone.Name

				self.loop_sfx = music_player_util.play_sfx(
						{ sfx_name = "01_water_loop_02", loop = true, type_priority = 'loop' })
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if self.loop_sfx ~= nil then
			if e.Zone.Name == self.loop_sfx_zone_name then
				self.loop_sfx_zone_name = nil

				self.loop_sfx:FadeOut()
				self.loop_sfx = nil
			end
		end

		if e.Zone.Name == self.hotel_zone_name then
			music_player_util.play_stage_music(
					{ name = 'ondemand/afterworld/preload:bgm_afterworld_main', state = 'field' })
		end
	end
end

function local_class:on_camera_grid_enter_event(e)
	if e.CameraGrid.name == self.rainbow_hot_spring_camera_grid_name then
		if not self.is_in_rainbow_hot_spring_grid then
			self.is_in_rainbow_hot_spring_grid = true

			-- 오색 온천 Material 색조 변경 루틴
			coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.set_material_rainbow_hot_spring, self))
		end
	end
end

function local_class:on_camera_grid_leave_event(e)
	if e.CameraGrid.name == self.rainbow_hot_spring_camera_grid_name then
		if self.is_in_rainbow_hot_spring_grid then
			self.is_in_rainbow_hot_spring_grid = false
		end
	end
end

function local_class:on_interact_event(e)
	local hole_interact_1 = get_field_object('hole_interact_1')
	local hole_interact_2 = get_field_object('hole_interact_2')

	if lua_helper.reference_equals(e.Target, self.judgement_gate) then
		local afterworld_main_quest_id = 60049
		local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

		-- 미니게임 진행 상태가 아니라면 상호작용 이벤트 실행함
		if quest_progress ~= nil and quest_progress.InnerProgress ~= 2 then
			sp_util.play_normal_screenplay(self.interact_with_judgement_gate, self)
		end
	elseif lua_helper.reference_equals(e.Target, self.rainbow_hot_spring) then
		sp_util.play_normal_screenplay(self.interact_with_rainbow_hot_spring, self)
	end

	if lua_helper.reference_equals(e.Target, hole_interact_1) then
		sp_util.play_normal_screenplay(self.hole_interact, self)
	elseif lua_helper.reference_equals(e.Target, hole_interact_2) then
		sp_util.play_normal_screenplay(self.hole_interact, self)
	end

	for i = 1, self.book_info_num do
		local cur_book_info = get_field_object(self.book_info_name..i)

		if lua_helper.reference_equals(e.Target, cur_book_info) then
			sp_util.play_normal_screenplay(self.interact_with_book_info, self, i)

			break
		end
	end

	if lua_helper.reference_equals(e.Target, self.exit_corp) then
		sp_util.play_normal_screenplay(self.interact_exit_corp, self)
	elseif lua_helper.reference_equals(e.Target, self.exit_hotel) then
		sp_util.play_normal_screenplay(self.interact_exit_hotel, self)
	end
end
--endregion

--region SpineController Macro Function
-- 스파인 컨트롤러 이름으로 찾아서 리턴
function local_class:get_spine_controller(name)
	return CS.Oak.Stage.Instance.StageTransform:Find(name):GetComponent(typeof(CS.Oak.SpineController))
end

-- 스파인 컨트롤러에 말풍선 표시
function local_class:show_speech_bubble_spine_controller(target, string_key, shout, world_pos)
	local is_shout = lua_helper.get_or_default(shout, false)
	local world_pos_val = lua_helper.get_or_default(world_pos, nil)

	param = speech_bubble.generate_param(get_party_leader(), game_string:GetString(string_key))
	param.Speaker = target.Transform
	param.ClickToProceed = false

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
--endregion

-- 신입사원 이벤트
function local_class:new_employee_event()
	local employee_leader = self:get_spine_controller(self.new_employee_leader_name)

	local employee_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.new_employee_num do
		employee_list:Add(self:get_spine_controller(self.new_employee_name..i))
	end

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_1')

	self:set_animation_spine_controller(employee_leader, { name = 'release', sfx_name = '01_swing_01' })

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_2')

	music_player_util.play_sfx(
			{ sfx_name = "01_crowd_shout_07", play_pos = vector(-38.5, 0, -191) })
	music_player_util.play_sfx(
			{ sfx_name = "02_twohand_stomp_jump_01", play_pos = vector(-38.5, 0, -191) })

	self:remove_animation_spine_controller(employee_leader)

	for i = 0, employee_list.Count - 1 do
		self:set_animation_spine_controller(employee_list[i], { name = 'salute', loop = false })
	end

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_3',
			true, vector(-38.5, 0, -189))

	music_player_util.play_sfx(
			{ sfx_name = "01_crowd_shout_07", play_pos = vector(-38.5, 0, -191) })

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_4',
			true, vector(-38.5, 0, -189))

	music_player_util.play_sfx(
			{ sfx_name = "01_crowd_shout_07", play_pos = vector(-38.5, 0, -191) })

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_5',
			true, vector(-38.5, 0, -189))

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_ready_01", play_pos = vector(-38.5, 0, -191) })

	for i = 0, employee_list.Count - 1 do
		self:remove_animation_spine_controller(employee_list[i])
	end

	self:set_animation_spine_controller(employee_leader, { name = 'shoot' })

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_6')

	music_player_util.play_sfx(
			{ sfx_name = "01_crowd_shout_07", play_pos = vector(-38.5, 0, -191) })
	music_player_util.play_sfx(
			{ sfx_name = "02_twohand_stomp_jump_01", play_pos = vector(-38.5, 0, -191) })

	self:remove_animation_spine_controller(employee_leader)

	for i = 0, employee_list.Count - 1 do
		self:set_animation_spine_controller(employee_list[i], { name = 'salute', loop = false })
	end

	self:show_speech_bubble_spine_controller(employee_leader, 'afterworld_company_new_employee_7',
			true, vector(-37.5, 0, -189))

	for i = 0, employee_list.Count - 1 do
		self:remove_animation_spine_controller(employee_list[i])
	end
end

-- 유나 뉴스 이벤트
function local_class:yuna_news_event()
	local reaper_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.yuna_news_reaper_num do
		reaper_list:Add(self:get_spine_controller(self.yuna_news_reaper_name..i))
	end

	self:show_speech_bubble_spine_controller(reaper_list[1], 'afterworld_company_yuna_news_1')

	reaper_list[1]:Jump(0.5, 0.3)

	wait_for_sec(0.3)

	reaper_list[1]:Jump(0.5, 0.3)

	wait_for_sec(0.3)

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_emphasize_01", play_pos = vector(-21.5, 0, -191) })

	self:show_speech_bubble_spine_controller(reaper_list[0], 'afterworld_company_yuna_news_2')

	self:show_speech_bubble_spine_controller(reaper_list[2], 'afterworld_company_yuna_news_3')

	self:show_speech_bubble_spine_controller(reaper_list[6], 'afterworld_company_yuna_news_4')
end

-- 지부 걱정 이벤트
function local_class:worry_branch_event()
	local reaper_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.worry_branch_reaper_num do
		reaper_list:Add(self:get_spine_controller(self.worry_branch_reaper_name..i))
	end

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_negative_02", play_pos = vector(-6.5, 0, -191) })

	self:show_speech_bubble_spine_controller(reaper_list[1], 'afterworld_company_worry_branch_1')

	self:show_speech_bubble_spine_controller(reaper_list[0], 'afterworld_company_worry_branch_2')

	self:show_speech_bubble_spine_controller(reaper_list[3], 'afterworld_company_worry_branch_3')
end

-- 화가 난 가이드 이벤트
function local_class:angry_guide_event()
	local guide_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.angry_guide_num do
		guide_list:Add(self:get_spine_controller(self.angry_guide_name..i))
	end

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_negative_01", play_pos = vector(2, 0, -195) })

	guide_list[0]:Jump(0.5, 0.3)

	self:show_speech_bubble_spine_controller(guide_list[0], 'afterworld_company_angry_guide_1')

	music_player_util.play_sfx(
			{ sfx_name = "01_jump_01", play_pos = vector(2, 0, -195) })

	guide_list[4]:Jump(0.5, 0.3)

	self:show_speech_bubble_spine_controller(guide_list[4], 'afterworld_company_angry_guide_2')

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_tipsy_01", play_pos = vector(2, 0, -195) })

	self:show_speech_bubble_spine_controller(guide_list[6], 'afterworld_company_angry_guide_3')

	guide_list[1]:Jump(0.5, 0.3)

	self:show_speech_bubble_spine_controller(guide_list[1], 'afterworld_company_angry_guide_4')

	self:show_speech_bubble_spine_controller(guide_list[5], 'afterworld_company_angry_guide_5')
end

-- 인베이더 이벤트
function local_class:invader_event()
	local reaper_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.invader_reaper_num do
		reaper_list:Add(self:get_spine_controller(self.invader_reaper_name..i))
	end

	self:show_speech_bubble_spine_controller(reaper_list[2], 'afterworld_company_invader_1')

	self:show_speech_bubble_spine_controller(reaper_list[0], 'afterworld_company_invader_2')

	self:show_speech_bubble_spine_controller(reaper_list[3], 'afterworld_company_invader_3')
end

-- 메인 광장 악령 주의 이벤트
function local_class:warning_event()
	local warning_reaper_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.warning_reaper_num do
		warning_reaper_list:Add(self:get_spine_controller(self.warning_reaper_name..i))
	end

	local warning_ghost_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.warning_ghost_num do
		warning_ghost_list:Add(self:get_spine_controller(self.warning_ghost_name..i))
	end

	self:set_animation_spine_controller(warning_reaper_list[0], { name = 'release', sfx_name = '01_swing_01' })

	self:show_speech_bubble_spine_controller(warning_reaper_list[0], 'afterworld_main_hall_warning_1')

	self:remove_animation_spine_controller(warning_reaper_list[0])

	self:set_animation_spine_controller(warning_reaper_list[1], { name = 'shoot' })

	self:show_speech_bubble_spine_controller(warning_reaper_list[1], 'afterworld_main_hall_warning_2')

	music_player_util.play_sfx(
			{ sfx_name = "03_runaway_01", play_pos = vector(1, 0, -33.5) })

	self:remove_animation_spine_controller(warning_reaper_list[1])

	warning_ghost_list[1]:Jump(0.5, 0.3)
	self:set_emotion_spine_controller(warning_ghost_list[1], 'scared')

	self:show_speech_bubble_spine_controller(warning_ghost_list[1], 'afterworld_main_hall_warning_3')

	music_player_util.play_sfx(
			{ sfx_name = "01_rustle_01", play_pos = vector(1, 0, -33.5) })

	self:set_animation_spine_controller(warning_ghost_list[5], { name = 'question', loop = false })

	self:show_speech_bubble_spine_controller(warning_ghost_list[5], 'afterworld_main_hall_warning_4')

	self:remove_animation_spine_controller(warning_ghost_list[5])
end

-- 메인 광장 도망치는 유령 이벤트
function local_class:runaway_event()
	local runaway_ghost = get_character(self.runaway_ghost_name)
	character_util.set_position(runaway_ghost, vector(-15, 0, -33.5))
	character_util.set_anim(runaway_ghost, { name = 'run' })
	character_util.set_emotion(runaway_ghost, { name = 'scared' })

	local runaway_reaper = get_character(self.runaway_reaper_name)
	character_util.set_position(runaway_reaper, vector(-15, 0, -33.5))
	character_util.set_anim(runaway_reaper, { name = 'run' })
	character_util.set_emotion(runaway_reaper, { name = 'attack' })

	music_player_util.play_sfx({ sfx_name = "01_prologue_wind_01", parent = runaway_ghost })

	character_util.move_to(runaway_ghost, runaway_ghost.Position + vector(7, 0, 0),
			1, nil, true, false)

	wait_for_sec(1)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = "03_runaway_01", parent = runaway_ghost })

	character_util.set_anim(runaway_ghost, { name = 'cliff' })
	character_util.set_emotion(runaway_ghost, { name = 'surprise' })

	character_util.move_to(runaway_reaper, runaway_reaper.Position + vector(6.5, 0, 0),
			1, nil, true, false)

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = "02_hit_big_01", parent = runaway_ghost })

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			runaway_ghost.Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			runaway_ghost.Position + vector(0, 0.3, 0))

	character_util.set_anim(runaway_ghost, { name = 'prostrate' })
	character_util.set_emotion(runaway_ghost, { name = 'damaged' })

	wait_for_sec(0.5)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = "03_dialogue_sadness_01", parent = runaway_ghost })

	character_util.set_anim(runaway_reaper, { name = 'push' })

	speech_bubble_util.show_speech_bubble_async(
			runaway_ghost, { key = 'afterworld_main_hall_runaway_1', skip = false })

	music_player_util.play_sfx({ sfx_name = "03_dialogue_negative_01", parent = runaway_ghost })

	speech_bubble_util.show_speech_bubble_async(
			runaway_reaper, { key = 'afterworld_main_hall_runaway_2', skip = false })

	speech_bubble_util.show_speech_bubble_async(
			runaway_reaper, { key = 'afterworld_main_hall_runaway_3', skip = false })

	local count_sfx = music_player_util.play_sfx(
			{ sfx_name = "01_count_number_01", loop = true, parent = runaway_ghost, type_priority = 'loop' })

	character_util.rolling_number(
			runaway_ghost.Transform, 974516, nil, 2, unity_class.color.red)

	wait_for_sec(2)

	count_sfx:FadeOut()
end

-- 플레이어 에너지 보고 놀라는 이벤트
function local_class:massive_energy_event()
	local massive_energy_ghost_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.massive_energy_ghost_num do
		massive_energy_ghost_list:Add(self:get_spine_controller(self.massive_energy_ghost_name..i))
	end

	wait_for_sec(0.5)

	music_player_util.play_sfx(
			{ sfx_name = "01_crowd_shout_05", play_pos = vector(-26, 0, -59.5) })

	for i = 0, massive_energy_ghost_list.Count - 1 do
		self:look_at_spine_controller(massive_energy_ghost_list[i], get_party_leader())
		massive_energy_ghost_list[i]:Jump(1, 0.5)
		self:set_animation_spine_controller(massive_energy_ghost_list[i], { name = 'cast' })
		self:set_emotion_spine_controller(massive_energy_ghost_list[i], 'surprise')
	end

	self:show_speech_bubble_spine_controller(
			massive_energy_ghost_list[6], 'afterworld_alley_massive_energy_1')

	music_player_util.play_sfx(
			{ sfx_name = "03_runaway_01", play_pos = vector(-26, 0, -59.5) })

	for i = 0, massive_energy_ghost_list.Count - 1 do
		self:look_at_spine_controller(massive_energy_ghost_list[i], get_party_leader())
	end

	self:set_animation_spine_controller(massive_energy_ghost_list[2], { name = 'embarrassed' })
	self:set_emotion_spine_controller(massive_energy_ghost_list[2], 'confused')

	self:show_speech_bubble_spine_controller(
			massive_energy_ghost_list[2], 'afterworld_alley_massive_energy_2')

	for i = 0, massive_energy_ghost_list.Count - 1 do
		self:look_at_spine_controller(massive_energy_ghost_list[i], get_party_leader())
	end

	self:set_animation_spine_controller(massive_energy_ghost_list[4], { name = 'cast' })
	self:set_emotion_spine_controller(massive_energy_ghost_list[4], 'surprise')

	self:show_speech_bubble_spine_controller(
			massive_energy_ghost_list[4], 'afterworld_alley_massive_energy_3')

	for i = 0, massive_energy_ghost_list.Count - 1 do
		self:look_at_spine_controller(massive_energy_ghost_list[i], get_party_leader())
	end

	music_player_util.play_sfx(
			{ sfx_name = "03_dialogue_positive_01", play_pos = vector(-26, 0, -59.5) })

	self:set_animation_spine_controller(massive_energy_ghost_list[3], { name = 'sing' })
	self:set_emotion_spine_controller(massive_energy_ghost_list[3], 'smile')

	self:show_speech_bubble_spine_controller(
			massive_energy_ghost_list[3], 'afterworld_alley_massive_energy_4')

	for i = 0, massive_energy_ghost_list.Count - 1 do
		self:look_at_spine_controller(massive_energy_ghost_list[i], get_party_leader())
		self:set_animation_spine_controller(massive_energy_ghost_list[i], { name = 'cast' })
		self:set_emotion_spine_controller(massive_energy_ghost_list[i], 'smile')
	end
end

-- 호텔 앞에서 에너지 자랑하는 NPC 이벤트
function local_class:hotel_greed_event()
	local greed_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.hotel_greed_num do
		greed_spine_list:Add(self:get_spine_controller(self.hotel_greed_name..i))
	end

	wait_for_sec(0.5)

	self:show_speech_bubble_spine_controller(
			greed_spine_list[1], 'afterworld_hotel_entrance_greed_1')

	self:show_speech_bubble_spine_controller(
			greed_spine_list[0], 'afterworld_hotel_entrance_greed_2')

	self:show_speech_bubble_spine_controller(
			greed_spine_list[3], 'afterworld_hotel_entrance_greed_3')
end

-- 호텔 앞에서 다단계 영업하는 NPC 이벤트
function local_class:hotel_envy_event()
	local rich_spine = self:get_spine_controller(self.hotel_rich_name)

	local envy_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.hotel_envy_num do
		envy_spine_list:Add(self:get_spine_controller(self.hotel_envy_name..i))
	end

	music_player_util.play_sfx_one_shot('01_crowd_clap_02')

	self:set_animation_spine_controller(rich_spine, { name = 'cast2' })
	self:set_emotion_spine_controller(rich_spine, 'attack')

	self:show_speech_bubble_spine_controller(
			rich_spine, 'afterworld_hotel_entrance_envy_1')

	self:set_animation_spine_controller(rich_spine, { name = 'throw', sfx_name = '01_swing_01' })

	self:show_speech_bubble_spine_controller(
			rich_spine, 'afterworld_hotel_entrance_envy_2')

	self:set_animation_spine_controller(rich_spine, { name = 'success' })

	self:show_speech_bubble_spine_controller(
			rich_spine, 'afterworld_hotel_entrance_envy_3')

	wait_for_sec(1)

	self:show_speech_bubble_spine_controller(
			envy_spine_list[1], 'afterworld_hotel_entrance_envy_4')

	self:show_speech_bubble_spine_controller(
			envy_spine_list[6], 'afterworld_hotel_entrance_envy_5')
end

-- 호텔 안에서 돌아다니는 NPC 이벤트
function local_class:hotel_walk_around_event()
	local walk_around_spine_list = create_generic_list(CS.Oak.SpineController)
	for i = 1, self.hotel_walk_around_num do
		walk_around_spine_list:Add(self:get_spine_controller(self.hotel_walk_around_name..i))
	end

	local waypoint_list_1 = create_generic_list(unity_class.vector3)
	waypoint_list_1:Add(walk_around_spine_list[0].Transform.localPosition + vector(6, 0, 0))
	waypoint_list_1:Add(walk_around_spine_list[0].Transform.localPosition)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.npc_walk_around, self, walk_around_spine_list[0], waypoint_list_1, 1))

	local waypoint_list_2 = create_generic_list(unity_class.vector3)
	waypoint_list_2:Add(walk_around_spine_list[1].Transform.localPosition + vector(4, 0, 0))
	waypoint_list_2:Add(walk_around_spine_list[1].Transform.localPosition + vector(4, 0, 2))
	waypoint_list_2:Add(walk_around_spine_list[1].Transform.localPosition + vector(0, 0, 2))
	waypoint_list_2:Add(walk_around_spine_list[1].Transform.localPosition)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.npc_walk_around, self, walk_around_spine_list[1], waypoint_list_2, 2))

	local waypoint_list_3 = create_generic_list(unity_class.vector3)
	waypoint_list_3:Add(walk_around_spine_list[2].Transform.localPosition + vector(0, 0, 3))
	waypoint_list_3:Add(walk_around_spine_list[2].Transform.localPosition + vector(8, 0, 3))
	waypoint_list_3:Add(walk_around_spine_list[2].Transform.localPosition + vector(8, 0, 0))
	waypoint_list_3:Add(walk_around_spine_list[2].Transform.localPosition)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.npc_walk_around, self, walk_around_spine_list[2], waypoint_list_3, 0))

	local waypoint_list_4 = create_generic_list(unity_class.vector3)
	waypoint_list_4:Add(walk_around_spine_list[3].Transform.localPosition + vector(0, 0, -4))
	waypoint_list_4:Add(walk_around_spine_list[3].Transform.localPosition)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.npc_walk_around, self, walk_around_spine_list[3], waypoint_list_4, 0))
end

-- NPC 돌아다니는 연출
function local_class:npc_walk_around(npc, waypoint_list, index)
	local waypoint_index = 0
	local cur_dir = waypoint_list[waypoint_index] - npc.Transform.localPosition

	local is_stopped = false
	local timer = 0
	local wait_duration = 3

	local is_animated = false
	local animated_duration = 1

	local is_talk = false
	local talk_dist = 3

	local speed = 1.5

	npc.Direction = cur_dir:ToDirection()
	self:set_animation_spine_controller(npc, { name = 'walk' })

	while npc ~= nil do
		if not is_stopped then
			local dist = waypoint_list[waypoint_index] - npc.Transform.localPosition

			if (dist.x + dist.z) * (cur_dir.x + cur_dir.z) < 0 then
				npc.Transform.localPosition = waypoint_list[waypoint_index]

				self:remove_animation_spine_controller(npc)

				is_stopped = true

				if waypoint_index >= waypoint_list.Count - 1 then
					waypoint_index = 0
				else
					waypoint_index = waypoint_index + 1
				end

				cur_dir = waypoint_list[waypoint_index] - npc.Transform.localPosition
			else
				npc.Transform.localPosition =
					npc.Transform.localPosition + cur_dir.normalized * speed * unity_class.time.deltaTime
			end
		else
			if timer >= wait_duration then
				timer = 0
				is_stopped = false
				is_animated = false

				npc.Direction = cur_dir:ToDirection()
				self:set_animation_spine_controller(npc, { name = 'walk' })
			elseif not is_animated and timer >= animated_duration then
				is_animated = true

				if waypoint_index % 2 == 0 then
					npc.Direction = CS.Oak.DirectionExtensions.GetSideDirection(npc.Direction)
					self:set_animation_spine_controller(npc, { name = 'question', loop = false })
				else
					self:set_animation_spine_controller(npc, { name = 'cast' })
				end
			end

			timer = timer + unity_class.time.deltaTime
		end

		if not is_talk and (npc.Transform.localPosition - get_party_leader().Position).magnitude < talk_dist then
			is_talk = true

			if index == 1 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.show_speech_bubble_spine_controller, self, npc, 'afterworld_hotel_walk_around_1'))
			elseif index == 2 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.show_speech_bubble_spine_controller, self, npc, 'afterworld_hotel_walk_around_2'))
			end
		end

		coroutine.yield(nil)
	end
end

-- 심판의 방 문과 상호작용 이벤트
function local_class:interact_with_judgement_gate()
	field_ui_util.show_narration_async({ key = 'afterworld_judgement_minigame_cannot_enter' })

	coroutine.yield(nil)
end

-- 명부 보관소 책에 상호작용 이벤트
function local_class:interact_with_book_info(index)
	if index ~= 5 then
		field_ui_util.show_narration_async({ key = 'afterworld_company_library_'..index })
	else
		field_ui_util.show_narration_async({ key = 'afterworld_company_library_5_1'})

		wait_for_sec(1)

		field_ui_util.show_narration_async({ key = 'afterworld_company_library_5_2' })

		field_ui_util.show_narration_async({ key = 'afterworld_company_library_5_3' })
	end

	coroutine.yield(nil)
end

-- 오색온천
function local_class:set_material_rainbow_hot_spring()
	local water_renderer =
		self.rainbow_hot_spring.Transform:GetChild(0):GetComponent(typeof(CS.UnityEngine.MeshRenderer))
	water_renderer.sharedMaterial = CS.UnityEngine.Material(water_renderer.sharedMaterial)

	local r_plus = true
	local r_add_per_frame = 0.3 / 255

	local g_plus = true
	local g_add_per_frame = 0.8 / 255

	local b_plus = true
	local b_add_per_frame = 0.5 / 255

	local max_r = 150 / 255
	local min_r = 0 / 255

	local max_g = 240 / 255
	local min_g = 120 / 255

	local max_b = 240 / 255
	local min_b = 150 / 255

	while self.rainbow_hot_spring ~= nil and self.is_in_rainbow_hot_spring_grid do
		local cur_r = water_renderer.material.color.r
		local cur_g = water_renderer.material.color.g
		local cur_b = water_renderer.material.color.b

		if r_plus then
			cur_r = cur_r + r_add_per_frame

			if cur_r > max_r then
				r_plus = false
				cur_r = max_r
			end
		else
			cur_r = cur_r - r_add_per_frame

			if cur_r < min_r then
				r_plus = true
				cur_r = min_r
			end
		end

		if g_plus then
			cur_g = cur_g + g_add_per_frame

			if cur_g > max_g then
				g_plus = false
				cur_g = max_g
			end
		else
			cur_g = cur_g - g_add_per_frame

			if cur_g < min_g then
				g_plus = true
				cur_g = min_g
			end
		end

		if b_plus then
			cur_b = cur_b + b_add_per_frame

			if cur_b > max_b then
				b_plus = false
				cur_b = max_b
			end
		else
			cur_b = cur_b - b_add_per_frame

			if cur_b < min_b then
				b_plus = true
				cur_b = min_b
			end
		end

		local cur_color = unity_color({cur_r, cur_g, cur_b, 1})
		water_renderer.material.color = cur_color

		coroutine.yield(nil)
	end
end

-- 오색온천 상호작용
function local_class:interact_with_rainbow_hot_spring()
	local dir = CS.Oak.DirectionExtensions.GetOpposite(get_party_leader().Direction)

	party_util.align_party(vector(71.5, 0, -69.5) + CS.Oak.DirectionExtensions.ToVector3(dir),
			dir, 1)

	local saved_pos = get_party_leader().Position

	field_ui_util.show_narration_async({ key = 'afterworld_rainbow_hot_spring_1' })

	local choose_result = choose_util.play_choose_event(
			{ { 'afterworld_rainbow_hot_spring_2', 'mercy' },
			  { 'afterworld_rainbow_hot_spring_3', 'brutal' } })

	if choose_result == 1 then
		music_player_util.play_stage_music({ name = 'bgm_waypoint', state = 'event', mix = 2 })

		character_util.move_to_async(get_party_leader(), vector(71.5, 0, -69.5),
				1, nil, true, true)

		music_player_util.play_sfx_one_shot('01_water_splash_01')

		character_util.set_direction(get_party_leader(), 'down')
		character_util.set_emotion(get_party_leader(), { name = 'blush' })

		character_util.move_to_async(get_party_leader(),
				get_party_leader().Position + vector(0, -0.6, 0),
				0.3, nil, false, false)

		wait_for_sec(1)

		field_ui_util.show_narration_async({ key = 'afterworld_rainbow_hot_spring_4' })

		for n = 1, 5 do
			music_player_util.play_sfx_one_shot('02_magic_heal_01')

			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = self.rainbow_hot_spring
			heal_info.target = get_party_leader()
			heal_info.heal = math.floor(get_party_leader().FieldObjectStatsBehaviour.MaxHP * 0.2)

			command_util.execute_heal(heal_info)

			wait_for_sec(1)
		end

		field_ui_util.show_narration_async({ key = 'afterworld_rainbow_hot_spring_5' })

		music_player_util.play_stage_music({ state = 'field', mix = 2 })

		music_player_util.play_sfx_one_shot('01_water_float_01')

		character_util.jump(get_party_leader(), 0.5, 0.3)
		character_util.remove_emotion(get_party_leader())
		character_util.move_to_async(get_party_leader(),
				get_party_leader().Position + vector(0, 0.6, 0),
				0.3, nil, false, false)

		character_util.move_to_async(get_party_leader(), saved_pos,
				1, nil, true, true)
	end
end

function local_class:hole_interact()
	field_ui_util.show_narration_async({ key = 'aw_laura_37'})
end

-- 저승 주식회사로 이동
function local_class:interact_exit_corp()
	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 2)
		character_util.move_to(user_party[i], user_party[i].Position + vector(0, 0, 2),
				2, nil, true, true)
	end

	camera_util.resize_to(3.5, 3)
	camera_util.move(vector(-0.5, 0, 17), 3)

	wait_for_sec(2)

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'disabled')
	end

	wait_for_sec(2)

	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')

	screen_util.fade_out_circular_async(0.6, 'linear')

	camera_util.resize_to_default(0)
	stage_camera:SetTarget(get_party_leader())

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'enabled')
		character_util.spine_set_alpha_fade(user_party[i], 1, 0)
	end

	local cur_marker = field:GetMarker(self.exit_corp_marker_name)

	party_util.align_party(cur_marker.position + CS.Oak.DirectionExtensions.ToVector3(cur_marker.direction),
			CS.Oak.DirectionExtensions.GetOpposite(cur_marker.direction), 0, 'linear')

	wait_for_sec(0.6)

	screen_util.fade_in_circular_async(0.6, 'linear')
end

-- 호텔 엘리시움으로 이동
function local_class:interact_exit_hotel()
	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 2)
		character_util.move_to(user_party[i], user_party[i].Position + vector(0, 0, 2),
				2, nil, true, true)
	end

	camera_util.resize_to(3.5, 3)
	camera_util.move(vector(73.5, 0, 3), 3)

	wait_for_sec(2)

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'disabled')
	end

	wait_for_sec(2)

	music_player_util.play_stage_music({ state = 'muted' })

	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')

	screen_util.fade_out_circular_async(0.6, 'linear')

	self.enter_hotel = true

	camera_util.resize_to_default(0)
	stage_camera:SetTarget(get_party_leader())

	for i = 0, user_party.Count - 1 do
		character_util.set_active_state(user_party[i], 'enabled')
		character_util.spine_set_alpha_fade(user_party[i], 1, 0)
	end

	wait_for_sec(0.6)

	local cur_marker = field:GetMarker(self.exit_hotel_marker_name)

	party_util.align_party(cur_marker.position + CS.Oak.DirectionExtensions.ToVector3(cur_marker.direction),
			CS.Oak.DirectionExtensions.GetOpposite(cur_marker.direction), 0, 'linear')

	music_player_util.set_stage_music_clip_async(
			{name = 'ondemand/afterworld/audio:bgm_afterworld_lobby', state = 'field'})

	music_player_util.play_stage_music({ state = 'field' })

	wait_for_sec(0.25)

	screen_util.fade_in_circular_async(0.6, 'linear')
end

-- 호텔 BGM 리셋
function local_class:hotel_bgm_reset()
	music_player_util.play_stage_music({ state = 'muted' })

	wait_for_sec(0.6)

	music_player_util.set_stage_music_clip_async(
			{name = 'ondemand/afterworld/preload:bgm_afterworld_main', state = 'field'})

	music_player_util.play_stage_music({ state = 'field' })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
