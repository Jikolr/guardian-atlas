local local_class = newclass('DemonShirePyramidNpcController')

-- 챕터 14 메인 퀘스트 회차별 피라미드 스테이지 NPC를 관리하는 컨트롤러
-- 원라인 Npc 위치 방향 / 피라미드 로얄가드 배치 등
function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 회차별 npc 세팅을 위한 state 값
	self.npc_setting_state = {
		none = 1,
		first = 2,
		second = 3,
		third = 4,
	}
	self.cur_npc_setting_state = self.npc_setting_state.none

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	-- 고정된 로얄가드 가져오기
	self.get_fixed_guard = function(index) return get_character('fixed_guard_' .. index) end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_custom_stage_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if stage.Name == 'demonshire_1_3' then
		-- 0회차 피라미드 (3스테이지) 입장 했을 때
		self.cur_npc_setting_state = self.npc_setting_state.none

		--TODO: 후에 원라인 배치관련 추가 필요

		-- 로얄가드 배치 관련
		if main_quest_progress ~= nil and main_quest_progress.IsComplete == false
				and main_quest_progress.InnerProgress == 7 then
			-- 메인퀘스트 7섹션일 때만 로얄가드 배치
			self:set_royal_guard_npc()
		end
	end

	return false
end

-- 시작할 때 로얄가드 배치하는 함수
function local_class:set_royal_guard_npc()
	if self.cur_npc_setting_state == self.npc_setting_state.none then
		-- 0회차 로얄가드 배치

		-- 가만히 서있는 로얄가드 8명 배치
		self:set_fixed_royal_guard()
	end
end

-- 고정된 로얄 가드를 배치하는 함수
function local_class:set_fixed_royal_guard()
	if self.cur_npc_setting_state == self.npc_setting_state.none then
		-- 0회차 일 때
		-- 가만히 서있는 로얄가드 8명 배치
		local fixed_guard_count = 8
		local pos_list = {
			vector(-111.5, 0, 17), vector(-109.5, 0, 17), vector(-97, 0, 7.5),
			vector(-97, 0, 5.5), vector(-113.5, 0, 23), vector(-113.5, 0, 20),
			vector(-107.5, 0, 23), vector(-107.5, 0, 20),
		}
		for i = 1, fixed_guard_count do
			local guard = self.get_fixed_guard(i)
			character_util.set_position(guard, pos_list[i])
			character_util.set_active_state(guard, 'enabled')
			guard:OnEvent(CS.Oak.StateResetEvent.Instance)
		end
	elseif self.cur_npc_setting_state == self.npc_setting_state.first then
		-- 1회차 일 때
	end
end

-- 배회하는 로얄 가드를 배치 하는 함수
-- 배회하는 로얄 가드들은 특정 이벤트가 날라 왔을 때 스테이트 리셋
function local_class:set_moving_royal_guard()
	if self.cur_npc_setting_state == self.npc_setting_state.none then
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
