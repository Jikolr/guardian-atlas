local local_class = newclass('ConveyorBeltManager')

local mover_pool = newclass('ConveyorBeltMoverPool')

local belt_controller_base = newclass('ConveyorBeltControllerBase')
local default_belt_controller = newclass('ConveyorBeltController', belt_controller_base)

local mover_base = newclass('ConveyorBeltMoverBase')

local default_fo_mover = newclass('ConveyorBeltFieldObjectMover', mover_base)
local default_character_mover = newclass('ConveyorBeltCharacterMover', mover_base)
local reset_holdable_mover = newclass('ConveyorBeltResetHoldableMover', mover_base)

local switchable_character_mover = newclass('ConveyorBeltSwitchableCharacterMover', default_character_mover)

local conveyor_belt = {
	default = {
		controller = default_belt_controller,
		movers = {
			{
				type = 'character',
				constructor = default_character_mover,
				type_checker = function(target)
					return lua_helper.type_compare(target, typeof(CS.Oak.Character))
							and (target.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None
				end
			},
		}
	},
	screenplay = {
		controller = belt_controller_base,
		movers = {}
	},
	switchable = {
		controller = default_belt_controller,
		movers = {
			{
				type = 'character',
				constructor = switchable_character_mover,
				type_checker = function(target)
					return lua_helper.type_compare(target, typeof(CS.Oak.Character))
							and (target.EntityGroup & CS.Oak.EntityGroups.Player) ~= CS.Oak.EntityGroups.None
				end
			},
			{
				type = 'reset_holdable',
				constructor = reset_holdable_mover,
				type_checker = function(target)
					return lua_helper.type_compare(target.Holdable, CS.Oak.Holdable)
				end
			}
		}
	}
}

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local all_constants = require('stageeventcontrollers/ConveyorBeltConstants.lua')
	self.constants = all_constants[stage.Name]

	self.belt_controllers = {}

	self.is_stage_ended = false
end

function local_class:load_resource()
	if self.constants == nil then
		return
	end

	for name, constants in pairs(self.constants) do
		local classes = conveyor_belt[constants.type]
		self.belt_controllers[name] = classes.controller(self, classes.movers, constants)
		self.belt_controllers[name]:on_load()
	end

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	self.cs_controller = nil

	if self.belt_controllers ~= nil then
		for controller_name, _ in pairs(self.belt_controllers) do
			self.belt_controllers[controller_name]:dispose()
		end

		self.belt_controllers = nil
	end

	self.constants = nil
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:use_late_update_frame()
	return false
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	for name, _ in pairs(self.belt_controllers) do
		self.belt_controllers[name]:on_stage_loaded_event(e)
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'conveyor_belt_control' then
		local group_name = e:GetParamAt(1)
		local controller = self.belt_controllers[group_name]

		if controller ~= nil then
			local command = e:GetParamAt(2)

			if command == 'on' then
				--컨베이어 벨트 활성화
				controller:activate_belt()

				return true

			elseif command == 'off' then
				--컨베이어 벨트 비활성화
				controller:deactivate_belt()

				return true
			end
		end
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.is_stage_ended = true

	return true
end

function local_class:convert_table_to_vector3(table)
	return vector(table[1], table[2], table[3])
end

--region 컨베이어 벨트 컨트롤러

--region BeltControllerBase
function belt_controller_base:init(manager, mover_types, constants)
	self.manager = manager
	self.constants = constants

	self.belt_animators = {}

	self.belt_fos = {}

	self.belt_animating = false

	-- ZoneName -> move_dir
	self.zone_to_move_dir = {}

	self.mover_types = mover_types

	self.mover_pools = {}

	-- 풀 생성
	for i = 1, #self.mover_types do
		local info = self.mover_types[i]
		local type = info.type

		-- FIXME : Dispose 내에서 self를 반환할 때, self가 베이스 클래스 인스턴스로 들어가는건 아닌지 확인 후에 교체 예정
		self.mover_pools[type] = mover_pool(info.constructor, type)
	end

	-- 움직임 속도 비율. 애니메이션 및 이동 속도 배율 조절할 때 사용
	self.speed_ratio = 1

	self.belt_sfx = nil

	self.sfx_routine_req_id = 0

	self.belt_sfx_bounds = {}

	self.sfx_routine_on = false
end

function belt_controller_base:on_load()
	if self.constants.sfx_check_zone ~= nil then
		message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
		message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	end
end

function belt_controller_base:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	for mover_type, _ in pairs(self.mover_pools) do
		self.mover_pools[mover_type]:dispose()
	end

	self:stop_belt_sfx()

	self.belt_sfx_bounds = nil

	self.manager = nil
	self.constants = nil
	self.belt_animators = nil
	self.belt_fos = nil
end

function belt_controller_base:on_stage_loaded_event(_)
	local belt_fo_hashset = {}
	local available_belt_name_hashset = self.constants.belt_gimmick_name_hashset

	for zone_name, dir_str in pairs(self.constants.belt_zone_dict) do
		local gather_zone = field:GetZone(zone_name)

		if gather_zone == nil then
			--TODO : 로그 출력
			goto continue
		end

		local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(gather_zone.Bounds, unity_class.vector3.zero)

		for i = 0, fo_list.Count - 1 do
			local fo = fo_list[i]

			-- 겹치는 애들은 패스
			if not belt_fo_hashset[fo] and available_belt_name_hashset[fo.Name] then
				belt_fo_hashset[fo] = true

				local animator = fo:GetComponent(typeof(CS.UnityEngine.Animator))

				animator.speed = self.constants.animator_speed
				animator:Play(self.constants.animation_name)
				animator.enabled = false

				table.insert(self.belt_fos, fo)
				table.insert(self.belt_animators, animator)
			end
		end

		fo_list:Dispose()

		self.zone_to_move_dir[zone_name] = direction_util.to_vector3_ver2(dir_str)

		if self.constants.sfx ~= nil then
			local belt_width = math.min(gather_zone.Bounds.extents.x, gather_zone.Bounds.extents.z)
			local sfx_bounds = gather_zone.Bounds
			local expand_dist = self.constants.sfx.max_dist - belt_width

			sfx_bounds:Expand(vector(expand_dist, 0, expand_dist) * 2)

			-- GC 방지를 위해 C#의 Bounds는 쓰지 않고, 필요한 데이터만 묶어서 테이블로 가짐
			table.insert(self.belt_sfx_bounds, {
				center = sfx_bounds.center,
				extents = sfx_bounds.extents,
				min = sfx_bounds.min,
				max = sfx_bounds.max,
				x_longer = sfx_bounds.extents.x > sfx_bounds.extents.z,
				width = math.min(sfx_bounds.extents.x, sfx_bounds.extents.z)
			})
		end

		::continue::
	end

	-- FIXME : 실행 조건 확인 필요
	self:toggle_animators(true)

	return true
end

--- 컨베이어 벨트 애니메이션 ON/OFF. 최적화가 필요해서 일단 남겨둠
function belt_controller_base:toggle_animators(on)
	if self.belt_animating == on then
		return
	end

	self.belt_animating = on

	for i = 1, #self.belt_animators do
		self.belt_animators[i].enabled = self.belt_animating
	end
end

function belt_controller_base:change_speed(ratio)
	if self.speed_ratio == ratio then
		return
	end

	self.speed_ratio = ratio

	for i = 1, #self.belt_animators do
		self.belt_animators[i].speed = self.constants.animator_speed * self.speed_ratio
	end
end

function belt_controller_base:deactivate_belt()
	self:change_speed(0)

	if self.belt_sfx ~= nil then
		self.belt_sfx.Volume = 0
	end
end

function belt_controller_base:activate_belt()
	self:change_speed(1)

	if self.belt_sfx ~= nil then
		self.belt_sfx.Volume = self.constants.sfx.volume
	end
end

--region 3D SFX 처리

function belt_controller_base:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), self.constants.sfx_check_zone) then
		self:start_sfx_routine()
		return true
	end

	return false
