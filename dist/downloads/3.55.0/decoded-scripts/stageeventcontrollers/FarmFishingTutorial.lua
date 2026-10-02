local local_class = newclass('FarmFishingTutorialController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 고양이 핸들네임
	self.cat_handle_name = 'npc_cat'

	-- 낚시터 핸들네임
	self.fishing_handle_name = 'fishing_spot_2'

	-- 튜토리얼 낚싯대
	self.get_tutorial_rod = function()
		return get_field_object('fishing_tutorial_rod')
	end

	-- 낚시터 핸들네임 리스트
	self.fishing_handle_name_list = {}
	table.insert(self.fishing_handle_name_list, 'fishing_spot_1')
	table.insert(self.fishing_handle_name_list, 'fishing_spot_2')
	table.insert(self.fishing_handle_name_list, 'fishing_spot_3')

	-- 고양이 NPC
	self.npc_cat = nil

	-- 고양이를 튜토리얼 진행상황
	-- 0 : 고양이를 만나지 않음
	-- 1 : 만나서 대화 후 고양이가 물에 빠짐
	-- 2 : 낚싯대 획득
	-- 3 : 낚시 시작
	-- 4 : 낚시종료
	self.fishing_tutorial_progress = 0

	-- 고양이의 혼잣말 코루틴 루프용
	self.tutorial_talk_loop = false

	-- 낚싯대 줍는 존
	self.rod_zone = nil
	self.rod_zone_name = 'get_rod_zone'

	-- 낚시 매니저
	self.fishing_manager = CS.Oak.HeavenHoldFarmSystem.Instance.FishingManager

	-- fx
	self.get_fx_water_in_pool = function()
		return unity_object_pool.GetOrCreate('fx_common_water_splash_in')
	end

	self.get_fx_water_splash_loop = function()
		return unity_object_pool.GetOrCreate('fx_fish_water_splash_loop')
	end

	self.get_fishing_rod_preset = function()
		return unity_object_pool.GetOrCreate('hhf_tutorial_rod')
	end

	-- 처음으로 물고기 주는 이벤트 체크용 key
	self.first_give_fish_key = 'give_first_fish_check'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if self.water_splash_effect ~= nil then
		self.water_splash_effect:Dispose()
		self.water_splash_effect = nil
	end

	if self.fishing_rod_preset ~= nil then
		self.fishing_rod_preset:Dispose()
		self.fishing_rod_preset = nil
	end

	if self.water_loop_sfx ~= nil then
		self.water_loop_sfx:Stop()
		self.water_loop_sfx = nil
	end

	self.rod_position = nil
	self.tutorial_talk_loop = false
	self.tutorial_fishing_loop = false

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	quest_util.load_pool_resource('fx_common_water_splash_in', 'fx_fish_water_splash_loop', 'hhf_tutorial_rod')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
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
	if lua_helper.reference_equals(e.Target, get_character(self.cat_handle_name)) and
			self.fishing_tutorial_progress == 0 then
		self:talk_to_cat()
		return true

	elseif lua_helper.reference_equals(e.Target, get_field_object(self.fishing_handle_name)) and
		self.fishing_tutorial_progress == 2 then
		self.fishing_tutorial_progress = 3
		start_coroutine(self.fishing_tutorial_start, self)
		return true

	elseif lua_helper.reference_equals(e.Target, self.get_tutorial_rod()) and
		self.fishing_tutorial_progress == 1 then
		self.fishing_tutorial_progress = 2
		farm_util.play_screenplay(self.get_fishing_rod, self)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	return false
end

function local_class:on_zone_leave_event(e)

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'rescue_cat' then
		start_coroutine(self.cat_suggest_fishing, self)

		return true
	elseif e:GetParamAt(0) == 'give_first_fish' then
		local fish_check = CS.UnityEngine.PlayerPrefs.GetInt(self.first_give_fish_key, 0)

		if fish_check == 0 then
			sp_util.play_normal_screenplay(self.give_first_fish, self)
		end

		return true
	elseif e:GetParamAt(0) == 'water_splash_end' then
		if self.water_splash_effect ~= nil then
			self.water_splash_effect:Dispose()
			self.water_splash_effect = nil
		end

		if self.water_loop_sfx ~= nil then
			self.water_loop_sfx:Stop()
			self.water_loop_sfx = nil
		end

		return true
	elseif e:GetParamAt(0) == 'first_fish_sell' then
		start_coroutine(self.give_first_fish, self)
	end

	return false
end

function local_class:on_stage_start_event(e)
	self:cat_npc_setting()


	return true
end

function local_class:on_stage_end_event(e)
	self.tutorial_talk_loop = false
	self.tutorial_fishing_loop = false

	if self.water_splash_effect ~= nil then
		self.water_splash_effect:Dispose()
		self.water_splash_effect = nil
	end

	if self.water_loop_sfx ~= nil then
		self.water_loop_sfx:Stop()
		self.water_loop_sfx = nil
	end
	return true
end
--endregion

--region FishingTutorial
function local_class:cat_npc_setting()
	-- 남의 농장이면 튜토리얼을 하지 않는다.
	if not farm_util.is_in_local_farm() then
		self.fishing_tutorial_progress = 4
	end

	-- 오두막 튜토리얼을 클리어하지 않은 상태라면 튜토리얼 하지 않음
	if not farm_util.is_farm_tutorial_finished() then
		self.fishing_tutorial_progress = 4
	end

	-- 낚싯대를 가지고 있으면 튜토리얼 하지 않음
	if self.fishing_manager:GetCurrentRodSpec() ~= nil then
		self.fishing_tutorial_progress = 4
	end

	-- 고양이 NPC 초기화
	self.npc_cat = get_character('npc_cat')
	if self.npc_cat ~= nil then
		-- 캐릭터 스탯 숨기기
		field_ui_manager:RemoveUI(self.npc_cat, CS.Oak.FieldUiType.CharacterStats)
		-- 고양이 NPC를 만나지 않은 상태라면 고양이를 이벤트 장소에 세팅
		if self.fishing_tutorial_progress < 4 then
			self.rod_zone = field:GetZone('get_rod_zone')
			self.fishing_tutorial_progress = 0
			ui_quest_marker:AddQuestMarkerToIFO('npc_cat', -1, false, self.npc_cat)
			self.npc_cat.Position = get_field_object(self.fishing_handle_name).Position - vector(1, 0, 0)
			character_util.set_direction(self.npc_cat, 'right')
			character_util.spine_set_attachment(self.npc_cat, '[base]weapon1', 'farm_fishing_rod_1')
			character_util.set_anim_and_emotion(self.npc_cat, { name = 'staff_cast', loop = true }, { name = 'attack' })
			message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'fishing_tutorial_begin' }))
			self.tutorial_talk_loop = true

			-- 모든 낚시 스폿 비활성화
			for _, handle_name in ipairs(self.fishing_handle_name_list) do
				local spot = get_field_object(handle_name)
				spot.ActiveState = active_state('disabled')
			end
		end
	end
