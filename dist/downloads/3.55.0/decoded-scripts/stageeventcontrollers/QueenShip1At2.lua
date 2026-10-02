local local_class = newclass('QueenShip1At2Controller')

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
	self.get_princess = function() return get_character('princess') end

	-- 안드라스 가져오기
	self.get_andras = function() return get_character('andras') end

	-- 파이몬 가져오기
	self.get_pymon = function() return get_character('pymon') end

	-- 크로셀 가져오기
	self.get_crosselle = function() return get_character('crosselle') end

--region Patrol Invader
	-- 순찰 인베이더
	self.detecting_invaders = {}
	self.detecting_invader_name = 'patrol_invader_'

	-- 감시 리셋 마커
	self.reset_marker_name = 'invader_gatekeeper_reset_'

	-- 인베이더 감시병 발각 플래그
	self.is_detected = false

	-- 인베이더 감시병 발각 커스텀 이벤트 키
	self.detected_event_key = 'detect_by_invader'

	-- 죽이면 특수 이벤트 발생하는 인베이더 리스트
	self.special_event_detecting_invaders = {}

	-- 발각 후에 상태 리셋시킬 인베이더 리스트
	self.reset_state_detecting_invaders = {}

	-- 스타피스 인베이더 제거한 수
	self.eliminate_star_piece_invader_num = 0
--endregion

--region Holdable Key
	-- 이벤트 작동 플래그
	self.deactivated_key_event = false

	-- 대사 실행
	self.is_key_invader_talk = false
	self.key_invader_talk_event_zone_name = 'key_invader_talk'

	-- 자석 작동 플래그
	self.is_magnet_activated = false

	-- 키도어
	self.keydoor_name = 'gatekeeper_keydoor'

	-- 인베이더
	self.key_invader_name = 'patrol_invader_3_2'
	self.notice_invader_name = 'key_detector_'

	-- 키
	self.event_key = nil
	self.key_name = 'gatekeeper_key'
	self.event_key_magnetizable = nil

	-- 자석
	self.magnet_name = 'gatekeeper_key_electric_magnet'
--endregion

--region Link Door Event, Plasma Bomb Check, Magnet Tutorial
	-- 커스텀 스테이지 State
	self.custom_stage_state =
	{
		link_door_green = 5,
		link_door_pink = 6,
		focus_electric_magnet = 7,
		plasma_bomb = 11
	}

	self.link_door_green_custom_state = self.custom_stage_state.link_door_green
	self.link_door_pink_custom_state = self.custom_stage_state.link_door_pink

	self.pink_switch_key = 'pink'
	self.green_switch_key = 'green'
	self.link_door_switch = {
		data = {},
		add_switch_data = function(this, key, name)
			local fo = get_field_object(name)
			local lua_table = fo.FieldObjectBehaviour:GetLuaTable()
			local cur_data = {
				fo = fo,
				lua_table = lua_table,
			}

			this.data[key] = cur_data
		end,
		set_tutorial = function(this, key, is_tutorial)
			if this.data[key] == nil then
				return
			end

			this.data[key].lua_table.is_tutorial = is_tutorial
		end,
		remove_switch_data = function(this, key)
			if this.data[key] ~= nil then
				this.data[key] = nil
			end
		end,
	}

	self.plasma_bomb_custom_state = self.custom_stage_state.plasma_bomb

	self.tutorial_magnet_name = 'magnet_tutorial_electric_magnet'
	self.magnet_tutorial_custom_state = self.custom_stage_state.focus_electric_magnet
--endregion

--region Andras, Pymon Remain Event
	-- 안드라스, 파이몬 희생자들
	self.andras_victim_entrance_name = 'andras_victim_entrance_'
	self.andras_victim_entrance_num = 10

	self.is_exploded_victim = false
	self.andras_victim_name = 'andras_victim_'
	self.andras_victim_num = 11
	self.andras_victim_purple_coin_names = { 'purple_coin_24', 'purple_coin_25' }

	self.pymon_victim_name = 'pymon_victim_'
	self.pymon_victim_num = 8
--endregion

--region Metal Block Push Puzzle
	-- 시작부터 눌려 있는 좌측 문 스위치 처리
	self.puzzle_start_stepped_switch_name = 'plasma_tutorial_left_door_switch'
	self.puzzle_center_metal_box_name = 'plasma_tutorial_center_metal_block'

	-- 연결 시 이벤트 발생하는 전자석
	self.is_electric_event = false
	self.check_electric_event = {}
	self.event_electric_magnet_num = 3
	self.event_electric_magnet_name = 'plasma_tutorial_magnet_'

	-- 중앙 문과 스위치
	self.is_puzzle_center_switch_stepped = false
	self.puzzle_center_switch_name = 'plasma_tutorial_center_door_switch_1'

	self.puzzle_center_door_num = 2
	self.puzzle_center_door_name = 'plasma_tutorial_center_door_'

	-- 예외 처리 스위치
	self.is_on_exception_handling_switch = false
	self.exception_handling_switch_name = 'plasma_tutorial_left_tesla_coil_switch_2'

	-- 플라즈마 폭탄병 존, 다른 물건 가지고 들어올 수 없음
	self.plasma_bomb_block_event_zone_name = 'plasma_bomb_block'
--endregion

