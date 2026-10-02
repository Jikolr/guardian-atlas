local local_class = newclass('NightmareDemonShire3Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.zone_enter_event_func = {
		--[[
			{
				zone_name = '',
				event_func = nil,
			}
		]]--
	}

	-- 라따뚜이 npc
	self.get_ratatouille_npc = function(index) return get_character('ratatouille_event_npc_' .. index) end

	-- 맨드레이크 npc
	self.get_mandrake_npc = function(index) return get_character('mandrake_event_npc_' .. index) end

	-- 메인 퀘스트 아이디
	self.main_quest_id = 406

	-- 맨드레이크 이벤트 보았는지?
	self.is_show_mandrake_event = true

	-- 맨드레이크 npc 카운트
	self.ratatouille_event_npc_count = 2
	self.mandrake_event_npc_count = 3

	-- 스테이지에 세팅할 드롭아이템 캐싱
	self.cached_drop_item = {}

	self.is_show_heart_emotion = false
end

function local_class:load_resource()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = quest_util.get_started_quest(self.main_quest_id)

	-- 맨드레이크 이벤트 세팅
	if quest_util.get_custom_state(quest_progress, 'stage3_mandrake_event') < 0 then
		self:set_mandrake_event()
	end

	-- 라따뚜이 이벤트 세팅
	local ratatouille_mouse = self.get_ratatouille_npc(2)

	local scale = unity_class.vector3.one * 0.5
	character_util.spine_scale(ratatouille_mouse, scale, 0)
	ratatouille_mouse.SpineController.ShadowScale = scale

	if quest_util.get_custom_state(quest_progress, 'stage3_ratatouille_event') < 0 then
		self:set_ratatouille_event()
	else
		character_util.add_listener(ratatouille_mouse, self)
	end

	-- 프리실라 사진
	self.cached_drop_item['picture'] = drop_item_util.create_item({
		pos = vector_util.get_x0z(get_field_object('half_vampire_picture').Position, 0.5),
		itemid = 21244,
		notforinven = true,
		sprscale = 0.5,
		lootstate = 'dontfindlooter',
		skip_text = true
	})
	self.cached_drop_item['picture'].ShadowTransform.localPosition = vector(0, 0.49, -0.03)

	-- 안내데스크 npc hitbox 조정
	local information_desk_count = 2
	for i = 1, information_desk_count do
		local npc = get_character('information_desk_npc_' .. i)
		npc.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(2.5, 0.75, 2.5))
	end

	local success_npc = get_character('nm_ds_main_stage3_plaza_oneline_1')
	character_util.remove_anim(success_npc)
	character_util.set_anim(success_npc, { name = 'success', sfx_name = '01_small_jump_01', loop = true })

	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s9_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s10_start_pos'),
				true, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	if self.is_show_mandrake_event == false then
		for i = 1, self.mandrake_event_npc_count do
			if lua_helper.reference_equals(e.Target, self.get_mandrake_npc(i)) then
				self.is_show_mandrake_event = true
				sp_util.start_scene(self.interact_mandrake_event_npc, self)
				return true
			end
		end
	end

	if not self.is_show_heart_emotion and
			lua_helper.reference_equals(e.Target, self.get_ratatouille_npc(2)) then
		self.is_show_heart_emotion = true

		start_coroutine(function()
			character_util.show_emoticon_async(self.get_ratatouille_npc(2), nil, 'heart')
			self.is_show_heart_emotion = false
		end)

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	for i = #self.zone_enter_event_func, 1, -1 do
		local zone_name = self.zone_enter_event_func[i].zone_name

		if type_util.is_zone_full_enter(e, leader, zone_name) then
			start_coroutine(self.zone_enter_event_func[i].event_func, self)
			table.remove(self.zone_enter_event_func, i)
			return true
		end
	end

	return false
end

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

--region 맨드레이크 이벤트

function local_class:set_mandrake_event()
	self.is_show_mandrake_event = false

	for i = 1, self.mandrake_event_npc_count do
		local npc = self.get_mandrake_npc(i)
		npc.Interactable.Talk = nil

		character_util.remove_anim_and_emotion(npc)
		scene_util.set_direction(npc, i == 1 and 'right' or 'left')

		if i == 1 then
			scene_util.set_emotion(npc, self, 'tired')
			character_util.set_anim(npc, { name = 'cast' })
		end
	end

	local zone_event_spec = {}

	zone_event_spec.zone_name = 'mandrake_event_zone'
	zone_event_spec.event_func = self.enter_mandrake_zone

	table.insert(self.zone_enter_event_func, zone_event_spec)
