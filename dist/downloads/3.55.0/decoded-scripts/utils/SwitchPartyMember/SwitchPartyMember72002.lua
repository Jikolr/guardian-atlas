return {
	--region Bootcamp
	memorial_bootcamp = {
		-- 타겟 퀘스트 id
		quest_id = 7200102,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'bc_summer_android', } },
			[1] = { switching_type = 'all', characters = { 'bc_summer_android', } },
			[2] = { switching_type = 'all', characters = { 'bc_summer_android', } },
			[3] = { switching_type = 'all', characters = { 'bc_summer_android', } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'bc_summer_android', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'bc_summer_android', } },

		is_set_character_info = true
	},
	--endregion Bootcamp
}
