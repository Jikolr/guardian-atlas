-- 예시 파일로 남겨둠
return {
	pixyworld_1 = {
		pools = {
			invader_warrior = {
				prefix = 'invader_warrior_',
				count = 5,
			}
		},
		groups = {
			invader_1 = {
				condition = {
					type = 'quest',
					quest_id = 413,
					progress_infos = {
						{
							from = -1,
							to = -1,
						},
						{
							from = 2,
							to = 3,
						},
					}
				},
				members = {
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(-2, 0, 0)
						},
						direction = 'left',
						anim = {
							name = 'release',
							upper = true,
						}
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(-1, 0, 0)
						},
						direction = 'up',
						talk = 'test_1',
					},
					{
						key = 'invader_warrior',
						position = 'grand_march_pre_flower_1',
						direction = 'down',
						talk = {
							key = 'test_1',
							sfx = '01_swing_01',
						}
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(1, 0, 0)
						},
						direction = 'up',
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(2, 0, 0)
						},
						direction = 'right',
						emotion = 'scared',
					},
				},
			},
			invader_2 = {
				condition = {
					type = 'quest',
					quest_id = 413,
					progress_infos = {
						{
							from = 0,
							to = 1,
						},
						{
							from = 4,
							to = 'clear',
						}
					}
				},
				members = {
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(-2, 0, 1)
						},
						direction = 'right',
						talk = 'test_2',
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(-1, 0, 1)
						},
						direction = 'down',
						talk = 'test_2',
					},
					{
						key = 'invader_warrior',
						position = 'grand_march_pre_flower_1',
						direction = 'up',
						talk = 'test_2',
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(1, 0, 1)
						},
						direction = 'down',
						talk = 'test_2',
					},
					{
						key = 'invader_warrior',
						position = {
							pivot = 'grand_march_pre_flower_1',
							offset = vector(2, 0, 1)
						},
						direction = 'left',
						talk = 'test_2',
					},
				},
			},
		}
	}
}
