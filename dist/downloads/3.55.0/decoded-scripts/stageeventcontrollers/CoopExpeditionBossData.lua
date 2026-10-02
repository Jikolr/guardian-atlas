return {
	[320010004] = {
		controller = 'CoopBossPan',
		param_table = {
			bosses = { 800001, 800002 },

			camera_size = 8.5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_pan_appear = 'fx_boss_pan_appear'
		},
	},
	[320011004] = {
		controller = 'CoopBossPan',
		param_table = {
			bosses = { 800003, 800004 },

			camera_size = 8.5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_pan_appear = 'fx_boss_pan_appear'
		},
	},
	[320012004] = {
		controller = 'CoopBossPan',
		param_table = {
			bosses = { 800636, 800637 },

			camera_size = 8.5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_pan_appear = 'fx_boss_pan_appear'
		},
	},
	[320020004] = {
		controller = 'CoopBossYaksha',
		param_table = {
			bosses = { 800485, 800486 },

			camera_size = 8,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			saya_marker_name = 'red_marker_',
			saya_stone_name = 'saya_stone_',
			saya_marker_count = 8, --사야봉인석과, 마커갯수는 동일해야함
			saya_stone_height = 9, --사야스톤 떨어지는 연출 생성 높이
			saya_stone_drop_speed = 10, --사야스톤 떨어지는 속도도

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_saya_sealstone_smoke = 'fx_saya_sealstone_smoke',
			fx_saya_sealstone_attack = 'fx_saya_sealstone_attack',
			fx_oni_phase2_start = 'fx_oni_phase2_start',
			fx_oni_phase2_end = 'fx_oni_phase2_end',
			fx_oni_teleport = 'fx_oni_teleport'
		},
	},
	[320021004] = {
		controller = 'CoopBossYaksha',
		param_table = {
			bosses = { 800487, 800488 },

			camera_size = 8,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			saya_marker_name = 'red_marker_',
			saya_stone_name = 'saya_stone_',
			saya_marker_count = 8, --사야봉인석과, 마커갯수는 동일해야함
			saya_stone_height = 9, --사야스톤 떨어지는 연출 생성 높이
			saya_stone_drop_speed = 10, --사야스톤 떨어지는 속도도

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_saya_sealstone_smoke = 'fx_saya_sealstone_smoke',
			fx_saya_sealstone_attack = 'fx_saya_sealstone_attack',
			fx_oni_phase2_start = 'fx_oni_phase2_start',
			fx_oni_phase2_end = 'fx_oni_phase2_end',
			fx_oni_teleport = 'fx_oni_teleport'
		},
	},
	[320022004] = {
		controller = 'CoopBossYaksha',
		param_table = {
			bosses = { 800638, 800639 },

			camera_size = 8,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			saya_marker_name = 'red_marker_',
			saya_stone_name = 'saya_stone_',
			saya_marker_count = 8, --사야봉인석과, 마커갯수는 동일해야함
			saya_stone_height = 9, --사야스톤 떨어지는 연출 생성 높이
			saya_stone_drop_speed = 10, --사야스톤 떨어지는 속도도

			fx_npc_appear_name = 'fx_boss_Pan_NPC_appear',
			fx_saya_sealstone_smoke = 'fx_saya_sealstone_smoke',
			fx_saya_sealstone_attack = 'fx_saya_sealstone_attack',
			fx_oni_phase2_start = 'fx_oni_phase2_start',
			fx_oni_phase2_end = 'fx_oni_phase2_end',
			fx_oni_teleport = 'fx_oni_teleport'
		},
	},
	[320031004] = {
		controller = 'CoopBossSnake',
		param_table = {
			bosses = { 800645, 800646 },

			camera_size = 5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,
			camera_zoom_size = 5,

			camera_magnitude1 = 0.4,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_phase2_camera = 'fx_co_ex_s2_snow_wind',
			fx_phase2_sfx = '01_blizzard_03',
			fx_phase2_sfx_volume = 0.5,

			fx_phase2_start = 'fx_boss_snake_phaseshift',
			fx_phase2_screen = 'fx_boss_snake_phaseshift_screen',
			fx_oni_phase2_end = 'fx_boss_snake_appear',
			fx_phase2_aura = 'fx_boss_snake_aura',

			visual_template = 'expedition_s2_boss'
		},
	},
	[320030004] = {
		controller = 'CoopBossSnake',
		param_table = {
			bosses = { 800643, 800644 },

			camera_size = 5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,
			camera_zoom_size = 5,

			camera_magnitude1 = 0.4,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_phase2_camera = 'fx_co_ex_s2_snow_wind',
			fx_phase2_sfx = '01_blizzard_03',
			fx_phase2_sfx_volume = 0.5,

			fx_phase2_start = 'fx_boss_snake_phaseshift',
			fx_phase2_screen = 'fx_boss_snake_phaseshift_screen',
			fx_oni_phase2_end = 'fx_boss_snake_appear',
			fx_phase2_aura = 'fx_boss_snake_aura',

			visual_template = 'expedition_s2_boss'
		},
	},
	[320040003] = {
		controller = 'CoopBossSelector',
		param_table = {
			bosses = { 800815, 800816 },

			camera_size = 5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,
			camera_zoom_size = 5,

			camera_magnitude1 = 0.4,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_teleport = 'fx_boss_selecter_findfake_teleport_phase',
			fx_teleport_end = 'fx_boss_selecter_findfake_teleport_phase_end',
			fx_phase2_phase_shift = 'fx_boss_selecter_phaseshift',
			fx_phase2_shout = 'fx_boss_selecter_findfake_shout',

			fx_phase2_camera = 'fx_co_ex_s2_snow_wind',
			fx_phase2_sfx = '01_blizzard_03',
			fx_phase2_sfx_volume = 0.5,

			visual_template = 'expedition_s2_boss'
		},
	},
	[320041003] = {
		controller = 'CoopBossSelector',
		param_table = {
			bosses = { 800817, 800818 },

			camera_size = 5,
			camera_magnitude = 0.5,
			camera_duration = 1.4,
			shake_time = 0.15,
			camera_zoom_size = 5,

			camera_magnitude1 = 0.4,

			knockback_time = 1.4,
			knockback_force = 1.7,

			reset_duration = 0.3,

			fx_teleport = 'fx_boss_selecter_findfake_teleport_phase',
			fx_teleport_end = 'fx_boss_selecter_findfake_teleport_phase_end',
			fx_phase2_phase_shift = 'fx_boss_selecter_phaseshift',
			fx_phase2_shout = 'fx_boss_selecter_findfake_shout',

			fx_phase2_camera = 'fx_co_ex_s2_snow_wind',
			fx_phase2_sfx = '01_blizzard_03',
			fx_phase2_sfx_volume = 0.5,

			visual_template = 'expedition_s2_boss'
		},
	}
}
