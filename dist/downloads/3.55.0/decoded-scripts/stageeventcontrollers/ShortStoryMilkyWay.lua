local local_class = newclass('ShortStoryMilkyWayController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 7001801

	-- exit 정보
	self.time_zone_exit_data = {
		-- 낮
		[false] = {
			{
				fo_name = 'pub_outer_1',
				way_point_name = 'pub_day_outer_1',
			},
			{
				fo_name = 'room_a_outer_1',
				way_point_name = 'room_a_day_outer_1',
			},
			{
				fo_name = 'room_b_outer_1',
				way_point_name = 'room_b_day_outer_1',
			},
			{
				fo_name = 'room_c_outer_1',
				way_point_name = 'room_c_day_outer_1',
			},
		},
		-- 밤
		[true] = {
			{
				fo_name = 'pub_outer_1',
				way_point_name = 'pub_night_outer_1',
			},
			{
				fo_name = 'room_a_outer_1',
				way_point_name = 'room_a_night_outer_1',
			},
			{
				fo_name = 'room_b_outer_1',
				way_point_name = 'room_b_night_outer_1',
			},
			{
				fo_name = 'room_c_outer_1',
				way_point_name = 'room_c_night_outer_1',
			},
		}
	}

	-- 밤 섹션 (4, 6, 9, 10, 13섹션)
	self.night_section_list = { 3, 5, 8, 9, 12 }

	-- 현재 밤으로 세팅되어 있는지 여부
	self.is_night = false

	-- 위치 별 bgm
	self.bgm_names = {
		day = 'ondemand/short_story_milkyway/audio:bgm_milkyway_day',
		night = 'ondemand/short_story_milkyway/audio:bgm_milkyway_night',
		cafe = 'ondemand/short_story_milkyway/audio:bgm_milkyway_cafe'
	}

	self.changing_bgm_name = nil

	self.in_librarian_event = false
	self.in_room_c_field = false

	self.get_bartender = function()
		return get_character('bartender')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent))

	do
		local bartender = self.get_bartender()

		character_util.remove_relate_event(bartender, self)
	end

	self.bgm_names = nil
	self.changing_bgm_name = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		local cur_progress = e.CurrentProgress

		-- 표지판 세팅
		self:set_sign_board_string(cur_progress)

		-- exit 세팅
		local is_cur_section_night = table_util.contain_value(self.night_section_list, cur_progress)

		if self.is_night ~= is_cur_section_night then
			self.is_night = is_cur_section_night
			self:set_time_zone_exit(self.time_zone_exit_data[self.is_night])
		end

		return true
	end

	return false
end

function local_class:on_stage_loaded_event()
	self:set_librarian_ipad()

	do
		local bartender = self.get_bartender()

		character_util.add_listener(bartender, self)
	end

	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_bartender()) then
		speech_bubble_util.remove_bubble(e.Target)

		speech_bubble_util.show_speech_bubble(e.Target, {
			key = e.Target.Interactable.Talk,
			bubble_direction = 'rb',
		})

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.in_room_c_field == false and type_util.is_zone_full_enter(e, get_party_leader(), 'room_c_field') then
		self.in_room_c_field = true
		camera_util.set_position(get_field_object('room_c_outer_1').Position)
		return true
	end

	if self.in_librarian_event == false and type_util.is_zone_full_enter(e, get_party_leader(), 'event_librarian_day_4_day') then
		self.in_librarian_event = true
		camera_util.move_to_target(get_field_object('event_librarian_ipad'), 0.3)
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.in_room_c_field == true and type_util.is_zone_full_leave(e, get_party_leader(), 'room_c_field') then
		self.in_room_c_field = false
		camera_util.move_to_target(get_party_leader(), 0, { end_target = get_party_leader() })
		return true
	end

	if self.in_librarian_event == true and type_util.is_zone_full_leave(e, get_party_leader(), 'event_librarian_day_4_day') then
		self.in_librarian_event = false
		camera_util.move_to_target(get_field_object('room_c_outer_1'), 0.3)
		return true
	end

	return false
