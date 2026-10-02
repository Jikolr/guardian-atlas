demon_world_global_event = get_or_create_global_variable('utils/DemonWorldGlobalEvent')

local local_class = newclass("DemonWorldBasicSystem")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region NPC
	-- 전체 NPC 정보를 저장하는 테이블
	self.npc_infos = {}

	-- NPC Type과 Talk Index를 저장하는 테이블 (위는 NPC 생성 시점에 생기는 테이블이므로 추가함)
	self.npc_types = {}

	-- 생성해서 돌려쓸 NPC 이름
	self.npc_name = 'spawn_npc_'

	-- 생성해서 돌려쓸 NPC 개수
	self.npc_num = 16

	-- 서로 다른 NPC 간의 생성 대기 시간
	self.npc_spawn_delay = 1

	-- 현재 화면에 보이는 주민 수 (일정 수 이상 보이면 생성 중단)
	self.cur_npc_on_camera_num = 0

	-- 화면에 보이는 최대 주민 수
	self.npc_on_camera_limit = 4

	-- NPC AI 상태
	self.npc_ai_state = {
		-- 생성 대기 상태
		idle = 0,
		-- 가만히 서서 말 걸면 대화하는 NPC 기본 상태
		talk_normal = 1,
		-- 경로를 따라 이동하는 상태
		move_waypoint = 2,
		-- 데미지 받아서 멈춰 있는 상태
		stop_by_damaged = 3,
		-- 플레이어로부터 도망치는 상태
		flee = 4,
		-- 도망이 종료되서 플레이어가 더 쫓아오지 않는지 지켜보는 상태
		wait_for_look = 5,
		-- 경로로 복귀하는 상태
		comeback = 6,
		-- HP가 0이 되서 죽은 상태
		dead = 7
	}

	-- NPC 데미지 입었을 때 대처 타입
	self.npc_damaged_type = {
		-- 대기 후 일정 체력 이하면 도망침
		runaway = 1,
		-- 제자리에서 전투 모션 취하면서 덤빔
		challenge = 2
	}

	-- 어떤 이동 타입의 NPC가 스폰될 지 결정하는 값
	self.npc_move_type = {
		waypoint = 0,
		stopped = 1
	}

	-- 이동 타입 스폰 관련 랜덤 값 보정
	self.spawn_npc_counter_start = 0
	self.spawn_npc_counter_end = 1
	self.spawn_counter_standard = 0.5

	-- NPC 이동 속도
	self.npc_walk_speed = 1.5
	self.npc_dash_speed = 3

	-- NPC가 서로 겹쳤다고 인식하는 거리 (겹쳐서 생성되는 것 막기 위함)
	self.npc_distance_limit = 1

	-- NPC가 데미지 입은 뒤 복귀 상태로 돌아가는 대기 시간
	self.damaged_delay = 3

	-- NPC가 대기하면서 상황을 지켜보는 상태(WaitForLook)에서 대기하는 시간
	self.wait_for_look_delay = 3

	-- NPC가 카메라 바깥으로 나간 뒤, 이 거리보다 멀어지면 제거됨
	self.out_of_camera_distance_limit = 20

	-- NPC가 플레이어가 근접했음을 인식하는 거리
	self.npc_notice_player_distance = 4

	-- NPC가 도망을 중지하는 플레이어와 NPC 사이의 거리
	self.stop_flee_distance = 7

	-- NPC 피격 대사 개수
	self.runaway_npc_damaged_talk_num = 3
	self.challenge_npc_damaged_talk_num = 2

	-- NPC 도망칠 때 선택할 Direction의 리스트
	self.npc_flee_direction_table = {}

	-- NPC가 방향을 지나치게 자주 바꾸는 것을 막기 위한 방향 유지 시간
	self.direction_change_time = 1.5

	-- 시민 대사
	self.civilian_talk_num = 4
	self.civilian_talk_name = 'demonworld1_civilian_talk_'

	-- NPC Immortal Zone 이름
	self.npc_immortal_zone_names = {}

	-- NPC Immortal 플래그
	self.is_npc_immortal = false

	-- 플레이어 옥상에 있음을 알리는 플래그
	self.is_in_rooftop = false
--endregion

--region NPC Spawn Marker
	-- NPC 생성 마커의 정보를 저장하는 테이블
	self.npc_spawn_markers = {}

	-- NPC 생성 마커 이름
	self.npc_spawn_marker_name = 'npc_spawn_'

	-- 정지해 있는 NPC 생성 마커의 정보를 저장하는 테이블
	self.stop_npc_spawn_markers = {}

	-- 정지해 있는 NPC 생성 마커 이름
	self.stop_npc_spawn_marker_name = 'stop_npc_spawn_'

	-- 한 마커에 연속 생성될 때까지 대기 시간
	self.npc_spawn_marker_delay = 3
--endregion

--region Police
	-- 경찰 테이블
	self.police_tables = {}

	-- 추적 경찰 테이블
	self.follow_police_table = {}

	-- 순찰 경찰 테이블
	self.patrol_police_table = {}

	-- 에리나
	self.erina = nil

	-- 경찰 이름
	self.police_names = { 'police_1_', 'police_2_', 'police_3_', 'police_4_' }
	self.patrol_police_names = { 'patrol_police_1_', 'patrol_police_2_', 'patrol_police_3_',
	                             'patrol_police_4_', 'patrol_police_5_' }
	self.follow_police_name = 'follow_police_'
	self.erina_name = 'police_erina'

	-- 레벨 별 경찰 수
	self.police_nums = nil

	-- 추적 경찰 수
	self.follow_police_nums = nil

	self.current_patrol_police_num = 0
	self.patrol_police_nums = nil

	-- 일반 경찰 생성 마커의 정보를 저장하는 테이블
	self.police_spawn_markers = {}

	-- 일반 경찰 생성 마커 이름
	self.police_spawn_marker_name = 'police_spawn_'

	-- 순찰 경찰 생성 마커의 정보를 저장하는 테이블
	self.patrol_police_spawn_markers = {}

	-- 순찰 경찰 생성, 이동 마커 이름
	self.patrol_police_spawn_marker_name = 'patrol_police_spawn_'

	-- 경찰 상태
	self.police_state = {
		-- 생성 대기 상태
		idle = 0,
		-- 플레이어 추적 중인 상태
		search_player = 1,
		-- 전투 중인 상태
		battle = 2,
		-- HP가 0이 되서 죽은 상태
		dead = 3
	}

	-- 경찰 시야 거리와 각도
	self.police_sight_distance = 3.15
	self.police_sight_angle = 60

	-- 경찰 쓰러트린 후 재생성까지 대기 시간
	self.police_respawn_delays = { 8, 8, 7, 6, 6 }

	-- 순찰 경찰 초기화 된 후 재생성까지 대기 시간
	self.patrol_police_respawn_delays = { 6, 6, 5, 5, 4 }

	-- 경찰 작동 중단 플래그
	self.pause_police = false

	-- 중복 발견 방지 플래그
	self.is_detected_by_police = false

	-- 플레이어가 경찰과 전투하기 전 원래 위치와 방향
	self.player_saved_pos = nil
	self.player_saved_dir = nil

	-- 플레이어와 경찰의 전투 위치 마커 포지션
	self.police_battle_marker_position = nil

	-- 플레이어와 경찰의 전투 위치 마커 이름
	self.police_battle_marker_name = 'police_battle'

	-- 배틀 그룹 이름
	self.police_battle_group_name = 'police_'
	self.police_battle_group_name_table = { 'police_1', 'police_2', 'police_3', 'police_4', 'police_5' }
	self.erina_battle_group_name = 'police_erina'

	-- 에리나 생성 마커 이름, 마커
	self.erina_spawn_marker_name = 'spawn_erina'
	self.erina_spawn_marker = nil

	self.police_crash_event_name = 'police_crash_player'
	self.current_crashed_police = nil
--endregion

--region Notoriety
	-- 플레이어의 악명 수치
	self.current_notoriety = 0

	-- 플레이어의 악명 레벨
	self.notoriety_lv = 0

	-- 악명 레벨, 점수 데이터 키
	self.notoriety_lv_data_key = 'notoriety_lv'
	self.notoriety_num_data_key = 'notoriety_num'

	-- 단계별 악명 수치
	self.notoriety_lv_values = { 10, 50, 100, 180, 300 }
	self.notoriety_lv_gauge_maxes = { 10, 40, 50, 80, 120 }

	-- 특수 행동 시 올라가는 악명 수치
	self.kill_civilian_notoriety = 5
	self.kill_police_notorieties = { 20, 30, 40, 60, 60 }

	-- 악명 레벨 MAX
	self.notoriety_lv_max = 5

	-- 현재 악명이 감소 중인지 저장하는 플래그
	self.is_notoriety_declined = false

	-- 악명 감소 상태로 전환하는 시간 카운터
	self.notoriety_declined_counter = 0

	-- 화면 내에 경찰이 없을 경우, 해당 시간만큼 대기 후에 악명이 감소하기 시작
	self.notoriety_declined_delay = 5

	-- 악명 감소 상태에서 레벨 당 악명 수치가 1 감소하는데 걸리는 시간
	self.notoriety_declined_sec = { 2, 1, 0.8, 0.6, 0.45, 0.3 }

	-- 현상 수배 상태일 경우, 전투가 발생하지 않도록 현재 스테이지의 배틀 그룹들을 받아와서 저장
	self.battle_groups = {}

	-- 현재 전투 중인 배틀 그룹에 들어 있는 몬스터 리스트
	-- (전투 종료 시 배틀 그룹이 제거되서 전투했던 몬스터들을 찾아올 수 없는 문제 해결)
	self.current_battle_group_monsters = {}

	-- 일반 전투 중일 경우, 이 값이 TRUE여서 현상 수배 레벨이 0에서 1로 올라갈 수 없도록 설정
	self.is_battle_with_fixed_monster = false

	-- 사이렌 이펙트 리스트
	self.siren_effect_list = nil

	-- 사이렌 생성 위치 마커 정보
	self.siren_marker_positions = {}
	self.siren_marker_num = nil
	self.siren_marker_name = 'siren_'

	-- 불 이펙트 필드오브젝트 리스트
	self.fire_effect_obj_list = nil
	self.fire_effect_obj_num = nil
	self.fire_effect_obj_name = 'fire_effect_'

	-- 불 이펙트 생성 위치 마커 정보
	self.fire_effect_obj_marker_name = 'fire_effect_'

	-- 악명 레벨 단계 별 틴트 키
	self.notoriety_lv_3_tint_key = 'demonworld_notoriety_lv_3'
	self.notoriety_lv_4_tint_key = 'demonworld_notoriety_lv_4'

	-- 4단계 틴트 키 일시정지 플래그
	self.pause_lv_4_tint = false

	-- 사이렌 SFX 루프
	self.siren_sfx = nil

	-- 현상 수배 초기화시켜주는 NPC
	self.notoriety_reset_npc = nil

	-- 해당 NPC의 이모티콘
	self.notoriety_reset_npc_emoticon = nil

	-- 현상 수배 초기화시켜주는 NPC 이름
	self.notoriety_reset_npc_name = 'notoriety_reset_npc'

	-- 현상 수배 초기화 비용
	self.notoriety_reset_dollar = 10000

	-- 컨트롤러에서 악명 점수가 변경되었을 때 Publish하는 커스텀 이벤트 이름
	self.current_notoriety_num = 'current_notoriety_num'

	-- 컨트롤러에서 악명 레벨이 변경되었을 때 Publish하는 커스텀 이벤트 이름
	self.current_notoriety_lv = 'current_notoriety_lv'

	-- 컨트롤러 외부에서 악명 레벨을 수정할 때 날릴 커스텀 이벤트 이름
	self.notoriety_lv_changed_custom_event = 'notoriety_lv_changed'

	-- 컨트롤러 외부에서 드론, 헬기에게 감지되었음을 알릴 때 날릴 커스텀 이벤트 이름
	self.detect_stalker_custom_event = 'detect_stalker'
--endregion

--region Notoriety UI
	-- 악명 UI
	self.notoriety_ui = nil

	-- UI 별 리스트 (UISprite)
	self.notoriety_ui_star_list = nil

	-- 게이지 바 리스트와 라벨
	self.notoriety_ui_gauge_bar_list = nil
	self.notoriety_ui_gauge_bar_label = nil

	-- 악명 상승 요청 req Id (중복 요청 처리)
	self.notoriety_req_id = -1

	-- UI의 별 개수
	self.notoriety_ui_star_num = 5

	-- 게이지에 표시될 악명 수치 최대값
	self.notoriety_ui_gauge_max = 300

	-- UI의 악명 증가 연출 시간
	self.notoriety_add_duration = 0.5
	self.notoriety_add_duration_defeat_police = 1

	-- UI의 악명 감소 연출 시간
	self.notoriety_declined_duration = 0.1
	self.notoriety_declined_with_special_event_duration = 1

	-- 별 스프라이트 페이드 인 시간
	self.star_sprite_fade_duration = 0.25
	self.star_sprite_fade_out_duration = 1

	-- 게이지 시작 위치
	self.gauge_bar_start_pos = nil

	-- 악명 레벨 증가 UI
	self.level_up_ui = nil

	-- 악명 레벨 증가 UI가 한 번에 여러 개 나올 수 없도록 막는 플래그
	self.is_level_up_ui_event = false

	-- 악명 레벨 증가 시 얻는 디버프 이름
	self.level_up_debuff_name = 'demonworld_part1_notoriety_debuff_'

	-- 디버프 레벨
	self.level_up_debuff_lvs = { 10, 10, 10, 1, 1 }
--endregion

--region dollar
	-- 드랍된 달러 테이블
	self.dollar_table = {}

	-- 달러 데이터 키
	self.dollar_data_key = 'dollar'

	-- 커스텀 이벤트
	self.dollar_add_event = 'dollar_add'
	self.dollar_remove_event = 'dollar_remove'

	-- 달러 아이템 ID
	self.dollar_item_id = 20339

	-- NPC 드랍 골드 양 최소값
	self.npc_drop_dollar_min = 45

	-- NPC 드랍 골드 양 최대값
	self.npc_drop_dollar_max = 50

	-- 경찰 드랍 골드 양 최소값
	self.police_drop_dollar_min = 60

	-- 경찰 드랍 골드 양 최대값
	self.police_drop_dollar_max = 70

	-- 달러 드랍 범위
	self.dollar_dropped_range_x = 0.5
	self.dollar_dropped_range_z = 0.5

	-- 달러 획득 거리
	self.dollar_pick_distance = 0.3
--endregion

	-- Constants
	self.constants = nil

	-- 리소스 홀더
	self.resholder = nil

	-- 플레이어 악명 레벨
	self.notoriety_lv = 0

	-- 스테이지 이름
	self.stage_2_name = 'demonworld_part1_1_2'
	self.stage_3_name = 'demonworld_part1_1_3'
	self.stage_4_name = 'demonworld_part1_1_4'

	-- 스테이지 종료 플래그
	-- (controller가 제거되면 코루틴도 꺼지겠지만,
	-- 문제를 미연에 방지하기 위해 controller Dispose할 때 이 값을 true로 하고 코루틴 중단한다)
	self.is_exit_stage = false

	-- 플레이어 전투 플래그
	self.player_is_battle = false

	-- 플레이어 게임오버 플래그
	self.player_is_gameover = false

	-- Exclusive 이벤트 시에 악명 올라가지 않도록 처리하는 플래그
	self.is_exclusive_quest_start = false

	-- 메인 퀘스트 번호
	self.main_quest_id = 216

	-- 이펙트 프리셋 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.explosion_effect_preset = 'FX_dead'
	self.siren_effect_preset = 'fx_siren_demonworld'
	self.erina_spawn_effect_preset = 'fx_erina_spawn'
	self.erina_bounce_effect_preset = 'FX_minotaur_buttbounce'
	self.teleport_effect_preset = 'FX_reset_object'

	-- NPC 로직 스테이트 (연속으로 타지 않도록 하기 위해)
	self.npc_logic_state = { changing = 1, hide = 2, show = 3, }

	-- 현재 NPC 로직 스테이트
	self.current_npc_logic_state = self.npc_logic_state.show

	-- NPC 숨길 익스클루시브 키 값 리스트
	self.hide_npc_exclusive_key_list = {
		'phone_booth',
		'adultery',
		'pervert',
		'kid_bully_key',
	}
end

