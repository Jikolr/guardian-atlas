local local_class = newclass('OberonPhaseController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.phase_one_boss_name = 'boss_phase_1'
	self.phase_two_boss_name = 'boss_phase_2'

	self.phase_shift_hp_ratio = 0.1

	self.state = {
		none = 0,
		cast = 1,
		shift = 2,
		post = 3,
		complete = 4,
	}

	self.cast_duration = 5.5
	self.cast_idle_duration = 2.5
	self.cast_camera_move_time = 1
	self.cast_battle_cam_size = 4.5

	self.shift_duration = 3.65
	self.shift_charge_duration = 3.15

	self.post_duration = 1.5
	self.post_camera_move_time = 2

	self.speech_offset, self.speech_dir = CS.SpeechBubbleOffset.Offsets[speech_bubble.bubble_directions.rt] + vector(1, 3.5, 0), "rt"

	self.current_state = self.state.none
	self.time_passed = 2

	self.first_speech_time = 1
	self.second_speech_time = 3
	self.third_speech_time = 9
	self.speech_time_passed = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	self.phase_one_boss = get_character(self.phase_one_boss_name)
	self.phase_two_boss = get_character(self.phase_two_boss_name)

	unity_object_pool.GetOrCreate('fx_boss_oberon_phaseshift_ready')
	unity_object_pool.GetOrCreate('fx_boss_oberon_phaseshift')
	unity_object_pool.GetOrCreate('fx_boss_oberon_windwave_enhance')
end

function local_class:set_invincible(character)
	if character.DamagedBehaviour ~= CS.Oak.NullDamagedBehaviour.Instance then
		character.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	end
end
function local_class:remove_invincible(character)
	-- 아닌 경우에만 할당한다
	if character.DamagedBehaviour ~= nil and lua_helper.type_compare(character.DamagedBehaviour, CS.Oak.MonsterDamagedBehaviour) == false then
		character.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.None)
	end
end

function local_class:on_damage_event(e)
	if lua_helper.type_compare(e, CS.Oak.DamageEvent)
			and lua_helper.reference_equals(e.Info.target,self.phase_one_boss)
			and self.current_state == self.state.none then
		if self.phase_one_boss.CharacterStatsBehaviour.HpRatio < self.phase_shift_hp_ratio then
			self:change_state(self.state.cast)
		end
	end
end

function local_class:change_state(next_state)
	--exit
	if self.current_state == self.state.cast then
	elseif self.current_state == self.state.shift then
		self.phase_two_boss:RemoveAnimation(self.cs_controller)
	elseif self.current_state == self.state.post then
		self.phase_two_boss.FieldObjectController.DontFight = false

		-- 바로 플레이어를 Notice하도록
		message_system:Send(self.phase_two_boss.FieldObjectController, CS.Oak.MonsterNoticeEvent.Create(self.phase_two_boss,
				user_party.Leader, CS.Oak.MonsterNoticeLevel.Battle))
		message_system:Publish(CS.Oak.MonsterNoticeEvent.Create(self.phase_two_boss, user_party.Leader, CS.Oak.MonsterNoticeLevel.Battle))

		self:remove_invincible(self.phase_one_boss)
		self:remove_invincible(self.phase_two_boss)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.sender = self.phase_one_boss
		damage_info.target = self.phase_one_boss
		damage_info.damage = self.phase_one_boss.CharacterStatsBehaviour.MaxHP * 10
		command_util.publish_damage(damage_info)

	end

	self.current_state = next_state
	self.time_passed = 0

	--enter
	if self.current_state == self.state.cast then
		self.speech_time_passed = 0

		stage_camera:Move(self.phase_one_boss.Bounds.center + vector(0,2,0), self.cast_camera_move_time)
		stage_camera:ResizeTo(self.cast_battle_cam_size, self.cast_camera_move_time)
		self:set_phase_one_boss_screen_play()
		self.phase_one_boss:SetAnimation(self.cs_controller, CS.Oak.AnimationRequest('idle', CS.Oak.AnimationPriorities.Custom, true))

	elseif self.current_state == self.state.shift then
		unity_object_pool.GetOrCreate('fx_boss_oberon_phaseshift'):Instantiate(stage_camera.Transform.position, stage_camera.Transform.rotation, nil)
		music_player_util.play_sfx({ sfx_name = '02_plagueboss_intro_03' })

	elseif self.current_state == self.state.post then
		music_player_util.play_sfx({ sfx_name = '02_priscilla_cast_02' })
		stage_camera:Move(user_party.Leader, self.post_camera_move_time, user_party)
		stage_camera:ResizeTo(self.phase_two_boss.CharacterStatsBehaviour.CharacterSpec.BattleCamSize, self.post_camera_move_time)

		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.phase_one_boss, { 'remove_all_powder_orb' }))
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.phase_one_boss, { 'remove_all_debuff' }))
		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.phase_two_boss, { 'change_powder_owner' }))
	end
