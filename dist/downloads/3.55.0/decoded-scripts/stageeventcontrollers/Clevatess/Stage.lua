local local_class = newclass('ShortStoryClevatessController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 7002101
	self.quest_progress = nil
	self.group_controller = nil

	self.is_stage_end = false

	--region 암살 관련 데이터
	self.level_of_sword_name = {
		day_2 = 2,
		day_3 = 3
	}

	self.current_level_of_sword = self.level_of_sword_name.day_2

	self.sword_name_prefix = 'broken_jibo_'

	self.get_waypoint_guard = function(index)
		return get_character('waypoint_guard_' .. index)
	end

	--TODO FIXME 퀘스트 컨트롤러와 현재 분리 되어있어, 문제가 생김. 이쪽으로 통합하는게 좋을듯.
	self.waypoint_guard_count = 26

	self.guard_battle_group_name = 'waypoint_guards'
	self.waypoint_guard_event_key = 'clevatess_wg_event'
	--endregion

	-- fx
	self.fx = metatable_helper.create_fx_accessor({
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
		get = function()
			return unity_object_pool.GetOrCreate('FX_get')
		end,
		dead = function()
			return unity_object_pool.GetOrCreate('FX_dead')
		end,
		gibo_assassination = function()
			return unity_object_pool.GetOrCreate('fx_ct_assassination_start_loop')
		end,
		gibo_end = function()
			return unity_object_pool.GetOrCreate('fx_ct_gibo_space_cracked_end')
		end,
		ice_ridge = function()
			return unity_object_pool.GetOrCreate('FX_IceRidge')
		end,
		klen_effect = function()
			return unity_object_pool.GetOrCreate('fx_ct_clen_shadow_start_loop')
		end,
		heal = function()
			return unity_object_pool.GetOrCreate('FX_heal_a')
		end
	})

	-- 대장장이 원라인 npc
	self.oneline_enhancement_npc = metatable_helper.inherit({
		item = nil,
		can_event = false,
		marker = 'oneline_enhancement_npc_pos',
		zone = 'oneline_enhancement_npc_zone',
	}, {
		get_npc = function()
			return get_character('oneline_enhancement_npc')
		end,
		get_event_npc = function()
			return get_character('oneline_enhancement_event_npc')
		end,
		create_item = function(this)
			this.item = quest_drop_item_util.create_item({
				item_id = 21701,
				pos = this:get_npc().Position + vector(-0.5, 0, 0),
				loot_state = quest_drop_item_loot_state.dont_find_looter,
				skip_text = true
			})
		end,
		dispose = function(this)
			if this.item ~= nil then
				quest_drop_item_util.dispose_item(this.item)
				this.item = nil
			end

			speech_bubble_util.remove_bubble(this:get_npc())
			speech_bubble_util.remove_bubble(this:get_event_npc())
		end,
		progress_setting = function(this, progress)
			local npc = this:get_npc()
			local check_progress = lua_helper.get_or_default(progress,
					self.quest_progress == nil and 0 or self.quest_progress.InnerProgress)

			if check_progress <= 2 then
				character_util.set_direction(npc, 'left')
				scene_util.set_emotion(npc, self, 'sleep_deep')
				scene_util.set_anim(npc, self, 'eat')
				npc.Interactable.Talk = 'ss_clevatess_oneline_event_1_1'
			elseif check_progress <= 4 then
				character_util.set_direction(npc, 'left')
				scene_util.set_emotion(npc, self, 'sleep_deep')
				scene_util.set_anim(npc, self, 'eat')
				npc.Interactable.Talk = 'ss_clevatess_oneline_event_1_1'
			elseif check_progress <= 5 then
				character_util.set_direction(npc, 'left')
				scene_util.set_emotion(npc, self, 'sleep_deep')
				scene_util.set_anim(npc, self, 'eat')
				npc.Interactable.Talk = 'ss_clevatess_oneline_event_1_1'
			elseif check_progress <= 7 then
				character_util.set_direction(npc, 'left')
				scene_util.set_emotion(npc, self, 'tired')
				scene_util.set_anim(npc, self, 'eat')
				npc.Interactable.Talk = nil

				local event_npc = this:get_event_npc()
				character_util.set_direction(event_npc, 'down')
				character_util.remove_anim_and_emotion(event_npc)
				character_util.spine_set_alpha_fade_v2(event_npc, 0, 0)

				--건물 open
				local house = get_field_object('enhancement_house')
				local mesh = house.Transform:Find('mesh').gameObject

				mesh.transform:Find('open').gameObject:SetActive(true)
				mesh.transform:Find('close').gameObject:SetActive(false)

				this.can_event = true
			end
		end,
		init = function(this)
			local npc = this:get_npc()
			--왼쪽으로 0.5타일 이동 부탁드립니다.
			local pivot = vector(-0.5, 0, 0)

			character_util.set_position(npc, field_util.get_marker_pos(this.marker) + pivot)

			this:create_item()
			this:progress_setting()
		end
	})

	-- 밥 린다
	self.oneline_bob_linda = metatable_helper.inherit({
		bob_marker = 'oneline_bob_pos',
		linda_marker = 'oneline_linda_pos',
		zone = 'oneline_bob_linda_zone',
		show_event = true,
	}, {
		get_bob_npc = function()
			return get_character('oneline_bob_younger')
		end,
		get_linda_npc = function()
			return get_character('oneline_linda')
		end,
		set_event = function(this)
			local bob = this.get_bob_npc()

			character_util.set_position(bob, field_util.get_marker_pos(this.bob_marker))
			character_util.set_direction(bob, 'left')
			character_util.remove_anim_and_emotion(bob)

			local linda = this.get_linda_npc()

			character_util.set_position(linda, field_util.get_marker_pos(this.linda_marker))
			character_util.set_direction(linda, 'right')
			scene_util.set_emotion(linda, self, 'attack')
			character_util.remove_anim(linda)

			this.show_event = false
		end,
		dispose = function(this)
			local bob = this.get_bob_npc()

			speech_bubble_util.remove_bubble(bob)
			character_util.set_position(bob, vector(999, 0, 999))

			local linda = this.get_linda_npc()

			speech_bubble_util.remove_bubble(linda)
			character_util.set_position(linda, vector(999, 0, 999))

			this.show_event = true
		end
	})

	-- 특이한 무기 전문가
	self.oneline_weapon = metatable_helper.inherit({
		marker = 'oneline_weapon_pos',
		zone = 'oneline_weapon_zone',
		show_event = true,
		item = nil,
	}, {
		get_male_npc = function()
			return get_character('oneline_weapon_male')
		end,
		get_blacksmith_npc = function()
			return get_character('oneline_weapon_blacksmith')
		end,
		drop_item = function(this)
			this.item = quest_drop_item_util.create_item({
				item_id = 21704,
				pos = this:get_blacksmith_npc().Position,
				target = this.get_male_npc().Position,
				loot_state = quest_drop_item_loot_state.dont_find_looter,
				spr_scale = 0.6,
				skip_text = true
			})
		end,
		set_event = function(this)
			local male = this.get_male_npc()
			local blacksmith = this.get_blacksmith_npc()

			character_util.set_position(male,
					field_util.get_marker_pos(this.marker) + vector(-1, 0, 0))
			character_util.set_direction(male, 'right')
			character_util.remove_anim_and_emotion(male)

			character_util.set_position(blacksmith, field_util.get_marker_pos(this.marker))
			character_util.set_direction(blacksmith, 'left')
			character_util.remove_emotion(blacksmith)
			scene_util.set_anim(blacksmith, self, { name = 'cross_arm', one_shot_sfx = false })

			this.show_event = false
		end,
		dispose = function(this)
			if this.item ~= nil then
				quest_drop_item_util.dispose_item(this.item)
				this.item = nil
			end

			local male = this.get_male_npc()

			speech_bubble_util.remove_bubble(male)
			character_util.set_position(male, vector(999, 0, 999))

			local blacksmith = this.get_blacksmith_npc()

			speech_bubble_util.remove_bubble(blacksmith)
			character_util.set_position(blacksmith, vector(999, 0, 999))

			this.show_event = true
		end
	})

	self.oneline_set_destroy_item = metatable_helper.inherit({
		item_ids = { 21736, 21737 },
		items = nil,
		marker_name = 'pooled_npc_cursed_sword_pos_',
		offset = {
			--claw_drill : 위로 1타일 이동 왼쪽 0.5타일 이동
			vector(-0.5, 0, 1),
			--laser_cannon : 위로 1타일 이동
			vector(0, 0, 1)
		}
	}, {
		set_item = function(this)
			if this.items == nil then
				this.items = {}
			end

			for idx, item_id in pairs(this.item_ids) do
				local item = quest_drop_item_util.create_item({
					item_id = item_id,
					pos = field_util.get_marker_pos(this.marker_name .. idx) + this.offset[idx],
					loot_state = quest_drop_item_loot_state.dont_find_looter,
					spr_scale = 0.6
				})

				table.insert(this.items, item)
			end

		end,
		dispose = function(this)
			if this.items == nil then
				return
			end

			for i, item in ipairs(this.items) do
				quest_drop_item_util.dispose_item(item)
			end

			this.items = nil
		end
	})

	self.shadow_manager = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WaypointGuardDetectEvent))

	self.oneline_enhancement_npc:dispose()
	self.oneline_bob_linda:dispose()
	self.oneline_weapon:dispose()
	self.oneline_set_destroy_item:dispose()

	self.group_controller = nil
	self.quest_progress = nil
	self.cs_controller = nil
