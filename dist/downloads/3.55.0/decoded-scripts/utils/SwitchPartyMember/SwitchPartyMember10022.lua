return {
	--region Fireworld
	fireworld_1 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[1] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[2] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },

		is_set_character_info = true
	},

	fireworld_2 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[3] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[4] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[5] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[6] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[7] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy', 'fw_fire_bishop' } },
			[8] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy', 'fw_fire_bishop' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },

		is_set_character_info = true
	},

	fireworld_3 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[8] = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },
			[9] = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },
			[10] = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		is_set_character_info = true
	},

	fireworld_4 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[11] = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },
			[12] = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		is_set_character_info = true
	},

	fireworld_5 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[19] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy', 'fw_fire_bishop' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_fire_bishop', 'fw_dragon_boy' } },

		is_set_character_info = true
	},

	fireworld_6 = {
		-- 타겟 퀘스트 id
		quest_id = 478,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[23] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[24] = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },
			[28] = { switching_type = 'all', characters = { 'fw_eternal_flame' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'fw_princess', 'fw_dragon_boy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'fw_eternal_flame' } },

		is_set_character_info = true
	},

	substage_22_1 = {
		-- 타겟 퀘스트 id
		quest_id = 481,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'fw_steam_knight' } },
			[1] = { switching_type = 'all', characters = { 'fw_steam_knight' } },
			[2] = { switching_type = 'all', characters = { 'fw_steam_knight_dragon_doll' } },
			[3] = { switching_type = 'all', characters = { 'fw_steam_knight_dragon_doll' } },
			[4] = { switching_type = 'all', characters = { 'fw_steam_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'fw_steam_knight_dragon_doll' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'fw_steam_knight_dragon_doll'} },

		is_set_character_info = true
	},

	substage_22_2 = {
		-- 타겟 퀘스트 id
		quest_id = 480,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'fw_knight_sauna' } },
			[2] = { switching_type = 'all', characters = { 'fw_knight_sauna' } },
			[3] = { switching_type = 'all', characters = { 'fw_knight_sauna', 'fw_uptown_lancer_girl_hotspring' } },
			[4] = { switching_type = 'all', characters = { 'fw_knight_sauna' } },
			[5] = { switching_type = 'all', characters = { 'fw_knight_sauna', 'fw_uptown_lancer_girl_hotspring' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},
}
