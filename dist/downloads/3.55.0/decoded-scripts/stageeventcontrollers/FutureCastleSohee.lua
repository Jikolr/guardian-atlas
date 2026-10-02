local local_class = newclass("FutureCastleSoheeController")


function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 진행 상황
	self.event_progress = {
		idle = 0,
		event_started = 1,
		talk_with_sohee = 2,
		event_finished = 3,
		event_deactivated = 4
	}

	self.current_progress = self.event_progress.idle

	self.sohee = nil

	self.lavi = nil

	self.buster_turret = nil

	-- 이벤트 종료 후, 소히 중복 대화 방지 플래그
	self.is_lavi_talk = false

	-- 기타 상수
	self.scroll_item_id = 20210

	-- 캐릭터 이름
	self.sohee_name = 'sohee'
	self.lavi_name = 'lavi'

	-- 필드오브젝트 이름
	self.buster_turret_name = 'buster_turret'

	-- 필드 이벤트 존 이름
	self.push_event_zone_name = 'section_9_sohee'

	-- 커스텀 이벤트 이름
	self.invader_attack_start_event = 'invader_attack_start'
	self.sohee_event_finished = 'sohee_event_finished'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = 'FX_hit'
	self.impact_hit_effect_preset = 'FX_lasthit'

	-- FutureCastle1At2.lua의 커스텀 키 개수가 늘어나면 변경되어야 함
	-- FIXME: 굉장히 안 좋은 구조인데 수정할 방법 없는지 찾아볼 것
	self.custom_key = {
		finished_sohee_event = 11
	}
end

function local_class:load_resource()
	-- 현재 메인 퀘스트 상황에 따라 스테이지 이벤트 상태 설정
	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil then
		if main_quest.InnerProgress < 10 then
			if stage_progress:GetCustomData(self.custom_key.finished_sohee_event, false) then
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
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	if self.current_progress < self.event_progress.event_finished then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
		message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	end

	self.sohee = get_character(self.sohee_name)

	self.lavi = get_character(self.lavi_name)

	self.buster_turret = get_field_object(self.buster_turret_name)

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
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
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	if self.current_progress ~= self.event_progress.event_deactivated then
		self.lavi.SpineController.AlwaysUpdateSpine = true
		self.lavi.Interactable:AddListener(self.cs_controller)

		if self.current_progress < self.event_progress.event_finished then
			character_util.set_position(self.sohee, self.buster_turret.Position + vector(0.5, 1.2, -0.2))
			character_util.set_direction(self.sohee, 'left')
			character_util.set_anim_and_emotion(self.sohee, { name = 'seat' }, { name = 'attack' })

			character_util.set_position(self.lavi, self.buster_turret.Position + vector(-0.6, 0, 0))
			character_util.set_direction(self.lavi, 'right')
			character_util.set_anim_and_emotion(self.lavi, { name = 'push' }, { name = 'damaged' })

			self.buster_turret.Interactable = CS.Oak.PublishInteractable.Create()
		elseif self.current_progress == self.event_progress.event_finished then
			character_util.set_position(self.lavi, self.buster_turret.Position + vector(-1, 0, 0))
			character_util.set_direction(self.lavi, 'left')
		end
	end
end

function local_class:on_stage_start_event(e)
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end

	local zone_name = e.Zone.Name

	if zone_name == self.push_event_zone_name then
		if self.current_progress == self.event_progress.idle then
			self.current_progress = self.event_progress.event_started

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.push_turret_event, self))
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.lavi) then
		if self.current_progress < self.event_progress.talk_with_sohee then
			sp_util.play_normal_screenplay(self.sohee_event, self, true)
		else
			if not self.is_lavi_talk then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.lavi_short_talk, self))
			end
		end
	elseif lua_helper.reference_equals(e.Target, self.buster_turret) then
		if self.current_progress < self.event_progress.talk_with_sohee then
			sp_util.play_normal_screenplay(self.sohee_event, self, false)
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.invader_attack_start_event then
			self.current_progress = self.event_progress.event_deactivated
		end
	end
end
--endregion

