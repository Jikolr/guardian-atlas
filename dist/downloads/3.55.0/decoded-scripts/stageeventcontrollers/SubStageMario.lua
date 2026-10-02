local local_class = newclass('SubstageMarioController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전
	self.scene_version = scene_util.default_version

	self.quest_id = 344

	--region 거북이 연출 관련

	self.get_fx_dead = function() return unity_object_pool.GetOrCreate('FX_dead') end
	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end
	self.get_fx_star_piece_in_character = function() return unity_object_pool.GetOrCreate('FX_starpiece_in_character') end
	self.get_fx_last_hit = function()
		return unity_object_pool.GetOrCreate('FX_lasthit')
	end

	-- 마리오 거북이
	self.get_mario_turtle = function()
		return get_character('mario_turtle')
	end

	self.get_link_door = function()
		return get_field_object('link_door_switch_green')
	end

	self.get_fire_statue = function(num)
		return get_field_object('turtle_fire_statue_' .. num)
	end

	self.activate_fire_statue = { false, false }
	self.is_opened = false

	-- 거북이 마커 이름
	self.turtle_marker_name = 's1_turtle_pos'

	-- 거북이를 죽이고 스타피스를 획득 하였는지?
	self.is_get_turtle_star_piece = false

	-- 거북이 스타피스 이름
	self.turtle_star_piece_name = 'turtle_star_piece'

	-- 거북이 스타피스 이팩트
	self.turtle_star_piece_effect = nil

	-- 거북이 공격 시작 존
	self.turtle_zone_name = 'turtle_attack_zone'

	-- 거북이 어택레인지 radius
	self.hammer_radius = 1.2

	-- 거북이용 Attack range
	self.attack_range_list = nil

	-- 거북이 존에 들어왔는지?
	self.is_enter_turtle_zone = false

	-- 거북이 스테이트
	self.turtle_state = {
		pattern_active = 1,
		pause = 2,
	}
	self.cur_turtle_state = self.turtle_state.pattern_active

	self.is_dead_turtle = false

	local contants_data = require('Quest/Main/QueenCastle/Mario/Gimmick/MarioGimmickConstants')

	-- 배틀 데이터들
	self.battle_info = contants_data.etc.reset
	self.deactivate_battle_info = {
		{ zone = 'BATTLE_1', complete_section = 2 },
		{ zone = 'BATTLE_2', complete_section = 3 }
	}
	--endregion

	--region 굼바

	self.goomba_state = {
		before_open_door = 1,
		goomba_moving = 2,
		goomba_hidden = 3,
		jumped = 4,
		done = 5,
	}

	self.current_goomba_state = self.goomba_state.before_open_door

	self.get_goomba = function()
		return get_character('goomba')
	end

	self.goomba_door = {
		name = 'goomba_door_',
		count = 2,
		close = function(this)
			for i = 1, this.count do
				message_system:Publish(CS.Oak.DoorCloseEvent.Create(this.name .. i, true))
			end
		end
	}

	self.goomba_star_piece_name = 'goomba_star_piece'

	self.get_goomba_jump_interact = function()
		return get_field_object('goomba_jump_interact')
	end

	self.get_goomba_jump_block = function()
		return get_field_object('goomba_jump_block')
	end

	self.goomba_star_piece_effect = nil
	self.goomba_star_piece_effect_parent = nil
	--endregion 굼바

	--region 부끄부끄
	self.get_ghost = function()
		return get_character('ghost')
	end

	self.ghost_star_piece_name = 'ghost_star_piece'

	self.ghost_state = {
		before_enter_ghost_zone = 1,
		ghost_runaway_1 = 2,
		ghost_runaway_2 = 3,
		drop_star_piece = 4,
	}
	self.current_ghost_state = self.ghost_state.before_enter_ghost_zone

	self.ghost_star_piece_effect = nil
	self.ghost_star_piece_effect_parent = nil

	self.brazier_count = 3
	self.get_brazier = function(key)
		return get_field_object('ghost_brazier_' .. key)
	end

	self.turn_on_all_brazier = false

	self.ghost_field_tint_key = 'ghost'
	--endregion 부끄부끄

	self.already_set_field_tint = false
	self.mario_gimmick = nil

	self.stage_ended = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_ended_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	return true
end

function local_class:on_stage_ended_event(_)
	self.stage_ended = true

	self:stop_goomba_routine()

	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_link_door()) then
		sp_util.start_scene(self.interact_turtle_link_door, self)
	end

	for i = 1, #self.activate_fire_statue do
		if lua_helper.reference_equals(e.Target, self.get_fire_statue(i)) then
			sp_util.start_scene(self.interact_fire_statue, self, i)
			return
		end
	end
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if not self.is_get_turtle_star_piece then
		if type_util.is_zone_full_enter(e, leader, self.turtle_zone_name)
				and not self.is_enter_turtle_zone then
			self.is_enter_turtle_zone = true
			start_coroutine(self.turtle_routine, self)
			return true
		end
	end

	if type_util.is_zone_full_enter(e, leader, 'ghost_runaway_1') and
			self.current_ghost_state == self.ghost_state.before_enter_ghost_zone then
		self.current_ghost_state = self.ghost_state.ghost_runaway_1
		sp_util.start_scene(self.ghost_runaway_1, self)
		return true
	end

	if type_util.is_zone_full_enter(e, leader, 'ghost_runaway_2') and
			self.current_ghost_state == self.ghost_state.ghost_runaway_1 then
		self.current_ghost_state = self.ghost_state.ghost_runaway_2
		start_coroutine(self.ghost_runaway_2, self)
		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_leave(e, leader, self.turtle_zone_name) then
		self.is_enter_turtle_zone = false
		camera_util.resize_to_default(1)
		return true
	end

	return false
