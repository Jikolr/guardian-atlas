local local_class = newclass('TowerChasingLaserController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 레이저 chest_box 가져오는 함수
	self.get_chest_box = function(index)
		return get_field_object('tower_laser_' .. index)
	end

	-- 레이저 기믹 존
	self.get_laser_loop_zone = function(index)
		return field:GetZone('laser_zone_' .. index)
	end

	-- 레이저 기믹의 상태
	-- none : 시작 전 / start : 시작 / game_over : 게임오버 됬을 때 / finish : 전투가 끝났을 때
	self.gimmick_state = { none = 1, start = 2, reached = 4, game_over = 5, finish = 6 }

	-- 현재 기믹 상태 초기화
	self.current_gimmick_state = self.gimmick_state.none

	-- 현재 레이저 루틴이 돌아가고 있는가?
	self.is_running_laser_gimmick = false

	-- 기믹 루틴 겹치지 않기 위한 방지용
	self.is_active_gimmick_routine = false

	--레이저 저장하여 사용
	self.lasers = {}

	self.stage_data = require('stageeventcontrollers/TowerChasingLaserData.lua')

	-- 현재 들어간 존을 세팅한다.
	self.current_zone = nil

	-- 현재 스테이지 정보
	self.current_stage_info = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.GameOverEvent), 'on_game_over_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	--리소스 프리로드
	self.current_stage_info = self.stage_data[stage.Name]
	-- 레이저 관련 항목의 초기화
	self:init_lasers()
end

function local_class:init_virtual_wall(laser1_pos, laser2_pos)
	-- 현재 스테이지 정보 읽어온 후 세팅..
	-- 아카유키, 비슈바크가 레이저를 넘어가지 못하도록 하기위해서 가상 벽을 설치하여레이저 뒤쪽에서 쫒아오도록 함.
	self.virtual_wall = CS.Oak.VirtualFieldObject()
	self.virtual_wall.Name = 'block_character_wall'

	local hitbox_size_x = 1
	local hitbox_size_z = 1

	--hitbox 사이즈는 레이저 진행 방향에 따라서 바꿔야 하므로.. 체스트 박스 두개 위치 이용해서 세팅 할것.
	if self.current_stage_info.direction == 'Right' or self.current_stage_info.direction == 'Left'then
		hitbox_size_z = vector_util.distance(laser1_pos, laser2_pos)
	elseif self.current_stage_info.direction == 'Up' or self.current_stage_info.direction == 'Down'then
		hitbox_size_x = vector_util.distance(laser1_pos, laser2_pos)
	end
	self.virtual_wall.Hitbox = CS.Oak.Hitbox(vector(hitbox_size_x, 1, hitbox_size_z))
	self.virtual_wall.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	self.virtual_wall.EntityGroup = CS.Oak.EntityGroups.Obstacle
	self.virtual_wall.ActiveState = CS.Oak.ActiveState.Disabled
end

function local_class:on_stage_start_event(e)
	if #self.lasers > 1 then
		self.lasers[1].FieldObjectBehaviour:SetDamageType(CS.Oak.DamageType.Death)
	end
end

function local_class:on_zone_enter_event(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
	local zone_name = e.Zone.Name

	--현재의 존이름이 지정되어있는 존 이름과 같다면
	for i = 1, #self.current_stage_info.gimmick_start_zone_names do
		if zone_name == self.current_stage_info.gimmick_start_zone_names[i] then
			self.current_zone = e.Zone
			--기믹이 시작되지 않았을때 시작하도록 함.
			if self.current_gimmick_state == self.gimmick_state.none then
				self.current_gimmick_state = self.gimmick_state.start
				self.is_running_laser_gimmick = true
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gimmick_routine, self))
				return true
			end
		end
	end
	return false
end

-- 게임오버 됬을 때 기믹 루프를 꺼준다.
function local_class:on_game_over_event(e)
	-- 레이저 기믹을 더이상 돌지 않게 하고
	-- current_gimmick_state를 game_over로 변경한다.
	self.is_running_laser_gimmick = false
	self.current_gimmick_state = self.gimmick_state.game_over
	return true
end

