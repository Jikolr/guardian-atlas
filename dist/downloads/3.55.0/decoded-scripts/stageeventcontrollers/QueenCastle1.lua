local local_class = newclass('QueenCastle1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 기사 가져오기
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	self.get_guard_worker = function(index)
		return get_character('guard_android_' .. index)
	end

	self.get_riri_event_worker = function(index)
		return get_character('riri_event_worker_' .. index)
	end

	self.get_fx_smoke = function()
		return unity_object_pool.GetOrCreate('fx_event_smokescreen')
	end

	-- 리리 석상 관련
	self.get_statue_riri = function() return get_field_object('statue_riri') end
	self.get_statue_riri_pos = function() return field_util.get_marker_pos('statue_riri_pos') end
	self.statue_riri_star_piece_name = 'statue_riri_star_piece'
	self.statue_riri_star_piece_effect = nil
	self.is_get_riri_star_piece = false
	self.is_zone_enter_riri_star_piece_zone = true

	self.get_shear_controller = function() return get_field_object('shear_controller') end
	self.shear_controller = nil
	self.default_shear_value = 0.03

	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end
	self.get_fx_star_piece_in_character = function() return unity_object_pool.GetOrCreate('FX_starpiece_in_character') end
	self.get_fx_magic_circle = function() return unity_object_pool.GetOrCreate('MagicCircle_AppearIdle') end
	self.stage_exit_name = 'exit_queencastle_1_8'

	self.exit_magic_circle = nil

	-- 메인 퀘스트 id
	self.main_quest_id = 330

	self.is_stage_exit = false

	self.last_leave_grid_name = nil

	self.is_detected = false
end

function local_class:load_resource()
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
	return false
end

function local_class:on_stage_start_event(_)
end

function local_class:on_stage_end_event(_)
	self.is_stage_exit = true
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()
	if type_util.is_zone_full_enter(e, leader, 's3_auto_event_zone_5')
			and not self.is_zone_enter_riri_star_piece_zone then
		-- 안드로이드 5 : 이 석상을 부수기 전까지는 퇴근할 수 없습니다…
		self.is_zone_enter_riri_star_piece_zone = true
		local carpenter = self.get_riri_event_worker(1)
		speech_bubble_util.show_speech_bubble(carpenter, { key = 'qc_incinerator_s1_14' })
		return true
	end

	if type_util.is_zone_full_enter(e, leader, 's10_stage_end_zone') and
			self.exit_magic_circle ~= nil then
		sp_util.start_scene(function()
			-- 스테이지 클리어
			screen_util.fade_out_circular_async(1, 'linear')
			screen_util.fade_out_async(0, unity_class.color.black, 'linear')
			CS.Oak.TeleportPartyStageLogic.Execute(self.stage_exit_name, 'queencastle_1_8', nil, true)
		end)
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 's10_event_grid')
			and self.shear_controller ~= nil then
		self.shear_controller.Shear = 0
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	self.last_leave_grid_name = e.CameraGrid.name
	if type_util.is_player_leave_to_cam_grid(e, 'magnet_grid') then
		local magnet_count = 2
		for i = 1, magnet_count do
			local holdable_magnet = get_field_object('holdable_magnet_' .. i)
			message_system:Send(holdable_magnet.FieldObjectBehaviour, CS.Oak.GimmickResetEvent.Instance)
		end

		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 's10_event_grid')
			and self.shear_controller ~= nil then
		self.shear_controller.Shear = self.default_shear_value
		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 'check_grid_4') then
		local tesla_count = 2
		for i = 1, tesla_count do
			local telsa = get_field_object('start_point_telsa_' .. i)
			message_system:Send(telsa, CS.Oak.GimmickResetEvent.Instance)
		end
		return true
	elseif type_util.is_player_leave_to_cam_grid(e, 'tesla_grid') then
		local telsa = get_field_object('s3_tesla_1')
		message_system:Send(telsa, CS.Oak.GimmickResetEvent.Instance)
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if self.is_detected then
		return false
	end

	local count = 6
	for i = 1, count do
		local event_name = 's10_detected_point_' .. i
		if e:GetParamAt(0) == event_name then
			self.is_detected = true
			start_coroutine(self.on_detected_with_watcher, self, e.Sender, event_name, event_name)
			return true
		end
	end

	count = 7
	for i = 1, count do
		local event_name = 'detected_point_' .. i
		if e:GetParamAt(0) == event_name then
			self.is_detected = true
			local reset_point_name = self:get_detected_point(event_name, i)
			start_coroutine(self.on_detected_with_watcher, self, e.Sender, reset_point_name, event_name)
			return true
		end
	end

	return false
end

