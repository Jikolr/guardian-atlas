local local_class = newclass("InvaderReporterController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.reporter = nil

	-- 암흑 마법사 외형
	self.dark_magician = nil

	-- 암흑 마법사 본체
	self.invader_knight = nil

	-- 기존 파티 리더, 맵 구석으로 옮겨서 NPC로 사용함
	self.saved_party_leader = nil

	-- 순찰 NPC들
	self.guard_npcs = nil

	-- 암흑 마법사 텐트 지키는 NPC들
	self.dark_magician_tent_guard_list = nil

	-- 출구
	self.stage_exit = nil

	-- 암흑 마법사 텐트 입구
	self.dark_magician_tent_entry = nil

	-- 암흑 마법사 텐트 출구
	self.dark_magician_tent_exit = nil

	-- 암흑 마법사 상호작용 오브젝트
	self.dark_magician_interactable = nil

	-- 카메라 포인터
	self.camera_pointer = nil

	-- 특종 게이지 UI
	self.scoop_ui = nil

	-- 리소스 홀더
	self.resholder = nil

	-- 현재 사진 개수
	self.scoop_point = 0

	-- 목표 사진 개수
	self.scoop_point_target = 4

	-- 트루 엔딩 볼 수 있는 사진 개수
	self.scoop_point_can_complete = 6

	-- 최대 사진 개수
	self.scoop_point_max = 7

	-- 현재 기사 점수
	self.journal_point = 0

	-- 목표 기사 점수
	self.journal_max = 120

	-- 마커가 보이지 않는 실내나 지하에 플레이어가 위치하는지 저장하는 플래그
	self.enter_inner = false

	-- 경비병에 걸린 경우, 중복 탐지 방지 플래그
	self.is_detected = false

	-- Positive 트루 엔딩인지
	self.is_positive_end = false

	-- 엔딩 이벤트 state
	self.event_state = {
		-- 특종 개수 조건 불만족
		idle = 0,
		-- 특종 개수 조건 만족
		scoop_complete = 1,
		-- 암흑 마법사 텐트 이벤트 봄
		see_dark_magician_tent_event = 2,
		-- 텐트 나와서 암흑 마법사 본체 이벤트 봄
		get_out_dark_magician_tent = 3
	}

	self.current_event_state = self.event_state.idle

	--현재 플레이어가 있는 카메라 그리드 이름
	self.current_cameragrid_name = nil

	-- 현재 플레이어가 있는 카메라 그리드
	self.current_cameragrid = nil

	-- 전체 카메라 그리드 이름 리스트
	self.cameragrid_name_list = nil

	-- 사진 찍기가 유효한 카메라 그리드 이름 리스트
	self.target_cameragrid_name_list = nil

	-- 사진 찍은 그리드 저장 리스트
	self.taken_picture_cameragrid_name_list = nil

	-- 사진 찍은 위치 저장하는 리스트
	self.photo_position_list = nil

	-- 카메라 포인터 진입으로는 ZoneEnterEvent 발동시키지 않을 이벤트 존 이름 리스트
	self.cannot_trigger_zone_enter_event_zone_name_list = nil

	-- 사진 촬영 state
	self.camera_state = {
		-- 카메라 조작 중인 상태가 아님
		idle = 0,
		-- 카메라 버튼을 눌러서 촬영 모드 진입 중인 상태
		enter_taking_picture = 1,
		-- 촬영 모드
		take_picture = 2,
		-- 촬영 모드 종료하고 일반 상태로
		enter_idle = 3
	}

	self.current_camera_state = self.camera_state.idle

	-- 스테이지 커스텀 State
	-- 한 번 촬영한 사진들은 이 곳에 저장되서 재입장 시에는 다시 찍을 필요 없도록 설정
	self.stage_custom_state = {
		dead_body = 0,
		prisoner = 1,
		soup = 2,
		lorain_1 = 3,
		super_invader = 4,
		lorain_2 = 5,
		frozen_transport = 6,
		-- 비키니 인베이더
		bikini_invader = 7,
		-- 암흑 마법사 만났는지 저장
		meet_dark_magician = 8,
		-- 이 값은 사진과 관계없이 노말 엔딩 본 뒤에 스테이지 재 입장시에 true인 State
		experience_failure = 9,
		-- 이 스테이지에는 퀘스트가 없어서 퍼플 코인이 저장되지 않을 수 있으므로 엔딩 전에 CustomState를 한 번 업데이트 해 줘서 저장시킨다.
		enter_exit = 10
	}

	-- 스테이지 커스텀 State가 true일 경우, 촬영한 사진의 위치를 임의로 저장 (Vector를 스테이지 정보로 저장하기에는 너무 무거움)
	self.saved_camera_pos_list = nil

	-- 사진 촬영 예외 처리
	self.get_photo_bikini_invader = false
	self.bikini_invader_cameragrid_name = 'bikini'
	self.camera_bikini_zone_name = 'camera_bikini'

	self.give_soup = false
	self.super_invader_scoop = false
	self.coco_scoop = false

	-- 기타 상수
	self.camera_pointer_move_speed = 8
	self.cameragrid_num = 19
	self.scoop_gauge = 1
	self.positive_journal_gauge = 20
	self.negative_journal_gauge = -20
	self.dark_magician_tent_guard_num = 2
	self.guard_num_2 = 2
	self.guard_num_11 = 6
	self.purple_coin_num = 25
	self.paper_item_id = 20102

	-- NPC 이름
	self.reporter_name = 'invader_reporter'
	self.dark_magician_name = 'dark_magician'
	self.invader_knight_name = 'invader_knight'
	self.dark_magician_tent_guard_name = 'dark_magician_guard_'
	self.guard_name_2 = 'guard_2_'
	self.guard_name_11 = 'guard_11_'
	self.soup_invader_name = 'soup_invader'
	self.super_invader_name = 'super_invader'
	self.coco_name = 'coco'

	-- 필드오브젝트 이름
	self.stage_exit_name = 'exit_stage'
	self.dark_magician_tent_entry_name = 'entry_dark_magician_tent'
	self.dark_magician_tent_exit_name = 'exit_dark_magician_tent'
	self.dark_magician_interactable_name = 'dark_magician_interactable'
	self.exit_door_name = 'exit_door'
	self.reporter_chair_name = 'reporter_chair'
	self.reporter_desk_name = 'reporter_desk'
	self.purple_coin_name = 'purple_coin_'

	-- 타일맵 존 이름
	self.camera_zone_name = 'camera_'
	self.inner_zone_name = 'inner'
	self.basement_zone_name = 'basement'

	-- 틴트 키
	self.tint_key = 'invader_reporter'
	self.tint_key_2 = 'invader_reporter_2'
	self.tint_key_3 = 'invader_reporter_3'

	-- 타임스케일 키
	self.time_scale_key = 'invader_reporter'

	-- 퀘스트 마커 이름
	self.quest_marker_name = 'invader_reporter'

	-- 커스텀 이벤트 이름
	self.get_photo_bikini_invader_event = 'get_photo_bikini_invader'
	self.get_photo_event = 'get_photo'
	self.cancel_camera_event = 'cancel_camera'
	self.give_soup_event = 'give_soup'
	self.take_picture_super_invader = 'take_picture_super_invader'
	self.take_picture_coco = 'take_picture_coco'

	-- 오브젝트 풀 이름

	CS.Oak.CommonScreenplay.PreloadTutorialSpine()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_cam_grid_enter')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.PlayerDetectedEvent), 'on_player_detected_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.reporter = get_character(self.reporter_name)

	self.dark_magician = get_character(self.dark_magician_name)
	self.dark_magician.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	self.dark_magician.SpineController.SortingGroup.sortingOrder = -1
	self.dark_magician.SpineController.IsShadowActive = false
	self.dark_magician.SpineController:AddColor(self.dark_magician.Name, unity_color({0, 0, 0, 1}), 1, 0)
	character_util.set_anim(self.dark_magician, { name = 'robe_only' })

	field_ui_manager:RemoveUI(self.dark_magician, CS.Oak.FieldUiType.CharacterStats)

	self.invader_knight = get_character(self.invader_knight_name)
	self.invader_knight:HideWeapon(true)

	self.guard_npcs = create_generic_list(CS.Oak.Character)

	-- 순찰 캐릭터 CrashBehaviour 변경
	for i = 1, self.guard_num_2 do
		local cur_guard = get_character(self.guard_name_2..i)

		cur_guard.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		self.guard_npcs:Add(cur_guard)
	end

	for i = 1, self.guard_num_11 do
		local cur_guard = get_character(self.guard_name_11..i)

		cur_guard.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		self.guard_npcs:Add(cur_guard)
	end

	self.dark_magician_tent_guard_list = create_generic_list(CS.Oak.Character)
	for i = 1, self.dark_magician_tent_guard_num do
		local guard = get_character(self.dark_magician_tent_guard_name..i)

		self.dark_magician_tent_guard_list:Add(guard)
	end

	self.stage_exit = get_field_object(self.stage_exit_name)
	self.stage_exit.Interactable = CS.Oak.PublishInteractable.Create()

	self.dark_magician_tent_entry = get_field_object(self.dark_magician_tent_entry_name)
	self.dark_magician_tent_entry.Interactable = CS.Oak.PublishInteractable.Create()

	self.dark_magician_tent_exit = get_field_object(self.dark_magician_tent_exit_name)
	self.dark_magician_tent_exit.Interactable = CS.Oak.PublishInteractable.Create()

	self.dark_magician_interactable = get_field_object(self.dark_magician_interactable_name)

	self.cameragrid_name_list = create_generic_list(CS.System.String)

	for i = 1, self.cameragrid_num do
		self.cameragrid_name_list:Add(i)
	end

	self.cameragrid_name_list:Add('bikini')

	self.target_cameragrid_name_list = create_generic_list(CS.System.String)
	self.target_cameragrid_name_list:Add('4')
	self.target_cameragrid_name_list:Add('2')
	self.target_cameragrid_name_list:Add('3')
	self.target_cameragrid_name_list:Add('7')
	self.target_cameragrid_name_list:Add('12')
	self.target_cameragrid_name_list:Add('13')
	self.target_cameragrid_name_list:Add('16')

	self.taken_picture_cameragrid_name_list = create_generic_list(CS.System.String)

	self.photo_position_list = create_generic_list(unity_class.vector3)

	for i = 0, self.target_cameragrid_name_list.Count - 1 do
		self.photo_position_list:Add(vector(999, 0, 999))
	end

	self.cannot_trigger_zone_enter_event_zone_name_list = create_generic_list(CS.System.String)
	self.cannot_trigger_zone_enter_event_zone_name_list:Add('super_invader_lab_upper_1')
	self.cannot_trigger_zone_enter_event_zone_name_list:Add('super_invader_lab_upper_2')
	self.cannot_trigger_zone_enter_event_zone_name_list:Add('super_invader_attack')

	self.saved_camera_pos_list = create_generic_list(unity_class.vector3)
	self.saved_camera_pos_list:Add(vector(7, 0, 16))
	self.saved_camera_pos_list:Add(vector(28.5, 0, -4))
	self.saved_camera_pos_list:Add(vector(52.5, 0, 4.5))
	self.saved_camera_pos_list:Add(vector(-16.5, 0, -56))
	self.saved_camera_pos_list:Add(vector(-18, 0, 39))
	self.saved_camera_pos_list:Add(vector(5, 0,  57.5))
	self.saved_camera_pos_list:Add(field:GetMarker('frozen_camera_marker').position)

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.resholder = CS.Foundations.ResourceHolder()

	-- 이펙트 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_5_invader_reporter/effects/stage', 'camera_pointer', function(prefab)
				self.camera_pointer = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.camera_pointer.transform.localPosition = unity_class.vector3.zero
				self.camera_pointer:SetActive(false)
			end)

	-- scoop UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_5_invader_reporter/ui', 'scoop_ui', function(prefab)
				self.scoop_ui = CS.NGUITools.AddChild(
						stage.UIRoot.gameObject, prefab):GetComponent(typeof(CS.Oak.UI.InvaderReporterScoopBoard))
			end)

	-- 현재까지 찍었던 사진 State 가져와서 확인
	local cur_scoop_num = 0

	for i = 0, self.scoop_point_max - 1 do
		if stage_progress:GetCustomData(i, false) then
			cur_scoop_num = cur_scoop_num + 1

			self.taken_picture_cameragrid_name_list:Add(self.target_cameragrid_name_list[i])
			self.photo_position_list[i] = self.saved_camera_pos_list[i]
		end
	end

	self.scoop_point = cur_scoop_num
	self.scoop_ui:Init(cur_scoop_num, self.scoop_point_max)

	if self.scoop_point >= self.scoop_point_target then
		self.current_event_state = self.event_state.scoop_complete

		-- 암흑 마법사 텐트 지키는 NPC들 제거
		for i = 0, self.dark_magician_tent_guard_list.Count - 1 do
			character_util.set_active_state(self.dark_magician_tent_guard_list[i], 'disabled')
		end
	end

	-- 암흑 마법사 이벤트 본 경우
	if stage_progress:GetCustomData(self.stage_custom_state.meet_dark_magician, false) then
		self.current_event_state = self.event_state.get_out_dark_magician_tent

		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.exit_door_name))
	end
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	screen_util.fade_in(0, unity_class.color.black, 'linear')

	-- 플레이어 캐릭터 인베이더 기자로 교체
	self:change_manual_character(self.reporter_name)

	coroutine.yield(nil)

	field:Tint('stage_start', unity_class.color.white, 0)

	music_player_util.play_stage_music({ state = 'field', mix = 2 })

	stage_camera:SetTarget(user_party_leader)

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')

	if not user_progress:IsStageCleared(stage.Name) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.intro_walk, self))

		-- 인트로 연출 시작
		screen_util.fade_in_circular_async(1, 'linear')
	else
		screen_util.fade_in_circular(1, 'linear')
	end

	if not stage_progress:GetCustomData(self.stage_custom_state.experience_failure, false) and
			not user_progress:IsStageCleared(stage.Name) then
		music_player_util.play_sfx({ sfx_name = '02_goblin_appear_01' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_0', skip = true })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_1', skip = true })

		camera_util.move(user_party_leader.Position + vector(6, 0, 0),
				2, { ignorecameragrids = true })

		wait_for_sec(1)

		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		coroutine.yield(nil)

		camera_util.move_async(vector(23, 0, 0.5), 0)

		coroutine.yield(nil)

		camera_util.move(vector(35, 0, 0.5), 4)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader,
				{
					key = 'invader_reporter_intro_2',
					screen_pos = vector(-100, 200),
					skip = true
				})

		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		stage_camera:CancelMove()

		coroutine.yield(nil)

		camera_util.move_async(user_party_leader.Position, 0, { end_target = user_party_leader })

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		user_party_leader.SpineController:SetAttachment('[base]weapon1', 'empty')
		character_util.set_anim(user_party_leader, { name = 'question', loop = false })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_3', skip = true })

		character_util.set_anim(user_party_leader, { name = 'cast' })
		character_util.set_emotion(user_party_leader, { name = 'tired' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_4', skip = true })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })

		character_util.set_anim(user_party_leader, { name = 'shoot' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_6', skip = true })

		user_party_leader.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
		character_util.set_anim(user_party_leader, { name = 'twohand_idle' })
		character_util.remove_emotion(user_party_leader)

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_7', skip = true })
	else
		if not user_progress:IsStageCleared(stage.Name) then
			wait_for_sec(1)

			music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01' })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_9', skip = true })

			if self.scoop_point ~= self.scoop_point_max then
				character_util.set_anim(user_party_leader, { name = 'question', loop = false })

				speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_10', skip = true })
			else
				character_util.set_anim(user_party_leader, { name = 'question', loop = false })

				speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_intro_11', skip = true })
			end
		end
	end

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	character_util.remove_anim(user_party_leader)

	-- 스테이지 시작 연출
	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry,
			user_party_leader.Position + vector(0.5, 0, 0), CS.Oak.Direction.Right, game_string:GetString(stage.Name))

	field_ui_manager:Show()

	coroutine.yield(nil)

	-- 캐릭터 무적으로 설정
	character_util.set_immortal(user_party_leader, true)

	-- 불필요한 UI 제거
	field_ui_manager:RemoveUI(user_party_leader, CS.Oak.FieldUiType.SkillButton
			| CS.Oak.FieldUiType.RoleButton | CS.Oak.FieldUiType.ModeChangeButton
			| CS.Oak.FieldUiType.TeamCombinationButton)

	-- 공격 액션 비활성화
	local manual_touch_state = CS.Oak.CharacterControllerManualTouchState.Create(user_party_leader, false)
	manual_touch_state:RequestDisableControl(user_party_leader, CS.Oak.DisabledControls.Attack)

	-- 클래스 버튼 UI를 찾아서 아이콘 강제로 변경
	local class_button = field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ClassButton)
	local class_button_icon = class_button.Content
	class_button.CustomIconName = 'actbtn_ic_act_camera.png';
	class_button_icon.SpriteName = 'actbtn_ic_act_camera.png'
	class_button_icon:Rebuild()

	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	-- 퀘스트 마커 설정
	-- 스테이지 클리어 시에는 나오지 않음
	if not user_progress:IsStageCleared(stage.Name) then
		-- 암흑 마법사 이벤트를 본 경우, Exit에 퀘스트 마커 설정
		if stage_progress:GetCustomData(self.stage_custom_state.meet_dark_magician, false) then
			ui_quest_marker:AddQuestMarkerToIFO(self.quest_marker_name, 0, false, self.stage_exit)
		elseif self.scoop_point >= self.scoop_point_target then
			-- 사진 개수가 target보다 큰 경우, 퀘스트 마커 여기서 설정해줌
			ui_quest_marker:AddQuestMarkerToPoint(self.quest_marker_name, 0, false, vector(28.5, 0, 43))
		end
	end

	-- 순찰 기믹 셋업
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.patrol_gimmick_setup, self))

	-- 순찰 병사들 속도 25% 감속
	for i = 0, self.guard_npcs.Count - 1 do
		buff_manager:AddBuff(self.guard_npcs[i], CS.Oak.EquipmentSlot.None, self.guard_npcs[i],
				"speed_down_persistent", 25, false, false)
	end

	-- 암흑 마법사 Interactable 여기서 셋업
	self.dark_magician_interactable.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(2, 3, 0.5))

	user_party:ResetControllers()
