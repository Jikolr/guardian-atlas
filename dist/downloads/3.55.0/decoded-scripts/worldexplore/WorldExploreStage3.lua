--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreStage3")

function local_class:init(cs_controller, scene)
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')

	self.constants = require('worldexplore/WorldExploreConstants')

	self.num_woods = 40
	self.num_stones = 40
end



function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')
	self.world_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageLoadedEvent) then

	elseif event_type == typeof(CS.Oak.StageStartEvent) then

	elseif event_type == typeof(CS.Oak.WorldExploreStageEvent) then
		if e.Type == self.constants.event_types.start_stage_event_load then
			self:load_npc()
		elseif e.Type == self.constants.event_types.npc_interaction_start then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.npc_interaction, self, e.Unit1, e.Unit2))
		elseif e.Type == self.constants.event_types.stage_launch_ready then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_event, self))
		end
	end
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:load_resource()
	return util.cs_generator(self.stage_load_resource, self)

end

function local_class:stage_load_resource()
	coroutine.yield(music_player:PreloadMusic('ondemand/worldexplore/audio:bgm_worldexplore_lobby'))
end

function local_class:load_npc()
	local has, world_controller = stage.WorldStates:TryGetValue("controller")
	self.world_controller = world_controller
	self.world_controller:add_npc("elf", "elf", CS.UnityEngine.Vector2Int(17, 0), CS.Oak.Direction.Left, game_string:Format("we_s3_1", self.num_woods, self.num_stones), true, "unknown")
	self.world_controller:finish_stage_event_load()
end

function local_class:npc_interaction(hero_unit, npc_unit)
	coroutine.yield(self.world_controller:focus_camera_to(npc_unit:GetFieldPosition()))
	wait_for_sec(0.1)
	local offset, bd = self.world_controller:get_npc_talk_params(false)
	if self.world_controller.current_wood >= self.num_woods and self.world_controller.current_stone >= self.num_stones then
		local c = self.world_controller.npc_units[1]
		character_util.set_emotion(c, { name = "doyagao", loop = false })
		character_util.set_anim(c, { name = "victory_extra", loop = true })

		speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_2", skip = true, offset = offset, bubble_direction = bd })
		character_util.remove_anim(c, false)
		c.Direction = CS.Oak.Direction.Right
		speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_3", skip = true, offset = offset, bubble_direction = bd })

		self.world_controller:use_wood(self.num_woods)
		self.world_controller:use_stone(self.num_stones)

		music_player:PlaySfxOneShot("01_fade_out_05")
		self.world_controller:destroy_npc("elf")
		wait_for_sec(1.0)
	else
		local c = self.world_controller.npc_units[1]
		local s = game_string:Format("we_s3_1", self.num_woods, self.num_stones)

		character_util.set_emotion(c, { name = "attack", loop = false })
		character_util.set_anim(c, { name = 'release', sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(c, { key = s, skip = true, offset = offset, bubble_direction = bd })
		character_util.remove_emotion(c)
		character_util.remove_anim(c, false)
	end

	self.world_controller:finish_npc_interaction()
end

function local_class:start_event()
	coroutine.yield(self.world_controller:intro_zoom_and_fade_in(nil))
	wait_for_sec(0.2)
	local c = self.world_controller.npc_units[1]
	local s = game_string:Format("we_s3_7", self.world_controller.turn_limit,  self.num_woods, self.num_stones)

	music_player_util.play_stage_music({ name = 'ondemand/worldexplore/audio:bgm_worldexplore_lobby', state = 'event', mix = 0 })
	coroutine.yield(self.world_controller:focus_camera_to(c.Position))

	local offset, bd = self.world_controller:get_npc_talk_params(false)

	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_4", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_emotion(c, { name = "attack", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_5", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_anim(c, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_6", skip = true, offset = offset, bubble_direction = bd })
	character_util.set_emotion(c, { name = "doyagao", loop = false })
	character_util.set_anim(c, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = s, skip = true, offset = offset, bubble_direction = bd })
	character_util.set_emotion(c, { name = "attack", loop = false })
	character_util.set_anim(c, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s3_8", skip = true, offset = offset, bubble_direction = bd })

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	wait_for_sec(0.1)
	field_ui_manager:Show()
	coroutine.yield(self.world_controller:show_stage_info())
	self.world_controller:finish_start_event()

	character_util.remove_emotion(c)
	character_util.remove_anim(c, false)
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}