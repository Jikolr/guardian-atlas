local local_class = newclass("FutureCastlePartB1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 캐릭터를 가져오는 함수
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		end

		return get_character('knight_female')
	end
	self.get_knight_gatling = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_gatling')
		end

		return get_character('knight_female_gatling')
	end
	self.get_knight_normal = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_normal')
		end

		return get_character('knight_female_normal')
	end
	self.get_princess = function() return get_character('princess') end

	--region 전경 / 중경 / 원경 스크롤링
	self.get_middle_obj = function(num) return get_field_object('mid_obj_' .. num) end
	self.middle_obj_yz_pos = vector(0, -5, 6.25)
	self.middle_obj_x_rot = 30
	self.middle_obj_count = 2
	self.middle_obj_x_offsets = {
		-167.5, -159.5
	}

	self.field_grid_info = nil
	self.field_grid_bounds = nil

	self.grid_side_gap = 0.5	-- 카메라 흔들림 등으로 유격이 생기는 걸 방지하고자 실제 그리드 크기보다 좌우로 0.5씩 늘려서 계산함

	self.foreground_layer = nil
	self.foreground_width = 6 * 75
	self.foreground_yz_pos = vector(0, 8.5, -9)
	self.foreground_x_offset = -164.5

	self.middleground_layer = nil
	self.middleground_width = 8 * 9
	self.middleground_yz_pos = vector(0, -19.375, 7)
	self.middleground_x_offset = -172

	self.background_layer = nil
	self.background_width = 6 * 3
	self.background_yz_pos = vector(0, -10, 10.25)
	self.background_x_offset = -174.5

	--endregion

	-- 동적로딩 npc 리스트 2
	self.optimized_npcs_2 = nil

	-- 동적로딩 npc 리스트 3
	self.optimized_npcs_opening = nil
	self.opening_resistance = nil

	-- 동적로딩 npc 리스트 4
	self.optimized_npcs_iron = nil
	self.iron_resistance = nil
	self.iron_invader = nil

	self.bg_back = true

	self.optimized_harvester = nil

	self.is_turret_battle = false
	self.is_sohee_move = false

	self.spark_screen_effect = nil
	self.meteor_effect = nil
	self.meteor_back_effect = nil
	self.smoke_effect_1 = nil
	self.smoke_effect_2 = nil
	self.smoke_effect_3 = nil

	self.sniper_effect = nil

	self.war_loop_1 = nil
	self.war_loop_2 = nil

	-- 이펙트 오브젝트 풀을 가져오는 함수
	self.get_fight_effect_1 = function() return unity_object_pool.GetOrCreate('fx_cp11_invader_vs_resi_fight_sprite') end
	self.get_fight_effect_2 = function() return unity_object_pool.GetOrCreate('fx_cp11_invader_vs_resi_fight_sprite_rev') end
	self.get_fight_effect_3 = function() return unity_object_pool.GetOrCreate('fx_cp11_invader2_attack_resi1') end
	self.get_fight_effect_4 = function() return unity_object_pool.GetOrCreate('fx_cp11_giant_vs_fat_invader_guard') end
	self.get_fight_effect_5 = function() return unity_object_pool.GetOrCreate('fx_cp11_steampunk_male_shooting') end
	self.get_heal_effect_1 = function() return unity_object_pool.GetOrCreate('fx_cp11_resi_cure_people_01') end
	self.get_heal_effect_2 = function() return unity_object_pool.GetOrCreate('fx_cp11_resi_cure_people_02') end
	self.get_heal_effect_3 = function() return unity_object_pool.GetOrCreate('fx_cp11_resi_cure_people_03') end
	self.get_heal_effect_4 = function() return unity_object_pool.GetOrCreate('fx_cp11_resi_cure_people_04') end

	-- 아이템 마커 + GO! 표시 오브젝트 풀
	self.get_move_icon = function() return unity_object_pool.GetOrCreate('ch11_move_icon') end

	self.fight_effect_list = {}
	self.heal_effect_list = {}

	self.mg_effect_list = {}

	self.resholder = nil
	self.time_text = nil
	self.title_tween_alpha = nil
	self.shadow_tween_alpha = nil

	--region 폭격 이벤트
	self.bombing_falling = false
	self.bombing_radius = 1.25
	self.bombing_zone_name = 'section3_bombing'

	self.bombing_state = {
		none = 0,
		in_zone = 1,
		screen_playing = 2,	-- 연출 중에 사용
	}
	self.current_bombing_state = self.bombing_state.none
	self.bombing_active = true

	-- 해당 존을 나갔다 들어오면 중복 루틴 발생 가능. -> 이 코루틴을 끊어줄 것이라고 전달하는 매개채 필요
	self.bombing_done_list = {}
	self.bombing_done_count = 0

	self.get_fx_darkmagic_missile = function() return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj') end
	self.get_fx_darkmagic_missile_explosion = function()
		return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj_Explosion')
	end

	-- obj / is_using
	self.bombing_range_pool = {}
	self.bombing_range_pool_size = 25

	--endregion

	--region 타일맵 회전
	self.tilemap_x_rot = 30
	--endregion

	--region 전투 시스템

	self.get_monster = function(battle_num, monster_num)
		return get_character('monster_battle_' .. battle_num .. '_' .. monster_num)
	end
	self.get_monster_respawn_marker = function(battle_num, monster_num)
		return field:GetMarker('monster_respawn_' .. battle_num .. '_' .. monster_num)
	end
	self.get_battle_invisible_wall = function(wall_num)
		return get_field_object('battle_gate_invisible_' .. wall_num)
	end

	self.get_battle_gate = function(gate_num)
		return get_field_object('battle_2_gate_' .. gate_num)
	end

	self.get_fx_invader_beam = function() return unity_object_pool.GetOrCreate('FX_Event_InvaderBeam') end

	self.battle_state = {
		idle = 0,
		in_battle = 1,
		done = 99
	}

	self.battle_infos = {
		battle_1 = {
			battle_num = 1,
			battle_zone_name = 'battle_1',
			active_zone_name = 'battle_1_active',
			group_name = 'BATTLE_1',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 3,
			monster_count_to_dead = 6,
			monster_count_to_respawn = 6 - 3,
			on_load_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					monster.ActiveState = active_state('visible')
				end
			end,
			start_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					character_util.convert_to_monster(monster, battle_info.group_name, battle_info.battle_zone_name)
					command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
					monster.ActiveState = active_state('enabled')
				end
			end
		},
		battle_2 = {
			battle_num = 2,
			battle_zone_name = 'battle_2',
			active_zone_name = 'battle_2_active',
			group_name = 'BATTLE_2',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 4,
			monster_count_to_dead = 8,
			monster_count_to_respawn = 8 - 4,
			on_load_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					monster.ActiveState = active_state('visible')
				end
			end,
			start_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					character_util.convert_to_monster(monster, battle_info.group_name, battle_info.battle_zone_name)
					command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
					monster.ActiveState = active_state('enabled')
				end
			end
		},
		battle_3 = {
			battle_num = 3,
			battle_zone_name = 'battle_3',
			active_zone_name = 'battle_3_active',
			group_name = 'BATTLE_3',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 5,
			monster_count_to_dead = 12,
			monster_count_to_respawn = 12 - 5,
			end_callback = function(battle_info, controller)
				if controller.current_main_state ~= controller.main_state.before_get_libera then
					--controller:remove_camera_limiting()
					controller:remove_battle_gate()
					controller:show_go_sign()
				end
			end
		},
		battle_7 = {
			battle_num = 7,
			battle_zone_name = 'sohee_gatling_battle',
			active_zone_name = 'sohee_gatling_active',
			group_name = 'BATTLE_7',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 6,
			monster_count_to_dead = 12,
			monster_count_to_respawn = 12 - 6,
			start_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					monster.Position = vector(999, 0, 999)
					monster.ActiveState = active_state('visible')
					controller:insert_battle_respawn_queue('battle_7', i, true, (i - 1) * 0.1)
				end
				controller.is_sohee_move = true

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(controller.sohee_appear, controller))

			end,
			end_callback = function(battle_info, controller)
				controller.is_turret_battle = false
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(controller.super_invader_battle, controller))
			end
		},
		battle_4 = {
			battle_num = 4,
			battle_zone_name = 'battle_4',
			active_zone_name = 'battle_4_active',
			group_name = 'BATTLE_4',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 3,
			monster_count_to_dead = 5,
			monster_count_to_respawn = 5 - 3
		},
		battle_5 = {
			battle_num = 5,
			battle_zone_name = 'battle_5',
			active_zone_name = 'battle_5_active',
			group_name = 'BATTLE_5_1',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 4,
			monster_count_to_dead = 9,
			monster_count_to_respawn = 9 - 4,
		},
		battle_6 = {
			battle_num = 6,
			battle_zone_name = 'battle_6',
			active_zone_name = 'battle_6_active',
			group_name = 'BATTLE_6',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 16,
			respawn_last_times = {},
			monster_count = 5,
			monster_count_to_dead = 10,
			monster_count_to_respawn = 10 - 5,
		},
		battle_8 = {
			battle_num = 8,
			battle_zone_name = 'battle_8',
			active_zone_name = 'battle_8_active',
			group_name = 'BATTLE_8',
			state = self.battle_state.idle,
			respawn_queue = {},
			respawn_pos_count = 1,
			respawn_last_times = {},
			monster_count = 1,
			monster_count_to_dead = 1,
			monster_count_to_respawn = 1 - 1,
			start_callback = function(battle_info, controller)
				for i = 1, battle_info.monster_count do
					local monster = controller.get_monster(battle_info.battle_num, i)
					monster.Position = vector(999, 0, 999)
					monster.ActiveState = active_state('visible')
					controller:insert_battle_respawn_queue('battle_8', i, true, (i - 1) * 0.1)
				end

				stage.BattleManager.PlayBattleVoiceAndFanfare = false
			end,
			end_callback = function(battle_info, controller)
				controller:hide_go_sign()

				local main_quest = user_progress:GetStartedQuest(controller.main_quest_id)

				if main_quest ~= nil then
					if main_quest.InnerProgress == 2 and not main_quest.IsComplete then
						music_player_util.play_stage_music( { state = 'field', mix = 2})
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(controller.scroll_ending, controller))
					else
						music_player_util.play_stage_music({name = 'ondemand/v2_10_futurecastle_part2/audio/music:bgm_futurecastle2_war_02', state = 'field'})
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
								wait_for_sec(6)
								controller:remove_battle_gate()
						end))
					end
				end
			end
		},
	}

	self.monster_respawn_state = {
		none = 0,
		before_heal = 1,
		after_heal = 2,	-- 힐 Event Send될 때 까지 1프레임 기다림
		respawning = 3,
		respawn_over = 4,
	}

	self.monster_respawn_type = {
		soldier_weak = {'walk_right'},
		archer_bow = {'up', 'down'},
		hulk_default = {'dash_left', 'dash_right'},
		healer_default = {'teleport'},
		runsoldier_slow = {'up', 'down'},
		monster_ogre = {'fall'},
		monster_boss_harvester_fc = {'harvester'},
	}

	-- 등장 타입
	self.respawn_type_infos = {
		left = {
			name = 'left',
			respawning_time = 1,
			marker_indexes = {
				14, 15, 16
			}
		},
		right = {
			name = 'right',
			respawning_time = 1,
			marker_indexes = {
				6, 7, 8
			}
		},
		up = {
			name = 'up',
			respawning_time = 1,
			marker_indexes = {
				1, 2, 3, 4, 5
			}
		},
		down = {
			name = 'down',
			respawning_time = 0.5,
			marker_indexes = {
				9, 10, 11, 12, 13
			}
		},
		walk_left = {
			name = 'walk_left',
			respawning_time = 0.5,
			marker_indexes = {
				14, 15, 16
			}
		},
		walk_right = {
			name = 'walk_right',
			respawning_time = 0.5,
			marker_indexes = {
				6, 7, 8
			}
		},
		dash_left = {
			name = 'dash_left',
			respawning_time = 1,
			marker_indexes = {
				1, 13, 14, 15, 16
			}
		},
		dash_right = {
			name = 'dash_right',
			respawning_time = 1,
			marker_indexes = {
				5, 6, 7, 8, 9
			}
		},
		teleport = {
			name = 'teleport',
			respawning_time = 0,
			marker_indexes = {
				1, 2, 3, 4, 5, 9, 10, 11, 12, 13
			}
		},
		fall = {
			name = 'fall',
			respawning_time = 1,
			marker_indexes = {
				1, 2, 3, 4, 5, 9, 10, 11, 12, 13
			}
		},
		harvester = {
			name = 'harvester',
			respawning_time = 0.5,
			marker_indexes = {
				1
			}
		}
	}

	self.respawn_pos_cool_time = 3
	self.leader_dead = false

	--endregion

	--region 카메라
	self.stage_camera_state = {
		idle = 0,
		limiting = 1,	-- 전투 구역 들어갔을 때 카메라 부드럽게 움직임, 이 스테이트 진입 전에 카메라 타겟 해제 필요
		limited = 2,
		returning = 3,	-- 전투 종료되었을 때 카메라 부드럽게 움직임, 이 스테이트 진입 전에 카메라 타겟 세팅 필요
	}
	self.stage_camera_info = {
		state = self.stage_camera_state.idle,
		target = nil,
		min_x = -999,
		max_x = 999,
		lerp_move_speed = 8,
		return_move_speed = 8,
		prev_pos = vector(0, 0, 0)
	}

	--endregion

	--region 아이템 드롭
	self.get_item_dropper = function(num) return get_field_object('item_dropper_' .. num) end

	self.item_info = {
		items = {
			turkey = {
				id = 20262,
				type = 'heal',
				heal_ratio = 0.5,
				sprite_scale = 1.7,
				need_mark = false,
			},
			meat = {
				id = 20263,
				type = 'heal',
				heal_ratio = 0.3,
				need_mark = false,
			},
			apple = {
				id = 20264,
				type = 'heal',
				heal_ratio = 0.1,
				sprite_scale = 0.85,
				need_mark = false,
			},
			libera = {
				id = 9010314,
				type = 'libera',
				need_mark = true,
				sprite_scale = 1,
			},
			gatling_gun = {
				id = 9030374,
				type = 'gatling_gun',
				need_mark = true,
				sprite_scale = 0.7,
			}
		},

		pick_fly_dist = 0.5,
		default_sprite_scale = 1.2,

		dropper_data = {
			item_dropper_1 = {
				num = 1,
				drop_item = 'apple',
				destroyed = false,
			},
			item_dropper_2 = {
				num = 2,
				drop_item = 'libera',
				destroyed = false
			},
			item_dropper_3 = {
				num = 3,
				drop_item = 'turkey',
				destroyed = false
			},
			item_dropper_4 = {
				num = 4,
				drop_item = 'gatling_gun',
				destroyed = false
			},
			item_dropper_5 = {
				num = 5,
				drop_item = 'apple',
				destroyed = false
			},
			item_dropper_6 = {
				num = 6,
				drop_item = 'apple',
				destroyed = false
			}
		},
	}

	self.item_marker_info = {
		object = nil,
		skel_anim = nil
	}

	--endregion

	--region 화물 호위
	self.get_wagon = function() return get_field_object('wagon') end
	self.get_wagon_barrel = function(num) return get_field_object('wagon_barrel_' .. num) end
	self.get_wagon_interact = function() return get_field_object('wagon_interact') end
	self.get_wagon_invisible = function(num) return get_field_object('wagon_invisible_' .. num) end

	-- 몬스터 가져오는 함수
	self.get_wagon_monster = function(battle_num, monster_num)
		return get_character('wagon_monster_' .. battle_num .. '_' .. monster_num)
	end

	self.get_stuck_x_pos = function(num) return field:GetMarker('wagon_stuck_' .. num).position.x end
	self.get_wagon_target_x_pos = function() return field:GetMarker('wagon_target_pos').position.x end
	self.get_wagon_start_pos = function() return field:GetMarker('wagon_start_pos').position end
	self.get_battle_active_x_pos = function(num) return field:GetMarker('wagon_battle_active_' .. num).position.x end
	self.get_wagon_monster_respawn_pos = function(battle_num, monster_num)
		return field:GetMarker('wagon_monster_pos_' .. battle_num .. '_' .. monster_num).position
	end

	self.wagon_barrel_offsets = {
		vector(0, 0, 0.7),
		vector(1, 0, 0.7),
		vector(2, 0, 0.7),
	}
	self.wagon_invisible_count = 4
	self.wagon_invisible_offsets = {
		vector(0, 0, 0),
		vector(0, 0, 1),
		vector(2, 0, 0),
		vector(2, 0, 1),
	}

	self.escort_state = {
		none = 0,
		before_escort = 1,
		escorting = 2,
		after_escort = 3,
	}
	self.current_escort_state = self.escort_state.none

	self.wagon_state = {
		idle = 0,
		move = 1,
		sticking = 2,
		stuck_in_mud = 3,
		blocked = 4,
		destroyed = 5,
		reached = 99
	}
	self.current_wagon_state = self.wagon_state.idle

	self.wagon_info = {
		max_hp = 100000,
		name_key = 'futurecastle_part2_s4_wagon_name',
		current_hp = 0,
		move_speed = 1,
	}
	self.top_hp_bar = nil

	self.stuck_pos_count = 1
	self.stuck_next_index = 1
	self.sticking_duration = 0.15
	self.sticking_target_z_rot = 8
	self.stucked = false

	--전투 관련
	self.battle_next_index = 1
	self.wagon_battle_group_name = 'BATTLE_5'
	self.wagon_battle_zone_name = 'wagon_battle'
	self.wagon_battle_infos = {
		{
			monster_count = 2
		},
		{
			monster_count = 2
		},
		{
			monster_count = 2
		},
		{
			monster_count = 1
		},
	}

	self.wagon_monster_damage = 1000

	self.get_turret = function(num) return get_character('turret_' .. num) end

	self.get_fx_cannon_ball = function() return unity_object_pool.GetOrCreate('fx_stage1_chase_bomb_proj') end
	self.get_fx_cannon_ball_contrail = function() return unity_object_pool.GetOrCreate('fx_stage1_chase_bomb_proj_contrail') end
	self.get_fx_small_explosion = function() return unity_object_pool.GetOrCreate('FX_Explosion_Bomb_small') end
	self.get_fx_event_invader_beam = function() return unity_object_pool.GetOrCreate('FX_Event_InvaderBeam') end
	self.get_fx_common_cannonfire = function() return unity_object_pool.GetOrCreate('FX_Common_CannonFire') end

	self.turret_state = {
		idle = 0,
		targeting = 1,	-- 타겟이 시야 내에 있을 때
		attacking = 2,
		dead = 99
	}
	self.turret_data = {
		attack_delay = 3,
		shoot_delay = 0.2,
		range = 12,
		damage = 7500,
		shoot_offset = vector(-0.5, 1.3, 0),
		count = 3
	}

	self.cannon_ball_data = {
		move_dur = 1,
		height_ratio = 1 / math.pi,	-- 일반적인 사인 곡선을 그리도록 함
		move_speed = 13,
	}

	self.turret_infos = {}
	for _ = 1, self.turret_data.count do
		table.insert(self.turret_infos, {
			time_passed = 0,
			state = self.turret_state.idle
		})
	end

	-- time_passed / start_pos / target_pos / object
	self.cannon_ball_infos = {}

	self.rocks = {}

	self.wagon_bombing_active = true
	self.wagon_bombing_damage = 10000

	self.sfx_wagon_move = nil

	--endregion

	--region 메인

	self.get_super_invader = function() return get_character('super_invader') end
	self.get_sohee = function() return get_character('sohee') end

	self.main_quest_id = 195

	self.main_state = {
		none = 0,
		opening = 1,
		before_panda = 2,
		before_aisha = 3,
		before_get_libera = 4,
		before_iron_teatan = 5,
		before_sohee_gatling = 6,
		before_wagon_escort = 7,
		meet_wagon = 8,
		wagon_escorting = 9,
		before_princess_gone = 10,
		last_battle = 11,
		done = 99
	}

	self.current_main_state = self.main_state.none

	self.main_zone_names = {
		panda_talk = 'panda_talk',
		aisha_rush = 'aisha_rush',
		aisha_battle_active = 'battle_3_active',
		iron_teatan = 'iron_teatan',
		sohee_gatling_active = 'sohee_gatling_active',
		sohee_gatling_battle = 'sohee_gatling_battle',
		wagon_escort_active = 'wagon_meet_active',
		wagon_escort = 'wagon_battle',
		harvester_fly = 'harvester_fly',
		last_battle_active = 'battle_7_active',
		last_battle = 'battle_7'
	}

	self.go_sign_info = {
		object = nil,
		skel_anim = nil,	-- Skeleton Animation
		duration = 3,
		time_passed = 0,
	}

	self.wait_progressing_section = true

	--endregion

	--region 박스 드랍 스타피스
	self.hidden_box_name = 'star_piece_drop_box'
	self.hidden_box_star_piece_name = 'star_piece_2'
	self.hidden_box = nil
	--endregion

	--region 아케이드 머신 스타피스
	self.arcade_machine_coin_event = 'arcade_machine_coin_break_event'
	self.coin_box_name = 'coin_box'
	self.coin_box = nil
	self.arcade_machine = nil
	--endregion

	--region 포로 스타피스
	self.captive_name = 'future_captive_'
	self.captives = {}
	self.help_icons = {}
	-- 포로 쉐이크 이벤트 상태값
	self.captive_shake_stat = {}
	self.get_captive_effect = function() return unity_object_pool.GetOrCreate('FX_dead') end
	self.get_captive_starpiece_effect = function() return unity_object_pool.GetOrCreate('FX_starpiece_in_character') end
	--endregion

	--region 화약통 스타피스
	self.get_star_inv_floor = function() return get_field_object('star_piece_inv_floor') end
	self.get_fx_object_twinkle = function() return unity_object_pool.GetOrCreate('FX_Object_Twinkle') end
	self.get_barrel_star_piece = function() return get_field_object('captive_star_piece') end
	self.twinkle_effect = nil
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_box_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	self:set_tilemap()

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	--TODO : 섹션 별로 안쓰는 애들은 따로 로드해야될듯
	quest_util.load_pool_resource(
		'FX_hit',
		'FX_lasthit',
		'FX_Event_InvaderBeam',
		'fx_cp11_invader_vs_resi_fight_sprite',
		'fx_cp11_invader_vs_resi_fight_sprite_rev',
		'fx_stage1_sidescroll_meteor',
		'fx_stage1_sidescroll_smoke_background',
		'fx_stage1_sidescroll_smoke_front',
		'fx_stage1_sidescroll_smoke_middle',
		'FX_DarkMagicMissile_Proj',
		'FX_DarkMagicMissile_Proj_Explosion',
		'fx_stage1_spark_screen_fx',
		'fx_stage1_sidescroll_meteor_background',
		'fx_cp11_resi_cure_people_01',
		'fx_cp11_resi_cure_people_02',
		'fx_cp11_resi_cure_people_03',
		'fx_cp11_resi_cure_people_04',
		'fx_cp11_sniper_shoot_loop',
		'ch11_move_icon',
		'fx_stage1_chase_bomb_proj',
		'fx_stage1_chase_bomb_proj_contrail',
		'FX_Explosion_Bomb_small',
		'FX_dead',
		'FX_starpiece_in_character',
		'FX_Common_CannonFire',
		'fx_cp11_giant_vs_fat_invader_guard',
		'fx_cp11_invader2_attack_resi1',
		'fx_cp11_steampunk_male_shooting',
		'FX_Object_Twinkle'
	)

	if self:is_belt_scroll_left() then
		wait_all({
			-- 스테이지 1은 다른 캐릭터 사용 안 하고 메뉴얼캐릭터는 기사이기 때문에 run sfx 가 정해져있다.
			music_player:PreloadSfx('01_dash_01', nil),
			-- 배틀게이트 등장/파괴 효과음
			music_player:PreloadSfx('01_gate_show_02', nil),
			music_player:PreloadSfx('01_gate_destroy_02', nil),
			-- 전투승리 팡파레 효과음
			music_player:PreloadSfx('02_battle_fanfare_01', nil),
			-- 벽충돌 효과음
			music_player:PreloadSfx(CS.Oak.ICrashBehaviourExtensions.KnockBackWallSfxHandleName, nil),
			-- 몬스터 죽음관련 효과음
			music_player:PreloadSfx('01_air_spin_01', nil),
			music_player:PreloadSfx('02_explosion_01', nil),
			music_player:PreloadSfx('02_die_fat_ogre_01', nil),
			music_player:PreloadSfx('02_die_demon_01', nil),
			music_player:PreloadSfx('01_boss_die_01', nil),
			-- 리베라 관련 sfx
			music_player:PreloadSfx('02_cloud_knight_01', nil),
			music_player:PreloadSfx('02_lightning_strike_03', nil),
			-- 게틀링건 sfx
			music_player:PreloadSfx('01_holy_loop_01', nil),
			music_player:PreloadSfx('02_plasma_ready_02', nil),
			music_player:PreloadSfx('02_gun_shoot_06', nil),
			music_player:PreloadSfx('01_nothing_01', nil),
			music_player:PreloadSfx('02_gun_shoot_05', nil),
			music_player:PreloadSfx('02_gun_reload_03', nil),
			music_player:PreloadSfx('02_wolf_boss_fire_01', nil),
			music_player:PreloadSfx('01_siren_oneshot_01', nil),
			music_player:PreloadSfx('02_princess_shoot_02', nil),
			-- 퍼플코인/스타피스/경험치/골드/아이템 드랍 및 획득 효과음
			music_player:PreloadSfx('03_get_drop_item_01', nil),
			music_player:PreloadSfx('03_get_starpiece_01', nil),
			music_player:PreloadSfx('03_get_purplecoin_01', nil),
			music_player:PreloadSfx('03_get_drop_gold_01', nil),
			music_player:PreloadSfx('03_get_drop_exp_01', nil),
			music_player:PreloadSfx('03_drop_gold_01', nil),
			music_player:PreloadSfx('03_drop_recovery_01', nil),
			music_player:PreloadSfx('01_get_keyitem_01', nil),
			-- 일자형 구성이라서 플레이하는 동안 나온 프리로드 안 되어있던 sfx 들을 추가해 주었음
			music_player:PreloadSfx('02_goblin_appear_01', nil),
			music_player:PreloadSfx('02_wolf_boss_bomb_01', nil),
			music_player:PreloadSfx('01_throw_01', nil),
			music_player:PreloadSfx('03_dialogue_positive_01', nil),
			music_player:PreloadSfx('03_dialogue_negative_01', nil),
			music_player:PreloadSfx('01_count_final_01', nil),
			music_player:PreloadSfx('01_crowd_shout_06', nil),
			music_player:PreloadSfx('01_dash_06', nil),
			music_player:PreloadSfx('01_super_invader_roar_02', nil),
			music_player:PreloadSfx('02_stomp_big_01', nil),
			music_player:PreloadSfx('01_invader_beam_01', nil),
			music_player:PreloadSfx('02_magic_shield_01', nil),
			music_player:PreloadSfx('02_cast_magic_03', nil),
			music_player:PreloadSfx('01_earthquake_04', nil),
			music_player:PreloadSfx('02_iron_teatan_prepare_01', nil),
			music_player:PreloadSfx('02_iron_teatan_prepare_02', nil),
			music_player:PreloadSfx('02_gun_shoot_01', nil),
			music_player:PreloadSfx('02_dash_stomp_jump_01', nil),
			music_player:PreloadSfx('02_charge_punch_01', nil),
			music_player:PreloadSfx('01_coop_matched_01', nil),
			music_player:PreloadSfx('02_small_explosion_loop_01', nil),
			music_player:PreloadSfx('02_missile_launch_03', nil),
			music_player:PreloadSfx('02_charge_laser_01', nil),
			music_player:PreloadSfx('02_stomp_01', nil),
			music_player:PreloadSfx('02_bomb_holdup_fail_01', nil),
			music_player:PreloadSfx('01_throw_01', nil),
			music_player:PreloadSfx('02_die_boss_invader_01', nil),
			music_player:PreloadSfx('02_bomb_count_fast_01', nil),
			music_player:PreloadSfx('01_clang_01', nil),
			music_player:PreloadSfx('03_rock_break_01', nil),
			music_player:PreloadSfx('01_holdup_01', nil),
			music_player:PreloadSfx('01_fall_down_01', nil),
			music_player:PreloadSfx('02_die_boss_harvester_01', nil),
			music_player:PreloadSfx('03_dialogue_01', nil),
			music_player:PreloadSfx('02_princess_wing_01', nil),
			music_player:PreloadSfx('02_homing_stab_01', nil),
			music_player:PreloadSfx('02_harvester_idle_01', nil),
			music_player:PreloadSfx('02_explosion_02', nil),
			music_player:PreloadSfx('01_earthquake_03', nil),
			music_player:PreloadSfx('01_shutter_01', nil),
			music_player:PreloadSfx('02_break_wood_01', nil),
			music_player:PreloadSfx('02_break_wood_02', nil),
			music_player:PreloadSfx('02_break_wagon_01', nil),
			music_player:PreloadSfx('01_interact_gamecenter_01', nil),
			music_player:PreloadSfx('03_gimmick_jingle_01', nil),
			music_player:PreloadSfx('03_dialogue_emphasize_01', nil),
			music_player:PreloadSfx('01_push_wagon_01', nil),
			music_player:PreloadSfx('01_wagon_loop_01', nil),
			music_player:PreloadSfx('02_gimmick_door_down_02', nil)
		})
	end

	-- 연출용 NPC들 동적 로드
	yield_return_func(self.npcs_setting_2, self)
	yield_return_func(self.npcs_setting_3, self)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	--공주 파티 합류 및 파티원 전원 날리고 스테이지 시작 시퀀스 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

