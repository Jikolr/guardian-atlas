local local_class = newclass('ShortStorySlimeController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 7001701

	self.village_construction = nil

	self.scene_version = scene_util.default_version

	-- 환금 아이템 구매 npc 리스트
	self.buyer_npc = {
		['forge'] = {
			npc = function() return get_character('vc_buyer_forge') end,
			interact_func = self.interact_forge_buyer,
			is_active = false,
			custom_sprite = 'hammer',
			emotion = nil,
			activate_type = 'quest',
			value = 5,
			item_sprite_p2w = 0.0125,
		},
		['potion_store'] = {
			npc = function() return get_character('vc_buyer_potion_store') end,
			interact_func = self.interact_potion_store_buyer,
			is_active = false,
			custom_sprite = 'stick',
			emotion = nil,
			activate_type = 'sub_quest_clear',
			value = 7001707,
			item_sprite_p2w = 0.013,
		},
		['hot_spring'] = {
			npc = function() return get_character('vc_buyer_spa') end,
			interact_func = self.interact_hot_spring_buyer,
			is_active = false,
			custom_sprite = 'pickaxe',
			emotion = nil,
			activate_type = 'none',
			item_sprite_p2w = 0.0175,
			oneline_npc_list = {
				'vc_spa_oneline_1', 'vc_spa_oneline_2'
			}
		},
	}

	-- 환금용 아이템 스팩
	self.exchange_item_id = {
		hammer = { spec_id = 2, sprite_id = 21200 },
		stick = { spec_id = 3, sprite_id = 21201 },
		pickaxe = { spec_id = 4, sprite_id = 21202 },
	}

	self.fx = {
		get = function()
			return unity_object_pool.GetOrCreate('FX_get')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	-- 카메라 그리드 이름
	self.village_cam_grid_names = {
		'village_grid',
		'explore_medicinal_herb_grid',
		'explore_spa_grid'
	}

	self.demon_cam_grid_name = 'demon_grid'
	self.is_leaved_village_grid = false
	self.can_change_field_music = true
	self.field_musics = {
		default = 'ondemand/short_story_slime/audio:bgm_slime_field',
		village = 'ondemand/short_story_slime/audio:bgm_slime_village'
	}
	self.current_cam_grid_name = nil
	self.has_new_bgm_change_request = false

	self.potion_house_pot_loop_sfx = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	if self.potion_house_pot_loop_sfx ~= nil then
		music_player_util.stop_sfx(self.potion_house_pot_loop_sfx)

		self.potion_house_pot_loop_sfx = nil
	end

	if self.village_construction ~= nil then
		self.village_construction:dispose()
		self.village_construction = nil
	end

	if self.buyer_npc ~= nil then
		for _, buyer_spec in pairs(self.buyer_npc) do
			character_util.remove_relate_event(buyer_spec.npc(), self)

			if buyer_spec.emotion ~= nil then
				buyer_spec.emotion:Clear()
				buyer_spec.emotion = nil
			end
		end

		self.buyer_npc = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local common_util = get_or_create_global_table('Quest/ShortStory/Slime/Common/Util')

	common_util:load_async()

	self.fx:load_all()

	-- 마을 건설 시스템 로드
	local path = 'Quest/ShortStory/Slime/VillageConstruction/VCSystem'

	self.village_construction = get_or_create_global_table(path)
	self.village_construction:load_resource()

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	local taxi_controller = get_or_create_global_table('Quest/ShortStory/Slime/Common/SlimeTaxiController')
	taxi_controller:load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	for _, buyer_spec in pairs(self.buyer_npc) do
		local npc = buyer_spec.npc()
		if buyer_spec.is_active and lua_helper.reference_equals(e.Target, npc) then
			sp_util.start_scene(buyer_spec.interact_func, self, npc)
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	-- guard clause
	if not self:is_village_construction_system_activated() then
		return
	end

	local has_no_new_request = not self.has_new_bgm_change_request
	local is_not_same_grid =  self.current_cam_grid_name ~= e.CameraGrid.name
	self.current_cam_grid_name = e.CameraGrid.name
	
	if has_no_new_request and is_not_same_grid then
		self.has_new_bgm_change_request = true
		start_coroutine(self.change_stage_music_clip_async, self)
	end
end

function local_class:on_zone_enter_event(e)
	if self.potion_house_pot_loop_sfx == nil and
			type_util.is_zone_full_enter(e, get_party_leader(), 'potion_house') then
		local pot = get_field_object('mana_addiction_pot')

		self.potion_house_pot_loop_sfx = music_player_util.play_sfx({
			sfx_name = '01_boiling_02',
			loop = true,
			play_pos = vector_util.get_x0z(pot.Bounds.center, pot.Position.y),
			type_priority = 'loop',
			player_priority = 'object',
			max_distance = 2.5,
			min_distance = 1.5
		})

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.potion_house_pot_loop_sfx ~= nil and
			type_util.is_zone_full_leave(e, get_party_leader(), 'potion_house') then
		music_player_util.stop_sfx(self.potion_house_pot_loop_sfx)
		self.potion_house_pot_loop_sfx = nil

		return true
	end

	return false
end

--endregion

--region late_update_frame
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
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 환금 npc 세팅
	for key, buyer_spec in pairs(self.buyer_npc) do
		if buyer_spec.activate_type == 'quest' and quest_progress.InnerProgress >= buyer_spec.value then
			self:set_buyer_npc(key)
		elseif buyer_spec.activate_type == 'sub_quest_clear' then
			local sub_quest_progress = user_progress:GetStartedQuest(buyer_spec.value)
			if sub_quest_progress ~= nil and sub_quest_progress.IsComplete then
				self:set_buyer_npc(key)
			end
		end
	end

	-- 영빈관내 NPC 설정
	self:active_villagers_if_guest_house_lv_is_under_two()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('clear_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_start_pos'),
				false, false)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_start_pos'),
				false, false)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s4_start'),
				false, false)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s6_start'),
				true, true)
	elseif quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('main_s1_start'),
				true, true)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

