local local_class = newclass("TowerDebuffController")


function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.buff_data = {
		{
			option_id = 400003,
			boss_name = 'boss_harvester',
			battle_name = 'battle1'
		},
		{
			-- 실제로 사용하지 않는 더미 데이터
			option_id = 200021,
			boss_name = 'boss_dummy_data',
			battle_name = 'boss_dummy_data'
		},
		{
			option_id = 200001,
			boss_name = 'boss_sapa',
			battle_name = 'battle3'
		},
		{
			option_id = 200010,
			boss_name = 'boss_demon',
			battle_name = 'battle4'
		}
	}

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')

	unity_object_pool.GetOrCreate('FX_Char_Debuff_purple')
	unity_object_pool.GetOrCreate('FX_Blockaura_Char_white')

	self.current_boss_index = 1
	self.bosses = { get_character('constant_boss_marina'), get_character('boss_marina') }
	self.regen_effects = nil

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
function local_class:on_stage_loaded_event(e)

	local effect_target = { get_character('constant_boss_marina'), get_character('boss_marina'),
							get_character('boss_harvester') }

	self.regen_effects = {}

	for i = 1, #effect_target do
		self.regen_effects[i] = unity_object_pool.GetOrCreate('FX_Blockaura_Char_white')
				 :Instantiate(effect_target[i].Position, unity_class.quaternion.identity, effect_target[i].Transform)
	end

	self.regen_effects[3].transform.localScale = vector(3, 3, 3)
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName ~= 'boss' then

		if e.BattleGroupName == 'battle1' then
			-- 리젠 이펙트 제거
			for i = 1, #self.regen_effects do
				self.regen_effects[i]:Dispose()
			end

			self.regen_effects = nil

		elseif e.BattleGroupName == 'battle2' then
			sp_util.play_normal_screenplay(self.boss_change, self)
			return true
		end

		if not self.bosses[self.current_boss_index].CharacterStatsBehaviour.IsDead then
			for i = 1, #self.buff_data do
				-- constant 몬스터 그룹 2번은 더미 데이터 이기 때문에 이 루틴을 타지 않는다.
				if e.BattleGroupName == self.buff_data[i].battle_name then
					sp_util.play_normal_screenplay(self.show_boss_debuff, self, self.buff_data[i].option_id)
				end
			end
		end

	end

	return false
end
---]]

-- 보스 버프 해제
function local_class:show_boss_debuff(option_id)
	local stage_options = {}

	for i = 1, 2 do
		stage_options[i] = self.bosses[i].FieldObjectBehaviour.StageOptions
	end

	camera_util.resize_to_default(1)
	camera_util.move_async(self.bosses[self.current_boss_index].Position, 1)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.monster_lost_power, self,
			self.bosses[self.current_boss_index]))

	if option_id == 200010 then
		local time_passed = 0
		local duration = 0.3
		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime
			local progress = (time_passed / duration)

			self.bosses[self.current_boss_index]:SetGiantFactor('elite_stat', 1.3 - 0.3 * progress)

			coroutine.yield(nil)
		end
	end

	for i = 1, 2 do
		for j = 0, stage_options[i].Count - 1 do

			if stage_options[i][j].Option.Id == option_id then
				stage_options[i][j]:Deactivate()
			end

		end
	end

	wait_for_sec(2)

	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.bosses = nil

	self.buff_data = nil
	self.stage_data = nil
	self.cs_controller = nil

	if self.regen_effects ~= nil then
		for i = 1, #self.regen_effects do
			self.regen_effects[i]:Dispose()
		end

		self.regen_effects = nil
	end
end

function local_class:boss_change()
	character_util.convert_to_npc(self.bosses[2])
	self.current_boss_index = 2

	character_util.spine_set_alpha_fade(self.bosses[2], 0, 0)
	self.bosses[2].Position = self.bosses[1].Position

	camera_util.move_async(self.bosses[1].Position, 1)

	character_util.spine_set_alpha_fade(self.bosses[1], 0, 1)
	character_util.spine_set_alpha_fade(self.bosses[2], 1, 1)
	wait_for_sec(2)
	character_util.convert_to_monster(self.bosses[2], 'boss', 'boss')

	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})

	character_util.convert_to_npc(self.bosses[1])
	character_util.set_position(self.bosses[1], vector(99, 0, 99))
	character_util.convert_to_monster(self.bosses[1], 'another')
end

function local_class:monster_lost_power(monster)
	local effect = unity_object_pool.GetOrCreate('FX_Char_Debuff_purple')
			:Instantiate(monster.Position, unity_class.quaternion.identity, monster.Transform)
	effect.transform.localScale = vector (2, 2, 2)

	wait_for_sec(2)

	effect:Dispose()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
