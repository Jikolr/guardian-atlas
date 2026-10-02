local local_class = newclass('TowerSnakeGame')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}
	self.current_progress = self.progress.none

	self.android_count = 10
	self.spawn_marker_count = 0
	self.follow_count = 0
	self.spawn_mobs = {}
	self.mob_move_points = {}

	self.spawn_mob_name_prefix = 'spawn_mob_'
	self.spawn_marker_prefix = 'spawn_point_'
	self.start_move_speed = 4
	self.door_clear_name = 'door_clear'

	--- 대상과 부딪혔는지 판단할 체커
	self.hit_targets = {}

	self.event_fail = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseEndEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_event')

	get_field_object('thorn_block_1').ActiveState = active_state('disabled')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FX_reset_object')
	coroutine.yield(unity_object_pool.WaitAll())
end

function local_class:need_on_launch()
	return false
end

-- Tower스테이지 컨트롤러의 이벤트를 받아 가이드 연출 실행
function local_class:on_stage_start_event()
	sp_util.play_normal_screenplay(self.display_guide, self)

	return false
end

function local_class:on_launch(_)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self.cs_controller = nil
end

function local_class:on_stage_loaded_event(_)
	local idx = 1
	while(true) do
		local mob = get_character(self.spawn_mob_name_prefix .. idx)

		if mob == nil then
			break
		else
			mob.ActiveState = active_state('disabled')
			table.insert(self.spawn_mobs, mob)
			idx = idx + 1
		end
	end

	idx = 1
	while(true) do
		local marker_name = self.spawn_marker_prefix .. idx
		if not field:HasMarker(marker_name) then
			break
		end

		self.spawn_marker_count = self.spawn_marker_count + 1
		idx = idx + 1
	end

	-- 퀘스트 마커 표시
	ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(10, 0, -0.5))

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, 'mini_game_trigger') and self.current_progress == self.progress.none then
		self.current_progress = self.progress.playing
		sp_util.play_normal_screenplay(self.start_snake_game, self)
	end

	return false
end

