local local_class = newclass('DemonShire3At5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end
	-- 소히 가져오기
	self.get_sohee = function()
		return get_character('sohee')
	end
	-- 백작 딸 가져오기
	self.get_count_daughter = function()
		return get_character('count_daughter')
	end
	-- 이벤트 몬스터 가져오기
	self.get_event_monster = function(idx)
		return get_character('lab_1_battle_' .. idx)
	end
	-- s20 과학자들 가져오기
	self.get_iris_lab_researcher = function(idx)
		return get_character('s20_lab_researcher_' .. idx)
	end
	self.get_lab_lobby_researcher = function(idx)
		return get_character('lab_lobby_researcher_' .. idx)
	end

	-- 컨트롤 패널 가져오기
	self.get_iris_control_panel = function()
		return get_field_object('iris_control_panel')
	end
	-- 카드키 리더 계단 가져오기
	self.get_a_room_down_stair = function()
		return get_field_object('a_room_down_stair')
	end
	-- 일반 카드키 문 가져오기
	self.get_card_key_door = function(idx)
		return get_field_object('card_key_door_' .. idx)
	end
	-- 카드키 리더 중앙 문 가져오기
	self.get_card_key_main_door = function(idx)
		return get_field_object('card_key_main_door_' .. idx)
	end
	-- 로비 문 가져오기
	self.get_lobby_door = function()
		return get_field_object('lobby_door')
	end

	self.main_stair_interactable = nil

	-- 카드키 콘솔 상호작용 하면 열리는 문 정보
	self.card_key = {
		card_key_console_1 = {
			-- 열리는 fo handle name 이름
			opening_fo_name = 'card_key_door_1',
			-- 정렬 방향
			align_dir = 'down',
			offset = vector(0, 0, 0.25)
		},
		card_key_console_3 = {
			opening_fo_name = 'card_key_door_3',
			align_dir = 'left',
			offset = vector(0.25, 0, 0)
		}
	}

	self.get_card_key_console = {
		card_key_door_1 = 'card_key_console_1',
		card_key_door_3 = 'card_key_console_3'
	}

	self.get_lobby_gate = function()
		return {
			get_field_object('main_front_gate_1'),
			get_field_object('main_front_gate_2')
		}
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	--region 공대 개그 SNS 이벤트
	-- sns id
	self.sns_follower_id = 64

	-- script
	self.engineer_comedy_script = 'ds_engineer_comedy_'
	-- npc
	self.get_comedian = function()
		return get_character('engineer_comedian')
	end

	self.get_audience = function(number)
		return get_character('engineer_audience_' .. number)
	end

	--field object
	self.get_chair = function()
		return get_field_object('invisible_engineer_chair')
	end
	--endregion

	--region 원라인 관련
	-- get_lab_lobby_researcher_(1-10)번까지 19섹션 원라인 설정 데이터
	self.oneline_s19_data = {
		{
			anim = { name = 'cross_arm' },
			emo = { name = 'tired' },
			talk = 'ds_main_s19_oneline_10'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'idle' },
			talk = 'ds_main_s19_oneline_11'
		},
		{
			anim = { name = 'bomb_idle' },
			emo = { name = 'tired' },
			talk = 'ds_main_s19_oneline_12'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'idle' },
			talk = 'ds_main_s19_oneline_13'
		},
		{
			anim = { name = 'cross_arm' },
			emo = { name = 'idle' },
			talk = 'ds_main_s19_oneline_14'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'smile' },
			talk = 'ds_main_s19_oneline_15'
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'damaged' },
			talk = 'ds_main_s19_oneline_16'
		},
		{
			anim = { name = 'sing' },
			emo = { name = 'smile' },
			talk = 'ds_main_s19_oneline_17'
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'tired' },
			talk = 'ds_main_s19_oneline_18'
		},
		{
			anim = { name = 'cast2' },
			emo = { name = 'attack' },
			talk = 'ds_main_s19_oneline_19'
		}
	}
	-- get_lab_lobby_researcher_(1-10)번까지 22섹션 원라인 설정 데이터
	self.oneline_s22_data = {
		{
			anim = { name = 'cross_arm' },
			emo = { name = 'tired' },
			talk = 'ds_main_s22_oneline_3'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'tired' },
			talk = 'ds_main_s22_oneline_4'
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'scared' },
			talk = 'ds_main_s22_oneline_5'
		},
		{
			anim = { name = 'cross_arm' },
			emo = { name = 'tired' },
			talk = 'ds_main_s22_oneline_6'
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'surprise' },
			talk = 'ds_main_s22_oneline_7'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'scared' },
			talk = 'ds_main_s22_oneline_8'
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'tired' },
			talk = nil
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'surprise' },
			talk = nil
		},
		{
			anim = { name = 'cast' },
			emo = { name = 'tired' },
			talk = 'ds_main_s22_oneline_9'
		},
		{
			anim = { name = 'idle' },
			emo = { name = 'damaged' },
			talk = 'ds_main_s22_oneline_10'
		},
	}

	self.can_play_lab_lobby_event = false
	self.lab_lobby_event_played = false
	--endregion

	self.gate_opening_status = {
		card_key_door_1 = false,
		card_key_door_2 = false,
		card_key_door_3 = false
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	-- 무조건 on_launch 런치에서 제어
	--TODO: 개발 상황에 따라 다르게 할 수도 있음
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

--region Event

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local leader = user_party.Leader

	if type_util.is_zone_full_enter(e, leader, 's20_door_close_zone_1') and
			self.gate_opening_status.card_key_door_1 == true then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.close_gate, self, self.get_card_key_door(1)))
	elseif type_util.is_zone_full_enter(e, leader, 's20_door_close_zone_3') and
			self.gate_opening_status.card_key_door_3 == true then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.close_gate, self, self.get_card_key_door(3)))
	elseif type_util.is_zone_full_enter(e, leader, 's19_lab_starting_zone') then
		if self.can_play_lab_lobby_event == true and self.lab_lobby_event_played == false then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lab_lobby_event, self))
		end
	elseif type_util.is_zone_full_enter(e, leader, 'battle_3') then
		self:battle_3_start()
	end
