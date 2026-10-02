local local_class = newclass('SideStoryBlossom2Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.main_quest_id = 60065
	self.quest_progress = nil

	-- marker
	self.marker = {
		crack_portal = function(pos_idx)
			return field_util.get_marker_pos('crack_effect_' .. pos_idx)
		end,
	}

	-- gimmick
	self.gimmick = {
		crack_portal = function(idx)
			return get_field_object('crack_portal_' .. idx)
		end,
		brazier = function()
			return get_field_object('s9_brazier')
		end,
	}

	self.fx = metatable_helper.create_fx_accessor({
		portal = function()
			return unity_object_pool.GetOrCreate('fx_bs_portalspawn_red_open')
		end,
	})

	self.cached_fx_list = nil

	-- 균열 포탈 갯수
	self.crack_portal_count = 3
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FallInHoleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))

	for _, fx in pairs(self.cached_fx_list) do
		if fx ~= nil then
			fx:Dispose()
		end
	end

	self.cs_controller = nil
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FallInHoleStartEvent), 'on_hole_in_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	--이동 가능한 균열 포탈 외 상호작용 처리
	for i = 2, self.crack_portal_count do
		local crack = self.gimmick.crack_portal(i)
		if lua_helper.reference_equals(e.Target, self.gimmick.crack_portal(i)) then
			local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

			if quest_progress == nil or quest_progress.InnerProgress >= 6 then
				start_coroutine(self.hole_interact_event, self, crack, i)
			else
				--짭기사 : 밥 선배님이 들어간 균열은 이쪽이 아니야.
				speech_bubble_util.show_speech_bubble(get_party_leader(), {
					key = 'bs_main_stage_2_1'
				})
			end

			return true
		end
	end

	return false
end

function local_class:on_hole_in_event(e)
	if lua_helper.reference_equals(e.Fool, self.gimmick.crack_portal(1)) then
		start_coroutine(function()
			music_player_util.play_sfx_one_shot('01_portal_11')

			music_player_util.change_stage_music_volume('field', 0, 0.5)

			wait_for_sec(0.5)

			music_player_util.play_stage_music({ state = 'muted' })

			wait_for_sec(0.5)

			music_player_util.play_stage_music({ name = 'bgm_teatans_main', state = 'event' })
		end)

		return true
	elseif lua_helper.reference_equals(e.Fool, self.gimmick.crack_portal(4)) then
		start_coroutine(function()
			music_player_util.play_sfx_one_shot('01_portal_11')

			music_player_util.change_stage_music_volume('event', 0, 0.5)

			wait_for_sec(0.5)

			music_player_util.play_stage_music({ state = 'muted' })

			wait_for_sec(0.5)

			music_player_util.play_stage_music({ state = 'field' })
		end)

		return true
	end
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, self.gimmick.brazier(), 'item_reset_zone') then
		message_system:SendSync(e.FieldObject, CS.Oak.GimmickResetEvent.Instance)

		return true
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	self.fx:create_all()

	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	if not quest_progress.IsComplete then
		-- 크리스탈 hit 키우기, ui 제거 및 WallCrashBehaviour 로 변경
		local red_crystal = get_character('red_crystal')

		field_object_util.set_active_state(red_crystal, active_state_type.enabled)

		red_crystal.Position = field_util.get_marker_pos('s10_center_pos_1')

		red_crystal.Hitbox = CS.Oak.Hitbox(vector(2.2, 1.5, 2.2))
		red_crystal.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		red_crystal.Transform.localScale = unity_class.vector3.one * 2

		red_crystal.Position = vector(red_crystal.Position.x, red_crystal.Position.y - 1, red_crystal.Position.z)
		red_crystal.SpineController.ShadowTransform.localPosition = vector(0, 0.03, 0) + vector(0, 0.5, 0)
		red_crystal.SpineController.ShadowTransform.localScale = unity_class.vector3.one * 0.5

		field_ui_manager:RemoveUI(red_crystal, CS.Oak.FieldUiType.CharacterStats)
	end
end

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
	local quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	stage_start_util.start_function(quest_progress)

	self:create_fx_effect()
end

function local_class:create_fx_effect()
	self.cached_fx_list = {}

	for i = 1, 4 do
		local portal_gimmick = self.gimmick.crack_portal(i)

		portal_gimmick.Position = portal_gimmick.Position + vector(-0.5, 0, -0.5)

		portal_gimmick.Hitbox = CS.Oak.Hitbox(vector(0.25, 0, 0.25), vector(2, 1, 2))

		local fx_portal = self.fx.portal():Instantiate(portal_gimmick.Position + vector(0.5, 0, 0.5))

		table.insert(self.cached_fx_list, fx_portal)
	end
