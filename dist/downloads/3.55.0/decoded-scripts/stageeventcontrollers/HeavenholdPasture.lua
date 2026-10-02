local local_class = newclass('HeavenholdPasture')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 몬스터 매니저
	self.monster_manager = CS.Oak.HeavenHoldPastureSystem.Instance.MonsterManager

	-- 너굴걸 핸들네임
	self.raccoon_handle_name = 'npc_raccoon'

	-- 너굴걸 초기 위치
	self.raccoon_init_pos = nil

	-- 경비 몬스터 핸들네임(뒤에 1~2가 붙음)
	self.guard_handle_name = 'npc_guard'

	-- 시작 마커 네임
	self.default_marker_name = 'default_start'

	-- 몬스터 복수 이벤트 시작 여부
	self.monsters_revenge_started = false

	-- 복수 존 네임
	self.revenge_zone_name = 'revengeZone'

	-- 도망 존 네임
	self.run_zone_name = 'runZone'

	-- 도망 여부
	self.run_away_started = false

	-- 경비견 인사 여부
	self.guard_greeting_state = {}

	-- 복수 연출 이동 수 체크
	self.move_end_count = 0
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	-- 복수 연출 중 건초 부술 때 이펙트
	self.fx_dead = unity_object_pool.GetOrCreate('FX_dead')

	-- 목장 영역(복수 연출을 위해 기억)
	self.revenge_zone_bounds = field_util.get_zone(self.revenge_zone_name).Bounds
	self.run_zone_bounds = field_util.get_zone(self.run_zone_name).Bounds
	self.pasture_center_pos = self.revenge_zone_bounds.center

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
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

-------------------------------------------------

--region Main