end

function local_class:on_damage_event(e)
	if self.is_get_turtle_star_piece then
		return false
	end

	local turtle = self.get_mario_turtle()

	if lua_helper.reference_equals(e.Info.target, turtle) then
		start_coroutine(self.drop_turtle_star_piece, self)
		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if self.turn_on_all_brazier then
		return
	end

	if type_util.is_player_enter_to_cam_grid(e, 'ghost_grid') then
		self:set_field_tint()
		return true
	end

	if not (type_util.is_player_enter_to_cam_grid(e, 'ghost_puzzle_grid_1') or
			type_util.is_player_enter_to_cam_grid(e, 'ghost_puzzle_grid_2') or
			type_util.is_player_enter_to_cam_grid(e, 'ghost_puzzle_grid_3')) then
		self:remove_field_tint()
		return true
	end
	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'brazier_reset_grid') then
		message_system:Send(get_field_object('puzzle_1_brazier_1'), CS.Oak.GimmickResetEvent.Instance)
		message_system:Send(get_field_object('puzzle_1_brazier_2'), CS.Oak.GimmickResetEvent.Instance)
		return true
	end
end

function local_class:on_brazier_on_off_event(e)
	if self.turn_on_all_brazier then
		return
	end

	for i = 1, self.brazier_count do
		if lua_helper.reference_equals(self.get_brazier(i), e.BrazierObject) and e.IsTurningOn then
			self:check_brazier()
			return true
		end
	end
	return false
end
--endregion

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
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BrazierOnOffEvent))

	self.mario_gimmick = nil

	self:dispose_attack_range()
	self:dispose_turtle_star_piece_effect()

	self:dispose_ghost_star_piece_effect()

	self:dispose_goomba_star_piece_effect()

	self:goomba_dispose()
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BrazierOnOffEvent), 'on_brazier_on_off_event')

	self.mario_gimmick = get_or_create_global_table('Quest/Main/QueenCastle/Mario/Gimmick/MarioGimmickController')
	self.mario_gimmick:load_async()

	self.get_fx_star_piece_in_character()
	self.get_fx_dead()
	self.get_fx_hit()
	self.get_fx_last_hit()
	yield_return(unity_object_pool, 'WaitAll')

	-- 거북이 세팅
	self:pre_setting_turtle()

	-- 부끄부끄 세팅
	self:pre_setting_ghost()

	-- 굼바 세팅
	self:goomba_init(quest_progress)


	self:deactivate_battle(quest_progress)

	-- 시작 연출 관리
	if quest_progress == nil or quest_progress.IsComplete then
		self:clear_s3_chasing_obj()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		--stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
		--	true, true)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		self:clear_s3_chasing_obj()
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('s4_start'),
				true, true)
	else
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

-- 조건에 따른 배틀 비활성화
function local_class:deactivate_battle(quest_progress)
	for i = 1, #self.battle_info do
		local battle_info = self.battle_info[i]
		for j = 1, #self.deactivate_battle_info do
			if battle_info.zone == self.deactivate_battle_info[j].zone then
				if quest_progress.IsComplete or
					self.deactivate_battle_info[j].complete_section <= quest_progress.InnerProgress then
					local battle_id = battle_info.battle_id
					for num = 1, battle_info.enemy_count do
						local enemy = get_character('battle_' .. battle_id .. '_' .. num)
						enemy.Position = vector(999, 0, 999)
						character_util.convert_to_npc(enemy)
						character_util.set_active_state(enemy, 'disabled')
					end
					if battle_info.battle_gates ~= nil then
						for j = 1, #battle_info.battle_gates do
							local gate_num = battle_info.battle_gates[j]
							local door = get_field_object('battlegate_' .. gate_num)
							door.ActiveState = active_state('disabled')
							door.Position = vector(999, 0, 999)
						end
					end
				end
			end
		end
	end
end

function local_class:custom_wait_for_sec(duration)
	local start_time = unity_class.time.time
	while not self.stage_ended and unity_class.time.time - start_time < duration do
		coroutine.yield()
	end
end

--region 거북이 연출

