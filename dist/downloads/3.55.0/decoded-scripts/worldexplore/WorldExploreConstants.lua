-- Constant values can be used in Succubus cafe and change immediatedly.
return {

	field_camera_size = 3.5,
	camera_speed = 20,
	max_camera_duration = 1.0,

	move_duration_per_tile = 0.1,
	max_move_duration = 0.5,

	hero_turn_focus_distance = 6,

	level_to_army = 0.2,
	army_to_display_hp = 1000,

	-- phases
	phases = {
		none = -6,
		stage_event_loading = -5,
		stage_event_loading_done = -4,
		start_event_running = -3,
		start_event_default = -2,
		start_event_done = -1,
		hero_turn_start = 0,
		hero_turn = 1,
		hero_turn_unit_move_range_preparing = 2,
		hero_turn_unit_move_range = 3,
		hero_turn_unit_moving = 4,
		hero_turn_unit_interacting = 5,
		hero_turn_unit_move_end = 6,
		hero_turn_end = 7,
		enemy_turn_start = 8,
		enemy_turn = 9,
		enemy_turn_end = 10,
		manual_battle = 11,
		army_battle = 12,
		town_visit = 13,
		focusing_hero = 14,
		clear_stage = 15,
		game_over = 16,
		npc_interacting = 17,
		npc_interacting_end = 18,
		inactive_town_visit = 19,
		ending_event_running = 20,
		ending_event_done = 21
	},

	event_types = {
		start_stage_event_load = 0,
		stage_launch_ready = 1,
		npc_interaction_start = 2,
		ending_ready = 3,
		manual_battle_start = 4,
		manual_battle_ended = 5
	},

	tap_types = {
		none = 0,
		active_player = 1,
		inactive_town_player = 2,
		range_blue_tap = 3,
		range_interactable_tap = 4,
		change_player = 5,
		change_player_with_focus = 6,
		empty_tap = 7
	},

	interactions = {
		stay = 0,
		open_treasure = 1,
		break_object = 2,
		battle = 3,
		talk = 4
	},

	town_levelup_costs =
	{
		{ wood = 5 },
		{ stone = 5 },
		{ wood = 5, stone = 5 },
		{ wood = 10, stone = 10 }
	},

	town_productions =
	{
		2,
		4,
		6,
		8,
		10
	},

	town_swordmen_costs =
	{
		{ amount = 2, gold = 2 },
		{ amount = 4, gold = 4 },
		{ amount = 6, gold = 6 },
		{ amount = 8, gold = 8 },
		{ amount = 10, gold = 10 }
	},

	town_riflemen_costs =
	{
		{ amount = 2, gold = 2 },
		{ amount = 4, gold = 4 },
		{ amount = 6, gold = 6 },
		{ amount = 8, gold = 8 },
		{ amount = 10, gold = 10 }
	},

	town_shieldmen_costs =
	{
		{ amount = 2, gold = 2 },
		{ amount = 4, gold = 4 },
		{ amount = 6, gold = 6 },
		{ amount = 8, gold = 8 },
		{ amount = 10, gold = 10 }
	},

	battlefield_states = {
		start = 0,
		centerfight = 1,
		othersidefight = 2,
		leaderfight = 3,
		done = 4,
		finished = 5
	},

	army_states = {
		marching = 0,
		bouncing = 1,
		stopped = 2,
		riflemen_blink = 3,
		melee_blink = 4,
		riflemen_recoil = 5,
	},

	enemy_ai_types = {
		none = 0,
		army_adding = 2,
		resource_seeking = 3,
	},

	battlefield_army_divider = 3,
	battlefield_army_offset = -2,
	battlefield_leader_offset = -3,
	battlefield_army_size = 0.02,
	battlefield_army_half_height = 0.2,
	battlefield_march_speed = 3.5,
	battlefield_camera_angle = 25
}
