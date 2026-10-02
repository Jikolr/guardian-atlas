local local_class = newclass('QueenShip1At6Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 꼬마 공주
	self.get_princess = function() return get_character('princess') end

	-- ifo
	self.get_flame_machine = function(num) return get_field_object('s24_flame_machine_' .. num) end

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- 개 흉내 인베이더 이동 루틴 작동 여부
	self.stop_dog_invader_routine = false
	-- 동적 생성 캐릭터 리스트
	self.optimized_npcs = nil

	self.clear_area_1_enter_event_setting = false
	self.area_1_enter_event = {
		{
			zone = 's24_area_1_zone_2',
			seen_event = false,
			cb = self.area_1_talk_event_1
		},
		{
			zone = 's24_area_1_invader_talk_1',
			seen_event = false,
			cb = self.area_1_talk_event_2
		},
		{
			zone = 's24_area_1_invader_talk_2',
			seen_event = false,
			cb = self.area_1_talk_event_3
		}
	}

	self.is_destroyed_rock = false

	self.stop_move_key = false
end

function local_class:load_resource()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	local lever = get_field_object('area_2_puzzle_lever')
	-- 24섹션 퍼즐 레버
	if lua_helper.reference_equals(e.Target, lever) and
			not lua_helper.type_compare(lever.Interactable, typeof(CS.Oak.NonInteractable)) then
		lever.Interactable = CS.Oak.NonInteractable.Instance
		start_coroutine(self.interact_puzzle_lever, self)
		return
	end
end

function local_class:on_zone_enter_event(e)
	if not self.clear_area_1_enter_event_setting then return end

	for i = 1, #self.area_1_enter_event do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.area_1_enter_event[i].zone)
				and not self.area_1_enter_event[i].seen_event then
			self.area_1_enter_event[i].seen_event = true
			start_coroutine(self.area_1_enter_event[i].cb, self)
			return true
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	-- 24섹션 퍼즐 바위
	if lua_helper.reference_equals(e.FieldObject, get_field_object('area_2_puzzle_rock')) then
		self.is_destroyed_rock = true
		return true
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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.stop_dog_invader_routine = true

	self.stop_move_key = true

	if self.optimized_npcs ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_npcs)
		self.optimized_npcs = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'conveyor_belt_control', 'area_2_puzzle', 'off' }))

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = user_util.get_knight_character('knight_female', 'knight_male')
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

	-- 캡슐 속 시민 세팅
	self:caspule_civil_setting()
	-- 배터리 기계 세팅
	self:battery_machine_setting()

	if main_quest_progress.IsComplete or main_quest_progress.InnerProgress > 23 then
		self:deactivate_flame_machine()
	end

	-- 6스테이지 메인 퀘스트들 클리어 전
	if main_quest_progress.InnerProgress < 27 then
		-- 6스테이지 출구 막는 문 닫아놓기
		message_system:Publish(CS.Oak.DoorCloseEvent.Create('stage_6_exit_door_1'))

		self:area_1_enter_event_setting()
	end

	-- 메인프로그레스가 26 이상인데 ammi가 안죽어 있다면 비활성화하고 죽도록 처리
	if main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 26 then
		local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants').common
		if stage_progress_util.get_custom_data_int(custom_keys.ammi_dead, 0) == 0 then
			stage_progress_util.set_custom_data_async(custom_keys.ammi_dead, 1)
			message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'deactivate_ammi' }))
		end
	end

	if main_quest_progress == nil or main_quest_progress.IsComplete then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('bulkhead_door_1'))
		change_leader_character({ self.get_princess(), user_util.get_china_hero_character('fei', 'mei') })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 21 then
		change_leader_character({ self.get_princess() })
		start_stage_event('left', field:GetMarker('s22_start').position, false, true)
	elseif main_quest_progress.InnerProgress == 22 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field:GetMarker('s23_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 23 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 24 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field:GetMarker('broken_ammi_pos').position + vector(-1.5, 0, 0.5),
				false, true)
	elseif main_quest_progress.InnerProgress == 25 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 26 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('bulkhead_door_1'))
		change_leader_character({ self.get_princess(), user_util.get_china_hero_character('fei', 'mei') })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	else
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('bulkhead_door_1'))
		change_leader_character({ self.get_princess(), user_util.get_china_hero_character('fei', 'mei') })
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end
end

-- 화염방사기 비활성화
function local_class:deactivate_flame_machine()
	local flame_machine_count = 14
	for i = 1, flame_machine_count do
		self.get_flame_machine(i).FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()
	end
end

