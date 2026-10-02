local local_class = newclass('DreamVillage4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 441

	-- character
	self.characters = {
		princess = function()
			return get_character('princess')
		end,

		square_statue = function()
			return get_character('square_statue')
		end
	}

	-- marker
	self.markers = {
		princess = function(inner_state, idx)
			return field_util.get_marker_pos('s17_' .. inner_state .. '_princess_' .. idx)
		end,
	}

	-- field object
	self.field_object = {
		library_gate = function() return get_field_object('library_gate') end,
		puzzle_bookcase = function(idx) return get_field_object('soulbinder_bookcase_' .. idx) end,
		opened_puzzle_bookcase_3 = function() return get_field_object('soulbinder_bookcase_3_open') end,
		secret_bookcase = function(idx) return get_field_object('secret_area_bookcase_' .. idx) end,
	}

	self.time_conversion_event_key = 'stage_4'

	self.tc_pooled_npc_event_info = {
		daylight = {
			{
				npc_name = 'pooled_dv_inn_keeper_1',
				event_type = 'zone_enter',
				zone_name = 'inn_keeper_oneline',
				func_loop = true,
				func = function(this)
					start_coroutine(function()
						local char = get_character(this.npc_name)
						local time_passed = 0
						local delay_time = 5.5

						while this.func_loop do
							start_coroutine(function()
								scene_util.play_normal_speech_action(char, self, nil,
										nil, { name = 'smile' }, { key = 'test_1', skip = false })
							end)

							while time_passed < delay_time do
								time_passed = time_passed + unity_class.time.deltaTime

								if not this.func_loop then
									--speech_bubble_util.remove_bubble(char)

									return
								end

								coroutine.yield()
							end

							time_passed = 0

							coroutine.yield()
						end
					end)
				end,
			},

			{
				event_type = 'zone_enter',
				zone_name = 'soulkeeper_house',
				func_loop = true,
				func = function(this)
					local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

					if quest_progress.InnerProgress > 17 then
						self:set_bookcase_narrations(self.day_state)
					end
				end,
			},
			{
				event_type = 'zone_enter',
				zone_name = 'secret_area',
				func_loop = true,
				func = function(this)
					local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

					if quest_progress.InnerProgress > 17 then
						self:set_bookcase_narrations(self.day_state)
					end
				end,
			},
		},

		night = {
			{
				npc_name = 'pooled_dv_inn_keeper_1',
				event_type = 'zone_enter',
				zone_name = 'inn_keeper_oneline',
				func_loop = true,
				func = function(this)
					start_coroutine(function()
						local char = get_character(this.npc_name)
						local time_passed = 0
						local delay_time = 5.5

						while this.func_loop do
							start_coroutine(function()
								scene_util.play_normal_speech_action(char, self, nil,
										nil, { name = 'smile' }, { key = 'test_2', skip = false })
							end)

							while time_passed < delay_time do
								time_passed = time_passed + unity_class.time.deltaTime

								if not this.func_loop then
									--speech_bubble_util.remove_bubble(char)

									return
								end

								coroutine.yield()
							end

							time_passed = 0

							coroutine.yield()
						end
					end)
				end,
			},

			{
				event_type = 'zone_enter',
				zone_name = 'soulkeeper_house',
				func_loop = true,
				func = function(this)
					local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

					if quest_progress.InnerProgress > 17 then
						self:set_bookcase_narrations(self.day_state)
					end
				end,
			},
			{
				event_type = 'zone_enter',
				zone_name = 'secret_area',
				func_loop = true,
				func = function(this)
					local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

					if quest_progress.InnerProgress > 17 then
						self:set_bookcase_narrations(self.day_state)
					end
				end,
			}
		}
	}

	self.bookcase_info = {
		puzzle_bookcase_count = 5,

		puzzle_bookcase_string_keys = {
			daylight = {
				[1] = {
					'dv_main_s18_book_story_1_1',
					'dv_main_s18_book_story_1_2',
					'dv_main_s18_book_story_1_3',
					'dv_main_s18_book_story_1_4'
				},
				[2] = {
					'dv_main_s18_book_story_2_1',
					'dv_main_s18_book_story_2_2',
					'dv_main_s18_book_story_2_3',
					'dv_main_s18_book_story_2_4'
				},
				[3] = {
					'dv_main_s18_book_story_3_1',
					'dv_main_s18_book_story_3_2',
					'dv_main_s18_book_story_3_3',
					'dv_main_s18_book_story_3_4'
				},
				[4] = {
					'dv_main_s18_book_story_4_1',
					'dv_main_s18_book_story_4_2',
					'dv_main_s18_book_story_4_3',
					'dv_main_s18_book_story_4_4'
				},
				[5] = {
					'dv_main_s18_book_story_5_1',
					'dv_main_s18_book_story_5_2',
					'dv_main_s18_book_story_5_3',
					'dv_main_s18_book_story_5_4'
				},
			},

			night = {
				[1] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[2] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[3] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[4] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[5] = {
					'dv_stage_4_bookcase_interact_1',
				},
			},
		},

		secret_bookcase_count = 4,

		secret_bookcase_string_keys = {
			daylight = {
				[1] = {
					'dv_main_s18_bookcase_1_2',
				},
				[2] = {
					'dv_main_s18_bookcase_2_2',
				},
				[3] = {
					'dv_main_s18_after_bookcase_1_1',
					'dv_main_s18_after_bookcase_1_2',
				},
				[4] = {
					'dv_main_s18_bookcase_3_2',
				},
			},

			night = {
				[1] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[2] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[3] = {
					'dv_stage_4_bookcase_interact_1',
				},
				[4] = {
					'dv_stage_4_bookcase_interact_1',
				},
			},

		},
	}

	self.day_state = 'daylight'

	self.s18_custom_state_key = 'main_s18_save'
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	local time_conversion = get_stage_event_controller('TimeConversionManager')

	if time_conversion ~= nil then
		time_conversion:unregister_callback(self.time_conversion_event_key)
	end

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	local npc_event_info = self.tc_pooled_npc_event_info[self.day_state]

	for i = 1, #npc_event_info do
		local info = npc_event_info[i]

		if type_util.is_zone_full_enter(e, get_party_leader(), info.zone_name) then
			if info.event_type == 'zone_enter' then
				info.func_loop = true
				info:func()

				return true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	local npc_event_info = self.tc_pooled_npc_event_info[self.day_state]

	for i = 1, #npc_event_info do
		local info = npc_event_info[i]

		if type_util.is_zone_full_leave(e, get_party_leader(), info.zone_name) then

			if info.event_type == 'zone_enter' and
					info.func ~= nil and info.func_loop then
				info.func_loop = false
			end
		end

		return true
	end

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
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.s18_state = quest_util.get_custom_state(quest_progress, self.s18_custom_state_key)

	self:set_time_conversion_register_callback()

	self:set_gimmick_state(quest_progress)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 16 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s17_1_knight_1'), false, false)
	elseif quest_progress.InnerProgress == 17 then
		if self.s18_state < 3 then
			stage_launch_util.play_launch_stage_ignore_disabled_member('right',
					field_util.get_marker_pos('s18_start_1'), true, true)
		elseif self.s18_state >= 3 then
			stage_launch_util.play_launch_stage_ignore_disabled_member('left',
					field_util.get_marker_pos('s18_start_2'), true, true)
		end
	elseif quest_progress.InnerProgress == 18 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 19 then
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('s20_player_pos'), false, false)
	else
		stage_launch_util.play_launch_stage_ignore_disabled_member('right',
				field_util.get_marker_pos('default_start'), true, true)
	end
