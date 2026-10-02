local local_class = newclass("DefaultStoryHell")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
end

function local_class:launch_routine(start_point_name)
	start_point_name = lua_helper.get_or_default(start_point_name, 'default_start')
	stage_launch_util.default_launch_with_marker_name(start_point_name, false)
end

function local_class:dispose()
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