--region 환금 아이템 npc 상호작용

function local_class:set_buyer_npc(key)
	if self.buyer_npc[key].is_active then
		return
	end

	local npc = self.buyer_npc[key].npc()
	character_util.set_active_state(npc, 'enabled')
	character_util.add_listener(npc, self)

	self.buyer_npc[key].emotion = character_util.show_emoticon_with_data(npc, nil,
			'item', self.buyer_npc[key].custom_sprite, {
				no_time_limit = true,
				item_sprite_p2w = self.buyer_npc[key].item_sprite_p2w
			})

	if self.buyer_npc[key].oneline_npc_list ~= nil then
		for i = 1, #self.buyer_npc[key].oneline_npc_list do
			local oneline_npc = get_character(self.buyer_npc[key].oneline_npc_list[i])
			character_util.set_active_state(oneline_npc, 'enabled')
		end
	end

	self.buyer_npc[key].is_active = true
end

function local_class:interact_forge_buyer(forge_npc)
	-- 대장장이 앞 정렬
	party_util.align_party(forge_npc.Position, 'right', 0.5, 'arc')

	-- 대장장이 (right,tired, cross_arm) : 몇번 휘두르지도 않았는데 전부 부서지네….
	scene_util.show_normal_speech_async(forge_npc, 'ss_slime_forge_buyer_1')

	-- 대장장이 (right, attack, idle) : 혹시 망치 좀 남는 거 있나? 사례는 두둑히 하지.
	character_util.remove_anim_and_emotion(forge_npc)
	scene_util.play_normal_speech_action(forge_npc, self, nil, nil,
			'attack', 'ss_slime_forge_buyer_2')

	local hammer_id = self.exchange_item_id.hammer.spec_id
	local have_value = self.village_construction.get_data_storage():get_product_item_value(hammer_id)

	local function quit_func()
		-- 대장장이 (right, tired, cross_arm) : 그래? 그것 참 아쉽게 되었군…
		scene_util.play_normal_speech_action(forge_npc, self, nil, { name = 'cross_arm', keep = true },
				{ name = 'tired', keep = true }, 'ss_slime_forge_buyer_6')
	end

	-- 가진 망치가 없으면 그냥 리턴
	if have_value <= 0 then
		choose_util.play_choose_event({ { 'ss_slime_forge_buyer_4', 'brutal' } })

		quit_func()
		return
	end

	local craft_item_spec = self.village_construction.constants_data.CraftItemSpecs[hammer_id]
	local dollar_when_all_item_sold = (craft_item_spec.cost * have_value)

	local choose_result = choose_util.play_choose_event({
		{ game_string:Format('ss_slime_forge_buyer_3', dollar_when_all_item_sold), 'mercy' },
		{ 'ss_slime_forge_buyer_4', 'brutal' }
	})

	if choose_result == 2 then
		quit_func()
		return
	end

	local rimuru = get_party_leader()

	-- 리무루 left, smile, eat를, 대장장이 right, smile, victory_extra를 시작.
	scene_util.set_emotion(rimuru, self, 'smile')
	scene_util.set_anim(rimuru, self, 'eat')
	scene_util.set_emotion(forge_npc, self, 'smile')
	scene_util.set_anim(forge_npc, self, 'victory_extra')

	-- 플레이어가 소지한 망치의 개수(최대 개수 6개까지만 체크)만큼 hammer 스프라이트를 대장장이에게 던지고, 스프라이트가 대장장이에게 닿으면 사라지며 Fx_get 이펙트를 출력한다.
	local throw_count = math.min(have_value, 6)

	local drop_item = {}
	for i = 1, throw_count do
		music_player_util.play_sfx_one_shot('01_throw_01')
		drop_item[i] = drop_item_util.create_item({
			pos = rimuru.Bounds.center,
			target = forge_npc.Position,
			itemid = self.exchange_item_id.hammer.sprite_id,
			notforinven = true,
			showoncharacter = true,
			lootstate = 'dontfindlooter',
			sprscale = 0.75,
			bounce_callback = function()
				music_player_util.play_sfx_one_shot('03_get_drop_item_01')
				self.fx.get():Instantiate(forge_npc.Bounds.center)
				drop_item[i]:ConsumeComplete()
			end
		})

		wait_for_sec(0.5)
	end

	-- 마지막 Fx_get 출력을 기준으로 0.5초 대기.
	wait_for_sec(0.5)

	-- 리무루 left, smile, cast2 실행. 대장장이 right, smile, throw를 실행하며, demonworld_dollar 스프라이트를 리무루에게 던지고, 리무루 스프라이트를 획득하며 Fx_get 이펙트 출력.
	scene_util.set_anim(rimuru, self, 'cast2')

	music_player_util.play_sfx_one_shot('01_throw_01')
	scene_util.set_anim(forge_npc, self, { name = 'throw', loop = false })

	-- 획득한 이후 플레이어 머리 위로 “ +(망치의 가격 x 던진 개수의 합산) 마계 달러” 메세지 출력.
	-- 마계 달러 메세지 종료까지 대기
	self:get_dollar_event(forge_npc, rimuru, dollar_when_all_item_sold)
	character_util.remove_anim_and_emotion(rimuru)

	-- 대장장이 (right, smile, cast2) : 좋은 거래였네! 그럼 또 부탁하지!!
	scene_util.play_normal_speech_action(forge_npc, self, nil, 'cast2',
			'smile', 'ss_slime_forge_buyer_5')

	-- 아이디에 해당하는 아이템 전부 제거 후 달러 넣어줌
	self.village_construction:set_dollar_when_all_item_sold(hammer_id, dollar_when_all_item_sold)

	-- 플레이어 컨트롤 복귀. 해당 캐릭터 인터렉트 가능 상태로 복귀하여 이벤트 반복 진행 가능.
