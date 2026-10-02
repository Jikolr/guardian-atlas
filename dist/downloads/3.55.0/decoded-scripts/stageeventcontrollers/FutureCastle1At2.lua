local local_class = newclass("FutureCastle1At2Controller")

local EventProgress = {
	idle = 0,
	shelter = 1,
}

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.event_progress = EventProgress.idle

	-- 내부 입장 플래그
	self.is_enter_inner = false

	-- 필드오브젝트 이름

	-- 필드 이벤트 존 이름
	self.shelter_zone_name = 'shelter'

	-- 커스텀 이벤트 이름
	self.invader_attack_start_event = 'invader_attack_start'
	self.invader_attack_end_event = 'invader_attack_end'

	-- 오브젝트 풀 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.smokescreen_preset = 'FX_Common_SmokeScreen'
	self.get_effect_preset = 'FX_get'

	self.short_event_state = {
		none = -1, -- 실행되지 않음
		ready = 0, -- 이벤트 볼 준비 됨
		in_control = 1, -- 컨트롤 뺏지 않은 상태의 이벤트
		scene = 2, -- 컨트롤 뺏은 상태의 이벤트
		done = 99    -- 이벤트 다 봄
	}

	self.custom_key = {
		favi_event = 1,
		tent_event = 2,
		--stew_event = 3,
		blacksmith_event = 4,
		china_event = 5,
		snow_event = 6,
		jump_tile_show_event = 7,
		succubus_event = 8,
		desert_event = 9
		--shen_city_event = 5
	}

	--region 의료 캠프 대화 이벤트

	self.get_favi = function()
		return get_character('favi')
	end

	self.favi_event_state = self.short_event_state.none

	self.hospital_event_zone = 'section_8_hospital'

	--endregion

	--region 텐트촌 이벤트

	self.get_tent_helper = function(num)
		return get_character('tent_helper_refugee_' .. num)
	end
	self.get_tent_thanker = function()
		return get_character('tent_thank_refugee')
	end

	self.get_firewood = function()
		return get_field_object('tent_help_firewood')
	end

	self.apple_id = 20020
	self.water_id = 20035

	self.tent_event_state = self.short_event_state.none

	self.tent_event_zone = 'tent_help'

	--endregion

	--region 대장간 이벤트

	self.get_blacksmith = function()
		return get_character('blacksmith')
	end
	self.get_blacksmith_soldier_1 = function()
		return get_character('resistance_camp_b_4')
	end
	self.get_blacksmith_soldier_2 = function()
		return get_character('resistance_camp_b_6')
	end

	self.get_fx_dead = function()
		return unity_object_pool.GetOrCreate('FX_dead')
	end

	self.origin_shield_id = 9080020
	self.sword_id = 9010243
	self.origin_gun_id = 9030020
	self.shield_id = 9080020

	self.origin_shield_item = nil
	self.sword_item = nil
	self.origin_gun_item = nil
	self.shield_item = nil

	self.blacksmith_event_state = self.short_event_state.none

	self.blacksmith_event_zone = 'blacksmith'

	--endregion

	--region 셴 시 NPC 이벤트

	self.get_shen_talker = function()
		return get_character('china_refugee_3')
	end

	self.shen_event_state = self.short_event_state.none

	--endregion

	--region 하이퍼 스타피스 이벤트

	-- 이벤트 존 이름
	self.bgm_event_zone_name = 'hyper_bgm_zone'

	--endregion

	--region 셴 시 난민 ZONE 이벤트

	self.china_event_zone = 'china_tent_zone'
	self.get_china_sapa = function()
		return get_character('china_refugee_6')
	end
	self.get_china_jungpa = function()
		return get_character('china_refugee_2')
	end

	self.china_event_state = self.short_event_state.none

	-- china_tent_zone에 들어왔는지
	self.in_china_tent_zone = false

	-- endregion

	--region 설산 난민 ZONE 이벤트

	self.snow_event_zone = 'snow_tent_zone'
	self.get_snow_kid_boy = function()
		return get_character('innuit_refugee_7')
	end
	self.get_snow_kid_girl = function()
		return get_character('innuit_refugee_8')
	end
	self.get_snow_female = function()
		return get_character('innuit_refugee_3')
	end
	self.get_snow_male = function()
		return get_character('innuit_refugee_2')
	end
	self.get_snow_mother = function()
		return get_character('innuit_refugee_5')
	end
	self.get_happy_snowman = function()
		return get_character('happy_snowman')
	end
	self.get_snow_kid_boy2 = function()
		return get_character('innuit_refugee_6')
	end

	self.snow_event_state = self.short_event_state.none

	-- endregion

	--region 사막 폭주족 텐트 방향 점프 타일 활성/비활성화 이벤트

	-- 점프 타일 활성화 플래그
	self.jump_tile_on = false

	-- 필드오브젝트 이름
	self.jump_tile_name = '_jump_tile_'
	self.jump_switch_name = 'desert_jump_switch'

	self.jump_tile_event_state = self.short_event_state.none

	--endregion

	--region 서큐버스 난민 ZONE 이벤트

	self.succubus_event_zone = 'succubus_tent_zone'

	self.get_maya = function()
		return get_character('succubus_refugee_4')
	end
	self.get_talker_1 = function()
		return get_character('succubus_refugee_2')
	end
	self.get_talker_2 = function()
		return get_character('succubus_refugee_6')
	end
	self.get_talker_3 = function()
		return get_character('succubus_refugee_7')
	end

	self.succubus_event_state = self.short_event_state.none

	-- endregion

	--region 사막 난민 ZONE 이벤트

	self.desert_event_zone = 'desert_tent_zone'

	self.get_desert_1 = function()
		return get_character('desert_refugee_5')
	end
	self.get_desert_2 = function()
		return get_character('desert_refugee_1')
	end
	self.get_desert_3 = function()
		return get_character('desert_refugee_3')
	end
	self.get_camp_fire = function()
		return get_field_object('desert_campfire')
	end

	self.desert_event_state = self.short_event_state.none

	-- endregion

	self.box_openning = false
	-- 공주 쪽지
	self.paper_drop_item = nil
end

function local_class:load_resource()
	unity_object_pool.GetOrCreate(self.hit_effect_preset)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset)
	unity_object_pool.GetOrCreate(self.smokescreen_preset)
	unity_object_pool.GetOrCreate(self.get_effect_preset)

	self.get_fx_dead()

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest ~= nil and main_quest.InnerProgress > 6 then
		get_field_object('break_barricade').ActiveState = active_state('disabled')
	end

	return main_quest ~= nil and not main_quest.IsComplete and (main_quest.InnerProgress == 4 or main_quest.InnerProgress == 10)
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		self:on_custom_stage_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		self:on_switch_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TreasureOpenedEvent) then
		self:on_treasure_opened_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ConvertSwitchChangedEvent) then
		self:on_convert_switch_changed_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		self:on_item_get_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.TreasureOpenScreenPlayEndEvent) then
		if self.box_openning then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
				user_party:StopAndDisableControl()
				stage.FieldUIManager:Hide()
				character_util.set_anim_and_emotion(user_party_leader, { name = 'victory_extra'}, { name = 'smile'})
			end))
		end
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	self:set_event()
end

function local_class:on_stage_start_event(e)
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then
		return
	end
	if e.FieldObject ~= user_party_leader then
		return
	end
	local zone_name = e.Zone.Name

	if zone_name == self.shelter_zone_name then
		if not self.is_enter_inner then
			self.is_enter_inner = true

			self:enter_shelter_event()
		end
	elseif zone_name == self.tent_event_zone then
		if self.tent_event_state == self.short_event_state.ready then
			self.tent_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tent_routine, self))
		end

	elseif zone_name == self.blacksmith_event_zone then
		if self.blacksmith_event_state == self.short_event_state.ready then
			self.blacksmith_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.blacksmith_routine, self))
		end
	elseif zone_name == self.bgm_event_zone_name then
		music_player_util.play_stage_music({ state = 'muted' })
	elseif zone_name == self.china_event_zone then
		self.in_china_tent_zone = true

		if self.china_event_state == self.short_event_state.ready then
			self.china_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.china_tent_event, self))
		end
	elseif zone_name == self.snow_event_zone then
		if self.snow_event_state == self.short_event_state.ready then
			self.snow_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.snow_tent_event, self))
		end
	elseif zone_name == self.hospital_event_zone then
		if self.favi_event_state == self.short_event_state.ready then
			self.favi_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hospital_event, self))
		end
	elseif zone_name == self.succubus_event_zone then
		if self.succubus_event_state == self.short_event_state.ready then
			self.succubus_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.succubus_tent_event, self))
		end
	elseif zone_name == self.desert_event_zone then
		if self.desert_event_state == self.short_event_state.ready then
			self.desert_event_state = self.short_event_state.in_control
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.desert_tent_event, self))
		end
	end

	-- 공주방 보물상자를 이미 열었다면 상호작용 못하도록 수정
	local princess_chest = get_field_object('princess_chest')
	if princess_chest.FieldObjectBehaviour.IsOpened then
		princess_chest.Interactable = CS.Oak.NonInteractable.Instance
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then
		return
	end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return
	end
	local zone_name = e.Zone.Name

	if zone_name == self.shelter_zone_name then
		if self.is_enter_inner then
			self.is_enter_inner = false

			self:leave_shelter_event()
		end
	elseif zone_name == self.bgm_event_zone_name then
		music_player_util.play_stage_music({ state = 'field' })
	elseif zone_name == self.china_event_zone then
		self.in_china_tent_zone = false
	end
