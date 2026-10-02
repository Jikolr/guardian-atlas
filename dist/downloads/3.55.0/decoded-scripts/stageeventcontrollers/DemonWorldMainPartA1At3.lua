local local_class = newclass("DemonWorldMainPartA1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'demonworld_part1_1_3'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_field_object_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
		-- 'stage_item'
		)
	end

	local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
	yield_return_func(demon_world_dollar.load_resource, demon_world_dollar)
end

function local_class:need_on_launch()
	local main_quest_id = 216
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		7
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_move_field_object_event(e)
	local burning_fo = get_field_object('burning_man')
	local burning_npc = get_character('burning_man')
	if lua_helper.reference_equals(e.FieldObject, burning_fo) then
		burning_npc.Position = burning_fo.Position
		return true
	end

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
