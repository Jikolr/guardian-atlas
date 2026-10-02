local local_class = newclass("FutureCastleCraig")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 진행 상황
	self.event_progress = {
		idle = 0,
		training_started = 1,
		training_finished = 2,
		event_finished = 3,
		event_deactivated = 4
	}

	self.current_progress = self.event_progress.idle

	self.craig = nil

	self.training_resistance_list = nil

	self.training_dummy_list = nil

	-- 훈련 종료 레지스탕스들의 대사 리스트
	self.resistance_talk_key_list = nil

	-- 레지스탕스 흩어지는 이벤트 중복 실행 방지 플래그
	self.is_dispersed = false

	-- 기타 상수
	self.training_dummy_num = 6
	self.training_resistance_num = 6

	-- 캐릭터 이름
	self.craig_name = 'craig'
	self.training_resistance_name = 'training_resistance_'

	-- 필드오브젝트 이름
	self.training_dummy_name = 'training_dummy_'

	-- 필드 이벤트 존 이름
	self.training_event_zone_name = 'section_7_training'

	-- 커스텀 이벤트 이름
	self.craig_event_finished = 'craig_event_finished'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = 'FX_hit'
	self.impact_hit_effect_preset = 'FX_lasthit'

	-- FutureCastle1At2.lua의 커스텀 키 개수가 늘어나면 변경되어야 함
	-- FIXME: 굉장히 안 좋은 구조인데 수정할 방법 없는지 찾아볼 것
	self.custom_key = {
		finished_craig_event = 10
	}

	self.is_attacking_dummy = false
	self.is_in_training_grid = false
	self.training_grid_name = 'training_grid'
end

function local_class:load_resource()
	-- 현재 메인 퀘스트 상황에 따라 스테이지 이벤트 상태 설정
	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil then
		if main_quest.InnerProgress < 10 then
			if stage_progress:GetCustomData(self.custom_key.finished_craig_event, false) then
				self.current_progress = self.event_progress.event_finished
			else
				self.current_progress = self.event_progress.idle
			end
		else
			self.current_progress = self.event_progress.event_deactivated
		end
	else
		self.current_progress = self.event_progress.event_deactivated
	end

	unity_object_pool.GetOrCreate(self.hit_effect_preset)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	if self.current_progress < self.event_progress.event_finished then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	end

	self.craig = get_character(self.craig_name)

	self.training_resistance_list = create_generic_list(CS.Oak.Character)

	self.resistance_talk_key_list = create_generic_list(CS.System.String)

	for i = 1, self.training_resistance_num do
		local cur_resistance = get_character(self.training_resistance_name..i)

		self.training_resistance_list:Add(cur_resistance)
		self.resistance_talk_key_list:Add(cur_resistance.Interactable.Talk)

		cur_resistance.Interactable.Talk = nil
	end

	self.training_dummy_list = create_generic_list(CS.Oak.FieldObject)

	for i = 1, self.training_dummy_num do
		self.training_dummy_list:Add(get_field_object(self.training_dummy_name..i))
	end

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--region on event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		if e.CameraGrid.name == self.training_grid_name then
			self.is_in_training_grid = true
			if self.current_progress == self.event_progress.idle or
					self.current_progress == self.event_progress.event_finished and not self.is_dispersed then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy_event, self))
			end
		end
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		if e.CameraGrid.name == self.training_grid_name then
			self.is_in_training_grid = false
		end
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	if self.current_progress == self.event_progress.idle then
		self.craig.Interactable:AddListener(self.cs_controller)
	elseif self.current_progress == self.event_progress.event_deactivated then
		character_util.set_active_state(self.craig, 'disabled')

		for i = 0, self.training_resistance_list.Count - 1 do
			character_util.set_active_state(self.training_resistance_list[i], 'disabled')
		end
	end

	if self.current_progress ~= self.event_progress.event_deactivated then
		character_util.set_position(self.craig, vector(120, 0, -1))
		character_util.set_direction(self.craig, 'left')
	end
