local local_class = newclass("SnowMountainSnowFightController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.kid_name = 'snow_fight_kid_'
	self.holder_name = 'snow_fight_manual'

	-- 처음 스테이지에 들어왔을 때 코스튬 id
	self.save_costume_id = nil

	-- 처음 대화하고 다음 대화에서는 앞 부분 대화 안 보도록 하는 플래그
	self.skip_talk = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')

	self.party = {}
	for i = 0, user_party.Count - 1 do
		table.insert(self.party, user_party[i])
	end

	-- 리더가 코스튬을 착용하고 있는지 체크
	if user_party_leader.Costume ~= nil then
		self.save_costume_id = user_party_leader.Costume.CostumeSpec.Id
	end

	return util.cs_generator(self.stage_load_resource, self)
end

-- 눈싸움 전용 캐릭터 관련 리소스 로드
function local_class:stage_load_resource()
	yield_return_func(self.snow_fight_resource_holder, self)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	local kid = get_character(self.kid_name .. 1)
	if lua_helper.type_compare(kid.Interactable, CS.Oak.NPCInteractable) then
		kid.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.party ~= nil then
		for k, _ in pairs(self.party) do
			self.party[k] = nil
		end

		self.party = nil
	end

	self.quest_marker_pos = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	local kid = get_character(self.kid_name .. 1)
	if event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, kid) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.talk_kid, self))
			return true
		end
	end

	if event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == 'snow_fight' then
			sp_util.play_normal_screenplay(self.win_player, self)
			return true
		end
	end

	local holder_for_leader = get_character(self.holder_name)
	if event_type == typeof(CS.Oak.DamageEvent) then
		if lua_helper.reference_equals(e.Info.target, holder_for_leader) then
			if e.HpBefore - e.Info:GetTotalDamage() < 1 then
				sp_util.play_normal_screenplay(self.lose_player, self)
			end
			return true
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		-- 스타피스 획득 여부에 따른 스타피스 처리
		if not stage_progress:HasStarPiece('snow_fight_star_piece') then
			kid.Interactable:AddListener(self.cs_controller)
		else
			-- 눈싸움 재밌다!
			kid.Interactable.Talk = 'snowmountain_1_4_snow_fight_12'
		end
		return true
	end

	return false
end

