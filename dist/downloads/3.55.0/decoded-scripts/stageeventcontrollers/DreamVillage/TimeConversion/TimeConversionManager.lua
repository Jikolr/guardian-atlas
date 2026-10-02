---@class TimeConversionManager
local local_class = newclass('TimeConversionManager')

--region StageEventController

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 시간전환이 가능한 상태인지 여부
	self.is_use_time_conversion = true

	-- 해당 기능이 활성화 되었는지 여부
	self.is_system_active = true

	-- 버튼 아이콘 모양
	self.button_icon_name = 'actbtn_ic_act_flute.png'

	-- 피리 아이템 이름
	self.pipe_item_name = 'gimmick_flute'

	--TODO: 많아지면 Constant로 빼자
	-- 밤/낮 전환 이펙트 이름
	self.conversion_effect = function()
		return unity_object_pool.GetOrCreate('fx_dv_flute_sing')
	end

	self.is_paused = false

	-- 버튼 ui 타입
	self.ui_type = CS.Oak.FieldUiType.CustomButton1

	-- 인게임 시간대
	self.time_zone = {
		daylight = 1,
		night = 2,
	}

	self.music_names = {
		[self.time_zone.daylight] = 'ondemand/v3_10_dreamvillage/preload:bgm_dreamvillage_day',
		[self.time_zone.night] = 'ondemand/v3_10_dreamvillage/audio:bgm_dreamvillage_night'
	}

	self.conversing_state = {
		none = 1,
		wait = 2,
		playing = 3,
	}

	self.cur_conversing_state = self.conversing_state.none

	-- 현재 인게임 시간대
	self.current_time_zone = self.time_zone.daylight

	--TODO: 피리로 밤/낮 바꾼 후 연출 진행할 때 사용
	-- 피리를 불고 난 뒤 컨트롤 리셋해줄건지 여부
	self.is_reset_control = true

	-- 밤/낮 전환 애니메이터
	self.animator_list = nil

	-- 밤/낮 전환 애니메이션 이름들
	self.animation_name_list = nil

	-- 밤/낮 전환 기능이 비활성화되는 존 데이터
	self.disabled_zone_data = {}

	-- 섹션에서 등록하는 callback list
	self.event_callback_list = {}

	-- 비네트 효과
	self.is_use_vignette = true
	self.vignette = nil
	self.disable_vignette_grid_list = {}
	self.is_active_vignette = true

	self.dv_sp_manager = nil

	self.target_quest_id = 0

	-- bgm 전환 효과를 줄 것인지
	self.is_bgm_transition = true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestClearedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.PauseEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GamepadConnectedEvent))

	if self.vignette ~= nil then
		CS.Utils.SafeDestroy(self.vignette)
	end

	self.quest_progress = nil
	self.cs_controller = nil
	self.event_callback_list = nil
	self.animation_name_list = nil
	self.disabled_zone_data = nil
	self.animator_list = nil
	self.dv_sp_manager = nil
end

function local_class:load_resource()
	local path = 'stageeventcontrollers/DreamVillage/TimeConversion/Constant'
	local constant_data = get_or_create_global_variable(path)[stage.Name]

	-- 애니메이터
	self.animator_list = {}

	local animator_fo = get_field_object(constant_data.animator_fo_name)
	local animator = animator_fo:GetComponent(typeof(CS.UnityEngine.Animator))
	table.insert(self.animator_list, animator)

	-- 밤/낮 전환 애니메이션 이름
	self.animation_name_list = constant_data.animation_name
	self.disabled_zone_data = lua_helper.get_or_default(constant_data.disabled_zone_data, {})
	self.disable_vignette_grid_list = lua_helper.get_or_default(constant_data.disable_vignette_grid_list, {})
	self.is_use_vignette = lua_helper.get_or_default(constant_data.is_use_vignette, true)

	self.current_time_zone = constant_data.start_time_index

	self.conversion_effect()

	self.target_quest_id = constant_data.quest_id

	do
		-- Event 그룹 관리 매니저 로드
		path = 'stageeventcontrollers/DreamVillage/TimeConversion/ElementController'

		local is_create
		is_create, self.element_controller = global_table_util.try_create(path)
		self.element_controller:initialize(self, constant_data)
	end

	-- 음향 관련 사전 로드


	music_player_util.preload_music_async(self.music_names[self.time_zone.night])
	music_player_util.pre_set_transition_music(self.music_names[self.time_zone.night])

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseStartEvent), 'on_pause_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.PauseEndEvent), 'on_pause_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.WatchingCameraGridChangedEvent), 'on_watching_camera_grid_changed_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_event(_)
	return false
end

--endregion StageEventController

--region Event