end

function local_class:on_interact_event(e)
	local target = e.Target

	if lua_helper.reference_equals(e.Target, self.get_a_room_down_stair()) then
		local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		if main_quest_progress ~= nil and main_quest_progress.InnerProgress == 21 then
			sp_util.play_normal_screenplay(self.card_key_stair_warning_log, self)
		end
	elseif self.card_key[target.Name] ~= nil then
		sp_util.play_normal_screenplay(self.use_card_key, self, target, self.card_key[target.Name] )
	end

	--region 공대 개그 SNS 이벤트
	if lua_helper.reference_equals(e.Target, self.get_chair()) then
		sp_util.play_normal_screenplay(self.interact_engineer_comedy, self)
	end
	--endregion

	return false
end


function local_class:on_stage_start_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:set_lobby_researcher_on_start()

	if main_quest_progress ~= nil then
		local progress = main_quest_progress.InnerProgress
		if progress >= 19 then
			local lobby_door = self.get_lobby_door()
			self:open_gate(lobby_door, true)

			if progress >= 20 then
				local door = self.get_card_key_main_door(1)

				local door_anim = door:GetComponent(typeof(CS.UnityEngine.Animator))
				door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
				door_anim:Play('on')

				-- 22섹션에서는 계단 다시 들어가려고 하면 나레이션 박스 출력
				if progress == 21 then
					local card_key_stair = self.get_a_room_down_stair()
					self.main_stair_interactable = card_key_stair.Interactable
					card_key_stair.Interactable = CS.Oak.PublishInteractable.Create()
				end

				message_system:Publish(CS.Oak.DoorOpenEvent.Create('demonshire_door_in_3', true))

				for i = 2, 6 do
					local npc = self.get_iris_lab_researcher(i)
					character_util.remove_emotion(npc)
				end
			end
		end
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		self.can_play_lab_lobby_event = false
		if e.CurrentProgress == 21 then
			self.can_play_lab_lobby_event = true

			local card_key_stair = self.get_a_room_down_stair()
			self.main_stair_interactable = card_key_stair.Interactable
			card_key_stair.Interactable = CS.Oak.PublishInteractable.Create()

			-- 이벤트 몬스터 활성화
			for i = 1, 5 do
				local monster = self.get_event_monster(i)
				character_util.set_active_state(monster, 'enabled')
				character_util.convert_to_npc(monster)
			end

			for i = 2, 6 do
				local npc = self.get_iris_lab_researcher(i)
				character_util.remove_emotion(npc)
			end
		elseif e.CurrentProgress == 22 then
			if self.main_stair_interactable ~= nil then
				local card_key_stair = self.get_a_room_down_stair()
				card_key_stair.Interactable = self.main_stair_interactable
			end
		end

		self:set_lobby_researcher_on_progressed(e)
	end
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 304101
	if user_util.has_knight_male() then
		character_spec_id = 304100
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

