local local_class = newclass('SubStageLana2')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.belt_table = nil
	------------
	-- 벨트 스크롤에서 무시할 기믹 이름
	self.belt_gimmick_name = {
		'[gimmick]beltC',
		'[gimmick]beltC1',
		'[gimmick]beltC2',
		'[gimmick]beltL',
		'[gimmick]beltR'
	}

	-- 떨어지는 돌의 지름
	self.stone_range_radius = 1
	-- 돌 투하중인지
	self.bombing = false
	-- 돌 맞고 리셋중인지
	self.resetting = false

	-------------
	-- 점프점프 구간 벨트에 끼였는지 체크
	self.check_trapped = false

	-------------
	-- 안드로이드 박스 열었는지 체크
	self.box_open = {false, false, false, false}

	-------------
	-- 8번 벨트 목적지에 돌이 파괴되었는지 체크
	self.belt_8_rock_destroyed = false
	-- 화약통, 점프대 스폰 했는지 여부 (1개만 가능)
	self.is_spawn = {false, false}

	---------------
	-- 가짜 hold_up 할지 업데이트 단에서 체크하는 플래그
	self.fake_hold_up = false
	self.fake_hold_up_state = {
		start = 1,
		holding = 2
	}
	self.cur_state = self.fake_hold_up_state.start
	self.hold_up_duration = 0.12
	self.hold_up_time_passed = 0
	self.hold_start_diff = nil

	----------------
	-- 버려진 재료들
	self.recipe = nil

	----------------
	-- 무한 사이클링 컨베이어 벨트 관련 변수
	self.clockwise_enum = {
		vector(1, 0,0),
		vector(0, 0, -1),
		vector(-1, 0, 0),
		vector(0, 0, 1)
	}
	self.dir_enum = {
		right = 1,
		down = 2,
		left = 3,
		up = 4
	}
	-- key값으로 오브젝트 이름, val값으로 현제 향하는 방향 인덱스 (self.dir_enum)
	-- pivot이 달라서 offset으로 위치 조정
	self.circling_belt_obj_info = {
		belt_5 = {
			{name = 'box_1', dir = self.dir_enum.right, offset = vector(0, 0, 0), cached_pos = nil},
			{name = 'loop_belt_1_jump', dir = self.dir_enum.up, offset = vector(-0.4, 0, 0.25), cached_pos = nil},
			{name = 'loop_belt_3_jump', dir = self.dir_enum.up, offset = vector(0.6, 0, -1.2), cached_pos = nil},
			{name = 'loop_belt_4_jump', dir = self.dir_enum.left, offset = vector(0.6, 0, 0), cached_pos = nil},
			{name = 'loop_belt_5_jump', dir = self.dir_enum.down, offset = vector(0.6, 0, -0.35), cached_pos = nil}
		},
		-- 한바퀴 돌았는지 체크하는데 필요한 테이블
		belt_5_loop_check = {
			-- 한바퀴 돌았는지 기준이 되는 물체 이름
			name = 'loop_belt_1_jump',
			-- 한번이라도 방향을 바꾼적이 있는지
			changed_direction_once = false,
			-- 한바퀴 돌았는지
			looped_once = false,
			-- 처음 방향
			original_dir = self.dir_enum.up
		},
		belt_7 = {
			{name = 'box_2', dir = self.dir_enum.down, offset = vector(0, 0, -0.1), cached_pos = nil},
			{name = 'loop_belt_2_jump', dir = self.dir_enum.up, offset = vector(-0.4, 0, 0.1), cached_pos = nil}
		},
		-- 한바퀴 돌았는지 체크하는데 필요한 테이블
		belt_7_loop_check = {
			name = 'loop_belt_2_jump',
			changed_direction_once = false,
			looped_once = false,
			original_dir = self.dir_enum.up
		}
	}
	-- 5번 컨베이어 벨트 모서리 좌표
	self.circling_belt_coords = {
		belt_5 = {
			top_right = vector(-68.7, 0, 3),
			bot_left = vector(-71.7, 0, -4.1)
		},
		belt_7 = {
			top_right = vector(-78, 0, 1.3),
			bot_left = vector(-81.7, 0, -2.7)
		}
	}


