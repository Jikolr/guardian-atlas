local local_class = newclass('LaboseWorld1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 386

	-- 연출용 라보스 안개
	self.labose_fxs = nil
	self.labose_zone_count = 12
	self.labose_zone_pre_fix = 'scene_labose_zone_'

	-- fx
	self.fx = {
		virus_fog_weak = function()
			return unity_object_pool.GetOrCreate('fx_lw_virus_fog_weak')
		end,
		proj_contrail = function()
			return unity_object_pool.GetOrCreate('fx_boss_symptom_ghost_liquid_proj_contrail')
		end,
		proj_explosion = function()
			return unity_object_pool.GetOrCreate('fx_boss_symptom_ghost_liquid_proj_explosion')
		end,
		load_all = function(this)
			for name, load_func in pairs(this) do
				if name ~= 'load_all' then
					load_func()
				end
			end
		end
	}

	-- shake loop
	self.shake_loop = false
	self.proj_loop = false
	self.req_cnt = 1
	self.proj_fail_grid_name = 'proj_fail_grid'

	-- attack range
	self.attack_range = {
		data = {},
		radius = 1.25,
		count = 1,
		create = function(this)
			if #this.data == this.count then
				return
			end

			for i = 1, this.count do
				local attack_range = attack_range_util.create_circle_by_color_key(
						'red', vector(999, 0, 999), this.radius)

				attack_range_util.hide(attack_range)
				table.insert(this.data, { range = attack_range, transform = attack_range.transform })
			end
		end,
		destroy = function(this)
			for i = 1, #this.data do
				attack_range_util.destroy(this.data[i].range)
			end

			this.data = {}
		end,
		activate_sight = function(this, index, pos)
			if this.data[index].active then
				return
			end

			this.data[index].active = true
			this.data[index].transform.position = vector_util.get_x0z(pos, 0.03)
			attack_range_util.show(this.data[index].range)
		end,
		deactivate_sight = function(this, index)
			this.data[index].active = false
			attack_range_util.hide(this.data[index].range)
		end
	}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	self.attack_range:destroy()
	self:heavenhold_shake_end()

	if self.labose_fxs ~= nil then
		for _, fx in pairs(self.labose_fxs) do
			fx:Dispose()
			fx = nil
		end
	end

	self.labose_fxs = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.labose_fxs = {}

	self.fx:load_all()
	self.attack_range:create()

	yield_return(unity_object_pool, 'WaitAll')

	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_camera_grid_enter_event(e)
	-- 돌 떨어지는 영역 grid에 들어갔을 경우
	if type_util.is_player_enter_to_cam_grid(e, self.proj_fail_grid_name) then
		self.proj_loop = true

		return true
	end

	-- 그 외의 경우
	self.proj_loop = false

	return false
end

function local_class:on_stage_end_event(e)
	self:heavenhold_shake_end()

	return true
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local labose_wind_pot_controller = get_stage_event_controller('LaboseWindPotController')

	if quest_progress ~= nil and quest_progress.InnerProgress > 1 then
		for i = 1, self.labose_zone_count do
			self:add_labose_zone(i)
		end
	else
		self:add_labose_zone(1)
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.InnerProgress == 0 then
		labose_wind_pot_controller:tutorial_button_setting(true)

		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, false)
	elseif quest_progress.InnerProgress == 1 then
		labose_wind_pot_controller:tutorial_button_setting(true)

		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s2_knight_pos'),
				true, true)
	elseif quest_progress.InnerProgress == 3 then
		self:heavenhold_shake_start(false)
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s3_knight_pos'),
				true, true)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

