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
	--region Thief
	memorial_thief = {
		main_quest = create_data('main_quest', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_wire = create_data('clue_wire', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_profile = create_data('clue_profile', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_controller = create_data('clue_controller', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_pill = create_data('clue_pill', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_records = create_data('clue_records', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_android = create_data('clue_android', 7200105, true, {
			main_field = create_fo_data('vent_in_interact_1'),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
		clue_piano = create_data('clue_piano', 7200105, true, {
			main_field = create_none_data(),
			lilith_room_field = create_none_data(),
			vent_field = create_fo_data('vent_out_interact_1'),
		}),
	},
	--endregion Thief
}
