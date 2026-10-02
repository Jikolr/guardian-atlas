local local_class = newclass("NightmareForest1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.have_hammer = false
	self.is_reinforced_golem_2 = false
	self.using_hammer_count = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	local golem_1 = get_character('golem_livingarmor_1')
	golem_1.Interactable.Talk = 'nightmare_forest_6_enhance_golem_5'
	local golem_2 = get_character('golem_livingarmor_2')
	golem_2.Interactable.Talk = 'nightmare_forest_6_enhance_golem_6'

	unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
	unity_object_pool.GetOrCreate('FX_hit_fire')
	unity_object_pool.GetOrCreate('FX_BuffMagic_Target')
	unity_object_pool.GetOrCreate('FX_get')
	unity_object_pool.GetOrCreate('FX_explosion_boss')

	unity_object_pool.GetOrCreate('test_empty_effect')

	CS.Oak.CommonScreenplay.PreloadItemGetEvent()

	-- 블랙스미스 레벨 UI 제거
	local blacksmith = get_character('blacksmith')
	field_ui_manager:RemoveUI(blacksmith, CS.Oak.FieldUiType.CharacterStats)

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	local blacksmith = get_character('blacksmith')
	if lua_helper.type_compare(blacksmith.Interactable, typeof(CS.Oak.NPCInteractable)) then
		blacksmith.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	local golem_1 = get_character('golem_livingarmor_1')
	if lua_helper.type_compare(golem_1.Interactable, typeof(CS.Oak.NPCInteractable)) then
		golem_1.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	local golem_2 = get_character('golem_livingarmor_2')
	if lua_helper.type_compare(golem_2.Interactable, typeof(CS.Oak.NPCInteractable)) then
		golem_2.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
	end

	self.star_piece_effect = nil

	self.ifo_util = nil
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.InteractEvent) then
		local blacksmith = get_character('blacksmith')
		if lua_helper.reference_equals(e.Target, blacksmith) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_blacksmith, self))
			return true
		end

		-- 망치 획득 여부 체크
		if not self.have_hammer then return false end

		local golem_1 = get_character('golem_livingarmor_1')
		if lua_helper.reference_equals(e.Target, golem_1) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reinforce_golem_1, self))
			return true
		end

		local golem_2 = get_character('golem_livingarmor_2')
		if lua_helper.reference_equals(e.Target, golem_2) then
			if not self.is_reinforced_golem_2 then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reinforce_golem_2, self))
			else
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.break_alter, self))
			end

			return true
		end

		local alter = get_field_object('reinforce_altar')
		if lua_helper.reference_equals(e.Target, alter) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reinforce_alter, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		local alter = get_field_object('reinforce_altar')
		local blacksmith = get_character('blacksmith')
		if not stage_progress:HasStarPiece('alter_star_piece') then
			blacksmith.Interactable:AddListener(self.cs_controller)

			local fx_star_piece_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
			self.star_piece_effect = fx_star_piece_pool:Instantiate(alter.Position + vector(-0.5, 0.5, 0))
		else
			local golem_1 = get_character('golem_livingarmor_1')
			local golem_2 = get_character('golem_livingarmor_2')

			blacksmith.Interactable.Talk = 'nightmare_forest_6_enhance_golem_4'
			alter.Position = vector(999, 0, 999)

			-- 골렘 1 세팅
			golem_1:SetGiantFactor('golem_1', 0.75)
			local exps_data = game_data_service.GetData('ExpsData')
			local exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exps_data, 0)
			golem_1.FieldObjectStatsBehaviour:SetExp(exp)
			golem_1.Interactable.Talk = 'nightmare_forest_6_enhance_golem_8'

			-- 골렘 2 세팅
			golem_2:SetGiantFactor('golem_2', 1.5)
			exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exps_data, 80)
			golem_2.FieldObjectStatsBehaviour:SetExp(exp)
			golem_2.Position = golem_2.Position + 4.5 * unity_class.vector3.forward
			golem_2.Interactable.Talk = 'nightmare_forest_6_enhance_golem_17'
		end
		return true
	end

	return false
