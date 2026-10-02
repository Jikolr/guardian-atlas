local local_class = newclass('NightmareFutureCastle2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.ailie_star_piece_name = 'ailie_star_piece'
	self.get_ailie = function() return get_character('ailie') end
	self.saw_ailie = false
	self.beer_list = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	local ailie = self.get_ailie()
	character_util.remove_relate_event(ailie, self.cs_controller)

	if self.beer_list ~= nil then
		for _, beer in ipairs(self.beer_list) do
			beer:ConsumeComplete()
			beer = nil
		end

		self.beer_list = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_start_event(_)
	if not CS.Oak.StageProgress.Current:HasStarPiece(self.ailie_star_piece_name) then
		local ailie = self.get_ailie()
		character_util.set_direction(ailie, 'right')
		character_util.set_anim(ailie, { name = 'eat' })
		character_util.add_listener(ailie, self.cs_controller)
	else
		local ailie = self.get_ailie()
		character_util.set_position(ailie, vector(999,0,999))
		self.saw_ailie = true
	end

	self.beer_list = {}
	for i = 1, 5 do
		local beer_pos = field:GetMarker('beer_point_'..i).position
		local beer_item = drop_item_util.create_item(
				{ pos = beer_pos,
				  target = nil,
				  itemid = 20113,
				  notforinven = true,
				  lootstate = 'dontfindlooter' })
		table.insert(self.beer_list, beer_item)
	end
	return false
end

function local_class:on_interact_event(e)
	if not self.saw_ailie and lua_helper.reference_equals(e.Target, self.get_ailie()) then
		self.saw_ailie = true
		sp_util.play_normal_screenplay(self.talk_ailie, self)
		return true
	end

	return false
end
--endregion

function local_class:talk_ailie()
	local ailie = self.get_ailie()
	local eat_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})

	party_util.align_party(ailie.Position + vector(-1.5,0,-1.5), 'up', 1, 'linear')
	party_util.set_direction('right')
	eat_sfx:Stop()

	-- 아저씨!
	character_util.look_at(ailie, user_party.Leader)
	character_util.remove_anim(ailie)
	character_util.set_emotion(ailie, { name = 'smile' })
	character_util.normal_double_jump(ailie, true)
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_1', skip = true })

	character_util.show_emoticon_async(ailie, nil, 'question')

	-- 넌… {0}이(가) 말하던 공주?
	speech_bubble_util.show_speech_bubble_async(ailie, {
		key = game_string:Format('nightmare_futurecastle_ailie_2', user.Name), skip = true })

	-- 에일리구나! 크레이그 친구!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	character_util.set_animation_n_times(user_party.Leader, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_ailie_3', skip = true })

	character_util.set_animation_n_times_async(ailie, { name = 'nod', count = 2 })

	character_util.remove_anim_and_emotion(user_party.Leader)

	--  {0}도 없이 여긴 웬일이야?
	speech_bubble_util.show_speech_bubble_async(ailie, {
		key = game_string:Format('nightmare_futurecastle_ailie_4', user.Name), skip = true })

	-- 아, 그렇지!
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.remove_emotion(ailie)
	character_util.normal_jump(ailie, true)
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_5', skip = true })

	eat_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})

	-- 네가 그렇게 반짝이는 노란 걸 좋아한다며?
	character_util.set_direction(ailie, 'right')
	character_util.set_anim(ailie, { name = 'eat' })
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_6', skip = true })

	-- 이건 아니고…
	local item_id = 20009
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.throw_item, self, item_id, ailie.Position + vector(0.5,0,0),
					ailie.Position + vector(-3,0,1), 1))
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_7', skip = true })

	-- 이것도 아니고…
	item_id = 20284
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.throw_item, self, item_id, ailie.Position + vector(0.5,0,0),
					ailie.Position + vector(-4,0,-1.5), 1))
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_8', skip = true })

	-- 이런 건 언제 챙긴 거야…?
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_emotion(ailie, { name = 'tired' })
	item_id = 20048
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.throw_item, self, item_id, ailie.Position + vector(0.5,0,0),
					ailie.Position + vector(-2,0,2), 1))
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_9', skip = true })

	-- 아, 어디 간 거야!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	character_util.set_emotion(ailie, { name = 'mad' })
	character_util.set_anim(ailie, { name = 'eat', scale = 1.5 })
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_10', skip = true })

	wait_for_sec(1)
	eat_sfx:FadeOut(2)
	character_util.remove_emotion(ailie)
	character_util.set_anim(ailie, { name = 'eat' })
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.show_emoticon_async(ailie, nil, 'notice')
	-- 찾았다!!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_emotion(ailie, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(ailie, { key = 'nightmare_futurecastle_ailie_11', skip = true })

	character_util.remove_anim(ailie)
	character_util.set_emotion(user_party.Leader, { name = 'surprise' })

	local star_piece = get_field_object(self.ailie_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(ailie.Position + vector(0,0,0.5)))
	wait_for_sec(2)

	-- {0}한테 한 턱 쏘기로 한 빚 갚았다고 전해줘!
	character_util.look_at(ailie, user_party.Leader)
	character_util.set_emotion(ailie, { name = 'smile' })
	character_util.set_animation_n_times(ailie, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(ailie, {
		key = game_string:Format('nightmare_futurecastle_ailie_12', user.Name), skip = true })

	-- 고마워! 꼭 전해줄게!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(user_party.Leader, { name = 'awesome' })
	character_util.set_anim(user_party.Leader, { name = 'success', sfx_name = '01_small_jump_01' })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader,
			{ key = 'nightmare_futurecastle_ailie_13', skip = true })

	character_util.remove_anim_and_emotion(user_party.Leader)

	character_util.remove_relate_event(ailie, self.cs_controller)
	ailie.Interactable.Talk = game_string:Format('nightmare_futurecastle_ailie_12', user.Name)
end

function local_class:throw_item(item_id, start_pos, end_pos, duration)
	music_player_util.play_sfx_one_shot('01_throw_01')
	local drop_item = drop_item_util.create_item(
			{ pos = start_pos ,
			  target = end_pos,
			  itemid = item_id,
			  notforinven = true,
			  lootstate = 'dontfindlooter' })

	wait_for_sec(1.5)
	local time_passed = 0
	local custom_alpha = 1
	local shadow_alpha = drop_item.ShadowTransform:GetComponent(typeof(CS.CustomSprite)).Alpha

	while time_passed <= duration do
		time_passed = time_passed + unity_class.time.deltaTime

		local alpha_progress = unity_class.mathf.Clamp01(1 - (time_passed / duration))
		local custom_sprite = drop_item.SpriteTransform:GetComponent(typeof(CS.CustomSprite))
		local shadow_sprite = drop_item.ShadowTransform:GetComponent(typeof(CS.CustomSprite))

		custom_sprite.TintColor = unity_color({ custom_alpha * alpha_progress
		, custom_alpha * alpha_progress, custom_alpha * alpha_progress, custom_alpha * alpha_progress })
		shadow_sprite.Alpha = shadow_alpha * alpha_progress
		custom_sprite:Rebuild()
		shadow_sprite:Rebuild()
		coroutine.yield()
	end

	drop_item:ConsumeComplete()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
