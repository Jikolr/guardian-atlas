local local_class = newclass("DemonWorldCivilianController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

--region NPC
	-- 전체 NPC 정보를 저장하는 테이블
	self.npc_infos = {}

	-- NPC 이름
	self.npc_name = 'spawn_npc_'

	-- NPC 개수
	self.npc_num = 16

	-- NPC 생성 대기 시간
	self.npc_spawn_delay = 1

	-- 현재 화면에 보이는 주민 수
	self.cur_npc_on_camera_num = 0

	-- 화면에 보이는 최대 주민 수
	self.npc_on_camera_limit = 4

	-- NPC가 서로 겹쳤다고 인식하는 거리
	self.npc_distance_limit = 1

	-- NPC가 데미지 입은 뒤 원래대로 돌아가는 대기 시간
	self.damaged_delay = 3

	-- NPC가 WaitForLook 상태에서 대기하는 시간
	self.wait_for_look_delay = 3

	-- NPC가 카메라 바깥으로 나간 뒤, 제거될 때까지 기다리는 유예 거리
	self.out_of_camera_distance_limit = 20

	-- NPC가 플레이어가 근접했음을 인식하는 거리
	self.npc_notice_player_distance = 3

	-- NPC가 도망을 중지하는 플레이어와 NPC 사이의 거리
	self.stop_flee_distance = 7

	-- NPC 피격 대사 개수
	self.npc_damaged_talk_num = 2

	-- NPC AI 상태
	self.npc_ai_state = {
		idle = 0,
		move_waypoint = 1,
		stop_by_damaged = 2,
		flee = 3,
		wait_for_look = 4,
		comeback = 5,
		dead = 6
	}

	-- NPC 도망칠 때 선택할 Direction의 리스트
	self.npc_flee_direction_table = {}

	-- NPC가 방향을 지나치게 자주 바꾸는 것을 막기 위한 방향 유지 시간
	self.direction_change_time = 1.5
--endregion

--region NPC Spawn Marker
	-- NPC 생성 마커의 정보를 저장하는 테이블
	self.npc_spawn_markers = {}

	-- NPC 생성 마커 이름
	self.npc_spawn_marker_name = 'npc_spawn_'

	-- 한 마커에 연속 생성될 때까지 대기 시간
	self.npc_spawn_marker_delay = 3
--endregion

--region Coin
	-- NPC 드랍 골드 양 최소값
	self.npc_drop_coin_min = 100

	-- NPC 드랍 골드 양 최대값
	self.npc_drop_coin_max = 300
--endregion

	-- 플레이어 악명 레벨
	self.notoriety_lv = 0

	-- 스테이지 이름
	self.stage_2_name = 'demonworld_part1_1_2'
	self.stage_3_name = 'demonworld_part1_1_3'
	self.stage_4_name = 'demonworld_part1_1_4'

	-- 악명 레벨 커스텀 이벤트 이름
	self.notoriety_lv_custom_event_name_0 = 'notoriety_lv_0'
	self.notoriety_lv_custom_event_name_1 = 'notoriety_lv_2'
	self.notoriety_lv_custom_event_name_2 = 'notoriety_lv_3'

	-- 스테이지 종료 플래그
	-- (controller가 제거되면 코루틴도 꺼지겠지만,
	-- 문제를 미연에 방지하기 위해 controller Dispose할 때 이 값을 true로 하고 코루틴 중단한다)
	self.is_exit_stage = false

	-- 메인 퀘스트 번호
	self.main_quest_id = 216

	-- 커스텀 이벤트 이름
	self.coin_drop_event = 'coin_drop'

	-- 이펙트 프리셋 이름
	self.hit_effect_preset = "FX_hit"
	self.impact_hit_effect_preset = "FX_lasthit"
	self.explosion_effect_preset = 'FX_dead'
end

function local_class:load_resource()
	-- 2스테이지, 메인 퀘스트 진행 상황이 5 이하면 작동하지 않음
	local main_quest = user_progress:GetStartedQuest(self.main_quest_id)

	if stage.Name == self.stage_2_name and main_quest ~= nil and main_quest.InnerProgress < 6 then
		return
	end

	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	-- NPC 공격 가능한 Hittable 마스크 사용
	CS.Oak.EntityGroupsExtensions.HittableMask = CS.Oak.GuildCastleStage.HittableMask

	-- 각 스테이지 별로 NPC 생성 마커 수가 다르므로 개별 설정
	if stage.Name == self.stage_2_name then
		-- 마커 정보 테이블에 등록
		self.npc_spawn_markers[1] = {
			marker_num = 11,
			markers = {},
			loop = false,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[2] = {
			marker_num = 10,
			markers = {},
			loop = false,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[3] = {
			marker_num = 6,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[4] = {
			marker_num = 11,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[5] = {
			marker_num = 6,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[6] = {
			marker_num = 4,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[7] = {
			marker_num = 4,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[8] = {
			marker_num = 6,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[9] = {
			marker_num = 7,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[10] = {
			marker_num = 6,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[11] = {
			marker_num = 8,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[12] = {
			marker_num = 12,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[13] = {
			marker_num = 9,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[14] = {
			marker_num = 4,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[15] = {
			marker_num = 8,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[16] = {
			marker_num = 12,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		self.npc_spawn_markers[17] = {
			marker_num = 6,
			markers = {},
			loop = true,
			current_npc_num = 0,
			npc_limit = {}
		}

		for i = 1, 17 do
			for n = 1, self.npc_spawn_markers[i].marker_num do
				table.insert(self.npc_spawn_markers[i].markers, field:GetMarker(self.npc_spawn_marker_name..i..'_'..n))

				table.insert(self.npc_spawn_markers[i].npc_limit, 0)
			end
		end
	end

	-- NPC Direction Table 설정
	self.npc_flee_direction_table = {}
	local size = 12
	local angle_step = math.pi * 2 / size

	for i = 1, size do
		table.insert(self.npc_flee_direction_table,
				unity_class.vector3(math.cos(angle_step * i), 0, math.sin(angle_step * i)))
	end

	-- NPC 생성 마커 수 정보가 없을 경우 NPC 스폰 루틴 실행하지 않음
	if self.npc_spawn_markers ~= nil and #self.npc_spawn_markers > 0 then
		-- NPC 정보 테이블에 등록
		for i = 1, self.npc_num do
			local cur_character = get_character(self.npc_name..i)
			cur_character.EntityGroup = CS.Oak.EntityGroups.Player1
			cur_character.DamagedBehaviour = CS.Oak.MonsterDamagedBehaviour.Create(CS.Oak.DeathType.None)

			self.npc_infos[i] = {
				character = cur_character,
				activated = false,
				ai_state = self.npc_ai_state.idle,
				damaged = false,
				out_of_camera = false,
				waypoints = {},
				spawn_marker_index = 0,
				wait_duration = 0,
			}
		end

		-- NPC 제어하는 루틴 실행
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.control_npc, self))
	end

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.npc_infos = nil
	self.npc_spawn_markers = nil

	self.is_exit_stage = true

	self.cs_controller = nil
end

function local_class:on_event(e)
	return false
end

function local_class:on_damage_event(e)
	for i = 1, #self.npc_infos do
		if lua_helper.reference_equals(e.Info.target, self.npc_infos[i].character) and
				e.Info.type ~= CS.Oak.DamageType.WallHit then
			-- 화면 밖에서 맞은 경우, 상태가 꼬일 수 있어서 처리하지 않음
			if not self.npc_infos[i].out_of_camera then
				-- 이미 Flee 상태라면 HPBar만 보여줌
				if self.npc_infos[i].ai_state == self.npc_ai_state.flee then
					message_system:Publish(CS.Oak.ShowCharacterHPBarEvent.Create(self.npc_infos[i].character))
				-- 악명 렙이 3 이상이면 NPC가 계속 flee 상태기 때문에 처리하지 않음
				elseif self.notoriety_lv < 3 then
					self:npc_convert_to_monster(i)
				end

				break
			end
		end
	end

	return false
end

function local_class:on_field_object_destroyed_event(e)
	for i = 1, #self.npc_infos do
		if lua_helper.reference_equals(e.FieldObject, self.npc_infos[i].character) then
			local dead_by_car = true

			for n = 0, user_party.Count - 1 do
				if lua_helper.reference_equals(e.Destroyer, user_party[n]) then
					dead_by_car = false

					break
				end
			end

			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.initialize_npc, self, self.npc_infos[i], true, dead_by_car))
		end
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == self.notoriety_lv_custom_event_name_1 then
			self.notoriety_lv = 2
		elseif e.Params[0] == self.notoriety_lv_custom_event_name_2 then
			self.notoriety_lv = 3
		elseif e.Params[0] == self.notoriety_lv_custom_event_name_0 then
			self.notoriety_lv = 0
		end
	end
end

-- NPC 제어 루틴
function local_class:control_npc()
	local timer = 0

	while not self.is_exit_stage do
		timer = timer + unity_class.time.deltaTime

		-- 카메라에 보이지 않는 것 체크를 위해 스테이지 카메라의 파라미터 받아옴
		local camera_pos = stage_camera.LookAtPosition

		-- 화면 밖으로 나간 NPC들을 조사해서 상태 변경 및 화면 안의 NPC 개수 확인
		local npc_in_camera = 0

		for i = 1, #self.npc_infos do
			if self.npc_infos[i].activated then
				-- 화면 밖으로 나가거나 들어온 NPC 컨트롤
				if self:is_pos_in_camera(self.npc_infos[i].character.Position) then
					npc_in_camera = npc_in_camera + 1

					-- 상태 변경되면 플래그 바꿔주고 유예 기간 초기화
					if self.npc_infos[i].out_of_camera then
						self.npc_infos[i].out_of_camera = false
					end
				else
					-- 상태 변경되면 플래그 바꿔줌
					if not self.npc_infos[i].out_of_camera then
						self.npc_infos[i].out_of_camera = true
					else
						local distance = (camera_pos - self.npc_infos[i].character.Position).magnitude

						-- 일정 거리 이상 멀어지면 NPC 제거 후 초기화 루틴 실행
						if distance >= self.out_of_camera_distance_limit then
							speech_bubble_util.remove_bubble(self.npc_infos[i].character)

							character_util.set_active_state(self.npc_infos[i].character, 'disabled')
							character_util.stop(self.npc_infos[i].character)
							character_util.remove_anim(self.npc_infos[i].character)
							character_util.remove_emotion(self.npc_infos[i].character)

							self.npc_spawn_markers[self.npc_infos[i].spawn_marker_index].current_npc_num =
								self.npc_spawn_markers[self.npc_infos[i].spawn_marker_index].current_npc_num - 1

							coroutine_manager:StartCoroutine(stage.StageGameObject,
									util.cs_generator(self.initialize_npc, self, self.npc_infos[i], false))
						end
					end
				end

				-- MoveWaypoint 상태에서 NPC State 변경
				if self.npc_infos[i].ai_state == self.npc_ai_state.move_waypoint then
					-- 플레이어의 악명 체크
					if self.notoriety_lv >= 2 then
						-- 플레이어가 일정 거리 이내로 들어온 경우
						if (user_party_leader.Position - self.npc_infos[i].character.Position).magnitude <
								self.npc_notice_player_distance then
							-- 악명 레벨 1이면 NPC가 플레이어를 보고 멈춰서서 벌벌 떤다
							if self.notoriety_lv == 2 then
								self.npc_infos[i].ai_state = self.npc_ai_state.wait_for_look
								self.npc_infos[i].wait_duration = self.wait_for_look_delay

								character_util.stop(self.npc_infos[i].character)
								character_util.look_at(self.npc_infos[i].character, user_party_leader)
								character_util.set_anim(self.npc_infos[i].character, { name = 'cast' })
								character_util.set_emotion(self.npc_infos[i].character, { name = 'tired' })
							-- 악명 레벨이 2 이상이면 NPC가 플레이어를 보고 도망친다
							else
								self.npc_infos[i].ai_state = self.npc_ai_state.flee

								local rand_string_key = math.floor(unity_class.random.Range(4, 6))
								speech_bubble_util.show_speech_bubble(self.npc_infos[i].character,
										{ key = 'demonworld_part1_civilian_'..rand_string_key })

								character_util.stop(self.npc_infos[i].character)
								character_util.set_anim(self.npc_infos[i].character, { name = 'run' })
								character_util.set_emotion(self.npc_infos[i].character, { name = 'damaged' })

								message_system:Send(self.npc_infos[i].character.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
										CS.Oak.CharacterAnalogueState.Create(self.npc_infos[i].character)))
							end
						end
					end
				-- Flee 상태에서 NPC State 변경 및 도망 실행
				elseif self.npc_infos[i].ai_state == self.npc_ai_state.flee then
					-- 플레이어가 일정 거리 밖으로 도망친 경우
					if (user_party_leader.Position - self.npc_infos[i].character.Position).magnitude >=
							self.stop_flee_distance then
						self.npc_infos[i].ai_state = self.npc_ai_state.wait_for_look
						self.npc_infos[i].wait_duration = self.wait_for_look_delay

						character_util.stop(self.npc_infos[i].character)
						character_util.look_at(self.npc_infos[i].character, user_party_leader)
						character_util.set_anim(self.npc_infos[i].character, { name = 'cast' })
						character_util.set_emotion(self.npc_infos[i].character, { name = 'scared' })
					else
						if not lua_helper.type_compare(self.npc_infos[i].character.FieldObjectBehaviour.CurrentState,
								typeof(CS.Oak.CharacterAnalogueState)) then
							message_system:Send(self.npc_infos[i].character.CharacterBehaviour,
									CS.Oak.StateChangeEvent.Create(
											CS.Oak.CharacterAnalogueState.Create(self.npc_infos[i].character)))
						end

						self:character_flee(self.npc_infos[i], user_party_leader)
					end
				-- WaitForLook 상태에서 NPC State 변경
				elseif self.npc_infos[i].ai_state == self.npc_ai_state.wait_for_look then
					character_util.look_at(self.npc_infos[i].character, user_party_leader)

					-- 플레이어가 일정 거리 이내로 들어온 경우
					if (user_party_leader.Position - self.npc_infos[i].character.Position).magnitude <
							self.npc_notice_player_distance then
						-- 공격받아서 도망치는 경우
						if self.npc_infos[i].damaged then
							self.npc_infos[i].ai_state = self.npc_ai_state.flee

							local rand_string_key = math.floor(unity_class.random.Range(4, 6))
							speech_bubble_util.show_speech_bubble(self.npc_infos[i].character,
									{ key = 'demonworld_part1_civilian_'..rand_string_key })

							character_util.stop(self.npc_infos[i].character)
							character_util.set_anim(self.npc_infos[i].character, { name = 'run' })
							character_util.set_emotion(self.npc_infos[i].character, { name = 'damaged' })

							message_system:Send(self.npc_infos[i].character.CharacterBehaviour,
									CS.Oak.StateChangeEvent.Create(
											CS.Oak.CharacterAnalogueState.Create(self.npc_infos[i].character)))
						else
							-- 플레이어의 악명 체크
							if self.notoriety_lv == 2 then
								self.npc_infos[i].wait_duration = self.wait_for_look_delay
							elseif self.notoriety_lv > 2 then
								self.npc_infos[i].ai_state = self.npc_ai_state.flee

								character_util.stop(self.npc_infos[i].character)
								character_util.set_anim(self.npc_infos[i].character, { name = 'run' })
								character_util.set_emotion(self.npc_infos[i].character, { name = 'damaged' })
							end
						end
					-- 플레이어가 일정 거리 밖에 있는 경우 타이머 감소하고 0되면 comeback 상태로 돌아감
					else
						self.npc_infos[i].wait_duration = self.npc_infos[i].wait_duration - unity_class.time.deltaTime

						if self.npc_infos[i].wait_duration <= 0 then
							self.npc_infos[i].wait_duration = 0

							coroutine_manager:StartCoroutine(stage.StageGameObject,
									util.cs_generator(self.wait_for_comeback, self, self.npc_infos[i]))
						end
					end
				-- Comeback 상태에서 NPC State 변경
				elseif self.npc_infos[i].ai_state == self.npc_ai_state.comeback then
					-- 플레이어가 일정 거리 이내로 들어온 경우
					if (user_party_leader.Position - self.npc_infos[i].character.Position).magnitude <
							self.npc_notice_player_distance then
						-- 플레이어의 악명 체크
						if self.notoriety_lv == 2 then
							self.npc_infos[i].ai_state = self.npc_ai_state.wait_for_look
							self.npc_infos[i].wait_duration = self.wait_for_look_delay

							character_util.stop(self.npc_infos[i].character)
							character_util.look_at(self.npc_infos[i].character, user_party_leader)
							character_util.set_anim(self.npc_infos[i].character, { name = 'cast' })
							character_util.set_emotion(self.npc_infos[i].character, { name = 'tired' })
						elseif self.notoriety_lv > 2 then
							self.npc_infos[i].ai_state = self.npc_ai_state.flee

							character_util.stop(self.npc_infos[i].character)
							character_util.set_anim(self.npc_infos[i].character, { name = 'run' })
							character_util.set_emotion(self.npc_infos[i].character, { name = 'damaged' })
						end
					end
				end
			end
		end

		-- 마커의 NPC 생성 카운터 감소
		for i = 1, #self.npc_spawn_markers do
			for j = 1, #self.npc_spawn_markers[i].npc_limit do
				if self.npc_spawn_markers[i].npc_limit[j] ~= 0 then
					self.npc_spawn_markers[i].npc_limit[j] =
						self.npc_spawn_markers[i].npc_limit[j] - unity_class.time.deltaTime

					if self.npc_spawn_markers[i].npc_limit[j] < 0 then
						self.npc_spawn_markers[i].npc_limit[j] = 0
					end
				end
			end
		end

		-- 일정 시간마다 화면 밖에서 NPC를 생성함
		if timer >= self.npc_spawn_delay then
			-- 타이머 초기화
			timer = 0

			-- 화면에 한계 이상의 NPC가 보이는 경우 넘어감
			if npc_in_camera < self.npc_on_camera_limit then
				-- 먼저 카메라와 가장 가까우면서 화면에 보이지 않는 NPC 생성 마커를 찾는다
				local shortest_dist = 9999
				local selected_marker = nil

				-- 마커 인덱스 값과 생성 마커 개수를 알아야 경로 설정이 가능
				local marker_table_num = 0
				local cur_marker_waypoint_index = 0

				for i = 1, #self.npc_spawn_markers do
					for j = 1, self.npc_spawn_markers[i].marker_num do
						local cur_marker = self.npc_spawn_markers[i].markers[j]

						-- 카메라에 보이거나 마커의 기본 NPC 생성 리미트가 0이 되서 해제되지 않은 상태라면 넘어감
						if not self:is_pos_in_camera(cur_marker.position) and
								self.npc_spawn_markers[i].npc_limit[j] <= 0 then
							-- 마커와 카메라 거리 측정 후 이전 최단 거리와 비교
							local cur_dist = math.abs((camera_pos - cur_marker.position).magnitude)

							if shortest_dist > cur_dist then
								selected_marker = cur_marker
								shortest_dist = cur_dist

								marker_table_num = i
								cur_marker_waypoint_index = j
							end
						end
					end
				end

				-- 선택된 마커 값이 nil이면 넘어간다
				if selected_marker ~= nil then
					-- 카메라에 보이지 않으면서 카메라와 최단 거리의 마커에 NPC 생성
					for i = 1, #self.npc_infos do
						local cur_npc_info = self.npc_infos[i]

						-- 비활성화 된 NPC 중에서 생성
						if not cur_npc_info.activated then
							cur_npc_info.activated = true
							cur_npc_info.ai_state = self.npc_ai_state.move_waypoint
							cur_npc_info.spawn_marker_index = marker_table_num

							character_util.set_active_state(cur_npc_info.character, 'enabled')

							-- 주변에 다른 NPC가 있어서 겹치는 경우가 발생하지 않도록 체크해서 위치 변경
							local position_diff = unity_class.vector3.zero

							for j = 1, #self.npc_infos do
								if i ~ j then
									if (selected_marker.position - self.npc_infos[j].character.Position).magnitude <
											self.npc_distance_limit then
										position_diff = CS.Oak.DirectionExtensions.ToVector3(selected_marker.direction)

										break
									end
								end
							end

							character_util.set_position(
									cur_npc_info.character, selected_marker.position + position_diff)
							character_util.set_direction(cur_npc_info.character, selected_marker.direction)

							self.npc_spawn_markers[marker_table_num].current_npc_num =
								self.npc_spawn_markers[marker_table_num].current_npc_num + 1
							self.npc_spawn_markers[marker_table_num].npc_limit[cur_marker_waypoint_index] =
								self.npc_spawn_marker_delay

							-- NPC가 경로를 이동하도록 설정
							local marker_waypoint_num = self.npc_spawn_markers[marker_table_num].marker_num
							cur_npc_info.waypoints = {}

							local move_end_index = 0

							for n = 1, marker_waypoint_num do
								table.insert(cur_npc_info.waypoints,
										self.npc_spawn_markers[marker_table_num].markers[cur_marker_waypoint_index].position)

								if self.npc_spawn_markers[marker_table_num].loop then
									if cur_marker_waypoint_index == marker_waypoint_num then
										cur_marker_waypoint_index = 1
									else
										cur_marker_waypoint_index = cur_marker_waypoint_index + 1
									end
								else
									if cur_marker_waypoint_index == marker_waypoint_num then
										break
									else
										cur_marker_waypoint_index = cur_marker_waypoint_index + 1
										move_end_index = move_end_index + 1
									end
								end
							end

							character_util.set_anim(cur_npc_info.character, { name = 'walk' })

							if self.npc_spawn_markers[marker_table_num].loop then
								character_util.move_waypoint(cur_npc_info.character, cur_npc_info.waypoints,
										cur_npc_info.character.CharacterStatsBehaviour.WalkSpeed, false,
										'loop', 'floor', CS.Oak.Direction.Down)
							else
								character_util.move_waypoint(cur_npc_info.character, cur_npc_info.waypoints,
										cur_npc_info.character.CharacterStatsBehaviour.WalkSpeed, false,
										'stop', 'floor', CS.Oak.Direction.Down, false, 0,
										function(index)
											if index == move_end_index then
												character_util.set_active_state(cur_npc_info.character, 'disabled')
												character_util.remove_anim(cur_npc_info.character)
												character_util.remove_emotion(cur_npc_info.character)

												self.npc_spawn_markers[cur_npc_info.spawn_marker_index].current_npc_num =
													self.npc_spawn_markers[cur_npc_info.spawn_marker_index].current_npc_num - 1

												coroutine_manager:StartCoroutine(stage.StageGameObject,
														util.cs_generator(self.initialize_npc, self, cur_npc_info, false))
											end
										end)
							end

							break
						end

						-- 전부 활성화 상태면 생성하지 않고 넘어감
					end
				end
			end
		end

		coroutine.yield(nil)
	end
end

-- 카메라에 해당 위치 좌표가 보이는지 리턴
function local_class:is_pos_in_camera(pos)
	local cam_half_height = stage_camera.Size
	local cam_half_width = stage_camera.HalfWidth
	local camera_pos = stage_camera.LookAtPosition

	if math.abs(camera_pos.x - pos.x) > cam_half_width + 0.7 or
			-- 카메라의 y값도 보정해서 계산
			math.abs(camera_pos.y / 1.414 + camera_pos.z - pos.z) > cam_half_height + 0.5 then
		return false
	end

	return true
end

-- NPC가 공격받으면 플레이어와 적대하는 이벤트
function local_class:npc_convert_to_monster(index)
	local cur_npc = self.npc_infos[index].character

	-- 이미 데미지 입어서 적대하는 NPC는 시간 초기화, 방향 변경, 이모션 표시만 진행한다
	character_util.look_at(cur_npc, user_party_leader)

	-- HP에 따라 상태 변경
	if cur_npc.FieldObjectStatsBehaviour.HP >= cur_npc.FieldObjectStatsBehaviour.MaxHP * 0.6 then
		self.npc_infos[index].ai_state = self.npc_ai_state.stop_by_damaged
		self.npc_infos[index].wait_duration = self.damaged_delay

		character_util.set_emotion(cur_npc, { name = 'damaged' })
		character_util.set_anim(cur_npc, { name = 'embarrassed' })
	elseif not cur_npc.FieldObjectStatsBehaviour.IsDead and cur_npc.FieldObjectStatsBehaviour.HP > 0 then
		self.npc_infos[index].ai_state = self.npc_ai_state.flee
		self.npc_infos[index].wait_duration = 0

		character_util.set_anim(cur_npc, { name = 'run' })
		character_util.set_emotion(cur_npc, { name = 'damaged' })

		message_system:Send(cur_npc.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
				CS.Oak.CharacterAnalogueState.Create(cur_npc)))
	end

	if not self.npc_infos[index].damaged then
		self.npc_infos[index].damaged = true

		-- ! 표시
		CS.Oak.NoticeIcon.SetBattleStart(cur_npc)

		-- 랜덤 대사 출력
		local cur_talk_num = math.floor(unity_class.random.Range(1, self.npc_damaged_talk_num + 1))
		speech_bubble_util.show_speech_bubble(cur_npc, { key = 'demonworld_part1_civilian_'..cur_talk_num })

		-- NPC의 HPBar를 보여줌
		message_system:Publish(CS.Oak.ShowCharacterHPBarEvent.Create(self.npc_infos[index].character))

		if self.npc_infos[index].ai_state == self.npc_ai_state.stop_by_damaged then
			character_util.stop(cur_npc)
			character_util.remove_anim(cur_npc)

			-- NPC 일정 시간 대기 후에 다시 이동 시작하는 루틴 실행
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.wait_for_comeback, self, self.npc_infos[index]))
		end
	end
end

-- NPC가 공격 받고 일정 시간 지나면 다시 NPC로 바뀐 뒤 원래 위치로 돌아가서 웨이포인트 이동을 진행하는 루틴
function local_class:wait_for_comeback(cur_npc_spec)
	local timer_finished = false

	-- NPC가 죽거나 비활성화 된 경우 루틴 종료
	while cur_npc_spec.activated and not cur_npc_spec.character.FieldObjectStatsBehaviour.IsDead do
		cur_npc_spec.wait_duration = cur_npc_spec.wait_duration - unity_class.time.deltaTime

		-- 시간이 전부 지난 경우 루틴 종료
		if cur_npc_spec.wait_duration <= 0 then
			timer_finished = true

			break
		-- NPC State가 Flee로 변경된 경우 루틴 종료
		elseif cur_npc_spec.ai_state == self.npc_ai_state.flee then
			break
		end

		coroutine.yield(nil)
	end

	-- NPC는 가장 가까운 웨이포인트로 복귀한다
	if timer_finished and cur_npc_spec.ai_state ~= self.npc_ai_state.flee then
		cur_npc_spec.damaged = false
		cur_npc_spec.ai_state = self.npc_ai_state.comeback

		-- NPC의 HPBar를 숨김
		message_system:Publish(CS.Oak.HideCharacterHPBarEvent.Create(cur_npc_spec.character))

		character_util.set_anim(cur_npc_spec.character, { name = 'walk' })
		character_util.remove_emotion(cur_npc_spec.character)

		-- 웨이포인트로 복귀하는 최단 경로 찾기
		local shortest_dist = 9999
		local target
		local shortest_index = 1

		local point = cur_npc_spec.character.Position

		for i = 1, #cur_npc_spec.waypoints do
			local origin = cur_npc_spec.waypoints[i]
			local cur_index = i + 1

			if i == #cur_npc_spec.waypoints then
				cur_index = 1
			end

			local next = cur_npc_spec.waypoints[cur_index]

			-- 웨이포인트 두 개를 이은 선분과 캐릭터의 위치 사이 최단거리를 구함
			local heading = (next - origin)
			local magnitude_max = heading.magnitude
			heading:Normalize()

			local lhs = point - origin
			local dot_p = unity_class.vector3.Dot(lhs, heading)
			dot_p = unity_class.mathf.Clamp(dot_p, 0, magnitude_max)

			-- 다른 선분과의 거리 비교하여 최단 거리면 저장한다
			local cur_target = origin + heading * dot_p
			local cur_dist = (cur_target - point).magnitude

			if cur_dist < shortest_dist then
				target = cur_target
				shortest_dist = cur_dist
				shortest_index = cur_index
			end
		end

		-- Path finder 사용해서 이동 경로 설정
		local current_planned_path
		local current_path_index = 0
		local plan_path_done = false

		if target ~= nil then
			field.PathFinder:FindNormalPath(
					cur_npc_spec.character, target, 100, cur_npc_spec.character, 0, nil, function(path, req_key)
						if req_key == 0 then
							plan_path_done = true

							if path ~= nil and path.Count > 0 then
								current_planned_path = create_generic_list(unity_class.vector3)

								for i = 1, path.Count - 1 do
									current_planned_path:Add(path[i])
								end
							end
						end
					end)

			-- Path finder 계산까지 대기, 도중에 공격받으면 취소
			while not plan_path_done and not cur_npc_spec.damaged do
				coroutine.yield(nil)
			end
		end

		-- 복귀
		if target ~= nil and current_planned_path ~= nil and current_planned_path.Count > 0 and
				not cur_npc_spec.damaged then

			message_system:Send(cur_npc_spec.character.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(
					CS.Oak.CharacterAnalogueState.Create(cur_npc_spec.character)))

			while not cur_npc_spec.damaged and cur_npc_spec.ai_state == self.npc_ai_state.comeback do
				-- 이번 프레임 이동 거리 계산
				local final_pos = cur_npc_spec.character.Position
				local movement = cur_npc_spec.character.CharacterStatsBehaviour.WalkSpeed * unity_class.time.deltaTime

				while movement > 0 and current_path_index < current_planned_path.Count do
					local diff = (current_planned_path[current_path_index] - final_pos):GetX0z()

					if float_util.is_almost_zero(diff.magnitude) then
						current_path_index = current_path_index + 1
					else
						if diff.magnitude < movement then
							movement = movement - diff.magnitude
							final_pos = current_planned_path[current_path_index]
							current_path_index = current_path_index + 1
						else
							final_pos = final_pos + diff.normalized * movement

							break
						end
					end
				end

				-- 방향 설정
				local final_diff = (final_pos - cur_npc_spec.character.Position):GetX0z()
				local dir = final_diff.normalized:ToDirection()

				if dir == CS.Oak.Direction.None then
					dir = cur_npc_spec.character.Direction
				end

				-- 최종 이동 요청
				if not float_util.is_almost_zero(final_diff.magnitude) then
					local move_info = CS.Oak.MoveOneFrameInfo()
					move_info.direction = final_diff.normalized
					move_info.magnitude = final_diff.magnitude

					local move_event = CS.Oak.AtomicMoveEvent.Create(move_info, dir, false)
					message_system:SendSync(cur_npc_spec.character, move_event)
				else
					break
				end

				coroutine.yield(nil)
			end

			-- 정상 완료된 경우
			if not cur_npc_spec.damaged and cur_npc_spec.ai_state == self.npc_ai_state.comeback then
				-- 웨이포인트 리셋
				local waypoints_num = #cur_npc_spec.waypoints
				local new_waypoints = {}
				local move_end_index = 0

				-- 플레이어 다시 원래 웨이포인트로 이동 시작
				for n = 1, waypoints_num do
					table.insert(new_waypoints, cur_npc_spec.waypoints[shortest_index])

					if self.npc_spawn_markers[cur_npc_spec.spawn_marker_index].loop then
						if shortest_index == waypoints_num then
							shortest_index = 1
						else
							shortest_index = shortest_index + 1
						end
					else
						if shortest_index == waypoints_num then
							break
						else
							shortest_index = shortest_index + 1
							move_end_index = move_end_index + 1
						end
					end
				end

				character_util.set_anim(cur_npc_spec.character, { name = 'walk' })

				if self.npc_spawn_markers[cur_npc_spec.spawn_marker_index].loop then
					character_util.move_waypoint(cur_npc_spec.character, new_waypoints,
							cur_npc_spec.character.CharacterStatsBehaviour.WalkSpeed, false,
							'loop', 'floor', CS.Oak.Direction.Down)
				else
					character_util.move_waypoint(cur_npc_spec.character, new_waypoints,
							cur_npc_spec.character.CharacterStatsBehaviour.WalkSpeed, false,
							'stop', 'floor', CS.Oak.Direction.Down, false, 0,
							function(index)
								if index == move_end_index then
									character_util.set_active_state(cur_npc_spec.character, 'disabled')
									character_util.remove_anim(cur_npc_spec.character)
									character_util.remove_emotion(cur_npc_spec.character)

									self.npc_spawn_markers[cur_npc_spec.spawn_marker_index].current_npc_num =
									self.npc_spawn_markers[cur_npc_spec.spawn_marker_index].current_npc_num - 1

									coroutine_manager:StartCoroutine(stage.StageGameObject,
											util.cs_generator(self.initialize_npc, self, cur_npc_spec, false))
								end
							end)
				end
			end
		end
	else
		-- 비정상적 종료 시 파라미터 초기화
		cur_npc_spec.wait_duration = 0
	end
end

-- NPC가 공격 받아서 일정 체력 이하로 내려가거나 플레이어가 악명이 높은 상태에서 접근하여 도망치고 있을 때, 위치 설정
function local_class:character_flee(cur_npc_info, target)
	-- Null Reference 예방
	if cur_npc_info == nil or cur_npc_info.character == nil or target == nil then
		return
	end

	-- 캐릭터가 타겟으로부터 멀어지는 방향
	local flee_from_dir = (target.Position - cur_npc_info.character.Position):GetX0z().normalized

	-- 선택된 방향, 방향 점수 최댓값
	local best_dir = unity_class.vector3.zero
	local best_score = 0

	-- 충돌 검사 거리
	local required_dist = 0
	local dist_to_check_collision = required_dist + 2

	-- 각 방향에 대해 점수 계산
	for i = 1, #self.npc_flee_direction_table do
		-- 이 방향으로 이동할 때 충돌하지 않고 이동할 수 있는 최대 거리
		-- 열린 공간으로 도망치는 것이 유리하므로 값이 클수록 이상적임
		local uncollided_dist = dist_to_check_collision

		-- 캐릭터가 도주 지점 반대 방향으로 향하는 벡터와 각 방향 벡터의 내적
		-- 값이 클수록 도주 지점으로부터 멀어지는 방향이므로 이상적임
		local opposite_dot = unity_class.vector3.Dot(self.npc_flee_direction_table[i], -flee_from_dir)

		-- 각 방향으로 이동 시에 충돌하는 물체 검사 (Bound를 줄여서 검사함)
		local cur_bound = cur_npc_info.character.Bounds
		cur_bound.size = cur_bound.size * 0.5

		local collided_objs = CS.Oak.LuaCollisionUtil.GetCollidedFieldObjects(
				cur_bound, self.npc_flee_direction_table[i] * dist_to_check_collision)

		if collided_objs ~= nil then
			local distances = collided_objs.Item1
			local fo_list = collided_objs.Item2

			if fo_list ~= nil and distances ~= nil then
				for n = 0, fo_list.Count - 1 do
					-- 자기 자신과 EtherealCrash, 생성된 NPC, 플레이어 파티원들은 무시
					if not lua_helper.reference_equals(fo_list[n], cur_npc_info.character) and
							not CS.Oak.ICrashBehaviourExtensions.IsEthereal(fo_list[n].CrashBehaviour) and
							fo_list[n].EntityGroup ~= CS.Oak.EntityGroups.Player1 and
							fo_list[n].EntityGroup ~= CS.Oak.EntityGroups.Player0 then
						-- Field.GetFieldObjectsCollidedBy는 충돌한 물체를 가장 가까운 것부터 정렬해서 리턴하므로
						-- 제일 먼저 걸리는 물체가 가장 먼저 충돌하는 물체임.
						-- 따라서 해당 물체까지의 거리가 충돌하지 않고 이동할 수 있는 거리.
						uncollided_dist = distances[n].distance

						break
					end
				end
			end

			distances:Dispose()
			fo_list:Dispose()
		end

		-- 최소 빈 공간이 확보되지 않았으면 이 방향으로는 도망갈 수 없음
		if required_dist <= 0 or required_dist <= uncollided_dist then
			-- 이 방향으로 도망갈 때의 점수
			-- 충돌하지 않고 도주할 수 있는 거리가 멀 수록 이상적이고,
			-- 가급적 도주 원인 지점으로부터 멀어지는 방향일수록 이상적이므로 두 수치를 곱하는 것으로 측정
			-- 내적 텀에 0.1을 0.1f를 더하는 이유는 도주하다가 벽 등에 가로막혔을 때 도주 원인 지점 방향에 수직으로 이동하는
			-- 경우가 필요한데, 이 경우 해당 방향 점수가 0이 되어 도주 루트로 고려되지 않는 경우가 발생하지 않도록 함.
			local score = uncollided_dist * (opposite_dot + 1)

			-- 점수가 가장 높은 방향이 도주하기 좋은 방향
			if best_score < score then
				best_dir = self.npc_flee_direction_table[i]
				best_score = score
			end
		end
	end

	if best_dir ~= unity_class.vector3.zero then
		-- AnalogueState 움직임 사용 시에는 벽에 끼는 경우가 자주 발생해서 직접 Position 변경
		character_util.set_direction(cur_npc_info.character, best_dir.normalized:ToDirection())
		cur_npc_info.character.Position = cur_npc_info.character.Position + best_dir.normalized *
				cur_npc_info.character.CharacterStatsBehaviour.DashSpeed * unity_class.time.deltaTime
	end
end

-- 공격 받아서 죽거나, 화면 밖으로 나가서 제거된 NPC를 완전히 초기화시켜서 다음에 쓸 수 있도록 하는 루틴
function local_class:initialize_npc(cur_npc_info, is_dead, dead_by_car)
	is_dead_by_car = lua_helper.get_or_default(dead_by_car, false)

	-- 타 요인에 의해 죽은 경우, 코인 드랍
	if is_dead then
		-- 코인 양 정함
		local coin_amount = unity_class.random.Range(self.npc_drop_coin_min, self.npc_drop_coin_max)

		for n = 1, 3 do
			message_system:Publish(CS.Oak.CustomStageEvent.Create(
					cur_npc_info.character, { self.coin_drop_event, tostring(coin_amount / 3) }))
		end
	end

	-- NPC AirSpin 처리 대기 시간
	if is_dead and not is_dead_by_car then
		cur_npc_info.ai_state = self.npc_ai_state.dead

		character_util.stop(cur_npc_info.character)

		coroutine.yield(nil)

		character_util.set_direction(cur_npc_info.character,
				CS.Oak.DirectionExtensions.GetSideDirection(cur_npc_info.character.Direction))
		character_util.set_anim(cur_npc_info.character, { name = 'dead', loop = false })
		character_util.set_emotion(cur_npc_info.character, { name = 'damaged' })

		-- 랜덤 대사 출력
		local cur_talk_num = math.floor(unity_class.random.Range(4, 6))
		speech_bubble_util.show_speech_bubble(
				cur_npc_info.character,{ key = 'demonworld_part1_civilian_'..cur_talk_num })

		wait_for_sec(3)

		unity_object_pool.GetOrCreate(self.explosion_effect_preset):Instantiate(cur_npc_info.character.Position)

		character_util.set_active_state(cur_npc_info.character, 'disabled')
	else
		if is_dead_by_car then
			unity_object_pool.GetOrCreate(self.hit_effect_preset):Instantiate(
					cur_npc_info.character.Position + vector(0, 0.3, 0))
			unity_object_pool.GetOrCreate(self.impact_hit_effect_preset):Instantiate(
					cur_npc_info.character.Position + vector(0, 0.3, 0))

			character_util.set_anim(cur_npc_info.character, { name = 'embarrassed' })
			character_util.set_emotion(cur_npc_info.character, { name = 'damaged' })
			character_util.air_spin(cur_npc_info.character)
		end

		wait_for_sec(1.5)
	end

	-- NPC Info 초기화
	cur_npc_info.activated = false
	cur_npc_info.ai_state = self.npc_ai_state.idle
	cur_npc_info.damaged = false
	cur_npc_info.out_of_camera = false
	cur_npc_info.waypoints = {}
	cur_npc_info.spawn_marker_index = 0
	cur_npc_info.wait_duration = 0

	-- NPC의 HPBar를 숨김
	message_system:Publish(CS.Oak.HideCharacterHPBarEvent.Create(cur_npc_info.character))

	local cur_npc = cur_npc_info.character
	character_util.set_position(cur_npc, vector(999, 0, 999))
	character_util.remove_anim(cur_npc)
	character_util.remove_emotion(cur_npc)
	cur_npc.SpineController:Rotate(0, 0)

	-- 힐로 HP 초기화
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = nil
	heal_info.target = cur_npc
	heal_info.heal = cur_npc.FieldObjectStatsBehaviour.MaxHP
	heal_info.isRevive = true

	command_util.execute_heal(heal_info)
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}