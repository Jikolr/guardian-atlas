return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- narration : 스테이지 시작시 출력할 나레이션 (없으면 출력안함)
	-- spike_total_count : 가시블록 충 개수
	-- spawn_marker_name : 마커 명칭(숫자 제외)
	-- marker_total_count : 배치되어있는 마커 총 개수
	-- spike_start_zone : 대기 존 명칭
	-- spike_end_zone : 목표 존 명칭
	-- spike_destroy_vfx = 가시 블록 폭발 이펙트
	-- spike_destroy_sfx = 가시 블록 폭발 사운드
	-- spike_warp_vfx = 가시 블록 생성/소멸 이펙트
	-- chest_box_group = {
	-- 		{
	-- 			chest_box_1 : chest_box 핸들 네임 1
	-- 			chest_box_2 : chest_box 핸들 네임 2,
	-- 			wall_direction : 관통 방지 판정 생성 방향
	-- 		}
	-- }
	-- chest_destroy_vfx : chest_box 폭발 이펙트,
	-- chest_destroy_sfx : chest_box 폭발 사운드,
	-- waves = {
	-- 		patterns : 가시블록 패턴 정보 = {
	-- 			마커 번호들 (예시 : {2, 4, 5, 6})
	-- 		}
	--		interval : 가시 블록이 소환된 이후 대기하는 시간
	-- 		speed : 가시블록 이동속도
	-- }
	]] --
	tower_none_48 = {
		--narration = 'tower_earth_boss_3_narration',
		spike_total_count = 20,
		spike_name = 'tb_',
		spawn_marker_name = 'marker_',
		marker_total_count = 11,
		spike_start_zone = 'start',
		spike_end_zone = 'end',
		spike_destroy_vfx = 'FX_Explosion_Bomb_small',
		spike_destroy_sfx = '03_rock_break_01',
		spike_warp_vfx = 'FX_reset_object',
		chest_box_group = {
			{
				chest_box_1 = 'chest_box_1',
				chest_box_2 = 'chest_box_2',
				wall_direction = 'up'
			},
			{
				chest_box_1 = 'chest_box_3',
				chest_box_2 = 'chest_box_4',
				wall_direction = 'down'
			}
		},
		chest_destroy_vfx = 'FX_Cin_Obj_RockExplosion',
		chest_destroy_sfx = '03_rock_break_01',
		waves = {
			{
				patterns = {
					{ 4, 5, 6 },
					{ 1, 2, 3 },
					{ 1, 5, 6 },
					{ 1, 2, 6 }
				},
				interval = 1.8,
				speed = 2
			},
			{
				patterns = {
					{ 8, 5, 6 },
					{ 1, 4, 5, 6 },
					{ 1, 2, 10 },
					{ 1, 2, 3, 6 }
				},
				interval = 1.8,
				speed = 2.3
			},
			{
				patterns = {
					{ 1, 9, 6 },
					{ 2, 3, 11 },
					{ 1, 9, 6 },
					{ 7, 4, 5 }
				},
				interval = 1.8,
				speed = 2.3
			},
			{
				patterns = {
					{ 1, 9, 6 },
					{ 7, 8, 11 },
					{ 8, 9, 10 },
					{ 7, 10, 11 },
					{ 1, 2, 5, 6}
				},
				interval = 1.6,
				speed = 2.3
			},
			{
				patterns = {
					{ 7, 8, 11 },
					{ 1, 9, 6 },
					{ 1, 2, 5, 6},
					{ 7, 10, 11 },
					{ 8, 9, 10 }
				},
				interval = 1.6,
				speed = 2.3
			}
		}
	}
}