-- 1구역 이벤트 세팅
function local_class:area_1_enter_event_setting()
	self.clear_area_1_enter_event_setting = true

	self.optimized_npcs = load_util.create_optimized_npcs_async({
		invader_1 = 'qs_invader_soldier',
		invader_2 = 'qs_invader_soldier',
		invader_3 = 'qs_invader_engineer',
		invader_4 = 'qs_invader_soldier',
		invader_5 = 'qs_invader_soldier',
		invader_6 = 'qs_invader_soldier',
		invader_7 = 'qs_invader_soldier'
	})

	character_util.set_position(self.optimized_npcs['invader_1'], 	field:GetMarker('s24_area_1_invader_pos_3').position)
	character_util.set_position(self.optimized_npcs['invader_2'], 	field:GetMarker('s24_area_1_invader_pos_4').position)

	character_util.set_position(self.optimized_npcs['invader_3'], 	field:GetMarker('s24_area_1_invader_pos_9').position)
	character_util.set_position(self.optimized_npcs['invader_4'], 	field:GetMarker('s24_area_1_invader_pos_10').position)
	character_util.set_direction(self.optimized_npcs['invader_3'], 'right')
	character_util.set_direction(self.optimized_npcs['invader_4'], 'left')

	character_util.set_position(self.optimized_npcs['invader_5'], 	field:GetMarker('s24_area_1_invader_pos_11').position)
	character_util.set_position(self.optimized_npcs['invader_6'], 	field:GetMarker('s24_area_1_invader_pos_12').position)
	character_util.set_position(self.optimized_npcs['invader_7'], 	field:GetMarker('s24_area_1_invader_pos_13').position)
	character_util.set_anim_and_emotion(self.optimized_npcs['invader_5'], { name = 'walk4legs' }, { name = 'doyagao' })
	character_util.set_anim(self.optimized_npcs['invader_6'], { name = 'release' })
	character_util.set_anim_and_emotion(self.optimized_npcs['invader_7'], { name = 'clap' }, { name = 'smile' })
	character_util.set_direction(self.optimized_npcs['invader_6'], 'right')
	character_util.set_direction(self.optimized_npcs['invader_7'], 'left')

	start_coroutine(self.area_1_dog_invader_routine, self)
end

-- 1구역 대화 이벤트1
function local_class:area_1_talk_event_1()
	local invader_1 = self.optimized_npcs['invader_1']
	local invader_2 = self.optimized_npcs['invader_2']

	wp_util.move(invader_1, invader_1.Position + vector(0, 0, -3.5), nil,
    				2, { last_direction = 'right' })

	wp_util.move(invader_2, invader_2.Position + vector(0, 0, -3.5), nil,
    				2, { last_direction = 'left' })
	-- 카레라이스를 좋아하던 그 친구… 오늘은 안 보이네.
	speech_bubble_util.show_speech_bubble_async(invader_2, { key = 'qs_main_s24_4', bubble_direction = 'rb' })

	character_util.set_emotion(invader_1, { name = 'tired' })
	character_util.set_anim(invader_1, { name = 'cast' })
	-- 가디언 그 놈 한 명 잡으려고 이게 무슨 고생이야.
	speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'qs_main_s24_5', bubble_direction = 'lb' })
	character_util.remove_anim_and_emotion(invader_1)

	character_util.set_anim_and_emotion(invader_2, { name = 'release', sfx_name = '01_swing_01' }, { name = 'doyagao' })
	-- 볼트 그놈은 벌써 가디언한테 된통 깨졌다더라!
	speech_bubble_util.show_speech_bubble_async(invader_2, { key = 'qs_main_s24_6', bubble_direction = 'rb' })
	character_util.remove_anim_and_emotion(invader_2)
end

-- 1구역 대화 이벤트2
function local_class:area_1_talk_event_2()
	local invader_1 = self.optimized_npcs['invader_3']
	local invader_2 = self.optimized_npcs['invader_4']

	-- 오늘 납품할 다리는 이걸로 끝이지?
	speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'qs_main_s24_6_1' })

	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	character_util.set_anim(invader_2, { name = 'salute', loop = false })
	-- 예, 그렇습니다!
	speech_bubble_util.show_speech_bubble_async(invader_2, { key = 'qs_main_s24_6_2' })
	character_util.remove_anim(invader_2)
end

-- 1구역 대화 이벤트3
function local_class:area_1_talk_event_3()
	local invader_1 = self.optimized_npcs['invader_5']
	local invader_2 = self.optimized_npcs['invader_6']
	local invader_3 = self.optimized_npcs['invader_7']

	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	-- 나는 마기~ 4군단장 님의 충실한 발닦개, 멍멍!
	speech_bubble_util.show_speech_bubble_async(invader_1, { key = 'qs_main_s24_6_3' })

	music_player_util.play_sfx_one_shot('01_ghost_laugh_evil_01')
	--우리 볼트 잘 짖네!
	speech_bubble_util.show_speech_bubble_async(invader_3, { key = 'qs_main_s24_6_4' })

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	--야 그만해! 이거 걸리면 그놈 또 발작한다고!
	speech_bubble_util.show_speech_bubble_async(invader_2, { key = 'qs_main_s24_6_5' })
