local local_class = newclass('NightmareFutureCastle6Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 리셋 연출중인지 체크하는 플래그
	self.is_reset = false

	-- 연기 이펙트들
	self.smokes = nil

	self.get_burning_skull = function() return get_character('burning_skull') end
	self.get_trio_boss = function() return get_character('trio_boss') end
	self.get_trio_man = function() return get_character('trio_man') end
	self.get_trio_panda = function() return get_character('trio_panda') end
	self.get_princess = function() return get_character('princess') end

	self.is_saw_burning_skill = false
	self.is_in_burning_grid = false
	self.is_enter_trio_zone = false
	self.is_interact_trio = false

	self.burning_skull_key = 0
	self.trio_key = 1
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.GotCrashedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))

	character_util.remove_relate_event(self.get_burning_skull(), self.cs_controller)
	character_util.remove_relate_event(self.get_trio_boss(), self.cs_controller)
	character_util.remove_relate_event(self.get_trio_man(), self.cs_controller)
	character_util.remove_relate_event(self.get_trio_panda(), self.cs_controller)
	self.cs_controller = nil

	if self.smokes ~= nil then
		for i = 1, #self.smokes do
			self.smokes[i]:Dispose()
			self.smokes[i] = nil
		end
	end
	self.smokes = nil
end

--region load_resource
function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	local resholder = CS.Foundations.ResourceHolder()

	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.GotCrashedEvent), 'on_got_crashed_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')

	self.get_burning_skull().Interactable:AddListener(self.cs_controller)

	unity_object_pool.GetOrCreate('fx_black_smoke')

	if stage_progress:GetCustomData(self.burning_skull_key) then
		self.is_saw_burning_skill = true
	end


	if stage_progress:GetCustomData(self.trio_key) then
		self.is_enter_trio_zone = true
		self:set_trio()
	else
		self.get_trio_boss().Interactable:AddListener(self.cs_controller)
		self.get_trio_man().Interactable:AddListener(self.cs_controller)
		self.get_trio_panda().Interactable:AddListener(self.cs_controller)
	end

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync,
			resholder, 'theatres/sealed_castle', 'bg_sealedkingdom', function(prefab)
				local bg = CS.UnityEngine.GameObject.Instantiate(prefab)
				local bg_transform = bg.transform
				bg_transform.localPosition = field:GetMarker('bg').position
			end)
end
--endregion

--region launch
function local_class:need_on_launch()
	return false
end

function local_class:on_launch(start_point_name)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end
	return false
end

function local_class:on_stage_loaded_event(e)
	for i = 1, 4 do
		local resistance = get_character('field_resistance_' .. i)
		character_util.set_with_marker(resistance, field:GetMarker('field_resistance_' .. i))
		character_util.set_anim_and_emotion(resistance, {name = 'prostrate'}, {name = 'damaged'})
	end

	self.smokes = {}
	for i = 1, 11 do
		local marker = field:GetMarker('smoke_' .. i)
		self.smokes[i] = unity_object_pool.GetOrCreate('fx_black_smoke'):Instantiate(marker.position)
	end

	for i = 1, 5 do
		local scout = get_character('invader_scout_' .. i)
		scout.Hitbox = CS.Oak.Hitbox(vector(0.55, 0.75, 0.45))
	end

	command_util.execute_burn(nil, get_field_object('hot_signboard'), true)
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 2 then
		if e.Params[0] == 'wasted' and self.is_reset == false then
			sp_util.play_normal_screenplay(self.invader_detect, self, e.Sender)
		end
	end

	return false
end

function local_class:on_got_crashed_event(e)
	if lua_helper.reference_equals(e.Crash.other, user_party.Leader) and string.find(e.Crash.self.Name, 'invader_scout_') then
		sp_util.play_normal_screenplay(self.invader_detect, self, e.Crash.self)
	end

	return false
end

