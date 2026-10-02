-- 기믹의 정보를 담고 있는 구조체
-- Key : 스테이지 이름
-- horizontal_names : 가로 라인 레이저 오브젝트
-- vertical_names : 세로 라인 레이저 오브젝트

-- attack_range_distance : 위험알림 영역 길이
-- attack_range_radius : 위험알림 영역 넓이

-- hp_list : 보스 체력 페이즈 리스트
-- laser_delay_time : 위험알림 영역 표기 시간 과 레이저 생성 딜레이 시간
-- laser_active_time : 위험알림 영역 이후 레이저 활성화 딜레이 시간
-- laser_damage_rate : 레이저 데미지 laser_damage_rate
-- laser_damage_type : 레이저 데미지 타입.

-- description : 스테이지 시작 이후 보여줄 기믹 설명 문자열 키

return {
	tower_fire_45 = {
		horizontal_names = {
			'laser_1',
			'laser_2',
			'laser_3',
			'laser_4',
			'laser_5',
			'laser_6'
		},
		vertical_names = {
			'laser_13',
			'laser_14',
			'laser_15',
			'laser_16'
		},

		attack_range_distance = 20,
		attack_range_radius = 0.5,

		boss_name = 'boss',
		gimmick_start_zone_names = 'boss',

		hp_list = { 80, 60, 40, 20 },

		laser_delay_time = 5.7,
		laser_active_time = 0.3,
		laser_damage_rate = 0.34,
		laser_damage_type = 'Trap',

		description = 'tower_fire_boss_5_narration'
		}
}
