local local_class = newclass("MovieMenInBlackStageController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.agent_name = 'men_in_black_agent_'

	self.invader_name = 'men_in_black_invader'

	-- 플레이어가 시야에 들어왔는지 체크할 것인지
	self.in_sight_check = false

	self.success_mission = false

	--몇 번 발각되었는지? (첫 번째 이벤트 스킵 여부 판단)
	self.discovered_time = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')

	local agents = {}
	for i = 1, 2 do
		local agent = get_character(self.agent_name .. i)
		table.insert(agents, agent)
	end

	-- 스타피스 획득 여부에 따른 처리
	if stage_progress:HasStarPiece('men_in_black_star_piece') then
		agents[1].ActiveState = active_state('disabled')
		agents[2].ActiveState = active_state('disabled')

		local invader = get_character(self.invader_name)
		invader.ActiveState = active_state('disabled')

		self.success_mission = true
	else
		agents[1].Interactable:AddListener(self.cs_controller)
		agents[2].Interactable:AddListener(self.cs_controller)

		agents[2].SpineController:SetAttachment('[base]weapon1', 'old_katana_piece_1')

		unity_object_pool.GetOrCreate('FX_minotaur_buttbounce')
	end

end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	for i = 1, 2 do
		local agent = get_character(self.agent_name .. i)
		if lua_helper.type_compare(agent.Interactable, CS.Oak.NPCInteractable) then
			agent.Interactable:RemoveRelatedEvent(self.cs_controller)
		end
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		local zone_name = e.Zone.Name

		if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then return false end

		if zone_name == 'men_in_black' and not self.in_sight_check and not self.success_mission then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.in_sight_target, self))
			return true
		end
	end

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		for i = 1, 2 do
			local agent = get_character(self.agent_name .. i)
			if lua_helper.reference_equals(e.Target, agent) and not self.success_mission then
				self.success_mission = true
				sp_util.play_normal_screenplay(self.success_infiltration, self)
				return true
			end
		end

	end

	return false
end

-- 플레이어가 시야 안에 들어왔는지 탐색
function local_class:in_sight_target()
	local agents = {}
	for i = 1, 2 do
		local agent = get_character(self.agent_name .. i)
		table.insert(agents, agent)
	end

	self.in_sight_check = true

	while self.in_sight_check do
		for _, v in pairs(agents) do
			-- 플레이어가 시야에 들어오면 이벤트 실행
			if CS.BoundsExtensions.IsIntersectingArc(user_party.Leader.Bounds, vector_util.get_x0z(v.Bounds.center),
				vector(1, 0, 0), 4, 90) then

				self.in_sight_check = false
				sp_util.play_normal_screenplay(self.discovered_player, self)
				return
			end
		end

		coroutine.yield(nil)
	end
end

