local local_class = newclass('PixyWorldBoomerangController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	self.button_icon_name = 'actbtn_ic_act_boomerang.png'

	self.scene_version = scene_util.default_version

	-- 부메랑 사용 가능한지
	self.can_use_boomerang = true
	-- 버튼 활성화 상태
	self.button_active = true

	-- 부메랑 정보
	self.boomerang_info = {
		is_burning = false,
		first_move_distance = nil,
		first_move_duration = nil,
		bounds = nil,
		box_bounds = nil,
		wait_duration = nil,
		second_move_speed = nil,
		second_move_acc_duration = nil,
		return_target_distance = nil
	}

	-- 부메랑 상태
	self.boomerang_state = {
		none = 1,
		ready = 2,
		first_move = 3,
		waiting = 4,
		collision = 5,
		second_move = 6,
		finish = 7,
	}

	self.cur_boomerang_state = self.boomerang_state.none

	-- 부메랑에 달려있는 fx
	self.boomerang_fx = setmetatable({
		boomerang = {
			fx = nil,
			pool = function()
				return unity_object_pool.GetOrCreate('fx_boomerang')
			end
		},
		boomerang_contrail = {
			fx = nil,
			pool = function()
				return unity_object_pool.GetOrCreate('fx_boomerang_contrail')
			end
		},
		boomerang_holdable = {
			fx = nil,
			pool = function()
				return unity_object_pool.GetOrCreate('fx_boomerang_holderable')
			end
		},
		boomerang_fire = {
			fx = nil,
			pool = function()
				return unity_object_pool.GetOrCreate('fx_boomerang_fire')
			end
		},
		boomerang_fire_contrail = {
			fx = nil,
			pool = function()
				return unity_object_pool.GetOrCreate('fx_boomerang_fire_contrail')
			end
		},
	}, {
		__index = {
			load_all = function(this)
				for _, fx_spec in pairs(this) do
					fx_spec.pool()
				end
			end,
			add = function(this, key, pos)
				if this[key].fx == nil then
					this[key].fx = this[key]:pool():Instantiate(pos)
				end
			end,
			get = function(this, key)
				return this[key].fx
			end,
			dispose = function(this, key)
				if this[key].fx ~= nil then
					this[key].fx:Dispose()
					this[key].fx = nil
				end
			end,
			dispose_all = function(this)
				for name, fx_spec in pairs(this) do
					this:dispose(name)
				end
			end
		}
	})

	self.fx = setmetatable({
		-- dispose type : time limit
		boomerang_shoot = function()
			return unity_object_pool.GetOrCreate('fx_boomerang_shoot')
		end,
		boomerang_hit = function()
			return unity_object_pool.GetOrCreate('fx_boomerang_hit')
		end,
		boomerang_get = function()
			return unity_object_pool.GetOrCreate('fx_boomerang_get')
		end,
	}, {
		__index = {
			load_all = function(this)
				for _, func in pairs(this) do
					func()
				end
			end
		}
	})

	-- 부메랑 sfx
	self.boomerang_sfx = nil

	-- holdable 관리용
	self.holdable_info = {
		slot = nil,
		start_pos = nil,
		move_pos = nil,
		switch_check = false,
	}

	-- 버튼 쿨타임 컬러
	self.button_gray_color = { 96 / 255, 96 / 255, 96 / 255, 1 }

	-- 버튼 상태
	self.button_state = {
		none = 1,
		load = 2,
		can_touch = 3,
		pressed = 4
	}

	self.cur_button_state = self.button_state.none

	-- 일시정지 체크
	self.paused = false

	self.custom_event_key = 'pw_boomerang_event'
	self.get_event_key = 'boomerang_get'
	self.npc_event_key = 'npc_collision'
end


--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseStartEvent), 'on_pause_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseEndEvent), 'on_pause_end_event')

	self.fx:load_all()
	self.boomerang_fx:load_all()
	yield_return(unity_object_pool, 'WaitAll')

	self:load_data()
end
--endregion load_resource

--region dispose
function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PixyCustomActionSwitchedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseEndEvent))

	self.cur_boomerang_state = self.button_state.none

	self.button = nil

	self.boomerang_info = nil

	self.holdable_info = nil

	self.boomerang_fx:dispose_all()
	self.boomerang_fx = nil

	self.cs_controller = nil
