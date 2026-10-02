local local_class = newclass('SubStageDemonQueenController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.target_sub_quest_id = 404

	-- 세번째 주둔지 몬스터 관련
	self.is_enter_third_camp_monster_zone = false
	self.third_camp_monster_count = 6
	self.third_camp_monster_name = 'third_camp_monster_'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
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
	return false
end

function local_class:on_zone_enter_event(e)
	if self.is_enter_third_camp_monster_zone == false and
			type_util.is_zone_full_enter(e, get_party_leader(), 'third_camp_battle_1') then
		self.is_enter_third_camp_monster_zone = true
		self:remove_anim_third_camp_monster()
		return true
	end

	return false
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
	local quest_progress = user_progress:GetStartedQuest(self.target_sub_quest_id)

	-- 세번째 주둔지 몬스터 애니메이션 세팅
	self:set_third_camp_battle()

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s1_demon_queen_pos_1'),
				false, false)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_start'),
			true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_start'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s4_start'),
				true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s5_start'),
				true, true)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:set_third_camp_battle()
	for i = 1, self.third_camp_monster_count do
		local monster = get_character(self.third_camp_monster_name .. i)
		character_util.set_anim(monster, { name = 'eat' })
	end

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:remove_anim_third_camp_monster()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	for i = 1, self.third_camp_monster_count do
		local monster = get_character(self.third_camp_monster_name .. i)
		character_util.remove_anim(monster)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
