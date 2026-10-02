local local_class = newclass('SubStageHiddenRoomController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.get_knight = function()
		return user_util.get_knight_character('knight_female', 'knight_male')
	end

	-- 카밀라의 방 퀘스트 id
	self.quest_id = 313
	-- 하트 로켓 얻었는지 여부 키.
	self.heart_locket_custom_key = 'qs_camilla_locket_get'

	self.brazier_turned_on = { false, false, false, false }

	self.brazier_count = 4

	self.get_brazier_zone_name = function(group)
		return 'brazier_event_zone_' .. group
	end

	self.get_brazier = function(group, num)
		return get_field_object('brazier_' .. group .. '_' .. num)
	end

	self.get_paper = function(index)
		return get_field_object('paper_' .. index)
	end

	self.paper_count = 6

	self.paper_str_and_sfx_key = {}

	self.action_state = {
		none = 1,
		reading_paper = 2,
	}

	self.current_action_state = self.action_state.none

	self.paper_items = {}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	for _, item in pairs(self.paper_items) do
		item:ConsumeComplete()
	end

	self.paper_items = {}

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
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
	--paper_piece, ringo_music_sheet 오브젝트 인터랙트 시 -> 01_turn_page_02
	--merch_laura_diary , clara_diary , diary_ghost 오브젝트 인터랙트 시 -> 01_turn_page_01
	local item_infos = {
		{ id = 20970, scale = 0.7, sfx = '01_turn_page_01' },
		{ id = 20971, scale = 1, sfx = '01_turn_page_02' },
		{ id = 20972, scale = 0.5, sfx = '01_turn_page_01' },
		{ id = 20973, scale = 0.8, sfx = '01_turn_page_02' },
		{ id = 20971, scale = 1, sfx = '01_turn_page_02' },
		{ id = 20974, scale = 1, sfx = '01_turn_page_01' },
	}

	for i = 1, #item_infos do
		local info = item_infos[i]
		local pos = field_util.get_marker_pos('paper_' .. i)
		local interactable = get_field_object('paper_' .. i)

		interactable.Position = pos

		local strs = interactable.Interactable.StringKeys
		local data = {
			strs = {},
			sfx = info.sfx,
		}

		for j = 0, strs.Length - 1 do
			table.insert(data.strs, strs[j])
		end

		table.insert(self.paper_str_and_sfx_key, data)

		interactable.Interactable = CS.Oak.PublishInteractable.Create()

		local item = drop_item_util.create_item({
			itemid = info.id, pos = pos, sprscale = info.scale,
			notforinven = true, lootstate = 'dontfindlooter'
		})

		table.insert(self.paper_items, item)
	end

	return true
end

function local_class:on_zone_enter_event(e)
	for i = 1, self.brazier_count do
		if  not self.brazier_turned_on[i] and
				type_util.is_zone_full_enter(e, user_party.Leader, self.get_brazier_zone_name(i)) then
			self.brazier_turned_on[i] = true
			command_util.execute_burn(nil, self.get_brazier(i, 1), false)
			command_util.execute_burn(nil, self.get_brazier(i, 2), false)
			return true
		end
	end

	return false
end

function local_class:on_interact_event(e)
	if self.current_action_state == self.action_state.none then
		for i = 1, self.paper_count do
			if lua_helper.reference_equals(e.Target, self.get_paper(i)) then
				self.current_action_state = self.action_state.reading_paper

				sp_util.start_scene(self.show_paper_nar_scene, self, i)

				return true
			end
		end
	end

	return false
end

--endregion

function local_class:show_paper_nar_scene(index)
	local data = self.paper_str_and_sfx_key[index]
	local str_keys = data.strs

	music_player_util.play_sfx_one_shot(data.sfx)

	for i = 1, #str_keys do
		local key = str_keys[i]

		field_ui_util.show_narration_async({ key = key })
	end

	self.current_action_state = self.action_state.none
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
