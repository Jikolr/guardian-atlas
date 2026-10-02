--[[ 스테이지 데이터 정보
	스테이지 이름 = {
		description = 스테이지 시작 시 설명
		attack_range_show_duration = 어택레인지 보여주는 시간, 음수면 안 보여줌,
		idle_duration = 범위 공격 생성 후 대기 시간,
		attack_modifier = 범위 공격 공격력 비율,
		damage_term = 범위 공격 사이 간격 시간,
		knock_back_force = 넉백 수치,
		max_hit_count = 즉사 카운트 수,
		stage_boss_name = 체력 기준 삼을 스테이지 필드 오브젝트 이름,
		effect_start_name = 시작 이펙트 이름,
		effect_loop_name = 루프 이펙트 이름,
		effect_end_name = 종료 이펙트 이름,
		wind_infos = {
			{
				wind_count = 생성되는 모래 폭풍 갯수,
				move_speed = 이동 속도,
				radius = 모래 폭풍 반지름,
				hp = 다음 페이즈로 전환 hp% 0 - 100,
				orbit = 공전 반지름,
				orbital_speed = 공전 속도
			},
			...
		}
}
]]
return {
	tower_earth_55 = {
		description = 'tower_earth_boss_7_narration',
		attack_range_show_duration = 0.5,
		idle_duration = 1.5,
		damage_modifier = 0.021,
		damage_term = 1,
		knock_back_force = 1.5,
		max_hit_count = 10,
		stage_boss_name = 'boss',
		effect_infos = {
			effect_start_name = nil,
			effect_loop_name = 'FX_SandwindOrange_proj',
			effect_end_name = 'FX_SandwindOrange_proj_end',
		},
		sfx_infos = {
			start_info = {
				sfx_name = '01_evolution_01',
				max_distance = nil,
				min_distance = nil,
				fade_in_time = nil,
				fade_out_time = nil,
				volume = nil,
				pitch = nil
			},
			loop_info = {
				sfx_name = '01_blizzard_01',
				max_distance = nil,
				min_distance = nil,
				fade_in_time = 1,
				fade_out_time = nil,
				volume = 0.7,
				pitch = nil
			},
			end_info = {
				sfx_name = '02_instant_heal_stomp_01',
				max_distance = nil,
				min_distance = nil,
				fade_in_time = nil,
				fade_out_time = nil,
				volume = nil,
				pitch = nil
			}
		},
		wind_infos = {
			{
				wind_count = 1,
				move_speed = 2,
				radius = 1,
				hp = 70,
				orbit = 0,
				orbital_speed = 2.5
			},
			{
				wind_count = 2,
				move_speed = 2.2,
				radius = 1,
				hp = 30,
				orbit = 1.3,
				orbital_speed = 3
			},
			{
				wind_count = 3,
				move_speed = 2.4,
				radius = 1,
				hp = 0,
				orbit = 1.8,
				orbital_speed = 3
			},
		}
	}
}
