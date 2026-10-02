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
	--region SquirrelGirl
	memorial_squirrel_girl = {
		main_quest = create_data('main_quest', 7200101, true, {
			forest_field = create_fo_data('exit_1_1'),
			teatan_field = create_fo_data('exit_4_1'),
			snow_field = create_fo_data('exit_5_1'),
			magic_school_field = create_fo_data('exit_3_2'),
			cave_field = create_fo_data('exit_6_2'),
			steampunk_field = create_none_data(),
			futurecastle_field_1 = create_none_data(),
			futurecastle_field_2 = create_fo_data('s5_exit'),
		}),

		nari_quest = create_data('nari_quest', 7200101, true, {
			forest_field = create_fo_data('exit_1_1'),
			teatan_field = create_fo_data('exit_4_1'),
			snow_field = create_fo_data('exit_5_1'),
			magic_school_field = create_fo_data('exit_3_2'),
			cave_field = create_fo_data('exit_6_2'),
		}),
	},

	--endregion Blossom
}
