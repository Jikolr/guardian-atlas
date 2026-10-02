local local_class = newclass('QueenShip1At4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.stage_string_key = 'qs_stage_4_'

	self.s13_string_key = 'qs_main_s13_stage_'
	self.s14_string_key = 'qs_main_s14_stage_'

	-- 파이몬 이펙트 가로 세로 타입
	self.pymon_effect_line_type = {
		width_1 = 1,
		width_2 = 2,
		vertical_1 = 3,
		vertical_2 = 4,
	}

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- field object
	self.get_metal_block = function(num)
		return get_field_object('s14_metal_block_'..num)
	end

	self.get_metal_block_jump_tile = function(num)
		return get_field_object('s14_metal_block_jump_tile_'..num)
	end

	-- 13섹션 이후 공주가 지나온 컴퓨터 실 샛길 막는 용도 오브젝트
	self.get_server_rack_dummy = function()
		return get_field_object('server_rack_dummy')
	end

	-- 13섹션 배틀중 배틀 존 나가기 방지용 오브젝트 (13섹션 이후로 비활성화)
	self.get_invisible_battle_barricade = function()
		return get_field_object('battle_barricade')
	end

	-- 13섹션 이후 공주가 지나온 컴퓨터 실 샛길 막는 용도 오브젝트
	self.get_s15_computer = function()
		return get_field_object('s15_computer')
	end

	-- 해킹 콘솔 상호작용 용도 오브젝트
	self.s14_hacking_console = function(num)
		return get_field_object('s14_hacking_console_' .. num)
	end

	-- section 13 s2 열쇠 구역 중앙 sack 오브젝트
	self.get_heal_gimmick = function(num)
		return get_field_object('get_heal_gimmick')
	end

	self.get_s13_up_side_magnet_n = function()
		return get_field_object('up_side_magnet_n')
	end

	-- section 14 자석 도둑 구역의 홀더블 자석
	self.get_magnet_s = function()
		return get_field_object('s14_magnet_s')
	end

	self.get_magnet_n = function()
		return get_field_object('s14_magnet_n')
	end

	-- 자석 도둑 이벤트 내 자석 리셋 스위치
	self.get_magnet_reset_switch = function()
		return get_field_object('s14_magnet_thief_magnet_reset')
	end
	-- 위의 꺼 동작 안하는 버전 더미
	self.get_magnet_reset_switch_dummy = function()
		return get_field_object('s14_magnet_thief_magnet_reset_dummy')
	end

	-- 공주
	-- 파티원 상태
	self.get_manual_princess = function()
		return get_character('manual_princess')
	end
	-- 솔로 상태
	self.get_supporter_princess = function()
		return get_character('supporter_princess')
	end

	-- 마귀
	self.get_magwi = function()
		return get_character('magwi')
	end

	self.get_s13_patrol_invader = function(num)
		return get_character('s13_key_room_patrol_invader_'..num)
	end

	-- 15섹션에서 사용하는 컴퓨터 방 지키는 인베이ㅣ더 1명
	self.get_s15_computer_invader = function()
		return get_character('s15_computer_room_invader')
	end


		-- object name
	self.magnet_thief_reset_switch_name = 's14_magnet_thief_block_reset'

	-- markers
	self.get_control_room_pos = function()
		return field:GetMarker('control_room').position
	end
	self.get_magic_circle_passage_pos = function(num)
		return field:GetMarker('magic_circle_passage_'..num..'_out_pos').position
	end
	self.get_s13_key_room_patrol_pos = function(num)
		return field:GetMarker('s13_key_room_patrol_pos_'..num).position
	end
	-- 철 블럭이 점프대에서 튄 후 도착 지점 마커
	self.get_iron_block_jump_end_pos = function()
		return field:GetMarker('s14_s1_magnet_thief_invader_pos_2_4').position
	end
	-- s13-s3, s14 시작 지점
	self.get_s14_start_pos = function()
		return field:GetMarker('s13_s3_last_scene_princess_pos').position
	end
	-- s15 시작 지점
	self.get_s15_start_pos = function()
		return field:GetMarker('s15_start_pos').position
	end
	-- 컴퓨터 방 내 인베이더 위치 (14섹션부터 사용)
	self.get_s14_computer_invader_pos = function(num)
		return field:GetMarker('secret_road_blocker_pos').position
	end
	-- 컴퓨터 방 내 인베이더 위치 (15섹션부터 사용)
	self.get_s15_computer_invader_pos = function(num)
		return field:GetMarker('s15_computer_room_invader_pos').position
	end

	-- 스테이지 재진입 시 각각의 자석 위치 (14섹션 구역에서 자석 도둑관련 자석 리셋 마커)
	self.get_reset_magnet_s_pos = function()
		return field:GetMarker('reset_magnet_s_pos').position
	end
	self.get_reset_magnet_n_pos = function()
		return field:GetMarker('reset_magnet_n_pos').position
	end
	-- 14섹션 자석 도둑 관련 도둑 인베이더 위치 마커(푸셔블 철 블럭 배치를 위해)
	self.get_s2_thief_pos = function(num, path_index)
		return field:GetMarker('s14_s1_magnet_thief_invader_pos_'..num..'_'..path_index).position
	end

	-- 키 도어 구역 감시 리셋 마커 가져오기
	self.get_reset_pos = {
		{
			pos = field:GetMarker('s13_key_room_reset_pos').position,
			dir = 'right'
		}
	}

	-- zone names
	self.magic_circle_passage_zone_1_name = 'magic_circle_passage_zone_1'
	self.magic_circle_passage_zone_2_name = 'magic_circle_passage_zone_2'

	self.metal_block_catapult_zone_1_name = 's14_s2_metal_block_catapult_zone_1'
	self.metal_block_catapult_zone_2_name = 's14_s2_metal_block_catapult_zone_2'

	self.magiccircle_out_markers = {
		magic_circle_passage_zone_1 = 'magic_circle_passage_1_out_pos',
		magic_circle_passage_zone_2 = 'magic_circle_passage_2_out_pos'
	}

	-- BATTLE_2 존이 컴퓨터 존 전체를 포함하고 있어 사용(자석이 영역 안에 들어오면 리셋 시킬 용도)
	self.computer_room_event_area_name = 'BATTLE_2'

	-- 철 블럭 점프 시작 방향
	self.block_jump_point = {
		up_side = 1,
		down_side = 2
	}

	-- field object name

	-- effect
	-- 마법진
	self.get_fx_magic_circle = function()
		return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')
	end
	-- 철 블록 점프 후 착지 이펙트
	self.get_fx_iron_block_shock = function()
		return unity_object_pool.GetOrCreate('fx_m_viking_stomp')
	end

	-- 석판 보드 폭발 이펙트
	self.get_fx_stone_board_bomb = function()
		return unity_object_pool.GetOrCreate('FX_explosion_boss')
	end

	-- [object]
	-- effect object
	self.magic_circle_passage_effect_1 = nil
	self.magic_circle_passage_effect_2 = nil

	-- battle gate
	-- [s15]
	self.battle_gate_count = 4
	self.battle_gate_key = 's15_battle_gate_'

	-- etc
	-- 마법진 사용 중 체크
	self.warp_magiccircle = false

	self.loop_escape = false

	-- 철 블럭 점프대로 쏜 횟수
	self.iron_block_jump_count = 0
	-- 철 블럭 점프대 이벤트 중인지 체크
	self.iron_block_enter_jump_zone = false

	-- 인베이더에게 발각 체크
	self.is_detected = true

	-- 스테이지 키 도어 방 순찰 인베이더 관련 변수
	self.invader_sight_distance = 3.7
	self.invader_sight_angle = 60

	-- 순찰 인베이더들 초기 위치
	self.invader_patrol_first_pos_list = {}

	-- 순찰 인베이더들 순찰 포인트 (2 그룹)
	self.invader_patrol_wp_pos_1_list = {}
	self.invader_patrol_wp_pos_2_list = {}

	-- 순찰 구역 걸릴때 리셋 위치
	self.patrol_area_reset_pos_list = {}

	-- 인베이더 그룹 당 인원
	self.number_of_invader_per_group = 3

	-- 인베이더 순찰 루프 플래그
	self.invaders_on_patrol = true

	-- 메인 퀘스트 id
	self.main_quest_id = 311
	self.main_quest = nil

	-- cctv
	self.cctv_1_detected_event_name = 'detected_stone1_cctv'
	self.cctv_2_detected_event_name = 'detected_stone2_cctv'

	self.cctv_1_detected_reset_marker_name = 'stone1_cctv_reset_pos'
	self.cctv_2_detected_reset_marker_name = 'stone2_cctv_reset_pos'

	self.laser_security_1_prefix = 'stone1_laser_'
	self.laser_security_2_prefix = 'stone2_laser_'

	self.laser_security_1_list = {}
	self.laser_security_2_list = {}

	self.laser_security_1_reset_marker_name = 'stone1_laser_reset_pos'
	self.laser_security_2_reset_marker_name = 'stone2_laser_reset_pos'

	self.playing_detected_event = false
	self.playing_laser_security = true

	self.in_laser_zone = false

	-- 석판 보드
	self.stone_board_name = 'qs_1_4_stone_board'

	--region 해킹 액팅 3
	self.mini_game = nil

	self.mini_game_3_play = false

	self.get_hacking_3_door_name = 'hacking_3_door'

	-- field object
	self.get_hacking_3_door = function()
		return get_field_object('hacking_3_door')
	end
	self.get_hacking_console_3 = function()
		return get_field_object('hacking_3_console')
	end
	-- 처음 콘솔에 접속했는지
	self.console_3_first_interact = false

	-- 상호작용하고 있는지
	self.interacted = false

	-- 미니게임(액티) 이름
	self.mini_game_name = 'EnemyBallDodgeGame'

	-- sack 안 포션 아이템
	self.position_in_sack_item_num = 20777

	self.potion_heal_ratio = 0.3

	-- 오퍼레이더 UI (queenship 전용)
	self.operator_ui_controller = nil
	self.operator_ui_obj = nil
	--endregion

	self.init_character_info = false
end

function local_class:load_resource()
	local main_quest_id = 311
	self.main_quest = user_progress:GetStartedQuest(main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent), 'on_reset_switch_turned_on_event')
	message_system:Subscribe(self ,typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self ,typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self ,typeof(CS.Oak.PlayerDetectedEvent), 'on_player_detected_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_mini_game_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.Events.StoneBoardDirectingFinishedEvent), 'on_stone_board_directing_finished_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CharacterConvertEvent), 'on_character_convert_event')

	self.get_fx_stone_board_bomb()
	self.get_fx_magic_circle()
	self.get_fx_iron_block_shock()

	local count = 1

	while true do
		local laser_security = get_field_object(self.laser_security_1_prefix .. count)

		if laser_security == nil then
			break
		end

		table.insert(self.laser_security_1_list, laser_security)
		count = count + 1
	end

	count = 1

	while true do
		local laser_security = get_field_object(self.laser_security_2_prefix .. count)

		if laser_security == nil then
			break
		end

		table.insert(self.laser_security_2_list, laser_security)
		count = count + 1
	end

	--region 해킹 액팅 3
	local hacking_door_3 = self.get_hacking_3_door()
	if not hacking_door_3.FieldObjectBehaviour.IsOpen then
		self.get_hacking_console_3().Interactable = CS.Oak.PublishInteractable()
	end
	--endregion

	-- CCTV HitBox 크기 줄임
	local cctvs = {}
	table.insert(cctvs, get_character('stone1_cctv_1'))
	table.insert(cctvs, get_character('stone1_cctv_2'))
	table.insert(cctvs, get_character('stone2_cctv_1'))
	table.insert(cctvs, get_character('stone2_cctv_2'))
	table.insert(cctvs, get_character('stone2_cctv_3'))
	table.insert(cctvs, get_character('stone2_cctv_4'))

	for i = 1, #cctvs do
		local cctv = cctvs[i]
		if cctv ~= nil then
			cctv.Hitbox = CS.Oak.Hitbox(vector(0.7, cctv.Hitbox.size.y, 0.7))
		end
	end
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

