return {
	--[[
		데이터 셋 구조

		스테이지_이름 = {
			narration_info =
			battle_group_name =
			wave_interval =
			last_wave =
			last_wave_boss_name =
		}
	]]
	tower_ice_52 = {
		narration_info = 'tower_ice_elite_7_narration',
		battle_group_name = 'wave',
		battle_group_names ={
			'wave1', 'wave2' ,'wave3', 'wave4', 'wave5'
		},
		last_wave = 4,
		last_wave_boss_name = 'wave_5_boss',
		wave_intervals = {
			10, 15, 20, 25, 40
		},
		wave_breaks = {
			3, 4, 4, 7
		},
		box_marker_names =
		{
			{ 'box_5' },
			{ 'box_5' },
			{ 'box_1', 'box_2', 'box_3', 'box_4' },
			{ 'box_5' }
		},
		box_interact_time = 0.5,
		box_heal_scale = 0.3
	},
	herotower_adela_noble_3 = {
		narration_info = 'tower_ice_elite_7_narration',
		battle_group_name = 'battle',
		battle_group_names ={
			'battle1', 'battle2' ,'battle3', 'battle4'
		},
		last_wave = 3,
		last_wave_boss_name = 'battle4_boss',
		wave_intervals = {
			30, 30, 30, 50
		},
		wave_breaks = {
			5, 5, 5
		},
		box_marker_names =
		{
			{ 'box_1' },
			{ 'box_2' },
			{ 'box_3'}
		},
		box_interact_time = 1,
		box_heal_scale = 0.05
	}
}
