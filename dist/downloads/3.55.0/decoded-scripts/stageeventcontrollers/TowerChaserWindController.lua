local local_class = newclass('TowerChaserWindController')

--region sand_storm
-- 추적 공격
local sand_storm = {
	owner = nil,
	start_fx_name = nil,
	loop_fx_name = nil,
	end_fx_name = nil,
	sfx = nil,
	attack_calculator = nil,
	fx = nil,
	offset = nil,
	pos = nil
}
sand_storm.mt = { __index = sand_storm }

function sand_storm:new(start_pos, damage_sender, offset, attack_calculator)
	local obj = {}
	setmetatable(obj, self.mt)

	obj.pos = start_pos + offset
	obj.owner = damage_sender
	obj.offset = offset
	obj.attack_calculator = attack_calculator

	if obj.start_fx_name then
		unity_object_pool.GetOrCreate(obj.start_fx_name):Instantiate(obj.pos)
	end
	obj.fx = unity_object_pool.GetOrCreate(obj.loop_fx_name):Instantiate(obj.pos)

	return obj
end

function sand_storm:set_param(start_fx_name, loop_fx_name, end_fx_name, damage_modifier, damage_term, knock_back_force)
	self.start_fx_name = start_fx_name
	self.loop_fx_name = loop_fx_name
	self.end_fx_name = end_fx_name
	self.damage_modifier = damage_modifier
	self.damage_term = damage_term
	self.knock_back_force = knock_back_force
end

function sand_storm:unset_param()
	self.start_fx_name = nil
	self.loop_fx_name = nil
	self.end_fx_name = nil
end

function sand_storm:set_position(pos, offset)
	if offset ~= nil then
		self.offset = offset
	end

	self.pos = pos + self.offset
	CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx, self.pos, unity_class.vector3.zero)
end

function sand_storm:process_damage(dt, leader_hit)
	local new_leader_hit = leader_hit

	self.attack_calculator.Position = self.pos
	local objects = self.attack_calculator:UpdateFrame(dt)
	for index = 0, objects.Count - 1 do
		local fo = objects[index]

		-- 타격 가능한 대상 인지 확인
		if not is_unity_null(fo) and not fo.FieldObjectStatsBehaviour.IsDead and not lua_helper.reference_equals(self.owner, fo)
				and CS.Oak.EntityGroupsExtensions.IsHittableTo(self.owner.EntityGroup, fo.EntityGroup) then
			local direction = (fo.Position - self.pos).normalized

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.IgnoreDefense
			damage_info.sender = self.owner
			damage_info.target = fo
			damage_info.modifier = self.damage_modifier
			damage_info.direction = direction
			damage_info.knockBackFactor = CS.Oak.DamageKnockBackConstants.FactorStrong
			damage_info.knockBackDirection = direction
			damage_info.knockBackForce = CS.Oak.DamageKnockBackConstants.StandardForce * self.knock_back_force

			command_util.execute_damage(damage_info)

			if lua_helper.reference_equals(fo, user_party.Leader) then
				if not new_leader_hit then
					new_leader_hit = true
					command_util.execute_damage(damage_info)
				end
			else
				command_util.execute_damage(damage_info)
			end
		end
	end
	objects:Dispose()

	return new_leader_hit
end

function sand_storm:terminate()
	if self.end_fx_name then
		unity_object_pool.GetOrCreate(self.end_fx_name):Instantiate(self.pos)
	end

	self:dispose()
end

function sand_storm:dispose()
	self.fx:Dispose()
	self.attack_calculator = nil

	self:unset_param()
end
--endregion

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	local controller_infos = require('stageeventcontrollers/TowerChaserWindControllerData.lua')
	local stage_name = stage.Name

	self.phase = {
		none = 0,
		phase0 = 1,
		phase1 = 2,
		phase2 = 3,
	}

	local controller_data = controller_infos[stage_name]
	if controller_data == nil then
		controller_data = controller_infos['default']
	end
	self.attack_range_show_duration = controller_data.attack_range_show_duration
	self.show_attack_range = (self.attack_range_show_duration and self.attack_range_show_duration > 0)
	self.idle_duration = controller_data.idle_duration
	self.max_death_count = controller_data.max_hit_count
	self.boss_name = controller_data.stage_boss_name
	self.wind_infos = controller_data.wind_infos
	self.on_start_description = controller_data.description

	local effect_infos = controller_data.effect_infos
	self.start_fx = effect_infos.effect_start_name
	self.loop_fx = effect_infos.effect_loop_name
	self.end_fx = effect_infos.effect_end_name
	sand_storm:set_param(effect_infos.effect_start_name, effect_infos.effect_loop_name, effect_infos.effect_end_name,
			controller_data.damage_modifier, controller_data.damage_term, controller_data.knock_back_force)

	-- start_info, loop_info, end_info
	self.sfx_infos = controller_data.sfx_infos
	self.sfx_infos.loop_info.loop = true
	self.sfx_infos.loop_info.type_priority = CS.Oak.SfxTypePriority.Loop

	self.attack_ranges = {}
	self.current_phase = self.phase.none
	self.boss = get_character(self.boss_name)

	unity_object_pool.GetOrCreate('FieldUICharacterState')
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEnterEvent), 'on_battle_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:init_fx()
	self:init_sfx()

	local marker = field:GetMarker('wind_0')
	if not CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(marker, typeof(CS.Oak.NullMarkerInfo)) then
		self.init_position = field:GetMarker('wind_0').position
	end
