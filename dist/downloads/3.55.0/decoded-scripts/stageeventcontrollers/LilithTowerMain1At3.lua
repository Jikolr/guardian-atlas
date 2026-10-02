local local_class = newclass("LilithTowerMain1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name = 'lilithtower_1_3'

	-- 윈도우 브레이커 이벤트 key
	self.windows_breaker_key = 'windows_breaker'

	-- 기사 리턴
	self.get_knight = function()
		if user_util.has_knight_male() then
			return get_character('knight_male')
		else
			return get_character('knight_female')
		end
	end

	-- 수트 맨손 기사
	self.get_knight_suit = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit')
		else
			return get_character('knight_female_suit')
		end
	end

	-- 수트 배트 기사
	self.get_knight_suit_bat = function()
		if user_util.has_knight_male() then
			return get_character('knight_male_suit_bat')
		else
			return get_character('knight_female_suit_bat')
		end
	end

	-- 베스
	self.get_beth = function() return get_character('beth_the_janitor') end

	-- 윈도우 브레이커 이벤트 key
	self.windows_breaker_key = 'windows_breaker'

	-- 환풍구 미니게임
	self.vent_mini_game = nil
	self.game_name = 'VentMiniGame'

	-- 파티원들
	self.saved_party = nil

	-- ExclusiveQuestStartEvent 받았으면 TRUE
	self.is_exclusive_quest = false

	-- 기계실 구멍 이벤트
	self.machinery_hole = nil
	self.machinery_hole_name = 'machinery_hole'
	self.exit_machinery_hole_name = 'exit_machinery_hole'

	-- 아래층 테러리스트들 구현
	self.under_floor_terrorist_list = nil
	self.under_floor_terrorist_name = 'under_floor_terrorist_'
	self.under_floor_terrorist_num = 16

	self.is_control_under_floor_terrorist = false

	-- 샹들리에
	self.first_chandelier = nil
	self.second_chandelier = nil
	self.third_chandelier = nil

	self.first_chandelier_name = 'first_floor_chandelier'
	self.second_chandelier_name = 'second_floor_chandelier'
	self.third_chandelier_name = 'third_floor_chandelier'

	self.broken_chandelier_name = 'broken_chandelier'

	-- 리소스 로드
	self.res_holder = nil
	self.under_floor_obj = nil
	self.grab_blur = nil

	-- 2층 크기와 위치
	self.second_floor_pos = vector(25.87, -4, 90)
	self.second_floor_scale = vector(0.82, 1, 0.82)

	self.second_floor_up_left = vector(24.2, -1, 126.3)
	self.second_floor_length = 0.82

	-- 3층 크기와 위치
	self.third_floor_pos = vector(17.87, -5, 165)
	self.third_floor_scale = vector(0.74, 1, 0.74)

	self.third_floor_up_left = vector(16.4, -1, 196.8)
	self.third_floor_length = 0.72

	-- 존 이름
	self.second_floor_zone_name = 'second_floor_outer'
	self.third_floor_zone_name = 'third_floor'
	self.beth_usage_zone_name = 'beth_usage'

	-- 카메라 그리드 이름
	self.second_floor_grid_name = '9'
	self.third_floor_grid_name = '3'
	self.beth_chest_grid_name = '4'

	-- 오브젝트 풀
	self.blur_obj_preset = 'grab_blur_object'
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.custom_sprite_preset = 'custom_sprite'
	self.hit_projectile_preset = "fx_virus_bullet_proj_groundhit"

	-- HP회복 로직이 도는 중인가
	self.is_recovery_hp = false
	-- 테러리스트 Exclusive 이벤트 키
	self.detected_by_terrorist_key = 'detected_by_terrorist'

	-- 베스 사용처 이벤트 관련 상태
	self.beth_mini_event_state = {
		chest_closed = 1,
		called_beth = 2,
		chest_opened = 3
	}
	self.is_playing_cease_event = false
	self.beth_usage_event_state = self.beth_mini_event_state.chest_closed

	self.pooled_bullets = {}
	self.custom_atlas = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent), 'on_exclusive_quest_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent), 'on_exclusive_quest_end_event')

	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_battle_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleEndEvent), 'on_battle_end_event')

	self.machinery_hole = get_field_object(self.machinery_hole_name)

	self.under_floor_terrorist_list = create_generic_list(CS.Oak.Character)
	for i = 1, self.under_floor_terrorist_num do
		local cur_terrorist = get_character(self.under_floor_terrorist_name..i)

		self.under_floor_terrorist_list:Add(cur_terrorist)
	end

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate(self.blur_obj_preset)

	-- 리소스 로드를 기다림
	yield_return(unity_object_pool, 'WaitAll')

	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if quest_progress.InnerProgress < 10 then
		-- 샹들리에 위치 설정
		self.first_chandelier = get_field_object(self.first_chandelier_name)
		self.first_chandelier.Position = vector(-0.5, 10.5, 27)

		local first_chandelier_shadow_transform = self.first_chandelier.Transform:GetChild(0):GetChild(1)
		first_chandelier_shadow_transform.localPosition = vector(0, -10, -3)

		self.second_chandelier = get_field_object(self.second_chandelier_name)
		self.second_chandelier.Position = vector(25.5, 9, 124)

		local second_chandelier_shadow_transform = self.second_chandelier.Transform:GetChild(0):GetChild(1)
		second_chandelier_shadow_transform.localPosition = vector(0, -12, 0)
		second_chandelier_shadow_transform.localScale = vector(3.5, 1, 3.5)

		self.third_chandelier = get_field_object(self.third_chandelier_name)
		self.third_chandelier.Position = vector(17.5, 8, 194)
		self.third_chandelier.Hitbox = CS.Oak.Hitbox(vector(0.5, 4, 0.15), vector(3.5, 2, 4))

		local third_chandelier_shadow_transform = self.third_chandelier.Transform:GetChild(0):GetChild(1)
		third_chandelier_shadow_transform.localPosition = vector(0, -10.2, 0)
		third_chandelier_shadow_transform.localScale = vector(3, 1, 3)
	else
		-- 샹들리에 비활성화
		stage_util.set_fo_active_state(self.first_chandelier_name, 'disabled')
		stage_util.set_fo_active_state(self.second_chandelier_name, 'disabled')
		stage_util.set_fo_active_state(self.third_chandelier_name, 'disabled')
	end

	stage_util.set_fo_active_state(self.broken_chandelier_name, 'disabled')

	-- 전경 로드
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/v2_22_lilithtower/tilesets/lilithtower', 'lilithtower_1_3_main_hall',
			function(prefab)
				self.under_floor_obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.under_floor_obj.transform.localPosition = self.second_floor_pos
				self.under_floor_obj.transform.localScale = self.second_floor_scale

				local grab_blur_obj = unity_object_pool.GetOrCreate(self.blur_obj_preset):Instantiate(
						self.under_floor_obj.transform.localPosition + vector(0, 3, 0))
				self.grab_blur = grab_blur_obj.transform:GetComponent(typeof(CS.Oak.GrabBlur))
			end)

	-- 원경 NPC 설정
	if quest_progress.InnerProgress < 10 then
		local mats = {}
		for i = 0, self.under_floor_terrorist_list.Count - 1 do
			field_ui_manager:RemoveUI(self.under_floor_terrorist_list[i], CS.Oak.FieldUiType.CharacterStats)

			local under_floor_terrorist = self.under_floor_terrorist_list[i]
			local mat = nil
			for j = 0, under_floor_terrorist.SpineController.SkeletonAnimation.SkeletonDataAsset.atlasAssets.Length - 1 do
				local aab = under_floor_terrorist.SpineController.SkeletonAnimation.SkeletonDataAsset.atlasAssets[j]
				if aab ~= nil then
					mat = aab.PrimaryMaterial
					break
				end
			end

			local new_mat
			if mat ~= nil then
				if not table_util.contain_key(mats, mat) then
					new_mat = CS.UnityEngine.Material(mat)
					new_mat.renderQueue = 2450
					mats[mat] = new_mat
				else
					new_mat = mats[mat]
				end

				under_floor_terrorist.SpineController.MaterialOverride = new_mat
			end

			if i < 4 then
				character_util.set_position(self.under_floor_terrorist_list[i],
						self.second_floor_up_left + vector(self.second_floor_length * i, 0, 0))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'down')
			elseif i < 6 then
				local index = i - 4

				character_util.set_position(self.under_floor_terrorist_list[i],
						self.second_floor_up_left + vector(
								0, 0, self.second_floor_length * - (4 + 2 * index)))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'right')
			elseif i < 8 then
				local index = i - 6

				character_util.set_position(self.under_floor_terrorist_list[i],
						self.second_floor_up_left + vector(
								self.second_floor_length * 3, 0, self.second_floor_length * - (4 + 2 * index)))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'left')
			elseif i < 12 then
				local index = i - 8

				character_util.set_position(self.under_floor_terrorist_list[i],
						self.third_floor_up_left + vector(self.third_floor_length * index, 0, 0))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'down')
			elseif i < 14 then
				local index = i - 12

				character_util.set_position(self.under_floor_terrorist_list[i],
						self.third_floor_up_left + vector(
								0, 0, self.third_floor_length * - (4.5 + 2 * index)))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'right')
			elseif i < 16 then
				local index = i - 14

				character_util.set_position(self.under_floor_terrorist_list[i],
						self.third_floor_up_left + vector(
								self.third_floor_length * 3, 0, self.third_floor_length * - (4.5 + 2 * index)))
				character_util.set_direction(self.under_floor_terrorist_list[i], 'left')
			end

			character_util.set_anim(self.under_floor_terrorist_list[i], { name = 'rifle_idle' })

			if i < 8 then
				character_util.set_scale_factor(
						self.under_floor_terrorist_list[i], self.under_floor_terrorist_list[i].Name, 0.7)
			else
				character_util.set_scale_factor(
						self.under_floor_terrorist_list[i], self.under_floor_terrorist_list[i].Name, 0.5)
			end
		end
	end

	-- 미니게임 로드
	self.vent_mini_game = mini_game_manager:GetOrCreate(self.game_name)

	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.game_name, 'vent_mini_game_stage_3', function()
		is_mini_game_load_complete = true
	end)

	while not is_mini_game_load_complete do
		coroutine.yield()
	end

	-- 베스 사용 이벤트용 총알 리소스 로드
	self:load_terrorist_bullet()

	-- 파워 테슬라 코일 크기를 2x2로 크게 함
	-- TODO: 이렇게 사용하는 경우가 한 번 더 발생할 경우 2x2 크기를 타일셋에 추가하는 것으로 박종수님과 구두로 얘기되었습니다.
	local machinery_main_light = get_field_object('machinery_main_light')
	machinery_main_light.Position = machinery_main_light.Position + vector(-0.1, 0, 0)
	machinery_main_light.transform.localScale = 2 * unity_class.vector3.one
	machinery_main_light.Hitbox = CS.Oak.Hitbox(vector(2, 1, 2))
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		7
	}

	-- 리더를 기사로 바꿈
	-- 방망이를 얻었다면 방망이를 든 기사로
	local character_spec_id = 302922
	if user_util.has_knight_male() then
		character_spec_id = 302921
	end

	local leader
	if quest_util.get_custom_state(quest_progress, self.windows_breaker_key) >= 1 then
		leader = self.get_knight_suit_bat()
	else
		leader = self.get_knight_suit()
	end

	character_util.convert_to_manual_character(leader)
	user_party.Leader.CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(user_party_leader.CharacterInfo.User, character_spec_id)

	field_ui_manager:SetUI(leader, CS.Oak.FieldUiType.TopHpBar)

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
end

