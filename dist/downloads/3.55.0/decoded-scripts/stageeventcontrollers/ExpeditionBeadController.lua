local local_class = newclass('ExpeditionBeadController')

-- 흡혈구슬 클래스
local bead_class = {
	fx = nil,
	--초기 배치
	is_start_move = false,
	collide_range = nil,
	fx_pool= nil,
	fx_trail_pool = nil,
	fx_consume_pool = nil,
	start_position = nil,
	position = nil,
	time_passed = 0,
	is_consume_move = false,
	target = nil,
	event_id = nil
}
bead_class.meta_tale = { __index = bead_class }

function bead_class:new(range, start_position, position, event_id, fx_name, fx_trail_name, fx_consume_name)
	local obj = {}
	setmetatable(obj, self.meta_tale)

	-- 어느 범위로 부딛혀서 사라지게 되는가
	obj.collide_range = range
	--구슬 모드에 따른 풀 등록된 리스트
	obj.fx_pool = function() return unity_object_pool.GetOrCreate(fx_name) end
	obj.fx_trail_pool = function() return unity_object_pool.GetOrCreate(fx_trail_name) end
	obj.fx_consume_pool = function() return unity_object_pool.GetOrCreate(fx_consume_name) end

	obj.fx = obj.fx_pool():Instantiate(start_position)
	obj.fx_trail_pool():Instantiate(start_position, unity_class.quaternion.identity, obj.fx.transform)

	obj.start_position = start_position
	obj.position = position
	obj.event_id = event_id
	obj.time_passed = 0
	-- 첫 생성시..
	obj.is_start_move = true

	return obj
end

-- 이펙트 해제 이후에 구슬테이블에서 빠지기전에 다시 체크되는 경우가 있어 충돌에 대한 조건 검사 추가함.
-- 캐릭터 받아서 거리 비교하고 해제
function bead_class:check_collide(target)
	-- 초기 배치중에는 충돌하지 않음
	if self.is_start_move or self.fx == nil or self.is_consume_move then
		return false
	end

	local position = self.fx.transform.position
	local target_position = target.Position
	local distance = vector_util.distance(vector_util.get_x0z(position), vector_util.get_x0z(target_position))
	if distance <= self.collide_range then
		-- 캐릭터에 빨려들어가는 모드 시작
		self.is_consume_move = true
		self.target = target
		self.time_passed = 0
		return true
	end
	return false
end

function bead_class:consume_bead()

	message_system:Publish(CS.Oak.ExpeditionStageCustomEvent.Create(self.event_id))
	self.fx_consume_pool():Instantiate(self.target.Position, unity_class.quaternion.identity, self.target.Transform)
	-- 먹는 사운드
	music_player_util.play_sfx({ sfx_name = '01_bounce_light_01', loop = false, type_priority = 'event', player_priority = 'default', play_pos = self.target.Position })
	if not is_unity_null(self.fx) then
		self.fx:Dispose()
	end
	self.fx = nil
	self.is_consume_move = false
	self.target = nil
end

-- 업데이트
function bead_class:update_frame(dt)
	self.time_passed = self.time_passed + dt
	if self.is_start_move then
		local progress = self.time_passed / 0.5
		local y = math.sin(math.pi * progress) * 1
		local new_pos = vector_util.lerp(self.start_position, self.position, progress) + unity_class.vector3(0, y, 0)
		self.fx.transform.position = new_pos

		if progress >= 1 then
			self.is_start_move = false
			self.fx.transform.position = self.position
			CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx, self.position, unity_class.vector3.zero)
		end
	end
end

function bead_class:update_consume(dt)
	self.time_passed = self.time_passed + dt
	if self.is_consume_move then
		if not is_unity_null(self.target) then
			-- 플레이어와 접촉해서 흡수되는 동작 하는 구슬

			local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseInSine(self.time_passed, 0, 1, 0.3))
			-- sin 이동 하지 않고 liner 하게 움직이도록
			local new_pos = vector_util.lerp(self.position, self.target.Position, progress)
			self.fx.transform.position = new_pos
			CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx, new_pos, unity_class.vector3.zero)
			if progress >= 1 then
				self:consume_bead()
				return true
			end
		end
	end
	return false
