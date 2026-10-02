local local_class = newclass("HighSchool1At2Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	if scene ~= nil then
		self.scene = scene()
	end

	-- 더미 트레이닝 프롤로그 패러디 이벤트

	-- 트레이닝 이벤트가 실행되는 더미
	self.player_dummy = nil

	-- 트레이닝 이벤트를 실행하는 더미 이름
	self.player_dummy_name = "player_dummy"

	-- 더미가 움직이고 있는지 저장
	self.dummy_is_move = false

	-- 기타 더미 개수
	self.dummy_num = 5

	-- 기타 더미 이름
	self.dummy_name = "dummy_"

	-- 더미 치는 NPC 수
	self.training_kendo_student_num = 5

	-- 더미 치는 NPC 이름
	self.training_kendo_student_name = "training_kendo_student_"

	-- 트레이닝 룸 카메라 그리드
	self.training_room_grid_name = 'training_room_grid'

	-- 지각 NPC 이름
	self.late_kendo_student_name = "training_kendo_student_late"

	-- 더미 훈련 리더 NPC 이름
	self.training_kendo_leader_name = "training_kendo_leader"

	-- TypingText 애셋 번들 이름
	self.typing_text_asset_bundle_name = "ui/prologue"

	-- TypingText 애셋 이름
	self.typing_text_asset_name = "typing_text"

	-- 더미 트레이닝 이벤트가 벌어지는 존 이름
	self.training_room_event_zone_name = "training_room"

	-- 더미 트레이닝 이벤트를 보았는지 저장
	self.see_training_room_event = false

	-- 더미 트레이닝 존에 들어갔는지 저장
	self.enter_training_room = false

	-- 플레이어가 더미에 상호작용할 때까지 이벤트가 중단되었는지
	self.wait_for_player = false

	-- 플레이어가 위치하면 이벤트가 진행되는 존 이름
	self.training_room_player_zone_name = "training_room_player_zone"

	-- 플레이어가 더미 앞에 도달한 뒤의 더미 트레이닝 이벤트를 보았는지
	self.see_training_room_player_event = false

	-- 더미 트레이닝 이벤트가 끝나면 등장하는 스타피스
	-- 더미 트레이닝 이벤트가 종료되었는지 확인하는 플래그로도 사용
	self.training_room_star_piece_name = "training_room_star_piece"



	-- 검도부 전투 이벤트

	-- 몬스터로 변하는 검도부원 NPC 이름
	self.battle_kendo_student_name = "battle_kendo_student_"

	-- 몬스터로 변하는 검도부원 NPC 수
	self.battle_kendo_student_num = 6

	-- 검도부원들이 달려가는 이벤트가 벌어지는 존 이름
	self.kendo_staff_member_run_zone_name = "kendo_staff_member_run"

	-- 검도부원들이 달려가는 이벤트를 보았는지
	self.see_kendo_staff_member_run_event = false

	-- 검도부원들과 전투하는 이벤트가 벌어지는 존 이름
	self.kendo_staff_member_battle_zone_name = "kendo_staff_member_battle"

	-- 검도부원들이 전투하는 이벤트를 보았는지
	self.see_kendo_staff_member_battle_event = false

	-- 검도부원들 Battle Group 이름
	self.kendo_staff_battle_group_name = "kendo_staff"

	-- 검도부 전투 이벤트의 배틀게이트 이름
	self.kendo_staff_battle_gate_name = "kendo_student_battlegate_"

	-- 검도부 전투 이벤트의 배틀게이트 수
	self.kendo_staff_battle_gate_num = 6



	-- 핫토리 한조 검 이벤트

	-- 핫토리 한조 NPC
	self.hattori_hanzo = nil

	-- 핫토리 한조 NPC 이름
	self.hattori_hanzo_name = "highschool_hanzo"

	-- 이벤트 시작하는 의자
	self.sushi_chair = nil

	-- 이벤트 시작하는 의자 이름
	self.sushi_chair_name = "sushi_chair"

	-- 핫토리 한조 검 아이템 번호
	self.hattori_hanzo_sword_item_id = 20140

	-- 핫토리 한조 검 획득을 저장하는 스테이지 커스텀 키 번호
	self.get_hattori_hanzo_sword = 0



	-- 킬빌 이벤트

	-- 킬빌 이벤트 보았는지
	self.see_kill_bill_event = false

	-- 킬빌 NPC
	self.kill_bill = nil

	-- 킬빌 NPC 이름
	self.kill_bill_name = "highschool_killbill"



	-- 역날검 획득 이벤트

	-- 역날검 아이템 Interact용 오브젝트
	self.reversed_blade = nil

	-- 역날검 아이템 이름
	self.reversed_blade_item_name = "reversed_blade"

	-- 역날검 아이템 번호
	self.reversed_blade_item_id = 20139

	-- 역날검 DropItem
	self.dropped_sword = nil

	-- 역날검 획득을 저장하는 스테이지 커스텀 키 번호
	self.get_reversed_blade = 1



	-- 양호실 이벤트

	-- 이미 양호실 검도부원과 대화했는지
	self.see_infirmary_kendo_staff_event = false

	-- 양호실 검도부원 NPC
	self.infirmary_kendo_staff = nil

	-- 양호실 검도부원 이름
	self.infirmary_kendo_staff_name = "infirmary_student_3"

	-- 양호실 스타피스 이름
	self.infirmary_star_piece_name = "infirmary_star_piece"

	-- 메인 퀘스트 번호
	self.main_quest_id = 60001



	-- BATTLE_1의 몬스터 그룹 이름
	self.battle_1_group_name = "battle_1"

	-- BATTLE_1에서 비밀길 막는 배틀게이트 이름 (전투 끝나면 비활성화해야 함)
	self.hidden_battle_gate_name = "hidden_battlegate"
end

function local_class:load_resource()
	CS.MessyText.PreLoad()

	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	self.scene:add_callback('ShowTypingText', { controller = self, func = self.show_typing_text })
	self.scene:add_callback('DummyStop', { controller = self, func = self.dummy_stop })
	self.scene:add_callback('DummyResume', { controller = self, func = self.dummy_resume })

	self.player_dummy = get_field_object(self.player_dummy_name)

	self.hattori_hanzo = get_character(self.hattori_hanzo_name)

	self.sushi_chair = get_field_object(self.sushi_chair_name)

	if stage_progress:GetCustomData(self.get_hattori_hanzo_sword) == false then
		self.sushi_chair.Interactable = CS.Oak.PublishInteractable.Create()
	end

	self.reversed_blade = get_field_object(self.reversed_blade_item_name)

	if stage_progress:GetCustomData(self.get_reversed_blade) then
		self.reversed_blade.ActiveState = CS.Oak.ActiveState.Disabled
	end

	self.kill_bill = get_character(self.kill_bill_name)
	self.kill_bill.Interactable:AddListener(self.cs_controller)

	self.infirmary_kendo_staff = get_character(self.infirmary_kendo_staff_name)

	if stage_progress:HasStarPiece(self.infirmary_star_piece_name) == false then
		self.infirmary_kendo_staff.Interactable:AddListener(self.cs_controller)
	end

	-- 기본 설정 씬 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.scene.setting, self.scene))

	if stage_progress:HasStarPiece(self.training_room_star_piece_name) then
		self.see_training_room_event = true
		self.see_training_room_player_event = true
	else
		-- 더미 트레이닝 설정 씬 실행
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.scene.setting_training_room, self.scene))
	end

	-- 더미 치는 NPC CrashBehaviour 설정
	for i = 1, self.training_kendo_student_num do
		local c = get_character(string.format("%s%d", self.training_kendo_student_name, i))

		c.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	end

	get_character(self.late_kendo_student_name).CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	get_character(self.training_kendo_leader_name).CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	-- 검도부원 설정 씬 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.scene.setting_kendo_staff, self.scene))

	return
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60001)
	return main_quest ~= nil and main_quest.InnerProgress >= 7 and main_quest.InnerProgress <= 9
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self.cs_controller = nil
	self.scene = nil

	self.player_dummy = nil
	self.hattori_hanzo = nil
	self.kill_bill = nil
	self.infirmary_kendo_staff = nil
	self.sushi_chair = nil
	self.reversed_blade = nil
	self.dropped_sword = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		self:on_camera_grid_leave_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- 역날검 설정
	if stage_progress:GetCustomData(self.get_reversed_blade) == false then
		local item_place_holder = CS.Oak.ItemPlaceholder()
		item_place_holder.ItemId = self.reversed_blade_item_id
		item_place_holder.NotForInventory = true

		self.dropped_sword = CS.Oak.DropItem.Create(self.reversed_blade.Position,
				item_place_holder, false, CS.Oak.DropItem.LootState.DontFindLooter)

		local reversed_blade_item_transform = self.dropped_sword.SpriteTransform
		local reversed_blade_shadow_transform = self.dropped_sword.ShadowTransform

		reversed_blade_item_transform.localRotation = unity_class.quaternion.Euler(vector(90, 135, 0))
		reversed_blade_shadow_transform.localRotation = unity_class.quaternion.Euler(vector(90, 135, 0))
	end
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then
		return
	end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		return
	end
	local zone_name = e.Zone.Name

	if zone_name == self.training_room_event_zone_name then
		if not self.enter_training_room then
			self.enter_training_room = true
		end

		if not self.see_training_room_event then
			self.see_training_room_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.training_room_event, self))
		end
	end

	if zone_name == self.kendo_staff_member_run_zone_name then
		if not self.see_kendo_staff_member_run_event then
			self.see_kendo_staff_member_run_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.scene.kendo_staff_member_run, self.scene))
		end
	end

	if zone_name == self.kendo_staff_member_battle_zone_name then
		if self.see_kendo_staff_member_battle_event == false and self.see_kendo_staff_member_run_event == true then
			self.see_kendo_staff_member_battle_event = true

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.start_battle, self))
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.player_dummy) then
		if self.see_training_room_player_event == false and self.wait_for_player == true then
			self.see_training_room_player_event = true
			self.wait_for_player = false

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.training_room_player_event, self))
		end
	elseif lua_helper.reference_equals(e.Target, self.sushi_chair) then
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.talk_with_hattori_hanzo, self))
	elseif lua_helper.reference_equals(e.Target, self.infirmary_kendo_staff) then
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.talk_with_infirmary_kendo_staff, self))
	elseif lua_helper.reference_equals(e.Target, self.kill_bill) then
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.talk_with_kill_bill, self))
	elseif lua_helper.reference_equals(e.Target, self.reversed_blade) then
		-- PublishInteractable이 비활성화 되어서 이 코드가 호출되지 않겠지만 혹시 몰라 에러 방지 코드 추가
		if not stage_progress:GetCustomData(self.get_reversed_blade) then
			coroutine_manager:StartCoroutine(
					stage.StageGameObject, util.cs_generator(self.get_reversed_blade_event, self))
		end
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.kendo_staff_battle_group_name then
		for i = 1, self.kendo_staff_battle_gate_num do
			message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(
					string.format("%s%d", self.kendo_staff_battle_gate_name, i)))
		end
	elseif e.BattleGroupName == self.battle_1_group_name then
		get_field_object(self.hidden_battle_gate_name).ActiveState = CS.Oak.ActiveState.Disabled
	end
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, self.training_room_grid_name) == false then
		return
	end

	if self.dummy_is_move == false and self.see_training_room_player_event == true then
		self.dummy_is_move = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dummy_move, self))
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, self.training_room_grid_name) == false then
		return
	end

	self.dummy_is_move = false
