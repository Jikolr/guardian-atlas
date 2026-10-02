-- BGM 데이터 생성
-- BGM 데이터의 경우에는 string 값으로, sfx 데이터의 경우 table 형태로 만들어서 저장

local function create_field_data(
		zone_data,
		state,
		mix_duration,
		volume
)
	return {
		zone_data = zone_data,
		state = state,
		mix_duration = mix_duration,
		volume = volume,
	}
end

-- zone영역 안에 들어왔을 때 bgm_data 생성
local function create_zone_in_bgm_data(bgm_name, quest_id, progress, is_before_progress)
	return {
		zone_in_type = 'bgm',
		zone_in_bgm_name = bgm_name,
		zone_in_quest_data = {
			quest_id = quest_id,
			progress = progress,
			is_before_progress = is_before_progress
		}
	}
end

-- zone영역에서 나갔을 때 bgm_data 데이터 생성
local function create_zone_out_bgm_data(bgm_name, quest_id, progress, is_before_progress)
	return {
		zone_out_type = 'bgm',
		zone_out_bgm_name = bgm_name,
		zone_out_quest_data = {
			quest_id = quest_id,
			progress = progress,
			is_before_progress = is_before_progress
		}
	}
end

--zone영역 안에 들어왔을 때 sfx 생성
local function create_zone_in_sfx_data(sfx_name, quest_id, progress, is_before_progress)
	return {
		zone_in_type = 'sfx',
		zone_in_bgm_name = sfx_name,
		zone_in_quest_data = {
			quest_id = quest_id,
			progress = progress,
			is_before_progress = is_before_progress
		}
	}
end

--zone영역에서 나갔을 때 sfx 생성
local function create_zone_out_sfx_data(sfx_name, quest_id, progress, is_before_progress)
	return {
		zone_out_type = 'sfx',
		zone_out_bgm_name = sfx_name,
		zone_out_quest_data = {
			quest_id = quest_id,
			progress = progress,
			is_before_progress = is_before_progress
		}
	}
end

return {
	test_stage = {
		zone_name_1 = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_milkyway/audio:bgm_milkyway_night', {
				quest_id = 123,
				progress = 99,
			}),
			create_zone_out_bgm_data('ondemand/short_story_milkyway/audio:bgm_milkyway_day')
		},
				'field',
				0.75,
				1),
		zone_name_2 = create_field_data(
				{ create_zone_in_bgm_data('ondemand/short_story_milkyway/audio:bgm_milkyway_cafe') }
		),
		zone_name_3 = create_field_data(
				{
					create_zone_in_sfx_data('01_bad_fairy_01'),
					create_zone_out_bgm_data('ondemand/short_story_milkyway/audio:bgm_milkyway_day')
				},
				'field',
				1,
				1)
	},

	--region NightmareQueenship
	nightmare_queenship_1 = {
		convenience_store_field = create_field_data({
			create_zone_in_bgm_data('ondemand/v2_15_demonworld/audio:bgm_demonworld_store'),
		},
				'field',
				1,
				1),
		bar_field = create_field_data({
			create_zone_in_bgm_data('bgm_restaurant'),
		},
				'field',
				1,
				1),
		lab_field = create_field_data({
			create_zone_in_bgm_data('ondemand/v2_49_queenship/audio:bgm_queenship_chamber'),
		},
				'field',
				1,
				1),
		main_field = create_field_data({
			create_zone_in_bgm_data('ondemand/v2_15_demonworld/audio:bgm_demonworld_main'),
		},
				'field',
				1,
				1),
	},
	--endregion NightmareQueenship


	--region ShortStoryFrieren
	shortstory_frieren = {
		held_house_entrance_zone = create_field_data({
			create_zone_in_bgm_data('bgm_frieren_event_02'),
			create_zone_out_bgm_data('ondemand/short_story_frieren/audio:bgm_frieren_field')
		},
				'field',
				2,
				1),
	},
	--endregion ShortStoryFrieren

	--region NightmareQueenCastle
	nightmare_queencastle_1 = {
		control_room = create_field_data({
			create_zone_in_bgm_data('ondemand/v2_65_queencastle/audio:bgm_queencastle_hub'),
		}, 'field', 1, 1),

		main_field = create_field_data({
			create_zone_in_bgm_data('ondemand/v3_18_nightmare_queencastle/audio:bgm_queencastle_nightmare_main'),
		}, 'field', 1, 1),
	},

	--endregion NightmareQueenCastle

	--region ShortStoryBattleball
	shortstory_battleball = {
		main_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_battleball/audio:bgm_battleball_beach'),
		}, 'field', 1, 1),

		ball_park_inside = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_battleball/audio:bgm_battleball_lobby'),
		}, 'field', 1, 1),
	},
	--endregion ShortStoryBattleball

	--region MemorialSquirrelGirl
	memorial_squirrel_girl = {
		forest_field = create_field_data({
			create_zone_in_bgm_data('bgm_forest_dark'),
		}, 'field', 1, 1),

		forest_puzzle_field = create_field_data({
			create_zone_in_bgm_data('bgm_forest_dark'),
		}, 'field', 1, 1),

		teatan_field = create_field_data({
			create_zone_in_bgm_data('bgm_teatans_main'),
		}, 'field', 1, 1),

		snow_field = create_field_data({
			create_zone_in_bgm_data('bgm_shivermore_main'),
		}, 'field', 1, 1),

		magic_school_field = create_field_data({
			create_zone_in_bgm_data('bgm_magic_school_main'),
		}, 'field', 1, 1),

		cave_field = create_field_data({
			create_zone_in_bgm_data('bgm_cave_main'),
		}, 'field', 1, 1),

		steampunk_field = create_field_data({
			create_zone_in_bgm_data('bgm_steampunk_basement'),
		}, 'field', 1, 1),

		futurecastle_field_1 = create_field_data({
			create_zone_in_bgm_data('ondemand/memorial_squirrel_girl/audio:bgm_futurecastle2_dungeon'),
		}, 'field', 1, 1),

		futurecastle_field_2 = create_field_data({
			create_zone_in_bgm_data('ondemand/memorial_squirrel_girl/audio:bgm_futurecastle2_dungeon'),
		}, 'field', 1, 1),
	}
	--endregion MemorialSquirrelGirl
}
