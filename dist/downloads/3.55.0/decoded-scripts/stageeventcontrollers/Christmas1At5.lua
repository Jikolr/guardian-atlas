local local_class = newclass("Christmas1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 커스텀 데이터 id
	self.is_second_door_open_custom_key = 0

	-- 문 이름
	self.first_door_name = 'first_door_'
	self.second_door_name = 'second_door_'

	-- 캐릭터를 가져오는 함수
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		end

		return get_character('knight_female')
	end
	self.get_princess = function() return get_character('princess') end
	self.get_rudolph = function() return get_character('rudolph') end

	-- 오브젝트를 가져오는 함수
	self.get_first_switch = function() return get_field_object('first_sw') end
	self.get_second_switch = function() return get_field_object('second_sw') end
	self.get_first_door = function(num) return get_field_object(self.first_door_name .. num) end
	self.get_second_door = function(num) return get_field_object(self.second_door_name .. num) end
	self.get_sled = function() return get_field_object('sled') end

	-- 몬스터를 가져오는 함수
	self.get_monster = function(battle_num, index)
		return get_character('battle_' .. battle_num .. '_' .. index)
	end

	self.battle_info_list = {
		BATTLE_1 = {
			dir = {
				forward = 'down',
				backward = 'right'
			},
			max_count = 7,
			index = 1,
		},
		BATTLE_2 = {
			dir = {
				forward = 'left',
				backward = 'right'
			},
			max_count = 9,
			index = 2,
		},
		BATTLE_3 = {
			dir = {
				forward = 'up',
				backward = 'left'
			},
			max_count = 7,
			index = 3,
		},
	}

	self.is_second_door_open = false
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')

	local sled = self.get_sled()
	--sled.Transform.localScale = unity_class.vector3.one * 0.4
	sled.Hitbox = CS.Oak.Hitbox(vector(0.75, 0, 0.5), vector(4, 1, 4))
end

function local_class:need_on_launch()
	local christmas_main_quest_id = 60045
	local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)
	local progress_list = {
		13,
		14,
		15
	}

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.SwitchOnOffEvent) then
		return self:on_switch_on_off_event(e)
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	local first_switch = self.get_first_switch()
	local second_switch = self.get_second_switch()

	if lua_helper.reference_equals(e.SwitchObject, first_switch) then
		local christmas_main_quest_id = 60045
		local quest_progress = user_progress:GetStartedQuest(christmas_main_quest_id)

		-- 크리스마스 메인 섹션 14~15 에서만 스위치가 동작하게
		if quest_progress.InnerProgress >= 13 and quest_progress.InnerProgress <= 14 then
			if e.IsTurningOn then
				for i = 1, 2 do
					message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.first_door_name .. i))
				end
				return true
			else
				for i = 1, 2 do
					message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.first_door_name .. i))
				end
				return true
			end
		end
	elseif lua_helper.reference_equals(e.SwitchObject, second_switch) then
		if not self.is_second_door_open and e.IsTurningOn then
			for i = 1, 2 do
				message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.second_door_name .. i))
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.send_second_door_open, self))

			return true
		end
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	for i = 1, 2 do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.first_door_name .. i))
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.second_door_name .. i))
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.first_door_name .. i))
		message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.second_door_name .. i))
	end

	self.is_second_door_open = stage_progress:GetCustomData(self.is_second_door_open_custom_key, false)
	if not self.is_second_door_open then
		for i = 1, 2 do
			message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.second_door_name .. i))
		end
	end

	return true
end
--endregion

function local_class:send_second_door_open()
	self.is_second_door_open = true

	local stage_custom = stage_progress:SetCustomData(self.is_second_door_open_custom_key, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
