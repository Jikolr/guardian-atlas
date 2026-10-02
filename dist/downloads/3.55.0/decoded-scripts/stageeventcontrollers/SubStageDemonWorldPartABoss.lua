local local_class = newclass("SubStageDemonWorldPartABossController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.stage_name = 'substage_12_3'

	self.get_npc = function (num) return get_character('outside_'..num) end

	self.entry_event_flag = false
	self.entry_event_off = false
	self.entry_event_speech = true

	self.show_background_event_zone = 'show_background_zone'

	self.entry_event_voice_zone = 'entry_event_voice_zone'
	self.voice_zone_flag = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	if stage.Name == self.stage_name then
		quest_util.load_pool_resource(
			-- 'stage_item'
		)
	end
end

function local_class:need_on_launch()
	local main_quest_id = 216
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		16,
		17
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	if stage.Name == self.stage_name then
		if not user_progress:IsStageCleared(stage.Name) then
			-- 보스 스테이지 클리어하기 전에는 아래 BGM이 재생되어야 함
			music_player_util.play_stage_music({ name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_event_8', state = 'field' })
		end
	end

	self:outside_npc_setting()

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	--공주 파티 합류 및 파티원 전원 날리기
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:opening_routine(innerprogress, IsComplete)
	local main_quest_id = 216
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)


	user_party:ResetControllers()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.entry_event_flag = nil
	self.entry_event_off = nil
	self.entry_event_speech = nil
	self.voice_zone_flag = nil

	self.cs_controller = nil
end

--region on_event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	local invisible_wall = get_field_object('window_wall')
	invisible_wall.ActiveState = CS.Oak.ActiveState.Enabled
	invisible_wall.Hitbox = CS.Oak.Hitbox(vector(1, 1, 12))
	invisible_wall.Position = vector(58, 0, 4.5)

	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == self.show_background_event_zone then
				message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(255, 255, 255, 255), 0))
				return true
			elseif e.Zone.Name == 'entry_event' and not user_progress:IsStageCleared(self.stage_name) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.entry_event, self))
				return true
			elseif e.Zone.Name == 'turing_office_outside_zone' and not user_progress:IsStageCleared(self.stage_name) then
				self.entry_event_flag = false
				self.entry_event_off = false
				return true
			elseif e.Zone.Name == self.entry_event_voice_zone then
				self.voice_zone_flag = true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave then
		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == self.show_background_event_zone then
				message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))
				return true
			elseif e.Zone.Name == self.entry_event_voice_zone then
				self.voice_zone_flag = false
			end
		end
	end

	return false
end
--endregion

function local_class:outside_npc_setting()
	if user_progress:IsStageCleared(self.stage_name) then
		-- 스테이지 클리어 했을 경우 바깥 npc disabled
		for i = 1, 8 do
			if i ~= 4 then
				character_util.set_position(self.get_npc(i), vector(999, 0, 999))
				character_util.set_active_state(self.get_npc(i), 'disabled')
			end
		end
	else
		-- 클리어 전일 경우 npc 세팅
		character_util.set_anim(self.get_npc(1), {name = 'bomb_idle'})

		-- 이번 일만 끝나면 우리도 자유를 얻게 되는 건가…?
		self.get_npc(7).Interactable.Talk = 'demonworld_part1_sub_boss_online_4'

		-- 꿈만 같군.
		self.get_npc(2).Interactable.Talk = 'demonworld_part1_sub_boss_online_5'
		character_util.set_anim(self.get_npc(2), {name = 'cast'})
		character_util.set_emotion(self.get_npc(2), {name = 'smile'})

		-- 이곳은 튜링의 구역이다.
		self.get_npc(5).Interactable.Talk = 'demonworld_part1_sub_boss_online_6'
		character_util.set_position(self.get_npc(5), vector(162, 0, -54.5))
		character_util.set_anim(self.get_npc(5), {name = 'idle'})
		character_util.set_emotion(self.get_npc(5), {name = 'idle'})
	end
end

function local_class:entry_event()
	if self.entry_event_flag then return end
	self.entry_event_flag = true
	self.entry_event_off = true

	if self.entry_event_speech then
		self.entry_event_speech = false
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			-- 유기물이 겁도 없군.
			speech_bubble_util.show_speech_bubble_async(self.get_npc(1), { key = 'demonworld_part1_sub_boss_online_1', dialogue = self.voice_zone_flag})
			-- 이 골목에 들어온 이상 각오는 되어 있겠지?
			speech_bubble_util.show_speech_bubble_async(self.get_npc(3), { key = 'demonworld_part1_sub_boss_online_2', dialogue = self.voice_zone_flag})
			-- 히...히이익
			speech_bubble_util.show_speech_bubble_async(self.get_npc(6), { key = 'demonworld_part1_sub_boss_online_3', scale = 0.8, dialogue = self.voice_zone_flag})
		end))
	end

	while true do
		character_util.shake(self.get_npc(6), 0.05, 1)
		wait_for_sec(2)
		if not self.entry_event_off then
			break
		end
	end

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
