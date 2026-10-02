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
	--region shortstory_noel
	shortstory_noel = {
		-- 전투 구역
		upper_bgm_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_noel/audio:bgm_noel_main_hard',
					7002201, 9, true) }),
		-- 아래층 구역
		main_field = create_field_data({
			create_zone_in_bgm_data('ondemand/short_story_noel/audio:bgm_noel_main_normal',
					7002201, 9, true) }),
		scientist_room = create_field_data({
			create_zone_in_sfx_data('01_amb_cave_01', 7002201, 9, true) },
				nil,
				1,
				0.3
		),
		scientist_room_cave = create_field_data({
			create_zone_in_sfx_data('01_amb_cave_01', 7002201, 9, true) },
				nil,
				0,
				0.3
		),
	},
	--endregion shortstory_noel
}
