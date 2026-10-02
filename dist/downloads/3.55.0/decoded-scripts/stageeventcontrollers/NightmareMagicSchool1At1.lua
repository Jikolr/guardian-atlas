local local_class = newclass("NightmareMagicSchool1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.ghost_disappear_time = 0.2

	self.ghost_disappeared = { false, false, false}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.seen_fall_down_event = false
	self.seen_run_away_event = false
end

function local_class:need_on_launch()
	-- 메인퀘스트가 PreSection이거나 1섹션인데 시간여행 도착씬을 보지않았다면 커스텀 인트로 이벤트를 진행한다.
	local main_quest = user_progress:GetStartedQuest(86)
	if main_quest ~= nil then
		return not main_quest.IsComplete and main_quest.InnerProgress == 0 and main_quest:GetCustomState('seen_time_travel_arrival') == -1
	else
		return true
	end
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self:ghost_event_dispose()

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(user_party_leader, e.FieldObject) then
		if not self.seen_fall_down_event and e.Zone.Name == 'fall_down_teacher' then
			self.seen_fall_down_event = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_down_teacher, self))
		end

		-- 도망가는 학생들 이벤트와 쓰러지는 선생님 이벤트가 동시에 일어나야 되기 때문에 같은 이벤트 존을 공유함.
		if not self.seen_run_away_event and e.Zone.Name == 'fall_down_teacher' then
			self.seen_run_away_event = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.run_away_students, self))
		end

		self:on_ghost_zone_enter_event(e)
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:ghost_knockback_event_setting()

		self:run_away_students_event_setting()

		self:fall_down_teacher_event_setting()
	end

	return false
end

function local_class:on_ghost_zone_enter_event(e)
	if not self.ghost_disappeared[1] and e.Zone.Name == 'disappear_ghost_1' then
		self.ghost_disappeared[1] = true
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.ghost_disappear, self, get_character('surprise_ghost_1')))
	end

	if not self.ghost_disappeared[2] and e.Zone.Name == 'disappear_ghost_2' then
		self.ghost_disappeared[2] = true
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.ghost_disappear, self, get_character('surprise_ghost_2')))
	end

	if not self.ghost_disappeared[3] and e.Zone.Name == 'disappear_ghost_3' then
		self.ghost_disappeared[3] = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ghost_knockback_event, self))
	end
end

function local_class:ghost_knockback_event_setting()
	local main_quest = user_progress:GetStartedQuest(86)
	if main_quest ~= nil and main_quest.InnerProgress >= 1 then
		for i = 1, #self.ghost_disappeared do
			self.ghost_disappeared[i] = true
		end

		for i = 1, 4 do
			local ghost = get_character('surprise_ghost_' .. i)
			ghost.ActiveState = active_state('disabled')
		end
	end
end

function local_class:ghost_event_dispose()
	self.ghost_disappeared = nil
end

function local_class:ghost_knockback_event()
	local ghost1 = get_character('surprise_ghost_3')
	local ghost2 = get_character('surprise_ghost_4')

	ghost1.SpineController:SetAlphaFade(1, 0.3)
	ghost2.SpineController:SetAlphaFade(1, 0.3)

	music_player:PlaySfxOneShot('01_hit_npc_01')

	local info = {
		type = CS.Oak.KnockBackType.Linear,
		jump = true, stun = true,
		direction = direction_util.to_vector3(direction_util.get_opposite(user_party_leader.Direction)),
		linearDuration = CS.Oak.Constants.WallBounceTime,
		linearMagnitude = CS.Oak.Constants.WallBounceDistance * 3
	}
	command_util.publish_knock_back(ghost1.Owner, user_party_leader, info, user_party_leader.Position)

	music_player:PlaySfxOneShot('01_ghost_laugh_evil_01')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ghost_disappear, self, ghost1))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ghost_disappear, self, ghost2))
end

function local_class:ghost_disappear(ghost)
	ghost.SpineController:SetAlphaFade(0, self.ghost_disappear_time)
	coroutine.yield(coroutine_class.wait_for_sec(self.ghost_disappear_time))

	ghost.ActiveState = active_state('disabled')
end

function local_class:run_away_students_event_setting()
	local main_quest = user_progress:GetStartedQuest(86)
	if main_quest ~= nil and main_quest.InnerProgress >= 1 then
		self.seen_run_away_event = true
		for i = 1, 6 do
			local student = get_character('run_away_student_' .. i)
			student.ActiveState = active_state('disabled')
		end
	end
end

function local_class:run_away_students()
	local waypoints = {
		{ vector(-2, 0, 16), vector(-2, 0, 21) },
		vector(1, 0, 21),
		{ vector(-1.5, 0, 14), vector(-1.5, 0, 21) },
		{ vector(-4, 0, 14), vector(-2, 0, 14), vector(-2, 0, 21) },
		{ vector(3, 0, 14.5), vector(0.5, 0, 14.5), vector(0.5, 0, 21) },
		{ vector(1, 0, 16), vector(1, 0, 21) }
	}

	for i = 1, 6 do
		local runner = get_character('run_away_student_' .. i)
		character_util.look_at(runner, user_party_leader)
		runner:SetEmotion('scared', true)
		runner:SetAnimation('embarrassed', true)
		character_util.normal_jump(runner)
	end
	wait_for_sec(0.3)

	-- 시간 여행 도착 씬일때만 1초 기다려준다.
	local is_time_travel_arrival_scene = self:need_on_launch()
	if is_time_travel_arrival_scene then
		wait_for_sec(1)
	end

	music_player:PlaySfxOneShot('03_runaway_01')

	local talk_cnt = 1;
	for i = 1, 6 do
		local runner = get_character('run_away_student_' .. i)

		runner:SetEmotion('damaged', true)
		runner:RemoveAnimation()

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.run_away_process, self, runner, waypoints[i], 7))

		if i == 2 or i == 5 then
			speech_bubble_util.show_speech_bubble(runner, {key = "nightmare_run_away_students_".. talk_cnt, bubble_type = 'shout'})
			talk_cnt = talk_cnt + 1
		end
	end
end

function local_class:run_away_process(runner, wp, speed)
	wp_util.move_way_points_async(runner, {waypoints = wp, speed = speed, run = true})

	runner:RemoveEmotion()
	runner:RemoveAnimation()
	runner.ActiveState = active_state('disabled')
end

function local_class:fall_down_teacher_event_setting()
	local main_quest = user_progress:GetStartedQuest(86)
	if main_quest ~= nil and main_quest.InnerProgress >= 1 then
		self.seen_fall_down_event = true
		get_character('counter_teacher').ActiveState = active_state('disabled')
	end
end

-- 카운터에 앉아있던 선생이 옆으로 쓰러지는 이벤트
function local_class:fall_down_teacher()
	local teacher = get_character('counter_teacher')

	music_player:PlaySfxOneShot('01_ghost_disappear_03')

	teacher:SetEmotion('scared', true)
	character_util.set_anim(teacher, {name = 'sleep', loop = false, scale = 0.2, mix_duration = 0.4})

	character_util.move_to_async(teacher, teacher.Position + unity_class.vector3.right * 0.7, 0.4)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
