local local_class = newclass('QueenShip1At3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 공주 가져오기
	self.get_princess = function()
		return get_character('princess')
	end

	-- 순찰 인베이더
	self.get_detecting_invader = function(idx)
		return get_character('detecting_invader_' .. idx)
	end

	self.detecting_invader_num = 9

	-- 대화 중인 인베이더
	self.get_invader = function(idx)
		return get_character('s10_invader_' .. idx)
	end

	-- 메인 퀘스트 InnerProgress가 12일 때부터 활성화되는 전투 인베이더(InnerProgress가 11일 경우, 메인 퀘스트 섹션에서 활성화)
	self.get_deactivated_monster = function(idx)
		return get_character('battle_5_' .. idx)
	end

	-- AMMI 장애물
	self.get_obstacle = function(idx)
		return get_field_object('s11_ammi_chase_obstacle_' .. idx)
	end

	-- 철제 폭탄 화로
	self.get_brazier = function(idx)
		return get_field_object('s10_brazier_' .. idx)
	end

	-- 감시 리셋 마커 가져오기
	self.get_reset_pos = {
		{
			pos = field:GetMarker('exit_5').position,
			dir = 'left'
		},
		{
			pos = field:GetMarker('exit_9').position,
			dir = 'right'
		},
		{
			pos = field:GetMarker('detected_reset_pos_1').position,
			dir = 'down'
		},
		{
			pos = field:GetMarker('detected_reset_pos_2').position,
			dir = 'left'
		}
	}

	-- 인베이더 감시병 발각 플래그
	self.is_detected = false

	-- 인베이더 감시병 발각 커스텀 이벤트 키
	self.detected_event_key = 'qs_detected_key'

	-- 이벤트 존 네임
	self.stage_event_zone_name = 'stage_event_'
	self.ammi_center_event_zone_name = 'ammi_center_zone'
	self.ammi_block_obj_zone_name = 'ammi_block_obj_zone'

	-- 플라즈마 폭탄병 도망 연출 플래그
	-- FIXME: 따로 저장 작업 필요
	self.fugitive_invader_event_flag = true

	-- 단발성 인베이더 이벤트 플래그
	self.invader_onetime_event_1_flag = true
	self.invader_onetime_event_2_flag = true
	self.invader_onetime_event_3_flag = true

	-- 몬스터 스타피스
	self.monster_star_piece_name = 'monster_star_piece'
	self.star_piece_monster_name = 'battle_5_1'
	self.star_piece_npc_name = 's12_invader_1'

	-- AMMI 중앙 4방향 출구 문
	self.ammi_center_exit_door_names = { 'ammi_north_door', 'ammi_east_door', 'ammi_south_door', 'ammi_west_door' }

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- 타임라인 어셋 로드
	timeline_util.load_playable('qs_stage_3_1')
	timeline_util.load_playable('qs_stage_3_2')
	timeline_util.load_playable('qs_main_s10_3')

	self.tint_key = 'qs_stage_3_tint'

	-- ObjectPool
	self.get_fx_star_piece_char = function()
		return unity_object_pool.GetOrCreate('FX_starpiece_in_character')
	end

	self.star_piece_effect_pool_monster = nil
	self.star_piece_effect_pool_npc = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))

	timeline_table.unregister_action('FX_starpiece_in_character')
	timeline_table.unregister_action('release_3d_sound')
	timeline_table.unregister_action('timeline_3d_sound')

	if not is_unity_null(self.cached_star_piece_effect_monster) then
		self.cached_star_piece_effect_monster:Dispose()
		self.cached_star_piece_effect_monster = nil
	end
	if not is_unity_null(self.cached_star_piece_effect_npc) then
		self.cached_star_piece_effect_npc:Dispose()
		self.cached_star_piece_effect_npc = nil
	end
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_got_crashed_event')

	self.get_fx_star_piece_char()
	timeline_table.register_action('invader_npc_star_piece_effect', self.attach_fx_star_piece, self)
	timeline_table.register_action('release_3d_sound', self.release_3d_sound, self)
	timeline_table.register_action('timeline_3d_sound', self.timeline_3d_sound, self)

	-- CCTV HitBox 크기 줄임
	local cctvs = {}
	table.insert(cctvs, get_character('mister_chief_cctv_1'))
	table.insert(cctvs, get_character('mister_chief_cctv_2'))

	for i = 1, #cctvs do
		local cctv = cctvs[i]
		if cctv ~= nil then
			cctv.Hitbox = CS.Oak.Hitbox(vector(0.7, cctv.Hitbox.size.y, 0.7))
		end
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()
	if type_util.is_zone_full_enter(e, leader, self.stage_event_zone_name .. 1) and
			self.invader_onetime_event_1_flag then
		-- 단발성 인베이더 4명 대화 이벤트
		self.invader_onetime_event_1_flag = false
		start_coroutine(self.invader_onetime_event_1, self)
	elseif type_util.is_zone_full_enter(e, leader, self.stage_event_zone_name .. 2) and
			self.invader_onetime_event_2_flag then
		-- 단발성 인베이더 3명 대화 이벤트
		self.invader_onetime_event_2_flag = false
		start_coroutine(self.invader_onetime_event_2, self)
	elseif type_util.is_zone_full_enter(e, leader, 's12_event_3') and
			self.fugitive_invader_event_flag then
		-- 플라즈마 폭탄병 연출
		self.fugitive_invader_event_flag = false
		start_coroutine(self.plasma_bomber_event, self)
	elseif type_util.is_zone_full_enter(e, leader, 's10_event_4') and
			self.invader_onetime_event_3_flag then
		self.invader_onetime_event_3_flag = false
		start_coroutine(self.s10_invader_onetime_event_1, self)
	elseif type_util.is_zone_full_enter(e, leader, self.ammi_center_event_zone_name) then
		local leader_dist = 999
		local target_door_index = 1

		for i = 1, #self.ammi_center_exit_door_names do
			local cur_dist = (
					leader.Position - get_field_object(self.ammi_center_exit_door_names[i]).Position).magnitude

			if cur_dist < leader_dist then
				leader_dist = cur_dist
				target_door_index = i
			end
		end

		message_system:Publish(CS.Oak.DoorCloseEvent.Create(
				self.ammi_center_exit_door_names[target_door_index], false))
	elseif string.find(e.Zone.Name, self.ammi_block_obj_zone_name) then
		-- AMMI 순찰 존 안으로 PushBlock이나 Spike, Holdable Magnet 가져갈 수 없도록 리셋
		if lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.MetalUnitPushableBlockBehaviour) or
				lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.SpikeBehaviour) or
				lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.HoldableObjectBehaviour) then
			message_system:Send(e.FieldObject, CS.Oak.GimmickResetEvent.Instance)
		end
	end