--region 공대 개그 SNS 이벤트
function local_class:interact_engineer_comedy()

	local leader = user_party.Leader

	local chair = self.get_chair()
	local comedian = self.get_comedian()
	local audience_1 = self.get_audience(1)
	local audience_2 = self.get_audience(2)
	local audience_3 = self.get_audience(3)

	--나레이션 박스 : 의자에 앉으시겠습니까?
	field_ui_util.show_narration_async({ key = self.engineer_comedy_script .. 'narration'})

	--아니요 / 예
	local choose_result = choose_util.play_choose_event(
			{ { self.engineer_comedy_script .. 'choose_2', 'mercy' }, { self.engineer_comedy_script .. 'choose_1', 'brutal' } })

	if choose_result == 1 then
		--컨트롤 복귀
	elseif choose_result == 2 then
		music_player_util.play_stage_music({ state = 'muted' })

		camera_util.move(leader.Position,0)
		character_util.hide_weapon(leader, true)
		character_util.set_emotion(audience_1, { name = 'smile' })

		--가디언 점프해서 빨간원위치에 (right,idle,seat)
		local count = 1
		local member_move_routine = function()
			for i = 0, user_party.Count - 1 do
				local member = user_party[i]
				if not lua_helper.reference_equals(user_party.Leader, member) then
					character_util.move_waypoint(member,
							chair.Position + vector(1,0, count), 4, false, 'stop', 'floor', 'right')
					count = count -1
				end
			end
		end
		wait_all({util.cs_generator(member_move_routine)})

		character_util.move_to(leader, chair.Position + vector(0,0.7,0), 0.5, nil)

		music_player_util.play_sfx_one_shot('01_jump_01')
		character_util.mario_jump_async(leader,'left', 0.5, 1)

		character_util.set_position(leader, chair.Position + vector(0,0.72,0))

		--leader 의자로 점프
		character_util.set_direction(leader, 'right')
		character_util.set_anim(leader, { name = 'seat'})

		music_player_util.play_sfx_one_shot('02_costume_equip_01')
		wait_for_sec(1)

		--관객들 전원(right,smile,seat)
		local dance_sfx = music_player_util.play_sfx({sfx_name = '01_amb_cf_01', loop = true})

		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		--관객3: 시작한다 시작해!
		speech_bubble_util.show_speech_bubble_async(audience_3, { key = self.engineer_comedy_script .. 1, skip = true })

		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		--관객1: 오늘은 또 얼마나 재밌는 얘기를 할까?
		speech_bubble_util.show_speech_bubble_async(audience_1, { key = self.engineer_comedy_script .. 2, skip = true })

		--관객2: 나 매일 이 시간만 기다리잖아.
		speech_bubble_util.show_speech_bubble_async(audience_2, { key = self.engineer_comedy_script .. 3, skip = true })

		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		local clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_02', loop = true})

		--개그맨(left,smile,clap) : 오늘 저희 데몬샤이어 코미디쇼에 오신 여러분들을 환영합니다!
		character_util.set_anim(comedian, { name = 'clap'})
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 4, skip = true })
		character_util.set_anim(comedian, { name = 'idle'})

		clap_sfx:Stop()
		clap_sfx = nil

		music_player_util.play_sfx_one_shot('01_clap_02')
		music_player_util.play_sfx_one_shot('01_coop_mvp_01')

		--관객들(right,smile,clap) 후 다시 (right,smile,seat)
		character_util.set_anim(audience_1, { name = 'clap'})
		character_util.set_anim(audience_2, { name = 'clap'})
		character_util.set_anim(audience_3, { name = 'clap'})

		wait_for_sec(1)

		character_util.set_anim(audience_1, { name = 'seat'})
		character_util.set_anim(audience_2, { name = 'seat'})
		character_util.set_anim(audience_3, { name = 'seat'})

		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		--개그맨(left,smile,sing) : 그럼, 오늘의 놀라운 이야기!
		character_util.set_anim(comedian, { name = 'sing'})
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 21, skip = true })

		--개그맨 : 철로 된 남자를 줄여서 여자라고 합니다. 왜 그럴까요?
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 5, skip = true })

		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(audience_1, { name = 'question', loop = false}, { name = 'tired'})
		character_util.set_anim_and_emotion(audience_2, { name = 'question', loop = false}, { name = 'tired'})
		character_util.set_anim_and_emotion(audience_3, { name = 'question', loop = false}, { name = 'tired'})

		--관객 1 : 분명히 남자인데…
		speech_bubble_util.show_speech_bubble(audience_1, { key = self.engineer_comedy_script .. 22, skip = true })
		wait_for_sec(0.5)
		--관객 2 : 염색체의 변화가?
		speech_bubble_util.show_speech_bubble(audience_2, { key = self.engineer_comedy_script .. 23, skip = true })
		wait_for_sec(0.5)
		--관객 3 : 분명 어떤 반응식이…
		speech_bubble_util.show_speech_bubble_async(audience_3, { key = self.engineer_comedy_script .. 24, skip = true })

		music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
		--개그맨(left,smile,release) : 철의 기호는 fe 남자는 male.
		character_util.play_speech_action(comedian, { name = 'release', sfx_name = '01_swing_01' },
				nil, self.engineer_comedy_script .. 6)

		--개그맨쪽으로 카메라가 줌된다.
		camera_util.resize_to(3,0.5)
		wait_for_sec(0.5)

		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		--개그맨(left,smile,victory_get) : 붙여 쓰면 /b female /b 이거든요!
		character_util.set_anim(comedian, { name = 'victory_get', loop = false })
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 7, skip = true })

		--줌이 다시 풀린다.
		camera_util.resize_to_default(0.5)
		wait_for_sec(0.5)

		character_util.set_anim(comedian, { name = 'idle'})

		music_player_util.play_sfx_one_shot('01_female_laugh_at_02')
		music_player_util.play_sfx_one_shot('01_male_laugh_at_02')
		clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_02', loop = true})

		camera_util.shake(0.06,1)
		--관객들 전원(right,awesome,clap) 후 다시 (right,smile,seat)
		--관객들(right,smile,clap) 후 다시 (right,smile,seat)
		character_util.set_anim_and_emotion(audience_1, {name = 'clap'}, {name = 'awesome'})
		character_util.set_anim_and_emotion(audience_2, {name = 'clap'}, {name = 'awesome'})
		character_util.set_anim_and_emotion(audience_3, {name = 'clap'}, {name = 'awesome'})

		character_util.set_emotion(leader, { name = 'tired'})
		--(right,awesome,clap)중 아래대사 빠르게 재생
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		--관객3 : 굉장해!
		speech_bubble_util.show_speech_bubble(audience_3, { key = self.engineer_comedy_script .. 8, skip = true })
		wait_for_sec(0.5)
		--관객1 : 이게 개그지!
		speech_bubble_util.show_speech_bubble(audience_1, { key = self.engineer_comedy_script .. 9, skip = true })
		wait_for_sec(0.5)
		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		--관객2 : 깔깔깔!
		speech_bubble_util.show_speech_bubble(audience_2, { key = self.engineer_comedy_script .. 10, skip = true, bubble_type = 'shout' })
		wait_for_sec(2)

		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		--가디언(tired) 땀방울 이모티콘
		character_util.show_emoticon_async(leader, nil, 'sweat')

		clap_sfx:Stop()
		clap_sfx = nil

		character_util.remove_emotion(leader)
		character_util.set_anim_and_emotion(audience_1, {name = 'seat'}, {name = 'smile'})
		character_util.set_anim_and_emotion(audience_2, {name = 'seat'}, {name = 'smile'})
		character_util.set_anim_and_emotion(audience_3, {name = 'seat'}, {name = 'smile'})

		--개그맨 : 과학자가 물을 시켰어요. H2O 주세요!
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 11, skip = true })

		--개그맨 : 옆에 있던 친구는 목이 더 말랐는지 두 개 시켰죠. H2O 둘!
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 12, skip = true })

		--개그맨(left,smile,release) : 그런데 그 친구가 물을 마시고 쓰러졌어요. 왜 그럴까요?
		character_util.play_speech_action(comedian, { name = 'release', sfx_name = '01_swing_01' },
				nil, self.engineer_comedy_script .. 13)

		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(audience_1, { name = 'question', loop = false}, { name = 'tired'})
		character_util.set_anim_and_emotion(audience_2, { name = 'question', loop = false}, { name = 'tired'})
		character_util.set_anim_and_emotion(audience_3, { name = 'question', loop = false}, { name = 'tired'})
		--관객 1 : 물의 성질을 계산해 보면…
		speech_bubble_util.show_speech_bubble(audience_1, { key = self.engineer_comedy_script .. 25, skip = true })
		wait_for_sec(0.5)
		--관객 2 : 다른 변수가 존재할 수도?
		speech_bubble_util.show_speech_bubble(audience_2, { key = self.engineer_comedy_script .. 26, skip = true })
		wait_for_sec(0.5)
		--관객 3 : 어떤 화학반응이…
		speech_bubble_util.show_speech_bubble_async(audience_3, { key = self.engineer_comedy_script .. 27, skip = true })

		--개그맨쪽으로 카메라가 줌된다.
		camera_util.resize_to(3,0.5)
		wait_for_sec(0.5)

		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		--개그맨(left,smile,victory_get) : 그 친구가 받은 건 H2O2 /b 과산화수소수 /b거든요!
		character_util.set_anim(comedian, { name = 'victory_get', loop = false })
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 14, skip = true })

		--줌이 다시 풀린다.
		camera_util.resize_to_default(0.5)
		wait_for_sec(0.5)

		camera_util.shake(0.06,1)
		clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_02', loop = true})
		music_player_util.play_sfx_one_shot('01_mad_laugh_01')
		character_util.set_anim(comedian, { name = 'idle'})
		--관객들 전원(right,awesome,clap)(아래 대사) 후 다시 (right,smile,seat)
		character_util.set_anim_and_emotion(audience_1, {name = 'clap'}, {name = 'awesome'})
		character_util.set_anim_and_emotion(audience_2, {name = 'clap'}, {name = 'awesome'})
		character_util.set_anim_and_emotion(audience_3, {name = 'clap'}, {name = 'awesome'})

		character_util.set_emotion(leader, { name = 'tired'})
		--(right,awesome,clap)중 아래대사 빠르게 재생
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		--관객1: 와하하하!
		speech_bubble_util.show_speech_bubble(audience_1, { key = self.engineer_comedy_script .. 15, skip = true, bubble_type = 'shout'})
		wait_for_sec(0.5)
		--관객3: 유레카!
		speech_bubble_util.show_speech_bubble(audience_3, { key = self.engineer_comedy_script .. 16, skip = true})
		wait_for_sec(0.5)
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		--관객2: 최고야!
		speech_bubble_util.show_speech_bubble(audience_2, { key = self.engineer_comedy_script .. 17, skip = true})
		wait_for_sec(2)

		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		--가디언(tired) 땀방울 이모티콘
		character_util.show_emoticon_async(leader, nil, 'sweat')
		clap_sfx:Stop()
		clap_sfx = nil
		character_util.remove_emotion(leader)
		character_util.set_anim_and_emotion(audience_1, {name = 'seat'}, {name = 'smile'})
		character_util.set_anim_and_emotion(audience_2, {name = 'seat'}, {name = 'smile'})
		character_util.set_anim_and_emotion(audience_3, {name = 'seat'}, {name = 'smile'})

		clap_sfx = music_player_util.play_sfx({sfx_name = '01_clap_02', loop = true})
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		--개그맨(left,smile,clap) : 끝으로 매일 연구로 바쁜 여러분들께 좋은 소식이 있습니다!
		character_util.set_anim(comedian, { name = 'clap'})
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 18, skip = true })
		clap_sfx:Stop()
		clap_sfx = nil
		--개그맨(left,smile,victory_extra): 제가 여러분들이 언제든 웃을 수 있도록 SNS를 개설했습니다!
		music_player_util.play_sfx_one_shot('01_coop_mvp_01')
		character_util.set_anim(comedian, { name = 'victory_extra'})
		speech_bubble_util.show_speech_bubble_async(comedian, { key = self.engineer_comedy_script .. 19, skip = true })

		--FB 등록
		yield_return_func(CS.Oak.AddSNSCoroutine, self.sns_follower_id)

		music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
		character_util.set_emotion(leader, { name = 'surprise'})
		character_util.normal_jump(leader,true)

		--개그맨(right,smile,release) : 매일 재미난 이야기를 공유해 드리겠습니다!
		character_util.play_speech_action(comedian, { name = 'release', sfx_name = '01_swing_01' },
				nil, self.engineer_comedy_script .. 20)

		music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
		--가디언 (right,tired,question) 물음표 이모션 박스
		character_util.set_emotion(leader, { name = 'tired'})
		character_util.show_emoticon_async(leader, nil, 'annoyed')

		character_util.move_to(leader, chair.Position + vector(1,0,0), 0.5, nil)

		music_player_util.play_sfx_one_shot('01_jump_01')
		character_util.mario_jump_async(leader,'right', 0.5, 1)

		character_util.set_direction(leader, 'right' )
		character_util.set_anim(leader, { name = 'idle' })

		music_player_util.play_sfx_one_shot('01_land_01')

		camera_util.return_to_leader(0.5)
		wait_for_sec(0.5)

		--의자 리스너 해제
		chair.Interactable = CS.Oak.NonInteractable.Instance

		--원라인 셋팅
		--개그맨(left,smile,idle) : 다음 시간을 기대해 주세요.
		character_util.set_anim_and_emotion(comedian, { name = 'idle' }, { name = 'smile' })
		comedian.Interactable.Talk = self.engineer_comedy_script .. 'oneline_5'

		--관객1(right,smile,seat) : 언제나 재밌다니까.
		character_util.set_anim_and_emotion(audience_1, { name = 'seat' }, { name = 'smile' })
		audience_1.Interactable.Talk = self.engineer_comedy_script .. 'oneline_6'

		--관객2(right,smile,seat) : 하하하 깔깔!
		character_util.set_anim_and_emotion(audience_2, { name = 'seat' }, { name = 'smile' })
		audience_2.Interactable.Talk = self.engineer_comedy_script .. 'oneline_7'

		--관객3(right,smile,seat) : 여기 개그는 참 고급스러워.
		character_util.set_anim_and_emotion(audience_3, { name = 'seat' }, { name = 'smile' })
		audience_3.Interactable.Talk = self.engineer_comedy_script .. 'oneline_8'

		character_util.remove_anim_and_emotion(leader)
		character_util.hide_weapon(leader, false)
		dance_sfx:Stop()
		dance_sfx = nil
		music_player_util.play_stage_music({ state = 'field' })
	end
