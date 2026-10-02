local local_class = newclass('LaboseWindPotController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.button_icon_name = 'actbtn_ic_ar_gravitygun.png'
	self.weapon_name = 'gravity_gun_2'
	self.xz_adder = 0.5

	self.player_state = {
		labose_zone_enter = false,
		wind_pot_launch = false,
		slow = false
	}
	self.player_emotion = 'idle'

	self.labose_tiles = {}
	self.labose_respawn_tiles = {}
	self.zone_list = {}
	self.entered_zone_list = create_lua_hashset()
	self.damage_sender = nil

	self.is_tutorial = false
	self.is_labose_collision_routine_end = false
	self.is_first_damage = false
	self.is_stage_end = false

	self.labose_active_state = true
	self.labose_load_complete = false
	self.damage_time_passed = 0

	self.is_labose_sfx_playing = false
	self.labose_sfx = nil

	self.button = nil
	self.button_active = false

	-- 바람 항아리 버튼 쿨타임 표시를 위한 회색 칼라 값
	self.button_gray_color = { 96 / 255, 96 / 255, 96 / 255, 1 }
	self.can_touch_button = true
	self.respawn_routine_check = true

	-- 쥐폭탄
	self.mouse_bombs = {}

	-- fx
	self.fx = {
		vacuum_wind_out = function()
			return unity_object_pool.GetOrCreate('fx_lw_vacuum_wind_out')
		end,
		virus_fog_weak = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_weak')
		end,
		virus_fog_weak_end = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_weak_end')
		end,
		virus_fog_weak_end_ice = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_weak_end_ice')
		end,
		virus_fog_strong = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong')
		end,
		virus_fog_strong_end = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong_end')
		end,
		virus_fog_strong_end_ice = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong_end_ice')
		end,
		virus_fog_weak_bug = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_weak_bug')
		end,
		virus_fog_strong_bug = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_strong_bug')
		end,
		virus_explosion = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_death_explosion')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil

	self.labose_tiles = nil
	self.labose_respawn_tiles = nil
	self.zone_list = nil
	self.entered_zone_list:clear()

	if self.use_wind_pot then
		self.button:ToggleIconTintChange(true)
	end

	self.sp_manager = nil

	self.labose_sfx = nil
	self.is_labose_sfx_playing = nil

	self.is_stage_end = true

	if self.damage_sender ~= nil then
		self.damage_sender:Dispose()
	end

	self.damage_sender = nil

	self.mouse_bombs = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	self.fx:load_all()
	yield_return(unity_object_pool, 'WaitAll')

	if not self.labose_load_complete and self.labose_active_state then
		self:load_data()
		self:load_mouse_bombs()
	end
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

function local_class:load_data()
	local data = get_or_create_global_variable('Quest/Main/LaboseWorld/Common/LaboseWindPotConstants.lua')
	self.wind_pot_bounds_size = data.wind_pot.bounds_size
	self.wind_pot_delay = data.wind_pot.delay
	self.labose_respawn_time = data.labose.respawn_time
	self.wind_spreads_time = data.wind_pot.wind_spreads_time
	self.bug_effect_time = data.labose.bug_effect_time
	self.damage_delay = data.labose.damage.delay_time
	self.damage_rate = data.labose.damage.rate
	self.damage_term = data.labose.damage.term
	self.decrease_speed_rate = data.labose.decrease_speed_rate
	self.sfx = data.labose.sfx

	if data[stage.Name] == nil then
		logger_util.error('Cannot Find [' .. stage.Name .. '] Constants Data')
	else
		self.weak_zone_count = data[stage.Name].weak_zone_count
		self:labose_setting(self.weak_zone_count, 'weak')

		self.strong_zone_count = data[stage.Name].strong_zone_count
		self:labose_setting(self.strong_zone_count, 'strong')

		self.use_wind_pot = data[stage.Name].use_wind_pot
	end

	self.labose_load_complete = true

	self.sp_manager = get_or_create_global_table('Quest/Main/LaboseWorld/Common/LaboseWorldScreenplayManager')

	-- damage sender 가 리더 일때 초당 공격력이 늘어나는 문제가 있어 데미지 damage sender 용 오브젝트 생성
	self.damage_sender = field_object_util.create_virtual_field_object(vector(999, 0, 999))
end

function local_class:load_mouse_bombs()
	local gimmick_layer = stage.StageGameObject.transform:Find(stage.Name .. '/gimmick/')

	for idx = 0, gimmick_layer.childCount - 1 do
		local gimmick = gimmick_layer:GetChild(idx):GetComponent(typeof(CS.Oak.FieldObject))

		if lua_helper.type_compare(gimmick.FieldObjectBehaviour, CS.Oak.MouseBombFieldObjectBehaviour) then
			gimmick.Interactable = CS.Oak.PublishInteractable.Create()
			table.insert(self.mouse_bombs, gimmick)
		end
	end
end

function local_class:labose_setting(zone_count, fx_type)
	if zone_count < 1 then
		return
	end

	for idx = 1, zone_count do
		local zone_name = fx_type .. '_labose_zone_' .. idx
		local zone = field_util.get_zone(zone_name)
		if zone == nil then
			logger_util.error('Cannot Find [' .. zone_name .. '] Zone')
		else
			table.insert(self.zone_list, zone)

			local min_x = zone.Bounds.min.x + self.xz_adder
			local min_z = zone.Bounds.min.z + self.xz_adder
			local max_x = zone.Bounds.max.x - self.xz_adder
			local max_z = zone.Bounds.max.z - self.xz_adder

			local start_pos = vector(min_x, 0, min_z)
			local end_pos = vector(max_x, 0, max_z)
			local cur_pos
			local labose_tile_info = {}
			local labose_num = 1

			for i = math.floor(start_pos.x), math.floor(end_pos.x) do
				for j = math.floor(start_pos.z), math.floor(end_pos.z) do
					cur_pos = vector(i, 0, j)

					local floor_height = field:GetTileInfoAt(cur_pos):GetHeightAt(cur_pos)
					cur_pos.y = floor_height

					local effect = self.fx['virus_fog_' .. fx_type]():Instantiate(cur_pos)

					labose_tile_info[labose_num] = {
						pos = cur_pos,
						is_active = true,
						effect = effect,
						is_effect_active = false,
						bug_effect = nil,
						is_bug_effect_active = false,
						respawn_time_passed = self.labose_respawn_time[fx_type],
						fx_type = fx_type
					}

					labose_num = labose_num + 1
				end
			end

			self.labose_tiles[zone_name] = labose_tile_info
		end
	end
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_touch_event(e)
	if not self.can_touch_button then
		return false
	end

	local leader = get_party_leader()
	local current_action_state = leader.FieldObjectBehaviour.CurrentActionState
	local field_object_current_state = leader.FieldObjectBehaviour.CurrentState
	local character_current_state = leader.CharacterBehaviour.CurrentState

	-- 물건을 들고, 던질 때, 점프 중일때, 대쉬 중일 땐 바람의 항아리 기능 막음
	if self.labose_active_state and self.button_active and
			e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown and
			not lua_helper.type_compare(current_action_state, CS.Oak.CharacterHoldUpState) and
			not lua_helper.type_compare(current_action_state, CS.Oak.CharacterThrowState) and
			not lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) and
			not lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) and
			not lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) and
			not lua_helper.type_compare(character_current_state, CS.Oak.CharacterCrushState) then

		self.sp_manager:try_start_coroutine(self.button_pressed, self)
	end

	return false
