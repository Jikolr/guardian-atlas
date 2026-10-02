local local_class = newclass('giantyeti_controller')

function local_class:init(cs_controller, scene)

	self.cs_controller = cs_controller
	self.scene = scene()

	self.is_stage_clear = false
	self.is_food_box_open = false

	self.training_rock_count = 0
	self.hit_yeti_count = 0
	self.batting_count = 0

	self.inner_progress = 0

	self.baseball = nil

	self.fight_coroutine = nil
	self.batting_coroutine = nil
end

function local_class:on_event_received_routine(e)
	return false
end

function local_class:load_resource()
	self.is_stage_clear = user_progress:IsStageCleared(stage.Name)
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')

	unity_object_pool.GetOrCreate('FX_lasthit')
	unity_object_pool.GetOrCreate('FX_hit')
	unity_object_pool.GetOrCreate('FX_hit_small')

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.setting_routine, self))
end

function local_class:setting_routine()
	if self.is_stage_clear then
		get_field_object('training_rock_2').ActiveState = active_state('disabled')
		get_field_object('training_rock_3').ActiveState = active_state('disabled')
		return
	end

	CS.Oak.CommonScreenplay.PreloadTutorialSpine()

	self.baseball = get_character('baseball_girl')
	self.baseball:SetEquipment(CS.Oak.EquipmentSlot.Weapon1,
			CS.Oak.Item.Create(CS.Oak.ItemSpec.GetByName('pink_bat_normal')))
	character_util.set_position(self.baseball, vector(7, 1, -1))

	yield_return_func(self.scene.Setting3_1, self.scene)
	yield_return_func(self.scene.baseballRun, self.scene)
end

function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.BattleStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.batting_coroutine = nil
	self.fight_coroutine = nil

	self.baseball = nil

	self.cs_controller = nil
	self.scene = nil
end

---[[ on event
function local_class:on_event(e)
	local event_type = e:GetType()

	if event_type == typeof(CS.Oak.StageStartEvent) then
		character_util.set_emotion(self.baseball, {name = 'burning'})
		if stage_progress:GetNamedData('food_box', false, CS.Tilemaps.NameSection.Box) then
			get_field_object('food_box').Interactable = CS.Oak.NonInteractable.Instance
		end
	elseif event_type == typeof(CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end

	if self.is_stage_clear then return false end

	if event_type == typeof(CS.Oak.ZoneEnterEvent) then
		self:on_zone_enter_event(e)
	elseif event_type == typeof(CS.Oak.FieldObjectDestroyedEvent) then
		self:on_field_object_destroyed_event(e)
	elseif event_type == typeof(CS.Oak.BattleGroupEliminatedEvent) then
		self:on_battle_group_eliminated_event(e)
	elseif event_type == typeof(CS.Oak.BattleStartEvent) then
		self:on_battle_start_event(e)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if not e.FullEnter then return end
	if not lua_helper.reference_equals(e.FieldObject, user_party_leader) then return end

	local zone_name = e.Zone.Name

	if zone_name == 'EVENT1' then
		if self.inner_progress == 0 then
			self.inner_progress = 1
			sp_util.play_normal_screenplay(self.baseball_shout, self)
		elseif self.inner_progress == 1 then
			sp_util.play_normal_screenplay(self.baseball_ask_again, self)
		end
	elseif zone_name == 'EVENT2' and self.inner_progress == 2 then
		self.inner_progress = 3
		sp_util.play_normal_screenplay(self.baseball_pass_ball, self)
	elseif zone_name == 'jump' and self.inner_progress == 4 then
		self.inner_progress = 5
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.baseball_jump, self))
	elseif zone_name == 'too_slow' and self.inner_progress == 5 then
		self.inner_progress = 6
		music_player:PlaySfxOneShot('03_dialogue_negative_01')
		speech_bubble_util.show_speech_bubble(self.baseball,
				{ key = 'substage_giant_yeti_18_1', bubble_type = 'shout', portraitname = 'battleball_girl'})
	elseif zone_name == 'run' and self.inner_progress == 6 then
		self.inner_progress = 7
		speech_bubble_util.remove_bubble(self.baseball)
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.baseball_run, self, 5))
	end

	for i = 1, 4 do
		if zone_name == string.format('stop_batting_%d', i) and self.batting_count < i then
			character_util.remove_anim_and_emotion(self.baseball)

			stop_coroutine(self.batting_coroutine)
			speech_bubble_util.remove_bubble(self.baseball)

			self.batting_count = self.batting_count + 1
			character_util.convert_to_party_member(self.baseball, user_party)
			self.baseball.FieldObjectStatsBehaviour.Immortal = true
		end
	end
end

