--[[ 스테이지 데이터 정보
스테이지 이름 = {
	laser info에 여러 개의 레이저 쌍 정보를 입력해 줄 수 있음
	laser_info = {
		{
			chest_1 = {
				patrol_markers = {
					이동할 마커 이름을 순서대로 넣어 줌
				},
				velocity = 이동할 속도
			},
			chest_2 = {
				patrol_markers = {
					이동할 마커 이름을 순서대로 넣어 줌
				},
				velocity = 이동할 속도
			},
			damage_rate = 최대 채력에서 차지하는 비율 (1이 100%)
			laser_type = 레이저 색깔 (1 = 보라색, 2 = 파란색, 3 = 노란색)
		}
}
]]
return {
	tower_fire_52 = {
		laser_info = {
			{-- 튜토리얼 레이저(수평)
			chest_1 = { 
				patrol_markers = {
					'marker_1',
					'marker_2'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_3',
					'marker_4'
				},
				velocity = 3
			},
			damage_rate = 0.33,
			laser_type = 1
			},

			{-- 배틀존 1 레이저
			chest_1 = { 
				patrol_markers = {
					'marker_6',
					'marker_5'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_8',
					'marker_7'
				},
				velocity = 3
			},
			damage_rate = 0.33,
			laser_type = 1
			},

			{-- 배틀존 2 레이저
			chest_1 = { 
				patrol_markers = {
					'marker_9',
					'marker_11'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_10',
					'marker_12'
				},
				velocity = 3
			},
			damage_rate = 0.33,
			laser_type = 1
			},

			{-- 배틀존 3 레이저_1
			chest_1 = { 
				patrol_markers = {
					'marker_21',
					'marker_23'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_22',
					'marker_24'
				},
				velocity = 3
			},
			damage_rate = 0.33,
			laser_type = 1
			},

			{-- 배틀존 3 레이저_2
			chest_1 = { 
				patrol_markers = {
					'marker_13',
					'marker_14'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_15',
					'marker_16'
				},
				velocity = 3
			},
			damage_rate = 0.33,
			laser_type = 1
			},

			{-- 배틀존 4 레이저_1
			chest_1 = { 
				patrol_markers = {
					'marker_19',
					'marker_17',
					'marker_18',
					'marker_20'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_18',
					'marker_20',
					'marker_19',
					'marker_17'
				},
				velocity = 3
			},
			damage_rate = 0.25,
			laser_type = 1
			},
			{-- 배틀존 4 레이저_2
			chest_1 = { 
				patrol_markers = {
					'marker_20',
					'marker_19',
					'marker_17',
					'marker_18'
				},
				velocity = 3
			},
			chest_2 = {
				patrol_markers = {
					'marker_17',
					'marker_18',
					'marker_20',
					'marker_19'
				},
				velocity = 3
			},
			damage_rate = 0.25,
			laser_type = 1
			}
		}
	},

	herotower_summer_android_3 = {
			laser_info = {
				{-- 배틀존2, 레이저1
				chest_1 = { 
					patrol_markers = {
						'marker_1',
						'marker_3'
					},
					velocity = 3
				},
				chest_2 = {
					patrol_markers = {
						'marker_2',
						'marker_4'
					},
					velocity = 3
				},
				damage_rate = 0.25,
				laser_type = 1
				},

				{-- 배틀존2, 레이저2
				chest_1 = { 
					patrol_markers = {
						'marker_5',
						'marker_7'
					},
					velocity = 3
				},
				chest_2 = {
					patrol_markers = {
						'marker_6',
						'marker_8'
					},
					velocity = 3
				},
				damage_rate = 0.25,
				laser_type = 1
				},

				{-- 배틀존2, 레이저3
				chest_1 = { 
					patrol_markers = {
						'marker_9',
						'marker_11'
					},
					velocity = 3
				},
				chest_2 = {
					patrol_markers = {
						'marker_10',
						'marker_12'
					},
					velocity = 3
				},
				damage_rate = 0.25,
				laser_type = 1
				},

				{-- 배틀존1, 레이저4
				chest_1 = { 
					patrol_markers = {
						'marker_13'
					},
					velocity = 0
				},
				chest_2 = {
					patrol_markers = {
						'marker_14',
						'marker_15',
						'marker_16',
						'marker_17'
					},
					velocity = 6
				},
				damage_rate = 0.25,
				laser_type = 1
				},

				{-- 배틀존3, 레이저5
				chest_1 = { 
					patrol_markers = {
						'marker_18',
						'marker_20'
					},
					velocity = 3
				},
				chest_2 = {
					patrol_markers = {
						'marker_19',
						'marker_21'
					},
					velocity = 3
				},
				damage_rate = 0.2,
				laser_type = 3
				}
		}
	}
}