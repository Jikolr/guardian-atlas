--BoxRegenDuration : 박스 획득 시 다시 젠 되는데 걸리는 시간
--DisableLaserDuration : 레이저 비활성화 시 다시 재작동하는데 걸리는 시간
--BuffIdList : 박스 획득시 걸릴 버프들(힐, 쉴드 제외)
--BuffLevelList : 위 버프들의 버프레벨
--HealHpRatio : 박스 획득시 치료될 Hp 대비 양

--BoxName : 타일맵에 배치된 박스들의 이름
--LaserName : 타일맵에 배치된 레이저박스들의 이름

--GuideMarkerZone : Zone 입장 & 전투 시작 시 퀘스트 가이드를 표시할 박스들의 이름
--SwitchGimmick : 스위치 작동시(on만) 비활성화 시킬 레이저 목록
return {
	tower_fire_54 = {
		BoxRegenDuration = 10,
		DisableLaserDuration = 5,

		-- BuffIdList와 BuffLevelList의 수량은 동일해야 합니다. , << 반점 주의
		BuffIdList = { 10001, 20001, 10901 },
		BuffLevelList = { 250, 1, 300 },
		HealHpRatio = 0.2,

		BoxName = { 'box_1', 'box_2', 'box_3', 'box_4', 'box_5', 'box_6', 'box_7'},
		LaserName = { 'b1_laser_1', 'b1_laser_2', 'b1_laser_3', 'b1_laser_4', 'b2_laser_1', 'b2_laser_2', 'b2_laser_3', 'b2_laser_4'},

		GuideMarkerZone = {
			battle1 = {
				'box_1', 'box_2', 'box_5', 'box_7'
			},
			battle2 = {
				'box_3', 'box_4'
			}
		},

		SwitchGimmick =
		{
			switch_1 = { 'b1_laser_1', 'b1_laser_2' },
			switch_2 = { 'b1_laser_3', 'b1_laser_4' },
			switch_3 = { 'b2_laser_1', 'b2_laser_2' },
			switch_4 = { 'b2_laser_3', 'b2_laser_4' },
		},

		NarrationKey = 'tower_fire_54_narration_key'
	},
	herotower_mermaid_spy_5 = {
		BoxRegenDuration = 10,
		DisableLaserDuration = 5,

		-- BuffIdList와 BuffLevelList의 수량은 동일해야 합니다. , << 반점 주의
		BuffIdList = { 10001, 20001, 10901 },
		BuffLevelList = { 50, 25, 500 },
		HealHpRatio = 0.075,

		BoxName = { 'box_1', 'box_2', 'box_3', 'box_4', 'box_5'},
		LaserName = { 'b1_laser_1'},

		GuideMarkerZone = {
			battle1 = {
				'box_1', 'box_2'
			},
			battle2 = {
				'box_3', 'box_4', 'box_5'
			}
		},

		SwitchGimmick =
		{
			switch_1 = { 'b1_laser_1', 'b1_laser_2' }
		},

		NarrationKey = 'tower_fire_54_narration_key'
	},
	herotower_saintess_5 = {
		BoxRegenDuration = 20,
		DisableLaserDuration = 5,

		-- BuffIdList와 BuffLevelList의 수량은 동일해야 합니다. , << 반점 주의
		BuffIdList = { 10004 },
		BuffLevelList = { 10 },
		HealHpRatio = 0.075,

		BoxName = { 'box_1', 'box_2', 'box_3', 'box_4', 'box_5', 'box_6', 'box_7', 'box_8'},
		LaserName = { 'b1_laser_1'},

		GuideMarkerZone = {
			battle1 = {
				'box_1', 'box_2','box_3', 'box_4'
			},
			battle2 = {
				'box_5', 'box_6','box_7', 'box_8'
			}
		},

		SwitchGimmick =
		{
			switch_1 = { 'b1_laser_1', 'b1_laser_2' }
		},

		NarrationKey = 'tower_fire_54_narration_key'
	}
}
