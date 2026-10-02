local local_class = newclass("Fox1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self:init_gliding_starpiece_event()

	self.in_reset_grid = false
	self.in_tiger_baby_grid = false
	self.in_drug_dealer_grid = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StarPieceGetEvent), 'on_starpiece_get_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	local tiger_statue = get_character('tiger_statue')
	tiger_statue.OverrideCrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	field_ui_manager:RemoveUI(tiger_statue, CS.Oak.FieldUiType.CharacterStats)
	tiger_statue:SetGiantFactor('tiger_statue', 1.5)
	tiger_statue.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.8), vector(2, 1, 0.8))

	local statue_setting = function(target)
		target.OverrideCrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		field_ui_manager:RemoveUI(target, CS.Oak.FieldUiType.CharacterStats)
		target:SetGiantFactor('statue', 1.5)
		target.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.8), vector(1, 1, 1))
	end

	statue_setting(get_character('nari_statue_in'))
	statue_setting(get_character('nari_statue_out'))

	self:load_gliding_starpiece_event()
end

function local_class:need_on_launch()
	local main_quest_id = 60009

	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	return quest_progress.InnerProgress < 13
end

function local_class:on_launch(start_point_name)
	local main_quest_id = 60009

	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self, quest_progress.InnerProgress))
end

function local_class:on_launch_routine(num)
	local nari_3 = get_character('nari')

	screen_util.fade_out_async(0, unity_class.color.black, CS.Oak.Interpolations.Linear)

	screen_util.fade_out_circular(0, CS.Oak.Interpolations.Linear)

	coroutine.yield(nil)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)

	screen_util.fade_in_circular(1, CS.Oak.Interpolations.Linear)

	if num == 9 then
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(-1, 0, -0.5),
		CS.Oak.Direction.Left, game_string:GetString(stage.Name)))
	elseif num >= 10 and num <= 12 then
		coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(vector(7.5, 0, -86),
		CS.Oak.Direction.Right, game_string:GetString(stage.Name)))
	else
		character_util.set_position(nari_3, user_party_leader.Position + vector(3, 0, 0))
	end

	user_party:ResetControllers()
	field_ui_manager:Show()
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StarPieceGetEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self:dispose_gliding_starpiece_event()

	self.crowd_buzz_sfx = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	self:setting_gliding_starpiece_event()

	local main_quest_id = 60009
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if quest_progress.InnerProgress ~= 12 then
		character_util.convert_to_party_member(get_character('nari'), user_party, true)
	end

	self.kid_positions = {}
	for i = 1, 4 do
		local kid = get_character('after_kid_play_' .. i)
		table.insert(self.kid_positions, kid.Position)
	end

	self.baby_tiger_positions = {}
	for i = 4, 6 do
		local tiger = get_character('cave_tiger_baby_' .. i)
		table.insert(self.baby_tiger_positions, tiger.Position)
	end

	return false
end

function local_class:on_starpiece_get_event(_)
	self:on_get_gliding_starpiece()

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party_leader, 'after_tiger_zone') then
		self.crowd_buzz_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_crowd_buzz_01', loop = true, fade_in_time = 2 })
		return true
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, 'forest_zone_1') or
			type_util.is_zone_full_enter(e, user_party.Leader, 'forest_zone_2') then
		if lua_helper.reference_equals(user_party.Leader, get_character('tiger_player')) then
			user_party.Leader.FieldObjectController.CurrentState:RequestDisableControl(user_party.Leader, CS.Oak.DisabledControls.Interact)
			return true
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party_leader, 'after_tiger_zone') then
		self.crowd_buzz_sfx:FadeOut(2)
		return true
	end

	if type_util.is_zone_full_leave(e, user_party.Leader, 'forest_zone_1') or
			type_util.is_zone_full_leave(e, user_party.Leader, 'forest_zone_2') then
		if lua_helper.reference_equals(user_party.Leader, get_character('tiger_player')) then
			user_party.Leader.FieldObjectController.CurrentState:RemoveDisableControl(user_party.Leader)
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if type_util.is_player_enter_to_cam_grid(e, 'ResetGrid') then
		self.in_reset_grid = true
		for i = 1, 4 do
			local kid = get_character('after_kid_play_' .. i)
			kid.Position = self.kid_positions[i]
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.after_kids_running, self, kid, i))
		end
	elseif type_util.is_player_enter_to_cam_grid(e, 'tiger_baby_grid') then
		self.in_tiger_baby_grid = true
		for i = 4, 6 do
			local tiger = get_character('cave_tiger_baby_' .. i)
			tiger.Position = self.baby_tiger_positions[i - 3]
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.baby_tigers_running, self, tiger))
		end
	elseif type_util.is_player_enter_to_cam_grid(e, 'drug_dealer_grid') then
		self.in_drug_dealer_grid = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.after_drug_dealer, self))
	end
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'ResetGrid') then
		self.in_reset_grid = false
	elseif type_util.is_player_leave_to_cam_grid(e, 'tiger_baby_grid') then
		self.in_tiger_baby_grid = false
	elseif type_util.is_player_leave_to_cam_grid(e, 'drug_dealer_grid') then
		self.in_drug_dealer_grid = false
	end
