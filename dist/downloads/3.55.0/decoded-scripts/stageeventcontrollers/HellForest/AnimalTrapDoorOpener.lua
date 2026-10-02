local local_class = newclass('HellForestAnimalTrapDoorOpener')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	--- 데이터 테이블 로드
	local controller_data = get_or_create_global_variable('stageeventcontrollers/HellForest/AnimalTrapDoorOpenerData')
	--- 현재 스테이지에서 적용될 데이터
	local current_stage_info = controller_data[stage.Name]
	--- 피탄자 체크를 위한 헤시셋 목록
	self.condition_targets_list = {}
	--- 조건 성립 시 열릴 문 정보
	self.target_door_info_list = {}

	-- 순회
	for _, pattern in pairs(current_stage_info.patterns) do
		table.insert(self.condition_targets_list, create_lua_hashset(table.unpack(pattern.condition_targets)))

		local door_info = {
			target_doors = pattern.target_doors,
			camera_marker = pattern.camera_marker,
			camera_move_duration = pattern.camera_move_duration,
			door_open_duration = pattern.door_open_duration,
		}
		table.insert(self.target_door_info_list, door_info)
	end
end

function local_class:load_resource()
	-- 피격 이벤트 체크
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
end

function local_class:dispose()
	self.cs_controller = nil

	-- 피격 이벤트 처리 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
end

function local_class:on_damage_event(e)
	-- 이미 해제된 뒤라면 생략
	if not self.condition_targets_list or #self.condition_targets_list == 0 then return false end

	--- 데미지 인포 캐싱
	local damage_info = e.Info
	--- 부여자 캐싱
	local sender = damage_info.sender
	-- 부여자가 유효치 않거나 동물트랩이 아니라면 체크할 가치가 없다.
	if not sender or not lua_helper.type_compare(sender.FieldObjectBehaviour, CS.Oak.AnimalTrapBehaviour) then return false end

	--- 피격자 캐싱
	local target = damage_info.target
	--- 피격자 이름 캐싱
	local target_name = target.Name

	-- 성립한 것들은 날려버릴 것이지만, 한번 체크하면 break할 것이라 굳이 역순으로 하지 않는다.
	for idx = 1, #self.condition_targets_list do
		-- 해시셋에 변화를 주었다면 체크한다.
		if self.condition_targets_list[idx]:remove(target_name) then
			-- 조건을 성립했는지 체크한다.
			self:check_and_proccess_condition(idx)

			-- 조건에 영향을 주었기 때문에 바로 이탈
			break
		end
	end
end

function local_class:check_and_proccess_condition(idx)
	-- 남은 조건이 있다면 이해 처리는 생략한다.
	if not #self.condition_targets_list[idx] == 0 then
		return
	end

	-- 해제한다.
	table.remove(self.condition_targets_list, idx)
	--- 열릴 문들에 대한 정보를 가져옴
	local door_info = table.remove(self.target_door_info_list, idx)

	-- 문 여는 연출 처리
	sp_util.start_scene(self.door_open_routine, self, door_info)
end

function local_class:door_open_routine(door_info)
	local door_list = door_info.target_doors
	local camera_marker = door_info.camera_marker
	local camera_move_duration = lua_helper.get_value(door_info, 'camera_move_duration', 1)
	local door_open_duration = lua_helper.get_value(door_info, 'door_open_duration', 2)

	camera_util.move_async(field_util.get_marker_pos(camera_marker), camera_move_duration)

	-- 연관된 모든 문을 열어준다.
	for _, door_name in pairs(door_list) do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(door_name, false))
	end

	wait_for_sec(door_open_duration)

	camera_util.return_to_leader(camera_move_duration)
end

return local_class
