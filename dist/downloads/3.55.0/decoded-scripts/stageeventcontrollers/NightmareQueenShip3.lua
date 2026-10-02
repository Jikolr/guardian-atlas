local local_class = newclass('NightmareQueenShip3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 435

	self.get_hit = function()
		return unity_object_pool.GetOrCreate('FX_hit')
	end

	-- AMMI
	self.ammi_controller = nil

	-- ammi 막는 door
	self.ammi_outer_door_first_name = 'ammi_zone_outer_door_'
	self.base_door_first_name = 'base_center_door_'

	self.door_count = 2

	self.is_camera_zoom_out = false

	self.is_dispose = false

	self.prequel_first_event_state = {
		none = 1,
		play_event = 2,
		end_event = 3,
	}

	self.cur_prequel_first_event_state = self.prequel_first_event_state.none

	self.request_id = 0
	self.max_request_id = 10

	self.is_first_prequel_event = false
	self.is_left_attack = true

	self.get_ribbon_wall = function()
		return get_field_object('s10_ribbon_wall')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
	self.is_dispose = true

	if self.ammi_controller ~= nil then
		self.ammi_controller:dispose()
		self.ammi_controller = nil
	end

	if self.ribbon_item ~= nil then
		drop_item_util.dispose_item(self.ribbon_item)
		self.ribbon_item = nil
	end
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 11섹션 부터는 ammi를 잡았으니 등장하지 않는다
	if quest_progress ~= nil and quest_progress.InnerProgress < 10 then
		local is_create
		is_create, self.ammi_controller = global_table_util.try_create('Quest/Nightmare/QueenShip/Common/NightmareQueenShipAMMI')
	end

	-- 페이/메이 ammi 세팅
	local china_hero_ammi = user_util.get_china_hero_character('s9_ammi_boy', 's9_ammi_girl')
	china_hero_ammi.Position = field_util.get_marker_pos('s9_china_hero_pivot')
	field_object_util.set_active_state(china_hero_ammi, active_state_type.enabled)

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	if quest_progress ~= nil and quest_progress.InnerProgress > 7 then
		message_system:Subscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent), 'on_watching_camera_grid_changed_event')
	else
		message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
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
	if type_util.is_interacted_target(e, self.get_ribbon_wall()) then
		start_coroutine(self.interact_ribbon, self)
		return true
	end

	return false
end

function local_class:on_watching_camera_grid_changed_event(e)
	if e.CameraGrid == nil then
		return false
	end

	if e.CameraGrid.name == 'ammi_grid' then
		self:camera_zoom_out(5.5, 0)

		-- ammi 구역 왔을 때 문 다열어줌
		for i = 1, self.door_count do
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.ammi_outer_door_first_name .. i, false))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.base_door_first_name .. i, false))
		end

		return true
	end

	self:reset_camera_zoom(0)
	return false
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_enter(e, leader, 'base_center_zone') then
		local leader_dist = 999
		local target_door_name = nil

		for i = 1, self.door_count do
			local door_name = self.base_door_first_name .. i
			local door = get_field_object(door_name)
			local cur_dist = (leader.Position - door.Position).magnitude

			if cur_dist <= 5 and cur_dist < leader_dist then
				leader_dist = cur_dist
				target_door_name = door_name
			end
		end

		if target_door_name ~= nil then
			message_system:Publish(CS.Oak.DoorCloseEvent.Create(target_door_name, false))
		end

		self:reset_camera_zoom()
		return true
	elseif not self.is_enter_prequel_zone and type_util.is_zone_full_enter(e, leader, 'prequel_event_zone') then
		self.is_enter_prequel_zone = true

		if self.cur_prequel_first_event_state ~= self.prequel_first_event_state.play_event then
			start_coroutine(self.start_prequel_event, self)
		end

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_leave(e, leader, 'base_center_zone') then
		self:camera_zoom_out()
		return true
	end

	if type_util.is_zone_full_leave(e, leader, 'ammi_chasing_zone_1')
			or type_util.is_zone_full_leave(e, leader, 'ammi_chasing_zone_2') then

		local leader_dist = 999
		local target_door_name = nil

		for i = 1, self.door_count do
			local door_name = self.ammi_outer_door_first_name .. i
			local door = get_field_object(door_name)
			local cur_dist = (leader.Position - door.Position).magnitude

			if cur_dist <= 5 and cur_dist < leader_dist then
				leader_dist = cur_dist
				target_door_name = door_name
			end
		end

		if target_door_name ~= nil then
			message_system:Publish(CS.Oak.DoorCloseEvent.Create(target_door_name, false))
		end

		return true
	elseif type_util.is_zone_full_leave(e, leader, 'prequel_event_zone') then
		self.is_enter_prequel_zone = false

		return true
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	-- 섹션 8로 넘어왔을 때
	if e.QuestId == self.main_quest_id and e.CurrentProgress >= 8 then
		message_system:Subscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent), 'on_watching_camera_grid_changed_event')
		message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
		return true
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	if self.ammi_controller ~= nil then
		self.ammi_controller:ammi_pre_setting(self)
	end