-- 거북이 세팅 함수
function local_class:pre_setting_turtle()
	-- 거북이 스타피스를 획득 하였는지 여부 확인
	self.is_get_turtle_star_piece = star_piece_util.has_star_piece(self.turtle_star_piece_name)

	-- 먹었으면 세팅할 필요 없음
	if self.is_get_turtle_star_piece then
		self.is_dead_turtle = true
		return
	end

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', false, true))

	self.get_link_door().Interactable = CS.Oak.PublishInteractable.Create()
	self.get_fire_statue(1).Interactable = CS.Oak.PublishInteractable.Create()
	self.get_fire_statue(2).Interactable = CS.Oak.PublishInteractable.Create()

	-- 거북이 데미지 받았는지 여부 확인용 데미지 이벤트 구독
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	-- 거북이 세팅
	local pos = field_util.get_marker_pos(self.turtle_marker_name)
	local turtle = self.get_mario_turtle()
	self.turtle_star_piece_effect = self.get_fx_star_piece_in_character():Instantiate(turtle.Position,
			unity_class.quaternion.identity, turtle.Transform)

	turtle:SetGiantFactor('turtle_key', 1.5)

	character_util.set_position(turtle, pos)
	character_util.set_direction(turtle, 'left')
	character_util.set_active_state(turtle, 'enabled')
	turtle.EntityGroup = CS.Oak.EntityGroups.Enemy

	-- 거북이 공격용 어택 레인지 캐싱
	self.attack_range_list = {}
	local circle_count = 10
	for _ = 1, circle_count do
		local attack_range = CS.AttackRange.CreateCircle(vector(999, 0, 999),
				self.hammer_radius, CS.Oak.AttackRangeShowType.OverlayForward)
		attack_range:Hide()
		table.insert(self.attack_range_list, attack_range)
	end
end

function local_class:turtle_routine()
	local turtle = self.get_mario_turtle()
	local leader = get_party_leader()

	-- 망치 거북이 존에 들어서면 카메라 사이즈 5.5로 변경.
	camera_util.resize_by_ratio_async(5.5, 1)
	if not self.is_enter_turtle_zone then
		return
	end

	local is_game_over = false
	local delay_list = { 0.5, 0.2, 0.5, 0.2 }

	local function is_routine_active()
		return self.is_enter_turtle_zone and not self.is_get_turtle_star_piece and not self.mario_gimmick:check_dead()
	end

	-- 루틴 멈추부분 체크 및 대기 시간 동안 화염 기믹에 데미지 들어가는거 체크용 로컬 lwait_for_sec
	local function local_wait_for_sec(time)
		local s = unity_class.time.time
		while unity_class.time.time - s < time
				and is_routine_active() and not is_game_over do
			--망치 거북이는 플레이어의 위치에 따라 left, front, right 방향을 바라본다. (상단 이미지 참고)
			character_util.look_at(turtle, leader)
			coroutine.yield(nil)
		end
	end

	local function check_attack_damage(attack_range, callback)
		if not is_routine_active() then
			return
		end

		-- 망치 거북이의 망치 1방 당 플레이어 전체 hp의 25%씩 닳는다.
		local damage_rate = 0.25
		if attack_range_util.is_contains_attack_range(attack_range, leader, self.hammer_radius - 0.8) then
			if callback then
				callback()
			end

			-- 스크린 플레이가 아닐 때 데미지를 준다.
			if not lua_helper.type_compare(
					leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
				start_coroutine(function()
					camera_util.shake(0.05, 0.3)
					self.get_fx_hit():Instantiate(leader.Position + vector(0, 0.2, 0))
					scene_util.set_emotion(leader, self, 'damaged')

					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.Trap
					damage_info.sender = turtle
					damage_info.target = leader
					damage_info.damage = math.floor(leader.FieldObjectStatsBehaviour.MaxHP * damage_rate)
					damage_info.notMortal = true
					damage_info.noCritical = true

					-- 가디언 damaged 표정으로 red pluse + squish + fx_hit + 화면 shake 0.05, 0.3초, 1회
					--TODO: 게임 오버 연출이랑 겹쳐서 0.3초 뒤에 불리는 remove_emotion가 연출꼬일 수도 있으니 체크 필요
					command_util.execute_damage(damage_info)

					wait_for_sec(0.3)
					if not self.mario_gimmick:check_dead() then
						character_util.remove_emotion(leader)
					end
				end)
			end
		end
	end

	local add_range = 0.25
	local function hammer_attack()
		-- 가로 1.5타일, 세로 1.5타일의 둥근 원형 attackragne
		local attack_range = self:get_turtle_attack_range()

		-- 가디언의 위치를 파악하여 가디언 위치에 총 4방의 hammer를 연속하여 던진다. (1번 망치 후 0.5초 대기, 2번 망치 후 0.2초 대기, 3번 망치 후 0.5초 대기, 이후 4번 망치)
		local add_x = unity_class.random.Range(-add_range, add_range)
		local add_z = unity_class.random.Range(-add_range, add_range)
		local target_pos = leader.Position + vector(add_x, 0, add_z)

		attack_range_util.setup_by_position(attack_range, target_pos, 0.01)
		attack_range_util.show(attack_range, 0)

		local hammer = drop_item_util.create_item({
			pos = vector(999, 0, 999),
			itemid = 20929,
			notforinven = true,
			lootstate = 'dontfindlooter',
			showoncharacter = true
		})

		music_player_util.play_sfx({ sfx_name = '01_swing_01', parent = turtle })
		scene_util.set_anim(turtle, self, { name = 'attack', count = 1, one_shot_sfx = false })
		character_util.normal_jump(turtle)

		local is_add_damage = false
		local hammer_time_passed = 0
		local hammer_duration = 1.5
		local height = 6

		local start_pos = turtle.Position
		local end_pos = vector_util.get_x0z(target_pos, target_pos.y - 0.25)

		local spine_count = 8
		local spine_rotate = 360 * spine_count

		-- 해머가 hammer_duration 시간 동안 날라감
		-- 시간이 95% 정도 지났을 때부터 데미지 체크
		-- 한번 데미지 검출 하면 더이상 안하고 break
		while hammer_time_passed <= hammer_duration do
			hammer_time_passed = hammer_time_passed + unity_class.time.deltaTime

			local progress = unity_class.mathf.Clamp01(hammer_time_passed / hammer_duration)
			local lerp_pos = unity_class.vector3.Lerp(start_pos, end_pos, progress)
			local cur_y = unity_class.mathf.Sin(unity_class.mathf.PI * progress) * height + lerp_pos.y
			local cur_pos = vector_util.get_x0z(lerp_pos, cur_y)

			hammer.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, 0, progress * spine_rotate)
			hammer.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, 0, progress * spine_rotate)
			drop_item_util.move_item(hammer, cur_pos)

			-- 95퍼센트 이동 했을 경우 체력 차감 체크
			if progress >= 0.975 and not is_add_damage then
				check_attack_damage(attack_range, function()
					is_add_damage = true
				end)
			end

			coroutine.yield(nil)
		end

		music_player_util.play_sfx({ sfx_name = '01_mining_01', parent = turtle })
		-- 해머 아이템 및 어택레인지 hide 이팩트 재생
		camera_util.shake(0.1, 0.1)
		self.get_fx_dead():Instantiate(hammer.Position)
		hammer:ConsumeComplete()
		attack_range:Hide()
	end

	local delay_index = 1
	self.cur_turtle_state = self.turtle_state.pattern_active
	while is_routine_active() do
		-- 퍼즈 상태가 아닐 때만 루틴 작동
		if self.cur_turtle_state ~= self.turtle_state.pause then
			-- 변신 이벤트 중에는 공격 중지
			if self.mario_gimmick:is_changing_event() then
				self.cur_turtle_state = self.turtle_state.pause
			end
			-- 해머 공격 루틴 시작
			start_coroutine(hammer_attack)

			-- 딜레이 시간 만큼 대기
			local_wait_for_sec(delay_list[delay_index])

			-- delay 시간 다 썼으면 4초 대기 시간 가진다.
			delay_index = delay_index + 1
			if delay_index > #delay_list then
				delay_index = 1
				-- 4방의 망치를 다 던진 후, 2.5초의 대기 시간을 갖는다. (이후 공격 반복)
				local_wait_for_sec(2.5)
			end
		else
			-- 변신 이벤트 끝나면 다시 공격 시작
			if not self.mario_gimmick:is_changing_event() then
				self.cur_turtle_state = self.turtle_state.pattern_active
			end
		end

		coroutine.yield(nil)
	end
