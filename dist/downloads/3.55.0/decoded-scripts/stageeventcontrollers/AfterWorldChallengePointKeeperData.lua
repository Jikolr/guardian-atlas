return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- start_point : 갖고 시작할 HP 대신 사용할 포인트
	-- max_point : 포인트 최대치
	-- earn_table : 대상 처치시 얻을  = {
	-- 		{
	-- 			header : 대상 몬스터 핸들 네임에 포함되는 머릿말
	-- 			value : 처지시 포인트 변화량
	-- 		}
	-- }
	-- hit_monster : 피격시 포인트 변화량
	-- hit_gimmick : Trap 유형 피해를 받을 경우 포인트 변화량
	-- start_battle_zone : 컨트롤러가 동작을 시작하는 배틀 존 명칭
	-- end_battle_zone : 클리어 판정이 될 배틀 그룹 명칭
	-- narration : 스테이지 입장시 출력할 나레이션 스트링 키 (없거나 ''면 연출 안함)
	]]--

	substage_afterworld_2 = {
		start_point = 300,
		max_point = 300,
		earn_table = {
			{
				header = 'battle1',
				value = 10
			},
			{
				header = 'battle2',
				value = 10
			},
			{
				header = 'battle3',
				value = 10
			},
			{
				header = 'battle4',
				value = 10
			},
			{
				header = 'battle5',
				value = 10
			},
		},
		hit_monster = -10,
		hit_gimmick = -70,
		start_battle_zone = 'battle1',
		end_battle_group = 'battle5',
		narration = 'aw_challange_pointkeeper_1'
	}
}
