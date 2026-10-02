local local_class = newclass('NightmareLilithTower5Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.sewerage_field = 'sewerage_field'
	self.main_quest_controller_name = 'NightmareLilithTowerMainController'

	self.main_quest_id = 380
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	
	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

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
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.sewerage_field) then
		local bgm_name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_event_7'
		music_player_util.play_stage_music({ name = bgm_name, state = 'event' })

		local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		
		if not main_quest_progress.IsComplete and main_quest_progress.InnerProgress > 9 then
			local main_quest_event_controller = get_quest_event_controller(self.main_quest_controller_name)
			main_quest_event_controller:stop_stage_5_loop_sound()
		end
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, self.sewerage_field) then
		local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		local is_main_complete = quest_progress.IsComplete
		local should_play_field_bgm = quest_progress.InnerProgress < 10

		if is_main_complete or should_play_field_bgm then
			music_player_util.play_stage_music({ state = 'field' })
		else
			music_player_util.play_stage_music({ state = 'muted'})
			
			local main_quest_event_controller = get_quest_event_controller(self.main_quest_controller_name)
			main_quest_event_controller:play_stage_5_loop_sound(0.8, 1)
		end
	end
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

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
			false, false)
	elseif quest_progress.InnerProgress == 9 then
		local should_start_from_boss_battle = lua_helper.get_conditional_value(
			quest_util.get_custom_state(quest_progress, 'should_start_from_boss_battle') ~= -1,
			true,
			false
		)

		if should_start_from_boss_battle then
			stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
			false, false)
		else
			--stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
			--true, true)
			self:custom_launch_routine()
		end

	elseif quest_progress.InnerProgress == 10 then
		self:custom_launch_routine()
	else
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
			true, true)
	end
end

-- 이벤트성 배경음 때문에 커스텀하게 만들어놓음.
function local_class:custom_launch_routine()
	party_util.align_party(field_util.get_marker_pos('default_start'), 'up', 0, 'linear')

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	music_player:PlayStageIntroMusic()
	CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name), 1)
		
	music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim(user_party.Leader, { name = 'victory_get', loop = false })

	wait_for_sec(1.5)

	character_util.remove_anim(user_party.Leader)
	character_util.set_direction(user_party.Leader, 'down')
		
	character_util.remove_anim_and_emotion(user_party.Leader)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	party_util.reset_controllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
