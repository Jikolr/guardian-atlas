--- 콜라보 전생슬 미니게임
local local_class = newclass('ShortStorySlimeBuildController')

function local_class:init()
	-- 메인 컨트롤러
	self.main_controller = nil
	self.destroyed_obstacles = {}

	self.bulletin_board_handle_name = 'management_bulletin_board'
	self.delivery_box_handle_name = 'delivery_box'
	self.craft_table_handle_name = 'craft_table'
	self.fountain_handle_name = 'fountain'

	self.build_anim_fx_4x4_name = 'short_story_slime_corporation_4x4'
	self.build_anim_fx_6x4_name = 'short_story_slime_corporation_6x4'

	self.fountain_base_id = 8

	-- 주택의 주민 변동 횟수
	self.move_in_out_count = 0

	-- 해당 횟수만큼 주택의 주민이 변동 되었을 때 저장한다
	self.save_move_in_out_count = 4
end

-- Constant 데이터 및 메인 컨트롤러 쪽 세팅
function local_class:set_constants_data(main_controller, constants_data)
	self.main_controller = main_controller

	self.building_specs_data = constants_data['BuildingSpecs']
	self.build_spots_data = constants_data['BuildSpots']
	self.craft_item_specs_data = constants_data['CraftItemSpecs']

	-- 에셋 프리로드
	for i, spec in pairs(self.building_specs_data) do repeat
		if i == 0 then
			break
		end
		unity_object_pool.GetOrCreate(spec.asset_name)
		break
	until true end
	unity_object_pool.GetOrCreate(self.build_anim_fx_6x4_name)
	unity_object_pool.GetOrCreate(self.build_anim_fx_4x4_name)

	for i = 1, 3 do
		local fountain_fx_name = 'wall_fountain_'..i
		unity_object_pool.GetOrCreate(fountain_fx_name)
	end

	self.handle_name_objects = {}
	self.handle_name_objects[self.bulletin_board_handle_name] = get_field_object(self.bulletin_board_handle_name)
	self.handle_name_objects[self.delivery_box_handle_name] = get_field_object(self.delivery_box_handle_name)
	self.handle_name_objects[self.craft_table_handle_name] = get_field_object(self.craft_table_handle_name)
	self.handle_name_objects[self.fountain_handle_name] = get_field_object(self.fountain_handle_name)

	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	--message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
end

--region init_building

-- 건물 건설 위치 초기화
function local_class:init_build_spots()
	self.build_spots_state = {}

	for handle_name, _ in pairs(self.build_spots_data) do
		-- 핸들네임으로 fo 찾기
		local fo = get_field_object(handle_name)
		local state = {
			field_object = fo,
			pooled_object = nil,
			id = 0
		}

		-- 임시
		if string.len(handle_name) > 13 then
			local substring = string.sub(handle_name, 1, 13)
			if substring == 'building_obj_' then
				local index = tonumber(string.sub(handle_name, 14))
				state.index = index
			end
		end

		if handle_name == 'guest_house' then
			local fountain_fo = get_field_object(self.fountain_handle_name)
			state.fountain = {
				field_object = fountain_fo,
				pooled_object = nil,
				id = 0
			}
		end

		self.build_spots_state[handle_name] = state
	end

	self.handle_name_objects[self.bulletin_board_handle_name].ActiveState = CS.Oak.ActiveState.Disabled
end

function local_class:init_guest_house(level)
	if level == 0 or level > 3 then
		return
	end

	local handle_name = 'guest_house'
	local building_id = self.build_spots_data[handle_name] + level - 1
	local spec = self.building_specs_data[building_id]
	local fo = get_field_object(handle_name)

	local state = self.build_spots_state[handle_name]
	if state == nil then
		state = {}
	end
	state.id = building_id
	fo.ActiveState = CS.Oak.ActiveState.InField
	fo.Interactable = CS.Oak.NonInteractable.Instance
	state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	state.field_object = fo

	self.build_spots_state[handle_name] = state

	self.handle_name_objects[self.bulletin_board_handle_name].ActiveState = CS.Oak.ActiveState.Enabled

	self:init_fountain(level)
end