end
--endregion dispose

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion launch

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.PixyCustomActionSwitchedEvent), 'on_pixy_custom_action_switched_event')

	-- 추후 튜토리얼 등의 상태가 끝나면 터치 가능으로 처리 필요
	self.cur_button_state = self.button_state.can_touch

	self:create_button()

	return true
end

function local_class:on_touch_event(e)
	if not self:button_use_check() then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown then
		start_coroutine(self.button_pressed, self)
		return true
	end

	return false
end

function local_class:on_gamepad_event(e)
	if not self:button_use_check() then
		return false
	end

	if e.GamepadEventType == CS.Oak.GamepadEventType.RightShoulderDown then
		start_coroutine(self.button_pressed, self)
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	-- grid 이동 시 부메랑 상태 초기화(이후 코루틴에서 각종 초기화)
	if self.cur_boomerang_state ~= self.boomerang_state.ready then
		self.cur_boomerang_state = self.boomerang_state.none
		self.cur_button_state = self.button_state.can_touch

		return true
	end

	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	-- exit 진입 시 부메랑 상태 초기화(이후 코루틴에서 각종 초기화)
	if self.cur_boomerang_state ~= self.boomerang_state.ready then
		self.cur_boomerang_state = self.boomerang_state.none
		self.cur_button_state = self.button_state.can_touch

		return true
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	-- 부메랑에 실린 기믹이 파괴될 경우 슬롯 초기화
	if lua_helper.reference_equals(e.FieldObject, self.holdable_info.slot) then
		self:reset_holdable_slot()
		return true
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.cur_boomerang_state = self.boomerang_state.none

	return true
end

function local_class:on_battle_start_event(e)
	if self.can_use_boomerang then
		self:set_button_active_state(false)

		return true
	end

	return false
end

function local_class:on_battle_end_event(e)
	if self.can_use_boomerang then
		self:set_button_active_state(true)

		return true
	end

	return false
end

function local_class:on_pause_start_event(e)
	self.paused = true
	return true
end

function local_class:on_pause_end_event(e)
	self.paused = false
	return true
end

function local_class:on_pixy_custom_action_switched_event(e)
	if e.NextState == CS.Oak.PixyCustomActionSwitchedEvent.State.StatusWindow then
		self.can_use_boomerang = false
	else
		self:boomerang_active_setting(true)
	end

	return false
end
--endregion

function local_class:load_data()
	local data = get_or_create_global_variable('Quest/Main/PixyWorld/Common/PixyWorldBoomerangConstants.lua')

	self.boomerang_info = {}

	self.boomerang_info.is_burning = false

	self.boomerang_info.first_move_distance = data.boomerang_info.first_move_distance
	self.boomerang_info.first_move_duration = data.boomerang_info.first_move_duration
	self.boomerang_info.bounds = CS.UnityEngine.Bounds(vector(900, 0, 900), data.boomerang_info.size)
	self.boomerang_info.box_bounds = CS.UnityEngine.Bounds(vector(900, 0, 900), data.boomerang_info.box_size)
	self.boomerang_info.wait_duration = data.boomerang_info.wait_duration
	self.boomerang_info.second_move_speed = data.boomerang_info.second_move_speed
	self.boomerang_info.second_move_acc_duration = data.boomerang_info.second_move_acc_duration
	self.boomerang_info.return_target_distance = data.boomerang_info.return_target_distance
end

--- 버튼 생성
function local_class:create_button()
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	-- SetUI에서 Get을 반환하나 기능 구분짓기 위해 따로 분리
	field_ui_manager:SetUI(leader, ui_type)

	self.button = field_ui_manager:GetUI(leader)[ui_type]
	self.button:SetIcon(self.button_icon_name)

	self:set_button_active_state(self.can_use_boomerang)
end

function local_class:set_button_active_state(active)
	local leader = get_party_leader()
	local ui_type = CS.Oak.FieldUiType.CustomButton1

	if active then
		-- 버튼 킴
		self.button_active = true
		self.button:SetIcon(self.button_icon_name)
		field_ui_manager:ShowTargetUI(ui_type, leader)

		if CS.Oak.Game.Instance.InputManager.GamepadEnabled then
			local icon = self.button.gameObject:GetComponentInChildren(typeof(CS.Oak.FieldUIGamepadIcon))

			icon.TargetKey = CS.GamepadKey.RightShoulder
			icon:Set()
		end
	else
		-- 버튼 끔
		self.button_active = false
		field_ui_manager:HideTargetUI(ui_type, leader)
	end