function local_class:on_event(e)
	return false
end

function local_class:on_magic_circle_effect()
	local effect_pos = self.get_magic_circle_passage_pos(1) + vector(2, 0, 0)
	self.magic_circle_passage_effect_1 = self.get_fx_magic_circle():Instantiate(effect_pos)

	effect_pos = self.get_magic_circle_passage_pos(2) + vector(0, 0, -2)
	self.magic_circle_passage_effect_2 = self.get_fx_magic_circle():Instantiate(effect_pos)
end

function local_class:on_stage_start_event()

	self:s13_patrol_invader_setting(false)

	-- 15섹션 구역 배틀게이트 열기
	for i = 1, self.battle_gate_count do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.battle_gate_key .. i))
	end

	self.playing_laser_security = true

	start_coroutine(self.s13_patrol_invader_detect_process, self)
	start_coroutine(self.laser_security_update, self)

	-- 석상보드 다 채웠으면 안 보이도록
	local stone_board = get_field_object(self.stone_board_name)
	if stone_board.FieldObjectBehaviour.IsComplete then
		character_util.set_active_state(stone_board, 'disabled')
	end

	-- FieldSNS창 띄우지 않도록 한다.
	message_system:Publish(CS.Oak.SNSSetEquipmentRecommendationEvent.Create(false))
