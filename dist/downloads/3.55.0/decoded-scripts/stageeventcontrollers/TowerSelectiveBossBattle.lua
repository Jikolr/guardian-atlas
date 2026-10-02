local local_class = newclass("TowerSelectiveBossBattle")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	local stage_infos = {
		-- @ zone : 존의 이름 (필수)
		-- @ boss : 해당 존의 보스 이름 (필수)
		-- @ close : 전투 시작시 닫아줄 문들 [1] 문 이름, [2] 개수 (선택)
		-- @ open : 전투 끝날 시 열어줄 문들

		tower_earth_20 = {
			{
				zone = 'battle1',
				boss = 'boss_battle1',
				close = {{ 'battle1_door_', 2 }, { 'battle2_boss_', 2 }},
				open = { }
			},
			{
				zone = 'battle2',
				boss = 'boss_battle2',
				close = {{ 'battle1_door_', 2 }, { 'battle2_boss_', 2 }},
				open = { }
			},
			{
				zone = 'battle3',
				boss = 'boss_battle3',
				close = {{ 'battle3_door_', 2 }, { 'battle4_door_', 2 }},
				open = {'boss_entry_door_1', 'boss_entry_door_2'},
			},
			{
				zone = 'battle4',
				boss = 'boss_battle4',
				close = {{ 'battle3_door_', 2 }, { 'battle4_door_', 2 }},
				open = {'boss_entry_door_1', 'boss_entry_door_2'}
			},
			{
				zone = 'boss',
				close = {{ 'boss_entry_door_', 2 }}
			}
		}
	}

	self.current_stage_info = stage_infos[stage.Name]
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(_)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_start_event(e)
	for _, group in ipairs(self.current_stage_info) do
		local zone_name = group.zone
		-- 처음 시작시 보스 게이트 말고 다 열어줌
		for _, gate in ipairs(group.close) do
			local gate_name = gate[1]
			local gate_count = gate[2]
			for i = 1, gate_count do
				if (zone_name ~= 'boss') then
					message_system:Publish(CS.Oak.DoorOpenEvent.Create(gate_name..i))
				else
					message_system:Publish(CS.Oak.DoorCloseEvent.Create(gate_name..i))
				end
			end
		end
	end
end

function local_class:on_zone_enter_event(e)
	if e.FieldObject ~= user_party_leader or not e.FullEnter then return end

	local zone_name = e.Zone.Name

	for _, data in ipairs(self.current_stage_info) do
		if zone_name == data.zone then
			self:close_gates(data.close)
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	local destroyed_object_name = e.FieldObject.Name

	for _, data in ipairs(self.current_stage_info) do
		if destroyed_object_name == data.boss then
			self:open_gates(data.open)
		end
	end
end


function local_class:open_gates(gate_info)
	if gate_info == nil then return end
	for _, gate_name in ipairs(gate_info) do
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(gate_name))
	end
end

function local_class:close_gates(gate_info)
	if gate_info == nil then return end
	for _, info in ipairs(gate_info) do
		local gate_name = info[1]
		local gate_count = info[2]
		for i = 1, gate_count do
			message_system:Publish(CS.Oak.DoorCloseEvent.Create(string.format("%s%d", gate_name ,i)))
		end
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
