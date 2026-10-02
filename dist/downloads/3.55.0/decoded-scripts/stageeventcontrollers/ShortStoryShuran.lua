local local_class = newclass('ShortStoryShuranController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 말풍선 방향 고정으로 하기 위해 interactable 변경 하기 위해 캐싱
	self.get_custom_sign_board = function() return get_field_object('pharmacy_sign_board_2') end

	self.main_quest_id = 7001601

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, typeof(CS.Oak.InteractEvent)) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local sign_board = self.get_custom_sign_board()

	if lua_helper.reference_equals(e.Target, sign_board) then
		speech_bubble_util.show_speech_bubble(sign_board, { key = 'short_story_sr_s2_interact_2'
		, skip = false, bubble_direction = 'rt' })
	end
end

function local_class:on_exit_interact_teleport_start_event(e)
	local exit_handle_name = e.ExitHandleName

	if exit_handle_name == 'exit_lion_cave_out' then
		music_player_util.play_stage_music({ state = 'field', mix = 2 })
		return true
	elseif exit_handle_name == 'lion_cave_entrance' then
		music_player_util.play_stage_music({ name = 'bgm_china_night', state = 'event', mix = 2 })
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
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s1_shuran_pos_1')
		, false, false)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_shuran_pos_1')
		, true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_shuran_pos_1')
		, false, false)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s4_start')
		, false, false)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s5_start')
		, true, true)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s6_start')
		, true, true)
	elseif quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s7_start')
		, true, true)
	elseif quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s8_magic_circle_pos')
		, false, false)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s9_shuran_pos_1')
		, false, false)
	elseif quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s10_shuran_pos')
		, false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end

	-- 루아에서 제어하기 위해 PublishInteractable 로 변경
	local sign_board = self.get_custom_sign_board()
	sign_board.Interactable = CS.Oak.PublishInteractable.Create()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
