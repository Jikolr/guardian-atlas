local local_class = newclass('FoxMouseSNSController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- sns follower id
	self.follower_id = 54

	-- sns follower 가 이미 추가되어 있는지
	self.is_added_sns_follower = false

	self.mouse_name = 'fox_hitchhiker_mouse'

end

function local_class:load_resource()
	--message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	local mouse = get_character(self.mouse_name)

	self.is_added_sns_follower = user_progress:IsFollowing(self.follower_id)

	-- sns follower 가 추가 되어 있지 않다면.
	if not self.is_added_sns_follower then
		mouse.Interactable:AddListener(self.cs_controller)
	else
		mouse.Interactable.Talk = 'fox_sns_mouse_16'
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	--message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local mouse = get_character(self.mouse_name)
	mouse.Interactable:RemoveRelatedEvent(self.cs_controller)

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local mouse = get_character(self.mouse_name)

	if lua_helper.reference_equals(e.Target, mouse) then
			sp_util.play_normal_screenplay(self.interact_mouse, self)
	end

	return false
end

function local_class:interact_mouse()
	local mouse = get_character(self.mouse_name)
	party_util.align_to_target(mouse, 'right', 1)
	character_util.set_direction(mouse, 'right')
	music_player:PlaySfxOneShot('01_mouse_01')
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_1', skip = true })
	--그래, 뭔가 알아낸 게 있어, 벤자민?

	character_util.set_anim(mouse, {name = 'question', loop = false})
	character_util.show_emoticon_async(mouse, nil, 'notice')

	character_util.set_anim(mouse, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_2', skip = true })
	--잠깐, 넌 벤자민은커녕 쥐도 아니잖아?
	character_util.remove_anim(mouse)

	local mouse_nari = get_character('mouse_nari')
	speech_bubble_util.show_speech_bubble_async(mouse_nari, { key = 'fox_sns_mouse_3', skip = true })
	--오, 쥐치고는 촉이 좀 있는데?

	character_util.set_anim(mouse, {name = 'cross_arm'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_4', skip = true })
	--흥, 무시하기는.

	character_util.remove_anim(mouse)
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_5', skip = true })
	--우리 쥐들은 평상시엔 찍찍거리는 멍청한 동물인 척 하지만, 사실 세계에서 지능이 가장 높은 존재라고.

	character_util.set_emotion(mouse, {name = 'damaged'})
	character_util.set_anim(mouse, {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_6', skip = true })
	--우리는 삶, 우주, 그리고 모든 것에 대한 궁극적인 해답을 찾고 있거든!
	character_util.remove_anim_and_emotion(mouse)

	local wait = true
	local talk_branch = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		--궁극적인 해답?
		Text = game_string:GetString('fox_sns_mouse_7'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			talk_branch = 0
			wait = false
		end
	})
	branches:Add({
		--42?
		Text = game_string:GetString('fox_sns_mouse_8'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			talk_branch = 1
			wait = false
		end
	})

	local u = ui_overlay_util
	u.push_overlay(nil, branches)

	while wait do
		coroutine.yield(nil)
	end

	if talk_branch == 0 then
		music_player:PlaySfxOneShot('01_clap_01')
		music_player:PlaySfxOneShot('01_die_mouse_01')
		character_util.set_anim(mouse, {name = 'clap'})
		speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_9', skip = true, bubble_type = 'shout' })
		--그래! 궁극적인 해답!
	elseif talk_branch == 1 then
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		character_util.set_emotion(mouse, {name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_10', skip = true })
		--42? 그게 무슨 소리야?
	end

	character_util.remove_anim_and_emotion(mouse)

	character_util.set_anim(mouse, {name = 'question', loop = false})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_11', skip = true })
	--보아하니 우리 쥐들이 고등한 존재라는 게 믿기지 않는 모양이군.

	character_util.set_emotion(mouse, {name = 'doyagao'})
	character_util.nod_twice(mouse)
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_12', skip = true })
	--뭐, 됐어. 굳이 힘들여 설파할 생각도 없으니까. 인간들은 그렇게 착각하게 두는 게 편해.

	character_util.set_anim(mouse, {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_13', skip = true })
	--우리가 위협적인 존재가 아니라고 착각하니까 우릴 경계하지도 않고 알아서 식량과 자원을 갖다 바치는 거 아니겠어?

	character_util.set_anim(mouse, {name = 'nod'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_14', skip = true })
	--인간이야말로 우리 쥐들의 친구라 할 수 있지.

	character_util.remove_anim_and_emotion(mouse)
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_15', skip = true })
	--그러고 보니 너, 비록 인간이지만 자기 타월이 어딨는지는 아는 타입인 것 같네.

	character_util.set_anim(mouse, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(mouse, { key = 'fox_sns_mouse_16', skip = true })
	--너도 궁극적인 해답의 실마리를 얻게 되면 연락 해.
	character_util.remove_anim_and_emotion(mouse)

	self.is_added_sns_follower = true
	yield_return_func(CS.Oak.AddSNSCoroutine, self.follower_id)

	mouse.Interactable:RemoveRelatedEvent(self.cs_controller)
	mouse.Interactable.Talk = 'fox_sns_mouse_16'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
