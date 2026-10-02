local local_class = newclass('ShuranGimmickUIController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.res_holder = nil

	self.ui_prefab = nil
	self.gimmick_ui = nil
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
			self.res_holder, 'ondemand/short_story_shuran/ui', 'ShuranGimmickUI', function(prefab)
				self.ui_prefab = CS.NGUITools.AddChild(CS.Oak.Stage.Instance.UIRoot.gameObject, prefab)
				self.gimmick_ui = self.ui_prefab:GetComponent(typeof(CS.Oak.UI.ShuranGimmickUI)).GetControllerLuaTable
			end)

	self.gimmick_ui:init_ui()
end

--- launch�� �� ��Ʈ�ѷ����� ��Ʈ�� �� ���ΰ�. true�� �����ϸ� ��Ʈ�� ����
function local_class:need_on_launch()
	return false
end

--- need_on_lunch�� true�� ��� �̸��� ����
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:on_field_ui_show_event(e)
	self.gimmick_ui:set_active(true)
end

function local_class:on_field_ui_hide_event(e)
	self.gimmick_ui:set_active(false)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'ui_on' then
		self.gimmick_ui:on_gimmick_ui(e:GetParamAt(1))
	elseif e:GetParamAt(0) == 'change_ui' then
		self.gimmick_ui:on_result_ui(e:GetParamAt(1))
	elseif e:GetParamAt(0) == 'ui_off' then
		self.gimmick_ui:end_ui()
	end

	return false
end

function local_class:dispose()
	self.cs_controller = nil

	self.res_holder = nil
	self.gimmick_ui = nil

	if self.ui_prefab ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.ui_prefab)
		self.ui_prefab = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
