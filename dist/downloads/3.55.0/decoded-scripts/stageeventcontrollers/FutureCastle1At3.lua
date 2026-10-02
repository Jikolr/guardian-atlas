local local_class = newclass("FutureCastle1At3Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller
	self.alert_guards = create_generic_list(typeof(CS.Oak.IFieldObject))
	self.laser_alerted = false
	self.damage_alerted = false
	self.alert_gauge = 0;
	self.alert_pending = false
	self.alert_pending_time_passed = 0
	self.running_alert_max = false
	self.running_mission_impossible = false
	self.reached_inside = false
	self.reached_checkpoint = false

	self.aps = 200
	self.reverse_aps = 100
	self.alert_pending_duration = 1.0

	self.pissing_guard_group_name = 'pissing_guard_group'
	self.pissing_guard_starpiece_name = 'pissing_guard_starpiece'

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.update_loop, self))

	-- FIXME:
	--coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.debug_loop, self))
	--self.force_mi = true

	self.hole_interactable = nil

	self.piss_guard_gone = false
	self.inside_grid = false
	self.grid_req_id = 0
	self.lock_piss = false
end


-- FIXME:
function local_class:debug_loop()
	while true do
		if CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.A) then
			local item = CS.Oak.ItemPlaceholder()
			item.ItemId = CS.Oak.ItemSpecId.MouseBombController
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mouse_controller_get, self, item))
		elseif CS.UnityEngine.Input.GetKeyDown(CS.UnityEngine.KeyCode.T) then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mission_impossible, self))
		end

		coroutine.yield(nil)
	end
end


function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.PlayerDetectedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_event')

	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')

	if not CS.Oak.User.Me:HasItem(CS.Oak.ItemSpecId.MouseBombController) or self.force_mi then
		unity_object_pool.GetOrCreate("rope_trap")
	end

	CS.Oak.CommonScreenplay.PreloadActivityClear()
	CS.Oak.CommonScreenplay.PreloadItemGetEvent()

	return util.cs_generator(self.stage_load_resource, self)
end

--- Load Resources Here.
function local_class:stage_load_resource()
	self.res_holder = CS.Foundations.ResourceHolder()
	self.alert_bar = nil
	coroutine.yield(self.res_holder:LoadPrefabAsync(CS.Foundations.AssetName("ondemand/v2_3_futurecastle/ui/stage", "BoundaryBar"), function(p)
		local menuObj = CS.NGUITools.AddChild(stage.UIRoot.gameObject, p)
		self.alert_bar = menuObj:GetComponent(typeof(CS.Oak.UI.FutureCastleAlertBar))
		self.alert_bar_initialized = true
	end))
	self.all_guards = create_generic_list(typeof(CS.Oak.IFieldObject))

	if stage_progress:IsBoxOpened('chest_red_2') then
		-- 아카유키 퀘스트 ID
		local quest_id = 161
		local custom_state_key = 'got_murasame'
		local quest_progress = user_progress:GetStartedQuest(quest_id)
		if quest_progress ~= nil and quest_util.get_custom_state(quest_progress, custom_state_key) ~= 1 then
			quest_util.set_custom_state(quest_progress, custom_state_key, 1)
		end
	end

	quest_util.load_pool_resource(
			'FX_starpiece_in_character'
	)
end

function local_class:need_on_launch()
	return true
end

function local_class:on_launch(start_point_name)
	local main_quest_id = 151
	local main_quest = user_progress:GetStartedQuest(main_quest_id)
	local inner_progress = -1
	if main_quest ~= nil and not main_quest.IsComplete then
		inner_progress = main_quest.InnerProgress
	end

	-- 파티원 모두 제외. 공주 추가.
	if user_party.Count > 1 then
		for i = 1, user_party.Count -1 do
			user_party[i].ActiveState = CS.Oak.ActiveState.Disabled
		end

		while user_party.Count > 1 do
			user_party:RemoveAt(1)
		end
	end

	local walker = 1
	while true do
		local g = get_character(string.format("gaurd_%d", walker))
		if g == nil then
			break
		end

		self.all_guards:Add(g)

		walker = walker + 1
	end

	get_field_object("section_2_jump").ActiveState = CS.Oak.ActiveState.Disabled
	get_field_object("laser_5").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_6").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_7").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_8").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_11").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_12").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_13").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_14").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_15").ActiveState = CS.Oak.ActiveState.InField
	get_field_object("laser_16").ActiveState = CS.Oak.ActiveState.InField

	self:enlarge_puzzle_2_switches()

	local princess = get_character("princess")
	character_util.convert_to_party_member(princess, user_party, true)
	princess:SetEquipment(CS.Oak.EquipmentSlot.Weapon1,
			CS.Oak.Item.Create(CS.Oak.ItemSpec.GetByName('cwp_futureprincess_epic'), nil, nil, 69), true)

	-- 쓸데없는 지뢰 렌더링 제거
	for i = 1, 62 do
		local mine = get_field_object(string.format("mi_mine_%d", i))
		mine.ActiveState = CS.Oak.ActiveState.Disabled
	end

	if inner_progress == 11 then
		-- 퀘스트에서 스테이지 시작 이벤트 연출
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	else
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
	end

	local thehole = get_field_object('route_1_hole')
	thehole.UnityGameObject.transform.localScale = vector(0.7,1,0.7)
	self.hole_interactable = thehole.Interactable
	thehole.Interactable = CS.Oak.NonInteractable.Instance

	local piss_guard = get_character('piss_guard')
	local piss_starpiece = get_field_object(self.pissing_guard_starpiece_name)

	self.pissing_guard_starpiece_effect = nil
	if not piss_starpiece.FieldObjectBehaviour.IsAcquired then
		self.pissing_guard_starpiece_effect = unity_object_pool.GetOrCreate('FX_starpiece_in_character'):Instantiate(
				piss_guard.Position, unity_class.quaternion.identity, piss_guard.Transform, CS.Oak.ParentFollowFlag.All)
	else
		self.piss_guard_gone = true
		character_util.set_active_state(piss_guard, 'disabled')
	end
	-- character_util.shake(piss_guard, 0.05, 3600)
end

