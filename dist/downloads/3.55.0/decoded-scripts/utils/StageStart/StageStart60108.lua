return {
  -- marker_key = 마커 키
  -- direction = 출력 방향, 있으면 마커 방향보더 우선 함
  -- position = 출력 포지션, 마커 없이 따로 포지션 지정할때 사용
  -- directional_stage_entry = 스테이지 시작 연출을 실행할 것인지 여부
  -- play_stage_music = field BGM을 재생할 것인지 여부
  -- directional_stage_entry, play_stage_music 수치는 없으면 기본 true
  bridgestory_seira = {
    -- 기본위치
    default_start = { marker_key = 's1_start_pos', direction = 'right' },

    --default_start = { position = {
    --    pivot = 'template_marker_1',
    --    offset = vector(0, 0, 0),
    --}, direction = 'right' },

    -- InnerProgress로 넣어야함 0부터 시작
    start_data_list = {
      [0] = { marker_key = 's1_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [1] = nil,
      [2] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [3] = { marker_key = 's4_start_pos', direction = 'up', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [4] = { marker_key = 's5_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
    },
  },
  bridgestory_seira_pepper = {
    -- 기본위치
    default_start = { marker_key = 's1_start_pos', direction = 'left' },

    --default_start = { position = {
    --    pivot = 'template_marker_1',
    --    offset = vector(0, 0, 0),
    --}, direction = 'right' },

    -- InnerProgress로 넣어야함 0부터 시작
    start_data_list = {
      [0] = nil,
      [1] = nil,
      [2] = nil,
      [3] = nil,
      [4] = nil,
      [5] = nil
    },
  },
  bridgestory_seira_v_driver = {
    -- 기본위치
    default_start = { marker_key = 's1_start_pos', direction = 'right', directional_stage_entry = false },

    --default_start = { position = {
    --    pivot = 'template_marker_1',
    --    offset = vector(0, 0, 0),
    --}, direction = 'right' },

    -- InnerProgress로 넣어야함 0부터 시작
    start_data_list = {
      [0] = { marker_key = 's1_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [1] = { marker_key = 's1_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [2] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [3] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [4] = nil,
      [5] = nil
    },
  },
  bridgestory_seira_epilogue = {
    -- 기본위치
    default_start = { marker_key = 's1_start_pos', direction = 'right' },

    --default_start = { position = {
    --    pivot = 'template_marker_1',
    --    offset = vector(0, 0, 0),
    --}, direction = 'right' },

    -- InnerProgress로 넣어야함 0부터 시작
    start_data_list = {
      [0] = nil,
      [1] = nil,
      [2] = { marker_key = 's3_start_pos', direction = 'right', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [3] = { marker_key = 's3_start_pos', direction = 'down', position = nil,
              directional_stage_entry = false, play_stage_music = false },
      [4] = { marker_key = 's4_start_pos', direction = 'down', position = nil,
              directional_stage_entry = false, play_stage_music = false }
    },
  },
}
