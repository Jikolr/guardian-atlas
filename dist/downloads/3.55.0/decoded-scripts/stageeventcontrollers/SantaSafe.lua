local local_class = newclass("SantaSafeController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 티니아
	self.tinia = nil

	-- 공주
	self.princess = nil

	-- 쓰레기통
	self.trash_can = nil

	-- 화이트보드
	self.whiteboard = nil

	-- 책 올라간 책상
	self.book_desk = nil

	-- 책
	self.dropped_book = nil

	-- 컴퓨터
	self.computer = nil

	-- 비밀길 입구 막고 있는 오브젝트
	self.blocker = nil

	-- 반짝이 이펙트 리스트
	self.twinkle_effect_list = nil

	-- QTE 처리
	self.qte_success = false

	-- 이벤트 보았는지 설정
	self.event_flags = {
		see_tinia_event = false,
		see_princess_event = false,
		see_trash_can_event = false,
		see_whiteboard_event = false,
		see_book_desk_event = false
	}

	-- 기타 상수
	self.large_clock_num = 5
	self.book_item_id = 20091
	self.paper_item_id = 20022

	-- 타일맵 NPC 이름
	self.tinia_name = 'tinia'
	self.princess_name = 'princess_factory'

	-- 타일맵 필드오브젝트 이름
	self.trash_can_name = 'trash_can'
	self.whiteboard_name = 'whiteboard'
	self.book_desk_name = 'book_desk'
	self.computer_name = 'computer'
	self.large_clock_name = 'large_clock_'
	self.safe_door_name = 'safe_door'
	self.blocker_name = 'blocker_1'

	-- 스테이지 커스텀 스테이트 이름
	self.stage_custom_data = {
		open_santa_safe_door = 0,
		move_blocker = 1
	}

	-- 오브젝트 풀 이름
	self.twinkle_effect_preset = 'FX_Object_Twinkle'

	CS.Oak.CommonScreenplay.PreloadTutorialSpine()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	self.tinia = get_character(self.tinia_name)
	character_util.set_position(self.tinia, vector(3.9, 0, 117.6))
	character_util.set_direction(self.tinia, 'right')
	character_util.add_listener(self.tinia, self.cs_controller)

	self.princess = get_character(self.princess_name)
	character_util.set_position(self.princess, vector(6, 0, 132.5))
	character_util.set_direction(self.princess, 'right')
	character_util.set_anim(self.princess, { name = 'hurt' })
	character_util.set_emotion(self.princess, { name = 'tired' })
	character_util.add_listener(self.princess, self.cs_controller)

	self.trash_can = get_field_object(self.trash_can_name)
	self.trash_can.Interactable = CS.Oak.PublishInteractable.Create()

	self.whiteboard = get_field_object(self.whiteboard_name)
	self.whiteboard.Interactable = CS.Oak.PublishInteractable.Create()

	self.book_desk = get_field_object(self.book_desk_name)
	self.book_desk.Interactable = CS.Oak.PublishInteractable.Create()

	self.computer = get_field_object(self.computer_name)

	self.blocker = get_field_object(self.blocker_name)

	if not stage_progress:GetCustomData(self.stage_custom_data.open_santa_safe_door, false) then
		self.computer.Interactable = CS.Oak.PublishInteractable.Create()
	else
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.safe_door_name))
	end

	if not stage_progress:GetCustomData(self.stage_custom_data.move_blocker, false) then
		self.blocker.Interactable = CS.Oak.PublishInteractable.Create()
	else
		self.blocker.Position = self.blocker.Position + vector(2, 0, 0)
	end

	for i = 1, self.large_clock_num do
		self:setting_clock(self.large_clock_name..i)
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if not stage_progress:GetCustomData(self.stage_custom_data.open_santa_safe_door) then
		local object_pool = unity_object_pool.GetOrCreate(self.twinkle_effect_preset)

		while not object_pool_extensions.IsLoaded(object_pool) do
			coroutine.yield(nil)
		end

		self.twinkle_effect_list = create_generic_list(CS.Oak.PooledUnityObject)

		self.twinkle_effect_list:Add(unity_object_pool.GetOrCreate(self.twinkle_effect_preset):Instantiate(
				self.trash_can.Position + vector(0, 0.5, 0)))
		self.twinkle_effect_list:Add(unity_object_pool.GetOrCreate(self.twinkle_effect_preset):Instantiate(
				self.whiteboard.Position + vector(0, 2, -1)))
		self.twinkle_effect_list:Add(unity_object_pool.GetOrCreate(self.twinkle_effect_preset):Instantiate(
				self.book_desk.Position + vector(0.5, 0.5, 0)))
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.tinia = nil
	self.princess = nil

	self.trash_can = nil
	self.whiteboard = nil
	self.book_desk = nil
	self.computer = nil

	if self.dropped_book ~= nil then
		self.dropped_book:ConsumeComplete()
		self.dropped_book = nil
	end

	if self.twinkle_effect_list ~= nil then
		for i = 0, self.twinkle_effect_list.Count - 1 do
			if self.twinkle_effect_list[i] ~= nil then
				self.twinkle_effect_list[i]:Dispose()
			end
		end

		self.twinkle_effect_list = nil
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.TouchEvent) then
		self:on_touch_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	self.dropped_book = drop_item_util.create_item({ pos = vector(25.5, 1, 137.8),
	                                                 itemid = self.book_item_id, notforinven = true, lootstate = 'dontfindlooter' })
	self.dropped_book.ShadowTransform.localScale = unity_class.vector3.zero
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.tinia) then
		if not self.event_flags.see_tinia_event then
			self.event_flags.see_tinia_event = true

			sp_util.play_normal_screenplay(self.talk_with_tinia, self)
		else
			speech_bubble_util.show_speech_bubble(self.tinia, { key = 'christmas_main_s4_tinia_8' })
		end
	elseif lua_helper.reference_equals(e.Target, self.princess) then
		if not self.event_flags.see_princess_event then
			self.event_flags.see_princess_event = true

			sp_util.play_normal_screenplay(self.talk_with_princess, self)
		else
			speech_bubble_util.show_speech_bubble(self.princess, { key = 'christmas_main_s4_princess_4' })
		end
	elseif lua_helper.reference_equals(e.Target, self.trash_can) then
		sp_util.play_normal_screenplay(self.interact_with_trash_can, self)
	elseif lua_helper.reference_equals(e.Target, self.whiteboard) then
		sp_util.play_normal_screenplay(self.interact_with_whiteboard, self)
	elseif lua_helper.reference_equals(e.Target, self.book_desk) then
		sp_util.play_normal_screenplay(self.interact_with_book_desk, self)
	elseif lua_helper.reference_equals(e.Target, self.computer) then
		sp_util.play_normal_screenplay(self.interact_with_computer, self)
	elseif lua_helper.reference_equals(e.Target, self.blocker) then
		sp_util.play_normal_screenplay(self.interact_with_blocker, self)
	end
