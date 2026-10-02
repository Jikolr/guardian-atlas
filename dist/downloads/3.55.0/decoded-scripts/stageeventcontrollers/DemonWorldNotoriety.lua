local local_class = newclass("DemonWorldNotorietyController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 리소스 홀더
	self.resholder = nil

--region Police
	-- 경찰 테이블 1
	self.police_table_1 = {}

	-- 경찰 테이블 2
	self.police_table_2 = {}

	-- 경찰 테이블 3
	self.police_table_3 = {}

	-- 경찰 테이블 4
	self.police_table_4 = {}

	-- 경찰 테이블 5
	self.police_table_5 = {}

	-- 에리나
	self.erina = nil

	-- 경찰 이름
	self.police_name_1 = 'police_1_'
	self.police_name_2 = 'police_2_'
	self.police_name_3 = 'police_3_'
	self.police_name_4 = 'police_4_'
	self.police_name_5 = 'police_5_'
	self.erina_name = 'police_erina'

	-- 경찰 수
	self.police_nums = { 4, 6, 6, 6, 6 }

	-- 경찰 생성 마커의 정보를 저장하는 테이블
	self.police_spawn_markers = {}

	-- 경찰 생성 마커 이름(일단 테스트용이므로 시민 생성 마커의 1번을 사용함)
	self.police_spawn_marker_name = 'npc_spawn_'

	-- 경찰 상태
	self.police_state = {
		idle = 0,
		search_player = 1,
		battle = 2,
		dead = 3
	}

	-- 경찰 시야 거리와 각도
	self.police_sight_distance = 4.5
	self.police_sight_angle = 60

	-- 경찰 쓰러트린 후 재생성까지 대기 시간
	self.police_respawn_delays = { 7, 5, 4, 3, 3 }

	-- 중복 발견 방지 플래그
	self.is_detected_by_police = false

	-- 플레이어가 경찰과 전투하기 전 원래 위치와 방향
	self.player_saved_pos = nil
	self.player_saved_dir = nil

	-- 플레이어와 경찰의 전투 위치 마커 이름
	self.police_battle_marker_name = 'police_battle'

	-- 배틀 그룹 이름
	self.police_battle_group_name = 'police_'
	self.police_battle_group_name_1 = 'police_1'
	self.police_battle_group_name_2 = 'police_2'
	self.police_battle_group_name_3 = 'police_3'
	self.police_battle_group_name_4 = 'police_4'
	self.police_battle_group_name_5 = 'police_5'
--endregion

--region Notoriety
	-- 플레이어의 악명
	self.current_notoriety = 0

	-- 플레이어의 악명 레벨
	self.notoriety_lv = 0

	-- 단계별 악명 수치
	self.notoriety_star_values = { 10, 50, 110, 170, 230 }

	-- 특수 행동 시 올라가는 악명 수치
	self.kill_civilian_notoriety = 5
	self.kill_police_notoriety = 10
	self.kill_erina_notoriety = 10

	-- 악명 레벨 커스텀 이벤트 이름
	self.notoriety_lv_custom_event_name = 'notoriety_lv_'
	-- 커스텀 이벤트 (나중에 세이브/로드 방식 변경할 것)
	self.notoriety_lv_save = 'notoriety_lv_save'
	self.notoriety_num_save = 'notoriety_num_save'
	self.notoriety_lv_load = 'notoriety_lv_load'
	self.notoriety_num_load = 'notoriety_num_load'
--endregion

--region Notoriety UI
	-- 악명 UI
	self.notoriety_ui = nil

	-- 별 리스트
	self.notoriety_ui_star_list = nil

	-- 게이지 바와 라벨
	self.notoriety_ui_gauge_bar = nil
	self.notoriety_ui_gauge_bar_label = nil

	-- 악명 상승 요청 req Id
	self.notoriety_req_id = -1

	-- UI의 별 개수
	self.notoriety_ui_star_num = 5

	-- 게이지에 표시될 악명 수치 최대값
	self.notoriety_ui_gauge_max = 230

	-- UI의 악명 증가 연출 시간
	self.notoriety_add_duration = 0.5

	-- 별 스프라이트 페이드 인 시간
	self.star_sprite_fade_in_duration = 1
--endregion

--region Coin
	-- 경찰 드랍 골드 양 최소값
	self.police_drop_coin_min = 300

	-- 경찰 드랍 골드 양 최대값
	self.police_drop_coin_max = 500
--endregion

	-- 메인 퀘스트 번호
	self.main_quest_id = 216

	-- 스테이지 이름
	self.stage_2_name = 'demonworld_part1_1_2'
	self.stage_3_name = 'demonworld_part1_1_3'
	self.stage_4_name = 'demonworld_part1_1_4'

	-- 이름으로 시민과 경찰 판정
	self.civilian_name = 'spawn_npc'
	self.police_name = 'police'

	-- 감시자
	self.fairy_glitch_name = 'fairy_glitch'

	-- 커스텀 이벤트 이름
	self.coin_drop_event = 'coin_drop'

	-- 오브젝트 풀 프리셋
	self.teleport_effect_preset = 'FX_reset_object'
	self.explosion_effect_preset = 'FX_dead'
end

function local_class:load_resource()
	-- 2스테이지, 메인 퀘스트 진행 상황이 5 이하면 작동하지 않음
	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)

	if stage.Name == self.stage_2_name and main_quest ~= nil and main_quest.InnerProgress < 6 then
		return
	end

	unity_object_pool.GetOrCreate(self.teleport_effect_preset)

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIShowEvent), 'on_field_ui_show_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldUIHideEvent), 'on_field_ui_hide_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- 경찰 생성 마커 테이블 설정
	if stage.Name == self.stage_2_name then
		-- 마커 정보 테이블에 등록
		for i = 1, 17 do
			self.police_spawn_markers[i] = {
				marker = field:GetMarker(self.police_spawn_marker_name..i..'_'..1),
				is_used = false
			}
		end
	end

	-- 경찰 정보 테이블에 등록
	for i = 1, self.police_nums[1] do
		local cur_police = get_character(self.police_name_1..i)

		self.police_table_1[i] = {
			character = cur_police,
			state = self.police_state.idle,
			attack_range = nil
		}
	end

	for i = 1, self.police_nums[2] do
		local cur_police = get_character(self.police_name_2..i)

		self.police_table_2[i] = {
			character = cur_police,
			state = self.police_state.idle,
			attack_range = nil
		}
	end

	for i = 1, self.police_nums[3] do
		local cur_police = get_character(self.police_name_3..i)

		self.police_table_3[i] = {
			character = cur_police,
			state = self.police_state.idle,
			attack_range = nil
		}
	end

	for i = 1, self.police_nums[4] do
		local cur_police = get_character(self.police_name_4..i)

		self.police_table_4[i] = {
			character = cur_police,
			state = self.police_state.idle,
			attack_range = nil
		}
	end

	for i = 1, self.police_nums[5] do
		local cur_police = get_character(self.police_name_5..i)

		self.police_table_5[i] = {
			character = cur_police,
			state = self.police_state.idle,
			attack_range = nil
		}
	end

	self.erina = get_character(self.erina_name)

	-- 에리나도 테이블에 추가
	self.police_table_5[self.police_nums[5] + 1] = {
		character = self.erina,
		state = self.police_state.idle,
		attack_range = nil
	}

	return util.cs_generator(self.on_load_resource_routine, self)
