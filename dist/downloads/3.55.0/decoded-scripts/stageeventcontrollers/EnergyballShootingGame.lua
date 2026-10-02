local local_class = newclass('EnergyballShootingGame')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.game_progress = {
		none = 1,
		playing = 2,
		fail = 3,
		clear = 4
	}
	self.current_game_progress = self.game_progress.none

	self.touch_state = {
		none = 1,
		hold = 2,
		up = 3
	}
	self.current_touch_state = self.touch_state.none

	self.monster_spawn_type = {
		use_marker = 1,
		random_in_end_line = 2
	}
	self.spawn_type = self.monster_spawn_type.random_in_end_line

	self.active_monsters = {}

	self.available_monsters = {}

	self.spawn_time_passed = 0
	self.spawn_cycle = 2

	self.game_start_area_name = 'start_game'
	self.game_area_name = 'game_area'
	self.player_start_stand_name = 'player_start_stand'
	self.player_end_stand_name = 'player_end_stand'
	self.door_clear_name = 'door_clear'

	-- 각 스테이지별 몬스터들 스폰 사이클
	-- Key: 스테이지명
	-- Value: 몬스터들 스폰 시간 리스트. 아이템들의 총 개수는 몬스터의 총 개수와 동일한 숫자로 이뤄지고 몬스터들의 순서와 똑같이 매핑된다.
	-- 예를 들어, 리스트가 {1,2,3}이라면 1번 몬스터는 1초후에 스폰되고 2번 몬스터는 1번 몬스터가 스폰된 시점으로부터 2초 후 스폰되는 식이다.
	self.spawn_cycle_each_stage = {
		tower_107 = {2.5, 2, 0.5, 1, 2,
					 6, 0.5, 1, 1, 1.5, 2, 1,
					 6, 2, 0.5, 1, 0.5, 2, 1, 1, 1.5}
	}

	-- 웨이브 #1 - Easy (count: 5)
	-- -- soldier 2.5
	-- -- fat 2
	-- -- soldier 0.5
	-- -- assassin 1
	-- -- fat 2

	-- 웨이브 #2 - Normal (count: 7)
	-- -- fat 6
	-- -- assassin 0.5
	-- -- soldier 1
	-- -- fat 1
	-- -- assassin 1.5
	-- -- fat 2
	-- -- soldier 1

	-- 웨이브 #3 - Hard (count: 9)
	-- -- soldier 6
	-- -- soldier 2
	-- -- assassin 0.5
	-- -- fat 1
	-- -- assassin 0.5
	-- -- soldier 2
	-- -- fat 1
	-- -- assassin 1
	-- -- soldier 1.5

	self.gamepad_label = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadConnectedEvent), 'on_gamepad_connected')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent), 'on_gamepad_disconnected')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FX_Chapter6_Sapa_energyball')
	unity_object_pool.GetOrCreate('FX_Chapter6_Sapa_energyball_cast')
	unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj_Explosion')
	unity_object_pool.GetOrCreate('FX_Blockaura_Char_black')
	unity_object_pool.GetOrCreate('FX_reset_object')

	gamepad_util.preload_joypad_label()

	coroutine.yield(unity_object_pool.WaitAll())
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

-- Tower스테이지 컨트롤러의 이벤트를 받아 가이드 연출 실행
function local_class:on_stage_start_event()
	sp_util.play_normal_screenplay(self.display_guide, self)

	return false
end

function local_class:display_guide()
	-- 인베이더를 모두 무찌르세요.
	field_ui_util.show_narration_async({ key = 'tower_puzzle_40_narration'})
end

function local_class:on_zone_enter_event(e)
	if self.current_game_progress ~= self.game_progress.none then return true end

	if type_util.is_zone_full_enter(e, user_party.Leader, self.game_start_area_name) and self.current_game_progress == self.game_progress.none then
		self.current_game_progress = self.game_progress.playing
		sp_util.play_normal_screenplay(self.start_game, self)
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.current_game_progress ~= self.game_progress.playing then return true end

	if e.FullLeave and e.Zone.Name == self.game_area_name and table_util.contain_key(self.active_monsters, e.FieldObject) then
		self.current_game_progress = self.game_progress.fail
	end

	return false
end

