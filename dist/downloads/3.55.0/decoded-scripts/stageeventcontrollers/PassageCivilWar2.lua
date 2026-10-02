local local_class = newclass('PassageCivilWar2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.galaxy_lab_zone_name = 'in_galaxy_lab'

	self.in_galaxy_lab = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
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
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

-- 특정 카메라 그리드에 들어왔을 시 사이즈 조절
function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 'puzzle2') then
		camera_util.resize_by_ratio(5, 0.3)
	end
end

-- 카메라 그리드 나갔을 시, 사이즈 원복
function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'puzzle2') then
		camera_util.resize_to_default(0.3)
	end
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if not self.in_galaxy_lab and type_util.is_zone_full_enter(e, get_party_leader(), self.galaxy_lab_zone_name) then
		self.in_galaxy_lab = true

		music_player_util.play_stage_music({
			name = 'ondemand/v2_75_civilwar/audio:bgm_civilwar_lab',
			state = 'event'
		})

		return true
	end

	return false
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)
	if self.in_galaxy_lab and type_util.is_zone_full_leave(e, get_party_leader(), self.galaxy_lab_zone_name) then
		self.in_galaxy_lab = false

		music_player_util.play_stage_music({
			name = 'ondemand/v2_75_civilwar/audio:bgm_civilwar_saul_01',
			state = 'field'
		})

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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
