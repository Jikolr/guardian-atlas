local local_class = newclass('NightmareFutureCastle2Launcher')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_data = {
		{
			stage_name = 'nightmare_futurecastle_part2_1',
			compare_func = function(inner_progress)
				return inner_progress <= 0
			end
		},
		{
			stage_name = 'nightmare_futurecastle_part2_6',
			compare_func = function(inner_progress)
				return inner_progress == 4
			end
		}
	}

	self.main_quest_id = 217
end

function local_class:load_resource()
	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	for i = 1, #self.stage_data do
		if stage.Name == self.stage_data[i].stage_name then

			local inner_progress = user_progress:GetStartedQuest(self.main_quest_id).InnerProgress

			return self.stage_data[i].compare_func(inner_progress) and not user_progress:ClearedQuest(self.main_quest_id)
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