end
--endregion

--endregion

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member, new_leader)
		-- 기사를 리더로
		local leader = new_leader == nil and self.get_knight() or new_leader

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
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 18 then
		-- 섹션 7일 때 입장 하면 소히를 파티원으로 추가
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('s19_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 19 then
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('s20_start_pos').position, true, true)
	elseif main_quest_progress.InnerProgress == 20 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		start_stage_event('right', field:GetMarker('s21_start_pos').position, false, false)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 21 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		change_leader_character()
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	local lobby_info_clerk = get_character('lobby_info_clerk')

	lobby_info_clerk.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 2.8))
	character_util.set_position_from_marker(lobby_info_clerk, 'lobby_info_desk')
	character_util.set_active_state(lobby_info_clerk, 'enabled')

	--region 공대 개그 SNS 이벤트
	local comedian = self.get_comedian()
	local audience_1 = self.get_audience(1)
	local audience_2 = self.get_audience(2)
	local audience_3 = self.get_audience(3)
	local chair = self.get_chair()

	character_util.set_direction(comedian , 'left')
	character_util.set_direction(audience_1 , 'right')
	character_util.set_direction(audience_2 , 'right')
	character_util.set_direction(audience_3 , 'right')

	-- sns follower 가 추가 되어 있지 않다면.
	if not user_progress:IsFollowing(self.sns_follower_id) then
		--개그맨(left,smile,idle) : 자리에 앉아주세요!
		character_util.set_anim_and_emotion(comedian, { name = 'idle' }, { name = 'smile' })
		comedian.Interactable.Talk = self.engineer_comedy_script .. 'oneline_1'

		--관객 1(right,smile,seat) : 기대감에 뇌가 떨린다아아!
		character_util.set_anim_and_emotion(audience_1, { name = 'seat' }, { name = 'greed' })
		audience_1.Interactable.Talk = self.engineer_comedy_script .. 'oneline_2'

		--관객 2(right,smile,seat) : 드디어 내 안면 근육을 활용할 때군.
		character_util.set_anim_and_emotion(audience_2, { name = 'seat' }, { name = 'smile' })
		audience_2.Interactable.Talk = self.engineer_comedy_script .. 'oneline_3'

		--관객 3(right,smile,seat) : 횡경막을 자극해 엔돌핀을 분비시켜보자고!
		character_util.set_anim_and_emotion(audience_3, { name = 'seat' }, { name = 'smile' })
		audience_3.Interactable.Talk = self.engineer_comedy_script .. 'oneline_4'
	else
		chair.Interactable = CS.Oak.NonInteractable.Instance

		--개그맨(left,smile,idle) : 다음 시간을 기대해 주세요.
		character_util.set_anim_and_emotion(comedian, { name = 'idle' }, { name = 'smile' })
		comedian.Interactable.Talk = self.engineer_comedy_script .. 'oneline_5'

		--관객1(right,smile,seat) : 언제나 재밌다니까.
		character_util.set_anim_and_emotion(audience_1, { name = 'seat' }, { name = 'smile' })
		audience_1.Interactable.Talk = self.engineer_comedy_script .. 'oneline_6'

		--관객2(right,smile,seat) : 하하하 깔깔!
		character_util.set_anim_and_emotion(audience_2, { name = 'seat' }, { name = 'smile' })
		audience_2.Interactable.Talk = self.engineer_comedy_script ..  'oneline_7'

		--관객3(right,smile,seat) : 여기 개그는 참 고급스러워.
		character_util.set_anim_and_emotion(audience_3, { name = 'seat' }, { name = 'smile' })
		audience_3.Interactable.Talk = self.engineer_comedy_script ..  'oneline_8'
	end
	--endregion
