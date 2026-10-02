local local_class = newclass("AfterWorld1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.get_charon_storage = function() return get_field_object('charon_storage') end

	self.get_boatman_square = function() return get_character('boatman_square') end
	self.get_boatman_office = function() return get_character('boatman_office') end
	self.get_boatman_marina = function() return get_character('boatman_marina') end
	self.get_boatman_anteroom = function() return get_character('boatman_anteroom') end
	self.get_boatman_garbage = function() return get_character('boatman_garbage') end

	self.boatmans = {}
	self.boatman_to_grid_dict = {}

	self.square_boatman_interacted = false

	self.using_boat = false

	self.entered_area_data_key = 0

	--(노란색)카론의 사무실
	--(노란색)오리배 선착장
	--(노란색)안내원 대기실
	--(노란색)쓰레기장
	self.area_enter_infos = {
		['office_area'] = {
			bit_exponent = 0,
			destination_str_key = 'aw_stage3_boat_branch_1',
			destination_marker_key = 'boat_office_destination',
			tendency = 'intellect',
			get_boatman = self.get_boatman_office,
			listener_added = false,
			entered = false,
		},
		['garbage_area'] = {
			bit_exponent = 1,
			destination_str_key = 'aw_stage3_boat_branch_2',
			destination_marker_key = 'boat_garbage_destination',
			tendency = 'intellect',
			get_boatman = self.get_boatman_garbage,
			listener_added = false,
			entered = false,
		},
		['marina_area'] = {
			bit_exponent = 2,
			destination_str_key = 'aw_stage3_boat_branch_3',
			destination_marker_key = 'boat_marina_destination',
			tendency = 'intellect',
			get_boatman = self.get_boatman_marina,
			listener_added = false,
			entered = false,
		},
		['anteroom_area'] = {
			bit_exponent = 3,
			destination_str_key = 'aw_stage3_boat_branch_4',
			destination_marker_key = 'boat_anteroom_destination',
			tendency = 'intellect',
			get_boatman = self.get_boatman_anteroom,
			listener_added = false,
			entered = false,
		},
		['square'] = {
			bit_exponent = 4,
			destination_str_key = 'aw_stage3_boat_branch_5',
			destination_marker_key = 'boat_square_destination',
			tendency = 'intellect',
			get_boatman = self.get_boatman_square,
			listener_added = false,
			entered = false,
		}
	}

	--region 잡입 / 감시

	self.get_sneak_npc = function(area, num) return get_character('sneak_npc_' .. area .. '_'.. num) end
	self.get_sneak_guard = function(area, num) return get_character('sneak_guard_' .. area .. '_'.. num) end

	self.sneak_npcs_info = {
		{	-- 섹션 12에서만 사용
			{
				wp = {
					1, 3, 7, 5
				},
				speed = 1.9,
			},
			{
				wp = {
					2, 4, 8, 6
				},
				speed = 2.3,
			},
			{
				wp = {
					3, 2, 6, 7
				},
				speed = 1.7
			},
			{
				wp = {
					4, 1, 5, 8
				},
				speed = 2.5
			}
		},
		--region 좌측
		{
			-- 좌측하단
			{
				wp = {
					1, 3, 7, 5
				},
				speed = 2.3,
			},
			{
				wp = {
					8, 6, 2, 4
				},
				speed = 1.7,
			},
			{
				wp = {
					4, 1, 5, 8
				},
				speed = 2.6,
			},
			{
				wp = {
					6, 7, 3, 2
				},
				speed = 1.5
			},
			-- 좌측 상단
			{
				wp = {
					13, 15, 11, 9,
				},
				speed = 2,
			},
			{
				wp = {
					12, 10, 14, 16
				},
				speed = 1.7,
			},
			{
				wp = {
					11, 10, 14, 15
				},
				speed = 2.7,
			},
			{
				wp = {
					13, 16, 12, 9
				},
				speed = 2.3
			},
			--좌측 전체
			{
				wp = {
					13, 14, 2, 1,
				},
				speed = 2.5,
			},
			{
				wp = {
					4, 3, 15, 16
				},
				speed = 2.9,
			},
			{
				wp = {
					3, 1, 13, 15
				},
				speed = 3.1,
			},
			{
				wp = {
					14, 16, 4, 2
				},
				speed = 3.3
			}
		},
		--endregion

		--region 상단
		{
			-- 상단 좌측
			{
				wp = {
					1, 3, 7, 5
				},
				speed = 2.5,
			},
			{
				wp = {
					8, 6, 2, 4
				},
				speed = 1.9,
			},
			{
				wp = {
					4, 1, 5, 8
				},
				speed = 2.1,
			},
			{
				wp = {
					6, 7, 3, 2
				},
				speed = 1.6
			},
			--상단 우측
			{
				wp = {
					13, 15, 11, 9,
				},
				speed = 1.6,
			},
			{
				wp = {
					12, 10, 14, 16
				},
				speed = 2.3,
			},
			{
				wp = {
					11, 10, 14, 15
				},
				speed = 2.7,
			},
			{
				wp = {
					13, 16, 12, 9
				},
				speed = 1.9
			},
			--상단 전체
			{
				wp = {
					13, 14, 2, 1,
				},
				speed = 3,
			},
			{
				wp = {
					4, 3, 15, 16
				},
				speed = 2.4,
			},
			{
				wp = {
					3, 1, 13, 15
				},
				speed = 2.7,
			},
			{
				wp = {
					14, 16, 4, 2
				},
				speed = 3.1
			}
		},
		--endregion

		--region 우측
		{	-- 우측하단
			{
				wp = {
					1, 3, 7, 5
				},
				speed = 2,
			},
			{
				wp = {
					8, 6, 2, 4
				},
				speed = 1.7,
			},
			{
				wp = {
					4, 1, 5, 8
				},
				speed = 2.4,
			},
			{
				wp = {
					6, 7, 3, 2
				},
				speed = 1.9
			},
			--우측 상단
			{
				wp = {
					13, 15, 11, 9,
				},
				speed = 1.8,
			},
			{
				wp = {
					12, 10, 14, 16
				},
				speed = 2,
			},
			{
				wp = {
					11, 10, 14, 15
				},
				speed = 2.4,
			},
			{
				wp = {
					13, 16, 12, 9
				},
				speed = 1.6
			},
			--우측 전체
			{
				wp = {
					13, 14, 2, 1,
				},
				speed = 2.2,
			},
			{
				wp = {
					4, 3, 15, 16
				},
				speed = 3,
			},
			{
				wp = {
					3, 1, 13, 15
				},
				speed = 2.5,
			},
			{
				wp = {
					14, 16, 4, 2
				},
				speed = 2
			}
		},
		--endregion
	}

	self.sneak_guards_info = {
		{
			{
				reset_index = 1,
			},
			{
				reset_index = 1,
			},
		},
		{
			{
				reset_index = 2,
			},
			{
				reset_index = 2,
			},
			{
				reset_index = 2,
			},
			{
				reset_index = 2,
			},
		},
		{
			{
				reset_index = 3,
			},
			{
				reset_index = 3,
			},
			{
				reset_index = 3,
			},
			{
				reset_index = 3,
			},
			{
				reset_index = 3,
				range = 3,
				angle = 60,
			},
			{
				reset_index = 3,
				range = 3,
				angle = 60,
			},
		},
		{
			{
				reset_index = 4,
			},
			{
				reset_index = 4,
			},
			{
				reset_index = 4,
			},
			{
				reset_index = 4,
			},
		},
	}

	self.sneak_detect_key = 'sneak_detected'
	self.is_sneak_detected = false

	self.sneak_in_square = false
	self.sneak_guards_dict = {}
	self.sneak_check_sqr_dist = 1.5 * 1.5
	self.sneak_check_grid_name = 'square'

	self.sneak_check_routine_on = false

	self.sneak_non_targeting = false

	self.evidence_controller = nil

	--endregion

	self.res_holder = nil
	self.bg_corporation = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_sneak_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.evidence_controller = get_or_create_global_table('Theatres/AfterWorldEvidence')

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	if quest_progress ~= nil and quest_progress.IsComplete == false
			and quest_progress.InnerProgress <= 13 then
		self.evidence_controller:pre_load_async()
	end

	-- 리소스 홀더 백그라운드 로드
	self.res_holder = CS.Foundations.ResourceHolder()

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			self.res_holder, 'ondemand/afterworld/tilesets', 'bg_aw_corporation', function(prefab)
				self.bg_corporation = CS.UnityEngine.GameObject.Instantiate(prefab)
			end)

	self.bg_corporation.transform.localPosition = get_field_object('stage_exit').Position + vector(0, 0, 9)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.opening_routine, self))
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	if is_unity_null(self.bg_corporation) == false then
		CS.UnityEngine.GameObject.Destroy(self.bg_corporation)
	end
	self.bg_corporation = nil

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end
	self.res_holder = nil

	if self.storage_loop_sfx ~= nil then
		self.storage_loop_sfx:Stop()
	end
	self.storage_loop_sfx = nil

	if self.computer_loop_sfx ~= nil then
		self.computer_loop_sfx:Stop()
	end
	self.computer_loop_sfx = nil

	for boatman, _ in pairs(self.boatman_to_grid_dict) do
		character_util.remove_relate_event(boatman, self)
	end
	self.evidence_controller = nil
	self.boatman_to_grid_dict = nil
	self.sneak_guards_dict = nil
	self.cs_controller = nil
