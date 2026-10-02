local local_class = newclass('FieldIgnitionController')

-- 발화 롼련 데이터 세팅
function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		done = 3
	}

	self.current_boss_character = nil

	self.stage_data = require('stageeventcontrollers/FieldIgnitionControllerData.lua')
	self.current_stage_info = nil

	-- 발화상태 걸린 오브젝트 리스트
	self.ignition_info_list = {
		-- 발화상태 걸린 오브젝트( 타겟)
		target = nil,
		-- 해당 오브젝트 발화상태 걸린 시간.
		time_passed = 0,
		-- 이펙트
		fx = nil
	}

	self.get_custom_sprite = function()
		return unity_object_pool.GetOrCreate('custom_sprite')
	end

	-- 현재 참여중인 배틀존. 해당 존 내의 캐릭터들에게 데미지를 입힌다.
	self.current_battle_zone = nil

	self.current_progress = self.progress.none
end

function local_class:load_resource(key, load_end_callback)
	return util.cs_generator(self.on_load_resource, self, load_end_callback)
end

function local_class:on_load_resource(load_end_callback)

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.PartySwitchingEvent), 'on_party_switch_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	self.current_stage_info = self.stage_data[stage.Name]
	if self.current_stage_info ~= nil then
		-- 머리위에 표시될 스프라이트 이름
		self.target_sprite_name = self.current_stage_info.target_sprite_name
		-- 입히는 데미지 비율
		self.damage_modifier = self.current_stage_info.damage_modifier
		-- 데미지 들어가는 인터벌 타임
		self.damage_interval = self.current_stage_info.damage_interval
		--연계기 몇까지 누적되면 발화상태 종료 할 것인가
		self.support_action_count = self.current_stage_info.support_action_count
		--연계기 누적 타임오버시간
		self.accumulation_time_over = self.current_stage_info.accumulation_time_over
		--연계기 연속으로 성공해야 취소가능한지 여부
		self.is_continuous_action_needs = self.current_stage_info.is_continuous_action_needs
		-- 연계기 누적 확인 구슬 이펙트명
		self.fx_support_bead_name = self.current_stage_info.fx_support_bead_name
		-- 연계기 구슬 트레일
		self.fx_support_bead_end_name = self.current_stage_info.fx_support_bead_end_name
		-- 구슬이펙트와 보스간 거리
		self.bead_fx_distance = self.current_stage_info.bead_fx_distance
		-- 구슬 회전 속도
		self.rotate_speed = self.current_stage_info.rotate_speed
		-- 카메라 스크린이펙트 네임
		self.fx_screen_effect_name = self.current_stage_info.screen_effect_name
		-- 카메라 스크린이펙트 종료
		self.fx_screen_effect_end_name = self.current_stage_info.screen_effect_end_name
	end

	-- 오브젝트 풀 미리 로드
	unity_object_pool.GetOrCreate(self.fx_support_bead_name)
	self.get_fx_bead_pool = function() return unity_object_pool.GetOrCreate(self.fx_support_bead_name) end

	unity_object_pool.GetOrCreate(self.fx_support_bead_end_name)
	self.get_fx_bead_end_pool = function() return unity_object_pool.GetOrCreate(self.fx_support_bead_end_name) end

	unity_object_pool.GetOrCreate(self.fx_screen_effect_name)
	self.get_fx_screen_effect_pool = function() return unity_object_pool.GetOrCreate(self.fx_screen_effect_name) end

	unity_object_pool.GetOrCreate(self.fx_screen_effect_end_name)
	self.get_fx_screen_effect_end_pool = function() return unity_object_pool.GetOrCreate(self.fx_screen_effect_end_name) end

	-- 스크린 이펙트
	self.fx_screen_effect = nil

	self.fx_bead_list = { }

	self.fx_bead_offset = unity_class.vector3(0, 0, 1)

	-- 현재까지 누적된 연계기 횟수
	self.current_support_action_count = 0
	-- 연계기 누적 후 지난 시간.
	self.accumulation_time_passed = 0

	-- 커스텀 스프라이트 로드용 풀 프리로드
	self.get_custom_sprite()

	self.current_progress = self.progress.none

	if load_end_callback then
		load_end_callback()
	end
	return
end

--런치루틴 사용 안함.
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)

end

