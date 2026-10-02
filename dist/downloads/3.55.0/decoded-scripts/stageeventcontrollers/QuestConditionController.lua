local local_class = newclass('QuestConditionController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 이 테이블에 Constants 경로를 추가
	self.constants = {
		--'Quest/Main/CivilWar/Common/QuestConditionConstants',
	}

	self.current_condition_table = nil
	self.constants_data_list = { }

	for i = 1, #self.constants do
		local constants = get_or_create_global_variable(self.constants[i])

		self.constants_data_list[i] = constants
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	message_system:Unsubscribe(self, typeof(CS.Oak.QuestClearedEvent), 'on_quest_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestStartedEvent), 'on_quest_event')

	self.current_condition_table = nil
	self.constants_data_list = nil
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	for i = 1, #self.constants_data_list do
		if self.current_condition_table ~= nil then
			break
		end

		self:try_load_constants(self.constants_data_list[i])
	end

	self.constants_data_list = nil

	message_system:Subscribe(self, typeof(CS.Oak.QuestStartedEvent), 'on_quest_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestClearedEvent), 'on_quest_event')

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_quest_event(e)
	if lua_helper.type_compare(e, CS.Oak.QuestProgressedEvent) then
		self:all_check_quest_condition_by_quest_data(e.QuestId, e.CurrentProgress)
	elseif lua_helper.type_compare(e, CS.Oak.QuestStartedEvent) then
		self:all_check_quest_condition_by_quest_data(e.QuestId, 0)
	else
		self:all_check_quest_condition_by_quest_id(e.QuestId)
	end
	return false
end

function local_class:on_stage_loaded_event(e)
	if self.current_condition_table ~= nil then
		for quest_id, _ in pairs(self.current_condition_table) do
			self:all_check_quest_condition_by_quest_id(quest_id)
		end
	end

	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:try_load_constants(constants)
	local stage_name = stage.Name

	if constants[stage_name] ~= nil then
		self.current_condition_table = { }

		table_util.for_each(constants[stage_name], function(quest_id, inner_table)
			self.current_condition_table[quest_id] = {
				characters = inner_table.characters,
				field_objects = inner_table.field_objects
			}
		end)
	end
end

function local_class:contains_by_progress(progress, data_value)
	return data_value ~= nil and data_value[progress] ~= nil
end

function local_class:get_max_progress(limit_progress, data_value)
	-- 리미트가 clear 일 경우 999로 셋업
	if limit_progress == 'clear' then
		limit_progress = 999
	end

	if data_value ~= nil then
		local current = -2

		for target_progress, target_data in pairs(data_value) do
			if type_util.is_number(target_progress) and current < target_progress and target_progress < limit_progress then
				current = target_progress
			end
		end

		-- 아에 못찾았다는 뜻이니 nil을 반환
		if current == -2 then
			return nil
		end

		return current
	end

	-- error
	return nil
end

function local_class:check_quest_condition_by_character(progress, data_key, data_value)
	for target_progress, target_data in pairs(data_value) do
		if progress == target_progress then
			local character = get_character(data_key)

			if target_data.active_state ~= nil then
				character_util.set_active_state(character, target_data.active_state)
			end

			if target_data.position ~= nil then
				local result_pos = nil

				if type_util.is_string(target_data.position) then
					result_pos = field_util.get_marker_pos(target_data.position)

					if not field_util.has_marker(target_data.position) then
						logger_util.error('[QuestConditionController] error! get_marker_pos failed. marker name = ' .. target_data.position)
					end
				else
					result_pos = target_data.position
				end

				if result_pos ~= nil then
					if target_data.offset ~= nil then
						result_pos = result_pos + target_data.offset
					end

					character.Position = result_pos
				else
					logger_util.error('[QuestConditionController] error! result_pos is nil')
				end
			end

			if target_data.anim ~= nil then
				if type_util.is_table(target_data.anim) then
					character_util.set_anim(character, target_data.anim)
				else
					character_util.set_anim(character, { name = target_data.anim })
				end
			end

			if target_data.emotion ~= nil then
				if type_util.is_table(target_data.emotion) then
					character_util.set_emotion(character, target_data.emotion)
				else
					character_util.set_emotion(character, { name = target_data.emotion })
				end
			end

			if target_data.dir ~= nil then
				character_util.set_direction(character, target_data.dir)
			end
		end
	end
end

function local_class:check_quest_condition_by_fo(progress, data_key, data_value)
	for target_progress, target_data in pairs(data_value) do
		if progress == target_progress then
			local fo = get_field_object(data_key)

			if target_data.active_state ~= nil then
				character_util.set_active_state(fo, target_data.active_state)
			end

			if target_data.position ~= nil then
				local result_pos = nil

				if type_util.is_string(target_data.position) then
					result_pos = field_util.get_marker_pos(target_data.position)

					if not field_util.has_marker(target_data.position) then
						logger_util.error('[QuestConditionController] error! get_marker_pos failed. marker name = ' .. target_data.position)
					end
				else
					result_pos = target_data.position
				end

				if result_pos ~= nil then
					if target_data.offset ~= nil then
						result_pos = result_pos + target_data.offset
					end

					fo.Position = result_pos
				else
					logger_util.error('[QuestConditionController] error! result_pos is nil')
				end
			end
		end
	end
end

function local_class:all_check_quest_condition_by_quest_id(quest_id)
	if self.current_condition_table == nil then
		return
	end

	local quest = user_progress:GetStartedQuest(quest_id)

	if quest ~= nil then
		self:all_check_quest_condition_by_quest(quest)
	else
		self:all_check_quest_condition_by_quest_data(quest_id, -1)
	end
end

function local_class:all_check_quest_condition_by_quest(quest)
	if quest ~= nil and self.current_condition_table ~= nil then
		local id = quest.QuestId
		local current_progress = quest.InnerProgress

		if quest.IsComplete then
			current_progress = 'clear'
		end

		self:all_check_quest_condition_by_quest_data(id, current_progress)
	end
end

function local_class:all_check_quest_condition_by_quest_data(quest_id, quest_progress)
	if self.current_condition_table ~= nil then
		local id = quest_id
		local current_progress = quest_progress

		if current_progress ~= nil and self.current_condition_table[id] ~= nil then
			local current_table = self.current_condition_table[id]
			local characters = current_table.characters
			local fos = current_table.field_objects

			if characters ~= nil then
				for key, value in pairs(characters) do
					if self:contains_by_progress(current_progress, value) then
						self:check_quest_condition_by_character(current_progress, key, value)
					else
						local max_progress = self:get_max_progress(current_progress, value)

						if max_progress ~= nil then
							self:check_quest_condition_by_character(max_progress, key, value)
						end
					end
				end
			end

			if fos ~= nil then
				for key, value in pairs(fos) do
					if self:contains_by_progress(current_progress, value) then
						self:check_quest_condition_by_fo(current_progress, key, value)
					else
						local max_progress = self:get_max_progress(current_progress, value)

						if max_progress ~= nil then
							self:check_quest_condition_by_fo(max_progress, key, value)
						end
					end
				end
			end
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
