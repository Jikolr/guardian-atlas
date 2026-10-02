local local_class = newclass('Cafe1At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.demo_1_start = false
	self.demo_2_start = false
	self.school_zone_start = false
	self.bianca_house_zone_start = false

	self.have_to_demo_1_start = false
	self.have_to_demo_2_start= false
	self.have_to_bianca_house_zone_start = false
	self.target_score = 0
	self.rock_item_id = 20019
	self.dark_succubus = CS.UnityEngine.Color(0.4, 0.4, 0.4, 0.4)
	self.has_dark = false

	self.demo_sfx = nil
end

function local_class:load_resource()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	if q ~= nil and q.InnerProgress >= 19 then
		message_system:Subscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent), 'on_event')
	end

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == 'cafe_1_4' then
		quest_util.load_pool_resource(
			  'FX_hit'
		)
	 end
end

function local_class:need_on_launch()

	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	self:stage_event_setting(q.InnerProgress)

	if q ~= nil and q.InnerProgress <= 17 and q.InnerProgress >= 14 and not q.IsComplete then
		if q==nil then

		end

	elseif q ~= nil and q.InnerProgress >= 19 then
		local yuze = get_character('yuze')
		if yuze.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
			yuze.Interactable:AddListener(self.cs_controller)
		end

		message_system:Publish(CS.Oak.DoorOpenEvent.Create('cafe_door_1'))
	else

	end
	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:dispose()
	self.cs_controller = nil

	self.demo_sfx = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SuccubusCafeEndEvent))

end

function local_class:on_event(e)
	local event_type = e:GetType()
	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)


	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	if event_type == typeof(CS.Oak.SuccubusCafeEndEvent) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_event_end, self, e.IsCancelled, e.Sales))

	end

	if event_type == typeof(CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if q ~= nil and q.InnerProgress <= 17 and q.InnerProgress >= 14 and not q.IsComplete then
			if e.Zone.Name == 'demo_zone' then
				self.have_to_demo_1_start = true
				if self.demo_1_start == false then
					self.demo_1_start = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.demo_at_cafe, self))
				end

			elseif e.Zone.Name == 'worrying_demo_zone' then
				if self.demo_sfx == nil then
					self.demo_sfx = music_player_util.play_sfx({ sfx_name = '01_crowd_buzz_01', loop = true, type_priority = 'loop', player_priority = 'default' })
				end

				self.have_to_demo_2_start = true
				if self.demo_2_start == false then
					self.demo_2_start = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.demo_at_main_street, self))
				end

			elseif e.Zone.Name == 'school_zone' and not self.school_zone_start then
				self.school_zone_start = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.succubus_school_event, self))

			elseif e.Zone.Name == 'bianca_house_zone' then
				self.have_to_bianca_house_zone_start = true
				if self.bianca_house_zone_start == false then
					self.bianca_house_zone_start = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.throw_stone_event, self))
				end

			end
		end

		if e.Zone.Name == 'succubus_cafe_zone' then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
		end

		return true
	end

	if event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'demo_zone' then
			self.have_to_demo_1_start = false
		elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'worrying_demo_zone' then
			if self.demo_sfx ~= nil then
				self.demo_sfx:FadeOut(1)
				self.demo_sfx = nil
			end
			self.have_to_demo_2_start = false

		elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'bianca_house_zone' then
			self.have_to_bianca_house_zone_start = false

		elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == 'succubus_cafe_zone' and e.FullLeave then
			music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_cafe_main', state = 'event', mix = 1.5 })

		end
		return true
	end
	return false
end


function local_class:succubus_darkened(is_dark)

	if is_dark then
		if not self.has_dark then
			field:Tint('dark', self.dark_succubus, 1)
			self.has_dark = true
		end
	else
		field:RemoveTint('dark', 1)
		self.has_dark = false
	end

end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_character('yuze')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cafe_manage_start, self))

	end

	return true
end


--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine()
	local party_list = {}

	local cafe_main_quest_id = 60033
	local q = user_progress:GetStartedQuest(cafe_main_quest_id)

	for i = 0, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		if i ~= 1 then
			character_util.convert_to_npc(party_list[i])
			party_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end

	if q ~= nil and q.InnerProgress == 16 and not q.IsComplete then
		if q==nil then

		end
		character_util.set_position(user_party.Leader, vector(-4.5, 0, -97.5))
		camera_util.move(user_party.Leader.Position, 0, {end_target = user_party.Leader})
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(-5.5, 0, -97.5),
		CS.Oak.Direction.Right, game_string:GetString(stage.Name)))

	elseif q ~= nil and q.InnerProgress == 18 and not q.IsComplete then
		if q==nil then

		end

	elseif q ~= nil and q.InnerProgress == 14 and not q.IsComplete then
		if q==nil then

		end

	else
		music_player_util.set_stage_music_clip_async({state = 'field', name = 'ondemand/cafe/audio:bgm_world_map_06'})
		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')

		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(0, 0, 0),
				CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
	end