--region Shortcut Puzzle
	-- 숏컷 스타피스
	self.is_shortcut_puzzle = false
	self.shortcut_star_piece_name = 'shortcut_star_piece'

	-- 숏컷 Brazier
	self.check_shortcut_switch = { false, false }
	self.shortcut_right_switch_name = 'shortcut_right_switch'
	self.shortcut_left_switch_name = 'shortcut_left_switch'

	-- 숏컷 라디오
	self.shortcut_radio_item_id = 20534
	self.shortcut_radio = nil
	self.shortcut_radio_name = 'shortcut_center_radio'

	self.is_enter_shortcut_radio_zone = false
	self.shortcut_radio_event_zone_name = 'shortcut_radio_zone'
	self.shortcut_radio_effect = nil
	self.shortcut_radio_twinkle_effect = nil

	-- 숏컷 경비병
	self.shortcut_guard_num = 4
	self.shortcut_guard_name = 'patrol_invader_10_'

	-- 완료 이벤트 플래그
	self.enter_shortcut_grid = false
	self.shortcut_entire_zone_name = 'shortcut'
--endregion

	-- 틴트 키
	self.tint_key = 'queenship_1_2'

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- ObjectPool
	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end
	self.get_fx_lasthit = function() return unity_object_pool.GetOrCreate('FX_lasthit') end
	self.get_tesla_effect = function() return unity_object_pool.GetOrCreate('FX_Tesla_Electric_Ray_Idle') end
	self.get_twinkle_effect = function() return unity_object_pool.GetOrCreate('FX_Object_Twinkle') end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent), 'on_tesla_coil_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_got_crashed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	self.get_fx_hit()
	self.get_fx_lasthit()
	self.get_tesla_effect()
	self.get_twinkle_effect()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_stage_start_event(e)
	-- 메인 퀘스트 Progress가 8이상일 때 7에서 사용한 순찰자 인베이더들 없애줌
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 8 then

		for i = 3, 6 do
			local lobby_invader = get_character('lobby_invader_' .. i)
			lobby_invader.FieldObjectController = CS.Oak.NPCCharacterController()
			character_util.set_active_state(cur_invader, 'disabled')
		end

		local inner_patrol_invader_nums = { 1, 2, 3, 4 }
		local inner_patrol_start_num = 6

		for i = 1, #inner_patrol_invader_nums do

			for j = 1, inner_patrol_invader_nums[i] do
				local cur_invader = get_character('patrol_invader_' .. inner_patrol_start_num + i - 1 .. '_' .. j)

				cur_invader.FieldObjectController = CS.Oak.NPCCharacterController()
				character_util.set_active_state(cur_invader, 'disabled')
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and e.Zone.Name == self.plasma_bomb_block_event_zone_name then
		if lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.HoldableObjectBehaviour) or
				lua_helper.type_compare(e.FieldObject.FieldObjectBehaviour, CS.Oak.BombFieldObjectBehaviour) then
			message_system:Send(e.FieldObject, CS.Oak.GimmickResetEvent.Instance)
		end
	end

	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return end
	if not e.FullEnter then return end

	if not self.deactivated_key_event and not self.is_key_invader_talk and
			e.Zone.Name == self.key_invader_talk_event_zone_name then
		self.is_key_invader_talk = true

		if get_character(self.key_invader_name).ActiveState == active_state('enabled') then
			speech_bubble_util.show_speech_bubble(
					get_character(self.key_invader_name), { key = 'qs_stage_1_2_key_event_3' })
		end
	elseif self.is_shortcut_puzzle and not self.is_enter_shortcut_radio_zone
			and e.Zone.Name == self.shortcut_radio_event_zone_name then
		self.is_enter_shortcut_radio_zone = true

		music_player_util.play_stage_music(
				{ name = 'ondemand/v2_49_queenship/audio:bgm_idol_radio', state = 'event', mix = 1 })
	elseif e.Zone.Name == self.shortcut_entire_zone_name then
		self.enter_shortcut_grid = true

		if self.is_shortcut_puzzle then
			start_coroutine(self.radio_jump_event, self)
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return end
	if not e.FullLeave then return end

	if self.is_shortcut_puzzle and self.is_enter_shortcut_radio_zone
			and e.Zone.Name == self.shortcut_radio_event_zone_name then
		self.is_enter_shortcut_radio_zone = false

		music_player_util.play_stage_music({ state = 'field', mix = 1 })
	elseif e.Zone.Name == self.shortcut_entire_zone_name then
		self.enter_shortcut_grid = false
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object(self.shortcut_radio_name)) then
		sp_util.play_normal_screenplay(self.interact_with_radio_event, self)
	end
end