end

-- 고양이에게 말 걸기
function local_class:talk_to_cat()
	if self.fishing_tutorial_progress == 0 then
		self.fishing_tutorial_progress = 1
		farm_util.play_screenplay(self.cat_first_meet_event, self)
	end
end

-- 고양이 첫만남 이벤트
function local_class:cat_first_meet_event()
	-- 퀘스트 마커 제거
	ui_quest_marker:RemoveQuestMarker('npc_cat')

	--선택지
	choose_util.play_choose_event({
		{ 'farm_fishing_tutorial_selection1_1', 'mercy' }, --누구세요?
		{ 'farm_fishing_tutorial_selection1_2', 'brutal' }    --물고기 도둑이야!
	})

	--혼잣말 종료
	self.tutorial_talk_loop = false
	speech_bubble_util.remove_bubble(self.npc_cat)

	-- 낚싯대 떨어뜨림
	music_player_util.play_sfx_one_shot('01_air_spin_02')
	self.npc_cat.SpineController:SetAttachment('[base]weapon1', 'empty')
	local target_pos = self.rod_zone.Bounds.center
	local rod_item = drop_item_util.create_item({ pos = self.npc_cat.Position, target = target_pos,
												 itemid = 240001, notforinven = true, sprscale = 0.7,
												 lootstate = 'dontfindlooter' })

	character_util.set_anim_and_emotion(self.npc_cat, { name = 'embarrassed', loop = true }, { name = 'surprise' })

	character_util.jump(self.npc_cat, 0.5, 0.3)
	character_util.move_to(self.npc_cat, self.npc_cat.Position + vector(0.5, 0, 0), 0.3, nil)

	music_player_util.play_stage_music({ name = 'bgm_trickery_theme', state = 'event' })
	music_player_util.play_sfx_one_shot('03_runaway_02')
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')

	--냐냐냐냥!
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_group_emotion({ user_party.Leader, self.npc_cat }, { name = 'surprise' })
	character_util.set_anim(self.npc_cat, { name = 'cliff' })
	speech_bubble_util.show_speech_bubble(self.npc_cat,
			{ key = 'farm_fishing_tutorial_speech2', skip = true, bubble_type = 'shout' })
	wait_for_sec(2)

	music_player_util.play_sfx_one_shot('01_fall_down_02')
	local water_center_pos = self.npc_cat.Position + vector(3, -0.5, 0)
	character_util.set_anim_and_emotion(self.npc_cat, { name = 'embarrassed', loop = true }, { name = 'surprise' })
	character_util.spine_rotate(self.npc_cat, -360, 0.3)
	character_util.jump(self.npc_cat, 2, 0.3)
	character_util.move_to_async(self.npc_cat, water_center_pos, 0.3, nil)

	start_coroutine(self.float_cat_loop, self)

	music_player_util.play_sfx_one_shot('02_explosion_water_01')
	self.get_fx_water_in_pool():Instantiate(water_center_pos)

	character_util.set_active_shadow(self.npc_cat, false)
	self.water_splash_effect = self.get_fx_water_splash_loop():Instantiate(water_center_pos)

	--살려줘! 난 수영을 못한단 말이야!
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(self.npc_cat,
			{ key = 'farm_fishing_tutorial_speech3', skip = true, bubble_type = 'shout' })

	wait_for_sec(0.5)

	start_coroutine(self.cat_fall_loop, self)

	ui_quest_marker:AddQuestMarkerToPoint('fishing_rod', -1, false, target_pos)
	character_util.remove_emotion(user_party.Leader)

	character_util.spine_rotate(self.npc_cat, 0, 0)
	self.get_tutorial_rod().Position = vector(16, 0, -11.5)

	-- 드랍아이템과 일반 오브젝트와 바꿔치기 한다
	self.rod_position = rod_item.Position
	drop_item_util.dispose_item(rod_item)
	local height = stage_util.get_height(self.rod_position)
	local preset_pos = vector_util.get_x0z(self.rod_position, height)
	self.fishing_rod_preset = self.get_fishing_rod_preset():Instantiate(preset_pos)

	music_player_util.play_stage_music({ state = 'field' })
