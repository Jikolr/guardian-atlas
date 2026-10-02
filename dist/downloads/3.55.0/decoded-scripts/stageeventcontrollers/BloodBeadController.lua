local local_class = newclass('BloodBeadController')

-- 흡혈구슬 클래스
local bead_class = {
	mode = nil,
	fx = nil,
	collide_range = nil,
	is_collide_boss = false,
	is_move = false,
	move_speed = 0,
	move_direction = unity_class.vector3.zero,
	mode_fx_pool_list = { },
	mode_fx_consume_pool_list = { },
	mode_fx_hit_pool_list = { },
	start_position,
	end_position,
	time_passed,
	is_start_move
}
bead_class.meta_tale = { __index = bead_class }

function bead_class:new( mode, range, start_position, end_position, fx1_name, fx1_consume_name, fx1_hit_name, fx2_name, fx2_consume_name, fx2_hit_name, start_move)
	local obj = {}
	setmetatable(obj, self.meta_tale)

	-- 어떤 모드로 생성할 것인가.
	obj.mode = mode
	-- 어느 범위로 부딛혀서 사라지게 되는가
	obj.collide_range = range
	--구슬 모드에 따른 풀 등록된 리스트
	table.insert(obj.mode_fx_pool_list, unity_object_pool.GetOrCreate(fx1_name))
	table.insert(obj.mode_fx_pool_list, unity_object_pool.GetOrCreate(fx2_name))

	table.insert(obj.mode_fx_consume_pool_list, unity_object_pool.GetOrCreate(fx1_consume_name))
	table.insert(obj.mode_fx_consume_pool_list, unity_object_pool.GetOrCreate(fx2_consume_name))

	table.insert(obj.mode_fx_hit_pool_list, unity_object_pool.GetOrCreate(fx1_hit_name))
	table.insert(obj.mode_fx_hit_pool_list, unity_object_pool.GetOrCreate(fx2_hit_name))

	if start_move then
		obj.fx = obj.mode_fx_pool_list[mode]:Instantiate(start_position)
	else
		obj.fx = obj.mode_fx_pool_list[mode]:Instantiate(end_position)
	end
	obj.start_position = start_position
	obj.end_position = end_position
	obj.time_passed = 0

	obj.is_start_move = start_move

	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
			{
				--이벤트 정의
				'blood_bead_create',
				-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
				self.mode,
			}))

	return obj
end

-- 이펙트 해제 이후에 구슬테이블에서 빠지기전에 다시 체크되는 경우가 있어 충돌에 대한 조건 검사 추가함.
-- 캐릭터 받아서 거리 비교하고 해제
function bead_class:check_collide(target, is_boss)
	-- 초기 배치중에는 충돌하지 않음
	if self.is_start_move or self.fx == nil then
		return false
	end

	local position = self.fx.transform.position
	local target_position = target.Position
	local distance = vector_util.distance(vector_util.get_x0z(position), vector_util.get_x0z(target_position))
	if distance <= self.collide_range then

		if is_boss then
			music_player_util.play_sfx({ sfx_name = '02_lord_shoot_02', loop = false, type_priority = 'event', player_priority = 'default', play_pos = target_position })
		else
			music_player_util.play_sfx({ sfx_name = '02_priscilla_hit_01', loop = false, type_priority = 'event', player_priority = 'default', play_pos = target_position })
		end

		-- 흡혈구슬 흡수되어 사라졌음을 이벤트로 발행.
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
				{
					--이벤트 정의
					'blood_bead_collide',
					--누구랑 부딛혀서 없어지는지
					target.Name,
					-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
					self.mode,
					-- 좌표 y 는 일단 보내지 않음.
					-- 부딛힌 구슬 좌표 위치 x
					position.x,
					-- 부딛힌 구슬 좌표 위치 z
					position.z
				}))
		-- 흡수 이펙트 구슬 위치에 표시
		self.mode_fx_consume_pool_list[self.mode]:Instantiate(position)
		self.is_move = false

		if not is_unity_null(self.fx) then
			self.fx:Dispose()
		end
		self.fx = nil
		--충돌하여 해제 됨
		return true
	end

	return false