end

-- 더미가 검도부원들의 공격에 움직이는 이벤트
function local_class:dummy_move()
	local dummy_list = create_generic_list(typeof(CS.Oak.FieldObject))
	local dummy_pos_list = create_generic_list(unity_class.vector3)
	local dummy_shadow_list = create_generic_list(typeof(CS.UnityEngine.Transform))
	local dummy_shadow_pos_list = create_generic_list(unity_class.vector3)

	for i = 1, self.dummy_num do
		local cur_dummy = get_field_object(string.format("%s%d", self.dummy_name, i))
		dummy_list:Add(cur_dummy)
		dummy_pos_list:Add(cur_dummy.Position)

		dummy_shadow_list:Add(cur_dummy.Transform:GetChild(0))
		dummy_shadow_pos_list:Add(cur_dummy.Transform:GetChild(0).position)
	end

	if self.see_training_room_player_event then
		dummy_list:Add(self.player_dummy)
		dummy_pos_list:Add(self.player_dummy.Position)

		dummy_shadow_list:Add(self.player_dummy.Transform:GetChild(0))
		dummy_shadow_pos_list:Add(self.player_dummy.Transform:GetChild(0).position)
	end

	-- 더미 치는 검도부원들 설정
	local training_kendo_student_list = {}

	for i = 1, self.training_kendo_student_num do
		local c = get_character(string.format("%s%d", self.training_kendo_student_name, i))

		table.insert(training_kendo_student_list, c)
	end

	if self.see_training_room_player_event then
		table.insert(training_kendo_student_list, get_character(self.late_kendo_student_name))
	end

	for i = 1, #training_kendo_student_list do
		character_util.jump(training_kendo_student_list[i], 0.1, 0.5)
		training_kendo_student_list[i]:SetAnimation("attack", false)
	end

	wait_for_sec(0.1)

	local cycle = 0.45
	local rest_cycle = 0.15
	local hitting_point = 0

	local dummy_hitting_time_passed = 0
	local hitting_progress = 0
	local shake_magnitude = 0.02

	local is_animated = false

	local isHit = false

	while self.dummy_is_move == true do
		dummy_hitting_time_passed = dummy_hitting_time_passed + unity_class.time.deltaTime

		local progress = dummy_hitting_time_passed / cycle;

		if progress >= 1 then
			dummy_hitting_time_passed = 0
			isHit = false
			is_animated = false

			for i = 0, dummy_list.Count - 1 do
				dummy_list[i].Transform.localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
				dummy_list[i].Position = dummy_pos_list[i]

				dummy_shadow_list[i].localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
				dummy_shadow_list[i].localPosition = vector(0, 0.03, -0.21)
			end

			for i = 1, #training_kendo_student_list do
				character_util.jump(training_kendo_student_list[i], 0.1, 0.5)
				training_kendo_student_list[i]:SetAnimation("attack", false)
			end

			wait_for_sec(rest_cycle)
		else
			if not isHit and self.enter_training_room then
				isHit = true

				-- 더미 hit sfx
				music_player_util.play_sfx({
					sfx_name = '01_hit_dummy_02', play_pos = dummy_list[0].Position
				})
			end

			hitting_progress = (dummy_hitting_time_passed - hitting_point) / ((cycle - hitting_point) * 0.75)

			for i = 0, dummy_list.Count - 1 do
				local angle = 18 * unity_class.mathf.Sin(unity_class.mathf.Min(1, hitting_progress) * unity_class.mathf.PI);

				dummy_list[i].Transform.localRotation = unity_class.quaternion.AngleAxis(angle, vector(0, 0, 1))

				local shake = vector(shake_magnitude * (unity_class.random.value - 0.5), 0,
						shake_magnitude * (unity_class.random.value - 0.5))

				dummy_list[i].Transform.localPosition = dummy_pos_list[i] + shake

				dummy_shadow_list[i].position = dummy_shadow_pos_list[i]
				dummy_shadow_list[i].localRotation = unity_class.quaternion.AngleAxis(-angle, vector(0, 0, 1))
			end

			-- 검도부원 애니메이션 처리
			if is_animated == false and progress >= 0.8 then
				is_animated = true

				for i = 1, #training_kendo_student_list do
					training_kendo_student_list[i]:SetAnimation("katana_idle", true)
				end
			end

			coroutine.yield(nil)
		end
	end

	for i = 0, dummy_list.Count - 1 do
		dummy_list[i].Transform.localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
		dummy_list[i].Transform.localPosition = dummy_pos_list[i]

		dummy_shadow_list[i].localRotation = unity_class.quaternion.Euler(vector(0, 0, 0))
		dummy_shadow_list[i].localPosition = vector(0, 0.03, -0.21)
	end
