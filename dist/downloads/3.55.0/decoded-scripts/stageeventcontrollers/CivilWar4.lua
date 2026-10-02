local local_class = newclass('CivilWar4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 마나캐논
	self.get_mana_cannon = function(index)
		return get_field_object('mana_cannon_' .. index)
	end

	-- 섹션 20 종이
	self.get_paper_s20 = function()
		return get_field_object('s20_paper')
	end

	-- 감시 npc에게 걸렸을 때의 마커 이름
	self.get_reset_marker = function(index)
		return field:GetMarker('detected_reset_pos_' .. index)
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	--크로셀 ui
	self.operator_ui = nil

	-- 감시 npc에게 걸려서 연출 진행 중인가?
	self.is_detected_eventing = false

	-- 유틸
	self.util = nil

	-- 섹션 18 관련 감시 병사 인원 수
	self.solder_num_s18 = 6

	--섹션 18 관련 감시 병사 체크용 키
	self.detected_by_s18_soldier_key = function(idx)
		return 's18_detected_by_soldier_' .. idx
	end

	self.testimony_zone = 's18_testimony_zone'

	-- 섹션 18 관련 탐문 조사 npc 원라인 이벤트 봤는지 여부
	self.is_enter_testimony_zone = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.operator_ui = get_or_create_global_table('Quest/Main/CivilWar/Common/OperatorUI')
	self.operator_ui:load_async()
	return true
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

--region event
function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_paper_s20()) then
		self.util:start_scene(self.interact_paper_s20, self)
		return true
	end
	return false
end

function local_class:on_zone_enter_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local leader = get_party_leader()

	if quest_progress.InnerProgress < 20 then
		if not self.is_enter_testimony_zone and
				type_util.is_zone_full_enter(e, leader, self.testimony_zone) then
			self.is_enter_testimony_zone = true

			start_coroutine(self.enter_testimony_zone, self)

			return true
		end
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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))

	self:dispose_paper_s20()

	self.util = nil
	self.cs_controller = nil
	self.scene = nil
end

function local_class:launch_routine()
	self.util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_got_crashed_event')

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)


	--마나 캐논 비활성화
	local save_state = quest_util.get_custom_state(quest_progress, 's21_save_state_key')
	for idx = 1, save_state do
		self:deactivate_mana_cannon(idx)
	end

	-- 감시 npc 및 연구소 길막용 wall 위치 세팅
	if quest_progress ~= nil and quest_progress.InnerProgress <= 20 then
		self:set_detected_npc(quest_progress.InnerProgress)
		self:set_detected_npc_related_s18()
		self:set_testimony_npc(quest_progress.InnerProgress)
	end

	--섹션 20용 연출 아이템 세팅
	self:setting_paper_s20()

	-- 4스테이지 완료 이후 오브젝트 비활성화
	if quest_progress.InnerProgress > 21 or quest_progress.IsComplete then
		get_field_object('lab_block_wall_1').ActiveState = active_state('disabled')
		get_field_object('s18_saul_truck_1').ActiveState = active_state('disabled')
		get_field_object('s18_saul_truck_2').ActiveState = active_state('disabled')
		get_field_object('s18_saul_truck_parts_1').ActiveState = active_state('disabled')
		local lab_secret_obstacle = get_field_object('s20_secret_passage_obstacle')
		lab_secret_obstacle.Position = lab_secret_obstacle.Position + vector(2,0,0)
		self:deactivate_mana_cannon_rock_all()
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 17 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	elseif quest_progress.InnerProgress == 19 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s19_cam_pos_2_1'),
				true, false)
		--연구실에서 시작하므로 'event'로 따로 틀어줘야함.
		music_player_util.play_stage_music({
			name = 'ondemand/v2_75_civilwar/audio:bgm_civilwar_lab',
			state = 'event',
		})
	elseif quest_progress.InnerProgress == 20 then
		-- bgm clip bgm_civilwar_saul_02로 변경
		music_player_util.set_stage_music_clip_async(
				{ name = 'ondemand/v2_75_civilwar/audio:bgm_civilwar_saul_02', state = 'field' })
		
		if save_state < 0 then
			save_state = 0
		end

		local target_index = save_state + 1
		local marker = field:GetMarker('s21_start_pos_' .. target_index)
		stage_launch_util.play_launch_stage(marker.direction, marker.position,
				true, true)
	elseif quest_progress.InnerProgress == 21 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s22_start_pos'),
				false, false)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'paper_get_event' then
		self.paper_item.ConsumeTarget = get_character('demon_engineer')
		self.paper_item:Fly()
		return true
	end

	if e:GetParamAt(0) == 'paper_create_event' then
		self:setting_paper_s20()
		return true
	end

	if self.is_detected_eventing == false and e:GetParamAt(0) == 'detected_by_soldier_1' then
		-- 1번구역 걸림
		self.is_detected_eventing = true
		self.util:start_scene(self.detected_event, self, e.Sender, 'detected_by_soldier_1', 1)
		return true
	elseif self.is_detected_eventing == false and e:GetParamAt(0) == 'detected_by_soldier_2' then
		-- 2번 구역 걸림
		self.is_detected_eventing = true
		self.util:start_scene(self.detected_event, self, e.Sender, 'detected_by_soldier_2', 2)
		return true
	elseif self.is_detected_eventing == false then
		for idx = 1, self.solder_num_s18 do
			if e.Params[0] == self.detected_by_s18_soldier_key(idx) then
				self.is_detected_eventing = true
				self.util:start_scene(self.detected_event_related_s18, self, idx)
				return true
			end
		end
	end

	return false
