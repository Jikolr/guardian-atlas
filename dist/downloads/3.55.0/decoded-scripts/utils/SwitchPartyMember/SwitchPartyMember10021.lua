return {
	--region WaterWorld
	waterworld_1 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'add', characters = { 'ww_princess' } },
			[1] = { switching_type = 'add', characters = { 'ww_princess' } },
			[2] = { switching_type = 'add', characters = { 'ww_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'ww_princess' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'ww_princess' } },

		is_set_character_info = true
	},

	waterworld_2 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[3] = { switching_type = 'add', characters = { 'ww_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = {} },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = {} },

		is_set_character_info = true
	},

	waterworld_3 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[8] = { switching_type = 'add', characters = { 'ww_princess', 'ww_wrestler' } },
			[9] = { switching_type = 'add', characters = { 'ww_princess', 'ww_wrestler' } },
			[10] = { switching_type = 'add', characters = { 'ww_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'ww_princess' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'ww_princess' } },

		is_set_character_info = true
	},

	waterworld_4 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[11] = { switching_type = 'add', characters = { 'ww_princess' } },
			[12] = { switching_type = 'add', characters = { 'ww_princess' } },
			[13] = { switching_type = 'add', characters = { 'ww_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'ww_princess' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'ww_princess' } },

		is_set_character_info = true
	},

	waterworld_5 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[14] = { switching_type = 'all', characters = { 'ww_wrestler' } },
			[15] = { switching_type = 'all', characters = { 'ww_wrestler' } },
			[16] = { switching_type = 'all', characters = { 'ww_wrestler' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ww_wrestler' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ww_wrestler' } },

		is_set_character_info = true
	},

	waterworld_6 = {
		-- 타겟 퀘스트 id
		quest_id = 465,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[17] = { switching_type = 'add', characters = {} },
			[18] = { switching_type = 'add', characters = {} },
			[23] = { switching_type = 'add', characters = {} },
			[24] = { switching_type = 'add', characters = {} },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = {} },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = {} },

		is_set_character_info = true
	},

	substage_21_1 = {
		-- 타겟 퀘스트 id
		quest_id = 476,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'ww_pirate' } },
			[1] = { switching_type = 'all', characters = { 'ww_pirate' } },
			[2] = { switching_type = 'all', characters = { 'ww_pirate' } },
			[3] = { switching_type = 'all', characters = { 'ww_pirate' } },
			[4] = { switching_type = 'all', characters = { 'ww_pirate' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ww_pirate' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ww_pirate' } },

		is_set_character_info = true
	},

	substage_21_2 = {
		-- 타겟 퀘스트 id
		quest_id = 477,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'add', characters = { 'ww_mermaid_spy' } },
			[1] = { switching_type = 'all', characters = { 'ww_knight_pink_soldier', 'ww_mermaid_spy_pink_soldier' } },
			[2] = { switching_type = 'all', characters = { 'ww_knight_pink_soldier', 'ww_mermaid_spy_pink_soldier' } },
			[3] = { switching_type = 'all', characters = { 'ww_knight_pink_soldier' } },
			[4] = { switching_type = 'add', characters = { 'ww_mermaid_spy_battle' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'ww_mermaid_spy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'ww_mermaid_spy' } },

		is_set_character_info = true
	},
	--endregion WaterWorld
}
