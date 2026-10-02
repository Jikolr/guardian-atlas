local local_class = newclass('ShortStoryRosettaController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인퀘스트 id
	self.main_quest_id = 7001301

	-- 섹션6 중간저장용 Custom State 이름
	self.s6_save_state_key = 's6_save_state'

	-- 로제라 집에 나레이션 원라인 아이템들
	self.rosetta_house_item_list = nil

	-- 원라인 event key (custom state에서 사용되는 key. ex) quest_util.get_custom_state )
	self.oasis_one_line_4_event_key = 'oasis_oneline_4_event'

	-- 원라인 npc들
	-- 오아시스 원라인 이벤트 3 npc들
	self.get_oasis_one_line_3_male_1 = function() return get_character('oasis_oneline_3_western_male_1') end
	self.get_oasis_one_line_3_male_2 = function() return get_character('oasis_oneline_3_western_male_2') end
	-- 오아시스 원라인 이벤트 4 npc들
	self.get_oasis_one_line_4_male_1 = function() return get_character('oasis_oneline_4_western_male_1') end
	self.get_oasis_one_line_4_female_1 = function() return get_character('oasis_oneline_4_western_female_1') end
	self.get_oasis_one_line_4_kid_1 = function() return get_character('oasis_oneline_4_western_kid_1') end
	-- 오아시스 원라인 이벤트 5 npc들
	self.get_oasis_one_line_5_male_1 = function() return get_character('oasis_oneline_5_western_male_1') end
	self.get_oasis_one_line_5_male_2 = function() return get_character('oasis_oneline_5_western_male_2') end

	self.get_magic_cactus = function() return get_field_object('magic_cactus') end

	-- 원라인 이벤트 zone 이름
	self.oasis_one_line_4_event_zone_name = 'oasis_oneline_4_event'
	self.oasis_one_line_4_event_show = false

	self.is_stage_end = false

	self.bar_sfx = nil

	-- self.is_switch_end = false

	self.get_fx_hit = function()
		return unity_object_pool.GetOrCreate('FX_hit')
	end

	self.drop_items = { }
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent), 'on_complete_switching_party_member_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	self.get_fx_hit()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch()
	start_coroutine(self.directing_start_event, self)
end

--region Event

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_complete_switching_party_member_event(_)
	-- self.is_switch_end = true

	return true
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_enter(e, leader, self.oasis_one_line_4_event_zone_name)
			and not self.oasis_one_line_4_event_show then
		self.oasis_one_line_4_event_show = true
		start_coroutine(self.oasis_one_line_4_event, self)
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_magic_cactus()) then
		start_coroutine(self.magic_cactus_talk, self)
		return true
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'remove_house_item' then
		self:remove_house_item()
		return true
	end

	return false
end

function local_class:on_stage_end_event(_)
	self.is_stage_end = true

	return true
end

function local_class:on_exit_interact_teleport_start_event(e)
	local exit_handle_name = e.ExitHandleName

	if exit_handle_name == 'bar_inner_1' then
		-- 메인 연출 바 입장
		-- 바 입장 효과음 재생 및 sfx 재생
		music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
		start_coroutine(self.play_bar_music, self, true, 0.75)
		return true
	elseif exit_handle_name == 'bar_inner_2' then
		-- 깁미어 드링크 서브 이벤트용 바 입장
		music_player_util.play_sfx_one_shot('01_interact_cakeshop_01')
		start_coroutine(self.play_bar_music, self, false, 0.75)
	elseif exit_handle_name == 'bar_outer_1' or exit_handle_name == 'bar_outer_2' then
		-- 바 sfx 제거
		self:dispose_bar_sfx(2)
		music_player_util.play_stage_music({ state = 'field', mix = 2 })
		return true
	elseif exit_handle_name == 'event_bar_outer' then
		self:dispose_bar_sfx(2)
		return true
	end

	return false
end

