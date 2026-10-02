local local_class = newclass('XMasChallengeBlizzardController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 사용할 프리셋
	self.preset = { blizzard = nil, blizzard_fade = nil }

	-- 생성된 눈보라 이펙트
	self.blizzard = {
		-- 풀링된 이펙트
		obj = nil,
		-- 이펙트 material
		material = nil,
		-- material color
		color = nil
	}

	-- 생성된 페이드 이펙트
	self.fade = {
		-- 풀링된 이펙트
		obj = nil,
		-- particle system main module
		main_module = nil,
		--
		color = nil,
		--
		gradient = nil
	}

	-- preset property name
	self.property_name = '_TintColor'

	self.is_blizzard_active = false

	-- 눈보라 대미지, 캠프파이어 힐 데이터
	-- scale: 최대 체력 * scale
	-- duration: 주기
	self.damage_scale = 0.05
	self.heal_scale = 0.05
	self.damage_duration = 1
	self.heal_duration = 0.5

	-- 눈보라 틴트 강도
	self.blizzard_tint = 0.2

	-- 카메라 패닝 스피드
	self.panning_speed = 9

	self.progress_enum = {
		-- 초기 상태
		none = 0,
		-- 눈보라 이벤트 상태
		start_blizzard = 1,
		-- 눈보라 이벤트를 클리어한 상태
		clear = 2,
		-- 눈보라 이벤트를 실패한 상태
		fail = 3
	}

	self.current_progress = self.progress_enum.none

	-- 패닝 연출 본 여부 커스텀 키
	self.show_panning_custom_key = 0

	-- 기믹 이름
	self.entry_door_name = 'entry_door'

	-- 이벤트 존 이름
	self.blizzard_start_zone = 'blizzard_start_event'
	self.campfire_zone = 'campfire_event'

	--- 버그 방지를 위해 명시적으로 전투를 벗어날 구역
	self.clear_zone = 'clear_zone'

	-- 마커
	self.get_leader_start_pos = function() return field:GetMarker('leader_start_pos').position end
	self.get_camera_pos = function() return field:GetMarker('camera_pos').position end

	-- npc
	self.get_battle_1 = function(index) return get_character('battle1_' .. index) end

	-- 플레이어가 캠프파이어 주변(힐 존)에 있는지
	self.in_heal_zone = false

	self:check_time_attack_mission()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')

	self.is_show_panning = stage_progress:GetCustomData(self.show_panning_custom_key, false)

	if not self.is_show_panning then
		-- 몬스터 전투 중단
		local battle1_index = 1
		while true do
			local battle1 = self.get_battle_1(battle1_index)

			if not battle1 then break end

			battle1.FieldObjectController.DontFight = true
			battle1_index = battle1_index + 1
		end
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.preset.blizzard = unity_object_pool.GetOrCreate('FX_Blizzard')
	self.preset.blizzard_fade = unity_object_pool.GetOrCreate('FX_Screen_Blizzard_Cloud')

	self.fade.gradient = CS.UnityEngine.ParticleSystem.MinMaxGradient(unity_class.color.black)

	quest_util.load_pool_resource(
		'FX_Blizzard',
		'FX_Screen_Blizzard_Cloud'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	if not is_unity_null(self.blizzard_sfx) then
		self.blizzard_sfx:FadeOut(2)
		self.blizzard_sfx = nil
	end

	self:blizzard_dispose()

	self.cs_controller = nil

	self.game_timer = nil
	self.check_time_attack_mission = nil
end

--- OnEvent
function local_class:on_event(_)
	return false
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.blizzard_start_zone) then
		if self.current_progress == self.progress_enum.none then
			self.current_progress = self.progress_enum.start_blizzard
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.blizzard_start, self))
			return true
		end
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, self.campfire_zone) and not self.in_heal_zone then
		self.in_heal_zone = true
		return true
	end

	--- 마지막 배틀 클리어 존에 들어왔다면, 버그 방지를 위해 명시적으로 배틀을 종료시킴
	if type_util.is_zone_full_enter(e, user_party.Leader, self.clear_zone) then
		stage.BattleManager:ForceEndBattles()
		return true
	end

	return false
