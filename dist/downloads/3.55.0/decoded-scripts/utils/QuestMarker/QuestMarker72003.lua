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
	--region MagicalGirl
	memorial_magical_girl = {
		main_quest = create_data('main_quest', 7200103, true, {
			campus_square = create_none_data(),
			classroom_area_1 = create_none_data(),
			classroom_area_2 = create_none_data(),
			rooftop = create_none_data(),
		}),
		main_quest_2 = create_data('main_quest_2', 7200103, true, {
			campus_square = create_none_data(),
			classroom_area_1 = create_none_data(),
			classroom_area_2 = create_none_data(),
			rooftop = create_none_data(),
		}),
		sub_quest = create_data('sub_quest', 7200103, false, {
			campus_square = create_none_data(),
			classroom_area_1 = create_none_data(),
			classroom_area_2 = create_none_data(),
			rooftop = create_none_data(),
		}),
	},
	--endregion MagicalGirl
}
