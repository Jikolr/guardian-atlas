local local_class = newclass('Fox1At5Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--region 헌화 이벤트
	self.flower_count = 0
	self.flower_grave_starpiece_name = 'anadem_starpiece'
	self.get_grave_star_piece = function() return get_field_object(self.flower_grave_starpiece_name) end
	self.flower_prefix = 'flower_grave_'
	self.show_star_piece = false

	unity_object_pool.GetOrCreate('FX_Object_Twinkle')
	self.twinkle = nil
	--endregion

	self.flower_grave_name = 'flower_grave'

	self.flower = nil
	self.grave = nil

	self.tint_key = 'remember'
	self.remember_color = CS.UnityEngine.Color(0.5, 0.3, 0)

	self.marker_active_check = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')

	return
end

function local_class:need_on_launch()
	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)

	local nari_statue = get_character('nari_statue')
	local garam_statue = get_character('garam_statue')

	nari_statue.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(nari_statue, CS.Oak.FieldUiType.CharacterStats)

	garam_statue.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(garam_statue, CS.Oak.FieldUiType.CharacterStats)

	garam_statue.OverrideCrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	field_ui_manager:RemoveUI(garam_statue, CS.Oak.FieldUiType.CharacterStats)
	garam_statue:SetGiantFactor('statue', 1.5)
	garam_statue.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.8), vector(1, 1, 1))

	nari_statue.OverrideCrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	field_ui_manager:RemoveUI(garam_statue, CS.Oak.FieldUiType.CharacterStats)
	nari_statue:SetGiantFactor('statue', 1.5)
	nari_statue.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.8), vector(1, 1, 1))

	garam_statue.SpineController:AddColor('garam_statue', self.remember_color, 1, 0)
	nari_statue.SpineController:AddColor('nari_statue', self.remember_color, 1, 0)

	if nari_statue.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		nari_statue.Interactable:AddListener(self.cs_controller)
	end

	if q ~= nil and q.InnerProgress <= 21 and q.InnerProgress >= 19 and not q.IsComplete then
		if q==nil then

		end

		self.marker_active_check = true
		return true
	end
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	local nari_statue = get_character('nari_statue')

	if nari_statue.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		nari_statue.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.twinkle ~= nil then
		for i = 1, #self.twinkle do
			self.twinkle[i]:Dispose()
		end
		self.twinkle = nil
	end
end

function local_class:on_event(e)
	if user_progress:GetStartedQuest(60009).InnerProgress > 21 then
		if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
			self:flower_grave_setting(false)
		elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
			if lua_helper.reference_equals(e.Target, get_field_object('girl_flower')) then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.go_back_to_player, self))
				return true
			else
				self:grave_interact_event(e)
			end
		end

	elseif lua_helper.type_compare(e, CS.Oak.CustomStageEvent) and e.Params[0] == 'flower_grave' then
		-- main section 에서 날려준 이벤트를 받아서 처리
			self:flower_grave_setting(true)
	end

	if lua_helper.reference_equals(e.Target, get_character('nari_statue')) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_to_nari_statue, self))
		return true
	end

	return false
end

function local_class:talk_to_nari_statue()

	party_util.stop_and_disable_control()
	stage.FieldUIManager:Hide()

	--나리 석상 내레이션박스
	field_ui_util.show_narration_async({ key = 'fox_main_s22_39', mintotalduration = 1.0})

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

function local_class:flower_grave_setting(custom_stage_event)
	self.grave = get_field_object(self.flower_grave_name)

	--회상씬 이후에 헌화 이벤트 오픈
	if not stage_progress:HasStarPiece(self.flower_grave_starpiece_name) then
		if custom_stage_event or user_progress:GetStartedQuest(60009).InnerProgress > 21 then
			self:set_flower()
		end
	else
		-- 꽃 세팅
		drop_item_util.create_item({itemid = 20180, notforinven = true,
									pos = self.grave.Position + vector(0, 0, -1),
									lootstate = 'dontfindlooter', sprscale = 0.9})
	end

	self.grave.Interactable = CS.Oak.PublishInteractable.Create()
