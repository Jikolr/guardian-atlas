local local_class = newclass("ExaltingGnomeController")

--[[QuestAttribute
		Type = controller @
		QuestName = Exalting Gnome @
		Comment = 퍼즐 3 : 찬양대 이벤트 컨트롤러 @
]]

function local_class:init(quest_id, cs_controller)
	self.cs_controller = cs_controller
	self.quest_id = quest_id
	self.quest_progress = nil
	self.quest_spec = nil

	self.stage_name = 'nightmare_titantavern_2'
end

function local_class:dispose()
	quest_util.dispose_controller(self)

	self.cs_controller = nil
	self.quest_progress = nil
	self.quest_spec = nil

	if self.current_section ~= nil then
		self.current_section:exit()
		self.current_section = nil
	end
	if self.pre_story_section ~= nil then
		self.pre_story_section = nil
	end
	if self.post_story_section ~= nil then
		self.post_story_section = nil
	end
end

function local_class:on_event(e)
	return quest_util.on_event(self, e)
end


function local_class:on_event_received_routine(e)
	return false
end

function local_class:load_resource()
	return util.cs_generator(quest_util.load_resource, self)
end

-- pre story section 설정
function local_class:on_pre_story_init()
end
-- main section 설정
function local_class:on_init()
	self.sections = {
		quest_util.load_section(self, 'ExaltingGnomeSection1'),
	}
end

function local_class:load_progress()
	return util.cs_generator(quest_util.load_progress, self)
end

function local_class:on_load_resource_routine()
	if self.quest_progress ~= nil and self.quest_progress.IsComplete then
	end
end

function local_class:on_stage_loaded()
	if stage.Name == self.stage_name then
	end
end

function local_class:on_progress_section()
end

return {
	create = function(quest_id, cs_controller)
		return local_class(quest_id, cs_controller)
	end
}

