local local_class = newclass('FallenQueenBeadController')

--카밀라 보스전 구슬 기믹
--2가지 모드의 구슬이 필드에 떨어지고 습득 구슬에 따라서 UI가 수정
--<5칸 >5칸으로 이루어진 UI 5칸끝에 도달하면 효과 발동
-- <5칸 달성시 보스에게 무력화기믹
-- >5칸 달성시 파티원에게 쉴드(전멸기 방어용,연출용)제공
--current_bead_gauge = -5 ~ 5로 구성

-- 구슬 클래스
local bead_class = {
	mode = nil,
	fx = nil,
	collide_range = nil,
	is_collide_boss = false,
	mode_fx_pool_list = { },
	mode_fx_consume_pool_list = { },
	mode_fx_hit_pool_list = { },
	start_position,
	end_position,
	time_passed,
	is_start_move
}
bead_class.meta_tale = { __index = bead_class }

function bead_class:new( mode, range, start_position, end_position, fx1_name, fx1_consume_name,
                         fx1_hit_name, fx2_name, fx2_consume_name, fx2_hit_name, start_move)
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

	--[[message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
			{
				--이벤트 정의
				'fallen_queen_bead_create',
				-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
				self.mode,
			}))]]

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

		--music_player_util.play_sfx({ sfx_name = '02_priscilla_hit_01', loop = false, type_priority = 'event', player_priority = 'default', play_pos = target_position })

		---- 구슬 모드에따라서 UI업데이트 필요
		--message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
		--		{
		--			--이벤트 정의
		--			'blood_bead_collide',
		--			--누구랑 부딛혀서 없어지는지
		--			target.Name,
		--			-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
		--			self.mode,
		--			-- 좌표 y 는 일단 보내지 않음.
		--			-- 부딛힌 구슬 좌표 위치 x
		--			position.x,
		--			-- 부딛힌 구슬 좌표 위치 z
		--			position.z
		--		}))
		-- 흡수 이펙트 구슬 위치에 표시
		self.mode_fx_consume_pool_list[self.mode]:Instantiate(position)

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
			self.time_passed = 0
		end
	end
end

