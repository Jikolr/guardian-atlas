-- 선택 버프 주기
local local_class = newclass("TowerWaveClearBonusTimeController")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.game_timer = nil
	self.current_wave = nil
	self.add_time_list = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')

	local temp_data = require('stageeventcontrollers/TowerWaveClearBonusTimeData.lua')
	local data = temp_data[stage.Name]

	self.add_time_list = data.BonusTimePerWave
	return
end

function local_class:on_stage_start()
	-- 타이머 스테이지 시작시 동작안함
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStopEvent.Instance)
end

function local_class:on_battle_start_event()
	self.current_wave = 0
	self.game_timer = CS.Oak.GlobalTimerServiceExtenstion.GetInGameTimer(CS.Oak.GlobalTimerId.SingleGameTimer)

	message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
end

function local_class:on_battle_group_wave_clear_event()
	local add_time = self.add_time_list[self.current_wave + 1]
	local total = self.game_timer.RemainTime + add_time
	if total > stage.Spec.TimeLimit then
		add_time = total - stage.Spec.TimeLimit
	end

	message_system:Publish(CS.Oak.GlobalTimerModifiedEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, add_time))
	self.current_wave = self.current_wave + 1
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))

	self.game_timer = nil
	self.current_wave = nil
	self.add_time_list = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
