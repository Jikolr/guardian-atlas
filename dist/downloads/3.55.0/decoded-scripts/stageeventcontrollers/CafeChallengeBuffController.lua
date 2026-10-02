local local_class = newclass('CafeChallengeBuffController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	-- 챌린지 모든 몬스터 피해 감소 버프
	local monsters = character_manager:GetAllMonsters()

	for i = 0, monsters.Count - 1 do
		buff_manager:AddBuff(monsters[i], CS.Oak.EquipmentSlot.None, monsters[i],
			'damage_reduction_persistent', 350, false, false)
	end

	return true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
