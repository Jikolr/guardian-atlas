local local_class = newclass('CoopExpeditionMagatamaController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.stage_data = require('stageeventcontrollers/CoopExpeditionMagatamaData.lua')

	self.marker_list = nil
	self.info_list = {}
	self.vfo_pool_list = nil
	self.user_character = nil
	self.boss_character = nil

	self.spawn_time_passed = 0

	self.current_spawn_count = 0
	self.revival_fo_list = nil
	self.active_revival_fo_list = {}

	self.state = {
		none = 0,
		battle = 1,
		battle_end = 3
	}

	self.fx_enabled = false
	self.buff_added_info = {}
	self.current_state = self.state.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BuffExpiredEvent), 'on_buff_expired_event')
	--AI에서 1페이즈인지 2페인지 구분해서 스타트을 주도록 해야 할 것 같은데?

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_buff_expired_event(e)
	if e.BuffIds:Contains(self.current_stage_info.buff_id) then
		self.buff_added_info[e.Target] = nil
	end
end


function local_class:on_load_resource()
	self.current_stage_info = self.stage_data[stage.Name]

	self.spawn_time_passed = self.current_stage_info.spawn_time

	self.user_character = CS.Oak.CoopClient.Instance.MyCharacter
	self.boss_character = get_character(self.current_stage_info.boss_name)

	self:init_markers()
	self:set_gogok()

	self.buff_vfo = CS.Oak.VirtualFieldObject()
	self.buff_vfo.Hitbox = CS.Oak.Hitbox(vector(1,1,1))
	self.buff_vfo.CrashBehaviour = CS.Oak.MonsterCrashBehaviour.Instance
	self.buff_vfo.EntityGroup = CS.Oak.EntityGroups.Enemy0
	self.buff_vfo.ActiveState = CS.Oak.ActiveState.Enabled
	self.buff_vfo.Position = vector(999, 0, 999)

	self:init_revival_area()
	unity_object_pool.GetOrCreate('fx_gogok_zone_end')
	unity_object_pool.GetOrCreate('fx_gogok_zone_light')
end

function local_class:add_buff(target)
	if not self:check_buff(target) then
		self.buff_added_info[target] = true
		buff_manager:AddBuff(self.buff_vfo, CS.Oak.EquipmentSlot.None, target,
				self.current_stage_info.buff_id, self.current_stage_info.buff_level, false, false)
	end
end

function local_class:check_buff(target)
	return self.buff_added_info[target]
end

function local_class:init_markers()
	self.marker_list = {}
	for i = 1, self.current_stage_info.marker_count do
		local name = self.current_stage_info.marker_name .. i
		local marker = CS.Oak.Stage.Instance.Field:GetMarker(name)
		table.insert(self.marker_list,
				{marker = marker,
				 marker_name = name
				})
	end

	self:set_marker_random()
end

function local_class:set_gogok()
	self.gogok_fo_list = {}
	for i = 1, self.current_stage_info.gogok_count do
		local name = self.current_stage_info.gogok_name .. i
		local gogok = get_field_object(name)
		table.insert(self.gogok_fo_list,
				{
					index = i,
					gogok = gogok,
					name = name
				})
	end

	self:set_marker_random()
end

function local_class:init_revival_area()
	self.revival_area_info_list = {}
	for i = 1, self.current_stage_info.revival_area_max_count do
		local fo_name = self.current_stage_info.revival_area_name .. i
		local fo = get_field_object(fo_name)
		table.insert(self.revival_area_info_list, {
	name = fo_name,
	fo = fo,
	is_active = false,
	time_passed = 0,
	marker_info = nil
	})
	end
end

function local_class:get_revival_area_fo()
	if #self.revival_area_info_list > 0 then
		return table.remove(self.revival_area_info_list)
	else
		return nil
	end
end

function local_class:return_revival_area_fo(info)
	info.is_active = false
	info.time_passed = 0
	message_system:Publish(CS.Oak.CoopExpeditionHealAreaEvent.Create(info.name, false))

	self:remove_marker(info.marker_info)
	table.insert(self.revival_area_info_list, info)
end

function local_class:active_revival_area(marker_info)
	local ra = self:get_revival_area_fo()
	ra.fo.Position = marker_info.marker.position + vector(-0.5, 0, -0.5)
	ra.is_active = true
	ra.marker_info = marker_info
	ra.time_passed = 0
	table.insert(self.active_revival_fo_list, ra)
	message_system:Publish(CS.Oak.CoopExpeditionHealAreaEvent.Create(ra.name, true))
end