--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:play_bar_music(is_play_sfx, sfx_wait_time)
	self:dispose_bar_sfx(0)

	-- bgm 변경
	music_player_util.play_stage_music({ name = 'ondemand/short_story_rosetta/audio:bgm_rosetta_saloon'
	, state = 'event', mix = 2 })

	sfx_wait_time = lua_helper.get_or_default(sfx_wait_time, 0)
	wait_for_sec(sfx_wait_time)

	if is_play_sfx then
		self.bar_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_restaurant_01', loop = true
		, type_priority = 'event', player_priority = 'default' })
	end
end

function local_class:dispose_bar_sfx(fade_time)
	if self.bar_sfx then
		self.bar_sfx:FadeOut(fade_time)
		self.bar_sfx = nil
	end
end

-- 마법의 선인장 원라인
function local_class:magic_cactus_talk()
	local magic_cactus = self.get_magic_cactus()

	music_player_util.play_sfx_one_shot('01_fade_out_03')
	speech_bubble_util.show_speech_bubble(magic_cactus, { key = 'short_story_rt_cactus_oneline_5' })
end

function local_class:directing_start_event()
	--TODO: 문제 생길시 주석 제거
	-- while not self.is_switch_end do
	-- 	coroutine.yield(nil)
	-- end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)
		wait_for_sec(1)

		-- 시작 연출을 한다면 연출
		screen_util.fade_in(0, unity_class.color.black, 'linear')
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position + direction_util.to_vector3(dir),
				leader.Direction, game_string:GetString(stage.Name)))
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	self:set_rosetta_house_item()

	-- 마법의 선인장 아이템 세팅
	local cactus_fo = self.get_magic_cactus()
	local magic_cactus_item = drop_item_util.create_item({
		pos = cactus_fo.Position + unity_class.vector3.forward * 0.3
	, itemid = 20304, notforinven = true, lootstate = 'dontfindlooter' })
	table.insert(self.drop_items, magic_cactus_item)

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if main_quest_progress.IsComplete then
		get_field_object('rosetta_main_tent').ActiveState = active_state('disabled')
		get_field_object('rosetta_room_inner_1').ActiveState = active_state('disabled')
		start_stage_event('right', field:GetMarker('default_start').position, true)
	elseif main_quest_progress.InnerProgress == 0 or main_quest_progress.InnerProgress == 1 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 2 then
		start_stage_event('right', field:GetMarker('default_start').position, true)
	elseif main_quest_progress.InnerProgress == 3 or main_quest_progress.InnerProgress == 4
			or main_quest_progress.InnerProgress == 6 or main_quest_progress.InnerProgress == 7 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 5 then
		-- 5섹션일 때는 중간 저장 값 보고 자동 시작할 지 정한다.
		local save_state = quest_util.get_custom_state(main_quest_progress, self.s6_save_state_key)
		if save_state < 0 then
			-- 저장 값이 없으면 컨트롤 풀리지 않고 섹션내에서 연출
			message_system:Publish(CS.Oak.StageStartEvent.Instance)
		elseif save_state == 1 then
			start_stage_event('right', field:GetMarker('default_start').position, true)
		else
			start_stage_event('right', field:GetMarker('s5_start_point_1').position, true)
		end
	else
		start_stage_event('right', field:GetMarker('default_start').position, true)
	end

	self:one_line_event_setting()

	-- skybox 비활성화
	local skybox = get_field_object('battle_skybox')
	skybox.ActiveState = active_state('disabled')
end