function local_class:on_zone_enter_event(e)
	--bgm management
	if e.FullEnter == false then return end
	if e.FieldObject ~= user_party.Leader then return end
	local zone_name = e.Zone.Name

	if zone_name == 'forest_bgm' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.set_bgm, self, 'bgm_forest_bright'))

	elseif zone_name == 'futurecastle_bgm' then
		coroutine_manager:StartCoroutine(stage.StageGameObject,
				util.cs_generator(self.set_bgm, self, 'ondemand/v2_3_futurecastle/audio/music/bgm_futurecastle_main:bgm_futurecastle_main'))
	end

	if zone_name == 'trio_zone' and not self.is_enter_trio_zone then
		self.is_enter_trio_zone = true
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.enter_trio_zone, self))
		return true
	end

	return false
end

function local_class:on_interact_event(e)
	local burning_skull = self.get_burning_skull()
	if lua_helper.reference_equals(e.Target, burning_skull) then
		if self.is_saw_burning_skill then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
								speech_bubble_util.show_speech_bubble_async, burning_skull, { key = 'nightmare_futurecastle_burning_skull_5'}))
		else
			sp_util.play_normal_screenplay(self.interact_burning_skull, self)
		end
		return true
	end

	if lua_helper.reference_equals(e.Target, self.get_trio_man()) or lua_helper.reference_equals(e.Target,
			self.get_trio_boss()) or lua_helper.reference_equals(e.Target, self.get_trio_panda()) then
		sp_util.play_normal_screenplay(self.interact_trio, self)
		return true
	end
	return false
end

function local_class:on_camera_grid_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == 'burning_skull_grid' and not self.is_in_burning_grid then
		self.is_in_burning_grid = true

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.set_burning_skull_tint, self))
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == 'burning_skull_grid' and self.is_in_burning_grid then
		self.is_in_burning_grid = false
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(
				self.remove_burning_skull_tint, self))
	end

	return false
end

--endregion

function local_class:set_bgm(bgm_name)
	music_player_util.play_stage_music({ name = bgm_name, state = 'event', mix = 1 })
	music_player_util.set_stage_music_clip_async({ name = bgm_name, state = 'field' })
end

function local_class:invader_detect(supervisor)
	self.is_reset = true
	character_util.set_emotion(user_party.Leader, {name = 'surprise'})
	character_util.set_anim(user_party.Leader, {name = 'embarrassed'})

	camera_util.shake(0.3, 0.5)
	music_player:PlaySfxOneShot('03_dialogue_negative_01')
	music_player:PlaySfxOneShot('03_runaway_01')

	character_util.look_at(supervisor, user_party.Leader)
	character_util.set_anim(supervisor, {name = 'release'})
	speech_bubble_util.show_speech_bubble_async(supervisor, {key = 'nightmare_titantavern_gnome_detect',
															 bubble_type = 'shout', skip = true})
	--거기 누구냐!

	music_player:PlaySfxOneShot('01_drown_01')
	screen_util.fade_out_circular_async(0.5, 'linear')

	character_util.remove_anim(supervisor)
	character_util.remove_anim_and_emotion(user_party.Leader)
	party_util.align_party(field:GetMarker('supervisor_reset').position, 'down', 0)
	wait_for_sec(0.5)

	screen_util.fade_in_circular_async(0.5, 'linear')
	self.is_reset = false

	self:hide_gnome_stat()
end

function local_class:hide_gnome_stat()
	local jack = get_character('fat_gnome')
	field_ui_manager:RemoveUI(jack, CS.Oak.FieldUiType.CharacterStats)

	for i = 1, 9 do
		local gnome = get_character('gnome_' .. i)
		field_ui_manager:RemoveUI(gnome, CS.Oak.FieldUiType.CharacterStats)
	end
end

function local_class:set_burning_skull_tint()
	wait_for_sec(0.1)
	field:Tint('burning_skull_tint', unity_color({ 1, 0.35, 1, 1 }), 0.2)
end

function local_class:remove_burning_skull_tint()
	wait_for_sec(0.1)
	field:RemoveTint('burning_skull_tint', 0.1)
end

