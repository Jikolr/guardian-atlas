local local_class = newclass('ShortStoryNoelController')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version + 1

	self.main_quest_id = 7002201

	self.quest_progress = nil

	-- npc
	self.npcs = {
		noel = function()
			return get_character('noel')
		end,

		noel_myth = function()
			return get_character('noel_myth')
		end,

		gnome_commander = function()
			return get_character('gnome_commander')
		end,
		s1_help_gnome = function(number)
			return get_character('s1_help_gnome_' .. number)
		end,
		machine_old = function()
			return get_character('machine_old')
		end,
		bombbug_friend = function()
			return get_character('bombbug_friend')
		end,
		bombbug_friend_myth = function()
			return get_character('bombbug_friend_myth')
		end,
		bombbug = function(number)
			return get_character('bombbug_' .. number)
		end,
		s5_ant = function(number)
			return get_character('s5_ant_soldier_' .. number)
		end,

		--마피아 감시 쥐
		watch_mafia = function(num)
			return get_character('sub_zootopia_mafia_watcher_' .. num)
		end,
	}

	-- marker
	self.markers = {
		s1_gnome_commander_pos = function()
			return field_util.get_marker_pos('s1_gnome_commander_pos')
		end,
		s1_gnome_help_pos = function(number)
			return field_util.get_marker_pos('s1_gnome_help_pos_' .. number)
		end,
		s1_bullet_start_pos = function(number)
			return field_util.get_marker_pos('s1_bullet_start_pos_' .. number)
		end,
		s1_bullet_end_pos = function(number)
			return field_util.get_marker_pos('s1_bullet_end_pos_' .. number)
		end,
		s3_diary_pos = function()
			return field_util.get_marker_pos('s3_diary_pos')
		end,
		s3_machine_old_pos = function()
			return field_util.get_marker_pos('s3_machine_old_pos')
		end,
		s5_reset_pos = function(number)
			return field_util.get_marker_pos('s5_ant_reset_pos_' .. number)
		end,
		s5_reset_dir = function(number)
			return field_util.get_marker_dir('s5_ant_reset_pos_' .. number)
		end,
		s6_screw_pos = function()
			return field_util.get_marker_pos('s6_screw_pos')
		end,
		s6_potion_pos = function()
			return field_util.get_marker_pos('s6_potion_pos')
		end
	}

	-- fx
	-- 원라인 controller에서 호출중인 fx도 여기서 로드
	self.fx = metatable_helper.create_fx_accessor({
		custom_sprite = function()
			return unity_object_pool.GetOrCreate('custom_sprite')
		end,
		hit = function()
			return unity_object_pool.GetOrCreate('FX_hit')
		end,
		gun_fire = function()
			return unity_object_pool.GetOrCreate('FX_Common_BasicShot_Gun')
		end,
		snow_camera = function()
			return unity_object_pool.GetOrCreate('fx_noel_stage_snow_camera_new_inside')
		end,
		explosion_bomb = function()
			return unity_object_pool.GetOrCreate('FX_Explosion_Bomb_new')
		end,
		war_grid_screen_fx = function()
			return unity_object_pool.GetOrCreate('fx_stage1_spark_screen_fx_noel')
		end,
		war_grid_smoke_fx = function()
			return unity_object_pool.GetOrCreate('fx_fire_smoke_right_view_weak_noel')
		end,
		smoke_fx = function()
			return unity_object_pool.GetOrCreate('fx_fire_smoke_right_view_weak_noel')
		end,
		landslide_brown_small = function()
			return unity_object_pool.GetOrCreate('fx_rock_landslide_brown_small_noel')
		end,
		reset = function()
			return unity_object_pool.GetOrCreate('FX_reset_object')
		end,
	})

	-- field object
	self.fo = {
		bookcase = function()
			return get_field_object('s9_bookcase')
		end,
		comic_book = function()
			return get_field_object('s9_comic_book')
		end,
		book_open = function()
			return get_field_object('s9_book_open')
		end,
		diary = function()
			return get_field_object('s9_diary')
		end,
	}

	-- 스테이지 관리 sprite들
	self.stage_item_list = metatable_helper.inherit({
		container = nil
	}, {
		add_item = function(this, item)
			if this.container == nil then
				this.container = {}
			end

			table.insert(this.container, item)
		end,
		pop_item = function(this, unique_id)
			for i, item in ipairs(this.container) do
				if item.UniqueId == unique_id then
					local pop_item = item

					table.remove(this.container, i)

					return pop_item
				end
			end
		end,
		dispose_all = function(this)
			if this.container == nil then
				return
			end

			for i, item in ipairs(this.container) do
				quest_drop_item_util.dispose_item(item)
			end

			this.container = nil
		end
	})

	-- 카메라 부착 fx 관리용
	self.camera_fx = nil
	self.camera_fx_info = {
		progress = 12,
		grid_list = {
			'main_grid_1',
			'main_grid_2',
			'main_grid_3',
			'fly_grid',
			'war_upper_grid',
			'ant_grid',
			'war_grid',
			'bomb_bug_racing_fly_grid'
		}
	}

	-- 표지판 제거용
	self.sign_board_info = {
		count = 4,
		name = 's13_sign_board_',
		progress = 12
	}

	-- snow layer 활성화용
	self.snow_layer_info = metatable_helper.inherit({
		progress = 12,
		count = 4,
	}, {
		set_active = function(this, progress)
			local is_active = this.progress <= progress
			local snow_layer = stage.StageGameObject.transform:Find(stage.Name .. '/snow/')
			snow_layer.gameObject:SetActive(is_active)

			--TODO: 레이어 더 추가되서 처리 (1~4 아닌거 불편)
			for i = 2, this.count do
				snow_layer = stage.StageGameObject.transform:Find(stage.Name .. '/snow' .. i .. '/')
				snow_layer.gameObject:SetActive(is_active)
			end
		end
	})

	-- war grid 총알 처리용
	self.res_holder = nil
	self.war_grid_bullets = {}
	self.bullet_pool_count = 2
	self.bullet_req_cnt = 0

	-- war grid 반복 루틴 처리용
	self.shoot_npc_req_cnt = 0
	self.shoot_helpers = nil

	-- stage exit 처리용
	self.is_stage_exit = false

	-- bgm 처리용
	self.bgm_info = {
		-- 미니게임 진입 전 탑승 해제 관련 처리용
		can_change_bgm = true,
		bgm_name = 'ondemand/short_story_noel/audio:bgm_flight_02',
		origin_bgm_name = 'bgm_flight',
		current_bgm_state = nil,
		current_stage_bgm_name = nil
	}

	-- 노움 광장 촌장
	self.house_gnome_bishop_info = metatable_helper.inherit({
		name = 'oneline_gnome_bishop',
		marker = 'oneline_gnome_bishop_pos',
		zone = 'oneline_gnome_zone',
		check_speech = false,
		talk_key = nil,
		info = {
			{
				direction = 'down',
				anim = 'idle',
				emotion = 'tired',
				speech_key = 'ss_noel_oneline_bishop_1',
				progress = {
					to = 0,
					from = 5
				},
			},
			{
				direction = 'down',
				anim = 'idle',
				emotion = 'tired',
				speech_key = 'ss_noel_oneline_bishop_1',
				progress = {
					to = 7,
					from = 8
				},
			},
			{
				direction = 'down',
				anim = 'idle',
				emotion = 'smile',
				speech_key = 'ss_noel_oneline_bishop_2',
				progress = {
					to = 12,
					from = 100
				},
			}
		}
	}, {
		set_npc = function(this, target_progress)
			local npc = get_character(this.name)

			for i, info in ipairs(this.info) do
				if info.progress.to <= target_progress and info.progress.from >= target_progress then

					character_util.set_position(npc, field_util.get_marker_pos(this.marker))
					character_util.set_direction(npc, info.direction)
					scene_util.set_anim(npc, self, { name = info.anim, sfx_name = false, one_shot_sfx = false })
					scene_util.set_emotion(npc, self, info.emotion)
					this.talk_key = info.speech_key
					return
				end
			end

			character_util.set_position(npc, vector(999, 0, 999))
			this.talk_key = nil
			this.check_speech = false
		end
	})

	-- main field shake 영역
	self.house_shake_grid_info = metatable_helper.inherit({
		zone_name = 'main_field',
		grid_name = 'main_grid_',
		marker_name = 'main_grid_shake_pos_',
		grid_number = 2,
		progress = {
			to = 2,
			from = 8
		},
		index = {
			{ 1, 2, 3 },
			{ 4, 5 },
			{ 6, 7 },
		},
		req_cnt = 0
	}, {
		shake_routine = function(this)
			this.req_cnt = this.req_cnt + 1
			local req_cnt = this.req_cnt

			local duration = 6
			local delay = 9

			while req_cnt == this.req_cnt do
				duration = duration + unity_class.time.deltaTime

				if delay <= duration then
					duration = 0

					music_player_util.play_sfx_one_shot('01_earthquake_08')

					--1,2번 지점에 fx_rock_landslide_brown_small_noel 이펙트 출력
					for i = 1, #this.index[this.grid_number] do
						local fx_pos = field_util.get_marker_pos(this.marker_name .. this.index[this.grid_number][i])
						local offset = vector(0, 1, -1)

						self.fx.landslide_brown_small():Instantiate(fx_pos + offset)
					end

					--화면 0.2값으로 1초 shake
					camera_util.shake(0.1, 1)
				end

				coroutine.yield()
			end
		end
	})

	--ant soldier 발각용
	self.detected_info = {
		ant = {
			is_detected = false,
			event_name = 's5_ant_detect',
			deactive_progress = 9,
			count = 12
		},

		rat = {
			is_detected = false,
			event_name = 'zootopia_mafia_rat_detect'
		},
	}

	-- pushable gimmick reset 처리용
	self.gimmick_reset_info = metatable_helper.inherit({
		info = {
			{
				zone = 'gimmick_reest_1_zone',
				switch = 'puzzle_reset_switch_1',
				pushable = {
					{ name = 'puzzle_1_pushable_1', reset_pos = unity_class.vector3.zero },
					{ name = 'puzzle_1_pushable_2', reset_pos = unity_class.vector3.zero },
					{ name = 'puzzle_1_pushable_3', reset_pos = unity_class.vector3.zero },
				},
			},
			{
				zone = nil,
				switch = 'puzzle2_reset_switch_1',
				pushable = {
					{ name = 'puzzle_2_pushable_1', reset_pos = unity_class.vector3.zero },
					{ name = 'puzzle_2_pushable_2', reset_pos = unity_class.vector3.zero },
					{ name = 'puzzle_2_pushable_3', reset_pos = unity_class.vector3.zero },
					{ name = 'puzzle_2_pushable_4', reset_pos = unity_class.vector3.zero },
				},
			},
		}
	}, {
		init_setting = function(this)
			for i = 1, #this.info do
				for j = 1, #this.info[i].pushable do
					this.info[i].pushable[j].reset_pos = get_field_object(this.info[i].pushable[j].name).Position
				end
			end
		end,
		switch_on_reset = function(this, switch)
			for i = 1, #this.info do
				if lua_helper.reference_equals(switch, get_field_object(this.info[i].switch)) then
					for j = 1, #this.info[i].pushable do
						this:reset_object(get_field_object(this.info[i].pushable[j].name), this.info[i].pushable[j].reset_pos)
					end

					break
				end
			end
		end,
		zone_enter_reset = function(this, e)
			for i = 1, #this.info do
				if this.info[i].zone ~= nil then
					for j = 1, #this.info[i].pushable do
						local pushable = get_field_object(this.info[i].pushable[j].name)

						if type_util.is_zone_full_enter(e, pushable, this.info[i].zone) then
							this:reset_object(pushable, this.info[i].pushable[j].reset_pos)
							return
						end
					end
				end
			end
		end,
		reset_object = function(this, target, reset_pos)
			if vector_util.is_almost_zero(target.Position - reset_pos) then
				return
			end

			local effect_size = target.Bounds.size

			local prev_pos_effect = self.fx.reset():Instantiate(target.Bounds.center)
			prev_pos_effect.transform.localScale = effect_size

			message_system:Send(target, CS.Oak.MoveBlockedEvent.Create(nil, unity_class.vector3.zero))
			target.Position = reset_pos

			local current_pos_effect = self.fx.reset():Instantiate(target.Bounds.center)
			current_pos_effect.transform.localScale = effect_size
		end
	})
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.VehicleRidingStateChangeEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))

	self:dispose_bullet()
	self:dispose_camera_fx()

	self.house_shake_grid_info.req_cnt = -10

	self.shoot_helpers = nil

	self.stage_item_list:dispose_all()
	self.stage_item_list = nil

	self.quest_progress = nil
	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.VehicleRidingStateChangeEvent), 'on_vehicle_riding_stage_change_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_switch_on_off_event')
