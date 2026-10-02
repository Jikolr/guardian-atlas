local local_class = newclass('LaboseWorld2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 386
	self.sub_1_quest_id = 401

	self.check_event_zone_names = {
		roof_top_area_1 = 's8_off_blur_effect_1',
		roof_top_area_2 = 's8_off_blur_effect_2',
		s7_second_battle_zone = 's7_battle_2',
		battle_zone_4 = 's8_battle_4',
	}

	self.characters = {
		demon_engineer   = function() return get_character('demon_engineer') end,
		demon_queen      = function() return get_character('demon_queen') end,
		-- 섹션7 경찰 npc 팔로워들
		all_polices      = function()
			return get_characters_with_name_format('s7_police_%d', 6)
		end,

		event_battle_labose_creature	= function(scene, idx)
			return get_character('s8_' .. scene .. '_battle_labose_creature_' .. idx)
		end,
	}

	-- 우측에서 나타나 마지막 이벤트 전 배틀의 2번째  진행하는 라보스들 마커를 위한 이전 노멀 라보스 수
	self.chase_labose_creatures_normal_count = 8

	-- marker
	self.markers = {
		-- 우측에서 나타나 마지막 이벤트 전 배틀의 2번째  진행하는 라보스들
		event_battle_labose_creature      = function(char_idx, scene_pos_idx, move_pos_idx)
			if self.chase_labose_creatures_normal_count >= char_idx then
				return field_util.get_marker_pos('s8_battle_4_labose_normal_' .. char_idx .. '_' .. scene_pos_idx .. '_' .. move_pos_idx)
			end

			return field_util.get_marker_pos('s8_battle_4_labose_ogre_' .. (char_idx - self.chase_labose_creatures_normal_count) .. '_' .. scene_pos_idx .. '_' .. move_pos_idx)
		end,
	}

	-- 섹션7 클리어 후 경찰들 처리(추후 생존 여부에 따른 처리도 해야함)
	-- all after 마지막에 배치될 경찰들의 anim, emo
	self.s7_police_anim_emotion_data = {
		{
			anim = 'bomb_idle',
			emo = 'attack'
		},
		{
			anim = 'release',
			emo = 'attack'
		},
		{
			anim = 'cross_arm',
		},
		{
			anim = 'cast2',
			emo = 'attack'
		},
		{
			anim = 'cast',
			emo = 'sleep_deep'
		},
		{
			anim = 'bomb_idle',
		},
	}

	-- field object
	self.field_object = {
		s8_rock_wall   = function(idx) return get_field_object('s8_rock_' .. idx) end,
		s7_event4_wall   = function(idx) return get_field_object('s7_event_4_interact_obj_' .. idx) end,
	}

	self.meet_my_party_after_sub_1_event_clear = false

	-- s7 - 구출에 실패한 경찰 인덱스 (1, 4, 5번은 강제로 구하는 이벤트로 구해짐)
	self.rescued_police_index_list = { 1, 4, 5 }

	self.s7_second_rescue_police_indexes = {
		2, 3
	}

	self.s7_fourth_rescue_police_indexes = {
		6
	}

	self.scene_version = scene_util.default_version

	self.fx = {
		cached_inst = {},

		virus_fog_strong = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong')
		end,

		slime_buttbounce = function()
			return unity_object_pool.GetOrCreate('FX_slime_buttbounce')
		end,

		cache = function(this, fx)
			if this.cached_inst ~= nil then
				table.insert(this.cached_inst, fx)
			end
		end,

		load_all = function(this)
			for name, load_func in pairs(this) do
				if type_util.is_function(load_func) and
						name ~= 'load_all' and
						name ~= 'cache' and
						name ~= 'dispose' then

					load_func()
				end
			end
		end,

		dispose = function(this)
			for i = 1, #this.cached_inst do
				this.cached_inst[i]:Dispose()
				this.cached_inst[i] = nil
			end

			this.cached_inst = nil
		end
	}

	self.labose_effect_sfx = nil

	self.gimmicks = {
		labose_effect_sfx_pivot			= function()
			return get_field_object('labose_effect_sfx_pivot')
		end,
	}


	-- 4번째 전투에서 추가되는 라보스 무리들 상태
	self.battle_4_enemy_pos_states = {
		pre_battle_pos = 2,
		second_battle_wave = 3,
	}

	-- 4번째 전투에서 추가되는 라보스 무리들 리스트
	self.chase_labose_creatures_count = 5

	self.util = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self.cs_controller = nil
	self.scene = nil

	self.fx:dispose()

	if self.labose_effect_sfx ~= nil then
		self.labose_effect_sfx:Stop()
		self.labose_effect_sfx = nil
	end

	self.rescued_police_index_list = nil

	self.util = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx:load_all()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_enter(e, leader, self.check_event_zone_names.roof_top_area_1) or
			type_util.is_zone_full_enter(e, leader, self.check_event_zone_names.roof_top_area_2) then

		start_coroutine(self.control_roof_top_effect, self)

		return true
	elseif type_util.is_zone_full_enter(e, leader, self.check_event_zone_names.s7_second_battle_zone) then

		start_coroutine(self.convert_labose_npc_to_monster, self, get_character('s7_battle_2_ogre_1'), 's7_battle_2')

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_leave(e, leader, self.check_event_zone_names.roof_top_area) then
		return true
	end

	return false
end

function local_class:on_battle_group_wave_clear_event(e)
	local current_wave = e.CurrentWave
	local max_wave = e.MaxWaveCount

	local has_next_wave = current_wave < max_wave

	-- 다음 웨이브가 있다면, 소환 후 탈출
	if has_next_wave then
	end

	return true
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 's8_battle_4' then
		local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

		if quest_progress.InnerProgress >= 9 then
			-- 현재 배틀 강제 종료
			stage.BattleManager:ForceEndBattles()
		end
	end

	return false
end

function local_class:on_battle_group_wave_clear_event(e)
	local current_wave = e.CurrentWave
	local max_wave = e.MaxWaveCount

	local has_next_wave = current_wave < max_wave

	-- 다음 웨이브가 있다면, 소환 후 탈출
	if has_next_wave then
		message_system:PublishSync(CS.Oak.BattleGroupSpawnNextWaveEvent.Create('s8_battle_4'))

		start_coroutine(self.start_battle_4_second_wave, self)
	end

	return true
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == 's8_area_in' then
		start_coroutine(self.change_stage_bgm, self, 'ondemand/v2_86_laboseworld/audio:bgm_laboseworld_main')

		return true
	elseif e.ExitHandleName == 's8_area_out' then
		start_coroutine(self.change_stage_bgm, self, 'ondemand/v2_75_civilwar/audio:bgm_civilwar_labose')

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

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.util = get_or_create_global_table('Quest/Main/LaboseWorld/Common/Util')

	-- 리리스 기본 표정 tired 로 변경
	local queen = get_character('demon_queen')
	queen.SpineController:SetCustomDefaultEmotion('tired')
	character_util.remove_emotion(queen)

	do
		local npc_infos = {
			{
				name = 'vampire_captain',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_vampirecaptain',
					},
				},
				custom_anim = {
					run = 'vampire_captain/run',
					walk = 'vampire_captain/walk',
					idle = 'vampire_captain/idle',
				}
			},
			{
				name = 'sheep_girl',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_sheepgirl',
					},
				},
				custom_anim = {
					run = 'katana_run',
					walk = 'katana_walk',
					idle = 'katana_idle',
				}
			},
			{
				name = 'desert_slave',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_desertslave',
					},
					{
						bone = '[base]weapon2',
						sprite = 'cwp_desertslave',
					},
				},
				custom_anim = {
					run = 'gauntlet_run',
					walk = 'gauntlet_walk',
					idle = 'gauntlet_idle',
				}
			},
			{
				name = 'china_hero_boy',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_china',
					},
					{
						bone = '[base]weapon2',
						sprite = 'cwp_china',
					},
				},
				custom_anim = {
					run = 'gauntlet_run',
					walk = 'gauntlet_walk',
					idle = 'gauntlet_idle',
				}
			},
			{
				name = 'china_hero_girl',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_china',
					},
					{
						bone = '[base]weapon2',
						sprite = 'cwp_china',
					},
				},
				custom_anim = {
					run = 'gauntlet_run',
					walk = 'gauntlet_walk',
					idle = 'gauntlet_idle',
				}
			},
			{
				name = 'ghost_buster',
				attachments = {
					{
						bone = '[base]weapon1',
						sprite = 'cwp_ghostbuster',
					},
				},
				custom_anim = {
					run = 'rifle_run',
					walk = 'rifle_walk',
					idle = 'rifle_idle',
				}
			},
		}

		for _, info in pairs(npc_infos) do
			local npc = get_character(info.name)

			for _, attachment in pairs(info.attachments) do
				character_util.spine_set_attachment(npc, attachment.bone, attachment.sprite)
			end

			npc.CustomIdleAnimationName = info.custom_anim.idle
			npc.CustomWalkAnimationName = info.custom_anim.walk
			npc.CustomRunAnimationName = info.custom_anim.run

			character_util.stop(npc)
		end
	end

	-- 10섹션 이상일 때에는 npc 세팅
	if quest_progress.InnerProgress >= 9 then
		self:set_one_line_npc(quest_progress)

		local rock_count = 3
		for i = 1, rock_count do
			local rock = self.field_object.s8_rock_wall(i)

			rock.ActiveState = active_state('disabled')
		end

		for i = 1, self.chase_labose_creatures_count do
			local npc = self.characters.event_battle_labose_creature(4, i)

			if npc ~= nil and npc.FieldObjectStatsBehaviour ~= nil then
				npc.FieldObjectStatsBehaviour.NoticeLinkName = ''
			end

			character_util.set_active_state(npc, 'disabled')
		end

		self:place_s7_polics_npcs_all_after()

		self:control_event_door()
		self:change_s7_event4_wall_off_state()
	elseif quest_progress.InnerProgress >= 7 then
		self:set_one_line_npc(quest_progress)

		self:control_event_door()
		self:change_s7_event4_wall_off_state()

		self:place_s7_polics_npcs_all_after()
	elseif quest_progress.InnerProgress >= 6 and quest_progress.InnerProgress < 7 then
		character_util.set_emotion(get_character('demon_queen'), { name = 'tired' })
	elseif quest_progress.IsComplete then
		self:place_s7_polics_npcs_all_after()

		self:control_event_door()
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		music_player_util.set_stage_music_clip_async(
				{ name = 'ondemand/v2_86_laboseworld/audio:bgm_laboseworld_main', state = 'field' }
		)

		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('second_area_in'),
				true, true)
	elseif quest_progress.InnerProgress == 4 or quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start')
		, true, true)
	elseif quest_progress.InnerProgress == 6 then
		local start_pos_name = self:get_s7_party_pos_marker_name()

		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos(start_pos_name)
		, true, true)
	elseif quest_progress.InnerProgress == 7 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s8_start')
		, true, true)
	elseif quest_progress.InnerProgress == 8 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s9_start_pos_1')
		, false, false)
	else
		music_player_util.set_stage_music_clip_async(
				{ name = 'ondemand/v2_86_laboseworld/audio:bgm_laboseworld_main', state = 'field' }
		)

		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('second_area_in'),
				true, true)
	end
