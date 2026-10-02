return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	patterns : 대상들이 animal_trap에 피격 시 열릴 문 등에 대한 정보 = {
		{
			condition_targets : 대상되는 fo 명칭 목록
			target_doors : 열릴 door 핸들네임 목록
			camera_marker : 카메라가 이동할 위치를 들고있는 마커
			camera_move_duration : 카메라가 편도로 이동할 떄 걸리는 시간 (기본값 : 1)
			door_open_duration : 문이 열리는데 걸리는 시간 (기본값 : 2)
		}
	}
	--]]
	hell_forest_2 = {
		patterns = {
			{
				condition_targets = { 'goblin_thief' },
				target_doors = { '05_door' },
				camera_marker = '05_door_camera',
				camera_move_duration = 0.5
			},
			{
				condition_targets = { '10_goblin_elite' },
				target_doors = { '10_door' },
				camera_marker = '10_door_camera',
				camera_move_duration = 0.5
			}
		}
	}
}
