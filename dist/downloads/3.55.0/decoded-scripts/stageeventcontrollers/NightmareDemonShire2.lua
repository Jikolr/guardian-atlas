local local_class = newclass('NightmareDemonShire2Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	self.operator_ui = nil

	self.scene_version = scene_util.default_version
	self.oneline_zone_event_data = {
		oneline_event_zone_1 = {
			routine = nil,
			is_first = true,
			{
				name = 'stage2_alley_oneline_npc_1',
				key = 'nm_ds_main_s6_alley_oneline_1'
			},
			{
				name = 'stage2_alley_oneline_npc_2',
				key = 'nm_ds_main_s6_alley_oneline_2'
			}
		},
		oneline_event_zone_2 = {
			routine = nil,
			is_first = true,
			{
				name = 'stage2_alley_oneline_npc_9',
				key = 'nm_ds_main_s6_alley_oneline_9'
			},
			{
				name = 'stage2_alley_oneline_npc_10',
				key = 'nm_ds_main_s6_alley_oneline_10'
			},
			{
				name = 'stage2_alley_oneline_npc_11',
				key = 'nm_ds_main_s6_alley_oneline_11'
			}
		},
		oneline_event_zone_4 = {
			routine = nil,
			is_first = true,
			{
				name = 'stage2_plaza_oneline_npc_22',
				key = 'nm_ds_stage2_plaza_oneline_22'
			},
			{
				name = 'stage2_plaza_oneline_npc_23',
				key = 'nm_ds_stage2_plaza_oneline_23',
				sfx = '01_crowd_shout_07'
			},
			{
				name = 'stage2_plaza_oneline_npc_24',
				key = 'nm_ds_stage2_plaza_oneline_24'
			},
			{
				name = 'stage2_plaza_oneline_npc_25',
				key = 'nm_ds_stage2_plaza_oneline_25',
				sfx = '01_crowd_shout_07'
			},
		},
		oneline_event_zone_5 = {
			routine = nil,
			is_first = true,
			{
				name = 'stage2_plaza_oneline_npc_26',
				key = 'nm_ds_stage2_plaza_oneline_26'
			},
			{
				name = 'stage2_plaza_oneline_npc_27',
				key = 'nm_ds_stage2_plaza_oneline_27',
				sfx = '01_crowd_shout_07'
			},
			{
				name = 'stage2_plaza_oneline_npc_28',
				key = 'nm_ds_stage2_plaza_oneline_28'
			},
			{
				name = 'stage2_plaza_oneline_npc_29',
				key = 'nm_ds_stage2_plaza_oneline_29',
				sfx = '01_crowd_shout_07'
			},
		},
	}

	self.items = {}
	self.item_data = {
		{
			-- butterfly_flower_basket
			item_id = 21242,
			scale = 1,
			pos = field_util.get_marker_pos('main_s6_flower_basket_pos_1')
		},
		{
			-- butterfly_flower_basket
			item_id = 21242,
			scale = 1,
			pos = field_util.get_marker_pos('main_s6_flower_basket_pos_2')
		},
		{
			-- half_vampire_frame
			item_id = 21244,
			scale = 0.5,
			pos = field_util.get_marker_pos('main_s6_half_vampire_frame_pos')
		},
	}
	self.eat_sfx_list = {}
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	for _, data in pairs(self.oneline_zone_event_data) do
		data.routine = false
	end

	if not table_util.is_empty(self.items) then
		for _, item in pairs(self.items) do
			item:ConsumeComplete()
		end

		self.items = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')

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

	self:set_figure()
	self:set_item_with_data()
	self:set_signboard_item()
	self:set_hall_oneline_npc_hitbox()
	self:set_npc_3d_sound()
	self:set_book()

	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				false, true)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
				false, true)
	elseif quest_progress.InnerProgress == 6 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start'),
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
	if self.oneline_zone_event_data[zone_name] ~= nil and
			type_util.is_zone_full_enter(e, get_party_leader(), zone_name) then
		local data = self.oneline_zone_event_data[zone_name]

		if data.routine == nil and data.is_first == true then
			data.is_first = false

			start_coroutine(self.oneline_zone_event, self, data)
		end
	end
end

function local_class:on_zone_leave_event(e)
	local zone_name = e.Zone.Name

	if self.oneline_zone_event_data[zone_name] ~= nil and
			type_util.is_zone_full_leave(e, get_party_leader(), zone_name) then
		local data = self.oneline_zone_event_data[zone_name]

		if data.routine == true then
			data.routine = false
		end
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

