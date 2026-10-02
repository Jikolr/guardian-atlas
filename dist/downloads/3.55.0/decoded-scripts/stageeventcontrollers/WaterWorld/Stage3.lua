local local_class = newclass('WaterWorld3Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 465
	self.quest_progress = nil

	-- book sprite
	self.book_sprite = nil
	self.book_sprite_id = 21532

	self.door_name_pre_fix = 's11_door_'
	self.save_data_key = 'section_11_save_state'

	self.dyn_npcs = {}

	self.dyn_npc_type = {
		stage10_to_stage11 = 1,
	}

	self.created_dyn_npc_type = {}
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))

	if self.book_sprite ~= nil then
		quest_drop_item_util.dispose_item(self.book_sprite)
		self.book_sprite = nil
	end

	if self.dyn_npcs ~= nil then
		for key, npcs in pairs(self.dyn_npcs) do
			load_util.dispose_dynamic_npcs(npcs)
			npcs = nil
		end

		self.dyn_npcs = nil
	end

	self.cs_controller = nil
end

function local_class:load_resource()
end

function local_class:on_event(e)
	return false
end

function local_class:on_quest_progressed_event(e)
	start_coroutine(function()
		-- 섹션별 동적 생성 NPC 셋팅
		self:set_pre_dyn_npc()
	end)

	return false
end

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 동적 NPC 생성 플래그
	self.created_dyn_npc_type[self.dyn_npc_type.stage10_to_stage11] = false

	self:set_book()
	self:set_wall(self.quest_progress)

	self:set_pre_dyn_npc()

	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')

	stage_start_util.start_function(self.quest_progress)

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress == 10 then
		local storage_create = require('utils/QuestDataStorage')
		local data_storage = storage_create.create(self.main_quest_id)

		local data = data_storage:get_data(self.save_data_key)

		if data < 1 then
			stage_launch_util.play_launch_stage_ignore_disabled_member('left',
					field_util.get_marker_pos('default_start'), true, true)
		elseif data == 1 then
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 1, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 2, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 4, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 5, true))

			stage_launch_util.play_launch_stage_ignore_disabled_member('right',
					field_util.get_marker_pos('s11_start_pos_1'), true, true)
		elseif data == 2 then
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 1, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 2, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 4, true))
			message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name_pre_fix .. 5, true))

			local mermaid_spy = get_character('mermaid_spy_battle')

			character_util.convert_to_party_member_v2(mermaid_spy, user_party, true)

			stage_launch_util.play_launch_stage_ignore_disabled_member('left',
					field_util.get_marker_pos('s11_start_pos_2'), true, true)
		end
	end
end

function local_class:set_book()
	-- book 세팅
	self.book_sprite = quest_drop_item_util.create_item({
		item_id = self.book_sprite_id,
		pos = field_util.get_marker_pos('s11_book_pos'),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
	})
end

function local_class:set_wall(quest_progress)
	-- 스테이지 클리어 후 exit 막는 wall 제거
	if quest_progress ~= nil and quest_progress.InnerProgress > 10 then
		local wall_pre_fix = 'exit_block_wall_'
		local wall_count = 3

		for i = 1, wall_count do
			field_object_util.set_active_state(get_field_object(wall_pre_fix .. i), active_state_type.disabled)
		end
	end
end

--region dynamic npc setting
-- 여러 섹션에 유지되는 동적 NPC 생성 및 저거 처리
function local_class:set_pre_dyn_npc()
	if self.quest_progress ~= nil and (self.quest_progress.InnerProgress >= 9 and self.quest_progress.InnerProgress <= 10) then
		if not self.created_dyn_npc_type[self.dyn_npc_type.stage10_to_stage11] then
			self.created_dyn_npc_type[self.dyn_npc_type.stage10_to_stage11] = true

			self:create_dyn_npcs(self.dyn_npc_type.stage10_to_stage11,
					{
						village_kid_npc_1 = 'ww_slum_human_kid_boy',
						village_kid_npc_2 = 'ww_slum_mermaid_kid_girl',
						village_kid_npc_3 = 'ww_slum_human_kid_boy',
						village_kid_npc_4 = 'ww_slum_fishman_kid_boy',
					}
			)

			self:set_dyn_npcs(self.dyn_npc_type.stage10_to_stage11)
		end
	end
end

function local_class:create_dyn_npcs(event_key, dyn_npcs)
	self.dyn_npcs[event_key] = load_util.create_dynamic_npcs_async(dyn_npcs)
end

function local_class:dispose_dyn_npcs(event_key)
	if self.dyn_npcs ~= nil and self.dyn_npcs[event_key] then
		local dyn_npc_list = self.dyn_npcs[event_key]

		load_util.dispose_dynamic_npcs(dyn_npc_list)

		dyn_npc_list = nil
	end

	self.dyn_npcs = nil
end

function local_class:return_dyn_npcs(event_key)
	return self.dyn_npcs[event_key]
end

function local_class:set_dyn_npcs(state)
	if state == self.dyn_npc_type.stage10_to_stage11 then
		local dyn_npcs = self.dyn_npcs[state]
		local npc = dyn_npcs['village_kid_npc_1']

		field_object_util.set_active_state(npc, active_state_type.enabled)
		character_util.set_position(npc, vector(999, 0, 999))

		npc = dyn_npcs['village_kid_npc_2']

		field_object_util.set_active_state(npc, active_state_type.enabled)
		character_util.set_position(npc, vector(999, 0, 999))

		npc = dyn_npcs['village_kid_npc_3']

		field_object_util.set_active_state(npc, active_state_type.enabled)
		character_util.set_position(npc, vector(999, 0, 999))

		npc = dyn_npcs['village_kid_npc_4']

		field_object_util.set_active_state(npc, active_state_type.enabled)
		character_util.set_position(npc, vector(999, 0, 999))

	end
end

return local_class