end

function local_class:on_stage_start_event(_)
	if self.is_stage_cleared() then

		return false
	end

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	--11섹션으로 넘어간 이후 스테이지 미클리어시 퀘스트 마커 노출
	if quest_progress ~= nil and
			quest_progress.InnerProgress > 9 then
		quest_marker_util.add_auto_control('main_quest', {
			{ zone = 'left_field', target = get_field_object('base_inner_4') },
			{ zone = 'down_field', target = get_field_object('base_inner_2') },
			{ zone = 'right_field', target = get_field_object('base_inner_1') },
			{ zone = 'main_field', target = get_field_object('exit_nightmare_queenship_3') },
		})

		return true
	end

	return false
end
--endregion event

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

	-- 10섹션 이후는 리본 세팅
	if quest_progress ~= nil and quest_progress.InnerProgress > 9 then
		self:setting_ribbon()
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s9_start_pos'), true, true)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('s10_start_pos'), true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:camera_zoom_out(size, duration)
	if not self.is_camera_zoom_out then
		size = lua_helper.get_or_default(size, 5.5)
		duration = lua_helper.get_or_default(duration, 0.5)

		self.is_camera_zoom_out = true
		camera_util.resize_by_ratio(size, duration)
	end
end

-- 카메라 줌 아웃 초기화
function local_class:reset_camera_zoom(duration)
	if self.is_camera_zoom_out then
		self.is_camera_zoom_out = false
		duration = lua_helper.get_or_default(duration, 0.5)

		camera_util.resize_to_default(duration)
	end
end

function local_class:start_prequel_event()
	local vr_invader = { get_character('vr_invader_1'), get_character('vr_invader_2') }

	do
		-- 첫 진행일 경우 처음 연출 재생
		if self.cur_prequel_first_event_state == self.prequel_first_event_state.none then
			self.cur_prequel_first_event_state = self.prequel_first_event_state.play_event
			self:prequel_first_event(vr_invader)
			self.cur_prequel_first_event_state = self.prequel_first_event_state.end_event

			if not self.is_enter_prequel_zone then
				return false
			end
		end
	end

	do
		-- 리퀘스트 아이디 갱신
		self.request_id = self.request_id + 1

		if self.request_id > self.max_request_id then
			self.request_id = 1
		end
	end

	local cur_request_id = self.request_id

	-- 루틴 멈춰야하는지 여부
	local function is_routine_active()
		return self.is_enter_prequel_zone and not self.is_dispose and self.request_id == cur_request_id
	end

	local function local_wait_for_sec(time)
		local s = unity_class.time.time

		while unity_class.time.time - s < time and is_routine_active() do
			coroutine.yield(nil)
		end
	end

	while is_routine_active() do
		local sender = self.is_left_attack and vr_invader[1] or vr_invader[2]
		local target = self.is_left_attack and vr_invader[2] or vr_invader[1]

		scene_util.set_anim(sender, self, {
			name = 'attack', loop = false, next_anim = 'idle', sfx_name = '01_hit_npc_01' })

		local_wait_for_sec(0.05)
		if not is_routine_active() then
			return
		end

		local deviation = self.is_left_attack and vector(0.5, 0, 0) or vector(-0.5, 0, 0)
		character_util.spine_deviate_local(sender, deviation, 0.2, 0.1)

		local_wait_for_sec(0.2)
		if not is_routine_active() then
			return
		end

		self.get_hit():Instantiate(target.Position + vector(0, 0.1, 0))
		character_util.remove_anim(target)
		character_util.spine_damage_red_pulse(target)
		character_util.spine_damage_squish_default(target)

		self.is_left_attack = self.is_left_attack == false
		local_wait_for_sec(1)
	end
end

