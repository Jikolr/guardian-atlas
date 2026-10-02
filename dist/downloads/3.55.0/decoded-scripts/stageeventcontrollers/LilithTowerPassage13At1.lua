local local_class = newclass("LilithTowerPassage13At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name = 'passage_13_1'

	self.is_exit_stage = false

	-- CCTV
	self.cctv_name = 'cctv_'
	self.cctv_num = 3
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cctv_event, self))
end

-- CCTV 처리
function local_class:cctv_event()
	local cctv_list = create_generic_list(CS.Oak.FieldObject)
	for i = 1, self.cctv_num do
		local cur_cctv = get_field_object(self.cctv_name..i)

		-- 파티클 시스템 언제나 업데이트하도록 수정
		local cur_particle_system = cur_cctv.transform:GetChild(0):GetComponentInChildren(typeof(CS.UnityEngine.ParticleSystem))
		cur_particle_system.main.cullingMode = CS.UnityEngine.ParticleSystemCullingMode.AlwaysSimulate

		cctv_list:Add(cur_cctv)
	end

	local timer = 0
	local duration = 2
	local is_on = true

	while not self.is_exit_stage do
		timer = timer + unity_class.time.deltaTime

		if timer >= duration then
			timer = 0

			if is_on then
				is_on = false

				for i = 0, cctv_list.Count - 1 do
					message_system:Publish(CS.Oak.CustomStageEvent.Create(
							get_party_leader(), { self.cctv_name..(i+1), 'cctv_off' }))
				end
			else
				is_on = true

				for i = 0, cctv_list.Count - 1 do
					message_system:Publish(CS.Oak.CustomStageEvent.Create(
							get_party_leader(), { self.cctv_name..(i+1), 'cctv_on' }))
				end
			end
		end

		coroutine.yield(nil)
	end
end

function local_class:dispose()
	self.is_exit_stage = true

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}