end

function local_class:grave_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.grave) then
		if self.flower_count == 3 and not self.show_star_piece then
			sp_util.play_normal_screenplay(self.flower_grave_event, self)
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.flower_grave_teleport_event, self))
		end

	end

	for i = 1, 3 do
		local flower = get_field_object(self.flower_prefix .. i)
		if lua_helper.reference_equals(e.Target, flower) then
			sp_util.play_normal_screenplay(self.pick_up_flower, self, flower)
		end

	end

	return false
end

function local_class:flower_grave_teleport_event()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()
	party_util.align_party(self.grave.Position + vector(0, 0, -1), 'down', 1, 'arc')

	screen_util.fade_out_async(1.5, unity_class.color.white, 'linear')

	self:change_to_garam()
	local garam = get_character('garam')

	character_util.set_position(garam, vector(62.5, 0, 55))
	field:Tint(self.tint_key, self.remember_color, 0)
	garam.SpineController:AddColor(garam.Name, self.remember_color, 1, 0)

	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)
	if q ~= nil and q.InnerProgress > 21 or q.IsComplete then
		if q == nil then

		end

		local flower_item = drop_item_util.create_item(
		{itemid = 20180, notforinven = true, pos = vector(999, 0, 999),
			lootstate = 'dontfindlooter', skip_text = true})

		local customSprite = flower_item.SpriteTransform:GetComponent(typeof(CS.CustomSprite))
		customSprite.TintColor = self.remember_color
		customSprite:Rebuild()

		flower_item.Position = vector(-1, 0, 54.5)

		flower_item.ShadowTransform.position = vector(-1, 0, 54.5) + vector(0, 0.01, -0.03)

		local invisible_interact = get_field_object('girl_flower')
		invisible_interact.Position = flower_item.SpriteTransform.position

		invisible_interact.Interactable = CS.Oak.PublishInteractable.Create()
	end

	if self.marker_active_check and q ~= nil then
		ui_quest_marker:RemoveQuestMarker('exit')
		local invisible_interact = get_field_object('girl_flower')
		ui_quest_marker:AddQuestMarkerToIFO('flower', fox_main_quest_id, true, invisible_interact)
	end

	wait_for_sec(0.5)
	screen_util.fade_in_async(1.5, unity_class.color.white, 'linear')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:go_back_to_player()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	screen_util.fade_out_async(1.5, unity_class.color.white, 'linear')

	party_manager:RestorePlayerParty()
	field:RemoveTint(nil, 0)

	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)
	if self.marker_active_check and q ~= nil then
		ui_quest_marker:RemoveQuestMarker('flower')
		ui_quest_marker:AddQuestMarkerToPoint('exit', fox_main_quest_id, true, vector(0.5, 0, 19.5))
	end

	wait_for_sec(0.5)
	screen_util.fade_in_async(1.5, unity_class.color.white, 'linear')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:change_to_garam()
	local garam = get_character('garam')

	--복장 바뀜
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	CS.Oak.ICharacterExtensions.ConvertToManualCharacter(garam, param)

	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)

end

--region 헌화 이벤트
function local_class:set_flower()
	self.twinkle = {}
	for i = 1, 3 do
		local marker = field:GetMarker(self.flower_prefix .. i)
		local flower = get_field_object(self.flower_prefix .. i)

		flower.Position = marker.position
		self.twinkle[i] = unity_object_pool.GetOrCreate('FX_Object_Twinkle'):Instantiate(flower.Position,
				unity_class.quaternion.identity, flower.Transform)
	end
end

