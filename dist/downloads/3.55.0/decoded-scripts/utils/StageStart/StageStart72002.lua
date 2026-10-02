return {
	-- marker_key = 마커 키
	-- direction = 출력 방향, 있으면 마커 방향보더 우선 함
	-- position = 출력 포지션, 마커 없이 따로 포지션 지정할때 사용
	-- directional_stage_entry = 스테이지 시작 연출을 실행할 것인지 여부
	-- play_stage_music = field BGM을 재생할 것인지 여부
	-- directional_stage_entry, play_stage_music 수치는 없으면 기본 true
	memorial_bootcamp = {
		-- 기본위치
		default_start = { marker_key = 's3_s4_start', direction = 'left' },

		-- InnerProgress로 넣어야함 0부터 시작
		start_data_list = {
			[0] = { marker_key = 's1_start', direction = 'left', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[1] = { marker_key = 's2_beach_side_pos', direction = 'down', position = nil,
					directional_stage_entry = false, play_stage_music = false },
			[2] = { marker_key = 's3_s4_start', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[3] = { marker_key = 's3_s4_start', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[5] = { marker_key = 's6_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
			[6] = { marker_key = 's6_start_pos', direction = 'left', position = nil,
					directional_stage_entry = true, play_stage_music = true },
		},
	},
}
