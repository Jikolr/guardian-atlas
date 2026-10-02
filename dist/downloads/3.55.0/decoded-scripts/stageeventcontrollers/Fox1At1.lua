local local_class = newclass("Fox1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.sec_end = true
	self.ruin_color = CS.UnityEngine.Color(0.4, 0.4, 0.8, 1)
	self.tint_key = 'ruin_color'

	self.is_tint_on = false

	self.rain_sfx = nil

	self.stg_start = false

	self.rain_ground_effect_1 = nil
	self.rain_ground_effect_2 = nil
	self.rain_ground_effect_3 = nil
	self.rain_ground_effect_4 = nil

	self.rain_screen_effect = nil

	self.is_in_vil = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_hit')
	unity_object_pool.GetOrCreate('fx_event_fox_portal_garam_portal_action')
	unity_object_pool.GetOrCreate('fx_event_fox_portal_garam_atk')
	unity_object_pool.GetOrCreate('FX_Blockaura_Char_black')

	unity_object_pool.GetOrCreate('fx_env_fox_rain_screen_fx')
	unity_object_pool.GetOrCreate('fx_env_fox_rain_ripple_ground')


	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bg_on, self))

	return
end

function local_class:need_on_launch()
	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)

	local statue_nari = get_character('statue_nari')
	local statue_garam = get_character('statue_garam')

	statue_nari.transform.localScale = vector(1.5, 1.5, 1.5)
	statue_garam.transform.localScale = vector(1.5, 1.5, 1.5)

	statue_nari.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	statue_nari.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(statue_nari, CS.Oak.FieldUiType.CharacterStats)

	statue_garam.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	statue_garam.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(statue_garam, CS.Oak.FieldUiType.CharacterStats)

	if q ~= nil and q.InnerProgress < 5 and not q.IsComplete then
		return true
	else
		character_util.set_active_state(get_character('nari'), 'disabled')
	end
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)


	--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.civil_really_fight_for_land, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self, q.InnerProgress))

end

function local_class:ruin_tint(is_zone_enter)

	if is_zone_enter then
		field:Tint(self.tint_key, self.ruin_color, 0)
		self.is_tint_on = true
	else
		field:RemoveTint(nil, 0)
		self.is_tint_on = false
	end

end

function local_class:bg_on()
	local res_holder = CS.Foundations.ResourceHolder()
	local bg = load_util.load_prefab_async(res_holder, 'ondemand/fox/tilesets', 'bg_fox')
	bg.transform.position = vector(-104.5, 0, -10)
end

function local_class:on_launch_routine(num)
	if num < 3 then
		music_player_util.play_stage_music({name = 'ondemand/fox/audio:bgm_fox_flashback', state = 'field', mix = 2})
	else
		self.is_in_vil = true
	end

	if num == 4 then
		local old = get_character('old_man')
		local start_marker = field:GetMarker('default_start')

		character_util.set_position(old, vector(0, 0, 3))

		local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(old, user_party, 0, 0, false)
		old:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
		old.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
		screen_util.fade_in_circular(1, 'ease_in_out_sine')

		coroutine.yield(
			CS.Oak.CommonScreenplay.DirectionalStageEntry(start_marker.position, CS.Oak.Direction.Down, game_string:GetString(stage.Name)))
	end
	if num >= 0 and num <= 4 then
		local clear_flag = get_field_object('fox_1_1_clear_flag')
		character_util.set_active_state(clear_flag, 'disabled')
	end
end

function local_class:civil_really_fight_for_land()


	local vil_1 = get_character('vil_npc1')
	local vil_2 = get_character('vil_npc2')
	local vil_3 = get_character('vil_npc3')

	character_util.set_position(vil_1, vector(-2, 0, -23))
	character_util.set_position(vil_2, vector(1, 0, -24))
	character_util.set_position(vil_3, vector(-0.5, 0, -21))

	character_util.spine_set_alpha_fade(vil_1, 0.5, 0)
	character_util.spine_set_alpha_fade(vil_2, 0.5, 0)
	character_util.spine_set_alpha_fade(vil_3, 0.5, 0)

	vil_1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	vil_2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	vil_3.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
end

function local_class:dispose()
	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	if self.rain_sfx ~= nil then
		self.rain_sfx:Stop()
	end

	self.sec_end = false
	self.sec_end = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)

	if event_type == typeof(CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then

		if e.Zone.Name == 's5_vil' and	self.is_tint_on == false and q.InnerProgress >= 3  then
			self:ruin_tint(true)
			self:rain()

		elseif e.Zone.Name == 's5_tree_above' and self.is_tint_on == false then
			self:ruin_tint(false)
			self.is_in_vil = false
			if self.rain_ground_effect_1 ~= nil then
				self.rain_ground_effect_1:Dispose()
			end

			if self.rain_ground_effect_2 ~= nil then
				self.rain_ground_effect_2:Dispose()
			end

			if self.rain_ground_effect_3 ~= nil then
				self.rain_ground_effect_3:Dispose()
			end

			if self.rain_ground_effect_4 ~= nil then
				self.rain_ground_effect_4:Dispose()
			end

			if self.rain_screen_effect ~= nil then
				self.rain_screen_effect:Dispose()
			end

			self.rain_ground_effect_1 = nil
			self.rain_ground_effect_2 = nil
			self.rain_ground_effect_3 = nil
			self.rain_ground_effect_4 = nil
			self.rain_screen_effect = nil

			if self.rain_sfx ~= nil then
				self.rain_sfx:Stop()
				self.rain_sfx = nil
			end

		end

	end

	if event_type == typeof(CS.Oak.ZoneLeaveEvent) and e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == 's5_vil' and	self.is_tint_on == true then
			self:ruin_tint(false)
		end
	end

	if event_type == typeof(CS.Oak.CameraGridEnterEvent) and self.is_in_vil == true and q.InnerProgress >= 3 then
		self:rain()
	end
	return false
end


function local_class:rain()
	if self.rain_screen_effect ~= nil then
		self.rain_screen_effect:Dispose()
	end

	self.rain_screen_effect = unity_object_pool.GetOrCreate('fx_env_fox_rain_screen_fx'):Instantiate(unity_class.vector3.zero)
	self.rain_screen_effect.transform:SetParent(stage_camera.Transform.parent)
	self.rain_screen_effect.transform.localPosition = unity_class.vector3.zero

	if self.rain_ground_effect_1 ~= nil then
		self.rain_ground_effect_1:Dispose()
		self.rain_ground_effect_2:Dispose()
		self.rain_ground_effect_3:Dispose()
		self.rain_ground_effect_4:Dispose()
	end

	self.rain_ground_effect_1 = unity_object_pool.GetOrCreate('fx_env_fox_rain_ripple_ground'):Instantiate(user_party_leader.Position + vector(-10, 0, -10))
	self.rain_ground_effect_2 = unity_object_pool.GetOrCreate('fx_env_fox_rain_ripple_ground'):Instantiate(user_party_leader.Position + vector(-10, 0, 10))
	self.rain_ground_effect_3 = unity_object_pool.GetOrCreate('fx_env_fox_rain_ripple_ground'):Instantiate(user_party_leader.Position + vector(10, 0, -10))
	self.rain_ground_effect_4 = unity_object_pool.GetOrCreate('fx_env_fox_rain_ripple_ground'):Instantiate(user_party_leader.Position + vector(10, 0, 10))

	if self.rain_sfx == nil then
		self.rain_sfx = music_player_util.play_sfx({ sfx_name = '01_rain_loop_01', loop = true, fade_in_time = 2, type_priority = "default"})
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}