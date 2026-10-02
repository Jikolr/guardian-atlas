local local_class = newclass("NightmareChina1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	local burning_skull = get_character("romance_2")
	local burning_sign = get_field_object("burning_sign")
	burning_sign.CombustibleBehaviour = CS.Oak.CombustibleBehaviour()
	command_util.execute_burn(burning_skull, burning_sign, true)

	for i = 1, 36 do
		local dummy = get_field_object('dummy' .. i)
		dummy.EntityGroup = CS.Oak.EntityGroups.Enemy
		local dummy_spec = CS.Oak.FieldObjectSpec()
		local calc_spec = CS.Oak.LuaScriptQuestUtil.SetFieldObjectSpecHpBase(dummy_spec, 2000)
		dummy.FieldObjectStatsBehaviour.FieldObjectSpec = calc_spec
		field_ui_manager:SetUI(dummy, CS.Oak.FieldUiType.CharacterStats)
	end

	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	return user_progress:GetStartedQuest(93).InnerProgress == 3
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}