function local_class:prequel_first_event(vr_invader)
	-- 인베이더 1 (down,idle,idle) : 캔터베리 기사단장 데이터로 할까? 설설 기는 게 재밌던데.
	speech_bubble_util.show_speech_bubble_async(vr_invader[1], { key = 'nm_qs_main_stage3_event_1' })
	if self.is_dispose then
		return
	end

	-- 인베이더 2 (down,idle,idle) : 우웩, 나는 오염생물 모습으로는 죽어도 못해.
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_tipsy_01', max_distance = 8, loop = false, parent = vr_invader[2],
		type_priority = 'event', player_priority = 'npc'
	})

	speech_bubble_util.show_speech_bubble_async(vr_invader[2], { key = 'nm_qs_main_stage3_event_2' })
	if self.is_dispose then
		return
	end
	-- 인베이더 1 (down,idle,idle) : 나도 그냥 농담한거야.
	speech_bubble_util.show_speech_bubble_async(vr_invader[1], { key = 'nm_qs_main_stage3_event_3' })
	if self.is_dispose then
		return
	end

	-- 인베이더 1,2, VR 기기를 쓰는 연출
	-- 인베이더 1 (right,idle,eat) 2초
	-- 인베이더 2 (left,idle,eat) 2초

	local eat_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', max_distance = 8, loop = true, parent = vr_invader[1],
		type_priority = 'event', player_priority = 'npc'
	})

	character_util.set_direction(vr_invader[1], 'right')
	character_util.set_direction(vr_invader[2], 'left')
	scene_util.set_group_anim(vr_invader, self, 'eat')

	wait_for_sec(2)
	eat_sfx:Stop()

	if self.is_dispose then
		return
	end

	-- 인베이더 2 (left,vr,cast2)
	music_player_util.play_sfx({
		sfx_name = '01_glitch_01', max_distance = 8, loop = false, parent = vr_invader[1],
		type_priority = 'event', player_priority = 'npc'
	})
	scene_util.set_group_emotion(vr_invader, self, 'vr')
	scene_util.set_group_anim(vr_invader, self, 'cast2')

	-- 1.5초 대기
	wait_for_sec(1.5)

	-- 인베이더 2 (left,idle,idle) : 이거 진짜 리얼한데?
	character_util.remove_anim(vr_invader[2])
	speech_bubble_util.show_speech_bubble_async(vr_invader[2], { key = 'nm_qs_main_stage3_event_4' })
	if self.is_dispose then
		return
	end

	-- 인베이더 2 대사 끝남과 동시에 인베이더 1 제자리에서 jump 1회 + notice 이모티콘.
	music_player_util.play_sfx({
		sfx_name = '01_small_jump_01', max_distance = 8, loop = false, parent = vr_invader[1],
		type_priority = 'event', player_priority = 'npc'
	})

	music_player_util.play_sfx({
		sfx_name = '01_jump_02', max_distance = 8, loop = false, parent = vr_invader[1],
		type_priority = 'event', player_priority = 'npc'
	})

	character_util.remove_anim(vr_invader[1])
	character_util.normal_jump(vr_invader[1])
	character_util.show_emoticon_async(vr_invader[1], nil, 'notice')
	if self.is_dispose then
		return
	end

	-- 인베이더 1 (right,idle,handgun_idle) : 가디언 이 자식!
	scene_util.set_anim(vr_invader[1], self, 'handgun_idle')
	speech_bubble_util.show_speech_bubble_async(vr_invader[1], { key = 'nm_qs_main_stage3_event_5' })

	-- 인베이더 1이 0.5타일 우측으로 이동하며 인베이더 2를 공격.
	start_coroutine(function()
		scene_util.set_anim(vr_invader[1], self, {
			name = 'attack', loop = false, next_anim = 'idle', sfx_name = '01_hit_npc_01' })
		wait_for_sec(0.05)
		if self.is_dispose then
			return
		end

		character_util.spine_deviate_local(vr_invader[1], vector(0.5, 0, 0), 0.2, 0.1)
		wait_for_sec(0.2)
		if self.is_dispose then
			return
		end

		self.get_hit():Instantiate(vr_invader[2].Position + vector(0, 0.1, 0))
		character_util.spine_damage_red_pulse(vr_invader[2])
		character_util.spine_damage_squish_default(vr_invader[2])
	end)

	-- 인인베이더 1 (right,idle,attack 1회) : 슉, 슈슈슉! 죽어라 가디언!
	speech_bubble_util.show_speech_bubble_async(vr_invader[1], { key = 'nm_qs_main_stage3_event_9' })

	-- 인베이더 2 (left,idle,cast2) : 아악! 이 오염생물이 감히 선빵을 쳐?!
	music_player_util.play_sfx({
		sfx_name = '01_kid_boy_shout_01', max_distance = 8, loop = false, parent = vr_invader[2],
		type_priority = 'event', player_priority = 'npc'
	})
	scene_util.set_anim(vr_invader[2], self, 'cast2')
	speech_bubble_util.show_speech_bubble_async(vr_invader[2], { key = 'nm_qs_main_stage3_event_7' })

	-- 인베이더 2도 인베이더 1을 공격.
	start_coroutine(function()
		scene_util.set_anim(vr_invader[2], self, {
			name = 'attack', loop = false, next_anim = 'idle', sfx_name = '01_hit_npc_01' })
		wait_for_sec(0.05)
		if self.is_dispose then
			return
		end

		character_util.spine_deviate_local(vr_invader[2], vector(-0.5, 0, 0), 0.2, 0.1)
		wait_for_sec(0.2)
		if self.is_dispose then
			return
		end

		self.get_hit():Instantiate(vr_invader[1].Position + vector(0, 0.1, 0))
		character_util.remove_anim(vr_invader[1])
		character_util.spine_damage_red_pulse(vr_invader[1])
		character_util.spine_damage_squish_default(vr_invader[1])
	end)

	-- 인베이더 2 (left,idle,attack) : 오염생물 박멸!
	speech_bubble_util.show_speech_bubble_async(vr_invader[2], { key = 'nm_qs_main_stage3_event_8' })
