local local_class = newclass('DemonShireSquareNPCController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc
	self.get_pickle_mother = function() return get_character('pickle_mother') end
	self.get_pickle_vampire = function() return get_character('pickle_vampire') end
	self.get_pickle_daughter = function() return get_character('pickle_daughter') end
	self.get_market_fight_merchant = function() return get_character('market_fight_merchant') end
	self.get_market_fight_customer = function() return get_character('market_fight_customer') end
	self.get_market_fight_civilian = function(index) return get_character('market_fight_civilian_' .. index) end
	self.get_left_street_civilian = function(index) return get_character('left_street_oneline_' .. index) end
	self.get_square_entrance = function(index) return get_character('square_entrance_oneline_' .. index) end

	-- 마커
	self.get_pickle_pos = function() return field:GetMarker('pickle_pos').position end
	self.get_market_fight_pos = function() return field:GetMarker('market_fight_pos').position end
	self.get_left_street_run_pos = function(index) return field:GetMarker('left_street_oneline_run_pos_' .. index).position end
	self.get_square_entrance_run_pos = function(index) return field:GetMarker('square_entrance_run_pos_' .. index).position end

	-- 피클 이벤트를 봤는지
	self.is_show_pickle_event = false

	-- 시장 싸움 이벤트를 봤는지
	self.is_show_market_fight_event = false

	self.get_fx_last_hit = function() return unity_object_pool.GetOrCreate('FX_lasthit') end
	-- 좌측 오벨리스크 이벤트를 봤는지
	self.is_show_left_obelisk_event = false
	self.left_obelisk_deco = nil
	self.get_left_obelisk_npc = function(index) return get_character('left_obelisk_npc_' .. index)  end
	-- 우측 오벨리스크 이벤트를 봤는지
	self.is_show_right_obelisk_event = false
	self.right_obelisk_deco = nil
	self.get_right_obelisk_npc = function(index) return get_character('right_obelisk_npc_' .. index)  end

	-- 좌측 대로 이벤트를 봤는지
	self.is_show_left_street_event = false

	self.left_street_items = {}

	-- 광장 입구 이벤트를 봤는지
	self.is_show_square_entrance_event = false

	-- dipose에 루프 탈출 용
	self.oneline_loop = true

	self.main_s9_chase_started = false

	--region 관저 주변 로얄가드
	self.get_out_office_patrol = function(group_num, index)
		return get_character('out_office_patrol_' .. group_num .. '_' .. index)
	end
	self.get_out_office_blocker = function(index) return get_character('out_office_blocker_' .. index) end

	self.get_out_office_patrol_pos = function(group_num, index)
		return field:GetMarker('out_office_patrol_pos_' .. group_num .. '_' .. index).position
	end

	self.out_office_patrol_group_count = 2
	self.out_office_patrol_npc_count = 5
	self.out_office_patrol_wp_count = 4

	self.out_office_patrol_info = {
		{
			z_diff = 0,
			emotion = 'attack',
		},
		{
			z_diff = 1.5,
		},
		{
			z_diff = 2.5,
		},
		{
			z_diff = 3.5,
		},
		{
			z_diff = 4.5,
		},
	}

	self.out_office_blocker_zone_name = 'out_office_blocking'
	self.is_out_office_blocking = false

	--endregion 관저 주변 로얄가드
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	-- FIXME : 메인퀘스트 진행도에 따라서 구독 요청 여부 결정
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.get_fx_last_hit()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.left_obelisk_deco ~= nil then
		self.left_obelisk_deco:ConsumeComplete()
		self.left_obelisk_deco = nil
	end

	if self.right_obelisk_deco ~= nil then
		self.right_obelisk_deco:ConsumeComplete()
		self.right_obelisk_deco = nil
	end

	if self.left_street_items ~= nil then
		for i = 1, #self.left_street_items do
			self.left_street_items[i]:ConsumeComplete()
		end
		self.left_street_items = nil
	end

	self.cs_controller = nil

	self.oneline_loop = false
end

--- OnEvent
function local_class:on_event(_)
	return false
end

--- on_stage_loaded_event
function local_class:on_stage_loaded_event(_)
	self:left_obelisk_setting()
	self:right_obelisk_setting()

	self:pickle_event_npc_setting()
	self:magic_event_setting()
	self:market_fight_event_npc_setting()

	self:left_street_setting()
	self:square_entrance_setting()

	self:out_office_patrol_setting()

	return true
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if not self.is_show_pickle_event and
		type_util.is_zone_full_enter(e, user_party.Leader, 'pickle_event') then

		self.is_show_pickle_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pickle_event, self))

		return true
	end

	if not self.is_show_market_fight_event and
		type_util.is_zone_full_enter(e, user_party.Leader, 'market_fight_event') then

		self.is_show_market_fight_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.market_fight_event, self))

		return true
	end

	if not self.is_show_left_obelisk_event and
		type_util.is_zone_full_enter(e, user_party.Leader, 'left_obelisk_zone') then

		self.is_show_left_obelisk_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.left_obelisk_event, self))

		return true
	end

	if not self.is_show_right_obelisk_event and
		type_util.is_zone_full_enter(e, user_party.Leader, 'right_obelisk_zone') then

		self.is_show_right_obelisk_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.right_obelisk_event, self))

		return true
	end

	if not self.is_show_left_street_event and not self.main_s9_chase_started and
			type_util.is_zone_full_enter(e, user_party.Leader, 'left_street_oneline_event') then

		self.is_show_left_street_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.left_street_event, self))

		return true
	end

	if not self.is_show_square_entrance_event and not self.main_s9_chase_started and
			type_util.is_zone_full_enter(e, user_party.Leader, 'square_entrance_event') then

		self.is_show_square_entrance_event = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.square_entrance_event, self))

		return true
	end

	if type_util.is_zone_full_enter(e, get_party_leader(), self.out_office_blocker_zone_name)
			and not self.is_out_office_blocking then
		self.is_out_office_blocking = true
		sp_util.play_normal_screenplay(self.enter_out_office_block, self)

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	-- 관저 좌우의 패트롤 NPC 비활성화
	-- FIXME : 임시 주석 처리
	if e:GetParamAt(0) == 'main_s9_start_chase' and not self.main_s9_chase_started then
		self.main_s9_chase_started = true

		for i = 1, self.out_office_patrol_group_count do
			for j = 1, self.out_office_patrol_npc_count do
				local npc = self.get_out_office_patrol(i, j)
				character_util.stop(npc)
				character_util.remove_anim_and_emotion(npc)
				character_util.set_active_state(npc, 'disabled')
			end
		end

		for i = 1, 4 do
			local npc = self.get_left_street_civilian(i)
			character_util.stop(npc)
			character_util.remove_anim_and_emotion(npc)
			character_util.set_active_state(npc, 'disabled')
		end

		for i = 1, #self.left_street_items do
			self.left_street_items[i]:ConsumeComplete()
		end
		self.left_street_items = nil

		for i = 1, 4 do
			local npc = self.get_square_entrance(i)
			character_util.stop(npc)
			character_util.remove_anim_and_emotion(npc)
			character_util.set_active_state(npc, 'disabled')
		end

		return true
	end

	return false
