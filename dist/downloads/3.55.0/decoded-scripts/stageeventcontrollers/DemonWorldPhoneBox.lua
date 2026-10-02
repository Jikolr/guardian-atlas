local local_class = newclass('DemonWorldPhoneBoxController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_phone_box = function() return get_field_object('quest_phone_box') end

	self.stage_2_name = 'demonworld_part1_1_2'
	self.stage_3_name = 'demonworld_part1_1_3'

	-- 전화 번호 정보
	self.phone_number_info = {
		-- 라이트닝 카운터 퀘스트
		{
			stage_name = self.stage_2_name,
			number = { 3, 5, 4 },
			custom_key = { 'oni_girl_racing' }
		}
	}

	-- 공중전화 들어갈 때 마지막 파티원 위치
	self.last_party_pos = nil

	self.on_exclusive = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(_)
	return false
end

--- InteractEvent
function local_class:on_interact_event(e)
	-- 공중전화에 상호작용 했을 때
	local phone_box = self.get_phone_box()
	if type_util.is_interacted_target(e, phone_box) then
		if not self.on_exclusive then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.call_with_phone_box, self))
		else
			local phone_box_speech_offset = vector(2.7, 0, 2.3)
			-- 지금은 사용할 때가 아니다.
			speech_bubble_util.show_speech_bubble(phone_box,
				{ key = 'quest_phone_box_4', offset = phone_box_speech_offset })
		end
		return true
	end

	return false
end

--- ExclusiveQuestStartEvent
function local_class:on_exclusive_quest_start_event(_)
	self.on_exclusive = true
	return true
end

--- ExclusiveQuestEndEvent
function local_class:on_exclusive_quest_end_event(_)
	self.on_exclusive = false
	return true
end

--- 전화 박스로 전화를 했을 때 이벤트
function local_class:call_with_phone_box()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local phone_box = self.get_phone_box()
	local leader = user_party.Leader

	local phone_box_center = vector_util.get_x0z(phone_box.Bounds.center)
	party_util.align_party(phone_box_center + vector(0, 0, -0.25), 'down', 1, 'linear')

	local player_choice = choose_util.play_choose_event({
		-- 공중전화를 사용한다.
		{ 'quest_phone_box_1', 'mercy' },
		-- 그만둔다.
		{ 'quest_phone_box_2', 'brutal' }
	})

	-- 그만둔다. 선택
	if player_choice == 2 then
		field_ui_manager:Show()
		party_util.reset_controllers()

		return
	end

	character_util.move_waypoint_async(leader, leader.Position + vector(0, 0, 0.75), 3)

	music_player_util.play_sfx_one_shot('01_interact_greenland_01')
	character_util.spine_deviate_local(leader, vector(0, 0.4, 0.1), 0.3, 0.2)
	character_util.set_animation_n_times_async(leader, { name = 'attack' })

	wait_for_sec(0.75)

	-- 현재 스테이지의 이벤트
	local stage_events = {}
	for i = 1, #self.phone_number_info do
		if self.phone_number_info[i].stage_name == stage.Name then
			table.insert(stage_events, self.phone_number_info[i])
		end
	end

	music_player_util.play_sfx_one_shot('01_phone_receive_02')

	for index = 1, 3 do
		-- 번호 입력 인터페이스
		player_choice = choose_util.play_choose_event({
			{ '0' }, { '1' }, { '2' }, { '3' }, { '4' }, { '5' }
		})

		-- 현재 입력한 번호와 맞지 않는 이벤트
		local remove_event = {}
		for i = 1, #stage_events do
			if stage_events[i].number[index] + 1 ~= player_choice then
				table.insert(remove_event, i)
			end
		end

		-- 번호와 맞지 않는 이벤트 제거
		for i = #remove_event, 1, -1 do
			table.remove(stage_events, remove_event[i])
		end
	end


	-- 이벤트 번호와 하나도 맞지 않을 때
	if #stage_events == 0 then
		music_player_util.play_sfx_one_shot('01_phone_call_fail_01')
		-- 응답이 없다. 결번인 모양이다.
		field_ui_util.show_narration_async({ key = 'quest_phone_box_3', mintotalduration = 1 })

		music_player_util.play_sfx_one_shot('01_phone_call_fail_01')
		character_util.move_to_async(leader, leader.Position + vector(0, 0, -0.75),
			1, nil, false, true)

		field_ui_manager:Show()
		party_util.reset_controllers()
		return
	end

	-- 맞는 번호의 Custom Key 발송
	message_system:Publish(CS.Oak.CustomStageEvent.Create(phone_box, stage_events[1].custom_key))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