end

function local_class:on_gamepad_event(e)
	if not self.can_touch_button then
		return false
	end

	local leader = get_party_leader()
	local current_action_state = leader.FieldObjectBehaviour.CurrentActionState
	local field_object_current_state = leader.FieldObjectBehaviour.CurrentState
	local character_current_state = leader.CharacterBehaviour.CurrentState

	if self.labose_active_state and self.button_active and
			e.GamepadEventType == CS.Oak.GamepadEventType.RightTriggerDown and
			not lua_helper.type_compare(current_action_state, CS.Oak.CharacterHoldUpState) and
			not lua_helper.type_compare(current_action_state, CS.Oak.CharacterThrowState) and
			not lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) and
			not lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) and
			not lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) and
			not lua_helper.type_compare(character_current_state, CS.Oak.CharacterCrushState) then

		self.sp_manager:try_start_coroutine(self.button_pressed, self)
	end

	return false
end

function local_class:on_interact_event(e)
	if self.player_state.wind_pot_launch then
		return false
	end

	local leader = get_party_leader()

	for _, mouse_bomb in pairs(self.mouse_bombs) do
		if type_util.is_interacted_target(e, mouse_bomb) then
			message_system:SendSync(mouse_bomb, CS.Oak.InteractEvent.Create(leader, mouse_bomb))
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if lua_helper.type_compare(leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) then
		return false
	end

	for _, zone in pairs(self.zone_list) do
		local zone_name = zone.Name

		if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) and e.Zone.Name == zone_name and
				lua_helper.reference_equals(e.FieldObject, leader) then
			if not e.FullEnter then
				self.entered_zone_list:add(zone)

				start_coroutine(self.include_labose_zone_routine, self, zone)
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local leader = get_party_leader()

	if lua_helper.type_compare(leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) then
		return false
	end

	for _, zone in pairs(self.zone_list) do
		local zone_name = zone.Name

		if type_util.is_zone_full_leave(e, leader, zone_name) then
			self.player_state.labose_zone_enter = false
			self.entered_zone_list:remove(zone)

			if #self.entered_zone_list < 1 then
				self.damage_time_passed = 0

				if self.player_emotion == 'damaged' then
					self.player_emotion = 'idle'
					character_util.remove_emotion(leader)
				end

				if self.player_state.slow then
					start_coroutine(self.set_slow_speed, self, false)
				end

				self:stop_labose_sfx()
			end

			return true
		end
	end

	return false
