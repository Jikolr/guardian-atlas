local local_class = newclass('NightmareQueenShip2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 435
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

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
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	-- 퍼즐용 테슬라 코일 컨디션 갱신
	message_system:Publish(CS.Oak.SwitchOnOffEvent.Create(get_field_object('puzzle_bomber_switch_1'), false, nil))
	message_system:Publish(CS.Oak.SwitchOnOffEvent.Create(get_field_object('puzzle_bomber_switch_2'), false, nil))

	return true
end
--endregion event

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
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	local core_box = get_field_object('core_box')

	if self.quest_progress ~= nil then
		if self.quest_progress.InnerProgress > 5 or self.quest_progress.IsComplete then
			local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')
			local common_keys = custom_keys.common

			-- 엘리베이터 코어 키 == 1
			local elevator_core_key = common_keys.core_count

			-- 엘리베이터 코어를 얻었는지
			local elevator_core_count = 1

			if stage_progress_util.get_custom_data_int(elevator_core_key, 0) == 0 then
				-- 프로그래스 5 초과면 엘리베이터 코어 얻은 것으로 처리
				stage_progress_util.set_custom_data_async(elevator_core_key, elevator_core_count)

				--상자 열림 애니메이션 재생
				local core_box_animator = core_box:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

				core_box_animator:Play('open1', -1, 1)

				-- UI 갱신 하도록 이벤트 보냄
				message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'refresh_resource_ui' }))
			end
		end
	end

	-- 시작 연출
	if self.quest_progress == nil or self.quest_progress.IsComplete then
		core_box.Interactable = CS.Oak.NonInteractable.Instance
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('exit_door'))

		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), false, false)
	elseif self.quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif self.quest_progress.InnerProgress == 6 then
		core_box.Interactable = CS.Oak.NonInteractable.Instance

		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	else
		core_box.Interactable = CS.Oak.NonInteractable.Instance
		message_system:Publish(CS.Oak.DoorOpenEvent.Create('exit_door'))

		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
