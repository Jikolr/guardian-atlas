local local_class = newclass('TowerFire45Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 현재 스테이지 정보
	self.stage_data = require('stageeventcontrollers/TowerFire45Data.lua')
	self.current_stage_info = nil

	-- 기믹 진행 상태
	self.progress = { none = 1, playing = 2, finish = 3 }
	self.current_progress = self.progress.none

	-- 현재 들어간 존을 세팅한다.
	self.current_zone = nil

	-- 레이저 기믹 데미지 타입
	self.damage_type = CS.Oak.DamageType.Trap

	-- 레이저 세로, 가로 정보
	self.is_horizontal = false
	self.lasers_horizontal = {}
	self.lasers_vertical = {}

	-- 활성화 된 레이저 PairedName
	self.active_lasers = {}

	-- 활성화 된 레이저 숫자
	self.current_laser_count = 1

	-- 레이저와 캐릭터 간격
	self.get_distance_xz = function (actor, target)
		return vector_util.get_x0z(target.Position - actor.Position).magnitude
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_enter_zone_event')

	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')

	return util.cs_generator(self.on_load_local, self)
end

function local_class:on_load_local()
	self.current_stage_info = self.stage_data[stage.Name]

	-- 레인지/충돌계산기 미리 생성
	self.attack_ranges = {}
	for _ = 1, 3 do
		local range = CS.AttackRange.CreateRect(unity_class.vector3.zero, unity_class.vector2(self.current_stage_info.attack_range_distance, self.current_stage_info.attack_range_radius))
		range:Hide()
		table.insert(self.attack_ranges, range)
	end

	-- 레이저 데미지 타입 지정
	if self.current_stage_info.laser_damage_type == 'Melee' then
		self.damage_type = CS.Oak.DamageType.Melee
	elseif self.current_stage_info.laser_damage_type == 'Projectile' then
		self.damage_type = CS.Oak.DamageType.Projectile
	else
		self.damage_type = CS.Oak.DamageType.Trap
	end
end

function local_class:get_attack_range()
	if #self.attack_ranges > 0 then
		return table.remove(self.attack_ranges)
	else
		local range = CS.AttackRange.CreateRect(unity_class.vector3.zero, unity_class.vector2(self.current_stage_info.attack_range_distance, self.current_stage_info.attack_range_radius))
		range:Hide()
		return range
	end
end

function local_class:return_attack_range(range)
	if not is_unity_null(range) then
		range:Hide()
		if self.attack_ranges ~= nil then
			table.insert(self.attack_ranges, range)
		end
	end
end

function local_class:on_reset_laser()
	self.lasers_horizontal = {}
	self.lasers_vertical = {}
	self.active_lasers = {}

	for n = 1, #self.current_stage_info.horizontal_names do
		local laser = get_field_object( self.current_stage_info.horizontal_names[n] )
		if not is_unity_null(laser) then
			laser.FieldObjectBehaviour.DamageRate = self.current_stage_info.laser_damage_rate
			laser.FieldObjectBehaviour:SetDamageType(self.damage_type)
			laser.FieldObjectBehaviour:PauseLaserEffect()
			table.insert(self.lasers_horizontal, laser)
		end
	end

	for n = 1, #self.current_stage_info.vertical_names do
		local laser = get_field_object( self.current_stage_info.vertical_names[n] )
		if not is_unity_null(laser) then
			laser.FieldObjectBehaviour.DamageRate = self.current_stage_info.laser_damage_rate
			laser.FieldObjectBehaviour:SetDamageType(self.damage_type)
			laser.FieldObjectBehaviour:PauseLaserEffect()
			table.insert(self.lasers_vertical, laser)
		end
	end
end

function local_class:on_stage_start_event(e)
	self.current_progress = self.progress.none
	self.target = get_character(self.current_stage_info.boss_name)
	self:on_reset_laser()

	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{key = self.current_stage_info.description, stop_timer = true })
end

function local_class:on_enter_zone_event(e)
	-- 리더가 존에 들어갔을 때만
	if not e.FullEnter or not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return false end
	local zone_name = e.Zone.Name

	--현재의 존이름이 지정되어있는 존 이름과 같다면
	if zone_name == self.current_stage_info.gimmick_start_zone_names then
		self.current_zone = e.Zone
		-- 기믹이 시작되지 않았을떄 시작.
		if self.current_progress == self.progress.none then
			self.current_progress = self.progress.playing
			return true
		end
	end

	return false
end

function local_class:on_battle_end_event(e)
	if self.current_progress == self.progress.playing then
		self.current_progress = self.progress.finish

		-- turnoff all lasers
		if self.lasers_horizontal ~= nil then
			self:deactivate_all(self.lasers_horizontal)
		end

		if self.lasers_vertical ~= nil then
			self:deactivate_all(self.lasers_vertical)
		end
	end

	return true