end

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, typeof(CS.Oak.InteractEvent)) then
		if self.boatman_to_grid_dict[e.Target] ~= nil and self.using_boat == false then
			self.using_boat = true
			self.evidence_controller:play_normal_screenplay(self.interact_boatman, self, e.Target)
			return true
		end
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_party_leader())
			or lua_helper.reference_equals(e.FieldObject, user_party) then
		-- 스트링 GC 방지를 위해 리더가 들어간 경우 먼저 체크함
		local grid_name = e.CameraGrid.name
		local info = self.area_enter_infos[grid_name]
		if info ~= nil and info.entered == false then
			self:set_area_entered(grid_name)
		end

		if grid_name == self.sneak_check_grid_name
				and self.sneak_in_square == false then
			self.sneak_in_square = true

			if self.sneak_non_targeting == false and self.sneak_check_routine_on == false then
				self.sneak_check_routine_on = true
				coroutine_manager:StartCoroutine(stage.StageGameObject,
						util.cs_generator(self.sneak_check_crash_routine, self))
				return true
			end
		end
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_party_leader())
			or lua_helper.reference_equals(e.FieldObject, user_party) then
		if e.CameraGrid.name == self.sneak_check_grid_name then
			self.sneak_in_square = false
		end
	end

	return false
end

--endregion