function local_class:on_damage_event(e)
	for i = 1, #self.detecting_invaders do
		local cur_invader = self.detecting_invaders[i]
		local is_kill_invader = false

		if lua_helper.reference_equals(e.Info.target, cur_invader) and
				(e.Info.type == CS.Oak.DamageType.Trap or e.Info.type == CS.Oak.DamageType.Explosion) then
			-- Holdable 키 인베이더 예외
			local key_invader = get_character(self.key_invader_name)

			if lua_helper.reference_equals(cur_invader, key_invader) then
				if not self.deactivated_key_event then
					-- 열쇠 떨어뜨리기
					local hold_target = cur_invader.CharacterBehaviour.CurrentActionState.HoldTarget

					command_util.execute_throw(cur_invader,
							hold_target, direction_util.to_vector3(cur_invader.Direction),
							cur_invader.Position, 3, true)

					self.deactivated_key_event = true

					is_kill_invader = true
				end
			else
				-- 스타피스 인베이더 예외
				for j = 1, #self.special_event_detecting_invaders do
					if lua_helper.reference_equals(self.special_event_detecting_invaders[j], cur_invader) then
						is_kill_invader = true

						self.eliminate_star_piece_invader_num = self.eliminate_star_piece_invader_num + 1

						break
					end
				end
			end

			if is_kill_invader then
				-- 이펙트
				self.get_fx_hit():Instantiate(cur_invader.Position + vector(0, 0.3, 0))
				self.get_fx_lasthit():Instantiate(cur_invader.Position + vector(0, 0.3, 0))

				-- 데미지 보내서 죽임
				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Assassinate
				damage_info.sender = e.Info.sender
				damage_info.target = cur_invader
				damage_info.damage = cur_invader.FieldObjectStatsBehaviour.MaxHP

				command_util.execute_damage(damage_info)
			end

			break
		end
	end

	for i = 1, self.andras_victim_num do
		local cur_invader = get_character(self.andras_victim_name..i)

		if not self.is_exploded_victim and lua_helper.reference_equals(e.Info.target, cur_invader) and
				(e.Info.type == CS.Oak.DamageType.Trap |
						CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick) then
			self.is_exploded_victim = true

			start_coroutine(self.explode_victim_event, self, e)
		end
	end

	for i = 1, #self.special_event_detecting_invaders do
		local cur_invader = self.special_event_detecting_invaders[i]

		local require_damage_type = CS.Oak.DamageType.Assassinate | CS.Oak.DamageType.Melee

		if lua_helper.reference_equals(e.Info.target, cur_invader) and
				e.Info.type & require_damage_type == require_damage_type then
			if lua_helper.reference_equals(cur_invader, get_character(self.key_invader_name)) then
				-- Holdable 키 인베이더 예외
				if not self.deactivated_key_event then
					sp_util.play_normal_screenplay(self.assassinate_key_invader_event, self, cur_invader)
				end
			else
				-- 한 마리만 남은 경우 암살 가능
				if self.eliminate_star_piece_invader_num ~= 3 then
					-- 스타피스 인베이더 예외
					for j = 1, #self.special_event_detecting_invaders do
						if not lua_helper.reference_equals(
								self.special_event_detecting_invaders[j], get_character(self.key_invader_name))
								and not
						lua_helper.reference_equals(self.special_event_detecting_invaders[j], cur_invader) then
							character_util.look_at(self.special_event_detecting_invaders[j], get_party_leader())
						end
					end

					message_system:Publish(CS.Oak.CustomStageEvent.Create(
							self.special_event_detecting_invaders[index], { 'detect_by_invader_1' }))

					table.insert(self.reset_state_detecting_invaders, cur_invader)
				end
			end

			break
		end
	end
end

function local_class:on_switch_on_off_event(e)
	local switch = get_field_object(self.puzzle_center_switch_name)

	if e.IsTurningOn and lua_helper.reference_equals(e.SwitchObject, switch) then
		if not self.is_puzzle_center_switch_stepped then
			self.is_puzzle_center_switch_stepped = true

			sp_util.play_normal_screenplay(self.open_puzzle_center_door_event, self)

			return true
		end
	end

	if not self.is_shortcut_puzzle then
		local shortcut_left_switch = get_field_object(self.shortcut_left_switch_name)
		local shortcut_right_switch = get_field_object(self.shortcut_right_switch_name)

		if lua_helper.reference_equals(e.SwitchObject, shortcut_left_switch) then
			if e.IsTurningOn then
				if not self.check_shortcut_switch[1] then
					self.check_shortcut_switch[1] = true

					if self.check_shortcut_switch[2] then
						sp_util.play_normal_screenplay(self.step_on_shortcut_left_switch_event, self, true)
					else
						sp_util.play_normal_screenplay(self.step_on_shortcut_left_switch_event, self, false)
					end

					return true
				end
			else
				if self.check_shortcut_switch[1] then
					self.check_shortcut_switch[1] = false

					return true
				end
			end
		elseif lua_helper.reference_equals(e.SwitchObject, shortcut_right_switch) then
			if e.IsTurningOn then
				if not self.check_shortcut_switch[2] then
					self.check_shortcut_switch[2] = true

					if self.check_shortcut_switch[1] then
						sp_util.play_normal_screenplay(self.step_on_shortcut_right_switch_event, self, true)
					else
						sp_util.play_normal_screenplay(self.step_on_shortcut_right_switch_event, self, false)
					end

					return true
				end
			else
				if self.check_shortcut_switch[2] then
					self.check_shortcut_switch[2] = false

					return true
				end
			end
		end
	end

	if self.is_electric_event then
		local exception_switch = get_field_object(self.exception_handling_switch_name)

		if lua_helper.reference_equals(e.SwitchObject, exception_switch) then
			if e.IsTurningOn then
				self.is_on_exception_handling_switch = true
			else
				self.is_on_exception_handling_switch = false
			end
		end
	end
end

function local_class:on_tesla_coil_on_off_event(e)
	if stage_progress_util.get_custom_data_int(self.magnet_tutorial_custom_state, 0) == 0 then
		if lua_helper.reference_equals(get_field_object(self.tutorial_magnet_name), e.CoilObject) then
			sp_util.play_normal_screenplay(self.electric_magnet_tutorial_event, self)
		end
	end

	if not self.deactivated_key_event then
		if lua_helper.reference_equals(get_field_object(self.magnet_name), e.CoilObject) then
			if e.IsTurningOn and not self.is_magnet_activated then
				self.is_magnet_activated = true

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.check_magnet, self))
			elseif not e.IsTurningOn and self.is_magnet_activated then
				self.is_magnet_activated = false
			end
		end
	end

	if self.is_electric_event then
		for i = 1, self.event_electric_magnet_num do
			if lua_helper.reference_equals(
					get_field_object(self.event_electric_magnet_name..i), e.CoilObject) then
				if e.IsTurningOn and not self.check_electric_event[i] then
					self.check_electric_event[i] = true

					if i <= 2 then
						start_coroutine(self.electric_magnet_activate_event, self, i)
					end
				end
			end
		end
	end

	local invisible_radio_obj = get_field_object(self.shortcut_radio_name)

	if lua_helper.reference_equals(invisible_radio_obj, e.CoilObject) then
		if e.IsTurningOn then
			if self.shortcut_radio_effect == nil then
				self.shortcut_radio_effect = self.get_tesla_effect():Instantiate(invisible_radio_obj.Position)
			end
		else
			if self.shortcut_radio_effect ~= nil then
				self.shortcut_radio_effect:Dispose()
				self.shortcut_radio_effect = nil
			end
		end
	end