end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.DamageEvent), 'on_damage_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_interact_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_field_object_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.BurnEvent), 'on_burn_event')

	self:set_belt_table()
	self.stucked_rock = get_field_object('belt_rock_3')
	return util.cs_generator(self.stage_load_resource, self)
end

function local_class:stage_load_resource()
	quest_util.load_pool_resource(
			'FX_reset_object',
			'fx_cp11_rock_landslide_purple'
	)

	coroutine.yield(unity_object_pool.WaitAll())
end

function local_class:need_on_launch()
	-- 퀘스트 진행도에 따라 launch를 빼앗아 온다.
	local quest_id = 197
	local inner_progress = user_progress:GetStartedQuest(quest_id).InnerProgress

	if inner_progress >= 1 then
		return true
	end
end

function local_class:on_launch(start_point_name)
	local quest_id = 197
	local inner_progress = user_progress:GetStartedQuest(quest_id).InnerProgress
	if inner_progress == 1 and not user_progress:ClearedQuest(quest_id) then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
	end
end

function local_class:on_launch_routine()
	local marker = field:GetMarker('new_start')

	party_util.position_party(marker.position, 'left', 'linear')

	coroutine.yield(nil)

	camera_util.move(user_party_leader.Position, 0, {end_target = user_party_leader})

	coroutine.yield(nil)

	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.Linear)

	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, marker.position, marker.direction,
			game_string:GetString(stage.Name))

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.DamageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BurnEvent))

	if self.recipe ~= nil then
		for _, value in ipairs(self.recipe) do
			value:ConsumeComplete()
			value = nil
		end
		self.recipe = nil
	end

	self.belt_table = nil
	self.belt_gimmick_name = nil
	self.stucked_rock = nil
	self.cs_controller = nil
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.Last
end

function local_class:late_update_frame(dt)
	-- 벨트 스크롤
	for i = 1, #self.belt_table do
		local belt = self.belt_table[i]

		-- 스위치 켜져있는지 판단
		if belt.switch_on then
			-- 애니메이션 재생 여부 판단
			if not belt.anim_on then
				for j = 1, belt.count do
					self:work_conveyor_belt(belt.name .. j, true)
				end
				belt.anim_on = true

				if belt.sfx == nil then
					belt.sfx = music_player_util.play_sfx({ sfx_name = '01_belt_01', play_pos = belt.bgm_pos,
															loop = true, type_priority = 'event', player_priority = 'default' })
				end
			end

			if i == 5 or i == 7 then
				self:circling_belt_move(i, belt.speed * dt)
			else
				-- 밸트 스크롤 루틴 시작
				for j = 1, belt.count do
					local zone = field:GetZone(belt.name .. j)
					local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, zone.Bounds)

					for k = 0, fo_list.Count - 1 do
						local fo = fo_list[k]
						if not table_util.contain_value(self.belt_gimmick_name, fo.Name) then
							fo.Position = fo.Position + belt.dir[j].normalized * belt.speed * dt
						end
					end

					fo_list:Dispose()

					local end_zone = field:GetZone(belt.name .. 'end')
					if end_zone ~= nil then
						local end_fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, end_zone.Bounds)

						for k = 0, end_fo_list.Count - 1 do
							local fo = end_fo_list[k]
							if not table_util.contain_value(self.belt_gimmick_name, fo.Name) then
								if fo.Position.y > 0 then
									fo.Position = fo.Position + vector(0, -1, 0).normalized * belt.speed * dt
								else
									fo.Position = fo.Position:GetX0z()

									if belt.callback then
										if not belt.callback_loop then
											belt.callback = false
										end
										if belt.end_custom_callback ~= nil then
											belt.end_custom_callback(fo)
										end
									end
								end
							end
						end

						end_fo_list:Dispose()
					end
				end
			end
		else
			if belt.anim_on then
				for j = 1, belt.count do
					self:work_conveyor_belt(belt.name .. j, false)
				end
				belt.anim_on = false
			end

			if belt.sfx ~= nil then
				belt.sfx:Stop()
				belt.sfx = nil
			end
			-- 밸트 스크롤 루틴 중단
		end
	end

	-- trap check
	if self.check_trapped then
		local leader_pos = user_party.Leader.Position

		if not user_party.Leader.FieldObjectBehaviour.CurrentState.IsAscending and leader_pos.y <= 0.8 then
			self.check_trapped = false
			sp_util.play_normal_screenplay(self.reset_position_by_trap, self)
		end
	end

	-- fake_hold_up
	if self.fake_hold_up then
		if self.cur_state == self.fake_hold_up_state.start then
			if self.hold_up_time_passed < self.hold_up_duration then
				self.hold_up_time_passed = self.hold_up_time_passed + dt
				-- character hold up state 참조
				-- 1회용이니 그냥 상수 넣었다
				local move_pos = user_party.Leader.Hitbox:GetCenter(user_party.Leader.Position)
				local hold_up_progress = self.hold_up_time_passed / self.hold_up_duration

				move_pos = move_pos + (1 - hold_up_progress) * vector(self.hold_start_diff.x, 0, self.hold_start_diff.z)
				local sin_end_rad = 100 * math.pi / 180
				local sin_end = math.sin(sin_end_rad)
				local y_diff = 1.1 * math.sin(sin_end_rad * hold_up_progress) / sin_end

				move_pos.y = y_diff
				user_party_leader.Position = move_pos
			else
				self.cur_state = self.fake_hold_up_state.holding
			end
		elseif self.cur_state == self.fake_hold_up_state.holding then
			user_party_leader.Position =
			user_party.Leader.SpineController.SpineContainerTransform.position + vector(0, 1.1, 0)
		end

	end