end

function local_class:on_stage_start_event(e)
	if self.use_wind_pot then
		message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
		message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
		message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

		if not self.is_tutorial then
			self.button_active = true
		end

		self:create_button()
	end
end

function local_class:on_battle_start_event(_)
	if not self.is_tutorial then
		self:set_button_active_state(false)
	end
end

function local_class:on_battle_end_event(_)
	if not self.is_tutorial then
		self:set_button_active_state(true)
	end
end

function local_class:on_field_object_destroyed_event(e)
	local leader = get_party_leader()
	if lua_helper.reference_equals(e.FieldObject, leader) then
		-- 기믹 안에서 죽었을 때 기믹 사운드 종료 해줌
		self:stop_labose_sfx()
	end
end
--endregion

function local_class:tutorial_button_setting(active)
	self.is_tutorial = active
	if self.is_tutorial then
		self:set_button_active_state(false)
	else
		self:set_button_active_state(true)
	end
end

function local_class:create_button()
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	field_ui_manager:SetUI(leader, ui_type)

	self.button = field_ui_manager:GetUI(leader)[ui_type]
	self.button:SetIcon(self.button_icon_name)
	self.button:ToggleIconTintChange(false)

	local button_active_state = self.button_active and true or false

	self:set_button_active_state(button_active_state)

	message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
end

function local_class:set_button_active_state(active)
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	if active then
		-- 버튼 킴
		self.button_active = true
		field_ui_manager:ShowTargetUI(ui_type, leader)
	else
		-- 버튼 끔
		self.button_active = false
		field_ui_manager:HideTargetUI(ui_type, leader)
	end
end

function local_class:set_labose_active_state(active)
	-- 엔터 시점에서 라보스 생성과 동작을 막음
	if active then
		-- 라보스 켬
		self.labose_active_state = true
	else
		-- 라보스 끔
		self.labose_active_state = false
	end
end