end
--endregion

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

function local_class:launch_routine()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 바텐더 HitBox세팅
	get_character('bartender').Hitbox = CS.Oak.Hitbox(vector(1.5, 1, 2.2))

	-- 공연장 표지판 스트링 세팅
	local progress = main_quest_progress == nil and 0 or main_quest_progress.InnerProgress
	self:set_sign_board_string(progress)

	if main_quest_progress ~= nil and not main_quest_progress.IsComplete then
		self.is_night = table_util.contain_value(self.night_section_list, progress)
		self:set_time_zone_exit(self.time_zone_exit_data[self.is_night])
	end

	-- 밤 섹션부터 시작이라면 밤 bgm으로 변경
	if self.is_night then
		music_player_util.set_stage_music_clip_async({ name = self.bgm_names.night, state = 'field' })
	end

	-- 시작 연출 관리
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s1_start_pos'),
				false, false)
	elseif main_quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_start_pos'),
				true, false)
	elseif main_quest_progress.InnerProgress == 4 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s6_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s7_pivot_pos'),
				false, false)
	elseif main_quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s7_pivot_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('night_boat_venue_pivot'),
				true, true)
	elseif main_quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s10_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s10_bar_pos_2'),
				true, true)
	elseif main_quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s11_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 12 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end

	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent), 'on_teleport_party_fadeout_finish_event')
end

function local_class:set_sign_board_string(progress)
	local board_string_key = 'ss_milkyway_concert_hall_sign_board_4'

	if progress <= 3 then
		board_string_key = 'ss_milkyway_concert_hall_sign_board_1'
	elseif progress > 3 and progress <= 5 then
		board_string_key = 'ss_milkyway_concert_hall_sign_board_2'
	elseif progress > 5 and progress <= 8 then
		board_string_key = 'ss_milkyway_concert_hall_sign_board_3'
	else
		board_string_key = 'ss_milkyway_concert_hall_sign_board_4'
	end

	local sign_board_count = 2
	for i = 1, sign_board_count do
		local sign_board = get_field_object('concert_hall_sign_board_' .. i)
		sign_board.Interactable.Message = board_string_key
	end
end

function local_class:set_time_zone_exit(target_exit_data)
	for i = 1, #target_exit_data do
		local exit_data = target_exit_data[i]
		local exit_fo = get_field_object(exit_data.fo_name)

		local open_path_info = CS.Oak.OpenPathInfo()
		open_path_info.OpenWaypoint = exit_data.way_point_name
		exit_fo.Interactable.MoveStage = open_path_info
	end
end

function local_class:set_librarian_ipad()
	--아이패드 : mall_pad 배치
	local ipad_item_id = 21322
	local target_pos = get_field_object('event_librarian_ipad').Position + unity_class.vector3.up * 0.5

	quest_drop_item_util.create_item({
		pos = target_pos,
		item_id = ipad_item_id,
		unique_id = 'event_librarian_ipad',
		loot_state = quest_drop_item_loot_state.dont_find_looter,
	})
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == 'pub_outer_1' then
		self.changing_bgm_name = self.is_night and self.bgm_names.night or self.bgm_names.day
		return true
	elseif e.ExitHandleName == 'pub_night_inner_1' or e.ExitHandleName == 'pub_day_inner_1' then
		self.changing_bgm_name = self.bgm_names.cafe
		return true
	end

	self.changing_bgm_name = nil
	return false
end

function local_class:on_teleport_party_fadeout_finish_event(_)
	if self.changing_bgm_name == nil then
		return false
	end

	if music_player.CurrentStageMusicName == self.changing_bgm_name then
		return false
	end

	start_coroutine(self.change_current_bgm, self)
end

function local_class:change_current_bgm()
	music_player_util.play_stage_music({ state = 'muted' })
	music_player_util.set_stage_music_clip_async({ name = self.changing_bgm_name, state = 'field' })

	music_player_util.play_stage_music({ state = 'field' })
	self.changing_bgm_name = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