end

-- 충돌한 guard detected_event 발생
function local_class:on_got_crashed_event(e)
	if lua_helper.reference_equals(e.Crash.other, get_party_leader()) then
		for i = 1, 3 do
			local saul_soldier = get_character('detected_saul_soldier_1_' .. i)
			if lua_helper.reference_equals(e.Crash.self, saul_soldier) then
				self.util:start_scene(self.detected_event, self, saul_soldier, 'detected_by_soldier_1', 1)
				return true
			end
		end
	end

	return false
end

-- 감시 npc 세팅
function local_class:set_detected_npc(inner_progress)
	local detected_saul_npc_name = 'detected_saul_soldier_'
	local soldier_count = 3
	for i = 2, soldier_count do
		-- detected_saul_soldier_1_1 은 21섹션 이벤트에서만 잠깐 등장하므로, 2부터 시작
		local soldier = get_character(detected_saul_npc_name .. '1_' .. i)
		character_util.set_active_state(soldier, 'enabled')
		message_system:SendSync(soldier, CS.Oak.StateResetEvent.Instance)
	end

	if inner_progress == 20 then
		soldier_count = 4
		for i = 1, soldier_count do
			local soldier = get_character(detected_saul_npc_name .. '2_' .. i)
			character_util.set_active_state(soldier, 'enabled')
			message_system:SendSync(soldier, CS.Oak.StateResetEvent.Instance)
		end
	else
		local lab_block_wall = get_field_object('lab_block_wall_1')
		lab_block_wall.Position = lab_block_wall.Position + vector(2, 0, 0)
	end
end

