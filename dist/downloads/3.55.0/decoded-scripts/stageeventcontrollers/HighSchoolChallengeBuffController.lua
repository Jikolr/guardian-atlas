local local_class = newclass("HighSchoolChallengeBuffController")

--[[ 데이터 관리 ]]
function local_class:set_data()
	--[[ 버프 관련 정보
		{
			name = (str) [Buff Name]
			level = (int) [Buff Level]
		}
		{
			heal_ratio = (float) [Heal Ratio]
		}
	]]
	self.buff_data = {
		{
			name = 'attack_up_permill_persistent',
			level = 500
		},
		{
			name = 'defense_up_permill_persistent',
			level = 500
		},
		{
			heal_ratio = 0.3
		}
	}

	-- 전투 이후 해당 구역에서 얻은 버프를 해지함
	self.zone_data = {
		'TUTORIAL'
	}

	--[[ 버프 이펙트 관련 정보
		{
			name = (str) [PresetName]
			range = (int) [이펙트가 생성될 버프 중첩 횟수 범위]
		}
	]]
	self.preset_data = {
		{
			name = 'FX_dash',
			range = { 4, 11 },
			scale = vector(1, 1.5, 1.2)
		},
		{
			name = 'FX_dash',
			range = { 12, 19 },
			scale = vector(1.2, 1.8, 1.44)
		},
		{
			name = 'FX_dash',
			range = { 20, 25 },
			scale = vector(1.5, 2.25, 1.8)
		}
	}
end

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

	self:set_data()

	-- 버프 추가 및 해지 등을 명시적으로 하기 위해 있을 홀더
	self.buff_holder = get_field_object('buff_holder')

	-- 버프 중첩 횟수
	self.buff_overlap = 0
	-- 일시적인 버프 중첩 횟수
	self.temporary_overlap = 0

	-- 현재 사용중인 버프 이펙트
	self.buff_effect = nil

	yield_return_func(self.preset_is_loaded, self)

	return
end

--[[
	필요한 preset이 모두 로드 되었는지 체킹
]]
function local_class:preset_is_loaded()
	while true do
		local is_loaded = true

		for _, value in pairs(self.preset_data) do
			local pool= unity_object_pool.GetOrCreate(value.name)

			if not CS.Oak.UnityObjectPoolExtensions.IsLoaded(pool) then
				is_loaded = false
				break
			end
		end

		if is_loaded then
			break
		end

		coroutine.yield(nil)
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.Linear)

	local marker = field:GetMarker("default_start")
	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, marker.position, marker.direction,
			game_string:GetString(stage.Name))

	party_util.stop_and_disable_control()

	local desc = game_string:Format('highschool_challenge_1_narration_1',
			self.buff_data[1].level / 10, self.buff_data[2].level / 10, self.buff_data[3].heal_ratio * 100)
	field_ui_util.show_narration_async({ key = desc })

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end


function local_class:dispose()
	-- 구독한 이벤트 해지
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	-- 생성한 이펙트 dispose
	if self.buff_effect ~= nil then
		self.buff_effect:Dispose()
		self.buff_effect = nil
	end

	self.buff_holder = nil

	self.buff_data = nil
	self.zone_data = nil
	self.preset_data = nil

	self.cs_controller = nil
end

--[[
	FieldObjectDestroyedEvent 이벤트 처리
]]
function local_class:on_field_object_destroyed_event(e)
	-- check event type
	if not lua_helper.type_compare(e, CS.Oak.FieldObjectDestroyedEvent) then
		return false
	end

	-- hittable mask가 켜져있지 않은 경우 (일반적으로 아군 혹은 본인)
	if not CS.Oak.EntityGroupsExtensions.IsHittableTo(user_party_leader.EntityGroup, e.FieldObject.EntityGroup) then
		return false
	end

	local temporary = false
	local zone_name = e.FieldObject.FieldObjectController.Zone

	for _, value in  pairs(self.zone_data) do
		-- 해당 Zone의 Data가 정의되어 있을 경우
		-- 이때 걸어주는 버프는 임시 버프로 처리
		if value == zone_name then
			temporary = true
		end
	end

	-- 버프 적용 루틴을 수행
	self:buff_apply_routine(temporary)

	return true
end

--[[
	BattleGroupEliminatedEvent 이벤트 처리
]]
function local_class:on_battle_group_eliminated_event(e)
	-- check event type
	if not lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		return false
	end

	-- 버프 해지 루틴 수행
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.buff_expired_routine, self))

	return true
end