function local_class:on_move_by_magnet_notice_event(e)
	local worker_count = 12
	for i = 1, worker_count do
		local guard_android = get_character('s10_guard_android_' .. i)
		if guard_android ~= nil and lua_helper.reference_equals(e.Target, guard_android) then
			self:convert_holdable_android(guard_android)
			return true
		end
	end

	worker_count = 16
	for i = 1, worker_count do
		local guard_android = self.get_guard_worker(i)
		if lua_helper.reference_equals(e.Target, guard_android) then
			self:convert_holdable_android(guard_android)
			return true
		end
	end

	return false
end

function local_class:on_damage_event(e)
	local worker_count = 12
	for i = 1, worker_count do
		local guard_android = get_character('s10_guard_android_' .. i)
		if guard_android ~= nil and lua_helper.reference_equals(e.Info.target, guard_android) then
			local require_damage_type = CS.Oak.DamageType.Assassinate | CS.Oak.DamageType.Melee
			if e.Info.type & require_damage_type == require_damage_type then
				start_coroutine(self.convert_monster_holdable, self, guard_android)
				return true
			end
		end
	end

	worker_count = 16
	for i = 1, worker_count do
		local guard_android = self.get_guard_worker(i)
		if lua_helper.reference_equals(e.Info.target, guard_android) then
			local require_damage_type = CS.Oak.DamageType.Assassinate | CS.Oak.DamageType.Melee
			if e.Info.type & require_damage_type == require_damage_type then
				start_coroutine(self.convert_monster_holdable, self, guard_android)
				return true
			end
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	local statue_riri = self.get_statue_riri()
	if lua_helper.reference_equals(e.FieldObject, statue_riri) then
		self.get_fx_smoke():Instantiate(statue_riri.Position + vector(0.5, 0, 0.25))
		start_coroutine(self.drop_riri_star_piece, self)
		return true
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveByMagnetNoticeEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	self:dispose_riri_star_piece_effect()

	if self.exit_magic_circle ~= nil then
		self.exit_magic_circle:Dispose()
		self.exit_magic_circle = nil
	end

	self.shear_controller = nil

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveByMagnetNoticeEvent), 'on_move_by_magnet_notice_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.get_fx_hit()
	self.get_fx_star_piece_in_character()
	self.get_fx_smoke()
	self.get_fx_magic_circle()
	unity_object_pool.GetOrCreate('FX_Env_BigRock_lv1_destroy')
	yield_return(unity_object_pool, 'WaitAll')

	self.shear_controller = self.get_shear_controller():GetComponent(typeof(CS.Oak.ShearController))
	self.default_shear_value = self.shear_controller.Shear

	if main_quest_progress ~= nil and (main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 10) then
		self.exit_magic_circle = self.get_fx_magic_circle():Instantiate(
				field_util.get_marker_pos('s10_magic_circle_pos'))
	end

	local holdable_wall_count = 9
	for i = 1, holdable_wall_count do
		local wall = get_field_object('holdable_wall_' .. i)
		wall.EntityGroup = CS.Oak.EntityGroups.Obstacle
	end

	-- 리리 석상 이벤트 세팅
	self:set_statue_riri_event(main_quest_progress)

	if main_quest_progress ~= nil and (main_quest_progress.IsComplete or main_quest_progress.InnerProgress >= 9) then
		self:set_guard_worker(main_quest_progress.InnerProgress)
	end

	-- 마계 라이트 disabled
	local demonworld_light = get_field_object('demonworld_light')
	demonworld_light.ActiveState = active_state('disabled')

	-- 시작 연출 관리
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress < 2 then
		-- 1,2,3 섹션은 섹션에서 컨트롤
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('s3_start_pos_1').position, false, false)
	elseif main_quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('s4_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('up', field:GetMarker('s5_start_pos_1').position, false, false)
	elseif main_quest_progress.InnerProgress == 9 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('s5_start').position, false, false)
	else
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	end
end

--region 리리 석상 관련

function local_class:set_statue_riri_event(main_quest_progress)
	self.is_get_riri_star_piece = star_piece_util.has_star_piece(self.statue_riri_star_piece_name)

	if self.is_get_riri_star_piece then
		return
	end

	local statue_riri = self.get_statue_riri()
	statue_riri.Position = self.get_statue_riri_pos()
	self.statue_riri_star_piece_effect = self.get_fx_star_piece_in_character():Instantiate(statue_riri.Position + vector(0.5, 1, 0))

	if main_quest_progress ~= nil and main_quest_progress.InnerProgress >= 9 then
		self.is_zone_enter_riri_star_piece_zone = false
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
		statue_riri.DamagedBehaviour = CS.Oak.RockDamagedBehaviour()
		statue_riri.DamagedBehaviour.RockBreakFxAsset = 'FX_Env_BigRock_lv1_destroy'
		start_coroutine(self.carpenter_hammer_routine, self)
	end