-- 발각 됐을 때 이벤트
function local_class:detected_event(sender, event_name, case_index)
	local leader = get_party_leader()
	local demon_engineer = get_character('demon_engineer')

	local soldier_count = case_index == 1 and 3 or 4
	local soldier_first_name = 'detected_saul_soldier_'

	local soldier_list = {}
	for i = 1, soldier_count do
		local data = {}
		data.soldier = get_character(soldier_first_name .. case_index .. '_' .. i)
		data.before_dir = data.soldier.Direction
		data.before_pos = data.soldier.Position

		local state_change_event = CS.Oak.StateChangeEvent.Create(CS.Oak.CharacterIdleState.Create(data.soldier))
		message_system:SendSync(data.soldier.FieldObjectController, state_change_event)

		scene_util.set_emotion(data.soldier, self, 'attack')
		character_util.look_at(data.soldier, leader)
		table.insert(soldier_list, data)
	end

	party_util.look_at(sender)
	character_util.jump(leader, 0.5, 0.3)
	character_util.set_emotion(leader, { name = 'scared' })
	scene_util.set_anim(leader, self, 'embarrassed')

	character_util.set_direction(demon_engineer, 'left')
	character_util.set_emotion(demon_engineer, { name = 'tired' })
	character_util.set_anim(demon_engineer, { name = 'bomb_idle' })

	local civil_female_1 = get_character('s18_civil_female_5_1')
	local civil_female_3 = get_character('s18_civil_female_5_3')

	character_util.look_at(civil_female_1, leader)
	character_util.set_emotion(civil_female_1, { name = 'scared' })

	character_util.look_at(civil_female_3, leader)
	character_util.set_emotion(civil_female_3, { name = 'scared' })

	-- 병사들 (attack표정, idle자세) : [shout] 반역자 일당을 찾았다!!!
	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	scene_util.play_shout_speech_action(sender, self, nil, 'release', nil
	, 'cw_main_s21_1')

	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	for i = 1, #soldier_list do
		local soldier = soldier_list[i].soldier
		scene_util.set_anim(soldier, self, 'prostrate')
		local rand_pos = leader.Position + vector(unity_class.random.Range(-0.15, 0.15)
		, 0, unity_class.random.Range(-0.15, 0.15))

		local dist = (soldier.Position - rand_pos).magnitude
		local speed = math.max(dist / 1, 0.5)

		character_util.jump_move(soldier, rand_pos, speed, 1.5, false)
	end

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(1, 'linear')

	-- 파티 리셋 포인트로
	local reset_marker = self.get_reset_marker(case_index)
	party_util.remove_emotion()
	party_util.remove_animation()
	party_util.align_party(reset_marker.position, reset_marker.direction, 0)

	-- 감시 npc 리셋
	for i = 1, #soldier_list do
		local soldier = soldier_list[i].soldier
		character_util.remove_anim_and_emotion(soldier)
		scene_util.set_direction(soldier, soldier_list[i].before_dir, false)
		character_util.set_position(soldier, soldier_list[i].before_pos)

		message_system:SendSync(soldier, CS.Oak.StateResetEvent.Instance)
	end

	character_util.set_direction(civil_female_1, 'left')
	character_util.set_emotion(civil_female_1, { name = 'tired' })

	character_util.set_direction(civil_female_3, 'left')
	character_util.set_emotion(civil_female_3, { name = 'tired' })
	wait_for_sec(1)

	-- 순찰자 리셋
	message_system:Publish(CS.Oak.CustomStageEvent.Create(leader, { 'reset', event_name }))
	coroutine.yield(nil)

	self.is_detected_eventing = false

	screen_util.fade_in_circular_async(1, 'linear')
end

-- 섹션 20 이전 흉악범 신고 npc 세팅
function local_class:set_testimony_npc(inner_progress)
	local testimony_pos = field_util.get_marker_pos('s19_testimony_pos')
	local civil_female_1 = get_character('s18_civil_female_5_1')
	local civil_female_3 = get_character('s18_civil_female_5_3')

	if inner_progress == 20 then
		character_util.set_direction(civil_female_1, 'left')
		character_util.set_direction(civil_female_3, 'left')
	else
		civil_female_1.Position = testimony_pos + vector(1, 0, 0)
		character_util.set_direction(civil_female_1, 'left')

		civil_female_3.Position = testimony_pos
		character_util.set_direction(civil_female_3, 'right')
	end
end

-- 섹션 18 관련 감시 npc 세팅
function local_class:set_detected_npc_related_s18()
	for i = 1, self.solder_num_s18 do
		local soldier = get_character('s18_saul_soldier_2_' .. i)
		soldier.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(
				soldier, self.detected_by_s18_soldier_key(i), 2, 60)
	end
end

