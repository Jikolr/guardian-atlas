local local_class = newclass('FireWorld2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 478
	self.quest_progress = nil
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:load_resource()
	--local is_create, place_controller =
	--global_table_util.try_create('Quest/Etc/CharacterPlaceController/CharacterPlaceController')
	--
	--place_controller:initialize()
end

function local_class:on_event(e)
	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	stage_start_util.start_function(self.quest_progress)
end

return local_class
