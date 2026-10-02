local local_class = newclass('TowerSniperController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.state = {
		idle = 1,
		snipe = 2,
		wait = 3,
		shoot = 4,
		escape = 5
	}

	self.stage_battle_info = require('stageeventcontrollers/TowerSniperData.lua')

	self.current_stage_info = nil
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.target_battle_count = 1

	-- 스나이퍼 캐릭터 초기 설정
	local snipe_marker = self:get_snipe_marker()
	self.sniper = get_character(self.current_stage_info.sniper_name)
	self.sniper.SpineController:SetAttachment('[base]weapon1', 'nw_2000_sniper_rifle')
	self.sniper.Position = snipe_marker.position
	self.sniper.Direction = snipe_marker.direction
	character_util.set_anim(self.sniper, {name = 'sniper_shoot', loop = false, scale = 0})

	self.attack_range = CS.AttackRange.CreateRect(unity_class.vector3.zero, vector(50, 0))
	self.attack_range:Hide()

	self.effect_pools = {
		scope_loop = unity_object_pool.GetOrCreate('fx_targetcircle_typeb_loop'),
		scope_end = unity_object_pool.GetOrCreate('fx_targetcircle_typeb_end'),
		hit_fx = unity_object_pool.GetOrCreate('FX_hit'),
		last_hit = unity_object_pool.GetOrCreate('FX_lasthit'),
		common_cannonfire = unity_object_pool.GetOrCreate('FX_Common_CannonFire'),
		smoke_trail = unity_object_pool.GetOrCreate('Manual_AssaultRifle_Sniper_Bullet_SmokeTrail'),
	}

	self.snipe_key = 'snipe'

	self.scope_start_size = unity_class.vector3.one
	self.scope_end_size = unity_class.vector3.one * 0.5

	self.current_progress = self.progress.playing
	self:change_state(self.state.idle)
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start(e)
	-- 타이머 스테이지 시작시 동작안함
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	message_system:Publish(CS.Oak.TowerTimerStopEvent.Instance)
	self.using_timer = false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter
			or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end

	if e.Zone.Name == self:get_snipe_zone() then
		if not self.using_timer then
			-- 존 진입시 타이머 동작
			message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
			message_system:Publish(CS.Oak.TowerTimerStartEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
			self.using_timer = true
		end
		self:change_state(self.state.wait)
	elseif e.Zone.Name == self:get_death_zone() then
		self:change_state(self.state.shoot)
	elseif e.Zone.Name == self:get_escape_zone() then
		self:change_state(self.state.escape)
	end
	return true
end

function local_class:on_game_over_event(e)
	-- 게임오버시 컨트롤러 중지
	self.current_progress = self.progress.none
	self:change_state(self.state.idle)
	return true
end

function local_class:on_camera_grid_leave_event(e)
	if self.current_state == self.state.escape then
		self:change_state(self.state.idle)
	end
	return true
end

function local_class:change_state(next_state)
	if self.current_state == next_state then return end

	if self.current_state == self.state.snipe then
		-- 범위 종료
		self.attack_range:Hide()
		-- 이펙트 종료
		local stored_scale = self.scope_effect.transform.localScale
		self.scope_effect:Dispose()
		self.scope_effect = nil
		if next_state ~= self.state.shoot then
			-- 저격 성공 이외는 취소 이펙트 생성
			self.scope_effect = self.effect_pools.scope_end:Instantiate(user_party_leader.Bounds.center, unity_class.quaternion.identity, user_party_leader.Transform)
			self.scope_effect.transform.localScale = stored_scale
		end
		-- 카메라 연출 종료
		stage_camera:CancelShake(self.snipe_key)
		self.is_shaking = false
		-- 효과음 종료
		self.scope_sfx:Stop()
		self.scope_sfx = nil
	elseif self.current_state == self.state.shoot then
		-- 연출 이후 즉사처리
		music_player:PlaySfxOneShot('02_gun_shoot_02')

		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party_leader
		damage_info.target = user_party_leader
		damage_info.type = CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)

		self.effect_pools.hit_fx:Instantiate(user_party_leader.Bounds.center)
		self.effect_pools.last_hit:Instantiate(user_party_leader.Bounds.center)
		camera_util.shake(0.1, 0.2)

		self:unpause()
		self.got_hit = false
		self.current_progress = self.progress.none
	elseif self.current_state == self.state.escape then
		-- 마커 위치/방향으로 설정
		local snipe_marker = self:get_snipe_marker()
		self.sniper.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
		if snipe_marker then
			character_util.set_anim(self.sniper, {name = 'sniper_shoot', loop = false, scale = 0})
			CS.Oak.CharacterControllerScreenplayState.Stop(self.sniper)
			self.sniper.Position = snipe_marker.position
			self.sniper.Direction = snipe_marker.direction
		else
			-- 저격 마커가 없으면 컨트롤러 클리어로 간주
			self.current_progress = self.progress.cleared
		end
	end

	if next_state == self.state.snipe then
		local pivot_pos = user_party_leader.Bounds.center
		if not is_unity_null(self.scope_effect) then
			self.scope_effect:Dispose()
		end
		-- 범위 시작
		attack_range_util.setup_by_direction(self.attack_range, self.sniper.Bounds.center, (pivot_pos - self.sniper.Bounds.center).normalized, 0)
		self.attack_range:Show(0.2)
		-- 이펙트 시작
		self.scope_effect = self.effect_pools.scope_loop:Instantiate(pivot_pos, unity_class.quaternion.identity, user_party_leader.Transform)
		self.scope_effect.transform.localScale = self.scope_start_size

		-- 효과음 시작
		self.scope_sfx = music_player_util.play_sfx(
				{sfx_name = '01_targeted_01', type_priority = 'event', player_priority = 'npc'})

		self.rotate_sniper = self:get_sniper_rorate()
	elseif next_state == self.state.shoot then
		-- 발사 연출 시작
		camera_util.resize_to(3.5, 0.3)
		party_util.stop_and_disable_control()
		user_party_leader:HideWeapon(true)
		self.got_hit = false

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sniper_shoot_to_target, self))
		self:pause()
	elseif next_state == self.state.escape then
		self.sniper.SpineController.AimPoint = nil
		character_util.remove_anim_and_emotion(self.sniper)
		self:escape_with_waypoints()
		self.sniper.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		self.target_battle_count = self.target_battle_count + 1
	end

	self.time_passed = 0
	self.current_state = next_state
