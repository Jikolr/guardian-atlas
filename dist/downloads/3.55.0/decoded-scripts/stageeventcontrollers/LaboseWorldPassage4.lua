local local_class = newclass('LaboseWorldPassage4')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local background_attacher = get_or_create_global_table(
			'Quest/Main/LaboseWorld/Common/OtherSideBackgroundAttacher'
	)

	background_attacher:load_async()
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