end

function local_class:load_resource()
	local is_create
	is_create, self.group_controller = global_table_util.try_create('Quest/ShortStory/Clevatess/Common/NpcPoolingGroupManager')

	if is_create then
		self.group_controller:initialize()
	end

	self.fx:load_async()

	self.esape_controller = get_or_create_global_table('Quest/ShortStory/Clevatess/Common/ClevatessBattleEscapeController')
	self.esape_controller:pre_load()

	self.revive_controller = get_or_create_global_table('Quest/ShortStory/Clevatess/Common/ClevatessReviveController')
	self.revive_controller:pre_load()

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.WaypointGuardDetectEvent), 'on_waypoint_guard_detect_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.oneline_enhancement_npc.can_event and
			type_util.is_zone_full_enter(e, get_party_leader(), self.oneline_enhancement_npc.zone) then
		self.oneline_enhancement_npc.can_event = false
		start_coroutine(self.show_oneline_enhancement_npc_scene, self)

		return true
	end

	if not self.oneline_bob_linda.show_event and
			type_util.is_zone_full_enter(e, get_party_leader(), self.oneline_bob_linda.zone) then
		self.oneline_bob_linda.show_event = true
		start_coroutine(self.show_bob_linda_scene, self)

		return true
	end

	if not self.oneline_weapon.show_event and
			type_util.is_zone_full_enter(e, get_party_leader(), self.oneline_weapon.zone) then
		self.oneline_weapon.show_event = true
		start_coroutine(self.show_weapon_scene, self)

		return true
	end

	return false
