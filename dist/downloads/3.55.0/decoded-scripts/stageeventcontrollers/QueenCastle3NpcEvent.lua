local local_class = newclass('QueenCastle3NpcEventController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.available_stage_name = 'queencastle_1_3'
	self.scene_version = scene_util.default_version

	--region item
	self.item_sprites = nil
	--endregion

	--regrion effect
	self.effects = nil
	--endregion

	--region AA72 서브 스테이지
	-- quest id
	self.summer_android_quest_id = 340

	-- npc
	self.get_summer_android = function()
		return get_character('sm_kid_android')
	end

	self.get_bad_student_female = function()
		return get_character('bad_student_female')
	end

	self.get_succubus = function()
		return get_character('dungeon_succubus_a')
	end

	self.get_teatan_ninja = function()
		return get_character('teatan_ninja')
	end

	self.get_succubus_researcher = function()
		return get_character('succubus_researcher')
	end

	self.get_shop_girl = function()
		return get_character('shop_girl')
	end

	self.get_monk_disciple = function()
		return get_character('monk_disciple')
	end

	-- item id
	self.stamp_paper_id = 20962
	self.stamp_id = 20963

	-- check option
	self.summer_android_interact_check = false
	--endregion

	--region 캐서린
	-- quest id
	self.survivor_quest_id = 347

	-- npc
	self.get_survivor = function()
		return get_character('survivor')
	end

	-- item id
	self.survivor_bag_id = 20938
	--endregion

	--region Group A AA72 & 캐서린 스타피스
	-- state
	self.group_a_state = {
		none = 0,
		aa72 = 1,
		survivor = 2,
		all_clear = 3,
	}

	self.group_a_current_state = self.group_a_state.none

	-- field object
	self.group_a_star_piece_name = 'group_a_star_piece'

	self.get_group_a_star_piece = function()
		return get_field_object('group_a_star_piece')
	end
	--endregion

	--region 란팡
	-- quest id
	self.ranpang_quest_id = 337

	self.get_ranpang = function()
		return get_character('ranpang')
	end

	self.get_doctor_bear = function()
		return get_character('doctor_bear')
	end

	self.get_dragontalon_minion = function()
		return get_character('dragontalon_minion')
	end
	--endregion

	--region 라나
	-- quest id
	self.oni_girl_quest_id = 339

	-- npc
	self.get_oni_girl = function()
		return get_character('oni_girl')
	end

	-- routine check
	self.oni_girl_loop = false
	--endregion

	--region Group B 란팡 & 라나 스타피스
	-- state
	self.group_b_state = {
		none = 0,
		ranpang = 1,
		oni_girl = 2,
		all_clear = 3,
	}

	self.group_b_current_state = self.group_b_state.none

	-- field object
	self.group_b_star_piece_name = 'group_b_star_piece'

	self.get_group_b_star_piece = function()
		return get_field_object('group_b_star_piece')
	end
	--endregion

	--region 마리아 리사
	-- quest id
	self.mario_quest_id = 344

	-- npc
	self.get_maria = function()
		return get_character('maria')
	end

	self.get_lisa = function()
		return get_character('lisa')
	end

	self.get_caravan = function()
		return get_character('caravan')
	end

	-- item id
	self.random_basket_id = 20965
	--endregion

	--region 리에
	-- quest id
	self.battleball_girl_quest_id = 352

	-- npc
	self.get_battleball_girl = function()
		return get_character('battleball_girl')
	end

	-- fx
	self.get_fx_slime_buttbounce = function()
		return unity_object_pool.GetOrCreate('FX_slime_buttbounce')
	end

	-- check option
	self.battleball_girl_interact_check = false
	--endregion

	--region Group C 마리아 리사 & 리에 스타피스
	-- state
	self.group_c_state = {
		none = 0,
		mario = 1,
		battleball_girl = 2,
		all_clear = 3,
	}

	self.group_c_current_state = self.group_c_state.none

	-- field object
	self.group_c_star_piece_name = 'group_c_star_piece'

	self.get_group_c_star_piece = function()
		return get_field_object('group_c_star_piece')
	end
	--endregion

	--region 봇치
	-- quest id
	self.hitori_android_quest_id = 345

	-- npc
	self.get_hitori_android = function()
		return get_character('android_hitori')
	end
	--endregion

	--region Mk 99
	-- quest id
	self.mecha_android_quest_id = 342

	self.get_mecha_android = function()
		return get_character('mecha_android')
	end
	--endregion

	--region Group D 봇치 & Mk 99
	self.group_d_state = {
		none = 0,
		hitori_android = 1,
		mecha_android = 2,
		all_clear = 3,
	}

	self.group_d_current_state = self.group_d_state.none

	-- field object
	self.group_d_star_piece_name = 'group_d_star_piece'

	self.group_d_door_name = 'npc_event_door'

	self.get_group_d_switch = function(number)
		return get_field_object('npc_event_switch_' .. number)
	end

	-- check option
	self.mecha_android_move = false
	--endregion

	--region 아오바
	self.leaf_fairy_quest_id = 355

	self.get_leaf_fairy = function()
		return get_character('leaf_fairy')
	end

	-- item id
	self.comics_1_id = 20967
	self.comics_2_id = 20968
	self.comics_3_id = 20969
	--endregion

	--region M 800
	self.m_800_quest_id = 341

	self.get_m_800 = function()
		return get_character('m_800')
	end

	-- fx
	self.get_fx_fx_char_debuff_yellow = function()
		return unity_object_pool.GetOrCreate('fx_char_debuff_yellow')
	end

	self.get_fx_aura_hit_loop = function()
		return unity_object_pool.GetOrCreate('fx_dai_aura_loop')
	end

	self.get_fx_ammi_railgun_ready = function()
		return unity_object_pool.GetOrCreate('fx_ammi_railgun_ready')
	end

	self.get_fx_ammi_hit = function()
		return unity_object_pool.GetOrCreate('fx_ammi_hit')
	end

	-- item id
	self.popcorn_id = 20942
	--endregion

	--region Group E 아오바 & M 800
	self.group_e_state = {
		none = 0,
		leaf_fairy = 1,
		m_800 = 2,
		all_clear = 3,
	}

	self.group_e_current_state = self.group_e_state.none

	-- field object
	self.group_e_star_piece_name = 'group_e_star_piece'

	self.get_group_e_star_piece = function()
		return get_field_object('group_e_star_piece')
	end
	--endregion
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	character_util.remove_relate_event(self.get_summer_android(), self.cs_controller)
	character_util.remove_relate_event(self.get_survivor(), self.cs_controller)
	character_util.remove_relate_event(self.get_ranpang(), self.cs_controller)
	character_util.remove_relate_event(self.get_oni_girl(), self.cs_controller)
	character_util.remove_relate_event(self.get_maria(), self.cs_controller)
	character_util.remove_relate_event(self.get_lisa(), self.cs_controller)
	character_util.remove_relate_event(self.get_battleball_girl(), self.cs_controller)
	character_util.remove_relate_event(self.get_hitori_android(), self.cs_controller)
	character_util.remove_relate_event(self.get_mecha_android(), self.cs_controller)
	character_util.remove_relate_event(self.get_leaf_fairy(), self.cs_controller)
	character_util.remove_relate_event(self.get_m_800(), self.cs_controller)

	if self.item_sprites ~= nil then
		for _, item in ipairs(self.item_sprites) do
			drop_item_util.dispose_item(item)
		end
		self.item_sprites = nil
	end

	self.oni_girl_loop = false
	character_util.stop(self.get_oni_girl())

	if self.effects ~= nil then
		for _, effect in ipairs(self.effects) do
			effect:Dispose()
			effect = nil
		end
		self.effects = nil
	end

	if self.popcorn_items ~= nil then
		for _, item in ipairs(self.popcorn_items) do
			drop_item_util.dispose_item(item)
		end
		self.popcorn_items = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')

	self.get_fx_slime_buttbounce()
	self.get_fx_fx_char_debuff_yellow()
	self.get_fx_aura_hit_loop()
	self.get_fx_ammi_railgun_ready()
	self.get_fx_ammi_hit()
	yield_return(unity_object_pool, 'WaitAll')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_summer_android()) then
		sp_util.start_scene(self.sound_scene, self, self.summer_android_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_survivor()) then
		sp_util.start_scene(self.sound_scene, self, self.survivor_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_ranpang()) or
			lua_helper.reference_equals(e.Target, self.get_oni_girl()) then
		sp_util.start_scene(self.sound_scene, self, self.group_b_talk, self, e.Target)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_maria()) or
			lua_helper.reference_equals(e.Target, self.get_lisa()) then
		sp_util.start_scene(self.sound_scene, self, self.mario_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_battleball_girl()) then
		sp_util.start_scene(self.sound_scene, self, self.battleball_girl_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_hitori_android()) then
		sp_util.start_scene(self.sound_scene, self, self.hitori_android_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mecha_android()) then
		sp_util.start_scene(self.sound_scene, self, self.mecha_android_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_leaf_fairy()) then
		sp_util.start_scene(self.sound_scene, self, self.leaf_fairy_talk, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_m_800()) then
		sp_util.start_scene(self.sound_scene, self, self.m_800_talk, self)
		return true
	end

	return false
end

function local_class:sound_scene(func, ...)
	music_player_util.change_stage_music_volume('field', 0.5, 1)
	func(...)
	music_player_util.change_stage_music_volume('field', 1, 1)
end

