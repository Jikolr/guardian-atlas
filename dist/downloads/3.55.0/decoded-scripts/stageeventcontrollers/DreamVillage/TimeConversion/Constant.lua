local yokai_blocking_ghost = {
	zone_name = 'yokai_open',
	override_quest_id = 449,
	progress_infos = {
		{
			from = 0,
			to = 3,
		},
	},

	fo = {
		yokai_blocking_ghost_1 = {
			key = 'dv_male_type_a',
			preset_key = 'ghost_type_b',
			position = {
				pivot = 'yokai_blocking_ghost',
				offset = vector(0, 0, 0.5)
			},
			direction = direction_constants.left,
		},

		yokai_blocking_ghost_2 = {
			key = 'dv_female_type_b',
			preset_key = 'ghost_type_b',
			position = {
				pivot = 'yokai_blocking_ghost',
				offset = vector(0, 0, -0.5)
			},
			direction = direction_constants.left,
		},
	}
}

return {
	-- 스테이지 이름
	['dreamvillage_2'] = {
		-- 밤/낮 타일맵 전환 관리 기믹 핸들네임
		animator_fo_name = 'visual_controller',

		-- 밤/낮 전환 애니메이터 종류 (복수가 될 수 있기에 배열로)
		animation_name = {
			daylight = 'daylight',
			night = 'night'
		},

		-- 시작할 타임 인덱스 (1: 낮 / 2: 밤)
		start_time_index = 1,

		-- 타겟 메인 퀘스트 id
		quest_id = 441,

		-- 비네트효과 사용할 것인지 여부
		is_use_vignette = true,

		-- 비네트 효과가 비활성화될 그리드 (ex) 실내, 동굴)
		disable_vignette_grid_list = {
			'inn_grid_1', 'inn_grid_2', 'inn_grid_3', 'library_grid_2', 'library_grid_1',
			'cave_grid_1', 'cave_grid_2', 'cave_grid_3', 'cave_grid_4', 'yokai_statue',
		},

		-- 밤/낮 바뀔 때 사용할 npc pools
		--TODO: 메인 2스테이지
		npc_pools = {
			princess = {
				prefix = 'princess_',
				count = 1,
			},
			reaper = {
				prefix = 'reaper_',
				count = 1,
			},
			dv_female_type_a = {
				prefix = 'pooled_dv_female_type_a_',
				count = 7,
			},
			dv_female_type_b = {
				prefix = 'pooled_dv_female_type_b_',
				count = 7,
			},
			dv_female_type_c = {
				prefix = 'pooled_dv_female_type_c_',
				count = 5,
			},
			dv_male_type_a = {
				prefix = 'pooled_dv_male_type_a_',
				count = 9,
			},
			dv_male_type_b = {
				prefix = 'pooled_dv_male_type_b_',
				count = 8,
			},
			dv_male_type_c = {
				prefix = 'pooled_dv_male_type_c_',
				count = 5,
			},
			dv_kid_female = {
				prefix = 'pooled_dv_kid_female_',
				count = 6,
			},
			dv_kid_male = {
				prefix = 'pooled_dv_kid_male_',
				count = 6,
			},
			dv_hulk_male = {
				prefix = 'pooled_dv_hulk_male_',
				count = 4,
			},
			dv_female_old = {
				prefix = 'pooled_dv_female_old_',
				count = 3,
			},
			dv_male_old = {
				prefix = 'pooled_dv_male_old_',
				count = 4,
			},
			dv_china_merchant = {
				prefix = 'pooled_dv_china_merchant_',
				count = 2,
			},
			dv_kid_male_friend = {
				prefix = 'pooled_dv_kid_male_friend_',
				count = 1,
			},
			dv_kid_female_friend = {
				prefix = 'pooled_dv_kid_female_friend_',
				count = 1,
			},
			dv_liar_prophet_male = {
				prefix = 'pooled_dv_liar_prophet_male_',
				count = 1,
			},
			dv_dungeon_mercenary_male = {
				prefix = 'pooled_dv_dungeon_mercenary_male_',
				count = 2,
			},
			dv_inn_keeper_female = {
				prefix = 'pooled_dv_inn_keeper_female_',
				count = 1,
			},
			dv_civilian_female = {
				prefix = 'pooled_dv_civilian_female_',
				count = 2,
			},
			dv_vampireidol = {
				prefix = 'pooled_dv_vampireidol_',
				count = 1,
			},
			dv_wood_goblin = {
				prefix = 'pooled_dv_wood_goblin_',
				count = 1,
			},
			dv_coward = {
				prefix = 'pooled_dv_coward_',
				count = 1,
			},
		},

		stage_setting = {
			-- 낮
			{
				-- npc
				npc = {
					-- 여관 앞 원라인
					{
						fo = {
							{
								key = 'dv_female_type_a',
								position = 'inn_outer_daylight_pos_1',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = 'dv_stage2_daylight_oneline_1_1',
							},
							{
								key = 'dv_female_type_b',
								position = 'inn_outer_daylight_pos_2',
								direction = direction_constants.left,
								anim = { name = 'sing' },
								emotion = { name = 'smile' },
								talk = 'dv_stage2_daylight_oneline_1_2',
							},
							{
								key = 'dv_hulk_male',
								position = 'inn_outer_daylight_pos_3',
								direction = direction_constants.right,
								anim = { name = 'eat' },
								talk = 'dv_stage2_daylight_oneline_1_3',
							},
							{
								key = 'dv_female_type_a',
								position = 'ghost_inn_outer_pos_2',
								direction = direction_constants.left,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'doyagao' },
								talk = 'dv_stage2_daylight_oneline_1_4',
							},
						},
					},
					-- 다리 앞 원라인 처리
					{
						fo = {
							{
								-- 1번(dv_male_type_a)(left, attack, cast2) : 이번 축제에는 꼭 그녀에게 내 마음을 전할 거야!
								key = 'dv_male_type_a',
								position = 'bridge_oneline_pos_1',
								direction = direction_constants.left,
								anim = { name = 'cast2', },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage2_daylight_oneline_2_1' }
							},
							{
								-- 2번(dv_female_type_c)(left, tired, idle) : 한 걸음 뒤엔 항상 내가 있어….
								key = 'dv_female_type_c',
								position = 'bridge_oneline_pos_2',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage2_daylight_oneline_2_2' }
							},
							{
								-- 3번(dv_female_type_a)(left, attack, cross_arm) : 축제의 주요 장소들을 빠짐없이 다 돌려면 계획을 세워야….
								key = 'dv_female_type_c',
								position = 'bridge_oneline_pos_3',
								direction = direction_constants.left,
								anim = { name = 'cross_arm', sfx_name = false, one_shot_sfx = false },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage2_daylight_oneline_2_3' }
							},
							{
								-- 4번(dv_male_type_c)(left, attack, bomb_idle) : 아빠가 숙제 다 하기 전까지는 놀러 못 간다고 했지?
								key = 'dv_male_type_c',
								position = 'bridge_oneline_pos_4',
								direction = direction_constants.left,
								anim = { name = 'bomb_idle', },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage2_daylight_oneline_2_4' }
							},
							{
								-- 5번(dv_kid_female)(up, idle, idle) : 축제인데도 저렇게 엄격하게 하시다니….
								key = 'dv_kid_female',
								position = 'bridge_oneline_pos_5',
								direction = direction_constants.up,
								talk = { key = 'dv_stage2_daylight_oneline_2_5' }
							},
							{
								-- 6번(dv_kid_male)(left, tired, idle) : 그치만… 애들이 기다린단 말이예요.
								key = 'dv_kid_male',
								position = 'bridge_oneline_pos_6',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage2_daylight_oneline_2_6' }
							},
						},
					},
					-- 광장 중앙 구역 원라인 NPC
					stage_2_square_event = {
						fo = {
							--1번 - dv_kid_female, right, tired, idle : 계속 무궁화 꽃이 피었습니다 해요…?
							sq_npc_1 = {
								key = 'dv_kid_female',
								position = 'daylight_square_pos_1',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_1' }
							},
							--2번 - dv_female_type_a, left, attack, bomb_idle : 아 아직 15승 15패니까 한판 더!
							sq_npc_2 = {
								key = 'dv_female_type_a',
								position = 'daylight_square_pos_2',
								direction = direction_constants.left,
								emotion = { name = 'attack' },
								anim = { name = 'bomb_idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_2' }
							},
							--3번 - dv_male_type_a, left, attack, cast2: 승부는 가려야지!
							sq_npc_3 = {
								key = 'dv_male_type_a',
								position = 'daylight_square_pos_3',
								direction = direction_constants.left,
								emotion = { name = 'attack' },
								anim = { name = 'cast2', },
								talk = { key = 'dv_stage2_daylight_oneline_3_3' }
							},
							--4번 - dv_kid_male, up, idle, idle : 저 어른들은 왜 저렇게 열심이야…?
							sq_npc_4 = {
								key = 'dv_kid_male',
								position = 'daylight_square_pos_4',
								direction = direction_constants.up,
								emotion = { name = 'idle' },
								anim = { name = 'idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_4' }
							},
							--5번 - dv_kid_female, up, idle, idle : 우… 우리가 하고 있던 건데….
							sq_npc_5 = {
								key = 'dv_kid_female',
								position = 'daylight_square_pos_5',
								direction = direction_constants.up,
								emotion = { name = 'idle' },
								anim = { name = 'idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_5' }
							},
							--6번 - dv_hulk_male, right, tired, idle : 오늘은 예언가 님을 만나실 수 없습니다.
							--(길 지나가지 못하도록 충돌 처리 필요합니다.)
							sq_npc_6 = {
								key = 'dv_hulk_male',
								position = 'daylight_square_pos_6',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_6' }
							},
							--7번 - dv_female_old, right, idle, bomb_idle : 옛날 생각이 나는구만 그려.
							sq_npc_7 = {
								key = 'dv_male_old',
								position = 'daylight_square_pos_7',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'bomb_idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_7' }
							},
							--8번 - dv_male_old, left, idle, idle : 호호, 당신이 고백했던 그 때 말이죠?
							sq_npc_8 = {
								key = 'dv_female_old',
								position = 'daylight_square_pos_8',
								direction = direction_constants.left,
								emotion = { name = 'idle' },
								anim = { name = 'idle', },
								talk = { key = 'dv_stage2_daylight_oneline_3_8' }
							},
							--9번 - dv_kid_male, right, attack, sword_idle
							sq_npc_9 = {
								key = 'dv_kid_male',
								position = 'daylight_square_pos_9',
								direction = direction_constants.right,
								emotion = { name = 'attack' },
								anim = { name = 'sword_idle', },
							},
							--10번 - dv_female_type_a, right, smile, idle
							sq_npc_10 = {
								key = 'dv_female_type_a',
								position = 'daylight_square_pos_10',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
							}
						},
					},
					--공주와 칠득이(강림) 이벤트
					stage_2_princess_n_reaper_event = {
						fo = {
							--공주 right, smile, idle
							pnr_princess = {
								key = 'princess',
								position = 'princess_n_reaper_pos_1',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
							},
							--칠득이 left, dumb_idle, idle
							pnr_reaper = {
								key = 'reaper',
								position = 'princess_n_reaper_pos_2',
								direction = direction_constants.left,
								emotion = { name = 'dumb_idle' },
								anim = { name = 'idle', },
							},
						}
					},
					-- 가판대 원라인 처리
					{
						fo = {
							{
								-- 시온 - dv_kid_male_friend, left, idle, idle. 조용히 좀 봐.
								key = 'dv_kid_male_friend',
								position = 'square_2_oneline_pos_8',
								direction = direction_constants.left,
								talk = { key = 'dv_stage2_daylight_oneline_4_1' }
							},
							{
								-- 디아나 - dv_kid_female_friend, up, idle, idle, 이거 예쁘다.
								key = 'dv_kid_female_friend',
								position = 'square_2_oneline_pos_9',
								direction = direction_constants.up,
								talk = { key = 'dv_stage2_daylight_oneline_4_2' }
							},
							{
								-- 1 - dv_china_merchant, left, idle, eat : 무… 물건은 살 거지 얘들아?
								key = 'dv_china_merchant',
								position = 'square_2_oneline_pos_1',
								direction = direction_constants.left,
								anim = { name = 'eat' },
								talk = { key = 'dv_stage2_daylight_oneline_4_3' }
							},
							{
								-- 2 - dv_female_type_b, right, smile, bomb_idle : 무슨 만두로 드릴까요?
								key = 'dv_female_type_b',
								position = 'square_2_oneline_pos_2',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_4' }
							},
							{
								-- 3 - dv_male_type_b, right, smile, idle : 고기 만두, 새우 만두 세트로 주세요!
								key = 'dv_male_type_b',
								position = 'square_2_oneline_pos_3',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_5' }
							},
							{
								-- 4 - dv_female_type_c, right, smile, idle : 이건 가격이 얼마죠?
								key = 'dv_female_type_c',
								position = 'square_2_oneline_pos_12',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_6' }
							},
							{
								-- 5 - dv_male_type_a, left, smile, bomb_idle: 가격이요? 음… 축제니까… 그냥 가져가세요!
								key = 'dv_male_type_a',
								position = 'square_2_oneline_pos_4',
								direction = direction_constants.left,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_7' }
							},
							{
								-- 6 - dv_male_type_c, right, blush, cast : 실례가 안 된다면… 이거 사드려도 될까요?
								key = 'dv_male_type_c',
								position = 'square_2_oneline_pos_10',
								direction = direction_constants.right,
								anim = { name = 'cast' },
								emotion = { name = 'blush' },
								talk = { key = 'dv_stage2_daylight_oneline_4_8' }
							},
							{
								-- 7 - dv_female_type_a, left, blush, idle : 네, 좋아요….
								key = 'dv_female_type_a',
								position = 'square_2_oneline_pos_5',
								direction = direction_constants.left,
								emotion = { name = 'blush' },
								talk = { key = 'dv_stage2_daylight_oneline_4_9' }
							},
							{
								-- 8 - dv_kid_female, down, smile, idle : 제 동생이 만든 물건들이예요! 한번 보고 가세요!
								key = 'dv_kid_female',
								position = 'square_2_oneline_pos_6',
								direction = direction_constants.down,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_10' }
							},
							{
								-- 9 - dv_male_old, right, smile, bomb_idle : 할아버지랑 노는 게 그렇게 좋니?
								key = 'dv_male_old',
								position = 'square_2_oneline_pos_11',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_11' }
							},
							{
								-- 10 - dv_kid_male, left, smile, success : 응! 할아버지 최고야!
								key = 'dv_kid_male',
								position = 'square_2_oneline_pos_7',
								direction = direction_constants.left,
								anim = { name = 'success' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_4_12' }
							},
						},
					},
					-- 여관 원라인 처리
					stage_2_inn_daylight_event = {
						fo = {
							{
								-- 1번(dv_male_type_a)(left, smile, idle) : 다들 신난 거 보니까 나도 기분이 좋은걸?
								key = 'dv_male_type_a',
								position = 'daylight_inn_pos_1',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_1' }
							},
							{
								-- 2번(dv_dungeon_mercenary_male)(right, idle, cast2) : 이 여관… 지금까지 와 본 여관 중 가장 좋은 걸?
								key = 'dv_dungeon_mercenary_male',
								position = 'daylight_inn_pos_2',
								direction = direction_constants.right,
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage2_daylight_oneline_5_2' }
							},
							{
								-- 3번(dv_dungeon_mercenary_male)(left, idle, cast2) : 그러니까! 던전 왕국보다 훨 낫네!
								key = 'dv_dungeon_mercenary_male',
								position = 'daylight_inn_pos_3',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage2_daylight_oneline_5_3' }
							},
							{
								-- 4번(dv_male_type_c )(right, idle, cast) : 축제 끝날 때까지 이 옷 입고 다녀야겠어.
								key = 'dv_male_type_c',
								position = 'daylight_inn_pos_4',
								direction = direction_constants.right,
								anim = { name = 'cast' },
								talk = { key = 'dv_stage2_daylight_oneline_5_4' }
							},
							{
								-- 5번(dv_female_type_c)(right, smile, bomb_idle) : 이 옷 보기보다 더 편한데?
								key = 'dv_female_type_c',
								position = 'daylight_inn_pos_5',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_5' }
							},
							{
								-- 6번(dv_male_type_c)(left, smile, cast2) : 다같이 이렇게 입으니까 진짜 현지인 된 거 같다.
								key = 'dv_male_type_c',
								position = 'daylight_inn_pos_6',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_6' }
							},
							{
								-- 1번(dv_male_old)(right, tired, idle) : 그런데… 꼭 이런 옷을 입어야 되겠니?
								key = 'dv_male_old',
								position = 'daylight_inn_pos_8',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage2_daylight_oneline_5_8' }
							},
							{
								-- 2번(dv_female_old)(left, attack, cast2) : 아이구, 영감도 참. 애들이 하자고 하면 하면 되지.
								key = 'dv_female_old',
								position = 'daylight_inn_pos_9',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage2_daylight_oneline_5_9' }
							},
							{
								-- 3번(dv_female_type_b)(left, attack, cast2) : 아우, 아빠! 여행 왔으면 좀 돈 아깝다, 하기 싫다 좀 그만해!
								key = 'dv_female_type_b',
								position = 'daylight_inn_pos_15',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage2_daylight_oneline_5_10' }
							},
							{
								-- 4번(dv_male_type_b)(left, tired, cast) : 여… 여보…. 아버님께 왜 그래….
								key = 'dv_male_type_b',
								position = 'daylight_inn_pos_10',
								direction = direction_constants.left,
								anim = { name = 'cast' },
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage2_daylight_oneline_5_11' }
							},
							{
								-- 5번(dv_kid_female)(right, smile, success) : 아빠! 오늘도 축제에서 놀아요!
								key = 'dv_kid_female',
								position = 'daylight_inn_pos_11',
								direction = direction_constants.right,
								anim = { name = 'success' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_12' }
							},
							{
								-- 6번(dv_kid_male)(right, smile, success) : 나도나도! 놀고 싶어요!
								key = 'dv_kid_male',
								position = 'daylight_inn_pos_12',
								direction = direction_constants.right,
								anim = { name = 'success' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_13' }
							},
							{
								-- 7번(dv_male_type_a)(left, smile, idle) : 하하, 그래. 축제 기간은 아닌 줄 알았는데… 축제라서 다행이구나.
								key = 'dv_male_type_a',
								position = 'daylight_inn_pos_13',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_14' }
							},
							{
								-- 1번(dv_china_merchant)(down, tired, question loop 없이) : 흠… 여기서 장사를 시작한지 며칠 째더라….
								key = 'dv_china_merchant',
								position = 'daylight_inn_pos_14',
								direction = direction_constants.down,
								anim = { name = 'question' },
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage2_daylight_oneline_5_15' }
							},
							inn_keeper = {
								-- 7번(dv_inn_keeper_female)(down, smile, bomb_idle) : 아유, 장기 손님은 언제나 반갑죠.
								key = 'dv_inn_keeper_female',
								position = 'daylight_inn_pos_7',
								direction = direction_constants.down,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage2_daylight_oneline_5_7' }
							},
						}
					},
					--퍼즐방 원라인 NPC(낮) dv_hulk_male
					stage_2_puzzle_daylight_event = {
						fo = {
							--1번(dv_hulk_male)(right, idle, idle) : 아마도 화약이겠지. 정말 맛있는 탄산보리차면 좋았겠지만….
							{
								key = 'dv_hulk_male',
								position = 'daylight_puzzle_pos_1',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = { key = 'dv_stage2_daylight_oneline_6_1' }
							},
							--2번(dv_hulk_male)(right, idle, bomb_idle) : 저 통에 든 게 뭐라고 생각하시오?
							{
								key = 'dv_hulk_male',
								position = 'daylight_puzzle_pos_2',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'idle' },
								talk = { key = 'dv_stage2_daylight_oneline_6_2' }
							}
						}
					},
					--세실 이벤트 관련 npc(낮)
					vampireidol_daylight = {
						fo = {
							--세실 (dv_vampireidol) (down, idle, sing2)
							vi_vampireidol = {
								key = 'dv_vampireidol',
								position = 'vi_daylight_pos_10',
								direction = direction_constants.down,
								emotion = { name = 'sing' },
								anim = { name = 'sing2' },
							},
							--우드 고블린 (dv_wood_goblin) (right, doyagao, basket_idle) : 이 목소리만이 나를 자유롭게 해줘.
							{
								key = 'dv_wood_goblin',
								position = 'vi_daylight_pos_11',
								direction = direction_constants.right,
								emotion = { name = 'doyagao' },
								anim = { name = 'basket_idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_10' }
							},
							--1번 NPC (dv_male_type_a) (right, smile, idle) : 미소가 절로 나는 노래야.
							{
								key = 'dv_male_type_a',
								position = 'vi_daylight_pos_1',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_1' }
							},
							--2번 NPC (dv_female_type_a) (right, smile, cast) : 맨날 내 귀에 맴돌았으면 좋겠어.
							{
								key = 'dv_female_type_a',
								position = 'vi_daylight_pos_2',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'cast', },
								talk = { key = 'dv_vampireidol_daylight_oneline_2' }
							},
							--3번 NPC (dv_female_old)(right, smile, idle) : 요즘도 이렇게 노래하는 젊은이가 있다니.
							{
								key = 'dv_female_old',
								position = 'vi_daylight_pos_3',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_3' }
							},
							--4번 NPC (dv_kid_male) (right, smile, idle) 와! 지존이다!
							{
								key = 'dv_kid_male',
								position = 'vi_daylight_pos_4',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_4' }
							},
							--5번 NPC (dv_kid_female)(left, smile, idle) : 수련회 때 불러야지!
							{
								key = 'dv_kid_female',
								position = 'vi_daylight_pos_5',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_5' }
							},
							--6번 NPC (dv_female_type_b)(left, smile, sing) : 영원히 불러줘요! 사랑해요!
							{
								key = 'dv_female_type_b',
								position = 'vi_daylight_pos_6',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								anim = { name = 'sing', },
								talk = { key = 'dv_vampireidol_daylight_oneline_6' }
							},
							--7번 NPC (dv_male_type_b) (right, tired, cast) : 처음 보는 녀석인데… 어디서 온 거지?
							{
								key = 'dv_male_type_b',
								position = 'vi_daylight_pos_7',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cast', },
								talk = { key = 'dv_vampireidol_daylight_oneline_7' }
							},
							--8번 NPC (dv_male_old)(right, idle, idle) : 요즘 젊은 사람들 노래도 좋구먼.
							{
								key = 'dv_male_old',
								position = 'vi_daylight_pos_8',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_8' }
							},
							--9번 NPC (dv_male_type_a)(right, idle, idle) : 그렇죠, 할아버지? 다음에도 같이 보러 와요.
							{
								key = 'dv_male_type_a',
								position = 'vi_daylight_pos_9',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_9' }
							},
							--10번 NPC (dv_female_type_a)(left, love, idle) : 옥구슬이 굴러가는 고운 소리…!
							{
								key = 'dv_female_type_a',
								position = 'vi_daylight_pos_12',
								direction = direction_constants.left,
								emotion = { name = 'love' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_11' }
							},
							--11번 NPC (dv_female_type_b)(right, sleep_deep, idle) : 노래의 호흡이 아주 이븐한데요?
							{
								key = 'dv_female_type_b',
								position = 'vi_daylight_pos_13',
								direction = direction_constants.right,
								emotion = { name = 'sleep_deep' },
								anim = { name = 'idle', },
								talk = { key = 'dv_vampireidol_daylight_oneline_12' }
							},
						}
					},
					--겁쟁이 이벤트 관련 npc(낮, 클리어 이전)
					coward_daylight_progress = {
						override_quest_id = 445,
						progress_infos = {
							{
								from = -1,
								to = 0,
							},
						},
						fo = {
							--무사 1(left, idle, idle) : 외부인은 들어갈 수 없소.
							dv_coward_samurai_1 = {
								key = 'dv_male_type_b',
								position = 'coward_guard_pos_1',
								direction = direction_constants.up,
								emotion = { name = 'idle' },
								anim = { name = 'idle' },
								talk = { key = 'dv_sub_coward_oneline_6' }
							},
							--무사 2(left, idle, idle) : 외부인은 들어갈 수 없소.
							dv_coward_samurai_2 = {
								key = 'dv_male_type_b',
								position = 'coward_guard_pos_2',
								direction = direction_constants.up,
								emotion = { name = 'idle' },
								anim = { name = 'idle' },
								talk = { key = 'dv_sub_coward_oneline_6' }
							},
							--무사3
							dv_coward_samurai_3 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_3',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'idle' },
							},
							--무사4
							dv_coward_samurai_4 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_4',
								direction = direction_constants.left,
								emotion = { name = 'idle' },
								anim = { name = 'idle' },
							},
						}
					},
					--겁쟁이 이벤트 관련 npc(낮, 클리어 이후)
					coward_daylight_cleared = {
						override_quest_id = 445,
						progress_infos = {
							{
								from = 'clear',
								to = 'clear',
							},
						},
						fo = {
							--겁쟁이 (left, smile, idle) : 이제는 열심히 수련해서 진짜 무사가 될 거에요.
							dv_coward_coward = {
								key = 'dv_coward',
								position = 'coward_epilogue_pos',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								anim = { name = 'idle' },
								talk = { key = 'dv_sub_coward_oneline_1' }
							},
							--무사1 (right, idle, cross_arm) : 엄청난 신입이 들어왔군.
							dv_coward_samurai_1 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_1',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'idle' },
								talk = { key = 'dv_sub_coward_oneline_2' }
							},
							--무사2 (right, idle, eat) : 신입한테 뒤지지 않도록 열심히 수련해야지.
							dv_coward_samurai_2 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_2',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'eat' },
								talk = { key = 'dv_sub_coward_oneline_3' }
							},
							--무사3 (right, idle, eat) : 에휴, 이걸 언제 다 치워.
							dv_coward_samurai_3 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_3',
								direction = direction_constants.right,
								emotion = { name = 'idle' },
								anim = { name = 'eat' },
								talk = { key = 'dv_sub_coward_oneline_4' }
							},
							--무사4 (left, idle, eat) : 생각해보니까 신고식을 준비 못했네. 뭐, 상관없나.
							dv_coward_samurai_4 = {
								key = 'dv_male_type_b',
								position = 'coward_samurai_pos_4',
								direction = direction_constants.left,
								emotion = { name = 'idle' },
								anim = { name = 'eat' },
								talk = { key = 'dv_sub_coward_oneline_5' }
							},
						}
					},
				},
				-- gimmick
				gimmick = {
					vi_block = {
						fo = {
							{
								name = 'vi_block_1',
								show_type = 'anim',
							},
						}
					}
				},
			},
			-- 밤
			{
				-- npc
				npc = {
					-- 강림 이벤트
					stage_2_reaper_event = {
						progress_infos = {
							{
								from = 9,
								to = 15,
							},
						},
						fo = {
							reaper = {
								key = 'reaper',
								position = 's10_reaper_pos_1',
								direction = direction_constants.down,
								emotion = { name = 'sleep_deep' },
								-- 강림은 empty 아니니 이모션 제외 프리셋 값 직접 다 넣음
								color = { r = 0.2, g = 0.6, b = 1, a = 0.5 },
								alpha = 0.5,
							},
						}
					},

					-- 여관 앞 블로킹 원라인 처리
					ghost_event_inn_outer_blocking = {
						zone_name = 'ghost_inn_outer_blocking_zone',
						fo = {
							-- 숨기 + 놀래키기
							surprise_ghost_1 = {
								key = 'dv_female_type_b',
								preset_key = 'ghost',
								position = 'ghost_inn_outer_blocking_pos_1',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									},
								},
							},
							surprise_ghost_2 = {
								key = 'dv_male_type_a',
								preset_key = 'ghost',
								position = 'ghost_inn_outer_blocking_pos_2',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									},
								},
							},
						},
					},
					-- 다리 앞 원라인 처리
					ghost_event_bridge = {
						zone_name = 'ghost_bridge_zone',
						progress_infos = {
							{
								from = 7,
								to = 'clear',
							},
						},
						fo = {
							{
								key = 'dv_female_type_a',
								preset_key = 'ghost',
								position = 'ghost_bridge_pos_1',
								direction = direction_constants.right,
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								}
							},
							{
								key = 'dv_female_type_b',
								preset_key = 'ghost',
								position = 'ghost_bridge_pos_2',
								direction = direction_constants.left,
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								}
							},
						},
					},
					-- 광장 원라인 처리
					ghost_event_square = {
						zone_name = 'ghost_square_1_zone',
						fo = {
							--  놀래키기
							surprise_ghost_1 = {
								key = 'dv_liar_prophet_male',
								preset_key = 'ghost',
								position = 'ghost_square_1_pos_3',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									},
								}
							},
							{
								key = 'dv_female_type_a',
								preset_key = 'ghost_type_b',
								position = 'ghost_square_1_pos_1',
								direction = direction_constants.down,
							},
							{
								key = 'dv_female_type_b',
								preset_key = 'ghost_type_b',
								position = 'ghost_square_1_pos_2',
								direction = direction_constants.right,
							},
						},
					},
					-- 여관 입구 원라인
					ghost_event_inn_1 = {
						progress_infos = {
							{
								from = 6,
								to = 'clear',
							}
						},
						zone_name = 'ghost_inn_zone_1',
						fo = {
							{
								-- 1번(dv_female_type_a)[3]
								key = 'dv_female_type_a',
								preset_key = 'ghost',
								position = 'ghost_inn_1_pos_1',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								-- 2번(dv_female_type_b)[3]
								key = 'dv_female_type_b',
								preset_key = 'ghost',
								position = 'ghost_inn_1_pos_2',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								-- 3번(dv_male_type_a)[3]
								key = 'dv_male_type_a',
								preset_key = 'ghost',
								position = 'ghost_inn_1_pos_3',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
						},
					},
					-- 여관 상인 원라인
					ghost_event_inn_2 = {
						zone_name = 'ghost_inn_zone_2',
						progress_infos = {
							{
								from = 7,
								to = 26,
							}
						},
						fo = {
							{
								-- 1번(dv_china_merchant)[3] : down, idle, idle
								key = 'dv_china_merchant',
								preset_key = 'ghost_type_b',
								position = 'ghost_inn_2_pos_1',
								direction = direction_constants.down,
							},
						},
					},
					-- 여관 원라인 3
					ghost_event_inn_3 = {
						zone_name = 'ghost_inn_zone_3',
						fo = {
							-- 1번(dv_civilian_female)[2] : left, idle, idle
							{

								key = 'dv_civilian_female',
								preset_key = 'ghost_type_b',
								position = 'ghost_inn_3_pos_1',
								direction = direction_constants.left,

							},
							{
								-- 2번(dv_civilian_female)[1] : left, tired, idle
								key = 'dv_civilian_female',
								preset_key = 'ghost_type_b',
								position = 'ghost_inn_3_pos_2',
								direction = direction_constants.left,
							},
							{
								-- 3번(dv_dungeon_mercenary_male)[1] : right, tired, idle
								key = 'dv_male_type_a',
								preset_key = 'ghost_type_b',
								position = 'ghost_inn_3_pos_3',
								direction = direction_constants.right,
							},
						},
					},
					-- 가판대 원라인 처리
					ghost_event_square_2 = {
						zone_name = 'ghost_square_2_zone',
						fo = {
							-- 1번(dv_female_type_a)[1]
							{
								key = 'dv_female_type_a',
								preset_key = 'ghost_type_b',
								position = 'ghost_square_2_pos_1',
								direction = direction_constants.down,
							},
							--  놀래키기
							{
								key = 'dv_female_type_b',
								preset_key = 'ghost',
								position = 'ghost_square_2_pos_2',
								-- 2번(dv_female_type_b)[3] : right, idle, idle
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									},
								},
							},
							--  놀래키기
							{
								key = 'dv_female_type_c',
								preset_key = 'ghost',
								position = 'ghost_square_2_pos_3',
								-- 3번(dv_female_type_c )[3] : right, idle, idle
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									},
								},
							},
						},
					},
					--세실 이벤트 관련 npc(밤)
					ghost_event_vampireidol = {
						zone_name = 'vi_sound_zone',
						fo = {
							--1,2번 제거됨.
							--3번 NPC (dv_male_type_a)(left, ilde, ilde)
							vi_ghost_3 = {
								key = 'dv_male_type_a',
								preset_key = 'ghost',
								position = 'vi_ghost_pos_3',
								direction = direction_constants.left,
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								}
							},
							--4번 NPC (dv_male_type_b)(left, idle, idle)
							vi_ghost_4 = {
								key = 'dv_male_type_b',
								preset_key = 'ghost',
								position = 'vi_ghost_pos_4',
								direction = direction_constants.left,
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								}
							},
						}
					},
					ghost_event_yokai_blocking = yokai_blocking_ghost
				},
				-- gimmick
				gimmick = {},
			}
		},
	},

	['dreamvillage_3'] = {
		-- 밤/낮 타일맵 전환 관리 기믹 핸들네임
		animator_fo_name = 'visual_controller',

		-- 밤/낮 전환 애니메이터 종류 (복수가 될 수 있기에 배열로)
		animation_name = {
			daylight = 'daylight',
			night = 'night'
		},

		quest_id = 441,

		-- 시작할 타임 인덱스 (1: 낮 / 2: 밤)
		start_time_index = 1,

		-- 스테이터스가 비활성화될 존
		disabled_zone_data = {
		},

		disable_vignette_grid_list = {
			'inn_grid_1', 'inn_grid_2', 'inn_grid_3',
			'cave_grid_1', 'cave_grid_2', 'cave_grid_3', 'cave_grid_4', 'cave_grid_5', 'cave_grid_6'
		},

		--TODO: 메인 3스테이지
		npc_pools = {
			dv_female_type_a = {
				prefix = 'pooled_dv_female_type_a_',
				count = 2,
			},

			dv_female_type_b = {
				prefix = 'pooled_dv_female_type_b_',
				count = 4,
			},

			dv_female_type_c = {
				prefix = 'pooled_dv_female_type_c_',
				count = 4,
			},

			dv_male_type_a = {
				prefix = 'pooled_dv_male_type_a_',
				count = 4,
			},

			dv_male_type_b = {
				prefix = 'pooled_dv_male_type_b_',
				count = 3,
			},

			dv_male_type_c = {
				prefix = 'pooled_dv_male_type_c_',
				count = 3,
			},

			dv_kid_male = {
				prefix = 'pooled_dv_kid_male_',
				count = 3,
			},

			dv_female_old = {
				prefix = 'pooled_dv_female_old_',
				count = 2,
			},

			dv_male_old = {
				prefix = 'pooled_dv_male_old_',
				count = 2,
			},

			dv_hulk_male = {
				prefix = 'pooled_dv_hulk_male_',
				count = 3,
			},

			dv_china_merchant = {
				prefix = 'pooled_dv_china_merchant_',
				count = 2,
			},

			museum_female_type_a = {
				prefix = 'museum_female_type_a_',
				count = 1
			},

			museum_female_type_b = {
				prefix = 'museum_female_type_b_',
				count = 2
			},

			museum_male_type_b = {
				prefix = 'museum_male_type_b_',
				count = 1
			},

			museum_kid_male = {
				prefix = 'museum_kid_male_',
				count = 1
			},

			museum_female_old = {
				prefix = 'museum_female_old_',
				count = 1
			},

			museum_male_old = {
				prefix = 'museum_male_old_',
				count = 1
			},

			museum_museum_male = {
				prefix = 'museum_museum_male_',
				count = 5
			},
			main_keeper_female = {
				prefix = 'keeper_female_',
				count = 1
			}
		},

		stage_setting = {
			-- 낮
			{
				-- npc
				npc = {
					--광장 하부 NPC
					day_event_group_1 = {
						fo = {
							--1번(dv_female_type_a)(right, scared, cast) : 그거… 진짜 토끼발일까…?
							{
								key = 'dv_female_type_a',
								position = 'pooled_day_group_1_pos_1',
								direction = direction_constants.right,
								anim = { name = 'cast' },
								emotion = { name = 'scared' },
								talk = 'dv_stage3_day_oneline_1',
							},
							--2번(dv_female_type_b)(left, smile, sing) : 방금 토끼발 뽑았어!
							{
								key = 'dv_female_type_b',
								position = 'pooled_day_group_1_pos_2',
								direction = direction_constants.left,
								anim = { name = 'sing' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_2',
							},
							--3번(dv_hulk_male)(right, attack, release) : 거기 형씨! 아직 안 열었으면 나랑 바꾸지 않겠어?
							{
								key = 'dv_hulk_male',
								position = 'pooled_day_group_1_pos_3',
								direction = direction_constants.right,
								anim = { name = 'release', sfx_name = false },
								emotion = { name = 'attack' },
								talk = 'dv_stage3_day_oneline_3',
							},
							--4번(dv_male_type_a)(left, scared, cast) : 제… 제가 뽑은 게 마음에 드는데….
							{
								key = 'dv_male_type_a',
								position = 'pooled_day_group_1_pos_4',
								direction = direction_constants.left,
								anim = { name = 'cast' },
								emotion = { name = 'scared' },
								talk = 'dv_stage3_day_oneline_4',
							},
							--5번(dv_male_type_c)(right, sleep_deep, bow_idle) : 이번 뽑기는 꽝인가… 인생사 새옹지마. 앞으로 행운이 오겠군.
							{
								key = 'dv_male_type_c',
								position = 'pooled_day_group_1_pos_5',
								direction = direction_constants.right,
								anim = { name = 'bow_idle' },
								emotion = { name = 'sleep_deep' },
								talk = 'dv_stage3_day_oneline_5',
							},
							--6번(dv_male_type_b)(left, smile, eat) : 축제 뽑기를 하려면 쓰레기를 주워야지! 그래야 행운이 찾아오니까!
							{
								key = 'dv_male_type_b',
								position = 'pooled_day_group_1_pos_6',
								direction = direction_constants.left,
								anim = { name = 'eat' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_6',
							},
						},
					},
					--광장 중앙 구역 원라인 NPC
					day_event_group_2 = {
						fo = {
							--1번 - dv_male_type_a, right, tired, seat: 너랑은 무궁화 꽃이 피었습니다 더 안 할 거야.
							{
								key = 'dv_male_type_a',
								position = 'pooled_day_group_2_pos_1',
								direction = direction_constants.right,
								anim = { name = 'seat' },
								emotion = { name = 'tired' },
								talk = 'dv_stage3_day_oneline_7',
							},
							--2번 - dv_female_type_a, left, doyagao, cross_arm : 하하, 내 승리라는 말씀!
							{
								key = 'dv_female_type_a',
								position = 'pooled_day_group_2_pos_2',
								direction = direction_constants.left,
								anim = { name = 'cross_arm', one_shot_sfx = false },
								emotion = { name = 'doyagao' },
								talk = 'dv_stage3_day_oneline_8',
							},
							--3번 - dv_kid_male, right, smile, bomb_idle : 아빠는 석상 부수기 했어요?
							{
								key = 'dv_kid_male',
								position = 'pooled_day_group_2_pos_3',
								direction = direction_constants.right,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_9',
							},
							--4번 - dv_male_type_b, left, scared, idle : 그… 그럼! 자, 이제 얼른 집으로 가자.
							{
								key = 'dv_male_type_b',
								position = 'pooled_day_group_2_pos_4',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'scared' },
								talk = 'dv_stage3_day_oneline_10',
							},
							--5번 - dv_male_type_c, left, sleep, sleep : sleep 이모티콘.
							{
								key = 'dv_male_type_c',
								position = 'pooled_day_group_2_pos_5',
								direction = direction_constants.left,
								anim = { name = 'sleep' },
								emotion = { name = 'sleep' },
								emoticon = { key = emoticon_type.sleep, sfx = '01_sleep_02' },
							},
							--6번 - dv_hulk_male, left, attack, idle : 예언가 님이 사라졌으니… 내가 그 의지를 이어가야 하는건가…!
							{
								key = 'dv_hulk_male',
								position = 'pooled_day_group_2_pos_6',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'attack' },
								talk = 'dv_stage3_day_oneline_11',
							},
						}
					},
					----시장 구역의 원라인
					day_event_group_3 = {
						fo = {
							--1 - dv_china_merchant, right, smile, idle : 아주 탁월하신 선택입니다!
							{
								key = 'dv_china_merchant',
								position = 'pooled_day_group_3_pos_1',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_12',
							},
							--2 - dv_female_type_b, left, smile, cast : 호호, 이걸로 할게요.
							{
								key = 'dv_female_type_b',
								position = 'pooled_day_group_3_pos_2',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_13',
							},
							--3 - dv_male_type_b, right, smile, release : 축제 기간이니까 이건 2배 가격을 주고 살게요! 축제니까!
							{
								key = 'dv_male_type_b',
								position = 'pooled_day_group_3_pos_3',
								direction = direction_constants.left,
								anim = { name = 'release', sfx_name = false },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_14',
							},
							--4 - dv_female_type_c, left, smile, bomb_idle : 축제 프리미엄이네요!
							{
								key = 'dv_female_type_c',
								position = 'pooled_day_group_3_pos_4',
								direction = direction_constants.left,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_15',
							},
							--5 - dv_male_type_a, left, smile, eat : 슬슬 장사를 시작해볼까?
							{
								key = 'dv_male_type_a',
								position = 'pooled_day_group_3_pos_5',
								direction = direction_constants.left,
								anim = { name = 'eat' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_16',
							},
							--6 - dv_kid_male, right, smile, cast2 : 아저씨가 첫 손님이예요!
							{
								key = 'dv_kid_male',
								position = 'pooled_day_group_3_pos_6',
								direction = direction_constants.right,
								anim = { name = 'cast2' },
								emotion = { name = 'smile' },
								talk = 'dv_stage3_day_oneline_17',
							},
							--7 - dv_male_old, left, cry, nod : 할아버지가 아니라 아… 아저씨라고? 이런 말을 들은 게 얼마만인지!
							{
								key = 'dv_male_old',
								position = 'pooled_day_group_3_pos_7',
								direction = direction_constants.left,
								anim = { name = 'nod', one_shot_sfx = false },
								emotion = { name = 'cry' },
								talk = 'dv_stage3_day_oneline_18',
							},
						}
					},

					----도깨비 감투 퀘스트 구역의 원라인
					day_event_group_gc = {
						fo = {
							--1 - dv_hulk_male, up, idle, idle : 이쪽으로는 들어오실 수 없습니다.
							{
								key = 'dv_hulk_male',
								position = 'gc_oneline_pos_1',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_ghost_cap_oneline_1',
							},
							--2 - dv_female_type_c, left, tired, eat : 이것마저 도둑맞으면....
							{
								key = 'dv_female_type_c',
								position = 'gc_oneline_pos_2',
								direction = direction_constants.left,
								anim = { name = 'eat' },
								emotion = { name = 'tired' },
								talk = 'dv_ghost_cap_oneline_2',
							},
							--3 - dv_male_old, right, tired, eat : 이게 무슨 고생이야....
							{
								key = 'dv_male_old',
								position = 'gc_oneline_pos_3',
								direction = direction_constants.right,
								anim = { name = 'eat' },
								emotion = { name = 'tired' },
								talk = 'dv_ghost_cap_oneline_3',
							},
							--4 - dv_china_merchant, left, attack, eat : 오기만 해 봐라, 이 도둑놈!
							{
								key = 'dv_china_merchant',
								position = 'gc_oneline_pos_4',
								direction = direction_constants.left,
								anim = { name = 'eat' },
								emotion = { name = 'attack' },
								talk = 'dv_ghost_cap_oneline_4',
							},
						}
					},

					-- 박물관 대기열 바깥 알바생 존
					stage_3_museum_daylight_event = {
						fo = {
							--NPC 1 (left, smile, dance) : 연인과의 데이트, 가족들과 친목 도모에도 안성맞춤!
							museum_group_1_male_1 = {
								key = 'museum_museum_male',
								position = 'museum_day_group_1_pos_1',
								direction = direction_constants.left,
								anim = { name = 'dance', one_shot_sfx = false },
								emotion = { name = 'smile' },
								talk = 'dv_night_at_the_museum_pre_3',
							},
							--NPC 2 (right, smile, dance) : 모토리산 역사 박물관으로 놀러오세요!
							museum_group_1_male_2 = {
								key = 'museum_museum_male',
								position = 'museum_day_group_1_pos_2',
								direction = direction_constants.right,
								anim = { name = 'dance', one_shot_sfx = false },
								emotion = { name = 'smile' },
								talk = 'dv_night_at_the_museum_pre_4',
							},
						}
					},
					-- 박물관 내부 대기열 줄
					museum_day_group_2 = {
						fo = {
							--dv_female_type_a (up, idle, idle)
							--언제쯤 들어가는 거야….
							{
								key = 'museum_female_type_a',
								position = 'museum_day_group_2_pos_1',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_night_at_the_museum_pre_5',
							},
							-- dv_female_type_b(up, idle, idle)
							--이러다 내일 들어가겠어….
							{
								key = 'museum_female_type_b',
								position = 'museum_day_group_2_pos_2',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_night_at_the_museum_pre_6',
							},
							-- dv_male_type_b(up, idle, idle)
							--미리 와있을껄….
							{
								key = 'museum_male_type_b',
								position = 'museum_day_group_2_pos_3',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_night_at_the_museum_pre_7',
							},
							--: dv_kid_male(up, idle, idle)
							--아빠! 우리 언제 쯤 들어가요?
							{
								key = 'museum_kid_male',
								position = 'museum_day_group_2_pos_4',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_night_at_the_museum_pre_8',
							},
							-- dv_female_type_b(left, idle, idle)
							--음… 아직 한참 남은 것 같은데….
							{
								key = 'museum_female_type_b',
								position = 'museum_day_group_2_pos_5',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'idle' },
								talk = 'dv_night_at_the_museum_pre_9',
							},
							-- dv_female_old(left, tired, idle)
							--아유… 영감. 들어가긴 하는 거 맞아유?
							{
								key = 'museum_female_old',
								position = 'museum_day_group_2_pos_6',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'tired' },
								talk = 'dv_night_at_the_museum_pre_10',
							},
							--dv_male_old(left, smile, idle)
							--에잉… 가만히 기다리고 있어. 금방 도착혀.
							{
								key = 'museum_male_old',
								position = 'museum_day_group_2_pos_7',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								emotion = { name = 'smile' },
								talk = 'dv_night_at_the_museum_pre_11',
							},
							--: 박물관 알바(down, smile, idle)
							--박물관은 오픈 준비중입니다! 잠시 기다려주세요!
							{
								key = 'museum_museum_male',
								position = 'museum_day_group_2_pos_8',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								emotion = { name = 'smile' },
								talk = 'dv_night_at_the_museum_pre_12',
							},
							--박물관 알바(down, tired, idle)
							--으으… 사람도 부족한데 진짜…!
							{
								key = 'museum_museum_male',
								position = 'museum_day_group_2_pos_9',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								emotion = { name = 'tired' },
								talk = 'dv_night_at_the_museum_pre_13',
							},
							-- 박물관 알바(right, smile, cast)
							--다들 줄을 어기지 말고 천천히 움직이세요!
							{
								key = 'museum_museum_male',
								position = 'museum_day_group_2_pos_10',
								direction = direction_constants.right,
								anim = { name = 'cast' },
								emotion = { name = 'smile' },
								talk = 'dv_night_at_the_museum_pre_14',
							},
						}
					}
				},
				-- gimmick
				gimmick = {
				},
			},
			-- 밤
			{
				-- npc
				npc = {
					-- 광장 하부 NPC
					ghost_event_group_1 = {
						zone_name = 'ghost_group_1_zone',
						fo = {
							--1번(dv_female_type_a)[3번 타입] : right, idle, idle
							{
								key = 'dv_female_type_a',
								preset_key = 'ghost',
								position = 'pooled_night_group_1_pos_1',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
							--2번(dv_female_type_c)[3번 타입] : down, attack, idle
							--접근시 down, 3타일 0.5초
							{
								key = 'dv_female_type_c',
								preset_key = 'ghost',
								position = 'pooled_night_group_1_pos_2',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
						},
					},
					-- 광장 중앙 구역 원라인 NPC
					ghost_event_group_2 = {
						zone_name = 'ghost_group_2_zone',
						fo = {
							--1번(dv_female_type_b)[3번 타입] : right
							--가까이 가면 등장
							{
								key = 'dv_female_type_a',
								preset_key = 'ghost',
								position = 'pooled_night_group_2_pos_1',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
							--2번(dv_female_type_c)[3번 타입] : left, idle, idle : 흐어어어….
							--가까이 가면 등장
							{
								key = 'dv_female_type_c',
								preset_key = 'ghost',
								position = 'pooled_night_group_2_pos_2',
								direction = direction_constants.left,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
							--3번(dv_male_type_b)[3번 타입] : left, attack, idle
							--접근시 left, 3타일 0.5초
							{
								key = 'dv_male_type_b',
								preset_key = 'ghost',
								position = 'pooled_night_group_2_pos_3',
								direction = direction_constants.left,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.left,
									}
								}
							},
						}
					},
					-- 시장 구역의 원라인
					ghost_event_group_3 = {
						zone_name = 'ghost_group_3_zone',
						fo = {
							--1번(dv_china_merchant)[2번 타입] : right
							--가까이 가면 등장
							{
								key = 'dv_china_merchant',
								preset_key = 'ghost',
								position = 'pooled_night_group_3_pos_1',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
							--2번(dv_female_type_b)[2번 타입] : left, idle, idle
							--가까이 가면 등장
							{
								key = 'dv_female_type_b',
								preset_key = 'ghost',
								position = 'pooled_night_group_3_pos_2',
								direction = direction_constants.left,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									}
								}
							},
							--3번(dv_female_type_c)[3번 타입] : down, attack, idle
							--접근시 down, 3타일 0.5초
							{
								key = 'dv_female_type_c',
								preset_key = 'ghost',
								position = 'pooled_night_group_3_pos_3',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									}
								}
							},
						}
					},
					-- 박물관 대기열 바깥 알바생 존
					ghost_event_group_4 = {
						zone_name = 'museum_ghost_zone',
						fo = {
							{
								key = 'museum_museum_male',
								preset_key = 'ghost',
								position = 'museum_night_group_1_pos_1',
								direction = direction_constants.left,
								anim = { name = 'dance', one_shot_sfx = false },
							},
							{
								key = 'museum_museum_male',
								preset_key = 'ghost',
								position = 'museum_night_group_1_pos_2',
								direction = direction_constants.right,
								anim = { name = 'dance', one_shot_sfx = false },
							}
						}
					},
					-- 박물관 대기열 존
					ghost_event_group_5 = {
						zone_name = 'museum_ghost_zone',
						fo = {
							{
								key = 'museum_museum_male',
								preset_key = 'ghost',
								position = 'museum_night_group_2_pos_1',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									}
								}
							},
							{
								key = 'museum_museum_male',
								preset_key = 'ghost',
								position = 'museum_night_group_2_pos_2',
								direction = direction_constants.down,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									}
								}
							}
						}
					},

					ghost_event_group_6 = {
						zone_name = 'ghost_group_3_zone',
						override_quest_id = 441,
						progress_infos = {
							{
								from = 14,
								to = 'clear'
							}
						},
						fo = {
							{
								key = 'main_keeper_female',
								preset_key = 'ghost',
								position = 'ghost_keeper_female_pos',
								direction = direction_constants.right,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.right,
									}
								}
							}
						}
					},

					ghost_event_group_7 = {
						zone_name = 'gc_ghost_zone',
						override_quest_id = 453,
						progress_infos = {
							{
								from = -1,
								to = 1
							}
						},
						fo = {
							{
								key = 'dv_male_type_a',
								preset_key = 'ghost',
								position = 'gc_ghost_pos',
								direction = direction_constants.left,
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.left,
									}
								}
							},
						}
					},

					ghost_event_yokai_blocking = yokai_blocking_ghost
				},
				-- gimmick
				gimmick = {},
			}
		},
	},

	--TODO: 메인 4스테이지
	['dreamvillage_4'] = {
		-- 밤/낮 타일맵 전환 관리 기믹 핸들네임
		animator_fo_name = 'visual_controller',

		-- 밤/낮 전환 애니메이터 종류 (복수가 될 수 있기에 배열로)
		animation_name = {
			daylight = 'daylight',
			night = 'night'
		},

		-- 비네트 효과가 비활성화될 그리드 (ex) 실내, 동굴)
		disable_vignette_grid_list = {
			'inn_grid_1', 'inn_grid_2', 'inn_grid_3',
			'house_grid_1', 'house_grid_2', 'house_grid_3', 'house_grid_4', 'house_grid_5', 'house_grid_6', 'house_grid_7',
			'cave_grid_1', 'yokai_statue',
		},

		-- 시작할 타임 인덱스 (1: 낮 / 2: 밤)
		start_time_index = 1,

		-- 스테이터스가 비활성화될 존
		disabled_zone_data = {
		},

		quest_id = 441,

		npc_pools = {
			-- 원라인 NPC
			dv_male_type_a = {
				prefix = 'pooled_dv_male_type_a_',
				count = 31,
			},
			dv_male_type_b = {
				prefix = 'pooled_dv_male_type_b_',
				count = 14,
			},
			dv_male_type_c = {
				prefix = 'pooled_dv_male_type_c_',
				count = 5,
			},

			dv_female_type_a = {
				prefix = 'pooled_dv_female_type_a_',
				count = 7,
			},
			dv_female_type_b = {
				prefix = 'pooled_dv_female_type_b_',
				count = 6,
			},

			dv_male_old = {
				prefix = 'pooled_dv_male_old_',
				count = 5,
			},

			dv_kid_male = {
				prefix = 'pooled_dv_kid_male_',
				count = 13,
			},
			dv_kid_female = {
				prefix = 'pooled_dv_kid_female_',
				count = 8,
			},

			dv_china_merchant = {
				prefix = 'pooled_dv_china_merchant_',
				count = 2,
			},
			dv_dungeon_mercenary_male = {
				prefix = 'pooled_dv_dungeon_mercenary_male_',
				count = 3,
			},

			dv_inn_keeper_female = {
				prefix = 'pooled_dv_inn_keeper_female_',
				count = 1,
			},
			dv_male_hulk = {
				prefix = 'pooled_dv_male_hulk_',
				count = 1,
			},


			-- 공주와 꼬마 이벤트
			dv_princess = {
				prefix = 'pooled_dv_princess_',
				count = 1,
			},

			dv_kid_female_friend = {
				prefix = 'pooled_dv_kid_female_friend_',
				count = 1,
			},

			dv_kid_male_friend = {
				prefix = 'pooled_dv_kid_male_friend_',
				count = 1,
			},

			-- 서브 퀘스트 블리치 패러디
			dv_secret_prisoner = {
				prefix = 'pooled_dv_secret_prisoner_',
				count = 1,
			}
		},

		stage_setting = {
			-- 낮
			{
				-- npc
				npc = {
					-- 원라인 NPC 처리
					-- 여관 (낮)
					stage_4_inn_inside_event = {
						fo = {
							-- group 1
							{
								-- (남)1번(dv_male_type_c)(right, attack, idle) : 뭐야, 오늘 장사 망했나봐?
								key = 'dv_male_type_c',
								position = 'oneline_day_1_1',
								direction = direction_constants.right,
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage_4_oneline_day_1_1' }
							},
							{
								-- (남)2번(dv_male_type_a)(up, idle, idle) : 계세요…? 어디 가신거야…?
								key = 'dv_male_type_a',
								position = 'oneline_day_1_2',
								direction = direction_constants.up,
								talk = { key = 'dv_stage_4_oneline_day_1_3' }
							},
							{
								-- (남)3번(dv_male_type_a)(up, idle, idle) : 다리 아파… 이제 좀 눕고 싶은데…
								key = 'dv_male_type_a',
								position = 'oneline_day_1_3',
								direction = direction_constants.up,
								talk = { key = 'dv_stage_4_oneline_day_1_4' }
							},
							{
								-- (남)4번(dv_dungeon_mercenary_male)(right, tired, idle) : 축제인데 영업을 안하는 건가?
								key = 'dv_dungeon_mercenary_male',
								position = 'oneline_day_1_4',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_1_5' }
							},
							{
								-- (남)5번(dv_dungeon_mercenary_male)(right, tired, idle) : 그건 아닌거 같은데… 뭔가 자리를 자주 비우시네.
								key = 'dv_dungeon_mercenary_male',
								position = 'oneline_day_1_5',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_1_6' }
							},
							{
								-- (남)6번(dv_dungeon_mercenary_male)(left, tired, idle) : 흠… 여관 운영이 질리신 걸까…
								key = 'dv_dungeon_mercenary_male',
								position = 'oneline_day_1_6',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_1_7' }
							},
							{
								-- (남)7번(dv_male_type_c)(right, tired, idle) : 야… 이제 그 옷 벗을때도 되지 않았냐?
								key = 'dv_male_type_c',
								position = 'oneline_day_1_7',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_1_8' }
							},
							{
								-- (남)8번(dv_male_type_c)(left, smile, cast2) : 왜? 얼마나 멋있는데. 이 멋짐을 모르는 네가 불쌍한 걸!
								key = 'dv_male_type_c',
								position = 'oneline_day_1_8',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_1_9' }
							},
							{
								-- (남)9번(dv_china_merchant)(left, tired, bomb_idle) : 말도 마. 왠 진상들을 만나서….
								key = 'dv_china_merchant',
								position = 'oneline_day_1_9',
								direction = direction_constants.left,
								anim = { name = 'bomb_idle' },
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_1_2' }
							},

							-- group 2
							{
								-- (남)1번(dv_male_type_a)(down, smile, cast) : 다들 축제 나가기 전에 번호를 세자! 오른쪽부터 번호 하나!
								key = 'dv_male_type_a',
								position = 'oneline_day_2_1',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_1' }
							},
							{
								-- (남)2번(dv_kid_male)(right, smile, idle) : 하나!
								key = 'dv_kid_male',
								position = 'oneline_day_2_2',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_2' }
							},
							{
								-- (남)3번(dv_kid_male)(right, smile, idle) : 둘!
								key = 'dv_kid_male',
								position = 'oneline_day_2_3',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_3' }
							},
							{
								-- (여)4번(dv_kid_female)(left, smile, idle) : 셋!
								key = 'dv_kid_female',
								position = 'oneline_day_2_4',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_4' }
							},
							{
								-- (여)5번(dv_kid_female)(left, smile, idle) : 넷! 번호 끝!
								key = 'dv_kid_female',
								position = 'oneline_day_2_5',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_5' }
							},
							{
								-- (여)6번(dv_female_type_b)(down, smile, cast) : 좋아! 다들 서로 손 꼭잡고 놓치면 안된다!
								key = 'dv_female_type_b',
								position = 'oneline_day_2_6',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_2_6' }
							},
							{
								-- (남)7번(dv_male_type_b)(right, attack, cast2) : 그러니까 내 말은… 뽑기부터 해야 한다 이말이야!
								key = 'dv_male_type_b',
								position = 'oneline_day_2_7',
								direction = direction_constants.right,
								anim = { name = 'cast2' },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage_4_oneline_day_2_7' }
							},
							{
								-- (남)8번(dv_male_type_a)(left, attack, cast2) : 내가 몇번을 말해! 중앙에 석상부터 보고…
								key = 'dv_male_type_a',
								position = 'oneline_day_2_8',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage_4_oneline_day_2_8' }
							},
							{
								-- (남)9번(dv_male_type_b)(left, attack, cast2) : 참 말 안통하네. 우선 다리에서 사진부터 찍고…
								key = 'dv_male_type_b',
								position = 'oneline_day_2_9',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage_4_oneline_day_2_9' }
							},
						}
					},

					-- 여관 앞 이벤트 (낮)
					stage_4_inn_front_event = {
						fo = {
							-- group 1
							{
								-- (여)1번(dv_inn_keeper_female)(down, tired, idle) : 하아… 정말 귀찮다고 생각했는데… 막상 멀쩡해지니 원…
								key = 'dv_inn_keeper_female',
								position = 'oneline_day_3_1',
								direction = direction_constants.down,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_3_1' }
							},
							{
								-- (남)2번(dv_kid_male)(up, idle, idle) : 왜그래요 아주머니? 무슨 일 있으세요?
								key = 'dv_kid_male',
								position = 'oneline_day_3_2',
								direction = direction_constants.up,
								talk = { key = 'dv_stage_4_oneline_day_3_2' }
							},
							{
								-- (여)3번(dv_kid_female)(left, attack, idle) : 그거 몰라? 우리 동네 바보 칠득이가 멀쩡해졌대!
								key = 'dv_kid_female',
								position = 'oneline_day_3_3',
								direction = direction_constants.left,
								emotion = { name = 'attack' },
								talk = { key = 'dv_stage_4_oneline_day_3_3' }
							},
							{
								-- (남)4번(dv_male_type_a)(left, sleep_deep, cross_arm) : 흠… 오늘은 밖에서 자볼까? 요즘에 주변도 조용하고….
								key = 'dv_male_type_a',
								position = 'oneline_day_3_4',
								direction = direction_constants.left,
								emotion = { name = 'sleep_deep' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_3_4' }
							},
							{
								-- ((남)5번(dv_male_old)(right, smile, idle) : 오호라. 오늘은 할멈 몰래 여관에서 자볼까!
								key = 'dv_male_old',
								position = 'oneline_day_3_5',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_3_5' }
							},
						}
					},

					-- 마을 아래쪽 (낮)
					stage_4_village_down_side_event = {
						fo = {
							{
								-- (여)1번(dv_male_type_a)(right, tired, cross_arm) : 흠… 축제에서 할 게 더 있으려나?
								key = 'dv_male_type_a',
								position = 'oneline_day_4_1',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_4_1' }
							},
							{
								-- (남)2번(dv_kid_male)(right, awesome, cast2) : 평생 축제가 안끝났으면 좋겠어! 그럼 다들 좋을텐데!
								key = 'dv_kid_male',
								position = 'oneline_day_4_2',
								direction = direction_constants.right,
								emotion = { name = 'awesome' },
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage_4_oneline_day_4_2' }
							},
							{
								-- (남)3번(dv_kid_male)(left, tired, idle) : 음… 축제 위원회는 힘들지 않을까?
								key = 'dv_kid_male',
								position = 'oneline_day_4_3',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_4_3' }
							},
							{
								-- (여)4번(dv_female_type_a)(left, sleep_deep, idle) : 안돼. 안사줄 거야. 집에 가자.
								key = 'dv_female_type_a',
								position = 'oneline_day_4_4',
								direction = direction_constants.left,
								emotion = { name = 'sleep_deep' },
								talk = { key = 'dv_stage_4_oneline_day_4_4' }
							},
							{
								-- (여)5번(dv_kid_female)(left, cry, seat) : 엄마아아아아! 나 사탕 하나마아아아안!
								key = 'dv_kid_female',
								position = 'oneline_day_4_5',
								direction = direction_constants.left,
								emotion = { name = 'cry' },
								anim = { name = 'seat' },
								talk = { key = 'dv_stage_4_oneline_day_4_5' }
							},
							{
								-- (남)6번(dv_male_type_b)(right, smile, idle) : 초치는 소리 하지마! 축제 구경이나 가자!
								key = 'dv_male_type_b',
								position = 'oneline_day_4_6',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_4_6' }
							},
							{
								-- (남)7번(dv_male_type_a)(left, sleep_deep, idle) : 우린 축제라는 유흥과 향락에 빠져 정신이 나태해지는 환경을 각별히 주의해야….
								key = 'dv_male_type_a',
								position = 'oneline_day_4_7',
								direction = direction_constants.left,
								emotion = { name = 'sleep_deep' },
								talk = { key = 'dv_stage_4_oneline_day_4_7' }
							},
						}
					},

					-- 마을 중앙 (낮)
					stage_4_village_center_event = {
						fo = {
							center_kid_1 = {
								-- 1번 (dv_kid_male), 1-1번 위치에서 (right, smile, idle) 상태 적용.
								key = 'dv_kid_male',
								position = 'oneline_day_5_1_1',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
							},
							center_kid_2 = {
								-- 2번 (dv_kid_female), 2-1번 위치에서 (left, smile, idle) 상태 적용.
								key = 'dv_kid_female',
								position = 'oneline_day_5_2_1',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
							},
							{
								-- (남)3번(dv_male_type_a)(right, attack, cast2) : 석상을 부수는 야만적인 활동은 사라져야 한다고 생각해!
								key = 'dv_male_type_a',
								position = 'oneline_day_5_3',
								direction = direction_constants.right,
								emotion = { name = 'attack' },
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage_4_oneline_day_5_2' }
							},
							{
								-- (남)4번(dv_male_type_b)(right, tired, cross_arm) : 음… 너 주변에서 눈치 없다는 소리 많이 듣지?
								key = 'dv_male_type_b',
								position = 'oneline_day_5_4',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_5_3' }
							},
							{
								-- (남)5번(dv_male_hulk)(left, attack, cast) : 왜 나에게는 예언이 내려지지 않는 거야! 왜?!
								key = 'dv_male_hulk',
								position = 'oneline_day_5_5',
								direction = direction_constants.left,
								emotion = { name = 'attack' },
								anim = { name = 'cast' },
								talk = { key = 'dv_stage_4_oneline_day_5_4' }
							},
							{
								-- (여)6번(dv_female_type_a)(right, tired, cross_arm) : 오늘은 어디로 간 거야… 이번엔 봐주려고 했는데….
								key = 'dv_female_type_a',
								position = 'oneline_day_5_6',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_5_5' }
							},
							{
								-- (여)7번(dv_female_type_b)(left, awesome, cast2) : 너희 아빠가 어릴적에 얼마나 약골이었는지 아니? 몽둥이 하나 못들고서….
								key = 'dv_female_type_b',
								position = 'oneline_day_5_7',
								direction = direction_constants.left,
								emotion = { name = 'awesome' },
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage_4_oneline_day_5_6' }
							},
							{
								-- (남)8번(dv_male_type_b)(left, blush, idle) : 아유 이 사람이… 부끄럽게시리…
								key = 'dv_male_type_b',
								position = 'oneline_day_5_8',
								direction = direction_constants.left,
								emotion = { name = 'blush' },
								talk = { key = 'dv_stage_4_oneline_day_5_7' }
							},
							{
								-- (남)9번(dv_kid_male)(left, smile, idle) : 뭐야! 아빠는 엄청 센줄 알았는데!
								key = 'dv_kid_male',
								position = 'oneline_day_5_9',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
								talk = { key = 'dv_stage_4_oneline_day_5_8' }
							},
						}
					},

					-- 마을 윗쪽 (낮)
					stage_4_village_up_side_event = {
						fo = {
							{
								-- (남)1번(dv_male_type_a)(right, tired, cross_arm) : 흠… 이젠 뭘 사야 하지…?
								key = 'dv_male_type_a',
								position = 'oneline_day_6_1',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_6_1' }
							},
							{
								-- (남)2번(dv_male_type_b)(right, attack, cast2) : 5개는 너무 적소. 10개는 받아야겠어.
								key = 'dv_male_type_b',
								position = 'oneline_day_6_2',
								direction = direction_constants.right,
								emotion = { name = 'attack' },
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage_4_oneline_day_6_2' }
							},
							{
								-- (남)3번(dv_male_old)(left, tired, cast) : 아니… 두배는 너무 날강도 심보 같은데….
								key = 'dv_male_old',
								position = 'oneline_day_6_3',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								anim = { name = 'cast' },
								talk = { key = 'dv_stage_4_oneline_day_6_3' }
							},
							{
								-- (남)4번(dv_male_type_a)(down, tired, idle) : 장사가 한창인데… 손님 하나 없네….
								key = 'dv_male_type_a',
								position = 'oneline_day_6_4',
								direction = direction_constants.down,
								emotion = { name = 'tired' },
								talk = { key = 'dv_stage_4_oneline_day_6_4' }
							},
							{
								-- (여)5번(dv_female_type_b)(right, tired, cross_arm) : 진짜 싸네… 싸니까 품질이 이상한 건….
								key = 'dv_female_type_b',
								position = 'oneline_day_6_5',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_stage_4_oneline_day_6_5' }
							},
							{
								-- (남)6번(dv_china_merchant)(left, attack, cast2) : 뭘로 보고 그런 소리를 하신대! 싫음 딴데 알아보셔!
								key = 'dv_china_merchant',
								position = 'oneline_day_6_6',
								direction = direction_constants.left,
								emotion = { name = 'attack' },
								anim = { name = 'cast2' },
								talk = { key = 'dv_stage_4_oneline_day_6_6' }
							},
						}
					},

					-- 공주와 꼬마 이벤트
					stage_4_princess_n_kids_event = {
						progress_infos = {
							{
								from = 16,
								to = 17,
							}
						},
						fo = {
							princess = {
								key = 'dv_princess',
								position = 'day_event_1_princess_1',
								direction = direction_constants.right,
								emotion = { name = 'smile' },
							},
							kid_female_friend = {
								key = 'dv_kid_female_friend',
								position = 'day_event_1_friend_kid_girl_1',
								direction = direction_constants.left,
								emotion = { name = 'smile' },
							},
							kid_male_friend = {
								key = 'dv_kid_male_friend',
								position = 'day_event_1_friend_kid_boy_1',
								direction = direction_constants.left,
								emotion = { name = 'sleep_deep' },
							},
						}
					},

					-- 서브 퀘스트 블리치 패러디
					stage_4_sub_secret_prisoner_event = {
						override_quest_id = 446,
						progress_infos = {
							{
								from = 0,
								to = 0,
							}
						},

						fo = {
							secret_prisoner = {
								key = 'dv_secret_prisoner',
								position = 'sub_sp_secret_prisoner_1_1',
								direction = direction_constants.left,
								emotion = { name = 'doyagao' },
							},
						}
					},

					stage_4_sub_grain_tea_pos_section_event = {
						override_quest_id = 454,
						progress_infos = {
							{
								from = 'clear',
								to = 'clear',
							}
						},
						fo = {
							female_2 = {
								-- 여2 (right, tired, bomb_idle) : 뭐야, 새로 곡물차 만들었대서 왔더니…
								key = 'dv_female_type_b',
								position = 'sub_gt_post_female_pos',
								direction = direction_constants.right,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_grain_tea_post_1' }
							},
							male_2 = {
								-- 남2 (left, tired, cross_arm) : 아니, 손님 다 내쫓고 자기가 마시는 경우가 어딨어?
								key = 'dv_male_type_b',
								position = 'sub_gt_post_male_pos',
								direction = direction_constants.left,
								emotion = { name = 'tired' },
								anim = { name = 'cross_arm' },
								talk = { key = 'dv_grain_tea_post_2' }
							},
						}
					}
				},
				-- gimmick
				gimmick = {},
			},
			-- 밤
			{
				-- npc
				npc = {
					-- 원라인 NPC 처리
					-- 여관 1 (밤)
					ghost_event_inside_1 = {
						zone_name = 'ghost_zone_1_2',
						fo = {
							-- group 1
							{
								-- (남)1번(dv_china_merchant)(right, empty, sing) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_c',
								position = 'oneline_night_1_1',
								direction = direction_constants.right,
								anim = { name = 'sing' },
								preset_key = 'ghost',
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								},
							},
							{
								-- (남)2번(dv_china_merchant)(left, empty, sing) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_1_2',
								direction = direction_constants.left,
								anim = { name = 'sing' },
								preset_key = 'ghost',
								setting_data = {
									hiding = {
										-- 최대 계산 거리
										max_dist = 5,
										-- 최소 계산 거리
										min_dist = 1.5,
										-- 최대 alpha 값
										max_alpha = 0.8,
									},
								},
							},
						}
					},

					-- 여관 2 (밤)
					ghost_event_inside_2 = {
						zone_name = 'ghost_zone_1_1',
						fo = {
							{
								-- (남)3번(dv_male_type_b)(left, empty, cast2) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_1_3',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 3,
									},
								},
							},
							{
								-- (남)4번(dv_male_type_a)(down, empty, cast2) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_1_4',
								direction = direction_constants.down,
								anim = { name = 'cast2' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 3,
									},
								},
							},
							{
								-- (남)5번(dv_male_type_c)(up, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_c',
								position = 'oneline_night_1_5',
								direction = direction_constants.up,
								preset_key = 'ghost_type_a',
							},
						}
					},

					-- 여관 3 (밤)
					ghost_event_inside_3 = {
						zone_name = 'ghost_zone_2_1',
						fo = {
							{
								-- (남)1번(dv_kid_male)(right, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_2_1',
								direction = direction_constants.right,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)2번(dv_kid_male)(right, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_2_2',
								direction = direction_constants.right,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (여)3번(dv_kid_female)(left, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_female',
								position = 'oneline_night_2_3',
								direction = direction_constants.left,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (여)4번(dv_kid_female)(left, empty, seat)  [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_female',
								position = 'oneline_night_2_4',
								direction = direction_constants.left,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)5번(dv_male_type_a)(down, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_2_5',
								direction = direction_constants.down,
								emotion = { name = 'tired' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)6번(dv_female_type_a)(down, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_female_type_a',
								position = 'oneline_night_2_6',
								direction = direction_constants.down,
								emotion = { name = 'tired' },
								preset_key = 'ghost_type_a',
							},

						}
					},

					-- 여관 4 (밤)
					ghost_event_inside_4 = {
						zone_name = 'ghost_zone_2_2',
						fo = {
							{
								-- (남)7번(dv_male_type_b)(left, empty, push) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_b',
								position = 'oneline_night_2_7',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)8번(dv_male_type_a)(left, empty, prostrate) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_2_8',
								direction = direction_constants.left,
								anim = { name = 'prostrate' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)9번(dv_male_type_a)(left, empty, prostrate) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_2_9',
								direction = direction_constants.left,
								anim = { name = 'prostrate' },
								preset_key = 'ghost_type_a',
							},
						}
					},

					-- 여관 앞 이벤트 (밤)
					ghost_event_inn_front = {
						zone_name = 'ghost_zone_3',
						fo = {
							{
								-- (남)1번(dv_male_type_a)(up, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_3_1',
								direction = direction_constants.up,
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)2번(dv_male_type_b)(left, empty, cast2) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_male_type_b',
								position = 'oneline_night_3_2',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 3,
									},
								},
							},
							{
								-- (남)3번(dv_male_type_b)(left, empty, cast2) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_male_type_b',
								position = 'oneline_night_3_3',
								direction = direction_constants.left,
								anim = { name = 'cast2' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 3,
									},
								},
							},
							{
								-- (남)4번(dv_male_type_a)(down, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_3_4',
								direction = direction_constants.down,
								preset_key = 'ghost_type_a',
							},
						}
					},

					-- 마을 아래쪽 (밤)
					ghost_event_village_down_side = {
						zone_name = 'ghost_zone_4',
						fo = {
							{
								-- (남)1번(dv_male_old)(right, empty, cast2) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_male_old',
								position = 'oneline_night_4_1',
								direction = direction_constants.right,
								anim = { name = 'cast2' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)2번(dv_male_type_a)(left, empty, prostrate) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_4_2',
								direction = direction_constants.left,
								anim = { name = 'prostrate' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)3번(dv_female_type_a)(down, empty, cast) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_female_type_a',
								position = 'oneline_night_4_3',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)4번(dv_female_type_b)(right, empty, reelase) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_female_type_b',
								position = 'oneline_night_4_4',
								direction = direction_constants.right,
								anim = { name = 'release' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)5번(dv_male_type_b)(left, empty, idle) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_b',
								position = 'oneline_night_4_5',
								direction = direction_constants.left,
								preset_key = 'ghost_type_a',
							},
						}
					},

					-- 마을 중앙 (밤)
					ghost_event_village_center = {
						zone_name = 'ghost_zone_5',
						fo = {
							{
								-- (남)1번(dv_male_old)(down, empty, cast) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_old',
								position = 'oneline_night_5_1',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)2번(dv_male_type_a)(right, empty, push) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_5_2',
								direction = direction_constants.right,
								anim = { name = 'push' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)3번(dv_kid_female)(down, empty, cast) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_kid_female',
								position = 'oneline_night_5_3',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)4번(dv_kid_male)(right, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_5_4',
								direction = direction_constants.right,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)5번(dv_kid_male)(right, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_5_5',
								direction = direction_constants.right,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)6번(dv_kid_male)(left, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_5_6',
								direction = direction_constants.left,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- (남)7번(dv_kid_male)(left, empty, seat) [2]
								-- 유령 [2]번 사양 적용
								key = 'dv_kid_male',
								position = 'oneline_night_5_7',
								direction = direction_constants.left,
								anim = { name = 'seat' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
						}
					},

					-- 마을 윗쪽 (밤)
					ghost_event_village_up_side = {
						zone_name = 'ghost_zone_6',
						fo = {
							{
								-- (남)1번(dv_male_old)(down, empty, cast)  [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_old',
								position = 'oneline_night_6_1',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)2번(dv_male_type_a)(down, empty, cast) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_a',
								position = 'oneline_night_6_2',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (남)3번(dv_male_type_b)(down, empty, cast2) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_male_type_b',
								position = 'oneline_night_6_3',
								direction = direction_constants.down,
								anim = { name = 'cast2' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)4번(dv_female_type_a)(down, empty, cast) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_female_type_a',
								position = 'oneline_night_6_4',
								direction = direction_constants.down,
								anim = { name = 'cast' },
								preset_key = 'ghost_type_a',
							},
							{
								-- (여)5번(dv_female_type_b)(left, empty, sing) [1]
								-- 유령 [1]번 사양 적용
								key = 'dv_female_type_b',
								position = 'oneline_night_6_5',
								direction = direction_constants.left,
								anim = { name = 'sing' },
								preset_key = 'ghost_type_a',
							},
						}
					},

					-- 메인 섹션18
					ghost_event_s18_older_twin_1 = {
						progress_infos = {
							{
								from = 17,
								to = 17,
							}
						},
						zone_name = 's18_ghost_zone_1',
						fo = {
							{
								-- (남)1번(dv_male_type_a)(right, empty, idle) [3]
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_a',
								position = 's18_1_barricate_1',
								direction = direction_constants.right,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										dist = 6,
										dir = direction_constants.right,
									},
								},
							},
							{
								-- (남)2번(dv_male_type_a)(right, empty, idle) [3]
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_a',
								position = 's18_1_barricate_2',
								direction = direction_constants.right,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										dist = 6,
										dir = direction_constants.right,
									},
								},
							},
							{
								-- (남)3번(dv_male_type_a)(right, empty, idle) [3]
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_a',
								position = 's18_1_barricate_3',
								direction = direction_constants.right,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										dist = 6,
										dir = direction_constants.right,
									},
								},
							},
							{
								-- (남)4번(dv_male_type_a)(right, empty, idle) [3]
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_a',
								position = 's18_1_barricate_4',
								direction = direction_constants.right,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										dist = 6,
										dir = direction_constants.right,
									},
								},
							},

						},
					},


					ghost_event_grain_tea_outside_progress = {
						override_quest_id = 454,
						progress_infos = {
							{
								from = -1,
								to = 1,
							},
						},

						zone_name = 'sub_gt_enter_area',

						fo = {
							{
								-- 여1 (down, empty, idle)
								-- 유령 [3]번 사양 적용
								key = 'dv_female_type_a',
								position = 'sub_gt_barricate_1',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- 남1 (down, empty, idle)
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_a',
								position = 'sub_gt_barricate_2',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
							{
								-- 남2 (down, empty, idle)
								-- 유령 [3]번 사양 적용
								key = 'dv_male_type_b',
								position = 'sub_gt_barricate_3',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
									},
								},
							},
						}

					},

					ghost_event_sub_sp = {
						zone_name = 'ghost_zone_sub_sp',
						fo = {
							{
								key = 'dv_male_type_b',
								position = 'sub_sp_entrance_ghost',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
                                        -- 도망가는 방향
                                        dir = direction_constants.right,
									},
								},
							},
						}
					},

					ghost_event_yokai_blocking = yokai_blocking_ghost
				},

				-- gimmick
				gimmick = {
				},
			}
		},
	},

	--TODO: 메인 5스테이지
	['dreamvillage_5'] = {
		-- 밤/낮 타일맵 전환 관리 기믹 핸들네임
		animator_fo_name = 'visual_controller_1',

		-- 밤/낮 전환 애니메이터 종류 (복수가 될 수 있기에 배열로)
		animation_name = {
			daylight = 'daylight',
			night = 'night'
		},

		-- 시작할 타임 인덱스 (1: 낮 / 2: 밤)
		start_time_index = 1,

		-- 타겟 메인 퀘스트 id
		quest_id = 441,

		-- 스테이터스가 비활성화될 존
		disabled_zone_data = {
		},

		--TODO: 메인 5스테이지
		npc_pools = {
			dv_female_type_a = {
				prefix = 'pooled_dv_female_type_a_',
				count = 4,
			},

			dv_female_type_b = {
				prefix = 'pooled_dv_female_type_b_',
				count = 4,
			},

			dv_female_type_c = {
				prefix = 'pooled_dv_female_type_c_',
				count = 4,
			},

			dv_male_type_a = {
				prefix = 'pooled_dv_male_type_a_',
				count = 9,
			},

			dv_male_type_b = {
				prefix = 'pooled_dv_male_type_b_',
				count = 4,
			},

			dv_male_type_c = {
				prefix = 'pooled_dv_male_type_c_',
				count = 4,
			},

			dv_kid_male = {
				prefix = 'pooled_dv_kid_male_',
				count = 3,
			},

			dv_kid_female = {
				prefix = 'pooled_dv_kid_female_',
				count = 3,
			},

			dv_female_old = {
				prefix = 'pooled_dv_female_old_',
				count = 3,
			},

			dv_male_old = {
				prefix = 'pooled_dv_male_old_',
				count = 3,
			},

			dv_hulk_male = {
				prefix = 'pooled_dv_hulk_male_',
				count = 3,
			},

			dv_china_merchant = {
				prefix = 'pooled_dv_china_merchant_',
				count = 3,
			},

			main_keeper_female = {
				prefix = 'pooled_dv_inn_keeper_female_',
				count = 1
			},

			dv_liar_prophet_male = {
				prefix = 'pooled_dv_liar_prophet_male_',
				count = 1,
			},

			dv_dungeon_mercenary_male = {
				prefix = 'pooled_dv_dungeon_mercenary_male_',
				count = 3,
			},
		},

		stage_setting = {
			-- 낮
			{
				-- npc
				npc = {},
				-- gimmick
				gimmick = {},
			},
			-- 밤
			{
				-- npc
				npc = {
					ghost_event_inside_1 = {
						zone_name = 'reaper_block_zone',
						fo = {
							{
								key = 'dv_male_type_a',
								position = 'stage5_oneline_pos_1',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								key = 'dv_male_type_a',
								position = 'stage5_oneline_pos_2',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								key = 'dv_male_type_a',
								position = 'stage5_oneline_pos_3',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								key = 'dv_male_type_a',
								position = 'stage5_oneline_pos_4',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
							{
								key = 'dv_male_type_a',
								position = 'stage5_oneline_pos_5',
								direction = direction_constants.down,
								preset_key = 'ghost',
								setting_data = {
									surprise = {
										-- 유령이 감지 하는 범위
										sight = 1.5,
										-- 도망가는 방향
										dir = direction_constants.down,
									},
								},
							},
						}
					},
					ghost_event_sub_starpiece = {
						fo = {
							{
								key = 'dv_male_type_a',
								position = 'ghost_starpiece_oneline_pos_1',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_b',
								position = 'ghost_starpiece_oneline_pos_2',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_c',
								position = 'ghost_starpiece_oneline_pos_3',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_a',
								position = 'ghost_starpiece_oneline_pos_4',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_b',
								position = 'ghost_starpiece_oneline_pos_5',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_c',
								position = 'ghost_starpiece_oneline_pos_6',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_old',
								position = 'ghost_starpiece_oneline_pos_7',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_old',
								position = 'ghost_starpiece_oneline_pos_8',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_hulk_male',
								position = 'ghost_starpiece_oneline_pos_9',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_china_merchant',
								position = 'ghost_starpiece_oneline_pos_10',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_dungeon_mercenary_male',
								position = 'ghost_starpiece_oneline_pos_11',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_male',
								position = 'ghost_starpiece_oneline_pos_12',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_a',
								position = 'ghost_starpiece_oneline_pos_13',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'main_keeper_female',
								position = 'ghost_starpiece_oneline_pos_14',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_b',
								position = 'ghost_starpiece_oneline_pos_15',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_c',
								position = 'ghost_starpiece_oneline_pos_16',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_b',
								position = 'ghost_starpiece_oneline_pos_17',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_c',
								position = 'ghost_starpiece_oneline_pos_18',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_a',
								position = 'ghost_starpiece_oneline_pos_19',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_old',
								position = 'ghost_starpiece_oneline_pos_20',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_old',
								position = 'ghost_starpiece_oneline_pos_21',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_hulk_male',
								position = 'ghost_starpiece_oneline_pos_22',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_china_merchant',
								position = 'ghost_starpiece_oneline_pos_23',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_dungeon_mercenary_male',
								position = 'ghost_starpiece_oneline_pos_24',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_male',
								position = 'ghost_starpiece_oneline_pos_25',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_female',
								position = 'ghost_starpiece_oneline_pos_26',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_china_merchant',
								position = 'ghost_starpiece_oneline_pos_27',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_b',
								position = 'ghost_starpiece_oneline_pos_28',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_c',
								position = 'ghost_starpiece_oneline_pos_29',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_hulk_male',
								position = 'ghost_starpiece_oneline_pos_30',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_b',
								position = 'ghost_starpiece_oneline_pos_31',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_dungeon_mercenary_male',
								position = 'ghost_starpiece_oneline_pos_32',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_old',
								position = 'ghost_starpiece_oneline_pos_33',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_old',
								position = 'ghost_starpiece_oneline_pos_34',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_liar_prophet_male',
								position = 'ghost_starpiece_oneline_pos_35',
								direction = direction_constants.left,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_a',
								position = 'ghost_starpiece_oneline_pos_36',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_a',
								position = 'ghost_starpiece_oneline_pos_37',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_c',
								position = 'ghost_starpiece_oneline_pos_38',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_female',
								position = 'ghost_starpiece_oneline_pos_39',
								direction = direction_constants.right,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_a',
								position = 'ghost_starpiece_oneline_pos_40',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_female',
								position = 'ghost_starpiece_oneline_pos_41',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_kid_male',
								position = 'ghost_starpiece_oneline_pos_42',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_a',
								position = 'ghost_starpiece_oneline_pos_43',
								direction = direction_constants.down,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_b',
								position = 'ghost_starpiece_oneline_pos_44',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_b',
								position = 'ghost_starpiece_oneline_pos_45',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_female_type_c',
								position = 'ghost_starpiece_oneline_pos_46',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
							{
								key = 'dv_male_type_c',
								position = 'ghost_starpiece_oneline_pos_47',
								direction = direction_constants.up,
								anim = { name = 'idle' },
								preset_key = 'ghost',
							},
						}
					},
				},
				-- gimmick
				gimmick = {},
			}
		},
	},

	--TODO: 그림자저택 서브스테이지
	['substage_20_2'] = {
		-- 밤/낮 타일맵 전환 관리 기믹 핸들네임
		animator_fo_name = 'visual_controller',

		-- 밤/낮 전환 애니메이터 종류 (복수가 될 수 있기에 배열로)
		animation_name = {
			daylight = 'daylight',
			night = 'night'
		},

		-- 시작할 타임 인덱스 (1: 낮 / 2: 밤)
		start_time_index = 1,

		-- 타겟 메인 퀘스트 id
		quest_id = 442,

		-- 비네트 효과가 비활성화될 그리드 (ex) 실내, 동굴)
		disable_vignette_grid_list = {
			'grid',
		},

		-- 밤/낮 바뀔 때 사용할 npc pools
		npc_pools = {
			dv_servant = {
				prefix = 'pooled_dv_servant_',
				count = 4,
			},
			dv_shadow_male = {
				prefix = 'pooled_dv_shadow_male_',
				count = 6,
			}
		},

		stage_setting = {
			-- 낮
			{
				-- npc
				npc = {},
				-- gimmick
				gimmick = {},
			},
			-- 밤
			{
				-- npc
				npc = {},
				-- gimmick
				gimmick = {},
			}
		},
	},
}