--전투가 끝났다고 기믹이 작동을 멈추지는 않는다.
--대신 맵 클리어시 Disabled 시켜야 함.
function local_class:disabled_chest_box()
	--기믹 작동중이 아니라면...
	if not self.is_running_laser_gimmick then return end

	self.is_running_laser_gimmick = false
	self.current_gimmick_state = self.gimmick_state.finish

	-- chest 1에서 레이저롤 쏘고 있으니 1에서 이팩트 Deactive
	self.lasers[1].FieldObjectBehaviour:DeactiveLaserEffect()
	self.lasers[2].FieldObjectBehaviour:DeactiveLaserEffect()

	-- 체스트 박스들 Disabled
	self.lasers[1].ActiveState = active_state('disabled')
	self.lasers[2].ActiveState = active_state('disabled')
end

function local_class:init_lasers()
	self.zone = self.get_laser_loop_zone(1)
	self.zone_bound = self.zone.Bounds

	local gimmick_count_in_zone = 2
	-- 초기 레이저 기믹에 대한 세팅
	for i = 1, gimmick_count_in_zone do
		local laser = self.get_chest_box(i)
		-- 기믹이 향해야 할 방향이 오른쪽이라면 해당 존의 왼쪽에 초기 세팅 해주도록 한다.
		if self.current_stage_info.direction == 'Right' then
			if i == 1 then
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(-self.zone_bound.extents.x, 0, self.zone_bound.extents.z))
			else
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(-self.zone_bound.extents.x, 0, -self.zone_bound.extents.z))
			end
			--기믹이 향해야 할 방향이 왼쪽이라면 해당 존의 오른쪽에 초기 세팅을 해주도록 한다.
		elseif self.current_stage_info.direction == 'Left' then
			if i == 1 then
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(self.zone_bound.extents.x, 0, self.zone_bound.extents.z))
			else
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(self.zone_bound.extents.x, 0, -self.zone_bound.extents.z))
			end
			--기믹이 향해야 할 방향이 위쪽이라면 해당 존의 아래쪽에 초기 세팅을 해주도록 한다.
		elseif self.current_stage_info.direction == 'Up' then
			if i == 1 then
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(self.zone_bound.extents.x, 0, -self.zone_bound.extents.z))
			else
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(-self.zone_bound.extents.x, 0, -self.zone_bound.extents.z))
			end
			--기믹이 향해야 할 방향이 위쪽이라면 해당 존의 아래쪽에 초기 세팅을 해주도록 한다.
		elseif self.current_stage_info.direction == 'Down' then
			if i == 1 then
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(self.zone_bound.extents.x, 0, self.zone_bound.extents.z))
			else
				laser.Position = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
						vector(-self.zone_bound.extents.x, 0, self.zone_bound.extents.z))
			end
		end
		laser.ActiveState = active_state('enabled')
		laser.FieldObjectBehaviour:PauseLaserEffect()
		table.insert(self.lasers, laser)
	end

