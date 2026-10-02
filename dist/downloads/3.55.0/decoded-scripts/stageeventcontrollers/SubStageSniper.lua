local local_class = newclass("SubStageSniperController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_tesla_coil_on_off_event')

	return
end

function local_class:need_on_launch()
	local sniper_quset = user_progress:GetStartedQuest(120)
	return sniper_quset ~= nil and not sniper_quset.IsComplete
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	local i = 1
	while user_party.Count ~= 1 do
		character_util.set_position(user_party[i], vector(99, 0, 99))
		character_util.convert_to_npc(user_party[i])
	end

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.Linear)

	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, field:GetMarker('default_start').position,
			field:GetMarker('default_start').direction, game_string:GetString(stage.Name))

	party_util.stop_and_disable_control()

	field_ui_util.show_narration_async({ key = 'steampunk_sniper_stage_narration'})

	party_util.reset_controllers()

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

--region on event
function local_class:on_event(e)
	return false
end

function local_class:on_tesla_coil_on_off_event(e)
	if lua_helper.reference_equals(e.CoilObject, get_field_object('tesla')) and e.IsTurningOn == false then
		sp_util.play_normal_screenplay(self.show_door_close, self)
	end

	return false
end
--endregion

function local_class:show_door_close()
	local door = get_field_object('room_2_door_1')
	camera_util.move_async(door.Position, 1)
	wait_for_sec(2)
	camera_util.return_to_leader(1)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
