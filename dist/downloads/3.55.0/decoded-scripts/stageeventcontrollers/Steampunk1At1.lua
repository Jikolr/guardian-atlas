local local_class = newclass("Steampunk1At1Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	--- [StageCustomKey(StageId = 100090001, StageName = 'steampunk_1_1')]
	self.custom_key =
	{
		-- 상점 도둑 이벤트를 보았는지
		see_shop_thief_event = 1
	}

	-- 상점 도둑 이벤트
	self.shop_thief_list = nil

	self.see_shop_thief_event = false

	self.shop_thief_num = 4
	self.shop_thief_battle_gate_num = 2

	self.shop_thief_name = "shop_thief_"
	self.shop_thief_battle_gate_name = "shop_battlegate_"

	self.shop_thief_event_zone_name = "shop_thief"

	self.shop_thief_battle_group_name = "shop_thief"

	-- 상점 기타 이벤트
	self.shop_3rd_floor_hole_1 = nil
	self.shop_3rd_floor_hole_2 = nil
	self.shop_2nd_floor_hole = nil

	self.see_shop_switch_on_event = false

	self.shop_3rd_floor_hole_1_name = "shop_3rd_floor_hole_1"
	self.shop_3rd_floor_hole_2_name = "shop_3rd_floor_hole_2"
	self.shop_2nd_floor_hole_name = "shop_2nd_floor_hole"
	self.shop_hidden_switch_name = "shop_2nd_floor_switch"
	self.shop_hidden_door_name = "shop_1st_floor_secret_door"
	self.shop_hidden_star_piece_name = "star_piece_5"

	self.shop_hole_marker_name = "dest_shop_hole"
	self.shop_hidden_hole_marker_name = "dest_shop_hidden_hole"

	self.shop_final_battle_group_name = "battle_4"

	self.rat_swarm_event_zone_name = "rat_swarm"
	self.rat_swarm_event_zone_name_2 = "rat_swarm_2"
	self.substage_name = 'substage_9_5'

	self.branch_name1 = "steampunk_thefifer_unlock_branch_1"
	self.branch_name2 = "steampunk_thefifer_unlock_branch_2"

	self.see_rat_swarm_event = false
	self.see_rat_swarm_event_2 = false

	self.fifer_citizen_name = "fifer_citizen_4"

	-- 상자 구역 너머의 Hole 이벤트
	self.cave_hole = nil
	self.cave_hole_name_1 = 'cave_hole_1'
	self.cave_entry_marker_name = 'entry_cave_1'

	-- 기타 상수
	self.train_num = 3

	-- NPC 이름
	self.train_name = 'train_'
	quest_icon.PreLoad()

	-- 엘리자베스 npc 이름
	self.elizabeth_name = 'elizabeth'

	-- 엘리자베스 zone 이름
	self.elizabeth_zone_name = 'elizabeth_zone'

	-- 엘리자베스 marker 이름
	self.elizabeth_marker_name = 'elizabeth_potal'

	-- 엘리자베스 follower id
	self.elizabeth_follower_id = 49
	-- 엘리자베스 진행도
	self.saw_elizabeth_start = false
	self.saw_elizabeth_end = false
	self.saw_elizabeth = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.SwitchOnOffEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_event')

	-- 상점 도둑 이벤트
	self.shop_thief_list = create_generic_list(CS.Oak.Character)

	for i = 1, self.shop_thief_num do
		local cur_thief = get_character(self.shop_thief_name..i)

		self.shop_thief_list:Add(cur_thief)
	end

	-- 상점 기타 이벤트
	self.shop_3rd_floor_hole_1 = get_field_object(self.shop_3rd_floor_hole_1_name)
	self.shop_3rd_floor_hole_2 = get_field_object(self.shop_3rd_floor_hole_2_name)
	self.shop_2nd_floor_hole = get_field_object(self.shop_2nd_floor_hole_name)

	self.fifer_citizen = get_character(self.fifer_citizen_name)
	self.fifer_citizen.Interactable:AddListener(self.cs_controller)

	self:setting()
	self:set_up_fifer()

	if not (user_progress:IsStageOpened(self.substage_name)) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rat_swarm_setup, self))
	end

	if CS.Oak.UserProgress.Instance.Followers:Contains(self.elizabeth_follower_id) then
		self.saw_elizabeth_start = true
		self.saw_elizabeth_end = true
		self.saw_elizabeth = true
	else
		unity_object_pool.GetOrCreate('fx_event_portalspawn_red_open')
		unity_object_pool.GetOrCreate('fx_event_portalspawn_red_end')
		local elizabeth = get_character(self.elizabeth_name)
		character_util.spine_set_alpha_fade(elizabeth, 0, 0)
	end

	self.cave_hole = get_field_object(self.cave_hole_name_1)
	self.cave_hole_interactable = self.cave_hole.Interactable
	self.cave_hole.Interactable = CS.Oak.PublishInteractable.Create()

	return
end

function local_class:need_on_launch()
	local main_quest_id = 91
	local main_quest = user_progress:GetStartedQuest(main_quest_id)

	return main_quest ~= nil and not main_quest.IsComplete and main_quest.InnerProgress > 0 and main_quest.InnerProgress < 5
end

function local_class:on_launch(_)
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	--- 메세지만 보냄, 실제 진입 처리는 main quest 에서 한다.
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
end