end
-- 레이저 기믹 루틴
function local_class:gimmick_routine()
	while self.is_active_gimmick_routine do
		if not self.is_running_laser_gimmick then
			return
		end
		coroutine.yield(nil)
	end

	-- 레이저 초기화 끝나야 시작
	while #self.lasers < 0 do
		coroutine.yield(nil)
	end

	self.is_active_gimmick_routine = true
	-- 매뉴얼 캐릭터 특수 이동상황으로 레이저 뒤쪽으로 넘어가지 못하도록 가상 벽 설치
	self:init_virtual_wall(self.lasers[1].Position, self.lasers[2].Position)

	--레이저 초기 위치 세팅 후 특정시간 대기
	wait_for_sec(self.current_stage_info.wait_for_active)

	if self.virtual_wall.ActiveState == CS.Oak.ActiveState.Disabled then
	self.virtual_wall.ActiveState = active_state('enabled')
	end

	-- 레이저 1번에서 레이저를 사용..
	self.lasers[1].FieldObjectBehaviour.DamageRate = 100
	self.lasers[1].FieldObjectBehaviour:ResumeLaserEffect()
	self.lasers[1].FieldObjectBehaviour.IsActiveLaserIntersectCheck = true

	local sfx_loop = music_player_util.play_sfx({ sfx_name = '02_light_laser_loop_01', loop = true,
	type_priority = 'gimmick', player_priority = 'player', fade_in_time = 2 })

	local destination1 = vector(0,0,0)
	local destination2 = vector(0,0,0)
	--최종적으로 도달하여 멈추게될 위치
	if self.current_stage_info.direction == 'Right' then
	destination1 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( self.zone_bound.extents.x , 0, self.zone_bound.extents.z))
	destination2 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( self.zone_bound.extents.x , 0, -self.zone_bound.extents.z))
	elseif self.current_stage_info.direction == 'Left' then
	destination1 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( -self.zone_bound.extents.x , 0, self.zone_bound.extents.z))
	destination2 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( -self.zone_bound.extents.x , 0, -self.zone_bound.extents.z))
	elseif self.current_stage_info.direction == 'Up' then
	destination1 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( self.zone_bound.extents.x , 0, self.zone_bound.extents.z))
	destination2 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( -self.zone_bound.extents.x , 0, self.zone_bound.extents.z))
	elseif self.current_stage_info.direction == 'Down' then
	destination1 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( self.zone_bound.extents.x , 0, -self.zone_bound.extents.z))
	destination2 = CS.BoundsExtensions.ConvertToZoneRelativeToWorldToLua(self.zone_bound,
	vector( -self.zone_bound.extents.x , 0, -self.zone_bound.extents.z))
	end

	while self.is_running_laser_gimmick do
	-- 레이저 기믹 박스 위치 세팅
	local dt = unity_class.time.deltaTime

	local final_pos1 = self.lasers[1].Position
	local final_pos2 = self.lasers[2].Position

	-- 이동속도
	local movement = dt * self.current_stage_info.speed * 3

	local diff1 = vector_util.get_x0z(destination1 - final_pos1, 0)
	local diff2 = vector_util.get_x0z(destination2 - final_pos2, 0)

	-- 존의 반대쪽까지 도달하면 레이저 기믹이 이동을 정지한다. (레이저 발사 지속됨.)
	if movement > 0 then
		if vector_util.magnitude(diff1) > movement then
		final_pos1 = vector_util.normalized(diff1) * movement
		final_pos2 = vector_util.normalized(diff2) * movement

		self.lasers[1].Position = vector_util.get_x0z(self.lasers[1].Position + final_pos1, 0)
		self.lasers[2].Position = vector_util.get_x0z(self.lasers[2].Position + final_pos2, 0)

		local virtual_wall_position = vector_util.lerp(self.lasers[1].Position, self.lasers[2].Position, 0.5)

		if self.current_stage_info.direction == 'Right' then
		virtual_wall_position.x = virtual_wall_position.x - 0.5
		elseif self.current_stage_info.direction == 'Left' then
		virtual_wall_position.x = virtual_wall_position.x + 0.5
		elseif self.current_stage_info.direction == 'Up' then
		virtual_wall_position.z = virtual_wall_position.z - 0.5
		elseif self.current_stage_info.direction == 'Down' then
		virtual_wall_position.z = virtual_wall_position.z + 0.5
		end
		--어차피 한방에 죽으니까 캐릭터가 밀리거나 할 필요는 없이 레이저에 타격될수 있는 위치에 멈출수 있으면 됨.
		self.virtual_wall.Position = vector_util.get_x0z(virtual_wall_position, 0)
		end
	end

	coroutine.yield(nil)

	--오브젝트 최종위치 도달.
	if vector_util.magnitude(diff1) < 0.09 and vector_util.magnitude(diff2) <0.09  then
		self.lasers[1].Position = destination1
		self.lasers[2].Position = destination2
		break
	end

	end
	sfx_loop:Stop()

	self.is_active_gimmick_routine = false
	self.current_gimmick_state = self.gimmick_state.reached
	end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GameOverEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	-- 기믹 dispose. 코루틴 돌릴 필요 없음.
	self:disabled_chest_box()

	if self.virtual_wall ~= nil then
		self.virtual_wall:Dispose()
	end

	self.lasers = nil
	self.zone = nil
	self.zone_bound = nil

	self.current_stage_info = nil
	self.stage_data = nil
	self.is_running_laser_gimmick = false
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