end

-- 블랙스미스랑 대화
function local_class:talk_blacksmith()
	local blacksmith = get_character('blacksmith')
	blacksmith.Interactable:RemoveRelatedEvent(self.cs_controller)

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	character_util.set_direction(blacksmith, 'right')

	local pos = blacksmith.Position + 1.5 * unity_class.vector3.right
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	speech_bubble_util.show_speech_bubble_async(blacksmith,
		{ key = 'nightmare_forest_6_enhance_golem_18', skip = true })

	speech_bubble_util.show_speech_bubble_async(blacksmith,
		{ key = 'nightmare_forest_6_enhance_golem_1', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local hide_weapon = false

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_7'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			hide_weapon = true
		end})

	ui_overlay_util.push_overlay(blacksmith, branches)

	while wait do
		coroutine.yield(nil)
	end

	if hide_weapon then
		character_util.set_emotion(user_party_leader, { name = 'surprise' })
		wait_for_sec(1)

		character_util.remove_emotion(user_party_leader)
		character_util.set_direction(user_party_leader, 'right')
		character_util.set_anim(user_party_leader, { name = 'eat' })
		wait_for_sec(1)

		character_util.remove_anim(user_party_leader)
		character_util.set_anim(user_party_leader, { name = 'bomb_idle' })
		character_util.set_emotion(user_party_leader, { name = 'smile' })
		user_party_leader:HideWeapon(true)
		character_util.set_direction(user_party_leader, 'left')
		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(blacksmith,
			{ key = 'nightmare_forest_6_enhance_golem_24', skip = true })

		character_util.remove_anim_and_emotion(user_party_leader)

		user_party_leader:HideWeapon(false)

		character_util.set_direction(blacksmith, 'down')

		blacksmith.Interactable:AddListener(self.cs_controller)

		field_ui_manager:Show()
		user_party:ResetControllers()

		return
	else
		character_util.set_anim(blacksmith, { name = 'attack', sfx_name = '01_enhance_hammer_01' })
		speech_bubble_util.show_speech_bubble_async(blacksmith,
			{ key = 'nightmare_forest_6_enhance_golem_2', skip = true })

		character_util.remove_anim(blacksmith)
		speech_bubble_util.show_speech_bubble_async(blacksmith,
			{ key = 'nightmare_forest_6_enhance_golem_3', skip = true })
	end

	-- 스프라이트 망치 드랍 (현재는 블랙스미스가 망치가 아이템으로 등록됨)
	local drop_pos = blacksmith.Position + unity_class.vector3.right
	coroutine_manager:StartCoroutine(
		stage.StageGameObject, util.cs_generator(self.drop, self, blacksmith.Position, drop_pos, 1, 2))
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 망치 장착 sfx 재생
	local equipSfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', loop = true, type_priority = 'loop', player_priority = 'player'
	})

	character_util.set_anim(user_party_leader, { name = 'eat' })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 망치 장착 sfx 중지
	equipSfx:Stop()

	character_util.remove_anim(user_party_leader)

	-- 아이템 획득 연출
	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = 20141
	local item_get_subtitle = 'nightmare_forest_6_enhance_golem_subtitle'
	local item_get_desc = 'nightmare_forest_6_enhance_golem_desc'
	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder, item_get_subtitle, item_get_desc))

	character_util.set_direction(blacksmith, 'down')

	local golem_1 = get_character('golem_livingarmor_1')
	local golem_2 = get_character('golem_livingarmor_2')

	blacksmith.Interactable.Talk = 'nightmare_forest_6_enhance_golem_4'
	golem_1.Interactable.Talk = nil
	golem_2.Interactable.Talk = nil

	golem_1.Interactable:AddListener(self.cs_controller)
	golem_2.Interactable:AddListener(self.cs_controller)

	local alter = get_field_object('reinforce_altar')
	alter.Interactable = CS.Oak.PublishInteractable.Create()

	self.have_hammer = true

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 골렘1 강화 시도
function local_class:reinforce_golem_1()
	local golem_1 = get_character('golem_livingarmor_1')
	golem_1.Interactable:RemoveRelatedEvent(self.cs_controller)

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local pos = golem_1.Position + 1.5 * unity_class.vector3.left
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	speech_bubble_util.show_speech_bubble_async(golem_1,
		{ key = 'nightmare_forest_6_enhance_golem_19', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local reinforce = false

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			reinforce = true
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(golem_1, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 선택지: 강화하기
	if reinforce then
		speech_bubble_util.show_speech_bubble(golem_1, { key = 'nightmare_forest_6_enhance_golem_12' })

		coroutine.yield(self:reinforce_motion(golem_1, golem_1.Position))

		CS.SpeechBubble.Return(golem_1)

		-- 골렘 크기 변경
		golem_1:SetGiantFactor('golem_1', 0.75)

		-- 레벨 감소
		local exps_data = game_data_service.GetData('ExpsData')
		local exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exps_data, 0)
		golem_1.FieldObjectStatsBehaviour:SetExp(exp)

		speech_bubble_util.show_speech_bubble_async(golem_1,
			{ key = 'nightmare_forest_6_enhance_golem_7', skip = true })

		speech_bubble_util.show_speech_bubble_async(golem_1,
			{ key = 'nightmare_forest_6_enhance_golem_8', skip = true })

		golem_1.Interactable.Talk = 'nightmare_forest_6_enhance_golem_8'

		self:use_hammer_check()

	-- 선택지: 그만두기
	else
		golem_1.Interactable:AddListener(self.cs_controller)
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 골렘2 강화 시도
function local_class:reinforce_golem_2()
	local golem_2 = get_character('golem_livingarmor_2')
	golem_2.Interactable:RemoveRelatedEvent(self.cs_controller)

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local pos = golem_2.Position + 1.5 * unity_class.vector3.right
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1))

	speech_bubble_util.show_speech_bubble_async(golem_2,
		{ key = 'nightmare_forest_6_enhance_golem_14', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local reinforce = false

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
			reinforce = true
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 선택지: 강화하기
	if reinforce then
		speech_bubble_util.show_speech_bubble(golem_2, { key = 'nightmare_forest_6_enhance_golem_13' })

		coroutine.yield(self:reinforce_motion(golem_2, golem_2.Position))

		CS.SpeechBubble.Return(golem_2)

		-- 거대화
		golem_2:SetGiantFactor('golem_2', 1.5)

		-- 레벨 증가
		local exps_data = game_data_service.GetData('ExpsData')
		local exp = CS.Oak.ExpsDataLevelExpExtensions.GetTotalExpForLevel(exps_data, 80)
		golem_2.FieldObjectStatsBehaviour:SetExp(exp)

		-- offset 사용을 위해서 직접 호출 (stage_init 에서 offset 변경 불가)
		local param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_9'))
		param.ClickToProceed = true
		param.Offset = vector(2.5, 0, 2)
		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		music_player:PlaySfxOneShot('03_dialogue_emphasize_01')

		param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_10'))
		param.ClickToProceed = true
		param.Offset = vector(2.5, 0, 2)
		coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

		self:use_hammer_check()

		local golem_2 = get_character('golem_livingarmor_2')
		golem_2.Interactable:AddListener(self.cs_controller)
		self.is_reinforced_golem_2 = true

	-- 선택지: 그만두기
	else
		golem_2.Interactable:AddListener(self.cs_controller)
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 석상 강화
function local_class:reinforce_alter()
	local alter = get_field_object('reinforce_altar')
	alter.Interactable = CS.Oak.NonInteractable.Instance

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true
	local reinforce = false

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			reinforce = true
			wait = false
		end})

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_3'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(alter, branches)

	while wait do
		coroutine.yield(nil)
	end

	if reinforce then
		coroutine.yield(self:reinforce_motion(alter, alter.Position + vector(-0.5, 1, 0)))

		-- 아무런 효과도 없는 것 같다.
		stage.FieldUINarrationBox:Show()
		coroutine.yield(stage.FieldUINarrationBox:SetNarration(
			game_string:GetString("nightmare_forest_6_enhance_golem_21"), 0, 1))
		stage.FieldUINarrationBox:Hide()
		coroutine.yield(coroutine_class.wait_for_sec(0.5))

		self:use_hammer_check()
	else
		alter.Interactable = CS.Oak.PublishInteractable.Create()
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 망치를 사용한 횟수 체크
function local_class:use_hammer_check()
	self.using_hammer_count = self.using_hammer_count + 1

	if self.using_hammer_count == 3 then
		coroutine.yield(coroutine_class.wait_for_sec(1))

		music_player:PlaySfxOneShot('02_break_bottle_01')

		-- 망치 깨짐
		stage.FieldUINarrationBox:Show()
		coroutine.yield(stage.FieldUINarrationBox:SetNarration(
			game_string:GetString("nightmare_forest_6_enhance_golem_11"), 0, 1))
		stage.FieldUINarrationBox:Hide()
		coroutine.yield(coroutine_class.wait_for_sec(0.5))
	end
