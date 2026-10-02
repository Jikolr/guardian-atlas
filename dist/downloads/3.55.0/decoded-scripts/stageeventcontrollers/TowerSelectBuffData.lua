return {
	-- zone_name: 이벤트가 발생한 존 네임
	-- sender : 버프등 실행하는 주체
	-- selections : 상세내역
	-- type : 기능타입 buff or heal
	-- buff_id : 버프인경우 데이터 id
	-- buff_level : 해당버프 레벨
	-- btn_string : 버튼에 표시될 글자 strings 테이블 참조
	-- heal_ratio : 힐 배율 = 리더캐릭터의 maxphp 기준으로 체크
	-- is_revive : 힐시 죽은사람 살릴건지에 대한 값
	tower_light_48 = {
		{
			zone_name = 'event_buff_1',
			sender ='android_1',
			talk_start ='tower_light_elite_8_narration',
			talk_end =
			{
				'tower_light_elite_8_select_1',--'select_1stBtn',
				'tower_light_elite_8_select_2',--'select_2ndBtn',
				'tower_light_elite_8_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'buff',
					buff_id = 10000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_1'
				},
				{
					type = 'buff',
					buff_id = 20000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_2'
				},
				{
					type = 'heal',
					heal_ratio = 0.3,
					is_revive = false,
					btn_string = 'tower_light_elite_8_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_2',
			sender ='android_2',
			talk_start ='tower_light_elite_8_narration',
			talk_end =
			{
				'tower_light_elite_8_select_1',--'select_1stBtn',
				'tower_light_elite_8_select_2',--'select_2ndBtn',
				'tower_light_elite_8_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'buff',
					buff_id = 10000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_1'
				},
				{
					type = 'buff',
					buff_id = 20000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_2'
				},
				{
					type = 'heal',
					heal_ratio = 0.3,
					is_revive = false,
					btn_string = 'tower_light_elite_8_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_3',
			sender ='android_3',
			talk_start ='tower_light_elite_8_narration',
			talk_end =
			{
				'tower_light_elite_8_select_1',--'select_1stBtn',
				'tower_light_elite_8_select_2',--'select_2ndBtn',
				'tower_light_elite_8_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'buff',
					buff_id = 10000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_1'
				},
				{
					type = 'buff',
					buff_id = 20000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_2'
				},
				{
					type = 'heal',
					heal_ratio = 0.3,
					is_revive = false,
					btn_string = 'tower_light_elite_8_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_4',
			sender ='android_4',
			talk_start ='tower_light_elite_8_narration',
			talk_end =
			{
				'tower_light_elite_8_select_1',--'select_1stBtn',
				'tower_light_elite_8_select_2',--'select_2ndBtn',
				'tower_light_elite_8_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'buff',
					buff_id = 10000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_1'
				},
				{
					type = 'buff',
					buff_id = 20000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_2'
				},
				{
					type = 'heal',
					heal_ratio = 0.3,
					is_revive = false,
					btn_string = 'tower_light_elite_8_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_5',
			sender ='android_5',
			talk_start ='tower_light_elite_8_narration',
			talk_end =
			{
				'tower_light_elite_8_select_1',--'select_1stBtn',
				'tower_light_elite_8_select_2',--'select_2ndBtn',
				'tower_light_elite_8_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'buff',
					buff_id = 10000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_1'
				},
				{
					type = 'buff',
					buff_id = 20000,
					buff_level = 200,
					btn_string = 'tower_light_elite_8_option_2'
				},
				{
					type = 'heal',
					heal_ratio = 0.3,
					is_revive = false,
					btn_string = 'tower_light_elite_8_option_3'
				}
			}
		}
	}
}