end

--- ZoneLeaveEvent
function local_class:on_zone_leave_event(e)

	if type_util.is_zone_full_leave(e, user_party.Leader, self.blizzard_start_zone) then
		if self.current_progress == self.progress_enum.start_blizzard then
			self.current_progress = self.progress_enum.clear
			return true
		end
	end

	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) and e.Zone.Name == self.campfire_zone then
		self.in_heal_zone = false
		return true
	end

	return false
end

--- GlobalTimerAlarmEvent
function local_class:on_global_timer_alarm_event(e)

	if e.IsComplete and self.current_progress == self.progress_enum.start_blizzard then
		self.current_progress = self.progress_enum.fail

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			party_util.stop_and_disable_control()
			field_ui_manager:Hide()
			local battle = stage.BattleManager:GetBattleForMyParty()

			if battle ~= nil then
				for i = 0, battle.Enemies.Count - 1 do
					battle.Enemies[i].Character.FieldObjectController.DontFight = true
				end

			end

			stage.BattleManager:ForceEndBattles()
			user_party.Leader.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance

			self:game_over()
		end))
		return true
	end

	return true
end

--- FieldObjectDestroyedEvent
function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		if self.current_progress == self.progress_enum.start_blizzard then
			self.current_progress = self.progress_enum.fail
		end
		return true
	end

	return false
end

--- 눈보라 존 이벤트 시작
function local_class:blizzard_start()
	party_util.stop_and_disable_control()
	field_ui_manager:Hide()

	local leader = user_party.Leader

	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, false)

	if not self.is_show_panning then
		-- 카메라 패닝 연출
		-- bgm_transition: Field(ondemand/xmas/preload:bgm_xmas_main) -> Muted
		music_player_util.play_stage_music({ state = 'muted', mix = 2 })
		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		self:blizzard_lerp(0, self.blizzard_tint, 0)

		camera_util.move(self.get_camera_pos(), 0)
		leader.Position = self.get_leader_start_pos()
		character_util.set_direction(leader, 'up')

		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.entry_door_name))

		wait_for_sec(1)

		-- bgm_transition: Muted -> Event(bgm_boss_intro)
		music_player_util.play_stage_music({ name = 'bgm_boss_intro', state = 'event', mix = 2 })
		self.blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = 2 })
		music_player:PlaySfxOneShot('03_dialogue_china_01')
		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		camera_util.return_to_leader(
			(self.get_camera_pos() - self.get_leader_start_pos()).magnitude / self.panning_speed)

		-- 몬스터 전투 시작
		local battle1_index = 1
		while true do
			local battle1 = self.get_battle_1(battle1_index)

			if not battle1 then break end

			battle1.FieldObjectController.DontFight = false
			battle1_index = battle1_index + 1
		end

		local stage_custom = stage_progress:SetCustomData(self.show_panning_custom_key, true)
		local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
		coroutine.yield(req)
	else
		-- bgm_transition: Field -> Muted
		music_player_util.play_stage_music({ state = 'muted' })

		self.blizzard_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_01', loop = true, fade_in_time = 2 })
		coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.blizzard_lerp, self, 0, self.blizzard_tint, 0.5))

		message_system:Publish(CS.Oak.DoorCloseEvent.Create(self.entry_door_name))

		character_util.jump(leader, 0.7, 0.3)
		character_util.move_to_async(leader, leader.Position + unity_class.vector3.forward,
			0.3, nil, true)
	end

	field_ui_manager:Show()
	party_util.reset_controllers()

	music_player_util.remove_stage_music_clip({ state = 'combat' })
	music_player_util.set_stage_music_clip_async({ name = 'bgm_battle_event', state = 'field' })
	-- bgm_transition: Event(bgm_boss_intro) -> Field(bgm_battle_event)
	music_player_util.play_stage_music({ state = 'field' })

	self:start_timer()

	-- 대미지 정보
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.DotDamage | CS.Oak.DamageType.Trap | CS.Oak.DamageType.Passive
	damage_info.sender = leader
	damage_info.target = leader
	damage_info.direction = unity_class.vector3.zero
	damage_info.noCritical = true
	damage_info.damage = unity_class.mathf.Floor(leader.FieldObjectStatsBehaviour.MaxHP * self.damage_scale)

	-- 힐 정보
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = leader
	heal_info.target = leader
	heal_info.heal = unity_class.mathf.Floor(leader.FieldObjectStatsBehaviour.MaxHP * self.heal_scale)

	while self.current_progress == self.progress_enum.start_blizzard do
		local current_state = self.in_heal_zone

		local duration = self.in_heal_zone and self.heal_duration or self.damage_duration
		local time_passed = 0

		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime

			if current_state ~= self.in_heal_zone then
				current_state = self.in_heal_zone
				-- 힐은 즉시, 대미지는 지정한 시간 뒤에 적용
				time_passed = self.in_heal_zone and duration or 0
			end

			if self.current_progress ~= self.progress_enum.start_blizzard then
				break
			end

			coroutine.yield(nil)
		end

		if self.current_progress ~= self.progress_enum.start_blizzard then
			break
		end

		if not self.in_heal_zone then
			command_util.execute_damage(damage_info)
		else
			music_player:PlaySfxOneShot('02_magic_heal_01')
			command_util.execute_heal(heal_info)
		end
	end

	-- bgm_transition: Field(bgm_battle_event) -> Event(ondemand/xmas/preload:bgm_xmas_main)
	music_player_util.play_stage_music({ name = 'ondemand/xmas/preload:bgm_xmas_main', state = 'event', mix = 2 })

	local elapsed_time = self.game_timer and self.game_timer.Elapsed or self.game_timer_duration

	self:end_timer()

	self.blizzard_sfx:FadeOut(2)
	self:blizzard_lerp(self.blizzard_tint, 0, 0.5)

	self:blizzard_dispose()

	self:check_time_attack_mission_cleared(elapsed_time)
