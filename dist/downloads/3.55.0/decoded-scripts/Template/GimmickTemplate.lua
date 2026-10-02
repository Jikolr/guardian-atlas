local local_class = newclass("ClassName")

--- 생성자
--- @param data_path string 해당 기믹이 사용할 Data의 경로.
--- @param data_key string 해당 기믹이 사용할 Data의 Key.
--- @param cs_behaviour any 해당 기믹의 C# Behaviour.
function local_class:init(data_path, data_key, cs_behaviour)
	self.cs_behaviour = cs_behaviour

	-- 데이터가 필요할 경우 아래 주석을 풀고 사용하면 된다.
	-- 데이터 사용 방법은 Confluence 참고
	--local data = load_util.load_lua_gimmick_data(data_path, data_key)
	--self.value = data['value_name']
end

-- IFO에 붙었을 때
function local_class:attach_to(fo)
	self.fo = fo
end

-- IFO에서 떨어졌을 때
function local_class:detach_from(fo)
end

-- 현재 기본 스테이트 얻기(아이들, 걷기 등 전신 및 하체 상태)
function local_class:current_state()
	return nil
end

-- 현재 IFO가 취하고 있는 액션
function local_class:current_action()
	return CS.Oak.FieldObjectAction.None
end

-- 업데이트. attach_to가 불린 시점부터 detach_from 이 불린 시점까지 매 프레임 불린다.
function local_class:update_frame(dt)
end

-- 이벤트 호출
function local_class:on_event(e)
	return false
end

--- Behaviour에 있는 StateMachine의 State를 변경
function local_class:change_state(next_state)
	self.cs_behaviour:ChangeState(next_state)
end

--- LuaMessageSystem(message_system)을 이용하여 콜백을 등록하였을 경우 이 곳에서 해제하여야 한다.
--- detach_from의 경우 LuaMessageSystem이 이미 날아간 상태이기 때문에 Leak발생함.
function local_class:dispose()
	self:change_state()
end

return {
	create = function(data_path, data_key, cs_behaviour)
		return local_class(data_path, data_key, cs_behaviour)
	end
}
