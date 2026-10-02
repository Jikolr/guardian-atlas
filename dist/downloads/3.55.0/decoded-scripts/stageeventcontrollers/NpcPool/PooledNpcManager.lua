local local_class = newclass('PooledNpcManager')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.constants = nil

	self.quest_id_to_group_names = {}

	self.group_handlers = {}

	self.pooling_system = nil

	self.condition_types = {
		quest = 'quest',
	}

	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
	local constants_generator = get_or_create_global_variable(
			'stageeventcontrollers/NpcPool/PooledNpcConstantsGenerator')

	self.constants = constants_generator.get_stage_constants(stage.Spec.ChapterCode.Value, stage.Name)

	if self.constants ~= nil then
		local created

		created, self.pooling_system = global_table_util.try_create_npc_pooling_system()

		self.pooling_system:init_pools(self.constants.pools)

		message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestClearedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))

	self.quest_id_to_group_names = nil

	if self.group_handlers ~= nil then
		for _, handlers in pairs(self.group_handlers) do
			for _, handler in ipairs(handlers) do
				handler:dispose()
			end
		end

		self.group_handlers = nil
	end

	self.pooling_system = nil

	self.cs_controller = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	for group_name, group in pairs(self.constants.groups) do
		if group.condition.type == self.condition_types.quest then
			local group_names = self.quest_id_to_group_names[group.condition.quest_id]

			if group_names == nil then
				self.quest_id_to_group_names[group.condition.quest_id] = {
					group_name
				}
			else
				group_names[#group_names + 1] = group_name
			end
		end

		local is_valid = self:is_valid_condition(group.condition)

		if is_valid then
			self:init_group(group_name)
		end
	end

	if not table_util.is_empty(self.quest_id_to_group_names) then
		message_system:Subscribe(self, typeof(CS.Oak.QuestClearedEvent), 'on_quest_cleared_event')
		message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	end
end

function local_class:on_quest_progressed_event(e)
	return self:on_quest_condition_changed(e.QuestId)
end

function local_class:on_quest_cleared_event(e)
	return self:on_quest_condition_changed(e.QuestId)
end

function local_class:on_quest_condition_changed(quest_id)
	local group_names = self.quest_id_to_group_names[quest_id]

	if group_names ~= nil then
		local groups_to_init = {}
		local groups_to_dispose = {}

		for _, group_name in ipairs(group_names) do
			local group = self.constants.groups[group_name]
			local is_activated = self.group_handlers[group_name] ~= nil
			local is_valid = self:is_valid_condition(group.condition)

			if not is_activated and is_valid then
				groups_to_init[#groups_to_init + 1] = group_name
			elseif is_activated and not is_valid then
				groups_to_dispose[#groups_to_dispose + 1] = group_name
			end
		end

		-- dispose들을 먼저 실행해야 최소한의 풀링 카운트를 보장할 수 있다.
		for _, group_name in ipairs(groups_to_dispose) do
			self:dispose_group(group_name)
		end

		for _, group_name in ipairs(groups_to_init) do
			self:init_group(group_name)
		end

		return true
	end

	return false
end

function local_class:init_group(group_name)
	local group = self.constants.groups[group_name]
	local handlers = {}

	for key, info in pairs(group.members) do
		local position = self:get_position(info.position)
		local handler = self.pooling_system:get_npc_handler(info.key, position, info.direction)

		-- FIXME : Upper Animation도 같이 세팅할 수 있어야 하나?
		if info.anim ~= nil then
			handler:set_anim(self, info.anim)
		end

		if info.emotion ~= nil then
			handler:set_emotion(self, info.emotion)
		end

		if info.talk ~= nil then
			if type_util.is_table(info.talk) then
				handler:set_one_line(info.talk.key, info.talk.sfx)
			else
				handler:set_one_line(info.talk)
			end
		end

		handlers[key] = handler
	end

	self.group_handlers[group_name] = handlers
end

function local_class:dispose_group(group_name)
	for _, handler in ipairs(self.group_handlers[group_name]) do
		handler:dispose()
	end

	self.group_handlers[group_name] = nil
end

local cleared_value = 'clear'

function local_class:is_valid_condition(condition_data)
	if condition_data.type == self.condition_types.quest then
		local quest = quest_util.get_started_quest(condition_data.quest_id)
		local progress = -1
		local cleared = false

		if quest ~= nil then
			progress = quest.InnerProgress
			cleared = quest.IsComplete
		end

		for i = 1, #condition_data.progress_infos do
			local info = condition_data.progress_infos[i]

			if info.from == cleared_value then
				if cleared then
					return true
				end
			elseif info.to == cleared_value then
				if info.from <= progress or cleared then
					return true
				end
			elseif info.from <= progress and progress <= info.to and not cleared then
				return true
			end
		end
	end

	return false
end

function local_class:get_position(position_data)
	if type_util.is_table(position_data) then
		return field_util.get_marker_pos(position_data.pivot) + position_data.offset
	else
		return field_util.get_marker_pos(position_data)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
