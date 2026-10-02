local local_class = newclass('HellForestRegisterNoAssassination')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--- 데이터 테이블 로드
	local controller_data = get_or_create_global_variable('stageeventcontrollers/HellForest/RegisterNoAssassinationData')
	--- 현재 스테이지에서 적용될 데이터
	self.current_stage_info = controller_data[stage.Name]
end

function local_class:load_resource()
	-- 피격 이벤트 체크
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:dispose()
	self.cs_controller = nil

	-- 피격 이벤트 처리 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_stage_loaded_event(e)
	--- 모든 대상 순회
	for _, name in pairs(self.current_stage_info.target_characters) do
		local target = get_character(name)

		-- 대상이 있다면 암살 불가 대상에 추가해둔다.
		if target then
			stage.BattleManager:AddToNoAssassination(target)
		end
	end
end

return local_class