end

function local_class:set_one_line_npc(quest_progress)
	-- 데몬 월드 진영
	local demon_world_group = { get_character('demon_queen') }

	for i = 1, #demon_world_group do
		local npc = demon_world_group[i]
		scene_util.set_direction(npc, 'left', false)
		character_util.set_position(npc, field_util.get_marker_pos('s9_demon_world_pos_' .. i))
		character_util.set_active_state(npc, 'enabled')
		scene_util.hide_weapon(npc)
		message_system:SendSync(npc, CS.Oak.CharacterBehaviourResetEvent.Instance)
	end

	-- 챔피언 진형
	local champion_group = { get_character('ghost_buster')
	, user_util.get_china_hero_character('china_hero_boy', 'china_hero_girl')
	, get_character('desert_slave') }

	for i = 1, #champion_group do
		local npc = champion_group[i]
		character_util.set_position(npc, field_util.get_marker_pos('s9_champion_pos_' .. i))
		character_util.set_active_state(npc, 'enabled')
		scene_util.hide_weapon(npc)
		message_system:SendSync(npc, CS.Oak.CharacterBehaviourResetEvent.Instance)
	end

	local is_fei = user_util.has_fei()

	-- 9섹션에서 선택한 선택지에 따라 원라인이 달라짐
	local before_choose_state = quest_util.get_custom_state(quest_progress, 's9_champion_choose_result')

	if before_choose_state > 0 then
		-- 소히(sleep_deep, cast) : 프리실라를 만난 게 정말 다행이었어.
		character_util.set_direction(champion_group[1], 'left')
		character_util.set_anim_and_emotion(champion_group[1], { name = 'cast' }, { name = 'tired' })
		champion_group[1].Interactable.Talk = 'lw_main_stage2_interact_1_5'

		-- 페이(attack, idle) : 반드시 다시 모일 수 있을 것이오!
		-- 메이(attack, idle) : 다같이 살아서 만날 수 있을 거야.
		character_util.set_direction(champion_group[2], 'left')
		character_util.set_emotion(champion_group[2], { name = 'attack' })
		champion_group[2].Interactable.Talk = is_fei and 'lw_main_stage2_interact_1_6' or 'lw_main_stage2_interact_1_7'

		-- 마빈(idle, idle) : 다들 무사할 테니 너무 걱정하지 마라.
		character_util.set_direction(champion_group[3], 'left')
		champion_group[3].Interactable.Talk = 'lw_main_stage2_interact_1_8'
	else
		-- 소히(mad, cast2) : 야, 고릴라! 우리 걱정은 안 한 거야?
		character_util.set_direction(champion_group[1], 'left')
		character_util.set_anim_and_emotion(champion_group[1], { name = 'cast2' },
				{ name = 'mad' })
		champion_group[1].Interactable.Talk = 'lw_main_stage2_interact_1_1'

		-- 페이(right, tired, idle) : 너무 그러지 마시오, 사제도 얼마나 지쳤겠소…
		character_util.set_direction(champion_group[2], 'right')
		character_util.set_emotion(champion_group[2], { name = 'tired' })
		champion_group[2].Interactable.Talk = is_fei and 'lw_main_stage2_interact_1_2' or
				'lw_main_stage2_interact_1_3'

		-- 마빈(idle, bomb_idle) : 걱정말고 나아가라, 가디언.
		character_util.set_direction(champion_group[3], 'left')
		character_util.set_anim(champion_group[3], { name = 'bomb_idle' })
		champion_group[3].Interactable.Talk = 'lw_main_stage2_interact_1_4'
	end

	local second_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_second_rescue_event')
	local fourth_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_fourth_rescue_event')

	if second_rescue_event_state > 0 then
		for i = 1, #self.s7_second_rescue_police_indexes do
			table.insert(self.rescued_police_index_list, self.s7_second_rescue_police_indexes[i])
		end
	end

	if fourth_rescue_event_state > 0 then
		for i = 1, #self.s7_fourth_rescue_police_indexes do
			table.insert(self.rescued_police_index_list, self.s7_fourth_rescue_police_indexes[i])
		end
	end