end

function local_class:on_load_resource_routine()
	self.resholder = CS.Foundations.ResourceHolder()

	-- 악명 UI 로드
	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.resholder, 'ondemand/v2_15_demonworld/ui', 'notoriety_ui', function(prefab)
				self.notoriety_ui = CS.NGUITools.AddChild(field_ui_manager.Transform.gameObject, prefab)

				CS.Utils.ChangeLayersRecursively(self.notoriety_ui.transform, 'FieldUI')
			end)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIShowEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldUIHideEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.police_table_1 = nil
	self.police_table_2 = nil
	self.police_table_3 = nil
	self.police_table_4 = nil
	self.police_table_5 = nil

	self.erina = nil

	self.police_spawn_markers = nil

	if self.resholder ~= nil then
		self.resholder:Dispose()
		self.resholder = nil
	end

	self.notoriety_ui = nil
	self.notoriety_ui_star_list = nil
	self.notoriety_ui_gauge_bar = nil
	self.notoriety_ui_gauge_bar_label = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	-- 악명 UI 기본 설정
	self.notoriety_ui.transform:Find('Contents/Button/item/Title'):GetComponent(typeof(CS.UILabel)).text =
		game_string:GetString('demonworld_part1_notoriety')

	self.notoriety_ui_gauge_bar = self.notoriety_ui.transform:Find(
			'Contents/Button/item/Gauge Bar/After'):GetComponent(typeof(CS.UISprite))

	self.notoriety_ui_gauge_bar_label = self.notoriety_ui.transform:Find(
			'Contents/Button/item/Gauge Bar/Label'):GetComponent(typeof(CS.UILabel))
	self.notoriety_ui_gauge_bar_label.text = tostring(self.current_notoriety)

	self.notoriety_ui_star_list = create_generic_list(CS.CustomSprite)
	for i = 1, self.notoriety_ui_star_num do
		local cur_custom_sprite = self.notoriety_ui.transform:Find(
				'Contents/Button/item/stars/star_'..i):GetComponent(typeof(CS.CustomSprite))

		cur_custom_sprite.TintColor = unity_color({ 0, 0, 0, 1 })
		cur_custom_sprite:Rebuild(true)

		self.notoriety_ui_star_list:Add(cur_custom_sprite)
	end

	self.notoriety_ui_gauge_bar.fillAmount = 0.0
