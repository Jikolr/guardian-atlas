local local_class = newclass('HellForest2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
	--region Init GoblinThief Respawn

	--- 실제 동작하는 고블린
	self.goblin = get_character('goblin_thief')
	--- 연출용 고블린
	self.goblin_for_screenplay = get_character('goblin_thief_fake')
	-- 연출용 고블린은 필드에 판정되지도, 암살되지도 않게 하기 위해서 visible로 설정해둔다.
	character_util.set_active_state(self.goblin_for_screenplay, 'visible')

	--- 리스폰 위치
	self.respawn_position = self.goblin.Position
	--- 연출 시작 위치
	self.screenplay_start_position = self.goblin_for_screenplay.Position
	--- 연출용 고블린이 바라볼 위치
	self.screenplay_start_direction = self.goblin_for_screenplay.Direction
	--- 고블린 바꿔치기 후 등장할 위치
	self.screenplay_appear_position = field_util.get_marker_pos('goblin_thief_pre_spawn')

	-- 문 열리는 이벤트 체크 (동작 필터 용도)
	message_system:Subscribe(self, typeof(CS.Oak.DoorOpenEvent), 'on_door_open_event')
	-- 사망 연출 완료 이벤트 체크
	message_system:Subscribe(self, typeof(CS.Oak.NormalDyingEndEvent), 'on_normal_dying_end_event')

	--endregion Init GoblinThief Respawn

	--region Init Burning SignBoard

	--- 체크할 사인보드
	self.burning_sign_board = get_field_object('starpiece_signboard')
	--- 불 붙은 상태인지 체크하기 위한 플래그
	self.is_burning = false

	-- 불타는 이벤트 체크 (불 타오를때 처리)
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	-- 인터렉트 이벤트 체크 (말풍선 출력 처리)
	message_system:Subscribe(self, typeof(CS.Oak.BurnEvent), 'on_burn_event')

	--endregion Init Burning SignBoard
end

function local_class:dispose()
	self.cs_controller = nil

	--region Dispose GoblinThief Respawn

	-- 문 여는 이벤트 체크 해제 (동작 필터 용도)
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenEvent), 'on_door_open_event')
	-- 사망 연출 완료 이벤트 처리 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.NormalDyingEndEvent), 'on_normal_dying_end_event')

	--endregion Dispose GoblinThief Respawn

	--region Dispose Burning SignBoard

	-- 불타는 이벤트 체크 해제 (불 타오를때 처리)
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	-- 인터렉트 이벤트 체크 해제 (말풍선 출력 처리)
	message_system:Unsubscribe(self, typeof(CS.Oak.BurnEvent), 'on_burn_event')

	--endregion Dispose Burning SignBoard
end

--region GoblinThief Respawn

function local_class:on_door_open_event(e)
	-- 이미 해제된 상태라면 생략
	if not self.cs_controller then return false end

	-- 이미 열린 상태면 체크 생략
	if self.is_cleared then return false end

	-- 05_door과 이름이 같으면 클리어 처리
	self.is_cleared = e.DoorHandleName == '05_door'

	return true
end

function local_class:on_normal_dying_end_event(e)
	-- 이미 해제된 상태라면 생략
	if not self.cs_controller then return false end

	if lua_helper.reference_equals(self.goblin, e.character) then
		start_coroutine(self.respawn_routine, self)
	end

	return true
end

function local_class:respawn_routine()
	-- 딜레이
	wait_for_sec(1)

	-- 사이 동안에 클리어 했다면 이탈한다.
	if self.is_cleared then return end

	-- 딜레이
	wait_for_sec(1)

	-- 연출용 고블린이 점프하며 이동
	character_util.jump_move(self.goblin_for_screenplay, self.respawn_position, 5, 1)

	-- 고블린 위치 설정
	character_util.set_position(self.goblin, self.respawn_position)
	-- 부활 처리
	local heal_info = CS.Oak.HealInfo()
	heal_info.type = CS.Oak.HealType.Normal
	heal_info.heal = self.goblin.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true
	heal_info.sender = self.goblin
	heal_info.target = self.goblin
	heal_info.skipEffect = true
	command_util.publish_heal(heal_info)
	--- 켜줌
	character_util.set_active_state(self.goblin, 'enabled')

	-- 화면 밖에서 들어오게 함
	character_util.set_position(self.goblin_for_screenplay, self.screenplay_appear_position)

	-- 연출용 고블린 대기 위치로 이동
	character_util.move_to_async(self.goblin_for_screenplay, self.screenplay_start_position, nil, 5)

	-- 연출용 고블린 최종 위치 설정
	character_util.set_position(self.goblin_for_screenplay, self.screenplay_start_position)
	-- 연출용 고블린 최종 방향 설정
	character_util.set_direction(self.goblin_for_screenplay, self.screenplay_start_direction)
end

--endregion GoblinThief Respawn

--region Burning SignBoard

function local_class:on_interact_event(e)
	-- 이미 해제된 상태라면 생략
	if not self.cs_controller then return false end
	-- 사인보드가 아니면 생략한다.
	if not lua_helper.reference_equals(e.Target, self.burning_sign_board) then return false end

	-- 불에 붙어있는 상태에 따라 분기
	if self.burning_sign_board.CombustibleBehaviour.IsBurning then
		speech_bubble_util.show_speech_bubble(self.burning_sign_board, {
			key = 'forest_1_3_signboard_after', skip = false
		})
	else
		speech_bubble_util.show_speech_bubble(self.burning_sign_board, {
			key = 'forest_1_3_signboard_before', skip = false
		})
	end
end

function local_class:on_burn_event(e)
	-- 이미 해제된 상태라면 생략
	if not self.cs_controller then return false end
	-- 이미 타고 있으면 생략한다.
	if self.is_burning then return false end
	-- 사인보드가 아니면 생략한다.
	if not lua_helper.reference_equals(e.Target, self.burning_sign_board) then return false end

	-- 갱신
	self.is_burning = self.burning_sign_board.CombustibleBehaviour.IsBurning

	-- 타오르기 시작하면 스피치 발생
	if self.is_burning then
		speech_bubble_util.show_speech_bubble(self.burning_sign_board, {
			key = 'forest_1_3_signboard_burn', skip = false
		})
	end

	return true
end

--endregion Burning SignBoard

return local_class
