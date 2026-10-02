local local_class = newclass('DemonShire3At1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end
	self.rescue_push_block = function(idx)
		return get_field_object('rescue_push_block_' .. idx)
	end
	self.rescue_tesla_block = function(idx)
		return get_field_object('rescue_push_tesla_' .. idx)
	end
	self.rescue_reset_switch = function(idx)
		return get_field_object('rescue_reset_switch_' .. idx)
	end
	self.rescue_push_block_pos = function(wp_idx)
		return field:GetMarker('rescue_block_pos_' .. wp_idx).position
	end
	self.rescue_push_tesla_pos = function(wp_idx)
		return field:GetMarker('rescue_tesla_pos_' .. wp_idx).position
	end
	self.get_fx_reset = function()
		return unity_object_pool.GetOrCreate('FX_reset_object')
	end
	-- 소히 가져오기
	self.get_sohee = function() return get_character('sohee') end

	-- 백작 딸 가져오기
	self.get_count_daughter = function() return get_character('count_daughter') end

	-- 소히가 부셨던 감옥 문
	self.get_prison_door = function() return get_field_object('prison_door_1') end

	-- 메인 퀘스트 id
	self.main_quest_id = 286

	self.get_homeless = function(index) return get_character('s18_homeless_' .. index) end

	self.get_homeless_waypoint = function(homeless_num, index)
		return field:GetMarker('s18_homeless_waypoint_' .. homeless_num .. '_' .. index).position
	end

	self.get_switch = function(index) return get_field_object('s18_switch_' .. index) end
	self.get_brazier = function(index) return get_field_object('s18_brazier_' .. index) end

	-- 화로에 불이 켜져 있는지
	self.on_brazier = { false, false, false, false }

	-- 스위치가 눌려 있는지
	self.on_switch = { false, false, false, false }

	-- 노숙자 데이터
	self.homeless_data = {}

	-- 문 이름
	self.down_door_name = 's18_down_door_'
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BrazierOnOffEvent), 'on_brazier_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_hold_up_event')
	message_system:Subscribe(self, typeof(CS.Oak.ThrowEvent), 'on_throw_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	self.get_fx_reset()
	if main_quest_progress.InnerProgress >= 17 then
		self.get_prison_door().ActiveState = active_state('disabled')
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pre_setting, self))
end

function local_class:dispose()
	self.cs_controller = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BrazierOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ThrowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
end

function local_class:on_event(e)

	return false
end

function local_class:on_switch_event(e)
	if lua_helper.reference_equals(e.SwitchObject, self.rescue_reset_switch(2)) then
		self:rescue_push_block_reset()
	elseif lua_helper.reference_equals(e.SwitchObject, self.rescue_reset_switch(3)) then
		self:rescue_tesla_block_reset(2)
	elseif lua_helper.reference_equals(e.SwitchObject, self.rescue_reset_switch(4)) then
		self:rescue_tesla_block_reset(1)
	end

	for i = 1, 4 do
		local switch = self.get_switch(i)
		if self.start_puzzle and lua_helper.reference_equals(e.SwitchObject, switch) then

			if e.IsTurningOn then
				self.on_switch[i] = true
			else
				self.on_switch[i] = false
			end

			return true
		end
	end

	return false
end


function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 304101
	if user_util.has_knight_male() then
		character_spec_id = 304100
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateStoryCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if not self.start_puzzle and type_util.is_zone_full_enter(e, user_party.Leader, 'start_homeless_puzzle') then

		self.start_puzzle = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.puzzle_manager, self))
		return true
	end

	return false
end

--- HoldUpEvent
function local_class:on_hold_up_event(e)
	for i = 1, #self.holdable_homeless_npc do
		if lua_helper.reference_equals(e.Holder, user_party.Leader) and
			lua_helper.reference_equals(e.Target, self.holdable_homeless_npc[i]) then

			-- 으후… 추워… 음냐, 음냐…
			speech_bubble_util.show_speech_bubble(self.holdable_homeless_npc[i],
				{ key = 'ds_main_s18_26', type_speed = 0 })

			return true
		end
	end

	return false
end

--- BrazierOnOffEvent
function local_class:on_brazier_on_off_event(e)
	for i = 1, 2 do
		if e.IsTurningOn and lua_helper.reference_equals(e.BrazierObject, self.get_brazier(i)) then
			self.on_brazier[i] = true
			return true
		end
	end

	return false
