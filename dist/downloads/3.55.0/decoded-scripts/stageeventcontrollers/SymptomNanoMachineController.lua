local local_class = newclass('SymptomNanoMachineController')

--흡혈 구술 생성 및 해제
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}

	self.stage_data = require('stageeventcontrollers/SymptomNanoMachineControllerData.lua')
	self.current_stage_info = nil

	self.time_passed = 0
	self.boss_character = nil
	self.nano_box_list = nil
	self.buff_holder = nil
	self.nano_box_info_list = nil
	self.nano_box_regen_count = 0

	self.drone_fx_name = "cw_drone_demonengineer"
	self.fail_fx_name = "FX_dead"
	self.regen_fx_name = "FX_Object_Twinkle"

	self.drone_state = {
		none = 1,
		move_in = 2,
		interval = 3,
		move_out = 4
	}

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	self.current_stage_info = self.stage_data[stage.Name]
	self.buff_holder = stage:GetCharacter('buff_holder')

	self.zone = field:GetZone(self.current_stage_info.zone_name)

	self.nano_box_info_list = {}
	for i = 1, self.current_stage_info.box_max_count do
		local box = get_field_object(self.current_stage_info.box_name .. i)

		table.insert(self.nano_box_info_list, {
			index = i,
			box = box,
			is_active = false,
			time_passed = 0,
			pos = nil
		})
	end

	self.drone_list = {}

	---- 오브젝트 풀 미리 로드
	unity_object_pool.GetOrCreate(self.drone_fx_name)
	unity_object_pool.GetOrCreate(self.fail_fx_name)
	unity_object_pool.GetOrCreate(self.regen_fx_name)
	self.drone_fx_pool = function() return unity_object_pool.GetOrCreate(self.drone_fx_name) end
	self.fail_fx_pool = function() return unity_object_pool.GetOrCreate(self.fail_fx_name) end
	self.regen_fx_pool = function() return unity_object_pool.GetOrCreate(self.regen_fx_name) end
	music_player:PreloadSfx('01_propeller_03')
	music_player:PreloadSfx('03_dialogue_worker_03')
	music_player:PreloadSfx('02_explosion_01')
	music_player:PreloadSfx('04_dialogue_vinette_01')

	self.current_regen_count = 0
	self.dron_loop_sfx = nil

	self.current_progress = self.progress.none

	return
end

--런치루틴 사용 안함.
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)

end

function local_class:get_sfx_name(origin_name)
	if music_player.CurrentVoiceLanguage ~= 'ko' then
		return origin_name .. '_' .. music_player.CurrentVoiceLanguage
	end

	return origin_name
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'interacting' then
		self:heal()

		for _,v in pairs(self.nano_box_info_list) do
			if v.box ~= nil then
				if lua_helper.reference_equals(e.Sender, v.box) then
					self:remove_nano_box(v)
				end
			end
		end
	end

	if e:GetParamAt(0) == 'charge_hit_nano_box' then
		for _,v in pairs(self.nano_box_info_list) do
			if v.box ~= nil then
				if v.box.Name == e:GetParamAt(1) then
					self:remove_nano_box(v)
				end
			end
		end
	end

	if e:GetParamAt(0) == 'start_battle_symptom' then
		self.boss_character = get_character(e:GetParamAt(1))
		self.current_progress = self.progress.playing
	end

	if e:GetParamAt(0) == 'ready_outgassing' then
		self.is_drone_regen_max_count = true
	end
end

function local_class:remove_nano_box(info)
	info.box.Position = vector(999, 0, 999)
	info.is_active = false
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character,{'remove_nano_box', info.index}))
	if info.regen_effect ~= nil then
		info.regen_effect:Dispose()
		info.regen_effect = nil
	end
	self.fail_fx_pool():Instantiate(info.box_pos)
	music_player_util.play_sfx_one_shot('02_explosion_01')
	info.time_passed = 0
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party_leader, self.current_stage_info.zone_name) then
		self.current_progress = self.progress.playing
		return true
	end
end

function local_class:on_battle_start_event(e)
	--self.current_progress = self.progress.playing
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none

	for _,v in pairs(self.nano_box_info_list) do
		if v.box ~= nil then
			v.box.Position = vector(999, 0, 999)
		end
		v.is_active = false
		if v.regen_effect ~= nil then
			v.regen_effect:Dispose()
			v.regen_effect = nil
		end
		v.time_passed = 0

		if v.box_pos then
			self.fail_fx_pool():Instantiate(v.box_pos)
		end

		message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character,{'remove_nano_box', v.index}))
	end
end

