local local_class = newclass('OberonPowderController')

local powder = {
	state = {
		none = 1,
		activated = 2,
		post = 3
	},
	post_duration = 10,
	debuff_time = 0.5,
	debuff_table = {},
	active_count = 0,
	large_orb_enabled = false,

	option_id = 1000018,
	option_level = 80
}

function powder:change_state(next_state)
	--exit
	if self.current_state == self.state.activated then
		powder.active_count = powder.active_count - 1
		if powder.active_count == 0 and powder.ash ~= nil and not powder.large_orb_enabled then
			powder.ash:FadeOut(1)
			powder.ash = nil
		end
		unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_explosion_end'):Instantiate(self.position)
		self.calculator:End()

	elseif self.current_state == self.state.post then
		--remove fx
	end

	self.time_passed = 0
	self.current_state = next_state

	--enter
	if self.current_state == self.state.activated then
		if powder.active_count == 0 and powder.ash == nil then
			powder.ash = music_player_util.play_sfx({ sfx_name = '01_bugs_loop_03', play_pos = self.position, mix = 2, loop = true, type_priority = 'loop' })
		end
		powder.active_count = powder.active_count + 1
		music_player_util.play_sfx({ sfx_name = '02_explosion_dark_03', play_pos = self.position })
		music_player_util.play_sfx({ sfx_name = '01_out_sand_01', play_pos = self.position })
		self.calculator:Start()

	elseif self.current_state == self.state.post then
		--instantiate_fx
	end
end

function powder:late_update_frame(dt)

	self.time_passed = self.time_passed + dt

	if self.current_state == self.state.activated then
		if self.duration >= 0 and self.time_passed > self.duration then
			self:change_state(self.state.post)
		else
			local objects = self.calculator:UpdateFrame(dt)

			for index = 0, objects.Count - 1 do
				if (objects[index].EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
					self:apply_debuff(objects[index])
				end
			end

			objects:Dispose()
		end

	elseif self.current_state == self.state.post then
		if self.time_passed > self.post_duration then
			self:change_state(self.state.none)
		end
	end
end

function powder:apply_debuff(target)
	for i = 1, #self.debuff_table do
		if self.debuff_table[i].target == target then
			self.debuff_table[i].time_passed = 0
			return
		end
	end

	local option = CS.Oak.OptionManager.CreateOption(self.option_id, self.option_level)

	target.EliteOptions:Add(option)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.elite_option_refresh, self, target))

	local ui = {
		po = unity_object_pool.GetOrCreate('run_block_gauge'):Instantiate(target.Position, unity_class.quaternion.identity, target.Transform)
	}
	ui.immune_ui = ui.po:GetComponent(typeof(CS.Oak.FieldUIImmuneGauge))
	ui.immune_ui:Init(target)

	local debuff_info = {
		target = target,
		time_passed = 0,
		ui = ui,
		fx =
		unity_object_pool.GetOrCreate('fx_boss_oberon_debuff'):Instantiate(target.Position, unity_class.quaternion.identity, target.Transform),
		update_frame = function(this, dt)
			this.time_passed = this.time_passed + dt

			if this.target == nil or
					this.target.FieldObjectStatsBehaviour == nil or
					this.target.FieldObjectStatsBehaviour.IsDead then
				self:remove_debuff(this.target)
			elseif not this.is_manual and lua_helper.type_compare(this.target.FieldObjectController.CurrentState, CS.Oak.CharacterControllerManualTouchState) then
				this.target.FieldObjectController.CurrentState:RequestDisableControl(self.sender, CS.Oak.DisabledControls.Dash)
				this.is_manual = true
			end

			if this.time_passed > self.debuff_time then
				self:remove_debuff(this.target)
			else
				this.ui.immune_ui:SetValue((self.debuff_time - this.time_passed) / self.debuff_time)
			end
		end
	}

	local target_state = target.FieldObjectController.CurrentState
	if lua_helper.type_compare(target_state, CS.Oak.CharacterControllerManualTouchState) then
		target_state:RequestDisableControl(self.sender, CS.Oak.DisabledControls.Dash)
		debuff_info.is_manual = true
	end

	table.insert(self.debuff_table, debuff_info)
