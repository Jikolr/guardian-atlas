local local_class = newclass("NightmareFutureCastle2At2Controller")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.get_grave_stones = function(num)
		return get_field_object('gravestone_' .. num)
	end

	self.get_aisha = function() return get_character('aisha') end
	self.get_steampunk_male = function(num) return get_character('aisha_steampunk_male_' .. num) end

	-- 추모객을 위한 꽃 스프라이트 아이디
	self.flower_id = 20389

	-- 꽃 아이템
	self.flower = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	self.main_quest_id = 217
	self.main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if self.main_quest_progress == nil or self.main_quest_progress.InnerProgress < 1 then
		return true
	end
	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageLoadedEvent) then
		self:on_stage_loaded()
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_loaded()
	self.flower = drop_item_util.create_item({
		pos = self.get_grave_stones(5).Position + vector(0, 0.05, -0.45),
		itemid = self.flower_id, notforinven = true, lootstate = 'dontfindlooter' })

	character_util.add_listener(self.get_aisha(), self.cs_controller)
	character_util.add_listener(self.get_steampunk_male(1), self.cs_controller)
	character_util.add_listener(self.get_steampunk_male(2), self.cs_controller)
end

function local_class:on_interact_event(e)
	for i = 1, 7 do
		local gravestone = self.get_grave_stones(i)

		if lua_helper.reference_equals(e.Target, gravestone) then
			sp_util.play_normal_screenplay(self.interact_gravestone, self, i)
			break
		end
	end

	local aisha = self.get_aisha()
	local steampunk_male_1 = self.get_steampunk_male(1)
	local steampunk_male_2 = self.get_steampunk_male(2)

	if lua_helper.reference_equals(e.Target, aisha) then
		music_player_util.play_sfx_one_shot('01_count_01')
		speech_bubble_util.show_speech_bubble(aisha, { key = 'nightmare_futurecastle_2_aisha_1', skip = false })
	end

	if lua_helper.reference_equals(e.Target, steampunk_male_1) then
		music_player_util.play_sfx_one_shot('01_sleep_02')
		speech_bubble_util.show_speech_bubble(steampunk_male_1, { key = 'nightmare_futurecastle_2_aisha_2', skip = false })
	end

	if lua_helper.reference_equals(e.Target, steampunk_male_2) then
		music_player_util.play_sfx_one_shot('03_runaway_01')
		speech_bubble_util.show_speech_bubble(steampunk_male_2, { key = 'nightmare_futurecastle_2_aisha_3', skip = false })
	end
end
--endregion

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

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	if self.flower ~= nil then
		self.flower:ConsumeComplete()
		self.flower = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:interact_gravestone(index)
	field_ui_util.show_narration_async({ key = ('nightmare_futurecastle_2_grave_' .. index) })
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
