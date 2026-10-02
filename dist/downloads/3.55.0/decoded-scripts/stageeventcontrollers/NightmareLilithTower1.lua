local local_class = newclass('NightmareLilithTower1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- scene_util 버전
	self.scene_version = scene_util.default_version

	self.stage_ended = false

	self.main_quest_id = 380

	self.get_vloger = function ()
		return get_character('vloger')
	end

	self.get_buddy = function ()
		return get_character('buddy')
	end

	self.epilogue_data = {
		secretary =
			{
				zone = 'secretary_event',
				entered = false,
				cb = self.secretary_scene
			},
		vloger =
			{
				zone = 'vloger_event',
				entered = false,
				cb = self.vloger_scene
			},
		buddy =
			{
				zone = 'buddy_event',
				entered = false,
				cb = self.buddy_scene
			},
		carpenter =
			{
				zone = 'carpenter_event',
				entered = false,
				cb = self.carpenter_scene
			},
	}

	self.item = {
		madeleine = nil,
		selfie_stick = nil,
		book_1 = nil,
		book_2 = nil,
		dispose_all = function(this)
			for name, item in pairs(this) do
				if name ~= 'dispose_all' then
					if item ~= nil then
						drop_item_util.dispose_item(item)
						item = nil
					end
				end
			end
		end
	}

	self.interactable_buddy = false
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	self.item:dispose_all()

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
end

--region load_resource
function local_class:load_resource()
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
	if lua_helper.reference_equals(e.Target, self.get_buddy()) and self.interactable_buddy then
		self.interactable_buddy = false
		start_coroutine(self.interact_buddy, self)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	for _,data in pairs(self.epilogue_data) do
		if type_util.is_zone_full_enter(e, get_party_leader(), data.zone) and
				not data.entered then
			data.entered = true
			start_coroutine(data.cb, self)
		end

	end
end

function local_class:on_stage_end_event()
	self.stage_ended = true
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

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	-- 1스테이지 npc들 세팅
	self:set_epilogue_npcs()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			false, false)
		quest_marker_util.add_auto_control('main_quest', {})
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			true, true)
		quest_marker_util.add_auto_control('main_quest', {})
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			true, true)
		quest_marker_util.add_auto_control('main_quest', {})
	elseif quest_progress.InnerProgress == 3 and not user_progress:IsStageCleared(stage.Name) then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
		quest_marker_util.add_auto_control('main_quest', {
			{ zone = 'main_field', target = get_field_object('office_inner') },
			{ zone = 'office_field', target = get_field_object('exit_nightmare_lilithtower_2') },
		})
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 후일담 npc 세팅
function local_class:set_epilogue_npcs()
	--region 비서 관련
	local civil = { get_character('secretary_civil_1'), get_character('secretary_civil_2'),
					get_character('secretary_civil_3'), get_character('secretary_civil_4'),
	}
	local secretary_quest = user_progress:GetStartedQuest(258)
	local secretary_state_key = 'safe_house_secretary'
	if secretary_quest ~= nil and quest_util.get_custom_state(secretary_quest, secretary_state_key) == 1 then
		character_util.set_active_state(get_character('secretary'), 'disabled')

		character_util.set_anim(civil[1], { name = 'question', loop = false })
		character_util.set_emotion(civil[2], { name = 'tired' })
		character_util.set_anim_and_emotion(civil[4], { name = 'cast' }, { name = 'tired' })

		civil[1].Interactable.Talk = 'nightmare_lt_stage1_sub_32'
		civil[1].Interactable.TalkSfx = '01_rustle_01'

		civil[2].Interactable.Talk = 'nightmare_lt_stage1_sub_33'
		civil[2].Interactable.TalkSfx = '03_dialogue_bad_01'

		civil[3].Interactable.Talk = 'nightmare_lt_stage1_sub_34'
		civil[3].Interactable.TalkSfx = '01_swing_01'

		civil[4].Interactable.Talk = 'nightmare_lt_stage1_sub_35'
		civil[4].Interactable.TalkSfx = '03_dialogue_sadness_01'
	else
		self.epilogue_data.secretary.cb = self.secretary_rescue_scene
		character_util.set_active_state(get_character('new_secretary'), 'disabled')

		character_util.set_anim(civil[1], { name = 'push' })
		character_util.set_anim_and_emotion(civil[2], { name = 'push' }, { name = 'smile' })
		character_util.set_anim(civil[3], { name = 'question', loop = false })
		character_util.set_anim_and_emotion(civil[4], { name = 'cast' }, { name = 'smile' })

		civil[1].Interactable.Talk = 'nightmare_lt_stage1_sub_28'
		civil[1].Interactable.TalkSfx = '01_turn_page_01'

		civil[2].Interactable.Talk = 'nightmare_lt_stage1_sub_29'
		civil[2].Interactable.TalkSfx = '01_turn_page_02'

		civil[3].Interactable.Talk = 'nightmare_lt_stage1_sub_30'
		civil[3].Interactable.TalkSfx = '01_rustle_01'

		civil[4].Interactable.Talk = 'nightmare_lt_stage1_sub_31'
		civil[4].Interactable.TalkSfx = '03_dialogue_positive_01'

		local book_1_pos = civil[1].Position + vector(0.3, 0.3, 0)
		local book_2_pos = civil[2].Position + vector(-0.3, 0.3, 0)
		self.item.book_1 = drop_item_util.create_item({ pos = book_1_pos,
			                                        itemid = 21119, notforinven = true,
													sprscale = 1,
													lootstate = 'dontfindlooter',
													skip_text = true })
		self.item.book_2 = drop_item_util.create_item({ pos = book_2_pos,
			                                        itemid = 21119, notforinven = true,
													sprscale = 1,
													lootstate = 'dontfindlooter',
													skip_text = true })

		self.item.book_1.ShadowTransform.gameObject:SetActive(false)
		self.item.book_2.ShadowTransform.gameObject:SetActive(false)
	end
	-- endregion 비서 관련

	--region 브이로그 관련
	local vlog_quest = user_progress:GetStartedQuest(273)
	if vlog_quest ~= nil and vlog_quest.IsComplete then
		self.epilogue_data.vloger.cb = self.vloger_rescue_scene

		local vloger = self.get_vloger()
		character_util.set_anim_and_emotion(vloger,
				{ name = 'seat' }, { name = 'smile' })
		self:set_selfie_stick()

		character_util.set_active_state(get_character('vloger_female'), 'disabled')
		character_util.set_active_state(get_character('vloger_male'), 'disabled')
	else
		character_util.set_active_state(self.get_vloger(), 'disabled')

		character_util.set_anim_and_emotion(get_character('vloger_female'),
				{ name = 'seat' }, { name = 'smile' })
		character_util.set_anim_and_emotion(get_character('vloger_male'),
				{ name = 'seat' }, { name = 'smile' })
	end

	local madeleine_pos = field_util.get_marker_pos('madeleine_pos') + vector(0, 0.5, 0)
	self.item.madeleine = drop_item_util.create_item({ pos = madeleine_pos,
		                                        itemid = 21116, notforinven = true,
												sprscale = 1,
												lootstate = 'dontfindlooter',
												skip_text = true })
	-- endregion 브이로그 관련

	--region 버디 관련
	local buddy_quest = user_progress:GetStartedQuest(270)
	if buddy_quest ~= nil and buddy_quest.IsComplete then
		self.epilogue_data.buddy.cb = self.buddy_rescue_scene
		character_util.set_emotion(get_character('buddy_civil_2'), { name = 'smile' })
		get_character('buddy_civil_1').Hitbox = CS.Oak.Hitbox(vector(0.6, 0.75, 1.1))
		get_character('buddy_civil_2').Hitbox = CS.Oak.Hitbox(vector(0.6, 0.75, 1.1))
		get_character('buddy').Hitbox = CS.Oak.Hitbox(vector(0.6, 0.75, 1.1))
	else
		character_util.set_active_state(get_character('buddy_civil_1'), 'disabled')
		character_util.set_active_state(get_character('buddy_civil_2'), 'disabled')
		character_util.set_active_state(self.get_buddy(), 'disabled')
		character_util.set_anim(get_character('buddy_interviewer'), { name = 'question', loop = false })
	end
	-- endregion 버디 관련

	music_player_util.play_sfx({ sfx_name = '01_crowd_buzz_02', parent = get_character('oneline_npc_25'),
			type_priority = 'event', loop = true, player_priority = 'npc',
			volume = 0.5, max_distance = 6, min_distance = 4 })