end

function local_class:setting_ribbon()
	local ribbon = self.get_ribbon_wall()
	local ribbon_pos = ribbon.Position

	if self.ribbon_item ~= nil then
		return
	end

	self.ribbon_item = quest_drop_item_util.create_item({
		pos = ribbon_pos,

		item_id = 21338,

		unique_id = 's10_ribbon',

		loot_state = quest_drop_item_loot_state.dont_find_looter,

		skip_text = false
	})

	ribbon.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:interact_ribbon()
	local invader_knight = get_party_leader()
	local little_girl = user_party[1]
	local ribbon_pos = field_util.get_marker_pos('s10_emp_pivot') + vector(-7.5, 0, 1.5)

	if little_girl == nil then
		return
	end

	sp_util.enter_scene(nil)

	music_player_util.change_stage_music_volume('field', 0.5)

	--리본 아이템에 인터랙트시 그 자리에서 플레이어 컨트롤 빼앗고 이벤트 진행

	--1초간 위와 같이 정렬
	--베스 (left,idle,idle)
	--신디 (left,idle,idle)
	wp_util.move(little_girl, ribbon_pos + vector(1.5, 0, -0.5), nil, 1, { last_direction = 'left' })
	wp_util.move_async(invader_knight, ribbon_pos + vector(1.5, 0, 0.5), nil, 1, { last_direction = 'left' })

	--신디 (left,smile,cast) : 저 아무래도 간호에 재능이 있는 것 같아요!
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	scene_util.play_normal_speech_action(little_girl, self,
			{ dir = 'left', sfx = false },
			{ name = 'cast' },
			'smile',
			{ key = 'nm_qs_main_s10_68', skip = true })
	--신디 (left,smile,release) : 보여요? 언니 상처를 닦느라 희생된 리본이!
	scene_util.play_normal_speech_action(little_girl, self,
			{ dir = 'left', sfx = false },
			{ name = 'release' },
			{ name = 'smile', keep = true },
			{ key = 'nm_qs_main_s10_69', skip = true })

	--베스 머리 위로 silence 이모티콘 출력
	character_util.show_emoticon_async(invader_knight, nil, 'silence')

	--베스 (down,idle,idle) : 리본 더럽히는 재능이 있는 거겠지.
	--신디 (up,idle,idle)
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.remove_anim_and_emotion(little_girl)
	character_util.set_direction(little_girl, 'up')
	scene_util.play_normal_speech_action(invader_knight, self,
			{ dir = 'down', sfx = false },
			nil,
			nil,
			{ key = 'nm_qs_main_s10_70', skip = true })

	--신디 (left,tried,idle) 상태로 notice 이모티콘 출력
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.set_direction(little_girl, 'left', false)
	character_util.set_emotion(little_girl, { name = 'tired' })
	character_util.show_emoticon_async(little_girl, nil, 'sweat')

	--플레이어 컨트롤 해제.
	character_util.remove_anim_and_emotion(invader_knight)
	character_util.remove_anim_and_emotion(little_girl)

	--인터랙트 할 때마다 반복

	music_player_util.change_stage_music_volume('field', 1)

	sp_util.exit_scene(nil, invader_knight)
end

function local_class:is_stage_cleared()
	return user_progress:IsStageCleared(stage.Name)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