end

function bead_class:instantiate_hit_fx(boss)
	if self.is_collide_boss then
		-- 보스와 충돌 하는 경우에만 이펙트 표시
		-- 흡수 이펙트 흡수하는 캐릭터 중앙에 표시
		self.mode_fx_hit_pool_list[self.mode]:Instantiate(boss.Bounds.center)
	end
end

function bead_class:mode_change(mode)
	local save_position = self.fx.transform.position
	--현재 이펙트 삭제 하고
	if not is_unity_null(self.fx) then
		self.fx:Dispose()
		self.fx = nil
	end

	self.mode = mode
	--새로운 이펙트로 갱신
	self.fx = self.mode_fx_pool_list[mode]:Instantiate(save_position)
end

-- 이동 값 정의
function bead_class:set_move_data(is_move, dir, speed)
	self.is_move = is_move
	self.move_speed = speed
	self.move_direction = dir
end

-- 구슬 첫 배치시 움직임
function bead_class:start_bead_update_throw(dt)
	if self.is_start_move then
		self.time_passed = self.time_passed + dt
		local progress = self.time_passed / 0.5
		local y = math.sin(math.pi * progress) * 1
		local new_pos = vector_util.lerp(self.start_position, self.end_position, progress) + unity_class.vector3(0, y, 0)
		self.fx.transform.position = new_pos

		if progress >= 1 then
			self.is_start_move = false
			self.fx.transform.position = self.end_position
		end
	end
end

-- 구슬 이동
function bead_class:update_move(dt)
	if not self.is_move then return end

	local calc_pos = self.fx.transform.position + dt * self.move_speed * self.move_direction
	self.fx.transform.position = calc_pos
	CS.Oak.UnityObjectPoolExtensions.UpdateObject(self.fx, calc_pos, self.move_direction)
end

function bead_class:dispose()

	if not is_unity_null(self.fx) then
		self.fx:Dispose()
	end
	self.fx = nil

	-- 구슬 사라지는 시점에 이벤트 ??
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
			{
				--이벤트 정의
				'blood_bead_dispose',
				-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
				self.mode,
			}))

end

