local local_class = newclass('DemonShire4At4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 메인 퀘스트 ID
	self.main_quest_id = 286

	self.on_transition = false
	self.vent_zone_name = 'vent_entrance_'
	self.vent_zone_1 = 'vent_entrance_1'
	self.vent_zone_2 = 'vent_entrance_2'
	self.vent_zone_3 = 'vent_entrance_3'
	self.vent_zone_4 = 'vent_entrance_4'

	self.in_vent = false

	self.crawling_sfx = nil

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
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	if self.crawling_sfx ~= nil then
		self.crawling_sfx:Stop()
		self.crawling_sfx = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	if string.find(e.Target.Name, self.vent_zone_name) then
		if not self.on_transition then
			if not self.in_vent then
				if e.Target.Name == self.vent_zone_1 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'up', e.Target))
					return true
				elseif e.Target.Name == self.vent_zone_2 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'left', e.Target))
					return true
				elseif e.Target.Name == self.vent_zone_3 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'up', e.Target))
					return true
				elseif e.Target.Name == self.vent_zone_4 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'up', e.Target))
					return true
				end
			else
				if e.Target.Name == self.vent_zone_1 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'down', e.Target)
					return true
				elseif e.Target.Name == self.vent_zone_2 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'right', e.Target)
					return true
				elseif e.Target.Name == self.vent_zone_3 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'down', e.Target)
					return true
				elseif e.Target.Name == self.vent_zone_4 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'down', e.Target
					, vector(0, 0, -0.25))
					return true
				end
			end

		end
	end
end

function local_class:on_move_fo_event(e)
	if not self.in_vent then return false end

	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.crawling_sfx == nil or not self.crawling_sfx.IsUsing then
			if self.crawling_sfx ~= nil then
				self.crawling_sfx:Stop()
				self.crawling_sfx = nil
			end
			self.crawling_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_04', loop = false })
		end
	end

	return false
end

function local_class:exit_hole_event(dir_str, target, add_pos)
	self.on_transition = true
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transition_start' }))

	local dir = vector(0, 0, 0)
	if dir_str == 'left' then
		dir = vector(-1, 0, 0)
	elseif dir_str == 'right' then
		dir = vector(1, 0, 0)
	elseif dir_str == 'up' then
		dir = vector(0, 0, 1)
	elseif dir_str == 'down' then
		dir = vector(0, 0, -1)
	else
		dir_str = 'none'
	end

	if add_pos then
		dir = dir + add_pos
	end

	party_util.align_party(target.Position + dir * 0.3,
			direction_util.get_opposite(character_util.get_direction(dir_str)), 0.7, 'linear')

	dir = dir * 1.7

	self:change_party_member_4legs(false)

	local party = {}
	for i = 0, user_party.Count - 1 do
		local c = user_party[i]
		table.insert(party, { npc = c, origin = c.Position })
		character_util.set_anim(c, { name = 'walk4legs' })
		character_util.set_direction(c, dir_str)
	end

	local timer = 0
	local duration = 1.5
	local stamps = {
		0.3, 0.8, 1.3
	}
	local states = {
		false, false, false
	}

	music_player_util.play_sfx_one_shot('01_grass_slide_02')

	while timer < duration do
		local progress = timer / duration
		local dt = unity_class.time.deltaTime

		for i, data in ipairs(party) do
			if stamps[i] < timer and not states[i] then
				states[i] = true
				music_player_util.play_sfx_one_shot('01_rustle_01')
				character_util.set_anim(data.npc, { name = 'walk' })
			end
			character_util.set_position(data.npc, data.origin + dir * progress)
		end
		coroutine.yield()
		timer = timer + dt
	end

	for i, data in ipairs(party) do
		character_util.set_position(data.npc, data.origin + dir)
	end

	party_util.remove_animation()

	wait_for_sec(0.1)

	self.on_transition = false
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transition_complete' }))

	self.in_vent = not self.in_vent
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
--endregion

