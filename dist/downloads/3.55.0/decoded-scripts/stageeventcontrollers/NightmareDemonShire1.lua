local local_class = newclass('NightmareDemonShire1Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.operator_ui = nil

	self.scene_version = scene_util.default_version

	self.stage_event_zone_data = {
		stage_worker_event_1 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_oneline_npc_1',
				npc_2 = 's1_oneline_npc_2',

				talk_1 = 'nm_ds_main_s1_oneline_1',
				talk_2 = 'nm_ds_main_s1_oneline_2',
			}
		},
		stage_worker_event_2 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_oneline_npc_3',
				npc_2 = 's1_oneline_npc_4',

				talk_1 = 'nm_ds_main_s1_oneline_3',
				talk_2 = 'nm_ds_main_s1_oneline_4',
			}
		},
		stage_park_event_1 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_plaza_oneline_npc_18',
				npc_2 = 's1_plaza_oneline_npc_17',

				talk_1 = 'nm_ds_main_s1_plaza_oneline_18',
				talk_2 = 'nm_ds_main_s1_plaza_oneline_17',
			}
		},
		stage_park_event_2 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_plaza_oneline_npc_21',
				npc_2 = 's1_plaza_oneline_npc_22',

				talk_1 = 'nm_ds_main_s1_plaza_oneline_21',
				talk_2 = 'nm_ds_main_s1_plaza_oneline_22',
			}
		},
		stage_park_event_3 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_plaza_oneline_npc_9',
				npc_2 = 's1_plaza_oneline_npc_10',

				talk_1 = 'nm_ds_main_s1_plaza_oneline_9',
				talk_2 = 'nm_ds_main_s1_plaza_oneline_10',
			}
		},
		stage_park_event_4 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_plaza_oneline_npc_7',
				npc_2 = 's1_plaza_oneline_npc_8',

				talk_1 = 'nm_ds_main_s1_plaza_oneline_7',
				talk_2 = 'nm_ds_main_s1_plaza_oneline_8',
			}
		},
		stage_park_event_5 = {
			routine = nil,
			is_first = true,

			name = {
				npc_1 = 's1_plaza_oneline_npc_23',
				npc_2 = 's1_plaza_oneline_npc_24',

				talk_1 = 'nm_ds_main_s1_plaza_oneline_23',
				talk_2 = 'nm_ds_main_s1_plaza_oneline_24',
			}
		},
		stage_routine_zone_1 = {
			routine = false,
			is_unique = false,

			func = self.stage_park_routine
		},
		stage_routine_zone_3 = {
			routine = false,
			is_unique = false,

			func = self.stage_worker_routine
		}
	}

	self.get_hall_online_npcs = function(number)
		return get_character('s1_hall_oneline_npc_' .. number)
	end

	self.get_hall_online_invisible = function(number)
		return get_field_object('s1_secretary_interact_' .. number)
	end

	self.maid_cafe_exit_name = 'maid_cafe_exit_'
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	for _, data in pairs(self.stage_event_zone_data) do
		data.routine = false
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
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

function local_class:launch_routine()
	local main_quest_id = 406
	local quest_progress = quest_util.get_started_quest(main_quest_id)

	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)

	elseif quest_progress.InnerProgress == 0 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
		message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('default_start'),
				true, true)

	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s3_baby_room_pos'),
				true, true)

	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('down', field_util.get_marker_pos('s3_pivot_pos'),
				true, true)

	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local zone_name = e.Zone.Name

	if self.stage_event_zone_data[zone_name] ~= nil and
			type_util.is_zone_full_enter(e, get_party_leader(), zone_name) then
		local data = self.stage_event_zone_data[zone_name]

		if data.is_unique == false then
			data.is_unique = true
			data.routine = true
			start_coroutine(data.func, self)

		elseif data.is_unique == true and data.routine == false then
			data.routine = true

		elseif data.routine == nil and data.is_first == true then
			data.is_first = false

			start_coroutine(function()
				local npc_1 = get_character(data.name.npc_1)
				local npc_2 = get_character(data.name.npc_2)

				scene_util.show_normal_speech_async(npc_1, data.name.talk_1, false, { dialogue = false })
				scene_util.show_normal_speech_async(npc_2, data.name.talk_2, false, {dialogue = false})

				npc_1.Interactable.Talk = data.name.talk_1
				npc_2.Interactable.Talk = data.name.talk_2
			end)
		end
	end

	return false