end

function local_class:baby_tigers_running(target)
	local center_pos = field:GetMarker('cave_tiger_baby_center').position
	while self.in_tiger_baby_grid do
		character_util.move_waypoint_async(target, {
			center_pos + vector(-1, 0, 1),
			center_pos + vector(-1, 0, -1),
			center_pos + vector(2, 0, -1),
			center_pos + vector(2, 0, 1)
		}, 4, true)
		coroutine.yield(nil)
	end
end

function local_class:after_kids_running(target, i)
	local center_pos = field:GetMarker('after_kids_center').position
	local round = 0
	while self.in_reset_grid do
		character_util.move_waypoint_async(target, {
			center_pos + vector(-1, 0, 1),
			center_pos + vector(-1, 0, -1),
			center_pos + vector(2, 0, -1),
			center_pos + vector(2, 0, 1)
		}, 5, true)

		if round > i and i > 2 then
			local num = i - 2
			speech_bubble_util.show_speech_bubble(target, {key = 'fox_3_after_kid_' .. num, skip = false, life_time = 1})
			round = 0
		end

		if i == 1 then
			self.after_kids_align()
		end
		round = round + 1
		coroutine.yield(nil)
	end
end

function local_class:after_kids_align()
	local targets = {
		get_character('after_kid_play_' .. 1),
		get_character('after_kid_play_' .. 2),
		get_character('after_kid_play_' .. 3),
		get_character('after_kid_play_' .. 4),
	}
	local center_pos = field:GetMarker('after_kids_center').position
	local poss = {
		center_pos + vector(2, 0, 1),
		center_pos + vector(2, 0, -1),
		center_pos + vector(0, 0, -1),
		center_pos + vector(-1, 0, 0)
	}

	for i, target in ipairs(targets) do
		target.Position = poss[i];
	end
end

function local_class:after_drug_dealer()
	local dealer = get_character('after_drug_dealer')
	local hustler = get_character('after_drug_hustler')
	while self.in_drug_dealer_grid do
		wait_for_sec(1)
		speech_bubble_util.show_speech_bubble_async(dealer, {key = 'fox_3_after_drug_1', skip = false, life_time = 1.5})
		wait_for_sec(0.5)
		speech_bubble_util.show_speech_bubble_async(dealer, {key = 'fox_3_after_drug_2', skip = false, life_time = 1.5})
		coroutine.yield(nil)
		wait_for_sec(1)
		-- 으랴압!
		speech_bubble_util.show_speech_bubble_async(hustler, {key = 'fox_3_after_drug_3', skip = false, life_time = 1.5})
	end
end

--region 나무 위 스타피스 이벤트

function local_class:init_gliding_starpiece_event()
	self.gliding_starpiece_effect = nil
end

function local_class:load_gliding_starpiece_event()
	local pool = unity_object_pool.GetOrCreate("FX_starpiece_in_character")
	coroutine.yield(CS.Oak.UnityObjectPool.WaitUntilLoaded(pool))
end

function local_class:setting_gliding_starpiece_event()
	if not stage_progress:HasStarPiece('jump_gliding_starpiece') then
		local center = field:GetZone('jump_gliding_starpiece_zone').Bounds.center
		self.gliding_starpiece_effect = unity_object_pool.GetOrCreate("FX_starpiece_in_character"):Instantiate(center)
	end
end

function local_class:on_get_gliding_starpiece()
	if stage_progress:HasStarPiece('jump_gliding_starpiece') then
		if self.gliding_starpiece_effect ~= nil then
			self.gliding_starpiece_effect:Dispose()
			self.gliding_starpiece_effect = nil
		end
	end
end

function local_class:dispose_gliding_starpiece_event()
	if self.gliding_starpiece_effect ~= nil then
		self.gliding_starpiece_effect:Dispose()
	end

	self.gliding_starpiece_effect = nil
end

--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}