function local_class:set_figure()
	local golem_tanker_figure = get_character('golem_tanker_figure')
	character_util.set_scale_factor(golem_tanker_figure, 'golem_tanker_fugure', 0.5)
	character_util.add_color(golem_tanker_figure, golem_tanker_figure.Name,
			unity_color({ 127 / 255, 121 / 255, 140 / 255, 1 }), 1, 0)
	character_util.set_anim_time_scale(golem_tanker_figure, 0)
end

function local_class:set_item_with_data()
	local data = self.item_data
	for idx = 1, #data do
		local item = drop_item_util.create_item({
			pos = data[idx].pos,
			itemid = data[idx].item_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
			sprscale = data[idx].scale
		})
		table.insert(self.items, item)
	end
end

function local_class:set_signboard_item()
	local pivot_pos = vector(42.5, 0, 42.5)

	-- signboard_staff
	local data = {
		{
			item_id = 21249,
			pos = pivot_pos + vector(0.5, 0, 0.5),
			angle = unity_class.quaternion.Euler(90, 130, 0)
		},
		{
			item_id = 21245,
			pos = pivot_pos,
			angle = unity_class.quaternion.Euler(90, 20,0)
		},
		{
			item_id = 21245,
			pos = pivot_pos + vector(0.3, 0, -0.4),
			angle = unity_class.quaternion.Euler(90, 180, 0)
		},
		{
			item_id = 21249,
			pos = pivot_pos + vector(0.1, 0, 0.3),
			angle = unity_class.quaternion.Euler(90, 10,  0)
		},
		{
			item_id = 21245,
			pos = pivot_pos + vector(-0.5, 0, -0.5),
			angle = unity_class.quaternion.Euler(90, 150, 0)
		},
		{
			item_id = 21249,
			pos = pivot_pos + vector(-0.3, 0, -0.2),
			angle = unity_class.quaternion.Euler(90, 120, 0)
		},
		{
			item_id = 21245,
			pos = pivot_pos + vector(0.7, 0, -0.1),
			angle = unity_class.quaternion.Euler(90, 50, 0)
		},
		{
			item_id = 21245,
			pos = pivot_pos + vector(-0.4, 0, 0.7),
			angle = unity_class.quaternion.Euler(90, 70, 0)
		},
	}

	for idx = 1, #data do
		local item = drop_item_util.create_item({
			pos = data[idx].pos,
			itemid = data[idx].item_id,
			notforinven = true,
			lootstate = 'dontfindlooter',
		})
		item.SpriteTransform.localRotation = data[idx].angle
		item.ShadowTransform.localRotation = data[idx].angle

		table.insert(self.items, item)
	end
end

function local_class:set_hall_oneline_npc_hitbox()
	for idx = 1, 2 do
		local npc = get_character('stage2_hall_oneline_npc_' .. idx)
		npc.Hitbox = CS.Oak.Hitbox(vector(2.5, 1, 1))
	end
end

function local_class:oneline_zone_event(data)
	local foreach = function(action)
		for idx = 1, #data do
			local npc = get_character(data[idx].name)

			action(npc, idx)
		end
	end

	foreach(function(npc, idx)
		if data[idx].sfx ~= nil then
			music_player_util.play_sfx({
				sfx_name = data[idx].sfx,
				parent = npc,
				type_priority = 'event',
				player_priority = 'npc',
				max_distance = 6
			})
		end

		scene_util.show_normal_speech_async(npc, data[idx].key, false)
	end)

	foreach(function(npc, idx)
		npc.Interactable.Talk = data[idx].key
	end)
end

function local_class:set_npc_3d_sound()
	local npcs = {
		{
			get_character('stage2_start_oneline_npc_13'),
			'release',
			'01_swing_01'
		},
		{
			get_character('stage2_road_oneline_npc_5'),
			'release',
			'01_swing_01'
		},
	}

	for idx = 1, #npcs do
		scene_util.set_anim(npcs[idx][1], self,
				{ name = npcs[idx][2], loop = true, sfx_name = npcs[idx][3] })
	end

	local flower_npc_count = 4
	for idx = 1, flower_npc_count do
		local eat_loop_sfx = music_player_util.play_sfx({
			sfx_name = '03_equipping_01',
			parent = get_character('main_s6_flower_npc_' .. idx),
			loop = true,
			type_priority = 'loop',
			player_priority = 'npc',
			max_distance = 4
		})

		table.insert(self.eat_sfx_list, eat_loop_sfx)
	end
end

function local_class:set_book()
	local quest_progress = user_progress:GetStartedQuest(406)

	if quest_progress == nil or quest_progress.InnerProgress > 5 then
		for idx = 1, 3 do
			local book = get_field_object('comic_book_' .. idx)
			book.ActiveState = CS.Oak.ActiveState.Disabled
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