function local_class:on_launch_routine()
	screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
	screen_util.fade_in_circular(1, CS.Oak.Interpolations.Linear)

	local marker = field:GetMarker("default_start")
	if marker.direction == CS.Oak.Direction.None then
		marker.direction = CS.Oak.Direction.Right
	end

	-- FIXME:
	--marker.position = vector(137, 0, 1)
	--marker.position = vector(65, 0, -17)
	--marker.position = vector(129.5, 0, 14.5)
	--marker.position = vector(109, 0, -15)

	yield_return_func(CS.Oak.CommonScreenplay.DirectionalStageEntry, marker.position, marker.direction,
			game_string:GetString(stage.Name))

	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end


function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.PlayerDetectedEvent) then
		if e.ByDamage then
			if e.Detector.FieldObjectController:GetType()  == typeof(CS.Oak.FutureCastleInvaderGuardCharacterController) then
				self.damage_alerted = true
				self.damaged_guard = e.Detector
			end
		else
			local bt = e.Detector.FieldObjectBehaviour:GetType()
			local ct = e.Detector.FieldObjectController:GetType()
			if ct  == typeof(CS.Oak.FutureCastleInvaderGuardCharacterController) then
				self.alert_guards:Add(e.Detector)
			elseif bt == typeof(CS.Oak.LaserSecurityFieldObjectBehaviour) then
				if self.running_mission_impossible then
					self.mission_impossible_detected = true
				else
					self.laser_alerted = true
				end

			end
		end

	elseif event_type == typeof(CS.Oak.InteractEvent) then
		if e.Target.Name == "mi_stair" then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mission_impossible_exit, self))
		elseif e.Target.Name == "mi_hole" then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mission_impossible_entry, self))
		end
	elseif event_type == typeof(CS.Oak.SwitchOnOffEvent) then
		if e.IsTurningOn and e.SwitchObject.Name == "mi_switch" and not self.mission_impossible_joined then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mission_impossible_join, self))
		end
	elseif event_type == typeof(CS.Oak.ItemGetEvent) then
		if e.Item.ItemId == CS.Oak.ItemSpecId.MouseBombController then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.mouse_controller_get, self, e.Item))
		elseif e.Item.ItemId == 20209 then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.akayuki_sword_get, self, e.Item))
		end
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		if e.FieldObject.Name == 'route_1_hole_breakable' then
			local thehole = get_field_object('route_1_hole')
			thehole.Interactable = self.hole_interactable
		end
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		if e.Zone.Name == "halbal_zone" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.reached_inside = true
		end if e.Zone.Name == "ROOM_stair" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
				self.reached_inside = true
		elseif e.Zone.Name == "checkpoint" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self.reached_checkpoint = true
		elseif e.FullEnter and e.Zone.Name == 'piss_guard_zone' and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not self.piss_guard_gone and not self.lock_piss then
				local piss_starpiece = get_field_object(self.pissing_guard_starpiece_name)
				if not piss_starpiece.FieldObjectBehaviour.IsAquired then
					self.inside_grid = true
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.piss_guard_talk, self))
					return true
				end
			end
		elseif e.FullEnter and e.Zone.Name == "ROOM_puzzle_2" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self:reset_puzzle_2_switches()
		end
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		if e.FullLeave and e.Zone.Name == 'piss_guard_zone' and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			if not self.piss_guard_gone then
				self.inside_grid = false
				return true
			end
		elseif e.FullLeave and e.Zone.Name == "ROOM_puzzle_2" and lua_helper.reference_equals(e.FieldObject, user_party_leader) then
			self:enlarge_puzzle_2_switches()
		end
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		return self:on_battle_group_eliminated_event(e)
	elseif event_type == typeof(CS.Oak.GotCrashedEvent) then
		if self.all_guards:Contains(e.Crash.self) then
			self.damaged_guard = e.Crash.self
			self.damage_alerted = true
		end
	end
	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.pissing_guard_group_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.pissing_guard_starpiece_show, self, e.Item))
		return true
	elseif e.BattleGroupName == "battle_2" then
		local jump = get_field_object("section_2_jump")
		jump.ActiveState = CS.Oak.ActiveState.Enabled
		music_player:PlaySfxOneShot("02_explosion_01")
		unity_object_pool.GetOrCreate("FX_dead"):Instantiate(jump.Bounds.center)
	end
	return false
end

function local_class:enlarge_puzzle_2_switches()
	local fo1 = get_field_object("puzzle_2_switch_1")
	local fo2 = get_field_object("puzzle_2_switch_2")

	local hb = fo1.Hitbox
	hb.size = vector(1.25, 0.2, 1.25)

	fo1.Hitbox = hb
	fo2.Hitbox = hb
end

function local_class:reset_puzzle_2_switches()
	local fo1 = get_field_object("puzzle_2_switch_1")
	local fo2 = get_field_object("puzzle_2_switch_2")

	local hb = fo1.Hitbox
	hb.size = vector(0.5, 0.2, 0.5)

	fo1.Hitbox = hb
	fo2.Hitbox = hb
end

function local_class:dispose()
	self.alert_guards:Clear()
	self.alert_guards = nil
	self.res_holder:Dispose()
	self.res_holder = nil
	self.damaged_guard = nil

	self.hole_interactable = nil

	if self.pissing_guard_starpiece_effect ~= nil then
		self.pissing_guard_starpiece_effect:Dispose()
		self.pissing_guard_starpiece_effect = nil
	end

	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.PlayerDetectedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.ItemGetEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent), "on_joypad")

	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')


	self.cs_controller = nil
end