end

function local_class:escape_with_waypoints()
	local points, dir = self:get_way_points()
	local info = nil
	if points then
		info = CS.Oak.WaypointMoveInfo()
		info.waypoints = points
		info.speed = self.current_stage_info.escape_speed
		info.lastDirection = dir
		info.run = true
		info.endType = CS.Oak.WaypointMoveEndType.Stop
		info.yMode = CS.Oak.CharacterYMode.Free
		info.playSfx = false
	elseif self.target_battle_count < #self.current_stage_info.snipe_infos then
		local snipe_marker = self:get_snipe_marker(self.target_battle_count + 1)
		info = CS.Oak.WaypointMoveInfo.Create(snipe_marker.position, self.current_stage_info.escape_speed,
				true, snipe_marker.direction)
	else
		self.escape_duration = 0
		return
	end

	self.escape_duration = info:GetDuration(self.sniper.Position)
	CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.sniper, info)
end

function local_class:pause()
	message_system:PublishSync(CS.Oak.GlobalTimerRequestPauseEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))

	local current_battle = stage.BattleManager:GetBattleForMyParty()
	if current_battle ~= nil then
		local enemies = current_battle.Enemies
		self.paused_enemys = {}
		for i = 0,enemies.Count - 1 do
			local target_character = enemies[i].Character
			if target_character.ActiveState == CS.Oak.ActiveState.Enabled and
					not target_character.FieldObjectStatsBehaviour.IsDead then
				-- 전투중인 몬스터 일시 정지처리
				target_character.ActiveState = CS.Oak.ActiveState.Visible
				target_character.CharacterBehaviour:CancelAllBattleActions(false)
				table.insert(self.paused_enemys, target_character)
			end
		end
	end
end

function local_class:unpause()
	message_system:PublishSync(CS.Oak.GlobalTimerRequestResumeEvent.Create(CS.Oak.GlobalTimerId.SingleGameTimer))
	if self.paused_enemys then
		for i = #self.paused_enemys, 1, -1 do
			self.paused_enemys[i].ActiveState = CS.Oak.ActiveState.Enabled
			table.remove(self.paused_enemys, i)
		end
		self.paused_enemys = nil
	end
