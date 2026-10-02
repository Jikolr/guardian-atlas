local local_class = newclass('NightmareLilithTower2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	self.main_quest_id = 380

	-- 섹션4 내 state(== 커스텀 스테이트)
	self.section_4_state = {
		none = 1,
		follow_neo_android = 2,
		before_interacting_with_the_vent = 3,
		first_vent_interaction = 4,
		staying_inside_the_vent = 5,
		escape_from_vent = 6,
		android_threaten_technician = 7,
		slove_android_puzzle = 8,
		follow_turing_android = 9,
		before_tracking_down = 10,
		tracking_area_1 = 11,
		tracking_area_2 = 12,
		end_tracking = 13,
		find_android_secret_meeting = 14,
		end_state = 15,
	}

	-- 저장 커스텀 스테이트 키
	self.save_state_key = 's4_save_state'

	-- 스테이지2 퀘스트 마커 이름
	self.stage_exit_marker_name = 'nightmare_lt_stage_2'

	self.custom_state_start_pos_list = {}

	self.get_exhibit_android = function (index)
		return get_character('exhibit_tower_android_' .. index)
	end

	-- 안내원 npc
	self.get_information_npc = function ()
		return get_character('information_npc')
	end

	-- 각 커스텀 스테이트에 따라 시작할 위치 마커
	-- 오딜 정렬 위치 마커
	self.get_trouble_shooter_align_pos = function(state, pos_idx)
		return field_util.get_marker_pos('s' .. state .. '_trouble_shooter_align_' .. pos_idx)
	end

	-- 리리스타워 안드로이드 위치할 쇼케이스 마커
	self.get_android_showcase_pos = function(pos_idx)
		return field_util.get_marker_pos('tower_android_showcase_' .. pos_idx)
	end

	-- 안내원 npc 위치
	self.get_information_npc_pos = function()
		return field_util.get_marker_pos('information_npc_1')
	end

	-- 벤트 출구 마커
	self.get_vent_out_pos = function()
		return field_util.get_marker_pos('vent_out')
	end

	self.get_stage_2_exit_pos = function()
		return field_util.get_marker_pos('main_quest_marker_7')
	end

	self.exhibit_tower_android_all_count = 6

	-- 타일맵 내 모든 키 도어 수
	self.key_door_all_count = 4

	self.epilogue_manager = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	self.custom_state_start_pos_list = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self:set_custom_state_start_pos_data()

	local vent_loader = get_or_create_global_table('Quest/Nightmare/LilithTower/Common/VentLoader')

	vent_loader:load_async()

	self.epilogue_manager = get_or_create_global_table('Quest/Nightmare/LilithTower/ShortEpilogue/EpilogueManager')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end
--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

function local_class:set_custom_state_start_pos_data()
	self.custom_state_start_pos_list = {
		[self.section_4_state.escape_from_vent] = {
			pos = self.get_vent_out_pos(),
			dir = 'down'
		},
		[self.section_4_state.slove_android_puzzle] = {
			pos = self.get_trouble_shooter_align_pos(2, 2),
			dir = 'right'
		},
	}
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 리리스 타워 전시용 안드로이드 셋팅
	self:set_lilithtower_exhibit_android()

	self:set_information_npc()

	self.epilogue_manager:load_async(self)

	local function play_custom_launch_stage(dir, pos, directional_stage_entry, play_stage_music)

		-- 리더를 시작 좌표로 이동
		local leader = get_party_leader()
		character_util.set_position(leader, pos)
		character_util.set_direction(leader, dir)

		-- 카메라 이동 완료 대기
		wait_for_sec(0.1)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, 'linear')
			screen_util.fade_in_circular(1, 'linear')

			yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, leader.Position,
					leader.Direction, game_string:GetString(stage.Name))

			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then

		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, false)

		self:open_door_on_main_section_4_completion()
	elseif quest_progress.InnerProgress == 3 then

		local current_section_state = quest_util.get_custom_state(quest_progress, self.save_state_key)

		if self.custom_state_start_pos_list[current_section_state] ~= nil then

			play_custom_launch_stage(
					self.custom_state_start_pos_list[current_section_state].dir,
					self.custom_state_start_pos_list[current_section_state].pos,
					true, true)

		else

			play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
					true, true)

		end

	else

		play_custom_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)

		-- 현재 섹션이 4 이상일 경우 키 도어 문 모두 오픈
		if quest_progress.InnerProgress > 3 then
			self:open_door_on_main_section_4_completion()

			if quest_progress.InnerProgress == 4 then
				if not user_progress:IsStageCleared(stage.Name) then
					quest_marker_util.add_quest_marker_to_point(self.stage_exit_marker_name,
							self.main_quest_id, true, self.get_stage_2_exit_pos())
				end
			end
		end
	end
end

function local_class:set_lilithtower_exhibit_android()
	for i = 1, self.exhibit_tower_android_all_count do
		local android = self.get_exhibit_android(i)
		local android_pos = self.get_android_showcase_pos(i)

		scene_util.set_direction(android, 'down', false)

		character_util.set_position(android, android_pos + vector(0, 0.35, 0))
		character_util.set_anim_time_scale(android, 0)

		android.CrashBehaviour = CS.Oak.WallCrashBehaviour()

		field_ui_manager:RemoveUI(android, CS.Oak.FieldUiType.CharacterStats)
	end
end

function local_class:set_information_npc()
	local npc = self.get_information_npc()

	local npc_pos = self.get_information_npc_pos(i)

	scene_util.set_direction(npc, 'up', false)

	character_util.set_position(npc, npc_pos)
end

function local_class:open_door_on_main_section_4_completion()
	for i = 1, self.key_door_all_count do
		local door = get_field_object('follow_android_door_' .. i)
		local door_animator = door:GetComponent(typeof(CS.UnityEngine.Animator))
		door_animator:Play('open')
		door.ActiveState = active_state('visible')
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
