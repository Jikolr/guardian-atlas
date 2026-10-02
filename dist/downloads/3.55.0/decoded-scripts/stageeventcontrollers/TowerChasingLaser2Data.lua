-- Stage Name 기반으로 동작
-- tower_none_52 기반으로 설명
-- laser1 = event zone 이름(이곳에 들어가면 기믹 작동 시작)
-- LaserNames = 위 event zone에 들어갔을경우 작동할 레이저 한쌍(무조껀 두개 넣어야함)
-- Direction = 레이저가 움직일 방향(대소문자 구분해야함)
-- Distance = 레이저가 정한 방향으로 움직일 거리
-- Delay = 레이저가 초기 작동 대기 시간
-- Speed = 레이저 움직임 속도

return {
	tower_none_52 = {
		-- 여기부터 1페이즈 레이저
		-- 1구역 레이저 쌍
		laser1 =
		{
			LaserNames = { 'laser_1', 'laser_2' },
			Direction = 'Right',
			Distance = 30,
			Delay = 0,
			Speed = 1.0,
		},
		laser2 =
		{
			LaserNames = { 'laser_3', 'laser_4' },
			Direction = 'Left',
			Distance = 11,
			Delay = 0,
			Speed = 1.0,
		},
		-- 2구역 레이저 쌍
		laser3 =
		{
			LaserNames = { 'laser_5', 'laser_6' },
			Direction = 'Down',
			Distance = 30,
			Delay = 0,
			Speed = 1.4,
		},
		laser4 =
		{
			LaserNames = { 'laser_7', 'laser_8' },
			Direction = 'Up',
			Distance = 30,
			Delay = 0,
			Speed = 1.2,
		},
		-- 3구역 레이저 쌍
		laser5 =
		{
			LaserNames = { 'laser_9', 'laser_10' },
			Direction = 'Left',
			Distance = 30,
			Delay = 0,
			Speed = 1.3,
		},
		laser6 =
		{
			LaserNames = { 'laser_11', 'laser_12' },
			Direction = 'Right',
			Distance = 16,
			Delay = 0,
			Speed = 1.3,
		},
		-- 4구역 레이저 쌍
		laser7 =
		{
			LaserNames = { 'laser_13', 'laser_14' },
			Direction = 'Up',
			Distance = 30,
			Delay = 0,
			Speed = 2.0,
		},
		laser8 =
		{
			LaserNames = { 'laser_15', 'laser_16' },
			Direction = 'Down',
			Distance = 20,
			Delay = 0,
			Speed = 2.0,
		},
		-- 5구역 레이저 쌍
		laser9 =
		{
			LaserNames = { 'laser_17', 'laser_18' },
			Direction = 'Right',
			Distance = 15,
			Delay = 0,
			Speed = 2.0,
		},
		laser10 =
		{
			LaserNames = { 'laser_19', 'laser_20' },
			Direction = 'Left',
			Distance = 5,
			Delay = 0,
			Speed = 2.0,
		},
		-- 6구역 레이저 쌍
		laser11 =
		{
			LaserNames = { 'laser_21', 'laser_22' },
			Direction = 'Up',
			Distance = 20,
			Delay = 0,
			Speed = 1.5,
		},
		-- laser10과 같이 출발
		laser12 =
		{
			LaserNames = { 'laser_23', 'laser_24' },
			Direction = 'Left',
			Distance = 10,
			Delay = 0,
			Speed = 2.0,
		},
		-- 여기부터 2페이즈 레이저
		laser13 =
		{
			LaserNames = { 'laser_25', 'laser_26' },
			Direction = 'Up',
			Distance = 25,
			Delay = 0,
			Speed = 1.3,
		},
		laser14 =
		{
			LaserNames = { 'laser_27', 'laser_28' },
			Direction = 'Down',
			Distance = 5,
			Delay = 0,
			Speed = 1.6,
		},
		laser15 =
		{
			LaserNames = { 'laser_29', 'laser_30' },
			Direction = 'Down',
			Distance = 30,
			Delay = 0,
			Speed = 2.3,
		},
		laser16 =
		{
			LaserNames = { 'laser_31', 'laser_32' },
			Direction = 'Up',
			Distance = 15,
			Delay = 0,
			Speed = 2.3,
		},
		laser17 =
		{
			LaserNames = { 'laser_33', 'laser_34' },
			Direction = 'Down',
			Distance = 19,
			Delay = 0,
			Speed = 1.3,
		},
		-- 벽 대신 사용되는 레이저
		laser18 =
		{
			LaserNames = { 'laser_35', 'laser_36' },
			Direction = 'Left',
			Distance = 5,
			Delay = 0,
			Speed = 7.7,
		},
		laser19 =
		{
			LaserNames = { 'laser_37', 'laser_38' },
			Direction = 'Right',
			Distance = 5,
			Delay = 0,
			Speed = 7.7,
		},
		laser20 =
		{
			LaserNames = { 'laser_39', 'laser_40' },
			Direction = 'Up',
			Distance = 5,
			Delay = 0,
			Speed = 7.7,
		}
	},
	herotower_wrestler_3 = {
		-- 여기부터 1페이즈 레이저
		-- 1구역 레이저 쌍
		battle1_laserzone_1 =
		{
			LaserNames = { 'battle1_laser_1', 'battle1_laser_2' },
			Direction = 'Right',
			Distance = 42,
			Delay = 0.5,
			Speed = 1.3,
		},
		battle1_laserzone_2 =
		{
			LaserNames = { 'battle1_laser_3', 'battle1_laser_4' },
			Direction = 'Left',
			Distance = 34,
			Delay = 0.75,
			Speed = 0.7,
		},
		battle1_laserzone_3 =
		{
			LaserNames = { 'battle1_laser_5', 'battle1_laser_6' },
			Direction = 'Right',
			Distance = 34,
			Delay = 0.75,
			Speed = 1,
		},
		battle3_laserzone_1 =
		{
			LaserNames = { 'battle3_laser_1', 'battle3_laser_2' },
			Direction = 'Up',
			Distance = 41,
			Delay = 1.3,
			Speed = 0.3,
		}
	}		
}
