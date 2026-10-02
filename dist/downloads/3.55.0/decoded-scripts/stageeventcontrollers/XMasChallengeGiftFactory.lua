local local_class = newclass('XMasChallengeGiftFactory')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- npc
	self.get_center_elf = function() return get_character('center_elf') end
	self.get_elf = function(spawn_index, index) return get_character('elf_' .. spawn_index .. '_' .. index) end

	-- 기믹
	self.get_gift = function(index) return get_field_object('gift_' .. index) end
	self.get_clear_door = function() return get_field_object('clear_door') end
	self.get_belt = function(spawn_index, index) return get_field_object('belt_' .. spawn_index .. '_' .. index) end

	-- 마커
	self.get_camera_pos = function() return field:GetMarker('camera_pos').position end
	self.get_spawn_pos = function(index) return field:GetMarker('spawn_pos_' .. index).position end
	self.get_spawn_dir = function(index) return field:GetMarker('spawn_pos_' .. index).direction end
	self.get_waypoint_final = function(index) return field:GetMarker('waypoint_final_' .. index).position end
	self.get_waypoint_pos = function(spawn_index, waypoint_index)
		return field:GetMarker('waypoint_' .. spawn_index .. '_' .. waypoint_index).position
	end

	-- 이벤트 존
	self.battle_zone = 'BATTLE_1'

	-- 이팩트
	self.get_fx_dead = function() return unity_object_pool.GetOrCreate('FX_dead') end
	self.get_fx_spawn = function() return unity_object_pool.GetOrCreate('FX_reset_object') end

	self.progress_enum = {
		none = 1,
		start_wave = 2,
		clear_or_fail = 3
	}

	self.current_progress = self.progress_enum.none

	self.target_object =
	{
		function() return self:get_object('gift') end,
		function() return self:get_object('small_life_monster') end,
		function() return self:get_object('medium_life_monster') end,
		function() return self:get_object('large_life_monster') end
	}

	-- 웨이브 스폰 데이터
	-- spawn_index: 스폰 루트
	-- spawn_object: 1-gift, 2-small_life_monster, 3-medium_life_monster, 4-large_life_monster
	-- spawn_time: 스폰 주기
	self.spawn_data = {
		-- 1웨이브
		{
			spawn_index = {
				1, 1, 1, 2, 2
			},
			spawn_object = {
				2, 1, 3, 3, 2
			},
			spawn_time = {
				2, 2, 2, 2, 0
			}
		},
		-- 2웨이브
		{
			spawn_index = {
				1, 1, 1, 1, 2,
				2, 2
			},
			spawn_object = {
				1, 2, 3, 4, 2,
				3, 2
			},
			spawn_time = {
				1, 1, 1, 0, 1,
				1, 0
			}
		},
		-- 3웨이브
		{
			spawn_index = {
				1, 1, 1, 1, 2,
				2, 2, 1, 2
			},
			spawn_object = {
				3, 2, 4, 2, 3,
				2, 1, 3, 4
			},
			spawn_time = {
				1, 1, 1, 0, 1,
				1, 1, 0, 1
			}
		},
		-- 4웨이브
		{
			spawn_index = {
				2, 1, 2, 1, 2,
				1, 2, 1, 2, 1,
				1, 1, 2, 2, 2
			},
			spawn_object = {
				3, 2, 1, 4, 2,
				1, 2, 3, 2, 3,
				2, 3, 4, 3, 2
			},
			spawn_time = {
				0, 1, 0, 1, 0,
				1, 0, 1, 0, 1,
				1, 0, 1, 1, 0
			}
		},
		-- 5웨이브
		{
			spawn_index = {
				1, 1, 1, 1, 2,
				1, 2, 1, 2, 1,
				2, 1, 2, 1, 2
			},
			spawn_object = {
				1, 4, 2, 2, 2,
				2, 1, 3, 4, 3,
				3, 2, 1, 3, 2
			},
			spawn_time = {
				0.5, 0.5, 0.5, 0, 0.5,
				0, 0.5, 0, 0.5, 1.5,
				0, 0.5, 0, 0.5, 0,
				0.5, 0, 0.5, 0, 0.5
			}
		},
		-- 6웨이브 (게임 오버 될 때까지 무한 반복. 단, 6웨이브 돌입 시 이동 속도는 상승하지 않는다.)
		{
			spawn_index = {
				1, 2, 1, 2, 1,
				2, 1, 2, 1, 2,
				1, 2, 1, 2, 1,
				2, 1, 2, 1, 2
			},
			spawn_object = {
				3, 2, 1, 3, 2,
				3, 2, 1, 3, 4,
				3, 2, 1, 3, 2,
				3, 2, 1, 3, 4
			},
			spawn_time = {
				0.5, 0, 0.5, 0, 0.5,
				0, 0.5, 0, 0.5, 1,
				0.5, 0, 0.5, 0, 0.5,
				0, 0.5, 0, 0.5, 0
			}
		}
	}

	-- 가져올 몬스터 현재 번호
	self.object_index = {
		small = 1,
		medium = 1,
		large = 1
	}

	-- 오브젝트 생존 여부
	self.object_alive = {}

	-- 가져올 선물 오브젝트 현재 번호
	self.gift_index = 1

	-- 현재 웨이브
	self.current_wave = 1

	-- 웨이브 교체 중인지
	self.change_wave = false

	-- 성공 선물 개수
	self.success_gift_count = 5
	self.current_gift_count = 0

	-- 제한 시간
	self.time_limit = 90

	-- 맨앞의 선물 운반자
	self.front_elf_index = { 1, 1 }

	-- 레일 스피드(몬스터 이동 스피드)
	self.rail_speed = 1
	-- 벨트 기믹 스피드
	self.belt_speed = 1

	-- 이번 웨이브 몬스터들
	self.current_wave_monster = {}
	-- 이번 웨이브 오브젝트들
	self.current_wave_object = {}

	-- 벨트 애니메이터
	self.belt_animators = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	character_util.add_listener(self.get_center_elf(), self.cs_controller)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	CS.Oak.CommonScreenplay.PreloadActivityClear()

	quest_util.load_pool_resource(
		'FX_dead',
		'FX_reset_object',
		'FieldUIDuelBuffState'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))

	character_util.remove_relate_event(self.get_center_elf(), self.cs_controller)

	self:detach_count_ui()

	self.current_wave_monster = nil
	self.current_wave_object = nil

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(e)
	local center_elf = self.get_center_elf()
	if type_util.is_interacted_target(e, center_elf)then
		if self.current_progress == self.progress_enum.none then
			music_player:PlaySfxOneShot('03_runaway_01')
			-- 이러다 배달 펑크나면 전원 감봉인데...
			speech_bubble_util.show_speech_bubble(center_elf, { key = 'substage_xm_1_online_1' })
		elseif self.current_progress == self.progress_enum.clear_or_fail then
			music_player:PlaySfxOneShot('03_dialogue_positive_01')
			-- 기사님 덕분에 특근 보너스까지 탔어요!
			speech_bubble_util.show_speech_bubble(center_elf, { key = 'substage_xm_1_online_2' })
		end
		return true
	end

	return false
