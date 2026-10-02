return {
	shortstory_clevatess = {
		-- 타겟 퀘스트 id
		quest_id = 7002101,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'ct_klen' } },
			[1] = { switching_type = 'all', characters = { 'ct_klen', 'ct_neruru_luna' } },
			[2] = { switching_type = 'all', characters = { 'ct_alicia', 'ct_klen' } },
			[3] = { switching_type = 'all', characters = { 'ct_alicia', 'ct_klen', 'ct_neruru_luna' } },
			[4] = { switching_type = 'all', characters = { 'ct_alicia_2' } },
			[5] = { switching_type = 'all', characters = { 'ct_alicia_2', 'ct_klen' } },
			[6] = { switching_type = 'all', characters = { 'ct_alicia_3', 'ct_klen' } },
			[7] = { switching_type = 'all', characters = { 'ct_alicia_3', 'ct_klen' } },
			[8] = { switching_type = 'all', characters = { 'ct_alicia_3', 'ct_klen' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ct_alicia', 'ct_klen' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ct_alicia_3', 'ct_klen' } },

		is_set_character_info = true
	},
}
