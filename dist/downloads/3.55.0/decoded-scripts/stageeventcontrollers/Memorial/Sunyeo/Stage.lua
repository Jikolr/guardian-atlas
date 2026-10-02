local local_class = newclass('MemorialSunyeoController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 7200104

	self.object = {
		breaker_panel = function()
			return get_field_object('s2_fence')
		end,
		building = function()
			return get_field_object('s2_building')
		end,
	}

	self.get_small_talk_npc = function()
		return get_character('s2_first_area_oneline_1')
	end
end

function local_class:dispose()
	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

function local_class:on_event(e)
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

	if quest_progress ~= nil then
		if quest_progress.InnerProgress >= 2 then
			local building = self.object.building()
			animator_util.play(building, 'off')

			if quest_progress.InnerProgress <= 3 then
				local breaker_panel = self.object.breaker_panel()
				breaker_panel.Interactable = CS.Oak.PublishInteractable.Create()
			end
		end
	end

	stage_start_util.start_function(quest_progress)
end

function local_class:on_stage_loaded_event(e)
	local npc = self.get_small_talk_npc()
	character_util.add_lua_listener(npc, self)
	character_util.set_scale_factor(npc, 'smaller', 0.3)

	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
end

function local_class:on_event(e)
	local npc = self.get_small_talk_npc()
	local breaker_panel = self.object.breaker_panel()

	if type_util.is_interacted_target(e, npc) then
		music_player_util.play_sfx_one_shot('03_runaway_02')
		character_util.normal_jump(npc)
		speech_bubble_util.show_speech_bubble(npc, {
			key = 'mm_sunyeo_main_s2_oneline_0_1',
			bubble_type = 'shout',
			scale = 0.6,
		})
		return true

	elseif type_util.is_interacted_target(e, breaker_panel) then
		local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

		if quest_progress ~= nil then
			if quest_progress.InnerProgress >= 2 and quest_progress.InnerProgress <= 3 then
				start_coroutine(self.interact_broken_breaker_panel, self)
			end
		end
	end

	return false
end

function local_class:on_stage_end_event(e)
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
end

function local_class:on_quest_progressed_event(e)
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if quest_progress ~= nil then
		if quest_progress.InnerProgress >= 4 then
			local breaker_panel = self.object.breaker_panel()

			breaker_panel.Interactable = CS.Oak.NonInteractable.Instance
		end
	end
end

function local_class:interact_broken_breaker_panel()
	local sunyeo = user_party.Leader

	scene_util.show_portrait_speech_async(sunyeo, 'mm_sunyeo_main_s2_14', false)
end

return local_class