end

--- StageLoadedEvent
function local_class:on_stage_loaded_event(_)
	-- 퀘스트 마커
	ui_quest_marker:AddQuestMarkerToIFO('game_start', -1, false, get_field_object('jump_1'))

	-- 오브젝트들 세팅
	local object_setting = function(object_name)
		local object_index = 1

		while true do
			local object

			if object_name == 'gift' then
				object = self.get_gift(object_index)
			else
				object = get_character(object_name .. '_' .. object_index)
			end

			if not object then
				return
			end

			if object_name == 'gift' then
				object.EntityGroup = CS.Oak.EntityGroups.Enemy
				local object_spec = CS.Oak.FieldObjectSpec()
				local calc_spec = CS.Oak.LuaScriptQuestUtil.SetFieldObjectSpecHpBase(object_spec, 10)
				object.FieldObjectStatsBehaviour.FieldObjectSpec = calc_spec
				field_ui_manager:SetUI(object, CS.Oak.FieldUiType.CharacterStats)
			else
				object.FieldObjectController.DontFight = true
			end

			object.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
			object.Hitbox = CS.Oak.Hitbox(vector(0.5, 1, 0.5), vector(1.3, 1, 1.3))
			object_index = object_index + 1
		end
	end

	object_setting('gift')
	object_setting('small_life_monster')
	object_setting('medium_life_monster')
	object_setting('large_life_monster')

	for spawn_index = 1, 2 do
		for i = 1, 24 do
			local belt = self.get_belt(spawn_index, i)
			local belt_animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
			table.insert(self.belt_animators, belt_animator)
		end
	end

	return true