end

--모든 스테이지 이벤트들 세팅
function local_class:stage_event_setting(innerprogress)

	if innerprogress >= 14 and innerprogress <= 17 then
		-- 메인 광장 서큐버스들과 괴롭히는 시위대 세팅
		for i = 1, 4 do
			local temp = get_character('worrying_succubus_' .. i)

			if i == 1 or i == 2 then
				temp.Interactable.Talk = 'cafe_s15_37'
			else
				temp.Interactable.Talk = 'cafe_s15_38'
			end
			character_util.set_anim(temp, { name = 'seat', loop = true })
			character_util.set_emotion(temp, { name = 'tired', loop = true })
		end

		local wd_pos = { vector(19, 0, -79), vector(22.5, 0, -79), vector(19, 0, -80), vector(22.5, 0, -80),
			vector(19, 0, -81), vector(22.5, 0, -81) }
		for i = 1, 6 do
			local demo = get_character('worrying_demo_' .. i)
			demo.SpineController:SetAttachment('[base]weapon1', 'succubus_picket')
			if i % 2 == 1 then
				character_util.set_direction(demo, 'right')
			else
				character_util.set_direction(demo, 'left')
			end
			character_util.set_position(demo, wd_pos[i] + vector(-21, 0, 0))

			character_util.set_anim(demo, { name = 'strike_idle', loop = true })
			character_util.set_emotion(demo, { name = 'attack', loop = true })
			demo.Interactable.Talk = ''
		end

		--시위하는 사람들 세팅
		local demo_pos = {vector(16, 0, -31), vector(17, 0, -30), vector(17, 0, -31), vector(17, 0, -32),
		vector(18, 0, -30), vector(18, 0, -31), vector(18, 0, -32), vector(19, 0, -30), vector(19, 0, -31), vector(19, 0, -32),
		vector(11, 0, -31), vector(10, 0, -30), vector(10, 0, -31), vector(10, 0, -32), vector(9, 0, -30), vector(9, 0, -31),
		vector(9, 0, -32), vector(8, 0, -30), vector(8, 0, -31), vector(8, 0, -32)}

		for i = 1, 20 do
			local demo = get_character('demo_'..i)
			demo.SpineController:SetAttachment('[base]weapon1', 'succubus_picket')
			if i <= 10 then
				character_util.set_direction(demo, 'left')
				character_util.set_position(demo, demo_pos[i])

			else
				character_util.set_direction(demo, 'right')
				character_util.set_position(demo, demo_pos[i])
			end

			character_util.set_anim(demo, { name = 'strike_idle', loop = true })
			character_util.set_emotion(demo, { name = 'attack', loop = true })
			demo.Interactable.Talk = ''

		end

		--비앙카네 가드에게 돌던지는 사람들 세팅
		for i = 1, 2 do
			local guard = get_character('bianca_guard_'..i)
			character_util.set_anim(guard, { name = 'idle', loop = true })
			character_util.set_emotion(guard, { name = 'tired', loop = true })
			guard.Interactable.Talk = ''
		end
		for i = 1, 5 do
			local throw = get_character('throw_stone_'..i)
			character_util.set_anim(throw, { name = 'idle', loop = true })
			character_util.set_emotion(throw, { name = 'attack', loop = true })
			character_util.set_direction(throw, 'up')
			throw.Interactable.Talk = ''
		end

		--서큐버스 학교 세팅
		local student_pos = {vector(-10, 0, -49), vector(-9, 0, -49), vector(-11, 0, -48.2), vector(-8, 0, -48.2),
		vector(-10, 0, -50), vector(-9, 0, -50), vector(-8, 0, -49.2), vector(-11, 0, -49.2),
		vector(-12, 0, -47.4), vector(-7, 0, -47.4), vector(-12, 0, -48.4), vector(-7, 0, -48.4)}
		for i = 1, 12 do
			local student = get_character('succubus_student_'..i)
			student.Interactable.Talk = ''
			character_util.set_position(student, student_pos[i])
			if student_pos[i].z > -48.5 then
				if student_pos[i].x > -9.5 then
					character_util.set_direction(student, 'left')
				else
					character_util.set_direction(student, 'right')
				end
				character_util.set_anim(student, { name = 'cross_arm', loop = true })
				character_util.set_emotion(student, { name = 'attack', loop = true })
			else
				character_util.set_direction(student, 'up')
				character_util.set_anim(student, { name = 'idle', loop = true })

			end
		end

	elseif innerprogress >= 18 then
		--시위 걱정하는 서큐버스들 수정
		for i = 1, 4 do
			local succubus = get_character('worrying_succubus_'..i)
			if i == 1 or i == 2 then
				succubus.Interactable.Talk = 'cafe_s15_36'
				character_util.set_anim(succubus, { name = 'success', loop = true })
				character_util.set_emotion(succubus, { name = 'smile', loop = true })
			else
				succubus.Interactable.Talk = 'cafe_s15_43'
				character_util.set_anim(succubus, { name = 'sing', loop = true })
				character_util.set_emotion(succubus, { name = 'awesome', loop = true })
			end

		end

		--서큐버스 학교 세팅
		local student_pos = {vector(-10, 0, -49), vector(-9, 0, -49), vector(-11, 0, -48.2), vector(-8, 0, -48.2),
		vector(-10, 0, -50), vector(-9, 0, -50), vector(-8, 0, -49.2), vector(-11, 0, -49.2),
		vector(-12, 0, -47.4), vector(-7, 0, -47.4), vector(-12, 0, -48.4), vector(-7, 0, -48.4)}
		for i = 1, 12 do
			local student = get_character('succubus_student_'..i)
			student.Interactable.Talk = 'cafe_s15_45'
			character_util.set_position(student, student_pos[i])
			if student_pos[i].z > -48.5 then
				if student_pos[i].x > -9.5 then
					character_util.set_direction(student, 'left')
				else
					character_util.set_direction(student, 'right')
				end
				character_util.set_anim(student, { name = 'cast', loop = true })
				character_util.set_emotion(student, { name = 'tired', loop = true })
			else
				character_util.set_direction(student, 'up')
				character_util.set_anim(student, { name = 'idle', loop = true })

			end
		end

		local succubus_teacher = get_character('succubus_teacher')
		succubus_teacher.Interactable.Talk = 'cafe_s15_46'
		character_util.set_direction(succubus_teacher, 'down')
		character_util.set_anim(succubus_teacher, { name = 'cast', loop = true })
		character_util.set_emotion(succubus_teacher, { name = 'smile', loop = true })

		for i = 1, 2 do
			local succubus_dark = get_character('succubus_dark_'..i)
			succubus_dark.Interactable.Talk = 'cafe_s15_'..(i+46)
		end
	end