end

function local_class:float_cat_loop()
	self.tutorial_talk_loop = true

	local time_passed = 0
	local speed = 0.3
	local height = 0.2
	local offset = -0.5
	local cat_position = self.npc_cat.Position

	self.water_loop_sfx = music_player_util.play_sfx({
		sfx_name = '01_water_loop_06', loop = true, type_priority = 'event', player_priority = 'npc', parent = self.npc_cat })

	while self.tutorial_talk_loop do
		local y = math.sin(math.pi * 2 * time_passed * speed) * height + offset

		self.npc_cat.Position = vector_util.get_x0z(cat_position, y)

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end
end

function local_class:cat_fall_loop()
	self.tutorial_talk_loop = true
	while self.tutorial_talk_loop do
		--살려줘! 난 수영을 못한단 말이야!
		speech_bubble_util.show_speech_bubble_async(self.npc_cat,
				{ key = 'farm_fishing_tutorial_speech3', bubble_type = 'shout' })

		wait_for_sec(2)
	end
end

-- 낚싯대 획득
function local_class:get_fishing_rod()
	wp_util.move_async(user_party.Leader, self.rod_position + vector(0.7, 0, 0),
			2, nil, { last_direction = 'left' })

	local equip_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true
	, type_priority = 'loop', player_priority = 'player' })

	character_util.set_animation_n_times_async(user_party.Leader, { name = 'eat', count = 3 })
	equip_sfx:Stop()

	-- 아이템 컨슘 연출
	self.fishing_rod_preset:Dispose()
	self.fishing_rod_preset = nil
	local height = stage_util.get_height(self.rod_position)
	local preset_pos = vector_util.get_x0z(self.rod_position, height)
	local rod_item = drop_item_util.create_item({ pos = preset_pos, itemid = 240001, notforinven = true, sprscale = 0.7, lootstate = 'FixLooter' })
	rod_item.ConsumeTarget = user_party.Leader
	self.rod_position = nil

	wait_for_sec(0.5)

	-- 아이템 획득 연출
	local item_place_holder = create_item_placeholder({ id = 240001 })
	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent, item_place_holder,
			'farm_fishing_tutorial_fishing_rod_title',
			'farm_fishing_tutorial_fishing_rod_subtitle',
			'farm_fishing_tutorial_fishing_rod_desc')

	ui_quest_marker:RemoveQuestMarker('fishing_rod')

	ui_quest_marker:AddQuestMarkerToPoint('fishing_rod', -1, false,
			get_field_object(self.fishing_handle_name).Position - vector(0.5, 0, 0))

	-- 낚시 스폿 활성화
	local spot = get_field_object(self.fishing_handle_name)
	spot.ActiveState = active_state('enabled')

	-- HeavenHoldFarm에서 낚시 관련 작동하지 않도록 처리
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'fishing_tutorial_playing' }))

	self.get_tutorial_rod().Position = vector(999, 0, 999)

	camera_util.resize_to_default(0.5)
	wait_for_sec(0.5)
