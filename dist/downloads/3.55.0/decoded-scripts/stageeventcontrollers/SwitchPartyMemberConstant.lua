return {
	-- 스테이지 이름
	test_sub_1 = {
		-- 타겟 퀘스트 id
		quest_id = 311,

		-- 섹션별 세팅할 파티 멤버
		--TODO: 파티 맴버만 교체되는 기능일 경우 characters로 한번 더 묶는 부분 빼도 될듯
		--TODO: 팔로잉 NPC들은 파티원들 다음 인덱스로 세팅할 것
		-- all / exclude_leader / add
		progress_data_list = {
			[12] = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },
			[13] = { switching_type = 'all', characters = { 'manual_princess' } },
			[14] = { switching_type = 'all', characters = { 'manual_princess' } },
			[15] = { switching_type = 'all', characters = { 'manual_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },

		--TODO: 캐릭터 인포를 세팅 해줘야 특수 능력이 정상 작동 하기에 release-v2.81 버전 이후 부터는 무조건 true로 추가
		is_set_character_info = false,
	},

	--region Short Story Rosetta

	shortstory_rosetta = {
		-- 타겟 퀘스트 id
		quest_id = 7001301,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[2] = { switching_type = 'all', characters = { 'red_hood' } },
			[5] = { switching_type = 'all', characters = { 'red_hood' } },
			[6] = { switching_type = 'all', characters = { 'red_hood' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'red_hood' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'red_hood_battle_mode' } },
	},

	--endregion

	--region Short Story Dai

	shortstory_dai_1 = {
		-- 타겟 퀘스트 id
		quest_id = 7001401,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam' } },
			[1] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'hyunckel', 'gome' } },
			[2] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'hyunckel', 'gome' } },
			[3] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'hyunckel', 'gome' } },
			[4] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'hyunckel', 'gome' } },
			[5] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'hyunckel', 'gome' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'gome' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'gome' } },
	},

	shortstory_dai_2 = {
		-- 타겟 퀘스트 id
		quest_id = 7001401,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[6] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'gome' } },
			[7] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'gome' } },
			[8] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'gome' } },
			[9] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'princess_bat', 'leona', 'gome' } },
			[10] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'princess_bat', 'gome' } },
			[11] = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'princess_bat', 'gome' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'gome' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'dai', 'popp', 'maam', 'leona', 'gome' } },
	},

	--endregion

	--region queencastle

	queencastle_1_1 = {
		-- 타겟 퀘스트 id
		quest_id = 330,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },
			[4] = { switching_type = 'all', characters = { 'manual_knight' } },
			[9] = { switching_type = 'all', characters = { 'manual_knight', 'qc_teatan_hero'
			, 'qc_desert_slave', 'qc_tanker', 'qc_innuit' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	queencastle_1_2 = {
		-- 타겟 퀘스트 id
		quest_id = 330,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[5] = { switching_type = 'all', characters = { 'manual_knight' } },
			[6] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	queencastle_1_3 = {
		-- 타겟 퀘스트 id
		quest_id = 330,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[7] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[8] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_1_4 = {
		-- 타겟 퀘스트 id
		quest_id = 338,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_1_5 = {
		-- 타겟 퀘스트 id
		quest_id = 332,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_1_6 = {
		-- 타겟 퀘스트 id
		quest_id = 336,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[1] = { switching_type = 'all', characters = { 'qc_knight_maid', 'qc_hero_ai_maid' } },
			[2] = { switching_type = 'all', characters = { 'qc_knight_maid', 'qc_hero_ai_maid' } },
			[3] = { switching_type = 'all', characters = { 'qc_knight_maid', 'qc_hero_ai_maid' } },
			[4] = { switching_type = 'all', characters = { 'qc_knight_maid', 'qc_hero_ai_maid' } },
			[5] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[6] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_1_7 = {
		-- 타겟 퀘스트 id
		quest_id = 331,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			--[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[0] = { switching_type = 'all', characters = { 'qc_innuit_follow' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_innuit_follow' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_innuit_follow' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_innuit_follow' } },
			[4] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_1_8 = {
		-- 타겟 퀘스트 id
		quest_id = 330,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[10] = { switching_type = 'all',
					 characters = { 'manual_knight', 'qc_teatan_hero', 'qc_desert_slave', 'qc_tanker', 'qc_innuit' } },
			[11] = { switching_type = 'all',
					 characters = { 'manual_knight', 'qc_teatan_hero', 'qc_desert_slave', 'qc_tanker', 'qc_innuit' } },
			[12] = { switching_type = 'all',
					 characters = { 'manual_knight', 'qc_teatan_hero', 'qc_desert_slave', 'qc_tanker', 'qc_innuit' } },
			[13] = { switching_type = 'all',
					 characters = { 'manual_knight' } },
			[14] = { switching_type = 'all',
					 characters = { 'manual_knight' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	queencastle_substage_fall_guardian = {
		-- 타겟 퀘스트 id
		quest_id = 339,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all',
					characters = { 'qc_fg_manual_knight' } },
			[1] = { switching_type = 'all',
					characters = { 'qc_fg_manual_knight' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'qc_fg_manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'qc_fg_manual_knight' } },
	},

	queencastle_substage_lifesaving = {
		-- 타겟 퀘스트 id
		quest_id = 340,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_summer_android' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_summer_android', 'qc_bad_student_female' } },
			[5] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_summer_android'
			, 'qc_bad_student_female', 'qc_dungeon_succubus_a', 'qc_teatan_ninja', 'qc_succubus_researcher' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_summer_android' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai', 'qc_summer_android' } },
	},

	queencastle_substage_android_lab = {
		-- 타겟 퀘스트 id
		quest_id = 341,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight' } },
			[4] = { switching_type = 'all', characters = { 'manual_knight' } },
			[5] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},

	queencastle_substage_mario = {
		-- 타겟 퀘스트 id
		quest_id = 344,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'qc_mario_knight', 'qc_maria', 'qc_lisa' } },
			[1] = { switching_type = 'all', characters = { 'qc_mario_knight', 'qc_maria', 'qc_lisa' } },
			[2] = { switching_type = 'all', characters = { 'qc_mario_knight', 'qc_maria', 'qc_lisa' } },
			[3] = { switching_type = 'all', characters = { 'qc_mario_knight', 'qc_maria', 'qc_lisa' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'qc_mario_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'qc_mario_knight' } },
	},
	queencastle_substage_secret = {
		-- 타겟 퀘스트 id
		quest_id = 342,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'qc_hero_ai' } },
	},
	queencastle_substage_hidden_room = {
		-- 타겟 퀘스트 id
		quest_id = 354,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},
	--endregion

	--region Short Story Mermaid

	shortstory_mermaid = {
		-- 타겟 퀘스트 id
		quest_id = 7001501,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'mm_sohee', 'mm_yuze' } },
			[1] = { switching_type = 'all', characters = { 'mm_sohee', 'mm_yuze' } },
			[2] = { switching_type = 'all', characters = { 'mm_mermaid_country' } },
			[3] = { switching_type = 'all', characters = { 'mm_mermaid_country', 'mm_sohee' } },
			[4] = { switching_type = 'all', characters = { 'mm_mermaid_country' } },
			[5] = { switching_type = 'all', characters = { 'mm_mermaid', 'mm_sohee' } },
			[6] = { switching_type = 'all', characters = { 'mm_mermaid', 'mm_sohee' } },
			[7] = { switching_type = 'all', characters = { 'mm_mermaid' } },
			[8] = { switching_type = 'all', characters = { 'mm_mermaid' } },
			[9] = { switching_type = 'all', characters = { 'mm_mermaid' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'mm_mermaid' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'mm_mermaid' } },
	},

	--endregion

	--region civilwar

	civilwar_1 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight' } },
			[5] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_queen' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_2 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[7] = { switching_type = 'all', characters = { 'princess' } },
			[8] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_3 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[11] = { switching_type = 'all', characters = { 'princess' } },
			[12] = { switching_type = 'all', characters = { 'manual_demon_knight' } },
			[13] = { switching_type = 'all', characters = { 'manual_demon_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_demon_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_demon_knight' } },
	},

	civilwar_4 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[17] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[18] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[19] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[20] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[21] = { switching_type = 'all', characters = { 'princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
	},

	civilwar_5 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[22] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[23] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[24] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[25] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
			[26] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_engineer' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_6 = {
		-- 타겟 퀘스트 id
		quest_id = 357,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[27] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_queen' } },
			[28] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_queen' } },
			[29] = { switching_type = 'all', characters = { 'manual_knight', 'cw_demon_queen' } },
			[30] = { switching_type = 'all', characters = { 'manual_knight' } },
			[31] = { switching_type = 'all', characters = { 'manual_knight' } },
			[32] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_substage_lana = {
		-- 타겟 퀘스트 id
		quest_id = 364,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight', 'cw_onigirl', 'cw_onigirl_mother' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_substage_heavenhold_1 = {
		-- 타겟 퀘스트 id
		quest_id = 363,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	civilwar_substage_pymon = {
		-- 타겟 퀘스트 id
		quest_id = 366,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'cw_demon_powergirl' } },
			[1] = { switching_type = 'all', characters = { 'cw_demon_powergirl' } },
			[2] = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },
			[3] = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },
			[4] = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },
			[5] = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'cw_reine', 'cw_hela' } },
	},

	civilwar_substage_demonshire = {
		-- 타겟 퀘스트 id
		quest_id = 371,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'cw_half_vampire' } },
			[1] = { switching_type = 'all', characters = { 'cw_half_vampire', 'cw_vampire_captain' } },
			[2] = { switching_type = 'all', characters = { 'cw_half_vampire', 'cw_vampire_captain', 'cw_sheep_girl' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'cw_half_vampire' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'cw_half_vampire' } },
	},

	civilwar_substage_agit = {
		-- 타겟 퀘스트 id
		quest_id = 370,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },
	},

	--endregion

	--region Short Story Shuran

	shortstory_shuran = {
		-- 타겟 퀘스트 id
		quest_id = 7001601,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'shuran' } },
			[1] = { switching_type = 'all', characters = { 'shuran' } },
			[2] = { switching_type = 'all', characters = { 'shuran' } },
			[3] = { switching_type = 'all', characters = { 'shuran', 'jungpa_master' } },
			[4] = { switching_type = 'all', characters = { 'shuran', 'jungpa_master' } },
			[5] = { switching_type = 'all', characters = { 'shuran', 'jungpa_master', 'spirit_rabbit' } },
			[6] = { switching_type = 'all', characters = { 'shuran', 'jungpa_master', 'spirit_rabbit' } },
			[7] = { switching_type = 'all', characters = { 'shuran_battle', 'cyborg_monk_battle' } },
			[8] = { switching_type = 'all', characters = { 'shuran_battle', 'cyborg_monk_battle' } },
			[9] = { switching_type = 'all', characters = { 'shuran' } }
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'shuran' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'shuran', 'spirit_rabbit' } },
	},

	--endregion

	--region nightmare_lilithtower

	nightmare_lilithtower_1 = {
		-- 타겟 퀘스트 id
		quest_id = 380,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
	},

	nightmare_lilithtower_2 = {
		-- 타겟 퀘스트 id
		quest_id = 380,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[3] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
	},

	nightmare_lilithtower_3 = {
		-- 타겟 퀘스트 id
		quest_id = 380,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[4] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
			[5] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
	},

	nightmare_lilithtower_4 = {
		-- 타겟 퀘스트 id
		quest_id = 380,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[6] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
			[7] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
	},

	nightmare_lilithtower_5 = {
		-- 타겟 퀘스트 di
		quest_id = 380,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[8] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
			[9] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
			[10] = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_lt_trouble_shooter', 'nightmare_lt_mad_scientist' } },
	},

	--endregion nightmare_lilithtower

	--region laboseworld
	laboseworld_1 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버2
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	laboseworld_2 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[4] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[5] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[6] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer', 'lw_demon_queen' } },
			[7] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer', 'lw_demon_queen' } },
			[8] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버2
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },

		is_set_character_info = true
	},

	laboseworld_3 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[9] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[10] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[11] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[12] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
			[13] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_engineer' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버2
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	laboseworld_4 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버2
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	laboseworld_5 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[17] = { switching_type = 'all', characters = { 'manual_knight' } },
			[18] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_queen' } },
			[19] = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_queen' } },
			[20] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_queen' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'lw_demon_queen' } },

		is_set_character_info = true
	},

	laboseworld_6 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[21] = { switching_type = 'all', characters = { 'manual_knight' } },
			[22] = { switching_type = 'all', characters = { 'manual_knight', 'lw_maiden' } },
			[23] = { switching_type = 'all', characters = { 'manual_knight', 'lw_maiden' } },
			[24] = { switching_type = 'all', characters = { 'manual_knight', 'lw_maiden' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	laboseworld_7 = {
		-- 타겟 퀘스트 id
		quest_id = 386,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[25] = { switching_type = 'all', characters = { 'manual_knight' } },
			[26] = { switching_type = 'all', characters = { 'manual_knight' } },
			[27] = { switching_type = 'all', characters = { 'manual_knight' } },
			[28] = { switching_type = 'all', characters = { 'manual_knight' } },
			[29] = { switching_type = 'all', characters = { 'manual_knight' } },
			[30] = { switching_type = 'all', characters = { 'manual_knight' } },
			[31] = { switching_type = 'all', characters = { 'manual_knight' } },
			[32] = { switching_type = 'all', characters = { 'manual_knight' } },
			[33] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	lw_sub_demonshire = {
		-- 타겟 퀘스트 id
		quest_id = 392,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },
			[1] = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain', 'lw_sheep_girl', 'lw_goat_girl' } },
			[2] = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },
			[3] = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },
			[4] = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },
			[5] = { switching_type = 'all', characters = { 'lw_half_vampire' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'lw_half_vampire', 'lw_vampire_captain' } },

		is_set_character_info = true
	},

	lw_sub_demongod = {
		-- 타겟 퀘스트 id
		quest_id = 394,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'lw_demon_slayer', 'lw_demon_operator' } },
			[1] = { switching_type = 'all', characters = { 'lw_demon_slayer', 'lw_demon_operator' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'lw_demon_slayer', 'lw_demon_powergirl', 'lw_demon_operator' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'lw_demon_slayer', 'lw_demon_powergirl', 'lw_demon_operator' } },

		is_set_character_info = true
	},

	lw_sub_lana = {
		-- 타겟 퀘스트 id
		quest_id = 395,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'lw_onigirl' } },
			[1] = { switching_type = 'all', characters = { 'lw_onigirl' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'lw_onigirl' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'lw_onigirl' } },

		is_set_character_info = true
	},

	lw_sub_kaden = {
		-- 타겟 퀘스트 id
		quest_id = 403,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	lw_sub_lilith = {
		-- 타겟 퀘스트 id
		quest_id = 404,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'lw_demon_queen' } },
			[1] = { switching_type = 'all', characters = { 'lw_demon_queen', 'lw_demon_governor' } },
			[2] = { switching_type = 'all', characters = { 'lw_demon_queen', 'lw_demon_governor' } },
			[3] = { switching_type = 'all', characters = { 'lw_demon_queen', 'lw_demon_governor' } },
			[4] = { switching_type = 'all', characters = { 'lw_demon_queen', 'lw_demon_governor' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'lw_demon_queen' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'lw_demon_queen' } },

		is_set_character_info = true
	},
	--endregion laboseworld

	shortstory_slime = {
		-- 타겟 퀘스트 id
		quest_id = 7001701,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna' } },
			[1] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_legendary_hero', 'ss_slime_souei' } },
			[2] = { switching_type = 'all', characters = { 'ss_slime_milim', 'ss_slime_veldora' } },
			[3] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_legendary_hero',
														   'ss_slime_benimaru', 'ss_slime_shion', 'ss_slime_souei', 'ss_slime_hakurou' } },
			[4] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[5] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[6] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[7] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[8] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[9] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
			[10] = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ss_slime_rimuru', 'ss_slime_shuna', 'ss_slime_milim' } },

		is_set_character_info = true
	},

	--region nightmare_demonshire
	nightmare_demonshire_1 = {
		-- 타겟 퀘스트 id
		quest_id = 406,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[1] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[2] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[3] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		is_set_character_info = true
	},

	nightmare_demonshire_2 = {
		-- 타겟 퀘스트 id
		quest_id = 406,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[4] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord', 'nightmare_ds_vampire_captain' } },
			[5] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord', 'nightmare_ds_vampire_captain' } },
			[6] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord', 'nightmare_ds_vampire_captain' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		is_set_character_info = true
	},

	nightmare_demonshire_3 = {
		-- 타겟 퀘스트 id
		quest_id = 406,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[7] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[8] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[9] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		is_set_character_info = true
	},

	nightmare_demonshire_4 = {
		-- 타겟 퀘스트 id
		quest_id = 406,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[10] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
			[11] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		is_set_character_info = true
	},

	nightmare_demonshire_5 = {
		-- 타겟 퀘스트 id
		quest_id = 406,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[12] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord', 'nightmare_ds_two_horn_goat_girl' } },
			[13] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord', 'nightmare_ds_two_horn_goat_girl' } },
			[14] = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_ds_vampire_lord' } },

		is_set_character_info = true
	},
	--endregion nightmare_demonshire

	--region pixyworld
	pixyworld_5 = {
		-- 타겟 퀘스트 id
		quest_id = 412,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[15] = { switching_type = 'all', characters = { 'pw_pixy_girl' } },
			[16] = { switching_type = 'all', characters = { 'pw_pixy_girl' } },
			[17] = { switching_type = 'all', characters = { 'pw_pixy_girl' } },
			[18] = { switching_type = 'all', characters = { 'pw_pixy_girl' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'pw_pixy_girl' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'pw_pixy_girl' } },

		is_set_character_info = true
	},

	substage_19_2 = {
		-- 타겟 퀘스트 id
		quest_id = 417,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'princess_bat', 'pixy_detective' } },
			[1] = { switching_type = 'all', characters = { 'princess_pixy', 'pixy_detective' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'princess_pixy' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'princess_pixy' } },

		is_set_character_info = true
	},

	substage_19_3 = {
		-- 타겟 퀘스트 id
		quest_id = 413,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight', 'princess' } },

		is_set_character_info = true
	},

	--endregion pixyworld

	--region Short Story Milkyway

	shortstory_milkyway = {
		-- 타겟 퀘스트 id
		quest_id = 7001801,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[1] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[2] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_star_girl', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[3] = { switching_type = 'all', characters = { 'ss_milkyway_star_girl', 'ss_milkyway_pirate' } },
			[4] = { switching_type = 'all', characters = { 'ss_milkyway_pirate', 'ss_milkyway_star_girl' } },
			[5] = { switching_type = 'all', characters = { 'ss_milkyway_star_girl', 'ss_milkyway_pirate' } },
			[6] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_star_girl',
				'ss_milkyway_teatan_kid_girl', 'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[7] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_star_girl',
				'ss_milkyway_teatan_kid_girl', 'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy',
				'ss_milkyway_teatan_hero',
			} },
			[8] = { switching_type = 'all', characters = {
				'ss_milkyway_star_girl', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[9] = { switching_type = 'all', characters = { 'ss_milkyway_star_girl' } },
			[10] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
			} },
			[11] = { switching_type = 'all', characters = {
				'ss_milkyway_pirate', 'ss_milkyway_star_girl', 'ss_milkyway_teatan_kid_girl',
				'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy', 'ss_milkyway_teatan_hero',
			} },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ss_milkyway_pirate' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = {
			'ss_milkyway_pirate', 'ss_milkyway_teatan_kid_girl',
			'ss_milkyway_innuit_kid_boy', 'ss_milkyway_civilian_kid_boy'
		} },

		is_set_character_info = true
	},

	--endregion Short Story Milkyway

	--region nightmare_queenship
	nightmare_queenship_1 = {
		-- 타겟 퀘스트 id
		quest_id = 435,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[1] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[2] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		is_set_character_info = true
	},

	nightmare_queenship_2 = {
		-- 타겟 퀘스트 id
		quest_id = 435,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[3] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[4] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[5] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[6] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		is_set_character_info = true
	},

	nightmare_queenship_3 = {
		-- 타겟 퀘스트 id
		quest_id = 435,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[7] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
			[8] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
			[9] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl_hair_down' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl_hair_down' } },

		is_set_character_info = true
	},

	nightmare_queenship_4 = {
		-- 타겟 퀘스트 id
		quest_id = 435,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[10] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
			[11] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
			[12] = { switching_type = 'all', characters = { 'nightmare_qs_beth', 'nightmare_qs_little_girl' } },
			[13] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		is_set_character_info = true
	},

	nightmare_queenship_5 = {
		-- 타겟 퀘스트 id
		quest_id = 435,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[14] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[15] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[16] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
			[17] = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'nightmare_qs_beth' } },

		is_set_character_info = true
	},
	--endregion nightmare_queenship

	--region DreamVillage

	dreamvillage_1 = {
		-- 타겟 퀘스트 id
		quest_id = 441,

		progress_data_list = {
			[0] = { switching_type = 'add', characters = { 'dv_princess' }, },
			[1] = { switching_type = 'add', characters = { 'dv_princess' }, },
			[2] = { switching_type = 'add', characters = { 'dv_princess' }, },
			[3] = { switching_type = 'add', characters = { 'dv_princess' }, },
			[4] = { switching_type = 'add', characters = { 'dv_princess' }, },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = {
			switching_type = 'add', characters = { 'dv_princess' },
		},

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = {
			switching_type = 'add', characters = { 'dv_princess' },
		},
	},

	dreamvillage_2 = {
		-- 타겟 퀘스트 id
		quest_id = 441,

		progress_data_list = {
			[5] = { switching_type = 'add', characters = {  } },
			[6] = { switching_type = 'add', characters = {  } },
			[7] = { switching_type = 'add', characters = { 'dv_twins_younger' }, },
			[8] = { switching_type = 'add', characters = { 'dv_twins_younger' }, },
			[9] = { switching_type = 'add', characters = { 'dv_twins_younger' }, },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = {
			switching_type = 'add', characters = { 'dv_twins_younger' },
		},

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = {
			switching_type = 'add', characters = { 'dv_twins_younger' },
		},
	},

	dreamvillage_3 = {
		-- 타겟 퀘스트 id
		quest_id = 441,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'dv_twins_younger' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'dv_twins_younger' } },

		is_set_character_info = true
	},

	dreamvillage_4 = {
		-- 타겟 퀘스트 id
		quest_id = 441,

		progress_data_list = {
			[16] = { switching_type = 'add', characters = {} },
			[17] = { switching_type = 'add', characters = {} },
			[18] = { switching_type = 'add', characters = {} },
			[19] = { switching_type = 'add', characters = {} },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = {}, },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = {}, },
	},

	dreamvillage_6 = {
		-- 타겟 퀘스트 id
		quest_id = 441,

		progress_data_list = {
			[26] = { switching_type = 'add', characters = { 'dv_princess' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = {}, },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'dv_princess' }, }
	},

	substage_20_1 = {
		-- 타겟 퀘스트 id
		quest_id = 447,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'add', characters = {  } },
			[1] = { switching_type = 'add', characters = { 'dv_sub_cyborg_china_hero' } },
			[2] = { switching_type = 'add', characters = { 'dv_sub_cyborg_china_hero' } },
			[3] = { switching_type = 'add', characters = {  } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'add', characters = { 'dv_sub_cyborg_china_hero' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'add', characters = { 'dv_sub_cyborg_china_hero' } },

		is_set_character_info = true
	},

	substage_20_2 = {
		-- 타겟 퀘스트 id
		quest_id = 442,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'manual_knight' } },
			[1] = { switching_type = 'all', characters = { 'manual_knight' } },
			[2] = { switching_type = 'all', characters = { 'manual_knight' } },
			[3] = { switching_type = 'all', characters = { 'manual_knight' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'manual_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'manual_knight' } },

		is_set_character_info = true
	},

	substage_20_3 = {
		-- 타겟 퀘스트 id
		quest_id = 448,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'museum_knight', 'dv_museum_male' } },
			[1] = { switching_type = 'all', characters = { 'museum_knight', 'dv_museum_male' } },
			[2] = { switching_type = 'all', characters = { 'museum_knight', 'dv_chris' } },
			[3] = { switching_type = 'all', characters = { 'museum_knight', 'dv_chris' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'museum_knight' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'museum_knight' } },

		is_set_character_info = true
	},

	dv_sub_cave = {
		-- 타겟 퀘스트 id
		quest_id = 450,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'exclude_leader', characters = { 'dv_akayuki', 'dv_kunoichi', 'dv_ninja_leader' } },
			[1] = { switching_type = 'exclude_leader', characters = { 'dv_akayuki', 'dv_kunoichi', 'dv_ninja_leader' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'exclude_leader', characters = { 'dv_akayuki', 'dv_kunoichi', 'dv_ninja_leader' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'exclude_leader', characters = { 'dv_akayuki', 'dv_kunoichi', 'dv_ninja_leader' } },

		is_set_character_info = true
	},


	--endregion DreamVillage

	--region ShortStoryFrieren

	shortstory_frieren = {
		-- 타겟 퀘스트 id
		quest_id = 7001901,

		-- 섹션별 세팅할 파티 멤버
		progress_data_list = {
			[0] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark' } },
			[2] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_ailie' } },
			[3] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_tanker', 'ss_frieren_ailie' } },
			[4] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_ailie' } },
			[5] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_ailie' } },
			[6] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_tanker', 'ss_frieren_ailie' } },
			[7] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_ailie' } },
			[8] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_ailie', 'ss_frieren_held' } },
			[9] = { switching_type = 'all', characters = { 'ss_frieren_frieren' } },
			[11] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_tanker' } },
			[12] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark', 'ss_frieren_tanker' } },
			[14] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark' } },
			[15] = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark' } },
		},

		-- progress_list 없는 섹션일 때 대응할 기본 파티 멤버
		fallback_data = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark' } },

		-- 타겟 퀘스트를 클리어 했을 때 파티 멤버
		complete_data = { switching_type = 'all', characters = { 'ss_frieren_frieren', 'ss_frieren_fern', 'ss_frieren_stark' } },

		is_set_character_info = true
	},

	--endregion ShortStoryFrieren
}
