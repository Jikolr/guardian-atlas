local local_class = newclass('ShortStorySummerController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 7001201

	self.get_yuze = function()
		return get_character('yuze')
	end

	self.get_kid_android = function()
		return get_character('kid_android')
	end

	self.basket_items = {}

	-- 메인 섹션 관리용
	self.main_section = 1

	self.active_event_check = { false, false, false }
	self.show_event_check = { false, false }
	self.emoticon_check = false
	self.item_list = nil
	self.second_item_list = nil
	self.radio_on_playing = true

	self.lupina_event_playing = false

	--region 공튀기기
	self:bound_init()
	--endregion
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)
	if e:GetType() == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_character('oneline_pet')) and not self.emoticon_check then
		self.emoticon_check = true
		start_coroutine(function()
			music_player_util.play_sfx_one_shot('01_pet_ordinary_01')
			character_util.show_emoticon_async(e.Target, nil, 'rowdy')
			self.emoticon_check = false
		end)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.main_section == 1 and not self.show_event_check[1] and
			type_util.is_zone_full_enter(e, user_party.Leader, 'oneline_lupina_zone') then
		self.show_event_check[1] = true
		self.lupina_event_playing = true
		start_coroutine(self.lupina_zone_event, self)
		return true
	elseif self.main_section == 1 and not self.show_event_check[2] and
			type_util.is_zone_full_enter(e, user_party.Leader, 'oneline_lancer_girl_zone') then
		self.show_event_check[2] = true
		start_coroutine(self.lancer_girl_zone_event, self)
		return true
	elseif not self.show_event_check[3] and
			type_util.is_zone_full_enter(e, user_party.Leader, 'oneline_bari_zone') then
		self.show_event_check[3] = true
		start_coroutine(self.bari_zone_event, self)
		return true
	end
	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == 'stop_pre_play_bound' then
			start_coroutine(self.stop_pre_play_routine, self)
		elseif e.Params[0] == 'start_pre_play_bound' then
			start_coroutine(self.start_pre_play_routine, self)
		elseif e.Params[0] == 'summer_s1_s4_event_start' then
			self:stop_lupina_event()
		end
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		if e.CurrentProgress <= 1 then
			self:npc_setting(e.CurrentProgress + 1)
			return true
		end
	end
	return false
end

function local_class:on_stage_end_event(_)
	character_util.remove_relate_event(get_character('oneline_pet'), self.cs_controller)

	self.radio_on_playing = false
	self:item_remove()

	if self.second_item_list ~= nil then
		for _, item in ipairs(self.second_item_list) do
			item:ConsumeComplete()
			item = nil
		end
		self.second_item_list = nil
	end

	for _, item in ipairs(self.basket_items) do
		item:ConsumeComplete()
		item = nil
	end
	self.basket_items = nil

	self.cs_controller = nil
	self.scene = nil

	--region 공튀기기
	self:bound_dispose()
	--endregion
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

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 수유즈로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 수유즈를 리더로
		local leader = self.get_yuze()
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

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.InnerProgress == 0 then
		change_leader_character()
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.IsComplete then
		change_leader_character({ self.get_kid_android() })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 1 then
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 3 then
		change_leader_character({ self.get_kid_android() })
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 5 then
		change_leader_character()
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)

	elseif main_quest_progress.InnerProgress == 6 then
		change_leader_character()
		start_stage_event('left', field:GetMarker('s7_yuze_pos').position, false, false)
	elseif main_quest_progress.InnerProgress == 7 then
		change_leader_character()
		start_stage_event('down', field:GetMarker('s8_yuze_pos').position, false, false)
	else
		change_leader_character({ self.get_kid_android() })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	--region 서브 이벤트 공튀기기 오브젝트
	self:bound_setting_npc()
	start_coroutine(self.start_pre_play_routine, self)
	--endregion

	--region 서브 이벤트 해변서바이벌 오브젝트
	local dirs = { north = vector(1, 0, 0),
				   south = vector(-1, 0, 0),
				   west = vector(0, 0, 1),
				   east = vector(0, 0, -1) }
	for dir, offset in pairs(dirs) do
		for i = 1, 5 do
			local npc = get_character('beach_survival_' .. dir .. '_' .. i)

			local item = drop_item_util.create_item({
				pos = npc.Position + offset,
				itemid = 20714,
				notforinven = true,
				lootstate = 'dontfindlooter'
			})

			table.insert(self.basket_items, item)
		end
	end

	--endregion

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 0 then
		self.main_section = main_quest_progress.InnerProgress + 1
	end
	self:npc_setting(self.main_section)
	self:item_setting()
