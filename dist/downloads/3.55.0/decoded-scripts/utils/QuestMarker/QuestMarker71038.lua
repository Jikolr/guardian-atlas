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
	shortstory_clevatess = {
		main_quest = create_data('main_quest', 7002101, true, {
			village_field = create_none_data(),
			forest_field = create_fo_data('exit_forest_a'),
			forest_b_field = create_fo_data('exit_forest_b'),
			forest_c_field = create_fo_data('exit_forest_c'),
			inn_field = create_none_data(),
			puzzle_field = create_none_data(),
			river_field = create_none_data(),
			shortcut_field = create_none_data(),
			forest_short_out_field = create_fo_data('exit_shortcut_d'),
		}),
		main_quest_2 = create_data('main_quest_2', 7002101, true, {
			village_field = create_none_data(),
			forest_field = create_fo_data('exit_forest_a'),
			forest_b_field = create_fo_data('exit_forest_b'),
			forest_c_field = create_fo_data('exit_forest_c'),
			inn_field = create_none_data(),
			puzzle_field = create_none_data(),
			river_field = create_none_data(),
			shortcut_field = create_none_data(),
			forest_short_out_field = create_fo_data('exit_shortcut_d'),
		}),
		main_quest_3 = create_data('main_quest_3', 7002101, true, {
			village_field = create_none_data(),
			forest_field = create_fo_data('exit_forest_a'),
			forest_b_field = create_fo_data('exit_forest_b'),
			forest_c_field = create_fo_data('exit_forest_c'),
			inn_field = create_none_data(),
			puzzle_field = create_none_data(),
			river_field = create_none_data(),
			shortcut_field = create_none_data(),
			forest_short_out_field = create_fo_data('exit_shortcut_d'),
		}),
		main_quest_4 = create_data('main_quest_4', 7002101, true, {
			village_field = create_none_data(),
			forest_field = create_fo_data('exit_forest_a'),
			forest_b_field = create_fo_data('exit_forest_b'),
			forest_c_field = create_fo_data('exit_forest_c'),
			inn_field = create_none_data(),
			puzzle_field = create_none_data(),
			river_field = create_none_data(),
			shortcut_field = create_none_data(),
			forest_short_out_field = create_fo_data('exit_shortcut_d'),
		}),

	},
}