end

-- 고양이 건지기
function local_class:fishing_tutorial_start()
	farm_util.start_screenplay()

	-- 고양이 대사 종료
	self.tutorial_talk_loop = false
	speech_bubble_util.remove_bubble(self.npc_cat)

	ui_quest_marker:RemoveQuestMarker('fishing_rod')

	local spot = get_field_object(self.fishing_handle_name)
	self.fishing_manager:StartFishing(CS.Oak.HeavenHoldFarmFishingManager.FishingType.Tutorial, spot.Position)

	start_coroutine(self.cat_damage_emotion_loop, self)
end

-- 낚시 진행 중 고양이의 표정이 바뀌는 부분이 있어 강제로 계속 변환
-- 낚시 코드 쪽에 예외처리할 사항이 많아 여기서 루프
function local_class:cat_damage_emotion_loop()
	self.tutorial_fishing_loop = true
	while self.tutorial_fishing_loop do
		scene_util.set_emotion_loop(self.npc_cat, 'damaged')
		coroutine.yield()
	end

end

-- 고양이가 낚시를 하자고 함
function local_class:cat_suggest_fishing()
	self.tutorial_fishing_loop = false

	camera_util.resize_to_default(1)

	music_player_util.play_sfx_one_shot('01_throw_01')
	character_util.remove_emotion(user_party.Leader)
	character_util.set_direction(user_party.Leader, 'left')
	character_util.set_animation_n_times(user_party.Leader, { name = 'throw' })
	wait_for_sec(0.15)

	character_util.set_active_shadow(self.npc_cat, true)
	character_util.jump_move(self.npc_cat, vector(self.npc_cat.Position.x - 3, 0, self.npc_cat.Position.z),
			7, 1.5, true, 'left')

	music_player_util.play_sfx_one_shot('01_trip_01')
	character_util.spine_damage_squish_default(self.npc_cat)
	character_util.spine_damage_red_pulse(self.npc_cat)
	character_util.set_anim_and_emotion(self.npc_cat, { name = 'prostrate' }, { name = 'damaged' })
	wait_for_sec(1)

	scene_util.shake_and_wakeup(self.npc_cat, 'right', 2, nil, true)
	character_util.set_direction(self.npc_cat, 'right')

	wait_for_sec(0.5)

	--(tired, idle, right) 휴… 죽을 뻔했네. 고마워,
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_direction(self.npc_cat, 'right')
	scene_util.set_emotion_loop(self.npc_cat, 'tired')
	scene_util.set_anim_loop(self.npc_cat, 'idle')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech4')

	--(idle, idle, right) 그 낚싯대를 사용한 거야? 헤실헤실하게 생긴 것치고는 꽤 하잖아.
	character_util.remove_anim_and_emotion(self.npc_cat)
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech5')

	--이모티콘 버블 silence 출력
	character_util.show_emoticon_async(self.npc_cat, nil, 'silence')

	--(doyagao, release, right) 저기, 나랑 일 하나 같이 안 할래?
	scene_util.set_emotion_loop(self.npc_cat, 'doyagao')
	wait_all({
		util.cs_generator(scene_util.pointing_at, self.npc_cat, 2),
		util.cs_generator(scene_util.show_normal_speech_async, self.npc_cat, 'farm_fishing_tutorial_speech7')
	})

	--(doyagao, idle, right) 쉬운 일이야. 물고기를 잡아서 나한테 주는 거지.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech8')

	--(doyagao, idle, right) 아, 이상한 사람은 아니니까 걱정하지마.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech9')

	--(doyagao, cross_arm, right) 혹시 이빨과 발톱이라고 들어봤을지 모르겠네.
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	scene_util.set_anim_loop(self.npc_cat, 'cross_arm')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech10')

	--(doyagao, cross_arm, right) 우리 연합에서 새 사업을 준비 중이거든?
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech11')

	--(doyagao, cross_arm, right) 도와주면 보상은 충분히 해줄 수 있어.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech11_1')

	choose_util.play_choose_event({ { 'farm_fishing_tutorial_speech12_1', 'mercy' } })

	scene_util.set_emotion_loop(user_party.Leader, 'doyagao')
	scene_util.nod_the_head(user_party.Leader, 1)

	--(smile, clap, right) 좋아. 그럼 그 낚싯대는 선물로 줄게.
	character_util.remove_emotion(user_party.Leader)
	music_player_util.play_sfx_one_shot('01_clap_01')
	scene_util.set_emotion_loop(self.npc_cat, 'smile')
	scene_util.set_anim_loop(self.npc_cat, 'clap')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech13')

	--(doyagao, cast2, right) 그래 봬도 내가 직접 만든 거라 품질은 보증한다고!
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	scene_util.set_emotion_loop(self.npc_cat, 'doyagao')
	scene_util.set_anim_loop(self.npc_cat, 'cast2')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech14')

	--(idle, attack, right) 그리고 이건 떡밥이야. 좋은 떡밥만이 최고의 물고기를 낚을 수 있지!
	scene_util.set_emotion_loop(self.npc_cat, 'idle')
	scene_util.set_anim_loop(self.npc_cat, 'idle')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech15')

	-- 떡밥 던져 줌
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_animation_n_times(self.npc_cat, { name = 'attack' })
	wait_for_sec(0.2)

	self.fishing_tutorial_progress = 4
	self.fishing_manager:StopFishing()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'fishing_tutorial_end' }))

	-- 모든 낚시 스폿 활성화
	for _, handle_name in ipairs(self.fishing_handle_name_list) do
		if handle_name ~= self.fishing_handle_name then
			local spot = get_field_object(handle_name)
			spot.ActiveState = active_state('enabled')
		end
	end

	music_player_util.play_sfx_one_shot('01_throw_01')
	local bait = drop_item_util.create_item({ pos = self.npc_cat.Position,
											  target = user_party.Leader.Position,
											  itemid = 241001, notforinven = true, sprscale = 0.7,
											  lootstate = 'dontfindlooter' })
	bait.ConsumeTarget = user_party.Leader
	wait_for_sec(0.7)

	--(idle, idle, right) 떡밥이 더 필요하면 나를 찾아줘.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech15_1')

	wait_for_sec(0.5)