end

function local_class:on_link_door_event(e)
	if stage_progress:GetCustomDataInt(self.link_door_green_custom_state, 0) == 0 then
		if e.LinkDoorTypeName == 'green' then
			if e.IsOpen then
				sp_util.play_normal_screenplay(self.link_door_green_open_event, self)
			end
		end
	end

	if stage_progress:GetCustomDataInt(self.link_door_pink_custom_state, 0) == 0 then
		if e.LinkDoorTypeName == 'pink' then
			if e.IsOpen then
				sp_util.play_normal_screenplay(self.link_door_pink_open_event, self)
			end
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

function local_class:on_custom_stage_event(e)
	-- waypoint guard 발각 이벤트
	local event_name = e:GetParamAt(0)

	if event_name ~= nil and not self.is_detected then
		if string.find(event_name, self.detected_event_key) then
			self.is_detected = true

			local key_idx = tonumber(string.sub(event_name, #event_name, #event_name))

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.detected_event, self, e.Sender, key_idx))
		end
	end
end

-- 충돌한 guard를 플레이어 바라보게 처리
function local_class:on_got_crashed_event(e)
	if lua_helper.reference_equals(e.Crash.other, get_party_leader()) then
		for i = 1, #self.detecting_invaders do
			if lua_helper.reference_equals(e.Crash.self, self.detecting_invaders[i]) then
				character_util.look_at(e.Crash.self, get_party_leader())
				return true
			end
		end
	end

	return false
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

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	self.detecting_invaders = nil
	self.special_event_detecting_invaders = nil
	self.reset_state_detecting_invaders = nil

	self.event_key = nil
	self.event_key_magnetizable = nil

	self.check_electric_event = nil

	self.check_shortcut_switch = nil

	if self.shortcut_radio ~= nil then
		self.shortcut_radio:ConsumeComplete()
		self.shortcut_radio = nil
	end

	if self.shortcut_radio_effect ~= nil then
		self.shortcut_radio_effect:Dispose()
		self.shortcut_radio_effect = nil
	end

	if self.shortcut_radio_twinkle_effect ~= nil then
		self.shortcut_radio_twinkle_effect:Dispose()
		self.shortcut_radio_twinkle_effect = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeslaCoilOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.LinkDoorEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
end

