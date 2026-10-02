local local_class = newclass('InvaderQuestActorsController')

function local_class:init(cs_controller)
	self.get_knightcaptain = function() return get_character('knightcaptain') end
	self.get_princess = function() return get_character('princess') end
	self.get_queen = function() return get_character('queen') end

	self.entry_zone_name = 'invader_quest_actors_entry'
	self.fight_zone_name = 'invader_quest_actors_fight'

	self.star_piece_name = 'invader_quest_actors_star_piece'

	self.battle_group_name = 'invader_quest_actors'

	self.defeat_count = 0

	self.is_saw_talking = false
	self.is_fighting = false
	self.is_say_guardian = false
	self.is_event_clear = false

	self.cs_controller = cs_controller
end

function local_class:load_resource()
	self.is_event_clear = stage_progress:HasStarPiece(self.star_piece_name)

	if self.is_event_clear then
		return
	end

	message_system:Subscribe(self, typeof(CS.Oak.StageControlStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	if self.is_event_clear then
		return
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.StageControlStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	if lua_helper.type_compare(knightcaptain.Interactable, CS.Oak.NPCInteractable) then
		knightcaptain.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(queen.Interactable, CS.Oak.NPCInteractable) then
		queen.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageControlStartEvent) then
		return self:on_stage_control_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return self:on_field_object_destroyed_event(e)
	end

	return false
end

function local_class:on_stage_control_start_event(e)
	if self.is_event_clear then
		return false
	end

	self:npc_setting()

	return true
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == self.entry_zone_name then
			if not self.is_saw_talking then
				sp_util.play_normal_screenplay(self.actors_talk, self)
				return true
			end
		elseif e.Zone.Name == self.fight_zone_name then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_field_bgm, self))
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == self.fight_zone_name then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.restore_field_bgm, self))

			if self.is_fighting then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fight_reset, self))
			end
			return true
		end
	end

	return false
end

function local_class:on_interact_event(e)
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	if lua_helper.reference_equals(e.Target, knightcaptain) or lua_helper.reference_equals(e.Target, princess) or lua_helper.reference_equals(e.Target, queen) then
		if not self.is_fighting then -- 전투중이 아닐 때
			if not self.is_say_guardian then
				sp_util.play_normal_screenplay(self.talk_to_actors, self)
				return true
			else
				sp_util.play_normal_screenplay(self.say_guardian, self)
				return true
			end
		else -- 전투중일 때
			sp_util.play_normal_screenplay(self.prostrate_actor_talk, self, e.Target)
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	if lua_helper.reference_equals(e.FieldObject, knightcaptain) or lua_helper.reference_equals(e.FieldObject, princess) or lua_helper.reference_equals(e.FieldObject, queen) then
		local position = vector(0, 0, 0)
		local index = 0
		local num = 0
		self.defeat_count = self.defeat_count + 1

		if lua_helper.reference_equals(e.FieldObject, knightcaptain) then
			position = vector(34, 0, 131)
			index = 1
			num = 54
		elseif lua_helper.reference_equals(e.FieldObject, princess) then
			position = vector(45, 0, 127)
			index = 2
			num = 53
		elseif lua_helper.reference_equals(e.FieldObject, queen) then
			position = vector(43, 0, 133)
			index = 3
			num = 52
		end

		character_util.stop_shake(e.FieldObject)

		speech_bubble_util.show_speech_bubble(e.FieldObject, { key = 'invader_quest_actors_' .. num })

		-- 세명 다 죽이면 세번쨰 사람에게서 스타피스가 튀어나온다.
		if self.defeat_count >= 3 then
			self.is_fighting = false
			self:drop_star_piece(e.FieldObject.Position, position)
		end

		return true
	end

	return false
end

-- 도망친 배우와 대화
function local_class:prostrate_actor_talk(fo)
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()
	local key_num = 0

	if lua_helper.reference_equals(fo, knightcaptain) then
		key_num = 19
	elseif lua_helper.reference_equals(fo, princess) then
		key_num = 18
	elseif lua_helper.reference_equals(fo, queen) then
		key_num = 17
	end
	speech_bubble_util.show_speech_bubble_async(fo, { key = 'invader_quest_actors_' .. key_num, skip = true })

	local choose_result = choose_util.play_choose_event({ { 'invader_quest_actors_56_1', 'brutal' }, { 'invader_quest_actors_56_2', 'mercy' } })
	if choose_result == 1 then
		-- 처치한다.
		self:convert_to_monster(fo)
	else
		-- 그만둔다.
	end
