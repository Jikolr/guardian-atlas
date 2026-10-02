local local_class = newclass("Movie1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.main_quest_num = 60005

	self.tourist_talker_1 = 'tourist_1'
	self.tourist_talker_2 = 'tourist_2'
	self.tourist_talker_3 = 'tourist_3'
	self.tourist_kid_1 = "tourist_kid_13"
	self.tourist_kid_2 = "tourist_kid_14"
	self.fight_tourist_1 = 'fight_tourist_10'
	self.fight_tourist_2 = 'fight_tourist_11'
	self.ice_cream_tourist_1 = 'tourist_12'
	self.ice_cream_tourist_2 = 'tourist_13'

	self.tourist_talk_1_zonename = 'tourist_talk_zone'

	self.seen_tourist_talk_1 = false

	self.ice_cream_tourist_coroutine_1 = nil
	self.ice_cream_tourist_coroutine_2 = nil
	self.club_dj = 'club_dj'
	self.club_dancer_1 = 'club_dancer_1'
	self.club_dancer_2 = 'club_dancer_2'
	self.club_dancer_3 = 'club_dancer_3'
	self.club_dancer_4 = 'club_dancer_4'
	self.club_dancer_5 = 'club_dancer_5'
	self.club_dancer_6 = 'club_dancer_6'
	self.club_dancer_7 = 'club_dancer_7'
	self.club_dancer_8 = 'club_dancer_8'
	self.club_dancer_9 = 'club_dancer_9'
	self.club_dancer_10 = 'club_dancer_10'
	self.club_dancer_11 = 'club_dancer_11'
	self.club_dancer_12 = 'club_dancer_12'
	self.club_dancer_13 = 'club_dancer_13'
	self.club_dancer_14 = 'club_dancer_14'
	self.club_dancer_15 = 'club_dancer_15'

	self.club_event_zone_name = 'enter_club'
	self.club_out_event_zone_name = 'exit_club'
	self.under_pass_zone_name = 'under_pass'

	self.tourist_talk_event_custom_key = "tourist_talk_event"
	self.stop_club_event_custom_key = "stop_club_event"

	self.get_club_hidden_stair = function() return get_field_object('club_hidden_stair') end
	self.get_club_speaker = function() return get_field_object('club_speaker') end

	self.is_in_club = false

	self.under_pass_sfx = nil

	self.club_coroutine = nil

	self.club_dance_routine = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	local ice_cream_tourist_1 = get_character(self.ice_cream_tourist_1)
	ice_cream_tourist_1.Interactable:AddListener(self.cs_controller)

	local ice_cream_tourist_2 = get_character(self.ice_cream_tourist_2)
	ice_cream_tourist_2.Interactable:AddListener(self.cs_controller)

	local club_hidden_stair = self:get_club_hidden_stair()
	character_util.set_active_state(club_hidden_stair, 'disabled')

	local club_speaker = self:get_club_speaker()
	club_speaker.EntityGroup = CS.Oak.EntityGroups.Enemy
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	local main_quest = user_progress:GetStartedQuest(self.main_quest_num)

	return main_quest == nil or main_quest.InnerProgress < 1
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	local ice_cream_tourist_1 = get_character(self.ice_cream_tourist_1)
	ice_cream_tourist_1.Interactable:RemoveRelatedEvent(self.cs_controller)

	local ice_cream_tourist_2 = get_character(self.ice_cream_tourist_2)
	ice_cream_tourist_2.Interactable:RemoveRelatedEvent(self.cs_controller)

	self:stop_coroutine(self.ice_cream_tourist_coroutine_1)
	self.ice_cream_tourist_coroutine_1 = nil

	self:stop_coroutine(self.ice_cream_tourist_coroutine_2)
	self.ice_cream_tourist_coroutine_2 = nil

	self.under_pass_sfx = nil

	self.club_coroutine = nil
	self.club_dance_routine = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fight_tourist_event, self))
	self.club_dance_routine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.club, self))
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and e.FieldObject == user_party_leader then
		if e.Zone.Name == self.tourist_talk_1_zonename then
			if not self.seen_tourist_talk_1 then
				self.seen_tourist_talk_1 = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tourist_talk_in_zone, self))
			end
		elseif e.Zone.Name == self.club_event_zone_name and not self.is_in_club then
			music_player_util.play_stage_music({ name = 'ondemand/movie/audio:bgm_techno', state = 'event', mix = 2 })

			self.is_in_club = true
			self.club_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.club_tint, self))
		elseif e.Zone.Name == self.club_out_event_zone_name then
			music_player_util.play_stage_music({ state = 'field', mix = 2 })

			self:stop_coroutine(self.club_coroutine)
			self.club_coroutine = nil

			self:club_tint_end()
			self.is_in_club = false
		elseif e.Zone.Name == self.under_pass_zone_name then
			music_player_util.play_stage_music({ state = 'muted', mix = 2 })
			self.under_pass_sfx = music_player_util.play_sfx({ sfx_name = '01_magic_circle_active_01', loop = true, type_priority = 'loop' })
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and e.FieldObject == user_party_leader then
		if e.Zone.Name == self.under_pass_zone_name then
			self.under_pass_sfx:FadeOut(0.3)
			self.under_pass_sfx = nil
			music_player_util.play_stage_music({ state = 'field', mix = 2 })
		end
	end
