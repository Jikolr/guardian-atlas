local local_class = newclass('QueenCastleLifeSavingController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 서브 퀘스트 id
	self.quest_id = 340

	self.is_stage_exit = false
end

function local_class:load_resource()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.pre_setting, self)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(_)
end

function local_class:on_stage_end_event(_)
	self.is_stage_exit = true
end

--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	local quest_progress = user_progress:GetStartedQuest(self.quest_id)

	-- 시작 연출 관리
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field:GetMarker('default_start').position, true, true)
	elseif quest_progress.InnerProgress <= 0 then
		-- 1섹션은 강제 이벤트
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, false, false)
	elseif quest_progress.InnerProgress > 0 then
		local section_num = quest_progress.InnerProgress + 1
		local pos = field_util.get_marker_pos('start_marker_' .. section_num)
		local dir = field_util.get_marker_dir('start_marker_' .. section_num)
		stage_launch_util.play_launch_stage(dir, pos, true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