function local_class:heal()
	for _,v in pairs(user_party) do
		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = math.floor(v.FieldObjectStatsBehaviour.MaxHpWoMod * self.current_stage_info.heal_ratio)
		heal_info.isRevive = false
		heal_info.sender = self.buff_holder
		heal_info.target = v

		local cmd = CS.Oak.HealCommand.Create(heal_info)
		command_util.publish_cmd(heal_info.Owner, cmd)
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end

	self.time_passed = self.time_passed + dt

	self:update_nano_box(dt)
	self:update_drone(dt)

	if self.time_passed > self.current_stage_info.regen_duration and
			self.current_regen_count < self.current_stage_info.max_regen_count then
		self.time_passed = 0
		self:drone_regen()
	end
end

function local_class:update_nano_box(dt)
	if self.nano_box_info_list == nil then return end

	for _,v in pairs(self.nano_box_info_list) do
		if v.is_active then
			if user_party[0] ~= nil then
				local dist = (v.box.Position - user_party[0].Position).magnitude

				if math.abs(dist) < 1 then
					self:heal()
					self:remove_nano_box(v)
				end
			end

			if v.time_passed > self.current_stage_info.box_duration then
				v.box.Position = vector(999, 0, 999)
				v.is_active = false
				message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character,{'remove_nano_box', v.index}))
				if v.regen_effect ~= nil then
					v.regen_effect:Dispose()
					v.regen_effect = nil
				end
				self.fail_fx_pool():Instantiate(v.box_pos)
				v.time_passed = 0
			end
			v.time_passed = v.time_passed + dt
		end
	end
end

function local_class:drone_regen()
	self.current_regen_count = self.current_regen_count + 1
	local pos = self:get_regen_position()
	local regen_pos = pos  + vector(0, self.current_stage_info.drone_regen_height, 0)

	local drone = self.drone_fx_pool():Instantiate(regen_pos)
	local drone_spine = drone.transform:GetComponent(typeof(CS.Oak.SpineController))
	drone_spine:SetAnimation(1, "idle", false, 1, nil, nil, "idle")

	music_player_util.play_sfx_one_shot('03_dialogue_worker_03')
	self.dron_loop_sfx = music_player_util.play_sfx({ sfx_name = '01_propeller_03', loop = true, fade_in_time = 1 })

	table.insert(self.drone_list,{
		drone = drone,
		time_passed = 0,
		is_active = true,
		start_pos = regen_pos,
		target_pos = pos + vector(0, self.current_stage_info.drone_box_height, 0),
		box_pos = pos,
		current_pos = regen_pos,
		state = self.drone_state.move_in,
		move_duration = 1,
	})
end

function local_class:update_drone(dt)
	for i = #self.drone_list, 1, -1 do
		local drone_info = self.drone_list[i]
		if drone_info.is_active then
			drone_info.time_passed = drone_info.time_passed + dt
			if drone_info.state == self.drone_state.move_in then
				local progress = drone_info.time_passed / self.current_stage_info.drone_move_duration
				if progress > 1 then
					local drone_spine = drone_info.drone.transform:GetComponent(typeof(CS.Oak.SpineController))
					drone_spine:SetAnimation(1, "drop", false, 1, nil, nil, "idle")

					music_player_util.play_sfx_one_shot('02_explosion_01')
					self:box_regen(drone_info.box_pos)
					drone_info.state = self.drone_state.interval
					drone_info.time_passed = 0
					--좌 우 벽이 가까운쪽으로 이동 후 사라짐
					drone_info.start_pos = drone_info.current_pos
					drone_info.target_pos = self:get_drone_out_position(drone_info.current_pos)
					self.dron_loop_sfx:FadeOut(1)
				else
					local move_pos = vector_util.lerp(drone_info.start_pos, drone_info.target_pos, progress)
					drone_info.drone.transform.position = move_pos
					drone_info.current_pos = move_pos
				end
			elseif drone_info.state == self.drone_state.interval then
				if drone_info.time_passed > self.current_stage_info.drone_move_interval_duration then
					drone_info.state = self.drone_state.move_out
					drone_info.time_passed = 0
				end
				elseif drone_info.state == self.drone_state.move_out then
				local progress = drone_info.time_passed / self.current_stage_info.drone_move_duration
				if progress > 1 then
					--TODO:드론 종료
					drone_info.is_active = false
					drone_info.time_passed = 0
					if drone_info.drone ~= nil then
						drone_info.drone:Dispose()
						drone_info.drone = nil
					end
				else
					local move_pos = vector_util.lerp(drone_info.start_pos, drone_info.target_pos, progress)
					drone_info.drone.transform.position = move_pos
					drone_info.current_pos = move_pos
				end
			end
		end
	end