function local_class:on_stage_start_event(e)
	if not self.is_get_key then
		-- 키 비활성화
		stage_util.set_fo_active_state(self.machinery_key_name, 'disabled')
	end

	-- 베스 상자가 열렸는지 확인
	local chest = get_field_object('beth_chest')
	self.beth_usage_event_state = lua_helper.get_conditional_value(chest.FieldObjectBehaviour.IsOpened,
			self.beth_mini_event_state.chest_opened, self.beth_mini_event_state.chest_closed)

	-- 베스 사용처 관련 NPC들 세팅
	if self.beth_usage_event_state == self.beth_mini_event_state.chest_closed then
		self:init_beth_help_npcs()
	end
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if e.Zone.Name == self.second_floor_zone_name then
			self.under_floor_obj.transform.localPosition = self.second_floor_pos
			self.under_floor_obj.transform.localScale = self.second_floor_scale

			self.grab_blur.transform.localPosition = self.under_floor_obj.transform.localPosition + vector(0, 3, 0)
			self.grab_blur.BlurRadius = 3
		elseif e.Zone.Name == self.third_floor_zone_name then
			self.under_floor_obj.transform.localPosition = self.third_floor_pos
			self.under_floor_obj.transform.localScale = self.third_floor_scale

			self.grab_blur.transform.localPosition = self.under_floor_obj.transform.localPosition + vector(0, 3, 0)
			self.grab_blur.BlurRadius = 4

		elseif e.Zone.Name == self.beth_usage_zone_name then
			if self.beth_usage_event_state > self.beth_mini_event_state.chest_closed then return end

			local beth_quest_id = 264
			local quest = user_progress:GetStartedQuest(beth_quest_id)

			if quest ~= nil and quest.IsComplete and quest.Grade == 0 then
				sp_util.play_normal_screenplay(self.open_calling_beth_narration, self)
			else
				sp_util.play_normal_screenplay(self.player_dead_event, self)
			end
		end
	end
