--[[
	스테이지명 = {
	}
]]
return {
	battle_test_5 = { --스테이지 이름
		box_name = "nano_box_", --tile_map에 배치된 박스 기믹 이름
		zone_name = "battle3",  --보스전 배틀존 이름
		box_max_count = 2,      --2 고정
		wall_offset = 2,        --기믹소환이 벽에서 얼마나 떨어질 것인지
		regen_range = 3,        --기믹소환이 메뉴얼 캐릭터에서 얼마나 떨어질 것인지
		boss_range = 2,         --기믹소환이 보스몬스터에서 얼마나 떨어질 것인지
		box_range = 2,          --기믹소환이 다른박스와 얼마나 떨어질 것인지
		regen_duration = 3,    --기믹 리젠 시간
		box_duration = 4,      --기믹 유지 시간
		heal_ratio = 0.3,       --기믹 작동 시 힐%량
		drone_regen_height = 10, --드론 시작 높이
		drone_box_height = 0.5, --박스 놓을 때 드론 높이
		drone_move_duration = 1.5, --드론 이동시간
		drone_move_interval_duration = 1, --드론 박스 소환 후 대기 시간
		fx_remove_duration = 1, --획득, 파괴이팩트 유지시간
		max_regen_count = 8 --박스소환 카운트
	},
	civilwar_6 = { --스테이지 이름
		box_name = 'boss_battle_nano_box_', --tile_map에 배치된 박스 기믹 이름
		zone_name = 'boss_battle',  --보스전 배틀존 이름
		box_max_count = 2,      --2 최대 박스 갯수
		wall_offset = 2,        --기믹소환이 벽에서 얼마나 떨어질 것인지
		regen_range = 3,        --기믹소환이 메뉴얼 캐릭터에서 얼마나 떨어질 것인지
		boss_range = 4,         --기믹소환이 보스몬스터에서 얼마나 떨어질 것인지
		box_range = 4,          --기믹소환이 다른박스와 얼마나 떨어질 것인지
		regen_duration = 30,    --기믹 리젠 시간
		box_duration = 45,      --기믹 유지 시간
		heal_ratio = 0.5,       --기믹 작동 시 힐%량
		drone_regen_height = 10, --드론 시작 높이
		drone_box_height = 0.5, --박스 놓을 때 드론 높이
		drone_move_duration = 1.5, --드론 이동시간
		drone_move_interval_duration = 1, --드론 박스 소환 후 대기 시간
		fx_remove_duration = 1, --획득, 파괴이팩트 유지시간
		max_regen_count = 8 --박스소환 카운트
	},
}