function local_class:rat_swarm_setup()
	local locations = {
		vector(78, 0,-98),
		vector(73, 0,-98),
		vector(73, 0,-93),
		vector(78, 0,-93)
	}

	local table = {
		get_character("rat_swarm_5"),
		get_character("rat_swarm_6"),
		get_character("rat_swarm_7"),
		get_character("rat_swarm_8")}
	--쥐들 4칸 안에 놓고 그칸 안에 만 이동 시킴. 이렇게 하면 쥐들이 부딪치지 않습니다.
	local boundaryx = {
		76,79,
		72, 75,
		72, 75,
		76, 79}
	local boundaryz = {
		96,100,
		96,100,
		91,95,
		91,95
	}
	for i = 1,4 do
		character_util.set_position(table[i], locations[i])
		table[i].SpineController:Scale(vector(0.5, 0.5, 0.5), 0)
	end

	local i = nil
	local rat = nil
	local min = nil
	local max = nil
	while true do
		i = math.random(1,4)
		rat = table[i]
		min = 2*i-1
		max = 2*i
		character_util.move_to_async(rat, vector(math.random(boundaryx[min], boundaryx[max]),0,0-math.random(boundaryz[min],boundaryz[max])), nil, 2, true, true)
	end
end

function local_class:set_up_fifer()
	if not (user_progress:IsStageOpened(self.substage_name)) then
		unity_object_pool.GetOrCreate("FX_hit")-- 쥐를 때릴때
		local pos_list = {
			vector(75, 0, -131),
			vector(76, 0, -132),
			vector(75, 0, -133),
			vector(72.5, 0, -130)
		}

		for i = 1, 4 do
			local fifer_cit = get_character("fifer_citizen_"..i)
			fifer_cit.Position = pos_list[i]
			if i == 4 then
				character_util.set_direction(fifer_cit, "down")
				character_util.set_emotion(fifer_cit, { name = 'scared' })
				character_util.shake(fifer_cit, 0.02, 9999)
			else
				character_util.set_direction(fifer_cit, "left")
			end
		end


	end
end


function local_class:on_event(e)
	local event_type = e:GetType()
	if event_type == typeof(CS.Oak.StageStartEvent) then
		self:on_stage_start_event(e)
	elseif event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	elseif event_type == typeof(CS.Oak.SwitchOnOffEvent) then
		self:on_switch_on_off_event(e)
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
	elseif event_type == typeof(CS.Oak.ZoneLeaveEvent) then
		return self:on_zone_leave_event(e)
	end

	return false
end

function local_class:on_stage_start_event(e)

end

function local_class:on_zone_leave_event(e)
	if e.FullLeave == false then return false end
	if e.FieldObject ~= user_party_leader then return false end

	if e.Zone.Name == self.elizabeth_zone_name and
		not self.saw_elizabeth and self.saw_elizabeth_end then
		sp_util.play_normal_screenplay(self.add_sns_elizabeth, self)
		return true
	end

	return true
end

function local_class:on_zone_enter_event(e)
	if e.FullEnter == false then return	end
	if e.FieldObject ~= user_party_leader then return end
	local zone_name = e.Zone.Name
	if zone_name == self.shop_thief_event_zone_name then
		if not self.see_shop_thief_event then
			self.see_shop_thief_event = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shop_thief_event, self))
		end
	elseif zone_name == self.rat_swarm_event_zone_name then
		if not (self.see_rat_swarm_event or user_progress:IsStageOpened(self.substage_name)) then
			self.see_rat_swarm_event = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rat_swarm_event, self))
		end
	elseif zone_name == self.rat_swarm_event_zone_name_2 then
		if not (self.see_rat_swarm_event_2 or user_progress:IsStageOpened(self.substage_name)) then
			self.see_rat_swarm_event_2 = true
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.rat_swarm_event_2, self))
		end
	elseif zone_name == self.elizabeth_zone_name then
		if not self.saw_elizabeth and not self.saw_elizabeth_start then
			sp_util.play_normal_screenplay(self.appear_elizabeth, self)
		end
	end
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.shop_2nd_floor_hole) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_into_2nd_floor_hole, self))
	elseif lua_helper.reference_equals(e.Target, self.shop_3rd_floor_hole_1) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_into_3rd_floor_hole_1, self))
	elseif lua_helper.reference_equals(e.Target, self.shop_3rd_floor_hole_2) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.fall_into_3rd_floor_hole_2, self))
	elseif lua_helper.reference_equals(e.Target, self.fifer_citizen) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_fifer, self))
	elseif lua_helper.reference_equals(e.Target, get_character(self.elizabeth_name)) and
		not self.saw_elizabeth and self.saw_elizabeth_start and not self.saw_elizabeth_end then
		sp_util.play_normal_screenplay(self.talk_elizabeth, self)
	elseif lua_helper.reference_equals(e.Target, self.cave_hole) then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.interact_with_hole, self))
	end
end

function local_class:on_switch_on_off_event(e)
	if e.IsTurningOn and
			lua_helper.reference_equals(e.SwitchObject, get_field_object(self.shop_hidden_switch_name)) and
			not self.see_shop_switch_on_event then
		self.see_shop_switch_on_event = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shop_hidden_swith_on, self))
	end
end

