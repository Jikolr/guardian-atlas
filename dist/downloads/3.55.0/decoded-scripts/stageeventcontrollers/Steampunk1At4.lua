local local_class = newclass("Steampunk1At4Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- [StageCustomKey(StageId = 100090004, StageName = 'steampunk_1_4')]
	self.custom_key = {
	}

	-- 기타 상수
	self.train_num = 3
	self.crystal_item_id = 20190

	-- NPC 이름
	self.train_name = 'train_'

	-- 표지판 이름
	self.signboard_name = 'rest_signboard'

	-- 인베이더 크리스탈 이름
	self.invader_crystal_name = '[GIMMICK]invaders_crystal'
	self.invader_crystal_small_name = '[GIMMICK]invaders_smallcrystal'

	-- 크리스탈 파괴 FX
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.crystal_destroy_effect_preset = 'FX_Env_BigRock_lv2_destroy'
	self.crystal_small_destroy_effect_preset = 'FX_Env_SmallRock_lv2_destroy'

	-- 관사 입구 Exit
	self.fake_enterance_name = 'fake_enterance'

	quest_icon.PreLoad()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent), 'on_event')

	unity_object_pool.GetOrCreate(self.hit_effect_preset)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset)
	unity_object_pool.GetOrCreate(self.crystal_destroy_effect_preset)
	unity_object_pool.GetOrCreate(self.crystal_small_destroy_effect_preset)

	return
end

function local_class:need_on_launch()
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and main_quest.InnerProgress == 12
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
	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		-- 기차 설정
		for i = 1, self.train_num do
			local cur_train = get_character(self.train_name..i)

			field_ui_manager:RemoveUI(cur_train, CS.Oak.FieldUiType.CharacterStats)
			cur_train.SpineController.IsShadowActive = false
		end
	elseif event_type == typeof(CS.Oak.StageStartEvent) then
		-- 표지판 기믹 쓰러져있도록
		local signboard = get_field_object(self.signboard_name)

		-- 그림자 비활성화
		signboard.transform:GetChild(0).gameObject:SetActive(false)
		signboard.transform.localRotation = unity_class.quaternion.Euler(75, -90, 0)
		signboard.Position = signboard.Position + vector(-0.3, 0, 0)
		signboard.Hitbox = CS.Oak.Hitbox(vector(1, 0, 0.5), vector(1.5, 0.3, 1))

		-- 관사 Entry Hitbox 키우기
		local entry_residence = get_field_object(self.fake_enterance_name)
		entry_residence.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.5), vector(2, 3, 3.1))
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		-- 인베이더 크리스탈에 Interact
		if lua_helper.type_compare(e.Target.FieldObjectBehaviour, CS.Oak.InvaderCrystalBehaviour) and
				lua_helper.type_compare(e.Target.Interactable ,CS.Oak.OnOffPublishInteractable) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mine_crystal, self, e.Target))
		elseif lua_helper.reference_equals(e.Target, get_field_object(self.fake_enterance_name)) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_fake_entrance, self))
		end
	elseif event_type == typeof(CS.Oak.ConvertSwitchChangedEvent) then
		-- FIXME: 청홍 스위치에서는 소리가 나지 않고 벽에서만 나고 있는데 벽 그리드가 플레이어 그리드와 달라서 소리가 나지 않는 문제 임시 해결
		music_player_util.play_sfx({ sfx_name = '01_blueredwall_01', type_priority = 'event', player_priority = 'npc' })
	end

	return false
end

function local_class:on_stage_loaded(_)
	return true
end

-- 크리스탈 채굴
function local_class:mine_crystal(target)
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	user_party.Leader:HideWeapon(true)
	user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
	character_util.set_anim(user_party_leader, { name = 'twohand_attack', sfx_name = '01_mining_01' })

	wait_for_sec(0.4)

	target:Shake(0.04, 1)

	for n = 0, 1 do
		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(target.Position)
		unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(target.Position)

		wait_for_sec(0.75)
	end

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

	music_player_util.play_sfx({ sfx_name = '01_crystal_01', type_priority = 'event', player_priority = 'npc' })

	camera_util.shake(0.1, 0.3)

	local rand_pos = vector(CS.UnityEngine.Random.Range(-0.5, 0.5), 0, CS.UnityEngine.Random.Range(-0.5, 0.5))

	drop_item_util.create_item({ pos = target.Position, target = user_party_leader.Position + rand_pos,
	                             itemid = self.crystal_item_id, notforinven = true })

	-- 큰 크리스탈은 한 개 더 드랍
	if target.Name == self.invader_crystal_name then
		local rand_pos_2 = vector(CS.UnityEngine.Random.Range(-0.5, 0.5), 0, CS.UnityEngine.Random.Range(-0.5, 0.5))

		drop_item_util.create_item({ pos = target.Position, target = user_party_leader.Position + rand_pos_2,
		                             itemid = self.crystal_item_id, notforinven = true })
	end

	wait_for_sec(0.2)

	user_party.Leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	user_party.Leader:HideWeapon(false)
	character_util.remove_anim(user_party_leader)

	wait_for_sec(0.3)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:interact_with_fake_entrance()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	stage.FieldUINarrationBox:Show()

	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString('steampunk_1_4_fake_enterance'), 0, 1.0))

	stage.FieldUINarrationBox:Hide()

	wait_for_sec(0.3)

	character_util.set_direction(user_party_leader, 'down')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