end
--endregion

--region 첫 판매 연출
function local_class:give_first_fish()
	local equip_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true
	, type_priority = 'loop', player_priority = 'player' })

	character_util.set_direction(user_party.Leader, 'left')
	character_util.set_direction(self.npc_cat, 'right')
	character_util.set_animation_n_times_async(user_party.Leader, { name = 'eat', count = 3, keep_anim = true })
	equip_sfx:Stop()

	-- 애니메이션을 낚시용 idle로 변경
	character_util.set_anim(user_party.Leader, { name = 'fishing/fishing_idle' })

	-- 물고기를 건내줌
	local fish_list = self.fishing_manager.ProcessFishList
	-- 물고기 아이스박스에서 나오는 연출
	local total_coin = 0
	local item_list = {}
	local fish_obj_list = {}
	for i = 0, fish_list.Count - 1 do
		local fish_data = fish_list[i]
		local fish_spec = self.fishing_manager:GetFishSpec(fish_data.SpecId)
		local fish = self:get_fish_object(fish_spec)
		local target_pos = self.npc_cat.Position + vector(0.5, 0, 0)
		local item = drop_item_util.create_custom_item({ pos = user_party.Leader.Position + vector(-1, 0, 0),
														 target = target_pos,
														 game_object = fish.gameObject, itemid = 70025,	--아이템 ID가 무조건 필요해서 아무거나 넣음
														 notforinven = true, showoncharacter = true, show_shadow = false,
														 lootstate = 'dontfindlooter', skip_text = true,
														 bounce_callback = function()
															 fish_drop_end = true
															 music_player_util.play_sfx_one_shot('01_get_head_01')
														 end })
		music_player_util.play_sfx_one_shot('01_throw_01')
		wait_for_sec(0.5)
		table.insert(item_list, item)
		table.insert(fish_obj_list, fish)
		total_coin = total_coin + fish_spec.Price
	end

	wait_for_sec(1.5)

	--(idle, question, right) 흠... 좋은 물고기잖아.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_anim_non_loop(self.npc_cat, 'question')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech16')

	--(idle, question, right) 이 정도면 연합에서 취급할 상품으로 손색이 없겠어.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech17')

	--(idle, question, right) 그리고 정말... 맛있게 생겼네....
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech18')

	character_util.show_emoticon_async(self.npc_cat, nil, 'silence')

	--"(burning, cast2, right) 으아아아 못참겠다!
	music_player_util.play_sfx_one_shot('03_dialogue_china_01')
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	scene_util.set_emotion_loop(self.npc_cat, 'burning')
	scene_util.set_anim_loop(self.npc_cat, 'cast2')
	scene_util.show_shout_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech20')

	--고양이 수인이 물고기를 먹는다. (greed, eat, right)
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	character_util.set_anim_and_emotion(self.npc_cat, { name = 'eat' }, { name = 'greed' })
	local eat_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_eat_01', loop = true, type_priority = 'event', player_priority = 'player' })
	scene_util.set_anim_loop(self.npc_cat)

	-- 놓여 있는 물고기들 하나씩 먹기
	for i = 1, #item_list do
		start_coroutine(self.eat_fish, self, item_list[i], fish_obj_list[i], 1.3)
		wait_for_sec(0.5)
	end
	wait_for_sec(1.1)

	eat_sfx:Stop()
	character_util.remove_anim(self.npc_cat)
	wait_for_sec(0.3)

	--(sing, seat, right) 히야~ 정말 맛있는 물고기네~
	music_player_util.play_sfx_one_shot('01_hit_npc_01')
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.set_emotion_loop(self.npc_cat, 'sing')
	scene_util.set_anim_loop(self.npc_cat, 'seat')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech21')

	--선택지 출력
	--1. 그걸 먹어버리면 어떡해!
	--2. 손님, 식사는 입에 맞으셨습니까?
	local choose_result = choose_util.play_choose_event(
			{ { 'farm_fishing_tutorial_speech22', 'brutal' }, { 'farm_fishing_tutorial_speech23', 'mercy' } })

	if choose_result == 1 then
		--(attack, release, left)
		music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
		scene_util.set_emotion_loop(user_party.Leader, 'attack')
		scene_util.pointing_at(user_party.Leader, 3)
	else
		--(smile, sing, left)
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		scene_util.set_emotion_loop(user_party.Leader, 'smile')
		scene_util.set_anim_loop(user_party.Leader, 'sing')
		wait_for_sec(1)
	end

	character_util.remove_emotion(user_party.Leader)

	-- 애니메이션을 낚시용 idle로 변경
	character_util.set_anim(user_party.Leader, { name = 'fishing/fishing_idle' })

	--(surprise, idle, right) 앗, 내 정신 좀 봐.
	scene_util.set_emotion_loop(self.npc_cat, 'surprise')
	scene_util.set_anim_loop(self.npc_cat, 'idle')
	character_util.normal_double_jump(self.npc_cat, '01_player_jump_01')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech24')

	--(blush, cross_arm_ right) 크흠, 방금 그건. 그... 그래. 품질 검사였어!
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.set_emotion_loop(self.npc_cat, 'blush')
	scene_util.set_anim_loop(self.npc_cat, 'cross_arm')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech25')

	--(attack, release, right) 정말 괜찮은 상품인지 알아본 것 뿐이라고!
	scene_util.set_emotion_loop(self.npc_cat, 'attack')
	wait_all({
		util.cs_generator(scene_util.pointing_at, self.npc_cat, 2),
		util.cs_generator(scene_util.show_normal_speech_async, self.npc_cat, 'farm_fishing_tutorial_speech26')
	})

	--(idle, attack right) 자, 여기 약속한 보상이야.
	scene_util.set_emotion_loop(self.npc_cat, 'idle')
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech27')

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_animation_n_times(self.npc_cat, { name = 'attack' })
	wait_for_sec(0.2)

	--고양이 수인으로부터 낚시 코인 드롭, 플레이어가 획득
	--낚시 코인 드롭할 때 모션 = (idle, attack, right)
	--낚시 코인 획득 팝업 출력
	--확인 버튼 터치 후 고양이 수인 아래 대사 진행
	music_player_util.play_sfx_one_shot('01_throw_01')
	local coin = drop_item_util.create_item({ pos = self.npc_cat.Position, target = user_party.Leader.Position,
											  itemid = 70025, notforinven = true, sprscale = 0.5,
											  lootstate = 'dontfindlooter', showoncharacter = true, skip_text = true })
	coin.ConsumeTarget = user_party.Leader
	wait_for_sec(1)

	-- 아이템 획득 연출
	local reward = CS.Oak.Item.Create(CS.Oak.ItemSpec.GetById(70025), nil, nil, nil,
			total_coin)
	local str = CS.GameStrings.Instance:GetString('farm_fishing_get_fishing_coin')
	local list = CS.System.Collections.Generic.List(CS.Oak.ItemPlaceholder)
	local items = list()
	items:Add(CS.Oak.IItemExtension.ToItemPlaceholder(reward))

	local state = CS.Oak.RewardNoticeDefaultState()
	state.Title = CS.GameStrings.Instance:GetString('popup_default_title')
	state.Notice = str
	state.ItemList = items
	state.OnConfirmButtonClicked = function()
		start_coroutine(self.close_reward_notice, self)
	end

	CS.Oak.RewardNoticeUtil.ShowRewardNotice(CS.Oak.UI.UISceneManager.Instance, state)
