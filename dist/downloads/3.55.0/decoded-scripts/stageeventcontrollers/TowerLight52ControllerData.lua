return {
	--[[
		데이터 셋 구조

		스테이지_이름 = {
		    description = 스테이지 시작 시 설명
			target_ifo_name = 부수는 대상이 포함하고 있는 이름
			additional_time = 대상을 부셨을 시 제공하는 시간 (초)
			break_delay = 연속적으로 부셨을 때, 타이머에 적용되는 중간 딜레이
		}
	]]
	tower_light_52 = {
		description = 'tower_light_elite_9_narration',
		target_ifo_name = 'breakable',
		additional_time = 3,
		break_delay = 0.1
	},
	tower_darkness_60 = {
		description = 'tower_light_elite_9_narration',
		target_ifo_name = 'breakable',
		additional_time = 3,
		break_delay = 0.1
	}
}
