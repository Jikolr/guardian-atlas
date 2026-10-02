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

return {
	--region NightmareQueenCastle
	nightmare_queencastle_1 = {
		main_quest = create_data('main_quest', 456, true, {
			main_field = create_none_data(),
			control_room = create_none_data()
		}),
	},

	nightmare_queencastle_2 = {
		main_quest = create_data('main_quest', 457, true, {
			main_field = create_none_data(),
		}),
		main_quest_1 = create_data('main_quest_1', 457, true, {
			main_field = create_none_data(),
		}),
		main_quest_2 = create_data('main_quest_2', 457, true, {
			main_field = create_none_data(),
		}),
		main_quest_3 = create_data('main_quest_3', 457, true, {
			main_field = create_none_data(),
		}),
	},

	nightmare_queencastle_3 = {
		main_quest = create_data('main_quest', 458, true, {
			main_field = create_none_data(),
		}),
	},

	nightmare_queencastle_4 = {
		main_quest = create_data('main_quest', 459, true, {
			main_field = create_none_data(),
		}),
	},

	nightmare_queencastle_5 = {
		main_quest = create_data('main_quest', 460, true, {
			main_field = create_none_data(),
		}),
	},

	nightmare_queencastle_6 = {
		main_quest = create_data('main_quest', 456, true, {
			main_field = create_none_data(),
			memory_field = create_none_data(),
			boss_field = create_none_data(),
		}),
	},
	--endregion
}