function local_class:opening_routine()
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	local start_infos = {
		{
			progress = 11,
		},
		{
			progress = 12,
			main_in_party = true,
			start_marker = 'default_start'
		},
		{
			progress = 13,
			main_in_party = true,
		},
		{
			progress = 14,
			start_marker = 'default_start',
			main_in_party = true,
		},
	}

	character_util.set_rolling_number(get_party_leader().Transform,
			999999999, nil, 0, unity_class.color.red)

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #start_infos do
			if quest_progress.InnerProgress == start_infos[i].progress then
				if start_infos[i].main_in_party then
					local main_character = get_character('main_character')
					character_util.convert_to_party_member(main_character, user_party, true)
				end

				if start_infos[i].start_marker then
					if start_infos[i].progress == 14 then
						local tao = get_character('tao')
						tao.ActiveState = active_state('enabled')
						character_util.convert_to_party_member(tao, user_party, true)

						local marty = get_character('marty')
						marty.ActiveState = active_state('enabled')
						character_util.convert_to_party_member(marty, user_party, true)

						local aggro_girl = get_character('aggro_girl')
						aggro_girl.ActiveState = active_state('enabled')
						character_util.convert_to_party_member(aggro_girl, user_party, true)
					end

					local marker = field:GetMarker(start_infos[i].start_marker)

					party_util.position_party(marker.position, marker.direction, 'linear')
					coroutine.yield()
					screen_util.fade_in(0, unity_class.color.black, 'linear')
					screen_util.fade_in_circular(1, 'linear')

					yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, marker.position, marker.direction,
							game_string:GetString(stage.Name))
				end

				message_system:Publish(CS.Oak.StageStartEvent.Instance)
				message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

				return
			end
		end
	end

	local main_character = get_character('main_character')
	character_util.convert_to_party_member(main_character, user_party, true)

	local marker = field:GetMarker('default_start')

	party_util.position_party(marker.position, marker.direction, 'linear')
	coroutine.yield()
	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular(1, 'linear')

	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, marker.position, marker.direction,
			game_string:GetString(stage.Name))

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:on_stage_loaded(_)
	self:set_sneak()

	-- 방문했던 곳 정보 가져옴
	local bits = self:get_area_entered_bits()

	for grid_name, _ in pairs(self.area_enter_infos) do
		local info = self.area_enter_infos[grid_name]
		local boatman = info.get_boatman()

		self.boatman_to_grid_dict[boatman] = grid_name

		-- 열린 목적지들 플래그 저장
		info.entered = (bits & (1 << info.bit_exponent)) ~= 0

		boatman.Interactable.Talk = 'aw_stage3_boat_1'

		if info.entered then
			for other_grid_name, _ in pairs(self.area_enter_infos) do
				local other_grid_info = self.area_enter_infos[other_grid_name]
				if other_grid_name ~= grid_name and other_grid_info.listener_added == false then
					other_grid_info.listener_added = true
					character_util.add_listener(other_grid_info.get_boatman(), self.cs_controller)
				end
			end
		end
	end

	-- 카론의 저장고만 비어있도록 세팅
	local charon_storage = self.get_charon_storage()
	charon_storage.Transform:Find('mesh').gameObject:SetActive(false)
	self.storage_loop_sfx = music_player_util.play_sfx({
		sfx_name = '01_event_dw_11', loop = true, play_pos = charon_storage.Position + vector(-1, 0, 0),
		type_priority = 'loop', player_priority = 'default'
	})

	self.computer_loop_sfx = music_player_util.play_sfx({
		sfx_name = '01_amb_computer_01', loop = true, play_pos = field:GetMarker('s13_office_clue_interact').position,
		type_priority = 'loop', player_priority = 'default'
	})

	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)
	if quest_progress ~= nil and quest_progress.InnerProgress < 15 and not quest_progress.IsComplete then
		get_field_object('stage_exit').ActiveState = active_state('disabled')
	end

	local office_houses = {
		get_field_object('office_house_ct'),
		get_field_object('office_house_rb'),
	}

	-- 문이 달려있는 집 오브젝트들은 문 열린 상태로 바꿔줌
	for _, house in pairs(office_houses) do
		local mesh_tf = house.Transform:Find('mesh')
		mesh_tf:Find('close').gameObject:SetActive(false)
		mesh_tf:Find('open').gameObject:SetActive(true)
	end

	return true