function local_class:load_resource()
	-- 메인 퀘스트 InnerProgress가 6 이하면 작동하지 않음
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local main_quest_inner_progress = quest_progress.InnerProgress

	if main_quest_inner_progress <= 6 then
		return
	end

	unity_object_pool.GetOrCreate(self.siren_effect_preset)
	unity_object_pool.GetOrCreate(self.erina_spawn_effect_preset)
	unity_object_pool.GetOrCreate(self.erina_bounce_effect_preset)
	unity_object_pool.GetOrCreate(self.teleport_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')

	self.constants = require('minigame/DemonWorldBasicSystem/DemonWorldCivilianConstants')

	local waypoint_civilian_marker_list_num = 0
	local stop_civilian_marker_list_num = 0
	local follow_police_marker_list_num = 0
	local patrol_police_marker_list_num = 0

	local constant_data = self.constants[stage.Name]

	if constant_data ~= nil then
		-- 시민 타입 정보 테이블에 등록
		self.npc_types = constant_data.civilian_type_data

		-- 이동 시민 생성 마커 정보 테이블에 등록
		waypoint_civilian_marker_list_num = #constant_data.waypoint_civilian_spawn_marker_data

		-- 제자리 시민 생성 마커 정보 테이블에 등록
		stop_civilian_marker_list_num = constant_data.stop_civilian_spawn_marker_data.num

		-- 추적 경찰 생성 마커 정보 테이블에 등록
		follow_police_marker_list_num = constant_data.police_spawn_marker_data.num

		-- 순찰 경찰 생성 마커 정보 테이블에 등록
		patrol_police_marker_list_num = #constant_data.patrol_police_spawn_marker_data

		for i = 1, waypoint_civilian_marker_list_num do
			self.npc_spawn_markers[i] = {
				index = constant_data.waypoint_civilian_spawn_marker_data[i].index,
				marker_num = constant_data.waypoint_civilian_spawn_marker_data[i].marker_num,
				markers = {},
				loop = constant_data.waypoint_civilian_spawn_marker_data[i].loop,
				current_npc_num = 0,
				npc_limit = {}
			}
		end

		for i = 1, patrol_police_marker_list_num do
			self.patrol_police_spawn_markers[i] = {
				marker_num = constant_data.patrol_police_spawn_marker_data[i].marker_num,
				markers = {},
				lv = constant_data.patrol_police_spawn_marker_data[i].lv
			}
		end

		self.patrol_police_nums = constant_data.patrol_police_nums

		self.police_nums = constant_data.battle_police_nums
		self.follow_police_nums = constant_data.follow_police_nums

		-- 배틀 그룹 정보 등록
		local num_battle_groups = #constant_data.battle_group_names
		if num_battle_groups > 0 then
			for i = 1, num_battle_groups do
				self.battle_groups[i] = stage.BattleManager:GetBattleGroup(constant_data.battle_group_names[i])
			end
		end

		-- 사이렌 정보 등록
		self.siren_marker_num = constant_data.siren_marker_num

		-- 불 오브젝트 정보 등록
		self.fire_effect_obj_num = constant_data.fire_obj_num

		-- NPC Immortal 존 정보 등록
		self.npc_immortal_zone_names = constant_data.npc_immortal_zone_names

		self.npc_num = #constant_data.civilian_type_data
	end

	if self.siren_marker_num > 0 then
		for i = 1, self.siren_marker_num do
			self.siren_marker_positions[i] = field:GetMarker(self.siren_marker_name..i).position
		end
	end

	for i = 1, waypoint_civilian_marker_list_num do
		for n = 1, self.npc_spawn_markers[i].marker_num do
			table.insert(self.npc_spawn_markers[i].markers, field:GetMarker(self.npc_spawn_marker_name..self.npc_spawn_markers[i].index..'_'..n))
			table.insert(self.npc_spawn_markers[i].npc_limit, 0)
		end
	end

	if stop_civilian_marker_list_num > 0 then
		for i = 1, stop_civilian_marker_list_num do
			self.stop_npc_spawn_markers[i] = {
				marker = field:GetMarker(self.stop_npc_spawn_marker_name..i),
				is_used = false
			}
		end
	end

	if follow_police_marker_list_num > 0 then
		for i = 1, follow_police_marker_list_num do
			self.police_spawn_markers[i] = {
				marker = field:GetMarker(self.police_spawn_marker_name..i),
				is_used = false
			}
		end
	end

	if patrol_police_marker_list_num > 0 then
		for i = 1, patrol_police_marker_list_num do
			for n = 1, self.patrol_police_spawn_markers[i].marker_num do
				table.insert(self.patrol_police_spawn_markers[i].markers,
					field:GetMarker(self.patrol_police_spawn_marker_name..i..'_'..n))
			end
		end
	end

	-- NPC 생성 마커 수 정보가 없을 경우 작동하지 않음
	if self.npc_spawn_markers ~= nil and #self.npc_spawn_markers > 0 then
		message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

		-- NPC 정보 테이블에 등록
		for i = 1, self.npc_num do
			local cur_character = get_character(self.npc_name..i)

			stage.BattleManager:AddToNoAssassination(cur_character)

			cur_character.EntityGroup = CS.Oak.EntityGroups.Enemy0
			cur_character.CrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance
			cur_character.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.None)

			self.npc_infos[i] = {
				character = cur_character,
				activated = false,
				ai_state = self.npc_ai_state.idle,
				damaged = false,
				out_of_camera = false,
				waypoints = {},
				spawn_marker_index = 0,
				wait_duration = 0,
				move_type = 0,
				damage_type = self.npc_types[i].damage_type,
				talk_index = self.npc_types[i].talk_index,
				talk_string = '',
				male = self.npc_types[i].male,
			}
		end

		-- NPC Direction Table 설정
		self.npc_flee_direction_table = {}
		local size = 12
		local angle_step = math.pi * 2 / size

		for i = 1, size do
			table.insert(self.npc_flee_direction_table,
					unity_class.vector3(math.cos(angle_step * i), 0, math.sin(angle_step * i)))
		end
	end

	-- 경찰 정보 테이블에 등록
	for n = 1, #self.police_names do
		self.police_tables[n] = {}

		for i = 1, self.police_nums[n] do
			local cur_police = {
				character = get_character(self.police_names[n]..i),
				state = self.police_state.idle,
				attack_range = nil
			}

			table.insert(self.police_tables[n], cur_police)
		end
	end

	self.erina = get_character(self.erina_name)

	local erina_data = {
		character = self.erina,
		state = self.police_state.idle,
		attack_range = nil
	}

	self.police_tables[5] = {}
	table.insert(self.police_tables[5], erina_data)

	-- 추적 경찰 정보 테이블에 등록
	for i = 1, 3 do
		local cur_police = {
			character = get_character(self.follow_police_name..i),
			state = self.police_state.idle,
			attack_range = nil
		}

		table.insert(self.follow_police_table, cur_police)
	end

	self.notoriety_reset_npc = get_character(self.notoriety_reset_npc_name)

	-- 나이트메어 에서는 시민을 때리지 못해서 악명이 올라가지 않기 때문에, NPC가 필요 없음.
	-- 따라서, NPC가 없는 경우에 대한 예외처리
	if self.notoriety_reset_npc ~= nil then
		character_util.add_listener(self.notoriety_reset_npc, self.cs_controller)
	end

	self.siren_effect_list = create_generic_list(CS.Oak.PooledUnityObject)

	self.fire_effect_obj_list = create_generic_list(CS.Oak.FieldObject)
	if self.fire_effect_obj_num > 0 then
		for i = 1, self.fire_effect_obj_num do
			self.fire_effect_obj_list:Add(get_field_object(self.fire_effect_obj_name..i))
		end
	end

	self.police_battle_marker_position = field:GetMarker(self.police_battle_marker_name).position
	self.erina_spawn_marker = field:GetMarker(self.erina_spawn_marker_name)

	CS.Oak.CommonScreenplay.PreloadBossTitle()

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.resholder = CS.Foundations.ResourceHolder()

	-- 악명 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/ui', 'notoriety_ui', function(prefab)
				self.notoriety_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
			end)

	-- 악명 증가 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/ui', 'warning_ui', function(prefab)
				self.level_up_ui = CS.NGUITools.AddChild(stage.UIRoot.gameObject, prefab)
				self.level_up_ui:SetActive(false)
			end)
end

function local_class:need_on_launch()
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	self.npc_infos = nil
	self.npc_spawn_markers = nil

	self.is_exit_stage = true

	self.police_tables = nil
	self.erina = nil
	self.current_crashed_police = nil

	self.police_spawn_markers = nil

	self.siren_marker_positions = nil

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	self.notoriety_ui = nil
	self.notoriety_ui_star_list = nil
	self.notoriety_ui_gauge_bar_list = nil
	self.notoriety_ui_gauge_bar_label = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, self.notoriety_reset_npc) then
			if self.current_notoriety == 0 then
				sp_util.play_normal_screenplay(self.interact_with_notoriety_reset_npc_normal, self)
			else
				sp_util.play_normal_screenplay(self.interact_with_notoriety_reset_npc, self)
			end
		else
			for i = 1, #self.npc_infos do
				if lua_helper.reference_equals(e.Target, self.npc_infos[i].character) then
					character_util.look_at(self.npc_infos[i].character, user_party.Leader)

					speech_bubble_util.remove_bubble(self.npc_infos[i].character)
					speech_bubble_util.show_speech_bubble(
							self.npc_infos[i].character, { key = self.npc_infos[i].talk_string })

					break
				end
			end
		end
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	-- 악명 UI 기본 설정
	self.notoriety_ui.transform:Find('Contents/Button/item/Title'):GetComponent(typeof(CS.UILabel)).text =
		game_string:GetString('demonworld_part1_notoriety_title_0')

	self.notoriety_ui_gauge_bar_list = create_generic_list(CS.UISprite)
	for i = 1, self.notoriety_lv_max do
		self.notoriety_ui_gauge_bar_list:Add(self.notoriety_ui.transform:Find(
				'Contents/Button/item/GaugeBar/GaugeBar_'..i..'/After'):GetComponent(typeof(CS.UISprite)))
	end

	self.gauge_bar_start_pos = self.notoriety_ui.transform:Find('Contents/Button/item/GaugeBar').localPosition

	self.notoriety_ui_gauge_bar_label = self.notoriety_ui.transform:Find(
			'Contents/Button/item/GaugeBar/Gauge_Label'):GetComponent(typeof(CS.UILabel))

	self.notoriety_ui_star_list = create_generic_list(CS.UISprite)
	for i = 1, self.notoriety_ui_star_num do
		local cur_custom_sprite = self.notoriety_ui.transform:Find(
				'Contents/Button/item/stars/star_'..i):GetComponent(typeof(CS.UISprite))

		cur_custom_sprite.alpha = 0

		self.notoriety_ui_star_list:Add(cur_custom_sprite)
	end

	for i = 0, self.notoriety_ui_gauge_bar_list.Count - 1 do
		self.notoriety_ui_gauge_bar_list[i].fillAmount = 0.0
	end

	-- 악명 레벨 업 UI 기본 설정
	self.level_up_ui.transform:Find('Warning/Title'):GetComponent(
			typeof(CS.UILabel)).text = game_string:GetString('demonworld_part1_notoriety')

	for i = 0, self.notoriety_lv - 1 do
		self.notoriety_ui_star_list[i].alpha = 1
	end

	self.notoriety_ui:SetActive(false)

	self:fill_gauge(self.current_notoriety)
end

function local_class:on_stage_start_event(e)
	-- NPC 제어하는 루틴 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.control_npc, self))

	-- 순찰 경찰에게 플레이어가 발각되었는지 확인하는 루틴 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.check_patrol_police_find_player, self))

	-- 현상 수배 레벨 처리
	self:generic_setting_notoriety_lv()

	-- 현상 수배 리셋 NPC 이모티콘 표시
	self:show_notoriety_reset_npc_emoticon()
end

function local_class:on_stage_end_event(e)
	self.is_exit_stage = true
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.npc_immortal_zone_names ~= nil then
			for n = 1, #self.npc_immortal_zone_names do
				-- Immortal Zone에 입장한 경우 NPC 공격 불가로 만듬
				if e.Zone.Name == self.npc_immortal_zone_names[n] then
					if not self.is_npc_immortal then
						self.is_npc_immortal = true

						self:npc_set_immortal(true)
					end

					break
				end
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.npc_immortal_zone_names ~= nil then
			for n = 1, #self.npc_immortal_zone_names do
				-- Immortal Zone에서 퇴장한 경우 NPC 원래대로 복구
				if e.Zone.Name == self.npc_immortal_zone_names[n] then
					if self.is_npc_immortal then
						self.is_npc_immortal = false

						self:npc_set_immortal(false)
					end

					break
				end
			end
		end
	end
end

function local_class:on_damage_event(e)
	if self.current_npc_logic_state ~= self.npc_logic_state.show then
		return false
	end

	for i = 1, #self.npc_infos do
		if lua_helper.reference_equals(e.Info.target, self.npc_infos[i].character) and
				e.Info.type ~= CS.Oak.DamageType.WallHit then
			-- 화면 밖에서 맞은 경우, 상태가 꼬일 수 있어서 처리하지 않음
			if not self.npc_infos[i].out_of_camera then
				music_player_util.play_sfx_one_shot('02_hit_big_01')

				-- 악명 감소 상태에서 플레이어가 시민을 공격한 경우, 상태 해제하고 카운터 초기화
				if self.is_notoriety_declined then
					self.is_notoriety_declined = false
					self.notoriety_declined_counter = 0
				end

				-- 이미 Flee 상태라면 HPBar만 보여줌
				if self.npc_infos[i].ai_state == self.npc_ai_state.flee then
					message_system:Publish(CS.Oak.ShowCharacterHPBarEvent.Create(self.npc_infos[i].character))
					-- 악명 렙이 3 이상이면 NPC가 계속 flee 상태기 때문에 처리하지 않음
				elseif self.notoriety_lv < 3 then
					self:npc_convert_to_monster(i)
				end

				break
			end
		end
	end

	return false
end

function local_class:on_battle_start_event(e)
	local current_battle_monsters = e.StartedBattle.AllCharacters

	-- 배틀 그룹 전체 순회
	for n = 1, #self.battle_groups do
		local check_completed = false
		local monsters = self.battle_groups[n]:GetMonsters()

		-- 현재 전투 중인 몬스터에 배틀 그룹의 몬스터가 1개라도 포함되어 있을 경우, 일반 전투 시작 플래그를 켬
		for i = 0, monsters.Count - 1 do
			if current_battle_monsters:Contains(monsters[i]) then
				self.is_battle_with_fixed_monster = true

				-- 몬스터 전부 제거되고 나서 레벨이 오른 경우, 레벨 상승 처리하는 루틴 실행
				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.wait_for_check_notoriety_lv, self))

				check_completed = true

				table.insert(self.current_battle_group_monsters, monsters[i])

				-- 전투 중에는 현상 수배 레벨 감소하지 않고 카운터 초기화함
				self.is_notoriety_declined = false
				self.notoriety_declined_counter = 0
			end
		end

		if check_completed then
			-- 시민, 차 비활성화
			self.current_npc_logic_state = self.npc_logic_state.changing

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_npc_alpha_fade, self))

			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'pause_car_logic' }))

			break
		end
	end
end

function local_class:on_battle_end_event(e)
	local current_battle_monsters = e.CharactersInBattle
	local check_completed = false

	-- 전투 종료된 몬스터에 배틀 그룹의 몬스터가 1개라도 포함되어 있을 경우, 일반 전투 시작 플래그를 끔
	for i = 1, #self.current_battle_group_monsters do
		if current_battle_monsters:Contains(self.current_battle_group_monsters[i]) then
			self.is_battle_with_fixed_monster = false

			check_completed = true

			break
		end
	end

	-- 전투 종료된 몬스터 테이블 초기화
	if check_completed then
		self.current_battle_group_monsters = {}

		-- 시민, 차 활성화
		self.current_npc_logic_state = self.npc_logic_state.changing

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			-- 전투 종료 후 2초 뒤에 npc들 보이도록
			wait_for_sec(2)

			self:show_npc_alpha_fade()
		end))

		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'resume_car_logic' }))
	end
end

function local_class:on_battle_group_eliminated_event(e)
	for i = 1, #self.police_battle_group_name_table do
		if e.BattleGroupName == self.police_battle_group_name_table[i] then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_police, self, i))
			break
		end
	end

	if e.BattleGroupName == self.erina_battle_group_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_erina, self))
	end
end

function local_class:on_field_object_destroyed_event(e)
	for i = 1, #self.npc_infos do
		if lua_helper.reference_equals(e.FieldObject, self.npc_infos[i].character) then
			local dead_by_car = true

			for n = 0, user_party.Count - 1 do
				if lua_helper.reference_equals(e.Destroyer, user_party[n]) then
					dead_by_car = false

					break
				end
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.npc_die_routine, self, self.npc_infos[i], dead_by_car))

			-- 플레이어가 죽인 경우 & CharacterControllerScreenplayState가 아닐 경우
			if not dead_by_car and not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
					CS.Oak.CharacterControllerScreenplayState) then
				-- 악명 추가
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.add_notoriety, self, self.current_notoriety + self.kill_civilian_notoriety))

				-- 달러 양 정함
				local dollar_amount = math.floor(unity_class.random.Range(self.npc_drop_dollar_min, self.npc_drop_dollar_max))

				for n = 1, 3 do
					local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
					demon_world_dollar:add_dollar(math.floor(dollar_amount / 3), true, { pos = self.npc_infos[i].character.Position })
				end
			end
		end
	end

	for i = 1, #self.police_tables do
		local cur_table = self.police_tables[i]

		for j = 1, #cur_table do
			if lua_helper.reference_equals(e.FieldObject, cur_table[j].character) then
				-- 달러 양 정함
				local dollar_amount = math.floor(
						unity_class.random.Range(self.police_drop_dollar_min, self.police_drop_dollar_max))

				for n = 1, 3 do
					local demon_world_dollar = get_or_create_global_table('stageeventcontrollers/DemonWorldDollar')
					demon_world_dollar:add_dollar(math.floor(dollar_amount / 3), true, { pos = cur_table[j].character.Position })
				end
			end
		end
	end
end

function local_class:on_game_over_event(e)
	self.player_is_gameover = true

	-- 경찰 이동 중단
	self.pause_police = true

	-- 드론, 헬기 이동 중단
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_stop' }))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_pause' }))

	-- 사이렌 소리 종료
	if self.siren_sfx ~= nil then
		self.siren_sfx:FadeOut(1)
	end
end

function local_class:on_field_object_revived_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		self.player_is_gameover = false

		-- 경찰 이동 재개
		self.pause_police = false

		-- 사이렌 소리 재개
		if self.notoriety_lv >= 2 then
			self.siren_sfx = music_player_util.play_sfx(
					{ sfx_name = '01_siren_loop_05', loop = true, type_priority = 'loop' })
		end

		-- 드론, 헬기 이동 재개
		if self.notoriety_lv >= 3 then
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_start' }))
		end

		if self.notoriety_lv >= 4 then
			-- 플레이어가 전투 구역에 있는 경우 활성화하면 안 됨
			if not self.player_is_battle then
				message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_resume' }))
			end
		end
	end
end

function local_class:on_field_ui_show_event(e)
	if self.current_notoriety > 0 then
		self.notoriety_ui:SetActive(true)
	end
end

function local_class:on_field_ui_hide_event(e)
	self.notoriety_ui:SetActive(false)
end

function local_class:on_custom_stage_event(e)
	-- 악명 레벨 변경
	if e:GetParamAt(0) == self.notoriety_lv_changed_custom_event then
		local level = tonumber(e:GetParamAt(1))
		self.notoriety_lv = level

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_star, self, self.notoriety_lv))

		self.current_notoriety = self.notoriety_lv_values[level]

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.add_notoriety, self, self.current_notoriety))

		-- 현상 수배 레벨 처리
		local custom_routine = function()
			coroutine.yield(self:activate_level_up_ui())
			self:generic_setting_notoriety_lv()
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(custom_routine))
		-- 드론이나 헬기에 발각된 경우
	elseif e:GetParamAt(0) == self.detect_stalker_custom_event then
		-- 악명 감소 상태 해제하고 카운터 초기화
		self.is_notoriety_declined = false
		self.notoriety_declined_counter = 0
	elseif e:GetParamAt(0) == 'pause_npc_logic' then
		self.is_exclusive_quest_start = true

		if self.current_npc_logic_state ~= self.npc_logic_state.show then
			return false
		end

		self.current_npc_logic_state = self.npc_logic_state.changing

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_npc_alpha_fade, self))
	elseif e:GetParamAt(0) == 'resume_npc_logic' then
		self.is_exclusive_quest_start = false

		if self.current_npc_logic_state ~= self.npc_logic_state.hide then
			return false
		end

		self.current_npc_logic_state = self.npc_logic_state.changing

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_npc_alpha_fade, self))
	elseif e:GetParamAt(0) == self.police_crash_event_name then
		if self.current_crashed_police == nil then
			self.current_crashed_police = e.Sender
		end
	end
end

function local_class:on_exclusive_quest_start_event(e)
	-- NPC 감추기
	if self.current_npc_logic_state ~= self.npc_logic_state.show then
		return false
	end

	if table_util.contain_value(self.hide_npc_exclusive_key_list, e.Key) then
		self.is_exclusive_quest_start = true
		self.current_npc_logic_state = self.npc_logic_state.changing
		self:hide_npc(e.Fade)
		return true
	end
end

function local_class:on_exclusive_quest_end_event(e)
	-- NPC 보이기
	if self.current_npc_logic_state ~= self.npc_logic_state.hide then
		return false
	end

	if table_util.contain_value(self.hide_npc_exclusive_key_list, e.Key) then
		self.is_exclusive_quest_start = false
		self.current_npc_logic_state = self.npc_logic_state.changing
		self:show_npc(e.Fade)
		return true
	end
end

--region exclusive start / end
-- 익스클루시브 처리 관련

-- NPC를 숨긴다.
function local_class:hide_npc(is_fade)
	if is_fade then
		self:hide_npc_list()
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_npc_alpha_fade, self))
	end
end

-- NPC를 보여준다.
function local_class:show_npc(is_fade)
	if is_fade then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_npc_alpha_fade, self, 0))
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_npc_alpha_fade, self))
	end
end

-- NPC들의 움직임을 멈추고 Spine Alpha Fade 이후에 disabled 시켜준다.
function local_class:hide_npc_alpha_fade()
	for i = 1, #self.npc_infos do
		self.npc_infos[i].character.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		if self.npc_infos[i].activated then
			character_util.spine_set_alpha_fade(self.npc_infos[i].character, 0, 0.5)
		end
	end
	wait_for_sec(0.5)

	self:hide_npc_list()
