local local_class = newclass("NightmareFutureCastle2At4Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- 란팡방 레지스탕스
	self.get_ranpang_resistance = function() return get_character('ranpang_traphole_resistance') end

	self.hole_name = 'ranpang_traphole_'
	self.bomb_name = 'ranpang_trap_bomb_1'
	self.bomb_pos_name = 'ranpang_bomb_drop'
	self.switch_name = 'ranpang_trap_switch_'
	self.spike_name = 'ranpang_trap_spike_'
	self.cracked_wall_name = 'ranpang_cracked_wall'
	self.on_trap_event = false

	self.trap_holes = nil
	self.trap_respawn_pos = vector(40, 0, 90)
	self.spike_lower = 112
	self.spike_upper = 115

	self.is_bomb_active = false
	self.is_spike_active = false
	self.spike_reset_call = false

	self.spike_push_speed = 7
	self.spike_pull_speed = 3

	self.seen_trapped_talk = false

	self.opts = nil
	self.free_fall = nil
	-- 마법진으로 워프 중인지 저장
	self.warp_magiccircle = false

	-- marker name
	self.magiccircle_out_marker_name = '_out'

	self.magiccircle_count = 6
	self.magiccircle_zone_name = 'magiccircle_'

	-- 마법진 이펙트 리스트
	self.magiccircle_effect_list = nil

	--region 런닝머신 발전기를 테스트 하는 소히
	-- 러닝머신 카매라 그리드 이름
	self.running_machine_grid = 'running_machine_grid'

	self.sohee_zone_name = 'sohee_zone'

	self.sohee_event_seen = false

	-- 스테이지 내에 있는 모든 컨베이어 밸트 담는 테이블

	self.belts = {}

	-- belts 테이블 검색에서 string 대신 idx로 검색하기 위한 용도
	self.belts_enum = {
		-- belt fo
		fo = 1,
		-- belt의 animator component
		anim = 2,
		-- belt의 sfx_holder
		sfx_holder = 3
	}

	-- sfx가 있는 원라인 대사 npc들을 캐싱
	self.sfx_online_talker = {
		running_machine_2 = {
			speech = 'nightmare_futurecastle_2_threadmill_generator_test_oneline_2',
			sfx = '03_dialogue_emphasize_01',
			sfx_holder = nil
		},
		running_machine_3 = {
			speech = 'nightmare_futurecastle_2_threadmill_generator_test_oneline_3',
			sfx = '03_dialogue_sadness_01',
			sfx_holder = nil
		}
	}

	-- 벨트 마지막 인덱스
	self.belt_num = 6
	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_minotaur_buttbounce')
	unity_object_pool.GetOrCreate('FX_Common_SmokeScreen')
	unity_object_pool.GetOrCreate('MagicCircle_AppearIdle')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.opts = load_util.create_optimized_npcs_async({
		victim_1 = 'nightmare_future2_resistance_male',
	})
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
		return true
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_loaded()
	--- 구멍 함정
	self.trap_holes = {}
	for i = 1, 3 do
		self.trap_holes[i] = {
			index = i,
			fo = get_field_object(self.hole_name .. i),
			marker = field:GetMarker(self.hole_name .. i),
			mats = {},
			item = nil,
		}
		if i > 1 then
			table.insert(self.trap_holes[i].mats, get_field_object('trap_mat_' .. (i - 1) * 2 - 1))
			table.insert(self.trap_holes[i].mats, get_field_object('trap_mat_' .. (i - 1) * 2))
		end
	end
	self.trap_holes[2].item = CS.Oak.DropGold.Create(self.trap_holes[2].marker.position, 0, false, 0, CS.Oak.DropGold.LootState.DontFindLooter)
	self.trap_holes[3].item = drop_item_util.create_item({
		pos = self.trap_holes[3].marker.position, itemid = 20280, notforinven = true, lootstate = 'dontfindlooter'
	})

	local victim = self.opts['victim_1']
	character_util.set_direction(victim, 'left')
	character_util.set_anim_and_emotion(victim, { name = 'prostrate', loop = false }, { name = 'damaged' })
	character_util.set_position(victim, self.trap_holes[1].marker.position + vector(0.1, 0, -0.72))
	character_util.set_scale_factor(victim, 'dead_in_trap', 0.65)
	victim.SpineController:AddColor('dead_in_trap', unity_color({ 0.4, 0.4, 0.4, 1 }), 1, 0)
	field_ui_manager:RemoveUI(victim, CS.Oak.FieldUiType.CharacterStats)

	self.trap_respawn_pos = field:GetMarker('ranpang_trap_respawn').position

	--- 폭탄 함정
	self.cracked_wall = get_field_object(self.cracked_wall_name)

	self.spike_switch = get_field_object(self.switch_name .. 1)
	self.bomb_switch = get_field_object(self.switch_name .. 2)
	self.bomb_barrel = get_field_object(self.bomb_name)

	local bounce_cb = function(bounce)
		if bounce == 1 then
			message_system:Send(self.bomb_barrel.FieldObjectBehaviour, CS.Oak.BombProvokeEvent.Create(self.bomb_barrel, CS.Oak.BombProvokeType.Fire))
		end
	end

	self.bomb_pos = field:GetMarker(self.bomb_pos_name).position
	self.free_fall = CS.CalculatorFreeFall.Create(-5, CS.Oak.Constants.JumpGravity * 3, 10, 1, bounce_cb)
	self.free_fall:SetElasticity(0.2)

	self.spikes = {}
	for i = 1, 4 do
		self.spikes[i] = get_field_object(self.spike_name .. i)
	end

	self.spike_lower = field:GetMarker(self.spike_name .. 'lower').position.z
	self.spike_upper = field:GetMarker(self.spike_name .. 'upper').position.z

	if stage_progress:GetNamedData(self.cracked_wall_name) then
		self:destroy_cracked_wall(false)
	end

	--region 런닝머신 발전기를 테스트 하는 소히
	for i = 1, self.belt_num do
		local belt = get_field_object('belt_' .. i)

		if belt ~= nil then
			local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
			if animator ~= nil then
				-- anim 까지 캐싱해서 사용하도록
				table.insert(self.belts, { belt, animator, nil })
			end
		end
	end

	for k, _ in pairs(self.sfx_online_talker) do
		local character = get_character(k)
		if character ~= nil then
			character_util.add_listener(character, self)
		end
	end
	--endregion

	-- 란팡 함정 레지스탕스
	local resistance = self.get_ranpang_resistance()
	character_util.add_listener(resistance, self)
end

function local_class:on_stage_start_event(e)
	-- 마법진 설정
	self.magiccircle_effect_list = {}

	for i = 1, self.magiccircle_count do
		local center = field:GetZone(self.magiccircle_zone_name .. i).Bounds.center + vector(0, -0.5, 0)
		local cur_magiccircle = unity_object_pool.GetOrCreate('MagicCircle_AppearIdle'):Instantiate(center)
		cur_magiccircle.transform.localScale = unity_class.vector3.one * 0.7

		table.insert(self.magiccircle_effect_list, cur_magiccircle)
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then
		return
	end
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		return
	end
	local zone_name = e.Zone.Name

	for i = 1, self.magiccircle_count do
		if zone_name == self.magiccircle_zone_name .. i and not self.warp_magiccircle then
			self.warp_magiccircle = true
			sp_util.play_normal_screenplay(self.enter_magiccircle_event, self, zone_name)
			return true
		end
	end

	if not self.on_trap_event then
		for i = 1, 3 do
			if zone_name == self.hole_name .. i then
				self.on_trap_event = true
				self.seen_trapped_talk = false
				sp_util.play_normal_screenplay(self.falling_trap, self, i)
				return true
			end
		end
	end

	if not self.sohee_event_seen then
		if zone_name == self.sohee_zone_name then
			self.sohee_event_seen = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.sohee_event, self))
		end
	end

	if not self.seen_trapped_talk and zone_name == 'ranpang_traphole_entrance' then
		self.seen_trapped_talk = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.ranpang_traphole_event, self))
		return true
	end
	return false
