return {
	-- marker_key = 마커 키
	-- direction = 출력 방향, 있으면 마커 방향보더 우선 함
	-- position = 출력 포지션, 마커 없이 따로 포지션 지정할때 사용
	-- directional_stage_entry = 스테이지 시작 연출을 실행할 것인지 여부
	-- play_stage_music = field BGM을 재생할 것인지 여부
	-- directional_stage_entry, play_stage_music 수치는 없으면 기본 true
	fireworld_1 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'left' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 's3_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},

	fireworld_2 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[3] = { marker_key = 's4_start_pos', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[4] = { marker_key = 's5_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[5] = { marker_key = 's6_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[6] = { marker_key = 's7_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[7] = { marker_key = 's8_start_pos', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[8] = { marker_key = 's7_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},

	fireworld_3 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[8] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[9] = { marker_key = 's9_field_lava_reset_1', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[10] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
		},
	},

	fireworld_4 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[11] = { marker_key = 's12_start', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[13] = { marker_key = 's14_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[14] = { marker_key = 's14_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[15] = { marker_key = 's16_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = true },
			[16] = { marker_key = 's17_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[17] = { marker_key = 's18_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[18] = { marker_key = 's19_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
		},
	},

	fireworld_5 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[19] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[20] = { marker_key = 's21_start_pos', direction = 'left', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[21] = { marker_key = 's21_start_pos', direction = 'left', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
		},
	},

	fireworld_6 = {
		-- 기본위치
		default_start = { marker_key = 's29_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[23] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[24] = { marker_key = 'default_start', direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[25] = { marker_key = 'default_start', direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[26] = { marker_key = 'default_start', direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[27] = { marker_key = 'default_start', direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[28] = { marker_key = nil, direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[29] = { marker_key = 's29_start', direction = 'left', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
		},
	},

	substage_22_1 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 's1_start_pos', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[3] = { marker_key = 's4_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[4] = { marker_key = 's5_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},

	substage_22_2 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[3] = { marker_key = 's4_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[5] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},
}