end

--- StageStartEvent
function local_class:on_stage_start_event(_)
	sp_util.play_normal_screenplay(function()
		field_ui_util.show_narration_async(
			{ key = game_string:Format('substage_xm_1_narration', self.success_gift_count), mintotalduration = 1 })
	end)
	return true
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)

	if type_util.is_zone_full_enter(e, user_party.Leader, self.battle_zone) then
		if self.current_progress == self.progress_enum.none then
			self.current_progress = self.current_progress + 1

			-- 퀘스트 마커 제거
			ui_quest_marker:RemoveQuestMarker('game_start')

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_game, self))
			return true
		end
	end

	return false
end

--- FieldObjectDestroyedEvent
function local_class:on_fo_destroyed_event(e)
	local object = e.FieldObject
	if string.find(object.Transform.name, 'monster') then

		self.object_alive[object] = false

		for _, v in pairs(self.current_wave_monster) do
			if not v.FieldObjectStatsBehaviour.IsDead then
				return true
			end
		end

		-- 현재 wave 몬스터가 전부 죽었다면 다음 웨이브
		if not self.change_wave then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ready_next_wave, self))
		end

	return true
end

	return false
end

--- DamageEvent
function local_class:on_damage_event(e)
	local object = e.Info.target
	if string.find(object.Transform.name, 'gift') and object.FieldObjectStatsBehaviour.HP < 1 then
		self.get_fx_dead():Instantiate(object.Position)
		self.object_alive[object] = false
		object.ActiveState = active_state('disabled')
	end

	return false
end

--- GlobalTimerAlarmEvent
function local_class:on_global_timer_alarm_event(e)

	if e.IsComplete and self.current_progress == self.progress_enum.start_wave then
		self.current_progress = self.current_progress + 1

		for _, v in pairs(self.current_wave_object) do
			self.object_alive[v] = false
		end

		-- 벨트 기믹 애니메이션 멈춤
		for _, v in pairs(self.belt_animators) do
			v:Play('empty')
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.time_over, self))

		return true
	end

	return true
end

--- 게임 시작
function local_class:start_game()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local leader = user_party.Leader

	-- 캐릭터가 점프대로 날아오는 중이면 대기
	while lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) do
		coroutine.yield(nil)
	end

	camera_util.resize_to(8, 1)
	camera_util.move_async(self.get_camera_pos(), 1)

	character_util.move_waypoint_async(leader, vector(1, 0, 26), 5, true)
	message_system:Publish(CS.Oak.DoorCloseEvent.Create('event_door'))

	-- bgm_transition: Combat(bgm_battle_normal) -> Combat(ondemand/xmas/audio:bgm_xmas_factory)
	music_player_util.play_stage_music({ name = 'ondemand/xmas/audio:bgm_xmas_factory', state = 'combat' })

	command_util.execute_monster_notice(get_character('small_life_monster_1'), leader, 'battle')

	character_util.set_direction(leader, 'left')
	character_util.set_animation_n_times_async(leader, { name = 'victory_get', sfx = '01_stage_intro_jump_01' })

	field_ui_manager:Show()
	party_util.reset_controllers()

	self:attach_count_ui(leader, self.current_gift_count)

	self:start_timer()

	for _, v in pairs(self.belt_animators) do
		v.speed = self.belt_speed
		v:Play('xmas_belt_rolling')
	end

	self:start_wave()
end

-- 웨이브 시작
function local_class:start_wave()
	if self.current_progress ~= self.progress_enum.start_wave or self.current_wave > #self.spawn_data then
		return
	end

	-- 이번 웨이브 오브젝트 세팅
	for i = 1, #self.spawn_data[self.current_wave].spawn_index do
		local target = self.target_object[self.spawn_data[self.current_wave].spawn_object[i]]()
		table.insert(self.current_wave_object, target)
		self.object_alive[target] = true

		-- 선물이 아니라면 몬스터
		if self.spawn_data[self.current_wave].spawn_object[i] ~= 1 then
			table.insert(self.current_wave_monster, target)
		end
	end

	-- 이번 웨이브 몬스터 소환
	for k, v in pairs(self.current_wave_object) do
		if self.current_progress ~= self.progress_enum.start_wave then
			return
		end

		coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.spawn_object, self, self.spawn_data[self.current_wave].spawn_index[k], v))

		wait_for_sec(self.spawn_data[self.current_wave].spawn_time[k])
	end