function local_class:on_stage_start_event(_)
	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadEvent), 'on_gamepad_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestClearedEvent), 'on_quest_cleared_event')
	message_system:Subscribe(self, typeof(CS.Oak.GamepadConnectedEvent), 'on_gamepad_connected_event')

	local _, dv_sp_manager = global_table_util.try_create_dream_village_screenplay_manager()
	self.dv_sp_manager = dv_sp_manager

	self.cur_conversing_state = self.conversing_state.wait

	self:set_button_active_state()

	return true
end

function local_class:on_stage_loaded_event(_)
	self.quest_progress = user_progress:GetStartedQuest(self.target_quest_id)

	if self.is_use_vignette then
		self.vignette = CS.Oak.FieldUIVignette.Create()
		self.vignette.transform.parent = stage_camera.Transform
		self.vignette.gameObject.layer = CS.UnityEngine.LayerMask.NameToLayer('Default')

		self.vignette:ShowCustom()
		self.vignette.Color = unity_color({ 0, 0, 0, 0 })
		self.vignette.Radius = 3
		self.vignette.Intensity = 1

		self.vignette.gameObject:SetActive(false)
	end

	local change_layer = stage.StageGameObject.transform:Find(stage.Name .. '/change/')

	if change_layer ~= nil then
		for idx = 0, change_layer.childCount - 1 do
			local animator = change_layer:GetChild(idx):GetComponent(typeof(CS.UnityEngine.Animator))

			if not is_unity_null(animator) then
				table.insert(self.animator_list, animator)
			end
		end
	end

	self:set_stage_animation(1)
	self.element_controller:setting_stage_loaded(self.quest_progress)
end

function local_class:on_battle_start_event(_)
	if not self.is_use_time_conversion then
		return false
	end

	self:conversion_active_setting(false)
	return true
end

function local_class:on_battle_end_event(_)
	self:conversion_active_setting(true)
	return true
end

function local_class:on_touch_event(e)
	if not self:button_use_check() then
		return false
	end

	if e.TouchEventType == CS.Oak.TouchEventType.CustomFunction1TouchDown then
		start_coroutine(self.changed_time_conversion, self, false)
		return true
	end

	return false
end

function local_class:on_gamepad_event(e)
	if not self:button_use_check() then
		return false
	end

	if e.GamepadEventType == CS.Oak.GamepadEventType.RightShoulderDown then
		start_coroutine(self.changed_time_conversion, self, false)
		return true
	end

	return false
end

function local_class:is_disabled_zone(data)
	if self.quest_progress == nil or data == nil then
		return true
	end

	local cur_progress = data.progress

	if cur_progress == nil then
		return true
	end

	return self.quest_progress.InnerProgress >= cur_progress
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	for zone_name, data in pairs(self.disabled_zone_data) do
		if e.Zone.Name == zone_name and lua_helper.reference_equals(e.FieldObject, leader) and
				self:is_disabled_zone(data) then
			self.disabled_zone_data[zone_name].is_in_zone = true
			self:conversion_active_setting(false)
			return true
		end
	end

	return false
end

function local_class:is_all_leave_zone()
	if self.disabled_zone_data == nil then
		return true
	end

	for _, data in pairs(self.disabled_zone_data) do
		if data.is_in_zone == true then
			return false
		end
	end

	return true
end

function local_class:on_zone_leave_event(e)
	local leader = get_party_leader()

	if self.is_use_time_conversion then
		return false
	end

	for zone_name, _ in pairs(self.disabled_zone_data) do
		if type_util.is_zone_full_leave(e, leader, zone_name) then
			self.disabled_zone_data[zone_name].is_in_zone = false

			if self:is_all_leave_zone() then
				self:conversion_active_setting(true)
				return true
			end
		end
	end

	return false
end

function local_class:on_quest_progressed_event(_)
	self.element_controller:quest_condition_changed()
	return true
end

function local_class:on_quest_cleared_event(_)
	self.element_controller:quest_condition_changed()
	return true
end

function local_class:on_watching_camera_grid_changed_event(e)
	if e.CameraGrid == nil or not self.is_use_vignette then
		return false
	end

	local grid_name = e.CameraGrid.name

	local is_disabled_grid = table_util.contain_value(self.disable_vignette_grid_list, grid_name)

	-- 현재 활성 여부와 비활성화 그리드 여부랑 같으면 return ( ex) 비네트가 활성화된 상태에서 비활성화 존에 들어왔으면 아래로 내려감
	if self.is_active_vignette ~= is_disabled_grid then
		return
	end

	self.is_active_vignette = is_disabled_grid == false
	self.vignette.gameObject:SetActive(self.is_active_vignette)

	return true
end

function local_class:on_pause_start_event(_)
	self.is_paused = true
	return true
