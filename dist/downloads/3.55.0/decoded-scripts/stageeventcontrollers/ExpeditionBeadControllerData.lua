--[[
	스테이지명 = {
		bead_max_count = 최대 생성 갯수,
		max_duration = 생성된 구슬 유지 시간
		create_collide_range = 구슬 생성시에 이범위가 곂치지 않도록 생성,
		collide_range = 충돌 범위 ( 캐릭터가 범위 안으로 들어가면 충돌 처리 ),
		create_range = 주어진 위치내에서 랜덤하게 생성될 반경,
		bead_name = 모드1 비드 이펙트명
		bead_consume_name = 흡수될때 표시될 이펙트 (구슬위치)
		bead_hit_name = 흡수될때 표시될 이펙트 (캐릭터 위치)
	}
]]
return {
	battle_test_5 = {
		bead_max_count = 30,
		max_duration = 10,
		create_collide_range = 1.5,
		collide_range = 1,
		create_range = 2.5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	},
	expedition_battle_test_7 = {
		bead_max_count = 30,
		max_duration = 10,
		create_collide_range = 1.5,
		collide_range = 1,
		create_range = 2.5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	},
	expedition_battle_chosenone_1_boss = {
		bead_max_count = 6,
		max_duration = 15,
		create_collide_range = 2,
		collide_range = 2,
		create_range = 5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	},
	expedition_battle_chosenone_2_boss = {
		bead_max_count = 15,
		max_duration = 15,
		create_collide_range = 2,
		collide_range = 2,
		create_range = 5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	},
	expedition_battle_chosenone_3_boss = {
		bead_max_count = 15,
		max_duration = 15,
		create_collide_range = 2,
		collide_range = 2,
		create_range = 5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	},
	expedition_battle_chosenone_4_boss = {
		bead_max_count = 15,
		max_duration = 15,
		create_collide_range = 2,
		collide_range = 2,
		create_range = 5,
		bead_name = 'fx_balock_charging_ball_proj',
		bead_contrail_name = 'fx_balock_charging_ball_proj_contrail',
		bead_consume_name = 'fx_balock_charging_ball_proj_end'
	}
}