function local_class:on_field_object_destroyed_event(e)
	local bomb = get_field_object('training_bomb')
	local rock1 = get_field_object('training_rock_1')
	local rock2 = get_field_object('training_rock_1_1')
	if lua_helper.reference_equals(e.FieldObject, bomb) and self.inner_progress == 3 then
		if self.training_rock_count == 2 then
			self.inner_progress = 4
			sp_util.play_normal_screenplay(self.training_1_pass, self)
		elseif self.training_rock_count == 1 and not self.try_again then
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.baseball_throw_bomb, self, 1))
			self.try_again = true
		else
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.baseball_throw_bomb, self, 2))
		end
	elseif lua_helper.reference_equals(e.FieldObject, rock1) then
		self.training_rock_count = 1
		self.try_again = false
	elseif lua_helper.reference_equals(e.FieldObject, rock2) then
		self.training_rock_count = 2
	elseif e.FieldObject.Name == 'battle4_1' or e.FieldObject.Name == 'battle4_2' then
		local yeti = e.FieldObject
		character_util.set_direction(yeti, 'right')
		character_util.set_anim(yeti, {name = 'dead', loop = false})
	end
end

function local_class:on_battle_group_eliminated_event(e)
	stop_coroutine(self.fight_coroutine)
	self.fight_coroutine = nil
	speech_bubble_util.remove_bubble(self.baseball)

	if e.BattleGroupName == 'battle1' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.baseball_run, self, 1))
	elseif e.BattleGroupName == 'battle3' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.baseball_run, self, 3))
	elseif e.BattleGroupName == 'battle4' and self.inner_progress == 7 then
		self.inner_progress = 8
		sp_util.play_normal_screenplay(self.training_2_setting, self)
	elseif e.BattleGroupName == 'battle5' and self.inner_progress == 9 then
		self.inner_progress = 10
		sp_util.play_normal_screenplay(self.ending, self)
	end
end

function local_class:on_battle_start_event(e)
	if self.fight_coroutine == nil then
		self.fight_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
		util.cs_generator(self.baseball_fight, self))
	end
end

function local_class:on_interact_event(e)
	local food_box = get_field_object('food_box')
	if lua_helper.reference_equals(e.Target, food_box) and not self.is_food_box_open then
		sp_util.play_normal_screenplay(self.open_box, self)
	end
end
---]]

-- 주인공을 불러 세우는 이벤트
function local_class:baseball_shout()
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	speech_bubble_util.show_speech_bubble(self.baseball,
			{ key = 'substage_giant_yeti_1', bubble_type = 'shout', screen_pos = {300, 300},
			  portraitname = 'battleball_girl'})
	-- 잠깐!
	character_util.stop(self.baseball)
	character_util.remove_emotion(self.baseball)

	local jump_target = field:GetMarker('battle_ball_jump')

	character_util.move_waypoint_async(self.baseball,
			{vector(self.baseball.Position.x, 1, jump_target.position.z),
			 vector(6, 1, jump_target.position.z)},
			5, false, nil, nil, 'left', true)

	local info = CS.Oak.WaypointMoveInfo.Create(jump_target.position, 6, false)
	local jump_duration = info:GetDuration(self.baseball.Position)

	music_player:PlaySfxOneShot('01_jump_01')
	character_util.jump(self.baseball, 2, jump_duration)
	CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.baseball, info)

	wait_for_sec(jump_duration)
	music_player:PlaySfxOneShot('01_land_01')

	coroutine.yield(nil)

	character_util.set_direction(self.baseball, 'down')

	character_util.align_party(self.baseball,'down', 1, 'arc')

	wait_for_sec(0.5)

	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_2', skip = true, portraitname = 'battleball_girl'})
	--너도 배틀볼 전지훈련을 하러 이 산까지 올라온 거야?
	character_util.remove_anim(self.baseball)

	local branches = create_generic_list(CS.Oak.TalkBranch)

	local wait_for_branch = true

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_3'),
		--맞다.
		Tendency = CS.Oak.TalkTendency.Intellect,
		Callback = function()
			wait_for_branch = false
		end})

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_4'),
		--예티를 잡으러 왔다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	character_util.set_direction(self.baseball, 'left')
	character_util.set_anim(self.baseball, {name = 'question', loop = false})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_5', skip = true, portraitname = 'battleball_girl'})
	--역시… 거대 예티만큼 훈련에 좋은 몬스터는 없지
	character_util.remove_anim(self.baseball)

	character_util.set_emotion(self.baseball, {name = 'greed'})
	character_util.set_direction(self.baseball, 'down')

	music_player:PlaySfxOneShot('01_gatcha_point_01')

	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_6', skip = true, portraitname = 'battleball_girl'})
	--있잖아, 내 훈련을 도와주지 않을래?
	character_util.remove_emotion(self.baseball)

	character_util.set_direction(self.baseball, 'left')
	character_util.set_anim(self.baseball, {name = 'twohand_attack', sfx_name = '02_normal_slash_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_7', skip = true, portraitname = 'battleball_girl'})
	--그럼 나도 예티를 잡는 걸 도와줄게!
	character_util.remove_anim(self.baseball)
	character_util.set_direction(self.baseball, 'down')

	yield_return_func(self.baseball_ask_help, self)