end

function local_class:enter_mandrake_zone()
	local mandrake_event_npc_list = {}

	for i = 1, self.mandrake_event_npc_count do
		local npc = self.get_mandrake_npc(i)
		table.insert(mandrake_event_npc_list, npc)
	end

	-- 연구원(right, tired, cast) : 후… 내일이 심사일이네. 잘 할 수 있을까?
	speech_bubble_util.show_speech_bubble_async(mandrake_event_npc_list[1], { key = 'nm_ds_stage3_mandrake_1' })

	-- 맨드레이크1(left, smile, idle, jump 2회) : 맨드! 맨드!
	start_coroutine(function()
		for _ = 1, 2 do
			music_player_util.play_sfx({
				sfx_name = '01_small_jump_01',
				play_pos = mandrake_event_npc_list[2].Position,
				loop = false
			})

			character_util.normal_jump(mandrake_event_npc_list[2])
			wait_for_sec(0.3)
			coroutine.yield(nil)
		end
	end)

	scene_util.set_emotion(mandrake_event_npc_list[2], self, 'smile')
	speech_bubble_util.show_speech_bubble_async(mandrake_event_npc_list[2], { key = 'nm_ds_stage3_mandrake_2' })

	-- 위 대사들 다 끝난 뒤에 인터랙트 가능.
	for i = 1, self.mandrake_event_npc_count do
		character_util.add_listener(mandrake_event_npc_list[i], self)
	end
end