end

function local_class:interact_potion_store_buyer(potion_npc)
	-- 연구원 앞 정렬
	party_util.align_party(potion_npc.Position, 'right', 0.5, 'arc')

	-- 연구원 (right,tired, cross_arm) : 음… 샘플들을 섞을만한 게 없나…
	scene_util.show_normal_speech_async(potion_npc, 'ss_slime_potion_store_buyer_1')

	-- 연구원 (right, tired, idle) : 혹시 봉 같은 게 있을까? 사례는 해줄게!
	character_util.remove_anim_and_emotion(potion_npc)
	scene_util.play_normal_speech_action(potion_npc, self, nil, nil,
			'tired', 'ss_slime_potion_store_buyer_2')

	local stick_id = self.exchange_item_id.stick.spec_id
	local have_value = self.village_construction.get_data_storage():get_product_item_value(stick_id)

	local function quit_func()
		-- 연구원 (right, tired, cross_arm) : 그래? 그럼 어쩌지…
		scene_util.play_normal_speech_action(potion_npc, self, nil, { name = 'cross_arm', keep = true },
				{ name = 'tired', keep = true }, 'ss_slime_potion_store_buyer_6')
	end

	-- 가진 봉이 없으면 그냥 리턴
	if have_value <= 0 then
		choose_util.play_choose_event({ { 'ss_slime_potion_store_buyer_4', 'brutal' } })

		quit_func()
		return
	end

	local craft_item_spec = self.village_construction.constants_data.CraftItemSpecs[stick_id]
	local dollar_when_all_item_sold = (craft_item_spec.cost * have_value)

	local choose_result = choose_util.play_choose_event({
		{ game_string:Format('ss_slime_potion_store_buyer_3', dollar_when_all_item_sold), 'mercy' },
		{ 'ss_slime_potion_store_buyer_4', 'brutal' }
	})

	if choose_result == 2 then
		quit_func()
		return
	end

	local rimuru = get_party_leader()

	-- 리무루 left, smile, eat를, 연구원 right, smile, victory_extra를 시작.
	scene_util.set_emotion(rimuru, self, 'smile')
	scene_util.set_anim(rimuru, self, 'eat')
	scene_util.set_emotion(potion_npc, self, 'smile')
	scene_util.set_anim(potion_npc, self, 'victory_extra')

	-- 플레이어가 소지한 봉의 개수(최대 개수 6개까지만 체크)만큼 stick 스프라이트를 연구원에게 던지고, 스프라이트가 연구원에게 닿으면 사라지며 Fx_get 이펙트를 출력한다.
	local throw_count = math.min(have_value, 6)

	local drop_item = {}
	for i = 1, throw_count do
		music_player_util.play_sfx_one_shot('01_throw_01')
		drop_item[i] = drop_item_util.create_item({
			pos = rimuru.Bounds.center,
			target = potion_npc.Position,
			itemid = self.exchange_item_id.stick.sprite_id,
			notforinven = true,
			showoncharacter = true,
			lootstate = 'dontfindlooter',
			sprscale = 0.6,
			bounce_callback = function()
				music_player_util.play_sfx_one_shot('03_get_drop_item_01')
				self.fx.get():Instantiate(potion_npc.Bounds.center)
				drop_item[i]:ConsumeComplete()
			end
		})

		wait_for_sec(0.2)
	end

	-- 마지막 Fx_get 출력을 기준으로 0.5초 대기.
	wait_for_sec(1)

	-- 리무루 left, smile, cast2 실행. 연구원 right, smile, throw를 실행하며, demonworld_dollar 스프라이트를 리무루에게 던지고, 리무루 스프라이트를 획득하며 Fx_get 이펙트 출력.
	scene_util.set_anim(rimuru, self, 'cast2')

	music_player_util.play_sfx_one_shot('01_throw_01')
	scene_util.set_anim(potion_npc, self, { name = 'throw', loop = false })

	-- 획득한 이후 플레이어 머리 위로 “ +(망치의 가격 x 던진 개수의 합산) 마계 달러” 메세지 출력.
	-- 마계 달러 메세지 종료까지 대기
	self:get_dollar_event(potion_npc, rimuru, dollar_when_all_item_sold)
	character_util.remove_anim_and_emotion(rimuru)

	-- 연구원 (right, smile, cast2) : 고마워! 그럼 다음에도 잘부탁해!
	scene_util.play_normal_speech_action(potion_npc, self, nil, 'cast2',
			'smile', 'ss_slime_potion_store_buyer_5')

	-- 아이디에 해당하는 아이템 전부 제거 후 달러 넣어줌
	self.village_construction:set_dollar_when_all_item_sold(stick_id, dollar_when_all_item_sold)

	-- 플레이어 컨트롤 복귀. 해당 캐릭터 인터렉트 가능 상태로 복귀하여 이벤트 반복 진행 가능.