--region 스테이지 세팅
function local_class:set_tilemap()
	local tilemap = field.Tilemap

	for i = 0, tilemap.transform.childCount - 1 do
		local layer_tf = tilemap.transform:GetChild(i)
		local layer = layer_tf:GetComponent(typeof(CS.Tilemaps.Layer))

		if layer ~= nil then
			local to_manage = (layer.LayerType == CS.Tilemaps.LayerType.Tile) and layer_tf.name ~= 'gimmick'

			if to_manage then
				layer_tf.position = layer_tf.position + vector(0, -1.8, 0)
				layer_tf.localRotation = unity_class.quaternion.Euler(self.tilemap_x_rot, 0, 0)
			end
		end
	end
end

function local_class:recover_tilemap()
	local tilemap = field.Tilemap

	for i = 0, tilemap.transform.childCount - 1 do
		local layer_tf = tilemap.transform:GetChild(i)
		local layer = layer_tf:GetComponent(typeof(CS.Tilemaps.Layer))

		if layer ~= nil then
			local to_manage = (layer.LayerType == CS.Tilemaps.LayerType.Tile) and layer_tf.name ~= 'gimmick'

			if to_manage then
				layer_tf.position = layer_tf.position + vector(0, 1.8, 0)
				layer_tf.localRotation = unity_class.quaternion.Euler(0, 0, 0)
			end
		end
	end
end

--주인공 혼자 들어오도록 하는 함수
function local_class:opening_routine()
	if self:is_belt_scroll_left() then
		self:load_bombing_range_pool()
		self:load_effect()
	end

	local party_list = {}

	for i = 0, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		if i ~= 1 then
			character_util.convert_to_npc(party_list[i])
			party_list[i].ActiveState = CS.Oak.ActiveState.Disabled
		end
	end

	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)
	local knight = self.get_knight_normal()

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(knight, param)
	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)
	character_util.set_position(user_party.Leader, user_party_leader.Position)
	character_util.set_position(user_party_leader, vector(999, 0, 999))

	local princess = get_character('princess')
	character_util.remove_anim_and_emotion(princess)
	character_util.convert_to_party_member(princess, user_party, true)
	character_util.remove_anim_and_emotion(princess)

	get_field_object('innercastle_scroll').transform.localScale = unity_class.vector3(0.8, 0.8, 0.8)

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	--region 박스 드랍 스타피스
	self.hidden_box = get_field_object(self.hidden_box_name)
	local box_star_piece = get_field_object(self.hidden_box_star_piece_name)
	self.hidden_box.Position = box_star_piece.Position
	--endregion

	--region 아케이드 머신 스타피스
	self.coin_box = get_field_object(self.coin_box_name)
	self.arcade_machine = get_field_object('arcade_machine')
	--endregion

	--region 포로 스타피스
	for i = 1, 4 do
		local captive = get_character(self.captive_name .. (i + 1))

		local help_icon = self.get_move_icon():Instantiate(captive.Position + vector(0, 1.5, 0))
		help_icon.transform.localScale = unity_class.vector3.one * 0.3
		help_icon.transform:GetComponent(
				typeof(CS.Spine.Unity.SkeletonAnimation)).state:SetAnimation(0, "help", true)

		field_ui_manager:RemoveUI(captive, CS.Oak.FieldUiType.CharacterStats)
		captive.Interactable = CS.Oak.PublishInteractable.Create()
		table.insert(self.captives, captive)
		-- 포로 쉐이크 이벤트 상태값
		table.insert(self.captive_shake_stat, true)
		table.insert(self.help_icons, help_icon)
	end

	-- 포로 쉐이크 이벤트 함수 코루틴
	for i = 1, #self.captive_shake_stat do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.captive_shake, self, i))
	end

	--endregion

	field_ui_manager:RemoveUI(self:get_sohee(), CS.Oak.FieldUiType.CharacterStats)
	field_ui_manager:RemoveUI(get_character('big_iron_teatan'), CS.Oak.FieldUiType.CharacterStats)

	if main_quest ~= nil and not main_quest.IsComplete then
		if main_quest.InnerProgress <= 5 or main_quest.InnerProgress == 5 then
			get_field_object('innercastle_scroll').Position = vector(152, 0, -5)
		end
	end

	if main_quest ~= nil and not main_quest.IsComplete then
		if main_quest.InnerProgress == 0 or main_quest.InnerProgress == 5 then
			return
		elseif main_quest.InnerProgress == 4 then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')

			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(field:GetMarker('default_start').position,
					CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
			return
		elseif main_quest.InnerProgress == 1 then
			self:preload_main_opening(true)
			self:main_opening()
			return
		end
	end

	self.current_main_state = self.main_state.before_panda
	self.spark_screen_effect = unity_object_pool.GetOrCreate('fx_stage1_spark_screen_fx'):Instantiate(vector(knight.Position.x, 7, -7.5), unity_class.quaternion.identity, stage_camera.Transform)
	self.spark_screen_effect.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, 'linear')

	coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(field:GetMarker('default_start').position,
			CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
end

function local_class:load_effect()
	local fight_pos_table = {
		vector(-3.5, -9, 8.8),
		vector(-1.5, -9, 7.8),
		vector(-0.5, -9, 8.3),
		vector(1.5, -9, 7.8),
	}

	local heal_pos_table = {
		vector(-178, -7, 7.5),
		vector(-177, -7, 6.9),
		vector(-175.9, -7, 7.25),
		vector(-175, -7, 7.5),
		vector(-174, -7, 6.9),
		vector(-173, -7, 7.35),
		vector(-170.9, -7, 7),
		vector(-169.8, -7, 7.5),
		vector(-169, -7, 7.15),
	}

	local heal_table = {
		2,
		2,
		3,
		2,
		2,
		2,
		1,
		4,
		2
	}

	local scale_table = {
		0.7,
		0.7,
		0.7,
		0.7
	}

	local fight_effect_count = 32
	local heal_effect_count = 9
	local effect_count = fight_effect_count + heal_effect_count
	local done_count = 0

	local infos = {}

	for i = 1, fight_effect_count do
		local delay = unity_class.random.Range(0, 700) / 1000	-- 싸우는 이펙트 duration이 0.7초임
		local pool = self['get_fight_effect_' .. random_util.get_random_int(1, 2)]
		local index = i % 4 + 1
		local pos = fight_pos_table[index] + vector(i // 4 * 6 - 151, 0, 0)
		table.insert(infos, {
			delay = delay,
			pool = pool,
			pos = pos,
			scale = scale_table[index],
			done = false,
		})
	end

	for i = 1, heal_effect_count do
		local delay = unity_class.random.Range(0, 700) / 1000
		local pool = self['get_heal_effect_' .. heal_table[i]]
		local pos = heal_pos_table[i]
		table.insert(infos, {
			delay = delay,
			pool = pool,
			pos = pos,
			scale = 1,
			done = false
		})
	end

	local time_passed = 0
	while done_count < effect_count do
		for i = 1, effect_count do
			local info = infos[i]

			if info.done == false then
				if time_passed >= info.delay then
					local effect = info.pool():Instantiate(info.pos, unity_class.quaternion.identity, self.middleground_layer)
					effect.transform.localScale = unity_class.vector3.one * info.scale
					table.insert(self.mg_effect_list, effect)
					info.done = true
					done_count = done_count + 1
				end
			end
		end

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end
	local effect_1 = self.get_fight_effect_5():Instantiate(vector(-155.5, -9, 8.3), unity_class.quaternion.identity, self.middleground_layer)
	effect_1.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_1)
	local effect_2 = self.get_fight_effect_3():Instantiate(vector(-138.5, -9, 9.1), unity_class.quaternion.identity, self.middleground_layer)
	effect_2.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_2)
	local effect_3 = self.get_fight_effect_3():Instantiate(vector(-124, -9, 7.5), unity_class.quaternion.identity, self.middleground_layer)
	effect_3.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_3)
	local effect_4 = self.get_fight_effect_3():Instantiate(vector(-148, -9, 8.3), unity_class.quaternion.identity, self.middleground_layer)
	effect_4.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_4)
	local effect_5 = self.get_fight_effect_4():Instantiate(vector(-132.5, -9, 9), unity_class.quaternion.identity, self.middleground_layer)
	effect_5.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_5)
	local effect_6 = self.get_fight_effect_4():Instantiate(vector(-116.5, -9, 9), unity_class.quaternion.identity, self.middleground_layer)
	effect_6.transform.localScale = unity_class.vector3.one * 0.7
	table.insert(self.mg_effect_list, effect_6)
end
--endregion

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_box_damage_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_wagon_damage_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.camera_pivot = nil
	self.camera = nil
	self.camera_height = nil
	self.camera_width = nil
	self.back_bg = nil
	self.item_dropper_cache = nil

	if is_unity_null(self.time_text) == false then
		CS.UnityEngine.Object.Destroy(self.time_text)
	end
	self.time_text = nil

	if is_unity_null(self.resholder) == false then
		self.resholder:Dispose()
	end
	self.resholder = nil

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.optimized_npcs_2 ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_npcs_2)
		self.optimized_npcs_2 = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.opening_resistance ~= nil then
		self.opening_resistance:Clear()
		self.opening_resistance = nil
	end
	if self.optimized_npcs_opening ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_npcs_opening)
		self.optimized_npcs_opening = nil
	end

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.optimized_npcs_iron ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_npcs_iron)
		self.optimized_npcs_iron = nil
	end
	self.iron_resistance = nil
	self.iron_invader = nil

	-- 동적 로딩한 캐릭터들 전부 제거
	if self.optimized_harvester ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_harvester)
		self.optimized_harvester = nil
	end

	for _, effect in pairs(self.mg_effect_list) do
		if is_unity_null(effect) == false then
			effect:Dispose()
		end
	end
	self.mg_effect_list = nil

	for _, attack_range in pairs(self.bombing_range_pool) do
		if is_unity_null(attack_range) == false then
			CS.UnityEngine.Object.Destroy(attack_range)
		end
	end
	self.bombing_range_pool = nil

	self.field_grid_info = nil
	self.field_grid_bounds = nil
	self.foreground_yz_pos = nil
	self.middleground_yz_pos = nil
	self.background_yz_pos = nil
	self.bombing_done_list = nil
	self.background_layer = nil
	self.middleground_layer = nil
	self.foreground_layer = nil
	self.background_yz_pos = nil
	self.middleground_yz_pos = nil
	self.foreground_yz_pos = nil

	if is_unity_null(self.spark_screen_effect) == false then
		self.spark_screen_effect:Dispose()
	end
	self.spark_screen_effect = nil

	if is_unity_null(self.meteor_effect) == false then
		self.meteor_effect:Dispose()
	end
	self.meteor_effect = nil

	if is_unity_null(self.meteor_back_effect) == false then
		self.meteor_back_effect:Dispose()
	end
	self.meteor_back_effect = nil

	if is_unity_null(self.smoke_effect_1) == false then
		self.smoke_effect_1:Dispose()
	end
	self.smoke_effect_1 = nil

	if is_unity_null(self.smoke_effect_2) == false then
		self.smoke_effect_2:Dispose()
	end
	self.smoke_effect_2 = nil

	if is_unity_null(self.smoke_effect_3) == false then
		self.smoke_effect_3:Dispose()
	end
	self.smoke_effect_3 = nil

	if is_unity_null(self.sniper_effect) == false then
		self.sniper_effect:Dispose()
	end
	self.sniper_effect = nil

	if is_unity_null(self.item_marker_info.object) == false then
		self.item_marker_info.object:Dispose()
	end
	self.item_marker_info.object = nil

	if is_unity_null(self.go_sign_info.object) == false then
		self.go_sign_info.object:Dispose()
	end
	self.go_sign_info.object = nil

	self.top_hp_bar = nil

	for i = 1, #self.cannon_ball_infos do
		local info = self.cannon_ball_infos[i]

		if is_unity_null(info.object) == false then
			info.object:Dispose()
		end

		if is_unity_null(info.trail_object) == false then
			info.trail_object:Dispose()
		end
	end
	self.cannon_ball_infos = nil

	--region 포로 스타피스

	-- 포로 쉐이크 이벤트 dispose처리
	if self.captive_shake_stat ~= nil then
		for i = 1, #self.captive_shake_stat do
			self.captive_shake_stat[i] = false
		end
		self.captive_shake_stat = nil
	end

	if self.help_icons ~= nil then
		for _, help_icon in pairs(self.help_icons) do
			if help_icon ~= nil then
				help_icon:Dispose()
			end
		end
		self.help_icons = nil
	end

	self.captives = nil

	if is_unity_null(self.meteor_effect) == false then
		self.meteor_effect:Dispose()
	end
	self.meteor_effect = nil
	--endregion

	self.hidden_box = nil
	self.coin_box = nil
	self.arcade_machine = nil

	self:stop_sfx_wagon_loop()

	self.cs_controller = nil
end

--region OnEvent
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	end
	--endregion

	return false
end

function local_class:on_stage_loaded()
	self.camera_pivot = stage_camera.Transform.parent
	self.camera = stage_camera.Camera

	self.back_bg = get_field_object('back_background')

	self.item_dropper_cache = {}
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_1'))
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_2'))
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_3'))
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_4'))
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_5'))
	table.insert(self.item_dropper_cache, get_field_object('item_dropper_6'))

	local x_rot = 45
	local camera_target_rot = unity_class.quaternion.AngleAxis(x_rot, vector(1, 0, 0))
	local bg_target_rot = unity_class.quaternion.AngleAxis(x_rot - 90, vector(1, 0, 0))

	self.camera_pivot.localRotation = camera_target_rot
	camera_util.resize_to(4.5, 0)
	stage_camera:OverrideDefaultCameraSize(4.5)

	self.camera_height = self.camera.orthographicSize
	self.camera_width = self.camera_height * self.camera.aspect

	local tilemap = field.Tilemap
	self.foreground_layer = tilemap.transform:Find('gimmick_foreground')
	self.middleground_layer = tilemap.transform:Find('gimmick_middleground')
	self.background_layer = tilemap.transform:Find('gimmick_background')

	self.foreground_layer.transform.localRotation = camera_target_rot
	self.middleground_layer.transform.localRotation = bg_target_rot
	self.background_layer.transform.localRotation = camera_target_rot

	local back_background = get_field_object('back_background')
	back_background.Transform.localRotation = unity_class.quaternion.AngleAxis(x_rot, vector(1, 0, 0))

	self:add_sorting_group(self.middleground_layer, -8)
	self:add_sorting_group(unity_object_pool.GetOrCreate('fx_stage1_sidescroll_smoke_middle').Transform, -9)
	self:add_sorting_group(self.background_layer, -10)
	self:add_sorting_group(unity_object_pool.GetOrCreate('fx_stage1_sidescroll_smoke_background').Transform, -11)
	self:add_sorting_group(back_background.Transform, -12)

	-- 그리드 가져옴
	for i = 0, field.CameraGrids.Count - 1 do
		local grid_info = field.CameraGrids[i]
		if grid_info.name == 'main_grid' then
			self.field_grid_info = grid_info
			self.field_grid_bounds = grid_info.bounds
		end
	end

	if self:is_belt_scroll_left() then
		self.meteor_effect = unity_object_pool.GetOrCreate('fx_stage1_sidescroll_meteor'):Instantiate(vector(0, -1, 0))
		--self.meteor_back_effect = unity_object_pool.GetOrCreate('fx_stage1_sidescroll_meteor_background'):Instantiate(vector(0, 0, 0), unity_class.quaternion.identity, self.background_layer)
		self.smoke_effect_1 = unity_object_pool.GetOrCreate('fx_stage1_sidescroll_smoke_front'):Instantiate(vector(0, 0, 0))
		self.smoke_effect_2 = unity_object_pool.GetOrCreate('fx_stage1_sidescroll_smoke_background'):Instantiate(vector(0, 0, 0), unity_class.quaternion.identity, self.background_layer)
		self.smoke_effect_3 = unity_object_pool.GetOrCreate('fx_stage1_sidescroll_smoke_middle'):Instantiate(vector(0, 0, 0), unity_class.quaternion.identity, self.background_layer)

		self.sniper_effect = unity_object_pool.GetOrCreate('fx_cp11_sniper_shoot_loop'):Instantiate(vector(8, 8, 2), unity_class.quaternion.identity, self.middleground_layer)
	end

	self.get_battle_invisible_wall(1).Hitbox = CS.Oak.Hitbox(vector(1, 1, 5))
	self.get_battle_invisible_wall(2).Hitbox = CS.Oak.Hitbox(vector(1, 1, 5))

	self:set_battles()

	-- TopHpBar 뜨던 문제 수정
	for _, item_dropper_data in pairs(self.item_info.dropper_data) do
		local dropper = self.item_dropper_cache[item_dropper_data.num]
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(dropper, true))
	end
	for i = 1, 7 do
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('extra_box_' .. i), true))
	end
	message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('coin_box'), true))
	message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('star_piece_drop_box'), true))
	message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('arcade_machine'), true))

	self.item_marker_info.object = self.get_move_icon():Instantiate(vector(999, 0, 999))
	self.item_marker_info.object.transform.localScale = unity_class.vector3.one * 0.4
	self.item_marker_info.skel_anim = self.item_marker_info.object:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
	self.item_marker_info.object.gameObject:SetActive(false)

	self.go_sign_info.object = self.get_move_icon():Instantiate(vector(1, 0.4, 0))
	if game_string.IsRTL then
		self.go_sign_info.object.transform.localScale = unity_class.vector3(-1, 1, 1) * 0.15
	else
		self.go_sign_info.object.transform.localScale = unity_class.vector3.one * 0.15
	end
	CS.Utils.ChangeLayersRecursively(self.go_sign_info.object.transform, 'UI')
	self.go_sign_info.skel_anim = self.go_sign_info.object:GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
	self.go_sign_info.object.gameObject:SetActive(false)

	local wagon = self.get_wagon()
	wagon.EntityGroup = CS.Oak.EntityGroups.Obstacle | CS.Oak.EntityGroups.Player
	wagon.Position = self.get_wagon_start_pos()
	wagon.FieldObjectStatsBehaviour.FieldObjectSpec.Hitbox = CS.Oak.Hitbox(vector(1 / 6, 0, 0.25),
			vector(2, 1, 2))

	for i = 1, #self.wagon_barrel_offsets do
		local wagon_barrel = self.get_wagon_barrel(i)
		wagon_barrel.Position = wagon.Position + self.wagon_barrel_offsets[i]
		wagon_barrel.Transform.parent = wagon.Transform
	end

	local rock_zone = field:GetZone('wagon_rock_zone')
	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(rock_zone.Bounds, unity_class.vector3.zero)

	for i = 0, obj_list.Count - 1 do
		local fo = obj_list[i]

		if lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.SmallRockBehaviour) then
			table.insert(self.rocks, fo)
		end
	end

	obj_list:Dispose()

	local wagon_resis =
	{
		get_character('s3_wagon_resistance_1'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}

	--character_util.set_position(wagon_resis[1], wagon.Position + vector(0, 0, 1.75))
	character_util.set_position(wagon_resis[2], wagon.Position + vector(1.95, 0, 1.75))
	character_util.set_position(wagon_resis[3], wagon.Position + vector(0, 0, -0.5))
	character_util.set_position(wagon_resis[4], wagon.Position + vector(1.95, 0, -0.5))

	for i = 2, 4 do
		character_util.set_anim(wagon_resis[i], { name = 'push' })
		character_util.set_emotion(wagon_resis[i], { name = 'damaged' })
	end

	for i = 1, #self.turret_infos do
		self.turret_infos[i].origin_pos = self.get_turret(i).Position
	end

	local heal_item_1 = drop_item_util.create_item(
			{ pos = field:GetMarker('item_dropped_pos_1').position,
			  target = nil,
			  itemid = 20262,
			  notforinven = true,
			  markforpick = false,
			  skip_text = true,
			  sprscale = 1.7,
			  lootstate = 'findlooter' })

	heal_item_1.PickFlyDistance = 0.5
	heal_item_1.Position =  heal_item_1.Position + 0.3 * unity_class.vector3.up

	local heal_item_2 = drop_item_util.create_item(
			{ pos = field:GetMarker('item_dropped_pos_2').position,
			  target = nil,
			  itemid = 20262,
			  notforinven = true,
			  markforpick = false,
			  skip_text = true,
			  sprscale = 1.7,
			  lootstate = 'findlooter' })

	heal_item_2.PickFlyDistance = 0.5
	heal_item_2.Position =  heal_item_2.Position + 0.3 * unity_class.vector3.up

	local heal_item_3 = drop_item_util.create_item(
			{ pos = field:GetMarker('item_dropped_pos_3').position,
			  target = nil,
			  itemid = 20264,
			  notforinven = true,
			  markforpick = false,
			  skip_text = true,
			  sprscale = 0.85,
			  lootstate = 'findlooter' })

	heal_item_3.PickFlyDistance = 0.5
	heal_item_3.Position =  heal_item_3.Position + 0.3 * unity_class.vector3.up

	local heal_item_4 = drop_item_util.create_item(
			{ pos = field:GetMarker('item_dropped_pos_4').position,
			  target = nil,
			  itemid = 20262,
			  notforinven = true,
			  markforpick = false,
			  skip_text = true,
			  sprscale = 1.7,
			  lootstate = 'findlooter' })

	heal_item_4.PickFlyDistance = 0.5
	heal_item_4.Position =  heal_item_4.Position + 0.3 * unity_class.vector3.up

	if star_piece_util.has_star_piece('captive_star_piece') == false then
		self.twinkle_effect = self.get_fx_object_twinkle():Instantiate(self.get_star_inv_floor().Position)
	else
		self.get_star_inv_floor().ActiveState = active_state('disabled')
	end

end

function local_class:add_sorting_group(transform, order, layer)
	local sorting_group = transform.gameObject:AddComponent(typeof(CS.UnityEngine.Rendering.SortingGroup))
	sorting_group.sortingOrder = order
	sorting_group.sortingLayerName = lua_helper.get_or_default(layer, 'Under Effects')
end

function local_class:on_box_damage_event(e)
	-- 데미지 이벤트 받을때마다 모든 조건문 다 도는데, 해당 기믹들만 처리하기 위해 조건 추가
	if lua_helper.type_compare(e.Info.target.DamagedBehaviour, CS.Oak.XMasSurvivalObjectDamagedBehaviour) then
		for key, data in pairs(self.item_info.dropper_data) do
			local fo = self.item_dropper_cache[data.num]
			if lua_helper.reference_equals(e.Info.target, fo) and data.destroyed == false and fo.gameObject.activeSelf == false then
				self.item_info.dropper_data[key].destroyed = true
				self:fo_drop_item(fo, data.drop_item)
			end
		end

		--region 박스 드랍 스타피스
		if self.hidden_box ~= nil and lua_helper.reference_equals(e.Info.target, self.hidden_box)
				and self.hidden_box.gameObject.activeSelf == false then
			if not CS.Oak.StageProgress.Current:HasStarPiece(self.hidden_box_star_piece_name) then
				local star_piece = get_field_object(self.hidden_box_star_piece_name)
				message_system:SendSync(star_piece, CS.Oak.StarPieceAppearEvent.Create(self.hidden_box.Position))
			end
			self.hidden_box = nil
			return true
		end
		--endregion

		--region 아케이드 머신 스타피스
		if self.coin_box ~= nil and lua_helper.reference_equals(e.Info.target, self.coin_box)
				and self.coin_box.gameObject.activeSelf == false then
			message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { self.arcade_machine_coin_event }))
			self.coin_box = nil
			return true
		elseif self.arcade_machine ~= nil and lua_helper.reference_equals(e.Info.target, self.arcade_machine)
				and self.arcade_machine.gameObject.activeSelf == false then
			speech_bubble_util.remove_bubble(self.arcade_machine)
			self.arcade_machine = nil
			return true
		end
		--endregion
	end

	return false
