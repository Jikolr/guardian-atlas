local local_class = newclass('QueenCastle4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.mural = get_or_create_global_table('Quest/Main/QueenCastle/Common/MuralTheatreController')

	self.mural:load_async()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)
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

function local_class:pre_setting()
	do
		local qc_util = get_or_create_global_table('Quest/Main/QueenCastle/Common/Util')
		qc_util:set_sector_directional_light(2)
	end

	local quest_progress = user_progress:GetStartedQuest(338)

	if quest_progress == nil then
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	elseif quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field:GetMarker('ending_start').position, true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	elseif quest_progress.InnerProgress == 1 then
		field_ui_manager:SetUI(get_party_leader(), CS.Oak.FieldUiType.TimerBar)
		field_ui_manager:RemoveUI(get_party_leader(), CS.Oak.FieldUiType.TimerBar)
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('center_start').position, true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('center_start').position, true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('center_start').position, true, true)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('center_start').position, true, true)
	elseif quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('ending_start').position, true, true)
	else
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
