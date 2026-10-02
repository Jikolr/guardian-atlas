local local_class = newclass('HeavenholdFarmController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.tutorial_state = {
		-- 오두막에 상호작용
		interact_hut = 1,
		-- 재료 획득
		get_farm_resource = 2,
		-- 오두막을 짓도록
		create_hut = 3,
		-- 제작대에 상호작용
		interact_craft_table = 4,
		-- 튜토리얼 클리어
		complete_tutorial = 5,
	}
	self.cur_tutorial_state = self.tutorial_state.complete_tutorial

	-- 오두막 1레벨 스팩
	self.hut_spec = nil

	-- 오두막 비헤이비어 이름
	self.hut_handle_name = 'farm_hut'

	-- 제작대 비헤이비어 이름
	self.craft_table_handle_name = 'farm_craft_table'

	-- 낚시터 핸들네임 리스트
	self.fishing_handle_name_list = {}
	table.insert(self.fishing_handle_name_list, 'fishing_spot_1')
	table.insert(self.fishing_handle_name_list, 'fishing_spot_2')
	table.insert(self.fishing_handle_name_list, 'fishing_spot_3')

	-- 고양이 핸들네임
	self.cat_handle_name = 'npc_cat'

	--- 남의 농장이면 인터렉트를 막을 fo 목록
	self.non_interact_fo_other_farm = {}
	table.insert(self.non_interact_fo_other_farm, self.hut_handle_name)
	table.insert(self.non_interact_fo_other_farm, self.craft_table_handle_name)

	-- 남의 농장이면 꺼버릴 fo 목록
	self.disable_fo_other_farm = {}
	for _, handle_name in ipairs(self.fishing_handle_name_list) do
		table.insert(self.disable_fo_other_farm, handle_name)
	end

	--- 남의 농장이면 인터렉트를 막을 character 목록
	self.non_interact_character_other_farm = {}
	table.insert(self.non_interact_character_other_farm, self.cat_handle_name)

	-- 튜토리얼 키
	self.tutorial_key = 'farm_tutorial'

	-- 채집물 마커 리스트
	self.obstacle_marker_list = nil

	-- 장애물(채집오브젝트) 매니져
	self.obstacle_manager = nil

	-- 낚시 매니저
	self.fishing_manager = CS.Oak.HeavenHoldFarmSystem.Instance.FishingManager

	-- 낚시 튜토리얼 진행중인지 체크용
	self.fishing_tutorial_state = {
		begin = 1,
		playing = 2,
		play_end = 3,
	}
	self.cur_fishing_tutorial_state = self.fishing_tutorial_state.play_end

	-- 상점이 열려있는지
	self.is_shop_open = false

	local stage_spec = CS.Oak.Stage.Instance.Spec
	local tilemap = stage_spec.Tilemap
	if tilemap == 'heavenhold_farm_1_new_xmas' then
		self.fx_snow_pool = unity_object_pool.GetOrCreate('fx_farm_snow_camera_fx')
	end
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.ChangeFarmBuildingStateEvent), 'on_building_change_event')
end

function local_class:on_stage_start_event(e)
	local is_local = farm_util.is_in_local_farm()

	-- HACK : 임시 포탈 정지 처리
	self:hack_portal_block()

	-- 스테이지 시작 시 기본적인 부분 세팅
	self:setup_default(is_local)

	-- 이 농장이 튜토리얼이 끝난 상태라면 생략
	if farm_util.is_farm_tutorial_finished() then return end

	-- 튜토리얼 진행 가능할 때 처리할 예외 사항 세팅
	self:setup_when_tutorial_available()

	-- 본인 농장이 아니라면 생략
	if not is_local then return end

	-- 튜토리얼 플레이가 가능하도록 세팅
	self:setup_tutorial()
end