end

function local_class:on_stage_start_event(e)
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end

	local zone_name = e.Zone.Name

	if zone_name == self.training_event_zone_name then
		if self.current_progress == self.event_progress.idle then
			self.current_progress = self.event_progress.training_started

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.training_event, self))
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.craig) then
		sp_util.play_normal_screenplay(self.talk_with_craig, self)
	end
end
--endregion

-- 단순 더미 공격 이벤트, 트레이닝 이벤트가 실행되면 중단한다
function local_class:attack_dummy_event()
	for i = 0, self.training_resistance_list.Count - 1 do
		character_util.set_emotion(self.training_resistance_list[i], { name = 'attack' })
	end

	local timer = 0
	local duration = 1

	while self.is_attacking_dummy do
		coroutine.yield()
	end

	-- 트레이닝 중일 때는 종료되도록 설정
	while self.current_progress == self.event_progress.idle or
			self.current_progress > self.event_progress.training_finished do
		timer = timer + unity_class.time.deltaTime

		if not self.is_in_training_grid then
			break
		end

		if timer >= duration then
			timer = 0
			self.is_attacking_dummy = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'attack', true))
		end

		coroutine.yield(nil)
	end
end

-- 플레이어가 존 입장하면 자동으로 실행되는 더미 훈련 이벤트
function local_class:training_event()
	-- 단순 더미 공격 이벤트 종료될 때까지 대기
	wait_for_sec(1)

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'get' })
	character_util.set_emotion(self.craig, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_2', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'sword_idle' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'sword_attack'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_3',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'cast2' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_4', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'sword_idle' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'attack'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_5',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '02_twohand_slash_01', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'sword_attack', loop = false, next_anim = 'sword_idle' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_6', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'katana_attack3'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_7',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'get' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_8', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'spear_shield_attack'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_9',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	character_util.set_anim(self.craig, { name = 'cast2' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_10', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'sword_attack2'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_11',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '02_twohand_slash_01', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'sword_attack', loop = false, next_anim = 'sword_idle' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_12', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.attack_dummy, self, 'twohand_attack4'))

	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_13',
				bubble_type = 'shout',
				world_pos = vector(117, 0, -2),
				bubble_direction = 'rt',
				skip = false
			})

	if self.current_progress > self.event_progress.training_started then return end

	character_util.set_anim(self.craig, { name = 'nod' })
	character_util.remove_emotion(self.craig)

	-- 흠…좋다, 오늘 훈련은 여기서 마친다.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_14', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_03', parent = self.craig, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.craig, { name = 'release', sfx_name = '01_swing_01' })

	for i = 0, self.training_resistance_list.Count - 1 do
		character_util.set_anim(self.training_resistance_list[i], { name = 'success' })
		character_util.set_emotion(self.training_resistance_list[i], { name = 'smile' })
	end

	-- 교대까지 개인 정비를 하거나 식사를 하도록.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_15', skip = false })

	if self.current_progress > self.event_progress.training_started then return end

	character_util.remove_anim(self.craig)

	self:disperse_resistance()
end