-- 섹션 18 관련 감시 npc에게 발각 됐을 때 이벤트
function local_class:detected_event_related_s18(event_num)
	--병사 1,2의 어택레인지에 닿았을 경우
	local marker_scene_idx = 4
	--inspection_scene과 사용 캐릭터가 겹치므로
	local character_scene_idx = 2

	local finder_num = event_num

	if event_num % 2 == 0 then
		finder_num = event_num - 1
	end

	local get_soldier = function(scene_idx, character_idx)
		return get_character('s18_saul_soldier_' .. scene_idx .. '_' .. character_idx)
	end

	--finder 1,2면 1,2로 진행. 3,4면 3,4로 진행. 5,6면 5,6로 진행
	--finder_num == 1 or 3 or 5
	local soldier_1 = get_soldier(character_scene_idx, finder_num)
	local soldier_2 = get_soldier(character_scene_idx, finder_num + 1)

	local soldier_direction = {
		{
			init = 'right',
			face_to_face = 'down',
			prostrate = 'right'
		},
		{
			init = 'right',
			face_to_face = 'up',
			prostrate = 'right'
		},
		{
			init = 'down',
			face_to_face = 'right',
			prostrate = 'right'
		},
		{
			init = 'down',
			face_to_face = 'left',
			prostrate = 'left'
		},
		{
			init = 'up',
			face_to_face = 'right',
			prostrate = 'right'
		},
		{
			init = 'up',
			face_to_face = 'left',
			prostrate = 'left'
		},
	}

	local party_direction = {
		'left', 'left', 'up', 'up', 'down', 'down'
	}

	local detected_pos_num = {
		1, 1, 2, 2, 3, 3
	}

	local knight = get_party_leader()
	local demon_engineer = get_character('demon_engineer')

	local get_knight_pos = function(scene_idx, idx)
		return field_util.get_marker_pos('s18_knight_pos_' .. scene_idx .. '_' .. idx)
	end

	local get_demon_engineer_pos = function(scene_idx, idx)
		return field_util.get_marker_pos('s18_demon_engineer_pos_' .. scene_idx .. '_' .. idx)
	end

	local get_soldier_pos = function(scene_idx, character_idx, idx)
		return field_util.get_marker_pos('s18_saul_soldier_pos_'
				.. scene_idx .. '_' .. character_idx .. '_' .. idx)
	end

	music_player_util.change_stage_music_volume('field', 0.5)

	--병사1 (right, idle, jump 1회) : 정지!
	music_player_util.play_sfx_one_shot('01_male_shout_01')
	soldier_1.FieldObjectController = CS.Oak.NPCCharacterController()
	soldier_2.FieldObjectController = CS.Oak.NPCCharacterController()
	character_util.normal_jump(soldier_1, true)
	scene_util.play_normal_speech_action(soldier_1, self,
			soldier_direction[finder_num].init, 'idle', 'idle',
			'cw_main_s18_30')

	--가디언,비네트 1번 ■타일에 정렬 후 left 방향 바라봄.
	do
		local move_key = 'move_to_detected_scene_pos'
		wp_util.move_with_end_callback(knight,
				get_knight_pos(marker_scene_idx, detected_pos_num[finder_num]),
				4,
				nil,
				self, move_key,
				{ last_direction = party_direction[finder_num] })

		wp_util.move_with_end_callback(demon_engineer,
				get_demon_engineer_pos(marker_scene_idx, detected_pos_num[finder_num]),
				4,
				nil,
				self, move_key,
				{ last_direction = party_direction[finder_num] })
		wp_util.wait_move_end(self, move_key)
	end

	--병사1 (right, idle, release) : 잠시 검문이 있겠습니다.
	scene_util.play_normal_speech_action(soldier_1, self,
			soldier_direction[finder_num].init, 'idle', 'idle',
			'cw_main_s18_31')

	--병사1 (right, idle, question)
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_direction(soldier_1, soldier_direction[finder_num].init, false)
	scene_util.set_anim_async(soldier_1, self, { name = 'question', keep_anim = true, loop = false })

	--대기 0.5초
	wait_for_sec(0.5)

	--병사1 (right, surprise, idle) 자세로 jump 1회.
	scene_util.set_direction(soldier_1, soldier_direction[finder_num].face_to_face, false)
	character_util.remove_anim(soldier_1)
	scene_util.set_emotion(soldier_1, self, 'surprise')
	character_util.normal_jump_async(soldier_1, '01_player_jump_01')

	--병사2 up 방향 전환.
	scene_util.set_direction(soldier_2, soldier_direction[finder_num + 1].face_to_face, false)
	scene_util.set_emotion(soldier_1, self, 'surprise')

	--병사1 (down, surprise, release 2회)
	local anim_duration = spine_util.get_animation_duration(soldier_1, 'release')
	scene_util.set_direction(soldier_1, soldier_direction[finder_num].face_to_face, false)
	scene_util.set_emotion(soldier_1, self, 'surprise')
	scene_util.set_anim(soldier_1, self, { name = 'release', count = 2 })
	wait_for_sec(anim_duration * 2)

	--병사1,2 (right, surprise, idle)
	scene_util.set_direction(soldier_1, soldier_direction[finder_num].init, false)
	scene_util.set_emotion(soldier_1, self, 'surprise')
	character_util.remove_anim(soldier_1)

	scene_util.set_direction(soldier_2, soldier_direction[finder_num + 1].init, false)
	scene_util.set_emotion(soldier_2, self, 'surprise')
	character_util.remove_anim(soldier_2)

	--대기 0.5초
	wait_for_sec(0.5)

	--가디언 surprise 표정 전환.
	scene_util.set_emotion(knight, self, 'surprise')

	--(화면 0.03값으로 1초 shake하며)
	--병사1 (right, attack, idle) : [shout] 대역죄인을 찾았다!!!
	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	scene_util.play_shout_speech_action(soldier_1, self,
			soldier_direction[finder_num].init, 'attack', 'attack',
			'cw_main_s18_32')

	--가디언 (left, scared, embarrassed) 자세,
	scene_util.set_direction(knight, 'left', false)
	scene_util.set_emotion(knight, self, 'surprise')
	scene_util.set_anim(knight, self, 'embarrassed')

	--비네트는 (left, tired, bomb_idle) 자세
	scene_util.set_direction(demon_engineer, 'left', false)
	scene_util.set_emotion(demon_engineer, self, 'tired')
	scene_util.set_anim(demon_engineer, self, 'bomb_idle')

	--동시에 병사 1,2 NPC (right, attack, prostrate) 자세로 가디언을 향해 jump.
	scene_util.set_direction(soldier_1, soldier_direction[finder_num].prostrate, false)
	scene_util.set_direction(soldier_2, soldier_direction[finder_num + 1].prostrate, false)

	--안1, 2, 3, 가디언 전부 greed, prostrate로 뛰어든다.
	--카메라 0.5초에 걸쳐 0.6배로 줌인
	local soldiers = {
		soldier_1, soldier_2
	}
	local vector_scatter = {
		vector(-0.4, 0.2, 0),
		vector(0.3, 0, 0)
	}
	--music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	--music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	camera_util.resize_by_ratio(4 * 0.6, 0.5)
	table_util.for_each(soldiers, function(i, soldier)
		scene_util.set_anim(soldier, self, 'prostrate')
		scene_util.set_emotion(soldier, self, 'attack')
		character_util.jump(soldier, 0.7 + (0.3 * i), 0.5)
		character_util.move_to(soldier, knight.Position + vector_scatter[i],
				0.5, nil, false, false)
	end)

	wait_for_sec(0.2)

	time_util.mod('prostrate', 0.2)

	--해당 연출과 동시에 서큘러 페이드 아웃 게임오버.
	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.3, 'linear')
	time_util.unmod('prostrate')

	wait_for_sec(0.3)
	camera_util.resize_to_default(0)
	camera_util.return_to_leader(0)

	for soldier_idx = 1, self.solder_num_s18 do
		local soldier = get_soldier(character_scene_idx, soldier_idx)

		character_util.remove_anim_and_emotion(soldier)

		character_util.set_position(soldier,
				get_soldier_pos(character_scene_idx, soldier_idx, 1))

		character_util.set_direction(soldier, soldier_direction[soldier_idx].init)
	end
	self:set_detected_npc_related_s18()

	character_util.set_position(knight,
			get_knight_pos(marker_scene_idx, 4))
	character_util.set_direction(knight, 'left')
	character_util.remove_anim_and_emotion(knight)

	character_util.set_position(demon_engineer,
			get_demon_engineer_pos(marker_scene_idx, 4))
	character_util.set_direction(demon_engineer, 'left')
	character_util.remove_anim_and_emotion(demon_engineer)

	self.is_detected_eventing = false

	music_player_util.change_stage_music_volume('field', 1)

	--이후 플레이어 ■타일에 (left, idle, idle) 자세로 서큘러 페이드 인.
	screen_util.fade_in_circular_async(0.7, 'linear')
