local function create_data(quest_marker_key, quest_id, is_story, control_data)
	return {
		quest_marker_key = quest_marker_key,
		quest_id = quest_id,
		is_story = is_story,
		control_data = control_data
	}
end

-- 아무것도 없는 (타겟 없는) 데이터 생성
local function create_none_data()
	return {
		type = 'none',
		name = nil,
	}
end

local function create_fo_data(fo_name)
	return {
		type = 'fo',
		name = fo_name
	}
end

return {
	--region FireWorld
	fireworld_1 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_none_data()
		}),
		sub_tamagotchi = create_data('sub_tamagotchi', 489, false, {
			main_field = create_none_data()
		}),
		sub_dokkaebi = create_data('sub_dokkaebi', 483, false, {
			main_field = create_none_data()
		}),
	},
	fireworld_2 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_none_data(),
			conference_field = create_none_data(),
			house_1_field = create_none_data(),
			house_2_field = create_none_data(),
			house_3_field = create_none_data()
		}),
		sub_dokkaebi = create_data('sub_dokkaebi', 483, false, {
			main_field = create_none_data(),
			conference_field = create_none_data(),
			house_1_field = create_none_data(),
			house_2_field = create_none_data(),
			house_3_field = create_none_data()
		}),
	},
	fireworld_3 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_none_data()
		}),
		main_quest_2 = create_data('main_quest_2', 478, true, {
			main_field = create_none_data()
		}),
		main_quest_3 = create_data('main_quest_3', 478, true, {
			main_field = create_none_data()
		}),
		sub_layton = create_data('sub_layton', 482, false, {
			main_field = create_none_data()
		}),
		sub_dokkaebi = create_data('sub_dokkaebi', 483, false, {
			main_field = create_none_data(),
		}),
	},
	fireworld_4 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_none_data()
		}),
		sub_dokkaebi = create_data('sub_dokkaebi', 483, false, {
			main_field = create_none_data(),
		}),
		sub_oni_girl = create_data('sub_oni_girl', 484, false, {
			main_field = create_none_data(),
			race_field = create_none_data(),
		}),
		sub_hotspring = create_data('sub_hotspring', 480, false, {
			main_field = create_none_data(),
		}),
	},
	fireworld_5 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_fo_data('portal_inner_1'),
			sealing_post_field = create_fo_data('portal_outer_1'),
		}),
	},
	fireworld_6 = {
		main_quest = create_data('main_quest', 478, true, {
			main_field = create_none_data(),
			human_village_field = create_none_data(),
			harpy_village_field = create_none_data(),
			ending_field = create_none_data(),
		}),
	},
	substage_22_1 = {
		wyvern_quest = create_data('wyvern_quest', 481, true, {
			main_field = create_none_data(),
		}),
	},
	substage_22_2 = {
		hotspring_quest = create_data('hotspring_quest', 480, true, {
			main_field = create_none_data(),
			tunnel_field = create_none_data()
		}),
	},

	--endregion FireWorld
}
