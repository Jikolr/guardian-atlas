local local_class = newclass('DemonShire2At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- Npcs
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end
	self.get_sohee = function()
		return get_character('sohee')
	end
	self.get_count_daughter = function()
		return get_character('count_daughter')
	end
	self.get_count_daughter_paper_bag = function()
		return get_character('count_daughter_paper_bag')
	end
	self.get_oneline_vampire_steward = function(idx)
		return get_character('s14_oneline_vampire_steward_' .. idx)
	end

	self.get_knight_walk4legs = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_walk4legs')
		else
			return get_character('knight_female_walk4legs')
		end
	end

	self.in_vent = false

	self.crawling_sfx = nil

	-- 상시 유지되는 아이템
	self.bottle_item = nil

	-- 상시 유지되는 아이템
	self.table_foods = {}

	-- 기본 이동이 기어가는 것으로 변경되기 시작하는 구역 이름
	self.vent_zone = 'vent_hole_entrance'
	self.on_transition = false
	self.vent_zone_2 = 'vent_hole_entrance_2'
	self.vent_zone_3 = 'vent_hole_entrance_3'

	self.gossip_state = {
		init = 1,
		is_ready = 2,
		on_going = 3,
		done = 4,
	}
	self.nobles_gossip_current_state = self.gossip_state.init
	self.kitchen_gossip_current_state = self.gossip_state.init

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	--region 라비 파비 부모님 이벤트

	-- sns id
	self.sns_follower_id = 63

	-- 희생의 석상 퀘스트 id
	self.demon_twins_quest_id = 64

	-- npc
	self.get_lavifavi_mother = function()
		return get_character('lavifavi_mother')
	end

	self.get_lavifavi_father = function()
		return get_character('lavifavi_father')
	end

	-- 대화했는 지 여부
	self.parents_interact_check = false
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_move_fo_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))

	if self.crawling_sfx ~= nil then
		self.crawling_sfx:Stop()
		self.crawling_sfx = nil
	end

	if self.nobles_gossip_current_state == self.gossip_state.on_going then
		self.nobles_gossip_current_state = self.gossip_state.done
	end

	if self.kitchen_gossip_current_state == self.gossip_state.on_going then
		self.kitchen_gossip_current_state = self.gossip_state.done
	end

	if self.bottle_item ~= nil then
		self.bottle_item:ConsumeComplete()
		self.bottle_item = nil
	end

	if #self.table_foods > 0 then
		for _, item in ipairs(self.table_foods) do
			if item ~= nil then
				item:ConsumeComplete()
				item = nil
			end
		end
	end

	--region 라비 파비 부모님 이벤트
	character_util.remove_relate_event(self.get_lavifavi_father(), self.cs_controller)
	character_util.remove_relate_event(self.get_lavifavi_mother(), self.cs_controller)
	--endregion

	self.cs_controller = nil
end

function local_class:on_event(e)
	local cook1 = get_character('vampire_cook_1')
	local cook2 = get_character('vampire_cook_2')
	if type_util.is_interacted_target(e, cook1) or type_util.is_interacted_target(e, cook2) then
		if self.kitchen_gossip_current_state == self.gossip_state.is_ready then
			self.kitchen_gossip_current_state = self.gossip_state.on_going
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.vampire_kitchen_gossip_event, self))
		end
	end

	--region 라비 파비 부모님 이벤트
	local mother = self.get_lavifavi_mother()
	local father = self.get_lavifavi_father()
	if type_util.is_interacted_target(e, mother) or type_util.is_interacted_target(e, father) then
		sp_util.play_normal_screenplay(self.interact_twins_present, self)
	end
	--endregion
	return false
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

function local_class:on_stage_loaded_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		if main_quest_progress.InnerProgress >= 14 and main_quest_progress.InnerProgress <= 15 then
			self:set_protest_civils()
		end
	end

	local drink_pos = field:GetMarker('s11_drink_pos').position
	local item_data = {
		{ 20624, vector(0.5, 0.7, -0.5), 1 },
		{ 20622, vector(0.5, 0.7, -2.5), 1},
		{ 20600, vector(0.5, 0.7, -4.5), 1},
		{ 20623, vector(0.5, 0.7, -6.5), 1},
		--{ 20601, vector(-0.2, 0.7, -0.7), 0.7 }, 원로 아들 앞에는 배치 안함
		{ 20601, vector(-0.2, 0.7, -2.7), 0.7 },
		{ 20601, vector(-0.2, 0.7, -4.7), 0.7 },
		{ 20601, vector(-0.2, 0.7, -6.7), 0.7 },
		{ 20601, vector(1.1, 0.7, 0.0), 0.7},
		{ 20601, vector(1.1, 0.7, -2.0), 0.7},
		{ 20601, vector(1.1, 0.7, -4.0), 0.7},
		{ 20601, vector(1.1, 0.7, -6.0), 0.7},
	}
	for _, data in ipairs(item_data) do
		table.insert(self.table_foods, drop_item_util.create_item({itemid = data[1], pos = drink_pos + data[2],
																   notforinven = true, sprscale = data[3],
																   lootstate = 'dontfindlooter'}))
	end