end

function local_class:on_pause_end_event(_)
	self.is_paused = false
	return true
end

function local_class:on_gamepad_connected_event(_)
	self:set_game_pad_icon()
end

--endregion Event

--region 버튼 관련

--- 버튼 활성화 비활성화
function local_class:set_button_active_state()
	local leader = get_party_leader()

	if not self.is_use_time_conversion then
		field_ui_manager:RemoveUI(leader, self.ui_type)
		return
	end

	field_ui_manager:SetUI(leader, self.ui_type)
	local button = field_ui_manager:GetUI(leader)[self.ui_type]
	button:SetIcon(self.button_icon_name)

	if CS.Oak.Game.Instance.InputManager.GamepadEnabled then
		self:set_game_pad_icon()
	end
end

function local_class:set_game_pad_icon()
	local leader = get_party_leader()

	local ui_list = field_ui_manager:GetUI(leader)
	local has_value, button = ui_list:TryGetValue(self.ui_type)

	if has_value == false then
		return
	end

	local icon = button.gameObject:GetComponentInChildren(typeof(CS.Oak.FieldUIGamepadIcon))

	if icon == nil then
		return
	end

	icon.TargetKey = CS.GamepadKey.RightShoulder
	icon:Set()
end

--- 버튼 비활성화 세팅
---@param is_active boolean 버튼 활성화 여부
function local_class:conversion_active_setting(is_active)
	if self.is_system_active == false or self.is_use_time_conversion == is_active then
		return false
	end

	self.is_use_time_conversion = is_active
	self:set_button_active_state()
end

--- 버튼 사용가능 여부
function local_class:button_use_check()
	if self.is_paused then
		return false
	end

	if self.cur_conversing_state ~= self.conversing_state.wait then
		return false
	end

	if not self.is_use_time_conversion then
		return false
	end

	local leader = get_party_leader()
	local current_action_state = leader.FieldObjectBehaviour.CurrentActionState
	local field_object_current_state = leader.FieldObjectBehaviour.CurrentState
	local character_current_state = leader.CharacterBehaviour.CurrentState
	local controller_current_state = leader.FieldObjectController.CurrentState

	if lua_helper.type_compare(current_action_state, CS.Oak.CharacterHoldUpState) or
			lua_helper.type_compare(current_action_state, CS.Oak.CharacterThrowState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterJumpState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterForcedDashState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.CharacterUnitPushState) or
			lua_helper.type_compare(field_object_current_state, CS.Oak.HeroDeadState) or
			lua_helper.type_compare(character_current_state, CS.Oak.CharacterHookShotState) or
			lua_helper.type_compare(controller_current_state, CS.Oak.CharacterControllerInteractState) or
			lua_helper.type_compare(controller_current_state, CS.Oak.CharacterControllerScreenplayState) then

		return false
	end

	return true
end

--endregion 버튼 관련

--- 피리를 불어서 시간 전환 시작
function local_class:changed_time_conversion(forced)
	if not forced then
		if not self.dv_sp_manager:try_proceed_request(self.cs_controller) then

			return
		end
	end

	self.cur_conversing_state = self.conversing_state.playing

	local leader = get_party_leader()
	character_util.cancel_all_battle_actions(leader, false)

	sp_util.enter_scene({ stop_party = false })

	character_util.stop(leader)

	music_player_util.play_sfx_one_shot('01_event_dv_01', 0.7)
	self.conversion_effect():Instantiate(leader.Position)

	character_util.spine_set_attachment(leader, '[base]weapon1', self.pipe_item_name)
	scene_util.set_direction(leader, 'down', false)
	scene_util.set_emotion(leader, self, 'sleep_deep')
	scene_util.set_anim(leader, self, 'rifle_idle')

	-- 밤/낮 상태 변화
	local target_time_zone = self.current_time_zone == self.time_zone.daylight and
			self.time_zone.night or self.time_zone.daylight

	self:changing_elements(target_time_zone)

	-- 무기 원복 컨트롤 돌려줌
	leader:RefreshWeaponAttachments()
	character_util.remove_anim_and_emotion(leader)

	-- 컨트롤 돌려주지 않아야 하는 상태라면 (ex) 피리 불고 난 뒤 퀘스트 연출 시작) exit_scene 스킵
	if self.is_reset_control then
		sp_util.exit_scene(nil, leader)
	end

	self.cur_conversing_state = self.conversing_state.wait

	if not forced then
		self.dv_sp_manager:remove_request(self.cs_controller)
	end

	self:changed_elements()
end

