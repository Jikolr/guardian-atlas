local local_class = newclass('TwitterAd')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
end


function local_class:on_event(e)
	local event_type = e:GetType()

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return false end
	if e.FieldObject ~= user_party_leader then return false end
	local zone_name = e.Zone.Name

	if zone_name == 'start_zone' then
		sp_util.play_normal_screenplay(self.princess_and_knight, self)
	end

	return false
end

function local_class:princess_and_knight()
	music_player_util.play_stage_music({ state = 'muted', mix = 0 })

	local princess = get_character('princess')
	local knight = get_character('knight')
	local lana = get_character('lana')
	local pet = get_character('pet')

	local gift = get_field_object('gift')
	gift.Transform.localScale = vector(0.5, 0.5, 0.5)
	command_util.execute_holdup(lana, gift, lana.Position)

	screen_util.fade_out_async(1, unity_class.color.black)

	camera_util.resize_to(3, 0)
	camera_util.move(knight.Position + vector(-0.5, 0, 1.5), 0)

	wait_for_sec(1)

	local waypoint = {field:GetMarker('waypoint_1').position, field:GetMarker('waypoint_2').position,
					  field:GetMarker('waypoint_3').position, field:GetMarker('waypoint_4').position}

	character_util.move_waypoint(lana, waypoint, 4, true, 'loop')
	character_util.move_waypoint(pet, waypoint, 4, true, 'loop')

	music_player_util.play_stage_music({ name = 'bgm_lobby_xmas', state = 'event' })
	screen_util.fade_in_async(1, unity_class.color.black)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = lana })
			wait_for_sec(0.5)
			music_player_util.play_sfx({ sfx_name = '01_pet_ordinary_01', parent = pet })
		end))

	character_util.normal_double_jump(princess, '01_small_jump_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_1', skip = true })
	--있잖아! 산타클로스라고 알아?

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim(knight, {name = 'bomb_idle'})
	character_util.show_emoticon_async(knight, nil, 'question')
	character_util.remove_anim(knight)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_anim(princess, {name = 'hold_loop'})
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_2', skip = true })
	--예전에! 그림책에서 읽은 적이 있어!

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_emotion(princess, {name = 'smile'})
	character_util.set_anim(princess, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_3', skip = true })
	--크리스마스 날에 나타나서 온세계 사람들에게 선물을 가져다 준대!
	character_util.remove_anim(princess)

	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	character_util.set_emotion(knight, {name = 'greed'})
	character_util.set_anim(knight, {name = 'sing'})
	wait_for_sec(1)

	local clap_sfx = music_player_util.play_sfx({ sfx_name = '01_clap_01', loop = true })
	character_util.set_anim(princess, {name = 'clap'})
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_4', skip = true })
	--멋지지 않아?
	character_util.remove_anim(princess)
	clap_sfx:Stop()

	music_player_util.play_sfx_one_shot('01_rustle_01')
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(knight, {name = 'smile'})
	character_util.nod_twice(knight)

	character_util.set_emotion(princess, {name = 'doyagao'})
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_5', skip = true })
	--나도, 산타클로스처럼 모두에게 선물을 주고 싶어서…

	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	character_util.set_direction(princess, 'down')
	character_util.set_emotion(princess, {name = 'smile'})
	--character_util.set_anim(princess, {name = 'tc/final_charge_confirm', loop = false, scale = 2})
	--wait_for_sec(0.5)
	character_util.set_anim(princess, {name = 'tc/final_charge_confirm', loop = false})
	wait_for_sec(0.8)

	character_util.normal_jump(knight, '01_player_jump_01')
	character_util.set_emotion(knight, {name = 'surprise'})

	music_player_util.play_stage_music({ state = 'muted', mix = 0 })
	music_player_util.play_sfx_one_shot('01_team_combination_start_01')
	camera_util.shake(0.05, 0.5)
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_6', skip = true })
	--준비해봤어!

	screen_util.fade_out_async(1, unity_class.color.black)

	wait_for_sec(1)

	character_util.remove_anim(princess)
	character_util.remove_anim(knight)
	character_util.set_direction(knight, 'down')
	character_util.set_emotion(knight, {name = 'smile'})

	screen_util.fade_in_async(1, unity_class.color.black)
	music_player_util.play_stage_music({ name = 'bgm_lobby_xmas', state = 'event' })

	wait_for_sec(0.5)

	character_util.normal_double_jump(princess, '01_small_jump_01')
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_7', skip = true })
	--리트윗한 후에, 바로 결과 알림이 오니까 조금만 기다려!

	character_util.set_direction(princess, 'right')
	character_util.set_direction(knight, 'left')

	music_player_util.play_sfx_one_shot('01_coop_mvp_01')
	character_util.set_emotion(princess, {name = 'awesome'})
	character_util.set_emotion(knight, {name = 'awesome'})
	character_util.set_anim(princess, {name = 'success', sfx_name = '01_player_jump_01'})
	character_util.set_anim(knight, {name = 'success'})
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'twitter_xmas_8', skip = true })
	--그럼, 또 봐!

	character_util.remove_animation_sfx(princess)
	music_player_util.play_stage_music({ state = 'muted' })
	screen_util.fade_out_async(1, unity_class.color.black)

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.black)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