end

-- 비서 구출 후일담
function local_class:secretary_rescue_scene()
	local secretary = get_character('secretary')
	local architect = get_character('architect')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', loop = false, parent = secretary })
	scene_util.set_emotion(secretary, self, 'attack')
	scene_util.set_anim(secretary, self, 'release')
	-- 키츠라기 씨! 이번 달 내로 타워 보안 시스템을 철저히 강화 해주세요!
	speech_bubble_util.show_speech_bubble_async(secretary, { key = 'nightmare_lt_stage1_sub_1' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = secretary })
	scene_util.set_emotion(secretary, self, 'tired')
	scene_util.set_anim(secretary, self, 'cast')
	-- 저번과 같은 일이 두번 다시 생겨서는 안되니까요…
	speech_bubble_util.show_speech_bubble_async(secretary, { key = 'nightmare_lt_stage1_sub_2' })
	character_util.remove_anim_and_emotion(secretary)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = architect })
	scene_util.set_anim(architect, self, { name = 'nod', count = 1, sfx_name = false })
	-- 네, 비서실장님. 명심하겠습니다.
	speech_bubble_util.show_speech_bubble_async(architect, { key = 'nightmare_lt_stage1_sub_3' })

	secretary.Interactable.Talk = 'nightmare_lt_stage1_sub_2'
	secretary.Interactable.TalkSfx = '01_rustle_01'
	architect.Interactable.Talk = 'nightmare_lt_stage1_sub_3'
	architect.Interactable.TalkSfx = '01_rustle_01'