function local_class:on_battle_group_eliminated_event(e)
	if e.BattleGroupName == self.shop_thief_battle_group_name then
		-- 스테이지 커스텀 스테이트 저장
		stage_progress:SetCustomData(self.custom_key.see_shop_thief_event, true)

		for i = 1, self.shop_thief_battle_gate_num do
			message_system:Publish(CS.Oak.BattleGateOpenEvent.Create(self.shop_thief_battle_gate_name..i))
		end
	elseif e.BattleGroupName == self.shop_final_battle_group_name then
		local star_piece = get_field_object(self.shop_hidden_star_piece_name)
		star_piece:OnEvent(CS.Oak.StarPieceAppearEvent.Create(star_piece.Position, false))
	end
end

-- 스테이지 이벤트 기본 설정
function local_class:setting()

	-- 상점 도둑 이벤트
	if not stage_progress:GetCustomData(self.custom_key.see_shop_thief_event) then
		local shop_thief_pos_list = create_generic_list(unity_class.vector3)
		shop_thief_pos_list:Add(vector(29, 0, -134))
		shop_thief_pos_list:Add(vector(29, 0, -135))
		shop_thief_pos_list:Add(vector(26, 0, -135))
		shop_thief_pos_list:Add(vector(31, 0, -135))

		local shop_thief_dir_list = create_generic_list(CS.System.String)
		shop_thief_dir_list:Add("left")
		shop_thief_dir_list:Add("left")
		shop_thief_dir_list:Add("right")
		shop_thief_dir_list:Add("right")

		for i = 0, self.shop_thief_list.Count - 1 do
			character_util.set_position(self.shop_thief_list[i], shop_thief_pos_list[i])
			character_util.set_direction(self.shop_thief_list[i], shop_thief_dir_list[i])
			character_util.set_anim(self.shop_thief_list[i], { name = "eat" })
		end
	else
		self.see_shop_thief_event = true
	end


	-- 기차 설정
	for i = 1, self.train_num do
		local cur_train = get_character(self.train_name..i)

		field_ui_manager:RemoveUI(cur_train, CS.Oak.FieldUiType.CharacterStats)
		cur_train.SpineController.IsShadowActive = false
	end
end

-- 엘리자베스 포탈에서 등장
function local_class:appear_elizabeth()
	self.saw_elizabeth_start = true

	local elizabeth_position = field:GetMarker(self.elizabeth_marker_name).position

	local elizabeth = get_character(self.elizabeth_name)

	music_player:PlaySfxOneShot('02_lightning_strike_01')
	music_player:PlaySfxOneShot('01_character_warp_01')
	potal = unity_object_pool.GetOrCreate('fx_event_portalspawn_red_open'):Instantiate(elizabeth_position + vector(0,0.5,0))
	character_util.set_position(elizabeth, elizabeth_position)
	character_util.move_to(elizabeth, elizabeth_position + vector(-1,0,0), 1, nil, true, true)
	character_util.spine_set_alpha_fade(elizabeth, 1, 1)
	wait_for_sec(1.2)
	potal:Dispose()
	music_player:PlaySfxOneShot('01_portal_02')
	unity_object_pool.GetOrCreate('fx_event_portalspawn_red_end'):Instantiate(elizabeth_position + vector(0,0.5,0))

	wait_for_sec(0.7)
	character_util.set_emotion(elizabeth, { name = 'surprise' })
	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	character_util.normal_jump(elizabeth)
	wait_for_sec(0.5)
	character_util.set_direction(elizabeth, 'right')
	wait_for_sec(0.7)
	music_player:PlaySfxOneShot('01_swing_01')
	character_util.set_direction(elizabeth, 'left')
	wait_for_sec(1)

	-- 여, 여긴…
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_0', skip = true })

	character_util.set_emotion(elizabeth, { name = 'tired' })
	character_util.set_anim(elizabeth, { name = 'cross_arm', loop = true })
	elizabeth.Interactable:AddListener(self.cs_controller)
end