end

-- npc들의 움직임을 멈추고 바로 disable 시켜준다.
function local_class:hide_npc_list()
	for i = 1, #self.npc_infos do
		if self.npc_infos[i].activated then
			self.npc_infos[i].ai_state = self.npc_ai_state.comeback
			character_util.stop(self.npc_infos[i].character)
			character_util.remove_anim_and_emotion(self.npc_infos[i].character)
			character_util.set_active_state(self.npc_infos[i].character, 'disabled')
		end
	end
	self.current_npc_logic_state = self.npc_logic_state.hide
end

-- 활성화 됐던 NPC들의 스파인을 Fade하며 활성화 시켜준다.
function local_class:show_npc_alpha_fade(duration)
	local fade_duration = lua_helper.get_or_default(duration, 0.5)

	-- 먼저 페이드 해준다.
	for i = 1, #self.npc_infos do
		if self.npc_infos[i].activated then
			character_util.spine_set_alpha_fade(self.npc_infos[i].character, 1, fade_duration)
		end
	end
	wait_for_sec(fade_duration)

	self:show_npc_list()
end

-- NPC를 다시 원래 자리로 돌려주고 활성화 시킨다.
function local_class:show_npc_list()
	for i = 1, #self.npc_infos do
		self.npc_infos[i].character.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.None)
		if self.npc_infos[i].activated then
			character_util.set_active_state(self.npc_infos[i].character, 'enabled')
			--[PS-5302] 수정 / npc 복귀 루틴 대신 최단 거리 찾는 함수를 실행 하고 있어 복귀 루틴으로 변경
			--self:get_shortest_distance_and_move_way_point(self.npc_infos[i])
			-- spawn_npc 16개 모두 동시에 복귀 해야 하고 함수가 불리는 횟수가 많지 않아 코루틴을 생성
			start_coroutine(self.wait_for_comeback, self, self.npc_infos[i])
		end
	end
	self.current_npc_logic_state = self.npc_logic_state.show
end

--endregion

--region NPC Function
-- NPC 제어 루틴
function local_class:control_npc()
	local timer = 0

	while not self.is_exit_stage do
		if self.current_npc_logic_state == self.npc_logic_state.show then
			timer = timer + unity_class.time.deltaTime

			-- 플레이어 옥상에 있으면 공격 불가능하게 처리
			-- Zone과 겹치면 Zone 우선 처리
			if not self.is_npc_immortal then
				if not self.is_in_rooftop and field:IsOnUpperFloor(user_party.Leader.Position) then
					self.is_in_rooftop = true

					self:npc_set_immortal(true)
				elseif self.is_in_rooftop and not field:IsOnUpperFloor(user_party.Leader.Position) then
					self.is_in_rooftop = false

					self:npc_set_immortal(false)
				end
			else
				self.is_in_rooftop = false
			end

			-- 카메라에 보이지 않는 것 체크를 위해 스테이지 카메라의 파라미터 받아옴
			local camera_pos = stage_camera.LookAtPosition

			-- 화면 밖으로 나간 NPC들을 조사해서 상태 변경 및 화면 안의 NPC 개수 확인
			local npc_in_camera = 0

			for i = 1, #self.npc_infos do
				if self.npc_infos[i].activated then
					-- 화면 밖으로 나가거나 들어온 NPC 관리
					if self:is_pos_in_camera(self.npc_infos[i].character.Position) then
						npc_in_camera = npc_in_camera + 1

						-- 상태 변경되면 플래그 바꿔주고 유예 기간 초기화
						if self.npc_infos[i].out_of_camera then
							self.npc_infos[i].out_of_camera = false
						end
					else
						-- 상태 변경되면 플래그 바꿔줌
						if not self.npc_infos[i].out_of_camera then
							self.npc_infos[i].out_of_camera = true
						else
							local distance = (camera_pos - self.npc_infos[i].character.Position).magnitude

							-- 일정 거리 이상 멀어지면 NPC 제거 후 초기화 루틴 실행
							if distance >= self.out_of_camera_distance_limit then
								speech_bubble_util.remove_bubble(self.npc_infos[i].character)

								character_util.set_active_state(self.npc_infos[i].character, 'disabled')
								character_util.stop(self.npc_infos[i].character)
								character_util.remove_anim(self.npc_infos[i].character)
								character_util.remove_emotion(self.npc_infos[i].character)

								if self.npc_infos[i].move_type == self.npc_move_type.waypoint then
									self.npc_spawn_markers[self.npc_infos[i].spawn_marker_index].current_npc_num =
									self.npc_spawn_markers[self.npc_infos[i].spawn_marker_index].current_npc_num - 1
								end

								self:initialize_npc(self.npc_infos[i])
							end
						end
					end

					-- TalkNormal 상태에서 NPC State 변경
					if self.npc_infos[i].ai_state == self.npc_ai_state.talk_normal then
						-- 플레이어의 악명 체크
						if self.notoriety_lv >= 3 then
							-- 플레이어가 일정 거리 이내로 들어온 경우
							if (user_party.Leader.Position - self.npc_infos[i].character.Position).magnitude <
									self.npc_notice_player_distance then
								self:npc_state_change(self.npc_infos[i], self.npc_ai_state.flee)
							end
						end
						-- MoveWaypoint 상태에서 NPC State 변경
					elseif self.npc_infos[i].ai_state == self.npc_ai_state.move_waypoint then
						-- 플레이어의 악명 체크
						if self.notoriety_lv >= 2 then
							-- 플레이어가 일정 거리 이내로 들어온 경우
							if (user_party.Leader.Position - self.npc_infos[i].character.Position).magnitude <
									self.npc_notice_player_distance then
								-- 악명 레벨 2이면 NPC가 플레이어를 보고 멈춰서서 벌벌 떤다
								if self.notoriety_lv == 2 then
									self:npc_state_change(self.npc_infos[i], self.npc_ai_state.wait_for_look)
									-- 악명 레벨이 3 이상이면 NPC가 플레이어를 보고 도망친다
								else
									self:npc_state_change(self.npc_infos[i], self.npc_ai_state.flee)
								end
							end
						end
						-- Flee 상태에서 NPC State 변경 및 도망 실행
					elseif self.npc_infos[i].ai_state == self.npc_ai_state.flee then
						-- 플레이어가 일정 거리 밖으로 도망친 경우
						if (user_party.Leader.Position - self.npc_infos[i].character.Position).magnitude >=
								self.stop_flee_distance then
							self:npc_state_change(self.npc_infos[i], self.npc_ai_state.wait_for_look)
						else
							-- Flee 상태에서 FieldObjectBehaviour의 State가 변경될 경우 다시 AnalogueState로 복구
							if not lua_helper.type_compare(self.npc_infos[i].character.FieldObjectBehaviour.CurrentState,
									typeof(CS.Oak.CharacterAnalogueState)) then
								message_system:Send(self.npc_infos[i].character.CharacterBehaviour,
										CS.Oak.StateChangeEvent.Create(
												CS.Oak.CharacterAnalogueState.Create(self.npc_infos[i].character)))
							end

							-- NPC가 도망치는 실제 로직 처리
							self:character_flee(self.npc_infos[i], user_party.Leader)
						end
						-- WaitForLook 상태에서 NPC State 변경
					elseif self.npc_infos[i].ai_state == self.npc_ai_state.wait_for_look then
						character_util.look_at(self.npc_infos[i].character, user_party.Leader)

						-- 플레이어가 일정 거리 이내로 들어온 경우
						if (user_party.Leader.Position - self.npc_infos[i].character.Position).magnitude <
								self.npc_notice_player_distance then
							-- 공격받아서 도망치는 경우
							if self.npc_infos[i].damaged then
								self:npc_state_change(self.npc_infos[i], self.npc_ai_state.flee)
							else
								-- 플레이어의 악명 체크
								if self.notoriety_lv == 2 then
									self.npc_infos[i].wait_duration = self.wait_for_look_delay
								elseif self.notoriety_lv > 2 then
									self:npc_state_change(self.npc_infos[i], self.npc_ai_state.flee)
								end
							end
							-- 플레이어가 일정 거리 밖에 있는 경우 타이머 감소하고 0되면 comeback 상태로 돌아감
						else
							self.npc_infos[i].wait_duration = self.npc_infos[i].wait_duration - unity_class.time.deltaTime

							if self.npc_infos[i].wait_duration <= 0 then
								self.npc_infos[i].wait_duration = 0

								coroutine_manager:StartCoroutine(stage.StageGameObject,
										util.cs_generator(self.wait_for_comeback, self, self.npc_infos[i]))
							end
						end
						-- Comeback 상태에서 NPC State 변경
					elseif self.npc_infos[i].ai_state == self.npc_ai_state.comeback then
						-- 플레이어가 일정 거리 이내로 들어온 경우
						if (user_party.Leader.Position - self.npc_infos[i].character.Position).magnitude <
								self.npc_notice_player_distance then
							-- 플레이어의 악명 체크
							if self.notoriety_lv == 2 then
								self:npc_state_change(self.npc_infos[i], self.npc_ai_state.wait_for_look)
							elseif self.notoriety_lv > 2 then
								self:npc_state_change(self.npc_infos[i], self.npc_ai_state.flee)
							end
						end
					end
				end
			end

			-- 마커의 NPC 생성 카운터 감소
			for i = 1, #self.npc_spawn_markers do
				for j = 1, #self.npc_spawn_markers[i].npc_limit do
					if self.npc_spawn_markers[i].npc_limit[j] ~= 0 then
						self.npc_spawn_markers[i].npc_limit[j] =
						self.npc_spawn_markers[i].npc_limit[j] - unity_class.time.deltaTime

						if self.npc_spawn_markers[i].npc_limit[j] < 0 then
							self.npc_spawn_markers[i].npc_limit[j] = 0
						end
					end
				end
			end

			-- 일정 시간마다 화면 밖에서 NPC를 생성함
			if timer >= self.npc_spawn_delay then
				-- 타이머 초기화
				timer = 0

				-- 화면에 한계 이상의 NPC가 보이는 경우 넘어감
				if npc_in_camera < self.npc_on_camera_limit then
					-- 이동 NPC를 생성할 것인지 정지 NPC를 생성할 것인지 결정
					local cur_counter = unity_class.random.Range(
							self.spawn_npc_counter_start, self.spawn_npc_counter_end)
					local is_spawn_waypoint_npc = cur_counter < self.spawn_counter_standard

					if is_spawn_waypoint_npc then
						-- 랜덤 설정 값을 보정해줌
						self.spawn_npc_counter_start = self.spawn_counter_standard
						self.spawn_npc_counter_end = 1

						-- 먼저 카메라와 가장 가까우면서 화면에 보이지 않는 NPC 생성 마커를 찾는다
						local shortest_dist = 9999
						local selected_marker = nil

						-- 마커 인덱스 값과 생성 마커 개수를 알아야 경로 설정이 가능
						local marker_table_num = 0
						local cur_marker_waypoint_index = 0

						for i = 1, #self.npc_spawn_markers do
							for j = 1, self.npc_spawn_markers[i].marker_num do
								local cur_marker = self.npc_spawn_markers[i].markers[j]

								-- 카메라에 보이거나 마커의 기본 NPC 생성 리미트가 0이 되서 해제되지 않은 상태라면 넘어감
								if not self:is_pos_in_camera(cur_marker.position) and
										self.npc_spawn_markers[i].npc_limit[j] <= 0 then
									-- 마커와 카메라 거리 측정 후 이전 최단 거리와 비교
									local cur_dist = math.abs((camera_pos - cur_marker.position).magnitude)

									if shortest_dist > cur_dist then
										selected_marker = cur_marker
										shortest_dist = cur_dist

										marker_table_num = i
										cur_marker_waypoint_index = j
									end
								end
							end
						end

						-- 선택된 마커 값이 nil이면 넘어간다
						if selected_marker ~= nil then
							-- 비활성화 된 NPC 중에서 랜덤으로 하나 골라서 생성한다
							local cur_activated_npc_infos = {}

							for i = 1, #self.npc_infos do
								if not self.npc_infos[i].activated then
									table.insert(cur_activated_npc_infos, self.npc_infos[i])
								end
							end

							-- 테이블에 원소 하나라도 있어야 생성 진행
							if #cur_activated_npc_infos > 0 then
								local spawn_npc_rand_index = math.floor(
										unity_class.random.Range(1, #cur_activated_npc_infos + 1))
								local cur_npc_info = cur_activated_npc_infos[spawn_npc_rand_index]

								cur_npc_info.activated = true
								cur_npc_info.ai_state = self.npc_ai_state.move_waypoint
								cur_npc_info.spawn_marker_index = marker_table_num
								cur_npc_info.move_type = self.npc_move_type.waypoint

								character_util.set_active_state(cur_npc_info.character, 'enabled')

								-- 주변에 다른 NPC가 있어서 겹치는 경우가 발생하지 않도록 체크해서 위치 변경
								local position_diff = unity_class.vector3.zero

								for j = 1, #self.npc_infos do
									if spawn_npc_rand_index ~= j then
										if (selected_marker.position - self.npc_infos[j].character.Position).magnitude <
												self.npc_distance_limit then
											position_diff =
											CS.Oak.DirectionExtensions.ToVector3(selected_marker.direction)

											break
										end
									end
								end

								character_util.remove_relate_event(cur_npc_info.character, self.cs_controller)

								character_util.set_position(
										cur_npc_info.character, selected_marker.position + position_diff)
								character_util.set_direction(cur_npc_info.character, selected_marker.direction)

								self.npc_spawn_markers[marker_table_num].current_npc_num =
									self.npc_spawn_markers[marker_table_num].current_npc_num + 1
								self.npc_spawn_markers[marker_table_num].npc_limit[cur_marker_waypoint_index] =
									self.npc_spawn_marker_delay

								-- NPC가 경로를 이동하도록 설정
								local marker_waypoint_num = self.npc_spawn_markers[marker_table_num].marker_num
								cur_npc_info.waypoints = {}

								-- 핑퐁 방식으로 움직이는 NPC는 저장된 웨이포인트와 실제 경로가 다르므로 따로 계산
								local real_waypoint_for_pingpong = {}
								local move_end_index = 0

								if self.npc_spawn_markers[marker_table_num].loop then
									for n = 1, marker_waypoint_num do
										table.insert(cur_npc_info.waypoints,
												self.npc_spawn_markers[marker_table_num].markers[
												cur_marker_waypoint_index].position)

										if cur_marker_waypoint_index == marker_waypoint_num then
											cur_marker_waypoint_index = 1
										else
											cur_marker_waypoint_index = cur_marker_waypoint_index + 1
										end
									end
								else
									for n = 1, marker_waypoint_num do
										table.insert(real_waypoint_for_pingpong,
												self.npc_spawn_markers[marker_table_num].markers[
												cur_marker_waypoint_index].position)

										if cur_marker_waypoint_index == marker_waypoint_num then
											break
										else
											cur_marker_waypoint_index = cur_marker_waypoint_index + 1
											move_end_index = move_end_index + 1
										end
									end

									for n = 1, marker_waypoint_num do
										table.insert(cur_npc_info.waypoints,
												self.npc_spawn_markers[marker_table_num].markers[n].position)
									end
								end

								character_util.set_anim(cur_npc_info.character, { name = 'walk' })

								if self.npc_spawn_markers[marker_table_num].loop then
									character_util.move_waypoint(cur_npc_info.character, cur_npc_info.waypoints,
											self.npc_walk_speed, false,
											'loop', 'floor', CS.Oak.Direction.Down)
								else
									character_util.move_waypoint(cur_npc_info.character, real_waypoint_for_pingpong,
											self.npc_walk_speed, false,
											'stop', 'floor', CS.Oak.Direction.Down,
											false, 0,
											function(index)
												-- 도착 지점에 오면 반대 경로로 이동한다
												if index == move_end_index then
													self:move_waypoint_pingpong(cur_npc_info, marker_table_num)
												end
											end)
								end
							end
						end
					else
						-- 랜덤 설정 값을 보정해줌
						self.spawn_npc_counter_end = self.spawn_counter_standard
						self.spawn_npc_counter_start = 0

						-- 먼저 카메라와 가장 가까우면서 화면에 보이지 않는 NPC 생성 마커를 찾는다
						local shortest_dist = 9999
						local selected_marker = nil
						local selected_marker_index = 0

						for i = 1, #self.stop_npc_spawn_markers do
							local cur_marker = self.stop_npc_spawn_markers[i].marker

							-- 카메라에 보이거나 마커의 기본 NPC 생성 마커가 사용 중 상태라면 넘어감
							if not self:is_pos_in_camera(cur_marker.position) and
									not self.stop_npc_spawn_markers[i].is_used then
								-- 마커와 카메라 거리 측정 후 이전 최단 거리와 비교
								local cur_dist = math.abs((camera_pos - cur_marker.position).magnitude)

								if shortest_dist > cur_dist then
									selected_marker_index = i
									selected_marker = cur_marker
									shortest_dist = cur_dist
								end
							end
						end

						-- 선택된 마커 값이 nil이면 넘어간다
						if selected_marker ~= nil then
							-- 카메라에 보이지 않으면서 카메라와 최단 거리의 마커에 NPC 생성
							for i = 1, #self.npc_infos do
								local cur_npc_info = self.npc_infos[i]

								-- 비활성화 된 NPC 중에서 생성
								if not cur_npc_info.activated then
									cur_npc_info.activated = true
									cur_npc_info.ai_state = self.npc_ai_state.talk_normal
									cur_npc_info.spawn_marker_index = selected_marker_index
									cur_npc_info.move_type = self.npc_move_type.stopped

									character_util.set_active_state(cur_npc_info.character, 'enabled')

									table.insert(cur_npc_info.waypoints, selected_marker.position)

									local talk_num = math.floor(unity_class.random.Range(1, self.civilian_talk_num))
									cur_npc_info.talk_string = self.civilian_talk_name..cur_npc_info.talk_index..'_'..talk_num

									character_util.add_listener(cur_npc_info.character, self.cs_controller)
									character_util.set_position(
											cur_npc_info.character, selected_marker.position)
									character_util.set_direction(cur_npc_info.character, selected_marker.direction)

									self.stop_npc_spawn_markers[selected_marker_index].is_used = true

									break
								end
							end
						end
					end
				end
			end
		end
		coroutine.yield(nil)
	end
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴
function local_class:is_pos_in_camera(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	if math.abs(camera_pos.x - pos.x) > cam_half_width + 0.7 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 0.5 then
		return false
	end

	return true
end

-- NPC 무적 설정
function local_class:npc_set_immortal(is_immortal)
	if is_immortal then
		for i = 1, #self.npc_infos do
			self.npc_infos[i].character.EntityGroup = CS.Oak.EntityGroups.Neutral0
			self.npc_infos[i].character.CharacterStatsBehaviour:AddStatsOptionRequest(stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
		end

		if self.npc_spawn_markers ~= nil and #self.npc_spawn_markers > 0 then
			message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
		end
	else
		for i = 1, #self.npc_infos do
			self.npc_infos[i].character.EntityGroup = CS.Oak.EntityGroups.Enemy0
			self.npc_infos[i].character.CharacterStatsBehaviour:RemoveStatsOptionRequest(stage.StageGameObject, CS.Oak.CharacterStatsOptions.Invincible)
		end

		if self.npc_spawn_markers ~= nil and #self.npc_spawn_markers > 0 then
			message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
		end
	end
end

-- NPC State 변경
function local_class:npc_state_change(cur_npc_info, state)
	cur_npc_info.ai_state = state

	if state == self.npc_ai_state.wait_for_look then
		cur_npc_info.wait_duration = self.wait_for_look_delay

		character_util.stop(cur_npc_info.character)
		character_util.look_at(cur_npc_info.character, user_party.Leader)
		character_util.set_anim(cur_npc_info.character, { name = 'cast' })
		character_util.set_emotion(cur_npc_info.character, { name = 'tired' })
	elseif state == self.npc_ai_state.flee then
		-- NPC가 플레이어를 보고 도망친다
		if cur_npc_info.male then
			if not self.player_is_gameover then
				music_player_util.play_sfx_one_shot('01_villain_scream_04')
			end

			speech_bubble_util.show_speech_bubble(cur_npc_info.character,
					{ key = 'demonworld_part1_civilian_'..4 })
		else
			if not self.player_is_gameover then
				music_player_util.play_sfx_one_shot('02_victim_fly_02')
			end

			speech_bubble_util.show_speech_bubble(cur_npc_info.character,
					{ key = 'demonworld_part1_civilian_'..5 })
		end

		if cur_npc_info.move_type == self.npc_move_type.stopped then
			character_util.remove_relate_event(cur_npc_info.character, self.cs_controller)
		end

		character_util.stop(cur_npc_info.character)
		character_util.set_anim(cur_npc_info.character, { name = 'run' })
		character_util.set_emotion(cur_npc_info.character, { name = 'damaged' })

		message_system:Send(cur_npc_info.character.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
				CS.Oak.CharacterAnalogueState.Create(cur_npc_info.character)))
	end
end

-- NPC가 공격받으면 플레이어와 적대하는 이벤트
function local_class:npc_convert_to_monster(index)
	local cur_npc = self.npc_infos[index].character
	local cur_damage_type =  self.npc_infos[index].damage_type

	-- 이미 데미지 입어서 적대하는 NPC는 시간 초기화, 방향 변경, 이모션 표시만 진행한다
	character_util.look_at(cur_npc, user_party.Leader)

	-- 타입에 따라 상태 변경
	if cur_damage_type == self.npc_damaged_type.runaway then
		-- HP에 따라 상태 변경
		if cur_npc.FieldObjectStatsBehaviour.HP >= cur_npc.FieldObjectStatsBehaviour.MaxHP * 0.6 then
			self.npc_infos[index].ai_state = self.npc_ai_state.stop_by_damaged
			self.npc_infos[index].wait_duration = self.damaged_delay

			character_util.set_emotion(cur_npc, { name = 'damaged' })
			character_util.set_anim(cur_npc, { name = 'embarrassed' })
		elseif not cur_npc.FieldObjectStatsBehaviour.IsDead and cur_npc.FieldObjectStatsBehaviour.HP > 0 then
			self.npc_infos[index].wait_duration = 0
			self:npc_state_change(self.npc_infos[index], self.npc_ai_state.flee)
		end
	else
		self.npc_infos[index].ai_state = self.npc_ai_state.stop_by_damaged
		self.npc_infos[index].wait_duration = self.damaged_delay

		-- Business Male은 해당 애니메이션이 없음
		if index ~= 3 then
			character_util.set_anim(cur_npc, { name = 'gauntlet_combo_attack' })
		else
			character_util.set_anim(cur_npc, { name = 'rifle_idle' })
		end

		character_util.set_emotion(cur_npc, { name = 'attack' })
	end

	if not self.npc_infos[index].damaged then
		self.npc_infos[index].damaged = true

		-- ! 표시
		CS.Oak.NoticeIcon.SetBattleStart(cur_npc)

		speech_bubble_util.remove_bubble(cur_npc)

		-- 타입에 따라 대사 변경
		if cur_damage_type == self.npc_damaged_type.runaway then
			-- 랜덤 대사 출력
			local cur_talk_num = math.floor(unity_class.random.Range(1, self.runaway_npc_damaged_talk_num))

			speech_bubble_util.show_speech_bubble(cur_npc, { key = 'demonworld_part1_civilian_'..cur_talk_num })
		else
			-- 랜덤 대사 출력
			local cur_talk_num = math.floor(
					unity_class.random.Range(6, 6 + self.challenge_npc_damaged_talk_num))

			speech_bubble_util.show_speech_bubble(cur_npc, { key = 'demonworld_part1_civilian_'..cur_talk_num })
		end

		if self.npc_infos[index].move_type == self.npc_move_type.stopped then
			character_util.remove_relate_event(cur_npc, self.cs_controller)
		end

		-- NPC의 HPBar를 보여줌
		message_system:Publish(CS.Oak.ShowCharacterHPBarEvent.Create(self.npc_infos[index].character))

		-- 사운드
		if self.npc_infos[index].male then
			music_player_util.play_sfx_one_shot('01_villain_scream_04')
		else
			music_player_util.play_sfx_one_shot('02_victim_fly_02')
		end

		if self.npc_infos[index].ai_state == self.npc_ai_state.stop_by_damaged then
			character_util.stop(cur_npc)

			if cur_damage_type == self.npc_damaged_type.runaway then
				character_util.remove_anim(cur_npc)
			end

			-- NPC 일정 시간 대기 후에 다시 이동 시작하는 루틴 실행
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.wait_for_comeback, self, self.npc_infos[index]))
		end
	end
end

-- NPC가 공격 받고 일정 시간 지나면 다시 NPC로 바뀐 뒤 원래 위치로 돌아가서 웨이포인트 이동을 진행하는 루틴
function local_class:wait_for_comeback(cur_npc_info)
	local timer_finished = false

	-- NPC가 죽거나 비활성화 된 경우 루틴 종료
	while not self.is_exit_stage and cur_npc_info.activated and
			not cur_npc_info.character.FieldObjectStatsBehaviour.IsDead do
		cur_npc_info.wait_duration = cur_npc_info.wait_duration - unity_class.time.deltaTime

		-- 시간이 전부 지난 경우 루틴 종료
		if cur_npc_info.wait_duration <= 0 then
			timer_finished = true

			break
			-- NPC State가 Flee로 변경된 경우 루틴 종료
		elseif cur_npc_info.ai_state == self.npc_ai_state.flee then
			break
		end

		if self.is_exit_stage then
			return
		end

		coroutine.yield(nil)
	end

	if self.is_exit_stage then
		return
	end

	-- NPC 복귀한다
	if timer_finished and cur_npc_info.ai_state ~= self.npc_ai_state.flee then
		cur_npc_info.damaged = false
		cur_npc_info.ai_state = self.npc_ai_state.comeback

		-- NPC의 HPBar를 숨김
		message_system:Publish(CS.Oak.HideCharacterHPBarEvent.Create(cur_npc_info.character))

		character_util.set_anim(cur_npc_info.character, { name = 'walk' })
		character_util.remove_emotion(cur_npc_info.character)
		self:get_shortest_distance_and_move_way_point(cur_npc_info)
	else
		-- 비정상적 종료 시 파라미터 초기화
		cur_npc_info.wait_duration = 0
	end
end

-- 핑퐁 이동 (재귀 호출 주의)
function local_class:move_waypoint_pingpong(cur_npc_info, marker_table_num)
	-- 버그 방지
	if #cur_npc_info.waypoints > 1 then
		-- 역순으로 저장
		local cur_new_waypoints = {}

		for i = #cur_npc_info.waypoints, 1, -1 do
			table.insert(cur_new_waypoints, cur_npc_info.waypoints[i])
		end

		-- 이동 경로 재설정
		cur_npc_info.waypoints = cur_new_waypoints
		local move_end_index = #cur_npc_info.waypoints - 1

		local cur_dir = (cur_npc_info.waypoints[1] - cur_npc_info.character.Position):ToDirection()
		character_util.set_direction(cur_npc_info.character, cur_dir)

		character_util.move_waypoint(cur_npc_info.character, cur_new_waypoints,
				self.npc_walk_speed, false,
				'stop', 'floor', CS.Oak.Direction.Down,
				false, 0,
				function(index)
					-- 도착 지점에 오면 반대 경로로 이동한다
					if index == move_end_index then
						self:move_waypoint_pingpong(cur_npc_info, marker_table_num)
					end
				end)
	end
end

-- 웨이포인트로 복귀하는 최단 경로 찾기
function local_class:get_shortest_distance_and_move_way_point(cur_npc_info)
	if cur_npc_info.move_type == self.npc_move_type.waypoint then
		local shortest_dist = 9999
		local target
		local shortest_index = 1

		local point = cur_npc_info.character.Position

		for i = 1, #cur_npc_info.waypoints do
			local origin = cur_npc_info.waypoints[i]
			local cur_index = i + 1

			if i == #cur_npc_info.waypoints then
				cur_index = 1
			end

			local next = cur_npc_info.waypoints[cur_index]

			-- 웨이포인트 두 개를 이은 선분과 캐릭터의 위치 사이 최단거리를 구함
			local heading = (next - origin)
			local magnitude_max = heading.magnitude
			heading:Normalize()

			local lhs = point - origin
			local dot_p = unity_class.vector3.Dot(lhs, heading)
			dot_p = unity_class.mathf.Clamp(dot_p, 0, magnitude_max)

			-- 다른 선분과의 거리 비교하여 최단 거리면 저장한다
			local cur_target = origin + heading * dot_p
			local cur_dist = (cur_target - point).magnitude

			if cur_dist < shortest_dist then
				target = cur_target
				shortest_dist = cur_dist
				shortest_index = cur_index
			end
		end

		coroutine.yield(self:find_path_and_move(cur_npc_info, target))

		-- 정상 완료된 경우
		if not cur_npc_info.damaged and cur_npc_info.ai_state == self.npc_ai_state.comeback then
			-- 웨이포인트 리셋
			local waypoints_num = #cur_npc_info.waypoints
			local new_waypoints = {}
			local move_end_index = 0

			-- 플레이어 다시 원래 웨이포인트로 이동 시작
			for n = 1, waypoints_num do
				table.insert(new_waypoints, cur_npc_info.waypoints[shortest_index])

				if self.npc_spawn_markers[cur_npc_info.spawn_marker_index].loop then
					if shortest_index == waypoints_num then
						shortest_index = 1
					else
						shortest_index = shortest_index + 1
					end
				else
					if shortest_index == waypoints_num then
						break
					else
						shortest_index = shortest_index + 1
						move_end_index = move_end_index + 1
					end
				end
			end

			character_util.set_anim(cur_npc_info.character, { name = 'walk' })

			if self.npc_spawn_markers[cur_npc_info.spawn_marker_index].loop then
				character_util.move_waypoint(cur_npc_info.character, new_waypoints,
						self.npc_walk_speed, false,
						'loop', 'floor', CS.Oak.Direction.Down)
			else
				character_util.move_waypoint(cur_npc_info.character, new_waypoints,
						self.npc_walk_speed, false,
						'stop', 'floor', CS.Oak.Direction.Down,
						false, 0,
						function(index)
							-- 도착 지점에 오면 반대 경로로 이동한다
							if index == move_end_index then
								self:move_waypoint_pingpong(cur_npc_info, cur_npc_info.spawn_marker_index)
							end
						end)
			end
		end
	else
		-- 원래 위치로 복귀
		local target = cur_npc_info.waypoints[1]
		local end_dir = self.stop_npc_spawn_markers[cur_npc_info.spawn_marker_index].marker.direction

		coroutine.yield(self:find_path_and_move(cur_npc_info, target))

		-- 정상 완료된 경우
		if cur_npc_info.ai_state == self.npc_ai_state.comeback then
			cur_npc_info.ai_state = self.npc_ai_state.talk_normal

			character_util.set_direction(cur_npc_info.character, end_dir)
			character_util.add_listener(cur_npc_info.character, self.cs_controller)
			character_util.remove_anim(cur_npc_info.character)
		end
	end
end

-- 길찾기 경로 계산 및 이동 실행
function local_class:find_path_and_move(cur_npc_info, target)
	if target == nil then
		return nil
	end

	-- Path finder 사용해서 이동 경로 설정
	local current_planned_path
	local current_path_index = 0
	local plan_path_done = false

	field.PathFinder:FindNormalPath(
			cur_npc_info.character, target, 100, cur_npc_info.character, 0, nil, function(path, req_key)
				if req_key == 0 then
					plan_path_done = true

					if path ~= nil and path.Count > 0 then
						current_planned_path = create_generic_list(unity_class.vector3)

						for i = 1, path.Count - 1 do
							current_planned_path:Add(path[i])
						end
					end
				end
			end)

	-- Path finder 계산까지 대기, 도중에 공격받으면 취소
	while not self.is_exit_stage and not plan_path_done and not cur_npc_info.damaged do
		coroutine.yield(nil)
	end

	if not self.is_exit_stage and current_planned_path ~= nil and current_planned_path.Count > 0 and
			not cur_npc_info.damaged then
		message_system:Send(cur_npc_info.character.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
				CS.Oak.CharacterAnalogueState.Create(cur_npc_info.character)))

		while not self.is_exit_stage and not cur_npc_info.damaged and
				cur_npc_info.ai_state == self.npc_ai_state.comeback do
			-- 이번 프레임 이동 거리 계산
			local final_pos = cur_npc_info.character.Position
			local movement = self.npc_walk_speed * unity_class.time.deltaTime

			while movement > 0 and current_path_index < current_planned_path.Count do
				local diff = (current_planned_path[current_path_index] - final_pos):GetX0z()

				if float_util.is_almost_zero(diff.magnitude) then
					current_path_index = current_path_index + 1
				else
					if diff.magnitude < movement then
						movement = movement - diff.magnitude
						final_pos = current_planned_path[current_path_index]
						current_path_index = current_path_index + 1
					else
						final_pos = final_pos + diff.normalized * movement

						break
					end
				end
			end

			-- 방향 설정
			local final_diff = (final_pos - cur_npc_info.character.Position):GetX0z()
			local dir = final_diff.normalized:ToDirection()

			if dir == CS.Oak.Direction.None then
				dir = cur_npc_info.character.Direction
			end

			-- 최종 이동 요청
			if not float_util.is_almost_zero(final_diff.magnitude) then
				cur_npc_info.character.Position = final_pos
				character_util.set_direction(cur_npc_info.character, dir)
			else
				break
			end

			coroutine.yield(nil)
		end
	end
