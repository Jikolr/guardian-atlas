local local_class = newclass('SectionName')

function local_class:init(controller, quest_spec)
	self.controller = controller
	self.quest_spec = quest_spec

	-- 이 섹션이 유효한 스테이지 이름. 여러 스테이지에서 처리가 필요하다면 스트링 테이블로 넣을 것
	-- 지정하지 않는 경우(nil일 때)에는 현재 스테이지와 관계없이 항상 유효한 것으로 판단
	--self.available_stage_name = 'blabla_1_1'

	-- 섹션 내 커스텀한 스테이트가 필요한 경우 아래 주석 풀고 사용할 것
	-- 섹션 내 스테이트 Enum
	--self.section_state = {
	--	blabla = 1,
	--}
	--
	--self.current_section_state = self.section_state.blabla
end

function local_class:enter()

end

function local_class:start()

end

function local_class:exit()

end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:dispose()
	self.controller = nil
	self.quest_spec = nil
end

return local_class