-- 엘리자베스와 대화
function local_class:talk_elizabeth()
	self.saw_elizabeth_end = true
	local elizabeth_position = field:GetMarker(self.elizabeth_marker_name).position
	local elizabeth = get_character(self.elizabeth_name)
	party_util.align_party(elizabeth.Position, 'left', 1.5, 'arc')

	-- …
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_1', skip = true })

	-- 여긴 컬럼비아…? 아니, 뭔가 달라...
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_2', skip = true })

	-- ...당신은?
	character_util.remove_anim(elizabeth)
	character_util.remove_emotion(elizabeth)
	character_util.show_emoticon_async(elizabeth, nil, 'question')
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_3', skip = true })

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	local wait = true

	-- 가디언입니다.
	branches:Add({
		Text = game_string:GetString('steampunk_elizabeth_talk_4'),
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait = false
		end })

	-- 화장실을 찾다가 길을 잃었어요.
	branches:Add({
		Text = game_string:GetString('steampunk_elizabeth_talk_5'),
		Tendency = CS.Oak.TalkTendency.Forced,
		Callback = function()
			wait = false
		end })

	ui_overlay_util.push_overlay(elizabeth, branches)
	while wait do
		coroutine.yield(nil)
	end

	-- ...증기기관, 동굴, 그리고 기사..
	character_util.set_emotion(elizabeth, { name = 'tired' })
	character_util.set_anim(elizabeth, { name = 'cross_arm', loop = true })
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_6', skip = true })

	-- 뭐 이런 엉망인 세계가 다 있어?
	character_util.set_emotion(elizabeth, { name = 'attack' })
	character_util.set_anim(elizabeth, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_7', skip = true })

	-- 이곳엔 손을 안대는게 좋겠어..
	character_util.remove_anim(elizabeth)
	character_util.remove_emotion(elizabeth)
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_8', skip = true })

	music_player:PlaySfxOneShot('02_lightning_strike_01')
	music_player:PlaySfxOneShot('01_character_warp_01')
	local potal = unity_object_pool.GetOrCreate('fx_event_portalspawn_red_open'):Instantiate(elizabeth_position + vector(0,0.5,0))
	character_util.move_to(elizabeth, elizabeth_position, 1, nil, true, true)
	character_util.spine_set_alpha_fade(elizabeth, 0, 1)
	wait_for_sec(1.5)
	character_util.set_position(elizabeth, vector(999,0,999))
	potal:Dispose()
	music_player:PlaySfxOneShot('01_portal_02')
	unity_object_pool.GetOrCreate('fx_event_portalspawn_red_end'):Instantiate(elizabeth_position + vector(0,0.5,0))
end

-- 앨리자베스 SNS 추가
function local_class:add_sns_elizabeth()
	self.saw_elizabeth = true

	local elizabeth_position = field:GetMarker(self.elizabeth_marker_name).position
	music_player:PlaySfxOneShot('02_lightning_strike_01')
	music_player:PlaySfxOneShot('01_character_warp_01')
	local potal = unity_object_pool.GetOrCreate('fx_event_portalspawn_red_open'):Instantiate(elizabeth_position + vector(0,0.5,0))

	local elizabeth = get_character(self.elizabeth_name)
	character_util.set_position(elizabeth, elizabeth_position)
	character_util.move_to(elizabeth, elizabeth_position + vector(-1,0,0), 1, nil, true, true)
	character_util.spine_set_alpha_fade(elizabeth, 1, 1)
	wait_for_sec(1.2)
	potal:Dispose()
	music_player:PlaySfxOneShot('01_portal_02')
	unity_object_pool.GetOrCreate('fx_event_portalspawn_red_end'):Instantiate(elizabeth_position + vector(0,0.5,0))


	-- 잠깐만. 이 엉망인 세계의 운명이 궁금하긴 하네요.
	character_util.set_emotion(elizabeth, { name = 'attack' })
	character_util.set_anim(elizabeth, { name = 'release', loop = true, sfx_name = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_9', skip = true })
	character_util.remove_anim(elizabeth)

	party_util.align_party(elizabeth.Position, 'left', 1.5, 'arc')

	-- 당신 FB 해요?
	character_util.remove_anim(elizabeth)
	character_util.remove_emotion(elizabeth)
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_10', skip = true })

	yield_return_func(CS.Oak.AddSNSCoroutine, self.elizabeth_follower_id)

	-- 재밌는 일이 생기면 가끔 포스팅해줘요.
	character_util.set_emotion(elizabeth, { name = 'doyagao'})
	character_util.set_anim(elizabeth, { name = 'nod', loop = true })
	speech_bubble_util.show_speech_bubble_async(elizabeth, { key = 'steampunk_elizabeth_talk_11', skip = true })

	character_util.remove_anim(elizabeth)
	character_util.remove_emotion(elizabeth)

	music_player:PlaySfxOneShot('02_lightning_strike_01')
	music_player:PlaySfxOneShot('01_character_warp_01')
	potal = unity_object_pool.GetOrCreate('fx_event_portalspawn_red_open'):Instantiate(elizabeth_position + vector(0,0.5,0))

	character_util.move_to(elizabeth, elizabeth_position, 1, nil, true, true)
	character_util.spine_set_alpha_fade(elizabeth, 0, 1)
	wait_for_sec(1.5)
	character_util.set_position(elizabeth, vector(999,0,999))
	potal:Dispose()
	music_player:PlaySfxOneShot('01_portal_02')
	unity_object_pool.GetOrCreate('fx_event_portalspawn_red_end'):Instantiate(elizabeth_position + vector(0,0.5,0))

	elizabeth.Interactable:RemoveRelatedEvent(self.cs_controller)
end

-- 상점에 들어가서 도둑들이 하는 얘기 듣고 전투 돌입하는 이벤트
function local_class:shop_thief_event()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	music_player:PlaySfxOneShot('01_rummaging_01')
	local eat_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true, type_priority = 'loop', player_priority = 'npc' })
	camera_util.move_async(vector(28.5, 0, -134), 1)

	character_util.set_emotion(self.shop_thief_list[0], { name = "doyagao" })

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')
	speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[0], { key = "steampunk_1_1_shop_thief_0", skip = true })

	character_util.set_direction(self.shop_thief_list[3], "left")
	character_util.set_anim(self.shop_thief_list[3], { name = "cast" })
	character_util.set_emotion(self.shop_thief_list[3], { name = "tired" })

	speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[3], { key = "steampunk_1_1_shop_thief_1", skip = true })

	character_util.set_direction(self.shop_thief_list[1], "right")
	character_util.set_anim(self.shop_thief_list[1], { name = "bomb_idle" })
	character_util.set_emotion(self.shop_thief_list[1], { name = "doyagao" })

	speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[1], { key = "steampunk_1_1_shop_thief_2", skip = true })

	camera_util.move(vector(28.5, 0, -135), 0.5)

	character_util.align_party(vector(28.5, 0, -136), "down")

	music_player:PlaySfxOneShot('01_player_jump_01')
	eat_sfx:Stop()
	for i = 0, self.shop_thief_list.Count - 1 do
		character_util.set_direction(self.shop_thief_list[i], "down")
		character_util.jump(self.shop_thief_list[i], 1, 0.5)
		character_util.set_anim(self.shop_thief_list[i], { name = "cast" })
		character_util.set_emotion(self.shop_thief_list[i], { name = "attack" })
	end

	speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[2], { key = "steampunk_1_1_shop_thief_3", skip = true })

	character_util.set_anim(self.shop_thief_list[1], { name = "release", sfx_name = "01_swing_01" })

	speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[1], { key = "steampunk_1_1_shop_thief_4", skip = true })

	--wait_for_sec(1)

	--character_util.set_anim(self.shop_thief_list[3], { name = "cross_arm" })

	--speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[3], { key = "steampunk_1_1_shop_thief_5", skip = true })

	--character_util.set_direction(self.shop_thief_list[1], "right")
	--character_util.set_anim(self.shop_thief_list[1], { name = "bomb_idle" })
	--character_util.set_emotion(self.shop_thief_list[1], { name = "doyagao" })

	--character_util.set_direction(self.shop_thief_list[3], "left")
	--character_util.set_anim(self.shop_thief_list[3], { name = "clap" })
	--character_util.set_emotion(self.shop_thief_list[3], { name = "doyagao" })

	--speech_bubble_util.show_speech_bubble_async(self.shop_thief_list[1], { key = "steampunk_1_1_shop_thief_6", skip = true })

	for i = 0, self.shop_thief_list.Count - 1 do
		character_util.set_direction(self.shop_thief_list[i], "down")
		character_util.remove_anim(self.shop_thief_list[i])
		character_util.remove_emotion(self.shop_thief_list[i])
	end

	camera_util.move_async(user_party_leader.Position, 0.5, { end_target = user_party_leader })

	for i = 1, self.shop_thief_battle_gate_num do
		message_system:Publish(CS.Oak.BattleGateCloseEvent.Create(self.shop_thief_battle_gate_name..i))
	end

	for i = 0, self.shop_thief_list.Count - 1 do
		character_util.convert_to_monster(self.shop_thief_list[i], self.shop_thief_battle_group_name)
		command_util.execute_monster_notice(self.shop_thief_list[i], user_party_leader, "battle")
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 상점에서 2층의 구멍에 Interact해서 아래로 떨어지는 이벤트
function local_class:fall_into_2nd_floor_hole()
	yield_return(self, "fall_into_hole_routine", self.shop_2nd_floor_hole.Position)

	local marker = stage.Field:GetMarker(self.shop_hole_marker_name)
	yield_return(self, "land_on_routine", marker.position, marker.direction)
