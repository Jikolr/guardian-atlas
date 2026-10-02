local local_class = newclass('DemonShireBgmSystemController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.bgm_zone_name = 'sewer_bgm_zone'
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self:stop_sewer_bgm()

	self.cs_controller = nil
	self.scene = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.bgm_zone_name then
				self:play_sewer_bgm()

				return true
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
			if e.Zone.Name == self.bgm_zone_name then
				self:stop_sewer_bgm(true)

				return true
			end
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'bgm' then
		if e:GetParamAt(1) == 'play' then
			self:play_sewer_bgm()
		elseif e:GetParamAt(1) == 'stop' then
			local param = e:GetParamAt(2)
			local is_play_bgm = false

			if param then
				if param == 'true' then
					is_play_bgm = true
				end
			end
			self:stop_sewer_bgm(is_play_bgm)
		end
	end

	return false
end


--region bgm
function local_class:play_sewer_bgm()
	music_player_util.play_stage_music({ state = 'muted',mix = 1 })
	music_player_util.remove_stage_music_clip({ state = 'field' })

	self:stop_sewer_bgm()

	self.background_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_cave_01', loop = true,
													   type_priority = 'loop',
													   player_priority = 'default' })
end

function local_class:stop_sewer_bgm(is_play_bgm)
	if is_play_bgm then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			music_player_util.set_stage_music_clip_async({
				name = 'ondemand/v2_39_demonshire/audio:bgm_demonshire_main', state = 'field'
			})
			music_player_util.play_stage_music({ state = 'field' })
		end))
	end

	if self.background_sfx then
		self.background_sfx:FadeOut(1)
		self.background_sfx = nil
	end
end
--endregion
return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
