local local_class = newclass('TowerNone20TimeBombController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		interval = 3,
		waiting = 4,
		cleared = 5,
	}

	self.current_progress = self.progress.none

	self.stage_battle_info = {
		tower_none_20 = {--tower_none_20
			battle_group_names = {'boss'},
			wave_count = 2,
			target_monster_names = { 'wave_1', 'boss'},
		}
	}

	self.range_radius = 2.5
	self.count_down = 3
	self.damage_modifier = 0.5
	self.gimmick_interval = 3

	self.attack_range_list = {}

	for i = 1, 2 do
		local attack_range = CS.AttackRange.CreateCircle(unity_class.vector3.zero, self.range_radius)
		attack_range:Hide()
		table.insert(self.attack_range_list, attack_range)
	end

	self.current_stage_info = nil
	self.current_wave = 0
	self.current_interval_time = 0
	self.target = nil
	self.is_intersection = false
	self.is_attach_ui = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent), 'on_battle_group_wave_clear_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')
	unity_object_pool.GetOrCreate('FX_FlameStrike')
	self.is_attach_ui = false
	self.current_stage_info = self.stage_battle_info[stage.Name]
	self.current_wave = 1
	self.target = get_character(self.current_stage_info.target_monster_names[self.current_wave])
	return
end

function local_class:on_battle_start_event(e)
	if self.current_progress ~= self.progress.playing then
		self.current_progress = self.progress.playing
		self.is_intersection = false
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.show_attack_range, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.check_intersection_routine, self))
	end
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.cleared
	self:detach_count_ui()

	for _,v in pairs(self.attack_range_list) do
		v:Hide()
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_field_object_destroyed_event(e)
	--대상 타겟이 죽고 마지막웨이브가 아니면 대기 스테이트
	if lua_helper.reference_equals(self.target, e.FieldObject) and self.current_wave < self.current_stage_info.wave_count then
		self.current_progress = self.progress.waiting
		self:disable_gimmick()
	end
end

function local_class:on_battle_group_wave_clear_event(e)
	--타겟변경
	self.current_wave = self.current_wave + 1
	self.target = get_character(self.current_stage_info.target_monster_names[self.current_wave])
	self.current_progress = self.progress.playing

	self.is_intersection = nil
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.show_attack_range, self))
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.check_intersection_routine, self))
	return true
end

function local_class:check_intersection_routine()
	while self.current_progress == self.progress.playing or self.current_progress == self.progress.interval do
		if self.current_progress == self.progress.playing then
			local checked = self:is_in_intersection()
			if self.is_intersection ~= checked then
				self.is_intersection = checked
				if not checked then
					if self.count_ui ~= nil then
						self.count_ui.gameObject:SetActive(false)
					end
				else
					if self.count_ui ~= nil then
						self.count_ui.gameObject:SetActive(true)
					end
					if not self.is_attach_ui then
						self:start_count_down()
						self.is_attach_ui = true
					else
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.count_down_timer, self))
					end

				end
			end
		elseif self.current_progress == self.progress.interval then
			if self.current_interval_time > self.gimmick_interval then
				self.current_progress = self.progress.playing
				self.current_interval_time = 0
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
						self.show_attack_range, self))
			else
				self.current_interval_time = self.current_interval_time + unity_class.time.deltaTime
			end
		end
		coroutine.yield(nil)
	end
end

function local_class:show_attack_range()
	for _,v in pairs(self.attack_range_list) do
		v:Show(0)
	end

	while true do
		if self.current_progress == self.progress.playing then
			attack_range_util.setup_by_position(self.attack_range_list[1], self.target.Position, 0)
			attack_range_util.setup_by_position(self.attack_range_list[2], user_party_leader.Position, 0)
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
		if self.is_intersection then
			self:update_count_ui(self.count_down - math.floor(self.passed_time + 0.5))

			if self.passed_time >= self.count_down then
				--safezone 체크
				self:check_intersection()
				self.passed_time = 0
			end

			self.passed_time = self.passed_time + unity_class.time.deltaTime
			coroutine.yield(nil)
		else
			break
		end
	end
end

function local_class:is_in_intersection()
	local distance = vector_util.get_x0z(self.target.Position - user_party_leader.Position).magnitude
	if distance > self.range_radius * 2 then
		return false
	else
		return true
	end
end

function local_class:explotion_damage(target_pos_list)
	for _,v in pairs(target_pos_list) do
		local fo_list = field:GetFieldObjectsInRadius(v, self.range_radius)

		--폭파 이펙트
		unity_object_pool.GetOrCreate('FX_FlameStrike'):Instantiate(v)

		for _,fo in pairs(fo_list) do
			if not CS.Oak.EntityGroupsExtensions.IsHittableTo(self.target.EntityGroup, fo.EntityGroup) or
					fo.FieldObjectStatsBehaviour.IsDead or
					lua_helper.reference_equals(self.character, fo) then
			else

				local dmg_dir = vector_util.get_x0z(fo.Position - v).normalized
				local damage_info = CS.Oak.DamageInfo()
				damage_info.type = CS.Oak.DamageType.Trap | CS.Oak.DamageType.Passive
				damage_info.sender = self.target
				damage_info.target = fo
				damage_info.direction = dmg_dir
				damage_info.damage = math.floor(fo.FieldObjectStatsBehaviour.MaxHpWoMod * self.damage_modifier)
				local cmd = CS.Oak.DamageCommand.Create(damage_info)
				command_util.publish_cmd(damage_info.Owner, cmd)
			end
		end
	end
end

function local_class:check_intersection()
	if self:is_in_intersection() then
		--카운트 종료 시 영역이 겹쳐있다면 체력비례 데미지를 준다.

		self:explotion_damage({user_party_leader.Position, self.target.Position})
		self.current_interval_time = 0
		self.current_progress = self.progress.interval
		self:disable_gimmick()
	end
end

function local_class:disable_gimmick()
	for _,v in pairs(self.attack_range_list) do
		v:Hide()
	end

	if self.count_ui ~= nil then
		self.count_ui.gameObject:SetActive(false)
	end

	self.is_intersection = nil
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(target, count)
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
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
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupWaveClearEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.progress = nil
	self.current_progress = nil

	for _, v in pairs(self.attack_range_list) do
		if not is_unity_null(v) then
			CS.UnityEngine.Object.Destroy(v)
		end
	end

	self.stage_battle_info = nil
	self.attack_range_list = nil
	self.target = nil
	self.current_stage_info = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