--- 밤/낮 요소들을 변경해주는 함수
---@param target_time_zone number 변경될 시간대
function local_class:changing_elements(target_time_zone)
	if self.current_time_zone == target_time_zone then
		return
	end

	-- 밤/낮 상태 변화
	self.current_time_zone = target_time_zone

	-- 밤/낮 변화 이벤트 publish
	message_system:PublishSync(CS.Oak.TimeConversionChangingEvent.Create(self:is_daylight()))

	if self.is_bgm_transition then
		self:change_field_bgm()
	end

	-- 애니메이션 전환
	self:set_stage_animation()

	-- 비네트 효과 세팅
	self:set_vignette()

	-- 등록된 이벤트 재생
	self:process_event_callback()

	-- 캐릭터 / 기믹 전환
	self.element_controller:conversion()

	if self.is_bgm_transition then
		music_player_util.wait_for_transition_completion()
	end
end

function local_class:change_field_bgm()
	music_player_util.play_stage_music_with_transition({
		state = 'field',
		mix = 2.5,
		volume = 1,
		bgm_name = self.music_names[self.current_time_zone],
		fade_out_interpolation = interpolations_constants.ease_out_sine,
		is_equal_gain = true,
	})
end

function local_class:changed_elements()
	self.element_controller:conversion_complete()

	-- 변경 완료 이벤트 publish
	message_system:PublishSync(CS.Oak.TimeConversionChangedEvent.Instance)
end

--- 스테이지 밤/낮 전환 애니메이션 세팅
---@param normalized_time number 애니메이션 노멀라이즈 시간 0이면 기본 1이면 바로 애니메이션 완료
function local_class:set_stage_animation(normalized_time)
	local animation_name = self.current_time_zone == self.time_zone.daylight and
			self.animation_name_list.daylight or self.animation_name_list.night

	normalized_time = lua_helper.get_or_default(normalized_time, 0)

	for _, animator in ipairs(self.animator_list) do
		animator:Play(animation_name, -1, normalized_time)
	end
end

function local_class:set_vignette()
	if self.vignette == nil then
		return
	end

	local color = self.vignette.Color
	local is_daylight = self:is_daylight()

	if self.is_active_vignette and not is_daylight then
		self.vignette.gameObject:SetActive(true)
	end

	local start_alpha = is_daylight and 1 or 0
	local end_alpha = is_daylight and 0 or 1

	start_coroutine(function()
		local time_passed = 0
		local duration = 1.9

		while time_passed <= duration do
			time_passed = time_passed + unity_class.time.deltaTime

			local progress = unity_class.mathf.Clamp01(time_passed / duration)
			color.a = unity_class.mathf.Lerp(start_alpha, end_alpha, progress)

			self.vignette.Color = color

			coroutine.yield(nil)
		end

		if self.is_active_vignette and is_daylight then
			self.vignette.gameObject:SetActive(false)
		end
	end)
end

--- 등록된 콜백들을 처리
function local_class:process_event_callback()
	local is_daylight = self:is_daylight()

	for _, callback in pairs(self.event_callback_list) do
		self:active_event_callback(is_daylight, callback)
	end
end

--- 등록된 콜백을 밤/낮에 따라 재생
---@param is_daylight boolean 밤/낮 어디쪽 콜백을 재생할지 여부
---@param callback_data function 재생할 콜백
function local_class:active_event_callback(is_daylight, callback_data)
	if is_daylight then
		callback_data.daylight()
		return
	end

	callback_data.night()
end

--region 콜백 등록

--- 콜백 등록 (보통 섹션에서 밤/낮 때 처리할 것이 있다면 등록)
---@param key string 등록할 콜백 키, 나중에 callback 해제 할 때 필요
---@param callback_data function 등록할 콜백 데이터
---@param is_renew_once boolean 콜백 등록 한 후 콜백을 한번 재생해줄지 여부 (첫 등록할 때 호출이 필요하면 true)
function local_class:register_callback(key, callback_data, is_renew_once)
	self.event_callback_list[key] = callback_data

	if not is_renew_once then
		return
	end

	self:active_event_callback(self:is_daylight(), callback_data)
end

--- 콜백 해제 (섹션종료나 섹션 내에서 다음 state로 넘어갈 때 제거 할 때 사용)
---@param key string 제거할 콜백 키
function local_class:unregister_callback(key)
	self.event_callback_list[key] = nil
end

--endregion 콜백 등록

--region Element 가져 오기

--- 이벤트 그룹 가져오기
---@param is_daylight boolean 밤/낮 어디쪽 그룹을 가져올 것인지 여부
---@param group_name string 그룹 이름
function local_class:get_group(group_name)
	return self.element_controller:get_group(group_name)
end

--endregion Element 가져 오기

--- 현재 시간대가 낮인지 여부
function local_class:is_daylight()
	return self.current_time_zone == self.time_zone.daylight
end

return local_class