function local_class:button_pressed()
	self.player_state.wind_pot_launch = true

	-- 점프 스테이트가 끝날 때 겹쳐 지는 문제로 한 프레임 쉬어줌
	coroutine.yield()
	local leader = get_party_leader()

	if lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) then
		self.player_state.wind_pot_launch = false

		return
	end

	if lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
		self.player_state.wind_pot_launch = false

		return
	end

	sp_util.enter_scene({ stop_party = false })

	character_util.stop(leader)

	music_player_util.play_sfx_one_shot('01_gimmick_vacuum_02')

	self.button:SetIconTint(unity_color(self.button_gray_color))

	start_coroutine(self.wind_pot_launch_delay, self)

	local leader = get_party_leader()
	local leader_dir = leader.Direction
	local leader_dir_vector3 = direction_util.to_vector3_ver2(leader_dir)

	local wind_pot_bounds = self:create_wind_pot_bounds(leader, leader_dir, leader_dir_vector3)

	local zone = self:labose_zone_check(wind_pot_bounds)

	if zone ~= nil then
		for _, scanned_zone in pairs(zone) do
			self:labose_scan(scanned_zone, wind_pot_bounds)
		end
	end

	--플레이어 항아리 장착한채로 표정 attack, 애니메이션 rifle_shoot2 0.9초간 실행.
	character_util.spine_set_attachment(leader, '[base]weapon1', self.weapon_name)

	character_util.set_anim_and_emotion(leader,
			{ name = 'rifle_shoot2', loop = false }, { name = 'attack' })

	local vacuum_wind_out = self.fx:vacuum_wind_out():Instantiate(leader.Position)

	local fx_size_dur = 0.2
	local start_scale = vector(0, 1, 0)
	local end_scale = vector(2.5, 1, 2)

	local angle_vector = unity_class.quaternion.LookRotation(leader_dir_vector3) * unity_class.quaternion.Euler(0, -90, 0)

	vacuum_wind_out.transform.localRotation = angle_vector

	coroutine_util.while_each_frame(fx_size_dur, function(progress)
		vacuum_wind_out.transform.localScale = unity_class.vector3.Lerp(start_scale, end_scale, progress)
	end)

	--이펙트 크기가 최고에 도달한 뒤 0.7초 간 대기.
	wait_for_sec(0.7)

	character_util.remove_anim_and_emotion(leader)
	leader:RefreshWeaponAttachments()

	sp_util.exit_scene(nil, leader)

	self.player_state.wind_pot_launch = false
end

-- 바라보는 방향에 따라 바운드 크기 조절
function local_class:create_wind_pot_bounds(fo, fo_dir, fo_dir_vector3)
	local bounds_size = self.wind_pot_bounds_size
	local wind_pot_bounds_center
	local wind_pot_bounds_center_x
	local wind_pot_bounds_center_z

	if direction_util.is_side_ver2(fo_dir) then
		bounds_size = vector(bounds_size.z, bounds_size.y, bounds_size.x)
		wind_pot_bounds_center_x = fo.Position.x + (bounds_size.x * fo_dir_vector3.x / 2)
		wind_pot_bounds_center = vector(wind_pot_bounds_center_x, bounds_size.y, fo.Position.z)
	else
		wind_pot_bounds_center_z = fo.Position.z + (bounds_size.z * fo_dir_vector3.z / 2)
		wind_pot_bounds_center = vector(fo.Position.x, bounds_size.y, wind_pot_bounds_center_z)
	end

	return CS.UnityEngine.Bounds(wind_pot_bounds_center, bounds_size)
end

function local_class:wind_pot_launch_delay()
	self.can_touch_button = false

	wait_for_sec(self.wind_pot_delay)

	self.button:SetIconTint(unity_class.color.white)

	self.can_touch_button = true
end

function local_class:labose_is_overlapping_xz(bounds, labose_pos, xz_adder)
	local labose_min_x = labose_pos.x - xz_adder
	local labose_min_z = labose_pos.z - xz_adder
	local labose_max_x = labose_pos.x + xz_adder
	local labose_max_z = labose_pos.z + xz_adder

	return bounds.min.x <= labose_max_x and bounds.max.x >= labose_min_x and
			bounds.min.z <= labose_max_z and bounds.max.z >= labose_min_z