end

function local_class:on_stage_end_event(_)
	self.is_stage_end = true
	return true
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId ~= self.main_quest_id then
		return false
	end

	-- 검 강화
	if e.CurrentProgress <= 7 then
		self.oneline_enhancement_npc:progress_setting(e.CurrentProgress)
	end

	-- 밥 린다
	if e.CurrentProgress == 3 then
		self.oneline_bob_linda:set_event()
	else
		self.oneline_bob_linda:dispose()
	end

	-- 특이한 무기 전문가
	if e.CurrentProgress == 5 then
		self.oneline_weapon:set_event()

		self.current_level_of_sword = self.level_of_sword_name.day_3
	else
		self.oneline_weapon:dispose()
	end

	if e.CurrentProgress == 5 or e.CurrentProgress == 6 then
		self.oneline_set_destroy_item:set_item()
	else
		self.oneline_set_destroy_item:dispose()
	end

	return true
end

function local_class:on_interact_event(e)
	for index = 1, self.waypoint_guard_count do
		local guard = self.get_waypoint_guard(index)
		if guard.ActiveState ~= active_state_type.disabled and type_util.is_interacted_target(e, guard) then
			sp_util.start_scene(
					self.action_assassination, self, self.sword_name_prefix .. self.current_level_of_sword, guard)
		end
	end
end
function local_class:on_waypoint_guard_detect_event(e)
	if e.EventName == self.waypoint_guard_event_key then

		if self.shadow_manager == nil then
			self.shadow_manager = get_stage_event_controller('ClevatessShadowCloneController')
		end

		self.shadow_manager:reset_shadow_clone()

		sp_util.start_scene(function()
			self:detected_by_waypoint_guard(e.Target, e.Sender)
		end)
	end
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.quest_progress == nil or self.quest_progress.InnerProgress <= 7 then
		self.oneline_enhancement_npc:init()
	end

	if self.quest_progress == nil or self.quest_progress.InnerProgress == 6 then
		self.current_level_of_sword = self.level_of_sword_name.day_3
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress == 3 then
		self.oneline_bob_linda:set_event()
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress == 5 then
		self.oneline_weapon:set_event()
		self.oneline_set_destroy_item:set_item()
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress == 6 then
		self.oneline_set_destroy_item:set_item()
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 4 then
		self:open_blacksmith_door()
	end

	stage_start_util.start_function(self.quest_progress)
end

