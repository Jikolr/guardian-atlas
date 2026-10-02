local local_class = newclass('CivilWarSubStageDemonShireController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 해당 스테이지의 퀘스트 id
	self.target_sub_quest_id = 371

	-- 퍼즐 그리드 구역 갯수
	self.puzzle_grid_count = 4
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:on_event(_)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'prison_field') then
		-- 수용소 입장 시 카메라 축소
		camera_util.resize_by_ratio(5, 0.5)
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), 'prison_field') then
		-- 수용소 퇴장 시 카메라 원복
		camera_util.resize_to_default(0.5)
		return true
	end

	return false
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.target_sub_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		local prison_door = get_field_object('special_prison_door_1')
		prison_door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		local animator = prison_door:GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('on', -1)

		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress <= 1 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s1_half_vampire_pos_1'),
				false, false)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s3_start_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s1_half_vampire_pos_1'),
				false, false)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