end

--region on event
function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_loaded_event(_)
	local names = {'first_jump', 'box_1', 'box_2', 'first_box'}

	for i = 1, #names do
		local loop_jump = get_field_object(names[i])
		local pos = loop_jump.Position
		pos.y = 0.7
		loop_jump.Position = pos
	end

	local pivot = {vector(0, 0.5, 1), vector(0, 0.5, 1),
				   vector(1, 0.5, 0), vector(1, 0.5, 1),
				   vector(1, 0.5, 0)}
	for i = 1, #pivot do
		local loop_jump = get_field_object('loop_belt_' .. i .. '_jump')
		local pos = loop_jump.Position
		pos.y = 0.7
		loop_jump.Position = pos

		local hitbox = CS.Oak.Hitbox(pivot[i], vector(0.8, 2, 0.8))
		loop_jump.Hitbox = hitbox
	end

	local last_jump = get_field_object('belt_jump_1')
	local hitbox = CS.Oak.Hitbox(vector(0, 0.1, 1), vector(1, 0.1, 1.2))
	last_jump.Hitbox = hitbox

	self.recipe = {}
	local recipe_1_pos = field:GetMarker('recipe_1').position
	for i = -1, 1 do
		for j = -3, 3 do
			local gnome = drop_item_util.create_item({ pos = recipe_1_pos + vector(j * 0.8, 0, -i * 0.3),
				itemid = 20132, notforinven = true, lootstate = 'dontfindlooter', sprscale = 0.5 })

			local rad = CS.UnityEngine.Random.value
			gnome.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)
			gnome.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)

			table.insert(self.recipe, gnome)
		end
	end

	for i = 1, 2 do
		local thorn = get_field_object('thorn_' .. i)
		local hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(1, 2, 1))
		thorn.Hitbox = hitbox
	end

	local recipe_ids = {20260, 20191, 20248, 20038, 20235}
	local recipe_2_pos = field:GetMarker('recipe_2').position
	for i = -2, 1 do
		for j = -2, 2 do
			local rand_id = random_util.get_random_int(1, #recipe_ids)
			local anything = drop_item_util.create_item({ pos = recipe_2_pos + vector(j * 0.7, 0, -i * 0.6),
													   itemid = recipe_ids[rand_id], notforinven = true, lootstate = 'dontfindlooter' })

			local rad = CS.UnityEngine.Random.value
			anything.SpriteTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)
			anything.ShadowTransform.localRotation = unity_class.quaternion.Euler(90, rad * 360, 0)

			table.insert(self.recipe, anything)
		end
	end

	self:resize_conveyor_belt()

	return true
end