end

function local_class:npc_setting()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	self:npc_position_setting()

	knightcaptain.Interactable:AddListener(self.cs_controller)
	princess.Interactable:AddListener(self.cs_controller)
	queen.Interactable:AddListener(self.cs_controller)
end

-- 연출
-- 인베이더 퀘스트 배우들이 방에서 대화중
function local_class:actors_talk()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	-- (악당 카밀라, 공주, 에바를 맡은 배우들이 시무룩해서 앉아있다. 방에 진입하려 하면 카메라 이동하며 이벤트)

	camera_util.move_async(queen.Position, 1)

	-- 우리 이러면 안되는거야...
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_1', skip = true })

	-- …
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_2', skip = true })

	-- 또 그 소리야. 제발 그만 좀해..
	character_util.normal_jump(knightcaptain, true)
	character_util.set_emotion(knightcaptain, { name = 'attack' })
	character_util.set_anim(knightcaptain, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_3', skip = true, bubble_direction = 'lt' })

	-- 이번에 아내가 두쌍둥이를 가졌다고..
	character_util.remove_anim(knightcaptain)
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_4', skip = true, bubble_direction = 'lt' })

	-- 하지만 그 영화는 거짓말이잖아!
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	character_util.set_emotion(queen, { name = 'attack' })
	character_util.set_anim(queen, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_5', skip = true })

	-- 캔터버리 난민들이 얼마나 상처를 받겠어..
	character_util.set_emotion(queen, { name = 'tired' })
	character_util.remove_anim(queen)
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_6', skip = true })

	-- …
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_7', skip = true })

	-- 이건 일이야. 우리가 자원 봉사하나?
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_8', skip = true, bubble_direction = 'lt' })

	-- 인베이더 픽쳐스가 아니면 우리 같은 사람에게 누가 배역을 줘?!
	character_util.set_anim(knightcaptain, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_9', skip = true, bubble_direction = 'lt' })

	-- 또 삼류 클럽 전전하면서 살고 싶어?!
	character_util.set_anim(knightcaptain, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_10', skip = true, bubble_direction = 'lt' })

	-- ….
	character_util.remove_anim(knightcaptain)
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_11', skip = true })

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	self.is_saw_talking = true
end

-- 인베이더 퀘스트 배우들에게 말 걸었을 때
function local_class:talk_to_actors()
	local queen = self:get_queen()

	party_util.align_to_target(vector_util.get_x0z(queen.Position) + vector(-0.75, 0, 0), 'left', 1, 'arc')

	-- ...아… 미안해요. 우리가 좀 시끄러웠죠?
	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.look_at(queen, user_party_leader)
	character_util.set_anim(queen, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_12', skip = true })

	-- 난 제나라고 해요. 당신은?
	character_util.remove_anim(queen)
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_13', skip = true })

	local choose_result = choose_util.play_choose_event({ { 'invader_quest_actors_13_1', 'brutal' }, { 'invader_quest_actors_13_2', 'mercy' } })
	if choose_result == 1 then
		-- 가디언입니다.
		yield_return_func(self.say_guardian, self)
	else
		-- 팬이에요.
		yield_return_func(self.say_fan, self)
	end
end

-- 가디언이라고 대답했을 경우의 연출
function local_class:say_guardian()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	if self.is_say_guardian then
		party_util.align_to_target(vector_util.get_x0z(queen.Position) + vector(-0.75, 0, 0), 'left', 1, 'arc')

		character_util.look_at(queen, user_party_leader)

		-- 다, 당신은 아까 가디언…!!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.normal_jump(princess, true)
		character_util.normal_jump(queen, true)
		character_util.normal_jump(knightcaptain, true)
		character_util.set_emotion(princess, { name = 'scared' })
		character_util.set_emotion(queen, { name = 'scared' })
		character_util.set_emotion(knightcaptain, { name = 'tired' })
		character_util.set_anim(knightcaptain, { name = 'embarrassed' })
		speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_55', skip = true, bubble_direction = 'lt' })
	else
		-- 가, 가디언?! 캔터버리의?!
		music_player:PlaySfxOneShot('03_runaway_01')
		character_util.normal_jump(princess, true)
		character_util.normal_jump(queen, true)
		character_util.normal_jump(knightcaptain, true)
		character_util.set_emotion(princess, { name = 'scared' })
		character_util.set_emotion(queen, { name = 'scared' })
		character_util.set_emotion(knightcaptain, { name = 'tired' })
		character_util.set_anim(knightcaptain, { name = 'embarrassed' })
		speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_14', skip = true, bubble_direction = 'lt' })
	end

	self.is_say_guardian = true

	-- ….!!
	character_util.remove_anim(princess)
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_15', skip = true })

	-- 다, 당신 우릴 어쩔 생각이죠?!
	character_util.shake(queen, 0.02, 9999)
	character_util.set_anim(queen, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_16', skip = true })

	local choose_result = choose_util.play_choose_event({ { 'invader_quest_actors_16_1', 'brutal' }, { 'invader_quest_actors_16_3', 'mercy' } })
	character_util.stop_shake(queen)
	if choose_result == 1 then
		-- 인베이더의 앞잡이들에게 천벌을!!
		self.is_fighting = true

		-- 3명 적으로 전환. 공격하지 않고 각자 화면 구석으로 가서 부들부들 떤다
		-- 히이이이이이익!!
		music_player:PlaySfxOneShot('03_runaway_01')
		speech_bubble_util.show_speech_bubble(knightcaptain, { key = 'invader_quest_actors_17' })
		speech_bubble_util.show_speech_bubble(princess, { key = 'invader_quest_actors_17' })
		speech_bubble_util.show_speech_bubble(queen, { key = 'invader_quest_actors_17' })
		character_util.remove_anim(princess)
		character_util.remove_anim(queen)
		wait_all({
			util.cs_generator(character_util.move_waypoint_async, knightcaptain, { vector(37, 0, 129), vector(32, 0, 129), vector(32, 0, 132) } , 7, true, nil, nil, 'left', true),
			util.cs_generator(character_util.move_waypoint_async, princess, { vector(42, 0, 129), vector(47, 0, 129), vector(47, 0, 126) } , 7, true, nil, nil, 'right', true),
			util.cs_generator(character_util.move_waypoint_async, queen, { vector(41, 0, 130), vector(45, 0, 130), vector(45, 0, 134) } , 7, true, nil, nil, nil, true)
		})
		character_util.shake(knightcaptain, 0.02, 9999)
		character_util.shake(princess, 0.02, 9999)
		character_util.shake(queen, 0.02, 9999)
		character_util.set_anim(knightcaptain, { name = 'prostrate' })
		character_util.set_anim(princess, { name = 'prostrate' })

		return
	else
		-- 당신들은 배우로써 일을 했을 뿐이야.
		-- …!!!
		character_util.set_emotion(princess, { name = 'tired' })
		character_util.set_emotion(queen, { name = 'tired' })
		character_util.set_emotion(knightcaptain, { name = 'tired' })
		character_util.remove_anim(knightcaptain)
		character_util.remove_anim(queen)
		speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_26', skip = true, bubble_direction = 'lt' })

		-- ...너…
		character_util.set_anim(princess, { name = 'cast' })
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_27', skip = true })

		-- ..고마워요.
		character_util.remove_anim(queen)
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_28', skip = true })

		-- 우리가 배우라는게 면죄부가 되지는 않는다고 생각해요..
		character_util.set_anim(queen, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_29', skip = true })

		-- 언젠가 우리가 만든 거짓을 바로잡을 수 있도록 노력할게요.
		character_util.remove_emotion(queen)
		character_util.set_anim(queen, { name = 'cast' })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_30', skip = true })
	end

	yield_return_func(self.throw_star_piece, self, queen)

	-- ..이게 조금이나마 모험에 도움이 될 수 있었으면 해요.
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_25', skip = true })

	self:set_talk_1()
end

-- 팬이라고 대답했을 경우의 연출
function local_class:say_fan()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	local is_mute = false

	-- 팬…? 우리들의…?
	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.set_emotion(queen, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_31', skip = true })

	-- ….!!
	character_util.normal_jump(princess, true)
	character_util.set_emotion(princess, { name = 'smile' })
	character_util.remove_anim(princess)
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_32', skip = true })

	-- 이, 이런날이 오다니..
	character_util.normal_jump(knightcaptain, true)
	character_util.set_emotion(knightcaptain, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_33', skip = true, bubble_direction = 'lt' })

	local choose_result = choose_util.play_choose_event({ { 'invader_quest_actors_33_1', 'mercy' }, { 'invader_quest_actors_33_2', 'normal' } })
	if choose_result == 1 then
		-- 항상 응원하고 있어요!
		-- 저, 정말 고마워요…
		character_util.set_emotion(queen, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_34', skip = true })

		-- ...감격…
		music_player:PlaySfxOneShot('03_dialogue_sadness_01')
		character_util.set_emotion(princess, { name = 'cry' })
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_35', skip = true })

		-- 헤헤.. 쑥쓰러운데..
		music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
		character_util.set_emotion(knightcaptain, { name = 'smile' })
		character_util.set_anim(knightcaptain, { name = 'cast2' })
		speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_36', skip = true, bubble_direction = 'lt' })

		-- 배우로써의 자신에 회의를 느끼고 있었는데..
		character_util.remove_emotion(queen)
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_37', skip = true })

		-- 당신의 한 마디에 큰 용기를 얻었어요.
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		character_util.set_emotion(queen, { name = 'smile' })
		character_util.set_anim(queen, { name = 'cast2' })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_38', skip = true })
	else
		-- 옳은 일을 하실 것이라 믿어요.
		-- …
		is_mute = true
		self:mute_bgm()
		character_util.remove_emotion(queen)
		character_util.remove_emotion(princess)
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_40', skip = true })

		-- …옳은 일…
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'invader_quest_actors_41', skip = true })

		-- ...팬들은 그렇게 생각하는거야?
		character_util.set_emotion(knightcaptain, { name = 'tired' })
		character_util.set_anim(knightcaptain, { name = 'question', loop = false })
		speech_bubble_util.show_speech_bubble_async(knightcaptain, { key = 'invader_quest_actors_42', skip = true, bubble_direction = 'lt' })

		-- ..진실된 의견 고마워요.
		character_util.set_emotion(queen, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_43', skip = true })

		-- 배우를 하기 위해 뭐든지 하겠다라고 생각해왔지만..
		character_util.remove_emotion(queen)
		character_util.set_anim(queen, { name = 'question', loop = false })
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_44', skip = true })

		-- ..어쩌면 그게 우리를 잘못된 길로 이끌고 있을지도 몰라요..
		character_util.remove_emotion(knightcaptain)
		character_util.remove_anim(knightcaptain)
		speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_45', skip = true })
	end

	yield_return_func(self.throw_star_piece, self, queen)

	-- 대단한건 아니지만 이게 모험에 도움이 될 수 있었으먼 해요.
	speech_bubble_util.show_speech_bubble_async(queen, { key = 'invader_quest_actors_39', skip = true })

	self:set_talk_2()
	if is_mute then
		self:play_bgm_field()
	end
end

-- 싸우다 밖에 나갔을 경우, NPC들의 위치를 초기화 시켜줌
function local_class:fight_reset()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	-- 한명이라도 쓰러뜨린 경우, 초기화 시켜주지 않음.
	if self.defeat_count > 0 then
		return
	end

	self.is_fighting = false

	self:npc_position_setting()

	character_util.stop_shake(knightcaptain)
	character_util.stop_shake(princess)
	character_util.stop_shake(queen)
end

-- 배우들을 원래의 위치, 방향, 표정, 애니메이션 상태로 배치
function local_class:npc_position_setting()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	princess.Holdable = CS.Oak.NonHoldable.Instance

	knightcaptain.Position = vector(38.2, 0.5, 129)
	princess.Position = vector(40.8, 0.5, 129)
	queen.Position = vector(40, 0.5, 130)

	character_util.set_direction(knightcaptain, 'right')
	character_util.set_direction(princess, 'left')
	character_util.set_direction(queen, 'down')

	character_util.set_emotion(knightcaptain, { name = 'tired' })
	character_util.set_emotion(princess, { name = 'tired' })
	character_util.set_emotion(queen, { name = 'tired' })

	character_util.remove_anim(knightcaptain)
	character_util.remove_anim(princess)
	character_util.remove_anim(queen)
end

-- NPC들을 몬스터로 변환, 공격은 하지 않음
function local_class:convert_to_monster(fo)
	character_util.convert_to_monster(fo, self.battle_group_name)
	fo.FieldObjectController.DontFight = true
	command_util.execute_monster_notice(fo, user_party_leader, 'battle')
	fo.DamagedBehaviour = CS.Oak.MonsterConstantDamagedBehaviour()
	character_util.set_death_type(fo, 'prostrate')
	fo.SpineController:RemoveFadeColor('ConstantMonster', 0)
	fo.FieldObjectStatsBehaviour:SetExp(0)
end

-- 스타피스를 주는 연출
function local_class:throw_star_piece(target)
	character_util.set_anim(target, { name = 'get', loop = false })

	local star_piece = get_field_object(self.star_piece_name)
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(target.Position))
	wait_for_sec(2)

	character_util.remove_anim(target)
end

-- 스타피스를 떨어뜨리는 연출
function local_class:drop_star_piece(start_position, end_position)
	local star_piece = get_field_object(self.star_piece_name)
	star_piece.Position = end_position
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(start_position))
end

-- 이벤트 끝난 후의 NPC들 대사 1
function local_class:set_talk_1()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	-- 언젠가는 이 거짓을 바로잡을 영화에 출연하고 싶어요...
	queen.Interactable.Talk = 'invader_quest_actors_46'

	-- 캔터버리 인들에게는 미안하게 생각하고 있어.
	knightcaptain.Interactable.Talk = 'invader_quest_actors_47'

	-- ...진짜 공주는 착한 아이겠지? 나랑은 달리..
	princess.Interactable.Talk = 'invader_quest_actors_48'

	if lua_helper.type_compare(knightcaptain.Interactable, CS.Oak.NPCInteractable) then
		knightcaptain.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(queen.Interactable, CS.Oak.NPCInteractable) then
		queen.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
end

-- 이벤트 끝난 후의 NPC들 대사 2
function local_class:set_talk_2()
	local knightcaptain = self:get_knightcaptain()
	local princess = self:get_princess()
	local queen = self:get_queen()

	-- 고마워요. 당신의 한 마디에 용기를 얻었어요.
	queen.Interactable.Talk = 'invader_quest_actors_49'

	-- ...팬… 고마워.
	knightcaptain.Interactable.Talk = 'invader_quest_actors_50'

	-- 네 한 마디. 소중이 간직할게.
	princess.Interactable.Talk = 'invader_quest_actors_51'

	if lua_helper.type_compare(knightcaptain.Interactable, CS.Oak.NPCInteractable) then
		knightcaptain.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(princess.Interactable, CS.Oak.NPCInteractable) then
		princess.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(queen.Interactable, CS.Oak.NPCInteractable) then
		queen.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
end

-- 사운드
function local_class:play_bgm_field()
	music_player_util.play_stage_music({ state = 'field', mix = 2 })
end

function local_class:mute_bgm()
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
end

function local_class:set_field_bgm()
	music_player_util.set_stage_music_clip_async({ name = 'ondemand/movie/audio:bgm_techno_02', state = 'field' })
	music_player_util.play_stage_music({ state = 'field', mix = 2 })
end

function local_class:restore_field_bgm()
	music_player_util.play_stage_music({ name = 'ondemand/movie/audio:bgm_techno', state = 'event', mix = 2 })
	music_player_util.set_stage_music_clip_async({ name = 'ondemand/movie/preload:bgm_burywood_main', state = 'field' })
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