end

function local_class:on_stage_start_event(e)
	-- 악명 레벨에 따라서 경찰 생성
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_police, self))
end

function local_class:on_field_ui_show_event(e)
	self.notoriety_ui:SetActive(true)
end

function local_class:on_field_ui_hide_event(e)
	self.notoriety_ui:SetActive(false)
end

function local_class:on_field_object_destroyed_event(e)
	if string.find(e.FieldObject.Name, self.civilian_name) or string.find(e.FieldObject.Name, self.police_name) then
		-- 플레이어나 파티원이 파괴한 경우에만 진행
		for i = 0, user_party.Count - 1 do
			if lua_helper.reference_equals(e.Destroyer, user_party[i]) then
				local notoriety_point = self.kill_civilian_notoriety

				if string.find(e.FieldObject.Name, self.police_name) then
					if lua_helper.reference_equals(e.FieldObject, self.erina) then
						notoriety_point = self.kill_erina_notoriety
					else
						notoriety_point = self.kill_police_notoriety

						-- 코인 양 정함
						local coin_amount = unity_class.random.Range(self.police_drop_coin_min, self.police_drop_coin_max)

						message_system:Publish(CS.Oak.CustomStageEvent.Create(
								e.FieldObject, { self.coin_drop_event, tostring(coin_amount) }))
					end
				end

				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.add_notoriety, self, self.current_notoriety + notoriety_point))
			end
		end
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.police_battle_group_name_1 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_police, self, 1))
	elseif e.BattleGroupName == self.police_battle_group_name_2 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_police, self, 2))
	elseif e.BattleGroupName == self.police_battle_group_name_3 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_police, self, 3))
	elseif e.BattleGroupName == self.police_battle_group_name_4 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_police, self, 4))
	elseif e.BattleGroupName == self.police_battle_group_name_5 then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.defeat_erina, self))
	end
end

function local_class:on_custom_stage_event(e)
	-- 악명 레벨 변경
	if e:GetParamAt(0) == 'notoriety_lv_changed' then
		local level = tonumber(e:GetParamAt(1))
		self.notoriety_lv = level

		for i = 1, level do
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_star, self, i))
		end

		self.current_notoriety = self.notoriety_star_values[3]

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.add_notoriety, self, self.current_notoriety))

		message_system:Publish(CS.Oak.CustomStageEvent.Create(user_party_leader,
				{ self.notoriety_lv_custom_event_name..self.notoriety_lv }))

		-- 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_police, self))
	-- 악명 레벨 로드
	elseif e:GetParamAt(0) == self.notoriety_lv_load and
			e:GetParamAt(1) ~= nil and tonumber(e:GetParamAt(1)) ~= nil then
		self.notoriety_lv = tonumber(e:GetParamAt(1))

		for i = 0, self.notoriety_lv - 1 do
			self.notoriety_ui_star_list[i].TintColor = unity_color({ 1, 1, 1, 1 })
			self.notoriety_ui_star_list[i]:Rebuild(true)
		end
	-- 악명 수치 로드
	elseif e:GetParamAt(0) == self.notoriety_num_load and
			e:GetParamAt(1) ~= nil and tonumber(e:GetParamAt(1)) ~= nil then
		self.current_notoriety = tonumber(e:GetParamAt(1))

		self.notoriety_ui_gauge_bar.fillAmount = math.min(self.current_notoriety / self.notoriety_ui_gauge_max, 1)
		self.notoriety_ui_gauge_bar_label.text = tostring(math.floor(self.current_notoriety))
	end
end

