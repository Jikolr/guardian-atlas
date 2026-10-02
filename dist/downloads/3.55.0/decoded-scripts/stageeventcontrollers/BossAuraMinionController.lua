local local_class = newclass('BossAuraMinionController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local data = require('stageeventcontrollers/BossAuraMinionControllerData.lua')[stage.Name]

	self.minion_name_table = data.minions
	self.option_id = data.enhance_option_id
	self.option_level = data.option_level

	self.barrier_fx_name = data.barrier_preset
	self.barrier_end_fx_name = data.barrier_break_preset

	self.revive_marker_fx_name = data.revive_mark_preset
	self.revive_target_fx_name = data.revive_target
	self.enhance_fx_name = data.enhance_preset

	self.activated_minion_table = {}
	self.deactivated_minion_table = {}

	self.enhanced_minion_table = {}
	self.not_enhanced_minion_table = {}

	self.cast_fx_table = {}
	self.revive_fx_pool = {}

	self.revive_count = 0
	self.revive_monster_count = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	unity_object_pool.GetOrCreate(self.revive_marker_fx_name)
	unity_object_pool.GetOrCreate(self.revive_target_fx_name)
	unity_object_pool.GetOrCreate(self.enhance_fx_name)
	unity_object_pool.GetOrCreate(self.barrier_fx_name)
	unity_object_pool.GetOrCreate(self.barrier_end_fx_name)

	self.barrier_fx = nil

	self:initialize_minion_info()
end

function local_class:on_field_object_revived_event(e)
	for i = #self.deactivated_minion_table, 1, -1 do
		if self.deactivated_minion_table[i] == e.FieldObject then
			e.FieldObject.DamagedBehaviour.DeathType = CS.Oak.DeathType.Prostrate
			e.FieldObject.ActiveState = CS.Oak.ActiveState.Enabled
			table.insert(self.activated_minion_table, table.remove(self.deactivated_minion_table, i))
			table.insert(self.not_enhanced_minion_table, e.FieldObject)
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	for i = #self.activated_minion_table, 1, -1 do
		if self.activated_minion_table[i] == e.FieldObject then
			e.FieldObject.ActiveState = CS.Oak.ActiveState.Visible
			table.insert(self.deactivated_minion_table, table.remove(self.activated_minion_table, i))

			self:remove_target_from_enhance_candidate(e.FieldObject)
			self:remove_enhance_from_target(e.FieldObject)

			if #self.cast_fx_table ~= 0 then
				self:set_revive_cast_fx(e.FieldObject)
			end

			if #self.activated_minion_table == 0 then
				self:dispose_all_revive_cast_fx()
				message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, {'destroyed_all_minion'}))
				if self.barrier_fx ~= nil then
					unity_object_pool.GetOrCreate(self.barrier_end_fx_name):Instantiate(self.barrier_fx.transform.position)
					self.barrier_fx:Dispose()
					self.barrier_fx = nil
				end
			end
		end
	end
end

function local_class:remove_target_from_enhance_candidate(target)
	for i = #self.not_enhanced_minion_table, 1, -1 do
		if self.not_enhanced_minion_table[i] == target then
			table.remove(self.not_enhanced_minion_table, i)
			return
		end
	end
end

function local_class:remove_enhance_from_target(target)

	for i = #self.enhanced_minion_table, 1, -1 do
		if self.enhanced_minion_table[i] == target then
			table.remove(self.enhanced_minion_table, i)

			self:remove_elite_option(target)

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
					self.elite_option_refresh, self, target))
		end
	end

end

function local_class:elite_option_refresh(target)
	yield_return_func(target.CharacterBehaviour.RefreshStageOptions,
			target.CharacterBehaviour)
end

function local_class:remove_elite_option(target)
	for i = 0, target.EliteOptions.Count - 1 do
		if target.EliteOptions[i].Id == self.option_id then
			target.EliteOptions:RemoveAt(i)
			break
		end
	end
end

