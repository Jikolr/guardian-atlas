--[[
	TowerDamageOnTimeController 데이터 정의
	스테이지 이름 = {
		zone_name = 기믹 시작될 존 이름
		end_battle_group_name = 해당 이름을 배틀 그룹으로 가지는 전투가 끝난후 기믹 종료됨
		boss_name = hp 줄어드는 대상 보스이름
		box_marker_names = { 박스 생성될 위치의 마커이름. boss_hp_percent 와 함께 사용되여
		boss_hp_percent 가 0.95 일때 box_1 마커 위치에, 0.8 일때 box_4 마커 위치에 상자 스폰됨. 값 중복 가능함.
		박스 다중 배치 허용하기 위해 리스트로 변경됨. 5개 까지 중복 소환 가능
		{'box_1', 'box_2'},
		{'box_3'},
		 {'box_4'}
		},
		boss_hp_percent = { 보스 hp 가 몇 퍼센트로 줄어들었을때 상자 생성되는지에 대한 값. 중복 불가 1 일때 maxhp 상태
		0.95, 0.9, 0.85, 0.8
		},
		box_interact_time = 박스 상호작용 하는데 걸리는 시간
		box_heal_ratio = 힐 하는데 드는 비율값 MaxHP * box_heal_ratio 으로 적용됨. 1 일때 완전회복.
		damage_ratio = dot 데미지 비율값 MaxHp * damage_ratio 으로 적용됨. 1 보다 크면 즉사가능
		damage_term = 어느시간마다 데미지 들어가는지 second 값.
	}
	**PS. 박스 오브젝트는 item_box_0 를 이름으로 타일맵 상에 하나 넣어주시면 됩니다.
]]
return {
	tower_none_45 = {
		zone_name = 'boss',
		end_battle_group_name = 'boss',
		boss_name = 'boss',
		box_marker_names =
		{
			{ 'box_1', 'box_2', 'box_3', 'box_4' },
			{ 'box_1', 'box_2', 'box_3' },
			{ 'box_2', 'box_4' },
			{ 'box_3' }
		},
		boss_hp_percent =
		{
			0.9,
			0.6,
			0.4,
			0.2
		},
		box_interact_time = 0.5,
		box_heal_scale = 0.3,
		damage_scale = 0.03,
		damage_term = 0.8
	},
	tower_125 = {
		zone_name = 'boss',
		end_battle_group_name = 'boss',
		boss_name = 'boss',
		box_marker_names =
		{
			{ 'box_1' },
			{ 'box_2' },
			{ 'box_3' },
			{ 'box_4' },
			{ 'box_1' }
		},
		boss_hp_percent =
		{
			0.85,
			0.7,
			0.55,
			0.35,
			0.15
		},
		box_interact_time = 0.5,
		box_heal_scale = 0.3,
		damage_scale = 0.03,
		damage_term = 0.85
	}
}