end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if e.CameraGrid.name == self.second_floor_grid_name then
			if not self.is_control_under_floor_terrorist then
				self.is_control_under_floor_terrorist = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.move_floor_character, self, 2))
			end
		elseif e.CameraGrid.name == self.third_floor_grid_name then
			if not self.is_control_under_floor_terrorist then
				self.is_control_under_floor_terrorist = true

				coroutine_manager:StartCoroutine(
						stage.StageGameObject, util.cs_generator(self.move_floor_character, self, 3))
			end
		elseif e.CameraGrid.name == self.beth_chest_grid_name then
			-- 베스 사용처 미니 이벤트: 보물상자 찾아서 좋아하는 테러리스트 NPC 부분
			if self.beth_usage_event_state ~= self.beth_mini_event_state.chest_closed then return end
			if self.is_playing_cease_event then return end

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.start_terrorist_cease_event, self))
			-- 베스 사용처 미니 이벤트: 베스 부르는 이벤트
		end
	end
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_party_leader()) then
		if e.CameraGrid.name == self.second_floor_grid_name then
			if self.is_control_under_floor_terrorist then
				self.is_control_under_floor_terrorist = false
			end
		elseif e.CameraGrid.name == self.third_floor_grid_name then
			if self.is_control_under_floor_terrorist then
				self.is_control_under_floor_terrorist = false
			end
		elseif e.CameraGrid.name == self.beth_chest_grid_name then
			self.is_playing_cease_event = false
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.machinery_hole) then
		sp_util.play_normal_screenplay(self.interact_with_hole_event, self)
	end