end

--- 관저 좌우의 패트롤 NPC
function local_class:out_office_patrol_setting()
	for i = 1, self.out_office_patrol_group_count do
		local waypoints = {}

		for j = 1, self.out_office_patrol_wp_count do
			table.insert(waypoints, self.get_out_office_patrol_pos(i, j))
		end

		for j = 1, self.out_office_patrol_npc_count do

			local npc = self.get_out_office_patrol(i, j)
			local setting_info = self.out_office_patrol_info[j]

			character_util.set_active_state(npc, 'visible')

			-- 조금씩 뒤로
			npc.Position = waypoints[1] + setting_info.z_diff * vector(0, 0, -1)

			character_util.remove_anim_and_emotion(npc)

			if setting_info.emotion ~= nil then
				character_util.set_emotion(npc, { name = setting_info.emotion })
			end

			wp_util.move_way_points(npc,
					{ waypoints = waypoints, speed = 0.6, anim_time_scale = 0.7, end_type = 'loop' })
		end
	end
end

function local_class:enter_out_office_block()
	local blocker_1 = self.get_out_office_blocker(1)
	local blocker_2 = self.get_out_office_blocker(2)
	local leader = get_party_leader()
	local zone_bounds = field:GetZone(self.out_office_blocker_zone_name).Bounds
	local leader_blocker = blocker_1
	local none_blocker = blocker_2

	-- 더 가까운 로얄 가드 가져옴
	if math.abs(leader.Position.x - blocker_1.Position.x)
			> math.abs(leader.Position.x - blocker_2.Position.x) then
		leader_blocker = blocker_2
		none_blocker = blocker_1
	else
		leader_blocker = blocker_1
		none_blocker = blocker_2
	end

	local need_block = math.abs(leader.Position.x - leader_blocker.Position.x) > 0.6
	local leader_blocker_origin_pos = leader_blocker.Position

	-- 너무 가까운 경우는 가서 막지 않도록
	if need_block then
		wp_util.move_way_points_async(leader_blocker, {
			waypoints = vector(leader.Position.x, 0, leader_blocker.Position.z),
			speed = 3.5, last_direction = CS.Oak.Direction.Down
		})
	end

	--로얄가드1(down, idle, idle) : 현재 이 지역은 출입 불가입니다.
	music_player_util.play_sfx_one_shot('01_armor_01')
	speech_bubble_util.show_speech_bubble_async(leader_blocker, { key = 'ds_out_office_blocker_1', skip = true })

	--로얄가드2(down, idle, idle) : 뒤로 물러나 주시길 바랍니다.
	speech_bubble_util.show_speech_bubble_async(none_blocker, { key = 'ds_out_office_blocker_2', skip = true })

	local move_duration = 1
	local move_done_count = 0
	local move_done_cb = function(wp_index)
		if wp_index == 0 then
			move_done_count = move_done_count + 1
		end
	end

	if need_block then
		wp_util.move_way_points(leader_blocker, {
			waypoints = leader_blocker_origin_pos,
			speed = 3,
			last_direction = CS.Oak.Direction.Down,
			callback = move_done_cb
		})
	else
		move_done_count = move_done_count + 1
	end

	--이후 가디언 물러남.
	wp_util.move_way_points(leader, {
		waypoints = vector(leader.Position.x, 0, zone_bounds.min.z - 1),
		speed = 2,
		callback = move_done_cb
	})

	while move_done_count < 2 do
		coroutine.yield()
	end

	self.is_out_office_blocking = false

	--플레이어 컨트롤 풀림.