end

function local_class:on_stage_end_event(e)
	self.playing_laser_security = false
end

function local_class:on_zone_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if not self.warp_magiccircle then
			if e.Zone.Name == self.magic_circle_passage_zone_1_name or
					e.Zone.Name == self.magic_circle_passage_zone_2_name then
				self.warp_magiccircle = true
				sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, e.Zone.Name)
			end
		end
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, 'laser_zone_1') or
			type_util.is_zone_full_enter(e, user_party.Leader, 'laser_zone_2') then
		self.in_laser_zone = true
	end

	-- 14섹션이 아닐때, 철 블록과 점프대 상호작용
	if self.main_quest.InnerProgress ~= 13 and not self.iron_block_enter_jump_zone then
		local metal_block_1 = self.get_metal_block(1)
		local metal_block_2 = self.get_metal_block(2)
		local iron_block_num = 0

		if lua_helper.reference_equals(e.FieldObject, metal_block_1) or
				lua_helper.reference_equals(e.FieldObject, metal_block_2) then
			if e.Zone.Name == self.metal_block_catapult_zone_1_name or e.Zone.Name == self.metal_block_catapult_zone_2_name then
				self.iron_block_enter_jump_zone = true

				local jump_point_index = self.block_jump_point.up_side
				if e.Zone.Name == self.metal_block_catapult_zone_1_name then
					jump_point_index = self.block_jump_point.up_side
				elseif e.Zone.Name == self.metal_block_catapult_zone_2_name then
					jump_point_index = self.block_jump_point.down_side
				end

				if lua_helper.reference_equals(e.FieldObject, metal_block_1) then
					iron_block_num = 1
				elseif lua_helper.reference_equals(e.FieldObject, metal_block_2) then
					iron_block_num = 2
				end

				start_coroutine(self.call_flying_iron_block_func, self, iron_block_num, jump_point_index)

				return true

			end
		end
	end

	-- 15 섹션 메인 이벤트 존에 자석 들어갈 경우 리셋 처리
	if lua_helper.reference_equals(e.FieldObject, self.get_s13_up_side_magnet_n()) then
		if e.Zone.Name == self.computer_room_event_area_name then
			self:reset_magnet_in_section_15_zone()
		end
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, 'laser_zone_1') or
			type_util.is_zone_full_leave(e, user_party.Leader, 'laser_zone_2') then
		self.in_laser_zone = false
	end
end

function local_class:on_reset_switch_turned_on_event(e)
	if self.main_quest.InnerProgress ~= 13 then
		if e.SwitchObject.Name == self.magnet_thief_reset_switch_name then
			if self.iron_block_jump_count > 0 then
				self:reset_magnet_thief_area_setting()
				return true
			end
		end
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if self.playing_detected_event then
		return false
	end

	if e.Params[0] == self.cctv_1_detected_event_name then
		self.playing_detected_event = true
		sp_util.play_normal_screenplay(self.on_detected_with_cctv, self, e.Sender, self.cctv_1_detected_reset_marker_name)

		return true

	elseif e.Params[0] == self.cctv_2_detected_event_name then
		self.playing_detected_event = true
		sp_util.play_normal_screenplay(self.on_detected_with_cctv, self, e.Sender, self.cctv_2_detected_reset_marker_name)

		return true
	end

	return false
	---- waypoint guard 용 발각 이벤트
	--if e:GetParamAt(0) == self.detected_event_key and not self.is_detected then
	--	self.is_detected = true
	--	start_coroutine(self.on_detected, self, e.Sender)
	--end
end

function local_class:on_player_detected_event(e)
	if self.playing_detected_event then
		return false
	end

	if table_util.contain_value(self.laser_security_1_list, e.Detector) then
		self.playing_detected_event = true
		sp_util.play_normal_screenplay(self.on_detected_with_laser_security, self, self.laser_security_1_reset_marker_name)

	elseif table_util.contain_value(self.laser_security_2_list, e.Detector) then
		self.playing_detected_event = true
		sp_util.play_normal_screenplay(self.on_detected_with_laser_security, self, self.laser_security_2_reset_marker_name)
	end
end

function local_class:on_field_object_destroyed_event(e)
	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_hacking_console_3()) and not self.mini_game_3_play then
		self.mini_game_3_play = true
		start_coroutine(self.hacking_3_console_interact, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_heal_gimmick()) then
		if not self.interacted then
			self.interacted = true
			self:eat_potion_in_sack(e.Target)
		end
	end

	return false
end

function local_class:on_mini_game_end_event(e)
	-- 미니게임 종료
	if e.Name == self.mini_game_name and self.mini_game_3_play then
		start_coroutine(self.end_mini_game, self, e.Success)
		return true
	end

	return false
end

function local_class:on_stone_board_directing_finished_event(e)
	if e.CurrentFill == 3 then
		start_coroutine(self.stone_board_bomb, self)

		return true
	end

	return false
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	if self.init_character_info then
		return false
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local character_spec_id = 20

	if main_quest_progress == nil or main_quest_progress.InnerProgress <= 12 or main_quest_progress.InnerProgress > 15
			or main_quest_progress.IsComplete then

		if user_util.has_knight_male() then
			character_spec_id = 2
		else
			character_spec_id = 1
		end
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)

	self.init_character_info = true
end

-- FIXME : 위와 중복코드지만 급해서 일단 그대로 씀
function local_class:on_character_convert_event(e)
	if e.Type ~= CS.Oak.CharacterConvertType.Player then
		return false
	end

	start_coroutine(function()
		coroutine.yield(nil)
		coroutine.yield(nil)

		local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
		local character_spec_id = 20

		if main_quest_progress == nil or main_quest_progress.InnerProgress < 12 or main_quest_progress.InnerProgress >= 15
				or main_quest_progress.IsComplete then

			if user_util.has_knight_male() then
				character_spec_id = 2
			else
				character_spec_id = 1
			end
		end

		get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
				user_party_leader.CharacterInfo.User, character_spec_id)
	end)