end

function local_class:drop_turtle_star_piece()
	self.is_get_turtle_star_piece = true

	-- 거북이는 에어스핀으로 퇴장
	local turtle = self.get_mario_turtle()

	local start_pos = turtle.Position
	local target_pos = vector(69, 1, -3.5)

	self:dispose_turtle_star_piece_effect()
	character_util.air_spin(turtle)
	self.is_dead_turtle = true
	-- 스타피스 등장
	local star_piece = get_field_object(self.turtle_star_piece_name)
	star_piece_util.appear(star_piece, start_pos, target_pos)

	wait_for_sec(3)
end

function local_class:get_turtle_attack_range()
	if self.attack_range_list == nil then
		return nil
	end

	for i = 1, #self.attack_range_list do
		local attack_range = self.attack_range_list[i]
		if not attack_range.gameObject.activeSelf then
			return attack_range
		end
	end

	local attack_range = CS.AttackRange.CreateCircle(vector(999, 0, 999),
			self.hammer_radius, CS.Oak.AttackRangeShowType.OverlayForward)
	attack_range:Hide()
	table.insert(self.attack_range_list, attack_range)

	return attack_range
end

function local_class:dispose_attack_range()
	if self.attack_range_list ~= nil then
		for i = 1, #self.attack_range_list do
			CS.UnityEngine.Object.Destroy(self.attack_range_list[i])
		end
		self.attack_range_list = nil
	end
end

function local_class:dispose_turtle_star_piece_effect()
	if self.turtle_star_piece_effect ~= nil then
		self.turtle_star_piece_effect:Dispose()
		self.turtle_star_piece_effect = nil
	end
end

function local_class:interact_turtle_link_door()
	local switch = self.get_link_door()

	character_util.set_anim_and_emotion(user_party.Leader, { name = 'sword_attack', loop = false }, { name = 'attack' })

	local dist = switch.Position - user_party.Leader.Position;
	character_util.spine_deviate_local(user_party.Leader, dist * 0.3, 0.2, 0.3)

	wait_for_sec(0.2)

	music_player_util.play_sfx_one_shot('02_switch_button_02')
	switch:Shake(0.04, 0.3)

	self.get_fx_hit():Instantiate(switch.Position + vector(0, 0.3, 0))
	self.get_fx_last_hit():Instantiate(switch.Position + vector(0, 0.3, 0))

	character_util.remove_anim_and_emotion(user_party.Leader)

	if self.is_opened then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', false, false))
		self.is_opened = false
	else
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true, false))
		self.is_opened = true

		for i = 1, #self.activate_fire_statue do
			if self.activate_fire_statue[i] then
				self:clear_turtle_event()
				return
			end
		end
	end

	wait_for_sec(0.2)
end