end

--- ThrowEvent
function local_class:on_throw_event(e)
	for i = 1, #self.holdable_homeless_npc do
		if lua_helper.reference_equals(e.Target, self.holdable_homeless_npc[i]) then
			self.homeless_data[self.holdable_homeless_npc[i]].on_action = false
			return true
		end
	end

	return false
end

--- StageLoadedEvent
function local_class:on_stage_loaded_event(_)
	self:npc_setting()
	return false
end

function local_class:npc_setting()
	local homeless_2 = self.get_homeless(2)
	local homeless_3 = self.get_homeless(3)

	homeless_2.Hitbox = CS.Oak.Hitbox(vector(1, 1, 1))
	homeless_3.Hitbox = CS.Oak.Hitbox(vector(1, 1, 1))

	homeless_2.Holdable = CS.Oak.Holdable()
	homeless_3.Holdable = CS.Oak.Holdable()

	-- 들 수 있는 npc
	self.holdable_homeless_npc = {
		homeless_2,
		homeless_3
	}

	self.homeless_data[homeless_2] = {
		waypoint = {
			self.get_homeless_waypoint(2, 1),
			self.get_homeless_waypoint(2, 2),
			self.get_homeless_waypoint(2, 3)
		},
		last_dir = 'right',
		on_action = false
	}

	self.homeless_data[homeless_3] = {
		waypoint = {
			self.get_homeless_waypoint(3, 1),
			self.get_homeless_waypoint(3, 2)
		},
		last_dir = 'left',
		on_action = false
	}
end

function local_class:pre_setting()
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

	-- 퀘스트정보가 없거나 클리어 했다면 기본 위치에서 시작
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		change_leader_character()
		start_stage_event('down', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 16 then
		change_leader_character()
		start_stage_event('down', field:GetMarker('s17_start_pos').position, false, true)
	elseif main_quest_progress.InnerProgress == 17 then
		change_leader_character({ self.get_sohee() })
		start_stage_event('down', field:GetMarker('default_start').position, true, true)
	else
		change_leader_character()
		start_stage_event('down', field:GetMarker('default_start').position, true, true)
	end
end

function local_class:portal_reset()
	local portal_cube = get_field_object('red_portal_1')
	message_system:SendSync(portal_cube, CS.Oak.GimmickResetEvent.Instance)
end

function local_class:rescue_push_block_reset()
	local push_block = {}
	for num = 1, 5 do
		push_block = self.rescue_push_block(num)
		push_block.Position = self.rescue_push_block_pos(num)
		self.get_fx_reset():Instantiate(push_block.Position)
	end
end

function local_class:rescue_tesla_block_reset(id)
	if id == 1 then
		local tesla_1 = self.rescue_tesla_block(1)
		tesla_1.Position = self.rescue_push_tesla_pos(1)
		self.get_fx_reset():Instantiate(tesla_1.Position)

	elseif id == 2 then
		local tesla_2 = self.rescue_tesla_block(2)
		tesla_2.Position = self.rescue_push_tesla_pos(2)
		self.get_fx_reset():Instantiate(tesla_2.Position)

	end
end

--- 퍼즐 매니저
function local_class:puzzle_manager()
	-- 모든 스위치가 눌렸는지
	local on_all_switch

	-- 기획 변경으로 사용 안 하게 됐지만 나중에 필요할 수도 있어서 남겨둠
	-- 버튼을 누르고 있어야 되는 시간
	local door_open_duration = 0

	local door_open_time_passed = 0

	local switch_pos_table = {}
	for i = 1, 4 do
		local switch = self.get_switch(i)
		table.insert(switch_pos_table, switch.Position)
	end

	while true do
		on_all_switch = true

		-- 스위치 검사
		for _, value in pairs(self.on_switch) do
			if not value then
				on_all_switch = false
				break
			end
		end

		-- 모든 스위치가 다 눌리고 불이 전부 켜졌을 때
		if on_all_switch then
			door_open_time_passed = door_open_time_passed + unity_class.time.deltaTime

			-- 1.5초가 지나면 문이 열림
			if not self.is_open_door and door_open_duration < door_open_time_passed then

				self.is_open_door = true

				message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.down_door_name .. 1, false))
				message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.down_door_name .. 2, false))
			end

		else
			door_open_time_passed = 0
		end

		-- 스위치와 노숙자 충돌 체크
		for _, homeless in pairs(self.holdable_homeless_npc) do

			-- 노숙자가 어떤 행동 중이면 체크 안 함
			if not self.homeless_data[homeless].on_action then
				-- 노숙자 히트 박스 강제로 변경했음 (내부 바운드 체크를 위해)
				local homeless_bounds = {
					min = homeless.Position + vector(-0.5, 0, -0.5),
					max = homeless.Position + vector(0.5, 0, 0.5),
				}

				-- 4개의 스위치 검사
				for switch_index, switch_pos in pairs(switch_pos_table) do
					local switch_bounds = {
						min = switch_pos + vector(-0.25, 0, -0.25),
						max = switch_pos + vector(0.25, 0, 0.25),
					}

					-- 현재 눌려있는 스위치만 계산
					-- 노숙자 y포지션 0일 때
					-- 바운드 충돌 체크
					if self.on_switch[switch_index] and homeless.Position.y <= constants.epsilon and
						not (math.abs(self:get_overlapped_xz_area(homeless_bounds, switch_bounds)) < constants.epsilon) then

						self.homeless_data[homeless].on_action = true

						if self.on_brazier[switch_index] then
							speech_bubble_util.remove_bubble(homeless)

							music_player_util.play_sfx_one_shot('01_bad_fairy_01')
							-- 음냐, 음냐… 아이고 뜨뜻하다…
							speech_bubble_util.show_speech_bubble(homeless, { key = 'ds_main_s18_28' })

						else
							-- 불이 꺼져 있을 때 노숙자 행동
							coroutine_manager:StartCoroutine(stage.StageGameObject,
								util.cs_generator(self.angry_homeless_action, self, homeless))
						end
					end
				end
			end
		end

		coroutine.yield(nil)
	end
