local local_class = newclass("TowerBossKillBuffController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_progress = {
		none = 0,
		playing = 1,
		cleared = 2
	}

	-- 해당 컨트롤러에 필요한 데이터 셋 불러오기.
	self.buff_infos = require('stageeventcontrollers/TowerBossKillBuffData.lua')
	self.current_stage = self.buff_infos[stage.Name]
	self.current_stage_progress = self.stage_progress.playing
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	self:preload_effects()
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

function local_class:preload_effects()
	self.effect_table = {}

	-- 사용되는 이펙트들 미리 로딩.
	for _, v in ipairs(self.current_stage) do
		if v.effect ~= nil and v.effect.name ~= 'scale_up' then
			unity_object_pool.GetOrCreate(v.effect.name)
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if self.current_stage == nil then return end

	local boss_name = e.FieldObject.Name

	-- 보스를 처치 시
	for i = 1, #self.current_stage do
		if boss_name == self.current_stage[i].boss_name then
			self:activate_boss_kill_buff(self.current_stage[i])
		end
	end
end

-- 특정 보스 킬 했을때 버프 활성화 루틴
function local_class:activate_boss_kill_buff(data)
	local slot = lua_helper.get_or_default(data.slot, CS.Oak.EquipmentSlot.None)
	local show_effect = lua_helper.get_or_default(data.show_effect, false)
	local show_text = lua_helper.get_or_default(data.show_text, false)
	local only_party_leader = lua_helper.get_or_default(data.only_party_leader, false)
	local buff_spec_name = lua_helper.get_or_default(data.buff_spec_name, nil)
	local buff_level = lua_helper.get_or_default(data.buff_level, 0)
	local heal_cooltime = lua_helper.get_or_default(data.heal_cooltime, 8)
	local effect = lua_helper.get_or_default(data.effect, nil)
	local target_num = (only_party_leader == false) and user_party.Count - 1 or 0

	if buff_spec_name == 'periodical_heal' then
		local triggered_event = util.cs_generator(self.periodical_heal, self,
				target_num, buff_level, heal_cooltime, effect)
		coroutine_manager:StartCoroutine(stage.StageGameObject, triggered_event)
		return
	elseif buff_spec_name == 'heal' then
		for i = 0, target_num do
			self:manual_heal_routine(user_party[i], buff_level, heal_cooltime, effect)
		end
		return
	end

	for i = 0, target_num do
		buff_manager:AddBuff(user_party_leader, slot, user_party[i], buff_spec_name,
				buff_level, show_effect, show_text)

		if (effect ~= nil) then
			if effect.name == 'scale_up' then
				user_party[i].transform.localScale = vector(effect.scale.x, effect.scale.y, effect.scale.z)
			else
				local pooled_effect = self:instantiate_pooled_effect(user_party[i], effect)
				self.effect_table[#self.effect_table + 1] = pooled_effect
			end
		end
	end
end

function local_class:periodical_heal(count, heal_ratio, heal_cooltime, effect)
	local time_passed = heal_cooltime

	-- 이펙트 적용
	for index = 0, count do
		if (effect ~= nil) then
			local pooled_effect = self:instantiate_pooled_effect(user_party[index], effect)
			self.effect_table[#self.effect_table + 1] = pooled_effect
		end
	end

	while self.current_stage_progress == self.stage_progress.playing do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed > heal_cooltime then
			for index = 0, count do
				self:manual_heal_routine(user_party[index], heal_ratio)
			end
			time_passed = 0
		end
		coroutine.yield(nil)
	end
end

function local_class:manual_heal_routine(target, heal_ratio)
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = nil
	heal_info.target = target
	heal_info.heal = math.floor(target.FieldObjectStatsBehaviour.MaxHP * heal_ratio)
	command_util.execute_heal(heal_info)
end

function local_class:instantiate_pooled_effect(target, data)
	local position = target.Position
	-- 이펙트의 회전도를 돌려줘야 하는 경우
	if data.rotated then
		position = position + target.SpineController.SpineTotalOffset
				+ (data.height_offset * unity_class.vector3.up)
	end
	local transform = target.SpineController.SpineContainerTransform
	local rotation = vector(data.init_dir.x, data.init_dir.y, data.init_dir.z)
	local pool = unity_object_pool.GetOrCreate(data.name)
	local pooled_effect = CS.Oak.UnityObjectPoolExtensions.Instantiate(pool, position, rotation, transform,
			CS.Oak.ParentFollowFlag.All)

	return pooled_effect
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.current_stage_progress = self.stage_progress.none

	for __, effect in ipairs(self.effect_table) do
		effect:Dispose()
	end

	self.buff_infos = nil
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