end

function local_class:on_damage_event(e)
	for i = 1, self.detecting_invader_num do
		local cur_invader = self.get_detecting_invader(i)

		if lua_helper.reference_equals(e.Info.target, cur_invader) and
				(e.Info.type == CS.Oak.DamageType.Trap or e.Info.type == CS.Oak.DamageType.Explosion) then
			local damaged_dir = e.Info.direction
			damaged_dir = vector(damaged_dir.x * -2, 0, 0)

			self.get_fx_hit():Instantiate(cur_invader.Position + vector(0, 0.3, 0))
			self.get_fx_lasthit():Instantiate(cur_invader.Position + vector(0, 0.3, 0))

			camera_util.shake(0.1, 0.3)

			character_util.set_anim(cur_invader, { name = 'embarrassed' })
			character_util.set_emotion(cur_invader, { name = 'damaged' })
			character_util.air_spin(cur_invader, { offset = damaged_dir })

			music_player_util.play_sfx_one_shot('02_victim_fly_01')

			break
		end
	end
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_character(self.star_piece_monster_name)) then
		star_piece_util.appear(
				get_field_object(self.monster_star_piece_name), e.FieldObject.Position, get_party_leader().Position)
		if not is_unity_null(self.cached_star_piece_effect_monster) then
			self.cached_star_piece_effect_monster:Dispose()
			self.cached_star_piece_effect_monster = nil
		end
	end
end

function local_class:on_custom_stage_event(e)
	-- waypoint guard 용 발각 이벤트
	if e:GetParamAt(0) == self.detected_event_key and not self.is_detected then
		self.is_detected = true
		start_coroutine(self.on_detected, self, e.Sender)
	end