-- 악명 증가
function local_class:add_notoriety(end_notoriety)
	-- Request ID 저장
	self.notoriety_req_id = self.notoriety_req_id + 1
	local cur_req_id = self.notoriety_req_id

	self.current_notoriety = end_notoriety
	self:check_notoriety_level_up()

	-- 악명 값 저장
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			user_party_leader, { self.notoriety_num_save, self.current_notoriety }))

	-- 증가 연출 진행
	local cur_time = unity_class.time.time
	local start_notoriety = self.notoriety_ui_gauge_max * self.notoriety_ui_gauge_bar.fillAmount

	while self.notoriety_req_id == cur_req_id and unity_class.time.time - cur_time < self.notoriety_add_duration do
		local normalized = (unity_class.time.time - cur_time) / self.notoriety_add_duration

		-- UI 변경 (수치는 Int로 표시)
		local cur_bar_value = start_notoriety + (end_notoriety - start_notoriety) * normalized

		self.notoriety_ui_gauge_bar.fillAmount = math.min(cur_bar_value / self.notoriety_ui_gauge_max, 1)
		self.notoriety_ui_gauge_bar_label.text = tostring(math.floor(cur_bar_value))

		coroutine.yield(nil)
	end

	-- 추가 요청이 없고 정상적으로 완료된 경우, 완료 값 지정
	if self.notoriety_req_id == cur_req_id then
		self.notoriety_ui_gauge_bar.fillAmount = math.min((self.current_notoriety / self.notoriety_ui_gauge_max), 1)
		self.notoriety_ui_gauge_bar_label.text = tostring(math.floor(self.current_notoriety))
	end
end

-- 악명 값이 특정 이상 올라간 경우, 레벨 상승시켜주고 경찰 생성함
function local_class:check_notoriety_level_up()
	local past_notoriety_lv = self.notoriety_lv

	-- 악명 값이 특정 이상 올라간 경우 레벨 상승시켜주고 경찰 생성
	if self.notoriety_lv == 0 and self.current_notoriety >= self.notoriety_star_values[1] then
		self.notoriety_lv = 1
	end

	-- 악명 레벨이 변한 경우
	if past_notoriety_lv ~= self.notoriety_lv then
		-- 커스텀 이벤트 Publish
		message_system:Publish(CS.Oak.CustomStageEvent.Create(
				user_party_leader, { self.notoriety_lv_custom_event_name..self.notoriety_lv }))

		-- 별 추가
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_star, self, self.notoriety_lv))

		-- 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_police, self))
	end
end

-- 별 UI에 추가하는 연출
function local_class:add_star(lv)
	-- 악명 레벨 저장
	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			user_party_leader, { self.notoriety_lv_save, self.notoriety_lv }))

	local cur_time = unity_class.time.time
	local cur_star = self.notoriety_ui_star_list[lv - 1]

	while unity_class.time.time - cur_time < self.star_sprite_fade_in_duration do
		local normalized = (unity_class.time.time - cur_time) / self.star_sprite_fade_in_duration

		cur_star.TintColor = unity_color({ normalized, normalized, normalized, 1 })
		cur_star:Rebuild(true)

		coroutine.yield(nil)
	end

	cur_star.TintColor = unity_color({ 1, 1, 1, 1 })
	cur_star:Rebuild(true)
end