end

--region event
function local_class:on_event(e)
	return false
end

function local_class:on_stage_end_event(e)
	self.shoot_npc_req_cnt = -10
	self.bullet_req_cnt = -10
	self.house_shake_grid_info.req_cnt = -10
	self.is_stage_exit = true
	return true
end

function local_class:on_zone_enter_event(e)
	self.gimmick_reset_info:zone_enter_reset(e)

	if not self.house_gnome_bishop_info.check_speech and
			self.house_gnome_bishop_info.talk_key ~= nil and
			type_util.is_zone_full_enter(e, get_party_leader(), self.house_gnome_bishop_info.zone) then
		self.house_gnome_bishop_info.check_speech = true
		start_coroutine(function()
			local npc = get_character(self.house_gnome_bishop_info.name)
			scene_util.show_normal_speech_async(npc, self.house_gnome_bishop_info.talk_key, false)
		end)

		return true
	end

	if self.quest_progress ~= nil and
			self.quest_progress.InnerProgress >= self.house_shake_grid_info.progress.to and
			self.quest_progress.InnerProgress <= self.house_shake_grid_info.progress.from and
			type_util.is_zone_full_enter(e, get_party_leader(), self.house_shake_grid_info.zone_name) then
		start_coroutine(self.house_shake_grid_info.shake_routine, self.house_shake_grid_info)

		return true
	end

	return false