-- 눈싸움 아이와 대화
function local_class:talk_kid()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local kids = {}
	for i = 1, 3 do
		local kid = get_character(self.kid_name .. i)
		table.insert(kids, kid)
	end

	kids[1].Interactable:RemoveRelatedEvent(self.cs_controller)

	character_util.align_party(kids[1], 'left', 1, 'linear')
	wait_for_sec(0.5)

	local snow_fight_string_key
	if not self.skip_talk then
		music_player:PlaySfxOneShot('03_dialogue_positive_01')
		-- 눈싸움 하자!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_1'
		speech_bubble_util.show_speech_bubble_async(kids[1],
			{ key = snow_fight_string_key, skip = true, bubble_type = 'shout' })

		-- 갑자기? / 나중에
		local player_choice = choose_util.play_choose_event(
			{{ 'snowmountain_1_4_snow_fight_2' }, { 'snowmountain_1_4_snow_fight_3' }})

		if player_choice == 2 then
			kids[1].Interactable:AddListener(self.cs_controller)
			field_ui_manager:Show()
			party_util.reset_controllers()
			return
		end

		-- 원래 눈 마주치면 눈싸움 하는 거야!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_4'
		speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

		-- 이기면 내가 선물 줄게!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_5'
		speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

		music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
		character_util.set_anim(kids[2], { name = 'dance' })
		-- 그치만 못 이길 걸~
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_20'
		speech_bubble_util.show_speech_bubble_async(kids[2], { key = snow_fight_string_key, skip = true })

		character_util.remove_anim(kids[2])

		music_player:PlaySfxOneShot('01_small_jump_01')
		character_util.set_anim(kids[3], { name = 'victory_get' })
		-- 얜 우리 마을 눈싸움 챔피언이라구!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_21'
		speech_bubble_util.show_speech_bubble_async(kids[3], { key = snow_fight_string_key, skip = true })

		character_util.remove_anim(kids[3])

		-- 어때? 할 거지? 할 거지!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_22'
		speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })
	else
		-- 준비됐어? 눈싸움의 세계는 만만치 않다구!
		snow_fight_string_key = 'snowmountain_1_4_snow_fight_23'
		speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })
	end

	self.skip_talk = true

	-- 덤벼! / 나중에
	local player_choice = choose_util.play_choose_event(
		{{ 'snowmountain_1_4_snow_fight_6' }, { 'snowmountain_1_4_snow_fight_3' }})

	if player_choice == 2 then
		kids[1].Interactable:AddListener(self.cs_controller)
		field_ui_manager:Show()
		party_util.reset_controllers()
		return
	end

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	-- 조오아써! 정정당당하게 일 대 일로 해!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_7'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	-- 리더 아이 끄덕끄덕
	character_util.set_direction(kids[1], 'right')
	character_util.set_anim(kids[1], { name = 'nod' })

	if #self.party ~= 1 then
		-- 플레이어 끄덕끄덕
		character_util.set_direction(user_party_leader, 'left')
		character_util.set_anim(user_party_leader, { name = 'nod' })
	end
	wait_for_sec(1)

	character_util.remove_anim(user_party_leader)
	character_util.remove_anim(kids[1])

	-- 아이 파티원들 끄덕끄덕
	for i = 2, #kids do
		character_util.set_anim(kids[i], { name = 'nod' })
	end
	-- 파티원들 끄덕끄덕
	for i = 2, #self.party do
		character_util.set_anim(self.party[i], { name = 'nod' })
	end
	wait_for_sec(1)

	for i = 2, #self.party do
		character_util.remove_anim(self.party[i])
	end

	for i = 2, #kids do
		character_util.remove_anim(kids[i])
	end

	-- 눈싸움 전 세팅
	-- bgm_transition: Field(bgm_shivermore_main) -> Muted
	music_player_util.play_stage_music({ state = 'muted' })
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	-- set_bgm: Combat(bgm_battle_normal) -> Combat(bgm_red_hood)
	music_player_util.set_stage_music_clip_async({ name = 'bgm_red_hood', state = 'combat' })

	local marker = field:GetMarker('snow_fight_leader').position
	user_party_leader.Position = marker
	marker = field:GetMarker('snow_fight_kid').position
	kids[1].Position = marker
	character_util.set_direction(kids[1], 'left')

	local party_action = {'release', 'success', 'clap'}
	-- 파티원들 npc로 변경 및 응원 장소로 이동
	marker = field:GetMarker('snow_fight_party').position
	for i = 2, #self.party do
		character_util.convert_to_npc(self.party[i])
		self.party[i].Position = marker + (i - 2) * 2 * unity_class.vector3.back
		character_util.set_direction(self.party[i], 'right')
		character_util.set_anim(self.party[i], { name = party_action[i - 1] })
	end

	-- 아이 파티원들 응원 장소로 이동
	marker = field:GetMarker('snow_fight_kid_party').position
	kids[2].Position = marker
	character_util.set_anim(kids[2], { name = 'clap' })
	kids[3].Position = marker + 7.5 * unity_class.vector3.back
	character_util.set_anim(kids[3], { name = 'success' })

	wait_for_sec(1)

	local holder_for_leader = get_character(self.holder_name)
	do
		--- manual 캐릭터 눈싸움용 캐릭터로 교체
		-- 코스튬 착용 가능한 캐릭터와 코스튬 착용 여부에 따른 체크
		if self.save_costume_id ~= user_party_leader.Costume then
			-- 처음 저장한 코스튬 id와 현재 입고 있는 코스튬이 다르면 다시 세팅
			if self.save_costume_id ~= user_party_leader.Costume.CostumeSpec.Id then
				self.save_costume_id = user_party_leader.Costume.CostumeSpec.Id
				yield_return_func(self.snow_fight_resource_holder, self)
			end
		end

		holder_for_leader.Position = user_party_leader.Position
		character_util.set_direction(holder_for_leader, 'right')
		holder_for_leader.FieldObjectStatsBehaviour:Heal(10000, false)

		user_party_leader.Position = vector(99, 0, 99)

		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		param.HidePreviousParty = false

		character_util.convert_to_manual_character(holder_for_leader, param)
		character_util.set_immortal(holder_for_leader, true)

		field_ui_manager:RemoveUI(holder_for_leader, CS.Oak.FieldUiType.CharacterStats)
		field_ui_manager:RemoveUI(kids[1], CS.Oak.FieldUiType.CharacterStats)

		holder_for_leader.FieldObjectStatsBehaviour:SetExp(0)
		kids[1].FieldObjectStatsBehaviour:SetExp(0)
	end
	user_party:StopAndDisableControl()

	music_player:PlaySfxOneShot('01_bell_01')
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	wait_for_sec(0.5)

	-- 눈싸움 아이를 적으로 변경
	character_util.convert_to_monster(kids[1], 'snow_fight', 'snow_fight')
	character_util.set_death_type(kids[1], 'prostrate')
	command_util.execute_monster_notice(kids[1], holder_for_leader, "battle")
	kids[1].FieldObjectStatsBehaviour.NoticeLinkName = 'snow_fight'
	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(kids[1]))

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 플레이어가 이겼을 때
function local_class:win_player()
	local kids = {}
	for i = 1, 3 do
		local kid = get_character(self.kid_name .. i)
		table.insert(kids, kid)
		-- 우는 아이들
		if i ~= 1 then
			character_util.remove_anim_and_emotion(kid)
			character_util.set_anim(kid, { name = 'cast' })
			character_util.set_emotion(kid, { name = 'cry' })
		end
	end

	local holder_for_leader = get_character(self.holder_name)
	-- 들고있는 물체를 던지도록 함
	local current_state = holder_for_leader.FieldObjectBehaviour.CurrentActionState
	if current_state ~= nil and lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local hold_target = current_state.HoldTarget
		command_util.execute_throw(holder_for_leader, hold_target, direction_util.to_vector3(holder_for_leader.Direction),
			holder_for_leader.Position, 8, false)
	end

	yield_return_func(self.end_setting, self, true)

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	-- 으아... 강하다...
	local snow_fight_string_key = 'snowmountain_1_4_snow_fight_8'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	-- 우리 마을 챔피언이 지다니...
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_13'
	speech_bubble_util.show_speech_bubble_async(kids[2], { key = snow_fight_string_key, skip = true })

	-- 엄청난 실력자야!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_14'
	speech_bubble_util.show_speech_bubble_async(kids[3], { key = snow_fight_string_key, skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.shake(kids[1], 0.02, 1)
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_player_popup_01')
	character_util.set_emotion(kids[1], { name = 'idle' })
	character_util.mario_jump_async(kids[1], 'left')

	character_util.set_anim(kids[1], { name = 'idle' })
	for _, v in pairs(kids) do
		character_util.set_emotion(v, { name = 'smile' })
	end
	music_player:PlaySfxOneShot('03_dialogue_positive_01')
	-- 우히히! 재밌어!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_9'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	character_util.remove_anim(kids[1])
	character_util.set_anim(kids[1], { name = 'success', sfx_name = '01_small_jump_01' })
	-- 자, 선물 줄게!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_10'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	-- 스타피스 드랍
	local star_piece = get_field_object('snow_fight_star_piece')
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(kids[1].Position))
	wait_for_sec(2)

	character_util.remove_anim(kids[1])
	character_util.set_anim(kids[1], { name = 'idle' })
	-- 놀아줘서 고마워! 빠빠이!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_11'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	-- 빠빠이!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_15'
	speech_bubble_util.show_speech_bubble_async(kids[2], { key = snow_fight_string_key, skip = true })

	character_util.remove_emotion(kids[1])
	character_util.set_emotion(kids[1],{ name = 'idle' })

	-- 눈싸움 재밌다!
	kids[1].Interactable.Talk = 'snowmountain_1_4_snow_fight_12'
end

-- 플레이어가 눈싸움에서 패배했을 때
function local_class:lose_player()
	local kids = {}
	for i = 1, 3 do
		local kid = get_character(self.kid_name .. i)
		table.insert(kids, kid)
	end
	character_util.convert_to_npc(kids[1])

	local holder_for_leader = get_character(self.holder_name)
	-- 들고있는 물체를 던지도록 함
	local current_state = holder_for_leader.FieldObjectBehaviour.CurrentActionState
	if current_state ~= nil and lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local hold_target = current_state.HoldTarget
		command_util.execute_throw(holder_for_leader, hold_target, direction_util.to_vector3(holder_for_leader.Direction),
			holder_for_leader.Position, 8, false)
	end

	-- 우는 파티원들
	for i = 2, #self.party do
		character_util.remove_anim_and_emotion(self.party[i])
		character_util.set_anim(self.party[i], { name = 'cast' })
		character_util.set_emotion(self.party[i], { name = 'cry' })
	end

	-- 플레이어 죽은 처리
	if holder_for_leader.Direction == CS.Oak.Direction.Up or holder_for_leader.Direction == CS.Oak.Direction.Down then
		character_util.set_direction(holder_for_leader, 'right')
	end
	character_util.set_anim(holder_for_leader, { name = 'dead', loop = false, sfx_name = '01_hit_npc_01' })
	character_util.set_emotion(holder_for_leader, { name = 'hurt' })
	wait_for_sec(3)

	yield_return_func(self.end_setting, self, false)

	character_util.remove_anim_and_emotion(holder_for_leader)

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	character_util.set_emotion(kids[1], { name = 'smile' })
	-- 에헤헤, 괜찮아? 보기보다 약하네!
	local snow_fight_string_key = 'snowmountain_1_4_snow_fight_16'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	character_util.set_emotion(kids[2], { name = 'smile' })
	-- 역시 우리 마을 챔피언이야!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_18'
	speech_bubble_util.show_speech_bubble_async(kids[2], { key = snow_fight_string_key, skip = true })

	character_util.set_emotion(kids[3], { name = 'smile' })
	-- 챔피언을 이길 순 없지!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_19'
	speech_bubble_util.show_speech_bubble_async(kids[3], { key = snow_fight_string_key, skip = true })

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.shake(user_party_leader, 0.02, 1)
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_player_popup_01')
	character_util.set_emotion(user_party_leader, { name = 'idle' })
	character_util.mario_jump_async(user_party_leader, 'right')

	character_util.set_anim(kids[1], { name = 'success', sfx_name = '01_small_jump_01' })
	-- 또 놀고 싶으면 말해!
	snow_fight_string_key = 'snowmountain_1_4_snow_fight_17'
	speech_bubble_util.show_speech_bubble_async(kids[1], { key = snow_fight_string_key, skip = true })

	character_util.remove_anim_and_emotion(kids[1])
	kids[1].Interactable:AddListener(self.cs_controller)
end

-- 눈싸움 끝나고 세팅
function local_class:end_setting(win)
	local kids = {}
	for i = 1, 3 do
		local kid = get_character(self.kid_name .. i)
		table.insert(kids, kid)
	end

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	-- set_bgm: Combat(bgm_red_hood) -> Combat(bgm_battle_normal)
	music_player_util.set_stage_music_clip_async({ name = 'bgm_battle_normal', state = 'combat' })

	local marker = field:GetMarker('snow_fight_end').position

	kids[1].FieldObjectStatsBehaviour:Heal(10000, false)
	character_util.convert_to_npc(kids[1])

	local end_pos = {marker, marker + vector(0.5, 0, -0.5), marker + vector(0.5, 0, 0.5)}
	for k, v in pairs(kids) do
		v.Position = end_pos[k]
	end

	-- 리더 되될리기
	local holder_for_leader = get_character(self.holder_name)
	holder_for_leader.Position = vector(99, 0, 99)

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false

	character_util.convert_to_manual_character(self.party[1], param)

	character_util.set_direction(kids[1], 'left')
	for i = 2, #self.party do
		character_util.remove_anim_and_emotion(self.party[i])
		character_util.convert_to_party_member(self.party[i], user_party)
	end

	local pos = marker + 2 * unity_class.vector3.left
	user_party:PositionParty(pos, CS.Oak.Direction.Right, 0, CS.Oak.Party.AlignType.Linear)
	user_party:StopAndDisableControl()

	for i = 2, #kids do
		character_util.set_anim(kids[i], { name = 'idle' })
		character_util.set_emotion(kids[i], { name = 'idle' })
	end

	if not win then
		character_util.set_anim(user_party_leader, { name = 'prostrate' })
		character_util.set_emotion(user_party_leader, { name = 'hurt' })
		character_util.set_anim(kids[1], { name = 'idle' })
		character_util.set_emotion(kids[1], { name = 'idle' })
	else
		character_util.set_emotion(kids[2], { name = 'surprise' })
		character_util.set_emotion(kids[3], { name = 'surprise' })
	end

	wait_for_sec(0.5)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
end

-- 홀더를 리더와 같도록 세팅
function local_class:snow_fight_resource_holder()
	local res_holder = CS.Foundations.ResourceHolder()

	local asset_bundle_name = user_party_leader.CharacterInfo.AssetName.assetBundleName
	local asset_name = user_party_leader.CharacterInfo.AssetName.assetName
	local skin_name = user_party_leader.CharacterInfo.SkinName

	local holder_for_leader = get_character(self.holder_name)

	if user_party_leader.Costume == nil then
		holder_for_leader.FieldObjectStatsBehaviour.CharacterSpec.SpriteAssetName =
			user_party_leader.CharacterInfo.CharacterSpec.SpriteAssetName
	else
		holder_for_leader.FieldObjectStatsBehaviour.CharacterSpec.SpriteAssetName =
			user_party_leader.Costume.CostumeSpec.AssetName
	end

	holder_for_leader.FieldObjectStatsBehaviour.CharacterSpec.CharacterName =
		user_party_leader.CharacterInfo.CharacterSpec.CharacterName

	holder_for_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualWalkSpeed =
		user_party_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualWalkSpeed

	holder_for_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualDashSpeed =
		user_party_leader.FieldObjectStatsBehaviour.CharacterSpec.ManualDashSpeed

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, res_holder,
		asset_bundle_name, asset_name, function (prefab)
			local go = CS.UnityEngine.GameObject.Instantiate(prefab)
			local spine_controller = go:GetComponent(typeof(CS.Oak.SpineController))

			if spine_controller ~= nil then
				holder_for_leader.SpineController:SwitchSpineController(spine_controller)
			else
				CS.UnityEngine.Object.Destroy(go)
			end
		end	)

	-- 스킨 설정
	if skin_name then
		holder_for_leader.SpineController.SkinName = skin_name
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
