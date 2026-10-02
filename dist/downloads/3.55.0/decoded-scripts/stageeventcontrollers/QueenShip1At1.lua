local local_class = newclass('QueenShip1At1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 소히 가져오기
	self.get_sohee = function()
		return get_character('sohee')
	end

	-- 공주 가져오기
	self.get_princess_bat = function()
		return get_character('princess_bat')
	end

	-- field object
	self.get_rooftop_exit = function()
		return get_field_object('rooftop_exit_2')
	end

	-- 메인 퀘스트 id
	self.main_quest_id = 311

	-- resource
	self.res_holder = nil
	self.broken_trailer = nil
	self.rain_screen_effect = nil
	self.rain_ground_effect = nil

	-- sfx
	self.rain_sfx = nil

	-- custom state
	self.civilian_key = 'stage1_civilian_'

	-- fx
	self.get_fx_darkmagic_missile = function()
		return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj')
	end

	self.get_fx_darkmagic_missile_explosion = function()
		return unity_object_pool.GetOrCreate('FX_DarkMagicMissile_Proj_Explosion')
	end

	self.get_thunder_fx = function()
		return unity_object_pool.GetOrCreate('fx_env_rain_thunder_flash_screen_fx')
	end

	-- 경찰 총 쏘는 구역
	self.shoot_helpers = nil
	self.shot_loop = true
	self.shot_req_cnt = 0

	-- 번개
	self.thunder_loop = false

	-- 미사일 포격
	self.missile_active = true

	self.bombing_range_pool = nil
	self.bombing_radius = 1.4
	self.bombing_range_pool_size = 10

	-- wall 구역 미사일 관리용
	self.wall_missile_active = false
	self.wall_missile_zone_name = 'wall_missile_zone_'
	self.wall_missile_marker_name = 'wall_missile_'

	self.wall_missile_points = {}
	self.wall_marker_count = { 6, 3, 5, 2, 4, 4, 2, 3, 2, 2, 4, 3 }
	self.wall_missile_req_cnt = 0
	self.wall_missile_zone_count = 12
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleActionsChangedEvent), 'on_battle_actions_changed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_battle_actions_changed_event(e)
	if e.Target ~= user_party.Leader then
		return false
	end

	local character_spec_id = 1
	if user_util.has_knight_male() then
		character_spec_id = 2
	end

	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'landmark_broken' then
		self:landmark_setting()

		return true
	elseif e:GetParamAt(0) == 'trailer_move' then
		start_coroutine(self.trailer_move, self, tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)), e:GetParamAt(3))

		return true
	elseif e:GetParamAt(0) == 'trailer_rotate' then
		start_coroutine(self.trailer_rotate, self, tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)))

		return true

	elseif e:GetParamAt(0) == 'trailer_shake' then
		start_coroutine(self.trailer_shake, self)

		return true
	elseif e:GetParamAt(0) == 'trailer_stop_shake' then
		self.trailer_shake_loop = false

		return true
	elseif e:GetParamAt(0) == 'active_rain' then
		self:activate_rain_effect_and_sound(true)

		return true
	elseif e:GetParamAt(0) == 'deactive_rain' then
		self:activate_rain_effect_and_sound(false)

		return true
	elseif e:GetParamAt(0) == 'bomb_fail' then
		start_coroutine(self.bomb_fall, self, e:GetParamAt(1),
				tonumber(e:GetParamAt(2)), tonumber(e:GetParamAt(3)), tonumber(e:GetParamAt(4)))

		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, 'wall_police_shot_zone') then
		start_coroutine(self.police_shot_bullet, self)

		return true
	end

	for i = 1, self.wall_missile_zone_count do
		if type_util.is_zone_full_enter(e, user_party.Leader, self.wall_missile_zone_name .. i) and
				self.wall_missile_active then
			start_coroutine(self.wall_missile_routine, self, i)
			return true
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, 'wall_police_shot_zone') then
		self.shot_loop = false

		return true
	end

	for i = 1, self.wall_missile_zone_count do
		if type_util.is_zone_full_leave(e, user_party.Leader, self.wall_missile_zone_name .. i) then
			self.wall_missile_req_cnt = self.wall_missile_req_cnt + 1
			return true
		end
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_character('s2_civilian_3')) then
		start_coroutine(self.trapped_civilian, self)

		return true

	elseif lua_helper.reference_equals(e.Target, self.get_rooftop_exit()) then
		start_coroutine(self.rooftop_move_event, self)

		return true
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == self.main_quest_id then
		if e.CurrentProgress == 3 then
			self:trapped_civilian_check()

			return true
		end
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.missile_active = false
	self.wall_missile_active = false
	self.wall_missile_req_cnt = -1

	self.trailer_shake_loop = false
	self.shot_loop = false
	self.shoot_helpers = nil
	self.thunder_loop = false

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
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleActionsChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	character_util.remove_relate_event(get_character('s2_civilian_3'), self.cs_controller)

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.wall_missile_points = nil
	self.wall_marker_count = nil

	for _, attack_range in pairs(self.bombing_range_pool) do
		if is_unity_null(attack_range) == false then
			CS.UnityEngine.Object.Destroy(attack_range)
		end
	end
	self.bombing_range_pool = nil

	self:dispose_trailer()
	self:dispose_stage_effect()

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	quest_icon.PreLoad()

	quest_util.load_pool_resource(
			'fx_siren_demonworld',
			'FX_DarkMagicMissile_Proj',
			'FX_DarkMagicMissile_Proj_Explosion',
			'fx_env_rain_thunder_flash_screen_fx')

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
			screen_util.fade_in(0, unity_class.color.black, 'linear')
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

	-- 리더 파티 세팅
	if main_quest_progress == nil or main_quest_progress.InnerProgress < 3 then
		change_leader_character({ self.get_sohee(), self.get_princess_bat() })
	else
		change_leader_character({ self.get_princess_bat() })
	end

	-- 폭탄 풀 세팅
	self:load_bombing_range_pool()

	-- 벽 구역 인베이더 미사일 포격 세팅
	self:wall_missile_setting()

	-- 총 쏘는 구역 경찰 세팅
	self:wall_police_setting()

	-- 랜드마크 상태 변경
	if main_quest_progress ~= nil and main_quest_progress.InnerProgress ~= 0 then
		self:landmark_setting()
	end

	-- 환경 이펙트 세팅
	if main_quest_progress ~= nil then
		self:setting_stage_effect(true)
	end

	if main_quest_progress == nil or main_quest_progress.InnerProgress < 2 then
		self:trailer_setting({ field:GetMarker('s2_broken_trailer_pos'), field:GetMarker('s4_broken_trailer_pos') })
	elseif main_quest_progress.InnerProgress < 4 then
		self:trailer_setting({ field:GetMarker('s3_broken_trailer_pos'), field:GetMarker('s4_broken_trailer_pos') })
	else
		self:trailer_setting({ field:GetMarker('s3_broken_trailer_pos'), field:GetMarker('s5_broken_trailer_pos') })
	end

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 3 then
		get_field_object('rooftop_exit').ActiveState = active_state('disabled')
	end

	self.get_rooftop_exit().Interactable = CS.Oak.PublishInteractable.Create()

	-- 섹션 2~3에서 쓰이는 구출용 시민 세팅(파티 세팅보다 뒤에 세팅)
	if main_quest_progress ~= nil and main_quest_progress.InnerProgress == 1 then
		self:setting_civilian(false)
	elseif main_quest_progress.InnerProgress == 2 then
		self:setting_civilian(true)
	end

	self:setting_trapped_civilian(main_quest_progress)
	self.wall_missile_active = true

	if main_quest_progress == nil or main_quest_progress.InnerProgress == 0 then
		start_stage_event('left', field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 1 then
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 2 then
		start_stage_event('right', field:GetMarker('s2_civilian_pos_3_1').position, true, true)
	elseif main_quest_progress.InnerProgress == 3 then
		start_stage_event('right', field:GetMarker('s4_princess_pos').position, false, true)
	elseif main_quest_progress.InnerProgress == 4 then
		field_ui_manager:Hide()
		start_stage_event('right', field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 5 then
		start_stage_event('right', field:GetMarker('s5_event_camera_pos').position, true, true)
	else
		get_field_object('exit_1').Position = field_util.get_marker_pos('exit_pos')
		start_stage_event('left', field:GetMarker('s4_princess_pos').position, true, true)
	end
end

--region 경찰 총쏘는 구역
function local_class:wall_police_setting()
	local pattern_info = { columns = 1 }
	local proj_data = game_data_service.GetData('ProjectileData')
	local proj_spec = proj_data:GetSpec('rifle_bullet_long_dist'):Clone()
	local shooting_police = {
		get_character('wall_police_3'),
		get_character('wall_police_4'),
		get_character('wall_police_6') }

	self.shoot_helpers = {}

	for i = 1, 3 do
		local ps = CS.Oak.LuaIProjectileShooter(self, shooting_police[i])
		self.shoot_helpers[i] = CS.Oak.ShootHelper(CS.Oak.Projectile.MoveType.Directional,
				ps, proj_spec, pattern_info, CS.Oak.ShootHelperShootEffectType.EachShootWithShootOffset)
	end

	character_util.shake(get_character('wall_police_7'), 0.03, 99999)
	character_util.shake(get_character('wall_police_9'), 0.03, 99999)
	character_util.shake(get_character('wall_police_10'), 0.03, 99999)
	get_field_object('s1_police_wall').CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	get_field_object('s1_car').transform:Find('fx').gameObject:SetActive(false)

	get_character('wall_police_4').Hitbox = CS.Oak.Hitbox(vector(0.5, 0.5, 0.5), vector(1.5, 1, 1))
end

function local_class:police_shot_bullet()
	self.shot_req_cnt = self.shot_req_cnt + 1
	local req_cnt = self.shot_req_cnt
	local time_passed = 0
	local police = { get_character('wall_police_3'),
					 get_character('wall_police_4'),
					 get_character('wall_police_6') }

	local pattern = { 'shot', 'shot', 'shot', 'shot', 'idle',
					  'shot', 'shot', 'shot', 'shot', 'idle',
					  'shot', 'shot', 'shot', 'shot', 'reload', 'reload' }
	local pattern_index = { random_util.get_random_int(1, #pattern),
							random_util.get_random_int(1, #pattern),
							random_util.get_random_int(1, #pattern) }

	character_util.remove_anim(get_character('wall_police_1'))
	character_util.set_anim(get_character('wall_police_1'), { name = 'release' , sfx_name = '01_swing_01' })

	self.shot_loop = true
	while self.shot_loop and self.shot_req_cnt == req_cnt do
		time_passed = time_passed + unity_class.time.deltaTime

		-- 구간을 0.4초 단위로 쪼갬
		if time_passed >= 0.4 then
			time_passed = 0
			for i = 1, #police do
				pattern_index[i] = pattern_index[i] % #pattern + 1
			end
		end

		for i = 1, #police do
			if pattern[pattern_index[i]] == 'shot' and time_passed == 0 then
				scene_util.set_anim_loop(police[i], 'handgun_attack')
				self.shoot_helpers[i]:ShootTargetPosition(police[i].Position - vector(10, 0, 0.2),
						vector(0, 0, 0.2), -1)
			elseif pattern[pattern_index[i]] == 'idle' and time_passed == 0 then
				scene_util.set_anim_loop(police[i], 'handgun_idle')
			elseif pattern[pattern_index[i]] == 'reload' and time_passed == 0 then
				scene_util.set_anim_loop(police[i], 'handgun_reload')
			end
		end
		coroutine.yield()
	end

	character_util.remove_anim(get_character('wall_police_1'))
	character_util.set_anim(get_character('wall_police_1'), { name = 'release' })
end
--endregion

--region 부서진 트레일러
--- 타일셋의 크기가 모자라서 프리팹 로드 후 스테이지에서 관리 해줘야함
function local_class:trailer_setting(marker)
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()
	end

	if type_util.is_array(marker) then
		self.broken_trailer = {}

		for i = 1, #marker do
			local trailer = load_util.load_prefab_async(self.res_holder,
					'ondemand/v2_49_queenship/tilesets', '[gimmick]dw_broken_trailer')
			trailer.transform.localPosition = marker[i].position

			local wall = nil
			if marker[i].direction == CS.Oak.Direction.Up then
				trailer.transform.localRotation = unity_class.quaternion.Euler(0, -90, 0)
				wall = get_field_object('s4_trailer_wall')
				wall.Hitbox = CS.Oak.Hitbox(vector(2, 1, 6))
				wall.Position = marker[i].position + vector(-0.5, 0, 2)
			else
				trailer.transform.localRotation = unity_class.quaternion.Euler(0, 180, 0)
				wall = get_field_object('s2_trailer_wall')
				wall.Hitbox = CS.Oak.Hitbox(vector(6, 1, 2.5))
				wall.Position = marker[i].position + vector(-2.5, 0, -0.25)
			end

			table.insert(self.broken_trailer, { object = trailer, wall = wall })
		end
	end
end

function local_class:dispose_trailer()
	if self.broken_trailer ~= nil then
		for _, trailer in pairs(self.broken_trailer) do
			if not is_unity_null(trailer.object) then
				CS.UnityEngine.GameObject.Destroy(trailer.object)
				trailer.object = nil
			end
		end

		self.broken_trailer = nil
	end
end

function local_class:trailer_move(index, move_time, relative_pos)
	local time_passed = 0
	local start_pos = self.broken_trailer[index].object.transform.localPosition

	local move_pos = {}
	local str_1 = relative_pos:gsub('%s+', "")
	local str_2 = str_1:gsub('%(', "")
	local str_3 = str_2:gsub('%)', "")
	for number_string in string.gmatch(str_3, '[^,]+') do
		table.insert(move_pos, tonumber(number_string))
	end

	move_pos = vector(move_pos[1], move_pos[2], move_pos[3])
	local end_pos = start_pos + move_pos

	local shake_calculator = CS.Oak.ShakeCalculator()
	local shake_info = CS.Oak.ShakeInfo()
	shake_info.magnitude = 0.03
	shake_info.duration = move_time
	shake_info.useUnscaledTime = true

	shake_calculator:Shake(shake_info)

	local move_sfx = music_player_util.play_sfx({ sfx_name = '01_push_rock_01', loop = true })
	while time_passed < move_time do
		shake_calculator:UpdateFrame(unity_class.time.deltaTime)
		time_passed = time_passed + unity_class.time.deltaTime
		self.broken_trailer[index].object.transform.localPosition = vector_util.lerp(start_pos, end_pos, time_passed / move_time) + shake_calculator.ShakeOffset
		coroutine.yield()
	end

	move_sfx:Stop()
	self.broken_trailer[index].object.transform.localPosition = end_pos
	self.broken_trailer[index].wall.Position = self.broken_trailer[index].wall.Position + move_pos
end

function local_class:trailer_shake()
	self.trailer_shake_loop = true

	local shake_calculator = CS.Oak.ShakeCalculator()
	local shake_info = CS.Oak.ShakeInfo()
	shake_info.magnitude = 0.025
	shake_info.duration = 99999
	shake_info.useUnscaledTime = true
	shake_calculator:Shake(shake_info)

	local origin_pos = self.broken_trailer[2].object.transform.localPosition

	while self.trailer_shake_loop do
		shake_calculator:UpdateFrame(unity_class.time.deltaTime)

		self.broken_trailer[2].object.transform.localPosition = origin_pos + shake_calculator.ShakeOffset
		coroutine.yield()
	end

	self.broken_trailer[2].object.transform.localPosition = origin_pos
end

function local_class:trailer_rotate(angle, angle_time)
	local origin_angle = self.broken_trailer[2].object.transform.eulerAngles

	local time_passed = 0
	while time_passed < angle_time do
		time_passed = time_passed + unity_class.time.deltaTime

		-- LerpAngle 안쓰면 한바퀴 돌아버림
		local cur_angle = unity_class.mathf.LerpAngle(origin_angle.x, angle, time_passed / angle_time)
		self.broken_trailer[2].object.transform.localRotation = unity_class.quaternion.Euler(cur_angle, origin_angle.y, 0)
		coroutine.yield()
	end

	self.broken_trailer[2].object.transform.localRotation = unity_class.quaternion.Euler(angle, origin_angle.y, 0)
end
--endregion

--region 비 내리는 이펙트, 사이렌
-- 시작 세팅
function local_class:setting_stage_effect(active)
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()
	end

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'effects/stage/weather', 'fx_env_rain_screen_fx', function(prefab)
				self.rain_screen_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.rain_screen_effect.transform:SetParent(stage_camera.Transform.parent)
				self.rain_screen_effect.transform.localPosition = unity_class.vector3.zero
				self.rain_screen_effect.transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
			end)

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_3_futurecastle/effects/futurecastle', 'fx_futurecastle_rain_ripple_1_1', function(prefab)
				self.rain_ground_effect = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.rain_ground_effect.transform.localPosition = unity_class.vector3.zero
			end)

	self:activate_rain_effect_and_sound(active)
end

function local_class:thunder_loop_routine()
	self.thunder_loop = true
	local time_passed = 0
	while self.thunder_loop do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= 12 then
			self.get_thunder_fx():Instantiate(
					stage_camera.Transform.position, unity_class.quaternion.Euler(45, 0, 0), stage_camera.Transform)

			music_player_util.play_sfx_one_shot('01_thunder_03')
			time_passed = 0
		end

		coroutine.yield()
	end
end

function local_class:activate_rain_effect_and_sound(active)
	if active then
		-- 이펙트 활성화
		self.rain_screen_effect:SetActive(true)
		self.rain_ground_effect:SetActive(true)

		-- 사운드 재생
		self.rain_sfx = music_player_util.play_sfx(
				{ sfx_name = '01_rain_loop_01', loop = true, fade_in_time = 2, type_priority = 'event', player_priority = 'npc' })

		if not self.thunder_loop then
			start_coroutine(self.thunder_loop_routine, self)
		end
	else
		-- 사운드 페이드 아웃
		if self.rain_sfx ~= nil then
			self.rain_sfx:FadeOut(1)
			self.rain_sfx = nil
		end

		-- 이펙트 비활성화
		self.rain_screen_effect:SetActive(false)
		self.rain_ground_effect:SetActive(false)
		self.thunder_loop = false
	end
end

function local_class:dispose_stage_effect()
	if self.rain_screen_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.rain_screen_effect)
		self.rain_screen_effect = nil
	end

	if self.rain_ground_effect ~= nil then
		CS.UnityEngine.Object.Destroy(self.rain_ground_effect)
		self.rain_ground_effect = nil
	end

	if self.rain_sfx ~= nil then
		self.rain_sfx:Stop()
		self.rain_sfx = nil
	end
end

--endregion

--region 랜드마크 처리용
function local_class:landmark_setting()
	local land_mark = get_field_object('broken_landmark')
	local on = land_mark.transform:Find('on').gameObject
	local off = land_mark.transform:Find('off').gameObject
	on:SetActive(false)
	off:SetActive(true)
end
--endregion

--region 시민 관리
--- 3번 시민 세팅
function local_class:setting_trapped_civilian(progress)
	if quest_util.get_custom_state(progress, self.civilian_key .. 3) ~= 1 then
		local civilian = get_character('s2_civilian_3')
		if progress.InnerProgress <= 2 then
			character_util.set_position(civilian, field_util.get_marker_pos('s2_civilian_pos_1_3'))
			character_util.add_listener(civilian, self.cs_controller)
			quest_icon.SetQuestCleared(civilian)
			character_util.set_direction(civilian, 'down')
			scene_util.set_anim_loop(civilian, 'cast')
			scene_util.set_emotion_loop(civilian, 'scared')
		else
			-- 3번 시민을 구출하지 않은 경우
			character_util.set_position(civilian, field_util.get_marker_pos('s2_civilian_pos_1_3'))
			character_util.set_direction(civilian, 'left')
			quest_icon.RemoveIcon(civilian)
			scene_util.set_anim_non_loop(civilian, 'prostrate')
			scene_util.set_emotion_non_loop(civilian, 'damaged')
			character_util.add_color(civilian, civilian.Name, unity_class.color.black, 0.7, 0)
			civilian.Interactable.Talk = 'qs_main_s2_25'
		end
	end
end

--- 갇혀있다 구출되는 3번 시민
function local_class:trapped_civilian()
	local civilian = get_character('s2_civilian_3')
	character_util.remove_relate_event(civilian, self.cs_controller)

	quest_icon.RemoveIcon(civilian)

	character_util.remove_anim_and_emotion(civilian)
	self:join_civilian(3)
	--감사합니다…!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(civilian, { key = 'qs_main_s2_24' })
end

-- 3번 시민을 무시하고 진행했을 경우
function local_class:trapped_civilian_check()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_util.get_custom_state(main_quest_progress, 'stage1_civilian_3') == -1 then
		local civilian = get_character('s2_civilian_3')
		character_util.remove_relate_event(civilian, self.cs_controller)

		character_util.set_direction(civilian, 'left')
		scene_util.set_anim_non_loop(civilian, 'prostrate')
		scene_util.set_emotion_non_loop(civilian, 'damaged')
		character_util.add_color(civilian, civilian.Name, unity_class.color.black, 0.7, 0)
		quest_icon.RemoveIcon(civilian)
		civilian.Interactable.Talk = 'qs_main_s2_25'
	end
end

--- 구출 x custom_state : -1
function local_class:setting_civilian(active)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local civilian_count = 5
	local alive_count = 0

	for i = 1, civilian_count do
		local cur_value = quest_util.get_custom_state(main_quest_progress, self.civilian_key .. i)
		if (cur_value == 1 and active) or (i >= 4 and active) then
			local civilian = get_character('s2_civilian_' .. i)
			character_util.convert_to_following_npc(civilian, user_party)
			character_util.set_position(civilian,
					user_party.Leader.Position - vector(2.1 + alive_count * alive_count, 0, 0))
			alive_count = alive_count + 1
			quest_util.set_custom_state(main_quest_progress, self.civilian_key .. i, 1)
		elseif not active then
			quest_util.set_custom_state(main_quest_progress, self.civilian_key .. i, -1)
		end
	end
end

--- 생존 custom_state : 1
function local_class:join_civilian(index)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local civilian = get_character('s2_civilian_' .. index)

	quest_util.set_custom_state(main_quest_progress, self.civilian_key .. index, 1)

	character_util.convert_to_following_npc(civilian, user_party, true)
end

--- 사망 custom_state : 2
function local_class:dead_civilian(index)
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local civilian = get_character('s2_civilian_' .. index)

	-- 시민 사망 처리
	quest_util.set_custom_state(main_quest_progress, self.civilian_key .. index, 2)

	character_util.convert_to_npc(civilian)
	scene_util.set_emotion_loop(civilian, 'damaged')
	character_util.air_spin(civilian)

	if index == 1 or index == 5 then
		-- 끄악!!
		music_player_util.play_sfx_one_shot('01_villain_scream_03')
		speech_bubble_util.show_speech_bubble(user_party.Leader, { key = 'qs_main_s2_22'
		, world_pos = civilian.Position + vector(0, 1, 0), bubble_type = 'shout' })
	else
		-- 꺄악!
		music_player_util.play_sfx_one_shot('01_linda_scream_01')
		speech_bubble_util.show_speech_bubble(user_party.Leader, { key = 'qs_main_s2_23'
		, world_pos = civilian.Position + vector(0, 1, 0), bubble_type = 'shout' })
	end
end
--endregion

--region futurecastle part2의 폭격 로직 사용
function local_class:load_bombing_range_pool()
	self.bombing_range_pool = {}
	for _ = 1, self.bombing_range_pool_size do
		local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.bombing_radius)
		attack_range.gameObject:SetActive(false)
		table.insert(self.bombing_range_pool, attack_range)
	end
end

function local_class:get_bombing_range()
	for i = 1, #self.bombing_range_pool do
		local attack_range = self.bombing_range_pool[i]
		if attack_range.gameObject.activeSelf == false then
			attack_range.gameObject:SetActive(true)
			return attack_range
		end
	end

	-- 풀에서 전부 끌어다 썼을 때
	local new_attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.bombing_radius)
	table.insert(self.bombing_range_pool, new_attack_range)

	return new_attack_range
end

function local_class:dispose_bombing_range(range)
	range.gameObject:SetActive(false)
end

function local_class:bomb_fall(target_pos, delay, move_time, shake)
	local shake_power = lua_helper.get_or_default(shake, 0.15)
	local end_pos = {}

	if type_util.is_string(target_pos) then
		local str_1 = target_pos:gsub('%s+', '')
		local str_2 = str_1:gsub('%(', '')
		local str_3 = str_2:gsub('%)', '')
		for number_string in string.gmatch(str_3, '[^,]+') do
			table.insert(end_pos, tonumber(number_string))
		end

		end_pos = vector(end_pos[1], end_pos[2], end_pos[3])
	else
		end_pos = target_pos
	end

	local start_pos = end_pos + vector(0, 15, 0)

	local attack_range = self:get_bombing_range()
	attack_range.transform.position = vector_util.get_x0z(end_pos, end_pos.y + 0.1)
	attack_range:Show()

	local time_passed = 0
	while time_passed < delay and self.missile_active do
		time_passed = time_passed + unity_class.time.deltaTime
		coroutine.yield()
	end

	time_passed = 0
	local missile_effect = self.get_fx_darkmagic_missile():Instantiate(start_pos)

	music_player_util.play_sfx({ sfx_name = '02_dark_magician_shoot_01', play_pos = end_pos })

	while time_passed < move_time and self.missile_active do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = unity_class.mathf.Clamp01(time_passed / move_time)

		missile_effect.transform.position = unity_class.vector3.Lerp(start_pos, end_pos, progress)
		coroutine.yield()
	end

	missile_effect:Dispose()
	self:dispose_bombing_range(attack_range)

	music_player_util.play_sfx({ sfx_name = '02_hit_dark_01', play_pos = end_pos })
	music_player_util.play_sfx({ sfx_name = '02_explosion_kick_02', play_pos = end_pos })

	if not screen_util.is_fo_in_screen(end_pos, { bonus_distance = 3 }) then
		return
	end

	local explosion_effect = self.get_fx_darkmagic_missile_explosion():Instantiate(end_pos)

	explosion_effect.transform.localScale = unity_class.vector3.one * 1.5
	camera_util.shake(shake_power, 0.2)

	-- 리더가 Screenplay 상태일 경우 제외
	if lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) then
		return
	end

	local hits = field:GetFieldObjectsInCylinder(end_pos, self.bombing_radius, 3)
	local dmg_multiplier = CS.Oak.ConstantsData.Value.GimmickDefaultDamage:GetDecrypted()

	for i = 0, hits.Count - 1 do
		local fo = hits.Values[i]
		if lua_helper.type_compare(fo, CS.Oak.Character) then
			if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
				-- 리더가 맞은 경우
				if lua_helper.reference_equals(fo, user_party.Leader) then
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
					damage_info.target = fo
					damage_info.sender = user_party.Leader
					damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * dmg_multiplier)
					damage_info.notMortal = true

					local cmd = CS.Oak.DamageCommand.Create(damage_info)
					command_util.publish_cmd(CS.Oak.Player.Local, cmd)
				end

				-- 특정 시민이 맞았을 경우 사망 처리
				local civilian_count = 5
				for j = 1, civilian_count do
					local civilian = get_character('s2_civilian_' .. j)
					if lua_helper.reference_equals(fo, civilian) then
						self:dead_civilian(j)
					end
				end
			end
		else
			-- Breakable등의 데미지를 입는 오브젝트일 때
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
			damage_info.target = fo
			damage_info.sender = user_party.Leader
			damage_info.damage = 10000

			local cmd = CS.Oak.DamageCommand.Create(damage_info)
			command_util.publish_cmd(CS.Oak.Player.Local, cmd)
		end
	end

	hits:Dispose()