end

-- 웨이브 끝나고 다음 웨이브 세팅
function local_class:ready_next_wave()
	self.change_wave = true
	wait_for_sec(2)

	for _, v in pairs(self.current_wave_monster) do
		v.Position = vector(99, 0 ,99)

		-- 오브젝트 재생
		if v.FieldObjectStatsBehaviour.HP ~= v.FieldObjectStatsBehaviour.MaxHP then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = v
			heal_info.target = v
			heal_info.isRevive = true
			heal_info.heal = v.FieldObjectStatsBehaviour.MaxHP
			command_util.execute_heal(heal_info)
		end
	end

	for k, _ in pairs(self.object_index) do
		self.object_index[k] = 1
	end

	self.current_wave_monster = {}
	self.current_wave_object = {}

	-- 최종 웨이브가 아닐 때만 다음 웨이브 난이도 증가
	if self.current_wave < #self.spawn_data then
		self.current_wave = self.current_wave + 1
		-- 몬스터 이동 스피드 증가
		self.rail_speed = self.rail_speed + 0.3

		-- 벨트 기믹 애니메이션 스피드 증가
		self.belt_speed = self.belt_speed + 0.3
		for _, v in pairs(self.belt_animators) do
			v.speed = self.belt_speed
		end
	end

	wait_for_sec(1)

	self.change_wave = false

	self:start_wave()
end

--- 오브젝트 소환 및 이동
function local_class:spawn_object(spawn_index, target)
	local spawn_pos = self.get_spawn_pos(spawn_index)

	local is_gift = string.find(target.Transform.name, 'gift') and true or false

	if not is_gift then
		character_util.remove_anim(target)
		character_util.set_direction(target, self.get_spawn_dir(spawn_index))
	end
	target.Position = spawn_pos + 4 * unity_class.vector3.up

	-- 오브젝트 낙하 연출
	self.get_fx_spawn():Instantiate(target.Position)
	if is_gift then
		music_player:PlaySfxOneShot('01_guild_warp_01')
	else
		music_player:PlaySfxOneShot('02_goblin_appear_01')
	end

	local gravity = 9.8
	local start_y = target.Position.y
	local bounce = 0
	local free_fall = CS.CalculatorFreeFall(0, gravity, start_y, bounce)
	local fall_duration = CS.CalculatorFreeFall.CalculateDurationIncludingBounces(0, gravity, start_y + spawn_pos.y, bounce, 0.5)

	local time_passed = 0
	while time_passed < fall_duration do
		time_passed = time_passed + unity_class.time.deltaTime

		free_fall:Proceed(unity_class.time.deltaTime, spawn_pos.y)

		local get_dist = unity_class.mathf.Max(free_fall:GetDistance(), spawn_pos.y)
		target.Position = vector_util.get_x0z(target.Position, get_dist)

		coroutine.yield(nil)
	end

	-- 낙하가 끝난 후 피격되도록 설정
	if not is_gift then
		target.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()
	else
		target.DamagedBehaviour = CS.Oak.BarrelDamagedBehaviour.Instance
	end

	-- 오브젝트 이동 연출
	local waypoint_count = 2
	local waypoint = {}

	for i = 1, waypoint_count do
		table.insert(waypoint, self.get_waypoint_pos(spawn_index, i))
	end

	self:move_waypoint_fo(target, waypoint, self.rail_speed, false, spawn_index)

	if not self.object_alive[target] then
		return
	end

	self:move_waypoint_fo(target, {self.get_waypoint_final(spawn_index)}, self.rail_speed, true, spawn_index)
end

