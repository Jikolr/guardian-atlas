local local_class = newclass('NightmareLilithTower4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- 메인 퀘스트 id
	self.main_quest_id = 380

	-- scene_util 버전
	self.scene_version = scene_util.default_version
end

function local_class:dispose()
	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
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

	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				false, true)
	elseif main_quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