end

-- 비서 구출x 후일담
function local_class:secretary_scene()
	local secretary = get_character('new_secretary')
	local architect = get_character('architect')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', loop = false, parent = secretary })
	scene_util.set_anim(secretary, self, 'release')
	-- 타워의 보안 시스템을 강화하라는 각하의 말씀이 있었습니다.
	speech_bubble_util.show_speech_bubble_async(secretary, { key = 'nightmare_lt_stage1_sub_4' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = secretary })
	scene_util.set_emotion(secretary, self, 'tired')
	scene_util.set_anim(secretary, self, 'cast')
	-- …순직하신 에리스 선배를 위해서라도, 다시는 이런 일이 생겨선 안됩니다.
	speech_bubble_util.show_speech_bubble_async(secretary, { key = 'nightmare_lt_stage1_sub_5' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = architect })
	scene_util.set_anim(architect, self, { name = 'nod', count = 1, sfx_name = false })
	-- 네, 책임지고 강화하도록 하겠습니다.
	speech_bubble_util.show_speech_bubble_async(architect, { key = 'nightmare_lt_stage1_sub_6' })

	secretary.Interactable.Talk = 'nightmare_lt_stage1_sub_5'
	secretary.Interactable.TalkSfx = '01_rustle_01'
	architect.Interactable.Talk = 'nightmare_lt_stage1_sub_6'
	architect.Interactable.TalkSfx = '01_rustle_01'
end

