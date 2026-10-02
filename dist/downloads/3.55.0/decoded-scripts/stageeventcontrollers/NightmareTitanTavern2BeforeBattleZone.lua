local local_class = newclass('NightMareTitanTavern2BeforeBattleZoneController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_princess = function() return CS.Oak.PartyManager.Instance.UserParty.Leader end
	self.get_gnome = function() return get_character('fat_gnome') end

	self.battle_zone_name = 'battle_zone_1'
	self.battle_group_name = 'battle_1'
	self.pre_battle_zone_name = 'pre_battle_zone_1'

	self.is_cleared = false
	self.is_inside_battle_zone = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))
	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.ZoneEnterEvent) and not self.is_cleared and not self.is_inside_battle_zone then
		return self:on_zone_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.BattleGroupEliminatedEvent) then
		return self:on_battle_group_eliminated_event(e)
	end
	return false
end

function local_class:on_zone_enter_event(e)
	local princess = self:get_princess()

	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, princess) then
		if e.Zone.Name == self.pre_battle_zone_name then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.start_event, self))
			return true
		end
	end
	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.battle_group_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.get_off_gnome, self))
			return true
	end
	return false
end

function local_class:on_touch_event(e)
	local fat_gnome = self:get_gnome()

	if lua_helper.type_compare(e, CS.Oak.TouchEvent) and self.is_inside_battle_zone then
		if lua_helper.reference_equals(e.TouchEventType, CS.Oak.TouchEventType.Action2TouchDown) then
			-- 아직 위험해!
			speech_bubble_util.show_speech_bubble(fat_gnome, { key = 'nightmare_titantavern_1_during_battle', skip = true } )
		end
	end
	return false
end

-- 이벤트 시작
function local_class:start_event()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	self.is_inside_battle_zone = true

	local princess = self:get_princess()
	local fat_gnome = self:get_gnome()

	local fat_gnome_speech_offset = CS.SpeechBubbleOffset.Offsets[speech_bubble.bubble_directions.rt]

	fat_gnome_speech_offset = fat_gnome_speech_offset + 1 * unity_class.vector3.up

	local current_state = princess.FieldObjectBehaviour.CurrentActionState

	if lua_helper.type_compare(current_state, CS.Oak.CharacterHoldUpState) then
		local target = current_state.HoldTarget
		command_util.execute_throw(princess, target, CS.Oak.DirectionExtensions.ToVector3(princess.Direction), princess.Position, 0, false)
	end

	character_util.convert_to_npc(fat_gnome)

	character_util.move_to_async(fat_gnome, princess.Position + 1 * unity_class.vector3.left, nil, 5, true,true)

	character_util.remove_anim_and_emotion(princess)
	character_util.remove_anim_and_emotion(fat_gnome)

	character_util.set_direction(princess, 'left')
	character_util.set_direction(fat_gnome, 'right')

	character_util.remove_emotion(fat_gnome)
	message_system:Publish(CS.Oak.FatGnomeRideEvent.Create(false))
	wait_for_sec(1.5)
	party_util.stop_and_disable_control()

	message_system:Subscribe(self, typeof(CS.Oak.TouchEvent), 'on_touch_event')

	-- 뚱보 노움인 상태로 돌아다니지 못하도록 강제로 Battle존에 입장하도록 처리
	local battle_start_pos = field:GetMarker('battle_start').position
	character_util.move_to_async(fat_gnome, battle_start_pos, nil, 4, true, true)

	field_ui_manager:Show()
	user_party:ResetControllers()
	local disabled_controls_flag = CS.Oak.DisabledControls.None | CS.Oak.DisabledControls.Super
	fat_gnome.FieldObjectController.CurrentState:RequestDisableControl(fat_gnome, disabled_controls_flag)
end

function local_class:end_event()
	local princess = self:get_princess()
	local fat_gnome = self:get_gnome()

	character_util.remove_anim_and_emotion(princess)
	character_util.set_emotion(princess, { name = 'awesome' })

	local princess_dir = (princess.Position.x > fat_gnome.Position.x ) and 'left' or 'right'
	local fat_gnome_dir = (princess.Position.x > fat_gnome.Position.x ) and 'right' or 'left'

	character_util.convert_to_npc(fat_gnome)

	local fat_gnome_speech_offset = CS.SpeechBubbleOffset.Offsets[speech_bubble.bubble_directions.rt]

	fat_gnome_speech_offset = fat_gnome_speech_offset + 1 * unity_class.vector3.up

	character_util.set_direction(fat_gnome, fat_gnome_dir)
	character_util.set_direction(princess, princess_dir)

	music_player:PlaySfxOneShot('01_rustle_01')
	character_util.shake(princess, 0.05, 0.7)
	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_player_popup_01')
	character_util.mario_jump_async(princess, princess_dir)
	character_util.remove_anim_and_emotion(princess)

	-- 뚱보 잭 애니메이션 버그 방지
	character_util.remove_anim_and_emotion(fat_gnome)
	character_util.set_direction(fat_gnome, 'down')
	character_util.remove_anim_and_emotion(fat_gnome)

	character_util.remove_anim_and_emotion(princess)
	character_util.remove_anim_and_emotion(fat_gnome)

	character_util.convert_to_party_member(fat_gnome, user_party, true)

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:get_off_gnome()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	message_system:Unsubscribe(self, typeof(CS.Oak.TouchEvent))

	local fat_gnome = self:get_gnome()

	self.is_cleared = true
	self.is_inside_battle_zone = false

	local battle_start_pos = field:GetMarker('battle_start').position
	character_util.move_to_async(fat_gnome, battle_start_pos + vector(-2,0,0), nil, 4, true, true)

	party_util.align_party(fat_gnome.Position, 'left', 0.4)

	character_util.set_direction(fat_gnome, 'left')

	wait_for_sec(0.5)

	message_system:PublishSync(CS.Oak.FatGnomeTakeOffEvent.Instance)

	wait_for_sec(1.1)

	self:end_event()
end

return {
	create = function(cs_controller)
		return local_class(cs_controller)
	end
}