end

function local_class:get_s7_party_pos_marker_name()
	local start_pos_marker_name = 's7_start_1'
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	local second_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_second_rescue_event')
	local third_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_third_rescue_event')
	local fourth_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_fourth_rescue_event')

	if second_rescue_event_state > -1 or third_rescue_event_state > -1 then
		start_pos_marker_name = 's7_start_2'
	end

	if fourth_rescue_event_state > -1 then
		start_pos_marker_name = 's7_start_3'
	end

	return start_pos_marker_name
end

function local_class:control_roof_top_effect()

	wait_for_sec(0.25)

	local in_roof_top = field:IsOnUpperFloor(user_party.Leader.Position)

	if in_roof_top then
		self.util:change_rooftop_effect_state(false)
	end
end

function local_class:place_s7_polics_npcs_all_after()
	local polices = self.characters.all_polices()

	local police_marker = 's7_all_after_ally_'
	local oneline_key = 's7_all_after_ally_oneline_'

	for i = 1, #polices do
		if self:check_s7_rescued_polics_npcs_idx(i) then
			local marker_name = police_marker .. i .. '_2'

			character_util.set_active_state(polices[i], 'enabled')

			character_util.set_position(polices[i], field_util.get_marker_pos(marker_name))
			character_util.set_direction(polices[i], field_util.get_marker_dir(marker_name))
			character_util.set_active_state(polices[i], 'enabled')

			local anim_emo = self.s7_police_anim_emotion_data[i]
			character_util.set_anim(polices[i], { name = anim_emo.anim })
			character_util.set_emotion(polices[i], { name = anim_emo.emo })

			polices[i].Interactable = CS.Oak.NPCInteractable.Create()
			polices[i].Interactable.Talk = oneline_key .. i
		end
	end

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local second_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_second_rescue_event')
	local fourth_rescue_event_state = quest_util.get_custom_state(quest_progress, 's7_fourth_rescue_event')

	if second_rescue_event_state == 0 then
		self:passed_event_2(
				{ get_character('s7_police_2'), get_character('s7_police_3') }
		)
	end

	if fourth_rescue_event_state == 0 then
		self:passed_event_4(
				{ get_character('s7_police_6') }
		)
	elseif fourth_rescue_event_state == 1 then
		self:cleared_event_4()
	end