end

function local_class:on_convert_switch_changed_event(e)
	-- FIXME: 청홍 스위치에서는 소리가 나지 않고 벽에서만 나고 있는데 벽 그리드가 플레이어 그리드와 달라서 소리가 나지 않는 문제 임시 해결
	music_player_util.play_sfx({ sfx_name = '01_blueredwall_01', type_priority = 'event', player_priority = 'npc' })
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.invader_attack_start_event then
			self:block_event_data()
			self:stop_blacksmith_routine()

			if self.paper_drop_item ~= nil then
				self.paper_drop_item.Position = vector(999, 0, 999)
			end

			stage_util.set_fo_active_state('princess_paper', 'disabled')
		elseif e.Params[0] == self.invader_attack_end_event then
			if self.paper_drop_item ~= nil then
				local marker = field:GetMarker('princess_paper')
				self.paper_drop_item.Position = marker.position + vector(0.5, 0, 0)
			end

			stage_util.set_fo_active_state('princess_paper', 'enabled')
		end
	end
end

function local_class:on_switch_event(e)
	local sw = get_field_object(self.jump_switch_name)
	if lua_helper.reference_equals(e.SwitchObject, sw) and e.IsTurningOn and not self.jump_tile_on then
		self.jump_tile_on = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.turn_on_jump_tiles, self))
		return true
	end
	return false
end

function local_class:on_treasure_opened_event(e)
	local princess_chest = get_field_object('princess_chest')
	if lua_helper.reference_equals(e.Target, princess_chest) then
		sp_util.play_normal_screenplay(function()
			wait_for_sec(1.5)
			self.box_openning = true
			local marker = field:GetMarker('princess_paper')

			local items = {}
			-- 가짜 젬
			for i = 1, 12 do

				local x = random_util.get_random_int(-24, 24) * 0.1
				local y = random_util.get_random_int(-8, 8) * 0.1
				local get_random_pos = vector(x,0,y)
				get_random_pos.y = 0
				local cur_item = drop_item_util.create_item({ itemid = 20191, notforinven = true,
											 pos = princess_chest.Bounds.center, target = marker.position + get_random_pos,
											 lootstate = 'dontfindlooter', sprscale = 0.9, skip_text = true })
				table.insert(items, cur_item)
				music_player:PlaySfxOneShot('03_treasure_item_popup_01')
				wait_for_sec(0.3)
			end

			wait_for_sec(1)
			for _, item in ipairs(items) do
				item.ConsumeTarget = user_party.Leader
			end
			wait_for_sec(0.3)
			character_util.remove_anim_and_emotion(user_party_leader)

			self.box_openning = false
			---- 공주 메모
			--self.paper_drop_item = drop_item_util.create_item({ itemid = 20022, notforinven = true,
			--													pos = princess_chest.Bounds.center, target = marker.position + vector(0.5, 0, 0),
			--													lootstate = 'dontfindlooter', sprscale = 0.9 })

			--local paper = get_field_object('princess_paper')
			--paper.Position = marker.position + vector(0.5, 0, 0)
		end)

	end

	return false
end

function local_class:on_interact_event(e)
	local paper = get_field_object('princess_paper')
	if lua_helper.reference_equals(e.Target, paper) then
		sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = 'futurecastle_princess_paper' })
	end

	if lua_helper.reference_equals(e.Target, self.get_favi()) then
		if self.favi_event_state == self.short_event_state.in_control then
			self.favi_event_state = self.short_event_state.scene
			sp_util.play_normal_screenplay(self.talk_with_favi, self)
		end

	elseif lua_helper.reference_equals(e.Target, self.get_shen_talker()) then
		if self.shen_event_state == self.short_event_state.ready then
			sp_util.play_normal_screenplay(self.talk_with_shen_citizen, self)
		end
	end

	return false
end

function local_class:on_item_get_event(e)
	if e.Item.ItemId == 20191 then
		CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName(
				game_string:GetString('futurecastle_princess_gem'), 0)
	end

	return false
end

function local_class:set_event()
	self:set_event_data()

	-- 파비는 down, cross_arm_side 상태로, 바닥에 환자 두 명 누워있고, 치유술사 한 명은 walk4legs 로 환자 돌보는 중
	if self.favi_event_state == self.short_event_state.ready then
		local favi = self.get_favi()
		favi.Position = vector(117, 0, 23)
		favi.Direction = CS.Oak.Direction.Left
		favi:HideWeapon(true)
		favi.SpineController:SetAttachment('[base]weapon2', 'paper_piece')
		character_util.set_anim(favi, { name = 'dualgun_idle' })
	elseif self.favi_event_state == self.short_event_state.none then
		local favi = self.get_favi()
		favi.ActiveState = active_state('disabled')
	else
		local favi = self.get_favi()
		favi.Position = vector(157.5, 0, -90)
		favi.Direction = CS.Oak.Direction.Left
		character_util.set_anim(favi, { name = 'question', loop = false })

		favi.Interactable.Talk = 'futurecastle_2_medical_camp_18'
	end

	if self.tent_event_state == self.short_event_state.ready then
		local helper = self.get_tent_helper(2)
		local firewood = self.get_firewood()

		local dir_table = {
			'right',
			'down',
			'right',
			'left'
		}

		for i = 1, 4 do
			local helper = self.get_tent_helper(i)

			character_util.remove_anim_and_emotion(helper)

			character_util.set_direction(helper, dir_table[i])
		end

		character_util.remove_anim_and_emotion(self.get_tent_thanker())
		character_util.set_emotion(self.get_tent_thanker(), { name = 'smile' })

		firewood.Position = helper.Position + vector(0, 1.2, 0)
		character_util.set_anim(helper, { name = 'hold', loop = false })

		self.get_tent_helper(1).SpineController:SetAttachment('[base]weapon1', 'exp_hammer')
	else
		local helper = self.get_tent_helper(2)
		local firewood = self.get_firewood()

		firewood.Position = helper.Position + vector(0, 0, -0.9)
		self.get_tent_helper(1).SpineController:SetAttachment('[base]weapon1', 'exp_hammer')
	end

	if self.blacksmith_event_state == self.short_event_state.ready then
		local blacksmith = self.get_blacksmith()
		self.origin_shield_item = drop_item_util.create_item({
			itemid = self.origin_shield_id, notforinven = true, lootstate = 'dontfindlooter',
			pos = blacksmith.Position + vector(-1, 0, 0),
			target = blacksmith.Position + vector(-1, 0, 0)
		})
	else

	end

	if self.shen_event_state == self.short_event_state.ready then
		local oldman = self.get_shen_talker()
		character_util.add_listener(oldman, self.cs_controller)
	end

	if self.china_event_state == self.short_event_state.ready then
		local sapa = self.get_china_sapa()
		local jungpa = self.get_china_jungpa()
		character_util.set_position(sapa, vector(114, 0, -41))
		character_util.set_direction(sapa, 'down')
		character_util.set_emotion(sapa, { name = 'attack' })
		character_util.set_position(jungpa, vector(115, 0, -41))
		character_util.set_direction(jungpa, 'left')

		sapa.Interactable.Talk = nil
		jungpa.Interactable.Talk = nil
	end

	if self.snow_event_state == self.short_event_state.ready then
		local snow_kid_boy = self.get_snow_kid_boy()
		local snow_kid_girl = self.get_snow_kid_girl()
		local happy_snowman = self.get_happy_snowman()
		local snow_female = self.get_snow_female()
		local snow_male = self.get_snow_male()
		local snow_mother = self.get_snow_mother()
		local snow_kid_boy2 = self.get_snow_kid_boy2()

		snow_kid_boy.Interactable.Talk = nil
		snow_kid_girl.Interactable.Talk = nil
		snow_mother.Interactable.Talk = nil
		snow_female.Interactable.Talk = nil
		snow_male.Interactable.Talk = nil
		snow_kid_boy2.Interactable.Talk = nil

		character_util.set_anim(happy_snowman, { name = 'idle', loop = false })
		character_util.set_position(snow_kid_boy, happy_snowman.Position + vector(-1, 0, -0.5))
		character_util.set_direction(snow_kid_boy, 'right')
		character_util.set_emotion(snow_kid_boy, { name = 'smile' })
	else
		local snow_kid_boy = self.get_snow_kid_boy()
		character_util.set_position(snow_kid_boy, vector(999, 0, 999))
		character_util.set_anim(happy_snowman, { name = 'idle', loop = false })
	end

	if self.jump_tile_event_state == self.short_event_state.ready then
		self.jump_tile_on = false

		local left1 = get_field_object('left' .. self.jump_tile_name .. 1)
		local left2 = get_field_object('left' .. self.jump_tile_name .. 2)
		local right1 = get_field_object('right' .. self.jump_tile_name .. 1)
		local right2 = get_field_object('right' .. self.jump_tile_name .. 2)

		left1.ActiveState = active_state('disabled')
		left2.ActiveState = active_state('disabled')
		right1.ActiveState = active_state('disabled')
		right2.ActiveState = active_state('disabled')
	else
		self.jump_tile_on = true
	end

	if self.succubus_event_state == self.short_event_state.ready then
		local maya = self.get_maya()
		local talker_1 = self.get_talker_1()
		local talker_2 = self.get_talker_2()
		local talker_3 = self.get_talker_3()

		character_util.set_position(maya, vector(148, 0.5, -3))
		character_util.set_direction(maya, 'left')
		character_util.set_emotion(maya, { name = 'idle' })
		character_util.set_anim(maya, { name = 'idle' })

		character_util.set_position(talker_1, vector(145, 0, -2))
		character_util.set_direction(talker_1, 'right')
		character_util.set_emotion(talker_1, { name = 'idle' })
		character_util.set_anim(talker_1, { name = 'idle' })

		character_util.set_position(talker_2, vector(144, 0, -3))
		character_util.set_direction(talker_2, 'right')
		character_util.set_emotion(talker_2, { name = 'idle' })
		character_util.set_anim(talker_2, { name = 'idle' })

		character_util.set_position(talker_3, vector(145, 0, -4))
		character_util.set_direction(talker_3, 'right')
		character_util.set_emotion(talker_3, { name = 'idle' })
		character_util.set_anim(talker_3, { name = 'idle' })

		maya.Interactable.Talk = nil
		talker_1.Interactable.Talk = nil
		talker_2.Interactable.Talk = nil
		talker_3.Interactable.Talk = nil
	end

	if self.desert_event_state == self.short_event_state.ready then
		local desert_people1 = self.get_desert_1()
		local desert_people2 = self.get_desert_2()
		local desert_people3 = self.get_desert_3()
		local camp_fire = self.get_camp_fire()

		character_util.set_position(desert_people1, vector(57.5, 0, 21.5))
		character_util.set_direction(desert_people1, 'down')
		character_util.set_emotion(desert_people1, { name = 'tired' })
		character_util.set_anim(desert_people1, { name = 'idle' })

		character_util.set_position(desert_people2, vector(56, 0, 20))
		character_util.set_direction(desert_people2, 'right')
		character_util.set_emotion(desert_people2, { name = 'tired' })
		character_util.set_anim(desert_people2, { name = 'seat' })

		character_util.set_position(desert_people3, vector(59, 0, 20))
		character_util.set_direction(desert_people3, 'left')
		character_util.set_emotion(desert_people3, { name = 'tired' })
		character_util.set_anim(desert_people3, { name = 'seat' })

		camp_fire.CombustibleBehaviour = CS.Oak.CampfireCombustibleBehaviour()
		command_util.execute_burn(nil, camp_fire, true)

		desert_people1.Interactable.Talk = nil
		desert_people2.Interactable.Talk = nil
		desert_people3.Interactable.Talk = nil
	end
