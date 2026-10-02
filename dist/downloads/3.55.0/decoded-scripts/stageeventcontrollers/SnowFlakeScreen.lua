local local_class = newclass('SnowFlakeScreenController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.snow_wind_preset_name = 'fx_expedition_snow_wind'
	self.snow_wind_sfx_name = '01_blizzard_03'
	self.mix = 0
	self.mix_duration = 0
	self.current_volume = 0.1
	self.prev_volume = 0
	self.target_volume = 0
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.snow_wind_preset_name)
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.ExpeditionEndEvent), 'on_expedition_end_event')
end

function local_class:on_stage_loaded_event(_)
	self.snow_fx = unity_object_pool.GetOrCreate(self.snow_wind_preset_name):Instantiate(stage_camera.LookAtPosition,
			unity_class.quaternion.identity, stage_camera.transform)

	self:set_sfx_mix(1.0, 3.0)
	self.snow_sfx = music_player_util.play_sfx({sfx_name = self.snow_wind_sfx_name, fade_in_time = 3, loop = true,
												type_priority = 'loop', volume = self.current_volume})
	message_system:SubscribeOnce(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent), 'on_expedition_monster_spawn_event')
end

function local_class:on_expedition_monster_spawn_event(_)
	self:set_sfx_mix(0.5, 2.0)
end

function local_class:on_expedition_end_event(_)
	self:set_sfx_mix(1.0, 2.0)
	message_system:Subscribe(self, typeof(CS.Oak.UI.UiOverlayPushEvent), 'on_ui_overlay_push_event')
end

function local_class:on_ui_overlay_push_event(_)
	if not CS.Oak.UI.ExpeditionStageClear.Instance then
		return
	end
	self:set_sfx_mix(0.0, 0.0)
	if self.snow_sfx then
		self.snow_sfx:FadeOut(3)
	end
	message_system:Unsubscribe(self, typeof(CS.Oak.UI.UiOverlayPushEvent))
end

function local_class:set_sfx_mix(volume, time)
	self.mix_duration = time
	self.mix = time
	self.prev_volume = self.current_volume
	self.target_volume = volume
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame(dt)
	if self.snow_sfx == nil or self.mix <= 0 then
		return
	end

	self.mix = self.mix - dt
	self.current_volume = unity_class.mathf.Lerp(self.target_volume, self.prev_volume, self.mix / self.mix_duration)
	self.snow_sfx.Volume = self.current_volume
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionMonsterSpawnedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.UI.UiOverlayPushEvent))
	if self.snow_fx then
		self.snow_fx:Dispose()
	end
	self.snow_fx = nil
	self.snow_sfx = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
