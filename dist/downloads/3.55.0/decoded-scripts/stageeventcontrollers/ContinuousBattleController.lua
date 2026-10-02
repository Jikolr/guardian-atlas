local local_class = newclass('ContinuousBattleController')

-- 18챕터 연속 전투 구현에 필요한 전투스테이지컨트롤러들을 중앙으로 관리할 컨트롤러.
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.on_stage_loaded_event_func = function(e)
		self:on_stage_loaded_event(e)
	end

	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)

	self.on_custom_stage_event_func = function(e)
		self:on_custom_stage_event(e)
	end

	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	return
end

function local_class:on_stage_loaded_event(e)
	self.blood_bead_controller = get_stage_event_controller('BloodBeadController')
	self.magnetic_stone_controller = get_stage_event_controller('MagneticStoneController')
	self.fallen_queen_bead_controller = get_stage_event_controller('FallenQueenBeadController')

	message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.BattleEndEvent))

	message_system:Unsubscribe(self.magnetic_stone_controller, typeof(CS.Oak.CustomStageEvent))

	message_system:Unsubscribe(self.blood_bead_controller, typeof(CS.Oak.CustomStageEvent))

end

function local_class:on_custom_stage_event(e)
	local battle_controller_key = e:GetParamAt(0)

	if battle_controller_key == 'BloodBeadController' then
		if e:GetParamAt(1) == 'activate' then
			message_system:Subscribe(self.blood_bead_controller, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
		else
			message_system:Unsubscribe(self.blood_bead_controller, typeof(CS.Oak.CustomStageEvent))
		end
	elseif battle_controller_key == 'MagneticStoneController' then
		if e:GetParamAt(1) == 'activate' then
			message_system:Subscribe(self.magnetic_stone_controller, typeof(CS.Oak.CustomStageEvent), 'on_receive_custom_event')
		else
			message_system:Unsubscribe(self.magnetic_stone_controller, typeof(CS.Oak.CustomStageEvent))
		end
	elseif battle_controller_key == 'FallenQueenBeadController' then
		if e:GetParamAt(1) == 'activate' then
			message_system:Subscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
			message_system:Subscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.DamageEvent), 'on_damage_event')
			message_system:Subscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
		else
			message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.CustomStageEvent))
			message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.DamageEvent))
			message_system:Unsubscribe(self.fallen_queen_bead_controller, typeof(CS.Oak.BattleEndEvent))
		end
	end
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

end

function local_class:dispose()
	if self.on_stage_loaded_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)
		self.on_stage_loaded_event_func = nil
	end

	if self.on_custom_stage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
		self.on_custom_stage_event_func = nil
	end

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
