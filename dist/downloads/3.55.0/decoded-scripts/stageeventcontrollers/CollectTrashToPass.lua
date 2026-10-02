local local_class = newclass("CollectTrashToPassController")

--[[QuestAttribute
		Type = controller @
		QuestName = Collect Trash To Pass @
		Comment = 쓰레기장 진입 이벤트 컨트롤러 @
]]

function local_class:init(quest_id, cs_controller)
	self.cs_controller = cs_controller
	self.quest_id = quest_id
	self.quest_progress = nil
	self.quest_spec = nil

	self.stage_name = 'nightmare_titantavern_2'
	-- 라즈베리, 테슬라, 찬양대

	self.has_trash = { false, false, false }

	self.trash_pos = {
		vector(3.5, 0.2, -39.5),
		vector(-3.5, 1.2, -50.5),
		vector(55, 0.2, -55)
	}

	self.trash = {}

	self.has_cleared_trash = 'has_cleared_trash'

	self.trash_name = { 'banana', 'gnome_times', 'cartridge_case' }

	self.title = { 'banana_title', 'gnome_times_title', 'cartridge_case_title' }
	self.subtitle = { 'banana_subtitle', 'gnome_times_subtitle', 'cartridge_case_subtitle' }
	self.desc = { 'banana_desc_desc', 'gnome_times_desc', 'cartridge_case_desc' }
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
		quest_util.load_section(self, 'CollectTrashToPassSection1'),
		quest_util.load_section(self, 'CollectTrashToPassSection2'),
	}

	self.post_story_section = quest_util.load_section(self, 'CollectTrashToPassPostSection')
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

function local_class:trash_setting(progress)
	local data = progress
	local bitflag_list = {
		1, --> 라즈베리 쓰레기 : 바나나 껍질
		2, --> 테슬라 쓰레기 : 노움 신문
		4, --> 찬양대 쓰레기 : 버려진 탄피
	}
	for i = 1, 3 do
		local scale = 1.5
		if i == 1 then scale = 1 end
		if data & bitflag_list[i] == 0 then
			self.trash[i] = drop_item_util.create_item({
				pos = self.trash_pos[i],
				itemid = game_data_service.GetData('ItemData'):GetSpec(self.trash_name[i]).Id,
				notforinven = true,
				sprscale = scale,
				showoncharacter = true
			})
			self.trash[i].PickFlyDistance = 1
		end
	end
end

function local_class:update_state(i)
	local item_data = game_data_service.GetData('ItemData')
	yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent,
			{ ItemId = item_data:GetSpec(self.trash_name[i]).Id },
			self.title[i],
			self.subtitle[i],
			self.desc[i]
	)
	local trash = get_field_object(self.trash_name[i])
	if trash ~= nil then
		trash.Position = vector(999, 0, 999)
	end

	quest_marker_util.remove('trash_' .. i)
	local progress = self.quest_progress:GetCustomState(self.has_cleared_trash)
	quest_util.set_custom_state(self.quest_progress, self.has_cleared_trash, progress + 2 ^ (i - 1))
end

return {
	create = function(quest_id, cs_controller)
		return local_class(quest_id, cs_controller)
	end
}
