local local_class = newclass("DemonWorldMainPartA1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'demonworld_part1_1_2'

	-- 경찰 NPC 정보
	self.police_name = 'event_police_'

	-- 메인 퀘스트 섹션 7에서 사용하는 울타리
	self.fence_num = 32
	self.fence_name = 'section_7_fence_'

	-- 메인 퀘스트 ID
	self.main_quest_id = 216
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

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
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local progress_list = {
		4, 5, 6, 7
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	-- 메인 퀘스트 섹션이 5, 6, 7일 때만 활성화
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local main_quest_inner_progress = quest_progress.InnerProgress

	if main_quest_inner_progress < 4 or main_quest_inner_progress >= 7 then
		for i = 1, self.fence_num do
			stage_util.set_fo_active_state(self.fence_name..i, 'disabled')
		end
	end

	-- 메인 퀘스트 섹션 7 이상이면 경찰서 내 NPC들에게 one Line 대사 추가
	if main_quest_inner_progress >= 7 then
		get_character(self.police_name..4).Interactable.Talk = 'demonworld_part1_stage_2_police_1'
		get_character(self.police_name..3).Interactable.Talk = 'demonworld_part1_stage_2_police_2'
		get_character(self.police_name..6).Interactable.Talk = 'demonworld_part1_stage_2_police_3'
		get_character(self.police_name..1).Interactable.Talk = 'demonworld_part1_stage_2_police_4'
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
