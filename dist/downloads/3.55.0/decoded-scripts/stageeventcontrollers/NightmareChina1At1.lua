local local_class = newclass("NightmareChina1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_singer = function()
		return get_character('singer')
	end

	self.get_signboard = function()
		return get_field_object('singer_signboard_fallen')
	end

	self.get_fx_roar = function()
		return unity_object_pool.GetOrCreate('fx_s_battleroar')
	end

	self.is_keep_singing = true
	self.is_roar_done = true
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.get_fx_roar()

	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	return user_progress:GetStartedQuest(93).InnerProgress < 1
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.get_singer()) then
			sp_util.play_normal_screenplay(self.talk_with_singer, self)
		elseif lua_helper.reference_equals(e.Target, self.get_signboard()) then
			speech_bubble_util.show_speech_bubble(self.get_signboard(),
					{key = 'nightmare_china_1_singer_sign_real', offset = vector(1.3, 0, 1.2)})
		end

	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		local singer = self.get_singer()
		if type_util.is_npc_interactable(singer) then
			singer.Interactable:AddListener(self.cs_controller)
		end

		-- 표지판 기믹 쓰러져있도록
		local signboard = self.get_signboard()

		-- 그림자 비활성화
		signboard.transform:GetChild(0).gameObject:SetActive(false)
		signboard.transform.localRotation = unity_class.quaternion.Euler(75, -90, 0)
		signboard.Position = vector(-19.7, 0, 28)
		signboard.Hitbox = CS.Oak.Hitbox(vector(1, 0, 0.5), vector(1.5, 0.3, 1))

		self:start_sing()
	end

	return false
end

function local_class:sing_routine()
	local singer = self.get_singer()

	while self.is_keep_singing do
		character_util.set_direction(singer, 'left')
		character_util.set_anim(singer, {name = 'sing', loop = true})
		character_util.set_emotion(singer, {name = 'sing', loop = true})

		self.get_fx_roar():Instantiate(singer.Position + vector(-0.3, 0, 0.3),
				CS.UnityEngine.Quaternion.FromToRotation(unity_class.vector3.forward, vector(-1, 0, 0)), nil)

		music_player_util.play_sfx({sfx_name = '02_battle_roar_01', parent = singer, volume = 0.5,
									type_priority = 'event', player_priority = 'npc'})

		wait_for_sec(2)

		if self.is_keep_singing == false then break end
		character_util.set_direction(singer, 'right')
		character_util.set_anim(singer, {name = 'sing', loop = true})
		character_util.set_emotion(singer, {name = 'sing', loop = true})

		self.get_fx_roar():Instantiate(singer.Position + vector(0.3, 0, 0.3),
				CS.UnityEngine.Quaternion.FromToRotation(unity_class.vector3.forward, vector(1, 0, 0)), nil)

		music_player_util.play_sfx({sfx_name = '02_battle_roar_01', parent = singer, volume = 0.5,
									type_priority = 'event', player_priority = 'npc'})

		wait_for_sec(2)
	end

	self.is_roar_done = true
end

function local_class:start_sing()
	self.is_roar_done = false
	self.is_keep_singing = true
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sing_routine, self))
end

function local_class:talk_with_singer()
	self.is_keep_singing = false

	local singer = self.get_singer()

	wait_all({
		util.cs_generator(self.wait_roar, self),
		util.cs_generator(character_util.align_party, singer, 'up', 1, 'arc')
	})

	character_util.remove_anim_and_emotion(singer)
	speech_bubble_util.remove_bubble(singer)

	--up, smile, idle, “아버지께서도 드디어 내 노래를 인정해 주시기 시작했어!”
	character_util.set_direction(singer, 'up')
	character_util.set_emotion(singer, {name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(singer, {key = 'nightmare_china_1_singer_1', skip = true})
	character_util.remove_anim_and_emotion(singer)

	--left, sing, sing, “맨날 사제들 수련이나 도우라고 하시더니, 요즘엔 노래를 하라고 하신다니까!”
	character_util.set_direction(singer, 'left')
	character_util.set_emotion(singer, {name = 'sing'})
	character_util.set_anim(singer, {name = 'sing'})
	speech_bubble_util.show_speech_bubble_async(singer, {key = 'nightmare_china_1_singer_2', skip = true})
	character_util.remove_anim_and_emotion(singer)

	--up, smile, release, “봐, 지금도 아버지가 준비해 주셔서 사람들에게 노래를 가르치고 있잖아!”
	character_util.set_direction(singer, 'up')
	character_util.set_emotion(singer, {name = 'smile'})
	character_util.set_anim(singer, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(singer, {key = 'nightmare_china_1_singer_3', skip = true})
	character_util.remove_anim_and_emotion(singer)

	--left, awesome, success, “내 재능을 다른 사람들을 위해 사용할 수 있어서 기뻐!”
	music_player:PlaySfxOneShot('03_dialogue_positive_01')

	character_util.set_direction(singer, 'left')
	character_util.set_emotion(singer, {name = 'awesome'})
	character_util.set_anim(singer, {name = 'success', sfx_name = '01_jump_01'})
	speech_bubble_util.show_speech_bubble_async(singer, {key = 'nightmare_china_1_singer_4', skip = true})
	character_util.remove_anim_and_emotion(singer)

	--up, idle, idle, “그럼, 이만! 마저 부를 노래가 있어서!”
	character_util.set_direction(singer, 'up')
	speech_bubble_util.show_speech_bubble_async(singer, {key = 'nightmare_china_1_singer_5', skip = true})
	character_util.remove_anim_and_emotion(singer)

	if type_util.is_npc_interactable(singer) then
		singer.Interactable:RemoveRelatedEvent(self.cs_controller)
		singer.Interactable.Talk = 'aspiring_singer_follow_talk_7'
	end

	self:start_sing()
end

function local_class:wait_roar()
	while self.is_roar_done == false do
		coroutine.yield()
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}