end

-- 플레이어 캐릭터 변경 및 파티 전체 비활성화
function local_class:change_manual_character(new_manual_character_name)
	self.saved_party_leader = user_party_leader
	local manual_character = get_character(new_manual_character_name)

	-- 레벨 업
	local exp = user_party_leader.FieldObjectStatsBehaviour.Exp
	manual_character.FieldObjectStatsBehaviour:SetExp(exp)

	-- 파티 리더 변경
	party_util.switch_leader(manual_character)

	character_util.set_direction(manual_character, self.saved_party_leader.Direction)

	-- 기존 캐릭터 보이지 않는 곳으로 이동
	character_util.set_position(self.saved_party_leader, vector(999, 0, 999))

	field_ui_manager:SetUI(user_party_leader, CS.Oak.FieldUiType.TopHpBar)

	local party_list = {}

	for i = 1, user_party.Count - 1 do
		local cur_party_member = user_party[i]

		table.insert(party_list, cur_party_member)
	end

	for i = 1, #party_list do
		character_util.convert_to_npc(party_list[i])

		character_util.set_active_state(party_list[i], 'disabled')
	end
end

-- 인베이더 기자 걸어서 스테이지 입장 연출
function local_class:intro_walk()
	character_util.set_anim(user_party_leader, { name = 'walk' })
	character_util.move_to_async(user_party_leader, user_party_leader.Position + vector(4, 0, 0),
			2, nil, true, false)

	character_util.set_anim(user_party_leader, { name = 'twohand_idle' })
end

-- #6 지역의 순찰 회피 기믹을 위해 virtual field object를 추가해서 NPC에 붙임
function local_class:patrol_gimmick_setup()
	local guard_1 = get_character('guard_6_3')
	local guard_2 = get_character('guard_6_6')

	-- 순찰 병사 웨이포인트 설정
	local waypoint_list_1 = create_generic_list(unity_class.vector3)
	waypoint_list_1:Add(vector(33.5, 0, -23))
	waypoint_list_1:Add(vector(33.5, 0, -16.5))

	character_util.move_waypoint(guard_1, waypoint_list_1,
			2, false, 'loop', 'floor', 'down')

	local waypoint_list_2 = create_generic_list(unity_class.vector3)
	waypoint_list_2:Add(vector(23.5, 0, -17))
	waypoint_list_2:Add(vector(23.5, 0, -22))

	character_util.move_waypoint(guard_2, waypoint_list_2,
			2, false, 'loop', 'floor', 'down')

	local guard_list = create_generic_list(CS.Oak.Character)
	guard_list:Add(guard_1)
	guard_list:Add(guard_2)

	for i = 0, guard_list.Count - 1 do
		guard_list[i].CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		guard_list[i].Hitbox = CS.Oak.Hitbox(vector(1.5, 2.25, 1.5))
		guard_list[i].ActiveState = CS.Oak.ActiveState.Visible
		guard_list[i].EntityGroup = CS.Oak.EntityGroups.Obstacle
	end

	coroutine.yield(nil)

	for i = 0, guard_list.Count - 1 do
		guard_list[i].ActiveState = CS.Oak.ActiveState.Enabled
	end
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.inner_zone_name or zone_name == self.basement_zone_name then
		if not self.enter_inner then
			self.enter_inner = true

			ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)
		end
	end
