local local_class = newclass("CafeFoodieController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_foodie = function() return get_character('sns_foodie') end

	-- SNS 캐릭터 id
	self.sns_follower_id = 57
end

function local_class:load_resource()
	-- SNS 캐릭터 팔로워 등록이 안됐을 때만 등장하게
	if not user_progress:IsFollowing(self.sns_follower_id) then
		self.get_foodie().Position = vector(7, 0.4, 105)
		self.get_foodie().Direction = CS.Oak.Direction.Left

		character_util.set_anim(self.get_foodie(), {name = 'seat'})
		self.get_foodie().SpineController:SetAttachment('[base]weapon2', 'shield_beer_full')

		if type_util.is_npc_interactable(self.get_foodie()) then
			self.get_foodie().Interactable:AddListener(self.cs_controller)
		end
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	if type_util.is_npc_interactable(self.get_foodie()) then
		self.get_foodie().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if type_util.is_interacted_target(e, self.get_foodie()) then
		sp_util.play_normal_screenplay(self.talk_with_foodie, self)
		return true
	end

	return false
end

function local_class:talk_with_foodie()
	local foodie = self.get_foodie()

	if type_util.is_npc_interactable(self.get_foodie()) then
		self.get_foodie().Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	party_util.align_to_target(foodie.Position + vector(-1, 0, 0), 'left', 1, 'linear')

	--탄산 보리차를 한모금 하고
	music_player:PlaySfxOneShot('01_drinking_01')
	foodie.SpineController:SetAttachment('[base]weapon2', 'shield_beer_full_2')
	character_util.set_anim(foodie, { name = 'dualgun_attack_right', upper = true, loop = false, scale = 0.3 })

	wait_for_sec(0.5)

	foodie.SpineController:SetAttachment('[base]weapon2', 'shield_beer_empty_2')

	wait_for_sec(0.5)

	character_util.remove_anim(foodie, true)
	foodie.SpineController:SetAttachment('[base]weapon2', 'shield_beer_empty')

	--고로 : 크으- 이곳의 탄산 보리차. 위험한걸?
	character_util.set_anim(foodie, { name = 'dualgun_attack_right', upper = true, scale = 0 })
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_1', skip = true})
	character_util.remove_anim(foodie, true)

	--고로 : 이 곳의 주인장은 이 가격으로 괜찮은건가?
	foodie.SpineController:SetAttachment('[base]weapon2', 'empty')
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_2', skip = true})

	--드림테라피 하고 있는 사람들을 바라보며
	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(foodie, 'right')
	wait_for_sec(1)

	--고로 : 저건… 드림 테라피?
	character_util.normal_jump(foodie, '01_small_jump_01')
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_3', skip = true})

	--고로 : 이런, 이런. 나는 이 때까지 행복이라는 것에 대해 무지했구나!
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_4', skip = true})

	--고로 : 던전왕국! 최고!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(foodie, {name = 'cast2', upper = true})
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_5', skip = true})
	character_util.remove_anim(foodie, true)

	--고로 : 시간과 사회에 얽매이지 않고 행복하게 배를 채울 때 잠시 동안 나는 제멋대로가 되고 자유로워지지.
	music_player:PlaySfxOneShot('01_rustle_01')
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_6', skip = true})

	--주인공을 알아차린다.
	wait_for_sec(0.5)

	character_util.look_at(foodie, user_party.Leader)

	wait_for_sec(1)

	--고로 : 거기, 자네!
	character_util.normal_jump_async(foodie, '01_small_jump_01')
	character_util.set_anim(foodie, {name = 'release', upper = true, sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_7', skip = true})
	character_util.remove_anim(foodie, true)

	--고로 : 혹시 이 곳처럼 뛰어난 음식점을 더 알고 있다면, 나에게 꼭 연락해줘!
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_8', skip = true})

	--FB 등록.
	yield_return_func(CS.Oak.AddSNSCoroutine, self.sns_follower_id)

	--고로 : 아아! 이 곳의 음식! 최고였어!
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_9', skip = true})

	--고로 : 잘 먹었습니다!
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(foodie, {key = 'cafe_foodie_10', skip = true})

	foodie.Interactable.Talk = 'cafe_foodie_10'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
