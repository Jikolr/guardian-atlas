local local_class = newclass('ShortStoryMermaidController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 7001501
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	get_or_create_global_table('utils/Shear/ShearManager')

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
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end
--endregion

function local_class:launch_routine()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출 관리
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	elseif main_quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	elseif main_quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s4_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s5_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('center'),
				false, true)
	elseif main_quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('center'),
				true, true)
	elseif main_quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s8_start_pos'),
				true, true)
	elseif main_quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s9_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	end
end

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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