function bead_class:dispose()

	if not is_unity_null(self.fx) then
		self.fx:Dispose()
	end
	self.fx = nil

	-- 구슬 사라지는 시점에 이벤트 ??
	--[[message_system:Publish(CS.Oak.CustomStageEvent.Create(nil,
			{
				--이벤트 정의
				'blood_bead_dispose',
				-- 현재 구슬 모드값 보내서 모드에 따른 동작 배틀액션에서 정의 할수 있도록 함.
				self.mode,
			}))]]

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

	self.stage_data = require('stageeventcontrollers/FallenQueenBeadControllerData.lua')
	self.current_stage_info = nil

	-- 생성 범위 (캐릭터 기준 위치에서 collide_range ~ create_range 범위 내에 최초 생성
	self.create_range = 0

	-- 현재 생성됭 구슬 리스트
	self.bead_list = { }
	-- 구슬 생성범위 배틀존 밖으로 벗어나지 않게 계산하기 위해 필요함.
	self.current_battle_zone = nil

	--기믹 게이지 -5 ~ 5
	self.current_gauge_value = 0

	self.fury_phase = {
		phase1 = 1,
		phase2 = 2
	}

	self.is_reset_gauge_ui = false
	self.is_second_phase = false
	self.gauge_ui_reset_time_passed = 0
	self.current_fury_phase = self.fury_phase.phase1

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

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

		--광폭화 이팩트(스크린)
		self.fx_fury_name = self.current_stage_info.fury_effect_name
		self.fx_fury_end_name = self.current_stage_info.fury_break_effect_name
		--광폭화 방어막 이팩트(보스)
		self.fx_fury_shield_name = self.current_stage_info.fury_shied_effect_name
		self.fx_fury_shield_end_name = self.current_stage_info.fury_shied_break_effect_name
		self.fx_fury_shield_hit_name = self.current_stage_info.fury_shied_hit_effect_name
		self.fx_fury_shield_2phase_name = self.current_stage_info.fury_shied_effect_name_2
		self.fx_fury_shield_end_2phase_name = self.current_stage_info.fury_shied_break_effect_name_2
		self.fx_fury_shield_hit_2phase_name = self.current_stage_info.fury_shied_hit_effect_name_2
		--광폭화 저지오라(캐릭터)
		self.fx_fury_aura_start_name = self.current_stage_info.fury_aura_start_effect_name
		self.fx_fury_aura_name = self.current_stage_info.fury_aura_effect_name
		--즉사기 방어막(맵)
		self.fx_cleave_shield_name = self.current_stage_info.cleave_shield_effect_name
		self.fx_cleave_shield_break_name = self.current_stage_info.cleave_shield_effect_break_name
		self.fx_cleave_shield_2phase_name = self.current_stage_info.cleave_shield_effect_name_2
		self.fx_cleave_shield_2phase_break_name = self.current_stage_info.cleave_shield_effect_break_name_2
		-- 구슬 먹었을때의 힐 비율
		self.heal_ratio = self.current_stage_info.heal_ratio
	end

	-- 오브젝트 풀 미리 로드
	unity_object_pool.GetOrCreate(self.fx1_name)
	unity_object_pool.GetOrCreate(self.fx2_name)
	unity_object_pool.GetOrCreate(self.fx1_consume_name)
	unity_object_pool.GetOrCreate(self.fx2_consume_name)
	unity_object_pool.GetOrCreate(self.fx1_hit_name)
	self:init_effect()
	self:init_gauge_ui()
	self:init_sounds()

	self.loop_count = 0
	self.fury_phase_hp_ratio = self.current_stage_info.fury_phase_hp_ratio
	self.bead_duration = self.current_stage_info.bead_duration
	self.cleave_shield_duration = self.current_stage_info.cleave_shield_duration
	self.current_progress = self.progress.none

	return
end

function local_class:init_effect()
	self.fx_fury = unity_object_pool.GetOrCreate(self.fx_fury_name)
	self.fx_fury_end = unity_object_pool.GetOrCreate(self.fx_fury_end_name)
	self.fx_fury_shield = unity_object_pool.GetOrCreate(self.fx_fury_shield_name)
	self.fx_fury_shield_end = unity_object_pool.GetOrCreate(self.fx_fury_shield_end_name)
	self.fx_fury_shield_hit = unity_object_pool.GetOrCreate(self.fx_fury_shield_hit_name)
	self.fx_fury_shield_2phase = unity_object_pool.GetOrCreate(self.fx_fury_shield_2phase_name)
	self.fx_fury_shield_end_2phase = unity_object_pool.GetOrCreate(self.fx_fury_shield_end_2phase_name)
	self.fx_fury_shield_hit_2phase = unity_object_pool.GetOrCreate(self.fx_fury_shield_hit_2phase_name)
	self.fx_fury_aura_start = unity_object_pool.GetOrCreate(self.fx_fury_aura_start_name)
	self.fx_fury_aura = unity_object_pool.GetOrCreate(self.fx_fury_aura_name)
	self.fx_cleave_shield = unity_object_pool.GetOrCreate(self.fx_cleave_shield_name)
	self.fx_cleave_shield_break = unity_object_pool.GetOrCreate(self.fx_cleave_shield_break_name)
	self.fx_cleave_shield_2phase = unity_object_pool.GetOrCreate(self.fx_cleave_shield_2phase_name)
	self.fx_cleave_shield_2phase_break = unity_object_pool.GetOrCreate(self.fx_cleave_shield_2phase_break_name)
end

function local_class:init_sounds()
	-- 사운드 미리 로드
	self.sfx_cleave_shield = '02_conquest_shield_01'
	music_player:PreloadSfx(self.sfx_cleave_shield)

	self.sfx_move_button = '02_switch_button_03'
	music_player:PreloadSfx(self.sfx_move_button)

	self.sfx_fury_shield = '02_cast_ball_02'
	music_player:PreloadSfx(self.sfx_fury_shield)

	self.sfx_fury_shield_break = '01_glass_02'
	music_player:PreloadSfx(self.sfx_fury_shield_break)

	self.sfx_fury_turn_on = '01_thunder_03'
	music_player:PreloadSfx(self.sfx_fury_screen_effect)

	self.sfx_fury_turn_off = '01_thunder_01'
	music_player:PreloadSfx(self.sfx_fury_turn_off)
end

function local_class:init_gauge_ui()
	local res_holder = CS.Foundations.ResourceHolder()
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			res_holder, 'ondemand/v2_65_queencastle/ui', 'FallenQueenGimmickUI', function(prefab)
				self.gauge_ui_prefab = CS.NGUITools.AddChild(CS.Oak.Stage.Instance.UIRoot.gameObject, prefab)
				self.gauge_ui = self.gauge_ui_prefab:GetComponent(typeof(CS.Oak.UI.FallenQueenGimmickUI)).GetControllerLuaTable
			end)

	self.gauge_ui_prefab.gameObject:SetActive(false)
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
	--if not self:check_bead_position(position) then
	--	--다른 구슬과 곂치는 부분 있다면 위치 조정 들어감.
	--	new_position = self:get_bead_position(position)
	--end

	if mode == nil then
		mode = 1
	end

	table.insert(self.bead_list, bead_class:new(mode, self.current_stage_info.collide_range, position, new_position,
			self.fx1_name, self.fx1_consume_name, self.fx1_hit_name, self.fx2_name, self.fx2_consume_name, self.fx2_hit_name, false))
