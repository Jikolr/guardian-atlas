--[[
	스테이지명 = {
		bead_max_count = 최대 생성 갯수,
		bead_move_speed = 구슬 움직일때 움직이는 속도,
		name = 보스 이름,
		create_collide_range = 구슬 생성시에 이범위가 곂치지 않도록 생성,
		collide_range = 충돌 범위 ( 캐릭터가 범위 안으로 들어가면 충돌 처리 ),
		create_range = 주어진 위치내에서 랜덤하게 생성될 반경,
		heal_ratio = 일반 구슬 먹었을때의 힐 비율,
		start_zone_name = 컨트롤러 시작 할 이벤트 존 이름,
		battle_end_group_name = 컨트롤러 종료될 전투
		bead1_name = 모드1 비드 이펙트명
		bead1_consume_name = 흡수될때 표시될 이펙트 (구슬위치)
		bead1_hit_name = 흡수될때 표시될 이펙트 (캐릭터 위치)
		bead2_name = 모드2 비드 이펙트명
		bead2_consume_name = 흡수될때 표시될 이펙트 (구슬위치)
		bead2_hit_name = 흡수될때 표시될 이펙트 (캐릭터 위치)
	}
]]
return {
	battle_test_5 = {
		bead_max_count = 30,
		bead_move_speed = 5,
		create_collide_range = 1.5,
		collide_range = 1,
		create_range = 2.5,
		heal_ratio = 0.1,
		battle_end_group_name = 'battle4',
		bead1_name = 'fx_blood_bead',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead2_name = 'fx_barrier_bead',
		bead2_consume_name = 'fx_barrier_bead_consume',
		bead2_hit_name = 'fx_barrier_bead_hit'
	},
	battle2 = {
		bead_max_count = 15,
		bead_move_speed = 2,
		create_collide_range = 1.5,
		collide_range = 1,
		create_range = 2.5,
		heal_ratio = 0.1,
		battle_end_group_name = 'battle1',
		bead1_name = 'fx_blood_bead',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead2_name = 'fx_priscilla_bead',
		bead2_consume_name = 'fx_priscilla_bead_consume',
		bead2_hit_name = 'fx_blood_bead_hit'
	},
	--주지사 중간보스 전투
	demonshire_3_3 = {
		bead_max_count = 15,
		bead_move_speed = 4,
		create_collide_range = 2,
		collide_range = 1.5,
		create_range = 3,
		heal_ratio = 0.018,
		battle_end_group_name = 'battle1',
		bead1_name = 'fx_blood_bead',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead2_name = 'fx_barrier_bead',
		bead2_consume_name = 'fx_barrier_bead_consume',
		bead2_hit_name = 'fx_barrier_bead_hit'
	},
	-- 최종 보스 전투
	demonshire_4_3 = {
		bead_max_count = 15,
		bead_move_speed = 3,
		create_collide_range = 2,
		collide_range = 1.5,
		create_range = 3,
		heal_ratio = 0.01,
		battle_end_group_name = 'battle1',
		bead1_name = 'fx_blood_bead',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead2_name = 'fx_priscilla_bead',
		bead2_consume_name = 'fx_priscilla_bead_consume',
		bead2_hit_name = 'fx_blood_bead_hit'
	},
	-- 원정대 3 최종보스
	expedition_battle_chosenone_3_boss =
	{
		bead_max_count = 15,
		bead_move_speed = 3,
		create_collide_range = 2,
		collide_range = 1.5,
		create_range = 3,
		heal_ratio = 0.01,
		battle_end_group_name = 'battle1',
		bead1_name = 'fx_blood_bead',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead2_name = 'fx_priscilla_bead',
		bead2_consume_name = 'fx_priscilla_bead_consume',
		bead2_hit_name = 'fx_blood_bead_hit'
	},
	-- 18 챕터 5연전
	laboseworld_6 =
	{
		bead_max_count = 15,
		bead_move_speed = 3,
		create_collide_range = 2,
		collide_range = 1.5,
		create_range = 3,
		heal_ratio = 0.001,
		battle_end_group_name = 'battle1',
		bead1_name = 'fx_blood_bead',
		bead1_hit_name = 'fx_blood_bead_hit',
		bead1_consume_name = 'fx_blood_bead_consume',
		bead2_name = 'fx_priscilla_bead',
		bead2_consume_name = 'fx_priscilla_bead_consume',
		bead2_hit_name = 'fx_blood_bead_hit'
	}
}
