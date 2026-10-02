local local_class = newclass('DemonWorldMainPartAPassage2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.fo_to_npc_interact_infos = {
		{
			fo_name = 'bar_succubus_1',
			npc_name = 'demon_civilian_succubus_1'
		},
		{
			fo_name = 'bar_succubus_2',
			npc_name = 'demon_civilian_succubus_2'
		},
		{
			fo_name = 'pizza_npc_1',
			npc_name = 'demon_civilian_pizzastore_1'
		},
		{
			fo_name = 'pizza_npc_2',
			npc_name = 'demon_civilian_pizzastore_2'
		},
	}
	self.fo_to_npc_interact_dict = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	yield_return_func(demon_world_dollar.load_resource, demon_world_dollar)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded(e)
	-- 인터랙트 타겟 할당
	for _, fo_to_npc_info in pairs(self.fo_to_npc_interact_infos) do
		self.fo_to_npc_interact_dict[get_field_object(fo_to_npc_info.fo_name)] = get_character(fo_to_npc_info.npc_name)
	end

	return false
end

function local_class:on_interact_event(e)
	local npc_target = self.fo_to_npc_interact_dict[e.Target]
	if npc_target ~= nil then
		speech_bubble_util.show_speech_bubble(npc_target,
				{key = npc_target.Interactable.Talk, bubble_direction = 'cb'})
		return true
	end

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