end

function local_class:create_bead(position, count, start_move, mode1_count, mode2_count)
	local index = 0
	local mode = 1

	for i = 1, count do
		-- 인덱스도 1 부터 시작하도록
		if #self.bead_list >= self.current_stage_info.bead_max_count then
			-- 새로 추가할 구슬이 맥시멈카운트보다 많다면 제일 먼저 생성된것 삭제
			local remove_bead = table.remove(self.bead_list, 1)
			remove_bead:dispose()
			remove_bead = nil
		end
		self.loop_count = 0
		if i > mode1_count or self.current_fury_phase == self.fury_phase.phase1 then
			mode = 2
		else
			mode = 1
		end
		-- 일반적으로 생성할때는 타겟 위치에서 랜덤위치로 조정 후 생성하도록 함.
		local new_position = self:get_bead_position(position)
		table.insert(self.bead_list, bead_class:new(mode, self.current_stage_info.collide_range, position, new_position,
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
	else
		local is_condition_checked = false
		-- 기존 나와있는 구슬들 위치에서 create_range 범위안에 곂치는 위치인지 확인
		for _, v in pairs(self.bead_list) do
			local dist = vector_util.distance(vector_util.get_x0z(position) , vector_util.get_x0z(v.end_position))
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

-- 구슬 근처에 캐릭터가 존재하면 구슬과 충돌되어 없어지도록.
-- 역순으로 비교하여 없앰.
function local_class:collide_bead()
	for i = #self.bead_list, 1, -1 do
		local bead = self.bead_list[i]
		-- 파티와 검사
		local fo_list = field:GetFieldObjectsInRadius(bead.fx.transform.position, self.current_stage_info.collide_range)
		for _, v in pairs(fo_list) do
			if CS.Oak.EntityGroupsExtensions.IsHittableTo(self.current_boss_character.EntityGroup, v.EntityGroup) then
				if lua_helper.reference_equals(v, user_party[0]) then
					if  bead:check_collide(v) then
						-- 구슬 타입에 따라 현재 기믹의 값변경
						if bead.mode == 1 then
							self.current_gauge_value = self.current_gauge_value - 1
							self.gauge_ui:move_left()
							self.gauge_ui:blink_current_dot()
							music_player_util.play_sfx({ sfx_name = self.sfx_move_button })

							if self.current_gauge_value == self.current_stage_info.active_fury_break_value then
								self.gauge_ui:blink_left_effect()

								self:init_fury_break_buff()
								self.is_reset_gauge_ui = true
							end
						else
							self.current_gauge_value = self.current_gauge_value + 1
							self.gauge_ui:move_right()
							self.gauge_ui:blink_current_dot()
							music_player_util.play_sfx({ sfx_name = self.sfx_move_button })

							if self.current_gauge_value == self.current_stage_info.active_shield_value then
								self.gauge_ui:blink_right_effect()

								self:init_cleave_shield()
								self.is_reset_gauge_ui = true
							end
						end
						bead:dispose()

						table.remove(self.bead_list, i)
					end
				end
			end
		end
		fo_list:Dispose()
	end
end

function local_class:init_fury()
	if self.is_fury_start then
		--이미걸려 있다면 시간이랑 틱같은것만 초기화 해줌
		self.fury_time_passed = 0
		self.fury_tick_count = 0
		self.fury2_tick_count = 0
		return
	end

	--1페이즈 광폭화
	--보스에게 쉴드부여 1.쉴드이팩트, 2.방어력버프부여 3.스크린이팩트
	if self.is_second_phase then
		local fx_pos = self.current_boss_character.Position
		self.body_eff_follower = CS.UnityEngine.GameObject('body_effect_follower')
		self.body_eff_follower.transform.parent = self.current_boss_character.transform
		self.body_eff_follower.transform.position = fx_pos
		local bone_follower = self.body_eff_follower:AddComponent(typeof(CS.Spine.Unity.BoneFollower))
		local spine = self.current_boss_character.SpineController
		bone_follower.followBoneRotation = false
		bone_follower.SkeletonRenderer = spine.SkeletonAnimation
		bone_follower:SetBone('body_eff')
		self.shield_effect = self.fx_fury_shield_2phase:Instantiate(fx_pos,
				unity_class.quaternion.identity, self.body_eff_follower.transform)
	else
		self.shield_effect = self.fx_fury_shield:Instantiate(self.current_boss_character.Position)
		self.shield_effect.transform.parent = self.current_boss_character.transform
		music_player_util.play_sfx({ sfx_name = self.sfx_fury_shield })
	end
	buff_manager:AddBuff(self.current_boss_character, CS.Oak.EquipmentSlot.None, self.current_boss_character,
			self.current_stage_info.fury_buff_name, self.current_stage_info.fury_buff_level, true, false)
	local transform = stage_camera.Transform
	self.fury_effect = self.fx_fury:Instantiate(transform.position, transform.rotation, transform.parent.transform)
	self.fury_time_passed = 0
	self.fury_tick_count = 0
	self.fury2_tick_count = 0
	self.current_fury_hit_count = 0

	music_player_util.play_sfx({ sfx_name = self.sfx_fury_turn_on })

	self.is_fury_start = true
	if self.target_list == nil then
		self.target_list = stage.BattleManager:GetTargets(self.current_boss_character)
	end
	ui_quest_marker:RemoveQuestMarker('boss_fury')
	ui_quest_marker:AddQuestMarkerToIFO('boss_fury', 0, false, self.current_boss_character)
end

function local_class:remove_fury(is_break)
	if not self.is_fury_start then return end

	local fx_pos

	--쉴드이팩트 제거, 방어력버프 제거, 스크린이팩트 제거
	self.is_fury_start = false
	if self.shield_effect ~= nil then
		if self.is_second_phase then
			fx_pos = self.shield_effect.transform.position
			CS.UnityEngine.Object.Destroy(self.body_eff_follower)
		end
		self.shield_effect:Dispose()
		self.shield_effect = nil
	end
	if self.fury_effect ~= nil then
		self.fury_effect:Dispose()
		self.fury_effect = nil
	end

	if is_break then
		if self.is_second_phase then
			self.fx_fury_shield_end_2phase:Instantiate(fx_pos and fx_pos or self.current_boss_character.Position,
					unity_class.quaternion.identity, self.body_eff_follower.transform)
		else
			self.fx_fury_shield_end:Instantiate(self.current_boss_character.Position)
			music_player_util.play_sfx({ sfx_name = self.sfx_fury_shield_break })
		end
		self:fury_break_head()
		self:create_bead(self.current_boss_character.Position,
				self.current_stage_info.fury_break_drop_bead_count, true,
				self.current_stage_info.fury_break_drop_bead_mode1)
	end
	local transform = stage_camera.Transform
	self.fx_fury_end:Instantiate(transform.position, transform.rotation, transform.parent.transform)

	music_player_util.play_sfx({ sfx_name = self.sfx_fury_turn_off })

	ui_quest_marker:RemoveQuestMarker('boss_fury')

	message_system:Send(self.current_boss_character, CS.Oak.CustomStageEvent.Create(self.current_boss_character, {'remove_fury'}))

	self.is_reset_gauge_ui = true

	buff_manager:RemoveBuff(self.current_boss_character, CS.Oak.EquipmentSlot.None,
			self.current_boss_character, self.current_stage_info.fury_buff_name)
end

function local_class:update_fury(dt)
	-- 3.체력비례 도트데미지, 4.시간제한
	if not self.is_fury_start then return end

	if self.fury_time_passed >= self.fury_duration then
		self:remove_fury()
		self.fury_time_passed = 0
		self.is_fury_start = false
	else
		self.fury_time_passed = self.fury_time_passed + dt
		if self.fury_time_passed >= self.current_stage_info.fury2_start_time then
			if self.fury_time_passed - self.current_stage_info.fury2_start_time > self.fury2_tick_count * self.current_stage_info.fury2_damage_interval then
				self.fury2_tick_count = self.fury2_tick_count + 1
				for _,v in pairs(self.target_list) do
					if not CS.Oak.EntityGroupsExtensions.IsHittableTo(self.current_boss_character.EntityGroup, v.EntityGroup) or
							v.FieldObjectStatsBehaviour.IsDead or
							lua_helper.reference_equals(self.current_boss_character, v) then
					else
						local damage_rate = math.floor(v.FieldObjectStatsBehaviour.MaxHpWoMod *
								self.current_stage_info.fury2_damage_rate)
						local damage_info = CS.Oak.DamageInfo()
						damage_info.type = CS.Oak.DamageType.IgnoreDefense
						damage_info.sender = self.current_boss_character
						damage_info.target = v
						damage_info.damage = damage_rate

						command_util.execute_damage(damage_info)
					end
				end
			end
		else
			if self.fury_time_passed > self.fury_tick_count * self.current_stage_info.fury_damage_interval then
				self.fury_tick_count = self.fury_tick_count + 1
				for _,v in pairs(self.target_list) do
					if not CS.Oak.EntityGroupsExtensions.IsHittableTo(self.current_boss_character.EntityGroup, v.EntityGroup) or
							v.FieldObjectStatsBehaviour.IsDead or
							lua_helper.reference_equals(self.current_boss_character, v) then
					else
						local damage_rate = math.floor(v.FieldObjectStatsBehaviour.MaxHpWoMod *
								self.current_stage_info.fury_damage_rate)
						local damage_info = CS.Oak.DamageInfo()
						damage_info.type = CS.Oak.DamageType.IgnoreDefense
						damage_info.sender = self.current_boss_character
						damage_info.target = v
						damage_info.damage = damage_rate

						command_util.execute_damage(damage_info)
					end
				end
			end
		end
	end
end

function local_class:fury_break_head()
	for _,v in pairs(self.target_list) do
		if not v.FieldObjectStatsBehaviour.IsDead then
			local heal_info = CS.Oak.HealInfo()
			heal_info.sender = v
			heal_info.target = v
			heal_info.heal = math.floor(v.FieldObjectStatsBehaviour.MaxHpWoMod * self.current_stage_info.fyry_break_head_rate)
			command_util.execute_heal(heal_info)
		end
	end
end

function local_class:init_fury_break_buff()
	if self.is_fury_break_buff then
		--이미 걸려 있다면 시간만 초기화
		self.fury_break_buff_time_passed = 0
		return
	end
	--메뉴얼 캐릭터에게 광폭화 저지버프 부여, 시간제한
	--오라이팩트(리더)
	--damage event체크해서 오라를 가지고있는 상태인데 캐릭터가 보스몬스터를 타격하면 광폭화 해제
	self.is_fury_break_buff = true
	self.fury_break_buff_time_passed = 0
	if not user_party[0].FieldObjectStatsBehaviour.IsDead then
		self.fx_fury_aura_start:Instantiate(user_party[0].Position)
		self.fury_break_effect = self.fx_fury_aura:Instantiate(user_party[0].Position)
		self.fury_break_effect.transform.parent = user_party[0].transform
	end
end

function local_class:remove_fury_break_buff()
	if not self.is_fury_break_buff then return end

	self.is_fury_break_buff = false
	self.fury_break_buff_time_passed = 0
	if self.fury_break_effect ~= nil then
		self.fury_break_effect:Dispose()
		self.fury_break_effect = nil
	end
end

function local_class:update_fury_break(dt)
	if not self.is_fury_break_buff then return end

	if self.fury_break_buff_time_passed < self.fury_break_duration then
		self.fury_break_buff_time_passed = self.fury_break_buff_time_passed + dt
	else
		self:remove_fury_break_buff()
	end
end

function local_class:init_cleave_shield()
	if self.is_start_cleave_shield then
		self.cleave_shield_time_passed = 0
		return
	end

	self.is_start_cleave_shield = true
	self.cleave_shield_time_passed = 0

	if self.cleave_shield_effect_list ~= nil then
		for _,v in pairs(self.cleave_shield_effect_list) do
			if v ~= nil then
				v:Dispose()
				v = nil
			end
		end
		self.cleave_shield_effect_list = nil
	end

	self.cleave_shield_effect_list = {}

	if not self.is_second_phase then
		for _,v in pairs(user_party) do
			local ef = self.fx_cleave_shield:Instantiate(v.Bounds.center)
			ef.transform.parent = v.transform
			table.insert(self.cleave_shield_effect_list, ef)
		end
		music_player_util.play_sfx({ sfx_name = self.sfx_cleave_shield })
		--queenshieldbattleaction에 쉴드 시작 이벤트 날림
		message_system:Send(self.current_boss_character, CS.Oak.CustomStageEvent.Create(self.current_boss_character, {'cleave_shield_start'}))
	else
		local num = #self.cleave_shield_2phase_offset_param
		local offset = self.cleave_shield_2phase_offset_param[math.random(1, num)]
		self.cleave_shield_pos = self.current_battle_zone.Bounds.center + unity_class.vector3(offset.x, 0, offset.y)
		local ef = self.fx_cleave_shield_2phase:Instantiate(self.cleave_shield_pos)
		table.insert(self.cleave_shield_effect_list, ef)
		--queenshieldbattleaction에 쉴드 시작 이벤트 날림
		message_system:Send(self.current_boss_character, CS.Oak.CustomStageEvent.Create(self.current_boss_character, {
			'cleave_shield_start',
			-- x좌표
			self.cleave_shield_pos.x,
			-- z좌표
			self.cleave_shield_pos.z,
			-- 쉴드 범위
			self.current_stage_info.cleave_shield_2phase_radius
		}))
	end


end

function local_class:remove_cleave_shield(is_break)
	if not self.is_start_cleave_shield then return end

	self.is_start_cleave_shield = false
	self.cleave_shield_time_passed = 0

	for _,v in pairs(self.cleave_shield_effect_list) do
		if v ~= nil then
			v:Dispose()
			v = nil
		end
	end
	self.cleave_shield_effect_list = nil

	if is_break then
		if not self.is_second_phase then
			for _,v in pairs(user_party) do
				self.fx_cleave_shield_break:Instantiate(v.Bounds.center)
			end
		else
			self.fx_cleave_shield_2phase_break:Instantiate(self.cleave_shield_pos)
		end
	end

	--queenshieldbattleaction에 쉴드 끝났다고 알려줌
	message_system:Send(self.current_boss_character, CS.Oak.CustomStageEvent.Create(self.character,
			{
				-- 어떤 이벤트인지
				'cleave_shield_end'}))
end

function local_class:update_cleave_shield(dt)
	if not self.is_start_cleave_shield then return end

	if self.cleave_shield_time_passed < self.cleave_shield_duration then
		self.cleave_shield_time_passed = self.cleave_shield_time_passed + dt
	else
		self:remove_cleave_shield(false)
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
	elseif e:GetParamAt(0) == 'init_bead_controller' then
		-- 세팅된 순간부터 컨트롤러 기능 시작 하도록 수정
		self.current_boss_character = get_character(e:GetParamAt(1))
		self.current_battle_zone = field:GetZone(e:GetParamAt(2))
		self.is_second_phase = e:GetParamAt(3) == 'phase2'
		self.fury_duration = self.current_stage_info.fury_duration
		self.fury_break_duration = self.current_stage_info.fury_break_duration
		if self.is_second_phase then
			self.bead_duration = self.current_stage_info.phase2_bead_duration
			self.cleave_shield_duration = self.current_stage_info.phase2_cleave_shield_duration
			self.fury_phase_hp_ratio = self.current_stage_info.fury_phase_hp_ratio_2
			self.cleave_shield_2phase_offset_param = self.current_stage_info.cleave_shield_2phase_offset
			self.fury_duration = self.current_stage_info.fury_duration_2phase
			self.fury_break_duration = self.current_stage_info.fury_break_duration_2phase
		end
		self.current_progress = self.progress.playing
		CS.Foundations.CoroutineManager.Instance:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.gauge_ui.show, self.gauge_ui, self.current_stage_info.gauge_ui_show_delay))


		if self.current_boss_character.CharacterStatsBehaviour.HpRatio < self.fury_phase_hp_ratio then
			self.current_fury_phase = self.fury_phase.phase2
		else
			self.current_fury_phase = self.fury_phase.phase1
		end
	elseif e:GetParamAt(0) == 'remove_beads' then
		self:remove_all_beads()
	elseif e:GetParamAt(0) == 'add_fury' then
		self:init_fury()
	elseif e:GetParamAt(0) == 'fury_start' then
		self.gauge_ui:left_loop_effect(true)
	elseif e:GetParamAt(0) == 'fury_end' then
		self.gauge_ui:left_loop_effect(false)
	elseif e:GetParamAt(0) == 'reset_gimmick_gauge' then
		self.is_reset_gauge_ui = true
		self:remove_all_beads()
	elseif e:GetParamAt(0) == 'cleave_shield_break' then
		self:remove_cleave_shield(true)
	elseif e:GetParamAt(0) == 'cleave_start' then
		self.gauge_ui:right_loop_effect(true)
	elseif e:GetParamAt(0) == 'cleave_end' then
		self.gauge_ui:right_loop_effect(false)
	elseif e:GetParamAt(0) == 'dispose_bead_controller' then
		-- 플레이 시작 이후에 해제 가능하도록
		if self.current_progress == self.progress.playing then
			self:dispose_all_beads()
			self.current_progress = self.progress.done
		end
		self.gauge_ui_prefab.gameObject:SetActive(false)
	end
