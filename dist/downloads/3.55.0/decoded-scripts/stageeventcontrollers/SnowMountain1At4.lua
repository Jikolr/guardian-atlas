local local_class = newclass('SnowMountain1At4Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.snowman_prince_name = 'snowman_prince'
	self.snowman_ice_name = 'snowman_ice_'
	self.log_name = 'log_'

	self.snowman_prince_zone_name = 'snowman_prince_last'
	self.laboratory_zone_name = "laboratory"

	self.snowman_prince_marker_name = 'snowman_prince_last'
	self.log_marker_name = 'log_'

	self.snowman_ice_num = 12
	self.log_num = 6
	self.log_item_id = 20093
	self.last_log_item_id = 20094

	self.log_string_key = 'snowmountain_1_4_log_'

	self.log_item_list = nil

	self.see_prince_event = false

	self.guard_follower_id = 46

	self.guard_training_coroutine = nil
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), "on_event")
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), "on_event")
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), "on_event")
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), "on_event")

	unity_object_pool.GetOrCreate('fx_common_water_splash_in')
	unity_object_pool.GetOrCreate('fx_common_water_splash_out')

	local main_quest = user_progress:GetStartedQuest(19)
	local snowman_prince = get_character(self.snowman_prince_name)

	if main_quest ~= nil and main_quest.InnerProgress > 7 and main_quest.InnerProgress < 11 and
		main_quest:GetCustomState("see_prince_event") ~= 1 then
		character_util.set_position(snowman_prince, field:GetMarker(self.snowman_prince_marker_name).position)
		character_util.set_direction(snowman_prince, 'right')
		character_util.set_anim(snowman_prince, { name = 'cast' })
	end

	for i = 1, self.snowman_ice_num do
		local ice = get_character(self.snowman_ice_name .. i)
		character_util.set_anim(ice, { name = 'ice' })
		ice.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance;
	end

	quest_icon:PreLoad()

	return
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self:laura_log_event_dispose()

	local guard = get_character('priest_bodyguard')
	guard.Interactable:RemoveRelatedEvent(self.cs_controller)

	self.guard_training_coroutine = nil

	self.log_item_list = nil

	self.cs_controller = nil
end

function local_class:on_event(e)
	local event_type = e:GetType()

	self:laura_log_on_event(e)

	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		self:on_zone_leave_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)
	self.log_item_list = create_generic_list(CS.Oak.DropItem)

	for i = 1, self.log_num do
		local log_marker = field:GetMarker(self.log_marker_name .. i)

		if i ~= self.log_num then
			self.log_item_list:Add(drop_item_util.create_item({ pos = log_marker.position, itemid = self.log_item_id, notforinven = true, lootstate = 'dontfindlooter' }))
		else
			self.log_item_list:Add(drop_item_util.create_item({ pos = log_marker.position, itemid = self.last_log_item_id, notforinven = true, lootstate = 'dontfindlooter' }))
		end
	end

	self:laura_log_event_setting()
	self.guard_training_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.body_guard_training, self))
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter and e.FieldObject == user_party_leader and e.Zone.Name == self.snowman_prince_zone_name then
		-- 설인 왕자가 플레이어와 같은 그리드에 없을 경우 이벤트 진행 준비가 되지 않은 것이므로 스킵
		local snowman_prince = get_character(self.snowman_prince_name)

		if field:IsInSameCameraGrid(user_party_leader.Position, snowman_prince.Position) then
			if not self.see_prince_event then
				self.see_prince_event = true

				sp_util.play_normal_screenplay(self.snowman_prince_event, self)
			end
		end
	elseif e.FullEnter and e.FieldObject == user_party_leader and e.Zone.Name == self.laboratory_zone_name then
		music_player_util.play_stage_music({
			name = 'bgm_cave_main', state = 'event', mix = 1
		})

		field:Tint("laboratory", unity_color({0.6, 0.4, 0.4, 1}), 0)
	end
end

function local_class:on_zone_leave_event(e)
	if e.FullLeave and e.FieldObject == user_party_leader and e.Zone.Name == self.laboratory_zone_name then
		music_player_util.play_stage_music({
			state = 'field', mix = 1
		})

		field:RemoveTint("laboratory", 0)
	end
end

function local_class:on_interact_event(e)
	for i = 1, self.log_num do
		local log = get_field_object(self.log_name .. i)
		if lua_helper.reference_equals(e.Target, log) then
			sp_util.play_normal_screenplay(self.read_log, self, i)
			break
		end
	end

	local guard = get_character('priest_bodyguard')
	if lua_helper.reference_equals(e.Target, guard) then
		sp_util.play_normal_screenplay(self.guard_follow_event, self)
	end