end

function local_class:on_exclusive_quest_start_event(e)
	if not self.is_exclusive_quest then
		self.is_exclusive_quest = true
	end

	if e.Key == self.detected_by_terrorist_key then
		self.is_recovery_hp = false
	end
end

function local_class:on_exclusive_quest_end_event(e)
	if self.is_exclusive_quest then
		self.is_exclusive_quest = false
	end

	if not self.is_recovery_hp and e.Key == self.detected_by_terrorist_key then
		self.is_recovery_hp = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.recovery_hp, self))
	end
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ExclusiveQuestEndEvent))

	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleEndEvent))

	if self.pooled_bullets ~= nil then
		for i = 1, #self.pooled_bullets do
			self.pooled_bullets[i]:Dispose()
		end
		self.pooled_bullets = nil

	end

	self.vent_mini_game = nil

	self.saved_party = nil

	if self.under_floor_obj ~= nil then
		CS.UnityEngine.Object.Destroy(self.under_floor_obj)
		self.under_floor_obj = nil
	end

	self.under_floor_terrorist_list = nil

	self.machinery_hole = nil
	self.first_chandelier = nil
	self.second_chandelier = nil
	self.third_chandelier = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end

	self.custom_atlas = nil

	self.grab_blur = nil

	self.cs_controller = nil
end

-- 원경 캐릭터 이동 루틴
function local_class:move_floor_character(floor)
	local cur_length

	if floor == 2 then
		cur_length = self.second_floor_length
	elseif floor == 3 then
		cur_length = self.third_floor_length
	end

	local change_dir_duration = 0.7

	local move_character_list = create_generic_list(CS.Oak.Character)
	local origin_pos_list = create_generic_list(unity_class.vector3)

	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	if floor == 2 then
		for i = 4, 7 do
			move_character_list:Add(self.under_floor_terrorist_list[i])
			origin_pos_list:Add(self.under_floor_terrorist_list[i].Position)
		end
	elseif floor == 3 then
		for i = 12, 15 do
			move_character_list:Add(self.under_floor_terrorist_list[i])
			origin_pos_list:Add(self.under_floor_terrorist_list[i].Position)
		end
	end

	while self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10 do
		for i = 0, move_character_list.Count - 1 do
			local waypoint_list = create_generic_list(unity_class.vector3)

			if i % 4 < 2 then
				waypoint_list:Add(move_character_list[i].Position + vector(-3 * cur_length, 0, 0))
			else
				waypoint_list:Add(move_character_list[i].Position + vector(3 * cur_length, 0, 0))
			end

			character_util.set_anim(move_character_list[i], { name = 'rifle_walk' })
			character_util.move_waypoint(move_character_list[i], waypoint_list,
					1.5 * cur_length, false, 'stop', 'free', 'left')
		end

		local timer = 0
		local duration = 2

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)

		for i = 0, move_character_list.Count - 1 do
			character_util.set_direction(move_character_list[i],
					CS.Oak.DirectionExtensions.GetCWTurn(move_character_list[i].Direction, 1))
			character_util.set_anim(move_character_list[i], { name = 'rifle_idle' })
		end

		timer = 0
		duration = change_dir_duration

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)

		for i = 0, move_character_list.Count - 1 do
			character_util.set_direction(move_character_list[i],
					CS.Oak.DirectionExtensions.GetCWTurn(move_character_list[i].Direction, 2))
		end

		timer = 0
		duration = change_dir_duration

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)

		for i = 0, move_character_list.Count - 1 do
			local waypoint_list = create_generic_list(unity_class.vector3)

			if i % 4 < 2 then
				waypoint_list:Add(move_character_list[i].Position + vector(3 * cur_length, 0, 0))
			else
				waypoint_list:Add(move_character_list[i].Position + vector(-3 * cur_length, 0, 0))
			end

			character_util.set_anim(move_character_list[i], { name = 'rifle_walk' })
			character_util.move_waypoint(move_character_list[i], waypoint_list,
					1.5 * cur_length, false, 'stop', 'free', 'left')
		end

		timer = 0
		duration = 2

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)

		for i = 0, move_character_list.Count - 1 do
			character_util.set_direction(move_character_list[i],
					CS.Oak.DirectionExtensions.GetCWTurn(move_character_list[i].Direction, 1))
			character_util.set_anim(move_character_list[i], { name = 'rifle_idle' })
		end

		timer = 0
		duration = change_dir_duration

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)

		for i = 0, move_character_list.Count - 1 do
			character_util.set_direction(move_character_list[i],
					CS.Oak.DirectionExtensions.GetCWTurn(move_character_list[i].Direction, 2))
		end

		timer = 0
		duration = change_dir_duration

		while (self.is_control_under_floor_terrorist and quest_progress.InnerProgress < 10) and timer < duration do
			timer = timer + unity_class.time.deltaTime

			coroutine.yield(nil)
		end

		if timer < duration then
			break
		end

		coroutine.yield(nil)
	end

	if not self.is_control_under_floor_terrorist then
		for i = 0, move_character_list.Count - 1 do
			character_util.stop(move_character_list[i])
			move_character_list[i].Position = origin_pos_list[i]
		end
	end