end

function local_class:change_ui_owner(cur_owner, owner)
	field_ui_manager:ChangeUIOwner(CS.Oak.FieldUiType.CustomButton1, cur_owner, owner)

	self.button:SetIcon(self.button_icon_name)
end

--- 부메랑 사용 가능을 변경할 함수
function local_class:boomerang_active_setting(active)
	self.can_use_boomerang = active

	if self.can_use_boomerang then
		self:set_button_active_state(true)
	else
		self:set_button_active_state(false)
	end
end

--- 버튼 사용 가능 체크
function local_class:button_use_check()
	if not self.can_use_boomerang or self.cur_button_state ~= self.button_state.can_touch or not self.button_active then
		return false
	end

	local leader = get_party_leader()
	local current_action_state = leader.FieldObjectBehaviour.CurrentActionState
	local field_object_current_state = leader.FieldObjectBehaviour.CurrentState
	local character_current_state = leader.CharacterBehaviour.CurrentState
	local controller_current_state = leader.FieldObjectController.CurrentState

	if lua_helper.type_compare(current_action_state, CS.Oak.CharacterHoldUpState) or
			lua_helper.type_compare(current_action_state, CS.Oak.CharacterThrowState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterUnitPushState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.HeroDeadState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) or
			lua_helper.type_compare(controller_current_state, CS.Oak.CharacterControllerInteractState) then

		return false
	end

	return true
end

function local_class:button_pressed()
	self.cur_button_state = self.button_state.pressed

	-- 일부 스테이트가 겹치는 부분 대기
	coroutine.yield()

	local leader = get_party_leader()

	-- 점프나 스크린 플레이 상태에 들어가있으면 탈출
	if lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) or
			lua_helper.type_compare(leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerInteractState) then
		self.cur_button_state = self.button_state.can_touch

		return
	end

	self.cur_boomerang_state = self.boomerang_state.ready
	self.button:SetIconTint(unity_color(self.button_gray_color))

	local leader_dir = leader.Direction
	local leader_dir_vec = direction_util.to_vector3_ver2(leader_dir)

	scene_util.set_anim(leader, self,
			{ name = 'attack', upper = true, count = 1, scale = 2.5, sfx_name = false })
	coroutine_util.while_each_frame(0.2, function(_)
		return self.cur_boomerang_state == self.boomerang_state.ready
	end)

	local boomerang_shoot = self.fx.boomerang_shoot():Instantiate(leader.Position)
	local angle_vector = unity_class.quaternion.LookRotation(leader_dir_vec)

	boomerang_shoot.transform.localRotation = angle_vector

	if self.cur_boomerang_state == self.boomerang_state.ready then
		-- TODO: 부메랑 루틴을 Update로 하는 방법도 있음, 해당 부분 루아 프로파일링 시 기본 코루틴 사용으로 gc 발생
		start_coroutine(self.boomerang_routine, self, leader, leader_dir_vec)
	end
end

--- CharacterControllerScreenplayState 상태에서도 부메랑 사용이 가능한 루틴
function local_class:screen_play_shot(target)
	self.cur_boomerang_state = self.boomerang_state.ready

	local target_dir = target.Direction
	local target_dir_vec = direction_util.to_vector3_ver2(target_dir)

	scene_util.set_anim(target, self,
			{ name = 'attack', upper = true, count = 1, scale = 2.5, sfx_name = false })
	coroutine_util.while_each_frame(0.2, function(_)
		return self.cur_boomerang_state == self.boomerang_state.ready
	end)

	local boomerang_shoot = self.fx.boomerang_shoot():Instantiate(target.Position)
	local angle_vector = unity_class.quaternion.LookRotation(target_dir_vec)

	boomerang_shoot.transform.localRotation = angle_vector

	if self.cur_boomerang_state == self.boomerang_state.ready then
		-- TODO: 부메랑 루틴을 Update로 하는 방법도 있음, 해당 부분 루아 프로파일링 시 기본 코루틴 사용으로 gc 발생
		start_coroutine(self.boomerang_routine, self, target, target_dir_vec)
	end