function local_class:pre_setting()
	-- 감시 인베이더 설정
	table.insert(self.detecting_invaders, get_character(self.detecting_invader_name..'1_'..1))

	for i = 1, 4 do
		table.insert(self.detecting_invaders, get_character(self.detecting_invader_name..'2_'..i))

		-- 스타피스 인베이더 특수 이벤트 리스트에 추가
		table.insert(self.special_event_detecting_invaders, get_character(self.detecting_invader_name..'2_'..i))
	end

	for i = 3, 5 do
		local cur_detecting_invader_name = self.detecting_invader_name..i..'_'

		for j = 1, 2 do
			table.insert(self.detecting_invaders, get_character(cur_detecting_invader_name..j))

			-- 열쇠 인베이더 특수 이벤트 리스트에 추가
			if i == 3 and j == 2 then
				table.insert(
						self.special_event_detecting_invaders, get_character(cur_detecting_invader_name..j))
			end
		end
	end

	for i = 1, #self.detecting_invaders do
		self.detecting_invaders[i].EntityGroup = CS.Oak.EntityGroups.Enemy0

		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(self.detecting_invaders[i], true))
	end

	-- Holdable Key 이벤트 설정
	if not get_field_object(self.keydoor_name).FieldObjectBehaviour.Opened then
		self.event_key = get_field_object(self.key_name)
		message_system:Publish(CS.Oak.MagnetManualOnOffEvent.Create(
				self.event_key, magnet_manual_active_state['force_deactivated']))

		self.event_key_magnetizable = self.event_key.Magnetizable
		self.event_key.Magnetizable = CS.Oak.NonMagnetizable.Instance

		command_util.execute_holdup(get_character(self.key_invader_name),
				self.event_key, get_character(self.key_invader_name).Position)
	else
		self.deactivated_key_event = true
	end

	-- 링크 도어 이벤트 설정
	if stage_progress:GetCustomDataInt(self.link_door_green_custom_state, 0) == 0 or
			stage_progress:GetCustomDataInt(self.link_door_pink_custom_state, 0) == 0 then
		message_system:Subscribe(self, typeof(CS.Oak.LinkDoorEvent), 'on_link_door_event')

		if stage_progress:GetCustomDataInt(self.link_door_green_custom_state, 0) == 0 then
			self.link_door_switch:add_switch_data(self.pink_switch_key, '[GIMMICK]linked_switch_1')
			self.link_door_switch:set_tutorial(self.pink_switch_key, true)
		end

		if stage_progress:GetCustomDataInt(self.link_door_green_custom_state, 0) == 0 then
			self.link_door_switch:add_switch_data(self.green_switch_key, '[GIMMICK]linked_switch_2')
			self.link_door_switch:set_tutorial(self.green_switch_key, true)
		end
	end

	-- 안드라스, 파이몬 후폭풍 이벤트 설정
	for i = 1, self.andras_victim_entrance_num do
		local cur_victim = get_character(self.andras_victim_entrance_name..i)
		cur_victim.SpineController:ForceUpdateSpines(0)

		field_ui_manager:RemoveUI(cur_victim, CS.Oak.FieldUiType.CharacterStats)
	end

	for i = 1, self.andras_victim_num do
		local cur_victim = get_character(self.andras_victim_name..i)
		cur_victim.SpineController:ForceUpdateSpines(0)

		field_ui_manager:RemoveUI(cur_victim, CS.Oak.FieldUiType.CharacterStats)
	end

	for i = 1, self.pymon_victim_num do
		local cur_victim = get_character(self.pymon_victim_name..i)
		cur_victim.SpineController:ForceUpdateSpines(0)

		field_ui_manager:RemoveUI(cur_victim, CS.Oak.FieldUiType.CharacterStats)
	end

	-- 시작 시점에서 블록에 눌려 있는 스위치 처리
	local puzzle_start_stepped_switch = get_field_object(self.puzzle_start_stepped_switch_name)
	local puzzle_start_metal_box = get_field_object(self.puzzle_center_metal_box_name)

	message_system:Send(puzzle_start_stepped_switch, CS.Oak.FloorSwitchStepOnEvent.Create(puzzle_start_metal_box))

	-- 숏컷 퍼즐 처리
	local invisible_radio_obj = get_field_object(self.shortcut_radio_name)
	self.shortcut_radio =  drop_item_util.create_item({
		pos = invisible_radio_obj.Position, itemid = self.shortcut_radio_item_id, notforinven = true,
		sprscale = 1, lootstate = 'dontfindlooter' })

	invisible_radio_obj.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1, 0.1, 1))

	self.shortcut_radio_twinkle_effect = self.get_twinkle_effect():Instantiate(invisible_radio_obj.Position)

	if star_piece_util.has_star_piece(self.shortcut_star_piece_name) then
		self.is_shortcut_puzzle = true

		for i = 1, self.shortcut_guard_num do
			local cur_character = get_character(self.shortcut_guard_name..i)

			character_util.set_active_state(cur_character, 'disabled')
		end
	else
		start_coroutine(function()
			drop_item_util.add_color_async(self.shortcut_radio,  unity_color({ 0.3, 0.3, 0.3, 1 }), 0)
		end)
	end

	-- 메인 퀘스트 관련
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

			message_system:Publish(CS.Oak.StageStartEvent.Instance)
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end
	end

	if main_quest_progress ~= nil then
		change_leader_character({ self.get_princess() })

		if main_quest_progress.InnerProgress ~= 6 then
			start_stage_event('right', field:GetMarker('default_start').position,
					true, true)
		else
			message_system:Publish(CS.Oak.StageStartEvent.Instance)
		end

		if main_quest_progress.InnerProgress > 8 then
			local custom_keys = require('Quest/Main/QueenShip/Common/CustomDataKeyConstants.lua')
			local common_keys = custom_keys.common

			-- 플라즈마 폭탄병 처치 여부, 폭탄 수 저장용 커스텀 데이터 키
			local plasma_bomber_dead_custom_key = common_keys.bomber_dead_default
			local plasma_bomb_count_custom_key = common_keys.bomb_count

			if stage_progress_util.get_custom_data_int(plasma_bomber_dead_custom_key, 0) == 0 then
				stage_progress_util.set_custom_data_async(plasma_bomber_dead_custom_key, 1)

				local bomb_count = stage_progress_util.get_custom_data_int(plasma_bomb_count_custom_key, 0)
				stage_progress_util.set_custom_data_async(plasma_bomb_count_custom_key, bomb_count + 1)

				-- UI 갱신 하도록 이벤트 보냄
				message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, {'refresh_resource_ui'}))
			end
		else
			-- 전자석 이벤트 처리 플래그 설정
			self.is_electric_event = true

			for i = 1, self.event_electric_magnet_num do
				table.insert(self.check_electric_event, false)
			end
		end
	end
end

-- 감시병 발각시 연출
function local_class:detected_event(detecting_invader, idx)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	music_player_util.play_sfx_one_shot('03_dialogue_police_01')
	music_player_util.play_sfx_one_shot('03_runaway_01')

	party_util.look_at(detecting_invader)
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	character_util.set_anim(detecting_invader, { name = 'release', sfx_name = '01_swing_01' })
	character_util.set_emotion(detecting_invader, { name = 'attack' })

	wait_for_sec(1)

	screen_util.fade_out_circular_async(0.5, 'linear')

	character_util.remove_anim_and_emotion(detecting_invader)

	self:detecting_invader_setting()

	self:reset_pos_setting(idx)

	party_util.remove_emotion()
	party_util.remove_animation()

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 감시 인베이더 리셋
function local_class:detecting_invader_setting()
	-- 부활시켜줘야 할 감시 인베이더 있다면 부활
	for i = 1, #self.reset_state_detecting_invaders do
		character_util.set_active_state(self.reset_state_detecting_invaders[i], 'enabled')

		-- 힐로 HP 초기화
		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = nil
		heal_info.target = self.reset_state_detecting_invaders[i]
		heal_info.heal = self.reset_state_detecting_invaders[i].FieldObjectStatsBehaviour.MaxHP
		heal_info.isRevive = true

		command_util.execute_heal(heal_info)
	end

	self.reset_state_detecting_invaders = {}

	-- 감시 인베이더 초기화
	for i = 1, #self.detecting_invaders do
		if self.detecting_invaders[i].ActiveState == active_state('enabled') and
				lua_helper.type_compare(
						self.detecting_invaders[i].FieldObjectController, CS.Oak.WayPointGuardCharacterController) then
			message_system:SendSync(self.detecting_invaders[i], CS.Oak.StateResetEvent.Instance)
		end
	end
end

-- 파티원들 리셋
function local_class:reset_pos_setting(idx)
	local reset_pos = field_util.get_marker_pos(self.reset_marker_name..idx)
	local reset_dir = field_util.get_marker_dir(self.reset_marker_name..idx)

	party_util.position_party(reset_pos, reset_dir, 'linear')

	coroutine.yield(nil)

	camera_util.return_to_leader(0)
end