end

function local_class:on_touch_event(e)
	if e.TouchEventType == CS.Oak.TouchEventType.SwipeRight and not self.qte_success then
		self.qte_success = true
	end
end

-- 시계 4시 2분으로 설정
function local_class:setting_clock(large_clock_name)
	local large_clock = get_field_object(large_clock_name)

	local transform_hour = CS.Utils.FindChildRecursively(large_clock.Transform, 'obj_largeclock_hour')
	local transform_minute = CS.Utils.FindChildRecursively(large_clock.Transform, 'obj_largeclock_minute')

	local animator_hour = transform_hour:GetComponent(typeof(CS.CustomAnimator))
	local animator_minute = transform_minute:GetComponent(typeof(CS.CustomAnimator))

	animator_hour.enabled = false
	animator_minute.enabled = false

	transform_hour.localRotation = unity_class.quaternion.Euler(vector(-18.31171, 0, -175))
	transform_minute.localRotation = unity_class.quaternion.Euler(vector(-15.70447, 0, -50))
end

-- 티니아와 대화
function local_class:talk_with_tinia()
	party_util.align_party(vector(4, 0, 118), 'right', 1, 'arc')

	character_util.set_anim(user_party_leader, { name = 'release', sfx_name = '01_swing_01' })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)

	character_util.jump(self.tinia, 1, 0.5)
	character_util.set_anim(self.tinia, { name = 'embarrassed' })
	character_util.set_emotion(self.tinia, { name = 'damaged' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_0', skip = true })

	character_util.set_emotion(self.tinia, { name = 'tired' })
	character_util.move_to_async(self.tinia, self.tinia.Position + vector(0.1, 0, 0),
			nil, 2, true, true)

	character_util.move_to_async(self.tinia, self.tinia.Position + vector(0, 0, 0.4),
			nil, 2, true, true)

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.tinia, 'right')
	character_util.set_anim(self.tinia, { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_1', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.tinia, { name = 'victory_get', loop = false })
	character_util.set_emotion(self.tinia, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_2', skip = true })

	choose_util.play_choose_event({ { 'christmas_main_s4_tinia_3', 'brutal' } })

	character_util.set_anim(user_party_leader, { name = 'sing' })

	character_util.set_anim(self.tinia, { name = 'cast' })
	character_util.set_emotion(self.tinia, { name = 'tired' })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)

	character_util.set_anim(self.tinia, { name = 'cast2' })
	character_util.set_emotion(self.tinia, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_4', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.tinia, { name = 'cast' })
	character_util.set_emotion(self.tinia, { name = 'surprise' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_5', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.tinia, { name = 'question', loop = false })
	character_util.set_emotion(self.tinia, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_6', skip = true })

	character_util.set_anim(self.tinia, { name = 'cross_arm' })
	character_util.remove_emotion(self.tinia)

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_7', skip = true })

	character_util.set_anim(self.tinia, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(self.tinia, { key = 'christmas_main_s4_tinia_8', skip = true })
end

-- 공주와 대화
function local_class:talk_with_princess()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'elf_shout', 'stop' }))
	party_util.align_party(self.princess, 'left', 1, 'arc')

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.princess, 'left')
	character_util.jump(self.princess, 0.5, 0.3)
	character_util.set_anim(self.princess, { name = 'sing' })
	character_util.set_emotion(self.princess, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.princess,
			{ key = game_string:Format('christmas_main_s4_princess_0', user.Name), skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.princess, { name = 'hurt' })
	character_util.set_emotion(self.princess, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.princess, { key = 'christmas_main_s4_princess_1', skip = true })

	character_util.set_direction(self.princess, 'right')
	character_util.remove_anim(self.princess)

	speech_bubble_util.show_speech_bubble_async(self.princess, { key = 'christmas_main_s4_princess_2', skip = true })

	character_util.set_direction(self.princess, 'left')
	character_util.set_anim(self.princess, { name = 'release', sfx_name = '01_swing_01' })
	character_util.remove_emotion(self.princess)

	speech_bubble_util.show_speech_bubble_async(self.princess, { key = 'christmas_main_s4_princess_3', skip = true })

	character_util.set_direction(user_party_leader, 'up')

	character_util.set_direction(self.princess, 'up')
	character_util.remove_anim(self.princess)

	camera_util.move_async(vector(user_party_leader.Position.x, 0, 137), 1)

	wait_for_sec(2)

	character_util.set_direction(user_party_leader, 'right')

	character_util.set_direction(self.princess, 'left')

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.princess, { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(self.princess, { key = 'christmas_main_s4_princess_4', skip = true })

	character_util.set_anim(self.princess, { name = 'sing' })
	character_util.set_emotion(self.princess, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.princess, { key = 'christmas_main_s4_princess_5', skip = true })
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character, { 'elf_shout', 'start' }))
end

-- 쓰레기통과 상호작용
function local_class:interact_with_trash_can()
	if not self.event_flags.see_trash_can_event then

		if self.twinkle_effect_list ~= nil then
			self.twinkle_effect_list[0]:Dispose()
		end
	end

	party_util.align_party(self.trash_can, 'right', 1)

	field_ui_util.show_narration_async({ key = 'christmas_main_s4_trash_can_0' })

	if not self.event_flags.see_trash_can_event then
		self.event_flags.see_trash_can_event = true

		music_player_util.play_sfx({ sfx_name = '01_turn_page_02', type_priority = 'event', player_priority = 'npc' })

		drop_item_util.create_item(
				{ pos = self.trash_can.Position, target = user_party_leader.Position, itemid = self.paper_item_id })

		wait_for_sec(0.5)

		music_player_util.play_sfx({ sfx_name = '01_paper_01', type_priority = 'event', player_priority = 'npc' })

		character_util.set_direction(user_party_leader, 'left')
		character_util.set_anim(user_party_leader, { name = 'eat' })

		wait_for_sec(1)

		character_util.look_at(user_party_leader, self.trash_can)
		character_util.remove_anim(user_party_leader)
	end

	field_ui_util.show_narration_async({ key = 'christmas_main_s4_trash_can_1' })
end

-- 화이트보드와 상호작용
function local_class:interact_with_whiteboard()
	if not self.event_flags.see_whiteboard_event then
		self.event_flags.see_whiteboard_event = true

		if self.twinkle_effect_list ~= nil then
			self.twinkle_effect_list[1]:Dispose()
		end
	end

	party_util.align_party(self.whiteboard, 'down', 1)

	speech_bubble_util.show_speech_bubble_async(self.whiteboard, { key = 'christmas_main_s4_whiteboard_0', skip = true })

	field_ui_util.show_narration_async({ key = 'christmas_main_s4_whiteboard_1' })

	speech_bubble_util.show_speech_bubble_async(self.whiteboard, { key = 'christmas_main_s4_whiteboard_2', skip = true })
end

-- 책 올라간 책상과 상호작용
function local_class:interact_with_book_desk()
	if not self.event_flags.see_book_desk_event then
		self.event_flags.see_book_desk_event = true

		if self.twinkle_effect_list ~= nil then
			self.twinkle_effect_list[2]:Dispose()
		end
	end

	party_util.align_party(self.book_desk.Position + vector(0.5, 0, 0), 'down', 1)

	field_ui_util.show_narration_async({ key = 'christmas_main_s4_book_0' })

	local choose_result = choose_util.play_choose_event(
			{ { 'christmas_main_s4_book_1', 'mercy' }, { 'christmas_main_s4_book_2', 'brutal' } })

	if choose_result == 1 then
		field_ui_util.show_narration_async({ key = 'christmas_main_s4_book_3' })

		field_ui_util.show_narration_async({ key = 'christmas_main_s4_book_4' })
	end
end

-- 컴퓨터와 상호작용 하는 이벤트
function local_class:interact_with_computer()
	party_util.align_party(self.computer, 'down', 1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_worker_01', type_priority = 'event', player_priority = 'npc' })

	speech_bubble_util.show_speech_bubble_async(self.computer, { key = 'christmas_main_s4_18', skip = true })

	-- 비밀번호 5자리 입력
	local is_correct = true

	for n = 0, 4 do
		local choose_result = choose_util.play_choose_event(
				{ { '0', 'normal' }, { '1', 'normal' }, { '2', 'normal' }, { '3', 'normal' },
				  { '4', 'normal' }, { '5', 'normal' } })

		if n == 0 then
			if choose_result ~= 5 then
				is_correct = false
			end
		elseif n == 1 then
			if choose_result ~= 3 then
				is_correct = false
			end
		elseif n == 2 then
			if choose_result ~= 5 then
				is_correct = false
			end
		elseif n == 3 then
			if choose_result ~= 3 then
				is_correct = false
			end
		elseif n == 4 then
			if choose_result ~= 1 then
				is_correct = false
			end
		end
	end

	if is_correct then
		music_player_util.play_sfx({ sfx_name = '03_dialogue_worker_01', type_priority = 'event', player_priority = 'npc' })

		speech_bubble_util.show_speech_bubble_async(self.computer, { key = 'christmas_main_s4_20', skip = true })

		local safe_door = get_field_object(self.safe_door_name)

		camera_util.move_async(safe_door.Position, 1)

		stage_progress:SendCustomData(self.stage_custom_data.open_santa_safe_door, true)

		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.safe_door_name, false))

		wait_for_sec(2.5)

		camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

		-- 컴퓨터에 Interact 불가능하게 수정
		self.computer.Interactable = CS.Oak.NonInteractable.Instance
	else
		music_player_util.play_sfx({ sfx_name = '03_dialogue_worker_01', type_priority = 'event', player_priority = 'npc' })

		speech_bubble_util.show_speech_bubble_async(self.computer, { key = 'christmas_main_s4_19', skip = true })
	end
end

-- 비밀길 막는 오브젝트 밀어냄
function local_class:interact_with_blocker()
	if user_party_leader.Position.z < 138 then
		character_util.move_to_async(user_party_leader, vector(18.7, 0, user_party_leader.Position.z),
				nil, 2, true, true)
	end

	character_util.move_to_async(user_party_leader, vector(18.7, 0, 138),
			nil, 2, true, true)

	music_player_util.play_sfx({ sfx_name = '01_tap_style_guide_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(user_party_leader, 'left')
	character_util.set_anim(user_party_leader, { name = 'push', upper = true })
	character_util.set_emotion(user_party_leader, { name = 'damaged' })

	-- QTE 이벤트
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')

	CS.Oak.CommonScreenplay.QTESwipe('right')

	while not self.qte_success do
		coroutine.yield(nil)
	end

	self.qte_success = false

	yield_return_func(CS.Oak.CommonScreenplay.QTEComplete, 0)

	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	music_player_util.play_sfx({ sfx_name = '01_push_rock_unit_01', type_priority = 'event', player_priority = 'npc' })

	character_util.shake(user_party_leader, 0.04, 1)
	character_util.set_emotion(user_party_leader, { name = 'damaged' })
	character_util.move_to(user_party_leader, user_party_leader.Position + vector(1, 0, 0),
			1, nil, false, true)

	self.blocker:Shake(0.02, 1)

	local cur_time = unity_class.time.time
	local move_time = 1
	local dec = 1
	local start_pos = self.blocker.Position

	while unity_class.time.time - cur_time < move_time do
		local normalized = (unity_class.time.time - cur_time) / move_time

		self.blocker.Position = start_pos + vector(dec * normalized, 0, 0)

		coroutine.yield(nil)
	end

	wait_for_sec(0.5)

	-- QTE 이벤트
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')

	CS.Oak.CommonScreenplay.QTESwipe('right')

	while not self.qte_success do
		coroutine.yield(nil)
	end

	self.qte_success = false

	yield_return_func(CS.Oak.CommonScreenplay.QTEComplete, 0)

	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	music_player_util.play_sfx({ sfx_name = '01_push_rock_unit_01', type_priority = 'event', player_priority = 'npc' })

	character_util.shake(user_party_leader, 0.04, 1)
	character_util.set_emotion(user_party_leader, { name = 'damaged' })
	character_util.move_to(user_party_leader, user_party_leader.Position + vector(1, 0, 0),
			1, nil, false, true)

	self.blocker:Shake(0.02, 1)

	cur_time = unity_class.time.time
	move_time = 1
	dec = 1
	start_pos = self.blocker.Position

	while unity_class.time.time - cur_time < move_time do
		local normalized = (unity_class.time.time - cur_time) / move_time

		self.blocker.Position = start_pos + vector(dec * normalized, 0, 0)

		coroutine.yield(nil)
	end

	wait_for_sec(0.5)

	character_util.remove_anim(user_party_leader, true)
	character_util.remove_emotion(user_party_leader)

	stage_progress:SendCustomData(self.stage_custom_data.move_blocker, true)

	-- 블로커에 Interact 불가능하게 수정
	self.blocker.Interactable = CS.Oak.NonInteractable.Instance
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
