local function create_data(quest_marker_key, quest_id, is_story, control_data)
	return {
		quest_marker_key = quest_marker_key,
		quest_id = quest_id,
		is_story = is_story,
		control_data = control_data
	}
end

-- 캐릭터 데이터 생성
local function create_character_data(character_name)
	return {
		type = 'character',
		name = character_name
	}
end

-- FieldObject 데이터 생성
local function create_fo_data(fo_name)
	return {
		type = 'fo',
		name = fo_name
	}
end

-- Field Marker 데이터 생성
local function create_marker_data(marker_name)
	return {
		type = 'marker',
		name = marker_name
	}
end

-- 아무것도 없는 (타겟 없는) 데이터 생성
local function create_none_data()
	return {
		type = 'none',
		name = nil,
	}
end

return {
	shortstory_mermaid = {
		main_quest = create_data('main_quest', 7001501, true, {
			main_field = create_fo_data('s8_exit_inner_1'),
			in_cave = create_fo_data('s8_exit_inner_2'),
			hana_past = create_none_data()
		}),
	},
	civilwar_1 = {
		main_quest = create_data('main_quest', 357, true, {
			main_field = create_character_data('demon_queen'),
			guardian_tent = create_fo_data('tent_outer_1'),
			friends_tent = create_fo_data('tent_outer_2'),
			demon_queen_tent = create_fo_data('tent_outer_3'),
			neo_federation_tent = create_fo_data('neo_federation_tent_outer_1'),
			demon_shire_tent = create_fo_data('demon_shire_tent_outer_1'),
			saul_tent = create_fo_data('saul_tent_outer_1'),
			temple_field = create_fo_data('sub_sm_inner_2')
		}),
	},
	civilwar_2 = {
		main_quest = create_data('main_quest', 357, true, {
			main_field = create_fo_data('tent_inner'),
			tent = create_character_data('demon_queen')
		}),
		death_flag = create_data('death_flag', 377, false, {
			main_field = create_fo_data('death_flag_camera_item'),
			tent = create_fo_data('tent_outer')
		}),
	},
	civilwar_3 = {
		main_quest = create_data('main_quest', 357, true, {
			main_field = create_fo_data('s16_exit_inner_1'),
			in_market = create_fo_data('s16_exit_inner_2'),
		}),
		mind_reading_sub_quest = create_data('mind_reading_sub_quest', 365, false, {
			main_field = create_fo_data('s16_exit_inner_1'),
			in_market = create_fo_data('s16_exit_inner_2'),
		}),
	},
	civilwar_4 = {
		main_quest = create_data('main_quest', 357, true, {
			main_field = create_fo_data('exit_lab_in'),
			in_lab = create_fo_data('exit_lab_out'),
			in_market = create_none_data(),
			in_entrapment_field = create_none_data(),
		}),
		demon_engineer_sub_quest = create_data('demon_engineer_sub_quest', 363, false, {
			main_field = create_fo_data('exit_lab_in'),
			in_lab = create_fo_data('exit_lab_out'),
			in_market = create_none_data(),
			in_entrapment_field = create_none_data(),
		}),
		entrapment_sub_quest = create_data('entrapment_sub_quest', 368, false, {
			main_field = create_fo_data('exit_lab_in'),
			in_lab = create_fo_data('exit_lab_out'),
			in_market = create_none_data(),
			in_entrapment_field = create_none_data(),
		})
	},
	civilwar_6 = {
		main_quest = create_data('main_quest', 357, true, {
			main_field = create_none_data(),
		}),
	},
	civilwar_substage_demonshire = {
		main_quest = create_data('main_quest', 371, true, {
			main_field = create_character_data('sheep_girl'),
		}),
	},
	shortstory_shuran = {
		main_quest = create_data('main_quest', 7001601, true, {
			main_field = create_fo_data('lion_cave_entrance'),
			in_lion_cave = create_fo_data('exit_lion_cave_out'),
		}),
	},
	nightmare_lilithtower_1 = {
		main_quest = create_data('main_quest', 380, true, {
			main_field = create_fo_data('office_inner'),
			office_field = create_marker_data('s3_align'),
			scent_event_field = create_fo_data('scent_room_outer'),
		}),
	},
	nightmare_lilithtower_3 = {
		main_quest = create_data('main_quest', 380, true, {
			first_floor = create_fo_data('elevator_first_door'),
			second_floor = create_marker_data('s5_main_marker_pos'),
			elevator_inner = create_fo_data('elevator_inner_door'),
		}),
		sub_missing_child = create_data('sub_missing_child', 381, false, {
			first_floor = create_character_data('missing_child_mother'),
			second_floor = create_fo_data('elevator_second_door'),
			machine_room = create_fo_data('boller_emergency_exit'),
			elevator_inner = create_none_data(),
		}),
	},
	nightmare_lilithtower_5 = {
		main_quest = create_data('main_quest', 380, true, {
			main_field = create_character_data('neo_federation_shifty'),
			lop_cam_background_deactive_zone = create_fo_data('bar_outer_exit'),
			sewerage_field = create_fo_data('ladder_left')
		}),
	},
	laboseworld_2 = {
		main_quest = create_data('main_quest', 386, true, {
			main_field = create_character_data('demon_queen'),
		}),
	},
	laboseworld_5 = {
		main_quest = create_data('main_quest', 386, true, {
			main_field = create_fo_data('other_world_entrance_in'),
		}),
	},
	shortstory_slime = {
		main_quest = create_data('main_quest', 7001701, true, {
			main_field = create_fo_data('main_s1_exit_inner'),
			demonworld_field = create_fo_data('main_s1_exit_inner_2'),
			police_field = create_fo_data('police_office_out_exit'),
			convenience_store = create_fo_data('convenience_store_out_exit'),
			pizza_store = create_fo_data('pizza_store_out_exit'),
			potion_house = create_fo_data('potion_building_exit'),
			guest_house_lv_1 = create_fo_data('guest_house_1_exit'),
			guest_house_lv_2 = create_fo_data('guest_house_2_exit'),
			guest_house_lv_3 = create_fo_data('guest_house_3_exit'),
			onigirl_minigame_field = create_none_data(),
		}),
		cupids_arrow = create_data('cupids_arrow', 7001709, false, {
			main_field = create_fo_data('main_s1_exit_inner'),
			demonworld_field = create_fo_data('main_s1_exit_inner_2'),
			police_field = create_fo_data('police_office_out_exit'),
			convenience_store = create_fo_data('convenience_store_out_exit'),
			pizza_store = create_fo_data('pizza_store_out_exit'),
			potion_house = create_fo_data('potion_building_exit'),
			guest_house_lv_1 = create_fo_data('guest_house_1_exit'),
			guest_house_lv_2 = create_fo_data('guest_house_2_exit'),
			guest_house_lv_3 = create_fo_data('guest_house_3_exit'),
			onigirl_minigame_field = create_none_data(),
		})
	},

	nightmare_demonshire_1 = {
		main_quest = create_data('main_quest', 406, true, {
			main_field = create_fo_data('office_in'),
			maid_cafe_field = create_fo_data('maid_cafe_exit_2'),
			goverment_building_field = create_fo_data('office_out'),
		}),
		agenda_paper_1 = create_data('agenda_paper_1', 406, true, {
			main_field = create_fo_data('office_in'),
			maid_cafe_field = create_fo_data('maid_cafe_exit_2'),
			goverment_building_field = create_fo_data('office_out'),
		}),
		agenda_paper_2 = create_data('agenda_paper_2', 406, true, {
			main_field = create_fo_data('office_in'),
			maid_cafe_field = create_fo_data('maid_cafe_exit_2'),
			goverment_building_field = create_fo_data('office_out'),
		}),
		agenda_paper_3 = create_data('agenda_paper_3', 406, true, {
			main_field = create_fo_data('office_in'),
			maid_cafe_field = create_fo_data('maid_cafe_exit_2'),
			goverment_building_field = create_fo_data('office_out'),
		}),
		maid_cafe = create_data('maid_cafe', 407, false, {
			main_field = create_none_data(),
			maid_cafe_field = create_none_data(),
			goverment_building_field = create_none_data(),
		}),
	},
	nightmare_demonshire_2 = {
		main_quest = create_data('main_quest', 406, true, {
			main_field = create_none_data(),
			state_capital_field = create_none_data(),
		}),
		friendship = create_data('friendship', 408, false, {
			main_field = create_none_data(),
			state_capital_field = create_none_data(),
		}),
		comic_book_1 = create_data('comic_book_1', 406, true, {
			main_field = create_none_data(),
			state_capital_field = create_none_data(),
		}),
		comic_book_2 = create_data('comic_book_2', 406, true, {
			main_field = create_none_data(),
			state_capital_field = create_none_data(),
		}),
		comic_book_3 = create_data('comic_book_3', 406, true, {
			main_field = create_none_data(),
			state_capital_field = create_none_data(),
		}),
	},

	nightmare_demonshire_3 = {
		main_quest = create_data('main_quest', 406, true, {
			main_field = create_none_data(),
			state_capitol_field = create_none_data(),
		}),
		kaiba = create_data('kaiba', 410, false, {
			main_field = create_fo_data('gachapon'),
			state_capitol_field = create_fo_data('state_capital_outer'),
		}),
	},

	nightmare_demonshire_4 = {
		main_quest = create_data('main_quest', 406, true, {
		}),
		palworld = create_data('palworld', 411, false, {
		})
	},

	nightmare_demonshire_5 = {
		main_quest = create_data('main_quest', 406, true, {
			main_field = create_fo_data('pyramid_exit_inner'),
			in_pyramid = create_fo_data('elevator_exit_inner'),
			pyraimid_stair = create_marker_data('pyramid_stair_pos'),
		}),
	},

	pixyworld_3 = {
		main_quest = create_data('main_quest', 412, true, {
			main_field = create_none_data(),
		}),
		sub_alexander = create_data('sub_alexander', 425, false, {
			main_field = create_none_data(),
		}),
	},
	pixyworld_4 = {
		main_quest = create_data('main_quest', 412, true, {
			main_field = create_none_data(),
			cave_field = create_none_data(),
		}),
	},
	pixyworld_5 = {
		main_quest = create_data('main_quest', 412, true, {
			main_field_1 = create_fo_data('exit_a_1'),
			main_field_2 = create_fo_data('exit_a_2'),
			doodle_jump_field = create_none_data(),
			doodle_jump_hard_field = create_fo_data('exit_b_1'),
		}),
	},
	pixyworld_6 = {
		main_quest = create_data('main_quest', 412, true, {
			main_field = create_marker_data('s21_pixy_chief_pos'),
		}),
	},
	pw_sub_east = {
		sub_eastworld = create_data('sub_eastworld', 428, true, {
			main_field = create_none_data(),
			ruins_field = create_none_data(),
		})
	},

	shortstory_milkyway = {
		main_quest = create_data('main_quest', 7001801, true, {
			day_field = create_none_data(),
			night_field = create_none_data(),
			room_a_field = create_fo_data('room_a_outer_1'),
			room_b_field = create_fo_data('room_b_outer_1'),
			room_c_field = create_fo_data('room_c_outer_1'),
			tavern_field = create_fo_data('pub_outer_1'),
		}),

		s6_firework = create_data('main_quest_1', 7001801, true, {
			day_field = create_none_data(),
			night_field = create_none_data(),
		}),

		s6_concert = create_data('main_quest_2', 7001801, true, {
			day_field = create_none_data(),
			night_field = create_none_data(),
		}),
	},

	--region NightmareQueenShip
	nightmare_queenship_1 = {
		main_quest = create_data('main_quest', 435, true, {
			main_field = create_none_data(),
			bar_field = create_fo_data('exit_inner_2'),
			convenience_store_field = create_fo_data('exit_inner_1'),
			neo_leader_field_1 = create_fo_data('s3_exit_inner_1'),
			neo_leader_field_2 = create_none_data(),
		}),
		suspicious_quest = create_data('suspicious_quest', 439, false, {
			main_field = create_none_data(),
			bar_field = create_fo_data('exit_inner_2'),
			convenience_store_field = create_fo_data('exit_inner_1'),
			neo_leader_field_1 = create_fo_data('s3_exit_inner_1'),
			neo_leader_field_2 = create_fo_data('exit_inner_6'),
		}),
	},

	nightmare_queenship_3 = {
		main_quest = create_data('main_quest', 435, true, {
			main_field = create_none_data(),
			right_field = create_none_data(),
			left_field = create_none_data(),
			down_field = create_none_data()
		}),
	},

	nightmare_queenship_4 = {
		main_quest = create_data('main_quest', 435, true, {
			main_field_1 = create_none_data(),
			main_field_2 = create_none_data(),
			secret_field = create_fo_data('sub_secret_exit_outer'),
		}),
	},

	--endregion NightmareQueenShip

	--region DreamVillage

	dreamvillage_1 = {
		main_quest = create_data('main_quest', 441, true, {
			main_field_1 = create_none_data(),
			main_field_2 = create_none_data(),
			secret_field = create_none_data(),
			cave = create_none_data(),
			forest = create_none_data(),
			house_in = create_none_data(),
		})
	},

	dreamvillage_2 = {
		main_quest = create_data('main_quest', 441, true, {
			main_field = create_none_data(),
			library_field = create_none_data(),
			library_way_field = create_none_data(),
			cave_field = create_none_data(),
			room_field = create_none_data(),
			infinite_field = create_none_data(),
		}),
		shadow_house = create_data('shadow_house', 443, false, {
			main_field = create_none_data(),
			library_field = create_none_data(),
			library_way_field = create_none_data(),
			cave_field = create_none_data(),
			room_field = create_none_data(),
			infinite_field = create_none_data(),
		})
	},

	dreamvillage_3 = {
		main_quest = create_data('main_quest', 441, true, {
			village_field = create_none_data(),
			cave = create_none_data(),
			forest = create_none_data(),
			house = create_fo_data('house_exit'),
		}),
		main_quest_1 = create_data('main_quest', 441, true, {
			village_field = create_fo_data('exit_2_1'),
			cave = create_none_data(),
			forest = create_fo_data('exit_3_1'),
			house = create_fo_data('house_exit'),
		})
	},

	dreamvillage_4 = {
		main_quest = create_data('main_quest', 441, true, {
			hotel_inside = create_none_data(),
			village = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			secret_area = create_none_data(),
			cave = create_fo_data('cave_exit'),
			restaurant = create_fo_data('restaurant_exit'),
			sub_gt_maze = create_fo_data('rin_forest_exit'),
		}),

		bookcase_1 = create_data('bookcase_1', 441, true, {
			hotel_inside = create_none_data(),
			village = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			cave = create_fo_data('cave_exit'),
			restaurant = create_fo_data('restaurant_exit'),
			sub_gt_maze = create_fo_data('rin_forest_exit'),
		}),
		bookcase_2 = create_data('bookcase_2', 441, true, {
			hotel_inside = create_none_data(),
			village = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			cave = create_fo_data('cave_exit'),
			restaurant = create_fo_data('restaurant_exit'),
			sub_gt_maze = create_fo_data('rin_forest_exit'),
		}),
		bookcase_3 = create_data('bookcase_3', 441, true, {
			hotel_inside = create_none_data(),
			village = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			cave = create_fo_data('cave_exit'),
			restaurant = create_fo_data('restaurant_exit'),
			sub_gt_maze = create_fo_data('rin_forest_exit'),
		}),

		sub_grain_tea_2 = create_data('sub_grain_tea_2', 454, false, {
			village = create_fo_data('restaurant_enter'),
			restaurant = create_none_data(),
			hotel_inside = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			secret_area = create_none_data(),
			cave = create_none_data(),
		}),
		sub_grain_tea_3 = create_data('sub_grain_tea_3', 454, false, {
			village = create_fo_data('restaurant_enter'),
			sub_gt_maze = create_none_data(),
			restaurant = create_none_data(),
			hotel_inside = create_none_data(),
			forest = create_none_data(),
			soulkeeper_house = create_none_data(),
			secret_area = create_none_data(),
			cave = create_none_data(),
		})
	},

	dreamvillage_5 = {
		main_quest_1 = create_data('main_quest_1', 441, true, {
			main_field = create_none_data(),
		}),
		main_quest_2 = create_data('main_quest_2', 441, true, {
			main_field = create_none_data(),
		}),
		main_quest_3 = create_data('main_quest_3', 441, true, {
			main_field = create_none_data(),
		})
	},

	dreamvillage_6 = {
		main_quest = create_data('main_quest', 441, true, {
			village_field = create_none_data(),
			twins_younger_field = create_fo_data('forest_to_village_exit'),
			cave_field = create_fo_data('cave_to_village_exit')
		})
	},

	dv_sub_cave = {
		sub_sealed_cave = create_data('sub_sealed_cave', 450, true, {
			main_field = create_none_data(),
		})
	},

	substage_20_1 = {
		main_quest = create_data('main_quest', 447, true, {
			main_field = create_none_data(),
			tunnel_field = create_none_data(),
			storage_field = create_none_data(),
		}),
	},

	substage_20_2 = {
		main_quest = create_data('main_quest', 442, true, {
			main_field = create_none_data(),
		}),
		main_quest_1 = create_data('main_quest_1', 442, true, {
			main_field = create_fo_data('exit_inner_1_1'),
			activity_field = create_none_data(),
			--activity_field = create_fo_data('exit_inner_1_2'),
		}),
		main_quest_2 = create_data('main_quest_2', 442, true, {
			main_field = create_none_data(),
			activity_field = create_fo_data('exit_inner_2_1'),
			--activity_field = create_fo_data('exit_inner_1_2'),
		}),
	},

	--endregion DreamVillage

	--region ShortStoryFrieren
	shortstory_frieren = {
		main_quest = create_data('main_quest', 7001901, true, {
			main_field = create_none_data(),
			held_house = create_fo_data('held_house_exit'),
			dungeon_entrance_field = create_fo_data('dungeon_entrance_to_village_exit'),
			izakaya_field = create_fo_data('izakaya_exit'),
			dessert_shop_field = create_fo_data('dessert_shop_exit'),
			dessert_shop_storage_field = create_fo_data('dessert_shop_storage_exit'),
			magic_tool_shop_field = create_fo_data('magic_tool_store_outer'),
		}),
		main_desert_shop = create_data('main_desert_shop', 7001905, true, {
			main_field = create_fo_data('dessert_shop_interactable_exit'),
			held_house = create_fo_data('held_house_exit'),
			dungeon_entrance_field = create_fo_data('dungeon_entrance_to_village_exit'),
			izakaya_field = create_fo_data('izakaya_exit'),
			dessert_shop_field = create_fo_data('dessert_shop_storage_entracne'),
			dessert_shop_storage_field = create_fo_data('dessert_shop_storage_exit'),
			magic_tool_shop_field = create_fo_data('magic_tool_store_outer'),
		}),
		main_magic_tool_shop = create_data('main_magic_tool_shop', 7001908, true, {
			main_field = create_fo_data('magic_tool_store_inner'),
			held_house = create_fo_data('held_house_exit'),
			dungeon_entrance_field = create_fo_data('dungeon_entrance_to_village_exit'),
			izakaya_field = create_fo_data('izakaya_table'),
			dessert_shop_field = create_fo_data('dessert_shop_exit'),
			dessert_shop_storage_field = create_fo_data('dessert_shop_storage_exit'),
		}),
		sub_quest_elf = create_data('sub_quest_elf', 7001909, false, {
			main_field = create_none_data(),
			held_house = create_none_data(),
			dungeon_entrance_field = create_none_data(),
			izakaya_field = create_none_data(),
			dessert_shop_field = create_none_data(),
			dessert_shop_storage_field = create_none_data(),
			magic_tool_shop_field = create_none_data(),
		}),
	},
	--endregion ShortStoryFrieren
}