end

-- 일지 읽는 이벤트
function local_class:read_log(index)
	stage.FieldUINarrationBox:Show()

	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(self.log_string_key..index.."_"..1), 0, 1.0))

	coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(self.log_string_key..index.."_"..2), 0, 1.0))

	if index ~= 4 then
		coroutine.yield(stage.FieldUINarrationBox:SetNarration(game_string:GetString(self.log_string_key..index.."_"..3), 0, 1.0))
	end

	stage.FieldUINarrationBox:Hide()

	wait_for_sec(0.3)
end

-- 설인 왕자 이벤트
function local_class:snowman_prince_event()
	local snowman_prince = get_character(self.snowman_prince_name)

	coroutine.yield(nil)

	party_util.align_party(vector(35, 0, -107.5), 'left', 1)

	wait_for_sec(1)

	music_player_util.play_sfx({ sfx_name = '01_swing_01' })

	character_util.set_direction(snowman_prince, 'left')

	wait_for_sec(0.3)

	music_player_util.play_sfx({ sfx_name = '01_jump_01' })
	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01' })

	speech_bubble_util.show_speech_bubble(snowman_prince, { key = 'snowmountain_1_4_snowman_prince_0' })
	character_util.jump(snowman_prince, 1, 0.5)
	character_util.set_anim(snowman_prince, { name = 'embarrassed' })
	character_util.set_emotion(snowman_prince, { name = 'scared' })

	wait_for_sec(0.5)

	character_util.remove_anim(snowman_prince)
	character_util.set_emotion(snowman_prince, { name = 'attack' })

	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(snowman_prince, { key = 'snowmountain_1_4_snowman_prince_1', skip = true })
	character_util.set_anim(snowman_prince, { name = 'release', sfx_name = "01_swing_01" })
	speech_bubble_util.show_speech_bubble_async(snowman_prince, { key = 'snowmountain_1_4_snowman_prince_2', skip = true })
	character_util.move_to_async(snowman_prince, vector(35, 0, -106.5), nil, 4, true, true)
	character_util.move_to_async(snowman_prince, vector(31, 0, -106.5), nil, 4, true, true)
	character_util.move_to_async(snowman_prince, vector(31, 0, -107.5), nil, 4, true, true)
	character_util.move_to_async(snowman_prince, vector(27, 0, -107.5), nil, 4, true, true)
	snowman_prince.ActiveState = active_state('disabled')
end

-- 로라에 관한 기록이 적혀있는 일기장과 상호작용하면 발생되는 이벤트
function local_class:interact_to_laura_log()
	local prefix = 'log_about_laura_'
	local count = 2

	for i = 1, count do
		local key = prefix .. i
		field_ui_util.show_narration_async({ key = key})
	end
end

function local_class:laura_log_event_setting()
	local log_npc = get_character('laura_log_npc')
	log_npc.Interactable:AddListener(self.cs_controller)

	local item_data = game_data_service.GetData('ItemData')
	local item_id = item_data:GetSpec('last_journal').Id
	local log_interact = get_field_object('laura_log_interact')
	local offset = vector(0, 0, -0.2)
	self.laura_log = drop_item_util.create_item(
			{itemid = item_id, pos = vector_util.get_x0z(log_interact.Position, 1) + offset, notforinven = true, amount = 1, lootstate = 'dontfindlooter'})
	self.laura_log.ShadowTransform.gameObject:SetActive(false)
end

function local_class:laura_log_event_dispose()
	if self.laura_log ~= nil then
		lua_helper.call_interface(self.laura_log, 'System.IDisposable', 'Dispose')
	end

	self.laura_log = nil
end

function local_class:laura_log_on_event(e)
	local event_type = e:GetType()

	local log = get_field_object('laura_log_interact')
	local log_npc = get_character('laura_log_npc')

	if event_type == typeof(CS.Oak.InteractEvent) then
		if lua_helper.reference_equals(e.Target, log) then
			sp_util.play_normal_screenplay(self.interact_to_laura_log, self)
		elseif lua_helper.reference_equals(e.Target, log_npc) then
			sp_util.play_normal_screenplay(self.talk_to_log_npc, self)
		end
	end
end