end

-- 수련장에 들어가면 실행되는 이벤트
function local_class:training_room_event()
	coroutine.yield(self.scene:training_room_event())

	self.wait_for_player = true
	self.player_dummy.Interactable = CS.Oak.PublishInteractable.Create()
end

-- 수련장 이벤트를 본 뒤, 빈 더미와 Interact하면 실행되는 이벤트
function local_class:training_room_player_event()
	self.player_dummy.Interactable = CS.Oak.NonInteractable.Instance

	field_ui_manager:Hide()

	character_util.align_party(vector(0, 0, 10), "right", 1, "arc")

	coroutine.yield(self.scene:training_room_player_event())

	-- 스타피스 등장
	local star_piece = get_field_object(self.training_room_star_piece_name)
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(vector(2, 0, 10)))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 수련장 이벤트의 TypingText 표시
function local_class:show_typing_text()
	-- TypingText 생성
	local resholder = CS.Foundations.ResourceHolder()
	local typing_text = nil

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			resholder, self.typing_text_asset_bundle_name, self.typing_text_asset_name, function(prefab)
				typing_text = CS.NGUITools.AddChild(
						stage.UIRoot.gameObject, prefab):GetComponent(typeof(CS.UITypingText))

				typing_text.Widget:SetAnchor(stage.UIRoot.gameObject, 1, 90, 1, 110);
				typing_text.Widget.topAnchor.relative = 0;
				typing_text.Widget:UpdateAnchors();
				typing_text.Label.fontSize = 32;

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						typing_text:SetTypedText(game_string:GetString('training_kendo_room_5'), 1000, 0.04, 1.0))
			end)

	coroutine.yield(coroutine_class.wait_for_sec(2))

	typing_text:ForceFinish()
	resholder:Dispose()