end

-- 석상 파괴를 부탁
function local_class:break_alter()
	local golem_2 = get_character('golem_livingarmor_2')
	golem_2.Interactable:RemoveRelatedEvent(self.cs_controller)

	user_party:StopAndDisableControl()
	field_ui_manager:Hide()

	local pos = golem_2.Position + 2 * unity_class.vector3.right
	user_party:PositionParty(pos, CS.Oak.Direction.Left, 1, CS.Oak.Party.AlignType.Linear)
	coroutine.yield(coroutine_class.wait_for_sec(1.3))

	local param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_14'))
	param.ClickToProceed = true
	param.Offset = vector(2.5, 0, 2)
	coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true

	branches:Add({
		Text = game_string:GetString('nightmare_forest_6_enhance_golem_selection_4'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	character_util.set_anim(user_party_leader, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(user_party_leader, { name = 'attack' })
	wait_for_sec(1)

	character_util.remove_anim_and_emotion(user_party_leader)

	param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_20'))
	param.ClickToProceed = true
	param.Offset = vector(2.5, 0, 2)
	coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

	character_util.set_anim(user_party_leader, { name = 'nod' })
	character_util.set_emotion(user_party_leader, { name = 'smile' })
	wait_for_sec(1)

	character_util.remove_anim_and_emotion(user_party_leader)

	music_player:PlaySfxOneShot('02_die_fat_ogre_01')

	param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_15'))
	param.ClickToProceed = true
	param.Offset = vector(2.5, 0, 2)
	coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

	pos = user_party_leader.Position + 3.5 * unity_class.vector3.forward
	user_party:PositionParty(pos, CS.Oak.Direction.Up, 1, CS.Oak.Party.AlignType.Linear)

	pos = golem_2.Position + 4.5 * unity_class.vector3.forward
	coroutine.yield(self.ifo_util.MoveTo(golem_2, pos, 1, nil, true, true))

	character_util.set_direction(golem_2, 'right')

	coroutine.yield(coroutine_class.wait_for_sec(1))

	-- 석상 부수기
	character_util.set_anim(golem_2, { name = 'shoot', loop = false })

	param = speech_bubble.generate_param(golem_2, game_string:GetString('nightmare_forest_6_enhance_golem_16'))
	param.ClickToProceed = true
	param.Offset = vector(2.5, 0, 2)
	coroutine.yield(speech_bubble.instance:ShowSpeechBubbleAsync(param))

	local alter = get_field_object('reinforce_altar')
	local explosion_effect

	-- 석상 부수는 연출
	local action = {'attack_hook', 'attack'}
	local anim_scale = 1
	local anim_time = 0.6
	local cur_anim_scale = anim_scale
	local cur_anim_time = anim_time
	local explosion_sfx
	for i = 0, 20 do
		character_util.remove_anim(golem_2)
		character_util.set_anim(golem_2, { name = action[i % 2 + 1], loop = false, scale = cur_anim_scale })
		coroutine.yield(coroutine_class.wait_for_sec(cur_anim_time/3))

		music_player:PlaySfxOneShot('02_stomp_big_01')

		camera_util.shake(0.2, cur_anim_time/3)
		coroutine.yield(coroutine_class.wait_for_sec(cur_anim_time/3 * 2))

		character_util.remove_anim(golem_2)
		if cur_anim_time > 0.2 then
			cur_anim_scale = cur_anim_scale + anim_scale * 0.07
			cur_anim_time = cur_anim_time - anim_time * 0.07
		end

		if i == 4 then
			-- 폭발 sfx 시작
			explosion_sfx = music_player_util.play_sfx({
				sfx_name = '01_boss_die_01'
			})

			screen_util.fade_out(3, unity_class.color.white, CS.Oak.Interpolations.Linear)
			local fx_explosion_pool = unity_object_pool.GetOrCreate('FX_explosion_boss')
			explosion_effect = fx_explosion_pool:Instantiate(alter.Position + vector(-0.5, 0.5, 0))
		end
	end

	-- 석상 파괴됨
	self.star_piece_effect:Dispose()

	local star_piece = get_field_object('alter_star_piece')
	star_piece.Position = alter.Position + vector(-0.5, 0, 0.5)
	alter.Position = vector(999, 0, 999)
	coroutine.yield(coroutine_class.wait_for_sec(1.3))

	character_util.remove_anim(golem_2)

	explosion_sfx:FadeOut(0.5)
	music_player:PlaySfxOneShot('02_explosion_02')

	screen_util.fade_in_async(0.7, unity_class.color.white, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	golem_2.Interactable.Talk = 'nightmare_forest_6_enhance_golem_17'

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 강화하는 모션
function local_class:reinforce_motion(target, pos)
	-- 무기 교체
	user_party_leader:HideWeapon(true, 'reinforce')
	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'blacksmith_hammer')

	character_util.set_anim(user_party_leader, { name = 'attack' })

	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	local golem_1 = get_character('golem_livingarmor_1')
	local golem_2 = get_character('golem_livingarmor_2')

	-- 망치로 때리는 sfx
	music_player:PlaySfxOneShot('01_enhance_hammer_01')

	-- 골렘 강화 시 피격 연출
	if lua_helper.reference_equals(target, golem_1) or lua_helper.reference_equals(target, golem_2) then
		character_util.set_anim(target, { name = 'damaged' })
		target.SpineController:DamageRedPulse()
		target.SpineController:DamageSquish(1)
	end

	local fx_hit_fire_pool = unity_object_pool.GetOrCreate('FX_hit_fire')
	fx_hit_fire_pool:Instantiate(pos)
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	if lua_helper.reference_equals(target, golem_1) or lua_helper.reference_equals(target, golem_2) then
		character_util.remove_anim(target)
	end
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	-- 망치로 때리는 sfx
	music_player:PlaySfxOneShot('01_enhance_hammer_01')

	-- 골렘 강화 시 피격 연출
	if lua_helper.reference_equals(target, golem_1) or lua_helper.reference_equals(target, golem_2) then
		character_util.set_anim(target, { name = 'damaged' })
		target.SpineController:DamageRedPulse()
		target.SpineController:DamageSquish(1)
	end

	fx_hit_fire_pool:Instantiate(pos)
	coroutine.yield(coroutine_class.wait_for_sec(0.25))

	if lua_helper.reference_equals(target, golem_1) or lua_helper.reference_equals(target, golem_2) then
		character_util.remove_anim(target)
	end
	coroutine.yield(coroutine_class.wait_for_sec(0.1))

	fx_hit_fire_pool:Instantiate(pos)

	local alter = get_field_object('reinforce_altar')
	-- 강화 이펙트 생성
	if lua_helper.reference_equals(target, golem_1) then
		-- 강화 실패 sfx
		music_player:PlaySfxOneShot('02_explosion_01')

		local fx_rock_destroy_pool = unity_object_pool.GetOrCreate('FX_Env_BigRock_lv2_destroy')
		fx_rock_destroy_pool:Instantiate(pos)
		coroutine.yield(coroutine_class.wait_for_sec(0.15))

	elseif lua_helper.reference_equals(target, golem_2) then
		coroutine.yield(coroutine_class.wait_for_sec(0.05))

		-- 강화 성공 sfx
		music_player:PlaySfxOneShot('01_enhance_light_01')

		local fx_buff_magic_target_pool = unity_object_pool.GetOrCreate('FX_BuffMagic_Target')
		local effect = fx_buff_magic_target_pool:Instantiate(pos)
		effect.transform.localScale = unity_class.vector3.one * 2

		coroutine.yield(coroutine_class.wait_for_sec(0.1))
	end

	character_util.remove_anim(user_party_leader)
	user_party_leader:HideWeapon(false, 'reinforce')
end

-- 스프라이트 드랍
function local_class:drop(start_pos, end_pos, duration, height)
	-- 세팅
	local sprite_name = 'blacksmith_hammer'

	-- 획득 sfx
	music_player_util.play_sfx({
		sfx_name = '03_get_drop_item_01', play_pos = start_pos
	})

	local weapon_pool = unity_object_pool.GetOrCreate('test_empty_effect')
	local weapon = weapon_pool:Instantiate(start_pos)

	local shadow_setter = weapon:GetComponent(typeof(CS.Oak.StageShadowSetter))
	local main_sprite = weapon.transform:Find('projectiles'):GetComponent(typeof(CS.CustomSprite))
	local shadow_sprite = weapon.transform:Find("shadow"):GetComponent(typeof(CS.CustomSprite))
	main_sprite:SetSortingLayer('Under Effects')

	main_sprite.SpriteName = sprite_name
	shadow_sprite.SpriteName = sprite_name

	main_sprite:Rebuild()
	shadow_sprite:Rebuild()

	-- 드랍 연출
	local time_passed = 0

	-- 날아가는 sfx 재생
	music_player_util.play_sfx({
		sfx_name = '01_air_spin_01', loop = true, duration = duration, type_priority = 'loop'
	})

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / duration)

		weapon.transform.localRotation = unity_class.quaternion.AngleAxis(360 * 4 * progress, unity_class.vector3.up)

		local h = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * height

		shadow_setter.Position = unity_class.vector3.Lerp(start_pos, end_pos, progress) + unity_class.vector3.up * h

		coroutine.yield(nil)
	end

	-- 공중에 살짝 떠있는 모습
	shadow_setter.Position = end_pos + 0.2 * unity_class.vector3.up
	weapon.transform.localRotation = unity_class.quaternion.Euler(0, -45, 0)

	coroutine.yield(coroutine_class.wait_for_sec(duration))

	-- 초기화
	main_sprite:SetSortingLayer('Default')

	main_sprite.SpriteName = ''
	shadow_sprite.SpriteName = ''

	main_sprite:Rebuild()
	shadow_sprite:Rebuild()

	weapon:Dispose()

	-- 아이템 획득 이펙트 생성
	local fx_get_pool = unity_object_pool.GetOrCreate('FX_get')
	fx_get_pool:Instantiate(end_pos)
	-- 아이템 라벨 생성
	local text = CS.Oak.FieldUIFloatingText.Get(user_party_leader)
	text:JustPrintItemName(game_string:GetString('blacksmith_hammer'))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