-- 모든 피격시마다 구슬을 생성하는게 아니기 때문에 커스텀이벤트 받아서 처리하도록 한다.
-- 공통사항으로 파라메터
function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'start_ignition' then
		-- 시작 메세지 받으면 동작 시작
		-- 보스와 적대되는 전체 캐릭터에 데미지
		self.current_boss_character = get_character(e:GetParamAt(1))
		self.current_battle_zone = field:GetZone(e:GetParamAt(2))
		self:start_ignitions()
	elseif e:GetParamAt(0) == 'end_ignition' then
		self.current_boss_character = nil
		self.current_battle_zone = nil
		-- 발화상태 종료
		self:end_ignitions()
	elseif e:GetParamAt(0) == 'hit_support_action' then
		-- 플레이중인 경우에만 이벤트 받음
		if self.current_progress == self.progress.playing then
			self.current_support_action_count = self.current_support_action_count + 1
			--hit 될때마다 카운트 초기화
			self.accumulation_time_passed = 0
			self:remove_fx_bead()
		end
	end
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then
		return true
	end

	if self.current_support_action_count > 0 then
		self.accumulation_time_passed = self.accumulation_time_passed + dt
		if self.current_support_action_count < self.support_action_count then
			if self.is_continuous_action_needs then
				if self.accumulation_time_passed >= self.accumulation_time_over then
					-- 누적시간 벗어나게 되면 카운드 재시작
					self.current_support_action_count = 0
					self.accumulation_time_passed = 0
					self:restore_fx_bead()
				end
			end
		else
			-- 연계기 체크 성공하여 종료 된다면
			CS.Oak.MessageSystem.Instance:Publish(CS.Oak.CustomStageEvent.Create(self.current_boss_character, {'boss_balock_groggy'}))
			-- 카운트만큼 체크되면 성공,
			self:end_ignitions()
			if not CS.Oak.CoopClient.IsRainMode or CS.Oak.IFieldObjectExtensions.IsManualLocal(user_party.Leader) then
				stage_camera:Shake(0.25, 0.2)
				local transform = stage_camera.Transform
				self.get_fx_screen_effect_end_pool():Instantiate(transform.position, transform.rotation, transform.parent.transform)
			end
		end

	end
	self:update_beads(dt)
	self:update_ignitions(dt)
end

function local_class:get_fx_bead_position(index)
	-- 보스 위치 기준으로 45도씩 돌아가면서 위치 확정 지어야 함.
	-- 생성기준은 12시 방향부터 ..
	local angle = 360 / self.support_action_count * (index - 1)
	local dir = unity_class.quaternion.AngleAxis(angle, unity_class.vector3.up) * unity_class.vector3.forward
	local new_position = self.current_boss_character.Bounds.center + self.fx_bead_offset + dir.normalized * self.bead_fx_distance
	return new_position, angle
end

-- 연계기 실패로 구슬 갯수 복구 하는 경우
function local_class:restore_fx_bead()
	-- 전체 갯수중 비어있는걸 추가 하면 되므로
	local index = 0

	for i= 1, #self.fx_bead_list do
		if not is_unity_null(self.fx_bead_list[i].fx) then
			index = i
		end
	end
	-- index 번째까지는 구슬이 존재하고, 그 이후부터 구슬이 없으므로
	local resotre_index = index + 1
	for i = resotre_index , self.support_action_count do
		local position = self.fx_bead_list[i].position
		self.fx_bead_list[i].fx = self.get_fx_bead_pool():Instantiate(position, unity_class.quaternion.identity, self.current_boss_character.Transform)
	end
end

-- 연계기 성공으로 구슬 하나 없애야 하는 경우
function local_class:remove_fx_bead()
	-- 성공한 액션 갯수 만큼 뒤에꺼부터 제거
	local index = self.support_action_count - self.current_support_action_count + 1
	if #self.fx_bead_list > 0 then
		if not is_unity_null(self.fx_bead_list[index].fx) then
			self.fx_bead_list[index].fx:Dispose()
			self.fx_bead_list[index].fx = nil
			self.get_fx_bead_end_pool():Instantiate(self.fx_bead_list[index].position, unity_class.quaternion.identity, nil)
		end
	end
end

function local_class:update_beads(dt)
	local center = self.current_boss_character.Bounds.center

	if self.degree >= 360 then
		self.degree = 0
	end
	self.degree = self.degree + dt * self.rotate_speed

	for i = 1, #self.fx_bead_list do
		local pos = self.fx_bead_list[i].position
		local each_degree = self.degree + self.fx_bead_list[i].angle
		if each_degree >= 360 then
			each_degree = each_degree % 360
		end

		local rad = math.rad(each_degree)

		local sin = math.sin(rad)
		local cos = math.cos(rad)
		local x = sin * self.bead_fx_distance
		local z = cos * self.bead_fx_distance

		pos = unity_class.vector3(x, 0, z) + center + self.fx_bead_offset
		self.fx_bead_list[i].position = pos

		if not is_unity_null(self.fx_bead_list[i].fx) then
			self.fx_bead_list[i].fx.transform.position = pos
		end
	end
end