end

-- 해당 구역에 방문했음을 저장
function local_class:set_area_entered(grid_name)
	local info = self.area_enter_infos[grid_name]
	local bits = self:get_area_entered_bits()

	info.entered = true

	--다른애들 돌면서 InteractEvent 구독 처리 안한거 확인해봄
	--bits가 0일때와 2의 거듭제곱 형태일 때의 경우를 나누는 방법도 고려해봐야 할 듯
	for key, _ in pairs(self.area_enter_infos) do
		local area_info = self.area_enter_infos[key]
		if grid_name ~= key and area_info.listener_added == false then
			area_info.listener_added = true
			character_util.add_listener(area_info.get_boatman(), self.cs_controller)
		end
	end

	stage_progress_util.set_custom_data(self.entered_area_data_key, bits | (1 << info.bit_exponent))
end

function local_class:get_area_entered_bits()
	return stage_progress_util.get_custom_data_int(self.entered_area_data_key, 0)
end

function local_class:interact_boatman(boatman)
	party_util.align_to_target(boatman, boatman.Direction, 1, 'linear')

	local destination_marker

	--중앙 광장에서 뱃사공과 첫 인터랙트 시
	if self.square_boatman_interacted == false then
		self.square_boatman_interacted = true
		--뱃사공 : 한 번 방문한 곳은 어디든 모셔다드립니다.
		speech_bubble_util.show_speech_bubble_async(boatman,
				{key = 'aw_stage3_boat_1', skip = true})
	end

	--뱃사공 : 탑승하시겠습니까?
	speech_bubble_util.show_speech_bubble_async(boatman, {key = 'aw_stage3_boat_2', skip = true})

	--(초록색)예
	--(빨간색)아니오
	local result = choose_util.play_choose_event({
		{'aw_stage3_boat_5', 'mercy'},
		{'aw_stage3_boat_6', 'brutal'}
	})

	if result == 1 then
		--뱃사공 : 어디로 가시겠습니까?
		speech_bubble_util.show_speech_bubble_async(boatman,
				{key = 'aw_stage3_boat_3', skip = true})

		--(노란색)카론의 사무실
		--(노란색)오리배 선착장
		--(노란색)안내원 대기실
		--(노란색)쓰레기장
		--(노란색)중앙 광장
		local talk_branches = {}
		for grid_name, info in pairs(self.area_enter_infos) do
			if self.boatman_to_grid_dict[boatman] ~= grid_name and info.entered then
				table.insert(talk_branches, {info.destination_str_key, info.tendency, function()
					destination_marker = field:GetMarker(info.destination_marker_key)
				end})
			end
		end

		table.insert(talk_branches, {'aw_stage3_boat_branch_6', 'normal'})

		choose_util.play_choose_event(talk_branches)
	end

	if destination_marker ~= nil then
		music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
		screen_util.fade_out_circular_async(0.6, 'linear')

		party_util.position_party(destination_marker.position, destination_marker.direction, 'linear')
		coroutine.yield()

		screen_util.fade_in_circular_async(0.6, 'linear')
	end

	self.using_boat = false