end

-- NPC가 공격 받아서 일정 체력 이하로 내려가거나 플레이어가 악명이 높은 상태에서 접근하여 도망치고 있을 때, 위치 설정
function local_class:character_flee(cur_npc_info, target)
	-- Null Reference 예방
	if cur_npc_info == nil or cur_npc_info.character == nil or target == nil then
		return
	end

	-- 캐릭터가 타겟으로부터 멀어지는 방향
	local flee_from_dir = (target.Position - cur_npc_info.character.Position):GetX0z().normalized

	-- 선택된 방향, 방향 점수 최댓값
	local best_dir = unity_class.vector3.zero
	local best_score = 0
	local final_uncollided_dist = 0

	-- 충돌 검사 거리
	local dist_to_check_collision = 2

	-- 각 방향으로 이동 시에 충돌하는 물체 검사 (Bound를 줄여서 검사함)
	local cur_bound = cur_npc_info.character.Bounds
	cur_bound.size = cur_bound.size * 0.5

	-- 각 방향에 대해 점수 계산
	for i = 1, #self.npc_flee_direction_table do
		-- 이 방향으로 이동할 때 충돌하지 않고 이동할 수 있는 최대 거리
		-- 열린 공간으로 도망치는 것이 유리하므로 값이 클수록 이상적임
		local uncollided_dist = dist_to_check_collision

		-- 캐릭터가 도주 지점 반대 방향으로 향하는 벡터와 각 방향 벡터의 내적
		-- 값이 클수록 도주 지점으로부터 멀어지는 방향이므로 이상적임
		local opposite_dot = unity_class.vector3.Dot(self.npc_flee_direction_table[i], -flee_from_dir)

		local collided_objs = CS.Oak.LuaCollisionUtil.GetCollidedFieldObjects(
				cur_bound, self.npc_flee_direction_table[i] * dist_to_check_collision)

		if collided_objs ~= nil then
			local distances = collided_objs.Item1
			local fo_list = collided_objs.Item2

			if fo_list ~= nil and distances ~= nil then
				for n = 0, fo_list.Count - 1 do
					-- 자기 자신과 EtherealCrash, 생성된 NPC, 플레이어 파티원들은 무시
					if not lua_helper.reference_equals(fo_list[n], cur_npc_info.character) and
							not CS.Oak.ICrashBehaviourExtensions.IsEthereal(fo_list[n].CrashBehaviour) and
							fo_list[n].EntityGroup ~= CS.Oak.EntityGroups.Enemy0 and
							fo_list[n].EntityGroup ~= CS.Oak.EntityGroups.Player0 then
						-- Field.GetFieldObjectsCollidedBy는 충돌한 물체를 가장 가까운 것부터 정렬해서 리턴하므로
						-- 제일 먼저 걸리는 물체가 가장 먼저 충돌하는 물체임.
						-- 따라서 해당 물체까지의 거리가 충돌하지 않고 이동할 수 있는 거리.
						uncollided_dist = distances[n].distance

						break
					end
				end
			end
			fo_list:Dispose()
			distances:Dispose()
		end

		-- 최소 빈 공간이 확보되지 않았으면 이 방향으로는 도망갈 수 없음
		if constants.epsilon < uncollided_dist then
			-- 이 방향으로 도망갈 때의 점수
			-- 충돌하지 않고 도주할 수 있는 거리가 멀 수록 이상적이고,
			-- 가급적 도주 원인 지점으로부터 멀어지는 방향일수록 이상적이므로 두 수치를 곱하는 것으로 측정
			-- 내적 텀에 0.1을 0.1f를 더하는 이유는 도주하다가 벽 등에 가로막혔을 때 도주 원인 지점 방향에 수직으로 이동하는
			-- 경우가 필요한데, 이 경우 해당 방향 점수가 0이 되어 도주 루트로 고려되지 않는 경우가 발생하지 않도록 함.
			local score = uncollided_dist * (opposite_dot + 1)

			-- 점수가 가장 높은 방향이 도주하기 좋은 방향
			if best_score < score then
				best_dir = self.npc_flee_direction_table[i]
				best_score = score
				final_uncollided_dist = uncollided_dist
			end
		end
	end

	if best_dir ~= unity_class.vector3.zero then
		-- AnalogueState 움직임 사용 시에는 벽에 끼는 경우가 자주 발생해서 직접 Position 변경
		character_util.set_direction(cur_npc_info.character, best_dir.normalized:ToDirection())
		local move_diff = best_dir.normalized *
				math.min(self.npc_dash_speed * unity_class.time.deltaTime, final_uncollided_dist)
		cur_npc_info.character.Position = cur_npc_info.character.Position + move_diff
	end

end