end

function local_class:on_switch_on_off_event(e)

	if e.IsTurningOn and lua_helper.reference_equals(e.SwitchObject, self.bomb_switch) and not self.is_bomb_active then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.bomb_drop, self))
	elseif e.IsTurningOn and lua_helper.reference_equals(e.SwitchObject, self.spike_switch)
			and not lua_helper.reference_equals(e.Stepper, self.spikes[4]) then
		if self.is_spike_active then
			self.spike_reset_call = true
		end
		--if self.is_spike_active then return false end
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.reset_spike, self))
		return true
	end
	return false
end

function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.bomb_barrel) and self.is_bomb_active then
		self.is_bomb_active = false
	end
end

function local_class:on_damage_event(e)
	local require_damage_type = CS.Oak.DamageType.Explosion

	if not stage_progress:GetNamedData(self.cracked_wall_name) and
			lua_helper.reference_equals(e.Info.target, self.cracked_wall) then
		if e.Info.type & require_damage_type == require_damage_type then
			--self:destroy_cracked_wall(true)
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.destroy_cracked_wall, self, true))
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.running_machine_grid) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.toggle_belt_anim, self, true))
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.running_machine_grid) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.toggle_belt_anim, self, false))
	end
end

function local_class:on_interact_event(e)
	local target_name = e.Target.Name

	if self.sfx_online_talker[target_name] ~= nil then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.online_talk_with_sfx, self, target_name))
		return true
	end

	local resistance = self.get_ranpang_resistance()
	if lua_helper.reference_equals(e.Target, resistance) then
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		speech_bubble_util.show_speech_bubble(resistance, { key = 'nightmare_futurecastle_2_ranpang_trapped_2' })
		return true
	end

	return false
