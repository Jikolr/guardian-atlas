local local_class = newclass("AfterWorldSisyphusSNSController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 대사 스크립트
	self.main_script = 'aw_sisyphus_'

	-- NPC
	self.sisyphus = nil
	self.sisyphus_name = 'sisyphus'

	-- FieldObject
	self.barrel = nil
	self.barrel_name = 'sisyphus_barrel'

	self.signboard = nil
	self.signboard_name = 'sisyphus_signboard'

	self.flag = nil
	self.flag_name = 'sisyphus_flag'

	-- 플래그
	self.is_in_camera_grid = false
	self.interrupt_loop = false
	self.is_recover_sisyphus = false

	-- SNS Follower ID
	self.follower_id = 62

	-- 카메라 그리드 이름
	self.sisyphus_camera_grid_name = 'sisyphus_grid'

	-- 오브젝트 풀 프리셋 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	self.sisyphus = get_character(self.sisyphus_name)

	self.barrel = get_field_object(self.barrel_name)
	self.signboard = get_field_object(self.signboard_name)
	self.flag = get_field_object(self.flag_name)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.sisyphus = nil

	self.barrel = nil
	self.signboard = nil

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		self:on_camera_grid_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- Barrel 크기 / 위치 설정
	self.barrel.Position = vector(-71, 1, 104)

	-- Flag 크기 조정
	self.flag.Transform.localScale = unity_class.vector3.one * 0.5

	character_util.set_rolling_number(self.sisyphus.Transform,
			999999999, nil, 0, unity_class.color.red)
end

function local_class:on_camera_grid_enter_event(e)
	if e.CameraGrid.name == self.sisyphus_camera_grid_name then
		if not self.is_in_camera_grid then
			self.is_in_camera_grid = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.labor_event, self))
		end
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.sisyphus_camera_grid_name) then
		if self.is_in_camera_grid then
			self.is_in_camera_grid = false
			self.is_recover_sisyphus = false

			character_util.stop(self.sisyphus)
			character_util.set_position(self.sisyphus, vector(-71, 0, 103))
			character_util.set_direction(self.sisyphus, 'up')

			self.barrel.Position = vector(-71, 1, 104)
			self.barrel.Transform:GetChild(0).localRotation = unity_class.quaternion.Euler(0, 0, 0)
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.sisyphus) then
		sp_util.play_normal_screenplay(self.talk_with_sisyphus_event, self)
	elseif lua_helper.reference_equals(e.Target, self.signboard) then
		sp_util.play_normal_screenplay(self.interact_with_signboard_event, self)
	end
end
--endregion