end

function local_class:interact_hot_spring_buyer(hot_spring_npc)
	-- 사우나 악마 앞 정렬
	party_util.align_party(hot_spring_npc.Position, 'right', 0.5, 'arc')

	-- 사우나 악마 (right,tired, idle) : 음… 이번엔 온천으로 사업을 해볼까…
	scene_util.show_normal_speech_async(hot_spring_npc, 'ss_slime_spa_buyer_1')

	-- 사우나 악마 (right, tired, idle) : 혹시 곡괭이를 가지고 계실까요? 제게 주신다면 사례는 톡톡히 하겠습니다.
	scene_util.play_normal_speech_action(hot_spring_npc, self, nil, nil,
			'tired', 'ss_slime_spa_buyer_2')

	local pickaxe_id = self.exchange_item_id.pickaxe.spec_id
	local have_value = self.village_construction.get_data_storage():get_product_item_value(pickaxe_id)

	local function quit_func()
		-- 사우나 악마 (right, tired, cross_arm) : 그러시군요… 아쉽게 되었네요…
		scene_util.play_normal_speech_action(hot_spring_npc, self, nil, 'cross_arm',
				{ name = 'tired', keep = true }, 'ss_slime_spa_buyer_6')
	end

	-- 가진 곡괭이가 없으면 그냥 리턴
	if have_value <= 0 then
		choose_util.play_choose_event({ { 'ss_slime_spa_buyer_4', 'brutal' } })

		quit_func()
		return
	end

	local craft_item_spec = self.village_construction.constants_data.CraftItemSpecs[pickaxe_id]
	local dollar_when_all_item_sold = (craft_item_spec.cost * have_value)

	local choose_result = choose_util.play_choose_event({
		{ game_string:Format('ss_slime_spa_buyer_3', dollar_when_all_item_sold), 'mercy' },
		{ 'ss_slime_spa_buyer_4', 'brutal' }
	})

	if choose_result == 2 then
		quit_func()
		return
	end

	local rimuru = get_party_leader()

	-- 리무루 left, smile, eat를, 연구원 right, smile, victory_extra를 시작.
	scene_util.set_emotion(rimuru, self, 'smile')
	scene_util.set_anim(rimuru, self, 'eat')
	scene_util.set_emotion(hot_spring_npc, self, 'smile')
	scene_util.set_anim(hot_spring_npc, self, 'victory_extra')

	-- 플레이어가 소지한 봉의 개수(최대 개수 6개까지만 체크)만큼 stick 스프라이트를 연구원에게 던지고, 스프라이트가 연구원에게 닿으면 사라지며 Fx_get 이펙트를 출력한다.
	local throw_count = math.min(have_value, 6)

	local drop_item = {}
	for i = 1, throw_count do
		music_player_util.play_sfx_one_shot('01_throw_01')
		drop_item[i] = drop_item_util.create_item({
			pos = rimuru.Bounds.center,
			target = hot_spring_npc.Position,
			itemid = self.exchange_item_id.pickaxe.sprite_id,
			notforinven = true,
			showoncharacter = true,
			lootstate = 'dontfindlooter',
			sprscale = 1,
			bounce_callback = function()
				music_player_util.play_sfx_one_shot('03_get_drop_item_01')
				self.fx.get():Instantiate(hot_spring_npc.Bounds.center)
				drop_item[i]:ConsumeComplete()
			end
		})

		wait_for_sec(0.2)
	end

	-- 마지막 Fx_get 출력을 기준으로 0.5초 대기.
	wait_for_sec(1)

	-- 리무루 left, smile, cast2 실행. 연구원 right, smile, throw를 실행하며, demonworld_dollar 스프라이트를 리무루에게 던지고, 리무루 스프라이트를 획득하며 Fx_get 이펙트 출력.
	scene_util.set_anim(rimuru, self, 'cast2')

	music_player_util.play_sfx_one_shot('01_throw_01')
	scene_util.set_anim(hot_spring_npc, self, { name = 'throw', loop = false })

	-- 획득한 이후 플레이어 머리 위로 “ +(망치의 가격 x 던진 개수의 합산) 마계 달러” 메세지 출력.
	-- 마계 달러 메세지 종료까지 대기
	self:get_dollar_event(hot_spring_npc, rimuru, dollar_when_all_item_sold)
	character_util.remove_anim_and_emotion(rimuru)

	-- 사우나 악마 (right, smile, cast2) : 감사합니다! 그럼 다음번에도 부탁드립니다.
	scene_util.play_normal_speech_action(hot_spring_npc, self, nil, 'cast2',
			'smile', 'ss_slime_spa_buyer_5')

	-- 아이디에 해당하는 아이템 전부 제거 후 달러 넣어줌
	self.village_construction:set_dollar_when_all_item_sold(pickaxe_id, dollar_when_all_item_sold)

	-- 플레이어 컨트롤 복귀. 해당 캐릭터 인터렉트 가능 상태로 복귀하여 이벤트 반복 진행 가능.
