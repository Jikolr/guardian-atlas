local local_class = newclass("Steampunk1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- [StageCustomKey(StageId = 100090005, StageName = 'steampunk_1_5')]
	self.custom_key = {
	}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	-- 퀘스트를 클리어 하지 않았으면, 오른쪽 바위 무더기쪽에 폭탄꽃이 나타나지 않음.
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil and not main_quest.IsComplete then
		local zone = field:GetZone('clear_bomb')
		local names = {
			'[GIMMICK]bomb_grass1',
			'[GIMMICK]bomb1',
		}

		local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, zone.Bounds)

		for i = 0, fo_list.Count - 1 do
			local fo = fo_list[i]
			if table_util.contain_value(names, fo.Name) then
				fo.ActiveState = active_state('disabled')
			end
		end

		fo_list:Dispose()
	end

	return
end

function local_class:need_on_launch()
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and (main_quest.InnerProgress >= 15)
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
end

function local_class:on_stage_loaded(_)
	return true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}