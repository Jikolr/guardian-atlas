local local_class = newclass('NightmareQueenCastle1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 456

	self.script = nil
	---@type CharacterPlaceController 캐릭터 배치 컨트롤러
	self.event_controller = nil

	self.fo = {
		mural = function(index)
			return get_field_object('control_room_mural_' .. index)
		end
	}

	--npc
	self.character = setmetatable({
		spec = {
			--니프티
			twins_android = 'twins_android',
			--시프티
			twins_android_b = 'twins_android_b',
		}
	}, {
		__index = function(this, key)
			return get_character(this.spec[key])
		end
	})

	-- 안드로이드 머리 세팅
	self.dummy_head_check = { false, false }

	self.fx = metatable_helper.create_fx_accessor({
		reset = function()
			return unity_object_pool.GetOrCreate('FX_reset_object')
		end,
	})

	self.equipping_sfx = nil

	self.dynamic_npcs = {
		prefix = 'nm_qc_stage_1',
		specs = {
			android_2 = 'nightmare_qc_android_worker',
			android_3 = 'nightmare_qc_android_worker',
			android_guard_1 = 'nightmare_qc_android_worker',
			android_guard_2 = 'nightmare_qc_android_worker',
			android_guard_3 = 'nightmare_qc_android_worker',
			android_guard_4 = 'nightmare_qc_android_worker',
		},

		container = nil,

		get = function(this, name)
			if this.container == nil then
				return
			end

			return this.container[name]
		end,

		load_async = function(this)
			if this.container ~= nil then
				return
			end

			this.container = load_util.create_dynamic_npcs_with_prefix_async(this.prefix, this.specs)
		end,

		dispose = function(this)
			if this.container == nil then
				return
			end

			load_util.dispose_dynamic_npcs(this.container)

			this.container = nil
		end
	}

	self.late_update_handler = metatable_helper.inherit({
		priority = CS.Oak.UpdatePriorities.StageEvent,
		callback_name = 'late_update_frame',
	}, {
		add = function(this, updater)
			update_util.add_late_update(updater, this.priority, this.callback_name)
		end,

		remove = function(this, updater)
			update_util.remove_late_update(updater, this.priority, this.callback_name)
		end,
	})

	self.guard = {
		reset_pos = field_util.get_marker_pos('s3_detected_reset_pos'),
		is_detected = false,
		count = 4,
		get = function(this, number)
			return self.dynamic_npcs:get('android_guard_' .. number)
		end,
		foreach = function(this, func)
			for i = 1, this.count do
				func(i, this:get(i))
			end
		end,
		attack_range = {
			data = {},
			count = 4,
			range = 3.5,
			sight_angle = 45,
			create = function(this)
				if #this.data == this.count then
					return
				end

				for i = 1, this.count do
					local attack_range = attack_range_util.create_arc(vector(999, 0, 999), this.range, this.sight_angle)
					attack_range.transform.rotation = unity_class.quaternion.identity

					table.insert(this.data, {
						comp = attack_range,
						tf = attack_range.transform,
					})

					attack_range_util.hide(attack_range)
				end
			end,
			destroy = function(this)
				for i = 1, #this.data do
					attack_range_util.destroy(this.data[i].comp)
				end

				this.data = {}
			end,
			is_in_sight = function(this, target)
				local leader = user_party.Leader

				if leader.FieldObjectStatsBehaviour.IsDead then
					return false
				end

				local full_diff = leader.Bounds.center - target.Bounds.center
				local diff = leader.Bounds.center - target.Bounds.center

				if diff.magnitude > this.range then
					return false
				end

				diff.y = 0

				if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(target.Direction)) >
						this.sight_angle / 2 then

					return false
				end

				if field:IsAnythingBlocking(CS.UnityEngine.Bounds(target.Bounds.center, vector(0.05, 0.05, 0.05)),
						CS.Oak.EntityGroups.Obstacle, vector_util.get_x0z(full_diff)) then

					return false
				end

				return true
			end
		},
		activate_sight = function(this)
			for i = 1, this.count do
				local npc = this:get(i)

				this.attack_range.data[i].tf:SetParent(npc.Transform)
				this.attack_range.data[i].tf.localPosition = vector(0, 0.03, 0)
				attack_range_util.show(this.attack_range.data[i].comp)
			end
		end,
		set_angle = function(this)
			for i = 1, this.count do
				local npc = this:get(i)
				local euler_angle

				if npc.Direction == CS.Oak.Direction.Right then
					euler_angle = unity_class.quaternion.identity
				elseif npc.Direction == CS.Oak.Direction.Left then
					euler_angle = unity_class.quaternion.Euler(0, 180, 0)
				elseif npc.Direction == CS.Oak.Direction.Up then
					euler_angle = unity_class.quaternion.Euler(0, -90, 0)
				else
					euler_angle = unity_class.quaternion.Euler(0, 90, 0)
				end

				this.attack_range.data[i].tf.rotation = euler_angle
			end
		end,
		deactivate_sight = function(this)
			for i = 1, this.count do
				this.attack_range.data[i].tf:SetParent(nil)
				attack_range_util.hide(this.attack_range.data[i].comp)
			end
		end,
		drop_item = {
			data = {},
			item_pos = {
				vector(69.5, 0, 46),
				vector(63.5, 0, 47),
			},
			create = function(this)
				for i = 1, 2 do
					local item = quest_drop_item_util.create_item({
						pos = this.item_pos[i],
						item_id = 21527,
						loot_state = quest_drop_item_loot_state.dont_find_looter,
						spr_scale = 0.8
					})
					table.insert(this.data, item)
				end
			end,
			dispose = function(this)
				for i = 1, #this.data do
					quest_drop_item_util.dispose_item(this.data[i])
				end
			end
		}
	}

	self.broken_worker_head = {
		prefix = 'broken_worker_head_',
		count_per_group = { 3, 1 },

		get_fo = function(this, group_idx, idx)
			return get_character(this.prefix .. group_idx .. '_' .. idx)
		end,

		---@type fun(this:self)
		init = function(this)
			for group_idx = 1, #this.count_per_group do
				local cur_group_count = this.count_per_group[group_idx]

				--레벨 비표시
				for idx = 1, cur_group_count do
					local target = this:get_fo(group_idx, idx)
					field_ui_manager:RemoveUI(target, CS.Oak.FieldUiType.CharacterStats)
				end
			end
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	if self.equipping_sfx ~= nil then
		music_player_util.stop_sfx(self.equipping_sfx)
		self.equipping_sfx = nil
	end

	self.stage_exit = true

	if self.late_update_handler ~= nil then
		self.late_update_handler:remove(self)
	end

	self.late_update_handler = nil

	self.guard.drop_item:dispose()
	self.dynamic_npcs:dispose()

	self.script:dispose()

	self.script = nil

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	local is_create, event_controller = global_table_util.try_create('Quest/Etc/CharacterPlaceController/CharacterPlaceController')

	self.event_controller = event_controller

	self.event_controller:initialize()
	local script_path = 'Quest/Nightmare/QueenCastle/Common/WeaponNpcBattleLogic'

	self.script = CS.Oak.StageLuaScript.Create(script_path)

	self.fx:create_all()
end

function local_class:on_event(e)
	return false
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('head_reset_switch_1')) then
		for i = 1, 3 do
			self:reset_dummy_head('broken_worker_head_1_', i)
		end

		return true
	elseif e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, get_field_object('head_reset_switch_2')) then
		self:reset_dummy_head('broken_worker_head_2_', 1)

		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'reset_grid_1') then
		for i = 1, 3 do
			self:reset_dummy_head('broken_worker_head_1_', i)
		end
	end

	if type_util.is_player_leave_to_cam_grid(e, 'reset_grid_2') then
		self:reset_dummy_head('broken_worker_head_2_', 1)
	end
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(_)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self:npc_setting()
	self:setting_mural()

	self.dynamic_npcs:load_async()

	self.late_update_handler:add(self)

	self:set_npc_presets_for_state()
	self:set_npc_with_data(self.npc_presets)

	self.broken_worker_head:init()

	self:set_waypoint_guard()

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.script:load()

	--4섹션 중간에 exit로 나갔던 경우 중간 이벤트부터 진행
	local used_exit_lobby_key = 's4_used_exit_lobby'
	local used_exit_lobby_val = 1
	local used_exit_lobby_state = quest_util.get_custom_state(quest_progress,
			used_exit_lobby_key)

	if quest_progress ~= nil and
			quest_progress.InnerProgress == 3 and
			used_exit_lobby_state == used_exit_lobby_val then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s5_start_pos'), true, true)

		music_player_util.play_stage_music({ state = 'muted', mix = 0 })
		music_player_util.play_stage_music({ name = 'ondemand/v2_65_queencastle/audio:bgm_queencastle_hub',
											 state = 'field',  volume = 1, mix = 1 })
	else
		stage_start_util.start_function(quest_progress)
	end

	music_player_util.start_bgm_manager()
