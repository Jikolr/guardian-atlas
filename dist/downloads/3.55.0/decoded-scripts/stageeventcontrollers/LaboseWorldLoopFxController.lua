local local_class = newclass('LaboseWorldLoopFxController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- fx
	self.fx = {
		cracked_space = function()
			return unity_object_pool.GetOrCreate('fx_lw_cracked_space')
		end,
		cracked_space_start = function()
			return unity_object_pool.GetOrCreate('fx_lw_cracked_space_start')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	-- 반복 재생 sfx용
	self.loop_sfx_list = nil

	-- 활성화된 fx 관리용
	self.cracked_space_effects = nil

	-- zone 처리용
	self.fx_zone_info = nil

	-- stage end 체크용
	self.stage_ended = false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	if self.cracked_space_effects ~= nil then
		for _, fx in pairs(self.cracked_space_effects) do
			fx:Dispose()
			fx = nil
		end

		self.cracked_space_effects = nil
	end

	if self.loop_sfx_list ~= nil then
		for _, sfx_info in pairs(self.loop_sfx_list) do
			music_player_util.stop_sfx(sfx_info.sfx)
		end

		self.loop_sfx_list = nil
	end


	self.fx_zone_info = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.fx:load_all()
	yield_return(unity_object_pool, 'WaitAll')

	local data = get_or_create_global_variable('Quest/Main/LaboseWorld/Common/LaboseWorldLoopFxConstants.lua')

	self:create_cracked_effect(data)
	self:zone_fx_setting(data)

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if self.fx_zone_info == nil then
		return false
	end

	for i = 1, #self.fx_zone_info do
		if not self.fx_zone_info[i].create_check and
			type_util.is_zone_full_enter(e, get_party_leader(), self.fx_zone_info[i].zone_name) then
			self.fx_zone_info[i].create_check = true
			start_coroutine(self.create_zone_cracked_effect, self, self.fx_zone_info[i])

			return true
		end
	end
	return false
end

function local_class:on_stage_end_event(e)
	self.stage_ended = true

	return true
end
--endregion

--- 스테이지 진입 시에 생성하는 effect
function local_class:create_cracked_effect(data)
	if data[stage.Name] == nil then
		return
	end

	local marker_info = data[stage.Name].loop_fx

	if marker_info == nil then
		return
	end

	local effect_pos_list = {}
	self.cracked_space_effects = {}

	for i = 1, marker_info.marker_count do
		local marker_name = marker_info.maker_name_pre_fix .. i

		if field_util.has_marker(marker_name) then
			table.insert(effect_pos_list, field_util.get_marker_pos(marker_name))
		end
	end

	for i = 1, #effect_pos_list do
		table.insert(self.cracked_space_effects, self.fx.cracked_space():Instantiate(effect_pos_list[i]))
	end

	data = nil

	start_coroutine(self.sfx_routine, self)
end

--- 존 세팅
function local_class:zone_fx_setting(data)
	if data[stage.Name] == nil then
		return
	end

	local zone_info = data[stage.Name].zone_fx

	self.fx_zone_info = {}

	for i = 1, zone_info.count do
		local cur_info = {
			zone_name = zone_info.zone_name_pre_fix .. i,
			marker_nzme = zone_info.maker_name_pre_fix .. i,
			create_check = false
		}

		table.insert(self.fx_zone_info, cur_info)
	end
end

function local_class:create_zone_cracked_effect(info)
	local effect_pos = field_util.get_marker_pos(info.marker_nzme)

	--카메라 shake(0.2, 0.1)
	camera_util.shake(0.2, 0.1)

	--(좌표)지점에 fx_lw_cracked_space_start 이펙트 생성
	self.fx.cracked_space_start():Instantiate(effect_pos)
	music_player_util.play_sfx({ sfx_name = '02_lightning_strike_01', play_pos = effect_pos })
	--1초 대기
	coroutine_util.while_each_frame(1, function(progress)
		return not self.stage_ended
	end)

	--카메라 shake(0.4, 0.25)
	camera_util.shake(0.4, 0.25)
	music_player_util.play_sfx({ sfx_name = '02_break_window_01', play_pos = effect_pos })

	--같은 지점에 fx_lw_cracked_space 이펙트 생성
	if self.cracked_space_effects ~= nil then
		table.insert(self.cracked_space_effects, self.fx.cracked_space():Instantiate(effect_pos))
	end
end

--- 사운드 관리 루틴
function local_class:sfx_routine()
	self.loop_sfx_list = {}

	while not self.stage_ended do

		self:distance_check()

		coroutine_util.while_each_frame(0.5, function(progress)
			return not self.stage_ended
		end)
	end
end

--- 이미 가까운 sfx와 겹치는지 체크
function local_class:cur_dist_check(pos, index)
	for i = 1, #self.loop_sfx_list do
		if vector_util.is_almost_zero(self.loop_sfx_list[i].pos - pos) then
			return 0
		end
	end

	return index
end

--- 사운드는 두개까지만 추가함
function local_class:distance_check()
	local leader = get_party_leader()
	local dist_list = {}
	local cur_sfx_list = {}

	for _, fx in pairs(self.cracked_space_effects) do
		local fx_pos = fx.transform.localPosition
		local dist = vector_util.sqr_xz_distance(leader.Position, fx_pos)

		table.insert(dist_list, { dist = dist, pos = fx_pos })
	end

	table.sort(dist_list, function(a, b)
		return a.dist < b.dist
	end)

	local create_sfx = function(index)
		if #dist_list >= index then
			local check_index = self:cur_dist_check(dist_list[index].pos, index)

			if check_index ~= 0 then
				if self.loop_sfx_list[check_index] ~= nil then
					music_player_util.fade_out_sfx(self.loop_sfx_list[check_index].sfx, 0.5)
					table.remove(self.loop_sfx_list, check_index)
				end

				local sfx = music_player_util.play_sfx({ sfx_name = '02_light_loop_04',
														 type_priority = 'loop',
														 play_pos = vector_util.get_x0z(dist_list[check_index].pos, 1),
														 loop = true,
														 max_distance = 10 })

				table.insert(cur_sfx_list, { sfx = sfx, pos = dist_list[check_index].pos })
			end
		end
	end

	create_sfx(1)

	for _, sfx_info in pairs(cur_sfx_list) do
		table.insert(self.loop_sfx_list, { sfx = sfx_info.sfx, pos = sfx_info.pos })
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