function local_class:npc_die_routine(cur_npc_info, dead_by_car)
	is_dead_by_car = lua_helper.get_or_default(dead_by_car, false)

	-- NPC 사망 처리
	if not is_dead_by_car then
		if cur_npc_info.male then
			music_player_util.play_sfx_one_shot('01_villain_scream_03')
		else
			music_player_util.play_sfx_one_shot('01_linda_scream_01')
		end

		if cur_npc_info.move_type == self.npc_move_type.stopped then
			character_util.remove_relate_event(cur_npc_info.character, self.cs_controller)
		end

		cur_npc_info.ai_state = self.npc_ai_state.dead

		character_util.stop(cur_npc_info.character)

		coroutine.yield(nil)

		cur_npc_info.character.SpineController:AddColor(
				cur_npc_info.character.Name, unity_color({ 0.2, 0.2, 0.2, 1 }), 1, 2)
		character_util.set_direction(cur_npc_info.character,
				CS.Oak.DirectionExtensions.GetSideDirection(cur_npc_info.character.Direction))
		character_util.set_anim(cur_npc_info.character, { name = 'dead', loop = false })
		character_util.set_emotion(cur_npc_info.character, { name = 'damaged' })

		-- 랜덤 대사 출력
		local cur_talk_num = math.floor(unity_class.random.Range(4, 6))
		speech_bubble_util.show_speech_bubble(
				cur_npc_info.character,{ key = 'demonworld_part1_civilian_'..cur_talk_num })

		wait_for_sec(2)

		music_player_util.play_sfx_one_shot('01_hit_npc_01')

		wait_for_sec(2)

		character_util.spine_set_alpha_fade(cur_npc_info.character, 0, 1)

		wait_for_sec(1)

		character_util.set_active_state(cur_npc_info.character, 'disabled')
	else

		unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
				cur_npc_info.character.Position + vector(0, 0.3, 0))
		unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
				cur_npc_info.character.Position + vector(0, 0.3, 0))

		character_util.set_anim(cur_npc_info.character, { name = 'embarrassed' })
		character_util.set_emotion(cur_npc_info.character, { name = 'damaged' })
		character_util.air_spin(cur_npc_info.character)

		wait_for_sec(1.5)
	end

	self:initialize_npc(cur_npc_info)

end
-- 공격 받아서 죽거나, 화면 밖으로 나가서 제거된 NPC를 완전히 초기화시켜서 다음에 쓸 수 있도록 하는 루틴
function local_class:initialize_npc(cur_npc_info)
	-- Type이 stopped인 경우, Marker 정보 초기화
	if cur_npc_info.move_type == self.npc_move_type.stopped and cur_npc_info.spawn_marker_index > 0 then
		self.stop_npc_spawn_markers[cur_npc_info.spawn_marker_index].is_used = false
	end

	-- NPC Info 초기화
	cur_npc_info.activated = false
	cur_npc_info.ai_state = self.npc_ai_state.idle
	cur_npc_info.damaged = false
	cur_npc_info.out_of_camera = false
	cur_npc_info.waypoints = {}
	cur_npc_info.spawn_marker_index = 0
	cur_npc_info.wait_duration = 0

	-- NPC의 HPBar를 숨김
	message_system:Publish(CS.Oak.HideCharacterHPBarEvent.Create(cur_npc_info.character))

	local cur_npc = cur_npc_info.character
	cur_npc.SpineController:RemoveColor(cur_npc.Name, 0)
	character_util.spine_set_alpha_fade(cur_npc, 1, 0)
	character_util.set_position(cur_npc, vector(999, 0, 999))
	character_util.remove_anim(cur_npc)
	character_util.remove_emotion(cur_npc)
	cur_npc.SpineController:Rotate(0, 0)
	if cur_npc.FieldObjectStatsBehaviour.HP < cur_npc.FieldObjectStatsBehaviour.MaxHP then
		-- 힐로 HP 초기화
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = nil
		heal_info.target = cur_npc
		heal_info.heal = cur_npc.FieldObjectStatsBehaviour.MaxHP
		heal_info.isRevive = true

		command_util.execute_heal(heal_info)
	end
end
--endregion

--region Notoriety Function
function local_class:generic_setting_notoriety_lv()
	-- 악명 레벨에 따라서 경찰 생성
	if self.notoriety_lv ~= 5 then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.spawn_police, self, self.notoriety_lv))
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_erina, self, true))
	end

	-- 악명 레벨이 1 이상인 경우
	if self.notoriety_lv > 0 then
		-- 순찰 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_patrol_police, self))

		-- 환경 변화 전부 적용
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.notoriety_lv_environment_change_with_under_level, self))

		-- 악명 디버프 적용
		for n = 1, self.notoriety_lv do
			for i = 0, user_party.Count - 1 do
				buff_manager:AddBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party[i],
						self.level_up_debuff_name..n, self.level_up_debuff_lvs[n], false, false)
			end
		end

		-- 악명 감소 조건 확인 루틴 실행
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.check_notoriety_declined, self))

		-- Exit 사용 금지 이벤트 Publish
		self:publish_exclusive(true)
		message_system:Publish(CS.Oak.ActivateExitInteractableEvent.Create(false))
	end
end

-- 악명 레벨이 1 이상 되거나 1 미만으로 내려갔을 때 보내는 함수
function local_class:publish_exclusive(is_increase)
	if is_increase then
		message_system:PublishSync(CS.Oak.ExclusiveQuestStartEvent.Create('notoriety_variance', false))

		-- 몬스터 비활성화
		local parent_transform = stage.StageTransform
		local child_count = parent_transform.childCount

		for i = 0, child_count - 1 do
			local cur_child = parent_transform:GetChild(i)
			local character = cur_child:GetComponent(typeof(CS.Oak.Character))

			-- 이미 죽은 몬스터는 무시함
			if character ~= nil and
					lua_helper.type_compare(character.FieldObjectController, CS.Oak.MonsterCharacterController) and
					not character.FieldObjectStatsBehaviour.IsDead then
				character.FieldObjectController.DontFight = true

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.fade_out_and_deactivate, self, character))
			end
		end

		-- 배틀 존에 들어가도 몬스터들이 강제 활성화되지 않도록 설정
		for i = 1, #self.battle_groups do
			self.battle_groups[i].IgnoreZoneEvent = true
		end
	else
		message_system:PublishSync(CS.Oak.ExclusiveQuestEndEvent.Create('notoriety_variance', false))

		-- 몬스터 활성화
		local parent_transform = stage.StageTransform
		local child_count = parent_transform.childCount

		for i = 0, child_count - 1 do
			local cur_child = parent_transform:GetChild(i)
			local character = cur_child:GetComponent(typeof(CS.Oak.Character))

			-- 강제 활성화하면 안 되기 때문에 이미 죽은 몬스터는 무시함
			if character ~= nil and
					lua_helper.type_compare(character.FieldObjectController, CS.Oak.MonsterCharacterController) and
					not character.FieldObjectStatsBehaviour.IsDead then
				character.FieldObjectController.DontFight = false

				self:fade_in_and_activate(character)
			end
		end

		-- 배틀 존에 들어가면 몬스터들이 강제 활성화되도록 설정
		for i = 1, #self.battle_groups do
			self.battle_groups[i].IgnoreZoneEvent = false
		end
	end
end

-- 전투 캐릭터들 페이드 아웃 된 뒤 비활성화 처리
function local_class:fade_out_and_deactivate(character)
	character_util.spine_set_alpha_fade(character, 0, 1)

	wait_for_sec(1)

	character_util.set_active_state(character, 'disabled')
end

-- 전투 캐릭터들 활성화한 뒤 페이드 인 처리
function local_class:fade_in_and_activate(character)
	character_util.set_active_state(character, 'visible')

	character_util.spine_set_alpha_fade(character, 1, 1)
end

-- 악명 증가
function local_class:add_notoriety(end_notoriety, kill_police)
	-- exclusive 이벤트 실행 중일 경우 무시
	if self.is_exclusive_quest_start then
		return
	end

	kill_police = lua_helper.get_or_default(kill_police, false)

	-- Request ID 저장
	self.notoriety_req_id = self.notoriety_req_id + 1
	local cur_req_id = self.notoriety_req_id

	local past_notoriety = self.current_notoriety
	self.current_notoriety = end_notoriety

	-- 악명 값 변경 수치 Publish
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			nil, { self.current_notoriety_num, self.current_notoriety }))

	-- 최초로 악명 값이 오른 경우 악명 UI 활성화하고 악명 감소 상태 체크 코루틴 실행
	if not self.notoriety_ui.activeSelf then
		self.notoriety_ui:SetActive(true)

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.check_notoriety_declined, self))
	end

	-- 악명 감소 상태에서 어떤 방법으로든 악명이 상승한 경우, 상태 해제하고 카운터 초기화
	if self.is_notoriety_declined then
		self.is_notoriety_declined = false
		self.notoriety_declined_counter = 0
	end

	if self.notoriety_lv < 5 and self.current_notoriety >= self.notoriety_lv_values[self.notoriety_lv + 1] and
			not self.is_battle_with_fixed_monster then
		-- 0에서 1로 레벨이 상승한 경우, 악명 감소 상태 체크 루틴 실행, ExitInteractable 사용 불가 이벤트 Publish
		if self.notoriety_lv + 1 == 1 then
			self:publish_exclusive(true)
			message_system:Publish(CS.Oak.ActivateExitInteractableEvent.Create(false))
		end
	end

	-- 증가 연출 진행
	local cur_time = unity_class.time.time
	local start_notoriety = past_notoriety

	local add_duration = self.notoriety_add_duration

	if kill_police then
		add_duration = self.notoriety_add_duration_defeat_police
	end

	-- 살짝 진동하도록 설정
	local ui_transform = self.notoriety_ui.transform:Find('Contents/Button/item/GaugeBar')

	local start_pos = self.gauge_bar_start_pos
	local shake_max_x = 5
	local shake_max_y = 5

	-- 사운드
	local count_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_count_number_01', loop = true, type_priority = 'loop' })

	while not self.is_exit_stage and self.notoriety_req_id == cur_req_id and
			unity_class.time.time - cur_time < add_duration do
		local normalized = (unity_class.time.time - cur_time) / add_duration

		-- UI 변경 (수치는 Int로 표시)
		local cur_bar_value = start_notoriety + (end_notoriety - start_notoriety) * normalized

		self:fill_gauge(cur_bar_value)

		-- UI 진동
		local cur_pos_x = unity_class.random.Range(-shake_max_x, shake_max_x)
		local cur_pos_y = unity_class.random.Range(-shake_max_y, shake_max_y)

		ui_transform.localPosition = start_pos + vector(cur_pos_x, cur_pos_y, 0)

		coroutine.yield(nil)
	end

	ui_transform.localPosition = start_pos

	count_sfx:FadeOut()

	if self.is_exit_stage then
		return
	end

	-- 추가 요청이 없고 정상적으로 완료된 경우, 완료 값 지정
	if self.notoriety_req_id == cur_req_id then
		self:fill_gauge(end_notoriety)
	end

	-- 플레이어가 특정 연출 중인 경우 대기 (리셋 NPC와 상호작용 중인 경우 아래 코드 실행되면 안 됨)
	while not self.is_exit_stage and lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) do
		coroutine.yield(nil)
	end

	-- 악명 값이 특정 이상 올라간 경우, 레벨 상승 (레벨 5 이상은 더 올라갈 수 없으므로 제외)
	-- 예외적으로 일반 전투 중에는 레벨 올라가지 않고 전투 종료되면 레벨 올라감
	if self.notoriety_lv < 5 and self.current_notoriety >= self.notoriety_lv_values[self.notoriety_lv + 1] and
			not self.is_battle_with_fixed_monster then
		coroutine.yield(self:notoriety_lv_up())
	end
end

-- 레벨 올라가는 처리
function local_class:notoriety_lv_up()
	-- 플레이어가 이미 경찰에 걸린 상황에서 레벨이 올라가면 현재 전투 중인 경찰들이 리셋되고
	-- 추적 경찰 프로세스가 꼬이는 문제가 발생하므로 대기
	while not self.is_exit_stage and self.is_detected_by_police do
		coroutine.yield(nil)
	end

	if self.is_exit_stage then
		return
	end

	-- 레벨 증가
	self.notoriety_lv = self.notoriety_lv + 1

	-- 악명 레벨 변경 수치 Publish
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			nil, { self.current_notoriety_lv, self.notoriety_lv }))

	-- 악명 UI 루틴 실행
	coroutine.yield(self:activate_level_up_ui())

	if self.notoriety_lv ~= 5 then
		-- 추적 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.spawn_police, self, self.notoriety_lv))
	else
		-- 에리나 등장 연출
		coroutine.yield(self:appear_erina())
	end

	-- 별 추가
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_star, self, self.notoriety_lv))

	-- 순찰 경찰 생성
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_patrol_police, self))

	if self.notoriety_lv ~= 0 then
		-- 악명 디버프 적용
		for i = 0, user_party.Count - 1 do
			buff_manager:AddBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party[i],
					self.level_up_debuff_name..self.notoriety_lv, self.level_up_debuff_lvs[self.notoriety_lv], true, false)
		end
	end

	-- 악명 레벨에 따른 환경 변화
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.notoriety_lv_environment_change, self, nil))

	if self.notoriety_lv == 5 then
		screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

		party_util.reset_controllers()

		-- 추적 경찰 대신 에리나 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_erina, self, true))
	end
end

-- 악명 감소 체크해서 감소 상태가 되면 악명을 줄임
function local_class:check_notoriety_declined()
	local local_timer = 0

	-- 악명 수치가 0이 될 경우 반복 종료
	while not self.is_exit_stage and self.current_notoriety > 0 do
		-- 모든 경찰들이 시야에 없는지 확인
		local is_condition_ok = true

		if self.notoriety_lv > 0 then
			local cur_police_table = self.follow_police_table

			for i = 1, self.follow_police_nums[self.notoriety_lv] do
				-- 순찰 상태가 아닌 경찰이 있을 경우 조건 불만족으로 판단
				if self:is_pos_in_camera(cur_police_table[i].character.Position) or
						cur_police_table[i].state ~= self.police_state.search_player then
					is_condition_ok = false

					break
				end
			end
		end

		if is_condition_ok then
			for i = 1, #self.patrol_police_table do
				-- 순찰 상태가 아닌 경찰이 있을 경우 조건 불만족으로 판단 (들켰거나 스폰 대기중)
				if self.patrol_police_table[i].state ~= self.police_state.search_player then
					is_condition_ok = false

					break
				end
			end
		end

		-- 플레이어가 ScreenplayState이면 조건 불만족으로 판단
		if lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
				CS.Oak.CharacterControllerScreenplayState) then
			is_condition_ok = false
		end

		-- 플레이어가 전투 중이면 조건 불만족으로 판단
		if stage.BattleManager:GetBattleFor(user_party.Leader) ~= nil then
			is_condition_ok = false
		end

		-- 플레이어가 게임오버 상태면 조건 불만족으로 판단
		if self.player_is_gameover then
			is_condition_ok = false
		end

		-- 조건 만족 시
		if is_condition_ok then
			if not self.is_notoriety_declined then
				self.notoriety_declined_counter = self.notoriety_declined_counter + unity_class.time.deltaTime

				-- 레벨 0, 1일 때는 감소 대기 시간 증가
				local cur_declined_delay = self.notoriety_declined_delay

				if self.notoriety_lv <= 1 then
					cur_declined_delay = cur_declined_delay * 2
				end

				-- 레벨 5일 때는 감소하지 않음
				if self.notoriety_lv ~= 5 and self.notoriety_declined_counter >= cur_declined_delay then
					self.is_notoriety_declined = true

					-- UI 느리게 깜박여서 안전 상태라는 것 알려주는 루틴 실행
					coroutine_manager:StartCoroutine(
							stage.StageGameObject, util.cs_generator(self.fade_notoriety_ui, self))
				end
			else
				local_timer = local_timer + unity_class.time.deltaTime

				-- 일정 시간마다 1씩 감소
				if local_timer >= self.notoriety_declined_sec[self.notoriety_lv + 1] then
					local_timer = 0

					-- 악명 감소
					local decline_notoriety_val = self.current_notoriety - 1

					if decline_notoriety_val < 0 then
						decline_notoriety_val = 0
					end

					self:decline_notoriety(decline_notoriety_val)
				end
			end
		-- 조건 불만족 시 (경찰 하나라도 시야에 들어온 경우 상태 초기화)
		else
			if self.is_notoriety_declined then
				self.is_notoriety_declined = false
			end

			self.notoriety_declined_counter = 0
		end

		coroutine.yield(nil)
	end
end

-- 악명 레벨 업 UI 생성 후 제거
function local_class:activate_level_up_ui()
	-- 플레이어가 특정 연출 중인 경우 대기
	while not self.is_exit_stage and lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) do
		coroutine.yield(nil)
	end

	-- 게임오버 된 상황이면 대기
	while self.player_is_gameover do
		coroutine.yield(nil)
	end

	if self.is_exit_stage then
		return
	end

	if self.is_level_up_ui_event then
		return
	else
		self.is_level_up_ui_event = true
	end

	-- 사운드
	if self.notoriety_lv == 1 then
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })

		coroutine.yield(nil)

		music_player_util.play_stage_music(
				{name = 'ondemand/v2_15_demonworld/audio:bgm_police_01', state = 'field', mix = 2})
	elseif self.notoriety_lv == 3 then
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })

		coroutine.yield(nil)

		music_player_util.play_stage_music(
				{name = 'ondemand/v2_15_demonworld/audio:bgm_police_02', state = 'field', mix = 2})
	end

	if self.notoriety_lv < 3 then
		music_player_util.play_sfx_one_shot('01_dw_police_01')
	else
		music_player_util.play_sfx_one_shot('01_dw_police_02')
	end

	-- 악명 레벨 업 UI 활성화
	self.level_up_ui:SetActive(true)

	self.level_up_ui.transform:Find('Warning/Debuff'):GetComponent(
			typeof(CS.UILabel)).text = game_string:GetString(self.level_up_debuff_name..self.notoriety_lv)
	self.level_up_ui.transform:Find('Warning/Title'):GetComponent(
			typeof(CS.UILabel)).text = game_string:GetString('demonworld_part1_notoriety_title_'..self.notoriety_lv)

	local animator = self.level_up_ui.transform:Find('Warning'):GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('open_'..self.notoriety_lv)

	while animator:GetCurrentAnimatorStateInfo(0).normalizedTime < 1 do
		coroutine.yield()
	end

	if self.is_exit_stage then
		return
	end

	camera_util.shake(0.4, 0.1)

	self.level_up_ui.transform:Find('fx_star_0'..self.notoriety_lv).gameObject:SetActive(true)

	-- 잠시 대기
	wait_for_sec(1)

	animator:Play('idle_'..self.notoriety_lv)

	wait_for_sec(1)

	self.level_up_ui.transform:Find('fx_star_0'..self.notoriety_lv).gameObject:SetActive(false)

	animator:Play('close_'..self.notoriety_lv)

	-- 애니메이션이 끝날 때 까지 대기
	while animator:GetCurrentAnimatorStateInfo(0).normalizedTime < 1 do
		coroutine.yield()
	end

	if self.is_exit_stage then
		return
	end

	self.is_level_up_ui_event = false

	self.level_up_ui:SetActive(false)
end

-- 몬스터와 전투 중인 상태라서 전투가 끝날 때까지 대기한 뒤, 전투가 종료되면 악명 점수를 체크해서 현재 플레이어의 레벨을 올려줌
function local_class:wait_for_check_notoriety_lv()
	while not self.is_exit_stage and self.is_battle_with_fixed_monster do
		coroutine.yield(nil)
	end

	if not self.is_exit_stage and not self.is_battle_with_fixed_monster then
		if self.notoriety_lv < 5 and self.current_notoriety >= self.notoriety_lv_values[self.notoriety_lv + 1] then
			coroutine.yield(self:notoriety_lv_up())
		end
	end
end

