local local_class = newclass("CpuTestController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_npc = function(num) return get_character('npc_' .. num) end

	self.npc_coroutine = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.TouchEvent) then
		if e.TouchEventType == CS.Oak.TouchEventType.Action1TouchDown and self.npc_coroutine == nil then
			self.npc_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.npcs_move_routine, self))
			return true
		end
	end
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	self.npc_coroutine = nil
	self.cs_controller = nil
end

function local_class:npcs_move_routine()

	for i = 1, 3 do
		self.get_npc(i).Position = vector(-6 + i, 0, 2)
		character_util.set_direction(self.get_npc(i), 'right')
		character_util.set_anim(self.get_npc(i), {name = 'dance'})
	end

	wait_for_sec(5)

	for i = 1, 3 do
		self.get_npc(i).Position = vector(999, 0, 999)
	end

	self.npc_coroutine = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