end

--endregion

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:ranpang_traphole_event()
	local first_key = 'nightmare_futurecastle_2_ranpang_trapped_'
	local resistance = self.get_ranpang_resistance()

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble(self.opts['victim_1'], { key = first_key .. 1, life_time = 1.5 })
	wait_for_sec(1.5)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble(resistance, { key = first_key .. 2 })
end

--region Magic Circle
-- 마법진 진입 이벤트
function local_class:enter_magiccircle_event(zone_name)
	local center = field:GetZone(zone_name).Bounds.center + vector(0, -0.5, 0)

	local out_marker_name = zone_name .. self.magiccircle_out_marker_name
	local out_marker = field:GetMarker(out_marker_name)

	self.warp_magiccircle = true

	local diff_1 = user_party.Leader.Position - center

	character_util.spine_set_alpha_fade(user_party.Leader, 0, 0.5)

	wait_for_sec(0.2)

	music_player_util.play_sfx({ sfx_name = '02_cast_magic_02', type_priority = 'event', player_priority = 'object' })

	screen_util.fade_out_async(0.5, unity_class.color.white, 'linear')

	character_util.set_position(user_party.Leader, out_marker.position + diff_1)

	wait_for_sec(0.5)

	character_util.spine_set_alpha_fade(user_party.Leader, 1, 0.5)

	screen_util.fade_in_async(0.5, unity_class.color.white, 'linear')

	self.warp_magiccircle = false
end
--endregion