end

-- 상점에 3층의 1번째 구멍에 Interact해서 아래로 떨어지는 이벤트
function local_class:fall_into_3rd_floor_hole_1()
	yield_return(self, "fall_into_hole_routine", self.shop_3rd_floor_hole_1.Position)

	local middle_pos = self.shop_2nd_floor_hole.Position
	local fall_time = 1
	local fall_party_delay = fall_time / user_party.Count

	camera_util.move(middle_pos + vector(0, 0, 2), 0)

	screen_util.fade_in_circular(0.5, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	for i = 0, user_party.Count - 1 do
		user_party[i].SpineController:Scale(unity_class.vector3.one, 0)

		character_util.set_position(user_party[i], middle_pos + vector(0, 15, 0))

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.freefall_character_gravity, self, user_party[i], 32, 1))

		coroutine.yield(coroutine_class.wait_for_sec(fall_party_delay))
	end

	coroutine.yield(coroutine_class.wait_for_sec(fall_time - fall_party_delay))

	screen_util.fade_out_circular(0.5, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))

	local marker = stage.Field:GetMarker(self.shop_hole_marker_name)
	yield_return(self, "land_on_routine", marker.position, marker.direction)
end

-- 상점에 3층의 2번째 구멍에 Interact해서 아래로 떨어지는 이벤트
function local_class:fall_into_3rd_floor_hole_2()
	yield_return(self, "fall_into_hole_routine", self.shop_3rd_floor_hole_2.Position)

	local marker = stage.Field:GetMarker(self.shop_hidden_hole_marker_name)
	yield_return(self, "land_on_routine", marker.position, marker.direction)
end

-- 구멍에 Interact해서 특정 위치로 떨어지는 이벤트
function local_class:fall_into_hole_routine(pos)
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	music_player:PlaySfxOneShot('01_jump_01')
	music_player:PlaySfxOneShot('01_fall_down_01')
	for i = 0, user_party.Count - 1 do
		user_party[i].SpineController:Scale(unity_class.vector3.zero, 1)
		user_party[i].SpineController:Jump(2, 1)

		character_util.set_anim(user_party[i], {name = "get"})

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				CS.Oak.IFieldObjectExtensions.MoveTo(user_party[i], pos + vector(0, -1, 0), 0.5, nil, true))
	end

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	screen_util.fade_out_circular(0.5, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(1))
end

