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
	shortstory_battleball = {
		main_quest = create_data('main_quest', 7002001, true, {
			main_field = create_fo_data('stadium_inner_1'),
			ball_park_inside =create_fo_data('stadium_outer_1'),
		}),
		main_quest_2 = create_data('main_quest_2', 7002001, true, {
			main_field = create_fo_data('stadium_inner_1'),
			ball_park_inside = create_fo_data('stadium_outer_1'),
		}),
		main_quest_5 = create_data('main_quest_5', 7002001, true, {
			main_field = create_none_data(),
			ball_park_inside = create_none_data(),
		}),
		sub_quest_bat_sign = create_data('sub_quest_bat_sign', 7002002, false, {
			main_field = create_fo_data('stadium_inner_1'),
			ball_park_inside = create_fo_data('stadium_outer_1'),
		}),

	},
}
