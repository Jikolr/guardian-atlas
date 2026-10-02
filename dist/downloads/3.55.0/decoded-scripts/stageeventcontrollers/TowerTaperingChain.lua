local local_class = newclass("TowerTaperingChain")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local stage_infos = require('stageeventcontrollers/TowerTaperingChainData.lua')

	self.game_progress = {
		none = 1,
		playing = 2,
		failed = 3,
		wave_cleared = 4,
		cleared = 5
	}
	self.current_game_progress = self.game_progress.none
	self.current_wave = 1
	self.current_stage_info = stage_infos[stage.Name]
	self.current_spikes = {}
	self.boss_defeated = false
	self.zone_entered = false
	self.effect_instances = {}
	self.attack_ranges = {}

	self.execute_damage_type = CS.Utils.ParseDamageType(self.current_stage_info.damage_type, CS.Oak.DamageType.Trap)
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	local move_type = self.current_stage_info.move_type
	self:parse_spike_data(move_type)

	self.removing_effect = unity_object_pool.GetOrCreate(self.current_stage_info.effect)
	if self.current_stage_info.reset_effect ~= nil then
		self.reset_effect = unity_object_pool.GetOrCreate(self.current_stage_info.reset_effect)
	end

	-- 전투 타입에 맞는 이벤트 구독.
	-- 스크립트 파일을 분리 했었어야했다....
	if self.current_stage_info.move_type == 'group' then
		message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	else

		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')

		if self.current_stage_info.set_spike_on_wave_start then
			message_system:Subscribe(self, typeof(CS.Oak.BattleGroupSpawnNextWaveEvent), 'on_spawn_next_wave_event')
		end
	end
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	local key = lua_helper.get_or_default(self.current_stage_info.narration_info, nil)
	if key == nil then return end

	sp_util.play_normal_screenplay(field_ui_util.show_narration_async, { key = self.current_stage_info.narration_info })
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_stage_info.move_type ~= 'group' then return end

	local destroyed_object_name = e.FieldObject.Name
	local current_stage_boss_name = self.current_stage_info.boss

	if destroyed_object_name == current_stage_boss_name then
		self.current_game_progress = self.game_progress.clear
		self:remove_all_spikes()
	end
end

function local_class:on_zone_enter_event(e)
	if e.Zone.Name ~= self.current_stage_info.zone then return end
	if e.FieldObject ~= user_party_leader or not e.FullEnter then return end
	if self.zone_entered then return end

	self.current_game_progress = self.game_progress.playing
	self.zone_entered = true

	local triggered_event = util.cs_generator(self.update_spikes, self)
	coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
end

function local_class:on_damage_event(e)
	local required_damage_type = CS.Oak.DamageType.Trap

	if (e.Info.type & required_damage_type) == required_damage_type then
		if lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.SpikeBehaviour) or
				lua_helper.type_compare(e.Info.sender.FieldObjectBehaviour, CS.Oak.NullFieldObjectBehaviour)then
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = self.execute_damage_type
			damage_info.sender = user_party_leader
			damage_info.target = e.Info.target
			damage_info.damage = math.floor(e.Info.target.FieldObjectStatsBehaviour.MaxHP * self.current_stage_info.damage_rate)
			command_util.execute_damage(damage_info)
		end
	end
end

function local_class:on_battle_group_wave_clear_event(e)

	local current_wave = e.CurrentWave

	if self.current_stage_info.set_spike_on_wave_start then
		self.current_game_progress = self.game_progress.wave_cleared

		local previous_wave = self.current_stage_info.waves[current_wave + 1]

		for __, spike_group in ipairs(previous_wave) do
			for idx = 1, spike_group.spikes.count do
				local name = spike_group.spikes.name .. idx
				local spike = get_field_object(name)
				local instance = self.reset_effect:Instantiate(spike.Position)
				self.effect_instances[#self.effect_instances + 1] = instance
				spike.Position = vector(999, 0, 999)
				self.initial_spike_positions[name] = spike.Position
			end
		end

		return
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_next_wave, self, current_wave + 1))

end

function local_class:on_spawn_next_wave_event(e)

	if self.current_stage_info.set_spike_on_wave_start == false then
		return
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.set_next_wave, self, self.current_wave))
end

