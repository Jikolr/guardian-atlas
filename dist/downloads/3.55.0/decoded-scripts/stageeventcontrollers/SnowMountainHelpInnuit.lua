local local_class = newclass("SnowMountainHelpInnuitController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.is_innuit_rescued = false
	self.is_innuit_in_zone = false
	self.is_start_rescue = false
	self.is_star_event_done = false
	self.zone_number = 0

	self.is_get_star_piece_already = false

	self.innuit_name = "help_needed_innuit"
	self.invisible_wall_name = "help_innuit_pushable"
	self.star_piece_name = "star_piece_5"

	self.innuit_follow_coroutine = nil

	-- 플레이어가 존에 들어와 있는지 체크
	self.enter_zone = {
		false,
		false,
		false
	}

	self.success_rescue = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

function local_class:on_load_resource_routine()
	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	--message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:innuit_follow_invisible()
	local innuit = get_character(self.innuit_name)
	local wall = get_field_object(self.invisible_wall_name)

	wall.Hitbox = CS.Oak.Hitbox(vector(0.7, 1, 0.7))

	while not self.is_innuit_rescued do
		local vec = innuit.Position - wall.Position

		if vec.x ~= 0 or vec.z ~= 0 then
			character_util.stop_shake(innuit)
			self.is_start_rescue = true
			character_util.set_position(innuit, wall.Position)

			if vec.x ~= 0 then
				if vec.x > 0 then
					character_util.set_direction(innuit, "left")
				else
					character_util.set_direction(innuit, "right")
				end
			elseif vec.z ~= 0 then
				if vec.z > 0 then
					character_util.set_direction(innuit, "down")
				else
					character_util.set_direction(innuit, "up")
				end
			end

			character_util.set_anim(innuit, {name = "embarrassed", loop = true})
			character_util.set_emotion(innuit, {name = "surprise"})
		else
			if self.is_innuit_in_zone then
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rescue_success, self))
				break
			end
			character_util.remove_anim(innuit)
			character_util.set_emotion(innuit, {name = "scared"})
			character_util.shake(innuit, 0.04, 9999)
		end

		coroutine.yield(nil)
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	local innuit = get_character(self.innuit_name)

	if innuit.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		innuit.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	if self.innuit_follow_coroutine ~= nil then
		stop_coroutine(self.innuit_follow_coroutine)
		self.innuit_follow_coroutine = nil
	end

	self.enter_zone = nil

	self.cs_controller = nil
end

function local_class:on_event(e)

	local event_type = e:GetType()

	local innuit = get_character(self.innuit_name)

	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		self.is_get_star_piece_already = stage_progress:HasStarPiece(self.star_piece_name)
		if not self.is_get_star_piece_already then
			self.innuit_follow_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.innuit_follow_invisible, self))
		else
			local wall  = get_field_object(self.invisible_wall_name)

			innuit.ActiveState = active_state("disabled")
			wall.ActiveState = active_state("disabled")
		end
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		if self.is_star_event_done then
			if innuit.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
				innuit.Interactable:RemoveRelatedEvent(self.cs_controller)
			end

			character_util.set_active_state(innuit, "disabled")
		end
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, innuit) then
			speech_bubble_util.show_speech_bubble(innuit, {key = "snowmountain_help_innuit_2"})
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if self.is_get_star_piece_already then return end

	local zone_name = e.Zone.Name

	local innuit = get_character(self.innuit_name)

	if lua_helper.reference_equals(e.FieldObject, innuit) then
		if string.find(zone_name, "rescue_innuit_") then
			for i = 1, 3 do
				if zone_name == "rescue_innuit_" .. i then
					self.zone_number = i
					self.is_innuit_in_zone = true
					break
				end
			end
		end
	elseif lua_helper.reference_equals(e.FieldObject, user_party_leader) and e.FullEnter then
		--if zone_name == "help_innuit" and not self.is_start_rescue then
		--	speech_bubble_util.show_speech_bubble(innuit, {key = "snowmountain_help_innuit_1"})
		--else
		if zone_name == "rescue_innuit_reset" then
			local wall = get_field_object(self.invisible_wall_name)
			wall.Position = field:GetMarker('help_innuit').position
		end

		for i = 1, 3 do
			if zone_name == 'rescue_innuit_show_' .. i then
				self.enter_zone[i] = true

				if self.success_rescue and self.zone_number == i then
					coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.give_star_piece_scene, self))
					return
				end
			end
		end
	end
end

function local_class:on_zone_leave_event(e)
	if self.is_get_star_piece_already then return end

	local zone_name = e.Zone.Name

	if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
		for i = 1, 3 do
			if zone_name == 'rescue_innuit_show_' .. i then
				self.enter_zone[i] = false
				return
			end
		end
	end
end

function local_class:rescue_success()
	if self.innuit_follow_coroutine ~= nil then
		stop_coroutine(self.innuit_follow_coroutine)
		self.innuit_follow_coroutine = nil
	end

	local innuit_pos_list = {
		vector(39, 0, -19),
		vector(65, 0, -17),
		vector(51, 0, -34)
	}

	local innuit = get_character(self.innuit_name)
	local wall = get_field_object(self.invisible_wall_name)

	wall.ActiveState = active_state("disabled")

	wait_for_sec(0.5)

	character_util.remove_anim_and_emotion(innuit)

	wait_for_sec(0.5)

	character_util.set_emotion(innuit, {name = "smile"})

	wp_util.move_way_points_async(innuit, {waypoints = innuit_pos_list[self.zone_number], speed = 4})

	character_util.set_direction(innuit, "down")
	innuit.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	if not self.enter_zone[self.zone_number] then
		self.success_rescue = true
		return
	end

	yield_return_func(self.give_star_piece_scene, self)
end

-- 스타피스 주는 이벤트
function local_class:give_star_piece_scene()
	local innuit = get_character(self.innuit_name)
	speech_bubble_util.show_speech_bubble_async(innuit, {key = "snowmountain_help_innuit_3"})

	music_player:PlaySfxOneShot('03_dialogue_positive_01')

	speech_bubble_util.show_speech_bubble_async(innuit, {key = "snowmountain_help_innuit_2"})

	local star_piece_pos_list = {
		vector(39, 0, -20),
		vector(66, 0, -17),
		vector(52, 0, -34)
	}

	local star_piece = get_field_object(self.star_piece_name)
	star_piece.Position = star_piece_pos_list[self.zone_number]
	star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(innuit.Position + vector(0, 1, 0)))

	self.is_get_star_piece_already = true

	wait_for_sec(1.5)

	if innuit.Interactable:GetType() == typeof(CS.Oak.NPCInteractable) then
		innuit.Interactable:AddListener(self.cs_controller)
	end

	character_util.set_anim(innuit, {name = "success", loop = true})

	self.is_star_event_done = true
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
