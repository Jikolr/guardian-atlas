local local_class = newclass('HellForestCameraSizeChanger')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--- 데이터 테이블 로드
	local controller_data = get_or_create_global_variable('stageeventcontrollers/HellForest/CameraSizeChangerData')
	--- 현재 스테이지에서 적용될 데이터
	self.current_stage_info = controller_data[stage.Name]
end

function local_class:load_resource()
	-- 존 이벤트 구독
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:dispose()
	self.cs_controller = nil

	-- 존 이벤트 구독 취소
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:on_zone_enter_event(e)
	-- 해제된 뒤면 생략
	if not self.cs_controller then return false end
	--- 존 이름 캐싱
	local zone_name = e.Zone.Name
	-- 존 이름이 할당되있던 것과 같다면 체크할 필요가 없다.
	if self.current_zone_name == zone_name then return false end
	-- 체크가 필요한 존인가 체크
	if not self.current_stage_info[zone_name] then return false end
	-- 존에 진입을 한 상태인가 체크
	if not lua_helper.reference_equals(e.FieldObject, party_manager.UserParty.Leader) then return false end

	-- 카메라 사이즈 변경
	camera_util.resize_to(self.current_stage_info[zone_name], 1)
	--- 현재 설정된 존 명칭
	self.current_zone_name = zone_name

	return true
end

function local_class:on_zone_leave_event(e)
	-- 해제된 뒤면 생략
	if not self.cs_controller then return false end
	-- 나간놈이 리더인가 체크
	if not type_util.is_zone_full_leave(e, party_manager.UserParty.Leader, self.current_zone_name) then return false end

	-- 카메라 사이즈 초기화
	camera_util.resize_to_default(1)
	--- 현재 설정된 존 명칭 해제
	self.current_zone_name = nil

	return true
end

return local_class