function local_class:on_stage_loaded_event(e)
	start_coroutine(function()
		self.item_sprites = {}
		self.effects = {}

		-- group a
		self:set_summer_android_quest()
		self:set_survivor_quest()
		self:group_a_star_piece_check()
		-- group b
		self:set_ranpang()
		self:set_oni_girl()
		self:group_b_star_piece_check()
		-- group c
		self:set_mario()
		self:set_battleball_girl()
		self:group_c_star_piece_check()
		-- group d
		self:set_hitori_android()
		self:set_mecha_android()
		self:group_d_star_piece_check()
		-- group e
		self:set_leaf_fairy()
		self:set_m_800()
		self:group_e_star_piece_check()
	end)
	return true
end

function local_class:on_stage_end_event(e)
	self.oni_girl_loop = false
	character_util.stop(self.get_oni_girl())
	return true
end

function local_class:on_switch_on_off_event(e)
	if self.mecha_android_move and e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, self.get_group_d_switch(1)) then
		self.mecha_android_move = false
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.group_d_door_name, false))
		return true
	end

	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

--region AA72 세팅
function local_class:set_summer_android_quest()
	local summer_android = self.get_summer_android()
	local bad_student_female = self.get_bad_student_female()
	local shop_girl = self.get_shop_girl()
	local succubus = self.get_succubus()
	local teatan_ninja = self.get_teatan_ninja()
	local monk_disciple = self.get_monk_disciple()
	local succubus_researcher = self.get_succubus_researcher()

	local quest_progress = user_progress:GetStartedQuest(self.summer_android_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(summer_android, 'disabled')
		character_util.set_active_state(bad_student_female, 'disabled')
		character_util.set_active_state(shop_girl, 'disabled')
		character_util.set_active_state(succubus, 'disabled')
		character_util.set_active_state(teatan_ninja, 'disabled')
		character_util.set_active_state(monk_disciple, 'disabled')
		character_util.set_active_state(succubus_researcher, 'disabled')
		return
	end

	self.group_a_current_state = self.group_a_current_state | self.group_a_state.aa72
end
--endregion

--region 캐서린 세팅
function local_class:set_survivor_quest()
	local survivor = self.get_survivor()

	local quest_progress = user_progress:GetStartedQuest(self.survivor_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(survivor, 'disabled')
		return
	end

	self.group_a_current_state = self.group_a_current_state | self.group_a_state.survivor

	local bag_item = drop_item_util.create_item({
		pos = survivor.Position - vector(0.5, 0, 0),
		itemid = self.survivor_bag_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })

	table.insert(self.item_sprites, bag_item)
end
--endregion

--region 그룹 A 스타피스 조건 체크
function local_class:group_a_star_piece_check()
	local summer_android = self.get_summer_android()
	local survivor = self.get_survivor()

	if self.group_a_current_state == self.group_a_state.all_clear then
		scene_util.set_emotion(survivor, self, 'idle')
		scene_util.set_anim(survivor, self, 'seat')
	end

	if star_piece_util.has_star_piece(self.group_a_star_piece_name) then
		summer_android.Interactable.Talk = 'qc_npc_stage3_event_21'
		summer_android.Interactable.TalkSfx = '03_dialogue_worker_01'
		survivor.Interactable.Talk = 'qc_npc_stage3_event_27'
		return
	end

	if 0 ~= (self.group_a_current_state & self.group_a_state.aa72) then
		character_util.add_listener(summer_android, self.cs_controller)
	end

	if 0 ~= (self.group_a_current_state & self.group_a_state.survivor) then
		character_util.add_listener(survivor, self.cs_controller)
	end
end
--endregion

--region AA72 Interact
function local_class:summer_android_talk()
	local leader = get_party_leader()
	local summer_android = self.get_summer_android()

	party_util.align_party(summer_android, 'right', 1, 'linear')

	if not self.summer_android_interact_check then
		--AA72(right,smile,idle)(jump1회): 마스터! 보십시오, 모두들 돌아왔습니다.
		music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
		scene_util.set_anim(summer_android, self, 'idle')
		character_util.normal_jump(summer_android, true)
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_7')

		--AA72(right,smile,ilde): 그리고 이것도 보십시오!
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_8')
	end

	--AA72(left,smile,eat) 1초
	local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	scene_util.set_anim(summer_android, self, 'eat')
	wait_for_sec(1)

	--AA72(right,smile,hold_loop) 로 머리위로 stamp_paper를 들고있다.
	equipping_sfx:Stop()
	music_player_util.play_sfx_one_shot('01_paper_01')
	local kid_hand_pos = summer_android.Position + vector(0.25, 0, 0.3)
	local stamp_paper = drop_item_util.create_item({
		pos = kid_hand_pos,
		itemid = self.stamp_paper_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })
	stamp_paper.ShadowTransform.gameObject:SetActive(false)
	stamp_paper.SpriteTransform.localScale = vector(-0.5, 0.5, 0.5)
	stamp_paper:SetSortingLayerAndOrder("Default", 2, "Default", 0)

	scene_util.set_anim(summer_android, self, 'hold_loop')

	if not self.summer_android_interact_check then
		self.summer_android_interact_check = true

		--대사 :칭찬 스탬프를 잔뜩 받아냈습니다!
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_9')
	end

	--AA72: 마스터도 하나 찍어주시겠습니까? -(이 후 재 인터랙트시 대사 시작점)
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_10')

	--캐서린 구출시 추가 대사. (캐서린을 구출하지 않았다면 출력되지 않는다.)
	if self.group_a_current_state == self.group_a_state.all_clear then
		--AA72(right,smile,hold_loop): 저기 계신분도 가방 정리를 도와드렸더니, 스탬프를 찍어주셨습니다.
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_11')
	end

	--가디언 선택지
	--그래!
	--싫어.
	local choice_result = choose_util.play_choose_event(
			{ { 'qc_npc_stage3_event_12', 'mercy' }, { 'qc_npc_stage3_event_13', 'brutal' } })

	if choice_result == 1 then
		--가디언(left,smile,nod2회)
		scene_util.set_emotion(leader, self, 'smile')
		scene_util.set_anim_async(leader, self, 'nod')
	else
		--가디언(left,sleep_deep,cross_arm) 1초
		scene_util.set_emotion(leader, self, 'sleep_deep')
		scene_util.set_anim(leader, self, 'cross_arm')
		wait_for_sec(1)

		--AA72(right,tired,hold_loop): 알겠습니다…
		character_util.remove_anim_and_emotion(leader)
		scene_util.set_emotion(summer_android, self, 'tired')
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_14')

		--컨트롤 풀림 AA72(right,smile,seat)
		drop_item_util.dispose_item(stamp_paper)
		scene_util.set_emotion(summer_android, self, 'smile')
		scene_util.set_anim(summer_android, self, 'seat')
		return
	end

	--그래! 선택지 이 후 진행
	--가디언 손에 stamp가 들려있다. 0.5칸 (left)이동 후 (twohand_attack4) 실행 이 후 0.5칸 (right) 이동
	character_util.spine_set_attachment(leader, '[base]weapon1', 'stamp')
	coroutine.yield()

	wp_util.move_async(leader, summer_android.Position + vector(0.7, 0, 0), 1)
	local anim_duration = spine_util.get_animation_duration(leader, 'twohand_attack4')

	music_player_util.play_sfx_one_shot('01_player_jump_01')
	character_util.set_animation_n_times(leader, { name = 'twohand_attack4', count = 1 })

	wait_for_sec(anim_duration * 0.7)

	--twohand_attack4 모션끝남과 동시에 stamp_paper (shake0.03) 1초
	music_player_util.play_sfx_one_shot('02_spear_02')
	drop_item_util.shake(stamp_paper, 'paper_shake', 0.03, 0.25)
	wait_for_sec(anim_duration * 0.3)

	wait_for_sec(0.3)

	character_util.remove_anim(summer_android)
	drop_item_util.dispose_item(stamp_paper)
	wait_for_sec(0.3)

	character_util.set_equipment(leader, CS.Oak.EquipmentSlot.Weapon1,
			leader.CharacterStatsBehaviour.CharacterSpec.DefaultWeapon1Id)
	wp_util.move_async(leader, summer_android.Position + vector(1, 0, 0),
			1, nil, { locked_dir = 'left' })

	character_util.remove_anim_and_emotion(leader)
	--이 후 캐서린 구출 여부에 따라 이벤트 재생
	if self.group_a_current_state ~= self.group_a_state.all_clear then
		--AA72(right,smile,idle): 감사합니다. 마스터! 이제 하나만 더 모으면 됩니다!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_15')

		character_util.remove_relate_event(summer_android, self.cs_controller)
		summer_android.Interactable.Talk = 'qc_npc_stage3_event_15'
		return
	end

	--AA72(right,smile,idle)(jump2회)
	character_util.normal_double_jump(summer_android, true)

	--AA72(right,smile,idle): 저기 계신분의 가방 정리를 돕고 받은 것과 마스터께 받은 스탬프까지…
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_16')

	--AA72(right,smile,sing): 칭찬스탬프를 다 모았습니다! 로레인님 한테 선물을 받을 겁니다!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.set_anim(summer_android, self, 'sing')
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_17')

	--AA72(right,smile,idle): 이것도 전부 마스터가 도와주신 덕분입니다!
	scene_util.set_anim(summer_android, self, 'idle')
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_18')

	--AA72(right,tired,idle): 하지만… 마스터한테 답례를 안한 것 같습니다…
	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
	scene_util.set_emotion(summer_android, self, 'tired')
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_19')

	--AA72(right,attack,idle)(jump1회) (!)notice 이모티콘 버블
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	scene_util.set_emotion(summer_android, self, 'attack')
	character_util.show_emoticon_async(summer_android, nil, 'notice')

	--AA72(left,smile,eat)(1초)
	equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	scene_util.set_emotion(summer_android, self, 'smile')
	scene_util.set_anim(summer_android, self, 'eat')
	wait_for_sec(1)

	--AA72(right,smile,get) 스타피스를 자신의 한칸아래에 던져준다.
	equipping_sfx:Stop()
	scene_util.set_anim(summer_android, self, 'get')
	local star_piece = self.get_group_a_star_piece()
	star_piece_util.appear(star_piece, summer_android.Position)
	wait_for_sec(2)

	--AA72(right,smile,release): 구조장비를 찾다 발견한 겁니다! 마스터께 드리겠습니다!
	scene_util.set_anim(summer_android, self, 'release')
	scene_util.show_normal_speech_async(summer_android, 'qc_npc_stage3_event_20')

	--제가 모두의 도움이 되어 너무 기쁩니다!
	scene_util.set_anim(summer_android, self, 'seat')
	character_util.remove_relate_event(summer_android, self.cs_controller)
	summer_android.Interactable.Talk = 'qc_npc_stage3_event_21'
	summer_android.Interactable.TalkSfx = '03_dialogue_worker_01'
end
--endregion

--region survivor Interact
function local_class:survivor_talk()
	local survivor = self.get_survivor()

	if self.group_a_current_state ~= self.group_a_state.all_clear then
		local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
		party_util.align_party(survivor, 'right', 1, 'linear')

		--캐서린(right,tired,seat): 으으… 가방상태가 엉망이야.
		equipping_sfx:Stop()
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		scene_util.set_direction(survivor, 'right')
		scene_util.set_anim(survivor, self, 'seat')
		scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_22')

		--캐서린(right,tired,bomb_idle): 역시 조금은 버리는 게 좋았을까…
		music_player_util.play_sfx_one_shot('01_swing_01')
		scene_util.set_anim(survivor, self, 'bomb_idle')
		scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_23')

		--캐서린 (left,tired,eat) 로 복귀
		scene_util.set_direction(survivor, 'left')
		scene_util.set_anim(survivor, self, { name = 'eat', sfx_name = false })
		return
	else
		party_util.align_party(survivor, 'right', 1, 'linear')
	end

	--캐서린(right,idle,idle): 네 말을 듣고 가방을 조금 정리해봤어.
	scene_util.set_direction(survivor, 'right')
	scene_util.set_anim(survivor, self, 'idle')
	scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_24')

	--캐서린(left,idle,idle): 저기 있는 꼬마가 곤란해하고 있으니까 도와주더라고…
	scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_25')

	--캐서린(right,tired,idle): 이곳으로 넘어온 후 처음 받아본 친절이야.
	scene_util.set_emotion(survivor, self, 'tired')
	scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_26')

	--캐서린(right,sleep_deep,question): 저 아이도 나처럼 속고 살지만 않으면 좋겠네…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_emotion(survivor, self, 'sleep_deep')
	scene_util.set_anim(survivor, self, 'question')
	scene_util.show_normal_speech_async(survivor, 'qc_npc_stage3_event_27')

	scene_util.set_emotion(survivor, self, 'idle')
	scene_util.set_anim(survivor, self, 'seat')
	character_util.remove_relate_event(survivor, self.cs_controller)
	survivor.Interactable.Talk = 'qc_npc_stage3_event_27'
end
--endregion

--region 란팡 세팅
function local_class:set_ranpang()
	local ranpang = self.get_ranpang()
	local doctor_bear = self.get_doctor_bear()
	local dragtalon = self.get_dragontalon_minion()

	local quest_progress = user_progress:GetStartedQuest(self.ranpang_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(ranpang, 'disabled')
		character_util.set_active_state(doctor_bear, 'disabled')
		character_util.set_active_state(dragtalon, 'disabled')
		return
	end

	self.group_b_current_state = self.group_b_current_state | self.group_b_state.ranpang
end
--endregion

--region 라나 세팅
function local_class:set_oni_girl()
	local oni_girl = self.get_oni_girl()

	local quest_progress = user_progress:GetStartedQuest(self.oni_girl_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(oni_girl, 'disabled')
		return
	end

	self.group_b_current_state = self.group_b_current_state | self.group_b_state.oni_girl
end
--endregion

--region 그룹 B 스타피스 조건 체크
function local_class:group_b_star_piece_check()
	local ranpang = self.get_ranpang()
	local doctor_bear = self.get_doctor_bear()
	local dragtalon = self.get_dragontalon_minion()
	local oni_girl = self.get_oni_girl()

	if star_piece_util.has_star_piece(self.group_b_star_piece_name) then
		doctor_bear.Interactable.Talk = 'qc_npc_stage3_event_65'
		dragtalon.Interactable.Talk = 'qc_npc_stage3_event_66'
		ranpang.Interactable.Talk = 'qc_npc_stage3_event_67'
		oni_girl.Interactable.Talk = 'qc_npc_stage3_event_68'
		scene_util.set_direction(oni_girl, 'right', false)
		scene_util.set_emotion(oni_girl, self, 'smile')
		scene_util.set_anim(oni_girl, self, 'seat')
		return
	end

	if 0 ~= (self.group_b_current_state & self.group_b_state.ranpang) then
		character_util.add_listener(ranpang, self.cs_controller)

		if 0 ~= (self.group_b_current_state & self.group_b_state.oni_girl) then
			character_util.add_listener(oni_girl, self.cs_controller)
		end
		return
	end

	if 0 ~= (self.group_b_current_state & self.group_b_state.oni_girl) then
		-- 무한 달리기
		start_coroutine(self.oni_girl_routine, self)
	end
end
--endregion

--region 라나 루프
function local_class:oni_girl_routine()
	local oni_girl = self.get_oni_girl()
	oni_girl.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.remove_anim_and_emotion(oni_girl)

	local wap_points = {
		oni_girl.Position + vector(0, 0, -2.5),
		oni_girl.Position + vector(-5, 0, -2.5),
		oni_girl.Position + vector(-5, 0, 2.5),
		oni_girl.Position + vector(0, 0, 2.5),
	}

	self.oni_girl_loop = true
	while self.oni_girl_loop do
		wp_util.move_async(oni_girl, wap_points, 7, nil, { run = true })
	end
end
--endregion

--region 그룹 B Interact
function local_class:group_b_talk(interact_target)
	local leader = get_party_leader()
	local ranpang = self.get_ranpang()
	local doctor_bear = self.get_doctor_bear()
	local dragtalon = self.get_dragontalon_minion()
	local oni_girl = self.get_oni_girl()
	local align_pos = ranpang.Position - vector(1, 0, 1)

	party_util.align_party(align_pos, 'right', 1, 'linear')

	party_util.set_direction('up')
	if lua_helper.reference_equals(interact_target, ranpang) then
		--곰(right,idle,release): 어디갔다 온 거냐! 보스!
		scene_util.play_normal_speech_action(doctor_bear, self, nil,
				'release', nil, 'qc_npc_stage3_event_28')

		--동태(right,idle,bomb_idle): 우리는 숨어있으라고 하고, 어딜 가셨던 겁니까?
		music_player_util.play_sfx_one_shot('01_swing_01')
		scene_util.play_normal_speech_action(dragtalon, self, nil,
				'bomb_idle', nil, 'qc_npc_stage3_event_29')

		--란팡(left,sleep_deep,cross_arm): 너희들이 있었으면 안드로이드들이 여기저기 흩어졌을 거다!
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'cross_arm', 'sleep_deep', 'qc_npc_stage3_event_30')

		--란팡(left,tired,idle): 이 보스가 안드로이드 무리들을 모아서 따돌리지 않았다면…
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'idle', 'tired', 'qc_npc_stage3_event_31')

		--란팡(left,sleep_deep,idle)(shake0.03): 부유성 주민들은…
		music_player_util.play_sfx_one_shot('01_rustle_01')
		character_util.shake(ranpang, 0.03, 1)
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'idle', 'sleep_deep', 'qc_npc_stage3_event_32')

		--란팡(left,smile,success): 즐겁게 안드로이드들과 술래잡기를 했을 거다!
		music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'success', 'smile', 'qc_npc_stage3_event_33')

		--란팡(left,doyagao,idle): 이 보스가 모두가 즐겁게 노는 모습을 가만히 지켜볼 것 같나?
		scene_util.set_emotion(ranpang, self, 'doyagao')
		scene_util.show_normal_speech_async(ranpang, 'qc_npc_stage3_event_34')

		--동태(right,idle,clap): 하하하! 역시 우리 보스가 세상에서 제일 사악하십니다!
		scene_util.play_normal_speech_action(dragtalon, self, nil,
				'clap', nil, 'qc_npc_stage3_event_35')

		if self.group_b_current_state ~= self.group_b_state.all_clear then
			character_util.remove_relate_event(ranpang, self.cs_controller)
			doctor_bear.Interactable.Talk = 'qc_npc_stage3_event_65'
			dragtalon.Interactable.Talk = 'qc_npc_stage3_event_35'
			ranpang.Interactable.Talk = 'qc_npc_stage3_event_34'
			return
		end
	end

	wp_util.move_async(oni_girl, ranpang.Position + vector(0.7, 0, 0), 2)

	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_emotion(oni_girl, self, 'smile')
	character_util.set_animation_n_times_async(oni_girl, { name = 'dualgun_attack_right', count = 2 })

	wp_util.move_async(oni_girl, ranpang.Position + vector(2, 0, 0),
			2, nil, { locked_dir = 'left' })

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.set_direction(ranpang, 'right')
	scene_util.set_emotion(ranpang, self, 'idle')
	character_util.show_emoticon_async(ranpang, nil, 'question')

	--라나(left,smile,release1회): 거기! 너 분명히 안드로이드들을 따돌렸다고 했지?
	character_util.set_animation_n_times(oni_girl, { name = 'release', sfx = '01_swing_01' })
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			nil, { name = 'smile', keep = true }, 'qc_npc_stage3_event_37')

	--라나(left,smile,sing): 그러면 너도 엄청나게 빠르단 얘기잖아!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			'sing', nil, 'qc_npc_stage3_event_38')

	--란팡(right,doyagao,cross_arm): 흠, 너도 혹시 용의 발톱단의 단원이 되고 싶은가?
	scene_util.play_normal_speech_action(ranpang, self, nil,
			'cross_arm', 'doyagao', 'qc_npc_stage3_event_39')

	--란팡(right,smile,release): 그렇다면 지금 당장 단원복을 가져오겠다!
	scene_util.play_normal_speech_action(ranpang, self, nil,
			'release', 'smile', 'qc_npc_stage3_event_40')

	--라나(left,tired,bomb_idle): 아니, 그런 것에는 관심 없어.
	--이때 란팡 (right,tired,idle)
	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')
	scene_util.set_emotion(ranpang, self, 'tired')
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			'bomb_idle', 'tired', 'qc_npc_stage3_event_41')

	--라나(left,smile,release): 너, 지금 나랑 달리기 시합 한 번 해볼래?
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			'release', 'smile', 'qc_npc_stage3_event_42')

	--란팡(right,sleep_deep,cross_arm): 흥, 싫다! 이 몸은 아주아주 바쁘단 말이다!
	scene_util.play_normal_speech_action(ranpang, self, nil,
			'cross_arm', 'sleep_deep', 'qc_npc_stage3_event_43')

	--라나(left,doyagao,sing): 너 혹시 나한테 지는 게 무서운 거 아냐?
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			'sing', { name = 'smile', keep = true }, 'qc_npc_stage3_event_44')

	--란팡(right,mad,release)(jump2회): 무… 무슨 소리! 이 몸에게 무서운 건 없다!
	--이때부터 라나 (left,smile,idle)
	scene_util.set_emotion(ranpang, self, 'mad')
	character_util.normal_double_jump(ranpang, true)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	scene_util.play_normal_speech_action(ranpang, self, nil,
			'release', nil, 'qc_npc_stage3_event_45')

	--곰 박사(right,idle,release): 맞아! 보스는 지금 정말 바쁘다!
	scene_util.play_normal_speech_action(doctor_bear, self, nil,
			'release', nil, 'qc_npc_stage3_event_46')

	--동태(right,idle,bomb_idle): 아마도?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(dragtalon, self, nil,
			'bomb_idle', nil, 'qc_npc_stage3_event_47')

	--란팡(down,attack,release): 그래, 부단장! 마침 잘왔다!
	--이때부터 라나 (down,idle,idle)
	scene_util.set_direction(oni_girl, 'down', false)
	scene_util.set_emotion(oni_girl, self, 'idle')
	scene_util.play_normal_speech_action(ranpang, self, 'down',
			'release', 'attack', 'qc_npc_stage3_event_48')

	--란팡(down,attack,idle): 부단장이 보기엔 둘이 겨루면 누가 이길 것 같나?!
	scene_util.play_normal_speech_action(ranpang, self, nil,
			nil, 'attack', 'qc_npc_stage3_event_49')

	--라나(down,smile,idle)(jump1회): 그래! $name(이)라면 둘 중에 누가 빠른지 객관적으로 알려주겠지?
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			nil, 'smile', 'qc_npc_stage3_event_50')

	--가디언 선택지
	--란팡이 이긴다.
	--라나가 이긴다.
	local choice_result = choose_util.play_choose_event(
			{ { 'qc_npc_stage3_event_51', 'mercy' }, { 'qc_npc_stage3_event_58', 'intellect' } })

	if choice_result == 1 then
		--가디언(up,idle,relesae)
		--이때 란팡(smile) 라나(tired)
		scene_util.set_emotion(ranpang, self, 'smile')
		scene_util.set_emotion(oni_girl, self, 'tired')
		character_util.set_animation_n_times_async(leader,
				{ name = 'release', count = 3, sfx = '01_swing_01' })

		--라나(left,tired,cross_arm): 흠, $name(이)가 하는 말이라면… 일단 믿어볼게.
		scene_util.set_direction(ranpang, 'right', false)
		character_util.remove_emotion(ranpang)
		scene_util.play_normal_speech_action(oni_girl, self, 'left',
				'cross_arm', 'tired', 'qc_npc_stage3_event_52')

		--라나(left,attack,shot): 그래도 나중에 꼭 시합해보는 거야!
		music_player_util.play_sfx_one_shot('01_swing_01')
		scene_util.play_normal_speech_action(oni_girl, self, nil,
				'shot', 'attack', 'qc_npc_stage3_event_53')

		--란팡(right,doyagao,cross_arm): 좋다! 만약에 달리기 단련이 필요하면 용의 발톱단에 들어오도록!
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'cross_arm', 'doyagao', 'qc_npc_stage3_event_54')

		--곰 박사(right,idle,release): 너무 상심하지 마라! 이걸 줄테니!
		scene_util.play_normal_speech_action(doctor_bear, self, nil,
				'release', nil, 'qc_npc_stage3_event_55')

		--곰박사가 (get) 자세로 란팡과 라나사이에 스타피스를 던져준다.
		scene_util.set_anim(doctor_bear, self, 'get')
		local star_piece = self.get_group_b_star_piece()
		star_piece_util.appear(star_piece, doctor_bear.Position)
		wait_for_sec(2)

		character_util.remove_anim(doctor_bear)

		--라나(left,smile,idle)(jump1회): 상심은 안해! 난 라이트닝 카운터 라나니까!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.set_emotion(oni_girl, self, 'smile')
		character_util.normal_jump(oni_girl, true)
		scene_util.show_normal_speech_async(oni_girl, 'qc_npc_stage3_event_55_1')

		--란팡(right,doyagao,cross_arm): 흠! 그 기세… 정말 탐나는 인재로군!
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'cross_arm', 'doyagao', 'qc_npc_stage3_event_55_2')
	else
		--가디언 (right,smile,relesae)
		--이때 란팡(tired) 라나(smile)
		scene_util.set_emotion(ranpang, self, 'tired')
		scene_util.set_emotion(oni_girl, self, 'smile')
		scene_util.set_direction(leader, 'right', false)
		scene_util.set_emotion(leader, self, 'smile')
		character_util.set_animation_n_times_async(leader,
				{ name = 'release', count = 3, sfx = '01_swing_01' })

		character_util.remove_emotion(leader)
		scene_util.set_direction(leader, 'up', false)

		--란팡(right,sleep_deep,cross_arm): 흠… 부단장이 보기엔 이 소녀가 나보다 뛰어나단 건가…
		scene_util.set_direction(oni_girl, 'left', false)
		character_util.remove_emotion(oni_girl)
		scene_util.play_normal_speech_action(ranpang, self, 'right',
				'cross_arm', 'sleep_deep', 'qc_npc_stage3_event_59')

		--란팡(right,doyagao,cross_arm): 그렇다면 이 소녀를 영입하지 않을 수가 없는 거다!
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'cross_arm', 'doyagao', 'qc_npc_stage3_event_60')

		--란팡(left,smile,release): 곰박사 빨리 사은품을 꺼내라!
		scene_util.play_normal_speech_action(ranpang, self, 'left',
				'release', 'smile', 'qc_npc_stage3_event_61')

		--곰박사(right,idle,idle): 알겠습니다. 보스.
		scene_util.show_normal_speech_async(doctor_bear, 'qc_npc_stage3_event_62')

		--곰박사가 (get) 자세로 란팡과 라나사이에 스타피스를 던져준다.
		scene_util.set_anim(doctor_bear, self, 'get')
		local star_piece = self.get_group_b_star_piece()
		star_piece_util.appear(star_piece, doctor_bear.Position)
		wait_for_sec(2)

		character_util.remove_anim(doctor_bear)
		--란팡(right,smile,release): 용의 발톱단에 들어온다면 이런 반짝이는 걸 잔뜩 가질 수 있다!
		scene_util.play_normal_speech_action(ranpang, self, 'right',
				'release', 'smile', 'qc_npc_stage3_event_63')

		--란팡(right,sleep_deep,cross_arm): 이건 그냥 사은품이니 부담말고 가져 가도록!
		scene_util.play_normal_speech_action(ranpang, self, 'right',
				'cross_arm', 'sleep_deep', 'qc_npc_stage3_event_64')

		--라나(left,smile,nod2회): 뭐, 다들 즐겁게 뛰어 다닐 수 있다면 어디든 좋아!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.play_normal_speech_action(oni_girl, self, nil,
				'nod', 'smile', 'qc_npc_stage3_event_64_1')

		--란팡(right,doyagao,cross_arm): 기다리고 있겠다!
		scene_util.play_normal_speech_action(ranpang, self, nil,
				'cross_arm', 'doyagao', 'qc_npc_stage3_event_64_2')
	end

	--라나(left,tired,cross_arm): 마음은 고맙지만… 이런 건 난 필요없는데…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.play_normal_speech_action(oni_girl, self, nil,
			'cross_arm', 'tired', 'qc_npc_stage3_event_56')

	--라나(down,smile,idle)(jump1회): 그래! 이건 그냥 $name 가져!
	character_util.normal_jump(oni_girl, true)
	scene_util.play_normal_speech_action(oni_girl, self, 'down',
			'idle', 'smile', 'qc_npc_stage3_event_57')

	character_util.remove_relate_event(ranpang, self.cs_controller)
	character_util.remove_relate_event(oni_girl, self.cs_controller)
	--곰박사(right,idle,idle): 보스도 참 고생이 많군.
	--동태(right,idle,idle): 새 단원은 언제 들어오려나…
	--란팡(left,idle.idle): 단원복을 전부 푹신한 인형옷으로 바꿔야 할 지 고민이다!
	--라나(right,smile,seat): 같이 달리기 시합해줄 사람… 어디 없나?
	doctor_bear.Interactable.Talk = 'qc_npc_stage3_event_65'
	dragtalon.Interactable.Talk = 'qc_npc_stage3_event_66'
	ranpang.Interactable.Talk = 'qc_npc_stage3_event_67'
	oni_girl.Interactable.Talk = 'qc_npc_stage3_event_68'
	scene_util.set_direction(ranpang, 'left', false)
	scene_util.set_direction(oni_girl, 'right', false)
	scene_util.set_emotion(oni_girl, self, 'smile')
	scene_util.set_anim(oni_girl, self, 'seat')
