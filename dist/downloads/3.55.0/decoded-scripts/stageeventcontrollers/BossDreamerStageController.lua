local local_class = newclass('BossDreamerStageController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- params
	self.zoom_in_cam_size = 3.0
	self.zoom_in_cam_duration = 0.8

	-- effect pool
	self.fx_phaseshift_pool = unity_object_pool.GetOrCreate('fx_boss_dreamer_phaseshift')

	-- event sub
	self.on_stage_loaded_event_func = function(e)
		self:on_stage_loaded_event(e) end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)

	self.on_fieldobject_destroyed_func = function(e)
		self:on_fieldobject_destroyed_event(e) end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_fieldobject_destroyed_func)

	self.time_passed = 0

	self.scene_version = scene_util.default_version
end

function local_class:on_stage_loaded_event(e)
	self.boss_one = get_character('boss_monster_phase_1')
	self.boss_two = get_character('boss_monster_phase_2')
	field_object_util.set_active_state(self.boss_two, active_state_type.visible)
end

function local_class:on_fieldobject_destroyed_event(e)
	if self.boss_one == nil or not lua_helper.reference_equals(e.FieldObject, self.boss_one) then
		return
	end

	start_coroutine(function()
		sp_util.enter_scene()

		self:phase_shift_scene()
		self:activate_phase_2()

		sp_util.exit_scene(nil, get_party_leader())
	end)
end

function local_class:load_resource(key, load_end_callback)
	return util.cs_generator(self.on_load_resource, self, load_end_callback)
end

function local_class:on_load_resource(load_end_callback)
	if load_end_callback then
		load_end_callback()
	end
end

function local_class:phase_shift_scene()
	local prev_camera_size = stage_camera.Size
	local black_tint_key = 's25_phase_shift'
	local target_color = unity_class.color.black

	do
		--보스 hp 0이 되면 dead 애니메이션 출력
		local dead_anim_name = 'dead'
		local dead_duration = spine_util.get_animation_duration(self.boss_one, dead_anim_name)
		local end_time = unity_class.time.time + dead_duration

		character_util.add_color(self.boss_two, black_tint_key, target_color, 1, 0)

		character_util.set_anim(self.boss_one, {
			name = dead_anim_name,
			loop = false,
			next_anim = 'dead_loop'
		})

		music_player_util.play_sfx_one_shot('01_event_dv_03')

		--카메라를 보스에게 고정
		do
			local duration = 0.8

			--카메라 사이즈 = 3
			--카메라 줌인 시간 = 0.8초
			camera_util.resize_by_ratio(3, duration)
			camera_util.move_async(self.boss_one.Bounds.center, duration)
		end

		while unity_class.time.time < end_time do
			coroutine.yield()
		end
	end

	--보스 dead_loop 상태 유지 = 2초
	do
		local duration = 2

		--보스 검은색 틴트 상태.
		character_util.add_color(self.boss_one, black_tint_key, target_color, 1, duration)
		character_util.add_color(self.boss_two, black_tint_key, target_color, 1, 0)
		character_util.force_update_spines(self.boss_two, 0.1)

		wait_for_sec(duration)
	end

	--fx_boss_dreamer_phaseshift 이펙트 출력
	self.fx_phaseshift_pool:Instantiate(self.boss_one.Bounds.center)

	--카메라 밖에서 영혼들이 보스에게 흡수되듯이 모임
	--카메라 쉐이크 = 2초
	--카메라 쉐이크 강도 = 0.2
	camera_util.shake(0.2, 2)

	--boss_dreamer_phaseshft
	--검은색 틴트 상태에서 뿔과 머리카락이 자라나는 스파인 재생
	music_player_util.play_sfx_one_shot('01_event_dv_04')
	scene_util.set_anim_async(self.boss_one, self, {
		name = 'boss_dreamer_phaseshift',
		loop = false,
		keep_anim = true,
		scale = 0.67,
	})

	--페이즈 전환 (교체)
	--boss_dreamer_phaseone → boss_dreamer_phasetwo로 교체
	character_util.swap(self.boss_two, self.boss_one)

	--검은색 틴트 상태 유지
	--애니메이션 boss_dreamer_tuskscratch_cast 재생
	scene_util.set_anim(self.boss_two, self, {
		name = 'tuskscratch_cast',
		count = 1,
	})

	--검은색 틴트 해제
	character_util.remove_color(self.boss_two, black_tint_key, 1)

	--카메라 쉐이크 = 0.5초
	--카메라 쉐이크 강도 = 0.5
	camera_util.shake(0.5, 0.5)

	do
		local duration = 1.5

		--카메라 줌아웃 시간 = 1.5초
		camera_util.resize_to(prev_camera_size, duration)

		wait_for_sec(duration)
	end

	--페이즈 전환 연출 종료
	character_util.remove_anim(self.boss_two)

	--전투 상태
	--유저 컨트롤 가능
	camera_util.return_to_leader(1)
end

function local_class:activate_phase_2()
	field_object_util.set_active_state(self.boss_two, active_state_type.enabled)
	character_util.set_death_type(self.boss_two, death_type_constants.none)
	command_util.publish_monster_notice(self.boss_two, get_party_leader(), 'battle')
end

function local_class:on_launch(_)

end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	self.time_passed = self.time_passed + dt
end

function local_class:dispose()
	if self.on_stage_loaded_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)
		self.on_stage_loaded_event_func = nil
	end

	if self.on_fieldobject_destroyed_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_fieldobject_destroyed_func)
		self.on_fieldobject_destroyed_func = nil
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
