local local_class = newclass('NightmareLilithTower3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 380

	self.scene_version = scene_util.default_version

	--floor prefab
	self.res_holder = nil

	--2층 위치, 크기
	self.second_floor_pos = vector(1, -4, 61.5)
	self.second_floor_scale = vector(0.82, 1, 0.82)

	self.under_floor_obj = nil
	self.grab_blur_obj = nil

	self.epilogue_data = {
		beth = {
			zone = 'beth_enter_zone',
			entered = false,
			cb = self.beth_scene,
		},
	}

	--엘레베이터
	self.elevator = {
		current_floor = 'first_floor',
		button_name = 'elevator_button',
		door_name = 'elevator_inner_door',
		get_door = function(this)
			return get_field_object(this.door_name)
		end,
		get_button = function(this)
			return get_field_object(this.button_name)
		end,
		change_floor = function(this, floor_key)
			if this.current_floor == floor_key then
				return false
			end

			--키 저장
			this.current_floor = floor_key

			--엘리베이터 출구 ExitInteractable 수정
			local door = this:get_door()
			door.Interactable = this.info[floor_key].exit_interactable

			return true
		end,
		info = {
			first_floor = {
				exit_interactable = nil,
				point_name = 'elevator_first_floor_pos',
			},
			second_floor = {
				exit_interactable = nil,
				point_name = 'elevator_second_floor_pos',
			},
		},
		pre_load = function(this)
			--ExitInteractable 저장
			for key, data in pairs(this.info) do
				this.info[key].exit_interactable = CS.Oak.ExitInteractable()

				local open_path_info = CS.Oak.OpenPathInfo()
				open_path_info.OpenWaypoint = data.point_name

				this.info[key].exit_interactable.MoveStage = open_path_info
			end
		end,
	}

	--스테이지 종료 체크
	self.stage_ended = false
	self.eat_sfx = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	if self.under_floor_obj ~= nil then
		CS.UnityEngine.Object.Destroy(self.under_floor_obj)
		self.under_floor_obj = nil
	end

	if self.grab_blur_obj ~= nil then
		self.grab_blur_obj:Dispose()
		self.grab_blur_obj = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
end

--region load_resource
function local_class:load_resource()
	unity_object_pool.GetOrCreate('grab_blur_object')

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	local vent_loader = get_or_create_global_table('Quest/Nightmare/LilithTower/Common/VentLoader')

	vent_loader:load_async()
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
	return false
end

function local_class:on_stage_loaded_event(_)
	start_coroutine(self.pre_setting, self)
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.elevator:get_button()) then
		sp_util.start_scene(self.button_scene, self)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	for _, data in pairs(self.epilogue_data) do
		if type_util.is_zone_full_enter(e, get_party_leader(), data.zone) and
				not data.entered then
			data.entered = true
			start_coroutine(data.cb, self)
		end

	end
end

function local_class:on_zone_leave_event(e)
	local block = get_field_object('missing_child_block')

	--이벤트존을 나갈 경우 초기화
	if type_util.is_zone_full_leave(e, block, 'missing_child_block_leave_zone') then
		message_system:SendSync(block, CS.Oak.GimmickResetEvent.Instance)
		return true
	end

	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == 'elevator_first_door' then
		self.elevator:change_floor('first_floor')
		return true
	elseif e.ExitHandleName == 'elevator_second_door' then
		self.elevator:change_floor('second_floor')
		return true
	end

	return false
end

function local_class:on_stage_end_event()
	self.stage_ended = true

	if self.eat_sfx ~= nil then
		self.eat_sfx:Stop()
		self.eat_sfx = nil
	end
end

--endregion

--엘리베이터 버튼 문 연출
function local_class:button_scene()
	local door = self.elevator:get_door()
	local button = self.elevator:get_button()

	party_util.align_to_target(button, 'down', 1, 'linear')

	--어느 층으로 가시겠습니까?
	field_ui_util.show_narration_async({ key = 'nightmare_lt_stage_3_elevator_1' })

	--30층
	--31층
	local result = choose_util.play_choose_event({
		{ 'nightmare_lt_stage_3_elevator_choose_1', 'normal' },
		{ 'nightmare_lt_stage_3_elevator_choose_2', 'normal' },
	})

	local is_change = false

	if result == 1 then
		is_change = self.elevator:change_floor('first_floor')
	elseif result == 2 then
		is_change = self.elevator:change_floor('second_floor')
	end

	--층 이동 연출
	if is_change then
		start_coroutine(function()
			--문,버튼 인터렉테이블 저장
			local door_saved_interactable = door.Interactable
			local button_saved_interactable = button.Interactable

			--문,버튼 인터렉테이블 비활성화
			door.Interactable = CS.Oak.NonInteractable.Instance
			button.Interactable = CS.Oak.NonInteractable.Instance

			music_player_util.play_sfx_one_shot('01_elevator_05')

			local shake_sfx = music_player_util.play_sfx({ sfx_name = '01_elevator_03', loop = true,
														   type_priority = 'event', player_priority = 'npc' })

			camera_util.shake(0.03, 2)

			wait_for_sec(2)

			shake_sfx:FadeOut()

			music_player_util.play_sfx_one_shot('01_broadcast_02')

			camera_util.shake(0.12, 0.5)

			wait_for_sec(0.5)

			door.Interactable = door_saved_interactable
			button.Interactable = button_saved_interactable
		end)
	end