-- 복수 연출
function local_class:monsters_revenge(monster)
	-- 복수에 참가하는 NPC
	local raccoon = get_character(self.raccoon_handle_name)
	local dancer1 = get_character(self.guard_handle_name .. '1')
	local dancer2 = get_character(self.guard_handle_name .. '2')

	-- 너굴걸과 경비견 초기 위치 기억
	local raccoon_init_pos = raccoon.Position
	local dancer1_init_pos = dancer1.Position
	local dancer2_init_pos = dancer2.Position

	-- 몬스터가 플레이어에게 다가옴
	local diff = vector_util.normalized(user_party.Leader.Position - monster.Position)
	self:face_to(monster, user_party.Leader.Position)
	self:face_to(user_party.Leader, monster.Position)
	character_util.set_emotion(user_party.Leader, {name = 'surprise'})
	-- 들고 있는 건초 내려놓기
	if lua_helper.type_compare(user_party.Leader.FieldObjectBehaviour.CurrentActionState, typeof(CS.Oak.CharacterHoldUpState)) then
		character_util.release_hold_object(user_party.Leader, user_party.Leader.CharacterBehaviour.CurrentActionState.HoldTarget)
	end
	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	self:near_to_pos(monster, user_party.Leader.Position, 2)

	-- 화내는 이모티콘
	character_util.set_emotion(monster, {name = 'attack'})
	music_player_util.play_sfx_one_shot('03_dialogue_angry_01')
	character_util.show_emoticon_async(monster, nil, 'angry')

	-- 추격전
	self.run_away_started = true
	local chaseSfx = music_player_util.play_sfx({sfx_name = "03_pet_bite_loop_01", loop = true})
	music_player_util.play_sfx_one_shot('03_runaway_01')
	character_util.hide_weapon(user_party.Leader, true)
	self.run_away_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.run_away, self, user_party.Leader, monster))
	self.move_to_leader_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to_leader, self, monster))
	local duration = 0
	local duration_max = 3
	while duration < duration_max * 2 do
		duration = duration + unity_class.time.deltaTime
		if duration >= duration_max and CS.BoundsExtensions.ContainsXZ(self.revenge_zone_bounds, user_party.Leader.Position) then
			break
		end
		coroutine.yield()
	end
	self.run_away_started = false

	-- 도망, 추적 완전히 끝날 때까지 대기
	while self.run_away_coroutine ~= nil or self.move_to_leader_coroutine ~= nil do
		coroutine.yield()
	end

	-- 복수 참가 몬스터 찾기
	local revenger_max = 8
	local revenger_list = {}
	table.insert(revenger_list, monster)
	table.insert(revenger_list, raccoon)
	local near_monster_list = self.monster_manager:GetAdjacentMonsters(user_party.Leader.Position, revenger_max - 1)
	for i = 0, near_monster_list.Count - 1 do
		local npc = near_monster_list[i]
		if npc ~= monster then
			table.insert(revenger_list, npc)

			-- 최대 인원 다 모였으면 충분
			if #revenger_list >= revenger_max then
				break
			end
		end
	end
	wait_for_sec(0.1)

	-- 다구리 지점
	local target_pos_list = {}
	target_pos_list[1] = user_party.Leader.Position - diff
	target_pos_list[2] = user_party.Leader.Position + diff
	target_pos_list[3] = user_party.Leader.Position + vector(-diff.z, 0, diff.x)
	target_pos_list[4] = user_party.Leader.Position - vector(-diff.z, 0, diff.x)
	target_pos_list[5] = (target_pos_list[2] + target_pos_list[4]) / 2
	target_pos_list[5] = user_party.Leader.Position + vector_util.normalized(user_party.Leader.Position - target_pos_list[5])
	target_pos_list[6] = (target_pos_list[3] + target_pos_list[1]) / 2
	target_pos_list[6] = user_party.Leader.Position + vector_util.normalized(user_party.Leader.Position - target_pos_list[6])
	target_pos_list[7] = (target_pos_list[2] + target_pos_list[3]) / 2
	target_pos_list[7] = user_party.Leader.Position + vector_util.normalized(user_party.Leader.Position - target_pos_list[7])
	target_pos_list[8] = (target_pos_list[4] + target_pos_list[1]) / 2
	target_pos_list[8] = user_party.Leader.Position + vector_util.normalized(user_party.Leader.Position - target_pos_list[8])

	-- 너굴걸 무기 장착
	character_util.spine_set_attachment(raccoon, '[base]weapon1', 'survival_chair')

	-- 다구리 위치로 달려옴
	self.move_end_count = 0
	for i, revenger in ipairs(revenger_list) do
		character_util.set_emotion(revenger, {name = 'attack'})
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_to_ready_pos, self, revenger, target_pos_list[i]))
	end

	-- 모두 모일 때까지 대기
	local time_delay = 0
	local move_end_count_max = #revenger_list
	self:face_to(monster, user_party.Leader.Position)
	while self.move_end_count < move_end_count_max do
		wait_for_sec(0.1)
		time_delay = time_delay + 0.1

		if time_delay >= 3 then	-- 최대 3초까지 기다리고 못 모이는 경우 다구리 시작
			break
		end
	end
	coroutine.yield()

	-- 플레이어 줌인
	local zoom_in_duration = 1
	camera_util.resize_to(3, zoom_in_duration)
	wait_for_sec(zoom_in_duration)

	-- 춤추는 애들 화면 밖에 들어옴
	self.dancing_end = false
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dancing, self, dancer1, dancer2))

	-- 때리기
	local revenger_count = #revenger_list
	local hit_count = 0
	local hit_count_max = 16
	local hit_delay = 0.2
	local prev_num = -1
	while hit_count < hit_count_max do
		local num_list
		while true do
			num_list = self:generate_random_num_list(revenger_count)
			if num_list[1] ~= prev_num then
				break
			end
		end

		for i = 1, revenger_count do
			self:attack_to_leader(revenger_list[i], 0.1)
			prev_num = i
			wait_for_sec(hit_delay)
			hit_delay = math.max(hit_delay - 0.025, 0.1)
			hit_count = hit_count + 1
			if hit_count >= hit_count_max then
				break
			end
		end
	end

	-- 가속 때리기
	while self.dancing_end == false do
		local num_list
		while true do
			num_list = self:generate_random_num_list(revenger_count)
			if num_list[1] ~= prev_num then
				break
			end
		end

		for i = 1, revenger_count do
			self:attack_to_leader(revenger_list[i], 0.05)
			prev_num = i
			wait_for_sec(hit_delay)
		end
	end

	-- 기절
	character_util.set_direction(user_party.Leader, 'right')
	character_util.set_anim(user_party.Leader, { name = 'dead', loop = false })
	wait_for_sec(1)
	music_player_util.play_sfx_one_shot('01_trip_01')
	wait_for_sec(2)

	-- 페이드 아웃 후 농장 입구로 이동
	screen_util.fade_out_circular_async(0.6, 'linear')
	local default_start_pos = field:GetMarker(self.default_marker_name).position
	user_party.Leader.Position = default_start_pos

	-- 뒷 정리
	raccoon.SpineController:SetAttachment('[base]weapon1', 'empty')
	raccoon.Position = raccoon_init_pos
	dancer1.Position = dancer1_init_pos
	dancer2.Position = dancer2_init_pos
	character_util.set_direction(raccoon, 'down')
	for _, revenger in ipairs(revenger_list) do
		character_util.remove_anim_and_emotion(revenger)
	end
	character_util.remove_anim_and_emotion(dancer1)
	character_util.remove_anim_and_emotion(dancer2)
	camera_util.resize_to_default(0)

	-- 페이드 인
	coroutine.yield()
	music_player_util.play_sfx_one_shot('01_drown_01')
	chaseSfx:FadeOut()
	screen_util.fade_in_circular_async(0.6, 'linear')

	-- 다시 일어남
	scene_util.shake_and_wakeup(user_party.Leader, 'right', 2, nil, true)
	character_util.hide_weapon(user_party.Leader, false)
	message_system:Publish(CS.Oak.CustomStageEvent.Create(monster, CS.Oak.PastureMonsterManager.MonsterRevengeEndParam))

	--복수 종료
	self.monsters_revenge_started = false