function local_class:setup_default(is_local)
	-- 마커가 없으면 생략한다.
	if field_util.has_marker('fishing_sound_spot') then
		-- 낚시터 사운드 세팅
		local fishing_sound_spot = field_util.get_marker_pos('fishing_sound_spot')
		farm_util.play_ambient_sound(self.cs_controller, "hhf_fishing_spot_loop", fishing_sound_spot)
	end

	--- 자신의 농장이라면 이하 생략
	if is_local then return end

	for _, handle_name in ipairs(self.non_interact_fo_other_farm) do
		local fo = get_field_object(handle_name)
		if fo ~= nil then
			fo.Interactable = CS.Oak.NonInteractable.Instance
		end
	end

	for _, handle_name in ipairs(self.disable_fo_other_farm) do
		local fo = get_field_object(handle_name)
		if fo ~= nil then
			fo.ActiveState = active_state('disabled')
		end
	end

	for _, handle_name in ipairs(self.non_interact_character_other_farm) do
		local character = get_character(handle_name)
		if character ~= nil then
			character.Interactable = CS.Oak.NonInteractable.Instance
		end
	end
end

function local_class:setup_when_tutorial_available()
	-- 튜토리얼이 완료되지 않은 경우 낚시 상인이 보이지 않도록 999 위치에 배치
	local cat_fo = get_character(self.cat_handle_name)
	-- npc가 해당 타일맵에 배치된 상태가 아니라면 생략함.
	if cat_fo ~= nil then
		cat_fo.Position = vector(999, 0, 999)
	end
end

function local_class:setup_tutorial()
	self.cur_tutorial_state = self.tutorial_state.interact_hut

	-- 오두막 / 제작대 PublishInteractable로 변경
	local hut = get_field_object(self.hut_handle_name)
	hut.Interactable = CS.Oak.PublishInteractable.Create()

	local craft_table = get_field_object(self.craft_table_handle_name)
	craft_table.Interactable = CS.Oak.PublishInteractable.Create()

	self.hut_spec = CS.Oak.HeavenHoldFarmData.Value:GetBuildingSpec(10001)

	self.obstacle_manager = CS.Oak.HeavenHoldFarmSystem.Instance.ObstacleManager

	-- 필요한 이벤트 구독
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_item_get_event')

	-- 퀘스트 마커 세팅
	ui_quest_marker:AddQuestMarkerToPoint(self.tutorial_key, -1, false, hut.Bounds.center)
end

--region Event

function local_class:on_event(e)
	return false
end

function local_class:on_interact_event(e)
	if CS.Oak.UI.UISceneManager.Instance.CurrentOverlay ~= nil or CS.Oak.UI.Chatting.Instance.IsInChatMode then
		return
	end

	-- 낚시, 일단 농장 튜토리얼 무시
	local target_name = e.Target.Name

	-- 낚시터인지 확인
	local is_fishing_spot = false
	for _, handle_name in ipairs(self.fishing_handle_name_list) do
		if target_name == handle_name then
			is_fishing_spot = true
			break
		end
	end

	if is_fishing_spot == true then
		-- 튜토리얼 진행중에는 넘기도록 한다.
		if self.cur_fishing_tutorial_state == self.fishing_tutorial_state.playing then
			return true
		end

		self.interactor = e.Interactor
		-- 낚시
		local rodSpec = self.fishing_manager:GetCurrentRodSpec()
		-- 낚싯대 없으면 경고 메시지
		if rodSpec == nil then
			farm_util.play_screenplay(self.narration_no_rod, self)
		else
			self.fishing_manager:StartFishing(CS.Oak.HeavenHoldFarmFishingManager.FishingType.Normal, e.Target.Transform.localPosition)
		end
		return true

	elseif target_name == self.cat_handle_name and self.is_shop_open == false then
		self.is_shop_open = true
		self.interactor = e.Interactor

		-- 튜토리얼 진행중에는 넘기도록 한다.
		if self.cur_fishing_tutorial_state == self.fishing_tutorial_state.begin then
			self.is_shop_open = false
			return true
		end

		farm_util.start_screenplay()

		local popup_state = CS.Oak.UI.HeavenHoldFarmShopState()
		local on_closed = function ()
			farm_util.end_screenplay()
			self.is_shop_open = false
		end

		popup_state.OnClosed = on_closed
		popup_state.Location = CS.Oak.ShopCategoryLocation.Fish

		ui_scene_manager:PushOverlay(CS.Oak.UI.HeavenHoldFarmShop.Instance, popup_state, typeof(CS.Oak.UI.HeavenHoldFarmShop))
		music_player_util.play_sfx_one_shot('01_interact_fishery_01')
		return true
	end

	if self.cur_tutorial_state == self.tutorial_state.none then
		return false
	end

	local hut = get_field_object(self.hut_handle_name)
	if lua_helper.reference_equals(e.Target, hut) then
		hut.FieldObjectBehaviour:InteractHut(function(isBuildStart)
			-- 건물 짓기를 시작했다면 튜토리얼 클리어, 아니라면 마커 갱신
			if isBuildStart then
				self:clear_tutorial()
			else
				self:check_marker_move()
			end
		end)

		return true
	end

	local craft_table = get_field_object(self.craft_table_handle_name)
	if lua_helper.reference_equals(e.Target, craft_table) then
		farm_util.play_screenplay(self.interact_craft_table, self)
		return true
	end

	return false