end

function local_class:on_zone_leave_event(e)
	if not e.FullLeave then return end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name

	if zone_name == self.inner_zone_name or zone_name == self.basement_zone_name then
		if self.enter_inner then
			self.enter_inner = false

			if self.current_event_state < self.event_state.see_dark_magician_tent_event or
					self.current_event_state == self.event_state.get_out_dark_magician_tent then
				ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)

				if not user_progress:IsStageCleared(stage.Name) then
					if self.current_event_state == self.event_state.scoop_complete then
						ui_quest_marker:AddQuestMarkerToPoint(self.quest_marker_name, 0, false, vector(28.5, 0, 43))
					elseif self.current_event_state == self.event_state.get_out_dark_magician_tent then
						ui_quest_marker:AddQuestMarkerToIFO(self.quest_marker_name, 0, false, self.stage_exit)
					end
				end
			end
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.stage_exit) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.write_journal, self))
	elseif lua_helper.reference_equals(e.Target, self.dark_magician_tent_entry) then
		if self.current_event_state == self.event_state.get_out_dark_magician_tent then
			speech_bubble_util.show_speech_bubble(user_party_leader, { key = 'invader_reporter_interact_dark_magician_tent_finished' })
		else
			sp_util.play_normal_screenplay(self.enter_dark_magician_tent, self)
		end
	elseif lua_helper.reference_equals(e.Target, self.dark_magician_tent_exit) then
		if self.current_event_state >= self.event_state.see_dark_magician_tent_event then
			self.current_event_state = self.event_state.get_out_dark_magician_tent

			sp_util.play_normal_screenplay(self.exit_dark_magician_tent, self)
		else
			speech_bubble_util.show_speech_bubble(user_party_leader, { key = 'invader_reporter_cannot_get_out_dark_magician_tent' })
		end
	elseif lua_helper.reference_equals(e.Target, self.dark_magician_interactable) then
		sp_util.play_normal_screenplay(self.dark_magician_tent_event, self)
	end
end

function local_class:on_cam_grid_enter(e)
	for i = 0, self.cameragrid_name_list.Count - 1 do
		local current = self.cameragrid_name_list[i]

		if type_util.is_player_enter_to_cam_grid(e, current) then
			self.current_cameragrid_name = current
			self.current_cameragrid = e.CameraGrid
		end
	end

	return false
end

function local_class:on_player_detected_event(e)
	if not self.is_detected then
		self.is_detected = true

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.player_detected, self, e.Detector, e.ResetMarker))
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.cancel_camera_event then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.cancel_camera, self))
		elseif e.Params[0] == self.give_soup_event then
			self.give_soup = true
		elseif e.Params[0] == self.take_picture_super_invader then
			self.super_invader_scoop = true
		elseif e.Params[0] == self.take_picture_coco then
			self.coco_scoop = true
		end
	end
end

function local_class:on_touch_event(e)
	-- 사진 촬영 모드 조작
	if self.current_camera_state == self.camera_state.take_picture then
		if e.TouchEventType == CS.Oak.TouchEventType.Action1TouchDown then
			-- 액션 버튼 누른 경우 사진 촬영
			self.current_camera_state = self.camera_state.enter_idle

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.take_picture, self))
		end
	elseif self.current_camera_state == self.camera_state.idle then
		-- 사진 촬영 모드가 아닐 때
		if e.TouchEventType == CS.Oak.TouchEventType.Action3TouchDown then
			self.current_camera_state = self.camera_state.enter_taking_picture

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.active_camera_mode, self))
		end
	end
end

function local_class:on_joypad_event(e)
	if not self.current_camera_state == self.camera_state.take_picture then
		return
	end

	-- 이벤트를 받아서 카메라를 이동시킨다
	if lua_helper.reference_equals(e.JoypadEventType, CS.Oak.JoypadEventType.StickDirection) then
		local dir = e.StickDirection
		local add = dir * unity_class.time.unscaledDeltaTime * self.camera_pointer_move_speed
		local cur_pos = self.camera_pointer.transform.localPosition + add

		local pointer_limit_x = 0
		local pointer_limit_z = 0

		-- 포인터 네 모서리 좌표 구하고 각 모서리 좌표가 전부 카메라 그리드 벗어나지 않으면 포인터 이동
		if self:is_in_camera_grid(cur_pos, pointer_limit_x, pointer_limit_z) then
			self.camera_pointer.transform.localPosition = cur_pos
		end

		local cam_half_height = stage_camera.Size
		local cam_half_width = stage_camera.HalfWidth

		camera_util.move(self.current_cameragrid:GetCameraPosInGrid(cur_pos, cam_half_width, cam_half_height),
				0, { use_unscaledtime = true })

		-- 카메라 포인터가 이동해서도 ZoneEnterEvent를 실행하도록 함, 플레이어가 직접 이동해야만 발생해야 하는 제외
		local zone_list = stage.Field:GetZoneListFor(cur_pos)

		if zone_list ~= nil and zone_list.Count > 0 then
			for i = 0, zone_list.Count - 1 do
				-- 예외 이벤트 존 확인
				local is_triggered = true

				for ii = 0, self.cannot_trigger_zone_enter_event_zone_name_list.Count - 1 do
					if zone_list[i].Name == self.cannot_trigger_zone_enter_event_zone_name_list[ii] then
						is_triggered = false
					end
				end

				if is_triggered then
					message_system:Publish(CS.Oak.ZoneEnterEvent.Create(zone_list[i], user_party_leader, true))
				end
			end

			zone_list:Dispose()
		end
	end
end

-- 해당 좌표에서 절대값이 x, y 좌표만큼 떨어진 네 꼭지점이 카메라 그리드 내부에 있는지 리턴
function local_class:is_in_camera_grid(pos, dist_x, dist_z)
	local pos_list = create_generic_list(unity_class.vector3)
	pos_list:Add(pos + vector(-dist_x, 0, dist_z))
	pos_list:Add(pos + vector(-dist_x, 0, -dist_z))
	pos_list:Add(pos + vector(dist_x, 0, dist_z))
	pos_list:Add(pos + vector(dist_x, 0, -dist_z))

	for i = 0, pos_list.Count - 1 do
		if not field:IsInCameraGrid(pos_list[i], self.current_cameragrid_name) then
			return false
		end
	end

	return true
end

-- 사진 촬영 모드로 변경
function local_class:active_camera_mode()
	-- 일반 State에서만 사진 촬영 모드로 변경하고 그 외는 무시
	-- 넉백, 단차 이동 등 촬영 금지
	if not lua_helper.type_compare(
			user_party_leader.FieldObjectBehaviour.CurrentState, CS.Oak.CharacterAnalogueState) then
		self.current_camera_state = self.camera_state.idle

		return
	end

	-- 일반 ActionState에서만 사진 촬영 모드로 변경하고 그 외는 무시
	-- 물건 들고 던지는 상태에서 촬영 금지
	local action_state = user_party_leader.CharacterBehaviour.CurrentActionState

	if action_state ~= nil and not lua_helper.type_compare(action_state, CS.Oak.CharacterNoActionState) then
		self.current_camera_state = self.camera_state.idle

		return
	end

	-- 불필요한 UI 끔
	stage.FieldUIMiniMap:Hide()

	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.PartyState)
	field_ui_manager:HideTargetUI(CS.Oak.FieldUiType.ClassButton)

	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Hide()
	end

	self.scoop_ui.Deactivated = true

	-- 이동 불가 설정
	local manual_touch_state = user_party_leader.FieldObjectController.CurrentState

	if manual_touch_state ~= nil and lua_helper.type_compare(manual_touch_state, CS.Oak.CharacterControllerManualTouchState) then
		manual_touch_state:RequestDisableControl(user_party_leader,
				CS.Oak.DisabledControls.Move | CS.Oak.DisabledControls.Interact | CS.Oak.DisabledControls.Hold)
	end

	-- 플레이어 촬영 포즈
	character_util.set_anim(user_party_leader, { name = 'unique/take_picture', loop = false })

	coroutine.yield(nil)

	music_player_util.play_sfx({ sfx_name = '01_camera_focus_01' })

	-- 카메라 포인터 활성화
	self.camera_pointer.transform.localPosition = user_party_leader.Position
	self.camera_pointer:SetActive(true)

	-- 액션 버튼 이미지 변경
	field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction =
	CS.Oak.CharacterControllerManualTouchState.Button1Action.Interact

	self.current_camera_state = self.camera_state.take_picture

	message_system:Subscribe(self, typeof(CS.Oak.JoypadEvent), 'on_joypad_event')
end