function local_class:update_loop()
	while true do
		if not self.running_alert_max and not self.running_mission_impossible then
			local dt = unity_class.time.deltaTime
			local watch_count = 0

			local i = 0
			while i < self.alert_guards.Count do
				local still_in = self.alert_guards[i].FieldObjectController:IsWatching()
				if still_in then
					watch_count = watch_count + 1
					i = i + 1
				else
					self.alert_guards:RemoveAt(i)
				end
			end

			local alert_max = false
			if watch_count == 0 and not self.laser_alerted and not self.damage_alerted then
				if self.alert_gauge > 0 then
					if self.alert_pending then
						local before = self.alert_pending_time_passed - self.alert_pending_duration
						self.alert_pending_time_passed = self.alert_pending_time_passed + dt
						local after = self.alert_pending_time_passed - self.alert_pending_duration

						if self.alert_pending_time_passed >= self.alert_pending_duration then
							if before < 0 then
								before = 0
							end
							local actual_dt = after - before

							self.alert_gauge = self.alert_gauge - self.reverse_aps * actual_dt
							if self.alert_gauge <= 0 then
								-- NOTE: 게이지가 0 이 되었다.
								self.alert_gauge = 0
							end
						end
					else
						self.alert_pending = true
						self.alert_pending_time_passed = 0
					end
				else
					self.alert_pending = false
				end
			elseif self.laser_alerted then
				alert_max = true
			elseif self.damage_alerted then
				alert_max = true
			elseif watch_count > 0 then
				self.alert_gauge = self.alert_gauge + self.aps * dt
				if self.alert_gauge >= 100 then
					self.alert_gauge = 100
					alert_max = true
				end
			end

			if self.alert_bar_initialized then
				if alert_max then
					coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.alert_max_gameover, self))
				else
					self.alert_bar:SetValue(self.alert_gauge)
				end
			end
		end

		coroutine.yield(nil)
	end
end

-- 오줌 참는 인베이더 대사
function local_class:piss_guard_talk()
	local piss_guard = get_character('piss_guard')

	-- 같은 코루틴 여러개 방지
	self.grid_req_id = self.grid_req_id + 1
	local my_req_id = self.grid_req_id
	local timer = -1
	local tmpflags = { false, false, false }
	repeat
		timer = timer + CS.UnityEngine.Time.deltaTime
		if timer > 0 and not tmpflags[1] then
			tmpflags[1] = true
			music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = piss_guard})
			-- 오늘은 근무중에 화장실 안갈거야!
			speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_1' , skip = false})
		end
		if timer > 3 and not tmpflags[2] then
			tmpflags[2] = true
			-- 추운 날이라서 다행이야…
			speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_2' , skip = false})
		end
		if timer > 6 and not tmpflags[3] then
			tmpflags[3] = true
			music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = piss_guard})
			-- 따뜻할 땐 이상하게 마렵거든…
			speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_3' , skip = false})
		end
		if timer > 12 then
			timer = 0
			tmpflags = { false, false, false}
		end
		coroutine.yield(nil)
	until not self.inside_grid or my_req_id ~= self.grid_req_id or self:piss_guard_check_burning()

	if self:piss_guard_check_burning() then
		self.lock_piss = true
		local timeSinceLastSeen = 0

		local flags = { false, false, false, false, false, false }

		repeat
			timeSinceLastSeen = timeSinceLastSeen + CS.UnityEngine.Time.deltaTime

			if timeSinceLastSeen > 3 and not flags[1] then
				flags[1] = true
				music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = piss_guard})
				-- 어...어어...
				speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_4', skip = false })
			elseif timeSinceLastSeen > 6 and not flags[2] then
				flags[2] = true
				music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = piss_guard})
				-- 왜 이렇게 따뜻해...
				speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_5', skip = false })
			elseif timeSinceLastSeen > 9 and not flags[3] then
				flags[3] = true
				music_player_util.play_sfx({ sfx_name = '03_runaway_01', parent = piss_guard})
				character_util.shake(piss_guard, 0.05, 10)
				-- 으...으아아아...
				speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_6', skip = false })
			elseif timeSinceLastSeen > 12 and not flags[4] then
				flags[4] = true
				-- 화, 화장실....
				speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_7', skip = false })
			elseif timeSinceLastSeen > 15 and not flags[5] then
				flags[5] = true
				music_player_util.play_sfx({ sfx_name = '03_dialogue_sadness_01', parent = piss_guard})
				-- 교대 시간은 아직 멀었는데..
				speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_8', skip = false })
			elseif timeSinceLastSeen > 18 and not flags[6] then
				self:going_to_piss()
				self.piss_guard_gone = true
				break
			end
			coroutine.yield(nil)
		until not self:piss_guard_check_burning()
	end
	speech_bubble_util.remove_bubble(piss_guard)
	self.lock_piss = false
	return
end

-- 오줌 참는 인베이더 주변 타는거 검사
function local_class:piss_guard_check_burning()
	local piss_guard = get_character('piss_guard')
	local fos = stage.Field:GetFieldObjectsInRadius(piss_guard.Bounds.center, 3)

	for i=0,fos.Count-1 do
		if not lua_helper.reference_equals(fos[i], piss_guard) then
			if fos[i].CombustibleBehaviour.IsBurning then
				return true
			end
		end
	end
	return false
end

-- 못참고 오줌 싸러 가는 인베이더
function local_class:going_to_piss()
	local piss_guard = get_character('piss_guard')

	character_util.stop_shake(piss_guard)

	character_util.normal_jump_async(piss_guard, true)

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = piss_guard})
	-- 으아아악 모르겠다!
	speech_bubble_util.show_speech_bubble_async(piss_guard, { key = 'futurecastle_piss_guard_9', skip = false })

	local tmp = piss_guard.Position
	local wps = {
		tmp + 2 * unity_class.vector3.back + 1 * unity_class.vector3.down,
		tmp + 4 * unity_class.vector3.back + 1 * unity_class.vector3.down,
		tmp + 4 * unity_class.vector3.back + 1 * unity_class.vector3.down + 3 * unity_class.vector3.right,
		tmp + 20 * unity_class.vector3.back + 1 * unity_class.vector3.down + 3 * unity_class.vector3.right,
	}

	music_player_util.play_sfx({ sfx_name = '01_dash_01', parent = piss_guard})
	wp_util.move_way_points_async(piss_guard, { waypoints = wps, speed = 6, run = true })

	self:pissing_guard()

	-- character_util.set_active_state(piss_guard, 'disabled')
end

function local_class:pissing_guard()
	local piss_guard = get_character('piss_guard')

	-- 후.. 시원하다.
	speech_bubble_util.show_speech_bubble(piss_guard, { key = 'futurecastle_piss_guard_10', skip = false })

	wait_for_sec(3)

	character_util.convert_to_monster(piss_guard, self.pissing_guard_group_name)
	character_util.set_death_type(piss_guard, 'airspin')