--region 런닝머신 발전기를 테스트 하는 소히
-- 컨베이어 벨트 애니메이션 투글
function local_class:toggle_belt_anim(run_anim)
	local belts = self.belts
	local end_idx = self.belt_num
	local belts_enum = self.belts_enum

	for i = 1, end_idx do
		local belt = belts[i]
		local animator = belt[belts_enum.anim]
		local sfx_holder = belt[belts_enum.sfx_holder]

		if animator ~= nil then
			animator.enabled = run_anim

			if run_anim == true then
				animator.speed = 2.5
				animator:Play('xmas_belt_rolling')

				if sfx_holder == nil then
					sfx_holder = music_player_util.play_sfx({ sfx_name = '01_belt_01', type_priority = 'loop',
					                                          player_priority = 'npc', loop = true, parent = belt[belts_enum.fo] })
				end
			else
				if sfx_holder ~= nil then
					sfx_holder:Stop()
					sfx_holder = nil
				end
			end
		end
	end
end
--endregion

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.opts ~= nil then
		load_util.dispose_optimized_npcs(self.opts)
		self.opts = nil
	end

	self.trap_holes = nil

	if self.magiccircle_effect_list ~= nil then
		for _, effect in ipairs(self.magiccircle_effect_list) do
			effect:Dispose()
		end
		self.magiccircle_effect_list = nil
	end

	for k, _ in pairs(self.sfx_online_talker) do
		local character = get_character(k)
		if character ~= nil then
			character_util.remove_relate_event(character, self)
		end
	end

	local resistance = self.get_ranpang_resistance()
	character_util.remove_relate_event(resistance, self)

	if self.free_fall ~= nil then
		self.free_fall:Dispose()
		self.free_fall = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:falling_trap(index)
	local smoke = nil

	if index > 1 then
		music_player_util.play_sfx_one_shot('02_explosion_01')
		smoke = unity_object_pool.GetOrCreate('FX_Common_SmokeScreen'):Instantiate(self.trap_holes[index].marker.position + vector(0, 0.1, 0))

		wait_for_sec(0.5)

		self.trap_holes[index].item.Position = vector(999, 0, 999)
		for _, mat in ipairs(self.trap_holes[index].mats) do
			mat.ActiveState = active_state('disabled')
		end

	end

	character_util.set_direction(user_party.Leader, 'down')
	music_player_util.play_sfx_one_shot('03_runaway_01')
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'cliff' }, { name = 'surprise' })
	character_util.set_active_shadow(user_party.Leader, false)
	wait_for_sec(1.25)

	music_player_util.play_sfx_one_shot('01_fall_down_01')
	character_util.set_anim_and_emotion(user_party.Leader, { name = 'get' }, { name = 'damaged' })

	user_party.Leader:SetScale(unity_class.vector3.one * 0.2, 1)
	user_party.Leader:SetRotation(720, 1)
	character_util.move_to(user_party.Leader, user_party.Leader.Position + vector(0, 0, -0.3),
			1, nil, false, false, false)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(1, 'linear')

	--if self.trap_holes[index].item ~= nil then
	--	self.trap_holes[index].item.Position = self.trap_holes[index].marker.position
	--end
	--for _, mat in ipairs(self.trap_holes[index].mats) do
	--	mat.ActiveState = active_state('enabled')
	--end

	if smoke ~= nil then
		smoke:Dispose()
		smoke = nil
	end

	self.trap_holes[index].fo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance

	user_party.Leader:SetScale(unity_class.vector3.one, 0)
	user_party.Leader:SetRotation(0, 0)
	character_util.remove_anim_and_emotion(user_party.Leader)
	character_util.set_position(user_party.Leader, self.trap_respawn_pos)
	character_util.set_direction(user_party.Leader, 'up')
	character_util.set_active_shadow(user_party.Leader, true)

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(1, 'linear')
	self.on_trap_event = false
end

function local_class:bomb_drop()
	self.is_bomb_active = true

	message_system:SendSync(self.bomb_barrel.FieldObjectBehaviour, CS.Oak.GimmickResetEvent.Instance)

	self.bomb_barrel.Position = self.bomb_pos + vector(0, 10, 1)
	self.free_fall:SetParameters(-5, CS.Oak.Constants.JumpGravity * 3, 10, 1)
	coroutine.yield()

	while not self.free_fall:IsDone() and not self.bomb_barrel.Holdable.IsHeld do
		local y_dist = self.free_fall:GetDistance()
		self.free_fall:Proceed(unity_class.time.deltaTime)
		self.bomb_barrel.Position = self.bomb_pos + vector(0, y_dist, 1)

		coroutine.yield(nil)
	end
