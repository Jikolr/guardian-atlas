return {
	--[[
		@ boss_names : 맞았을 때 스텍이 중척 될 몬스터의 이름(중복 설정 가능)
		@ buff_id : 버프의 스펙 Id
		@ buff_level : 버프 레벨
		@ max_count : 스텍의 최대 수치(최대 수치 도달 시 즉사)
	]]
	tower_light_45 = {

			boss_names = {
				'boss1'
			},
			buff_id = 10000,
			--최종 버프레벨은 현재스텍 * buff_level
			buff_level = 500,
			max_count = 10,
			description = 'tower_light_boss_5_narration'

	},
	tower_130 = {

		boss_names = {
			'boss_1',
			'boss_2'
		},
		buff_id = 10000,
		--최종 버프레벨은 현재스텍 * buff_level
		buff_level = 500,
		max_count = 15,
		description = 'tower_130_narration'

}
}
