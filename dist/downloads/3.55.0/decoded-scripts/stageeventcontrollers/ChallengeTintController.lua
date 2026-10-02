local local_class = newclass("ChallengeTintController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	self.use_battle_gate = false
	self.battle_count = 0
	self.total_battle = 2
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent), 'on_field_object_revived_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

--region on_event
function local_class:on_stage_loaded_event(e)
	local monsters = character_manager:GetAllMonsters()

	for i = 0, monsters.Count - 1 do
		monsters[i].SpineController:AddColor('challenge', unity_color({0.5, 0.5, 0.8, 1}), 0.7, 0)
	end

	local boss = get_character('boss')
	boss.SpineController:RemoveColor('challenge', 0)

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 'boss' or e.BattleGroupName == 'boss_1' then
		self.battle_count = self.battle_count + 1
		if self.battle_count == self.total_battle then
			for i = 1, 2 do
				message_system:Publish(CS.Oak.BattleGateOpenEvent.Create('battlegate_'..i))
			end
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false or e.FieldObject ~= user_party_leader or self.use_battle_gate == true then
		return false
	end

	local zone_name = e.Zone.Name

	if zone_name == 'boss' then
		self.use_battle_gate = true

		for i = 1, 2 do
			message_system:Publish(CS.Oak.BattleGateCloseEvent.Create('battlegate_'..i))
		end
	end

	return false
end

--FIXME: BattleInstance들을 받아올 방법이 없어 몬스터들을 통해 모두 순회하도록 하였으니 나중에 변경해야함
function local_class:on_field_object_revived_event(e)
	-- 체크가 끝난 BattleInstance
	local checking_completed_instance = {}

	-- 몬스터들을 받아와서
	local monsters = character_manager:GetAllMonsters()
	-- 몬스터들을 순회하면서
	for monster_index = 0, monsters.Count - 1 do
		-- 해당 몬스터가 속해 있는 BattleInstance를 받아온다
		local battle_instance = stage.BattleManager:GetBattleFor(monsters[monster_index])
		if battle_instance ~= nil then
			-- 체크하지 않은 BattleInstance 이면
			if table_util.contain_value(checking_completed_instance, battle_instance) == false then
				-- 해당 몬스터가 속해 있는 BattleInstance에 적들의 Active상태를 체크
				local is_alive_monster = false
				for enemy_index = 0, battle_instance.Enemies.Count - 1 do
					local status = battle_instance.Enemies[enemy_index]
					if status.IsActive then
						is_alive_monster = true
						break
					end
				end

				-- 모든 몬스터의 Active상태가 false라면
				if is_alive_monster == false then
					for i = 0, battle_instance.Allies.Count - 1 do
						local status = battle_instance.Allies[i]
						status.IsActive = false
					end
				end

				table.insert(checking_completed_instance, battle_instance)
			end
		end
	end

	return false
end

function local_class:on_event(e)
	return false
end
--endregion


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectRevivedEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
