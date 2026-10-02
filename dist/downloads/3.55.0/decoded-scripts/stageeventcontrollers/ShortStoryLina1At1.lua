local local_class = newclass("ShortStoryLina1At1")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.sections_need_on_launch = {
		0,
		3,
		5
	}

	-- 스테이지 이벤트 저장용 키
	self.stage_event_custom_keys = {
		zel_amel = 1,
		trio_boss = 2,
		trio_man = 3,
	}

	-- 스테이지 이벤트의 기본 세팅 값
	self.default_event_state_value = {
		number = 0,
		boolean = false
	}

	-- 스테이지 이벤트의 상태
	self.stage_event_state = {
		zel_amel = self.default_event_state_value.boolean,
		trio_boss = self.default_event_state_value.boolean,
		trio_man = self.default_event_state_value.boolean,
	}

	-- 카메라 크기 (Vector2)
	self.camera_scale = nil

	-- 재화 시스템 테이블
	self.gold_table = nil

	--region 제르가디스와 아멜리아
	self.get_amelia = function() return get_character('zel_amel_amelia') end
	self.get_zelgadis = function() return get_character('zel_amel_zelgadis') end
	self.get_dog = function() return get_character('zel_amel_dog') end

	self.get_zel_amel_center_pos = function() return field:GetMarker('zel_amel_center_pos').position end

	self.current_zel_amel_screenplay_index = 0
	self.zel_amel_screenplay_bounds = nil
	self.in_zel_amel_screenplay_zone = false

	self.zel_amel_event_state = {
		none = 0,
		screenplaying = 1,
		screenplay_stopped = 2,
		done = 3
	}
	self.current_zel_amel_event_state = self.zel_amel_event_state.none

	--endregion

	--region 트리오 이벤트
	self.get_trio_boss = function() return get_character('trio_boss') end
	self.get_trio_man = function() return get_character('trio_man') end
	self.get_man_npc = function(num) return get_character('trio_npc_' .. num) end
	self.get_believer = function(num) return get_character('trio_believer_' .. num) end

	self.is_seen_boss = false
	self.is_seen_man = false

	self.panda_brooch = nil

	self.trio_panda_event_zone_name = 'trio_panda_zone'

	self.trio_panda_crowd_buzz_sfx = nil
	--endregion

	--region 옷가게 이벤트
	self.get_clothing_npc = function() return get_character('cloth_seller') end
	self.get_costume_npc = function(num) return get_character('clothing_costume_' .. num) end

	self.get_costume_lina = function() return get_character('costume_lina') end
	self.get_costume_xellos = function() return get_character('costume_xellos') end
	self.get_costume_goury = function() return get_character('costume_goury') end
	self.get_origin_lina = function() return get_character('lina') end
	self.get_origin_xellos = function() return get_character('xellos') end
	self.get_origin_goury = function() return get_character('goury') end

	self.get_lina_costume_item = function() return get_field_object('costume_lina_item') end
	self.get_xellos_costume_item = function() return get_field_object('costume_xellos_item') end
	self.get_goury_costume_item = function() return get_field_object('costume_goury_item') end

	-- 옷가게 이벤트 상태
	self.clothing_state = {
		none = 0,
		changing_clothes = 1,	-- 옷을 갈아입으려 하는지
	}
	self.current_clothing_state = self.clothing_state.none

	self.current_clothes_storage_key = 'wearing_clothes'

	self.clothes_price = 3000

	self.costume_package_item_id = 20488

	self.costume_info_key = 'clothing_costume_'

	self.costume_infos = {
		[self.costume_info_key .. 1] = {
			nar_key = 'short_story_lina_clothing_costume_1',-- 인터랙트 시 나올 옷의 설명 나래이션 키값
			binary_exponent = 0,							-- 옷을 입고 있는지 여부를 저장하기 위한 2의 지수값
			party_index = 0,								-- 옷을 입는 파티원 인덱스
			get_exchange_member = self.get_costume_lina,	-- 변경될 파티 멤버 캐릭터를 가져오는 함수
			get_origin_member = self.get_origin_lina,		-- 오리지널 코스튬 멤버 가져오는 함수
			get_floating_item = self.get_lina_costume_item,	-- 플로팅 아이템 가져오는 함수 (itemid는 Behaviour 접근으로)
			item_name_key = 'lina_idol'						-- 구입 시에 나오는 선택지 정보
		},
		[self.costume_info_key .. 2] = {
			nar_key = 'short_story_lina_clothing_costume_2',
			binary_exponent = 1,
			party_index = 1,
			get_exchange_member = self.get_costume_goury,
			get_origin_member = self.get_origin_goury,
			get_floating_item = self.get_goury_costume_item,
			item_name_key = 'gourry_black'
		},
		[self.costume_info_key .. 3] = {
			nar_key = 'short_story_lina_clothing_costume_3',
			binary_exponent = 2,
			party_index = 2,
			get_exchange_member = self.get_costume_xellos,
			get_origin_member = self.get_origin_xellos,
			get_floating_item = self.get_xellos_costume_item,
			item_name_key = 'xellos_dress'
		},
	}

	--endregion

	self.bgm_state = {
		field = 0,
		cave = 1,
		lab = 2
	}
	self.current_bgm_state = self.bgm_state.field

	self.aircraft_sfx = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenedEvent), 'on_treasure_open_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	-- FIXME : 무조건 구독이 아닌 다른 이벤트 조건까지 종합해서 구독할지말지 판별하는 것으로 수정 필요
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_field_object_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()

	self.gold_table = get_or_create_global_table('stageeventcontrollers/ShortStoryLinaGold')
	yield_return_func(self.gold_table.load_resource, self.gold_table)
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local qp = user_progress:GetStartedQuest(7000801)

	-- pre section
	if qp == nil or qp.InnerProgress < 0 then
		return true
	elseif qp.IsComplete then
		return false
	else
		-- 1, 2, 4, 6  섹션
		for _, section in ipairs(self.sections_need_on_launch) do
			if qp.InnerProgress == section then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, typeof(CS.Oak.InteractEvent)) then
		if self.current_clothing_state == self.clothing_state.none and self.costume_infos[e.Target.Name] ~= nil then
			self.current_clothing_state = self.clothing_state.changing_clothes
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.interact_costume, self, e.Target))
			return true
		end
	end

	return false
end