end

function local_class:pissing_guard_starpiece_show()
	local star_piece = get_field_object(self.pissing_guard_starpiece_name)
	star_piece.Position = vector(38.5,0,-42)
	self.pissing_guard_starpiece_effect:Dispose()
	message_system:Send(star_piece, CS.Oak.StarPieceAppearEvent.Create(vector(38.5,0,-42)))
end

function local_class:alert_max_gameover()
	local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

	if self.damage_alerted then
		message_system:Publish(CS.Oak.MouseBombResetEvent.Create(false))
	end

	self.running_alert_max = true
	user_party:StopAndDisableControl()
	field:Tint("alert_max", unity_class.color(1, 0, 0), 0.25)
	camera_util.shake(0.07, 0.25)

	for i = 0, user_party.Count -1 do
		character_util.set_anim(user_party[i], { name = "embarrassed", loop = true })
		character_util.set_emotion(user_party[i], { name = "surprise", loop = true})
		if i == 0 then
			user_party[i].SpineController:Jump(0.3, 0.2)
		end
	end

	local gauge_time = 0.2
	local current_val = self.alert_bar.AlertRealValue
	local to_end_time = (100 - current_val) / self.aps
	if to_end_time < gauge_time then
		gauge_time = to_end_time
	end

	local time_passed = 0
	while time_passed < gauge_time do
		time_passed = time_passed + unity_class.time.deltaTime
		local prog = time_passed / gauge_time
		if prog >= 1 then
			break
		end

		self.alert_bar:SetValue(prog * 100 + (1 - prog) * current_val)
		coroutine.yield(nil)
	end

	self.alert_bar:SetValue(100)

	if self.damage_alerted then
		character_util.set_anim(self.damaged_guard, { name = "embarrassed", loop = true })
		speech_bubble_util.show_speech_bubble_async(self.damaged_guard, { key = "futurecastle_1_3_guard_damaged", skip = "true", bubble_type = "shout" })
		wait_for_sec(0.25)
	elseif self.alert_guards.Count > 0 then
		for i = 0, self.alert_guards.Count -1 do
			character_util.set_anim(self.alert_guards[i], { name = "release", loop = true })
		end
		speech_bubble_util.show_speech_bubble_async(self.alert_guards[0], { key = "futurecastle_1_3_guard_alert", skip = "true", bubble_type = "shout" })
		wait_for_sec(0.25)
	else
		wait_for_sec(0.75)
	end


	screen_util.fade_out_circular(0.5, 'linear')

	wait_for_sec(1.0)
	siren:FadeOut(0.5)

	field:RemoveTint("alert_max", 0)

	local respawn_pos = field:GetMarker("default_start").position
	if self.reached_checkpoint then
		respawn_pos = field:GetMarker("revive_2").position
	elseif self.reached_inside then
		respawn_pos = field:GetMarker("revive_1").position
	end

	local respawn_dir = CS.Oak.Direction.Right

	user_party:PositionParty(respawn_pos, respawn_dir, 0, 'linear')
	for i = 0, user_party.Count -1 do
		character_util.remove_anim(user_party[i], false)
		character_util.remove_emotion(user_party[i])
	end

	wait_for_sec(0.5)

	self.alert_gauge = 0
	self.laser_alerted = false
	self.damage_alerted = false
	if self.damaged_guard ~= nil then
		character_util.remove_anim(self.damaged_guard, false)
	end

	self.damaged_guard = nil

	for i = 0, self.alert_guards.Count -1 do
		character_util.remove_anim(self.alert_guards[i], false)
	end
	self.alert_guards:Clear()
	self.alert_bar:SetValue(0)
	stage_camera:Move(user_party_leader.Position, 0, user_party_leader)

	screen_util.fade_in_circular(0.5, 'linear')
	wait_for_sec(0.5)

	user_party:ResetControllers()

	self.running_alert_max = false

end