-- 구멍에 Interact해서 특정 위치와 방향으로 착지하는 이벤트
function local_class:land_on_routine(pos, dir)
	camera_util.move(pos, 0.1)

	screen_util.fade_in_circular(0.5, CS.Oak.Interpolations.Linear)

	coroutine.yield(coroutine_class.wait_for_sec(0.5))

	local fall_time = 1
	local bounce_time = 0.5

	local fall_party_delay = fall_time / user_party.Count
	local bounce_party_delay = bounce_time / user_party.Count

	for i = 0, user_party.Count - 1 do
		user_party[i].SpineController:Scale(unity_class.vector3.one, 0)

		character_util.set_position(user_party[i], pos + vector(0, 15, 0))
		character_util.set_direction(user_party[i], dir)
		character_util.set_anim(user_party[i], {name = "embarrassed"})
		character_util.set_emotion(user_party[i], {name = "damaged"})

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.freefall_character, self, user_party[i], fall_time))

		coroutine.yield(coroutine_class.wait_for_sec(fall_party_delay))
	end

	stage_camera:SetTarget(user_party_leader)

	music_player:PlaySfxOneShot('01_land_01')
	for i = 0, user_party.Count - 1 do
		user_party[i].SpineController:Jump(1, bounce_time)

		character_util.set_anim(user_party[i], {name = "get"})
		character_util.remove_emotion(user_party[i])

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				CS.Oak.IFieldObjectExtensions.MoveTo(user_party[i],
						pos,
						bounce_time, nil, true))

		coroutine.yield(coroutine_class.wait_for_sec(bounce_party_delay))
	end

	coroutine.yield(coroutine_class.wait_for_sec(bounce_time - bounce_party_delay))

	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
	end

	field_ui_manager:Show()
	user_party:ResetControllers()
end

-- 일정 시간 동안 자유낙하하는 캐릭터 연출
function local_class:freefall_character(character, fall_time)
	local curtime = unity_class.time.time
	local falltime = fall_time
	local curpos = character.Position
	local freefall = CS.CalculatorFreeFall(falltime, curpos.y, 0);

	while unity_class.time.time - curtime < falltime do
		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		character_util.set_position(character, vector(curpos.x, curpos.y + dist_y, curpos.z), true)
		coroutine.yield(nil)
	end

	character_util.set_position(character, vector(curpos.x, 0, curpos.z))
end

-- 일정 시간 동안 정해진 값의 중력으로 자유낙하하는 캐릭터 연출
function local_class:freefall_character_gravity(character, gravity, fall_time)
	local curtime = unity_class.time.time
	local falltime = fall_time
	local curpos = character.Position
	local freefall = CS.CalculatorFreeFall(0, gravity, 0, 0);

	while unity_class.time.time - curtime < falltime do
		freefall:Proceed(unity_class.time.deltaTime)
		local dist_y = freefall:GetDistance()

		character_util.set_position(character, vector(curpos.x, curpos.y + dist_y, curpos.z), true)
		coroutine.yield(nil)
	end

	character_util.set_position(character, vector(curpos.x, 0, curpos.z))
end

-- 상점에서 숨겨진 스위치를 눌러서 비밀 문이 열리는 것을 보여주는 연출
function local_class:shop_hidden_swith_on()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	local hidden_door = get_field_object(self.shop_hidden_door_name)

	coroutine.yield(screen_util.fade_out_async(1, unity_class.color.black, CS.Oak.Interpolations.Linear))

	camera_util.move(hidden_door.Position, 0)

	coroutine.yield(screen_util.fade_in_async(1, unity_class.color.black, CS.Oak.Interpolations.Linear))

	message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.shop_hidden_door_name, false))

	coroutine.yield(coroutine_class.wait_for_sec(2.5))

	coroutine.yield(screen_util.fade_out_async(1, unity_class.color.black, CS.Oak.Interpolations.Linear))

	stage_camera:SetTarget(user_party_leader)

	coroutine.yield(screen_util.fade_in_async(1, unity_class.color.black, CS.Oak.Interpolations.Linear))

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:rat_swarm_event()
	--user_party:StopAndDisableControl()
	--stage.FieldUIManager:Hide()

	--camera_util.move_async(user_party_leader.Position+vector(-2,0,0), 1)
	local rat_table = {}
	local rat_size = 4

	for i = 1, rat_size do
		rat_table[i] = get_character("rat_swarm_" .. i)
		rat_table[i].SpineController:Scale(vector(0.5, 0.5, 0.5), 0)
		character_util.spine_set_alpha_fade(rat_table[i], 0, 0)
		field_ui_manager:RemoveUI(rat_table[i], CS.Oak.FieldUiType.CharacterStats)
	end

	new_location = {vector(70, 0, -131),
					vector(69, 0, -132),
					vector(70, 0,  -133),
					vector(999,0,999)}
	--party_util.set_emotion({name = "surprise", loop = true})
	--party_util.set_anim({name = "embarrassed", loop = true})

	for i = 1, rat_size do
		local sfx_name = '01_die_mouse_01'

		if i % 2 == 0 then
			sfx_name = '01_mouse_01'
		end

		music_player_util.play_sfx({ sfx_name = sfx_name, parent = rat_table[i], type_priority = 'event', player_priority = 'npc'})
		rat_table[i].Position = vector(75, 0, -90)
		character_util.spine_set_alpha_fade(rat_table[i], 1, 0.1)
		character_util.set_anim(rat_table[i], {name = 'run', loop = true})
		character_util.move_to_async(rat_table[i], rat_table[i].Position + vector(0, 0, -5), nil, 9, true)
		character_util.spine_set_alpha_fade(rat_table[i], 0, 1)
		character_util.move_to(rat_table[i], rat_table[i].Position + vector(-8, 0, 0), nil, 9, true)

	end
	wait_for_sec(1)

	--camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})

	for i = 1, rat_size do
		rat_table[i].Position = new_location[i]
		character_util.set_direction(rat_table[i], "right")
	end

	for i = 1, rat_size do
		character_util.spine_set_alpha_fade(rat_table[i], 1, 0)
	end

	--party_util.remove_emotion()
	--party_util.remove_animation()
	--user_party:ResetControllers()
	--stage.FieldUIManager:Show()