end

function local_class:check_s7_rescued_polics_npcs_idx(idx)
	for i = 1, #self.rescued_police_index_list do
		if idx == self.rescued_police_index_list[i] then
			return true
		end
	end

	return false
end

function local_class:convert_labose_npc_to_monster(convert_npc, battle_group_name)
	if type_util.is_array(convert_npc) then
		for i = 1, #convert_npc do
			local npc = convert_npc[i]

			character_util.convert_to_monster(npc, battle_group_name)
			command_util.execute_monster_notice(npc, user_party.Leader, 'battle')
		end
	else
		character_util.convert_to_monster(convert_npc, battle_group_name)
		command_util.execute_monster_notice(convert_npc, user_party.Leader, 'battle')
	end
end

function local_class:debug_loop()
	while not self.is_game_ended do
		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.Q) then
			start_coroutine(self.jump_route_4_state, self)
		end
		coroutine.yield()
	end
end

function local_class:jump_route_4_state()
	party_util.position_party(vector(-97, 0, -105), 'left', 'linear')
end

function local_class:passed_event_2(police_list)
	character_util.set_active_state(police_list[1], 'enabled')
	character_util.set_active_state(police_list[2], 'enabled')

	character_util.set_direction(police_list[1], 'right')
	character_util.set_direction(police_list[2], 'left')

	scene_util.set_group_anim(police_list, self, { name = 'dead', loop = false })

	character_util.add_color(police_list[1], police_list[1].Name, unity_class.color.black, 1, 1)
	field_ui_manager:RemoveUI(police_list[1], CS.Oak.FieldUiType.CharacterStats)

	character_util.add_color(police_list[2], police_list[2].Name, unity_class.color.black, 1, 1)
	field_ui_manager:RemoveUI(police_list[2], CS.Oak.FieldUiType.CharacterStats)

	local virus_pool = self.fx.virus_fog_strong()
	local initial_pos = field_util.get_marker_pos('s7_puzzle_area_labose_effect_start')

	for i = 3, 8 do
		self.fx:cache(virus_pool:Instantiate(initial_pos + vector(0, 0, 1 - i)))
		self.fx:cache(virus_pool:Instantiate(initial_pos + vector(1, 0, 1 - i)))
	end