end

--region 스테이지 이벤트 세팅
function local_class:item_remove()
	if self.item_list ~= nil then
		for _, item in ipairs(self.item_list) do
			item:ConsumeComplete()
			item = nil
		end
		self.item_list = nil
	end
end

function local_class:npc_setting(section)
	self.main_section = section

	local lupina = get_character('oneline_lupina')
	local lahn = get_character('oneline_lahn')
	local lancer_girl = get_character('oneline_lancer_girl')
	local pet = get_character('oneline_pet')
	local trio_npc_list = {
		boss = get_character('oneline_trio_boss'),
		panda = get_character('oneline_trio_panda'),
		man = get_character('oneline_trio_man')
	}

	-- 하얀 야수
	character_util.add_listener(pet, self.cs_controller)

	if section == 1 and not self.active_event_check[1] then
		self.active_event_check[1] = true

		--루피나 / 란 이벤트1
		character_util.set_position(lupina, field:GetMarker('s1_oneline_pos_1').position)

		self.item_list = {}
		local item = drop_item_util.create_item({ pos = lupina.Position + vector(-0.45, 0.55, 0)
		, itemid = 20723, notforinven = true, sprscale = 1, lootstate = 'dontfindlooter', skip_text = true })
		item:SetSortingLayer(true)
		item.SpriteTransform.localScale = vector(-1, 1, 1)
		table.insert(self.item_list, item)

		character_util.set_direction(lupina, 'left')
		scene_util.set_emotion_loop(lupina, 'attack')
		character_util.set_anim(lupina, { name = 'seat' })
		lupina.Interactable.Talk = nil

		character_util.set_position(lahn, field:GetMarker('s1_oneline_pos_2').position)
		character_util.set_direction(lahn, 'right')
		scene_util.set_emotion_loop(lahn, 'idle')
		scene_util.set_anim_loop(lahn, 'librarian/writing')
		lahn.Interactable.Talk = nil

		--라피스 이벤트1
		character_util.set_position(lancer_girl, field:GetMarker('s1_oneline_pos_3').position)
		lancer_girl.SpineController:SetAttachment('[base]weapon1', 'cwp_uptowngirl')
		character_util.set_direction(lancer_girl, 'right')
		scene_util.set_emotion_loop(lancer_girl, 'smile')
		character_util.remove_anim(lancer_girl)
		lancer_girl.Interactable.Talk = nil

		--매팬단 이벤트1
		character_util.set_position(trio_npc_list.boss, field:GetMarker('s1_oneline_pos_4').position)
		character_util.set_position(trio_npc_list.panda, field:GetMarker('s1_oneline_pos_5').position)
		character_util.set_position(trio_npc_list.man, field:GetMarker('s1_oneline_pos_6').position)

		character_util.set_direction(trio_npc_list.boss, 'left')
		scene_util.set_emotion_loop(trio_npc_list.boss, 'attack')
		scene_util.set_anim_loop(trio_npc_list.boss, 'cross_arm')

		character_util.set_direction(trio_npc_list.panda, 'left')
		scene_util.set_emotion_loop(trio_npc_list.panda, 'attack')
		scene_util.set_anim_loop(trio_npc_list.panda, 'release')

		character_util.set_direction(trio_npc_list.man, 'right')
		scene_util.set_emotion_loop(trio_npc_list.man, 'sleep')
		scene_util.set_anim_loop(trio_npc_list.man, 'sleep')

		--보스 (right, attack, cross_arm) : 서둘러야 해! 저쪽에서 상품 이벤트를 하고 있는 걸 봤다고!
		trio_npc_list.boss.Interactable.Talk = 'short_story_summer_stage_oneline_9'
		trio_npc_list.boss.Interactable.TalkSfx = '03_dialogue_negative_01'

		--대니 (left, sleep, sleep ) : 대니, 따뜻해서 잠 온다…
		trio_npc_list.man.Interactable.Talk = 'short_story_summer_stage_oneline_10'
		trio_npc_list.man.Interactable.TalkSfx = '01_sleep_02'

		--팬더 (right, attack, release) : 빨리 일어나, 이 굼벵아!
		trio_npc_list.panda.Interactable.Talk = 'short_story_summer_stage_oneline_11'
		trio_npc_list.panda.Interactable.TalkSfx = '03_dialogue_negative_02'
	end

	if section >= 2 and not self.active_event_check[2] then
		self.active_event_check[2] = true
		--아이템 배치 추가
		self:item_remove()
		self.item_list = {}
		for i = 1, 7 do
			local item_id = { 20719, 20718, 20719, 20719, 20720, 20721, 20722 }
			local item = drop_item_util.create_item({ pos = field:GetMarker('s2_item_pos_' .. i).position
			, itemid = item_id[i], notforinven = true, sprscale = 0.6, lootstate = 'dontfindlooter', skip_text = true })

			table.insert(self.item_list, item)
		end

		--루피나 / 란 이벤트2
		character_util.set_position(lupina, field:GetMarker('s2_oneline_pos_1').position)
		lupina.SpineController:SetAttachment('[base]weapon1', 'empty')
		character_util.set_direction(lupina, 'right')
		scene_util.set_emotion_loop(lupina, 'attack')
		scene_util.set_anim_loop(lupina, 'cross_arm')
		lupina.Interactable.Talk = 'short_story_summer_stage_oneline_12'
		lupina.Interactable.TalkSfx = '03_dialogue_negative_01'

		character_util.set_position(lahn, field:GetMarker('s2_oneline_pos_2').position)
		character_util.set_direction(lahn, 'right')
		scene_util.set_emotion_loop(lahn, 'idle')
		scene_util.set_anim_loop(lahn, 'librarian/writing')
		lahn.Interactable.Talk = 'short_story_summer_stage_oneline_14'
		lahn.Interactable.TalkSfx = '01_writing_01'

		--라피스 이벤트2
		character_util.set_position(lancer_girl, field:GetMarker('s2_oneline_pos_3').position)
		lancer_girl.SpineController:SetAttachment('[base]weapon1', 'empty')
		character_util.set_direction(lancer_girl, 'right')
		scene_util.set_emotion_loop(lancer_girl, 'scared')
		scene_util.set_anim_loop(lancer_girl, 'cast')
		lancer_girl.Interactable.Talk = 'short_story_summer_stage_oneline_15'
		lancer_girl.Interactable.TalkSfx = '03_runaway_01'

		--매팬단 이벤트 체크
		character_util.set_position(trio_npc_list.boss, vector(50, 0, 2))
		character_util.set_position(trio_npc_list.panda, vector(50.5, 0, 3))
		character_util.set_position(trio_npc_list.man, vector(51, 0, 2))

		character_util.set_direction(trio_npc_list.boss, 'right')
		character_util.set_direction(trio_npc_list.panda, 'down')
		character_util.set_direction(trio_npc_list.man, 'left')

		local quest_progress = user_progress:GetStartedQuest(7001208)
		if quest_progress == nil or not quest_progress.IsComplete then
			character_util.set_anim_and_emotion(trio_npc_list.boss, { name = 'idle' }, { name = 'idle' })
			character_util.set_anim_and_emotion(trio_npc_list.panda, { name = 'idle' }, { name = 'smile' })

			character_util.remove_anim_and_emotion(trio_npc_list.man)
			scene_util.set_emotion_loop(trio_npc_list.man, 'smile')
			scene_util.set_anim_loop(trio_npc_list.man, 'success', { sfx_name = '01_small_jump_01' })

			trio_npc_list.boss.Interactable.Talk = 'short_story_summer_trio_oneline_1'
			trio_npc_list.panda.Interactable.Talk = 'short_story_summer_trio_oneline_2'
			trio_npc_list.man.Interactable.Talk = 'short_story_summer_trio_oneline_3'

			trio_npc_list.boss.Interactable.TalkSfx = nil
			trio_npc_list.panda.Interactable.TalkSfx = nil
			trio_npc_list.man.Interactable.TalkSfx = nil
		else
			for _, npc in pairs(trio_npc_list) do
				scene_util.set_emotion_loop(npc, 'tired')
				scene_util.set_anim_non_loop(npc, 'prostrate')
			end

			trio_npc_list.boss.Interactable.Talk = 'short_story_summer_trio_oneline_4'
			trio_npc_list.panda.Interactable.Talk = 'short_story_summer_trio_oneline_5'
			trio_npc_list.man.Interactable.Talk = 'short_story_summer_trio_oneline_6'

			trio_npc_list.panda.Interactable.TalkSfx = '03_dialogue_tipsy_01'
			trio_npc_list.man.Interactable.TalkSfx = '03_dialogue_sadness_01'
		end
	end

	if section >= 6 and not self.active_event_check[3] then
		self.active_event_check[3] = true
		--상인 (down, smile, idle) : 스텔라였지? 상품은 한 사람당 하나씩만 가질 수 있단다.
		local seller = get_character('stamp_seller')
		seller.Interactable.Talk = 'short_story_summer_main_s5_42'
	end