end

-- 도와달라고 물어보는 로직 (shout, ask_again 에서 쓰임)
function local_class:baseball_ask_help()
	local branches = create_generic_list(CS.Oak.TalkBranch)

	local wait_for_branch = true
	local help = false

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_9'),
		--훈련을 도와준다.
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
			help = true
		end})

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_10'),
		--도와주지 않는다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			help = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	if not help then
		character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_11', skip = true, portraitname = 'battleball_girl'})
		--생각이 바뀌면 말해줘!
		character_util.remove_anim(self.baseball)

		character_util.set_direction(self.baseball, 'left')
		self.batting_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.batting_training, self))

		character_util.move_waypoint_async(user_party_leader,
				user_party_leader.Position + vector(0, 0, -2),
				3, false, nil, nil, 'down', true)
	else
		character_util.set_emotion(self.baseball, {name = 'doyagao'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12', skip = true, portraitname = 'battleball_girl'})
		--정말이지?

		music_player:PlaySfxOneShot('03_dialogue_emphasize_01')

		character_util.set_direction(self.baseball, 'left')
		character_util.set_anim(self.baseball, {name = 'victory_get', loop = false})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_1', skip = true, portraitname = 'battleball_girl'})
		--나중에 후회하기 없기다?

		character_util.remove_anim_and_emotion(self.baseball)

		character_util.move_waypoint_async(self.baseball,
				{self.baseball.Position + vector(0, 0, 1),
				 self.baseball.Position + vector(-5, 0, 1)},
				6, true, nil, nil, 'left', true)

		wait_for_sec(0.5)

		character_util.set_direction(self.baseball, 'right')

		character_util.set_emotion(self.baseball, {name = 'attack'})
		character_util.set_anim(self.baseball, {name = 'jingak', sfx_name = '01_hit_npc_01'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_2', skip = true, portraitname = 'battleball_girl'})
		--거기 서서 뭐하는 거야?

		party_util.jump(0.5, 0.5)
		party_util.set_anim({name = 'embarrassed'})

		camera_util.shake(0.4, 0.3)

		music_player:PlaySfxOneShot('03_dialogue_negative_02')
		character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_3', bubble_type = 'shout', skip = true, portraitname = 'battleball_girl'})
		--빨리 뛰어!
		character_util.remove_anim_and_emotion(self.baseball)

		party_util.remove_animation()

		character_util.move_waypoint_async(self.baseball,
				 self.baseball.Position + vector(-8, 0, 0),
				6, true, nil, nil, 'left', true)

		character_util.set_position(self.baseball, vector(-17, 0, 9))
		self.batting_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.batting_training, self))

		self.inner_progress = 2
	end
end

function local_class:baseball_fight()
	while true do
		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_4', portraitname = 'battleball_girl'})
		--그렇게해서 티탄 자이언츠를 이길 수 있겠어?

		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_5', portraitname = 'battleball_girl'})
		--공격! 제대로 점수 내보자고!

		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_12_6', portraitname = 'battleball_girl'})
		--피해! 잡히면 실점이야!
	end
end

function local_class:batting_training()
	self.baseball.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	character_util.set_anim(self.baseball, {name = 'twohand_attack', sfx_name = '02_normal_slash_01'})
	character_util.set_emotion(self.baseball, {name = 'burning'})
	while true do
		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_11_1', portraitname = 'battleball_girl', use_3d_dialogue_voice = true })
		--배트를 휘두르는 만큼!

		wait_for_sec(0.5)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_11_2', portraitname = 'battleball_girl', use_3d_dialogue_voice = true })
		--강해지는 법이야!
	end
end

-- zone에 다시 들어오면 도와달라고 요청
function local_class:baseball_ask_again()
	stop_coroutine(self.batting_coroutine)

	speech_bubble_util.remove_bubble(self.baseball)

	character_util.align_party(self.baseball,'down', 1, 'arc')

	wait_for_sec(0.5)

	character_util.remove_anim_and_emotion(self.baseball)

	character_util.set_direction(self.baseball, 'down')

	wait_for_sec(0.5)

	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_8', skip = true, portraitname = 'battleball_girl'})
	--내 훈련을 도와주는거야?

	yield_return_func(self.baseball_ask_help, self)
end

-- 어디론가 먼저 가서 배팅 연습하는 배틀볼 소녀
function local_class:baseball_run(index)
	character_util.convert_to_npc(self.baseball)
	self.baseball.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance

	character_util.set_emotion(self.baseball, {name = 'burning'})
	character_util.move_waypoint_async(self.baseball,
			{ field:GetMarker('battle_'..index..'_exit').position,
			  field:GetMarker('battle_'..index..'_move_pos').position },
			8, true, nil, nil, nil, true)

	local target = field:GetMarker('battle_'..index..'_target_pos')

	character_util.set_position(self.baseball, target.position)
	character_util.set_direction(self.baseball, target.direction)

	self.batting_coroutine = coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.batting_training, self))