function local_class:interact_fire_statue(idx)
	local statue = self.get_fire_statue(idx)

	scene_util.set_anim(get_party_leader(), self, { name = 'attack', count = 1 })

	if self.activate_fire_statue[idx] == true then
		music_player_util.play_sfx_one_shot('02_switch_button_01')
		statue.FieldObjectBehaviour:GetLuaTable():turn_off()
		self.activate_fire_statue[idx] = false
	else
		music_player_util.play_sfx_one_shot('02_switch_button_03')
		statue.FieldObjectBehaviour:GetLuaTable():turn_on()
		self.activate_fire_statue[idx] = true
	end

	wait_for_sec(0.5)

	if self.is_opened then
		self:clear_turtle_event()
	end
end

function local_class:clear_turtle_event()
	local turtle_pos = field_util.get_marker_pos('s1_turtle_pos')
	local turtle = self.get_mario_turtle()

	character_util.set_direction(turtle, 'up')
	character_util.show_emoticon(turtle, nil, 'question')

	for i = 1, #self.activate_fire_statue do
		self.get_fire_statue(i).Interactable = CS.Oak.Interactable()
	end
	self.get_link_door().Interactable = CS.Oak.Interactable()

	camera_util.move_async(turtle_pos, 0.5)

	while not self.is_dead_turtle do
		coroutine.yield(nil)
	end
	wait_for_sec(2)

	camera_util.return_to_leader(0.5)
end

--endregion

--region 굼바
function local_class:goomba_init(quest_progress)
	local goomba = self.get_goomba()

	if not self:goomba_cleared() then
		if quest_progress ~= nil and quest_progress.InnerProgress > 1 then
			character_util.set_active_state(goomba, 'visible')
			character_util.set_position(goomba, field_util.get_marker_pos('goomba_hide'))
			self.current_goomba_state = self.goomba_state.goomba_hidden
		else
			self.goomba_door:close()

				--홀더블 가능 상태
			goomba.Holdable = CS.Oak.Holdable()

			--임시 리소스 dog_corgi 사용
			--right, idle, prostrate
			character_util.set_locked_dir(goomba, 'down')
			scene_util.set_anim(goomba, self, { name = 'head', one_shot_sfx = false })
		end

		do
			local fo = self.get_goomba_jump_block()
			fo.Position = field_util.get_marker_pos('goomba_jump_block')
			fo.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1))
		end

		do
			local fo = self.get_goomba_jump_interact()
			fo.Position = field_util.get_marker_pos('goomba_jump_interact')
			fo.Hitbox = CS.Oak.Hitbox(vector(2, 1, 1))
		end

		self.goomba_star_piece_effect = self.get_fx_star_piece_in_character():Instantiate(goomba.Position)
		self.goomba_star_piece_effect_parent = self.goomba_star_piece_effect.transform.parent
		self.goomba_star_piece_effect.transform.parent = goomba.SpineController.SpineContainerTransform

		message_system:Subscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_goomba_door_opened_event')
		message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_goomba_interact_event')
	else
		do
			local pos = field_util.get_marker_pos('goomba_hide')

			character_util.set_position(goomba, pos)
			character_util.set_direction(goomba, 'down')
			character_util.set_active_state(goomba, 'visible')
			scene_util.set_anim(goomba, self, { name = 'head', one_shot_sfx = false })

			--검은 틴트 30%
			character_util.add_color(goomba, goomba.Name, unity_class.color.black, 0.5, 0)
		end
	end
end

function local_class:goomba_dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
end

function local_class:on_goomba_door_opened_event(e)
	--굼바를 들어올려 도어 스위치 중 한개에 던져넣고 플레이어가 나머지 스위치에 올라가면 도어가 열린다.
	--도어 열림과 동시에 아래 비강제 연출 진행
	if self.current_goomba_state == self.goomba_state.before_open_door and
			e.DoorHandleName == (self.goomba_door.name .. 1) then
		self.current_goomba_state = self.goomba_state.goomba_moving

		start_coroutine(self.goomba_move_routine, self)

		return true
	end

	return false
end

function local_class:on_goomba_interact_event(e)
	if self.current_goomba_state == self.goomba_state.goomba_hidden and
			lua_helper.reference_equals(e.Target, self.get_goomba_jump_interact()) then
		self.current_goomba_state = self.goomba_state.jumped

		sp_util.start_scene(self.goomba_jump_scene, self)

		return true
	end

	return false
end

function local_class:goomba_cleared()
	return star_piece_util.has_star_piece(self.goomba_star_piece_name)
end