end

function local_class:pre_setting()

	--region 해킹3
	yield_return_func(CS.ScreenPlay.QueenShipOperatorUIExtensions.LoadOperatorUI, function(operator_ui)
		self.operator_ui_controller = operator_ui
		-- GT-1333 아랍어 대응
		if game_string.IsRTL and self.operator_ui_controller.operatorLabel.transform.localScale.x > 0 then
			local scale = self.operator_ui_controller.operatorLabel.transform.localScale
			scale.x = -scale.x

			self.operator_ui_controller.operatorLabel.transform.localScale = scale
			self.operator_ui_controller.operatorLabel.alignment = CS.TMPro.TextAlignmentOptions.TopRight
		end
	end)
	self.operator_ui_obj = self.operator_ui_controller.gameObject
	self.operator_ui_obj:SetActive(false)

	if self.operator_ui_controller ~= nil then
		yield_return_func(self.operator_ui_controller.InitPortrait, self.operator_ui_controller, 'demon_operator')
	end
	--endregion

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 13섹션 시작 지점 패트롤 인베이더들 셋팅
	character_util.set_active_state(self.get_s13_patrol_invader(1), 'enabled')
	--character_util.set_active_state(self.get_s13_patrol_invader(2), 'enabled')
	character_util.set_active_state(self.get_s13_patrol_invader(3), 'enabled')
	character_util.set_active_state(self.get_s13_patrol_invader(4), 'enabled')
	--character_util.set_active_state(self.get_s13_patrol_invader(5), 'enabled')
	character_util.set_active_state(self.get_s13_patrol_invader(6), 'enabled')

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(leader, party_member)
		-- 기사를 리더로
		local leader = leader
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 메인 컴퓨터 애니 상태 지정
	self:init_main_computer_ani(main_quest_progress)

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		screen_util.fade_in(0, unity_class.color.black, 'linear')
		screen_util.fade_in_circular(1, 'linear')
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position + direction_util.to_vector3(dir),
				leader.Direction, game_string:GetString(stage.Name)))
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end
	end

	-- 13섹션 이후 컴퓨터 실 샛길 막는 용도의 오브젝트 비활성화
	local server_rack_dummy = self.get_server_rack_dummy()
	local invisible_battle_barricade = self.get_invisible_battle_barricade()

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress < 13 then
		server_rack_dummy.ActiveState = active_state('disabled')
	end

	-- 13섹션 이후 컴퓨터 방 -> 샛길 방향 막는 오브젝트 비활성화
	if main_quest_progress ~= nil and main_quest_progress.InnerProgress > 12 then
		invisible_battle_barricade.ActiveState = active_state('disabled')

		if main_quest_progress.InnerProgress > 13 then
			local hacking_console = self.s14_hacking_console(1)
			hacking_console.ActiveState = active_state('disabled')
			hacking_console = self.s14_hacking_console(2)
			hacking_console.ActiveState = active_state('disabled')

			self:enable_magnet_reset_switch()
		end
	end




	-- link door 메세지 날림
	if main_quest_progress.InnerProgress > 13 then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true))

		local magnet_s = self.get_magnet_s()
		local magnet_n = self.get_magnet_n()
		local metal_block_1 = self.get_metal_block(1)
		local metal_block_2 = self.get_metal_block(2)

		magnet_s.Position = self.get_reset_magnet_s_pos()
		magnet_n.Position = self.get_reset_magnet_n_pos()
		metal_block_1.Position = self.get_s2_thief_pos(2, 4)
		metal_block_2.Position = self.get_s2_thief_pos(2, 4) + vector(1, 0, 0)
	end

	-- 현재 스펙트로 모든 섹션에서 비활성화(사용하지 않는다면 추후 삭제 예정)
	if main_quest_progress.InnerProgress ~= 12 then
		local computer = self.get_s15_computer()
		computer.ActiveState = active_state('disabled')
	end

	if main_quest_progress.IsComplete then
		change_leader_character(self.get_knight(), { self.get_supporter_princess() })

		start_stage_event('right', field_util.get_marker_pos('default_start'), true)
	elseif main_quest_progress.InnerProgress == 12 then
		change_leader_character(self.get_knight(), { self.get_supporter_princess() })
	elseif main_quest_progress.InnerProgress == 13 then
		change_leader_character(self.get_manual_princess(), nil)
		coroutine.yield(nil)
		start_stage_event('left', self.get_s14_start_pos() + vector(5, 0, 0), false)
	elseif main_quest_progress.InnerProgress == 14 then
		change_leader_character(self.get_manual_princess(), nil)
		coroutine.yield(nil)
		start_stage_event('left', self.get_s15_start_pos(), false)
	elseif main_quest_progress.InnerProgress == 15 then
		change_leader_character(self.get_manual_princess(), nil)
		coroutine.yield(nil)
		start_stage_event('left', self.get_s15_start_pos(), false)
	elseif main_quest_progress == nil or main_quest_progress.InnerProgress > 15  or main_quest_progress.InnerProgress < 12 then
		change_leader_character(self.get_knight(), { self.get_supporter_princess() })

		start_stage_event('right', field_util.get_marker_pos('default_start'), true)
	end

	coroutine.yield(nil)
	self:on_stage_start_event()
	self:on_magic_circle_effect()

	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

--region section_13_patrol_invader
function local_class:s13_patrol_invader_setting(reset)
	if not reset then
		-- 13섹션 키 도어 구역 인베이더 순찰하는 waypoint move
		table.insert(self.invader_patrol_wp_pos_1_list, self.get_s13_key_room_patrol_pos(1))
		table.insert(self.invader_patrol_wp_pos_1_list, self.get_s13_key_room_patrol_pos(2))
		table.insert(self.invader_patrol_wp_pos_1_list, self.get_s13_key_room_patrol_pos(3))
		table.insert(self.invader_patrol_wp_pos_1_list, self.get_s13_key_room_patrol_pos(4))
	end

	for i = 1, self.number_of_invader_per_group do
		local invader = self.get_s13_patrol_invader(i)

		if not reset then
			-- 초기 위치 저장
			table.insert(self.invader_patrol_first_pos_list, invader.Position)
		end

		self:convert_only_assassinate(invader)

		-- 인베이더 순찰 시작
		character_util.move_waypoint(invader,
				self.invader_patrol_wp_pos_1_list, 3, false, 'loop')
	end

	if not reset then
		table.insert(self.invader_patrol_wp_pos_2_list, self.get_s13_key_room_patrol_pos(3))
		table.insert(self.invader_patrol_wp_pos_2_list, self.get_s13_key_room_patrol_pos(4))
		table.insert(self.invader_patrol_wp_pos_2_list, self.get_s13_key_room_patrol_pos(1))
		table.insert(self.invader_patrol_wp_pos_2_list, self.get_s13_key_room_patrol_pos(2))
	end

	for i = self.number_of_invader_per_group + 1, (self.number_of_invader_per_group * 2) do
		local invader = self.get_s13_patrol_invader(i)

		if not reset then
			-- 초기 위치 저장
			table.insert(self.invader_patrol_first_pos_list, invader.Position)
		end

		self:convert_only_assassinate(invader)

		-- 인베이더 순찰 시작
		character_util.move_waypoint(invader,
				self.invader_patrol_wp_pos_2_list, 3, false, 'loop')
	end
