local local_class = newclass("SubStageSnowDragonController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.scene = scene()

	self.dovakin_name = 'dragon_otaku'
	self.ddong_name = 'ddong'

	self.dragon_scale_item_name = 'dragon_scale'

	self.is_saw_dovakin_event = false
	self.is_saw_jump_event = false
	self.is_saw_smell_event = false
	self.is_enter_smell_1_zone = false
	self.is_enter_smell_2_zone = false
	self.is_enter_smell_3_zone = false
	self.is_enter_can_zone = false
	self.dovakin_talk_flag = false

	self.scale_item_list = nil

	self.prev_audio_source_holder = nil

	self.coroutine = nil

	self.saw_dovakin_state = 0
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	local dovakin = get_character(self.dovakin_name)
	local ddong = get_character(self.ddong_name)

	-- ddong의 레벨을 안보이게 처리
	field_ui_manager:RemoveUI(ddong, CS.Oak.FieldUiType.CharacterStats)
	ddong.transform.localScale = unity_class.vector3.one * 2

	self.is_saw_dovakin_event = stage_progress:GetCustomData(self.saw_dovakin_state)

	if self.is_saw_dovakin_event == true then
		character_util.set_active_state(dovakin, 'disabled')
		character_util.set_active_state(ddong, 'disabled')
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.scene.Setting3_4, self.scene))

		self.scene:add_callback('DovakinFall', { controller = self, func = self.DovakinFall })
		self.scene:add_callback('DovakinHold', { controller = self, func = self.DovakinHold })
		self.scene:add_callback('DovakinReset', { controller = self, func = self.DovakinReset })
		self.scene:add_callback('DovakinCrashEthereal', { controller = self, func = self.DovakinCrashEthereal })
		self.scene:add_callback('DovakinGetEmptyCan', { controller = self, func = self.DovakinGetEmptyCan })
		self.scene:add_callback('PlaySfx', { controller = self, func = self.PlaySfx })
		self.scene:add_callback('StopSfx', { controller = self, func = self.StopSfx })
	end
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local dovakin = get_character(self.dovakin_name)
	if lua_helper.type_compare(dovakin.Interactable, CS.Oak.NPCInteractable) then
		dovakin.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.scale_item_list = nil

	self.prev_audio_source_holder = nil

	self.coroutine = nil

	self.cs_controller = nil
	self.scene = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	-- 도바킨 소녀 이벤트를 봤었다면 아무것도 하지않는다.
	if self.is_saw_dovakin_event == true then
		return false
	end

	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		if e.FullLeave == true and e.FieldObject == user_party_leader and e.Zone.Name == 'cave' then
		end
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	if self.is_saw_dovakin_event == true then
		return
	end

	self:dropEventItem()
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == true and e.FieldObject == user_party_leader then
		if e.Zone.Name == 'event1' and self.is_saw_jump_event == false then
			self.is_saw_jump_event = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.DovakinJump, self))
		elseif e.Zone.Name == 'cave' then
		elseif e.Zone.Name == 'smell_1' and self.is_enter_smell_1_zone == false then
			self.is_enter_smell_1_zone = true
			self.coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.DovakinSmell, self))
		elseif e.Zone.Name == 'smell_2' and self.is_enter_smell_2_zone == false then
			self.is_enter_smell_2_zone = true
		elseif e.Zone.Name == 'smell_3' and self.is_enter_smell_3_zone == false then
			self.is_enter_smell_3_zone = true
		elseif e.Zone.Name == 'can' and self.is_enter_can_zone == false then
			self.is_enter_can_zone = true

			if self.is_saw_smell_event == false then
				stop_coroutine(self.coroutine)
				self.coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.SkipDovakinMove, self))
			end
		end
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == 'battle3' then
		local ddong = get_character(self.ddong_name)
		ddong.Interactable:AddListener(self.cs_controller)
	end
end

function local_class:on_interact_event(e)
	local dovakin = get_character(self.dovakin_name)
	local ddong = get_character(self.ddong_name)

	if lua_helper.reference_equals(e.Target, dovakin) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.DovakinHappy, self))
	elseif lua_helper.reference_equals(e.Target, ddong) then
		stop_coroutine(self.coroutine)
		sp_util.play_normal_screenplay(self.DovakinRun, self)
	end
end