end

function local_class:npc_setting()
	self.equipping_sfx = music_player_util.play_sfx(
			{ sfx_name = '03_equipping_01', type_priority = 'loop',
			  loop = true, parent = get_character('android_3') })

	for i = 3, 4 do
		local android = get_character('android_' .. i)

		character_util.add_color(android, android.Name,
				unity_class.color.black, 0.7, 0)
		field_ui_util.remove_ui(android, CS.Oak.FieldUiType.CharacterStats)
	end
end

function local_class:reset_dummy_head(head_group, index)
	local leader = user_party.Leader
	local head = get_character(head_group .. index)

	character_util.release_hold_object(leader, head)

	local fx_reset = self.fx.reset()
	fx_reset:Instantiate(head.Position)
	head.Position = field_util.get_marker_pos(head_group .. index)
	fx_reset:Instantiate(head.Position)

	head.Holdable = CS.Oak.Holdable()
end

function local_class:setting_mural()
	for i = 2, 5 do
		local mural_transform = self.fo.mural(i).Transform
		local on_target

		if i == 5 then
			on_target = CS.Utils.FindChildRecursively(mural_transform, 'second')
		else
			on_target = CS.Utils.FindChildRecursively(mural_transform, 'second_picture')
		end

		local off_target = CS.Utils.FindChildRecursively(mural_transform, 'first_picture')

		on_target.gameObject:SetActive(true)
		off_target.gameObject:SetActive(false)
	end
