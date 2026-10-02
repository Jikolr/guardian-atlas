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
	shortstory_noel = {
		main_quest = create_data('main_quest', 7002201, true, {
			main_field = create_none_data(),
			war_field = create_fo_data('village_in1'),
			fly_field = create_fo_data('village_in2'),
			ant_field = create_fo_data('s5_inner_2'),
			puzzle_down_field = create_none_data(),
			room_field_1 = create_fo_data('house_out1'),
			room_field_2 = create_fo_data('house_out2'),
			room_field_3 = create_fo_data('house_out3'),
			cave_field = create_none_data(),
		}),
		main_quest_2 = create_data('main_quest_2', 7002201, true, {
			main_field = create_none_data(),
			war_field = create_fo_data('village_in1'),
			fly_field = create_fo_data('village_in2'),
			ant_field = create_fo_data('s5_inner_2'),
			puzzle_down_field = create_none_data(),
			room_field_1 = create_fo_data('house_out1'),
			room_field_2 = create_fo_data('house_out2'),
			room_field_3 = create_fo_data('house_out3'),
		}),
		main_quest_3 = create_data('main_quest_3', 7002201, true, {
			main_field = create_none_data(),
			war_field = create_fo_data('village_in1'),
			fly_field = create_fo_data('village_in2'),
			ant_field = create_fo_data('s5_inner_2'),
			puzzle_down_field = create_none_data(),
			room_field_1 = create_fo_data('house_out1'),
			room_field_2 = create_fo_data('house_out2'),
			room_field_3 = create_fo_data('house_out3'),
		}),

		sub_bomb_bug = create_data('sub_bomb_bug', 7002203, false, {
			main_field = create_none_data(),
			war_field = create_fo_data('village_in1'),
			fly_field = create_fo_data('village_in2'),
			ant_field = create_fo_data('s5_inner_2'),
			puzzle_down_field = create_none_data(),
			room_field_1 = create_fo_data('house_out1'),
			room_field_2 = create_fo_data('house_out2'),
			room_field_3 = create_fo_data('house_out3'),
		}),

		sub_zootopia = create_data('sub_zootopia', 7002204, false, {
			war_field = create_fo_data('village_in1'),
			ant_field = create_fo_data('s5_inner_2'),
			mafia_field = create_none_data(),
			fly_field = create_none_data(),
			room_field_1 = create_fo_data('house_out1'),
			room_field_2 = create_fo_data('house_out2'),
			room_field_3 = create_fo_data('house_out3'),
		}),
	},
}