end

-- 구멍 상호작용 이벤트
function local_class:interact_with_hole_event()
	party_util.stop_and_disable_control()

	local fall_down_sfx = music_player_util.play_sfx(
			{ sfx_name = '01_fall_down_01', type_priority = 'event', player_priority = 'npc' })

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	local move_duration = 0.5

	character_util.jump(get_party_leader(), 1, move_duration)
	character_util.set_anim(get_party_leader(), { name = 'get' })
	character_util.move_to(get_party_leader(), self.machinery_hole.Position + vector(0, 0, -0.3),
			move_duration, nil, false, false)

	wait_for_unscaled_sec(move_duration)

	get_party_leader().SpineController:Scale(unity_class.vector3.zero, 0.3)

	screen_util.fade_out_circular_async(0.5, 'linear')

	fall_down_sfx:FadeOut(0)

	-- 플레이어 위치 설정
	local target_marker = field:GetMarker(self.exit_machinery_hole_name)

	get_party_leader().SpineController:Scale(unity_class.vector3.one, 0)

	for i = 0, user_party.Count - 1 do
		character_util.set_position(user_party[i], target_marker.position + vector(0, 10, 0) -
				CS.Oak.DirectionExtensions.ToVector3(target_marker.direction) * CS.Oak.Constants.DistBetweenPartyMembers * i, true)
		character_util.set_direction(user_party[i], target_marker.direction)
		character_util.remove_anim(user_party[i])
	end

	wait_for_unscaled_sec(0.6)

	camera_util.move_async(target_marker.position, 0)

	screen_util.fade_in_circular_async(0.6, 'linear')

	for i = 0, user_party.Count - 1 do
		coroutine_manager:StartCoroutine(
				stage.StageGameObject, util.cs_generator(self.free_fall_with_bounce, self, user_party[i]))

		wait_for_sec(0.2)
	end

	wait_for_sec(2)

	coroutine.yield(nil)

	stage_camera:SetTarget(get_party_leader())

	party_util.reset_controllers()
end

-- 캐릭터 자유낙하 + 바운스 연출
function local_class:free_fall_with_bounce(target)
	character_util.set_anim(target, { name = 'embarrassed' })
	character_util.set_emotion(target, { name = 'damaged' })

	local free_fall = CS.CalculatorFreeFall(0.7, target.Position.y, 3)
	local end_pos = vector(target.Position.x, 0, target.Position.z)
	local is_bounce = false
	local bounce_num = 0

	while not free_fall:IsDone() do
		free_fall:Proceed(unity_class.time.deltaTime)
		local cur_y = free_fall:GetDistance()

		if not is_bounce and cur_y < 0 then
			character_util.set_position(target, vector(end_pos.x, 10 + cur_y, end_pos.z), true)
		else
			if not is_bounce then
				is_bounce = true
			end

			character_util.set_position(target, vector(end_pos.x, cur_y, end_pos.z), true)
		end

		if bounce_num < free_fall:NumBounced() then
			bounce_num = bounce_num + 1

			music_player_util.play_sfx(
					{ sfx_name = '01_land_01', type_priority = 'event', player_priority = 'object' })
		end

		coroutine.yield(nil)
	end

	character_util.set_position(target, end_pos)
	character_util.remove_anim(target)
	character_util.remove_emotion(target)
end

function local_class:on_stage_end_event(e)
	self.is_recovery_hp = false
end

function local_class:on_battle_start_event(e)
	self.is_recovery_hp = false
end

function local_class:on_battle_end_event(e)
	if not self.is_recovery_hp then
		self.is_recovery_hp = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.recovery_hp, self))
	end
end

function local_class:recovery_hp()
	local current_time = 0
	local recovery_time = 5
	while self.is_recovery_hp do
		if user_party.Leader.FieldObjectStatsBehaviour.HpRatio >= 1.0 then
			return
		end

		if current_time <= recovery_time then
			current_time = current_time + unity_class.time.deltaTime
		else
			current_time = 0

			local heal_info = CS.Oak.HealInfo()
			heal_info.type = CS.Oak.HealType.Normal
			heal_info.heal = math.floor(user_party.Leader.CharacterStatsBehaviour.MaxHP * 0.01)
			heal_info.sender = user_party.Leader
			heal_info.target = user_party.Leader
			heal_info.skipEffect = true

			command_util.execute_heal(heal_info)
		end

		coroutine.yield(nil)
	end