function local_class:mission_impossible_entry()
	local fo = get_field_object("mi_hole")
	if not CS.Oak.User.Me:HasItem(CS.Oak.ItemSpecId.MouseBombController) or self.force_mi then
		user_party:StopAndDisableControl()

		user_party:PositionParty(fo.Position + vector(1.0, 0, 0), CS.Oak.Direction.Left, 0.5, "linear")
		--coroutine.yield(align_party(fo, CS.Oak.Direction.Right, 1.0, CS.Oak.Party.AlignType.Linear))
		wait_for_sec(0.5)
		coroutine.yield(nil)

		local leader = user_party[0]
		local princess = user_party[1]

		camera_util.resize_to(3.0, 0.75, true)
		wait_for_sec(0.75)

		CS.GlobalTimeManager.Instance:Mod(0.075, "mi_entry")

		music_player_util.play_sfx({sfx_name = '01_player_jump_01'})
		character_util.set_emotion(leader, { name = "smile", loop = true })
		character_util.set_anim(leader, { name = "get", loop = false })
		character_util.set_emotion(princess, { name = "surprise", loop = true })

		local time_passed = 0
		local jump_duration = 0.2
		local jump_height = 0.3
		local jump_start_pos = leader.Position

		local princess_start_time = 0.11
		local princess_set = false
		local princess_start_pos = princess.Position
		local princess_end_pos = princess.Position - vector(1.15, 0, 0)

		while time_passed < jump_duration do
			local dt = unity_class.time.deltaTime
			time_passed = time_passed + dt
			local prog = time_passed / jump_duration
			if prog >= 1 then
				break
			end

			local princess_prog = (time_passed - princess_start_time) / (jump_duration - princess_start_time)
			if princess_prog >= 0 then
				if not princess_set then
					princess_set = true
					character_util.set_anim(princess, { name = "run", loop = true })
					character_util.set_anim(princess, { name = "push", loop = true, upper = true})
					princess:HideWeapon(true)
					CS.GlobalTimeManager.Instance:Unmod("mi_entry")
				end

				princess.Position = princess_start_pos * (1 - princess_prog) + princess_end_pos * princess_prog
			end

			leader.Position = jump_start_pos * (1 - prog) +  fo.Position * prog
			leader.SpineController.SpineOffset = vector(0, jump_height * unity_class.mathf.Sin(unity_class.mathf.PI * 0.5 * prog), 0)
			coroutine.yield(nil)
		end

		music_player_util.play_sfx({ sfx_name = '02_hit_critical_01' })
		unity_object_pool.GetOrCreate("FX_hit"):Instantiate(leader.Bounds.center, unity_class.quaternion.identity, leader.Transform)

		leader.Position = fo.Position
		leader.SpineController.SpineOffset = vector(0, jump_height, 0)

		character_util.set_emotion(leader, { name = "damaged", loop = true })
		character_util.set_anim(leader, { name = "embarrassed", loop = true })
		character_util.remove_anim(princess, false)

		time_passed = 0
		local rotation_time_passed = 0

		local fly_duration = 0.15
		local fly_target = fo.Position - vector(1.25, 0, 0)
		local calc = CS.CalculatorFreeFall(5, 10, jump_height, 0)
		calc:ScaleTime(3.0)
		local rotation_duration = calc:GetTotalTime() / 3.0 + fly_duration
		leader.SpineController:Rotate(360, rotation_duration)

		while time_passed < fly_duration do
			local dt = unity_class.time.deltaTime
			time_passed = time_passed + dt
			rotation_time_passed = rotation_time_passed + dt

			local prog  = time_passed / fly_duration
			if prog >= 1 then
				break
			end

			leader.Position = fo.Position * (1 - prog) + fly_target * prog
			coroutine.yield(nil)
		end

		music_player_util.play_sfx({ sfx_name = '01_player_hit_wall_01' })
		unity_object_pool.GetOrCreate("FX_wallimpact"):Instantiate(fo.Position - vector(1.5, 0, 0), unity_class.quaternion.AngleAxis(-90, vector(0, 1, 0)), nil)

		leader.Direction = CS.Oak.Direction.Right
		character_util.set_anim(leader, { name = "prostrate", loop = false })

		local fall_target = fo.Position + vector(0, 0, 1)
		while true do
			local dt = unity_class.time.deltaTime
			calc:Proceed(dt)

			local prog = calc:GetProgress()
			leader.Position = fly_target * (1 - prog) + fall_target * prog
			leader.SpineController.SpineOffset = vector(0, calc:GetDistance(), 0)

			if calc:IsDone() then
				break
			end
			coroutine.yield(nil)
		end

		music_player_util.play_sfx({ sfx_name = '01_land_01' })
		leader.SpineController.SpineOffset = vector(0, 0, 0)

		wait_for_sec(0.5)

		character_util.remove_anim(princess, true)
		character_util.set_anim(princess, { name = "walk", loop = true })
		princess.Direction = CS.Oak.Direction.Up
		character_util.move_to(princess, princess.Position + vector(0.25, 0, 1), 0.5)
		wait_for_sec(0.5)
		princess.Direction = CS.Oak.Direction.Left

		character_util.set_anim(princess, { name = "release", loop = true })
		character_util.add_animation_sfx(princess, '01_swing_01')

		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_1", skip = true })

		character_util.remove_anim(princess, false)

		leader:Shake(0.07, 0.35)
		music_player_util.play_sfx({ sfx_name = '01_rustle_01' })
		wait_for_sec(0.5)

		character_util.remove_emotion(leader)
		character_util.remove_anim(leader, false)
		music_player:PlaySfxOneShot('01_player_popup_01')
		yield_return_func(CS.Oak.CharacterExtensions.MarioJump, leader, CS.Oak.Direction.Right, 0.3, 0.3)

		wait_for_sec(0.5)
		leader:HideWeapon(true)
		character_util.set_anim(leader, { name = "bomb_idle", loop = true})

		wait_for_sec(1.0)

		character_util.set_emotion(princess, { name = "attack", loop = false })
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_2", skip = true })
		character_util.remove_emotion(princess)
		character_util.remove_anim(leader, true)

		leader.Direction = CS.Oak.Direction.Down
		princess.Direction = CS.Oak.Direction.Down
		character_util.set_anim(princess, { name = "walk", loop = true })
		character_util.move_to(princess, princess.Position - vector(0.25, 0, 1), 0.5)
		wait_for_sec(0.5)
		princess.Direction = CS.Oak.Direction.Left
		character_util.remove_anim(princess, false)
		wait_for_sec(1.0)
		--character_util.set_anim(princess, { name = "eat", loop = true })
		--wait_for_sec(0.5)

		screen_util.fade_out(0.5, unity_class.color.black, "linear")
		wait_for_sec(1.0)

		ui_quest_marker:Show(false)

		local room_pos = field:GetZone("ROOM_mi").Bounds.center
		room_pos.y = 0

		for i = 1, 62 do
			local mine = get_field_object(string.format("mi_mine_%d", i))
			mine.ActiveState = CS.Oak.ActiveState.Enabled
		end

		local stair = get_field_object("mi_stair")
		stair.ActiveState = CS.Oak.ActiveState.Disabled

		camera_util.move(room_pos, 0, { end_target = nil })
		camera_util.resize_to_default(0)

		coroutine.yield(nil)

		screen_util.fade_in(0.5, unity_class.color.black, "linear")
		wait_for_sec(3.0)

		screen_util.fade_out(0.5, unity_class.color.black, "linear")
		wait_for_sec(1.0)

		camera_util.move(leader.Position, 0, { end_target = leader })
		camera_util.resize_to(3.0, 0)

		coroutine.yield(nil)

		screen_util.fade_in(0.5, unity_class.color.black, "linear")
		wait_for_sec(1.0)

		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_3", skip = true })
		character_util.remove_anim(princess, false)
		wait_for_sec(0.5)
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_4", skip = true })

		princess.Direction = CS.Oak.Direction.Up
		character_util.set_anim(princess, { name = "walk", loop = true })
		character_util.move_to(princess, princess.Position + vector(0.25, 0, 1), 0.5)
		wait_for_sec(0.5)
		leader.Direction = CS.Oak.Direction.Right
		princess.Direction = CS.Oak.Direction.Left
		character_util.remove_anim(princess, false)
		speech_bubble_util.show_speech_bubble_async(princess, { key = { "futurecastle_1_3_hole_entry_5", user.Name }, skip = true })
		character_util.set_emotion(princess, { name = "tired", loop = false})
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_6", skip = true })

		local wait_for_branch = true
		local branches = create_generic_list(typeof(CS.Oak.TalkBranch))

		local talk_branch_1 = {
			Text = game_string:GetString("futurecastle_1_3_hole_entry_7"),
			Tendency = CS.Oak.TalkTendency.Brutal,
			Callback = function()
				wait_for_branch = false
			end}

		local talk_branch_2 = {
			Text = game_string:GetString("futurecastle_1_3_hole_entry_8"),
			Tendency = CS.Oak.TalkTendency.Intellect,
			Callback = function()
				wait_for_branch = false
			end}

		local talk_branch_3 = {
			Text = game_string:GetString("futurecastle_1_3_hole_entry_9"),
			Tendency = CS.Oak.TalkTendency.Mercy,
			Callback = function()
				wait_for_branch = false
			end}


		branches:Add(talk_branch_1)
		branches:Add(talk_branch_2)
		branches:Add(talk_branch_3)

		local choice_state = CS.Oak.UI.AnswerChoiceState()
		choice_state.Branchs = branches
		choice_state.Talker = leader
		ui_scene_manager:PushOverlay(CS.Oak.UI.AnswerChoice.Instance, choice_state)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		character_util.set_emotion(leader, { name = "smile", loop = false })
		character_util.set_anim(leader, { name = "release", loop = true })
		character_util.add_animation_sfx(leader, '01_swing_01')

		wait_for_sec(1.0)

		character_util.remove_emotion(leader)
		character_util.remove_anim(leader, false)

		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_10_2", skip = true })
		character_util.set_emotion(princess, { name = "sleep_deep", loop = false})
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_10", skip = true })
		character_util.remove_emotion(princess)
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_11", skip = true })

		leader.Direction = CS.Oak.Direction.Down
		princess.Direction = CS.Oak.Direction.Down
		character_util.set_anim(princess, { name = "walk", loop = true })
		character_util.move_to(princess, princess.Position - vector(0, 0, 1), 0.5)
		wait_for_sec(0.5)
		princess.Direction = CS.Oak.Direction.Left
		character_util.remove_anim(princess, false)
		wait_for_sec(1.0)
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_12", skip = true })
		wait_for_sec(0.5)
		character_util.set_emotion(princess, { name = "attack"})
		speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_hole_entry_13", skip = true })

		character_util.set_anim(leader, { name = "question", loop = false })
		local go = unity_object_pool.GetOrCreate("emoticon"):Instantiate(user_party[1].Position)
		local emoticon = go.transform:GetComponent(typeof(CS.Oak.Emoticon))
		emoticon:Init()
		emoticon:ShowOn(leader, vector(1, 1, 1), CS.Oak.EmoticonType.Question)
		wait_for_sec(2.0)

		yield_return_func(self.mission_impossible, self)
	else
		speech_bubble_util.show_speech_bubble_async(fo, { key = "futurecastle_1_3_mi_no_entry"} )
	end
