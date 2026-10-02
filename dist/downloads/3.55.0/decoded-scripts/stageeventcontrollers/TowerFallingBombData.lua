return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- target_groups = {
	-- 		{
	-- 			markers = {
	-- 				name : 폭탄이 낙하할 위치의 마커 명칭
	-- 				delay_time : 폭탄 폭발 후 딜레이 시간
	-- 			}
	-- 			event_zone : 진입시 적용될 배틀 존
	-- 		}
	-- }
	-- missile_vfx : 낙하하는 이펙트 (없을 경우 폭탄 프리펩 사용)
	-- explosion_vfx : 폭탄 폭발시 이펙트
	-- explosion_sfx : 폭탄 폭발시 효과음
	-- bomb_warp_vfx : 폭탄 소환, 낙하도중 비활성화시 이펙트
	-- proportional_damage_rate : 입힐 체력 비례 피해율 (maxHP * proportional_damage_rate)
	-- explosion_radius : 폭발 범위 반지름,
	-- bomb_height : 폭탄 소환시 높이,
	-- fall_duration : 낙하하는 시간,
	]] --
	tower_none_43 = {
		target_groups = {
			{
				markers = {
					{
						name = 'marker_21',
						delay_time = 2
					},
					{
						name = 'marker_22',
						delay_time = 2
					},
					{
						name = 'marker_23',
						delay_time = 2
					},
					{
						name = 'marker_24',
						delay_time = 2
					},
					{
						name = 'marker_25',
						delay_time = 4
					},
					{
						name = 'marker_26',
						delay_time = 4
					},
					{
						name = 'marker_27',
						delay_time = 4
					},
					{
						name = 'marker_28',
						delay_time = 4
					}
				},
				event_zone = 'bomb_1'
			},
			{
				markers = {
					{
						name = 'marker_1',
						delay_time = 1
					},
					{
						name = 'marker_2',
						delay_time = 2
					},
					{
						name = 'marker_3',
						delay_time = 1
					},
					{
						name = 'marker_4',
						delay_time = 2
					},
					{
						name = 'marker_5',
						delay_time = 1
					},
					{
						name = 'marker_6',
						delay_time = 2
					},
					{
						name = 'marker_7',
						delay_time = 2
					},
					{
						name = 'marker_8',
						delay_time = 2
					},
					{
						name = 'marker_9',
						delay_time = 2
					},
					{
						name = 'marker_14',
						delay_time = 2
					},
					{
						name = 'marker_15',
						delay_time = 2
					},
					{
						name = 'marker_16',
						delay_time = 1
					},
					{
						name = 'marker_17',
						delay_time = 2
					},
					{
						name = 'marker_18',
						delay_time = 3
					},
					{
						name = 'marker_19',
						delay_time = 2
					},
					{
						name = 'marker_20',
						delay_time = 1
					}
				},
				event_zone = 'bomb_2'
			},
			{
				markers = {
					{
						name = 'marker_10',
						delay_time = 2
					},
					{
						name = 'marker_12',
						delay_time = 2
					}
				},
				event_zone = 'bomb_3'
			}
		},
		missile_vfx = 'FX_IronMissile_Proj',
		explosion_vfx = 'FX_IronMissile_Explosion',
		explosion_sfx = '02_wolf_boss_bomb_01',
		bomb_warp_vfx = 'FX_reset_object',
		proportional_damage_rate = 0.1,
		explosion_radius = 1.5,
		bomb_height = 20,
		fall_duration = 1
	},
	
	}
	--[[,
	hell_forest_1 = {
		target_groups = {
			{
				markers = {
					{
						name = 'marker_1',
						delay_time = 1.5
					},
					{
						name = 'marker_2',
						delay_time = 1.5
					}
				},
				event_zone = 'bomb_1'
			},
			{
				markers = {
					{
						name = 'marker_10',
						delay_time = 2.5
					},
					{
						name = 'marker_11',
						delay_time = 5.5
					},
					{
						name = 'marker_12',
						delay_time = 2.5
					},
					{
						name = 'marker_13',
						delay_time = 5.5
					},
					{
						name = 'marker_14',
						delay_time = 2.5
					},
					{
						name = 'marker_15',
						delay_time = 5.5
					},
					{
						name = 'marker_16',
						delay_time = 2.5
					}
				},
				event_zone = 'bomb_2'
			},
			{
				markers = {
					{
						name = 'marker_20',
						delay_time = 2.5
					},
					{
						name = 'marker_21',
						delay_time = 5.5
					},
					{
						name = 'marker_22',
						delay_time = 2.5
					},
					{
						name = 'marker_23',
						delay_time = 5.5
					},
					{
						name = 'marker_24',
						delay_time = 2.5
					},
					{
						name = 'marker_25',
						delay_time = 5.5
					},
					{
						name = 'marker_26',
						delay_time = 2.5
					},
					{
						name = 'marker_27',
						delay_time = 5.5
					},
					{
						name = 'marker_28',
						delay_time = 2.5
					}
				},
				event_zone = 'bomb_3'
			},
			{
				markers = {
					{
						name = 'marker_40',
						delay_time = 5.5
					},
					{
						name = 'marker_41',
						delay_time = 2.5
					},
					{
						name = 'marker_42',
						delay_time = 5.5
					},
					{
						name = 'marker_43',
						delay_time = 2.5
					},
					{
						name = 'marker_44',
						delay_time = 5.5
					},
					{
						name = 'marker_45',
						delay_time = 2.5
					}
				},
				event_zone = 'bomb_4'
			}
		},
		missile_vfx = 'FX_IronMissile_Proj',
		explosion_vfx = 'FX_IronMissile_Explosion',
		explosion_sfx = '02_wolf_boss_bomb_01',
		bomb_warp_vfx = 'FX_reset_object',
		proportional_damage_rate = 0.08,
		explosion_radius = 0.75,
		bomb_height = 4,
		fall_duration = 0.2
	}--]]