end

--region 베스 사용처 이벤트
function local_class:init_beth_help_npcs()
	local terrorist_name = 'beth_help_terrorist_'
	local init_pos = 'beth_help_terrorist_pos_'
	local npc_count = 6
	--local battle_group_name = 'beth_usage_event'

	for i = 1, npc_count do
		local npc = get_character(terrorist_name .. i)
		local init_pos = field:GetMarker(init_pos .. i).position

		character_util.set_position(npc, init_pos)
		character_util.set_active_state(npc, 'enabled')
	end
end

function local_class:load_terrorist_bullet()
	unity_object_pool.GetOrCreate(self.custom_sprite_preset)
	unity_object_pool.GetOrCreate(self.hit_projectile_preset)

	yield_return(unity_object_pool, 'WaitAll')

	-- 총알 프리로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'spritesheets/projectiles', 'projectiles_custom', function(prefab)
				self.custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
				self.custom_atlas:Initialize()
			end)

	for i = 1, 4 do
		local bullet = unity_object_pool.GetOrCreate('custom_sprite'):Instantiate(unity_class.vector3.one)
		local bullet_sprite = bullet.transform:GetComponent(typeof(CS.CustomSprite))
		bullet_sprite.transform.localPosition = unity_class.vector3.one * 999
		bullet_sprite.transform.localRotation = unity_class.quaternion.Euler(90, 0, 0)
		bullet_sprite.transform.localScale = unity_class.vector3.one
		bullet_sprite.LocalScale = unity_class.vector2.one
		bullet_sprite.Atlas = self.custom_atlas
		bullet_sprite.SpriteName = 'virus_bullet_1.png'
		bullet_sprite:Rebuild()

		table.insert(self.pooled_bullets, bullet)
	end
end

