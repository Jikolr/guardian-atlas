return {
	-- marker_key = 마커 키
	-- direction = 출력 방향, 있으면 마커 방향보더 우선 함
	-- position = 출력 포지션, 마커 없이 따로 포지션 지정할때 사용
	-- directional_stage_entry = 스테이지 시작 연출을 실행할 것인지 여부
	-- play_stage_music = field BGM을 재생할 것인지 여부
	-- directional_stage_entry, play_stage_music 수치는 없으면 기본 true
	shortstory_battleball = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[3] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = false },
			[5] = { marker_key = nil, direction = 'left', position = vector(127.5, 0, -5.5),
					directional_stage_entry = true, play_stage_music = true },
			[6] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[7] = { marker_key = 's8_intro_pos', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[8] = { marker_key = 's9_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[9] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[10] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[11] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[12] = { marker_key = nil, direction = 'right',
					 position = field_util.get_marker_pos('battleball_game_field_1') + vector(-2, 0, 1),
					 directional_stage_entry = false, play_stage_music = false },
			[13] = { marker_key = 's8_intro_pos', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[14] = { marker_key = 's8_intro_pos', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[15] = { marker_key = 's8_intro_pos', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
		},
	},
}