end

function powder:elite_option_refresh(target)
	yield_return_func(target.CharacterBehaviour.RefreshStageOptions,
			target.CharacterBehaviour)
end

function powder:check_contain_options(monster, option_id)
	for _,v in pairs(monster.FieldObjectBehaviour.StageOptions) do
		if v.Option.Id == option_id then
			return true
		end
	end
	return false
end

function powder:remove_debuff(target)
	local debuff_info = nil
	for i = 1, #self.debuff_table do
		if self.debuff_table[i].target == target then
			debuff_info = table.remove(self.debuff_table, i)
			break
		end
	end

	if debuff_info == nil or target == nil then
		return
	end
	debuff_info.ui.po:Dispose()
	debuff_info.fx:Dispose()

	for i = 0, target.EliteOptions.Count - 1 do
		if target.EliteOptions[i].Id == self.option_id then
			target.EliteOptions:RemoveAt(i)
			break
		end
	end
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.elite_option_refresh, self, target))

	local target_state = target.FieldObjectController.CurrentState
	if lua_helper.type_compare(target_state, CS.Oak.CharacterControllerManualTouchState) then
		target_state:RemoveDisableControl(self.sender)
	end
end

function local_class:remove_all_debuff()
	for i = #powder.debuff_table, 1, -1 do
		powder:remove_debuff(powder.debuff_table[i].target)
	end
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
	self.powder_duration = 5

	self.powder_table = {}
	self.last_powder_id = 1
	self.powder_orb_table = {}
	self.last_orb_id = 1

	self.small_orb_bound = CS.Oak.Hitbox(vector(1.5,0.1,1.5))
	self.small_orb_duration = -1
	self.small_orb_powder_radius = 4

	self.large_orb_bound = CS.Oak.Hitbox(vector(2.5,2.5,2.5))
	self.large_orb_duration = -1
	self.large_orb_powder_radius = 5
	self.large_orb_spec_id = 200006
	self.total_damage_modifier = 0.25
	self.total_damage_radius = 30
	self.hitbox_activation_duration = 3

	self.glow_count = 8
	self.fx_speed_modifier = 0.1

	self.buff_option_level = -13
	self.large_orb = nil
	self.large_orb_cache = nil
	self.max_damage_shake_count = 100
	self.damage_shake_count = 0
	self.shake_calculator = CS.Oak.ShakeCalculator()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.on_field_object_destroyed_event_func = function(e)
		self:on_field_object_destroyed_event(e)
	end
	CS.Oak.MessageSystem.Instance:Subscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_field_object_destroyed_event_func)
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_proj_loop')
	unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_proj_end')
	unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_loop')
	unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_end')
	unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_explosion_loop')
	unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_explosion_end')
	unity_object_pool.GetOrCreate('fx_boss_oberon_debuff')
	unity_object_pool.GetOrCreate('run_block_gauge')
	unity_object_pool.GetOrCreate('fx_boss_oberon_windwave_enhance')
	unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_loop_ring')

	self.large_orb_cache = get_character('oberon_giant_powder_orb')
end

