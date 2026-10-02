local local_class = newclass("BrandNewTestamentController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.main_quest_id = 91
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.sally = nil
	self.follower_name = 'sally_dustin'
	self.sally_follower_id = 52
	self.sally_zone = 'sally_zone'

	-- 기믹 이름
	self.scrap_dummy_name = 'scrap_dummy_'
	self.smoke_effect_name = 'FX_Common_SmokeScreen'

	-- 이펙트 이름름
	self.star_piece_name = 'scrap_dummy_star_piece'

	self.has_star_piece = false

	self.has_talked = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.PlayerGatherEvent), 'on_player_gather_event')

	unity_object_pool.GetOrCreate(self.smoke_effect_name)

	-- 팔로우 안되어있을때만
	-- 이거 사용 : user_progress:IsFollowing(__id__)
	if user_progress:IsFollowing(self.sally_follower_id) then
		--if not CS.Oak.UserProgress.Instance.Followers:Contains(self.sally_follower_id) then
		self.has_talked = true

		character_util.set_active_state(get_character(self.follower_name), 'disabled')
	else
		self.sally = get_character(self.follower_name)

		character_util.add_listener(self.sally, self.cs_controller)

		character_util.set_anim(npc, {name = 'prostrate' })
		character_util.set_emotion(npc, {name = 'damaged'})

		get_field_object(self.scrap_dummy_name .. 1).Interactable = CS.Oak.Interactable()
	end

	if not stage_progress:HasStarPiece(self.star_piece_name) then
		get_field_object(self.scrap_dummy_name .. 2).Interactable = CS.Oak.Interactable()
	else
		self.has_star_piece = true
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PlayerGatherEvent))

	character_util.remove_relate_event(get_character(self.follower_name), self.cs_controller)

	self.sally = nil


	self.cs_controller = nil
end

function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	end

	if type_util.is_interacted_target(e, get_character(self.follower_name)) then
		sp_util.play_normal_screenplay(self.what_doesnt_kill_me, self)
		return true
	end

	return false
end

-- on event 처리
function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == self.sally_zone then
				if self.main_quest_progress.InnerProgress >= 16 then -- 메인 퀘 진행도 16이상이면 중보 잡은 것
					if not self.has_talked then
						local npc = self.sally

						character_util.set_direction(npc, 'left')
						character_util.set_anim(npc, {name = 'prostrate' })
						character_util.set_emotion(npc, {name = 'damaged'})

						local scrap_dummy = get_field_object(self.scrap_dummy_name .. 1)
						scrap_dummy.Position = field:GetMarker('scrap_dummy_pos').position
					end

					if not self.has_star_piece then
						local star_piece_dummy = get_field_object(self.scrap_dummy_name .. 2)

						local marker = field:GetMarker('scrap_dummy_pos').position
						star_piece_dummy.Position = marker + vector(22, 0, -4)

						get_field_object(self.star_piece_name).FieldObjectBehaviour:ShowHiddenEffect()
					end

					return true
				end
			end
		end
	end
end

function local_class:on_stage_loaded_event(_)
	get_field_object(self.star_piece_name).FieldObjectBehaviour:HideHiddenEffect()
	return true
end

function local_class:on_player_gather_event(e)
	for i = 1, 2 do
		local scrap_dummy = get_field_object(self.scrap_dummy_name .. i)
		if lua_helper.reference_equals(e.Gatherable, scrap_dummy) then
			sp_util.play_normal_screenplay(self.dummy_search, self, i)
			return true
		end
	end
	return false
end

--별도 함수들
function local_class:she_said(anim,emote,num)
	local npc = self.sally
	character_util.set_anim(npc, {name = anim})
	character_util.set_emotion(npc, {name = emote})
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'brand_new_testament_'..num, skip = true})
end