end

--- 눈보라 강도 조절
function local_class:blizzard_lerp(from, to, duration)
	if not self.is_blizzard_active then
		--- flag set
		self.is_blizzard_active = true

		--- blizzard set up
		self:blizzard_set_up()
	end

	--- blizzard inner param refresh
	self:blizzard_color_refresh()

	local time_passed = 0

	--- blizzard update
	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Max(time_passed / duration, 0)
		local cur_tint = unity_class.mathf.Lerp(from, to, progress)

		self:blizzard_update(cur_tint)

		coroutine.yield(nil)
	end
end

--- blizzard 이펙트 셋업
function local_class:blizzard_set_up(args)
	if self.blizzard == nil or self.fade == nil then return end
	if self.blizzard.obj ~= nil or self.fade.obj ~= nil then return end

	local with_fade = lua_helper.get_value(args, 'with_fade', true)
	local alpha = lua_helper.get_value(args, 'alpha', -1)
	local custom_alpha = false

	if not float_util.almost_close_to(alpha, -1) then
		custom_alpha = true
	end

	local camera = stage_camera

	self.blizzard.obj = self.preset.blizzard:Instantiate(
		camera.Transform.position + vector(0, 5, 10), unity_class.quaternion.identity, camera.Transform)
	self.blizzard.material = self.blizzard.obj.transform:GetComponentInChildren(
		typeof(CS.UnityEngine.Renderer)).material

	self.blizzard.color = self.blizzard.material:GetColor(self.property_name)

	local target_alpha = custom_alpha and alpha or self.blizzard.color.a * 0.2

	self.blizzard.material:SetColor(self.property_name, unity_color(
		{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, target_alpha }))

	if with_fade then
		self.fade.obj = self.preset.blizzard_fade:Instantiate(
			camera.Transform.position, unity_class.quaternion.identity, camera.Transform)
		self.fade.main_module = self.fade.obj.transform:GetComponentInChildren(
			typeof(CS.UnityEngine.ParticleSystem)).main
		self.fade.color = self.fade.main_module.startColor.color

		target_alpha = custom_alpha and alpha or self.fade.color.a * 0.2

		self.fade.gradient.color = unity_color(
			{ self.fade.color.r, self.fade.color.g, self.fade.color.b, target_alpha })

		self.fade.main_module.startColor = self.fade.gradient
		self.fade.color = self.fade.main_module.startColor.color
	end
