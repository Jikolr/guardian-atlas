local local_class = newclass("NightmareNewtubeTalentSNSController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 뉴투브 영재
	self.get_newtube_talent = function() return get_character('newtube_talent') end

	-- 수련인형
	self.get_rock = function() return get_field_object('newtube_rock') end
	self.get_projector = function() return get_field_object('newtube_projector') end

	-- SNS 캐릭터 id
	self.newtube_talent_follower_id = 58

	self.check_ailie = false
end

function local_class:load_resource()
	-- SNS 캐릭터 팔로워 등록이 안됐을 때만 등장하게
	if user_progress:IsFollowing(self.newtube_talent_follower_id) then
		local newtube_talent = self:get_newtube_talent()
		local rock = self:get_rock()

		character_util.set_active_state(newtube_talent, 'disabled')
		rock.ActiveState = CS.Oak.ActiveState.Disabled
	else
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

		self.inside_grid = false
		self.grid_req_id = 0

		local newtube_talent = self:get_newtube_talent()
		character_util.set_direction(newtube_talent, 'left')

		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	end

	-- 에일리 처리
	local main_quest = user_progress:GetStartedQuest(131)
	if main_quest ~= nil and (main_quest.InnerProgress == 2 or main_quest.InnerProgress >= 5)
			and not main_quest.IsComplete then
		self.check_ailie = true
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	local newtube_talent = self:get_newtube_talent()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')

	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	if lua_helper.type_compare(newtube_talent.Interactable, CS.Oak.NPCInteractable) then
		newtube_talent.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	local newtube_talent = self:get_newtube_talent()

	if lua_helper.reference_equals(e.Target, newtube_talent) then
		sp_util.play_normal_screenplay(self.interact_newtube_talent, self)
		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	local rock = self:get_rock()

	if lua_helper.reference_equals(e.FieldObject, rock) then
		self.inside_grid = false
		message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
		message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

		local newtube_talent = self:get_newtube_talent()
		speech_bubble_util.remove_bubble(newtube_talent)
		character_util.remove_anim_and_emotion(newtube_talent)

		sp_util.play_normal_screenplay(self.newtube_talent_stop_stream, self)
	end
	return false
end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'newtube_sns_grid' and not self.inside_grid then
			self.inside_grid = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_event_action, self))
			return true
		end
	end
	return false
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'newtube_sns_grid' and self.inside_grid then
			self.inside_grid = false
			local newtube_talent = self:get_newtube_talent()
			speech_bubble_util.remove_bubble(newtube_talent)
			character_util.remove_anim_and_emotion(newtube_talent)
			return true
		end
	end
	return false
end

-- 이벤트 시작 전 코루틴
function local_class:pre_event_action()
	local newtube_talent = self:get_newtube_talent()

	-- 같은 코루틴 여러개 방지
	self.grid_req_id = self.grid_req_id + 1
	local my_req_id = self.grid_req_id

	local attack_sfx_func = function()
		music_player_util.play_sfx({ sfx_name = '02_hit_projectile_01', parent = newtube_talent, type_priority = 'event', player_priority = 'npc' })
	end

	newtube_talent.SpineController.AlwaysUpdateSpine = true
	repeat
		character_util.set_direction(newtube_talent, 'left')
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		character_util.set_anim_and_emotion(newtube_talent, { name = 'attack', sfx_name = attack_sfx_func }, { name = 'attack' })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		-- 얍!
		speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_1', skip = false })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		character_util.set_anim_and_emotion(newtube_talent, { name = 'attack', sfx_name = attack_sfx_func }, { name = 'attack' })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		-- 얍!
		speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_1', skip = false })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		character_util.set_anim_and_emotion(newtube_talent, { name = 'attack', sfx_name = attack_sfx_func }, { name = 'attack' })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		-- 얍!
		speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_1', skip = false })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		character_util.set_direction(newtube_talent, 'down')
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		character_util.set_anim_and_emotion(newtube_talent, { name = 'idle' }, { name = 'blush' })
		if not self.inside_grid or my_req_id ~= self.grid_req_id then break end

		-- 후우...
		speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_2', skip = false })
	until not self.inside_grid or my_req_id ~= self.grid_req_id
	return
end

-- 돌을 부수고 나서 interactable 된 상태
function local_class:newtube_talent_stop_stream()
	local newtube_talent = self:get_newtube_talent()

	camera_util.move_async(newtube_talent.Position, 0.5, { ignorecameragrids = true} )

	character_util.set_direction(newtube_talent, 'left')
	character_util.set_emotion(newtube_talent, { name = 'surprise' })
	character_util.normal_jump_async(newtube_talent, '01_player_jump_01')

	wait_for_sec(1)

	newtube_talent.SpineController.AlwaysUpdateSpine = false

	-- 부, 부서졌잖아?
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	local amb_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_cf_02', loop = true, type_priority = 'event', fade_in_time = 2})
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_3', skip = true })

	character_util.remove_emotion(newtube_talent)

	character_util.set_direction(newtube_talent, 'down')
	character_util.set_anim_and_emotion(newtube_talent, { name = 'embarrassed' }, { name = 'scared' })

	-- 어 그 그러면 시청하고 계시던 여러분
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_4', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'release', sfx_name = '01_swing_01' }, { name = 'scared' })

	-- 던 전 영재의 수련 스트리밍은 사정 상 오늘 여기서 끝낼게요
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_5', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'embarrassed' }, { name = 'smile' })

	-- 하핫 여러분 그러면 모두 안녕
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_6', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'frustration', loop = false, sfx_name = '01_hit_npc_01' }, { name = 'tired' })

	-- 엄마한테 혼날텐데
	amb_sfx:FadeOut(2)
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_7', skip = true })

	newtube_talent.Interactable:AddListener(self.cs_controller)

	camera_util.return_to_leader(0.5)
	music_player_util.play_stage_music({ state = 'field' })