function local_class:on_switch_on_off_event(e)
	local switch_name = e.SwitchObject.Name
	-- 벨트 작동용 스위치
	if string.find(switch_name, 'belt') then
		local belt_string = 'belt_'
		local switch_idx = tonumber(string.sub(switch_name, #belt_string + 1, #belt_string + 1))
		self.belt_table[switch_idx].switch_on = e.IsTurningOn

		return true
	elseif string.find(switch_name, 'spawn_switch') then
		local spawn_string = 'spawn_switch_'
		local switch_idx = tonumber(string.sub(switch_name, #spawn_string + 1, #spawn_string + 1))
		if not self.is_spawn[switch_idx] then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.spawn_obj, self, switch_idx))
		end
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return false end
	if e.FieldObject ~= user_party.Leader then return false end
	local zone_name = e.Zone.Name

	if zone_name == 'crash_change_zone_1' then
		user_party.Leader.OverrideCrashBehaviour = CS.Oak.DefaultCrashBehaviour.Instance
	elseif zone_name == 'crash_change_zone_2' then
		user_party.Leader.OverrideCrashBehaviour = CS.Oak.EtherealCharacterCrashBehaviour.Instance
	elseif zone_name == 'bomb_zone' then
		self.bombing = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rock_falling, self))
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rock_falling_leader, self))
	elseif zone_name == 'conveyor_belt_active_zone' then
		for i = 2, 3 do
			self.belt_table[i].switch_on = true
		end
	elseif zone_name == 'conveyor_belt_8_9_active_zone' then
		self.belt_table[8].switch_on = true
		self.belt_table[9].switch_on = true
		self:work_conveyor_belt('conveyor_belt_10_1', true)
	elseif zone_name == 'conveyor_belt_8_9_deactive_zone' then
		self.belt_table[8].switch_on = false
		self.belt_table[9].switch_on = false
		self.belt_table[10].switch_on = false
	elseif zone_name == 'loop_belt_3' and not self.belt_8_rock_destroyed then
		self.check_trapped = true
	else
		for i = 1, 2 do
			if zone_name == 'loop_belt_' .. i then
				self.check_trapped = true
			end
		end
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave == false then return false end
	if e.FieldObject ~= user_party.Leader then return false end
	local zone_name = e.Zone.Name

	if zone_name == 'bomb_zone' then
		self.bombing = false
	elseif zone_name == 'conveyor_belt_active_zone' then
		for i = 2, 4 do
			self.belt_table[i].switch_on = false
		end
	else
		for i = 1, 3 do
			if zone_name == 'loop_belt_' .. i then
				self.check_trapped = false
			end
		end
	end

	return false
end

function local_class:on_damage_event(e)
	--if lua_helper.reference_equals(e.Info.target, get_field_object('jump_stone_2'))
	--		and e.Info.type == CS.Oak.DamageType.Explosion then
	--
	--	for i = 1, 2 do
	--		local stone = get_field_object('jump_stone_' .. i)
	--		stone.ActiveState = active_state('disabled')
	--	end
	--
	--	self.belt_8_rock_destroyed = true
	--	-- 걸려있는척 하던 끝부분을 작동시킨다
	--	self.belt_table[10].switch_on = true
	--end
	--if lua_helper.reference_equals(e.Info.target, user_party.Leader)
	--		and e.Info.type == CS.Oak.DamageType.Trap then
	--	--coroutine_manager:StartCoroutine(stage.StageGameObject,
	--	--		util.cs_generator(self.self_knock_back, self, e.Info.knockBackDirection))
	--	local duration = 0.2
	--	local leader_x = user_party.Leader.Position.x
	--	local impact_vector = e.Info.knockBackDirection * 0.8
	--
	--	if user_party.Leader.Position.y > 0 then
	--		if leader_x > -32 then
	--			duration = 0.3
	--			impact_vector = vector(0.8, 0, 0)
	--		elseif leader_x > -36 then
	--			duration = 0.25
	--			impact_vector = vector(1.6, 0, 0)
	--		elseif leader_x > -38 then
	--			duration = 0.1
	--			impact_vector = vector(0.8, 0, 0)
	--		end
	--	end
	--	--character_util.move_to(user_party.Leader,
	--	--		user_party.Leader.Position + impact_vector, duration, 0)
	--end
