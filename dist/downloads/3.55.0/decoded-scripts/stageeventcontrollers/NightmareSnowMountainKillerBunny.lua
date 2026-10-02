local local_class = newclass('NightmareSnowMountainKillerBunnyController')

function local_class:init(quest_id, cs_controller)
	self.cs_controller = cs_controller
	self.quest_id = quest_id

	self.starting_grade = -1
end

function local_class:load_resource()
	return util.cs_generator(quest_util.load_resource, self)
end

function local_class:on_load_resource_routine()
end

function local_class:on_pre_story_init()
end

function local_class:on_init()
	self.sections = {
		quest_util.load_section(self, 'NightmareSnowMountainKillerBunnySection1')
	}

	self.post_story_section = quest_util.load_section(self, 'NightmareSnowMountainKillerBunnyPostSection')
end

function local_class:on_stage_loaded()
end

function local_class:on_event(e)
	return quest_util.on_event(self, e)
end

function local_class:load_progress()
	return util.cs_generator(quest_util.load_progress, self)
end

function local_class:on_load_resource_routine()
end

function local_class:on_progress_section()
end

function local_class:dispose()
	quest_util.dispose_controller(self)

	if self.current_section ~= nil then
	self.current_section:exit()
		self.current_section = nil
	end

	if self.post_story_section ~= nil then
		self.post_story_section = nil
	end

	self.sections = nil

	self.cs_controller = nil
	self.quest_progress = nil
	self.quest_spec = nil
end

return {
	create = function(quest_id, cs_controller)
		return local_class(quest_id, cs_controller)
	end
}
