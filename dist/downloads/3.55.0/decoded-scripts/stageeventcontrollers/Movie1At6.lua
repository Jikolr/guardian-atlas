local local_class = newclass("Movie1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.battle_1_event_open = false
	self.battle_2_event_open = false
	self.battle_3_event_open = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	return
end

function local_class:need_on_launch()
	local movie_main_quest_id = 60005
	local q = user_progress:GetStartedQuest(movie_main_quest_id)
	return q ~= nil and q.InnerProgress >= 20 and not q.IsComplete
end

-- 배틀 게이트 온오프 함수: 매뉴얼 타입이 트루이면 클로즈, 거짓이면 오픈
function local_class:gate_manual_controll(manual_type,battle_num, length)
	if manual_type then
		for i=1, length do
			local temp_name = "battle_".. battle_num .."_gate_".. i
			message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(temp_name))
		end

	elseif not manual_type then
		for i=1, length do
			local temp_name = "battle_".. battle_num .."_gate_".. i
			message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(temp_name))
		end
	end
	return
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	self.cs_controller = nil
	self.battle_1_event_open = nil
	self.battle_2_event_open = nil
	self.battle_3_event_open = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

function local_class:on_event(e)
	local movie_main_quest_id = 60005
	local q = user_progress:GetStartedQuest(movie_main_quest_id)
	local event_type = e:GetType()

	if q.IsComplete then
		if event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
			if e.BattleGroupName == "BATTLE_1" then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, false, 1, 4))
			elseif e.BattleGroupName == "BATTLE_2" then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, false, 2, 6))
			elseif e.BattleGroupName == "BATTLE_3" then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, false, 3, 6))
			end
		elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
			self:on_zone_enter_event(e)
		end
	end
	return false
end

function local_class:on_zone_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return
	end
	local zone_name = e.Zone.Name

	if zone_name == "BATTLE_1" then
		if self.battle_1_event_open == false then
			self.battle_1_event_open = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, true, 1, 4))
		end

	elseif zone_name == "BATTLE_2" then
		if self.battle_2_event_open == false then
			self.battle_2_event_open = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, true, 2, 6))
		end

	elseif zone_name == "BATTLE_3" then
		if self.battle_3_event_open == false then
			self.battle_3_event_open = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, true, 3, 6))
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}