-- 로라 기록 일기장 옆의 NPC와 상호작용하면 발생하는 이벤트
function local_class:talk_to_log_npc()
	local npc = get_character('laura_log_npc')

	character_util.align_party(npc, 'left')

	speech_bubble_util.show_speech_bubble_async(npc, {key = 'log_about_laura_5', skip = true})

	speech_bubble_util.show_speech_bubble_async(npc, {key = 'log_about_laura_6', skip = true})
end

function local_class:body_guard_training()
	local guard = get_character('priest_bodyguard')
	local scarecrow = get_character('scarecrow_1')
	local marker_pos = {field:GetMarker('guard_1').position,
						field:GetMarker('guard_2').position, field:GetMarker('guard_3').position}
	while true do

		guard.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

		character_util.move_waypoint_async(guard, marker_pos[1], 3,
				true, nil, nil, nil, true)

		coroutine.yield(nil)

		local info = CS.Oak.WaypointMoveInfo.Create(
				marker_pos[2], 3, false, CS.Oak.Direction.Down)

		local jump_duration = info:GetDuration(guard.Position)

		character_util.jump(guard, 2, jump_duration)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(guard, info)

		character_util.set_anim(guard, {name = 'get'})
		music_player_util.play_sfx({sfx_name = '01_jump_01', play_pos = guard.Position})
		wait_for_sec(jump_duration)
		character_util.remove_anim(guard)

		unity_object_pool.GetOrCreate('fx_common_water_splash_in'):Instantiate(guard.Position)
		music_player_util.play_sfx({sfx_name = '01_dive_01', play_pos = guard.Position})

		character_util.shake(guard, 0.05, 2)
		character_util.set_emotion(guard, {name = 'tired'})
		character_util.set_anim(guard, {name = 'meditation'})

		wait_for_sec(2)

		character_util.remove_anim_and_emotion(guard)

		info = CS.Oak.WaypointMoveInfo.Create(
				marker_pos[1], 3, false, CS.Oak.Direction.Left)

		jump_duration = info:GetDuration(guard.Position)

		character_util.jump(guard, 2, jump_duration)
		CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(guard, info)

		unity_object_pool.GetOrCreate('fx_common_water_splash_out'):Instantiate(guard.Position)

		character_util.set_anim(guard, {name = 'get'})
		music_player_util.play_sfx({sfx_name = '01_jump_01', play_pos = guard.Position})
		wait_for_sec(jump_duration)
		character_util.remove_anim(guard)

		coroutine.yield(nil)

		character_util.move_waypoint_async(guard, marker_pos[3], 3,
				true, nil, nil, nil, true)

		guard.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

		-- 팔로우 안되어있을때만
		if not CS.Oak.UserProgress.Instance.Followers:Contains(self.guard_follower_id) then
			guard.Interactable:AddListener(self.cs_controller)
		end

		character_util.set_emotion(guard, {name = 'attack'})
		character_util.set_anim(guard, {name = 'gauntlet_combo_attack', loop = false})
		music_player_util.play_sfx({sfx_name = "02_hit_critical_01", play_pos = guard.Position, delayed_time = 0.2})

		wait_for_sec(0.2)

		character_util.spine_pulse_color(scarecrow, CS.Oak.Constants.DamageColor, 1, 0.3, 0.5)
		character_util.spine_damage_squish(scarecrow, 1.3, 0.7, 1, 0.3)

		music_player_util.play_sfx({sfx_name = "02_goblin_hit_01", play_pos = guard.Position, volume = 2})
		speech_bubble_util.show_speech_bubble_async(guard,
				{key = 'priest_bodyguard_1', bubble_type = 'shout'})
		--뜨호오오앗!

		character_util.remove_anim_and_emotion(guard)

		wait_for_sec(0.5)

		guard.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
end