end

function local_class:on_wagon_damage_event(e)
	if self.current_wagon_state ~= self.wagon_state.destroyed
			and e.Info.target == self.get_wagon()
			and (e.Info.sender.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then
		self:damage_wagon(self.wagon_monster_damage, e.Info.direction)
		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)

	if lua_helper.reference_equals(e.FieldObject, self.get_super_invader()) then
		self.is_turret_battle = false
		self.is_sohee_move = false
		--self:remove_camera_limiting()
		self:remove_battle_gate()
		self:show_go_sign(3)
		-- 최적화를 위해 이전 미션 직후에 불러줌
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wagon_stucked_before_escort, self))
		character_util.remove_anim(self:get_sohee())
		return true

	elseif lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		-- LateUpdateFrame에서 카메라 갱신 조건 체크할 것이므로 그보다 먼저 처리될 죽은 연출 처리가 제대로 불리도록 함
		self.stage_camera_info.state = self.stage_camera_state.idle
		self.leader_dead = true
		return true

	elseif lua_helper.reference_equals(e.FieldObject, self.get_star_inv_floor()) then
		if star_piece_util.has_star_piece('captive_star_piece') == false then
			local inv_floor = self.get_star_inv_floor()
			star_piece_util.appear(self.get_barrel_star_piece(), inv_floor.Position, inv_floor.Position)
			if self.twinkle_effect ~= nil then
				self.twinkle_effect:Dispose()
			end
		end

		return true
	end

	for battle_key, _ in pairs(self.battle_infos) do
		local battle_info = self.battle_infos[battle_key]
		for i = 1, battle_info.monster_count do
			if lua_helper.reference_equals(e.FieldObject, self.get_monster(battle_info.battle_num, i)) then
				battle_info.monster_count_to_dead = battle_info.monster_count_to_dead - 1
				if battle_info.monster_count_to_dead > 0 then

					if battle_info.monster_count_to_respawn > 0 then
						battle_info.monster_count_to_respawn = battle_info.monster_count_to_respawn - 1
						self:insert_battle_respawn_queue(battle_key, i,false)
					end

				else
					self:dispose_battle(battle_key)
				end
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		local zone_name = e.Zone.Name

		if zone_name == self.bombing_zone_name and self.current_bombing_state == self.bombing_state.none then
			self:start_bombing()
		end

		if zone_name == self.main_zone_names.panda_talk
				and self.current_main_state == self.main_state.before_panda then
			self:custom_progress_section()
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.panda_talk, self))

		elseif zone_name == self.main_zone_names.aisha_rush
				and self.current_main_state == self.main_state.before_aisha then
			self:custom_progress_section()
			self:add_item_marker_to_point(self.get_item_dropper(2).Position + vector(0, 0.4, 0))
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.aisha_rush_fight, self))

		elseif zone_name == self.main_zone_names.iron_teatan
				and self.current_main_state == self.main_state.before_iron_teatan then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatan_bg, self))
			self:custom_progress_section()
			-- 아이언 티탄

		elseif zone_name == self.main_zone_names.wagon_escort_active
				and self.current_main_state == self.main_state.before_wagon_escort then
			self:custom_progress_section()
			self:set_camera_limiting('wagon_meet')
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.escort_start, self))

		elseif zone_name == self.main_zone_names.harvester_fly
				and self.current_main_state == self.main_state.wagon_escorting then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.harvester_fly, self))
			self:custom_progress_section()
			-- 하베스터 전투

		else
			for battle_key, battle_info in pairs(self.battle_infos) do
				if e.Zone.Name == battle_info.active_zone_name and battle_info.state == self.battle_state.idle then
					self:active_battle(battle_key)
				end
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if e.Zone.Name == self.bombing_zone_name and self.current_bombing_state ~= self.bombing_state.none then
			self:stop_bombing()
		end
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	return false
end

function local_class:on_item_get_event(e)
	if lua_helper.type_compare(e, CS.Oak.ItemGetEvent) then
		if e.Getter == user_party.Leader then
			for item_name, item in pairs(self.item_info.items) do
				if e.Item.ItemId == item.id then
					if item.type == 'heal' then
						local heal_info = CS.Oak.HealInfo()
						heal_info.type = CS.Oak.HealType.Normal
						heal_info.sender = user_party.Leader
						heal_info.target = user_party.Leader
						heal_info.heal = math.floor(user_party.Leader.CharacterStatsBehaviour.MaxHP * item.heal_ratio)

						command_util.execute_heal(heal_info)
					elseif item.type == 'libera' then
						if self.current_main_state == self.main_state.before_get_libera then
							sp_util.play_normal_screenplay(self.gain_libera, self)
						end
					elseif item.type == 'gatling_gun' then
						if self.current_main_state == self.main_state.before_sohee_gatling then
							sp_util.play_normal_screenplay(self.gain_gatling_gun, self)
						end
					end

					if item.need_mark then
						self:remove_item_marker()
					end

					return true
				end
			end
		end

	end
	return false
end

function local_class:on_interact_event(e)
	--region 포로 스타피스
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		for i, captive in ipairs(self.captives) do
			if lua_helper.reference_equals(e.Target, captive) then
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.rescue_captive, self, captive, i + 1))	-- 인덱스가 한칸씩 밀렸음...
				return true
			end
		end
	end
	return false
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		self.leader_dead = false
	end
end

--endregion

function local_class:show_go_sign(duration)
	if duration ~= nil then
		self.go_sign_info.duration = duration
	end

	music_player_util.play_sfx({ sfx_name = '01_go_01', type_priority = 'event', player_priority = 'npc' })
	if self.go_sign_info.object.activeSelf then	-- 해당 루틴 종료 전에 실행된 경우
		self.go_sign_info.time_passed = 0
	else
		self.go_sign_info.time_passed = 0

		self.go_sign_info.skel_anim.AnimationState:SetAnimation(0, 'go', true)
		self.go_sign_info.object.gameObject:SetActive(true)
	end
end

function local_class:hide_go_sign()
	self.go_sign_info.object.gameObject:SetActive(false)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'stop_bombing' then
		self:stop_bombing()

	elseif e:GetParamAt(0) == 'start_bombing' then
		self:start_bombing()

	elseif e:GetParamAt(0) == 'bombing_active' then
		if e:GetParamAt(1) == 'disabled' then
			self.bombing_active = false
		elseif e:GetParamAt(1) == 'enabled' then
			self.bombing_active = true
		end

	elseif e:GetParamAt(0) == 'section_5' then
		for i = 1, #self.captive_shake_stat do
			self.captive_shake_stat[i] = false
		end
		self.captive_shake_stat = nil
	elseif e:GetParamAt(0) == 'section_6' then
		self:recover_tilemap()
		if is_unity_null(self.spark_screen_effect) == false then
			self.spark_screen_effect:Dispose()
		end
		self.spark_screen_effect = nil

	elseif e:GetParamAt(0) == 'bg_back_toggle' then
		self.bg_back = false

	elseif e:GetParamAt(0) == 'spark_on' then
		self.spark_screen_effect = unity_object_pool.GetOrCreate('fx_stage1_spark_screen_fx'):Instantiate(stage_camera.Transform.position, unity_class.quaternion.identity, stage_camera.Transform)
		self.spark_screen_effect.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)

	elseif  e:GetParamAt(0) == 'spark_off' then
		if is_unity_null(self.spark_screen_effect) == false then
			self.spark_screen_effect:Dispose()
		end
		self.spark_screen_effect = nil

	elseif e:GetParamAt(0) == 'section2_preload' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.preload_main_opening, self, false))

	elseif e:GetParamAt(0) == 'section2_start' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.main_opening, self))

	elseif e:GetParamAt(0) == 'section2_section_progressed' then
		self.wait_progressing_section = false

	elseif e:GetParamAt(0) == 'section3_section_progressed' then
		self.wait_progressing_section = false

	elseif e:GetParamAt(0) == 'interacting' then
		local wagon_inv = self.get_wagon_interact()

		if lua_helper.reference_equals(e.Sender, wagon_inv) then
			if self.current_main_state == self.main_state.meet_wagon then
				wagon_inv.Position = vector(999, 0, 999)
				ui_quest_marker:RemoveQuestMarker('wagon')
				self.stucked = false
				speech_bubble_util.remove_bubble(self.get_princess())
				self:custom_progress_section()
				self:remove_camera_limiting()
				--self:set_camera_limiting('wagon_battle')
				self:set_battle_gate('wagon_battle')
			else
				wagon_inv.Position = vector(999, 0, 999)
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wagon_pull_success, self))
			end
			return true
		end
	end

	return false
end

--region 카메라 이동
function local_class:use_late_update_frame()
	return true
end

function local_class:is_belt_scroll_left()
	local main_quest = CS.Oak.UserProgress.Instance:GetStartedQuest(self.main_quest_id)

	-- 섹션 5, 6인 경우 아예 안씀
	return main_quest == nil or (main_quest.InnerProgress < 4 or main_quest.InnerProgress > 5)
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.Last
end

function local_class:late_update_frame(dt)
	if self.field_grid_info == nil then
		return
	end

	local cur_min_x = self.stage_camera_info.min_x + self.camera_width
	local cur_max_x = self.stage_camera_info.max_x - self.camera_width

	if self.stage_camera_info.state == self.stage_camera_state.limiting then
		local target_x_pos = self.field_grid_info:GetCameraPosInGrid(self.stage_camera_info.target.Position,
				self.camera_width, self.camera_height).x

		if cur_max_x < cur_min_x then
			target_x_pos = (cur_min_x + cur_max_x) / 2	-- 혹시라도 카메라 사이즈가 더 커졌을 때를 대비
		elseif target_x_pos < cur_min_x then
			target_x_pos = cur_min_x
		elseif target_x_pos > cur_max_x then
			target_x_pos = cur_max_x
		end

		local target_dif = vector_util.get_0yz(self.stage_camera_info.target.Position, target_x_pos)
				- self.stage_camera_info.prev_pos
		local move_dist = unity_class.time.deltaTime * self.stage_camera_info.lerp_move_speed
		if math.abs(target_dif.magnitude) > move_dist then
			if target_dif.magnitude < 0 then
				move_dist = move_dist * -1
			end

			self.camera_pivot.position = self.field_grid_info:GetCameraPosInGrid(
					target_dif.normalized * move_dist + self.stage_camera_info.prev_pos,
					self.camera_width, self.camera_height)
		else
			stage_camera:SetTarget(self.stage_camera_info.target)
			self.camera_pivot.position = self.field_grid_info:GetCameraPosInGrid(
					vector_util.get_0yz(self.stage_camera_info.target.Position, target_x_pos),
					self.camera_width, self.camera_height)
			self.stage_camera_info.state = self.stage_camera_state.limited
		end

	elseif self.stage_camera_info.state == self.stage_camera_state.limited then
		local target_x_pos = self.camera_pivot.position.x

		if cur_max_x < cur_min_x then
			target_x_pos = (cur_min_x + cur_max_x) / 2	-- 혹시라도 카메라 사이즈가 더 커졌을 때를 대비
		elseif target_x_pos < cur_min_x then
			target_x_pos = cur_min_x
		elseif target_x_pos > cur_max_x then
			target_x_pos = cur_max_x
		end

		self.camera_pivot.position = vector_util.get_0yz(self.camera_pivot.position, target_x_pos)

	elseif self.stage_camera_info.state == self.stage_camera_state.returning then
		local target_x_pos = self.field_grid_info:GetCameraPosInGrid(self.stage_camera_info.target.Position,
				self.camera_width, self.camera_height).x

		local target_dif = vector_util.get_0yz(self.stage_camera_info.target.Position, target_x_pos)
				- self.stage_camera_info.prev_pos
		local move_dist = unity_class.time.deltaTime * self.stage_camera_info.return_move_speed
		if math.abs(target_dif.magnitude) > move_dist then
			if target_dif.magnitude < 0 then
				move_dist = move_dist * -1
			end
			self.camera_pivot.position = self.field_grid_info:GetCameraPosInGrid(
					target_dif.normalized * move_dist + self.stage_camera_info.prev_pos,
					self.camera_width, self.camera_height)
		else
			stage_camera:SetTarget(self.stage_camera_info.target)
			self.camera_pivot.position = self.field_grid_info:GetCameraPosInGrid(
					vector_util.get_0yz(self.stage_camera_info.target.Position, target_x_pos),
					self.camera_width, self.camera_height)
			self.stage_camera_info.state = self.stage_camera_state.idle
		end
	end

	-- 현재 메인 그리드에 있지 않다면 아래 로직은 실행할 필요가 없다.
	if not self.field_grid_bounds:Contains(self.camera_pivot.position) then
		return
	end

	local cur_cam_x_pos = self.camera_pivot.position.x
	local cam_min_x_pos = self.field_grid_bounds.min.x - self.grid_side_gap + self.camera_width
	local cam_max_x_pos = self.field_grid_bounds.max.x + self.grid_side_gap - self.camera_width
	local normalized = unity_class.mathf.Clamp01((cur_cam_x_pos - cam_min_x_pos) / (cam_max_x_pos - cam_min_x_pos))

	-- normalized 값이 변경되었을 때에만 값이 바뀌기때문에 변경되었을때에만 실행해준다.
	if self.before_normalized_pos ~= normalized  then
		local fg_move_dist = self.field_grid_bounds.size.x + self.grid_side_gap * 2 - self.foreground_width		-- 음수
		local mg_move_dist = self.field_grid_bounds.size.x + self.grid_side_gap * 2 - self.middleground_width
		local bg_move_dist = self.field_grid_bounds.size.x + self.grid_side_gap * 2 - self.background_width

		self.foreground_layer.position = vector_util.get_0yz(self.foreground_yz_pos,
				self.foreground_x_offset - self.grid_side_gap + fg_move_dist * normalized)
		self.middleground_layer.position = vector_util.get_0yz(self.middleground_yz_pos,
				self.middleground_x_offset - self.grid_side_gap + mg_move_dist * normalized)
		self.background_layer.position = vector_util.get_0yz(self.background_yz_pos,
				self.background_x_offset - self.grid_side_gap + bg_move_dist * normalized)

		self.before_normalized_pos = normalized
	end

	if self.bg_back == true and self.stage_camera_info.prev_pos.x ~= self.camera_pivot.position.x then
		self.back_bg.transform.position = vector(self.camera_pivot.position.x, -25, 15)
	end

	-- GO Sign
	if self.go_sign_info.object.gameObject.activeSelf then
		self.go_sign_info.time_passed = self.go_sign_info.time_passed + unity_class.time.deltaTime
		if self.go_sign_info.time_passed >= self.go_sign_info.duration then
			self:hide_go_sign()
		end
	end

	self.stage_camera_info.prev_pos = self.camera_pivot.position
end

function local_class:set_camera_limiting(zone_name)
	local zone_bounds = field:GetZone(zone_name).Bounds

	self.stage_camera_info.min_x = zone_bounds.min.x
	self.stage_camera_info.max_x = zone_bounds.max.x

	stage_camera:SetTarget(nil)	-- 현재 지정된 타겟 벗어남
	self.stage_camera_info.target = user_party.Leader
	self.stage_camera_info.state = self.stage_camera_state.limiting

	self.get_battle_invisible_wall(1).Position = vector(zone_bounds.min.x - 0.5, 0, -1)
	self.get_battle_invisible_wall(2).Position = vector(zone_bounds.max.x + 0.5, 0, -1)
end

function local_class:remove_camera_limiting()
	self.stage_camera_info.state = self.stage_camera_state.returning

	self.get_battle_invisible_wall(1).Position = vector(999, 0, 999)
	self.get_battle_invisible_wall(2).Position = vector(999, 0, 999)
end

function local_class:set_battle_gate(zone_name)
	local zone_bounds = field:GetZone(zone_name).Bounds


	for i = 1, 3 do
		local gate = self.get_battle_gate(i)
		gate.Position = vector(zone_bounds.min.x - 1, 0, 3 - 2 * i)
	end

	for i = 1, 3 do
		local gate = self.get_battle_gate(i + 3)
		gate.Position = vector(zone_bounds.max.x + 1, 0, 3 - 2 * i)
	end

	for i = 1, 6 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('battle_2_gate_' .. i, true))
	end
end

function local_class:remove_battle_gate()
	for i = 1, 6 do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create('battle_2_gate_' .. i, true))
	end
end

--endregion

--region 리스폰 전투 시스템
function local_class:set_battles()
	for battle_key, _ in pairs(self.battle_infos) do
		local battle_info = self.battle_infos[battle_key]
		if battle_info.on_load_callback ~= nil then
			battle_info:on_load_callback(self)
		end
	end
end

function local_class:active_battle(battle_key)
	local battle_info = self.battle_infos[battle_key]
	--self:set_camera_limiting(battle_info.battle_zone_name)
	self:set_battle_gate(battle_info.battle_zone_name)

	if battle_info.start_callback ~= nil then
		battle_info:start_callback(self)
	else
		for i = 1, battle_info.monster_count do
			local monster = self.get_monster(battle_info.battle_num, i)
			monster.Position = vector(999, 0, 999)
			monster.ActiveState = active_state('visible')
			self:insert_battle_respawn_queue(battle_key, i, true, (i - 1) * 0.1)
		end
	end

	battle_info.state = self.battle_state.in_battle

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.battle_respawn_routine, self, battle_key))
end

function local_class:dispose_battle(battle_key)
	local battle_info = self.battle_infos[battle_key]
	battle_info.state = self.battle_state.done

	if battle_info.end_callback ~= nil then
		battle_info:end_callback(self)
	else
		-- self:remove_camera_limiting()
		self:remove_battle_gate()

		self:show_go_sign(3)
	end
end

function local_class:insert_battle_respawn_queue(battle_key, monster_index, immediately, respawn_delay)
	table.insert(self.battle_infos[battle_key].respawn_queue, {
		battle_num = self.battle_infos[battle_key].battle_num,
		monster_index = monster_index,
		type = '',	-- 리스폰 루틴 내에서 결정함
		state = immediately and self.monster_respawn_state.after_heal or self.monster_respawn_state.before_heal,
		respawn_delay = lua_helper.get_or_default(respawn_delay, 0),
		time_passed = 0,
		respawn_pos = nil,	-- 리스폰 루틴 내에서 결정함
		bombing_range = nil	-- 오우거인 경우만 사용
	})
end

function local_class:remove_battle_respawn_queue(battle_key, index)
	local battle_info = self.battle_infos[battle_key]
	table.remove(battle_info.respawn_queue, index)
end

