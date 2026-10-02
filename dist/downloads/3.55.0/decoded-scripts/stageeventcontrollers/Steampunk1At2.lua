local local_class = newclass("Steampunk1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.brazier_list = {}
	self.ishya_note = nil
	self.shyapira_note = nil
	self.wardrobe = nil

	self.ishya_note_marker_name = 'ishya_note_marker'
	self.shyapira_note_marker_name = 'shyapira_note_marker'
	self.ishya_note_name = 'ishya_note_interact'
	self.shyapira_note_name = 'shyapira_note_interact'
	self.wardrobe_name = 'secret_wardrobe'
	self.wardrobe_marker_name = 'secret_wardrobe_marker'
	self.wardrobe_end_marker_name = 'secret_wardrobe_marker_end'
	self.stair_name = "secret_stair"

	self.gimmick_door_down_sfx_name = '01_push_rock_unit_01'

	self.ishya_note_nar = 'steampunk_2_ishya_note'
	self.shyapira_note_nar = 'steampunk_2_shyapira_note'
	self.secret_nar = 'steampunk_2_secret_narration'
	self.secret_branch_1 = 'steampunk_2_secret_talk_branch_1'
	self.secret_branch_2 = 'steampunk_2_secret_talk_branch_2'

	self.note_item_id = 20022

	self.braziers_name = 'secret_brazier_'
	--- [StageCustomKey(StageId = 100090002, StageName = 'steampunk_1_2')]
	self.custom_key = {
	}

	-- 기타 상수
	self.train_num = 3
	self.crystal_item_id = 20190

	-- NPC 이름
	self.train_name = 'train_'

	-- 인베이더 크리스탈 이름
	self.invader_crystal_name = '[GIMMICK]invaders_crystal'
	self.invader_crystal_small_name = '[GIMMICK]invaders_smallcrystal'

	-- 크리스탈 파괴 FX
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.crystal_destroy_effect_preset = 'FX_Env_BigRock_lv2_destroy'
	self.crystal_small_destroy_effect_preset = 'FX_Env_SmallRock_lv2_destroy'

	-- 관사 입구 Exit
	self.entry_residence_name = 'entry_residence'

	-- 특수 NPC 이름
	self.player_refugee_male_name = 'knight_male_refugee'
	self.player_refugee_female_name = 'knight_female_refugee'
	self.refugee_poacher_name = 'refugee_poacher'
	self.refugee_poacher_lady_name = 'refugee_poacher_lady'
	self.refugee_elf_archer_name = 'refugee_elf_archer'
	self.refugee_goblin_name = 'refugee_goblin'

	-- 이벤트 이름
	self.on_off_interact_event_key = 'special_refugee'

	-- sfx
	self.lab_sfx = nil

	-- 강철의 연금술사 이벤트용 크리스탈 이름
	self.invader_crystal_fullmetal_name = 'invader_crystal_fullmetal'

	-- 현자의 돌 아이템 id
	self.sorcerer_stone_id = 20189

	self.get_fx_twinkle = function() return unity_object_pool.GetOrCreate('FX_Object_Twinkle') end

	self.stone_get_title = 'fullmetal_alchemist_title'
	self.stone_get_subtitle = 'fullmetal_alchemist_subtitle'
	self.stone_get_desc = 'fullmetal_alchemist_desc'

	self.stone_twinkle_effect = nil

	-- 뱁파이어 아이돌 이름
	self.vampireidol_name = 'vampireidol'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	unity_object_pool.GetOrCreate(self.hit_effect_preset)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset)
	unity_object_pool.GetOrCreate(self.crystal_destroy_effect_preset)
	unity_object_pool.GetOrCreate(self.crystal_small_destroy_effect_preset)

	self.get_fx_twinkle()

	get_character(self.vampireidol_name).Interactable.Talk = 'steampunk_vampireidol_talk_1'
	return
end