end

-- 존 바운드와 fo 의 바운드의 center 로 비교 해서 절반이 엔터 되었는지 판단
function local_class:is_zone_half_enter(bound, fo)
	local fo_center_pos = fo.Bounds.center

	return CS.BoundsExtensions.ContainsXZ(bound, fo_center_pos)
end

-- 삼마신 스테이지에서 리더가 바뀌는 경우가 있어 fo 를 따로 받지 않고 계속 리더만 체크
function local_class:include_labose_zone_routine(zone)
	local zone_bound = zone.Bounds

	while not self.is_stage_end and not self.player_state.labose_zone_enter and #self.entered_zone_list > 0 do
		local leader = get_party_leader()
		if self:is_zone_half_enter(zone_bound, leader) then
			if not self.player_state.labose_zone_enter and #self.entered_zone_list <= 1 then
				self.player_state.labose_zone_enter = true

				if not self.is_labose_collision_routine_end then
					self.is_labose_collision_routine_end = true

					self:labose_check_collision_routine(self.entered_zone_list)
				end
			end
		end

		coroutine.yield()
	end
end

function local_class:labose_zone_check(wind_pot_bounds)
	local scanned_zone_list = {}
	for _, zone in pairs(self.zone_list) do
		if bounds_util.is_overlapping_xz(zone.Bounds, wind_pot_bounds) then
			table.insert(scanned_zone_list, zone)
		end
	end

	return scanned_zone_list
end

function local_class:labose_hit_check(zone_name, fo)
	for _, labose in pairs(self.labose_tiles[zone_name]) do
		if labose.is_active and self:labose_is_overlapping_xz(fo.Bounds, labose.pos, 0.4) then
			return true
		end
	end
end

function local_class:labose_check_collision_routine(zone_list)
	local leader = get_party_leader()
	local zone_name

	while not self.is_stage_end and #zone_list > 0 do
		local current_state = leader.FieldObjectBehaviour.CurrentState
		local dt = unity_class.time.deltaTime

		if not self.player_state.wind_pot_launch and
				not lua_helper.type_compare(current_state, CS.Oak.CharacterJumpState) and
				not lua_helper.type_compare(leader.CharacterBehaviour.CurrentState, CS.Oak.CharacterHookShotState) and
				not leader.FieldObjectStatsBehaviour.IsDead then

			local labose_hit = false

			for zone, _ in pairs(zone_list) do
				labose_hit = self:labose_hit_check(zone.Name, leader)

				if labose_hit then
					zone_name = zone.Name

					break
				end
			end

			local hit_sfx = nil
			local labose_type = nil

			if labose_hit then
				if string.find(zone_name, 'weak') then
					hit_sfx = '02_hit_sneak_blood_01'
					labose_type = 'weak'
				else
					hit_sfx = '02_octo_hit_01'
					labose_type = 'strong'
				end

				self:play_labose_sfx(leader, labose_type)

				if self.player_emotion == 'idle' then
					self.player_emotion = 'damaged'
					character_util.set_emotion(leader, { name = 'damaged' })
				end

				if not self.player_state.slow then
					self:set_slow_speed(true)
				end

				self.damage_time_passed = self.damage_time_passed + dt
			else
				self.is_first_damage = false
				self.damage_time_passed = 0

				if self.player_state.slow then
					self:set_slow_speed(false)
				end

				if self.player_emotion == 'damaged' then
					self.player_emotion = 'idle'
					character_util.remove_emotion(leader)
				end

				self:stop_labose_sfx()
			end

			-- 유예 시간이 지나고도 라보스와 닿은 상태라면 데미지 입기 시작
			if self.damage_time_passed > self.damage_delay then
				if not self.is_first_damage then
					self.is_first_damage = true
					self.damage_time_passed = 0

					if not lua_helper.type_compare(leader.FieldObjectController.CurrentState,
							CS.Oak.CharacterControllerScreenplayState) then
						self:execute_damage(leader, self.damage_rate, hit_sfx)
					end
				end

				if self.damage_time_passed > self.damage_term then
					self.damage_time_passed = 0

					if not lua_helper.type_compare(leader.FieldObjectController.CurrentState,
							CS.Oak.CharacterControllerScreenplayState) then
						self:execute_damage(leader, self.damage_rate, hit_sfx)
					end
				end
			end
		end

		coroutine.yield()
	end

	self.is_first_damage = false
	self.is_labose_collision_routine_end = false