end

--- 피클 이벤트 npc 세팅
function local_class:pickle_event_npc_setting()
	local pickle_pos = self.get_pickle_pos()

	drop_item_util.create_item({ pos = pickle_pos + vector(0, 0.5, 0),
								 itemid = 20570, notforinven = true, lootstate = 'dontfindlooter',
								 sprscale = 0.75 })

	local mother = self.get_pickle_mother()
	mother.Interactable.Talk = nil

	self.get_pickle_vampire().Interactable.Talk = nil
	self.get_pickle_daughter().Interactable.Talk = nil
end

--- 피클 이벤트
function local_class:pickle_event()
	local pickle_mother = self.get_pickle_mother()
	local pickle_vampire = self.get_pickle_vampire()
	local pickle_daughter = self.get_pickle_daughter()

	-- 빨강3 (right, attack, bomb_idle) : 내가 밥 먹겠다는데 당신 무슨 상관이에요?!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_02', parent = pickle_vampire, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(pickle_vampire, { key = 'ds_pickle_event_1' })

	self:waiting_for_interact()

	-- 빨강1(left, attack, release) : 여기서 혈액팩을 먹으면 어떻게 해요! 애들 정서에 안 좋잖아요!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_01', parent = pickle_mother, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(pickle_mother, { key = 'ds_pickle_event_2' })

	self:waiting_for_interact()

	-- 빨강2(right, tired, push) : 엄마… 싸우지 마아…
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_sadness_01', parent = pickle_daughter,
		type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(pickle_daughter, { key = 'ds_pickle_event_3' })

	pickle_mother.Interactable.Talk = 'ds_pickle_event_2'
	pickle_vampire.Interactable.Talk = 'ds_pickle_event_1'
	pickle_daughter.Interactable.Talk = 'ds_pickle_event_3'
end

--- 시장 싸움 이벤트 npc 세팅
function local_class:market_fight_event_npc_setting()
	local market_fight_pos = self.get_market_fight_pos()

	local drop_items = {}

	local create_drop_item = function(pos, item_id)
		local item = drop_item_util.create_item(
			{ pos = pos, itemid = item_id, notforinven = true,
			  lootstate = 'dontfindlooter', sprscale = 0.5, showoncharacter = true })

		table.insert(drop_items, item)
	end

	create_drop_item(market_fight_pos + vector(0, 0.5, 0), 20647)
	create_drop_item(market_fight_pos + vector(-1, 0.5, 0), 20648)
	create_drop_item(market_fight_pos + vector(-1, 0.5, 1), 20649)

	for i = 1, 3 do
		local item = drop_items[i]
		item.ShadowTransform.localPosition = vector(0, 0.5, -0.03)
	end

	self.get_market_fight_merchant().Interactable.Talk = nil
	self.get_market_fight_customer().Interactable.Talk = nil

	self.get_market_fight_civilian(1).Interactable.TalkSfx = '03_dialogue_tipsy_01'