end

-- 1구역 개 흉내 인베이더 이동 루틴
function local_class:area_1_dog_invader_routine()
	local invader = self.optimized_npcs['invader_5']
	local patrol_list = { field:GetMarker('s24_area_1_invader_pos_11').position + vector(0, 0, -2),
						field:GetMarker('s24_area_1_invader_pos_11').position + vector(-3, 0, -2),
						field:GetMarker('s24_area_1_invader_pos_11').position + vector(-3, 0, 0),
						field:GetMarker('s24_area_1_invader_pos_11').position }

	while not self.stop_dog_invader_routine do
		for i = 1, #patrol_list do
			if self.stop_dog_invader_routine then
				return
			end

			local look_dir = vector_util.to_direction(patrol_list[i] - invader.Position)
			invader.Direction = look_dir == CS.Oak.Direction.None and fo.Direction or look_dir

			local progress = 0
			local time_passed = 0
			local duration = 1
			local start_pos = invader.Position
			while progress < 1 do
				if self.stop_dog_invader_routine then
					return
				end

				progress = time_passed /duration

				local pos = unity_class.vector3.Lerp(start_pos, patrol_list[i], progress)
				invader.Position = pos

				time_passed = time_passed + unity_class.time.deltaTime
				coroutine.yield(nil)
			end
			invader.Position = patrol_list[i]
		end
		coroutine.yield(nil)
	end
end

-- 캡슐 속 시민 세팅
function local_class:caspule_civil_setting()
	for i = 1, 6 do
		local civil = get_character('s25_capsule_civil_' .. i)
		character_util.set_anim(civil, { name = 'idle', loop = false })
		field_ui_manager:RemoveUI(civil, CS.Oak.FieldUiType.CharacterStats)
	end
	for i = 5, 8 do
		local civil = get_character('s25_civil_' .. i)
		character_util.set_anim(civil, { name = 'idle', loop = false })
		field_ui_manager:RemoveUI(civil, CS.Oak.FieldUiType.CharacterStats)
	end
end

-- 배터리 에너지 게이지 0으로
function local_class:battery_machine_setting()
	local battery_machine = get_field_object('s25_battery_machine')
	local battery = battery_machine.transform:Find('biological_battery_glow')
	battery.transform.localScale = vector(0, 1, 1)
end

-- 24섹션 2구역 퍼즐 레버 작동
function local_class:interact_puzzle_lever()
	local lever = get_field_object('area_2_puzzle_lever')

	wait_for_sec(0.2)

	music_player_util.play_sfx({
		sfx_name = '01_gear_02', play_pos = lever.Position, type_priority = 'gimmick', player_priority = 'object'
	})
	local animator = lever:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('pull')

	wait_for_sec(0.5)
	-- 컨베이어 벨트 작동
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'conveyor_belt_control', 'area_2_puzzle', 'on' }))

	-- 문이 열려있지 않으면 열쇠 이동 루틴 실행
	if not get_field_object('s24_area_2_keydoor_1').FieldObjectBehaviour.Opened then
		start_coroutine(self.conveyor_belt_key_routine, self)
	end
end

-- 24섹션 2구역 열쇠 이동 루틴
function local_class:conveyor_belt_key_routine()
	local key = get_field_object('s24_area_2_door_key_1')

	self:move_key('area_2_puzzle_key_pos_1')
	self:move_key('area_2_puzzle_key_pos_2')
	while not self.is_destroyed_rock do
		if self.stop_move_key then
			return
		end
		coroutine.yield()
	end

	self:move_key('area_2_puzzle_key_pos_3')
	self:move_key('area_2_puzzle_key_pos_4')
	self:move_key('area_2_puzzle_key_pos_5')
	self:move_key('area_2_puzzle_key_pos_6')
	self:move_key('area_2_puzzle_key_pos_7')
	key.Holdable = CS.Oak.Holdable()
end

-- 열쇠 이동
function local_class:move_key(pos_marker)
	local key = get_field_object('s24_area_2_door_key_1')
	local speed = 2.5
	local start_pos = key.Position
	local end_pos = field:GetMarker(pos_marker).position
	local duration = unity_class.vector3.Distance(start_pos, end_pos) / speed
	local time_passed = 0

	while time_passed < duration do
		if self.stop_move_key then
			return
		end

		local progress = unity_class.mathf.Clamp01(time_passed / duration)
		local cur_pos = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		key.Position = cur_pos

		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield(nil)
	end

	key.Position = end_pos
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