function local_class:interact_burning_skull()
	self.is_saw_burning_skill = true
	local burning_skull = self.get_burning_skull()
	party_util.align_party(burning_skull.Position, 'right', 1, 'linear')

	music_player:PlaySfxOneShot('01_fire_01')
	-- 날씨 좋네… 이럴 때 같이 소풍이라도 갈 친구가 있었으면…
	speech_bubble_util.show_speech_bubble_async(burning_skull, { key = 'nightmare_futurecastle_burning_skull_1', skip = true })
	-- 안녕, 꼬마 친구? 나 같은 외톨이한테 말을 걸어주다니 참 친절하구나.
	speech_bubble_util.show_speech_bubble_async(burning_skull, { key = 'nightmare_futurecastle_burning_skull_2', skip = true })
	-- 예전에도 숲속에서 말을 걸어주던 친구가 내 첫 FB 친구가 됐었는데…
	speech_bubble_util.show_speech_bubble_async(burning_skull, { key = 'nightmare_futurecastle_burning_skull_3', skip = true })
	-- 그 이후로 한 명도 추가하지 못해서 내 친구 수는 여전히 한 명이지만 말이야.
	speech_bubble_util.show_speech_bubble_async(burning_skull, { key = 'nightmare_futurecastle_burning_skull_4', skip = true })
	-- 아무튼, 너무 가까이 오면 불이 붙을 수도 있으니까 조심하렴.
	speech_bubble_util.show_speech_bubble_async(burning_skull, { key = 'nightmare_futurecastle_burning_skull_5', skip = true })

	local stage_custom = stage_progress:SetCustomData(self.burning_skull_key, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)
end

-- 트리오를 인터렉트 후 상태로 변경
function local_class:set_trio()
	local trio_boss = self.get_trio_boss()
	local trio_man = self.get_trio_man()
	local trio_panda = self.get_trio_panda()

	character_util.set_direction(trio_boss, 'left')
	character_util.set_anim_and_emotion(trio_boss, { name = 'cross_arm' }, { name = 'tired'})
	character_util.set_emotion(trio_man, { name = 'tired' })
	character_util.set_direction(trio_man, 'right')
	character_util.set_emotion(trio_panda, { name = 'tired' })
	character_util.set_direction(trio_panda, 'right')
	trio_boss.Interactable.Talk = 'nightmare_futurecastle_trio_23'
	trio_man.Interactable.Talk = 'nightmare_futurecastle_trio_24'
	trio_panda.Interactable.Talk = 'nightmare_futurecastle_trio_25'
end

-- 트리오존 진입 이벤트
function local_class:enter_trio_zone()
	local trio_man = self.get_trio_man()
	local trio_panda = self.get_trio_panda()
	local trio_boss = self.get_trio_boss()

	character_util.set_emotion(trio_man, { name = 'tired' })
	character_util.set_direction(trio_man, 'right')

	music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = trio_man, type_priority = 'event' })
	character_util.set_animation_n_times(trio_man, { name = 'release', count = 2, sfx = '01_swing_01' })
	-- 대니, 배고프다…
	speech_bubble_util.show_speech_bubble_async(trio_man, { key = 'nightmare_futurecastle_trio_1' })

	-- 대화 시작했으면 라쿤 대사 패스
	if self.is_interact_trio then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = trio_panda, type_priority = 'event' })
	character_util.set_emotion(trio_panda, { name = 'tired' })
	character_util.set_direction(trio_panda, 'right')
	-- 너 방금 전에 밥 먹지 않았냐…?
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_2', bubble_direction = 'lt' })

	if self.is_interact_trio then
		return
	end

	music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = trio_boss, type_priority = 'event' })
	--눈만 뜨면 밥 타령이야!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_26' })
end