function local_class:on_treasure_open_event(e)
	for i, chest in ipairs(self.treasures) do
		if lua_helper.reference_equals(e.Target, chest.fo) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.treasure_gold_drop, self, chest))
			return true
		end
	end

	return false
end

function local_class:treasure_gold_drop(data)
	local gold_table = get_or_create_global_table('stageeventcontrollers/ShortStoryLinaGold')
	wait_all({
		util.cs_generator(function()
			gold_table:add_dollar_async(data.amount, false, false)
			self:apply_custom_state_immediately(gold_table.main_quest_id, gold_table.dollar_data_key, gold_table:get_dollar())
		end),
	util.cs_generator(wait_for_sec, 2),
	})
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(gold_table.add_dollar_directing, gold_table, data.amount,
					{ pos = data.fo.Position, target_pos = user_party.Leader.Position }))
end

function local_class:on_stage_loaded_event(e)
	-- 스테이지에 존재하는 ExitInner 히트박스 조정

	get_field_object('slum_entrance').Hitbox = CS.Oak.Hitbox(vector(4, 1, 2))
	get_field_object('slum_exit').Hitbox = CS.Oak.Hitbox(vector(4, 1, 2))
	get_field_object('slum_entrance_B').Hitbox = CS.Oak.Hitbox(vector(2, 1, 4))
	get_field_object('slum_exit_B').Hitbox = CS.Oak.Hitbox(vector(4, 1, 2))

	-- 카메라 사이즈 받아옴
	self.camera_scale = screen_util.get_world_screen_size()

	-- 커스텀 키 받아와서 각 데이터 세팅해줌
	for name, key in pairs(self.stage_event_custom_keys) do
		if self.stage_event_state[name] == self.default_event_state_value.number then
			self.stage_event_state[name] = stage_progress_util.get_custom_data_int(
					key, self.default_event_state_value.number)
		else
			-- 저장될 타입에 대한 기본 데이터가 없는 경우 Boolean으로 간주
			self.stage_event_state[name] = stage_progress_util.get_custom_data(
					key, self.default_event_state_value.boolean)
		end
	end

	--region 골드 지급 보물상자 세팅

	self.treasures = {}
	local gold_amounts = {
		4000,
		4000,
		3000,
		3000,
	}

	for i = 1, 4 do
		local box = get_field_object('chest_fancy_' .. i)
		if box.FieldObjectBehaviour.IsOpened then
			box.Interactable = CS.Oak.NonInteractable.Instance
		end
		table.insert(self.treasures, {
			fo = box,
			amount = gold_amounts[i]
		})
	end

	--endregion

	--region 스테이지 이벤트의 세팅

	--region 제르가디스-아멜리아 이벤트
	-- 이벤트가 끝나지 않았다면
	if self.stage_event_state.zel_amel == self.default_event_state_value.boolean then
		self:set_zelgadis_amelia()
	else
		-- 이벤트 끝난 것으로 처리
		self.current_zel_amel_event_state = self.zel_amel_event_state.done
	end
	--endregion

	--region 트리오 이벤트
	if self.stage_event_state.trio_boss then
		self.is_seen_boss = true
		self:set_trio_boss_oneline()
	end

	if self.stage_event_state.trio_man then
		self.is_seen_man = true
		self:set_trio_man_oneline()
	end

	self.panda_brooch = drop_item_util.create_item(
			{itemid = 20478, notforinven = true, lootstate = 'dontfindlooter', sprscale = 0.4,
			 pos = get_character('trio_npc_5').Position + vector(-0.1,0,0), showoncharacter = true })
	--endregion

	--region 옷가게 이벤트
	local can_buy_clothes = false

	for key, info in pairs(self.costume_infos) do
		-- 기본 값이 New인 코스튬들에 대한 처리

		-- 키 값이 NPC 이름임
		local costume_npc = get_character(key)

		-- 마네킹에 인터랙트 가능하도록
		character_util.add_listener(costume_npc, self.cs_controller)

		-- 마네킹 세팅
		self:set_costume_npc(costume_npc)

		field_ui_manager:RemoveUI(costume_npc, CS.Oak.FieldUiType.CharacterStats)
	end

	--endregion
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'zel_amel_event_active') then
		if self.current_zel_amel_event_state == self.zel_amel_event_state.none then
			self:start_scene_zelgadis_amelia()
			return true
		end

	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'trio_boss_zone') and not self.is_seen_boss then
		self.is_seen_boss = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.trio_boss_event, self))

	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'trio_man_zone') and not self.is_seen_man then
		self.is_seen_man = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.trio_man_event, self))
	elseif self.current_bgm_state ~= self.bgm_state.field and type_util.is_zone_full_enter(e, get_party_leader(), 'field_area') then
		self.current_bgm_state = self.bgm_state.field
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			-- FIXME: 현재 단편집 스테이지 field bgm이 설정되어있지 않아 임시로 설정해놓음. 추후 수정해야 함.
			music_player_util.play_stage_music({ name = 'ondemand/castletown/audio:bgm_slayers_castletown', state = 'event' })
			music_player_util.set_stage_music_clip_async({ state = 'field', name = 'ondemand/castletown/audio:bgm_slayers_castletown' })
			if self.aircraft_sfx then
				self.aircraft_sfx:Stop()
				self.aircraft_sfx = nil
			end
		end))

		return true
	elseif self.current_bgm_state ~= self.bgm_state.cave and type_util.is_zone_full_enter(e, get_party_leader(), 'cave_area') then
		self.current_bgm_state = self.bgm_state.cave
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			music_player_util.play_stage_music({ name = 'bgm_cave_main', state = 'event' })
			music_player_util.set_stage_music_clip_async({ state = 'field', name = 'bgm_cave_main' })
			if self.aircraft_sfx then
				self.aircraft_sfx:Stop()
				self.aircraft_sfx = nil
			end
		end))

		return true
	elseif self.current_bgm_state ~= self.bgm_state.lab and type_util.is_zone_full_enter(e, get_party_leader(), 'lab_area') then
		self.current_bgm_state = self.bgm_state.lab_area
		music_player_util.play_stage_music({ state = 'muted' })
		self.aircraft_sfx = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01', loop = true, type_priority = 'event', player_priority = 'default' })
		return true
	elseif type_util.is_zone_full_enter(e, get_party_leader(), self.trio_panda_event_zone_name) and user_progress:GetStartedQuest(7000801) ~= nil then
		self.trio_panda_crowd_buzz_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_restaurant_01',
																	  play_pos = vector(-6.5, 0, 7), loop = true, type_priority = 'event',
																	  player_priority = 'default', fade_in_time = 0.7 })
		return true
	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'clothing_store') then
		music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), self.trio_panda_event_zone_name) then
		if self.trio_panda_crowd_buzz_sfx then
			self.trio_panda_crowd_buzz_sfx:FadeOut(0.7)
			self.trio_panda_crowd_buzz_sfx = nil
		end
		return true
	end

	return false