end

function local_class:on_interact_event(e)
	if string.find(e.Target.Name, self.vent_zone) then
		if not self.on_transition then
			if not self.in_vent then
				if e.Target.Name == self.vent_zone then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'left', e.Target))
					return true
				end
				if e.Target.Name == self.vent_zone_3 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'left', e.Target))
					return true
				end
				if e.Target.Name == self.vent_zone_2 then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.enter_hole_event, self, 'up', e.Target))
					return true
				end
			else
				if e.Target.Name == self.vent_zone then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'right', e.Target)
					return true
				end

				if e.Target.Name == self.vent_zone_3 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'right', e.Target)
					return true
				end

				if e.Target.Name == self.vent_zone_2 then
					sp_util.play_normal_screenplay(self.exit_hole_event, self, 'down', e.Target)
					return true
				end
			end

		end
	end

end

function local_class:on_stage_start_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		-- 15, 16 섹션
		if main_quest_progress.InnerProgress >= 14 and main_quest_progress.InnerProgress <= 15 then
			for i = 1, 2 do
				local oneline_vampire_steward = self.get_oneline_vampire_steward(i)
				character_util.set_active_state(oneline_vampire_steward, 'enabled')
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	if main_quest_progress ~= nil then
		-- 15, 16 섹션
		if main_quest_progress.InnerProgress >= 10 and main_quest_progress.InnerProgress <= 13 then
			if type_util.is_zone_full_enter(e, user_party.Leader, 'vampire_nobles_gossip_zone')
					and self.nobles_gossip_current_state == self.gossip_state.is_ready then
				self.nobles_gossip_current_state = self.gossip_state.on_going
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.vampire_nobles_gossip_event, self))
			end
		end

	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'ds_s14_uncover_culprit_clear' then
		local vamp1 = get_character('s14_vampire_noble_1')
		local vamp2 = get_character('s14_vampire_noble_2')

		vamp1.Interactable.Talk = nil
		vamp2.Interactable.Talk = nil

		self.nobles_gossip_current_state = self.gossip_state.done
	end
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 304101
	if user_util.has_knight_male() then
		character_spec_id = 304100
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end


function local_class:pre_setting()
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

		while leader.IsChangingEquipment do
			coroutine.yield()
		end
	end

	local stage_entry_type = {
		directional_stage_entry = 1,
		fall_stage_entry = 2
	}

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, entry_type, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if entry_type == stage_entry_type.directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		elseif entry_type == stage_entry_type.fall_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.FallStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	--region 원라인 npc
	if main_quest_progress ~= nil then
		if main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 14 then
			self:set_oneline_npc_after_event(main_quest_progress.InnerProgress)
		end
	end
	--endregion

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('left', field:GetMarker('default_start').position,
				stage_entry_type.directional_stage_entry, true)
	elseif main_quest_progress.InnerProgress == 9 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 12 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter_paper_bag() })
		start_stage_event('left', field:GetMarker('s13_start_pos').position,
				stage_entry_type.directional_stage_entry, true)
	elseif main_quest_progress.InnerProgress == 13 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter_paper_bag() })
		start_stage_event('left', field:GetMarker('s14_start_pos').position,
				stage_entry_type.directional_stage_entry, true)
	elseif main_quest_progress.InnerProgress == 10 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif main_quest_progress.InnerProgress == 11 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter_paper_bag() })
		start_stage_event('left', field:GetMarker('s12_start_pos').position,
				stage_entry_type.directional_stage_entry, true)
	elseif main_quest_progress.InnerProgress == 14 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		start_stage_event('left', field:GetMarker('s15_start_pos').position,
				stage_entry_type.directional_stage_entry, true)
	elseif main_quest_progress.InnerProgress == 15 then
		change_leader_character({ self.get_sohee(), self.get_count_daughter() })
		start_stage_event('left', field:GetMarker('default_start').position,
				stage_entry_type.directional_stage_entry, true)
	else
		--TODO: 나머지 섹션별로 위치 정해줘야 할듯
		change_leader_character()
		start_stage_event('left', field:GetMarker('default_start').position,
				stage_entry_type.directional_stage_entry, true)
	end

	-- 섹션에 관계 없이 항상 있을 것
	local front_clerk = get_character('s12_front_clerk_1')
	front_clerk.Hitbox = CS.Oak.Hitbox(vector(2.8, 0.75, 0.7))

	-- 별도로 세팅해줘야 하는 경우
	if main_quest_progress ~= nil and not main_quest_progress.IsComplete then
		if main_quest_progress.InnerProgress > 11 then
			-- 12섹션에서 연출중 사용되는 일이 있기 때문에 그 이후부터 상시 배치
			local drink_pos = field:GetMarker('s11_drink_pos').position
			self.bottle_item = drop_item_util.create_item({itemid = 20603, pos = drink_pos + vector(0, 0.7, -0.6),
														   notforinven = true, sprscale = 1,
														   lootstate = 'dontfindlooter'})
		end

		-- main_quest_progress.InnerProgress > 10 and 동선상 해당 이벤트 가능 시점 이전에 그 공간을 지날 수 없음.
		if main_quest_progress.InnerProgress <= 13 then
			self:vampire_nobles_gossip_setting()
		end

		if main_quest_progress.InnerProgress <= 11 then
			self:vampire_kitchen_gossip_setting()
		end
	end

	--region 라비 파비 부모님 이벤트
	local mother = self.get_lavifavi_mother()
	local father = self.get_lavifavi_father()

	-- sns follower 가 추가 되어 있지 않다면.
	if not user_progress:IsFollowing(self.sns_follower_id) then
		father.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
		character_util.set_anim_and_emotion(father, { name = 'twohand_idle' }, { name = 'tired' })
		character_util.remove_anim_and_emotion(mother)
		character_util.add_listener(father, self.cs_controller)
		character_util.add_listener(mother, self.cs_controller)
	else
		--라비 어머니 (left, smile, idle) : 잘 지내고 있는 것 같아서 다행이네. 그치 남편?
		character_util.set_anim_and_emotion(mother, { name = 'idle' }, { name = 'smile' })
		mother.Interactable.Talk = 'lavi_favi_parents_32'
		--파비 아버지 (left, tired, idle) : 왜 연락이 안될까… 사춘기가 온 걸까…?
		character_util.set_anim_and_emotion(father, { name = 'idle' }, { name = 'tired' })
		father.Interactable.Talk = 'lavi_favi_parents_33'
		father.Interactable.TalkSfx = '03_dialogue_sadness_01'
	end
	--endregion