end

--- 시장 싸움 이벤트
function local_class:market_fight_event()
	local merchant = self.get_market_fight_merchant()
	local customer = self.get_market_fight_customer()
	local center_pos = (merchant.Position + customer.Position) / 2

	-- 마족 상인(ds_demon_oldman) : 너…! 지금 뭐라 그랬어?!
	music_player_util.play_sfx({
		sfx_name = '01_rustle_01', play_pos = center_pos, type_priority = 'event', player_priority = 'npc',
	})
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_01', parent = merchant, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(merchant, { key = 'ds_market_fight_event_1' })

	self:waiting_for_interact()

	-- 뱀파이어 시민1(ds_vampire_male) : 확 벨리알에나 씌어버리라고 했다!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_02', parent = customer, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(customer, { key = 'ds_market_fight_event_2' })

	customer.Interactable.Talk = 'ds_market_fight_event_2'
	merchant.Interactable.Talk = 'ds_market_fight_event_1'
end

--- 마술 이벤트 세팅
function local_class:magic_event_setting()
	local magician = get_character('magic_magician')
	magician.SpineController:SetAttachment('[base]weapon1', 'bari_shepherds_fresh')

	drop_item_util.create_item(
		{ pos = magician.Position + vector(-0.6, 0, 0),
		  itemid = 20650, notforinven = true, lootstate = 'dontfindlooter',
		  sprscale = 0.75 })
end

function local_class:left_obelisk_setting()
	local obelisk_pos = field:GetMarker('left_obelisk_pos').position

	if self.left_obelisk_deco == nil then
		self.left_obelisk_deco = drop_item_util.create_item({itemid = 20651, pos = obelisk_pos + vector(0, 3, -0.9),
															 notforinven = true, showoncharacter = true,
															 lootstate = 'dontfindlooter'})
		self.left_obelisk_deco.ShadowTransform.gameObject:SetActive(false)
	end

	if not self.is_show_left_obelisk_event then
		local npc_1 = self.get_left_obelisk_npc(1)
		character_util.set_direction(npc_1, 'up')
		character_util.set_anim(npc_1, { name = 'basket_idle' })
		self.left_obelisk_deco.Position = npc_1.Position + vector(0, 0.6, 0)
		self.left_obelisk_deco:SetSortingLayer(false)
	else
		local talk_name = 'ds_left_obelisk_oneline_'
		self.get_left_obelisk_npc(1).Interactable.Talk = talk_name .. 1
		self.get_left_obelisk_npc(3).Interactable.Talk = talk_name .. 2
		self.get_left_obelisk_npc(5).Interactable.Talk = talk_name .. 3
	end
end

