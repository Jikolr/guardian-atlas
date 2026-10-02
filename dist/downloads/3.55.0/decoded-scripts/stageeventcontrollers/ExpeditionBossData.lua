return {
	--[[
	[스테이지 id] = {
		controller = 연출용 컨트롤러
		param_table = {
		boss_id = 보스 몬스터 Id (웨이브에서 이름 순차 생성되므로 이름 말고 id 로 찾을수 있도록 수정됨)
			fall_angle = 낙하각도 (위쪽 기준 오른쪽으로 각도 증가),
			fall_distance = 낙하거리,
			fall_speed = 낙하속도
		}
	}
	]]
	[119990009] = {
		controller = 'ExpeditionBalock',
		param_table = {
			boss_id = 102776,
			fall_angle = 45,
			fall_distance = 20,
			fall_speed = 50,
			howl_y_offset = 6
		}
	},
	[250010007] = {
		controller = 'ExpeditionBalock',
		param_table = {
			boss_id = 102776,
			fall_angle = 15,
			fall_distance = 20,
			fall_speed = 50,
			howl_y_offset = 6
		}
	},
	[250011010] = {
		controller = 'ExpeditionBalock',
		param_table = {
			boss_id = 102776,
			fall_angle = 45,
			fall_distance = 20,
			fall_speed = 50,
			howl_y_offset = 4
		}
	},
	[250012010] = {
		controller = 'ExpeditionArachne',
		param_table = {
			boss_id = 103296,
			fall_angle = 0,
			fall_distance = 27,
			fall_speed = 14,
			howl_y_offset = 6
		}
	},
	[250013007] = {
		controller = 'ExpeditionIceDragon',
		param_table = {
			boss_id = 103642,
			howl_x_offset = 0,
			howl_z_offset = 0,
			breath_x_offset = 0,
			breath_z_offset = 0,
			stomp_camera_magnitude = 1,
			stomp_camera_duration = 1,
			howl_camera_magnitude = 1,
			howl_camera_duration = 1,
			knockback_force = 1
		}
	},
	[250014005] = {
		controller = 'ExpeditionClara',
		param_table = {
			boss_phase1_id = 104148,
			boss_phase2_id = 104149,
			knight_captain_id = 320023,
			boss_phase1_zone_name = 'battle_phase1',
			boss_phase2_zone_name = 'battle_phase2',
			appear_camera_magnitude = 0.25,
			appear_camera_duration = 0.1,
			s4_hidden_b_hp = 100,
			s4_hidden_b_hp_bar_height = 1,
			s4_hidden_b_hp_bar_width = 100,
			stage_tint_r = 75,
			stage_tint_g = 64,
			stage_tint_b = 64,
			use_hidden_b_effect = false
		}
	}
}