end

-- 송구 트레이닝 시작
function local_class:baseball_pass_ball()
	local bomb_marker = field:GetMarker('battle_ball_training_1')

	character_util.remove_anim_and_emotion(self.baseball)

	stop_coroutine(self.batting_coroutine)
	speech_bubble_util.remove_bubble(self.baseball)

	character_util.align_party(self.baseball,'down', 1, 'arc')

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')

	character_util.set_emotion(self.baseball, {name = 'burning'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_13', skip = true, portraitname = 'battleball_girl'})
	--수비의 기본은 정확한 송구지!
	character_util.remove_emotion(self.baseball)

	camera_util.move_async(vector(-17, 0, 27), 1)
	wait_for_sec(1)
	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})

	character_util.set_direction(self.baseball, 'right')
	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_14', skip = true, portraitname = 'battleball_girl'})
	--내가 폭탄을 던져주면, 네가 받아서 저 바위에 던지는 거야!
	character_util.remove_anim(self.baseball)

	character_util.move_waypoint_async(self.baseball,
			bomb_marker.position,
			5, false, nil, nil, 'left', true)

	self.baseball.CrashBehaviour = CS.Oak.NPCCrashBehaviour.Instance

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.baseball_throw_bomb, self, false))
end

-- 실제로 여기서 폭탄을 들어서 던진다
function local_class:baseball_throw_bomb(type)
	if type == 1 then
		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_17_2', portraitname = 'battleball_girl'})
		--이대로 한 번 더!
	elseif type == 2 then
		wait_for_sec(1)

		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_16', portraitname = 'battleball_girl'})
		--괜찮아, 괜찮아! 한 번 더 간다!
	end

	local bomb = get_field_object('training_bomb')

	character_util.set_direction(self.baseball, 'left')

	command_util.execute_holdup(self.baseball, bomb, self.baseball.Position)

	wait_for_sec(1.5)

	character_util.set_direction(self.baseball, 'right')

	speech_bubble_util.show_speech_bubble(self.baseball,
			{ key = 'substage_giant_yeti_15', portraitname = 'battleball_girl'})
	--자, 받아!

	wait_for_sec(1)

	command_util.execute_throw(self.baseball, bomb, vector(1, 0, 0),
			self.baseball.Position, 8, false)
end

