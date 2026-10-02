return {
	shortstory_battleball = {
		-- 타겟 퀘스트 id
		quest_id = 7002001,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'battleball_princess', 'bb_teaten_hero', 'bb_innuit' } },
			[1] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[2] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[3] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[4] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[5] = { switching_type = 'all', characters = { 'battleball_pitcher' } },

			[7] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[8] = { switching_type = 'all', characters = { 'battleball_girl_myth', 'battleball_pitcher_myth' } },
			[9] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[11] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[13] = { switching_type = 'all', characters = { 'battleball_girl_myth' } },
			[15] = { switching_type = 'all', characters = { 'battleball_pitcher_myth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'battleball_girl_myth', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'battleball_girl_myth', 'battleball_pitcher_myth' } },

		is_set_character_info = true
	},
}
