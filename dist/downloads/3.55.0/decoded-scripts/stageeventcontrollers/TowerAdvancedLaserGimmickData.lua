--[[ 스테이지 데이터 정보
스테이지 이름 = {
-- 각 스테이지당 다수의 zone 을 설정할수 있다.
	{
		zone_name : 존 이름
		boss_name : 보스 이름
		respawn_delay : 레이저 파괴 후 재 생성되기까지의 딜레이 및 다음 레이버 시작 범위 보여주는 시간
		damage_type : 레이저가 주는 데미지 타입 Death 일경우 방어무시 + 각종 옵션 무시 데미지를 줌 Melee, Projectile, Death 가능
		phase = { : 조건에 의해 변화하는 페이즈 정보
			{
				remain_hp_percent : boss_name 인 보스의 남은 HP 비율. 해당 비율 아래일때 해당 페이즈 진행중
				gimmick_count : 해당페이즈에서 쓰이는 레이저 기믹 수 1 or 2
				change_directing_time : 레이저 방향이 바뀌는 시간. 해당 시간마다 방향이 전환됨. 0 이면 계속 같은 방향으로 진행.
				damage : 레이저가 주는 데미지 배율
			},
			{
				두번째 페이즈 정보
			},
			{
				세번째 페이즈 정보
			},
			{
				마지막 페이즈 정보
			}
		}
	}
]]
return {
	tower_ice_45 = {
		{
			zone_name = 'boss',
			boss_name = 'boss',
			respawn_delay = 1,
			damage_type = 'Death',
			phase = {
				{
					remain_hp_percent = 100,
					gimmick_count = 1,
					speed = 0.1,
					change_directing_time = 0,
					damage = 0.51,
				},
				{
					remain_hp_percent = 75,
					gimmick_count = 2,
					speed = 0.1,
					change_directing_time = 0,
					damage = 0.51,
				},
				{
					remain_hp_percent = 50,
					gimmick_count = 1,
					speed = 0.2,
					change_directing_time = 10,
					damage = 0.51,
				},
				{
					remain_hp_percent = 25,
					gimmick_count = 2,
					speed = 0.15,
					change_directing_time = 10,
					damage = 0.51,
				}
			}
		}
	}
}