function local_class:init_fountain(level)
	if level == 0 or level > 3 then
		return
	end

	local fountain_fo = get_field_object(self.fountain_handle_name)
	local position = fountain_fo.Position
	fountain_fo.ActiveState = CS.Oak.ActiveState.InField
	fountain_fo.Interactable = CS.Oak.NonInteractable.Instance

	local fountain_id = self.fountain_base_id + level - 1
	local fountain_spec = self.building_specs_data[fountain_id]
	local guest_house_state = self.build_spots_state['guest_house']
	if guest_house_state.fountain == nil then
		guest_house_state.fountain = {}
	end
	guest_house_state.fountain.pooled_object = unity_object_pool.GetOrCreate(fountain_spec.asset_name):Instantiate(position)
	guest_house_state.fountain.field_object = fountain_fo
	guest_house_state.fountain.id = fountain_id
end

function local_class:init_forge()
	local handle_name = 'forge'
	local building_id = self.build_spots_data[handle_name]
	local spec = self.building_specs_data[building_id]
	local fo = get_field_object(handle_name)
	local state = {
		id = building_id
	}

	fo.ActiveState = CS.Oak.ActiveState.InField
	fo.Interactable = CS.Oak.NonInteractable.Instance

	state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	state.field_object = fo

	self.build_spots_state[handle_name] = state
end

function local_class:init_potion_store()
	local handle_name = 'potion_store'
	local building_id = self.build_spots_data[handle_name]
	local spec = self.building_specs_data[building_id]
	local fo = get_field_object(handle_name)
	local state = {
		id = building_id
	}

	fo.ActiveState = CS.Oak.ActiveState.InField
	fo.Interactable = CS.Oak.NonInteractable.Instance

	state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	state.field_object = fo

	self.build_spots_state[handle_name] = state
end

function local_class:init_hot_spring()
	local handle_name = 'hot_spring_build_rock'
	local building_id = self.build_spots_data[handle_name]
	local spec = self.building_specs_data[building_id]
	local fo = get_field_object(handle_name)
	local state = {
		id = building_id
	}

	fo.ActiveState = CS.Oak.ActiveState.InField
	fo.Interactable = CS.Oak.NonInteractable.Instance

	state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	state.field_object = fo

	self.build_spots_state[handle_name] = state
end

function local_class:init_house(index)
	local handle_name = 'building_obj_' .. index
	if self.build_spots_data[handle_name] == nil then
		return
	end

	local building_id = self.build_spots_data[handle_name]
	local fo = get_field_object(handle_name)
	local spec = self.building_specs_data[building_id]

	if spec == nil then
		return
	end

	local state = {
		id = building_id,
		index = index
	}

	fo.ActiveState = CS.Oak.ActiveState.InField
	self:attach_target_bound_publish_interactable(fo)

	state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	state.field_object = fo

	self.build_spots_state[handle_name] = state
end

-- 공터 Interactable 넣어줌
function local_class:init_stage_interactable()
	for handle_name, _ in pairs(self.build_spots_data) do
		local state = self.build_spots_state[handle_name]
		if state.id == 0 then
			if handle_name ~= 'hot_spring_build_rock' then
				self:attach_target_bound_publish_interactable(state.field_object)
			end
		end
	end
end

--endregion

-- 핸들네임 위치에 현재 지어진 건물 스펙
function local_class:get_current_building_spec_by_handle_name(handle_name)
	local state = self.build_spots_state[handle_name]

	if state == nil then
		return nil
	end

	return self.building_specs_data[state.id]
end

-- 현재 지어진 영빈관 레벨
function local_class:get_current_guest_house_level()
	local spec = self:get_current_building_spec_by_handle_name('guest_house')
	if spec == nil then
		return 0
	end

	return spec.level
end

-- 핸들네임 위치에 지어진 건물의 build_type
function local_class:get_current_build_type(handle_name)
	local state = self.build_spots_state[handle_name]

	if state == nil then
		return nil
	end

	return self.building_specs_data[state.id].build_type
end

-- 해당 핸들네임에 지을 수 있는 건물이 특수 건물인지
function local_class:get_buildable_build_type(handle_name)
	if self.build_spots_data[handle_name] == nil then
		return nil
	end
	return self.building_specs_data[self.build_spots_data[handle_name]].build_type
end

