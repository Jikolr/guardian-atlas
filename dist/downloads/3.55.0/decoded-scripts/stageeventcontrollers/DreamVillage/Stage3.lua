local local_class = newclass('DreamVillage3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 441

	-- club 아이템
	self.club_item_id = 21391
	self.club_item = nil

	-- 석상
	self.square_statue = function()
		return get_character('square_statue')
	end

	-- 동굴 이벤트용 아이템
	self.cave_item = setmetatable({
		id = { 21395, 21396, 21397, 21398, 21399, 21400, 21401 },
		items = nil,
		marker_pre_fix = 'cave_item_pos_',
		fo_count = 7,
		fo_pre_fix = 'cave_item_',
	}, {
		__index = {
			init = function(this)
				this.items = {}

				for i = 1, #this.id do
					local item = quest_drop_item_util.create_item({
						pos = field_util.get_marker_pos(this.marker_pre_fix .. i),
						item_id = this.id[i],
						loot_state = quest_drop_item_loot_state.dont_find_looter,
						skip_text = true
					})

					table.insert(this.items, item)
				end
			end,
			dispose_all = function(this)
				for _, item in pairs(this.items) do
					quest_drop_item_util.dispose_item(item)
				end

				this.id = nil
				this.items = nil
			end
		}
	})

	self.time_conversion_event_key = 'stage_3'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self:dispose_club_item()
	self.cave_item:dispose_all()

	self.cs_controller = nil
end

function local_class:load_resource()
	local square_statue = self.square_statue()

	square_statue.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 2
	field_ui_manager:RemoveUI(square_statue, CS.Oak.FieldUiType.CharacterStats)

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	for i = 1, self.cave_item.fo_count do
		local item = get_field_object(self.cave_item.fo_pre_fix .. i)

		if lua_helper.reference_equals(e.Target, item) then
			sp_util.start_scene(self['cave_item_event_' .. i], self, item)

			return true
		end
	end

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self:create_club_item()
	self:start_setting()
	self:s15_open_box_setting()
	self:exit_open_box_setting()
	self.cave_item:init()

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), false, false)
	elseif quest_progress.InnerProgress == 15 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s16_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:start_setting()
	do
		-- 밤/낮 세팅
		local time_conversion = get_stage_event_controller('TimeConversionManager')

		-- 콜백 등록
		time_conversion:register_callback(self.time_conversion_event_key, {
			-- 낮
			daylight = function()
				self:show_club()
				self:reset_square_statue()
			end,
			-- 밤
			night = function()
				self:hide_club()
				self:set_alpha_square_statue()
			end
		}, true)
	end
end

--region club item
function local_class:create_club_item()
	if self.club_item ~= nil then
		return
	end

	self.club_item = quest_drop_item_util.create_item({
		pos = field_util.get_marker_pos('club_pos'),
		item_id = self.club_item_id,
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})
end

function local_class:get_club_item()
	return self.club_item
end

function local_class:dispose_club_item()
	quest_drop_item_util.dispose_item(self.club_item)
	self.club_item = nil
end

function local_class:show_club()
	if self.club_item == nil then
		return
	end

	quest_drop_item_util.set_alpha_fade(self.club_item, 1, 1)
end

function local_class:hide_club()
	if self.club_item == nil then
		return
	end

	quest_drop_item_util.set_alpha_fade(self.club_item, 0, 1)
end

function local_class:reset_square_statue()
	local square_statue = self.square_statue()

	character_util.remove_color(square_statue, square_statue.Name, 2)
end

function local_class:set_alpha_square_statue()
	local square_statue = self.square_statue()

	character_util.add_color(square_statue, square_statue.Name, unity_color({ 0.5, 0.4, 0.4 }), 1, 1)
end
--endregion club item

--region 길 막는 box 처리
function local_class:s15_open_box_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress == nil or quest_progress.InnerProgress < 14 then
		return
	end

	field_object_util.set_active_state(get_field_object('s15_open_box'), active_state_type.disabled)
end

function local_class:exit_open_box_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress == nil or quest_progress.InnerProgress < 16 then
		return
	end

	field_object_util.set_active_state(get_field_object('exit_open_box_1'), active_state_type.disabled)
	field_object_util.set_active_state(get_field_object('exit_open_box_2'), active_state_type.disabled)
end
--endregion 길 막는 box 처리

--region 동굴 아이템 이벤트
function local_class:cave_item_event_1(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'right')
	--도화(left, smile, idle) : 아, 그… 그건 언니랑 갖고 놀던 팽이예요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			nil, 'smile', 'dv_stage_3_cave_event_1_talk_1')

	--도화(left, tired, idle) : 지… 집에서는 바닥 긁힌다고 해서 고무같은 걸 달아놨었는데…
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			nil, 'tired', 'dv_stage_3_cave_event_1_talk_2')

	--도화(left, tired, cast) : 여기 둬… 뒀었네요.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'tired', 'dv_stage_3_cave_event_1_talk_3')
end

function local_class:cave_item_event_2(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'right')
	--도화(left, smile, idle) : 아, 곰돌이 아빠! 오랜만이예요!
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			nil, 'smile', 'dv_stage_3_cave_event_2_talk_1')

	--기사 right, idle, idle, question 이모티콘
	character_util.show_emoticon_async(leader, nil, 'question')

	--도화(left, blush, cast) : 어… 언니랑 소꿉놀이할 때 그 곰돌이가 항상 아빠 역할을 맡았었거든요.
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'blush', 'dv_stage_3_cave_event_2_talk_2')

	--도화(left, tired, idle) : 치… 치마를 입긴 했는데… 곰돌이 아빠였어요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'tired', 'dv_stage_3_cave_event_2_talk_3')