end

-- 리워드 창 닫은 후
function local_class:close_reward_notice()
	--(idle, idle, right) 그럼 다시 물고기를 잡아오라구.
	scene_util.show_normal_speech_async(self.npc_cat, 'farm_fishing_tutorial_speech28')
	character_util.set_direction(user_party.Leader, 'right')

	CS.UnityEngine.PlayerPrefs.SetInt(self.first_give_fish_key, 1)
	self.fishing_manager:OpenIceBox()
end

-- 물고기 한마리 생성
function local_class:get_fish_object(fish_spec)
	local fish = CS.Oak.FishExtensions.GetFishObject(fish_spec.AssetName, vector(999, 0, 999))
	local spine = fish.transform:GetComponentInChildren(typeof(CS.Oak.SpineController))
	spine.IsShadowActive = false
	spine:SetAnimation(1, 'catch', true)

	return fish
end

-- 물고기 흔들리면서 줄어들고 사라지는 연출
function local_class:eat_fish(item, fish, duration)
	local cur_time = unity_class.time.time
	local shake_duration = duration

	local shake_range = 0.05

	local shrink_start = duration - 1
	local start_scale = 1
	local end_scale = 0.3

	wait_for_sec(0.5)

	local item_pos = item.Position
	while unity_class.time.time - cur_time < shake_duration do
		local cur_shake_x = unity_class.random.Range(-shake_range, shake_range)
		local cur_shake_z = unity_class.random.Range(-shake_range, shake_range)

		item.Position = item_pos + vector(cur_shake_x, 0, cur_shake_z)

		if unity_class.time.time - cur_time >= shrink_start then
			local cur_scale = CS.Oak.Interpolations.Linear((unity_class.time.time - cur_time) - shrink_start,
					start_scale, end_scale - start_scale, shake_duration - shrink_start)

			fish.transform.localScale = unity_class.vector3.one * cur_scale
		end

		coroutine.yield(nil)
	end

	item.ConsumeTarget = self.npc_cat
	wait_for_sec(0.5)
end
--endregion

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