--흡혈 구술 생성 및 해제
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}

	self.current_boss_character = nil

	self.stage_data = require('stageeventcontrollers/BloodBeadControllerData.lua')
	self.current_stage_info = nil

	-- 생성 범위 (캐릭터 기준 위치에서 collide_range ~ create_range 범위 내에 최초 생성
	self.create_range = 0

	-- 현재 생성됭 구슬 리스트
	self.bead_list = { }
	-- 구슬 생성범위 배틀존 밖으로 벗어나지 않게 계산하기 위해 필요함.
	self.current_battle_zone = nil

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	self.current_stage_info = self.stage_data[stage.Name]
	if self.current_stage_info ~= nil then
		self.fx1_name = self.current_stage_info.bead1_name
		self.fx1_consume_name = self.current_stage_info.bead1_consume_name
		self.fx1_hit_name = self.current_stage_info.bead1_hit_name
		self.fx2_name = self.current_stage_info.bead2_name
		self.fx2_consume_name = self.current_stage_info.bead2_consume_name
		self.fx2_hit_name = self.current_stage_info.bead2_hit_name
		self.create_range = self.current_stage_info.create_range
		-- 구슬 먹었을때의 힐 비율
		self.heal_ratio = self.current_stage_info.heal_ratio
	end

	-- 오브젝트 풀 미리 로드
	unity_object_pool.GetOrCreate(self.fx1_name)
	unity_object_pool.GetOrCreate(self.fx2_name)
	unity_object_pool.GetOrCreate(self.fx1_consume_name)
	unity_object_pool.GetOrCreate(self.fx2_consume_name)
	unity_object_pool.GetOrCreate(self.fx1_hit_name)
	unity_object_pool.GetOrCreate(self.fx2_hit_name)

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

-- 포지션 기준 랜덤위치 생성하지 않고 해당 위치에 생성 하도록 함.
function local_class:create_bead_on_position(position, mode)
	-- 인덱스도 1 부터 시작하도록
	if #self.bead_list >= self.current_stage_info.bead_max_count then
		-- 새로 추가할 구슬이 맥시멈카운트보다 많다면 제일 먼저 생성된것 삭제
		local remove_bead = table.remove(self.bead_list, 1)
		remove_bead:dispose()
		remove_bead = nil
	end
	-- 주어진 포지션 위치에 바로 생성해야 하므로
	-- 일단 해당 위치에 바로 생성하도록 하되..
	local new_position = position
	self.loop_count = 0
	if not self:check_bead_position(position) then
		--다른 구슬과 곂치는 부분 있다면 위치 조정 들어감.
		new_position = self:get_bead_position(position)
	end

	if mode == nil then
		mode = 1
	end

	table.insert(self.bead_list, bead_class:new(mode, self.current_stage_info.collide_range, position, new_position,
			self.fx1_name, self.fx1_consume_name, self.fx1_hit_name, self.fx2_name, self.fx2_consume_name, self.fx2_hit_name, false))
end

function local_class:create_bead(position, count, start_move)
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
		table.insert(self.bead_list, bead_class:new(1, self.current_stage_info.collide_range, position, new_position,
				self.fx1_name, self.fx1_consume_name, self.fx1_hit_name, self.fx2_name, self.fx2_consume_name, self.fx2_hit_name, start_move))
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
	end
	
    -- 기존 나와있는 구슬들 위치에서 create_range 범위안에 곂치는 위치인지 확인
    for _, v in pairs(self.bead_list) do
        local dist = vector_util.distance(vector_util.get_x0z(position) , vector_util.get_x0z(v.end_position))
        
        -- 1개라도 걸린다면 바로 false
        if dist <= self.current_stage_info.create_collide_range then
            return false
        end
    end

    return true
end

--타겟에서 가장 먼 구슬 찾아서 모드 변경할수 있도록
function local_class:change_farthest_bead_mode(mode, target)
	if #self.bead_list == 0 then
		return
	end

	local far_dist = 0
	local selected_index = 0
	-- 가장 먼 구슬 찾기
	for i = #self.bead_list, 1, -1 do
		local bead = self.bead_list[i]
		local dist = vector_util.distance(target.Position, bead.fx.transform.position)
		if dist > far_dist then
			far_dist = dist
			selected_index = i
		end
	end

	local selected_bead = table.remove(self.bead_list, selected_index)
	selected_bead:mode_change(mode)
	table.insert(self.bead_list, selected_bead)
end

-- 기존 구슬들 중에 모드 변경 해야 하는 경우 호출
function local_class:change_bead_mode(mode, count)
	local beads = random_util.get_values_in_array(self.bead_list, {
		overlap = false,
		count = count
	})

	for _, v in pairs(beads) do
		v:mode_change(mode)
		table.insert(self.bead_list, v)
	end
end

-- 전체 구슬 보스에게로 이동..
function local_class:all_beads_move_to_target(target)
	for _, v in pairs(self.bead_list) do
		local dir = vector_util.get_x0z(target.Position - v.fx.transform.position, v.fx.transform.position.y).normalized
		local speed = self.current_stage_info.bead_move_speed
		v:set_move_data(true, dir, speed)
		-- 보스에게 구슬이 가는 경우로 지정되면 보스에게도 충돌 되도록 한다.
		if lua_helper.reference_equals(target, self.current_boss_character) then
			v.is_collide_boss = true
		end
	end
end

-- 구슬 근처에 캐릭터가 존재하면 구슬과 충돌되어 없어지도록.
-- 역순으로 비교하여 없앰.
function local_class:collide_bead()
	for i = #self.bead_list, 1, -1 do
		local bead = self.bead_list[i]
		-- 파티와 검사
		local fo_list = field:GetFieldObjectsInRadius(bead.fx.transform.position, self.current_stage_info.collide_range)
		for _, v in pairs(fo_list) do
			if CS.Oak.EntityGroupsExtensions.IsHittableTo(self.current_boss_character.EntityGroup, v.EntityGroup) then
				if  bead:check_collide(v) then
					-- 일반 구슬일때 힐 기능 호출 되도록 한다.
					if bead.mode == 1 then
						self:heal_target(v)
					end
					bead:dispose()

					table.remove(self.bead_list, i)
				end
			elseif bead.is_collide_boss and self.current_boss_character ~= nil then
				if lua_helper.reference_equals(v, self.current_boss_character) then
					if  bead:check_collide(v, true) then
						-- 보스일경우에만 흡수할때 보스에게 이펙트 표시함
						bead:instantiate_hit_fx(v)
						bead:dispose()
						table.remove(self.bead_list, i)
					end
				end
			end
		end
		fo_list:Dispose()
	end
end

-- 모든 피격시마다 구슬을 생성하는게 아니기 때문에 커스텀이벤트 받아서 처리하도록 한다.
-- 공통사항으로 파라메터

function local_class:on_custom_stage_event(e)
	-- 0 - 이벤트명
	-- 1 - 타겟 캐릭터 이름
	-- 2 - 생성할 구슬 갯수
	if e:GetParamAt(0) == 'blood_bead_drop_request_by_target' then
		local target = get_character(e:GetParamAt(1))
		self:create_bead(target.Position, tonumber(e:GetParamAt(2)), true)
		-- 해당하는 특정 포지션에 생성
	elseif e:GetParamAt(0) == 'blood_bead_drop_request_by_position' then
		local target_position = unity_class.vector3(tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)), tonumber(e:GetParamAt(3)))
		self:create_bead_on_position(target_position, tonumber(e:GetParamAt(4)))
	elseif e:GetParamAt(0) == 'blood_bead_mode_change_request' then
		self:change_bead_mode(tonumber(e:GetParamAt(1)), tonumber(e:GetParamAt(2)))
	elseif e:GetParamAt(0) == 'blood_bead_mode_change_request_by_farthest' then
		local target = get_character(e:GetParamAt(2))
		self:change_farthest_bead_mode(tonumber(e:GetParamAt(1)), target)
	elseif e:GetParamAt(0) == 'blood_bead_move_request_by_target' then
		-- 모든 구슬은 보스에게 이동하여 흡수 될것.
		local target = get_character(e:GetParamAt(1))
		self:all_beads_move_to_target(target)
	elseif e:GetParamAt(0) == 'init_bead_controller' then
		-- 세팅된 순간부터 컨트롤러 기능 시작 하도록 수정
		self.current_boss_character = get_character(e:GetParamAt(1))
		self.current_battle_zone = field:GetZone(e:GetParamAt(2))
		self.current_progress = self.progress.playing
	elseif e:GetParamAt(0) == 'remove_beads' then
		self:remove_all_beads()
	elseif e:GetParamAt(0) == 'dispose_bead_controller' then
		-- 플레이 시작 이후에 해제 가능하도록
		if self.current_progress == self.progress.playing then
			self:dispose_all_beads()
			self.current_progress = self.progress.done
		end
	end
end

function local_class:update_beads(dt)

	if #self.bead_list == 0 then
		return
	end

	for _, v in pairs(self.bead_list) do
		v:start_bead_update_throw(dt)
		v:update_move(dt)
	end

	self:collide_bead()
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
end

-- 일반 구슬 접촉에 의한 치료
function local_class:heal_target(target)
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = target
	heal_info.target = target
	heal_info.heal = math.floor(target.FieldObjectStatsBehaviour.MaxHpWoMod * self.heal_ratio)
	command_util.execute_heal(heal_info)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	self:dispose_all_beads()

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil
end



return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