end

function local_class:stop_coroutine(coroutine)
	if coroutine ~= nil then
		stop_coroutine(coroutine)
	end
end

function local_class:on_interact_event(e)
	local ice_cream_tourist_1 = get_character(self.ice_cream_tourist_1)
	local ice_cream_tourist_2 = get_character(self.ice_cream_tourist_2)

	if lua_helper.reference_equals(e.Target, ice_cream_tourist_1) then
		self:stop_coroutine(self.ice_cream_tourist_coroutine_1)
		self.ice_cream_tourist_coroutine_1 = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ice_cream_tourist_talk_1, self))
	elseif lua_helper.reference_equals(e.Target, ice_cream_tourist_2) then
		self:stop_coroutine(self.ice_cream_tourist_coroutine_2)
		self.ice_cream_tourist_coroutine_2 = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ice_cream_tourist_talk_2, self))
	end
end

function local_class:on_field_object_destroyed_event(e)
	local club_speaker = self:get_club_speaker()

	if lua_helper.reference_equals(e.FieldObject, club_speaker) then
		local club_hidden_stair = self:get_club_hidden_stair()
		character_util.set_active_state(club_hidden_stair, 'enabled')
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.stop_club_event_custom_key then
			self:stop_coroutine(self.club_dance_routine)
			self.club_dance_routine = nil
		elseif e.Params[0] == self.tourist_talk_event_custom_key then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tourist_talk_in_zone, self))
		end
	end
end

function local_class:club_tint()
	local color_list = { CS.UnityEngine.Color(0.41015625, 0.12890625, 0.55078125, 1), CS.UnityEngine.Color(0.7578125, 0.37109375, 0.78515625, 1) }

	while true do
		for i = 1, #color_list do
			field:Tint('club', color_list[i], 0.9)
			wait_for_sec(0.9)
			field:Tint('club_base', color_list[i], 0)
		end
	end
end

function local_class:club_tint_end()
	field:RemoveTint()
end