function local_class:get_pos_to_respawn(battle_key, type)
	local battle_info = self.battle_infos[battle_key]
	local respawn_info = self.respawn_type_infos[type]
	local usable_indexes = {}
	local max_tp = 0
	local max_tp_index = 0

	for i = 1, #respawn_info.marker_indexes do
		local marker_index = respawn_info.marker_indexes[i]

		if battle_info.respawn_last_times[marker_index] == nil
				or unity_class.time.time - battle_info.respawn_last_times[marker_index] > self.respawn_pos_cool_time then
			table.insert(usable_indexes, marker_index)
		elseif max_tp < unity_class.time.time - battle_info.respawn_last_times[marker_index] then
			max_tp = unity_class.time.time - battle_info.respawn_last_times[marker_index]
			max_tp_index = marker_index
		end
	end

	if #usable_indexes == 0 then	-- 쿨이 다 돈 마커가 존재하지 않으면
		battle_info.respawn_last_times[max_tp_index] = unity_class.time.time
		return self.get_monster_respawn_marker(battle_info.battle_num, max_tp_index).position
	end

	local rand_index = random_util.get_random_int(1, #usable_indexes)
	battle_info.respawn_last_times[usable_indexes[rand_index]] = unity_class.time.time

	return self.get_monster_respawn_marker(battle_info.battle_num, usable_indexes[rand_index]).position
end

-- 리스폰 된 적 없는 시간 크기가 클 수록 가중치를 줌
function local_class:get_respawn_type(battle_key, monster_class)
	local battle_info = self.battle_infos[battle_key]
	local sum_max = 0
	local sum_max_type = ''
	for _, type_name in pairs(self.monster_respawn_type[monster_class]) do
		local sum = 0
		for _, marker_index in pairs(self.respawn_type_infos[type_name].marker_indexes) do
			if battle_info.respawn_last_times[marker_index] ~= nil then
				sum = sum + unity_class.time.time - battle_info.respawn_last_times[marker_index]
			else
				sum = sum + unity_class.time.time
			end
		end

		if sum_max < sum then
			sum_max = sum
			sum_max_type = type_name
		end
	end

	return sum_max_type
end

-- MoveTo 돌리기에는 코루틴 쓰는게 걸려서 따로 만듦
function local_class:monster_move(monster, target_pos, duration, jump_height, run)
	local speed = (target_pos - monster.Position).magnitude / duration
	run = lua_helper.get_or_default(run, false)
	--character_util.set_anim(monster, {name = 'get'})
	if jump_height ~= nil then
		character_util.jump(monster, jump_height, duration)
	end
	-- Visible 상태일 것이므로 플레이어가 이동중인 몬스터에게 갖다 박거나 하는 일은 없음
	wp_util.move_way_points(monster, {waypoints 	= target_pos, speed = speed, run = run})
end

function local_class:battle_respawn_routine(battle_key)
	local battle_info = self.battle_infos[battle_key]
	local battle_zone_bounds = field:GetZone(battle_info.battle_zone_name).Bounds
	local left_respawn_start_x = battle_zone_bounds.min.x - 1
	local right_respawn_start_x = battle_zone_bounds.max.x + 1
	local princess = self.get_princess()
	local monsters = {}
	for i = 1, battle_info.monster_count do
		table.insert(monsters, self.get_monster(battle_info.battle_num, i))
	end

	while battle_info.state == self.battle_state.in_battle do
		local done_list = {}

		for i = 1, #battle_info.respawn_queue do
			local respawn_info = battle_info.respawn_queue[i]
			if respawn_info.state == self.monster_respawn_state.before_heal
					and monsters[respawn_info.monster_index].gameObject.activeSelf == false then	-- 실제로 비활성화 될 때 까지 기다림
				local monster = monsters[respawn_info.monster_index]

				character_util.convert_to_npc(monster)
				character_util.set_position(monster, vector(999, 0, 999))

				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = monster
				heal_info.target = monster
				heal_info.heal = monster.FieldObjectStatsBehaviour.MaxHP
				heal_info.isRevive = true
				heal_info.skipEffect = true

				command_util.execute_heal(heal_info)

				respawn_info.time_passed = 0
				respawn_info.state = self.monster_respawn_state.after_heal

			elseif respawn_info.state == self.monster_respawn_state.after_heal
					and respawn_info.time_passed >= respawn_info.respawn_delay then
				local monster = monsters[respawn_info.monster_index]
				local monster_class = monster.CharacterStatsBehaviour.CharacterSpec.Class
				respawn_info.type = self:get_respawn_type(battle_key, monster_class)
				respawn_info.respawn_pos = self:get_pos_to_respawn(battle_key, respawn_info.type)
				character_util.set_active_state(monster, 'visible')

				if respawn_info.type == self.respawn_type_infos.left.name then
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, left_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Right
					music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', type_priority = 'gimmick', player_priority = 'npc' })
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.left.respawning_time, 3)

				elseif respawn_info.type == self.respawn_type_infos.right.name then
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, right_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Left
					music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', type_priority = 'gimmick', player_priority = 'npc' })
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.right.respawning_time, 3)

				elseif respawn_info.type == self.respawn_type_infos.up.name then
					monster.Position = vector(respawn_info.respawn_pos.x, -8, 6)
					monster.LockedDirection = respawn_info.respawn_pos.x < user_party.Leader.Position.x
							and CS.Oak.Direction.Right or CS.Oak.Direction.Left
					music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', type_priority = 'gimmick', player_priority = 'npc' })
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.up.respawning_time, 5)

				elseif respawn_info.type == self.respawn_type_infos.down.name then
					monster.Position = vector(respawn_info.respawn_pos.x, 8, -16)
					monster.LockedDirection = respawn_info.respawn_pos.x < user_party.Leader.Position.x
							and CS.Oak.Direction.Right or CS.Oak.Direction.Left
					character_util.set_scale_factor(monster, nil, 3)
					music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01', type_priority = 'gimmick', player_priority = 'npc' })
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.down.respawning_time, 1.5)

				elseif respawn_info.type == self.respawn_type_infos.walk_left.name then
					character_util.spine_set_alpha_fade(monster, 0, 0)
					character_util.spine_set_alpha_fade(monster, 1, 1)
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, left_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Right
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.walk_left.respawning_time)

				elseif respawn_info.type == self.respawn_type_infos.walk_right.name then
					character_util.spine_set_alpha_fade(monster, 0, 0)
					character_util.spine_set_alpha_fade(monster, 1, 1)
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, right_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Left
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.walk_right.respawning_time)

				elseif respawn_info.type == self.respawn_type_infos.dash_left.name then
					character_util.spine_set_alpha_fade(monster, 0, 0)
					character_util.spine_set_alpha_fade(monster, 1, 1)
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, left_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Right
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.dash_left.respawning_time, nil, true)

				elseif respawn_info.type == self.respawn_type_infos.dash_right.name then
					character_util.spine_set_alpha_fade(monster, 0, 0)
					character_util.spine_set_alpha_fade(monster, 1, 1)
					monster.Position = vector_util.get_0yz(respawn_info.respawn_pos, right_respawn_start_x)
					monster.Direction = CS.Oak.Direction.Left
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.dash_right.respawning_time, nil, true)

				elseif respawn_info.type == self.respawn_type_infos.teleport.name then
					monster.Position = respawn_info.respawn_pos
					character_util.look_at(monster, user_party.Leader)
					music_player_util.play_sfx({ sfx_name = '01_invader_beam_01', type_priority = 'gimmick', player_priority = 'npc' })
					self.get_fx_invader_beam():Instantiate(respawn_info.respawn_pos)
					-- 따로 MoveWayPoint를 걸지 않기 때문에 다음 프레임에 respawning이 끝날 것임

				elseif respawn_info.type == self.respawn_type_infos.fall.name then
					monster.Position = respawn_info.respawn_pos + vector(0, 30, 0)
					character_util.set_anim(monster, { name = 'buttbounce' })
					monster.LockedDirection = respawn_info.respawn_pos.x < user_party.Leader.Position.x
							and CS.Oak.Direction.Right or CS.Oak.Direction.Left
					respawn_info.bombing_range = self:get_bombing_range()
					respawn_info.bombing_range.transform.position = respawn_info.respawn_pos
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.fall.respawning_time)
				elseif respawn_info.type == self.respawn_type_infos.harvester.name then
					monster.Position = respawn_info.respawn_pos + vector(25, 10, 0)
					camera_util.shake(0.1, self.respawn_type_infos.fall.respawning_time)
					character_util.set_anim(monster, { name = 'appear_charge' })
					monster.LockedDirection = CS.Oak.Direction.Left
					music_player_util.play_sfx({ sfx_name = '02_harvester_prepare_01', type_priority = 'gimmick', player_priority = 'npc' })
					self:monster_move(monster, respawn_info.respawn_pos,
							self.respawn_type_infos.fall.respawning_time)
				end

				respawn_info.time_passed = 0
				respawn_info.state = self.monster_respawn_state.respawning

			elseif respawn_info.state == self.monster_respawn_state.respawning then
				-- 몬스터가 아직 움직이는 중이면
				local monster = monsters[respawn_info.monster_index]
				if monster.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped then
					if respawn_info.type == self.respawn_type_infos.down.name then
						--local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseInQuart(
						--		respawn_info.time_passed, 0, 1, self.respawn_type_infos.down.respawning_time))

						local progress = unity_class.mathf.Clamp01(
								respawn_info.time_passed / self.respawn_type_infos.down.respawning_time)

						character_util.set_scale_factor(monster, nil, 1 + 2 * (1 - progress))
					end
				else
					if respawn_info.type == self.respawn_type_infos.fall.name then
						self:dispose_bombing_range(respawn_info.bombing_range)
						character_util.remove_anim(monster)
						camera_util.shake(0.3, 0.3)
						music_player_util.play_sfx({ sfx_name = '03_mech_stomp_01', type_priority = 'event', player_priority = 'npc' })

						local hits = field:GetFieldObjectsInCylinder(respawn_info.respawn_pos, self.bombing_radius, 3)

						for i = 0, hits.Count - 1 do
							local fo = hits.Values[i]
							if lua_helper.reference_equals(fo, user_party.Leader)
									or lua_helper.reference_equals(fo, princess) then
								local damage_info = CS.Oak.DamageInfo()
								damage_info.type = CS.Oak.DamageType.Melee
								damage_info.target = fo
								damage_info.sender = monster
								damage_info.damage = math.floor(CS.Oak.StatCalculator.GetDps(monster))

								local cmd = CS.Oak.DamageCommand.Create(damage_info)
								command_util.publish_cmd(CS.Oak.Player.Local, cmd)
							end
						end

						hits:Dispose()

					elseif respawn_info.type == self.respawn_type_infos.harvester.name then
						character_util.remove_anim(monster)
						music_player_util.play_stage_music({state = 'combat', name = 'bgm_battle_boss', mix = 2})
					end

					monster.LockedDirection = CS.Oak.Direction.None
					monster.Position = respawn_info.respawn_pos
					character_util.set_scale_factor(monster, nil, 1)
					character_util.remove_anim(monster)
					character_util.look_at(monster, user_party.Leader)
					character_util.set_active_state(monster, 'enabled')
					if not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
							CS.Oak.CharacterControllerScreenplayState) then
						character_util.convert_to_monster(monster, battle_info.group_name, battle_info.battle_zone_name)
						command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
					end

					table.insert(done_list, i - #done_list)
					respawn_info.state = self.monster_respawn_state.respawn_over
				end
			end

			respawn_info.time_passed = respawn_info.time_passed + unity_class.time.deltaTime
		end

		for i = 1, #done_list do
			self:remove_battle_respawn_queue(battle_key, done_list[i])
		end

		coroutine.yield()
	end
end
--endregion

--region 아이템 드롭하는 오브젝트

function local_class:fo_drop_item(fo, item_name)
	local item_data = self.item_info.items[item_name]
	local spr_scale = lua_helper.get_or_default(item_data.sprite_scale, self.item_info.default_sprite_scale)

	local drop_item = drop_item_util.create_item(
			{pos = fo.Position + vector(0, 0.2, 0), itemid = item_data.id,
			 notforinven = true, sprscale = spr_scale, skip_text = true})
	drop_item.PickFlyDistance = self.item_info.pick_fly_dist

	if item_data.need_mark then
		--ui_quest_marker:AddQuestMarkerToPoint(item_name, self.main_quest_id, true, fo.Position)
		self:add_item_marker_to_point(fo.Position)
	end
end

function local_class:add_item_marker_to_point(target_pos)
	self.item_marker_info.object.transform.position = target_pos + vector(0, 1, 0)
	self.item_marker_info.skel_anim.AnimationState:SetAnimation(0, 'in', true)
	self.item_marker_info.object.gameObject:SetActive(true)
end

function local_class:remove_item_marker()
	--self.item_marker_info.object.transform.position = vector(999, 1, 999)
	self.item_marker_info.object.gameObject:SetActive(false)
end

--endregion

--region 폭격 이벤트
function local_class:load_bombing_range_pool()
	for _ = 1, self.bombing_range_pool_size do
		local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.bombing_radius)
		attack_range:Show()
		attack_range.gameObject:SetActive(false)
		table.insert(self.bombing_range_pool, attack_range)
	end
end

function local_class:get_bombing_range()
	for i = 1, #self.bombing_range_pool do
		local attack_range = self.bombing_range_pool[i]
		if attack_range.gameObject.activeSelf == false then
			attack_range.gameObject:SetActive(true)
			return attack_range
		end
	end

	-- 풀에서 전부 끌어다 썼을 때
	local new_attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.bombing_radius)
	new_attack_range:Show()
	table.insert(self.bombing_range_pool, new_attack_range)

	return new_attack_range
end

function local_class:dispose_bombing_range(range)
	range.gameObject:SetActive(false)
end

function local_class:start_bombing()
	self.current_bombing_state = self.bombing_state.in_zone
	--camera_util.shake(0.07, 1)

	self.bombing_done_count = self.bombing_done_count + 1
	self.bombing_done_list[self.bombing_done_count] = false

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.bombing_routine, self, self.bombing_done_count))
end

function local_class:stop_bombing()
	self.current_bombing_state = self.bombing_state.none

	for key, _ in pairs(self.bombing_done_list) do
		self.bombing_done_list[key] = true
	end
end

function local_class:bombing_routine(routine_index)
	wait_for_sec(1.0)

	while self.current_bombing_state ~= self.bombing_state.none and self.bombing_active
			and self.bombing_done_list ~= nil and self.bombing_done_list[routine_index] == false do
		if self.current_bombing_state == self.bombing_state.in_zone then
			self:bomb_fall(user_party.Leader.Position, 0.5)
		end

		wait_for_sec(1)
	end

	if self.bombing_done_list ~= nil then
		self.bombing_done_list[routine_index] = nil
	end
end

function local_class:bomb_fall(target_pos, delay)
	local start_y = 10
	local target_y = 0
	target_pos.y = target_y

	local attack_range = self:get_bombing_range()
	attack_range.transform.position = vector_util.get_x0z(target_pos, 0.1)

	local dmg_multiplier = CS.Oak.ConstantsData.Value.GimmickDefaultDamage:GetDecrypted()

	if delay > 0 then
		wait_for_sec(delay)
	end

	-- y = -10x^2 + 10
	-- y = 0 -> x = 1 (1초 후 도달)
	local calc_free_fall = CS.CalculatorFreeFall()
	calc_free_fall:SetParameters(0, 20, start_y - target_y, 0)
	calc_free_fall:ScaleTime(1.75)

	local move_time = 1 / 1.75	-- 1초간 이동인데 Calculator의 TimeScale이 1.75배
	local time_passed = 0
	local x_move_dist = 3

	local missile_effect = self.get_fx_darkmagic_missile()
			:Instantiate(target_pos + vector(x_move_dist, start_y, 0))

	while not calc_free_fall:IsDone() do
		coroutine.yield()

		calc_free_fall:Proceed(unity_class.time.deltaTime)

		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / move_time)

		missile_effect.transform.position = target_pos
				+ vector(x_move_dist * (1 - progress), calc_free_fall:GetDistance(), 0)
	end

	missile_effect:Dispose()
	music_player_util.play_sfx({ sfx_name = '02_explosion_01', type_priority = 'event', player_priority = 'npc' })
	self:dispose_bombing_range(attack_range)

	local explosion_effect = self.get_fx_darkmagic_missile_explosion():Instantiate(target_pos)
	explosion_effect.transform.localScale = unity_class.vector3.one * 1.5
	camera_util.shake(0.15, 0.15)

	local hits = field:GetFieldObjectsInCylinder(target_pos, self.bombing_radius, 3)

	for i = 0, hits.Count - 1 do
		local fo = hits.Values[i]
		if lua_helper.type_compare(fo, CS.Oak.Character) then
			local damage = false
			local non_mortal = false

			if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
				if lua_helper.reference_equals(fo, user_party.Leader) then
					damage = true
					non_mortal = true
				end
			elseif (fo.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then
				damage = true
			end

			if damage then
				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
				damage_info.target = fo
				damage_info.sender = self.get_wagon()
				damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * dmg_multiplier)
				damage_info.notMortal = non_mortal

				local cmd = CS.Oak.DamageCommand.Create(damage_info)
				command_util.publish_cmd(CS.Oak.Player.Local, cmd)
			end
		elseif lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.BarrelFieldObjectBehaviour) then
			-- 화약통 운반 미션에서 사용하는 화약통 일 때
			message_system:SendSync(fo.FieldObjectBehaviour,
					CS.Oak.BombProvokeEvent.Create(fo, CS.Oak.BombProvokeType.Fire))
		else
			-- Breakable등의 데미지를 입는 오브젝트일 때
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
			damage_info.target = fo
			damage_info.sender = user_party.Leader
			damage_info.damage = 10000

			local cmd = CS.Oak.DamageCommand.Create(damage_info)
			command_util.publish_cmd(CS.Oak.Player.Local, cmd)
		end
	end

	hits:Dispose()
end
--endregion

--region npc 연출

-- 연출용 NPC 세팅: 린치
function local_class:npcs_setting_2()
	-- NPC 동적할당
	self.optimized_npcs_2 = load_util.create_optimized_npcs_async({

		boss = 'future2_trio_boss',
		man = 'future2_trio_man',
		panda = 'future2_trio_panda',
		invader = 'future2_invader_warrior'
	})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.battle_template_panda, self,
				self.optimized_npcs_2['man'],
				self.optimized_npcs_2['boss'],
				self.optimized_npcs_2['panda'],
				self.optimized_npcs_2['invader'],
				vector(-105, 0, 0.5)
			))
end

function local_class:npcs_setting_3()
	-- NPC 동적할당
	self.optimized_npcs_iron = load_util.create_optimized_npcs_async({

		resistance_1 = 'future2_resistance_male',
		resistance_2 = 'future2_resistance_female',
		resistance_3 = 'future2_resistance_male',

		invader_1 = 'future2_invader_hulk',
		invader_2 = 'future2_invader_guard',
		invader_3 = 'future2_invader_warrior',
		invader_4 = 'future2_invader_priestess',
		invader_5 = 'future2_invader_archer',
		invader_6 = 'future2_invader_priestess',
		invader_7 = 'future2_invader_archer',
		invader_8 = 'future2_invader_hulk',
	})

	self.iron_resistance = create_generic_list(CS.Oak.Character)
	for i = 1, 3 do
		local cur
		cur = self.optimized_npcs_iron['resistance_'..i]
		self.iron_resistance:Add(cur)
	end

	self.iron_invader = create_generic_list(CS.Oak.Character)
	for i = 1, 8 do
		local cur
		cur = self.optimized_npcs_iron['invader_'..i]
		self.iron_invader:Add(cur)
	end

	local x = field:GetMarker('iron_teatan_pos').position.x - 4.5

	character_util.set_position(self.iron_invader[5], vector(x + 6, 0, 0.5))
	character_util.set_position(self.iron_invader[7], vector(x + 6, 0, -0.75))
	character_util.set_position(self.iron_invader[1], vector(x + 4.25, 0, -1.25))
	character_util.set_position(self.iron_invader[3], vector(x + 5.5, 0, -2.5))
	character_util.set_position(self.iron_invader[2], vector(x + 8, 0, 0))
	character_util.set_position(self.iron_invader[0], vector(x + 7, 0, -0.5))
	character_util.set_position(self.iron_invader[6], vector(x + 7.5, 0, -2.25))
	character_util.set_position(self.iron_invader[4], vector(x + 6.75, 0, -1.75))

	character_util.set_direction(self.iron_invader[0], 'right')
	character_util.set_direction(self.iron_invader[1], 'right')
	character_util.set_direction(self.iron_invader[2], 'right')
	character_util.set_direction(self.iron_invader[3], 'right')
	character_util.set_direction(self.iron_invader[4], 'right')
	character_util.set_direction(self.iron_invader[5], 'right')
	character_util.set_direction(self.iron_invader[6], 'right')
	character_util.set_direction(self.iron_invader[7], 'right')

	character_util.set_position(self.iron_resistance[0], vector(x - 3, 0, -2))
	character_util.set_position(self.iron_resistance[1], vector(x - 2, 0, -1))
	character_util.set_position(self.iron_resistance[2], vector(x - 2.25, 0, 0))

	character_util.set_direction(self.iron_resistance[0], 'right')
	character_util.set_direction(self.iron_resistance[1], 'right')
	character_util.set_direction(self.iron_resistance[2], 'right')

	for i = 0, 2 do
		character_util.set_anim(self.iron_resistance[i], { name = 'handgun_idle', upper = true})
		character_util.set_emotion(self.iron_resistance[i], { name = 'damaged' })
		character_util.shake(self.iron_resistance[i], 0.03, 9999)
		self.iron_resistance[i]:SetEquipment(CS.Oak.EquipmentSlot.Weapon1,
			CS.Oak.Item.Create(CS.Oak.ItemSpec.GetByName('tutorial_sword_normal')))
	end
end

function local_class:battle_template_panda(char_1, char_2, char_3, target, pos)
	character_util.set_position(char_1, pos + vector(-1, 0, 0))
	character_util.set_position(char_2, pos + vector(0, 0, 1))
	character_util.set_position(char_3, pos + vector(1, 0, 0))
	character_util.set_position(target, pos)

	character_util.set_direction(char_1, 'right')
	character_util.set_direction(char_2, 'down')
	character_util.set_direction(char_3, 'left')
	character_util.set_direction(target, 'right')

	character_util.set_emotion(char_1, { name = 'attack' })
	character_util.set_emotion(char_2, { name = 'attack' })
	character_util.set_emotion(char_3, { name = 'attack' })
	character_util.set_emotion(target, { name = 'confused' })

	character_util.set_anim(target, { name = 'prostrate' })

	char_2.SpineController:SetAttachment('[base]weapon1', 'frypan')
	char_1.SpineController:SetAttachment('[base]weapon1', 'mall_crowbar')
	char_3.SpineController:SetAttachment('[base]weapon1', 'mall_whisker')

	local timer = 0.3
	local delay = 0.3
	local index = 1
	local panda_table = {}
	table.insert(panda_table, char_1)
	table.insert(panda_table, char_2)
	table.insert(panda_table, char_3)

	local deviate_pos_list = {}
	table.insert(deviate_pos_list, vector(1, 0, 0))
	table.insert(deviate_pos_list, vector(0, 0, -1))
	table.insert(deviate_pos_list, vector(-1, 0, 0))

	while true do
		timer = timer + unity_class.time.deltaTime

		if timer > delay then
			timer = 0

			index = index + 1

			if index > 3 then
				index = 1
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.attack_routine, self, panda_table[index], target,
					deviate_pos_list[index]))
		end

		coroutine.yield(nil)
	end
end

-- 매드 팬더 용병단 공격 세부 연출
function local_class:attack_routine(attacker, victim, deviate_pos)
	character_util.spine_deviate_local(attacker, deviate_pos * 0.5, 0.3, 0.2)
	character_util.set_anim(attacker, { name = 'attack', loop = false })

	wait_for_sec(0.3)

	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(victim.Position + vector(0, 0.3, 0))

	character_util.spine_deviate_local(victim, deviate_pos * 0.3, 0.2, 0.1)
	character_util.spine_pulse_color(victim, CS.Oak.Constants.DamageColor, 1, 1, 1)
	character_util.spine_damage_squish(victim, 1.3, 0.7, 1, 0.3)

	character_util.remove_anim(attacker)

	wait_for_sec(0.2)
end

--endregion

--region 메인 로직
function local_class:custom_progress_section()
	self.current_main_state = self.current_main_state + 1
	--CS.UnityEngine.Debug.LogError('Custom Section Progressed To ' .. self.current_main_state)
end

-- 컨트롤 뺏은 상태로 진행해야 함!
function local_class:progress_main_section()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	self.current_main_state = self.main_state.done

	self.wait_progressing_section = true
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, {'section3_finished'}))
end
--endregion

--region 화물 호위 이벤트
function local_class:wagon_stucked_before_escort()
	local wagon = self.get_wagon()
	local wagon_resis =
	{
		get_character('princess'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}

	wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, self.sticking_target_z_rot)
	wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, -0.4, wagon.Transform.localPosition.z)

	for i = 2, 4 do
		character_util.set_direction(wagon_resis[i], 'right')
		character_util.set_emotion(wagon_resis[i], { name = 'damaged'})
		character_util.set_anim(wagon_resis[i], { name = 'push', loop = true})
		character_util.shake(wagon_resis[i], 0.02, 9999)
	end
	self.stucked = true

	while self.stucked do
		local duration = 0.3
		local cur_time = 0
		local vtr = wagon.Transform.localPosition
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon.Position + vector(0, 0, 1.75)
				+ vector(-0.2, 0, -0.2))
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[3].Position + vector(-0.2, 0, -0.2))
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[2].Position + vector(0.2, 0, -0.2),
				unity_class.quaternion.Euler(0,180,0), nil)
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[4].Position + vector(0.2, 0, -0.2),
				unity_class.quaternion.Euler(0,180,0), nil)

		music_player_util.play_sfx({sfx_name = '01_push_wagon_01', parent = wagon,
									type_priority = 'event', player_priority = 'npc'})
		while cur_time < duration do
			local rand_x = math.floor(unity_class.random.Range(1, 50))
			local rand_z = math.floor(unity_class.random.Range(1, 50))

			wagon.Transform.localPosition = vtr + vector(rand_x/1000, 0, rand_z/1000)

			if self.stucked == false then
				wagon.Transform.localPosition = vtr
				break
			end

			cur_time = cur_time + unity_class.time.deltaTime
			coroutine.yield()
		end
		wagon.Transform.localPosition = vtr
		duration = 1.2
		cur_time = 0
		while cur_time < duration do
			if self.stucked == false then
				break
			end

			cur_time = cur_time + unity_class.time.deltaTime
			coroutine.yield()
		end
	end
	local princess = self.get_princess()
	local target_pos_1 = wagon.Position + vector(-1, 0, 1.75)
	local move_diff = target_pos_1 - princess.Position
	local move_diff_prime = vector(move_diff.x, 0, move_diff.z * 2)
	local x_speed = 3
	local wait_1 = true
	local wait_2 = true
	local move_2_activated = false
	character_util.convert_to_npc(princess)
	princess.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	if float_util.is_almost_zero(move_diff_prime.magnitude) == false then
		wp_util.move_way_points(princess,
				{waypoints = target_pos_1, speed = move_diff.magnitude / move_diff_prime.magnitude * x_speed,
				 callback = function()
					wait_1 = false
				 end})
	else
		wait_1 = false
	end

	local sticking_time_passed = 0
	while sticking_time_passed < self.sticking_duration * 2 do
		local progress = unity_class.mathf.Clamp01(sticking_time_passed / (self.sticking_duration * 2))
		local z_rot = progress * self.sticking_target_z_rot
		wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0,  self.sticking_target_z_rot - z_rot)
		local y_pos = progress * 0.4
		wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, y_pos - 0.4, wagon.Transform.localPosition.z)

		sticking_time_passed = sticking_time_passed + unity_class.time.deltaTime

		if wait_1 == false and move_2_activated == false then
			move_2_activated = true
			wp_util.move_way_points(princess,
					{waypoints = wagon.Position + vector(0, 0, 1.75), speed = x_speed, callback = function()
						wait_2 = false
						character_util.set_direction(princess, 'right')
						princess:SetUpperAnimation('push', true)
						character_util.set_emotion(princess, { name = 'attack'})
					end})
		end

		coroutine.yield()
	end

	wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
	wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, 0, wagon.Transform.localPosition.z)

	if wait_2 then
		for i = 2, 4 do
			character_util.set_direction(wagon_resis[i], 'right')
			wagon_resis[i]:SetUpperAnimation('push', true)
			character_util.set_emotion(wagon_resis[i], { name = 'attack'})
			character_util.stop_shake(wagon_resis[i])
		end

		while wait_2 do
			if wait_1 == false and move_2_activated == false then
				move_2_activated = true
				wp_util.move_way_points(princess,
						{waypoints = wagon.Position + vector(0, 0, 1.75), speed = x_speed, callback = function()
							wait_2 = false
							character_util.set_direction(princess, 'right')
							princess:SetUpperAnimation('push', true)
							character_util.set_emotion(princess, { name = 'attack'})
						end})
			end
			coroutine.yield()
		end
	end

	self:set_wagon()
	self:start_escort()

	self:cannon_ball_routine()