function local_class:set_rosetta_house_item()
	self.rosetta_house_item_list = {}
	local item_info_list = {
		{
			handle_name = 'rosetta_photo_frame',
			item_id = 20854,
			scale = 0.6,
			offset = vector(0, 0.55, 0)
		},
		{
			handle_name = 'rosetta_pocket_watch',
			item_id = 20855,
			scale = 0.9,
			offset = vector(0, 0.55, 0)
		},
		{
			handle_name = 'rosetta_newspaper',
			item_id = 20860,
			scale = 1,
			offset = vector(0, 0.5, 0)
		},
	}

	for i = 1, #item_info_list do
		local item_info = item_info_list[i]
		local fo = get_field_object(item_info.handle_name)
		local item = drop_item_util.create_item({ pos = fo.Position + item_info.offset, sprscale = item_info.scale
		, itemid = item_info.item_id, notforinven = true, lootstate = 'dontfindlooter' })

		item.ShadowTransform.localPosition = vector(0, item_info.offset.y, -0.03)
		table.insert(self.rosetta_house_item_list, item)
	end
end

function local_class:remove_house_item()
	for i = 2, 1, - 1 do
		self.rosetta_house_item_list[i]:ConsumeComplete()
		table.remove(self.rosetta_house_item_list, i)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self:dispose_bar_sfx(0)

	if self.drop_items ~= nil then
		table_util.for_each(self.drop_items, function(key, value)
			value:ConsumeComplete()
		end)

		self.drop_items = nil
	end

	if self.rosetta_house_item_list then
		for i = 1, #self.rosetta_house_item_list do
			self.rosetta_house_item_list[i]:ConsumeComplete()
		end
		self.rosetta_house_item_list = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:can_play_one_line_event(one_line_event_key)
	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)
	local state = quest_util.get_custom_state(main_quest, one_line_event_key)

	return state < 1
end

function local_class:set_complete_one_line_event(one_line_event_key)
	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)
	quest_util.set_custom_state(main_quest, one_line_event_key, 1)
end

-- npc sfx 재생 함수
function local_class:play_npc_sfx_one_shot(sfx_name, parent)
	return music_player_util.play_sfx({ sfx_name = sfx_name, parent = parent, type_priority = 'event', player_priority = 'npc' })
end