end

-- 낚싯대를 가지고 있지 않습니다 나레이션
function local_class:narration_no_rod()
	field_ui_util.show_narration_async({ key = 'farm_obstacle_lake_desc' })
	field_ui_util.show_narration_async({ key = 'farm_fishing_no_rod2' })
end

-- 미끼를 가지고 있지 않습니다 나레이션 (사용되지 않고있다)
function local_class:narration_no_bait()
	field_ui_util.show_narration_async({ key = 'farm_fishing_no_bait' })
end

function local_class:on_field_object_destroyed_event(e)
	if self.cur_tutorial_state ~= self.tutorial_state.get_farm_resource
			or self.obstacle_marker_list == nil then
		return false
	end

	-- 퀘스트 마커가 부여된 채집 오브젝트를 부쉈으면 퀘스트 마커를 제거
	for i = #self.obstacle_marker_list, 1, -1 do
		local obstacle = get_field_object(self.obstacle_marker_list[i])
		if obstacle ~= nil and lua_helper.reference_equals(e.FieldObject, obstacle) then
			ui_quest_marker:RemoveQuestMarker(self.obstacle_marker_list[i])
			table.remove(self.obstacle_marker_list, i)
		end
	end

	return false
end

function local_class:on_item_get_event(e)
	if e.Item.ItemId == CS.Oak.ItemSpecId.Tree and e.Item.ItemId == CS.Oak.ItemSpecId.Stone then
		return false
	end

	local is_enough_tree = self:is_enough_obstacle(CS.Oak.FarmObstacleType.Tree, 0)
	local is_enough_stone = self:is_enough_obstacle(CS.Oak.FarmObstacleType.Stone, 1)

	-- 나무와 돌 재화를 다 모았다면 다음 단계로 넘어감
	if is_enough_tree and is_enough_stone then
		self:remove_obstacle_marker()
		self.cur_tutorial_state = self.tutorial_state.create_hut

		local hut = get_field_object(self.hut_handle_name)
		ui_quest_marker:AddQuestMarkerToPoint(self.tutorial_key, -1, false, hut.Bounds.center)

		return true
	end

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'fishing_tutorial_begin' then
		self.cur_fishing_tutorial_state = self.fishing_tutorial_state.begin
		return true
	elseif e:GetParamAt(0) == 'fishing_tutorial_playing' then
		self.cur_fishing_tutorial_state = self.fishing_tutorial_state.playing
		return true
	elseif e:GetParamAt(0) == 'fishing_tutorial_end' then
		self.cur_fishing_tutorial_state = self.fishing_tutorial_state.play_end
		return true
	elseif e:GetParamAt(0) == 'aquarium_enter' then
		if self.fx_snow then
			self.fx_snow:Dispose()
		end
		self.fx_snow = nil
	elseif e:GetParamAt(0) == 'aquarium_leave' then
		if self.fx_snow_pool then
			self.fx_snow = self.fx_snow_pool:Instantiate(stage_camera.LookAtPosition, unity_class.quaternion.identity,	stage_camera.transform)
		end
	end

	return false
end

function local_class:on_stage_loaded_event(e)
	if self.fx_snow_pool then
		self.fx_snow = self.fx_snow_pool:Instantiate(stage_camera.LookAtPosition, unity_class.quaternion.identity,	stage_camera.transform)
	end
end

function local_class:on_building_change_event(e)
	-- HACK : 임시 포탈 정지 처리
	self:hack_portal_block()
end

