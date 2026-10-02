
-- 스테이지별 레이저 기믹의 정보를 담고 있는 구조체
-- Key : 스테이지 이름
-- speed : 레이저 기믹이 이동하는 속도 (높을수록 빨라짐)
-- wait_for_active : 레이저 기믹 활성화 대기 시간
-- direction : 레이저 기믹의 이동방향
-- gimmick_count : 해당 스테이지에 레이저 기믹의 갯수 gimmick_start_zone_names 와 battle_end_group_names는
-- 해당 count와 같은 숫자의 배열을 가지고 있어야 한다.
-- gimmick_start_zone_names : 레이저 기믹이 시작하는 존의 이름
-- battle_end_group_names : 이 이름의 배틀그룹의 BattleGroupEliminatedEvent를 받으면 레이저가 사라진다.

return {
	tower_fire_43 = {
		speed = 0.33,
		wait_for_active = 7,
		direction = 'Right',
		gimmick_count = 1,
		gimmick_start_zone_names = { 'battle1' }
	}
}
