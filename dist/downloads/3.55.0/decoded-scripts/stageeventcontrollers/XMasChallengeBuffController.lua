local local_class = newclass('XMasChallengeBuffController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.progress_enum = {
		-- 초기 상태
		none = 1,
		-- 보스와 전투 상태
		boss_battle = 2,
		-- 보스 잡은 상태
		clear = 3
	}

	self.current_progress = self.progress_enum.none

	-- npc
	self.get_boss = function() return get_character('boss') end

	-- 오브젝트 풀
	self.get_fx_immune = function() return unity_object_pool.GetOrCreate('fx_abnormal_immune_all') end
	self.fx_immune_dispose = function()
		if self.fx_immune then
			self.fx_immune:Dispose()
		end
	end

	self.boss_zone_name = 'boss'
	self.boss_buff_name = 'persistent_no_damage'

	-- 전투 시작 후 보스한테 버프를 주기까지 기다리는 시간
	self.start_wait_buff_time = 3
	-- 버프 지속 시간
	self.buff_duration = 3
	-- 버프 지속 시간이 끝난 후 다시 버프를 주기까지 기다리는 시간 (버프 주기)
	self.buff_interval = 7
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	quest_util.load_pool_resource(
		'fx_abnormal_immune_all'
	)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))

	self.fx_immune_dispose()
	self.fx_immune = nil

	self.cs_controller = nil
end

--- OnEvent
function local_class:on_event(_)
	return false
end

--- ZoneEnterEvent
function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.boss_zone_name) then
		if self.current_progress == self.progress_enum.none then
			self.current_progress = self.current_progress + 1
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.boss_buff_routine, self))
		end
		return true
	end

	return false
end

--- BattleGroupEliminatedEvent
function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.boss_zone_name then
		if self.current_progress == self.progress_enum.boss_battle then
			self.current_progress = self.current_progress + 1

			self.fx_immune_dispose()
			stage.BuffManager:RemoveBuff(self.get_boss(), CS.Oak.EquipmentSlot.None, self.get_boss(), self.boss_buff_name)
		end
		return true
	end

	return false
end

-- 보스 버프 루틴
function local_class:boss_buff_routine()
	local boss = self.get_boss()

	wait_for_sec(self.start_wait_buff_time)

	while self.current_progress == self.progress_enum.boss_battle do
		self.fx_immune = self.get_fx_immune():Instantiate(boss.Position + vector(0, 0, 0.5),
			unity_class.quaternion.identity, boss.Transform)
		stage.BuffManager:AddBuff(boss, CS.Oak.EquipmentSlot.None, boss, self.boss_buff_name, 0, false, false)

		wait_for_sec(self.buff_duration)

		if self.current_progress ~= self.progress_enum.boss_battle then
			return
		end

		self.fx_immune_dispose()
		stage.BuffManager:RemoveBuff(boss, CS.Oak.EquipmentSlot.None, boss, self.boss_buff_name)

		wait_for_sec(self.buff_interval)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
