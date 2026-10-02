
-- 스테이지별 사야 봉인석 데이터
return {
	battle_test_5 = {
		boss_name = 'boss_phase_1',
		saya_stone_name = 'saya_stone_',
		saya_stone_count = 8,
		marker_name = "red_marker_", --마커 이름
		marker_count = 8, --마커 갯수
		max_spawn_count = 2,--최대 소환 갯수
		attack_radius = 10, --그로기 적용 범위
		aliment_gauge = 30, --그로기 증가 수치
		spawn_count = 2, --고정
		marker_group = {  --소환 시 같은 그룹은 같이 소환되지 않음
			{1, 2, 3, 4},
			{5, 6, 7, 8}},
		ignore_group = {
			{1, 5}, --같은 그룹은 같이 소환되지 않음
			{2, 6},
			{3, 7},
			{4, 8}},
		spawn_time = 10, --소환 딜레이 간격
		is_active = false -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
	},
	co_exp_stage_2_4 = {
		boss_name = 'boss_phase_1',
		saya_stone_name = 'saya_stone_',
		saya_stone_count = 8,
		marker_name = "red_marker_", --마커 이름
		marker_count = 8, --마커 갯수
		max_spawn_count = 2,--최대 소환 갯수
		attack_radius = 10, --그로기 적용 범위
		aliment_gauge = 100, --그로기 증가 수치
		spawn_count = 2, --고정
		marker_group = {  --소환 시 같은 그룹은 같이 소환되지 않음
			{1, 2, 3, 4},
			{5, 6, 7, 8}},
		ignore_group = {
			{1, 5}, --같은 그룹은 같이 소환되지 않음
			{2, 6},
			{3, 7},
			{4, 8}},
		spawn_time = 25, --소환 딜레이 간격
		is_active = false -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
	},
	co_exp_stage_2_4_hard = {
		boss_name = 'boss_phase_1',
		saya_stone_name = 'saya_stone_',
		saya_stone_count = 8,
		marker_name = "red_marker_", --마커 이름
		marker_count = 8, --마커 갯수
		max_spawn_count = 2,--최대 소환 갯수
		attack_radius = 10, --그로기 적용 범위
		aliment_gauge = 100, --그로기 증가 수치
		spawn_count = 2, --고정
		marker_group = {  --소환 시 같은 그룹은 같이 소환되지 않음
			{1, 2, 3, 4},
			{5, 6, 7, 8}},
		ignore_group = {
			{1, 5}, --같은 그룹은 같이 소환되지 않음
			{2, 6},
			{3, 7},
			{4, 8}},
		spawn_time = 25, --소환 딜레이 간격
		is_active = false -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
	},
	co_exp_stage_2_4_super_hard = {
		boss_name = 'boss_phase_1',
		saya_stone_name = 'saya_stone_',
		saya_stone_count = 8,
		marker_name = "red_marker_", --마커 이름
		marker_count = 8, --마커 갯수
		max_spawn_count = 2,--최대 소환 갯수
		attack_radius = 10, --그로기 적용 범위
		aliment_gauge = 100, --그로기 증가 수치
		spawn_count = 2, --고정
		marker_group = {  --소환 시 같은 그룹은 같이 소환되지 않음
			{1, 2, 3, 4},
			{5, 6, 7, 8}},
		ignore_group = {
			{1, 5}, --같은 그룹은 같이 소환되지 않음
			{2, 6},
			{3, 7},
			{4, 8}},
		spawn_time = 25, --소환 딜레이 간격
		is_active = false -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
	}	
}