local local_class = newclass('DreamVillage6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 441
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:load_resource()
	self:dokkaebi_setting()
end

function local_class:on_event(e)
	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	do
		local statue = get_character('statue')

		field_ui_manager:RemoveUI(statue, field_ui_type.character_stats)

		statue.SpineController.ShadowScale = statue.SpineController.ShadowScale * 2
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 23 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 24 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 25 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif quest_progress.InnerProgress == 26 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('main_s26_knight_awake_align'),
				true, true)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('left',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

--- 은하 퀘스트 세팅
function local_class:dokkaebi_setting()
	local quest_progress = user_progress:GetStartedQuest(451)
	if quest_progress == nil or not quest_progress.IsComplete then
		return
	end

	--나리 (left, tired, cross_arm) : 겨우 하루 지났는데 무슨 수련? 뭐 잘 지냈다니까 됐어!
	local nari = get_character('nari')
	field_object_util.set_active_state(nari, active_state_type.enabled)
	character_util.set_direction(nari, 'left')
	nari.Interactable.Talk = 'dv_dokkaebi_stage_6_oneline_3'

	--은하 (left, smile, sing) : 오랫만입니다 신선님! $name 도사님과 수련을 했더니, 시간 가는 줄 몰랐네요!
	local dokkaebi = get_character('dokkaebi')
	dokkaebi.Position = nari.Position + vector(1, 0, 0)
	character_util.set_direction(dokkaebi, 'left')
	scene_util.set_emotion(dokkaebi, self, 'smile')
	scene_util.set_anim(dokkaebi, self, 'sing')
end

return local_class