-- 레지스탕스들의 더미 어택 루틴
function local_class:attack_dummy(animation_name, is_repeating_event)
	local dummy_pos_list = create_generic_list(unity_class.vector3)
	local dummy_shadow_list = create_generic_list(typeof(CS.UnityEngine.Transform))
	local dummy_shadow_pos_list = create_generic_list(unity_class.vector3)

	for i = 0, self.training_dummy_list.Count - 1 do
		dummy_pos_list:Add(self.training_dummy_list[i].Position)
		dummy_shadow_list:Add(self.training_dummy_list[i].Transform:GetChild(0))
		dummy_shadow_pos_list:Add(self.training_dummy_list[i].Transform:GetChild(0).position)
	end

	for i = 0, self.training_resistance_list.Count - 1 do
		character_util.spine_deviate_local(self.training_resistance_list[i], vector(0.3, 0, 0), 0.3, 0.2)
		character_util.jump(self.training_resistance_list[i], 0.1, 0.5)
		character_util.set_anim(self.training_resistance_list[i], { name = animation_name, loop = false })
	end

	-- 싱크 안 맞아서 대기시간 조금 추가
	wait_for_sec(0.2)

	local cycle = 0.4
	local rest_cycle = 0.2
	local hitting_point = 0

	local dummy_hitting_time_passed = 0
	local hitting_progress = 0
	local shake_magnitude = 0.02

	local isHit = false

	while true do
		dummy_hitting_time_passed = dummy_hitting_time_passed + unity_class.time.deltaTime

		local progress = dummy_hitting_time_passed / cycle

		if progress >= 1 then
			for i = 0, self.training_dummy_list.Count - 1 do
				self.training_dummy_list[i].Transform.localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
				self.training_dummy_list[i].Position = dummy_pos_list[i]

				dummy_shadow_list[i].localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
				dummy_shadow_list[i].localPosition = vector(0, 0.03, -0.21)
			end

			for i = 0, self.training_resistance_list.Count - 1 do
				character_util.set_anim(self.training_resistance_list[i], { name = 'sword_idle' })
			end

			wait_for_sec(rest_cycle)

			break
		else
			if not isHit then
				isHit = true

				for i = 0, self.training_dummy_list.Count - 1 do
					unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(self.training_dummy_list[i].Position + vector(0, 0.3, 0))
				end

				-- 더미 hit sfx
				music_player_util.play_sfx({
					sfx_name = '01_hit_dummy_02', play_pos = self.training_dummy_list[1].Position
				})
			end

			hitting_progress = (dummy_hitting_time_passed - hitting_point) / ((cycle - hitting_point) * 0.75)

			for i = 0, self.training_dummy_list.Count - 1 do
				local angle = -18 * unity_class.mathf.Sin(unity_class.mathf.Min(1, hitting_progress) * unity_class.mathf.PI);

				self.training_dummy_list[i].Transform.localRotation = unity_class.quaternion.AngleAxis(angle, vector(0, 0, 1))

				local shake = vector(shake_magnitude * (unity_class.random.value - 0.5), 0,
						shake_magnitude * (unity_class.random.value - 0.5))

				self.training_dummy_list[i].Transform.localPosition = dummy_pos_list[i] + shake

				dummy_shadow_list[i].position = dummy_shadow_pos_list[i]
				dummy_shadow_list[i].localRotation = unity_class.quaternion.AngleAxis(-angle, vector(0, 0, 1))
			end

			coroutine.yield(nil)
		end
	end

	for i = 0, self.training_dummy_list.Count - 1 do
		self.training_dummy_list[i].Transform.localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
		self.training_dummy_list[i].Transform.localPosition = dummy_pos_list[i]

		dummy_shadow_list[i].localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
		dummy_shadow_list[i].localPosition = vector(0, 0.03, -0.21)
	end

	if is_repeating_event then
		self.is_attacking_dummy = false
	end
end

-- 흩어져서 주변으로 이동하는 레지스탕스들
function local_class:disperse_resistance()
	-- 이중 호출 방지
	if not self.is_dispersed then
		self.is_dispersed = true
	else
		return
	end

	local dummy_resistance_pos_list = create_generic_list(unity_class.vector3)
	dummy_resistance_pos_list:Add(vector(112, 0, 5))
	dummy_resistance_pos_list:Add(vector(113, 0, 5))
	dummy_resistance_pos_list:Add(vector(106, 0, 1))
	dummy_resistance_pos_list:Add(vector(108, 0, -2))
	dummy_resistance_pos_list:Add(vector(107, 0, -2))
	dummy_resistance_pos_list:Add(vector(115, 0, 5))

	local dummy_resistance_dir_list = create_generic_list(CS.System.String)
	dummy_resistance_dir_list:Add('right')
	dummy_resistance_dir_list:Add('left')
	dummy_resistance_dir_list:Add('right')
	dummy_resistance_dir_list:Add('left')
	dummy_resistance_dir_list:Add('right')
	dummy_resistance_dir_list:Add('left')

	for i = 0, self.training_resistance_list.Count - 1 do
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.move_and_seat, self,  self.training_resistance_list[i],
						dummy_resistance_pos_list[i], dummy_resistance_dir_list[i], self.resistance_talk_key_list[i]))
	end
