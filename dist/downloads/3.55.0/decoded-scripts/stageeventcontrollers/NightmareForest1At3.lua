local local_class = newclass("NightmareForest1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.ifo_util = CS.Oak.IFieldObjectExtensions

	self.is_moving = false
	self.is_throwing_star_piece = false

	-- 꽃밭
	self.flower = {
		left_flower = 1,
		right_flower = 2,
		star_piece_flower = 3
	}

	-- 해당 꽃밭이 바위로 막혀있는지
	self.block = {
		left_flower = false,
		right_flower = false,
		star_piece_flower = false
	}

	-- 나비가 현재 있는 꽃밭
	self.current_butterfly_flower = self.flower.left_flower
	-- 플레이어가 현재 근처에 있는 꽃밭
	self.current_leader_flower = -1
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_starpiece_in_character')

	local drone = get_character('drone')
	drone.SpineController.SpineOffset = vector(0, 0.8, 0)
	drone.Interactable:AddListener(self.cs_controller)

	-- 나비 레벨 UI 제거
	local butterfly = get_character('butterfly')
	field_ui_manager:RemoveUI(butterfly, CS.Oak.FieldUiType.CharacterStats)

	-- 첫 전투 오크 잡기전까지 nonInteractable, hitbox 크기 조정
	local trap = get_field_object('wolf_trap')
	trap.Interactable = CS.Oak.NonInteractable.Instance
	trap.Hitbox = CS.Oak.Hitbox(vector(1, 0, 0.5), vector(1.5, 2, 1.5))

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	local drone = get_character('drone')
	if lua_helper.type_compare(drone.Interactable, CS.Oak.NPCInteractable) then
		drone.Interactable:RemoveRelatedEvent(self.cs_controller)
	end

	self.flower = nil
	self.block = nil

	if self.star_piece_effect ~= nil then
		self.star_piece_effect:Dispose()
	end

	self.star_piece_effect = nil

	self.cs_controller = nil
	self.ifo_util = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	local flower_push_stone = get_field_object('flower_push_stone')

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		local zone_name = e.Zone.Name

		-- 바위가 꽃밭을 막았는지 체크
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, flower_push_stone) then
			for k, v in pairs(self.block) do
				if zone_name == 'push_stone_' .. k then
					self.block[k] = true
					-- 막은 꽃밭에 나비가 있으면 날아가도록
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_flower, self, self.flower[k]))
					return true
				end
			end
		end

		-- 플레이어가 꽃밭에 다가갔는지 체크
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			for k, v in pairs(self.flower) do
				if zone_name == k then
					self.current_leader_flower = v
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.move_flower, self, v))
					return true
				end
			end
		end
	end

	if event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		local zone_name = e.Zone.Name

		if lua_helper.reference_equals(e.FieldObject, flower_push_stone) then
			for k, v in pairs(self.block) do
				if zone_name == 'push_stone_' .. k then
					self.block[k] = false
					return true
				end
			end
		end

		if lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			for k, v in pairs(self.flower) do
				if zone_name == k then
					self.current_leader_flower = -1
					return true
				end
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self.earned_butterfly_star_piece = stage_progress:HasStarPiece('butterfly_star_piece')

		if not self.earned_butterfly_star_piece then
			local marker = field:GetMarker('butterfly_flower_3').position
			local fx_star_piece_pool = unity_object_pool.GetOrCreate('FX_starpiece_in_character')
			self.star_piece_effect = fx_star_piece_pool:Instantiate(marker)
		end

		return true
	end

	if event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
		if e.CameraGrid.name == 'last_grid' then
			local marker = field:GetMarker('push_block_start_pos').position
			for i = 1, 4 do
				local push_block = get_field_object('push_block_' .. i)
				push_block.Position = marker + i * unity_class.vector3.back
			end
			return true
		end
	end

	if event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		if e.BattleGroupName == 'battle1' then
			get_field_object('wolf_trap').Interactable = CS.Oak.PublishInteractable.Create()
		end

		return true
	end

	if event_type == typeof(CS.Oak.InteractEvent) then
		local trap = get_field_object('wolf_trap')

		if lua_helper.reference_equals(e.Target, trap) then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.wolf_trap_narration, self))
		end

		local drone = get_character('drone')
		if lua_helper.reference_equals(e.Target, drone) then
			local string_key = 'nightmare_forest_3_drone_1'
			local offset = vector(2.3, 0, 2)
			speech_bubble_util.show_speech_bubble(drone,{ key = string_key, offset = offset })
			return true
		end

		return true
	end

	return false
end

-- 나비 꽃밭 이동
function local_class:move_flower(index)
	-- 나비가 이동하고 있는지 체크
	if self.is_moving then return end

	-- 접근한 꽃밭에 나비 존재하는지 체크
	if self.current_butterfly_flower ~= index then return end

	-- 스타피스가 나오는 동안 나비가 이동하지 않도록
	if self.is_throwing_star_piece then return end

	self.is_moving = true

	-- 이동하려는 꽃밭이 바위로 막혔는지 체크
	local move_end_flower = self.flower.left_flower
	if self.current_butterfly_flower == self.flower.left_flower then
		if self.block.right_flower then
			move_end_flower = self.flower.star_piece_flower
		else
			move_end_flower = self.flower.right_flower
		end
	elseif self.current_butterfly_flower == self.flower.right_flower then
		if self.block.left_flower then
			move_end_flower = self.flower.star_piece_flower
		end
	else
		if self.block.left_flower then
			move_end_flower = self.flower.right_flower
		end
	end

	local butterfly = get_character('butterfly')

	local duration = 2
	character_util.jump(butterfly, 1.5, duration)
	local marker = field:GetMarker('butterfly_flower_' .. move_end_flower).position
	yield_return_func(self.ifo_util.MoveTo, butterfly, marker, duration, 0, true, true)

	self.is_moving = false
	self.current_butterfly_flower = move_end_flower
	character_util.remove_anim(butterfly)
	character_util.set_anim(butterfly, { name = 'sleep' })

	-- 나비가 스타피스가 있는 꽃밭으로 이동하면 스타피스 드랍
	if move_end_flower == self.flower.star_piece_flower and not self.earned_butterfly_star_piece then
		self.earned_butterfly_star_piece = true

		self.star_piece_effect:Dispose()

		local star_piece = get_field_object('butterfly_star_piece')
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(butterfly.Position))

		self.is_throwing_star_piece = true

		wait_for_sec(3)

		self.is_throwing_star_piece = false
	end

	wait_for_sec(0.3)

	-- 나비 꽃밭 이동 끝나고 바위에 막혔는지 플레이어가 있는지 체크
	if self.current_butterfly_flower == self.current_leader_flower or self.block[self.current_butterfly_flower] then
		yield_return_func(self.move_flower, self, self.current_butterfly_flower)
	end
end

function local_class:wolf_trap_narration()
	user_party:StopAndDisableControl()
	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, "SetNarration",
		game_string:GetString("nightmare_forest_3_trap_1"), 0, 1.0)
	yield_return(stage.FieldUINarrationBox, "HideAnimation")
	user_party:ResetControllers()
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
