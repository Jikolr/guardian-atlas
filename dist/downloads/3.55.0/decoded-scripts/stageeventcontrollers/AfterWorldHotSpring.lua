local local_class = newclass("AfterWorldHotSpringController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 온천 탈출이 가능한지 저장하는 플래그
	self.can_get_out_hot_spring = true

	-- 게임을 플레이했는지
	self.is_play_game = true

--region Field Object
	self.hot_spring_outer_gate_num = 2
	self.hot_spring_outer_gate_name = 'hot_spring_outer_gate_'

	self.hot_spring_inner_gate_name = 'hot_spring_inner_gate'

	self.hot_spring_changing_booth_list = nil
	self.hot_spring_changing_booth_num = 6
	self.hot_spring_changing_booth_name = 'hot_spring_changing_booth_'

	self.hot_spring_exit_gate_num = 3
	self.hot_spring_exit_gate_name = 'hot_spring_exit_gate_'
--endregion

	-- 기존 파티 리더
	self.saved_leader = nil

	-- 샤워 타올 기사 이름
	self.knight_male_hot_spring_name = 'knight_male_hot_spring'
	self.knight_female_hot_spring_name = 'knight_female_hot_spring'

	-- 카론 이름
	self.charon_name = 'charon'

	-- 온천 내부 존 이름
	self.hot_spring_event_zone_name = 'hot_spring'

	-- 커스텀 이벤트 이름
	self.changing_clothes_custom_event = 'changing_clothes'
	self.main_quest_hot_spring_finished_custom_event = 'main_quest_hot_spring_finished'
	self.exit_hot_spring_event = 'exit_hot_spring'

	-- 커스텀 스테이트 이름
	self.enter_hot_spring_custom_state = 'enter_hot_spring'

	-- 오브젝트 풀 프리셋
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	self.hot_spring_changing_booth_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.hot_spring_changing_booth_num do
		self.hot_spring_changing_booth_list:Add(get_field_object(self.hot_spring_changing_booth_name..i))
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.saved_leader = nil

	self.hot_spring_changing_booth_list = nil

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- 메인 퀘스트 섹션 4일 경우에는 메인 퀘스트에서 외부 게이트 열어주므로 여기서는 닫는다
	-- 메인 퀘스트 섹션 4 이하일 경우에는 온천 탈출 불가능하게 설정
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	if quest_progress.InnerProgress <= 3 and
			quest_progress:GetCustomState(self.enter_hot_spring_custom_state) == -1 then
		self.can_get_out_hot_spring = false

		for i = 1, self.hot_spring_outer_gate_num do
			message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_outer_gate_name..i, false))
		end
	end

	message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_inner_gate_name, false))

	for i = 1, self.hot_spring_exit_gate_num do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_exit_gate_name..i, false))
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if self.can_get_out_hot_spring and e.Zone.Name == self.hot_spring_event_zone_name then
			sp_util.play_normal_screenplay(self.get_out_hot_spring_event, self)
		end
	end
end

function local_class:on_interact_event(e)
	for i = 0, self.hot_spring_changing_booth_list.Count - 1 do
		if lua_helper.reference_equals(e.Target, self.hot_spring_changing_booth_list[i]) then
			sp_util.play_normal_screenplay(
					self.changing_clothes_event, self, self.hot_spring_changing_booth_list[i])
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == self.main_quest_hot_spring_finished_custom_event then
		self.can_get_out_hot_spring = true
	end
end
--endregion