end

function local_class:get_snipe_zone()
	if self.target_battle_count <= #self.current_stage_info.snipe_infos then
		return self.current_stage_info.snipe_infos[self.target_battle_count].snipe_zone
	end
end

function local_class:get_death_zone()
	if self.target_battle_count <= #self.current_stage_info.snipe_infos then
		return self.current_stage_info.snipe_infos[self.target_battle_count].death_zone
	end
end

function local_class:get_escape_zone()
	if self.target_battle_count <= #self.current_stage_info.snipe_infos then
		return self.current_stage_info.snipe_infos[self.target_battle_count].escape_zone
	end
end

function local_class:get_way_points()
	local points = nil
	local dir = CS.Oak.Direction.Right
	if self.target_battle_count <= #self.current_stage_info.snipe_infos then
		local way_points = self.current_stage_info.snipe_infos[self.target_battle_count].way_points
		if way_points and #way_points > 0 then
			points = create_generic_list(unity_class.vector3)
			for i = 1, #way_points do
				local marker = field:GetMarker(way_points[i])
				points:Add(marker.position)
				dir = marker.direction
			end
		end
	end

	return points, dir
end

function local_class:get_snipe_marker(idx)
	if idx and idx <= #self.current_stage_info.snipe_infos then
		return field:GetMarker(self.current_stage_info.snipe_infos[idx].snipe_marker)
	elseif self.target_battle_count <= #self.current_stage_info.snipe_infos then
		return field:GetMarker(self.current_stage_info.snipe_infos[self.target_battle_count].snipe_marker)
	end
end