--검 강화
function local_class:show_oneline_enhancement_npc_scene()
	local npc_1 = self.oneline_enhancement_npc:get_npc()
	local npc_2 = self.oneline_enhancement_npc:get_event_npc()

	--1초 대기
	coroutine_util.while_each_frame(1, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--동시 연출 (async 아님)
	--2번 NPC 0.5초에 걸쳐 알파값 0에서 1까지 전환
	character_util.spine_set_alpha_fade_v2(npc_2, 1, 0.5)

	--2번 NPC (down, idle, walk) 1의 속도로 위 화살표 동선 이동
	--왼쪽으로 쭉 이동해서 카메라 그리드 밖으로 이동시 제거
	do
		field_ui_manager:RemoveUI(npc_2, CS.Oak.FieldUiType.CharacterStats)

		character_util.set_position(npc_2, npc_1.Position + vector(1.5, 0, 1))

		local move_pos = {
			npc_2.Position + vector(0, 0, -1.5),
			npc_2.Position + vector(-14, 0, -1.5),
			npc_2.Position + vector(-17, 0, -1.5),
		}

		npc_2.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		wp_util.move(npc_2, move_pos, 3, nil, { callback = function(waypoint_index)
			if waypoint_index == 1 then
				character_util.spine_set_alpha_fade_v2(npc_2, 0, 1)
			end
		end, end_callback = function()
			npc_2.Position = vector(999, 0, 999)
		end })
	end

	coroutine_util.while_each_frame(1, function()
		return not self.is_stage_end
	end)

	--위 연출 시작 1.5초(1번 NPC 아래로 0.5타일에 지나가는 시점) 다음 연출 진행
	--1번 NPC (left, attack, eat 정지)(shake (0.08, 0.5) 출력
	scene_util.set_emotion(npc_1, self, 'attack')
	scene_util.set_anim(npc_1, self, { name = 'eat', loop = false })
	scene_util.shake(npc_1, 0.08, 0.5)

	--1번 NPC 위치에 fx_hit 출력
	self.fx.hit():Instantiate(npc_1.Position + vector(0, 0.1, 0))

	--위 연출 시작 0.5초 후 a 스프라이트 fx_dead 출력과 함께 제거.
	coroutine_util.while_each_frame(0.5, function()
		return not self.is_stage_end
	end)

	music_player_util.play_sfx({
		sfx_name = '02_enhance_result_fail_02',
		loop = false,
		play_pos = self.oneline_enhancement_npc.item.Position
	})
	self.fx.dead():Instantiate(self.oneline_enhancement_npc.item.Position)

	quest_drop_item_util.dispose_item(self.oneline_enhancement_npc.item)

	self.oneline_enhancement_npc.item = nil

	scene_util.set_emotion(npc_1, self, 'tired')
	scene_util.set_anim(npc_1, self, 'seat')

	coroutine_util.while_each_frame(1, function()
		return not self.is_stage_end
	end)

	--1번 NPC (left, tired, seat): 하….
	scene_util.play_normal_speech_action(npc_1, self, 'left',
			{ name = 'seat', keep = true },
			{ name = 'tired', keep = true },
			{ key = 'ss_clevatess_oneline_event_1_2' })

	if self.is_stage_end then
		return
	end

	--1번 NPC 마지막 대사 원라인 대사로 진
	npc_1.Interactable.Talk = 'ss_clevatess_oneline_event_1_2'
	npc_1.Interactable.TalkSfx = '03_dialogue_bad_01'
end

function local_class:show_bob_linda_scene()
	local bob = self.oneline_bob_linda.get_bob_npc()
	local linda = self.oneline_bob_linda.get_linda_npc()

	--린다 (right, attack, idle): 내가 지원하지 말라고 했지?
	scene_util.show_normal_speech_async(linda, 'ss_clevatess_oneline_event_3_1', false)

	if self.is_stage_end then
		return
	end

	--밥 (left, attack, release 3회): 저도 같이 작전갈 거예요!
	scene_util.play_normal_speech_action(bob, self, 'left',
			{ name = 'release', count = 3 }, { name = 'attack', keep = true },
			{ key = 'ss_clevatess_oneline_event_3_3' })

	if self.is_stage_end then
		return
	end

	--린다 (right, tired, idle) 상태에서 (annoyed) 출력
	scene_util.set_emotion(linda, self, 'tired')
	character_util.show_emoticon_async(linda, nil, 'annoyed')

	if self.is_stage_end then
		return
	end

	--린다 (right, tired, bomb_idle): 어휴… 못살아.
	scene_util.set_anim(linda, self, 'bomb_idle')
	scene_util.show_normal_speech_async(linda, 'ss_clevatess_oneline_event_3_4', false)

	if self.is_stage_end then
		return
	end

	--린다 (right, tired, idle): 위험하니까 새 갑옷으로 하나 맞추자.
	scene_util.set_anim(linda, self, 'idle')
	scene_util.show_normal_speech_async(linda, 'ss_clevatess_oneline_event_3_5', false)

	if self.is_stage_end then
		return
	end

	--밥 (left, idle, cast): 저…
	scene_util.set_anim(bob, self, 'cast')
	character_util.remove_emotion(bob)
	scene_util.show_normal_speech_async(bob, 'ss_clevatess_oneline_event_3_6', false)

	if self.is_stage_end then
		return
	end

	--밥 (left, blush, cast): 선배 주려고 새 방어구를 사놨어요.
	scene_util.set_emotion(bob, self, 'blush')
	scene_util.show_normal_speech_async(bob, 'ss_clevatess_oneline_event_3_7', false)

	if self.is_stage_end then
		return
	end

	--린다 (right, blush, cast) (silence) 출력
	scene_util.set_emotion(linda, self, 'blush')
	scene_util.set_anim(linda, self, 'cast')
	character_util.show_emoticon_async(linda, nil, 'silence')

	if self.is_stage_end then
		return
	end

	--린다 (right, blush, cast): 정…말?
	scene_util.show_normal_speech_async(linda, 'ss_clevatess_oneline_event_3_8', false)

	if self.is_stage_end then
		return
	end

	--이후 원라인 대사 출력
	--밥 (left, blush, cast): 제가 지켜줄게요.
	bob.Interactable.Talk = 'ss_clevatess_oneline_event_3_9'
	--린다 (right, blush, cast): 나…도.
	linda.Interactable.Talk = 'ss_clevatess_oneline_event_3_10'
end

function local_class:show_weapon_scene()
	local male = self.oneline_weapon.get_male_npc()
	local blacksmith = self.oneline_weapon.get_blacksmith_npc()

	--8번 NPC(shortstory_ct_mercenary_male)(right, idle, idle): 묵직한 무기 없을까요?
	scene_util.show_normal_speech_async(male, 'ss_clevatess_oneline_event_4_1', false)

	if self.is_stage_end then
		return
	end

	--9번 NPC(shortstory_ct_blacksmith_a)(left, tired, cross_arm) 상태에서 (silence) 이모티콘 출력
	scene_util.set_emotion(blacksmith, self, 'tired')
	scene_util.set_anim(blacksmith, self, { name = 'cross_arm', one_shot_sfx = false })
	character_util.show_emoticon_async(blacksmith, nil, 'silence')

	if self.is_stage_end then
		return
	end

	--9번 NPC(shortstory_ct_blacksmith_a)(left, smile, idle) (notice)이모티콘 출력과 함께 normal_jump 1회 출력
	scene_util.set_emotion(blacksmith, self, 'smile')
	character_util.remove_anim(blacksmith)
	character_util.normal_jump(blacksmith, false)
	scene_util.play_emoticon_action(blacksmith, self,
			'left',
			nil,
			nil,
			'notice')

	if self.is_stage_end then
		return
	end

	--9번 NPC(shortstory_ct_blacksmith_a)(right, idle, eat) 1초간 출력
	music_player_util.play_sfx({
		sfx_name = '03_equipping_01',
		loop = true,
		play_pos = blacksmith.Position,
		duration = 1
	})

	character_util.set_direction(blacksmith, 'right')
	scene_util.set_anim(blacksmith, self, 'eat')
	coroutine_util.while_each_frame(1, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--동시 연출
	--9번 NPC(shortstory_ct_blacksmith_a)(left, smile, attack)
	character_util.set_direction(blacksmith, 'left')
	scene_util.set_emotion(blacksmith, self, 'smile')
	scene_util.set_anim(blacksmith, self, { name = 'attack', count = 1 })

	--9번 NPC y축 최대 1의 높이까지 tuna_twohand_sword(0.6배) 아이템 1초에 걸쳐 포물선 이동
	--tuna_twohand_sword 시계 반대 방향으로 1초에 걸쳐 720도 회전
	--tuna_twohand_sword y축 0되면 fx_get 이펙트와 함께 사라짐
	music_player_util.play_sfx({
		sfx_name = '01_air_spin_01',
		loop = false,
		play_pos = blacksmith.Position
	})
	self.oneline_weapon:drop_item()

	coroutine_util.while_each_frame(1.5, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--0.5초 대기
	music_player_util.play_sfx({
		sfx_name = '03_get_drop_item_01',
		loop = false,
		play_pos = self.oneline_weapon.item.Position
	})
	self.fx.get():Instantiate(self.oneline_weapon.item.Position)

	quest_drop_item_util.dispose_item(self.oneline_weapon.item)

	self.oneline_weapon.item = nil

	if self.is_stage_end then
		return
	end

	--9번 NPC(shortstory_ct_mercenary_male)(right, idle, sword_idle)(tuna_twohand_sword 착용 상태)
	scene_util.set_emotion(male, self, 'idle')
	scene_util.set_anim(male, self, 'sword_idle')
	character_util.spine_set_attachment(male, '[base]weapon1', 'tuna_twohand_sword')

	--0.5초 대기
	coroutine_util.while_each_frame(0.5, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--8번 NPC(shortstory_ct_mercenary_male)(right, tired, sword_idle)(tuna_twohand_sword 착용 상태): 이거 무기 같진 않은데요?
	scene_util.show_normal_speech_async(male, 'ss_clevatess_oneline_event_4_3', false)

	if self.is_stage_end then
		return
	end

	--9번 NPC*shortstory_ct_blacksmith_a)(left, smile, release 2회 후 cross_arm)
	character_util.set_direction(blacksmith, 'left')
	scene_util.set_emotion(blacksmith, self, 'smile')
	scene_util.set_anim(blacksmith, self, { name = 'release', count = 2, loop = false, next_anim = 'cross_arm' })

	coroutine_util.while_each_frame(1, function()
		return not self.is_stage_end
	end)

	scene_util.set_anim(blacksmith, self, 'cross_arm')

	--0.5초 대기
	coroutine_util.while_each_frame(0.5, function()
		return not self.is_stage_end
	end)


	--8번 NPC(shortstory_ct_mercenary_male)(left, tired, twohand_attack)
	scene_util.set_anim(male, self, { name = 'twohand_attack', loop = false, next_anim = 'sword_idle' })

	--위 연출 시작 0.5초 뒤에 동시 출력
	coroutine_util.while_each_frame(0.5, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--9번 NPC 위치에 FX_IceRidge 로테이션(0, 90, 0)
	local effect_pos = blacksmith.Position + vector(-1, 0, 0)
	music_player_util.play_sfx({ sfx_name = '02_ice_ridge_03', play_pos = effect_pos })
	local fx_ice_ridge = self.fx.ice_ridge():Instantiate(effect_pos)
	fx_ice_ridge.transform.localRotation = unity_class.quaternion.Euler(0, 90, 0)

	--9번 NPC 파란색(R95, G123, B245) 틴트 100%출력
	character_util.add_color(blacksmith, blacksmith.Name, unity_color({ 0.372, 0.48, 0.957, 1 }), 1, 0)

	--9번 NPC 표정만 (surprise)로 전환
	--scene_util.set_emotion(blacksmith, self, 'surprise')

	--9번 NPC 정지 상태
	character_util.set_anim_time_scale(blacksmith, 0)

	--위 연출 모두 완료되면 0.5초 대기
	coroutine_util.while_each_frame(0.5, function()
		return not self.is_stage_end
	end)

	if self.is_stage_end then
		return
	end

	--이후 원라인 대사 세팅
	--8번 NPC(shortstory_ct_blacksmith_b)(right, smile, twohand_idle): 계산이요!
	scene_util.set_emotion(male, self, 'smile')
	male.Interactable.Talk = 'ss_clevatess_oneline_event_4_4'
	male.Interactable.TalkSfx = '03_dialogue_emphasize_01'
end

function local_class:action_assassination(weapon_name, target_npc)
	local leader = get_party_leader()

	target_npc.FieldObjectController = CS.Oak.NPCCharacterController()

	--지보가 수리된 시점에 퀘스트 프로그래스 적용하여, 하수인 인터렉트 활성화된다.
	--하수인 인터렉트시, 즉시 플레이어 컨트롤 빼앗는다.
	--0.2초에 걸쳐 현재 단계의 지보 장착한다.
	character_util.spine_set_attachment(leader, '[base]weapon1]', weapon_name)

	scene_util.show_weapon(leader)

	scene_util.set_anim(leader, self, 'sword_idle')

	--암살 시 플레이어 컨트롤 뻇고 효과음 재생
	music_player_util.play_sfx_one_shot('02_assassinate_01')

	wait_for_sec(0.2)

	--동시 실행 async
	do
		local duration = 0.5

		--0.5초에 걸쳐 플레이어 스파인 인터렉트한 하수인 위치로 정렬
		character_util.look_at(leader, target_npc)
		local dir = character_util.get_look_direction(leader)
		local opposite_dir = direction_util.get_opposite(dir)

		local vec = direction_util.to_4way_vector3(opposite_dir)

		wp_util.move(leader, target_npc.Position + vec, nil, duration, { locked_dir = dir })

		--카메라 포커스 0.3초에 걸쳐 인터렉트한 하수인 위치로 이동
		camera_util.move(target_npc.Position, duration)

		--카메라 줌 인 (3.0, 0.5)
		camera_util.resize_by_ratio(3.0, duration)
	end

	--2일차 : broken_jibo_2
	--3일차 : broken_jibo_3
	--플레이어 (현재 방향, attack, twohand_attack4 1회 실행, 마지막 프레임 유지 (0.5초))
	scene_util.set_emotion(leader, self, 'attack')
	scene_util.set_anim(leader, self, { name = 'twohand_attack4', loop = false })

	wait_for_sec(1.25)

	music_player_util.play_sfx_one_shot('02_clevatess_cwp_ready_01')

	--sfx 타이밍에 맞추어 아래 연출 동시 실행
	--대상 위치에 fx_ct_gibo_space_cracked_start_loop 출력
	local loop_fx = self.fx.gibo_assassination():Instantiate(target_npc.Position)

	--하수인 (바라보고 있는 방향, damaged, embarrassed)
	scene_util.set_emotion(target_npc, self, 'damaged')
	scene_util.set_anim(target_npc, self, 'embarrassed')

	--화면 shake (0.15, 0.2)
	camera_util.shake(0.15, 0.2)

	do
		local duration = 0.3

		--카메라 포커스 0.3초에 걸쳐 플레이어 위치로 이동
		camera_util.resize_to_default(duration)

		--카메라 줌 아웃 (4.0, 0.3)
		camera_util.return_to_leader(duration)
	end

	--인터렉트한 하수인 npc waypointguard 컴포넌트 제거
	--하수인 npc 0.5초간 360도 회전
	character_util.spine_rotate(target_npc, 360, 0.5)

	--하수인 npc 0.3초에 걸쳐 스파인 크기 0으로 줄어든다.
	character_util.spine_scale(target_npc, unity_class.vector3.zero, 0.3)

	--하수인 npc 0.3초에 걸쳐 알파값 페이드아웃된다.
	character_util.add_color(target_npc, target_npc.Name, unity_class.color.black, 1, 0.3)

	wait_for_sec(0.3)

	character_util.set_position(target_npc, vector(999, 0, 999))

	field_object_util.set_active_state(target_npc, active_state_type.disabled)
	character_util.spine_scale(target_npc, unity_class.vector3.one, 0)
	character_util.remove_color(target_npc, target_npc.Name, 0)
	character_util.remove_anim_and_emotion(target_npc)

	--해당 위치 하수인 npc 소멸
	--플레이어 표정, 애니 원복 후 컨트롤 돌려줍니다.
	character_util.remove_anim_and_emotion(leader)
	character_util.spine_remove_attachment(leader, '[base]weapon1]')

	scene_util.hide_weapon(leader)
end

function local_class:detected_by_waypoint_guard(leader, waypoint_guard)
	local reset_pos = field_util.get_marker_pos(waypoint_guard.FieldObjectController.ResetMarkerName)
	local detect_talk = lua_helper.get_or_default(waypoint_guard.FieldObjectController.DetectTalk,
			'ss_clevatess_puzzle_02')

	local klen = user_party[1]
	local neruru = user_party[2]

	local wg_org_pos = waypoint_guard.Position
	local wg_org_dir = waypoint_guard.Direction

	local attack_range = waypoint_guard.FieldObjectController.AttackRange

	--하수인에게 노출당할 경우
	--동시 연출
	do
		--알리시아 (하수인 방향, scared, idle) 출력
		character_util.look_at(leader, waypoint_guard)
		scene_util.set_emotion(leader, self, 'scared')

		--클렌 (하수인 방향, idle, idle)
		if klen ~= nil then
			character_util.look_at(klen, waypoint_guard)
		end
		if neruru ~= nil then
			character_util.look_at(neruru, waypoint_guard)
			scene_util.set_emotion(neruru, self, 'scared')
		end

		--기존 스트링 사용
		--하수인 (적발 방향, idle, release 2회): 인간이다!
		character_util.look_at(waypoint_guard, leader)
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		start_coroutine(function()
			scene_util.play_normal_speech_action(waypoint_guard, self, nil,
					{ name = 'release', count = 2 }, nil, { key = detect_talk, skip = false })
		end)
	end

	local leader_detected_dir = leader.Direction
	local wg_detected_dir = waypoint_guard.Direction

	--위 연출 시작 0.3초 후
	wait_for_sec(0.3)

	--아래 그룹 연출 순서대로 진행

	--클렌 위치에 fx_ct_klen_shadow_start_loop 0.3초에 걸쳐 스케일 0에서 1크기로 조절
	local klen_effect_loop
	local neruru_effect_loop
	if klen ~= nil or neruru ~= nil then
		if klen ~= nil then
			klen_effect_loop = self.fx.klen_effect():Instantiate(klen.Position + vector(0, 0.03, 0))
			klen_effect_loop.transform.localScale = vector(0, 0, 0)
		end

		if neruru ~= nil then
			neruru_effect_loop = self.fx.klen_effect():Instantiate(neruru.Position + vector(0, 0.03, 0))
			neruru_effect_loop.transform.localScale = vector(0, 0, 0)
		end

		local duration = 0.1
		local time_passed = 0
		local target_scale = vector(1, 1, 1)
		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime
			local progress = time_passed / duration

			if klen ~= nil then
				klen_effect_loop.transform.localScale = progress * target_scale
			end

			if neruru ~= nil then
				neruru_effect_loop.transform.localScale = progress * target_scale
			end
			coroutine.yield(nil)
		end

		if klen ~= nil then
			klen_effect_loop.transform.localScale = target_scale
		end

		if neruru ~= nil then
			neruru_effect_loop.transform.localScale = target_scale
		end
	end

	--클렌, 현재 상태에서 검은색 틴트 0.3초에 걸쳐 0에서 1까지 출력
	if klen ~= nil then
		character_util.add_color(klen, klen.Name, unity_class.color.black, 1, 0.1)
	end
	if neruru ~= nil then
		character_util.add_color(neruru, neruru.Name, unity_class.color.black, 1, 0.1)
	end

	wait_for_sec(0.1)

	--클렌, 0.3초에 걸쳐 y축 -1.2위치로 전환
	do
		local move_key = 'clevatess_detect_move'
		if klen ~= nil then
			scene_util.set_anim(klen, self, 'idle')
			wp_util.move_with_end_callback(klen, vector_util.get_x0z(klen.Position, -1.5), nil, 0.1, self, move_key)
		end

		if neruru ~= nil then
			scene_util.set_anim(neruru, self, 'idle')
			wp_util.move_async(neruru, vector_util.get_x0z(neruru.Position, -1.5), nil, 0.1, self, move_key)
		end

		if klen ~= nil or neruru ~= nil then
			wp_util.wait_move_end(self, move_key)
		end
	end

	-- fx_ct_klen_shadow_start_loop 0.3초에 걸쳐 스케일 1에서 0크기로 조절

	if klen ~= nil or neruru ~= nil then
		do
			local duration = 0.1
			local time_passed = 0
			local target_scale = vector(1, 1, 1)
			while time_passed < duration do
				time_passed = time_passed + unity_class.time.deltaTime
				local progress = time_passed / duration

				if klen ~= nil then
					klen_effect_loop.transform.localScale = (1 - progress) * target_scale
				end
				if neruru ~= nil then
					neruru_effect_loop.transform.localScale = (1 - progress) * target_scale
				end
				coroutine.yield(nil)
			end
			if klen ~= nil then
				klen_effect_loop.transform.localScale = vector(0, 0, 0)
			end
			if neruru ~= nil then
				neruru_effect_loop.transform.localScale = vector(0, 0, 0)
			end
		end
	end

	--위 연출 모두 완료되면 아래 연출 진행
	if klen_effect_loop ~= nil then
		klen_effect_loop:Dispose()
		klen_effect_loop = nil
	end

	if neruru_effect_loop ~= nil then
		neruru_effect_loop:Dispose()
		neruru_effect_loop = nil
	end

	--해당 하수인 경계 범위 출력 제거
	attack_range:Hide()

	--동시 연출
	wait_all_lua(
			function()
				--하수인 (적발 방향, idle, run) 5의 속도로 플레이어 0.5타일 간격으로 이동
				character_util.set_direction(waypoint_guard, wg_detected_dir)
				scene_util.set_anim(waypoint_guard, self, 'run')

				--알리시아 (위 아래 일경우 left 출려, damaged, embrassed) 출력
				if leader_detected_dir == direction_constants.right then
					character_util.set_direction(leader, 'right')
				else
					character_util.set_direction(leader, 'left')
				end

				scene_util.set_emotion(leader, self, 'damaged')
				scene_util.set_anim(leader, self, 'embarrassed')

				local start_pos = waypoint_guard.Position
				local end_pos = leader.Position + direction_util.to_vector3(leader_detected_dir) * 0.5

				local time_passed = 0
				local distance = (end_pos - start_pos).magnitude
				--local speed = 5
				local duration = 0.5
				while time_passed < duration do
					time_passed = time_passed + unity_class.time.deltaTime
					local progress = unity_class.mathf.Clamp01(time_passed / duration)
					local cur_pos = progress * end_pos + (1 - progress) * start_pos
					character_util.set_position(waypoint_guard, cur_pos)

					coroutine.yield(nil)
				end

				character_util.set_position(waypoint_guard, end_pos)
			end,
			function()
				--카메라 0.5초에 걸쳐 서큘러 페이드 아웃
				screen_util.fade_out_circular_async(0.5)
			end
	)

	--알리시아 리셋 위치에 (right, tired, prostrate) 출력
	scene_util.set_emotion(leader, self, 'tired')
	scene_util.set_anim(leader, self, 'prostrate')
	party_util.position_party(reset_pos, 'right', 'linear')

	--알리시아 왼쪽 1타일 간격에 클렌 (right, idle, idle) 출력
	if klen ~= nil then
		scene_util.set_direction(klen, 'left', false)
		character_util.remove_anim_and_emotion(klen)
		character_util.remove_color(klen, klen.Name, 0)
		klen.Position = leader.Position + vector(1, 0, 0)
	end

	--네루루 있었으면
	if neruru ~= nil then
		scene_util.set_direction(neruru, 'right', false)
		character_util.remove_anim_and_emotion(neruru)
		character_util.remove_color(neruru, neruru.Name, 0)
		neruru.Position = leader.Position + vector(-1, 0, 0)
	end

	--(CODE) 웨이포인트 가드 원위치
	waypoint_guard.Position = wg_org_pos
	character_util.set_direction(waypoint_guard, wg_org_dir)
	character_util.remove_anim_and_emotion(waypoint_guard)
	speech_bubble_util.remove_bubble(waypoint_guard)
	attack_range:Show()

	--카메라 알리시아 포커스로 이동
	camera_util.return_to_leader(0)

	--1초 대기
	wait_for_sec(1)

	--화면 1초에 걸쳐 서큘러 fade in
	screen_util.fade_in_circular_async(1)

	--클렌 (left, idle, idle): 언제까지 누워있을 거지? (ss_clevatess_catch 스트링 사용)
	if klen ~= nil then
		scene_util.play_normal_speech_action(klen, self, 'left',
				nil, nil, 'ss_clevatess_catch')
	end

	--알리시아 (right, damaged, prostrate) shake(0.03, 지속)
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.set_direction(leader, 'right', false)
	scene_util.set_emotion(leader, self, 'damaged')
	scene_util.set_anim(leader, self, 'prostrate')
	character_util.shake(leader, 0.03, 999)

	--0.5초 대기
	wait_for_sec(0.5)

	start_coroutine(function()
		music_player_util.play_sfx_one_shot('02_break_wood_02')
		scene_util.play_normal_speech_action(leader, self, nil,
				nil, nil, { key = 'ss_clevatess_main_s2_10_3', skip = false })
	end)

	--아래 연출 순번대로 진행

	local pivot_pos = leader.Position + vector(0, 0.03, 0)

	camera_util.shake(0.05, 1)

	--알리시아 위치에 fx_hit 출력
	music_player_util.play_sfx_one_shot('02_hit_big_01')
	self.fx.hit():Instantiate(pivot_pos)

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x +0.2, z +0.5) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(0.2, 0, 0.5))

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x -0.2 z +0.2) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(-0.2, 0, 0.2))

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x +0.3, z +0.2) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(0.3, 0, 0.2))

	--위 연출 시작 0.1초 후 알리시아 위치에 FX_heal_a 출력
	wait_for_sec(0.1)

	music_player_util.play_multiple_sfx_one_shot('02_magic_heal_04', '02_break_wood_02')
	self.fx.heal():Instantiate(leader.Bounds.center + vector(0, 0, -0.5))

	--위 연출 시작 0.2초 후
	wait_for_sec(0.2)
	--알리시아 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos)

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x +0.2, z +0.5) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(0.2, 0, 0.5))

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x -0.2 z +0.2) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(-0.2, 0, 0.2))

	--위 연출 시작 0.1초 후
	wait_for_sec(0.1)
	--알리시아 위치 기준 (x +0.3, z +0.2) 위치에 fx_hit 출력
	self.fx.hit():Instantiate(pivot_pos + vector(0.3, 0, 0.2))

	--위 연출 시작 0.1초 후 알리시아 위치에 FX_heal_a 출력
	wait_for_sec(0.1)
	music_player_util.play_sfx_one_shot('02_magic_heal_04')
	self.fx.heal():Instantiate(leader.Bounds.center + vector(0, 0, -0.5))

	--위 연출 완료되면 0.5초 대기
	wait_for_sec(0.5)

	--알리시아 (right, tired, prostrate) 출력
	scene_util.set_direction(leader, 'right', false)
	scene_util.set_emotion(leader, self, 'tired')
	scene_util.set_anim(leader, self, 'prostrate')

	wait_for_sec(1)

	--shake 제거
	character_util.stop_shake(leader)

	--0.5초 대기
	wait_for_sec(0.5)

	--알리시아 (right, tired, idle) mix duration 1초 출력
	music_player_util.play_sfx_one_shot('01_player_popup_01')
	scene_util.set_direction(leader, 'right', false)
	scene_util.set_emotion(leader, self, 'tired')
	character_util.mario_jump_async(leader, 'right')

	character_util.remove_anim_and_emotion(leader)

	--0.5초 대기
	wait_for_sec(0.5)

	--이후 컨트롤 해제
end

function local_class:open_blacksmith_door()
	--스미스 작업실 [gimmick]smithy2의 mesh, open만 활성화
	--4섹션 이후 현재 상태 지속 유지
	local house = get_field_object('s4_blacksmith_house')
	local mesh = house.Transform:Find('mesh').gameObject

	mesh.transform:Find('open').gameObject:SetActive(true)
	mesh.transform:Find('close').gameObject:SetActive(false)
end

return local_class
