local local_class = newclass('IncubusTownController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 이벤트 존 이름
	self.dream_clinic_zone_name = 'dream_clinic'

	-- 캐릭터를 가져오는 함수
	self.get_incubus = function(num) return get_character('dream_incubus_' .. num) end

	-- 예외 처리용 에일리를 가져오는 함수
	self.get_ailie = function() return get_character('ailie') end

	-- 인큐버스 수
	self.incubus_num = 4
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	for i = 1, self.incubus_num do
		local incubus = self.get_incubus(i)
		incubus.Interactable:AddListener(self.cs_controller)
	end

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	for i = 1, self.incubus_num do
		local incubus = self.get_incubus(i)
		incubus.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	for i = 1, self.incubus_num do
		local incubus = self.get_incubus(i)

		if lua_helper.reference_equals(e.Target, incubus) then
			sp_util.play_normal_screenplay(self.interact_incubus, self, i)
			return true
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == self.dream_clinic_zone_name then
			music_player:PlaySfxOneShot('01_door_push_01')
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		if e.Zone.Name == self.dream_clinic_zone_name then
			music_player:PlaySfxOneShot('01_door_push_01')
		end
	end
end

function local_class:on_stage_loaded_event(e)
	-- 한국 버전에서는 홍등가 같은 느낌을 내지않도록 함.
	if (not CS.Oak.ConstantsData.Value.ShowButcherShop:GetDecrypted() and CS.Foundations.GameEnvironment.IsKakaoKorea) then
		local gimmick_layer = stage.StageTransform:Find(string.format('%s/gimmick', stage.Name))
		local child_count = gimmick_layer.childCount

		for i = 0, child_count - 1 do
			local child = gimmick_layer:GetChild(i)
			if child.name == 'obj_redhouse' then
				child:Find('on').gameObject:SetActive(false)
				child:Find('off').gameObject:SetActive(true)
			end
		end
	end

	return false
end

-- 인큐버스에게 상호작용 했을 때
function local_class:interact_incubus(index)
	local incubus = self.get_incubus(index)

	-- 메인 퀘스트 프로그레스를 검사하여 에일리를 정렬할지 판단
	local quest_progress = user_progress:GetStartedQuest(131)
	local align_ailie = quest_progress.InnerProgress > 5 and not quest_progress.IsComplete

	if align_ailie then
		local ailie = self.get_ailie()
		local target_pos = incubus.Position + vector(1, 0, -1.5)
		character_util.move_waypoint(ailie, target_pos, 4, false, false, false, 'up')
	end

	party_util.align_to_target(incubus, 'down', 1, 'arc')

	speech_bubble_util.show_speech_bubble_async(incubus, { key = string.format('incubus_town_incubus_%d_1', index), skip = true })

	speech_bubble_util.show_speech_bubble_async(incubus, { key = string.format('incubus_town_incubus_%d_2', index), skip = true })

	-- 드림 클리닉을 받는다. / 그만둔다.
	local choose_result = choose_util.play_choose_event({ { 'incubus_town_incubus_choose_1', 'brutal' }, { 'incubus_town_incubus_choose_2', 'mercy' } })
	if choose_result == 1 then
		speech_bubble_util.show_speech_bubble_async(incubus, { key = string.format('incubus_town_incubus_%d_3', index), skip = true })

		character_util.move_waypoint(incubus, incubus.Position + vector(0, 0, 2.5), 4, false)
		character_util.move_waypoint_async(user_party_leader, user_party_leader.Position + vector(0, 0, 3.5), 4, false)
		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(incubus, { key = string.format('incubus_town_incubus_%d_4', index), skip = true })
		music_player:PlaySfxOneShot('01_keyitem_effect_01')

		local pink = (not CS.Oak.ConstantsData.Value.ShowButcherShop:GetDecrypted() and CS.Foundations.GameEnvironment.IsKakaoKorea) and unity_class.color.black or unity_color({ 1, 0.4, 0.6, 1 })
		screen_util.fade_out_async(2, pink, 'linear')

		wait_for_sec(1)
		music_player:PlaySfxOneShot('01_fade_out_01')
		screen_util.fade_in_async(1, pink, 'linear')

		field_ui_util.show_narration_async({ key = string.format('incubus_town_incubus_%d_5', index) })

		character_util.move_waypoint(user_party_leader, user_party_leader.Position + vector(0, 0, -3.5), 4, false, nil, nil, 'up')
		wait_for_sec(0.5)
		character_util.move_waypoint_async(incubus, incubus.Position + vector(0, 0, -2.5), 4, false)

		music_player:PlaySfxOneShot('02_magic_heal_02')
		character_util.spine_pulse_color(incubus, CS.Oak.Constants.DamageColor, 1, 1, 1)
		character_util.spine_damage_squish(incubus, 1.3, 0.7, 1, 0.3)
		damage_util.show_damage_number(user_party_leader, 99, unity_class.color.red, user_party_leader.Position)

		incubus.SpineController:HealGreenPulse()
		damage_util.show_damage_number(incubus, 99, unity_class.color.green, incubus.Position)
		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(incubus, { key = string.format('incubus_town_incubus_%d_6', index), skip = true })
		character_util.set_emotion(incubus, { name = 'smile' })
	else
	end

	character_util.look_at(incubus, user_party_leader)

	if align_ailie then
		local ailie = self.get_ailie()
		local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(ailie, user_party, 0, 0, true,
				CS.Oak.NpcFollowingStateInBattle.OutBattleZone)
		ailie:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