end

function local_class:reset_spike()
	if self.spike_reset_call then
		coroutine.yield(nil)
	end

	local is_pushing = true
	self.is_spike_active = true

	while is_pushing and not self.spike_reset_call do
		local dt = unity_class.time.deltaTime
		for i, spike in ipairs(self.spikes) do
			CS.Oak.MoveOneFrameStageLogic.ExecuteMove(spike, vector(0, 0, 1), self.spike_push_speed * dt)
		end
		if self.spikes[1].Position.z >= self.spike_upper then
			is_pushing = false
		end
		coroutine.yield(nil)
	end

	if self.spike_reset_call then
		self.spike_reset_call = false
		return
	end

	while not is_pushing and not self.spike_reset_call do
		local dt = unity_class.time.deltaTime
		for i, spike in ipairs(self.spikes) do
			CS.Oak.MoveOneFrameStageLogic.ExecuteMove(spike, vector(0, 0, -1), self.spike_pull_speed * dt)
		end
		if self.spikes[1].Position.z <= self.spike_lower then
			is_pushing = true
		end
		coroutine.yield(nil)
	end

	if self.spike_reset_call then
		self.spike_reset_call = false
		return
	end

	for i, spike in ipairs(self.spikes) do
		spike.Position = vector(spike.Position.x, 0, 113)
	end

	self.is_spike_active = false
end

function local_class:destroy_cracked_wall(effect)
	stage_progress:SetNamedData(self.cracked_wall_name, true)

	if effect then
		unity_object_pool.GetOrCreate('FX_Common_SmokeScreen')
		                 :Instantiate(self.cracked_wall.Position)
		music_player_util.play_sfx({ sfx_name = '02_explosion_02', parent = self.cracked_wall,
		                             type_priority = 'event', player_priority = 'object' })
		camera_util.shake(0.3, 0.5)
		wait_for_sec(0.2)
	end

	self.cracked_wall.Transform:GetChild(0).gameObject:SetActive(false)
	self.cracked_wall.Transform:GetChild(1).gameObject:SetActive(true)

	self.cracked_wall.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	self.cracked_wall.Interactable = CS.Oak.NonInteractable.Instance
end

function local_class:sohee_event()
	local sohee = get_character('running_machine_sohee')
	sohee.Interactable = CS.Oak.NonInteractable.Instance

	music_player_util.play_sfx({ sfx_name = '01_typing_01', type_priority = 'event', player_priority = 'npc', parent = sohee })

	-- 좋았어! 이대로라면 안정적으로 전력을 공급할 수 있겠어!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', type_priority = 'event', player_priority = 'npc', parent = sohee })
	speech_bubble_util.show_speech_bubble_async(sohee, { key = 'nightmare_futurecastle_2_threadmill_generator_test_1' })

	--  …252시간만 더 그렇게 뛰면 돼!!
	speech_bubble_util.show_speech_bubble_async(sohee, { key = 'nightmare_futurecastle_2_threadmill_generator_test_2' })

	sohee.Interactable = CS.Oak.NPCInteractable.Create()
	sohee.Interactable.Talk = 'nightmare_futurecastle_2_threadmill_generator_test_2'
end

function local_class:online_talk_with_sfx(name)
	local character = get_character(name)
	local info = self.sfx_online_talker[name]

	if character ~= nil then
		if info.sfx_holder ~= nil then
			info.sfx_holder:Stop()
			info.sfx_holder = nil
		end
		info.sfx_holder = music_player_util.play_sfx({ sfx_name = info.sfx, type_priority = 'event', player_priority = 'npc' })

		speech_bubble_util.remove_bubble(character)
		speech_bubble_util.show_speech_bubble_async(character, { key = info.speech })
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
