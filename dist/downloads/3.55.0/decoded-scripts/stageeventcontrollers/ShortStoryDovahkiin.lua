local local_class = newclass('ShortStoryDovahkiin')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 7000601

	self.get_neva = function() return get_character('neva') end

	--region 하수구 길 찾기
	self.sewer_event_state = {
		none = 0,
		in_sewer = 1,
		returning = 2,	-- 컨트롤 뺏고 아래로 내리는 부분
		done = 3,
	}
	self.current_sewer_event_state = self.sewer_event_state.none

	self.sewer_info = {
		max_z = 999,	-- 위쪽 리셋 포인트(컨트롤 뺏고 이 길이 아닌것 같아 하는 부분)
		left_max_x = -999,	-- 3개 통로 판정 지점
		right_min_x = 999,
		bounds = nil,
		passage_width = 0,
		area_state = {
			left = 0,
			center = 1,
			right = 2,
		},
		is_entered_correct_first = false,
		area_enter_callback = function(info)
			if info.current_area == info.area_state.center then
				character_util.remove_emotion(user_party.Leader)
			elseif info:in_correct_area() then	-- 맞는 구역일 때
				music_player_util.play_sfx_one_shot('01_gatcha_point_01')
				character_util.remove_emotion(user_party.Leader)
				character_util.set_emotion(user_party.Leader, {name = 'greed'})
			else	-- 틀렸을 때
				character_util.remove_emotion(user_party.Leader)
				character_util.set_emotion(user_party.Leader, {name = 'scared'})
			end
		end,
		current_area = 1,
		current_index = 1,
		route_info = {
			{
				area = 0,
				color = unity_color({0.2, 0.2, 0.2, 1}),
				talk_key = 'shortstory_dragon_main_s4_8'
			},
			{
				area = 2,
				color = unity_color({0.4, 0.4, 0.4, 1}),
				talk_key = 'shortstory_dragon_main_s4_8_1'
			},
			{
				area = 0,
				color = unity_color({0.5, 0.5, 0.5, 1}),
				talk_key = 'shortstory_dragon_main_s4_8_2'
			},
			{
				area = 0,
				color = unity_color({0.6, 0.6, 0.6, 1}),
				talk_key = 'shortstory_dragon_main_s4_8_3'
			},
		},
		get_current_route_info = function(info)
			return info.route_info[info.current_index]
		end,
		in_correct_area = function(info)
			return info:get_current_route_info().area == info.current_area
		end,
	}

	self.sewer_tint_key = nil
	--endregion

	--region 창고 박스 기믹
	self.get_warehouse_box = function(num) return get_field_object('warehouse_box_' .. num) end

	self.get_fx_dead = function() return unity_object_pool.GetOrCreate('FX_dead') end

	self.box_infos = {}

	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.get_fx_dead()
end

function local_class:need_on_launch()
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	-- 섹션의 Start는 다음 프레임에서 불림. 리더 교체 이후 불리게 됨
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_stage_loaded(_)
	local sewer_zone = field:GetZone('sewer_room')
	self.sewer_info.bounds = sewer_zone.Bounds
	self.sewer_info.max_z = self.sewer_info.bounds.max.z + 4
	self.sewer_info.passage_width = self.sewer_info.bounds.size.x / 3
	self.sewer_info.left_max_x = self.sewer_info.bounds.min.x + self.sewer_info.passage_width
	self.sewer_info.right_min_x = self.sewer_info.bounds.max.x - self.sewer_info.passage_width

	local train_name = {
		'train_1',
		'train_2',
		'chasing_train',
		'event_train'
	}

	-- 열차 그림자 제거
	for i = 1, #train_name do
		local train = get_character(train_name[i])
		character_util.set_active_shadow(train, false)
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'main_section_2' then
		if e:GetParamAt(1) == 'reset_warehouse_obj' then
			self:reset_warehouse_box()
			return true
		end

	elseif e:GetParamAt(0) == 'main_section_4' then
		if e:GetParamAt(1) == 'enter_sewer' then
			field:Tint(self.sewer_tint_key, self.sewer_info:get_current_route_info().color, 0)
			return true

		elseif e:GetParamAt(1) == 'start_sewer_game' then
			self.current_sewer_event_state = self.sewer_event_state.in_sewer
			return true

		elseif e:GetParamAt(1) == 'need_renew_emotion' then
			self.sewer_info:area_enter_callback()
			return true

		elseif e:GetParamAt(1) == 'remove_tint' then
			field:RemoveTint(self.sewer_tint_key, 1)
			return true
		end

	elseif e.Sender ~= nil and self.box_infos[e.Sender] ~= nil then
		local info = self.box_infos[e.Sender]
		self:open_warehouse_box(e.Sender, info)
		return true
	end

	return false