end

--region 잠입 / 감시 시스템

function local_class:set_sneak()
	local afterworld_main_quest_id = 60049
	local quest_progress = user_progress:GetStartedQuest(afterworld_main_quest_id)

	if quest_progress ~= nil and (quest_progress.IsComplete or quest_progress.InnerProgress >= 14) then
		self.sneak_non_targeting = true
	end

	self.using_areas = nil
	local screen_size = screen_util.get_world_screen_size() / 2
	self.screen_size = vector(screen_size.x + 3, screen_size.y + 3)

	if quest_progress ~= nil and (quest_progress.IsComplete or quest_progress.InnerProgress >= 12) then
		self.using_areas = {
			2, 3, 4
		}
	else
		self.using_areas = {
			1, 2, 3, 4
		}
	end

	self.check_npcs = {}

	for _, area_index in pairs(self.using_areas) do
		local npc_infos = self.sneak_npcs_info[area_index]

		for npc_index, npc_info in pairs(npc_infos) do
			local npc = self.get_sneak_npc(area_index, npc_index)
			local waypoints = {}

			npc.EntityGroup = CS.Oak.EntityGroups.Obstacle
			npc.Position = self:get_sneak_marker_pos(area_index .. '_npc' .. npc_index .. '_start')
			npc.ActiveState = CS.Oak.ActiveState.Enabled
			npc.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
			npc.Hitbox = CS.Oak.Hitbox(vector(1.2, 1, 1.2))

			for _, wp_index in pairs(npc_info.wp) do
				table.insert(waypoints, self:get_sneak_marker_pos(
						area_index .. '_' .. wp_index))
			end

			wp_util.move_way_points(npc, {waypoints = waypoints, speed = npc_info.speed, end_type = 'loop'})
			table.insert(self.check_npcs, npc)
		end

		local guard_infos = self.sneak_guards_info[area_index]

		for guard_index, guard_info in pairs(guard_infos) do
			local guard = self.get_sneak_guard(area_index, guard_index)

			guard.ActiveState = CS.Oak.ActiveState.Enabled

			if self.sneak_non_targeting == false then
				-- 어차피 정지해있는 애들이니까 모든 데이터를 가지고 있도록 세팅
				self.sneak_guards_dict[guard] = {
					pos = guard.Position,
					bounds = guard.Bounds,
					reset_marker = field:GetMarker('sneak_reset_' .. guard_info.reset_index)
				}

				guard.FieldObjectController = CS.Oak.WayPointGuardCharacterController.Create(guard,
						self.sneak_detect_key, guard_info.range or 5.5, guard_info.angle or 45, false, false)

				guard.OverrideCrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
			end
		end
	end
end

function local_class:on_sneak_custom_stage_event(e)
	if e.Params[0] == 'sneak' then
		if e.Params[1] == 'disable_area_1' then
			self:disable_area(1)
			return true
		elseif e.Params[1] == 'after_agora' and self.sneak_non_targeting == false then
			self.sneak_non_targeting = true
			self:set_non_targeting()
			return true
		end
	elseif e.Params[0] == self.sneak_detect_key and self.is_sneak_detected == false then
		self.is_sneak_detected = true
		self.evidence_controller:play_normal_screenplay(self.sneak_detected, self, e.Sender)

		return true
	end

	return false