function local_class:on_field_object_destroyed_event(e)
	if self.sender == nil then
		return
	end

	if e.FieldObject == self.sender or lua_helper.reference_equals(e.FieldObject, user_party.Leader) then
		local large_orb = self.large_orb
		local large_orb_cache = self.large_orb_cache

		-- 구체 오브젝트 미리 캐싱해두고 엘리트 옵션 다 제거
		self:remove_all_powder_orb()
		
		-- 이후 데미지를 주어 데미지가 온전하게 들어가게 함
		if not is_unity_null(large_orb) then
			large_orb.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Death
			damage_info.sender = self.sender
			damage_info.target = large_orb
			damage_info.damage = large_orb.CharacterStatsBehaviour.MaxHP * 10
			command_util.publish_damage(damage_info)
		elseif not is_unity_null(large_orb_cache) then
			large_orb_cache.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Death
			damage_info.sender = self.sender
			damage_info.target = large_orb_cache
			damage_info.damage = large_orb_cache.CharacterStatsBehaviour.MaxHP * 10
			command_util.publish_damage(damage_info)
		end
	else
		if not is_unity_null(self.large_orb) and self.large_orb == e.FieldObject then
			if (e.Destroyer.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
				self:remove_all_debuff()
			end

			self:remove_all_powder_orb()
		end
	end
end

function local_class:on_damage_event(e)
	if self.sender == nil then
		return
	end

	if not is_unity_null(self.large_orb)
			and self.large_orb_fx ~= nil
			and self.large_orb == e.Info.target
			and (e.Info.sender.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None
			and self.damage_shake_count < self.max_damage_shake_count then
		self.damage_shake_count = self.damage_shake_count + 1
		self.shake_calculator:Shake(0.1, 0.5)
	end
end

function local_class:on_custom_stage_event(e)
	if lua_helper.type_compare(e, CS.Oak.CustomStageEvent) then
		if e:GetParamAt(0) == 'instantiate_powder' then
			self.sender = e.Sender
			powder.sender = self.sender
			local position = self:string_to_vector(e:GetParamAt(1))
			local area_size = tonumber(e:GetParamAt(2))
			local duration = tonumber(e:GetParamAt(3))
			duration = duration ~= nil and duration or self.powder_duration
			self:instantiate_powder(position, area_size, duration)

		elseif e:GetParamAt(0) == 'remove_powder' then
			self.sender = e.Sender
			powder.sender = self.sender
			local id = tonumber(e:GetParamAt(1))
			self:remove_powder(id)

		elseif e:GetParamAt(0) == 'remove_all_powder' then
			self.sender = e.Sender
			powder.sender = self.sender
			self:remove_all_powder()

		elseif e:GetParamAt(0) == 'instantiate_powder_orb' then
			self.sender = e.Sender
			powder.sender = self.sender
			local position = self:string_to_vector(e:GetParamAt(1))
			local explosion_limit = tonumber(e:GetParamAt(2))
			local instantiate_duration = e:GetParamAt(3)
			if instantiate_duration ~= nil then
				instantiate_duration = tonumber(instantiate_duration)
			end

			local instantiate_modifier = e:GetParamAt(4)
			if instantiate_modifier ~= nil then
				instantiate_modifier = tonumber(instantiate_modifier)
			end

			self:instantiate_powder_orb(position, explosion_limit, instantiate_duration, instantiate_modifier)

		elseif e:GetParamAt(0) == 'remove_powder_orb' then
			self.sender = e.Sender
			powder.sender = self.sender
			local id = tonumber(e:GetParamAt(1))
			self:remove_powder_orb(id)

		elseif e:GetParamAt(0) == 'remove_all_powder_orb' then
			self.sender = e.Sender
			powder.sender = self.sender
			self:remove_all_powder_orb()

		elseif e:GetParamAt(0) == 'remove_all_debuff' then
			self.sender = e.Sender
			powder.sender = self.sender
			self:remove_all_powder_orb()

		elseif e:GetParamAt(0) == 'change_powder_owner' then
			self.sender = e.Sender

		end
	end
end

--'a, b, c' 형태의 string
function local_class:string_to_vector(str)
	local value_table = {}

	local start_idx = 1
	local idx = string.find(str, ',', start_idx)
	while idx ~= nil do
		table.insert(value_table, tonumber(string.sub(str, start_idx, idx - 1)))
		start_idx = idx + 2
		idx = string.find(str, ',', start_idx)
	end
	table.insert(value_table, tonumber(string.sub(str, start_idx)))

	if #value_table == 3 then
		return vector(value_table[1], value_table[2], value_table[3])
	end

	return vector(0,0,0)
end

function local_class:instantiate_powder(position, size, duration)
	local powder_instance = {
		position = position,
		time_passed = 0,
		current_state = powder.state.none,
		duration = duration,
	}

	local info = CS.Oak.CylinderCollisionInfo()
	info.Radius = size
	info.Duration = duration > 0 and duration or CS.System.Single.MaxValue
	info.DamageTerm = 0.1
	info.Center = vector(0,0,0)
	info.Height = 1.5

	local calculator = CS.Oak.AreaBattleCollision(self.sender, info)
	calculator.Position = position

	powder_instance.calculator = calculator

	powder_instance.id = self.last_powder_id + 1
	self.last_powder_id = powder_instance.id

	setmetatable(powder_instance, { __index = powder })
	table.insert(self.powder_table, powder_instance)

	powder_instance:change_state(powder_instance.state.activated)
end

function local_class:remove_powder(id)
	for i = 1, #self.powder_table do
		if self.powder_table[i].id == id then
			self.powder_table[i]:change_state(powder.state.none)
		end
	end
end

function local_class:remove_all_powder()
	for i = 1, #self.powder_table do
		self.powder_table[i]:change_state(powder.state.none)
	end
end

function local_class:instantiate_powder_orb(position, explosion_limit, instantiate_duration, instantiate_modifier)
	local is_large = explosion_limit > 0
	local powder_radius = is_large and self.large_orb_powder_radius or self.small_orb_powder_radius

	local info = CS.Oak.CylinderCollisionInfo()
	info.Radius = powder_radius
	info.Duration = 1
	info.DamageTerm = -1
	info.Center = position
	info.Height = 1.5

	local calculator = CS.Oak.AreaBattleCollision(self.sender, info)
	calculator.Position = position

	local powder_orb = {
		position = position,
		vfo = nil,
		fx = nil,
		powder_id = nil,
		time_passed = 0,
		calculator = calculator,
		explosion_limit = explosion_limit,
		range = CS.AttackRange.CreateCircle(position, powder_radius, CS.Oak.AttackRangeShowType.OverlayForward),
		powder_instantiate_duration = 2,
		powder_explosion_modifier = 1.05,
		duration = is_large and self.large_orb_duration or self.small_orb_duration,
		explosion_calculator = nil,
		update_frame = nil,
		explosion_delay = 1,
		explosion_update_frame = function(this, dt)

			this.time_passed = this.time_passed + dt
			if this.time_passed > this.explosion_delay then
				this.explode_attack_range:Hide()
				this:explode()
				self:remove_all_powder_orb()
			end
		end,
		normal_update_frame = function(this, dt)
			self:update_hp_bar(this)

			this.time_passed = this.time_passed + dt

			if this.explosion_limit <= 0 and this.time_passed > this.powder_instantiate_duration and this.time_passed - dt < this.powder_instantiate_duration then
				stage_camera:Shake(0.2, 0.5)
				this:instantiate_powder()
			end

			if this.duration >= 0 and this.time_passed > this.duration then
				self:remove_powder_orb(this.id)

			elseif this.explosion_limit > 0 and this.time_passed > this.explosion_limit then
				message_system:Publish(CS.Oak.AttackQueueEndEvent.Create(this.vfo))

				if this.vfo.DamagedBehaviour ~= nil then
					this.vfo.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
				end

				attack_range_util.setup_by_position(this.explode_attack_range, this.vfo.Position, 0.1)
				this.explode_attack_range:Show(this.explosion_delay)

				this.update_frame = this.explosion_update_frame
				this.time_passed = 0

				return
			elseif this.explosion_limit > 0 and this.time_passed > self.hitbox_activation_duration and this.time_passed - dt < self.hitbox_activation_duration then
				this.vfo.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()
				self.damage_shake_count = 0
			end
		end,
		instantiate_powder = function(this)
			this.range:Hide()
			message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.sender, this.range))
			this.calculator:Start()

			local objects = this.calculator:UpdateFrame(0)
			for index = 0, objects.Count - 1 do
				local fo = objects[index]

				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Melee
				damage_info.sender = self.sender
				damage_info.target = fo
				damage_info.modifier = this.powder_explosion_modifier

				command_util.execute_damage(damage_info)
			end
			objects:Dispose()

			this.calculator:End()

			this.fx:Dispose()
			this.fx = unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_explosion_loop'):Instantiate(this.position)

			self:instantiate_powder(this.position, powder_radius, -1)
			this.powder_id = self.last_powder_id
		end,
		explode = function(this)
			unity_object_pool.GetOrCreate('fx_boss_oberon_windwave_enhance'):Instantiate(this.position)
			music_player_util.play_sfx({ sfx_name = '02_explosion_dark_01', play_pos = this.position })

			this.explosion_calculator:Start()

			local objects = this.explosion_calculator:UpdateFrame(0)
			for index = 0, objects.Count - 1 do
				local fo = objects[index]
				if fo.Name ~= 'princess' and fo.Name ~= 'pixy_girl' then
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.IgnoreDefense | CS.Oak.DamageType.IgnoreOptions
					damage_info.sender = self.sender
					damage_info.target = fo
					damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * self.total_damage_modifier * #self.powder_orb_table)

					local ailment_info = CS.Oak.AilmentInfo()
					ailment_info.Ailment = CS.Oak.Ailment.Aerial
					ailment_info.AilmentGauge = 100
					damage_info:FillAilmentGauge(ailment_info, 1)
					damage_info.forceAilment = true

					command_util.execute_damage(damage_info)
				end
			end
			objects:Dispose()

			this.explosion_calculator:End()

		end
	}
	if instantiate_duration ~= nil then
		powder_orb.powder_instantiate_duration = instantiate_duration
	end

	if instantiate_modifier ~= nil then
		powder_orb.powder_explosion_modifier = instantiate_modifier
	end

	powder_orb.update_frame = powder_orb.normal_update_frame
	powder_orb.id = self.last_orb_id + 1
	self.last_orb_id = powder_orb.id

	local vfo = self:configure_vfo(is_large, powder_orb.id)
	vfo.Position = position
	powder_orb.vfo = vfo
	vfo.ActiveState = CS.Oak.ActiveState.Enabled

	self:set_hp_bar(powder_orb)

	table.insert(self.powder_orb_table, powder_orb)

	if not is_large then
		attack_range_util.setup_by_position(powder_orb.range, position, 0.1)
		powder_orb.range:Show(powder_orb.powder_instantiate_duration)
		message_system:Publish(CS.Oak.AttackRangeUpdateEvent.Create(self.sender, powder_orb.range))

		powder_orb.fx = unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_proj_loop'):Instantiate(powder_orb.position)
		music_player_util.play_sfx({ sfx_name = '02_wolf_explosion_01 02', play_pos = powder_orb.position })
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'powder_orb_created', tostring(powder_orb.id), position.x .. ', ' .. position.y .. ', ' .. position.z }))
		self:refresh_orb_option()
		self:refresh_large_orb_fx()
	else
		self.large_orb = powder_orb.vfo
		powder.large_orb_enabled = true
		if powder.ash == nil then
			powder.ash = music_player_util.play_sfx({ sfx_name = '01_bugs_loop_03', play_pos = powder_orb.position, loop = true, mix = 2, type_priority = 'loop' })
		end
		message_system:Publish(CS.Oak.AttackQueueStartEvent.Create(powder_orb.vfo, powder_orb.explosion_limit))
		message_system:Publish(CS.Oak.ShowBossHPEvent.Create(self.large_orb))

		info = CS.Oak.CylinderCollisionInfo()
		info.Radius = self.total_damage_radius
		info.Duration = 1
		info.DamageTerm = -1
		info.Center = position
		info.Height = 1.5

		powder_orb.explosion_calculator = CS.Oak.AreaBattleCollision(self.sender, info)
		powder_orb.explosion_calculator.Position = position

		powder_orb.explode_attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.total_damage_radius, CS.Oak.AttackRangeShowType.OverlayForward)

		stage_camera:Shake(0.2, 0.5)

		powder_orb.fx = unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_loop'):Instantiate(powder_orb.position)
		unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_loop_ring'):Instantiate(powder_orb.position)

		music_player_util.play_sfx({ sfx_name = '02_explosion_dark_02', play_pos = powder_orb.position })
		self.large_orb_fx = powder_orb.fx
		self.large_orb_transform = powder_orb.fx.transform

		self:init_large_orb_fx()
		self:refresh_large_orb_fx()
	end
