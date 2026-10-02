local local_class = newclass('"$NAME$"')

--[[QuestAttribute
		"$QUEST_ATTRIBUTE$"
]]

function local_class:init(controller, cs_section)
	---@type "$CONTROLLER_NAME$"
	self.controller = controller

	---@type LuaQuestEventController
	self.cs_controller = controller.cs_controller

	---@type LuaQuestEventSection
	self.cs_section = cs_section

	-- 스테이지 제약이 있는 경우 주석 해제하고 스테이지명 입력. string과 string 테이블 둘 다 사용 가능
	--self.available_stage_names = {}

	-- 섹션 내부 스테이트 enum
	--self.states = {
	--	none = 1,
	--}
	--
	--self.current_state = self.states.none
end

--- 해당 기능을 사용하지 않으면 지워도 무관함
function local_class:on_pre_load()
end

--- 해당 기능을 사용하지 않으면 지워도 무관함
function local_class:need_skip()
	return false
end

function local_class:enter()
end

function local_class:start()
end

function local_class:exit()
end

function local_class:dispose()
	self.controller = nil
	self.cs_controller = nil
	self.cs_section = nil
end

function local_class:on_event(e)
	return false
end

return local_class
