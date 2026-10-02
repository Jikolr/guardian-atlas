local local_class = newclass('FakeKnightStageController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_data = require('stageeventcontrollers/FakeKnightStageControllerData.lua')
	self.current_stage_info = self.stage_data[stage.Name];

	self.current_phase = 1

	self.state = {
		none = 1,
		prepare = 2,
		move = 3,
		move_interval = 4,
		action = 5,
		post = 6
	}

	self.prepare_duration = self.current_stage_info.prepare_duration
	self.move_duration = self.current_stage_info.move_duration
	self.move_interval_duration = self.current_stage_info.move_interval_duration
	self.action_duration = self.current_stage_info.action_duration
	self.post_duration = self.current_stage_info.post_duration

	self.knock_back_force = self.current_stage_info.knock_back_force
	self.knock_back_radius = self.current_stage_info.knock_back_radius

	self.action_rotation_angle = self.current_stage_info.action_rotation_angle
	self.post_rotation_angle = self.current_stage_info.post_rotation_angle

	self.camera_thunder_time = self.current_stage_info.camera_thunder_time
	self.camera_thunder_magnitude = self.current_stage_info.camera_thunder_magnitude

	self.camera_focus_time = self.current_stage_info.camera_focus_time
	self.camera_focus_size = self.current_stage_info.camera_focus_size

	self.buff_id = self.current_stage_info.buff_id
	self.buff_level = self.current_stage_info.buff_level

	self.defense_buff_id = self.current_stage_info.defense_buff_id
	self.defense_buff_level_2 = self.current_stage_info.defense_buff_level_2
	self.defense_buff_level_3 = self.current_stage_info.defense_buff_level_3

	self.move_height = self.current_stage_info.move_height
	self.sfx_thunder_strike =  self.current_stage_info.sfx_thunder_strike
	self.sfx_phase_begin =  self.current_stage_info.sfx_phase_begin
	self.sfx_jump_begin =  self.current_stage_info.sfx_jump_begin

	self.fx_thunder_strike_pool = unity_object_pool.GetOrCreate(self.current_stage_info.fx_thunder_strike)
	self.thunder_offset_z = self.current_stage_info.thunder_offset_z

	self.give_buff = false

	self.on_battle_start_event_func = function(e)
		self:on_battle_start_event(e)
	end
	--- 전투 시작 이벤트 구독
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.BattleStartEvent), self.on_battle_start_event_func)

	self.on_stage_loaded_event_func = function(e)
		self:on_stage_loaded_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)

	self.on_damage_event_func = function(e)
		self:on_damage_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.DamageEvent), self.on_damage_event_func)

	self.on_custom_stage_event_func = function(e)
		self:on_custom_stage_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)

	self:change_state(self.state.none)
end

function local_class:change_state(next_state)

	-- 현재 스테이트 exit 처리
	if self.current_state == self.state.prepare then
		for _, knight in pairs(self.knight_list) do
			knight:RemoveAnimation()
		end
	elseif self.current_state == self.state.move then
	elseif self.current_state == self.state.move_interval then
	elseif self.current_state == self.state.action then

	elseif self.current_state == self.state.post then
		self:heal()

		for _, knight in pairs(self.knight_list) do
			buff_manager:RemoveBuff(knight, CS.Oak.EquipmentSlot.None, knight, self.defense_buff_id)
			if self.current_phase == 3 then
				knight:SetEmotion('mad',true)
				buff_manager:AddBuff(knight, CS.Oak.EquipmentSlot.None, knight, self.defense_buff_id, self.defense_buff_level_3, false, false)
			else
				buff_manager:AddBuff(knight, CS.Oak.EquipmentSlot.None, knight, self.defense_buff_id, self.defense_buff_level_2, false, false)
			end

			knight:RemoveAnimation()
		end

		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'phase_start', self.current_phase}))
	end

	-- 다음 스테이트 enter 처리
	if next_state == self.state.prepare then
		for _, knight in pairs(self.knight_list) do
			knight.Direction = CS.Oak.Direction.Right
			knight:SetAnimation('idle', true)
		end

		camera_util.move(self.reset_marker_3_1.position, self.camera_focus_time)
		camera_util.resize_to(self.camera_focus_size, self.camera_focus_time)
		music_player:PlaySfxOneShot(self.sfx_phase_begin)
	elseif next_state == self.state.move then
		for _, knight in pairs(self.knight_list) do
			knight:SetAnimation('cwp/knight', false)
			knight.SpineController:Rotate(self.action_rotation_angle, self.move_duration)
		end
		music_player:PlaySfxOneShot(self.sfx_jump_begin)
	elseif next_state == self.state.move_interval then
		for _, knight in pairs(self.knight_list) do
			knight.SpineController:Rotate(self.action_rotation_angle + self.post_rotation_angle, self.move_interval_duration)
		end

	elseif next_state == self.state.action then
		for _, knight in pairs(self.knight_list) do
			knight.SpineController:Rotate(0, 0)
			local dir = user_party.Leader.Position - knight.Position

			if dir.x >= 0 then
				knight.Direction = CS.Oak.Direction.Right
			else
				knight.Direction = CS.Oak.Direction.Left
			end

			knight:SetAnimation('unique/hero_landing', false)
			self:create_thunder(vector(knight.Position.x, 0, knight.Position.z))
		end
	elseif next_state == self.state.post then
		camera_util.move(user_party.Leader.Position, self.camera_focus_time, {
			target = user_party.Leader,
			end_target = user_party.Leader
			}
		)

		if self.current_phase == 2 then
			self.knight_list[1].Position = vector(self.reset_marker_2_1.position.x, 0, self.reset_marker_2_1.position.z)
			self.knight_list[2].Position = vector(self.reset_marker_2_2.position.x, 0, self.reset_marker_2_2.position.z)
		else
			self.knight_list[1].Position = vector(self.reset_marker_3_1.position.x, 0, self.reset_marker_3_1.position.z)
		end

		camera_util.resize_to_default(self.camera_focus_time)

		for _, knight in pairs(self.knight_list) do

			local speech = ''

			if self.current_phase == 2 then
				speech = 'nightmare_lt_boss_phaseshift_two'
			else
				speech = 'nightmare_lt_boss_phaseshift_three'
			end

			character_util.set_direction(knight, 'down')
			speech_bubble_util.show_speech_bubble(knight, { key = speech, skip = false })
		end

	else
	end

	self.time_passed = 0
	self.current_state = next_state