end

function local_class:s13_patrol_invader_detect_process()
	local attack_range_renderer_list = {}

	for i = 1, (self.number_of_invader_per_group * 2) do
		local invader = self.get_s13_patrol_invader(i)
		local renderer = CS.Oak.GhostGuardAttackRangeRenderer(invader,
				self.invader_sight_distance, self.invader_sight_angle)
		table.insert(attack_range_renderer_list, renderer)
	end

	while self.invaders_on_patrol do
		for i = 1, (self.number_of_invader_per_group * 2) do
			local invader = self.get_s13_patrol_invader(i)

			attack_range_renderer_list[i].AttackRange:Show(0)
			attack_range_renderer_list[i]:Update(invader)

			local detected = self:is_in_sight(invader, user_party.Leader,
					self.invader_sight_distance, self.invader_sight_angle)

			if detected then
				self.invaders_on_patrol = false
				start_coroutine(self.on_detected, self, invader)
			end
		end

		coroutine.yield(nil)
	end

	for i = 1, (self.number_of_invader_per_group * 2) do
		attack_range_renderer_list[i]:Dispose()
		attack_range_renderer_list[i] = nil
	end
	attack_range_renderer_list = nil
end

--endregion

function local_class:reset_magnet_thief_area_setting()
	self.iron_block_jump_count = 0
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)
	local center = field:GetZone(zone_name).Bounds.center

	local out_marker_name = self.magiccircle_out_markers[zone_name]
	local out_marker = field:GetMarker(out_marker_name)

	self.warp_magiccircle = true

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 0, 0.5)
	end

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	local party_dir = ''
	if zone_name == self.magic_circle_passage_zone_1_name then
		party_dir = 'left'
	elseif zone_name == self.magic_circle_passage_zone_2_name then
		party_dir = 'up'
	end

	party_util.position_party(out_marker.position, party_dir, 'linear')

	user_party.Leader:OnEvent(CS.Oak.StateResetEvent.Instance)

	wait_for_sec(0.5)

	for i = 0, user_party.Count - 1 do
		character_util.spine_set_alpha_fade(user_party[i], 1, 0.5)
	end

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion

function local_class:call_flying_iron_block_func(jump_zone_iron_block_num, jump_side_index)

	wait_for_sec(0.3)

	sp_util.play_normal_screenplay(self.flying_metal_block, self, jump_zone_iron_block_num, jump_side_index)
end

-- 점프 타일 밟고 날아가는 철 블럭
function local_class:flying_metal_block(metal_block_index, jump_side_index)
	local metal_block = self.get_metal_block(metal_block_index)

	-- 점프 타일 발동 사운드
	music_player_util.play_sfx_one_shot('03_jumptile_01')

	-- 점프 타일 애니메이션 실행
	local jump_tile = self.get_metal_block_jump_tile(jump_side_index)
	local jump_tile_animator = jump_tile:GetComponent(typeof(CS.UnityEngine.Animator))
	jump_tile_animator.speed = 1.5
	jump_tile_animator:Play('on')

	-- 날아가는 철 블럭
	local time_passed = 0
	local duration = 1
	local start_pos = metal_block.Position
	local end_pos = nil
	local height = 2.5

	end_pos = self.get_iron_block_jump_end_pos()
	if self.iron_block_jump_count > 0 then
		end_pos = vector(end_pos.x + 1, end_pos.y, end_pos.z)
	end

	local shadow = metal_block.transform:Find('scale/shadow (11)')

	if shadow ~= nil then
		shadow.gameObject:SetActive(false)
	end

	-- 날아가는 동안 사운드
	--local blizzard_sound = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true })

	stage.StageCamera:SetTarget(metal_block)

	-- 철 블럭 날아가는 사운드
	music_player_util.play_sfx_one_shot('01_fall_down_01')

	self:move_field_object(metal_block, duration, start_pos, end_pos, height, true)

	-- 점프 타일 애니메이션 되돌리기
	jump_tile_animator:Play('off')

	stage.StageCamera:SetTarget(nil)

	self.get_fx_iron_block_shock():Instantiate(metal_block.Position)

	camera_util.shake(0.3, 0.5)

	wait_for_sec(2)

	camera_util.return_to_leader(1)

	-- 철 블럭 발사 카운트
	self.iron_block_jump_count = self.iron_block_jump_count + 1

	self.iron_block_enter_jump_zone = false
end

function local_class:move_field_object(throw_obj, duration, start_pos, end_pos, height, camera_active)
	local time_passed = 0
	-- 카메라 이동을 실행했는지 체크
	local camera_move_start = false
	local cur_y = 0

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime

		if camera_active then
			if time_passed > 0.2 and not camera_move_start then
				camera_move_start = true
				camera_util.move(end_pos, duration - 0.1)
			end
		end

		local progress = unity_class.mathf.Clamp01(time_passed / duration)

		cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * height

		if cur_y <= 0 then cur_y = 0 end

		throw_obj.Position = unity_class.vector3.Lerp(start_pos, end_pos, progress) + cur_y * unity_class.vector3.up

		-- loop escape
		if self.loop_escape then
			return
		end

		coroutine.yield(nil)
	end
end