end

function local_class:on_move_field_object_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if self.current_zel_amel_event_state ~= self.zel_amel_event_state.done then
			local in_bounds = self.zel_amel_screenplay_bounds ~= nil
					and self.zel_amel_screenplay_bounds:Contains(get_party_leader().Position)

			-- 구역 경계를 넘은 경우
			if in_bounds ~= self.in_zel_amel_screenplay_zone then
				-- 다시 들어왔을 때
				if in_bounds and self.current_zel_amel_event_state == self.zel_amel_event_state.screenplay_stopped then
					-- 연출 끊겼던 부분부터 재시작함
					self:start_scene_zelgadis_amelia()
				end

				self.in_zel_amel_screenplay_zone = in_bounds

				return true
			end
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'stop_restaurant_sfx' then
		self:stop_restaurant_sfx()
		return true
	end

	if e:GetParamAt(0) == 'restart_restaurant_sfx' then
		self:restart_restaurant_sfx()
		return true
	end

	return false
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.camera_scale = nil
	self.zel_amel_screenplay_bounds = nil

	for key, _ in pairs(self.costume_infos) do
		local costume_npc = get_character(key)
		character_util.remove_relate_event(costume_npc, self.cs_controller)
	end
	self.costume_infos = nil

	if self.aircraft_sfx then
		self.aircraft_sfx:Stop()
		self.aircraft_sfx = nil
	end

	if self.trio_panda_crowd_buzz_sfx then
		self.trio_panda_crowd_buzz_sfx:Stop()
		self.trio_panda_crowd_buzz_sfx = nil
	end

	if self.amelia_loop_sfx then
		self.amelia_loop_sfx:Stop()
		self.amelia_loop_sfx = nil
	end

	self.cs_controller = nil
	self.scene = nil

	if self.panda_brooch ~= nil then
		self.panda_brooch:ConsumeComplete()
	end

	self.gold_table = nil
end

function local_class:set_stage_event_state(name, value)
	-- 동기화시킴
	stage_progress_util.set_custom_data(self.stage_event_custom_keys[name], value)
	self.stage_event_state[name] = value
end

--region 제르가디스와 아멜리아 이벤트
function local_class:set_zelgadis_amelia()
	local amelia = self.get_amelia()
	local zelgadis = self.get_zelgadis()
	local dog = self.get_dog()
	local center_pos = self.get_zel_amel_center_pos()

	--짐수레 오브젝트 옆에 배치. 각기 짐수레 방향을 바라보며 eat 모션 중인 제르가디스, 아멜리아.
	amelia.ActiveState = active_state('enabled')
	amelia.Position = center_pos + vector(-1.8, 0, 0)
	amelia.Direction = CS.Oak.Direction.Right
	field_ui_manager:RemoveUI(amelia, CS.Oak.FieldUiType.CharacterStats)
	character_util.set_anim(amelia, {name = 'eat'})

	zelgadis.ActiveState = active_state('enabled')
	zelgadis.Position = center_pos + vector(1.8, 0, 0)
	zelgadis.Direction = CS.Oak.Direction.Left
	field_ui_manager:RemoveUI(zelgadis, CS.Oak.FieldUiType.CharacterStats)
	character_util.set_anim(zelgadis, {name = 'eat'})

	character_util.spine_set_alpha_fade(dog, 0, 0)
	field_ui_manager:RemoveUI(dog, CS.Oak.FieldUiType.CharacterStats)
	dog.ActiveState = active_state('disabled')

	-- 이벤트 진행하는 구역이 대략 5x3정도 되니 연출이 보이는 한계점으로 바운더리 세팅함
	self.zel_amel_screenplay_bounds = CS.UnityEngine.Bounds(center_pos,
			vector(self.camera_scale.x + 5, 3, self.camera_scale.y + 3))

	-- 원하는 그리드 데이터 가져오려면 빡세서 마커 하나 찍어두기로함
	self.zel_amel_screenplay_bounds.max = vector_util.get_0yz(
			self.zel_amel_screenplay_bounds.max, field:GetMarker('zel_amel_grid_x').position.x)
end

function local_class:start_scene_zelgadis_amelia()
	self.current_zel_amel_event_state = self.zel_amel_event_state.screenplaying

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.scene_zelgadis_amelia, self))
end