end

function local_class:labose_scan(zone, wind_pot_bounds)
	local leader = get_party_leader()
	local zone_name = zone.Name
	local shortest_dist = 99999
	local scanned_labose_hashset = create_lua_hashset()
	local holdable_list = create_lua_hashset()
	local shortest_dist_labose = nil
	local obj_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(wind_pot_bounds, unity_class.vector3.zero)
	local leader_pos = leader.Position
	local leader_dir = leader.Direction
	local leader_dir_vector3 = direction_util.to_vector3_ver2(leader_dir)
	local obstacle_check_bounds = CS.UnityEngine.Bounds(leader_pos, vector(1, 0, 1))

	-- 홀더블 오브젝트, 홀더블 열쇠는 장애물로 인식하지 않도록 잠시 visible 로 바꿨다가 원복
	for idx = 0, obj_list.Count - 1 do
		local fo = obj_list[idx]
		if lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.HoldableObjectBehaviour) or
				lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.KeyObjectBehaviour) then
			holdable_list:add(fo)
			fo.ActiveState = active_state('visible')
		end
	end

	local center_offset = vector(leader_dir_vector3.x * 0.5, 0, leader_dir_vector3.z * 0.5)
	local cur_bounds_center = center_offset + leader_pos

	-- 벽 뒤에 가로막혔는 지 검사를 하기 위한 기준점
	local block_between_pos = center_offset + leader_pos
	local line_count_max = math.floor(math.max(self.wind_pot_bounds_size.x, self.wind_pot_bounds_size.z))
	local line_count_min = 0.5
	local line_1_first_obstacle = false
	local line_2_first_obstacle = false

	for i = 0, line_count_max - 1 do
		for j = -line_count_min, line_count_min do
			if direction_util.is_side_ver2(leader_dir) then
				cur_bounds_center = vector(cur_bounds_center.x, 0, leader_pos.z + j)
				block_between_pos = vector(block_between_pos.x, 0, leader_pos.z + j)
			else
				cur_bounds_center = vector(leader_pos.x + j, 0, cur_bounds_center.z)
				block_between_pos = vector(leader_pos.x + j, 0, block_between_pos.z)
			end

			obstacle_check_bounds.center = cur_bounds_center

			for _, labose in pairs(self.labose_tiles[zone_name]) do
				if self:labose_is_overlapping_xz(obstacle_check_bounds, labose.pos, self.xz_adder) then
					if labose.is_active then
						local sqr_dist = vector_util.sqr_distance(leader_pos, labose.pos)
						if shortest_dist > sqr_dist then
							shortest_dist = sqr_dist
							shortest_dist_labose = labose
						end

						-- 처음에 막힌 블럭 위에 라보스는 지워야함
						if field:IsAnythingBlockingWithoutBounds(obstacle_check_bounds,
								CS.Oak.EntityGroups.Obstacle, unity_class.vector3.zero) then
							if not line_1_first_obstacle and j == -0.5 then
								line_1_first_obstacle = true
								scanned_labose_hashset:add(labose)
							elseif not line_2_first_obstacle and j == 0.5 then
								line_2_first_obstacle = true
								scanned_labose_hashset:add(labose)
							end
						else
							if not CS.Oak.IFieldObjectExtensions.IsMovementBlockedBetween(leader, block_between_pos,
									labose.pos, CS.Oak.EntityGroups.Obstacle) then
								scanned_labose_hashset:add(labose)
							end
						end
					end
				end
			end
		end

		if direction_util.is_side_ver2(leader_dir) then
			cur_bounds_center = cur_bounds_center + vector(leader_dir_vector3.x, 0, 0)
		else
			cur_bounds_center = cur_bounds_center + vector(0, 0, leader_dir_vector3.z)
		end
	end

	for fo, _ in pairs(holdable_list) do
		fo.ActiveState = active_state('enabled')
	end

	holdable_list:clear()
	obj_list:Dispose()

	-- labose_disappears_routine 에선 인자값을 테이블로 받고 있기 때문에, 테이블로 옮겨서 넣어줌.
	local scanned_labose_table = {}

	for labose, _ in pairs(scanned_labose_hashset) do
		table.insert(scanned_labose_table, labose)
	end

	scanned_labose_hashset:clear()

	if shortest_dist_labose ~= nil then
		-- 0.15 딜레이를 주고 삭제 되어야 하고, 추후 재생성 루틴을 위해 코루틴 생성
		start_coroutine(self.labose_disappears_routine, self, scanned_labose_table, shortest_dist_labose, zone_name)
	end
