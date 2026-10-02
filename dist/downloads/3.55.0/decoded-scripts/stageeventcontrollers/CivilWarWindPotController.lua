local local_class = newclass('CivilWarWindPotControllerController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	CS.Oak.WindPotManager.Init()
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	yield_return_func(CS.Oak.WindPotManager.LoadAll)
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	CS.Oak.WindPotManager.Dispose()

	self.cs_controller = nil
	self.scene = nil
end

function local_class:on_stage_start_event(e)
	--self:set_button()
	return true
end

function local_class:on_battle_start_event(e)
	CS.Oak.WindPotManager.SetActive(false)
	--self:set_button_active_state(false)
	return true
end

function local_class:on_battle_end_event(e)
	CS.Oak.WindPotManager.SetActive(true)
	--self:set_button_active_state(true)
	return true
end

--function local_class:set_button()
--	local ui_type = CS.Oak.FieldUiType.CustomButton1
--
--	field_ui_manager:SetUI(user_party.Leader, ui_type)
--
--	self.button = field_ui_manager:GetUI(user_party.Leader)[ui_type]
--	self.button:SetIcon('actbtn_ic_act_android.png')
--	self:set_button_active_state(true)
--
--	message_system:Publish(CS.Oak.FieldUICustomButtonEvent.Create(true))
--end
--
--function local_class:set_button_active_state(active)
--	if active then
--		-- 버튼 킴
--		--self.button_active = true
--		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.CustomButton1, user_party.Leader)
--	else
--		-- 버튼 끔
--		--self.button_active = false
--		field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.CustomButton1, user_party.Leader)
--	end
--end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