function local_class:update_ignitions(dt)
	if #self.ignition_info_list > 0 then
		for i, v in ipairs(self.ignition_info_list) do
			-- 죽은경우에 데미지 보내지 않음.
			if v.target ~= nil and not v.target.FieldObjectStatsBehaviour.IsDead then
				v.time_passed = v.time_passed + dt
				if v.time_passed >= self.damage_interval then
					v.time_passed = 0
					local damage_info = CS.Oak.DamageInfo()
					damage_info.type = CS.Oak.DamageType.Melee
					damage_info.sender = self.current_boss_character
					damage_info.target = v.target
					damage_info.modifier = self.damage_modifier
					command_util.publish_cmd(damage_info.Owner, CS.Oak.DamageCommand.Create(damage_info))
				end
			end
		end
	end
end

-- 파티 스위칭되어 변경된경우에 발화상태 걸리는 캐릭터들을 변경
function local_class:on_party_switch_event(e)
	self:change_ignition_list()
end

-- 발화상태 걸린 캐릭터들을 변경한다.
function local_class:change_ignition_list()
	if self.current_progress == self.progress.playing then
		--기존 리스트 삭제
		self:clear_ignition_list()
		-- 리스트 새로 추가
		self:set_ignition_list()
	end
end

-- 전체 캐릭터들에게 발화상태 추가
function local_class:set_ignition_list()
	local fo_list = field:GetFieldObjectsCollidedBy(self.current_battle_zone.Bounds, unity_class.vector3.zero)
	for i, v in pairs(fo_list) do
		--타격 가능한 경우에 isHittable, 죽은경우 포함하여 리스트에 포함 (부활등이 있는 경우에 대비)
		if CS.Oak.EntityGroupsExtensions.IsHittableTo(self.current_boss_character.EntityGroup, v.EntityGroup) then
			local info = { }
			info.target = v
			info.time_passed = 0
			table.insert(self.ignition_info_list, info)
		end
	end
	fo_list:Dispose()
end

-- 발화상태 정리
function local_class:clear_ignition_list()
	if #self.ignition_info_list > 0 then
		for i = #self.ignition_info_list, 1, -1 do
			self.ignition_info_list[i].target = nil
			table.remove(self.ignition_info_list, i)
		end
	end
end

-- 발화상태 시작
function local_class:start_ignitions()

	-- 프로그레스 done 되지 않은 경우에만 실행 가능함.
	if self.current_progress == self.progress.none then

		self:set_ignition_list()

		-- 보스 주위에 구슬 생성 할것.
		for i = 1, self.support_action_count do
			local position, angle = self:get_fx_bead_position(i)
			local fx_bead = self.get_fx_bead_pool():Instantiate(position, unity_class.quaternion.identity, self.current_boss_character.Transform)
			local bead = {
				fx = fx_bead,
				-- 구슬 회전시키면서 위치 저장해둿다가 해당 위치로 다시 복구 하기 위해서 위치값 따로 저장해둠.
				position = position,
				-- 기본 위치각도
				angle = angle
			}
			table.insert(self.fx_bead_list, bead)
		end

		self.degree = 0
		self.current_progress = self.progress.playing
		if not CS.Oak.CoopClient.IsRainMode or CS.Oak.IFieldObjectExtensions.IsManualLocal(user_party.Leader) then
			local transform = stage_camera.Transform
			self.fx_screen_effect = self.get_fx_screen_effect_pool():Instantiate(transform.position, transform.rotation, transform.parent.transform)
		end
	end
end

-- 발화상태 종료 (전투 종료시, 기믹 성공시)
function local_class:end_ignitions()
	self:clear_ignition_list()

	-- 연계기 성공으로 종료된다면 없겠지만 아니라면 존재할것이기 때문에 여기서도 없애줌.
	if #self.fx_bead_list > 0 then
		for i = #self.fx_bead_list, 1, -1 do
			if not is_unity_null(self.fx_bead_list[i].fx) then
				self.fx_bead_list[i].fx:Dispose()
				self.fx_bead_list[i].fx = nil
			end
			table.remove(self.fx_bead_list, i)
		end
	end
	if not is_unity_null(self.fx_screen_effect) then
		self.fx_screen_effect:Dispose()
		self.fx_screen_effect = nil
	end

	--다 없애고 프로그레스 종료
	self.current_progress = self.progress.done
end

-- 전투 종료시 발화상태 취소하기 위해서 이벤트 구독함.
function local_class:on_battle_end_event(e)
	self:end_ignitions()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PartySwitchingEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	self:end_ignitions()

	self.cs_controller = nil
	self.current_progress = nil
	self.progress = nil

	self.get_fx_bead_pool = nil
	self.get_fx_bead_end_pool = nil
end



return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