-- 트리오 인터랙트 이벤트
function local_class:interact_trio()
	local trio_boss = self.get_trio_boss()
	local trio_man = self.get_trio_man()
	local trio_panda = self.get_trio_panda()
	local princess = self.get_princess()

	self.is_interact_trio = true
	music_player_util.play_stage_music({name = 'bgm_trio_non_fight', state = 'event', mix_time = 2})

	speech_bubble_util.remove_bubble(trio_man)
	speech_bubble_util.remove_bubble(trio_panda)
	speech_bubble_util.remove_bubble(trio_boss)

	party_util.align_party(trio_boss.Position + vector(0.3,0,0), 'right', 1, 'linear')

	wait_for_sec(0.5)
	character_util.remove_emotion(trio_boss)
	character_util.remove_emotion(trio_man)
	character_util.remove_emotion(trio_panda)
	character_util.set_direction(trio_panda, 'right')
	character_util.set_direction(trio_boss, 'right')
	character_util.show_emoticon(trio_boss, nil, 'notice')
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')

	wait_for_sec(2)

	character_util.set_emotion(trio_boss, { name = 'attack' })
	-- 너는!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_3', skip = true })

	character_util.set_emotion(trio_boss, { name = 'smile' })
	character_util.normal_double_jump(trio_boss, true)

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	-- 몸값 높은 꼬맹이잖아!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_30', skip = true })

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.remove_emotion(trio_boss)
	character_util.set_direction(trio_boss, 'up')
	wait_for_sec(0.5)
	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(trio_boss, 'left')
	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_swing_01')
	character_util.set_direction(trio_boss, 'right')
	character_util.set_emotion(trio_boss, { name = 'smile' })

	-- 뭐야? 또 혼자 돌아다니는 거야?
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_4', skip = true })

	music_player_util.play_sfx_one_shot('01_ghost_laugh_evil_01')
	character_util.set_emotion(trio_panda, { name = 'smile' })
	character_util.set_animation_n_times(trio_panda, { name = 'attack', count = 2 })
	-- 그 애송이 자식, 너 버리고 갔구나?
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_5', skip = true, bubble_direction = 'lt' })

	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	character_util.set_anim(trio_man, { name = 'release', sfx_name = '01_swing_01' })
	-- 꼬마, 또 잡혀간다!
	speech_bubble_util.show_speech_bubble_async(trio_man, { key = 'nightmare_futurecastle_trio_6', skip = true })

	character_util.remove_anim(trio_man)
	character_util.set_emotion(princess, { name = 'tired' })
	-- …….
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'nightmare_futurecastle_trio_7', skip = true })

	music_player_util.play_sfx_one_shot('03_dialogue_evil_01')
	character_util.set_anim_and_emotion(trio_boss, { name = 'question', loop = false }, { name = 'doyagao'})
	-- 잘됐네~
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_8', skip = true })

	character_util.remove_anim(trio_boss)
	character_util.set_direction(trio_boss, 'left')
	character_util.set_anim(trio_boss, { name = 'release', sfx_name = '01_swing_01' })
	-- 대니, 팬더. 이제 우리가 이 꼬마 데려가도 방해할 사람 없는 것 같지?
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_9', skip = true })

	character_util.remove_anim(trio_boss)
	character_util.set_direction(trio_boss, 'right')
	character_util.set_anim(trio_boss, { name = 'question', loop = false })
	character_util.set_emotion(trio_panda, { name = 'doyagao' })
	character_util.normal_double_jump(trio_panda, true)
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	-- 그러네! 야, 잡자!
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_10', skip = true, bubble_direction = 'lt' })
	-- 대니, 꼬마 잡는다!
	speech_bubble_util.show_speech_bubble_async(trio_man, { key = 'nightmare_futurecastle_trio_11', skip = true })
	character_util.remove_anim_and_emotion(trio_boss)

	character_util.move_to(trio_boss, trio_boss.Position + vector(0.5, 0, 0), 3, nil, true, true)
	character_util.shake(princess, 0.02, 9999)
	music_player_util.play_sfx_one_shot('01_rustle_01')
	-- {0}이(가)… {0}이(가)…
	speech_bubble_util.show_speech_bubble_async(princess, {key= game_string:Format('nightmare_futurecastle_trio_12', user.Name, user.Name), skip = false, life_time = 1.5})

	camera_util.resize_to(3.2, 1)
	camera_util.move_async(princess.Position, 1, { ignorecameragrids = true })
	character_util.set_emotion(princess, { name = 'cry' })
	music_player_util.play_sfx_one_shot('01_rustle_01')
	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	-- {0}이(가)… 없어… 어디 갔는지 모르겠어…
	speech_bubble_util.show_speech_bubble_async(princess, {key= game_string:Format('nightmare_futurecastle_trio_13', user.Name), skip = false, life_time = 1.5})

	camera_util.resize_to_default(0.5)
	camera_util.return_to_leader(0.5)

	character_util.normal_jump(trio_man)
	character_util.normal_jump(trio_panda)
	character_util.normal_jump(trio_boss, true)

	music_player_util.play_sfx_one_shot('03_runaway_01')
	character_util.set_anim_and_emotion(trio_boss, { name = 'embarrassed' }, { name = 'surprise'})
	character_util.set_anim_and_emotion(trio_man, { name = 'embarrassed' }, { name = 'surprise'})
	character_util.set_anim_and_emotion(trio_panda, { name = 'embarrassed' }, { name = 'surprise'})

	character_util.move_to_async(trio_boss, trio_boss.Position + vector(-0.5,0,0), nil, 2, false)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	-- 왜… 왜 울어…!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_14', skip = true })

	character_util.set_emotion(trio_panda, { name = 'scared' })
	-- 진짜 혼자였던 거야?!
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_15', skip = true, bubble_direction = 'lt' })
	character_util.set_emotion(trio_man, { name = 'scared' })
	-- 대니, 진심 아니었다!
	speech_bubble_util.show_speech_bubble_async(trio_man, { key = 'nightmare_futurecastle_trio_16', skip = true })

	character_util.set_emotion(princess, { name = 'tired' })
	character_util.stop_shake(princess)

	character_util.set_anim_and_emotion(trio_boss, { name = 'idle' }, { name = 'tired'})
	character_util.set_anim_and_emotion(trio_man, { name = 'idle' }, { name = 'tired'})
	character_util.set_anim_and_emotion(trio_panda, { name = 'idle' }, { name = 'tired'})

	wait_for_sec(1)

	music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
	character_util.set_anim(trio_boss, { name = 'release', sfx_name = '01_swing_01' })
	-- 에… 에이~ 잠깐 어디 간 거겠지!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_17', skip = true })
	character_util.remove_anim(trio_boss)

	music_player_util.play_sfx_one_shot('03_runaway_01')
	character_util.set_anim(trio_panda, { name = 'embarrassed' })
	-- 걱… 걱정마…!
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_18', skip = true, bubble_direction = 'lt' })

	character_util.set_direction(trio_panda, 'left')
	character_util.set_anim(trio_panda, { name = 'question', loop = false, sfx_name = '01_rustle_01'  })
	-- 어… 그… 뭐냐…
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_27', skip = true, bubble_direction = 'lt' })

	character_util.remove_anim(trio_panda)
	character_util.set_direction(trio_panda, 'right')
	character_util.normal_double_jump(trio_panda, true)

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	-- 우… 우리가 찾아줄게!
	speech_bubble_util.show_speech_bubble_async(trio_panda, { key = 'nightmare_futurecastle_trio_28', skip = true, bubble_direction = 'lt' })

	character_util.set_direction(trio_boss, 'left')
	character_util.set_emotion(trio_boss, { name = 'surprise' })

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	music_player_util.play_sfx_one_shot('01_swing_01')
	-- 우리가 찾아줘?
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_19', skip = true })

	-- 정말…?
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'nightmare_futurecastle_trio_29', skip = true })

	character_util.set_direction(trio_boss, 'right')
	character_util.set_emotion(trio_boss, { name = 'tired' })
	character_util.set_anim(trio_boss, { name = 'release', sfx_name = '01_swing_01' })
	-- 그… 그래, 맞아! 우리가 찾아줄게!
	speech_bubble_util.show_speech_bubble_async(trio_boss, { key = 'nightmare_futurecastle_trio_20', skip = true })
	character_util.remove_anim(trio_boss)

	character_util.normal_double_jump(trio_man, true)
	-- 대니, 꼬마 우는 거 싫다!
	speech_bubble_util.show_speech_bubble_async(trio_man, { key = 'nightmare_futurecastle_trio_21', skip = true })

	character_util.nod_twice(princess)
	-- …고마워, 다들…
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'nightmare_futurecastle_trio_22', skip = true })
	character_util.remove_emotion(princess)

	character_util.remove_relate_event(trio_boss, self.cs_controller)
	character_util.remove_relate_event(trio_man, self.cs_controller)
	character_util.remove_relate_event(trio_panda, self.cs_controller)

	self:set_trio()

	music_player_util.play_stage_music({ state = 'field' })

	local stage_custom = stage_progress:SetCustomData(self.trio_key, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