-- 들킨 플레이어
function local_class:discovered_player()
	local agents = {}
	for i = 1, 2 do
		local agent = get_character(self.agent_name .. i)
		table.insert(agents, agent)
	end

	local invader = get_character(self.invader_name)

	local dir = vector_util.to_direction(agents[2].Position - user_party.Leader.Position)
	character_util.set_direction(user_party.Leader, dir)

	if self.discovered_time == 0 then
		--아 나는 외계인이 아니라 인베이더라니까!
		music_player:PlaySfxOneShot('02_goblin_hit_01')
		character_util.set_anim(invader, {name = 'release', loop = true, scale = 1, sfx_name = '01_swing_01'})
		character_util.set_emotion(invader, {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(invader, {key = 'movie_4_men_in_black_1', skip = true})
		character_util.remove_anim_and_emotion(invader)

		character_util.show_emoticon_async(agents[1], nil, 'notice')

		--..손님이 있군.
		speech_bubble_util.show_speech_bubble_async(agents[1], {key = 'movie_4_men_in_black_2', skip = true})

		--T 요원.
		speech_bubble_util.show_speech_bubble_async(agents[1], {key = 'movie_4_men_in_black_3', skip = true})

		--아이고 네네.
		character_util.set_anim(agents[2], {name = 'bomb_idle', loop = true, scale = 1})
		character_util.set_emotion(agents[2], {name = 'tired', loop = true})
		speech_bubble_util.show_speech_bubble_async(agents[2], {key = 'movie_4_men_in_black_4', skip = true})
		character_util.remove_anim_and_emotion(agents[2])

	else
		--아이씨 저 진상 또 저러네
		character_util.set_anim(agents[2], {name = 'hold_loop', loop = true, scale = 1})
		character_util.set_emotion(agents[2], {name = 'attack', loop = true})
		speech_bubble_util.show_speech_bubble_async(agents[2], {key = 'movie_4_men_in_black_6', skip = true})
		character_util.remove_anim_and_emotion(agents[2])
	end

	if (user_party.Leader.Position - agents[2].Position).magnitude > 1 then
		-- 플레이어 앞으로 가는 요원 (거리가 1보다 클 때)
		character_util.move_to_async(agents[2], user_party.Leader.Position + direction_util.to_vector3(dir),
			1, nil, false, true)
	end

	--자 주목. 여기 좀 봐요?
	character_util.set_anim(agents[2], { name = 'rifle_victory', loop = false, sfx_name = '01_fade_out_03'})
	speech_bubble_util.show_speech_bubble_async(agents[2],
		{ key = 'movie_4_men_in_black_5', skip = true })

	if dir ~= CS.Oak.Direction.Left then
		character_util.set_direction(agents[2], 'right')
	end

	-- 빛 번쩍
	music_player:PlaySfxOneShot('01_shutter_02')
	screen_util.fade_out_async(0.1, unity_class.color.white, 'linear')

	character_util.remove_anim(agents[2])
	local marker = field:GetMarker('men_in_black_reset').position
	party_util.align_party(marker, 'right', 0, 'linear')
	agents[2].Position = agents[1].Position + unity_class.vector3.back
	character_util.set_direction(agents[2], 'right')
	character_util.remove_anim_and_emotion(agents[2])
	self.discovered_time = self.discovered_time + 1
	wait_for_sec(0.1)

	screen_util.fade_in_async(0.1, unity_class.color.white, 'linear')
end

-- 잠입 성공한 플레이어
function local_class:success_infiltration()
	self.in_sight_check = false

	local agents = {}
	for i = 1, 2 do
		local agent = get_character(self.agent_name .. i)
		agent.Interactable:RemoveRelatedEvent(self.cs_controller)
		table.insert(agents, agent)
	end

	local invader = get_character(self.invader_name)

	party_util.align_party(agents[1].Position + 0.5 * unity_class.vector3.back,
		'left', 1, 'arc')

	local leader = user_party.Leader
	character_util.set_anim(leader, { name = 'jingak', loop = false, remove_after = 1.2 })
	wait_for_sec(0.7)
	character_util.remove_anim_and_emotion(leader)

	camera_util.shake(0.4, 0.5)
	music_player:PlaySfxOneShot('02_explosion_01')
	local buttbounce_pool = unity_object_pool.GetOrCreate('FX_minotaur_buttbounce')
	local buttbounce_effect = buttbounce_pool:Instantiate(leader.Position + 0.5 * unity_class.vector3.right)
	buttbounce_effect.transform.localScale = 0.3 * unity_class.vector3.one

	for _, v in pairs(agents) do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.character_jump_back, self, v))
	end

	wait_for_sec(1)

	--...이 친구 제법인데?
	speech_bubble_util.show_speech_bubble_async(agents[1], { key = 'movie_4_men_in_black_7', skip = true })

	--A, 또 엄한 사람 이 거지같은 직종에 끌어들일 생각이에요?
	character_util.set_anim(agents[2], {name = 'bomb_idle', loop = true, scale = 1})
	character_util.set_emotion(agents[2], {name = 'tired', loop = true})
	speech_bubble_util.show_speech_bubble_async(agents[2], { key = 'movie_4_men_in_black_8', skip = true })
	character_util.remove_anim_and_emotion(agents[2])

	--...젊은이.
	speech_bubble_util.show_speech_bubble_async(agents[1], { key = 'movie_4_men_in_black_9', skip = true })

	--언젠가 또 보자고.
	speech_bubble_util.show_speech_bubble_async(agents[1], { key = 'movie_4_men_in_black_10', skip = true })

	--스위치 딸깍
	agents[1].SpineController:SetAttachment('[base]weapon1', 'old_katana_piece_1')
	character_util.set_anim(agents[1], { name = 'rifle_victory', loop = false, sfx_name = '01_fade_out_03'})
	wait_for_sec(1.7)

	-- 빛 번쩍
	music_player:PlaySfxOneShot('01_shutter_02')
	screen_util.fade_out_async(0.1, unity_class.color.white, 'linear')

	character_util.set_active_state(agents[1], 'disabled')
	character_util.set_active_state(agents[2], 'disabled')
	character_util.set_active_state(invader, 'disabled')

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.1, unity_class.color.white, 'linear')

end

function local_class:character_jump_back(agent_character)

	local move_pos = vector(2, 0, 0)

	if agent_character.Position.z > user_party.Leader.Position.z then
		move_pos = move_pos + vector(0, 0, 0.5)

	else
		move_pos = move_pos - vector(0, 0, 0.5)

	end

	character_util.jump(agent_character, 0.6, 0.3)
	character_util.set_direction(agent_character, 'left')
	character_util.set_emotion(agent_character, { name = 'attack' })
	character_util.set_anim(agent_character, { name = 'jump', loop = false })
	character_util.move_to_async(agent_character, agent_character.Position + move_pos, 0.3, 5, false, false)

	character_util.remove_anim_and_emotion(agent_character)

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
