local local_class = newclass('LightGimmickController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:load_resource()
	self.light_gimmick_manager = get_or_create_global_table('Gimmick/LightGimmickManager')
	self.light_gimmick_manager:load_resource()
end

function local_class:on_event(e)
	return false
end

return local_class