end

-- 달려가서 제자리에 앉아있는 레지스탕스들 설정
function local_class:move_and_seat(resistance, pos, dir, talk_key)
	local waypoint_list = create_generic_list(unity_class.vector3)
	waypoint_list:Add(vector(resistance.Position.x, 0, -0.5))
	waypoint_list:Add(vector(pos.x, 0, -0.5))
	waypoint_list:Add(pos)

	character_util.set_anim(resistance, { name = 'run' })
	character_util.remove_emotion(resistance)
	wp_util.move_way_points_async(resistance,
			{ waypoints = waypoint_list, speed = 6, run = true, play_sfx = true })

	resistance.Interactable.Talk = talk_key
	character_util.set_direction(resistance, dir)
	character_util.set_anim(resistance, { name = 'seat' })
	character_util.set_emotion(resistance, { name = 'tired' })
end

-- 플레이어 대화로 인해 트레이닝 강제 종료
function local_class:stop_training_scene()
	-- 말풍선 제거
	speech_bubble_util.remove_bubble(self.craig)

	for i = 0, self.training_resistance_list.Count - 1 do
		character_util.remove_anim(self.training_resistance_list[i])
	end

	character_util.remove_anim_and_emotion(self.craig)
	speech_bubble_util.remove_bubble(self.craig)
end

