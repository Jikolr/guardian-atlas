local local_class = newclass('CivilWarGimmickTableUIController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.res_holder = nil

	self.ui_prefab = nil
	self.table_ui = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.WindPotCraftStartEvent), 'on_wind_pot_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.WindPotCraftResultEvent), 'on_wind_pot_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_75_civilwar/ui', 'CivilWarGimmickTableUI', function(prefab)
				self.ui_prefab = CS.NGUITools.AddChild(CS.Oak.Stage.Instance.UIRoot.gameObject, prefab)
				self.table_ui = self.ui_prefab:GetComponent(typeof(CS.Oak.UI.CivilWarGimmickTableUI)).GetControllerLuaTable
			end)

	self.table_ui:init_table_ui()
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

function local_class:on_field_ui_show_event(e)
	self.table_ui:set_active(true)
end

function local_class:on_field_ui_hide_event(e)
	self.table_ui:set_active(false)
end

function local_class:on_wind_pot_start_event(e)
	self.table_ui:start_ui(e.IngredientType)
end

function local_class:on_wind_pot_end_event(e)
	self.table_ui:end_ui()
end

function local_class:dispose()
	self.cs_controller = nil

	self.res_holder = nil
	self.table_ui = nil

	if self.ui_prefab ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.ui_prefab)
		self.ui_prefab = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.WindPotCraftStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WindPotCraftResultEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
