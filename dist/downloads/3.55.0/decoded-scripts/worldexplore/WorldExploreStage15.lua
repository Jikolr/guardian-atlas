--- 월드 탐험 게임 컨트롤러
local local_class = newclass("WorldExploreStage15")

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
			--self.world_controller:default_start_event()
		elseif e.Type == self.constants.event_types.ending_ready then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ending_event, self))
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
	self.world_controller.current_enemy_gold = 100
	self.world_controller.has_custom_ending = true
	self.world_controller:add_npc("ailie", "ailie", CS.UnityEngine.Vector2Int(0, 8), CS.Oak.Direction.Down, "none", false, "unknown")

	if user_util.has_knight_male() then
		get_character("knight_female").ActiveState = CS.Oak.ActiveState.Disabled
	else
		get_character("knight_male").ActiveState = CS.Oak.ActiveState.Disabled
	end

	self.world_controller:finish_stage_event_load()
end

function local_class:npc_interaction(hero_unit, npc_unit)
	wait_for_sec(1.0)
	self.world_controller:finish_npc_interaction()
end


function local_class:start_event()
	local c = self.world_controller.npc_units[1]
	c.Direction = CS.Oak.Direction.Up

	local units = stage.Units
	local boss_unit = nil
	for i = 0, units.Count - 1 do
		if units[i].Faction == CS.Oak.WorldExploreStageFaction.Enemy and units[i].IsBoss then
			self.world_controller:hide_unit(units[i])
			boss_unit = units[i]
			break
		end
	end

	local hero_unit = self.world_controller:get_hero_unit_from_stage(0)
	coroutine.yield(self.world_controller:intro_zoom_and_fade_in(c.Position))
	wait_for_sec(0.2)

	music_player_util.play_stage_music({ name = 'ondemand/worldexplore/audio:bgm_worldexplore_lobby', state = 'event', mix = 0 })
	wait_for_sec(0.2)

	local offset, bd = self.world_controller:get_npc_talk_params(false)

	character_util.set_anim(c, { name = 'success', loop = true })
	music_player:PlaySfxOneShot("03_dialogue_positive_01")
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s15_1", skip = true, offset = offset, bubble_direction = bd })

	c.Direction = CS.Oak.Direction.Down
	character_util.set_emotion(c, { name = "doyagao" })
	character_util.set_anim(c, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s15_2", skip = true, offset = offset, bubble_direction = bd })

	c.Direction = CS.Oak.Direction.Up
	character_util.set_anim(c, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s15_3", skip = true, offset = offset, bubble_direction = bd })

	coroutine.yield(self.world_controller:focus_camera_to(vector(0, 0, 24)))
	wait_for_sec(0.25)
	self.world_controller:reinforce_unit(boss_unit)
	wait_for_sec(1.25)
	coroutine.yield(self.world_controller:focus_camera_to(c.Position))
	wait_for_sec(0.25)

	c.Direction = CS.Oak.Direction.Down
	character_util.set_emotion(c, { name = "smile", loop = false })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s15_4", skip = true, offset = offset, bubble_direction = bd })

	character_util.set_anim(c, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(c, { key = "we_s15_5", skip = true, offset = offset, bubble_direction = bd })

	character_util.remove_anim(c, false)
	music_player:PlaySfxOneShot("01_fade_out_05")
	self.world_controller:destroy_npc("ailie")
	wait_for_sec(1.0)

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	wait_for_sec(0.1)
	field_ui_manager:Show()
	coroutine.yield(self.world_controller:show_stage_info())
	self.world_controller:finish_start_event()
end

function local_class:ending_event()
	local elf1 = get_character("elf_1")
	local elf2 = get_character("elf_2")
	local elf6 = get_character("elf_6")
	local knight = nil

	if user_util.has_knight_male() then
		knight = get_character("knight_male")
	else
		knight = get_character("knight_female")
	end

	local girl = get_character("ailie_ending")

	self.world_controller.camera_controller:DeactivateTouch()
	coroutine.yield(nil)

	stage_camera:Move(field:GetMarker("ending_marker").position, 0, nil)

	music_player_util.play_stage_music({ state = 'muted', mix = 0.5 })
	wait_for_sec(1.0)

	screen_util.fade_out_circular_async(0, "linear")
	screen_util.fade_in_async(0, unity_class.color.black, "linear")

	stage_camera:ResizeToDefault(0)
	coroutine.yield(nil)
	screen_util.fade_in_circular_async(1, "linear")
	music_player_util.play_stage_music({ name = 'bgm_sealed_castle', state = 'event', mix = 0 })
	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(elf2, { key = "we_s15_6", skip = true })
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_7", skip = true })


	music_player:PlaySfxOneShot("03_dialogue_positive_01")
	character_util.set_emotion(girl, { name = "smile", loop = false })
	character_util.set_anim(girl, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_8", skip = true })

	character_util.set_anim(girl, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_9", skip = true })

	character_util.set_anim(girl, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_10", skip = true })

	character_util.set_emotion(girl, { name = "tired", loop = false })
	character_util.set_anim(girl, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_11", skip = true })
	character_util.remove_emotion(girl)


	character_util.set_emotion(elf1, { name = "sad", loop = false })
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_12", skip = true })
	character_util.remove_emotion(elf1)
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_13", skip = true })
	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_14", skip = true })
	speech_bubble_util.show_speech_bubble_async(elf2, { key = "we_s15_15", skip = true })
	speech_bubble_util.show_speech_bubble_async(elf2, { key = "we_s15_16", skip = true })
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_17", skip = true })

	character_util.set_emotion(girl, { name = "tired", loop = false })
	character_util.set_anim(girl, { name = 'idle', loop = true })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_18", skip = true })
	character_util.set_anim(girl, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_19", skip = true })

	music_player:PlaySfxOneShot('03_dialogue_ready_01')
	speech_bubble_util.show_speech_bubble_async(elf1, { key = "we_s15_20", skip = true })

	character_util.set_emotion(girl, { name = "smile", loop = false })
	character_util.set_anim(girl, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_21", skip = true })

	character_util.set_emotion(girl, { name = "doyagao", loop = false })
	character_util.set_anim(girl, { name = 'cast', loop = true })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_22", skip = true })

	girl.Direction = CS.Oak.Direction.Right
	character_util.set_emotion(girl, { name = "smile", loop = false })
	character_util.set_anim(girl, { name = 'sing', loop = true })
	speech_bubble_util.show_speech_bubble_async(girl, { key = "we_s15_23", skip = true })

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	music_player:PlaySfxOneShot("01_stage_clear_01")
	screen_util.fade_out_circular_async(1.0, "linear")

	screen_util.fade_out_async(0, unity_class.color.black, "linear")
	screen_util.fade_in_circular_async(0, "linear")

	self.world_controller:finish_ending_event()
end



return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}