end

function local_class:use_card_key(target, key_info)
	local fo_name = key_info['opening_fo_name']
	local align_dir = key_info['align_dir']
	local offset = key_info['offset']
	local leader = user_party.Leader
	local align_pos = vector_util.get_x0z(target.Bounds.center) + offset

	target.Interactable = CS.Oak.NonInteractable.Instance

	party_util.align_party(align_pos, align_dir, 1)
	coroutine.yield(nil)

	local typing_sfx = music_player_util.play_sfx({ sfx_name = '01_typing_01', loop = true })
	character_util.hide_weapon(leader, true)
	if direction_util.is_side(leader.Direction) then
		character_util.set_anim(leader, { name = 'dualgun_attack_right' })
	else
		character_util.set_anim(leader, { name = 'shoot' })
	end
	wait_for_sec(1.5)
	character_util.remove_anim(leader)
	character_util.hide_weapon(leader, false)
	typing_sfx:Stop()

	-- 보안 인증 완료.
	music_player_util.play_sfx_one_shot('01_elevator_05')
	speech_bubble_util.show_speech_bubble_async(target, { key = 'ds_main_s20_124', skip = true })

	-- 열때 사용한 콜손과, 열리는 문 정보 보냄
	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { target.Name, fo_name }))

	self:open_gate(get_field_object(fo_name))