end

function local_class:deactivate_all(laser_list)
	for n = 1, #laser_list do
		local laser = laser_list[n]
		if not is_unity_null(laser) then
			laser.FieldObjectBehaviour:DeactiveLaserEffect()
		end
	end
end

--function local_class:use_late_update_frame()
--	return true
--end
--
--function local_class:late_update_frame_priority()
--	return CS.Oak.UpdatePriorities.StageEvent
--end
--
--function local_class:late_update_frame(dt)
--	if self.current_progress == self.progress.playing then
--	end
--end

function local_class:on_damage_event(e)
	if not lua_helper.reference_equals(e.Info.target, self.target) then return end
	if #self.current_stage_info.hp_list < self.current_laser_count then return end

	local check_hp = self.current_stage_info.hp_list[self.current_laser_count]
	if self.target.CharacterStatsBehaviour.HpRatio * 100 < check_hp then
		-- 레이저 생성
		self:on_next_laser(self.is_horizontal)
		-- 레이저 관련 변수 업데이트
		self.is_horizontal = not self.is_horizontal
		self.current_laser_count = self.current_laser_count + 1
	end
end

-- 레이저 세로 -> 가로 순으로 활성화
function local_class:on_next_laser(is_horizontal)
	if is_horizontal then
		self:on_check_laser(self.lasers_horizontal, is_horizontal)
	else
		self:on_check_laser(self.lasers_vertical, is_horizontal)
	end
end

function local_class:on_check_laser(laser_list, is_horizontal)
	local possible_lasers = {}

	for n = 1, #laser_list do
		local laser = laser_list[n]
		if not table_util.contain_value( self.active_lasers, laser.FieldObjectBehaviour.PairedName) then
			table.insert(possible_lasers, laser)
		end
	end

	if #possible_lasers > 0 then
		local active_event = util.cs_generator(self.on_active_laser, self, possible_lasers, is_horizontal)
		coroutine_manager:StartCoroutine(stage.StageGameObject, active_event)
	end
end

function local_class:on_active_laser(possible_lasers, is_horizontal)
	local start_time = unity_class.time.time
	local user_character = user_party_leader

	local current_laser = self:pick_closest_laser(possible_lasers, user_character)

	local dir = CS.Oak.Direction.None
	if is_horizontal then
		dir = CS.Oak.Direction.Down
	else
		dir = CS.Oak.Direction.Right
	end

	local laser_direction = direction_util.to_vector3(dir)

	-- 알림영역 생성
	local range = self:get_attack_range()
	attack_range_util.setup_by_direction(range, current_laser.Position, laser_direction)

	-- attack range 등장 시 살짝 fade
	range:Show(self.current_stage_info.laser_delay_time)

	coroutine.yield()

	-- update
	while unity_class.time.time - start_time < self.current_stage_info.laser_delay_time and
			self.current_progress == self.progress.playing and self.active_lasers ~= nil do

		current_laser = self:pick_closest_laser(possible_lasers, user_character)

		if not is_unity_null(current_laser) and not is_unity_null(range) then
			attack_range_util.setup_by_direction(range, current_laser.Position, laser_direction)
			coroutine.yield()
		end
	end

	-- 알림영역 반환
	self:return_attack_range(range)

	local active_time = unity_class.time.time

	-- 레이저 활성화 추가 딜레이 시간 적용.
	while unity_class.time.time - active_time < self.current_stage_info.laser_active_time do
		coroutine.yield()
	end

	-- 레이저 활성화 전 상태 검사
	if self.current_progress == self.progress.playing and self.active_lasers ~= nil and not is_unity_null(current_laser) then
		table.insert( self.active_lasers, current_laser.FieldObjectBehaviour.PairedName )
		current_laser.FieldObjectBehaviour:ResumeLaserEffect()
	end
end

function local_class:pick_closest_laser(laser_list, current_character)
	local min_distance = CS.System.Single.MaxValue
	local current_laser = nil

	for n = 1, #laser_list do
		local laser = laser_list[n]
		if not table_util.contain_value( self.active_lasers, laser.FieldObjectBehaviour.PairedName) then
			local distance_x0z = self.get_distance_xz( current_character, laser )
			if min_distance > distance_x0z then
				min_distance = distance_x0z
				current_laser = laser
			end
		end
	end

	return current_laser
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))

	self.target = nil
	self.attack_ranges = nil

	self.is_horizontal = false
	self.current_progress = self.progress.none

	self.lasers_horizontal = nil
	self.lasers_vertical = nil
	self.active_lasers = nil
	self.current_laser_count = 1

	self.current_zone = nil

	self.current_stage_info = nil
	self.stage_data = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}