end

-- 건초를 부수거나 부술수 없으면 뛰어 넘으며 도망
function local_class:chase(npc_data, next_pos, dt)
	local npc = npc_data.fo
	local speed = npc_data.speed

	-- 목적지 바라봄
	local moveDirection = next_pos - npc.Position
	self:face_to(npc, next_pos)

	-- 목적지로 이동
	local prev_pos = npc.Position
	self:move_by_one_frame(npc, next_pos, speed, dt)
	if prev_pos == npc.Position then
		npc_data.delay = npc_data.delay + dt
	else
		npc_data.delay = 0
	end

	-- 막혔을 때 처리
	if npc_data.delay > 0.05 then
		local destroy = false
		local objects = field:GetFieldObjectsInRadius(npc.Position, 0.5)
		if objects.Count > 1 then
			for _, fo in pairs(objects) do
				if fo == npc then
					break
				end

				-- 건초면 파괴
				if fo.Holdable.IsHoldable == true then
					music_player_util.play_sfx_one_shot('01_destroy_tree_01', 0.8)
					self.fx_dead:Instantiate(fo.Position)
					fo.Position = vector(999, 0, 999)
					destroy = true
					break
				end
			end
		end

		-- 파괴 불가 오브젝트면 점프
		if destroy == false then
			npc_data.jumping = true
			music_player_util.play_sfx_one_shot('01_jump_01')
			if vector_util.distance(npc.Position, next_pos) <= 1 then
				character_util.jump_move(npc, next_pos, speed, 2, true)
			else
				character_util.jump_move(npc, npc.Position + moveDirection.normalized, speed, 2, true)
			end
			npc_data.jumping = false
		end
		npc_data.delay = 0
	end
end