end

function local_class:enter_testimony_zone()
	local civil_female_1 = get_character('s18_civil_female_5_1')
	local civil_female_3 = get_character('s18_civil_female_5_3')
	--플레이어 비강제 트리거 존 진입 시, 하단의 대사 자동 출력.

	--여1 (left, tired, cast) : 그게 사실이야? 흉악범을 봤다는게?!
	scene_util.play_normal_speech_action(civil_female_1, self,
			nil, nil, nil,
			{ key = 'cw_main_s18_35',
			  skip = false })
	--여3 (right, tired, release) : 응! 어떤 이상하게 생긴 놈하고 같이 다니고 있었어!
	scene_util.set_emotion(civil_female_3, self, 'tired')
	scene_util.play_normal_speech_action(civil_female_3, self,
			nil, 'release', nil,
			{ key = 'cw_main_s18_36',
			  skip = false })
	--여1 (left, damaged, cast 0.03값 shake 1초) : 무서워…! 빨리 신고하자!
	local runaway_sfx = music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = civil_female_1 })
	character_util.shake(civil_female_1, 0.03, 1)
	scene_util.set_emotion(civil_female_1, self, 'damaged')
	scene_util.set_anim(civil_female_1, self, 'cast')
	scene_util.play_normal_speech_action(civil_female_1, self,
			nil, nil, nil,
			{ key = 'cw_main_s18_37',
			  skip = false })
