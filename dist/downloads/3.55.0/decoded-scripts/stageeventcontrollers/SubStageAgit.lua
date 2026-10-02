local local_class = newclass('SubStageAgitController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 370
	self.cw_util = nil

	--region FieldObject
	--첫번째 방 아이템 들
	self.get_first_item = function(number)
		return get_field_object('s1_interactable_item_' .. number)
	end

	--두번째 방 (보물방 포함)
	self.get_second_item = function(number)
		return get_field_object('s1_second_room_interactable_item_' .. number)
	end

	--브레이커블
	self.get_breakable_pot = function(number)
		return get_field_object('s1_breakable_' .. number)
	end

	--시작맵 이동 exit
	self.get_exit = function(number)
		return get_field_object('s1_exit_' .. number)
	end
	--endregion FieldObject
	--region Marker
	--아이템 위치 (첫 번째 방)
	self.get_item_pos = function(number)
		return field_util.get_marker_pos('s1_interactable_item_pos_' .. number)
	end

	--아이템 위치 (두 번째 방 : 보물 방 포함)
	self.get_item_second_room_pos = function(number)
		return field_util.get_marker_pos('s1_second_room_interactable_item_pos_' .. number)
	end
	--브레이커블 위치
	self.get_breakable_pot_pos = function(number)
		return field_util.get_marker_pos('s1_breakable_pos_' .. number)
	end
	--endregion Marker

	--region Sprite
	self.item_info = {
		first = {
			{ id = 21063, scale = 1 },
			{ id = 21064, scale = 1 },
			{ id = 21065, scale = 0.7 },
			{ id = 21066, scale = 1 },
		},
		second = {
			{ id = 21067, scale = 0.5 },
			{ id = 21068, scale = 1 },
			{ id = 21069, scale = 0.6 },
			{ id = 21070, scale = 1 },
			{ id = 21071, scale = 1 },
			{ id = 21072, scale = 1 },
			{ id = 21073, scale = 1 },
			{ id = 21074, scale = 1 },
			{ id = 21075, scale = 1 },
			{ id = 21076, scale = 1 },
			{ id = 21077, scale = 1 },
			{ id = 21078, scale = 1 },
			{ id = 21079, scale = 1 },
			{ id = 21080, scale = 1 },
			{ id = 21073, scale = 1 },
			{ id = 21081, scale = 0.7 },
		}
	}

	self.substage_map_item = nil
	--endregion Sprite

	self.is_in_agit = false

	self.items = nil

	self.wait_pos = vector(999, 0, 999)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.HoldUpEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	if self.items then
		for idx = 1, #self.items do
			self.items[idx]:ConsumeComplete()
			self.items[idx] = nil
		end
		self.items = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	---@type CivilWarUtil
	self.cw_util = get_or_create_global_table('Quest/Main/CivilWar/Common/Util')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	start_coroutine(self.launch_routine, self)
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

function local_class:on_hold_up_event(e)
	-- 브레이커블 hold up 처리
	if not self.is_found_breakable_pot and
			e.Target == self.get_breakable_pot(1) then
		self.is_found_breakable_pot = true

		local exit_fo = self.get_exit(1)

		exit_fo.ActiveState = active_state('enabled')

		return true
	end
	return false
end

function local_class:on_field_object_destroyed_event(e)
	-- 브레이커블 파괴 처리
	if not self.is_found_breakable_pot and
			e.FieldObject == self.get_breakable_pot(1) then
		self.is_found_breakable_pot = true

		local exit_fo = self.get_exit(1)

		exit_fo.ActiveState = active_state('enabled')

		return true
	end
	return false
end

function local_class:on_field_ui_show()
	if not self.is_in_agit then
		music_player_util.change_stage_music_volume('field', 1)
	end
end

function local_class:on_field_ui_hide()
	music_player_util.change_stage_music_volume('field', 0.5)
end

function local_class:on_zone_enter_event(e)
	local leader = get_party_leader()

	if type_util.is_zone_full_enter(e, leader, 'agit_tent_zone') then
		self.is_in_agit = true
		music_player_util.change_stage_music_volume('field', 0.5)

		return true
	end

	if type_util.is_zone_full_enter(e, leader, 'forest_zone') then
		self.is_in_agit = false
		music_player_util.change_stage_music_volume('field', 1)

		return true
	end
end
--endregion

function local_class:launch_routine()
	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.cw_util:activate_control_directional_light(
			{
				agit_tent_zone = 'agit_tent_in',
				forest_zone = 'agit_forest_in',
			}
	)

	if main_quest_progress == nil or main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	elseif main_quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				false, true)
	end

	self:pre_setting()

	message_system:Subscribe(self, typeof(CS.Oak.HoldUpEvent), 'on_hold_up_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

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
--세팅
function local_class:pre_setting()
	self.items = {}

	--첫 번째 방 세팅
	do
		--exit 오브젝트 비 활성화
		local exit_fo = self.get_exit(1)

		exit_fo.ActiveState = active_state('disabled')

		--브레이커블 세팅
		local pot = self.get_breakable_pot(1)

		pot.Position = self.get_breakable_pot_pos(1)

		--아이템 세팅
		for idx = 1, #self.item_info.first do
			local item_fo = self.get_first_item(idx)
			local item_pos = self.get_item_pos(idx)
			local item = drop_item_util.create_item(
					{ pos = item_pos, itemid = self.item_info.first[idx].id, notforinven = true,
					  lootstate = 'dontfindlooter', sprscale = self.item_info.first[idx].scale })

			item_fo.Position = item_pos

			table.insert(self.items, item)
		end

		-- 스프라이트가 없어 따로
		local door = self.get_first_item(5)
		local door_pos = self.get_item_pos(5)

		door.Position = door_pos
	end

	--두 번째 방 세팅
	do
		--아이템 세팅

		for idx = 1, #self.item_info.second do
			local item_fo = self.get_second_item(idx)
			local item_pos = self.get_item_second_room_pos(idx)
			local item = drop_item_util.create_item(
					{ pos = item_pos, itemid = self.item_info.second[idx].id, notforinven = true,
					  lootstate = 'dontfindlooter', sprscale = self.item_info.second[idx].scale })

			item_fo.Position = vector_util.get_x0z(item_pos, 0)

			table.insert(self.items, item)
		end

	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	--클리어시 라디오 인터렉트 안되도록 설정
	if main_quest_progress == nil or main_quest_progress.IsComplete then
		self.get_second_item(16).Position = self.wait_pos
	end
end
--endregion custom
return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
