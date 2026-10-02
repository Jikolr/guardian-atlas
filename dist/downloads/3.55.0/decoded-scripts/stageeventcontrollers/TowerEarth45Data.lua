
-- 스테이지별 레이저 기믹의 정보를 담고 있는 구조체
-- Key : 스테이지 이름
-- speed : 레이저 기믹이 이동하는 속도 (높을수록 빨라짐)
-- damage : 레이저 데미지 천체 체력기준으로 몇 % 인지 1 = 100%
-- damage_type : 레이저 기믹 데미지 타입 Melee, Projectile, Trap 세가지중 하나
-- revive_time : 레이저 파괴된 후 재생성 되는 시간
-- immune_time : 면역 버프 지속시간
-- gimmick_count : 해당 스테이지에 레이저 기믹의 갯수 gimmick_start_zone_names 와 battle_end_group_names는
-- 해당 count와 같은 숫자의 배열을 가지고 있어야 한다.
-- gimmick_start_zone_names : 레이저 기믹이 시작하는 존의 이름
-- battle_end_group_names : 이 이름의 배틀그룹의 BattleGroupEliminatedEvent를 받으면 레이저가 사라진다.
-- activation_duration: 버프가 유지될 시간
-- initial_waiting_duration: 버프가 처음 붙을때 기다리는 시간
-- waiting_duration: 그 뒤, 버프를 재생성하기까지 기다리는 시간

return {
	tower_earth_45 = {
		phase_info = {
			{
				speed = 1,
				damage = 1.5,
				revive_time = 2.5,
				patten = 'horizontal'
			},
		},
		horizon_damage_type = "Melee",
		vertical_damage_type = "Projectile",
		horizon_effect_type = 'purple',
		buff_activation_duration = 3,
		buff_initial_waiting_duration = 0,
		buff_waiting_duration = 0,

		gimmick_count = 1,
		gimmick_start_zone_names = { 'boss' },
		battle_end_group_names = { 'boss' }
	},
	tower_140 = {
		phase_info = {
			{
				speed = 1,
				damage = 3.5,
				revive_time = 2.5,
				patten = 'horizontal'
			},
			{
				speed = 1,
				damage = 3.5,
				revive_time = 2,
				patten = 'vertical'
			},
			{
				speed = 1,
				damage = 3.5,
				revive_time = 1.5,
				patten = 'cross'
			}
		},
		horizon_damage_type = "Melee",
		vertical_damage_type = "Projectile",
		horizon_effect_type = 'blue',
		vertical_effect_type = 'yellow',
		phase_hp_rate = { 70, 40 },
		buff_activation_duration = 1.75,
		buff_initial_waiting_duration = 0,
		buff_waiting_duration = 0,

		boss_name = 'boss',
		gimmick_count = 1,
		gimmick_start_zone_names = { 'boss' },
		battle_end_group_names = { 'boss' }
	}
}