end

function local_class:setting_paper_s20()
	local paper = get_field_object('s20_paper')

	local paper_item_data = {
		pos = paper.Position + vector(0, 1, -0.5),
		itemid = 21059, notforinven = true,
		lootstate = 'dontfindlooter', sprscale = 1.0, skip_text = true
	}
	self.paper_item = drop_item_util.create_item(paper_item_data)

	paper.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:dispose_paper_s20()
	if self.paper_item ~= nil then
		self.paper_item:ConsumeComplete()
		self.paper_item = nil
	end
end

function local_class:interact_paper_s20()
	--이후 paper_piece 아이템에 인터렉트 시, 하단의 나레이션 박스 출력.

	--『헤븐홀드 연구 진행 문서』
	field_ui_util.show_narration_async({ key = 'cw_main_s20_paper_1' })

	--『수석 연구원 엘리 , 공업 기술자 하워드,
	--화학 연구원 에디, 의료 생명 연구원 레니,
	--안드로이드 공학자 론, 개발 총괄자 비네트』
	field_ui_util.show_narration_async({ key = 'cw_main_s20_paper_2' })

	--『이상 6명의 인원을 헤븐홀드 프로젝트의 개발 연구원으로 임명한다.』
	field_ui_util.show_narration_async({ key = 'cw_main_s20_paper_3' })
end

function local_class:deactivate_mana_cannon(idx)
	if idx >= 4 then
		return false
	end

	local mana_cannon = get_field_object('mana_cannon_' .. idx)
	local mana_cannon_broken = get_field_object('mana_cannon_broken_' .. idx)
	local mana_cannon_pos = mana_cannon.Position
	mana_cannon_broken.Position = mana_cannon_pos
	mana_cannon.ActiveState = active_state('disabled')
	return true
end

function local_class:deactivate_mana_cannon_rock_all()
	local get_rock = function(region, idx)
		return get_field_object('mana_cannon_rock_' .. region .. '_' .. idx)
	end

	-- 각 지역당 바위 갯수
	local rock_num = {
		5, 7, 6
	}

	for i = 1, #rock_num do
		for j = 1, rock_num[i] do
			local rock = get_rock(i, j)
			rock.ActiveState = active_state('disabled')
		end

	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
