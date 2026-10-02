local local_class = newclass('HellForest3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version
end

function local_class:load_resource()
	--region Init Stomping LivingArmor

	--- 연출용 골렘 캐릭터들
	self.living_armor_fos = {
		get_character('livingarmor_1'),
		get_character('livingarmor_2'),
		get_character('livingarmor_3'),
		get_character('livingarmor_4'),
	}

	-- 그리드 체크 및 효과음 출력될 때 사용할 위치
	self.grid_check_position = vector_util.lerp(self.living_armor_fos[1].Bounds.center, self.living_armor_fos[4].Bounds.center, 0.5)

	-- 그리드 처리
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_grid_leave_event')

	--endregion Init Stomping LivingArmor

	--region Init MasterBlade

	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	--endregion Init MasterBlade

	--region Init Door Open Key

	--- 마지막 문을 여는 열쇠
	self.target_door_key = get_field_object('04_key')
	-- 문 열리는 이벤트 체크 (키 활성화 용도)
	message_system:Subscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_door_opened_event')

	--endregion Init Door Open Key
end

function local_class:dispose()
	self.cs_controller = nil

	--region Dispose Stomping LivingArmor

	-- 그리드 처리 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_grid_enter_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_grid_leave_event')

	--endregion Dispose Stomping LivingArmor

	--region Dispose MasterBlade

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')

	--endregion Dispose MasterBlade

	--region Dispose Door Open Key

	-- 문 여는 이벤트 체크 해제 (키 활성화 용도)
	message_system:Unsubscribe(self, typeof(CS.Oak.DoorOpenedEvent), 'on_door_opened_event')

	--endregion Dispose Door Open Key
end

--region Stomping LivingArmor

function local_class:on_grid_enter_event(e)
	-- 이미 해제된 뒤라면 생략
	if not self.cs_controller then return false end
	-- 조작중인 리더 외에는 체크할 필요가 없다.
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return false end
	-- 그리드에 포함된 위치가 아니면 생략
	if not e.CameraGrid:Contains(self.grid_check_position) then return false end

	-- 애니 설정
	for idx = 1, #self.living_armor_fos do
		local target = self.living_armor_fos[idx]

		-- 첫번쨰 대상만 사운드 출력하도록 함
		if idx == 1 then
			local sfx_callback_func = function(_, spine_event)
				-- 이미 해제된 뒤라면 생략
				if not self.cs_controller then return end
				-- 효과음 키 검증
				if spine_event.Data.Name ~= 'sfx' then return end

				music_player_util.play_sfx({
					sfx_name = '03_mech_stomp_02',
					play_pos = self.grid_check_position,
					loop = false,
					min_distance = 4,
					max_distance = 6
				})
			end

			character_util.set_anim(target, {
				name = 'stomp',
				loop = true,
				sfx_callback = sfx_callback_func
			})

		-- 나머지는 단순 애니만 출력
		else
			character_util.set_anim(target, {
				name = 'stomp',
				loop = true,
			})
		end
	end

	return true
end

function local_class:on_grid_leave_event(e)
	-- 이미 해제된 뒤라면 생략
	if not self.cs_controller then return false end
	-- 조작중인 리더 외에는 체크할 필요가 없다.
	if not lua_helper.reference_equals(e.FieldObject, get_party_leader()) then return false end
	-- 그리드에 포함된 위치가 아니면 생략
	if not e.CameraGrid:Contains(self.grid_check_position) then return false end

	for idx = 1, #self.living_armor_fos do
		local target = self.living_armor_fos[idx]

		-- 붙여두었던 애니 해제
		character_util.remove_anim(target)
	end

	return true
end

--endregion Stomping LivingArmor

function local_class:on_stage_loaded_event(e)
	-- 이미 해제된 뒤라면 생략
	if not self.cs_controller then return false end

	--region MasterBlade

	-- 부셔진 마스터블레이드 처리
	-- 어처피 먹지 않을거고 계속 배치되있을 것이라 그냥 인스턴스 캐싱은 생략한다..
	drop_item_util.create_item({
		pos = field_util.get_marker_pos('05_master_blade'),
		-- broken_master_blade
		itemid = 20106,
		notforinven = true,
		lootstate = 'dontfindlooter'
	})

	--endregion MasterBlade

	--region Door Open Key

	--- 설정되있던 홀더블을 캐싱한다.
	--- pool로 관리되던 객체가 아니라 그냥 캐싱해도 무방함
	self.cached_holdable = self.target_door_key.Holdable
	--- 들 수 없도록 NonHolable 할당
	self.target_door_key.Holdable = CS.Oak.NonHoldable.Instance

	--endregion Door Open Key
end

--endregion MasterBlade

--region Door Open Key

function local_class:on_door_opened_event(e)
	-- 이미 해제된 뒤라면 생략
	if not self.cs_controller then return false end
	-- 이미 열린 뒤면 체크 생략
	if self.is_cleared then return false end
	-- 열린 문이 02_door인지 체크
	if e.DoorHandleName ~= '02_door' then return false end

	--- 02_door과 이름이 같으면 클리어 처리
	self.is_cleared = true
	-- 홀더블 복구
	self.target_door_key.Holdable = self.cached_holdable
	return true
end

--endregion Door Open Key

return local_class