-- 라비가 터렛 밀고 소히가 훈수하는 이벤트, 플레이어가 말 걸면 종료되어야 함
function local_class:push_turret_event()
	self.lavi.SpineController.AlwaysUpdateSpine = false

	character_util.set_anim(self.sohee, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_1' })

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.sohee, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.sohee, { name = 'mad' })

	character_util.jump(self.lavi, 1, 0.5)
	character_util.set_anim(self.lavi, { name = 'embarrassed' })
	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_2' , dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.sohee.Position)})

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'cast' })
	character_util.set_emotion(self.sohee, { name = 'attack' })

	character_util.jump(self.lavi, 0.5, 0.3)
	character_util.set_anim(self.lavi, { name = 'cast2' })
	character_util.set_emotion(self.lavi, { name = 'attack' })

	wait_for_sec(0.3)

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '01_small_jump_01', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	character_util.jump(self.lavi, 0.5, 0.3)

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_3' , dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.lavi.Position)})

	if self.current_progress > self.event_progress.event_started then return end

	local slide_sfx = music_player_util.play_sfx({ sfx_name = '02_gimmick_door_down_01', parent = self.lavi, loop = true, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'seat' })

	character_util.set_anim(self.lavi, { name = 'push' })
	character_util.set_emotion(self.lavi, { name = 'damaged' })

	local cur_time = unity_class.time.time
	local push_duration = 2

	local push_dist = -2

	local sohee_pos = self.sohee.Position
	local lavi_pos = self.lavi.Position
	local buster_turret_pos = self.buster_turret.Position

	while self.current_progress < self.event_progress.talk_with_sohee and
			unity_class.time.time - cur_time < push_duration do
		local normalized = (unity_class.time.time - cur_time) / push_duration

		character_util.set_position(self.sohee, sohee_pos + vector(push_dist * normalized, 0, 0))
		character_util.set_position(self.lavi, lavi_pos + vector(push_dist * normalized, 0, 0))

		self.buster_turret.Position = buster_turret_pos + vector(push_dist * normalized, 0, 0)

		coroutine.yield(nil)
	end

	slide_sfx:FadeOut()

	if self.current_progress > self.event_progress.event_started then return end

	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_4' , dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.lavi.Position) })

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.sohee, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_5', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.sohee.Position) })

	if self.current_progress > self.event_progress.event_started then return end

	slide_sfx = music_player_util.play_sfx({ sfx_name = '02_gimmick_door_down_01', loop = true, parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'seat' })

	character_util.set_emotion(self.lavi, { name = 'damaged' })

	cur_time = unity_class.time.time
	push_duration = 2

	push_dist = 2

	sohee_pos = self.sohee.Position
	lavi_pos = self.lavi.Position
	buster_turret_pos = self.buster_turret.Position

	while self.current_progress < self.event_progress.talk_with_sohee and
			unity_class.time.time - cur_time < push_duration do
		local normalized = (unity_class.time.time - cur_time) / push_duration

		character_util.set_position(self.sohee, sohee_pos + vector(push_dist * normalized, 0, 0))
		character_util.set_position(self.lavi, lavi_pos + vector(push_dist * normalized, 0, 0))

		self.buster_turret.Position = buster_turret_pos + vector(push_dist * normalized, 0, 0)

		coroutine.yield(nil)
	end

	slide_sfx:FadeOut()

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_6', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.lavi.Position) })

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = self.sohee, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.sohee, { name = 'mad' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_7', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.sohee.Position) })

	if self.current_progress > self.event_progress.event_started then return end

	slide_sfx = music_player_util.play_sfx({ sfx_name = '02_gimmick_door_down_01', loop = true, parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'seat' })
	character_util.set_emotion(self.sohee, { name = 'attack' })

	character_util.set_emotion(self.lavi, { name = 'damaged' })

	cur_time = unity_class.time.time
	push_duration = 1

	push_dist = -1

	sohee_pos = self.sohee.Position
	lavi_pos = self.lavi.Position
	buster_turret_pos = self.buster_turret.Position

	while self.current_progress < self.event_progress.talk_with_sohee and
			unity_class.time.time - cur_time < push_duration do
		local normalized = (unity_class.time.time - cur_time) / push_duration

		character_util.set_position(self.sohee, sohee_pos + vector(push_dist * normalized, 0, 0))
		character_util.set_position(self.lavi, lavi_pos + vector(push_dist * normalized, 0, 0))

		self.buster_turret.Position = buster_turret_pos + vector(push_dist * normalized, 0, 0)

		coroutine.yield(nil)
	end

	slide_sfx:FadeOut()

	if self.current_progress > self.event_progress.event_started then return end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = self.lavi, type_priority = 'event', player_priority = 'npc' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_8', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, self.lavi.Position) })
end

function local_class:sohee_event(align_lavi)
	self.current_progress = self.event_progress.talk_with_sohee

	self.buster_turret.Interactable = CS.Oak.NonInteractable.Instance

	speech_bubble_util.remove_bubble(self.sohee)
	speech_bubble_util.remove_bubble(self.lavi)

	coroutine.yield(nil)

	self.sohee:HideWeapon(true)
	character_util.set_anim(self.sohee, { name = 'seat' })
	character_util.set_emotion(self.sohee, { name = 'attack' })

	self.lavi:HideWeapon(true)
	character_util.set_anim(self.lavi, { name = 'push' })
	character_util.set_emotion(self.lavi, { name = 'damaged' })

	if align_lavi then
		party_util.align_party(self.lavi, 'left', 1, 'arc')
	else
		local player_waypoint_list = create_generic_list(unity_class.vector3)

		if user_party_leader.Position.z < self.buster_turret.Position.z + 1.5 then
			player_waypoint_list:Add(vector(user_party_leader.Position.x, 0, self.buster_turret.Position.z + 1.5))
			player_waypoint_list:Add(vector(self.lavi.Position.x - 1, 0, self.buster_turret.Position.z + 1.5))
		else
			player_waypoint_list:Add(vector(self.lavi.Position.x - 1, 0, user_party_leader.Position.z))
		end

		player_waypoint_list:Add(vector(self.lavi.Position.x - 1, 0, self.lavi.Position.z))

		character_util.move_waypoint_async(user_party_leader, player_waypoint_list, 4, false,
				'stop', 'floor', 'right')
	end

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.jump(self.sohee, 0.5, 0.3)
	character_util.set_anim(self.sohee, { name = 'cast2' })
	character_util.set_emotion(self.sohee, { name = 'mad' })

	character_util.set_direction(self.lavi, 'left')
	character_util.remove_anim(self.lavi)
	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_9', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })

	character_util.jump(self.sohee, 1, 0.5)
	character_util.set_anim(self.sohee, { name = 'embarrassed' })
	character_util.set_emotion(self.sohee, { name = 'surprise' })

	character_util.set_anim(self.lavi, { name = 'cast' })
	character_util.set_emotion(self.lavi, { name = 'surprise' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_10', bubble_type = 'shout', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	-- 소히 점프
	local cur_time = unity_class.time.time
	local jump_duration = 0.4

	local start_pos = self.sohee.Position
	local end_pos = self.lavi.Position

	local freefall = CS.CalculatorFreeFall(jump_duration, start_pos.y, 0)

	character_util.jump(self.sohee, 1, jump_duration)
	character_util.set_anim(self.sohee, { name = 'get' })

	while unity_class.time.time - cur_time < jump_duration do
		local cur_x = CS.Oak.Interpolations.Linear(
				unity_class.time.time - cur_time, start_pos.x, end_pos.x - start_pos.x, jump_duration)

		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		character_util.set_position(self.sohee, vector(cur_x, start_pos.y + dist_y, end_pos.z), true)

		coroutine.yield(nil)
	end

	character_util.set_position(self.sohee, end_pos)

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_trip_01', type_priority = 'event', player_priority = 'npc' })

	-- 라비 소히에게 맞고 엎어짐
	camera_util.shake(0.2, 0.3)

	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
			self.lavi.Position + vector(0, 0.3, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
			self.lavi.Position + vector(0, 0.3, 0))

	character_util.move_to(user_party_leader, user_party_leader.Position + vector(-1, 0, 0),
			0.5, nil, false, true)

	character_util.set_anim(self.lavi, { name = 'prostrate' })
	character_util.set_emotion(self.lavi, { name = 'hurt' })

	-- 소히가 라비 밟고 뛰어올라 플레이어 앞으로 이동
	cur_time = unity_class.time.time
	jump_duration = 0.4

	start_pos = self.sohee.Position
	end_pos = self.sohee.Position + vector(-1, 0, 0)

	freefall = CS.CalculatorFreeFall(8, 34, 0, 0)

	character_util.jump(self.sohee, 1, jump_duration)
	character_util.set_anim(self.sohee, { name = 'get' })

	while unity_class.time.time - cur_time < jump_duration do
		local cur_x = CS.Oak.Interpolations.Linear(
				unity_class.time.time - cur_time, start_pos.x, end_pos.x - start_pos.x, jump_duration)

		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		character_util.set_position(self.sohee, vector(cur_x, start_pos.y + dist_y, end_pos.z), true)

		coroutine.yield(nil)
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_position(self.sohee, end_pos)
	character_util.set_anim(self.sohee, { name = 'shoot' })
	character_util.set_emotion(self.sohee, { name = 'scared' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_11', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.3, 0.3)

	character_util.jump(self.sohee, 1, 0.5)
	character_util.set_anim(self.sohee, { name = 'cast2' })
	character_util.set_emotion(self.sohee, { name = 'mad' })

	character_util.mario_jump_new(self.lavi, 'left')
	character_util.remove_anim(self.lavi)
	character_util.set_emotion(self.lavi, { name = 'surprise' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_12', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(self.sohee, { name = 'embarrassed' })
	character_util.set_emotion(self.sohee, { name = 'confused' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_13', skip = true })

	choose_util.play_choose_event({{ 'futurecastle_sohee_14', 'mercy' }})

	character_util.set_anim(user_party_leader, { name = 'push' })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)

	character_util.set_anim(self.sohee, { name = 'cast' })
	character_util.set_emotion(self.sohee, { name = 'tired' })

	character_util.jump(self.lavi, 1, 0.5)
	character_util.set_anim(self.lavi, { name = 'shoot' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_15', skip = true })

	character_util.remove_anim(self.sohee)
	character_util.remove_emotion(self.sohee)

	character_util.set_anim(self.lavi, { name = 'question', loop = false })
	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_16', skip = true })

	local result = choose_util.play_choose_event(
			{{'futurecastle_sohee_17', 'mercy'}, {'futurecastle_sohee_18', 'brutal'}})

	if result == 1 then
		music_player_util.play_sfx({ sfx_name = '01_gatcha_point_01', type_priority = 'event', player_priority = 'npc' })
		music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

		character_util.set_anim(user_party_leader, { name = 'cast' })
		character_util.set_emotion(user_party_leader, { name = 'scared' })

		character_util.set_anim(self.sohee, { name = 'push' })
		character_util.set_emotion(self.sohee, { name = 'greed' })

		character_util.jump(self.lavi, 1, 0.5)
		character_util.remove_anim(self.lavi)
		character_util.set_emotion(self.lavi, { name = 'surprise' })

		speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_19', skip = true })
	else
		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', type_priority = 'event', player_priority = 'npc' })

		character_util.set_anim(user_party_leader, { name = 'cast' })
		character_util.set_emotion(user_party_leader, { name = 'tired' })

		character_util.set_anim(self.sohee, { name = 'shoot' })
		character_util.set_emotion(self.sohee, { name = 'mad' })

		character_util.remove_anim(self.lavi)
		character_util.set_emotion(self.lavi, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_20', skip = true })
	end

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	character_util.set_direction(self.sohee, 'right')
	character_util.remove_anim(self.sohee)
	character_util.remove_emotion(self.sohee)

	character_util.jump(self.lavi, 1, 0.5)
	character_util.set_anim(self.lavi, { name = 'cast2' })
	character_util.set_emotion(self.lavi, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_21', skip = true })

	character_util.set_emotion(user_party_leader, { name = 'smile' })

	character_util.set_direction(self.sohee, 'left')
	character_util.set_emotion(self.sohee, { name = 'smile' })

	character_util.set_anim(self.lavi, { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_22', skip = true })

	choose_util.play_choose_event({{'futurecastle_sohee_23', 'intellect'}})

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_anim(user_party_leader, { name = 'bomb_idle' })
	character_util.remove_emotion(user_party_leader)

	character_util.jump(self.sohee, 1, 0.5)
	character_util.set_emotion(self.sohee, { name = 'attack' })

	character_util.jump(self.lavi, 1, 0.5)
	character_util.set_anim(self.lavi, { name = 'cast' })
	character_util.set_emotion(self.lavi, { name = 'tired' })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })

	character_util.remove_anim(user_party_leader)

	character_util.shake(self.sohee, 0.04, 1)
	character_util.set_anim(self.sohee, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_24', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.4, 0.3)

	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_anim(user_party_leader, { name = 'embarrassed' })
	character_util.set_emotion(user_party_leader, { name = 'scared' })

	character_util.set_anim(self.sohee, { name = 'cast2' })
	character_util.set_emotion(self.sohee, { name = 'mad' })

	character_util.set_emotion(self.lavi, { name = 'scared' })

	speech_bubble_util.show_speech_bubble_async(self.sohee, { key = 'futurecastle_sohee_25', skip = true })

	character_util.move_to(self.sohee, self.sohee.Position + vector(0, 0, 6),
			2, nil, true, true)

	wait_for_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '01_paper_01', type_priority = 'event', player_priority = 'npc' })

	local scroll = drop_item_util.create_item({ pos = self.sohee.Position + vector(0, 0.5, 0), target = self.sohee.Position,
	                                            itemid = self.scroll_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	wait_for_sec(0.5)

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	wait_for_sec(0.5)

	-- 아이템 획득
	scroll.ConsumeTarget = user_party_leader
	scroll:Fly()

	wait_for_sec(1.5)

	music_player_util.play_sfx({ sfx_name = '01_player_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.jump(self.lavi, 0.5, 0.3)
	character_util.set_direction(self.lavi, 'up')
	character_util.set_anim(self.lavi, { name = 'cast2' })
	character_util.set_emotion(self.lavi, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_26', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.lavi, 'left')
	character_util.set_anim(self.lavi, { name = 'hurt' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_26_1', skip = true })

	character_util.move_to_async(self.lavi, user_party_leader.Position + vector(1, 0, 0),
			0.5, nil, true, true)

	character_util.set_anim(self.lavi, { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_27', skip = true })

	character_util.set_direction(self.lavi, 'right')
	character_util.set_anim(self.lavi, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_28', skip = true })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	character_util.set_direction(self.lavi, 'left')
	character_util.jump(self.lavi, 1, 0.5)
	character_util.remove_emotion(self.lavi)

	wait_for_sec(0.5)

	character_util.set_anim(self.lavi, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(self.lavi, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_29', skip = true })

	character_util.set_anim(self.lavi, { name = 'question', loop = false })
	character_util.remove_emotion(self.lavi)

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_30', skip = true })

	character_util.remove_anim(self.lavi)
	character_util.remove_emotion(self.lavi)

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_31', skip = true })

	character_util.set_direction(user_party_leader, 'down')

	character_util.set_direction(self.lavi, 'down')

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_32', skip = true })

	self.sohee:HideWeapon(false)
	character_util.set_position(self.sohee, vector(999, 0, 999))
	character_util.remove_anim(self.sohee)
	character_util.remove_emotion(self.sohee)

	self.lavi:HideWeapon(false)
	character_util.set_direction(self.lavi, 'left')

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.sohee_event_finished }))

	stage_progress:SendCustomData(self.custom_key.finished_sohee_event, true)
end

function local_class:lavi_short_talk()
	self.is_lavi_talk = true

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_31' })

	speech_bubble_util.show_speech_bubble_async(self.lavi, { key = 'futurecastle_sohee_32' })

	self.is_lavi_talk = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.sohee = nil

	self.lavi = nil

	self.buster_turret = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