function local_class:goomba_move_routine()
	local goomba = self.get_goomba()

	goomba.Holdable = CS.Oak.NonHoldable.Instance

	music_player_util.play_sfx({ sfx_name = '03_dialogue_angry_01', parent = goomba })
	--emoticon_bubble_angry
	local goomba_emoticon = character_util.show_emoticon_with_data(goomba,
			nil, 'angry', nil, { no_time_limit = true })

	self:custom_wait_for_sec(2.5)

	-- stage_ended가 되든, 정상적으로 종료되든 결국 Dispose 해줘야 함
	goomba_emoticon:Dispose()

	if self.stage_ended then
		return
	end

	character_util.shake(goomba, 0.03, 0.3)
	self:custom_wait_for_sec(0.6)

	if self.stage_ended then
		return
	end

	character_util.shake(goomba, 0.03, 0.3)
	self:custom_wait_for_sec(0.3)

	if self.stage_ended then
		return
	end

	--굼바 right, idle, idle +
	character_util.remove_anim_and_emotion(goomba)

	--굼바 스파인 (충돌처리x)에
	-- 어차피 점프 인터랙트 안밟으면 못들어가니 그냥 여기서부터 파티션에서 빼버림
	character_util.set_active_state(goomba, 'visible')

	goomba.SpineController.AlwaysUpdateSpine = true

	--굼바, 하늘색 원으로 걸어 올라간다. (속도2)
	local target_pos = field_util.get_marker_pos('goomba_hide')
	local jump_start_pos = field_util.get_marker_pos('goomba_hide_turn_z') + vector(0, 0, 1)
	local speed = 2.5
	local waypoints = wp_util.get_turn_twice_wp(goomba, jump_start_pos, { x = jump_start_pos.x })

	wp_util.move_async(goomba, waypoints, speed)

	if self.stage_ended then
		return
	end

	music_player_util.play_sfx({ sfx_name = '01_jump_01', parent = goomba })
	--올라가 있는 청홍벽을 지날 땐 굼바가 점프해서 올라가는 것처럼 연출로 부탁드립니다
	character_util.jump(goomba, 2, 2 / speed)
	wp_util.move_async(goomba, target_pos, speed, nil, { last_direction = 'down' })

	goomba.SpineController.AlwaysUpdateSpine = false
	if self.stage_ended then
		return
	end

	self.current_goomba_state = self.goomba_state.goomba_hidden
end

function local_class:stop_goomba_routine()
	if self.current_goomba_state == self.goomba_state.done then
		return
	end

	self.current_goomba_state = self.goomba_state.done

	local goomba = self.get_goomba()

	character_util.stop(goomba)
end

function local_class:goomba_jump_scene()
	local goomba = self.get_goomba()
	local knight = get_party_leader()

	--가디언 right, attack, get+jump
	scene_util.set_direction_by_args(knight, { dir = 'right', sfx = false })
	scene_util.set_emotion(knight, self, 'attack')
	scene_util.set_anim(knight, self, 'get')

	music_player_util.play_sfx_one_shot('01_arcade_throw_01')

	do
		local dirs = {
			'down',
			'left',
			'up',
			'right',
		}

		local cur_dir_index = 1
		local target_dir_count = 4
		local target_pos = goomba.Position
		local start_pos = knight.Position
		local jump_height = 3
		local stepped_on = false

		coroutine_util.while_each_frame(1, function(progress)
			local cur_add_y = math.sin(math.pi * progress) * jump_height
			local cur_xz = start_pos * (1 - progress) + target_pos * progress

			character_util.set_position(knight, cur_xz + unity_class.vector3.up * cur_add_y)

			--360도로 빠르게 빙글빙글 돌며 굼바에게 내려온다
			if cur_dir_index / target_dir_count <= progress then
				character_util.set_direction(knight, dirs[cur_dir_index])

				cur_dir_index = cur_dir_index % 4 + 1
			end

			if not stepped_on and knight.Position.y < 0.7 then
				stepped_on = true

				music_player_util.play_sfx_one_shot('01_arcade_hit_wall_01')
				self:dispose_goomba_star_piece_effect()
				--굼바에게 착지 시 fx_dead 이펙트 +
				self.get_fx_dead():Instantiate(goomba.Position)

				--화면 shake 0.1, (0.3초, 1회)와 함께
				camera_util.shake(0.2, 0.3)

				--굼바 애니메이션 down, idle, head + 검은 틴트 30% (임시로 prostrate사용)으로 변경되어있고
				scene_util.set_anim(goomba, self, 'head')
				character_util.add_color(goomba, goomba.Name, unity_class.color.black, 0.5, 0.2)

				--굼바 스파인 (충돌처리x)에 인터랙트하면 나래이션 박스가 출력된다.
			end
		end)
	end

	character_util.remove_anim_and_emotion(knight)

	star_piece_util.appear(get_field_object(self.goomba_star_piece_name), goomba.Position)

	self.get_goomba_jump_interact().ActiveState = active_state('disabled')
	self.get_goomba_jump_block().ActiveState = active_state('disabled')

	--인터랙트하면 나래이션 박스가 출력된다.
	--이번 생은 밟히기 싫었던 어느 버섯의 최후의 모습이 남아있다.
	self.current_goomba_state = self.goomba_state.done
end

function local_class:dispose_goomba_star_piece_effect()
	if self.goomba_star_piece_effect ~= nil then
		self.goomba_star_piece_effect.transform.parent = self.goomba_star_piece_effect_parent
		self.goomba_star_piece_effect:Dispose()
		self.goomba_star_piece_effect = nil
	end
	self.goomba_star_piece_effect_parent = nil
end

--endregion 굼바

--region 부끄부끄
-- 부끄부끄 세팅
function local_class:pre_setting_ghost()
	-- 스타피스를 얻은 상태면 무시
	 if star_piece_util.has_star_piece(self.ghost_star_piece_name) then
	 	self.current_ghost_state = self.ghost_state.drop_star_piece
		return
	 end

	local ghost = self.get_ghost()
	local pos = field_util.get_marker_pos('ghost_follow_start')
	ghost.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	self.ghost_star_piece_effect = self.get_fx_star_piece_in_character():Instantiate(ghost.Position)
	self.ghost_star_piece_effect_parent = self.ghost_star_piece_effect.transform.parent
	self.ghost_star_piece_effect.transform.parent = ghost.SpineController.SpineContainerTransform
	character_util.set_position(ghost, pos)
	character_util.set_direction(ghost, 'down')

	start_coroutine(self.ghost_routine, self)