end

--- 부메랑 루틴
function local_class:boomerang_routine(target, dir_vec)
	local progress = 0
	self.holdable_info.switch_check = false

	-- 첫번째 이동
	do
		local start_pos = target.Position
		local move_pos = start_pos + dir_vec * self.boomerang_info.first_move_distance

		local interpolation_func = interpolations_constants.ease_out_quint

		local duration = self.boomerang_info.first_move_duration
		local time_passed = 0

		music_player_util.play_sfx_one_shot('02_normal_slash_02')

		if self.boomerang_sfx == nil then
			self.boomerang_sfx = music_player_util.play_sfx(
					{ sfx_name = '01_throw_04', loop = true, play_pos = start_pos,
					  type_priority = 'gimmick', player_priority = 'object' })
		end

		self.cur_boomerang_state = self.boomerang_state.first_move
		self.boomerang_fx:add('boomerang', start_pos)
		self.boomerang_fx:add('boomerang_contrail', start_pos)
		self:set_boomerang_position(start_pos)

		local move_update = function(dt)
			time_passed = time_passed + dt

			progress = interpolation_func(time_passed, 0, 1, duration)
			local cur_pos = unity_class.vector3.Lerp(start_pos, move_pos, progress)

			-- 충돌 체크
			self:check_boomerang_collision(target, cur_pos - self.boomerang_info.bounds.center)

			-- 부메랑 위치 갱신
			self:set_boomerang_position(cur_pos)

			if self.cur_boomerang_state ~= self.boomerang_state.first_move or time_passed >= duration then
				return false
			end

			return true
		end

		while self.cur_boomerang_state == self.boomerang_state.first_move and time_passed < duration do
			local dt = unity_class.time.deltaTime
			local target_dt = self:get_delta_time()

			if dt > target_dt then
				while dt >= target_dt and move_update(target_dt) do
					dt = dt - target_dt
				end

				if float_util.is_almost_zero(dt) then
					move_update(dt)
				end
			else
				move_update(dt)
			end

			coroutine.yield()
		end
	end

	-- 대기 상태 돌입
	if self.cur_boomerang_state == self.boomerang_state.first_move then
		self.cur_boomerang_state = self.boomerang_state.waiting

		local duration = self.boomerang_info.wait_duration
		local time_passed = 0

		while self.cur_boomerang_state == self.boomerang_state.waiting and time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime

			coroutine.yield()
		end
	end

	-- 부메랑 되돌아옴 (충돌 무시)
	if self.cur_boomerang_state == self.boomerang_state.waiting or
			self.cur_boomerang_state == self.boomerang_state.collision then

		-- 부메랑 fx 시뮬레이션 스피드 조정
		self:set_boomerang_simulation_speed('boomerang', 0.75)

		-- 충돌로 인해 되돌아 온다면 날릴 때와 되돌아올 때의 속도에 비례하도록 가속 유지
		local time_passed = self.cur_boomerang_state == self.boomerang_state.collision and (1 - progress) or 0

		self.cur_boomerang_state = self.boomerang_state.second_move

		local duration = self.boomerang_info.second_move_acc_duration
		local interpolation_func = interpolations_constants.ease_in_quint

		local move_update = function(dt)
			time_passed = time_passed + dt

			local speed = interpolation_func(time_passed, 0, self.boomerang_info.second_move_speed, duration)
			speed = math.min(speed, self.boomerang_info.second_move_speed)

			local dir = (target.Position - self.boomerang_info.bounds.center).normalized
			local cur_pos = self.boomerang_info.bounds.center + dir * speed * dt

			self:check_boomerang_collision(target, cur_pos - self.boomerang_info.bounds.center)

			self:set_boomerang_position(cur_pos)

			-- 정상적으로 회수될 경우 finish state 진입
			if (self.boomerang_info.bounds.center - target.Position).magnitude <= self.boomerang_info.return_target_distance then
				self.cur_boomerang_state = self.boomerang_state.finish

				return false
			end

			return true
		end

		while self.cur_boomerang_state == self.boomerang_state.second_move do
			local dt = unity_class.time.deltaTime
			local digit_count = 5
			local target_dt = dt / digit_count

			while dt > target_dt do
				move_update(target_dt)

				dt = dt - target_dt
			end

			if self.cur_boomerang_state == self.boomerang_state.second_move then
				coroutine.yield()
			end
		end

		--부메랑이 플레이어 위치에 복귀하면 Fx_boomerang_get 실행하며 삭제.
		if self.cur_boomerang_state == self.boomerang_state.finish then
			self.fx.boomerang_get():Instantiate(self.boomerang_info.bounds.center)
			music_player_util.play_sfx_one_shot('01_movie_end_01', 0.6)
		end
	end

	self:set_boomerang_simulation_speed('boomerang', 1)
	self.boomerang_fx:dispose('boomerang')
	self.boomerang_fx:dispose('boomerang_contrail')
	self.boomerang_fx:dispose('boomerang_fire')
	self.boomerang_fx:dispose('boomerang_fire_contrail')

	-- 불이 붙었던 기능들 꺼줌
	if self.boomerang_info ~= nil and self.boomerang_info.is_burning then
		self.boomerang_info.is_burning = false
	end

	if self.holdable_info ~= nil then
		-- 홀더블 리셋&위치 체크
		self:check_holdable(target)
		-- 홀더블 리더 기준 이동 처리
		self:move_holdable()
	end

	if self.holdable_info ~= nil then
		-- 청홍벽, 스위치 기둥 담은 리스트 초기화
		self.holdable_info.switch_check = false
		-- holdable 슬롯 리셋
		self:reset_holdable_slot()
	end

	--이후 부메랑 기믹 버튼 활성화.
	if self.button ~= nil then
		self.button:SetIconTint(unity_class.color.white)
	end

	if self.boomerang_sfx ~= nil then
		music_player_util.stop_sfx(self.boomerang_sfx)
		self.boomerang_sfx = nil
	end

	self.cur_boomerang_state = self.boomerang_state.none
	self.cur_button_state = self.button_state.can_touch
	message_system:Publish(CS.Oak.CustomStageEvent.Create(target, { self.custom_event_key, self.get_event_key }))