-- 사진 촬영
function local_class:take_picture()
	-- 이동 불가 해제
	local manual_touch_state = user_party_leader.FieldObjectController.CurrentState

	if manual_touch_state ~= nil and lua_helper.type_compare(manual_touch_state, CS.Oak.CharacterControllerManualTouchState) then
		manual_touch_state:RemoveDisableControl(user_party_leader)
	end

	user_party:StopAndDisableControl()

	-- 성공 여부 판단
	local success_take_picture = false
	local invalid_focus = false
	local duplicate_picture = false
	local other_condition = true

	-- 비키니 인베이더 촬영 시 예외 처리
	local bikini_exception = false

	if self.current_cameragrid_name == self.bikini_invader_cameragrid_name then
		local cur_camera_zone = field:GetZone(self.camera_bikini_zone_name)

		if cur_camera_zone:Contains(stage_camera.LookAtPosition) then
			if not self.get_photo_bikini_invader then
				self.get_photo_bikini_invader = true

				bikini_exception = true
				success_take_picture = true
			else
				duplicate_picture = true
			end
		else
			invalid_focus = true
		end
	else
		-- 이미 찍은 장소에서 찍었는지 확인
		for i = 0, self.taken_picture_cameragrid_name_list.Count - 1 do
			if self.current_cameragrid_name == self.taken_picture_cameragrid_name_list[i] then
				duplicate_picture = true

				break
			end
		end

		-- 각 사진 별로 특수 조건 만족했는지 확인
		if not duplicate_picture then
			if self.current_cameragrid_name == '3' then
				-- 3번 그리드에서는 수프 주는 인베이더가 화면에 잡히고, 수프를 준 상태여야 함
				local soup_invader = get_character(self.soup_invader_name)

				if not self:check_character_in_camera(soup_invader) or not self.give_soup then
					other_condition = false
				end
			elseif self.current_cameragrid_name == '12' then
				-- 12번 그리드에서는 슈퍼 인베이더가 화면에 잡혀야 함
				local super_invader = get_character(self.super_invader_name)

				if not self:check_character_in_camera(super_invader) or not self.super_invader_scoop then
					other_condition = false
				end
			elseif self.current_cameragrid_name == '16' then
				-- 17번 그리드에서는 코코가 화면에 잡혀야 함
				local coco = get_character(self.coco_name)

				if not self:check_character_in_camera(coco) or not self.coco_scoop then
					other_condition = false
				end
			end
		end

		-- 유효한 장소에서 찍었는지 확인
		if not duplicate_picture and other_condition then
			for i = 0, self.target_cameragrid_name_list.Count - 1 do
				-- 카메라 그리드가 유효한지 확인
				if self.current_cameragrid_name == self.target_cameragrid_name_list[i] then
					local cur_camera_zone = field:GetZone(self.camera_zone_name..self.current_cameragrid_name)

					if cur_camera_zone:Contains(stage_camera.LookAtPosition) then
						success_take_picture = true
					else
						invalid_focus = true
					end
				end
			end
		end
	end

	-- 성공 시 QTE 완료 연출
	if success_take_picture then
		if not bikini_exception then
			-- 특종 게이지 상승
			self.scoop_point = self.scoop_point + self.scoop_gauge

			-- 찍은 장소 리스트에 추가
			self.taken_picture_cameragrid_name_list:Add(self.current_cameragrid_name)

			-- 찍은 위치 리스트에 추가
			for i = 0, self.target_cameragrid_name_list.Count - 1 do
				if self.target_cameragrid_name_list[i] == self.current_cameragrid_name then
					self.photo_position_list[i] = stage_camera.LookAtPosition

					-- 스테이지 커스텀 스테이트 저장
					stage_progress:SendCustomData(i, true)
				end
			end

			-- 촬영 성공 시에는 커스텀 이벤트 Publish해서 이벤트 컨트롤러가 받도록 설정
			message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.get_photo_event..self.current_cameragrid_name }))
		else
			message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader, { self.get_photo_bikini_invader_event }))
		end
	end

	coroutine.yield(nil)

	-- 타임스케일 0
	CS.GlobalTimeManager.Instance:Mod(0, self.time_scale_key)

	-- 카메라 플래시
	music_player_util.play_stage_music({ state = 'muted' })

	music_player_util.play_sfx_one_shot('01_shutter_02')
	music_player_util.play_sfx_one_shot('01_fade_out_02')

	screen_util.fade_out_async(0.1, unity_class.color.white, 'linear')

	-- 카메라 포인터 비활성화
	self.camera_pointer:SetActive(false)

	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({0.66, 0.39, 0.12, 1}), 0)

	wait_for_unscaled_sec(0.3)

	screen_util.fade_in_async(0.1, unity_class.color.white, 'linear')

	wait_for_unscaled_sec(0.5)

	-- 성공 시 QTE 완료 연출
	if success_take_picture and not bikini_exception then
		yield_return_func(CS.Oak.CommonScreenplay.QTEComplete, 1.5)
	else
		wait_for_unscaled_sec(1)
	end

	music_player_util.play_stage_music({ state = 'field' })

	-- 타임스케일 복구
	CS.GlobalTimeManager.Instance:Unmod(self.time_scale_key)

	-- 카메라 플레이어에 고정
	local camera_to_player_dist = (stage_camera.LookAtPosition - user_party_leader.Position).magnitude
	local camera_reset_speed = 8
	local camera_reset_duration = camera_to_player_dist / camera_reset_speed

	-- 틴트 복구
	field:RemoveTint(self.tint_key, camera_reset_duration)

	-- 플레이어 설정
	camera_util.move_async(user_party_leader.Position, camera_reset_duration, { end_target = user_party_leader })

	-- 촬영 후 인베이더에게 발각된 경우
	if self.is_detected then
		self.current_camera_state = self.camera_state.idle

		if success_take_picture then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_point, self))
		end

		return
	end

	if success_take_picture then
		character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))

		if bikini_exception then
			character_util.set_anim(user_party_leader, { name = 'cast' })
			character_util.set_emotion(user_party_leader, { name = 'smile' })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_photo_bikini', skip = true })
		else
			music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })

			character_util.set_anim(user_party_leader, { name = 'success', sfx_name = '01_jump_01' })
			character_util.set_emotion(user_party_leader, { name = 'smile' })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_photo_success', skip = true })
		end

		character_util.remove_anim(user_party_leader)
		character_util.remove_emotion(user_party_leader)

		-- 특종 게이지가 일정 이상 찬 경우 발생하는 이벤트
		if self.current_event_state == self.event_state.idle and self.scoop_point >= self.scoop_point_target then
			self.current_event_state = self.event_state.scoop_complete

			character_util.set_direction(user_party_leader, 'right')
			character_util.set_anim(user_party_leader, { name = 'question', loop = false })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_0', skip = true })

			character_util.remove_anim(user_party_leader)

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_1', skip = true })

			music_player_util.play_sfx({ sfx_name = '03_dialogue_ready_01' })

			character_util.set_anim(user_party_leader, { name = 'cross_arm' })
			character_util.set_emotion(user_party_leader, { name = 'attack' })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_2', skip = true })

			character_util.set_anim(user_party_leader, { name = 'cast' })
			character_util.remove_emotion(user_party_leader)

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_3', skip = true })

			music_player_util.play_sfx({ sfx_name = '01_rustle_01' })

			character_util.set_anim(user_party_leader, { name = 'question', loop = false })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_4', skip = true })

			character_util.set_anim(user_party_leader, { name = 'nod' })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_exit_5', skip = true })

			character_util.remove_anim(user_party_leader)

			-- 암흑 마법사 텐트 지키는 NPC들 제거
			for i = 0, self.dark_magician_tent_guard_list.Count - 1 do
				character_util.set_active_state(self.dark_magician_tent_guard_list[i], 'disabled')
			end

			-- 마커 표시
			ui_quest_marker:AddQuestMarkerToPoint(self.quest_marker_name, 0, false, vector(28.5, 0, 43))
		end
	else
		character_util.set_direction(user_party_leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))

		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01' })

		if duplicate_picture then
			character_util.set_anim(user_party_leader, { name = 'bomb_idle' })
		else
			character_util.set_anim(user_party_leader, { name = 'question', loop = false })
			character_util.set_emotion(user_party_leader, { name = 'tired' })
		end

		if duplicate_picture then
			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_duplicated', skip = true })
		elseif invalid_focus then
			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_photo_focus_out', skip = true })
		elseif not other_condition then
			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_photo_something_loss', skip = true })
		else
			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_photo_fail', skip = true })
		end

		character_util.remove_anim(user_party_leader)
		character_util.remove_emotion(user_party_leader)
	end

	-- 촬영 후 인베이더에게 발각된 경우
	if self.is_detected then
		self.current_camera_state = self.camera_state.idle

		if success_take_picture then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_point, self))
		end

		return
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent))

	self.current_camera_state = self.camera_state.idle

	-- UI 다시 켬
	stage.FieldUIMiniMap:Show()

	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.PartyState)
	field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.ClassButton)

	if CS.Oak.UI.NavigationBar.Instance ~= nil then
		CS.Oak.UI.NavigationBar.Instance:Show()
	end

	self.scoop_ui.Deactivated = false

	-- 액션 버튼 복구
	field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction = nil

	user_party:ResetControllers()

	if success_take_picture and not bikini_exception then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_point, self))
	end
end

-- 카메라 화면에 해당 캐릭터가 잡혔는지 확인, y축은 무시함
function local_class:check_character_in_camera(character)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth

	local camera_pos = stage_camera.LookAtPosition

	if character.Position.x < camera_pos.x + cam_half_width and
			character.Position.x > camera_pos.x - cam_half_width and
			character.Position.z < camera_pos.z + cam_half_height and
			character.Position.z > camera_pos.z - cam_half_height then
		return true
	end

	return false
end

-- 사진 찍기 성공 시, 흥미도 증가 연출
function local_class:add_point()
	local increase_sfx = music_player_util.play_sfx({ sfx_name = '01_count_number_01', loop = true, type_priority = 'event', player_priority = 'npc' })

	self.scoop_ui:SetQuota(self.scoop_point, self.scoop_point_max, 1)

	wait_for_sec(1)

	increase_sfx:FadeOut()

	-- 특종 개수 만족 시 event state 설정
	if self.scoop_point >= self.scoop_point_max and self.current_event_state == self.event_state.idle then
		self.current_event_state = self.event_state.scoop_complete
	end
end

-- 플레이어가 순찰 중인 Guard에게 발각 시 실행되는 이벤트
function local_class:player_detected(detector, reset_marker)
	coroutine.yield(self:cancel_camera())

	local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

	user_party:StopAndDisableControl()

	field:Tint("alert_max", unity_class.color(1, 0, 0), 0.25)

	camera_util.shake(0.07, 0.25)

	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

	for i = 0, user_party.Count -1 do
		character_util.set_anim(user_party[i], { name = "embarrassed", loop = true })
		character_util.set_emotion(user_party[i], { name = "surprise", loop = true})
		if i == 0 then
			user_party[i].SpineController:Jump(0.3, 0.2)
		end
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	character_util.set_anim(detector, { name = "attack" })

	speech_bubble_util.show_speech_bubble_async(detector,
			{ key = "invader_reporter_super_invader_lab_guard_alert", skip = "true", bubble_type = "shout" })

	wait_for_sec(0.25)

	screen_util.fade_out_circular(0.5, 'linear')

	wait_for_sec(1.0)

	-- 경비병들 리셋
	message_system:Publish(CS.Oak.CustomStageEvent.Create(detector, { 'reset', 'invader_guard_detect_leader' }))

	siren:FadeOut(0.5)

	field:RemoveTint("alert_max", 0)

	local respawn_pos = field:GetMarker(reset_marker).position
	local respawn_dir = field:GetMarker(reset_marker).direction

	user_party:PositionParty(respawn_pos, respawn_dir, 0, 'linear')

	for i = 0, user_party.Count -1 do
		character_util.remove_anim(user_party[i], false)
		character_util.remove_emotion(user_party[i])
	end

	wait_for_sec(0.5)

	character_util.remove_anim(detector)
	character_util.remove_emotion(detector)

	stage_camera:Move(user_party_leader.Position, 0, user_party_leader)

	screen_util.fade_in_circular(0.5, 'linear')

	wait_for_sec(0.5)

	self.is_detected = false

	user_party:ResetControllers()
