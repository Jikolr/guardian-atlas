local local_class = newclass('TowerBombDamageController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
end

function local_class:on_damage_event(e)
	if lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		local tmp = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
		if lua_helper.reference_equals(e.Info.type, tmp) then
			if lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.BarrelFieldObjectBehaviour) or
					lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.BombFieldObjectBehaviour) then
				if not lua_helper.reference_equals(e.Info.target, user_party_leader) then
					local damage_info = CS.Oak.DamageInfo()
					local c = 0.25
					damage_info.type = tmp
					damage_info.sender = user_party_leader
					damage_info.target = e.Info.target
					damage_info.damage = math.floor(e.Info.target.FieldObjectStatsBehaviour.MaxHP * c)
					damage_info.notMortal = false
					command_util.execute_damage(damage_info)
				end
			end
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
