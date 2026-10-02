local local_class = newclass('CivilWarSubStageHeavenholdController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.cw_util = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	self.cw_util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()

	self.cw_util:activate_control_directional_light(
			{
				main_field = '[gimmick]directional_light_saul',
				saul_lab = '[gimmick]directional_light_saul',
				lilithtawer = 'directional_light_1',
			}
	)

	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	--message_system:Publish(CS.Oak.StageStartEvent.Instance)
	--message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
