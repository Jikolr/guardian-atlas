return {
	-- 스테이지별 정보를 담고 있는 구조체
	--[[
	-- sniper_name : 스나이퍼 캐릭터 명칭
	-- snipe_duration : 저격 시간
	-- snipe_cam_shake_time : 저격 상태중 카메라가 흔들리기 시작할 시간
	-- escape_speed : 도망칠때 속도
	-- snipe_infos : 저격에 사용되는 정보들
	-- {
	-- reset_marker : 플레이어 리셋 지점
	-- snipe_marker : 저격 지점 마커
	-- snipe_zone : 저격이 진행될 존
	-- death_zone : 즉시 사격할 존
	-- escape_zone : 저격수가 다음 위치로 도망가기 시작할 존
	-- way_points : 도주 경로 (배열형식, 설정되지 않은경우 다음 info의 snipe_marker가 기본 웨이포인트로써 사용)
	-- rotate_sniper : 저격 중 저격수가 대상을 향해 회전할지 여부
	-- }
	]] --
	tower_ice_48 = {
		sniper_name = 'sniper',
		snipe_duration = 5,
		snipe_cam_shake_time = 1,
		escape_speed = 7,
		snipe_infos = {
			{
				snipe_marker = 'sniper_1',
				snipe_zone = 'sniper1',
				death_zone = 'death1',
				escape_zone = 'safe1',
				way_points = {'waypoint1'},
				rotate_sniper = true
			},
			{
				snipe_marker = 'sniper_2',
				snipe_zone = 'sniper2',
				death_zone = 'death2',
				escape_zone = 'safe2',
				way_points = {'waypoint2'},
				rotate_sniper = true
			},
			{
				snipe_marker = 'sniper_3',
				snipe_zone = 'sniper3',
				death_zone = 'death3',
				escape_zone = 'safe3',
				way_points = {'waypoint3'},
				rotate_sniper = true
			},
			{
				snipe_marker = 'sniper_4',
				snipe_zone = 'sniper4',
				death_zone = 'death4',
				escape_zone = 'safe4',
				way_points = {'waypoint4'},
				rotate_sniper = true
			}
		}
	},
	tower_none_54 = {
		sniper_name = 'sniper',
		snipe_duration = 5,
		snipe_cam_shake_time = 2.5,
		escape_speed = 7,
		snipe_infos = {
			{
				snipe_marker = 'sniper_1',
				snipe_zone = 'sniper1',
				death_zone = 'death1',
				escape_zone = 'safe1',
				way_points = {'waypoint1'},
				rotate_sniper = true
			}
		}
	}
}