-- 플레이어 도망
function local_class:run_away(npc, monster)
	local next_pos = self:find_next_run_pos(npc, monster)
	character_util.set_direction(npc, 'down')
	character_util.set_anim_and_emotion(npc, { name = 'embarrassed' }, { name = 'surprise' })
	local npc_data = {
		fo = npc,
		speed = 8,
		delay = 0,
		jumping = false,
	}

	while self.run_away_started == true do
		local dt = unity_class.time.deltaTime

		-- 목적지로 이동
		local prev_pos = npc.Position
		self:chase(npc_data, next_pos, dt)

		-- 목적지 근처면 다음 목적지 찾기
		if npc_data.jumping == false and self:is_arrive_pos(npc, prev_pos, next_pos) then
			next_pos = self:find_next_run_pos(npc, monster)
		end

		coroutine.yield(nil)
	end

	if next_pos.x > npc.Position.x then
		character_util.set_direction(npc, 'right')
	else
		character_util.set_direction(npc, 'left')
	end
	character_util.set_anim_and_emotion(npc, {name = 'prostrate', loop = false}, { name = 'damaged' })
	self.run_away_coroutine = nil
end

-- 다음 도망 지점 찾기
function local_class:find_next_run_pos(npc, monster)
	-- 복수존 위일 때는 복수존으로 도망감
	if npc.Position.z > self.revenge_zone_bounds.max.z then
		return vector(npc.Position.x, 0, self.revenge_zone_bounds.max.z - 1)
	end

	-- 농장 중심으로 도망감
	local next_pos_list
	local distance = 3
	next_pos_list = {}
	if npc.Position.x < self.pasture_center_pos.x then
		table.insert(next_pos_list, vector(npc.Position.x + distance, 0, npc.Position.z))
	else
		table.insert(next_pos_list, vector(npc.Position.x - distance, 0, npc.Position.z))
	end

	if npc.Position.z < self.pasture_center_pos.z then
		table.insert(next_pos_list, vector(npc.Position.x, 0, npc.Position.z + distance))
	else
		table.insert(next_pos_list, vector(npc.Position.x, 0, npc.Position.z - distance))
	end

	-- 도망 영역 안이 아니면 우선 도망영역 안인 곳으로 도망
	local is_in_area1 = CS.BoundsExtensions.ContainsXZ(self.run_zone_bounds, next_pos_list[1])
	local is_in_area2 = CS.BoundsExtensions.ContainsXZ(self.run_zone_bounds, next_pos_list[2])
	if is_in_area1 == true and is_in_area2 == false then
		return next_pos_list[1]
	elseif is_in_area1 == false and is_in_area2 == true then
		return next_pos_list[2]
	end

	-- 두 후보 지점 중 몬스터랑 먼 곳으로 도망
	local diff1 = vector_util.distance(next_pos_list[1], monster.Position)
	local diff2 = vector_util.distance(next_pos_list[2], monster.Position)

	if diff1 > diff2 then
		return next_pos_list[1]
	end

	return next_pos_list[2]
end

-- 좌표에 접근
function local_class:near_to_pos(npc, pos, distance)
	character_util.set_anim(npc, { name = 'run'} )
	local npc_data = {
		fo = npc,
		speed = 7,
		delay = 0
	}

	while vector_util.distance(npc.Position, pos) >= distance do
		local dt = unity_class.time.deltaTime
		self:chase(npc_data, pos, dt)
		coroutine.yield(nil)
	end

	character_util.set_anim(npc, { name = 'idle'})
end

-- 준비 위치로 이동
function local_class:move_to_ready_pos(npc, pos)
	character_util.set_anim(npc, { name = 'run'} )
	local npc_data = {
		fo = npc,
		speed = 7,
		delay = 0,
		jumping = false,
	}

	while true do
		local dt = unity_class.time.deltaTime
		local prev_pos = npc.Position
		self:chase(npc_data, pos, dt)

		-- 목적지 도착 확인
		if npc_data.jumping == false and self:is_arrive_pos(npc, prev_pos, pos) then
			break
		end

		coroutine.yield(nil)
	end

	character_util.set_anim(npc, { name = 'idle'})
	self:face_to(npc, user_party.Leader.Position)

	self.move_end_count = self.move_end_count + 1
