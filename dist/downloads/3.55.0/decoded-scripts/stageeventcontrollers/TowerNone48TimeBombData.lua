return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- target_groups = {
	-- 		{
	-- 			monsters : 위험 범위 적용할 몬스터들
	-- 			field_objects : 위험 범위 적용할 필드 오브젝트 핸들 네임들
	-- 			event_zone : 진입시 적용될 배틀 존
	-- 		}
	-- }
	-- manual_range_radius : 메뉴얼 캐릭터의 위험 범위 반지름
	-- monster_range_radius : 몬스터의 위험 범위 반지름
	-- field_object_range_radius : 필드 오브젝트의 위험 범위 반지름
	-- counter_limit : 즉사까지 남은 카운터
	-- explosion_vfx : 즉사시 표시할 이펙트
	-- force_ban_revive : 강제로 GameOver에 금지처리 할 것인지 (가급적이면 이 기능 말고, 부활 카운트를 0으로 하는 것을 권장함)
	-- stage_start_desc : 스테이지 시작하고서 발생하는 나레이션 박스
	]] --
	tower_none_43 = {
		target_groups = {
			{
				monsters = {'battle_1_1'},
				event_zone = 'battle_1'
			},
			{
				monsters = {'battle_2_1', 'battle_2_10'},
				event_zone = 'battle_2'
			},
			{
				monsters = {'battle_3_1'},
				event_zone = 'battle_3'
			},
			{
				field_objects = {'b1', 'b2', 'b3', 'b4', 'b5', 'b6'},
				event_zone = 'battle_4'
			},
			{
				field_objects = {'sl1', 'sl2'},
				event_zone = 'battle_5'
			}
		},
		manual_range_radius = 1.8,
		monster_range_radius = 2.5,
		field_object_range_radius = 2.2,
		counter_limit = 3,
		explosion_vfx = 'FX_FlameStrike'
	},
	substage_blossom_1 = {
		target_groups = {
			{
				monsters = {'battle_1_1', 'battle_1_2'},
				event_zone = 'battle1'
			},
			{
				field_objects = {'t1', 't2', 't3', 't4', 't5'},
				event_zone = 'puzzle'
			},
			{
				field_objects = {'t6', 't7', 't8', 't9'},
				event_zone = 'battle2'
			}
		},
		manual_range_radius = 2,
		monster_range_radius = 2,
		field_object_range_radius = 2,
		counter_limit = 4,
		explosion_vfx = 'FX_FlameStrike',
		force_ban_revive = true
	}
}