end

function local_class:hole_interact_event(hole_fo, index)
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	music_player_util.play_sfx_one_shot('01_portal_11')

	music_player_util.play_sfx({
		sfx_name = '01_jump_01',
		play_pos = get_party_leader().Position,
		type_priority = 'battle_attack',
		player_priority = 'player',
	})

	local delay = 0.2
	local dir = index == 2 and 'down' or 'left'
	local target_pos = index == 2 and vector(-17.5, 0, 20) or vector(-27, 0, 28.5)

	stage_camera:SetTarget(nil)

	-- 홀 들어가는 연출
	self:hole_in_directing(hole_fo, delay, dir)

	-- 떨어지는 연출
	self:hole_fall_directing(delay, dir, target_pos)

	-- 나레이션
	field_ui_util.show_narration_async({ key = 'bs_main_stage_2_2' })

	camera_util.return_to_leader(0.2)

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:hole_in_directing(hole_fo, delay, dir)
	local jump_duration = 0.5

	local cur_user_party = get_user_party()

	start_coroutine(function()
		for i = 0, cur_user_party.Count - 1 do
			local fo = cur_user_party[i]

			local x_sign = unity_class.mathf.Sign(hole_fo.Bounds.center.x - hole_fo.Position.x)
			local z_sign = unity_class.mathf.Sign(hole_fo.Bounds.center.z - hole_fo.Position.z)

			local x_offset = 0.5 * (math.abs(hole_fo.Bounds.size.x) - 1) * x_sign
			local z_offset = 0.5 * (math.abs(hole_fo.Bounds.size.z) - 1) * z_sign

			local offset = vector(x_offset, 0.13, z_offset)
			local target_pos = hole_fo.Position + offset
			local dist = vector_util.magnitude(fo.Position - target_pos)

			scene_util.set_anim(fo, self, 'get')
			character_util.jump(fo, 1, jump_duration)

			local speed = math.max(1, dist / jump_duration)

			wp_util.move(fo, target_pos, speed, nil, {
				locked_dir = dir
			})

			start_coroutine(function()
				wait_for_sec(jump_duration - delay)
				character_util.spine_scale(fo, unity_class.vector3.zero, 0.27)
			end)

			wait_for_sec(delay)
		end
	end)

	wait_for_sec(0.3)

	screen_util.fade_out_circular_async(0.5, interpolations_constants.linear)
end

function local_class:hole_fall_directing(delay, dir, target_pos)
	wait_for_sec(0.5)

	local start_y = 12

	local bounce_cb = function(count)
		if count ~= 1 then
			return
		end

		music_player_util.play_sfx({ sfx_name = '01_land_01', type_priority = 'gimmick', player_priority = 'player' })
	end

	camera_util.move_async(target_pos, 0)

	local fall_cal_list = {}
	local cur_user_party = get_user_party()

	for i = 0, cur_user_party.Count - 1 do
		local fo = cur_user_party[i]

		character_util.stop(fo)
		character_util.spine_scale(fo, unity_class.vector3.one, 0)
		character_util.set_direction(fo, dir)

		scene_util.set_emotion(fo, self, 'damaged')
		scene_util.set_anim(fo, self, { name = 'embarrassed', one_shot_sfx = false })

		local fall_cal = CS.CalculatorFreeFall.Create(start_y, 12, 12, 1, bounce_cb)
		fall_cal:SetElasticity(0.3)
		fall_cal:ScaleTime(1.8)

		character_util.set_position(fo, vector(target_pos.x, fall_cal:GetDistance(), target_pos.z), true)

		table.insert(fall_cal_list, {
			fo = fo,
			cal = fall_cal
		})
	end

	screen_util.fade_in_circular(0.5, interpolations_constants.linear)

	local list_cal = fall_cal_list[#fall_cal_list]
	local current_time = 0

	while fall_cal_list ~= nil and not list_cal.cal:IsDone() do
		local dt = unity_class.time.deltaTime
		current_time = current_time + dt

		for i = 1, #fall_cal_list do
			local fo = fall_cal_list[i].fo
			local cal = fall_cal_list[i].cal

			local is_active = current_time > (delay * i)

			if not cal:IsDone() and is_active then
				cal:Proceed(dt)
				fo.Position = vector_util.get_x0z(fo.Position, cal:GetDistance())
			end
		end

		coroutine.yield(nil)
	end

	party_util.remove_anim_and_emotion()

	for i = 0, cur_user_party.Count - 1 do
		local fo = cur_user_party[i]
		character_util.set_position(fo, vector_util.get_x0z(target_pos))
	end
end

return local_class