end

function belt_controller_base:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), self.constants.sfx_check_zone) then
		self:stop_sfx_routine()
		self:stop_belt_sfx()
		return true
	end

	return false
end

function belt_controller_base:play_or_move_belt_sfx(play_pos)
	if self.belt_sfx == nil then
		self.belt_sfx = music_player_util.play_sfx({
			sfx_name = self.constants.sfx.name, loop = true,
			play_pos = play_pos, volume = self.speed_ratio > 0 and self.constants.sfx.volume or 0,
			max_distance = self.constants.sfx.max_dist, min_distance = self.constants.sfx.min_dist,
			type_priority = 'gimmick', player_priority = 'object'
		})
	else
		self.belt_sfx:SetPosition(play_pos)
	end
end

function belt_controller_base:stop_belt_sfx()
	if self.belt_sfx == nil then
		return
	end

	music_player_util.stop_sfx(self.belt_sfx)

	self.belt_sfx = nil
end

function belt_controller_base:start_sfx_routine()
	self.sfx_routine_req_id = self.sfx_routine_req_id + 1

	start_coroutine(self.sfx_routine, self)
end

function belt_controller_base:stop_sfx_routine()
	-- FIXME : 일단 이런식으로 체크해서 강제 종료시켜줌
	self.sfx_routine_req_id = self.sfx_routine_req_id + 1
end

