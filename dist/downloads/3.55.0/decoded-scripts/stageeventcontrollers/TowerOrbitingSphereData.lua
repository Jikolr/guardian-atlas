return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	--	boss_name : 구체가 따라다닐 몬스터 명칭
	--	sphere_projectile : 구체 이펙트
	--	proportional_damage_rate : 구체 피격시 부여할 체력 비례 대미지 비율
	--	damage_term : 대미지 간격
	--	knockback_factor : 넉백 인자
	--	knockback_modifier : 넉백 강도 (StandardForce * knockback_modifier)
	--	spheres = {
	--		{
	--			target_hp_rate : 생성될 목표 체력 (속도 테스트시 1로 하면 환인이 쉬움)
	--			sphere_radius : 판정 범위 반지름
	--			effect_size_multiplier : 생성된 이펙트의 초기 사이즈 기준으로 곱할 비율
	--			orbit_radius : 이동 궤도 반지름
	--			speed = 3 : 이동 속도
	--		},
	--	}
	]] --
	tower_none_50 = {
		boss_name = 'boss_admiral_hard_tower.none',
		sphere_projectile = 'fx_boss_waterball',
		sphere_trail = 'fx_boss_waterball_contrail',
		sphere_explosion = 'fx_boss_waterball_explosion',
		proportional_damage_rate = 0.1,
		damage_term = 0.5,
		knockback_factor = 0,
		knockback_modifier = 0,
		spheres = {
			{
				target_hp_rate = 1,
				sphere_radius = 0.8,
				effect_size_multiplier = 0.8,
				orbit_radius = 3,
				speed = 3
			},
			{
				target_hp_rate = 0.7,
				sphere_radius = 0.8,
				effect_size_multiplier = 0.8,
				orbit_radius = 4.5,
				speed = 4
			},
			{
				target_hp_rate = 0.4,
				sphere_radius = 0.8,
				effect_size_multiplier = 0.8,
				orbit_radius = 6,
				speed = 5
			}
		}
	}
}