end

function local_class:find_labose(zone_name, labose_pos)
	local labose_list = {}
	for _, labose in pairs(self.labose_tiles[zone_name]) do
		local diff = vector_util.get_x0z(labose_pos - labose.pos)

		if vector_util.is_almost_zero(diff) then
			table.insert(labose_list, labose)
		end
	end

	return labose_list
end

function local_class:labose_disappears_routine(scanned_labose, shortest_dist_labose, zone_name)
	local leader = get_party_leader()
	local leader_dir = leader.Direction
	local dir_vec = direction_util.to_vector3_ver2(leader_dir)
	local disappears_labose = shortest_dist_labose.pos

	local line = direction_util.is_side_ver2(leader_dir) and 'x' or 'z'
	local line_count = math.floor(math.max(self.wind_pot_bounds_size.x, self.wind_pot_bounds_size.z))

	for i = 1, line_count do
		local disappears_labose_list = {}

		for idx = 1, #scanned_labose do
			if disappears_labose[line] == scanned_labose[idx].pos[line] then
				table.insert(disappears_labose_list, scanned_labose[idx])
			end
		end

		self:labose_disappears(zone_name, disappears_labose_list)

		wait_for_sec(0.15)

		disappears_labose = disappears_labose + dir_vec
	end

	self:labose_respawn_routine(scanned_labose)
end

function local_class:labose_disappears(zone_name, labose_list, is_andras_gimmick, on_fog_affected_callback)
	start_coroutine(self.labose_disappears_async, self, zone_name, labose_list, is_andras_gimmick, on_fog_affected_callback)
end

function local_class:labose_disappears_async(zone_name, labose_list, is_andras_gimmick, on_fog_affected_callback)
	local fx_type = string.find(zone_name, 'weak') and 'weak' or 'strong'
	local fx_name

	is_andras_gimmick = lua_helper.get_or_default(is_andras_gimmick, false)

	if is_andras_gimmick then
		fx_name = 'virus_fog_' .. fx_type .. '_end_ice'

		labose_list = self:find_labose(zone_name, labose_list)
	else
		fx_name = 'virus_fog_' .. fx_type .. '_end'
	end

	for key, labose in pairs(labose_list) do
		if labose.is_active then
			labose.is_active = false
			labose.respawn_time_passed = 0
			labose.effect:Dispose()

			self.fx[fx_name]():Instantiate(labose.pos)

			if on_fog_affected_callback ~= nil then
				on_fog_affected_callback(labose.pos)
			end
		else
			table.remove(labose_list, key)
		end
	end

	if is_andras_gimmick and not table_util.is_empty(labose_list) then
		self:labose_respawn_routine(labose_list)
	end
end