-- 악명 감소
function local_class:decline_notoriety(end_notoriety)
	self.current_notoriety = end_notoriety

	-- 악명 값 변경 수치 Publish
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			nil, { self.current_notoriety_num, self.current_notoriety }))

	-- 악명 UI 설정
	self:fill_gauge(self.current_notoriety)

	-- 악명 값이 0이 된 경우, 악명 UI 비활성화,
	if self.notoriety_ui.activeSelf and self.current_notoriety == 0 then
		self.notoriety_ui:SetActive(false)
	end

	-- 악명 값이 특정 이상 내려간 경우, 레벨 하락 (레벨 0 이하는 더 내려갈 수 없으므로 제외)
	if self.notoriety_lv > 0 and self.current_notoriety < self.notoriety_lv_values[self.notoriety_lv] then
		-- 레벨 감소
		local past_notoriety_lv = self.notoriety_lv
		self.notoriety_lv = self.notoriety_lv - 1

		-- 악명 레벨이 0이 된 경우, ExitInteractable 활성화
		if self.notoriety_lv == 0 then
			self:publish_exclusive(false)
			message_system:Publish(CS.Oak.ActivateExitInteractableEvent.Create(true))
		end

		-- 악명 레벨 변경 수치 Publish
		message_system:Publish(CS.Oak.CustomStageEvent.Create(
				nil, { self.current_notoriety_lv, self.notoriety_lv }))

		-- 기존 경찰 초기화
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.reset_follow_police, self, self.notoriety_lv, true))
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.reset_patrol_police, self, past_notoriety_lv, true))

		-- 감소된 레벨에 맞춰서 추적 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.spawn_police, self, self.notoriety_lv, true))

		-- 별 제거
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.remove_star, self, past_notoriety_lv))

		-- 악명 디버프 제거
		for i = 0, user_party.Count - 1 do
			buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party[i],
					self.level_up_debuff_name..past_notoriety_lv)
		end

		-- 악명 레벨에 따른 환경 변화
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.notoriety_lv_environment_change, self, past_notoriety_lv))
	end
end

-- 악명 감소 중 상태일 때 UI 느리게 깜박임
function local_class:fade_notoriety_ui()
	local timer = 0
	local fade_duration = 1
	local fade_val = 0.5
	local is_fade_out = true

	local widget = self.notoriety_ui.transform:Find('Contents/Button/item/GaugeBar'):GetComponent(typeof(CS.UIWidget))

	while not self.is_exit_stage and self.is_notoriety_declined do
		timer = timer + unity_class.time.deltaTime

		if is_fade_out then
			widget.alpha = 1 - (fade_val * (timer / fade_duration))
		else
			widget.alpha = fade_val + fade_val * (timer / fade_duration)
		end

		if timer >= fade_duration then
			timer = 0

			if is_fade_out then
				is_fade_out = false
			else
				is_fade_out = true
			end
		end

		coroutine.yield(nil)
	end

	if not self.is_exit_stage then
		widget.alpha = 1
	end
end

-- 현재 현상 수배 점수를 받아서 게이지와 라벨을 채워줌
function local_class:fill_gauge(val)
	local current_val = val

	for i = 1, self.notoriety_lv_max do
		if current_val < 0 then
			break
		end

		local cur_gauge_max_value = self.notoriety_lv_gauge_maxes[i]

		self.notoriety_ui_gauge_bar_list[i - 1].fillAmount = math.min(current_val / cur_gauge_max_value, 1)

		current_val = current_val - cur_gauge_max_value
	end

	self.notoriety_ui_gauge_bar_label.text = tostring(math.floor(val))
end

-- 추적 경찰 리셋
function local_class:reset_follow_police(lv, fade)
	-- 추적하던 경찰들 비활성화
	for i = 1, #self.follow_police_table do
		if lv == 0 or self.follow_police_nums[lv] < i then
			self.follow_police_table[i].character.FieldObjectController = CS.Oak.NPCCharacterController()
			character_util.stop(self.follow_police_table[i].character)

			character_util.spine_set_alpha_fade(self.follow_police_table[i].character, 0, 1)

			character_util.remove_anim(self.follow_police_table[i].character)
			character_util.remove_emotion(self.follow_police_table[i].character)

			-- AttackRange 비활성화
			if self.follow_police_table[i].attack_range ~= nil then
				self.follow_police_table[i].attack_range:Hide()
			end

			self.follow_police_table[i].state = self.police_state.idle
		end
	end

	if fade then
		wait_for_sec(1)
	end

	for i = 1, #self.follow_police_table do
		if lv == 0 or self.follow_police_nums[lv] < i then
			if lv ~= 5 then
				character_util.set_position(self.follow_police_table[i].character, vector(999, 0, 999))
			else
				character_util.set_active_state(self.follow_police_table[i].character, 'disabled')
			end

			character_util.spine_set_alpha_fade(self.follow_police_table[i].character, 1, 0)

			-- 히트박스 복구
			self.follow_police_table[i].Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

			-- 에리나는 버프 제거
			if lv == 5 then
				buff_manager:RemoveBuff(self.follow_police_table[i], CS.Oak.EquipmentSlot.None,
						self.follow_police_table[i], "speed_down_persistent")
			end
		end
	end
end

-- 순찰 경찰 제거
function local_class:reset_patrol_police(lv, fade)
	local remove_start = 1

	for i = 1, lv - 1 do
		remove_start = remove_start + self.patrol_police_nums[i]
	end

	local remove_end = remove_start + self.patrol_police_nums[lv] - 1

	-- 에러 방지
	if #self.patrol_police_table < remove_end then
		CS.UnityEngine.Debug.LogError('현재 활성화된 순찰 경찰의 수가 악명 레벨보다 적어서 순찰 경찰을 제거할 수 없습니다.')

		return
	end

	for i = remove_start, remove_end do
		character_util.spine_set_alpha_fade(self.patrol_police_table[i].character, 0, 1)

		-- 범위 표시 제거
		if self.patrol_police_table[i].attack_range ~= nil then
			self.patrol_police_table[i].attack_range:Hide()
		end

		self.current_patrol_police_num = self.current_patrol_police_num - 1
	end

	if fade then
		wait_for_sec(1)
	end

	for i = remove_start, remove_end do
		self:initialize_monster(self.patrol_police_table[i].character)
	end

	-- 테이블에서 제거
	for n = remove_start, remove_end do
		table.remove(self.patrol_police_table, #self.patrol_police_table)
	end
end

-- 별 UI에 추가하는 연출
function local_class:add_star(lv)
	self.notoriety_ui.transform:Find('Contents/Button/item/Title'):GetComponent(typeof(CS.UILabel)).text =
		game_string:GetString('demonworld_part1_notoriety_title_'..lv)

	-- 레벨보다 낮은 별 중에 켜지지 않은 것이 있으면 같이 켜줌
	local cur_star_list = create_generic_list(CS.UISprite)

	for i = 1, lv do
		local cur_star = self.notoriety_ui_star_list[i - 1]

		if cur_star.alpha ~= 1 then
			cur_star_list:Add(cur_star)
		end
	end

	music_player_util.play_sfx_one_shot('01_get_star_01')

	for n = 1, 4 do
		local cur_time = unity_class.time.time

		while not self.is_exit_stage and unity_class.time.time - cur_time < self.star_sprite_fade_duration do
			local normalized = (unity_class.time.time - cur_time) / self.star_sprite_fade_duration

			for i = 0, cur_star_list.Count - 1 do
				cur_star_list[i].alpha = normalized
			end

			coroutine.yield(nil)
		end

		if self.is_exit_stage then
			return
		end

		if n ~= 3 then
			cur_time = unity_class.time.time

			while not self.is_exit_stage and unity_class.time.time - cur_time < self.star_sprite_fade_duration do
				local normalized = (unity_class.time.time - cur_time) / self.star_sprite_fade_duration

				for i = 0, cur_star_list.Count - 1 do
					cur_star_list[i].alpha = 1 - normalized
				end

				coroutine.yield(nil)
			end
		end
	end

	if not self.is_exit_stage then
		for i = 0, cur_star_list.Count - 1 do
			cur_star_list[i].alpha = 1
		end
	end
end

-- 별 UI에서 제거하는 연출
function local_class:remove_star(lv)
	if lv <= 0 then
		return
	end

	self.notoriety_ui.transform:Find('Contents/Button/item/Title'):GetComponent(typeof(CS.UILabel)).text =
		game_string:GetString('demonworld_part1_notoriety_title_'..lv)

	local cur_star = self.notoriety_ui_star_list[lv - 1]
	local cur_time = unity_class.time.time

	-- 도중에 악명 레벨이 다시 상승한 경우 연출 중단
	while not self.is_exit_stage and unity_class.time.time - cur_time < self.star_sprite_fade_out_duration do
		-- 악명 레벨 다시 상승한 경우 연출 중단
		if lv <= self.notoriety_lv then
			break
		end

		local normalized = (unity_class.time.time - cur_time) / self.star_sprite_fade_out_duration

		cur_star.alpha = 1 - normalized

		coroutine.yield(nil)
	end

	if not self.is_exit_stage then
		cur_star.alpha = 0
	end
end

-- 악명 레벨 증가에 따른 환경 변화
function local_class:notoriety_lv_environment_change(past_level)
	if past_level == nil then
		if self.notoriety_lv == 2 then
			if self.siren_marker_num > 0 then
				for i = 1, self.siren_marker_num do
					self.siren_effect_list:Add(
						unity_object_pool.GetOrCreate(self.siren_effect_preset):Instantiate(self.siren_marker_positions[i]))
				end
			end

			self.siren_sfx = music_player_util.play_sfx(
					{ sfx_name = '01_siren_loop_05', loop = true, type_priority = 'loop' })
		elseif self.notoriety_lv == 3 then
			field:Tint(self.notoriety_lv_3_tint_key, unity_color({ 0.7, 0.5, 0.5, 0.5 }), 1)
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_start'}))
		elseif self.notoriety_lv == 4 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.notoriety_lv_4_tint, self))
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_start'}))
		elseif self.notoriety_lv == 5 then
			for i = 0, self.fire_effect_obj_list.Count - 1 do
				self.fire_effect_obj_list[i].Position = field:GetMarker(
						self.fire_effect_obj_marker_name..(i + 1)).position
			end
		end
	else
		if past_level == 1 then
			music_player_util.play_stage_music({ state = 'muted', mix = 2 })

			coroutine.yield(nil)

			music_player_util.set_stage_music_clip_async(
					{name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_main', state = 'field'})

			music_player_util.play_stage_music({ state = 'field', mix = 2 })
		elseif past_level == 2 then
			for i = 0, self.siren_effect_list.Count - 1 do
				if self.siren_effect_list[i] ~= nil then
					self.siren_effect_list[i]:Dispose()
				end
			end
			self.siren_effect_list:Clear()

			if self.siren_sfx ~= nil then
				self.siren_sfx:FadeOut(1)
			end
		elseif past_level == 3 then
			field:RemoveTint(self.notoriety_lv_3_tint_key, 1)
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_stop'}))

			music_player_util.play_stage_music({ state = 'muted', mix = 2 })

			coroutine.yield(nil)

			music_player_util.play_stage_music(
					{name = 'ondemand/v2_15_demonworld/audio:bgm_police_01', state = 'field', mix = 2})
		-- 반복문에서 알아서 제거하게 되어 있음
		elseif past_level == 4 then
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_stop'}))
		elseif past_level == 5 then
			for i = 0, self.fire_effect_obj_list.Count - 1 do
				self.fire_effect_obj_list[i].Position = vector(-200, 0, -200)
			end
		end
	end
end

-- 악명 레벨 증가에 따른 환경 변화 현재 악명 레벨의 이하 것까지 한꺼번에 적용, 저장 시스템이 제거되서 사실상 안 쓰는 코루틴
function local_class:notoriety_lv_environment_change_with_under_level()
	if self.notoriety_lv >= 2 then
		if self.siren_marker_num > 0 then
			for i = 1, self.siren_marker_num do
				self.siren_effect_list:Add(
					unity_object_pool.GetOrCreate(self.siren_effect_preset):Instantiate(self.siren_marker_positions[i]))
			end
		end

		self.siren_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_siren_loop_05', loop = true, type_priority = 'loop' })
	end

	if self.notoriety_lv >= 3 then
		field:Tint(self.notoriety_lv_3_tint_key, unity_color({ 0.7, 0.5, 0.5, 0.5 }), 1)
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_start'}))
	end

	if self.notoriety_lv >= 4 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.notoriety_lv_4_tint, self))

		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_start'}))
	end
end

-- 악명 레벨 4단계 틴트 펄스
function local_class:notoriety_lv_4_tint()
	local tint_duration = 1
	local timer = tint_duration
	local is_tint = false

	while not self.is_exit_stage and self.notoriety_lv >= 4 do
		if self.pause_lv_4_tint then
			if is_tint then
				is_tint = false
				timer = 0

				field:RemoveTint(self.notoriety_lv_4_tint_key, 0.5)
			end
		else
			timer = timer + unity_class.time.deltaTime

			if timer >= tint_duration then
				timer = 0

				if is_tint then
					is_tint = false

					field:RemoveTint(self.notoriety_lv_4_tint_key, tint_duration)
				else
					is_tint = true

					field:Tint(self.notoriety_lv_4_tint_key, unity_color({ 1, 0, 0, 0.8 }), tint_duration)
				end
			end
		end

		coroutine.yield(nil)
	end

	if not self.is_exit_stage and is_tint then
		field:RemoveTint(self.notoriety_lv_4_tint_key, 0)
	end
end

-- 악명 레벨 5가 되면 에리나 등장 연출
function local_class:appear_erina()
	-- 플레이어가 특정 연출 중인 경우 대기
	while not self.is_exit_stage and lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) do
		coroutine.yield(nil)
	end

	-- 플레이어가 게임 오버 상태인 경우 대기
	while self.player_is_gameover do
		coroutine.yield(nil)
	end

	-- 레벨 확인해서 미달일 경우 넘어감 (악명 제거 NPC에게 말 걸어서 악명 제거 후 아래 루틴이 호출되는 문제 방지)
	if not self.is_exit_stage and self.notoriety_lv < 5 then
		return
	end

	-- 플레이어가 전투중일 때는 진행하지 않도록 함
	if self.player_is_battle then
		while self.player_is_battle do
			coroutine.yield(nil)
		end
	end

	field_ui_manager:Hide()

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 헬기와 드론 일시 비활성화
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_pasue' }))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_stop' }))

	-- 경찰 제거
	self:remove_follow_police()

	-- NPC 일시정지
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.hide_npc_alpha_fade, self))

	party_util.stop_and_disable_control()

	-- 틴트 제거
	self.pause_lv_4_tint = true

	field:RemoveTint(self.notoriety_lv_3_tint_key, 0)

	-- 사이렌 비활성화
	for i = 0, self.siren_effect_list.Count - 1 do
		self.siren_effect_list[i].gameObject:SetActive(false)
	end

	local erina_spawn_marker_position = self.erina_spawn_marker.position

	camera_util.move_async(erina_spawn_marker_position + vector(0, 0, 1), 0)

	self.erina.SpineController.AlwaysUpdateSpine = true
	character_util.stop_shake(self.erina)
	character_util.set_active_state(self.erina, 'enabled')
	character_util.spine_set_alpha_fade(self.erina, 1, 0)
	character_util.set_anim(self.erina, { name = 'walk4legs', loop = false })

	wait_for_sec(0.5)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_pasue' }))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_stop' }))

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	wait_for_sec(0.5)

	-- 화면 틴트
	local tint_key = 'demonworld_appear_erina'
	field:Tint(tint_key, unity_color({0, 0, 0, 1}), 0.3)

	unity_object_pool.GetOrCreate(self.erina_spawn_effect_preset):Instantiate(erina_spawn_marker_position)

	character_util.set_position(self.erina, erina_spawn_marker_position + vector(0, 10, 0), true)
	character_util.set_direction(self.erina, 'down')
	character_util.set_emotion(self.erina, { name = 'sleep_deep' })

	local cur_time = unity_class.time.time
	local fall_duration = 0.2
	local start_pos = self.erina.Position

	local zoom_time = 0.35
	local freefall = CS.CalculatorFreeFall(fall_duration, self.erina.Position.y, 0)

	camera_util.resize_to(2, zoom_time)

	while not self.is_exit_stage and unity_class.time.time - cur_time < fall_duration do
		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		if start_pos.y + dist_y > 0 then
			character_util.set_position(self.erina, start_pos + vector(0, dist_y, 0), true)
		else
			character_util.set_position(self.erina,  vector(start_pos.x, 0, start_pos.z))
		end

		coroutine.yield(nil)
	end

	if self.is_exit_stage then
		return
	end

	music_player_util.play_sfx_one_shot('02_stomp_01')
	music_player_util.play_sfx_one_shot('02_ficklelady_stomp_01')

	self.erina.SpineController.AlwaysUpdateSpine = false

	field:RemoveTint(tint_key, 2)

	camera_util.shake(0.2, 0.3)

	character_util.set_position(self.erina, vector(start_pos.x, 0, start_pos.z))

	wait_for_sec(1.5)

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.remove_anim(self.erina)
	character_util.remove_emotion(self.erina)

	camera_util.resize_to_default(1)

	wait_for_sec(1.5)

	speech_bubble_util.show_speech_bubble_async(self.erina, { key = 'demonworld_part1_police_3', skip = true })

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- NPC 복구
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_npc_alpha_fade, self))

	-- 틴트 복구
	self.pause_lv_4_tint = false

	field:Tint(self.notoriety_lv_3_tint_key, unity_color({ 0.7, 0.5, 0.5, 0.5 }), 0)

	-- 사이렌 활성화
	for i = 0, self.siren_effect_list.Count - 1 do
		self.siren_effect_list[i].gameObject:SetActive(true)
	end

	-- 카메라 복구
	stage_camera:SetTarget(user_party.Leader)

	-- 전투할 에리나는 위치 변경
	character_util.set_position(self.erina, vector(999, 0, 999))

	wait_for_sec(0.5)

	-- 헬기와 드론 활성화
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_resume' }))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_start' }))

	field_ui_manager:Show()
end

