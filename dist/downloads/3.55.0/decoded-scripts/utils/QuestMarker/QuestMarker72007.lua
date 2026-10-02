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
	--region Carp_Girl
	memorial_carp_girl = {
		main_quest = create_data('main_quest', 7200107, true, {
			jar_world_field = create_none_data(),
			main_field = create_none_data(),
			s2_field = create_none_data(),
			peak_field = create_fo_data('peak_exit_a'),
			s8_boss_field = create_none_data(),
			third_waterfall_field = create_none_data(),
		}),
		main_quest_2 = create_data('main_quest_2', 7200107, true, {
			jar_world_field = create_none_data(),
			main_field = create_none_data(),
			s2_field = create_none_data(),
			peak_field = create_fo_data('peak_exit_a'),
			s8_boss_field = create_none_data(),
			third_waterfall_field = create_none_data(),
		}),
		main_quest_3 = create_data('main_quest_3', 7200107, true, {
			jar_world_field = create_none_data(),
			main_field = create_none_data(),
			s2_field = create_none_data(),
			peak_field = create_fo_data('peak_exit_a'),
			s8_boss_field = create_none_data(),
			third_waterfall_field = create_none_data(),
		}),
	},
	--endregion Carp_Girl
}