function local_class:left_obelisk_event()
	local obelisk_pos = field:GetMarker('left_obelisk_pos').position
	local talk_name = 'ds_left_obelisk_oneline_'
	local npc_1 = self.get_left_obelisk_npc(1)
	local npc_2 = self.get_left_obelisk_npc(2)
	local npc_3 = self.get_left_obelisk_npc(3)
	local npc_5 = self.get_left_obelisk_npc(5)

	local clap_sfx = music_player_util.play_sfx({
		sfx_name = '01_clap_01', parent = npc_2, loop = true, type_priority = 'loop', player_priority = 'npc',
	})

	local init_pos = npc_1.Position
	character_util.set_anim(npc_1, {name = 'basket_walk'})
	local timer = 0
	local duration = 0.5
	while timer < duration do
		local progress = timer / duration
		character_util.set_position(npc_1, init_pos + vector(0, 0, 0.5 * progress))
		self.left_obelisk_deco.Position = npc_1.Position + vector(0, 0.6, 0)
		timer = timer + unity_class.time.deltaTime
		coroutine.yield()
	end
	character_util.set_anim(npc_1, { name = 'basket_idle' })
	wait_for_sec(0.5)
	character_util.set_anim(npc_1, { name = 'jump' })
	character_util.jump(npc_1, 1.5, 0.7, 0.15)
	music_player:PlaySfxOneShot("01_small_jump_01")

	music_player_util.play_sfx({
		sfx_name = '01_holdup_01', parent = npc_1, type_priority = 'event', player_priority = 'npc',
	})

	timer = 0
	duration = 0.4
	init_pos = npc_1.Position + vector(0, 0.6, 0)
	local move_dir = obelisk_pos + vector(0, 3, -0.9) - init_pos
	local anim_token = true
	while timer < duration do
		local progress = timer / duration
		if anim_token and timer > 0.3 then
			anim_token = false
			character_util.set_animation_n_times(npc_1, { name = 'attack' })
		end

		self.left_obelisk_deco.Position = init_pos + move_dir * progress
		timer = timer + unity_class.time.deltaTime
		coroutine.yield()
	end
	self.left_obelisk_deco.Position = obelisk_pos + vector(0, 3, -0.9)
	self.left_obelisk_deco:SetSortingLayer(true)
	music_player_util.play_sfx({
		sfx_name = '01_gatcha_point_01', play_pos = self.left_obelisk_deco.Position,
		type_priority = 'event', player_priority = 'npc',
	})

	wait_for_sec(0.8 - duration)
	character_util.remove_anim(npc_1)
	clap_sfx:Stop()
	wait_for_sec(0.2)

	self:waiting_for_interact()

	--빨강1(left, awesome, ;clap) : 이번 태양 축제는 역대 최대 규모라지?
	character_util.set_direction(npc_1, 'left')
	music_player_util.play_sfx({
		sfx_name = '01_clap_02', parent = npc_1, type_priority = 'loop', player_priority = 'npc',
	})
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_positive_01', parent = npc_1, type_priority = 'loop', player_priority = 'npc',
	})
	character_util.set_anim_and_emotion(npc_1, {name = 'clap'}, {name = 'awesome'})
	speech_bubble_util.show_speech_bubble_async(npc_1, {key = talk_name .. 1})

	self:waiting_for_interact()

	--빨강3(left, smile, release2) : 마계 최고의 아이돌 그룹, 데몬걸즈도 온다는 소리를 들었어!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_emphasize_01', parent = npc_3, type_priority = 'event', player_priority = 'npc',
	})
	character_util.set_animation_n_times(npc_3, {name = 'release', count = 2, sfx = function()
		music_player_util.play_sfx({
			sfx_name = '01_swing_01', parent = npc_3, type_priority = 'event', player_priority = 'npc'
		})
	end})
	speech_bubble_util.show_speech_bubble_async(npc_3, {key = talk_name .. 2})

	self:waiting_for_interact()

	--빨강5(right, awesome, get) ::작년 축제보다 더 즐겁게 먹고, 마시고, 즐기자고!
	music_player_util.play_sfx({
		sfx_name = '01_bad_fairy_01', parent = npc_5, type_priority = 'event', player_priority = 'npc',
	})
	character_util.set_anim_and_emotion(npc_5, {name = 'get'}, {name = 'awesome'})
	speech_bubble_util.show_speech_bubble_async(npc_5, {key = talk_name .. 3})

	self:left_obelisk_setting()
end

function local_class:right_obelisk_setting()
	local obelisk_pos = field:GetMarker('right_obelisk_pos').position
	if self.right_obelisk_deco == nil then
		self.right_obelisk_deco = drop_item_util.create_item({itemid = 20651, pos = obelisk_pos + vector(0, 3, -0.9),
															 notforinven = true, showoncharacter = true,
															 lootstate = 'dontfindlooter'})
	end

	if self.is_show_right_obelisk_event then
		local target_pos = obelisk_pos + vector(0.3, 0.05, -1.3)
		self.right_obelisk_deco.Position = target_pos
		self.right_obelisk_deco.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 30, 0)
		self.right_obelisk_deco:SetSortingLayer(false)

		character_util.set_anim_and_emotion(self.get_right_obelisk_npc(1), {name = 'release'}, {name = 'attack'})
		character_util.set_anim_and_emotion(self.get_right_obelisk_npc(2), {name = 'cast2'}, {name = 'attack'})
		character_util.set_anim_and_emotion(self.get_right_obelisk_npc(3), {name = 'victory_extra'}, {name = 'attack'})
		character_util.set_anim_and_emotion(self.get_right_obelisk_npc(4), {name = 'victory_extra'}, {name = 'attack'})

		local talk_name = 'ds_right_obelisk_oneline_'
		self.get_right_obelisk_npc(1).Interactable.Talk = talk_name .. 1
		self.get_right_obelisk_npc(2).Interactable.Talk = talk_name .. 2
	end