end

function local_class:wall_missile_setting()
	for i = 1, self.wall_missile_zone_count do
		self.wall_missile_points[i] = {}
		for j = 1, self.wall_marker_count[i] do
			table.insert(self.wall_missile_points[i],
					field_util.get_marker_pos(self.wall_missile_marker_name .. i .. '_' .. j))
		end
	end
end

function local_class:wall_missile_routine(zone_index)
	self.wall_missile_req_cnt = self.wall_missile_req_cnt + 1
	local req_cnt = self.wall_missile_req_cnt

	local time_passed = 0
	local missile_delay = 8 / self.wall_marker_count[zone_index]

	while req_cnt == self.wall_missile_req_cnt do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= missile_delay then
			time_passed = 0

			if not lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
					CS.Oak.CharacterControllerScreenplayState) then
				local rand_index = random_util.get_random_int(1, #self.wall_missile_points[zone_index])
				self:bomb_fall(self.wall_missile_points[zone_index][rand_index], 0, 1)
			end
		end

		coroutine.yield()
	end
end
--endregion

function local_class:rooftop_move_event()
	party_util.stop_and_disable_control()

	music_player_util.play_sfx_one_shot('01_walk_02')
	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	screen_util.fade_out_circular_async(0.6, 'linear')
	field_ui_manager:Hide()

	party_util.position_party(field_util.get_marker_pos('airraid_rooftop'), 'up', 'linear')
	wait_for_sec(0.1)

	field.RooftopManager:ForceVisible(false)

	screen_util.fade_in_circular_async(0.6, 'linear')
	party_util.reset_controllers()
	field_ui_manager:Show()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