end

function bead_class:check_time_passed(max_duration)
	if self.time_passed >= max_duration then
		return true
	else
		return false
	end
end

function bead_class:dispose()
	-- 구슳 이펙트 제거
	if not is_unity_null(self.fx) then
		self.fx:Dispose()
	end
	self.fx = nil
end

--흡혈 구술 생성 및 해제
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}

	self.stage_data = require('stageeventcontrollers/ExpeditionBeadControllerData.lua')
	self.current_stage_info = nil

	-- 생성 범위 (기준 위치에서 collide_range ~ create_range 범위 내에 최초 생성
	self.create_range = 0

	-- 현재 생성됭 구슬 리스트
	self.bead_list = { }
	-- 삭제될 구슬 리스트
	self.consume_bead_list = { }
	-- 구슬 생성범위 배틀존 밖으로 벗어나지 않게 계산하기 위해 필요함.
	self.current_battle_zone = nil

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.PartySwitchingEvent), 'on_party_switch_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	self.current_stage_info = self.stage_data[stage.Name]
	if self.current_stage_info ~= nil then
		self.fx_name = self.current_stage_info.bead_name
		self.fx_trail_name = self.current_stage_info.bead_contrail_name
		self.fx_consume_name = self.current_stage_info.bead_consume_name
		self.create_range = self.current_stage_info.create_range
		self.max_duration = self.current_stage_info.max_duration
	end

	-- 오브젝트 풀 미리 로드
	unity_object_pool.GetOrCreate(self.fx_name)
	unity_object_pool.GetOrCreate(self.fx_trail_name)
	unity_object_pool.GetOrCreate(self.fx_consume_name)

	music_player:PreloadSfx('01_bounce_light_01')

	self.loop_count = 0
	self.current_progress = self.progress.none

	return
end

--런치루틴 사용 안함.
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)

end

function local_class:create_bead(position, count, event_id)
	for i = 1, count do
		-- 인덱스도 1 부터 시작하도록
		if #self.bead_list >= self.current_stage_info.bead_max_count then
			-- 새로 추가할 구슬이 맥시멈카운트보다 많다면 제일 먼저 생성된것 삭제
			local remove_bead = table.remove(self.bead_list, 1)
			remove_bead:dispose()
			remove_bead = nil
		end
		self.loop_count = 0
		-- 일반적으로 생성할때는 타겟 위치에서 랜덤위치로 조정 후 생성하도록 함.
		local new_position = self:get_bead_position(position)
		table.insert(self.bead_list, bead_class:new(self.current_stage_info.collide_range, position, new_position, event_id, self.fx_name, self.fx_trail_name, self.fx_consume_name))
	end
end

-- 현재 있는 포지션에대해 기존에 생성되어 있는 포지션들 검사 해서 범위에 곂치지 않는 포지션을 하나 리턴
function local_class:get_bead_position(position)
	self.loop_count = self.loop_count + 1
	
	local new_position = position

	-- 들어온 위치가 기준이 되는 캐릭터 위치임.
	-- 캐릭터 주변 5타일 이내에 랜덤 드랍 (타일 위치기반으로 랜덤 계산하도록.. )
	-- 바로 충돌나서 없어지지 않도록 self.current_stage_info.collide_range 범위밖에 생성되도록 하야 함.
	local distance = CS.UnityEngine.Random.Range(self.current_stage_info.create_collide_range, self.create_range)
	local rand_angle = unity_class.random.Range(0.0, 359.9999)
	local rand_dir = unity_class.quaternion.AngleAxis(rand_angle, unity_class.vector3.up) * unity_class.vector3.forward
	
	-- 랜덤 회전값 만큼 회전시켜서 해당 방향으로 랜덤 거리만큼 이동
	new_position = position + rand_dir.normalized * distance

	if false == self.current_battle_zone:Contains(new_position) then
		-- 새로 결정된 포지션이 배틀존 안에 없으면
		new_position = CS.BoundsExtensions.ConvertPositionToInsideOfBounds(self.current_battle_zone.Bounds, new_position, self.current_stage_info.collide_range)
		
		-- 조정해준 애가 문제 있으면 처음으로 되돌아감
		if false == self:check_bead_position(new_position) then
			return self:get_bead_position(position)
		end
		
		return new_position
		
	elseif true == self:check_bead_position(new_position) then
	    -- 문제 없는 경우
		return new_position
	    
	else
	    -- 문제가 있으면 다음 interpolate.
		return self:get_bead_interpolate_position(new_position, position)
	end