function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.PauseStartEvent) then
		self.is_pause = true
		return true
	elseif event_type == typeof(CS.Oak.PauseEndEvent) then
		self.is_pause = false
		return true
	elseif event_type == typeof(CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'over_worm_game' then
			self.event_fail = true
			return true
		end
	elseif event_type == typeof(CS.Oak.DamageEvent) then
		-- 넉백으로 이벤트처리가 안되고 가시블록에 대한 데미지 이벤트만 받을 경우 꼬이는 현상
		-- 구조가 안좋아서 리펙토링을 할 기회가 있다면 무조건 하는것이 좋아보임
		-- 플레이어가 NPC 데이미 비헤이비어를 사용중일 뿐더러 이 조건이 게임 종료에 영향을 미치지 않아 추가
		if lua_helper.reference_equals(e.Info.target, user_party.Leader) then
			self.event_fail = true
			return true
		end
	end

	return false
end

function local_class:display_guide()
	-- 안드로이드 {0}기를 모두 수거하세요.
	field_ui_util.show_narration_async({ key = game_string:Format('tower_puzzle_38_narration', self.android_count) })
end

-- 미니게임 시작
function local_class:start_snake_game()
	-- 퀘스트 마커 제거
	ui_quest_marker:RemoveQuestMarker('game_start')

	-- 관련 변수 초기화
	self.follow_count = 0
	self.mob_move_points = {}

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	character_util.remove_anim_and_emotion(user_party.Leader)

	local game_position = stage.Field:GetMarker('mini_game_start').position

	-- 파티원들 제외
	for i = user_party.Count - 1, 1, -1 do
		local member = user_party[i]
		character_util.convert_to_npc(member)
		member.ActiveState = active_state('disabled')
	end

	-- 리더 위치 변경
	character_util.set_position(user_party.Leader, game_position)
	character_util.set_direction(user_party.Leader, 'left')

	-- 리더가 스네이크 게임을 할때는 데미지를 받지않고 리액션만 취하도록하기위해 NPC 데미지 비헤비어로 갈아끼워준다.
	user_party.Leader.DamagedBehaviour = CS.Oak.NPCCharacterDamagedBehaviour.Create()

	-- 미니게임 게이트 닫기
	for i = 1, 2 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('wormgame_gate_' .. i))
	end

	-- 장애물 세팅
	local thorn = get_field_object('thorn_block_1')
	thorn.ActiveState = active_state('enabled')
	thorn.Position = vector(10, 0, 4)

	local spawn_line_numbers = {}
	for i =1, self.spawn_marker_count do
		table.insert(spawn_line_numbers, i)
	end

	-- 몹들 세팅
	local last_spawn_line = -1
	for _, mob in ipairs(self.spawn_mobs) do
		local y = random_util.get_random_int(0, 3)

		local x
		if last_spawn_line >= 0 then
			local pick = {table.unpack(spawn_line_numbers)}
			table.remove(pick, last_spawn_line)
			local pulled = random_util.get_values_in_array(pick)
			x = pulled[1]
		else
			x = random_util.get_random_int(1, self.spawn_marker_count)
		end

		local spawn_pos = stage.Field:GetMarker(self.spawn_marker_prefix .. x).position + vector(0, 0, y * 2)
		character_util.set_position(mob, spawn_pos)
		mob.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		mob.ActiveState = active_state('disabled')
		last_spawn_line = x
	end

	wait_for_sec(0.5)
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	music_player:PlaySfxOneShot('01_stage_intro_jump_01')

	character_util.set_anim(user_party.Leader, { name = 'victory_get', loop = false })
	wait_for_sec(1.5)

	field_ui_manager:Show()
	user_party:ResetControllers()

	-- 플레이어 state 변경
	local speed = self.start_move_speed
	local ckms = CS.Oak.CharacterControllerWormGameMoveState.Create(user_party.Leader, speed, CS.Oak.Direction.Left)
	message_system:SendSync(user_party.Leader, CS.Oak.StateChangeEvent.Create(ckms))

	self.run_sound = music_player_util.play_sfx({ sfx_name = '01_dash_01', loop = true})
	character_util.set_anim(user_party.Leader, { name = 'run' })

	self.event_fail = false

	local cur_position = vector(99,0,99)
	local check_time = 0
	while self.follow_count < #self.spawn_mobs do
		-- 게임 진행 중 다음에 나올 몹 생성
		local mob = get_character(self.spawn_mob_name_prefix .. self.follow_count + 1)
		if mob.ActiveState == active_state('disabled') then
			music_player:PlaySfxOneShot('01_guild_warp_01')
			mob.ActiveState = active_state('enabled')
			unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(mob.Position)
			coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.check_collision, self, mob))

			if self.follow_count >= 1 then
				-- {0}기 남았습니다.
				speech_bubble_util.show_speech_bubble(get_character('spawn_mob_1'),
					{ key=  game_string:Format('tower_puzzle_38_count', #self.spawn_mobs - self.follow_count)
					})
			end
		end

		-- 플레이어 부딪혔는지 체크
		if not self.is_pause then
			if cur_position == user_party.Leader.Position or self.event_fail then
				check_time = check_time + unity_class.time.deltaTime
				if check_time > 0.05 or self.event_fail then

					local knock_back_info = CS.Oak.KnockBackInfo()
					knock_back_info.type = CS.Oak.KnockBackType.Physics
					knock_back_info.stun = true
					knock_back_info.direction = direction_util.to_vector3(direction_util.get_opposite(user_party.Leader.Direction))
					knock_back_info.impactForce = 5000
					knock_back_info.impactTime = 0.05
					knock_back_info.muCoefficient = CS.Oak.Constants.DefaultFrictionCoefficient

					local ckms = CS.Oak.CharacterKnockBackState.Create(user_party.Leader, knock_back_info)
					user_party.Leader.FieldObjectBehaviour:OnEvent(CS.Oak.StateChangeEvent.Create(ckms))

					break
				end
			else
				cur_position = user_party.Leader.Position
				check_time = 0
			end
		end

		local count = 0
		if self.follow_count >= count then
			count = count + 1
			user_party.Leader.FieldObjectController.CurrentState.speed = speed + self.follow_count * 0.17
		end

		coroutine.yield()
	end

	self:result_process(self.follow_count == #self.spawn_mobs)
end

function local_class:check_collision(mob)
	coroutine_manager:StartCoroutine(
			stage.StageGameObject, util.cs_generator(self.moving_mob, self, mob))

	local leader_crashed = false
	local next_pos = user_party.Leader.Position
	local cur_pos = next_pos
	while not leader_crashed and lua_helper.type_compare(mob.CrashBehaviour, CS.Oak.EtherealCrashBehaviour) and
			self.current_progress == self.progress.playing do
		cur_pos = next_pos
		next_pos = user_party.Leader.Position

		local collide_fos = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(user_party.Leader.Bounds, next_pos - cur_pos)

		if collide_fos:Contains(mob) and not leader_crashed then
			leader_crashed = true
		end

		collide_fos:Dispose()

		coroutine.yield()
	end

	if self.current_progress == self.progress.playing and leader_crashed then
		--- 대상과 부딪혔다는 사실을 체크 (다른 루틴에서 확인 가능하도록)
		self.hit_targets[mob] = true

		mob.Position = cur_pos
		mob.Direction = user_party.Leader.Direction
		local dir_vector = CS.Oak.DirectionExtensions.ToVector3(user_party.Leader.Direction)
		character_util.set_position(mob, cur_pos - dir_vector)

		mob.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		local clms = CS.Oak.CharacterControllerPartyFollowerNPCState.Create(mob, user_party, self.follow_count, 0, 0.3, false)
		mob:OnEvent(CS.Oak.StateChangeEvent.Create(clms))
		self.follow_count = self.follow_count + 1

		if self.follow_count ~= 1 then
			mob.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		end
	end
end

function local_class:moving_mob(mob)
	local current_pos
	while self.current_progress == self.progress.playing and lua_helper.type_compare(mob.CrashBehaviour, CS.Oak.EtherealCrashBehaviour) and
		-- 스네이크 대상에 부딪혔는가?
		self.hit_targets[mob] == nil do

		local x = random_util.get_random_int(1, self.spawn_marker_count)
		local y = random_util.get_random_int(0, 3)
		local rand = random_util.get_random_int(1, 4)

		local marker_pos = stage.Field:GetMarker(self.spawn_marker_prefix .. x).position
		local next_x = vector(marker_pos.x, 0, mob.Position.z)
		local next_y = vector(mob.Position.x, 0, marker_pos.z + y * 2)
		local next_pos = marker_pos + vector(0, 0, y * 2)

		if current_pos ~= next_pos then
			current_pos = next_pos
			if rand == 1 then
				yield_return_func(self.move_to, self, mob, next_x, nil, 4, true, true)
				yield_return_func(self.move_to, self, mob, next_pos, nil, 4, true, true)
				wait_for_sec(0.3)
			elseif rand == 2 then
				yield_return_func(self.move_to, self, mob, next_y, nil, 4, true, true)
				yield_return_func(self.move_to, self, mob, next_pos, nil, 4, true, true)
				wait_for_sec(0.3)
			elseif rand == 3 then
				yield_return_func(self.move_to, self, mob, next_x, nil, 4, true, true)
				wait_for_sec(0.3)
			elseif rand == 4 then
				yield_return_func(self.move_to, self, mob, next_y, nil, 4, true, true)
				wait_for_sec(0.3)
			end
		end

		coroutine.yield()
	end
end

function local_class:move_to(fo, position, duration, speed, auto_direction, auto_animation, play_sfx)
	local time_passed = 0
	local start_pos = fo.Position

	local final_duration = 1
	if duration ~= nil then
		final_duration = duration
	elseif speed ~= nil then
		final_duration = (position - start_pos).magnitude / speed
	end

	if auto_direction ~= nil and auto_direction then
		local dir = (position - fo.Position):ToDirection()
		if dir ~= CS.Oak.Direction.None then
			fo.Direction = dir
		end
	end

	if auto_animation ~= nil and auto_animation and lua_helper.type_compare(fo, CS.Oak.Character) then
		character_util.set_anim(fo, { name = 'walk' })
	end

	local dash_sfx = nil

	if play_sfx ~= nil and play_sfx then
		dash_sfx = music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = fo, loop = true, max_distance = 10, type_priority = 'loop', player_priority = 'npc' })
	end

	while self.hit_targets[fo] == nil do
		time_passed = time_passed + unity_class.time.deltaTime
		if time_passed >= final_duration then
			break
		end

		fo.Position = unity_class.vector3.Lerp(start_pos, position, time_passed / final_duration)
		coroutine.yield()
	end

	if self.hit_targets[fo] == nil then
		fo.Position = position
	end

	if dash_sfx ~= nil then
		dash_sfx:FadeOut(0.2)
	end

	if auto_animation ~= nil and auto_animation and lua_helper.type_compare(fo, CS.Oak.Character) then
		character_util.remove_anim(fo)
	end