end

function local_class:on_interact_event(e)
	for i = 1, 4 do
		local box = get_field_object('android_box_' .. i)
		if lua_helper.reference_equals(e.Target, box) then
			if not self.box_open[i] then
				-- 보물상자 오픈
				--coroutine_manager:StartCoroutine(stage.StageGameObject,
				--		util.cs_generator(self.open_box, self, box, i))
				sp_util.play_normal_screenplay(self.open_box, self, box, i)
			else
				-- 안드로이드 대사
				music_player:PlaySfxOneShot('03_dialogue_worker_01')
				local android = get_character('box_android_' .. i)
				speech_bubble_util.show_speech_bubble(android, {key = 'futurecastle_oni_girl_2_box_android_' .. i})
				--원재료 보관상자도 점검중입니다.
			end
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, get_field_object('jump_stone_2')) then

		local another_stone = get_field_object('jump_stone_1')
		local damage_info = CS.Oak.DamageInfo()
		damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
		damage_info.sender = user_party
		damage_info.target = another_stone
		damage_info.damage = 100

		command_util.execute_damage(damage_info)

		self.belt_8_rock_destroyed = true
		-- 걸려있는척 하던 끝부분을 작동시킨다
		self.belt_table[10].switch_on = true
	end
end

function local_class:on_custom_stage_event(e)
	if e.Params[0] == 'fake_hold_up' then
		self.fake_hold_up = e.Params[1] == 'true' and true or false
		if self.fake_hold_up then
			self.hold_up_time_passed = 0
			music_player:PlaySfxOneShot('01_holdup_01')
			self.hold_start_diff = user_party_leader.Hitbox:GetCenter(user_party_leader.Position)
					- user_party.Leader.Hitbox:GetCenter(user_party.Leader.Position)
		end
	end
end

function local_class:on_burn_event(e)
	local gunpowder = get_field_object('belt_gunpowder_1')
	if lua_helper.reference_equals(e.Target, gunpowder) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
			wait_for_sec(0.7)
			gunpowder.Holdable = CS.Oak.Holdable()
		end))
	end
end
--endregion

function local_class:circling_belt_move(belt_num, speed)
	-- 벨트 번호로 어떤 컨베이어 벨트가 돌아가야 하는지 확인
	local objs_info = nil
	local loop_check = nil
	local belt_coord = nil
	objs_info = self.circling_belt_obj_info['belt_' .. belt_num]
	belt_coord = self.circling_belt_coords['belt_' .. belt_num]
	loop_check = self.circling_belt_obj_info['belt_' .. belt_num ..'_loop_check']
	if objs_info == nil then return end

	for i = 1, table_util.get_size(objs_info) do
		local obj_info = objs_info[i]
		local obj_name = obj_info['name']
		local obj_dir = obj_info['dir']
		local offset = obj_info['offset']
		local cached_pos = obj_info['cached_pos']

		local fo = get_field_object(obj_name)
		-- 모서리 위치 받기
		local l, r, t, b
		l = belt_coord.bot_left.x
		r = belt_coord.top_right.x
		t = belt_coord.top_right.z
		b = belt_coord.bot_left.z

		fo.Position = fo.Position - offset

		-- 이동한 거리를 퍼센트로 환산
		local progress = 0
		local total_dist = 0
		local moved_dist = 0
		if obj_dir == self.dir_enum.right then
			total_dist = r - l
			moved_dist = fo.Position.x - l
		elseif obj_dir == self.dir_enum.down then
			total_dist = b - t
			moved_dist = fo.Position.z - t
		elseif obj_dir == self.dir_enum.left then
			total_dist = l - r
			moved_dist =  fo.Position.x - r
		elseif obj_dir == self.dir_enum.up then
			total_dist = t - b
			moved_dist = fo.Position.z - b
		end
		progress = moved_dist / total_dist

		local loop_check_name = loop_check['name']
		if progress >= 1 then
			if obj_name == loop_check_name and not loop_check['changed_direction_once'] then
				loop_check['changed_direction_once'] = true
			end

			if obj_dir == self.dir_enum.right then
				fo.Position = vector(r, fo.Position.y, fo.Position.z)
				obj_dir = self.dir_enum.down
			elseif obj_dir == self.dir_enum.down then
				fo.Position = vector(fo.Position.x, fo.Position.y, b)
				obj_dir = self.dir_enum.left
			elseif obj_dir == self.dir_enum.left then
				fo.Position = vector(l, fo.Position.y, fo.Position.z)
				obj_dir = self.dir_enum.up
			elseif obj_dir == self.dir_enum.up then
				fo.Position = vector(fo.Position.x, fo.Position.y, t)
				obj_dir = self.dir_enum.right
			end
		else
			fo.Position = fo.Position + self.clockwise_enum[obj_dir] * speed
		end

		-- 한바퀴 돌때마다 위치 리셋
		if obj_name == loop_check_name and loop_check['looped_once'] then
			if cached_pos ~= nil then
				if cached_pos:AlmostCloseTo(fo.Position) then
					for j = 1, table_util.get_size(objs_info) do
						local temp_fo = get_field_object(objs_info[j]['name'])
						temp_fo.Position = objs_info[j]['cached_pos']
					end
				end
			end
		end

		-- 한바퀴 돈 시점에서 물체들 전부 캐싱
		if obj_name == loop_check_name and not loop_check['looped_once'] then
			if obj_dir == loop_check['original_dir'] and loop_check['changed_direction_once'] then
				loop_check['looped_once'] = true
				for j = 1, table_util.get_size(objs_info) do
					local temp_fo = get_field_object(objs_info[j]['name'])
					objs_info[j]['cached_pos'] = temp_fo.Position
				end
			end
		end

		fo.Position = fo.Position + offset

		self.circling_belt_obj_info['belt_' .. belt_num][i]['dir'] = obj_dir
		self.circling_belt_obj_info['belt_' .. belt_num .. '_loop_check'] = loop_check
	end
