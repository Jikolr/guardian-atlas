local local_class = newclass('NightmareDemonShire4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 406

	self.field_objects = {
		door = function()
			return get_field_object('s12_door')
		end
	}

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.field_objects = nil
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
end

function local_class:on_interact_event(e)
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'main_field_3') then
		-- 수용소 입장 시 카메라 축소
		camera_util.resize_by_ratio(5, 0.5)
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), 'main_field_3') then
		-- 수용소 퇴장 시 카메라 원복
		camera_util.resize_to_default(0.5)
		return true
	end

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

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)

	elseif quest_progress.InnerProgress == 10 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 11 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start')
		, true, true)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:door_open(fo)
	local fo_anim = fo:GetComponent(typeof(CS.UnityEngine.Animator))
	fo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	fo_anim:Play('on')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
