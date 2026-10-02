
-- 스테이지별 곡옥장판.
return {
	battle_test_5 = {
		gogok_name = 'gogok_',
		gogok_count = 1,
		boss_name = 'boss_phase_2',
		marker_name = "red_marker_",
		revival_area_name = "revival_area_", --기믹 handleName
		revival_area_max_count = 1,
		revival_area_life_time = 25, --장판 소환 후 유지 시간
		marker_count = 1,
		monster_hit_radius = 3, --적 충돌 범위
		monster_damage_radius = 3, --충돌 후 데미지를 줄 범위?
		buff_hit_radius = 3, --캐릭터 충돌범위
		spawn_count = 1, --한번에 몇개 소환할건지?
		spawn_time = 10, --소환 딜레이
		max_count = 1, --소환 최대 갯수
		damage_rate = 0.1, --퍼센트데미지
		buff_id = 800053, --공격력증가 20초짜리
		buff_level = 0,
		is_active = true, -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
		zone_name = ''
	},
	co_exp_stage_2_4 = {
		gogok_name = 'gogok_',
		gogok_count = 1,
		boss_name = 'boss_phase_2',
		marker_name = "gogok_",
		revival_area_name = "revival_area_", --기믹 handleName
		revival_area_max_count = 1,
		revival_area_life_time = 25, --장판 소환 후 유지 시간
		marker_count = 1,
		monster_hit_radius = 1, --적 충돌 범위
		monster_damage_radius = 1, --충돌 후 데미지를 줄 범위?
		buff_hit_radius = 1, --캐릭터 충돌범위
		spawn_count = 1, --한번에 몇개 소환할건지?
		spawn_time = 25, --소환 딜레이
		max_count = 1, --소환 최대 갯수
		damage_rate = 0.01, --퍼센트데미지
		buff_id = 800053, --공격력증가 20초짜리
		buff_level = 0,
		is_active = false, -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
		zone_name = '' --존이름이있으면 존에 들어갔을 때 실행
	},
	co_exp_stage_2_4_hard = {
		gogok_name = 'gogok_',
		gogok_count = 1,
		boss_name = 'boss_phase_2',
		marker_name = "gogok_",
		revival_area_name = "revival_area_", --기믹 handleName
		revival_area_max_count = 1,
		revival_area_life_time = 25, --장판 소환 후 유지 시간
		marker_count = 1,
		monster_hit_radius = 1, --적 충돌 범위
		monster_damage_radius = 1, --충돌 후 데미지를 줄 범위?
		buff_hit_radius = 1, --캐릭터 충돌범위
		spawn_count = 1, --한번에 몇개 소환할건지?
		spawn_time = 25, --소환 딜레이
		max_count = 1, --소환 최대 갯수
		damage_rate = 0.01, --퍼센트데미지
		buff_id = 800053, --공격력증가 20초짜리
		buff_level = 0,
		is_active = false, -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
		zone_name = '' --존이름이있으면 존에 들어갔을 때 실행
	},
	co_exp_stage_2_4_super_hard = {
		gogok_name = 'gogok_',
		gogok_count = 1,
		boss_name = 'boss_phase_2',
		marker_name = "gogok_",
		revival_area_name = "revival_area_", --기믹 handleName
		revival_area_max_count = 1,
		revival_area_life_time = 25, --장판 소환 후 유지 시간
		marker_count = 1,
		monster_hit_radius = 1, --적 충돌 범위
		monster_damage_radius = 1, --충돌 후 데미지를 줄 범위?
		buff_hit_radius = 1, --캐릭터 충돌범위
		spawn_count = 1, --한번에 몇개 소환할건지?
		spawn_time = 25, --소환 딜레이
		max_count = 1, --소환 최대 갯수
		damage_rate = 0.01, --퍼센트데미지
		buff_id = 800053, --공격력증가 20초짜리
		buff_level = 0,
		is_active = false, -- true : BattleStartEvent가 불린 후 자동 시작, flase : 보스 등에서 컨트롤
		zone_name = '' --존이름이있으면 존에 들어갔을 때 실행
	}	
}