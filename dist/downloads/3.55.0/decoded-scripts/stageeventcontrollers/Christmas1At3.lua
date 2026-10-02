local local_class = newclass("Christmas1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 눈 내리는 효과
	self.snow_screen_effect = nil

	-- 리소스 홀더
	self.resholder = CS.Foundations.ResourceHolder()

	-- 캠프파이어 효과
	self.campfire_effect = nil

	self.played_flag = false
	self.santa_start_flag = false

	-- 플레이어가 내부 공간에 있는지 저장
	self.is_inner = false

	-- 골드 트리 예티와 전투 중인지?
	self.is_battle_gold_tree_yeti = false

	-- 골드 트리 예티존 이름
	self.gold_tree_yeti_zone_name = 'BATTLE_gold_tree_yeti'

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
end

function local_class:get_knight()
	if user_util.has_knight_male() then
		return get_character('knight_male')
	end

	return get_character('knight_female')
end


function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate("FX_Blizzard")
	unity_object_pool.GetOrCreate('FX_Event_InvaderBeam')
	unity_object_pool.GetOrCreate('fx_xmas_campfire')

	local main_quest_id = 60045
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest.IsComplete or main_quest.InnerProgress > 8 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_snow, self))
	end

	unity_object_pool:WaitAll()
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)

	local xmas_main_quest_id = 60045
	local q = user_progress:GetStartedQuest(xmas_main_quest_id)

	-- 모든 파티원들을 파티에서 제외시키고, 비활성화 함.
	self:change_manual_character(self:get_knight().Name)

	local i = 1
	while true do
		local invader = get_character('battle_3_'..i)
		if is_unity_null(invader) then break end
		character_util.set_active_state(invader, 'disabled')
		i = i + 1
	end

	-- 3스테이지 메인퀘 섹션 8/9/10로 입장시 연출을 위해 오프닝을 위임함
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	if not (q.InnerProgress == 7 or q.InnerProgress == 8) then
		if q.IsComplete or q.InnerProgress > 8 then
			local campfire_1 = get_field_object('campfire_1')
			campfire_1.ActiveState = CS.Oak.ActiveState.Disabled
			local campfire_brazier = get_field_object('campfire_brazier')
			campfire_brazier.Position =  field:GetMarker('central_plaza').position
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_campfire, self))

			local brazier_placeholder = get_character('brazier_placeholder')
			brazier_placeholder.ActiveState = CS.Oak.ActiveState.InField
			brazier_placeholder.Position = campfire_brazier.Position

			local snowtomb = get_field_object('princess_snow_mound')
			snowtomb.ActiveState = CS.Oak.ActiveState.Disabled
		end

		if q.IsComplete or q.InnerProgress > 9 then
			for i = 1,3 do
				local tree = get_field_object('gold_tree_'..i)
				tree.ActiveState = CS.Oak.ActiveState.Disabled
			end

			local stewpot = get_field_object('campfire_brazier')
			stewpot.Interactable = CS.Oak.PublishInteractable.Create()
		end

		if q.InnerProgress == 9 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.custom_intro, self))
		else
			sp_util.play_normal_screenplay(self.custom_intro, self)
		end
	end
end