-- 통 굴리는 이벤트
function local_class:labor_event()
	local timer = 0
	local move_up_duration = 7
	local fail_duration = 2
	local recover_duration = 4

	local start_rotation = 0
	local end_rotation = 360

	local start_pos = self.sisyphus.Position
	local move_up_pos = vector(0, 0, 7)

	local start_barrel_pos = self.barrel.Position

	local is_laid_out = false
	local laid_duration = 0.2

	local recover_finished_duration = 1

	local labor_state = {
		move_up = 0,
		fail = 1,
		recover = 2
	}

	local state = labor_state.move_up

	local rotate_transform = self.barrel.Transform:GetChild(0)

	local loop_sfx = music_player_util.play_sfx(
			{ sfx_name = "01_drumtong_01", loop = true, type_priority = 'loop' })

	character_util.set_anim(self.sisyphus, { name = 'push', upper = true })
	character_util.set_anim(self.sisyphus, { name = 'walk' })
	character_util.set_emotion(self.sisyphus, { name = 'tired' })

	speech_bubble_util.show_speech_bubble(self.sisyphus, { key = self.main_script..1, skip = false })

	local is_add_listener = not user_progress:IsFollowing(self.follower_id)

	while not self.interrupt_loop and self.sisyphus ~= nil and self.barrel ~= nil and self.is_in_camera_grid do
		if state == labor_state.move_up then
			local player_dist_x = get_party_leader().Position.x - self.barrel.Bounds.center.x
			local player_dist_z = get_party_leader().Position.z - self.barrel.Bounds.center.z

			if math.abs(player_dist_x) > 1.3 or math.abs(player_dist_z) > 1 or
					get_party_leader().Position.y > 0 then
				timer = timer + unity_class.time.deltaTime

				if timer >= move_up_duration then
					timer = 0
					state = labor_state.fail

					loop_sfx:FadeOut()
					loop_sfx = music_player_util.play_sfx(
							{ sfx_name = "01_drumtong_02", loop = true, type_priority = 'loop' })

					character_util.set_position(self.sisyphus, start_pos + move_up_pos)

					self.barrel.Position = start_barrel_pos + move_up_pos
					rotate_transform.localRotation = unity_class.quaternion.Euler(end_rotation, 0, 0)
				else
					local cur_move_up_pos = unity_class.vector3.Lerp(
							start_pos, start_pos + move_up_pos, timer / move_up_duration)
					local cur_barrel_move_up_pos = unity_class.vector3.Lerp(
							start_barrel_pos, start_barrel_pos + move_up_pos, timer / move_up_duration)

					local cur_rotation = unity_class.mathf.Lerp(
							start_rotation, end_rotation, timer / move_up_duration)

					character_util.set_position(self.sisyphus, cur_move_up_pos)

					self.barrel.Position = cur_barrel_move_up_pos
					rotate_transform.localRotation = unity_class.quaternion.Euler(cur_rotation, 0, 0)
				end
			end
		elseif state == labor_state.fail then
			timer = timer + unity_class.time.deltaTime

			if timer >= fail_duration then
				timer = 0
				is_laid_out = false
				state = labor_state.recover

				loop_sfx:FadeOut()

				self.is_recover_sisyphus = false

				self.barrel.Position = start_barrel_pos
				rotate_transform.localRotation = unity_class.quaternion.Euler(start_rotation, 0, 0)

				if is_add_listener then
					character_util.add_listener(self.sisyphus, self.cs_controller)
				end

				music_player_util.play_sfx_one_shot('01_rustle_01')

				character_util.shake(self.sisyphus, 0.04, 1)
			else
				local cur_barrel_move_up_pos = unity_class.vector3.Lerp(
						start_barrel_pos + move_up_pos, start_barrel_pos, timer / fail_duration)

				local cur_rotation = unity_class.mathf.Lerp(
						end_rotation, start_rotation, timer / fail_duration)

				self.barrel.Position = cur_barrel_move_up_pos
				rotate_transform.localRotation = unity_class.quaternion.Euler(cur_rotation, 0, 0)
			end

			if not is_laid_out and timer >= laid_duration then
				is_laid_out = true

				music_player_util.play_sfx_one_shot('01_drumtong_03')
				music_player_util.play_sfx_one_shot('01_trip_01')
				music_player_util.play_sfx_one_shot('01_villain_scream_03')

				speech_bubble_util.show_speech_bubble(self.sisyphus,
						{ key = self.main_script..2, bubble_type = 'shout', skip = false })

				unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
						self.sisyphus.Position + vector(0, 0.3, 0))
				unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
						self.sisyphus.Position + vector(0, 0.3, 0))

				character_util.set_direction(self.sisyphus, 'right')
				character_util.spine_pulse_color(
						self.sisyphus, CS.Oak.Constants.DamageColor, 1, 1, 1)
				character_util.spine_damage_squish(
						self.sisyphus, 1.3, 0.7, 1, 0.3)
				character_util.remove_anim(self.sisyphus, true)
				character_util.set_anim(self.sisyphus, { name = 'prostrate' })
				character_util.set_emotion(self.sisyphus, { name = 'damaged' })

				CS.DamageNumber.ShowDamageNumber(self.sisyphus, 99999, unity_class.color.red, self.sisyphus.Position)
			end
		elseif state == labor_state.recover then
			timer = timer + unity_class.time.deltaTime

			if timer >= recover_duration then
				timer = 0

				self.sisyphus.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

				if is_add_listener then
					character_util.remove_relate_event(self.sisyphus, self.cs_controller)
				end

				character_util.set_anim(self.sisyphus, { name = 'run' })

				local waypoint_list = create_generic_list(unity_class.vector3)
				waypoint_list:Add(self.sisyphus.Position + vector(2, 0, 0))
				waypoint_list:Add(self.sisyphus.Position + vector(2, 0, -7))
				waypoint_list:Add(self.sisyphus.Position + vector(0, 0, -7))

				character_util.move_waypoint(self.sisyphus, waypoint_list, 6, true,
						'stop', 'floor', 'up', true, 0,
						function(index)
							if index == waypoint_list.Count - 1 then
								timer = 0
								state = labor_state.move_up

								loop_sfx = music_player_util.play_sfx(
										{ sfx_name = "01_drumtong_01", loop = true, type_priority = 'loop' })

								self.sisyphus.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

								character_util.set_anim(self.sisyphus, { name = 'idle' })
								character_util.set_anim(self.sisyphus, { name = 'push', upper = true })
							end
						end)
			end

			if not self.is_recover_sisyphus and timer >= recover_finished_duration then
				self.is_recover_sisyphus = true

				music_player_util.play_sfx_one_shot('01_player_popup_01')

				character_util.remove_anim(self.sisyphus)
				character_util.set_emotion(self.sisyphus, { name = 'tired' })
				character_util.mario_jump_new(self.sisyphus, 'right')

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.wait_and_animation, self))
			end
		end

		coroutine.yield(nil)
	end

	if loop_sfx ~= nil then
		loop_sfx:FadeOut()
		loop_sfx = nil
	end
