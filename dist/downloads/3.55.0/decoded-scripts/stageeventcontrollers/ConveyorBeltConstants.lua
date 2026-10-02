local constants = {
	queenship = {
		belt_gimmick_name_hashset = {
			['[gimmick]beltC1'] = true,
			['[gimmick]beltC2'] = true,
			['[gimmick]beltL'] = true,
			['[gimmick]beltR'] = true,
			['[gimmick]beltS'] = true,
		},

		animation_name = 'queenship_belt_on',

		spine_offset = { 0, 0, 0 },
		spine_offset_adjust_dur = 0.3,

		sfx = {
			name = '01_belt_01',
			min_dist = 2,
			max_dist = 5,
			volume = 0.7
		},
	}
}

return {
	['queenship_1_6'] = {
		ammi_left_leg = {
			type = 'screenplay',

			speed = 3,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_ammi_left_leg_1'] = 'left',
				['conveyor_ammi_left_leg_2'] = 'down',
				['conveyor_ammi_left_leg_3'] = 'right',
			},

			animator_speed = 2.5,
			animation_name = constants.queenship.animation_name,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_ammi_left_leg_sfx'
		},
		star_piece = {
			type = 'screenplay',

			speed = 3,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_star_piece'] = 'right',
			},

			animator_speed = 2.5,
			animation_name = constants.queenship.animation_name,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_star_piece_sfx'
		},
		ammi_right_arm = {
			type = 'switchable',

			speed = 3,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_ammi_right_arm_1'] = 'up',
				['conveyor_ammi_right_arm_2'] = 'right',
				['conveyor_ammi_right_arm_3'] = 'down',
				['conveyor_ammi_right_arm_4'] = 'right',
				['conveyor_ammi_right_arm_5'] = 'down',
				['conveyor_ammi_right_arm_6'] = 'left',
				['conveyor_ammi_right_arm_7'] = 'down',
				['conveyor_ammi_right_arm_8'] = 'right',
				['conveyor_ammi_right_arm_9'] = 'down',
				['conveyor_ammi_right_arm_10'] = 'left',
				['conveyor_ammi_right_arm_11'] = 'down'
			},

			jumpable_zones = {
				'conveyor_ammi_right_arm_jumpable_1'
			},

			animator_speed = 2.5,
			animation_name = constants.queenship.animation_name,

			spine_offset = constants.queenship.spine_offset,
			spine_offset_adjust_dur = constants.queenship.spine_offset_adjust_dur,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_ammi_right_arm_sfx'
		},
		acting = {
			type = 'switchable',

			speed = 1.5,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_acting_1'] = 'down',
				['conveyor_acting_2'] = 'right',
				['conveyor_acting_3'] = 'down',
			},

			jumpable_zones = {
				'conveyor_acting_jumpable_1'
			},

			animator_speed = 1.25,
			animation_name = constants.queenship.animation_name,

			spine_offset = constants.queenship.spine_offset,

			spine_offset_adjust_dur = constants.queenship.spine_offset_adjust_dur,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_acting_sfx'
		},
		frog = {
			type = 'screenplay',

			speed = 1.5,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_frog'] = 'right',
			},

			animator_speed = 1.25,
			animation_name = constants.queenship.animation_name,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_frog_sfx'
		},
		area_2_puzzle = {
			type = 'screenplay',

			speed = 3,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['conveyor_puzzle_1'] = 'right',
				['conveyor_puzzle_2'] = 'down',
				['conveyor_puzzle_3'] = 'right',
				['conveyor_puzzle_4'] = 'down',
				['conveyor_puzzle_5'] = 'left'
			},

			animator_speed = 2.5,
			animation_name = constants.queenship.animation_name,

			sfx = constants.queenship.sfx,
			sfx_check_zone = 'conveyor_area_2_puzzle_sfx'
		},
	},
	['queenship_substage_among'] = {
		among_belt = {
			type = 'screenplay',

			speed = 3,

			belt_gimmick_name_hashset = constants.queenship.belt_gimmick_name_hashset,

			belt_zone_dict = {
				['express_enter_zone'] = 'left',
			},

			animator_speed = 2.5,
			animation_name = constants.queenship.animation_name,

			--sfx = constants.queenship.sfx,
			--sfx_check_zone = ''
		},
	}
}