end

function local_class:set_gimmick_state(quest_progress)
	-- 메인 섹션19부터 3번 책장 열려있도록 셋팅
	if quest_progress.InnerProgress >= 18 then
		local bookcase = self.field_object.puzzle_bookcase(3)

		animator_util.play(bookcase, 'open')
		field_object_util.set_active_state(bookcase, active_state_type.visible)

		local library_gate = self.field_object.library_gate()

		animator_util.play(library_gate, 'gate_open')
		field_object_util.set_active_state(library_gate, active_state_type.visible)
	end

	-- 괴물 동상 셋팅
	local square_statue = self.characters.square_statue()

	square_statue.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 2
	field_ui_manager:RemoveUI(square_statue, CS.Oak.FieldUiType.CharacterStats)
end

function local_class:set_time_conversion_register_callback()
	do
		-- 밤/낮 세팅
		local time_conversion = get_stage_event_controller('TimeConversionManager')

		-- 콜백 등록
		time_conversion:register_callback(self.time_conversion_event_key, {
			-- 낮
			daylight = function()
				self.day_state = 'daylight'

				local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

				if quest_progress.InnerProgress ~= 17 then
					self:set_bookcase_narrations('daylight')
				end

				self:reset_square_statue()
			end,
			-- 밤
			night = function()
				self.day_state = 'night'

				local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

				if quest_progress.InnerProgress ~= 17 then
					self:set_bookcase_narrations('night')
				end

				self:set_alpha_square_statue()
			end
		}, true)
	end
end

function local_class:reset_square_statue()
	local square_statue = self.characters.square_statue()

	character_util.remove_color(square_statue, square_statue.Name, 2)
end

function local_class:set_alpha_square_statue()
	local square_statue = self.characters.square_statue()

	character_util.add_color(square_statue, square_statue.Name, unity_color({ 0.5, 0.4, 0.4 }), 1, 1)
end

function local_class:set_bookcase_narrations(day_or_night)
	if zone_util.contains_fo('soulkeeper_house', get_party_leader(), false) or
			zone_util.contains_fo('secret_area', get_party_leader(), false) then
		for i = 1, self.bookcase_info.puzzle_bookcase_count do
			local bookcase = self.field_object.puzzle_bookcase(i)
			local narration_interactable = CS.Oak.NarrationInteractable()

			narration_interactable.StringKeys = self.bookcase_info.puzzle_bookcase_string_keys[day_or_night][i]
			bookcase.Interactable = narration_interactable
		end

		for i = 1, self.bookcase_info.secret_bookcase_count do
			local bookcase = self.field_object.secret_bookcase(i)
			local narration_interactable = CS.Oak.NarrationInteractable()

			narration_interactable.StringKeys = self.bookcase_info.secret_bookcase_string_keys[day_or_night][i]
			bookcase.Interactable = narration_interactable
		end

		local other_bookcase = self.field_object.opened_puzzle_bookcase_3()
		local narration_interactable = CS.Oak.NarrationInteractable()

		narration_interactable.StringKeys = self.bookcase_info.puzzle_bookcase_string_keys[day_or_night][3]
		other_bookcase.Interactable = narration_interactable
	end
end

return local_class
