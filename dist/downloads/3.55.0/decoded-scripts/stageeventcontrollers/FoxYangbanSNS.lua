local local_class = newclass('FoxYangbanSNSController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.yangban_name = 'don_yangban_SNS'
	self.nobi_name = 'don_nobi_SNS'

	-- sns follower id
	self.follower_id = 54

	-- sns follower 가 이미 추가되어 있는지
	self.is_added_sns_follower = false

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	local yangban = get_character(self.yangban_name)
	local nobi = get_character(self.nobi_name)
	yangban.Interactable:AddListener(self.cs_controller)

	self.is_added_sns_follower = user_progress:IsFollowing(self.follower_id)

	-- sns follower 가 추가 되어 있지 않다면.
	if not self.is_added_sns_follower then
		character_util.move_to(yangban, vector(-33, 0, -4), 0, nil)
		character_util.move_to(nobi, yangban.Position + vector(0, 0, 2), 0, nil)
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local yangban = get_character(self.yangban_name)
	yangban.Interactable:RemoveRelatedEvent(self.cs_controller)

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local yangban = get_character(self.yangban_name)

	if lua_helper.reference_equals(e.Target, yangban) then
		if not self.is_added_sns_follower then
			sp_util.play_normal_screenplay(self.interact_yangban, self)
		end
	end

	return false
end

function local_class:interact_yangban()
	local yangban = get_character(self.yangban_name)
	local nobi = get_character(self.nobi_name)
	party_util.align_to_target(yangban, 'left', 1)
	character_util.set_direction(yangban, 'left')

	character_util.set_anim_and_emotion(yangban, { name = 'victory_get', loop = false }, { name = 'smile', loop = true })
	--나는 라만자 마을의 기사! 셋시내 아가씨의 기사! 돈기오 기사일세!
	speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_1', skip = true })
	--실례가 되지 않는다면 그대의 존함을 알려주게.
	speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_2', skip = true })

	local wait = true
	local talk_branch = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		--캔터베리 왕국, 공주님의 기사! OOO이다!
		Text = game_string:GetString('fox_sns_3'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			talk_branch = 0
			wait = false;
		end
	})
	branches:Add({
		--아무말도 하지 않는다.
		Text = game_string:GetString('fox_sns_5'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			talk_branch = 1
			wait = false;
		end
	})

	local u = ui_overlay_util
	u.push_overlay(nil, branches)

	while wait do
		coroutine.yield(nil)
	end

	if talk_branch == 0 then
		character_util.set_anim(yangban, { name = 'success', loop = false })
		--오오! OOO 기사! 반갑소!
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_4', skip = true })
	elseif talk_branch == 1 then
		character_util.set_anim(yangban, { name = 'nod', loop = true })
		--흠… 침묵의 기사구려!
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_6', skip = true })
	end

	character_util.set_anim_and_emotion(yangban, { name = 'idle', loop = true }, { name = 'tired', loop = true })
	--나는 나의 할아버지이자 역사상 가장 위대한 기사님이셨던 돈기호 기사님의 유품을 찾아다니는 중이라네
	speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_7', skip = true })
	character_util.set_anim_and_emotion(yangban, { name = 'bomb_idle', loop = true }, { name = 'attack', loop = true })
	--그대! 혹시 돈기호 기사님의 유품을 찾는다면 나에게 알려줄 수 있겠나?
	speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_8', skip = true })

	wait = true
	talk_branch = -1

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		--네
		Text = game_string:GetString('fox_sns_9'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			talk_branch = 0
			wait = false;
		end
	})
	branches:Add({
		--아니오
		Text = game_string:GetString('fox_sns_12'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			talk_branch = 1
			wait = false;
		end
	})

	local u = ui_overlay_util
	u.push_overlay(nil, branches)

	while wait do
		coroutine.yield(nil)
	end

	if talk_branch == 0 then
		character_util.set_anim_and_emotion(yangban, { name = 'victory_get', loop = false }, { name = 'smile', loop = true })
		--정말 고맙네!!
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_10', skip = true })
		--그럼 연락하기 쉽도록 나와 FB 친구 등록을 하세!
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_11', skip = true })
		self.is_added_sns_follower = true
		yield_return_func(CS.Oak.AddSNSCoroutine, self.follower_id)
	elseif talk_branch == 1 then
		character_util.set_anim_and_emotion(yangban, { name = 'idle', loop = true }, { name = 'tired', loop = true })
		--아쉽게 되었군 그래.
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_13', skip = true })
		--그대의 생각이 바뀌면 알려주게.
		speech_bubble_util.show_speech_bubble_async(yangban, { key = 'fox_sns_14', skip = true })
	end

	character_util.set_anim_and_emotion(nobi, { name = 'cast', loop = false }, { name = 'smile', loop = true })
	--저희 기사님 부탁 들어주셔서 정말 감사합니다.
	speech_bubble_util.show_speech_bubble_async(nobi, { key = 'fox_sns_15', skip = true })

	character_util.remove_anim_and_emotion(nobi)
	character_util.remove_anim_and_emotion(yangban)
	yangban.Interactable:RemoveRelatedEvent(self.cs_controller)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