function local_class:guard_follow_event()
	local guard = get_character('priest_bodyguard')

	guard.Interactable:RemoveRelatedEvent(self.cs_controller)

	if self.guard_training_coroutine ~= nil then
		stop_coroutine(self.guard_training_coroutine)
	end

	party_util.align_party(guard.Position, 'down', 1, 'arc')
	wait_for_sec(0.5)

	character_util.remove_anim_and_emotion(guard)
	character_util.set_direction(guard, 'down')

	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_2', skip = true})
	--방해하지 마라.

	character_util.set_direction(guard, 'left')
	character_util.set_anim(guard, {name = 'gauntlet_combo_attack', loop = false, sfx_name = "01_swing_01"})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_3', skip = true})
	--사막의 대신관님을 보호하는 것이 나의 의무.
	character_util.remove_anim(guard)

	character_util.set_direction(guard, 'down')
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_4', skip = true})
	--의무를 다하기 위해선 지금보다 강해져야 한다.

	character_util.set_direction(guard, 'right')
	character_util.set_anim(guard, {name = 'meditation'})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_5', skip = true})
	--엉덩이 두쪽이 붙어버릴 정도로 차가운 물에 냉수마찰 하루 오천 번.

	character_util.set_direction(guard, 'left')
	character_util.set_anim(guard, {name = 'gauntlet_handskill2', loop = false, sfx_name = "01_swing_01"})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_6', skip = true})
	--그리고 팔이 빠질 것 같은 속도로 펀치 하루 오천 번.
	character_util.remove_anim(guard)

	character_util.set_direction(guard, 'down')
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_7', skip = true})
	--잡담할 시간따위…

	character_util.set_emotion(guard, {name = 'damaged'})
	camera_util.shake(0.4, 0.3)
	music_player_util.play_sfx({sfx_name = "02_goblin_hit_01"})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_8', skip = true, bubble_type = 'shout'})
	--엣취!
	character_util.remove_emotion(guard)

	character_util.set_emotion(guard, {name = 'blush'})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_9', skip = true})
	--… 방금 그건 못 들은 걸로.

	local wait = true
	local die = true

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString('priest_bodyguard_10'),
		--신관은 이제 없다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			die = true
		end})
	branches:Add({
		Text = game_string:GetString('priest_bodyguard_11'),
		--네 실력으론 무리다.
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
			die = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait do
		coroutine.yield(nil)
	end

	if die then
		music_player_util.play_sfx({sfx_name = "03_dialogue_negative_01"})
		character_util.set_emotion(guard, {name = 'surprise'})
		speech_bubble_util.show_speech_bubble_async(guard,
				{key = 'priest_bodyguard_12', skip = true, bubble_type = 'shout'})
		--뭐?!

		music_player_util.play_sfx({sfx_name = "03_runaway_01"})
		character_util.set_emotion(guard, {name = 'scared'})
		character_util.set_anim(guard, {name = 'embarrassed'})
		speech_bubble_util.show_speech_bubble_async(guard,
				{key = 'priest_bodyguard_13', skip = true, bubble_type = 'shout'})
		--신관님이 당하셨단 말인가? 대체 누구한테!
	else
		character_util.set_emotion(guard, {name = 'tired'})
		speech_bubble_util.show_speech_bubble_async(guard,
				{key = 'priest_bodyguard_14', skip = true})
		--그래, 거듭된 수련으로 큰 힘을 얻었지만…

		character_util.set_direction(guard, 'right')
		speech_bubble_util.show_speech_bubble_async(guard,
				{key = 'priest_bodyguard_15', skip = true})
		--위대하신 신관님 곁에 서기엔 한참 모자르다.
	end
	character_util.set_direction(guard, 'down')
	character_util.remove_anim_and_emotion(guard)

	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_16', skip = true})
	--…잠깐.

	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_17', skip = true})
	--당신, 신관님께서 보내신 거군.

	character_util.set_direction(guard, 'right')
	character_util.set_emotion(guard, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_18', skip = true})
	--이렇게 믿음이 부족한 모습을 보여버리다니.

	music_player_util.play_sfx({sfx_name = "01_catch_fire_01"})
	character_util.set_emotion(guard, {name = 'burning'})
	character_util.set_anim(guard, {name = 'gauntlet_combo_attack', loop = false, sfx_name = "01_swing_01"})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_19', skip = true})
	--아직 수련이 부족하다!

	music_player_util.play_sfx({sfx_name = "02_hit_critical_01", play_pos = guard.Position, delayed_time = 0.2})
	character_util.set_direction(guard, 'left')
	character_util.set_anim(guard, {name = 'gauntlet_handskill2', loop = false, sfx_name = "01_swing_01"})
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_20', skip = true, bubble_type = 'shout'})
	--따으으으하앗!

	character_util.set_direction(guard, 'down')
	character_util.remove_anim_and_emotion(guard)
	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_21', skip = true})
	--나의 채찍이 되어주어 고맙군.

	speech_bubble_util.show_speech_bubble_async(guard,
			{key = 'priest_bodyguard_22', skip = true})
	--앞으로도 모질게 부탁하네.

	yield_return_func(CS.Oak.AddSNSCoroutine, self.guard_follower_id)

	guard.Interactable.Talk = 'priest_bodyguard_23'

	self.guard_training_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.body_guard_training, self))
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