function local_class:custom_intro()
	local need_to_update_weapon = true

	-- 섹션 8 이나 9 의 경우 강제 무기 업데이트를 하지 않는다.
	local xmas_main_quest_id = 60045
	local q = user_progress:GetStartedQuest(xmas_main_quest_id)
	if q == nil or q.InnerProgress == 7 or q.InnerProgress == 8 then
		need_to_update_weapon = false
	end

	-- 그 외의 경우 가지고 있는 곡괭이 중 가장 강한것을 장비한다
	if need_to_update_weapon then
		message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_weapon_query_response')

		self.weapon_query_responded = false;
		self.weapon_query_response = nil

		local params = create_generic_list(CS.System.String)
		params:Add("xmas_survival_weapon_query")
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party[0], params:ToArray()))

		local walker = 0
		while not self.weapon_query_responded do
			coroutine.yield(nil)
			walker = walker + 1
			if walker > 100 then
				CS.UnityEngine.Debug.LogError("No weapon query response")
				break
			end
		end

		message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_weapon_query_response')

		local weapon_name = self.weapon_query_response
		if weapon_name == nil then
			weapon_name = "xmas_pickaxe_bronze_epic"
		end

		-- HACK : DefaultCharacterGenerator 에서 무기 세팅을 하고 끝날때까지 가디리지 않기 때문에 여기서 기다려줘야 한다.
		while user_party[0].IsChangingEquipment do
			coroutine.yield(nil)
		end

		local item_data = game_data_service.GetData('ItemData')
		local spec = item_data:GetSpec(weapon_name)
		local gear  = CS.Oak.Item.Create(spec)

		user_party[0]:SetEquipment(CS.Oak.EquipmentSlot.Weapon2, nil , false)
		user_party[0]:SetEquipment(CS.Oak.EquipmentSlot.Weapon1, gear)

		coroutine.yield(nil)
		coroutine.yield(nil)

		while user_party[0].IsChangingEquipment do
			coroutine.yield(nil)
		end
	end

	if q.InnerProgress > 9 or q.IsComplete then
		music_player_util.play_stage_music({ state = 'field' })
		stage_launch_util.default_launch_with_marker_name('default_start', true)
	end
end

function local_class:on_weapon_query_response(e)
	if e:GetParamAt(0) == "xmas_survival_weapon_response" then
		self.weapon_query_responded = true
		self.weapon_query_response = e:GetParamAt(1)
	end
end


-- 플레이어 캐릭터 변경 및 파티 전체 비활성화
function local_class:change_manual_character(new_manual_character_name)
	local saved_party_leader = user_party_leader
	local manual_character = get_character(new_manual_character_name)

	-- 레벨 업
	--local exp = user_party_leader.FieldObjectStatsBehaviour.Exp
	--manual_character.FieldObjectStatsBehaviour:SetExp(exp)

	-- 파티 리더 변경
	party_util.switch_leader(manual_character)

	character_util.set_direction(manual_character, saved_party_leader.Direction)

	-- 기존 캐릭터 보이지 않는 곳으로 이동
	character_util.set_position(saved_party_leader, vector(999, 0, 999))

	-- field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.TopHpBar)

	local party_list = {}

	for i = 1, user_party.Count - 1 do
		local cur_party_member = user_party[i]
		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		character_util.convert_to_npc(party_list[i])
		character_util.set_active_state(party_list[i], 'disabled')
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	if self.snow_screen_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.snow_screen_effect)
		self.snow_screen_effect = nil
	end

	if self.campfire_effect ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.campfire_effect.gameObject)
		self.campfire_effect = nil
	end

	if self.resholder ~= nil then
		self.resholder:Dispose()
	end

	self.played_flag = nil
	self.santa_start_flag = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		-- 밤 분위기 연출을 위해 틴트
		field:Tint("night", CS.UnityEngine.Color(0.3, 0.3, 0.6, 0.8), 0.0)

		-- 다리 세팅
		local is_bridge_fixed = false

		local xmas_main_quest_id = 60045
		local q = user_progress:GetStartedQuest(xmas_main_quest_id)

		if q.InnerProgress > 9 then
			is_bridge_fixed = true
		end

		field.Tilemap.Transform:Find("obj1").gameObject:SetActive(is_bridge_fixed)

		if is_bridge_fixed then
			get_field_object("broken_bridge_1").ActiveState = CS.Oak.ActiveState.Disabled
			get_field_object("broken_bridge_2").ActiveState = CS.Oak.ActiveState.Disabled
			get_field_object("broken_bridge_3").ActiveState = CS.Oak.ActiveState.Disabled
		else
			get_field_object("broken_bridge_1").ActiveState = CS.Oak.ActiveState.Enabled
			get_field_object("broken_bridge_2").ActiveState = CS.Oak.ActiveState.Enabled
			get_field_object("broken_bridge_3").ActiveState = CS.Oak.ActiveState.Enabled
		end

		for i = 1, 8 do
			local marker_pos = field:GetMarker(string.format("powder_%d", i)).position
			marker_pos.y = 1
			self:put_item_at("xmas_component_explosive_powder", marker_pos)
		end

		-- 예티 시리즈에게 Damage reduction buff
		-- 2000 -> 2600, 20000 -> 22600 ( 크리티컬 데미지가 뜰때도 데미지 0 들어가게 ).
		self:add_damage_reduction_to("gold_tree_yeti", 2600)
		-- 몬스터에 방어력 적용되게 되면서 버프레벨 하향조정함. 
		self:add_damage_reduction_to("fat_yeti", 15000)

	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.QuestProgressedEvent) then
		self:on_quest_progressed_event(e)
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == 60045 then
		if e.CurrentProgress == 9 then
			if self.snow_screen_effect == nil then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_snow, self))
			end
			if self.campfire_effect == nil then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_campfire, self))
			end
		end
	end