function local_class:on_touch_event(e)
	-- 게임 플레이 중이 아니면 터치 관련 처리 하지않음.
	if self.current_game_progress ~= self.game_progress.playing then
		return true
	end

	if self.current_touch_state== self.touch_state.none and e.TouchEventType == CS.Oak.TouchEventType.Action1TouchDown then
		self.current_touch_state = self.touch_state.hold
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.charge_energy_ball, self))
	elseif self.current_touch_state == self.touch_state.hold and e.TouchEventType == CS.Oak.TouchEventType.Action1TouchUp then
		self.current_touch_state = self.touch_state.up
	end

	return false
end

function local_class:on_fo_destroyed_event(e)
	if table_util.contain_key(self.active_monsters, e.FieldObject) then
		self.active_monsters[e.FieldObject] = false
		if self:is_all_monster_dead() then
			self.current_game_progress = self.game_progress.clear
		end
	end
end

function local_class:on_stage_loaded_event(_)
	self:set_spawn_monsters()

	-- 퀘스트 마커 표시
	ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(5.5, 0, -0.5))

	return false
end

function local_class:on_gamepad_connected(_)
	if self.current_game_progress ~= self.game_progress.playing then return true end

	self:show_gamepad_label()

	return false
end

function local_class:on_gamepad_disconnected(_)
	if self.current_game_progress ~= self.game_progress.playing then return true end

	self:hide_gamepad_label()

	return false
end

function local_class:shoot_energy_ball(energy_ball, direction, radius)
	local life_time = 7
	local time_passed = 0
	local speed = 20

	music_player:PlaySfxOneShot('02_dark_magician_shoot_01')
	character_util.set_anim(user_party.Leader, { name = 'shoot', loop = false, next_anim = 'idle' })

	while self.current_game_progress == self.game_progress.playing and time_passed < life_time do
		time_passed = time_passed + unity_class.time.deltaTime

		local hit = false
		local hit_ifos = field:GetFieldObjectsInRadius(energy_ball.transform.position, radius)
		for i = 0, hit_ifos.Count - 1 do
			local target = hit_ifos[i]
			hit = table_util.contain_key(self.active_monsters, target) or
					(not lua_helper.reference_equals(target, user_party.Leader) and not CS.Oak.ICrashBehaviourExtensions.IsEthereal(target.CrashBehaviour))
			if hit then
				break
			end
		end
		hit_ifos:Dispose()

		-- 무언가에 맞았다면 루프 탈출
		if hit then
			break
		end

		energy_ball.transform.position = energy_ball.transform.position + direction * speed * unity_class.time.deltaTime

		coroutine.yield()
	end

	camera_util.shake(0.2, 0.1)
	music_player:PlaySfxOneShot('02_impact_lightning_01')
	local explosion = unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj_Explosion'):Instantiate(energy_ball.transform.position)
	explosion.transform.localScale = unity_class.vector3.one * 1.5

	-- 반경 1의 범위만큼 폭발 데미지를 부여
	local hittable_targets = field:GetFieldObjectsInRadius(energy_ball.transform.position, 1)
	for i = 0, hittable_targets.Count - 1 do
		local target = hittable_targets[i]
		local attackable = self.current_game_progress == self.game_progress.playing and
				table_util.contain_key(self.active_monsters, target) and self.active_monsters[target]
		if attackable then
			-- 패시브 데미지는 주지않기위해 데미지 타입에 패시브를 포함해줌.
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Projectile | CS.Oak.DamageType.Passive
			damage_info.sender = user_party.Leader
			damage_info.target = target
			damage_info.damage = 1
			damage_info.noCritical = true
			command_util.execute_damage(damage_info)
		end
	end
	hittable_targets:Dispose()

	energy_ball:Dispose()
end

function local_class:charging_fail_reaction()
	music_player:PlaySfxOneShot('03_runaway_01')
	user_party.Leader:SetEmotion('surprise', true)
	user_party.Leader:SetAnimation('embarrassed', true)
	wait_for_sec(1)

	user_party.Leader:RemoveEmotion()
	user_party.Leader:RemoveAnimation()
end