end

-- 충돌한 guard를 플레이어 바라보게 처리
function local_class:on_got_crashed_event(e)
	for i = 1, self.detecting_invader_num do
		if lua_helper.reference_equals(e.Crash.other, user_party.Leader) and
				lua_helper.reference_equals(e.Crash.self, self.get_detecting_invader(i)) then
			character_util.look_at(e.Crash.self, user_party.Leader)
			return true
		end
	end

	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:pre_setting()
	field:Tint(self.tint_key, unity_class.color.black, 0, 0.3)

	self:brazier_setting()
	self:plasma_bomber_setting()
	self:attach_fx_star_piece()

	-- 감시 인베이더 암살 처리
	for i = 1, self.detecting_invader_num do
		self.get_detecting_invader(i).EntityGroup = CS.Oak.EntityGroups.Enemy0
		self.get_detecting_invader(i).DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
		self.get_detecting_invader(i).DamagedBehaviour.DeathCount = 1
		self.get_detecting_invader(i).DamagedBehaviour.ShowDamageNumber = false
		self.get_detecting_invader(i).DamagedBehaviour.ApplyOtherDamage = false
		self.get_detecting_invader(i).DamagedBehaviour.ApplyAilment = false

		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(self.get_detecting_invader(i), true))
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = self.get_knight()
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

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character({ self.get_princess() })
		self:ammi_hangar_open()
		self:obstacle_pos_setting()
		start_stage_event('right',
				field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 9 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right',
				field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 10 then
		change_leader_character({ self.get_princess() })
		start_stage_event('right',
				field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 11 then
		change_leader_character({ self.get_princess() })
		self:ammi_hangar_open()
		self:obstacle_pos_setting()
		start_stage_event('right',
				field:GetMarker('default_start').position, true, true)
	else
		change_leader_character({ self.get_princess() })
		self:ammi_hangar_open()
		self:obstacle_pos_setting()
		start_stage_event('right',
				field:GetMarker('default_start').position, true, true)
	end

	if main_quest_progress.InnerProgress > 11 or main_quest_progress.IsComplete then
		local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')
		local common_keys = custom_keys.common

		-- 엘리베이터 코어 키 == 1
		local elevator_core_key = common_keys.core_count

		-- 엘리베이터 코어를 얻었는지
		local elevator_core_count = 1

		if stage_progress_util.get_custom_data_int(elevator_core_key, 0) == 0 then
			-- 프로그래스 11 이상이면 엘리베이터 코어 얻은것으로 처리
			stage_progress_util.set_custom_data_async(elevator_core_key, elevator_core_count)

			-- UI 갱신 하도록 이벤트 보냄
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'refresh_resource_ui' }))
		end
	end

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress < 12 then
		for i = 1, 4 do
			character_util.set_active_state(self.get_deactivated_monster(i), 'disabled')
		end
	end
end

-- 인베이더에 스타피스 이펙트 붙이는 함수
function local_class:attach_fx_star_piece(npc)
	local star_piece_invader_monster = get_character(self.star_piece_monster_name)
	local star_piece_invader_npc = get_character(self.star_piece_npc_name)

	if not star_piece_util.has_star_piece(self.monster_star_piece_name) then
		if npc then
			if self.cached_star_piece_effect_npc == nil then
				local star_piece_effect_pool_npc = self.get_fx_star_piece_char()
				self.cached_star_piece_effect_npc = star_piece_effect_pool_npc:Instantiate(star_piece_invader_npc.Position,
						unity_class.quaternion.identity, star_piece_invader_npc.Transform)
			end
		else
			if self.cached_star_piece_effect_monster == nil then
				local star_piece_effect_pool_monster = self.get_fx_star_piece_char()
				self.cached_star_piece_effect_monster = star_piece_effect_pool_monster:Instantiate(star_piece_invader_monster.Position,
						unity_class.quaternion.identity, star_piece_invader_monster.Transform)
			end
		end
	end
end

function local_class:obstacle_pos_setting()
	for idx = 1, 15 do
		self.get_obstacle(idx).Position = vector(999, 0, 999)
	end