end

function local_class:set_wagon()
	local wagon = self.get_wagon()

	wagon.Position = self.get_wagon_start_pos()
	wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
	wagon.ActiveState = active_state('enabled')

	local wagon_resis =
	{
		get_character('princess'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}

	character_util.set_position(wagon_resis[1], wagon.Position + vector(0, 0, 1.75))
	character_util.set_position(wagon_resis[2], wagon.Position + vector(1.95, 0, 1.75))
	character_util.set_position(wagon_resis[3], wagon.Position + vector(0, 0, -0.5))
	character_util.set_position(wagon_resis[4], wagon.Position + vector(1.95, 0, -0.5))

	for i = 1, 4 do
		character_util.set_direction(wagon_resis[i], 'right')
		character_util.set_emotion(wagon_resis[i], { name = 'attack' })
		wagon_resis[i]:SetUpperAnimation('push', true)
		character_util.set_anim(wagon_resis[i], { name = 'walk', loop = true})
	end

	self.wagon_info.current_hp = self.wagon_info.max_hp
	self.current_wagon_state = self.wagon_state.idle
end

function local_class:start_escort()
	self.current_escort_state = self.escort_state.escorting
	self.current_wagon_state = self.wagon_state.move
	self.stuck_next_index = 1
	self.battle_next_index = 1

	self.get_wagon_interact().Position = vector(999, 0, 999)

	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)
	local ui_dic = field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBarForBoss)
	self.top_hp_bar = ui_dic[CS.Oak.FieldUiType.TopHpBarForBoss]
	self.top_hp_bar.MaxHP = self.wagon_info.max_hp
	self.top_hp_bar.HP = self.wagon_info.current_hp
	self.top_hp_bar.Diff = self.wagon_info.max_hp
	self.top_hp_bar:SetName(game_string:GetString(self.wagon_info.name_key))

	for i = 1, #self.turret_infos do
		local info = self.turret_infos[i]
		info.state = self.turret_state.idle
		info.time_passed = 0

		local turret = self.get_turret(i)
		turret.ActiveState = active_state('enabled')
		character_util.convert_to_monster(turret, self.wagon_battle_group_name, self.wagon_battle_zone_name)
	end

	local battle = stage.BattleManager:GetBattleFor(user_party.Leader)
	if battle == nil then
		battle = stage.BattleManager:CreateBattleInstance()
		battle:AddAlly(user_party.Leader)
	end
	battle:AddAlly(self.get_wagon())

	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_wagon_damage_event')
	local dummy_monster = get_character('wagon_monster_dummy')
	character_util.convert_to_monster(dummy_monster, self.wagon_battle_group_name, self.wagon_battle_zone_name)
	dummy_monster.FieldObjectController.DontFight = true
	dummy_monster.ActiveState = active_state('enabled')
	battle:AddEnemy(dummy_monster)

	message_system:Publish(CS.Oak.BattleStartEvent.Create(battle))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.escort_routine, self))
end

function local_class:wagon_crash()

	local sticking_time_passed = 0
	local wagon = self.get_wagon()

	self:add_item_marker_to_point(wagon.Bounds.center + vector(-1, 0.5, 0))

	local wagon_resis =
	{
		get_character('s3_wagon_resistance_1'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}

	for i = 1, 4 do
		if i%2 == 1 then
			character_util.set_direction(wagon_resis[i], 'right')
		else
			character_util.set_direction(wagon_resis[i], 'left')
		end
		wagon_resis[i]:RemoveUpperAnimation()
		character_util.set_emotion(wagon_resis[i], { name = 'surprise'})
		character_util.set_anim(wagon_resis[i], { name = 'embarrassed', loop = true})
	end

	camera_util.shake(0.2, 0.3)
	unity_object_pool.GetOrCreate('FX_minotaur_buttbounce')
					 :Instantiate(wagon.Transform.localPosition + vector(1, 0, 0.5))
	music_player_util.play_sfx({sfx_name = '02_break_wood_01', parent = wagon,
								type_priority = 'event', player_priority = 'npc'})
	music_player_util.play_sfx({sfx_name = '02_break_wagon_01', parent = wagon,
								type_priority = 'event', player_priority = 'npc'})

	while sticking_time_passed < self.sticking_duration and self.current_wagon_state ~= self.wagon_state.destroyed do
		local progress = unity_class.mathf.Clamp01(sticking_time_passed / self.sticking_duration)
		local z_rot = progress * self.sticking_target_z_rot
		wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, -z_rot)

		sticking_time_passed = sticking_time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	sticking_time_passed = 0
	while sticking_time_passed < self.sticking_duration and self.current_wagon_state ~= self.wagon_state.destroyed do
		local progress = unity_class.mathf.Clamp01(sticking_time_passed / self.sticking_duration)
		local z_rot = progress * self.sticking_target_z_rot
		wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, (z_rot * 2) - self.sticking_target_z_rot)
		local y_pos = progress * (-0.4)
		wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, y_pos, wagon.Transform.localPosition.z)

		sticking_time_passed = sticking_time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	if self.current_wagon_state == self.wagon_state.destroyed then
		return
	end

	sticking_time_passed = 0
	wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, self.sticking_target_z_rot)
	wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, -0.4, wagon.Transform.localPosition.z)

	local wagon_inv = self.get_wagon_interact()
	wagon_inv.Position = wagon.Position + vector(0, 0, 0.5)

	wait_for_sec(1)

	if self.current_wagon_state == self.wagon_state.destroyed then
		return
	end

	for i = 1, 4 do
		character_util.set_direction(wagon_resis[i], 'right')
		character_util.set_emotion(wagon_resis[i], { name = 'damaged'})
		character_util.set_anim(wagon_resis[i], { name = 'push', loop = true})
		character_util.shake(wagon_resis[i], 0.02, 9999)
	end
	self.stucked = true
	wait_for_sec(0.5)

	while self.stucked and self.current_wagon_state ~= self.wagon_state.destroyed do
		local duration = 0.3
		local cur_time = 0
		local vtr = wagon.Transform.localPosition
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[1].Position + vector(-0.2, 0, -0.2))
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[3].Position + vector(-0.2, 0, -0.2))
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[2].Position + vector(0.2, 0, -0.2),
				unity_class.quaternion.Euler(0,180,0), nil)
		unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[4].Position + vector(0.2, 0, -0.2),
				unity_class.quaternion.Euler(0,180,0), nil)
		music_player_util.play_sfx({sfx_name = '01_push_wagon_01', parent = wagon,
									type_priority = 'event', player_priority = 'npc'})
		while cur_time < duration do
			local rand_x = math.floor(unity_class.random.Range(1, 50))
			local rand_z = math.floor(unity_class.random.Range(1, 50))

			wagon.Transform.localPosition = vtr + vector(rand_x/1000, 0, rand_z/1000)

			if self.stucked == false then
				wagon.Transform.localPosition = vtr
				break
			end

			cur_time = cur_time + unity_class.time.deltaTime
			coroutine.yield()
		end
		wagon.Transform.localPosition = vtr
		duration = 1.2
		cur_time = 0
		while cur_time < duration do
			if self.stucked == false then
				break
			end

			cur_time = cur_time + unity_class.time.deltaTime
			coroutine.yield()
		end
	end
end

function local_class:dispose_escort()
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_wagon_damage_event')
	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBarForBoss)
end

function local_class:escort_routine()
	local wagon = self.get_wagon()
	local wagon_bound_x_offset = 2.5
	local wagon_check_x_offset = 1
	local wagon_target_x_pos = self.get_wagon_target_x_pos()
	local move_fx_cooltime = 0.5
	local move_fx_time_passed = 0
	local rock_talked = false
	local rock_talk_x_pos = 76
	local wagon_resis =
	{
		get_character('princess'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}
	local kb_ban_list = {
		user_party.Leader,
		get_character('princess'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}
	local resistance_offsets = {}
	for i = 1, #wagon_resis do
		resistance_offsets[i] = wagon_resis[i].Position - wagon.Position
	end

	local wagon_monsters = {}
	for battle_num, info in pairs(self.wagon_battle_infos) do
		local monsters = {}
		for i = 1, info.monster_count do
			table.insert(monsters, self.get_wagon_monster(battle_num, i))
		end
		wagon_monsters[battle_num] = monsters
	end

	local wagon_animator = wagon.transform:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

	local turrets = {}
	for i = 1, self.turret_data.count do
		table.insert(turrets, self.get_turret(i))
		table.insert(kb_ban_list, self.get_turret(i))
	end

	local stuck_x_pos_list = {}
	for i = 1, self.stuck_pos_count do
		table.insert(stuck_x_pos_list, self.get_stuck_x_pos(i))
	end

	local battle_x_pos_list = {}
	for i = 1, #self.wagon_battle_infos do
		table.insert(battle_x_pos_list, self.get_battle_active_x_pos(i))
	end

	local move_started = false

	while true do
		if self.current_wagon_state == self.wagon_state.destroyed then
			self:stop_sfx_wagon_loop()
			break
		elseif wagon.Position.x >= wagon_target_x_pos then
			if self.current_wagon_state ~= self.wagon_state.idle then
				self.current_wagon_state = self.wagon_state.idle
				for i = 1, 4 do
					character_util.remove_anim(wagon_resis[i])
					wagon_resis[i]:SetUpperAnimation('push', true)
					character_util.set_emotion(wagon_resis[i], { name = 'attack'})
					character_util.stop_shake(wagon_resis[i])
				end
				self:stop_sfx_wagon_loop()

				-- 이제 도착이다!
				speech_bubble_util.show_speech_bubble_async(wagon_resis[3], { key = "futurecastle_part2_s3_2", skip = false })

			end

			local reached = true
			for battle_num, info in pairs(self.wagon_battle_infos) do
				for i = 1, info.monster_count do
					if wagon_monsters[battle_num][i].ActiveState ~= CS.Oak.ActiveState.Disabled then
						reached = false
						break
					end
				end
			end
			for i = 1, self.turret_data.count do
				if turrets[i].gameObject.activeSelf ~= false then
					reached = false
					break
				end
			end

			if reached == true then
				self.current_wagon_state = self.wagon_state.reached
				self.current_escort_state = self.escort_state.after_escort
				break
			end
		end

		if self.current_wagon_state == self.wagon_state.move then
			if move_started == false then
				for i = 1, 4 do
					character_util.set_direction(wagon_resis[i], 'right')
					wagon_resis[i]:SetUpperAnimation('push', true)
					character_util.set_emotion(wagon_resis[i], { name = 'attack'})
					character_util.set_anim(wagon_resis[i], { name = 'walk', loop = true})
					character_util.stop_shake(wagon_resis[i])
				end
				wagon_animator:Play('wagon_roll_R')
				move_started = true

				self:start_sfx_wagon_loop()
			end

			if move_fx_time_passed >= move_fx_cooltime then
				unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[1].Position + vector(-0.2, 0, -0.2))
				unity_object_pool.GetOrCreate('FX_Dash_Smoke'):Instantiate(wagon_resis[3].Position + vector(-0.2, 0, -0.2))
				move_fx_time_passed = 0
			else
				move_fx_time_passed = move_fx_time_passed + unity_class.time.deltaTime
			end

			local target_x_dif = self.wagon_info.move_speed * unity_class.time.deltaTime
			local closest_obj_x_pos = self:get_closest_obj_x_pos(
					wagon.Position + vector(wagon_bound_x_offset, 0, 0.5), turrets)
			local closest_stuck_x_pos = self.stuck_next_index <= self.stuck_pos_count
					and stuck_x_pos_list[self.stuck_next_index] or 999
			local target_x_pos = wagon.Position.x + target_x_dif + wagon_bound_x_offset
			local closest_battle_x_pos = self.battle_next_index <= #self.wagon_battle_infos
					and battle_x_pos_list[self.battle_next_index] or 999

			if closest_obj_x_pos < target_x_pos + wagon_check_x_offset then

				if wagon.Position.x + wagon_bound_x_offset + wagon_check_x_offset < closest_obj_x_pos then
					target_x_pos = closest_obj_x_pos - wagon_bound_x_offset - wagon_check_x_offset
					self:try_wagon_knockback(vector(target_x_pos - wagon.Position.x, 0, 0), kb_ban_list)
					wagon.Position = vector_util.get_0yz(wagon.Position, target_x_pos)
				end

				move_started = false
				self:stop_sfx_wagon_loop()
				self.current_wagon_state = self.wagon_state.blocked

			elseif closest_stuck_x_pos < target_x_pos then
				move_started = false
				self:stop_sfx_wagon_loop()
				self.current_wagon_state = self.wagon_state.sticking
			else
				if closest_battle_x_pos < target_x_pos then
					coroutine_manager:StartCoroutine(stage.StageGameObject,
							util.cs_generator(self.active_wagon_battle, self, self.battle_next_index))
					self.battle_next_index = self.battle_next_index + 1
				end
				self:try_wagon_knockback(vector(target_x_dif, 0, 0), kb_ban_list)
				wagon.Position = wagon.Position + vector(target_x_dif, 0, 0)
			end

			for i = 1, 4 do
				character_util.set_position(wagon_resis[i], resistance_offsets[i] + wagon.Position)
			end

			if rock_talked == false and rock_talk_x_pos < wagon.Position.x + wagon_bound_x_offset then
				rock_talked = true
				for i = 1, #self.rocks do
					if self.rocks[i].gameObject.activeSelf then
						speech_bubble_util.show_speech_bubble(wagon_resis[1], {key = 'futurecastle_part2_s3_1_1'})
						break
					end
				end
			end

		elseif self.current_wagon_state == self.wagon_state.blocked then
			for i = 1, 4 do
				character_util.set_anim(wagon_resis[i], { name = 'idle', loop = true})
			end
			wagon_animator:Play('wagon_idle')
			local closest_obj_x_pos = self:get_closest_obj_x_pos(
					wagon.Position + vector(wagon_bound_x_offset, 0, 0.5), turrets)
			if closest_obj_x_pos - (wagon.Position.x + wagon_bound_x_offset)
					> wagon_check_x_offset then	-- 공간이 좀 생기면
				self.current_wagon_state = self.wagon_state.move
			end

		elseif self.current_wagon_state == self.wagon_state.sticking then
			self.current_wagon_state = self.wagon_state.stuck_in_mud
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wagon_crash, self))
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.active_wagon_bombing, self))
			wagon_animator:Play('wagon_idle')

		--elseif self.current_wagon_state == self.wagon_state.stuck_in_mud then

		end

		for i = 1, self.turret_data.count do
			local info = self.turret_infos[i]

			-- AirSpin하면서 쏘는 경우 방지
			if turrets[i].FieldObjectStatsBehaviour.IsDead then
				info.state = self.turret_state.dead
			end

			local dist_to_wagon = vector_util.get_x0z(wagon.Bounds.center - turrets[i].Position).magnitude
			if info.state == self.turret_state.idle then
				if dist_to_wagon <= self.turret_data.range then
					info.state = self.turret_state.targeting
					-- 첫 공격은 빠르게 진행
					info.time_passed = self.turret_data.attack_delay - 1
				end

			elseif info.state == self.turret_state.targeting then
				if dist_to_wagon > self.turret_data.range then
					info.state = self.turret_state.idle
				elseif info.time_passed < self.turret_data.attack_delay then
					info.time_passed = info.time_passed + unity_class.time.deltaTime
				else
					info.time_passed = 0
					info.state = self.turret_state.attacking
				end

			elseif info.state == self.turret_state.attacking then
				if dist_to_wagon <= self.turret_data.range then
					music_player_util.play_sfx({sfx_name = '02_bomb_arrow_shoot_01', parent = turrets[i],
												type_priority = 'event', player_priority = 'npc'})
					character_util.set_anim(turrets[i], {name = 'attack', loop = false, next_anim = 'idle'})
					self.get_fx_common_cannonfire():Instantiate(turrets[i].Position + self.turret_data.shoot_offset,
							unity_class.quaternion.Euler(0, -150, 0), turrets[i].Transform)
					self:insert_cannon_queue(turrets[i].Position + self.turret_data.shoot_offset, wagon.Bounds.center)
					info.state = self.turret_state.targeting
				else
					info.state = self.turret_state.idle
				end
			end
		end

		coroutine.yield()
	end

	wagon_animator:Play('wagon_idle')
	self:dispose_escort()

	-- 운반 성공
	if self.current_wagon_state == self.wagon_state.reached then
		local wagon_resis =
		{
			get_character('princess'),
			get_character('s3_wagon_resistance_2'),
			get_character('s3_wagon_resistance_3'),
			get_character('s3_wagon_resistance_4')
		}

		for i = 1, 4 do
			character_util.remove_anim(wagon_resis[i])
		end

		character_util.convert_to_npc(get_character('wagon_monster_dummy'))
		local battle = stage.BattleManager:GetBattleFor(user_party.Leader)
		if battle == nil then
			battle:DeactivateAlly(wagon)
		end
		wagon_animator:Play('wagon_idle')
		stage.BattleManager:ForceEndBattles()

		field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)

		for _, item_dropper_data in pairs(self.item_info.dropper_data) do
			local dropper = self.item_dropper_cache[item_dropper_data.num]
			message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(dropper, true))
		end
		for i = 1, 7 do
			message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('extra_box_' .. i), true))
		end
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('coin_box'), true))
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('star_piece_drop_box'), true))
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(get_field_object('arcade_machine'), true))

		-- 운반 성공 & 마티 납치 이벤트
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.escort_ending, self))

	elseif self.current_wagon_state == self.wagon_state.destroyed then
		-- 운반 실패
		sp_util.play_normal_screenplay(self.escort_failed, self)
	end
end

function local_class:start_sfx_wagon_loop()
	local wagon = self.get_wagon()
	self:stop_sfx_wagon_loop()
	self.sfx_wagon_move = music_player_util.play_sfx({sfx_name = '01_wagon_loop_01', parent = wagon, loop = true,
													  type_priority = 'event', player_priority = 'npc'})
end

function local_class:stop_sfx_wagon_loop()
	if self.sfx_wagon_move ~= nil then
		self.sfx_wagon_move:Stop()
		self.sfx_wagon_move = nil
	end
end

function local_class:damage_wagon(damage, direction)
	local wagon = self.get_wagon()
	CS.DamageNumber.ShowDamageNumber(wagon, damage, unity_class.color.red, wagon.Bounds.center)

	self.wagon_info.current_hp = self.wagon_info.current_hp - damage
	if is_unity_null(self.top_hp_bar) == false then
		self.top_hp_bar.HP = self.wagon_info.current_hp
		self.top_hp_bar.Diff = self.wagon_info.current_hp + damage
	end

	if self.wagon_info.current_hp <= 0 then
		self:wagon_die()
	else
		--wagon:Shake(0.02, 0.3)
		--wagon:Deviate(direction.normalized * 0.1, 0.2, 0.1)
	end
end

function local_class:wagon_die()
	message_system:SendSync(self.get_wagon_interact(),
			CS.Oak.InteractCancelEvent.Create(user_party.Leader, self.get_wagon_interact()))
	self.get_wagon_interact().Position = vector(999, 0, 999)
	self.current_wagon_state = self.wagon_state.destroyed
end

-- blockers 추가
-- 매번 터렛들 가져오는 게 좋지 않아서 테이블로 넘겨받음
function local_class:get_closest_obj_x_pos(check_pos, blockers)
	local bounds = CS.UnityEngine.Bounds(check_pos + vector(0.5, 0, 0), vector(1, 1, 2))
	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(bounds, vector(1, 0, 0))
	local min_x = 999

	for i = 0, obj_list.Count - 1 do
		local fo = obj_list[i]

		if min_x > fo.Position.x
				and (not lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.CharacterBehaviour)
				or table_util.contain_value(blockers, fo)) then
			min_x = fo.Position.x
		end
	end

	obj_list:Dispose()

	return min_x
end

function local_class:wagon_pull_success()
	local sticking_time_passed = 0
	local wagon = self.get_wagon()

	self.stucked = false
	self:remove_item_marker()

	music_player_util.play_sfx({sfx_name = '02_gimmick_door_down_02', parent = wagon,
								type_priority = 'event', player_priority = 'npc'})
	while sticking_time_passed < self.sticking_duration * 2 and self.current_wagon_state ~= self.wagon_state.destroyed do
		local progress = unity_class.mathf.Clamp01(sticking_time_passed / (self.sticking_duration * 2))
		local z_rot = progress * self.sticking_target_z_rot
		wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0,  self.sticking_target_z_rot - z_rot)
		local y_pos = progress * 0.4
		wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, y_pos - 0.4, wagon.Transform.localPosition.z)

		sticking_time_passed = sticking_time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	if self.current_wagon_state == self.wagon_state.destroyed then
		return
	end

	sticking_time_passed = 0
	wagon.Transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
	wagon.Transform.localPosition = vector(wagon.Transform.localPosition.x, 0, wagon.Transform.localPosition.z)

	wait_for_sec(0.2)

	if self.current_wagon_state == self.wagon_state.destroyed then
		return
	end

	self.stuck_next_index = self.stuck_next_index + 1
	self.current_wagon_state = self.wagon_state.move
end

function local_class:active_wagon_battle(battle_num)
	local battle = stage.BattleManager:GetBattleFor(user_party.Leader)
	if battle == nil then
		battle = stage.BattleManager:CreateBattleInstance()
		battle:AddAlly(user_party.Leader)
	end

	battle:AddAlly(self.get_wagon())

	for i = 1, self.wagon_battle_infos[battle_num].monster_count do
		if self.current_wagon_state == self.wagon_state.destroyed then
			return
		end

		local monster = self.get_wagon_monster(battle_num, i)
		local target_pos = self.get_wagon_monster_respawn_pos(battle_num, i)

		battle:AddEnemy(monster)
		character_util.convert_to_monster(monster, self.wagon_battle_group_name, self.wagon_battle_zone_name)

		music_player_util.play_sfx({ sfx_name = '01_invader_beam_01', type_priority = 'gimmick', player_priority = 'npc' })
		self.get_fx_event_invader_beam():Instantiate(target_pos)
		monster.Position = target_pos
		monster.ActiveState = active_state('enabled')

		command_util.execute_monster_notice(monster, self.get_wagon(), 'battle')

		wait_for_sec(0.2)
	end
end

