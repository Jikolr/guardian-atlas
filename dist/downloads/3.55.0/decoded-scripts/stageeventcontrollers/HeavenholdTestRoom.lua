local local_class = newclass('HeavenholdTestRoomController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	--region FieldObject
	--나레이션 인터렉트 fo
	self.get_interact_wall = function(number)
		return get_field_object('interact_item_' .. number)
	end

	--문
	self.get_interact_door = function(number)
		return get_field_object('interact_door_' .. number)
	end

	--브레이커블
	self.get_breakable_pot = function(number)
		return get_field_object('breakable_pot_' .. number)
	end

	self.exit_name = 'door_exit_'
	--endregion FieldObject

	--region Marker
	self.get_interact_pos = function(number)
		return field_util.get_marker_pos('interact_pos_' .. number)
	end
	--endregion Marker

	--region Sprite
	self.sprite = {
		sprite_info = {
			paper = 21148,
			magi_times = 21174,
			diary = 21175,
		},
		sprite_table = {},
		create = function(this, name, pos, item_id, target_pos, scale, showoncharacter)
			scale = lua_helper.get_or_default(scale, 1)
			showoncharacter = lua_helper.get_or_default(showoncharacter, false)

			local item = drop_item_util.create_item(
					{ pos = pos, target = target_pos, itemid = item_id, notforinven = true, showoncharacter = showoncharacter,
					  lootstate = 'dontfindlooter', sprscale = scale })

			this.sprite_table[name] = item

			return item
		end,
		dispose = function(this, name)
			if this.sprite_table[name] then
				this.sprite_table[name]:ConsumeComplete()
				this.sprite_table[name] = nil
			end
		end,
		dispose_all = function(this)
			if this.sprite_table then
				for name, value in pairs(this.sprite_table) do
					if name then
						this:dispose(name)
					end
				end
			end
			this.sprite_table = nil
		end
	}
	--endregion Sprite

	--region Etc
	self.wait_pos = vector(999, 0, 999)
	self.is_found_breakable_pot = false
	self.is_fadeout = false
	self.quest_id = 403
	--region Etc
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent))

	self.sprite:dispose_all()

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_hold_up_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExitInteractTeleportStartEvent), 'on_exit_interact_teleport_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.TeleportPartyFadeOutFinishEvent), 'on_teleport_party_fadeout_finish_event')
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local quest_progress = user_progress:GetStartedQuest(403)

	if quest_progress.IsComplete then
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('pink', true))
		message_system:Publish(CS.Oak.LinkDoorEvent.Create('green', true))
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end
--endregion

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(_)
	-- 시작 연출
	self:pre_setting()
end

function local_class:on_field_object_destroyed_event(e)
	-- 브레이커블 파괴 처리
	if not self.is_found_breakable_pot and
			e.FieldObject == self.get_breakable_pot(1) then
		self.is_found_breakable_pot = true

		start_coroutine(self.pot_drop_item, self)

		return true
	end
	return false
end

function local_class:on_hold_up_event(e)
	-- 브레이커블 hold up 처리
	if not self.is_found_breakable_pot and
			e.Target == self.get_breakable_pot(1) then
		self.is_found_breakable_pot = true

		start_coroutine(self.pot_drop_item, self)

		return true
	end
	return false
end

function local_class:on_exit_interact_teleport_start_event(e)
	if e.ExitHandleName == self.exit_name .. '1' then
		start_coroutine(function()
			music_player_util.play_stage_music({ name = 'ondemand/v2_65_queencastle/audio:bgm_queencastle_kai', state = 'event' })

			while not self.is_fadeout do
				coroutine.yield(nil)
			end

			self.is_fadeout = false

			field_util.tint(self.tint_key, unity_color({ 0.275, 0.288, 0.392, 1 }), 0)
		end)

		return true
	end

	if e.ExitHandleName == self.exit_name .. '2' then
		music_player_util.play_stage_music({ name = 'ondemand/v2_65_queencastle/audio:bgm_queencastle_temple', state = 'event', mix = 0.6 })

		start_coroutine(function()
			while not self.is_fadeout do
				coroutine.yield(nil)
			end

			self.is_fadeout = false

			field_util.tint(self.tint_key, unity_color({ 1, 1, 1, 1 }), 0)
		end)

		return true
	end

	return false
end

function local_class:on_teleport_party_fadeout_finish_event(e)
	self.is_fadeout = true
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

--region custom
function local_class:pre_setting()
	local quest_progress = user_progress:GetStartedQuest(403)

	local interact_wall_count = 9

	local sprite_ids = {
		self.sprite.sprite_info.magi_times,
		self.sprite.sprite_info.magi_times,
		self.sprite.sprite_info.diary,
		nil,
		self.sprite.sprite_info.diary,
		self.sprite.sprite_info.diary,
		self.sprite.sprite_info.diary,
		self.sprite.sprite_info.paper,
		self.sprite.sprite_info.paper,
	}

	for idx = 1, interact_wall_count do
		if sprite_ids[idx] then
			local interact_wall = self.get_interact_wall(idx)
			local interact_wall_pos = self.get_interact_pos(idx)

			self.sprite:create('interact_item_' .. idx, interact_wall_pos,
					sprite_ids[idx])
			interact_wall.Position = vector_util.get_x0z(interact_wall_pos)
		end
	end

	if quest_progress.IsComplete then
		local door_1 = self.get_interact_door(1)
		local door_2 = self.get_interact_door(2)

		animator_util.play(door_1, 'open')
		animator_util.play(door_2, 'open')

		door_1.ActiveState = active_state('visible')
		door_2.ActiveState = active_state('visible')
	end
end

function local_class:pot_drop_item()
	local item_number = 4
	local interact_wall = self.get_interact_wall(item_number)
	local interact_wall_pos = self.get_interact_pos(item_number)

	self.sprite:create('interact_item_' .. item_number, interact_wall_pos,
			self.sprite.sprite_info.paper, interact_wall_pos)
	interact_wall.Position = vector_util.get_x0z(interact_wall_pos)
	interact_wall.Interactable = CS.Oak.NonInteractable.Instance

	wait_for_sec(1)
	local narration_interactable= CS.Oak.NarrationInteractable()
	narration_interactable.StringKeys = {
		'lw_sub_heavenhold_test_room_s1_16',
		'lw_sub_heavenhold_test_room_s1_17',
		'lw_sub_heavenhold_test_room_s1_18',
		'lw_sub_heavenhold_test_room_s1_19'
	}
	narration_interactable.InteractingSfx = '01_turn_page_02'
	interact_wall.Interactable = narration_interactable
end
--endregion custom

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