function local_class:one_line_event_setting()
	-- 오아시스 원라인 이벤트 3
	local oasis_one_line_3_male_1 = self.get_oasis_one_line_3_male_1()
	local oasis_one_line_3_male_2 = self.get_oasis_one_line_3_male_2()

	local credit_item = drop_item_util.create_item({
		itemid = 20862,
		notforinven = true,
		pos = oasis_one_line_3_male_1.Position + vector(1, 0.5, 0),
		lootstate = 'dontfindlooter',
		showoncharacter = true,
		skip_text = true,
		sprscale = 0.6
	})

	table.insert(self.drop_items, credit_item)

	character_util.spine_set_attachment(oasis_one_line_3_male_1, '[base]weapon1', 'tactical_knife_sword')
	character_util.spine_set_attachment(oasis_one_line_3_male_2, '[base]weapon1', 'tactical_knife_sword')

	-- 서부 남성 1 (right, attack, dagger_idle) : 손가락 사이를 더 많이 찍는 사람이 모두 가져간다. 준비됐어?
	self:play_npc_sfx_one_shot('02_knife_attack_01', oasis_one_line_3_male_1)
	character_util.set_emotion(oasis_one_line_3_male_1, {name = 'attack'})
	character_util.set_anim(oasis_one_line_3_male_1, {name = 'dagger_idle', loop = true})
	oasis_one_line_3_male_1.Interactable.Talk = 'short_story_rt_oasis_oneline_3_1'
	oasis_one_line_3_male_1.Interactable.TalkSfx = '02_knife_attack_01'

	-- 서부 남성 2 (left, smile, dagger_idle) : 자신있어? 저번에 한번 날릴뻔 하지 않았나?
	self:play_npc_sfx_one_shot('01_fade_out_03', oasis_one_line_3_male_2)
	character_util.set_emotion(oasis_one_line_3_male_2, {name = 'smile'})
	character_util.set_anim(oasis_one_line_3_male_2, {name = 'dagger_idle', loop = true})
	oasis_one_line_3_male_2.Interactable.Talk = 'short_story_rt_oasis_oneline_3_2'
	oasis_one_line_3_male_2.Interactable.TalkSfx = '01_fade_out_03'

	-- 오아시스 원라인 이벤트 4
	local oasis_one_line_4_male_1 = self.get_oasis_one_line_4_male_1()
	local oasis_one_line_4_female_1 = self.get_oasis_one_line_4_female_1()
	local oasis_one_line_4_kid_1 = self.get_oasis_one_line_4_kid_1()
	character_util.set_emotion(oasis_one_line_4_kid_1, {name = 'attack'})
	character_util.set_anim(oasis_one_line_4_kid_1, {name = 'success', loop = true})
	character_util.spine_set_attachment(oasis_one_line_4_kid_1, '[base]weapon2', 'magi_times')

	-- 오아시스 원라인 이벤트 5
	-- 서부 남성 1 (right, doyagao, handgun_idle) : 높게 들어. 머리랑 헷갈리지 않게 말이야.
	local oasis_one_line_5_male_1 = self.get_oasis_one_line_5_male_1()
	character_util.spine_set_attachment(oasis_one_line_5_male_1, '[base]weapon1', 'basic_handgun')
	character_util.set_emotion(oasis_one_line_5_male_1, {name = 'doyagao'})
	character_util.set_anim(oasis_one_line_5_male_1, {name = 'dualgun_idle', loop = true})
	oasis_one_line_5_male_1.Interactable.Talk = 'short_story_rt_oasis_oneline_5_1'
	oasis_one_line_5_male_1.Interactable.TalkSfx = '02_gun_reload_02'

	-- 서부 남성 2 (left, scared, cast2) : 미, 미안해! 돈 갚을 테니까 제발 용서해 줘!!
	local oasis_one_line_5_male_2 = self.get_oasis_one_line_5_male_2()
	character_util.set_emotion(oasis_one_line_5_male_2, {name = 'scared'})
	character_util.set_anim(oasis_one_line_5_male_2, {name = 'cast2', loop = true})
	oasis_one_line_5_male_2.Interactable.Talk = 'short_story_rt_oasis_oneline_5_2'
	oasis_one_line_5_male_2.Interactable.TalkSfx = '03_dialogue_sadness_01'

	local apple_pos = oasis_one_line_5_male_2.Position + vector(0, 0, 0.9)
	local apple_item = drop_item_util.create_item({
		itemid = 20865,
		notforinven = true,
		pos = apple_pos,
		lootstate = 'dontfindlooter',
		showoncharacter = true,
		skip_text = true
	})

	table.insert(self.drop_items, apple_item)

	self.oasis_one_line_4_event_show = not self:can_play_one_line_event(self.oasis_one_line_4_event_key)

	-- 이미 본 원라인 이벤트 셋팅
	if self.oasis_one_line_4_event_show then
		oasis_one_line_4_male_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_2'
		oasis_one_line_4_female_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_3'
		oasis_one_line_4_kid_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_1'

		character_util.set_direction(oasis_one_line_4_male_1, 'right')
		character_util.spine_set_attachment(oasis_one_line_4_male_1, '[base]weapon1', 'magi_times')
		character_util.set_emotion(oasis_one_line_4_male_1, {name = 'tired'})
		character_util.set_anim(oasis_one_line_4_male_1, {name = 'bow_idle', loop = true})
		character_util.set_direction(oasis_one_line_4_female_1, 'left')
		character_util.set_emotion(oasis_one_line_4_female_1, {name = 'tired'})
		character_util.set_anim(oasis_one_line_4_female_1, {name = 'bomb_idle', loop = true})
		character_util.set_emotion(oasis_one_line_4_kid_1, {name = 'attack'})
	end
end