end

function local_class:set_campfire()
	local central_plaza = field:GetMarker('central_plaza').position
	self.campfire_effect = load_util.load_prefab_async(self.resholder, 'ondemand/xmas/effects',
			'fx_xmas_campfire_pot')

	coroutine.yield(nil)

	self.campfire_effect.gameObject.transform.position = central_plaza
end

function local_class:set_snow()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/xmas/effects', 'fx_xmas_stage_snow_camera_fx', function(prefab)
				self.snow_screen_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.snow_screen_effect.transform:SetParent(stage_camera.Transform.parent)
				self.snow_screen_effect.transform.localPosition = unity_class.vector3.zero
				self.snow_screen_effect.transform.localRotation = unity_class.quaternion.Euler(unity_class.vector3.zero)
			end)
end

function local_class:on_interact_event(e)
	local stewpot = get_field_object('campfire_brazier')

	if lua_helper.reference_equals(e.Target, stewpot) then
		local main_quest_id = 60045
		local main_quest = user_progress:GetStartedQuest(main_quest_id)
		if main_quest.InnerProgress > 9 or main_quest.IsComplete then
			local knight = self:get_knight()
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = knight
			heal_info.isRevive = false
			heal_info.heal = knight.FieldObjectStatsBehaviour.MaxHP

			for i = 0, user_party.Count - 1 do
				heal_info.target = user_party[i]
				heal_info.heal = user_party[i].FieldObjectStatsBehaviour.MaxHP
				command_util.execute_heal(heal_info)
			end
		end
	else
		local gameboy = get_field_object("gameboy")
		if lua_helper.reference_equals(gameboy, e.Target) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gameboy_interaction, self, gameboy))
		end
	end
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end
	if not e.FullEnter then return false end

	local zone_name = e.Zone.Name

	if zone_name == 'battle_3_zone_entry' and not self.played_flag then
		self.played_flag = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.invader_appear, self))
		return true
	elseif zone_name == 'ancient_santa_start' and not self.santa_start_flag then
		self.santa_start_flag = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ancient_santa_appear, self))
		return true
	elseif zone_name == 'inner' and not self.is_inner then
		self.is_inner = true

		if self.snow_screen_effect ~= nil then
			self.snow_screen_effect:SetActive(false)
			field:RemoveTint('night')
		end
		return true
	elseif zone_name == self.gold_tree_yeti_zone_name then
		self.is_battle_gold_tree_yeti = true
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave == false then return false end
	if e.FieldObject ~= user_party_leader then return false end

	if e.Zone.Name == 'inner' and self.is_inner then
		self.is_inner = false

		field:Tint("night", CS.UnityEngine.Color(0.3, 0.3, 0.6, 0.8), 0.0)
		if self.snow_screen_effect ~= nil then
			self.snow_screen_effect:SetActive(true)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_snow, self))
		end
		return true
	elseif e.Zone.Name == self.gold_tree_yeti_zone_name then
		self.is_battle_gold_tree_yeti = false
		return true
	end

	return false