end

function local_class:item_setting()
	local nari = get_character('oneline_npc_9')
	local kid = get_character('oneline_npc_8')
	local life_guard = get_character('oneline_npc_54')
	local balloon_man = get_character('oneline_npc_61')

	self.second_item_list = {}

	local item = drop_item_util.create_item({ pos = life_guard.Position + vector(1, 0, 0.4)
	, itemid = 20724, notforinven = true, sprscale = 1, lootstate = 'dontfindlooter', skip_text = true })
	item:SetSortingLayer(true)
	start_coroutine(self.bouncing_item, self, item, 0.5, 0.3)

	item = drop_item_util.create_item({ pos = nari.Position + vector(-0.2, 0.15, 0)
	, itemid = 20690, notforinven = true, sprscale = 0.6, lootstate = 'dontfindlooter', skip_text = true })
	item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, -45, 0)
	item:SetSortingLayer(true)
	table.insert(self.second_item_list, item)

	item = drop_item_util.create_item({ pos = kid.Position + vector(0.15, 0.15, 0)
	, itemid = 20690, notforinven = true, sprscale = 0.6, lootstate = 'dontfindlooter', skip_text = true })
	item.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 45, 0)
	item:SetSortingLayer(false)
	table.insert(self.second_item_list, item)

	item = drop_item_util.create_item({ pos = balloon_man.Position + vector(0.25, 0.5, 0.3)
	, itemid = 20725, notforinven = true, sprscale = 0.75, lootstate = 'dontfindlooter', skip_text = true })
	item:SetSortingLayer(false)
	table.insert(self.second_item_list, item)
