local local_class = newclass("NightmareChina1At6Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()

	local inner_door = get_field_object('main_door')
	inner_door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	local animator = inner_door:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play("gate_open", -1)
	return
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	local main_progress = user_progress:GetStartedQuest(93)
	return ( main_progress.InnerProgress == 9 and not user_progress:ClearedQuest(93) )
			or ( main_progress.InnerProgress == 8 and main_progress:GetCustomState('saw_boss_intro') == 1)
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