function local_class:pick_up_flower(flower)
	local flower_pos = flower.Position

	character_util.set_side_direction(user_party.Leader)

	local eat_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})

	character_util.set_anim(user_party.Leader, {name = 'eat'})
	wait_for_sec(1)
	character_util.remove_anim(user_party.Leader)

	eat_sfx:Stop()

	music_player:PlaySfxOneShot('01_player_popup_01')
	flower.Position = vector(99, 0, 99)
	--drop_item_util.create_item({itemid = 20002, notforinven = true, pos = flower_pos, target = flower_pos,
	--							markforpick = true, sprscale = 0.9})
	wait_for_sec(0.1)
	CS.Oak.FieldUIFloatingText.Get(user_party_leader):JustPrintItemName(
			game_string:GetString('fox_5_flower_grave_flower'), 0)
	music_player:PlaySfxOneShot('03_get_drop_item_01')

	self.flower_count = self.flower_count + 1

	if self.flower_count == 3 then
		wait_for_sec(1)

		field_ui_util.show_narration_async({ key = 'fox_5_flower_grave_narration'})
		--꽃들로 화환을 만들 수 있을 것 같다.

		local wait = true
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
		--화환을 만든다.
		branches:Add({
			Text = game_string:GetString('fox_5_flower_grave_branch_0'),
			Tendency = CS.Oak.TalkTendency.Normal,
			Callback = function()
				wait = false
			end })

		ui_overlay_util.push_overlay(user_party_leader, branches)

		while wait do
			coroutine.yield(nil)
		end

		local eat_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})

		character_util.set_anim(user_party.Leader, {name = 'eat'})

		local dir = direction_util.to_vector3(user_party_leader.Direction).x

		local wreath = drop_item_util.create_item({itemid = 20180, notforinven = true,
												   pos = user_party.Leader.Position + vector(0.5 * dir, 0, 0),
												   lootstate = 'dontfindlooter', sprscale = 0.9, showoncharacter = true})
		wreath.SpriteTransform.localScale = unity_class.vector3.zero
		wreath.ShadowTransform.localScale = unity_class.vector3.zero

		local time_passed = 0
		local duration = 1
		while time_passed <= duration do
			time_passed = time_passed + unity_class.time.deltaTime
			local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseOutSine(time_passed, 0, 1, duration))
			wreath.SpriteTransform.localScale = unity_class.vector3.one * progress * 0.8
			wreath.ShadowTransform.localScale = unity_class.vector3.one * progress * 0.8

			coroutine.yield(nil)
		end
		--wait_for_sec(1)
		character_util.remove_anim(user_party.Leader)
		eat_sfx:Stop()

		wait_for_sec(0.5)

		music_player:PlaySfxOneShot('02_flower_shoot_01')
		wreath.ConsumeTarget = user_party.Leader
		wreath:Fly()
	end
end

function local_class:flower_grave_event()
	party_util.align_party(self.grave.Position + vector(0, 0, -1), 'down', 1, 'arc')
	local wait = true
	local pass = false
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	-- 예를 갖춘다 / 돌아간다
	branches:Add({
		Text = game_string:GetString('fox_5_flower_grave_branch_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
			pass = true
		end })
	branches:Add({
		Text = game_string:GetString('fox_5_flower_grave_branch_2'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- 헌화시 스타피스 등장
	if pass then
		self.show_star_piece = true
		character_util.set_anim(user_party_leader, {name = 'push'})
		character_util.spine_deviate_local(user_party_leader, vector(0, 0, 0.5), 0.5, 0.3)
		wait_for_sec(0.5)

		music_player:PlaySfxOneShot('01_rustle_01')
		drop_item_util.create_item({itemid = 20180, notforinven = true,
									pos = self.grave.Position + vector(0, 0, -1),
									lootstate = 'dontfindlooter', sprscale = 0.9})

		wait_for_sec(0.3)
		character_util.remove_anim(user_party_leader)

		wait_for_sec(1)

		local star_piece = self:get_grave_star_piece()
		local throw_position = self.grave.Position + vector(0, 1.5, 0)
		star_piece.Position = self.grave.Position + vector(0, 0, -1)
		message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(throw_position, false))
	end
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
