local local_class = newclass('QueenCastle7Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- npc
	-- sector innuit section 3 마지막 등장하는 안드로이드들
	self.get_s3_event_android = function(group, num)
		if group % 2 == 1 then
			return get_character('s3_melee_android_'..group..'_'..num)
		end
		return get_character('s3_range_android_'..group..'_'..num)
	end

	-- s1 코코 방 안에서 사용된 안드로이드 1 ~ 4 (s1 마지막에 위치한 곳으로 배치를 위해 사용)
	self.get_s1_innuit_room_android = function(num)
		return get_character('s1_innuit_room_android_' .. num)
	end

	-- marker
	-- sector innuit section 3 안드로이드 몬스터 위치
	self.get_s3_event_android_pos = function(group, num, scene)
		if group % 2 == 1 then
			return field:GetMarker('s3_melee_android_pos_' .. group .. '_' .. num .. '_' .. scene).position
		end
		return field:GetMarker('s3_range_android_pos_' .. group .. '_' .. num .. '_' .. scene).position
	end

	-- sector innuit section 1에서 등장했던 안드로이드들 위치 (s1 마지막에 위치한 곳으로 배치를 위해 사용)
	self.get_s1_innuit_room_android_pos = function(scene, num)
		return field:GetMarker('s1_android_pos_' .. scene .. '_' .. num).position
	end

	-- field object
	-- 캐서린 서브 퀘스트 - 처음에 안보이는 캐서린 방으로 가는 계단 오브젝트
	self.get_event_room_enter_stair = function()
		return get_field_object('survivor_event_room_enter_stair')
	end
	self.get_event_room_exit_stair = function()
		return get_field_object('survivor_event_room_exit_stair')
	end

	-- [name]
	self.s2_switch_room_door_1_name = 'switch_room_door_1'
	self.s2_switch_room_door_2_name = 'switch_room_door_2'

	self.enter_stair_handle_name = 'survivor_event_room_enter_stair'
	self.exit_stair_handle_name = 'survivor_event_room_exit_stair'

	-- custom state key
	self.passed_escape_waterpool_event = 'pass_escape_waterpool_event'
	self.passed_switch_room_event = 'passed_switch_room_event'
	self.restart_last_door_open_event = 'restart_last_door_open_event'

	-- sector innuit section 3 안드로이드들 그룹 수, 그룹 내 인원 수
	self.s3_event_android_group_count = 4
	self.s3_event_android_member_count = 2

	-- sector innuit section 1 마지막에 배치한 안드로이드들 그룹 내 인원 수
	self.s1_event_android_member_count = 4

	-- 메인 내 섹터 코코 퀘스트 id
	self.main_sector_innuit_quest_id = 331

	self.survivor_quest_marker_name = 'qc_survivor'

	-- 메인 내 섹터 코코 퀘스트 id
	self.survivor_quest_id = 347

	-- 캐서린 서브 퀘스트 id
	self.survivor_quest_id = 347
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local mural = get_or_create_global_table('Quest/Main/QueenCastle/Common/MuralTheatreController')
	mural:load_async()

	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

--region event
function local_class:on_event(e)
	return false
end

--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:on_exit_interact_teleport_start_event(e)
	local interact_handle_name = e.ExitHandleName

	if self.enter_stair_handle_name == interact_handle_name or self.exit_stair_handle_name == interact_handle_name then
		start_coroutine(self.reset_quest_market_in_survivor_room, self, interact_handle_name)
	end

	return false
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:pre_setting()
	local main_sector_quest_progress = user_progress:GetStartedQuest(self.main_sector_innuit_quest_id)

	-- 메인 캐릭터를 기사로 교체하는 함수
	local change_leader_character = function(party_member)
		-- 기사를 리더로
		local leader = user_util.get_knight_character('knight_female', 'knight_male')
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	if main_sector_quest_progress ~= nil then
		-- 섹션1 마지막에 배치된 안드로이드들 배치
		if not main_sector_quest_progress.IsComplete then
			if main_sector_quest_progress.InnerProgress >= 1 and main_sector_quest_progress.InnerProgress <= 3 then
				self:set_waiting_android_group()
			end
		end
	end

	do
		local qc_util = get_or_create_global_table('Quest/Main/QueenCastle/Common/Util')
		qc_util:set_sector_directional_light(2)
	end

	-- 시작 연출 관리
	if main_sector_quest_progress == nil or main_sector_quest_progress.IsComplete then
		-- 도어 오픈
		self:door_open()
		-- 고정 화로 불 붙임
		self:burn_the_braziers()
		-- 코코 섹션3 안드로이드 셋팅
		self:s3_last_event_android_setting()

		-- 코코가 닫은 문 열기
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_1_name))
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_2_name))

		stage_launch_util.play_launch_stage('right', field:GetMarker('clear_stage_restart_pos').position,
				true, true)
	elseif main_sector_quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_1_name))
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_2_name))

		stage_launch_util.play_launch_stage('right', field:GetMarker('s1_stage_start_pos_1').position,
				false, false)
	elseif main_sector_quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right', field:GetMarker('s2_stage_restart_pos_1').position,
				true, true)
	elseif main_sector_quest_progress.InnerProgress == 2 then
		-- 고정 화로 불 붙임
		self:burn_the_braziers()
		local passed_escape_waterpool_event = quest_util.get_custom_state(main_sector_quest_progress, self.passed_escape_waterpool_event)
		if passed_escape_waterpool_event < 1 then
			stage_launch_util.play_launch_stage('right', field:GetMarker('s3_stage_restart_pos_1').position,
					true, true)
		elseif passed_escape_waterpool_event == 1 then
			stage_launch_util.play_launch_stage('left', field:GetMarker('s3_stage_restart_pos_2').position,
					true, true)
		end
	elseif main_sector_quest_progress.InnerProgress == 3 or main_sector_quest_progress.InnerProgress == 4 then

		if main_sector_quest_progress.InnerProgress == 4 then
			local restart_last_door_open_event = quest_util.get_custom_state(main_sector_quest_progress, self.restart_last_door_open_event)
			if restart_last_door_open_event == 1 then
				message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_1_name))
				message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.s2_switch_room_door_2_name))
			end
		end
		-- 도어 오픈
		self:door_open()
		-- 고정 화로 불 붙임
		self:burn_the_braziers()
		-- 코코 섹션3 안드로이드 셋팅
		self:s3_last_event_android_setting()

		stage_launch_util.play_launch_stage('left', field:GetMarker('s4_stage_restart_pos_1').position, true, false)
	else
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	end

	-- 서브 퀘스트 관리
	-- survivor
	local survivor_quest_progress = user_progress:GetStartedQuest(self.survivor_quest_id)
	if survivor_quest_progress == nil or survivor_quest_progress.IsComplete then
		local stake = get_field_object("breakable_stake")
		if stake.FieldObjectBehaviour:GetType() == typeof(CS.Oak.HookShotStakeBehaviour) then
			stake.FieldObjectBehaviour:SetBrokenState()
		end

		local stair = self.get_event_room_enter_stair()
		if stair ~= nil then
			stair.ActiveState = active_state('enabled')
		end
	elseif survivor_quest_progress.InnerProgress == 0 then
		local stair = self.get_event_room_enter_stair()
		if stair ~= nil then
			stair.ActiveState = active_state('disabled')
		end
	end
