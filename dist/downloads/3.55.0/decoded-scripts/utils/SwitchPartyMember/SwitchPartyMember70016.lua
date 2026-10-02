return {
	shortstory_noel = {
		-- 타겟 퀘스트 id
		quest_id = 7002201,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[12] = { switching_type = 'all', characters = { 'ss_noel_noel_myth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ss_noel_noel', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ss_noel_noel_myth' } },

		is_set_character_info = true
	},
}
