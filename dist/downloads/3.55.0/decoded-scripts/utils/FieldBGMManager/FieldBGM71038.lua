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
	--region shortstory_clevatess
	shortstory_clevatess = {
		village_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_village')
		}),
		--inn_field = create_field_data({
		--	create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_village')
		--}),
		shortcut_field = create_field_data({
			create_zone_in_bgm_data('bgm_cave_main')
		}),
		forest_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_village')
		}),

		forest_b_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_forest')
		}),
		forest_b_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_forest')
		}),

		forest_c_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_forest')
		}),
		forest_c_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_forest')
		}),

		river_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_clevatess/audio:bgm_clevatess_underwater') }
		),
	},
	--endregion shortstory_clevatess
}