function belt_controller_base:sfx_routine()
	local max_value = CS.System.Single.MaxValue
	local req_id = self.sfx_routine_req_id

	while req_id == self.sfx_routine_req_id and not self.manager.is_stage_ended do
		local camera_pos = stage_camera.LookAtPosition
		local min_sqr_dist = max_value
		local play_pos = nil

		for i = 1, #self.belt_sfx_bounds do
			local bounds = self.belt_sfx_bounds[i]

			-- 바운드 안에 들어온 경우
			if bounds.min.x <= camera_pos.x and bounds.max.x >= camera_pos.x and
					bounds.min.z <= camera_pos.z and bounds.max.z >= camera_pos.z then
				local new_play_pos = nil

				if bounds.x_longer then
					new_play_pos = vector_util.get_xy0(camera_pos, bounds.center.z)

					if bounds.max.x - bounds.width < new_play_pos.x then
						new_play_pos.x = bounds.max.x - bounds.width
					elseif bounds.min.x + bounds.width > new_play_pos.x then
						new_play_pos.x = bounds.min.x + bounds.width
					end
				else
					new_play_pos = vector_util.get_0yz(camera_pos, bounds.center.x)

					if bounds.max.z - bounds.width < new_play_pos.z then
						new_play_pos.z = bounds.max.z - bounds.width
					elseif bounds.min.z + bounds.width > new_play_pos.z then
						new_play_pos.z = bounds.min.z + bounds.width
					end
				end

				new_play_pos.y = bounds.center.y

				local sqr_dist = (camera_pos - new_play_pos).sqrMagnitude

				if min_sqr_dist > sqr_dist then
					min_sqr_dist = sqr_dist
					play_pos = new_play_pos
				end
			end
		end

		if play_pos then
			self:play_or_move_belt_sfx(play_pos)
		else
			self:stop_belt_sfx()
		end

		coroutine.yield()
	end
end

--endregion 3D SFX 처리

--endregion BeltControllerBase

--region DefaultBeltController
function default_belt_controller:init(manager, mover_types, constants)
	self.super:init(manager, mover_types, constants)

	self.routine_on = false

	-- [현재 이 컨트롤러에서 관리 중인 오브젝트 -> Mover 클래스 인스턴스] 딕셔너리
	self.mover_dict = {}

	-- 현재 이 컨트롤러에서 관리 중인 오브젝트의 갯수
	self.mover_count = 0

	-- 컨베이어 벨트에 완전히 올라갔을 때의 스파인 오프셋
	self.spine_offset = self.manager:convert_table_to_vector3(self.constants.spine_offset)
end

function default_belt_controller:on_load()
	self.super:on_load()

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function default_belt_controller:on_stage_loaded_event(e)
	self.super:on_stage_loaded_event(e)

	self:create_walls()

	return true
end