end

function local_class:card_key_stair_warning_log()
	-- 다시 들어가게 되면 잡힐 것 같다.
	field_ui_util.show_narration_async({ key = 'ds_main_s21_41' })
end

function local_class:open_gate(gate, immediate)
	local gate_animator = gate:GetComponent(typeof(CS.UnityEngine.Animator))
	gate_animator:Play('on')

	self.gate_opening_status[gate.Name] = true

	if immediate ~= true then
		music_player_util.play_sfx_one_shot('02_gimmick_door_down_03')
		wait_for_sec(0.5)
	end
	gate.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
end

function local_class:close_gate(gate, immediate)
	local gate_animator = gate:GetComponent(typeof(CS.UnityEngine.Animator))
	gate_animator:Play('off')

	self.gate_opening_status[gate.Name] = false

	if immediate ~= true then
		music_player_util.play_sfx_one_shot('02_gimmick_door_down_03')
		wait_for_sec(0.5)
	end
	gate.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance

	local console_name = self.get_card_key_console[gate.Name]
	if console_name ~= nil then
		local console = get_field_object(console_name)
		console.Interactable = CS.Oak.PublishInteractable.Create()
	end
end

function local_class:lab_lobby_event()
	self.lab_lobby_event_played = true

	local npc_7 = self.get_lab_lobby_researcher(7)
	local npc_8 = self.get_lab_lobby_researcher(8)

	wait_all({
		util.cs_generator(function()
			--초록7 대사 출력(이후 원라인 처리) (left, tired, cast)
			--뭐… 뭐야…?
			speech_bubble_util.show_speech_bubble(npc_7, { key = 'ds_main_s22_oneline_1' })
			npc_7.Interactable.Talk = 'ds_main_s22_oneline_1'
		end),
		util.cs_generator(function()
			--초록7 대사 출력 시작하고 0.2초 뒤 초록8 대사 출력 시작 (right, surprise, idle)
			--방금 경보 울리지 않았어…?
			wait_for_sec(0.2)
			speech_bubble_util.show_speech_bubble(npc_8, { key = 'ds_main_s22_oneline_2' })
			npc_8.Interactable.Talk = 'ds_main_s22_oneline_2'
		end)
	})