end

function local_class:carpenter_hammer_routine()
	local leader = get_party_leader()

	local carpenter_1 = self.get_riri_event_worker(1)
	character_util.set_active_state(carpenter_1, 'enabled')
	character_util.set_anim(carpenter_1, { name = 'carpenter_hammer', scale = 1.1 })

	-- 0.2초 딜레이
	wait_for_sec(0.2)

	local carpenter_2 = self.get_riri_event_worker(2)
	character_util.set_active_state(carpenter_2, 'enabled')
	character_util.set_anim(carpenter_2, { name = 'carpenter_hammer', scale = 1.1 })

	while not self.is_stage_exit and not self.is_get_riri_star_piece do
		wait_for_sec(0.3)
		if self.is_stage_exit or self.is_get_riri_star_piece then
			break
		end

		local dir_vector = direction_util.to_vector3_ver2(carpenter_1.Direction)
		local dist = vector_util.distance(leader.Position, carpenter_1.Position)
		if dist < 10 then
			local effect_pos = carpenter_1.Position + vector(dir_vector.x * 0.4, 0.3, dir_vector.z * 0.4)
			self.get_fx_hit():Instantiate(effect_pos)
			music_player_util.play_sfx({ sfx_name = '01_mining_01', parent = carpenter_1, volume = 0.1 })
		end

		wait_for_sec(0.2)
		if self.is_stage_exit or self.is_get_riri_star_piece then
			break
		end

		dir_vector = direction_util.to_vector3_ver2(carpenter_2.Direction)
		dist = vector_util.distance(leader.Position, carpenter_2.Position)
		if dist < 10 then
			local effect_pos = carpenter_2.Position + vector(dir_vector.x * 0.4, 0.3, dir_vector.z * 0.4)
			self.get_fx_hit():Instantiate(effect_pos)
			music_player_util.play_sfx({ sfx_name = '01_mining_01', parent = carpenter_2, volume = 0.1 })
		end
	end
end