function local_class:tourist_talk_in_zone()
	local tourist_talker_1 = get_character(self.tourist_talker_1)
	local tourist_talker_2 = get_character(self.tourist_talker_2)
	local tourist_talker_3 = get_character(self.tourist_talker_3)

	wait_for_sec(1.5)

	character_util.set_anim(tourist_talker_1, { key = 'cross_arm', loop = false })

	speech_bubble_util.show_speech_bubble_async(tourist_talker_1, { key = 'movie_main_npc_28' })

	character_util.remove_anim(tourist_talker_1)

	character_util.set_anim(tourist_talker_2, { key = 'release', sfx_name = '01_swing_01' })
	character_util.set_direction(tourist_talker_2, 'right')
	character_util.set_emotion(tourist_talker_2, { name = 'attack' })

	character_util.set_direction(tourist_talker_3, 'left')

	speech_bubble_util.show_speech_bubble_async(tourist_talker_2,{ key = 'movie_main_npc_29' })

	character_util.remove_anim(tourist_talker_2)
	character_util.remove_emotion(tourist_talker_2)

	character_util.set_anim(tourist_talker_3, { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(tourist_talker_3, { key = 'movie_main_npc_30' })

	character_util.remove_anim(tourist_talker_3)
end

function local_class:fight_tourist_event()
	local fight_tourist_1 = get_character(self.fight_tourist_1)
	local fight_tourist_2 = get_character(self.fight_tourist_2)
	local attack = function(sender, target)
		character_util.set_anim(sender, { name = 'attack', loop = false })
		wait_for_sec(0.25)
		target.SpineController:DamageSquish(1)
		target.SpineController:DamageRedPulse()
		wait_for_sec(0.5)
		character_util.remove_anim(sender)
	end

	character_util.set_direction(fight_tourist_1, 'right')
	character_util.set_direction(fight_tourist_2, 'left')
	character_util.set_emotion(fight_tourist_1, { name = 'attack' })
	character_util.set_emotion(fight_tourist_2, { name = 'attack' })

	while true do
		attack(fight_tourist_1, fight_tourist_2)
		attack(fight_tourist_2, fight_tourist_1)
	end
end

function local_class:ice_cream_tourist_talk_1()
	local tourist = get_character(self.ice_cream_tourist_1)

	character_util.look_at(tourist, user_party_leader)
	speech_bubble_util.show_speech_bubble_async(tourist, { key = 'movie_main_npc_20' })
	character_util.set_direction(tourist, 'down')
end


function local_class:club()
	local club_dj = get_character(self.club_dj)
	local club_dancer_1 = get_character(self.club_dancer_1)
	local club_dancer_2 = get_character(self.club_dancer_2)
	local club_dancer_3 = get_character(self.club_dancer_3)
	local club_dancer_4 = get_character(self.club_dancer_4)
	local club_dancer_5 = get_character(self.club_dancer_5)
	local club_dancer_6 = get_character(self.club_dancer_6)
	local club_dancer_7 = get_character(self.club_dancer_7)
	local club_dancer_8 = get_character(self.club_dancer_8)
	local club_dancer_9 = get_character(self.club_dancer_9)
	local club_dancer_10 = get_character(self.club_dancer_10)
	local club_dancer_11 = get_character(self.club_dancer_11)
	local club_dancer_12 = get_character(self.club_dancer_12)
	local club_dancer_13 = get_character(self.club_dancer_13)
	local club_dancer_14 = get_character(self.club_dancer_14)
	local club_dancer_15 = get_character(self.club_dancer_15)

	-- FIXME: 이런식으로 말고, 개별적으로 루틴이 돌아게게 수정해야 함
	while true do
		character_util.set_anim(club_dj, { name = 'bow_attack', loop = true})
		character_util.set_direction(club_dj, 'left')

		wait_for_sec(0.4)

		character_util.set_direction(club_dj, 'right')
		character_util.set_emotion(club_dj,{ name = 'greed' })
		wait_for_sec(0.3)
		character_util.remove_emotion(club_dj)

		-- 1
		-- up 방향
		character_util.set_emotion(club_dancer_1, { name = 'blush' })
		character_util.set_anim(club_dancer_1, { name = 'dance_voodoo', loop = true })
		club_dancer_1.SpineController:Jump(0.7, 0.3)

		--2
		character_util.set_emotion(club_dancer_2, { name = 'love' })

		character_util.set_direction(club_dancer_2,'left')
		character_util.set_anim(club_dancer_2, { name = 'dance', loop = true })

		wait_for_sec(0.5)
		club_dancer_2.SpineController:Jump(0.7, 0.3)

		character_util.set_anim(club_dancer_2, { name = 'dance', loop = true })
		character_util.set_direction(club_dancer_2,'right')

		club_dj.SpineController:Jump(0.7, 0.3)
		club_dancer_1.SpineController:Jump(0.7, 0.3)

		--3
		character_util.set_emotion(club_dancer_3, { name = 'awesome' })
		character_util.set_direction(club_dancer_3,'down')
		character_util.set_anim(club_dancer_3, { name = 'dance_voodoo', loop = true })

		wait_for_sec(0.2)
		club_dancer_3.SpineController:Jump(0.7, 0.3)

		character_util.set_direction(club_dancer_3,'left')
		character_util.set_anim(club_dancer_3, { name = 'attack', loop = true })

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_3,'right')
		character_util.set_anim(club_dancer_3, { name = 'attack', loop = true })

		wait_for_sec(0.2)

		--4
		character_util.set_emotion(club_dancer_4, { name = 'awesome' })

		wait_for_sec(0.1)

		character_util.set_direction(club_dancer_4, 'right')
		character_util.set_anim(club_dancer_4, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_4, 'right')
		character_util.set_anim(club_dancer_4, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		club_dj.SpineController:Jump(0.7, 0.5)

		--5
		character_util.set_emotion(club_dancer_5, { name = 'awesome' })

		character_util.set_direction(club_dancer_5, 'down')
		character_util.set_anim(club_dancer_5, { name = 'clap', loop = true})

		wait_for_sec(0.6)

		character_util.set_direction(club_dancer_5, 'up')
		character_util.set_anim(club_dancer_5, { name = 'clap', loop = true})

		wait_for_sec(0.6)

		character_util.set_direction(club_dancer_5, 'left')
		character_util.set_anim(club_dancer_5, { name = 'clap', loop = true})

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_5, 'right')
		character_util.set_anim(club_dancer_5, { name = 'clap', loop = true})

		wait_for_sec(0.6)
		club_dancer_5.SpineController:Jump(0.7, 0.4)
		wait_for_sec(0.2)

		--6
		character_util.set_emotion(club_dancer_6, { name = 'awesome' })
		character_util.set_direction(club_dancer_6, 'down')
		character_util.set_anim(club_dancer_6, { name = 'dance_voodoo', loop = true})

		wait_for_sec(0.6)

		club_dancer_6.SpineController:Jump(0.7, 0.4)

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_6, 'up')
		character_util.set_anim(club_dancer_6, { name = 'gauntlet_boong_attack', loop = true})

		wait_for_sec(0.2)

		--7
		character_util.set_emotion(club_dancer_7, { name = 'awesome' })
		club_dancer_7.SpineController:Jump(0.7, 0.4)

		character_util.set_direction(club_dancer_7, 'left')
		character_util.set_anim(club_dancer_7, { name = 'rifle_reload', loop = true})

		wait_for_sec(0.6)

		character_util.set_direction(club_dancer_7, 'right')
		character_util.set_anim(club_dancer_7, { name = 'rifle_reload', loop = true})

		wait_for_sec(0.5)

		--8
		character_util.set_direction(club_dancer_8, 'right')
		character_util.set_anim(club_dancer_8, { name = 'dance', loop = true})

		wait_for_sec(0.5)

		character_util.set_direction(club_dancer_8, 'left')
		character_util.set_anim(club_dancer_8, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		--9
		club_dancer_9.SpineController:Jump(0.7, 0.4)

		character_util.set_direction(club_dancer_9, 'right')
		character_util.set_anim(club_dancer_9, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_9, 'left')
		character_util.set_anim(club_dancer_9, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		club_dancer_9.SpineController:Jump(0.7, 0.4)

		wait_for_sec(0.2)

		--10
		character_util.set_direction(club_dancer_10, 'left')
		character_util.set_anim(club_dancer_10, { name = 'dance', loop = true})

		wait_for_sec(0.5)

		character_util.set_direction(club_dancer_10, 'right')
		character_util.set_anim(club_dancer_10, { name = 'dance', loop = true})

		wait_for_sec(0.1)
		club_dancer_10.SpineController:Jump(0.7, 0.4)
		wait_for_sec(0.2)

		--11
		character_util.set_direction(club_dancer_11, 'down')
		character_util.set_anim(club_dancer_11, { name = 'dance_voodoo', loop = true})

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_12, 'left')
		character_util.set_anim(club_dancer_12, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		--9
		club_dancer_9.SpineController:Jump(0.7, 0.4)

		character_util.set_direction(club_dancer_13, 'right')
		character_util.set_anim(club_dancer_13, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		character_util.set_direction(club_dancer_13, 'left')
		character_util.set_anim(club_dancer_13, { name = 'dance', loop = true})

		wait_for_sec(0.2)

		club_dancer_9.SpineController:Jump(0.7, 0.4)

		wait_for_sec(0.2)

		--10
		character_util.set_direction(club_dancer_14, 'left')
		character_util.set_anim(club_dancer_14, { name = 'dance', loop = true})

		wait_for_sec(0.5)

		character_util.set_direction(club_dancer_14, 'right')
		character_util.set_anim(club_dancer_14, { name = 'dance', loop = true})

		wait_for_sec(0.1)
		club_dancer_10.SpineController:Jump(0.7, 0.4)
		wait_for_sec(0.2)

		--11
		character_util.set_direction(club_dancer_15, 'down')
		character_util.set_anim(club_dancer_15, { name = 'dance_voodoo', loop = true})

		wait_for_sec(0.2)
	end
end

function local_class:ice_cream_tourist_talk_2()
	local tourist = get_character(self.ice_cream_tourist_2)

	character_util.look_at(tourist, user_party_leader)
	speech_bubble_util.show_speech_bubble_async(tourist, { key = 'movie_main_npc_21' })
	character_util.set_direction(tourist, 'down')
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}