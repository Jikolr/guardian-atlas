local local_class = newclass('NpcPooledController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.npc_pooled_data = nil
	self.npc_pooled_for_zone = {}

	self.enter_zone = ''
end

function local_class:load_resource()
	local npc_pooled_data = require('stageeventcontrollers/NpcPooledData.lua')
	self.npc_pooled_data_for_stage = npc_pooled_data[stage.Name]

	self:make_npc_pool()

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')

end

function local_class:on_zone_enter_event(e)
	local zone_name = e.Zone.Name

	if e.FieldObject ~= user_party.Leader then
		return false
	end

	if not table_util.contain_key(self.npc_pooled_for_zone, zone_name) then
		return false
	end

	if self.enter_zone == zone_name then
		return false
	end

	self.enter_zone = zone_name

	local npc_pooled = self.npc_pooled_for_zone[zone_name]
	for i = 1, #npc_pooled do
		local character = get_character(npc_pooled[i].name)
		if character == nil then
			goto continue
		end

		character.Position = npc_pooled[i].pos
		character.Interactable.Talk = npc_pooled[i].talk
		character_util.set_direction(character, npc_pooled[i].direction)
		character_util.set_anim(character, { name = npc_pooled[i].animation, loop = true })
		character_util.set_emotion(character, { name = npc_pooled[i].emotion })
		speech_bubble_util.remove_bubble(character)

		::continue::
	end
end

function local_class:on_camera_grid_enter_event(e)

end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:make_npc_pool()
	if self.npc_pooled_data_for_stage == nil then
		return
	end

	for npc_name, npc_datas in pairs(self.npc_pooled_data_for_stage) do

		for i = 1, #npc_datas do
			local npc_data = npc_datas[i]

			if npc_data.type == 'zone' then
				if table_util.contain_key(self.npc_pooled_for_zone, npc_data.zone_name) then
					table.insert(self.npc_pooled_for_zone[npc_data.zone_name],
							{ name = npc_name,
							  pos = vector(npc_data.pos[1], npc_data.pos[2], npc_data.pos[3]),
							  talk = lua_helper.get_or_default(npc_data.talk, ''),
							  direction = lua_helper.get_or_default(npc_data.direction, 'up'),
							  animation = lua_helper.get_or_default(npc_data.animation, 'idle'),
							  emotion = lua_helper.get_or_default(npc_data.emotion, 'idle') })
				else
					self.npc_pooled_for_zone[npc_data.zone_name] = {
						{ name = npc_name,
						  pos = vector(npc_data.pos[1], npc_data.pos[2], npc_data.pos[3]),
						  talk = lua_helper.get_or_default(npc_data.talk, ''),
						  direction = lua_helper.get_or_default(npc_data.direction, 'up'),
						  animation = lua_helper.get_or_default(npc_data.animation, 'idle'),
						  emotion = lua_helper.get_or_default(npc_data.emotion, 'idle') }
					}
				end
			end
		end
	end

	local temp = 0
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))

	self.npc_pooled_data = nil
	self.npc_pooled_for_zone = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
