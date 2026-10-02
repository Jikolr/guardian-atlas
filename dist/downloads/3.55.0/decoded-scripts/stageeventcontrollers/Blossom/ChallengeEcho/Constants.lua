return {
	substage_blossom_2 = {
		puzzle_infos = {
			{
				reset_marker = 'echo_reset_marker',
				zone_name = 'echo_puzzle_zone',
			},
		},
		--퍼즐 난이도 조절을 위해, 아래 값을 수정하면 되겠습니다.
		--총 (max_count + 1) * cycle_duration의 시간이 지난 후 reset_marker로 이동됩니다.
		--기본 세팅으로 예시를 들면, 분신이 3개 생긴후, 4개 생길 타이밍에 rewind 연출이 진행되어 reset_marker로 이동합니다.
		--즉, 10초의 시간 유예 후 리셋마커 위치로 이동됩니다.
		echo_infos = {
			--최대로 생길 수 있는 분신.
			--갯수 만큼 다이나믹 npc가 생성되므로, 과도하게 많은 숫자는 최적화에 문제가 있을 수 있음.
			max_count = 3,

			--분신이 생성되는 주기.
			cycle_duration = 0.88,

			--분신 NPC 이름 Prefix. 굳이 건들 필요 없음.
			npc_prefix = 'echo_dynamic_'
		},

		--echo_infos.max_count와 데이터 갯수 같아야 함.
		--	따라서, 자연스러운 연출을 위해 분신을 늘린다면(echo_infos.maxcount) 아래 rewind_infos의 데이터 갯수도 늘려줘야함.
		--	max_count를 넘어서서 없는 데이터는 데이터 마지막 꺼(현재대로라면 0.4,0.6들어있는 데이터)로 간주하여 사용함.
		--	ex) 기본 데이터는 그대로 max_count = 4면, 4번째 분신은 3번째 데이터 대로 : 0.4초만에 4번째 분신으로 가고, 0.6초 대기
		--다음을 max_count 갯수 만큼 반복합니다.
		--	존에 진입하고 cycle_duration * k초 지난 후의 플레이어 파티리더의 좌표 지점으로 move_time초만에 이동한다.
		--	이후 wait_time 만큼 대기
		--	반복하여 최종으로 reset_marekr로 되돌아갑니다.
		--ex)	0.4초만에 3번쨰 분신으로 가고, 0.6초 대기,
		--		0.2초만에 2번째 분신으로 가고, 0.2초 대기,
		--		0.16초만에 1번째 분신으로 가고, 0.1초 대기.
		rewind_infos = {
			{
				move_time = 0.15,
				wait_time = 0.1,
			},
			{
				move_time = 0.2,
				wait_time = 0.2,
			},

			{
				move_time = 0.4,
				wait_time = 0.6,
			},
		},

		--기믹이 시작하는 존을 가시화 하기 위해, fx_cw_glitch_effect를 설치하는데, 그 위치입니다.
		--더 필요하시면 마커 추가 후, 해당 데이터에 마커 이름을 추가하시면 되겠습니다.
		glitch_marker_infos = {
			'echo_glitch_marker_1',
			'echo_glitch_marker_2',
			'echo_glitch_marker_3',
			'echo_glitch_marker_4',
			'echo_glitch_marker_5',
			'echo_glitch_marker_6',
		},

		--페이드 아웃 관련. 후에 다른 스테이지에서 사용하면,
		--background_fade_controller를 사용하기위해 알맞은 asset_path 와 asset_name을 맞춰줘야함.
		background_fade_infos = {
			asset_path = 'ondemand/blossom/effects',
			asset_name = 'white_tint_background'
		}

	}
}