end

function local_class:set_phase_one_boss_screen_play()
	self.phase_one_boss.CharacterBehaviour:CancelAllBattleActions(true)

	self:set_invincible(self.phase_one_boss)

	self.phase_one_boss.FieldObjectController.DontFight = true
	message_system:SendSync(self.phase_one_boss.FieldObjectController, CS.Oak.StateResetEvent.Instance)
end

function local_class:change_boss()
	local boss_pos = self.phase_one_boss.Position
	self.phase_one_boss.Position = vector(999, 0, 999)

	message_system:Publish(CS.Oak.ShowBossHPEvent.Create(self.phase_two_boss))

	--교환될 보스 셋팅
	self.phase_two_boss.Direction = self.phase_one_boss.Direction
	self.phase_two_boss.FieldObjectController.DontFight = true
	self.phase_two_boss.Position = boss_pos
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	return false
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)

	if self.current_state ~= self.state.none and self.current_state ~= self.state.complete then
		self:update_speech(dt)
	end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.cast then
		if self.time_passed > self.cast_duration then
			self:change_state(self.state.shift)
		elseif self.time_passed > self.cast_idle_duration and self.time_passed - dt < self.cast_idle_duration then
			self.ready_fx = unity_object_pool.GetOrCreate('fx_boss_oberon_phaseshift_ready'):Instantiate(self.phase_one_boss.Bounds.center)
			self.phase_one_boss:SetAnimation(self.cs_controller, CS.Oak.AnimationRequest('charge', CS.Oak.AnimationPriorities.Custom, false))
			music_player_util.play_sfx({ sfx_name = '01_beth_transform_07', play_pos = self.phase_one_boss.Position })
			music_player_util.play_sfx({ sfx_name = '01_impact_02', play_pos = self.phase_one_boss.Position })
			self.phase_one_boss.SpineController:AddColor('phase_shift', unity_class.color.black, 1, self.cast_duration - self.cast_idle_duration)
		end
	elseif self.current_state == self.state.shift then
		if self.time_passed > self.shift_duration then
			self:change_state(self.state.post)
		elseif self.time_passed > self.shift_charge_duration and self.time_passed - dt < self.shift_charge_duration then
			if self.ready_fx ~= nil then
				self.ready_fx:Dispose()
				self.ready_fx = nil
			end
			self:change_boss()
			unity_object_pool.GetOrCreate('fx_boss_oberon_windwave_enhance'):Instantiate(self.phase_two_boss.Bounds.center)
			music_player_util.play_sfx({ sfx_name = '02_plagueboss_judge_02', play_pos = self.phase_two_boss.Position })
			self.phase_two_boss:SetAnimation(self.cs_controller, CS.Oak.AnimationRequest('shot', CS.Oak.AnimationPriorities.Custom, false))
			self:set_invincible(self.phase_two_boss)

		end
	elseif self.current_state == self.state.post then
		if self.time_passed > self.post_duration then
			self:change_state(self.state.complete)
		end
	end
end

function local_class:update_speech(dt)
	self.speech_time_passed = self.speech_time_passed + dt

	if self.speech_time_passed > self.first_speech_time and self.speech_time_passed - dt < self.first_speech_time then
		speech_bubble_util.show_speech_bubble(self.phase_one_boss, { key = 'pw_boss_phaseshift_one', offset = self.speech_offset, bubble_direction = self.speech_dir})
	elseif self.speech_time_passed > self.second_speech_time and self.speech_time_passed - dt < self.second_speech_time then
		speech_bubble_util.show_speech_bubble(self.phase_one_boss, { key = 'pw_boss_phaseshift_two', offset = self.speech_offset, bubble_direction = self.speech_dir})
	elseif self.speech_time_passed > self.third_speech_time and self.speech_time_passed - dt < self.third_speech_time then
		speech_bubble_util.show_speech_bubble(self.phase_two_boss, { key = 'pw_boss_phaseshift_three', offset = self.speech_offset, bubble_direction = self.speech_dir})
		music_player_util.play_sfx({ sfx_name = '01_impact_06', play_pos = self.phase_two_boss.Position })
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
