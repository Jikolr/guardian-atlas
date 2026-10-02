local local_class = newclass("MovieChallengeDebuffController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.buff_data = {
		{
			option_id = 200022,
			battle_group = 'battle1',
			monster_count = 5
		},
		{
			option_id = 200021,
			battle_group = 'battle2',
			monster_count = 6
		},
		{
			option_id = 200010,
			battle_group = 'battle3',
			monster_count = 3
		},
		{
			option_id = 200001,
			battle_group = 'battle4',
			monster_count = 5
		},
		{
			option_id = 200022,
			battle_group = 'battle5',
			monster_count = 6
		}
	}

	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')

	unity_object_pool.GetOrCreate('FX_Char_Debuff_purple')

	self.boss = get_character('boss')

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

---[[ on_event
function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return false end
	if e.FieldObject ~= user_party_leader then return false end

	local zone_name = e.Zone.Name

	if zone_name == 'boss' then
		stage.BattleManager:ForceEndBattles()

		stage.ProjectileManager:ClearProjectiles()
		stage.AreaOfEffectManager:ClearAllAoe()

		for i = 0, user_party.Count - 1 do
			user_party[i].CharacterBehaviour:CancelAllBattleActions(true)
		end
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)

	-- 1은 튜토리얼
	if not self.boss.CharacterStatsBehaviour.IsDead then
		for i = 2, #self.buff_data do
			if e.BattleGroupName == self.buff_data[i].battle_group then
				sp_util.play_normal_screenplay(self.show_joker_debuff, self, self.buff_data[i].option_id)
			end
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for i = 1, #self.buff_data do

		local tower = get_character('battle_' .. i .. '_1')

		if lua_helper.reference_equals(e.FieldObject, tower) then

			for j = 2, self.buff_data[i].monster_count do
				local monster = get_character('battle_' .. i .. '_' .. j)

				local monster_option = monster.FieldObjectBehaviour.StageOptions

				for k = 0, monster_option.Count - 1 do
					monster_option[k]:Deactivate()
				end

				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.monster_lost_power, self, monster))
			end

		end
	end

	return false
end
---]]

function local_class:show_joker_debuff(option_id)
	local stage_option = self.boss.FieldObjectBehaviour.StageOptions

	camera_util.move_async(self.boss.Position, 1)

	self:monster_lost_power(self.boss)

	for j = 0, stage_option.Count - 1 do

		if stage_option[j].Option.Id == option_id then
			stage_option[j]:Deactivate()
		end

	end

	wait_for_sec(1)

	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))

	self.boss = nil

	self.buff_data = nil
	self.stage_data = nil
	self.cs_controller = nil
end

function local_class:monster_lost_power(monster)
	local effect = unity_object_pool.GetOrCreate('FX_Char_Debuff_purple')
			:Instantiate(monster.Position, unity_class.quaternion.identity, monster.Transform)

	wait_for_sec(1)

	effect:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