end

function local_class:on_zone_leave_event(e)
	if self.quest_progress ~= nil and
			self.quest_progress.InnerProgress >= self.house_shake_grid_info.progress.to and
			self.quest_progress.InnerProgress <= self.house_shake_grid_info.progress.from and
			type_util.is_zone_full_leave(e, get_party_leader(), self.house_shake_grid_info.zone_name) then
		self.house_shake_grid_info.req_cnt = self.house_shake_grid_info.req_cnt + 1

		return true
	end

	return false
end

function local_class:on_camera_grid_enter_event(e)
	if self.quest_progress ~= nil and
			self.quest_progress.InnerProgress > 0 and
			self.quest_progress.InnerProgress < 10 and
			type_util.is_player_enter_to_cam_grid(e, 'war_grid') then
		start_coroutine(self.bullet_routine, self)

		return true
	end

	if self.quest_progress ~= nil and
			self.quest_progress.InnerProgress >= self.house_shake_grid_info.progress.to and
			self.quest_progress.InnerProgress <= self.house_shake_grid_info.progress.from then

		for i = 1, #self.house_shake_grid_info.index do
			if type_util.is_player_enter_to_cam_grid(e, self.house_shake_grid_info.grid_name .. i) then
				self.house_shake_grid_info.grid_number = i

				return true
			end
		end
	end

	if type_util.is_player_enter_to_cam_grid(e, 'diary_grid') then
		field_util.tint('diary_tint', unity_color({ 0.5, 0.5, 0.5, 1 }), 0.7)

		return true
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= self.camera_fx_info.progress then
		for i = 1, #self.camera_fx_info.grid_list do
			if type_util.is_player_enter_to_cam_grid(e, self.camera_fx_info.grid_list[i]) or
					lua_helper.reference_equals(e.FieldObject, self.npcs.bombbug_friend_myth()) then
				self:set_snow_camera_fx()
				return true
			end
		end

		self:dispose_camera_fx()
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if type_util.is_player_leave_to_cam_grid(e, 'war_grid') then
		self.shoot_npc_req_cnt = self.shoot_npc_req_cnt + 1
		self.bullet_req_cnt = self.bullet_req_cnt + 1

		return true
	end

	if type_util.is_player_leave_to_cam_grid(e, 'diary_grid') then
		field_util.remove_tint('diary_tint', 0.7)

		return true
	end

	return false