end

-- 부끄부끄 행동 루틴
function local_class:ghost_routine()
	local ghost = self.get_ghost()
	local start_pos = field_util.get_marker_pos('ghost_follow_start')
	local end_pos = field_util.get_marker_pos('ghost_follow_end')
	local leader = get_party_leader()

	character_util.set_direction(ghost, 'left')
	while self.current_ghost_state == self.ghost_state.before_enter_ghost_zone and not self.stage_ended do
		if leader.Direction == CS.Oak.Direction.Right then
			character_util.set_emotion(ghost, { name = 'blush' })
		else
			character_util.remove_emotion(ghost)
		end

		if self.mario_gimmick:ended_dead_fade() then
			if leader.Position.z < start_pos.z then
				character_util.set_position(ghost, vector(ghost.Position.x, 1, start_pos.z))
			elseif leader.Position.z > end_pos.z then
				character_util.set_position(ghost, vector(ghost.Position.x, 1, end_pos.z))
			else
				character_util.set_position(ghost, vector(ghost.Position.x, 1, leader.Position.z))
			end
		end

		coroutine.yield(nil)
	end
	scene_util.set_emotion(ghost, self, 'blush')
end

-- 부끄부끄 도주 이벤트
function local_class:ghost_runaway_1()
	local ghost = self.get_ghost()
	local leader = get_party_leader()
	local align_pos = {
		vector(ghost.Position.x - 1.7, 1, leader.Position.z),
		ghost.Position + vector(-1, 0, 0) }
	local ghost_end_pos = field_util.get_marker_pos('ghost_runaway_pos_1')

	music_player_util.change_stage_music_volume('field', 0.5)

	scene_util.set_emotion(leader, self, 'smile')

	character_util.shake(ghost, 0.03, 9999)

	wp_util.move_async(leader, align_pos, 2, nil)
	character_util.set_direction(leader, 'right')
	character_util.show_emoticon_async(leader, nil, 'question')

	character_util.stop_shake(ghost)

	music_player_util.play_sfx_one_shot('01_ghost_scream_01')
	camera_util.shake(0.1, 0.3)
	character_util.set_anim(ghost, { name = 'scream' })
	character_util.set_emotion(ghost, { name = 'scream' })

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	scene_util.set_emotion(leader, self, 'damaged')
	character_util.normal_jump(leader)

	wait_for_sec(0.5)
	character_util.remove_anim(ghost)
	character_util.set_emotion(ghost, { name = 'blush' })

	wp_util.move_async(ghost, ghost.Position + vector(7, 0, 0), nil, 1)

	character_util.remove_emotion(leader)
	character_util.set_position(ghost, ghost_end_pos)

	character_util.set_direction(ghost, 'down')

	music_player_util.change_stage_music_volume('field', 1)
end

-- 부끄부끄 도주 이벤트2
function local_class:ghost_runaway_2()
	local ghost = self.get_ghost()
	local ghost_wp_1 = field_util.get_marker_pos('ghost_runaway_pos_2')
	local ghost_wp_2 = field_util.get_marker_pos('ghost_runaway_pos_3')
	local ghost_wp_3 = field_util.get_marker_pos('ghost_runaway_pos_4')
	local speed = 4
	local fade_time = vector_util.get_x0z(ghost.Position - ghost_wp_1).magnitude / 4 / 2

	wp_util.move(ghost, ghost_wp_1, speed)

	character_util.spine_set_alpha_fade(ghost, 0, fade_time)
	wait_for_sec(fade_time)
	character_util.spine_set_alpha_fade(ghost, 1, fade_time)
	wait_for_sec(fade_time)
	wp_util.move_async(ghost, ghost_wp_2, speed)

	wp_util.move_async(ghost, { vector(ghost.Position.x, 0, ghost_wp_3.z), ghost_wp_3 }, speed)

	character_util.set_direction(ghost, 'right')
	character_util.set_anim(ghost, { name = 'sleep' })
	character_util.set_emotion(ghost, { name = 'sleep' })
	character_util.spine_set_alpha_fade(ghost, 0.4, 0.5)

	character_util.show_emoticon(ghost, nil, 'happy')
end

-- 부끄부끄 스타피스 이펙트 끄기
function local_class:dispose_ghost_star_piece_effect()
	if self.ghost_star_piece_effect ~= nil then
		self.ghost_star_piece_effect.transform.parent = self.ghost_star_piece_effect_parent
		self.ghost_star_piece_effect:Dispose()
		self.ghost_star_piece_effect = nil
	end
	self.ghost_star_piece_effect_parent = nil
end

-- 필트 틴트 세팅
function local_class:set_field_tint()
	if not self.already_set_field_tint then
		self.already_set_field_tint = true
		field:Tint(self.ghost_field_tint_key, unity_class.color.black, 0.2, 0.5)
	end
end

-- 필드 틴트 끄기
function local_class:remove_field_tint()
	if self.already_set_field_tint then
		self.already_set_field_tint = false
		field:RemoveTint(self.ghost_field_tint_key, 0.2)
	end
end

