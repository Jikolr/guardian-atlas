local local_class = newclass("Fox1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.battle_2_event_open = false
	self.tint_loop_stat = false

end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	return
end

function local_class:need_on_launch()
	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)

	local statue_nari = get_character('statue_nari')
	local statue_garam = get_character('statue_garam')

	statue_nari.transform.localScale = vector(1.5, 1.5, 1.5)
	statue_garam.transform.localScale = vector(1.5, 1.5, 1.5)

	statue_nari.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	statue_nari.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(statue_nari, CS.Oak.FieldUiType.CharacterStats)

	statue_garam.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	statue_garam.DamagedBehaviour = CS.Oak.NullDamagedBehaviour.Instance
	field_ui_manager:RemoveUI(statue_garam, CS.Oak.FieldUiType.CharacterStats)

	-- 나리, 가람 석상 강제 스파인 업데이트 진행
	statue_nari.SpineController:ForceUpdateSpines(0)
	statue_garam.SpineController:ForceUpdateSpines(0)

	if q ~= nil and q.InnerProgress <= 23 and q.InnerProgress >=22 and not q.IsComplete then
		self:run_tint_loop()

		return true
	end
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')

	self.cs_controller = nil
end

-- 깜빡이는 틴트, 카메라 쉐이크
function local_class:tint_loop()
	local duration = 2

	while self.tint_loop_stat do
		camera_util.shake(0.02, duration)
		music_player_util.play_sfx({sfx_name = '01_earthquake_02'})
		music_player_util.play_sfx({sfx_name = '03_teatan_robot_emerge_01'})
		field:Tint('tint_loop', unity_color({1.0, 0.5, 0.5, 1}), duration)
		wait_for_sec(2.5)
		field:RemoveTint('tint_loop', duration)
		wait_for_sec(2.5)
	end
end

function local_class:run_tint_loop()
	if self.tint_loop_stat then
		return
	end
	self.tint_loop_stat = true
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.tint_loop, self))
end

function local_class:stop_tint_loop()
	self.tint_loop_stat = false
end

function local_class:on_event(e)
	local fox_main_quest_id = 60009
	local q = user_progress:GetStartedQuest(fox_main_quest_id)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) and e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party.Leader) then

		if e.Zone.Name == 'BATTLE_2' then

			if q.InnerProgress == 22 or self.battle_2_event_open then
				return false
			end

			self.battle_2_event_open = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, true, 2, 4))


		elseif e.Zone.Name == 'BATTLE_4' then
			if q.InnerProgress == 23 then
				self:stop_tint_loop()
				return false
			end

		end

	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then

		if e.BattleGroupName == "BATTLE_2" then
			if not q.IsComplete and not self.battle_2_event_open then
				self.battle_2_event_open = true
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.gate_manual_controll, self, false, 2, 4))
		end

	end


	return false
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

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
