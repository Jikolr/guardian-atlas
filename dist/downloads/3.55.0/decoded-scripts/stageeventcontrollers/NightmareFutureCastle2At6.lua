local local_class = newclass("NightmareFutureCastle2At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_bob_marker = function() return field:GetMarker('bob_linda').position end

	self.get_bob = function() return get_character('bob') end
	self.get_linda = function() return get_character('linda') end
	self.get_invader = function(num) return get_character('bob_linda_invader_' .. num) end

	self.main_quest = user_progress:GetStartedQuest(217)

	self.is_cleared_main_quest = false
	self.is_seen_bob = false
	self.stop_linda_cor = false

	self.battle_2_on = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	quest_util.load_pool_resource(
			'FX_Event_InvaderBeam',
			'FX_Common_Jump_small'
	)

	if self.main_quest ~= nil and self.main_quest.IsComplete then
		self.is_cleared_main_quest = true
	end

	local res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			res_holder, 'backgrounds/prologue', 'prologue_background', function(prefab)
				local bg_object = CS.UnityEngine.GameObject.Instantiate(prefab)
				local bg_transform = bg_object.transform
				bg_transform.parent = stage_camera.Transform
				bg_transform.localPosition = vector(0, 0, 0)

				local bg_scroller = bg_object:GetComponent(typeof(CS.BackgroundScroller))
				bg_scroller.CameraToAttach = stage_camera.Camera
				bg_scroller.DeactivatedZoneNames = {'deactive'}
				bg_scroller:Init()
			end)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) or e.FullEnter == false then
		return false
	end

	local zone = e.Zone.Name

	if zone == 'bob_linda_zone' and self.is_seen_bob == false and self.is_cleared_main_quest == false then
		sp_util.play_normal_screenplay(self.bob_linda_event, self)
		return true
	elseif zone == 'BATTLE_2' and self.battle_2_on == false then
		self.battle_2_on = true
		message_system:Publish(CS.Oak.DoorCloseEvent.Create('battle_door_2', false))
		message_system:Publish(CS.Oak.DoorCloseEvent.Create('battle_door_3', false))
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object('chest_red_1')) then

		sp_util.play_normal_screenplay(function()
			speech_bubble_util.show_speech_bubble_async(user_party.Leader,
					{ key = game_string:Format('nightmare_futurecastle_2_stage_6_chest', user.Name), skip = true })
			--이건 {0}에게 양보하자.
		end)

		return true
	end

	return false
end

--endregion

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	self.stop_linda_cor = true
	self.cs_controller = nil
end

