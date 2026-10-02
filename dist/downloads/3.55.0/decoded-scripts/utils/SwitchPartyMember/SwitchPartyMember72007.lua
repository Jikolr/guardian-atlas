return {
	--region CarpGirl
	memorial_carp_girl = {
		-- 타겟 퀘스트 id
		quest_id = 7200107,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'mm_cg_carp_girl', } },
			[2] = { switching_type = 'all', characters = { 'mm_cg_carp_girl', } },
			[3] = { switching_type = 'all', characters = { 'mm_cg_carp_girl', 'mm_cg_civilian_male_1', } },
			[5] = { switching_type = 'all', characters = { 'mm_cg_carp_girl', } },
			[7] = { switching_type = 'all', characters = { 'mm_cg_carp_girl_myth', } },
			[8] = { switching_type = 'all', characters = { 'mm_cg_shuran', } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'mm_cg_carp_girl', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'mm_cg_carp_girl', } },

		is_set_character_info = true
	},
	--endregion CarpGirl
}