end

--- 내부 바운드 충돌 체크
function local_class:get_overlapped_xz_area(bounds1, bounds2)
	local min_x = math.max(bounds1.min.x, bounds2.min.x)
	local min_z = math.max(bounds1.min.z, bounds2.min.z)
	local max_x = math.min(bounds1.max.x, bounds2.max.x)
	local max_z = math.min(bounds1.max.z, bounds2.max.z)

	return math.max(0, max_x - min_x) * math.max(0, max_z - min_z)
end

--- 불이 안 켜져있을 때 노숙자 액션
function local_class:angry_homeless_action(homeless)
	character_util.stop(homeless)
	homeless.Holdable = CS.Oak.NonHoldable.Instance
	speech_bubble_util.remove_bubble(homeless)
	character_util.remove_anim_and_emotion(homeless)

	character_util.set_direction(homeless, 'down')
	character_util.set_emotion(homeless, { name = 'mad' })
	character_util.normal_jump(homeless, '01_player_jump_01')
	wait_for_sec(0.7)

	-- 스위치 옆으로 한칸 이동
	local move_vector
	if self.homeless_data[homeless]['waypoint'][1].x < homeless.Position.x then
		move_vector = vector(-1, 0, 0)
	else
		move_vector = vector(1, 0, 0)
	end

	homeless.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	character_util.move_waypoint_async(homeless, homeless.Position + move_vector, 4)

	character_util.set_anim(homeless, { name = 'release', sfx_name = '01_swing_01' })
	music_player_util.play_sfx_one_shot('02_boss_sapa_shout_01')
	-- 잠도 못 자게 이게 무슨 짓이야!
	speech_bubble_util.show_speech_bubble_async(homeless, { key = 'ds_main_s18_27' })

	character_util.remove_anim_and_emotion(homeless)

	-- 원래 위치로 돌아감
	local waypoint = {
		vector(homeless.Position.x, 0, self.homeless_data[homeless]['waypoint'][1].z)
	}

	for i = 2, #self.homeless_data[homeless].waypoint do
		table.insert(waypoint, self.homeless_data[homeless]['waypoint'][i])
	end

	local last_dir = self.homeless_data[homeless].last_dir
	character_util.move_waypoint_async(homeless, waypoint, 4, false, nil, nil, last_dir)

	-- 세팅 초기화
	character_util.set_emotion(homeless, { name = 'sleep' })
	character_util.set_anim(homeless, { name = 'sleep' })
	homeless.OverrideCrashBehaviour = nil
	homeless.Holdable = CS.Oak.Holdable()
	self.homeless_data[homeless].on_action = false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