-- 해당 필드 오브젝트가 공터에 지어진 건물이면 그에 맞는 핸들네임 반환, 공터인지도 반환
function local_class:get_handle_name_by_fo(fo)
	for handle_name, obj in pairs(self.handle_name_objects) do
		if lua_helper.reference_equals(obj, fo) then
			return handle_name, handle_name
		end
	end

	for handle_name, data in pairs(self.build_spots_state) do
		if lua_helper.reference_equals(data.field_object, fo) then
			return handle_name, self.building_specs_data[data.id].build_type
		end
	end

	return nil, nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	-- 그리드 떠날 때 채집 자원 리셋
	if event_type == typeof(CS.Oak.CameraGridLeaveEvent) then
		for _, fo in ipairs(self.destroyed_obstacles) do
			fo.FieldObjectBehaviour:ResetObstacle()
		end
		self.destroyed_obstacles = {}
	--[[elseif event_type == typeof(CS.Oak.ItemGetEvent) then
		if not e.Item.NotForInventory then
			return false
		end

		local item_data = game_data_service.GetData('ItemData')
		local spec = item_data:GetSpec(e.Item.ItemId)
		if spec == nil then
			return false
		end]]--
	end

	return false
end

function local_class:on_interact_event(e)
	local target = e.Target

	-- 해당 필드 오브젝트가 공터에 지어진 건물인지 확인
	local handle_name, build_type = self:get_handle_name_by_fo(target)
	if handle_name == nil then
		return false
	end

	if build_type == 'build_spot' then
		-- 집이나 포션 상점만 직접 건설
		local buildable_build_type = self:get_buildable_build_type(handle_name)
		if buildable_build_type ~= 'house' and buildable_build_type ~= 'potion_store' then
			return false
		end

		-- 건설
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.pop_build_ui_routine, self, handle_name, target))
	elseif build_type == 'house' then
		-- 주택 입주민 관리
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.pop_residence_manage_ui_routine, self, target))
	elseif build_type == 'craft_table' then
		-- 제작
		local recipe_ids = self:get_craft_item_ids()
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.pop_craft_item_ui_routine, self, target, recipe_ids))
	elseif build_type == 'management_bulletin_board' then
		-- 영빈관 관리 및 업그레이드
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.pop_guest_house_ui_routine, self, 'guest_house', target))
	elseif build_type == 'delivery_box' then
	end

	return false
end

function local_class:on_fo_destroyed_event(e)
	local fo = e.FieldObject
	local behaviour_type = fo.FieldObjectBehaviour:GetType()

	if behaviour_type ~= typeof(CS.Oak.SlimeObstacleFieldObjectBehaviour) then
		return false
	end

	-- TODO: 자원 드랍 수량 확인
	local drop_amount = 10

	-- 얻은 재료 바로 갱신하고 ui는 합산해서 갱신
	local drop_item_id = fo.FieldObjectBehaviour.DropItemId
	self.main_controller:set_resource_add_stack(drop_item_id, drop_amount)

	-- 플로팅 텍스트 출력
	local resource_string = drop_item_id == 21193 and game_string:GetString('shortstory_slime_wood') or
			game_string:GetString('shortstory_slime_stone')
	CS.Oak.FieldUIFloatingText.Get(get_party_leader()):JustPrintItemName(resource_string .. ' +' .. drop_amount)

	fo.FieldObjectBehaviour:DropReward(drop_amount)

	table.insert(self.destroyed_obstacles, fo)
end

-- 파티 정렬
function local_class:align_party(target, dist, direction_vector, last_direction, align_party_member)
	if dist == nil then
		dist = 0.5
	end

	if direction_vector == nil then
		direction_vector = unity_class.vector3.back
	end

	if last_direction == nil then
		last_direction = CS.Oak.Direction.Up
	end

	if align_party_member == nil then
		align_party_member = true
	end

	local duration = 0.5

	local target_pos = target.Bounds.center + direction_vector * (target.Bounds.extents.z + dist)
	target_pos.y = 0

	local leader = user_party[0]
	wp_util.move(leader, target_pos, nil, duration,
			{ last_direction = last_direction, y_mode = 'floor' })

	if align_party_member then
		local count = user_party.Count
		if count > 1 then
			local space_between = 1
			local left_pos = target_pos + unity_class.vector3(- space_between * (count - 2) * 0.5, 0, -1)
			for i = 1, count - 1 do
				local member = user_party[i]
				local pos = left_pos + space_between * (i - 1) * unity_class.vector3.right
				wp_util.move(member, pos, nil, duration,
						{ last_direction = last_direction, y_mode = 'floor' })
			end
		end
	end

	coroutine.yield(coroutine_class.wait_for_sec(0.5))
