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
	--region WaterWorld
	waterworld_1 = {
		main_quest = create_data('main_quest', 465, true, {
			main_field = create_none_data(),
			sub_field = create_none_data(),
		}),

		dave_the_diver_sub_quest = create_data('dtd_sub_quest', 470, false, {
			main_field = create_none_data(),
			sub_field = create_none_data(),
		}),
	},

	waterworld_2 = {
		main_quest = create_data('main_quest', 465, true, {
			main_field = create_none_data(),
			dock_field = create_fo_data('exit_inner_1'),
			ticket_office_field = create_fo_data('exit_inner_5'),
			waiting_room_field = create_fo_data('exit_inner_6'),
			casino_1f_field = create_fo_data('exit_inner_8'),
			casino_2f_field = create_fo_data('exit_inner_10')
		}),
		sub_kaiji_quest = create_data('sub_kaiji_quest', 473, false, {
			main_field = create_none_data(),
			dock_field = create_none_data(),
			ticket_office_field = create_none_data(),
			waiting_room_field =create_none_data(),
			casino_1f_field = create_fo_data('exit_inner_8'),
			casino_2f_field = create_fo_data('exit_inner_10')
		}),
		s4_fishman_quest_1 = create_data('s4_fishman_quest_1', 465, true, {
			main_field = create_none_data(),
			dock_field = create_none_data(),
		}),
		s4_fishman_quest_2 = create_data('s4_fishman_quest_2', 465, true, {
			main_field = create_none_data(),
			dock_field = create_none_data(),
		}),
		s4_fishman_quest_3 = create_data('s4_fishman_quest_3', 465, true, {
			main_field = create_none_data(),
			dock_field = create_none_data(),
		}),
	},

	waterworld_3 = {
		main_quest = create_data('main_quest', 465, true, {
			main_field = create_fo_data('field_exit'),
			historic_site_field = create_none_data(),
		}),
	},

	waterworld_4 = {
		main_quest = create_data('main_quest', 465, true, {
			main_field = create_none_data(),
			sub_field = create_none_data(),
			bar_field = create_fo_data('exit_bar'),
			brief_field = create_none_data(),
		}),
		wrestler_quest = create_data('wrestler_quest', 466, true, {
			main_field = create_fo_data('exit_city_4'),
			sub_field = create_fo_data('entrance_bar'),
			bar_field = create_fo_data(),
			brief_field = create_none_data(),
		}),
		companion_boy_quest = create_data('companion_boy_quest', 468, true, {
			main_field = create_none_data(),
			sub_field = create_fo_data('exit_city_1'),
			bar_field = create_fo_data('exit_bar'),
			brief_field = create_none_data(),
		}),
		mermaid_spy_quest = create_data('mermaid_spy_quest', 471, true, {
			main_field = create_none_data(),
			sub_field = create_fo_data('exit_city_3'),
			bar_field = create_fo_data('exit_bar'),
			brief_field = create_none_data(),
		}),
	},

	substage_21_1 = {
		angel_fruits_quest = create_data('angel_fruits_quest', 476, false, {
			main_field = create_none_data(),
			sub_field = create_fo_data('waitring_room_entrance'),
		})
	},

	substage_21_2 = {
		squid_game_quest = create_data('squid_game_quest', 477, true, {
			main_field = create_fo_data('exit_1'),
			squid_field_1 = create_none_data(),
			squid_field_2 = create_none_data(),
		})
	},
	--endregion WaterWorld
}
