return {
	--[[
	@pattern_data - 패턴 정보 목록, 각 테이블에는 아래 인자가 필요하다.
		@ boss_table : 동시에 죽여야 하는 보스의 정보 테이블. 2마리 이상도 가능
		@ boss_name : 보스 이름
		@ revive_dir : 부활 대기 시 보스가 바라볼 방향 ( default = dir 변경 없음 )
		@ revive_anim : 부활 대기 시 보스의 애니메이션 ( default = 애니메이션 없음 )
		@ revive_time : 보스 부활에 걸리는 시간 ( default = 5 )
		@ revive_hp : 보스 부활 시 체력 ( default = 0.5 )
		@ revive_tint : 부활 대기 시 틴트 ( default = { 0.3, 0.3, 0.3 })
		@ boss_group : 보스들이 속한 그룹 ( default = 'boss' )
	@ force_ban_revive : 강제로 GameOver에 부활 금지처리 할 것인지 (가급적이면 이 기능 말고, 부활 카운트를 0으로 하는 것을 권장함)

	@ 템플릿 ( 설명 : test_sub2 스테이지에 한번에 죽여야 하는 보스 그룹 1,2,3과 또 다른 그룹 4,5 미기재 부분은 default 값 적용 )
	test_sub_2 = {
		pattern_data = {
			{
				boss_table = {
					{ boss_name = 'boss_snowman_general_tower_1' },
					{ boss_name = 'boss_snowman_general_tower_2', revive_dir = 'down', revive_anim = 'monster_kneel'},
					{ boss_name = 'boss_snowman_general_tower_3', revive_dir = 'down', revive_anim = 'monster_kneel'}
				},
				revive_time = 5,
				revive_hp = 0.5,
				revive_tint = { 0.3 , 0.3, 0.3 }
				boss_group = 'boss'
			},
			{
				boss_table = {
					{ boss_name = 'boss_snowman_general_tower_4', revive_dir = 'down', revive_anim = 'monster_kneel'},
					{ boss_name = 'boss_snowman_general_tower_5', revive_dir = 'down', revive_anim = 'monster_kneel'}
				}
			}
		}
		force_ban_revive = true,
	}
	]]
	tower_fire_40 = {
		pattern_data = {
			{
				boss_table = {
					{ boss_name = 'boss_snowman_general', revive_dir = 'down', revive_anim = 'monster_kneel' },
					{ boss_name = 'boss_minister_tower', revive_dir = 'down', revive_anim = 'idle' }
				},
				revive_time = 5,
				revive_hp = 0.5,
				revive_tint = { 0.3, 0.3, 0.3 },
				boss_group = 'boss'
			}
		}
	},
	substage_blossom_2 = {
		pattern_data = {
			{
				boss_table = {
					{ boss_name = 'fake_warrior_1', revive_dir = 'right', revive_anim = 'prostrate'},
					{ boss_name = 'fake_warrior_2', revive_dir = 'left', revive_anim = 'prostrate'}
				},
				revive_time = 5,
				revive_hp = 0.5,
				revive_tint = { 0.3 , 0.3, 0.3 },
				boss_group = 'battle1'
			},
			{
				boss_table = {
					{ boss_name = 'fake_bow', revive_dir = 'right', revive_anim = 'prostrate'},
					{ boss_name = 'fake_sword', revive_dir = 'left', revive_anim = 'prostrate'},
				},
				revive_time = 5,
				revive_hp = 0.6,
				revive_tint = { 0.3 , 0.3, 0.3 },
				boss_group = 'boss'
			}
		}
	},
		herotower_kamael_5 = {
		pattern_data = {
			{
				boss_table = {
					{ boss_name = 'turret_poison', revive_dir = 'down', revive_anim = 'idle' },
					{ boss_name = 'debuff_def', revive_dir = 'up', revive_anim = 'idle' }
				},
				revive_time = 5,
				revive_hp = 0.5,
				revive_tint = { 0.3, 0.3, 0.3 },
				boss_group = 'boss'
			}
		}
	},
		force_ban_revive = true
	}
