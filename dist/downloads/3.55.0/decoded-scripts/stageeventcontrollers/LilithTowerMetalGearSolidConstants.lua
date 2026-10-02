return {
	-- 공용 상수
	common = {
		--region Patrol Terrorist

		-- 테러리스트 시야 각도
		terrorist_sight_angle_idle = 70,
		terrorist_sight_angle_detected = 120,

		-- 테러리스트 시야 길이
		terrorist_sight_distance_idle = 3.5,
		terrorist_sight_distance_detected = 6,

		-- Puzzled 상태 테러리스트의 방향 변환 딜레이
		terrorist_puzzled_change_direction_delay = 1.5,

		-- Return 상태 테러리스트의 복귀 속도
		terrorist_returned_speed = 4,

		-- 적대적이 된 테러리스트가 전투 상태를 계속 유지하는 시간
		terrorist_keep_monster_delay = 3,

		--endregion
	},

	-- 1스테이지 전용 상수
	lilithtower_1_1 = {
		--region Patrol Terrorist

		-- 순찰 테러리스트 이름
		patrol_terrorist_name = 'patrol_terrorist_',

		-- 순찰 테러리스트 개수
		patrol_terrorist_num = 5,

		--endregion

		--region Super Terrorist

		-- 슈퍼 테러리스트 이름
		super_terrorist_name = 'super_terrorist_',

		-- 슈퍼 테러리스트 개수
		super_terrorist_num = 0,

		--endregion

		-- 해당 이름의 존에 들어가면 경계 상태 강제 종료됨
		alert_quit_zone_names = { 'b_area_event_start', 'c_area_event_start' },

		-- 카메라 확대시킬 그리드 이름
		camera_resize_grid_names = {},

		-- 그리드 별 몬스터 이벤트 그룹
		camera_grid_event_groups = {}
	},

	-- 2스테이지 전용 상수
	lilithtower_1_2 = {
		--region Patrol Terrorist

		-- 순찰 테러리스트 이름
		patrol_terrorist_name = 'patrol_terrorist_',

		-- 순찰 테러리스트 개수
		patrol_terrorist_num = 10,

		--endregion

		--region Super Terrorist

		-- 슈퍼 테러리스트 이름
		super_terrorist_name = 'super_terrorist_',

		-- 슈퍼 테러리스트 개수
		super_terrorist_num = 0,

		--endregion

		-- 해당 이름의 존에 들어가면 경계 상태 강제 종료됨
		alert_quit_zone_names = { 'vent', 'safe_house', 'machinery_room' },

		-- 카메라 확대시킬 그리드 이름
		camera_resize_grid_names = { '3', '9', '11', '16', '18', '22' },

		-- 그리드 별 몬스터 이벤트 그룹
		camera_grid_event_groups = { 'maze_room', 'shop_corridor', 'middle_corridor',
		                             'main_hall', 'hotel_room_2', 'hotel_room_1' }
	},

	-- 3스테이지 전용 상수
	lilithtower_1_3 = {
		--region Patrol Terrorist

		-- 순찰 테러리스트 이름
		patrol_terrorist_name = 'patrol_terrorist_',

		-- 순찰 테러리스트 개수
		patrol_terrorist_num = 6,

		--endregion

		--region Super Terrorist

		-- 슈퍼 테러리스트 이름
		super_terrorist_name = 'super_terrorist_',

		-- 슈퍼 테러리스트 개수
		super_terrorist_num = 12,

		--endregion

		-- 해당 이름의 존에 들어가면 경계 상태 강제 종료됨
		alert_quit_zone_names = { 'vent_1', 'vent_2', 'first_floor_chest' },

		-- 카메라 확대시킬 그리드 이름
		camera_resize_grid_names = { 'machine_01', 'machine_02', 'machine_04', 'machine_05', '20', '21', '23' },

		-- 그리드 별 몬스터 이벤트 그룹
		camera_grid_event_groups = { 'machinery_fourth_room', 'machinery_third_room',
		                             'machinery_second_room', 'machinery_entrance', 'first_main_hall',
		                             'first_floor_right_room', 'first_floor_left_room' }
	}
}
