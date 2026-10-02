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
	--region Blossom
	blossom_1 = {
		main_quest = create_data('main_quest', 60065, true, {
			main_field = create_none_data(),
			boss_field = create_fo_data('s3_chasm_hole_8'),
			ground_field = create_none_data(),
			tavern_field = create_none_data(),
			bob_chasm_field = create_fo_data('s3_chasm_hole_4'),
			student_bad_chasm_field = create_fo_data('s3_chasm_hole_5'),
			hyper_chasm_field = create_fo_data('s3_chasm_hole_6'),
		}),
		main_quest_2 = create_data('main_quest_2', 60065, true, {
			main_field = create_none_data(),
			boss_field = create_fo_data('s3_chasm_hole_8'),
			ground_field = create_none_data(),
			tavern_field = create_none_data(),
			bob_chasm_field = create_fo_data('s3_chasm_hole_4'),
			student_bad_chasm_field = create_fo_data('s3_chasm_hole_5'),
			hyper_chasm_field = create_fo_data('s3_chasm_hole_6'),
		}),
		main_quest_3 = create_data('main_quest_3', 60065, true, {
			main_field = create_none_data(),
			boss_field = create_fo_data('s3_chasm_hole_8'),
			ground_field = create_none_data(),
			tavern_field = create_none_data(),
			bob_chasm_field = create_fo_data('s3_chasm_hole_4'),
			student_bad_chasm_field = create_fo_data('s3_chasm_hole_5'),
			hyper_chasm_field = create_fo_data('s3_chasm_hole_6'),
		}),
	},

	blossom_2 = {
		main_quest = create_data('main_quest', 60065, true, {
			main_field = create_none_data(),
			portal_area_field = create_none_data(),
			possession_field = create_none_data(),
			crack_field = create_none_data()
		}),
	},
	--endregion Blossom
}