end

function local_class:get_drone_out_position(pos)
	local out_pos = self.zone.Bounds.center
	if pos.x > self.zone.Bounds.center.x then
		out_pos = vector(self.zone.Bounds.max.x + 5, 5, 0)
	else
		out_pos = vector(self.zone.Bounds.min.x - 5, 5, 0)
	end

	return out_pos
end

function local_class:box_regen(pos)
	if self.current_regen_count == self.current_stage_info.max_regen_count then
		if music_player.CurrentVoiceLanguage == 'ko' then
			music_player:PlaySfxOneShot(self:get_sfx_name('04_dialogue_vinette_01'))
		end
	end

	local regen_effect = self.regen_fx_pool():Instantiate(pos)
	local info = self:get_box_info()
	info.box.Position = pos
	info.is_active = true
	info.box_pos = pos
	info.regen_effect = regen_effect
	self.nano_box_regen_count = self.nano_box_regen_count + 1

	self.fail_fx_pool():Instantiate(pos)
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.character,{'regen_nano_box',
	                                                                      info.index, pos.x, pos.y, pos.z, self.nano_box_regen_count}))
end

function local_class:get_regen_position()
	--생성규칙
	--1. 존 외각으로 부터 2거리 떨어져서
	--2. 보스로부터 3거리 떨어져서
	--3. 다른박스로부터 2거리 떨어져서
	--4. 캐릭터 반경 이내 regen_range

	local random_angle = unity_class.random.Range(0, 360)
	local random_range = unity_class.random.Range(1, self.current_stage_info.regen_range)
	local dir = unity_class.quaternion.Euler(0, random_angle, 0) * unity_class.vector3.forward
	local start_pos = self.zone.Bounds.center
	if user_party[0] ~= nil then
		start_pos = user_party[0].Position
	end
	local pos = start_pos + dir * random_range

	pos = self:check_position_by_box(pos)
	if self.boss_character ~= nil then
		pos = self:check_position_by_boss(pos)
	end
	pos = self:check_position_by_wall(pos)

	return pos
end

function local_class:check_position_by_box(dest_pos)
	local final_pos = dest_pos
	local box_pos = self:get_active_box_position()
	if box_pos ~= nil then
		local diff = box_pos - dest_pos
		local dist = diff.magnitude

		if math.abs(dist) < self.current_stage_info.box_range then
			final_pos = box_pos + diff.normalized * self.current_stage_info.box_range
		end
	end

	return final_pos
end

function local_class:get_active_box_position()
	for _,v in pairs(self.nano_box_info_list) do
		if v.is_active then
			return v.box.Position
		end
	end

	return nil
end

function local_class:check_position_by_boss(dest_pos)
	local final_pos = dest_pos
	local diff = self.boss_character.Position - dest_pos
	local dist = diff.magnitude

	if math.abs(dist) < self.current_stage_info.boss_range then
		final_pos = self.boss_character.Position + diff.normalized * self.current_stage_info.boss_range
	end

	return final_pos
end

function local_class:check_position_by_wall(dest_pos)
	local final_dest_pos = dest_pos
	if dest_pos.x <= self.zone.Bounds.min.x + self.current_stage_info.wall_offset then
		final_dest_pos.x = self.zone.Bounds.min.x + self.current_stage_info.wall_offset
	end
	if dest_pos.x >= self.zone.Bounds.max.x - self.current_stage_info.wall_offset then
		final_dest_pos.x = self.zone.Bounds.max.x - self.current_stage_info.wall_offset
	end
	if dest_pos.z <= self.zone.Bounds.min.z + self.current_stage_info.wall_offset then
		final_dest_pos.z = self.zone.Bounds.min.z + self.current_stage_info.wall_offset
	end
	if dest_pos.z >= self.zone.Bounds.max.z - self.current_stage_info.wall_offset then
		final_dest_pos.z = self.zone.Bounds.max.z - self.current_stage_info.wall_offset
	end

	return final_dest_pos
end

function local_class:get_box_info()
	for _,v in pairs(self.nano_box_info_list) do
		if not v.is_active then
			return v
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
	self.manual_character = nil

	self.current_stage_info = nil
	self.buff_holder = nil
	self.boss_character = nil
	self.zone = nil
	self.nano_box_info_list = nil
	self.drone_list = nil
	self.drone_fx_pool = nil
	self.fail_fx_pool = nil
	self.regen_fx_pool = nil
	self.nano_box_list = nil
	self.drone_fx_name = nil
	self.fail_fx_name = nil
	self.regen_fx_name = nil
	self.drone_state = nil
end



return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