end

function local_class:set_event_data()
	-- 파비 이벤트 예외처리, 메인 퀘스트 InnerProgress가 10 이상이면 이벤트 발생하지 않음
	self.favi_event_state = self:get_custom_data(self.custom_key.favi_event)

	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	if main_quest == nil or main_quest.InnerProgress >= 10 then
		self.favi_event_state = self.short_event_state.none
	end

	self.tent_event_state = self:get_custom_data(self.custom_key.tent_event)
	self.blacksmith_event_state = self:get_custom_data(self.custom_key.blacksmith_event)
	--self.shen_event_state = self:get_custom_data(self.custom_key.shen_city_event)
	self.shen_event_state = self.short_event_state.ready
	self.china_event_state = self:get_custom_data(self.custom_key.china_event)
	self.snow_event_state = self:get_custom_data(self.custom_key.snow_event)
	self.jump_tile_event_state = self:get_custom_data(self.custom_key.jump_tile_show_event)
	self.succubus_event_state = self:get_custom_data(self.custom_key.succubus_event)
	self.desert_event_state = self:get_custom_data(self.custom_key.desert_event)
end

function local_class:block_event_data()
	self.favi_event_state = self.short_event_state.none
	self.tent_event_state = self.short_event_state.none
	self.blacksmith_event_state = self.short_event_state.none
	self.shen_event_state = self.short_event_state.none
	self.china_event_state = self.short_event_state.none
	self.snow_event_state = self.short_event_state.none
	self.jump_tile_event_state = self.short_event_state.none
	self.succubus_event_state = self.short_event_state.none
	self.desert_event_state = self.short_event_state.none
end

function local_class:get_custom_data(key)
	local is_cleared = stage_progress:GetCustomData(key, false)
	return is_cleared and self.short_event_state.done or self.short_event_state.ready
end

function local_class:progress_custom_data(key)
	stage_progress:SendCustomData(key, true)
end

function local_class:turn_on_jump_tiles()
	local left1 = get_field_object('left' .. self.jump_tile_name .. 1)
	local left2 = get_field_object('left' .. self.jump_tile_name .. 2)
	local right1 = get_field_object('right' .. self.jump_tile_name .. 1)
	local right2 = get_field_object('right' .. self.jump_tile_name .. 2)

	unity_object_pool.GetOrCreate(self.smokescreen_preset):Instantiate(left1.Position)
	unity_object_pool.GetOrCreate(self.smokescreen_preset):Instantiate(right2.Position)

	wait_for_sec(0.2)

	left1.ActiveState = active_state('enabled')
	left2.ActiveState = active_state('enabled')
	right1.ActiveState = active_state('enabled')
	right2.ActiveState = active_state('enabled')

	self:progress_custom_data(self.custom_key.jump_tile_show_event)
	self.jump_tile_event_state = self.short_event_state.done
end

-- 지하 대피소로 들어가면 나오는 이벤트
function local_class:enter_shelter_event()
	-- 배경 제거
	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))

	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({ 0.5, 0.5, 0.5, 1 }), 0)
end

-- 지하 대피소를 벗어나면 나오는 이벤트
function local_class:leave_shelter_event()
	-- 배경 켜기
	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(255, 255, 255, 255), 0))

	-- 틴트 복구
	field:RemoveTint(self.tint_key, 0)
end