-- 경찰 생성
function local_class:spawn_police(lv, immeditate)
	immeditate = lua_helper.get_or_default(immeditate, false)

	if lv <= 0 then
		return
	end

	-- 레벨에 따라 대기
	if not immeditate and self.police_respawn_delays ~= nil then
		wait_for_sec(self.police_respawn_delays[lv])
	elseif self.police_respawn_delays == nil then
		return
	end

	-- 레벨이 변경된 경우 스폰 루틴 중단
	if lv ~= self.notoriety_lv then
		return
	end

	-- 스폰 마커 초기화
	for i = 1, #self.police_spawn_markers do
		self.police_spawn_markers[i].is_used = false
	end

	-- 정해진 개수만큼만 스폰
	for n = 1, self.follow_police_nums[lv] do
		-- 해당 경찰의 상태가 idle이 아니면 이미 스폰된 것이니 넘어감
		if self.follow_police_table[n].state == self.police_state.idle then
			-- 카메라에 보이지 않는 것 체크를 위해 스테이지 카메라의 파라미터 받아옴
			local camera_pos = stage_camera.LookAtPosition

			-- 먼저 카메라와 가장 가까우면서 화면에 보이지 않는 NPC 생성 마커를 찾는다
			local shortest_dist = 9999
			local selected_marker = nil
			local marker_index = 0

			for i = 1, #self.police_spawn_markers do
				local cur_marker = self.police_spawn_markers[i].marker

				-- 카메라에 보이거나 이미 사용 중인 마커면 넘어감
				if not self:is_pos_in_camera_for_police(cur_marker.position) and
						not self.police_spawn_markers[i].is_used then
					-- 마커와 카메라 거리 측정 후 이전 최단 거리와 비교
					local cur_dist = math.abs((camera_pos - cur_marker.position).magnitude)

					-- 카메라에 보이지 않으면서 카메라와 최단 거리의 마커에 경찰 생성
					if shortest_dist > cur_dist then
						selected_marker = cur_marker
						shortest_dist = cur_dist
						marker_index = i
					end
				end
			end

			-- 선택된 마커 값이 nil이면 넘어간다
			if selected_marker ~= nil then
				local cur_police_info = self.follow_police_table[n]

				cur_police_info.character.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
				character_util.set_active_state(cur_police_info.character, 'enabled')
				character_util.set_position(cur_police_info.character, selected_marker.position)
				character_util.set_direction(cur_police_info.character, selected_marker.direction)

				self.police_spawn_markers[marker_index].is_used = true
			end
		end

		-- 작동 시작
		local cur_police_info = self.follow_police_table[n]

		cur_police_info.state = self.police_state.search_player

		if cur_police_info.attack_range == nil then
			cur_police_info.attack_range = CS.AttackRange.CreateArc(
					cur_police_info.character.Position, self.police_sight_distance, self.police_sight_angle)
			cur_police_info.attack_range:Show(0)
		else
			cur_police_info.attack_range:Show(0)
		end

		local direction = direction_util.to_vector3(cur_police_info.character.Direction)

		attack_range_util.setup_by_direction(cur_police_info.attack_range, cur_police_info.character.Position, direction, 0)

		-- 길 찾을 때 끼지 않게 Hitbox 변경
		cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(0.4, 0.75, 0.4))

		-- 플레이어 쫓아오는 State로 변경
		cur_police_info.character.FieldObjectController = CS.Oak.FollowEventCharacterController.Create(
				cur_police_info.character, self.police_crash_event_name, 'player')

		character_util.set_anim(cur_police_info.character, { name = 'walk' })
	end

	-- 플레이어가 발각되었는지 확인하는 루틴 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_police_find_player, self))
end

-- 특정 지점 순회하며 순찰하는 경찰 생성
function local_class:spawn_patrol_police()
	if self.notoriety_lv <= 0 then
		return
	end

	if self.patrol_police_respawn_delays ~= nil then
		wait_for_sec(self.patrol_police_respawn_delays[self.notoriety_lv])
	else
		return
	end

	-- 레벨에 따라 순찰 Police 생성
	for n = 1, self.notoriety_lv do
		for i = 1, self.patrol_police_nums[n] do
			-- 이미 테이블에 있을 경우 넘어감
			local cur_patrol_police_character = get_character(self.patrol_police_names[n]..i)

			local is_already_spawn = false
			local cur_patrol_police
			local cur_patrol_police_index = -1

			for j = 1, #self.patrol_police_table do
				if lua_helper.reference_equals(self.patrol_police_table[j].character, cur_patrol_police_character) then
					is_already_spawn = true
					cur_patrol_police = self.patrol_police_table[j]
					cur_patrol_police_index = j

					break
				end
			end

			-- Idle 상태가 아닐 경우 이미 작동 중인 것이므로 무시하고 넘어감
			if cur_patrol_police == nil or cur_patrol_police.state == self.police_state.idle then
				-- 테이블에 없을 경우, 직접 만듬
				if cur_patrol_police == nil then
					cur_patrol_police = {
						character = cur_patrol_police_character,
						state = self.police_state.search_player,
						attack_range = nil
					}

					cur_patrol_police_index = self.current_patrol_police_num + 1
				else
					cur_patrol_police.state = self.police_state.search_player
				end

				-- 마커 리스트 중 화면에 안 보이는 곳에서 생성
				-- 모두 화면에 보일 리는 없겠지만 만약 그럴 경우는 마커 설정이 잘못된 것이므로 생성 취소하고 에러 메시지 출력
				local complete_spawn = false
				local cur_marker_table = self.patrol_police_spawn_markers[cur_patrol_police_index]

				for j = 1, cur_marker_table.marker_num do
					local cur_marker = cur_marker_table.markers[j]

					if not self:is_pos_in_camera_for_police(cur_marker.position) then
						complete_spawn = true

						character_util.set_position(cur_patrol_police.character, cur_marker.position)
						character_util.set_direction(cur_patrol_police.character, cur_marker.direction)

						-- NPC가 경로를 이동하도록 설정
						local waypoint_list = create_generic_list(unity_class.vector3)
						local index = j

						for k = 1, cur_marker_table.marker_num do
							if index == cur_marker_table.marker_num then
								index = 1
							else
								index = index + 1
							end

							waypoint_list:Add(cur_marker_table.markers[index].position)
						end

						-- EtherealCrash로 설정
						cur_patrol_police.character.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

						character_util.set_anim(cur_patrol_police.character, { name = 'walk' })
						character_util.move_waypoint(cur_patrol_police.character, waypoint_list,
								cur_patrol_police.character.CharacterStatsBehaviour.WalkSpeed, false,
								'loop', 'floor', CS.Oak.Direction.Down)

						if cur_patrol_police.attack_range == nil then
							cur_patrol_police.attack_range = CS.AttackRange.CreateArc(
									cur_patrol_police.character.Position, self.police_sight_distance, self.police_sight_angle)
							cur_patrol_police.attack_range:Show(0)
						else
							cur_patrol_police.attack_range:Show(0)
						end

						local direction = direction_util.to_vector3(cur_patrol_police.character.Direction)

						attack_range_util.setup_by_direction(cur_patrol_police.attack_range,
								cur_patrol_police.character.Position, direction, 0)

						break
					end
				end

				if complete_spawn and not is_already_spawn then
					self.current_patrol_police_num = self.current_patrol_police_num + 1

					table.insert(self.patrol_police_table, cur_patrol_police)
				end
			end
		end
	end

	-- 스폰 마커 초기화
	for i = 1, #self.police_spawn_markers do
		self.police_spawn_markers[i].is_used = false
	end
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴 (경찰은 AttackRange가 있어서 더 조건 강화해야 함)
function local_class:is_pos_in_camera_for_police(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	if math.abs(camera_pos.x - pos.x) > cam_half_width + 4 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 3 then
		return false
	end

	return true
end

-- 에리나 생성
function local_class:spawn_erina(initialize)
	-- 기존 경찰들 비활성화
	for i = 1, #self.follow_police_table - 1 do
		self.follow_police_table[i].state = self.police_state.idle

		character_util.set_active_state(self.follow_police_table[i].character, 'disabled')
	end

	local cur_police_info = self.follow_police_table[3]
	local selected_marker = self.erina_spawn_marker

	-- 에리나 필드에 스폰 후 설정
	cur_police_info.state = self.police_state.search_player

	character_util.set_active_state(cur_police_info.character, 'enabled')

	if initialize then
		character_util.set_position(cur_police_info.character, selected_marker.position)
	end

	character_util.set_direction(cur_police_info.character, selected_marker.direction)
	character_util.set_anim(cur_police_info.character, { name = 'run' })
	character_util.set_emotion(cur_police_info.character, { name = 'mad' })

	if cur_police_info.character.attack_range == nil then
		cur_police_info.attack_range = CS.AttackRange.CreateArc(
				cur_police_info.character.Position, self.police_sight_distance, self.police_sight_angle)
		cur_police_info.attack_range:Show(0)
	else
		cur_police_info.attack_range:Show(0)
	end

	local direction = direction_util.to_vector3(cur_police_info.character.Direction)

	attack_range_util.setup_by_direction(cur_police_info.attack_range,
			cur_police_info.character.Position, direction, 0)

	-- 길 찾을 때 끼지 않게 Hitbox 변경
	cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(0.4, 0.75, 0.4))

	cur_police_info.character.FieldObjectController = CS.Oak.FollowEventCharacterController.Create(
			cur_police_info.character, self.police_crash_event_name, 'player')

	-- 이동 속도 증가
	buff_manager:AddBuff(cur_police_info.character, CS.Oak.EquipmentSlot.None, cur_police_info.character,
			"speed_down_persistent", -50, false, false)

	-- 플레이어가 발각되었는지 확인하는 루틴 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_police_find_player, self))
end

-- 레벨에 따른 Police Table 리턴
function local_class:get_police_table(lv)
	return self.police_tables[lv]
end

-- 경찰들이 플레이어 찾았는지 확인하고 전투 시작하는 루틴
function local_class:check_police_find_player()
	-- 파라미터에 따라 Police 설정
	local find_police
	local is_wait_for_other_event = false

	-- 루틴 중도 캔슬 플래그
	local cancel_routine = false
	local loop_out = false

	self.current_crashed_police = nil

	-- 추적 중인 경찰만 작동한다
	while not self.is_exit_stage do
		-- 중복 발생 플래그가 on거나 플레이어 컨트롤이 빼앗긴 경우, 전투 중인 경우, 경찰 이동 중단된 경우는 넘어감
		if not self.is_detected_by_police and not self.pause_police and not
			lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
				CS.Oak.CharacterControllerScreenplayState) and
				is_unity_null(stage.BattleManager:GetBattleFor(user_party)) then
			-- ScreenPlayState 대기 끝나면 다시 이동 시작
			if is_wait_for_other_event then
				is_wait_for_other_event = false

				for i = 1, #self.follow_police_table do
					character_util.set_anim(self.follow_police_table[i].character, { name = 'walk' })

					self.follow_police_table[i].character:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			local state_changed_police_num = 0

			for i = 1, #self.follow_police_table do
				-- state가 변경된 경우, 진행 중단
				if self.follow_police_table[i].state ~= self.police_state.search_player then
					state_changed_police_num = state_changed_police_num + 1
				else
					local direction = direction_util.to_vector3(self.follow_police_table[i].character.Direction)

					attack_range_util.setup_by_direction(self.follow_police_table[i].attack_range,
							self.follow_police_table[i].character.Position, direction, 0)

					if self:is_in_sight(self.follow_police_table[i].character, user_party.Leader,
							self.police_sight_distance, self.police_sight_angle)
							or lua_helper.reference_equals(self.follow_police_table[i].character,
							self.current_crashed_police) then
						loop_out = true
						find_police = self.follow_police_table[i].character

						break
					end
				end
			end

			if state_changed_police_num == #self.follow_police_table then
				loop_out = true
				cancel_routine = true
			end
		-- ScreenPlayState 상태거나 경찰 이동 중단된 경우는 대기함
		elseif not is_wait_for_other_event and (lua_helper.type_compare(
				user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) or
				self.pause_police) then
			is_wait_for_other_event = true

			for i = 1, #self.follow_police_table do
				character_util.stop(self.follow_police_table[i].character)
				character_util.set_anim(self.follow_police_table[i].character, { name = 'idle' })
			end
		end

		if loop_out then
			break
		end

		coroutine.yield(nil)
	end

	-- 경찰 리셋이나 스테이지 종료로 인하여 루틴 캔슬된 경우 실행 중단
	if cancel_routine or self.is_exit_stage then
		return
	end

	if find_police ~= nil then
		coroutine.yield(self:detected_by_police(find_police))
	end
end

-- 순찰 경찰들이 플레이어 찾았는지 확인하고 전투 시작하는 루틴
function local_class:check_patrol_police_find_player()
	while true do
		local find_police = nil

		for i = 1, #self.patrol_police_table do
			-- Search Player 상태인 경우에만 확인
			if self.patrol_police_table[i].state == self.police_state.search_player then
				local direction = direction_util.to_vector3(self.patrol_police_table[i].character.Direction)

				attack_range_util.setup_by_direction(self.patrol_police_table[i].attack_range,
						self.patrol_police_table[i].character.Position, direction, 0)

				-- 중복 발생 플래그가 on거나 플레이어 컨트롤이 빼앗긴 경우, 전투 중인 경우, 경찰 이동 중단된 경우는 넘어감
				if not self.is_detected_by_police and not self.pause_police and not
				lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
						CS.Oak.CharacterControllerScreenplayState) and
						is_unity_null(stage.BattleManager:GetBattleFor(user_party)) then
					if self:is_in_sight(self.patrol_police_table[i].character, user_party.Leader,
							self.police_sight_distance, self.police_sight_angle) then
						find_police = self.patrol_police_table[i].character

						self.patrol_police_table[i].attack_range:Hide()

						break
					end
				end
			end
		end

		-- 발각된 경우
		if find_police ~= nil then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.detected_by_police, self, find_police))
		end

		coroutine.yield(nil)
	end
end

-- 경찰에게 발각된 경우 실행되는 이벤트
function local_class:detected_by_police(find_police)
	-- 파라미터에 따라 Police 설정
	local cur_police_table = self:get_police_table(self.notoriety_lv)
	local is_erina = false

	-- 물건을 들고 갈 경우 연출 처리 추가
	if lua_helper.type_compare(user_party.Leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState) then
		local hold_target = user_party.Leader.CharacterBehaviour.CurrentActionState.HoldTarget
		command_util.execute_throw(user_party.Leader,
				hold_target, direction_util.to_vector3(user_party.Leader.Direction),
				user_party.Leader.Position, 3, false)
	end

	-- 현재 레벨이 5이고 find_police가 에리나가 아니라면 이전 레벨의 경찰들을 쓰러트리는 것으로 함
	if self.notoriety_lv == 5 and
			not lua_helper.reference_equals(find_police, self.follow_police_table[3].character) then
		cur_police_table = self:get_police_table(self.notoriety_lv - 1)
	else
		is_erina = true
	end

	self.is_detected_by_police = true

	character_util.remove_anim(find_police)
	character_util.stop(find_police)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_pause'}))
	party_util.stop_and_disable_control()

	-- 추적하던 경찰들 전부 멈춤
	for i = 1, #self.follow_police_table do
		if self.follow_police_table[i].state == self.police_state.search_player then
			self.follow_police_table[i].character.FieldObjectController = CS.Oak.NPCCharacterController()
			character_util.stop(self.follow_police_table[i].character)
			character_util.remove_anim(self.follow_police_table[i].character)

			-- AttackRange 비활성화
			if self.follow_police_table[i].attack_range ~= nil then
				self.follow_police_table[i].attack_range:Hide()
			end
		end
	end

	camera_util.move_async(find_police.Position, 0.5)

	for i = 0, user_party.Count - 1 do
		character_util.look_at(user_party[i], find_police)
	end

	-- 발견한 경찰 연출
	CS.Oak.NoticeIcon.SetBattleStart(find_police)

	if lua_helper.reference_equals(find_police, self.follow_police_table[3].character) then
		music_player_util.play_sfx_one_shot('03_dialogue_ready_01')

		character_util.remove_anim(find_police)

		speech_bubble_util.show_speech_bubble_async(
				find_police, { key = 'demonworld_part1_police_4', skip = true })
	else
		music_player_util.play_sfx_one_shot('03_dialogue_police_01')

		character_util.jump(find_police, 0.5, 0.3)
		character_util.set_anim(find_police, { name = 'release', sfx_name = '01_swing_01' })
		character_util.set_emotion(find_police, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(
				find_police, { key = 'demonworld_part1_police_1', skip = true })
	end

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 플레이어 원래 위치 저장
	self.player_saved_pos = user_party.Leader.Position
	self.player_saved_dir = user_party.Leader.Direction

	camera_util.move_async(self.police_battle_marker_position + vector(0, 0, 1), 0)

	-- 플레이어 이동
	party_util.align_party(self.police_battle_marker_position + vector(0, 0, -1), 'down', 0, 'arc')

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
	end

	-- 적 이동
	if self.notoriety_lv ~= 5 or not is_erina then
		local battle_pos_list = create_generic_list(unity_class.vector3)
		local battle_dir_list = create_generic_list(CS.System.String)

		if self.notoriety_lv == 1 then
			battle_pos_list:Add(vector(-3.5, 0, 0))
			battle_pos_list:Add(vector(-5.5, 0, 3))
			battle_pos_list:Add(vector(3.5, 0, 0))
			battle_pos_list:Add(vector(5.5, 0, 3))
		elseif self.notoriety_lv == 2 then
			battle_pos_list:Add(vector(-4, 0, 0))
			battle_pos_list:Add(vector(-5.5, 0, 2))
			battle_pos_list:Add(vector(0, 0, 0))
			battle_pos_list:Add(vector(0, 0, 3))
			battle_pos_list:Add(vector(4, 0, 0))
			battle_pos_list:Add(vector(5.5, 0, 2))
		elseif self.notoriety_lv == 3 then
			battle_pos_list:Add(vector(-5, 0, 2))
			battle_pos_list:Add(vector(-6.5, 0, -5))
			battle_pos_list:Add(vector(0, 0, 1))
			battle_pos_list:Add(vector(0, 0, 4))
			battle_pos_list:Add(vector(5, 0, 2))
			battle_pos_list:Add(vector(6.5, 0, -5))

			battle_dir_list:Add('down')
			battle_dir_list:Add('right')
			battle_dir_list:Add('down')
			battle_dir_list:Add('down')
			battle_dir_list:Add('down')
			battle_dir_list:Add('left')
		elseif self.notoriety_lv == 4 or self.notoriety_lv == 5 then
			battle_pos_list:Add(vector(-4, 0, 2))
			battle_pos_list:Add(vector(4, 0, 2))
			battle_pos_list:Add(vector(-6.5, 0, 4))
			battle_pos_list:Add(vector(-6.5, 0, -5))
			battle_pos_list:Add(vector(6.5, 0, -5))
			battle_pos_list:Add(vector(6.5, 0, 4))

			battle_dir_list:Add('down')
			battle_dir_list:Add('down')
			battle_dir_list:Add('down')
			battle_dir_list:Add('left')
			battle_dir_list:Add('right')
			battle_dir_list:Add('down')
		end

		for i = 1, #cur_police_table do
			local cur_police_info = cur_police_table[i]

			cur_police_info.state = self.police_state.battle

			-- 히트박스 복구
			cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

			cur_police_info.character.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
			character_util.set_position(cur_police_info.character, self.police_battle_marker_position + battle_pos_list[i - 1])

			if battle_dir_list.Count == 0 then
				character_util.set_direction(cur_police_info.character, 'down')
			else
				character_util.set_direction(cur_police_info.character, battle_dir_list[i - 1])
			end

			character_util.remove_anim(cur_police_info.character)
			character_util.remove_emotion(cur_police_info.character)
		end
	else
		buff_manager:RemoveBuff(self.erina, CS.Oak.EquipmentSlot.None, self.erina, "speed_down_persistent")

		for i = 1, #cur_police_table do
			local cur_police_info = cur_police_table[i]
			cur_police_info.state = self.police_state.battle

			-- 히트박스 복구
			cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

			character_util.set_position(cur_police_info.character,
					self.police_battle_marker_position + vector(0, 0, 1))
			character_util.set_direction(cur_police_info.character, 'down')
			character_util.remove_anim(cur_police_info.character)
		end

		music_player_util.set_stage_music_clip_async({ name = 'bgm_battle_boss', state = 'combat' })

		music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	end

	wait_for_unscaled_sec(0.5)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	if self.notoriety_lv == 5 and not is_erina then
		screen_util.show_boss_title('demonworld_part1_police_battle_'..(self.notoriety_lv - 1),
				'', 2, false)
	else
		if self.notoriety_lv == 5 then
			music_player_util.play_sfx_one_shot('01_boss_title_01')

			screen_util.show_boss_title('demonworld_part1_police_battle_'..self.notoriety_lv,
					'demonworld_part1_police_battle_6', 2, false)
		else
			screen_util.show_boss_title('demonworld_part1_police_battle_'..self.notoriety_lv,
					'', 2, false)
		end
	end

	wait_for_sec(2)

	camera_util.move_async(user_party.Leader.Position, 1, { end_target = user_party.Leader })

	self.player_is_battle = true

	-- 전투 시작
	if self.notoriety_lv ~= 5 or not is_erina then
		for i = 1, #cur_police_table do
			local cur_police_info = cur_police_table[i]

			character_util.convert_to_monster(cur_police_info.character,
					self.police_battle_group_name..self.notoriety_lv, nil)
			command_util.execute_monster_notice(cur_police_info.character, user_party.Leader, 'battle')
		end
	else
		character_util.convert_to_monster(self.erina, self.erina_battle_group_name, nil)
		command_util.execute_monster_notice(self.erina, user_party.Leader, 'battle')
	end

	party_util.reset_controllers()
end

-- A의 시야에 B가 들어왔는지 확인, y축은 무시함
function local_class:is_in_sight(fo, target, distance, angle)
	local full_diff = target.Bounds.center - fo.Bounds.center
	local diff = target.Bounds.center - fo.Bounds.center

	if diff.magnitude > distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > angle / 2 then
		return false
	end

	if field:IsAnythingBlockingWithoutBounds(CS.UnityEngine.Bounds(fo.Bounds.center, vector(0.05, 0.05, 0.05)),
			CS.Oak.EntityGroups.Obstacle, vector_util.get_x0z(full_diff)) then
		return false
	end

	return true
end

-- 경찰 쓰러트리면 원래 위치로 돌아오고 악명 증가
function local_class:defeat_police(table_id)
	-- 파라미터에 따라 Police 설정
	local cur_police_table
	if table_id == 5 then
		cur_police_table = self:get_police_table(table_id - 1)
	else
		cur_police_table = self:get_police_table(table_id)
	end

	for i = 1, #cur_police_table do
		local cur_police_info = cur_police_table[i]

		cur_police_info.state = self.police_state.dead
	end

	wait_for_sec(2)

	party_util.stop_and_disable_control()

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 적 초기화
	for i = 1, #cur_police_table do
		self:initialize_monster(cur_police_table[i].character)

		cur_police_table[i].state = self.police_state.idle
	end

	-- 경찰 제거
	if self.notoriety_lv ~= 5 then
		self:remove_follow_police()
	end

	self:remove_patrol_police()

	party_util.align_party(self.player_saved_pos + CS.Oak.DirectionExtensions.ToVector3(
			CS.Oak.DirectionExtensions.GetOpposite(self.player_saved_dir)),
			self.player_saved_dir, 0, 'arc')

	-- 파티션에 넣으려면 Position 직접 변경해줘야 함
	user_party.Leader.Position = self.player_saved_pos

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	self.player_is_battle = false
	party_util.reset_controllers()

	-- 드론 스토킹 다시 시작 (add_notoriety 에리나 등장때 pause 다시 호출)
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_resume'}))

	self.is_detected_by_police = false

	-- 악명 추가
	coroutine.yield(self:add_notoriety(
			self.current_notoriety + self.kill_police_notorieties[table_id], true))

	-- 값 변경되지 않은 경우 (변경된 경우에는 add_notoriety 내부에서 생성)
	if table_id == self.notoriety_lv then
		if self.notoriety_lv ~= 5 then
			-- 추적 경찰 생성
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.spawn_police, self, self.notoriety_lv))
		else
			-- 추적 경찰 생성
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.spawn_erina, self, false))
		end

		-- 순찰 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_patrol_police, self))
	end