function local_class:set_marker_random()
	self.marker_list = random_util.get_values_in_array(self.marker_list,
			{count = #self.marker_list})
end

function local_class:spawn_stone(marker_names)
	--거기에 맞춰서 생성되도록 변경 필요
	if self.current_spawn_count < self.current_stage_info.max_count then
		for i = 1, self.current_stage_info.spawn_count do
			local marker_info = self:get_marker(marker_names[i])

			if marker_info == nil then
				return
			end

			local gogok_fo = self:get_gogok_fo()
			gogok_fo.gogok.Position = marker_info.marker.position + vector(-0.5, 0, -0.5)

			table.insert(self.info_list, {
				gogok_fo = gogok_fo,
				pos = marker_info.marker.position,
				marker_info = marker_info,
				is_add_buff = false,
				fx = self.fx_enabled
						and unity_object_pool.GetOrCreate('fx_gogok_zone_light'):Instantiate(marker_info.marker.position)
						or nil
			})

			self.current_spawn_count = self.current_spawn_count + 1
		end
	end
end

function local_class:explosion_stone(marker_name, pos, target)
	for i = #self.info_list, 1, -1 do
		local info = self.info_list[i]
		if info.marker_info.marker_name == marker_name then
			self:apply_damage(target)
			if info.fx ~= nil then
				info.fx:Dispose()
				info.fx = nil
			end
			unity_object_pool.GetOrCreate('fx_gogok_zone_end'):Instantiate(info.marker_info.marker.position)
			music_player_util.play_sfx({ sfx_name = '01_break_cube_01' })
			music_player_util.play_sfx({ sfx_name = '01_firefly_04' })

			--생성 카운트 누적으로 더이상 생성되지 않도록
			--self.current_spawn_count = self.current_spawn_count - 1

			--부활장판 마커는 반환하지 않는다.
			if #self.revival_area_info_list > 0 then
				self:active_revival_area(info.marker_info)
			else
				self:remove_marker(info.marker_info)
			end

			self:remove_gogok_pool_fo(info.gogok_fo)

			table.remove(self.info_list, i)
		end
	end
end

function local_class:get_gogok_fo()
	return table.remove(self.gogok_fo_list)
end

function local_class:remove_gogok_pool_fo(v)
	v.gogok.Position = vector(999, 0, 999)
	if v.fx ~= nil then
		v.fx:Dispose()
		v.fx = nil
	end

	table.insert(self.gogok_fo_list, v)
end

function local_class:get_marker(marker_name)
	if #self.marker_list > 0 then
		if marker_name ~= nil then
			for _,v in pairs(self.marker_list) do
				if v.marker_name == marker_name then
					return table.remove(self.marker_list, _)
				end
			end
		else
			return table.remove(self.marker_list)
		end
	else
		return nil
	end
end

function local_class:remove_marker(marker)
	table.insert(self.marker_list, marker)
end

function local_class:on_damage_event(e)
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'start_magatama_event' then
		self.current_state = self.state.battle
		return true
	end
	return false
end

--- 보스에게 퍼뎀 피해
function local_class:apply_damage(target)
	--- 데미지 정보 생성
	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.IgnoreDefense | CS.Oak.DamageType.IgnoreOptions
	damage_info.sender = target
	damage_info.target = target
	damage_info.damage = math.floor(target.FieldObjectStatsBehaviour.MaxHP
			* self.current_stage_info.damage_rate)

	command_util.publish_damage(damage_info)
end

function local_class:on_battle_start_event(e)
	if self.current_stage_info ~= nil and self.current_stage_info.is_active then
		self.current_state = self.state.battle
	end
end

function local_class:on_battle_end_event(e)
	--구슬 삭제, 버프제거
	if self.info_list ~= nil then
		for i = #self.info_list, 1, -1 do
			local info = self.info_list[i]

			if info.fx ~= nil then
				info.fx:Dispose()
				info.fx = nil
			end

			self:remove_marker(info.marker_info)
			self:remove_gogok_pool_fo(info.gogok_fo)

			table.remove(self.info_list, i)
		end

		for i = #self.active_revival_fo_list, 1, -1 do
			self:return_revival_area_fo(table.remove(self.active_revival_fo_list, i))
		end

		self.current_state = self.state.none
	end
end

function local_class:on_zone_enter_event(e)
	--stageinfo에 있는 이름이라면 기믹 시작
	if self.current_stage_info ~= nil then
		if type_util.is_zone_full_enter(e, self.user_character, self.current_stage_info.zone_name) then
			if self.current_state ~= self.state.battle then
				self.current_state = self.state.battle
			end
		end

	end
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

function local_class:late_update_frame(dt)
	if self.current_state ~= self.state.battle then return end

	self:update_hit_monster(dt)
	self:update_hit_character(dt)
	self:validate_buff_info()
	self:update_revival_area(dt)

	self:update_fx()

	if self.spawn_time_passed > 0 then
		self.spawn_time_passed = self.spawn_time_passed - dt
	else
		self.spawn_time_passed = self.current_stage_info.spawn_time
		local info = CS.Oak.StageEventControllerSyncInfo()
		info.Strings:Add("Spawn_Stone")
		local names = self:get_marker_names()

		if names == nil then
			return
		end

		for _,v in pairs(names) do
			info.Strings:Add(v)
		end

		local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionMagatamaController', info)
		command_util.publish_cmd(self.boss_character.Owner, command)
	end
end

function local_class:update_revival_area(dt)
	if self.active_revival_fo_list == nil then return end

	for i = #self.active_revival_fo_list, 1, -1 do
		local info = self.active_revival_fo_list[i]

		if info.is_active then
			if info.time_passed >= self.current_stage_info.revival_area_life_time then
				--부활장판 종료
				self:return_revival_area_fo(table.remove(self.active_revival_fo_list, i))
			else
				info.time_passed = info.time_passed + dt
			end
		end
	end
end

function local_class:validate_buff_info()
	local to_remove = {}
	for k, v in pairs(self.buff_added_info) do
		if not user_party:Contains(k) then
			table.insert(to_remove, k)
		end
	end

	for i = 1, #to_remove do
		self.buff_added_info[to_remove[i]] = nil
	end
end

function local_class:update_fx()
	if not self.fx_enabled and next(self.buff_added_info) ~= nil then
		self.fx_enabled = true
		for i = 1, #self.info_list do
			self.info_list[i].fx = unity_object_pool.GetOrCreate('fx_gogok_zone_light'):Instantiate(self.info_list[i].pos)
		end

	elseif self.fx_enabled and next(self.buff_added_info) == nil then
		self.fx_enabled = false
		for i = 1, #self.info_list do
			self.info_list[i].fx:Dispose()
			self.info_list[i].fx = nil
		end

	end
end

function local_class:get_marker_names()
	if #self.marker_list > 0 then
		local names = {}
		for i = 1, self.current_stage_info.spawn_count do
			table.insert(names, self.marker_list[i].marker_name)
		end

		return names
	else
		return nil
	end
end

function local_class:update_hit_monster(dt)
	if self.info_list == nil then return end
	--보스일 경우 삭제 후 부활장판 생성 : 보스용 충돌범위가 따로있음
	for _,v in pairs(self.info_list) do
		--- 범위 내의 ifo
		local ifo_list = field:GetFieldObjectsInRadius(v.pos, self.current_stage_info.monster_hit_radius)

		for _,fo in pairs(ifo_list) do
			--- 대상이 몬스터 일 경우
			if (fo.EntityGroup & CS.Oak.EntityGroups.Enemy) ~= CS.Oak.EntityGroups.None then

				local info = CS.Oak.StageEventControllerSyncInfo()
				info.Strings:Add("hit_monster")
				info.Strings:Add(v.marker_info.marker_name)--터트린 마커 이름
				info.Strings:Add(fo.Name)--터트린 몬스터 이름
				info.Positions:Add(v.pos)--터진 마커 pos
				local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionMagatamaController', info)
				command_util.publish_cmd(self.boss_character.Owner, command)

				--self:explosion_stone(v.marker_info.marker_name)
			end
		end

		ifo_list:Dispose()
	end
end

function local_class:update_hit_character(dt)
	for _,v in pairs(self.info_list) do
		--- 범위 내의 ifo
		local ifo_list = field:GetFieldObjectsInRadius(v.pos, self.current_stage_info.buff_hit_radius)

		for _,fo in pairs(ifo_list) do
			--- 대상이 몬스터 일 경우
			if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
				local info = CS.Oak.StageEventControllerSyncInfo()
				info.Strings:Add("hit_character")
				local command = CS.Oak.StageEventControllerSyncCommand.Create('CoopExpeditionMagatamaController', info)
				command_util.publish_cmd(self.boss_character.Owner, command)
			end
		end

		ifo_list:Dispose()
	end
end

function local_class:sync(info)
	if info.Strings[0] == "Spawn_Stone" then
		self.sender = get_character(info.Strings[1])
		local marker_names = {}
		for i = 1, self.current_stage_info.spawn_count do
			table.insert(marker_names, info.Strings[i])
		end

		self:spawn_stone(marker_names)


	elseif info.Strings[0] == 'hit_monster' then
		local target = get_character(info.Strings[2])
		self:explosion_stone(info.Strings[1], info.Positions[0], target)
	elseif info.Strings[0] == 'hit_character' then
		for _,v in pairs(user_party) do
			self:add_buff(v)
		end
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BuffExpiredEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}