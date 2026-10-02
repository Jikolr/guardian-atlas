local local_class = newclass('TowerHitStackBuffOption')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress = {
		none = 1,
		playing = 2,
		cleared = 3,
	}

	-- 해당 컨트롤러에 필요한 데이터 셋 불러오기.
	self.stage_battle_info = require('stageeventcontrollers/TowerHitStackBuffData.lua')

	self.current_stack_count = 0
	self.effect_name = "elemental_tower_buff"
	self.is_attach_buff_effect = false
	self.targets = nil
	self.count_ui = nil
	self.current_stage_info = nil
	self.buff_effect_list = {}
	self.current_progress = self.progress.none
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]

	self.targets = {}

	for _,v in pairs(self.current_stage_info.boss_names) do
		local boss = get_character(v)
		table.insert(self.targets, boss)
	end
	unity_object_pool.GetOrCreate(self.effect_name)
	unity_object_pool.GetOrCreate('FieldUIDuelBuffState')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start(e)
	sp_util.play_normal_screenplay(field_ui_util.show_narration_async,
			{key = self.current_stage_info.description, parameters = {self.current_stage_info.max_count} })
end

function local_class:on_battle_start_event(e)
	self.current_progress = self.progress.playing
end

function local_class:on_battle_end_event(e)
	self.current_progress = self.progress.none
	self:detach_count_ui()

	self:remove_buff()
end

function local_class:on_damage_event(e)
	if self.current_progress ~= self.progress.playing then return end

	if table_util.contain_value(self.targets, e.Info.sender) and
			lua_helper.reference_equals(user_party_leader, e.Info.target)then
		self:be_hit()
	end
end

function local_class:be_hit()
	self.current_stack_count = self.current_stack_count + 1

	if self.count_ui == nil then
		self:attach_count_ui(self.current_stack_count)
	else
		self:update_count_ui(self.current_stack_count)
	end

	if self.current_stack_count >= self.current_stage_info.max_count then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dead, self))
	else
		self:update_buff()
	end
end

function local_class:update_buff()
	if self.current_stack_count <= 0 then return end

	for i = 0, user_party.Count - 1 do
		local member = user_party[i]

		--기존 버프 해제
		buff_manager:RemoveBuff(member, CS.Oak.EquipmentSlot.None, member, self.current_stage_info.buff_id)

		buff_manager:AddBuff(member, CS.Oak.EquipmentSlot.None, member, self.current_stage_info.buff_id,
		self.current_stage_info.buff_level * self.current_stack_count, false, false)
	end

	if not self.is_attach_buff_effect then
		for i = 0, user_party.Count - 1 do
			if not user_party[i].FieldObjectStatsBehaviour.IsDead and
					user_party[i].ActiveState ~= CS.Oak.ActiveState.Disabled then
				table.insert(self.buff_effect_list, self:attach_buff_effect(user_party[i]))
			end
		end
		self.is_attach_buff_effect = true
	end
end

function local_class:attach_buff_effect(target)
	local effect_pos = target.Position + target.SpineController.SpineTotalOffset + -0.1 * unity_class.vector3.up
	local effect = unity_object_pool.GetOrCreate(self.effect_name):Instantiate(effect_pos)
	effect.transform.localRotation = unity_class.quaternion.Euler(0, -90, 0)
	effect.transform.parent = target.SpineController.SpineContainerTransform
	effect.transform.localScale = vector(1, 1.5, 1.2)
	return effect
end

function local_class:dead()
	--모든 버프를 지운다.
	self:remove_buff()

	coroutine.yield(nil)

	local damage_info = CS.Oak.DamageInfo()
	damage_info.sender = user_party_leader
	damage_info.target = user_party_leader
	damage_info.type = CS.Oak.DamageType.Trap | CS.Oak.DamageType.Death
	damage_info.damage = CS.Oak.DamageConstants.InstantKillDamage

	local cmd = CS.Oak.DamageCommand.Create(damage_info)
	command_util.publish_cmd(damage_info.Owner, cmd)

	self.current_progress = self.progress.none
end

function local_class:remove_buff()
	for i = 0, user_party.Count - 1 do
		buff_manager:RemoveBuff(user_party[i], CS.Oak.EquipmentSlot.None, user_party.Leader)

		if self.buff_effect_list[i + 1] ~= nil then
			self.buff_effect_list[i + 1]:Dispose()
			self.buff_effect_list[i + 1] = nil
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_progress ~= self.progress.playing then return true end

	for i = 0, user_party.Count - 1 do
		if lua_helper.reference_equals(user_party[i], e.FieldObject) and
				user_party[i].FieldObjectStatsBehaviour.IsDead then
			if self.buff_effect_list[i + 1] ~= nil then
				self.buff_effect_list[i + 1]:Dispose()
			end
		end
	end
end

-- 카운트 UI 시작하기 위해 붙임
function local_class:attach_count_ui(count)
	-- FIXME: 2.10에 X축 0 -> 0.25로 변경
	local target = user_party_leader
	local offset = vector(0, target.Bounds.size.y + 2, -0.5)
	self.count_ui = unity_object_pool.GetOrCreate('FieldUIDuelBuffState'):Instantiate(target.Position + offset,
			unity_class.quaternion.identity, target.Transform)

	self.count_ui.transform:Find('Offset').gameObject:SetActive(false)

	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = count
	tmp.color = unity_class.color.white
end

function local_class:detach_count_ui()
	if self.count_ui ~= nil then
		self.count_ui.transform:Find('Offset').gameObject:SetActive(true)
		self.count_ui:Dispose()
		self.count_ui = nil
	end
end

-- 카운트 UI 갱신
function local_class:update_count_ui(value)
	local tmp = self.count_ui.transform:Find('BuffCountText'):GetComponent(typeof(CS.TMPro.TextMeshPro))
	tmp.text = value

	if value <= 3 then
	elseif value <= 7 then
		tmp.color = unity_class.color.yellow
	else
		tmp.color = unity_class.color.red
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	self.cs_controller = nil
	self.stage_battle_info = nil
	self.current_stage_info = nil

	for i = 1, #self.buff_effect_list do
		if self.buff_effect_list[i] ~= nil then
			self.buff_effect_list[i]:Dispose()
			self.buff_effect_list[i] = nil
		end
	end

	self.buff_effect_list = nil
	self.targets = nil
	self.count_ui = nil
	self.current_progress = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