end

function local_class:set_npc_presets_for_state()
	self.npc_presets = {
		{
			type = 'dynamic',
			name = 'android_2',
			pos = vector(67, 1, 40),
			dir = 'left',
			anim = 'eat'
		},
		{
			type = 'dynamic',
			name = 'android_3',
			pos = vector(70, 1, 39.5),
			dir = 'right',
			anim = 'carpenter_hammer'
		},
		{
			type = 'dynamic',
			name = 'android_guard_1',
			pos = vector(71.5, 0, 51),
			dir = 'right',
		},
		{
			type = 'dynamic',
			name = 'android_guard_2',
			pos = vector(63, 0, 47),
			dir = 'right',
			anim = 'carpenter_hammer'
		},
		{
			type = 'dynamic',
			name = 'android_guard_3',
			pos = vector(69, 0, 46),
			dir = 'right',
			anim = 'carpenter_hammer'
		},
		{
			type = 'dynamic',
			name = 'android_guard_4',
			pos = vector(63, 0, 43),
			dir = 'left',
			anim = 'eat'
		},
	}
end

function local_class:set_npc_with_data(data)
	for i = 1, #data do
		local npc_preset = data[i]

		local npc
		if npc_preset.type == 'static' then
			if npc_preset.name == 'leader' then
				npc = get_party_leader()
			else
				npc = get_character(npc_preset.name)
			end
		else
			npc = self.dynamic_npcs:get(npc_preset.name)
		end

		character_util.remove_anim_and_emotion(npc)

		if data[i].pos ~= nil then
			character_util.set_position(npc, data[i].pos)
		end

		if data[i].dir ~= nil then
			character_util.set_direction(npc, data[i].dir)
		end

		if data[i].emo ~= nil then
			scene_util.set_emotion(npc, self, data[i].emo)
		end

		if data[i].anim ~= nil then
			scene_util.set_anim(npc, self, { name = data[i].anim, one_shot_sfx = false })
		end

		if data[i].tint ~= nil then
			character_util.add_color(npc, npc.Name, data[i].tint, 1, 0)
		end

		if data[i].active ~= nil then
			field_object_util.set_active_state(npc, data[i].active)
		else
			field_object_util.set_active_state(npc, active_state_type.enabled)
		end
	end
end

