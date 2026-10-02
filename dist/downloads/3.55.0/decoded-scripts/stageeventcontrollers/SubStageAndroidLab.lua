local local_class = newclass('SubStageAndroidLabController')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.conveyor_item_id_list = {
		{ 20947, 20948, 20947, 20949, 20947, 20949, 20947, 20947 },
		--여기 20949는 몸통대신 머리임
		{ 20948, nil, 20948, 20948, 20947, nil },
		--3-1~3-2
		{ 20956, 20957 },
		--3-3~3-5
		{ 20954, 20952, 20894, 20955, },
		--5. 마지막 몸통은 머리임
		{ nil, 20947, 20948, nil }
	}

	self.get_shear_controller = function()
		return get_field_object('shear_controller')
	end
	self.shear_controller = nil
	self.default_shear_value = 0.03

	self.get_part_init_pos = function(target_idx, pos_idx)
		return field_util.get_marker_pos('s1_part_init_pos_' .. target_idx .. '_' .. pos_idx)
	end

	self.item_list_list = {}

	--1~3
	self.get_s4_puzzle_switch = function(idx)
		return get_field_object('s4_puzzle_switch_' .. idx)
	end
	--1~3
	self.get_s4_puzzle_switch_perma = function(idx)
		return get_field_object('s4_puzzle_switch_perma_' .. idx)
	end
	----1~3
	self.get_s4_puzzle_door = function(idx)
		return get_field_object('s4_puzzle_door_' .. idx)
	end
	--1,2. 1은 5섹션 공간에만, 2는 신전공간(2,3,4 섹션)
	self.get_directional_light = function(idx)
		return get_field_object('[gimmick]directional_light_' .. idx)
	end

	self.is_puzzle_switch_work = {
		true,
		true,
		true
	}

end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self:dispose_item()
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
	start_coroutine(self.pre_setting, self)
	self:setting_item()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))

	--라이트 조절. 기본은 신전이니 2만 활성화
	self.get_directional_light(1).ActiveState = active_state('disabled')
	self.get_directional_light(2).ActiveState = active_state('enabled')

end
--endregion

function local_class:on_launch_routine()
	coroutine.yield(nil)

	local main_quest_id = 341
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	if quest_progress.InnerProgress == 0 then
		stage_launch_util.play_launch_stage('down',
				field_util.get_marker_pos('default_start'), true, true)
	elseif quest_progress.InnerProgress == 1 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s2_start'), true, true)
	elseif quest_progress.InnerProgress == 2 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s3_start'), true, true)
	elseif quest_progress.InnerProgress == 3 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s3_start'), true, true)
	elseif quest_progress.InnerProgress == 4 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s3_start'), true, true)
	elseif quest_progress.InnerProgress == 5 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s3_start'), true, true)
	elseif quest_progress.InnerProgress == 6 then
		stage_launch_util.play_launch_stage('right',
				field_util.get_marker_pos('s3_start'), true, true)
	end
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, user_party.Leader, 'shear_zero_zone')
			and self.shear_controller ~= nil then
		self.shear_controller.Shear = 0
		return true
	end

	if type_util.is_zone_full_enter(e, user_party.Leader, 's5_room') then
		self.get_directional_light(1).ActiveState = active_state('enabled')
		self.get_directional_light(2).ActiveState = active_state('disabled')
		return true
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, user_party.Leader, 'shear_zero_zone')
			and self.shear_controller ~= nil then
		self.shear_controller.Shear = self.default_shear_value

		return true
	end

	if type_util.is_zone_full_leave(e, user_party.Leader, 's5_room') then
		self.get_directional_light(1).ActiveState = active_state('disabled')
		self.get_directional_light(2).ActiveState = active_state('enabled')
		return true
	end

	return false
end

function local_class:on_switch_on_off_event(e)
	for i = 1, 3 do
		local switch_perma = self.get_s4_puzzle_switch_perma(i)
		local door = self.get_s4_puzzle_door(i)

		if lua_helper.reference_equals(e.SwitchObject, switch_perma) and e.IsTurningOn then
			self.is_puzzle_switch_work[i] = false
			--열어줌
			message_system:PublishSync(CS.Oak.DoorOpenEvent.Create(door.name))
			field_object_util.create_virtual_field_object(door.Position,
					{ crash_behaviour = CS.Oak.EtherealCrashBehaviour.Instance })
		end
	end

end
--endregion

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

function local_class:pre_setting()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')

	self.shear_controller = self.get_shear_controller():GetComponent(typeof(CS.Oak.ShearController))
	self.default_shear_value = self.shear_controller.Shear
end

function local_class:setting_item()
	for conveyor_num = 1, #self.conveyor_item_id_list do
		for item_num = 1, #self.conveyor_item_id_list[conveyor_num] do
			local id = self.conveyor_item_id_list[conveyor_num][item_num]
			if id ~= nil then
				local item = drop_item_util.create_item({
					pos = self.get_part_init_pos(conveyor_num, item_num),
					itemid = id, notforinven = true,
					lootstate = 'dontfindlooter', sprscale = 1.0
				})
				table.insert(self.item_list_list, item)

			end

		end

	end
end

function local_class:dispose_item()
	for i = 1, #self.item_list_list do
		if self.item_list_list[i] ~= nil then
			self.item_list_list[i]:ConsumeComplete()
			self.item_list_list[i] = nil
		end
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
