local local_class = newclass('MemorialCarpGirlController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 7200107

	self.background_attacher = nil

	self.background_color = {
		default_color = unity_class.color(1, 0, 0, 0),	-- 특정 시점에 배경 프리펩의 투명도 조절해 나타나지 않게 하거나 제거 처리
		red = unity_class.color(1, 0, 0, 0.3)
	}
end

function local_class:dispose()
	self.cs_controller = nil

	if self.background_attacher ~= nil then
		self.background_attacher:dispose()
	end
end

function local_class:load_resource()
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	return false
end

function local_class:on_stage_end_event(_)
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
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	stage_start_util.start_function(quest_progress)
end

function local_class:load_background_attacher(default_red_color)
	default_red_color = lua_helper.get_or_default(default_red_color, true)

	self.background_attacher = get_or_create_global_table(
			'Quest/Main/PixyWorld/Common/BackgroundAttacher'
	)

	self.background_attacher:load_async('Quest/Memorial/CarpGirl/Common/BackgroundAttacherConstants', 3)

	self.renderer = self.background_attacher.background_objects['default']:GetComponentInChildren(typeof(CS.UnityEngine.MeshRenderer))

	self.material = self.renderer.material

	local background_color = nil

	if default_red_color  then
		background_color = self.background_color.red
	else
		background_color = self.background_color.default_color
	end

	self.material.color = background_color
end

function local_class:set_background_color(color)
	self.material.color = color
end

return local_class
