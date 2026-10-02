--[[
	스테이지명 = {
		target_sprite_name = 발화상태인 적에게 표시해줄 스프라이트 이름
		damage_modifier = 데미지 수정치
		damage_interval = 데미지 들어가는 인터벌 시간 (sec)
		fx_name = 발화상태의 적에게 표시될 이펙트 (임시)
		support_action_count = 연계기 배틀액션 몇번 맞았을 경우 발화상태 취소 되는지
		accumulate_count_time_over = 몇초동안 연계기 누적(갱신)되지 않으면 누적 취소 처리함.
		fx_support_bead_name = 보스 주변에 위치할 이펙트, 연계기 카운트와 연동함
		bead_fx_distance = 보스에서 구슬 얼마나 떨어져 있는지. 거리 (해당 값 필요할지 아닐지 논의 필요 ex. 이펙트 자체가 이동하는 경우 등)
		is_continuous_action_needs = 연계기를 넣어야만 취소 가능한지
	}
]]
return {
	battle_test_5 = {
		target_sprite_name = '',
		damage_modifier = 0.01,
		damage_interval = 0.25,
		support_action_count = 8,
		accumulation_time_over = 2.5,
		fx_support_bead_name = 'fx_balock_fireball_start',
		fx_support_bead_end_name = 'fx_balock_fireball_end',
		bead_fx_distance = 4.25,
		is_continuous_action_needs = true,
		rotate_speed = 15,
		screen_effect_name = 'fx_balock_danger_screen',
		screen_effect_end_name = 'fx_balock_danger_screen_end'
	},
	expedition_battle_test_7 = {
		target_sprite_name = '',
		damage_modifier = 0.01,
		damage_interval = 0.25,
		support_action_count = 8,
		accumulation_time_over = 4.5,
		fx_support_bead_name = 'fx_balock_fireball_start',
		fx_support_bead_end_name = 'fx_balock_fireball_end',
		bead_fx_distance = 4.25,
		is_continuous_action_needs = true,
		rotate_speed = 15,
		screen_effect_name = 'fx_balock_danger_screen',
		screen_effect_end_name = 'fx_balock_danger_screen_end'
	},
	expedition_battle_chosenone_1_boss = {
		target_sprite_name = '',
		damage_modifier = 0.1,
		damage_interval = 0.2,
		support_action_count = 8,
		accumulation_time_over = 10,
		fx_support_bead_name = 'fx_balock_fireball_start',
		fx_support_bead_end_name = 'fx_balock_fireball_end',
		bead_fx_distance = 4.25,
		is_continuous_action_needs = true,
		rotate_speed = 15,
		screen_effect_name = 'fx_balock_danger_screen',
		screen_effect_end_name = 'fx_balock_danger_screen_end'
	},
	single_raid_balock = {
		target_sprite_name = '',
		damage_modifier = 0.05,
		damage_interval = 0.25,
		support_action_count = 4,
		accumulation_time_over = 10,
		fx_support_bead_name = 'fx_balock_fireball_start',
		fx_support_bead_end_name = 'fx_balock_fireball_end',
		bead_fx_distance = 4.25,
		is_continuous_action_needs = true,
		rotate_speed = 15,
		screen_effect_name = 'fx_balock_danger_screen',
		screen_effect_end_name = 'fx_balock_danger_screen_end'
	}
}