end

function local_class:on_interact_event(e)
	do
		local count = 2
		for index = 1, count do
			if type_util.is_interacted_target(e, self.get_hall_online_invisible(index)) then
				local npc = self.get_hall_online_npcs(index)

				speech_bubble_util.show_speech_bubble(npc, { key = 'nm_ds_main_s2_hall_oneline_' .. index })
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	local zone_name = e.Zone.Name

	if self.stage_event_zone_data[zone_name] ~= nil and
			type_util.is_zone_full_leave(e, get_party_leader(), zone_name) then
		local data = self.stage_event_zone_data[zone_name]

		if data.routine == true then
			data.routine = false
		end
	end

	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == self.maid_cafe_exit_name .. '1' then
		music_player_util.play_stage_music({ name = 'bgm_restaurant', state = 'event' })

		return true
	end

	if e.ExitHandleName == self.maid_cafe_exit_name .. '2' then
		music_player_util.play_stage_music({ name = 'ondemand/v2_39_demonshire/audio:bgm_demonshire_main', state = 'field', mix = 0.6 })

		return true
	end

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

--region scene
function local_class:stage_park_routine()
	local npc_1 = get_character('s1_plaza_oneline_npc_3')
	local npc_2 = get_character('s1_plaza_oneline_npc_4')

	--해당 NPC들은 지정된 위치를 달리는 것을 반복하며, 하단의 대사를 번갈아가며 출력.
	--NPC 3 / ds_demon_kid_boy (자신 방향 , awesome, run) : 꺄하하! 나 잡아봐라!
	--NPC 4 / ds_vampire_kid_boy (자신 방향 , awesome, run) : 거기 서어!!!

	local npc_1_move_pos = wp_util.get_turn_once_wp(npc_1, npc_2.Position, false)
	local npc_2_move_pos = wp_util.get_turn_once_wp(npc_2, npc_1.Position, false)

	local data = self.stage_event_zone_data['stage_routine_zone_1']

	character_util.set_active_state(npc_1, 'visible')
	character_util.set_active_state(npc_2, 'visible')

	while data.routine do

		speech_bubble_util.show_speech_bubble(npc_1, { key = 'nm_ds_main_s1_plaza_oneline_3', skip = false, })

		wp_util.move(npc_1, npc_1_move_pos, 5, nil, { run = true })

		wp_util.move_async(npc_2, npc_2_move_pos, 5, nil, { run = true })

		wp_util.move(npc_1, npc_2_move_pos, 5, nil, { run = true })

		speech_bubble_util.show_speech_bubble(npc_2, { key = 'nm_ds_main_s1_plaza_oneline_4', skip = false })

		wp_util.move_async(npc_2, npc_1_move_pos, 5, nil, { run = true })

		coroutine.yield(nil)
	end

	character_util.set_active_state(npc_1, 'enabled')
	character_util.set_active_state(npc_2, 'enabled')

	data.is_unique = false
end

function local_class:stage_worker_routine()
	local npc_number_max = 15

	--모든 원라인 0.5만큼 shake 상태, 7 ~ 9 스트링키 돌려씀
	for index = 7, npc_number_max do
		local npc = get_character('s1_oneline_npc_' .. index)

		character_util.shake(npc, 0.04, 999)
	end

	local data = self.stage_event_zone_data['stage_routine_zone_3']

	while data.routine do
		coroutine.yield(nil)
	end

	for index = 7, npc_number_max do
		local npc = get_character('s1_oneline_npc_' .. index)

		character_util.stop_shake(npc)
	end

	data.is_unique = false
end

--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
