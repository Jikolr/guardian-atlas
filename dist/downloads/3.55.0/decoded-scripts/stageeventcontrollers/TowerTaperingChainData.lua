return {
	--[[
		데이터 셋 구조

		스테이지_이름 = {
			-- 스테이지 내 가시 체인 정보들
			chains = {
				{
					name = 가시 체인 핸들 네임(숫자 제외) 작은 따옴표로 묶어줄 것,
					count = 해당 핸들 네임으로 시작하는 FO의 개수,
					x = x축 이동 방향 및 한번에 이동하는 거리
					z = z축 이동 방향 및 한번에 이동하는 거리
				}
			},
			boss = 스테이지 내 보스의 이름, 작은 따옴표로 묶어줄 것,
			zone = 진입 시 가시 체인 이동 루틴을 작동시킬 존의 이름,
			effect = 가시 체인을 없앨 때 사용할 이펙트의 이름,
			angle = 가시 체인이 움직일 각도,
			speed = 가시 체인이 움직일 속도,
			distance = 가시 체인이 총 움직여야 하는 거리,
			damage_rate = 가시 체인이 주는 데미지의 비율.
			set_spike_on_wave_start = 가시체인을 설치할 이벤트 타이밍, 기본은 false 이고, false 일 때 BattleGroupWaveClearEvent 에서, true 일때 BattleGroupSpawnNextWaveEvent 에서 가시를 생성한다.
		}
	]]
	tower_earth_30 = {
		move_type = 'group',
		narration_info = 'tower_earth_boss_3_narration',
		spikes = {
			{
				name = 'chain_top_',
				count = 14,
				x = 1,
				z = -1
			},
			{
				name = 'chain_bottom_',
				count = 14,
				x = -1,
				z = 1
			},
			{
				name = 'chain_right_',
				count = 14,
				x = -1,
				z = -1
			},
			{
				name = 'chain_left_',
				count = 14,
				x = 1,
				z = 1
			}
		},
		boss = 'boss_nine_tailed_fox',
		zone = 'boss',
		effect = 'FX_Explosion_Bomb_small',
		angle = 31,
		speed = 0.05,
		distance = math.sqrt(32),
		damage_rate = 3,
		damage_type = 'Death',
		set_spike_on_wave_start = false,
		use_attack_range = false,
		spike_delay = 0.0
	},
	tower_earth_15 = {
		move_type = 'wave',
		waves = {
			-- 이 뎁스가 하나의 웨이브
			-- 1 웨이브
			{
				-- 이 뎁스가 하나의 가시 블럭 그룹
				{
					spikes = {
						name = 'sk_1_',
						count = 4,
					},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
					},
				}
			},
			-- 2 웨이브
			{
				{
					spikes = {
						name = 'sk_2_',
						count = 2,
					},
					-- 웨이브 시작 지점
					init = {
						{ -2, 0, 15 },
						{ 1, 0, 12 }
					},
					waypoints = {
						{ 2 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.forward, 2, 0 }
					},
				}
			},
			-- 3 웨이브
			{
				{
					spikes = {
						name = 'sk_3_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -3, 0, 16 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 }
					},
				},
				{
					spikes = {
						name = 'sk_3_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 4, 0, 16 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_c_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 4, 0, 9 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_d_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -3, 0, 9 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_e_',
						count = 2,
					},
					-- 웨이브 시작 지점
					init = {
						{ 2, 0, 14 },
						{ -1, 0, 11 }
					},
					waypoints = {
					},
				},
			},
			-- 4 웨이브
			{
				{
					spikes = {
						name = 'sk_4_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -3, 0, 16 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_4_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 3, 0, 10 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.back, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_4_c_',
						count = 4,
					},
					-- 웨이브 시작 지점
					init = {
						{ -1, 0, 14 },
						{ 2, 0, 14 },
						{ 2, 0, 11 },
						{ -1, 0, 11 },
					},
					waypoints = {
					},
				},
			},
			-- 5 웨이브
			{
				{
					spikes = {
						name = 'sk_5_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 4, 0, 9 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_5_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -1, 0, 14 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 3 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 3 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 3 * CS.UnityEngine.Vector3.forward, 2, 0 },
					},
				},
			},
		},
		boss = '',
		zone = 'wave',
		effect = 'FX_Explosion_Bomb_small',
		reset_effect = 'FX_reset_object',
		damage_rate = 0.18,
		set_spike_on_wave_start = false,
		use_attack_range = false,
		spike_delay = 0.0
	},
	tower_fire_15 = {
		move_type = 'wave',
		waves = {
			-- 이 뎁스가 하나의 웨이브
			-- 1 웨이브
			{
				-- 이 뎁스가 하나의 가시 블럭 그룹
				{
					spikes = {
						name = 'sk_1_',
						count = 4,
					},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
					},
				}
			},
			-- 2 웨이브
			{
				{
					spikes = {
						name = 'sk_2_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -3, 1, 16 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.right, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 1 }
					},
				},
				{
					spikes = {
						name = 'sk_2_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 4, 1, 9 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.left, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.right, 2, 1 },
						{ 7 * CS.UnityEngine.Vector3.back, 2, 1 }
					},
				}
			},
			-- 3 웨이브
			{
				{
					spikes = {
						name = 'sk_3_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -2, 1, 15 }
					},
					waypoints = {
						{ 2 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.forward, 2, 0 }
					},
				},
				{
					spikes = {
						name = 'sk_3_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 3, 1, 15 }
					},
					waypoints = {
						{ 2 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.right, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_c_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 3, 1, 10 }
					},
					waypoints = {
						{ 2 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.back, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_d_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -2, 1, 10 }
					},
					waypoints = {
						{ 2 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 2 * CS.UnityEngine.Vector3.left, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_3_e_',
						count = 4,
					},
					-- 웨이브 시작 지점
					init = {
						{ -1, 1, 14 },
						{ 2, 1, 14 },
						{ -1, 1, 11 },
						{ 2, 1, 11 }
					},
					waypoints = {
					},
				},
			},
			-- 4 웨이브
			{
				{
					spikes = {
						name = 'sk_4_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -3, 1, 12.5 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 }
					},
				},
				{
					spikes = {
						name = 'sk_4_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 0.5, 1, 12.5 }
					},
					waypoints = {
						{ 3.5 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward, 2, 0 },
						{ 3.5 * CS.UnityEngine.Vector3.back, 2, 0 }
					},
				},
				{
					spikes = {
						name = 'sk_4_c_',
						count = 4,
					},
					-- 웨이브 시작 지점
					init = {
						{ -1, 1, 14 },
						{ 2, 1, 14 },
						{ -1, 1, 11 },
						{ 2, 1, 11 }
					},
					waypoints = {
					},
				},
			},
			-- 5 웨이브
			{
				{
					spikes = {
						name = 'sk_5_a_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ 4, 1, 9 }
					},
					waypoints = {
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.forward + 7 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 7 * CS.UnityEngine.Vector3.back + 7 * CS.UnityEngine.Vector3.right, 2, 0 },
					},
				},
				{
					spikes = {
						name = 'sk_5_b_',
						count = 1,
					},
					-- 웨이브 시작 지점
					init = {
						{ -2, 1, 5 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.right, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.back, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.left, 2, 0 },
						{ 5 * CS.UnityEngine.Vector3.forward, 2, 0 }
					},
				},
			},
		},
		boss = '',
		zone = 'wave',
		effect = 'FX_Explosion_Bomb_small',
		reset_effect = 'FX_reset_object',
		damage_rate = 0.18,
		set_spike_on_wave_start = false,
		use_attack_range = false,
		spike_delay = 0.0
	},
	tower_ice_52 = {
		move_type = 'wave',
		waves = {
			-- 이 뎁스가 하나의 웨이브
			-- 1 웨이브
			{
				-- 이 뎁스가 하나의 가시 블럭 그룹
				{
					spikes = {
						name = 'sk_1_',
						count = 4,
					},
					--init = {
					--	{ 31, 1, 6 },
					--	{ 33, 1, 6 },
					--	{ 35, 1, 6 }
					--},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
					--	{ 13 * CS.UnityEngine.Vector3.back, 2, 1 }
					},
				}
			},
			-- 2 웨이브
			{
				-- NW
				{
					spikes = {
						name = 'sk_2_nw_1_',
						count = 1,
					},
					init = {
						{ 31, 1, 6 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.right, 2, 3 }, --5.5
						{ 5 * CS.UnityEngine.Vector3.left, 2, 3 } --5.5
					},
				},
				{
					spikes = {
						name = 'sk_2_nw_2_',
						count = 1,
					},
					init = {
						{ 29, 1, 4 }
					},
					waypoints = {
						{ 9 * CS.UnityEngine.Vector3.right, 3, 2.5 }, --5.5
						{ 9 * CS.UnityEngine.Vector3.left, 3, 2.5 }
					},
				},
				{
					spikes = {
						name = 'sk_2_nw_3_',
						count = 1,
					},
					init = {
						{ 27, 1, 2 }
					},
					waypoints = {
						{ 13 * CS.UnityEngine.Vector3.right, 4, 2.25 },
						{ 13 * CS.UnityEngine.Vector3.left, 4, 2.25 }
					},
				},
				-- NE
				{
					spikes = {
						name = 'sk_2_ne_1_',
						count = 1,
					},
					init = {
						{ 40, 1, 2 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.back, 2, 3 },
						{ 5 * CS.UnityEngine.Vector3.forward, 2, 3 }
					},
				},
				{
					spikes = {
						name = 'sk_2_ne_2_',
						count = 1,
					},
					init = {
						{ 38, 1, 4 }
					},
					waypoints = {
						{ 9 * CS.UnityEngine.Vector3.back, 3, 2.5 },
						{ 9 * CS.UnityEngine.Vector3.forward, 3, 2.5 }
					},
				},
				{
					spikes = {
						name = 'sk_2_ne_3_',
						count = 1,
					},
					init = {
						{ 36, 1, 6 }
					},
					waypoints = {
						{ 13 * CS.UnityEngine.Vector3.back, 4, 2.25 },
						{ 13 * CS.UnityEngine.Vector3.forward, 4, 2.25 }
					},
				},
				-- SE
				{
					spikes = {
						name = 'sk_2_se_1_',
						count = 1,
					},
					init = {
						{ 36, 1, -7 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.left, 2, 3 },
						{ 5 * CS.UnityEngine.Vector3.right, 2, 3 }
					},
				},
				{
					spikes = {
						name = 'sk_2_se_2_',
						count = 1,
					},
					init = {
						{ 38, 1, -5 }
					},
					waypoints = {
						{ 9 * CS.UnityEngine.Vector3.left, 3, 2.5 },
						{ 9 * CS.UnityEngine.Vector3.right, 3, 2.5 }
					},
				},
				{
					spikes = {
						name = 'sk_2_se_3_',
						count = 1,
					},
					init = {
						{ 40, 1, -3 }
					},
					waypoints = {
						{ 13 * CS.UnityEngine.Vector3.left, 4, 2.25 },
						{ 13 * CS.UnityEngine.Vector3.right, 4, 2.25 }
					},
				},
				-- SW
				{
					spikes = {
						name = 'sk_2_sw_1_',
						count = 1,
					},
					init = {
						{ 27, 1, -3 }
					},
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.forward, 2, 3 },
						{ 5 * CS.UnityEngine.Vector3.back, 2, 3 }
					},
				},
				{
					spikes = {
						name = 'sk_2_sw_2_',
						count = 1,
					},
					init = {
						{ 29, 1, -5 }
					},
					waypoints = {
						{ 9 * CS.UnityEngine.Vector3.forward, 3, 2.5 },
						{ 9 * CS.UnityEngine.Vector3.back, 3, 2.5 }
					},
				},
				{
					spikes = {
						name = 'sk_2_sw_3_',
						count = 1,
					},
					init = {
						{ 31, 1, -7 }
					},
					waypoints = {
						{ 13 * CS.UnityEngine.Vector3.forward, 4, 2.25 },
						{ 13 * CS.UnityEngine.Vector3.back, 4, 2.25 }
					},
				}
			},
			-- 3 웨이브
			{
				-- TOP
				{
					spikes = {
						name = 'sk_3_top_',
						count = 6,
					},
					init = {
						{ 31, 1, 6 },
						{ 32, 1, 6 },
						{ 33, 1, 6 },
						{ 34, 1, 6 },
						{ 35, 1, 6 },
						{ 36, 1, 6 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.back, 1, 3 },
						{ 3 * CS.UnityEngine.Vector3.forward, 1, 3 },
					},
				},
				-- LEFT
				{
					spikes = {
						name = 'sk_3_left_',
						count = 6,
					},
					init = {
						{ 27, 1, 2 },
						{ 27, 1, 1 },
						{ 27, 1, 0 },
						{ 27, 1, -1 },
						{ 27, 1, -2 },
						{ 27, 1, -3 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.right, 1, 3 },
						{ 3 * CS.UnityEngine.Vector3.left, 1, 3 },
					},
				},
				-- BOT
				{
					spikes = {
						name = 'sk_3_bot_',
						count = 6,
					},
					init = {
						{ 31, 1, -7 },
						{ 32, 1, -7 },
						{ 33, 1, -7 },
						{ 34, 1, -7 },
						{ 35, 1, -7 },
						{ 36, 1, -7 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.forward, 1, 3 },
						{ 3 * CS.UnityEngine.Vector3.back, 1, 3 },
					},
				},
				-- RIGHT
				{
					spikes = {
						name = 'sk_3_right_',
						count = 6,
					},
					init = {
						{ 40, 1, 2 },
						{ 40, 1, 1 },
						{ 40, 1, 0 },
						{ 40, 1, -1 },
						{ 40, 1, -2 },
						{ 40, 1, -3 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.left, 1, 3 },
						{ 3 * CS.UnityEngine.Vector3.right, 1, 3 },
					},
				},
			},
			-- 4 웨이브
			{
				-- 이 뎁스가 하나의 가시 블럭 그룹
				{
					spikes = {
						name = 'sk_4_top_',
						count = 3,
					},
					init = {
						{ 31, 1, 6 },
						{ 33, 1, 6 },
						{ 35, 1, 6 }
					},
					waypoints = {
						{ 4 * CS.UnityEngine.Vector3.back, 1, 100 },
						{ 2 * CS.UnityEngine.Vector3.back, 1, 1 },
						{ 2 * CS.UnityEngine.Vector3.back, 1, 2 },
						{ 5 * CS.UnityEngine.Vector3.back, 1, 2 }
					},
				},
				{
					spikes = {
						name = 'sk_4_bot_',
						count = 3,
					},
					init = {
						{ 32, 1, -7 },
						{ 34, 1, -7 },
						{ 36, 1, -7 }
					},
					waypoints = {
						{ 3 * CS.UnityEngine.Vector3.forward, 1, 100 },
						{ 3 * CS.UnityEngine.Vector3.forward, 1, 12.5 },
						{ 7 * CS.UnityEngine.Vector3.forward, 1, 2 },
					},
				},
				{
					spikes = {
						name = 'sk_4_right_',
						count = 3,
					},
					init = {
						{ 40, 1, 2 },
						{ 40, 1, 0 },
						{ 40, 1, -2 }
					},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
						{ 4 * CS.UnityEngine.Vector3.left, 1, 100 },
						{ 3 * CS.UnityEngine.Vector3.left, 1, 9.5 },
						{ 6 * CS.UnityEngine.Vector3.left, 1, 2 }
					},
				},
				{
					spikes = {
						name = 'sk_4_left_',
						count = 3,
					},
					init = {
						{ 27, 1, 1 },
						{ 27, 1, -1 },
						{ 27, 1, -3 }
					},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
						{ 5 * CS.UnityEngine.Vector3.right, 1, 100 },
						{ 2 * CS.UnityEngine.Vector3.right, 1, 2 },
						{ 6 * CS.UnityEngine.Vector3.right, 1, 2 }
					},
				},
			},
			-- 5 웨이브
			{
				-- 이 뎁스가 하나의 가시 블럭 그룹
				{
					spikes = {
						name = 'sk_5_',
						count = 36,
					},
					init = {
						{ 31, 1, 6 },
						{ 32, 1, 6 },
						{ 33, 1, 6 },
						{ 34, 1, 6 },
						{ 35, 1, 6 },
						{ 36, 1, 6 },

						{ 37, 1, 5 },
						{ 38, 1, 4 },
						{ 39, 1, 3 },

						{ 40, 1, 2 },
						{ 40, 1, 1 },
						{ 40, 1, 0 },
						{ 40, 1, -1 },
						{ 40, 1, -2 },
						{ 40, 1, -3 },

						{ 39, 1, -4 },
						{ 38, 1, -5 },
						{ 37, 1, -6 },

						{ 31, 1, -7 },
						{ 32, 1, -7 },
						{ 33, 1, -7 },
						{ 34, 1, -7 },
						{ 35, 1, -7 },
						{ 36, 1, -7 },

						{ 30, 1, -6 },
						{ 29, 1, -5 },
						{ 28, 1, -4 },

						{ 27, 1, 2 },
						{ 27, 1, 1 },
						{ 27, 1, 0 },
						{ 27, 1, -1 },
						{ 27, 1, -2 },
						{ 27, 1, -3 },

						{ 28, 1, 3 },
						{ 29, 1, 4 },
						{ 30, 1, 5 }
					},
					-- 이 뎁스는 가시 블럭의 웨이브 진행 중 이동 경로.
					-- [1] : 이동 벡터
					-- [2] : 이동 속도
					-- [3] : 이동 완료후 정지 시간
					waypoints = {
					--	{ 13 * CS.UnityEngine.Vector3.back, 2, 1 }
					},
				}
			},
		},
		boss = '',
		zone = 'wave',
		effect = 'FX_Explosion_Bomb_small',
		reset_effect = 'FX_reset_object',
		damage_rate = 0.20,
		set_spike_on_wave_start = true,
		use_attack_range = true,
		spike_delay = 0.5
	},
	tower_darkness_59 = {
		move_type = 'wave',
		waves = {
			-- 이 뎁스가 하나의 웨이브
			-- 1 웨이브
			{
				-- 가시 블록 그룹 (정지)
				{
					spikes = {
						name = 'spike_wall_1_',
						count = 44,
					},
					init = {
						{ 19, 0, 5 },
						{ 19, 0, 4 },
						{ 19, 0, 3 },
						{ 19, 0, 2 },
						{ 19, 0, 1 },
						{ 19, 0, 0 },
						{ 19, 0, -1 },
						{ 19, 0, -2 },
						{ 19, 0, -3 },
						{ 19, 0, -4 },
						{ 19, 0, -5 },
						{ 30, 0, -6 },
						{ 30, 0, -5 },
						{ 30, 0, -4 },
						{ 30, 0, -3 },
						{ 30, 0, -2 },
						{ 30, 0, -1 },
						{ 30, 0, 0 },
						{ 30, 0, 1 },
						{ 30, 0, 2 },
						{ 30, 0, 3 },
						{ 30, 0, 4 },
						{ 20, 0, 5 },
						{ 21, 0, 5 },
						{ 22, 0, 5 },
						{ 23, 0, 5 },
						{ 24, 0, 5 },
						{ 25, 0, 5 },
						{ 26, 0, 5 },
						{ 27, 0, 5 },
						{ 28, 0, 5 },
						{ 29, 0, 5 },
						{ 30, 0, 5 },
						{ 19, 0, -6 },
						{ 20, 0, -6 },
						{ 21, 0, -6 },
						{ 22, 0, -6 },
						{ 23, 0, -6 },
						{ 24, 0, -6 },
						{ 25, 0, -6 },
						{ 26, 0, -6 },
						{ 27, 0, -6 },
						{ 28, 0, -6 },
						{ 29, 0, -6 }
					},
					waypoints = {
					}
				}
			},
			-- 2 웨이브
			{
				-- 가시 블록 1그룹 (좌변)
				{
					spikes = {
						name = 'spike_wave_1_right_',
						count = 9,
					},
					init = {
						{ 19, 0, 5 },
						{ 19, 0, 4 },
						{ 19, 0, 3 },
						{ 19, 0, 2 },
						{ 19, 0, 1 },
						{ 19, 0, -2 },
						{ 19, 0, -3 },
						{ 19, 0, -4 },
						{ 19, 0, -5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 }
					}
				},
				-- 가시 블록 2그룹 (우변)
				{
					spikes = {
						name = 'spike_wave_1_left_',
						count = 9,
					},
					init = {
						{ 30, 0, -6 },
						{ 30, 0, -5 },
						{ 30, 0, -4 },
						{ 30, 0, -3 },
						{ 30, 0, -2 },
						{ 30, 0, 1 },
						{ 30, 0, 2 },
						{ 30, 0, 3 },
						{ 30, 0, 4 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 }
					}
				},
				-- 가시 블록 3그룹 (상변)
				{
					spikes = {
						name = 'spike_wave_1_down_',
						count = 9,
					},
					init = {
						{ 20, 0, 5 },
						{ 21, 0, 5 },
						{ 22, 0, 5 },
						{ 23, 0, 5 },
						{ 26, 0, 5 },
						{ 27, 0, 5 },
						{ 28, 0, 5 },
						{ 29, 0, 5 },
						{ 30, 0, 5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 }
					}
				},
				-- 가시 블록 4그룹 (하변)
				{
					spikes = {
						name = 'spike_wave_1_up_',
						count = 9,
					},
					init = {
						{ 19, 0, -6 },
						{ 20, 0, -6 },
						{ 21, 0, -6 },
						{ 22, 0, -6 },
						{ 23, 0, -6 },
						{ 26, 0, -6 },
						{ 27, 0, -6 },
						{ 28, 0, -6 },
						{ 29, 0, -6 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 }
					}
				}
			},
			-- 3 웨이브
			{
				-- 가시 블록 그룹 (정지)
				{
					spikes = {
						name = 'spike_wall_2_',
						count = 44,
					},
					init = {
						{ 19, 0, 5 },
						{ 19, 0, 4 },
						{ 19, 0, 3 },
						{ 19, 0, 2 },
						{ 19, 0, 1 },
						{ 19, 0, 0 },
						{ 19, 0, -1 },
						{ 19, 0, -2 },
						{ 19, 0, -3 },
						{ 19, 0, -4 },
						{ 19, 0, -5 },
						{ 30, 0, -6 },
						{ 30, 0, -5 },
						{ 30, 0, -4 },
						{ 30, 0, -3 },
						{ 30, 0, -2 },
						{ 30, 0, -1 },
						{ 30, 0, 0 },
						{ 30, 0, 1 },
						{ 30, 0, 2 },
						{ 30, 0, 3 },
						{ 30, 0, 4 },
						{ 20, 0, 5 },
						{ 21, 0, 5 },
						{ 22, 0, 5 },
						{ 23, 0, 5 },
						{ 24, 0, 5 },
						{ 25, 0, 5 },
						{ 26, 0, 5 },
						{ 27, 0, 5 },
						{ 28, 0, 5 },
						{ 29, 0, 5 },
						{ 30, 0, 5 },
						{ 19, 0, -6 },
						{ 20, 0, -6 },
						{ 21, 0, -6 },
						{ 22, 0, -6 },
						{ 23, 0, -6 },
						{ 24, 0, -6 },
						{ 25, 0, -6 },
						{ 26, 0, -6 },
						{ 27, 0, -6 },
						{ 28, 0, -6 },
						{ 29, 0, -6 }
					},
					waypoints = {
					}
				}
			},
			-- 4 웨이브
			{
				-- 가시 블록 1그룹 (좌변)
				{
					spikes = {
						name = 'spike_wave_2_right_',
						count = 9,
					},
					init = {
						{ 19, 0, 5 },
						{ 19, 0, 4 },
						{ 19, 0, 3 },
						{ 19, 0, 2 },
						{ 19, 0, 1 },
						{ 19, 0, -2 },
						{ 19, 0, -3 },
						{ 19, 0, -4 },
						{ 19, 0, -5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 }
					}
				},
				-- 가시 블록 2그룹 (우변)
				{
					spikes = {
						name = 'spike_wave_2_left_',
						count = 9,
					},
					init = {
						{ 30, 0, -6 },
						{ 30, 0, -5 },
						{ 30, 0, -4 },
						{ 30, 0, -3 },
						{ 30, 0, -2 },
						{ 30, 0, 1 },
						{ 30, 0, 2 },
						{ 30, 0, 3 },
						{ 30, 0, 4 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 }
					}
				},
				-- 가시 블록 3그룹 (상변)
				{
					spikes = {
						name = 'spike_wave_2_down_',
						count = 9,
					},
					init = {
						{ 20, 0, 5 },
						{ 21, 0, 5 },
						{ 22, 0, 5 },
						{ 23, 0, 5 },
						{ 26, 0, 5 },
						{ 27, 0, 5 },
						{ 28, 0, 5 },
						{ 29, 0, 5 },
						{ 30, 0, 5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 }
					}
				},
				-- 가시 블록 4그룹 (하변)
				{
					spikes = {
						name = 'spike_wave_2_up_',
						count = 9,
					},
					init = {
						{ 19, 0, -6 },
						{ 20, 0, -6 },
						{ 21, 0, -6 },
						{ 22, 0, -6 },
						{ 23, 0, -6 },
						{ 26, 0, -6 },
						{ 27, 0, -6 },
						{ 28, 0, -6 },
						{ 29, 0, -6 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 }
					}
				}
			},
			-- 5 웨이브
			{
				-- 가시 블록 1그룹 (좌변)
				{
					spikes = {
						name = 'spike_wave_3_right_',
						count = 9,
					},
					init = {
						{ 19, 0, 5 },
						{ 19, 0, 4 },
						{ 19, 0, 3 },
						{ 19, 0, 2 },
						{ 19, 0, 1 },
						{ 19, 0, -2 },
						{ 19, 0, -3 },
						{ 19, 0, -4 },
						{ 19, 0, -5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.right, 0.075, 0 }
					}
				},
				-- 가시 블록 2그룹 (우변)
				{
					spikes = {
						name = 'spike_wave_3_left_',
						count = 9,
					},
					init = {
						{ 30, 0, -6 },
						{ 30, 0, -5 },
						{ 30, 0, -4 },
						{ 30, 0, -3 },
						{ 30, 0, -2 },
						{ 30, 0, 1 },
						{ 30, 0, 2 },
						{ 30, 0, 3 },
						{ 30, 0, 4 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.left, 0.075, 0 }
					}
				},
				-- 가시 블록 3그룹 (상변)
				{
					spikes = {
						name = 'spike_wave_3_down_',
						count = 9,
					},
					init = {
						{ 20, 0, 5 },
						{ 21, 0, 5 },
						{ 22, 0, 5 },
						{ 23, 0, 5 },
						{ 26, 0, 5 },
						{ 27, 0, 5 },
						{ 28, 0, 5 },
						{ 29, 0, 5 },
						{ 30, 0, 5 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.back, 0.075, 0 }
					}
				},
				-- 가시 블록 4그룹 (하변)
				{
					spikes = {
						name = 'spike_wave_3_up_',
						count = 9,
					},
					init = {
						{ 19, 0, -6 },
						{ 20, 0, -6 },
						{ 21, 0, -6 },
						{ 22, 0, -6 },
						{ 23, 0, -6 },
						{ 26, 0, -6 },
						{ 27, 0, -6 },
						{ 28, 0, -6 },
						{ 29, 0, -6 }
					},
					waypoints = {
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 },
						{ 1 * CS.UnityEngine.Vector3.forward, 0.075, 0 }
					}
				}
			},
		},
		boss = '',
		zone = 'wave',
		effect = 'FX_Explosion_Bomb_small',
		reset_effect = 'FX_reset_object',
		damage_rate = 0.66,
		set_spike_on_wave_start = false,
		use_attack_range = false,
		spike_delay = 0.0
	}
}