--- 라보스 안개 영역 추가 함수
function local_class:add_labose_zone(zone_index)
	local zone_name = self.labose_zone_pre_fix .. zone_index
	local xz_adder = 0.5
	local zone = field_util.get_zone(zone_name)

	if zone == nil then
		logger_util.error('has no [' .. zone_name .. '] zone')
	else
		local min_x = zone.Bounds.min.x + xz_adder
		local min_z = zone.Bounds.min.z + xz_adder
		local max_x = zone.Bounds.max.x - xz_adder
		local max_z = zone.Bounds.max.z - xz_adder

		local start_pos = vector(min_x, 0, min_z)
		local end_pos = vector(max_x, 0, max_z)
		local cur_pos

		for x = math.floor(start_pos.x), math.floor(end_pos.x) do
			for z = math.floor(start_pos.z), math.floor(end_pos.z) do
				cur_pos = vector(x, 0, z)

				local fx = self.fx.virus_fog_weak():Instantiate(cur_pos)

				table.insert(self.labose_fxs, fx)
			end
		end
	end
end

--- 카메라 진동 및 파편 처리 함수
--- 10초에 1번씩 카메라 shake(0.4, 0.3)
--- 별도 명시 있을때까지 유지
function local_class:heavenhold_shake_start(immediate)
	start_coroutine(function()
		self.req_cnt = self.req_cnt + 1
		local cur_req_cnt = self.req_cnt
		local shake_delay = 10
		local time_passed = immediate and shake_delay or 0

		self.shake_loop = true

		while self.shake_loop and cur_req_cnt == self.req_cnt do
			time_passed = time_passed + unity_class.time.deltaTime

			if time_passed >= shake_delay then
				music_player_util.play_sfx_one_shot('03_mech_stomp_01')
				camera_util.shake(0.4, 0.3)

				if self.proj_loop then
					start_coroutine(self.fragment_fail, self)
				end

				time_passed = 0
			end

			coroutine.yield()
		end
	end)
end

function local_class:heavenhold_shake_end()
	self.shake_loop = false
	self.proj_loop = false
	self.req_cnt = -1
end

function local_class:fragment_fail()
	local leader = get_party_leader()
	local end_pos = leader.Position
	local start_pos = end_pos + vector(0, 15, 0)
	local fail_time = 1

	local proj_contrail = self.fx.proj_contrail():Instantiate(start_pos)

	music_player_util.play_sfx_one_shot('01_blackflower_01')
	self.attack_range:activate_sight(1, end_pos)
	coroutine_util.while_from_to_each_frame(fail_time, start_pos, end_pos, function(_, cur_value)
		proj_contrail.transform.position = cur_value

		return self.proj_loop
	end)

	proj_contrail:Dispose()
	self.attack_range:deactivate_sight(1)

	-- 화면 범위에 있을 경우 및 proj_loop 체크
	if not screen_util.is_fo_in_screen(end_pos, { bonus_distance = 3 }) and not self.proj_loop then
		return
	end

	-- 폭발 이펙트
	music_player_util.play_sfx_one_shot('02_lord_explosion_01')
	self.fx.proj_explosion():Instantiate(end_pos)
	camera_util.shake(0.3, 0.2)

	-- 리더가 Screenplay 상태일 경우 제외
	if lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState,
			CS.Oak.CharacterControllerScreenplayState) then
		return
	end

	local hits = field:GetFieldObjectsInCylinder(end_pos, self.attack_range.radius, 3)
	local damage_percent = 0.1

	for i = 0, hits.Count - 1 do
		local fo = hits.Values[i]
		if lua_helper.type_compare(fo, CS.Oak.Character) then
			if (fo.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None then
				-- 리더가 맞은 경우
				if lua_helper.reference_equals(fo, leader) then
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick | CS.Oak.DamageType.Trap
					damage_info.target = fo
					damage_info.sender = leader
					damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHP * damage_percent)
					damage_info.notMortal = true

					local cmd = CS.Oak.DamageCommand.Create(damage_info)
					command_util.publish_cmd(CS.Oak.Player.Local, cmd)
				end
			end
		else
			-- Breakable등의 데미지를 입는 오브젝트일 때
			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
			damage_info.target = fo
			damage_info.sender = user_party.Leader
			damage_info.damage = 10000

			local cmd = CS.Oak.DamageCommand.Create(damage_info)
			command_util.publish_cmd(CS.Oak.Player.Local, cmd)
		end
	end

	hits:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
