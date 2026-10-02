local local_class = newclass("FutureCastlePartB1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 기타 상수
	self.key_num = 2

	-- 타일맵의 필드오브젝트 이름
	self.secret_key_name = 'key_'

	-- 코코 서브이벤트 grid 처리용
	self.in_coco_grid = false

	-- 재진입 시 실험관 내부 버블 제거용
	self.tube_a_name = 'tube_1_'
	self.tube_a_count = 3

	self.tube_b_name = 'tube_2_'
	self.tube_b_count = 4
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MoveFieldObjectEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	return
end

function local_class:need_on_launch()
	local main_quest_id = 195
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return (main_quest ~= nil and (main_quest.InnerProgress == 12))
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MoveFieldObjectEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	self.puzzle_stake_vfo = nil
	self.puzzle_stake = nil
	self.game_ended = true
	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.MoveFieldObjectEvent) then
		if self.puzzle_stake_vfo ~= nil and lua_helper.reference_equals(e.FieldObject, self.puzzle_stake_vfo) then
			self.puzzle_stake.Position = self.puzzle_stake_vfo.Position
		end
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, get_field_object("fake_brazier")) then
			e.Target:Shake(0.06, 0.15)
			music_player:PlaySfxOneShot("02_bomb_holdup_fail_01")
			speech_bubble_util.show_speech_bubble(e.Target, { key = "err_cant_hold_up" })
		end
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridEnterEvent) then
		self:on_camera_grid_enter_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.CameraGridLeaveEvent) then
		self:on_camera_grid_leave_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	-- 열쇠 크기 조절
	for i = 1, self.key_num do
		get_field_object(self.secret_key_name .. i).Transform.localScale = unity_class.vector3.one * 0.8
	end

	-- 들어 던지는 훅샷용 버츄얼 오브젝트
	local puzzle_stake = get_field_object("puzzle_stake")
	local hb = puzzle_stake.Hitbox
	hb.size = hb.size * 0.75

	local tile = CS.Oak.VirtualFieldObject()
	tile.EntityGroup = CS.Oak.EntityGroups.Obstacle
	tile.Position = puzzle_stake.Position
	tile.Hitbox = hb
	local b = CS.Oak.HoldableObjectBehaviour()
	b.ResetType = CS.Oak.ResetEvent.Switch
	b.ResetSwitchName = "long_reset"
	tile.FieldObjectBehaviour = b
	tile.FieldObjectStatsBehaviour = CS.Oak.FieldObjectStatsBehaviour()
	tile.Holdable = CS.Oak.Holdable()
	tile.Holdable.BounceSfxHandleName = "01_bounce_iron_02"
	tile.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
	tile.ActiveState = CS.Oak.ActiveState.Enabled
	self.puzzle_stake_vfo = tile
	self.puzzle_stake = puzzle_stake

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.stake_watcher, self))

	self:play_belt(field:GetZone('coco_sub_zone'))

	-- 일정 이상 진행 되었으면 시험관 버블 제거
	local main_quest = user_progress:GetStartedQuest(195)
	if main_quest ~= nil then
		if main_quest.InnerProgress > 13 then
			for i = 1, self.tube_a_count do
				local cur_tube = get_field_object(self.tube_a_name..i)
				self:change_tube(cur_tube)
			end
		end

		if main_quest.InnerProgress > 14 then
			for i = 1, self.tube_b_count do
				local cur_tube = get_field_object(self.tube_b_name..i)
				self:change_tube(cur_tube)
			end
		end
	end
end

-- 시험관 클리어 모습으로 초기화
function local_class:change_tube(cur_tube)
	local cur_bubble_fx = CS.Utils.FindChildRecursively(cur_tube.transform, 'fx_future_glasstube_bubble_inside')
	cur_bubble_fx.gameObject:SetActive(false)

	--region 시험관 유리 색상 변경
	local cur_renderer = CS.Utils.FindChildRecursively(cur_tube.transform,
			'obj_glasstube'):GetComponent(typeof(CS.UnityEngine.MeshRenderer))

	local cur_mat = cur_renderer.material
	local mesh_color = cur_mat:GetColor("_TintColor")
	-- R 0 G 142 B 45 A 36 계산한 수치
	mesh_color = unity_color({0.34901, 0.20392, 0.45098, 0.30588})
	cur_mat:SetColor("_TintColor", mesh_color)
end

function local_class:stake_watcher()

	while true do
		coroutine.yield(nil)
		if self.puzzle_stake_vfo ~= nil then
			local behaviour = self.puzzle_stake_vfo.FieldObjectBehaviour
			cast(behaviour, typeof(CS.Oak.IFieldObjectBehaviour))
			if behaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped then
				if not lua_helper.reference_equals(self.puzzle_stake.CrashBehaviour, CS.Oak.EtherealCrashBehaviour.Instance) then
					self.puzzle_stake.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
				end
			else
				if not lua_helper.reference_equals(self.puzzle_stake.CrashBehaviour, CS.Oak.WallCrashBehaviour.Instance) then
					self.puzzle_stake.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
				end
			end
		end

		if self.game_ended then
			break
		end
	end

end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'coco_grid' and not self.in_coco_grid then
			self.in_coco_grid = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.play_coco_grid_belt, self))
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, user_party.Leader) or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == 'coco_grid' then
			self.in_coco_grid = false
			return true
		end
	end

	return false
end

function local_class:play_belt(target_zone)
	local belts = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(target_zone.Bounds, unity_class.vector3.zero)

	--- 해당 존에 있는 모든 오브젝트를 순회
	for index = 0, belts.Count - 1 do
		local belt = belts[index]

		if string.sub(belt.Name, 1, 13) == '[gimmick]belt' then
			local animator = belt:GetComponent(typeof(CS.UnityEngine.Animator))
			animator:Play('xmas_belt_rolling')
			belt.ActiveState = active_state('visible')
		end
	end

	belts:Dispose()
end

function local_class:play_coco_grid_belt()
	local ice_blocks = {}
	local start_points = {}
	local time_passeds = {}
	for i = 1, 3 do
		local ice_block_loop = get_character('ice_block_loop_'..i)
		local start_point = field:GetMarker('coco_sub_loop_point_'..i)
		table.insert(ice_blocks, ice_block_loop)
		table.insert(start_points, start_point)
		table.insert(time_passeds, 0)
	end

	local aircraft_loop = music_player_util.play_sfx({ sfx_name = '01_aircraft_loop_01',  fade_in_time = 2,
													  loop = true, type_priority = 'loop', player_priority = 'npc' })

	while self.in_coco_grid do
		for i, ice_block in ipairs(ice_blocks) do
			time_passeds[i] = time_passeds[i] + unity_class.time.deltaTime
			ice_block.Position = start_points[i].position + vector(0,0, time_passeds[i])

			if ice_block.Position.z > 152 then
				ice_block.Position = start_points[1].position
				time_passeds[i] = 0
			end
		end
		coroutine.yield()
	end

	for i, ice_block in ipairs(ice_blocks) do
		ice_block.Position = start_points[i].position
	end

	aircraft_loop:Stop()
	ice_blocks = nil
	start_points = nil
	time_passeds = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}