function local_class:hack_portal_block()
	if farm_util.get_current_user_data().Buildings == nil then return end

	local building_data = nil

	for _, data in pairs(farm_util.get_current_user_data().Buildings) do
		if data.SpecId == 10501 then
			building_data = data
			break
		end
	end

	-- 데이터를 못찾으면 아직 포탈이 없는 것
	if not building_data then return end
	-- field_object를 가져오길 시도한다.
	local building_instance = farm_util.get_farm_system().BuildingManager:GetBuildingById(building_data.Id)
	-- 만약 field_object가 없으면 설정할게 없다
	if building_instance then building_instance.Interactable = CS.Oak.NonInteractable.Instance end
end

--endregion

-- 마커를 채집물 or 오두막에 그대로 둘지 체크
function local_class:check_marker_move()
	if self.cur_tutorial_state >= self.tutorial_state.create_hut then
		return
	end

	local is_enough_tree = self:is_enough_obstacle(CS.Oak.FarmObstacleType.Tree, 0)
	local is_enough_stone = self:is_enough_obstacle(CS.Oak.FarmObstacleType.Stone, 1)

	if is_enough_tree and is_enough_stone then
		-- 둘다 오두막을 짓기에 충분하다면 create_hut 상태로 진입
		self.cur_tutorial_state = self.tutorial_state.create_hut
	else
		-- 둘중에 하나라도 오두막짓는 비용보다 적으면 오두막의 마커를 지우고 부족한 채집 재료쪽은 마커 표시
		ui_quest_marker:RemoveQuestMarker(self.tutorial_key)

		self.obstacle_marker_list = {}

		-- 제일 가까운 넘버링의  죽지 않은 나무에 마커
		if is_enough_tree == false then
			self:set_obstacle_marker(0, 10)
		end

		-- 제일 가까운 넘버링의 죽지 않은 돌에 마커
		if is_enough_stone == false then
			self:set_obstacle_marker(11, 20)
		end

		-- 채집 오브젝트 얻는 상태로 변경
		self.cur_tutorial_state = self.tutorial_state.get_farm_resource
	end
end

function local_class:is_enough_obstacle(farm_obstacle_type, index)
	return self.obstacle_manager:GetCurFarmResource(farm_obstacle_type) >= self.hut_spec.ResourceCost[index].Amount
end

function local_class:set_obstacle_marker(start_index, end_index)
	for i = start_index, end_index do
		local handle_name = 'obstacle_' .. i
		local obstacle = get_field_object(handle_name)
		if obstacle.FieldObjectBehaviour.IsActive then
			ui_quest_marker:AddQuestMarkerToPoint(handle_name, -1, false, obstacle.Bounds.center)
			table.insert(self.obstacle_marker_list, handle_name)
			break
		end
	end
end

-- 튜토리얼 클리어
function local_class:clear_tutorial()
	-- 작업대 상호작용 처리 제대로 되도록 수정
	local craft_table = get_field_object(self.craft_table_handle_name)
	craft_table.Interactable = CS.Oak.Interactable()

	-- 마커 remove
	self:remove_obstacle_marker()
	ui_quest_marker:RemoveQuestMarker(self.tutorial_key)

	-- 구독해지
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))

	-- 건물 정보 변경 갱신
	message_system:Publish(CS.Oak.ChangeFarmBuildingStateEvent.Instance)

	-- 튜토리얼 퀘스트 클리어
	self.cur_tutorial_state = self.tutorial_state.complete_tutorial
end

-- 제작대에 상호작용했을 때
function local_class:interact_craft_table()
	field_ui_util.show_narration_async({ key = 'farm_craft_tutorial_notice' })
end

function local_class:remove_obstacle_marker()
	if self.obstacle_marker_list == nil then
		return
	end

	for i = 1, #self.obstacle_marker_list do
		ui_quest_marker:RemoveQuestMarker(self.obstacle_marker_list[i])
	end

	self.obstacle_marker_list = nil
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ChangeFarmBuildingStateEvent))

	-- 튜토리얼 퀘스트를 클리어 한 상태가 아니라면 구독해지
	if self.cur_tutorial_state ~= self.tutorial_state.complete_tutorial then
		message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent))
	end

	self:remove_obstacle_marker()

	self.obstacle_manager = nil

	self.hut_spec = nil

	self.cs_controller = nil

	if self.fx_snow_pool then
		self.fx_snow_pool:Dispose()
	end
	self.fx_snow_pool = nil

	if self.fx_snow then
		self.fx_snow:Dispose()
	end
	self.fx_snow = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
