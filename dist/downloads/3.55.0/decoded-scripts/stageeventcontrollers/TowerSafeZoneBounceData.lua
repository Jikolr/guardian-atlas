return {
	--[[
		데이터 셋 구조

		스테이지_이름 = {
			battle_zone_names = 현재 스테이지에 존재하는 배틀존 이름, 아래 데이터와 일치되어야 함.
			배틀존 이름 = {
				safe_zones = { : 안전지역 설정
					{
						start_marker = 시작 마커
						radius = 반지름
						speed = 속도
						angle = 출발각도 12시 기준으로 시계 방향으로 책정됨
						radius_per_bounce = 바운스시 범위 감소량 value < 0 으로만 입력 필수
						speed_per_bounce = 바운스시 속도 증감량 증감량에 의한 속도 최대치 : 21 / 최소치 0.5 까지만 변화 함.
						duration = 바운스시 증감하는 값 적용 시간
					}
					.. : 여러개 설정 가능
				},
				party_safe_zone_radius = { 파티 기본 원형 범위 : 파티원 없거나 사망한 상탱에서는 적용되지 않음
					0, // 리더
					1, // 두번째 파티원
					1, // 세번째 파티원
					1 // 네번째 파티원
				}
			}
			.. : 배틀존 여러개 설정 가능
			count_down = 전체 스테이지에서 적용되는 카운트다운
			narration_info = 나레이션 스트링 정보
		}
	]]
	tower_ice_54 = {
		battle_zone_names = {
			'battle_1',
			'battle_2',
			'battle_3',
			'battle_4',
			'gimmick_1',
			'gimmick_2'
		},
		battle_1 = {
			safe_zones = {
				{
					start_marker = 'b1_1',
					radius = 5,
					speed = 1,
					angle = 80,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.1,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				2,
				2,
				2
			}
		},
		battle_2 = {
			safe_zones = {
				{
					start_marker = 'b2_1',
					radius = 4,
					speed = 2,
					angle = 200,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.2,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				2,
				2,
				2
			}
		},
		battle_3 = {
			safe_zones = {
				{
					start_marker = 'b3_1',
					radius = 3.5,
					speed = 2,
					angle = 160,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.25,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				2,
				2,
				2
			}
		},
		battle_4 = {
			safe_zones = {
				{
					start_marker = 'b4_1',
					radius = 3.5,
					speed = 2,
					angle = 50,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.25,
					duration = 0.5
				},
				{
					start_marker = 'b4_2',
					radius = 3.5,
					speed = 2,
					angle = 260,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.25,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				2,
				2,
				2
			}
		},
		gimmick_1 = {
			safe_zones = {
				{
					start_marker = 'g1_1',
					radius = 3,
					speed = 2,
					angle = 165,
					radius_per_bounce = -0.1,
					speed_per_bounce = -0.25,
					duration = 0.5
				},
				{
					start_marker = 'g1_2',
					radius = 3,
					speed = 2,
					angle = 345,
					radius_per_bounce = -0.1,
					speed_per_bounce = -0.25,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				0,
				0,
				0
			}
		},
		gimmick_2 = {
			safe_zones = {
				{
					start_marker = 'g2_1',
					radius = 4,
					speed = 1,
					angle = 285,
					radius_per_bounce = -0.1,
					speed_per_bounce = 0.5,
					duration = 0.5
				}
			},
			party_safe_zone_radius = {
				0,
				0,
				0,
				0
			}
		},
		count_down = 5,
		narration_info = 'tower_ice_elite_8_narration',
	}
}
