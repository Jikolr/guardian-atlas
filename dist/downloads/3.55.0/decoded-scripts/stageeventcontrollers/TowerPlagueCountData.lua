return {
	-- ** 배틀 그룹(몬스터의 이벤트그룹)과 배틀존(타일맵상 event)은 이름이 같아야 한다.  
	--tower_darkness_2 = { : 맵이름
	--	battle_group_names = { : 전체 배틀 그룹명, 아래 데이터와 일치 되어야 한다.
	--		'battle_1'
	--	},
	--	battle_1 = { : 배틀그룹 이름
	--		target_name = 'battle_1_1' : 해당 배틀 그룹 내 엘리트 몬스터 이름
	--		plague_count = 10, : 해당 배틀에서의 카운트 시간
	--		cam_magnitude = 0.2, : 옵션 전염되는 경우 카메라 셰이킹 강도
	--		cam_duration = 0.3, : 카메라 셰이킹 길이
	--	}
	--	tint_color = { R,G,B } : 틴트 색상
	--	tint_time = 틴트 하는데 걸리는 시간
	--}
	--
	tower_light_54 = {
		battle_group_names = {
			'battle1',
			'battle2',
			'battle3',
			'battle4',
			'battle5',
		},
		battle1 = {
			target_name = 'battle1_1',
			plague_count = 10,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle2 = {
			target_name = 'battle2_7', 
			plague_count = 10,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle3 = {
			target_name = 'battle3_1_9',
			plague_count = 10,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle4 = {
			target_name = 'battle4_1',
			plague_count = 10,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle5 = {
			target_name = 'battle5_14',
			plague_count = 10,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		tint_color = { 0.3, 1, 0.3 },
		tint_time = 0.5
	},
	tower_darkness_57 = {
		battle_group_names = {
			'battle1',
			'battle2',
			'battle3',
			'battle4',
			'battle5',
		},
		battle1 = {
			target_name = 'battle1_1',
			plague_count = 12,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle2 = {
			target_name = 'battle2_1', 
			plague_count = 12,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle3 = {
			target_name = 'battle3_1_1',
			plague_count = 15,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle4 = {
			target_name = 'battle4_1',
			plague_count = 12,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		battle5 = {
			target_name = 'battle5_1',
			plague_count = 15,
			cam_magnitude = 0.4,
			cam_duration = 0.3,
		},
		tint_color = { 0.3, 1, 0.3 },
		tint_time = 0.5
	}
}
