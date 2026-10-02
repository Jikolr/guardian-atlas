-- ////////////////////////////////////////////////////////////////////////////   데이터 구조   /////////
--  아이템_이름 = {
--      price = 아이템 가격
--      id = 드랍 아이템일 시 id
--      sprite = 아이템 스프라이트
--      info = {
--          title = 아이템의 주 이름
--          sub_title = 아이템 획득 연출, 가판대에서 설명으로 사용될 타이틀
--          desc = 아이템 획득 연출에 사용될 아이템 설명문
--      },
--      handle_names = {
--          아이템 스프라이트를 배치해두고 싶은 장소의 핸들 네임을 넣어놓으면 됨
--          'handle_name_1',
--          'handle_name_2'
--      },
--      holdable = 들고 다닐 수 있는 오브젝트 인지?
--      play_item_get = 아이템 획득 연출을 틀어줄 것인지?
--      edible = 구매하자마자 먹는 모션을 취할 것인지? (True일 시 드랍 아이템 생성 ㄴ)
--      override_item_description = 이거 true면 아이템 이름과 설명문을 첫 설명때 같이 넣어줌.
--  }
--  ///////////////////////////////////////////////////////////////////////////////////////////////////

return {
	demonworld_part1_1_2 = {
		-- 해당 스테이지에서 사용하는 아이템들의 종류
		items = {
			store_massage_oil = {
				price = 1000,
				sprite = 'massage_oil',
				id = 20361,
				info = {
					title = 'massage_oil',
					subtitle = 'massage_oil_subtitle',
					desc = 'massage_oil_desc',
				},
				handle_names = {
					'store_massage_oil_a',
					'store_massage_oil_b',
				},
				holdable = true,
				play_item_get = true,
				should_store = false,
				edible = false
			},
			store_soylent_red = {
				price = 1000,
				sprite = 'soylent_red_can',
				id = 20367,
				info = {
					title = 'soylent_red_can',
					subtitle = 'soylent_red_can_subtitle',
					desc = 'soylent_red_can_desc'
				},
				handle_names = {
					'store_soylent_red_a',
					'store_soylent_red_b',
				},
				holdable = false,
				play_item_get = true,
				should_store = true,
				edible = false,
				override_item_description = true
			},
			store_sushi = {
				price = 500,
				sprite = 'oodevil_sushi',
				id = 20371,
				info = {
					title = 'sushi',
					subtitle ='sushi_subtitle',
					desc = nil
				},
				handle_names = {
					'store_sushi_a',
					'store_sushi_b'
				},
				holdable = false,
				play_item_get = false,
				should_store = false,
				edible = true
			}
		} ,
		--- @ key : 편의점 출구 쪽에 배치 되어있는 존의 이름
		--- @ value : 아이템이 존에 닿을 시 이동할 마커의 이름
		item_exit = {
			convenience_store_item_exit_a = 'convenience_store_a_exit',
			convenience_store_item_exit_b = 'convenience_store_b_exit',
		},

		entrances = {
			'store_a_exit',
			'store_b_exit'
		}
	},
	demonworld_part1_1_3 = {
		-- 해당 스테이지에서 사용하는 아이템들의 종류
		items = {
			store_soylent_red = {
				price = 1000,
				sprite = 'soylent_red_can',
				id = 20367,
				info = {
					title = 'soylent_red_can',
					subtitle = 'soylent_red_can_subtitle',
					desc = 'soylent_red_can_desc'
				},
				handle_names = {
					'store_soylent_red',
				},
				holdable = false,
				play_item_get = true,
				should_store = true,
				edible = false,
				override_item_description = true
			},
			store_sushi = {
				price = 500,
				sprite = 'oodevil_sushi',
				id = 20371,
				info = {
					title = 'sushi',
					subtitle ='sushi_subtitle',
					desc = nil
				},
				handle_names = {
					'store_sushi',
				},
				holdable = false,
				play_item_get = false,
				should_store = false,
				edible = true
			}
		} ,
		--- @ key : 편의점 출구 쪽에 배치 되어있는 존의 이름
		--- @ value : 아이템이 존에 닿을 시 이동할 마커의 이름
		item_exit = {
			convenience_store_item_exit = 'convenience_store_exit',
		},

		entrances = {
			'store_entrance'
		}
	},
	substage_12_1 = {
		items = {
			store_soylent_red = {
				price = 1000,
				sprite = 'soylent_red_can',
				id = 20367,
				info = {
					title = 'soylent_red_can',
					subtitle = 'soylent_red_can_subtitle',
					desc = 'soylent_red_can_desc'
				},
				handle_names = {
					'store_soylent_red',
				},
				holdable = false,
				play_item_get = true,
				should_store = true,
				edible = false,
				override_item_description = true
			},
			store_sushi = {
				price = 500,
				sprite = 'oodevil_sushi',
				id = 20371,
				info = {
					title = 'sushi',
					subtitle ='sushi_subtitle',
					desc = nil
				},
				handle_names = {
					'store_sushi',
				},
				holdable = false,
				play_item_get = false,
				should_store = false,
				edible = true
			}
		},
		item_exit = {
			convenience_store_item_exit = 'convenience_store_exit',
		},

		entrances = {
			'store_entrance'
		}
	},
	demonworld_part1_1_4 = {
		items = {
			store_sushi = {
				price = 500,
				sprite = 'oodevil_sushi',
				id = 20371,
				info = {
					title = 'sushi',
					subtitle ='sushi_subtitle',
					desc = nil
				},
				handle_names = {
					'store_sushi',
				},
				holdable = false,
				play_item_get = false,
				should_store = false,
				edible = true
			}
		},
		item_exit = {
			convenience_store_item_exit_a = 'convenience_store_a_exit',
			convenience_store_item_exit_b = 'convenience_store_b_exit',
		},
		entrances = {
			'store_a_exit',
			'store_b_exit'
		}
	},
	passage_12_2 = {
		items = {},
		item_exit = {},
		entrances = {}
	}
}