-- 브이로거 구출 후일담
function local_class:vloger_rescue_scene()
	local vloger = self.get_vloger()

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', loop = false, parent = vloger })
	-- 여러분~ 안녕! 뉴튜버 큐블리에요!
	speech_bubble_util.show_speech_bubble_async(vloger, { key = 'nightmare_lt_stage1_sub_7' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', loop = false, parent = vloger })
	-- 오늘은 리리스 타워의 인기 상품, 최고급 마들렌 먹방을 해볼거에요!
	speech_bubble_util.show_speech_bubble_async(vloger, { key = 'nightmare_lt_stage1_sub_8' })

	if self.stage_ended then
		return
	end

	local eat_loop = music_player_util.play_sfx({ sfx_name = '01_eat_01', loop = true, parent = vloger })
	scene_util.set_anim(vloger, self, 'eat')
	drop_item_util.shake(self.item.madeleine, 'madeleine', 0.03, 1)
	self:resize_item_async(self.item.madeleine, 0.01, 1)

	drop_item_util.cancel_shake(self.item.madeleine, 'madeleine')
	drop_item_util.dispose_item(self.item.madeleine)
	self.item.madeleine = nil

	if self.stage_ended then
		return
	end

	eat_loop:FadeOut(0)
	eat_loop = nil

	character_util.set_emotion(vloger, { name = 'surprise' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_notice_01', loop = false, parent = vloger })

	character_util.set_anim_time_scale(vloger, 0)
	character_util.show_emoticon_async(vloger, nil, 'notice')
	character_util.set_anim_time_scale(vloger, 1)

	character_util.set_anim(vloger, { name = 'seat' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', loop = false, parent = vloger })
	-- 이, 이맛은?! 겉은 바삭하고 안은 달콤 촉촉…! 완전 최고에요!
	speech_bubble_util.show_speech_bubble_async(vloger, { key = 'nightmare_lt_stage1_sub_9' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', loop = false, parent = vloger })
	scene_util.set_emotion(vloger, self, 'awesome')
	-- 역시 리리스 타워의 명물 답네요~!
	speech_bubble_util.show_speech_bubble_async(vloger, { key = 'nightmare_lt_stage1_sub_10' })

	vloger.Interactable.Talk = 'nightmare_lt_stage1_sub_10'
	vloger.Interactable.TalkSfx = '01_bad_fairy_01'
end

-- 브이로거 구출x 후일담
function local_class:vloger_scene()
	local civil_1 = get_character('vloger_female')
	local civil_2 = get_character('vloger_male')

	local eat_loop = music_player_util.play_sfx({ sfx_name = '01_eat_01', loop = true, parent = civil_1 })

	scene_util.set_anim(civil_1, self, 'eat')
	drop_item_util.shake(self.item.madeleine, 'madeleine', 0.03, 1)
	self:resize_item_async(self.item.madeleine, 0.01, 1)

	drop_item_util.cancel_shake(self.item.madeleine, 'madeleine')
	drop_item_util.dispose_item(self.item.madeleine)
	self.item.madeleine = nil

	if self.stage_ended then
		return
	end

	eat_loop:FadeOut(0)
	eat_loop = nil

	character_util.remove_anim(civil_1)
	wait_for_sec(0.5)

	scene_util.set_emotion(civil_1, self, 'awesome')
	scene_util.set_direction(civil_1, 'down')
	scene_util.set_direction(civil_2, 'up')

	music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', loop = false, parent = civil_1 })
	-- 자기야, 이 마들렌 진짜 맛있다!
	speech_bubble_util.show_speech_bubble_async(civil_1, { key = 'nightmare_lt_stage1_sub_11' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', loop = false, parent = civil_2 })
	-- 그치? 괜히 인기 상품이 아니라니까!
	speech_bubble_util.show_speech_bubble_async(civil_2, { key = 'nightmare_lt_stage1_sub_12' })

	civil_1.Interactable.Talk = 'nightmare_lt_stage1_sub_11'
	civil_1.Interactable.TalkSfx = '01_bad_fairy_01'

	civil_2.Interactable.Talk = 'nightmare_lt_stage1_sub_12'
	civil_2.Interactable.TalkSfx = '03_dialogue_positive_01'
end

-- 인부 후일담
function local_class:carpenter_scene()
	local carpenter_1 = get_character('bridge_carpenter_1')
	local carpenter_2 = get_character('bridge_carpenter_2')
	local civil_1 = get_character('bridge_civil_1')
	local civil_2 = get_character('bridge_civil_2')

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', loop = false, parent = civil_1 })
	character_util.normal_jump(civil_1)
	-- 그게 무슨 소리에요?! 구름 다리가 공사중이라뇨!
	speech_bubble_util.show_speech_bubble_async(civil_1, { key = 'nightmare_lt_stage1_sub_13' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', loop = false, parent = civil_2 })
	scene_util.set_anim(civil_2, self, { name = 'release', count = 2 })
	-- 다리에서 사진 찍으려고 일부러 여기까지 왔는데…!
	speech_bubble_util.show_speech_bubble_async(civil_2, { key = 'nightmare_lt_stage1_sub_14' })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = carpenter_1 })
	-- 최근 테러 사건 때문에 구름 다리가 무너져서 재건중입니다.
	speech_bubble_util.show_speech_bubble_async(carpenter_1, { key = 'nightmare_lt_stage1_sub_15', bubble_direction = 'lb' })

	if self.stage_ended then
		return
	end

	scene_util.set_anim(carpenter_2, self, { name = 'release', count = 2 })
	-- 당분간은 왼쪽에 있는 비상구를 통해 이동해주세요.
	speech_bubble_util.show_speech_bubble_async(carpenter_2, { key = 'nightmare_lt_stage1_sub_16', bubble_direction = 'rb' })

	civil_1.Interactable.Talk = 'nightmare_lt_stage1_sub_13'
	civil_1.Interactable.TalkSfx = '01_male_shout_01'
	civil_2.Interactable.Talk = 'nightmare_lt_stage1_sub_14'
	civil_2.Interactable.TalkSfx = '03_dialogue_sadness_01'
end

-- 버디 구출 후일담
function local_class:buddy_rescue_scene()
	local civil_1 = get_character('buddy_civil_1')
	local civil_2 = get_character('buddy_civil_2')
	local buddy = self.get_buddy()
	local interviewer = get_character('buddy_interviewer')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', loop = false, parent = civil_2 })
	-- 실례지만, 이번에 이 회사에 지원 했는데… 혹시 결과가 어떻게 됐나요?
	speech_bubble_util.show_speech_bubble_async(civil_2, { key = 'nightmare_lt_stage1_sub_17' })

	wait_for_sec(0.5)
	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = interviewer })
	scene_util.set_anim(interviewer, self, 'question')
	-- 말씀해주신 지원서를 계속 찾아봤지만…
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_18' })

	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = interviewer })
	scene_util.set_anim(interviewer, self, 'bomb_idle')
	-- 헤스텔라 씨의 이력서는 보이지 않더군요.
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_18_1' })

	character_util.remove_anim(interviewer)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', loop = false, parent = civil_1 })
	character_util.remove_anim(civil_2)
	character_util.normal_jump(civil_1)
	scene_util.set_emotion(civil_1, self, 'attack')
	scene_util.set_emotion(civil_2, self, 'surprise')
	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '01_male_shout_01', loop = false, parent = civil_1 })
	scene_util.set_anim(civil_1, self, 'release')
	-- 그게 무슨 소리에요! 분명히 이력서를 제 손으로 낸 걸 확인까지 했는데…!
	speech_bubble_util.show_speech_bubble_async(civil_1, { key = 'nightmare_lt_stage1_sub_19' })
	character_util.remove_anim_and_emotion(civil_1)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = interviewer })
	scene_util.set_anim(interviewer, self, 'cast')
	scene_util.set_emotion(interviewer, self, 'tired')
	-- 저번 테러 사건의 여파로 인해 입사지원서가 모두 파손된 것으로 보입니다. 
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_20' })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_bad_01', loop = false, parent = interviewer })
	-- 정말 유감이에요…
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_20_1' })
	character_util.remove_anim(interviewer)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = interviewer })
	-- 차후 새 공고를 올릴테니, 그 때 다시 지원 부탁드립니다.
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_21' })
	character_util.remove_emotion(interviewer)

	interviewer.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	wp_util.move_async(interviewer,
			{
				interviewer.Position + vector(-1, 0, 0),
				interviewer.Position + vector(-1, 0, 2),
			}, 3, nil, { last_direction = 'right' })
	scene_util.set_anim(interviewer, self, 'eat')
	interviewer.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', loop = false, parent = civil_2 })
	scene_util.set_anim(civil_2, self, 'cast')
	scene_util.set_emotion(civil_2, self, 'tired')
	-- 꼭 이 회사에 붙고 싶었는데…
	speech_bubble_util.show_speech_bubble_async(civil_2, { key = 'nightmare_lt_stage1_sub_22' })
	character_util.remove_anim(civil_2)

	civil_2.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	start_coroutine(function()
		wp_util.move_async(civil_2,
				{
					civil_2.Position + vector(0, 0, 1),
					civil_2.Position + vector(9, 0, 1),
					civil_2.Position + vector(9, 0, 3),
				}, 3, nil, { last_direction = 'left' })
		scene_util.set_anim(civil_2, self, 'seat')
		civil_2.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	end)

	wait_for_sec(1)

	if self.stage_ended then
		return
	end

	scene_util.set_direction(civil_1, 'right')
	wait_for_sec(1)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = civil_1 })
	scene_util.set_anim(civil_1, self, 'question')
	scene_util.set_emotion(civil_1, self, 'tired')
	-- 쳇… 이럴 줄 알았으면 합격자 명단에 이름이라도 넣을 걸 그랬나.
	speech_bubble_util.show_speech_bubble_async(civil_1, { key = 'nightmare_lt_stage1_sub_22_1', scale = 0.7 })

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_pet_bark_01', loop = false, parent = buddy })
	scene_util.set_anim(buddy, self, 'victory_extra')
	character_util.show_emoticon_async(buddy, nil, 'rowdy')
	character_util.remove_anim(buddy)
	character_util.remove_anim_and_emotion(civil_1)

	civil_1.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance

	wp_util.move(civil_1,
			{
				civil_1.Position + vector(0, 0, 1),
				civil_1.Position + vector(6, 0, 1),
				civil_1.Position + vector(6, 0, 3),
			}, 3, nil, { last_direction = 'right' })

	wait_for_sec(1)

	buddy.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	wp_util.move_async(buddy,
			{
				buddy.Position + vector(0, 0, 1),
				buddy.Position + vector(5, 0, 1),
				buddy.Position + vector(5, 0, 2),
			}, 3, nil, { last_direction = 'right' })

	scene_util.set_emotion(civil_1, self, 'tired')
	buddy.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	civil_1.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	interviewer.Interactable.Talk = 'nightmare_lt_stage1_sub_22_3'
	interviewer.Interactable.TalkSfx = '03_equipping_01'

	civil_1.Interactable.Talk = 'nightmare_lt_stage1_sub_22_2'
	civil_1.Interactable.TalkSfx = '01_rustle_01'

	civil_2.Interactable.Talk = 'nightmare_lt_stage1_sub_22'
	civil_2.Interactable.TalkSfx = '03_dialogue_sadness_01'

	character_util.add_listener(buddy, self.cs_controller)
	self.interactable_buddy = true
