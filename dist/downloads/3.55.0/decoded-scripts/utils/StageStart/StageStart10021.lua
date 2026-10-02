return {
	-- marker_key = 마커 키
	-- direction = 출력 방향, 있으면 마커 방향보더 우선 함
	-- position = 출력 포지션, 마커 없이 따로 포지션 지정할때 사용
	-- directional_stage_entry = 스테이지 시작 연출을 실행할 것인지 여부
	-- play_stage_music = field BGM을 재생할 것인지 여부
	-- directional_stage_entry, play_stage_music 수치는 없으면 기본 true
	waterworld_1 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'left' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 's3_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},

	waterworld_2 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'left' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[3] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[5] = { marker_key = 's6_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[6] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[7] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
		},
	},

	waterworld_3 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'left' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[8] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[9] = { marker_key = 'default_start', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[10] = { marker_key = 'skip', direction = 'left', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
		},
	},

	waterworld_4 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[11] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[12] = { marker_key = 's13_start_pos', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[13] = { marker_key = 's14_start_pos', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
		},
	},

	waterworld_5 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[14] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[15] = { marker_key = 's16_start_pos', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[16] = { marker_key = 's17_start_pos', direction = 'left', position = nil,
					 directional_stage_entry = true, play_stage_music = false },
		},
	},

	waterworld_6 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[17] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[18] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = true, play_stage_music = true },
			[19] = { marker_key = 's20_knight', direction = 'up', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[20] = { marker_key = 's20_knight', direction = 'up', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[21] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[22] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[23] = { marker_key = 'default_start', direction = 'right', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
			[24] = { marker_key = 'default_start', direction = 'up', position = nil,
					 directional_stage_entry = false, play_stage_music = false },
		},
	},

	substage_21_1 = {
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
			[4] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
		},
	},

	substage_21_2 = {
		-- 기본위치
		default_start = { marker_key = 'default_start', direction = 'right' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 'default_start', direction = 'right', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[2] = { marker_key = 's3_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[3] = { marker_key = 's4_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},
}