end

function local_class:bouncing_item(target, duration, height)
	local state = 1
	local init_pos = target.Position
	local timer = 0
	while self.radio_on_playing do
		local progress = timer / duration
		local process = math.sin(math.pi * progress)
		timer = timer + unity_class.time.deltaTime
		if state == 1 then
			target.SpriteTransform.localScale = vector(1, unity_class.mathf.Lerp(1, 0.7, process), 1)
			target.SpriteTransform.position = init_pos + vector(0, 0, -0.15 * process)
			target.ShadowTransform.localScale = vector(1, unity_class.mathf.Lerp(1, 0.7, process), 1)
			target.ShadowTransform.position = vector_util.get_x0z(init_pos + vector(0, 0, -0.15 * process), 0.01)
			if timer > duration then
				target.SpriteTransform.localScale = vector(1, 1, 1)
				target.SpriteTransform.position = init_pos
				target.ShadowTransform.localScale = vector(1, 1, 1)
				target.ShadowTransform.position = vector_util.get_x0z(init_pos, 0.01)

				state = 2
				timer = 0
			end
		elseif state == 2 then
			target.Position = init_pos + vector(0, height * process, 0)
			if timer > duration then
				target.Position = init_pos

				state = 1
				timer = 0
			end
		end
		coroutine.yield(nil)
	end
	target.Position = init_pos
	target.SpriteTransform.localScale = vector(1, 1, 1)
	target.SpriteTransform.position = init_pos
	target.ShadowTransform.localScale = vector(1, 1, 1)
	target.ShadowTransform.position = vector_util.get_x0z(init_pos, 0)

	if target ~= nil then
		target:ConsumeComplete()
		target = nil
	end