end

function local_class:pre_setting()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	local door = get_field_object('s6_interactable_5')
	local pos = field_util.get_marker_pos('s6_door_pos')

	--5,6 섹션일때 문 위치 지정
	if quest_progress ~= nil and
			not quest_progress.IsComplete and
			(quest_progress.InnerProgress == 4 or quest_progress.InnerProgress == 5) then
		door.Position = pos
	end

	--메인 퀘스트 진행 후에도 3스테이지 클리어 하지 않았을 경우 메인 퀘스트 마커 처리
	if not user_progress:IsStageCleared(stage.Name) and
			quest_progress ~= nil and
			not quest_progress.IsComplete and
			quest_progress.InnerProgress > 5 then
		quest_marker_util.add_auto_control('main_quest', {
			{ zone = 'machine_room', target = get_field_object('exit_nightmare_lilithtower_4') },
			{ zone = 'second_floor', target = get_field_object('s6_emergency_exit') },
		})
	end

	--엘리베이터 설정
	self.elevator:pre_load()

	self.res_holder = CS.Foundations.ResourceHolder()

	-- 전경 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_22_lilithtower/tilesets/lilithtower', 'nightmare_lilithtower_3_main_hall',
			function(prefab)
				self.under_floor_obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.under_floor_obj.transform.localPosition = self.second_floor_pos
				self.under_floor_obj.transform.localScale = self.second_floor_scale
			end)

	self.grab_blur_obj = unity_object_pool.GetOrCreate('grab_blur_object'):Instantiate(
			self.second_floor_pos + vector(0, 3, 0))
	local grab_blur = self.grab_blur_obj.transform:GetComponent(typeof(CS.Oak.GrabBlur))
	grab_blur.BlurRadius = 3

	--region 베스 후일담
	local carpenter_1 = get_character('beth_carpenter_1')
	character_util.set_active_state(carpenter_1, 'enabled')
	character_util.set_direction(carpenter_1, 'right')
	character_util.set_anim_and_emotion(carpenter_1, { name = 'push' }, { name = 'idle' })

	local carpenter_2 = get_character('beth_carpenter_2')
	character_util.set_active_state(carpenter_2, 'enabled')
	character_util.set_direction(carpenter_2, 'left')
	character_util.set_anim_and_emotion(carpenter_2, { name = 'eat' }, { name = 'idle' })
	--endregion

	--region 다이하드 후일담
	local diehard_quest_progress = user_progress:GetStartedQuest(269)

	if diehard_quest_progress.InnerProgress == 1 then
		local staff = get_character('diehard_demon_staff')
		local john = get_character('diehard_demon_john_mcclane')

		--스태프(right, idle, idle): 이번분기 최고 인기 상품들입니다.
		character_util.set_active_state(staff, 'enabled')
		character_util.set_direction(staff, 'left')
		staff.Interactable.Talk = 'nightmare_lt_stage3_sub_9'

		--션(up, idle, idle): 이 옷… 졸리가 입었다면 참 예뻤을텐데…
		character_util.set_active_state(john, 'enabled')
		character_util.set_direction(john, 'up')
		character_util.set_position(john, field_util.get_marker_pos('diehard_john_pos'))
		john.Interactable.Talk = 'nightmare_lt_stage3_sub_10'

	elseif diehard_quest_progress.InnerProgress == 3 then
		local staff = get_character('diehard_demon_staff')
		local wife = get_character('diehard_demon_wife')
		local john = get_character('diehard_demon_john_mcclane')

		--스태프(right, idle, idle): 이번분기 최고 인기 상품들입니다.
		character_util.set_active_state(staff, 'enabled')
		character_util.set_direction(staff, 'left')
		staff.Interactable.Talk = 'nightmare_lt_stage3_sub_9'

		--졸리(left, smile, eat): 션, 이것 좀 봐요! 옷이 너무 예뻐요!
		character_util.set_active_state(wife, 'enabled')
		character_util.set_direction(wife, 'left')
		character_util.set_anim_and_emotion(wife, { name = 'eat' }, { name = 'smile' })
		wife.Interactable.Talk = 'nightmare_lt_stage3_sub_11'

		--션(left, tired, cross_arm): 옷 한 벌 가격이 경위 월급 절반이라니…
		character_util.set_active_state(john, 'enabled')
		character_util.set_direction(john, 'left')
		character_util.set_anim_and_emotion(john, { name = 'cross_arm' }, { name = 'tired' })
		john.Interactable.Talk = 'nightmare_lt_stage3_sub_12'

	else
		local staff = get_character('diehard_demon_staff')
		local male = get_character('diehard_demon_male')
		local female = get_character('diehard_demon_female')

		--스태프(right, idle, idle): 이번분기 최고 인기 상품들입니다.
		character_util.set_active_state(staff, 'enabled')
		character_util.set_direction(staff, 'left')
		staff.Interactable.Talk = 'nightmare_lt_stage3_sub_9'

		--마족 여자(right, smile, victory_get(마지막 프레임)): 오빠! 이 옷 어때?
		character_util.set_active_state(female, 'enabled')
		character_util.set_direction(female, 'right')
		character_util.set_anim_and_emotion(female, { name = 'victory_get', loop = false }, { name = 'smile' })
		female.Interactable.Talk = 'nightmare_lt_stage3_sub_13'

		--마족 남자(left, scared, cast): 아, 아까 90% 세일 매대에서 본 게 더 예쁜 것 같은데? 절대 옷이 비싸서 그런건 아니고…
		character_util.set_active_state(male, 'enabled')
		character_util.set_direction(male, 'left')
		scene_util.set_emotion(male, self, 'scared')
		scene_util.set_anim(male, self, 'cast')
		male.Interactable.Talk = 'nightmare_lt_stage3_sub_14'
	end
	--endregion
