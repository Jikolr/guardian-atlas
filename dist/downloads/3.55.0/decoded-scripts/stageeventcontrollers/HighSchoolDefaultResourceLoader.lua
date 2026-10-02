local local_class = newclass("HighSchoolDefaultResourceLoader")

--- 라이브 이벤트 하이스쿨에서만
--- 공용으로 사용 하는 리소스들은 여기서 로드 및 해제 하도록

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	-- Rolling Number 리소스를 여기서 로드 한다.
	local pool = unity_object_pool.GetOrCreate('rolling_number')

	-- pool 이 이미 로드 됐으면 리턴 처리 (한번은 꼭 로드 되도록)
	if pool ~= nil and pool.State == CS.Oak.UnityObjectPoolState.Loaded then
		return
	end

	coroutine.yield(unity_object_pool.WaitUntilLoaded(pool))
end

function local_class:need_on_launch()
	return false
end

function local_class:dispose()
	CS.Oak.RollingNumberManager.Instance:ReturnRollingNumberAll();
	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
