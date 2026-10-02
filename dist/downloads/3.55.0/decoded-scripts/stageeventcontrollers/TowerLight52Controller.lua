local local_class = newclass('TowerLight52Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	self.controller_data = require('stageeventcontrollers/TowerLight52ControllerData.lua')
	self.current_stage_info = self.controller_data[stage.Name]
	self.timer_increase_count = 0
	self.elapsed_time = 0.0
	self.is_game_over = false;
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end


function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)

	if self.is_game_over then return end

	self.elapsed_time = self.elapsed_time + dt

	if self.elapsed_time <= self.current_stage_info.break_delay then return end

	if self.timer_increase_count <= 0 then return end

	self.elapsed_time = 0.0

	local game_timer = CS.Oak.GlobalTimerServiceExtenstion.GetInGameTimer(CS.Oak.GlobalTimerId.SingleGameTimer)

	if game_timer == nil then return end

	local additional_time = game_timer.RemainTime + self.current_stage_info.additional_time

	if additional_time >= stage.Spec.TimeLimit then
		additional_time = stage.Spec.TimeLimit - game_timer.RemainTime
	else
		additional_time = self.current_stage_info.additional_time
	end

	message_system:Publish(CS.Oak.GlobalTimerModifiedEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer,
		additional_time))

	self.timer_increase_count = self.timer_increase_count - 1;
end


function local_class:on_field_object_destroyed_event(e)

	if string.find(e.FieldObject.Name, self.current_stage_info.target_ifo_name) then

		self.timer_increase_count = self.timer_increase_count + 1
	end

end

function local_class:on_stage_start_event(e)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
		{key = self.current_stage_info.description, stop_timer = true })
end

function local_class:on_game_over_event(e)
 	self.is_game_over = true
end


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))

	self.cs_controller = nil
	self.controller_data = nil
	self.current_stage_info = nil

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