function local_class:start_terrorist_cease_event()
	self.is_playing_cease_event = true

	local terrorist_1 = get_character('beth_help_terrorist_1')
	local terrorist_2 = get_character('beth_help_terrorist_2')
	local string_key = 'lilithtower_beth_help_'

	local wait_for_sec_custom = function(duration)
		local time_passed = 0
		while time_passed < duration do
			time_passed = time_passed + unity_class.time.deltaTime

			if not self.is_playing_cease_event then
				return false
			end
			coroutine.yield(nil)
		end

		return true
	end

	-- 테러범(남) : 흐흐흐… 이건 우리 거다!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', loop = false, parent = terrorist_1 })
	character_util.set_anim(terrorist_1, { name = 'success', sfx_name = '01_player_jump_01' })
	speech_bubble_util.show_speech_bubble(terrorist_1, { key = string_key.. 1, skip = false })

	if wait_for_sec_custom(2.1) == false then
		speech_bubble_util.remove_bubble(terrorist_1)
		character_util.remove_anim(terrorist_1)
		return
	end

	-- 테러범(여) : 공평하게 나누는 거 잊지 말라고!
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', loop = false, parent = terrorist_2 })
	character_util.set_anim(terrorist_2, { name = 'release', sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble(terrorist_2, { key = string_key.. 2, skip = false })

	if wait_for_sec_custom(2.1) == false then
		character_util.remove_anim(terrorist_1)
		character_util.remove_anim(terrorist_2)
		speech_bubble_util.remove_bubble(terrorist_1)
		return
	end

	character_util.remove_anim(terrorist_1)
	character_util.remove_anim(terrorist_2)

	self.is_playing_cease_event = false
end

function local_class:open_calling_beth_narration()
	-- 베스를 호출하겠습니까?

	self.is_playing_cease_event = false

	local msg = game_string:GetString('lilithtower_beth_help_narration')
	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, 'SetNarration', msg, 0, 1.0)

	-- TODO: Insert string key! not string literal!
	local choose_result = choose_util.play_choose_event({
		{ 'lilithtower_beth_help_decision_1', 'normal' },
		{ 'lilithtower_beth_help_decision_2', 'normal' },
		{ 'lilithtower_beth_help_decision_3', 'normal' },
	})

	yield_return(stage.FieldUINarrationBox, 'HideAnimation')

	if choose_result == 1 then
		self.beth_usage_event_state = self.beth_mini_event_state.called_beth
		self:summon_beth()
	elseif choose_result == 2 then
		self:player_dead_event()
	else
		character_util.move_distance_async(user_party.Leader, vector(-1, 0, 0), nil,
				1.5, true, true)
	end
end

function local_class:summon_beth()
	-- 베스 공중 도약
	wait_for_sec(0.5)

	local target_pos = field:GetMarker('beth_help_stomp_pos').position
	self:start_beth_stomp_attack_scene(target_pos)

	local terrorist_name = 'beth_help_terrorist_'
	local terrorist_count = 6
	local dir = CS.Oak.DirectionExtensions.ToVector3(user_party.Leader.Direction)

	for i = 1, terrorist_count do
		local terrorist = get_character(terrorist_name .. i)
		character_util.air_spin(terrorist, { offset = dir, speed = 1.5, stay_time = 0.6 })
	end

	wait_for_sec(1.5)

	local beth = self.get_beth()

	character_util.set_anim(beth, { name = 'twohand_idle', loop = true })
	character_util.set_emotion(beth, { name = 'normal_eye2' })

	music_player_util.play_sfx_one_shot('01_clap_01')
	character_util.set_emotion(user_party.Leader, 'right')
	character_util.set_anim(user_party.Leader, { name ='clap' })
	character_util.set_emotion(user_party.Leader, { name = 'smile' })

	wait_for_sec(1.5)

	character_util.remove_anim(user_party.Leader)
	character_util.remove_emotion(user_party.Leader)

	-- 베스, 플레이어를 쳐다본다.
	character_util.look_at(beth, user_party.Leader)

	-- TODO: Add string key to the sheet
	-- 베스 (여) : ...위급한 상황인 줄 알았는데 생각 외로 멀쩡하네.
	local string_key = 'lilithtower_beth_help_'
	speech_bubble_util.show_speech_bubble_async(beth, { key = string_key .. 3, skip = true })

	-- 베스 (여) : ...
	speech_bubble_util.show_speech_bubble_async(beth, { key = string_key .. 4, skip = true })

	-- 베스 (여) : 어찌 됐든 지금처럼 필요하면 부르도록 해.
	speech_bubble_util.show_speech_bubble_async(beth, { key = string_key .. 5, skip = true })

	-- 베스 술 마시고 퇴장
	music_player_util.play_sfx_one_shot('01_drinking_01')
	character_util.set_emotion(beth, { name = 'drunken' })
	character_util.set_anim(beth, { name = 'unique/drunk_seat', upper = true })

	wait_for_sec(2)

	local y_dest = lua_helper.get_conditional_value(user_party.Leader.Position.z >= 193.5, -0.5, 0.5)

	character_util.set_anim(beth, { name = 'walk' })
	character_util.move_distance_async(beth, vector(0, 0, y_dest),
			nil, 3, true, false, false)
	character_util.move_distance_async(beth, vector(-9, 0, 0),
			nil, 3, true, false, false)

	character_util.set_position(beth, vector(999, 0, 999))
	character_util.set_active_state(beth, 'disabled')
end

function local_class:start_beth_stomp_attack_scene(target_pos)
	local beth = self.get_beth()

	beth.SpineController:SetAttachment('[base]weapon1', 'cwp_invaderknight')
	character_util.set_anim(beth, { name = 'invader_knight/attack2', loop = false, scale = 3 })
	character_util.set_emotion(beth, { name = 'attack' })
	character_util.set_direction(beth, 'left')
	character_util.set_active_state(beth, 'enabled')

	local time_passed = 0
	local fall_duration = 0.25
	local jump_height = 15
	local is_start_stomp_effect = false
	local did_stomped = false

	-- TODO: Set initial jump start position
	local jump_start_position = target_pos + vector(0, 15, 0)

	local get_height_at = function(target_pos)
		return field:GetTileInfoAt(target_pos):GetHeightAt(target_pos)
	end

	local create_cross_explosion_fx = function(target_pos)
		local effect_pos = vector_util.get_x0z(target_pos, get_height_at(target_pos) + 0.1)
		local cross_fx_pool = unity_object_pool.GetOrCreate('fx_boss_darkmagician_cross_explosion')
		return cross_fx_pool:Instantiate(effect_pos)
	end

	while(did_stomped == false) do
		time_passed = time_passed + unity_class.time.deltaTime

		if time_passed >= fall_duration - 0.3 and not is_start_stomp_effect then
			create_cross_explosion_fx(target_pos)
			--camera_util.resize_to(3.3, 0.2)
			music_player_util.play_sfx_one_shot('02_ficklelady_explosion_01')
			music_player_util.play_sfx_one_shot('02_stomp_fire_01')
			is_start_stomp_effect = true
		elseif time_passed >= fall_duration - 0.1 then
			stage.StageCamera:Shake(0.6, 0.7)
		end

		if time_passed >= fall_duration then
			did_stomped = true
			time_passed = 0
		elseif time_passed < fall_duration and did_stomped == false then
			local progress = unity_class.mathf.Clamp01(CS.Oak.Interpolations.EaseOutQuart(time_passed, 0, 1, fall_duration))
			beth.Position = vector_util.get_x0z(target_pos, get_height_at(jump_start_position))
					+ unity_class.vector3.up * jump_height * (1 - progress)
		end

		coroutine.yield()
	end
end

function local_class:player_dead_event()
	local starting_idx = 3
	local terrorist_cnt = 6
	local terrorists = {}

	character_util.move_distance_async(user_party.Leader, vector(0.5, 0, 0), nil,
			1.5, true, true)

	music_player_util.play_sfx_one_shot('02_gun_reload_02')
	for idx = starting_idx, terrorist_cnt do
		local terrorist = get_character('beth_help_terrorist_' .. idx)
		table.insert(terrorists, terrorist)
		character_util.set_anim(terrorist,{ name = 'rifle_reload', loop = false })
	end

	local fire_routine = function(shooter_idx, target)
		local shooter_pos = terrorists[shooter_idx].Position
		local target_pos = target.Position
		local bullet = self.pooled_bullets[shooter_idx].transform:GetComponent(typeof(CS.CustomSprite))
		character_util.set_anim(terrorists[shooter_idx],{ name = 'rifle_idle' })
		character_util.set_anim(terrorists[shooter_idx],{ name = 'rifle_shoot', loop = false })

		wait_for_sec(0.1)

		music_player_util.play_sfx_one_shot('02_gun_shoot_08')

		bullet.transform.position = shooter_pos

		local look_rotation = unity_class.quaternion.LookRotation(target_pos - shooter_pos)
		bullet.transform.localRotation = look_rotation * unity_class.quaternion.Euler(90, 0, 0)

		local move_distance = (shooter_pos - target_pos).magnitude
		local speed = 12

		local timer = 0
		local duration = move_distance / speed

		while timer < duration do
			timer = timer + unity_class.time.deltaTime

			local current_pos = unity_class.vector3.Lerp(shooter_pos, target_pos, 1 - ((duration - timer) / duration))

			bullet.transform.position = current_pos

			coroutine.yield(nil)
		end

		-- 피격
		unity_object_pool.GetOrCreate(self.hit_projectile_preset):Instantiate(
				user_party.Leader.Position + vector(0, 0.3, 0))

		bullet.transform.position = vector(999, 0, 999)

		CS.DamageNumber.ShowDamageNumber(user_party.Leader, 999999, unity_class.color.red, user_party.Leader.Position)
	end

	local player_hit_routine = function(shooter)
		character_util.spine_deviate_local(
				user_party.Leader, CS.Oak.DirectionExtensions.ToVector3(shooter.Direction).normalized * 0.3,
				0.3, 0.2)
		character_util.spine_pulse_color(
				user_party.Leader, CS.Oak.Constants.DamageColor, 1, 1, 1)
		character_util.spine_damage_squish(
				user_party.Leader, 1.3, 0.7, 1, 0.3)
	end

	local fire_n_times_routine = function(terrorist, idx, each_fire_routine, each_hit_routine, times)
		for i = 1, times do
			each_fire_routine(idx, user_party.Leader)
			wait_for_sec(0.15)
			music_player_util.play_sfx_one_shot('02_hit_big_01')
			wait_for_sec(0.15)
			each_hit_routine(terrorist)
			wait_for_sec(0.3)
		end

		character_util.set_anim(terrorist,{ name = 'rifle_idle' })
	end

	local interval = 0.2
	local idx = 1

	character_util.set_emotion(user_party.Leader, { name = 'surprise' })

	wait_for_sec(0.75)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(fire_n_times_routine, terrorists[idx], idx, fire_routine, player_hit_routine, 2))
	wait_for_sec(interval)
	character_util.set_emotion(user_party.Leader, { name = "damaged" })

	idx = 3
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(fire_n_times_routine, terrorists[idx], idx, fire_routine, player_hit_routine, 2))
	wait_for_sec(interval)
	idx = 2
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(fire_n_times_routine, terrorists[idx], idx, fire_routine, player_hit_routine, 2))
	wait_for_sec(interval)
	idx = 4
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(fire_n_times_routine,terrorists[idx], idx, fire_routine, player_hit_routine, 2))

	wait_for_sec(1.75)

	user_party.Leader.SpineController:AddColor(user_party.Leader.Name, unity_color({0, 0, 0, 1}), 1, 3)
	character_util.set_direction(
			user_party.Leader, CS.Oak.DirectionExtensions.GetSideDirection(user_party.Leader.Direction))
	character_util.set_anim(user_party.Leader, { name = "dead", loop = false, sfx_name ='01_hit_npc_01' })

	for i = starting_idx, terrorist_cnt do
		character_util.set_anim(terrorists[i],{ name = 'rifle_idle' })
	end

	wait_for_sec(3)

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 리셋
	user_party.Leader.SpineController:RemoveColor(user_party.Leader.Name, 0)
	character_util.set_position(user_party.Leader, vector(28.48725, 0, 193.8741))
	character_util.set_direction(user_party.Leader, 'right')
	character_util.remove_anim(user_party.Leader)
	character_util.remove_emotion(user_party.Leader)

	stage_camera:SetTarget(get_party_leader())

	wait_for_sec(1)

	screen_util.fade_in_circular_async(0.5, 'linear')
end
--endregion

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