function local_class:dropEventItem()
	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec(self.dragon_scale_item_name).Id

	self.scale_item_list = {}
	table.insert(self.scale_item_list, drop_item_util.create_item({ pos = vector(50, 0, -52), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' }))
	table.insert(self.scale_item_list, drop_item_util.create_item({ pos = vector(53, 0, -52), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' }))
	table.insert(self.scale_item_list, drop_item_util.create_item({ pos = vector(53, 0, -49), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' }))
	table.insert(self.scale_item_list, drop_item_util.create_item({ pos = vector(50, 0, -49), itemid = item_id, notforinven = true, lootstate = 'dontfindlooter' }))
end

function local_class:DovakinRun()
	local ddong = get_character(self.ddong_name)

	for i = 1, 4 do
		self:DovakinGetEmptyCan(i)
	end

	self:StopSfx()

	party_util.align_party(ddong, 'down', 1, 'arc')

	ddong.Holdable = CS.Oak.Holdable()
	yield_return(self.scene, "dovakinRun")
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('dragon_door', false))
	stage_progress:SendCustomData(self.saw_dovakin_state, true)
end

function local_class:DovakinJump()
	yield_return(self.scene, "dovakinJump")
end

function local_class:DovakinFall()
	local fall_time = 1.2
	local dovakin = get_character(self.dovakin_name)

	dovakin.SpineController.IsShadowActive = false
	dovakin.SpineController:Rotate(1080, fall_time)
	dovakin.SpineController:Scale(unity_class.vector3.zero, fall_time)

	wait_for_sec(fall_time)
end

function local_class:DovakinSmell()
	yield_return(self.scene, 'dovakinSmell')
	yield_return(self.scene, 'dovakinSmell_1')

	while not self.is_enter_smell_2_zone do
		coroutine.yield(nil)
	end

	yield_return(self.scene, 'dovakinSmell')
	yield_return(self.scene, 'dovakinSmell_2')

	while not self.is_enter_smell_3_zone do
		coroutine.yield(nil)
	end

	yield_return(self.scene, 'dovakinSmell')
	yield_return(self.scene, 'dovakinSmell_3')

	self.is_saw_smell_event = true

	yield_return(self.scene, 'dovakinEnterGridCan_1')

	while not self.is_enter_can_zone do
		coroutine.yield(nil)
	end

	yield_return(self, 'DovakinEmptyCan')
end

function local_class:DovakinEmptyCan()
	yield_return(self.scene, 'dovakinGetCan')

	local dovakin = get_character(self.dovakin_name)
	dovakin.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance
	dovakin.Interactable:AddListener(self.cs_controller)
end

function local_class:SkipDovakinMove()
	yield_return(self.scene, 'dovakinEnterGridCan_2', true)
	yield_return(self, 'DovakinEmptyCan')
end

function local_class:DovakinGetEmptyCan(index)
	local dovakin = get_character(self.dovakin_name)

	if self.scale_item_list[index] ~= nil then
		self.scale_item_list[index].ConsumeTarget = dovakin
		self.scale_item_list[index]:Fly()
		self.scale_item_list[index] = nil
	end
end

function local_class:DovakinHappy()
	local dovakin = get_character(self.dovakin_name)

	if self.dovakin_talk_flag == true then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.scene.dovakinHappy_1, self.scene))
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.scene.dovakinHappy_2, self.scene))
	end

	self.dovakin_talk_flag = not self.dovakin_talk_flag
end

function local_class:DovakinHold()
	local dovakin = get_character(self.dovakin_name)
	local ddong = get_character(self.ddong_name)

	command_util.execute_holdup(dovakin, ddong, dovakin.Position)

	wait_for_sec(0.5)
end

function local_class:DovakinReset()
	local dovakin = get_character(self.dovakin_name)

	dovakin.SpineController:Scale(unity_class.vector3.one, 0)
	dovakin.SpineController:Rotate(0, 0)
	dovakin.SpineController.IsShadowActive = true
end

function local_class:PlaySfx(data)
	local sfx_name = lua_helper.get_value(data, 'sfx_name')
	local target_name = lua_helper.get_value(data, 'target')
	local target = get_character(target_name)

	self.prev_audio_source_holder = music_player_util.play_sfx({ sfx_name = sfx_name, parent = target, player_priority = 'npc' })
end

function local_class:StopSfx()
	if self.prev_audio_source_holder ~= nil then
		self.prev_audio_source_holder:Stop()
		self.prev_audio_source_holder = nil
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