end

-- 카메라 모드 강제 종료, 다른 이벤트에서 캐릭터가 발각되거나 등의 처리
function local_class:cancel_camera()
	-- 촬영 도중 발각된 상황에서는 촬영 해제 처리를 여기서 해줘야 함
	if self.current_camera_state ~= self.camera_state.idle then
		self.camera_pointer:SetActive(false)

		message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent))

		self.current_camera_state = self.camera_state.idle

		-- UI 다시 켬
		stage.FieldUIMiniMap:Show()

		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.PartyState)
		field_ui_manager:ShowTargetUI(CS.Oak.FieldUiType.ClassButton)

		if CS.Oak.UI.NavigationBar.Instance ~= nil then
			CS.Oak.UI.NavigationBar.Instance:Show()
		end

		self.scoop_ui.Deactivated = false

		-- 액션 버튼 복구
		field_ui_manager:GetSingleUI(CS.Oak.FieldUiType.ActionButton).OverridenButtonAction = nil

		-- 이동 불가 해제
		local manual_touch_state = user_party_leader.FieldObjectController.CurrentState

		if manual_touch_state ~= nil and lua_helper.type_compare(manual_touch_state, CS.Oak.CharacterControllerManualTouchState) then
			manual_touch_state:RemoveDisableControl(user_party_leader)
		end
	end

	if self.current_camera_state == self.camera_state.enter_taking_picture then
		-- 촬영 모드 진입 중에 발각된 경우, 촬영 모드 진입 이벤트에서 현재 진행 중인 시퀀스를 종료할 때까지 대기
		while self.current_camera_state ~= self.camera_state.idle do
			coroutine.yield(nil)
		end
	elseif self.current_camera_state == self.camera_state.take_picture then
		-- 촬영 모드 상태에서 발각된 경우, 촬영 강제 종료
		local camera_to_player_dist = (stage_camera.LookAtPosition - user_party_leader.Position).magnitude
		local camera_reset_speed = 6
		local camera_reset_duration = camera_to_player_dist / camera_reset_speed

		camera_util.move_async(user_party_leader.Position, camera_reset_duration, { end_target = user_party_leader })
	elseif self.current_camera_state == self.camera_state.enter_idle then
		-- 사진 찍은 후 연출 과정에서 발각되는 경우, 사진 찍는 이벤트에서 현재 진행 중인 시퀀스를 종료할 때까지 대기
		while self.current_camera_state ~= self.camera_state.idle do
			coroutine.yield(nil)
		end
	end
end

-- 암흑 마법사 텐트 입장 시 나오는 이벤트
function local_class:enter_dark_magician_tent()
	ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	music_player_util.play_sfx({ sfx_name = '01_stage_in_teleport_01' })

	screen_util.fade_out_circular_async(0.6, 'linear')

	screen_util.fade_out_async(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular_async(0, 'linear')

	-- 화면 틴트
	field:Tint(self.tint_key_2, unity_color({0.2, 0.2, 0.2, 1}), 0)

	character_util.set_position(user_party_leader, vector(112.5, 0, 35))
	character_util.set_direction(user_party_leader, 'up')

	wait_for_sec(0.6)

	screen_util.fade_in_async(0.6, unity_class.color.black, 'linear')

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_dark_magician_0', skip = true })
end

-- 암흑 마법사 로브에 상호작용 시 발생하는 이벤트
function local_class:dark_magician_tent_event()
	speech_bubble_util.remove_bubble(user_party_leader)

	music_player_util.play_sfx({ sfx_name = '01_dark_magician_02' })

	self.dark_magician_interactable.Interactable = CS.Oak.NonInteractable.Instance

	character_util.move_to_async(user_party_leader, vector(112.5, 0, 42.5), nil, 2, true, true)

	character_util.set_direction(user_party_leader, 'up')
	character_util.set_anim(user_party_leader, { name = 'cast' })

	wait_for_sec(1)

	character_util.remove_anim(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_dark_magician_2', skip = true })

	self.current_event_state = self.event_state.see_dark_magician_tent_event
end

-- 암흑 마법사 로브 이벤트 본 뒤, 텐트 나가면 발생하는 이벤트
function local_class:exit_dark_magician_tent()
	music_player_util.play_sfx({ sfx_name = '01_stage_in_teleport_01' })

	music_player_util.play_stage_music({ state = 'field', mix = 2 })

	screen_util.fade_out_circular_async(0.6, 'linear')

	-- 화면 틴트
	field:RemoveTint(self.tint_key_2, 0)

	character_util.set_position(user_party_leader, vector(28.5, 0, 41))
	character_util.set_direction(user_party_leader, 'down')

	character_util.set_position(self.invader_knight, vector(28.5, 0, 39))
	character_util.set_direction(self.invader_knight, 'up')

	self.dark_magician.SpineController.SortingGroup.sortingOrder = 0

	wait_for_sec(0.6)

	screen_util.fade_in_circular_async(0.6, 'linear')

	music_player_util.play_sfx({ sfx_name = '01_count_01' })
	music_player_util.play_sfx({ sfx_name = '01_jump_01' })

	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_direction(user_party_leader, 'down')
	character_util.set_emotion(user_party_leader, { name = 'damaged' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_3', skip = true })

	choose_result = choose_util.play_choose_event({ { 'invader_reporter_dark_magician_4', 'brutal' },
	                                                { 'invader_reporter_dark_magician_4_1', 'mercy' } })

	if choose_result == 1 then
		music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

		character_util.jump(user_party_leader, 1, 0.5)
		character_util.set_anim(user_party_leader, { name = 'embarrassed' })

		wait_for_sec(1)
	else
		character_util.set_anim(user_party_leader, { name = 'sing' })
		character_util.set_emotion(user_party_leader, { name = 'smile' })

		wait_for_sec(1)
	end

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	character_util.set_anim(self.invader_knight, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_5', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_5_1', skip = true })

	camera_util.move(vector(29, 0, 39), 1.5)

	character_util.move_to(self.invader_knight, self.invader_knight.Position + vector(-0.5, 0, 0),
			0.5, nil, true, true)

	character_util.move_to(user_party_leader, user_party_leader.Position + vector(0.5, 0, -2),
			1.5, nil, true, true)

	wait_for_sec(0.5)

	coroutine.yield(nil)

	character_util.set_direction(self.invader_knight, 'right')

	wait_for_sec(1)

	coroutine.yield(nil)

	character_util.set_direction(user_party_leader, 'left')

	choose_result = choose_util.play_choose_event({ { 'invader_reporter_dark_magician_6', 'mercy' } })

	character_util.set_anim(self.invader_knight, { name = 'cross_arm' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_7', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01' })

	character_util.set_anim(self.invader_knight, { name = 'hurt' })
	character_util.set_emotion(self.invader_knight, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_8', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_rustle_01' })

	character_util.set_anim(self.invader_knight, { name = 'question', loop = false })
	character_util.remove_emotion(self.invader_knight)

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_9', skip = true })

	character_util.remove_anim(self.invader_knight)

	character_util.set_anim(user_party_leader, { name = 'nod' })

	wait_for_sec(1)

	character_util.remove_anim(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_10', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'bomb_idle' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_11', skip = true })

	character_util.remove_anim(self.invader_knight)

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_12', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'release', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_13', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'sing' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_dark_magician_14', skip = true })

	character_util.remove_anim(self.invader_knight)

	local exit_door = get_field_object(self.exit_door_name)

	camera_util.move_async(exit_door.Position, 1)

	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.exit_door_name, false))

	wait_for_sec(2.5)

	camera_util.move_async(user_party_leader.Position, 1, { end_target = user_party_leader })

	-- 스테이지 커스텀 스테이트 저장
	stage_progress:SendCustomData(self.stage_custom_state.meet_dark_magician, true)

	-- Stage Exit에 마커 설정
	ui_quest_marker:AddQuestMarkerToIFO(self.quest_marker_name, 0, false, self.stage_exit)
end

