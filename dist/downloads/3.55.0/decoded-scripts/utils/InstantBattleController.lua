---@class InstantBattleController
local local_class = newclass('InstantBattleController')

function local_class:init(info)
	self.waves = {}

	local wave_metatable = {
		__index = {
			-- FIXME : 탐색 최적화 필요한가?
			contains = function(this, monster)
				for i = 1, #this.monster_infos do
					if lua_helper.reference_equals(monster, this.monster_infos[i].monster) then
						return true
					end
				end

				return false
			end,
			is_done = function(this)
				for i = 1, #this.monster_infos do
					if not this.monster_infos[i].monster.FieldObjectStatsBehaviour.IsDead then
						return false
					end
				end

				return true
			end,
			foreach_monster = function(this, action)
				for i = 1, #this.monster_infos do
					action(i, this.monster_infos[i])
				end
			end
		}
	}

	for index, wave_info in pairs(info.waves) do
		self.waves[index] = setmetatable({
			monster_infos = wave_info.monster_infos,
			group_spawn_routine = wave_info.group_spawn_routine,
			single_spawn_routine = wave_info.single_spawn_routine,
		}, wave_metatable)
	end

	self.current_wave_num = 0

	self.common_info = info.common

	self.is_stage_ended = false

	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
end

-- 전투 종료 이후 호출 요망
function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.battle_info = nil
end

function local_class:on_field_object_destroyed_event(e)
	if not self:is_last_wave() then
		local current_wave = self:get_current_wave()

		if current_wave:contains(e.FieldObject) and current_wave:is_done() then
			self.current_wave_num = self.current_wave_num + 1

			if self:is_last_wave() then
				message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
			end

			start_coroutine(self.spawn_routine, self)

			return true
		end
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if self:is_last_wave() and e.BattleGroupName == self.common_info.group_name then
		self:end_battle()

		return true
	end

	return false
end

function local_class:on_stage_end_event(e)
	self.is_stage_ended = true

	return true
end

function local_class:start_battle()
	self.current_wave_num = 1

	if not self:is_single_battle() then
		stage.BattleManager.PlayBattleVoiceAndFanfare = false
		stage.BattleManager.PlayBattleEndEffect = false
	else
		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	end

	self:close_battle_gates()

	local current_wave = self:get_current_wave()

	current_wave:foreach_monster(function(_, monster_info)
		self:convert_to_monster_and_notice(monster_info)
	end)
end

function local_class:spawn_routine()
	local current_wave = self:get_current_wave()

	if current_wave.group_spawn_routine ~= nil then
		current_wave.group_spawn_routine(self.current_wave_num)

		if self.is_stage_ended then
			return
		end

		current_wave:foreach_monster(function(_, monster_info)
			self:convert_to_monster_and_notice(monster_info)
		end)

	elseif current_wave.single_spawn_routine ~= nil then
		local routines = {}

		current_wave:foreach_monster(function(index, monster_info)
			table.insert(routines, function()
				current_wave.single_spawn_routine(self.current_wave_num, index, monster_info.monster)

				if self.is_stage_ended then
					return
				end

				self:convert_to_monster_and_notice(monster_info)
			end)
		end)

		wait_all_lua(table.unpack(routines))
	else
		-- TODO : 각기 다른 루틴을 타야되는 경우에는 어떻게 할 것인가?
	end

	if self.is_stage_ended then
		return
	end

	if not self:is_single_battle() and self:is_last_wave() then
		stage.BattleManager.PlayBattleVoiceAndFanfare = true
		stage.BattleManager.PlayBattleEndEffect = true

		message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	end
end

function local_class:end_battle()
	self.current_wave_num = 0

	self:open_battle_gates()

	self.common_info.end_callback()
end

function local_class:convert_to_monster_and_notice(monster_info)
	character_util.convert_to_monster(monster_info.monster, self.common_info.group_name, self.common_info.zone_name)

	command_util.publish_monster_notice(monster_info.monster, get_party_leader(), 'battle')

	if monster_info.death_type ~= nil then
		character_util.set_death_type(monster_info.monster, monster_info.death_type)
	end
end

function local_class:close_battle_gates()
	if self.common_info.battle_gate_names == nil then
		return
	end

	for _, name in pairs(self.common_info.battle_gate_names) do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(name))
	end
end

function local_class:open_battle_gates()
	if self.common_info.battle_gate_names == nil then
		return
	end

	for _, name in pairs(self.common_info.battle_gate_names) do
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(name))
	end
end

function local_class:get_current_wave()
	return self.waves[self.current_wave_num]
end

function local_class:is_last_wave()
	return self.current_wave_num == #self.waves
end

function local_class:is_single_battle()
	return #self.waves == 1
end

return local_class