-- 열쇠 인베이더 암살 시 발생하는 이벤트
function local_class:assassinate_key_invader_event(key_invader)
	self.is_detected = true

	local notice_invaders = {}

	for i = 1, 3 do
		table.insert(notice_invaders, get_character(self.notice_invader_name..i))
	end

	music_player_util.play_sfx_one_shot('03_dialogue_police_01')

	field:Tint(self.tint_key, unity_color({ 1, 0, 0, 0.8 }), 1)

	party_util.jump(1, 0.5)

	speech_bubble_util.show_speech_bubble_async(notice_invaders[1],
			{
				key = 'qs_stage_1_2_key_event_4',
				bubble_type = 'shout',
				screen_pos = vector(-50, 250),
				skip = true
			})

	-- 플레이어 위치에 따라 감지 인베이더들의 위치 설정
	local start_pos
	local end_pos
	local mid_x

	if get_party_leader().Position.x < 130.5 then
		start_pos = vector(124.5, 0, get_party_leader().Position.z + 8)
	else
		start_pos = vector(136.5, 0, get_party_leader().Position.z + 8)
	end

	mid_x = start_pos.x

	for i = 1, #notice_invaders do
		character_util.set_anim(notice_invaders[i], { name = 'run' })
		character_util.set_emotion(notice_invaders[i], { name = 'attack' })

		local waypoint_list = create_generic_list(unity_class.vector3)

		if get_party_leader().Position.x < 129 or get_party_leader().Position.x > 132 then
			end_pos = start_pos + vector(0, 0, -7)

			character_util.set_position(
					notice_invaders[i], start_pos + (start_pos - end_pos).normalized * (i - 1))

			waypoint_list:Add(end_pos + vector(0, 0, i - 1))

			character_util.move_waypoint(notice_invaders[i], waypoint_list, 6,
					true, 'stop', 'floor',
					vector_util.to_direction(get_party_leader().Position - end_pos),
					true, 0,
					function(index)
						if index == waypoint_list.Count - 1 then
							character_util.set_anim(notice_invaders[i],
									{ name = 'release', sfx_name = '01_swing_01' })
							character_util.set_emotion(notice_invaders[i], { name = 'attack' })
						end
					end)
		else
			end_pos = start_pos + vector(0, 0, -8)

			character_util.set_position(
					notice_invaders[i], start_pos + (start_pos - end_pos).normalized * (i - 1))

			waypoint_list:Add(end_pos)

			if get_party_leader().Position.x < 130.5 then
				waypoint_list:Add(vector(get_party_leader().Position.x - i, 0, end_pos.z))

				character_util.move_waypoint(notice_invaders[i], waypoint_list, 6,
						true, 'stop', 'floor', 'right',
						true, 0,
						function(index)
							if index == waypoint_list.Count - 1 then
								character_util.set_anim(notice_invaders[i],
										{ name = 'release', sfx_name = '01_swing_01' })
								character_util.set_emotion(notice_invaders[i], { name = 'attack' })
							end
						end)
			else
				waypoint_list:Add(vector(get_party_leader().Position.x + i, 0, end_pos.z))

				character_util.move_waypoint(notice_invaders[i], waypoint_list, 6,
						true, 'stop', 'floor', 'left',
						true, 0, function(index)
							if index == waypoint_list.Count - 1 then
								character_util.set_anim(notice_invaders[i],
										{ name = 'release', sfx_name = '01_swing_01' })
								character_util.set_emotion(notice_invaders[i], { name = 'attack' })
							end
						end)
			end
		end
	end

	wait_for_sec(1.3)

	party_util.look_at(notice_invaders[1])

	wait_for_sec(math.abs(get_party_leader().Position.x - mid_x) / 6)

	music_player_util.play_sfx_one_shot('03_runaway_01')

	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	wait_for_sec(1)

	screen_util.fade_out_circular_async(0.5, 'linear')

	field:RemoveTint(self.tint_key, 0)

	table.insert(self.reset_state_detecting_invaders, key_invader)

	for i = 1, #notice_invaders do
		character_util.set_position(notice_invaders[i], vector(999, 0, 999))
		character_util.remove_anim_and_emotion(notice_invaders[i])
	end

	self:detecting_invader_setting()

	wait_for_sec(0.5)

	command_util.execute_holdup(key_invader, self.event_key, key_invader.Position)

	self:reset_pos_setting(2, false)

	party_util.remove_emotion()
	party_util.remove_animation()

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false
end

-- 자석 범위 내에 키가 들어왔는지 확인
function local_class:check_magnet()
	local magnet = get_field_object(self.magnet_name)
	local magnet_radius = magnet.Magnetizable.MagnetForceRadius

	local invader = get_character(self.key_invader_name)

	while not self.deactivated_key_event and self.is_magnet_activated do
		local dir = magnet.Bounds.center - invader.Position

		if dir.magnitude <= magnet_radius then
			self.deactivated_key_event = true

			sp_util.play_normal_screenplay(self.magnet_key_event, self)

			break
		end

		coroutine.yield(nil)
	end
end

