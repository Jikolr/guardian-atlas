local local_class = newclass('SubStageAmongController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--'인베이더 중에' 퀘스트 아이디
	self.among_quest_id = 312

	--event zone
	self.dark_room_event_zone = 'dark_room_enter_zone'
	self.get_elect_zone_name = 'among_s4_elect_zone'

	-- 어몽 슈트 입은 기사 가져오기
	self.get_knight = function()
		return get_character('knight_hazmat')
	end

	self.get_dark_room_lever = function()
		return get_field_object('dark_room_lever')
	end

	self.get_push_block = function()
		return get_field_object('elect_room_push_box')
	end

	--flags
	self.is_lever_pulled = false

end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

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
	start_coroutine(self.pre_setting, self)
end
--endregion

--region event
function local_class:on_event(e)

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_dark_room_lever()) then
		start_coroutine(self.interact_lever, self)
		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == 'among_lever_push' then
			self.is_lever_pulled = false
			local animator = self.get_dark_room_lever():GetComponent(typeof(CS.UnityEngine.Animator))
			message_system:Publish(CS.Oak.PowerSourceTurnOnEvent.Create('dark_room_tesla'))
			animator:Play('push')
			self.get_dark_room_lever().Interactable = CS.Oak.PublishInteractable.Create()
		end
	end
end

function local_class:on_zone_enter_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.among_quest_id)
	if type_util.is_zone_full_enter(e, user_party.Leader, self.dark_room_event_zone) and
			self.is_lever_pulled and quest_progress.InnerProgress ~= 5 then
		start_coroutine(self.toggle_dark_room_tint, self, true)
	end

	if type_util.is_zone_full_enter(e, self.get_push_block(), self.get_elect_zone_name) then
		message_system:Send(self.get_push_block(), CS.Oak.GimmickResetEvent.Instance)
	end
end

function local_class:on_zone_leave_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.among_quest_id)
	if type_util.is_zone_full_leave(e, user_party.Leader, self.dark_room_event_zone) and
			self.is_lever_pulled and quest_progress.InnerProgress ~= 5 then
		start_coroutine(self.toggle_dark_room_tint, self, false)
		return true
	end
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

function local_class:lever_pull(name)
	local lever = get_field_object(name)
	local animator = lever:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('pull')
end

function local_class:pre_setting()
	local main_quest_progress = user_progress:GetStartedQuest(self.among_quest_id)

	get_field_object('shear').transform:GetComponent(typeof(CS.Oak.ShearController)).Shear = 0

	-- 메인 캐릭터를 기사로 교체하는 함수
	local leader = self.get_knight()
	character_util.set_active_state(leader, 'enabled')
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	character_util.convert_to_manual_character(leader, param, true)

	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		else
			music_player_util.play_stage_music({ state = 'muted' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	local object_control = function()
		for i = 1, 3 do
			message_system:Publish(CS.Oak.PowerSourceTurnOffEvent.Create('meet_room_power_source_' .. i))
			self:lever_pull('meet_room_lever_' .. i)
		end
	end

	--섹션 별 시작 지점
	if main_quest_progress == nil or main_quest_progress.IsComplete or main_quest_progress.InnerProgress == 0 then
		start_stage_event('left', field:GetMarker('default_start').position, true, true)
		object_control()
	elseif main_quest_progress.InnerProgress == 1 then
		object_control()
		start_stage_event('left', field:GetMarker('meet_room_start_pos').position, true, false)
	elseif main_quest_progress.InnerProgress < 7 then
		start_stage_event('down', field:GetMarker('meet_room_start_pos').position, false, false)
	end
end

function local_class:interact_lever()
	local lever = self.get_dark_room_lever()
	local leader = user_party.Leader
	local quest_progress = user_progress:GetStartedQuest(self.among_quest_id)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local align_pos = vector_util.get_x0z(lever.Bounds.center + vector(-0.1, 0, 0))
	party_util.align_party(align_pos, 'left', 0.5)
	character_util.set_animation_n_times(leader, { name = 'attack' })
	wait_for_sec(0.3)

	music_player_util.play_sfx_one_shot('01_gear_02')
	local animator = lever:GetComponent(typeof(CS.UnityEngine.Animator))

	self.is_lever_pulled = not self.is_lever_pulled

	if self.is_lever_pulled then
		animator:Play('pull')

		wait_for_sec(0.2)
		character_util.remove_emotion(leader)
		wait_for_sec(0.3)

		message_system:Publish(CS.Oak.PowerSourceTurnOffEvent.Create('dark_room_tesla'))
	else
		animator:Play('push')

		wait_for_sec(0.2)
		character_util.remove_emotion(leader)
		wait_for_sec(0.3)

		message_system:Publish(CS.Oak.PowerSourceTurnOnEvent.Create('dark_room_tesla'))
	end

	music_player_util.play_sfx_one_shot('01_mayreel_charge_01')

	if quest_progress.InnerProgress ~= 5 then
		party_util.reset_controllers()
		field_ui_manager:Show()
		self:toggle_dark_room_tint(self.is_lever_pulled)
	else
		lever.Interactable = CS.Oak.NonInteractable.Instance
	end

end

function local_class:toggle_dark_room_tint(darken)
	local dark_room_tint_key = 'dark_room_light_off_key'

	if darken then
		music_player_util.play_sfx_one_shot('01_blackout_02')
		field:Tint(dark_room_tint_key, unity_color({ 0.2, 0.2, 0.2, 1 }), 1)
	else
		field:RemoveTint(dark_room_tint_key, 1)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