end

-- 버디 구출x 후일담
function local_class:buddy_scene()
	local interviewer = get_character('buddy_interviewer')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', loop = false, parent = interviewer })
	scene_util.set_emotion(interviewer, self, 'tired')
	-- 이번 사건 이후로 우리 엠프리스 패션 회사의 재정적 손실이 막대해요.
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_23' })

	character_util.remove_anim(interviewer)
	-- 바로 일할 수 있는 새 직원들을 뽑을 준비를 해야겠어요.
	speech_bubble_util.show_speech_bubble_async(interviewer, { key = 'nightmare_lt_stage1_sub_24' })

	interviewer.Interactable.Talk = 'nightmare_lt_stage1_sub_24'
end

function local_class:resize_item_async(item, end_scale, duration)
	local start_scale = item.SpriteTransform.localScale.x

	local time_passed = 0
	while time_passed < duration and not self.stage_ended do
		local progress = time_passed / duration
		item.SpriteTransform.localScale = unity_class.vector3.one * unity_class.mathf.Lerp(start_scale, end_scale, progress)
		item.ShadowTransform.localScale = unity_class.vector3.one * unity_class.mathf.Lerp(start_scale, end_scale, progress)
		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield(nil)
	end

	item.SpriteTransform.localScale = unity_class.vector3.one * end_scale
	item.ShadowTransform.localScale = unity_class.vector3.one * end_scale
end

function local_class:interact_buddy()
	music_player_util.play_sfx({ sfx_name = '01_pet_bark_01', loop = false, parent = self.get_buddy() })
	character_util.show_emoticon_async(self.get_buddy(), nil, 'rowdy')
	self.interactable_buddy = true
end

function local_class:set_selfie_stick()
		local vloger = self.get_vloger()
		self.item.selfie_stick = drop_item_util.create_item({ pos = vloger.Position + vector(0.45, 0.55, 0),
		itemid = 21117, notforinven = true, sprscale = 1,
		lootstate = 'dontfindlooter', skip_text = true, showoncharacter = true })
		self.item.selfie_stick.ShadowTransform.gameObject:SetActive(false)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