end

function local_class:right_obelisk_event()
	local obelisk_pos = field:GetMarker('right_obelisk_pos').position
	local talk_name = 'ds_right_obelisk_oneline_'

	--빨강 1이 attack 애니메이션으로 오벨리스크의 장식을 떨어뜨린다,
	local vampires = {}
	for i = 1, 4 do
		table.insert(vampires, self.get_right_obelisk_npc(i))
	end

	character_util.set_animation_n_times(vampires[1], {name = 'attack', count = 1})
	character_util.spine_deviate_local(vampires[1], vector(0.8, 0, 0), 0.4, 0.3)
	wait_for_sec(0.3)
	--오벨리스크에 fx_lasthit
	self.get_fx_last_hit():Instantiate(vampires[1].Position + vector(0.5, 0.5, 0))
	music_player_util.play_sfx({
		sfx_name = '02_hit_big_01', play_pos = vampires[1].Position + vector(0.5, 0.5, 0),
		type_priority = 'event', player_priority = 'npc',
	})
	--태양 장식 shake 후 바닥에 떨어짐
	local timer = 0
	local duration = 0.3
	local init_pos = self.right_obelisk_deco.Position
	local anim_token = true

	while duration > 0 do
		if timer > 0.03 then
			duration = duration - 0.03
			timer = 0
		end

		if anim_token then
			self.right_obelisk_deco.Position = init_pos + vector(0.5, 0, 0) * duration
		else
			self.right_obelisk_deco.Position = init_pos + vector(-0.5, 0, 0) * duration
		end
		anim_token = not anim_token

		timer = timer + unity_class.time.deltaTime
		coroutine.yield()
	end

	wait_for_sec(0.2)

	timer = 0
	duration = 0.7
	init_pos = obelisk_pos + vector(0, 3, -0.9)
	local target_pos = obelisk_pos + vector(0.3, 0.05, -1.3)
	anim_token = true
	while timer < duration do
		local progress = (timer*timer) / (duration*duration)
		local ypos = math.abs(math.cos(progress * math.pi)) * (1 - progress)
		if anim_token and progress > 0.333 then
			-- 약 0.57초 지난 시점
			anim_token = false
			camera_util.shake(0.05, 0.3)
			music_player_util.play_sfx({
				sfx_name = '01_hit_comic_01', play_pos = self.right_obelisk_deco.Position,
				type_priority = 'event', player_priority = 'npc',
			})
			self.right_obelisk_deco:SetSortingLayer(false)
		end

		if not anim_token then
			self.right_obelisk_deco.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 45 * progress - 0.333, 0)
		end
		self.right_obelisk_deco.Position = target_pos + (init_pos - target_pos) * ypos
		timer = timer + unity_class.time.deltaTime
		coroutine.yield()
	end
	self.right_obelisk_deco.Position = target_pos
	self.right_obelisk_deco.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 30, 0)


	--장식이 떨어지면 빨강 2, 3, 4 (left, attack, victory_extra) 애니메이션으로 변경
	for i = 2, 4 do
		character_util.set_anim(vampires[i], {name = 'victory_extra'})
	end

	self:waiting_for_interact()

	--빨강1(right, release, attack) : 태양 축제는 무슨! 멀쩡히 살고 있던 우리 땅을 빼앗은 도둑놈들 주제에!
	character_util.set_anim_and_emotion(vampires[1], { name = 'release', sfx_name = function()
		music_player_util.play_sfx({
			sfx_name = '01_swing_01', parent = vampires[1], type_priority = 'event', player_priority = 'npc',
		})
	end }, {name = 'attack'})
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_02', parent = vampires[1], type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(vampires[1], {key = talk_name .. 1})
	character_util.set_anim(vampires[1], { name = 'release' })

	self:waiting_for_interact()

	--빨강2 (right, attack, cast2) : 망할 인공 태양 때문에 우리 뱀파이어들이 얼마나 고통받고 있는지도 모르는 건가?
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_negative_01', parent = vampires[1], type_priority = 'event', player_priority = 'npc',
	})
	character_util.set_anim_and_emotion(vampires[2], {name = 'cast2'}, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(vampires[2], {key = talk_name .. 2})

	self:right_obelisk_setting()
end

function local_class:left_street_setting()
	local bench_npc = self.get_left_street_civilian(1)
	local drunken_npc = self.get_left_street_civilian(2)
	local kid_girl = self.get_left_street_civilian(3)
	local kid_boy = self.get_left_street_civilian(4)

	-- 밴치 취객들 설정
	local bench_items = {
		rum_item = {
			id = 20644,
			pos = { bench_npc.Position + vector(0.5, 0, 0) }
		},
		ds_chicken_basket = {
			id = 20636,
			pos = { bench_npc.Position + vector(0.8, 0, 0) }
		},
		ds_shield_beer_empty = {
			id = 20645,
			pos = { drunken_npc.Position + vector(-0.25, 0, -0.5) }
		},
		ds_shield_beer_empty_2 = {
			id = 20646,
			pos = { drunken_npc.Position + vector(-0.5, 0, -0.65) }
		}
	}

	bench_npc.Interactable.TalkSfx = '01_clap_01'
	drunken_npc.Interactable.TalkSfx = '03_dialogue_tipsy_01'

	for _, item in pairs(bench_items) do
		for i = 1, #item.pos do
			table.insert(self.left_street_items, drop_item_util.create_item({
				itemid = item.id,
				pos = item.pos[i],
				notforinven = true,
				showoncharacter = false,
				lootstate = 'dontfindlooter',
				sprscale = 0.7
			}))
		end
	end

	-- 뛰어다니는 아이들 설정
	kid_girl.SpineController:SetAttachment('[base]weapon2', 'snowmountain_teddy')
	kid_boy.SpineController:SetAttachment('[base]weapon2', 'teatan_ranger_figure')

	field_ui_manager:RemoveUI(kid_girl, CS.Oak.FieldUiType.CharacterStats)
	field_ui_manager:RemoveUI(kid_boy, CS.Oak.FieldUiType.CharacterStats)

	character_util.set_active_state(kid_girl, 'visible')
	character_util.set_active_state(kid_boy, 'visible')

	character_util.set_anim(kid_girl, { name = 'sword_run' })
	character_util.set_anim(kid_boy, { name = 'sword_run' })

	local run_wp = {
		self.get_left_street_run_pos(1),
		self.get_left_street_run_pos(2),
		self.get_left_street_run_pos(3),
		self.get_left_street_run_pos(4)
	}

	character_util.move_waypoint(kid_girl, run_wp, 4, true, 'loop')
	character_util.move_waypoint(kid_boy, run_wp, 4, true, 'loop')
end

function local_class:left_street_event()
	local kid_girl = self.get_left_street_civilian(3)
	local kid_boy = self.get_left_street_civilian(4)

	while true do
		if not self.oneline_loop then
			return
		end

		-- 화면에 둘 다 보일 때 까지 이벤트 대기
		if screen_util.is_fo_in_screen(kid_girl.Position) and
				screen_util.is_fo_in_screen(kid_boy.Position) then
			break
		end
		coroutine.yield(nil)
	end

	--빨강3(smile) : 이거 봐라! 엄마가 새 인형 사 췄어!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_positive_01', parent = kid_girl, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(kid_girl, { key = 'ds_stage1_oneline_3' })

	self:waiting_for_interact()

	--빨강4(attack) : 내 로보트가 더 멋있거든?
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_emphasize_01', parent = kid_boy, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(kid_boy, { key = 'ds_stage1_oneline_4' })
end

function local_class:square_entrance_setting()
	local mask_man = self.get_square_entrance(1)
	local left_kid_1 = self.get_square_entrance(2)
	local left_kid_2 = self.get_square_entrance(3)
	local kid_boy = self.get_square_entrance(4)
	local kid_girl = self.get_square_entrance(5)

	-- 마스크맨 풍선 들고있는 연출
	local mask_man_balloon = drop_item_util.create_item(
			{ pos = mask_man.Position + vector(0.4, 0, 1), itemid = 20625, notforinven = true,
			  lootstate = 'dontfindlooter', sprscale = 0.75, showoncharacter = true })

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.item_floating, self, mask_man_balloon, 2.668, 0.05))

	left_kid_1.Interactable.TalkSfx = '03_dialogue_emphasize_01'
	left_kid_2.Interactable.TalkSfx = '03_dialogue_positive_01'

	character_util.remove_anim(left_kid_1)
	character_util.set_anim(left_kid_1, { name = 'success', sfx_name = 	function()
		music_player_util.play_sfx({
			sfx_name = '01_small_jump_01', parent = left_kid_1, type_priority = 'default', player_priority = 'npc',
		})
	end })

	-- 뛰어다니는 애들
	local kid_boy_wp = {
		self.get_square_entrance_run_pos(2),
		self.get_square_entrance_run_pos(3),
		self.get_square_entrance_run_pos(4),
		self.get_square_entrance_run_pos(1),
	}

	local kid_girl_wp = {
		self.get_square_entrance_run_pos(1),
		self.get_square_entrance_run_pos(2),
		self.get_square_entrance_run_pos(3),
		self.get_square_entrance_run_pos(4),
	}

	field_ui_manager:RemoveUI(kid_girl, CS.Oak.FieldUiType.CharacterStats)
	field_ui_manager:RemoveUI(kid_boy, CS.Oak.FieldUiType.CharacterStats)

	character_util.set_active_state(kid_girl, 'visible')
	character_util.set_active_state(kid_boy, 'visible')

	character_util.set_anim(kid_boy, { name = 'sword_run' })
	character_util.set_anim(kid_girl, { name = 'sword_run' })

	character_util.move_waypoint(kid_boy, kid_boy_wp, 4, true, 'loop')
	character_util.move_waypoint(kid_girl, kid_girl_wp, 4, true, 'loop')

	-- 뛰는 애가 든 풍선
	local kid_boy_balloon = drop_item_util.create_item(
			{ pos = kid_boy.Position, itemid = 20625, notforinven = true,
			  lootstate = 'dontfindlooter', sprscale = 0.75, showoncharacter = true })

	local dir_offset = {
		down = vector(-0.25, 0.1, 0.5),
		right = vector(0.15, 0.1, 0.5),
		up = vector(0.15, 0.1, 0.65),
		left = vector(-0.15, 0.1, 0.5),
	}

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		while self.oneline_loop and not self.main_s9_chase_started do
			local dir_key = direction_util.to_str(kid_boy.Direction)
			kid_boy_balloon.SpriteTransform.position = kid_boy.Position + dir_offset[dir_key]
			kid_boy_balloon.ShadowTransform.position = kid_boy.Position + dir_offset[dir_key] + vector(0, -0.03, 0)
			coroutine.yield(nil)
		end

		kid_boy_balloon:ConsumeComplete()
	end))