-- 블레이저 체크
function local_class:check_brazier()
	local burning_brazier_count = 0
	local ghost = self.get_ghost()
	for i = 1, self.brazier_count do
		if self.get_brazier(i).CombustibleBehaviour.IsBurning then
			burning_brazier_count = burning_brazier_count + 1
		end
	end

	if self.current_ghost_state == self.ghost_state.ghost_runaway_2 then
		if burning_brazier_count == 1 then
			character_util.shake(ghost, 0.03, 0.3)
			character_util.spine_set_alpha_fade(ghost, 0.6, 0.2)
		elseif burning_brazier_count == 2 then
			character_util.shake(ghost, 0.03, 0.3)
			character_util.spine_set_alpha_fade(ghost, 0.8, 0.2)
		end
	end

	if burning_brazier_count >= self.brazier_count then
		self.turn_on_all_brazier = true
		self:remove_field_tint()
		if self.current_ghost_state == self.ghost_state.ghost_runaway_2 then
			self.current_ghost_state = self.ghost_state.drop_star_piece
			sp_util.start_scene(self.clear_ghost_scene, self)
		end
	end
end

-- 부끄부끄 스타피스 이벤트 클리어
function local_class:clear_ghost_scene()
	local ghost = self.get_ghost()
	local star_piece_pos = ghost.Position
	local leader = get_party_leader()

	music_player_util.change_stage_music_volume('field', 0.5)

	party_util.align_party(ghost.Position, 'left', 1, 'arc')

	character_util.spine_set_alpha_fade(ghost, 1, 0.2)

	character_util.shake(ghost, 0.03, 0.3)
	wait_for_sec(0.6)
	character_util.shake(ghost, 0.03, 0.3)
	wait_for_sec(0.6)
	character_util.remove_anim_and_emotion(ghost)

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.show_emoticon_async(ghost, nil, 'question')

	scene_util.set_emotion(leader, self, 'smile')
	scene_util.set_anim(leader, self, { name = 'jingak', loop = false,
			count = 1, keep = true, scale = 0.5 })
	wait_for_sec(1.4)
	music_player_util.play_sfx_one_shot('02_twohand_stomp_01')
	camera_util.shake(0.1, 0.3)

	scene_util.set_emotion(ghost, self, 'surprise')
	character_util.normal_jump(ghost)
	wait_for_sec(0.3)

	music_player_util.play_sfx_one_shot('03_runaway_02')
	scene_util.set_emotion(ghost, self, 'confused')
	local ghost_dir = { 'up', 'right', 'down', 'left' }
	for i = 0, 31 do
		local idx = (i % 4) + 1
		character_util.set_direction(ghost, ghost_dir[idx])
		wait_for_sec(0.05)
	end
	for i = 0, 15 do
		local idx = (i % 4) + 1
		character_util.set_direction(ghost, ghost_dir[idx])
		wait_for_sec(0.1)
	end

	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	scene_util.set_anim(leader, self, 'dance3')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('03_dialogue_bad_01')

	scene_util.set_emotion(ghost, self, 'scared')
	character_util.show_emoticon_async(ghost, nil, 'notice')
	character_util.shake(ghost, 0.1, 2)
	wait_for_sec(2)

	local move_key = 'ghost_move'
	local speed = 7
	local wp = {
		ghost.Position + vector(1.5, 0, 0),
		ghost.Position + vector(1.5, 0, 2.5),
		ghost.Position + vector(1.5, 1, 3),
		ghost.Position + vector(1.5, 1, 8),
	}
	self:dispose_ghost_star_piece_effect()

	character_util.remove_anim_and_emotion(leader)

	music_player_util.play_sfx_one_shot('01_cry_01')
	scene_util.set_emotion(ghost, self, 'cry')
	wp_util.move_with_end_callback(ghost, wp, speed, nil, self, move_key,
			{ last_direction = 'down'})

	wait_for_sec(0.5)
	star_piece_util.appear(get_field_object(self.ghost_star_piece_name), ghost.Position, star_piece_pos)

	wp_util.wait_move_end(self, move_key)

	character_util.set_position(ghost, vector(999, 0, 999))

	music_player_util.change_stage_music_volume('field', 1)
end

--endregion 부끄부끄

function local_class:clear_s3_chasing_obj()
	local bomb = get_field_object('run_bomb_grass')
	get_field_object('run_rock_1').Position = vector(999, 0, 999)
	get_field_object('run_rock_2').Position = vector(999, 0, 999)
	get_field_object('run_rock_3').Position = vector(999, 0, 999)

	local obj_list = field:GetFieldObjectsInRadius(bomb.Position, 0.5)
	for i = 0, obj_list.Count - 1 do
		local fo = obj_list[i]
		if fo.Name == '[GIMMICK]bomb_grass1' then
			fo.ActiveState = active_state('disabled')
		end
	end
	obj_list:Dispose()
	bomb.Position = vector(999, 0, 999)

	local door_1 = get_field_object('run_door_1')
	local door_2 = get_field_object('rum_door_2')
	local opened_door_1 = get_field_object('run_opened_door_1')
	local opened_door_2 = get_field_object('run_opened_door_2')
	local door_1_pos = door_1.Position
	local door_2_pos = door_2.Position

	opened_door_1.Position = door_1_pos
	door_1.Position = vector(999, 0, 999)
	opened_door_2.Position = door_2_pos
	door_2.Position = vector(999, 0, 999)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
