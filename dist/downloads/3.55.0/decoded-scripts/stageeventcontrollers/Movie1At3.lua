local local_class = newclass("Movie1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	return
end

function local_class:need_on_launch()
	local main_quest = user_progress:GetStartedQuest(60005)

	return main_quest.InnerProgress >= 7 and main_quest.InnerProgress <= 10
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.left_beer ~= nil then
		self.left_beer:ConsumeComplete()
	end

	if self.right_beer ~= nil then
		self.right_beer:ConsumeComplete()
	end

	local manner_bar = get_field_object('manner_bar')
	manner_bar.Interactable = CS.Oak.NonInteractable.Instance

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		local beer_position = vector_util.get_x0z(field:GetMarker('beer_pos').position, 0.9)

		self.left_beer = drop_item_util.create_item(
				{itemid = 9089024, notforinven = true, sprscale = 0.7,
				 pos = beer_position + vector(-0.5, 0, 0), lootstate = 'dontfindlooter'})

		self.left_beer.ShadowTransform.position = vector_util.get_x0z(self.left_beer.ShadowTransform.position, 0.9)

		self.right_beer = drop_item_util.create_item(
				{itemid = 9089024, notforinven = true, sprscale = 0.7,
				 pos = beer_position + vector(0.5, 0, 0), lootstate = 'dontfindlooter'})

		self.right_beer.ShadowTransform.position = vector_util.get_x0z(self.right_beer.ShadowTransform.position, 0.9)

		self.right_beer.SpriteTransform.localScale = vector(-1, 1, 1) * 0.7
		self.right_beer.ShadowTransform.localScale = vector(-1, 1, 1) * 0.7

		local main_quest = user_progress:GetStartedQuest(60005)
		if main_quest.InnerProgress >= 7 and main_quest.InnerProgress <= 10 then
			local clear_flag = get_field_object('movie_1_3_clear_flag')
			character_util.set_active_state(clear_flag, 'disabled')
		end

		if main_quest.InnerProgress ~= 7 then
			local manner_chair = get_field_object('manner_chair')
			manner_chair.Interactable = CS.Oak.NonInteractable.Instance
		end

		local manner_bar = get_field_object('manner_bar')
		manner_bar.Interactable = CS.Oak.PublishInteractable.Create()
	end

	return false
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, get_field_object('manner_bar')) then
		speech_bubble_util.show_speech_bubble(get_character('manner_bartender'),
				{key = game_string:Format('movie_main_s8_bartender', user.Name)})
	end

	return true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}