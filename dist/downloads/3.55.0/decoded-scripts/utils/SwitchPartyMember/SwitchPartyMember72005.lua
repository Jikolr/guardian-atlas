return {
	--region MagicalGirl
	memorial_thief = {
		-- 타겟 퀘스트 id
		quest_id = 7200105,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'mm_th_disguised_demon_inspector', } },
			[1] = { switching_type = 'all', characters = { 'mm_th_disguised_demon_inspector', } },
			[2] = { switching_type = 'all', characters = { 'mm_th_disguised_demon_inspector', } },
			[3] = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },
			[6] = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },
			[7] = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },
			[8] = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'mm_th_demon_inspector', } },

		is_set_character_info = true
	},
	--endregion MagicalGirl
}
