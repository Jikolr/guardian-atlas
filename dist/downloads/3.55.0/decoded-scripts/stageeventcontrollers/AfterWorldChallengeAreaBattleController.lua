local local_class = newclass("AfterWorldChallengeAreaBattleController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	--원 범위 크기
	self.area_radius = 3.5
	--범위 스왑 시간
	self.area_swap_duration = 10
	--기믹이 활성화될 존 이름
	self.zone_name = 'battle1'
	--보스들의 이름
	self.boss_names = {'boss_awceo_main', 'boss_awceo_sub'}

	--캐릭터에게 적용할 디버프 ID, Level
	self.debuff_id = 10000
	self.debuff_level = -990

	-- 보스 무적버프
	self.boss_buff_name = 'persistent_no_damage'
	-- 오브젝트 풀
	self.get_fx_immune = function() return unity_object_pool.GetOrCreate('fx_abnormal_immune_all') end
	self.fx_immune_dispose = function()
		if not is_unity_null(self.fx_immune) then
			self.fx_immune:Dispose()
		end
	end

	self.range_light_color = CS.UnityEngine.Color32(53, 70, 255, 76)
	self.range_dark_color = CS.UnityEngine.Color32(53, 70, 255, 153)

	self.attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.area_radius,
			self.range_light_color, self.range_dark_color)
	self.attack_range:Hide()

	self.current_buff_boss_index = 1
	self.is_start_gimmick = false
	self.boss_list = {}
	self.time_passed = 0
	self.user_debuff_check_list = {}
	self.boss_buff_check_list = {}
	self.is_last_boss = false

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3
	}

	self.current_progress = self.progress.none
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	for i = 1, #self.boss_names do
		local c = get_character(self.boss_names[i])
		table.insert(self.boss_list, c)
	end
	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--region on_event
function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return false end
	if e.FieldObject ~= user_party_leader then return false end

	local zone_name = e.Zone.Name

	if zone_name == self.zone_name then
		self.current_progress = self.progress.playing
	end

	return false
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.cleared

	--전투가 종료 됐다면 파티에게 걸린 디버프 해제
	for i= 0, user_party.Count - 1 do
		if not user_party[i].CharacterStatsBehaviour.IsDead then
			self:remove_debuff(user_party[i])
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress ~= self.progress.playing then return false end

	-- 하나의 보스가 죽으면 남은보스에게 원 고정
	for i = 1, #self.boss_list do
		if lua_helper.reference_equals(self.boss_list[i], e.FieldObject) then
			self.is_last_boss = true
			local index = i + 1
			if index > #self.boss_list then
				index = 1
			end
			self.current_buff_boss_index = index
			self:remove_boss_buff(self.boss_list[self.current_buff_boss_index])
			self:add_boss_area(self.boss_list[self.current_buff_boss_index])
		end
	end
end

function local_class:add_boss_buff(target)
	self.fx_immune = self.get_fx_immune():Instantiate(target.Position + vector(0, 0.01, 0.9),
			unity_class.quaternion.identity, target.Transform)
	self.fx_immune.transform.localScale = vector(1.8, 0, 1.85)
	stage.BuffManager:AddBuff(target, CS.Oak.EquipmentSlot.None, target, self.boss_buff_name, 0, false, false)
end

function local_class:remove_boss_buff(target)
	self.fx_immune_dispose()
	stage.BuffManager:RemoveBuff(target, CS.Oak.EquipmentSlot.None, target, self.boss_buff_name)
end

function local_class:add_debuff(target)
		buff_manager:AddBuff(target, CS.Oak.EquipmentSlot.None, target, self.debuff_id, self.debuff_level, false, false)
end

function local_class:remove_debuff(target)

		buff_manager:RemoveBuff(target, CS.Oak.EquipmentSlot.None, target, self.debuff_id)
end

function local_class:on_event(e)
	return false
end

function local_class:use_late_update_frame(e)
	return true
end

function local_class:late_update_frame(dt)
	if self.current_progress ~= self.progress.playing then return end

	if not self.is_start_gimmick then
		self:set_buffs()
		self.is_start_gimmick = true
	else
		if self.time_passed >= self.area_swap_duration then
			--swap
			if not self.is_last_boss then
				self:swap_area()
			end
			self.time_passed = 0
		else
			--check_area
			self:check_area(self.boss_list[self.current_buff_boss_index])
			self.time_passed = self.time_passed + dt

			self:check_attack_range_height()
		end
	end
end

function local_class:check_area(target)
	for i= 0, user_party.Count - 1 do
		if not user_party[i].CharacterStatsBehaviour.IsDead then
			if self:is_in_area(target.Position, user_party[i]) then
				if self.user_debuff_check_list[i + 1] then
					self:remove_debuff(user_party[i])
					self.user_debuff_check_list[i + 1] = false
				end
			else
				if not self.user_debuff_check_list[i + 1] then
					self:add_debuff(user_party[i])
					self.user_debuff_check_list[i + 1] = true
				end
			end
		end
	end
end

function local_class:is_in_area(target_pos, target)
	local distance = vector_util.get_x0z(target_pos - target.Position).magnitude
	if distance > self.area_radius then
		return false
	else
		return true
	end
end

function local_class:swap_area()
	local prev_index = self.current_buff_boss_index
	local index = self.current_buff_boss_index + 1
	if index > #self.boss_names then
		index = 1
	end
	self.current_buff_boss_index = index

	self:remove_boss_buff(self.boss_list[index])
	self:add_boss_buff(self.boss_list[prev_index])
	self:add_boss_area(self.boss_list[index])
	self.boss_buff_check_list[prev_index] = false
	self.boss_buff_check_list[index] = true
end

function local_class:set_buffs()
	for i= 0, user_party.Count - 1 do
		self:add_debuff(user_party[i])
		self.user_debuff_check_list[i + 1] = true
	end
	if not self.boss_buff_check_list[self.current_buff_boss_index] then
		self:add_boss_buff(self.boss_list[2])
		self:add_boss_area(self.boss_list[1])
		self.boss_buff_check_list[self.current_buff_boss_index] = true
	end
end

function local_class:add_boss_area(target)
	local height = field:GetTileInfoAt(target.Position):GetHeightAt(target.Position)
	local pos = vector_util.get_x0z(target.Position, height)
	attack_range_util.setup_by_position(self.attack_range, pos, height)
	self.attack_range:Show(0.1)
	self.attack_range.transform.parent = target.transform
	self.attack_range.transform.localPosition.y = 0.1
end

function local_class:check_attack_range_height()
	if self.attack_range.transform.localPosition.y < 0 then
		local pos = self.attack_range.transform.localPosition
		pos.y = 0.05
		self.attack_range.transform.localPosition = pos
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	self.cs_controller = nil

	self.get_fx_immune = nil
	self.fx_immune_dispose = nil
	self.range_light_color = nil
	self.range_dark_color = nil

	if not is_unity_null(self.attack_range) then
		CS.UnityEngine.Object.Destroy(self.attack_range)
	end
	self.attack_range = nil
	self.boss_list = nil
	self.user_debuff_check_list = nil
	self.boss_buff_check_list = nil
	self.progress = nil
	self.current_progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
