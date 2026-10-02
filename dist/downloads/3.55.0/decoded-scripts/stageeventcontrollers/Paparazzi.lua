local local_class = newclass('PaparazziController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}