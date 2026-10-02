return {
	-- 스테이지 이름
	civilwar_substage_demonshire = {
		-- 스파이크 이동 속도
		speed = 5,

		-- 스파이크 스팩 데이터
		spec = {
			-- 스위치의 핸들네임
			moving_wall_switch_1 = {
				-- 스파이크 필드 오브젝트의 핸들 네임
				--TODO: end_pos_marker_name와 갯수가 같아야함
				--TODO: 시작 좌표는 스파이크 필드 오브젝트의 좌표
				fo_name_list = { 'moving_wall_1_1', 'moving_wall_1_2', 'moving_wall_1_3', 'moving_wall_1_4' },
				-- 스파이크 필드오브젝트가 도착할 좌표의 마커 이름
				end_pos_marker_name = {
					'moving_wall_end_pos_1_1', 'moving_wall_end_pos_1_2',
					'moving_wall_end_pos_1_3', 'moving_wall_end_pos_1_4'
				},
			},
			moving_wall_switch_2 = {
				fo_name_list = { 'moving_wall_2_1', 'moving_wall_2_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_2_1', 'moving_wall_end_pos_2_2'
				},
			},
			moving_wall_switch_3 = {
				fo_name_list = { 'moving_wall_3_1', 'moving_wall_3_2', 'moving_wall_3_3', 'moving_wall_3_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_3_1', 'moving_wall_end_pos_3_2',
					'moving_wall_end_pos_3_3', 'moving_wall_end_pos_3_4'
				},
			},
			moving_wall_switch_4 = {
				fo_name_list = { 'moving_wall_4_1', 'moving_wall_4_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_4_1', 'moving_wall_end_pos_4_2'
				},
			},
			moving_wall_switch_5 = {
				fo_name_list = { 'moving_wall_5_1', 'moving_wall_5_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_5_1', 'moving_wall_end_pos_5_2',
				},
			},
			moving_wall_switch_6 = {
				fo_name_list = { 'moving_wall_6_1', 'moving_wall_6_2', 'moving_wall_6_3', 'moving_wall_6_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_6_1', 'moving_wall_end_pos_6_2',
					'moving_wall_end_pos_6_3', 'moving_wall_end_pos_6_4'
				},
			},
			moving_wall_switch_7 = {
				fo_name_list = { 'moving_wall_7_1', 'moving_wall_7_2', 'moving_wall_7_3', 'moving_wall_7_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_7_1', 'moving_wall_end_pos_7_2',
					'moving_wall_end_pos_7_3', 'moving_wall_end_pos_7_4'
				},
			},
			moving_wall_switch_8 = {
				fo_name_list = { 'moving_wall_8_1', 'moving_wall_8_2', 'moving_wall_8_3', 'moving_wall_8_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_8_1', 'moving_wall_end_pos_8_2',
					'moving_wall_end_pos_8_3', 'moving_wall_end_pos_8_4'
				},
			},
			moving_wall_switch_9 = {
				fo_name_list = { 'moving_wall_9_1', 'moving_wall_9_2', 'moving_wall_9_3', 'moving_wall_9_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_9_1', 'moving_wall_end_pos_9_2',
					'moving_wall_end_pos_9_3', 'moving_wall_end_pos_9_4'
				},
			},
			moving_wall_switch_10 = {
				fo_name_list = { 'moving_wall_10_1', 'moving_wall_10_2', 'moving_wall_10_3', 'moving_wall_10_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_10_1', 'moving_wall_end_pos_10_2',
					'moving_wall_end_pos_10_3', 'moving_wall_end_pos_10_4'
				},
			},
			moving_wall_switch_11 = {
				fo_name_list = { 'moving_wall_11_1', 'moving_wall_11_2', 'moving_wall_11_3', 'moving_wall_11_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_11_1', 'moving_wall_end_pos_11_2',
					'moving_wall_end_pos_11_3', 'moving_wall_end_pos_11_4'
				},
			},
			moving_wall_switch_12 = {
				fo_name_list = { 'moving_wall_12_1', 'moving_wall_12_2', 'moving_wall_12_3', 'moving_wall_12_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_12_1', 'moving_wall_end_pos_12_2',
					'moving_wall_end_pos_12_3', 'moving_wall_end_pos_12_4'
				},
			},
			moving_wall_switch_13 = {
				fo_name_list = { 'moving_wall_13_1', 'moving_wall_13_2', 'moving_wall_13_3', 'moving_wall_13_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_13_1', 'moving_wall_end_pos_13_2',
					'moving_wall_end_pos_13_3', 'moving_wall_end_pos_13_4'
				},
			},
			moving_wall_switch_14 = {
				fo_name_list = { 'moving_wall_14_1', 'moving_wall_14_2', 'moving_wall_14_3', 'moving_wall_14_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_14_1', 'moving_wall_end_pos_14_2',
					'moving_wall_end_pos_14_3', 'moving_wall_end_pos_14_4'
				},
			},
			moving_wall_switch_15 = {
				fo_name_list = { 'moving_wall_15_1', 'moving_wall_15_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_15_1', 'moving_wall_end_pos_15_2'
				},
			},
		}
	},
	nightmare_demonshire_4 = {
		-- 스파이크 이동 속도
		speed = 5,

		-- 스파이크 스팩 데이터
		spec = {
			-- 스위치의 핸들네임
			moving_wall_switch_1 = {
				-- 스파이크 필드 오브젝트의 핸들 네임
				--TODO: end_pos_marker_name와 갯수가 같아야함
				--TODO: 시작 좌표는 스파이크 필드 오브젝트의 좌표
				fo_name_list = { 'moving_wall_1_1', 'moving_wall_1_2', 'moving_wall_1_3', 'moving_wall_1_4' },
				-- 스파이크 필드오브젝트가 도착할 좌표의 마커 이름
				end_pos_marker_name = {
					'moving_wall_end_pos_1_1', 'moving_wall_end_pos_1_2',
					'moving_wall_end_pos_1_3', 'moving_wall_end_pos_1_4'
				},
			},
			moving_wall_switch_2 = {
				fo_name_list = { 'moving_wall_2_1', 'moving_wall_2_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_2_1', 'moving_wall_end_pos_2_2'
				},
			},
			moving_wall_switch_3 = {
				fo_name_list = { 'moving_wall_3_1', 'moving_wall_3_2', 'moving_wall_3_3', 'moving_wall_3_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_3_1', 'moving_wall_end_pos_3_2',
					'moving_wall_end_pos_3_3', 'moving_wall_end_pos_3_4'
				},
			},
			moving_wall_switch_4 = {
				fo_name_list = { 'moving_wall_5_1', 'moving_wall_5_2', 'moving_wall_6_3', 'moving_wall_6_4' },
				end_pos_marker_name = {
					'moving_wall_end_pos_5_1', 'moving_wall_end_pos_5_2', 'moving_wall_end_pos_6_3', 'moving_wall_end_pos_6_4'
				},

			},
			moving_wall_switch_5 = {
				fo_name_list = { 'moving_wall_4_1', 'moving_wall_4_2' },
				end_pos_marker_name = {
					'moving_wall_end_pos_4_1', 'moving_wall_end_pos_4_2',
				},
			},
			moving_wall_switch_6 = {
				fo_name_list = { 'moving_wall_4_3', 'moving_wall_4_4'},
				end_pos_marker_name = {
					'moving_wall_end_pos_4_3', 'moving_wall_end_pos_4_4'
				},
			},
			moving_wall_switch_7 = {
				fo_name_list = { 'moving_wall_6_1', 'moving_wall_6_2', 'moving_wall_7_1', 'moving_wall_7_2'},
				end_pos_marker_name = {
					'moving_wall_end_pos_6_1', 'moving_wall_end_pos_6_2', 'moving_wall_end_pos_7_1', 'moving_wall_end_pos_7_2'
				},
			},
		}
	}
}