end

-- interpolate max 인자를 현재 loop count 기반으로 정하고 target 과 origin 과의 거리를 비교한다.
function local_class:is_interpolate_max(target, origin, bead_loop_count, add_create_range)
    local max = self.current_stage_info.create_collide_range + add_create_range * (bead_loop_count / 4)
    return vector_util.distance(vector_util.get_x0z(target) , vector_util.get_x0z(origin)) <= max
end

-- prev 위치에서 최초 위치인 origin_position 과 비교해 외부로 interpolate 해준다.
function local_class:get_bead_interpolate_position(prev, origin_position)
	self.loop_count = self.loop_count + 1
	
	local new_position = prev
	local add_create_range = 1
	local distance = CS.UnityEngine.Random.Range(self.current_stage_info.create_collide_range, self.current_stage_info.create_collide_range + self.current_stage_info.create_collide_range)
	local rand_angle = unity_class.random.Range(-60, 60)
	local polated_vec = prev - origin_position
	local rand_dir = unity_class.quaternion.AngleAxis(rand_angle, unity_class.vector3.up) * polated_vec
	
	-- 최초 포지션인 origin_position 을 기준으로 prev 위치에서 바깥쪽 좌우 각도에서 랜덤하게 위치를 선택한다.
	new_position = prev + (rand_dir.normalized * distance)
	
	-- 일단 먼저 interpolate max 에 도달하였는지 체크.
	if false == self:is_interpolate_max(new_position, origin_position, self.loop_count, add_create_range) then
		return self:get_bead_position(origin_position)
	end
	
	if false == self.current_battle_zone:Contains(new_position) then
		-- 새로 결정된 포지션이 배틀존 안에 없으면
		new_position = CS.BoundsExtensions.ConvertPositionToInsideOfBounds(self.current_battle_zone.Bounds, new_position, self.current_stage_info.collide_range)
		
		-- 조정해준 애가 문제 있으면 처음으로 되돌아감
		if false == self:check_bead_position(new_position) then
			return self:get_bead_position(origin_position)
			
		else
			return new_position
		end
		
	elseif true == self:check_bead_position(new_position) then
		-- 문제 없는 경우
		return new_position
	    
	else
		-- 문제가 있으면 다음 interpolate.
		return self:get_bead_interpolate_position(new_position, origin_position)
	end
end

-- 곂치는 위치가 있다면 false, 곂치는 위치가 없으면 true
function local_class:check_bead_position(position)
	if #self.bead_list == 0 then
		return true
	else
		local is_condition_checked = false
		-- 기존 나와있는 구슬들 위치에서 create_range 범위안에 곂치는 위치인지 확인
		for _, v in pairs(self.bead_list) do
			local dist = vector_util.distance(vector_util.get_x0z(position) , vector_util.get_x0z(v.position))
			--조건 만족하면 리턴
			-- 개별 검사해서 리턴이 아니라 전체 리스트 다 검사후 리턴되어야 함.
			-- 따라서 조건 검사 이후
			if dist <= self.current_stage_info.create_collide_range then
				is_condition_checked = true
			end
		end

		-- 다른 위치들과 검사가 끝난 후 조건에 걸린게 없으면 바로 리턴
		if not is_condition_checked then
			return true
		else
			--검사 다 했는데 조건이 만족되지 않았으면 포지션 다시 설정해서 재검사?
			return false
		end
	end
end

-- 파티 스위칭되어 변경된경우에 구슬 먹을수 있는 캐릭터를 변경 해줌.
function local_class:on_party_switch_event(e)
	self.manual_character = e.CurrentParty.Leader