end

function local_class:set_boomerang_simulation_speed(key, speed)
	local boomerang_fx = self.boomerang_fx:get(key)

	if boomerang_fx == nil then
		return
	end

	local particle_systems = boomerang_fx:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem))

	for i = 0, particle_systems.Length - 1 do
		local main = particle_systems[i].main

		main.simulationSpeed = speed
	end
end

--- 부메랑에 연관된 fx, bounds, object 위치 이동용 함수
function local_class:set_boomerang_position(pos)
	for _, fx_spec in pairs(self.boomerang_fx) do
		if fx_spec.fx ~= nil then
			fx_spec.fx.transform.position = pos
		end
	end

	self.boomerang_info.bounds.center = pos
	self.boomerang_info.box_bounds.center = pos

	if self.holdable_info.slot ~= nil then
		self.holdable_info.slot.Position = pos
	end

	if self.boomerang_sfx ~= nil then
		self.boomerang_sfx:SetPosition(pos)

		local leader = get_party_leader()
		local diff = (pos - leader.Position).magnitude
		local volume = 1 - math.min(diff / self.boomerang_info.first_move_distance, 0.5)

		self.boomerang_sfx:ChangeVolume(volume, 0)
	end
end

--- 부메랑의 이동 구간 충돌 체크
function local_class:check_boomerang_collision(target, move)
	-- 충돌 우선 순위 : breakable -> 속성 -> 기믹-> 벽 -> holdable 충돌
	local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(self.boomerang_info.bounds, move)
	local fo_list_2 = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(self.boomerang_info.box_bounds, move)

	for _, fo in pairs(fo_list) do
		-- breakable
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				lua_helper.type_compare(fo.DamagedBehaviour, CS.Oak.PotDamagedBehaviour) then
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Melee
			damage_info.sender = fo
			damage_info.target = fo
			damage_info.damage = CS.Oak.DamageConstants.ObjectImpact

			command_util.publish_damage(damage_info)
			return
		end
	end

	for _, fo in pairs(fo_list_2) do
		-- fire
		if self:is_overlapping_y(self.boomerang_info.box_bounds, fo.Bounds) and
				not self.boomerang_info.is_burning and fo.CombustibleBehaviour.IsBurning then
			self.boomerang_info.is_burning = true
			self.boomerang_fx:add('boomerang_fire', self.boomerang_info.box_bounds.center)
			self.boomerang_fx:add('boomerang_fire_contrail', self.boomerang_info.box_bounds.center)
			music_player_util.play_sfx_one_shot('01_catch_fire_01')
		end

		-- burn 상태라면 닿는 gimmick에 burn 부여
		if self.boomerang_info.is_burning then
			CS.Oak.ICombustibleBehaviourExtensions.DefaultBurn(nil, target, fo)

			-- 슬롯에 있는 대상에게도 burn 부여
			if self.holdable_info.slot ~= nil then
				CS.Oak.ICombustibleBehaviourExtensions.DefaultBurn(nil, target, self.holdable_info.slot)
			end
		end
	end

	for _, fo in pairs(fo_list) do
		-- 청홍벽, 스위치 기둥 충돌 시
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.ConvertSwitchFieldObjectBehaviour) or
				lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.LimitSwitchBehaviour) then
			-- 이미 처리된 기믹인지 검사
			if not self.holdable_info.switch_check then
				local damage_info = CS.Oak.DamageInfo()

				damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
				damage_info.sender = fo
				damage_info.target = fo
				damage_info.damage = 0

				command_util.publish_damage(damage_info)

				-- 중복 처리 방지
				self.holdable_info.switch_check = true
				self.fx.boomerang_hit():Instantiate(self.boomerang_info.bounds.center)
				if self.cur_boomerang_state ~= self.boomerang_state.second_move then
					self.cur_boomerang_state = self.boomerang_state.collision
				end

				return
			end
		end

		-- key door, 가시블록 등의 crash behaviour 충돌
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				self.cur_boomerang_state == self.boomerang_state.first_move and
				(lua_helper.type_compare(fo.CrashBehaviour, CS.Oak.SpikeCrashBehaviour) or
						lua_helper.type_compare(fo.CrashBehaviour, CS.Oak.KeyDoorCrashBehaviour)) then
			self.cur_boomerang_state = self.boomerang_state.collision
			return
		end

		-- 벽 충돌 시
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				self.cur_boomerang_state == self.boomerang_state.first_move and
				lua_helper.type_compare(fo.CrashBehaviour, CS.Oak.WallCrashBehaviour) then
			-- 난간 체크
			local slope_check = self.boomerang_info.bounds.center.y >= 1 and
					fo.EntityGroup & CS.Oak.EntityGroups.Slope == CS.Oak.EntityGroups.Slope

			-- cliff 지형(호수) 체크
			local cliff_check = fo.EntityGroup & CS.Oak.EntityGroups.Cliff == CS.Oak.EntityGroups.Cliff

			-- 고정형 화로 체크
			local is_brazier = lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.BrazierCombustibleBehaviour) or
					lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.SwitchBrazierCombustibleBehaviour) or
					lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.ToggleBrazierCombustibleBehaviour) or
					lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.EventBrazierCombustibleBehaviour) or
					lua_helper.type_compare(fo.CombustibleBehaviour, CS.Oak.ImprovisedBrazierCombustibleBehaviour)

			-- 나머지 wall crash behaviour는 충돌 판정
			if not slope_check and not cliff_check and not is_brazier then
				self.cur_boomerang_state = self.boomerang_state.collision
				return
			end
		end

		-- NPC 충돌 시
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				self.cur_boomerang_state == self.boomerang_state.first_move and
				lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.CharacterBehaviour) then
			local is_user_party = false

			-- 파티원은 판정 제외
			for i = 0, user_party.Count - 1 do
				if lua_helper.reference_equals(fo, user_party[i]) then
					is_user_party = true

					break
				end
			end

			is_user_party = lua_helper.reference_equals(fo, target) and true or is_user_party

			-- 파티원 제외 충돌 판정
			if not is_user_party then
				self.cur_boomerang_state = self.boomerang_state.collision
				self.fx.boomerang_hit():Instantiate(self.boomerang_info.bounds.center)
				character_util.spine_damage_squish_default(fo)
				character_util.spine_damage_red_pulse(fo)
				message_system:Publish(CS.Oak.CustomStageEvent.Create(fo, { self.custom_event_key, self.npc_event_key }))
			end
		end

		-- holdable 충돌 시
		-- 불이 붙은 폭탄일 경우 들고오지 말아야 함
		if self:is_overlapping_y(self.boomerang_info.bounds, fo.Bounds) and
				self.holdable_info.slot == nil and lua_helper.type_compare(fo.Holdable, CS.Oak.Holdable) then
			local is_character = lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.CharacterBehaviour)
			local is_bomb = lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.BarrelFieldObjectBehaviour) or
					lua_helper.type_compare(fo.FieldObjectBehaviour, CS.Oak.BombFieldObjectBehaviour)

			if (not self.boomerang_info.is_burning or not is_bomb) and not is_character then
				self:add_holdable_slot(fo)

				return
			end
		end
	end

	fo_list:Dispose()
	fo_list_2:Dispose()
