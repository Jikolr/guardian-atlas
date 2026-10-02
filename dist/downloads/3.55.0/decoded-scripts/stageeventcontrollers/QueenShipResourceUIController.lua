local local_class = newclass('QueenShipResourceUIController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.res_holder = nil

	self.resource_ui = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_49_queenship/ui', 'QueenShipInGameResourceUI', function(prefab)
				local ui_prefab = CS.NGUITools.AddChild(CS.Oak.Stage.Instance.UIRoot.gameObject, prefab)
				self.resource_ui = ui_prefab:GetComponent(typeof(CS.Oak.UI.QueenShipInGameResourceUI)).GetControllerLuaTable
			end)

	self.resource_ui:init_resource_ui()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'refresh_resource_ui' then
		self:refresh_ui()
	elseif e:GetParamAt(0) == 'resource_ui_show' then
		self.resource_ui:set_active(true)
	elseif e:GetParamAt(0) == 'resource_ui_off' then
		self.resource_ui:set_active(false)
	end

	return false
end

function local_class:on_field_ui_show_event(e)
	self.resource_ui:set_active(true)
end

function local_class:on_field_ui_hide_event(e)
	self.resource_ui:set_active(false)
end

function local_class:refresh_ui()
	self.resource_ui:refresh_resource_ui()
end

function local_class:dispose()
	self.cs_controller = nil

	self.res_holder = nil
	self.resource_ui = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