function local_class:enter_hole_event(dir_str, target)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.on_transition = true
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transition_start' }))

	local dir = vector(0, 0, 0)
	if dir_str == 'left' then
		dir = vector(-1, 0, 0)
	elseif dir_str == 'right' then
		dir = vector(1, 0, 0)
	elseif dir_str == 'up' then
		dir = vector(0, 0, 1)
	elseif dir_str == 'down' then
		dir = vector(0, 0, -1)
	else
		dir_str = 'none'
	end

	party_util.align_party(target.Position + dir * 0.3,
			direction_util.get_opposite(character_util.get_direction(dir_str)), 0.7, 'linear')

	dir = dir * 1.7

	local party = {}
	for i = 0, user_party.Count - 1 do
		local c = user_party[i]
		table.insert(party, { npc = c, origin = c.Position })
		character_util.set_anim(c, { name = 'walk' })
		character_util.set_direction(c, dir_str)
	end

	local timer = 0
	local duration = 1.2
	local stamps = {
		0, 0.5, 1
	}
	local states = {
		false, false, false
	}

	music_player_util.play_sfx_one_shot('01_grass_slide_02')

	while timer < duration do
		local progress = timer / duration
		local dt = unity_class.time.deltaTime

		for i, data in ipairs(party) do
			if stamps[i] < timer and not states[i] then
				states[i] = true
				music_player_util.play_sfx_one_shot('01_rustle_01')
				character_util.set_anim(data.npc, { name = 'walk4legs' })
			end
			character_util.set_position(data.npc, data.origin + dir * progress)
		end
		coroutine.yield()
		timer = timer + dt
	end

	for i, data in ipairs(party) do
		character_util.set_position(data.npc, data.origin + dir)
	end

	self:change_party_member_4legs(true)

	wait_for_sec(0.1)

	self.on_transition = false

	party_util.remove_animation()

	party_util.reset_controllers()
	field_ui_manager:Show()

	local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party.Leader, false)
	manual_touch_state:DisableControls(CS.Oak.DisabledControls.Dash | CS.Oak.DisabledControls.Attack | CS.Oak.DisabledControls.Super)

	local state_change_event = CS.Oak.StateChangeEvent.Create(manual_touch_state)
	message_system:SendSync(user_party.Leader.FieldObjectController, state_change_event)
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { 'transition_complete' }))

	self.in_vent = not self.in_vent
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local save_vamp_town_progress = user_progress:GetStartedQuest(308)

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
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music, fade)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)
		local fade_screen = lua_helper.get_or_default(fade, true)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			if fade_screen then
				screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
				screen_util.fade_in_circular(1, 'linear')
			end

			coroutine.yield(stage_launch_util.directional_stage_entry(leader.Position, leader.Direction,
					game_string:GetString(stage.Name), true, play_stage_music))

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress ~= nil and main_quest_progress.InnerProgress == 27
			and save_vamp_town_progress ~= nil and not save_vamp_town_progress.IsComplete then
		local is_play_stage_entry = save_vamp_town_progress.InnerProgress > 0
		change_leader_character({ self.get_sohee() })
		start_stage_event('left', field:GetMarker('default_start').position,
				is_play_stage_entry, false)
	else
		change_leader_character({ self.get_sohee() })
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
	end
end

function local_class:change_party_member_4legs(to_walk_4legs)
	for i = 0, user_party.Count - 1 do
		local character = user_party[i]
		if to_walk_4legs then
			character.CustomIdleAnimationName = 'meditation'
			character.CustomWalkAnimationName = 'walk4legs'

			buff_manager:AddBuff(character, CS.Oak.EquipmentSlot.None, character, 'speed_down_persistent', 60, false, false)

		else
			character.CustomIdleAnimationName = ''
			character.CustomWalkAnimationName = ''

			buff_manager:RemoveBuff(character, CS.Oak.EquipmentSlot.None, character, 'speed_down_persistent')
		end
	end
end

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