-- 자석 범위 내에 키 들어온 경우 발생하는 이벤트
function local_class:magnet_key_event()
	local invader = get_character(self.key_invader_name)
	invader.FieldObjectController = CS.Oak.NPCCharacterController()
	invader.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance

	camera_util.move_async(invader.Position, 1)

	wait_for_sec(0.5)

	local magnet = get_field_object(self.magnet_name)

	command_util.execute_throw(invader, self.event_key, (magnet.Position - invader.Position).normalized,
			invader.Position, 0.1, true)

	wait_for_sec(0.5)

	self.event_key.Magnetizable = self.event_key_magnetizable

	character_util.jump(invader, 1, 0.5)
	character_util.remove_anim(invader)
	character_util.set_emotion(invader, { name = 'attack' })

	wait_for_sec(1)

	character_util.set_anim(invader, { name = 'cast' })
	character_util.set_emotion(invader, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(invader,
			{ key = 'qs_stage_1_2_key_event_1', skip = true })

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('03_runaway_01')

	character_util.jump(invader, 1, 0.5)
	character_util.set_anim(invader, { name = 'embarrassed' })
	character_util.set_emotion(invader, { name = 'damaged' })

	speech_bubble_util.show_speech_bubble_async(invader,
			{ key = 'qs_stage_1_2_key_event_2', bubble_type = 'shout', skip = true })

	character_util.set_anim(invader, { name = 'run' })

	character_util.move_to_async(invader, vector(136.5, 0, invader.Position.z),
			nil, 6, true, false, true)

	character_util.move_to_async(invader, invader.Position + vector(0, 0, 8),
			nil, 6, true, false, true)

	character_util.set_position(invader, vector(999, 0, 999))
	character_util.remove_anim_and_emotion(invader)

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })
end

-- 전자석 튜토리얼 이벤트
function local_class:electric_magnet_tutorial_event()
	camera_util.move_async(get_field_object(self.tutorial_magnet_name).Position, 1)

	wait_for_sec(2)

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })

	stage_progress_util.set_custom_data_async(self.magnet_tutorial_custom_state, 1)
end

-- 초록 링크 도어 튜토리얼 이벤트
function local_class:link_door_green_open_event()
	if stage_progress:GetCustomDataInt(self.link_door_green_custom_state) == 0 then
		stage_progress_util.set_custom_data_async(self.link_door_green_custom_state, 1)
	end

	camera_util.move_async(vector(196, 0, 2), 1)

	wait_for_sec(2)

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })

	self.link_door_switch:set_tutorial(self.green_switch_key, false)
	self.link_door_switch:remove_switch_data(self.green_switch_key)
end

-- 핑크 링크 도어 튜토리얼 이벤트
function local_class:link_door_pink_open_event()
	if stage_progress:GetCustomDataInt(self.link_door_pink_custom_state) == 0 then
		stage_progress_util.set_custom_data_async(self.link_door_pink_custom_state, 1)
	end

	camera_util.move_async(vector(196, 0, 4), 1)

	wait_for_sec(2)

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })

	self.link_door_switch:set_tutorial(self.pink_switch_key, false)
	self.link_door_switch:remove_switch_data(self.pink_switch_key)
end

-- 플라즈마 폭탄병 퍼즐 가운데 문 열리는 이벤트
function local_class:open_puzzle_center_door_event()
	local metal_box = get_field_object(self.puzzle_center_metal_box_name)

	camera_util.move(metal_box.Position, 1, { target = metal_box, end_target = metal_box })

	wait_for_sec(1)

	for i = 1, self.puzzle_center_door_num do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.puzzle_center_door_name..i, false))
	end

	wait_for_sec(5)

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })
end

-- 전자석 활성화 이벤트
function local_class:electric_magnet_activate_event(start_index)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local metal_box = get_field_object(self.puzzle_center_metal_box_name)

	camera_util.move(metal_box.Position, 1, { target = metal_box, end_target = metal_box })

	wait_for_sec(4)

	-- 2번 스위치를 눌렀는데 3번에 이미 불 켜진 경우, 3번 이벤트로 넘어감
	local interrupt = false

	if start_index == 2 and
			self.is_on_exception_handling_switch and
			not self.is_puzzle_center_switch_stepped then
		interrupt = true

		-- 3번 테슬라 코일 켜진 타이밍 정확히 맞춰서 코루틴 종료
		while not self.check_electric_event[3] do
			-- 원인 불명의 문제로 스위치 눌린 상태가 해제될 수 있으니 체크해서 이벤트 다시 진행
			if not self.is_on_exception_handling_switch then
				interrupt = false

				break
			end

			coroutine.yield(nil)
		end
	end

	if not interrupt then
		camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })

		field_ui_manager:Show()
		party_util.reset_controllers()
	end
end

-- 숏컷 라디오 상호작용 이벤트
function local_class:interact_with_radio_event()
	if self.is_shortcut_puzzle then
		field_ui_util.show_narration_async( { key = 'qs_stage_1_2_vampireidol_4' } )
	else
		field_ui_util.show_narration_async( { key = 'qs_stage_1_2_vampireidol_3' } )
	end
end

-- 숏컷 좌측 테슬라 코일 스위치 누르면 나오는 이벤트
function local_class:step_on_shortcut_left_switch_event(complete)
	local invisible_radio_obj = get_field_object(self.shortcut_radio_name)

	camera_util.move_async(invisible_radio_obj.Position, 2)

	if complete then
		self:activate_radio_event()
	else
		music_player_util.play_sfx_one_shot('02_spark_01')

		drop_item_util.shake(self.shortcut_radio, nil, 0.04, 1)
		drop_item_util.add_color_async(self.shortcut_radio,  unity_color({ 0.6, 0.6, 0.6, 1 }), 1)

		wait_for_sec(1)

		camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })
	end
end

-- 숏컷 우측 테슬라 코일 스위치 누르면 나오는 이벤트
function local_class:step_on_shortcut_right_switch_event(complete)
	local invisible_radio_obj = get_field_object(self.shortcut_radio_name)

	camera_util.move_async(invisible_radio_obj.Position, 2)

	if complete then
		self:activate_radio_event()
	else
		music_player_util.play_sfx_one_shot('02_spark_01')

		drop_item_util.shake(self.shortcut_radio, nil, 0.04, 1)
		drop_item_util.add_color_async(self.shortcut_radio,  unity_color({ 0.6, 0.6, 0.6, 1 }), 1)

		wait_for_sec(1)

		camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })
	end
end