function local_class:charge_energy_ball()
	local chargeable_duration = 1.5
	local energy_ball
	local charge_effect
	local black_aura
	local offset = vector(0.5, 0, 0.25)
	local ball_max_scale = 0.2
	local charge_max_scale = 0.3
	local rotate_angle = 60
	local rotate_speed = 2.5
	local shotable_duration = chargeable_duration / 3
	local radius_ratio = 1.6

	user_party.Leader:SetAnimation('boong_attack_ready_loop', true)

	energy_ball = unity_object_pool.GetOrCreate('FX_Chapter6_Sapa_energyball'):Instantiate(user_party.Leader.Position + offset)
	charge_effect = unity_object_pool.GetOrCreate('FX_Chapter6_Sapa_energyball_cast'):Instantiate(user_party.Leader.Position + offset)
	message_system:Publish(CS.Oak.AttackQueueStartEvent.Create(user_party.Leader, shotable_duration))

	local charge_sfx = music_player_util.play_sfx({sfx_name = '02_flower_charge_01', loop = true})

	local start_dir = unity_class.vector3.right
	local current_dir
	local time_passed = 0
	while self.current_game_progress == self.game_progress.playing and self.current_touch_state == self.touch_state.hold do

		time_passed = time_passed + unity_class.time.deltaTime

		-- 공을 쏠수있는 시간이 됐다면 검은색 아우라 이펙트를 붙여줌
		if time_passed >= shotable_duration and black_aura == nil then
			black_aura = unity_object_pool.GetOrCreate('FX_Blockaura_Char_black'):Instantiate(user_party.Leader.Position)
		end

		-- 공이랑 캐스트 이펙트 크기 & 반지름 업데이트
		local progress = unity_class.mathf.Clamp01(time_passed / chargeable_duration)
		energy_ball.transform.localScale = unity_class.vector3.one * unity_class.mathf.Lerp(0.1, ball_max_scale, progress)
		charge_effect.transform.localScale = unity_class.vector3.one * unity_class.mathf.Lerp(0.1, charge_max_scale, progress)

		-- 공이랑 캐스트 이펙트 위치 업데이트
		local sine_val = unity_class.mathf.Sin(time_passed * rotate_speed) * -1
		local current_angle = rotate_angle * sine_val
		current_dir = unity_class.quaternion.AngleAxis(current_angle, unity_class.vector3.up) * start_dir
		local ball_pos = user_party.Leader.Position + current_dir
		energy_ball.transform.position = ball_pos
		charge_effect.transform.position = ball_pos

		coroutine.yield()
	end

	-- 차징 소리 스탑
	charge_sfx:Stop()

	message_system:Publish(CS.Oak.AttackQueueEndEvent.Create(user_party.Leader))

	if charge_effect ~= nil then
		charge_effect:Dispose()
	end

	if black_aura ~= nil then
		black_aura:Dispose()
	end

	-- 게임플레이가 끝나서 취소된거라면 에너지볼도 해제
	if self.current_game_progress ~= self.game_progress.playing then
		energy_ball:Dispose()
		return
	end

	local shotable = time_passed >= shotable_duration
	if shotable then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shoot_energy_ball,
				self, energy_ball, current_dir, energy_ball.transform.localScale.x * radius_ratio))
	else
		energy_ball:Dispose()
		self:shoot_fail_reaction()
	end

	-- 탄이 다 나가거나 실패 리액션이 끝나야 재터치 가능할수있게해준다.
	self.current_touch_state = self.touch_state.none
end

-- 총 충전 최소시간을 만족하지못했을떄 발생하는 이벤트
function local_class:shoot_fail_reaction()
	music_player:PlaySfxOneShot('03_runaway_01')
	user_party.Leader:SetEmotion('surprise', true)
	user_party.Leader:SetAnimation('embarrassed', true)
	wait_for_sec(1)

	user_party.Leader:RemoveEmotion()
	user_party.Leader:RemoveAnimation()
end

function local_class:game_loop()
	while(self.current_game_progress == self.game_progress.playing) do
		self:monster_spawn_update(unity_class.time.deltaTime)

		coroutine.yield()
	end
end

function local_class:monster_spawn_update(dt)
	-- 가용할수있는 몬스터가 없으면 스폰 업데이트 하지않음.
	if #self.available_monsters == 0 then return end

	self.spawn_time_passed = self.spawn_time_passed + dt
	if self.spawn_time_passed > self.spawn_cycle then
		self.spawn_time_passed = 0
		self:spawn_monster()
	end
end