end

function local_class:on_damage_event(e)
	if self.current_fury_phase == self.fury_phase.phase1 then
		if self.current_boss_character ~= nil and lua_helper.reference_equals(e.Info.target, self.current_boss_character) then
			if self.current_boss_character.CharacterStatsBehaviour.HpRatio < self.fury_phase_hp_ratio then
				self.current_fury_phase = self.fury_phase.phase2
			end
		end
	end

	--광폭화 파훼용
	--광폭화가 진행중이고 데미지 주체가 광폭화 버프를 가지고 있다면?
	if self.is_fury_start and self.is_fury_break_buff then

		if lua_helper.reference_equals(e.Info.sender, user_party[0]) then
			if self.current_fury_hit_count > self.current_stage_info.fury_break_hit_count then
				self:remove_fury_break_buff()
				self:remove_fury(true)
			else
				if self.is_second_phase then
					if self.shield_effect then
						self.fx_fury_shield_hit_2phase:Instantiate(self.shield_effect.transform.position, unity_class.quaternion.identity, self.body_eff_follower.tranform)
					end
				else
					self.fx_fury_shield_hit:Instantiate(self.current_boss_character.Position)
				end
				self.current_fury_hit_count = self.current_fury_hit_count + 1
			end
		end
	end
end

function local_class:on_battle_end_event(e)
	self.current_gauge_value = 0
	self.gauge_ui:reset_arrow()
	self.gauge_ui_prefab.gameObject:SetActive(false)
	self:remove_fury()
	self:remove_cleave_shield()
	self:remove_fury_break_buff()