end

function local_class:on_vehicle_riding_stage_change_event(e)
	if not self.bgm_info.can_change_bgm then
		return false
	end

	if e.State == CS.Oak.FlyingVehicleBehaviour.FlyState.Ascending then
		self:change_flying_bgm()

		return true
	elseif e.State == CS.Oak.FlyingVehicleBehaviour.FlyState.Descending then
		self:recover_flying_bgm()

		return true
	end

	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId ~= self.main_quest_id then
		return false
	end

	self.house_gnome_bishop_info:set_npc(e.CurrentProgress)
	self:dispose_sign_board(e.CurrentProgress)

	if e.CurrentProgress == 10 then
		self:end_set_war_grid()
	end

	if self.detected_info.ant.deactive_progress <= e.CurrentProgress then
		self:de_active_ant()
	end

	self.snow_layer_info:set_active(e.CurrentProgress)

	return true
end

function local_class:on_custom_stage_event(e)
	if not self.detected_info.ant.is_detected and e.Params[0] == self.detected_info.ant.event_name then
		self.detected_info.ant.is_detected = true
		sp_util.start_scene(self.detected_scene, self, e.Sender)

	elseif not self.detected_info.rat.is_detected and e.Params[0] == self.detected_info.rat.event_name then
		self.detected_info.rat.is_detected = true
		sp_util.start_scene(self.detected_scene_by_rats, self, e.Sender)

	end

	return false
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn then
		self.gimmick_reset_info:switch_on_reset(e.SwitchObject)
	end

	return false
end
--endregion event

-- 해당 컨트롤러에서 스테이지 런치가 필요할 시 주석 풀고 사용할 것
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.launch_routine, self)
end

function local_class:launch_routine()
	self.quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self.gimmick_reset_info:init_setting()
	self.fx:load_async()

	self:set_s1_npc()
	self:set_s1_help_npc()
	self:set_laboratory_item()
	self:set_machine_old()
	self:set_table_item()
	self:set_war_grid_bullet()
	self.house_gnome_bishop_info:set_npc(self.quest_progress.InnerProgress == nil and 0 or self.quest_progress.InnerProgress)
	self:dispose_sign_board(self.quest_progress.InnerProgress == nil and 0 or self.quest_progress.InnerProgress)
	self.snow_layer_info:set_active(self.quest_progress.InnerProgress == nil and 0 or self.quest_progress.InnerProgress)
	self:set_bombbug()

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress > 0 and self.quest_progress.InnerProgress <= 8 then
		music_player_util.start_bgm_manager()
	end

	-- 순찰 개미
	if self.quest_progress == nil or self.quest_progress.InnerProgress <= 8 then
		local ant_count = 12

		for i = 1, ant_count do
			local ant = self.npcs.s5_ant(i)

			scene_util.set_anim(ant, self, i <= 6 and 'rifle_idle' or 'rifle_walk')
			ant.OverrideCrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		end
	end

	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 12 then
		field_object_util.set_active_state(self.npcs.bombbug_friend(), active_state_type.disabled)
	else
		field_object_util.set_active_state(self.npcs.bombbug_friend_myth(), active_state_type.disabled)
	end

	-- 퀘스트 클리어 후 jump exit 제거
	if self.quest_progress ~= nil and self.quest_progress.IsComplete then
		field_object_util.set_active_state(get_field_object('s13_exit'), active_state_type.disabled)
	end

	stage_start_util.start_function(self.quest_progress)