--- 오브젝트 가져오기
function local_class:get_object(object_name)
	local object
	if object_name == 'gift' then
		object = self.get_gift(self.gift_index)
		self.gift_index = self.gift_index + 1

		if self.gift_index > 10 then
			self.gift_index = 1
		end

		local next_gift = self.get_gift(self.gift_index)
		next_gift.Position = vector(99, 0, 99)
		-- 오브젝트 재생
		if next_gift.FieldObjectStatsBehaviour.HP ~= next_gift.FieldObjectStatsBehaviour.MaxHP then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = next_gift
			heal_info.target = next_gift
			heal_info.isRevive = true
			heal_info.heal = next_gift.FieldObjectStatsBehaviour.MaxHP
			command_util.execute_heal(heal_info)
		end

	elseif object_name == 'small_life_monster' then
		object = get_character(object_name .. '_'.. self.object_index.small)
		self.object_index.small = self.object_index.small + 1
	elseif object_name == 'medium_life_monster' then
		object = get_character(object_name .. '_'.. self.object_index.medium)
		self.object_index.medium = self.object_index.medium + 1
	elseif object_name == 'large_life_monster' then
		object = get_character(object_name .. '_'.. self.object_index.large)
		self.object_index.large = self.object_index.large + 1
	end

	object.ActiveState = active_state('enabled')

	return object
end

--- 오브젝트 이동 루틴
function local_class:move_waypoint_fo(fo, waypoint, speed, final, spawn_index)
	local is_gift = string.find(fo.Transform.name, 'gift') and true or false

	-- 이동 도중 스피드가 바뀌면 업데이트
	local new_waypoint = {}
	local move_update = false

	for _, v in pairs(waypoint) do
		local start_pos = fo.Position
		local end_pos = v

		if not move_update then
			if not is_gift then
				local look_dir = vector_util.to_direction(end_pos - start_pos)
				character_util.set_direction(fo, look_dir)
			end

			local move_duration = (fo.Position - v).magnitude / speed
			local time_passed = 0

			while time_passed < move_duration do
				time_passed = time_passed + unity_class.time.deltaTime

				fo.Position = unity_class.vector3.Lerp(start_pos, end_pos, time_passed / move_duration)

				if not self.object_alive[fo] then
					return
				end

				-- 다음 웨이브가 넘어가 스피드가 변경됐으면 스피드 변경해서 다시 이동 함수 호출
				if speed ~= self.rail_speed then
					move_update = true
					table.insert(new_waypoint, v)
					break
				end

				-- 다운 상태가 끝났을 때 위아래 방향에 애니메이션이 없으면 해제가 안 되서 애니메이션 해제 후 원하는 방향 지정
				if is_gift then
					coroutine.yield(nil)
				else
					if lua_helper.type_compare(fo.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterDownState) then
						character_util.set_side_direction(fo)
						coroutine.yield(nil)
					else
						coroutine.yield(nil)
						local look_dir = vector_util.to_direction(end_pos - start_pos)
						character_util.set_direction(fo, look_dir)
					end
				end
			end
		else
			table.insert(new_waypoint, v)
		end
	end

	if move_update then
		self:move_waypoint_fo(fo, new_waypoint, self.rail_speed, final, spawn_index)
	end

	if not final or move_update then return end

	if self.current_progress ~= self.progress_enum.start_wave then
		return
	end

	-- 마지막 위치에 몬스터가 도착하면 게임오버
	if not is_gift then
		self.current_progress = self.current_progress + 1

		character_util.set_immortal(fo, true)

		for _, v in pairs(self.current_wave_object) do
			self.object_alive[v] = false
		end

		-- 벨트 기믹 애니메이션 멈춤
		for _, v in pairs(self.belt_animators) do
			v:Play('empty')
		end

		self:mission_fail(fo, spawn_index)

	-- 마지막 위치에 선물이 도착하면 선물 옮기기
	else
		self.current_gift_count = self.current_gift_count + 1
		if self.current_gift_count == self.success_gift_count then
			-- 성공 개수만큼 선물을 지켰으면 클리어
			self.current_progress = self.current_progress + 1
		end

		self:update_count_ui(self.current_gift_count)

		fo.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance

		-- 선물 들기
		music_player:PlaySfxOneShot('01_holdup_01')
		local front_elf = self.get_elf(spawn_index, self.front_elf_index[spawn_index])
		character_util.set_anim(front_elf, { name = 'hold_loop', upper = true })
		character_util.move_to(fo, front_elf.Position + vector(0, 1.2, 0), 0.12)
		wait_for_sec(0.3)

		self.front_elf_index[spawn_index] = self.front_elf_index[spawn_index] + 1

		-- 선물을 들은 엘프가 가지고 나감
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			local dir = spawn_index == 1 and unity_class.vector3.left or unity_class.vector3.right
			character_util.move_to(fo, fo.Position + 14 * dir, nil, 5)
			character_util.move_waypoint_async(front_elf, front_elf.Position + 14 * dir, 5)
		end))

		if self.current_gift_count == self.success_gift_count then
			sp_util.play_normal_screenplay(self.clear_game, self)
		else
			music_player:PlaySfxOneShot('01_quiz_o_02')
			-- 앞으로 한칸씩 이동
			for i = self.front_elf_index[spawn_index], 5 do
				local elf = self.get_elf(spawn_index, i)
				if i == self.front_elf_index[spawn_index] then
					local dir = spawn_index == 1 and 'down' or 'up'
					character_util.move_waypoint(elf, self.get_elf(spawn_index, i - 1).Position, 3,
						false, nil, nil, dir)
				else
					character_util.move_waypoint(elf, self.get_elf(spawn_index, i - 1).Position, 3)
				end
			end
		end
	end