function local_class:active_wagon_bombing()
	local wagon = self.get_wagon()
	local start_y = 10
	local target_y = 0
	local dmg_multiplier = CS.Oak.ConstantsData.Value.GimmickDefaultDamage:GetDecrypted()
	local bombing_count = 4
	local move_time = 1 / 1.75
	local x_move_dist = 3
	local bombing_state = {
		none = 0,
		delayed = 1,
		activated = 2,
		fall = 3,
		done = 99
	}
	local fall_delay = 15
	local infos = {}
	local done_count = 0
	local time_range = 1
	local attack_range_max_x = -999
	local target_pos_offset = vector_util.get_x0z(wagon.Bounds.center)
	local target_pos_list = {
		vector(-1.5, 0, -1.5),
		vector(1.3, 0, 1.2),
		vector(1, 0, -1),
		vector(-1.8, 0, 0.9),
	}

	local dummy = get_character('sohee_emoticon')
	dummy.Interactable.Talk = ''
	dummy.CrashBehaviour = CS.Oak.NullCrashBehaviour.Instance
	character_util.spine_set_alpha_fade(dummy, 0, 0)
	local ui_dic = field_ui_manager:SetUI(dummy, CS.Oak.FieldUiType.CharacterStats)
	local lv_ui = ui_dic[CS.Oak.FieldUiType.CharacterStats]
	lv_ui.gameObject:SetActive(true)
	lv_ui.Level.gameObject:SetActive(false)
	dummy.Position = target_pos_offset + vector(-0.3, 2, 0)

	for i = 1, bombing_count do
		infos[i] = {
			state = bombing_state.delayed,
			start_delay = time_range / bombing_count * (i - 1),
			calc = CS.CalculatorFreeFall(),
			attack_range = nil,
			target_pos = target_pos_offset + target_pos_list[i],
			time_passed = 0,
			effect = nil,
		}

		if attack_range_max_x < infos[i].target_pos.x + self.bombing_radius then
			attack_range_max_x = infos[i].target_pos.x + self.bombing_radius
		end
	end

	local all_fall = false
	local attack_queue_activated = false
	local already_falling = false

	self.wagon_bombing_active = true
	while done_count < bombing_count and self.wagon_bombing_active do
		if all_fall == false and attack_range_max_x < wagon.Bounds.min.x  then
			all_fall = true

			if already_falling == false then
				local min_time_left = fall_delay - infos[1].time_passed	-- 순서대로 넣었음

				for i = 1, bombing_count do
					infos[i].time_passed = infos[i].time_passed + min_time_left
				end

				already_falling = true
			end

			character_util.hide_attack_timer(dummy)
		end

		for i = 1, bombing_count do
			local info = infos[i]

			if info.state == bombing_state.delayed and info.time_passed >= info.start_delay then
				info.state = bombing_state.activated
				info.attack_range = self:get_bombing_range()
				info.attack_range.transform.position = info.target_pos
				info.time_passed = 0
				music_player_util.play_sfx({sfx_name = '02_wolf_boss_fire_01', play_pos = info.target_pos,
											type_priority = 'event', player_priority = 'npc'})
				music_player_util.play_sfx({sfx_name = '01_siren_oneshot_01', play_pos = info.target_pos,
											type_priority = 'event', player_priority = 'npc'})

				if attack_queue_activated == false then
					attack_queue_activated = true
					character_util.show_attack_timer(dummy, fall_delay)
				end

			elseif info.state == bombing_state.activated and info.time_passed >= fall_delay then
					info.state = bombing_state.fall
					already_falling = true
					info.calc:SetParameters(0, 20, start_y - target_y, 0)
					info.calc:ScaleTime(1.75)
					info.effect = self.get_fx_darkmagic_missile():Instantiate(info.target_pos + vector(x_move_dist, start_y, 0))

					info.time_passed = 0

			elseif info.state == bombing_state.fall then
				if not info.calc:IsDone() then
					info.calc:Proceed(unity_class.time.deltaTime)

					local progress = unity_class.mathf.Clamp01(info.time_passed / move_time)

					info.effect.transform.position = info.target_pos
							+ vector(x_move_dist * (1 - progress), info.calc:GetDistance(), 0)
				else
					info.state = bombing_state.done
					done_count = done_count + 1
					info.effect:Dispose()
					info.effect = nil
					local explosion_effect = self.get_fx_darkmagic_missile_explosion():Instantiate(info.target_pos)
					explosion_effect.transform.localScale = unity_class.vector3.one * 1.5
					music_player_util.play_sfx({sfx_name = '02_explosion_01', play_pos = info.target_pos,
												type_priority = 'event', player_priority = 'npc'})
					camera_util.shake(0.15, 0.15)
					self:dispose_bombing_range(info.attack_range)

					local hits = field:GetFieldObjectsInCylinder(info.target_pos, self.bombing_radius, 3)

					for i = 0, hits.Count - 1 do
						local fo = hits.Values[i]
						if lua_helper.type_compare(fo, CS.Oak.Character) then
							local damage = false
							local non_mortal = false

							if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
								if lua_helper.reference_equals(fo, user_party.Leader) then
									damage = true
									non_mortal = true
								end
							elseif (fo.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then
								damage = true
							end

							if damage then
								local damage_info = CS.Oak.DamageInfo()
								damage_info.type = CS.Oak.DamageType.Explosion
										| CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
								damage_info.target = fo
								damage_info.sender = wagon
								damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * dmg_multiplier)
								damage_info.notMortal = non_mortal

								local cmd = CS.Oak.DamageCommand.Create(damage_info)
								command_util.publish_cmd(CS.Oak.Player.Local, cmd)
							end
						elseif lua_helper.reference_equals(fo, wagon) then
							self:damage_wagon(self.wagon_bombing_damage,
									(wagon.Bounds.center - info.target_pos).normalized)
						end
					end

					hits:Dispose()
				end
			end

			info.time_passed = info.time_passed + unity_class.time.deltaTime
		end

		coroutine.yield()
	end

	character_util.hide_attack_timer(dummy)
	dummy.Position = vector(999, 0, 999)

	for i = 1, bombing_count do
		local info = infos[i]
		self:dispose_bombing_range(info.attack_range)
		if is_unity_null(info.effect) == false then
			info.effect:Dispose()
		end
	end
end

function local_class:insert_cannon_queue(start_pos, target_pos)
	local cannon_ball = self.get_fx_cannon_ball():Instantiate(start_pos)
	local cannon_ball_contrail = self.get_fx_cannon_ball_contrail():Instantiate(start_pos)
	local move_dist = (target_pos - start_pos).magnitude
	table.insert(self.cannon_ball_infos, {
		object = cannon_ball,
		trail_object = cannon_ball_contrail,
		time_passed = 0,
		start_pos = start_pos,
		target_pos = target_pos,
		move_dur = move_dist / self.cannon_ball_data.move_speed,
		height = move_dist * self.cannon_ball_data.height_ratio
	})
end

function local_class:dispose_cannon_ball(index)
	local info = self.cannon_ball_infos[index]

	if info.object ~= nil then
		info.object:Dispose()
	end

	if info.trail_object ~= nil then
		info.trail_object:Dispose()
	end

	table.remove(self.cannon_ball_infos, index)
end

function local_class:cannon_ball_routine()
	local wagon = self.get_wagon()
	while self.current_escort_state ~= self.escort_state.after_escort or #self.cannon_ball_infos > 0 do
		local done_list = {}
		for i = 1, #self.cannon_ball_infos do
			local info = self.cannon_ball_infos[i]
			if info.time_passed < info.move_dur
					and not wagon.Bounds:Contains(vector_util.get_x0z(info.object.transform.position, wagon.Bounds.center.y)) then
				local progress = unity_class.mathf.Clamp01(info.time_passed / info.move_dur)
				info.object.transform.position = info.start_pos * (1 - progress) + info.target_pos * progress
						+ vector(0, math.sin(progress * math.pi) * info.height, 0)
				info.trail_object.transform.position = info.object.transform.position
				info.time_passed = info.time_passed + unity_class.time.deltaTime
			else
				music_player_util.play_sfx(
						{sfx_name = '02_wolf_boss_bomb_01', play_pos = info.object.transform.position,
						 type_priority = 'event', player_priority = 'npc'})
				self.get_fx_small_explosion():Instantiate(info.object.transform.position)
				camera_util.shake(0.2, 0.2)
				if self.current_wagon_state ~= self.wagon_state.reached then
					self:damage_wagon(self.turret_data.damage, vector(0, 0, 0))
				end

				table.insert(done_list, i - #done_list)
			end
		end

		for i = 1, #done_list do
			self:dispose_cannon_ball(done_list[i])
		end

		coroutine.yield()
	end
end

function local_class:escort_failed()
	local wagon_resis = {
		get_character('princess'),
		get_character('s3_wagon_resistance_2'),
		get_character('s3_wagon_resistance_3'),
		get_character('s3_wagon_resistance_4')
	}

	self.stucked = false
	self:remove_item_marker()

	speech_bubble_util.remove_bubble(wagon_resis[1])

	for i = 1, #self.wagon_barrel_offsets do
		local wagon_barrel = self.get_wagon_barrel(i)
		wagon_barrel.ActiveState = active_state('disabled')
	end
	unity_object_pool.GetOrCreate('FX_Explosion_Bomb_small'):Instantiate(self.get_wagon().Transform.localPosition + vector(1, 0, 0.5))

	for i = 1, 4 do
		wagon_resis[i]:RemoveUpperAnimation()
		character_util.normal_jump(wagon_resis[i], true)
		character_util.set_anim(wagon_resis[i], { name = 'embarrassed', loop = true})
		character_util.set_emotion(wagon_resis[i], { name = 'scared'})
	end
	character_util.normal_jump(user_party.Leader, true)
	character_util.set_anim(user_party.Leader, { name = 'embarrassed', loop = true})
	character_util.set_emotion(user_party.Leader, { name = 'scared'})

	wait_for_sec(1)

	camera_util.move_async(self.get_wagon().Position, 1)

	wait_for_sec(0.5)

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	self.wagon_bombing_active = false

	for battle_num, battle_info in pairs(self.wagon_battle_infos) do
		for i = 1, battle_info.monster_count do
			local monster = self.get_wagon_monster(battle_num, i)
			character_util.convert_to_npc(monster)
			character_util.set_active_state(monster, 'disabled')

			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = monster
			heal_info.target = monster
			heal_info.target = monster
			heal_info.heal = monster.FieldObjectStatsBehaviour.MaxHP
			heal_info.isRevive = true

			command_util.execute_heal(heal_info)
		end
	end

	for i = 1, self.turret_data.count do
		local turret = self.get_turret(i)

		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = turret
		heal_info.target = turret
		heal_info.heal = turret.FieldObjectStatsBehaviour.MaxHP
		heal_info.isRevive = true

		command_util.execute_heal(heal_info)

		turret.Position = self.turret_infos[i].origin_pos
		turret.Direction = CS.Oak.Direction.Left
		character_util.remove_anim(turret)
	end

	for i = 1, #self.wagon_barrel_offsets do
		local wagon_barrel = self.get_wagon_barrel(i)
		wagon_barrel.ActiveState = active_state('enabled')
	end

	for _, rock in pairs(self.rocks) do
		message_system:SendSync(rock.FieldObjectBehaviour, CS.Oak.GimmickResetEvent.Instance)
	end

	local start_pos = self.get_wagon_start_pos() + vector(-3, 0, 0)
	party_util.position_party(start_pos + vector(2, 0, -1), 'right', 'linear')
	character_util.remove_anim_and_emotion(user_party.Leader)
	camera_util.return_to_leader(0.5)
	for i = 1, 4 do
		character_util.remove_anim_and_emotion(wagon_resis[i])
	end
	self:set_wagon()

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self:start_escort()
end

function local_class:try_wagon_knockback(move_diff, ban_list)
	local wagon = self.get_wagon()
	local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(wagon.Bounds, move_diff)

	for i = 0, fo_list.Count - 1 do
		local fo = fo_list[i]

		if lua_helper.type_compare(fo, CS.Oak.Character) and table_util.contain_value(ban_list, fo) == false then
			-- 넉백 실행
			local knockback_dir = wagon.Bounds.center.z > fo.Position.z
					and vector(1, 0, -1) or vector(1, 0, 1)
			local knockback_info = character_util.knockback_info('physics', false, knockback_dir,
					13000, 0.05, CS.Oak.Constants.DefaultFrictionCoefficient)
			knockback_info.knocker = wagon
			command_util.publish_knock_back(fo.Owner, fo, knockback_info, nil)
		end
	end

	fo_list:Dispose()
end

--endregion

--region 메인 연출
function local_class:preload_main_opening(start_in_section_2)
	self.optimized_npcs_opening = load_util.create_optimized_npcs_async({

		resistance_1 = 'future2_resistance_male',
		resistance_2 = 'future2_resistance_female',
		resistance_3 = 'future2_resistance_male',
		resistance_4 = 'future2_resistance_female',
		resistance_5 = 'future2_resistance_male',
		resistance_6 = 'future2_resistance_female',
		resistance_7 = 'future2_resistance_male',
		resistance_8 = 'future2_resistance_female',
		resistance_9 = 'future2_resistance_male',
		resistance_10 = 'future2_resistance_female',
		resistance_11 = 'future2_resistance_male',
		resistance_12 = 'future2_resistance_female',
		resistance_13 = 'future2_resistance_male'
	})

	self.opening_resistance = create_generic_list(CS.Oak.Character)
	for i = 1, 13 do
		local cur
		cur = self.optimized_npcs_opening['resistance_'..i]
		self.opening_resistance:Add(cur)
	end

	local x = field:GetMarker('default_start').position.x

	character_util.set_position(self.opening_resistance[0], vector(x - 10, 0, -3))
	character_util.set_position(self.opening_resistance[1], vector(x - 8.5, 0, -2.5))
	character_util.set_position(self.opening_resistance[2], vector(x - 11, 0, -2))
	character_util.set_position(self.opening_resistance[3], vector(x - 10, 0, 1))
	character_util.set_position(self.opening_resistance[4], vector(x - 8.5, 0, 0))
	character_util.set_position(self.opening_resistance[5], vector(x - 8.5, 0, 0))
	character_util.set_position(self.opening_resistance[12], vector(x + 13, 0, -1))

	for i = 0, 2 do
		character_util.set_emotion(self.opening_resistance[i], { name = 'attack' })
		character_util.set_anim(self.opening_resistance[i], { name = 'run' })
	end
	character_util.set_emotion(self.opening_resistance[12], { name = 'attack' })
	character_util.set_anim(self.opening_resistance[12], { name = 'release' })
	character_util.set_direction(self.opening_resistance[12], 'right')

	self.resholder = CS.Foundations.ResourceHolder()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ui/prologue', 'label_ac',
			function(prefab)
				self.time_text = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.time_text:SetActive(false)

				local label_title = self.time_text.transform:GetChild(0)
				local label_shadow = label_title:GetChild(0)
				local title_ui_localize = label_title:GetComponent(typeof(CS.UILocalize))
				local shadow_ui_localize = label_shadow:GetComponent(typeof(CS.UILocalize))

				self.title_tween_alpha = label_title:GetComponent(typeof(CS.TweenAlpha))
				self.shadow_tween_alpha = label_shadow:GetComponent(typeof(CS.TweenColor))

				title_ui_localize.key = 'futurecastle_part2_s2_0'
				shadow_ui_localize.key = 'futurecastle_part2_s2_0'
			end)

	local princess = self.get_princess()
	local knight = self.get_knight_normal()
	local default_start_pos = field:GetMarker('default_start').position

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	param.MoveCamera = false
	character_util.convert_to_npc(get_character('chapter_end_knight_male'))
	character_util.convert_to_npc(get_character('chapter_end_knight_female'))
	knight.Position = default_start_pos + vector(8, 0, 0.5)
	knight.Direction = CS.Oak.Direction.Right

	character_util.convert_to_manual_character(knight, param)
	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)

	knight.Position = default_start_pos + vector(8, 0, 0.5)
	knight.Direction = CS.Oak.Direction.Right

	princess.Position = knight.Position + vector(0.45, 0, -0.05)
	princess.Direction = CS.Oak.Direction.Left
	character_util.set_anim(princess, { name = 'push'})
	character_util.set_emotion(princess, { name = 'attack' })

	character_util.set_emotion(knight, {name = 'sleep_deep'})
	character_util.set_anim(knight, {name = 'seat'})

	if not start_in_section_2 then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, {'section2_preloaded'}))
	end
end

function local_class:main_opening()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local factor = get_field_object('move_factor')
	factor.ActiveState = active_state('enabled')

	music_player_util.play_stage_music( { state = 'muted', mix = 0})

	self:custom_progress_section()

	local princess = self.get_princess()
	local knight = user_party.Leader

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_bg, self))

	camera_util.resize_to(3.5, 0)
	field:RemoveTint('section1', 0)

	local camera_height = self.camera.orthographicSize
	local camera_width = camera_height *  self.camera.aspect
	self.camera_pivot.position = self.field_grid_info:GetCameraPosInGrid(user_party.Leader.Position, camera_width, camera_height)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(0, 'linear')

	self.spark_screen_effect = unity_object_pool.GetOrCreate('fx_stage1_spark_screen_fx'):Instantiate(vector(knight.Position.x, 7, -7.5), unity_class.quaternion.identity, stage_camera.Transform)
	self.spark_screen_effect.transform.localRotation = unity_class.quaternion.Euler(45, 0, 0)

	music_player_util.play_sfx({ sfx_name = '02_stomp_fire_02', type_priority = 'event', player_priority = 'npc' })
	self.war_loop_2 = music_player_util.play_sfx({ sfx_name = '01_war_loop_02', loop = true, type_priority = "event", fade_in_time = 2})
	music_player_util.play_sfx({ sfx_name = '01_fire_01', type_priority = 'event', player_priority = 'npc' })


	camera_util.shake(0.4, 0.5)
	-- {0}!!!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(princess, { key = { 'futurecastle_part2_s2_5', user.Name }, skip = true, bubble_type = 'shout', scale = 1.5 })


	self.time_text:SetActive(true)
	self.title_tween_alpha:PlayForward()
	self.shadow_tween_alpha:PlayForward()
	self.war_loop_1 = music_player_util.play_sfx({ sfx_name = '01_war_loop_01', loop = true, type_priority = "event", fade_in_time = 2})
	--self.war_loop_2 = music_player_util.play_sfx({ sfx_name = '01_war_loop_02', loop = true, type_priority = "event", fade_in_time = 2})
	camera_util.resize_to_default(2)
	for i = 1, 2 do
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })
		character_util.shake(knight, 0.05, 0.3)
		wait_for_sec(1)
	end

	for i = 1, 2 do
		character_util.set_emotion(knight, {name = 'sleep_deep'})
		wait_for_sec(0.2)
		character_util.remove_emotion(knight)
		wait_for_sec(0.8)
	end

	character_util.remove_emotion(princess)
	character_util.move_to_async(princess, princess.Position + vector(0.55, 0, 0), 0.5, nil, false, true)

	-- 괜찮아, {0}?
	character_util.set_anim(princess, { name = 'sing' })
	speech_bubble_util.show_speech_bubble_async(princess, { key = { 'futurecastle_part2_s2_6', user.Name }, skip = true })
	character_util.remove_anim(princess)
	wait_for_sec(0.3)

	music_player_util.play_sfx({ sfx_name = '01_player_popup_01', type_priority = 'event', player_priority = 'npc' })
	character_util.mario_jump_async(knight, 'right')

	-- 갑자기 정신이라도 나간 것 처럼...
	music_player_util.play_sfx({ sfx_name = '01_rustle_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(princess, { name = 'cross_arm' })
	speech_bubble_util.show_speech_bubble_async(princess, {key = 'futurecastle_part2_s2_7', skip = true})

	-- 조금 쉬라고 말하고 싶지만 그럴 상황이 아냐.
	character_util.set_anim(princess, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(princess, {key = 'futurecastle_part2_s2_7_1', skip = true})
	character_util.remove_anim(princess)

	music_player_util.play_sfx({ sfx_name = '01_equip_weapon_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_direction(princess, 'right')
	wait_for_sec(0.3)

	-- 선봉대가 방위선을 강제로 열어 젖혔지만 오래 버티지는 못해.
	speech_bubble_util.show_speech_bubble_async(princess, {key = 'futurecastle_part2_s2_7_2', skip = true})

	-- 한시라도 빨리 성문에 도달해야 해!
	character_util.set_direction(princess, 'left')
	music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(princess, { name = 'shoot' })
	character_util.set_emotion(princess, { name = 'attack' })
	speech_bubble_util.show_speech_bubble_async(princess, {key = 'futurecastle_part2_s2_7_3', skip = true})
	character_util.remove_anim_and_emotion(princess)

	character_util.nod_twice(knight)
	wait_for_sec(0.3)
	CS.Oak.CommonScreenplay.ShowStageTitle(game_string:GetString(stage.Name))
	music_player_util.play_stage_music({state = 'field', mix = 1.5})
	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(user_party.Leader, { name = 'victory_get', loop = false })
	character_util.move_to_async(princess, knight.Position + vector(-1, 0, 0), nil, 4, true, true)
	character_util.set_direction(princess, 'right')
	character_util.set_direction(knight, 'right')

	camera_util.move_async(knight.Position, 0.25, {end_target = knight })

	self.wait_progressing_section = true
	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, {'section2_finished'}))
	while self.wait_progressing_section do
		coroutine.yield()
	end

	self:custom_progress_section()

	self.war_loop_1:FadeOut(2.0)
	self.war_loop_2:FadeOut(2.0)
	wait_for_sec(1)
	character_util.remove_anim(user_party.Leader)
	wait_for_sec(0.3)

	character_util.convert_to_party_member(princess, user_party, true)
	princess.FieldObjectController.DontFight = false

	CS.UnityEngine.Object.Destroy(self.time_text)
	self.time_text = nil
	self.resholder:Dispose()
	self.resholder = nil

	field_ui_manager:Show()
	user_party:ResetControllers()

	wait_for_sec(0.5)
	self:show_go_sign(3)
end

function local_class:opening_bg()
	local x = field:GetMarker('default_start').position.x

	for i = 0, 2 do
		character_util.move_waypoint(self.opening_resistance[i], self.opening_resistance[i].Position + vector(30, 0, 0), 6, false, 'stop', 'floor', CS.Oak.Direction.Right)
	end

	self:bomb_fall(vector(x + 3.5, 0, -2.5), 0.5)
	music_player_util.play_sfx({ sfx_name = '01_dash_06', type_priority = 'event', player_priority = 'npc' })
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x - 0.5, 0, 1), 1.2))
	wait_for_sec(0.3)
	self:bomb_fall(vector(x - 2, 0, -3), 0)
	wait_for_sec(0.5)
	self:bomb_fall(vector(x + 4, 0, -3), 0.3)
	for i = 3, 4 do
		character_util.set_emotion(self.opening_resistance[i], { name = 'attack' })
		character_util.set_anim(self.opening_resistance[i], { name = 'run' })
		character_util.move_waypoint(self.opening_resistance[i], self.opening_resistance[i].Position + vector(30, 0, 0), 6, false, 'stop', 'floor', CS.Oak.Direction.Right)
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x - 1, 0, -1.5), 0))
	wait_for_sec(0.3)

	for i = 0, 2 do
		character_util.stop(self.opening_resistance[i])
		character_util.set_emotion(self.opening_resistance[i], { name = 'attack' })
		character_util.set_anim(self.opening_resistance[i], { name = 'run' })
	end
	character_util.set_position(self.opening_resistance[0], vector(x - 10, 0, -2.5))
	character_util.set_position(self.opening_resistance[1], vector(x - 20, 0, -2))
	character_util.set_position(self.opening_resistance[2], vector(x - 25, 0, -3))
	character_util.move_to(self.opening_resistance[0], self.opening_resistance[0].Position + vector(16, 0, 0), 2.35, nil, true, false)
	character_util.move_waypoint(self.opening_resistance[1], self.opening_resistance[1].Position + vector(50, 0, 0), 6, false, 'stop', 'floor', CS.Oak.Direction.Right)
	character_util.move_waypoint(self.opening_resistance[2], self.opening_resistance[2].Position + vector(50, 0, 0), 6, false, 'stop', 'floor', CS.Oak.Direction.Right)


	self:bomb_fall(self.opening_resistance[12].Position, 0)
	character_util.remove_anim_and_emotion(self.opening_resistance[12])
	character_util.set_emotion(self.opening_resistance[12], { name = 'damaged' })
	character_util.air_spin(self.opening_resistance[12], { offset = vector(2, 0, 0), speed = 1.5, stay_time = 0.5 })
	self:bomb_fall(vector(x - 1.5, 0, -1.5), 0.5)
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.bomb_and_air_spin, self, vector(x + 6, 0, -2.5), self.opening_resistance[11], self.opening_resistance[0], 5))
	wait_for_sec(0.2)
	self:bomb_fall(vector(x + 2, 0, 0.75), 0.2)


	for i = 5, 9 do
		character_util.stop(self.opening_resistance[i])
		character_util.set_emotion(self.opening_resistance[i], { name = 'attack' })
		character_util.set_anim(self.opening_resistance[i], { name = 'run' })
	end
	character_util.set_position(self.opening_resistance[5], vector(x - 10, 0, 0))
	character_util.set_position(self.opening_resistance[6], vector(x - 11.5, 0, 1))
	character_util.set_position(self.opening_resistance[7], vector(x - 16, 0, 0.5))
	character_util.set_position(self.opening_resistance[8], vector(x - 21, 0, -2))
	character_util.set_position(self.opening_resistance[9], vector(x - 22.5, 0, -2.5))
	for i = 5, 6 do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_bg_run, self, self.opening_resistance[i]))
	end
	for i = 8, 9 do
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_bg_run, self, self.opening_resistance[i]))
	end
	character_util.move_to(self.opening_resistance[7], self.opening_resistance[7].Position + vector(22, 0, 0.5), 3.5, nil, true, false)
	self:bomb_fall(vector(x - 1.5, 0, 1), 0.3)
	wait_for_sec(0.15)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x - 1, 0, -1.5), 0))
	wait_for_sec(0.7)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x + 2, 0, -2.5), 0))
	wait_for_sec(0.35)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x - 1.5, 0, -1.5), 0))
	wait_for_sec(0.7)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x + 6, 0, -3), 0))
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.bomb_and_air_spin, self, vector(x + 6, 0, 0.5), self.opening_resistance[7], self.opening_resistance[10], 5))
	wait_for_sec(0.25)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_fall, self, vector(x - 3, 0, 0.5), 0))

	for i = 1, 4 do
		character_util.stop(self.opening_resistance[i])
		character_util.set_position(self.opening_resistance[i], vector(999, 0, 999))
		character_util.set_active_state(self.opening_resistance[i], "disabled")
	end