end

function local_class:use_late_update_frame()
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	return self.main_quest_progress == nil or (self.main_quest_progress.InnerProgress < 4
			and not self.main_quest_progress.IsComplete)
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

-- 플레이어 이동 후 추가 처리가 필요해서 LateUpdate 사용
function local_class:late_update_frame(dt)
	if self.current_sewer_event_state ~= self.sewer_event_state.in_sewer then
		return
	end

	local leader_pos = user_party.Leader.transform.position
	local target_leader_pos = leader_pos
	local need_return = false
	local need_exit = false

	-- 루프
	if target_leader_pos.x < self.sewer_info.bounds.min.x then
		target_leader_pos = target_leader_pos + vector(self.sewer_info.bounds.size.x, 0, 0)
	elseif target_leader_pos.x > self.sewer_info.bounds.max.x then
		target_leader_pos = target_leader_pos + vector(-self.sewer_info.bounds.size.x, 0, 0)
	end

	local prev_area = self.sewer_info.current_area
	if target_leader_pos.x < self.sewer_info.left_max_x then
		self.sewer_info.current_area = self.sewer_info.area_state.left
	elseif target_leader_pos.x > self.sewer_info.right_min_x then
		self.sewer_info.current_area = self.sewer_info.area_state.right
	else
		self.sewer_info.current_area = self.sewer_info.area_state.center
	end

	-- 다음 구역으로 들어가려 할 때
	if target_leader_pos.z < self.sewer_info.bounds.min.z then
		-- 정답일 때
		if self.sewer_info:in_correct_area() then
			local reset_x_dif = self.sewer_info.current_area == self.sewer_info.area_state.left
					and self.sewer_info.passage_width or -self.sewer_info.passage_width
			target_leader_pos = target_leader_pos
					+ vector(reset_x_dif, 0, self.sewer_info.bounds.size.z)

			self.sewer_info.current_index = self.sewer_info.current_index + 1
			self.sewer_info.current_area = self.sewer_info.area_state.center
			need_exit = self.sewer_info.current_index > #self.sewer_info.route_info

			if not need_exit then
				local current_info = self.sewer_info:get_current_route_info()
				field:Tint(self.sewer_tint_key, current_info.color, 1)
				speech_bubble_util.remove_bubble(user_party.Leader)
				speech_bubble_util.show_speech_bubble(user_party.Leader, current_info.talk_key)
			end

		else
			target_leader_pos = target_leader_pos + vector(0, 0, self.sewer_info.bounds.size.z)
		end

	elseif target_leader_pos.z > self.sewer_info.max_z
			and self.current_sewer_event_state == self.sewer_event_state.in_sewer then	-- 컨트롤 뺏고 두칸 내려가야 함
		need_return = true
	end

	-- 리더 포지션이 바뀌었을 때만 갱신해 줌
	if leader_pos ~= target_leader_pos then
		user_party.Leader.Position = target_leader_pos
	end

	if need_exit then
		self.current_sewer_event_state = self.sewer_event_state.done
		-- 포지션 다시 원위치
		user_party.Leader.Position = leader_pos
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(user_party.Leader, {'main_section_4', 'sewer_game_over'}))
	elseif need_return then
		self.current_sewer_event_state = self.sewer_event_state.returning
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.say_wrong_way, self))
	elseif prev_area ~= self.sewer_info.current_area then
		-- 구역 변경됐으면 표정 세팅
		-- 다음 프레임에 표정 변경하도록
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader,
				{ 'main_section_4', 'need_renew_emotion' }))
		if self.sewer_info:in_correct_area() and self.sewer_info.is_entered_correct_first == false then
			self.sewer_info.is_entered_correct_first = true
			speech_bubble_util.show_speech_bubble(user_party.Leader, 'shortstory_dragon_main_s4_8')
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:opening_routine()
	local neva = self.get_neva()
	local start_pos = field:GetMarker('pre_start').position
	local section_2_pos = field:GetMarker('train_1_2').position + vector(0, 0, -3)
	local section_3_pos = field:GetMarker('retreat_restaurant_train').position
	local section_4_pos = field:GetMarker('restaurant_back_exit').position
	local factory_pos = field:GetMarker('factory_start_pos').position
	local section_6_pos = vector(97, 0, 108.5)
	local ending_pos = vector(137,0,110.5)

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	character_util.convert_to_manual_character(neva, param)

	neva.Position = start_pos

	if self.main_quest_progress ~= nil and self.main_quest_progress.IsComplete then
		neva.Position = start_pos
		neva.Direction = CS.Oak.Direction.Right

		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'linear')
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(neva.Position,
				neva.Direction, game_string:GetString(stage.Name)))
		return
	end

	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress == 0 then
		neva.Position = start_pos
		return

	elseif self.main_quest_progress.InnerProgress == 1 then
		neva.Position = section_2_pos
		neva.Direction = CS.Oak.Direction.Left

	elseif self.main_quest_progress.InnerProgress == 2 then
		neva.Position = section_3_pos
		neva.Direction = CS.Oak.Direction.Right

	elseif self.main_quest_progress.InnerProgress == 3 then
		neva.Position = section_4_pos
		neva.Direction = CS.Oak.Direction.Right

	elseif self.main_quest_progress.InnerProgress == 4 then
		neva.Position = factory_pos
		neva.Direction = CS.Oak.Direction.Right

	elseif self.main_quest_progress.InnerProgress == 5 then
		neva.Position = section_6_pos
		neva.Direction = CS.Oak.Direction.Left

	elseif self.main_quest_progress.InnerProgress == 6 then
		neva.Position = ending_pos
		return
	end

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')
	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(neva.Position,
			neva.Direction, game_string:GetString(stage.Name)))
