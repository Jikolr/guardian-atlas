local local_class = newclass("NightmareSnowMountain3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- SNS 관련 변수
	self.is_added_sns_follower = false
	self.follower_id = 59
	-- 이벤트 진행 상황
	self.event_progress = {
		idle = 0,
		event_started = 1,
		got_item = 2,
		event_finished = 3
	}

	self.current_progress = self.event_progress.idle

	self.got_item_list = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')

	local snowman_begger = get_character('snowman_begger')
	self.is_added_sns_follower = user_progress:IsFollowing(self.follower_id)
	-- sns follower 가 추가 되어 있지 않다면.
	if not self.is_added_sns_follower then
		self.got_item_list = { false, false, false}
		-- 리스너 추가
		character_util.add_listener(snowman_begger, self.cs_controller)
	else
		self.current_progress = self.event_progress.event_finished
		character_util.set_emotion(snowman_begger, { name = 'doyagao' })
		character_util.remove_anim(snowman_begger)
		snowman_begger.Interactable.Talk = 'nightmare_snowmountain_snowman_begger_36'
	end
end

function local_class:on_stage_loaded_event()
	return true
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	local snowman_begger = get_character('snowman_begger')
	character_util.remove_relate_event(snowman_begger, self.cs_controller)
	self.cs_controller = nil
	self.got_item_list = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)

	elseif lua_helper.type_compare(e, CS.Oak.DamageEvent) then
		return self:on_damage_event(e)
	end

	return quest_util.on_event(self, e)
end

function local_class:on_interact_event(e)
	local snowman_begger = get_character('snowman_begger')
	if lua_helper.reference_equals(e.Target, snowman_begger) then
		if self.current_progress == self.event_progress.idle then
			sp_util.play_normal_screenplay(self.request_snowman_begger, self)
		elseif self.current_progress == self.event_progress.got_item then
			sp_util.play_normal_screenplay(self.give_item, self)
		end
	end
	return false
end

function local_class:on_damage_event(e)
	if  self.current_progress == self.event_progress.event_finished then
		return false
	end

	for i = 1, 3 do
		local ice_block = get_field_object('ice_block_'..i)
		if lua_helper.reference_equals(e.Info.target, ice_block) and not self.got_item_list[i] then
			self.got_item_list[i] = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.drop_items, self, i))
			return true
		end
	end
	return false
end