end

function local_class:on_damage_event(e)
	if self.is_battle_gold_tree_yeti then return false end

	local gold_tree_yeti = get_character('gold_tree_yeti')
	if e.Info.target == gold_tree_yeti then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cancel_gold_yeti_aggro
		, self, gold_tree_yeti))
		return true
	end

	return false
end

function local_class:cancel_gold_yeti_aggro(gold_tree_yeti)
	-- 예티 전투 종료
	message_system:Publish(CS.Oak.MonsterGiveUpEvent.Create(gold_tree_yeti, self.gold_tree_yeti_zone_name))

	-- 파티원 어그로 풀고 리더 따라가기
	for i = 1, user_party.Count - 1 do
		local clms = CS.Oak.CharacterControllerPartyFollowState.Create(user_party[i], user_party)
		user_party[i]:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
	end
	coroutine.yield(nil)

	-- 예티 전투 스테이트 초기화
	gold_tree_yeti:OnEvent(CS.Oak.ReturnToPatrolEvent.Instance)
end

function local_class:ancient_santa_appear()
	local santa = get_character('ancient_santa')

	character_util.set_active_state(santa, 'enabled')
	character_util.spine_set_alpha_fade(santa, 0.5, 0)

	local santa_ui = field_ui_manager:GetUI(santa)[CS.Oak.FieldUiType.CharacterStats]
	santa_ui.Level.gameObject:SetActive(false)

	while self.santa_start_flag do
		local dist = (user_party.Leader.Position - santa.Position).magnitude / 5
		character_util.spine_set_alpha_fade(santa, dist > 1 and 0.5 or dist/2 , 0)
		coroutine.yield(nil)
	end
end

function local_class:invader_appear()
	local invaders = { }

	local i = 1
	while true do
		local invader = get_character('battle_3_'..i)
		if is_unity_null(invader) then break end
		table.insert(invaders, invader)
		i = i + 1
	end

	music_player_util.play_sfx({ sfx_name = '01_invader_beam_01', type_priority = 'event', player_priority = 'npc' })

	for _, invader in ipairs(invaders) do
		unity_object_pool.GetOrCreate('FX_Event_InvaderBeam'):Instantiate(invader.Position)
	end

	wait_for_sec(1)

	for _, invader in ipairs(invaders) do
		character_util.set_active_state(invader, 'enabled')
		character_util.look_at(invader, user_party.Leader)
		character_util.convert_to_monster(invader, 'battle_3', 'battle_3_zone')

		local cmd = CS.Oak.MonsterNoticeCommand.Create(invader, user_party.Leader, CS.Oak.MonsterNoticeLevel.Battle)
		command_util.publish_cmd(invader.Owner, cmd)
	end
end

function local_class:add_damage_reduction_to(character_name, dr)
	local character = get_character(character_name)
	if character == nil then
		CS.UnityEngine.Debug.LogError("Can't find a character")
		return
	end

	stage.BuffManager:AddBuff(character, CS.Oak.EquipmentSlot.None, character, 'damage_reduction_persistent', dr, false, false)
	stage.BattleManager:AddToNoAssassination(character)
end

function local_class:put_item_at(item_name, pos)
	local item_data = CS.Oak.GameDataService.GetData("ItemData")
	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = item_data:GetSpec(item_name).Id
	item_place_holder.Amount = 1
	item_place_holder.NotForInventory = true
	CS.Oak.DropItem.Create(pos, item_place_holder);
end

function local_class:gameboy_interaction(gameboy)
	coroutine.yield(user_party:AlignPartyNew(gameboy, CS.Oak.Direction.Down, 0.5))
	music_player:PlaySfxOneShot('03_dialogue_worker_01')
	speech_bubble_util.show_speech_bubble_async(gameboy, { key = "christmas_1_3_gameboy_1", skip = true })
	speech_bubble_util.show_speech_bubble_async(gameboy, { key = "christmas_1_3_gameboy_2", skip = true })
	user_party:ResetControllers()
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