end

function local_class:vampire_nobles_gossip_setting()
	local vamp1 = get_character('s14_vampire_noble_1')
	local vamp2 = get_character('s14_vampire_noble_2')

	character_util.set_anim_and_emotion(vamp1, {name = 'cross_arm'}, {name = 'attack'})
	character_util.set_anim_and_emotion(vamp2, {name = 'bomb_idle'}, {name = 'attack'})

	self.nobles_gossip_current_state = self.gossip_state.is_ready
end

function local_class:vampire_nobles_gossip_event()
	local talk_name = 'ds_main_noble_talk_'
	local vamp1 = get_character('s14_vampire_noble_1')
	local vamp2 = get_character('s14_vampire_noble_2')
	--트리거 존 진입시, 컨트롤 뺏지 않는 자동 이벤트
	--14섹션 집사에게 인터렉트 전까지 유지
	--귀족 뱀파이어1 (파랑4, right, attack, cross_arm) : 마족 놈들… 그 헛소문 때문에 원로님을 죽인 게 분명해.
	speech_bubble_util.show_speech_bubble_async(vamp1, {key = talk_name .. 1})
	if self.nobles_gossip_current_state == self.gossip_state.done then return end
	--귀족 뱀파이어2 (파랑5, left, attack, bomb_idle) : 맞아. 백작님이 우리랑 손잡고 영부인을 숙청했다는 게 말이 돼?!
	speech_bubble_util.show_speech_bubble_async(vamp2, {key = talk_name .. 2})
	if self.nobles_gossip_current_state == self.gossip_state.done then return end
	character_util.remove_anim(vamp1)
	--귀족 뱀파이어1(파랑4, right, attack, idle) : 왜 영부인이 돌아가신 걸 우리 탓을 하는 건지…
	speech_bubble_util.show_speech_bubble_async(vamp1, {key = talk_name .. 3})
	if self.nobles_gossip_current_state == self.gossip_state.done then return end
	--귀족 뱀파이어2 (파랑5, left, attack, cross_arm) : 단체로 벨리알에 씌이기라도 한 거야, 뭐야.
	character_util.set_anim_and_emotion(vamp2, {name = 'cross_arm'}, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(vamp2, {key = talk_name .. 4})
	--이후 마지막 대사 원라인

	vamp1.Interactable.Talk = talk_name .. 3
	vamp2.Interactable.Talk = talk_name .. 4

	self.nobles_gossip_current_state = self.gossip_state.done
end

function local_class:vampire_kitchen_gossip_setting()
	local cook1 = get_character('vampire_cook_1')
	local cook2 = get_character('vampire_cook_2')

	character_util.set_anim_and_emotion(cook1, {name = 'idle'}, {name = 'tired'})
	character_util.set_anim_and_emotion(cook2, {name = 'cast'}, {name = 'tired'})

	character_util.add_listener(cook1, self)
	character_util.add_listener(cook2, self)

	self.kitchen_gossip_current_state = self.gossip_state.is_ready
end

function local_class:vampire_kitchen_gossip_event()
	local talk_name = 'ds_main_kitchen_'
	local cook1 = get_character('vampire_cook_1')
	local cook2 = get_character('vampire_cook_2')

	character_util.remove_relate_event(cook1, self)
	character_util.remove_relate_event(cook2, self)

	--인터랙트시 대화 이벤트 진행
	--뱀파이어 요리사2(left, tired, cast) : 오늘 정시 퇴근해서 태양절 축제는 갈 수 있을까…?
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', loop = false, parent = cook2,
								 type_priority = 'event', player_priority = 'default' })
	character_util.set_anim_and_emotion(cook2, {name = 'cast'}, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(cook2, {key = talk_name .. 2})
	if self.kitchen_gossip_current_state == self.gossip_state.done then return end
	--뱀파이어 요리사1(right, idle, release) : 관둬. 오늘 출근하는데 마족놈들 얼굴 살벌하더라.
	character_util.set_anim_and_emotion(cook1, {name = 'release', sfx_name = '01_swing_01'}, {name = 'idle'})
	speech_bubble_util.show_speech_bubble_async(cook1, {key = talk_name .. 3})
	if self.kitchen_gossip_current_state == self.gossip_state.done then return end
	--뱀파이어 요리사1(right, idle, bomb_idle) : 백작님이 결국 미쳐서 프리실라님을 수용소에 가뒀다나 뭐라나…
	music_player_util.play_sfx({ sfx_name = '01_swing_01', loop = false, parent = cook1,
								 type_priority = 'event', player_priority = 'default' })
	character_util.set_anim_and_emotion(cook1, {name = 'bomb_idle'}, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(cook1, {key = talk_name .. 4})
	if self.kitchen_gossip_current_state == self.gossip_state.done then return end
	--뱀파이어 요리사2(left, surprise, idle)  : 뭐? 대체 왜?
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', loop = false, parent = cook2,
								 type_priority = 'event', player_priority = 'default' })
	character_util.set_anim_and_emotion(cook2, {name = 'idle'}, {name = 'surprise'})
	speech_bubble_util.show_speech_bubble_async(cook2, {key = talk_name .. 5})
	if self.kitchen_gossip_current_state == self.gossip_state.done then return end
	--뱀파이어 요리사1(right, tired, idle) : 놈들이 항상 하는 말들 있잖아. 백작이 마족들을 여기서 싹 쓸어버릴거라는…
	character_util.set_anim_and_emotion(cook1, {name = 'idle'}, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(cook1, {key = talk_name .. 6})
	if self.kitchen_gossip_current_state == self.gossip_state.done then return end
	--뱀파이어 요리사2 (left, tired, idle) : 그걸 믿는 놈들이 있다고?
	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', loop = false, parent = cook2,
								 type_priority = 'event', player_priority = 'default' })
	character_util.set_anim_and_emotion(cook2, {name = 'idle'}, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(cook2, {key = talk_name .. 7})
	--이후 재인터랙트시 원라인 대사

	character_util.remove_anim(cook1)
	character_util.remove_anim(cook2)

	cook1.Interactable.Talk = talk_name .. 6
	cook2.Interactable.Talk = talk_name .. 7

	self.kitchen_gossip_current_state = self.gossip_state.done
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

	self.in_vent = to_walk_4legs

	return
end

function local_class:enter_hole_event(dir_str, target)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.on_transition = true

	local dir = vector(0, 0, 0)
	if dir_str == 'left' then
		dir = vector(-1,0,0)
	elseif dir_str == 'right' then
		dir = vector(1,0,0)
	elseif dir_str == 'up' then
		dir = vector(0,0,1)
	elseif dir_str == 'down' then
		dir = vector(0,0,-1)
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
		character_util.set_anim(c, {name = 'walk'})
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
				character_util.set_anim(data.npc, {name = 'walk4legs'})
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
end

function local_class:exit_hole_event(dir_str, target)
	self.on_transition = true

	local dir = vector(0, 0, 0)
	if dir_str == 'left' then
		dir = vector(-1,0,0)
	elseif dir_str == 'right' then
		dir = vector(1,0,0)
	elseif dir_str == 'up' then
		dir = vector(0,0,1)
	elseif dir_str == 'down' then
		dir = vector(0,0,-1)
	else
		dir_str = 'none'
	end

	party_util.align_party(target.Position + dir * 0.3,
			direction_util.get_opposite(character_util.get_direction(dir_str)), 0.7, 'linear')

	dir = dir * 1.7


	self:change_party_member_4legs(false)

	local party = {}
	for i = 0, user_party.Count - 1 do
		local c = user_party[i]
		table.insert(party, { npc = c, origin = c.Position })
		character_util.set_anim(c, {name = 'walk4legs'})
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
				character_util.set_anim(data.npc, {name = 'walk'})
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
end

--region 라비 파비 부모님 이벤트
function local_class:interact_twins_present()
	local mother = self.get_lavifavi_mother()
	local father = self.get_lavifavi_father()
	local leader = get_party_leader()

	party_util.align_party(mother, 'right', 1, 'linear')

	if not self.parents_interact_check then
		self.parents_interact_check = true

		--파비 아버지 (right, tired, 전화 받기) : 파비… 아빠가 오늘은…
		music_player_util.play_sfx_one_shot('01_phone_receive_02')
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_1', skip = true })

		--라비 어머니 (left, smile, idle) : 남편! 오늘도 또 애들한테 연락중이야?
		music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
		character_util.set_emotion(mother, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_2', skip = true })

		--파비 아버지 (right, tired, cast) : 하, 하지만…! 연락이 안된단 말이야!
		music_player_util.play_sfx_one_shot('01_rustle_01')
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		character_util.set_anim_and_emotion(father, { name = 'cast' }, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_3', skip = true })

		--파비 아버지 (right, scared, cast) : 그러지 않았으면 하지만… 이제 아빠같은 건 싫다는 걸까?!
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_3_1', skip = true })

		--라비 어머니 (letf, smile, idle) : 하하! 우리 애들이 그럴 리가 없잖아!
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_4', skip = true })

		--라비 어머니 (letf, attack, idle) : 만약 그렇다면… 가족의 시간이 필요하겠는걸?
		character_util.set_emotion(mother, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_4_1', skip = true })

		father.SpineController:SetAttachment('[base]weapon1', 'empty')
		character_util.remove_anim(father)
		character_util.set_emotion(father, { name = 'attack' })
		character_util.normal_jump(father, true)
		music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
		character_util.show_emoticon_async(father, nil, 'notice')

		character_util.set_direction(mother, 'up')
		character_util.move_to(mother, mother.Position - vector(0, 0, 1),
				0.25, nil, false, true)
		character_util.move_to_async(father, father.Position + vector(1, 0, 0),
				0.25, nil, true, true)

		--파비 아버지 (right, attack, jump 1회) : 저, 저기! 혹시 인간계에서 오신 분?!
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		character_util.normal_jump(father, '01_player_jump_01')
		character_util.set_anim(father, { name = 'cast' })
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_5', skip = true })

		--플레이어 머리 위로 emoticon_bubble_question 출력.
		character_util.show_emoticon_async(leader, nil, 'question')

		--파비 아버지 (right, tired, cast) : 혹시… 인간계에서 저희처럼 뿔 달린 아이들을 보신 적 없을까요?
		character_util.set_anim_and_emotion(father, { name = 'cast' }, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_6', skip = true })

		--플레이어 tired 표정으로 바뀌며 짧게 shake 실행.
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_emotion(leader, { name = 'tired' })
		character_util.shake(leader, 0.02, 0.4)
		wait_for_sec(0.4)

		--파비 아버지 (right, tired, cast) : 한 아이는 나보다 씩씩하고… 또 한 아이는 너무 착한 아이인데…
		character_util.remove_emotion(leader)
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_7', skip = true })

		--라비 어머니 (up, idle, idle) : 미안, 우리 남편이 조금 걱정이 많아서 말이야…
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_8', skip = true })

		--라비 어머니 (up, idle, idle) : 혹시 알고 있는 게 있을까?
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_8_1', skip = true })
	else
		--파비 아버지 (right, attack, jump 1회) : 앗! 저번에 인간분!
		character_util.remove_anim(father)
		character_util.set_emotion(father, { name = 'attack' })
		character_util.normal_jump(father, '01_player_jump_01')
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_13', skip = true })

		character_util.set_direction(mother, 'up')
		local run = music_player_util.play_sfx({ sfx_name = '01_dash_01', loop = true })
		character_util.move_to(mother, mother.Position - vector(0, 0, 1),
				0.25, nil, false, true)
		character_util.move_to_async(father, father.Position + vector(1, 0, 0),
				0.25, nil, true, true)
		run:Stop()

		--파비 아버지 (right, tired, cast) : 혹시… 저희 애들은 만나셨나요?
		character_util.set_anim_and_emotion(father, { name = 'cast' }, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_14', skip = true })
	end

	local twins_quest_clear = false
	local demon_twins_quest = user_progress:GetStartedQuest(self.demon_twins_quest_id)
	if demon_twins_quest ~= nil and demon_twins_quest.IsComplete then
		twins_quest_clear = true
	end

	-- 희생의 석상 퀘스트 미 클리어 시
	if not twins_quest_clear then
		choose_util.play_choose_event({ { 'lavi_favi_parents_9', 'brutal' } })

		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(leader, { name = 'cast' }, { name = 'tired' })
		character_util.shake(leader, 0.02, 1)
		wait_for_sec(1)

		character_util.remove_anim_and_emotion(leader)
		character_util.remove_anim(father)
		character_util.move_to(father, father.Position - vector(1, 0, 0),
				0.5, nil, false, true)
		character_util.move_to_async(mother, mother.Position + vector(0, 0, 1),
				0.5, nil, true, true)

		--라비 어머니 (left, attack, idle) : 그만. 남편 마음도 알지만, 더 이상은 민폐야.
		music_player_util.play_sfx_one_shot('01_land_01')
		character_util.set_direction(mother, 'left')
		character_util.set_emotion(mother, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_11', skip = true })

		--파비 아버지 (right, tired, cast) : 알았어… 하지만 그래도…!
		music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
		character_util.set_anim_and_emotion(father, { name = 'cast' }, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_12', skip = true })

		--라비 어머니 (left, sleep_deep, idle) : …….
		character_util.set_emotion(mother, { name = 'sleep_deep' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_12_1', skip = true })

		character_util.set_direction(mother, 'left')
		return
	end

	choose_util.play_choose_event({ { 'lavi_favi_parents_10', 'mercy' } })

	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(leader, { name = 'smile' })
	character_util.set_animation_n_times_async(leader, { name = 'release', count = 2, sfx = '01_swing_01' })

	character_util.remove_emotion(leader)
	character_util.remove_anim(father)
	character_util.move_to(father, father.Position - vector(1, 0, 0),
			0.25, nil, false, true)
	character_util.move_to_async(mother, mother.Position + vector(0, 0, 1),
			0.25, nil, true, true)

	--라비 어머니 (right, smile, idle) : 오, 우리 애들이랑 친구인가 보네?
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.set_direction(mother, 'right')
	character_util.set_emotion(mother, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_15', skip = true })

	--라비 어머니 (right, smile, idle) : 잘됐네. 우리 애들 잘 살고 다니는지 좀 알려줄 수 있어?
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_16', skip = true })

	local choose_select_1 = function()
		--라비 어머니 (right, smile, idle) : 호오. 귀신을 사냥했다고? 맨주먹으로?
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		character_util.set_emotion(mother, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_20', skip = true })

		--라비 어머니 (right, awesome, cross_arm) : 좋네! 역시 우리 딸! 씩씩한게 맘에 들어!
		character_util.set_anim_and_emotion(mother, { name = 'cross_arm' }, { name = 'awesome' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_20_1', skip = true })

		--라비 어머니 (right, tired, idle) : 우리 남편도 그런 면은 좀 배웠으면 좋겠지만…
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		character_util.set_anim_and_emotion(mother, { name = 'idle' }, { name = 'tired' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_21', skip = true })

		character_util.remove_anim_and_emotion(mother)
	end

	local choose_select_2 = function()
		--라비 어머니 (right, attack, idle) : 흐음… 그림자 마수인지 뭔지 모르겠지만…
		character_util.set_emotion(mother, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_22', skip = true })

		--라비 어머니 (right, sleep_deep, cross_arm) : 적을 상대로 뒤를 내어주고 도망가다니…
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.set_anim_and_emotion(mother, { name = 'cross_arm' }, { name = 'sleep_deep' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_22_1', skip = true })

		--라비 어머니 (right, attack, idle) : 이거… 우리 애들 근성이 좀 부족해졌는 걸?
		music_player_util.play_sfx_one_shot('03_dialogue_china_01')
		character_util.set_anim_and_emotion(mother, { name = 'idle' }, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_23', skip = true })

		character_util.remove_emotion(mother)
	end

	local choose_select_3 = function()
		--라비 어머니 (right, idle, idle) : 음! 무슨 소리인지는 모르겠지만…
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_24', skip = true })

		--라비 어머니 (right, awesome, cast) : 친구를 지켜주려 한 일이었다는 거지?
		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		character_util.set_anim_and_emotion(mother, { name = 'cast' }, { name = 'awesome' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_24_1', skip = true })

		--라비 어머니 (right, smile, idle) : 내가 애들 하나는 잘 키웠다니까~
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		character_util.set_anim_and_emotion(mother, { name = 'idle' }, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_25', skip = true })

		character_util.remove_emotion(mother)
	end

	--귀신을 사냥했던 일을 말한다.(초록)
	--그림자 마수에게 쫓기던 일을 말한다.(초록)
	--100골드에 전시되던 일을 말한다.(빨강)
	local choose_list = { { 'lavi_favi_parents_17', 'intellect' },
						  { 'lavi_favi_parents_18', 'mercy' }, { 'lavi_favi_parents_19', 'brutal' } }
	local choose_func_list = { choose_select_1, choose_select_2, choose_select_3 }

	while #choose_list > 0 do
		local choose_result = choose_util.play_choose_event(choose_list)
		choose_func_list[choose_result]()
		table.remove(choose_list, choose_result)
		table.remove(choose_func_list, choose_result)
	end

	--라비 어머니 (right, smile, idle) : 우리 애들 잘 지내는 것 같네! 당분간은 걱정 없겠어.
	character_util.set_emotion(mother, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_26', skip = true })

	--라비 어머니 (left, attack, idle) : 당신도 이제 적당히 해. 애들 다 우리 도움 없이 잘 살고 있잖아?
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(mother, 'left')
	character_util.set_emotion(mother, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_27', skip = true })

	--파비 아버지 (right, tired, idle) : 그, 그치만! 연락이…
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	character_util.set_emotion(father, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(father, { key = 'lavi_favi_parents_28', skip = true })

	--라비 어머니 (left, idle, idle) : 음… 뭐 알았어 그럼.
	character_util.set_emotion(mother, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_29', skip = true })

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(mother, 'right')
	character_util.remove_emotion(mother)
	yield_return_func(CS.Oak.AddSNSCoroutine, self.sns_follower_id)

	wait_for_sec(0.5)

	--라비 어머니 (right, tired, idle) : 우리 애들 연락해도 받지를 않으니까 부탁 좀 하자.
	character_util.set_emotion(mother, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_30', skip = true })

	--라비 어머니 (right, smile, idle) : 간간히 연락할테니. 우리 애들 잘 지내는지만 좀 알려줘.
	character_util.set_emotion(mother, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(mother, { key = 'lavi_favi_parents_31', skip = true })

	--이후 플레이어 컨트롤 복귀. 각자 하단의 상태로 원라인 배치.
	character_util.remove_relate_event(mother, self.cs_controller)
	character_util.remove_relate_event(father, self.cs_controller)

	--라비 어머니 (left, smile, idle) : 잘 지내고 있는 것 같아서 다행이네. 그치 남편?
	character_util.set_direction(mother, 'left')
	character_util.set_emotion(mother, { name = 'smile' })
	mother.Interactable.Talk = 'lavi_favi_parents_32'

	--파비 아버지 (left, tired, idle) : 왜 연락이 안될까… 사춘기가 온 걸까…?
	father.Interactable.Talk = 'lavi_favi_parents_33'
	father.Interactable.TalkSfx = '03_dialogue_sadness_01'
end
--endregion

--region 원라인 NPC 세팅 함수
-- 15섹션 이후 원라인 npc 배치
function local_class:set_oneline_npc_after_event(progress)
	-- 이전 섹션에서 사용중인 원라인 npc 배치
	local active_number_list = { '1', '1_1', '2', '3', '4', '5', '6', '7', '14', '15' }
	local ani_list = { 'eat', nil, nil, nil, nil, nil, nil, nil, 'cross_arm', nil }
	local emo_list = { nil, nil, nil, 'smile', 'attack', 'tired', nil, 'tired', 'attack', nil }
	local online_string_key = 'ds_2_4_oneline_'
	for i = 1, #active_number_list do
		local town_npc = get_character('vampire_town_npc_' .. active_number_list[i])
		local marker = field:GetMarker('town_oneline_npc_pos_1_' .. i)

		-- 방향 및 좌표 세팅
		character_util.set_position(town_npc, marker.position)
		character_util.set_direction(town_npc, marker.direction)
		character_util.remove_anim_and_emotion(town_npc)

		-- 애니메이션 세팅
		local animation = ani_list[i]
		if animation ~= nil then
			character_util.set_anim(town_npc, { name = animation })
		end

		-- 이모션 세팅
		local emotion = emo_list[i]
		if emotion ~= nil then
			character_util.set_emotion(town_npc, { name = emotion })
		end

		-- 원라인 키 세팅
		town_npc.Interactable = CS.Oak.NPCInteractable.Create()
		town_npc.Interactable.Talk = online_string_key .. i

		character_util.set_active_state(town_npc, 'enabled')
	end

	-- 15섹션 이후 부터 활성화 되는 npc들 배치
	-- 해당 npc들은 활성화만 시켜주면 된다.

	-- 가운데 부분
	local npc_count = 8
	for i = 1, npc_count do
		local town_npc = get_character('new_vampire_town_npc_' .. i)
		character_util.set_active_state(town_npc, 'enabled')
	end

	-- 저택 입구 부분
	npc_count = 2
	for i = 1, npc_count do
		local town_npc = get_character('mansion_oneline_npc_' .. i)
		if progress == 14 then
			-- 15섹션에서는 따로 연출할것 이기에 이모션 애니메이션 제거
			character_util.remove_anim_and_emotion(town_npc)
			town_npc.Interactable.Talk = nil
		end
		character_util.set_active_state(town_npc, 'enabled')
	end
end
--endregion

-- 시위하는 관중들 세팅
function local_class:set_protest_civils()
	local elder = get_character('elder')
	if elder ~= nil and elder.ActiveState == active_state('enabled') then
		elder.Interactable.Talk = nil
		character_util.set_position(elder, vector(-63, 0, 3))
		character_util.set_direction(elder, 'left')
		character_util.set_anim(elder, { name = 'dead', loop = false, scale = 999 })

		local corpse_tint_color = unity_color({ 0, 0, 0, 1 })
		character_util.add_color(elder, 'dead_tint', corpse_tint_color, 1, 0)
	end

	local elder_son = get_character('elder_son')
	if elder_son ~= nil and elder_son.ActiveState == active_state('enabled') then
		elder_son.Interactable.Talk = nil
		character_util.set_position(elder_son, vector(-60.5, 0, 7))
		character_util.set_direction(elder_son, 'down')
		character_util.set_emotion(elder_son, { name = 'surprise' })
	end

	local aide = get_character('aide')
	if aide ~= nil and aide.ActiveState == active_state('enabled') then
		aide.Interactable.Talk = nil
		character_util.set_position(aide, vector(-60, 0, 7))
		character_util.set_direction(aide, 'right')
		character_util.set_emotion(aide, { name = 'surprise' })
	end

	local demon_1 = get_character('s14_demon_1')
	if demon_1 ~= nil and demon_1.ActiveState == active_state('enabled') then
		demon_1.Interactable.Talk = nil
		character_util.set_position(demon_1, vector(-61, 0, 5))
		character_util.set_direction(demon_1, 'up')
		character_util.set_anim(demon_1, { name = 'release' })
	end

	local demon_2 = get_character('s14_demon_2')
	if demon_2 ~= nil and demon_2.ActiveState == active_state('enabled') then
		demon_2.Interactable.Talk = nil
		character_util.set_position(demon_2, vector(-61, 0, 6))
		character_util.set_direction(demon_2, 'up')
		character_util.set_anim(demon_2, { name = 'release' })
	end

	local vampire_noble_1 = get_character('s14_vampire_noble_1')
	if vampire_noble_1 ~= nil and vampire_noble_1.ActiveState == active_state('enabled') then
		vampire_noble_1.Interactable.Talk = nil
		character_util.set_position(vampire_noble_1, vector(-59, 0, 6))
		character_util.set_direction(vampire_noble_1, 'up')
		character_util.set_anim(vampire_noble_1, { name = 'release' })
	end

	local vampire_noble_2 = get_character('s14_vampire_noble_2')
	if vampire_noble_2 ~= nil and vampire_noble_2.ActiveState == active_state('enabled') then
		vampire_noble_2.Interactable.Talk = nil
		character_util.set_position(vampire_noble_2, vector(-60, 0, 5))
		character_util.set_direction(vampire_noble_2, 'up')
		character_util.set_anim(vampire_noble_2, { name = 'release' })
	end

	local vampire_noble_3 = get_character('s14_vampire_noble_3')
	if vampire_noble_3 ~= nil and vampire_noble_3.ActiveState == active_state('enabled') then
		vampire_noble_3.Interactable.Talk = nil
		character_util.set_position(vampire_noble_3, vector(-60, 0, 6))
		character_util.set_direction(vampire_noble_3, 'up')
		character_util.set_anim(vampire_noble_3, { name = 'release' })
	end

	local audience_1 = get_character('s14_npc_1')
	if audience_1 ~= nil and audience_1.ActiveState == active_state('enabled') then
		audience_1.Interactable.Talk = nil
		character_util.set_position(audience_1, vector(-62, 0, 7))
		character_util.set_direction(audience_1, 'right')
		character_util.set_anim(audience_1, { name = 'strike_idle' })
		character_util.set_emotion(audience_1, { name = 'attack' })
	end

	local audience_2 = get_character('s14_npc_2')
	if audience_2 ~= nil and audience_2.ActiveState == active_state('enabled') then
		audience_2.Interactable.Talk = nil
		character_util.set_position(audience_2, vector(-63, 0, 7))
		character_util.set_direction(audience_2, 'right')
		character_util.set_anim(audience_2, { name = 'strike_idle' })
		character_util.set_emotion(audience_1, { name = 'attack' })
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