-- Exit로 나가면 발생하는 기사 작성 이벤트
function local_class:write_journal()
	ui_quest_marker:RemoveQuestMarker(self.quest_marker_name)

	-- 스테이지 커스텀 스테이트 저장
	stage_progress:SendCustomData(self.stage_custom_state.enter_exit, true)

	-- 순찰 NPC들 전부 정지
	for i = 0, self.guard_npcs.Count - 1 do
		character_util.set_position(self.guard_npcs[i], self.guard_npcs[i].Position)
	end

	-- 퍼플 코인 비활성화
	for i = 1, self.purple_coin_num do
		stage_util.set_fo_active_state(self.purple_coin_name..i, 'disabled')
	end

	-- 책상에 종이 아이템 추가
	local item = drop_item_util.create_item({ pos = vector(113.1, 1.5, 13.5),
	                                          itemid = self.paper_item_id, lootstate = 'dontfindlooter', notforinven = true })

	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	music_player_util.play_sfx({ sfx_name = '01_stage_in_teleport_01' })

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	screen_util.fade_out_circular_async(0.6, 'linear')

	character_util.set_position(user_party_leader, vector(112.1, 1, 13.5))
	character_util.set_direction(user_party_leader, 'right')

	wait_for_sec(0.6)

	screen_util.fade_in_circular_async(0.6, 'linear')

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_journal_0', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_clap_02' })

	character_util.set_anim(user_party_leader, { name = 'clap' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_journal_1', skip = true })

	character_util.remove_anim(user_party_leader)

	local complete_journal = false
	local keep_going = false

	-- 기사 작성 성공하거나 실패 상태에서 플레이어가 그냥 진행을 누를 때까지 재시작 가능
	while not complete_journal and not keep_going do
		screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

		-- 사진마다 기사 작성
		local photo_num = 0

		for i = 0, self.target_cameragrid_name_list.Count - 1 do
			local cur_item = self.target_cameragrid_name_list[i]

			if self.photo_position_list[i] ~= vector(999, 0, 999) then
				coroutine.yield(self:select_journal(cur_item, self.photo_position_list[i]))

				photo_num = photo_num + 1

				-- 마지막 사진은 fadeout 없음
				if photo_num < self.taken_picture_cameragrid_name_list.Count then
					screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')
				end
			end
		end

		-- 제목 정하기
		character_util.set_anim(user_party_leader, { name = 'release', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_journal_title', skip = true })

		character_util.set_anim(user_party_leader, { name = 'question', loop = false })

		local wait_for_branch = true
		local choice = 2

		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

		local rand = math.floor(unity_class.random.Range(0, 2))

		local talk_branch_1 = {
			Text = game_string:GetString('invader_reporter_journal_title_positive'),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				choice = 0
				wait_for_branch = false
			end}

		local talk_branch_2 = {
			Text = game_string:GetString('invader_reporter_journal_title_negative'),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				choice = 1
				wait_for_branch = false
			end}

		if rand == 0 then
			branches:Add(talk_branch_1)
			branches:Add(talk_branch_2)
		elseif rand == 1 then
			branches:Add(talk_branch_2)
			branches:Add(talk_branch_1)
		end

		local choice_state = CS.Oak.UI.AnswerChoiceState()
		choice_state.Branchs = branches
		choice_state.Talker = user_party_leader
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		if choice == 0 then
			self.journal_point = self.journal_point + self.positive_journal_gauge
		else
			self.journal_point = self.journal_point + self.negative_journal_gauge
		end

		-- 기사는 성공 조건에 해당하는 만큼 모았지만 선택지를 잘못 골라서 실패한 경우, 재시작 기회를 준다
		if math.abs(self.journal_point) < self.journal_max and self.scoop_point >= self.scoop_point_can_complete then
			character_util.set_anim(user_party_leader, { name = 'question', loop = false })
			character_util.set_emotion(user_party_leader, { name = 'tired' })

			wait_for_sec(1)

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_journal_restart', skip = true })

			character_util.remove_anim(user_party_leader)
			character_util.remove_emotion(user_party_leader)

			wait_for_branch = true
			choice = 0

			branches:Clear()

			talk_branch_1 = {
				Text = game_string:GetString('invader_reporter_journal_restart_positive'),
				Tendency = CS.Oak.TalkTendency.Mercy,
				Callback = function()
					choice = 0
					wait_for_branch = false
				end}

			talk_branch_2 = {
				Text = game_string:GetString('invader_reporter_journal_restart_negative'),
				Tendency = CS.Oak.TalkTendency.Brutal,
				Callback = function()
					choice = 1
					wait_for_branch = false
				end}

			branches:Add(talk_branch_1)
			branches:Add(talk_branch_2)

			choice_state = CS.Oak.UI.AnswerChoiceState()
			choice_state.Branchs = branches
			choice_state.Talker = user_party_leader
			ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

			while wait_for_branch do
				coroutine.yield(nil)
			end

			if choice == 1 then
				keep_going = true
			end
		else
			complete_journal = true
		end
	end

	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01' })

	character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })

	wait_for_sec(1.5)

	music_player_util.play_sfx({ sfx_name = '01_fade_out_01' })

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	character_util.remove_anim(user_party_leader)

	-- 책상과 의자 비활성화
	stage_util.set_fo_active_state(self.reporter_chair_name, 'disabled')
	stage_util.set_fo_active_state(self.reporter_desk_name, 'disabled')

	-- 아이템 제거
	item:ConsumeComplete()

	-- journal 점수와 모은 기사 개수에 따라 따라 노말 엔딩, 트루 엔딩 갈림
	if math.abs(self.journal_point) >= self.journal_max and self.scoop_point >= self.scoop_point_can_complete then
		if self.journal_point > 0 then
			self.is_positive_end = true
		end

		coroutine.yield(self:true_ending())
	else
		coroutine.yield(self:normal_ending())
	end
end

-- 그리드와 카메라 좌표를 받아와서 기사 작성하는 이벤트
function local_class:select_journal(cameragrid_name, pos)
	coroutine.yield(self:show_picture(pos))

	character_util.set_anim(user_party_leader, { name = 'question', loop = false })

	local wait_for_branch = true
	local choice = 2

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

	local rand = math.floor(unity_class.random.Range(0, 2))

	local talk_branch_1 = {
		Text = game_string:GetString('invader_reporter_journal_'..cameragrid_name..'_positive_choice'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			choice = 0
			wait_for_branch = false
		end}

	local talk_branch_2 = {
		Text = game_string:GetString('invader_reporter_journal_'..cameragrid_name..'_negative_choice'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			choice = 1
			wait_for_branch = false
		end}

	local talk_branch_3 = {
		Text = game_string:GetString('invader_reporter_journal_photo'),
		Tendency = CS.Oak.TalkTendency.Normal,
		Callback = function()
			choice = 2
			wait_for_branch = false
		end}

	if rand == 0 then
		branches:Add(talk_branch_1)
		branches:Add(talk_branch_2)
	elseif rand == 1 then
		branches:Add(talk_branch_2)
		branches:Add(talk_branch_1)
	end

	branches:Add(talk_branch_3)

	while choice == 2 do
		local choice_state = CS.Oak.UI.AnswerChoiceState()
		choice_state.Branchs = branches
		choice_state.Talker = user_party_leader
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		music_player_util.play_sfx({ sfx_name = '01_pen_01' })

		if choice == 0 then
			local positive_string_1 = 'invader_reporter_journal_'..cameragrid_name..'_positive_0'
			local positive_string_2 = 'invader_reporter_journal_'..cameragrid_name..'_positive_1'

			character_util.set_anim(user_party_leader, { name = 'sing' })

			wait_for_sec(1)

			character_util.remove_anim(user_party_leader)

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = positive_string_1, skip = true })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = positive_string_2, skip = true })

			self.journal_point = self.journal_point + self.positive_journal_gauge
		elseif choice == 1 then
			local negative_string_1 = 'invader_reporter_journal_'..cameragrid_name..'_negative_0'
			local negative_string_2 = 'invader_reporter_journal_'..cameragrid_name..'_negative_1'

			character_util.set_anim(user_party_leader, { name = 'sing' })

			wait_for_sec(1)

			character_util.remove_anim(user_party_leader)

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = negative_string_1, skip = true })

			speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = negative_string_2, skip = true })

			self.journal_point = self.journal_point + self.negative_journal_gauge
		else
			screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

			coroutine.yield(self:show_picture(pos))

			wait_for_branch = true
		end
	end
end

-- 사진 보여주는 이벤트
function local_class:show_picture(pos)
	camera_util.move_async(pos, 0)

	-- 타임스케일 0
	CS.GlobalTimeManager.Instance:Mod(0, self.time_scale_key)

	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({0.66, 0.39, 0.12, 1}), 0)

	wait_for_unscaled_sec(0.5)

	music_player_util.play_sfx({ sfx_name = '02_evolve_result_01' })

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	wait_for_unscaled_sec(2)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 타임스케일 복구
	CS.GlobalTimeManager.Instance:Unmod(self.time_scale_key)

	field:RemoveTint(self.tint_key, 0)

	stage_camera:SetTarget(user_party_leader)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
end

-- 노말 엔딩, 기자 실패함
function local_class:normal_ending()
	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({0.4, 0.4, 0.8, 1}), 1)

	camera_util.move_async(vector(-100, 0, 0), 0)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	field_ui_util.show_narration_async({ key = 'invader_reporter_normal_end_0' })

	if self.scoop_point < self.scoop_point_can_complete then
		field_ui_util.show_narration_async({ key = 'invader_reporter_normal_end_1_1' })
	else
		field_ui_util.show_narration_async({ key = 'invader_reporter_normal_end_1_2' })
	end

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	stage_camera:SetTarget(user_party_leader)

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
	character_util.set_position(user_party_leader, vector(112.5, 0, 14.5))
	character_util.set_direction(user_party_leader, 'right')
	character_util.set_anim(user_party_leader, { name = 'hurt', upper = true })
	character_util.set_anim(user_party_leader, { name = 'twohand_idle' })
	character_util.set_emotion(user_party_leader, { name = 'tired' })

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_2', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_hit_npc_01' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01' })

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	character_util.remove_anim(user_party_leader, true)
	character_util.set_anim(user_party_leader, { name = 'frustration', loop = false })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_3', skip = true })

	if self.scoop_point < self.scoop_point_can_complete then
		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_3_1', skip = true })
	else
		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_3_2', skip = true })
	end

	music_player_util.play_sfx({ sfx_name = '01_rustle_01' })

	character_util.set_anim(user_party_leader, { name = 'shoot' })
	character_util.set_emotion(user_party_leader, { name = 'attack' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_4', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })
	music_player_util.play_sfx({ sfx_name = '01_stage_intro_jump_01' })

	character_util.set_anim(user_party_leader, { name = 'victory_get', loop = false })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_normal_end_5', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_stage_clear_01' })

	screen_util.fade_out_circular_async(1, 'linear')

	-- 스테이지 커스텀 스테이트 저장
	stage_progress:SendCustomData(self.stage_custom_state.experience_failure, true)

	wait_for_sec(0.5)

	CS.Oak.Game.Instance:StageToLobby(false)
end

