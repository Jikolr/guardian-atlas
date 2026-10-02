return {
	--[[
		@ gargoyle_names : 기믹으로 파괴될 가고일 석상 핸들러
		@ debuff_data : 가고일 석상으로 인해 캐릭터가 걸릴 디/버프
		@ gagoyle_effect : 가고일 석상이 소멸할때 생성할 이펙트
		@ description : 스테이지 시작 이후 보여줄 기믹 설명 문자열 키
	]]

	tower_darkness_45 = {
		gagoyle_names = {
			'gagoyle_1',
			'gagoyle_2',
			'gagoyle_3',
			'gagoyle_4'
		},
		debuff_data = {
			{10000, -300}
		},
		gagoyle_sfx = '03_rock_break_01',
		gagoyle_effect = 'FX_Cin_Obj_RockExplosion',
		description = 'tower_darkness_boss_5_narration'
	}
}