end

function local_class:get_dollar_event(sender, target, value)
	music_player_util.play_sfx_one_shot('01_dollars_01')

	local dollar_item = drop_item_util.create_item({
		pos = sender.Bounds.center,
		target = target.Position,
		itemid = 20339,
		notforinven = true,
		sprscale = 0.5,
		lootstate = 'dontfindlooter',
		skip_text = true
	})

	wait_for_sec(1)

	dollar_item.ConsumeTarget = target
	dollar_item:Fly()

	while ((target.Position:GetX0z() - dollar_item.Position:GetX0z()).magnitude > 0.3) do
		coroutine.yield(nil)
	end

	CS.Oak.FieldUIFloatingText.Get(target):JustPrintItemName('+' .. (value) .. ' ' ..
			game_string:GetString('ss_village_construction_dollar'), 0)

	wait_for_sec(0.5)
end

--endregion 환금 아이템 npc 상호작용

--region 영빈관 내 NPC 설정
-- 레벨 1 영빈관내 NPC들 관련 처리
function local_class:active_villagers_if_guest_house_lv_is_under_two()
	local cur_lv = self.village_construction.get_data_storage():get_guest_house_level()

	if cur_lv < 2 then
		local npcs = get_characters_with_name_format('s5_guest_house_civil_%d', 4)
		character_util.set_group_active_state(npcs, 'enabled')
	end