function local_class:drop_riri_star_piece()
	self.is_get_riri_star_piece = true
	coroutine.yield(nil)

	local carpenter_list = {}
	local carpenter_count = 2
	for i = 1, carpenter_count do
		local carpenter = self.get_riri_event_worker(i)
		character_util.remove_anim_and_emotion(carpenter)
		speech_bubble_util.remove_bubble(carpenter)
		scene_util.set_emotion(carpenter, self, 'surprise')
		character_util.normal_jump(carpenter, true)
		table.insert(carpenter_list, carpenter)
	end

	-- 석상 파괴됨과 동시에 석상에서 스타피스 위 그림 위치로 나옴
	-- 석상 파괴되면 이벤트 (멈추지 않음)
	self:dispose_riri_star_piece_effect()
	local star_piece = get_field_object(self.statue_riri_star_piece_name)
	local start_pos = self.get_statue_riri_pos() + vector(0.5, 0, 0)
	star_piece_util.appear(star_piece, start_pos, start_pos - vector(2, 0, 0))
	wait_for_sec(3)

	-- 안드로이드 5, 6 (left, smile, victory_extra)
	for i = 1, #carpenter_list do
		character_util.remove_anim_and_emotion(carpenter_list[i])
		character_util.set_anim_and_emotion(carpenter_list[i], { name = 'victory_extra' }
		, { name = 'smile' })
	end

	-- 안드로이드 6 (left, smile, victory_extra) : 신난다! 퇴근이야!!
	music_player_util.play_sfx({ sfx_name = '01_coop_mvp_01', parent = carpenter_list[#carpenter_list]
	, type_priority = 'event', player_priority = 'npc' })
	scene_util.show_normal_speech_async(carpenter_list[#carpenter_list], 'qc_incinerator_s1_13', false)

	for i = 1, #carpenter_list do
		character_util.remove_anim(carpenter_list[i])
	end

	-- 안드로이드 5, 6 속도 3으로 우측으로 1칸 이동
	wp_util.move(carpenter_list[1], carpenter_list[1].Position + vector(1, 0, 0)
	, 3, nil)
	wp_util.move_async(carpenter_list[#carpenter_list]
	, carpenter_list[#carpenter_list].Position + vector(1, 0, 0), 3, nil)

	-- 안드로이드 5, 6 (right, tired, sleep)
	music_player_util.play_sfx({ sfx_name = '01_hit_npc_01', parent = carpenter_list[#carpenter_list]
	, type_priority = 'event', player_priority = 'npc' })
	for i = 1, #carpenter_list do
		scene_util.set_direction(carpenter_list[i], 'right', false)
		character_util.remove_anim_and_emotion(carpenter_list[i])
		character_util.set_anim_and_emotion(carpenter_list[i], { name = 'sleep' }
		, { name = 'tired' })
	end
end

function local_class:dispose_riri_star_piece_effect()
	if self.statue_riri_star_piece_effect ~= nil then
		self.statue_riri_star_piece_effect:Dispose()
		self.statue_riri_star_piece_effect = nil
	end
end

--endregion

--region 10섹션부터 활성화되는 안드로이드 세팅

function local_class:set_guard_worker(progress)
	-- 10섹션에는 추가 배치
	if progress == 9 then
		local worker_count = 12
		for i = 1, worker_count do
			local guard_android = get_character('s10_guard_android_' .. i)
			self:assassinate_enable(guard_android)
			character_util.set_active_state(guard_android, 'enabled')
			message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(guard_android, true))
			message_system:SendSync(guard_android, CS.Oak.StateResetEvent.Instance)
		end
	end

	local worker_count = 16
	for i = 1, worker_count do
		local guard_android = self.get_guard_worker(i)
		self:assassinate_enable(guard_android)
		character_util.set_active_state(guard_android, 'enabled')
		message_system:Publish(CS.Oak.FieldUITopHPBarIgnoreTargetEvent.Create(guard_android, true))
		message_system:SendSync(guard_android, CS.Oak.StateResetEvent.Instance)
	end
end

function local_class:get_detected_point(event_name, index)
	if index == 2 then
		if self.last_leave_grid_name == 'check_grid_5' then
			return 'detected_point_2_1'
		else
			return 'detected_point_2_2'
		end
	elseif index == 3 then
		if self.last_leave_grid_name == 'magnet_grid' then
			return 'detected_point_3_2'
		elseif self.last_leave_grid_name == 'check_grid_1' then
			return 'detected_point_3_3'
		else
			return 'detected_point_3_1'
		end
	elseif index == 4 then
		if self.last_leave_grid_name == 'check_grid_3' then
			return 'detected_point_4_2'
		else
			return 'detected_point_4_1'
		end
	end

	return event_name
end

function local_class:on_detected_with_watcher(watcher, reset_point_name, event_name)
	local leader = get_party_leader()

	-- 암살중일 수도 있으니 끝날 때까지 대기
	while lua_helper.type_compare(leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterAssassinateState) do
		coroutine.yield(nil)
	end

	sp_util.enter_scene()

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	music_player_util.play_sfx_one_shot('03_dialogue_worker_02')
	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.look_at(watcher)
	party_util.set_emotion({ name = 'surprise' })
	party_util.set_anim({ name = 'embarrassed' })
	party_util.jump(0.5, 0.3)

	scene_util.set_emotion(watcher, self, 'mad')
	scene_util.set_anim(watcher, self, 'release')
	scene_util.show_shout_speech_async(watcher, 'qc_android_lab_s1_23')

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 파티 리셋 세팅
	party_util.remove_emotion()
	party_util.remove_animation()
	character_util.remove_anim_and_emotion(watcher)

	local reset_pos = field_util.get_marker_pos(reset_point_name)
	character_util.set_position(leader, reset_pos)
	party_util.align_party(reset_pos, field_util.get_marker_dir(reset_point_name), 0, 'linear')

	coroutine.yield(nil)

	-- 순찰 패트롤 좌표랑 상태 다 리셋 시키도록
	message_system:Publish(CS.Oak.CustomStageEvent.Create(leader, { 'reset', event_name }))

	coroutine.yield(nil)

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	self.is_detected = false

	sp_util.exit_scene(nil, leader)
end

function local_class:convert_monster_holdable(monster)
	wait_for_sec(0.2)
	self:convert_holdable_android(monster)

	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = monster
	heal_info.target = monster
	heal_info.heal = monster.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true
	heal_info.skipEffect = true

	command_util.execute_heal(heal_info)
end

function local_class:assassinate_enable(character)
	character.EntityGroup = CS.Oak.EntityGroups.Enemy0
	character.DamagedBehaviour = CS.Oak.MonsterAssassinateDamagedBehaviour.Create()
	character.DamagedBehaviour.ShowDamageNumber = false
	character.DamagedBehaviour.ApplyOtherDamage = false
	character.DamagedBehaviour.ApplyBombDamage = false
	character.DamagedBehaviour.DeathType = CS.Oak.DeathType.Prostrate
end

function local_class:convert_holdable_android(android)
	character_util.stop(android)
	character_util.remove_anim_and_emotion(android)
	character_util.set_anim(android, { name = 'prostrate' })

	android.EntityGroup = CS.Oak.EntityGroups.Neutral0
	android.OverrideCrashBehaviour = CS.Oak.MetalNPCCrashBehaviour.Instance
	android.DamagedBehaviour = CS.Oak.NPCCharacterDamagedBehaviour.Create()
	android.Holdable = CS.Oak.Holdable()
end

--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