end

-- 프레임당 움직임
function local_class:move_by_one_frame(fo, pos_to, speed, dt)
	local dir = (pos_to - fo.Position).normalized
	if dir == unity_class.vector3.zero then
		return
	end

	CS.Oak.MoveOneFrameStageLogic.ExecuteMove(
			fo,
			dir,
			speed * dt)
end

-- 선과 원의 겹칩 체크
function local_class:dist(x1, y1, x2, y2)
	return ((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1))
end

function local_class:is_inside_circle(circle_x, circle_y, r, x, y)
	return self:dist(circle_x, circle_y, x, y) <= r * r
end

function local_class:check_intersection(circle_x, circle_y, circle_radius, line_x1, line_y1, line_x2, line_y2)
	local dx, dy = line_x2 - line_x1, line_y2 - line_y1
	local t = (((circle_x - line_x1) * dx) + ((circle_y - line_y1) * dy)) / ((dx * dx) + (dy * dy))

	if t < 0 then
		t = 0
	elseif t > 1 then
		t = 1
	end

	local closest_x, closest_y = line_x1 + t * dx, line_y1 + t * dy

	return self:is_inside_circle(circle_x, circle_y, circle_radius, closest_x, closest_y)
end

-- 목적지 도착 확인
function local_class:is_arrive_pos(npc, prev_pos, pos)
	if prev_pos == pos then
		return true
	end

	if vector_util.distance(npc.Position, pos) <= 1 then
		local result = self:check_intersection(pos.x, pos.z, 0.01, prev_pos.x, prev_pos.z, npc.Position.x, npc.Position.z)
		if result == true then
			npc.Position = pos
			return true
		end
	end

	return false
end

-- 플레이어 추적
function local_class:move_to_leader(npc)
	character_util.set_anim(npc, { name = 'run'} )
	local npc_data = {
		fo = npc,
		speed = 7,
		delay = 0
	}

	while self.run_away_started == true do
		local dt = unity_class.time.deltaTime
		self:chase(npc_data, user_party.Leader.Position, dt)
		coroutine.yield(nil)
	end

	character_util.set_anim(npc, { name = 'idle'})
	self.move_to_leader_coroutine = nil
end

-- 특정 위치를 바라봄
function local_class:face_to(fo, target_pos)
	local dir = vector_util.to_direction(target_pos - fo.Position)
	if dir ~= CS.Oak.Direction.None then
		fo.Direction = dir
	end
end

-- 배열을 랜덤하게 섞음
function local_class:random_shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

-- 랜덤 숫자 배열 생성
function local_class:generate_random_num_list(size)
	local num_list = {}
	for i = 1, size do
		table.insert(num_list, i)
	end

	self:random_shuffle(num_list)

	return num_list
end

-- 플레이어를 공격
function local_class:attack_to_leader(npc, delay)
	local init_pos = npc.Position

	-- 공격
	local anim_scale = (4 * 0.05) / delay
	character_util.set_animation_n_times(npc, { name = 'attack', count = 1, scale = anim_scale })
	character_util.move_to_async(npc, user_party.Leader.Position, delay, nil, false)

	-- 대미지 입은 플레이어
	self:face_to(user_party.Leader, init_pos)
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'damaged' }, { name = 'damaged' })
	character_util.spine_damage_squish_default(user_party.Leader)
	character_util.spine_damage_red_pulse(user_party.Leader)
	music_player_util.play_sfx_one_shot('02_hit_big_01')

	-- 다시 원위치
	character_util.move_to_async(npc, init_pos, delay, nil, false)
end