function local_class:initialize_minion_info()
	for i = 1, #self.minion_name_table do
		local minion = stage:GetCharacter(self.minion_name_table[i])
		table.insert(self.activated_minion_table, minion)
		table.insert(self.not_enhanced_minion_table, minion)
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'request_initialize_aura_ai' then
		if self.barrier_fx == nil then
			self.barrier_fx = unity_object_pool.GetOrCreate(self.barrier_fx_name):Instantiate(e.Sender.Position)
		end
		message_system:PublishSync(
				CS.Oak.CustomStageEvent.Create(
						nil,
						{
							'initialize_aura_ai',
							#self.activated_minion_table + #self.deactivated_minion_table,
							#self.deactivated_minion_table,
							#self.not_enhanced_minion_table,
							self.revive_monster_count,
							self.revive_count
						}))

	elseif e:GetParamAt(0) == 'request_update_minion_info' then
		message_system:PublishSync(
				CS.Oak.CustomStageEvent.Create(
						nil,
						{
							'update_minion_info',
							#self.deactivated_minion_table,
							#self.not_enhanced_minion_table
						}))

	elseif e:GetParamAt(0) == 'add_elite_option' then
		self:add_elite_option_to_minion()

	elseif e:GetParamAt(0) == 'revive_all_minions' then
		self:revive_all_minions()

	elseif e:GetParamAt(0) == 'revive_canceled' then
		self:dispose_all_revive_cast_fx()

	elseif e:GetParamAt(0) == 'revive_cast' then
		self:prepare_revive_cast_fx()
		for i = 1, #self.deactivated_minion_table do
			self:set_revive_cast_fx(self.deactivated_minion_table[i])
		end

	end
end

function local_class:prepare_revive_cast_fx()
	self.revive_fx_pool = {}
	for i = 1, #self.minion_name_table do
		table.insert(self.revive_fx_pool, unity_object_pool.GetOrCreate(self.revive_marker_fx_name):Instantiate(vector(999,999,999)))
	end
end

function local_class:set_revive_cast_fx(target)
	if self.revive_fx_pool == nil or #self.revive_fx_pool == 0 then
		return
	end

	local fx = table.remove(self.revive_fx_pool, 1)
	fx.transform.position = target.Position

	table.insert(self.cast_fx_table, fx)
end

function local_class:dispose_all_revive_cast_fx()
	for i = #self.cast_fx_table, 1, -1 do
		table.remove(self.cast_fx_table, i):Dispose()
	end

	for i = #self.revive_fx_pool, 1, -1 do
		table.remove(self.revive_fx_pool, i):Dispose()
	end
end

function local_class:set_enhance_fx(target)
	unity_object_pool.GetOrCreate(self.enhance_fx_name):Instantiate(target.Position, unity_class.quaternion.identity, target.Transform)
end

function local_class:add_elite_option_to_minion()
	if #self.not_enhanced_minion_table == 0 then
		return
	end

	--체력비율 높은 소환수에 부여
	local candidates = {}
	local max_ratio = -1

	for i = #self.not_enhanced_minion_table, 1, -1 do
		local target = self.not_enhanced_minion_table[i]

		if target.FieldObjectStatsBehaviour.HpRatio > max_ratio then
			max_ratio = target.FieldObjectStatsBehaviour.HpRatio
			candidates = {}
			table.insert(candidates, {idx = i, target = target})

		elseif target.FieldObjectStatsBehaviour.HpRatio == max_ratio then
			table.insert(candidates, {idx = i, target = target})

		end
	end

	local option = CS.Oak.OptionManager.CreateOption(self.option_id, self.option_level)
	local target_table = candidates[random_util.get_random_int(1, #candidates)]
	local target = target_table.target
	table.insert(self.enhanced_minion_table, table.remove(self.not_enhanced_minion_table, target_table.idx))
	target.EliteOptions:Add(option)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
			self.elite_option_refresh, self, target))
	music_player:PlaySfxOneShot('02_magic_heal_04')
	self:set_enhance_fx(target)
end

function local_class:revive_all_minions()
	for i = #self.deactivated_minion_table, 1, -1 do
		--인스턴스 여러 개 만들어 지는 것 방지
		self.deactivated_minion_table[i].FieldObjectStatsBehaviour.NoticeLinkName = nil

		local heal_info = CS.Oak.HealInfo()
		heal_info.sender = self.deactivated_minion_table[i]
		heal_info.target = self.deactivated_minion_table[i]
		heal_info.heal = self.deactivated_minion_table[i].CharacterStatsBehaviour.MaxHP
		heal_info.isRevive = true

		command_util.publish_heal(heal_info)
		command_util.publish_monster_notice(self.deactivated_minion_table[i], user_party.Leader, 'battle')

		unity_object_pool.GetOrCreate(self.revive_target_fx_name):Instantiate(self.deactivated_minion_table[i].Position)
	end

	music_player:PlaySfxOneShot('02_dark_projectile_03')

	self.revive_count = self.revive_count + 1
	self.revive_monster_count = self.revive_monster_count + #self.deactivated_minion_table
	self:dispose_all_revive_cast_fx()
	message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, {'minion_revive_triggered', self.revive_monster_count, self.revive_count}))
end

function local_class:dispose()
	self.cs_controller = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.activated_minion_table = nil
	self.deactivated_minion_table = nil

	self.enhanced_minion_table = nil
	self.not_enhanced_minion_table = nil

	self.cast_fx_table = nil
end

function local_class:on_event(e)
	return false
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