end
--endregion

--region 공튀기기 서브 이벤트
function local_class:bound_init()

	self.get_moderator = function()return get_character('bound_ball_moderator') end
	self.get_follower = function(number) return get_character('bound_ball_follower_' .. number) end

	self.get_moderator_pos = function() return field:GetMarker('bound_ball_moderator_pos').position end
	self.get_follower_pos = function(number) return field:GetMarker('bound_ball_follower_pos_' .. number).position end
	self.get_game_start_pos = function() return field:GetMarker('bound_ball_game_start_pos').position end

	--complete setting_npc
	--비치볼 item
	self.ball_item_number = 20685
	self.ball = nil

	--ball update
	self.free_fall = nil
	self.ball_progress = 0
	self.is_bound = true

	--banana
	self.banana_item_number = 20696
	self.bananas = {}
end

function local_class:bound_dispose()
	if self.free_fall ~= nil then
		self.free_fall:Dispose()
	end
	self.is_bound = false

	--비치볼 item 제거
	if self.ball ~= nil then
		drop_item_util.dispose_item(self.ball)
		self.ball = nil
	end

	--바나나 제거
	for i = 1, #self.bananas do
		if self.bananas[i] ~= nil then
			drop_item_util.dispose_item(self.bananas[i])
			self.bananas[i] = nil
		end
	end
end

function local_class:bound_setting_npc()
	local moderator = self.get_moderator()

	--사회자
	character_util.set_position(moderator, self.get_moderator_pos())
	character_util.set_direction(moderator, 'right')
	character_util.set_anim_and_emotion(moderator, { name = 'idle' }, { name = 'smile' })

	--참가자 4명 설정
	for i = 2, 4 do
		character_util.set_position(self.get_follower(i), self.get_follower_pos(i))
		self.get_follower(i).Interactable.Talk = 'short_story_summer_bound_ball_oneline_' .. i
	end
	character_util.set_anim(self.get_follower(2), { name = 'cast', loop = true })
	character_util.set_position(self.get_follower(1), self.get_game_start_pos())

	--바나나
	local trap_pos_table = {
		vector(-19, 0, -32),
		vector(-22, 0, -32),
		vector(-17, 0, -33),
		vector(-23, 0, -34),
		vector(-18, 0, -35),
		vector(-20, 0, -37)
	}

	for i = 1, #trap_pos_table do
		local banana = drop_item_util.create_item({
			itemid = self.banana_item_number,
			pos = trap_pos_table[i],
			notforinven = true,
			lootstate = 'dontfindlooter'
		})
		table.insert(self.bananas, banana)
	end
end

function local_class:stop_pre_play_routine()
	--참가자
	character_util.set_active_state(self.get_follower(1), 'disabled')

	--비치볼
	self.ball.SpriteTransform.gameObject:SetActive(false)
	self.ball.ShadowTransform.gameObject:SetActive(false)
	self.is_bound = false

	--바나나
	for i = 1, #self.bananas do
		self.bananas[i].SpriteTransform.gameObject:SetActive(false)
		self.bananas[i].ShadowTransform.gameObject:SetActive(false)
	end
end

