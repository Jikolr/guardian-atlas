return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	--	tower_light_55 = { : 맵 이름
	--		boss_name = 'boss_minister', : 보스이름
	-- 		recovery_robots = { : 회복용 로봇 이름, 최대 3기 동시소환이라 3개 지정 (타일맵에 포함된 이름)
	-- 			'recovery_robot_1',
	-- 			'recovery_robot_2',
	-- 			'recovery_robot_3'
	-- 		},
	-- 		marker_name = 'spawn_position_', : 마커 이름 (번호 제외)
	-- 		respawn_point = {1, 2, 3, 4}, : 리스폰에 쓰일 마커 번호 (spawn_position_1 ~ 4)
	-- 		waypoints = { : 웨이포인트 넘버 (spawn_position_1 ~ 12)
	-- 			{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}, : 1번 리스폰 포인트에서 등장한 경우의 웨이포인트
	-- 			{2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1}, : 2번 리스폰 포인트에서 등장한 경우의 웨이포인트
	-- 			{3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2}, : 3번 리스폰 포인트에서 등장한 경우의 웨이포인트
	-- 			{4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3}  : 4번 리스폰 포인트에서 등장한 경우의 웨이포인트
	-- 		},
	-- 		level_1hp = 1, : 해당 hp 와 다음레벨의 hp 사이에 있을때 1개 소환 (100% ~ 50%)
	-- 		level_2hp = 0.5, : 해당 hp 와 다음레벨의 hp 사이에 있을때 2개 소환 (50% ~ 30%)
	-- 		level_3hp = 0.3, : 해당 hp 이하일때 3개 소환 (30% ~ 0%)
	-- 		cool_down_time = 5, : 회복용 로봇 다 사라지고 난 뒤의 쿨타임
	-- 		recovery_range = 1, : 회복 로봇 범위
	-- 		recovery_amount = 0.05, : 회복량 (MaxHp * recovery_amount) 1일때 최대치
	-- 		move_speed = 1 : 회복로봇 이동속도
	-- 	}
	]] --
	tower_light_55 = {
		boss_name = 'boss_minister',
		recovery_robots = {
			'recovery_robot_1',
			'recovery_robot_2',
			'recovery_robot_3'
		},
		marker_name = 'spawn_position_',
		respawn_point = {1, 5, 3, 7},
		waypoints = {
			{1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4},
			{5, 6, 7, 8, 5, 6, 7, 8, 5, 6, 7, 8},
			{3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2},
			{7, 8, 5, 6, 7, 8, 5, 6, 7, 8, 5, 6}
		},
		level_1hp = 1,
		level_2hp = 0.5,
		level_3hp = 0.5,
		cool_down_time = 8,
		recovery_range = 2,
		recovery_amount = 0.2,
		move_speed = 2.5,
		show_range = true
	}
}