--Wall 세팅
function default_belt_controller:create_walls()
	--region 1층 세팅

	-- PS-10099 : 실제로 오브젝트에 대한 로직이 들어가는 경우에만 Visible로 변경하여 벽 뚫지 않도록 세팅
	for i = 1, #self.belt_fos do
		self.belt_fos[i].ActiveState = active_state('visible')
	end

	local first_floor_wall_thickness = 0.1
	local wall_height = 0.7
	local wall_info_getter = {
		-- left
		function(bounds)
			local pos = vector(bounds.min.x - (first_floor_wall_thickness / 2), 0, bounds.center.z)
			local hitbox = CS.Oak.Hitbox(
					vector(first_floor_wall_thickness, wall_height, bounds.size.z + first_floor_wall_thickness * 2)
			)

			return pos, hitbox
		end,
		-- right
		function(bounds)
			local pos = vector(bounds.max.x + (first_floor_wall_thickness / 2), 0, bounds.center.z)
			local hitbox = CS.Oak.Hitbox(
					vector(first_floor_wall_thickness, wall_height, bounds.size.z + first_floor_wall_thickness * 2)
			)

			return pos, hitbox
		end,
		-- up
		function(bounds)
			local pos = vector(bounds.center.x, 0, bounds.max.z + (first_floor_wall_thickness / 2))
			local hitbox = CS.Oak.Hitbox(
					vector(bounds.size.x + first_floor_wall_thickness * 2, wall_height, first_floor_wall_thickness)
			)

			return pos, hitbox
		end,
		-- down
		function(bounds)
			local pos = vector(bounds.center.x, 0, bounds.min.z - (first_floor_wall_thickness / 2))
			local hitbox = CS.Oak.Hitbox(
					vector(bounds.size.x + first_floor_wall_thickness * 2, wall_height, first_floor_wall_thickness)
			)

			return pos, hitbox
		end,
	}

	for zone_name, _ in pairs(self.zone_to_move_dir) do
		local zone_bounds = field_util.get_zone(zone_name).Bounds

		for i = 1, #wall_info_getter do
			local pos, hitbox = wall_info_getter[i](zone_bounds)

			local vfo = CS.Oak.VirtualFieldObject()

			vfo.Position = pos
			vfo.Hitbox = hitbox
			vfo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance

			vfo.ActiveState = active_state('enabled')
		end
	end

	--endregion 1층 세팅

	--region 2층 세팅

	-- FIXME : 왜인지는 모르겠지만 1층에서 자꾸 2층 벽에 충돌함...
	local second_floor_adder = vector(0, 0.1, 0)

	local wall_generators = {
		-- left
		{
			pos_adder = vector(0, 0, 1),
			get_start_pos = function(bounds)
				return vector(bounds.min.x - 0.5, 1, bounds.min.z + 0.5)
			end,
			check_walk_end = function(bounds, current_pos)
				return current_pos.z > bounds.max.z
			end
		},
		-- right
		{
			pos_adder = vector(0, 0, 1),
			get_start_pos = function(bounds)
				return vector(bounds.max.x + 0.5, 1, bounds.min.z + 0.5)
			end,
			check_walk_end = function(bounds, current_pos)
				return current_pos.z > bounds.max.z
			end
		},
		-- up
		{
			pos_adder = vector(1, 0, 0),
			get_start_pos = function(bounds)
				return vector(bounds.min.x + 0.5, 1, bounds.max.z + 0.5)
			end,
			check_walk_end = function(bounds, current_pos)
				return current_pos.x > bounds.max.x
			end
		},
		-- down
		{
			pos_adder = vector(1, 0, 0),
			get_start_pos = function(bounds)
				return vector(bounds.min.x + 0.5, 1, bounds.min.z - 0.5)
			end,
			check_walk_end = function(bounds, current_pos)
				return current_pos.x > bounds.max.x
			end
		},
	}

	for zone_name, _ in pairs(self.zone_to_move_dir) do
		local zone_bounds = field_util.get_zone(zone_name).Bounds

		for i = 1, #wall_generators do
			local generator = wall_generators[i]
			local wall_center_pos = generator.get_start_pos(zone_bounds)

			while not generator.check_walk_end(zone_bounds, wall_center_pos) do
				local enable_to_generate = true

				for check_zone_name, _ in pairs(self.zone_to_move_dir) do
					if check_zone_name ~= zone_name then
						local check_zone = field_util.get_zone(check_zone_name)

						if check_zone:Contains(wall_center_pos) then
							enable_to_generate = false
							break
						end
					end
				end

				-- Jumpable 달리는 위치에는 Wall 설치 안함
				if self.constants.jumpable_zones ~= nil then
					for j = 1, #self.constants.jumpable_zones do
						local check_zone = field_util.get_zone(self.constants.jumpable_zones[j])

						if check_zone:Contains(wall_center_pos) then
							enable_to_generate = false
							break
						end
					end
				end

				-- TODO : 일자로 붙어있는 VFO끼리 머지하여 파티션 계산 부하를 줄임
				if enable_to_generate then
					local vfo = CS.Oak.VirtualFieldObject()

					vfo.Position = wall_center_pos + second_floor_adder
					vfo.Hitbox = CS.Oak.Hitbox(vector(1, 1, 1))
					vfo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance

					vfo.ActiveState = active_state('enabled')
				end

				wall_center_pos = wall_center_pos + generator.pos_adder
			end
		end
	end

	if self.constants.jumpable_zones ~= nil then
		for i = 1, #self.constants.jumpable_zones do
			local zone_name = self.constants.jumpable_zones[i]
			local jumpable_bounds = field_util.get_zone(zone_name).Bounds

			-- VFO는 MonoBehaviour가 안붙어있어서 FieldUIInteractionMarker 내에서 인터랙트 가능 마커 표시를 안띄워준다.
			-- 따라서 실제 GameObject를 생성해서 FieldObject를 붙여주는 방식을 선택함
			local go = CS.UnityEngine.GameObject()
			go.transform.parent = stage.StageTransform

			local fo = go:AddComponent(typeof(CS.Oak.FieldObject))
			fo.Name = zone_name .. '_interact'

			fo.Position = vector_util.get_x0z(jumpable_bounds.center, 1) + second_floor_adder
			fo.Hitbox = CS.Oak.Hitbox(vector_util.get_x0z(jumpable_bounds.size, 0.5))
			fo.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
			fo.Interactable = CS.Oak.JumpDownInteractable.Create()

			fo.ActiveState = active_state('enabled')
		end
	end

	--endregion 2층 세팅
end

function default_belt_controller:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.routine_on = false

	-- 종료 시 전부 리셋
	local dispose_targets = {}
	for target, _ in pairs(self.mover_dict) do
		table.insert(dispose_targets, target)
	end

	for i = 1, #dispose_targets do
		self:remove_mover(dispose_targets[i])
	end

	self.mover_dict = nil
	self.mover_count = 0

	self.zone_to_move_dir = nil

	self.super:dispose()