end

function local_class:refresh_orb_option()
	if  is_unity_null(self.large_orb) then
		return
	end

	for i = 0, self.large_orb.EliteOptions.Count - 1 do
		if self.large_orb.EliteOptions[i].Id == powder.option_id then
			self.large_orb.EliteOptions:RemoveAt(i)
			break
		end
	end


	local option = CS.Oak.OptionManager.CreateOption(powder.option_id, self.buff_option_level * (#self.powder_orb_table - 1))

	self.large_orb.EliteOptions:Add(option)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			powder.elite_option_refresh, self, self.large_orb))
end

function local_class:init_large_orb_fx()
	self.glow_fx_table = {}
	local transform = self.large_orb_fx.transform:Find('size')

	for i = 1, self.glow_count do
		table.insert(self.glow_fx_table, transform:Find('glow_' .. i):GetComponent(typeof(CS.UnityEngine.ParticleSystem)))
	end

	self.speed_control_fx_table = {transform:Find('BG_smoke'):GetComponent(typeof(CS.UnityEngine.ParticleSystem)),
								   transform:Find('spark'):GetComponent(typeof(CS.UnityEngine.ParticleSystem)),
								   transform:Find('powder_spark'):GetComponent(typeof(CS.UnityEngine.ParticleSystem))}