end

function local_class:create_thunder(position)

	self.fx_thunder_strike_pool:Instantiate(position + vector(0,0, self.thunder_offset_z))
	music_player:PlaySfxOneShot(self.sfx_thunder_strike)

	for i = 0, user_party.Count - 1 do
		local party = user_party[i]
		local knock_direction = (party.Position - position).normalized

		local distance = vector_util.get_x0z(party.Position - position).magnitude

		if distance <= self.knock_back_radius then
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.IgnoreDefense
			damage_info.sender = party
			damage_info.target = party
			damage_info.modifier = 0
			damage_info.direction = knock_direction
			damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
			damage_info.knockBackDirection = knock_direction
			damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.knock_back_force

			command_util.publish_damage(damage_info)
		end
	end

	camera_util.shake(self.camera_thunder_magnitude, self.camera_thunder_time)

end

function local_class:get_post_fix()

	local is_male = user_util.has_knight_male()

	if is_male then
		return '_f'
	else
		return '_m'
	end
end

function local_class:on_battle_start_event(e)

	local battle_instance = e.StartedBattle

	for _, knight in pairs(self.knight_list) do
		if battle_instance:IsInBattle(knight ,true) then

			if self.give_buff == false then
				buff_manager:AddBuff(user_party.Leader, CS.Oak.EquipmentSlot.None, user_party.Leader, self.buff_id, self.buff_level, false, false)
				self.give_buff = true
			end
			break
		end
	end

	return true
end


function local_class:on_stage_loaded_event(e)
	self.knight_list = {}

	table.insert(self.knight_list, get_character('boss_fakeknight_bow'..self:get_post_fix()));
	table.insert(self.knight_list, get_character('boss_fakeknight_twohand'..self:get_post_fix()));
	table.insert(self.knight_list, get_character('boss_fakeknight_onehand'..self:get_post_fix()));

	for _, knight in pairs(self.knight_list) do
		knight.CharacterStatsBehaviour.Immortal = true
	end


	self.reset_marker_2_1 = field:GetMarker('reset_fake_knight_2_1')
	self.reset_marker_2_2 = field:GetMarker('reset_fake_knight_2_2')
	self.reset_marker_3_1 = field:GetMarker('reset_fake_knight_3')

end

function local_class:on_damage_event(e)
	if not (self.current_state == self.state.none) then
		return
	end

	local has_knight_killed = false
	self.dead = nil

	for i, knight in pairs(self.knight_list) do
		if lua_helper.reference_equals(knight, e.Info.target) and knight.CharacterStatsBehaviour.HpRatio * 100 <= 1 then
			table.remove(self.knight_list, i)
			has_knight_killed = true

			self.dead = knight
			self.dead.SpineController:AddColor('dead', unity_class.color.black, 1, 0)
			self.dead.OverrideCrashBehaviour = CS.Oak.PassCharacterCrashBehaviour.Instance;
			self.dead.Direction = CS.Oak.Direction.Left
			self.dead:RemoveAnimation()
			self.dead:SetAnimation('dead', false)
			self.dead.CharacterStatsBehaviour.Immortal = false

			local field_ui = stage.FieldUIManager:GetUI(self.dead)
			if field_ui ~= nil then
				local has_value, field_ui_character_stats = field_ui:TryGetValue(CS.Oak.FieldUiType.CharacterStats)
				if has_value == true then
					field_ui_character_stats.gameObject:SetActive(false)
				end
			end

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Death
			damage_info.sender = self.dead
			damage_info.target = self.dead
			damage_info.damage = self.dead.CharacterStatsBehaviour.MaxHP * 10
			command_util.publish_damage(damage_info)
			break;
		end
	end

	if not has_knight_killed then
		return false
	end

	self.current_phase = self.current_phase + 1

	if self.current_phase > 3 then
		return false
	end

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'phase_increase', self.current_phase, self.dead.Name }))

	if self.current_phase == 2 then
		self.start_pos_2_1 = self.knight_list[1].Position
		self.start_pos_2_2 = self.knight_list[2].Position
	elseif self.current_phase == 3 then
		self.start_pos_3_1 = self.knight_list[1].Position
		self.knight_list[1].CharacterStatsBehaviour.Immortal = false
	end

	self:change_state(self.state.prepare)

	return true
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'phase_request' then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'phase_start', self.current_phase}))
	end