end
--endregion

--region 마리아 리사 세팅
function local_class:set_mario()
	local maria = self.get_maria()
	local lisa = self.get_lisa()
	local caravan = self.get_caravan()

	local quest_progress = user_progress:GetStartedQuest(self.mario_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(maria, 'disabled')
		character_util.set_active_state(lisa, 'disabled')
		character_util.set_active_state(caravan, 'disabled')
		return
	end

	self.group_c_current_state = self.group_c_current_state | self.group_c_state.mario
end
--endregion

--region 리에 세팅
function local_class:set_battleball_girl()
	local battleball_girl = self.get_battleball_girl()

	local quest_progress = user_progress:GetStartedQuest(self.battleball_girl_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(battleball_girl, 'disabled')
		return
	end

	self.group_c_current_state = self.group_c_current_state | self.group_c_state.battleball_girl
end
--endregion

--region 그룹 C 스타피스 조건 체크
function local_class:group_c_star_piece_check()
	local maria = self.get_maria()
	local lisa = self.get_lisa()
	local battleball_girl = self.get_battleball_girl()

	if star_piece_util.has_star_piece(self.group_c_star_piece_name) then
		scene_util.set_direction(maria, 'right', false)
		scene_util.set_direction(lisa, 'right', false)
		scene_util.set_direction(battleball_girl, 'left', false)
		character_util.set_position(battleball_girl, lisa.Position + vector(1, 0, 0))

		scene_util.set_emotion(maria, self, 'love')
		scene_util.set_emotion(lisa, self, 'love')
		scene_util.set_emotion(battleball_girl, self, 'smile')
		scene_util.set_anim(maria, self, 'sing')
		scene_util.set_anim(lisa, self, 'sing')
		scene_util.set_anim(battleball_girl, self, 'staff_idle')
		character_util.spine_set_attachment(battleball_girl, '[base]weapon1', 'guild_card_4')

		maria.Interactable.Talk = 'qc_npc_stage3_event_90'
		maria.Interactable.TalkSfx = '01_bad_fairy_01'
		lisa.Interactable.Talk = 'qc_npc_stage3_event_90'
		lisa.Interactable.TalkSfx = '01_bad_fairy_01'
		battleball_girl.Interactable.Talk = 'qc_npc_stage3_event_87'
		return
	end

	if 0 ~= (self.group_c_current_state & self.group_c_state.mario) then
		character_util.add_listener(maria, self.cs_controller)
		character_util.add_listener(lisa, self.cs_controller)
	end

	if 0 ~= (self.group_c_current_state & self.group_c_state.battleball_girl) then
		character_util.add_listener(battleball_girl, self.cs_controller)
	end
end
--endregion

--region 마리아 리사 Interact
function local_class:mario_talk()
	local maria = self.get_maria()
	local lisa = self.get_lisa()

	scene_util.set_direction(maria, 'left', false)
	scene_util.set_direction(lisa, 'left', false)
	party_util.align_party(maria, 'left', 1, 'linear')

	--리사(left,smile,release): 고마워, 형씨! 덕분에 캐러밴을 되찾았어!
	scene_util.play_normal_speech_action(lisa, self, nil,
			'release', { name = 'smile', keep = true }, 'qc_npc_stage3_event_69')

	--마리아(left,tired,bomb_idle): 안드로이드들한테 도망치려고 물건을 좀 많이 던지긴 했지만!
	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')
	scene_util.play_normal_speech_action(maria, self, nil,
			'bomb_idle', 'tired', 'qc_npc_stage3_event_70')

	--리사(left,smile,clap): 뭐, 다시 잔뜩 팔아서 메꾸면 되지 않겠어?
	scene_util.set_direction(maria, 'right')
	scene_util.play_normal_speech_action(lisa, self, nil,
			'clap', nil, 'qc_npc_stage3_event_71')

	--마리아(right,smile,idle): 맞아! 이 상황에 기 죽어봤자, 남는 건 없으니까!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(maria, self, nil,
			nil, { name = 'smile', keep = true }, 'qc_npc_stage3_event_72')

	--리사(left,smile,release): 형씨! 뭔가 필요한 사람이 있으면 꼭 홍보좀 해주라고!
	scene_util.set_direction(maria, 'left')
	scene_util.play_normal_speech_action(lisa, self, nil,
			'release', 'smile', 'qc_npc_stage3_event_73')

	--이 후 위 상단대사 원라인으로 (down,idle,idle) 배치
	scene_util.set_direction(maria, 'down', false)
	scene_util.set_direction(lisa, 'down', false)
	character_util.remove_group_anim_and_emotion({ maria, lisa })

	character_util.remove_relate_event(maria, self.cs_controller)
	character_util.remove_relate_event(lisa, self.cs_controller)

	maria.Interactable.Talk = 'qc_npc_stage3_event_72'
	lisa.Interactable.Talk = 'qc_npc_stage3_event_73'
end
--endregion

--region 리에 Interact
function local_class:battleball_girl_talk()
	local leader = get_party_leader()
	local battleball_girl = self.get_battleball_girl()
	local maria = self.get_maria()
	local lisa = self.get_lisa()

	party_util.align_party(battleball_girl, 'left', 1, 'linear')

	if not self.battleball_girl_interact_check then
		self.battleball_girl_interact_check = true

		--리에(left,smile,twohand_idle)(jump1회): 아! 또 만났구나!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.set_anim(battleball_girl, self, 'twohand_idle')
		scene_util.play_normal_speech_action(battleball_girl, self, nil,
				nil, 'smile', 'qc_npc_stage3_event_74')

		--리에(right,smile,twohand_attack): 지금 팬미팅전에 퍼포먼스를 연습하고 있어! 팬서비스는 중요하니까.
		scene_util.play_normal_speech_action(battleball_girl, self, nil,
				{ name = 'twohand_attack', sfx_name = '02_twohand_slash_02' },
				'smile', 'qc_npc_stage3_event_75')
	end

	--리에(left,idle,bomb_idle): 흠… 뭔가 때릴만한 게 있으면 더 나을 거 같은데… - 이후 재 인터랙트시 이 파트부터 재시작
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(battleball_girl, self, nil,
			'bomb_idle', nil, 'qc_npc_stage3_event_76')

	local choose_list = { { 'qc_npc_stage3_event_77', 'intellect' } }
	if self.group_c_current_state == self.group_c_state.all_clear then
		table.insert(choose_list, { 'qc_npc_stage3_event_79', 'mercy' })
	end

	--가디언 선택지
	--찾으면 알려줄게! (노랑)
	--저기 위에서 뭔가 팔고있어! (초록)(상단 캐러밴 이벤트를 봐야 생기는 선택지)
	scene_util.set_anim(battleball_girl, self, 'twohand_idle')
	local choice_result = choose_util.play_choose_event(choose_list)

	if choice_result == 1 then
		--리에(left,smile,twohand_idle)(jump1회): 고마워! 너 정말 내 열성팬이구나!
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		character_util.normal_jump(battleball_girl, true)
		scene_util.play_normal_speech_action(battleball_girl, self, nil,
				nil, 'smile', 'qc_npc_stage3_event_78')

		scene_util.set_anim(battleball_girl, self, 'twohand_attack')
		return
	end

	character_util.remove_relate_event(maria, self.cs_controller)
	character_util.remove_relate_event(lisa, self.cs_controller)
	character_util.remove_relate_event(battleball_girl, self.cs_controller)

	--리에(left,smile,twohand_idle)(jump1회): 정말이야? 고마워!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.normal_jump(battleball_girl, true)
	scene_util.play_normal_speech_action(battleball_girl, self, nil,
			nil, 'smile', 'qc_npc_stage3_event_80')

	party_util.set_direction('up')
	scene_util.set_anim(battleball_girl, self, 'twohand_walk')
	camera_util.move(leader.Position + vector(0, 0, 2), 1.5)
	wp_util.move_async(battleball_girl, lisa.Position + vector(1, 0, 0),
			2, nil, { last_direction = 'left' })

	--리에(left,idle,twohand_idle): 저기! 여기 뭐 단단하고 때리기 좋은 거 없어?
	scene_util.set_anim(battleball_girl, self, 'twohand_idle')
	scene_util.set_direction(maria, 'right')
	scene_util.set_direction(lisa, 'right', false)
	scene_util.show_normal_speech_async(battleball_girl, 'qc_npc_stage3_event_81')

	--마리아(right,smile,sing): 그런거라면 아주 좋은 물건이 있습니다!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.play_normal_speech_action(maria, self, nil,
			'sing', { name = 'smile', keep = true }, 'qc_npc_stage3_event_82')

	--마리아(right,smile,eat)리사(left,smile,eat) 1초 후
	local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	scene_util.set_direction(lisa, 'left')
	scene_util.set_emotion(lisa, self, 'smile')
	scene_util.set_anim(maria, self, 'eat')
	scene_util.set_anim(lisa, self, { name = 'eat', sfx_name = false })
	wait_for_sec(1)

	--마리아(down,smile,idle) 리사(down,smile,throw)로 한칸아래에 random_basket 스프라이트를 둔다.
	equipping_sfx:Stop()
	scene_util.set_direction(maria, 'down')
	scene_util.set_direction(lisa, 'down', false)
	scene_util.set_anim(maria, self, 'idle')
	character_util.set_animation_n_times(lisa, { name = 'throw' })
	wait_for_sec(0.3)

	music_player_util.play_sfx_one_shot('03_treasure_item_popup_01')
	local random_item = drop_item_util.create_item({
		pos = lisa.Position + vector(0, 0.3, 0),
		target = lisa.Position - vector(0, 0, 1),
		itemid = self.random_basket_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })
	wait_for_sec(1.5)

	--마리아(down,attack,release):그 박스는 저희 배관공 집안 7대 째 내려오는 전설의 아이템 중 하나.
	--이 때 리에 (twohand_walk)로 한칸 내려간 후 (left,smile,twohand_idle)
	scene_util.set_anim(battleball_girl, self, 'twohand_walk')
	wp_util.move_with_end_callback(battleball_girl, battleball_girl.Position - vector(0, 0, 1), 2,
			nil, self, nil, { last_direction = 'left', end_callback = function()
				scene_util.set_emotion(battleball_girl, self, 'smile')
				scene_util.set_anim(battleball_girl, self, 'twohand_idle')
			end })
	scene_util.play_normal_speech_action(maria, self, nil,
			'release', { name = 'attack', keep = true }, 'qc_npc_stage3_event_83')

	--리사(down,attack,cast): 시원한 타격감과 단단한 질감! 물건을 보관할 수 있는 편리함까지!
	scene_util.play_normal_speech_action(lisa, self, nil,
			'cast', 'attack', 'qc_npc_stage3_event_84')

	--마리아(down,smile,success): 구매하시면 절대 후회안하실 머스트 헤브 아이템입니다!
	scene_util.set_emotion(lisa, self, 'smile')
	scene_util.play_normal_speech_action(maria, self, nil,
			'success', { name = 'smile', keep = true }, 'qc_npc_stage3_event_85')

	music_player_util.play_sfx_one_shot('01_slowmotion_01')
	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	character_util.set_animation_n_times(battleball_girl, { name = 'twohand_attack4' })
	camera_util.move(battleball_girl.Position, 1)
	camera_util.resize_by_ratio(2.5, 1)
	time_util.mod('slow', 0.5)
	wait_for_sec(1.16)

	music_player_util.play_sfx_one_shot('03_rock_break_01')
	time_util.unmod('slow')
	camera_util.resize_to_default(1)
	self.get_fx_slime_buttbounce():Instantiate(random_item.Position)
	local star_piece = self.get_group_c_star_piece()
	star_piece_util.appear(star_piece, random_item.Position)
	drop_item_util.dispose_item(random_item)

	scene_util.set_emotion(maria, self, 'surprise')
	scene_util.set_emotion(lisa, self, 'surprise')
	character_util.normal_jump(maria, true)
	character_util.normal_jump(lisa, true)
	wait_for_sec(2)

	--리에(left,smile,nod2회): 뭐, 나쁘지 않네!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.remove_group_emotion({ maria, lisa })
	scene_util.play_normal_speech_action(battleball_girl, self, nil,
			'nod', nil, 'qc_npc_stage3_event_86')

	--리에 (up)방향으로 한칸 이동 후 (left,smile,staff_idle)로 (50%scale)을 손에 들고있다.
	scene_util.set_anim(battleball_girl, self, 'twohand_walk')
	wp_util.move_async(battleball_girl, lisa.Position + vector(1, 0, 0),
			2, nil, { last_direction = 'left' })

	scene_util.set_anim(battleball_girl, self, 'staff_idle')
	character_util.spine_set_attachment(battleball_girl, '[base]weapon1', 'guild_card_4')

	--리에(left,smile,staff_idle): 여기있는 물건 있는대로 다줘!
	--이때 마리아,리사(right,surprise,idle)(jump1회)
	scene_util.set_direction(maria, 'right', false)
	scene_util.set_direction(lisa, 'right')
	scene_util.set_emotion(maria, self, 'surprise')
	scene_util.set_emotion(lisa, self, 'surprise')
	scene_util.set_direction(battleball_girl, 'left', false)
	scene_util.show_normal_speech_async(battleball_girl, 'qc_npc_stage3_event_87')


	--마리아(right,smile,cast)(shake0.03): 이… 이건
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_emotion(maria, self, 'smile')
	scene_util.set_emotion(lisa, self, 'smile')
	scene_util.set_anim(maria, self, 'cast')
	scene_util.set_anim(lisa, self, 'cast')
	character_util.shake(maria, 0.03, 20)
	character_util.shake(lisa, 0.03, 20)
	scene_util.show_normal_speech_async(maria, 'qc_npc_stage3_event_88')

	--리사(right,smile,cast)(shake0.03): 유명인들만 가지고 다닌다는… 블랙카드?!
	scene_util.show_normal_speech_async(lisa, 'qc_npc_stage3_event_89')

	--마리아 리사 (right,love,sing)(jump1회)(shake풀림): 사랑합니다! 고객님!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.stop_shake(maria)
	character_util.stop_shake(lisa)
	scene_util.set_emotion(maria, self, 'love')
	scene_util.set_emotion(lisa, self, 'love')
	scene_util.set_anim(maria, self, 'sing')
	scene_util.set_anim(lisa, self, 'sing')
	speech_bubble_util.show_speech_bubble(maria,
			{ key = 'qc_npc_stage3_event_90', skip = true, bubble_direction = 'lb' })
	scene_util.show_normal_speech_async(lisa, 'qc_npc_stage3_event_90')

	camera_util.return_to_leader(1)

	maria.Interactable.Talk = 'qc_npc_stage3_event_90'
	maria.Interactable.TalkSfx = '01_bad_fairy_01'
	lisa.Interactable.Talk = 'qc_npc_stage3_event_90'
	lisa.Interactable.TalkSfx = '01_bad_fairy_01'
	battleball_girl.Interactable.Talk = 'qc_npc_stage3_event_87'
end
--endregion

--region 봇치 세팅
function local_class:set_hitori_android()
	local hitori_android = self.get_hitori_android()

	local quest_progress = user_progress:GetStartedQuest(self.hitori_android_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(hitori_android, 'disabled')
		return
	end

	self.group_d_current_state = self.group_d_current_state | self.group_d_state.hitori_android
end
--endregion

--region Mk 99 세팅
function local_class:set_mecha_android()
	local mecha_android = self.get_mecha_android()

	local quest_progress = user_progress:GetStartedQuest(self.mecha_android_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(mecha_android, 'disabled')
		return
	end

	self.group_d_current_state = self.group_d_current_state | self.group_d_state.mecha_android
end
--endregion

--region 그룹 D 스타피스 조건 체크
function local_class:group_d_star_piece_check()
	local hitori_android = self.get_hitori_android()
	local mecha_android = self.get_mecha_android()

	if star_piece_util.has_star_piece(self.group_d_star_piece_name) then
		character_util.set_position(mecha_android, hitori_android.Position + vector(-2, 0.2, -0.2))

		local switch = self.get_group_d_switch(3)
		local switch_button = switch.Transform:Find('mesh/switch2')
		switch_button.localPosition = vector(0, -0.08, 0)

		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.group_d_door_name))
		return
	end

	if self.group_d_current_state == self.group_b_state.all_clear then
		character_util.set_position(hitori_android, mecha_android.Position + vector(-2, 0, 2))
		scene_util.set_direction(hitori_android, 'right', false)
		scene_util.set_emotion(hitori_android, self, 'tired')
		scene_util.set_anim(hitori_android, self, 'idle')
		character_util.shake(hitori_android, 0.03, 999999)
		character_util.add_listener(hitori_android, self.cs_controller)
	end
end
--endregion

--region 봇치 Interact
function local_class:hitori_android_talk()
	local hitori_android = self.get_hitori_android()

	party_util.align_party(hitori_android, 'left', 1, 'linear')

	--봇치에게 말 걸면 (left,attack,idle)(jump1회): 아!
	character_util.stop_shake(hitori_android)
	scene_util.set_direction(hitori_android, 'left')
	scene_util.set_emotion(hitori_android, self, 'attack')
	character_util.normal_jump(hitori_android, true)
	scene_util.show_normal_speech_async(hitori_android, 'qc_npc_stage3_event_92')

	--봇치(left,tired,idle)(shake0.03): 우으으…
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.shake(hitori_android, 0.03, 20)
	scene_util.set_emotion(hitori_android, self, 'tired')
	scene_util.show_normal_speech_async(hitori_android, 'qc_npc_stage3_event_93')

	--봇치(right,tired,cast)0.3초(down,tired,cast)0.3초(right,tired,cast)0.3초
	character_util.stop_shake(hitori_android)
	scene_util.set_anim(hitori_android, self, 'cast')
	scene_util.set_direction(hitori_android, 'right')
	wait_for_sec(0.3)

	scene_util.set_direction(hitori_android, 'left')
	wait_for_sec(0.3)

	scene_util.set_direction(hitori_android, 'right')
	wait_for_sec(0.3)

	--봇치(left,attack,idle): 호… 혹시 저 분께 자리를 비켜달라고…
	scene_util.set_direction(hitori_android, 'left')
	scene_util.set_emotion(hitori_android, self, 'attack')
	scene_util.set_anim(hitori_android, self, 'idle')
	scene_util.show_normal_speech_async(hitori_android, 'qc_npc_stage3_event_94')

	--봇치(left,idle,idle)0.5초 (left,tired,idle)0.5초
	scene_util.set_emotion(hitori_android, self, 'idle')
	wait_for_sec(0.5)

	scene_util.set_emotion(hitori_android, self, 'tired')
	wait_for_sec(0.5)

	--봇치(left,tired,idle)(0.75 scale말풍선): 해주실 수 있을까요오오…
	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')
	scene_util.show_normal_speech_async(hitori_android,
			'qc_npc_stage3_event_95', true, { scale = 0.75 })

	--(down,tired,cast) 상태 원라인 X
	scene_util.set_direction(hitori_android, 'down', false)
	scene_util.set_anim(hitori_android, self, 'cast')

	character_util.remove_relate_event(hitori_android, self.cs_controller)
	character_util.add_listener(self.get_mecha_android(), self.cs_controller)

	hitori_android.Interactable.Talk = nil
end
--endregion

--region Mk 99 Interact
function local_class:mecha_android_talk()
	local leader = get_party_leader()
	local hitori_android = self.get_hitori_android()
	local mecha_android = self.get_mecha_android()

	party_util.align_party(mecha_android, 'left', 1, 'linear')

	local choice_result = choose_util.play_choose_event(
			{ { 'qc_npc_stage3_event_96', 'mercy' }, { 'qc_npc_stage3_event_97', 'brutal' } })

	if choice_result == 1 then
		music_player_util.play_sfx_one_shot('01_bad_fairy_01')
		scene_util.set_emotion(leader, self, 'smile')
		scene_util.set_anim(leader, self, 'sing')
	else
		scene_util.set_emotion(leader, self, 'attack')
		scene_util.set_anim(leader, self, 'release')
	end

	wait_for_sec(1)
	character_util.remove_anim_and_emotion(leader)

	start_coroutine(function()
		party_util.set_locked_dir('down')
		party_util.align_party(mecha_android.Position + vector(0, 0, 1), 'left', 1, 'linear')

		party_util.set_locked_dir('none')
	end)

	music_player_util.play_sfx_one_shot('03_dialogue_worker_02')
	character_util.remove_anim(mecha_android)
	wp_util.move_async(mecha_android, mecha_android.Position + vector(-2, 0.2, -0.2),
			1, nil, { last_direction = 'down' })

	local switch_3 = self.get_group_d_switch(3)
	local switch_3_button = switch_3.Transform:Find('mesh/switch2')
	switch_3_button.localPosition = vector(0, -0.08, 0)
	music_player_util.play_sfx_one_shot('02_switch_button_01')

	scene_util.set_anim(mecha_android, self, 'sleep')

	camera_util.move_async(hitori_android.Position, 1)

	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.set_emotion(hitori_android, self, 'smile')
	character_util.remove_anim(hitori_android)
	character_util.normal_jump(hitori_android, true)
	wait_for_sec(0.6)

	wp_util.move_async(hitori_android, {
		hitori_android.Position + vector(2, 0, 0),
		hitori_android.Position + vector(2, 0.2, -2.2),
	}, 4, nil, { run = true, last_direction = 'left' })
	local switch_2 = self.get_group_d_switch(2)
	local switch_2_button = switch_2.Transform:Find('mesh/switch2')
	switch_2_button.localPosition = vector(0, -0.08, 0)
	music_player_util.play_sfx_one_shot('02_switch_button_01')

	scene_util.set_emotion(hitori_android, self, 'idle')
	scene_util.set_anim(hitori_android, self, 'seat')
	character_util.remove_relate_event(mecha_android, self.cs_controller)
	hitori_android.Interactable.Talk = 'qc_npc_stage3_event_91'

	camera_util.return_to_leader(1)

	self.mecha_android_move = true
end
--endregion

--region 아오바 세팅
function local_class:set_leaf_fairy()
	local leaf_fairy = self.get_leaf_fairy()

	local quest_progress = user_progress:GetStartedQuest(self.leaf_fairy_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(leaf_fairy, 'disabled')
		return
	end

	self.group_e_current_state = self.group_e_current_state | self.group_e_state.leaf_fairy

	local comics_1 = drop_item_util.create_item({
		pos = leaf_fairy.Position + vector(-1.2, 0, 0.5),
		itemid = self.comics_1_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })

	table.insert(self.item_sprites, comics_1)

	local comics_2 = drop_item_util.create_item({
		pos = leaf_fairy.Position + vector(-1.5, 0, 0),
		itemid = self.comics_2_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })

	table.insert(self.item_sprites, comics_2)

	local comics_3 = drop_item_util.create_item({
		pos = leaf_fairy.Position + vector(-1.2, 0, -0.5),
		itemid = self.comics_3_id,
		notforinven = true,
		lootstate = 'dontfindlooter' })

	table.insert(self.item_sprites, comics_3)
end
--endregion

--region M 800 세팅
function local_class:set_m_800()
	local m_800 = self.get_m_800()

	local quest_progress = user_progress:GetStartedQuest(self.m_800_quest_id)
	if quest_progress == nil or not quest_progress.IsComplete then
		character_util.set_active_state(m_800, 'disabled')
		return
	end

	self.group_e_current_state = self.group_e_current_state | self.group_e_state.m_800

	local effect = self.get_fx_fx_char_debuff_yellow():Instantiate(m_800.Position,
			unity_class.quaternion.identity, m_800.SpineController.SpineContainerTransform)
	table.insert(self.effects, effect)
end
--endregion

--region 그룹 E 스타피스 조건 체크
function local_class:group_e_star_piece_check()
	local leaf_fairy = self.get_leaf_fairy()
	local m_800 = self.get_m_800()

	if star_piece_util.has_star_piece(self.group_e_star_piece_name) then
		scene_util.set_direction(leaf_fairy, 'right', false)
		scene_util.set_emotion(leaf_fairy, self, 'confused')
		scene_util.set_anim(leaf_fairy, self, 'prostrate')
		leaf_fairy.Interactable.Talk = 'qc_npc_stage3_event_118'
		leaf_fairy.Interactable.TalkSfx = '03_dialogue_tipsy_01'
		m_800.Interactable.Talk = 'qc_npc_stage3_event_120'

		local effect = self.get_fx_fx_char_debuff_yellow():Instantiate(leaf_fairy.Position,
				unity_class.quaternion.identity, leaf_fairy.SpineController.SpineContainerTransform)
		table.insert(self.effects, effect)
		return
	end

	if self.group_e_current_state == self.group_e_state.all_clear then
		scene_util.set_direction(leaf_fairy, 'right', false)
		scene_util.set_direction(m_800, 'left', false)
		scene_util.set_emotion(leaf_fairy, self, 'smile')
		scene_util.set_anim(leaf_fairy, self, 'sing')
	end

	if 0 ~= (self.group_e_current_state & self.group_e_state.leaf_fairy) then
		character_util.add_listener(leaf_fairy, self.cs_controller)
	end

	if 0 ~= (self.group_e_current_state & self.group_e_state.m_800) then
		character_util.add_listener(m_800, self.cs_controller)
	end
end
--endregion

--region 아오바 Interact
function local_class:leaf_fairy_talk()
	if self.group_e_current_state == self.group_e_state.all_clear then
		self:group_e_talk()
		return
	end

	local leaf_fairy = self.get_leaf_fairy()

	party_util.align_party(leaf_fairy, 'down', 1, 'linear')

	--아오바(left,tired,seat): 으으… 만화책만 보고있으니 조금 아쉬운데.
	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_98')

	--아오바(left,tired,sleep): 뭔가… 만화보면서 먹을 만한 거 없을까.
	music_player_util.play_sfx_one_shot('01_hit_npc_01')
	scene_util.set_anim(leaf_fairy, self, 'sleep')
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_99')

	--이 후 상단대사와 포즈로 원라인
	character_util.remove_relate_event(leaf_fairy, self.cs_controller)
	leaf_fairy.Interactable.Talk = 'qc_npc_stage3_event_99'
end
--endregion

--region M 800 Interact
function local_class:m_800_talk()
	if self.group_e_current_state == self.group_e_state.all_clear then
		self:group_e_talk()
		return
	end

	local m_800 = self.get_m_800()

	party_util.align_party(m_800, 'right', 1, 'linear')

	--M800(right,attack,salute): 마스터, 다시 만났군요.
	music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
	scene_util.play_normal_speech_action(m_800, self, 'right',
			'salute', 'attack', 'qc_npc_stage3_event_100')

	--M800(right,idle,bomb_idle): 마스터께서 어떤 명령을 내려도 대응할 수 있도록 대기중입니다.
	music_player_util.play_sfx_one_shot('01_swing_01')
	scene_util.play_normal_speech_action(m_800, self, nil,
			'bomb_idle', nil, 'qc_npc_stage3_event_101')

	--M800(right,idle,nod2회): 명령만 내려주십시오.
	scene_util.play_normal_speech_action(m_800, self, nil,
			'nod', nil, 'qc_npc_stage3_event_102')

	--이 후 (down,idle,idle) 로 원라인 상단대사
	scene_util.set_direction(m_800, 'down', false)
	character_util.remove_relate_event(m_800, self.cs_controller)
	m_800.Interactable.Talk = 'qc_npc_stage3_event_102'
end
--endregion

--region Group E 스타피스 획득
function local_class:group_e_talk()
	local leader = get_party_leader()
	local leaf_fairy = self.get_leaf_fairy()
	local m_800 = self.get_m_800()

	party_util.align_party(leaf_fairy, 'down', 1, 'linear')

	--아오바(right,smile,idle): 고소한 냄새…! 이건 팝콘 냄새잖아!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.set_anim(leaf_fairy, self, 'idle')
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_103')

	--M800(down,idle,idle): 마스터, 다시 만났군요.
	music_player_util.play_sfx_one_shot('03_dialogue_worker_01')
	scene_util.set_direction(m_800, 'down')
	scene_util.show_normal_speech_async(m_800, 'qc_npc_stage3_event_100')

	--아오바(right,smile,idle): 만화보면서 먹을 게 필요했는데…
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_104')

	--아오바(right,smile,release): 팝콘 조금만 튀겨주면 안될까?
	scene_util.play_normal_speech_action(leaf_fairy, self, nil,
			'release', nil, 'qc_npc_stage3_event_105')

	--M800(down,idle,ilde): 마스터, 이 휴먼은 왜 이렇게 질척대는 겁니까?
	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')
	scene_util.show_normal_speech_async(m_800, 'qc_npc_stage3_event_106')

	--M800(down,idle,idle): 내부에서 큰 마력이 느껴지기는 하나 느리고 에너지 효율도 낮아보입니다.
	scene_util.show_normal_speech_async(m_800, 'qc_npc_stage3_event_107')

	--M800(down,mad,idle): 제 계산 결과, 없는 편이 나아보입니다. 제거할까요?
	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
	scene_util.set_emotion(m_800, self, 'mad')
	scene_util.show_normal_speech_async(m_800, 'qc_npc_stage3_event_108')

	--카메라 줌
	camera_util.resize_by_ratio(3, 0.5)
	--가디언 선택지
	--그냥 해달라는대로 해줘. (초록)
	--와! 이제 팝콘을 먹을 수 있다! (노랑)
	local choice_result = choose_util.play_choose_event(
			{ { 'qc_npc_stage3_event_109', 'mercy' }, { 'qc_npc_stage3_event_110', 'intellect' } })

	if choice_result == 1 then
		--가디언 (up,idle,release)
		music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
		scene_util.set_anim(leader, self, 'release')
	else
		--가디언(up,success)
		scene_util.set_anim(leader, self, { name = 'success', sfx_name = '01_player_jump_01' })
	end

	wait_for_sec(1)

	--카메라 줌 해제
	character_util.remove_anim(leader)
	camera_util.resize_to_default(1)
	wait_for_sec(1)

	--M800(down,idle,nod2회): 마스터의 뜻이라면… 수행하도록 하죠.
	scene_util.play_normal_speech_action(m_800, self, nil,
			'nod', 'idle', 'qc_npc_stage3_event_111')

	--M800(down, mad, cast) : 엔진 출력 1단계. (안드로이드 연구소 섹션4와 동일스펙)
	music_player_util.play_sfx({ sfx_name = '02_yuze_max_01', volume = 0.5 })
	scene_util.play_normal_speech_action(m_800, self, nil,
			'cast', 'mad', 'qc_npc_stage3_event_112')

	character_util.set_sorting_layer(m_800, 'Top Effects', 3)

	--FX_Aura_Hit_Loop 생성
	local aura_hit_loop_effect = self.get_fx_aura_hit_loop():Instantiate(m_800.Position + vector(0, 0, 0.25),
			unity_class.quaternion.identity, m_800.SpineController.SpineContainerTransform)
	aura_hit_loop_effect.transform.localScale = vector(0.5, 0.5, 0.5)

	--아오바(right,smile,idle)(jump1회) : 오 시작한다!
	character_util.normal_jump(leaf_fairy, true)
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_113')

	--M800(down, mad, cast2) : 엔진 출력! 2단계!
	music_player_util.play_sfx({ sfx_name = '02_light_loop_04', volume = 0.5 })
	scene_util.play_normal_speech_action(m_800, self, nil,
			'cast2', 'mad', 'qc_npc_stage3_event_114')

	--Fx_ammi_railgun_ready생성
	local ammi_railgun_ready_effect = self.get_fx_ammi_railgun_ready():Instantiate(m_800.Position + vector(0, 0, 0.25),
			unity_class.quaternion.identity, m_800.SpineController.SpineContainerTransform)
	ammi_railgun_ready_effect.transform.localScale = vector(0.5, 0.5, 0.5)

	--몸 shake 시작.
	character_util.shake(m_800, 0.05, 999)

	--0.25초마다 팝콘 스프라이트가 하나씩 튀어나온다. (연구소와 동일)
	--총 3번
	self.popcorn_items = {}
	local popcorn_count = 3
	for i = 1, popcorn_count do
		local popcorn_item = drop_item_util.create_item({
			pos = m_800.Position,
			itemid = self.popcorn_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			sprscale = 0.5 })
		table.insert(self.popcorn_items, popcorn_item)

		local x = random_util.get_random_int(-20, 20) * 0.1
		local y = random_util.get_random_int(-10, 10) * 0.1
		local random_pos = m_800.Position + vector(x, 0, y)

		music_player_util.play_sfx_one_shot('01_throw_01')
		start_coroutine(function()
			drop_item_util.throw_item(self.popcorn_items[i], random_pos)
			music_player_util.play_sfx_one_shot('01_food_01')
		end)
		wait_for_sec(0.25)
	end

	--아오바(right,smile,sing) : 점점 고소한 냄새가…!
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.set_anim(leaf_fairy, self, 'sing')
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_115')

	--실안(down, burning, basket_damaged) : 엔진 출력! 3단계!
	music_player_util.play_sfx_one_shot('01_catch_fire_01')
	scene_util.play_normal_speech_action(m_800, self, nil,
			'basket_damaged', { name = 'burning', keep = true }, 'qc_npc_stage3_event_116')

	--Shake 더 강하게
	local loop_sfx = music_player_util.play_sfx({ sfx_name = '01_earthquake_03', volume = 0.5, loop = true })
	character_util.shake(m_800, 0.1, 999)

	--아오바(right,smile,success): 오오오!!
	scene_util.set_emotion(leaf_fairy, self, 'awesome')
	scene_util.set_anim(leaf_fairy, self, 'success')
	scene_util.show_normal_speech_async(leaf_fairy, 'qc_npc_stage3_event_117')

	--이때 카메라 줌 1초만에 0.6배로.
	camera_util.resize_by_ratio(2.5, 1)

	--M800(left,burning,idle)로 0.5칸 (left)로 이동
	wp_util.move_async(m_800, m_800.Position - vector(0.5, 0, 0), nil, 1)

	local second_popcorn_count = 15

	for i = popcorn_count + 1, popcorn_count + second_popcorn_count do
		local popcorn_item = drop_item_util.create_item({
			pos = m_800.Position,
			itemid = self.popcorn_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			sprscale = 0.5 })
		table.insert(self.popcorn_items, popcorn_item)

		local x = random_util.get_random_int(-40, -8) * 0.1
		local y = random_util.get_random_int(-10, 10) * 0.1
		local random_pos = m_800.Position + vector(x, 0, y)

		start_coroutine(drop_item_util.throw_item, self.popcorn_items[i], random_pos)
	end

	music_player_util.play_sfx_one_shot('02_explosion_01')
	character_util.set_sorting_layer(m_800, 'default', 0)
	self.get_fx_ammi_hit():Instantiate(m_800.Position)

	loop_sfx:Stop()
	character_util.stop_shake(m_800)
	aura_hit_loop_effect:Dispose()
	ammi_railgun_ready_effect:Dispose()

	camera_util.shake(0.1, 0.3)
	camera_util.resize_to_default(0.3)

	character_util.spine_damage_red_pulse(leaf_fairy)
	character_util.spine_damage_squish_default(leaf_fairy)
	character_util.spine_rotate(leaf_fairy, 360, 0.6)
	scene_util.set_emotion(leaf_fairy, self, 'damaged')
	scene_util.set_anim(leaf_fairy, self, 'embarrassed')
	character_util.move_to(leaf_fairy, leaf_fairy.Position - vector(1, 0, 0), 0.6)

	local effect = self.get_fx_fx_char_debuff_yellow():Instantiate(leaf_fairy.Position,
			unity_class.quaternion.identity, leaf_fairy.SpineController.SpineContainerTransform)
	table.insert(self.effects, effect)

	local star_piece = self.get_group_e_star_piece()
	star_piece_util.appear(star_piece, m_800.Position)
	wait_for_sec(0.6)

	scene_util.set_emotion(leaf_fairy, self, 'confused')
	scene_util.set_anim(leaf_fairy, self, 'prostrate')
	wait_for_sec(1.4)

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.set_direction(m_800, 'right')
	character_util.remove_anim_and_emotion(m_800)
	character_util.show_emoticon_async(m_800, nil, 'question')

	--M800(down,idle,nod1회): 마스터, 엔진에 이물질이 있었던 모양이군요.
	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
	character_util.set_animation_n_times(m_800, { name = 'nod' })
	scene_util.play_normal_speech_action(m_800, self, 'down',
			nil, nil, 'qc_npc_stage3_event_119')

	--M800(down,idle,idle): 이제 다시 마스터의 명령을 대기하도록 하겠습니다.
	--이후 상단 대사 원라인
	scene_util.show_normal_speech_async(m_800, 'qc_npc_stage3_event_120')

	character_util.remove_relate_event(leaf_fairy, self.cs_controller)
	character_util.remove_relate_event(m_800, self.cs_controller)

	leaf_fairy.Interactable.Talk = 'qc_npc_stage3_event_118'
	leaf_fairy.Interactable.TalkSfx = '03_dialogue_tipsy_01'
	m_800.Interactable.Talk = 'qc_npc_stage3_event_120'
end
--endregion


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