function local_class:training_1_pass()
	camera_util.move_async(self.baseball.Position, 0.5)

	local clap_sfx = music_player_util.play_sfx({
		sfx_name = '01_clap_01', loop = true,
		type_priority = CS.Oak.SfxTypePriority.Loop, player_priority = CS.Oak.SfxPlayerPriority.Npc
	})

	character_util.set_emotion(self.baseball, {name = 'smile'})
	character_util.set_anim(self.baseball, {name = 'clap'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_17', skip = true, portraitname = 'battleball_girl'})
	--제법인데?

	clap_sfx:FadeOut(0.2)

	character_util.set_anim(self.baseball, {name = 'cross_arm'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_17_1', skip = true, portraitname = 'battleball_girl'})
	--그치만 이정돈 아기 배틀볼단도 할 수 있는 레벨이야.

	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	character_util.set_emotion(self.baseball, {name = 'attack'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_18', skip = true, portraitname = 'battleball_girl'})
	--자만하지 말고 다음 훈련으로 향한다. 실시!
	character_util.remove_anim_and_emotion(self.baseball)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.baseball_run, self, 2))

	wait_for_sec(1)

	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})

	for i = 1, 2 do
		local yeti = get_character(string.format("battle4_%d", i))
		character_util.set_death_type(yeti, 'none')
	end
end

function local_class:baseball_jump()
	character_util.remove_anim_and_emotion(self.baseball)

	stop_coroutine(self.batting_coroutine)
	speech_bubble_util.remove_bubble(self.baseball)

	local info = CS.Oak.WaypointMoveInfo.Create(self.baseball.Position + vector(-7, 0, 0),
			6, false, CS.Oak.Direction.Right)
	local jump_duration = info:GetDuration(self.baseball.Position)

	music_player:PlaySfxOneShot('01_jump_01')

	character_util.jump(self.baseball, 3, jump_duration)
	CS.Oak.CharacterControllerScreenplayState.MoveWaypoints(self.baseball, info)
end

function local_class:training_2_setting()
	for i = 1, 2 do
		local yeti = get_character(string.format("battle4_%d", i))
		yeti.Holdable = CS.Oak.Holdable()
		yeti.Holdable.BounceSfxHandleName = '01_hit_npc_01'
	end

	character_util.convert_to_npc(self.baseball)
	local marker = field:GetMarker('battle_ball_training_2')

	character_util.move_waypoint_async(self.baseball,
			marker.position,
			5, false, nil, nil, 'left', true)

	character_util.align_party(self.baseball,'left', 1, 'arc')

	character_util.set_emotion(self.baseball, {name = 'tired'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_19', skip = true, portraitname = 'battleball_girl'})
	--이 예티…

	music_player:PlaySfxOneShot('01_gatcha_point_01')
	music_player:PlaySfxOneShot('03_dialogue_emphasize_01')

	character_util.set_emotion(self.baseball, {name = 'greed'})
	character_util.set_anim(self.baseball, {name = 'twohand_attack', sfx_name = '02_normal_slash_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_20', skip = true, portraitname = 'battleball_girl'})
	--타격 연습하기 딱인데?

	character_util.set_emotion(self.baseball, {name = 'burning'})
	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_21', skip = true, portraitname = 'battleball_girl'})
	--나한테 던져 줄래?
	character_util.remove_anim(self.baseball)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.finding_target, self))
end

-- 타겟 검색
function local_class:finding_target()
	local finding = true
	local yeti = nil

	while finding do
		local target_list = field:GetFieldObjectsInRadius(self.baseball.Position, 1.2)
		for k, v in pairs(target_list) do
			if v.Name == 'battle4_1' or v.Name == 'battle4_2' then
				if lua_helper.type_compare(v.FieldObjectBehaviour.CurrentState, CS.Oak.FieldObjectThrownState) then
					--and v.Position.y > 0.2 then
					finding = false
					self.hit_yeti_count = self.hit_yeti_count + 1
					yeti = v
				end
			end
		end

		target_list:Dispose()
		coroutine.yield(nil)
	end

	yield_return_func(self.training_2_break_rock, self, yeti)
end

function local_class:training_2_break_rock(yeti)
	stage.FieldUIManager:Hide()
	user_party:StopAndDisableControl()

	local rock = get_field_object('training_rock_' .. self.hit_yeti_count + 1)
	character_util.jump(self.baseball, 0.5, 0.3)
	character_util.set_anim(self.baseball, {name = 'twohand_attack2', loop = false, scale = 2,
											sfx_name = '02_normal_slash_01'})
	wait_for_sec(0.22)

	local idle_state = CS.Oak.CharacterIdleState.Create(yeti);
	message_system:SendSync(yeti, CS.Oak.StateChangeEvent.Create(idle_state))

	unity_object_pool.GetOrCreate('FX_lasthit'):Instantiate(yeti.Position)
	unity_object_pool.GetOrCreate('FX_hit'):Instantiate(yeti.Position)

	music_player:PlaySfxOneShot('01_fall_down_01')

	camera_util.move(rock.Position, 0.3)
	character_util.spine_rotate(yeti, 360 * 1, 0.3)
	yield_return_func(move_util.move_to_routine, yeti,
			rock.Position + vector(0, 0, -1.2),	{ duration = 0.3})

	coroutine.yield(nil)

	local damage_info = CS.Oak.DamageInfo()
	damage_info.type = CS.Oak.DamageType.Explosion | CS.Oak.DamageType.AffectGimmick
	damage_info.sender = user_party_leader
	damage_info.target = rock
	damage_info.damage = 100

	command_util.execute_damage(damage_info)

	coroutine.yield(nil)

	camera_util.shake(0.2, 0.5)

	local cass = CS.Oak.CharacterAirSpinState.Create(yeti,
			unity_class.vector3.right * 3, 1, 0.15, true, true)
	message_system:Send(yeti.CharacterBehaviour, CS.Oak.StateChangeEvent.Create(cass))

	character_util.remove_anim(self.baseball)

	wait_for_sec(1)

	camera_util.move_async(user_party_leader.Position, 1, {end_target = user_party_leader})

	if self.hit_yeti_count == 1 then
		character_util.set_emotion(self.baseball, {name = 'burning'})
		speech_bubble_util.show_speech_bubble(self.baseball,
				{ key = 'substage_giant_yeti_22', portraitname = 'battleball_girl'})
		--좋아, 한 번 더!

		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.finding_target, self))
	else
		self.inner_progress = 9

		character_util.align_party(self.baseball,'left', 1, 'arc')

		wait_for_sec(0.5)

		character_util.set_emotion(self.baseball, {name = 'attack'})
		character_util.set_anim(self.baseball, {name = 'jingak', sfx_name = '01_hit_npc_01'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_23', skip = true, portraitname = 'battleball_girl'})
		--으음.. 가벼워! 가벼워! 가벼워!!
		character_util.remove_emotion(self.baseball)

		character_util.set_anim(self.baseball, {name = 'question', loop = false})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_23_1', skip = true, portraitname = 'battleball_girl'})
		--딱 2배 정도만 더 무거우면 좋을 텐데 말야.

		character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
		speech_bubble_util.show_speech_bubble_async(self.baseball,
				{ key = 'substage_giant_yeti_23_2', skip = true, portraitname = 'battleball_girl'})
		--빨리 그 거대한 놈을 보러 가야겠어!
		character_util.remove_anim(self.baseball)

		--yield_return_func(self.baseball_run, self, 4)
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.baseball_run, self, 4))
	end

	stage.FieldUIManager:Show()
	user_party:ResetControllers()