end

function local_class:heal()

	local heal_ratio = 1.0

	if self.current_phase == 2 then
		heal_ratio = self.current_stage_info.HealPhase_2
	elseif self.current_phase == 3 then
		heal_ratio = self.current_stage_info.HealPhase_3
	end

	for _, knight in pairs(self.knight_list) do
		knight.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()
		knight.DamagedBehaviour.DeathType = CS.Oak.DeathType.None

		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = math.floor(knight.FieldObjectStatsBehaviour.MaxHpWoMod * heal_ratio)
		heal_info.isRevive = false
		heal_info.sender = nil
		heal_info.target = knight
		local cmd = CS.Oak.HealCommand.Create(heal_info)
		command_util.publish_cmd(heal_info.Owner, cmd)
	end

	return heal_ratio
end

function local_class:load_resource(key, load_end_callback)
	return util.cs_generator(self.on_load_resource, self, load_end_callback)
end

function local_class:on_load_resource(load_end_callback)


	if load_end_callback then
		load_end_callback()
	end

end

function local_class:on_launch(_)
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)

	if self.current_state == self.state.none then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.prepare then
		if self.time_passed >= self.prepare_duration then
			self:change_state(self.state.move)
		end
	elseif self.current_state == self.state.move then
		if self.time_passed >= self.move_duration then
			self:change_state(self.state.move_interval)
		else

			local progress = self.time_passed / self.move_duration

			if self.current_phase == 2 then
				local move_pos_2_1 = vector_util.lerp(self.start_pos_2_1, vector(self.reset_marker_2_1.position.x ,self.move_height, self.reset_marker_2_1.position.z), progress)
				local move_pos_2_2 = vector_util.lerp(self.start_pos_2_2, vector(self.reset_marker_2_2.position.x ,self.move_height, self.reset_marker_2_2.position.z), progress)

				self.knight_list[1].Position = move_pos_2_1
				self.knight_list[2].Position = move_pos_2_2
			else
				local move_pos_3_1 = vector_util.lerp(self.start_pos_3_1, vector(self.reset_marker_3_1.position.x ,self.move_height, self.reset_marker_3_1.position.z), progress)

				self.knight_list[1].Position = move_pos_3_1
			end

		end
	elseif self.current_state == self.state.move_interval then
		if self.time_passed >= self.move_interval_duration then
			self:change_state(self.state.action)
		end
	elseif self.current_state == self.state.action then
		if self.time_passed >= self.action_duration then
			self:change_state(self.state.post)
		else
			local progress = self.time_passed / self.action_duration

			if self.current_phase == 2 then
				local move_pos_2_1 = vector_util.lerp(vector(self.reset_marker_2_1.position.x ,self.move_height, self.reset_marker_2_1.position.z),self.reset_marker_2_1.position, progress)
				local move_pos_2_2 = vector_util.lerp(vector(self.reset_marker_2_2.position.x ,self.move_height, self.reset_marker_2_2.position.z),self.reset_marker_2_2.position, progress)

				self.knight_list[1].Position = move_pos_2_1
				self.knight_list[2].Position = move_pos_2_2
			else
				local move_pos_3_1 = vector_util.lerp(vector(self.reset_marker_3_1.position.x ,self.move_height, self.reset_marker_3_1.position.z), self.reset_marker_3_1.position, progress)

				self.knight_list[1].Position = move_pos_3_1
			end
		end
	elseif self.current_state == self.state.post then
		if self.time_passed >= self.post_duration then
			self:change_state(self.state.none)
		end
	end
end

function local_class:dispose()
	self.cs_controller = nil

	if self.on_damage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.DamageEvent), self.on_damage_event_func)
		self.on_damage_event_func = nil
	end

	if self.on_stage_loaded_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.StageLoadedEvent), self.on_stage_loaded_event_func)
		self.on_stage_loaded_event_func = nil
	end

	if self.on_battle_start_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.BattleStartEvent), self.on_battle_start_event_func)
		self.on_battle_start_event_func = nil
	end

	if self.on_custom_stage_event_func ~= nil then
		CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.CustomStageEvent), self.on_custom_stage_event_func)
		self.on_custom_stage_event_func = nil
	end

end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
