local local_class = newclass("NightmareTeatans1At2Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.harvester_progress =
	{
		none = 0,
		-- 첫번째 출현
		appear1 = 1,
		-- 두번째 출현
		appear2 = 2
	}

	self.harvester_current_progress = self.harvester_progress.none

	self.harvester_speed = 27
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.FullEnter and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if e.Zone.Name == 'harvester_appear_1' and self.harvester_current_progress == self.harvester_progress.none then
				self.harvester_current_progress = self.harvester_progress.appear1
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.harvester_appear1_event, self))
			elseif e.Zone.Name == 'harvester_appear_2' and self.harvester_current_progress == self.harvester_progress.appear1 then
				self.harvester_current_progress = self.harvester_progress.appear2
				coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.harvester_appear2_event, self))
			end
		end
	end

	if event_type == typeof(CS.Oak.StageLoadedEvent) then

		-- 유저가 현재 악몽 티탄왕국 섹션2가 아니라면 이벤트를 보여주지않게함
		local main_quest = user_progress:GetStartedQuest(81)
		if main_quest == nil or main_quest.InnerProgress ~= 1 or main_quest.IsComplete then
			self.harvester_current_progress = self.harvester_progress.appear2

			local people = {
				get_character('harvester_merchant_1'),
				get_character('harvester_shopper_1'),
				get_character('harvester_shopper_2'),
			}
			for _, person in ipairs(people) do
				person.ActiveState = active_state('disabled')
			end
		end
	end

	return false
end

function local_class:harvester_appear1_event()
	local harvester = get_character('harvester')

	local people = {
		get_character('harvester_merchant_1'),
		get_character('harvester_shopper_1'),
		get_character('harvester_shopper_2'),
	}

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local start_pos =  vector(45, 0, -8)
	local end_pos = vector(67,0 , 14)

	harvester.Position = start_pos
	character_util.set_locked_dir(harvester, 'none')
	character_util.set_locked_dir(harvester, 'right')
	harvester.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	harvester.SpineController:ResetAllColors()
	harvester.SpineController:AddColor('darken_harvester', unity_color({ 0, 0, 0, 0.2 }), 1, 0)

	character_util.move_waypoint_async(harvester,
			unity_class.vector3.Lerp(start_pos, end_pos, 0.5), self.harvester_speed, false)

	-- 하베스터 지나가는 sfx
	music_player_util.play_sfx({
		sfx_name = '02_harvester_prepare_01', parent = harvester
	})

	character_util.move_waypoint(harvester, end_pos, self.harvester_speed, false)

	for _, person in ipairs(people) do
		character_util.look_at(person, harvester)
		person:SetEmotion('scared', true)
		person:RemoveAnimation()
		person:Jump(0.5, 0.3)
	end

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local oneline_prefix = 'look_harvester_first_appear_'
	for i, person in ipairs(people) do
		person.Interactable.Talk = oneline_prefix .. i
		person:Shake(0.05, 3)
	end
end

function local_class:harvester_appear2_event()
	coroutine.yield(coroutine_class.wait_for_sec(1))

	local harvester = get_character('harvester')
	local start_pos = vector(106, 0, 12)
	local end_pos = vector(134, 0, 28)

	harvester.Position = start_pos
	character_util.set_locked_dir(harvester, 'none')
	character_util.set_locked_dir(harvester, 'right')
	harvester.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	harvester.SpineController:ResetAllColors()
	harvester.SpineController:AddColor('darken_harvester', unity_color({ 0, 0, 0, 0.2 }), 1, 0)

	-- 하베스터 지나가는 sfx
	music_player_util.play_sfx({
		sfx_name = '02_harvester_prepare_01', parent = harvester
	})

	character_util.move_waypoint_async(harvester, end_pos, self.harvester_speed, false)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