end

function local_class:set_belt_table()
	self.belt_table = {
		{
			name = 'conveyor_belt_1_',
			count = 2,
			dir = {vector(0, 0, -1), vector(1, 0, 0)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = true,
			callback_loop = false,
			end_custom_callback = function (fo)
				music_player_util.play_sfx({ sfx_name = '01_gatcha_box_01', type_priority = 'event', player_priority = 'npc' })
				message_system:Publish(CS.Oak.SwitchOnOffEvent.Create(get_field_object('door_switch_1'), true, user_party.Leader))
			end,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_1').position
		},
		{
			name = 'conveyor_belt_2_',
			count = 1,
			dir = {vector(0, 0, 1)},
			switch_on = false,
			anim_on = false,
			speed = 3,
			callback = true,
			callback_loop = true,
			end_custom_callback = function (fo)
				if string.find(fo.Name, 'thorn') then
					music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', parent = fo,
												 type_priority = 'event', player_priority = 'npc' })

					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
					fo.Position = field:GetMarker('conveyor_belt_2_marker').position
					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
				end
			end,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_2').position
		},
		{
			name = 'conveyor_belt_3_',
			count = 1,
			dir = {vector(0, 0, 1)},
			switch_on = false,
			anim_on = false,
			speed = 3,
			callback = true,
			callback_loop = true,
			end_custom_callback = function (fo)
				if string.find(fo.Name, 'thorn') then
					music_player_util.play_sfx({ sfx_name = '01_guild_warp_01', parent = fo,
												 type_priority = 'event', player_priority = 'npc' })

					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
					fo.Position = field:GetMarker('conveyor_belt_3_marker').position
					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
				end
			end,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_2').position
		},
		{
			name = 'conveyor_belt_4_',
			count = 1,
			dir = {vector(0, 0, 1)},
			switch_on = false,
			anim_on = false,
			speed = 1,
			callback = true,
			callback_loop = true,
			end_custom_callback = function (fo)
				if string.find(fo.Name, 'thorn') then
					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
					fo.Position = field:GetMarker('conveyor_belt_4_marker').position
					unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(fo.Position)
				end
			end,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_2').position
		},
		{
			name = 'conveyor_belt_5_',
			count = 4,
			dir = {vector(0, 0, -1), vector(-1, 0, 0),
				   vector(0, 0, 1), vector(1, 0, 0)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = false,
			callback_loop = false,
			end_custom_callback = nil,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_3').position
		},
		{
			name = 'conveyor_belt_6_',
			count = 3,
			dir = {vector(-1, 0, 0), vector(0, 0, -1), vector(-1, 0, 0)},
			switch_on = false,
			anim_on = false,
			speed = 3,
			callback = true,
			callback_loop = false,
			end_custom_callback = function (fo)
				music_player_util.play_sfx({ sfx_name = '01_bounce_iron_01', type_priority = 'event', player_priority = 'npc' })
			end,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_1').position
		},
		{
			name = 'conveyor_belt_7_',
			count = 4,
			dir = {vector(0, 0, -1), vector(-1, 0, 0),
				   vector(0, 0, 1), vector(1, 0, 0)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = false,
			callback_loop = false,
			end_custom_callback = nil,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_4').position
		},
		{
			name = 'conveyor_belt_8_',
			count = 1,
			dir = {vector(0, 0, 1)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = true,
			callback_loop = true,
			end_custom_callback = nil,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_5').position
		},
		{
			name = 'conveyor_belt_9_',
			count = 1,
			dir = {vector(0, 0, -1)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = true,
			callback_loop = true,
			end_custom_callback = nil,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_6').position
		},
		{
			name = 'conveyor_belt_10_',
			count = 1,
			dir = {vector(0, 0, -1)},
			switch_on = false,
			anim_on = false,
			speed = 2,
			callback = true,
			callback_loop = true,
			end_custom_callback = nil,
			sfx = nil,
			bgm_pos = field:GetMarker('bgm_pos_6').position
		}
	}
end

-- 컨베이어벨트 애니메이션 컨트롤
function local_class:work_conveyor_belt(zone_name, turn_on)
	local zone = field:GetZone(zone_name)

	local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, zone.Bounds)

	for i = 0, fo_list.Count - 1 do
		local fo = fo_list[i]
		if table_util.contain_value(self.belt_gimmick_name, fo.Name) then
			local animator = fo:GetComponent(typeof(CS.UnityEngine.Animator))
			if turn_on then
				animator:Play('xmas_belt_rolling')
				animator.speed = 3
			else
				animator:Play('empty')
				animator.speed = 1
			end
		end
	end

	fo_list:Dispose()
end

function local_class:resize_conveyor_belt()

	for i = 1, #self.belt_table do
		local belt = self.belt_table[i]
		for j = 1, belt.count do
			local zone = field:GetZone(belt.name .. j)

			local fo_list = CS.Oak.LuaCollisionUtil.GetFieldObjectsCollidedBy(unity_class.vector3.zero, zone.Bounds)

			for k = 0, fo_list.Count - 1 do
				local fo = fo_list[k]
				if table_util.contain_value(self.belt_gimmick_name, fo.Name) then

					local pivot = vector(0.5, 0.5, 0.5)
					local size = vector(1, 1, 1)

					if string.find(fo.Name, 'beltC1') or string.find(fo.Name, 'beltC2') then
						pivot = vector(0.3335, 0.5, 0.6665)
						size = vector(1.5, 1, 1.5)

						if fo.Transform.eulerAngles.y == 90 then
							pivot = vector(0.6665, 0.5, 0.6665)
						elseif fo.Transform.eulerAngles.y == 180 then
							pivot = vector(0.6665, 0.5, 0.3335)
						elseif fo.Transform.eulerAngles.y == 270 then
							pivot = vector(0.3335, 0.5, 0.6665)
						end
					end

					--pivot = unity_class.quaternion.Euler(fo.Transform.eulerAngles) * pivot
					--size = unity_class.quaternion.Euler(fo.Transform.eulerAngles) * size
					local hitbox = CS.Oak.Hitbox(pivot, size)
					fo.Hitbox = hitbox
				end
			end

			fo_list:Dispose()
		end
	end
end

-- 마지막 돌 떨어지는 루틴
function local_class:rock_fall(target_pos, delay)

	if delay > 0 then
		wait_for_sec(delay)
	end

	local rock = unity_object_pool.GetOrCreate('fx_cp11_rock_landslide_purple'):Instantiate(target_pos)
	rock.transform.localScale = unity_class.vector3.one * 0.5

	wait_for_sec(0.4)

	camera_util.shake(0.15, 0.15)
end

-- 랜덤하게 떨어지는 돌
function local_class:rock_falling()
	while self.bombing do
		local rand_x = math.floor(unity_class.random.Range(-5, 1))
		local rand_z = math.floor(unity_class.random.Range(-2, 2))

		rand_x = user_party.Leader.Position.x + rand_x
		if rand_x <= -113 then
			rand_x = 113
		end
		if rand_x >= -86 then
			rand_x = -86
		end

		self:rock_fall(vector(rand_x, 1, rand_z), 1)

		local rand_additional_time = unity_class.random.Range(0.3, 2)

		wait_for_sec(rand_additional_time)
	end
end

-- 리더 있던 자리로 떨어지는 돌
function local_class:rock_falling_leader()
	while self.bombing do
		self:rock_fall(user_party.Leader.Position, 1)

		local rand_additional_time = unity_class.random.Range(0.3, 1)

		wait_for_sec(rand_additional_time)
	end
end

-- 점프대 잘못 이용해서 벨트 영역 안으로 들어갔을때 불리는 루틴
function local_class:reset_position_by_trap()
	message_system:Send(user_party.Leader, CS.Oak.HitFloorEvent.Create(0));
	wait_for_sec(0.1)

	--coroutine.yield(nil)

	local target_pos = user_party.Leader.Position
	--target_pos.y = 0.7

	music_player_util.play_sfx_one_shot('03_runaway_01')
	character_util.set_position(user_party.Leader, target_pos)
	character_util.set_emotion(user_party.Leader, {name = 'surprise'})

	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(1, 'linear')

	character_util.set_with_marker(user_party.Leader, field:GetMarker('trap_reset'))
	character_util.remove_emotion(user_party.Leader)

	screen_util.fade_in_circular_async(1, 'linear')
end

function local_class:spawn_obj(idx)
	local obj = {get_field_object('belt_gunpowder_1'), get_field_object('belt_jump_1')}
	local pos = {field:GetMarker('conveyor_belt_8_marker').position, field:GetMarker('conveyor_belt_9_marker').position}
	local offset = {vector(0, 0, 0), vector(-0.5, 0, 0)}
	self.is_spawn[idx] = true
	music_player_util.play_sfx_one_shot('01_guild_warp_01')
	unity_object_pool.GetOrCreate('FX_reset_object'):Instantiate(pos[idx])
	wait_for_sec(0.3)
	obj[idx].Position = pos[idx] + offset[idx]
end

-- 안드로이드 상자를 연다
function local_class:open_box(fo, idx)
	self.box_open[idx] = true

	local and_data = {
		{
			anim = 'eat',
			emo = 'scared',
			dir = 'right',
			shake = true
		},
		{
			anim = 'idle',
			emo = 'idle',
			dir = 'up',
			shake = false
		},
		{
			anim = 'idle',
			emo = 'mad',
			dir = 'down',
			shake = false
		},
		{
			anim = 'idle',
			emo = 'smile',
			dir = 'down',
			shake = false
		}
	}

	--message_system:SendSync(fo, CS.Oak.InteractEvent.Create(user_party.Leader, fo))
	local diff = (fo.Bounds.center - user_party.Leader.Position).normalized
	user_party.Leader.SpineController:DeviateLocal(diff * 0.3, 0.12, 0.15)

	wait_for_sec(0.09)

	music_player:PlaySfxOneShot('01_cliff_01')

	fo:Shake(0.03, 10)

	music_player:PlaySfxOneShot('02_treasure_open_01')

	local box_animator = fo.transform:GetComponentInChildren(
			typeof(CS.UnityEngine.Animator))

	box_animator:Play('open')

	wait_for_sec(0.15)

	fo:CancelShake()

	wait_for_sec(1)

	local android = get_character('box_android_' .. idx)
	android.Position = fo.Position + vector(-0.5, -0.1, -1.1)

	character_util.set_direction(android, and_data[idx].dir)
	character_util.set_anim_and_emotion(android, {name = and_data[idx].anim}, {name = and_data[idx].emo})
	if and_data[idx].shake then
		character_util.shake(android, 0.04, 99999)
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