end


function local_class:mission_impossible()
	self.running_mission_impossible = true
	self.mission_impossible_detected = false
	self.mission_impossible_joined = false
	self.mission_impossible_done = false

	music_player_util.play_stage_music({ state = 'muted', mix = 1.0 })
	screen_util.fade_out(1.0, unity_class.color.black, "linear")

	wait_for_sec(1.5)

	local stair = get_field_object("mi_stair")
	stair.ActiveState = CS.Oak.ActiveState.Disabled

	for i = 1, 62 do
		local mine = get_field_object(string.format("mi_mine_%d", i))
		mine.ActiveState = CS.Oak.ActiveState.Enabled
	end

	local computer = get_field_object("mi_computer")

	local computer_ui_dict = field_ui_manager:SetUI(computer, CS.Oak.FieldUiType.TimerBar)
	local computer_timer_bar = computer_ui_dict[CS.Oak.FieldUiType.TimerBar]
	computer_timer_bar.BarSprite:SetWidth(100)
	computer_timer_bar.BarSprite:SetMinMax(0, 100)
	computer_timer_bar.BarSprite:SetValue(0, 0)
	computer_timer_bar:SetPosition(computer.Position + vector(0, 2, 0))
	computer_timer_bar.gameObject:SetActive(false)
	local computer_progress = 0
	local cps = 25

	local laser_1 = get_field_object("mi_laser_1")
	local laser_2 = get_field_object("mi_laser_2")
	local room = field:GetZone("ROOM_mi").Bounds

	local room_center = room.center
	room_center.y = 0
	laser_1.Position = (room_center - vector(room.extents.x, 0, 0))
	laser_2.Position = (room_center + vector(room.extents.x, 0, 0))

	user_party[0]:HideWeapon(false)
	character_util.remove_anim(user_party[0], false)
	user_party[1]:HideWeapon(false)

	local princess = user_party[1]
	user_party:RemoveAt(1)
	self.original_leader = user_party_leader
	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	CS.Oak.ICharacterExtensions.ConvertToManualCharacter(princess, param)

	local rope = unity_object_pool.GetOrCreate("rope_trap"):Instantiate(princess.Position + vector(0, 0.3, 0), unity_class.quaternion.identity, princess.SpineController.SpineContainerTransform)
	self.rope_tip = rope.transform:Find("tip"):GetComponent(typeof(CS.CustomSprite))
	self.rope_1 = rope.transform:Find("rope"):GetComponent(typeof(CS.CustomSprite))

	local rope_4 = rope.transform:Find("rope (4)")
	local new_rope = CS.UnityEngine.GameObject.Instantiate(rope_4.gameObject, rope_4.position + vector(0, 2.3, 0), unity_class.quaternion.identity, rope.transform)
	local new_rope_2 = CS.UnityEngine.GameObject.Instantiate(rope_4.gameObject, rope_4.position + vector(0, 4.6, 0), unity_class.quaternion.identity, rope.transform)

	coroutine.yield(nil)

	self.rope_tip:SetSortingOrder(-1)
	self.rope_1:SetSortingOrder(-1)

	coroutine.yield(nil)

	user_party:StopAndDisableControl()

	local start_pos = field:GetMarker("mi_start").position
	princess.Position = start_pos + vector(0.5, 0, 0.5)
	princess.Direction = CS.Oak.Direction.Left
	--camera_util.move(princess.Position, 0, { end_target = princess })
	camera_util.move(room_center, 0, { end_target = nil })
	camera_util.resize_to(3.5, 0)
	character_util.set_anim(princess, { name = "unique/mi_idle", loop = true })
	character_util.remove_emotion(princess)

	local start_offset = 10
	princess.SpineController.SpineOffset = vector(0, start_offset, 0)

	coroutine.yield(nil)

	music_player_util.play_stage_music({ name = 'ondemand/v2_3_futurecastle/audio/music/bgm_futurecastle_mission:bgm_futurecastle_mission', state = 'event', mix = 0 })
	screen_util.fade_in(1.0, unity_class.color.black, "linear")
	wait_for_sec(1.0)

	local drop_druation = 3.5
	local drop_time_passed = 0
	local target_offset = 0.2

	while drop_time_passed < drop_druation do
		drop_time_passed = drop_time_passed + unity_class.time.deltaTime
		local prog = drop_time_passed / drop_druation
		if prog >= 1 then
			break
		end

		princess.SpineController.SpineOffset = vector(0, start_offset * (1 - prog) + target_offset * prog, 0)

		coroutine.yield(nil)
	end

	princess.SpineController.SpineOffset = vector(0, target_offset, 0)

	camera_util.move(princess.Position, 1.0, { end_target = princess })

	wait_for_sec(1.0)

	speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_security_1", skip = true})
	speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_security_2", skip = true})

	princess.Direction = CS.Oak.Direction.Up
	self.rope_tip:SetSortingOrder(1)
	self.rope_1:SetSortingOrder(1)

	stage_camera:Move(computer.Position, 1.0, nil)
	wait_for_sec(2.0)
	stage_camera:Move(princess.Position, 1.0, princess)
	wait_for_sec(1.1)

	speech_bubble_util.show_speech_bubble_async(princess, { key = "futurecastle_1_3_security_3", skip = true})

	message_system:Subscribe(self, typeof(CS.Oak.JoypadEvent), "on_joypad")

	field_ui_manager:SetUI(princess, CS.Oak.FieldUiType.DPad);

	local type_loop = nil
	local time_passed = 0
	while true do
		local dt = unity_class.time.deltaTime
		time_passed = time_passed + dt

		local rad = time_passed * CS.UnityEngine.Mathf.PI * 0.25
		local dir = vector(CS.UnityEngine.Mathf.Cos(rad), 0, CS.UnityEngine.Mathf.Sin(rad))

		local r1 = CS.UnityEngine.Ray(room.center, dir)
		local r2 = CS.UnityEngine.Ray(room.center, -dir)

		local dist1 = CS.BoundsExtensions.RayIntersectDistance(room, r1)
		local dist2 = CS.BoundsExtensions.RayIntersectDistance(room, r2)

		laser_1.Position = room_center + dir * dist1
		laser_2.Position = room_center - dir * dist2

		local did_computer = false
		if user_party[0].Direction ~= CS.Oak.Direction.Down then
			local c_dir = (computer.Position - user_party[0].Position):ToDirection()
			if c_dir == user_party[0].Direction then
				local computer_dist = CS.BoundsExtensions.GetDistanceBetween(princess.Bounds, computer.Bounds)
				if computer_dist < 0.05 then
					if computer_progress == 0 then
						computer_timer_bar.gameObject:SetActive(true)
					end

					computer_progress = computer_progress + cps * dt
					did_computer = true
				end
			end
		end

		if did_computer and type_loop == nil then
			type_loop = music_player:PlaySfx({ sfxName = '01_typing_01', loop = true })
		elseif not did_computer and type_loop ~= nil then
			type_loop:Stop()
			type_loop = nil
		end

		computer_timer_bar.BarSprite:SetValue(computer_progress, 0)

		if computer_progress >= 100 then
			CS.Oak.CommonScreenplay.ShowActivityClear()
			break
		end


		if self.mission_impossible_detected then
			local siren = music_player:PlaySfx({ sfxName = '01_siren_loop_01', loop = true })

			character_util.set_emotion(princess, { name = "surprise", loop = true })
			field:Tint("alert_max", unity_class.color(1, 0, 0), 0.5)
			camera_util.shake(0.07, 0.25)
			field_ui_manager:RemoveUI(princess, CS.Oak.FieldUiType.DPad)

			wait_for_sec(1.0)
			screen_util.fade_out_circular(0.5, "linear")
			wait_for_sec(0.5)
			siren:FadeOut(0.5)
			wait_for_sec(0.5)

			self.rope_tip:SetSortingOrder(-1)
			self.rope_1:SetSortingOrder(-1)
			princess.Position = start_pos
			princess.Direction = CS.Oak.Direction.Left
			character_util.remove_emotion(princess)
			computer_progress = 0
			computer_timer_bar.BarSprite:SetValue(computer_progress, 0)
			computer_timer_bar.gameObject:SetActive(false)
			time_passed = 0
			laser_1.Position = (room_center - vector(room.extents.x, 0, 0))
			laser_2.Position = (room_center + vector(room.extents.x, 0, 0))

			field:RemoveTint("alert_max", 0)
			field_ui_manager:SetUI(princess, CS.Oak.FieldUiType.DPad);

			screen_util.fade_in_circular(0.5, "linear")
			wait_for_sec(0.5)
			self.mission_impossible_detected = false
		else
			coroutine.yield(nil)
		end
	end

	self.mission_impossible_done = true
	self.rope_tip = nil
	self.rope_1 = nil

	if type_loop ~= nil then
		type_loop:Stop()
		type_loop = nil
	end

	wait_for_sec(1.75)

	speech_bubble_util.show_speech_bubble_async(computer, { key = "futurecastle_1_3_security_off", skip = true })

	screen_util.fade_out(0.5, unity_class.color.white, "linear")
	wait_for_sec(1.0)

	laser_1.ActiveState = CS.Oak.ActiveState.Disabled
	laser_2.ActiveState = CS.Oak.ActiveState.Disabled

	camera_util.resize_to_default(0)

	for i = 1, 62 do
		local mine = get_field_object(string.format("mi_mine_%d", i))
		mine.ActiveState = CS.Oak.ActiveState.Disabled
	end

	field_ui_manager:RemoveUI(princess, CS.Oak.FieldUiType.DPad)
	field_ui_manager:RemoveUI(computer, CS.Oak.FieldUiType.TimerBar)
	message_system:Unsubscribe(self, typeof(CS.Oak.JoypadEvent), "on_joypad")

	princess.SpineController.SpineOffset = vector(0, 0, 0)
	character_util.remove_anim(princess, false)
	princess.SpineController:ForceUpdateSpines(unity_class.time.deltaTime)

	rope:Dispose()
	rope = nil

	screen_util.fade_in(0.5, unity_class.color.white, "linear")
	wait_for_sec(0.75)

	music_player:PlaySfxOneShot("02_explosion_01")

	unity_object_pool.GetOrCreate("FX_dead"):Instantiate(stair.Bounds.center)
	stair.ActiveState = CS.Oak.ActiveState.Enabled

	user_party:ResetControllers()

	self.running_mission_impossible = false