end

function local_class:update_beads(dt)

	if #self.bead_list == 0 then
		return
	end

	for _, v in pairs(self.bead_list) do
		v:start_bead_update_throw(dt)
		--v:update_move(dt)

		if not v.is_start_move then
			v.time_passed = v.time_passed + dt
			if v.time_passed > self.current_stage_info.bead_max_count then

			end
		end
	end

	for i = #self.bead_list, 1, -1 do
		local bead = self.bead_list[i]
		bead.time_passed = bead.time_passed + dt
		if not bead.is_start_move then
			if bead.time_passed * 0.5 > self.bead_duration then
				bead:dispose()
				table.remove(self.bead_list, i)
			end
		end
	end

	self:collide_bead()
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return true end

	self:update_beads(dt)
	self:update_fury(dt)
	self:update_fury_break(dt)
	self:update_cleave_shield(dt)
	self:update_reset_gauge_ui(dt)
end

function local_class:update_reset_gauge_ui(dt)
	if self.gauge_ui == nil then return end

	if self.is_reset_gauge_ui then
		if self.gauge_ui_reset_time_passed > self.current_stage_info.gauge_ui_reset_duration then
			self.gauge_ui:reset_arrow()
			self.current_gauge_value = 0
			self.gauge_ui_reset_time_passed = 0
			self.is_reset_gauge_ui = false
		else
			self.gauge_ui_reset_time_passed = self.gauge_ui_reset_time_passed + dt
		end
	end
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
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
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
