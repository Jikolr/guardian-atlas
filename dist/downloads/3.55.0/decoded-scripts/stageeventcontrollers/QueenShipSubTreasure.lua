local local_class = newclass('QueenShipSubTreasure')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
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

function local_class:on_stage_loaded_event(e)
	-- 기사를 리더로
	local leader

	if user_util.has_knight_male() then
		leader = get_character('knight_male')
	else
		leader = get_character('knight_female')
	end

	character_util.set_active_state(leader, 'enabled')
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	character_util.convert_to_manual_character(leader, param, true)

	-- 공주 파티원으로 추가
	local princess = get_character('princess')
	character_util.set_active_state(princess, 'enabled')
	character_util.convert_to_party_member(princess, user_party, true)
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
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	self.cs_controller = nil
	self.scene = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}