function local_class:get_sniper_rorate()
	if self.target_battle_count <= #self.current_stage_info.snipe_infos then
		return self.current_stage_info.snipe_infos[self.target_battle_count].rotate_sniper
	end
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.snipe then
		local sniper_center = self.sniper.Position + self.sniper.SpineController.SpineTotalOffset
		local rifle_dir = self:get_current_rifle_dir(user_party_leader)
		local rifle_pos = self:get_current_muzzle_pos(user_party_leader, 0.5)

		if self.rotate_sniper then
			self.sniper.Direction = vector_util.to_direction(rifle_dir)
		end
		-- IK
		self.sniper.SpineController.AimPoint = CS.Oak.IKSupportUtil.GetAimPointInSpineSpace(rifle_pos, sniper_center)
		-- 범위 업데이트
		attack_range_util.setup_by_direction(self.attack_range, rifle_pos, rifle_dir, user_party_leader.Bounds.center.y)
		-- 이펙트 크기 업데이트
		local normalized_shrink_time = self.time_passed / self.current_stage_info.snipe_duration
		self.scope_effect.transform.localScale = unity_class.vector3.Lerp(self.scope_start_size,
				self.scope_end_size, normalized_shrink_time)

		if self:is_blocked_between(user_party_leader) then
			-- wait 상태로 전환
			self:change_state(self.state.wait)
		elseif self.time_passed >= self.current_stage_info.snipe_cam_shake_time and not self.is_shaking then
			-- 카메라 진동 ON
			local cam_shake_time = self.current_stage_info.snipe_duration - self.current_stage_info.snipe_cam_shake_time
			self.is_shaking = true
			camera_util.shake(0.04, cam_shake_time, nil, self.snipe_key)
		elseif self.time_passed > self.current_stage_info.snipe_duration then
			-- 저격 성공 연출
			self:change_state(self.state.shoot)
		end
	elseif self.current_state == self.state.wait then
		if not self:is_blocked_between(user_party_leader) then
			-- snipe 상태로 전환
			self:change_state(self.state.snipe)
		end
	elseif self.current_state == self.state.escape then
		if not self:is_pos_in_camera(self.sniper.Position) or self.time_passed > self.escape_duration then
			-- 카메라 밖으로 이동하면 목표위치로 바로 이동
			self:change_state(self.state.idle)
		end
	elseif self.current_state == self.state.shoot then
		if self.got_hit then
			self:change_state(self.state.idle)
		end
	end
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴 (DamageField.lua, DemonWorldBasicSystem.lua참고)
function local_class:is_pos_in_camera(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	if math.abs(camera_pos.x - pos.x) > cam_half_width + 0.7 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 0.5 then
		return false
	end

	return true
end

-- 사격 연출 (SteampunkSniper.lua 참고)
function local_class:sniper_shoot_to_target()
	local sniper = self.sniper
	local target_pos = user_party_leader.Bounds.center

	local bullet_speed = 60
	local effect_scale_ratio = bullet_speed / 30 * 1.1
	local effect_delay_ratio = bullet_speed / 30 * 0.5
	local rifle_dir = self:get_current_rifle_dir(user_party_leader)
	local muzzle_pos = self:get_current_muzzle_pos(user_party_leader) + vector(0, 0.4, 0)
	local shoot_dir = (target_pos - muzzle_pos).normalized
	local start_pos = muzzle_pos
	local end_pos = target_pos - shoot_dir * 0.3
	local target_hit_hour = unity_class.vector3.Distance(start_pos, end_pos) / bullet_speed

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		character_util.set_animation_n_times_async(sniper, {name = 'sniper_shoot'})
		character_util.set_animation_n_times_async(sniper, {name = 'rifle_reload'})
		character_util.set_anim(sniper, {name = 'sniper_shoot', loop = false, scale = 0})
	end))

	wait_for_sec(0.1)

	local fx_rotation = unity_class.quaternion.Euler(0, unity_class.quaternion.FromToRotation(unity_class.vector3.right, rifle_dir).eulerAngles.y, 0)
	self.effect_pools.common_cannonfire:Instantiate(muzzle_pos, fx_rotation, sniper.Transform)

	local fx_rotation_2 = unity_class.quaternion.LookRotation(shoot_dir) * unity_class.quaternion.Euler(0, 90, 0)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		if target_hit_hour > effect_delay_ratio then
			wait_for_sec(target_hit_hour - effect_delay_ratio)
			local smoke_effect = self.effect_pools.smoke_trail:Instantiate(bullet_sprite.transform.position, fx_rotation_2, nil)
			smoke_effect.transform.localScale = vector(effect_scale_ratio, 1, 1)
		else
			local smoke_effect = self.effect_pools.smoke_trail:Instantiate(start_pos, fx_rotation_2, nil)
			smoke_effect.transform.localScale = vector(effect_scale_ratio, 1, 1)
		end
	end))

	local wait_sec = (end_pos - start_pos).magnitude / bullet_speed
	wait_for_sec(wait_sec)

	self.got_hit = true
end

function local_class:is_blocked_between(target)
	if target.FieldObjectStatsBehaviour.IsDead then return false end

	local detection_pos = vector_util.get_x0z(self.sniper.Position, target.Bounds.center.y)
	local bound = CS.UnityEngine.Bounds(detection_pos, unity_class.vector3.one * 0.05)
	local move = vector_util.get_x0z(target.Position - self.sniper.Position)
	local list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(bound, move)

	local is_blocked = false
	for i = 0, list.Count - 1 do
		local v = list[i]
		local is_holding_object = lua_helper.reference_equals(v.Holdable.Holder, user_party_leader)
		local is_ethereal = CS.Oak.ICrashBehaviourExtensions.IsEthereal(v.CrashBehaviour)
		local is_character = lua_helper.type_compare(v, CS.Oak.Character)

		if not is_holding_object and not is_ethereal and not is_character then
			is_blocked = true
			break
		end
	end
	list:Dispose()

	return is_blocked;
end

function local_class:get_current_rifle_dir(target)
	return vector_util.get_x0z(target.Bounds.center - self.sniper.Bounds.center).normalized
end

function local_class:get_current_muzzle_pos(target, offset)
	local offset_size = offset == nil and 0.85 or offset

	local sniper_center = self.sniper.Position + self.sniper.SpineController.SpineTotalOffset
	local rifle_dir = self:get_current_rifle_dir(target)
	local rifle_pos = sniper_center + rifle_dir * offset_size

	return rifle_pos
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	if not is_unity_null(self.attack_range) then
		CS.UnityEngine.Object.Destroy(self.attack_range)
	end
	self.attack_range = nil
	self.effect_pools = nil

	self.current_stage_info = nil

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