end

--region s1~s10 npc 배치
--- s1부터 s10까지 배치되는 npc
--- s2에 상호작용 및 이후 애니메이션이 달라짐
function local_class:set_s1_help_npc()
	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 10 then
		return
	end

	local set_info

	if self.quest_progress == nil or self.quest_progress.InnerProgress < 2 then
		set_info = {
			--노움A(남) (right, damaged, sleep 자세로 0.03값 shake 지속)
			{
				dir = 'right',
				emotion = 'damaged',
				anim = 'sleep',
				talk = 'ss_noel_main_s2_oneline_9',
				sfx = '01_rustle_01',
				shake = true
			},
			--노움B(여) (left, damaged, sleep 자세로 0.03값 shake 지속)
			{
				dir = 'left',
				emotion = 'damaged',
				anim = 'sleep',
				talk = 'ss_noel_main_s2_oneline_10',
				sfx = '01_rustle_01',
				shake = true
			},
			--노움C(남) (right, damaged, sleep)
			{
				dir = 'right',
				emotion = 'damaged',
				talk = 'ss_noel_main_s2_oneline_11',
				anim = 'sleep',
			},
		}
	else
		set_info = {
			--노움A(남) (right, tired, seat)
			{
				dir = 'right',
				emotion = 'tired',
				anim = 'seat',
				talk = 'ss_noel_main_s2_oneline_12',
			},
			--노움B(여) (left, tired, seat)
			{
				dir = 'left',
				emotion = 'tired',
				anim = 'seat',
				talk = 'ss_noel_main_s2_oneline_13',
			},
			--노움C(남) (right, tired, seat)
			{
				dir = 'right',
				emotion = 'tired',
				anim = 'seat',
				talk = 'ss_noel_main_s2_oneline_14',
			},
		}
	end

	for i, info in ipairs(set_info) do
		local gnome = self.npcs.s1_help_gnome(i)

		character_util.set_position(gnome, self.markers.s1_gnome_help_pos(i))
		character_util.set_direction(gnome, info.dir)
		scene_util.set_emotion(gnome, self, info.emotion)
		scene_util.set_anim(gnome, self, { name = info.anim, sfx_name = false, one_shot_sfx = false })
		gnome.Interactable.Talk = info.talk

		if info.sfx then
			gnome.Interactable.TalkSfx = info.sfx
		end

		if info.shake then
			character_util.shake(gnome, 0.03, 999999)
		end
	end
end

--- s1부터 s10까지 배치되는 npc
function local_class:set_s1_npc()
	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 10 then
		return
	end

	--노움 대장(할아버지) (right, attack, release)
	local gnome_commander = self.npcs.gnome_commander()

	character_util.set_position(gnome_commander, self.markers.s1_gnome_commander_pos())
	scene_util.set_emotion(gnome_commander, self, 'attack')

	if self.quest_progress == nil or self.quest_progress.InnerProgress < 2 then
		character_util.set_direction(gnome_commander, 'right')
		scene_util.set_anim(gnome_commander, self, { name = 'release', sfx_name = false })
	else
		--노움 대장(할아버지) (left, attack, salute 정지자세) : 웃는 얼굴님의 가호가 함께하길!
		character_util.set_direction(gnome_commander, 'left')
		scene_util.set_anim(gnome_commander, self, { name = 'salute', one_shot_sfx = false })
		gnome_commander.Interactable.Talk = 'ss_noel_main_s2_43'
		gnome_commander.Interactable.TalkSfx = '02_twohand_stomp_jump_01'
	end
end

--- 총알 세팅
function local_class:set_war_grid_bullet()
	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 10 then
		return
	end

	self.res_holder = CS.Foundations.ResourceHolder()

	local prefab = load_util.load_prefab_async(self.res_holder,
			'spritesheets/projectiles', 'projectiles_custom')

	local custom_atlas
	custom_atlas = prefab.transform:GetComponent(typeof(CS.CustomAtlas))
	custom_atlas:Initialize()

	self.war_grid_bullets = {}

	for i = 1, self.bullet_pool_count do
		local bullet = self.fx.custom_sprite():Instantiate(unity_class.vector3.one)
		local bullet_sprite = bullet.transform:GetComponent(typeof(CS.CustomSprite))
		bullet_sprite.transform.localPosition = vector(999, 0, 999)
		bullet_sprite.transform.localRotation = unity_class.quaternion.Euler(0, 0, 0)
		bullet_sprite.transform.localScale = unity_class.vector3.one
		bullet_sprite.LocalScale = unity_class.vector2.one
		bullet_sprite.Atlas = custom_atlas
		bullet_sprite.SpriteName = 'small_shot_normal.png'
		bullet_sprite:Rebuild()

		table.insert(self.war_grid_bullets, {
			bullet = bullet,
			start_pos = vector_util.get_x0z(self.markers.s1_bullet_start_pos(i), 0.5),
			target_pos = vector_util.get_x0z(self.markers.s1_bullet_end_pos(i), 0.5),
			active = false,
			speed = 10,
			delay = 0.5,
			cur_delay = 0.5 * (i - 1),
			cur_duration = 0,
			duration = 0.5
		})
	end