-- 온천 용 옷으로 갈아 입는 이벤트
function local_class:changing_clothes_event(cur_booth)
	for i = 0, self.hot_spring_changing_booth_list.Count - 1 do
		self.hot_spring_changing_booth_list[i].Interactable = CS.Oak.NonInteractable.Instance
	end

	self.saved_leader = get_party_leader()

	local hot_spring_knight

	if user_util.has_knight_male() then
		hot_spring_knight = get_character(self.knight_male_hot_spring_name)
	else
		hot_spring_knight = get_character(self.knight_female_hot_spring_name)
	end

	character_util.spine_set_alpha_fade(hot_spring_knight, 0, 0)
	character_util.set_active_state(hot_spring_knight, 'enabled')

	camera_util.move(cur_booth.Position, 1)

	party_util.align_party(cur_booth, 'left', 1)

	music_player_util.play_sfx_one_shot('01_curtain_01')

	character_util.spine_set_alpha_fade(get_party_leader(), 0, 1)
	character_util.move_to_async(get_party_leader(),
			get_party_leader().Position + vector(1, 0, 0),
			1, nil, true, true)

	local equip_sfx = music_player_util.play_sfx(
			{ sfx_name = "03_equipping_01", loop = true, type_priority = 'loop' })

	cur_booth:Shake(0.04, 1)

	wait_for_sec(1)

	equip_sfx:FadeOut()

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('01_curtain_01')

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.MoveCamera = false
	param.KeepParty = true

	character_util.convert_to_manual_character(hot_spring_knight, param)

	character_util.set_active_state(self.saved_leader, 'disabled')
	character_util.convert_to_npc(self.saved_leader)

	character_util.set_position(hot_spring_knight, cur_booth.Position)

	coroutine.yield(nil)

	camera_util.move(hot_spring_knight.Position + vector(-1, 0, 0),
			1, { end_target = hot_spring_knight })

	character_util.spine_set_alpha_fade(hot_spring_knight, 1, 1)
	character_util.move_to_async(get_party_leader(),
			get_party_leader().Position + vector(-1, 0, 0),
			1, nil, true, true)

	for i = 1, self.hot_spring_outer_gate_num do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_outer_gate_name..i, true))
	end

	message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.hot_spring_inner_gate_name, true))

	for i = 1, self.hot_spring_exit_gate_num do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.hot_spring_exit_gate_name..i, true))
	end

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { self.changing_clothes_custom_event }))
end

-- 온천 나가는 이벤트
function local_class:get_out_hot_spring_event()
	field_ui_util.show_narration_async({ key = 'afterworld_hot_spring_minigame_2' })

	local choose_result = choose_util.play_choose_event(
			{ { 'afterworld_hot_spring_minigame_3', 'mercy' },
			  { 'afterworld_hot_spring_minigame_4', 'brutal' } })

	if choose_result == 1 then
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		-- 온천 나가고 화면 검은색 된 후 알림 이벤트 생성
		message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, { self.exit_hot_spring_event }))
		coroutine.yield(nil)

		for i = 1, self.hot_spring_outer_gate_num do
			message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.hot_spring_outer_gate_name..i, false))
		end

		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_inner_gate_name, false))

		for i = 1, self.hot_spring_exit_gate_num do
			message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.hot_spring_exit_gate_name..i, false))
		end

		for i = 0, self.hot_spring_changing_booth_list.Count - 1 do
			self.hot_spring_changing_booth_list[i].Interactable = CS.Oak.PublishInteractable.Create()
		end

		local past_leader = get_party_leader()

		if get_party_leader().Position.z > -69.5 then
			character_util.set_position(self.saved_leader, vector(39, 0, -59.5))
		else
			character_util.set_position(self.saved_leader, vector(32, 0, -80.5))
		end

		character_util.set_active_state(self.saved_leader, 'enabled')
		character_util.spine_set_alpha_fade(self.saved_leader, 1, 0)
		character_util.set_direction(self.saved_leader, 'left')

		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		param.KeepParty = true

		character_util.convert_to_manual_character(self.saved_leader, param)

		character_util.convert_to_npc(past_leader)
		character_util.set_active_state(past_leader, 'disabled')
		character_util.set_position(past_leader, vector(999, 0, 999))

		for i = 1, user_party.Count - 1 do
			character_util.set_position(charon, get_party_leader().Position + vector(0.7 * i, 0, 0))
			character_util.set_direction(charon, 'left')
		end

		wait_for_sec(0.5)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')
	else
		character_util.move_to_async(get_party_leader(),
				get_party_leader().Position + vector(2, 0, 0),
				0.67, nil, true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