end

function local_class:blizzard_update(alpha, fade_alpha)
	if fade_alpha == nil then
		fade_alpha = alpha
	end

	self.blizzard.material:SetColor(self.property_name, unity_color(
		{ self.blizzard.color.r, self.blizzard.color.g, self.blizzard.color.b, alpha }))

	if self.fade.obj ~= nil then
		self.fade.gradient.color = unity_color(
			{ self.fade.color.r, self.fade.color.g, self.fade.color.b, fade_alpha })

		self.fade.main_module.startColor = self.fade.gradient
	end
end

function local_class:blizzard_color_refresh()
	self.blizzard.color = self.blizzard.material:GetColor(self.property_name)

	if self.fade.obj ~= nil then
		self.fade.color = self.fade.main_module.startColor.color
	end
end

--- 눈보라 관련 이펙트 dispose
function local_class:blizzard_dispose()
	if self.blizzard.obj ~= nil then
		self.blizzard.material = nil
		self.blizzard.color = nil
		self.blizzard.obj:Dispose()
		self.blizzard.obj = nil
	end

	if self.fade.obj ~= nil then
		self.fade.main_module = nil
		self.fade.color = nil
		self.fade.obj:Dispose()
		self.fade.obj = nil
	end
end

-- 타이머 시작
function local_class:start_timer()
	music_player:PlaySfxOneShot('02_gimmick_ticking_01')

	field_ui_manager:SetUI(user_party.Leader, CS.Oak.FieldUiType.EventTimer)

	self.game_timer_duration = 60
	self.game_timer = CS.Oak.InGameTimer.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.game_timer_duration, nil)
	message_system:PublishSync(CS.Oak.GlobalTimerAddEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, self.game_timer))
	message_system:Subscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent), 'on_global_timer_alarm_event')
	message_system:Publish(CS.Oak.EventTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer, true))
end

-- 타이머 종료
function local_class:end_timer()
	self.game_timer = nil
	message_system:PublishSync(CS.Oak.GlobalTimerRemoveEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Unsubscribe(self, typeof(CS.Oak.GlobalTimerAlarmEvent))
	message_system:Publish(CS.Oak.EventTimerStopEvent.Instance)
end

-- 게임 오버 연출
function local_class:game_over()
	stage:SetGameOver(CS.Oak.UIGameOver.UIGameOverButtonType.LobbyWithWaypoint, false, true)
	message_system:Publish(CS.Oak.GameOverEvent.Instance)

	music_player:PlaySfxOneShot('01_drown_01')

	character_util.set_direction(user_party.Leader, direction_util.to_side_dir(user_party.Leader.Direction))
	character_util.set_emotion(user_party.Leader, { name = 'damaged' })
	character_util.set_anim(user_party.Leader, { name = 'frustration', loop = false, scale = 0.4 })
end

function local_class:check_time_attack_mission()
	local data = CS.Oak.SeasonAchievementsData.Value
	local available_season = data:GetAvailableSeason()
	if available_season == nil then
		return
	end

	local mission_list = data:GetAvailableMissionList(available_season.Id)
	if mission_list == nil or mission_list.Count == 0 then
		return
	end

	for i = 0, mission_list.Count - 1 do
		local mission = mission_list[i]
		if mission.Type == CS.Oak.MissionType.WinterSurvivalTimeAttack then
			self.time_attack_mission = mission
			break
		end
	end
end

function local_class:check_time_attack_mission_cleared(elapsed_time)
	if self.current_progress ~= self.progress_enum.clear then
		return
	end

	if self.time_attack_mission and elapsed_time < self.time_attack_mission.Value then
		local stage_custom = CS.Oak.StageCustom()
		stage_custom.ClearInTime = true
		local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
		coroutine.yield(req)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
