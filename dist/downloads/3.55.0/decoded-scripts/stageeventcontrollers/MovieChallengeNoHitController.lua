local local_class = newclass("MovieChallengeNoHitController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

---[[ on_event
function local_class:on_stage_loaded_event()
	local monsters = character_manager:GetAllMonsters()

	-- 플레이어를 한방에 죽일 수 있도록 몬스터에 공업 버프

	for i = 0, monsters.Count - 1 do
		buff_manager:AddBuff(user_party_leader, CS.Oak.EquipmentSlot.None,
				monsters[i], 'attack_up_permill_persistent', 9999, false, false)
	end

	-- 플레이어가 한방에 죽도록 def, hp 디버프

	buff_manager:AddBuff(user_party_leader, CS.Oak.EquipmentSlot.None,
			user_party_leader, 'defense_up_permill_persistent', -9999, false, false)

	buff_manager:AddBuff(user_party_leader, CS.Oak.EquipmentSlot.None,
			user_party_leader, 'hp_up_permill_persistent', -999, false, false)

	return false
end
---]]


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.stage_data = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