function local_class:set_waypoint_guard()
	self.guard.attack_range:create()
	self.guard:activate_sight()
	self.guard.drop_item:create()

	self:waypoint_guard_routine()
end

function local_class:waypoint_guard_routine()
	local wp_guard_1_routine = function()
		local guard_1 = self.guard:get(1)

		local guard_wp_1 = {
			vector(63, 0, 51),
			vector(73, 0, 51),
		}

		wp_util.move_async(guard_1, guard_wp_1[1], 4, nil, { run = false, play_sfx = true })

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--1번 NPC
		--‘가’ 지점으로 이동
		--4의 속도로 이동

		--이동 시 애니메이션 (left/right, idle, carpenter_walk)

		--가 지점 도착 시
		--1초간 (left, idle, carpenter_hammer) 출력
		local hammer_loop_sfx = music_player_util.play_sfx({
			sfx_name = '01_mining_01',
			parent = guard_1,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 4.5
		})

		scene_util.set_anim(guard_1, self, { name = 'carpenter_hammer' })

		wait_for_sec(1)

		--이후 나 지점으로 이동
		character_util.remove_anim(guard_1)
		music_player_util.stop_sfx(hammer_loop_sfx)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		wp_util.move_async(guard_1, guard_wp_1[2], 4, nil, { run = false, play_sfx = true })

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--나 지점 도착 시
		--1초 간 (right, idle, eat)출력
		local eat_loop_sfx = music_player_util.play_sfx({
			sfx_name = '03_equipping_01',
			parent = guard_1,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 4.5
		})

		scene_util.set_anim(guard_1, self, { name = 'eat' })

		wait_for_sec(1)

		character_util.remove_anim(guard_1)

		music_player_util.stop_sfx(eat_loop_sfx)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--이후 가 지점으로 이동
	end

	local wp_guard_4_routine = function()
		local guard_4 = self.guard:get(4)

		--‘다’ 지점으로 이동
		--4의 속도로 이동
		local guard_wp_2 = {
			vector(63, 0, 43),
			vector(71, 0, 43),
		}

		wp_util.move_async(guard_4, guard_wp_2[1], 4, nil, { run = false })

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--이동 시 애니메이션 (left/right, idle, carpenter_walk)

		--다 지점 도착 시
		--1초 간 (left, idle, carpenter_hammer) 출력
		local hammer_loop_sfx = music_player_util.play_sfx({
			sfx_name = '01_mining_01',
			parent = guard_4,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 4.5
		})

		scene_util.set_anim(guard_4, self, { name = 'carpenter_hammer' })

		wait_for_sec(1)

		--이후 라 지점으로 이동
		character_util.remove_anim(guard_4)
		music_player_util.stop_sfx(hammer_loop_sfx)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		wp_util.move_async(guard_4, guard_wp_2[2], 4, nil, { run = false, play_sfx = true })

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--라 지점 도착 시
		--1초 간 (right, idle, eat) 출력
		local eat_loop_sfx = music_player_util.play_sfx({
			sfx_name = '03_equipping_01',
			parent = guard_4,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 4.5
		})

		scene_util.set_anim(guard_4, self, { name = 'eat' })

		wait_for_sec(1)

		character_util.remove_anim(guard_4)

		music_player_util.stop_sfx(eat_loop_sfx)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--이후 다 지점으로 이동
	end

	local guard_routine = function()
		local guard_2 = self.guard:get(2)
		local guard_3 = self.guard:get(3)

		local hammer_loop_sfx_1 = music_player_util.play_sfx({
			sfx_name = '01_mining_01',
			play_pos = guard_2.Position,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 3
		})

		--2,3번 NPC
		--(left, idle, carpenter_hammer) 2초간 출력
		scene_util.set_direction(guard_2, direction_constants.left, false)
		scene_util.set_anim(guard_2, self, { name = 'carpenter_hammer' })

		local hammer_loop_sfx_2 = music_player_util.play_sfx({
			sfx_name = '01_mining_01',
			play_pos = guard_3.Position,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 3
		})

		scene_util.set_direction(guard_3, direction_constants.left, false)
		scene_util.set_anim(guard_3, self, { name = 'carpenter_hammer' })

		wait_for_sec(2)

		music_player_util.stop_sfx(hammer_loop_sfx_1)
		music_player_util.stop_sfx(hammer_loop_sfx_2)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--(right, idle, eat)1.5초간 출력
		local eat_loop_sfx_1 = music_player_util.play_sfx({
			sfx_name = '03_equipping_01',
			play_pos = guard_2.Position,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 3
		})

		scene_util.set_direction(guard_2, direction_constants.right, false)
		scene_util.set_anim(guard_2, self, { name = 'eat' })

		local eat_loop_sfx_2 = music_player_util.play_sfx({
			sfx_name = '03_equipping_01',
			play_pos = guard_3.Position,
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 3
		})

		scene_util.set_direction(guard_3, direction_constants.right, false)
		scene_util.set_anim(guard_3, self, { name = 'eat' })

		wait_for_sec(1.5)

		music_player_util.stop_sfx(eat_loop_sfx_1)
		music_player_util.stop_sfx(eat_loop_sfx_2)

		if self.stage_exit or self.guard.is_detected then
			return
		end

		--반복
	end

	start_coroutine(function()
		while self.stage_exit or not self.guard.is_detected do
			wp_guard_1_routine()

			if self.stage_exit or self.guard.is_detected then
				return
			end
		end
	end)

	start_coroutine(function()
		while self.stage_exit or not self.guard.is_detected do
			wp_guard_4_routine()

			if self.stage_exit or self.guard.is_detected then
				return
			end
		end
	end)

	start_coroutine(function()
		while self.stage_exit or not self.guard.is_detected do
			guard_routine()

			if self.stage_exit or self.guard.is_detected then
				return
			end
		end
	end)