--[[
	적이 죽었을때, 버프 관련 처리
	FIXME: ZIWON 동시 처리 관련 루틴 추가 할 것
]]
function local_class:buff_apply_routine(temporary)
	-- 중첩 갱신
	self.buff_overlap = self.buff_overlap + 1

	-- 임시 버프라면 임시 중첩 갱신
	if temporary then
		self.temporary_overlap = self.temporary_overlap + 1
	end

	self:update_buff_routine(true)
end

--[[
	배틀 그룹이 전멸했을때, 임시 버프 관련 처리
]]
function local_class:buff_expired_routine()
	-- destory 당시 보낸 커맨드 처리를 위해 한 프레임 쉼
	-- 같은 버프 정보에 대해서 remove부터 우선 수행하기 때문에 expire 루틴을 제대로 수행하려면 한 프레임 쉬어야한다
	coroutine.yield(nil)

	-- 임시 버프가 없다면 아래 루틴을 수행하지 않음
	if self.temporary_overlap == 0 then
		return
	end

	-- 버프 중첩 갱신
	self.buff_overlap = self.buff_overlap - self.temporary_overlap
	-- 임시 버프 중첩 초기화
	self.temporary_overlap = 0

	self:update_buff_routine(false)
end

--[[
	실제 버프 갱신 처리
]]
function local_class:update_buff_routine(apply_heal)
	-- 버프, 힐 정보 순회
	for _, value in pairs(self.buff_data) do
		-- buff Routine
		if value['name'] ~= nil then
			local buff_name = value['name']
			local buff_level = value['level']

			-- 현재 stackable 기능을 쓰지 않기 때문에, 버프 해지후 새로운 레벨로 적용
			for index = 0, user_party.Count - 1 do
				local member = user_party[index]

				-- 기존에 걸어준 버프 해제
				buff_manager:RemoveBuff(
					self.buff_holder, CS.Oak.EquipmentSlot.None, member, buff_name)

				-- 새로운 버프 추가
				if buff_level * self.buff_overlap > 0 then
					buff_manager:AddBuff(self.buff_holder, CS.Oak.EquipmentSlot.None,
						member, buff_name, buff_level * self.buff_overlap, true, false)
				end
			end
		end

		-- Heal Routine (힐을 적용할 때만)
		if apply_heal and value['heal_ratio'] ~= nil then
			for index = 0, user_party.Count - 1 do
				local member = user_party[index]

				-- 파티 멤버가 죽지 않았을때 수행
				if not member.FieldObjectStatsBehaviour.IsDead then
					local heal_info = CS.Oak.HealInfo()
					heal_info.sender = nil
					heal_info.target = user_party[index]
					heal_info.heal = math.floor(user_party[index].FieldObjectStatsBehaviour.MaxHP * value['heal_ratio'])

					command_util.execute_heal(heal_info)
				end
			end
		end
	end

	self:update_buff_effect_routine()
end

--[[
	프리셋 데이터 기반으로 버프 이펙트 갱신
]]
function local_class:update_buff_effect_routine()
	-- 버프 이펙트 높이 오프셋
	local height_offset = -0.1

	-- 버프 이펙트가 생성되지 말아야할 조건에 버프 이펙트가 있을 경우
	if self.buff_overlap < self.preset_data[1].range[1] and self.buff_effect ~= nil then
		self.buff_effect:Dispose()
		self.buff_effect = nil

		return
	end

	-- 프리셋 데이터를 순회하며 이펙트 관련 정보를 체킹
	for _, value in pairs(self.preset_data) do
		-- 현재 중첩 횟수가 범위안이라면
		if value.range[1] <= self.buff_overlap and self.buff_overlap <= value.range[2] then
			-- 새로운 이펙트를 생성해야 하는지 여부
			local init_new_effect = self.buff_effect == nil

			-- 현재 버프 이펙트가 보여져야할 이펙트와 다르다면
			if self.buff_effect ~= nil and (self.buff_effect.ObjectPool.PresetName ~= value.name or
				self.buff_effect.transform.localScale ~= value.scale) then
				-- 현재 이펙트 해지
				self.buff_effect:Dispose()
				self.buff_effect = nil

				-- 새로운 이펙트를 생성해야함
				init_new_effect = true
			end

			-- 새로운 버프가 필요하다면
			if init_new_effect then
				local pool = unity_object_pool.GetOrCreate(value.name)

				-- nil check
				if pool == nil then
					return
				end

				local target_pos = user_party_leader.Position +
					user_party_leader.SpineController.SpineTotalOffset + height_offset * unity_class.vector3.up

				-- 새로운 버프 이펙트 생성
				self.buff_effect = CS.Oak.UnityObjectPoolExtensions.Instantiate(pool, target_pos,
					unity_class.vector3.back, user_party_leader.SpineController.SpineContainerTransform)

				self.buff_effect.transform.localScale = value.scale
			end

			break
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