end

--- holdable이 리셋될 수 있는 상황 처리
function local_class:check_holdable(target)
	-- 슬롯이 비어있으면 탈출
	if self.holdable_info.slot == nil then
		return
	end

	-- 부메랑이 정상 도착한 것이 아니라면 리셋
	if self.cur_boomerang_state ~= self.boomerang_state.finish then
		self:reset_holdable()

		return
	end

	local field_object_current_state = target.FieldObjectBehaviour.CurrentState
	local character_current_state = target.CharacterBehaviour.CurrentState

	-- 점프대, 가속, 훅샷, 컨트롤 뺏긴 상태일 경우
	if lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterControllerScreenplayState) then
		self:reset_holdable()

		return
	end

	-- 바닥 체크
	local dir_vec = (self.holdable_info.slot.Position - target.Position).normalized
	local check_pos = vector_util.get_x0z(target.Position + dir_vec, target.Position.y)
	local obstacle_check_bounds = CS.UnityEngine.Bounds(check_pos, vector(0.1, 0, 0.1))

	if not field:IsThereFloorAt(check_pos) or
			field:IsAnythingBlockingWithoutBounds(obstacle_check_bounds,
					CS.Oak.EntityGroups.Obstacle, unity_class.vector3.zero) then
		self:reset_holdable()

		return
	end

	-- holdable 도착 지점 추가
	self.holdable_info.move_pos = check_pos