function local_class:start_pre_play_routine()
	--참가자
	local get_follower = function(number) return get_character('bound_ball_follower_' .. number) end

	character_util.set_active_state(get_follower(1), 'enabled')

	--바나나
	for i = 1, #self.bananas do
		self.bananas[i].SpriteTransform.gameObject:SetActive(true)
		self.bananas[i].ShadowTransform.gameObject:SetActive(true)
	end

	if self.ball ~= nil then
		self.ball.SpriteTransform.gameObject:SetActive(true)
		self.ball.ShadowTransform.gameObject:SetActive(true)
		self.ball.Position = self.get_game_start_pos() + vector(0, 1, 0)
	else
		self.ball = drop_item_util.create_item({
			itemid = self.ball_item_number,
			pos = self.get_game_start_pos() + vector(0, 1, 0),
			notforinven = true,
			showoncharacter = true,
			lootstate = 'dontfindlooter'
		})
		self.ball.ShadowTransform.localPosition = vector_util.get_x0z(self.ball.ShadowTransform.localPosition, 0.03)
	end

	self.is_bound = true
	self.ball_progress = 0

	if self.free_fall == nil then
		self.free_fall = CS.CalculatorFreeFall.Create(15, CS.Oak.Constants.JumpGravity * 3, 0, 0)
	end

	local time_passed = 0
	while self.is_bound do
		local dt = unity_class.time.deltaTime
		time_passed = time_passed + dt

		self:ball_update(dt)
		coroutine.yield()
	end
end

function local_class:ball_update(dt)
	local ball_y = self.free_fall:GetDistance(self.ball_progress)
	local pinnacle = self.free_fall:GetPinnacleDistance()

	self.ball.Position = vector_util.get_x0z(self.ball.Position, ball_y + 0.5)
	self.ball.ShadowTransform.localScale = unity_class.vector3.one * unity_class.mathf.Max((pinnacle - ball_y) / pinnacle, 0.2)

	--바닥 도착 시 조건 처리
	if ball_y <= 0 then
		self.ball_progress = 0
		character_util.remove_anim(self.get_follower(1))
		scene_util.set_anim_non_loop(self.get_follower(1), 'dualgun_victory', { scale = 1.5 })

		music_player_util.play_sfx({ sfx_name = '01_bounce_head_01', parent = self.get_follower(1), type_priority = 'event', player_priority = 'npc' })
	end

	self.ball_progress = self.ball_progress + dt
end
--endregion