-- 감시병 발각시 연출
function local_class:on_detected(detecting_invader)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	for i = 1, (self.number_of_invader_per_group * 2) do
		local invader = self.get_s13_patrol_invader(i)
		character_util.stop(invader)
	end

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')

	party_util.look_at(detecting_invader)
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	character_util.set_anim(detecting_invader, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(detecting_invader, { name = 'attack' })

	music_player_util.play_sfx_one_shot('02_goblin_appear_01')

	speech_bubble_util.show_speech_bubble_async(detecting_invader, { key = self.s13_string_key .. 1, skip = true })

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')
	wait_for_sec(0.5)

	character_util.remove_anim_and_emotion(detecting_invader)
	party_util.remove_emotion()
	party_util.remove_animation()

	self:reset_pos_setting()

	self:detecting_invader_setting()

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false

	field_ui_manager:Show()
	party_util.reset_controllers()

	-- 인베이더들 다시 움직임
	self:s13_patrol_invader_setting(true)

	self.invaders_on_patrol = true
	start_coroutine(self.s13_patrol_invader_detect_process, self)
end

function local_class:reset_pos_setting()
	local leader = get_party_leader()

	-- 플레이어로부터 가장 가까운 리셋 위치를 찾음
	local shortest_dist = 99999
	local reset_marker = nil
	local reset_dir = nil

	for i = 1, #self.get_reset_pos do
		local dist_to_player = (leader.Position - self.get_reset_pos[i].pos).sqrMagnitude
		if shortest_dist > dist_to_player then
			shortest_dist = dist_to_player
			reset_marker = self.get_reset_pos[i].pos
			reset_dir = self.get_reset_pos[i].dir
		end
	end

	party_util.position_party(reset_marker, reset_dir, 'linear')
end

function local_class:detecting_invader_setting()
	-- 인베이더 리셋
	for i = 1, (self.number_of_invader_per_group * 2) do
		local invader = self.get_s13_patrol_invader(i)
		character_util.set_position(invader, self.invader_patrol_first_pos_list[i])

		if i >= 1 and i <= self.number_of_invader_per_group then
			scene_util.set_direction(invader, 'up', false)
		else
			scene_util.set_direction(invader, 'down', false)
		end
	end
end

function local_class:laser_security_update()
	local is_show = true
	local show_time = 1
	local hide_time = 3
	local current_time = 0

	local laser_sound

	while self.playing_laser_security do
		current_time = current_time + unity_class.time.deltaTime

		if is_show then

			if current_time >= show_time then

				for i = 1, #self.laser_security_1_list do
					local laser_security = self.laser_security_1_list[i]
					laser_security.FieldObjectBehaviour.Suspended = true
				end

				for i = 1, #self.laser_security_2_list do
					local laser_security = self.laser_security_2_list[i]
					laser_security.FieldObjectBehaviour.Suspended = true
				end

				current_time = 0
				is_show = false

				if laser_sound then
					laser_sound:Stop()
					laser_sound = nil
				end
			end

		else

			if current_time >= hide_time then

				for i = 1, #self.laser_security_1_list do
					local laser_security = self.laser_security_1_list[i]
					laser_security.FieldObjectBehaviour.Suspended = false
				end

				for i = 1, #self.laser_security_2_list do
					local laser_security = self.laser_security_2_list[i]
					laser_security.FieldObjectBehaviour.Suspended = false
				end

				current_time = 0
				is_show = true

				if self.in_laser_zone then
					laser_sound = music_player_util.play_sfx({ sfx_name = '02_light_loop_03', parent = user_party.Leader })
				end
			end
		end

		coroutine.yield(nil)
	end

	if laser_sound then
		laser_sound:Stop()
		laser_sound = nil
	end
end

function local_class:on_detected_with_cctv(cctv, marker_name)
	party_util.look_at(cctv)
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	music_player_util.play_sfx_one_shot('03_runaway_01')
	music_player_util.play_sfx_one_shot('01_drown_01')

	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 파티 리셋 세팅
	party_util.remove_emotion()
	party_util.remove_animation()

	local reset_marker = field:GetMarker(marker_name)
	party_util.align_party(reset_marker.position, reset_marker.direction, 0, 'linear')

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.playing_detected_event = false
end

function local_class:on_detected_with_laser_security(marker_name)
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	music_player_util.play_sfx_one_shot('03_runaway_01')
	music_player_util.play_sfx_one_shot('01_drown_01')

	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 파티 리셋 세팅
	party_util.remove_emotion()
	party_util.remove_animation()

	local reset_marker = field:GetMarker(marker_name)
	party_util.align_party(reset_marker.position, reset_marker.direction, 0, 'linear')

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.playing_detected_event = false
end

function local_class:stone_board_bomb()
	local stone_board = get_field_object(self.stone_board_name)
	self.get_fx_stone_board_bomb():Instantiate(vector(stone_board.Position.x - 0.5, stone_board.Position.y + 0.5,
			stone_board.Position.z))
	local die_sound = music_player_util.play_sfx({ sfx_name = '01_boss_die_01', parent = stone_board })
	music_player:PlaySfxOneShot('01_boss_die_01')
	stone_board:Shake(0.1, 5)

	wait_for_sec(5)

	if die_sound then
		die_sound:Stop()
	end

	music_player:PlaySfxOneShot('03_rock_break_03')
	music_player:PlaySfxOneShot('01_enhance_light_01')

	character_util.set_active_state(stone_board, 'disabled')
end

function local_class:dispose()

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ResetSwitchTurnedOnEvent))
	message_system:Unsubscribe(self ,typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self ,typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self ,typeof(CS.Oak.PlayerDetectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.Events.StoneBoardDirectingFinishedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CharacterConvertEvent))

	self.loop_escape = true
	self.invaders_on_patrol = false

	if self.magic_circle_passage_effect_1 ~= nil then
		self.magic_circle_passage_effect_1:Dispose()
		self.magic_circle_passage_effect_1 = nil
	end

	if self.magic_circle_passage_effect_2 ~= nil then
		self.magic_circle_passage_effect_2:Dispose()
		self.magic_circle_passage_effect_2 = nil
	end

	self.get_reset_pos = nil
	self.invader_patrol_wp_pos_1_list = nil
	self.invader_patrol_wp_pos_2_list = nil

	if self.mini_game then
		mini_game_manager:DisposeMiniGame(self.game_name)
		self.mini_game = nil
	end

	self.operator_ui_controller = nil
	self.operator_ui_obj = nil

	self.cs_controller = nil
	self.scene = nil
end

--- 오브젝트가 감시 범위에 포함되는지 체크
function local_class:is_in_sight(fo, target, distance, angle)
	if fo == nil then
		return false
	end

	if fo.ActiveState == active_state('disabled') then
		return false
	end

	if fo.FieldObjectStatsBehaviour.IsDead then
		return false
	end

	if target.Position.y >= 1 then
		return false
	end

	local diff = target.Bounds.center - vector_util.get_x0z(fo.Bounds.center)

	if diff.magnitude > distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > angle / 2 then
		return false
	end

	return true
