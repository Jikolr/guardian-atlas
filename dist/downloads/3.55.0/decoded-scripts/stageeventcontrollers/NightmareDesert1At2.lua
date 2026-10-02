local local_class = newclass("NightmareDesert1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.crystal_table_name = 'crystal_ball_table'
	self.crystal_kid_name = 'beginner_fortune_teller'

	self.is_got_sns_follower = false
	self.sns_follower_id = 48
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	local crystal_table = get_field_object(self.crystal_table_name)
	crystal_table.Interactable = CS.Oak.NonInteractable.Instance

	local follower_kid = get_character(self.crystal_kid_name)
	if follower_kid.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		follower_kid.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local crystal_table = get_field_object(self.crystal_table_name)
		local follower_kid = get_character(self.crystal_kid_name)

		if lua_helper.reference_equals(e.Target, crystal_table) then
			sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = 'nightmare_desert_2_crystal_narration_1'})
		elseif lua_helper.reference_equals(e.Target, follower_kid) then
			sp_util.play_normal_screenplay(self.talk_with_fortune_teller, self)
		end

	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		local crystal_table = get_field_object(self.crystal_table_name)
		crystal_table.Interactable = CS.Oak.PublishInteractable.Create()

		local follower_kid = get_character(self.crystal_kid_name)
		self.is_got_sns_character = CS.Oak.UserProgress.Instance.Followers:Contains(self.sns_follower_id)

		if not self.is_got_sns_character then
			if follower_kid.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				follower_kid.Interactable:AddListener(self.cs_controller)
			end
		end
	end

	return false
end

function local_class:talk_with_fortune_teller()
	local follower_kid = get_character(self.crystal_kid_name)

	character_util.align_party(follower_kid, 'left', 1, 'linear')

	-- 오오… 보여요, 보여! 수정구슬이 제게 말을 걸어와요!
	character_util.set_anim(follower_kid, {name = 'cast', loop = true})
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_1', skip = true})
	character_util.remove_anim_and_emotion(follower_kid)

	-- 틀림 없어요! 저 점술에 재능이 있는 거예요, 그렇죠?
	character_util.set_direction(follower_kid, 'left')
	character_util.set_anim(follower_kid, {name = 'victory_get', loop = false, remove_after = 1.2, sfx_name = '01_small_jump_01'})
	wait_for_sec(1.2)
	character_util.remove_anim(follower_kid)
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_2', skip = true})

	-- 어디, 기사님에 대해서는 수정구슬이 뭐라고 하는지 봐 보죠!
	character_util.set_direction(follower_kid, 'down')
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_3', skip = true})

	wp_util.move_way_points_async(follower_kid,
			{waypoints = follower_kid.Position + vector(0, 0, -0.5), speed = 3})

	music_player:PlaySfxOneShot('01_rustle_01')
	-- 음… 흠흠… 그렇군요…
	character_util.set_anim(follower_kid, {name = 'cast', loop = true})
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_4', skip = true})

	-- 기사님, 기사님은 따뜻한 성격을 지녔지만 동시에 냉정한 면이 있으시네요, 그렇죠?
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_5', skip = true})

	-- 그렇다 / 아니다
	local result_1 = choose_util.play_choose_event(
			{{'beginner_fortune_teller_talk_branch_1', 'mercy'}, {'beginner_fortune_teller_talk_branch_2', 'brutal'}})

	if result_1 == 1 then
		-- 후후, 전 다 알 수가 있답니다.
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_6_0', skip = true})
	else
		-- 스스로를 잘 모르시네요. 이번 기회에 다시 한 번 생각해 보세요.
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_6_1', skip = true})
	end

	-- 그리고 기사님, 가끔씩 소화가 잘 안 되시죠?
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_7', skip = true})

	-- 그렇다 / 아니다
	local result_2 = choose_util.play_choose_event(
			{{'beginner_fortune_teller_talk_branch_1', 'mercy'}, {'beginner_fortune_teller_talk_branch_2', 'brutal'}})

	if result_2 == 1 then
		-- 저런, 저희 엄마가 약재를 잘 아세요. 찾아가 보세요.
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_8_0', skip = true})
	else
		-- 가끔씩요. 가. 끔. 씩. 있죠?
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_8_1', skip = true})
	end

	-- 오, 이건… 기사님, 어렸을 적 마음에 상처를 많이 받으셨군요.
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_9', skip = true})

	-- 그렇다 / 아니다
	local result_3 = choose_util.play_choose_event(
			{{'beginner_fortune_teller_talk_branch_1', 'mercy'}, {'beginner_fortune_teller_talk_branch_2', 'brutal'}})

	if result_3 == 1 then
		-- 아아, 안타까워라.
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_10_0', skip = true})
	else
		-- 힘든 기억을 떠올리기 싫어 애써 부정하시네요.
		speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_10_1', skip = true})
	end

	wp_util.move_way_points_async(follower_kid,
			{waypoints = follower_kid.Position + vector(0, 0, 0.5), speed = 3})

	-- 역시 제 예상대로 기사님은 프로메테이아형 인물이시군요!
	character_util.set_direction(follower_kid, 'left')
	character_util.set_emotion(follower_kid, {name = 'smile'})
	character_util.set_anim(follower_kid, {name = 'release', loop = true, scale = 0.7, sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_11', skip = true})
	character_util.remove_anim_and_emotion(follower_kid)

	-- 프로메테이아형 인물들은 ~
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_12', skip = true})

	-- 또 ~~~한 게 특징이죠!
	character_util.set_emotion(follower_kid, {name = 'smile'})
	character_util.set_anim(follower_kid, {name = 'victory_get', loop = false, sfx_name = '01_small_jump_01'})
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_13', skip = true})
	character_util.remove_anim_and_emotion(follower_kid)

	-- 프로메테이아형 인물일수록 ~~(운세 봐야 한다는 얘기)
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_13_0', skip = true})

	-- 자, 제 연락처 받으세요!
	character_util.set_anim(follower_kid, {name = 'release', loop = true, scale = 0.7, sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_13_1', skip = true})
	character_util.remove_anim(follower_kid)

	-- 페이스브레이크로 제 점괘를 보시면 모험에 도움이 될 거예요!
	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_13_2', skip = true})

	yield_return_func(CS.Oak.AddSNSCoroutine, self.sns_follower_id)

	speech_bubble_util.show_speech_bubble_async(follower_kid, {key = 'beginner_fortune_teller_14', skip = true})

	character_util.remove_anim_and_emotion(follower_kid)
	character_util.set_direction(follower_kid, 'down')

	if follower_kid.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		follower_kid.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
