return {
	--[[
		데이터 셋 구조

		스테이지_이름 = {
			start_zone_name : 해당 존에 입장 했을때 safe_zone 움직이기 시작함
			end_zone_name : 해당 존 탈출 했을때 컨트롤러 동작 종료
			safe_zone_rally_markers : 맵상 marker 의 네임 리스트, 위에서 부터 safe_zone 이 쫒아가게 되는 웨이포인트로 쓰임
			safe_zone_change_markers : 맵상 marker 의 리스트, 해당 마커에 가까워 졌을때 safe_zone 의 사이즈 변경이 일어남
			{
				name : 사이즈 변경용 마커 이름
				duration : 사이즈 변경되는 시간
				radius : 변경될 사이즈
			}
			speed : safe_zone 움직이는 속도
			radius : safe_zone 기본 반지름
			count_down : safe_zone 벗어난경우 사망까지 카운트되는 시간 (정수)
		}
	]]
	tower_ice_43 = {
		start_zone_name = 'battle1',
		end_zone_name = 'battle6',
		narration_info = 'tower_ice_elite_5_narration',
		safe_zone_rally_markers = {
			'safezone_point_1',
			'safezone_point_2',
			'safezone_point_3',
			'safezone_point_4',
			'safezone_point_5',
			'safezone_point_6',
			'safezone_point_7',
			'safezone_point_8',
			'safezone_point_9',
			'safezone_point_10',
			'safezone_point_11',
			'safezone_point_12'
		},
		safe_zone_change_markers = {
			{
				name = 'resize_1',
				duration = 0.5,
				radius = 3.5
			},
			{
				name = 'resize_2',
				duration = 0.5,
				radius = 3
			},
			{
				name = 'resize_3',
				duration = 0.5,
				radius = 2.5
			},
			{
				name = 'resize_4',
				duration = 0.5,
				radius = 2
			},
		},
		speed = 0.9,
		radius = 4,
		count_down = 5
	},
	herotower_adela_noble_2 = {
		start_zone_name = 'battle2',
		end_zone_name = 'battle2',
		narration_info = 'tower_ice_elite_5_narration',
		safe_zone_rally_markers = {
			'safezone_point_1',
			'safezone_point_2',
			'safezone_point_3',
			'safezone_point_4',
			'safezone_point_3',
			'safezone_point_2',
			'safezone_point_1'
		},
		safe_zone_change_markers = {
		},
		speed = 0.5,
		radius = 2.5,
		count_down = 15
	}
}
