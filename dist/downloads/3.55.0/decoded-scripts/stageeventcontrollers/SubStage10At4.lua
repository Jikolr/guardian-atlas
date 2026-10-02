local local_class = newclass("SubStage10At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.is_tint = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	return
end

function local_class:need_on_launch()
	local yuze_quest = user_progress:GetStartedQuest(168)
	return yuze_quest ~= nil and yuze_quest.InnerProgress == 1 and not yuze_quest.IsComplete
end

function local_class:on_launch(_)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	sp_util.play_normal_screenplay(self.on_launch_routine, self)
end

function local_class:on_launch_routine()
	local default_start_marker = field:GetMarker('wake_up')
	party_util.align_party(default_start_marker.position + vector(0, 0, -1), 'up', 0, 'linear')
	wait_for_sec(1)

	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.EaseInOutSine)
	party_util.align_party(default_start_marker.position + vector(0, 0, -1.5), 'up', 0.5, 'linear')

	music_player:PlayStageIntroMusic()
	music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
	CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name))

	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim_and_emotion(user_party.Leader, {name = 'victory_get', loop = false}, {name = 'smile'})
	wait_for_sec(0.5)
	music_player.StageBgmState = CS.Oak.StageBgmState.Field
	wait_for_sec(1)
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.set_direction(user_party.Leader, 'down')
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		return self:on_custom_stage_event(e)
	end
	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params[0] == 'screen_tint_white' then
		if self.is_tint then
			return false
		end
		self.is_tint = true
		if e.Params[1] == 'immediate' then
			field:Tint('green_fog_after', unity_color({1, 1, 1, 0.1 }), 0)
		else
			field:Tint('green_fog_after', unity_color({1, 1, 1, 0.1 }), 1)
		end
		return true
	elseif e.Params[0] == 'remove_tint_white' then
		if not self.is_tint then
			return false
		end
		self.is_tint = false
		if e.Params[1] == 'immediate' then
			field:RemoveTint('green_fog_after', 0)
		else
			field:RemoveTint('green_fog_after', 1)
		end
		return true
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	field:RemoveTint('green_fog_after', 0)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}