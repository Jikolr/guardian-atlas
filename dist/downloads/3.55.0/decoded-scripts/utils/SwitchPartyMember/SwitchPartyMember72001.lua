return {
	--region MemorialSquirrelGirl
	memorial_squirrel_girl = {
		-- 타겟 퀘스트 id
		quest_id = 7200101,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', } },
			[2] = { switching_type = 'all', characters = { 'manual_knight', 'sq_squirrel_girl' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight', 'sq_squirrel_girl' } },
			[4] = { switching_type = 'all', characters = { 'manual_knight', } },
			[5] = { switching_type = 'all', characters = { 'manual_knight', } },
			[6] = { switching_type = 'all', characters = { 'manual_knight', } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'sq_squirrel_girl' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'sq_squirrel_girl' } },

		is_set_character_info = true
	},

	--endregion MemorialSquirrelGirl
}