end

function local_class:rat_swarm_event_2()
	-- 집 안에 들어 올때
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()
	quest_icon.SetSubstageIcon(self.fifer_citizen)
	local rats = {get_character("rat_swarm_1"),
					get_character("rat_swarm_2"),
					get_character("rat_swarm_3")}
	local citizens = {get_character("fifer_citizen_1"),
					get_character("fifer_citizen_2"),
					get_character("fifer_citizen_3")}

	camera_util.move_async(vector(73,0,-133), 1)

	character_util.set_emotion(citizens[2], {name = "surprise", loop = true})
	--무, 무슨 쥐가 저렇게 커!
	music_player:PlaySfxOneShot('03_dialogue_negative_02')
	speech_bubble_util.show_speech_bubble_async(citizens[2], {key = "steampunk_thefifer_unlock_9", skip = true} )

	character_util.set_emotion(citizens[3], {name = "scared", loop = true})
	--징그러워!
	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')
	speech_bubble_util.show_speech_bubble_async(citizens[3], {key = "steampunk_thefifer_unlock_10", skip = true} )

	character_util.set_anim_and_emotion(rats[2], {name = "attack", loop = false}, {name = "mad", loop = true})
	camera_util.resize_to(3, 0.5)
	--찍찍!
	music_player:PlaySfxOneShot('01_die_mouse_01')
	speech_bubble_util.show_speech_bubble_async(rats[2], {key = "steampunk_thefifer_unlock_11", skip = true, bubble_type = "shout"})

	--쥐 첫번재 공격
	music_player:PlaySfxOneShot('01_mouse_01')
	for i = 1,3 do
		character_util.move_to(rats[i], citizens[i].Position+vector(-0.5, 0, 0), nil, 9, true, true)
	end
	camera_util.resize_to_default()

	wait_for_sec(1)
	music_player:PlaySfxOneShot('02_hit_big_01')
	music_player:PlaySfxOneShot('01_hit_npc_01')
	for i = 1, 3 do
		character_util.set_anim(rats[i], {name = "attack", loop = false})
		character_util.set_anim_and_emotion(citizens[i], {name = "prostrate", loop = true}, {name = "hurt", loop = true})

		unity_object_pool.GetOrCreate('FX_hit'):Instantiate(citizens[i].Position)
		character_util.spine_damage_red_pulse(citizens[i])
		character_util.spine_damage_squish_default(citizens[i])
	end

	wait_for_sec(0.5)

	character_util.set_direction(rats[3], "down")
	character_util.set_anim_and_emotion(rats[3], {name = "release", loop = true}, {name = "smile", loop = true})
	--찍! 찌직!
	music_player:PlaySfxOneShot('01_mouse_01')
	speech_bubble_util.show_speech_bubble_async(rats[3], {key = "steampunk_thefifer_unlock_12", skip = true})

	--주인공 자리에 이동
	circle_loc = {vector(0.5,0,0),
	              vector(0,0,0.5),
	              vector(-0.5,0,0)}

	circle_dir = {"left",
	              "down",
	              "right" }

	for i = 1, 3 do
		character_util.remove_anim(rats[i])
		character_util.move_to(rats[i], user_party_leader.Position+circle_loc[i],0.5, nil, true, true)
	end

	wait_for_sec(0.5)
	--쥐 두번재 공격
	party_util.jump(1,0.5)
	local direction = -1.5

	--너무 왼쪽에 이벤트를 시작 하면, 쥐들이 부딪칠때 타일맵에서 나갈 수 도있으니까 오늘쪽으로 가게 합니다.
	for i = 0, user_party.Count - 1 do
		if user_party[i].Position.x <= 68 then
			direction = 1.5
		end
	end

	music_player:PlaySfxOneShot('02_hit_big_01')
	for i = 0, user_party.Count - 1 do
		unity_object_pool.GetOrCreate('FX_hit'):Instantiate(user_party_leader.Position)
		character_util.spine_damage_red_pulse(user_party_leader)
		character_util.spine_damage_squish_default(user_party_leader)

		character_util.set_direction(user_party[i], "left")
		character_util.move_to(user_party[i], user_party[i].Position+vector(direction,0,0), 0.5, nil)


		character_util.set_emotion(user_party[i], {name = "hurt", loop = true})
	end

	for i = 1, 3 do
		character_util.set_direction(rats[i], circle_dir[i])
		character_util.set_anim(rats[i], {name = "attack", loop = false})
	end


	music_player:PlaySfxOneShot('01_hit_npc_01')
	party_util.set_anim({name = "prostrate", loop = true})
	wait_for_sec(0.5)
	camera_util.move(user_party_leader.Position, 1, {end_target = user_party_leader})


	--쥐 도망 간다
	music_player:PlaySfxOneShot('01_mouse_01')
	for i = 1, 3 do
		character_util.remove_anim(rats[i])
		character_util.move_to(rats[i], vector(72.5,0,-136)+circle_loc[i], nil, 9, true, true)
	end
	while rats[1].Position ~= vector(73, 0,-136) do
		coroutine.yield(nil)
	end
	for i = 1, 3 do
		character_util.move_to(rats[i], rats[i].Position+vector(0,0,-30), nil, 9, true, true)
	end

	--파티 떨고 마리오 점프
	wait_for_sec(2)
	music_player:PlaySfxOneShot('01_rustle_01')
	for i = 0, user_party.Count - 1 do
		character_util.shake(user_party[i], 0.05, 1)
	end

	wait_for_sec(1)

	music_player:PlaySfxOneShot('01_player_popup_01')
	for i = 0, user_party.Count - 1 do
		character_util.remove_anim_and_emotion(user_party[i])
		character_util.mario_jump_new(user_party[i], "down", 0.3, 0.4)
	end

	wait_for_sec(1)

	for i = 0, 3 do
		character_util.remove_anim_and_emotion(user_party[i])
	end

	user_party:ResetControllers()
	stage.FieldUIManager:Show()
