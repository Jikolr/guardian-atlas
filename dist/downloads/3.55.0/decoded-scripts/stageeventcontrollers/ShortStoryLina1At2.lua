local local_class = newclass("ShortStoryLina1At2")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.sections_need_on_launch = {
		0,
		1,
		2,
		3,
		4,
		5,
		6,
		7
	}
end

function local_class:stage_load_resource()
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local qp = user_progress:GetStartedQuest(7000901)

	if user_progress:ClearedQuest(7000901) then
		return false
	end

	-- pre section
	if qp == nil or qp.InnerProgress < 0 then
		return true
	else
		-- 1, 2, 4, 6  섹션
		for _, section in ipairs(self.sections_need_on_launch) do
			if qp.InnerProgress == section then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