end

function local_class:set_lobby_researcher_on_start()
	-- 19, 20섹션에서 19섹션 원라인 설정으로..
	-- 22 섹션 이후에는 5-6 번 npc 지운다
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		local progress = main_quest_progress.InnerProgress
		if progress == 18 or progress == 19 then
			for i = 1, 5 do
				local npc = self.get_lab_lobby_researcher(i)
				local marker = field:GetMarker('lab_lobby_researcher_s19_pos_' .. i)
				local data = self.oneline_s19_data[i]

				character_util.set_active_state(npc, 'enabled')
				character_util.set_position(npc, marker.position)
				character_util.set_direction(npc, marker.direction)
				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end

			for i = 6, 10 do
				local npc = self.get_lab_lobby_researcher(i)
				local data = self.oneline_s19_data[i]

				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end
		elseif progress < 22 then
			for i = 1, 3 do
				local npc = self.get_lab_lobby_researcher(i)
				local marker = field:GetMarker('lab_lobby_researcher_s19_pos_' .. i)
				local data = self.oneline_s19_data[i]

				character_util.set_active_state(npc, 'enabled')
				character_util.set_position(npc, marker.position)
				character_util.set_direction(npc, marker.direction)
				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end

			for i = 6, 10 do
				local npc = self.get_lab_lobby_researcher(i)
				local data = self.oneline_s19_data[i]

				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end
		elseif progress >= 22 then
			for i = 6, 10 do
				local npc = self.get_lab_lobby_researcher(i)
				local data = self.oneline_s19_data[i]

				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end
		end
	end