function local_class:need_on_launch()
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and main_quest.InnerProgress > 4 and main_quest.InnerProgress < 9
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.SwitchOnOffEvent) then
		if e.IsTurningOn and e.SwitchObject == get_field_object('secret_brazier_reset_button') then
			self:secret_brazier_reset()
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.ishya_note) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ishya_note_event, self))
		elseif lua_helper.reference_equals(e.Target, self.shyapira_note) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shyapira_note_event, self))
		elseif lua_helper.reference_equals(e.Target, self.wardrobe) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wardrobe_move, self))
		end

		-- 인베이더 크리스탈에 Interact
		if lua_helper.type_compare(e.Target.FieldObjectBehaviour, CS.Oak.InvaderCrystalBehaviour) and
			lua_helper.type_compare(e.Target.Interactable ,CS.Oak.OnOffPublishInteractable) then

			if stage.BattleManager:GetBattleFor(user_party_leader) == nil then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mine_crystal, self, e.Target))
			end
		end
	elseif event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:secret_brazier_setting()
		self:note_setting()
		self:wardrobe_setting()

		-- 기차 설정
		for i = 1, self.train_num do
			local cur_train = get_character(self.train_name..i)

			field_ui_manager:RemoveUI(cur_train, CS.Oak.FieldUiType.CharacterStats)
			cur_train.SpineController.IsShadowActive = false
		end
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter then
			if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				if e.Zone.Name == 'lab_zone' then
					music_player_util.play_stage_music({ state = 'muted', mix = 2 })
					self.lab_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_scifi_01', loop = true, type_priority = 'loop', player_priority = 'default' })
				end
			end
			if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				if e.Zone.Name == 'out_of_residence' then
					message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(255, 255, 255, 255), 0))
				elseif e.Zone.Name == 'residence' then
					message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))
				end
			end
		end
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if e.FullLeave then
			if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				if e.Zone.Name == 'lab_zone' then
					music_player_util.play_stage_music({ state = 'field', mix = 2 })
					self.lab_sfx:Stop()
					self.lab_sfx = nil
				end
			end
		end
	end

	return false
end

function local_class:is_fullmetal_event_done()
	local fullmetal_quest = user_progress:GetStartedQuest(135)	-- TODO : QuestId 수정

	return fullmetal_quest ~= nil and fullmetal_quest.IsComplete
end

function local_class:on_stage_start_event(e)
	-- 관사 Entry Hitbox 키우기
	local entry_residence = get_field_object(self.entry_residence_name)
	entry_residence.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.5), vector(2, 3, 3.1))

	-- 특수 NPC들 설정
	local special_refugee_list = create_generic_list(CS.Oak.Character)

	special_refugee_list:Add(get_character(self.refugee_poacher_name))
	special_refugee_list:Add(get_character(self.refugee_poacher_lady_name))
	special_refugee_list:Add(get_character(self.refugee_elf_archer_name))
	special_refugee_list:Add(get_character(self.refugee_goblin_name))

	for i = 0, special_refugee_list.Count - 1 do
		special_refugee_list[i].SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
		character_util.set_anim(special_refugee_list[i], { name = 'twohand_attack2' })
		character_util.set_emotion(special_refugee_list[i], { name = 'tired' })
	end

	message_system:Publish(CS.Oak.InteractableOnOffEvent.Create(self.on_off_interact_event_key, false))

	if not self:is_fullmetal_event_done() then
		local fullmetal_crystal = get_field_object(self.invader_crystal_fullmetal_name)

		self.stone_twinkle_effect = self.get_fx_twinkle()
										:Instantiate(fullmetal_crystal.Position + vector(0.5, 1, 0.5))
		self.stone_twinkle_effect.transform.localScale = 2 * unity_class.vector3.one
	end
end

function local_class:wardrobe_setting()
	local wardrobe_marker = field:GetMarker(self.wardrobe_marker_name)
	self.wardrobe = get_field_object(self.wardrobe_name)

	self.wardrobe.Interactable = CS.Oak.PublishInteractable.Create()
	self.wardrobe.Position = wardrobe_marker.position
	stage_util.set_fo_active_state(self.stair_name, 'visible')
end