end

function local_class:refresh_large_orb_fx()
	if is_unity_null(self.large_orb_fx) then
		return
	end

	for i = 1, self.glow_count do
		local prev = self.glow_fx_table[i].main.loop
		local current = i <= #self.powder_orb_table - 1

		self.glow_fx_table[i].main.loop = current
		if not prev and current then
			self.glow_fx_table[i]:Play()
		end
	end

	for i = 1, #self.speed_control_fx_table do
		self.speed_control_fx_table[i].main.simulationSpeed = 1 - self.fx_speed_modifier * (self.glow_count - #self.powder_orb_table + 1)
	end
end

function local_class:reset_large_orb_fx()
	for i = 1, self.glow_count do
		self.glow_fx_table[i].main.loop = true
	end

	for i = 1, #self.speed_control_fx_table do
		self.speed_control_fx_table[i].main.simulationSpeed = 1
	end
end

function local_class:configure_vfo(is_large, id)
	local vfo = nil
	if is_large then
		vfo = get_character('oberon_giant_powder_orb')
		-- 힐
		local heal_info = CS.Oak.HealInfo()
		heal_info.type = CS.Oak.HealType.Normal
		heal_info.heal = vfo.CharacterStatsBehaviour.MaxHP
		heal_info.isRevive = true
		heal_info.sender = self.sender
		heal_info.target = vfo

		vfo.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create()
		command_util.publish_heal(heal_info)
		vfo.SpineController:Hide(true)
		vfo.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance

		if user_party ~= nil then
			message_system:Publish(CS.Oak.MonsterNoticeEvent.Create(vfo, user_party.Leader, CS.Oak.MonsterNoticeLevel.Battle))
		end
	else
		vfo = CS.Oak.VirtualFieldObject()
		vfo.Name = "small_powder_orb_" .. id
		vfo.Hitbox = self.small_orb_bound
		vfo.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		vfo.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
		vfo.EntityGroup = CS.Oak.EntityGroups.Neutral0
	end


	return vfo
end

function local_class:remove_powder_orb(id)
	local target_orb = nil
	for i = 1, #self.powder_orb_table do
		if self.powder_orb_table[i].id == id then
			target_orb = table.remove(self.powder_orb_table, i)
			break
		end
	end

	if target_orb == nil then
		return
	end

	target_orb.range:Hide()
	message_system:Publish(CS.Oak.AttackRangeEndEvent.Create(self.sender, target_orb.range))

	if target_orb.explosion_limit > 0 then
		powder.large_orb_enabled = false
		target_orb.explode_attack_range:Hide()
		message_system:Publish(CS.Oak.AttackQueueEndEvent.Create(target_orb.vfo))
		if target_orb.update_frame == target_orb.normal_update_frame then
			message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'large_orb_destroyed', tostring(target_orb.id) }))
			self.large_orb = nil
			self.large_orb_cache = nil
			if powder.ash ~= nil then
				powder.ash:FadeOut(1)
				powder.ash = nil
			end
			music_player_util.play_sfx({ sfx_name = '02_explosion_dark_04', play_pos = target_orb.position })
			music_player_util.play_sfx({ sfx_name = '01_creature_15', play_pos = target_orb.position })

			self:reset_large_orb_fx()
			self.large_orb_fx = nil
			self.large_orb_transform = nil

			if not self.destroying_all then
				self:remove_all_powder_orb()
			end
		else
			if powder.ash ~= nil then
				powder.ash:FadeOut(1)
				powder.ash = nil
			end
			music_player_util.play_sfx({ sfx_name = '02_explosion_dark_01', play_pos = target_orb.position })
		end
	else
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'small_orb_destroyed', tostring(target_orb.id) }))
		self:refresh_orb_option()
		self:refresh_large_orb_fx()
	end

	if target_orb.explosion_limit < 0 and target_orb.fx ~= nil then
		target_orb.fx:Dispose()
		target_orb.fx = nil
		unity_object_pool.GetOrCreate('fx_boss_oberon_powderball_proj_end'):Instantiate(target_orb.vfo.Position)
	elseif target_orb.fx ~= nil then
		target_orb.fx:Dispose()
		target_orb.fx = nil
		unity_object_pool.GetOrCreate('fx_boss_oberon_giantpowderball_proj_end'):Instantiate(target_orb.vfo.Position)
	end
	target_orb.vfo.ActiveState = CS.Oak.ActiveState.Disabled
	--remove hp bar

	self:remove_powder(target_orb.powder_id)