function local_class:labose_respawn_routine(scanned_labose)
	local respawn_routine_check = true

	while not self.is_stage_end and respawn_routine_check do
		respawn_routine_check = false
		local dt = unity_class.time.deltaTime

		for _, labose in pairs(scanned_labose) do
			if not labose.is_active then
				respawn_routine_check = true

				if labose.respawn_time_passed < self.labose_respawn_time[labose.fx_type] then
					labose.respawn_time_passed = labose.respawn_time_passed + dt

					if not labose.is_bug_effect_active and labose.respawn_time_passed > self.bug_effect_time[labose.fx_type] then
						labose.is_bug_effect_active = true

						local bug_effect = self.fx['virus_fog_' .. labose.fx_type .. '_bug']():Instantiate(labose.pos)
						labose.bug_effect = bug_effect
					end
					-- 이펙트 자연스럽게 이어지게 하기 위해 0.2초 먼저 재생함
					if not labose.is_effect_active and labose.respawn_time_passed > self.labose_respawn_time[labose.fx_type] - 0.2 then
						labose.is_effect_active = true

						local effect = self.fx['virus_fog_' .. labose.fx_type]():Instantiate(labose.pos)
						labose.effect = effect
					end
				else
					labose.bug_effect:Dispose()

					labose.is_bug_effect_active = false
					labose.is_effect_active = false

					labose.is_active = true
				end
			end
		end

		if not respawn_routine_check then
			return
		end

		coroutine.yield()
	end
end

function local_class:execute_damage(target, ratio, hit_sfx)
	local damage_info = CS.Oak.DamageInfo()

	damage_info.type = CS.Oak.DamageType.IgnoreDefense
	damage_info.sender = self.damage_sender
	damage_info.target = target
	damage_info.damage = math.floor(target.FieldObjectStatsBehaviour.MaxHP * ratio)
	damage_info.critical = false
	if hit_sfx ~= nil then
		damage_info.hitSfxInfo = CS.Oak.HitSfxInfo(false, hit_sfx)
	end

	command_util.publish_damage(damage_info)
end

--- 플레이어 달리기를 막고 스피드 변경
function local_class:set_slow_speed(is_slow)
	local leader = get_party_leader()
	local current_state = leader.FieldObjectController.CurrentState

	if current_state ~= nil then
		-- ScreenplayState 일때 로직에 들어오면 ManualTouchState 가 될때까지 대기 했다가 버프 걸거나 지워 줌
		while not self.is_stage_end and not lua_helper.type_compare(current_state, CS.Oak.CharacterControllerManualTouchState) do
			current_state = leader.FieldObjectController.CurrentState

			coroutine.yield()
		end
	end

	if is_slow and not self.player_state.slow then
		self.player_state.slow = true
		current_state:RequestDisableControl(leader, CS.Oak.DisabledControls.Dash)

		-- 달리기 키 막고 슬로우 걸음
		buff_manager:AddBuff(leader, CS.Oak.EquipmentSlot.None, leader,
				"speed_down_persistent", self.decrease_speed_rate, false, false)
	else
		self.player_state.slow = false
		buff_manager:RemoveBuff(leader, CS.Oak.EquipmentSlot.None, leader, 'speed_down_persistent')

		-- 달리기키 원래대로 리셋
		current_state:RemoveDisableControl(leader)
	end
end

function local_class:play_labose_sfx(fo, labose_type)
	if not self.is_labose_sfx_playing then
		self.is_labose_sfx_playing = true
		self.labose_sfx = {
			fly = music_player_util.play_sfx({
				sfx_name = self.sfx.fly_sound.name,
				loop = true,
				parent = fo,
				volume = self.sfx.fly_sound[labose_type .. '_volume'],
				type_priority = 'gimmick',
				player_priority = 'object',
				fade_in_time = 1
			}),
			bug = music_player_util.play_sfx({
				sfx_name = self.sfx.bug_sound.name,
				loop = true,
				parent = fo,
				volume = self.sfx.bug_sound[labose_type .. '_volume'],
				type_priority = 'gimmick',
				player_priority = 'object',
				fade_in_time = 1
			})
		}
	end
end

function local_class:stop_labose_sfx()
	if self.labose_sfx ~= nil then
		if self.is_labose_sfx_playing then
			self.is_labose_sfx_playing = false
			music_player_util.fade_out_sfx(self.labose_sfx.fly, 1)
			music_player_util.fade_out_sfx(self.labose_sfx.bug, 1)
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