end

function local_class:late_update_frame(dt)
	if self.stage_exit or self.guard.is_detected then
		return
	end

	self.guard:set_angle()
	self.guard:foreach(function(index, guard)
		if self.stage_exit or self.guard.is_detected then
			return
		end

		self.guard.is_detected = self.guard.attack_range:is_in_sight(guard)

		if self.guard.is_detected then
			sp_util.start_scene(self.detected_event, self, guard)
		end
	end)
end

function local_class:detected_event(guard)
	local twins_android = self.character.twins_android
	local twins_android_b = self.character.twins_android_b

	local look_direction = vector_util.to_direction(twins_android.Position - guard.Position)

	character_util.stop(guard)

	--니프티, 시프티 (적발 방향, scared, embarrassed) 출력
	music_player_util.play_sfx_one_shot('03_runaway_01')

	character_util.look_at(twins_android, guard)
	scene_util.set_emotion(twins_android, self, 'scared')
	scene_util.set_anim(twins_android, self, { name = 'embarrassed' })

	character_util.look_at(twins_android_b, guard)
	scene_util.set_emotion(twins_android_b, self, 'scared')
	scene_util.set_anim(twins_android_b, self, { name = 'embarrassed' })

	--적발 시 연출
	--화면 shake 0.1세기로 0.5초간 출력
	camera_util.shake(0.1, 0.5)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	music_player_util.play_sfx_one_shot('03_dialogue_worker_02')

	--NPC (적발한 방향, mad, release 3회):[shout, 한 번에 출력] 식별 불가 안드로이드를 발견했습니다!
	scene_util.play_shout_speech_action(guard, self, look_direction,
			{ name = 'release', count = 3 },
			{ name = 'mad' },
			{ key = 'nm_qc_main_s3_detection_key', skip = true, type_speed = 0 })

	--1초 대기
	wait_for_sec(1)

	--1초에 걸쳐 circular fade out
	music_player_util.play_sfx_one_shot('01_drown_01')

	local fade_duration = 1
	screen_util.fade_out_circular_async(fade_duration, 'linear')

	character_util.remove_anim_and_emotion(twins_android)
	character_util.remove_anim_and_emotion(twins_android_b)

	--빨간색 마름모 위치로 리스폰
	party_util.align_party(self.guard.reset_pos, 'right', 0)

	--0.5초 대기
	wait_for_sec(0.5)

	self.guard.is_detected = false

	--모든 NPC는 초기화된 위치로 경비 시작
	self:set_npc_with_data(self.npc_presets)

	self:waypoint_guard_routine()

	--1초에 걸쳐 circular fade in
	screen_util.fade_in_circular_async(fade_duration, 'linear')

	--이후 컨트롤 해제
end

return local_class
