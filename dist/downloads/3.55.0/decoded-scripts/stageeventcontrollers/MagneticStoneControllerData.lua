--magnetic_stone_default에 스테이지명을 만들어서 아래 더 추가하면 해당스테이지 전용으로 작동한다.

return {
    magnetic_stone_default = {

        center_pos_offset1 = { 0, 0, -1 },  --배틀존 기준 자성바위중심부의 1페이즈용 오프셋
        center_pos_offset2 = { 0, 0, 0 }, --배틀존 기준 자성바위중심부의 2페이즈용 오프셋

        magnet_offset = 1.36,
        stone_angle = 22.5,         --자성바위 N각형 배치시 회전오프셋

        max_stone_count = 8, -- 필드에 유지되는 바위 최대 개수
        drop_count_at_once = 2, -- 한번에 떨어뜨릴 바위 개수
        drop_distance = 4.3, -- 맵 중심으로부터 자성바위 드랍할 거리
        drop_interval = 2, --2개 이상 낙하시 낙하 간격

        -- 바위 정보
        vfo_hitbox_pivot = { 0.5, 0, 0.5 }, -- 바위 충돌체 기준점(벽판정)
        vfo_hitbox_size = { 1, 0.75, 1 }, -- 바위 충돌체 크기

        falling_init_velocity = 5,
        falling_acceleration = 1,
        fall_duration = 0.4, --낙하 시간      @실제로 낙하 시간을 결정
        fall_height = 20, --낙하 높이       @비주얼 적으로 어느 높이쯤에서 떨어뜨리는지

        magnet_life_time = 5,
        -- 낙하 직격 피해
        impact_radius = 2, --낙하 피격 범위
        impact_damage_modifier = 1, --낙하 피격 배율
        impact_knockback_force = 1, --낙하 피격 넉백 배율

        -- 펜스
        laser_preaction_time = 0.5, --펜스 활성화 준비 시간(연출)
        laser_postaction_time = 0.5, --펜스 완전히 꺼지는 시간(연출)
        laser_fence_offsetY = 0.6,

        laser_width = 0.3, --펜스 넓이
        laser_height = 0.5, --펜스 높이
        -- 펜스 길이는 가변으로 결정된다.

        laser_damage_modifier = 1.8, --펜스 데미지 배율
        laser_knockback_force = 0, --펜스 넉백 배율
        laser_damage_term = 0.8, --펜스 접촉시 피해 간격 (짧으면 기사는 튀겨짐)

        -- fx
        fx_normal_stone_name = 'fx_boss_magwi_magnatic_rock_normal', --자성 없는 바위 모델링
        fx_magnetic_stone_name = 'fx_boss_magwi_magnatic_rock', --자성 바위 모델링

        fx_normal_stone_destroy_name = 'fx_boss_magwi_magnatic_rock_crash', --자성 바위 파괴 vfx
        fx_magnetic_stone_destroy_name = 'fx_boss_magwi_magnatic_rock_crash', --자성 바위 파괴 vfx

        fx_stone_impact_name = 'fx_boss_magwi_magnatic_rock_dust',

        fx_laser_name = 'fx_boss_magwi_laser_fence', --레이저 연결된 이펙트(fx_s_laser_light)

        -- sfx
        sfx_stone_landing_name = '02_magwi_rock_set_01',
        sfx_stone_destroy_name = '03_rock_break_05',
        sfx_stone_destroy_by_drill_name = '03_rock_break_01',
        sfx_laser_fence_on_name = '02_magwi_rock_fence_01',

        laser_pattern1 = { { 1, 4 }, { 2, 7 }, { 3, 6 }, { 5, 8 }, },
        laser_pattern2 = { { 1, 6 }, { 2, 5 }, { 3, 8 }, { 4, 7 }, },
        laser_pattern3 = { { 6, 7 }, { 7, 5 }, { 5, 8 }, { 8, 4 }, { 4, 1 }, { 1, 3 }, { 3, 2 } },

        stone_offset_list1 = { { 3.5, 0.5 }, { 3.5, -0.25 }, { 1, -0.5 }, { -1, -0.5 }, { -3.5, -0.25 }, { -3.5, 0.5 }, { -1, 0.5 }, { 1, 0.5 } }, --바위 위치 선정시 육각형 모양을 변경하기위한 위치 모음
        stone_offset_list2 = { { 0.5, 0.5 }, { 0.5, 0 }, { 0.5, -0.5 }, { 0, -0.5 }, { -0.5, 0 }, { -0.5, 0.5 }, { 0, 0.5 }, { 0.5, 0.5 } }, --바위 위치 선정시 육각형 모양을 변경하기위한 위치 모음

        laser_pattern_check_box1 = { 4, 6 },
        laser_pattern_check_box2 = { 4, 6 },
        --육각형은 맨 오른쪽(3시) 부터 1234 시계방향.


        magnetic_drop_ignore_indexes = { 7,8 },
    },
}
