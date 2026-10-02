local local_class = newclass("LilithTowerMain1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'lilithtower_1_1'

	-- 윈도우 브레이커 이벤트 key
	self.windows_breaker_key = 'windows_breaker'

	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 수트 맨손 기사
	self.get_knight_suit = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit')
		else
			return get_character('knight_female_suit')
		end
	end

	-- 수트 양손 기사
	self.get_knight_suit_bat = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit_bat')
		else
			return get_character('knight_female_suit_bat')
		end
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 바위 터질때 사용할 이팩트 미리 로드
	unity_object_pool.GetOrCreate('FX_Env_SmallRock_lv1_destroy_gray')

	-- 리소스 로드를 기다림
	yield_return(unity_object_pool, 'WaitAll')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		0,
		1,
		2,
		3
	}

	-- 리더를 기사로 바꿈
	-- 방망이를 얻었다면 방망이를 든 기사로
	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	local leader = nil
	if quest_progress.InnerProgress ~= 0 and quest_progress.InnerProgress <= 2 then
		leader = self.get_knight()
	elseif quest_progress.InnerProgress >= 3 then
		-- suit 상태일경우 재입장시 id 변경
		character_spec_id = 302922
		if user_util.has_knight_male() then
			character_spec_id = 302921
		end

		if quest_util.get_custom_state(quest_progress, self.windows_breaker_key) >= 1 then
			leader = self.get_knight_suit_bat()
		else
			leader = self.get_knight_suit()
		end
	end

	if leader ~= nil then
		character_util.convert_to_manual_character(leader)
		user_party.Leader.CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(user_party_leader.CharacterInfo.User, character_spec_id)

		leader.Position = vector(0, 0, 0)
	end

	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 255), 0))

	if quest_progress ~= nil then
		if quest_progress.InnerProgress > 3 then
			get_field_object('exit_passage_13_1').Position = vector(0.5, 0, 5.5)

			get_field_object('pillar_hitbox_1').Position = vector(-4.5, 0, 43)
			get_field_object('pillar_hitbox_1').Hitbox = CS.Oak.Hitbox(vector(2, 1, 6))
			get_field_object('pillar_piece_1').Position = vector(-4.75, 0, 45)
			get_field_object('lobby_pillar_1').transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator)):Play('open')

			get_field_object('pillar_hitbox_2').Position = vector(8.5, 0, 40.5)
			get_field_object('pillar_hitbox_2').Hitbox = CS.Oak.Hitbox(vector(8, 1, 2))
			get_field_object('pillar_piece_2').Position = vector(9.75, 0, 40.25)
			get_field_object('lobby_pillar_2').transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator)):Play('open')

			get_field_object('pillar_hitbox_3').Position = vector(-7.5, 0, 50)
			get_field_object('pillar_hitbox_3').Hitbox = CS.Oak.Hitbox(vector(7, 1, 2))
			get_field_object('pillar_piece_3').Position = vector(-9.75, 0, 50)
			get_field_object('lobby_pillar_3').transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator)):Play('open')

			get_field_object('pillar_hitbox_4').Position = vector(5.5, 0, 48)
			get_field_object('pillar_hitbox_4').Hitbox = CS.Oak.Hitbox(vector(2, 1, 6))
			get_field_object('pillar_piece_4').Position = vector(4.75, 0, 45.5)
			get_field_object('lobby_pillar_4').transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator)):Play('open')

			get_character('terror_1_1').Position = vector(-2.5, 0, 4)
			character_util.set_anim(get_character('terror_1_1'), { name = 'rifle_idle' })
			character_util.remove_emotion(get_character('terror_1_1'))
			get_character('terror_1_1').FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(get_character('terror_1_1'), 'entrance_guard', 4, 60)

			get_character('terror_1_2').Position = vector(0.5, 0, 4)
			character_util.set_anim(get_character('terror_1_2'), { name = 'rifle_idle' })
			character_util.remove_emotion(get_character('terror_1_2'))
			get_character('terror_1_2').FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(get_character('terror_1_2'), 'entrance_guard', 4, 60)

			get_character('terror_1_3').Position = vector(3.5, 0, 4)
			character_util.set_anim(get_character('terror_1_3'), { name = 'rifle_idle' })
			character_util.remove_emotion(get_character('terror_1_3'))
			get_character('terror_1_3').FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(get_character('terror_1_3'), 'entrance_guard', 4, 60)
		end
	end

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:opening_routine(innerprogress, IsComplete)
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if quest_progress ~= nil and not quest_progress.IsComplete then
		if quest_progress.InnerProgress ~= 0 then
			character_util.set_active_state(user_party.Leader, "enabled")
			character_util.set_active_state(get_character('trouble_shooter'), "enabled")
			character_util.set_active_state(get_character('mad_scientist'), "enabled")

			get_character('trouble_shooter').Position = vector(0, 0, -1)
			get_character('mad_scientist').Position = vector(0, 0, -2)

			character_util.convert_to_party_member(get_character('trouble_shooter'), user_party, true)
			character_util.convert_to_party_member(get_character('mad_scientist'), user_party, true)

			if quest_progress.InnerProgress == 3 then
				character_util.set_active_state(get_character('secretary'), "enabled")
				get_character('secretary').Position = vector(0, 0, -3)
				character_util.convert_to_following_npc(get_character('secretary'), user_party, false, CS.Oak.NpcFollowingStateInBattle.OutBattleZone, 0)
			end
		end
	end

	user_party:ResetControllers()
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
end

function local_class:on_stage_loaded_event(e)
	get_field_object('gate_wall').Hitbox = CS.Oak.Hitbox(vector(12, 1, 1))

	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if quest_progress ~= nil and (quest_progress.InnerProgress >= 4 or quest_progress.IsComplete) then
		local office_door = get_field_object('s4_office_door')
		animator_util.play(office_door, 'end')
		office_door.ActiveState = CS.Oak.ActiveState.Visible
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == 'skybridge' then
			message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(255, 255, 255, 255), 0))
		elseif e.Zone.Name == 'skybridge_out' then
			message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))
		end
	end

	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
