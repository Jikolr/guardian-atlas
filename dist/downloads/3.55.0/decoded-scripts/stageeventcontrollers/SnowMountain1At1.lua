local local_class = newclass("SnowMountain1At1Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.scene = scene()

	self.substage_name = 'substage_3_2'
	self.substage_object_name = 'last_journal'

	self:iced_teatan_init()
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')

	-- 눈덩이 리셋용
	unity_object_pool.GetOrCreate('FX_reset_object')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_load_resource_routine, self))
end

function local_class:on_load_resource_routine()
	quest_icon:PreLoad()

	--- load check
	while not quest_icon.IsLoaded do
		coroutine.yield(nil)
	end

	--- substage setup
	if not user_progress:IsStageOpened(self.substage_name) then
		local substage_book = get_field_object(self.substage_object_name)
		quest_icon.SetSubstageIcon(substage_book)
	end

	return false
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self:iced_teatan_dispose()

	self.scene = nil
	self.cs_controller = nil
end

function local_class:on_event(e)

	local event_type = e:GetType()

	self:iced_teatan_on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		self:on_camera_grid_leave_event(e)
	end

	return false
end

function local_class:iced_teatan_init()
	self.hide_ice_block_name = 'hide_ice_block'
	self.iced_teatan_follow_id = 14
	self.iced_teatan_shake = nil
end

function local_class:iced_teatan_setting()
	local iced_teatan = get_character('iced_teatan_male')

	if user_progress:IsFollowing(self.iced_teatan_follow_id) then
		iced_teatan.ActiveState = active_state('disabled')
	else
		field_ui_manager:RemoveUI(iced_teatan, CS.Oak.FieldUiType.CharacterStats)
		self.iced_teatan_shake = coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.iceman_shake, self, iced_teatan))
		self.scene:add_callback('IcemanJump', { controller = self, func = self.iceman_jump })
	end
end

function local_class:on_interact_event(e)
	local substage_book = get_field_object(self.substage_object_name)

	if lua_helper.reference_equals(e.Target, substage_book) then
		sp_util.play_normal_screenplay(self.read_last_journal, self, substage_book)
	end
end

function local_class:on_camera_grid_leave_event(e)
	if e.CameraGrid.name == 'snowball_grid' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.reset_snow_ball, self))
	end
end

function local_class:iced_teatan_on_event(e)
	local event_type = e:GetType()
	local iced_teatan = get_character('iced_teatan_male')

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:iced_teatan_setting()
	end

	if event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) and e.FieldObject.Name == self.hide_ice_block_name then
		iced_teatan.Interactable:AddListener(self.cs_controller)
	end

	if event_type == typeof(CS.Oak.InteractEvent) and lua_helper.reference_equals(e.Target, iced_teatan) then
		stop_coroutine(self.iced_teatan_shake)
		self.iced_teatan_shake = nil

		iced_teatan.Interactable:RemoveRelatedEvent(self.cs_controller)

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.scene.HelpIcedTeatanMale, self))
	end
end

function local_class:iced_teatan_dispose()
	if self.iced_teatan_shake ~= nil then
		stop_coroutine(self.iced_teatan_shake)
	end

	self.iced_teatan_shake = nil
end

function local_class:iceman_jump()
	local iced_teatan = get_character('iced_teatan_malee')

	iced_teatan:SetAnimation('get', true)
	iced_teatan:SetEmotion('surprise', true)

	iced_teatan:Jump(1.7, 0.5)

	iced_teatan.Position = vector_util.get_x0z(iced_teatan.Position)

	wait_for_sec(0.5)

	iced_teatan:RemoveAnimation()
end

function local_class:iceman_shake(iced_teatan)
	while true do
		iced_teatan:Shake(0.05, 1)
		wait_for_sec(2)
	end
end

function local_class:read_last_journal(book)

	if not user_progress:IsStageOpened('substage_3_2') then
		quest_icon.RemoveIcon(book)
	end

	field_ui_util.show_narration_async({ key = 'substage_lastjournal_1', mintotalduration = 1 })

	if not user_progress:IsStageOpened('substage_3_2') then
		local substage_map = get_field_object(self.substage_name).FieldObjectBehaviour
		yield_return(substage_map, 'OpenStage')
	end
end

function local_class:reset_snow_ball()
	local snow_ball = get_field_object('snow_ball')

	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(snow_ball.Bounds.center)

	wait_for_sec(0.2)

	snow_ball.Position = field:GetMarker('snow_ball_reset_point').position
	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(snow_ball.Bounds.center)

	snow_ball.Hitbox = CS.Oak.Hitbox(vector(0.5, -0.1, 0.5), vector(0.5, 0.5, 0.5))
	snow_ball.transform.localScale = vector(1, 1, 1)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