end

--region section_14_dragons_trace
--function local_class:dragons_trace_setting()
--	for i = 1, self.andras_trace_invader_max_count do
--		local andras_invader_pos = self.get_andras_trace_invader_pos(i)
--		local invader_body = self.get_andras_trace_invader_body(i)
--		local invader_head = self.get_andras_trace_invader_head(i)
--		character_util.set_active_state(invader_body, 'enabled')
--		character_util.set_active_state(invader_head, 'enabled')
--		character_util.set_position(invader_body, andras_invader_pos)
--		character_util.set_position(invader_head, andras_invader_pos + vector(0, 1, 0))
--		self.andras_trace_ice_effect_list[i] = self.get_fx_andras_ice():Instantiate(andras_invader_pos)
--
--		scene_util.set_anim_non_loop(invader_body, 'unique/only_body')
--		scene_util.set_anim_non_loop(invader_head, 'unique/only_head')
--
--		-- 오브젝트의 캐릭터 스텟UI 지우기
--		field_ui_manager:RemoveUI(invader_body, CS.Oak.FieldUiType.CharacterStats)
--		field_ui_manager:RemoveUI(invader_head, CS.Oak.FieldUiType.CharacterStats)
--	end
--
--	local pymon_effect_list_index = 1
--	for i = 1, self.pymon_trace_effect_line_count do
--		local line_start_pos = self.get_pymon_trace_effect_pos(i)
--		for j = 1, self.pymon_trace_effect_count_per_line do
--			if i >= self.pymon_effect_line_type.width_1 and i <= self.pymon_effect_line_type.width_2 then
--				self.pymon_trace_fire_effect_list[pymon_effect_list_index] =
--				self.get_fx_pymon_fire_smoke():Instantiate(line_start_pos + vector(j, 0, 0))
--
--				pymon_effect_list_index = pymon_effect_list_index + 1
--			elseif i >= self.pymon_effect_line_type.vertical_1 and i <= self.pymon_effect_line_type.vertical_2 then
--				self.pymon_trace_fire_effect_list[pymon_effect_list_index] =
--				self.get_fx_pymon_fire_smoke():Instantiate(line_start_pos - vector(0, 0, j))
--
--				pymon_effect_list_index = pymon_effect_list_index + 1
--			end
--		end
--	end
--
--	local field_tint_key = 'soot_tint'
--	for k = 1, self.pymon_trace_invader_count do
--		local pymon_invader_pos = self.get_pymon_trace_invader_pos(k)
--		local pymon_invader = self.get_pymon_trace_invader(k)
--		character_util.set_active_state(self.get_pymon_trace_invader(k), 'enabled')
--		character_util.set_position(pymon_invader, pymon_invader_pos)
--		character_util.add_color(pymon_invader, field_tint_key, unity_class.color.black, 1, 0)
--
--		-- 오브젝트의 캐릭터 스텟UI 지우기
--		field_ui_manager:RemoveUI(pymon_invader, CS.Oak.FieldUiType.CharacterStats)
--	end
--
--	character_util.set_direction(self.get_pymon_trace_invader(1), 'left')
--	scene_util.set_anim_non_loop(self.get_pymon_trace_invader(1), 'prostrate')
--	character_util.set_direction(self.get_pymon_trace_invader(2), 'right')
--	scene_util.set_anim_non_loop(self.get_pymon_trace_invader(2), 'prostrate')
--	character_util.set_direction(self.get_pymon_trace_invader(3),'left')
--	scene_util.set_anim_non_loop(self.get_pymon_trace_invader(3), 'prostrate')
--	character_util.set_direction(self.get_pymon_trace_invader(4), 'right')
--	scene_util.set_anim_non_loop(self.get_pymon_trace_invader(4), 'prostrate')
--end
--
--function local_class:enter_andras_trace_zone(bubble_pos)
--	-- 인베이더 병사 : [shout] 제, 제발 살려…!
--	local invader_head = self.get_andras_trace_invader_head(1)
--	speech_bubble_util.show_speech_bubble_async(invader_head,
--			{ key = self.s14_string_key .. 1, skip = false, bubble_type = 'shout', world_pos = bubble_pos + vector(0, 0, -2)})
--end
--
--function local_class:enter_pymon_trace_zone()
--	camera_util.shake(0.15, 0.5)
--
--	-- 파이몬 : [shout] 비켜! 내가 가고싶은 데로 간다!!
--	speech_bubble_util.show_speech_bubble_async(user_party.Leader,
--			{ key = self.s14_string_key .. 2, skip = false, bubble_type = 'shout', screen_pos = vector(100, 0)})
--end
--
--function local_class:dispose_dragons_effect()
--	if self.andras_trace_ice_effect_list == nil and self.pymon_trace_fire_effect_list == nil then
--		return
--	end
--
--	if self.andras_trace_ice_effect_list ~= nil then
--		for i = 1, #self.andras_trace_ice_effect_list do
--			self.andras_trace_ice_effect_list[i]:Dispose()
--			self.andras_trace_ice_effect_list[i] = nil
--		end
--	end
--
--	if self.pymon_trace_fire_effect_list ~= nil then
--		for i = 1, #self.pymon_trace_fire_effect_list do
--			self.pymon_trace_fire_effect_list[i]:Dispose()
--			self.pymon_trace_fire_effect_list[i] = nil
--		end
--	end
--
--	self.andras_trace_ice_effect_list = nil
--	self.pymon_trace_fire_effect_list = nil
--end

--endregion

function local_class:convert_only_assassinate(fo)
	character_util.convert_to_monster(fo)
	fo.DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
	fo.DamagedBehaviour.DeathCount = 1
	fo.DamagedBehaviour.ShowDamageNumber = false
	fo.DamagedBehaviour.ApplyOtherDamage = false
	fo.FieldObjectController.DontFight = true
end