end

function local_class:remove_all_powder_orb()
	self.destroying_all = true

	for i = #self.powder_orb_table, 1, -1 do
		self:remove_powder_orb(self.powder_orb_table[i].id)
	end

	self.destroying_all = false
end

function local_class:set_hp_bar(orb)
end

function local_class:update_hp_bar(orb)
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
	for i = #self.powder_table, 1, -1 do
		self.powder_table[i]:late_update_frame(dt)
		if self.powder_table.current_state == powder.state.none then
			table.remove(self.powder_table, i)
		end
	end

	for i = #self.powder_orb_table, 1, -1 do
		if self.powder_orb_table[i].update_frame ~= nil then
			self.powder_orb_table[i]:update_frame(dt)
		end
	end

	for i = #powder.debuff_table, 1, -1 do
		powder.debuff_table[i]:update_frame(dt)
	end

	if self.large_orb_fx ~= nil and not is_unity_null(self.large_orb) and self.shake_calculator.IsActive then
		self.shake_calculator:UpdateFrame(dt)
		self.large_orb_transform.position = self.large_orb.Position + self.shake_calculator.ShakeOffset
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	CS.Oak.MessageSystem.Instance:Unsubscribe(typeof(CS.Oak.FieldObjectDestroyedEvent), self.on_field_object_destroyed_event_func)
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