end

function local_class:mission_impossible_exit()
	user_party:StopAndDisableControl()

	music_player:PlaySfxOneShot("01_stage_in_teleport_01")

	screen_util.fade_out_circular(0.6, CS.Oak.Interpolations.EaseInOutSine)

	music_player_util.play_stage_music({ state = 'field', mix = 2 })

	wait_for_sec(0.6)

	local marker = field:GetMarker("mi_stair_out")

	user_party:PositionParty(marker.position, CS.Oak.Direction.Left, 0, "linear")

	coroutine.yield(nil)

	self.original_leader.Position = marker.position - vector(2, 0, 4)
	self.original_leader.Direction = CS.Oak.Direction.Up
	character_util.set_anim(self.original_leader, { name = "success", loop = true })
	ui_quest_marker:Show(true)

	screen_util.fade_in_circular(0.6, CS.Oak.Interpolations.EaseInOutSine)

	wait_for_sec(0.6)

	user_party:ResetControllers()
end

function local_class:mission_impossible_join()
	self.mission_impossible_joined = true

	user_party:StopAndDisableControl()
	message_system:Publish(CS.Oak.DoorOpenEvent.Create("mi_door", false))

	wait_for_sec(2.0)

	stage_camera:Move(self.original_leader.Position, 1.0, self.original_leader)

	wait_for_sec(1.0)

	local princess = user_party[0]

	local param = CS.Oak.CharacterConvertParam:ManualDefault()
	param.HidePreviousParty = false
	CS.Oak.ICharacterExtensions.ConvertToManualCharacter(self.original_leader, param)
	character_util.convert_to_party_member(princess, user_party, true)
	character_util.remove_anim(self.original_leader, false)
	self.original_leader = nil