--region 해킹 3번 콘솔 인터렉트
function local_class:hacking_3_console_interact()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local hacking_3_console = self.get_hacking_console_3()
	local console_pos = hacking_3_console.Position + vector(0.5, 0, -0.5)

	party_util.align_party(console_pos, 'down', 1, 'linear')

	local choose_result = choose_util.play_choose_event({
		{ 'qs_main_s14_acting_connect_event_1', 'mercy' }, { 'qs_main_s14_acting_connect_event_2', 'brutal' } })

	if choose_result == 2 then
		self.mini_game_3_play = false
		party_util.reset_controllers()
		field_ui_manager:Show()
		return
	end

	music_player_util.play_stage_music({ state = 'muted' })
	music_player_util.play_sfx_one_shot('01_qte_action_wind_02')
	camera_util.move(user_party.Leader.Position + vector(0, 0, 1), 1, { ignorecameragrids = true })
	camera_util.resize_to(2, 1)

	wait_for_sec(0.5)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	local acting_area = '_s14_c'

	self.mini_game = mini_game_manager:GetOrCreate(self.mini_game_name)

	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.mini_game_name, stage.Name..acting_area, function()
		is_mini_game_load_complete = true
	end)

	-- 미니게임이 로드 다되면
	while not is_mini_game_load_complete do
		coroutine.yield(nil)
	end
	coroutine.yield(nil)

	CS.Oak.MessageSystem.Instance:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stage_4_third_acting_start' }))

	-- 미니게임 시작
	mini_game_manager:StartMiniGame(self.mini_game_name)
end

function local_class:end_mini_game(e)
	if e.Name == self.mini_game_name and self.mini_game_3_play then
		start_coroutine(self.end_mini_game, self, e.Success)
		return true
	end
	return false
end

function local_class:end_mini_game(is_success)

	if self.mini_game ~= nil then
		mini_game_manager:DisposeMiniGame(self.mini_game_name)
		self.mini_game = nil
	end

	music_player_util.play_stage_music({ name = 'ondemand/v2_49_queenship/audio:bgm_queenship_main', state = 'field' })

	if is_success then
		character_util.set_direction(user_party.Leader, 'right', false)
		scene_util.set_anim_loop(user_party.Leader, 'idle')
		scene_util.set_emotion_loop(user_party.Leader, 'attack')

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		camera_util.move_async(self.get_hacking_3_door().Position, 1)

		message_system:PublishSync(CS.Oak.DoorOpenEvent.Create(self.get_hacking_3_door_name, false))
		wait_for_sec(1.5)

		camera_util.return_to_leader(1)

		self:show_crosselle_briefing('qs_hacking_console3_8')

		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		scene_util.set_anim_non_loop(user_party.Leader, 'victory_get')
		scene_util.set_emotion_loop(user_party.Leader, 'smile')
		wait_for_sec(1.5)

		self.get_hacking_console_3().Interactable = CS.Oak.NonInteractable.Instance
	else
		character_util.set_direction(user_party.Leader, 'right', false)
		scene_util.set_anim_loop(user_party.Leader, 'cast')
		scene_util.set_emotion_loop(user_party.Leader, 'damaged')

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		self:show_crosselle_briefing('qs_hacking_console3_6')
	end

	party_util.remove_animation()
	party_util.remove_emotion()
	party_util.reset_controllers()
	field_ui_manager:Show()

	CS.Oak.MessageSystem.Instance:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'stage_4_third_acting_end' }))

	self.mini_game_3_play = false
end

function local_class:show_crosselle_briefing(string_key)
	-- 크로셀 : 보안 시스템 내부 진입 성공.
	self.operator_ui_obj:SetActive(true)
	yield_return_func(self.operator_ui_controller.SetLabelKeyAsync, self.operator_ui_controller,
			string_key, -1, 0.05, 2, nil,
			true, string_key, true, nil, true, true)
	self.operator_ui_obj:SetActive(false)
end
--endregion

function local_class:eat_potion_in_sack(sack)
	start_coroutine(self.consume_item_routine, self, sack, sack.Position)
end

function local_class:generate_store_item_as_drop_item(id, loot_state, pos_to_spawn)
	local item = drop_item_util.create_item(
			{ itemid = id, pos = pos_to_spawn, lootstate = loot_state, notforinven = true, sprscale = 0.929, showoncharacter = true })
	item.SpriteTransform.rotation = unity_class.quaternion.Euler(10, 0, 0)
	return item
end

function local_class:consume_item_routine(sack, init_pos)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true })
	if init_pos.x <= user_party.Leader.Position.x then
		character_util.set_direction(user_party.Leader, 'left')
	else
		character_util.set_direction(user_party.Leader, 'right')
	end
	character_util.set_anim(user_party.Leader, { name = 'eat' })

	wait_for_sec(1)

	local drop_item = self:generate_store_item_as_drop_item(self.position_in_sack_item_num, 'dontfindlooter',
			init_pos)

	--sack.Interactable = CS.Oak.NonInteractable.Instance

	music_player_util.play_sfx_one_shot('01_throw_01')
	music_player_util.play_sfx_one_shot('01_interact_saloon_01')
	drop_item_util.throw_item(drop_item, user_party.Leader.Position + vector(0, 0.5, 0))

	drop_item.Position = vector(888, 0, 888)

	music_player:PlaySfxOneShot('02_magic_heal_01')
	for i = 0, user_party.Count - 1 do
		-- 힐
		local heal_info = CS.Oak.HealInfo()
		local heal_value = math.floor(user_party[i].CharacterStatsBehaviour.MaxHP * self.potion_heal_ratio)
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = heal_value
		heal_info.isRevive = true
		heal_info.sender = user_party[i]
		heal_info.target = user_party[i]

		command_util.execute_heal(heal_info)
	end

	eat_sfx:Stop()
	character_util.remove_anim(user_party.Leader)

	drop_item:ConsumeComplete()

	field_ui_manager:Show()
	party_util.reset_controllers()

	self.interacted = false
end

function local_class:init_main_computer_ani(main_quest_progress)
	local obj = get_field_object('main_computer_object')
	if obj ~= nil then
		if main_quest_progress ~= nil then
			if main_quest_progress.InnerProgress >= 12 and main_quest_progress.InnerProgress <= 14 then
				animator_util.play(obj, 'onvader_idle')
			elseif main_quest_progress.InnerProgress >= 15 then
				animator_util.play(obj, 'invader_idle')
			end
		end
	end
end

function local_class:enable_magnet_reset_switch()
	local magnet_reset_switch = self.get_magnet_reset_switch()
	local dummy = self.get_magnet_reset_switch_dummy()

	magnet_reset_switch.Position = dummy.Position

	dummy.ActiveState = active_state('disabled')
end

function local_class:reset_magnet_in_section_15_zone()
	local reset_1 = get_field_object('key_area_up_side_reset')
	message_system:Publish(CS.Oak.ResetSwitchTurnedOnEvent.Create(reset_1))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