function local_class:lupina_zone_event()
	local lupina = get_character('oneline_lupina')
	local lahn = get_character('oneline_lahn')
	--파라오 루피나 (right, attack, seat) : 설산 밖에서도 차고 넘치는 이 위엄을 보러 찾아왔구나…
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_ready_01', parent = lupina, type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(lupina, { key = 'short_story_summer_stage_oneline_1' })

	if not self.lupina_event_playing then
		self:lupina_event_end_setting(lupina, lahn)
		return
	end

	--파라오 루피나 (right, awesome, seat) : 기대에 보답해서 좋아요와 구독, 루피나 최고를 외칠 수 있는 권리를 주마!
	music_player_util.play_sfx({
		sfx_name = '01_bad_fairy_01', parent = lupina, type_priority = 'event', player_priority = 'npc' })
	scene_util.set_emotion_loop(lupina, 'awesome')
	speech_bubble_util.show_speech_bubble_async(lupina, { key = 'short_story_summer_stage_oneline_2' })

	if not self.lupina_event_playing then
		self:lupina_event_end_setting(lupina, lahn)
		return
	end

	--수영복 란 (left, idle, librarian/writing) : 얼음 마녀의 악명 전파를 위한 첫번째 기록.
	music_player_util.play_sfx({
		sfx_name = '01_writing_01', parent = lahn, type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(lahn, { key = 'short_story_summer_stage_oneline_3' })

	if not self.lupina_event_playing then
		self:lupina_event_end_setting(lupina, lahn)
		return
	end

	--수영복 란 (left, idle, librarian/writing) : 쌍방 원격 통신기를 이용. 추종자들과의 전자 통신 소통을 진행.
	speech_bubble_util.show_speech_bubble_async(lahn, { key = 'short_story_summer_stage_oneline_4' })

	if not self.lupina_event_playing then
		self:lupina_event_end_setting(lupina, lahn)
		return
	end

	--수영복 란 (left, idle, librarian/writing) : 그로 인해 전자 통신 추종자들이 최초로 20명 이상이 된 것을 확인.
	music_player_util.play_sfx({
		sfx_name = '01_writing_01', parent = lahn, type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(lahn, { key = 'short_story_summer_stage_oneline_5', auto_layout = true })

	self:lupina_event_end_setting(lupina, lahn)
end

function local_class:lupina_event_end_setting(lupina, lahn)
	lupina.Interactable.Talk = 'short_story_summer_stage_oneline_2'
	lupina.Interactable.TalkSfx = '01_bad_fairy_01'
	lahn.Interactable.Talk = 'short_story_summer_stage_oneline_5'
end

function local_class:stop_lupina_event()
	local lupina = get_character('oneline_lupina')
	local lahn = get_character('oneline_lahn')

	self.lupina_event_playing = false
	speech_bubble_util.remove_bubble(lupina)
	speech_bubble_util.remove_bubble(lahn)
end

function local_class:lancer_girl_zone_event()
	local lancer_girl = get_character('oneline_lancer_girl')
	--수영복 라피스 (right, smile, idle) : 민중들의 안전을 지키는 데에는 다양한 방법이 있구나!
	speech_bubble_util.show_speech_bubble_async(lancer_girl, { key = 'short_story_summer_stage_oneline_6' })

	--수영복 라피스 (right, attack, cross_arm) : 라이프 가드들의 구호활동… 기사로서 귀감이 되겠어!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_ready_01', parent = lancer_girl, type_priority = 'event', player_priority = 'npc' })
	scene_util.set_emotion_loop(lancer_girl, 'attack')
	scene_util.set_anim_loop(lancer_girl, 'cross_arm')
	speech_bubble_util.show_speech_bubble_async(lancer_girl, { key = 'short_story_summer_stage_oneline_7' })

	--수영복 라피스 (right, awesome, victory_get) : 좋았어! 나도 힘내자!
	music_player_util.play_sfx({
		sfx_name = '01_stage_intro_jump_01', parent = lancer_girl, type_priority = 'event', player_priority = 'npc' })
	scene_util.set_emotion_loop(lancer_girl, 'awesome')
	scene_util.set_anim_non_loop(lancer_girl, 'victory_get')
	speech_bubble_util.show_speech_bubble_async(lancer_girl, { key = 'short_story_summer_stage_oneline_8' })

	lancer_girl.Interactable.Talk = 'short_story_summer_stage_oneline_8'
end


function local_class:bari_zone_event()
	local bari = get_character('oneline_bari')
	local mayreel = get_character('oneline_mayreel')

	--메이릴 (right, attack, idle) : 카마엘 할아버지 봤어?
	speech_bubble_util.show_speech_bubble_async(mayreel, { key = 'short_story_summer_stage_oneline_18' })


	--메이릴 (right, damaged, idle) : 망할 꼬맹이가 되어 버렸다고!
	music_player_util.play_sfx({sfx_name = '03_dialogue_tipsy_01', loop = false,
	                            max_distance = 7, play_pos = mayreel.Position})
	scene_util.set_emotion_loop(mayreel, 'damaged')
	scene_util.shake(mayreel, 0.03, 0.3)
	speech_bubble_util.show_speech_bubble_async(mayreel, { key = 'short_story_summer_stage_oneline_19' })


	--바리 (left, tired, idle) : 진정해요, 메이릴. 저주에 걸리셔서 그런 거잖아요.
	speech_bubble_util.show_speech_bubble_async(bari, { key = 'short_story_summer_stage_oneline_20' })
	--바리 (left, smile, sing) : 무척 귀여워서 풀고 싶지 않은 저주지만요!
	scene_util.set_emotion_loop(bari, 'smile')
	scene_util.set_anim_loop(bari, 'sing')
	music_player_util.play_sfx({sfx_name = '01_bad_fairy_01', loop = false,
	                            max_distance = 7, play_pos = bari.Position})
	speech_bubble_util.show_speech_bubble_async(bari, { key = 'short_story_summer_stage_oneline_21' })
	--메이릴 (right, damaged, idle) : 으… 정말 최악이야!
	scene_util.shake(mayreel, 0.05, 0.3)
	music_player_util.play_sfx({sfx_name = '01_hit_comic_01', loop = false,
	                            max_distance = 7, play_pos = mayreel.Position})
	speech_bubble_util.show_speech_bubble_async(mayreel, { key = 'short_story_summer_stage_oneline_22' })

	bari.Interactable.Talk = 'short_story_summer_stage_oneline_21'
	mayreel.Interactable.Talk = 'short_story_summer_stage_oneline_22'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