end

--비앙카 가드들한테 돌 던지고 있는 이벤트
function local_class:throw_stone_event()
	local rand_dir = 0
	local rand_index = 0
	local rand_delay = 0
	local rand_talk = 0

	while self.have_to_bianca_house_zone_start do
		rand_dir = math.floor(unity_class.random.Range(0, 2))
		rand_index = math.floor(unity_class.random.Range(0, 5))
		rand_delay = unity_class.random.Range(0.2, 0.5)

		local thrower = get_character('throw_stone_'..(rand_index + 1))
		local target = get_character('bianca_guard_'..(rand_dir + 1))

		character_util.look_at(thrower, target)
		character_util.set_anim(thrower, { name = 'attack', loop = false })
		music_player:PlaySfxOneShot('01_swing_01')

		local rock = drop_item_util.create_item(
				{ itemid = self.rock_item_id, notforinven = true, pos = thrower.Position + vector(0, 0, 0.5),
				  target = target.Position, lootstate = 'dontfindlooter', sprscale = 0.3, showoncharacter = true })

		wait_for_sec(0.5)

		character_util.remove_anim(thrower)

		wait_for_sec(0.2)

		-- 명중에 성공했을 경우 실행
		if (rock.Position - target.Position).magnitude < 0.5 then
			music_player:PlaySfxOneShot('02_hit_big_01')
			unity_object_pool.GetOrCreate('FX_hit'):Instantiate(target.Position + vector(0, 0.3, 0))
			character_util.spine_pulse_color(target, CS.Oak.Constants.DamageColor, 1, 1, 0.667)
			character_util.spine_damage_squish(target, 1.3, 0.7, 1, 0.3)
		end

		wait_for_sec(0.1)

		rock:ConsumeComplete()

		rand_talk = rand_talk + 1

		if rand_talk == 1 then
			speech_bubble_util.show_speech_bubble_async(thrower, { key = 'cafe_s15_15', skip = false, bubble_type = 'shout' })
		elseif rand_talk == 2 then
			speech_bubble_util.show_speech_bubble_async(thrower, { key = 'cafe_s15_16', skip = false, bubble_type = 'shout' })

			character_util.set_anim(target, { name = 'release', loop = true })
			character_util.set_emotion(target, { name = 'attack', loop = true })
			speech_bubble_util.show_speech_bubble_async(target, { key = 'cafe_s15_18', skip = false, bubble_type = 'shout' })
			character_util.remove_anim_and_emotion(target)
		else
			rand_talk = 0
			speech_bubble_util.show_speech_bubble_async(thrower, { key = 'cafe_s15_17', skip = false, bubble_type = 'shout' })
		end

		wait_for_sec(rand_delay)
	end

	self.bianca_house_zone_start = false