end

function local_class:passed_event_4(police_list)
	character_util.set_active_state(police_list[1], 'enabled')

	-- left, prostrate 루프 없이, 완전히 검게 틴트된 상태.
	character_util.set_direction(police_list[1], 'left')

	scene_util.set_anim(police_list[1], self, { name = 'prostrate', loop = false })

	character_util.add_color(police_list[1], police_list[1].Name, unity_class.color.black, 1, 1)
	field_ui_manager:RemoveUI(police_list[1], CS.Oak.FieldUiType.CharacterStats)

	-- 라보스 괴물이 앞에 eat 애니메이션 하고 있는 상태.
	local lasbose = get_character('s7_event_4_labose_1')

	character_util.set_active_state(lasbose, 'enabled')

	character_util.set_position(lasbose, police_list[1].Position + vector(-0.5, 0, 0))
	character_util.set_direction(lasbose, 'right')

	scene_util.set_anim(lasbose, self, 'eat')

	character_util.set_sorting_layer(lasbose, 'Default', 3)
end

function local_class:cleared_event_4()
	local lasbose = get_character('s7_event_4_labose_1')

	character_util.set_active_state(lasbose, 'disabled')
end

function local_class:change_stage_bgm(bgm_name)
	music_player_util.play_stage_music({ state = 'muted' })

	wait_for_sec(0.25)

	music_player_util.play_stage_music({ name = bgm_name, state = 'field' })
end

function local_class:control_event_door()
	message_system:PublishSync(CS.Oak.DoorOpenEvent.Create('s7_switch_door_1', false))
	message_system:PublishSync(CS.Oak.DoorOpenEvent.Create('s7_switch_door_2', false))
end

function local_class:change_s7_event4_wall_off_state()
	local s7_event_4_wall = self.field_object.s7_event4_wall(1)

	s7_event_4_wall.Interactable = CS.Oak.NonInteractable.Instance

	s7_event_4_wall = self.field_object.s7_event4_wall(2)

	s7_event_4_wall.Interactable = CS.Oak.NonInteractable.Instance
end