function local_class:oasis_one_line_4_event()
	local oasis_one_line_4_male_1 = self.get_oasis_one_line_4_male_1()
	local oasis_one_line_4_female_1 = self.get_oasis_one_line_4_female_1()
	local oasis_one_line_4_kid_1 = self.get_oasis_one_line_4_kid_1()
	local paper_key = 'paper'

	-- 꼬마(남) (right, attack , attack) : 특종이에요! 특종! 주점에서 난동이 벌어졌어요!
	character_util.set_emotion(oasis_one_line_4_kid_1, {name = 'attack'})
	character_util.set_anim(oasis_one_line_4_kid_1, {name = 'success', loop = true})

	local throw_func = function()
		local kid = oasis_one_line_4_kid_1
		local male = oasis_one_line_4_male_1

		if self.is_stage_end then
			return
		end

		local news_paper_item = drop_item_util.create_item({
			itemid = 20860,
			notforinven = true,
			pos = kid.Position,
			lootstate = 'dontfindlooter',
			showoncharacter = true,
			skip_text = true
		})

		self.drop_items[paper_key] = news_paper_item

		character_util.spine_remove_attachment(kid, '[base]weapon2')

		self:play_npc_sfx_one_shot('01_turn_page_02', oasis_one_line_4_kid_1)
		drop_item_util.throw_item(news_paper_item, male.Position + vector(0.5, 0, -0.5), {rotate_num = 3})
	end

	wait_all({
		util.cs_generator(
				throw_func, self),
		util.cs_generator(speech_bubble_util.show_speech_bubble_async,
				oasis_one_line_4_kid_1, { key = 'short_story_rt_oasis_oneline_4_1' }),
		util.cs_generator(wait_for_sec, 0.5)
	})

	if self.is_stage_end then
		return
	end

	-- 꼬마(남)의 대사가 끝나면, 남자 NPC가 right 방향 전환 하며 손에 신문 아이템이 들려짐. (예시 이미지)
	character_util.set_direction(oasis_one_line_4_male_1, 'right')

	wait_for_sec(0.5)

	if self.is_stage_end then
		return
	end

	if self.drop_items ~= nil and self.drop_items[paper_key] ~= nil then
		self.drop_items[paper_key].ConsumeTarget = oasis_one_line_4_male_1
		self.drop_items[paper_key]:Fly()
		self.drop_items[paper_key] = nil
	end

	wait_for_sec(0.5)

	if self.is_stage_end then
		return
	end

	character_util.spine_set_attachment(oasis_one_line_4_male_1, '[base]weapon1', 'magi_times')

	-- 남자 (right, tired ,bow_idle) : 흠… 요즘 따라 치안이 영 말이 아니군.
	self:play_npc_sfx_one_shot('01_turn_page_01', oasis_one_line_4_male_1)
	character_util.set_emotion(oasis_one_line_4_male_1, {name = 'tired'})
	character_util.set_anim(oasis_one_line_4_male_1, {name = 'bow_idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(oasis_one_line_4_male_1, {key = 'short_story_rt_oasis_oneline_4_2'})
	if self.is_stage_end then
		return
	end

	-- 여자 (left, tired ,bomb_idle) : 조만간 다른 곳으로 떠나는 게 좋겠어요.
	self:play_npc_sfx_one_shot('01_sigh_01', oasis_one_line_4_female_1)
	character_util.set_direction(oasis_one_line_4_female_1, 'left')
	character_util.set_emotion(oasis_one_line_4_female_1, {name = 'tired'})
	character_util.set_anim(oasis_one_line_4_female_1, {name = 'bomb_idle', loop = true})
	speech_bubble_util.show_speech_bubble_async(oasis_one_line_4_female_1, {key = 'short_story_rt_oasis_oneline_4_3'})
	if self.is_stage_end then
		return
	end

	-- 마지막 원라인 셋팅
	oasis_one_line_4_male_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_2'
	oasis_one_line_4_female_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_3'
	oasis_one_line_4_kid_1.Interactable.Talk = 'short_story_rt_oasis_oneline_4_1'

	self:set_complete_one_line_event(self.oasis_one_line_4_event_key)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