end

-- 더미 움직임 중단
function local_class:dummy_stop()
	self.dummy_is_move = false
end

-- 더미 움직임 재개
function local_class:dummy_resume()
	self.dummy_is_move = true

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.dummy_move, self))
end

-- 핫토리 한조 NPC와 대화 이벤트
function local_class:talk_with_hattori_hanzo()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	coroutine.yield(nil)

	camera_util.move(vector(-34, 0, 64), 0.5)

	music_player:PlaySfxOneShot('01_jump_01')

	character_util.jump(user_party_leader, 1, 0.5)

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(
			user_party_leader, vector(-34, 0.5, 63), nil, 2, true, true))

	character_util.set_direction(user_party_leader, CS.Oak.Direction.Up)

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(
			self.hattori_hanzo, vector(-34, 0, 65), nil, 2, true, true))

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Down)

	self.hattori_hanzo:SetAnimation("question", false)
	self.hattori_hanzo:SetEmotion("smile", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_0', skip = true })

	user_party_leader:SetAnimation("nod", true)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	user_party_leader:RemoveAnimation()

	self.hattori_hanzo:SetAnimation("cast", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_1', skip = true })

	local wait = true
	local go_next = false
	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_0"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			go_next = true
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_1"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_2"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if not go_next then
		yield_return(self, "talk_end")

		return
	end

	-- 박수 sfx 재생
	local clap_sfx = music_player_util.play_sfx({
		sfx_name = '01_clap_01', loop = true
	})

	self.hattori_hanzo:SetAnimation("clap", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_2', skip = true })

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_3', skip = true })

	-- 박수 sfx 중지
	clap_sfx:FadeOut(0.2)

	self.hattori_hanzo:SetAnimation("question", false)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_4', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_4"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_3"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if not go_next then
		yield_return(self, "talk_end")

		return
	end

	self.hattori_hanzo:SetAnimation("cast", true)
	self.hattori_hanzo:RemoveEmotion()

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_5', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_5"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_6"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if not go_next then
		yield_return(self, "talk_end")

		return
	end

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Left)

	-- equipping sfx 재생
	local equipping_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', loop = true
	})

	self.hattori_hanzo:SetAnimation("eat", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_6', skip = true })

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_7', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_7"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_8"),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_9"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- equipping sfx 중지
	equipping_sfx:FadeOut(0.2)

	if not go_next then
		yield_return(self, "talk_end")

		return
	end

	-- bgm_transition: Field(ondemand/highschool/preload:bgm_highschool_main) -> Muted, 2
	music_player_util.play_stage_music({
		state = 'muted', mix = 2
	})

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Down)
	self.hattori_hanzo:RemoveAnimation()
	self.hattori_hanzo:SetEmotion("attack", true)

	character_util.show_emoticon_async(self.hattori_hanzo, nil, CS.Oak.EmoticonType.Silence)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_8', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_11"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_10"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if not go_next then
		yield_return(self, "talk_end")

		-- '핫토리 한조' 선택지 선택 시 Muted햇던 Bgm 원복
		-- bgm_transition: Muted -> Field(ondemand/highschool/preload:bgm_highschool_main), 2
		music_player_util.play_stage_music({
			state = 'field', mix = 2
		})

		return
	end

	self.hattori_hanzo:SetAnimation("question", false)
	self.hattori_hanzo:RemoveEmotion()

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_9', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_12"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_13"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if not go_next then
		yield_return(self, "talk_end")

		-- '핫토리 한조' 선택지 선택 시 Muted햇던 Bgm 원복
		-- bgm_transition: Muted -> Field(ondemand/highschool/preload:bgm_highschool_main), 2
		music_player_util.play_stage_music({
			state = 'field', mix = 2
		})

		return
	end

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Left)

	-- equipping sfx 재생
	equipping_sfx = music_player_util.play_sfx({
		sfx_name = '03_equipping_01', loop = true
	})

	self.hattori_hanzo:SetAnimation("eat", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_10', skip = true })

	wait = true
	branches:Clear()
	go_next = false

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_14"),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			go_next = true
			wait = false
		end })

	branches:Add({
		Text = game_string:GetString("highschool_1_2_hattori_hanzo_talk_branch_15"),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(self.user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	-- equipping sfx 중지
	equipping_sfx:FadeOut(0.2)

	if not go_next then
		yield_return(self, "talk_end")

		-- '핫토리 한조' 선택지 선택 시 Muted햇던 Bgm 원복
		-- bgm_transition: Muted -> Field(ondemand/highschool/preload:bgm_highschool_main), 2
		music_player_util.play_stage_music({
			state = 'field', mix = 2
		})

		return
	end

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Up)
	self.hattori_hanzo:RemoveAnimation()
	self.hattori_hanzo:RemoveEmotion()

	character_util.show_emoticon_async(self.hattori_hanzo, nil, CS.Oak.EmoticonType.Silence)

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Down)
	self.hattori_hanzo:SetAnimation("idle", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_11', skip = true })

	coroutine_manager:StartCoroutine(stage.StageGameObject, CS.Oak.IFieldObjectExtensions.MoveTo(
			self.hattori_hanzo, vector(-34, 0, 68), 1, nil, true, true))

	screen_util.fade_out_async(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	screen_util.fade_in(1, unity_class.color.black, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	coroutine_manager:StartCoroutine(stage.StageGameObject, CS.Oak.IFieldObjectExtensions.MoveTo(
			self.hattori_hanzo, vector(-34, 0, 65), 1, nil, true, true))

	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(
			game_string:GetString("highschool_1_2_hattori_hanzo_narration_1"), 0, 1))
	stage.FieldUINarrationBox:Hide()

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	self.hattori_hanzo:SetAnimation("cross_arm", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_12', skip = true })

	self.hattori_hanzo:SetAnimation("push", true)

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_13', skip = true })

	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = self.hattori_hanzo_sword_item_id
	item_place_holder.NotForInventory = true

	-- 검 튀어나오는 sfx
	music_player:PlaySfxOneShot('02_sword_attack_01')

	local dropped_sword = CS.Oak.DropItem.Create(
			self.hattori_hanzo.Position + vector(0, 0, -0.2),
			user_party_leader.Position + vector(0, 0, 0.3), item_place_holder, false)
	dropped_sword:SetSortingLayer(true)

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder, "hattori_hanzo_sword_subtitle",
			"hattori_hanzo_sword_description"))

	self.hattori_hanzo:RemoveAnimation()

	speech_bubble_util.show_speech_bubble_async(self.hattori_hanzo, { key = 'highschool_1_2_hattori_hanzo_14', skip = true })

	-- '핫토리 한조' 선택지 선택 시 Muted햇던 Bgm 원복
	-- bgm_transition: Muted -> Field(ondemand/highschool/preload:bgm_highschool_main), 2
	music_player_util.play_stage_music({
		state = 'field', mix = 2
	})

	-- 플레이어 의자에서 뛰어내리는 sfx
	music_player:PlaySfxOneShot('01_jump_01')

	character_util.jump(user_party_leader, 1, 0.5)

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(
			user_party_leader, vector(-34, 0, 62), nil, 2, true, true))

	character_util.set_direction(user_party_leader, CS.Oak.Direction.Down)

	camera_util.move(user_party_leader.Position, 0.3)

	coroutine.yield(coroutine_class.wait_for_sec(0.3))

	stage_camera:SetTarget(user_party_leader)

	stage_progress:SendCustomData(self.get_hattori_hanzo_sword, true)

	self.sushi_chair.Interactable = CS.Oak.NonInteractable.Instance

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 핫토리 한조 대화 종료
function local_class:talk_end()
	self.hattori_hanzo:RemoveAnimation()
	self.hattori_hanzo:RemoveEmotion()

	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(
			game_string:GetString("highschool_1_2_hattori_hanzo_narration_0"), 0, 1))
	stage.FieldUINarrationBox:Hide()

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(
			self.hattori_hanzo, vector(-35, 0, 65), nil, 2, true, true))

	character_util.set_direction(self.hattori_hanzo, CS.Oak.Direction.Down)

	-- 플레이어 의자에서 뛰어내리는 sfx
	music_player:PlaySfxOneShot('01_jump_01')

	character_util.jump(user_party_leader, 1, 0.5)

	coroutine.yield(CS.Oak.IFieldObjectExtensions.MoveTo(
			user_party_leader, vector(-34, 0, 62), nil, 2, true, true))

	character_util.set_direction(user_party_leader, CS.Oak.Direction.Down)

	camera_util.move(user_party_leader.Position, 0.3)

	coroutine.yield(coroutine_class.wait_for_sec(0.3))

	stage_camera:SetTarget(user_party_leader)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 양호실 검도부원과 대화 이벤트