end

function local_class:set_lobby_researcher_on_progressed(e)
	--- 21에서 22섹션으로 진입시에만 원라인 22섹션 설정으로 바뀌고,
	--- 22섹션 이후로는 6-10번 npc는 사라지고, 다시 19섹션 설정으로 바뀌고, 6-10번 npc는 사라짐
	if e.QuestId == self.main_quest_id then
		if e.CurrentProgress == 21 then
			for i = 1, 3 do
				local npc = self.get_lab_lobby_researcher(i)
				local marker = field:GetMarker('lab_lobby_researcher_s21_pos_' .. i)
				local data = self.oneline_s22_data[i]

				character_util.set_active_state(npc, 'enabled')
				character_util.set_position(npc, marker.position)
				character_util.set_direction(npc, marker.direction)
				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end

			for i = 4, 5 do
				local npc = self.get_lab_lobby_researcher(i)

				character_util.set_active_state(npc, 'disabled')
				character_util.set_position(npc, vector(999, 0, 999))
				character_util.remove_anim_and_emotion(npc)
				npc.Interactable.Talk = nil
			end

			for i = 6, 10 do
				local npc = self.get_lab_lobby_researcher(i)
				local data = self.oneline_s22_data[i]

				character_util.set_anim(npc, data.anim)
				character_util.set_emotion(npc, data.emo)
				npc.Interactable.Talk = data.talk
			end
		end
	elseif e.CurrentProgress >= 22 then
		for i = 1, 5 do
			local npc = self.get_lab_lobby_researcher(i)

			character_util.set_active_state(npc, 'disabled')
			character_util.set_position(npc, vector(999, 0, 999))
			character_util.remove_anim_and_emotion(npc)
			npc.Interactable.Talk = nil
		end

		for i = 6, 10 do
			local npc = self.get_lab_lobby_researcher(i)
			local data = self.oneline_s19_data[i]

			character_util.set_anim(npc, data.anim)
			character_util.set_emotion(npc, data.emo)
			npc.Interactable.Talk = data.talk
		end
	end
end

function local_class:battle_3_start()
	for i = 1, 5 do
		local monster = self.get_event_monster(i)
		character_util.convert_to_monster(monster, 'battle_3', 'battle_3')
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
