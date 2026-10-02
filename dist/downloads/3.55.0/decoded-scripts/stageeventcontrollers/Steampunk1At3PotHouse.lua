local local_class = newclass("Steampunk1At3PotHouseController")

--[[QuestAttribute
		Type = controller @
		QuestName = Steampunk 3 star piece 4 event @
		Comment = 스팀펑크 3 스타피스 이벤트 4 @
]]

function local_class:init(quest_id, cs_controller)
	self.cs_controller = cs_controller
	self.quest_id = quest_id
	self.quest_progress = nil
	self.quest_spec = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

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
	self.pre_story_section = quest_util.load_section(self, 'SteampunkStarPiece3PotHousePreSection')
end
-- main section 설정
function local_class:on_init()
	self.sections = {
		quest_util.load_section(self, 'SteampunkStarPiece3PotHouseSection1')
	}

	self.post_story_section = quest_util.load_section(self, 'SteampunkStarPiece3PotHousePostSection')
end

function local_class:load_progress()
	return util.cs_generator(quest_util.load_progress, self)
end

function local_class:on_load_resource_routine()
	if self.quest_progress ~= nil and self.quest_progress.IsComplete then
		local pot_guy = get_character('pot_male')
		character_util.set_direction(pot_guy, "left")
		character_util.set_emotion(pot_guy, { name = 'hurt' })
		character_util.set_anim(pot_guy, { name = 'prostrate' })
	end
end

function local_class:on_stage_loaded()
end

function local_class:on_progress_section()
end

return {
	create = function(quest_id, cs_controller)
		return local_class(quest_id, cs_controller)
	end
}