end

--- 총알 날라오는 루틴
function local_class:bullet_routine()
	self.bullet_req_cnt = self.bullet_req_cnt + 1

	local req_cnt = self.bullet_req_cnt

	while self.bullet_req_cnt == req_cnt do
		local dt = unity_class.time.deltaTime

		for i, info in ipairs(self.war_grid_bullets) do
			if info.active then
				info.cur_duration = info.cur_duration + dt

				local shoot_dir = (info.target_pos - info.start_pos).normalized
				info.bullet.transform.localRotation = unity_class.quaternion.LookRotation(shoot_dir)
						* unity_class.quaternion.Euler(90, 0, 0)
				info.bullet.transform.position = unity_class.vector3.Lerp(info.start_pos, info.target_pos,
						unity_class.mathf.Clamp01(info.cur_duration / info.duration))
			else
				info.cur_delay = info.cur_delay + unity_class.time.deltaTime
			end

			if info.delay <= info.cur_delay then
				info.active = true
				info.cur_delay = 0

				info.bullet.transform.position = info.start_pos
			end

			if info.duration <= info.cur_duration then
				info.active = false
				info.cur_duration = 0

				self.fx.hit():Instantiate(info.bullet.transform.position)
				info.bullet.transform.position = vector(999, 0, 999)
			end
		end

		coroutine.yield()
	end
end

--- 총알 관련 dispose
function local_class:dispose_bullet()
	if self.war_grid_bullets ~= nil then
		for i, info in ipairs(self.war_grid_bullets) do
			info.bullet:Dispose()
		end

		self.war_grid_bullets = nil
	end

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
		self.res_holder = nil
	end
end

function local_class:end_set_war_grid()
	local help_gnome_count = 3

	for i = 1, help_gnome_count do
		field_object_util.set_active_state(self.npcs.s1_help_gnome(i), active_state_type.disabled)
	end

	field_object_util.set_active_state(self.npcs.gnome_commander(), active_state_type.disabled)

	self:dispose_bullet()
end
--endregion s1~s10 npc 배치