end

-- 모든 피격시마다 구슬을 생성하는게 아니기 때문에 커스텀이벤트 받아서 처리하도록 한다.
-- 공통사항으로 파라메터

function local_class:on_custom_stage_event(e)
	-- 0 - 이벤트명
	-- 1 - 기믹 위치
	if e:GetParamAt(0) == 'expedition_bead_drop_request' then
		-- 구슬 생성시
		-- 포지션
		-- 갯수
		-- 이벤트 id
		-- 순서로 이벤트 보낸다.
		local target_position = unity_class.vector3(tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)), tonumber(e:GetParamAt(3)))
		self:create_bead(target_position, tonumber(e:GetParamAt(4)), tonumber(e:GetParamAt(5)))
	elseif e:GetParamAt(0) == 'init_expedition_bead_controller' then
		-- 세팅된 순간부터 컨트롤러 기능 시작 하도록 수정
		self.current_battle_zone = field:GetZone(e:GetParamAt(1))
		self.manual_character = get_party_leader()
		self.current_progress = self.progress.playing
	elseif e:GetParamAt(0) == 'remove_expedition_beads' then
		self:remove_all_beads()
	elseif e:GetParamAt(0) == 'dispose_expedition_bead_controller' then
		-- 플레이 시작 이후에 해제 가능하도록
		if self.current_progress == self.progress.playing then
			self:dispose_all_beads()
			self.current_progress = self.progress.done
		end
	end
end

function local_class:update_beads(dt)

	if #self.bead_list > 0 then
		-- 구슬 근처에 캐릭터가 존재하면 구슬과 충돌되어 없어지도록.
		-- 역순으로 비교하여 없앰.
		for i = #self.bead_list, 1, -1 do
			local bead = self.bead_list[i]
			bead:update_frame(dt)
			-- 매뉴얼 캐릭터와 검사 또는 유지시간 지났는지 검사
			if  bead:check_collide(self.manual_character) then
				local consume_bead = table.remove(self.bead_list, i)
				table.insert(self.consume_bead_list , consume_bead)
			elseif bead:check_time_passed(self.max_duration) then
				-- 이쪽은 그냥 사라지도록 처리함.
				bead:dispose()
				table.remove(self.bead_list, i)
			end
		end
	end

	if #self.consume_bead_list > 0 then
		for i = #self.consume_bead_list, 1, -1 do
			local bead = self.consume_bead_list[i]
			if bead:update_consume(dt) then
				bead:dispose()
				table.remove(self.consume_bead_list, i)
			end
		end
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end
	self:update_beads(dt)
end

-- 이벤트에 의한 구슬 삭제
-- 구슬 해제되었음을 이벤트 발송하도록 함.
function local_class:remove_all_beads()
	if #self.bead_list > 0 then
		for i = #self.bead_list, 1, -1 do
			self.bead_list[i]:dispose()
			table.remove(self.bead_list, i)
		end
	end

	if #self.consume_bead_list > 0 then
		for i = #self.consume_bead_list, 1, -1 do
			self.consume_bead_list:dispose()
			table.remove(self.consume_bead_list, i)
		end
	end
end

-- 전투 종료시 모든 구슬 해제 할수 있도록
-- 구슬 해제되었다는 이벤트는 보내지 않음. (전투자체가 종료 되었기 때문에)
function local_class:dispose_all_beads()
	if #self.bead_list > 0 then
		for i = #self.bead_list, 1, -1 do
			if not is_unity_null(self.bead_list[i].fx) then
				self.bead_list[i].fx:Dispose()
				self.bead_list[i].fx = nil
			end

			table.remove(self.bead_list, i)
		end
	end

	if #self.consume_bead_list > 0 then
		for i = #self.consume_bead_list, 1, -1 do
			if not is_unity_null(self.consume_bead_list[i].fx) then
				self.consume_bead_list[i].fx:Dispose()
				self.consume_bead_list[i].fx = nil
			end
			table.remove(self.consume_bead_list, i)
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PartySwitchingEvent))
	self:dispose_all_beads()

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
	self.manual_character = nil
end



return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
