local local_class = newclass('DemonShire4At1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 소히
	self.get_sohee = function()
		return get_character('sohee')
	end

	-- 백작의 딸
	self.get_count_daughter = function()
		return get_character('count_daughter')
	end

	-- npc
	self.get_wall_shadow_spirit = function(number)
		return get_character('shadow_spirit_wall_' .. number)
	end

	self.center_civilian = function(number)
		return get_character('center_civilian_' .. number)
	end

	-- effect
	self.get_sun_effect = function()
		return unity_object_pool.GetOrCreate('fx_theater_demonshire_sun_big')
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	self.guard_appear_check = true

	-- 존 진입을 막을 건지
	self.zone_event_option = false
	self.zone_string_key = 'ds_main_s27_zone_out'
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	self.get_sun_effect()
	yield_return(unity_object_pool, 'WaitAll')
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	-- 태양 이팩트 dispose
	if self.sun_effect then
		self.sun_effect:Dispose()
		self.sun_effect = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 's26_event_out_zone_down') and
			self.zone_event_option then
		sp_util.play_normal_screenplay(self.event_out_zone, self, vector(0, 0, -2))
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 's29_zone_event_open' then
		self.zone_event_option = false
		return true
	end
	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == 286 then
		if e.CurrentProgress == 26 then
			self.zone_event_option = true
			self:enabled_monster_group('visible')
			return true
		end
	end
	return false
end

function local_class:pre_setting()
	local exit = get_field_object('exit_demonshire_4_5')
	local exit_renderer_tf = exit.Transform:Find('exit_tile 1')
	exit_renderer_tf.gameObject:SetActive(false)

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
				leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 태양 세팅
	local sun_pos = field:GetMarker('s26_intro_sun_pos').position
	self.sun_effect = self.get_sun_effect():Instantiate(sun_pos)
	self.sun_effect.transform.localRotation = unity_class.quaternion.Euler(90, 0, 0)

	-- 파티가 시작할 지점을 읽어온다.
	local startMarker = field:GetMarker('default_start')
	if not string_helper.is_nil_or_empty(stage.StartWaypoint) then
		startMarker = field:GetMarker(stage.StartWaypoint)
	end

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		self:enabled_monster_group('disabled')
		self:disabled_shelter_monster()
		start_stage_event(startMarker.direction, startMarker.position, true, true)
	elseif main_quest_progress.InnerProgress == 25 then
		self:enabled_monster_group('out')
		change_leader_character({ self.get_sohee() })
		start_stage_event('right', field:GetMarker('s26_knight_pos').position + vector(0.5, 0, 0),
				false, true)
	elseif main_quest_progress.InnerProgress == 26 then
		change_leader_character({ self.get_sohee() })
		self:enabled_monster_group('enabled')
		self:disabled_shelter_monster()
		self.zone_event_option = true
		start_stage_event(startMarker.direction, startMarker.position, false, true)
	elseif main_quest_progress.InnerProgress == 27 then
		self.zone_event_option = true
		self:enabled_prison_group()
		self:enabled_researcher_group()
		self:enabled_vampire_town_group()
		self:enabled_monster_group('enabled')
		self:disabled_shelter_monster()
		self:guard_appear()
		change_leader_character({ self.get_sohee() })
		start_stage_event(startMarker.direction, startMarker.position, true, true)
	elseif main_quest_progress.InnerProgress == 28 then
		self.zone_event_option = true
		self:enabled_monster_group('disabled')
		self:disabled_shelter_monster()
		self:enabled_prison_group()
		self:enabled_researcher_group()
		self:enabled_vampire_town_group()
		change_leader_character({ self.get_sohee() })
		start_stage_event(startMarker.direction, startMarker.position, true, true)
	else
		self:enabled_monster_group('disabled')
		self:disabled_shelter_monster()
		change_leader_character({ self.get_sohee() })
		start_stage_event(startMarker.direction, startMarker.position, true, true)
	end
end


-- 시민 그룹 활성화
function local_class:enabled_civil_group()
	local civil_num = 4
	local civil_key_name = 's29_civilian_'

	local guard_num = 5
	local guard_key_name = 's29_guard_'

	for i = 1, civil_num do
		character_util.set_active_state(get_character(civil_key_name .. i), 'enabled')
	end
	for i = 1, guard_num do
		character_util.set_active_state(get_character(guard_key_name .. i), 'enabled')
	end
end

-- 뱀파이어 거주지 그룹 활성화
function local_class:enabled_vampire_town_group()
	if user_progress:IsStageCleared('demonshire_4_4') then
		self.guard_appear_check = false
		local vampire_town_num = 8
		local vampire_town_key_name = 's29_vampire_town_'

		for i = 1, vampire_town_num do
			character_util.set_active_state(get_character(vampire_town_key_name .. i), 'enabled')
		end
	end
end

-- 감옥 그룹 활성화
function local_class:enabled_prison_group()
	if user_progress:IsStageCleared('demonshire_4_2') then
		self.guard_appear_check = false
		local prison_num = 8
		local prison_key_name = 's29_prison_'

		for i = 1, prison_num do
			local npc = get_character(prison_key_name .. i)
			character_util.set_active_state(npc, 'enabled')
			if i > 4 then
				character_util.set_emotion(npc, { name = 'awesome' })
			end
		end
	end
end

