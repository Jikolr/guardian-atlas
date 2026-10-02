return {
	--[[
		@ brazier_names: 기믹으로 작동하는 화로
		@ brazier_distance: 화로 적용 거리
		@ brazier_effect_offset: 화로 마스크 오프셋
		@ brazier_effect_scale: 화로 마스크 스케일
		@ debuff_data: 화로 범위 안에 없을때 걸릴 디버프 정보 (id / 레벨 순서쌍 리스트)
		@ event_key: 화로 토글 이벤트 키 (레버 TileProp 등에서 지정)
	]]
	tower_light_43 = {
		brazier_names = {
			'debuff_gimick_brazier_1',
			'debuff_gimick_brazier_2',
			'debuff_gimick_brazier_3',
			'debuff_gimick_brazier_4',
			'debuff_gimick_brazier_5',
			'debuff_gimick_brazier_6'
		},

		brazier_distance = 3.5,
		brazier_effect_offset = {0, 2.2, -1.5}, -- 불 위치와 맞게
		brazier_effect_scale = {1, 1, 1}, -- 3.5 기준
		debuff_data = {
			 {20000, -10000},
			 {10000, -10000}
		},

		monster_buff_data = {
			{20001, 150}
		},

		event_key = 'brazier_toggle',
		background_color = {0, 0, 0, 126/255}
	},
	tower_darkness_43 = {
		brazier_names = {
			'debuff_gimick_brazier_1',
			'debuff_gimick_brazier_2',
			'debuff_gimick_brazier_3',
			'debuff_gimick_brazier_4',
			'debuff_gimick_brazier_5',
			'debuff_gimick_brazier_6',
			'debuff_gimick_brazier_7',
			'debuff_gimick_brazier_8'
		},

		brazier_distance = 3.5,
		brazier_effect_offset = {0, 2.2, -1.5}, -- 불 위치와 맞게
		brazier_effect_scale = {1, 1, 1}, -- 3.5 기준
		debuff_data = {
			 },

		monster_buff_data = {
			{10001, 100},
			{20001, 500}
		},

		event_key = 'brazier_toggle',
		background_color = {0, 0, 0, 126/255}
	}
}