end

-- 추적 경찰 제거
function local_class:remove_follow_police()
	for i = 1, #self.follow_police_table do
		self.follow_police_table[i].character.FieldObjectController = CS.Oak.NPCCharacterController()
		character_util.stop(self.follow_police_table[i].character)

		character_util.spine_set_alpha_fade(self.follow_police_table[i].character, 0, 1)

		character_util.remove_anim(self.follow_police_table[i].character)
		character_util.remove_emotion(self.follow_police_table[i].character)

		-- AttackRange 비활성화
		if self.follow_police_table[i].attack_range ~= nil then
			self.follow_police_table[i].attack_range:Hide()
		end

		self.follow_police_table[i].state = self.police_state.idle

		if lv ~= 5 then
			character_util.set_position(self.follow_police_table[i].character, vector(999, 0, 999))
		else
			character_util.set_active_state(self.follow_police_table[i].character, 'disabled')
		end

		character_util.spine_set_alpha_fade(self.follow_police_table[i].character, 1, 0)

		-- 히트박스 복구
		self.follow_police_table[i].Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

		-- 에리나는 버프 제거
		if lv == 5 then
			buff_manager:RemoveBuff(self.follow_police_table[i], CS.Oak.EquipmentSlot.None,
					self.follow_police_table[i], "speed_down_persistent")
		end
	end
end

-- 순찰 경찰 제거
function local_class:remove_patrol_police()
	-- 순찰 경찰 제거
	for i = 1, #self.patrol_police_table do
		local cur_patrol_police = self.patrol_police_table[i].character

		character_util.stop(cur_patrol_police)
		character_util.set_position(cur_patrol_police, vector(999, 0, 999))
		character_util.remove_anim(cur_patrol_police)
		character_util.remove_emotion(cur_patrol_police)

		self.patrol_police_table[i].state = self.police_state.idle

		if self.patrol_police_table[i].attack_range ~= nil then
			self.patrol_police_table[i].attack_range:Hide()
		end
	end
end

-- 에리나 쓰러트린 경우의 연출
function local_class:defeat_erina()
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	music_player_util.set_stage_music_clip_async(
			{ name = 'ondemand/v2_15_demonworld/audio:bgm_battle_normal_02', state = 'combat' })

	self.siren_sfx:FadeOut(0)

	local boss_sfx = music_player_util.play_sfx({sfx_name = '01_boss_die_01', type_priority = "event", player_priority = "npc" })

	for i = 0, user_party.Count - 1 do
		character_util.look_at(user_party[i], self.erina)
	end

	wait_for_sec(6.5)
	boss_sfx:FadeOut(0)
	wait_for_sec(0.5)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 버그 발생 후 리셋 연출
	local noise_effect
	local typing_text
	local noise_end_effect

	local cur_time = unity_class.time.time

	-- 노이즈 이펙트 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/effects', 'fx_cp13_noise_screen_fx', function(prefab)
				noise_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				noise_effect.transform:SetParent(stage_camera.Transform)
				noise_effect.transform.localPosition = unity_class.vector3.zero
				noise_effect.transform.localRotation = unity_class.quaternion.identity
				noise_effect:SetActive(false)
			end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ui/prologue', 'typing_text', function(prefab)
				typing_text = CS.NGUITools.AddChild(
						stage.UIRoot.gameObject, prefab):GetComponent(typeof(CS.UITypingText))

				typing_text.Widget:SetAnchor(stage.UIRoot.gameObject, 1, 150, 1, 170)
				typing_text.Widget.topAnchor.relative = 0
				typing_text.Widget:UpdateAnchors()
				typing_text.Label.fontSize = 32
			end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/effects', 'fx_cp13_noise_screen_turnoff', function(prefab)
				noise_end_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				noise_end_effect.transform:SetParent(stage_camera.Transform)
				noise_end_effect.transform.localPosition = unity_class.vector3.zero
				noise_end_effect.transform.localRotation = unity_class.quaternion.identity
				noise_end_effect:SetActive(false)
			end)

	local load_duration = 1

	if unity_class.time.time - cur_time < load_duration then
		wait_for_sec(load_duration - (unity_class.time.time - cur_time))
	end

	local noise_active_duration = 2

	noise_effect:SetActive(true)

	local glitch_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_glitch_03', loop = true, type_priority = 'loop' })

	wait_for_sec(noise_active_duration)

	music_player_util.play_sfx_one_shot('01_count_01')

	coroutine.yield(typing_text:SetTypedText(game_string:GetString('demonworld_part1_police_5'), 1000, 0, 3.0))

	music_player_util.play_sfx_one_shot('01_count_01')

	coroutine.yield(typing_text:SetTypedText(game_string:Format('demonworld_part1_police_6', user.Name), 1000, 0, 3.0))

	typing_text:ForceFinish()

	wait_for_sec(0.5)

	glitch_sfx:FadeOut(0)

	music_player_util.play_sfx_one_shot('01_tv_off_02')

	noise_effect:SetActive(false)
	noise_end_effect:SetActive(true)

	wait_for_sec(1)

	screen_util.fade_out_async(0, unity_class.color.black, 'linear')

	-- 사용한 프리팹들 제거
	if noise_effect ~= nil then
		CS.UnityEngine.Object.Destroy(noise_effect)
	end

	if typing_text ~= nil then
		CS.UnityEngine.Object.Destroy(typing_text)
	end

	if noise_end_effect ~= nil then
		CS.UnityEngine.Object.Destroy(noise_end_effect)
	end

	self:reset_notoriety()

	wait_for_sec(1)

	field_ui_manager:Show()

	stage_camera:SetTarget(user_party.Leader)

	-- 플레이어 초기화
	party_util.align_party(self.player_saved_pos + CS.Oak.DirectionExtensions.ToVector3(self.player_saved_dir),
			self.player_saved_dir, 0, 'arc')

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self.is_detected_by_police = false

	party_util.reset_controllers()
end

-- 악명 초기화에 따른 전체 리셋
function local_class:reset_notoriety()
	-- 악명 초기화
	self.notoriety_lv = 0
	self.current_notoriety = 0

	-- 악명 값 변경 수치 Publish
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			nil, { self.current_notoriety_num, self.current_notoriety }))

	-- 악명 레벨 변경 수치 Publish
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			nil, { self.current_notoriety_lv, self.notoriety_lv }))

	for i = 0, 4 do
		self.notoriety_ui_star_list[i].alpha = 0
	end

	self:fill_gauge(self.current_notoriety)

	self.notoriety_ui:SetActive(false)

	-- 악명 부가 효과 제거
	for i = 0, self.siren_effect_list.Count - 1 do
		if self.siren_effect_list[i] ~= nil then
			self.siren_effect_list[i]:Dispose()
		end
	end
	self.siren_effect_list:Clear()

	-- 사운드
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	coroutine.yield(nil)

	music_player_util.play_stage_music(
			{ name = 'ondemand/v2_15_demonworld/audio:bgm_demonworld_main', state = 'field', mix = 2 })

	if self.siren_sfx ~= nil then
		self.siren_sfx:FadeOut(1)
	end

	-- 드론 및 헬기 기믹 stop
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stalking_stop'}))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'patrolling_stop'}))

	field:RemoveTint(self.notoriety_lv_3_tint_key, 0)

	for i = 0, self.fire_effect_obj_list.Count - 1 do
		self.fire_effect_obj_list[i].Position = vector(-200, 0, -200)
	end

	for n = 1, 5 do
		for i = 0, user_party.Count - 1 do
			buff_manager:RemoveBuff(
					user_party[i], CS.Oak.EquipmentSlot.None, user_party[i], self.level_up_debuff_name..n)
		end
	end

	-- NPC와 적 초기화
	for i = 1, #self.police_tables do
		local cur_table = self.police_tables[i]

		for j = 1, #cur_table do
			self:initialize_monster(cur_table[j].character)

			cur_table[j].state = self.police_state.idle
		end
	end

	for i = 1, #self.follow_police_table do
		self:initialize_monster(self.follow_police_table[i].character)

		self.follow_police_table[i].state = self.police_state.idle

		if self.follow_police_table[i].attack_range ~= nil then
			self.follow_police_table[i].attack_range:Hide()
		end
	end

	for i = 1, #self.patrol_police_table do
		self:initialize_monster(self.patrol_police_table[i].character)

		if self.patrol_police_table[i].attack_range ~= nil then
			self.patrol_police_table[i].attack_range:Hide()
		end
	end

	self.patrol_police_table = nil
	self.patrol_police_table = {}

	self.current_patrol_police_num = 0

	-- 기타 UI 처리
	self.notoriety_ui.transform:Find('Contents/Button/item/Title'):GetComponent(typeof(CS.UILabel)).text =
		game_string:GetString('demonworld_part1_notoriety_title_'..0)

	for i = 0, self.notoriety_ui_gauge_bar_list.Count - 1 do
		self.notoriety_ui_gauge_bar_list[i].fillAmount = 0.0
	end

	-- ExclusiveQuestEndEvent
	self:publish_exclusive(false)

	-- 건물 입장 가능
	message_system:Publish(CS.Oak.ActivateExitInteractableEvent.Create(true))
end

-- 적 초기화
function local_class:initialize_monster(fo)
	if not lua_helper.type_compare(fo.FieldObjectController, CS.Oak.NPCCharacterController) then
		fo.EntityGroup = CS.Oak.EntityGroups.Enemy
		character_util.convert_to_npc(fo)
	end

	character_util.set_active_state(fo, 'enabled')
	character_util.spine_set_alpha_fade(fo, 1, 0)
	character_util.stop(fo)
	character_util.set_position(fo, vector(999, 0, 999))
	character_util.remove_anim(fo)
	character_util.remove_emotion(fo)
	fo.SpineController:Rotate(0, 0)

	-- 힐로 HP 초기화
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = nil
	heal_info.target = fo
	heal_info.heal = fo.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true

	command_util.execute_heal(heal_info)
end
--endregion

--region Notoriety Reset Function
-- 현상 수배 리셋 NPC 이모티콘 표시
function local_class:show_notoriety_reset_npc_emoticon()
	-- NPC가 없으면 아무것도 처리하지 않음
	if self.notoriety_reset_npc == nil then
		return
	end

	-- 현상수배 리셋 NPC 이모티콘 추가
	local emoticon_obj = unity_object_pool.GetOrCreate('emoticon'):Instantiate(self.notoriety_reset_npc.Position)
	self.notoriety_reset_npc_emoticon = emoticon_obj.transform:GetComponent(typeof(CS.Oak.Emoticon))
	local emoticon_type = character_util.get_emoticon_type('tease')

	self.notoriety_reset_npc_emoticon:Init()
	self.notoriety_reset_npc_emoticon:ShowOn(
			self.notoriety_reset_npc.transform, unity_class.vector3.one, emoticon_type, vector(0, 0, 1), nil, 1, nil, true)
end

-- 악명 초기화 시켜주는 NPC와 상호작용 시 나오는 이벤트 일반
function local_class:interact_with_notoriety_reset_npc_normal()
	-- NPC가 없으면 아무것도 처리하지 않음
	if self.notoriety_reset_npc == nil then
		return
	end

	self.notoriety_reset_npc_emoticon:Clear()

	party_util.align_party(self.notoriety_reset_npc, self.notoriety_reset_npc.Direction, 1, 'arc')

	character_util.set_anim(self.notoriety_reset_npc, { name = 'cast' })
	character_util.set_emotion(self.notoriety_reset_npc, { name = 'doyagao' })

	speech_bubble_util.show_speech_bubble_async(
			self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_7', skip = true })

	character_util.set_anim(self.notoriety_reset_npc, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(
			self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_8', skip = true })

	character_util.remove_anim(self.notoriety_reset_npc)
	character_util.remove_emotion(self.notoriety_reset_npc)

	self:show_notoriety_reset_npc_emoticon()
end

-- 악명 초기화 시켜주는 NPC와 상호작용 시 나오는 이벤트
function local_class:interact_with_notoriety_reset_npc()
	-- NPC가 없으면 아무것도 처리하지 않음
	if self.notoriety_reset_npc == nil then
		return
	end

	self.notoriety_reset_npc_emoticon:Clear()

	party_util.align_party(self.notoriety_reset_npc, self.notoriety_reset_npc.Direction, 1, 'arc')

	character_util.set_anim(self.notoriety_reset_npc, { name = 'question', loop = false })

	speech_bubble_util.show_speech_bubble_async(
			self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_1', skip = true })

	character_util.set_anim(self.notoriety_reset_npc, { name = 'cross_arm' })
	character_util.set_emotion(self.notoriety_reset_npc, { name = 'doyagao' })

	speech_bubble_util.show_speech_bubble_async(
			self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_2', skip = true })

	character_util.remove_anim(self.notoriety_reset_npc)
	character_util.remove_emotion(self.notoriety_reset_npc)

	local choose_result = choose_util.play_choose_event(
			{ { 'demonworld_part1_notoriety_reset_3', 'mercy' }, { 'demonworld_part1_notoriety_reset_4', 'brutal' } })

	if choose_result == 1 then
		music_player_util.play_sfx_one_shot('01_phone_receive_02')

		local phone = drop_item_util.create_item(
				{itemid = 20017, pos = self.notoriety_reset_npc.Position + vector(-0.15, 0.35, -0.1),
				 notforinven = true, lootstate = 'dontfindlooter', showoncharacter = true, sprscale = 0.6})

		wait_for_sec(0.7)

		character_util.set_anim(self.notoriety_reset_npc, { name = 'nod' })

		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(self.notoriety_reset_npc,
				{ key = 'demonworld_part1_notoriety_reset_5', skip = true })

		screen_util.fade_out_async(1, unity_class.color.white, 'linear')

		phone:ConsumeComplete()

		character_util.remove_anim(self.notoriety_reset_npc)
		character_util.remove_emotion(self.notoriety_reset_npc)

		self:reset_notoriety()

		wait_for_sec(1)

		screen_util.fade_in_async(1, unity_class.color.white, 'linear')

		character_util.set_anim(self.notoriety_reset_npc, { name = 'bomb_idle' })

		speech_bubble_util.show_speech_bubble_async(
				self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_9', skip = true })

		character_util.set_anim(self.notoriety_reset_npc, { name = 'release', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(
				self.notoriety_reset_npc, { key = 'demonworld_part1_notoriety_reset_10', skip = true })

		character_util.remove_anim(self.notoriety_reset_npc)
	end

	self:show_notoriety_reset_npc_emoticon()
end
--endregion

--region Dollar Function
-- 달러 떨어짐
function local_class:dollar_drop(sender, number)
	local rand_x = unity_class.random.Range(-self.dollar_dropped_range_x, self.dollar_dropped_range_x)
	local rand_z = unity_class.random.Range(-self.dollar_dropped_range_z, self.dollar_dropped_range_z)

	local dollar_item = drop_item_util.create_item({ pos = sender.Position,
	                                                 target = sender.Position + vector(rand_x, 0, rand_z),
	                                                 itemid = self.dollar_item_id, notforinven = true, sprscale = 0.5,
	                                                 lootstate = 'dontfindlooter', skip_text = true })

	self.dollar_table[#self.dollar_table + 1] = {
		item = dollar_item,
		num = number
	}

	local cur_table = self.dollar_table[#self.dollar_table]

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.wait_for_change_dollar_state, self, cur_table, 1))
end

-- 떨어진 달러 1초 뒤에 플레이어가 강제로 획득하게 설정
function local_class:wait_for_change_dollar_state(cur_table, wait_delay)
	wait_for_sec(wait_delay)

	cur_table.item.ConsumeTarget = user_party.Leader
	cur_table.item:Fly()

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.get_dollar, self, cur_table))
end

-- 달러 획득했는지 처리
function local_class:get_dollar(cur_table)
	-- 달러 Item을 획득할 때까지 대기
	-- TODO: 매 프레임마다 대기하는 방식인데 개선 필요함
	while ((user_party.Leader.Position:GetX0z() -
			cur_table.item.Position:GetX0z()).magnitude > self.dollar_pick_distance) do
		coroutine.yield(nil)
	end

	CS.Oak.FieldUIFloatingText.Get(user_party.Leader):JustPrintItemName('+' .. (amount) .. ' ' ..
			game_string:GetString('demonworld_part1_dollar'), 0)

	message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party.Leader, { self.dollar_add_event, amount, true }))
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