end

--region building

-- 해당 핸들네임의 공터에 지을 수 있는 건물 id
function local_class:get_buildable_id(handle_name)
	if self.build_spots_data[handle_name] == nil then
		return nil
	end

	return self.build_spots_data[handle_name]
end

-- ShortStorySlimeBuildingSpec MakeData
function local_class:make_building_spec_data(id)
	if id < 1 then
		return nil
	end

	local item_data = game_data_service.GetData('ItemData')
	local building_spec = self.building_specs_data[id]

	local name = building_spec.name
	local build_type = building_spec.build_type

	local max_num = 1
	if build_type == 'house' then
		-- 주택의 경우 영빈관 레벨에 따라 최대 갯수 변경
		max_num = self.main_controller:get_max_build_count()
	end

	local cost_list = create_generic_list(typeof(CS.Oak.UI.ShortStorySlimeCraftCost))
	for _, data in ipairs(building_spec.resource_cost) do
		if data.value > 0 then
			local item_spec = item_data:GetSpec(data.id)
			local cost_data = CS.Oak.UI.ShortStorySlimeCraftCost.MakeData(item_spec, data.value)
			cost_list:Add(cost_data)
		end
	end

	local spec_for_ui = CS.Oak.UI.ShortStorySlimeBuildingSpec.MakeData(
			id, name, building_spec.sprite_name, max_num, cost_list, building_spec.guest_house_level,
			building_spec.sprite_scale, building_spec.level, building_spec.happiness, building_spec.build_type,
			building_spec.upgrade_id, building_spec.happiness_required
	)

	return spec_for_ui
end

-- 공터 건설 루틴
function local_class:pop_build_ui_routine(handle_name, target, screenplay_routine, options)
	local new_building_id = self:get_buildable_id(handle_name)
	if new_building_id < 1 then
		return
	end

	local show_ui_on_sp_end = lua_helper.get_value(options, 'show_ui_on_sp_end', true)

	for i = 0, user_party.Count - 1 do
		character_util.stop(user_party[i])
	end
	field_ui_manager:Hide()

	coroutine.yield(self:align_party(target))

	music_player:PlaySfxOneShot('01_craft_01')
	local build_state = CS.Oak.UI.ShortStorySlimeBuildPopupState()

	-- 스테이트 데이터 저장
	build_state.CurrentBuilding = self:make_building_spec_data(new_building_id)

	local confirmed = false
	build_state.OnConfirm = function()
		confirmed = true
	end

	-- 오버레이 띄움
	coroutine.yield(CS.Oak.UI.UISceneManager.Instance:PushOverlayRoutine(CS.Oak.UI.ShortStorySlimeBuildPopup.Instance,
			build_state, typeof(CS.Oak.UI.ShortStorySlimeBuildPopup)))

	-- 오버레이 연출 다 끝날때 까지 대기
	local waitCoroutine = CS.Oak.UI.WaitUntilOverlayClosed(CS.Oak.UI.UISceneManager.Instance)
	coroutine.yield(waitCoroutine)

	self.main_controller:all_add_resource_tween_disable()

	if confirmed then
		if screenplay_routine == nil then
			screenplay_routine = function(target_fo, _handle_name, building_id)
				self:default_building_screenplay(target_fo, _handle_name, building_id)
			end
		end

		coroutine.yield(screenplay_routine(target, handle_name, new_building_id))

		-- 갱신
		-- 자원 소모 등 후처리

		-- 자원 소모
		for _, resource_data in pairs(self.building_specs_data[new_building_id].resource_cost) do
			self.main_controller:update_resource_and_update_status(resource_data.id, -resource_data.value)
		end

		-- 건물 정보 업데이트
		local index = self.build_spots_state[handle_name].index
		if index ~= nil then
			self.main_controller:build_building_on_spot(index)
		end

		local data_storage = self.main_controller:get_data_storage()

		-- 물약 상점이면 활성화
		if handle_name == 'potion_store' then
			-- 포션 공장 입구 세팅
			self.main_controller:set_potion_store_entrance()

			-- 실제 데이터 갱신
			data_storage:set_activate_special_building('potion_store')
		end

		-- 온천을 제외하고 다른 건물이 지어질 때만 주민 퇴거
		if handle_name ~= 'hot_spring_build_rock' then
			-- 건물이 지어질 때 일정확률로 주민 퇴거
			self.main_controller:moved_out_villager(false)
		end

		-- 모든 데이터 저장
		data_storage:all_save()

		-- UI 및 수치 갱신
		self.main_controller:update_status_ui()
		self.main_controller:show_add_resource_right_status()
	end

	-- not confirmed or (confirmed and show_ui_on_sp_end)
	if not confirmed or show_ui_on_sp_end then
		field_ui_manager:Show()
		user_party:ResetControllers()
	end
