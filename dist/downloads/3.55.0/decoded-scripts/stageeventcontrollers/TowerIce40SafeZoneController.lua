local local_class = newclass('TowerIce40SafeZoneController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
	}

	self.current_progress = self.progress.none

	self.range_radius = 2
	self.count_down = 3
	self.boss_name = 'boss1'

	self.range_light_color = CS.UnityEngine.Color32(53, 70, 255, 76)
	self.range_dark_color = CS.UnityEngine.Color32(53, 70, 255, 153)

	self.attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.range_radius,
	self.range_light_color, self.range_dark_color)
	self.attack_range:Hide()

	self.target = nil
	self.is_safe_zone = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	self.target = get_character(self.boss_name)
	return
end

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing
	self.is_safe_zone = true
	self:start_count_down()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.show_safe_zone, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.check_safe_zone_routine, self))
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.cleared
	self:detach_count_ui()
	self.attack_range:Hide()
end

function local_class:need_on_launch()
	return false
end

function local_class:check_safe_zone_routine()
	while self.current_progress == self.progress.playing do
		local checked = self:is_in_safe_zone()
		if self.is_safe_zone ~= checked then
			self.is_safe_zone = checked
			if checked then
				if self.count_ui ~= nil then
					self.count_ui.gameObject:SetActive(false)
				end
			else
				if self.count_ui ~= nil then
					self.count_ui.gameObject:SetActive(true)
				end
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.count_down_timer, self))
			end
		end
		coroutine.yield(nil)
	end
end

function local_class:show_safe_zone()
	self.attack_range:Show(0)

	while true do
		if self.current_progress == self.progress.playing then
			attack_range_util.setup_by_position(self.attack_range, self.target.Position, 0)
			coroutine.yield(nil)
		else
			break
		end
	end
end

function local_class:start_count_down()
	self:attach_count_ui(user_party.Leader, 0)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.count_down_timer, self))
end

function local_class:count_down_timer()
	self.passed_time = 0

	while self.current_progress == self.progress.playing do
		if not self.is_safe_zone then
			self:update_count_ui(self.count_down - math.floor(self.passed_time + 0.5))

			if self.passed_time >= self.count_down then
				--safezone 체크
				self:check_safe_zone()
				self.passed_time = 0
			end

			self.passed_time = self.passed_time + unity_class.time.deltaTime
			coroutine.yield(nil)
		else
			break
		end
	end
end

function local_class:is_in_safe_zone()
	local distance = vector_util.get_x0z(self.target.Position - user_party_leader.Position).magnitude
	if distance > self.range_radius then
		return false
	else
		return true
	end
end

function local_class:check_safe_zone()
	if not self:is_in_safe_zone() then
		--안전지대 밖이라면 즉사 데미지를 입는다.

		--모든 버프를 지운다.
		for i = 0, user_party.Count - 1 do
			buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party.Leader)
		end

		coroutine.yield(nil)

		local damage_info = CS.Oak.DamageInfo()
		damage_info.sender = user_party_leader
		damage_info.target = user_party_leader
		damage_info.type = CS.Oak.DamageType.Death
		damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

		local cmd = CS.Oak.DamageCommand.Create(damage_info)
		command_util.publish_cmd(damage_info.Owner, cmd)

		self.current_progress = self.progress.none
	end
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
	tmp.color = unity_class.color.red
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value
end

-- 카운트 UI 해제
function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self.range_light_color = nil
	self.range_dark_color = nil

	if not is_unity_null(self.attack_range) then
		CS.UnityEngine.Object.Destroy(self.attack_range)
	end
	self.attack_range = nil
	self.target = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
