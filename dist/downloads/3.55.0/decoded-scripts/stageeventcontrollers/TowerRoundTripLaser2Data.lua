--[[ 스테이지 데이터 정보
스테이지 이름 = {
	laser info에 여러 개의 레이저 쌍 정보를 입력해 줄 수 있음
	laser_info = {
		{
			chest_1 = {
				patrol_infos = {
					{
						patrol_markers = {
							이동할 마커 이름을 순서대로 넣어 줌
						},
						duration = 패트롤 경로 지속 시간,
						velocity = 이동할 속도,
						stop_point = duratio 후 정지 위치,
						delay = stop_point에 머무는 시간,
						damage_rate = 최대 채력에서 차지하는 비율 (1이 100%)
						laser_type = 레이저 색깔 (1 = 보라색, 2 = 파란색, 3 = 노란색)
					}
				},
				dispose_effect = 비활성화시 이펙트
			},
		}
}
]]
return {
	tower_none_55 = {
		gimmick_owner = 'et_boss_erina_guild_fury',
		laser_info = {
			{-- 1set Laser(pink)
				chest_1 = {
					patrol_infos = {
						{
							patrol_markers = {
								'marker_1',
								'marker_2'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 5,
							damage_rate = 0.4,
							laser_type = 1
						},
						{
							patrol_markers = {
								'marker_1',
								'marker_2',
								'marker_5',
								'marker_6'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 8,
							damage_rate = 0.15,
							laser_type = 2
						},
						{
							patrol_markers = {
								'marker_9'
							},
							stop_point = 'marker_1',
							delay = 2,
							duration = 0.1,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						}
					},
					dispose_effect = 'FX_Explosion_Bomb_new'
				},
				chest_2 = {
					patrol_infos = {
						{
							patrol_markers = {
								'marker_8',
								'marker_3'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 5,
							damage_rate = 0.4,
							laser_type = 1
						},
						{
							patrol_markers = {
								'marker_5',
								'marker_6',
								'marker_1',
								'marker_2'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 8,
							damage_rate = 0.15,
							laser_type = 2
						},
						{
							patrol_markers = {
								'marker_9'
							},
							stop_point = 'marker_8',
							delay = 2,
							duration = 0.1,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						}
					},
					dispose_effect = 'FX_Explosion_Bomb_new'
				}
			},

			{ -- 2set Laser(blue)
				chest_1 = {
					patrol_infos = {
						{
							patrol_markers = {
								'marker_3',
								'marker_8'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						},
						{
							patrol_markers = {
								'marker_10',
								'marker_11',
								'marker_17',
								'marker_12',
								'marker_13',
								'marker_14',
								'marker_16',
								'marker_15'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 2.5,
							damage_rate = 0.4,
							laser_type = 1
						},
						{
							patrol_markers = {
								'marker_9'
							},
							stop_point = 'marker_3',
							delay = 2,
							duration = 0.1,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						}
					},
					dispose_effect = 'FX_Explosion_Bomb_new'
				},
				chest_2 = {
					patrol_infos = {
						{
							patrol_markers = {
								'marker_4',
								'marker_7'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						},
						{
							patrol_markers = {
								'marker_9'
							},
							stop_point = 'marker_9',
							delay = 2,
							duration = 20,
							velocity = 2.5,
							damage_rate = 0.4,
							laser_type = 1
						},
						{
							patrol_markers = {
								'marker_9'
							},
							stop_point = 'marker_4',
							delay = 2,
							duration = 0.1,
							velocity = 5,
							damage_rate = 0.15,
							laser_type = 2
						}
					},
					dispose_effect = 'FX_Explosion_Bomb_new'
				}
			},

			{-- 3set Laser(pink)
			chest_1 = {
				patrol_infos = {
					{
						patrol_markers = {
							'marker_7',
							'marker_4'
						},
						stop_point = 'marker_9',
						delay = 2,
						duration = 20,
						velocity = 5,
						damage_rate = 0.4,
						laser_type = 1
					},
					{
						patrol_markers = {
							'marker_6',
							'marker_1',
							'marker_2',
							'marker_5'
						},
						stop_point = 'marker_9',
						delay = 2,
						duration = 20,
						velocity = 8,
						damage_rate = 0.15,
						laser_type = 2
					},
					{
						patrol_markers = {
							'marker_9'
						},
						stop_point = 'marker_7',
						delay = 2,
						duration = 0.1,
						velocity = 5,
						damage_rate = 0.15,
						laser_type = 2
					}
				},
				dispose_effect = 'FX_Explosion_Bomb_new'
			},
			chest_2 = {
				patrol_infos = {
					{
						patrol_markers = {
							'marker_6',
							'marker_5'
						},
						stop_point = 'marker_9',
						delay = 2,
						duration = 20,
						velocity = 5,
						damage_rate = 0.4,
						laser_type = 1
					},
					{
						patrol_markers = {
							'marker_2',
							'marker_5',
							'marker_6',
							'marker_1'
						},
						stop_point = 'marker_9',
						delay = 2,
						duration = 20,
						velocity = 8,
						damage_rate = 0.15,
						laser_type = 2
					},
					{
						patrol_markers = {
							'marker_9'
						},
						stop_point = 'marker_6',
						delay = 2,
						duration = 0.1,
						velocity = 5,
						damage_rate = 0.15,
						laser_type = 2
					}
				},
				dispose_effect = 'FX_Explosion_Bomb_new'
			}

		}
	}
  }
}