end

function local_class:init_fx()
	if self.start_fx then
		unity_object_pool.GetOrCreate(self.start_fx)
	end
	if self.loop_fx then
		unity_object_pool.GetOrCreate(self.loop_fx)
	end
	if self.end_fx then
		unity_object_pool.GetOrCreate(self.end_fx)
	end
end

function local_class:init_sfx()
	--self.sfx_infection = ''
	--music_player:PreloadSfx(self.sfx_infection)
end

function local_class:attach_count_ui()
	local leader = user_party.Leader

	local offset = vector(-0.24, leader.Bounds.size.y + 1, 0)
	local count_ui_object = unity_object_pool.GetOrCreate('FieldUICharacterState'):
	Instantiate(leader.Position + offset, unity_class.quaternion.identity, leader.Transform)
	self.count_ui = count_ui_object:GetComponent(typeof(CS.Oak.FieldUICharacterState))

	if self.count_ui == nil then
		return false
	end

	self.count_ui:Init(leader)
end

function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

function local_class:show_count_ui()
	if self.count_ui == nil then
		return
	end

	self.count_ui:Show()
	self.count_ui:HideIcon()
end

function local_class:hide_count_ui()
	if self.count_ui == nil then
		return
	end

	self.count_ui:Hide()
end

-- 카운트 UI 갱신
function local_class:update_count_ui()
	if self.count_ui == nil then
		return
	end

	self.count_ui.Count = self.current_count

	if self.max_death_count <= 1 then
		return
	end

	local danger_level = self.current_count / (self.max_death_count - 1)

	if danger_level <= 0.333 then
		self.count_ui.CountTextColor = unity_class.color.white
	elseif danger_level <= 0.66 then
		self.count_ui.CountTextColor = unity_class.color.yellow
	else
		self.count_ui.CountTextColor = unity_class.color.red
	end
end

function local_class:update_phase_switch()
	if self.boss == nil then
		return
	end

	local hp_rate = self.boss.FieldObjectStatsBehaviour.HP / self.boss.FieldObjectStatsBehaviour.MaxHP * 100

	local phase = 1
	for i,info in ipairs(self.wind_infos) do
		local hp = info.hp
		if hp_rate <= hp then
			phase = i + 1
		else
			break
		end
	end

	phase = math.fmod(phase, #self.wind_infos + 1)
	self:switch_phase(phase)
end

function local_class:on_stage_start_event(_)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{ key = self.on_start_description, stop_timer = true })
end

function local_class:on_battle_enter_event(e)
	if self.current_phase ~= self.phase.none then
		return
	end

	if self.boss == nil then
		return
	end

	if not e.Battle:IsInBattle(self.boss) then
		return
	end

	if not self.count_ui then
		self:attach_count_ui()
	end

	self.current_count = 0
	self:update_phase_switch()
	self:update_count_ui()
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_phase == self.phase.none then
		return
	end

	if self.boss == nil then
		return
	end

	if lua_helper.reference_equals(e.FieldObject, self.boss) or
			lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		self:switch_phase(self.phase.none)
		self.boss = nil
	end
end

function local_class:on_damage_event(e)
	if not lua_helper.reference_equals(e.Info.target, self.boss) then
		return
	end

	self:update_phase_switch()
end

function local_class:switch_phase(next_phase)
	if self.current_phase == next_phase then
		return
	end

	if self.current_phase == self.phase.none then
		self:show_count_ui()
		self:update_count_ui()
	else
		if next_phase == self.phase.none then
			self:hide_count_ui()
		end
		self:end_wind_phase()
	end

	if next_phase ~= self.phase.none then
		self.current_position = self.init_position and self.init_position or user_party.Leader.Position
		self:init_wind_info(self.wind_infos[next_phase])
	end

	if self.loop_sfx then
		self.loop_sfx:FadeOut(0)

		if self.sfx_infos.end_info.sfx_name then
			music_player_util.play_sfx(self.sfx_infos.end_info)
		end
	end

	self.current_phase = next_phase

	self.time_passed = 0