end

function local_class:ammi_hangar_open()
	for idx = 1, 2 do
		local animator = get_field_object('s11_ammi_hangar_' .. idx):GetComponent(typeof(CS.UnityEngine.Animator))
		animator:Play('open')
	end
end

function local_class:brazier_setting()
	for i = 1, 2 do
		self.get_brazier(i).Hitbox = CS.Oak.Hitbox(vector(1, 1, 1))
	end
end

-- 감시 인베이더 리셋
function local_class:detecting_invader_setting()
	for i = 1, self.detecting_invader_num do
		message_system:SendSync(self.get_detecting_invader(i), CS.Oak.StateResetEvent.Instance)
	end
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

	camera_util.return_to_leader(0)
end

-- 감시병 발각시 연출
function local_class:on_detected(detecting_invader)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()
	music_player_util.play_sfx_one_shot('03_dialogue_police_01')

	party_util.look_at(detecting_invader)
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	character_util.set_anim(detecting_invader, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(detecting_invader, { name = 'attack' })

	screen_util.fade_out_circular_async(0.5, 'linear')

	character_util.remove_anim_and_emotion(detecting_invader)
	party_util.remove_emotion()
	party_util.remove_animation()

	self:reset_pos_setting()

	self:detecting_invader_setting()

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 단발성 인베이더 4명 대화 이벤트
function local_class:invader_onetime_event_1()
	timeline_util.play_async('qs_stage_3_1', 'qs_stage_3_1')
end

-- 단발성 인베이더 3명 대화 이벤트
function local_class:invader_onetime_event_2()
	timeline_util.play_async('qs_stage_3_2', 'qs_stage_3_2')
end

function local_class:plasma_bomber_setting()
	local plasma_bomber = get_character('plasma_bomber')

	local custom_data = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')

	local is_dead = stage_progress_util.get_custom_data_int(custom_data.common.bomber_dead_default, 0)

	if is_dead == 1 then
		-- 이벤트 발생 비활성화
		self.fugitive_invader_event_flag = false
	else
		character_util.set_active_state(plasma_bomber, 'visible')
		character_util.set_position_from_marker(plasma_bomber, 'plasma_bomber_event_pos')
	end
end

-- 플라즈마 폭탄병 이벤트
function local_class:plasma_bomber_event()
	local plasma_bomber = get_character('plasma_bomber')

	local runaway_sfx = music_player_util.play_sfx({
		sfx_name = '03_runaway_01', play_pos = plasma_bomber.Position, type_priority = 'gimmick', player_priority = 'npc'
	})

	wp_util.move_async(plasma_bomber, { plasma_bomber.Position + vector(0, 0, -7) }, 10,
			nil, { last_direction = 'right', run = true, play_sfx = false })

	runaway_sfx:FadeOut(0.3)

	character_util.set_active_state(plasma_bomber, 'enabled')

	-- 플라즈마 폭탄병 세팅
	local way_list = create_generic_list(CS.System.String)
	way_list:Add('6, 1')
	way_list:Add('0, 2')
	way_list:Add('1, 5, 3')
	way_list:Add('2, 4')
	way_list:Add('3, 5')
	way_list:Add('6, 2, 4')
	way_list:Add('0, 5')

	plasma_bomber.FieldObjectController = CS.Oak.FugitiveCharacterController.Create(way_list, 4, 10, nil)
	plasma_bomber.FieldObjectController.TripSfx = '02_touch_laser_cannon_01'
end

-- 단발성 인베이더 무리 연출
function local_class:s10_invader_onetime_event_1()
	timeline_util.play_async('qs_stage_3_1', 'qs_main_s10_3')
	self.invader_onetime_event_3_flag = true
end

function local_class:release_3d_sound(fo)
	character_util.set_anim(fo, { name = 'release', sfx_name = function()
		music_player_util.play_sfx({
			sfx_name = '01_swing_01', parent = fo, type_priority = 'event', player_priority = 'npc',
		})
	end })
end

function local_class:timeline_3d_sound(fo, sfx_name)
	music_player_util.play_sfx({ sfx_name = sfx_name, parent = fo,
								 type_priority = 'event', player_priority = 'npc', })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