-- 파비가 환자들 진찰하는 이벤트
function local_class:hospital_event()
	local favi = self.get_favi()

	local medic_1 = get_character('medic_2')
	local medic_2 = get_character('medic_4')

	character_util.move_to_async(favi, vector(115, 0, favi.Position.z),
			nil, 2, true, true)

	character_util.move_to_async(favi, vector(115, 0, 22),
			nil, 2, true, true)

	character_util.set_direction(favi, 'right')
	character_util.set_anim(favi, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_19' })

	character_util.set_anim(favi, { name = 'question', loop = false })

	character_util.set_anim(medic_1, { name = 'cast' })
	character_util.set_emotion(medic_1, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(medic_1, { key = 'futurecastle_2_medical_camp_20', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, medic_1.Position) })

	character_util.set_anim(favi, { name = 'eat' })

	character_util.remove_anim(medic_1)
	character_util.remove_emotion(medic_1)

	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_21', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, favi.Position) })

	character_util.set_anim(medic_1, { name = 'nod' })

	wait_for_sec(1)

	character_util.set_direction(favi, 'left')
	character_util.remove_anim(favi)

	character_util.set_anim(medic_1, { name = 'eat' })

	character_util.set_anim(medic_2, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(medic_2, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(medic_2, { key = 'futurecastle_2_medical_camp_22', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, medic_2.Position) })

	character_util.remove_anim(medic_2)
	character_util.remove_emotion(medic_2)

	character_util.move_to_async(favi, vector(favi.Position.x, 0, 20.5),
			nil, 2, true, true)

	character_util.move_to_async(favi, vector(114, 0, 20.5),
			nil, 2, true, true)

	character_util.set_anim(favi, { name = 'eat' })

	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_23', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, favi.Position) })

	character_util.move_to_async(favi, vector(114.5, 0, 20.5), nil, 2, true, true)

	character_util.set_direction(favi, 'left')
	character_util.set_anim(favi, { name = 'release', sfx_name = '01_swing_01' })

	character_util.set_anim(medic_2, { name = 'nod' })

	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_24', dialogue = field:IsInSameCameraGrid(user_party.Leader.Position, favi.Position) })

	character_util.set_anim(medic_2, { name = 'eat' })

	character_util.move_to_async(favi, vector(114.5, 0, 23),
			nil, 2, true, true)

	character_util.move_to_async(favi, vector(117, 0, 23),
			nil, 2, true, true)

	character_util.add_listener(favi, self.cs_controller)
	character_util.set_anim(favi, { name = 'dualgun_idle' })
end

-- 파비와 대화하는 이벤트
function local_class:talk_with_favi()
	local favi = self.get_favi()

	speech_bubble_util.remove_bubble(favi)

	character_util.remove_relate_event(favi, self.cs_controller)

	party_util.align_to_target(favi, 'right', 1, 'linear')

	--난민 두 명은 회복 중… 천막 안 병사들에겐 약초를 처방 하면…
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_1', skip = true })

	character_util.remove_emotion(favi)

	--아, 진료 받으러 오셨나요?
	character_util.set_direction(favi, 'right')
	character_util.set_emotion(favi, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_2', skip = true })

	--안으로 들어가서 증상을 말씀하신 후…
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_3', skip = true })

	wait_for_sec(1)

	--…어엇?! (surprise)
	character_util.normal_jump(favi, '01_player_jump_01')
	character_util.set_emotion(favi, { name = 'surprise' })
	character_util.set_anim(favi, { name = 'cast' })
	favi.SpineController:SetAttachment('[base]weapon2', 'empty')
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_4', skip = true })

	-- 혹시 (플레이어 이름) …?
	speech_bubble_util.show_speech_bubble_async(favi, { key = { 'futurecastle_2_medical_camp_6', user.Name }, skip = true })

	character_util.nod_twice(user_party.Leader)

	--이럴 수가! 저 파비예요.
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	character_util.set_emotion(favi, { name = 'smile' })
	character_util.set_anim(favi, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_7', skip = true })
	character_util.remove_anim(favi)

	--누나랑 저 석상이 됐었잖아요. 기억하세요?
	character_util.set_anim(favi, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_8', skip = true })
	character_util.remove_anim(favi)

	-- 선택지 : 기억한다. / 희생의 석상! / 전혀 기억이 안 난다.
	choose_util.play_choose_event({
		{ 'futurecastle_2_medical_camp_9', 'mercy' },
		{ 'futurecastle_2_medical_camp_10', 'intellect' },
		{ 'futurecastle_2_medical_camp_11', 'forced' }
	})

	character_util.set_anim(user_party.Leader, { name = 'release', sfx_name = '01_swing_01' })
	wait_for_sec(1.5)
	character_util.remove_anim(user_party.Leader)

	character_util.remove_anim_and_emotion(favi)

	--후아… 어쨌든 시간이 정말 많이 흘렀네요.
	character_util.set_emotion(favi, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_12', skip = true })
	character_util.remove_emotion(favi)

	--아, 저는 다른 치유술사들과 함께 환자를 돌보고 있어요.
	character_util.set_direction(favi, 'left')
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_13', skip = true })
	character_util.set_direction(favi, 'right')

	--싸우다 부상을 입은 병사나, 병에 걸린 난민들을 치료하고 있죠.
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_14', skip = true })

	local tent_entrance_pos = vector(118.5, 0, 25.5)

	camera_util.move_async(tent_entrance_pos, 1)

	--(오른쪽 의료 텐트 입구에 말풍선 출력, 마치 안에서 소리치는 것처럼)
	--파비님! 환자 깨어났습니다!
	character_util.set_direction(favi, 'up')
	party_util.set_direction('up')

	character_util.normal_jump(favi)

	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble_async(favi,
			{ key = 'futurecastle_2_medical_camp_15', skip = true,
			  world_pos = tent_entrance_pos, bubble_type = 'shout' })

	camera_util.return_to_leader(0.5)

	--앗! 지금은 가봐야 할 것 같네요. 다음에 또 얘기해요.
	character_util.set_direction(favi, 'right')
	party_util.set_direction('left')
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_16', skip = true })

	--참, 소히랑 라비 누나, 크레이그도 꼭 만나 보세요!
	character_util.set_emotion(favi, { name = 'smile' })
	character_util.set_anim(favi, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(favi, { key = 'futurecastle_2_medical_camp_17', skip = true })
	character_util.remove_anim_and_emotion(favi)

	--(말풍선 출력된 텐트 안으로 뛰어가서 사라짐)
	wp_util.move_way_points_async(favi, { waypoints = tent_entrance_pos, speed = 4, run = true, play_sfx = true })

	character_util.set_direction(favi, 'up')
	character_util.spine_set_alpha_fade(favi, 0, 1)

	wait_for_sec(1)

	favi.Interactable.Talk = 'futurecastle_2_medical_camp_18'
	favi.Position = vector(157.5, 0, -90)
	favi.Direction = CS.Oak.Direction.Left
	character_util.set_anim(favi, { name = 'question', loop = false })
	character_util.spine_set_alpha_fade(favi, 1, 0)

	self:progress_custom_data(self.custom_key.favi_event)
	self.favi_event_state = self.short_event_state.done
end

function local_class:tent_routine()
	local helper = {
		self.get_tent_helper(1),
		self.get_tent_helper(2),
		self.get_tent_helper(3),
		self.get_tent_helper(4),
	}
	local thanker = self.get_tent_thanker()
	local firewood = self.get_firewood()
	local stake_pos_1 = vector(89.7, 0.3, -2.7)
	local stake_pos_2 = vector(93.3, 0.3, -2.7)

	local helper_talk_backup = {
		helper[1].Interactable.Talk,
		helper[2].Interactable.Talk,
		helper[3].Interactable.Talk,
		helper[4].Interactable.Talk,
	}
	local thanker_talk_backup = thanker.Interactable.Talk

	for _, v in pairs(helper) do
		v.Interactable.Talk = ''
	end
	thanker.Interactable.Talk = ''

	--(텐트 네 귀퉁이 번갈아가며 또땅또땅 말뚝 박는 시늉)
	character_util.set_direction(helper[1], 'right')
	character_util.set_anim(helper[1], { name = 'twohand_attack' })
	wait_for_sec(0.33)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(stake_pos_1)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(stake_pos_1)
	music_player_util.play_sfx(
			{ sfx_name = '01_hit_dummy_02', parent = helper[1], type_priority = 'event', player_priority = 'npc' })
	wait_for_sec(0.4)
	wait_for_sec(0.33)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(stake_pos_1)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(stake_pos_1)
	music_player_util.play_sfx(
			{ sfx_name = '01_hit_dummy_02', parent = helper[1], type_priority = 'event', player_priority = 'npc' })
	wait_for_sec(0.4)
	character_util.remove_anim(helper[1])

	helper[1].CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	wp_util.move_way_points_async(helper[1],
			{ waypoints = vector(93.5, 0, helper[1].Position.z), speed = 4 })
	helper[1].CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	character_util.set_direction(helper[1], 'left')
	character_util.set_anim(helper[1], { name = 'twohand_attack' })
	wait_for_sec(0.33)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(stake_pos_2)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(stake_pos_2)
	music_player_util.play_sfx(
			{ sfx_name = '01_hit_dummy_02', parent = helper[1], type_priority = 'event', player_priority = 'npc' })
	wait_for_sec(0.4)
	wait_for_sec(0.33)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(stake_pos_2)
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(stake_pos_2)
	music_player_util.play_sfx(
			{ sfx_name = '01_hit_dummy_02', parent = helper[1], type_priority = 'event', player_priority = 'npc' })
	wait_for_sec(0.4)
	character_util.remove_anim(helper[1])

	--이 정도면 텐트가 바람에 날아갈 일은 없을 거야.
	helper[1].SpineController:SetAttachment('[base]weapon1', 'empty')

	character_util.set_direction(helper[1], 'down')
	character_util.set_emotion(helper[1], { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(helper[1], { key = 'futurecastle_2_tent_helper_1' })

	character_util.look_at(thanker, helper[2])

	--(futurecastle_oak 텐트 안에 던져 넣음)
	character_util.set_emotion(helper[2], { name = 'smile' })
	character_util.set_animation_n_times(helper[2], { name = 'throw' })

	local hold_down_dur = 0.2
	local start_pos = firewood.Position
	local target_pos = helper[2].Position + direction_util.to_vector3(helper[2].Direction) * 0.9
	local time_passed = 0

	while time_passed < hold_down_dur do
		local progress = unity_class.mathf.Clamp01(time_passed / hold_down_dur)

		firewood.Position = start_pos * (1 - progress) + target_pos * progress

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end

	firewood.Position = target_pos

	music_player_util.play_sfx(
			{ sfx_name = '01_hit_dummy_02', parent = firewood, type_priority = 'event', player_priority = 'npc' })

	wait_for_sec(0.5)

	--내 땔감을 좀 나눠줄게요.
	character_util.set_direction(helper[2], 'left')
	speech_bubble_util.show_speech_bubble_async(helper[2], { key = 'futurecastle_2_tent_helper_2' })
	character_util.remove_anim(helper[2])

	character_util.look_at(thanker, helper[3])

	character_util.set_emotion(helper[3], { name = 'smile' })
	character_util.set_animation_n_times(helper[3], { name = 'throw' })
	music_player_util.play_sfx(
			{ sfx_name = '01_throw_01', parent = helper[3], type_priority = 'event', player_priority = 'npc' })

	local apple_item = drop_item_util.create_item({
		itemid = self.apple_id, notforinven = true,
		pos = helper[3].Position, target = thanker.Position + vector(-0.2, 0, 0.2),
		lootstate = 'dontfindlooter'
	})

	wait_for_sec(1)

	unity_object_pool.GetOrCreate('FX_get'):Instantiate(apple_item.Position)
	music_player_util.play_sfx({ sfx_name = '03_get_drop_item_01', play_pos = thanker.Position })
	apple_item:ConsumeComplete()
	CS.Oak.FieldUIFloatingText.Get(thanker):JustPrintItemName(game_string:GetString('apple'), 0)

	--(apple 텐트 안에 던져 넣음)
	--당장 먹을 것도 없을 텐데, 이걸로 허기라도 달래세요.
	speech_bubble_util.show_speech_bubble_async(helper[3], { key = 'futurecastle_2_tent_helper_3' })

	character_util.look_at(thanker, helper[4])

	--(water  텐트 안에 던져 넣음)
	character_util.set_emotion(helper[4], { name = 'smile' })
	character_util.set_animation_n_times(helper[4], { name = 'throw' })
	music_player_util.play_sfx(
			{ sfx_name = '01_throw_01', parent = helper[1], type_priority = 'event', player_priority = 'npc' })

	local water_item = drop_item_util.create_item({
		itemid = self.water_id, notforinven = true,
		pos = helper[4].Position, target = thanker.Position + vector(0.2, 0, 0),
		lootstate = 'dontfindlooter'
	})

	wait_for_sec(1)

	unity_object_pool.GetOrCreate('FX_get'):Instantiate(water_item.Position)
	music_player_util.play_sfx({ sfx_name = '03_get_drop_item_01', play_pos = thanker.Position })
	water_item:ConsumeComplete()
	CS.Oak.FieldUIFloatingText.Get(thanker):JustPrintItemName(game_string:GetString('desert_water'), 0)

	--당분간은 이 물로 생활할 수 있을 거요.
	speech_bubble_util.show_speech_bubble_async(helper[4], { key = 'futurecastle_2_tent_helper_4' })

	--다들 힘드실 텐데 이렇게 도와주시다니…
	character_util.set_direction(thanker, 'right')
	character_util.set_emotion(thanker, { name = 'tired' })
	character_util.set_anim(thanker, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(thanker, { key = 'futurecastle_2_tent_helper_5' })

	--정말 감사합니다. 정말 고마워요! (폴짝폴짝)
	character_util.set_anim(thanker, { name = 'victory_extra' })
	character_util.set_emotion(thanker, { name = 'smile' })
	music_player_util.play_sfx(
			{ sfx_name = '03_dialogue_positive_01', parent = thanker,
			  type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(thanker, { key = 'futurecastle_2_tent_helper_6' })

	character_util.set_direction(helper[1], 'left')
	character_util.set_anim(helper[1], { name = 'twohand_attack' })
	self.get_tent_helper(1).SpineController:SetAttachment('[base]weapon1', 'exp_hammer')

	character_util.remove_emotion(helper[1])
	character_util.remove_emotion(helper[3])

	for k, v in pairs(helper) do
		v.Interactable.Talk = helper_talk_backup[k]
	end
	thanker.Interactable.Talk = thanker_talk_backup

	self:progress_custom_data(self.custom_key.tent_event)
	self.tent_event_state = self.short_event_state.done
end

function local_class:blacksmith_routine()
	local blacksmith = self.get_blacksmith()
	local soldier_1 = self.get_blacksmith_soldier_1()
	local soldier_2 = self.get_blacksmith_soldier_2()

	--정말 확실히 강화되는 거 맞죠?
	character_util.set_anim(soldier_1, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(soldier_1, { key = 'futurecastle_2_blacksmith_1' })
	character_util.remove_anim(soldier_1)

	--그럼 그럼, 나만 믿으라고!
	music_player_util.play_sfx({ sfx_name = '01_blacksmith_shout_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(blacksmith, { name = 'upgrade', loop = false })
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_2' })
	character_util.remove_anim(blacksmith)

	--대장장이 모션 시작되면 무기에서 실제 강화 또는 진화 연출, 연출 끝나면 병사 쪽으로 칼이 하나 튀어나감 gold_hilt_sword
	for i = 1, 4 do
		music_player_util.play_sfx({ sfx_name = '02_axe_slash_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(blacksmith, { name = 'hammer' })
		wait_for_sec(0.18)
		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
		unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
		wait_for_sec(0.18)
		character_util.remove_anim(blacksmith)
	end

	music_player_util.play_sfx({ sfx_name = '02_wolf_boss_bomb_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(blacksmith, { name = 'hammer' })
	wait_for_sec(0.18)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
	self.get_fx_dead():Instantiate(blacksmith.Position + vector(-1, 0, 0))

	self.sword_item = drop_item_util.create_item({
		itemid = self.sword_id, notforinven = true,
		pos = blacksmith.Position + vector(-1, 0, 0), target = blacksmith.Position + vector(-1, 0, 0), lootstate = 'dontfindlooter'
	})

	if self.origin_shield_item ~= nil then
		self.origin_shield_item:ConsumeComplete()
		self.origin_shield_item = nil
	end

	wait_for_sec(0.18)
	character_util.remove_anim(blacksmith)

	wait_for_sec(1)

	--어때? 이제 뭐든지 베어버릴 수 있겠지?
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(blacksmith, { name = 'smile' })
	character_util.set_anim(blacksmith, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_3' })
	character_util.remove_anim(blacksmith)

	wait_for_sec(1)

	character_util.set_emotion(soldier_1, { name = 'mad' })

	wait_for_sec(1)

	--뭐야?! 내가 맡겼던 건 방패잖아요!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = soldier_1, type_priority = 'event', player_priority = 'npc' })
	character_util.normal_jump(soldier_1)
	speech_bubble_util.show_speech_bubble_async(soldier_1, { key = 'futurecastle_2_blacksmith_4' })

	--아이~ 이 친구가 아직 무작위 진화의 묘미를 모르네!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(blacksmith, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_5' })
	character_util.remove_anim(blacksmith)

	--묘미는 무슨 묘미! 지금 칼만 열다섯 갠데!!!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = soldier_1, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(soldier_1, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(soldier_1, { key = 'futurecastle_2_blacksmith_6' })
	character_util.remove_anim_and_emotion(soldier_1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = soldier_1, type_priority = 'event', player_priority = 'npc' })
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true, parent = soldier_1, type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(soldier_1, { name = 'cry' })
	character_util.set_anim(soldier_1, { name = 'eat' })
	wait_for_sec(1.5)

	eat_sfx:Stop()
	character_util.remove_anim(soldier_1)
	if self.sword_item ~= nil then
		self.sword_item:ConsumeComplete()
		self.sword_item = nil
	end

	wp_util.move_way_points(soldier_1, { waypoints = soldier_1.Position + vector(0, 0, -1),
										 speed = 2, callback = function()
			soldier_1.Direction = CS.Oak.Direction.Left
			character_util.set_anim(soldier_1, { name = 'seat' })
		end })

	wp_util.move_way_points_async(soldier_2, { waypoints = soldier_2.Position + vector(1, 0, 0), speed = 2 })

	--어어… 전 괜찮으니까, 맡긴 거 다시 돌려주시겠어요?
	character_util.set_emotion(soldier_2, { name = 'tired' })
	character_util.set_anim(soldier_2, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(soldier_2, { key = 'futurecastle_2_blacksmith_7' })

	music_player_util.play_sfx({ sfx_name = '01_air_spin_01', play_pos = blacksmith.Position + vector(-1, 0, 0), type_priority = 'event', player_priority = 'default' })
	self.origin_gun_item = drop_item_util.create_item({
		itemid = self.origin_gun_id, notforinven = true,
		pos = blacksmith.Position, target = blacksmith.Position + vector(-1, 0, 0), lootstate = 'dontfindlooter'
	})

	--응, 뭐라고? 시끄러워서 소리가 잘 안 들리네?
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_8' })

	--(대장장이 모션 시작되면 무기에서 실제 강화 또는 진화 연출, 병사는 scared 표정. 연출 끝나면 병사 쪽으로 방패가 하나 튀어나감
	character_util.set_emotion(soldier_2, { name = 'scared' })

	for i = 1, 4 do
		music_player_util.play_sfx({ sfx_name = '02_axe_slash_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
		character_util.set_anim(blacksmith, { name = 'hammer' })
		wait_for_sec(0.18)
		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
		unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
		wait_for_sec(0.18)
		character_util.remove_anim(blacksmith)
	end

	music_player_util.play_sfx({ sfx_name = '02_wolf_boss_bomb_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(blacksmith, { name = 'hammer' })
	wait_for_sec(0.18)
	unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
	unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(blacksmith.Position + vector(-1, 0, 0))
	self.get_fx_dead():Instantiate(blacksmith.Position + vector(-1, 0, 0))

	if self.origin_gun_item ~= nil then
		self.origin_gun_item:ConsumeComplete()
		self.origin_gun_item = nil
	end
	self.shield_item = drop_item_util.create_item({
		itemid = self.shield_id, notforinven = true,
		pos = blacksmith.Position + vector(-1, 0, 0), target = blacksmith.Position + vector(-1, 0, 0), lootstate = 'dontfindlooter'
	})

	wait_for_sec(0.18)
	character_util.remove_anim(blacksmith)

	wait_for_sec(1)

	character_util.set_emotion(soldier_2, { name = 'cry' })

	--어때? 놀랍도록 진부해서 오히려 신선한 방패지?
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.normal_jump(blacksmith)
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_9' })

	--거짓말이야! 이건 거짓말이야! 내 갑옷! 내 갑옷 돌려줘!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = soldier_2, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(soldier_2, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(soldier_2, { key = 'futurecastle_2_blacksmith_10' })
	character_util.remove_anim(soldier_2)
	character_util.set_anim(soldier_2, { name = 'seat' })

	--네 갑옷은 영원히 네 안에서 살아 숨쉴 거란다.
	music_player_util.play_sfx({ sfx_name = '01_coop_mvp_01', parent = blacksmith, type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(blacksmith, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(blacksmith, { key = 'futurecastle_2_blacksmith_11' })
	character_util.remove_anim(blacksmith)

	self:progress_custom_data(self.custom_key.blacksmith_event)
	self.blacksmith_event_state = self.short_event_state.done
end

function local_class:stop_blacksmith_routine()
	local soldier_1 = self.get_blacksmith_soldier_1()
	local soldier_2 = self.get_blacksmith_soldier_2()
	local blacksmith = self.get_blacksmith()

	character_util.stop(soldier_1)
	character_util.stop(soldier_2)

	character_util.remove_anim_and_emotion(soldier_1)
	character_util.remove_anim_and_emotion(soldier_2)
	character_util.remove_anim_and_emotion(blacksmith)

	if self.origin_shield_item ~= nil then
		self.origin_shield_item:ConsumeComplete()
		self.origin_shield_item = nil
	end

	if self.sword_item ~= nil then
		self.sword_item:ConsumeComplete()
		self.sword_item = nil
	end

	if self.origin_gun_item ~= nil then
		self.origin_gun_item:ConsumeComplete()
		self.origin_gun_item = nil
	end

	if self.shield_item ~= nil then
		self.shield_item:ConsumeComplete()
		self.shield_item = nil
	end
end

function local_class:talk_with_shen_citizen()
	local oldman = self.get_shen_talker()

	party_util.align_to_target(oldman, 'down', 1, 'arc')

	--습관처럼 부유성 절벽 밑을 내려다본다네.
	character_util.set_direction(oldman, 'right')
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_1', skip = true })

	--구름 사이로 센의 높다란 산봉우리들이 보이지 않을까 해서 말일세.
	character_util.set_direction(oldman, 'down')
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_2', skip = true })

	--센은 어떻게 됐나요? / 산봉우리를 봤나요? / 센에 사람들이 있나요? / 하나도 안궁금함
	local result = choose_util.play_choose_event({
		{ 'futurecastle_2_shen_citizen_3', 'mercy' },
		{ 'futurecastle_2_shen_citizen_4', 'intellect' },
		{ 'futurecastle_2_shen_citizen_5', 'normal' },
		{ 'futurecastle_2_shen_citizen_5_1', 'brutal' },
	})

	if result == 4 then
		return
	end

	--이젠 하늘을 나는 새만이 센에 내려앉겠지.
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_6', skip = true })

	--? (question)
	character_util.show_emoticon_async(user_party.Leader, nil, 'question')

	--인베이더들은 센 시를 서로 잇는 구름다리를 전부 끊어놓고는…
	character_util.set_anim(oldman, { name = 'cast' })
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_7', skip = true })

	--마을들을 모조리 불살라버렸네.
	character_util.set_anim(oldman, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_8', skip = true })
	character_util.remove_anim(oldman)

	--그 까마득한 골짜기 밑으로 수많은 사람들이 몸을 던졌지.
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_9', skip = true })

	--선산권 수련자들은? / 항아리 신선은? / 용의 발톱단은?
	choose_util.play_choose_event({
		{ 'futurecastle_2_shen_citizen_10', 'mercy' },
		{ 'futurecastle_2_shen_citizen_11', 'intellect' },
		{ 'futurecastle_2_shen_citizen_12', 'brutal' },
	})

	character_util.set_anim(user_party.Leader, { name = 'release', sfx_name = '01_swing_01' })
	wait_for_sec(1.5)
	character_util.remove_anim(user_party.Leader)

	--신선과 무림 고수들과 의적단이라니… 마치 전설 같은 이야기로군.
	character_util.set_direction(oldman, 'right')
	character_util.set_anim(oldman, { name = 'cross_arm' })
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_13', skip = true })
	character_util.remove_anim(oldman)

	--하지만 젊은이. 내 하나만 일러주지.
	character_util.set_direction(oldman, 'down')
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_14', skip = true })

	--그 전설들은… 센에 실재했다네.
	character_util.set_anim(oldman, { name = 'cast2' })
	speech_bubble_util.show_speech_bubble_async(oldman, { key = 'futurecastle_2_shen_citizen_15', skip = true })
	character_util.remove_anim(oldman)

	--self:progress_custom_data(self.custom_key.shen_city_event)
	--self.shen_event_state = self.short_event_state.done
end

function local_class:china_tent_event()
	local sapa = self.get_china_sapa()
	local jungpa = self.get_china_jungpa()

	-- 키야압!
	character_util.set_emotion(sapa, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(sapa, { key = 'futurecastle_2_china_tent_1' })

	character_util.set_animation_n_times_async(sapa, { name = 'twohand_attack4', count = 1 })
	wait_for_sec(0.5)
	character_util.remove_emotion(sapa)
	character_util.set_direction(sapa, 'right')
	character_util.set_emotion(jungpa, { name = 'smile' })

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	-- 어때? 적을 기습할 때 안성맞춤인 사파의 암습술!
	speech_bubble_util.show_speech_bubble_async(sapa, { key = 'futurecastle_2_china_tent_2' })

	character_util.set_animation_n_times_async(jungpa, { name = 'clap', count = 3 })
	character_util.set_direction(jungpa, 'down')
	character_util.set_emotion(jungpa, { name = 'attack' })
	character_util.set_animation_n_times_async(jungpa, { name = 'twohand_attack4', count = 1 })
	wait_for_sec(0.5)

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	character_util.set_direction(jungpa, 'left')
	character_util.set_emotion(jungpa, { name = 'smile' })

	-- 오오, 괜찮은데? 동작에 군더더기가 없고 효율적이야. 스피드도 빠른 편이고.
	character_util.set_animation_n_times(sapa, { name = 'nod', count = 2 })
	speech_bubble_util.show_speech_bubble_async(jungpa, { key = 'futurecastle_2_china_tent_3' })
	character_util.remove_emotion(jungpa)

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	-- 으음… 그럼 나는 정파의 연속기 하나 보여줄게.
	speech_bubble_util.show_speech_bubble_async(jungpa, { key = 'futurecastle_2_china_tent_4' })

	character_util.set_direction(jungpa, 'down')
	character_util.set_emotion(jungpa, { name = 'attack' })
	character_util.set_animation_n_times_async(jungpa, { name = 'gauntlet_combo_attack2', count = 1 })
	wait_for_sec(0.5)

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	character_util.set_direction(jungpa, 'left')
	character_util.remove_emotion(jungpa)
	character_util.set_animation_n_times_async(sapa, { name = 'clap', count = 3 })

	-- 탓! 탓! 헛! 키얍!
	character_util.set_direction(sapa, 'down')
	character_util.set_emotion(sapa, { name = 'attack' })
	speech_bubble_util.show_speech_bubble(sapa,
			{ key = 'futurecastle_2_china_tent_5', type_speed = 0.01, bubble_direction = 'lt' })
	character_util.set_animation_n_times_async(sapa, { name = 'gauntlet_combo_attack2', count = 1 })
	wait_for_sec(1)

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	-- 역시 기본기가 있으니 빨리 배우는 구나?
	character_util.set_direction(sapa, 'right')
	character_util.remove_emotion(sapa)
	wait_for_sec(0.5)
	speech_bubble_util.show_speech_bubble_async(jungpa, { key = 'futurecastle_2_china_tent_6' })

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	-- 하하하, 사파와 정파는 사실 뿌리가 같으니까.
	speech_bubble_util.show_speech_bubble_async(sapa, { key = 'futurecastle_2_china_tent_7' })

	character_util.set_emotion(jungpa, { name = 'smile' })
	character_util.set_anim(jungpa, { name = 'salute_china', loop = false })
	character_util.set_emotion(sapa, { name = 'smile' })
	character_util.set_anim(sapa, { name = 'salute_china', loop = false })

	wait_for_sec(1)

	-- 존을 나갔는지 체크하여 나갔으면 코루틴 다시 돌 수 있도록 상태 바꿔줌.
	if not self.in_china_tent_zone then
		self.china_event_state = self.short_event_state.ready
		return
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(sapa)
		character_util.move_to_async(sapa, vector(110.5, 0, -41), nil, 4, true, true)
		character_util.move_to_async(sapa, vector(110.5, 0, -38.95), nil, 4, true, true)
		character_util.spine_set_alpha_fade(sapa, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_position(sapa, vector(999, 0, 999))
	end, sapa))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(jungpa)
		character_util.move_to_async(jungpa, vector(123, 0, -41), nil, 4, true, true)
		character_util.move_to_async(jungpa, vector(123, 0, -38.95), nil, 4, true, true)
		character_util.spine_set_alpha_fade(jungpa, 0, 0.5)
		wait_for_sec(0.5)
		character_util.set_position(jungpa, vector(999, 0, 999))
	end, jungpa))

	self:progress_custom_data(self.custom_key.china_event)
	self.china_event_state = self.short_event_state.done
end

function local_class:snow_tent_event()
	local snow_kid_boy = self.get_snow_kid_boy()
	local snow_kid_girl = self.get_snow_kid_girl()
	local snow_female = self.get_snow_female()
	local snow_male = self.get_snow_male()
	local snow_mother = self.get_snow_mother()
	local snow_kid_boy2 = self.get_snow_kid_boy2()

	snow_kid_boy.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	snow_kid_girl.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	snow_female.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	snow_male.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	snow_mother.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	snow_kid_boy2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	-- 다들 이것 좀 보세요! 제가 눈사람 만들었어요!
	character_util.set_direction(snow_kid_boy, 'down')
	character_util.set_anim(snow_male, { name = 'idle' })
	speech_bubble_util.show_speech_bubble_async(snow_kid_boy, { key = 'futurecastle_2_snow_tent_1' })
	character_util.set_direction(snow_kid_boy, 'right')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_male)
		character_util.set_anim(snow_male, { name = 'walk' })
		character_util.move_to_async(snow_male, vector(118.65, 0, -60.5), nil, 4, true)
		character_util.move_to_async(snow_male, vector(116, 0, -60.5), nil, 4, true)
		character_util.set_anim(snow_male, { name = 'idle' })
	end, snow_male))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_female)
		character_util.set_anim(snow_female, { name = 'walk' })
		character_util.move_to_async(snow_female, vector(116.59, 0, -67.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(119, 0, -67.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(119, 0, -61.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(116, 0, -61.5), nil, 4, true)
		character_util.set_anim(snow_female, { name = 'idle' })
	end, snow_female))

	wait_for_sec(0.5)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_kid_girl)
		character_util.set_anim(snow_kid_girl, { name = 'walk' })
		character_util.move_to_async(snow_kid_girl, vector(112.5, 0, -62.93), nil, 4, true)
		character_util.move_to_async(snow_kid_girl, vector(112.5, 0, -60.5), nil, 4, true)
		character_util.move_to_async(snow_kid_girl, vector(113.5, 0, -60.5), nil, 4, true)
		character_util.set_direction(snow_kid_girl, 'right')
		character_util.set_emotion(snow_kid_girl, { name = 'smile' })
		character_util.set_anim(snow_kid_girl, { name = 'idle' })
	end, snow_kid_girl))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_kid_boy2)
		character_util.set_anim(snow_kid_boy2, { name = 'walk' })
		character_util.move_to_async(snow_kid_boy2, vector(111.5, 0, -62.05), nil, 4, true)
		character_util.move_to_async(snow_kid_boy2, vector(111.5, 0, -60.5), nil, 4, true)
		character_util.move_to_async(snow_kid_boy2, vector(112.5, 0, -60.5), nil, 4, true)
		character_util.set_direction(snow_kid_boy2, 'right')
		character_util.set_emotion(snow_kid_boy2, { name = 'smile' })
		character_util.set_anim(snow_kid_boy2, { name = 'idle' })
	end, snow_kid_boy2))

	wait_for_sec(1)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_mother)
		character_util.move_waypoint_async(snow_mother, { vector(94.5, 0, snow_mother.Position.z), vector(94.5, 0, -111) }, 4, false)

		snow_mother.SpineController.AlwaysUpdateSpine = true
		character_util.spine_set_alpha_fade(snow_mother, 0, 0.75)
		wait_for_sec(0.75)

		coroutine.yield()

		character_util.set_position(snow_mother, vector(122.5, 0, -60.5))
		character_util.set_direction(snow_mother, 'down')
		character_util.spine_set_alpha_fade(snow_mother, 1, 1)
		wait_for_sec(1)

		snow_mother.SpineController.AlwaysUpdateSpine = false
		character_util.move_to_async(snow_mother, vector(122.5, 0, -63), nil, 4, true, true)
		character_util.move_to_async(snow_mother, vector(115, 0, -63), nil, 4, true, true)
	end, snow_mother))

	-- 우와! 진짜 눈사람이잖아? 저거 보니까 옛날 생각 난다.
	character_util.set_emotion(snow_male, { name = 'surprise' })
	speech_bubble_util.show_speech_bubble_async(snow_male, { key = 'futurecastle_2_snow_tent_2' })
	character_util.remove_emotion(snow_male)

	-- 눈사람 하나로 이렇게 설산 분위기가 날 줄이야. 그립다…
	speech_bubble_util.show_speech_bubble_async(snow_female, { key = 'futurecastle_2_snow_tent_3' })

	-- 엄마! 엄마! 제가 눈사람 만든 것 좀 봐요!
	speech_bubble_util.show_speech_bubble_async(snow_kid_boy, { key = 'futurecastle_2_snow_tent_4' })

	character_util.set_emotion(snow_mother, { name = 'confused' })
	-- 혹시 너…  천막 앞에 모아둔 이불 솜 뜯어서… 이거… 만든 거니?
	speech_bubble_util.show_speech_bubble_async(snow_mother, { key = 'futurecastle_2_snow_tent_5' })

	character_util.set_emotion(snow_kid_boy, { name = 'tired' })
	character_util.set_direction(snow_kid_boy, 'up')
	wait_for_sec(0.5)
	character_util.look_at(snow_kid_boy, snow_mother)
	wait_for_sec(0.5)
	character_util.set_direction(snow_kid_boy, 'up')
	wait_for_sec(1)
	character_util.look_at(snow_kid_boy, snow_mother)

	-- …네!
	speech_bubble_util.show_speech_bubble_async(snow_kid_boy, { key = 'futurecastle_2_snow_tent_6' })

	-- 어휴, 이 녀석! 그거 추워서 덜덜 떠는 사막 난민들 주려고 모아놓은 거란 말야!
	character_util.set_emotion(snow_mother, { name = 'mad' })
	character_util.set_anim(snow_mother, { name = 'release' })
	character_util.set_emotion(snow_kid_girl, { name = 'tired' })
	character_util.set_emotion(snow_kid_boy, { name = 'scared' })
	character_util.normal_jump(snow_kid_boy)
	character_util.shake(snow_kid_boy, 0.02, 99)
	speech_bubble_util.show_speech_bubble_async(snow_mother, { key = 'futurecastle_2_snow_tent_7' })
	character_util.remove_anim(snow_mother)

	character_util.move_to_async(snow_mother, vector(113.5, 0, -63), nil, 4, true, true)
	character_util.move_to_async(snow_mother, vector(113.5, 0, -62.5), nil, 4, true, true)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_kid_boy)
		character_util.move_to_async(snow_kid_boy, vector(113.5, 0, -63), nil, 4, true, true)
		character_util.move_to_async(snow_kid_boy, vector(122.5, 0, -63), nil, 4, true, true)
		character_util.move_to(snow_kid_boy, vector(122.5, 0, -60.5), nil, 4, true, true)
		character_util.spine_set_alpha_fade(snow_kid_boy, 0, 0.75)
		wait_for_sec(0.75)
		character_util.set_position(snow_kid_boy, vector(999, 0, 999))
	end, snow_kid_boy))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_mother)
		character_util.move_to_async(snow_mother, vector(113.5, 0, -63), nil, 4, true, true)
		character_util.move_to_async(snow_mother, vector(122.5, 0, -63), nil, 4, true, true)
		character_util.move_to(snow_mother, vector(122.5, 0, -60.5), nil, 4, true, true)
		character_util.spine_set_alpha_fade(snow_mother, 0, 0.75)
		wait_for_sec(0.75)
		character_util.set_position(snow_mother, vector(999, 0, 999))
	end, snow_mother))

	wait_for_sec(1)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_kid_boy2)
		character_util.set_anim(snow_kid_boy2, { name = 'walk' })
		character_util.move_to_async(snow_kid_boy2, vector(105.5, 0, -60.5), nil, 4, true)
		character_util.move_to_async(snow_kid_boy2, vector(105.5, 0, -62.05), nil, 4, true)
		character_util.set_direction(snow_kid_boy2, 'down')
		character_util.set_emotion(snow_kid_boy2, { name = 'awesome' })
		character_util.set_anim(snow_kid_boy2, { name = 'idle' })
	end, snow_kid_boy2))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_kid_girl)
		character_util.set_anim(snow_kid_girl, { name = 'walk' })
		character_util.move_to_async(snow_kid_girl, vector(112.5, 0, -63), nil, 4, true)
		character_util.move_to_async(snow_kid_girl, vector(105.5, 0, -63), nil, 4, true)
		character_util.set_direction(snow_kid_girl, 'up')
		character_util.set_anim(snow_kid_girl, { name = 'idle' })
	end, snow_kid_girl))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_male)
		character_util.set_anim(snow_male, { name = 'walk' })
		character_util.move_to_async(snow_male, vector(118.65, 0, -60.5), nil, 4, true)
		character_util.move_to_async(snow_male, vector(118.65, 0, -59.5), nil, 4, true)
		character_util.set_direction(snow_male, 'down')
		character_util.set_anim(snow_male, { name = 'idle' })
	end, snow_male))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(snow_female)
		character_util.set_anim(snow_female, { name = 'walk' })
		character_util.move_to_async(snow_female, vector(116, 0, -61.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(119, 0, -61.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(119, 0, -67.5), nil, 4, true)
		character_util.move_to_async(snow_female, vector(116.59, 0, -67.5), nil, 4, true)
		character_util.set_direction(snow_female, 'left')
		character_util.set_anim(snow_female, { name = 'idle' })
	end, snow_female))

	wait_for_sec(2.4)

	snow_kid_boy.Interactable.Talk = 'futurecastle_1_2_innuit_camp_5'
	snow_kid_girl.Interactable.Talk = 'futurecastle_1_2_innuit_camp_5'
	snow_mother.Interactable.Talk = 'futurecastle_1_2_innuit_camp_7'
	snow_female.Interactable.Talk = 'futurecastle_1_2_innuit_camp_4'
	snow_male.Interactable.Talk = 'futurecastle_1_2_innuit_camp_2'
	snow_kid_boy2.Interactable.Talk = 'futurecastle_1_2_innuit_camp_6'

	snow_kid_boy.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	snow_kid_girl.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	snow_female.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	snow_male.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	snow_mother.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	snow_kid_boy2.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	self:progress_custom_data(self.custom_key.snow_event)
	self.snow_event_state = self.short_event_state.done
end

function local_class:succubus_tent_event()
	local maya = self.get_maya()
	local talker_1 = self.get_talker_1()
	local talker_2 = self.get_talker_2()
	local talker_3 = self.get_talker_3()

	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_1' })

	character_util.set_emotion(talker_1, { name = 'attack' })
	character_util.set_emotion(talker_2, { name = 'attack' })
	character_util.set_emotion(talker_3, { name = 'attack' })
	speech_bubble_util.show_speech_bubble(talker_1, { key = 'futurecastle_2_succubus_teaching_2', bubble_type = 'shout' })
	speech_bubble_util.show_speech_bubble(talker_2, { key = 'futurecastle_2_succubus_teaching_2', bubble_type = 'shout' })
	speech_bubble_util.show_speech_bubble_async(talker_3, { key = 'futurecastle_2_succubus_teaching_2', bubble_type = 'shout' })

	speech_bubble_util.remove_bubble(talker_1)
	speech_bubble_util.remove_bubble(talker_2)
	speech_bubble_util.remove_bubble(talker_3)

	character_util.remove_emotion(talker_1)
	character_util.remove_emotion(talker_2)
	character_util.remove_emotion(talker_3)

	character_util.set_emotion(maya, { name = 'smile' })
	character_util.set_animation_n_times(maya, { name = 'nod', count = 2, upper = true })
	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_3' })
	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_4' })
	character_util.remove_emotion(maya)

	-- 어떤 소재를 택하죠? 트라우마를 직시하게 하나요? 아님 거리가 멀게?
	speech_bubble_util.show_speech_bubble_async(talker_1, { key = 'futurecastle_2_succubus_teaching_5' })

	character_util.jump(maya, 0.5, 0.3)
	character_util.set_anim(maya, { name = 'idle' })
	character_util.move_to_async(maya, maya.Position + vector(-1, -0.5, 0), 0.3)

	-- 좋은 질문! 너무 노골적이어서도, 너무 거리가 멀어서도 안 돼.
	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_6' })
	-- 어려운 문제지? 이 때 우리가 적극 활용해야 할 게, 바로 메타포야.
	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_7' })

	character_util.set_anim_and_emotion(talker_1, { name = 'cross_arm' }, { name = 'tired' })
	character_util.set_anim_and_emotion(talker_2, { name = 'cross_arm' }, { name = 'tired' })
	character_util.set_anim_and_emotion(talker_3, { name = 'cross_arm' }, { name = 'tired' })

	character_util.show_emoticon(talker_1, nil, 'question')
	character_util.show_emoticon(talker_2, nil, 'question')
	character_util.show_emoticon_async(talker_3, nil, 'question')

	character_util.remove_anim_and_emotion(talker_1)
	character_util.remove_anim_and_emotion(talker_2)
	character_util.remove_anim_and_emotion(talker_3)

	-- 자, 메타포에 대해선 내일 집중적으로 다룰 테니까, 다들 늦지 않도록 해!
	character_util.set_anim_and_emotion(maya, { name = 'clap' }, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(maya, { key = 'futurecastle_2_succubus_teaching_8' })

	character_util.remove_anim_and_emotion(maya)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(maya)
		character_util.move_to_async(maya, vector(147, 0, 1.75), nil, 4, true, true)
		character_util.move_to_async(maya, vector(148, 0, 1.75), nil, 4, true, true)
		character_util.set_direction(maya, 'left')
		character_util.set_emotion(maya, { name = 'smile' })
	end, maya))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(talker_1)
		character_util.move_to_async(talker_1, vector(142.5, 0, -2), nil, 4, true, true)
		character_util.move_to_async(talker_1, vector(142.5, 0, 1.75), nil, 4, true, true)
		character_util.set_direction(talker_1, 'down')
		character_util.set_emotion(talker_1, { name = 'smile' })
	end, talker_1))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(talker_2)
		character_util.move_to_async(talker_2, vector(143, 0, -3), nil, 4, true, true)
		character_util.move_to_async(talker_2, vector(143, 0, -5), nil, 4, true, true)
		character_util.move_to_async(talker_2, vector(140, 0, -5), nil, 4, true, true)
		character_util.move_to_async(talker_2, vector(140, 0, -8.45), nil, 4, true, true)
		character_util.move_to_async(talker_2, vector(138.5, 0, -8.45), nil, 4, true, true)
		character_util.set_direction(talker_2, 'left')
		character_util.set_emotion(talker_2, { name = 'blush' })
	end, talker_2))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(talker_3)
		character_util.move_to_async(talker_3, vector(142, 0, -4), nil, 4, true, true)
		character_util.move_to_async(talker_3, vector(142, 0, -6), nil, 4, true, true)
		character_util.set_direction(talker_3, 'down')
		character_util.set_emotion(talker_3, { name = 'tired' })
	end, talker_3))

	wait_for_sec(2.5)

	maya.Interactable.Talk = 'futurecastle_1_2_succubus_camp_5'
	talker_1.Interactable.Talk = 'futurecastle_1_2_succubus_camp_6'
	talker_2.Interactable.Talk = 'futurecastle_1_2_succubus_camp_8'
	talker_3.Interactable.Talk = 'futurecastle_1_2_succubus_camp_7'

	self:progress_custom_data(self.custom_key.succubus_event)
	self.succubus_event_state = self.short_event_state.done
