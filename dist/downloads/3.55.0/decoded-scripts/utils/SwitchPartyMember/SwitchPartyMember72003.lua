return {
	--region MagicalGirl
	memorial_magical_girl = {
		-- 타겟 퀘스트 id
		quest_id = 7200103,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[1] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[2] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[3] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[4] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[5] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[6] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[7] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[8] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
			[9] = { switching_type = 'all', characters = { 'mm_mg_magical_girl', 'mm_mg_dog', } },
			[11] = { switching_type = 'all', characters = { 'mm_mg_magical_girl', 'mm_mg_dog', } },
			[12] = { switching_type = 'all', characters = { 'mm_mg_magical_girl', 'mm_mg_dog', } },
			[13] = { switching_type = 'all', characters = { 'mm_mg_magical_girl', 'mm_mg_dog', } },
			[14] = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'mm_mg_magical_girl_student', } },

		is_set_character_info = true
	},
	--endregion MagicalGirl
}