-- 경찰 생성
function local_class:spawn_police()
	if self.notoriety_lv <= 0 then
		return
	end

	-- 레벨에 따라 대기
	wait_for_sec(self.police_respawn_delays[self.notoriety_lv])

	-- 레벨에 따라 Police 설정
	local cur_police_table = self:get_police_table(self.notoriety_lv)

	-- 악명 레벨이 5인 경우 특수 연출 실행
	if self.notoriety_lv == 5 then
		-- 전투 장소 마커 설정
		local battle_marker = field:GetMarker(self.police_battle_marker_name)

		for i = 1, #cur_police_table do
			local val = math.floor((i - 1) / 3)
			local mod = (i - 1) % 3

			if i == #cur_police_table then
				character_util.set_position(cur_police_table[i].character,
						battle_marker.position + vector(0, 0, 0.5))
				character_util.set_direction(cur_police_table[i].character, 'down')
			else
				character_util.set_position(cur_police_table[i].character,
						battle_marker.position + vector(-1.5 + 1.5 * mod, 0, 1.5 + 1.5 * val))
			end
		end

		field_ui_manager:Hide()
		party_util.stop_and_disable_control()

		camera_util.shake(0.3, 0.7)

		for i = 0, user_party.Count - 1 do
			character_util.set_anim(user_party[i], { name = 'embarrassed' })
			character_util.set_emotion(user_party[i], { name = 'surprise' })
		end

		wait_for_sec(1)

		for i = 0, user_party.Count - 1 do
			character_util.set_direction(user_party[i], 'up')
			character_util.remove_anim(user_party[i])
			character_util.remove_emotion(user_party[i])
		end

		camera_util.move(user_party_leader.Position + vector(0, 0, 3), 1)

		screen_util.fade_out_async(1, unity_class.color.black, 'linear')

		coroutine.yield(nil)

		camera_util.resize_to(3, 0)
		camera_util.move_async(self.erina.Position, 0)

		wait_for_sec(0.5)

		screen_util.fade_in_async(1, unity_class.color.black, 'linear')

		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(
				self.erina, { key = 'demonworld_part1_police_3', skip = true })

		field:Tint(nil, CS.UnityEngine.Color(1, 0.5, 0.5, 0.5), 0.1)

		character_util.set_anim(self.erina, { name = 'sword_attack', loop = false })
		character_util.set_emotion(self.erina, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(
				self.erina, { key = 'demonworld_part1_police_4', bubble_type = 'shout', skip = true })

		field:RemoveTint(nil, 1)

		character_util.remove_anim(self.erina)

		wait_for_sec(0.5)

		screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

		camera_util.resize_to_default(0)
		stage_camera:SetTarget(user_party_leader)

		wait_for_sec(0.5)

		screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

		field_ui_manager:Show()
		party_util.reset_controllers()
	end

	-- 스폰 마커 초기화
	for i = 1, #self.police_spawn_markers do
		self.police_spawn_markers[i].is_used = false
	end

	for n = 1, #cur_police_table do
		-- 카메라에 보이지 않는 것 체크를 위해 스테이지 카메라의 파라미터 받아옴
		local camera_pos = stage_camera.LookAtPosition

		-- 먼저 카메라와 가장 가까우면서 화면에 보이지 않는 NPC 생성 마커를 찾는다
		local shortest_dist = 9999
		local selected_marker = nil
		local marker_index = 0

		for i = 1, #self.police_spawn_markers do
			local cur_marker = self.police_spawn_markers[i].marker

			-- 카메라에 보이거나 이미 사용 중인 마커면 넘어감
			if not self:is_pos_in_camera(cur_marker.position) and not self.police_spawn_markers[i].is_used then
				-- 마커와 카메라 거리 측정 후 이전 최단 거리와 비교
				local cur_dist = math.abs((camera_pos - cur_marker.position).magnitude)

				if shortest_dist > cur_dist then
					selected_marker = cur_marker
					shortest_dist = cur_dist
					marker_index = i
				end
			end
		end

		-- 선택된 마커 값이 nil이면 넘어간다
		if selected_marker ~= nil then
			local cur_police_info = cur_police_table[n]

			-- 카메라에 보이지 않으면서 카메라와 최단 거리의 마커에 경찰 생성
			cur_police_info.state = self.police_state.search_player

			character_util.set_active_state(cur_police_info.character, 'enabled')
			character_util.set_position(cur_police_info.character, selected_marker.position)
			character_util.set_direction(cur_police_info.character, selected_marker.direction)

			if cur_police_info.attack_range == nil then
				cur_police_info.attack_range = CS.AttackRange.CreateArc(
						cur_police_info.character.Position, self.police_sight_distance, self.police_sight_angle)
				attack_range_util.show(cur_police_info.attack_range, 0)
			else
				attack_range_util.show(cur_police_info.attack_range, 0)
			end

			local direction = direction_util.to_vector3(cur_police_info.character.Direction)

			attack_range_util.setup_by_direction(cur_police_info.attack_range, cur_police_info.character.Position, direction, 0)

			self.police_spawn_markers[marker_index].is_used = true

			-- 길 찾을 때 끼지 않게 Hitbox 변경
			cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(0.4, 0.75, 0.4))

			-- 플레이어 쫓아오는 State로 변경
			cur_police_info.character.FieldObjectController = CS.Oak.FollowEventCharacterController.Create(
					cur_police_info.character, '', 'player')

			character_util.set_anim(cur_police_info.character, { name = 'walk' })
		end
	end

	-- 플레이어가 발각되었는지 확인하는 루틴 실행
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.check_police_find_player_and_battle, self, self.notoriety_lv))
end

