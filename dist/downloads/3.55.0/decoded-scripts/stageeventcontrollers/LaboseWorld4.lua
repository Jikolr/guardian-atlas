local local_class = newclass('LaboseWorld4Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.main_quest_id = 386

	self.champion_sword_item = nil
end

function local_class:dispose()
	self.cs_controller = nil
	self.scene = nil

	if self.champion_sword_item ~= nil then
		self.champion_sword_item:ConsumeComplete()
		self.champion_sword_item = nil
	end
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.operator_ui = get_or_create_global_table('Quest/Main/CivilWar/Common/OperatorUI')
	self.operator_ui:load_async()
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end
--endregion

--region event
function local_class:on_event(e)
	return true
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

function local_class:launch_routine()
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	-- 시작 연출
	if quest_progress == nil or quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field_util.get_marker_pos('default_start'),
				true, true)
	elseif quest_progress.InnerProgress == 14 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 15 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start')
		, false, false)
	elseif quest_progress.InnerProgress == 16 then
		stage_launch_util.play_launch_stage('up', field_util.get_marker_pos('default_start')
		, false, false)
	else
		stage_launch_util.play_launch_stage('left', field_util.get_marker_pos('default_start'),
				true, true)
	end

	local pos = field_util.get_marker_pos('s15_camera_pos')
	self.champion_sword_item = self:create_champion_sword_on_floor(vector_util.get_x0z(pos, -0.7))
end

function local_class:create_champion_sword_on_floor(position)
	local champion_sword = drop_item_util.create_item({
		pos = position,
		itemid = 21142,
		notforinven = true,
		lootstate = 'dontfindlooter',
		sprscale = 0.75,
		showoncharacter = true,
	})

	champion_sword.Position = position
	champion_sword.SpriteTransform.position = position + vector(-0.06, 1, 0.1)
	champion_sword.SpriteTransform.localRotation = unity_class.quaternion.Euler(-35, 180, -134)
	champion_sword.ShadowTransform.gameObject:SetActive(false)

	return champion_sword
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