end

function local_class:opening_bg_run(target)
	character_util.move_waypoint_async(target, target.Position + vector(100, 0, 0), 6, false, 'stop', 'floor', CS.Oak.Direction.Right)
	character_util.stop(target)
	character_util.set_position(target, vector(999, 0, 999))
	character_util.set_active_state(target, "disabled")
end

function local_class:aisha_rush_fight()
	local aisha = get_character('aisha')
	local fight_aisha_army = {}
	local fight_aisha_invader = {}
	local fight_aisha_struggle = {}

	for i = 1, 6 do
		table.insert(fight_aisha_army, get_character('aisha_fight_' ..i))
	end
	for i = 1, 11 do
		table.insert(fight_aisha_invader, get_character('aisha_invader_' ..i))
	end
	for i = 1, 6 do
		table.insert(fight_aisha_struggle, get_character('aisha_struggle_' ..i))
	end

	camera_util.shake(0.2, 0.3)
	self:hide_go_sign()

	music_player_util.play_sfx({ sfx_name = '01_count_final_01', type_priority = 'gimmick', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_crowd_shout_06', type_priority = 'gimmick', player_priority = 'npc' })
	-- 와아아아아아아!
	speech_bubble_util.show_speech_bubble
		(aisha, {key = 'futurecastle_part2_s3_0', skip = false, bubble_type = 'shout', scale = 1.5, screen_pos = vector(0, 375)})

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.aisha_run_struggle, self, aisha))

	for i = 1, 4 do
		character_util.set_anim(fight_aisha_army[i], { name = 'run'})
		character_util.set_anim(fight_aisha_invader[i], { name = 'walk'})
		character_util.move_to(fight_aisha_invader[i], fight_aisha_invader[i].Position - vector(2.25, 0, 0), 3.25, nil, true, false)
	end
	character_util.move_to(fight_aisha_army[1], fight_aisha_invader[1].Position - vector(3.75, 0, -0.30), 3.25, nil, true, false)
	character_util.move_to(fight_aisha_army[2], fight_aisha_invader[1].Position - vector(3.75, 0, 0.30), 3.25, nil, true, false)
	character_util.move_to(fight_aisha_army[3], fight_aisha_invader[3].Position - vector(3.75, 0, -0.30), 3.25, nil, true, false)
	character_util.move_to(fight_aisha_army[4], fight_aisha_invader[3].Position - vector(3.75, 0, 0.30), 3.25, nil, true, false)
	for i = 5, 6 do
		character_util.set_anim(fight_aisha_army[i], { name = 'run'})
	end
	character_util.move_to(fight_aisha_army[5], fight_aisha_invader[1].Position - vector(4.25, 0, 0), 3.25, nil, true, false)
	character_util.move_to(fight_aisha_army[6], fight_aisha_invader[3].Position - vector(4.25, 0, 0), 3.25, nil, true, false)
	for i = 5, 11 do
		character_util.set_anim(fight_aisha_invader[i], { name = 'embarrassed'})
	end
	wait_for_sec(1)
	music_player_util.play_sfx({ sfx_name = '01_dash_06', type_priority = 'gimmick', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_minotaurs_slash_01', type_priority = 'gimmick', player_priority = 'npc' })
	camera_util.shake(0.4, 0.1)
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[10].Position + vector(-0.25, 0, 0))
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[9].Position + vector(-0.25, 0, 0))
	character_util.air_spin(fight_aisha_invader[10], {offset = vector(-1, 0, 0)})
	character_util.air_spin(fight_aisha_invader[9], {offset = vector(-1, 0, 0)})
	wait_for_sec(0.25)
	camera_util.shake(0.4, 0.1)
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[11].Position + vector(-0.25, 0, 0))
	character_util.air_spin(fight_aisha_invader[11], {offset = vector(-1, 0, 0)})
	wait_for_sec(0.25)
	camera_util.shake(0.4, 0.1)
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[7].Position + vector(-0.25, 0, 0))
	character_util.air_spin(fight_aisha_invader[7], {offset = vector(-1, 0, 0)})
	wait_for_sec(0.5)
	camera_util.shake(0.4, 0.1)
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[6].Position + vector(-0.25, 0, 0))
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[8].Position + vector(-0.25, 0, 0))
	character_util.air_spin(fight_aisha_invader[6], {offset = vector(-1, 0, 0)})
	character_util.air_spin(fight_aisha_invader[8], {offset = vector(-1, 0, 0)})
	wait_for_sec(0.5)
	camera_util.shake(0.4, 0.1)
	music_player_util.play_sfx({ sfx_name = '02_hit_big_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(fight_aisha_invader[5].Position + vector(-0.25, 0, 0))
	character_util.air_spin(fight_aisha_invader[5], {offset = vector(-1, 0, 0)})
	wait_for_sec(0.25)
	for i = 1, 6 do
		character_util.set_anim(fight_aisha_army[i], { name = 'guard', loop = false})
	end
	wait_for_sec(0.25)

	for i = 1, 4 do
		character_util.set_anim(fight_aisha_invader[i], { name = 'eat3' })
	end
	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_02', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_stomp_big_01', type_priority = 'event', player_priority = 'npc' })
	camera_util.shake(0.6, 0.4)
	for i = 1, 4 do
		unity_object_pool.GetOrCreate('FX_minotaur_buttbounce'):Instantiate(fight_aisha_army[i].Position + vector(0.25, 0, 0))

		character_util.shake(fight_aisha_army[i], 0.04, 9999)
		character_util.move_to(fight_aisha_army[i], fight_aisha_army[i].Position + vector(0.1, 0, 0), 1, nil)

		character_util.shake(fight_aisha_invader[i], 0.04, 9999)
		character_util.move_to(fight_aisha_invader[i], fight_aisha_invader[i].Position + vector(0.1, 0, 0), 1, nil)
	end
	for i = 5, 6 do
		character_util.shake(fight_aisha_army[i], 0.04, 9999)
		character_util.move_to(fight_aisha_army[i], fight_aisha_army[i].Position + vector(0.1, 0, 0), 1, nil)
	end
end

function local_class:aisha_run_struggle(target)
	character_util.set_anim(target, { name = 'run'})
	character_util.set_emotion(target, { name = 'attack' })
	if target.Position.z == -0.5 then
		character_util.move_to_async(target,
			vector(-73 - 4.35, 0, 0),
			3.5, nil, true, false)
	elseif target.Position.z == -0.75 then
		character_util.move_to_async(target,
			vector(-73 - 4.35, 0, 0),
			3.5, nil, true, false)
	elseif target.Position.z == -1.25 then
		character_util.move_to_async(target,
			vector(-73 - 4.35, 0, -1.5),
			3.5, nil, true, false)
	else
		character_util.move_to_async(target,
			vector(-73 - 4.35, 0, target.Position.z),
			3.5, nil, true, false)
	end
	camera_util.shake(0.1, 0.05)
	character_util.shake(target, 0.04, 9999)
	character_util.set_anim(target, { name = 'push'})
end

--폭격에 맞고 날아가는 연출
function local_class:bomb_and_air_spin(vtr, chr1, chr2, i)
	self:bomb_fall(vtr, 0)

	character_util.set_emotion(chr1, { name = 'damaged'})
	character_util.set_emotion(chr2, { name = 'damaged'})
	character_util.air_spin(chr1, { offset = vector(-1, 0, 0), speed = 1.5, stay_time = 0.3 })
	character_util.air_spin(chr2, { offset = vector(2, 0, 0), speed = 1.5, stay_time = 0.3 })

	wait_for_sec(2)
end

function local_class:gain_libera()
	for i = 1, self.battle_infos.battle_3.monster_count do
		local monster = self.get_monster(3, i)
		if monster.ActiveState == active_state('enabled')
				and lua_helper.type_compare(monster.FieldObjectController, CS.Oak.MonsterCharacterController) then
			character_util.convert_to_npc(monster)
		end
	end

	local target_leader = self.get_knight()
	local origin_leader = user_party.Leader

	target_leader.DamagedBehaviour = CS.Oak.ManualCharacterDamagedBehaviour.Create()
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Trap
	damage_info.sender = origin_leader
	damage_info.target = target_leader
	damage_info.damage = math.floor(target_leader.FieldObjectStatsBehaviour.MaxHP * (1 - origin_leader.FieldObjectStatsBehaviour.HpRatio))

	command_util.execute_damage(damage_info)

	origin_leader.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance

	screen_util.item_get_event(
			'cwp_knight_epic',
			'futurecastle_part2_s2_libera_title',
			'futurecastle_part2_s2_libera_subtitle',
			'futurecastle_part2_s2_libera_desc')

	local princess = self.get_princess()

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(self.get_knight(), param)
	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)
	character_util.convert_to_party_member(princess, user_party, true)
	user_party.Leader.Position = origin_leader.Position
	user_party.Leader.Direction = origin_leader.Direction
	origin_leader.Position = vector(999, 0, 999)

	stage.BattleManager:ForceEndBattles()

	self.stage_camera_info.target = user_party.Leader

	self:custom_progress_section()
	if self.battle_infos.battle_3.state == self.battle_state.done then
		--self:remove_camera_limiting()
		self:remove_battle_gate()
		self:show_go_sign(3)
	else
		for i = 1, self.battle_infos.battle_3.monster_count do
			local monster = self.get_monster(3, i)
			if monster.ActiveState == active_state('enabled')
					and lua_helper.type_compare(monster.FieldObjectController, CS.Oak.NPCCharacterController) then
				character_util.convert_to_monster(monster,
					self.battle_infos.battle_3.group_name, self.battle_infos.battle_3.battle_zone_name)
				command_util.execute_monster_notice(monster, user_party.Leader, 'battle')
			end
		end
	end
end

function local_class:panda_talk()
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(self.optimized_npcs_2['boss'], { key = 'futurecastle_main_a_s3_0', skip = false })
	speech_bubble_util.show_speech_bubble_async(self.optimized_npcs_2['panda'], { key = 'futurecastle_main_a_s3_1', skip = false })
	speech_bubble_util.show_speech_bubble_async(self.optimized_npcs_2['man'], { key = 'futurecastle_main_a_s3_2', skip = false })
end

function local_class:teatan_bg()

	local time_passed = unity_class.time.time
	local temp = unity_class.time.time - time_passed
	local x = field:GetMarker('iron_teatan_pos').position.x - 2.5
	local big_iron_teatan = get_character('big_iron_teatan')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.teatan_bg_anim, self))

	wait_for_sec(1.5)
	character_util.set_scale_factor(big_iron_teatan, nil, 1.5)
	character_util.set_position(big_iron_teatan, vector(x - 1, -14, 7.15))
	character_util.set_direction(big_iron_teatan, 'down')
	character_util.shake(big_iron_teatan, 0.15, 3)
	character_util.set_anim(big_iron_teatan, { name = 'appear', next_anim = 'idle' })
	time_passed = unity_class.time.time
	temp = unity_class.time.time - time_passed
	music_player_util.play_sfx({ sfx_name = '01_earthquake_04', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_iron_teatan_prepare_02', type_priority = 'event', player_priority = 'npc' })
	camera_util.shake(0.5, 2)

	for i = 0, 7 do
		character_util.stop(self.iron_invader[i])
	end
	time_passed = unity_class.time.time
	temp = 0
	while temp < 0.15 do

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end
	for i = 0, 7 do
		character_util.set_direction(self.iron_invader[i], 'up')
	end
	time_passed = unity_class.time.time
	temp = 0
	while temp < 0.15 do

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end
	for i = 0, 7 do
		character_util.set_anim(self.iron_invader[i], { name = 'embarrassed' })
	end

	time_passed = unity_class.time.time
	temp = 0
	while temp < 2 do
		local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseOutQuad(
			temp, 0, 1, 2))

		character_util.set_position(big_iron_teatan, vector(x - 1, -14 + (progress * 8), 7.25))

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end

	character_util.set_anim(big_iron_teatan, { name = 'laser', loop = false })
	wait_for_sec(0.3)
	for i = 0, 19 do
		local rand_x_1 = math.floor(unity_class.random.Range(-25, 25))
		local rand_y_1 = math.floor(unity_class.random.Range(-10, 10))

		local rand_x_2 = math.floor(unity_class.random.Range(-200, 200))
		local rand_z_2 = math.floor(unity_class.random.Range(-200, 0))

		rand_x_1 = rand_x_1/100
		rand_y_1 = rand_y_1/100

		rand_x_2 = rand_x_2/100
		rand_z_2 = rand_z_2/100

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator
			(self.shoot_missile, self, vector(x + rand_x_1 - 1, 1.5 + rand_y_1, 1.5), vector(x + rand_x_2, 0, 0 + rand_z_2), 0.1, false))
		wait_for_sec(0.1)

		if i%2 == 0 then
			local temp = i/2
			if temp <= 7 then
				character_util.air_spin(self.iron_invader[temp], { offset = vector(1, 0, 0), speed = 1.5, stay_time = 0.3 })
			end
		else
			local temp = i//2 + 10
			--character_util.air_spin(self.iron_invader[temp], { offset = vector(1, 0, 0), speed = 1.5, stay_time = 0.3 })
		end

	end

	wait_for_sec(0.5)
	character_util.remove_anim(big_iron_teatan)
	for i = 0, 2 do
		character_util.set_emotion(self.iron_resistance[i], { name = 'idle' })
	end
	wait_for_sec(0.5)
	character_util.mario_jump_async(self.iron_resistance[1], self.iron_resistance[1].Direction)
	wait_for_sec(0.3)
	for i = 0, 2 do
		character_util.set_emotion(self.iron_resistance[i], { name = 'smile' })
		character_util.stop_shake(self.iron_resistance[i])
		self.iron_resistance[i]:RemoveUpperAnimation()
		character_util.set_anim(self.iron_resistance[i], { name = 'success' })
	end
	wait_for_sec(0.3)

	time_passed = unity_class.time.time
	temp = unity_class.time.time - time_passed

	camera_util.shake(0.1, 1.5)
	character_util.shake(big_iron_teatan, 0.1, 3)
	music_player_util.play_sfx({ sfx_name = '01_earthquake_04', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_iron_teatan_prepare_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_crowd_clap_03', type_priority = 'event', player_priority = 'npc' })

	while temp < 3 do
		local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseOutQuad(
			temp, 0, 1, 3))

		character_util.set_position(big_iron_teatan, vector(x - 1, -6 - (progress * 8), 7.25))

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end
end

-- 특정위치로 미사일 쏘기
function local_class:shoot_missile(start_pos, end_pos, duration, use_unscaledtime)

	local dir = (end_pos - start_pos).normalized
	local rot = CS.UnityEngine.Quaternion.FromToRotation(unity_class.vector3.forward, dir)

	-- 발사 sfx
	music_player_util.play_sfx({
		sfx_name = '02_gun_shoot_01', play_pos = start_pos
	})

	local missile = unity_object_pool.GetOrCreate('FX_Missile_small_Proj'):Instantiate(start_pos, rot, nil)
	local trail = unity_object_pool.GetOrCreate('FX_Missile_small_Proj_contrail'):Instantiate(start_pos, rot, nil)

	local tp = 0
	while (tp < duration) do
		local progress = tp / duration

		missile.transform.position = unity_class.vector3.Lerp(start_pos, end_pos, progress)
		trail.transform.position = unity_class.vector3.Lerp(start_pos, end_pos, progress)

		if use_unscaledtime then
			tp = tp + unity_class.time.unscaledDeltaTime
		else
			tp = tp + unity_class.time.deltaTime
		end

		coroutine.yield(nil)
	end

	-- 타격 sfx
	music_player_util.play_sfx({ sfx_name = '02_fire_explosion_02', play_pos = end_pos, type_priority = 'default' })

	missile:Dispose()
	trail:TriggeredDispose()
	unity_object_pool.GetOrCreate('FX_Missile_small_Explosion'):Instantiate(end_pos)
	camera_util.shake(0.1, 0.1)
end

function local_class:teatan_bg_anim()
	character_util.move_to(self.iron_resistance[0], self.iron_resistance[0].Position + vector(-2.5, 0, 0), 3, nil, false, true)
	character_util.move_to(self.iron_resistance[2], self.iron_resistance[2].Position + vector(-2.5, 0, 0), 3, nil, false, true)
	for i = 0, 7 do
		character_util.move_waypoint(self.iron_invader[i], self.iron_invader[i].Position + vector(-5, 0, 0), 1.5, true, nil, nil, nil, true)
	end
	self.iron_resistance[1]:RemoveUpperAnimation()
	character_util.set_direction(self.iron_resistance[1], 'left')
	character_util.set_anim(self.iron_resistance[1], { name = 'prostrate' })
	character_util.normal_jump(self.iron_resistance[1])
	character_util.move_to(self.iron_resistance[1], self.iron_resistance[1].Position + vector(-0.5, 0, 0), 0.3, nil)
	wait_for_sec(0.5)
end

function local_class:super_invader_battle()
	local super_invader = self.get_super_invader()
	local sohee = self.get_sohee()
	local emoji = get_character('sohee_emoticon')
	local princess = self.get_princess()
	local fall_pos = vector(11, 0, -1)
	local battle_info = self.battle_infos.battle_7


	super_invader.Position = fall_pos + vector(0, 40, 0)
	super_invader.ActiveState = active_state('visible')
	super_invader.LockedDirection = fall_pos.x > user_party.Leader.Position.x
			and CS.Oak.Direction.Left or CS.Oak.Direction.Right
	character_util.set_anim(super_invader, { name = 'stomp', next_anim = 'idle'})
	wp_util.move_way_points_async(super_invader, {waypoints = fall_pos, speed = 40})

	while self.leader_dead do
		coroutine.yield(nil)
	end
	music_player_util.play_sfx({ sfx_name = '02_stomp_01', type_priority = 'gimmick', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_super_invader_roar_02', type_priority = 'gimmick', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_minotaur_buttbounce'):Instantiate(super_invader.Position)
	camera_util.shake(0.4, 0.5)

	super_invader.ActiveState = active_state('enabled')
	character_util.convert_to_monster(super_invader, battle_info.group_name, battle_info.battle_zone_name)
	stage.BuffManager:AddBuff(super_invader, CS.Oak.EquipmentSlot.None, super_invader,
			'persistent_no_damage', 0, false, false)
	command_util.execute_monster_notice(super_invader, user_party.Leader, 'battle')
	super_invader.LockedDirection = CS.Oak.Direction.None
	super_invader.FieldObjectController.DontFight = true
	wait_for_sec(1)

	camera_util.shake(0.2, 2)
	character_util.set_anim(super_invader, { name = 'eat3', next_anim = 'idle'})
	wait_for_sec(2)
	character_util.remove_anim(super_invader)
	super_invader.FieldObjectController.DontFight = false

	local monster_list = create_generic_list(CS.Oak.Character)

	monster_list:Add(super_invader)

	self.is_turret_battle = true
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.buster_turret_attack, self, monster_list, 0.03))

	wait_for_sec(5)

	-- 이대로는 끝이 없겠어...
	speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_part2_s2_9", skip = false })

	-- 뭔가 다른게 필요해. 강력한 무기라거나...
	speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_part2_s2_10", skip = false })

	self.is_turret_battle = false

	character_util.show_emoticon_async(emoji, nil, 'notice')

	-- {0}! 이거 받아!
	while self.leader_dead do
		coroutine.yield(nil)
	end
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', type_priority = 'gimmick', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble_async(emoji, { key = { 'futurecastle_part2_s2_11', user.Name }, skip = false, bubble_type = 'shout', scale = 1.3 })

	while self.leader_dead do
		coroutine.yield(nil)
	end
	music_player_util.play_sfx({ sfx_name = '02_bomb_holdup_fail_01', type_priority = 'gimmick', player_priority = 'npc' })
	character_util.set_anim(sohee, { name = 'handover', loop = false, next_anim = 'idle'})
	wait_for_sec(1.2)

	local time_passed = 0
	local duration = 0.7
	local start_pos = vector(13, 3.2, -5)
	local target_pos = user_party.Leader.Position
	local sin_height = 5
	local gatling_box = self.get_item_dropper(self.item_info.dropper_data.item_dropper_4.num)
	local damage_behaviour = gatling_box.DamagedBehaviour
	gatling_box.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	local start_scale = 1.5

	while self.leader_dead do
		coroutine.yield(nil)
	end
	music_player_util.play_sfx({ sfx_name = '01_throw_01', type_priority = 'gimmick', player_priority = 'npc' })
	while time_passed < duration do
		local progress = unity_class.mathf.Clamp01(time_passed / duration)
		local linear_pos = start_pos * (1 - progress) + target_pos * progress
		local sin_y = math.sin(math.pi * progress) * sin_height
		gatling_box.Position = linear_pos + vector(0, sin_y, 0)
		local cur_scale = start_scale * (1 - progress) + 1 * progress
		gatling_box.Transform.localScale = unity_class.vector3.one * cur_scale

		time_passed = time_passed + unity_class.time.deltaTime

		coroutine.yield()
	end

	gatling_box.Position = target_pos

	self:add_item_marker_to_point(target_pos)

	gatling_box.DamagedBehaviour = damage_behaviour

	self.is_turret_battle = true
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.buster_turret_attack, self, monster_list, 0.03))
end

function local_class:gain_gatling_gun()
	local super_invader = self.get_super_invader()
	local battle_info = self.battle_infos.battle_7

	super_invader.CharacterBehaviour:CancelAllBattleActions(true)
	character_util.convert_to_npc(super_invader)

	local target_leader = self.get_knight_gatling()
	local origin_leader = user_party.Leader

	target_leader.DamagedBehaviour = CS.Oak.ManualCharacterDamagedBehaviour.Create()
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Trap
	damage_info.sender = self.get_knight_normal()
	damage_info.target = target_leader
	damage_info.damage = math.floor(target_leader.FieldObjectStatsBehaviour.MaxHP * (1 - origin_leader.FieldObjectStatsBehaviour.HpRatio))

	command_util.execute_damage(damage_info)

	screen_util.item_get_event(
			'cwp_futureknight_item',
			'futurecastle_part2_s2_gatling_title',
			'futurecastle_part2_s2_gatling_subtitle',
			'futurecastle_part2_s2_gatling_desc')

	local princess = self.get_princess()

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	character_util.convert_to_manual_character(target_leader, param)
	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.TopHpBar)
	character_util.convert_to_party_member(princess, user_party, true)
	user_party.Leader.Position = origin_leader.Position
	user_party.Leader.Direction = origin_leader.Direction
	origin_leader.Position = vector(999, 0, 999)

	self.stage_camera_info.target = user_party.Leader

	stage.BuffManager:RemoveBuff(super_invader, CS.Oak.EquipmentSlot.None, super_invader, 'persistent_no_damage')

	character_util.convert_to_monster(super_invader, battle_info.group_name, battle_info.battle_zone_name)
	command_util.execute_monster_notice(super_invader, user_party.Leader, 'battle')

	self:custom_progress_section()
end