end

-- 건설 기본 연출
function local_class:default_building_screenplay(target, handle_name, building_id)
	-- 이펙트 로드
	local build_anim_pool = handle_name == 'guest_house'
			and unity_object_pool.GetOrCreate(self.build_anim_fx_6x4_name)
			or unity_object_pool.GetOrCreate(self.build_anim_fx_4x4_name)

	local new_object_pool = unity_object_pool.GetOrCreate(self.building_specs_data[building_id].asset_name)

	while build_anim_pool.State ~= CS.Oak.UnityObjectPoolState.Loaded do
		coroutine.yield(nil)
	end

	while new_object_pool.State ~= CS.Oak.UnityObjectPoolState.Loaded do
		coroutine.yield(nil)
	end

	local leader = user_party.Leader

	leader:HideWeapon(true)
	leader.SpineController:ForceUpdateSpines(0)

	coroutine.yield(self:align_party(target, 1, nil, nil, false))

	-- 좌우 이동
	--[[local start_pos = leader.Position

	wp_util.move(leader, start_pos + unity_class.vector3.right * 2, 4, nil,
			{ last_direction = CS.Oak.Direction.Left, y_mode = 'floor' })
	while leader.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('03_equipping_01')
	character_util.set_anim(leader, { name = "eat", loop = true })
	coroutine.yield(coroutine_class.wait_for_sec(1))
	character_util.remove_anim(leader, false)

	wp_util.move(leader, start_pos + unity_class.vector3.left * 2, 4, nil,
			{ last_direction = CS.Oak.Direction.Right, y_mode = 'floor' })
	while leader.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped do
		coroutine.yield(nil)
	end

	music_player:PlaySfxOneShot('03_equipping_01')
	character_util.set_anim(leader, { name = "eat", loop = true })
	coroutine.yield(coroutine_class.wait_for_sec(1))
	character_util.remove_anim(leader, false)

	wp_util.move(leader, start_pos, 4, nil,
			{ last_direction = CS.Oak.Direction.Left, y_mode = 'floor' })
	while leader.FieldObjectBehaviour.CurrentAction ~= CS.Oak.FieldObjectAction.Stopped do
		coroutine.yield(nil)
	end]]--

	character_util.set_direction(leader, 'left')
	local equip_sfx = music_player_util.play_sfx({sfx_name = '03_equipping_01', loop = true})
	character_util.set_anim(leader, { name = "eat" })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('01_build_building_01')
	local upgrade_object, animator = self:play_build_anim(target, handle_name)

	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(leader, 'right')
	character_util.set_anim(leader, { name = "eat" })
	coroutine.yield(coroutine_class.wait_for_sec(1))

	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(leader, 'left')
	character_util.set_anim(leader, { name = "eat", loop = true })
	coroutine.yield(coroutine_class.wait_for_sec(1))
	music_player:PlaySfxOneShot('01_mining_01')

	-- 오브젝트 상태 변경
	self:change_build_spot_state(handle_name, building_id)

	-- 건축 완료
	animator:Play('off')
	coroutine.yield(coroutine_class.wait_for_sec(1.0))
	music_player:PlaySfxOneShot('01_heavenhold_build_complete_01')
	coroutine.yield(coroutine_class.wait_for_sec(0.25))
	upgrade_object:Dispose()

	leader:HideWeapon(false)
	leader.SpineController:ForceUpdateSpines(0)
	equip_sfx:Stop()

	music_player:PlaySfxOneShot('01_stage_intro_jump_01')
	character_util.remove_anim(leader)
	character_util.set_anim_and_emotion(leader, { name = 'victory_get', loop = false }
	, { name = 'smile', loop = true })

	coroutine.yield(coroutine_class.wait_for_sec(1.5))

	character_util.remove_anim_and_emotion(leader)
end

