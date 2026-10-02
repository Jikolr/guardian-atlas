return {
	--['tilemap_name'] = {
	--	target_grids = {
	--		['visual_name'] = {
	--			'grid_1',
	--			'grid_2',
	--			'grid_3',
	--		}
	--	},
	--},
	--region LaboseWorld

	['laboseworld_1'] = {
		target_grids = {
			['controller_CW'] = {
				'cw_grid',
				'proj_fail_grid',
			},
			['controller_CR'] = {
				'cr_grid'
			}
		},
	},
	['laboseworld_2'] = {
		target_grids = {
			['controller_CW'] = {
				'cw_grid',
				's7_puzzle_area',
				's7_running_polices_grid',
			},
			['controller_DW'] = {
				'dw_grid',
			}
		},
	},
	['laboseworld_3'] = {
		fixed_visual = 'controller_CR'
	},
	['laboseworld_4'] = {
		fixed_visual = 'controller_CR'
	},
	['laboseworld_5'] = {
		fixed_visual = 'controller_CW'
	},
	['laboseworld_6'] = {
		target_grids = {
			['controller_OW'] = {
				'ow_grid',
			},
			['controller_CR'] = {
				'cr_grid',
			},
		},
	},
	['laboseworld_7'] = {
		target_grids = {
			['controller_CW'] = {
				'cw_grid',
			},
			['controller_CR'] = {
				'cr_grid',
			},
			['controller_OW'] = {
				'ow_grid',
				'ow_normal_grid',
				'empty_grid'
			},
			['controller_DW'] = {
				'dw_grid',
			},
		},
	},
	['lw_sub_lana'] = {
		fixed_visual = 'controller_DW'
	},
	['lw_sub_demonshire'] = {
		fixed_visual = 'controller_CW'
	},
	['lw_sub_lilith'] = {
		target_grids = {
			['controller_CW'] = {
				'cw_grid',
			},
			['controller_DW'] = {
				'dw_grid',
			},
		},
	},
	['lw_sub_kaden'] = {
		fixed_visual = 'controller_CR'
	},
	['passage_18_1'] = {
		fixed_visual = 'controller_CW'
	},
	['passage_18_2'] = {
		fixed_visual = 'controller_DW'
	},
	['passage_18_3'] = {
		fixed_visual = 'controller_CW'
	},
	['passage_18_4'] = {
		fixed_visual = 'controller_OW'
	},

	['eventrift_19'] = {
		fixed_visual = 'controller_CW'
	},
	['eventrift_29'] = {
		fixed_visual = 'controller_CW'
	},

	['eventrift_39'] = {
		fixed_visual = 'controller_DW'
	},
	['eventrift_49'] = {
		fixed_visual = 'controller_DW'
	},

	['eventrift_59'] = {
		fixed_visual = 'controller_CW'
	},
	['eventrift_69'] = {
		fixed_visual = 'controller_CW'
	},

	--endregion LaboseWorld

	--region ShortStorySlime
	['shortstory_slime'] = {
		target_grids = {
			['controller_demon'] = {
				'demon_grid',
			},
			['controller_civil'] = {
				'explore_spa_grid',
				'explore_medicinal_herb_grid',
				'village_grid',
				'civil_grid'
			},
			['default'] = {
				'grid'
			}
		},
	},
	--endregion ShortStorySlime

	--region PixyWrold
	['pixyworld_4'] = {
		target_grids = {
			['controller_town'] = {
				'town_grid',
			},
			['controller_pixy'] = {
				'grid'
			},
		},
	},

	['pixyworld_6'] = {
		target_grids = {
			['controller_pixyworld'] = {
				'pixy_grid',
			},
			['controller_town'] = {
				'town_grid',
				'puzzle_grid',
				'red_town_grid',
				'default_town_grid'
			},
		},
	},

	['substage_19_1'] = {
		target_grids = {
			['controller_town'] = {
				'town',
			},
			['controller_pixyworld'] = {
				'grid',
			},
		},
	},

	['pw_sub_east'] = {
		target_grids = {
			['controller_lab'] = {
				'lab',
			},
			['controller_pixyworld'] = {
				'grid',
			},
		},
	},

	['substage_19_2'] = {
		target_grids = {
			['controller_town'] = {
				'town_grid',
			},
			['controller_pixy'] = {
				'grid'
			},
		},
	},

	--endregion PixyWrold


	--region ShortStoryMilkyway
	['shortstory_milkyway'] = {
		target_grids = {
			['controller_daylight'] = {
				'daylight_grid',
				'daylight_central_square_grid',
				'daylight_accommodation_grid',
				'daylight_concert_grid',
				'grid',
			},
			['controller_night'] = {
				'night_grid',
				'night_concert_grid'
			},
			['controller_in'] = {
				'in_grid'
			}
		},
	},
	--endregion ShortStoryMilkyway

	--region DreamVillage
	['dreamvillage_2'] = {
		target_grids = {
			['controller_daylight'] = {
				's7_infinite_grid',
				'grid',
			},
			['controller_cave2'] = {
				'cave_grid_1',
				'cave_grid_2',
				'cave_grid_3',
				'cave_grid_4',
				'yokai_statue'
			},
		},
	},

	['dreamvillage_3'] = {
		target_grids = {
			['controller_daylight'] = {
				'yokai_statue',
				'inn_grid_1',
				'inn_grid_2',
				'inn_grid_3',
				'grid',
			},
			['controller_cave2'] = {
				'cave_grid_1',
				'cave_grid_2',
				'cave_grid_3',
				'cave_grid_4',
				'cave_grid_5',
				'cave_grid_6'
			},
		},
	},

	['dreamvillage_4'] = {
		target_grids = {
			['controller_daylight'] = {
				'yokai_statue',
				'grid',
			},
			['controller_cave2'] = {
				'cave_grid_1',
			},
		},
	},
	--endregion DreamVillage

	--region ShortStoryFrieren
	['shortstory_frieren'] = {
		target_grids = {
			['controller_frieren'] = {
				'grid',
				'elf_puzzle_grid'
			},
			['controller_frieren_dun'] = {
				'dungeon_grid',
				'dungeon_puzzle_grid_1',
				'dungeon_puzzle_grid_2',
				'dungeon_puzzle_grid_3',
				'dungeon_puzzle_grid_4',
				'dungeon_puzzle_grid_reset',
				'dungeon_puzzle_grid_center',
				'dungeon_grid_boss'
			}
		}
	}
	--endregion ShortStoryFrieren




}