function local_class:talk_with_infirmary_kendo_staff()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if main_quest_progress.InnerProgress > 9 then
		field_ui_manager:Hide()
		character_util.align_party(self.infirmary_kendo_staff, "left")

		-- 검도부원이 기분 좋아서 펄쩍펄쩍 뜀
		-- Positive 분위기 소리 추가

		self.infirmary_kendo_staff:SetAnimation("victory_extra", true)
		self.infirmary_kendo_staff:SetEmotion("smile", true)

		music_player:PlaySfxOneShot('03_dialogue_positive_01')

		speech_bubble_util.show_speech_bubble_async(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_3', skip = true })

		self.infirmary_kendo_staff:SetAnimation("cast", true)

		speech_bubble_util.show_speech_bubble_async(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_4', skip = true })

		-- 스타피스 등장
		local star_piece = get_field_object(self.infirmary_star_piece_name)
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(self.infirmary_kendo_staff.Position))

		self.infirmary_kendo_staff.Interactable:RemoveRelatedEvent(self.cs_controller)
		self.infirmary_kendo_staff:RemoveAnimation()

		field_ui_manager:Show()
		user_party:ResetControllers()
	else
		if self.see_infirmary_kendo_staff_event then
			speech_bubble_util.show_speech_bubble(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_1', skip = true })
		else
			self.see_infirmary_kendo_staff_event = true

			field_ui_manager:Hide()
			character_util.align_party(self.infirmary_kendo_staff, "left")

			speech_bubble_util.show_speech_bubble_async(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_0', skip = true })

			self.infirmary_kendo_staff:SetAnimation("release", true)
			self.infirmary_kendo_staff:SetEmotion("attack", true)

			character_util.add_animation_sfx(self.infirmary_kendo_staff, '01_swing_01')

			speech_bubble_util.show_speech_bubble_async(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_1', skip = true })

			self.infirmary_kendo_staff:SetAnimation("question", false)
			self.infirmary_kendo_staff:SetEmotion("tired", true)

			speech_bubble_util.show_speech_bubble_async(self.infirmary_kendo_staff, { key = 'highschool_1_2_infirmary_2', skip = true })

			self.infirmary_kendo_staff:RemoveAnimation()
			self.infirmary_kendo_staff:RemoveEmotion()

			field_ui_manager:Show()
			user_party:ResetControllers()
		end
	end
end

-- 킬빌 NPC와 대화 이벤트
function local_class:talk_with_kill_bill()
	if stage_progress:GetCustomData(self.get_hattori_hanzo_sword) then
		speech_bubble_util.show_speech_bubble(self.kill_bill, { key = 'highschool_1_2_kill_bill_2' })
	else
		if self.see_kill_bill_event == false then
			self.see_kill_bill_event = true

			field_ui_manager:Hide()
			character_util.align_party(self.kill_bill, "left")

			self.kill_bill:SetAnimation("release", true)
			self.kill_bill:SetEmotion("attack", true)

			character_util.add_animation_sfx(self.kill_bill, '01_swing_01')

			-- bgm_transition: Field(ondemand/highschool/preload:bgm_highschool_main) -> Muted
			music_player_util.play_stage_music({
				state = 'muted', mix = 0.5
			})

			local kill_bill_sfx = music_player_util.play_sfx({
				sfx_name = '01_killbill_01'
			})

			speech_bubble_util.show_speech_bubble_async(self.kill_bill, { key = 'highschool_1_2_kill_bill_0', skip = true })

			self.kill_bill:SetAnimation("cross_arm", true)

			speech_bubble_util.show_speech_bubble_async(self.kill_bill, { key = 'highschool_1_2_kill_bill_1', skip = true })

			self.kill_bill:RemoveAnimation()
			self.kill_bill:RemoveEmotion()

			kill_bill_sfx:FadeOut(1)

			-- bgm_transition: Muted -> Field(ondemand/highschool/preload:bgm_highschool_main)
			music_player_util.play_stage_music({
				state = 'field'
			})

			field_ui_manager:Show()
			user_party:ResetControllers()
		else
			speech_bubble_util.show_speech_bubble(self.kill_bill, { key = 'highschool_1_2_kill_bill_1' })
		end
	end
end

-- 역날검 획득 이벤트
function local_class:get_reversed_blade_event()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	self.reversed_blade.ActiveState = CS.Oak.ActiveState.Disabled

	self.dropped_sword.ConsumeTarget = user_party_leader
	self.dropped_sword:Fly()

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local item_place_holder = CS.Oak.ItemPlaceholder()
	item_place_holder.ItemId = self.reversed_blade_item_id

	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item_place_holder, "reversed_blade_subtitle",
			"reversed_blade_description"))

	stage_progress:SendCustomData(self.get_reversed_blade, true)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 2층에서 달려온 검도부원들과 전투 시작
function local_class:start_battle()
	for i = 1, self.battle_kendo_student_num do
		local cur_student = get_character(string.format("%s%d", self.battle_kendo_student_name, i))
		character_util.convert_to_monster(cur_student, self.kendo_staff_battle_group_name)
		command_util.execute_monster_notice(cur_student, user_party_leader, "battle")
	end

	for i = 1, self.kendo_staff_battle_gate_num do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(
				string.format("%s%d", self.kendo_staff_battle_gate_name, i)))
	end

	coroutine.yield(nil)

	speech_bubble_util.show_speech_bubble(
			get_character(string.format("%s%d", self.battle_kendo_student_name, 4)),
			"kendo_staff_member_battle_0")
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
