local local_class = newclass('CoExpeditionWindPathController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.calculator_table = {}
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CoExpeditionWindPathTriggerEvent), 'on_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.CoExpeditionWindPathTriggerEvent) then
		self.sender = e.Sender

		local info = CS.Oak.StageEventControllerSyncInfo()
		info.Positions:Add(e.StartPos)
		info.Directions:Add(e.Direction)
		info.Strings:Add(e.Sender.Name)
		info.Floats:Add(e.Duration)
		info.Floats:Add(e.Modifier)
		info.Floats:Add(e.Width)
		info.Floats:Add(e.Velocity)

		local command = CS.Oak.StageEventControllerSyncCommand.Create('CoExpeditionWindPathController', info)
		--todo: owner를 보스로?
		command_util.publish_cmd(self.sender.Owner, command)
		return true
	end

	return false
end

function local_class:sync(sync_info)
	local info = CS.Oak.RotatableCubeCollisionInfo()
	info.Size = vector(0, 2, sync_info.Floats[2])
	info.Duration, info.DamageTerm = sync_info.Floats[0], 0.1

	local sender = stage:GetCharacter(sync_info.Strings[0])
	local calculator = CS.Oak.AreaBattleCollision(sender, info)
	calculator.Position = sync_info.Positions[0]
	calculator.Direction = sync_info.Directions[0]

	calculator:Start()
	table.insert(self.calculator_table, {
		calculator = calculator,
		time_passed = 0,
		duration = sync_info.Floats[0],
		info = info,
		sender = sender,
		velocity = sync_info.Floats[3],
		modifier = sync_info.Floats[1]
	})
end

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	for i = #self.calculator_table, 1, -1 do
		local current_table = self.calculator_table[i]

		if current_table.time_passed > current_table.duration then
			current_table.calculator:End()
			table.remove(self.calculator_table, i)
			return
		end

		current_table.time_passed = current_table.time_passed + dt
		current_table.calculator.Position = current_table.calculator.Position + current_table.calculator.Direction * current_table.velocity * dt
		current_table.calculator.Direction = current_table.calculator.Direction
		current_table.info.Size = vector(current_table.time_passed * current_table.velocity * 2, 2, current_table.info.Size.z)
		local objects = current_table.calculator:UpdateFrame(dt)

		for index = 0, objects.Count - 1 do
			local fo = objects[index]

			local damage_info = CS.Oak.DamageInfo()
			damage_info.type = CS.Oak.DamageType.Melee
			damage_info.sender = current_table.sender
			damage_info.target = fo
			damage_info.modifier = current_table.modifier
			damage_info.direction = current_table.calculator.Direction

			command_util.publish_damage(damage_info)
		end
		objects:Dispose()
	end
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
	self.calculator_table = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.CoExpeditionWindPathTriggerEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
