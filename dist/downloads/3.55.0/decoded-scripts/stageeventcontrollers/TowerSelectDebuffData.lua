return {
	-- zone_name: 이벤트가 발생한 존 네임
	-- sender : 버프등 실행하는 주체
	-- selections : 상세내역
	-- type : 기능타입 debuff or time
	-- debuff_id : 버프인경우 데이터 id
	-- debuff_level : 해당버프 레벨
	-- btn_string : 버튼에 표시될 글자 strings 테이블 참조
	-- time_sec : 감소될 시간 초
	-- talk_time_over : 대기중 시간 초과로 인한 이벤트 발생시의 대사
	tower_earth_48 = {
		{
			zone_name = 'event_buff_1',
			sender ='android_1',
			talk_start ='tower_earth_elite_6_narration',
			talk_time_over ='tower_earth_elite_6_narration',
			talk_end =
			{
				'tower_earth_elite_6_select_1',--'select_1stBtn',
				'tower_earth_elite_6_select_2',--'select_2ndBtn',
				'tower_earth_elite_6_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'debuff',
					debuff_id = 10000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_1'
				},
				{
					type = 'debuff',
					debuff_id = 20000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_2'
				},
				{
					type = 'time',
					time_sec = 30,
					btn_string = 'tower_earth_elite_6_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_2',
			sender ='android_2',
			talk_start ='tower_earth_elite_6_narration',
			talk_time_over ='tower_earth_elite_6_narration',
			talk_end =
			{
				'tower_earth_elite_6_select_1',--'select_1stBtn',
				'tower_earth_elite_6_select_2',--'select_2ndBtn',
				'tower_earth_elite_6_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'debuff',
					debuff_id = 10000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_1'
				},
				{
					type = 'debuff',
					debuff_id = 20000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_2'
				},
				{
					type = 'time',
					time_sec = 30,
					btn_string = 'tower_earth_elite_6_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_3',
			sender ='android_3',
			talk_start ='tower_earth_elite_6_narration',
			talk_time_over ='tower_earth_elite_6_narration',
			talk_end =
			{
				'tower_earth_elite_6_select_1',--'select_1stBtn',
				'tower_earth_elite_6_select_2',--'select_2ndBtn',
				'tower_earth_elite_6_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'debuff',
					debuff_id = 10000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_1'
				},
				{
					type = 'debuff',
					debuff_id = 20000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_2'
				},
				{
					type = 'time',
					time_sec = 30,
					btn_string = 'tower_earth_elite_6_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_4',
			sender ='android_4',
			talk_start ='tower_earth_elite_6_narration',
			talk_time_over ='tower_earth_elite_6_narration',
			talk_end =
			{
				'tower_earth_elite_6_select_1',--'select_1stBtn',
				'tower_earth_elite_6_select_2',--'select_2ndBtn',
				'tower_earth_elite_6_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'debuff',
					debuff_id = 10000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_1'
				},
				{
					type = 'debuff',
					debuff_id = 20000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_2'
				},
				{
					type = 'time',
					time_sec = 30,
					btn_string = 'tower_earth_elite_6_option_3'
				}
			}
		},
		{
			zone_name = 'event_buff_5',
			sender ='android_5',
			talk_start ='tower_earth_elite_6_narration',
			talk_time_over ='tower_earth_elite_6_narration',
			talk_end =
			{
				'tower_earth_elite_6_select_1',--'select_1stBtn',
				'tower_earth_elite_6_select_2',--'select_2ndBtn',
				'tower_earth_elite_6_select_3'--'select_3rdBtn'
			},
			selections =
			{
				{
					type = 'debuff',
					debuff_id = 10000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_1'
				},
				{
					type = 'debuff',
					debuff_id = 20000,
					debuff_level = -100,
					btn_string = 'tower_earth_elite_6_option_2'
				},
				{
					type = 'time',
					time_sec = 30,
					btn_string = 'tower_earth_elite_6_option_3'
				}
			}
		}
	}
}