end

function local_class:s3_last_event_android_setting()
	local android = self.get_s3_event_android(1, 1)
	local android_pos = self.get_s3_event_android_pos(1, 1, 2)

	for i = 1, self.s3_event_android_group_count do
		for j = 1, self.s3_event_android_member_count do
			android = self.get_s3_event_android(i, j)
			android_pos = self.get_s3_event_android_pos(i, j, 2)
			character_util.set_active_state(android, 'enabled')
			character_util.set_position(android, android_pos)
		end
	end

	android = self.get_s3_event_android(1, 1)
	android_pos = self.get_s3_event_android_pos(1, 1, 2)

	scene_util.set_direction_by_args(android, { dir = 'down', sfx = false })
	scene_util.set_anim(android, self, { name = 'cast' })
	scene_util.set_emotion(android, self, { name = 'smile' })

	android = self.get_s3_event_android(2, 1)
	android_pos = self.get_s3_event_android_pos(2, 1, 2)

	scene_util.set_direction_by_args(android, { dir = 'up', sfx = false })

	android = self.get_s3_event_android(3, 1)
	android_pos = self.get_s3_event_android_pos(3, 1, 2)

	scene_util.set_direction_by_args(android, { dir = 'right', sfx = false })
	scene_util.set_anim(android, self, { name = 'bomb_idle' })
	scene_util.set_emotion(android, self, { name = 'smile' })

	android = self.get_s3_event_android(4, 1)
	android_pos = self.get_s3_event_android_pos(4, 1, 2)

	scene_util.set_direction_by_args(android, { dir = 'left', sfx = false })
	scene_util.set_anim(android, self, { name = 'bow_idle' })
	scene_util.set_emotion(android, self, { name = 'smile' })

	android = self.get_s3_event_android(1, 2)
	android_pos = self.get_s3_event_android_pos(1, 2, 2)

	scene_util.set_direction_by_args(android, { dir = 'right', sfx = false })
	scene_util.set_anim(android, self, { name = 'sleep' })
	scene_util.set_emotion(android, self, { name = 'sleep' })

	android = self.get_s3_event_android(2, 2)
	android_pos = self.get_s3_event_android_pos(2, 2, 2)

	scene_util.set_direction_by_args(android, { dir = 'right', sfx = false })
	scene_util.set_anim(android, self, { name = 'sleep' })
	scene_util.set_emotion(android, self, { name = 'sleep' })

	android = self.get_s3_event_android(3, 2)
	android_pos = self.get_s3_event_android_pos(3, 2, 2)

	scene_util.set_direction_by_args(android, { dir = 'right', sfx = false })
	scene_util.set_anim(android, self, { name = 'bomb_idle' })
	scene_util.set_emotion(android, self, { name = 'smile' })

	android = self.get_s3_event_android(4, 2)
	android_pos = self.get_s3_event_android_pos(4, 2, 2)

	scene_util.set_direction_by_args(android, { dir = 'left', sfx = false })
	scene_util.set_anim(android, self, { name = 'bow_idle' })
	scene_util.set_emotion(android, self, { name = 'smile' })