end

function local_class:init_wind_info(wind_info)
	self.current_wind_info = wind_info

	local info = CS.Oak.CylinderCollisionInfo()
	info.Center = unity_class.vector3.zero
	info.DamageTerm = sand_storm.damage_term
	info.Duration = CS.System.Single.MaxValue
	info.Radius = wind_info.radius
	info.Height = 3
	info.IsCenterToBottom = true
	self.attack_calculator = CS.Oak.AreaBattleCollision(self.boss, info)

	local wind_count = wind_info.wind_count

	if wind_count == 1 then
		local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero,
				wind_info.radius, CS.Oak.AttackRangeShowType.OverlayForward)
		attack_range_util.setup_by_position(attack_range, self.current_position)
		if self.show_attack_range then
			attack_range:Show(self.attack_range_show_duration)
		end
		message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.boss, attack_range))
		table.insert(self.attack_ranges, attack_range)
	else
		local angle = math.pi / wind_count * 2
		local orbit = wind_info.orbit

		for i = 1, wind_count do
			local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero,
					wind_info.radius, CS.Oak.AttackRangeShowType.OverlayForward)
			local offset = unity_class.vector3(math.sin(angle * i), 0, math.cos(angle * i)) * orbit
			attack_range_util.setup_by_position(attack_range, self.current_position + offset, self.current_position.y)
			if self.show_attack_range then
				attack_range:Show(self.attack_range_show_duration)
			end
			message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.boss, attack_range))
			table.insert(self.attack_ranges, attack_range)
		end
	end
end

function local_class:end_wind_phase()
	if self.current_phase == self.phase.none then
		return
	end

	if self.chaser then
		for i, storm in ipairs(self.chaser) do
			storm:terminate()
			self.chaser[i] = nil
		end
		self.chaser = nil
	end

	self.attack_calculator:End()

	local num_attack_ranges = #self.attack_ranges
	for i = num_attack_ranges, 1, -1 do
		local attack_range = self.attack_ranges[i]
		attack_range:Hide()
		message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.boss, attack_range))
		table.remove(self.attack_ranges, i)
	end
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame(dt)
	if self.current_phase == nil or self.current_phase == self.phase.none then
		return
	end

	local leader = user_party.Leader

	if is_unity_null(leader) then
		return
	end

	self.time_passed = self.time_passed + dt

	if self.time_passed < self.attack_range_show_duration then
		return
	end

	if self.chaser == nil then
		self.attack_calculator:Start()

		self.chaser = {}
		for _, attack_range in ipairs(self.attack_ranges) do
			attack_range:Hide()
			local offset = attack_range.CacheTransform.position - self.current_position
			local storm = sand_storm:new(self.current_position, self.boss, offset, self.attack_calculator)
			table.insert(self.chaser, storm)
		end

		if self.sfx_infos.start_info.sfx_name then
			music_player_util.play_sfx(self.sfx_infos.start_info)
		end
		if self.sfx_infos.loop_info.sfx_name then
			self.loop_sfx = music_player_util.play_sfx(self.sfx_infos.loop_info)
		end
	end

	if self.time_passed >= self.attack_range_show_duration + self.idle_duration then
		local move_dist = self.current_wind_info.move_speed * dt
		local target_direction_vector = (leader.Position - self.current_position):GetX0z().normalized
		self.current_position = self.current_position + target_direction_vector * move_dist
	end

	local angle = math.pi / #self.chaser * 2
	local orbit = self.current_wind_info.orbit
	local rotate_amount = (self.time_passed - self.attack_range_show_duration) * self.current_wind_info.orbital_speed
	local is_hit = false
	for i, storm in ipairs(self.chaser) do
		local offset = unity_class.vector3(math.sin(angle * i + rotate_amount), 0, math.cos(angle * i + rotate_amount)) * orbit
		storm:set_position(self.current_position, offset)
		local delta_time = i == 1 and dt or 0
		if storm:process_damage(delta_time) then
			is_hit = true
		end
	end

	if is_hit then
		self.current_count = self.current_count + 1
		self:update_count_ui()

		if self.current_count == self.max_death_count then
			self:kill_player()
		end
	end
end

function local_class:kill_player()
	local target = user_party.Leader
	self.current_count = 0

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Death
	damage_info.sender = target
	damage_info.target = target
	damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	command_util.publish_cmd(damage_info.Owner, cmd)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self:switch_phase(self.phase.none)
	self:detach_count_ui()

	self.cs_controller = nil
	self.scene = nil
	self.phase = nil
	self.current_phase = nil
	self.boss = nil

	self.attack_range_0 = nil
	self.attack_range_1 = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