function local_class:scene_zelgadis_amelia()
	local amelia = self.get_amelia()
	local zelgadis = self.get_zelgadis()
	local dog = self.get_dog()
	local center_pos = self.get_zel_amel_center_pos()
	-- FIXME : 실제 오브젝트 나오면 다시 세팅해야됨
	local center_top_pos = center_pos + vector(0.2, 1.55, 0)

	local shake_min_dist = 5
	local shake_max_dist = 8

	if self.current_zel_amel_screenplay_index == 0 then
		--트리거 존 입장 시 자동 이벤트 시작. 두 사람이 각자 동작을 반복하며 가벼운 대화 나누도록 진행.

		local bubble_dir = 'lt'
		if get_party_leader().Position.x > center_pos.x then
			bubble_dir = 'rb'
		end

		if not self.amelia_loop_sfx then
			self.amelia_loop_sfx = music_player_util.play_sfx(
				{ sfx_name = '03_equipping_01', loop = true, play_pos = center_pos,
				  type_priority = 'event', player_priority = 'npc' })
		end
		--아멜리아 (right, idle, eat) : 제르가디스 오빠~ 그쪽은 어떤가요~
		speech_bubble_util.show_speech_bubble_async(amelia,
				{key = 'short_story_lina_zel_amel_1', bubble_direction = bubble_dir})

		--제르가디스 (left, idle, eat) : …아무것도 보이지 않아.
		speech_bubble_util.show_speech_bubble_async(zelgadis, 'short_story_lina_zel_amel_2')

		if self.amelia_loop_sfx then
			self.amelia_loop_sfx:Stop()
			self.amelia_loop_sfx = nil
		end
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		--아멜리아 (right, tired, question) : 의뢰인은 이곳으로 도망쳤다고 했지만요…
		character_util.set_emotion(amelia, {name = 'tired'})
		character_util.set_anim(amelia, {name = 'question', loop = false})
		speech_bubble_util.show_speech_bubble_async(amelia, 'short_story_lina_zel_amel_3')

		--제르가디스 (left, idle, eat) : 싱거운 일이지만, 주인이 상당한 부자로 보이니 분명 괜찮은 보상을…
		speech_bubble_util.show_speech_bubble_async(zelgadis, 'short_story_lina_zel_amel_4')

		self.current_zel_amel_screenplay_index = 1

		if self.in_zel_amel_screenplay_zone == false then
			self.current_zel_amel_event_state = self.zel_amel_event_state.screenplay_stopped
			return
		end
	end

	if self.current_zel_amel_screenplay_index == 1 then
		--짐수레 뒤에서 dog_corgi 등장.
		--강아지 짐수레 오브젝트에서부터 up으로 나타난 뒤 해당 위치에 정렬.
		dog.Position = center_pos + vector(0, -0.5, 0.5)
		dog.Direction = CS.Oak.Direction.Up
		dog.ActiveState = active_state('enabled')
		dog.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		character_util.spine_set_alpha_fade(dog, 1, 1.7)
		wp_util.move_way_points_async(dog, {waypoints = center_pos + vector(0, 0, 1), speed = 0.5})

		music_player_util.play_sfx({ sfx_name = '01_grass_slide_02', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		wp_util.move_way_points_async(dog, {waypoints = center_pos + vector(0, 0, 1.5), speed = 1})

		--이후 right, jump를 실행하여 해당 지점에 안착.
		dog.Direction = CS.Oak.Direction.Down
		music_player_util.play_sfx({ sfx_name = '01_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.jump(dog, 1.2, 0.5)
		character_util.move_to_async(dog, center_top_pos, 0.5)
		dog.Direction = CS.Oak.Direction.Right

		--이후 right, idle, victory 1회 실행.
		music_player_util.play_sfx({ sfx_name = '01_pet_bark_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_animation_n_times_async(dog, {name = 'victory'})

		--이후 아멜리아, 제르가디스 일제히 강아지 방향을 바라봄.
		music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.remove_anim_and_emotion(amelia)
		character_util.remove_anim_and_emotion(zelgadis)

		wait_for_sec(0.5)

		character_util.set_emotion(amelia, {name = 'attack'})
		character_util.set_emotion(zelgadis, {name = 'attack'})
		character_util.normal_jump(amelia)
		character_util.normal_jump_async(zelgadis, '01_player_jump_01')

		wait_for_sec(0.3)

		--아멜리아 (right, attack, idle) : 제르가디스 오빠!
		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		dog.Direction = CS.Oak.Direction.Left
		speech_bubble_util.show_speech_bubble_async(amelia, 'short_story_lina_zel_amel_5')

		--아멜리아 (right, attack, jump 1회) : 짧은 다리에 주황빛 털… 저 녀석이 분명해요!
		character_util.play_speech_action(amelia, {name = 'release', sfx_name = '01_swing_01'},
				nil, {key = 'short_story_lina_zel_amel_6'})

		self.current_zel_amel_screenplay_index = 2

		if self.in_zel_amel_screenplay_zone == false then
			self.current_zel_amel_event_state = self.zel_amel_event_state.screenplay_stopped
			return
		end
	end

	if self.current_zel_amel_screenplay_index == 2 then

		--제르가디스 (left, attack, idle) : 얼른 잡아!
		music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		dog.Direction = CS.Oak.Direction.Right
		speech_bubble_util.show_speech_bubble_async(zelgadis, 'short_story_lina_zel_amel_7')

		-- 뒤로 한발자국 물러남
		character_util.move_to_async(zelgadis, zelgadis.Position + vector(0.5, 0, 0),
				0.5, nil, false, true)

		music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(zelgadis, {name = 'boong_attack_ready', loop = false})

		wait_for_sec(0.5)

		--연출 참조 : https://youtu.be/6uByejvDkSs?t=657
		--상단 제르가디스의 대사가 종료되면, left, attack, prostrate 자세로 짐수레 위로 뛰어드는 제르가디스.
		music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(zelgadis, {name = 'prostrate', mix_duration = 0.5})
		character_util.jump(zelgadis, 1, 0.4)
		character_util.move_to_async(zelgadis,
				zelgadis.Position + (center_top_pos - zelgadis.Position) * 0.25, 0.1)

		music_player_util.play_sfx({ sfx_name = '01_player_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		dog.LockedDirection = dog.Direction
		character_util.jump(dog, 2, 0.5)
		--이때 제르가디스가 오브젝트에 도착하는 타이밍에 맞춰 강아지 제자리에서 left, idle, jump.
		wp_util.move_way_points(dog, {waypoints = dog.Position + vector(0, 0.35, 0),
									  speed = 0.35 / 0.5, last_direction = CS.Oak.Direction.Right})

		--제르가디스 attack, prostrate 자세로 오브젝트 위에 착지.
		character_util.move_to_async(zelgadis, center_top_pos, 0.3)
		wait_for_sec(0.2)

		--이후 강아지 그대로 낙하하며 제르가디스 몸통 위로 착지.

		-- 제르가디스에게 피격 이펙트 출력하고
		music_player_util.play_sfx({ sfx_name = '01_hit_comic_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '01_land_03', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.spine_damage_squish_default(zelgadis)
		character_util.spine_damage_red_pulse(zelgadis)
		character_util.set_emotion(zelgadis, {name = 'damaged'})
		self:custom_camera_shake(0.2, 0.1,
				shake_min_dist, shake_max_dist, 0.2, center_pos)
		wait_for_sec(0.5)

		dog.LockedDirection = CS.Oak.Direction.None

		--제르가디스 (left, damaged, prostrate) : 크읏…!
		character_util.shake(zelgadis, 0.025, 1)

		self.current_zel_amel_screenplay_index = 3

		if self.in_zel_amel_screenplay_zone == false then
			self.current_zel_amel_event_state = self.zel_amel_event_state.screenplay_stopped
			return
		end
	end

	if self.current_zel_amel_screenplay_index == 3 then
		-- 뒤로 한발자국 물러남
		character_util.move_to_async(amelia, amelia.Position + vector(-0.5, 0, 0),
				0.5, nil, false, true)

		--아멜리아 (right, attack, prostrate)
		music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		dog.Direction = CS.Oak.Direction.Left
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(amelia, {name = 'boong_attack_ready', loop = false})
		wait_for_sec(0.5)

		--상단 대사와 함께 아멜리아도 동일하게 right, attack, prostrate 자세로 짐수레 위로 뛰어듬.
		music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(amelia, {name = 'prostrate', mix_duration = 0.5})
		character_util.jump(amelia, 1, 0.4)
		--이때 도착 지점은 제르가디스 캐릭터의 몸통 위로 포개도록 진행.
		character_util.move_to_async(amelia, amelia.Position
				+ (center_top_pos + vector(0, 0.35, 0) - amelia.Position) * 0.25, 0.1)

		dog.LockedDirection = dog.Direction
		music_player_util.play_sfx({ sfx_name = '01_player_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.jump(dog, 2, 0.5)

		--이때 아멜리아가 오브젝트에 도착하는 타이밍에 맞춰 강아지 제자리에서 left, idle, jump.
		wp_util.move_way_points(dog, {waypoints = dog.Position + vector(0, 0.35, 0),
									  speed = 0.35 / 0.5, last_direction = CS.Oak.Direction.Left})

		--아멜리아 attack, prostrate 자세로 제르가디스 위에 착지.
		character_util.move_to_async(amelia, center_top_pos + vector(0, 0.35, 0), 0.3)
		self:custom_camera_shake(0.2, 0.1,
				shake_min_dist, shake_max_dist, 0.2, center_pos)
		wait_for_sec(0.2)

		self:custom_camera_shake(0.2, 0.1,
				shake_min_dist, shake_max_dist, 0.3, center_pos)

		--이후 강아지 그대로 낙하하며 아멜리아 몸통 위로 착지.
		--아멜리아 (right, damaged, prostrate) : 꺅!
		--상단 대사와 함께 아멜리아를 발로 딛으면 제르가디스, 아멜리아 모두에게 피격 이펙트 출력하고, 아멜리아 표정 damaged으로 변경.
		music_player_util.play_sfx({ sfx_name = '01_hit_comic_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '01_land_03', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_emotion(amelia, {name = 'damaged'})
		character_util.spine_damage_squish_default(zelgadis)
		character_util.spine_damage_red_pulse(zelgadis)
		character_util.spine_damage_squish_default(amelia)
		character_util.spine_damage_red_pulse(amelia)

		wait_for_sec(1)

		dog.LockedDirection = CS.Oak.Direction.None
		self.current_zel_amel_screenplay_index = 4

		if self.in_zel_amel_screenplay_zone == false then
			self.current_zel_amel_event_state = self.zel_amel_event_state.screenplay_stopped
			return
		end
	end

	if self.current_zel_amel_screenplay_index == 4 then
		--강아지 left, idle, jump로 오브젝트 좌측으로 이동.
		music_player_util.play_sfx({ sfx_name = '01_small_jump_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.jump(dog, 0.6, 0.45)
		character_util.move_to_async(dog, center_top_pos + vector(-1, 0, 0), 0.45)

		--이후 right, doyagao, victory_extra 1회 실행.
		dog.Direction = CS.Oak.Direction.Right
		music_player_util.play_sfx({ sfx_name = '01_pet_ordinary_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		character_util.set_emotion(dog, {name = 'doyagao'})
		character_util.set_animation_n_times_async(dog, {name = 'victory'})

		--이후 제르가디스, 아멜리아 shake 상태로 하단 대사 실행.
		character_util.shake(zelgadis, 0.02, 999)
		character_util.shake(amelia, 0.02, 999)
		character_util.set_emotion(zelgadis, {name = 'attack'})
		character_util.set_emotion(amelia, {name = 'attack'})

		--제르가디스 (left, attack, prostrate, shake 진행) : 저 자식이…!
		music_player_util.play_sfx({ sfx_name = '03_dialogue_angry_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		speech_bubble_util.show_speech_bubble_async(zelgadis,
				{key = 'short_story_lina_zel_amel_11', bubble_direction = 'lb',
				 type_speed = 0.03, life_time = 1.5})

		--아멜리아 (right, attack, prostrate, shake 진행) : 으으…!
		music_player_util.play_sfx({ sfx_name = '03_runaway_01', play_pos = center_pos,
									 type_priority = 'event', player_priority = 'npc' })
		speech_bubble_util.show_speech_bubble_async(amelia,
				{key = 'short_story_lina_zel_amel_12', bubble_direction = 'rt',
				 type_speed = 0.03, life_time = 1.5})
		character_util.stop_shake(zelgadis)
		character_util.stop_shake(amelia)

		self.current_zel_amel_screenplay_index = 5

		if self.in_zel_amel_screenplay_zone == false then
			self.current_zel_amel_event_state = self.zel_amel_event_state.screenplay_stopped
			return
		end
	end

	--강아지 right, attack, bark 2회 실행.
	music_player_util.play_sfx({ sfx_name = '01_pet_grr_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.remove_emotion(dog)
	character_util.set_emotion(dog, {name = 'attack'})
	character_util.set_animation_n_times_async(dog, {name = 'bark', count = 2})
	character_util.remove_emotion(dog)

	amelia.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	zelgadis.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	--아멜리아 기상.
	music_player_util.play_sfx({ sfx_name = '01_player_popup_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(amelia, {name = 'mad'})
	character_util.remove_anim(amelia)
	character_util.mario_jump_async(amelia, 'right')

	wait_for_sec(0.1)

	--아멜리아 (left, mad, jump) : 놓치지 않겠어요!!!
	music_player_util.play_sfx({ sfx_name = '01_swing_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	amelia.Direction = CS.Oak.Direction.Left
	speech_bubble_util.show_speech_bubble_async(amelia,
			{key = 'short_story_lina_zel_amel_13', type_speed = 0.03, life_time = 1.3})

	--강아지는 left, idle, jump로 오브젝트 아래로 내려간다.
	character_util.jump_move(dog, center_pos + vector(-2.5, 0, 0),
			(center_pos + vector(-2.5, 0, 0) - dog.Position).magnitude / 0.4,
			1, false, 'right')

	--이후 상단 대사와 함께 left, mad, jump로 강아지를 향해 달려들고,
	music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.spine_damage_squish_default(zelgadis)
	character_util.spine_damage_red_pulse(zelgadis)

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.jump(amelia, 1, 0.3)
	character_util.move_to_async(amelia, dog.Position, 0.3)

	wait_for_sec(0.2)


	local jump_and_run = function(fo, jump_pos, end_z_pos, jump_dur, jump_height, cb, dash_sfx)
		if jump_pos then
			music_player_util.play_sfx({ sfx_name = '01_jump_01', play_pos = center_pos,
										 type_priority = 'event', player_priority = 'npc' })
			character_util.jump(fo, jump_height, jump_dur)
			wp_util.move_way_points_async(fo,
					{waypoints = jump_pos, speed = (fo.Position - jump_pos).magnitude / jump_dur})
		end

		if cb then
			cb()
		end

		wp_util.move_way_points_async(fo,
				{ waypoints = vector(fo.Position.x, 0, end_z_pos - 2.5),
				 speed = 5, run = true, play_sfx = dash_sfx })

		character_util.spine_set_alpha_fade(fo, 0, 0.5)

		wp_util.move_way_points_async(fo,
				{ waypoints = vector(fo.Position.x, 0, end_z_pos),
				 speed = 5, run = true, play_sfx = dash_sfx })

		character_util.remove_anim_and_emotion(fo)
		fo.ActiveState = active_state('disabled')

		speech_bubble_util.remove_bubble(fo)
	end

	--강아지는 up 방향으로 달려가며 사라진다.
	music_player_util.play_sfx({ sfx_name = '01_pet_bark_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(jump_and_run, dog, nil, 100))

	wait_for_sec(0.3)

	--아멜리아는 강아지를 따라 left, mad, jump
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(jump_and_run, amelia, center_pos + vector(-3, 0, 0), 100, 0.45, 0.6, nil, true))

	--제르가디스 기상.
	music_player_util.play_sfx({ sfx_name = '01_player_popup_01', play_pos = center_pos,
								 type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(zelgadis, {name = 'mad'})
	character_util.remove_anim(zelgadis)
	character_util.mario_jump_async(zelgadis, 'left')

	wait_for_sec(0.15)

	--이후 상단 대사와 함께 left, mad, jump로 아멜리아의 뒤를 따라 점프한다.
	jump_and_run(zelgadis, center_pos + vector(-2, 0, 0),
			100, 0.45, 1, function()
				music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', play_pos = center_pos,
											 type_priority = 'event', player_priority = 'npc' })
				--제르가디스 (left, mad, idle) : 거기 서!!!
				speech_bubble_util.show_speech_bubble(zelgadis,
						{key = 'short_story_lina_zel_amel_14', type_speed = 0})
			end, true)

	--이후 그대로 강아지가 이동한 방향을 따라 움직이며 사라지는 두사람.

	--이벤트 종료.
	self:set_stage_event_state('zel_amel', true)
	self.current_zel_amel_event_state = self.zel_amel_event_state.done
end

--- @param screenplay_pos any 연출이 실행되는 위치
function local_class:custom_camera_shake(max_mag, min_mag, min_dist, max_dist, duration, screenplay_pos)
	local camera_pos = stage_camera.Transform.parent.position
	local dist_to_center = (screenplay_pos - camera_pos).magnitude

	if dist_to_center <= min_dist then
		camera_util.shake(max_mag, duration, true)
	elseif dist_to_center <= max_dist then
		local weight = (dist_to_center - min_dist) / (max_dist - min_dist)

		camera_util.shake(max_mag * (1 - weight) + min_mag * weight, duration, true)
	end

	-- max_dist 이상인 경우 (충분히 먼 경우) 셰이크 안넣음
end

--endregion

--region 트리오 이벤트
function local_class:trio_boss_event()
	local believer = self.get_believer(1)
	local boss = self.get_trio_boss()

	-- …오늘도 자매들과 싸움이 있었다는 소식이 들려왔습니다.
	speech_bubble_util.show_speech_bubble_async(believer, { key = 'short_story_lina_trio_1' })
	character_util.set_emotion(believer, { name = 'tired' })
	-- 당신을 원망하지는 않습니다. 다만 신께 은혜를 입고 계시는 분이시라면…
	speech_bubble_util.show_speech_bubble_async(believer, { key = 'short_story_lina_trio_2' })
	-- …모두를 사랑하는 마음을 가져주세요.
	character_util.set_emotion(believer, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(believer, { key = 'short_story_lina_trio_3' })

	character_util.set_emotion(boss, { name = 'attack' })
	-- …그, 그렇지만 싸움을 건 것은 저쪽…
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = boss, type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(boss, { key = 'short_story_lina_trio_4' })

	character_util.move_to_async(believer, believer.Position + vector(-0.5,0,0), 0.5,
			nil, true, true)
	character_util.set_anim(believer, { name = 'push' })

	wait_for_sec(0.2)
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = boss, type_priority = 'event', player_priority = 'npc' })
	character_util.shake(boss, 0.04, 0.5)
	wait_for_sec(1)
	character_util.set_emotion(boss, { name = 'tired' })
	wait_for_sec(0.5)

	-- 괜찮습니다. 프로메테이아님은 반성하는 이에겐 모두 자비를 베푸십니다.
	speech_bubble_util.show_speech_bubble_async(believer, { key = 'short_story_lina_trio_5' })
	-- …….
	speech_bubble_util.show_speech_bubble_async(boss, { key = 'short_story_lina_trio_6' })

	self:set_trio_boss_oneline()
	self:set_stage_event_state('trio_boss', true)
end

function local_class:trio_man_event()
	-- 역시 대니얼 도련님… 너무 멋있으셔…!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', parent = self.get_man_npc(1), type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(self.get_man_npc(1), { key = 'short_story_lina_trio_9' })
	-- 저 빛나는 은발… 가문의 적통에서만 나타난다며…?!
	speech_bubble_util.show_speech_bubble_async(self.get_man_npc(2), { key = 'short_story_lina_trio_10' })
	-- 이번에는 왕립 대학 조기 입학까지 하셨대!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = self.get_man_npc(3), type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(self.get_man_npc(3), { key = 'short_story_lina_trio_11' })
	-- 역시 대니얼 도련님! 다른 도련님들과는 격이 다르시다니까!
	speech_bubble_util.show_speech_bubble_async(self.get_man_npc(4), { key = 'short_story_lina_trio_12' })

	music_player_util.play_sfx({ sfx_name = '01_gatcha_point_01', parent = self.get_trio_man(), type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(self.get_trio_man(), { name = 'doyagao' })

	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_05', parent = self.get_man_npc(1), type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', parent = self.get_man_npc(1), type_priority = 'event', player_priority = 'npc' })
	for i = 1, 4 do
		local npc = self.get_man_npc(i)
		character_util.set_anim_and_emotion(npc, { name = 'cast' }, { name = 'love'})
		character_util.normal_jump(npc)
	end
	wait_for_sec(0.5)
	self:set_trio_man_oneline()
	self:set_stage_event_state('trio_man', true)
end

function local_class:set_trio_boss_oneline()
	self.get_believer(1).Interactable.Talk = 'short_story_lina_trio_5'
	self.get_trio_boss().Interactable.Talk = 'short_story_lina_trio_6'
	self.get_believer(2).Interactable.Talk = 'short_story_lina_trio_7'
	self.get_believer(2).Interactable.TalkSfx = '03_dialogue_tipsy_01'
	self.get_believer(3).Interactable.Talk = 'short_story_lina_trio_8'
end

function local_class:set_trio_man_oneline()
	local first_text_num = 8
	for i = 1, 4 do
		self.get_man_npc(i).Interactable.Talk = 'short_story_lina_trio_' .. (first_text_num + i)
	end
end
--endregion

--region 옷가게 이벤트
function local_class:set_costume_npc(fo)
	character_util.remove_anim_and_emotion(fo)

	fo.ActiveState = active_state('enabled')
	fo.Direction = CS.Oak.Direction.Down
	character_util.set_emotion(fo, {name = 'empty'})
	character_util.set_anim(fo, {name = 'idle', scale = 0})
	fo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
end

-- 현재 해당 코스튬을 가지고 있는지
function local_class:has_costume(costume_info)
	return user:HasItem(self:get_costume_item_id(costume_info))
end

-- 해당 코스튬의 아이템 아이디 가져옴
function local_class:get_costume_item_id(costume_info)
	local floating_item = costume_info.get_floating_item()
	return floating_item.FieldObjectBehaviour.Item.ItemId
end

function local_class:interact_costume(costume_npc)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local costume_key = costume_npc.Name
	local costume_info = self.costume_infos[costume_key]
	local target_member_index = costume_info.party_index
	local is_leader = target_member_index == 0
	local is_wearing_original = self.gold_table:is_original_costume(target_member_index)

	party_util.align_to_target(costume_npc, 'down', 1, 'linear')

	if not self:has_costume(costume_info) then
		--코스츔에 대한 대사 나레이션 박스가 나오고
		field_ui_util.show_narration_async({key = costume_info.nar_key})

		--	--구입한다. (3000G)
		--	--그만 둔다.
		local result = choose_util.play_choose_event({
			{game_string:Format('short_story_lina_buy_costume_1', self.clothes_price), 'mercy'},
			{'short_story_lina_buy_costume_2', 'normal'},
		})

		if result == 2 then
			party_util.reset_controllers()
			field_ui_manager:Show()

			self.current_clothing_state = self.clothing_state.none
			return
		elseif self.gold_table:get_dollar() < self.clothes_price then
			--소지금이 부족할 때,
			--구입한다 선택지 선택 후 소지금이 부족하면 나레이션 박스 출력.
			--소지금이 부족해 구입할 수 없다.
			music_player_util.play_sfx_one_shot('01_hit_comic_01')
			field_ui_util.show_narration_async({key = 'short_story_lina_clothing_not_enough'})

			party_util.reset_controllers()
			field_ui_manager:Show()

			self.current_clothing_state = self.clothing_state.none
			return
		end

		--region 서버에 아이템 및 재화 저장
		local floating_item = costume_info.get_floating_item()
		local clone = create_generic_dictionary(CS.System.String, CS.System.Int32)

		-- 아이템 얻을 때 지불한 돈도 같이 저장함 (동기화 목적)
		clone:Add('gold_collect', self.gold_table:change_dollar_immediately(-self.clothes_price))

		-- 기존에 저장된 커스텀 스테이트도 복사함
		for k,v in pairs(self.gold_table:get_quest_progress().CustomStates) do
			-- 먼저 추가된 값이 우선순위가 더 높기 때문에 먼저 저장된 같은 키가 있는 경우 무시함
			if not clone:ContainsKey(k) then
				clone:Add(k, v)
			end
		end

		local stage_custom = CS.Oak.StageCustom()
		-- 데이터 스토리지 퀘스트 아이디
		stage_custom.QuestId = self.gold_table.main_quest_id
		stage_custom.QuestCustomState = clone

		local wait = true

		-- 아이템 얻도록 함
		stage:SendPickStageItem(floating_item.Name, stage_custom, function(data)
			local has_value, value = data:TryGetValue('AddedItem')
			local added_item = value

			if added_item ~= nil then
				CS.Oak.StageProgress.Current:AddItem(floating_item.KeyIndex)

				has_value, value = added_item:TryGetValue('Id')
				local item_id = value

				has_value, value = user.Items:TryGetValue(item_id)
				if has_value then
					CS.Oak.AddItemStageLogic.Execute(value, get_party_leader())
				end
			end

			wait = false
		end)

		--endregion

		-- 코스튬 패키지 던져줌
		local package = drop_item_util.create_item(
				{itemid = self:get_costume_item_id(costume_info),
				 pos = costume_npc.Position + vector(0, 0.3, -0.2),
				 target = get_party_leader().Position + vector(0, 0, 0.5),
				 notforinven = true, lootstate = 'FixLooter', skip_text = true})

		package.ConsumeTarget = get_party_leader()

		music_player_util.play_sfx_one_shot('01_throw_01')
		music_player_util.play_sfx_one_shot('01_gatcha_box_01')

		wait_for_sec(0.9)

		--아이템 명 플로팅 텍스트
		CS.Oak.FieldUIFloatingText.Get(get_party_leader())
		  :JustPrintItemName(game_string:GetString(costume_info.item_name_key), 0)

		wait_for_sec(0.8)

		-- 만약 아직도 안끝났다면 NetworkRequest가 끝날때까지 기다림
		while wait do
			coroutine.yield()
		end
	end

	--선택지 출력.
	if is_wearing_original then
		--의상 구입 후 마네킹 상호 작용하면
		--구입한 의상으로 갈아입는다.
		--그만 둔다.
		local result = choose_util.play_choose_event({
			{'short_story_lina_clothing_branch_1', 'mercy'},
			{'short_story_lina_clothing_branch_3', 'normal'}
		})

		if result == 2 then
			self.current_clothing_state = self.clothing_state.none
			party_util.reset_controllers()
			field_ui_manager:Show()
			return
		end

		--페이드 아웃
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		-- 옷 정보 세팅
		local changed_wear_binary = 2 ^ target_member_index
		local wearing_binary = self.gold_table:get_wearing_binary()

		-- 1로 비트플래그 전환
		wearing_binary = wearing_binary | changed_wear_binary

		self.gold_table:set_custom_data_async(self.current_clothes_storage_key, wearing_binary)
	else
		--구입한 옷 착용 상태로 마네킹 상호 작용하면 선택지 출력.
		--원래 의상으로 갈아입는다.
		--그만 둔다.
		local result = choose_util.play_choose_event({
			{'short_story_lina_clothing_branch_2', 'mercy'},
			{'short_story_lina_clothing_branch_3', 'normal'}
		})

		if result == 2 then
			self.current_clothing_state = self.clothing_state.none
			party_util.reset_controllers()
			field_ui_manager:Show()
			return
		end

		--페이드 아웃/인
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		-- 옷 정보 세팅
		local changed_wear_binary = 2 ^ target_member_index
		local wearing_binary = self.gold_table:get_wearing_binary()

		-- 0으로 비트플래그 전환
		wearing_binary = wearing_binary & (~changed_wear_binary)

		self.gold_table:set_custom_data_async(self.current_clothes_storage_key, wearing_binary)
	end

	--의상 바뀐 채 다시 파티 합류.
	-- FIXME : 가우리와 제로스의 파티 인덱스는 고정되어있는 것으로 가정하고 넣었으나, 문제가 되는 경우에는 접근 방식을 바꿔야 함
	local excluding_member = user_party[target_member_index]
	local including_member = is_wearing_original
			and costume_info.get_exchange_member() or costume_info.get_origin_member()

	including_member.Direction = excluding_member.Direction
	including_member.Position = excluding_member.Position
	including_member.ActiveState = active_state('enabled')

	local maintain_members = {}

	-- 뒤에서부터 파티 멤버 빼줌 (갈아입을 멤버 인덱스까지)
	for i = user_party.Count - 1, target_member_index, -1 do
		local member = user_party[i]
		character_util.convert_to_npc(member)

		table.insert(maintain_members, member)
	end

	if is_leader then
		-- 리나가 갈아입는 경우
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		param.KeepParty = false
		character_util.convert_to_manual_character(including_member, param, true)

		-- 중복해서 파티에 들어가는 걸 막기 위해 마지막 값을 비워줌
		maintain_members[#maintain_members] = nil
	else
		-- 마지막 캐릭터를 옷이 바뀐 캐릭터로 변경
		maintain_members[#maintain_members] = including_member
	end

	for i = #maintain_members, 1, -1 do
		character_util.convert_to_party_member(maintain_members[i], user_party, true)
	end

	excluding_member.ActiveState = active_state('disabled')

	-- 리더가 바뀐 경우 인터랙트 링이 보여서 다시 리셋시켜줌
	party_util.stop_and_disable_control()

	camera_util.return_to_leader(0)

	coroutine.yield()

	if is_wearing_original then
		music_player_util.play_sfx_one_shot('03_equip_finish_01')
	else
		music_player_util.play_sfx_one_shot('02_costume_equip_01')
	end

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	--2스테이지와 연계되지 않음.

	party_util.reset_controllers()
	field_ui_manager:Show()

	self.current_clothing_state = self.clothing_state.none
end

--endregion

function local_class:stop_restaurant_sfx()
	if self.trio_panda_crowd_buzz_sfx then
		self.trio_panda_crowd_buzz_sfx:FadeOut(1)
		self.trio_panda_crowd_buzz_sfx = nil
	end
end

function local_class:restart_restaurant_sfx()
	if not self.trio_panda_crowd_buzz_sfx then
		self.trio_panda_crowd_buzz_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_amb_restaurant_01', play_pos = vector(-6.5, 0, 7),
			  loop = true, type_priority = 'event', player_priority = 'default', fade_in_time = 2 })
	end
end


-- 스테이지 나가지 않아도 커스텀 스테이트가 바로 저장 되도록 하기
function local_class:apply_custom_state_immediately(quest_id, key_name, val)
	local quest_progress = user_progress:GetStartedQuest(quest_id)
	local save_success = true
	local on_success = function (res)
		save_success = true
	end

	-- 먼저 custom state 를 set 한다.
	local fail_count = 0
	while true do
		local r = CS.Oak.IQuestEventControllerExtensions.SetCustomState(nil, quest_progress, key_name, val)
		coroutine.yield(r)
		coroutine.yield(nil)
		-- on_error 콜백을 안받아서 CustomState 가 실제로 변경되었는지로 체크해야 한다..
		save_success = true

		if quest_progress:GetCustomState(key_name) ~= val then
			save_success = false
		end

		if not save_success then
			fail_count = fail_count + 1
			CS.UnityEngine.Debug.LogError("ShortStoryLina1At1 : SetCustomState Retry")
			wait_for_sec(5.0 + fail_count)
		else
			break
		end
	end

	fail_count = 0
	while true do
		save_success = false
		local r = CS.Oak.NetworkManager.ApiConnection:SendProgressQuest(stage.StageId, quest_progress.QuestId, quest_progress.InnerProgress, nil)
		r:Then(on_success)
		coroutine.yield(r:SuppressDefaultErrorHandler())
		coroutine.yield(nil)
		if not save_success then
			fail_count = fail_count + 1
			CS.UnityEngine.Debug.LogError("ShortStoryLina1At1 : SendProgressQuest Retry")
			wait_for_sec(5.0 + fail_count)
		else
			break
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