function local_class:spawn_monster()
	local monster = table.remove(self.available_monsters, 1)

	local area_bound = field:GetZone('game_area').Bounds
	local rb = area_bound.min + unity_class.vector3.right * area_bound.size.x
	local rt = area_bound.max
	local spawn_point = unity_class.vector3.right * rt.x +
			unity_class.vector3.forward * unity_class.mathf.Lerp(rt.z, rb.z, unity_class.random.value)

	character_util.convert_to_monster(monster)
	monster.FieldObjectController.DontFight = true
	monster.Position = spawn_point
	monster.ActiveState = active_state('enabled')

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.display_fake_lv_to_ui, self, monster))

	-- 몬스터가 생성된 곳에 등장 이펙트 생성
	music_player:PlaySfxOneShot('01_guild_warp_01')

	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(spawn_point)

	local move_point = unity_class.vector3.right * (area_bound.min.x - monster.Bounds.size.x * 2) +
			unity_class.vector3.forward * monster.Position.z
	local speed = monster.FieldObjectStatsBehaviour.WalkSpeed
	wp_util.move_way_points(monster, { waypoints = move_point, speed = speed, run = speed >= 2 })

	self.active_monsters[monster] = true

	-- 다음 몬스터 스폰사이클 세팅
	self:set_spawn_cycle(table_util.get_size(self.active_monsters) + 1)
end

function local_class:display_fake_lv_to_ui(monster)
	-- 몬스터로 컨버트되면 실제 레벨이 업데이트되므로 한 프레임 기다려줬다가 적용
	coroutine.yield()

	-- 실제 레벨은 1이지만 UI에서는 스테이지 스탠다드 레벨을 표기하도록 세팅
	-- 스테이지를 들어오기전, 표기되는 몬스터 레벨과 달라보이지 않도록 하기위함.
	local stat_ui = field_ui_manager:GetUI(monster)[CS.Oak.FieldUiType.CharacterStats]
	if stat_ui ~= nil then
		stat_ui:SetLevel(stage.Spec.StageStandardLevel, true)
	end
end

function local_class:sort_available_monsters()
	local hierarchy_orders = {}
	local npcs = stage.StageGameObject.transform:Find(stage.Name .. '/npcs')

	-- npc 루트 없으면 그냥 소팅 안하고 리턴
	if is_unity_null(npcs) then return end

	for i = 0, npcs.childCount - 1 do
		local name = npcs:GetChild(i).gameObject.name
		hierarchy_orders[name] = i
	end

	local poped = {}
	for _, monster in ipairs(self.available_monsters) do
		table.insert(poped, { monster })
	end

	table.sort(poped, function (left, right)
		return hierarchy_orders[left[1].Name] < hierarchy_orders[right[1].Name]
	end)

	self.available_monsters = {}
	for _, t in pairs(poped) do
		local monster = t[1]
		table.insert(self.available_monsters, monster)
	end
end

function local_class:set_spawn_monsters()
	local npcs = stage.CharacterManager:GetAllNpcs()
	for i = 0, npcs.Count - 1 do
		local npc = npcs[i]
		if string.match(npc.Name, 'shooting_game_monster') then
			npc.Position = unity_class.vector3.one * 999
			npc.FieldObjectStatsBehaviour:SetExp(0)
			npc.ActiveState = active_state('disabled')

			-- 죽어있던 몬스터들에겐 힐을 준다.
			if npc.FieldObjectStatsBehaviour.HP ~= npc.FieldObjectStatsBehaviour.MaxHP then
				local heal_info = CS.Oak.HealInfo()
				heal_info.sender = npc
				heal_info.target = npc
				heal_info.isRevive = true
				heal_info.heal = npc.FieldObjectStatsBehaviour.MaxHP
				command_util.execute_heal(heal_info)
			end

			table.insert(self.available_monsters, npc)
		end
	end

	self:sort_available_monsters()
end

function local_class:set_spawn_cycle(order)
	-- 첫 몬스터 생성 스폰사이클을 세팅해준다. 값을 찾을 수 없으면 기본값 2로 세팅해줌
	if self.spawn_cycle_each_stage[stage.Name] == nil then
		self.spawn_cycle = 2
	else
		local monster1_spawn_cycle = self.spawn_cycle_each_stage[stage.Name][order]
		self.spawn_cycle = monster1_spawn_cycle == nil and 2 or monster1_spawn_cycle
	end
end

function local_class:game_init()
	self.current_touch_state = self.touch_state.none
	self.spawn_time_passed = 0
	self.available_monsters = {}
	self.active_monsters = {}

	self:set_spawn_cycle(1)
	self:set_spawn_monsters()
end

function local_class:is_all_monster_dead()
	if #self.available_monsters > 0 then return false end

	for _, alive in  pairs(self.active_monsters) do
		if alive then
			return false
		end
	end

	return true
end