-- 건설 위치 상태 변경 (id, 필드 오브젝트, 외형)
function local_class:change_build_spot_state(handle_name, new_building_id)
	local spec = self.building_specs_data[new_building_id]
	local state = self.build_spots_state[handle_name]

	-- 업그레이드가 아니고 공터에서 새 건물을 짓는 경우
	if state ~= nil and state.id == 0 then
		-- 집이 아니면 직접 상호작용 하지 않게 변경
		local fo = state.field_object
		if spec.build_type == 'house' then
			self:attach_target_bound_publish_interactable(fo)
		else
			if spec.build_type == 'guest_house' then
				self.handle_name_objects[self.bulletin_board_handle_name].ActiveState = CS.Oak.ActiveState.Enabled
				self:init_fountain(1)
			end
			fo.Interactable = CS.Oak.NonInteractable.Instance
		end

		-- 공터는 숨김
		fo.ActiveState = CS.Oak.ActiveState.InField
		state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(fo.Position)
	else
		-- 업그레이드
		-- 외형 교체
		state.pooled_object:Dispose()
		state.pooled_object = unity_object_pool.GetOrCreate(spec.asset_name):Instantiate(state.field_object.Position)
	end

	-- id 변경
	state.id = new_building_id

	-- 영빈관이면 분수 외형도 바꿔줌
	if handle_name == 'guest_house' then
		local fountain_id = self.fountain_base_id + spec.level - 1
		local fountain_spec = self.building_specs_data[fountain_id]
		local fountain_pos = state.fountain.field_object.Position
		state.fountain.pooled_object:Dispose()
		state.fountain.pooled_object = unity_object_pool.GetOrCreate(fountain_spec.asset_name):Instantiate(fountain_pos)
		state.fountain.id = fountain_id
	end
end

-- 건설 기믹 오브젝트 생성
function local_class:play_build_anim(target, handle_name)
	local offset = unity_class.vector3(0.5, 0, 1)

	local object_pool
	if handle_name == 'guest_house' then
		object_pool = unity_object_pool.GetOrCreate(self.build_anim_fx_6x4_name)
	else
		object_pool = unity_object_pool.GetOrCreate(self.build_anim_fx_4x4_name)
	end

	local position = target.Bounds.min + offset
	local upgrade_object = object_pool:Instantiate(position)
	local animator = upgrade_object:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('on')

	return upgrade_object, animator
end

--endregion

--region crafting

-- 해당 건물 id에서 제작 가능한 제작품 리스트
function local_class:get_craft_item_ids()
	local id_list = {}

	for id, _ in pairs(self.craft_item_specs_data) do
		table.insert(id_list, id)
	end
	table.sort(id_list)

	return id_list
end

-- 아이템 제작 ui 루틴
function local_class:pop_craft_item_ui_routine(target, id_list)
	local item_data = game_data_service.GetData('ItemData')

	for i = 0, user_party.Count - 1 do
		character_util.stop(user_party[i])
	end
	field_ui_manager:Hide()

	coroutine.yield(self:align_party(target))

	music_player:PlaySfxOneShot('01_craft_01')
	local craft_item_state = CS.Oak.UI.ShortStorySlimeCraftTablePopupState()

	-- 스펙 리스트 완성
	local craft_item_spec_list = create_generic_list(typeof(CS.Oak.UI.ShortStorySlimeCraftItemSpec))
	for _, craft_item_id in ipairs(id_list) do
		local craft_item_spec = self.craft_item_specs_data[craft_item_id]

		local name = craft_item_spec.name

		local cost_list = create_generic_list(typeof(CS.Oak.UI.ShortStorySlimeCraftCost))
		for _, data in ipairs(craft_item_spec.resource_cost) do
			if data.value > 0 then
				local item_spec = item_data:GetSpec(data.id)
				local cost_data = CS.Oak.UI.ShortStorySlimeCraftCost.MakeData(item_spec, data.value)
				cost_list:Add(cost_data)
			end
		end

		local spec_for_ui = CS.Oak.UI.ShortStorySlimeCraftItemSpec.MakeData(
				craft_item_id, name, craft_item_spec.sprite_name, craft_item_spec.max_num, cost_list,
				craft_item_spec.guest_house_level, craft_item_spec.sprite_scale, craft_item_spec.item_type,
				craft_item_spec.cost
		)

		craft_item_spec_list:Add(spec_for_ui)
	end

	-- 스테이트 데이터 저장
	-- TODO: ShowHelpPopup?
	craft_item_state.CraftItemDataList = craft_item_spec_list
	craft_item_state.ShowHelpPopup = false

	local crafted_item_id = -1
	local crafted_amount = -1
	craft_item_state.OnCraftItem = function(item_id, amount)
		if amount == nil then
			crafted_amount = 1
		end
		crafted_item_id = item_id
		self.main_controller:add_product_item_value(item_id)
	end

	-- 오버레이 띄움
	coroutine.yield(CS.Oak.UI.UISceneManager.Instance:PushOverlayRoutine(CS.Oak.UI.ShortStorySlimeCraftTablePopup.Instance,
			craft_item_state, typeof(CS.Oak.UI.ShortStorySlimeCraftTablePopup)))

	-- 오버레이 연출 다 끝날때 까지 대기
	local waitCoroutine = CS.Oak.UI.WaitUntilOverlayClosed(CS.Oak.UI.UISceneManager.Instance)
	coroutine.yield(waitCoroutine)

	self.main_controller:all_add_resource_tween_disable()

	field_ui_manager:Show()
	if crafted_item_id > 0 and crafted_amount >= 1 then
		coroutine.yield(self:craft_item_screenplay_routine(target))

		-- 재료 재화 감소
		self.main_controller:show_add_resource_right_status()

		-- 건물이 지어질 때 일정확률로 주민 퇴거
		self.main_controller:moved_out_villager()

		-- 재화 갱신
		self.main_controller.get_data_storage():all_save()
	end

	user_party:ResetControllers()
