local local_class = newclass("LilithTowerElevatorController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 대사
	self.main_script = 'lilith_tower_elevator_'

	-- 스테이지 이름
	self.stage_name = 'lilithtower_1_3'

	-- 엘리베이터 Exit
	self.elevator_exit_in_list = nil
	self.elevator_exit_in_name = 'exit_elevator_in_'
	self.elevator_exit_in_num = 3

	self.elevator_exit_in_interactable_list = nil

	self.elevator_exit_out = nil
	self.elevator_exit_out_name = 'exit_elevator_out'

	-- 엘리베이터 버튼
	self.elevator_button = nil
	self.elevator_button_name = 'elevator_button'

	-- 메인 퀘스트 상태를 체크해서 얻은 엘리베이터 작동 여부
	self.elevator_on = false

	self.main_quest_id = 258
	self.elevator_on_main_quest_progress = 9

	-- 엘리베이터 층 수
	self.current_floor = 1

	-- 엘리베이터 출구 마커 이름
	self.elevator_exit_marker_name = 'exit_elevator_out_'

	-- 존 이름
	self.elevator_room_zone_name = 'elevator_room'
	self.first_floor_zone_name = 'first_floor'
	self.second_floor_zone_name = 'second_floor_outer'
	self.third_floor_zone_name = 'third_floor'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	-- 메인 퀘스트에서 엘리베이터 상태 체크
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress.InnerProgress >= self.elevator_on_main_quest_progress then
		self.elevator_on = true
	else
		self.elevator_exit_in_list = create_generic_list(CS.Oak.FieldObject)
		self.elevator_exit_in_interactable_list = create_generic_list(CS.Oak.IInteractable)

		for i = 1, self.elevator_exit_in_num do
			local cur_exit = get_field_object(self.elevator_exit_in_name..i)

			self.elevator_exit_in_interactable_list:Add(cur_exit.Interactable)
			cur_exit.Interactable = CS.Oak.PublishInteractable.Create()

			self.elevator_exit_in_list:Add(cur_exit)
		end
	end

	self.elevator_exit_out = get_field_object(self.elevator_exit_out_name)
	self.elevator_button = get_field_object(self.elevator_button_name)
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return end
	if not e.FullEnter then return end
	local zone_name = e.Zone.Name

	if zone_name == self.first_floor_zone_name then
		self.current_floor = 1
	elseif zone_name == self.second_floor_zone_name then
		self.current_floor = 2
	elseif zone_name == self.third_floor_zone_name then
		self.current_floor = 3
	elseif zone_name == self.elevator_room_zone_name then
		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_22_lilithtower/audio:bgm_lilith_pre_02', state = 'event' })

		music_player_util.play_sfx_one_shot('01_elevator_02')
	end
end

function local_class:on_interact_event(e)
	if not self.elevator_on then
		for i = 0, self.elevator_exit_in_list.Count - 1 do
			if lua_helper.reference_equals(e.Target, self.elevator_exit_in_list[i]) then
				sp_util.play_normal_screenplay(self.cannot_use_elevator_event, self)

				break
			end
		end
	else
		if lua_helper.reference_equals(e.Target, self.elevator_button) then
			sp_util.play_normal_screenplay(self.elevator_button_event, self)
		elseif lua_helper.reference_equals(e.Target, self.elevator_exit_out) then
			sp_util.play_normal_screenplay(self.go_out_elevator_event, self)
		end
	end
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id and e.CurrentProgress == self.elevator_on_main_quest_progress then
		self.elevator_on = true

		for i = 0, self.elevator_exit_in_list.Count - 1 do
			self.elevator_exit_in_list[i].Interactable = self.elevator_exit_in_interactable_list[i]
		end
	end
end

function local_class:on_exclusive_quest_start_event(e)
	if not self.elevator_on then
		for i = 0, self.elevator_exit_in_list.Count - 1 do
			self.elevator_exit_in_list[i].Interactable = CS.Oak.NonInteractable.Instance
		end
	end
end

function local_class:on_exclusive_quest_end_event(e)
	if not self.elevator_on then
		for i = 0, self.elevator_exit_in_list.Count - 1 do
			self.elevator_exit_in_list[i].Interactable = CS.Oak.PublishInteractable.Create()
		end
	end
end

-- 전원이 꺼져서 엘리베이터가 사용 불가하다는 메시지 출력하는 이벤트
function local_class:cannot_use_elevator_event()
	field_ui_util.show_narration_async({ key = self.main_script..1 })

	coroutine.yield(nil)
end

-- 엘리베이터 버튼 누르는 이벤트
function local_class:elevator_button_event()
	music_player_util.play_sfx_one_shot('01_elevator_01')

	party_util.align_party(self.elevator_button, 'down', 1)

	field_ui_util.show_narration_async({ key = self.main_script..2 })

	local choose_result = choose_util.play_choose_event(
			{ { self.main_script..3, 'normal' }, { self.main_script..4, 'normal' },
			  { self.main_script..5, 'normal' } })

	if choose_result ~= self.current_floor then
		self.current_floor = choose_result

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_elevator, self))
	else
		field_ui_util.show_narration_async({ key = self.main_script..6 })

		coroutine.yield(nil)
	end
end

-- 엘리베이터 다른 층으로 이동 시에 흔들리는 이벤트
function local_class:move_elevator()
	music_player_util.play_sfx_one_shot('01_elevator_05')

	local shake_sfx = music_player_util.play_sfx({ sfx_name = '01_elevator_03', loop = true,
	                                               type_priority = 'event', player_priority = 'npc' })

	local saved_interactable = self.elevator_exit_out.Interactable
	self.elevator_exit_out.Interactable = CS.Oak.NonInteractable.Instance

	camera_util.shake(0.03, 2)

	wait_for_sec(2)

	shake_sfx:FadeOut()

	music_player_util.play_sfx_one_shot('01_broadcast_02')

	self.elevator_exit_out.Interactable = saved_interactable

	camera_util.shake(0.12, 0.5)

	wait_for_sec(0.5)
end

-- 엘리베이터 나오는 이벤트
function local_class:go_out_elevator_event()
	music_player_util.play_sfx_one_shot('01_elevator_02')

	screen_util.fade_out_circular_async(0.6, 'linear')

	local cur_marker = field:GetMarker(self.elevator_exit_marker_name..self.current_floor)

	party_util.align_party(cur_marker.position,
			CS.Oak.DirectionExtensions.GetOpposite(cur_marker.direction), 0, 'linear')

	wait_for_sec(0.5)

	music_player_util.play_stage_music({ state = 'field' })

	screen_util.fade_in_circular_async(0.6, 'linear')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	self.elevator_exit_in_list = nil
	self.elevator_exit_in_interactable_list = nil

	self.elevator_exit_out = nil

	self.elevator_button = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}