end

function local_class:interact_with_fifer()
	user_party:StopAndDisableControl()
	stage.FieldUIManager:Hide()

	party_util.align_to_target(self.fifer_citizen, 'down', 1, 'arc')

	quest_icon.RemoveIcon(self.fifer_citizen)

	-- 요즘 쥐 때문에 사람 사는 것 같지 않아요.
	speech_bubble_util.show_speech_bubble_async(self.fifer_citizen,
		{ key = "steampunk_thefifer_unlock_4_1", skip = true })

	speech_bubble_util.show_speech_bubble_async(self.fifer_citizen,
		{ key = "steampunk_thefifer_unlock_4", skip = true })

	speech_bubble_util.show_speech_bubble_async(self.fifer_citizen,
		{ key = "steampunk_thefifer_unlock_5", skip = true })

	if not (user_progress:IsStageOpened(self.substage_name)) then
		local opener = get_field_object('fifer_substage_unlock')
		coroutine.yield(opener.FieldObjectBehaviour:OpenStage())
	end

	user_party:ResetControllers()
	stage.FieldUIManager:Show()

end

-- 경비 구역 너머의 구멍에 Interact시 발생하는 이벤트
function local_class:interact_with_hole()
	field_ui_manager:Hide()
	user_party:StopAndDisableControl()

	music_player_util.play_sfx({ sfx_name = '01_jump_01', type_priority = 'event', player_priority = 'npc' })

	local move_duration = 0.5

	character_util.jump(user_party_leader, 1, move_duration)
	character_util.set_anim(user_party_leader, { name = 'get' })
	character_util.move_to(user_party_leader, self.cave_hole.Position + vector(0, 0, -0.3),
			move_duration, nil, false, false)

	wait_for_sec(move_duration)

	music_player_util.play_sfx({ sfx_name = '01_fall_down_01', type_priority = 'event', player_priority = 'npc' })

	user_party_leader.SpineController:Scale(unity_class.vector3.zero, 0.3)

	screen_util.fade_out_circular_async(0.5, 'linear')

	-- 플레이어 위치 설정
	local target_marker = field:GetMarker(self.cave_entry_marker_name)

	user_party_leader.SpineController:Scale(unity_class.vector3.one, 0)

	for i = 0, user_party.Count - 1 do
		character_util.set_position(user_party[i], target_marker.position -
				CS.Oak.DirectionExtensions.ToVector3(target_marker.direction) * CS.Oak.Constants.DistBetweenPartyMembers * i)
		character_util.set_direction(user_party[i], target_marker.direction)
		character_util.remove_anim(user_party[i])
	end

	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')

	user_party:ResetControllers()
	field_ui_manager:Show()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.SwitchOnOffEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil

	self.border_soldier_list = nil
	self.emergency_soldier = nil

	self.shop_thief_list = nil

	self.shop_3rd_floor_hole_1 = nil
	self.shop_3rd_floor_hole_2 = nil
	self.shop_2nd_floor_hole = nil

	self.cave_hole = nil

	local elizabeth = get_character(self.elizabeth_name)
	if type_util.is_npc_interactable(elizabeth) then
		elizabeth.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	if lua_helper.type_compare(self.fifer_citizen.Interactable, CS.Oak.NPCInteractable) then
		self.fifer_citizen.Interactable:RemoveRelatedEvent(self.cs_controller)
	end
	self.fifer_citizen = nil
end

return {
	create = function(cs_controller)
		return local_class(cs_controller);
	end
}
