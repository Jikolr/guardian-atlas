local local_class = newclass('CoopDefense')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.strongholdObject = get_field_object('stronghold')
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end')

	unity_object_pool.GetOrCreate('fx_summon_circle')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_coop_end(e)
	if CS.Oak.UI.CoopDefenseBaseHpUI.Instance ~= nil then
		CS.Oak.UI.CoopDefenseBaseHpUI.Instance:StopWarningGlowAnimation()
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))

	self.strongholdObject = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