end

function local_class:say_wrong_way()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	character_util.remove_emotion(user_party.Leader)

	--네바 정지 후 짧은 대화 이벤트 진행
	--네바 (up, jump) : 아냐, 냄새는 아래쪽에서 나고 있어!
	character_util.normal_jump_async(user_party.Leader, '01_player_jump_01')
	-- 정답 구역 최초 진입 시 출력되던 말풍선이 켜져있을 수 있음
	speech_bubble_util.remove_bubble(user_party.Leader)
	speech_bubble_util.show_speech_bubble_async(user_party.Leader,
			{key = 'shortstory_dragon_main_s4_7', skip = true})

	wp_util.move_way_points_async(user_party.Leader,
			{waypoints = vector(user_party.Leader.Position.x, 0, self.sewer_info.max_z - 2), speed = 3})

	self.sewer_info:area_enter_callback()	-- 표정 다시 세팅함
	self.current_sewer_event_state = self.sewer_event_state.in_sewer

	party_util.reset_controllers()
	field_ui_manager:Show()
	stage.FieldUIMiniMap:Hide()
	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Hide()
	end
end

function local_class:open_warehouse_box(box_fo, info)
	info.opened = true
	info.inner_fo.Position = box_fo.Position
	info.inner_fo.ActiveState = active_state('enabled')

	self.get_fx_dead():Instantiate(box_fo.Position)
	box_fo.ActiveState = active_state('disabled')
end

function local_class:reset_warehouse_box()
	for box, info in pairs(self.box_infos) do
		if info.opened then
			info.inner_fo.Position = box.Position
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