end

function local_class:ending()
	music_player:PlayStageMusic(CS.Oak.StageBgmState.Muted, 1.5)

	screen_util.fade_out_async(1.5, unity_class.color.black, 'linear')

	field:Tint('night', unity_color({ 0.23, 0.23, 0.53, 0.3 }), 0.1)
	camera_util.move(field:GetMarker('campfire').position, 0.1)

	wait_for_sec(1.5)

	local campfire = get_field_object("campfire")
	campfire.Position = field:GetMarker('campfire').position + vector(-0.5, 0, 0)
	command_util.execute_burn(user_party_leader, campfire)

	character_util.convert_to_npc(self.baseball)
	character_util.set_position(self.baseball, field:GetMarker('battle_ball_training_3').position)
	character_util.set_direction(self.baseball, 'left')
	character_util.set_emotion(self.baseball, {name = 'smile'})
	--character_util.set_anim(self.baseball, {name = 'eat'})
	local drop_items = {}
	drop_items[0] = drop_item_util.create_item(
		{ pos = self.baseball.Position +
				CS.Oak.DirectionExtensions.ToVector3(self.baseball.Direction) * 0.5 + vector(0, 0, 0.2),
		  itemid = 20032, notforinven = true, sprscale = 2, lootstate = 'dontfindlooter' })

	for i = 0, user_party.Count - 1 do
		local party_marker = field:GetMarker('campfire_party_' .. i + 1)
		character_util.set_emotion(user_party[i], {name = 'smile'})
		character_util.set_position(user_party[i], party_marker.position)
		character_util.set_direction(user_party[i], party_marker.direction)
	end

	screen_util.fade_in_async(1.5, unity_class.color.black, 'linear')

	local fire_sfx = music_player_util.play_sfx({
		sfx_name = '01_fire_01', loop = true,
		type_priority = CS.Oak.SfxTypePriority.Loop, player_priority = CS.Oak.SfxPlayerPriority.Npc
	})

	wait_for_sec(0.5)

	for i = 0, user_party.Count - 1 do
		music_player:PlaySfxOneShot('01_throw_01')
		character_util.set_anim(self.baseball, {name = 'bomb_attack', loop = false})
		drop_items[i + 1] = drop_item_util.create_item(
				{ pos = self.baseball.Position, target = user_party[i].Position
						+ CS.Oak.DirectionExtensions.ToVector3(user_party[i].Direction) * 0.5,
				  itemid = 20032, notforinven = true, sprscale = 2, lootstate = 'dontfindlooter' })
		wait_for_sec(0.5)
		character_util.remove_anim(self.baseball)
	end

	character_util.set_anim(self.baseball, {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_23_3', skip = true, portraitname = 'battleball_girl'})
	--자, 여기 예티 대령이오!

	party_util.set_emotion({name = 'tired'})

	for i = 0, user_party.Count - 1 do
		character_util.show_emoticon(user_party[i], nil, 'sweat')
	end

	wait_for_sec(2.5)

	character_util.show_emoticon_async(self.baseball, nil, 'silence')

	character_util.remove_anim(self.baseball)

	character_util.set_emotion(self.baseball, {name = 'tired'})

	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_23_4', skip = true, portraitname = 'battleball_girl'})
	--왜 그렇게 봐?

	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_23_5', skip = true, portraitname = 'battleball_girl'})
	--예티가 최고의 훈련 상대인 건, 예티가 최고로 맛있기 때문이라고.

	character_util.set_emotion(self.baseball, {name = 'smile'})
	character_util.set_anim(self.baseball, {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_23_6', skip = true, portraitname = 'battleball_girl'})
	--그렇게 보지 말고 어서 먹어 봐.
	character_util.remove_anim(self.baseball)

	local branches = create_generic_list(CS.Oak.TalkBranch)
	local wait_for_branch = true
	local eat = false

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_23_7'),
		--거절한다.
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
		end})

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_23_9'),
		--예티를 먹는다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
			eat = true
		end})

	while not eat do
		ui_overlay_util.push_overlay(user_party_leader, branches)

		while wait_for_branch do
			coroutine.yield(nil)
		end

		wait_for_branch = true

		if not eat then
			character_util.set_anim(user_party_leader, {name = 'release', sfx_name = '01_swing_01'})
			wait_for_sec(0.5)
			character_util.remove_anim(user_party_leader)

			party_util.jump(0.5, 0.5)
			party_util.set_emotion({name = 'surprise'})

			character_util.set_anim(self.baseball, {name = 'attack'})
			character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
			camera_util.shake(0.4, 0.3)

			music_player:PlaySfxOneShot('03_dialogue_negative_02')

			speech_bubble_util.show_speech_bubble_async(self.baseball,
					{ key = 'substage_giant_yeti_23_8', skip = true, bubble_type = 'shout',
					  portraitname = 'battleball_girl'})
			--이걸 먹는거 까지가 훈련이라고!
			character_util.remove_anim_and_emotion(self.baseball)

			party_util.set_emotion({name = 'tired'})
		end
	end

	local eat_sfx = music_player_util.play_sfx({
		sfx_name = '01_eat_01', loop = true
	})
	party_util.set_anim({name = 'eat'})

	wait_for_sec(1)

	eat_sfx:FadeOut(0.2)

	music_player:PlaySfxOneShot('01_player_jump_01')

	party_util.remove_animation()
	party_util.jump(0.5, 0.5)
	party_util.set_emotion({name = 'surprise'})

	wait_for_sec(0.5)

	music_player:PlaySfxOneShot('03_dialogue_tipsy_01')

	character_util.set_emotion(self.baseball, {name = 'doyagao'})
	character_util.set_anim(self.baseball, {name = 'victory_get', loop = false})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_24', skip = true, portraitname = 'battleball_girl'})
	--어때, 맛있지?
	character_util.remove_anim(self.baseball)

	branches:Clear()
	wait_for_branch = true

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_25'),
		--고기는 사랑이다.
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait_for_branch = false
		end})

	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_26'),
		--예티가 이렇게 맛있는지 몰랐다.
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait_for_branch = false
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	while wait_for_branch do
		coroutine.yield(nil)
	end

	party_util.set_emotion({name = 'smile'})
	party_util.set_anim({name = 'eat'})

	music_player:PlaySfxOneShot('01_bad_fairy_01')

	for i = 0, user_party.Count - 1 do
		character_util.show_emoticon(user_party[i], nil, 'heart')
	end

	character_util.remove_anim(user_party_leader)
	character_util.remove_anim(self.baseball)
	character_util.set_emotion(self.baseball, {name = 'smile'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_27', skip = true, portraitname = 'battleball_girl'})
	--그치?

	character_util.set_anim(self.baseball, {name = 'dance'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_28', skip = true, portraitname = 'battleball_girl'})
	--훈련 뒤 먹는 고기는 역시 최고라니까!

	local eat_sfx = music_player_util.play_sfx({
		sfx_name = '01_eat_01', loop = true
	})
	character_util.set_anim(self.baseball, {name = 'eat'})

	character_util.set_anim(user_party_leader, {name = 'eat'})
	wait_for_sec(1)

	eat_sfx:FadeOut(2)
	fire_sfx:FadeOut(2)
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	field:RemoveTint(nil, 0.1)
	command_util.execute_extinguish(user_party_leader, campfire)
	for i = 0, user_party.Count - 1 do
		character_util.remove_anim(user_party[i])
		character_util.remove_emotion(user_party[i])
	end

	character_util.remove_anim(self.baseball)

	for i = 0, #drop_items do
		drop_items[i]:ConsumeComplete()
	end

	drop_items = nil

	--character_util.set_position(user_party_leader,
	--		self.baseball.Position + CS.Oak.DirectionExtensions.ToVector3(self.baseball.Direction) * 0.825)

	wait_for_sec(1)

	music_player:PlayStageMusic(CS.Oak.StageBgmState.Field, 1)
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	field_ui_util.show_narration_async({ key = 'substage_giant_yeti_29'})
	--밤새도록 배틀볼 이야기를 하며, 예티 바베큐를 즐겼다.

	local clap_sfx = music_player_util.play_sfx({
		sfx_name = '01_clap_01', loop = true,
		type_priority = CS.Oak.SfxTypePriority.Loop, player_priority = CS.Oak.SfxPlayerPriority.Npc
	})

	character_util.set_anim(self.baseball, {name = 'clap'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_30', skip = true, portraitname = 'battleball_girl'})
	--아, 잘 먹었다.

	clap_sfx:FadeOut(0.2)

	character_util.set_anim(self.baseball, {name = 'cast2'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_31', skip = true, portraitname = 'battleball_girl'})
	--꽤 재밌는 훈련이었어.

	character_util.set_anim(self.baseball, {name = 'cross_arm'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_32', skip = true, portraitname = 'battleball_girl'})
	--간만에 아기 배틀볼단 추억도 떠올랐고 말야.

	character_util.set_anim(self.baseball, {name = 'release', sfx_name = '01_swing_01'})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_33', skip = true, portraitname = 'battleball_girl'})
	--다음엔 훈련보단 같이 또 뭐라도 먹자고.

	music_player:PlaySfxOneShot('01_jump_01')
	music_player:PlaySfxOneShot('03_dialogue_positive_01')

	character_util.set_anim(self.baseball, {name = 'victory_get', loop = false})
	speech_bubble_util.show_speech_bubble_async(self.baseball,
			{ key = 'substage_giant_yeti_34', skip = true, portraitname = 'battleball_girl'})
	--고기라던가, 고기라던가… 고기라던가 말야!
	character_util.remove_anim(self.baseball)

	character_util.set_anim(user_party_leader, {name = 'nod'})
	wait_for_sec(0.9)
	character_util.remove_anim(user_party_leader)

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(self.training_again, self))

	camera_util.move_async(user_party_leader.Position, 0.5, {end_target = user_party_leader})
end


function local_class:training_again()
	self.baseball.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	character_util.set_emotion(self.baseball, {name = 'burning'})
	speech_bubble_util.show_speech_bubble(self.baseball,
			{ key = 'substage_giant_yeti_35', portraitname = 'battleball_girl'})
	--자, 다시 특훈 시작이다!

	wait_for_sec(1)

	character_util.move_waypoint_async(self.baseball,
			{self.baseball.Position + vector(-2, 0, 0),
			 			self.baseball.Position + vector(-2, 0, -7)},
			8, true, nil, nil, 'down', true)
	character_util.remove_emotion(self.baseball)
	character_util.set_position(self.baseball, vector(999, 0, 999))
end

function local_class:open_box()
	local wait = true
	local open = true

	local branches = create_generic_list(typeof(CS.Oak.TalkBranch))
	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_box_answer_1'),
		Tendency = CS.Oak.TalkTendency.Mercy,
		Callback = function()
			wait = false
			open = false
		end})
	branches:Add({
		Text = game_string:GetString('substage_giant_yeti_box_answer_2'),
		Tendency = CS.Oak.TalkTendency.Brutal,
		Callback = function()
			wait = false
			open = true
		end})

	ui_overlay_util.push_overlay(user_party_leader, branches)

	stage.FieldUINarrationBox:Show()
	yield_return(stage.FieldUINarrationBox, 'SetNarration',
			game_string:GetString('substage_giant_yeti_box_narration'), 0, 1.0, false)

	while wait do
		coroutine.yield(nil)
	end

	yield_return(stage.FieldUINarrationBox, 'HideAnimation')

	local box = get_field_object('food_box')
	if open then
		--message_system:Send(box, CS.Oak.InteractEvent.Create(user_party_leader, box))
		--
		--wait_for_sec(7)

		--TODO: develop 의 코드가 적용되면 위의 코드로 다시 바꿔야함.
		self.is_food_box_open = true

		local diff = (box.Bounds.center - user_party_leader.Position).normalized

		user_party_leader.SpineController:DeviateLocal(diff * 0.3, 0.12, 0.15)

		character_util.set_anim(user_party_leader, {name = 'bomb_attack', loop = falsee})

		wait_for_sec(0.09)

		music_player:PlaySfxOneShot('01_cliff_01')

		box:Shake(0.03, 10)

		camera_util.resize_to(3.75, 1)
		camera_util.move(vector_util.get_x0z(box.Bounds.center), 1)

		music_player:PlaySfxOneShot('02_treasure_open_01')

		local box_animator = box.transform:GetComponentInChildren(
				typeof(CS.UnityEngine.Animator))

		box_animator:Play('open')

		wait_for_sec(0.15)

		box:CancelShake()

		wait_for_sec(0.25)

		character_util.remove_anim(user_party_leader)

		character_util.set_direction(user_party_leader,
				CS.Oak.DirectionExtensions.GetSideDirection(user_party_leader.Direction))

		character_util.set_emotion(user_party_leader, {name = 'smile'})
		character_util.set_anim(user_party_leader, {name = 'victory_extra'})

		wait_for_sec(1)

		local item_ids = { 20014, 20032, 20038, 20048, 20081, 20086, 20110, 20136 }
		local items = {}

		for i = 1, #item_ids do
			music_player:PlaySfxOneShot('03_treasure_item_popup_01')

			items[i] = drop_item_util.create_item({itemid = item_ids[i], pos = box.Bounds.center,
												   target = box.Position + vector(-0.5, 0, -2),
												   notforinven = true, amount = 1, lootstate = 'dontfindlooter'})
			camera_util.shake(0.06, 0.2)
			wait_for_sec(0.5)
		end

		wait_for_sec(1)

		for i = 1, #items do
			items[i].ConsumeTarget = user_party_leader
			items[i]:Fly()
		end

		camera_util.resize_to_default(0.2)
		camera_util.move_async(user_party_leader.Position, 0.2, {end_target = user_party_leader})

		character_util.remove_anim_and_emotion(user_party_leader)

		box.Interactable = CS.Oak.NonInteractable.Instance

	end
end

return {
	create = function(cs_controller, scene_class)
		return local_class(cs_controller, scene_class)
	end
}