-- 중간 보스 처리 이후 첫 만남 대사
function local_class:what_doesnt_kill_me()
	local npc = self.sally

	character_util.remove_relate_event(npc, self.cs_controller)

	local align_dir = vector_util.to_side_dir(user_party_leader.Position - npc.Position)

	party_util.align_to_target(npc, align_dir, 1, 'linear')

	--떨다가
	music_player_util.play_sfx({
		sfx_name = '01_rustle_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	character_util.shake(npc, 0.02, 1)
	wait_for_sec(1)
	--놀라 일어나서
	music_player_util.play_sfx({
		sfx_name = '01_player_popup_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})

	character_util.set_direction(npc, align_dir)
	character_util.mario_jump_async(npc, align_dir)

	character_util.set_emotion(npc, {name = 'surprise'})
	wait_for_sec(1)

	-- 두리번 두리번
	music_player_util.play_sfx({
		sfx_name = '01_swing_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})

	if align_dir == CS.Oak.Direction.Right then
		character_util.set_direction(npc, 'left')
	else
		character_util.set_direction(npc, 'right')
	end
	wait_for_sec(1)

	music_player_util.play_sfx({
		sfx_name = '01_swing_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	character_util.set_direction(npc, align_dir)
	wait_for_sec(1)

	--: (surprise) 기사님이 저 괴물을 물리쳐 주셨군요!
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'brand_new_testament_1', skip = true})

	-- 주인공 끄덕 끄덕 (2번 끄덕)
	character_util.set_animation_n_times_async(user_party_leader, { name = 'nod', count = 2 })

	--(smile) 정말 대단하세요!
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_positive_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	music_player_util.play_sfx({
		sfx_name = '01_clap_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	self:she_said('clap', 'awesome', 2)

	--(smile, get 자세) 그렇지만 어차피 저는 죽지 않았을 거예요!
	music_player_util.play_sfx({
		sfx_name = '01_player_jump_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})

	character_util.set_anim(npc, {name = 'victory_get', loop = false })
	character_util.set_emotion(npc, {name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(npc, { key = 'brand_new_testament_3', skip = true})

	-- emoticon_bubble_question
	character_util.show_emoticon_async(user_party_leader, nil, 'question')

	--기사님은 이 세상 어딘가에 신이 정말 있다는 걸 알고 계시나요?
	self:she_said('idle', 'idle', 4)

	-- (smile) 못 믿으시겠다고요? 제가 받은 문자 좀 보세요!
	self:she_said('idle', 'smile', 5)

	-----sns 등록 후 문자
	yield_return_func(CS.Oak.AddSNSCoroutine, self.sally_follower_id)

	--샐리 더스틴 남은 생애: 42년 3개월 11일
	field_ui_util.show_narration_async({ key = 'brand_new_testament_6' })

	--아침에 사고로 돌아가신 옆집 아저씨한테 마지막으로 온 문자도 2초 남았다는 문자였대요!
	self:she_said('idle', 'smile', 7)

	-- (awesome, clap) 분명 진짜 신이 보낸 문자겠지요?
	music_player_util.play_sfx({
		sfx_name = '03_dialogue_emphasize_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	music_player_util.play_sfx({
		sfx_name = '01_clap_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	self:she_said('clap', 'awesome', 8)

	--(success, 점프) 42년 3개월 11일 동안은 무슨 짓을 해도 죽지 않을 거예요!
	music_player_util.play_sfx({
		sfx_name = '01_jump_01',
		play_pos = npc.Position,
		loop = false,
		type_priority = 4000,
		player_priority = 900
	})
	self:she_said('success', 'awesome', 9)

	character_util.remove_anim(npc)

	get_character(self.follower_name).Interactable.Talk = 'brand_new_testament_9'

	self.has_talked = true
end

-- sns 피드로 메시지 띄우는 함수
--[[
function local_class:sns_msg()
	local id = self.sally_follower_id
	--샐리 더스틴 남은 생애: 42년 3개월 11일
	local text = game_string:GetString('brand_new_testament_6')

	local follower_data = CS.Oak.GameDataService.GetData('FollowerData')
	local spec = follower_data:GetSpec(id)

	local target_name = spec.Name
	local portrait_name = spec.PortraitName
	local sns_obj = CS.Oak.SNSMessage.Create(target_name, portrait_name, text)

	message_system:Publish(CS.Oak.SNSEvent.Create(sns_obj))
	local sns_popped = false

	local event_receiver = {}
	event_receiver.on_sns_popped = function(e)
		sns_popped = true
		return false
	end
	message_system:Subscribe(event_receiver, typeof(CS.Oak.SNSTouchPoppedEvent), 'on_sns_popped')

	local time_passed = 0

	while sns_popped == false and time_passed < 1.75 do
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield(nil)
	end

	if sns_popped == false then
		message_system:Publish(CS.Oak.SNSPopEvent.Instance)
	end

	message_system:Unsubscribe(event_receiver, typeof(CS.Oak.SNSTouchPoppedEvent))
	event_receiver = nil
end
]]

-- 더미 뒤적인 연출 이후
function local_class:dummy_search(index)
	local scrap_dummy = get_field_object(self.scrap_dummy_name .. index)
	local sally = get_character(self.follower_name)

	music_player:PlaySfxOneShot('02_wolf_boss_bomb_01')

	local scrap_dummy_pos = vector_util.get_x0z(scrap_dummy.Bounds.center)
	unity_object_pool.GetOrCreate(self.smoke_effect_name):Instantiate(scrap_dummy_pos)

	character_util.set_active_state(scrap_dummy, 'disabled' )

	if index == 1 then
		sally.Position = field:GetMarker('scrap_dummy_pos').position + vector(0.5, 0, 0.5)
		return
	end

	wait_for_sec(0.5)

	self.has_star_piece = true

	local star_piece = get_field_object(self.star_piece_name)
	star_piece.Position = star_piece.Position + vector(0, -1, 1)
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(star_piece.Position))
	wait_for_sec(2.5)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