end

-- 시시포스 애니메이션 연출 보조
function local_class:wait_and_animation()
	wait_for_sec(0.5)

	character_util.set_anim(self.sisyphus, { name = 'seat' })

	if not self.interrupt_loop then
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')

		speech_bubble_util.show_speech_bubble(self.sisyphus, { key = self.main_script..3, skip = false })
	end
end

-- 시시포스 대화 이벤트
function local_class:talk_with_sisyphus_event()
	if self.is_recover_sisyphus then
		self.interrupt_loop = true
	end

	party_util.align_party(self.sisyphus, 'right', 1, 'arc')

	while not self.is_recover_sisyphus do
		coroutine.yield(nil)
	end

	self.interrupt_loop = true

	music_player_util.play_sfx_one_shot('01_player_jump_01')

	character_util.jump(self.sisyphus, 1, 0.5)
	character_util.set_anim(self.sisyphus, { name = 'cast' })
	character_util.set_emotion(self.sisyphus, { name = 'surprise' })

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..4, skip = true })

	character_util.remove_emotion(self.sisyphus)

	choose_util.play_choose_event({ { self.main_script..5, 'mercy' } })

	character_util.set_anim(get_party_leader(), { name = 'release', sfx_name = '01_swing_01' })

	wait_for_sec(1)

	character_util.remove_anim(get_party_leader())

	character_util.set_emotion(self.sisyphus, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..6, skip = true })

	music_player_util.play_sfx_one_shot('01_swing_01')

	character_util.set_direction(self.sisyphus, 'down')

	character_util.set_direction(get_party_leader(), 'down')

	camera_util.move_async(vector(get_party_leader().Position.x, 0, 107), 1)

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..7, skip = true })

	character_util.set_direction(self.sisyphus, 'up')

	character_util.set_direction(get_party_leader(), 'up')

	camera_util.move_async(vector(get_party_leader().Position.x, 0, 113), 1.5)

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..8, skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')

	character_util.set_direction(get_party_leader(), 'left')

	character_util.set_direction(self.sisyphus, 'right')
	character_util.set_anim(self.sisyphus, { name = 'hurt' })

	camera_util.move_async(get_party_leader().Position, 1, { end_target = get_party_leader() })

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..9, skip = true })

	wait_for_sec(1.5)

	music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')

	character_util.set_anim(self.sisyphus, { name = 'victory_get', loop = false })
	character_util.set_emotion(self.sisyphus, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..10, skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.set_anim(self.sisyphus, { name = 'push' })

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..11, skip = true })

	-- SNS 등록 - 시시포스
	yield_return_func(CS.Oak.AddSNSCoroutine, self.follower_id)

	character_util.remove_anim(self.sisyphus)

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..12, skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')

	character_util.set_anim(self.sisyphus, { name = 'question', loop = false })
	character_util.remove_emotion(self.sisyphus)

	speech_bubble_util.show_speech_bubble_async(self.sisyphus, { key = self.main_script..13, skip = true })

	character_util.remove_relate_event(self.sisyphus, self.cs_controller)
	character_util.remove_anim(self.sisyphus)

	self.interrupt_loop = false

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.wait_for_reset, self))
end

-- 시시포스 리셋 대기
function local_class:wait_for_reset()
	wait_for_sec(2)

	self.sisyphus.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	character_util.set_anim(self.sisyphus, { name = 'run' })

	local waypoint_list = create_generic_list(unity_class.vector3)
	waypoint_list:Add(self.sisyphus.Position + vector(2, 0, 0))
	waypoint_list:Add(self.sisyphus.Position + vector(2, 0, -7))
	waypoint_list:Add(self.sisyphus.Position + vector(0, 0, -7))

	character_util.move_waypoint_async(self.sisyphus, waypoint_list, 6, true,
			'stop', 'floor', 'up', true)

	if self.is_in_camera_grid then
		character_util.set_anim(self.sisyphus, { name = 'idle' })
		character_util.set_anim(self.sisyphus, { name = 'push', upper = true })

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.labor_event, self))
	end
end

-- 표지판 상호작용 이벤트
function local_class:interact_with_signboard_event()
	field_ui_util.show_narration_async({ key = 'aw_sisyphus_14' })

	field_ui_util.show_narration_async({ key = 'aw_sisyphus_15' })

	coroutine.yield(nil)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