-- 두 마리는 춤춘다
function local_class:dancing(dancer1, dancer2)
	-- 화면 밖에서 등장
	local dancer1_pos = user_party.Leader.Position + vector(-1, 0, -2)
	local dancer2_pos = user_party.Leader.Position + vector(1, 0, -2)
	dancer1.Position = user_party.Leader.Position + vector(-11, 0, -2)
	dancer2.Position = user_party.Leader.Position + vector(11, 0, -2)
	dancer1.ActiveState = active_state('enabled')
	dancer2.ActiveState = active_state('enabled')
	character_util.set_anim(dancer1, { name = 'run'} )
	character_util.set_anim(dancer2, { name = 'run'} )
	character_util.jump_move(dancer1, dancer1_pos, 8, 4, false, 'right')
	character_util.jump_move(dancer2, dancer2_pos, 8, 4, true, 'left')

	-- 1페이즈
	character_util.set_anim_and_emotion(dancer1, { name = 'embarrassed' }, { name = 'smile' })
	character_util.set_anim_and_emotion(dancer2, { name = 'embarrassed' }, { name = 'smile' })
	wait_for_sec(1)

	-- 2페이즈
	character_util.set_direction(dancer1, 'left')
	character_util.set_direction(dancer2, 'right')
	character_util.set_anim_and_emotion(dancer1, { name = 'victory' }, { name = 'smile' })
	character_util.set_anim_and_emotion(dancer2, { name = 'victory' }, { name = 'smile' })
	music_player_util.play_sfx_one_shot('01_bad_fairy_01')
	character_util.show_emoticon(dancer1, nil, 'heart')
	character_util.show_emoticon_async(dancer2, nil, 'heart')

	-- 3페이즈
	character_util.set_direction(dancer1, 'right')
	character_util.set_direction(dancer2, 'left')
	character_util.set_anim_and_emotion(dancer1, { name = 'happy' }, { name = 'smile' })
	character_util.set_anim_and_emotion(dancer2, { name = 'happy' }, { name = 'smile' })
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.show_emoticon(dancer1, nil, 'happy')
	character_util.show_emoticon_async(dancer2, nil, 'happy')

	-- 마무리
	character_util.set_direction(dancer1, 'down')
	character_util.set_direction(dancer2, 'down')
	character_util.set_anim_and_emotion(dancer1, { name = 'embarrassed' }, { name = 'smile' })
	character_util.set_anim_and_emotion(dancer2, { name = 'embarrassed' }, { name = 'smile' })
	wait_for_sec(1)

	self.dancing_end = true
end

-- 와이번과 인터렉션시 반겨줌
function local_class:guard_greeting(npc, id)
	if self.guard_greeting_state[id] == true then
		return
	end

	music_player_util.play_sfx_one_shot('01_pet_ordinary_01')

	self.guard_greeting_state[id] = true
	self:face_to(npc, user_party.Leader.Position)
	character_util.set_anim_and_emotion(npc, { name = 'happy' }, { name = 'smile' })
	wait_for_sec(1)
	character_util.remove_anim_and_emotion(npc)
	character_util.set_direction(npc, 'down')
	self.guard_greeting_state[id] = false
end

-- endregion

-----------------------------------------------------------------------------------------------------------------

--region Event

function local_class:on_custom_stage_event(e)
	-- 몬스터 복수 연출
	if e:GetParamAt(0) == 'monsters_revenge' and self.monsters_revenge_started == false then
		self.monsters_revenge_started = true
		sp_util.play_normal_screenplay(self.monsters_revenge, self, e.Sender)
	end

	return false
end

function local_class:on_interact_event(e)
	local npc = e.Target
	local target_name = e.Target.Name

	-- 경비견
	if target_name == self.guard_handle_name .. '1' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.guard_greeting, self, npc, 1))
		return true
	elseif target_name == self.guard_handle_name .. '2' then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.guard_greeting, self, npc, 2))
		return true
	end

	return false
end

--endregion

return {
	create = function(data_path, data_key, cs_behaviour)
		return local_class(data_path, data_key, cs_behaviour)
	end
}
