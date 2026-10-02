--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreStage12")

function local_class:init(cs_controller, scene)
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.WorldExploreStageEvent), 'on_event')

	self.constants = require('worldexplore/WorldExploreConstants')
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
end

function local_class:load_npc()
	local has, world_controller = stage.WorldStates:TryGetValue("controller")
	self.world_controller = world_controller
	self.world_controller:add_npc("eva", "eva", CS.UnityEngine.Vector2Int(1, 2), CS.Oak.Direction.Left, "none", false, "unknown")
	self.world_controller:finish_stage_event_load()
end

function local_class:npc_interaction(hero_unit, npc_unit)
	wait_for_sec(1.0)
	self.world_controller:finish_npc_interaction()
end


function local_class:start_event()
	local c = self.world_controller.npc_units[1]
	local hero_unit = self.world_controller:get_hero_unit_from_stage(0)
	coroutine.yield(self.world_controller:intro_zoom_and_fade_in(c.Position))
	wait_for_sec(0.2)

	music_player_util.play_stage_music({ name = 'ondemand/worldexplore/audio:bgm_worldexplore_lobby', state = 'event', mix = 0 })
	wait_for_sec(0.2)

	local offset, bd = self.world_controller:get_npc_talk_params(false)

	character_util.set_anim(c, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_1", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_anim(c, { name = 'salute', loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_2", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_anim(c, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_3", skip = true, offset = offset, bubble_direction = bd })

	coroutine.yield(self.world_controller:focus_camera_to(hero_unit:GetFieldPosition()))
	wait_for_sec(0.5)

	character_util.set_anim(c, { name = 'release', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_4", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_emotion(c, { name = "tired", loop = false })
	character_util.set_anim(c, { name = 'cross_arm', loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_5", skip = true, offset = offset, bubble_direction = bd })


	coroutine.yield(self.world_controller:focus_camera_to(vector(0, 0, 11)))
	wait_for_sec(1.5)
	coroutine.yield(self.world_controller:focus_camera_to(c.Position))
	wait_for_sec(0.25)

	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_6", skip = true, offset = offset, bubble_direction = bd })

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	character_util.set_emotion(c, { name = "attack", loop = false })
	character_util.set_anim(c, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_7", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_anim(c, { name = 'idle', loop = true })
	character_util.remove_emotion(c)
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_8", skip = true, offset = offset, bubble_direction = bd })


	character_util.set_emotion(c, { name = "smile", loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_9", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_anim(c, { name = 'salute', loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s12_10", skip = true, offset = offset, bubble_direction = bd })

	music_player:PlaySfxOneShot("01_fade_out_05")
	self.world_controller:destroy_npc("eva")
	wait_for_sec(1.0)

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	wait_for_sec(0.1)
	field_ui_manager:Show()
	coroutine.yield(self.world_controller:show_stage_info())
	self.world_controller:finish_start_event()
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}