end

function local_class:beth_scene()
	local carpenter_1 = get_character('beth_carpenter_1')
	local carpenter_2 = get_character('beth_carpenter_2')

	self.eat_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01',
		loop = true,
		type_priority = 'loop',
		player_priority = 'npc',
		parent = carpenter_1,
		volume = 0.5
	})

	--0.5초 대기
	wait_for_sec(0.5)

	if self.stage_ended then
		return
	end

	--청소부 1(right, damaged, idle): 아이고, 허리야…
	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', loop = false, parent = carpenter_1 })
	character_util.remove_anim(carpenter_1)
	scene_util.play_normal_speech_action(carpenter_1, self,
			nil,
			nil,
			'damaged',
			{ key = 'nightmare_lt_stage3_sub_1', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 1(left, tired, release): 역시 셋이 하던걸 둘이 할려니 여간 힘든게 아니네…
	scene_util.play_normal_speech_action(carpenter_1, self,
			'left',
			'release',
			'tired',
			{ key = 'nightmare_lt_stage3_sub_2', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 1(left, smile, idle)
	scene_util.set_emotion(carpenter_1, self, 'smile')

	--청소부 2(left, smile, eat): 그래도 빈자리 티가 나는 걸 보니 그 아가씨도 이제 한 사람 몫은 하게 된 모양이구만.
	scene_util.set_emotion(carpenter_2, self, 'smile')
	scene_util.play_normal_speech_action(carpenter_2, self,
			nil,
			nil,
			nil,
			{ key = 'nightmare_lt_stage3_sub_3', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 2(left, smile, idle) 0.3초 대기
	character_util.remove_anim(carpenter_2)
	wait_for_sec(0.3)

	if self.stage_ended then
		return
	end

	self.eat_sfx:Stop()
	self.eat_sfx = nil

	--청소부 2(right, smile, release): 다음주까지 휴가랬지?
	scene_util.play_normal_speech_action(carpenter_2, self,
			'right',
			'release',
			nil,
			{ key = 'nightmare_lt_stage3_sub_4', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 1(left, smile, question): 그래. 지금 뭐 하고 있으려나…?
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = carpenter_1 })
	scene_util.set_anim(carpenter_1, self, 'question')
	scene_util.play_normal_speech_action(carpenter_1, self,
			nil,
			nil,
			nil,
			{ key = 'nightmare_lt_stage3_sub_5', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 2(right, tired, question) 2.5초 대기
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = carpenter_2 })
	scene_util.set_emotion(carpenter_2, self, 'tired')
	scene_util.set_anim(carpenter_2, self, 'question', { loop = false })
	wait_for_sec(2.5)

	if self.stage_ended then
		return
	end

	--청소부 1(left, tired, bomb_idle)
	scene_util.set_emotion(carpenter_1, self, 'tired')
	scene_util.set_anim(carpenter_1, self, 'bomb_idle')

	--청소부 2(right, tired, bomb_idle): 글쎼, 또 술이나 진탕 퍼마시고 있지 않겠어…?
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', loop = false, parent = carpenter_2 })
	scene_util.play_normal_speech_action(carpenter_2, self,
			nil,
			'bomb_idle',
			nil,
			{ key = 'nightmare_lt_stage3_sub_6', skip = false })

	if self.stage_ended then
		return
	end

	--청소부 1(right, tired, push)
	scene_util.set_direction(carpenter_1, 'right', false)
	scene_util.set_anim(carpenter_1, self, 'push')

	--청소부 2(left, tired, eat)
	scene_util.set_direction(carpenter_2, 'left', false)
	scene_util.set_anim(carpenter_2, self, 'eat')

	--청소부 1: 휴가를 괜히 보내줬나…?
	carpenter_1.Interactable.Talk = 'nightmare_lt_stage3_sub_7'

	--청소부 2: 그거 말고 다른 모습은 상상이 안가네…
	carpenter_2.Interactable.Talk = 'nightmare_lt_stage3_sub_8'
end

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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