--region 박사 연구실
---연구실 배치
function local_class:set_laboratory_item()
	-- 다이어리 아이템 배치
	local diary_item = quest_drop_item_util.create_item({
		item_id = 21728,
		unique_id = 21728,
		pos = vector_util.get_x0z(self.markers.s3_diary_pos(), 1.1),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(diary_item)

	local comic_book_item = quest_drop_item_util.create_item({
		item_id = 21753,
		unique_id = 21753,
		pos = self.fo.comic_book().Position,
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(comic_book_item)

	local open_book_item = quest_drop_item_util.create_item({
		item_id = 21756,
		unique_id = 21756,
		pos = vector_util.get_x0z(self.fo.book_open().Position, 1.1),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(open_book_item)

	local paper_item = quest_drop_item_util.create_item({
		item_id = 21755,
		unique_id = 21755,
		pos = vector_util.get_x0z(self.fo.diary().Position, 0.7),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(paper_item)

	-- 책장 위치 이동
	if self.quest_progress ~= nil and self.quest_progress.InnerProgress >= 9 then
		self.fo.bookcase().Position = self.fo.bookcase().Position + vector(-2, 0, 0)
	end
end

---s3~s8 머신 배치
function local_class:set_machine_old()
	if self.quest_progress == nil or self.quest_progress.InnerProgress < 2 or self.quest_progress.InnerProgress >= 8 then
		return
	end

	---플레이어가 shortstory_noel_machine_old (임시) 스파인 인터렉트 시, 하단의 나레이션 박스 출력.
	local machine_old = self.npcs.machine_old()

	--「박사님의 미완성된 발명품이 놓여있다.」
	local narration_interactable = CS.Oak.NarrationInteractable()
	narration_interactable.StringKeys = {
		'ss_noel_main_s3_0',
	}

	machine_old.Interactable = narration_interactable

	character_util.set_position(machine_old, self.markers.s3_machine_old_pos() + vector(-0.2, 0, 0.5))
	field_ui_manager:RemoveUI(machine_old, CS.Oak.FieldUiType.CharacterStats)
	machine_old.SpineController.SpineOffset = vector(0, 1, 0)
	machine_old.Hitbox = CS.Oak.Hitbox(vector(1.3, 1, 1))
end

---s7~s8 책상 위 부품 아이템 배치
function local_class:set_table_item()
	if self.quest_progress == nil or self.quest_progress.InnerProgress < 6 or self.quest_progress.InnerProgress >= 8 then
		return
	end

	-- 나사 아이템
	local screw_item = quest_drop_item_util.create_item({
		item_id = 21732,
		unique_id = 21732,
		pos = vector_util.get_x0z(self.markers.s6_screw_pos(), 1.1),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(screw_item)

	-- 포션 아이템
	local potion_item = quest_drop_item_util.create_item({
		item_id = 21733,
		unique_id = 21733,
		pos = vector_util.get_x0z(self.markers.s6_potion_pos(), 1.1),
		loot_state = quest_drop_item_loot_state.dont_find_looter,
		skip_text = true
	})

	self.stage_item_list:add_item(potion_item)
end
--endregion 박사 연구실

--region 폭탄벌레 탑승 bgm 변경
function local_class:change_flying_bgm()
	self.bgm_info.current_bgm_state = music_player.StageBgmState
	self.bgm_info.current_stage_bgm_name = music_player.CurrentStageMusicName

	if self.bgm_info.current_bgm_state == stage_bgm_state.fanfare or
			self.bgm_info.current_bgm_state == stage_bgm_state.theatre then
		self.bgm_info.current_bgm_state = stage_bgm_state.field
	end

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)
	local bgm_name = quest_progress.InnerProgress >= 12 and self.bgm_info.origin_bgm_name or self.bgm_info.bgm_name

	music_player_util.play_stage_music({ name = bgm_name, state = 'event' })
end

function local_class:recover_flying_bgm()
	music_player_util.play_stage_music({ state = 'muted' })

	if self.bgm_info.current_bgm_state == stage_bgm_state.event then
		music_player_util.play_stage_music({ name = self.bgm_info.current_stage_bgm_name, state = 'event' })
	else
		music_player:PlayStageMusic(self.bgm_info.current_bgm_state)
	end
end
--endregion 폭탄벌레 탑승 bgm 변경

--region s5~s10 순찰 개미
--- 발각 됐을 경우
function local_class:detected_scene(sender)
	local leader = get_party_leader()
	local cashed_speed = sender.FieldObjectStatsBehaviour.CharacterSpec.WalkSpeed
	local ant_count = 12

	for i = 1, ant_count do
		local ant = self.npcs.s5_ant(i)

		ant.FieldObjectStatsBehaviour.CharacterSpec.WalkSpeed = 0
		scene_util.set_anim(ant, self, 'rifle_idle')
	end

	music_player_util.change_stage_music_volume('field', 0.6)

	--화면 0.3값으로 0.5초 shake.
	camera_util.shake(0.3, 0.5)
	--노엘이 개미 NPC를 향해 방향 회전
	character_util.look_at(leader, sender)
	--노엘 surprise 표정, embarrassed 자세로 jump 1회
	scene_util.set_emotion(leader, self, 'surprise')
	scene_util.set_anim(leader, self, 'embarrassed')
	character_util.normal_jump(leader, true)
	--개미 NPC가 노엘 캐릭터를 향해 방향 회전
	character_util.look_at(sender)
	--개미 attack 표정, rifle_reload 자세 1회.
	scene_util.set_emotion(sender, self, 'attack')
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	music_player_util.play_sfx_one_shot('02_gun_reload_06')
	scene_util.set_anim(sender, self, { name = 'rifle_reload', loop = false, next_anim = 'rifle_idle' })
	--개미 : [shout]여기 노움 녀석이 있다!!
	scene_util.show_shout_speech_async(sender, 'ss_noel_main_s5_1')

	music_player_util.play_sfx_one_shot('01_drown_02')
	screen_util.fade_out_circular_async(0.6)

	--개미 4,5,6 에게 발각되었을 경우
	--리셋2 지점(s5_ant_reset_pos_2)에서 left 방향으로 리스폰.
	--개미 7,8,9,10,11,12 에게 발각 되었을 경우
	--리셋3 지점(s5_ant_reset_pos_3)에서 right 방향으로 리스폰.
	local index_list = { 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3 }
	local anim_list = { 'rifle_idle', 'rifle_idle', 'rifle_idle', 'rifle_idle', 'rifle_idle', 'rifle_idle',
						'rifle_walk', 'rifle_walk', 'rifle_walk', 'rifle_walk', 'rifle_walk', 'rifle_walk' }

	for i = 1, ant_count do
		local ant = self.npcs.s5_ant(i)

		ant.FieldObjectStatsBehaviour.CharacterSpec.WalkSpeed = cashed_speed

		if lua_helper.reference_equals(sender, ant) then
			character_util.set_position(leader, self.markers.s5_reset_pos(index_list[i]))
			character_util.set_direction(leader, self.markers.s5_reset_dir(index_list[i]))
			character_util.remove_anim_and_emotion(leader)

			message_system:Publish(CS.Oak.CustomStageEvent.Create(leader, { 'reset', self.detected_info.ant.event_name }))

			character_util.remove_emotion(sender)
		end
	end

	for i = 1, ant_count do
		scene_util.set_anim(self.npcs.s5_ant(i), self, anim_list[i])
	end

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.6)

	music_player_util.change_stage_music_volume('field', 1)

	self.detected_info.ant.is_detected = false
end

function local_class:de_active_ant()
	for i = 1, self.detected_info.ant.count do
		local ant = self.npcs.s5_ant(i)

		field_object_util.set_active_state(ant, active_state_type.disabled)
	end
end
--endregion 순찰 개미

--region 폭탄벌레 처리
function local_class:set_bombbug()
	local bombbug_count = 3

	for i = 1, bombbug_count do
		local bombbug = self.npcs.bombbug(i)

		field_ui_manager:RemoveUI(bombbug, CS.Oak.FieldUiType.CharacterStats)
	end
end
--endregion 폭탄벌레 처리

--region 카메라 부착 fx
function local_class:set_snow_camera_fx()
	if self.camera_fx ~= nil then
		return
	end

	self.camera_fx = self.fx.snow_camera():Instantiate(stage_camera.LookAtPosition,
			unity_class.quaternion.identity, stage_camera.transform)
end

function local_class:dispose_camera_fx()
	if self.camera_fx ~= nil then
		self.camera_fx:Dispose()
		self.camera_fx = nil
	end
end
--endregion 카메라 부착 fx

--region 표지판
function local_class:dispose_sign_board(progress)
	if self.sign_board_info.progress > progress then
		return
	end

	for i = 1, self.sign_board_info.count do
		field_object_util.set_active_state(get_field_object(self.sign_board_info.name .. i), active_state_type.disabled)
	end
end
--endregion 표지판

--region 서브 퀘스트 주토피아 s1 순찰 쥐
--- 발각 됐을 경우
function local_class:detected_scene_by_rats(sender)
	local leader = get_party_leader()

	music_player_util.change_stage_music_volume('field', 0.6)

	--마피아 쥐에게 노출당할 경우
	--컨트롤 뺏고 동시 연출
	--노엘 (현재 방향, surprise, embarrassed)
	scene_util.set_emotion(leader, self, 'surprise')
	scene_util.set_anim(leader, self, 'embarrassed')
	music_player_util.play_sfx_one_shot('03_runaway_01')

	--쥐가 노엘을 향해 방향 회전
	local origin_dir = sender.Direction
	character_util.look_at(sender, leader)

	--마피아 쥐 (적발 방향, mad, release 2회): 여긴 우리 구역이야!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.set_emotion(sender, self, 'mad')
	scene_util.set_anim(sender, self, { name = 'release', count = 2 })
	scene_util.show_shout_speech_async(sender, 'ss_noel_zootopia_watcher_1')

	--0.7초에 걸쳐 서큘러 페이드아웃.async
	music_player_util.play_sfx_one_shot('01_drown_01')
	screen_util.fade_out_circular_async(0.7)

	--리셋 위치 설정
	do
		local reset_marker_name = sender.FieldObjectController.ResetMarkerName
		local reset_marker = field_util.get_marker_pos(reset_marker_name)

		--별도 지정된 리셋 구역으로 이동한다.
		--플레이어 (right, damaged, prostrate)
		character_util.set_position(leader, reset_marker)
		character_util.set_direction(leader, 'right')
		scene_util.set_emotion(leader, self, 'damaged')
		scene_util.set_anim(leader, self, 'prostrate')

		if lua_helper.reference_equals(sender, self.npcs.watch_mafia(1)) or
				lua_helper.reference_equals(sender, self.npcs.watch_mafia(2)) then

			--리더가 6등급인지 확인 후 그에 따라 같은 6등급의 이브 셋팅
			local friend
			if lua_helper.reference_equals(user_party.Leader, self.npcs.noel()) then
				friend = self.npcs.bombbug_friend()
			elseif lua_helper.reference_equals(user_party.Leader, self.npcs.noel_myth()) then
				friend = self.npcs.bombbug_friend_myth()
			end

			friend.Position = reset_marker + vector(0, 0, -1)
			character_util.set_direction(friend, 'right')
		end

	end

	character_util.set_direction(sender, origin_dir)
	character_util.remove_anim_and_emotion(sender)

	wait_for_sec(0.5)

	--0.7초에 걸쳐 서큘러 페이드 인.async
	screen_util.fade_in_circular_async(0.6)

	--shake 2회 실행 후 마리오 점프로 기상
	--플레이어 컨트롤 돌려준다.
	scene_util.shake_and_wakeup(leader, leader.Direction, 2, nil, true)

	music_player_util.change_stage_music_volume('field', 1)

	self.detected_info.rat.is_detected = false
end
--endregion 순찰 쥐

return local_class