function local_class:interact_mandrake_event_npc()
	local vampire_lord = get_party_leader()
	local mandrake_event_npc_list = {}

	for i = 1, self.mandrake_event_npc_count do
		local npc = self.get_mandrake_npc(i)
		character_util.remove_relate_event(npc, self)

		table.insert(mandrake_event_npc_list, npc)
	end

	-- 컨트롤 뺏김과 함께 BGM 볼륨 0.6으로 조절, 믹스 디폴트값
	music_player_util.change_stage_music_volume('field', 0.6)

	party_util.align_party(mandrake_event_npc_list[1].Position, 'down', 0.5, 'linear')

	-- 연구원 down, surprise, idle, jump 1회, 느낌표 이모티콘.
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.remove_anim(mandrake_event_npc_list[1])
	scene_util.set_direction(mandrake_event_npc_list[1], 'down', false)
	scene_util.set_emotion(mandrake_event_npc_list[1], self, 'surprise')
	character_util.normal_jump(mandrake_event_npc_list[1], true)
	character_util.show_emoticon_async(mandrake_event_npc_list[1], nil, 'notice')

	-- 연구원(down, surprise, release) : 클로드 백작님!!
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
			'release', nil, 'nm_ds_stage3_mandrake_3')

	-- 맨드레이크2(down, smile, idle) : 맨드! 맨드!
	music_player_util.play_sfx_one_shot('01_creature_05')
	scene_util.set_direction(mandrake_event_npc_list[2], 'down', false)
	scene_util.play_normal_speech_action(mandrake_event_npc_list[3], self, { dir = 'down', sfx = false },
			nil, { name = 'smile', keep = true }, 'nm_ds_stage3_mandrake_4')

	-- 클로드(남)(up, bomb_idle) : 고민이 있어 보이던데.
	scene_util.play_normal_speech_action(vampire_lord, self, nil,
			'bomb_idle', nil, 'nm_ds_stage3_mandrake_5')

	-- 연구원(right, smile, release 2회) : 아! 저는 이 맨드레이크들을 활용하는 사업을 계획 중이예요!
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, { dir = 'right', sfx = false },
			{ name = 'release', count = 2 }, { name = 'smile', keep = true },
			'nm_ds_stage3_mandrake_6')

	-- 맨드레이크2(down, attack, cast2) : 맨드으으으~!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.play_normal_speech_action(mandrake_event_npc_list[3], self, nil,
			'cast2', 'attack', 'nm_ds_stage3_mandrake_7')
	scene_util.set_emotion(mandrake_event_npc_list[3], self, 'smile')

	-- 연구원(down, tired, idle) : 내일 주에서 시행하는 창업 지원 프로그램의 최종 심사일이라…
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, { dir = 'down', sfx = false },
			nil, 'tired', 'nm_ds_stage3_mandrake_8')

	-- 연구원(down, tired, cast) : 너무 떨려서….
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
			'cast', 'tired', 'nm_ds_stage3_mandrake_9')

	-- 연구원(down, attack, cast2) : 혹시! 클로드 님께서 심사 팀에 좋은 말씀을 해주신다면…
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
			'cast2', 'attack', 'nm_ds_stage3_mandrake_10')

	-- 클로드 선택지
	-- 받아들인다.(초록) / 거절한다.(빨강)
	local choose_result = choose_util.play_choose_event({
		{ 'nm_ds_stage3_mandrake_11', 'mercy' },
		{ 'nm_ds_stage3_mandrake_12', 'brutal' }
	})

	if choose_result == 1 then
		-- 받아들인다.(초록)

		-- 클로드(남)(right, idle, question 1회, 자세 유지.) : 확실히 이렇게 크고 활동성이 높은 맨드레이크는 처음 보는군.
		music_player_util.play_sfx_one_shot('01_rustle_01')
		scene_util.play_normal_speech_action(vampire_lord, self, { dir = 'right', sfx = false },
				{ name = 'question', keep = true }, nil, 'nm_ds_stage3_mandrake_13')

		-- 연구원(down, smile, sing, jump 1회) : 그렇죠!
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		character_util.normal_jump(mandrake_event_npc_list[1], '01_small_jump_01')
		scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
				{ name = 'sing', keep = true }, { name = 'smile', keep = true },
				'nm_ds_stage3_mandrake_14')

		-- 클로드(남)(up) : 시간이 난다면 심사 팀에 얘기해보겠다.
		character_util.remove_anim(vampire_lord)
		scene_util.play_normal_speech_action(vampire_lord, self, { dir = 'up', sfx = false },
				nil, nil, 'nm_ds_stage3_mandrake_15')
	else
		-- 거절한다.(빨강)

		-- 연구원 표정 tired
		scene_util.set_emotion(mandrake_event_npc_list[1], self, 'tired')

		-- 클로드(남)(right, sleep_deep, idle) : 너에게만 특혜를 줄 수는 없다.
		music_player_util.play_sfx_one_shot('01_swing_01')
		scene_util.play_normal_speech_action(vampire_lord, self, { dir = 'right', sfx = false },
				nil, 'sleep_deep', 'nm_ds_stage3_mandrake_16')

		-- 클로드(남)(up, bomb_idle) : 진짜 좋은 상품이라는 자부심이 있다면 내 도움 없이도 통과할 수 있을 거다.
		scene_util.play_normal_speech_action(vampire_lord, self, { dir = 'up', sfx = false },
				'bomb_idle', nil, 'nm_ds_stage3_mandrake_17')

		-- 연구원(down, smile, nod 2회) : 마… 맞는 말씀이예요!
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')
		scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
				'nod', 'smile', 'nm_ds_stage3_mandrake_18')
	end

	-- 연구원(down, smile, cast2) : 감사합니다! 열심히 할게요!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(mandrake_event_npc_list[1], self, nil,
			'cast2', { name = 'smile', keep = true }, 'nm_ds_stage3_mandrake_19')

	-- 맨드레이크1 : 맨드! 맨드!
	music_player_util.play_sfx_one_shot('01_creature_05')
	scene_util.show_normal_speech_async(mandrake_event_npc_list[2], 'nm_ds_stage3_mandrake_20')

	-- 이후 원라인으로 남는다.
	scene_util.set_direction(mandrake_event_npc_list[1], 'right', false)
	character_util.set_anim(mandrake_event_npc_list[1], { name = 'cast' })

	-- 맨드레이크 1, 2(down, smile, idle) : 맨드! 맨드!
	-- 연구원(right, smile, cast) : 이번 심사에 통과하면 아르바이트 생도 잔뜩 뽑아야지!
	for i = 1, self.mandrake_event_npc_count do
		local npc = mandrake_event_npc_list[i]
		npc.Interactable.Talk = 'nm_ds_stage3_mandrake_oneline_' .. i
	end

	-- 저장
	local quest_progress = quest_util.get_started_quest(self.main_quest_id)
	quest_util.set_custom_state(quest_progress, 'stage3_mandrake_event', 1)

	-- 컨트롤 복귀와 함께 BGM 볼륨 1로 조절, 믹스 디폴트값
	music_player_util.change_stage_music_volume('field', 1)