end

--카페 바로 앞 데모 이벤트
function local_class:demo_at_cafe()
	local demo_1 = get_character('demo_1')
	local demo_11 = get_character('demo_11')
	local rand_num = 2

	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_01', parent = demo_1, fade_in_time = 1, fade_out_time = 1, type_priority = 'event', player_priority = 'npc' })

	while self.have_to_demo_1_start do
		music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = demo_1, type_priority = 'event', player_priority = 'npc' })
		speech_bubble_util.show_speech_bubble_async(demo_1, { key = 'cafe_s15_1', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(2, 10))
		music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = get_character('demo_'..rand_num), type_priority = 'event', player_priority = 'npc' })
		speech_bubble_util.show_speech_bubble_async(get_character('demo_'..rand_num), { key = 'cafe_s15_2', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(2, 10))
		music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', parent = get_character('demo_'..rand_num), type_priority = 'event', player_priority = 'npc' })
		speech_bubble_util.show_speech_bubble_async(get_character('demo_'..rand_num), { key = 'cafe_s15_2', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

		if self.have_to_demo_1_start == false then
			break
		end

		speech_bubble_util.show_speech_bubble_async(demo_11, { key = 'cafe_s15_4', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(2, 9))
		speech_bubble_util.show_speech_bubble_async(get_character('demo_1'..rand_num), { key = 'cafe_s15_5', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(2, 9))
		speech_bubble_util.show_speech_bubble_async(get_character('demo_1'..rand_num), { key = 'cafe_s15_5', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

		if self.have_to_demo_1_start == false then
			break
		end

		rand_num = math.floor(unity_class.random.Range(1, 2))

		if rand_num == 1 then
			speech_bubble_util.show_speech_bubble_async(demo_1, { key = 'cafe_s15_6', skip = false, bubble_type = 'shout' })
		else
			speech_bubble_util.show_speech_bubble_async(demo_11, { key = 'cafe_s15_6', skip = false, bubble_type = 'shout' })
		end

		rand_num = math.floor(unity_class.random.Range(2, 10))
		speech_bubble_util.show_speech_bubble_async(get_character('demo_'..rand_num), { key = 'cafe_s15_7', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(2, 9))
		speech_bubble_util.show_speech_bubble_async(get_character('demo_1'..rand_num), { key = 'cafe_s15_7', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

	end

	self.demo_1_start = false

end
function local_class:demo_at_main_street()
	local rand_num = 1

	while self.have_to_demo_2_start do
		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_1', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_2', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_2', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

		if self.have_to_demo_2_start == false then
			break
		end

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_4', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_5', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_5', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

		if self.have_to_demo_2_start == false then
			break
		end

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_6', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_7', skip = false, bubble_type = 'shout' })

		rand_num = math.floor(unity_class.random.Range(1, 6))
		speech_bubble_util.show_speech_bubble_async(get_character('worrying_demo_'..rand_num), { key = 'cafe_s15_7', skip = false, bubble_type = 'shout' })

		wait_for_sec(1)

	end

	self.demo_2_start = false

end


--학교 이벤트
function local_class:succubus_school_event()
	local succubus_teacher = get_character('succubus_teacher')
	local student_1 = get_character('succubus_student_1')
	local student_3 = get_character('succubus_student_3')
	local student_4 = get_character('succubus_student_4')
	--다들 조용! 조용!
	character_util.set_anim(succubus_teacher, { name = 'release', loop = true })
	character_util.set_emotion(succubus_teacher, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(succubus_teacher, { key = 'cafe_s15_8', skip = false, bubble_type = 'shout' })

	--드림테라피를 배우면 살인자래요! 저희는 살인자가 되기 싫어요!
	character_util.set_anim(succubus_teacher, { name = 'idle', loop = true })
	character_util.set_emotion(succubus_teacher, { name = 'surprise', loop = true })
	character_util.normal_jump(succubus_teacher)

	character_util.set_anim(student_1, { name = 'release', loop = true })
	speech_bubble_util.show_speech_bubble_async(student_1, { key = 'cafe_s15_9', skip = false })
	character_util.remove_anim(student_1)

	--아니야, 얘들아. 그 영상은 다 거짓말이야!
	character_util.set_anim(succubus_teacher, { name = 'cast', loop = true })
	character_util.set_emotion(succubus_teacher, { name = 'tired', loop = true })
	speech_bubble_util.show_speech_bubble_async(succubus_teacher, { key = 'cafe_s15_10', skip = false })

	--증거있어요? 이 영상에는 증거도 있다구요!
	character_util.set_direction(succubus_teacher, 'left')
	character_util.set_anim(student_3, { name = 'release', loop = true })
	character_util.set_emotion(student_3, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(student_3, { key = 'cafe_s15_11', skip = false })
	character_util.set_anim(student_3, { name = 'cross_arm', loop = true })

	--즈... 증거는...
	character_util.set_emotion(succubus_teacher, { name = 'scared', loop = true })
	speech_bubble_util.show_speech_bubble_async(succubus_teacher, { key = 'cafe_s15_12', skip = false })

	--저희는 수업 안 들을거예요!!
	character_util.set_anim(student_4, { name = 'release', loop = true })
	character_util.set_emotion(student_4, { name = 'attack', loop = true })
	speech_bubble_util.show_speech_bubble_async(student_4, { key = 'cafe_s15_13', skip = false })
	character_util.set_anim(student_4, { name = 'cross_arm', loop = true })

	for i = 1, 12 do
		local student = get_character('succubus_student_'..i)

		if student.Direction == CS.Oak.Direction.Left then
			character_util.set_direction(student, 'right')

		elseif student.Direction == CS.Oak.Direction.Right then
			character_util.set_direction(student, 'left')

		else
			character_util.set_direction(student, 'down')
			character_util.set_anim(student, { name = 'cross_arm', loop = true })
			character_util.set_emotion(student, { name = 'attack', loop = true })

		end
		character_util.normal_jump(student)
		student.Interactable.Talk = 'cafe_s15_13'
	end

	--얘들아...
	character_util.set_emotion(succubus_teacher, { name = 'tired', loop = true })
	speech_bubble_util.show_speech_bubble_async(succubus_teacher, { key = 'cafe_s15_14', skip = false })

	for i = 1, 12 do
		local student = get_character('succubus_student_'..i)
		student.Interactable.Talk = 'cafe_s15_13'
	end

	succubus_teacher.Interactable.Talk = 'cafe_s15_14'
end

--카페 이벤트 시작
 --카페 운영 파트 시작
function local_class:cafe_manage_start()
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	local yuze = get_character('yuze')
	local choice = 0

	character_util.align_party(yuze.Position, 'down', 1, 'linear')

	--어때, 이제 장사 시작할 준비 됐어?
	character_util.set_anim(yuze, { name = 'bomb_idle', loop = true })
	character_util.set_emotion(yuze, { name = 'smile', loop = true })
	speech_bubble_util.show_speech_bubble_async(yuze, { key = 'cafe_s9_14', skip = true })

	--선택지
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait_for_branch = true
	--네
	branches:Add({
		Text = game_string:GetString('cafe_s9_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			choice = 1
		end
	})
	--아니오
	branches:Add({
		Text = game_string:GetString('cafe_s9_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait_for_branch = false
			choice = 0
		end
	})
	local choice_state = CS.Oak.UI.AnswerChoiceState()
	choice_state.Branchs = branches
	choice_state.Talker = yuze

	ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)
	while wait_for_branch do
		coroutine.yield(nil)
	end
	character_util.remove_anim_and_emotion(yuze)

	--선택지 준비 됐어?
	if choice == 1 then
		--카페 운영 시작.
		message_system:Publish(CS.Oak.SuccubusCafeStartEvent.Create(self.target_score))

	else
		--인터랙트 종료.
		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end

end

--카페 이벤트 끝
function local_class:cafe_event_end(iscancelled, score)

	music_player_util.play_stage_music({ name = 'ondemand/cafe/audio:bgm_world_map_06', state = 'event', mix = 1.5 })
	if score >= self.target_score then
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()

	elseif iscancelled then
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()

	else
		camera_util.move_async(user_party.Leader.Position, 0, {end_target = user_party.Leader})

		wait_for_sec(0.5)
		screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

		stage.FieldUIManager:Show()
		user_party:ResetControllers()
	end
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}