-- 숏컷 라디오 활성화되는 이벤트
function local_class:activate_radio_event()
	music_player_util.play_sfx_one_shot('02_lightning_strike_02')

	drop_item_util.shake(self.shortcut_radio, nil, 0.04, 1)
	drop_item_util.add_color_async(self.shortcut_radio,  unity_color({ 1, 1, 1, 1 }), 1)

	start_coroutine(self.radio_jump_event, self)

	music_player_util.play_stage_music(
			{ name = 'ondemand/v2_49_queenship/audio:bgm_idol_radio', state = 'event', mix = 2 })

	wait_for_sec(1)

	local cur_invader_list = create_generic_list(CS.Oak.Character)

	for i = 1, self.shortcut_guard_num do
		local cur_character = get_character(self.shortcut_guard_name..i)

		cur_character.FieldObjectController = CS.Oak.NPCCharacterController()

		local death_type = cur_character.DamagedBehaviour.DeathType
		local damage_type_list = create_generic_list(CS.Oak.DamageType)
		damage_type_list:Add(CS.Oak.DamageType.Explosion)
		damage_type_list:Add(CS.Oak.DamageType.AffectGimmick)
		damage_type_list:Add(CS.Oak.DamageType.Trap)

		local new_damaged_behaviour = CS.Oak.NpcDeadDamagedBehaviour.Create(death_type, damage_type_list)
		cur_character.DamagedBehaviour = new_damaged_behaviour

		local x_diff
		local z_diff

		if i <= 2 then
			x_diff = -1.5 + i
			z_diff = 1
		else
			x_diff = -3.5 + i
			z_diff = -1
		end

		local waypoint_list = create_generic_list(unity_class.vector3)
		waypoint_list:Add(vector(
				self.shortcut_radio.Position.x + x_diff, 0, cur_character.Position.z))
		waypoint_list:Add(vector(
				self.shortcut_radio.Position.x + x_diff, 0, self.shortcut_radio.Position.z + z_diff))

		local last_dir = 'down'

		if i > 2 then
			last_dir = 'up'
		end

		character_util.move_waypoint(cur_character, waypoint_list,
				2, false, 'stop', 'floor', last_dir)

		cur_invader_list:Add(cur_character)

		wait_for_sec(0.4)
	end

	while true do
		local end_count = 0
		for _, character in pairs(cur_invader_list) do
			if character.FieldObjectBehaviour.CurrentAction == CS.Oak.FieldObjectAction.Stopped then
				end_count = end_count + 1
			end
		end

		if end_count == cur_invader_list.Count then
			break
		end

		end_count = 0

		coroutine.yield(nil)
	end

	for i = 0, cur_invader_list.Count - 1 do
		character_util.set_anim(cur_invader_list[i], { name = 'sing' })
		character_util.set_emotion(cur_invader_list[i], { name = 'smile' })
	end

	speech_bubble_util.show_speech_bubble_async(cur_invader_list[2],
			{ key = 'qs_stage_1_2_vampireidol_1', skip = true })

	speech_bubble_util.show_speech_bubble_async(cur_invader_list[1],
			{ key = 'qs_stage_1_2_vampireidol_2', skip = true })

	wait_for_sec(1)

	camera_util.move(get_party_leader().Position, 1, { end_target = get_party_leader() })

	wait_for_sec(0.5)

	music_player_util.play_stage_music({ state = 'field', mix = 1 })

	wait_for_sec(0.5)

	self.is_shortcut_puzzle = true
end

-- 숏컷 라디오 점프 이벤트
function local_class:radio_jump_event()
	local radio_transform = self.shortcut_radio.SpriteTransform
	local radio_transform_y_mod = 1.3

	local invisible_radio_obj = get_field_object(self.shortcut_radio_name)
	local start_hitbox_size_y = 0.1
	local hitbox_size_mod = 1.2

	local origin_pos = self.shortcut_radio.Position
	local start_effect_y = 0
	local effect_y_mod = 1.3

	local timer = 0
	local duration = 0.6

	while self.enter_shortcut_grid do
		timer = timer + unity_class.time.deltaTime
		local progress = timer / duration

		radio_transform.localPosition = vector(
				0, math.max(math.sin(math.pi * progress) * radio_transform_y_mod, 0), 0)

		local cur_hitbox_size = start_hitbox_size_y + math.max(
				math.sin(math.pi * progress) * hitbox_size_mod, 0)
		invisible_radio_obj.Hitbox = CS.Oak.Hitbox(
				vector(0.5, 0, 0.5), vector(1, cur_hitbox_size, 1))

		if self.shortcut_radio_effect ~= nil then
			local effect_transform = self.shortcut_radio_effect.transform

			local cur_y = start_effect_y + math.max(math.sin(math.pi * progress) * effect_y_mod, 0)
			effect_transform.localPosition = origin_pos + vector(0, cur_y, 0)
		end

		if timer >= duration then
			timer = 0
		end

		coroutine.yield(nil)
	end
end

-- 안드라스 희생자 더미 폭발 이벤트
function local_class:explode_victim_event(damage_event)
	for i = 1, self.andras_victim_num do
		local cur_invader = get_character(self.andras_victim_name..i)
		local dir = (cur_invader.Position - damage_event.Info.sender.Position).normalized

		character_util.spine_damage_red_pulse(cur_invader)
		character_util.spine_damage_squish_default(cur_invader)
		character_util.air_spin(cur_invader, { offset = dir })
	end

	for i = 1, #self.andras_victim_purple_coin_names do
		if not stage_progress:HasPurpleCoin(self.andras_victim_purple_coin_names[i]) then
			local purple_coin = get_field_object(self.andras_victim_purple_coin_names[i])
			message_system:SendSync(purple_coin, CS.Oak.PurpleCoinAppearEvent.Instance)
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
