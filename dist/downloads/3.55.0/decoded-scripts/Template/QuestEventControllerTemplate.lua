local local_class = newclass('name_controller')

-- EnterSection, ActivateQuest, ProgressSection, CompleteQuest 등의 함수들을 quest_util 에 들어가 있음
-- 이전 C# 에서 부모 함수에 구현 된 부분은 quest_util 로 빼놓았음
-- 생성자
function local_class:init(quest_id, cs_controller, _)
	-- CS Controller 로 OnEvent 를 받을수 있다.
	self.cs_controller = cs_controller
	self.quest_id = quest_id
	self.quest_progress = nil
	self.quest_spec = nil

	self.starting_inner_progress = -1
	self.starting_grade = -1
	self.inter_section_params = {}

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:on_event_received_routine(e)
	return false
end

function local_class:load_resource()
	return util.cs_generator(quest_util.load_resource, self)
end

function local_class:on_pre_story_init()
	-- pre story section 은 여기서 읽는다
	self.pre_story_section = quest_util.load_section(self, 'pre_section_name')
end

function local_class:on_init()
	self.sections = {
		quest_util.load_section(self, 'section1_name')
	}

	self.post_story_section = quest_util.load_section(self, 'post_section_name')
end

function local_class:on_load_resource_routine()
	-- ObjectPool PreLoad가 필요할 때 뒤에 인자로 주르륵 넣는다
	-- ex) yield_return_func(quest_util.load_pool_resource,'bla1', 'bla2')
	--yield_return_func(quest_util.load_pool_resource,'')
end

function local_class:on_event(e)
	return quest_util.on_event(self, e)
end

function local_class:on_stage_loaded()
end

function local_class:load_progress()
	return util.cs_generator(quest_util.load_progress, self)
end

function local_class:dispose()
	quest_util.dispose_controller(self)

	if quest_util.is_available_section(self.current_section) then
		self.current_section:exit()
	end

	self.current_section = nil

	if self.pre_story_section ~= nil then
		self.pre_story_section = nil
	end

	if self.post_story_section ~= nil then
		self.post_story_section = nil
	end

	self.cs_controller = nil
	self.quest_progress = nil
	self.quest_spec = nil
	self.scene = nil

	self.sections = nil
	self.inter_section_params = nil
end

return {
	create = function(quest_id, cs_controller, scene_class)
		return local_class(quest_id, cs_controller, scene_class)
	end
}
