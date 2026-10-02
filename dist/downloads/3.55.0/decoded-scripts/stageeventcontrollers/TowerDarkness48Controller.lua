-- 선택 버프 주기
local local_class = newclass("TowerDarkness48Controller")

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
	self.is_timer_start = false
	self.is_game_over = false
	self.is_sub_battle = false
	self.current_battle_name = nil
	self.game_timer = nil
	self.field_ui = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.subs_stage_start_func = function(e)
		self:on_stage_start_event(e)
	end
	--스테이지 시작
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.StageStartEvent), self.subs_stage_start_func)

	self.subs_zone_enter_func = function(e)
		self:on_zone_enter_event(e)
	end
	--배틀존 입장
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.ZoneEnterEvent), self.subs_zone_enter_func)--Zone, IFO, isFullEnter

	self.subs_game_over_func = function(e)
		self:on_game_over_event(e)
	end
	--게임 종료 (타임아웃)
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.GameOverEvent), self.subs_game_over_func)

	self.subs_timer_alarm_func = function(e)
		self:on_global_timer_alarm_event(e)
	end
	-- 타이머 알람
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.GlobalTimerAlarmEvent), self.subs_timer_alarm_func)

	self.subs_battle_group_eliminated_func = function(e)
		self:on_battle_group_eliminated_event(e)
	end
	-- 배틀존 그룸 전멸시킨 경우
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.BattleGroupEliminatedEvent), self.subs_battle_group_eliminated_func)

	self.controller_data = require('stageeventcontrollers/TowerDarkness48Data.lua')
	return
end
--스테이시 시작시
function local_class:on_stage_start_event(e)
	--타이머 시작되어야 함.
	self:start_timer()
end

function local_class:start_timer()
	self.is_timer_start = true
	self.game_timer = CS.Oak.GlobalTimerServiceExtenstion.GetInGameTimer(CS.Oak.GlobalTimerId.SingleGameTimer)
end

--종료해서 게임 끝났으면
function local_class:stop_timer()
	message_system:Publish(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStopEvent.Instance)
end

function local_class:on_time_over()
	self.is_game_over = true
end


-- 시간이 오버 되면 불리는 루틴
function local_class:on_global_timer_alarm_event(e)
	if e.TimerId ~= CS.Oak.GlobalTimerId.SingleGameTimer or not e.IsComplete then return end
	self:on_time_over()
end

--해당 배틀존 입장시
function local_class:on_zone_enter_event(e)
	if not e.FullEnter then
		return false
	end

	if e.FieldObject ~= user_party_leader then
		return false
	end
	local zone_name = e.Zone.Name
	for i = 1, #self.controller_data.zones do

		if zone_name == self.controller_data.zones[i].zone_name then
			self.is_sub_battle = true
			self.current_battle_name = zone_name
		end
	end
	return true
end

-- 배틀존에서의 적군 전멸 이벤트
function local_class:on_battle_group_eliminated_event(e)
	if self.current_battle_name == e.BattleGroupName then
		-- 지정된 배틀이 종료 되었다면
		self.is_sub_battle = false
		--시간추가되어야 함.
		for i = 1, #self.controller_data.zones do
			if self.controller_data.zones[i].zone_name == self.current_battle_name then
				local additional_time = self.game_timer.RemainTime + self.controller_data.zones[i].additional_play_time


				if additional_time >= stage.Spec.TimeLimit then
						additional_time = stage.Spec.TimeLimit - self.game_timer.RemainTime
				else
					additional_time = self.controller_data.zones[i].additional_play_time
				end

				message_system:Publish(CS.Oak.GlobalTimerModifiedEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
						additional_time))
			end
		end

	end
end

-- 종료 이벤트
function local_class:on_game_over_event(e)
	return true
end


function local_class:dispose()

	if self.subs_stage_start_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.StageStartEvent), self.subs_stage_start_func)
	end
	self.subs_stage_start_func = nil

	if self.subs_zone_enter_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.ZoneEnterEvent), self.subs_zone_enter_func)
	end
	self.subs_zone_enter_func = nil
	if self.subs_game_over_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.GameOverEvent), self.subs_game_over_func)
	end

	self.subs_game_over_func = nil
	if self.subs_timer_alarm_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.GlobalTimerAlarmEvent), self.subs_timer_alarm_func)
	end

	self.subs_timer_alarm_func = nil
	if self.subs_battle_group_eliminated_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.BattleGroupEliminatedEvent), self.subs_battle_group_eliminated_func)
	end
	self.subs_battle_group_eliminated_func = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