end

function default_belt_controller:on_zone_enter_event(e)
	if e.FullEnter then
		return false
	end

	return self:on_enter_mover(e.FieldObject, e.Zone)
end

function default_belt_controller:on_zone_leave_event(e)
	if not e.FullLeave then
		return false
	end

	return self:on_leave_mover(e.FieldObject, e.Zone)
end

--- 컨베이어 벨트 애니메이션 ON/OFF
function default_belt_controller:toggle_animators(on)
	self.super:toggle_animators(on)
end

function default_belt_controller:deactivate_belt()
	self.super:deactivate_belt()
end

function default_belt_controller:activate_belt()
	self.super:activate_belt()
end

function default_belt_controller:start_belt_routine()
	if self.routine_on then
		return
	end

	self.routine_on = true

	start_coroutine(self.belt_routine, self)
end

--- 컨베이어 벨트 위의 오브젝트 위치를 갱신하는 루틴
function default_belt_controller:belt_routine()
	-- Mover가 하나라도 있는 경우에는 계속 갱신
	while self.mover_count > 0 and self.routine_on and not self.manager.is_stage_ended do
		local delta_time = unity_class.time.deltaTime
		local move_magnitude = self.constants.speed * self.speed_ratio * delta_time
		local exited_targets = {}

		for target, _ in pairs(self.mover_dict) do
			local mover = self.mover_dict[target]

			-- 움직임 갱신
			local need_remove = mover:execute_move(delta_time, move_magnitude)

			-- 캐릭터 점프 등이 끝나서 더 이상 이쪽에서 들고 있을 필요가 없을 때
			if need_remove then
				table.insert(exited_targets, target)
			end
		end

		-- 루틴에서 들고 있을 필요가 없는 타겟들 갱신
		for i = 1, #exited_targets do
			local target = exited_targets[i]

			self:remove_mover(target)
		end

		coroutine.yield()
	end

	self.routine_on = false
end

--- 현재 타겟이 어떤 타입인지 확인
function default_belt_controller:get_mover_type(target)
	for i = 1, #self.mover_types do
		-- 맞는 타입을 찾았을 때 해당 타입 리턴
		if self.mover_types[i].type_checker(target) then
			return self.mover_types[i].type
		end
	end

	-- 그 외는 전부 논외로 처리
	return nil
end

--- 갱신할 오브젝트 추가
function default_belt_controller:add_mover(target, mover_type)
	local mover = self.mover_pools[mover_type]:get_or_create(self)

	mover:attach_to(target)

	self.mover_dict[target] = mover

	self.mover_count = self.mover_count + 1

	return mover
end

--- 갱신할 오브젝트 삭제
function default_belt_controller:remove_mover(target)
	local mover = self.mover_dict[target]
	local mover_type = mover.type

	mover:detach_from(target)

	self.mover_pools[mover_type]:return_obj(mover)

	self.mover_dict[target] = nil

	self.mover_count = self.mover_count - 1
end

function default_belt_controller:on_enter_mover(target, entered_zone)
	local move_dir = self.zone_to_move_dir[entered_zone.Name]

	if move_dir == nil then
		return false
	end

	local mover_type = self:get_mover_type(target)

	if mover_type == nil then
		return false
	end

	local mover = self.mover_dict[target]
	local make_new_mover = mover == nil

	-- 없는 경우 풀에서 가져와서 붙여줌
	if make_new_mover then
		mover = self:add_mover(target, mover_type)
	end

	-- 정보 갱신이 없는 경우엔 탈출
	if not mover:on_enter(entered_zone, move_dir) then
		return false
	end

	-- 들어온 오브젝트가 여지껏 없었고, 루틴이 돌고있지 않은 경우 루틴 시작
	if make_new_mover and self.mover_count == 1 then
		self:start_belt_routine()
	end

	return true
end

function default_belt_controller:on_leave_mover(target, left_zone)
	local move_dir = self.zone_to_move_dir[left_zone.Name]

	if move_dir == nil then
		return false
	end

	local mover = self.mover_dict[target]

	if mover == nil then
		return false
	end

	-- 정보 갱신이 없는 경우엔 탈출
	if not mover:on_leave(left_zone, move_dir) then
		return false
	end

	return true
end
--endregion DefaultBeltController

--endregion 컨베이어 벨트 컨트롤러

--region Mover Pool

function mover_pool:init(constructor, type)
	self.constructor = constructor
	self.type = type

	self.pool = {}

	-- FIXME : 미리 N개 만들어 놓는거는 안됨...
end

function mover_pool:dispose()
	if self.pool == nil then
		return
	end

	for i = 1, #self.pool do
		self.pool[i]:dispose()
	end

	self.pool = nil

	self.constructor = nil
end

