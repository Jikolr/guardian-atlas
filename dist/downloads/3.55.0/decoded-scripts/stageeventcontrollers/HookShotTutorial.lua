local local_class = newclass("HookShotTutorialController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	local wall_name = 'hook_shot_wall'
	local wall = get_field_object(wall_name)

	-- null checking
	if wall == nil then
		return
	end

	-- 훅샷을 제대로 사용할 수 있도록 cliff 속성을 넣어줌
	wall.EntityGroup = wall.EntityGroup | CS.Oak.EntityGroups.Cliff
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