end

--- 게임 클리어 후 연출
function local_class:clear_game()
	self:end_timer()
	self:detach_count_ui()

	stage.BattleManager:ForceEndBattles()

	music_player:PlaySfxOneShot('03_gimmick_jingle_01')
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local crowd_sfx = music_player_util.play_sfx({ sfx_name = '01_crowd_clap_03' })
		wait_for_sec(3)

		crowd_sfx:FadeOut(2)
	end))
	CS.Oak.CommonScreenplay.ShowActivityClear()

	for _, v in pairs(self.current_wave_object) do
		self.object_alive[v] = false
	end

	-- 벨트 기믹 애니메이션 멈춤
	for _, v in pairs(self.belt_animators) do
		v:Play('empty')
	end

	local leader = user_party.Leader
	local center_elf = self.get_center_elf()
	-- 캐릭터가 점프대로 날아오는 중이면 대기
	while lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) do
		coroutine.yield(nil)
	end

	character_util.set_direction(leader, 'down')
	character_util.set_anim(leader, { name = 'success' })
	character_util.set_emotion(leader, { name = 'smile' })

	wait_for_sec(1.5)

	-- 페이드 인아웃 세팅
	music_player:PlaySfxOneShot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(1, 'linear')

	character_util.remove_anim_and_emotion(leader)
	leader.Position = center_elf.Position + vector(1, 0, 0)

	character_util.set_direction(center_elf, 'right')
	character_util.set_anim(center_elf, { name = 'sing' })
	character_util.set_emotion(center_elf, { name = 'smile' })

	character_util.set_direction(leader, 'left')
	camera_util.resize_to_default(0)
	camera_util.return_to_leader(0)
	wait_for_sec(1)

	screen_util.fade_in_circular_async(1, 'linear')

	-- 도어 오픈 연출
	camera_util.move_async(self.get_clear_door().Bounds.center, 1)

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('clear_door', false))
	wait_for_sec(2)

	camera_util.return_to_leader(1)
end

--- 시간이 지나서 게임오버
function local_class:time_over()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	self:end_timer()

	local leader = user_party.Leader

	-- 캐릭터가 점프대로 날아오는 중이면 대기
	while lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('03_runaway_01')
	music_player:PlaySfxOneShot('01_crowd_shout_05')

	for spawn_index = 1, 2 do
		for i = self.front_elf_index[spawn_index], 5 do
			local elf = self.get_elf(spawn_index, i)
			character_util.stop(elf)
			character_util.set_emotion(elf, { name = 'surprise' })
			character_util.set_anim(elf, { name = 'embarrassed' })
		end
	end

	character_util.set_direction(leader, 'down')
	character_util.set_emotion(leader, { name = 'surprise' })
	character_util.set_anim(leader, { name = 'embarrassed' })

	wait_for_sec(1.5)

	self:game_over(true)
end