function local_class:set_next_wave(wave_idx)
	-- 이전 웨이브 스파이크들 리셋
	local previous_wave = self.current_stage_info.waves[wave_idx]

	for __, spike_group in ipairs(previous_wave) do
		for idx = 1, spike_group.spikes.count do
			local name = spike_group.spikes.name .. idx
			local spike = get_field_object(name)
			local instance = self.reset_effect:Instantiate(spike.Position)
			self.effect_instances[#self.effect_instances + 1] = instance
			spike.Position = vector(999, 0, 999)
			self.initial_spike_positions[name] = spike.Position
		end
	end

	self.current_wave = wave_idx + 1
	if self.current_wave <= self.total_wave_count then

		-- 다음 웨이브 타일들 준비
		local next_wave = self.current_stage_info.waves[self.current_wave]

		if self.current_stage_info.use_attack_range then
			for _, attack_range in pairs(self.attack_ranges) do
				if is_unity_null(attack_range) == false then
					attack_range:Hide()
					CS.UnityEngine.Object.Destroy(attack_range)
				end
			end
		end

		for _, spike_group in ipairs(next_wave) do
			for idx = 1, spike_group.spikes.count do
				local name = spike_group.spikes.name .. idx
				local spike = get_field_object(name)
				local init_pos = spike_group.init[idx]
				local instance = self.reset_effect:Instantiate(spike.Position)
				self.effect_instances[#self.effect_instances + 1] = instance
				spike.Position = vector(init_pos[1], init_pos[2], init_pos[3])
				self.initial_spike_positions[spike.Name] = spike.Position
			end
		end

		coroutine.yield()
		self.current_game_progress = self.game_progress.playing
		local triggered_event = util.cs_generator(self.update_spikes, self)
		coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
		music_player:PlaySfxOneShot('01_guild_warp_01')
	end

end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_stage_info.move_type ~= 'wave' then return end
	self.current_game_progress = self.game_progress.clear
	self:remove_all_spikes()
end

function local_class:update_spikes()
	wait_for_sec(0.3)
	local update_routines = {
		group = self.update_group_movement,
		wave = self.update_wave_movement
	}

	-- 현재 스테이지의 움직임 패턴 종류에 따른 업데이트 루틴 실행.
	local move_type = self.current_stage_info.move_type
	update_routines[move_type](self)
end

--[[
	그룹으로 체인을 움직일 시 업데이트 루틴
]]
function local_class:update_group_movement()
	while (self.current_game_progress ~= self.game_progress.clear) do
		for _, data in ipairs(self.current_stage_info.spikes) do
			local name = data.name
			local count = data.count

			for i = 1, count do
				local chain_name = name .. i
				local chain = get_field_object(chain_name)
				if chain ~= nil and self:destination_not_reached(chain, chain_name) then
					local new_x_pos = self:calc_moved_dist(data.x)
					local new_z_pos = self:calc_moved_dist(data.z)
					local move_vector = vector(new_x_pos, 0, new_z_pos)
					if move_vector.sqrMagnitude > 0 then
						CS.Oak.MoveOneFrameStageLogic.ExecuteMove(chain, move_vector)
					end
				end
			end
		end

		coroutine.yield(nil)
	end
end

--[[
	웨이브 별로 가시 블럭을 움직일 시 업데이트 루틴
]]
function local_class:update_wave_movement()
	local current_wave_data = self.current_stage_info.waves[self.current_wave]
	for __, spike_group in ipairs(current_wave_data) do
		for idx = 1, spike_group.spikes.count do
			local spike_name = spike_group.spikes.name .. idx
			local spike = get_field_object(spike_name)

			local triggered_event = util.cs_generator(self.move_spike, self, spike, spike_group.waypoints)
			coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
		end
	end
end


function local_class:parse_spike_data(move_type)
	-- Note: 새로운 종류의 패턴이 추가시 여기에 파싱 루틴 연결 해줄 것.
	local parse_routine = {
		group = self.parse_group_spikes,
		wave = self.parse_wave_spikes
	}

	parse_routine[move_type](self);
end

--[[
	그룹별 이동일 시 가시 블럭 데이터 파싱 루틴
]]
function local_class:parse_group_spikes()
	self.initial_spike_positions = {}

	for _, data in ipairs(self.current_stage_info.spikes) do
		local name = data.name
		local count = data.count

		for i = 1, count do
			local chain = get_field_object(name .. i)
			self.initial_spike_positions[name .. i] = chain.Position
		end
	end
end

--[[
	웨이브별 이동일 시 가시 블럭 데이터 파싱 루틴
]]
function local_class:parse_wave_spikes()
	self.initial_spike_positions = {}
	self.total_wave_count = #self.current_stage_info.waves

	for _, wave_data in ipairs(self.current_stage_info.waves) do
		for __, spike_data in ipairs(wave_data) do
			for idx, data in ipairs(spike_data) do
				local name = data.name .. idx
				local spike = get_field_object(name .. i)
				self.initial_spike_positions[name .. i] = spike.Position
			end
		end
	end
end

--[[
	보스를 처치 했을 시 가시 블럭들을 스테이지에서 없애는 루틴.
]]
function local_class:remove_all_spikes()

	-- 어텍 레인지로 미리 알려주기
	if self.current_stage_info.use_attack_range and self.current_wave + 1 <= self.total_wave_count then

		local next_wave = self.current_stage_info.waves[self.current_wave + 1]

		for _, spike_group in ipairs(next_wave) do
			for idx = 1, spike_group.spikes.count do
				local init_pos = spike_group.init[idx]
				local range = CS.AttackRange.CreateRect(vector(init_pos[1], init_pos[2] + 0.01, init_pos[3]), vector(0.90, 0.90), CS.Oak.AttackRangeShowType.OverlayForward)
				table.insert(self.attack_ranges, range)
			end
		end
	end

	self:remove_spikes(self:get_all_spikes())
	music_player:PlaySfxOneShot('02_explosion_01')
end

function local_class:remove_spikes(spikes)
	for _, name in ipairs(spikes) do
		local spike = get_field_object(name)
		if spike ~= nil then
			local instance = self.removing_effect:Instantiate(spike.Position)
			self.effect_instances[#self.effect_instances + 1] = instance
			spike.Position = vector(999, 999, 999)
			self.initial_spike_positions[spike.Name] = spike.Position
		end
	end
end

--[[
	움직임 거리를 계산해서 반환하는 루틴
]]
function local_class:calc_moved_dist(dir_adj)
	local cos = math.cos(math.rad(self.current_stage_info.angle))
	local speed = self.current_stage_info.speed

	return cos * dir_adj * speed * unity_class.time.deltaTime
end

--[[
	왔다 갔다 하는 루틴.
]]
function local_class:move_spike(spike, waypoint_data)
	if self.current_game_progress == self.game_progress.playing then
		self:move_spike_to(waypoint_data, spike,self.current_wave)
	end

	spike.Position = vector(999, 0, 999)
end

function local_class:move_spike_to(waypoints, spike, wave_num)
	local escape_routine = function()
		if self.current_wave ~= wave_num or self.current_game_progress ~= self.game_progress.playing then
			return true
		end
		return false
	end

	if #waypoints == 0 then
		while not escape_routine() do
			coroutine.yield(nil)
		end
		return
	end

	local idx = 1
	local waypoint = waypoints[idx][1]
	local speed = waypoints[idx][2]
	local spike_init_pos = self.initial_spike_positions[spike.Name]
	local dest = spike_init_pos + vector(waypoint.x, waypoint.y, waypoint.z)
	local direction = vector_util.get_x0z(dest - spike.Position).normalized
	local waiting = lua_helper.get_or_default(waypoints[idx][3], 1)

	while (not escape_routine()) do
		local magnitude = unity_class.time.deltaTime * speed
		local diff_magnitude = (dest - spike.Position).magnitude

		if magnitude < diff_magnitude then
			CS.Oak.MoveOneFrameStageLogic.ExecuteMove(spike, direction, magnitude)
		else
			if diff_magnitude > 0 then
				CS.Oak.MoveOneFrameStageLogic.ExecuteMove(spike, direction, diff_magnitude)
			end
			idx = (idx == #waypoints) and 1 or idx + 1
			waypoint = waypoints[idx][1]
			speed = waypoints[idx][2]
			waiting = lua_helper.get_or_default(waypoints[idx][3], 1)
			spike_init_pos = dest
			dest = spike_init_pos + vector(waypoint.x, waypoint.y, waypoint.z)
			direction = vector_util.get_x0z(dest - spike.Position).normalized
			wait_for_sec(waiting)
		end
		coroutine.yield(nil)
	end
end

--[[
	가시 체인이 설정된 거리만큼 이동했는지 확인하는 루틴.
]]
function local_class:destination_not_reached(fo, name)
	local current_pos = fo.Position
	local initial_pos = self.initial_spike_positions[name]
	local moved_distance = CS.UnityEngine.Vector3.Distance(current_pos, initial_pos)

	return (self.current_stage_info.distance > moved_distance)
end

--[[
	스테이지에 존재하는 가시 블럭들의 핸들 네임을 가져오는 루틴.
]]
function local_class:get_all_spikes()
	local routine_impl = {
		group = self.get_all_group_spikes,
		wave = self.get_all_wave_spikes
	}

	return routine_impl[self.current_stage_info.move_type](self)
end

function local_class:get_all_group_spikes()
	local spike_names = {}
	local spikes = self.current_stage_info.spikes

	for _, v in ipairs(spikes) do
		for i = 1, v.count do
			spike_names[#spike_names + 1] = v.name .. i
		end
	end

	return spike_names
end

function local_class:get_all_wave_spikes()
	local spike_names = {}
	local waves = self.current_stage_info.waves

	for _, wave in ipairs(waves) do
		for __, spike_group in ipairs(wave) do
			for i = 1, spike_group.spikes.count do
				spike_names[#spike_names + 1] = spike_group.spikes.name .. i
			end
		end
	end

	return spike_names
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	if self.current_stage_info.move_type == 'group' then
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	else

		if self.current_stage_info.set_spike_on_wave_start then
			message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupSpawnNextWaveEvent))
		end

		message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	end

	-- 생성했던 이펙트 인스턴스들 전부 dispose.
	for _, v in ipairs(self.effect_instances) do
		v:Dispose()
	end

	self.attack_ranges = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