-- 밥 린다 이벤트
function local_class:bob_linda_event()
	local bob = self.get_bob()
	local linda = self.get_linda()
	local invader_1 = self.get_invader(1)
	local invader_2 = self.get_invader(2)

	self.is_seen_bob = true
	camera_util.move_async(self.get_bob_marker() + vector(-4,0,1.5), 1)

	camera_util.shake(0.1, 0.5)
	music_player_util.play_sfx_one_shot('01_villain_scream_03')
	-- 으아아악!!!!
	speech_bubble_util.show_speech_bubble(bob, { key = 'futurecastle_part2_bob_and_linda_1', world_pos =
	self.get_bob_marker() + vector(-5, 0, 0.5), skip = false, bubble_type = 'shout', scale = 2, type_speed = 0, life_time = 0.7  })

	bob.Position = self.get_bob_marker() + vector(0,20,0)
	character_util.set_anim_and_emotion(bob, { name = 'prostrate' }, { name = 'damaged'})
	wait_for_sec(0.5)

	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_emotion(user_party.Leader, { name = 'attack' })
	character_util.show_emoticon(user_party.Leader, nil, 'notice')

	local fall_down_sfx = music_player_util.play_sfx({ sfx_name = '01_fall_down_01', loop = true, type_priority = 'loop', player_priority = 'npc' })

	character_util.spine_rotate(bob, 1440, 1)
	character_util.move_to_async(bob, self.get_bob_marker(), 1, nil, false, false)
	fall_down_sfx:Stop()
	music_player_util.play_sfx_one_shot('03_mech_stomp_01')

	character_util.set_emotion(bob, { name = 'confused' })
	unity_object_pool.GetOrCreate('FX_Common_Jump_small'):Instantiate(bob.Position + vector(-0.2,0,0))
	unity_object_pool.GetOrCreate('FX_Common_Jump_small'):Instantiate(bob.Position + vector(0.2,0,0))

	camera_util.shake(0.2, 0.3)

	wait_for_sec(1)

	linda.Position = self.get_bob_marker() + vector(6,0,2)

	character_util.set_emotion(linda, { name = 'attack' })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wait_for_sec(0.5)
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')

		-- 밥!!!
		speech_bubble_util.show_speech_bubble(linda, { key = 'futurecastle_part2_bob_and_linda_2', skip = false, type_speed = 0 })
	end))

	local dash_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = linda, loop = true, type_priority = 'loop', player_priority = 'npc' })
	character_util.move_waypoint_async(linda, { self.get_bob_marker() + vector(-6,0,2),
												self.get_bob_marker() + vector(-6,0,0),
												self.get_bob_marker() + vector(-0.6,0,0) }, 7, true, nil, nil)
	dash_sfx:Stop()

	local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true, type_priority = 'loop', player_priority = 'npc' })
	character_util.set_anim(linda, { name = 'eat' })
	-- 밥! 괜찮아? 눈 좀 떠봐!
	speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_3', skip = true })

	wait_for_sec(0.3)

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.remove_emotion(bob)
	character_util.set_anim(bob, { name = 'hurt' })

	wait_for_sec(0.5)

	equipping_sfx:Stop()
	character_util.set_anim(linda, { name = 'cast' })
	character_util.set_emotion(linda, { name = 'tired' })
	-- 휴… 다행이다…
	speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_4', skip = true })

	wait_for_sec(1)

	message_system:Publish(CS.Oak.DoorCloseEvent.Create('bob_linda_door', false))

	character_util.remove_anim(linda)
	character_util.normal_jump(linda)
	character_util.set_direction(linda, 'left')
	character_util.set_emotion(linda, { name = 'attack' })

	music_player_util.play_sfx_one_shot('01_invader_beam_01')
	character_util.set_direction(invader_1, 'right')
	invader_1.Position = self.get_bob_marker() + vector(-2,0,-1)
	unity_object_pool.GetOrCreate('FX_Event_InvaderBeam'):Instantiate(invader_1.Position)

	wait_for_sec(0.3)

	music_player_util.play_sfx_one_shot('01_invader_beam_01')
	character_util.set_direction(invader_2, 'right')
	invader_2.Position = self.get_bob_marker() + vector(-3,0,0)
	unity_object_pool.GetOrCreate('FX_Event_InvaderBeam'):Instantiate(invader_2.Position)

	wait_for_sec(1)


	local is_swing = true
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		wait_for_sec(0.3)
		while is_swing do
			music_player_util.play_sfx_one_shot('01_swing_01')
			wait_for_sec(0.5)
		end
	end))
	character_util.set_anim(linda, { name = 'attack' })
	-- 언제 여기까지!
	speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_5', skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	-- 밥과 나를 건드릴 생각 하지마!
	speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_6', skip = true })
	-- 훠이-! 훠이-! 저리 가!
	speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_7', skip = true })

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.linda_cor, self))

	is_swing = false
	character_util.remove_emotion(user_party.Leader)
	camera_util.return_to_leader(0.5)
end

-- 린다 대사 코루틴
function local_class:linda_cor()
	local linda = self.get_linda()

	while self.stop_linda_cor == false do
		wait_for_sec(3)
		-- 훠이-! 훠이-! 저리 가!
		speech_bubble_util.show_speech_bubble_async(linda, { key = 'futurecastle_part2_bob_and_linda_7', skip = false })

		coroutine.yield(nil)
	end
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