-- 연구원 그룹 활성화
function local_class:enabled_researcher_group()
	if user_progress:IsStageCleared('demonshire_4_5') then
		self.guard_appear_check = false
		local researcher_num = 8
		local researcher_key_name = 's29_researcher_'

		for i = 1, researcher_num do
			character_util.set_active_state(get_character(researcher_key_name .. i), 'enabled')
		end
	end
end

function local_class:enabled_monster_group(enabled_op)
	if enabled_op == 'visible' then
		for i = 1, 7 do
			local npc_1 = get_character('fieldbattle_1_' .. i)
			local npc_2 = get_character('fieldbattle_3_' .. i)

			character_util.set_active_state(npc_1, 'visible')
			character_util.set_active_state(npc_2, 'visible')
		end

		for i = 1, 4 do
			local npc_1 = get_character('fieldbattle_2_1_' .. i)
			local npc_2 = get_character('fieldbattle_2_2_' .. i)

			character_util.set_active_state(npc_1, 'visible')
			character_util.set_active_state(npc_2, 'visible')
		end

		local npc = get_character('fieldbattle_2_1_5')
		character_util.set_active_state(npc, 'visible')
	elseif enabled_op == 'out' then
		for i = 1, 7 do
			local npc_1 = get_character('fieldbattle_1_' .. i)
			local npc_2 = get_character('fieldbattle_3_' .. i)

			-- 예외처리로 진입 못하도록 막고 있으므로 조건 수정
			character_util.set_active_state(npc_1, 'disabled')
			character_util.set_active_state(npc_2, 'disabled')
		end

		for i = 1, 4 do
			local npc_1 = get_character('fieldbattle_2_1_' .. i)
			local npc_2 = get_character('fieldbattle_2_2_' .. i)

			-- 예외처리로 진입 못하도록 막고 있으므로 조건 수정
			character_util.set_active_state(npc_1, 'disabled')
			character_util.set_active_state(npc_2, 'disabled')
		end

		local npc = get_character('fieldbattle_2_1_5')
		-- 예외처리로 진입 못하도록 막고 있으므로 조건 수정
		character_util.set_active_state(npc, 'disabled')
	elseif enabled_op == 'disabled' then
		for i = 1, 7 do
			local npc_1 = get_character('fieldbattle_1_' .. i)
			local npc_2 = get_character('fieldbattle_3_' .. i)

			character_util.set_active_state(npc_1, 'disabled')
			character_util.set_active_state(npc_2, 'disabled')
			message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(npc_1, npc_1.Position, npc_1.Hitbox))
			message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(npc_2, npc_2.Position, npc_2.Hitbox))
		end

		for i = 1, 4 do
			local npc_1 = get_character('fieldbattle_2_1_' .. i)
			local npc_2 = get_character('fieldbattle_2_2_' .. i)

			character_util.set_active_state(npc_1, 'disabled')
			character_util.set_active_state(npc_2, 'disabled')
			message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(npc_1, npc_1.Position, npc_1.Hitbox))
			message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(npc_2, npc_2.Position, npc_2.Hitbox))
		end

		local npc = get_character('fieldbattle_2_1_5')
		character_util.set_active_state(npc, 'disabled')
		message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(npc, npc.Position, npc.Hitbox))
	end
end

function local_class:event_out_zone(dir)
	local sohee = self.get_sohee()
	local leader = get_party_leader()

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.look_at(sohee, leader)
	character_util.play_speech_action(sohee, { name = 'release', sfx_name = '01_swing_01' },
			{ name = 'attack' }, { key = self.zone_string_key, skip = true })

	character_util.move_distance_async(leader, dir, 1, nil, true, true)
end

function local_class:guard_appear()
	if not self.guard_appear_check then
		self:enabled_civil_group()
		return
	end

	for i = 1, 14 do
		if i > 5 or i == 3 then
			self:setting_push_npc(i, false)
		else
			self:setting_push_npc(i, true)
		end
	end
end

function local_class:setting_push_npc(marker_index, sub_index_check)

	local guard = get_character('royalguard_' .. marker_index)
	local shadow = get_character('s27_push_shadow_' .. marker_index)
	local guard_pos = field:GetMarker('s27_push_pos_' .. marker_index .. '_1').position
	local shadow_pos = field:GetMarker('s27_push_pos_' .. marker_index .. '_2').position
	if sub_index_check then
		shadow_pos = field:GetMarker('s27_push_pos_' .. marker_index .. '_2').position
		guard_pos = field:GetMarker('s27_push_pos_' .. marker_index .. '_3').position
	end

	character_util.set_position(guard, guard_pos)
	character_util.set_position(shadow, shadow_pos)
	character_util.look_at(guard, shadow)
	character_util.look_at(shadow, guard)
	local guard_move = direction_util.to_vector3(guard.Direction) * 0.25
	local shadow_move = direction_util.to_vector3(shadow.Direction) * 0.25
	character_util.set_position(guard, guard_pos + guard_move)
	character_util.set_position(shadow, shadow_pos + shadow_move)
	character_util.set_group_anim_and_emotion({ guard, shadow },
			{ name = 'push' }, { name = 'attack' })
	character_util.shake(guard, 0.03, 9999)
	character_util.shake(shadow, 0.03, 9999)
end

function local_class:disabled_shelter_monster()
	for i = 1, 3 do
		for j = 1, 8 do
			local enemy = get_character('battle_' .. i .. '_' .. j)
			character_util.set_active_state(enemy, 'disabled')
			message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(enemy, enemy.Position, enemy.Hitbox))
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