end

function local_class:result_process(clear)
	self.current_progress = self.progress.none

	if self.run_sound ~= nil then
		self.run_sound:Stop()
		self.run_sound = nil
	end

	if clear then
		music_player:PlaySfxOneShot('03_gimmick_jingle_01')
		character_util.stop(user_party.Leader)
		character_util.set_direction(user_party.Leader, 'down')
		character_util.set_emotion(user_party.Leader, { name = 'awesome' })
		character_util.set_anim(user_party.Leader, { name = 'success' })
		wait_for_sec(2)

		-- 클리어 시 클리어 플래그로 향하는 동쪽 문 오픈
		self.current_progress = self.progress.cleared
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_clear_name, false))
		wait_for_sec(2)
	else
		--- 대상 리스트 초기화
		if self.hit_targets then
			for key in pairs(self.hit_targets) do
				self.hit_targets[key] = nil
			end
		end

		music_player:PlaySfxOneShot('01_hit_comic_01')
		character_util.set_emotion(user_party.Leader, { name = 'confused' })
		character_util.set_anim(user_party.Leader, { name = 'embarrassed' })
		wait_for_sec(1)
		ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(10, 0, -0.5))
	end

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 장애물 비활성화
	get_field_object('thorn_block_1').ActiveState = active_state('disabled')

	-- 미니게임 게이트 열기
	for i = 1, 2 do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create('wormgame_gate_' .. i))
	end

	-- 유저 원래대로
	local end_marker = field:GetMarker('mini_game_end')
	character_util.remove_anim(user_party.Leader)
	character_util.remove_emotion(user_party.Leader)
	character_util.set_position(user_party.Leader, end_marker.position)
	character_util.set_direction(user_party.Leader, 'right')
	user_party.Leader.DamagedBehaviour = CS.Oak.ManualCharacterDamagedBehaviour.Create();

	camera_util.resize_to_default(0)
	camera_util.return_to_leader(0.05)

	-- 안드로이드들 제거
	for _, mob in ipairs(self.spawn_mobs) do
		mob:OnEvent(CS.Oak.StateResetEvent.Instance)
		mob.CrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
		character_util.set_position(mob, vector(99, 0, 99))
		mob.ActiveState = active_state('disabled')
	end

	-- 기존 파티 합류
	local align_dir = direction_util.to_vector3(direction_util.get_opposite(end_marker.direction))
	local origin_party = party_util.get_origin_party()
	for i, member in ipairs(origin_party) do
		if not lua_helper.reference_equals(member,user_party.Leader) then
			member.ActiveState = active_state('enabled')
			member.Position = user_party.Leader.Position + align_dir * (i - 1)
			character_util.convert_to_party_member(member, user_party)
		end
	end

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')
end


return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
