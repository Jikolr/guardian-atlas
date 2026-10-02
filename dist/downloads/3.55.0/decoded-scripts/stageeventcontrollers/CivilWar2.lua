local local_class = newclass('CivilWar2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	-- 메인 퀘스트 id
	self.main_quest_id = 357

	self.tint_key = 'night_field_tint'
	self.tint_color = unity_color({ 0.7, 0.7, 0.7, 1 })

	self.set_night_tint = false

	self.cw_util = nil

	self.amb_forest_night_sfx = nil
end

function local_class:load_resource()
	self.battlefield_controller = get_or_create_global_table(
			'Quest/Main/CivilWar/Main/BattleField/BattleFieldEventController')

	---@type CivilWarUtil
	self.cw_util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'main_field')
			and not self.set_night_tint then
		self:add_night_tint()
		self:start_amb_forest_night_sfx()

		return true
	elseif type_util.is_zone_full_enter(e, get_party_leader(), 'tent')
		and self.set_night_tint then
		self:remove_night_tint()
		self:fade_out_amb_forest_night_sfx()

		return true
	end
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 's11_start' then
		self:set_s11_oneline_npc(true)
		self:set_night_tint_routine()

		return true
	end

	if  e:GetParamAt(0) == 's11_sfx_start' then
		self:start_amb_forest_night_sfx()

		return true
	end

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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	self:stop_amb_forest_night_sfx()

	self.battlefield_controller = nil
	self.cw_util = nil
	self.cs_controller = nil
	self.scene = nil
end

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	self.cw_util:activate_control_directional_light(
		{
			main_field = 'main_field_light',
			tent = 'tent_light',
		}
	)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		self:set_s11_oneline_npc(false)
		self:remove_obstacles()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 7 then
		self.battlefield_controller:load_async()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			false, false)
	elseif quest_progress.InnerProgress == 8 then
		self.battlefield_controller:load_async()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
			false, false)
	elseif quest_progress.InnerProgress == 9 then
		self.battlefield_controller:load_async()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('s10_start'),
			false, false)
	elseif quest_progress.InnerProgress == 10 then
		self:remove_obstacles()
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('s11_start'),
			false, true)
	elseif quest_progress.InnerProgress == 11 then
		self:set_s11_oneline_npc(false)
		self:remove_obstacles()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
		quest_marker_util.add_auto_control('main_quest', {
			{ zone = 'main_field', target = get_field_object('exit_passage_17_2') },
			{ zone = 'tent', target = get_field_object('tent_outer') },
		})
	else
		self:set_s11_oneline_npc(false)
		self:remove_obstacles()
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	end
end

function local_class:set_s11_oneline_npc(blocking)
	local swat_npc_idx = { 8, 9, 12, 13, 16, 17 }
	for i = 1, #swat_npc_idx do
		local npc = get_character('s11_oneline_npc_' .. swat_npc_idx[i])
		character_util.spine_set_attachment(npc, '[base]weapon1', 'onehandsword_police_club')
		character_util.spine_set_attachment(npc, '[base]weapon2', 'shield_police_shield')
	end
	for i = 5, 21 do
		character_util.set_active_state(get_character('s11_oneline_npc_' .. i), 'enabled')
	end

	if blocking then
		local blocking_swat_npc_idx = { 1, 2, 3, 4, 10, 11, 22, 23 }
		for i = 1, #blocking_swat_npc_idx do
			local npc = get_character('s11_oneline_npc_' .. blocking_swat_npc_idx[i])
			character_util.set_active_state(npc, 'enabled')
			character_util.spine_set_attachment(npc, '[base]weapon1', 'onehandsword_police_club')
			character_util.spine_set_attachment(npc, '[base]weapon2', 'shield_police_shield')
		end

		character_util.set_position(get_character('s11_oneline_npc_12'),
		get_character('s11_oneline_npc_12').Position + vector(1, 0, 0))
		character_util.set_position(get_character('s11_oneline_npc_13'),
		get_character('s11_oneline_npc_13').Position + vector(-1, 0, 0))
	end

	character_util.set_emotion(get_character('s11_oneline_npc_15'), { name = 'scared' })
	character_util.set_emotion(get_character('s11_oneline_npc_18'), { name = 'scared' })
	character_util.set_emotion(get_character('s11_oneline_npc_19'), { name = 'sleep_deep' })
end

function local_class:set_night_tint_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	self:add_night_tint()
end

function local_class:add_night_tint()
	self.set_night_tint = true
	field:Tint(self.tint_key, self.tint_color, 0)
end

function local_class:remove_night_tint()
	self.set_night_tint = false
	field:RemoveTint(self.tint_key, 0)
end

function local_class:remove_obstacles()
	get_field_object('bf_cannon_rock_1').ActiveState = active_state('disabled')
	get_field_object('bf_cannon_rock_2').ActiveState = active_state('disabled')

	get_field_object('bf_cannon_obstacle_1').ActiveState = active_state('disabled')
	get_field_object('bf_cannon_obstacle_2').ActiveState = active_state('disabled')
	get_field_object('bf_cannon_obstacle_3').ActiveState = active_state('disabled')
	get_field_object('bf_cannon_obstacle_4').ActiveState = active_state('disabled')

	message_system:Publish(CS.Oak.DoorOpenEvent.Create('door_3', true))
	message_system:Publish(CS.Oak.DoorOpenEvent.Create('door_4', true))
end

function local_class:start_amb_forest_night_sfx()
	self.amb_forest_night_sfx = music_player_util.play_sfx({
		sfx_name = '01_amb_forest_night_01',
		volume = 0.6,
		fade_in_time = 2,
		loop = true })
end

function local_class:stop_amb_forest_night_sfx()
	if self.amb_forest_night_sfx ~= nil then
		music_player_util.stop_sfx(self.amb_forest_night_sfx)
		self.amb_forest_night_sfx = nil
	end
end

function local_class:fade_out_amb_forest_night_sfx()
	if self.amb_forest_night_sfx ~= nil then
		music_player_util.fade_out_sfx(self.amb_forest_night_sfx, 1)
		self.amb_forest_night_sfx = nil
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