function local_class:request_snowman_begger()
	local snowman_begger = get_character('snowman_begger')
	party_util.align_to_target(snowman_begger, 'down', 1, 'arc')

	character_util.remove_anim(snowman_begger)

	-- 전 가난한 화가 지망생이에요.
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_1', skip = true })

	-- 물감 살 형편도 안 되지만… 설산 풍경만큼은 그럭저럭 담아낼 수 있었죠.
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_2', skip = true })

	-- 흰색은 칠하지 않고 그대로 두면 되거든요.
	character_util.set_emotion(snowman_begger, {name = "smile"})
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_3', skip = true })

	-- 으으! 근데 빨간색은! 이제 뭘 갈아서 빨강의 오묘함을 표현하죠?!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_emotion(snowman_begger, {name = "attack"})
	character_util.set_anim(snowman_begger, {name = "attack", sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_4', skip = true })
	character_util.remove_anim(snowman_begger)

	character_util.show_emoticon_async(user_party_leader, nil, 'silence')

	-- 하하… 그래서 말인데요… 혹시 녹은 얼음 속에서…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_emotion(snowman_begger, {name = "smile"})
	character_util.set_anim(snowman_begger, { name = 'cast'})
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_5', skip = true })

	-- 빨간 물감 만들기에 적당한 재료를 발견하면… 갖다주실래요?
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_6', skip = true })

	-- 수락한다. / 거절한다.
	local choose = choose_util.play_choose_event({ { 'nightmare_snowmountain_snowman_begger_8', 'mercy' },
									{ 'nightmare_snowmountain_snowman_begger_9', 'normal' } })

	character_util.set_emotion(snowman_begger, { name = 'tired'})
	character_util.set_anim(snowman_begger, { name = 'question', loop = false })
	if choose == 1 then
		self.current_progress = self.event_progress.event_started
		for i = 1, 3 do
			if self.got_item_list[i] then
				self.current_progress = self.event_progress.got_item
			end
		end

		if self.current_progress == self.event_progress.event_started then
			character_util.remove_relate_event(snowman_begger, self.cs_controller)
			snowman_begger.Interactable.Talk = 'nightmare_snowmountain_snowman_begger_6'
		end
	end
end

-- 아이스 블록이 녹으면면
function local_class:drop_items(index)
	local item_id
	if index == 1 then
		item_id = 20081
	elseif index == 2 then
		item_id = 20223
	elseif index == 3 then
		item_id = 20020
	end
	ice_block = get_field_object('ice_block_'..index)
	local drop_item = drop_item_util.create_item({itemid = item_id, notforinven = true, pos = ice_block.Position,
												lootstate = 'dontfindlooter', target = nil})
	drop_item.ConsumeTarget = nil
	wait_for_sec(2)
	drop_item.ConsumeTarget = user_party_leader

	if self.current_progress == self.event_progress.event_started then
		self.current_progress = self.event_progress.got_item
		local snowman_begger = get_character('snowman_begger')
		character_util.add_listener(snowman_begger, self.cs_controller)
	end
end

function local_class:give_item()
	local snowman_begger = get_character('snowman_begger')
	party_util.align_to_target(snowman_begger, 'down', 1, 'arc')

	character_util.remove_anim(snowman_begger)

	-- 선택지
	local wait_for_branch = true
	local selection = 0

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	-- 캔에 담긴 스프를 준다.
	-- 당근을 준다.
	-- 사과를 준다.
	local item_check = false
	for i = 1, 3 do
		if self.got_item_list[i] then
			item_check = true
			branches:Add({
				Text = game_string:GetString('nightmare_snowmountain_snowman_begger_'..(9 + i)),
				Tendency = CS.Oak.TalkTendency.Intellect,
				Callback = function()
					selection = i
					wait_for_branch = false
				end})
		end
	end

	if not item_check then
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_6', skip = true })
		character_util.set_anim(snowman_begger, { name = 'question', loop = false })
		return
	end

	ui_overlay_util.push_overlay(snowman_begger, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	character_util.set_animation_n_times_async(user_party_leader, { name = 'throw', count = 1 })
	music_player_util.play_sfx_one_shot('01_throw_01')
	local item_id
	if selection == 1 then
		item_id = 20081
	elseif selection == 2 then
		item_id = 20223
	elseif selection == 3 then
		item_id = 20020
	end
	local drop_item = drop_item_util.create_item(
			{pos = user_party_leader.Position, target = snowman_begger.Position, itemid = item_id, notforinven = true})
	drop_item.ConsumeTarget = snowman_begger

	wait_for_sec(1.5)

	if selection == 1 then
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		-- 헉…! 강렬해요!
		character_util.set_emotion(snowman_begger, { name = 'awesome'})
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_13', skip = true })

		-- 요 새빨간 라벨을 뜯어내서… 불그죽죽한 스프에 으깨어 넣는다면…
		character_util.set_anim(snowman_begger, { name = 'release', sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_14', skip = true })

		-- 좋아요… 강렬한 카드뮴 레드를 얻을 수 있겠어요. 감사합니다…!
		character_util.set_anim(snowman_begger, { name = 'sing'})
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_15', skip = true })
	elseif selection == 2 then
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')

		-- 다, 당근… 당근이란 말이죠…?
		character_util.set_emotion(snowman_begger, { name = 'greed'})
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_16', skip = true })

		-- 숭덩숭덩 썰어서 폭탄벌레들과 같이 얼음그릇에 넣고… 짓이긴다면…
		character_util.set_anim(snowman_begger, { name = 'release', sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_17', skip = true })

		-- 흠… 그래도 크림슨 레이크 색을 내기는 힘들겠네요.
		character_util.remove_anim(snowman_begger)
		character_util.set_emotion(snowman_begger, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_18', skip = true })
		character_util.set_anim(snowman_begger, { name = 'question', loop = false })
		self.got_item_list[selection] = false
		return
	elseif selection == 3 then
		music_player_util.play_sfx_one_shot('01_gatcha_point_01')

		-- 오오… 후흐흐… 설산에서 보기 힘든 새빨간 사과군요.
		character_util.set_emotion(snowman_begger, { name = 'greed'})
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_19', skip = true })

		-- 이 녀석은 날카로운 칼로 껍데기만 벗겨낸 후… 아주 잘게 다지면…
		character_util.set_anim(snowman_begger, { name = 'release', sfx_name = "01_swing_01" })
		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_20', skip = true })

		-- 아냐… 턱도 없이 모자라요. 그냥 사과 주스나 만들어드세요.
		character_util.remove_anim(snowman_begger)
		character_util.set_emotion(snowman_begger, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(snowman_begger,
				{ key = 'nightmare_snowmountain_snowman_begger_21', skip = true })
		character_util.set_anim(snowman_begger, { name = 'question', loop = false })
		self.got_item_list[selection] = false
		return
	end

	character_util.remove_anim(snowman_begger)
	character_util.set_emotion(snowman_begger, { name = 'smile' })

	character_util.show_emoticon_async(user_party_leader, nil, 'silence')

	-- 답례로 제 그림을 보여드리고 싶지만, 이제 시작 단계라….
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_22', skip = true })

	-- 대신 FB 친구가 되어주시겠어요? 언젠가 그림이 완성되면 꼭 보여드릴게요!
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_23', skip = true })

	-- SNS 추가
	yield_return_func(CS.Oak.AddSNSCoroutine, self.follower_id)

	-- 그런데 말이에요, 기사님…
	character_util.remove_emotion(snowman_begger)
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_24', skip = true })

	-- 이 설산의 아름다움을 있는 그대로 화폭에 표현하려면…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim(snowman_begger, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_25', skip = true })

	-- 설산에서 살아 숨쉬며 감정을 느끼던 존재가 담겨야 한다고 생각하는데…
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_26', skip = true })

	-- 기사님은 어떻게 생각하시죠?
	character_util.set_anim(snowman_begger, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_27', skip = true })
	character_util.remove_anim(snowman_begger)

	-- 소재가 중요하다. / 색채가 중요하다. / 잘 모르겠다.
	choose_util.play_choose_event({ { 'nightmare_snowmountain_snowman_begger_28', 'mercy' },
									{ 'nightmare_snowmountain_snowman_begger_29', 'intellect' },
									{ 'nightmare_snowmountain_snowman_begger_30', 'normal' } })

	-- 아, 역시 기사님은… 뭘 좀 아시는군요?
	character_util.set_emotion(snowman_begger, { name = 'doyagao' })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_31', skip = true })

	-- 얼마 전… 손가락을 다친 이누이트놈이 제 그림을 만졌는데요…
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_32', skip = true })

	-- 후흐흐… 웬걸요? 그 핏자국이 만든 빨간색이야말로…
	character_util.set_anim(snowman_begger, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_33', skip = true })

	-- 제가 봤던 것 중 가장 아름다운 빨강이었어요.
	character_util.set_anim(snowman_begger, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_34', skip = true })
	character_util.remove_anim(snowman_begger)

	character_util.show_emoticon_async(user_party_leader, nil, 'question')

	-- 후후… 오늘은 염치없이 기사님께 부탁을 드렸지만…
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_35', skip = true })

	character_util.normal_jump(user_party_leader)
	music_player_util.play_sfx_one_shot('01_jump_01')
	-- 다음부터 빨간색만큼은… 제가 직접 조달하려고요.
	speech_bubble_util.show_speech_bubble_async(snowman_begger,
			{ key = 'nightmare_snowmountain_snowman_begger_36', skip = true })

	character_util.remove_relate_event(snowman_begger, self.cs_controller)
	snowman_begger.Interactable.Talk = 'nightmare_snowmountain_snowman_begger_36'
	self.current_progress = self.event_progress.event_finished
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}