end

--endregion 맨드레이크 이벤트


--region 라따뚜이 이벤트

function local_class:set_ratatouille_event()
	for i = 1, self.ratatouille_event_npc_count do
		local npc = self.get_ratatouille_npc(i)
		npc.Interactable.Talk = nil
	end

	-- 치즈 세팅
	self.cached_drop_item['cheesecake'] = drop_item_util.create_item({
		pos = self.get_ratatouille_npc(2).Position - vector(0.3, 0, 0),
		itemid = 21243,
		notforinven = true,
		sprscale = 0.8,
		lootstate = 'dontfindlooter',
		skip_text = true
	})

	local zone_event_spec = {}

	zone_event_spec.zone_name = 'ratatouille_event_zone'
	zone_event_spec.event_func = self.enter_ratatouille_zone

	table.insert(self.zone_enter_event_func, zone_event_spec)
end

function local_class:enter_ratatouille_zone()
	local ratatouille_npc = {}

	for i = 1, self.ratatouille_event_npc_count do
		table.insert(ratatouille_npc, self.get_ratatouille_npc(i))
	end

	local cheesecake = self.cached_drop_item['cheesecake']

	-- 존 엔터하면 컨트롤 뺏지 않고 이벤트 진행.

	-- 쥐가 치즈 위에서 eat 2초간.
	local eat_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01',
		play_pos = ratatouille_npc[2].Position,
		max_distance = 8,
		loop = true
	})

	scene_util.set_anim(ratatouille_npc[2], self, 'eat')

	drop_item_util.resize_to_async(cheesecake, 0, 2)

	eat_sfx:Stop()
	cheesecake:ConsumeComplete()
	self.cached_drop_item['cheesecake'] = nil

	-- 쥐 jump 1회 하며 하트 이모티콘 띄운다.
	music_player_util.play_sfx({
		sfx_name = '01_mouse_01',
		play_pos = ratatouille_npc[2].Position,
		max_distance = 8,
		loop = false
	})
	music_player_util.play_sfx({
		sfx_name = '01_small_jump_01',
		play_pos = ratatouille_npc[2].Position,
		max_distance = 8,
		loop = false
	})

	character_util.remove_anim(ratatouille_npc[2])
	character_util.normal_jump(ratatouille_npc[2])
	character_util.show_emoticon_async(ratatouille_npc[2], nil, 'heart')

	-- 꼬마(left, smile, idle, jump 2회) : 헤헤! 맛있으면 다행이야, 친구!
	music_player_util.play_sfx({
		sfx_name = '01_bad_fairy_01',
		play_pos = ratatouille_npc[1].Position,
		max_distance = 8,
		loop = false
	})
	music_player_util.play_sfx({
		sfx_name = '01_small_jump_01',
		play_pos = ratatouille_npc[1].Position,
		max_distance = 8,
		loop = false
	})

	start_coroutine(function()
		character_util.normal_double_jump(ratatouille_npc[1])
	end)

	speech_bubble_util.show_speech_bubble_async(ratatouille_npc[1], { key = 'nm_ds_stage3_ratatouille_oneline_1' })

	-- 이후 둘 다 원라인으로 남아있는다.
	-- 쥐 : 하트 이모티콘 띄운다.
	character_util.add_listener(ratatouille_npc[2], self)

	-- 꼬마 : 헤헤! 맛있으면 다행이야, 친구!
	ratatouille_npc[1].Interactable.Talk = 'nm_ds_stage3_ratatouille_oneline_1'

	-- 저장
	local quest_progress = quest_util.get_started_quest(self.main_quest_id)
	quest_util.set_custom_state(quest_progress, 'stage3_ratatouille_event', 1)
end

--endregion 라따뚜이 이벤트

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	character_util.remove_relate_event(self.get_ratatouille_npc(2), self)

	for _, item in pairs(self.cached_drop_item) do
		if item ~= nil then
			item:ConsumeComplete()
			item = nil
		end
	end

	self.cached_drop_item = nil

	self.zone_enter_event_func = nil

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