function mover_pool:get_or_create(controller)
	local obj

	--CS.UnityEngine.Debug.LogError(self.type .. ' Mover Current Pooled Count (On GetOrCreate) : ' .. (#self.pool + 1))

	if #self.pool == 0 then
		obj = self.constructor(controller, self.type)
	else
		obj = self.pool[#self.pool]
		self.pool[#self.pool] = nil
	end

	return obj
end

function mover_pool:return_obj(obj)
	---- DEBUG CODE : 풀에 다른 타입의 오브젝트가 들어가는 거 트래킹
	--if obj.type ~= self.type then
	--	CS.UnityEngine.Debug.LogError(obj .. ' has Different Type with ' .. self.type .. ' Pool.')
	--	return
	--end
	--
	--for i = 1, #self.pool do
	--	-- DEBUG CODE : 풀에 같은 오브젝트 두 번 들어가는 거 트래킹
	--	if self.pool[i] == obj then
	--		CS.UnityEngine.Debug.LogError(obj .. ' is In Pool Already.')
	--		return
	--	end
	--end

	table.insert(self.pool, obj)
end

--endregion Mover Pool

--region Mover

--region Mover Base
function mover_base:init(controller, type)
	self.controller = controller
	self.type = type
	self.target = nil

	self.entered_zone_hash_set = {}
	self.entered_zone_count = 0
	self.move_dir = unity_class.vector3.zero
end

function mover_base:attach_to(target)
	self.target = target

	self.entered_zone_hash_set = {}
	self.entered_zone_count = 0
end

function mover_base:detach_from(target)
	self.target = nil

	self.entered_zone_hash_set = {}
	self.entered_zone_count = 0
end

---@return boolean 정보 갱신이 이루어졌는지 리턴
function mover_base:on_enter(zone, dir)
	if self.entered_zone_hash_set[zone] ~= nil then
		return false
	end

	self.entered_zone_hash_set[zone] = true
	self.entered_zone_count = self.entered_zone_count + 1
	self.move_dir = self.move_dir + dir

	return true
end

---@return boolean 정보 갱신이 이루어졌는지 리턴
function mover_base:on_leave(zone, dir)
	if self.entered_zone_hash_set[zone] == nil then
		return false
	end

	self.entered_zone_hash_set[zone] = nil
	self.entered_zone_count = self.entered_zone_count - 1
	self.move_dir = self.move_dir - dir

	return true
end

---@return boolean 전체 Mover 정보에서 삭제가 필요하면 true 리턴
function mover_base:execute_move(dt, magnitude)
	return false
end

function mover_base:dispose()
	self.target = nil

	self.entered_zone_hash_set = nil
end
--endregion Mover Base

--region Default FieldObject Mover
function default_fo_mover:init(controller, type)
	self.super:init(controller, type)
end

function default_fo_mover:attach_to(target)
	self.super:attach_to(target)
end

function default_fo_mover:detach_from(target)
	self.super:detach_from(target)
end

function default_fo_mover:on_enter(zone, dir)
	return self.super:on_enter(zone, dir)
end

function default_fo_mover:on_leave(zone, dir)
	return self.super:on_leave(zone, dir)
end

function default_fo_mover:execute_move(dt, magnitude)
	if self.entered_zone_count == 0 then
		return true
	end

	-- 대각선 이동이 벽에 막히는 경우가 있어서 x z 방향 두 개로 나눠서 움직이도록 세팅
	if not float_util.is_almost_zero(self.move_dir.x) then
		CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.target,
				vector(self.move_dir.x, 0, 0), magnitude)
	end

	if not float_util.is_almost_zero(self.move_dir.z) then
		CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.target,
				vector(0, 0, self.move_dir.z), magnitude)
	end

	return self.super:execute_move(dt, magnitude)
end

function default_fo_mover:dispose()
	self.super:dispose()
end
--endregion Default FieldObject Mover

--region Reset Holdable Mover
function reset_holdable_mover:init(controller, type)
	self.super:init(controller, type)
end

function reset_holdable_mover:attach_to(target)
	self.super:attach_to(target)
end

function reset_holdable_mover:detach_from(target)
	self.super:detach_from(target)
end

function reset_holdable_mover:on_enter(zone, dir)
	return self.super:on_enter(zone, dir)
end

function reset_holdable_mover:on_leave(zone, dir)
	return self.super:on_leave(zone, dir)
end

function reset_holdable_mover:execute_move(dt, magnitude)
	if self.entered_zone_count == 0 then
		return true
	end

	-- FIXME : 챕터 15 스테이지 6 대응 : 어떤 식으로든 들어오는 경우에는 무조건 리셋시키도록 함.
	if not self.target.Holdable.IsHeld then
		message_system:SendSync(self.target, CS.Oak.GimmickResetEvent.Instance)
	end

	return self.super:execute_move(dt, magnitude)
end

function reset_holdable_mover:dispose()
	self.super:dispose()
end
--endregion Default FieldObject Mover

--region Default Character Mover
function default_character_mover:init(controller, type)
	self.super:init(controller, type)

	self.original_spine_offset = unity_class.vector3.zero
	self.original_stat_ui_offset = unity_class.vector3.zero

	self.remain_offset_adjust_dur = 0

	self.stat_ui = nil
end

function default_character_mover:attach_to(target)
	self.super:attach_to(target)

	self.original_spine_offset = self.target.SpineController.SpineOffset

	self.stat_ui = field_ui_manager:GetUIByKey(CS.Oak.FieldUiType.CharacterStats, self.target)

	if self.stat_ui ~= nil then
		self.original_stat_ui_offset = self.stat_ui.Offset.localPosition
	end

	-- FIXME : 챕터 15 스테이지 6 대응 : 뭔가를 들고 들어오는 경우에는 무조건 리셋시키도록 함.
	if lua_helper.type_compare(self.target.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState) then
		message_system:SendSync(self.target.CharacterBehaviour.CurrentActionState.HoldTarget, CS.Oak.GimmickResetEvent.Instance)
	end

	self.remain_offset_adjust_dur = 0
end

function default_character_mover:detach_from(target)
	self.remain_offset_adjust_dur = 0

	-- 오프셋 원복
	self:set_target_offset(unity_class.vector3.zero)

	self.stat_ui = nil

	self.super:detach_from(target)
end

function default_character_mover:dispose()
	self.super:dispose()

	self.stat_ui = nil
end

function default_character_mover:on_enter(zone, dir)
	if not self.super:on_enter(zone, dir) then
		return false
	end

	-- 최초 진입 시
	if self.entered_zone_count == 1 then
		-- 그림자 꺼버림
		self.target.SpineController.IsShadowActive = false

		if self:is_jumping() then
			self.remain_offset_adjust_dur = self.controller.constants.spine_offset_adjust_dur
		end
	end

	return true
end

function default_character_mover:on_leave(zone, dir)
	if not self.super:on_leave(zone, dir) then
		return false
	end

	-- 컨베이어 벨트에서 완전히 나간 경우
	if self.entered_zone_count == 0 then
		-- 그림자 다시 켜줌
		self.target.SpineController.IsShadowActive = true

		if self:is_jumping() then
			self.remain_offset_adjust_dur = self.controller.constants.spine_offset_adjust_dur
		end
	end

	return true
end

function default_character_mover:execute_move(dt, magnitude)
	-- 만약 남은 시간이 있는 경우 강제로 오프셋 맞춰줌
	if self.remain_offset_adjust_dur > 0 then
		local offset_dt = math.min(dt, self.remain_offset_adjust_dur)

		if self.entered_zone_count > 0 then
			self:move_target_offset(self.controller.spine_offset * offset_dt /
					self.controller.constants.spine_offset_adjust_dur)
		else
			-- 나가고 있는 경우 마이너스 배율
			self:move_target_offset(-self.controller.spine_offset * offset_dt /
					self.controller.constants.spine_offset_adjust_dur)
		end

		self.remain_offset_adjust_dur = self.remain_offset_adjust_dur - dt

	elseif not self:is_jumping() then
		-- 걸쳐있는 컨베이어 벨트가 있는 경우
		if self.entered_zone_count > 0 then
			-- 움직임이 없을 때는 아래 로직을 전부 패스
			if magnitude > 0 then
				-- 오프셋 고정시켜줌
				self:set_target_offset(self.controller.spine_offset)

				-- 대각선 이동이 벽에 막히는 경우가 있어서 x z 방향 두 개로 나눠서 움직이도록 세팅
				if not float_util.is_almost_zero(self.move_dir.x) then
					CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.target,
							vector(self.move_dir.x, 0, 0), magnitude)
				end

				if not float_util.is_almost_zero(self.move_dir.z) then
					CS.Oak.MoveOneFrameStageLogic.ExecuteMove(self.target,
							vector(0, 0, self.move_dir.z), magnitude)
				end
			end
		else
			-- 점프가 끝났고, 나가고 있는 상황이었을 때
			if self.remain_offset_adjust_dur <= 0 then
				-- 삭제가 필요함을 알림
				return true
			end
		end
	end

	return self.super:execute_move(dt, magnitude)
end

function default_character_mover:is_jumping()
	return lua_helper.type_compare(self.target.CharacterBehaviour.CurrentState, typeof(CS.Oak.CharacterJumpState))
end

--- CharacterStat UI 및 스파인 오프셋 조절
function default_character_mover:set_target_offset(offset)
	self.target.SpineController.SpineOffset = self.original_spine_offset + offset

	-- 캐릭터 스탯 ui 세팅
	if self.stat_ui ~= nil then
		self.stat_ui.Offset.localPosition = self.original_stat_ui_offset + offset
	end
end

--- CharacterStat UI 및 스파인 오프셋 조절
function default_character_mover:move_target_offset(diff)
	self.target.SpineController.SpineOffset = self.target.SpineController.SpineOffset + diff

	-- 캐릭터 스탯 ui 세팅
	if self.stat_ui ~= nil then
		self.stat_ui.Offset.localPosition = self.stat_ui.Offset.localPosition + diff
	end
end

--endregion Default Character Mover

--region Switchable Character Mover

function switchable_character_mover:init(controller, type)
	self.super:init(controller, type)

	self.play_mode = {
		acting = 1,
		screenplay = 2,
	}

	self.current_play_mode = self.play_mode.acting
end

function switchable_character_mover:attach_to(target)
	self.super:attach_to(target)

	-- TODO : 시작 조건 확인 필요
	self.current_play_mode = self.play_mode.acting

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
end

function switchable_character_mover:detach_from(target)
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.super:set_target_offset(unity_class.vector3.zero)

	self.super:detach_from(target)
end

function switchable_character_mover:dispose()
	self.super:dispose()
end

function switchable_character_mover:on_enter(zone, dir)
	if not self.super.super:on_enter(zone, dir) then
		return false
	end

	-- 최초 진입 시
	if self.entered_zone_count == 1 then
		-- 그림자 꺼버림
		self.target.SpineController.IsShadowActive = false

		if self.current_play_mode == self.play_mode.acting then
			if self.super:is_jumping() then
				self.remain_offset_adjust_dur = self.controller.constants.spine_offset_adjust_dur
			end
		end
	end

	return true
end

function switchable_character_mover:on_leave(zone, dir)
	if not self.super.super:on_leave(zone, dir) then
		return false
	end

	-- 컨베이어 벨트에서 완전히 나간 경우
	if self.entered_zone_count == 0 then
		-- 그림자 다시 켜줌
		self.target.SpineController.IsShadowActive = true

		if self.current_play_mode == self.play_mode.acting then
			if self.super:is_jumping() then
				self.remain_offset_adjust_dur = self.controller.constants.spine_offset_adjust_dur
			end
		end
	end

	return true
end

function switchable_character_mover:on_custom_stage_event(e)
	if not lua_helper.reference_equals(e.Sender, self.target) then
		return false
	end

	if e:GetParamAt(0) == 'conveyor_belt_switchable_character_mover' then
		if e:GetParamAt(1) == 'change_mode' then
			if e:GetParamAt(2) == 'acting' and self.current_play_mode == self.play_mode.screenplay then
				self.current_play_mode = self.play_mode.acting

				-- 이미 벨트 위에 있는 경우
				if self.entered_zone_count > 0 then
					-- 오프셋 및 위치 다시 세팅해줌
					-- TODO : Jump 중일 때도 처리 필요
					self:set_target_offset(self.controller.spine_offset)
					--self.target.Position = self.target.Position - self.controller.spine_offset
				end

			elseif e:GetParamAt(2) == 'screenplay' and self.current_play_mode == self.play_mode.acting then
				self.current_play_mode = self.play_mode.screenplay

				-- 이미 벨트 위에 있는 경우
				if self.entered_zone_count > 0 then
					-- 오프셋 및 위치 다시 세팅해줌
					-- TODO : Jump 중일 때도 처리 필요
					self:set_target_offset(unity_class.vector3.zero)
					--self.target.Position = self.target.Position + self.controller.spine_offset
				end
			end
		end
	end

	return false
end

function switchable_character_mover:set_target_offset(offset)
	local spine_diff = (self.original_spine_offset + offset) - self.target.SpineController.SpineOffset

	-- SpineController Update 시점이 Toolbox Update 시점보다 빠름
	-- 여기서 스파인 오프셋 변경하는 것은 이번 프레임에는 적용이 안되어있으므로 잠깐 튀는 문제가 있음
	-- 따라서 스파인 컨테이너를 직접 건드려서 오프셋 조절을 이번 프레임에만 강제로 맞춰줌
	self.target.SpineController.SpineContainerTransform.localPosition =
	self.target.SpineController.SpineContainerTransform.localPosition + spine_diff

	-- 얘는 다음 프레임에 업데이트될 것임
	self.target.SpineController.SpineOffset = self.original_spine_offset + offset

	self.target.Position = self.target.Position - spine_diff

	-- 캐릭터 스탯 ui 세팅
	if self.stat_ui ~= nil then
		self.stat_ui.Offset.localPosition = self.original_stat_ui_offset + offset
	end
end

function switchable_character_mover:execute_move(dt, magnitude)
	if self.current_play_mode == self.play_mode.acting then
		return self.super:execute_move(dt, magnitude)
	end

	return false
end

--endregion Switchable Character Mover

--endregion Mover

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
