local local_class = newclass('TowerTransferEliteOption')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.stage_battle_info = {
		tower_ice_20 = {
			battle_group_names = {
				'battle_1'
			},
		}
	}

	self.current_stage_info = nil
	self.battle_groups = {}
	self.monster_list = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	unity_object_pool.GetOrCreate('FX_levelup_new')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.current_stage_info = self.stage_battle_info[stage.Name]
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	self.battle_groups = {}

	local battle_manager = stage.BattleManager
	local num_battle_groups = #self.current_stage_info.battle_group_names
	for i = 1, num_battle_groups do
		self.battle_groups[i] = battle_manager:GetBattleGroup(
				self.current_stage_info.battle_group_names[i])
	end

	for i = 1, num_battle_groups do
		self.monster_list[i] = self.battle_groups[i]:GetMonsters()
	end
end

function local_class:on_field_object_destroyed_event(e)
	--파괴된 오브젝트가 속한 몬스터 그룹에게 옵션을 적용시킨다.
	for i = 1, #self.current_stage_info.battle_group_names do
		if table_util.contain_value(self.monster_list[i], e.FieldObject) then
			local stage_options = e.FieldObject.FieldObjectBehaviour.StageOptions

			local get_options = {}
			for i = 0, stage_options.Count - 1 do
				local option = stage_options[i]
				table.insert(get_options, option)
			end


			for _,v in pairs(get_options) do
				local option_id = v.Option.Id
				local option_level = v.Option.Level
				local option = CS.Oak.OptionManager.CreateOption(option_id, option_level)
				for _,monster in pairs(self.monster_list[i]) do
					--엘리트옵션 추가할때 중복체크
					if not self:check_contain_options(monster, option_id) and
							not monster.FieldObjectStatsBehaviour.IsDead and
							monster.ActiveState ~= CS.Oak.ActiveState.Disabled then
						monster.EliteOptions:Add(option)
						coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
								self.elite_option_relfash, self, monster))
						unity_object_pool.GetOrCreate('FX_levelup_new'):Instantiate(monster.Position,
								unity_class.quaternion.identity, monster.Transform)
					end
				end
			end
		end
	end
end

function local_class:check_contain_options(monster, option_id)
	for _,v in pairs(monster.FieldObjectBehaviour.StageOptions) do
		if v.Option.Id == option_id then
			return true
		end
	end
	return false
end

function local_class:elite_option_relfash(monster)
	yield_return_func(monster.CharacterBehaviour.RefreshStageOptions,
			monster.CharacterBehaviour)
end

function local_class:get_target_elite_option(target)

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
	self.stage_battle_info = nil
	self.current_stage_info = nil
	self.battle_groups = nil
	self.monster_list = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
