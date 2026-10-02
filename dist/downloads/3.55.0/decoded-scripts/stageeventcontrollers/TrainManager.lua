local local_class = newclass("TrainManagerController")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller

	if scene ~= nil then
		self.scene = scene()
	end

	self.backup_intactable = {}

	self.is_train_move = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact')

	if stage.Name == 'steampunk_1_1' then
		self.stage1_train2 = get_character('train_2')
		self.stage1_train2_levers = { get_field_object('stage1_lever2') }
		self.stage1_train2_zones = { 'stage1_train2_zone1', 'stage1_train2_zone2', 'stage1_train2_zone3' }
	elseif stage.Name == 'steampunk_1_2' then
		self.stage2_train3 = get_character('train_3')
		self.stage2_train3_levers = { get_field_object('stage2_lever1_1'), get_field_object('stage2_lever1_2') }
		self.stage2_train3_zones = { 'stage2_train_3_zone1', 'stage2_train_3_zone2', 'stage2_train_3_zone3', 'stage2_train_3_zone4' }
	elseif stage.Name == 'steampunk_1_3' then
		self.stage3_train1 = get_character('train_1')
		self.stage3_train1_levers = { get_field_object('stage3_lever1_1'), get_field_object('stage3_lever1_2') }
		self.stage3_train1_zones = { 'stage3_train1_zone1', 'stage3_train1_zone2', 'stage3_train1_zone3', 'stage3_train1_zone4' }
	elseif stage.Name == 'steampunk_1_4' then
		self.stage4_train3 = get_character('train_3')
		self.stage4_train3_levers = { get_field_object('stage4_lever3_1') }
		self.stage4_train3_zones = { 'stage4_train3_zone1', 'stage4_train3_zone2', 'stage4_train3_zone3' }
	end

	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
end

function local_class:on_event(e)

	return true
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:on_zone_enter(e)
	-- Zone을 완전히 들어온게 아니라면 리턴
	if e.FullEnter == false then
		return false
	end

	-- 스테이지1
	if stage.Name == 'steampunk_1_1' then
		-- 2번 기차
		if e.FieldObject == self.stage1_train2 and table_util.contain_value(self.stage1_train2_zones, e.Zone.Name) then
			self:revert_levers(self.stage1_train2_levers)
		end
	-- 스테이지2
	elseif stage.Name == 'steampunk_1_2' then
		-- 3번 기차
		if e.FieldObject == self.stage2_train3 and table_util.contain_value(self.stage2_train3_zones, e.Zone.Name) then
			self:revert_levers(self.stage2_train3_levers)
		end
	-- 스테이지3
	elseif stage.Name == 'steampunk_1_3' then
		-- 1번 기차
		if e.FieldObject == self.stage3_train1 and table_util.contain_value(self.stage3_train1_zones, e.Zone.Name) then
			self:revert_levers(self.stage3_train1_levers)
		end
	-- 스테이지4
	elseif stage.Name == 'steampunk_1_4' then
		-- 3번 기차
		if e.FieldObject == self.stage4_train3 and table_util.contain_value(self.stage4_train3_zones, e.Zone.Name) then
			self:revert_levers(self.stage4_train3_levers)
		end
	end

	return true
end

function local_class:on_zone_leave(e)
	if e.FullLeave == false then
		return false
	end

	-- 스테이지1
	if stage.Name == 'steampunk_1_1' then
		-- 2번 기차
		if e.FieldObject == self.stage1_train2 and table_util.contain_value(self.stage1_train2_zones, e.Zone.Name) then
			self:backup_levers(self.stage1_train2_levers)
		end
	-- 스테이지2
	elseif stage.Name == 'steampunk_1_2' then
		-- 3번 기차
		if e.FieldObject == self.stage2_train3 and table_util.contain_value(self.stage2_train3_zones, e.Zone.Name) then
			self:backup_levers(self.stage2_train3_levers)
		end
	-- 스테이지3
	elseif stage.Name == 'steampunk_1_3' then
		-- 1번 기차
		if e.FieldObject == self.stage3_train1 and table_util.contain_value(self.stage3_train1_zones, e.Zone.Name) then
			self:backup_levers(self.stage3_train1_levers)
		end
	-- 스테이지4
	elseif stage.Name == 'steampunk_1_4' then
		-- 3번 기차
		if e.FieldObject == self.stage4_train3 and table_util.contain_value(self.stage4_train3_zones, e.Zone.Name) then
			self:backup_levers(self.stage4_train3_levers)
		end
	end

	return true
end

function local_class:on_interact(e)
	if self.is_train_move == false then
		return false
	end

	-- 스테이지1
	if stage.Name == 'steampunk_1_1' then
		-- 2번 기차
		if table_util.contain_value(self.stage1_train2_levers, e.Target) == false then
			return false
		end
	-- 스테이지2
	elseif stage.Name == 'steampunk_1_2' then
		-- 3번 기차
		if table_util.contain_value(self.stage2_train3_levers, e.Target) == false then
			return false
		end
	-- 스테이지3
	elseif stage.Name == 'steampunk_1_3' then
		-- 1번 기차
		if table_util.contain_value(self.stage3_train1_levers, e.Target) == false then
			return false
		end
	-- 스테이지4
	elseif stage.Name == 'steampunk_1_4' then
		-- 3번 기차
		if table_util.contain_value(self.stage4_train3_levers, e.Target) == false then
			return false
		end
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.show_narration_box_routine, self))

	return true
end

function local_class:show_narration_box_routine()
	stage.FieldUIManager:Hide()

	stage.FieldUINarrationBox:Show()
	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString("steampunk_move_lock_lever"), 0, 1))
	stage.FieldUINarrationBox:Hide()

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	stage.FieldUIManager:Show()
end

function local_class:revert_levers(levers)
	-- Interactable이 Publish가 아니라면 바꿀 필요가 없다.
	if lua_helper.type_compare(levers[1].Interactable, typeof(CS.Oak.PublishInteractable)) == false then
		return
	end

	for i = 1, #levers do
		levers[i].Interactable = self.backup_intactable[i]
	end

	self.is_train_move = false
end

function local_class:backup_levers(levers)
	-- Interactable이 RotateRailLever가 아니라면 Backup할 필요가 없다.
	if lua_helper.type_compare(levers[1].Interactable, typeof(CS.Oak.RotateRailLeverInteractable)) == false then
		return
	end

	for i = 1, #levers do
		table.insert(self.backup_intactable, levers[i].Interactable)
		levers[i].Interactable = CS.Oak.PublishInteractable.Create()
	end

	self.is_train_move = true
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