end

function local_class:desert_tent_event()
	local desert_people1 = self.get_desert_1()
	local desert_people2 = self.get_desert_2()
	local desert_people3 = self.get_desert_3()
	local camp_fire = self.get_camp_fire()

	-- 으으으~ 모닥불 옆을 떠날 수가 없네… 사막의 뜨거운 태양이 그립다…
	character_util.shake(desert_people1, 0.02, 2)
	speech_bubble_util.show_speech_bubble_async(desert_people1, { key = 'futurecastle_2_desert_fire_1' })

	-- 비 내린 다음에는 천막 안이 너무 썰렁해서 못 견디겠어.
	character_util.shake(desert_people2, 0.02, 2)
	speech_bubble_util.show_speech_bubble_async(desert_people2, { key = 'futurecastle_2_desert_fire_2' })

	-- 이누이트들이 두꺼운 이불을 준다던데, 그게 있으면 좀 나아질까…?
	character_util.shake(desert_people3, 0.02, 2)
	speech_bubble_util.show_speech_bubble_async(desert_people3, { key = 'futurecastle_2_desert_fire_3' })

	command_util.execute_extinguish(nil, camp_fire)
	camp_fire.CombustibleBehaviour = CS.Oak.NonCombustibleBehaviour.Instance

	character_util.set_emotion(desert_people1, { name = 'surprise' })
	character_util.set_emotion(desert_people2, { name = 'surprise' })
	character_util.set_emotion(desert_people3, { name = 'surprise' })
	wait_for_sec(1.5)

	character_util.jump(desert_people1, 0.5, 0.3)
	character_util.jump(desert_people2, 0.5, 0.3)
	character_util.jump(desert_people3, 0.5, 0.3)
	character_util.set_emotion(desert_people1, { name = 'confused' })
	character_util.set_emotion(desert_people2, { name = 'scared' })
	character_util.set_emotion(desert_people3, { name = 'surprise' })

	character_util.remove_anim(desert_people1)
	character_util.remove_anim(desert_people2)
	character_util.remove_anim(desert_people3)
	wait_for_sec(1)

	-- 땔감! 땔감! 빨리 땔감 던져 넣어!
	character_util.set_anim(desert_people1, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(desert_people1, { key = 'futurecastle_2_desert_fire_4' })

	-- 모, 몰라! 내 땔감은 어젯밤에 다 던져 넣었다고!
	character_util.set_anim(desert_people2, { name = 'cliff' })
	speech_bubble_util.show_speech_bubble_async(desert_people2, { key = 'futurecastle_2_desert_fire_5' })

	-- 당신은? 당신은 땔감 없어?
	speech_bubble_util.show_speech_bubble_async(desert_people1, { key = 'futurecastle_2_desert_fire_6' })
	character_util.remove_anim(desert_people1)
	character_util.remove_anim(desert_people2)

	character_util.set_emotion(desert_people3, { name = 'damaged' })
	wait_for_sec(1.5)

	character_util.set_emotion(desert_people1, { name = 'cry' })
	character_util.set_emotion(desert_people2, { name = 'tired' })
	character_util.set_emotion(desert_people3, { name = 'damaged' })
	wait_for_sec(2)

	character_util.shake(desert_people1, 0.02, 5)
	character_util.shake(desert_people2, 0.02, 5)
	character_util.shake(desert_people3, 0.02, 5)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(desert_people1)
		character_util.move_to_async(desert_people1, vector(59, 0, 21.5), nil, 4, true, true)
		character_util.move_to_async(desert_people1, vector(59, 0, 27), nil, 4, true, true)
		character_util.set_direction(desert_people1, 'right')
		character_util.set_emotion(desert_people1, { name = 'tired' })
		character_util.set_anim(desert_people1, { name = 'seat' })
	end, desert_people1))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(desert_people2)
		character_util.move_to_async(desert_people2, vector(56, 0, 25), nil, 4, true, true)
		character_util.move_to_async(desert_people2, vector(56.5, 0, 25), nil, 4, true, true)
		character_util.set_direction(desert_people2, 'right')
		character_util.set_emotion(desert_people2, { name = 'tired' })
		character_util.set_anim(desert_people2, { name = 'sleep' })
	end, desert_people2))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function(desert_people3)
		character_util.move_to_async(desert_people3, vector(59, 0, 19), nil, 4, true, true)
		character_util.move_to_async(desert_people3, vector(52.5, 0, 19), nil, 4, true, true)
		character_util.set_direction(desert_people3, 'left')
	end, desert_people3))

	wait_for_sec(3)

	desert_people1.Interactable.Talk = 'futurecastle_1_2_desert_camp_1'
	desert_people2.Interactable.Talk = 'futurecastle_1_2_desert_camp_4'
	desert_people3.Interactable.Talk = nil

	self:progress_custom_data(self.custom_key.desert_event)
	self.desert_event_state = self.short_event_state.done
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ConvertSwitchChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TreasureOpenScreenPlayEndEvent))

	character_util.remove_relate_event(self.get_favi(), self.cs_controller)

	character_util.remove_relate_event(self.get_shen_talker(), self.cs_controller)

	self.short_event_state = nil
	self.custom_key = nil

	if self.origin_shield_item ~= nil then
		self.origin_shield_item:ConsumeComplete()
		self.origin_shield_item = nil
	end

	if self.sword_item ~= nil then
		self.sword_item:ConsumeComplete()
		self.sword_item = nil
	end

	if self.origin_gun_item ~= nil then
		self.origin_gun_item:ConsumeComplete()
		self.origin_gun_item = nil
	end

	if self.shield_item ~= nil then
		self.shield_item:ConsumeComplete()
		self.shield_item = nil
	end

	self.get_favi().SpineController:SetAttachment('[base]weapon2', 'empty')

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