end

-- 상호작용시 메인 이벤트 진행
function local_class:interact_newtube_talent()
	local newtube_talent = self:get_newtube_talent()

	if self.check_ailie then
		local ailie = get_character('ailie')
		character_util.convert_to_npc(ailie)
		if lua_helper.type_compare(ailie.FieldObjectController.CurrentState,
				CS.Oak.CharacterControllerPartyFollowerNPCState) then
			CS.Oak.ICharacterExtensions.ConvertToFollowingNpc(ailie, user_party, true,
					CS.Oak.NpcFollowingStateInBattle.OutBattleZone)
		end
	end

	party_util.align_to_target(newtube_talent, 'left', nil, 'linear')

	character_util.set_direction(newtube_talent, 'left')

	character_util.remove_anim_and_emotion(newtube_talent)

	-- 기사님이 부쉈냐
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_8', skip = true })

	character_util.set_animation_n_times_async(user_party_leader, { name = 'nod', count = 2 })

	character_util.set_emotion(newtube_talent, { name = 'smile' })

	-- 고마워요. 솔직히 팔이 너무 아팠거든.
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_9', skip = true })

	character_util.set_emotion(newtube_talent, { name = 'tired' })

	-- 그치만 엄마한테 혼날 게 걱정이다
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_10', skip = true })

	character_util.set_anim(newtube_talent, { name = 'cross_arm', loop = false })

	-- 난 관심 없는데 엄마가 자꾸 뉴튜브 스타가 되어야 한다고 뭘 시킨다
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_11', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'embarrassed' }, { name = 'scared' })

	-- 구독자 수도 안 늘었는데 일찍 방송을 종료한 걸 아시면 뭐라고 하실지…
	music_player_util.play_sfx_one_shot('03_runaway_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_12', skip = true })

	choose_util.play_choose_event({ { 'nightmare_newtube_talent_sns_13' }, { 'nightmare_newtube_talent_sns_14' }})

	character_util.set_emotion(newtube_talent, { name = 'surprise' })
	character_util.normal_jump_async(newtube_talent, '01_player_jump_01')

	-- 저, 정말요?
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_15', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'idle' }, { name = 'smile' })

	-- 그러면그러면 혹시 엄마가 안 믿으면 말 좀 잘 해 줘라
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_16', skip = true })

	-- FB등록
	yield_return_func(CS.Oak.AddSNSCoroutine, self.newtube_talent_follower_id)

	character_util.set_anim_and_emotion(newtube_talent, { name = 'idle' }, { name = 'smile' })

	-- 휴 다행이다
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_17', skip = true })

	character_util.remove_anim_and_emotion(newtube_talent)

	-- 그럼 이만 가 보겠다
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_18', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'victory_get', loop = false, sfx_name = '01_player_jump_01' }, { name = 'attack' })

	-- 곧 다음 방송 시간이거든요
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_19', skip = true })

	character_util.set_direction(newtube_talent, 'right')
	character_util.set_anim_and_emotion(newtube_talent, { name = 'question', loop = false }, { name = 'idle' })

	-- 그러니까 다음 방송은… A… 그게 끝나면 저녁 식사 시간에 B
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_20', skip = true })

	character_util.set_emotion(newtube_talent, { name = 'tired' })

	-- 자기 전까지 C를 방송하다가, 자러 가면서 D…
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_21', skip = true })

	character_util.set_anim_and_emotion(newtube_talent, { name = 'idle' }, { name = 'tired' })

	-- 후우… 정말 이렇게 하면 뉴튜브 스타가 되기는 하는 걸까요
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_22', skip = true })

	character_util.remove_anim_and_emotion(newtube_talent)
	character_util.set_direction(newtube_talent, 'left')

	-- 아무튼, 그럼 다음에 또 만나요!
	speech_bubble_util.show_speech_bubble_async(newtube_talent, { key = 'nightmare_newtube_talent_sns_23', skip = true })

	local tmp = newtube_talent.Position

	character_util.move_to_async(newtube_talent, tmp + 1 * unity_class.vector3.right, nil, 5, true, true)
	character_util.move_to_async(newtube_talent, tmp + 1 * unity_class.vector3.right + 10 * unity_class.vector3.back, nil, 5, true, true)

	newtube_talent.Interactable:RemoveRelatedEvent(self.cs_controller)
	character_util.set_active_state(newtube_talent, 'disabled')

	if self.check_ailie then
		local ailie = get_character('ailie')
		character_util.convert_to_npc(ailie)
		local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(ailie, user_party, 0, 0, true,
				CS.Oak.NpcFollowingStateInBattle.OutBattleZone)
		ailie:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
		ailie.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