-- 트루 엔딩
function local_class:true_ending()
	-- 화면 틴트
	field:Tint(self.tint_key, unity_color({0.4, 0.4, 0.8, 1}), 1)

	camera_util.move_async(vector(-100, 0, 0), 0)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_0' })

	if self.is_positive_end then
		field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_1' })

		field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_2' })
	else
		field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_3' })

		field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_4' })
	end

	field_ui_util.show_narration_async({ key = 'invader_reporter_true_end_5' })

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	stage_camera:SetTarget(user_party_leader)

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
	character_util.set_position(user_party_leader, vector(112.5, 0, 13.5))
	character_util.set_direction(user_party_leader, 'right')
	character_util.set_anim(user_party_leader, { name = 'twohand_idle' })
	character_util.set_emotion(user_party_leader, { name = 'smile' })

	wait_for_sec(0.5)

	music_player_util.play_stage_music({ name = 'bgm_heroic_moment', state = 'event', mix = 2 })

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_positive_01' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_6', skip = true })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_7', skip = true })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_8', skip = true })

	music_player:PlaySfxOneShot('01_drinking_01')

	character_util.set_anim(user_party_leader, { name = 'dualgun_attack_right', loop = false, scale = 0.3 })

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	user_party_leader.SpineController:SetAttachment('[base]weapon2', 'glass_cup_filled_90')

	wait_for_sec(0.5)

	user_party_leader.SpineController:SetAttachment('[base]weapon2', 'glass_cup_empty_90')

	wait_for_sec(0.5)

	character_util.remove_anim(user_party_leader)

	user_party_leader.SpineController:SetAttachment('[base]weapon2', 'glass_cup_filled')

	wait_for_sec(0.1)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01' })

	character_util.set_emotion(user_party_leader, { name = 'awesome' })

	wait_for_sec(1)

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'maiden_phone')
	user_party_leader.SpineController:SetAttachment('[base]weapon2', 'empty')
	character_util.set_anim(user_party_leader, { name = 'twohand_idle' })
	character_util.set_emotion(user_party_leader, { name = 'smile' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_9', skip = true })

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02' })

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	character_util.remove_emotion(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_10', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_jump_01' })

	field:RemoveTint(self.tint_key, 1)
	field:Tint(self.tint_key_2, unity_color({0.7, 0.3, 0.3, 1}), 1)

	user_party_leader.SpineController:SetAttachment('[base]weapon1', 'empty')
	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_emotion(user_party_leader, { name = 'tired' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_11', skip = true })

	music_player_util.play_stage_music({ name = 'bgm_thriller', state = 'event', mix = 2 })

	music_player_util.play_sfx({ sfx_name = '01_dark_magician_01' })

	field:RemoveTint(self.tint_key_2, 1)
	field:Tint(self.tint_key_3, unity_color({0.8, 0.2, 0.2, 1}), 1)

	camera_util.shake(0.05, 1)
	camera_util.move(vector(112.5, 0, 13), 1)

	character_util.set_direction(user_party_leader, 'down')
	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_anim(user_party_leader, { name = 'cast' })
	character_util.set_emotion(user_party_leader, { name = 'surprise' })

	character_util.spine_set_alpha_fade(self.invader_knight, 0, 0)
	character_util.set_position(self.invader_knight, vector(112.5, 0, 9))

	character_util.spine_set_alpha_fade(self.invader_knight, 1, 0.4)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_beth, self))

	wait_for_sec(2)

	camera_util.move(vector(112.5, 0, 15.5), 2)

	character_util.set_direction(user_party_leader, 'right')

	wait_for_sec(1.5)

	character_util.set_direction(user_party_leader, 'up')
	character_util.set_anim(user_party_leader, { name = 'cast' })

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_count_01' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_true_end_12', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'sing' })
	character_util.set_emotion(self.invader_knight, { name = 'doyagao' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_true_end_13', skip = true })

	character_util.remove_anim(self.invader_knight)
	character_util.remove_emotion(self.invader_knight)

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_14', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_jump_01' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	character_util.jump(user_party_leader, 1, 0.5)
	character_util.set_anim(user_party_leader, { name = 'throw', sfx_name = '01_swing_01' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_15', skip = true })

	character_util.set_anim(self.invader_knight, { name = 'sing' })

	character_util.remove_anim(user_party_leader)
	character_util.remove_emotion(user_party_leader)

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_true_end_16', skip = true })

	music_player_util.play_sfx({ sfx_name = '01_camera_emphasize_01' })

	camera_util.resize_to(3, 0.5)

	wait_for_sec(0.5)

	character_util.set_anim(self.invader_knight, { name = 'cast2' })
	character_util.set_emotion(self.invader_knight, { name = 'doyagao' })

	speech_bubble_util.show_speech_bubble_async(self.invader_knight, { key = 'invader_reporter_true_end_17', skip = true })

	-- 암흑 마법사 등장 연출
	local shake_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_earthquake_03', loop = true, fade_in_time = 1, type_priority = 'event', player_priority = 'npc' })

	character_util.spine_set_alpha_fade(self.invader_knight, 0, 1)

	camera_util.move(vector(112.5, 0, 16), 0.3)
	camera_util.shake(0.3, 2.1)

	-- 암흑 마법사 등장
	local dark_magician_pos = vector(112.5, 0, 15.5)

	local appear_darkmagician_fx = nil
	local resholder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			resholder, 'effects/character/base_darkmagician', 'FX_appear_darkmagician', function(prefab)
				appear_darkmagician_fx = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	music_player_util.play_sfx({ sfx_name = '02_impact_lightning_02', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '02_stomp_fire_01', type_priority = 'event', player_priority = 'npc' })

	local appear_transform = appear_darkmagician_fx.transform
	appear_transform.localPosition = dark_magician_pos + vector(0, 0, 0.5)

	appear_transform:GetChild(6).gameObject:SetActive(false)

	local appear_animator = appear_transform:GetComponent(typeof(CS.UnityEngine.Animator))
	appear_animator.enabled = true
	appear_animator:Play("appear")

	appear_darkmagician_fx:SetActive(true)

	wait_for_sec(1.5)

	music_player_util.play_sfx({ sfx_name = '02_lastsnipe_01', type_priority = 'event', player_priority = 'npc' })

	wait_for_sec(0.6)

	camera_util.shake(0.7, 0.35)

	self.dark_magician.SpineController.SortingGroup.sortingOrder = 0
	self.dark_magician.SpineController.IsShadowActive = true
	self.dark_magician.SpineController:RemoveColor(self.dark_magician.Name, 0)
	character_util.set_position(self.dark_magician, dark_magician_pos)
	character_util.set_direction(self.dark_magician, 'down')
	character_util.set_anim(self.dark_magician, { name = 'appear', loop = false, next_anim = 'idle' })

	character_util.shake(user_party_leader, 0.04, 9999)
	character_util.set_anim(user_party_leader, { name = 'embarrassed' })

	character_util.set_active_state(self.invader_knight, 'disabled')

	wait_for_sec(0.35)

	music_player_util.play_stage_music({ name = 'bgm_darkmagician', state = 'event', mix = 2 })

	camera_util.shake(1, 0.07)

	wait_for_sec(0.3)

	shake_sfx:FadeOut()

	music_player_util.play_sfx({ sfx_name = '02_stomp_fire_01', type_priority = 'event', player_priority = 'npc' })

	wait_for_sec(1.5)

	music_player_util.play_sfx({ sfx_name = '01_dark_magician_follow_01', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_runaway_01' })

	camera_util.resize_to_default(1)
	camera_util.move_async(vector(112.5, 0, 16), 1)

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_18', skip = true })

	character_util.set_anim(user_party_leader, { name = 'cast' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_19', skip = true })

	speech_bubble_util.show_speech_bubble_async(self.dark_magician,
			{ key = 'invader_reporter_true_end_20', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_21', skip = true })

	if self.is_positive_end then
		character_util.set_anim(self.dark_magician, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_23', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(self.dark_magician, { name = 'darkhand_start', loop = false, next_anim = 'darkhand_start_loop' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_24', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(user_party_leader, { name = 'cast2' })

		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

		character_util.remove_anim(self.dark_magician)
		character_util.remove_emotion(self.dark_magician)

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_29', skip = true })

		character_util.set_anim(user_party_leader, { name = 'throw', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_30', skip = true })

		character_util.set_anim(user_party_leader, { name = 'walk4legs' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_31', skip = true })

		character_util.remove_anim(user_party_leader)

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_32', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(user_party_leader, { name = 'nod' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_33', skip = true })

		music_player_util.play_sfx({ sfx_name = '01_invader_laugh_01' })

		character_util.set_anim(user_party_leader, { name = 'cast' })

		character_util.set_anim(self.dark_magician, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_37', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.remove_anim(self.dark_magician)

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_38', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		camera_util.resize_to(3, 0.3)

		wait_for_sec(0.3)

		music_player_util.play_sfx({ sfx_name = '01_count_final_01' })

		character_util.jump(user_party_leader, 1, 0.5)
		character_util.set_anim(user_party_leader, { name = 'embarrassed' })

		character_util.set_anim(self.dark_magician, { name = 'cast_start', loop = false, next_anim = 'cast' })
		character_util.set_emotion(self.dark_magician, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_39', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })
	else
		character_util.set_anim(self.dark_magician, { name = 'smile' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_25', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(self.dark_magician, { name = 'darkhand_start', loop = false, next_anim = 'darkhand_start_loop' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_26', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(user_party_leader, { name = 'cast2' })

		character_util.remove_anim(self.dark_magician)
		character_util.remove_emotion(self.dark_magician)

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_34', skip = true })

		character_util.set_anim(user_party_leader, { name = 'throw', sfx_name = '01_swing_01' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_35', skip = true })

		character_util.set_anim(user_party_leader, { name = 'cast' })

		speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_36', skip = true })

		character_util.jump(user_party_leader, 1, 0.5)

		character_util.set_anim(self.dark_magician, { name = 'attack_start', loop = false, next_anim = 'attack_loop' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_36_1', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		character_util.set_anim(self.dark_magician, { name = 'attack_end', loop = false, next_anim = 'idle' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_36_2', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_36_3', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_36_4', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })

		camera_util.resize_to(3, 0.3)

		wait_for_sec(0.3)

		music_player_util.play_sfx({ sfx_name = '01_count_final_01' })

		character_util.jump(user_party_leader, 1, 0.5)
		character_util.set_anim(user_party_leader, { name = 'embarrassed' })

		character_util.set_anim(self.dark_magician, { name = 'cast_start', loop = false, next_anim = 'cast' })
		character_util.set_emotion(self.dark_magician, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(self.dark_magician,
				{ key = 'invader_reporter_true_end_36_5', offset = vector(0, 3.2, 0), auto_layout = true, bubble_direction = "ct", skip = true })
	end

	music_player_util.play_sfx({ sfx_name = '01_darkmagician_roar_01' })
	music_player_util.play_sfx({ sfx_name = '01_dark_magician_01' })
	music_player_util.play_sfx({ sfx_name = '02_beth_jump_01' })

	camera_util.resize_to(5, 1)

	screen_util.fade_out_async(1, unity_class.color.red, 'linear')

	character_util.stop_shake(user_party_leader)

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	local wait_duration = 1
	local cur_time = unity_class.time.time

	-- 행진 씬 설정
	local optimized_npcs = load_util.create_optimized_npcs_async({
		event_invader_warrior_1 = 'future_invader_warrior',
		event_invader_warrior_2 = 'future_invader_warrior',
		event_invader_warrior_3 = 'future_invader_warrior',
		event_invader_warrior_4 = 'future_invader_warrior',
		event_invader_warrior_5 = 'future_invader_warrior',
		event_invader_warrior_6 = 'future_invader_warrior',
		event_invader_warrior_8 = 'future_invader_warrior',
		event_invader_warrior_9 = 'future_invader_warrior',

		event_invader_archer_1 = 'future_invader_archer',
		event_invader_archer_2 = 'future_invader_archer',
		event_invader_archer_3 = 'future_invader_archer',
		event_invader_archer_4 = 'future_invader_archer',
		event_invader_archer_5 = 'future_invader_archer',
		event_invader_archer_6 = 'future_invader_archer',
		event_invader_archer_7 = 'future_invader_archer',
		event_invader_archer_8 = 'future_invader_archer',
		event_invader_archer_9 = 'future_invader_archer',
		event_invader_archer_10 = 'future_invader_archer',
		event_invader_archer_11 = 'future_invader_archer',
		event_invader_archer_12 = 'future_invader_archer',

		event_invader_hulk_1 = 'future_invader_hulk',
		event_invader_hulk_2 = 'future_invader_hulk',
		event_invader_hulk_3 = 'future_invader_hulk',
		event_invader_hulk_4 = 'future_invader_hulk',
		event_invader_hulk_5 = 'future_invader_hulk',
		event_invader_hulk_6 = 'future_invader_hulk',
		event_invader_hulk_7 = 'future_invader_hulk',
		event_invader_hulk_8 = 'future_invader_hulk',
		event_invader_hulk_9 = 'future_invader_hulk',
		event_invader_hulk_10 = 'future_invader_hulk',

		event_invader_guard_1 = 'future_invader_guard',
		event_invader_guard_2 = 'future_invader_guard',
		event_invader_guard_3 = 'future_invader_guard',
		event_invader_guard_4 = 'future_invader_guard',

		ally_1 = 'future_princess_event',
		ally_2 = 'future_pet',
		ally_3 = 'future_sohee',
		ally_4 = 'future_craig',
		ally_5 = 'future_lavi',
		ally_6 = 'future_trio_boss',
		ally_7 = 'future_trio_man',
		ally_8 = 'future_trio_panda',
		ally_9 = 'future_resistance_male',
	})

	local monster_list = create_generic_list(CS.Oak.Character)

	local invader_warrior_list = create_generic_list(CS.Oak.Character)
	for i = 1, 9 do
		local cur_invader

		if i ~= 7 then
			cur_invader = optimized_npcs['event_invader_warrior_'..i]
		else
			cur_invader = user_party_leader
		end

		invader_warrior_list:Add(cur_invader)
		monster_list:Add(cur_invader)
	end

	local invader_archer_list = create_generic_list(CS.Oak.Character)
	for i = 1, 12 do
		local cur_invader = optimized_npcs['event_invader_archer_'..i]

		invader_archer_list:Add(cur_invader)
		monster_list:Add(cur_invader)
	end

	local invader_hulk_list = create_generic_list(CS.Oak.Character)
	for i = 1, 10 do
		local cur_invader = optimized_npcs['event_invader_hulk_'..i]

		invader_hulk_list:Add(cur_invader)
		monster_list:Add(cur_invader)
	end

	local invader_guard_list = create_generic_list(CS.Oak.Character)
	for i = 1, 4 do
		local cur_invader = optimized_npcs['event_invader_guard_'..i]

		invader_guard_list:Add(cur_invader)
		monster_list:Add(cur_invader)
	end

	-- 인베이더 위치 설정
	for i = 0, invader_warrior_list.Count - 1 do
		if i < 4 then
			character_util.set_position(invader_warrior_list[i], vector(113.25 + i * 1.5, 0, -38))
		else
			character_util.set_position(invader_warrior_list[i], vector(112.5 + (i - 4) * 1.5, 0, -33))
		end
	end

	for i = 0, invader_hulk_list.Count - 1 do
		if i < 3 then
			character_util.set_position(invader_hulk_list[i], vector(114 + i * 1.5, 0, -37))
		elseif i < 5 then
			character_util.set_position(invader_hulk_list[i], vector(115 + (i - 3), 0, -36))
		elseif i < 8 then
			character_util.set_position(invader_hulk_list[i], vector(114 + (i - 5) * 1.5, 0, -32))
		else
			character_util.set_position(invader_hulk_list[i], vector(115 + (i - 8), 0, -31))
		end
	end

	for i = 0, invader_archer_list.Count - 1 do
		if i < 4 then
			character_util.set_position(invader_archer_list[i], vector(113.25 + i * 1.5, 0, -34))
		elseif i < 8 then
			character_util.set_position(invader_archer_list[i], vector(113.25 + (i - 4) * 1.5, 0, -29))
		else
			character_util.set_position(invader_archer_list[i], vector(113.25 + (i - 8) * 1.5, 0, -28))
		end
	end

	for i = 0, invader_guard_list.Count - 1 do
		if i < 2 then
			character_util.set_position(invader_guard_list[i], vector(113.5 + 4 * i, 0, -36))
		else
			character_util.set_position(invader_guard_list[i], vector(113.5 + 4 * (i - 2), 0, -31))
		end
	end

	-- 아군 설정
	local ally_list = create_generic_list(CS.Oak.Character)
	for i = 1, 9 do
		local cur_ally = optimized_npcs['ally_'..i]

		ally_list:Add(cur_ally)
	end

	-- 아군들 위치 설정
	local ally_pos_list = create_generic_list(unity_class.vector3)
	ally_pos_list:Add(vector(115.5, 0, -66))
	ally_pos_list:Add(vector(110, 0, -66.5))
	ally_pos_list:Add(vector(120.5, 1.2, -68.4))
	ally_pos_list:Add(vector(116, 0, -68))
	ally_pos_list:Add(vector(115, 0, -67))
	ally_pos_list:Add(vector(118, 0, -66.5))
	ally_pos_list:Add(vector(117.5, 0, -67.5))
	ally_pos_list:Add(vector(118.5, 0, -67.5))
	ally_pos_list:Add(vector(112.5, 2, -68))

	for i = 0, ally_list.Count - 1 do
		character_util.set_position(ally_list[i], ally_pos_list[i])
		character_util.set_direction(ally_list[i], 'up')
	end

	character_util.set_active_state(self.saved_party_leader, 'enabled')
	character_util.set_position(self.saved_party_leader, vector(115, 0, -68))
	character_util.set_direction(self.saved_party_leader, 'up')

	field:RemoveTint(self.tint_key_3, 0)

	camera_util.move(vector(115.5, 0, -66), duration)
	camera_util.resize_to_default(0)

	local time_diff = unity_class.time.time - cur_time

	if time_diff < wait_duration then
		wait_for_sec(wait_duration - time_diff)
	end

	screen_util.fade_in(1, unity_class.color.black, 'linear')

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '02_stomp_fire_02', type_priority = 'event', player_priority = 'npc' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	camera_util.shake(0.3, 0.5)

	speech_bubble_util.show_speech_bubble_async(ally_list[2], { key = 'futurecastle_main_a_s10_11', skip = true })

	-- 카메라 기자에게 다가가서 고정
	stage_camera:Move(user_party_leader, 3, user_party_leader)

	wait_for_sec(1)

	-- 인베이더 대군 아래로 걸어옴
	for i = 0, monster_list.Count - 1 do
		local waypoint_list = create_generic_list(unity_class.vector3)
		waypoint_list:Add(monster_list[i].Position + vector(0, 0, -26))

		character_util.set_anim(monster_list[i], { name = 'walk' })
		character_util.move_waypoint(monster_list[i], waypoint_list, 1.5, false,
				'stop', 'floor', 'down')
	end

	character_util.set_anim(user_party_leader, { name = 'unique/[emo]dead_eye', upper = true })

	wait_for_sec(2)

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_40', skip = true })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_41', skip = true })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_42', skip = true })

	speech_bubble_util.show_speech_bubble_async(user_party_leader, { key = 'invader_reporter_true_end_43', skip = true })

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 배경 제거
	message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 0), 0))

	-- 엔딩 설정
	camera_util.move_async(vector(-100, 0, 0), 0)
	camera_util.resize_to(3, 0)

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	music_player_util.play_sfx({ sfx_name = '01_count_01' })

	speech_bubble_util.show_speech_bubble_async(user_party_leader,
			{
				key = 'invader_reporter_true_end_44',
				screen_pos = vector(-130, 100),
				skip = true
			})

	music_player_util.play_sfx({ sfx_name = '01_stage_clear_01' })

	screen_util.fade_out_circular_async(1, 'linear')

	-- 스테이지 커스텀 스테이트 저장
	stage_progress:SendCustomData(self.stage_custom_state.experience_failure, false)

	wait_for_sec(0.5)

	-- 동적 로딩한 캐릭터들 전부 제거
	if optimized_npcs ~= nil and self.experimental_destroy_character == true then
		load_util.dispose_optimized_npcs(optimized_npcs)
		optimized_npcs = nil
	end

	CS.Oak.Game.Instance:StageToLobby(true)
end

-- 베스 이동 처리
function local_class:move_beth()
	local waypoint_list_invader_knight = create_generic_list(unity_class.vector3)
	waypoint_list_invader_knight:Add(self.invader_knight.Position + vector(0, 0, 3.5))
	waypoint_list_invader_knight:Add(self.invader_knight.Position + vector(1, 0, 3.5))
	waypoint_list_invader_knight:Add(self.invader_knight.Position + vector(1, 0, 5.5))
	waypoint_list_invader_knight:Add(self.invader_knight.Position + vector(0, 0, 5.5))
	waypoint_list_invader_knight:Add(self.invader_knight.Position + vector(0, 0, 6.5))

	character_util.set_anim(self.invader_knight, { name = 'walk' })
	character_util.move_waypoint_async(self.invader_knight, waypoint_list_invader_knight,
			2, 'stop', 'stop', 'floor', 'down')

	character_util.remove_anim(self.invader_knight)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PlayerDetectedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent))

	self.reporter = nil
	self.saved_party_leader = nil
	self.dark_magician = nil
	self.invader_knight = nil
	self.super_invader = nil
	self.coco = nil

	self.dark_magician_tent_guard_list = nil

	self.stage_exit = nil
	self.dark_magician_tent_entry = nil
	self.dark_magician_tent_exit = nil
	self.lorain_flower = nil

	if self.camera_pointer ~= nil then
		CS.UnityEngine.Object.Destroy(self.camera_pointer)
		self.camera_pointer = nil
	end

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	self.cameragrid_name_list = nil
	self.target_cameragrid_name_list = nil
	self.taken_picture_cameragrid_name_list = nil
	self.photo_position_list = nil

	self.cs_controller = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