end

function local_class:on_joypad(e)
	if not self.running_mission_impossible or self.mission_impossible_done then
		return false
	end

	local speed = 3.0
	if e.JoypadEventType == CS.Oak.JoypadEventType.StickDirection then
		CS.Oak.MoveOneFrameStageLogic.ExecuteMove(user_party[0], e.StickDirection, speed * unity_class.time.deltaTime)

		if user_party[0].Direction ~= e.Stick4WayDirection then
			user_party[0].Direction = e.Stick4WayDirection
			if self.rope_tip ~= nil then
				if e.Stick4WayDirection == CS.Oak.Direction.Up then
					self.rope_tip:SetSortingOrder(1)
					self.rope_1:SetSortingOrder(1)
				else
					self.rope_tip:SetSortingOrder(-1)
					self.rope_1:SetSortingOrder(-1)
				end
			end
		end
	end

	return false
end

function local_class:mouse_controller_get(item)
	user_party:StopAndDisableControl()

	stage_camera:Move(user_party_leader.Position, 0.5, user_party_leader)
	wait_for_sec(0.5)

	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item, "mouse_bomb_controller", "mouse_bomb_controller_subtitle", "mouse_bomb_controller_desc"))

	if user_party.Count > 1  then
		wait_for_sec(0.25)
		if user_party[0].Position.x < user_party[1].Position.x then
			user_party[1].Direction = CS.Oak.Direction.Left
		else
			user_party[1].Direction = CS.Oak.Direction.Right
		end

		character_util.set_anim(user_party[1], { name = "question", loop = false})
		speech_bubble_util.show_speech_bubble_async(user_party[1], { key = "futurecastle_1_3_mouse_get_1", skip = true })

		local go = unity_object_pool.GetOrCreate("emoticon"):Instantiate(user_party[1].Position)
		local emoticon = go.transform:GetComponent(typeof(CS.Oak.Emoticon))
		emoticon:Init()
		emoticon:ShowOn(user_party[1], vector(1, 1, 1), CS.Oak.EmoticonType.Notice)
		wait_for_sec(2.0)

		speech_bubble_util.show_speech_bubble_async(user_party[1], { key = "futurecastle_1_3_mouse_get_2", skip = true })
		character_util.remove_anim(user_party[1], false)
	end

	user_party:ResetControllers()
end

function local_class:akayuki_sword_get(item)
	user_party:StopAndDisableControl()

	-- 아카유키 퀘스트 ID
	local quest_id = 161
	local custom_state_key = 'got_murasame'
	local quest_progress = user_progress:GetStartedQuest(quest_id)
	if quest_progress ~= nil then
		quest_util.set_custom_state(quest_progress, custom_state_key, 1)
	end

	stage_camera:Move(user_party_leader.Position, 0.5, user_party_leader)
	wait_for_sec(0.5)

	coroutine.yield(CS.Oak.CommonScreenplay.ItemGetEvent(item, "akayuki_sword", "akayuki_sword_subtitle", "akayuki_sword_desc"))

	user_party:ResetControllers()
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
