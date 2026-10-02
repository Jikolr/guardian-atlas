local local_class = newclass('PixyWorld2Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 412
end

function local_class:dispose()
	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 파티멤버 전투 시에만 등장 로직 / 전투 팔로우 배틀 로직
	custom_stage_option_util.register_option({
		break_in_party_member = {},
		follow_npc_battle_logic = { quest_id = 412 },
	})
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	--TODO: 해당 스타피스가 아래쪽에 파묻혀있어서 히트박스 Y축 조금 키움
	local puzzle_star_piece_name = 'puzzle_star_piece_1'
	if not stage_progress:HasStarPiece(puzzle_star_piece_name) then
		local star_piece = get_field_object(puzzle_star_piece_name)
		star_piece.Hitbox = CS.Oak.Hitbox(vector(1, 1.5, 1))
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), false, false)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