end

-- 아이템 제작 연출
function local_class:craft_item_screenplay_routine(_)
	local leader = user_party.Leader
	leader:HideWeapon(true)
	leader.Direction = CS.Oak.Direction.Left

	local craft_sfx = music_player_util.play_sfx({ sfx_name = '01_craft_02', loop = true })
	character_util.set_anim(leader, { name = "eat", loop = true })

	local time_passed = 0
	local duration = 1.0

	local ui_dict = field_ui_manager:SetUI(leader, CS.Oak.FieldUiType.TimerBar)
	local timer_bar = ui_dict[CS.Oak.FieldUiType.TimerBar]
	timer_bar.BarSprite:SetMinMax(0, 1.0)
	timer_bar.BarSprite:SetValue(0, 0)

	while time_passed < duration do
		time_passed = time_passed + unity_class.time.deltaTime
		local progress = time_passed / duration

		if progress >= 1 then
			break
		end

		timer_bar.BarSprite:SetValue(progress, 0)

		coroutine.yield(nil)
	end

	field_ui_manager:RemoveUI(leader, CS.Oak.FieldUiType.TimerBar)

	craft_sfx:Stop()
	music_player_util.play_sfx_one_shot('03_get_drop_item_01')
	leader:HideWeapon(false)
	character_util.remove_anim(leader)

	coroutine.yield(coroutine_class.wait_for_sec(0.25))
end

--endregion

--region guest_house

-- 영빈관 ui 루틴
function local_class:pop_guest_house_ui_routine(guest_house_handle_name, target)
	local state = self.build_spots_state[guest_house_handle_name]
	local id = state.id
	if id < 1 then
		return
	end

	for i = 0, user_party.Count - 1 do
		character_util.stop(user_party[i])
	end
	field_ui_manager:Hide()

	-- 파티 정위치
	coroutine.yield(self:align_party(target))

	music_player:PlaySfxOneShot(self.building_specs_data[id].open_sfx)

	-- ui 스테이트 채워 넣기
	local info_state = CS.Oak.UI.ShortStorySlimeBuildingInfoPopupState()
	local building_spec = self:make_building_spec_data(id)

	info_state.CurrentBuilding = building_spec

	local is_upgrade = false

	-- 각 콜백 루틴에서 컨트롤 리셋
	local reset_control = true
	info_state.OnUpgrade = function()
		is_upgrade = true
		reset_control = false

		local upgrade_id = self.building_specs_data[id].upgrade_id
		if upgrade_id < 0 then
			return
		end

		local guest_house_fo = self.build_spots_state[guest_house_handle_name].field_object
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.on_upgrade_routine, self, guest_house_fo, guest_house_handle_name, upgrade_id))
	end

	-- 오버레이 띄움
	coroutine.yield(CS.Oak.UI.UISceneManager.Instance:PushOverlayRoutine(CS.Oak.UI.ShortStorySlimeBuildingInfoPopup.Instance,
			info_state, typeof(CS.Oak.UI.ShortStorySlimeBuildingInfoPopup)))

	-- 오버레이 연출 다 끝날때 까지 대기
	local waitCoroutine = CS.Oak.UI.WaitUntilOverlayClosed(CS.Oak.UI.UISceneManager.Instance)
	coroutine.yield(waitCoroutine)

	self.main_controller:all_add_resource_tween_disable()

	-- status UI 갱신
	self.main_controller.get_data_storage():all_save()
	self.main_controller:update_status_ui()

	if reset_control then
		field_ui_manager:Show()
		user_party:ResetControllers()
	end