--region 섹션8 마지막 이벤트 전 전투의 추가 웨이브 관련 함수
function local_class:start_battle_4_second_wave()
	self:set_event_battle_labose_creature_pos(self.battle_4_enemy_pos_states.pre_battle_pos, vector(4, 0, 0))

	self:appear_second_wave_labose_creature()
end

function local_class:set_event_battle_labose_creature_pos(scene_pos_idx, offset_pos)
	offset_pos = lua_helper.get_or_default(offset_pos, unity_class.vector3.zero)

	for i = 1, self.chase_labose_creatures_count do
		local npc = self.characters.event_battle_labose_creature(4, i)

		character_util.set_position(npc, self.markers.event_battle_labose_creature(i, scene_pos_idx, 1) + offset_pos)
	end
end

function local_class:appear_second_wave_labose_creature()
	local labose = self.characters.event_battle_labose_creature(4, 4)
	local labose_pos = self.markers.event_battle_labose_creature(9, self.battle_4_enemy_pos_states.second_battle_wave, 1)

	character_util.set_position(labose, labose_pos)

	labose = self.characters.event_battle_labose_creature(4, 5)
	labose_pos = self.markers.event_battle_labose_creature(10, self.battle_4_enemy_pos_states.second_battle_wave, 1)

	character_util.set_position(labose, labose_pos)


	wait_for_sec(0.1)

	labose = self.characters.event_battle_labose_creature(4, 4)
	labose_pos = self.markers.event_battle_labose_creature(9, self.battle_4_enemy_pos_states.second_battle_wave, 2)

	local ogre_last = false
	local normal_last = false
	local ogre_labose_appear = function(labose_npc, labose_arrive_pos, last)
		-- attack2 애니메이션 실행하고, 총 1초에 걸쳐서 자리에 위치.
		scene_util.set_anim(labose_npc, self, { name = 'attack2', count = 1 })

		character_util.move_to_async(labose_npc,
				labose_arrive_pos,
				1,
				nil,
				false,
				false)

		-- 등장하여 땅 찍는 순간 FX_slime_buttbounce, 카메라 shake 0.2초, 세기 0.2
		self.fx:slime_buttbounce():Instantiate(labose_npc.Position)

		music_player_util.play_sfx_one_shot('03_mech_stomp_01')

		camera_util.shake(0.15, 0.3)

		if not ogre_last and last then
			ogre_last = true

			local normal_creature_max_count = 3
			for i = normal_creature_max_count + 1, self.chase_labose_creatures_count do
				local npc = self.characters.event_battle_labose_creature(4, i)

				character_util.remove_anim(npc)

				character_util.convert_to_monster(npc, 's8_battle_4')
				command_util.execute_monster_notice(npc, user_party.Leader, 'battle')
			end
		end
	end

	local normal_labose_appear = function(labose_npc, labose_idx, last)
		-- attack2 애니메이션 실행하고, 총 1초에 걸쳐서 자리에 위치.
		character_util.remove_anim(labose_npc)
		wp_util.move_async(labose_npc, self.markers.event_battle_labose_creature(labose_idx, self.battle_4_enemy_pos_states.second_battle_wave, 1), 4, nil)

		music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')

		character_util.jump_move(labose_npc, self.markers.event_battle_labose_creature(labose_idx, self.battle_4_enemy_pos_states.second_battle_wave, 2), 6, 1.6, true)

		if not normal_last and last then
			normal_last = true

			local normal_creature_max_count = 3
			for i = 1, normal_creature_max_count do
				local npc = self.characters.event_battle_labose_creature(4, i)

				character_util.remove_anim(npc)

				character_util.convert_to_monster(npc, 's8_battle_4')
				command_util.execute_monster_notice(npc, user_party.Leader, 'battle')
			end
		end
	end

	start_coroutine(ogre_labose_appear, labose, labose_pos, false)

	wait_for_sec(0.3)

	labose = self.characters.event_battle_labose_creature(4, 5)
	labose_pos = self.markers.event_battle_labose_creature(10,
			self.battle_4_enemy_pos_states.second_battle_wave, 2)

	start_coroutine(ogre_labose_appear, labose, labose_pos, true)

	local normal_creature_max_count = 3
	for i = 1, normal_creature_max_count do
		labose = self.characters.event_battle_labose_creature(4, i)
		local last = false

		if i == normal_creature_max_count then
			last = true
		end

		start_coroutine(normal_labose_appear, labose, i, last)
	end

	while not normal_last do
		coroutine.yield(nil)
	end

	wait_for_sec(0.1)
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
