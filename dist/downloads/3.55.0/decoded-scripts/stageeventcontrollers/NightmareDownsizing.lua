local local_class = newclass("NightmareDownsizingController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 캐릭터를 얻어오는 함수
	self.get_little_matt = function() return get_character('little_matt') end

	-- 오브젝트를 얻어오는 함수
	self.get_cheese = function(num) return get_field_object('sns_cheese_' .. num) end
	self.get_cherry = function(num) return get_field_object('sns_cherry_' .. num) end

	-- SNS 캐릭터 id
	self.little_matt_follower_id = 55
end

function local_class:load_resource()
	-- SNS 캐릭터 팔로워 등록이 안됐을 때만 등장하게
	if not user_progress:IsFollowing(self.little_matt_follower_id) then
		local little_matt = self.get_little_matt()
		character_util.set_direction(little_matt, 'down')
		little_matt.Position = vector(74, 0, 89)
		little_matt.Interactable:AddListener(self.cs_controller)

		-- NPC 옆에 있는 치즈, 체리가 부숴지지 않게
		for i = 1, 2 do
			local cheese = self.get_cheese(i)
			local cherry = self.get_cheese(i)

			cheese.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
			cheese.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
			cheese.Holdable = CS.Oak.NonHoldable.Instance
			cherry.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
			cherry.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
			cherry.Holdable = CS.Oak.NonHoldable.Instance
		end
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	local little_matt = self.get_little_matt()
	little_matt.Interactable:RemoveRelatedEvent(self.cs_controller)
	if lua_helper.type_compare(little_matt.Interactable, CS.Oak.NPCInteractable) then
		little_matt.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local little_matt = self.get_little_matt()

	if lua_helper.reference_equals(e.Target, little_matt) then
		sp_util.play_normal_screenplay(self.interact_little_matt, self)
		return true
	end

	return false
end

-- 작은 사이즈의 남성과 상호작용
function local_class:interact_little_matt()
	local little_matt = self.get_little_matt()

	party_util.align_to_target(little_matt, 'down', 1, 'linear')

	-- 이건 혁명입니다!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(little_matt, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_1', skip = true })

	-- 보세요, 자두 하나가 제 몸통만한 걸요!
	character_util.set_direction(little_matt, 'right')
	character_util.set_anim(little_matt, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_2', skip = true })

	-- 쪼만한 탁자가 이렇게 광활한 벌판처럼 느껴지는 걸요!
	character_util.set_direction(little_matt, 'down')
	character_util.set_anim(little_matt, { name = 'success', sfx_name = '01_jump_01' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_3', skip = true })

	-- 여기선 먹고싶은만큼 아무리 먹어도 동전 몇 개면 해결되요!
	character_util.set_anim(little_matt, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_4', skip = true })

	-- 한정된 자원의 분배는 인류의 영원한 숙제였죠.
	character_util.set_anim(little_matt, { name = 'question', loop = false })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_5', skip = true })

	-- 하지만 이제 걱정할 필요가 없어요.
	character_util.set_anim(little_matt, { name = 'cross_arm' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_6', skip = true })

	-- 이렇게 작아지면 모든게 해결되니까요!
	character_util.set_anim(little_matt, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_7', skip = true })

	-- 다시 커지면 이곳을 낙원으로 개조해야겠어요.
	character_util.set_anim(little_matt, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_8', skip = true })

	-- 이름은… 레저랜드 정도면 적당하지 않을까요?
	character_util.remove_anim(little_matt)
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_9', skip = true })

	-- 당신도 관심있으면 연락 주세요!
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_10', skip = true })

	-- FB등록
	yield_return_func(CS.Oak.AddSNSCoroutine, self.little_matt_follower_id)

	-- 분명 이 사업은 대박날 거예요!
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	character_util.set_anim(little_matt, { name = 'success', sfx_name = '01_jump_01' })
	speech_bubble_util.show_speech_bubble_async(little_matt, { key = 'sns_downsizing_11', skip = true })

	character_util.remove_anim(little_matt)

	little_matt.Interactable:RemoveRelatedEvent(self.cs_controller)
	little_matt.Interactable.Talk = 'sns_downsizing_11'
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
