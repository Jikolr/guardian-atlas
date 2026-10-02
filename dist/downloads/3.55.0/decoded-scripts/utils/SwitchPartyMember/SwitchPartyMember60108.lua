return {
    bridgestory_seira = {
		-- 타겟 퀘스트 id
		quest_id = 60068,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'seira_seira', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'seira_seira' } },

		is_set_character_info = true
	},
	bridgestory_seira_pepper = {
		-- 타겟 퀘스트 id
		quest_id = 60069,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'pepper_pepper', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'pepper_pepper' } },

		is_set_character_info = true
	},
    bridgestory_seira_v_driver = {
      -- 타겟 퀘스트 id
      quest_id = 60070,

      -- 섹션별 세팅할 파티 멤버
      progress_data_list = {
      },

      -- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
      fallback_data = { switching_type = 'all', characters = { 'v_driver', } },

      -- 타겟 퀘스트를 클리어 했을 때 파티 멤버
      complete_data = { switching_type = 'all', characters = { 'v_driver' } },

      is_set_character_info = true
    },
	bridgestory_seira_epilogue = {
		-- 타겟 퀘스트 id
		quest_id = 60071,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'seira_epilogue', } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'seira_epilogue' } },

		is_set_character_info = true
	},
}