end

function local_class:disable_area(area_index)
	for npc_index, _ in pairs(self.sneak_npcs_info[area_index]) do
		local npc = self.get_sneak_npc(area_index, npc_index)
		character_util.stop(npc)
		npc.ActiveState = CS.Oak.ActiveState.Disabled

		for i = 1, #self.check_npcs do
			if lua_helper.reference_equals(npc, self.check_npcs[i]) then
				table.remove(self.check_npcs, i)
				break
			end
		end
	end

	for guard_index, _ in pairs(self.sneak_guards_info[area_index]) do
		local guard = self.get_sneak_guard(area_index, guard_index)

		character_util.stop(guard)
		guard.ActiveState = CS.Oak.ActiveState.Disabled

		--현재 목록에서 비워줌
		self.sneak_guards_dict[guard] = nil
	end
end

function local_class:set_non_targeting()
	for area_index, guard_infos in pairs(self.sneak_guards_info) do
		for guard_index, guard_info in pairs(guard_infos) do
			local guard = self.get_sneak_guard(area_index, guard_index)
			character_util.stop(guard)
			guard.OverrideCrashBehaviour = nil
		end
	end
end

function local_class:sneak_detected(guard)
	local leader = get_party_leader()
	if lua_helper.type_compare(leader.CharacterBehaviour.CurrentActionState, CS.Oak.CharacterHoldUpState) then
		local hold_target = leader.CharacterBehaviour.CurrentActionState.HoldTarget
		command_util.execute_throw(leader, hold_target, direction_util.to_vector3(leader.Direction),
				leader.Position, 3, false)
	end

	music_player_util.play_sfx_one_shot('03_runaway_01')
	party_util.look_at(guard)
	party_util.set_anim({name = 'embarrassed'})
	party_util.set_emotion({name = 'scared'})

	local guard_origin_dir = guard.Direction
	character_util.look_at(guard, get_party_leader())

	character_util.set_emotion(guard, {name = 'attack'})
	character_util.set_anim(guard, {name = 'release', sfx_name = '01_swing_01'})

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	music_player_util.play_sfx_one_shot('01_whistle_01')

	speech_bubble_util.show_speech_bubble_async(guard, {key = 'aw_stage3_sneak_detected', skip = true})

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	party_util.remove_emotion()
	party_util.remove_animation()

	local reset_marker = self.sneak_guards_dict[guard].reset_marker

	guard.Direction = guard_origin_dir

	party_util.position_party(reset_marker.position, reset_marker.direction, 'linear')

	character_util.remove_anim_and_emotion(guard)

	coroutine.yield()

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	self.is_sneak_detected = false
end

function local_class:sneak_check_crash_routine()
	local leader = get_party_leader()

	while self.sneak_in_square and self.sneak_non_targeting == false do
		if self.is_sneak_detected == false then
			local leader_pos = leader.Position
			for guard, info in pairs(self.sneak_guards_dict) do
				if (info.pos - leader_pos).sqrMagnitude < self.sneak_check_sqr_dist then
					if self:aabb(info.bounds, leader.Bounds) then
						self.is_sneak_detected = true
						sp_util.play_normal_screenplay(self.sneak_detected, self, guard)
						break
					end
				end
			end
		end

		coroutine.yield()
	end

	self.sneak_check_routine_on = false
end

function local_class:aabb(a, b)
	return a.min.x <= b.max.x and a.max.x >= b.min.x
			and a.min.z <= b.max.z and a.max.z >= b.min.z
end

function local_class:get_sneak_marker_pos(name)
	return field:GetMarker('sneak_' .. name).position
end

--endregion

-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return true
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.using_areas ~= nil then
		local count = #self.check_npcs
		for i = 1, count do
			local npc = self.check_npcs[i]
			if not self:is_in_screen(npc.Position) then
				npc.ActiveState = CS.Oak.ActiveState.Visible
			else
				npc.ActiveState = CS.Oak.ActiveState.Enabled
			end
		end
	end
end

function local_class:is_in_screen(pos)
	local center_pos = stage_camera.LookAtPosition
	local x_gap = math.abs(center_pos.x - pos.x)
	local y_gap = math.abs(center_pos.z - pos.z)

	if x_gap >= self.screen_size.x or y_gap >= self.screen_size.y then
		return false
	end

	return true
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