end
--endregion

-- Inner Progress가 5 부터는 건설 시스템 활성화 상태로 판단.
function local_class:is_village_construction_system_activated()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local activate = quest_progress.InnerProgress > 4

	--메인 10섹션은 비활성화
	if quest_progress.InnerProgress == 9 then
		activate = false
	end

	return activate
end

-- 카메라의 그리드 이동 시간 0.55초 이용
function local_class:change_stage_music_clip_async()
	if not self.can_change_field_music then
		return
	end

	local mix_duration = 0.75

	local function get_new_music_clip_name()
		return table_util.contain_value(self.village_cam_grid_names, self.current_cam_grid_name)
				and self.field_musics.village
				or self.field_musics.default
	end

	local clip_name = get_new_music_clip_name()

	if music_player.CurrentStageMusicName ~= clip_name then
		music_player_util.change_stage_music_volume('field', 0, mix_duration)
	end
	
	local time_passed = 0

	while (time_passed < mix_duration) do
		if self.has_new_bgm_change_request then
			time_passed = 0
			self.has_new_bgm_change_request = false
		end
		
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end
	

	clip_name = get_new_music_clip_name()

	-- 같은 브금이면 생략
	if music_player.CurrentStageMusicName ~= clip_name then
		music_player_util.play_stage_music({ state = 'muted', mix = 0 })
		music_player_util.set_stage_music_clip_async({ state = 'field', name = clip_name })
		music_player_util.play_stage_music({ state = 'field', mix = 0, volume = 0  })
	end

	music_player_util.change_stage_music_volume('field', 1, mix_duration)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