-- 크리스탈 채굴
function local_class:mine_crystal(target)
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	user_party.Leader:HideWeapon(true)
	user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')

	-- twohand_attack 애니메이션이 없는 경우(4족 보행하는 푸른야수) attack 애니메이션을 대신 사용하도록 함.
	local animation_name = spine_util.has_animation(user_party.Leader, 'twohand_attack') and
		'twohand_attack' or 'attack'
	local base_anim_duration = 0.733
	local anim_duration = spine_util.get_animation_duration(user_party.Leader, animation_name)
	local anim_scale = anim_duration / base_anim_duration

	character_util.set_animation_n_times(user_party.Leader, { name = animation_name, scale = anim_scale, count = 3 })

	wait_for_sec(0.4)

	target:Shake(0.04, 1)

	for n = 0, 1 do
		music_player_util.play_sfx_one_shot('01_mining_01')
		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(target.Position)
		unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(target.Position)

		wait_for_sec(0.75)
	end

	music_player_util.play_sfx_one_shot('01_mining_01')
	music_player_util.play_sfx({ sfx_name = '03_rock_break_01', type_priority = 'event', player_priority = 'npc' })

	if target.Name == self.invader_crystal_name then
		unity_object_pool.GetOrCreate(self.crystal_destroy_effect_preset):Instantiate(target.Position)
	elseif target.Name == self.invader_crystal_small_name then
		unity_object_pool.GetOrCreate(self.crystal_small_destroy_effect_preset):Instantiate(target.Position)
	else
		-- 이름이 설정된 크리스탈들이 있어서 예외처리
		unity_object_pool.GetOrCreate(self.crystal_destroy_effect_preset):Instantiate(target.Position)
	end

	wait_for_sec(0.1)

	target.ActiveState = CS.Oak.ActiveState.Disabled

	if target.Name == self.invader_crystal_fullmetal_name and self.stone_twinkle_effect ~= nil then
		self.stone_twinkle_effect:Dispose()
		self.stone_twinkle_effect = nil
	end

	music_player_util.play_sfx({ sfx_name = '01_crystal_01', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.1, 0.3)
	local rand_pos = vector(CS.UnityEngine.Random.Range(-0.5, 0.5), 0, CS.UnityEngine.Random.Range(-0.5, 0.5))

	drop_item_util.create_item({ pos = target.Position, target = user_party.Leader.Position + rand_pos,
	                             itemid = self.crystal_item_id, notforinven = true })

	-- 큰 크리스탈은 한 개 더 드랍
	if target.Name == self.invader_crystal_name then
		local rand_pos_2 = vector(CS.UnityEngine.Random.Range(-0.5, 0.5), 0, CS.UnityEngine.Random.Range(-0.5, 0.5))

		drop_item_util.create_item({ pos = target.Position, target = user_party.Leader.Position + rand_pos_2,
		                             itemid = self.crystal_item_id, notforinven = true })
	elseif target.Name == self.invader_crystal_fullmetal_name and not self:is_fullmetal_event_done() then
		local drop_pos = target.Position + vector(0.5, 0, 0.5)

		drop_item_util.create_item({
			pos = drop_pos, target = drop_pos, sprscale = 0.5,
			itemid = self.sorcerer_stone_id, notforinven = true })
	end

	wait_for_sec(0.2)

	user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	user_party.Leader:HideWeapon(false)
	character_util.remove_anim(user_party.Leader)

	wait_for_sec(0.3)

	if target.Name == self.invader_crystal_fullmetal_name and not self:is_fullmetal_event_done() then
		wait_for_sec(1)

		yield_return_func(CS.Oak.CommonScreenplay.ItemGetEvent,
				{ItemId = self.sorcerer_stone_id}, self.stone_get_title, self.stone_get_subtitle, self.stone_get_desc)
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:wardrobe_move()
	field_ui_manager:Hide()
	CS.Oak.Party.MyParty:StopAndDisableControl()

	stage.FieldUINarrationBox:Show()

	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:GetString(self.secret_nar), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")

	local wait = true
	local branch = 0

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	-- 예
	branches:Add({
		Text = game_string:GetString(self.secret_branch_1),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			branch = 0
			wait = false
		end})
	-- 아니오
	branches:Add({
		Text = game_string:GetString(self.secret_branch_2),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			branch = 1
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party.Leader, branches)
	while wait do
		coroutine.yield(nil)
	end

	if branch == 0 then
		local wardrobe_marker = field:GetMarker(self.wardrobe_marker_name)
		local wardrobe_marker_end = field:GetMarker(self.wardrobe_end_marker_name)
		local wardrobe = get_field_object(self.wardrobe_name)
		local wait_pos = get_field_object(self.stair_name)

		local current_time = 0
		local end_time = 0.5
		local start_pos = wardrobe_marker.position
		local end_pos = (wardrobe_marker.position + wardrobe_marker_end.position) / 2

		--옷장을 왼쪽으로 두 타일 밀어냄
		character_util.align_party(start_pos + unity_class.vector3.right, 'right', 1.0, 'arc')
		wait_for_sec(0.5)

		local leader_pos = user_party_leader.Position

		party_util.set_anim({ name = 'push' })
		party_util.set_emotion({ name = 'damaged' })
		party_util.set_direction('left')

		local move_coroutine = function()
			current_time = 0
			camera_util.shake(0.1, end_time)
			music_player:PlaySfxOneShot(self.gimmick_door_down_sfx_name)

			while current_time <= end_time do
				current_time = current_time + unity_class.time.deltaTime

				local progress = unity_class.mathf.Clamp01(current_time/end_time)
				local current_xz = unity_class.vector3.Lerp(start_pos, end_pos, progress)

				wardrobe.Position = current_xz
				user_party:PositionParty(current_xz + unity_class.vector3.right * 2, CS.Oak.Direction.Left, 0, CS.Oak.Party.AlignType.Arc)
				--character_util.align_party(current_xz + unity_class.vector3.right, 'right', 0.1, 'arc')

				coroutine.yield(nil)
			end
		end

		yield_return_func(move_coroutine)
		wait_for_sec(0.5)

		start_pos = end_pos
		end_pos = wardrobe_marker_end.position
		yield_return_func(move_coroutine)

		--이벤트 전에 계단 상호작용을 막기 위해, 사전에 visible상태로 설정
		--옷장 밀어내는 이벤트가 끝난 것을 확인 후 enabled로 전환
		party_util.remove_animation()
		party_util.remove_emotion()
		character_util.align_party(wait_pos, 'down', 1.0, 'linear')

		wait_for_sec(0.2)
		stage_util.set_fo_active_state(self.stair_name, 'enabled')

		self.wardrobe.Interactable = CS.Oak.NonInteractable.Instance
	end

	field_ui_manager:Show()
	CS.Oak.Party.MyParty:ResetControllers()
end

function local_class:note_setting()
	local ishya_note_pos = vector_util.get_x0z(field:GetMarker(self.ishya_note_marker_name).position, 1)
	local shyapira_note_pos = vector_util.get_x0z(field:GetMarker(self.shyapira_note_marker_name).position, 1)

	drop_item_util.create_item({ pos = ishya_note_pos,
												   itemid = self.note_item_id, notforinven = true, lootstate = 'dontfindlooter' })
	drop_item_util.create_item({ pos = shyapira_note_pos,
												   itemid = self.note_item_id, notforinven = true, lootstate = 'dontfindlooter' })

	self.ishya_note = get_field_object(self.ishya_note_name)
	self.shyapira_note = get_field_object(self.shyapira_note_name)

	self.ishya_note.Interactable = CS.Oak.PublishInteractable.Create()
	self.shyapira_note.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:ishya_note_event()
	field_ui_manager:Hide()
	CS.Oak.Party.MyParty:StopAndDisableControl()

	stage.FieldUINarrationBox:Show()

	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:GetString(self.ishya_note_nar), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")

	field_ui_manager:Show()
	CS.Oak.Party.MyParty:ResetControllers()
end

function local_class:shyapira_note_event()
	field_ui_manager:Hide()
	CS.Oak.Party.MyParty:StopAndDisableControl()

	stage.FieldUINarrationBox:Show()

	yield_return(stage.FieldUINarrationBox, "SetNarration",
			game_string:GetString(self.shyapira_note_nar), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")

	field_ui_manager:Show()
	CS.Oak.Party.MyParty:ResetControllers()
end

function local_class:secret_brazier_setting()
	for i = 1, 6 do
		table.insert(self.brazier_list, get_field_object(string.format('%s%d', self.braziers_name, i)))
	end
	self:secret_brazier_reset()
end

function local_class:secret_brazier_reset()
	local bust_cs = CS.Oak.LuaICombustibleBehaviour()
	-- 화로 문의 개방 조건은 화로 3, 5, 6번만 켜져있는 상태이다.
	-- 이때, 1, 3, 5, 6번 화로가 켜진 상태에서 오름차순으로 화로를 꺼주면 도중에 개방 조건을 만족하여 문이 열리게 된다.
	-- 따라서 개방 조건에 해당하는 6번 화로부터 내림차순으로 화로룰 꺼주어 연출상 이슈가 없도록 한다.
	for i = 1, 6 do
		bust_cs:GetExtinguishedBy(self.brazier_list[7 - i], nil)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	get_character(self.vampireidol_name).Interactable.Talk = nil

	if self.lab_sfx ~= nil then
		self.lab_sfx:Stop()
		self.lab_sfx = nil
	end

	if self.stone_twinkle_effect ~= nil then
		self.stone_twinkle_effect:Dispose()
		self.stone_twinkle_effect = nil
	end

	self.ishya_note = nil
	self.shyapira_note = nil
	self.wardrobe = nil
	self.brazier_list = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