--- 크레이그와의 대화 이벤트
function local_class:talk_with_craig()
	self.current_progress = self.event_progress.event_finished

	character_util.remove_relate_event(self.craig, self)

	self:stop_training_scene()

	party_util.align_to_target(self.craig, self.craig.Direction)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', type_priority = 'event', player_priority = 'npc' })

	-- 맙소사… 오오, 프로메테이아시여!
	character_util.look_at(self.craig, user_party_leader)
	character_util.jump(self.craig, 1, 0.5)
	character_util.set_anim(self.craig, { name = 'cast2' })
	character_util.set_emotion(self.craig, { name = 'surprise' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_17', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })

	-- Player!!! 나, 나를 알아보겠나?
	character_util.set_anim(self.craig, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.craig, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = { 'futurecastle_main_a_s7_18', user.Name }, skip = true })

	character_util.remove_anim(self.craig)
	character_util.remove_emotion(self.craig)

	-- 크레이그!
	choose_util.play_choose_event({ { 'futurecastle_main_a_s7_19', 'mercy' } })

	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })
	character_util.set_emotion(user_party_leader, { name = 'smile' })

	wait_for_sec(1.5)

	local clap_sfx = music_player_util.play_sfx({ sfx_name = '01_clap_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)

	-- 이럴 수가, 정말 Player가 맞았군! 그래, 크레이그일세!
	character_util.set_anim(self.craig, { name = 'clap' })
	character_util.set_emotion(self.craig, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = { 'futurecastle_main_a_s7_20', user.Name }, skip = true })

	clap_sfx:FadeOut()

	character_util.remove_emotion(user_party_leader)

	-- 그동안 대체 무슨 일이 있었던 건가? 많은 사람들이 자넬 찾았지만, 아무런…!
	character_util.set_anim(self.craig, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_22', skip = true })

	character_util.remove_anim(self.craig)

	character_util.set_anim(user_party_leader, { name = 'bomb_idle' })
	character_util.set_emotion(user_party_leader, { name = 'tired' })

	wait_for_sec(0.75)

	-- 그래, 설명할 수 없는 사정이 있겠지..
	character_util.set_anim(self.craig, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_27', skip = true })

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	character_util.remove_anim(self.craig)

	-- 자네가 없어진 후 세상은 격변했어…
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_28', skip = true })

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 스테이지 카메라는 잠시 꺼준다.
	stage_camera.Enabled = false

	-- 부유성 폭격 씬 로드
	local holder = CS.Foundations.ResourceHolder()
	local earth_theatre = load_util.load_prefab_async(holder, 'theatres/earth_lily', 'theatre_earth_future')
	local theatre_animator = earth_theatre.transform:GetComponent(typeof(CS.UnityEngine.Animator))

	-- 2프레임 정도 애니메이션을 실행시켰다가 멈추게함.
	coroutine.yield()

	coroutine.yield()

	theatre_animator.enabled = false

	local space_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_space_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	-- 세계 전역에 무차별적인 인베이더의 공습이 시작되었지.
	speech_bubble_util.show_speech_bubble_async(self.craig,
			{
				key = 'futurecastle_main_a_s7_28_1',
				world_pos = vector(-2, 15, 100),
				skip = true
			})

	-- 부유성 폭격 씬 애니메이션 실행하고 끝날떄까지 대기
	theatre_animator.enabled = true

	wait_for_sec(9) -- 여유시간 3초정도 더 줌.

	space_sfx:FadeOut(2)

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	CS.UnityEngine.GameObject.Destroy(earth_theatre.gameObject)

	holder:Dispose()

	-- 스테이지 캠 원상복구
	stage_camera.Enabled = true

	camera_util.move_async(user_party_leader.Position, 0, { end_target = user_party_leader })

	music_player_util.play_stage_music({ state = 'field', mix = 2 })

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	character_util.set_anim(self.craig, { name = 'cast' })
	character_util.set_emotion(self.craig, { name = 'tired' })

	-- 난민들을 데리고 대피한 이 곳 부유성마저 대부분 인베이더들에 손아귀에 떨어졌지.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_29', skip = true })

	character_util.set_anim(self.craig, { name = 'cross_arm' })

	-- 공주님과 우리 레지스탕스가 겨우…마지막 방어선을 지키고 있는 상태야.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_30', skip = true })

	character_util.remove_anim(self.craig)
	character_util.remove_emotion(self.craig)

	-- 바로 여기, 부유성 마지막 방어선에서 말이야.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_31', skip = true })

	-- 공주님...
	choose_util.play_choose_event({{'futurecastle_main_a_s7_31_1', 'mercy'}})

	character_util.set_anim(self.craig, { name = 'nod' })

	-- 그래, 바로 그 꼬마 공주님일세.
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_32', skip = true })

	character_util.remove_anim(self.craig)

	-- 정말 강인하고 다부지게 성장하셨어..
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_33', skip = true })

	character_util.set_anim(self.craig, { name = 'question', loop = false })
	character_util.set_emotion(self.craig, { name = 'tired' })

	character_util.set_emotion(user_party_leader, { name = 'tired' })

	-- 보는 사람이 안타까울 정도로…
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_34', skip = true })

	character_util.set_anim(self.craig, { name = 'cast2' })
	character_util.set_emotion(self.craig, { name = 'smile' })

	character_util.remove_emotion(user_party_leader)

	-- 오랜만에 만났는데 우울한 이야기만 했군. 그래, 다른 친구도 만나고 싶지 않나?
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_35', skip = true })

	character_util.set_anim(self.craig, { name = 'release', sfx_name = '01_swing_01' })

	-- 반가운 얼굴들이 최전선 목책에 있을걸세. 잊지 말고 방문해보게!
	speech_bubble_util.show_speech_bubble_async(self.craig, { key = 'futurecastle_main_a_s7_36', skip = true })

	character_util.remove_anim(self.craig)
	character_util.remove_emotion(self.craig)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.craig_event_finished }))

	stage_progress:SendCustomData(self.custom_key.finished_craig_event, true)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	character_util.remove_relate_event(self.craig, self.cs_controller)
	self.craig = nil

	self.training_resistance_list = nil
	self.training_dummy_list = nil

	self.resistance_talk_key_list = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