end

function local_class:square_entrance_event()
	local kid_boy = self.get_square_entrance(4)
	local kid_girl = self.get_square_entrance(5)

	while true do
		if not self.oneline_loop or self.main_s9_chase_started then
			return
		end

		-- 화면에 둘 다 보일 때 까지 이벤트 대기
		if screen_util.is_fo_in_screen(kid_girl.Position) and
				screen_util.is_fo_in_screen(kid_boy.Position) then
			break
		end
		coroutine.yield(nil)
	end

	--빨강4(cry) : 내 풍선 돌려줘…!
	music_player_util.play_sfx({
		sfx_name = '01_kid_girl_shout_01', parent = kid_girl, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(kid_girl, { key = 'ds_balloon_event_4' })

	self:waiting_for_interact()

	if self.main_s9_chase_started then
		return
	end

	--빨강3(smile) : 싫은데! 새로 하나 받아오던가!
	music_player_util.play_sfx({
		sfx_name = '01_bad_fairy_01', parent = kid_boy, type_priority = 'event', player_priority = 'npc',
	})
	speech_bubble_util.show_speech_bubble_async(kid_boy, { key = 'ds_balloon_event_5' })
end

function local_class:item_floating(item, cycle_dur, y_gap)
	local item_pos = item.SpriteTransform.position
	local shadow_pos = item.ShadowTransform.position
	local time_passed = unity_class.time.deltaTime
	local half_cycle = cycle_dur * 0.5
	local move_up = true
	while self.oneline_loop and not self.main_s9_chase_started do
		if move_up then
			time_passed = time_passed + unity_class.time.deltaTime
		else
			time_passed = time_passed - unity_class.time.deltaTime
		end
		local progress = unity_class.mathf.Clamp01(time_passed / half_cycle)

		if progress >= 1 then
			move_up = false
		elseif progress <= 0 then
			move_up = true
		end

		local new_y = math.sin(math.pi * progress) * y_gap
		item.SpriteTransform.position = item_pos + vector(0, 0, new_y)
		item.ShadowTransform.position = shadow_pos + vector(0, 0, new_y)

		coroutine.yield(nil)
	end

	item:ConsumeComplete()
end

-- 플레이어가 다른 이벤트를 진행중이라 ScreenplayState일 경우, 끝날 때 까지 기다리는 함수.
function local_class:waiting_for_interact()
	while lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
		coroutine.yield()
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