end

--- holdable 이동 처리용
function local_class:move_holdable()
	-- 슬롯이 비어있거나 되돌아갈 위치를 받지 못한 경우 탈출
	if self.holdable_info.slot == nil or self.holdable_info.move_pos == nil then
		return
	end

	local duration = 0.1
	local start_pos = self.holdable_info.slot.Position

	coroutine_util.while_from_to_each_frame(duration, start_pos,
			self.holdable_info.move_pos, function(progress, cur_value)
				if self.holdable_info.slot == nil then
					return false
				end

				self.holdable_info.slot.Position = cur_value

				return self.cur_boomerang_state == self.boomerang_state.finish
			end)
end

--- holdable reset
function local_class:reset_holdable()
	message_system:SendSync(self.holdable_info.slot.FieldObjectBehaviour, CS.Oak.GimmickResetEvent.Instance)
end

--- 홀더블 슬롯에 추가
function local_class:add_holdable_slot(fo)
	self.holdable_info.slot = fo
	self.holdable_info.start_pos = fo.Position
	self.holdable_info.slot.ActiveState = active_state('visible')

	self.boomerang_fx:add('boomerang_holdable', fo.Position)
	music_player_util.play_sfx({ sfx_name = '01_holdup_01', loop = false, play_pos = fo.Position })
end

--- 부메랑에 실린 holdable 슬롯 리셋
function local_class:reset_holdable_slot()
	if self.holdable_info.slot ~= nil then
		if self.holdable_info.slot.ActiveState == active_state('visible') then
			self.holdable_info.slot.ActiveState = active_state('enabled')

			if self.holdable_info.move_pos ~= nil then
				local dir = (self.holdable_info.move_pos).normalized

				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.holdable_info.slot, dir, 0.01)
			end
		end

		self.holdable_info.move_pos = nil
		self.holdable_info.slot = nil
		self.holdable_info.start_pos = nil
	end

	self.boomerang_fx:dispose('boomerang_holdable')
end

function local_class:is_overlapping_y(a, b)
	return a.min.y <= b.max.y and a.max.y >= b.min.y
end

function local_class:get_delta_time()
	return self.paused and unity_class.time.deltaTime or (1 / 60)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