end

function local_class:cave_item_event_3(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(-1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(-2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'left')
	--도화(right, smile, idle) : 이… 이건 언니랑 하던 모험 이야기 게임이예요.
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			nil, 'smile', 'dv_stage_3_cave_event_3_talk_1')

	--도화(right, tired, idle) : 두… 둘만의 주인공을 만들어서… 능력치도 정하고….
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'idle', 'tired', 'dv_stage_3_cave_event_3_talk_2')

	--도화(right, damaged, cast) : 서… 설명하다 보니 좀 부끄럽네요….
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'cast', 'damaged', 'dv_stage_3_cave_event_3_talk_3')
end

function local_class:cave_item_event_4(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(-1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(-2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'left')
	--도화(right, tired, idle) : 이 주사위도 여기 있었구나….
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			nil, 'tired', 'dv_stage_3_cave_event_4_talk_1')

	--도화(right, tired, idle) : 어… 언니가 놀이할 때 쓰려고 만들었던 주사위예요.
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'idle', 'tired', 'dv_stage_3_cave_event_4_talk_2')

	--도화(right, smile, cast) : 주… 주사위 눈은 제가 새겼어요, 헤헤….
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'cast', 'smile', 'dv_stage_3_cave_event_4_talk_3')
end

function local_class:cave_item_event_5(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'right')
	--도화(left, smile, cast, jump 1회) : 와! 이 책 여기 있었구나….
	character_util.normal_jump(twins_younger, true)
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'smile', 'dv_stage_3_cave_event_5_talk_1')

	--도화(left, tired, idle) : 이… 이 책은… 언니가 매번 읽어주던 책이예요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'tired', 'dv_stage_3_cave_event_5_talk_2')

	--도화(left, tired, idle) : 하… 항상 가장 중요한 부분은 둘이 같이 연기하면서 했어요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'tired', 'dv_stage_3_cave_event_5_talk_3')

	--도화(left, smile, cast) : 진짜 주인공이 된 거 같아서 재밌었는데….
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'smile', 'dv_stage_3_cave_event_5_talk_4')
end

function local_class:cave_item_event_6(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(-1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(-2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'right' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'left')
	--도화(right, tired, idle) : 아, 돌이 낳은 알이예요.
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			nil, 'tired', 'dv_stage_3_cave_event_6_talk_1')

	--	--도화(right,tired,cast) : 시… 실제로 알인 건 아니예요. 그냥 돌이었는데… 알처럼 생겨서….
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'cast', 'tired', 'dv_stage_3_cave_event_6_talk_2')

	--	--도화(right, tired, idle) : 버… 번갈아가면서 돌 끌어안은 채로 얼른 깨어나라면서 놀기도 했었는데….
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'idle', 'tired', 'dv_stage_3_cave_event_6_talk_3')

	--도화(right, smile, idle) : 어… 언니는 이 알이 깨면 안에서 돌이 나올 거라고 했어요…. 재밌죠?
	scene_util.play_normal_speech_action(twins_younger, self, 'right',
			'idle', 'smile', 'dv_stage_3_cave_event_6_talk_4')
end

function local_class:cave_item_event_7(item)
	local leader = get_party_leader()
	local twins_younger = get_character('twins_younger')
	local wp_key = 'item_wp'

	--인터랙트 하면 컨트롤 뺏고 1초간 정렬.
	wp_util.move_with_end_callback(leader, item.Position + vector(1, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })
	wp_util.move_with_end_callback(twins_younger, item.Position + vector(2, 0, 0),
			nil, 1, self, wp_key, { last_direction = 'left' })

	wp_util.wait_move_end(self, wp_key)

	character_util.set_direction(leader, 'right')

	--도화(left, tired, idle) : 이… 이건 소꿉놀이할 때 쓰던 가짜 돈이에요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'tired', 'dv_stage_3_cave_event_7_talk_1')

	--도화(left, smile, cast) : 가… 감쪽같죠?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'smile', 'dv_stage_3_cave_event_7_talk_2')

	--기사 right, greed, cast
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	scene_util.set_emotion(leader, self, 'greed')
	scene_util.set_anim(leader, self, 'cast')
	--1초 대기.
	wait_for_sec(1)

	--기사 right, idle, idle.
	character_util.remove_anim_and_emotion(leader)
	--도화(left, tired, cast) : 어… 언니랑 진짜 돈 보면서 열심히 따라서 만들었어요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'cast', 'tired', 'dv_stage_3_cave_event_7_talk_3')

	--도화(left, tired, idle) : 하… 한번은 아빠가 이 돈 들고 나갔다 시장에서 쫓겨나신 적도 있었는데…
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'tired', 'dv_stage_3_cave_event_7_talk_4')

	--도화(left, sleep_deep, idle) : 언니랑 그날 엄청 혼났어요. 그러고 여기에 숨겨뒀었나봐요.
	scene_util.play_normal_speech_action(twins_younger, self, 'left',
			'idle', 'sleep_deep', 'dv_stage_3_cave_event_7_talk_5')
end
--endregion 동굴 아이템 이벤트

return local_class
