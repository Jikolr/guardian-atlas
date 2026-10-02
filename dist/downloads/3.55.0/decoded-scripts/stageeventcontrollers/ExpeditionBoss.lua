local local_class = newclass("ExpeditionBossController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	-- 해당 컨트롤러에 필요한 데이터 셋 불러오기.
	self.expedition_boss_data = require('stageeventcontrollers/ExpeditionBossData.lua')
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_event')


	-- FIX: 길드 점령전 보스전 프레임 AI 이슈로 60프레임 제한
	local frame_rate = CS.UnityEngine.Application.targetFrameRate
	if frame_rate > 60 then
		CS.UnityEngine.Application.targetFrameRate = 60
	end
	return util.cs_generator(self.on_load_resource_routine, self)
end

-- 중간에 옵션창에서 프레임 바꿨을 경우 처리를 위해 updateFrame 추가
function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	-- 프레임 레이트 60 초과로 설정 됐을 경우 다시 강제로 60으로 낮춤
	local frame_rate = CS.UnityEngine.Application.targetFrameRate
	if frame_rate > 60 then
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	if self.expedition_add_on and self.expedition_add_on.late_update_frame then
		self.expedition_add_on:late_update_frame(dt)
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageEndEvent) then
		self:on_stage_end_event(e)
	elseif event_type == typeof(CS.Oak.GlobalTimerAlarmEvent) then
		self:on_global_timer_alarm_event(e)
	end
	return true
end

-- 끝났을 때 처리할 이벤트
function local_class:on_stage_end_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.stage_end_routine, self))
end

-- 타이머 종료시 생성되있는 모든 프로젝타일을 청소한다.
function local_class:on_global_timer_alarm_event(e)
	if e.TimerId == CS.Oak.GlobalTimerId.SingleGameTimer and e.IsComplete then
		stage.ProjectileManager:ClearProjectiles()
	end
end

function local_class:stage_end_routine()
	-- addon에도 종료시 처리하도록
	if self.expedition_add_on then
		self.expedition_add_on:on_stage_end()
	end
end

function local_class:on_load_resource_routine()
	-- 현재 스테이지의 전용 연출이 있으면 추가
	local current_info = self.expedition_boss_data[stage.Spec.Id]
	if current_info and current_info.controller then
		self.expedition_add_on = CS.Oak.StageLuaScript.Create('stageeventcontrollers/ExpeditionAddon/' .. current_info.controller)
		self.expedition_add_on:on_load_resource_routine(current_info.param_table)
	end
	return
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	-- 초반부터 캐릭터 돌아다닐수 있음.
	user_party:ResetControllers()

	-- FadeIn 전 연출 준비
	if self.expedition_add_on then
		self.expedition_add_on:pre_launch_routine()
	end

	CS.Oak.FadeScreenTransition.Instance:FadeIn(0, CS.Oak.Interpolations.EaseInOutSine)
	CS.Oak.CircularScreenTransition.Instance:FadeIn(1, CS.Oak.Interpolations.EaseInOutSine)

	-- 카메라 페이드 대기
	wait_for_sec(1)

	-- 보스 등장 연출 시작
	if self.expedition_add_on then
		self.expedition_add_on:on_launch_routine()
	end

	-- 보스 등장 연출 종료
	if self.expedition_add_on then
		self.expedition_add_on:post_launch_routine()
	end

	--music_player:PlayStageMusic(CS.Oak.StageBgmState.Combat)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	-- FIX: 프레임 복구 - 도중에 옵션창에서 변경 된 경우 등에 대비해 설정값 읽어서 되돌림
	-- Low = 1, Mid, High
	local frame_option = CS.UnityEngine.PlayerPrefs.GetInt('FrameRateOption', 2)
	if frame_option == 1 then
		CS.UnityEngine.Application.targetFrameRate = 30
	elseif frame_option == 3 then
		CS.UnityEngine.Application.targetFrameRate = CS.Oak.UI.OptionsFrameRate.MaximumFps
	else
		CS.UnityEngine.Application.targetFrameRate = 60
	end

	if self.expedition_add_on then
		self.expedition_add_on:on_dispose()
	end
	self.expedition_boss_data = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	self.scene = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