end

function local_class:door_open()
	message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
	message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true))
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('s3_puzzle_2_door', false))
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('qcastle_door_in1_1', false))
end

function local_class:set_waiting_android_group()
	for i = 1, self.s1_event_android_member_count do
		local android = self.get_s1_innuit_room_android(i)
		local android_pos = self.get_s1_innuit_room_android_pos(3, i)
		character_util.set_active_state(android, 'enabled')
		character_util.set_position(android, android_pos)
		if i >= 1 and i <= 2 then
			scene_util.set_direction_by_args(android, { dir = 'down', sfx = false })
		else
			scene_util.set_direction_by_args(android, { dir = 'up', sfx = false })
		end

		character_util.spine_set_attachment(android, '[base]weapon1', 'energy_rifle')
		character_util.set_anim(android, { name = 'rifle_idle' })
	end
end

function local_class:burn_the_braziers()
	local brazier = get_field_object('puzzle_1_brazier_1')
	command_util.execute_burn(nil, brazier, true)
	brazier = get_field_object('puzzle_1_brazier_2')
	command_util.execute_burn(nil, brazier, true)
end

function local_class:reset_quest_market_in_survivor_room(interact_handle_name)

	wait_for_sec(0.5)

	if self.enter_stair_handle_name == interact_handle_name then
		local exit_stair = self.get_event_room_exit_stair()
		quest_marker_util.add_quest_marker_to_point(self.survivor_quest_marker_name, self.survivor_quest_id, true, exit_stair.Position)
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'hide_quest_marker' }))
	elseif self.exit_stair_handle_name == interact_handle_name then
		message_system:Publish(CS.Oak.CustomStageEvent.Create(nil, { 'show_quest_marker' }))
		quest_marker_util.remove(self.survivor_quest_marker_name)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
