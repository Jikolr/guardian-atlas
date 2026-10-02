return {
	--[[
		@ boss_table : 동시에 죽여야 하는 보스의 정보 테이블. 2마리 이상도 가능
		@ boss_name : 보스 이름
		@ revive_dir : 부활 대기 시 보스가 바라볼 방향 ( default = dir 변경 없음 )
		@ revive_anim : 부활 대기 시 보스의 애니메이션 ( default = 애니메이션 없음 )
		@ revive_time : 보스 부활에 걸리는 시간 ( default = 5 )
		@ revive_hp : 보스 부활 시 체력 ( default = 0.5 )
		@ revive_tint : 부활 대기 시 틴트 ( default = { 0.3, 0.3, 0.3 })
		@ boss_group : 보스들이 속한 그룹 ( default = 'boss' )
		@ boss_type : 1 - minister
		              2 - snowman
		              3 - minotours
	}
	]]
	tower_fire_50 = {
		{
			boss_table = {
				{
					is_switching = true,
					boss_info = {
					{ boss_name = 'boss_1_1', revive_dir = 'down', revive_anim = 'idle', boss_type = 1},
					{ boss_name = 'boss_2_1', revive_dir = 'down', revive_anim = 'monster_kneel', boss_type = 2},
					{ boss_name = 'boss_3_1', revive_dir = 'down', revive_anim = 'idle', boss_type = 3}}
				},
				{
					is_switching = true,
					boss_info = {
					{ boss_name = 'boss_1_2', revive_dir = 'down', revive_anim = 'monster_kneel', boss_type = 2},
					{ boss_name = 'boss_2_2', revive_dir = 'down', revive_anim = 'idle', boss_type = 3},
					{ boss_name = 'boss_3_2', revive_dir = 'down', revive_anim = 'idle', boss_type = 1}}
				},
				{
					is_switching = true,
					boss_info = {
						{ boss_name = 'boss_1_3', revive_dir = 'down', revive_anim = 'idle', boss_type = 3},
						{ boss_name = 'boss_2_3', revive_dir = 'down', revive_anim = 'idle', boss_type = 1},
						{ boss_name = 'boss_3_3', revive_dir = 'down', revive_anim = 'monster_kneel', boss_type = 2} }
				}
			},
			revive_time = 6,
			revive_hp = 0.7,
			revive_tint = { 0.3 , 0.3, 0.3 },
			boss_group = 'boss',
			narration_key = 'tower_fire_50_narration_key'
		}
	}
}