end

-- 업그레이드 루틴
function local_class:on_upgrade_routine(target_fo, handle_name, building_id)
	-- 기본 건설 연출 재생
	coroutine.yield(self:default_building_screenplay(target_fo, handle_name, building_id))

	-- 갱신
	-- 자원 소모 등 후처리
	local building_spec = self.building_specs_data[building_id]
	for _, resource_data in pairs(building_spec.resource_cost) do
		self.main_controller:update_resource_and_update_status(resource_data.id, -resource_data.value)
	end

	if handle_name == 'guest_house' then
		self.main_controller:upgrade_guest_house()
	end

	self.main_controller:update_status_ui()
	self.main_controller:show_add_resource_right_status()

	field_ui_manager:Show()
	user_party:ResetControllers()
end

--endregion

--region house

-- 주택 ui 루틴
function local_class:pop_residence_manage_ui_routine(target)
	for i = 0, user_party.Count - 1 do
		character_util.stop(user_party[i])
	end
	field_ui_manager:Hide()

	coroutine.yield(self:align_party(target))

	music_player:PlaySfxOneShot(self.building_specs_data[4].open_sfx)
	local is_move_in_out = false

	local spot_state = self.build_spots_state[target.Name]
	local state = CS.Oak.UI.ShortStorySlimeHousePopupState()
	state.SpotIndex = spot_state.index
	state.OnMoveInOut = function()
		is_move_in_out = true
	end

	-- 오버레이 띄움
	coroutine.yield(CS.Oak.UI.UISceneManager.Instance:PushOverlayRoutine(CS.Oak.UI.SlimeHousePopup.Instance, state,
			typeof(CS.Oak.UI.SlimeHousePopup)))

	-- 오버레이 연출 다 끝날때 까지 대기
	local waitCoroutine = CS.Oak.UI.WaitUntilOverlayClosed(CS.Oak.UI.UISceneManager.Instance)
	coroutine.yield(waitCoroutine)

	self.main_controller:all_add_resource_tween_disable()

	if is_move_in_out then
		self.move_in_out_count = self.move_in_out_count + 1

		-- 주민이 입주 퇴거가 이루어 졌다면 랜덤으로 주민 퇴거
		self.main_controller:moved_out_villager(false)

		-- 주민의 입주 퇴거가 이루어 졌으니 저장
		if self.move_in_out_count >= self.save_move_in_out_count then
			self.move_in_out_count = 0
			-- 강제 업데이트
			self.main_controller.get_data_storage():force_all_data_save()
		else
			self.main_controller.get_data_storage():all_save()
		end

		-- ui 업데이트
		self.main_controller:update_status_ui()
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

--endregion

function local_class:attach_target_bound_publish_interactable(fo)
	if CS.Oak.LuaBattleExtensions.TypeCompareSubClassOf(fo.Interactable, typeof(CS.Oak.TargetBoundPublishInteractable)) then
		return
	end

	local fo_size = fo.Bounds.size
	local offset = unity_class.vector3(0,0,-fo.Bounds.extents.z)
	local target_bound = CS.UnityEngine.Bounds(offset,
			unity_class.vector3(math.max(0.5, fo_size.x - 2), fo_size.y, 1)
	)
	fo.Interactable = CS.Oak.TargetBoundPublishInteractable()
	fo.Interactable:SetTargetBound(target_bound)
end

function local_class:dispose()
	-- TODO:
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_event')
	--message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')

	self.building_specs_data = nil
	self.build_spots_data = nil

	self.destroyed_obstacles = nil
	self.build_spots_state = nil
	self.handle_name_objects = nil
end

return {
	create = function()
		return local_class()
	end
}