--- 몬스터가 끝에 도착해서 게임오버
function local_class:mission_fail(monster, spawn_index)
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	music_player:PlaySfxOneShot('02_die_goblin_01')

	self:end_timer()

	local leader = user_party.Leader

	-- 캐릭터가 점프대로 날아오는 중이면 대기
	while lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterJumpState) do
		coroutine.yield(nil)
	end

	local look_dir = spawn_index == 1 and 'up' or 'down'
	character_util.set_direction(monster, look_dir)
	character_util.set_anim(monster, { name = 'attack' })

	music_player:PlaySfxOneShot('03_runaway_01')
	music_player:PlaySfxOneShot('01_crowd_shout_05')

	for i = self.front_elf_index[spawn_index], 5 do
		local elf = self.get_elf(spawn_index, i)
		character_util.stop(elf)
		character_util.set_emotion(elf, { name = 'surprise' })
		character_util.set_anim(elf, { name = 'embarrassed' })
	end

	character_util.set_direction(leader, 'down')
	character_util.set_emotion(leader, { name = 'surprise' })
	character_util.set_anim(leader, { name = 'embarrassed' })

	-- 엘프들 도망
	local elf_dir = spawn_index == 1 and unity_class.vector3.left or unity_class.vector3.right
	local move_end_pos = self.get_elf(spawn_index, self.front_elf_index[spawn_index]).Position + 14 * elf_dir
	for i = self.front_elf_index[spawn_index], 5 do
		local elf = self.get_elf(spawn_index, i)
		character_util.move_to(elf, move_end_pos, nil, 5, true)
	end

	wait_for_sec(1)

	character_util.remove_anim(monster)

	local jump_dir = spawn_index == 1 and unity_class.vector3.forward or unity_class.vector3.back
	character_util.jump(monster, 1, 0.5)
	character_util.move_to_async(monster, vector_util.get_x0z(monster.Position) + jump_dir, 0.5)

	character_util.move_waypoint_async(monster, monster.Position + 14 * elf_dir, 7)

	self:game_over(false)

	wait_for_sec(2)

	for _, v in pairs(self.current_wave_object) do
		self.object_alive[v] = false
	end
end

-- 게임 오버 연출
function local_class:game_over(time_over)
	local leader = user_party.Leader

	-- bgm_transition: Combat(ondemand/xmas/audio:bgm_xmas_factory) -> Muted
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	self:detach_count_ui()

	music_player:PlaySfxOneShot('01_drown_01')
	camera_util.resize_to_default(1)
	camera_util.move_async(leader.Position, 1, { ignorecameragrids = true })

	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, time_over)
	message_system:Publish(CS.Oak.GameOverEvent.Instance)

	character_util.set_direction(leader, direction_util.to_side_dir(leader.Direction))
	character_util.set_emotion(leader, { name = 'damaged' })
	character_util.set_anim(leader, { name = 'frustration', loop = false, scale = 0.4 })
end

--- 플레이어 머리 위 선물상자 개수 UI 생성
function local_class:attach_count_ui(target, count)
	local offset = vector(0, 1, 0.5)
	self.ammo_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset, unity_class.quaternion.identity, user_party.Leader.Transform)

	local tmp = self.ammo_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	local sprite = self.ammo_ui.transform:Find('Offset'):Find('BuffSprite'):GetComponent(typeof(CS.CustomSprite))
	self.origin_sprite_name = sprite.SpriteName
	sprite.SpriteName = 'xm_ic_gift.png'
	sprite:Rebuild()
	tmp.text = count
end

--- 플레이어 머리 위 선물상자 개수 UI 업데이트
function local_class:update_count_ui(value)
	local tmp = self.ammo_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

--- 플레이어 머리 위 선물상자 개수 UI 제거
function local_class:detach_count_ui()
	if self.ammo_ui ~= nil then
		local sprite = self.ammo_ui.transform:Find('Offset'):Find('BuffSprite'):GetComponent(typeof(CS.CustomSprite))
		sprite.SpriteName = self.origin_sprite_name
		sprite:Rebuild()

		self.ammo_ui:Dispose()
		self.ammo_ui = nil
	end
end

-- 타이머 시작
function local_class:start_timer()
	music_player:PlaySfxOneShot('02_gimmick_ticking_01')

	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.EventTimer)

	local game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.time_limit, nil)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, game_timer))
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_global_timer_alarm_event')
	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, true))
end

-- 타이머 종료
function local_class:end_timer()
	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