-- 플레이어가 쏘는거 처리
function local_class:start_game()
	screen_util.fade_out_async(1, unity_class.color.black)

	-- 퀘스트 마커 제거
	ui_quest_marker:RemoveQuestMarker('game_start')

	self:game_init()

	local marker = field:GetMarker(self.player_start_stand_name)
	user_party.Leader.Position = marker.position
	user_party.Leader.Direction = marker.direction

	for i = user_party.Count - 1, 1, -1 do
		local member = user_party[i]
		character_util.convert_to_npc(member)
		member.ActiveState = active_state('disabled')
	end

	camera_util.resize_by_ratio(5, 0)
	camera_util.move_async(marker.position + unity_class.vector3.right * 6, 0.05)

	screen_util.fade_in_async(1, unity_class.color.black)

	field_ui_manager:Show()

	music_player:PlaySfxOneShot('01_stage_intro_jump_01')

	character_util.set_emotion(user_party.Leader, { name = 'smile', loop = true })
	character_util.set_anim(user_party.Leader, { name = 'victory_get', loop = false })

	wait_for_sec(1.5)

	party_util.remove_emotion()
	party_util.remove_animation()

	-- 공격버튼 활성화
	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.ActionButton)
	field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction =
	CS.Oak.CharacterControllerManualTouchState.Button1Action.CustomAttack

	-- 이미 게임패드가 활성화되있는 상태라면 게임패드 라벨을 보여준다.
	if CS.Oak.Game.Instance.InputManager.GamepadEnabled then
		self:show_gamepad_label()
	end

	self:game_loop()

	self:hide_gamepad_label()

	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.ActionButton)
	field_ui_manager:Hide()

	local cleared = self:is_all_monster_dead()
	if cleared then
		self:clear_reaction()
	else
		self:fail_reaction()

		screen_util.fade_out_async(1, unity_class.color.black)

		local end_marker = field:GetMarker(self.player_end_stand_name)
		party_util.position_party(end_marker.position, end_marker.direction, 'arc')
		party_util.remove_emotion()
		party_util.remove_animation()

		camera_util.resize_to_default(0)
		camera_util.return_to_leader(0.05)

		for monster, _ in pairs(self.active_monsters) do
			character_util.convert_to_npc(monster)
			monster.ActiveState = active_state('disabled')
		end

		screen_util.fade_in_async(1, unity_class.color.black)

		self.current_game_progress = self.game_progress.none

		-- 퀘스트 마커 재표시
		ui_quest_marker:AddQuestMarkerToPoint('game_start', -1, false, vector(5.5, 0, -0.5))
	end

	local origin_party = party_util.get_origin_party()
	for _, member in ipairs(origin_party) do
		if not lua_helper.reference_equals(member, user_party.Leader) then
			character_util.convert_to_party_member(member, user_party)
			member.ActiveState = active_state('enabled')
		end
	end
end

function local_class:show_gamepad_label()
	-- 게임패드용으로 (A 누르기) UI를 만들어서 보여준다.
	self.gamepad_label = gamepad_util.show_joypad_label({
		string_key = 'joypad_tutorial_push_label'
	})
end

function local_class:hide_gamepad_label()
	gamepad_util.hide_joypad_label(self.gamepad_label)

	self.gamepad_label = nil
end

function local_class:clear_reaction()
	character_util.set_direction(user_party.Leader, 'down')

	user_party.Leader:SetEmotion('awesome', true)
	user_party.Leader:SetAnimation('success', true)
	wait_for_sec(2)

	-- 클리어 플래그로 향하는 문 오픈
	local door = get_field_object(self.door_clear_name)
	if door ~= nil then
		camera_util.move_async(door.Bounds.center, 1)

		music_player:PlaySfxOneShot('03_gimmick_jingle_01')
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_clear_name, false))
		wait_for_sec(2.5)
	end

	camera_util.resize_to_default(1)
	camera_util.return_to_leader(1)

	party_util.remove_emotion()
	party_util.remove_animation()
end

function local_class:fail_reaction()
	user_party.Leader:SetEmotion('surprise', true)
	user_party.Leader:SetAnimation('embarrassed', true)

	music_player_util.play_sfx({sfx_name = '03_runaway_01', type_priority = 'event', player_priority = 'npc'})

	wait_for_sec(1)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadConnectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadDisconnectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self:hide_gamepad_label()

	self.game_progress = nil
	self.touch_state = nil
	self.monster_spawn_type = nil
	self.active_monsters = nil
	self.available_monsters = nil
	self.spawn_cycle_each_stage = nil
	self.custom_event_listener = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
