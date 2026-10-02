local local_class = newclass('NightmareDemonWorld1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.get_philosopher = function() return get_character('philosopher') end

	self.get_philosopher_marker = function(num) return field:GetMarker('philosopher_pos_' .. num).position end

	self.playing_philosopher_event = false

	self.philosopher_zone = 'philosopher_zone'

	self.on_philosopher_zone = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.philosopher_zone then
		self.on_philosopher_zone = true

		if not self.playing_philosopher_event then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.philosopher_event, self))
		end
		return true
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return end
	local zone_name = e.Zone.Name

	if zone_name == self.philosopher_zone then
		self.on_philosopher_zone = false
	end
end

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

function local_class:dispose()
	self.on_philosopher_zone = false

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil
end

function local_class:philosopher_event()
	local philosopher = self.get_philosopher()

	self.playing_philosopher_event = true

	while self.on_philosopher_zone do

		wait_for_sec(0.5)

		music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.set_emotion(philosopher, { name = 'tired' })
		-- 엉덩이가 차가워…
		speech_bubble_util.show_speech_bubble_async(philosopher, { key = 'nightmare_demonworld_philosopher_1', skip = false })

		wait_for_sec(0.2)

		character_util.remove_anim_and_emotion(philosopher)
		music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.jump_move(philosopher, philosopher.Position + vector(-1, -0.5, 0),
				3, 0.5, true, 'left')

		character_util.move_waypoint_async(philosopher,
				{ vector(self.get_philosopher_marker(1).x,0,philosopher.Position.z),
				self.get_philosopher_marker(1) },
				3, false, nil, nil, 'down')

		music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.jump_move(philosopher, philosopher.Position + vector(0, 0.7, -1),
				3, 0.5, true, 'left')

		music_player_util.play_sfx({ sfx_name = '02_flower_hit_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })

		character_util.set_direction(philosopher, 'left')
		character_util.set_anim(philosopher, { name = 'seat' })

		wait_for_sec(0.5)

		-- 어디 보자…
		speech_bubble_util.show_speech_bubble_async(philosopher, { key = 'nightmare_demonworld_philosopher_2', skip = false })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.set_emotion(philosopher, { name = 'tired' })
		-- 여기는 너무 눅눅한데…
		speech_bubble_util.show_speech_bubble_async(philosopher, { key = 'nightmare_demonworld_philosopher_3', skip = false })

		wait_for_sec(0.2)

		character_util.remove_anim_and_emotion(philosopher)
		music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.jump_move(philosopher, philosopher.Position + vector(1, -0.7, 0),
				3, 0.7, true, 'right')

		character_util.move_waypoint_async(philosopher,
				{ self.get_philosopher_marker(2) },
				3, false, nil, nil, 'right')

		music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		sp_util.sine_move(philosopher, { from = philosopher.Position, to = philosopher.Position + vector(1, 1, 0), duration = 0.4, height = 1})

		music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		wait_for_sec(0.2)

		character_util.set_direction(philosopher, 'right')
		character_util.set_anim(philosopher, { name = 'seat' })

		wait_for_sec(0.5)

		music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim_and_emotion(philosopher, { name = 'embarrassed' }, { name = 'scared'})
		-- 구멍에서 찬 바람이 나오잖아…!
		speech_bubble_util.show_speech_bubble_async(philosopher, { key = 'nightmare_demonworld_philosopher_4', skip = false })

		character_util.set_anim_and_emotion(philosopher, { name = 'seat' }, { name = 'tired'})
		-- 넓은 우주에서 내 앉을 자리 하나 찾는 것만으로도… 인생의 한 가지 업적일 텐데…
		speech_bubble_util.show_speech_bubble_async(philosopher, { key = 'nightmare_demonworld_philosopher_5', skip = false })

		character_util.remove_anim_and_emotion(philosopher)

		music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.jump_move(philosopher, philosopher.Position + vector(0, -1, 1),
				3, 0.5, true, 'up')

		music_player_util.play_sfx({ sfx_name = '01_land_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })
		character_util.move_waypoint_async(philosopher,
				{ self.get_philosopher_marker(3) },
				3, false, nil, nil, 'up')

		character_util.jump_move(philosopher, philosopher.Position + vector(0, 0.5, 1),
				3, 0.5, true, 'left')
		music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = philosopher, type_priority = 'event', player_priority = 'npc' })

		character_util.set_direction(philosopher, 'left')
		character_util.set_anim(philosopher, { name = 'seat' })
	end

	self.playing_philosopher_event = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}