-- 레벨에 따른 Police Table 리턴
function local_class:get_police_table(lv)
	local cur_police_table = self.police_table_1

	if lv == 2 then
		cur_police_table = self.police_table_2
	elseif lv == 3 then
		cur_police_table = self.police_table_3
	elseif lv == 4 then
		cur_police_table = self.police_table_4
	elseif lv == 5 then
		cur_police_table = self.police_table_5
	end

	return cur_police_table
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴
function local_class:is_pos_in_camera(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	-- AttackRange 감안해서 유예값 널널하게 설정
	if math.abs(camera_pos.x - pos.x) > cam_half_width + 4 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 6 then
		return false
	end

	return true
end

-- 경찰들이 플레이어 찾았는지 확인하고 전투 시작하는 루틴
function local_class:check_police_find_player_and_battle(table_id)
	-- 파라미터에 따라 Police 설정
	local cur_police_table = self:get_police_table(table_id)
	local find_police
	local is_wait_for_screenplay = false

	while true do
		local loop_out = false

		-- 중복 발생 플래그가 on거나 플레이어 컨트롤이 빼앗긴 경우, 전투 중인 경우는 넘어감
		if not self.is_detected_by_police and not
			lua_helper.type_compare(user_party_leader.FieldObjectController.CurrentState,
				CS.Oak.CharacterControllerScreenplayState) and
				is_unity_null(stage.BattleManager:GetBattleFor(user_party)) then
			-- ScreenPlayState 대기 끝나면 다시 이동 시작
			if is_wait_for_screenplay then
				is_wait_for_screenplay = false

				for i = 1, #cur_police_table do
					character_util.set_anim(cur_police_table[i].character, { name = 'walk' })

					cur_police_table[i].character:OnEvent(CS.Oak.StateResetEvent.Instance)
				end
			end

			for i = 1, #cur_police_table do
				if self:is_in_sight(cur_police_table[i].character, user_party_leader,
						self.police_sight_distance, self.police_sight_angle) then
					loop_out = true
					find_police = cur_police_table[i].character

					break
				else
					local direction = direction_util.to_vector3(cur_police_table[i].character.Direction)

					attack_range_util.setup_by_direction(
							cur_police_table[i].attack_range, cur_police_table[i].character.Position, direction, 0)
				end
			end
		-- ScreenPlayState 상태면 이동 중단하고 대기함
		elseif not is_wait_for_screenplay and lua_helper.type_compare(
				user_party_leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
			is_wait_for_screenplay = true

			for i = 1, #cur_police_table do
				character_util.stop(cur_police_table[i].character)
				character_util.set_anim(cur_police_table[i].character, { name = 'idle' })
			end
		end

		if loop_out then
			break
		end

		coroutine.yield(nil)
	end

	self.is_detected_by_police = true

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	-- 추적하던 경찰들 전부 멈춤
	for i = 1, #cur_police_table do
		cur_police_table[i].character.FieldObjectController = CS.Oak.NPCCharacterController()
		character_util.stop(cur_police_table[i].character)
		character_util.remove_anim(cur_police_table[i].character)

		CS.Oak.MessageSystem.Instance:Publish(
				CS.Oak.AttackRangeEndEvent.Create(cur_police_table[i].character, cur_police_table[i].attack_range))

		-- AttackRange 비활성화
		if cur_police_table[i].attack_range ~= nil then
			cur_police_table[i].attack_range:Hide()
		end
	end

	-- 플레이어 연출
	for i = 0, user_party.Count - 1 do
		character_util.look_at(user_party[i], find_police)
		character_util.jump(user_party[i], 1, 0.5)
		character_util.set_anim(user_party[i], { name = 'embarrassed' })
		character_util.set_emotion(user_party[i], { name = 'damaged' })
	end

	camera_util.move_async(find_police.Position, 0.5)

	-- 발견한 경찰 연출
	CS.Oak.NoticeIcon.SetBattleStart(find_police)

	if lua_helper.reference_equals(find_police, self.erina) then
		character_util.set_emotion(find_police, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(
				find_police, { key = 'demonworld_part1_police_3', skip = true })
	else
		character_util.jump(find_police, 0.5, 0.3)
		character_util.set_anim(find_police, { name = 'release', sfx_name = '01_swing_01' })
		character_util.set_emotion(find_police, { name = 'mad' })

		speech_bubble_util.show_speech_bubble_async(
				find_police, { key = 'demonworld_part1_police_1', skip = true })
	end

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	-- 플레이어 원래 위치 저장
	self.player_saved_pos = user_party_leader.Position
	self.player_saved_dir = user_party_leader.Direction

	-- 전투 장소 마커 설정
	local battle_marker = field:GetMarker(self.police_battle_marker_name)

	stage_camera:SetTarget(user_party_leader)

	-- 플레이어 이동
	party_util.align_party(battle_marker.position, 'down', 0, 'arc')

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
	end

	-- 적 이동
	for i = 1, #cur_police_table do
		local cur_police_info = cur_police_table[i]

		local val = math.floor((i - 1) / math.floor(#cur_police_table / 2))
		local mod = (i - 1) % math.floor(#cur_police_table / 2)

		cur_police_info.state = self.police_state.battle

		-- 히트박스 복구
		cur_police_info.character.Hitbox = CS.Oak.Hitbox(vector(1.1, 0.75, 1.1))

		if table_id == 1 then
			character_util.set_position(cur_police_info.character,
					battle_marker.position + vector(-1.5 + 3 * mod, 0, 0.5 + 1.5 * val))
		else
			if table_id < 5 then
				character_util.set_position(cur_police_info.character,
						battle_marker.position + vector(-1.5 + 1.5 * mod, 0, 0.5 + 1.5 * val))
			else
				if i == #cur_police_table then
					character_util.set_position(cur_police_info.character,
							battle_marker.position + vector(0, 0, 0.5))
				else
					character_util.set_position(cur_police_info.character,
							battle_marker.position + vector(-1.5 + 1.5 * mod, 0, 1.5 + 1.5 * val))
				end
			end
		end

		character_util.set_direction(cur_police_info.character, 'down')
		character_util.remove_anim(cur_police_info.character)
		character_util.remove_emotion(cur_police_info.character)
	end

	wait_for_sec(0.5)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	-- 전투 시작
	for i = 1, #cur_police_table do
		local cur_police_info = cur_police_table[i]

		character_util.convert_to_monster(cur_police_info.character,
				self.police_battle_group_name..table_id, nil)
		command_util.execute_monster_notice(cur_police_info.character, user_party_leader, 'battle')

		-- 에리나 DeathType 변경
		if lua_helper.reference_equals(cur_police_info.character, self.erina) then
			cur_police_info.character.DamagedBehaviour.DeathType = CS.Oak.DeathType.Prostrate
		end
	end

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- A의 시야에 B가 들어왔는지 확인, y축은 무시함
function local_class:is_in_sight(fo, target, distance, angle)
	local full_diff = target.Bounds.center - fo.Bounds.center
	local diff = target.Bounds.center - fo.Bounds.center

	if diff.magnitude > distance then
		return false
	end

	diff.y = 0

	if unity_class.vector3.Angle(diff.normalized, direction_util.to_vector3(fo.Direction)) > angle / 2 then
		return false
	end

	if field:IsAnythingBlockingWithoutBounds(CS.UnityEngine.Bounds(fo.Bounds.center, vector(0.05, 0.05, 0.05)),
			CS.Oak.EntityGroups.Obstacle, vector_util.get_x0z(full_diff)) then
		return false
	end

	return true
end

-- 경찰 쓰러트리면 원래대로 돌아옴
function local_class:defeat_police(table_id)
	-- 파라미터에 따라 Police 설정
	local cur_police_table = self:get_police_table(table_id)

	for i = 1, #cur_police_table do
		local cur_police_info = cur_police_table[i]

		cur_police_info.state = self.police_state.dead
	end

	wait_for_sec(2)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	screen_util.fade_out_async(0.5, unity_class.color.black, 'linear')

	party_util.align_party(self.player_saved_pos + CS.Oak.DirectionExtensions.ToVector3(self.player_saved_dir),
			self.player_saved_dir, 0, 'arc')

	wait_for_sec(0.5)

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	-- 악명 레벨이 상승하고 경찰 생성
	local past_notoriety_lv = self.notoriety_lv

	if self.notoriety_lv == 1 then
		self.notoriety_lv = 2
	elseif self.notoriety_lv == 2 then
		self.notoriety_lv = 3
	elseif self.notoriety_lv == 3 then
		self.notoriety_lv = 4
	elseif self.notoriety_lv == 4 then
		self.notoriety_lv = 5
	end

	-- 악명 레벨이 변한 경우
	if past_notoriety_lv ~= self.notoriety_lv then
		-- 커스텀 이벤트 Publish
		message_system:Publish(CS.Oak.CustomStageEvent.Create(
				user_party_leader, { self.notoriety_lv_custom_event_name..self.notoriety_lv }))

		-- 별 추가
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.add_star, self, self.notoriety_lv))

		-- 경찰 생성
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_police, self))
	end

	self.is_detected_by_police = false

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 에리나 쓰러트린 경우의 연출
function local_class:defeat_erina()
	wait_for_sec(1)

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	for i = 0, user_party.Count - 1 do
		character_util.look_at(user_party[i], self.erina)
	end

	camera_util.move_async(self.erina.Position, 1)

	character_util.shake(self.erina, 0.04, 2)

	party_util.align_party(self.erina.Position, 'down',  1, 'arc')

	wait_for_sec(1)

	camera_util.shake(0.2, 0.5)

	unity_object_pool.GetOrCreate(self.explosion_effect_preset):Instantiate(self.erina.Position)

	character_util.set_active_state(self.erina, 'disabled')

	wait_for_sec(2)

	local cur_time = unity_class.time.time
	local fall_duration = 3

	local start_pos = self.erina.Position + vector(0, 10, 0)
	local end_pos = self.erina.Position + vector(0, 1, 0)

	local free_fall = CS.CalculatorFreeFall(fall_duration, 9, 0)

	local fairy = get_character(self.fairy_glitch_name)
	character_util.set_position(fairy, start_pos, true)
	character_util.set_direction(fairy, 'down')

	while unity_class.time.time - cur_time < fall_duration do
		free_fall:Proceed(unity_class.time.deltaTime)
		local dist_y = free_fall:GetDistance()

		character_util.set_position(fairy, start_pos + vector(0, dist_y, 0), true)

		coroutine.yield(nil)
	end

	character_util.set_position(fairy, end_pos)

	wait_for_sec(1)

	camera_util.shake(0.3, 0.5)

	character_util.normal_double_jump(fairy)
	character_util.set_anim(fairy, { name = 'embarrassed' })
	character_util.set_emotion(fairy, { name = 'damaged' })

	speech_bubble_util.show_speech_bubble_async(
			fairy, { key = 'demonworld_part1_police_5', bubble_type = 'shout', skip = true })

	character_util.set_anim(fairy, { name = 'attack' })
	character_util.set_emotion(fairy, { name = 'mad' })

	speech_bubble_util.show_speech_bubble_async(fairy, { key = 'demonworld_part1_police_6', skip = true })

	camera_util.move(fairy.Position + vector(0, 0, 3), 3)

	character_util.remove_anim(fairy)
	character_util.remove_emotion(fairy)

	wait_for_sec(0.5)

	screen_util.fade_out_async(2.5, unity_class.color.white, 'linear')

	stage_camera:SetTarget(user_party_leader)

	-- 악명 초기화
	self.notoriety_lv = 0
	self.current_notoriety = 0

	for i = 0, 4 do
		self.notoriety_ui_star_list[i].TintColor = unity_color({ 0, 0, 0, 1 })
		self.notoriety_ui_star_list[i]:Rebuild(true)
	end

	self.notoriety_ui_gauge_bar.fillAmount = math.min(self.current_notoriety / self.notoriety_ui_gauge_max, 1)
	self.notoriety_ui_gauge_bar_label.text = tostring(math.floor(self.current_notoriety))

	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			user_party_leader, { self.notoriety_lv_custom_event_name..self.notoriety_lv }))

	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			user_party_leader, { self.notoriety_lv_save, self.notoriety_lv }))

	message_system:Publish(CS.Oak.CustomStageEvent.Create(
			user_party_leader, { self.notoriety_num_save, self.current_notoriety }))

	-- NPC와 적 초기화
	character_util.set_position(fairy, vector(999, 0, 999))
	character_util.remove_anim(fairy)
	character_util.remove_emotion(fairy)

	for i = 1, #self.police_table_1 do
		self:initialize_monster(self.police_table_1[i].character)

		self.police_table_1[i].state = self.police_state.idle
	end

	for i = 1, #self.police_table_2 do
		self:initialize_monster(self.police_table_2[i].character)

		self.police_table_2[i].state = self.police_state.idle
	end

	for i = 1, #self.police_table_3 do
		self:initialize_monster(self.police_table_3[i].character)

		self.police_table_3[i].state = self.police_state.idle
	end

	for i = 1, #self.police_table_4 do
		self:initialize_monster(self.police_table_4[i].character)

		self.police_table_4[i].state = self.police_state.idle
	end

	for i = 1, #self.police_table_5 do
		self:initialize_monster(self.police_table_5[i].character)

		self.police_table_5[i].state = self.police_state.idle
	end

	-- 플레이어 초기화
	party_util.align_party(self.player_saved_pos + CS.Oak.DirectionExtensions.ToVector3(self.player_saved_dir),
			self.player_saved_dir, 0, 'arc')

	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.white, 'linear')

	self.is_detected_by_police = false

	field_ui_manager:Show()
	party_util.reset_controllers()
end

-- 적 초기화
function local_class:initialize_monster(fo)
	character_util.convert_to_npc(fo)

	character_util.set_active_state(fo, 'enabled')
	character_util.set_position(fo, vector(999, 0, 999))
	character_util.remove_anim(fo)
	character_util.remove_emotion(fo)
	fo.SpineController:Rotate(0, 0)

	-- 힐로 HP 초기화
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = nil
	heal_info.target = fo
	heal_info.heal = fo.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true

	command_util.execute_heal(heal_info)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