function local_class:scroll_ending()
	wait_for_sec(6)
	local sfx_1 = music_player_util.play_sfx({ sfx_name = '01_war_loop_02', type_priority = 'event', player_priority = 'npc' })
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	wait_for_sec(1.5)
	character_util.move_to_async(user_party.Leader, vector(142, 0, -1), nil, 3, true, true)
	character_util.set_direction(user_party.Leader, 'down')
	wait_for_sec(1)
	music_player_util.play_sfx({ sfx_name = '01_swing_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_direction(user_party.Leader, 'left')
	wait_for_sec(0.5)
	music_player_util.play_sfx({ sfx_name = '01_swing_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_direction(user_party.Leader, 'down')
	wait_for_sec(0.5)
	music_player_util.play_sfx({ sfx_name = '01_swing_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_direction(user_party.Leader, 'right')
	wait_for_sec(0.5)

	sfx_1:FadeOut(2)
	music_player_util.play_stage_music( { state = 'muted', mix = 2})
	field:Tint(nil, CS.UnityEngine.Color(0.5, 0.5, 0.5, 1), 2)
	camera_util.shake(0.5, 0.4)
	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_stomp_fire_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	character_util.normal_jump(user_party.Leader)
	wait_for_sec(1)

	local bbg = get_field_object('back_background')
	local cur_bbg_pos = bbg.transform.position

	character_util.set_direction(user_party.Leader, 'up')
	wait_for_sec(0.7)
	character_util.show_emoticon_async(user_party.Leader, nil, 'notice')
	music_player_util.play_sfx({ sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc' })
	character_util.set_anim(user_party.Leader, { name = 'embarrassed' })
	local sfx = music_player_util.play_sfx({ sfx_name = '01_earthquake_03', type_priority = 'event', player_priority = 'npc' })
	camera_util.shake(0.2, 2)
	wait_for_sec(1)
	field:RemoveTint(nil, 3)
	self.bg_back = false

	sfx:FadeOut(1.5)

	self.spark_screen_effect.transform:Find('fx_stage1_spark_screen_fx').gameObject:SetActive(false)
	local effect2 = self.spark_screen_effect.transform:Find('fx_stage1_sidescroll-chase_screen_fx')
	effect2.gameObject:SetActive(true)

	self.spark_screen_effect.transform.position = self.spark_screen_effect.transform.position + vector(0, 0, 10)
	local start_pos = self.spark_screen_effect.transform.position

	bbg.Position = cur_bbg_pos
	character_util.move_to(bbg,
			cur_bbg_pos + vector(0, 0, 20), 2, nil)
	camera_util.move(vector(cur_bbg_pos.x, 0, 22.5), 2, { ignorecameragrids = true })

	local time_passed = unity_class.time.time
	local temp = unity_class.time.time - time_passed

	while temp < 1 do
		self.spark_screen_effect.transform.position = start_pos - vector(0, 0, temp * 3.2)

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end

	-- 올라가는 중간에 SpecialEvents로 레이어를 바꿔줌 한프레임 정도 대기하여 전환 자연스럽게 적용
	CS.Utils.ChangeLayersRecursively(get_field_object('back_background').transform, 'SpecialEvents')
	stage_camera.Camera.cullingMask = 1 << CS.UnityEngine.LayerMask.NameToLayer('SpecialEvents')
	CS.Utils.ChangeLayersRecursively(effect2.transform, 'SpecialEvents')
	coroutine.yield()
	self:progress_main_section()

	while temp < 2 do
		self.spark_screen_effect.transform.position = start_pos - vector(0, 0, temp * 3.2)

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end
end

function local_class:sohee_appear()
	local sohee = self:get_sohee()

	wait_for_sec(3)

	character_util.set_anim(sohee, { name = 'appear', loop = false, next_anim = 'idle' })
	character_util.move_to_async(sohee, vector(13, 20, -17), 2, nil)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	-- 내 작은 친구에게 인사하라고, 이 빌어먹은 외계인 놈들아!
	speech_bubble_util.show_speech_bubble(sohee, { key = { 'futurecastle_part2_s2_8_0', user.Name }, skip = false, bubble_type = 'shout', scale = 1.3 })

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.sohee_move, self))

	local monster_list = create_generic_list(CS.Oak.Character)

	for i = 1, 6 do
		monster_list:Add(self.get_monster(7, i))
	end
	self.is_turret_battle = true

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.buster_turret_attack, self, monster_list, 0.5))
end

function local_class:sohee_move()
	local sohee = self:get_sohee()
	local emoji = get_character('sohee_emoticon')

	--field_ui_manager:RemoveUI(emoji, CS.Oak.FieldUiType.CharacterStats)
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CharacterStats, emoji)
	character_util.set_position(emoji, vector(13, 20, -16))

	while self.is_sohee_move do
		character_util.move_to(emoji, vector(15, 20, -16), 5, nil)
		character_util.move_to_async(sohee, vector(15, 20, -17), 5, nil)
		wait_for_sec(3)
		character_util.move_to(emoji, vector(13, 20, -16), 5, nil)
		character_util.move_to_async(sohee, vector(13, 20, -17), 5, nil)
		wait_for_sec(3)
		character_util.move_to(emoji, vector(11, 20, -16), 5, nil)
		character_util.move_to_async(sohee, vector(11, 20, -17), 5, nil)
		wait_for_sec(3)
		character_util.move_to(emoji, vector(13, 20, -16), 5, nil)
		character_util.move_to_async(sohee, vector(13, 20, -17), 5, nil)
		wait_for_sec(3)
	end
end

-- 버스터 터렛 공격
function local_class:buster_turret_attack(monster_list, damage_per_hp)
	local sohee = self:get_sohee()

	local timer = 0
	local attack_delay = 1
	local attack_duration = 1
	local is_attack = false

	-- 타겟 조준 발사를 위한 변수
	local shoot_effect
	local target_effect
	local target

	while self.is_turret_battle and self.leader_dead == false do
		timer = timer + unity_class.time.deltaTime

		if not is_attack and timer > attack_delay then
			timer = 0
			is_attack = true

			-- 근처에 있는 적 한 명 잡아서 타겟으로 지정
			local short_dist = 9999
			local cur_index = 0

			for i = 0, monster_list.Count - 1 do
				if not monster_list[i].FieldObjectStatsBehaviour.IsDead then
					local cur_dist = (sohee.Position - monster_list[i].Position).magnitude

					if cur_dist < short_dist then
						short_dist = cur_dist
						cur_index = i
					end
				end
			end

			target = monster_list[cur_index]

		elseif is_attack and timer > attack_duration then
			timer = 0
			is_attack = false

			local start_pos = sohee.Position + vector(0, 0, 1.5)
			local end_pos = target.Position

			if self.leader_dead == false then
				music_player_util.play_sfx({ sfx_name = '02_charge_laser_01', type_priority = 'event', player_priority = 'npc' })
			end
			character_util.set_animation_n_times_async(sohee, { name = 'shoot', count = 4 })

			if self.leader_dead == false then
				music_player_util.play_sfx({ sfx_name = '02_missile_launch_03', type_priority = 'event', player_priority = 'npc' })
			end
			local shoot_effect = unity_object_pool.GetOrCreate('FX_IceFrostBall_Proj'):Instantiate(start_pos)
			shoot_effect.transform.localScale = vector(0.6, 0.6, 0.6)

			--[[
			local effect_rot = unity_class.quaternion.LookRotation(start_pos - end_pos) * unity_class.quaternion.Euler(vector(0, 0, 0))
			shoot_effect.transform.localRotation = effect_rot
			]]

			local time_passed = unity_class.time.time
			local temp = unity_class.time.time - time_passed
			local duration = 0.3
			while temp < duration do
				local progress = unity_class.mathf.Clamp01(temp / duration)
				shoot_effect.transform.position = start_pos * (1 - progress) + end_pos * progress
				shoot_effect.transform.localScale = vector(0.6, 0.6, 0.6) * (1 - progress) + vector(0.3, 0.3, 0.3)

				temp = unity_class.time.time - time_passed
				coroutine.yield()
			end

			shoot_effect:Dispose()
			if self.leader_dead == false then
				music_player_util.play_sfx({ sfx_name = '02_impact_lightning_01', type_priority = 'event', player_priority = 'npc' })
				camera_util.shake(0.3, 0.2)
			end
			target_effect = unity_object_pool.GetOrCreate('fx_snowman_bomb_explosion'):Instantiate(
					target.Position + vector(0, 0.3, 0))

			local damage_info = CS.Oak.DamageInfo()

			damage_info.type = CS.Oak.DamageType.Trap
			damage_info.sender = sohee
			damage_info.target = target
			damage_info.damage = math.floor(target.FieldObjectStatsBehaviour.MaxHP * damage_per_hp)
			damage_info.direction = (target.Position - sohee.Position).normalized

			command_util.execute_damage(damage_info)
		end

		coroutine.yield(nil)
	end

	-- 이펙트 사라질 때까지 유예 기간
	wait_for_sec(1)

	if target_effect ~= nil then
		target_effect.transform.localScale = unity_class.vector3.one
	end
end

-- 2개의 벡터로 angle 구하기 (기준선은 x y 사분면에서 우측 좌표 x축이 0도, 시계 반대방향으로 증가)
function local_class:get_angle(target, start)
	local dir = vector(target.x - start.x, target.z - start.z)

	local sign
	if target.z < start.z then
		sign = -1
	else
		sign = 1
	end

	return unity_class.vector2.Angle(unity_class.vector2.right, dir) * sign
end

function local_class:escort_start()
	local princess = self.get_princess()
	local wagon = self.get_wagon()
	local wagon_inv = self.get_wagon_interact()
	wagon_inv.Position = wagon.Position + vector(0, 0, 0.5)

	ui_quest_marker:AddQuestMarkerToPoint('wagon', self.main_quest_id, true, wagon_inv.Position + vector(0, 0, 0.5))

	if self.current_main_state == self.main_state.meet_wagon then
		-- 성벽을 부술 화약들이야!
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_part2_s3_1", skip = false })
	end

	if self.current_main_state == self.main_state.meet_wagon then
		-- 어서 운반해야 해!
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_part2_s3_1_0", skip = false })
	end
end

function local_class:escort_ending()
	local craig = get_character('s3_wagon_resistance_3')
	local lavi = get_character('s3_wagon_resistance_4')
	local marty = get_character('s3_wagon_resistance_2')
	local princess = self.get_princess()
	local harvester = get_character('monster_battle_8_1')
	local active_zone_bounds = field:GetZone('escort_ending_active').Bounds

	local princess_wing_obj

	self.resholder = CS.Foundations.ResourceHolder()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_3_futurecastle/effects/futurecastle', 'fx_event_princess_barrier_wings_ready', function(prefab)
				princess_wing_obj = CS.UnityEngine.GameObject.Instantiate(prefab) --, unity_class.quaternion.identity, princess)
				princess_wing_obj:SetActive(false)
			end)

	craig:RemoveUpperAnimation()
	lavi:RemoveUpperAnimation()
	marty:RemoveUpperAnimation()
	princess:RemoveUpperAnimation()

	character_util.set_anim(craig, { name = 'eat' })
	character_util.set_anim(lavi, { name = 'eat' })
	character_util.set_anim(marty, { name = 'eat' })
	character_util.set_anim(princess, { name = 'eat' })

	character_util.set_direction(craig, 'right')
	character_util.set_direction(lavi, 'left')
	character_util.set_direction(princess, 'right')
	character_util.set_direction(marty, 'left')

	local wait_dur = 1.5
	local time_passed = 0
	local zone_limit_on = false
	while time_passed < wait_dur or zone_limit_on == false do
		if zone_limit_on == false and active_zone_bounds:Contains(user_party.Leader.Position) then
			zone_limit_on = true
			self:set_camera_limiting('escort_ending_zone')
		end
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	local barrel_2 = get_field_object('barrel_2')

	music_player_util.play_sfx({ sfx_name = '01_holdup_01', type_priority = 'event', player_priority = 'npc' })
	character_util.remove_anim(lavi)
	barrel_2.ActiveState = active_state('visible')
	barrel_2.Position = lavi.Position + vector(0, 1, 0)
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	speech_bubble_util.show_speech_bubble(lavi, { key = "futurecastle_part2_s3_3", skip = false, type_speed = 0 })
	character_util.set_anim(lavi, { name = 'hold_loop', upper = true})
	wait_for_sec(0.5)
	character_util.move_to(barrel_2, barrel_2.Position + vector(0.5, 0, 0), nil, 4)
	character_util.move_to_async(lavi, lavi.Position + vector(0.5, 0, 0), nil, 4, true, true)
	character_util.move_to(barrel_2, barrel_2.Position + vector(0, 0, 3), nil, 4)
	character_util.move_to_async(lavi, lavi.Position + vector(0, 0, 3), nil, 4, true, true)
	character_util.set_direction(lavi, 'left')

	local barrel_1 = get_field_object('barrel_1')

	character_util.remove_anim(craig)
	barrel_1.ActiveState = active_state('visible')
	barrel_1.Position = craig.Position + vector(0, 1, 0)
	character_util.set_anim(craig, { name = 'hold_loop', upper = true})

	character_util.set_direction(lavi, 'up')

	music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_jump_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', type_priority = 'event', player_priority = 'npc' })
	field_ui_manager:RemoveUI(lavi, CS.Oak.FieldUiType.CharacterStats)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump, self, lavi, lavi.Position, lavi.Position + vector(0, -18, 8), 1.5))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump, self, barrel_2, barrel_2.Position, barrel_2.Position + vector(0, -18, 8), 1.5))

	character_util.move_to(barrel_1, barrel_1.Position + vector(-0.5, 0, 0), nil, 4)
	character_util.move_to_async(craig, craig.Position + vector(-0.5, 0, 0), nil, 4, true, true)
	character_util.move_to(barrel_1, barrel_1.Position + vector(0, 0, 3), nil, 4)
	character_util.move_to_async(craig, craig.Position + vector(0, 0, 3), nil, 4, true, true)

	local barrel_3 = get_field_object('barrel_3')

	character_util.remove_anim(marty)
	barrel_3.ActiveState = active_state('visible')
	barrel_3.Position = marty.Position + vector(0, 1, 0)
	character_util.set_anim(marty, { name = 'hold_loop', upper = true})

	music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_jump_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', type_priority = 'event', player_priority = 'npc' })
	field_ui_manager:RemoveUI(craig, CS.Oak.FieldUiType.CharacterStats)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump, self, craig, craig.Position, craig.Position + vector(0, -18, 8), 1.5))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump, self, barrel_1, barrel_1.Position, barrel_1.Position + vector(0, -18, 8), 1.5))


	harvester.ActiveState = active_state('visible')
	character_util.set_direction(harvester, 'right')
	character_util.set_position(harvester, vector(60, -5.6, 5.3))
	character_util.set_anim(harvester, { name = 'appear', next_anim = 'idle' })
	character_util.move_to(harvester, vector(100, -5.6, 5.3), 1.63, nil)
	wait_for_sec(0.5)

	character_util.move_to(barrel_3, barrel_3.Position + vector(-0.5, 0, 0), 0.25, nil)
	character_util.move_to_async(marty, marty.Position + vector(-0.5, 0, 0), 0.25, nil, true, true)
	character_util.move_to(barrel_3, barrel_3.Position + vector(0, 0, 1), 0.5, nil)
	character_util.move_to_async(marty, marty.Position + vector(0, 0, 1), 0.5, nil, true, true)

	music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_jump_01', type_priority = 'event', player_priority = 'npc' })
	field_ui_manager:RemoveUI(marty, CS.Oak.FieldUiType.CharacterStats)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump_stop, self, marty, marty.Position, marty.Position + vector(0, -18, 8), 1.5))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.barrel_jump_stop, self, barrel_3, barrel_3.Position, barrel_3.Position + vector(0, -18, 8), 1.5))
	wait_for_sec(0.375)
	music_player_util.play_sfx({ sfx_name = '02_die_boss_harvester_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_harvester_crush_02', type_priority = 'event', player_priority = 'npc' })
	camera_util.shake(0.3, 0.4)
	barrel_3.ActiveState = active_state('disabled')
	barrel_3.Position = vector(999, 0, 999)
	marty:RemoveUpperAnimation()
	character_util.set_direction(marty, 'right')
	character_util.set_anim(marty, { name = 'embarrassed' })
	character_util.set_emotion(marty, { name = 'damaged' })
	marty.Transform:SetParent(harvester.Transform)
	character_util.set_position(marty, vector(0.8, 3, -1.2), true)

	--[[
	local time_passed = unity_class.time.time
	local temp = unity_class.time.time - time_passed
	while temp < 1.5 do
		local progress = CS.Oak.Interpolations.EaseOutExpo(unity_class.mathf.Clamp01(temp / 1.5), 0, 1, 1)

		character_util.set_position(harvester, vector(98 + (progress * 2), -5.6, 5.3))

		temp = unity_class.time.time - time_passed
		coroutine.yield()
	end
	]]
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	music_player_util.play_sfx({ sfx_name = '01_linda_scream_01', type_priority = 'event', player_priority = 'npc' })
	character_util.move_to(harvester, vector(140, -5.6, 5.3), 1.63, nil)

	princess:RemoveUpperAnimation()
	character_util.remove_anim(princess)
	character_util.set_emotion(princess, { name = 'attack' })
	character_util.move_to_async(princess, vector(102, 0, 0.5), nil, 6, true, false)
	character_util.normal_jump(princess)
	camera_util.shake(0.3, 0.2)
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', type_priority = 'event', player_priority = 'npc' })
	-- 주니어!
	speech_bubble_util.show_speech_bubble_async(princess, {key = 'futurecastle_part2_s3_4', skip = true, bubble_type = 'shout', scale = 1.3})


	character_util.set_anim(princess, { name = 'gauntlet_boong_attack_ready_loop'})
	music_player_util.play_sfx({ sfx_name = '02_princess_wing_01', type_priority = 'event', player_priority = 'npc' })
	local sfx = music_player_util.play_sfx({ sfx_name = '02_princess_wing_01', type_priority = 'event', player_priority = 'npc' })
	princess_wing_obj.transform.localPosition = princess.Position
	princess_wing_obj.transform:SetParent(princess.SpineController.SpineContainerTransform)
	princess_wing_obj:SetActive(true)

	wait_for_sec(1)
	sfx:Stop()
	music_player_util.play_sfx({ sfx_name = '02_princess_shoot_02', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_princess_provoke_01', type_priority = 'event', player_priority = 'npc' })
	camera_util.shake(0.3, 0.2)
	local wing_effect = unity_object_pool.GetOrCreate('fx_m_futureprincess_support_barrier')
			:Instantiate(princess.Position, unity_class.quaternion.identity,
			princess.SpineController.SpineContainerTransform)
	character_util.move_to_async(princess, vector(106, 0, 0.5), nil, 15, true, false)
	field_ui_manager:Show()
	user_party:ResetControllers()

	self:remove_camera_limiting()

	self:custom_progress_section()
	self:remove_camera_limiting()
	self:remove_battle_gate()
	character_util.set_active_state(marty, 'disabled')

	character_util.set_anim(princess, { name = 'run'})
	music_player_util.play_sfx({ sfx_name = '02_twohand_stomp_01', type_priority = 'event', player_priority = 'npc' })
	unity_object_pool.GetOrCreate('FX_minotaur_buttbounce'):Instantiate(princess.Position)
	character_util.jump(princess, 2, 0.5)
	character_util.move_to_async(princess, princess.Position + vector(30, 0, 0), nil, 10)

	character_util.set_position(princess, vector(999, 0, 999))
	character_util.set_position(harvester, vector(999, 0, 999))

	if is_unity_null(princess_wing_obj) == false then
		CS.UnityEngine.Object.Destroy(princess_wing_obj)
		princess_wing_obj = nil
	end
	wing_effect:Dispose()
end

function local_class:barrel_jump(object, start_pos, end_pos, duration)
	local time = 0
	local free_fall_fire = CS.CalculatorFreeFall.Create(19.6, 39.2, 0, 0)
	while time < duration do
		time = time + unity_class.time.deltaTime
		free_fall_fire:Proceed(unity_class.time.deltaTime)
		local dist_y = free_fall_fire:GetDistance()
		local move_pos = unity_class.vector3.Lerp(start_pos, end_pos, time / duration)
		object.transform.position = move_pos + vector(0, 1, 0) * dist_y
		object.transform.localScale = (1 - ((time/duration) * 0.5)) * unity_class.vector3.one
		coroutine.yield()
	end
end

function local_class:barrel_jump_stop(object, start_pos, end_pos, duration)
	local time = 0
	local free_fall_fire = CS.CalculatorFreeFall.Create(19.6, 39.2, 0, 0)
	while time < duration/4 do
		time = time + unity_class.time.deltaTime
		free_fall_fire:Proceed(unity_class.time.deltaTime)
		local dist_y = free_fall_fire:GetDistance()
		local move_pos = unity_class.vector3.Lerp(start_pos, end_pos, time / duration)
		object.transform.position = move_pos + vector(0, 1, 0) * dist_y
		coroutine.yield()
	end
end

function local_class:harvester_fly()
	-- NPC 동적할당
 	self.optimized_harvester = load_util.create_optimized_npcs_async({
		harvester = 'future2_boss_harvester'
 	})

 	character_util.set_position(self.optimized_harvester['harvester'], vector(user_party.Leader.Position.x + 15, 9, -14.5))
 	character_util.set_direction(self.optimized_harvester['harvester'], 'left')
 	character_util.set_scale_factor(self.optimized_harvester['harvester'], nil, 2)
 	self.optimized_harvester['harvester'].SpineController:AddColor(self.optimized_harvester['harvester'].Name, unity_color({0.1, 0.1, 0.1, 1}), 1, 0)

	music_player_util.play_sfx({ sfx_name = '02_harvester_prepare_01', type_priority = 'event', player_priority = 'npc' })
	character_util.move_to_async(self.optimized_harvester['harvester'], self.optimized_harvester['harvester'].Position + vector(-40, 0, 0), nil, 21, false, true)

 	-- 동적 로딩한 캐릭터들 전부 제거
 	if self.optimized_harvester ~= nil then
		load_util.dispose_optimized_npcs(self.optimized_harvester)
		self.optimized_harvester = nil
 	end
end

function local_class:set_field_music()
	music_player_util.set_stage_music_clip_async({ name = "bgm_battle_boss", state = 'field' })
end

--endregion

--region 포로 스타피스
function local_class:rescue_captive(captive, captive_index)
	local effect = self.get_captive_effect():Instantiate(captive.Position)
	effect.transform.localScale = vector(0.3, 0.3, 0.3)

	captive.Interactable = CS.Oak.NonInteractable.Instance
	music_player_util.play_sfx_one_shot('02_wolf_boss_bomb_01')

	-- 포로 쉐이크 이벤트 종료 처리
	for i = 1, #self.captives do
		if lua_helper.reference_equals(self.captives[i] , captive) then
			self.captive_shake_stat[i] = false
			self.help_icons[i]:Dispose()
			self.help_icons[i] = nil
			character_util.stop_shake(captive)
			break
		end
	end

	character_util.set_emotion(captive, { name = 'smile' })
	local rand_script = random_util.get_random_int(1, 2)

	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble(captive, {key = 'future_2_captive_'..rand_script })
	character_util.set_animation_n_times_async(captive, { name = 'success', count = 1 })

	local appear_pos = captive.Position
	local purple_coin = nil

	-- 스타피스를 주는 포로일 경우
	-- 스타피스를 안 줬을 경우 조건 검사 후 퍼플코인 드롭
	local coin_name = 'purple_coin_' .. (captive_index + 30)
	if not stage_progress:HasPurpleCoin(coin_name) then
		music_player_util.play_sfx_one_shot('01_throw_01')
		purple_coin = get_field_object(coin_name)
		purple_coin.Position = captive.Position
		purple_coin.ActiveState = active_state('visible')
		message_system:SendSync(purple_coin, CS.Oak.PurpleCoinAppearEvent.Instance)
	end

	local wait = true
	music_player_util.play_sfx_one_shot('01_dash_01')
	character_util.spine_set_alpha_fade(captive, 0, 2)
	wp_util.move_way_points(captive,
			{waypoints = appear_pos + vector(12, 0, 0),
			 speed = 6,  run = true, callback = function()
				wait = false
			end})

	if purple_coin ~= nil then
		local start_scale = 0.5
		local target_scale = 1
		local time_passed = 0
		local duration = 0.25
		local sprite = purple_coin.Transform:GetChild(0)
		local shadow = purple_coin.Transform:GetChild(1)

		while time_passed < duration do
			local progress = unity_class.mathf.Clamp01(time_passed / duration)
			local cur_scale = (start_scale * (1 - progress) + target_scale * progress) * unity_class.vector3.one
			sprite.localScale = cur_scale
			shadow.localScale = cur_scale
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield()
		end

		purple_coin.ActiveState = active_state('enabled')
	end

	while wait do
		coroutine.yield()
	end

	captive.Position = vector(999,0,999)
	character_util.set_active_state(captive, 'disabled')
end

-- 포로 구출 전 코루틴
function local_class:captive_shake(captive_num)
	wait_for_sec(unity_class.random.Range(0, 5))

	local shake_time_passed = 0
	while self.captive_shake_stat and self.captive_shake_stat[captive_num] do
		shake_time_passed = shake_time_passed + unity_class.time.deltaTime

		if shake_time_passed > 0.8 then
			shake_time_passed = 0
			character_util.shake(self.captives[captive_num], 0.05, 0.3)
		end

		coroutine.yield()
	end

end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
