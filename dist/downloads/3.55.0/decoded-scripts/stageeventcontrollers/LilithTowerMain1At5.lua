local local_class = newclass("LilithTowerMain1At5Controller")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 스테이지 이름
	self.stage_name = 'lilithtower_1_5'

	-- field object
	self.get_pillar = function(num) return get_field_object('lobby_pillar_'..num) end

	-- 로비 이벤트 체크용
	self.section_check = false
	self.show_lobby_zone = { false, false, false, false, false, false, false }
	self.onigirl_routine = false

	--region 공주 / 리더 루프 움직임 전용
	self.princess = nil

	self.is_late_updating = false

	self.loop_start_z = -33
	self.loop_end_z = -17
	self.is_stop = false
	self.is_follow = true
	self.is_shake = true

	self.rock_effect = nil

	self.princess_walk_anim = nil

	self.get_rock_effect = function() return unity_object_pool.GetOrCreate('fx_cp11_rock_landslide_purple_small') end

	--endregion
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_stage_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.QuestProgressedEvent), 'on_quest_progressed_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	unity_object_pool.GetOrCreate('fx_cp11_rock_landslide_purple_small')

	self.get_rock_effect()

	-- 리소스 로드를 기다림
	yield_return(unity_object_pool, 'WaitAll')
end

-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local progress_list = {
		17, 18, 19, 20, 21
	}

	self:lobby_setting()

	if quest_progress ~= nil and not quest_progress.IsComplete then
		for i = 1, #progress_list do
			if quest_progress.InnerProgress == progress_list[i] then
				return true
			end
		end
	elseif quest_progress ~= nil and quest_progress.IsComplete then
		return true
	end

	return false
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.on_launch_routine, self))
end

function local_class:on_launch_routine()
	coroutine.yield(nil)

	local main_quest_id = 258
	local quest_progress = user_progress:GetStartedQuest(main_quest_id)

	local leader = nil
	local character_spec_id = 1
	if user_util.has_knight_male() then
		leader = get_character('knight_male')
		character_spec_id = 2
	else
		leader = get_character('knight_female')
	end

	if leader ~= nil then
		character_util.convert_to_manual_character(leader)

		leader.Position = vector(0, 0, -7)
	end

	get_character('princess').Position = vector(0, 0, -8)
	character_util.convert_to_party_member(get_character('princess'), user_party, true)

	if quest_progress ~= nil and (quest_progress.InnerProgress >= 20 or quest_progress.IsComplete) then
		message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 255), 0))

		-- 클리어했다면
		if quest_progress.IsComplete then
			field_ui_manager:Hide()
			party_util.stop_and_disable_control()

			party_util.position_party(vector(-76.5, 0, 32), 'up', 'linear')
			camera_util.return_to_leader(0)

			screen_util.fade_in_async(0, unity_class.color.black,'linear')
			screen_util.fade_in_circular(0.5,'linear')

			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(user_party.Leader.Position + vector(0,0,0.5),
					CS.Oak.Direction.Up, game_string:GetString(stage.Name)))

			party_util.reset_controllers()
			field_ui_manager:Show()
		end
	else
		user_party.Leader:HideWeapon(true)
	end
end

function local_class:on_event(e)
	local event_type = e:GetType()
	return false
end

function local_class:on_stage_start_event(e)
	return false
end

function local_class:on_zone_enter_event(e)
	for i = 1, #self.show_lobby_zone do
		if type_util.is_zone_full_enter(e, user_party.Leader, 'lobby_event_'.. i) and
				not self.show_lobby_zone[i] then
			self.show_lobby_zone[i] = true
			coroutine_manager:StartCoroutine(stage.StageGameObject,
					util.cs_generator(self.show_lobby_event, self, e.Zone.Name))
			return true
		end
	end
	return false
end

function local_class:on_quest_progressed_event(e)
	if e.QuestId == 258 then
		if e.CurrentProgress == 21 then
			self.section_check = true
			self:lobby_setting()
			return true
		end
	end
	return false
end

function local_class:on_stage_loaded_event(e)
	self.princess = get_character('princess')
	self.princess_walk_anim = CS.Oak.CharacterExtensions.GetCustomWalkAnimation(self.princess)

	return false
end

function local_class:on_custom_stage_event(e)
	if e:GetParamAt(0) == 'section18' then
		if e:GetParamAt(1) == 'loop_start' then
			self.is_late_updating = true
			return true

		elseif e:GetParamAt(1) == 'walk_start' then
			self.is_stop = false
			return true

		elseif e:GetParamAt(1) == 'loop_stop' then
			self.is_late_updating = false
			return true

		elseif e:GetParamAt(1) == 'walk_stop' then
			self.is_stop = true
			return true

		elseif e:GetParamAt(1) == 'shake_start' then
			coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.shake_loop, self))
			return true

		elseif e:GetParamAt(1) == 'shake_stop' then
			self.is_shake = false
			return true
		end
	end

	return false
end

function local_class:use_late_update_frame()
	return true
end

function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
	if self.is_late_updating == false then
		return
	end

	-- 무한루프 걷기
	-- is_stop 이면 일단 멈춤. 걷기 애니메이션은 연출 멈추고 시작할때 끄고 키는것으로.
	if self.is_stop == false then
		if user_party.Leader.Position.z > self.loop_end_z then
			local diff_1 = user_party.Leader.Position.z - self.loop_end_z
			local diff_2 = self.princess.Position.z - self.loop_end_z

			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.loop_start_z + diff_2)
			user_party.Leader.Position = vector_util.get_xy0(user_party.Leader.Position, self.loop_start_z + diff_1)
			if self.rock_effect ~= nil then
				self.rock_effect.transform.localPosition = self.rock_effect.transform.localPosition
						- vector(0, 0, self.loop_end_z - self.loop_start_z)
			end
		end
	end

	if user_party.Leader.Position.z - self.princess.Position.z > 0 then
		self.is_follow = true
	end

	if self.is_follow == true then
		--character_util.set_anim(self.princess, { name = self.princess_walk_anim})
		character_util.set_anim(self.princess, { name = 'twohand_walk' })
		if user_party.Leader.Position.z - self.princess.Position.z > 0.3 then
			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.princess.Position.z + (unity_class.time.deltaTime * 4))
		elseif user_party.Leader.Position.z - self.princess.Position.z + 1 > (unity_class.time.deltaTime * 2.5) then
			self.princess.Position = vector_util.get_xy0(self.princess.Position, self.princess.Position.z + (unity_class.time.deltaTime * 2.5))
		else
			self.princess.Position = vector_util.get_xy0(self.princess.Position, user_party.Leader.Position.z + 1)
			self.is_follow = false
			character_util.remove_anim(self.princess)
		end
	else
		character_util.set_anim(self.princess, { name = 'twohand_idle' })
	end
end

function local_class:shake_loop()
	while self.is_shake do
		local time_passed = 0

		while time_passed < 3 do
			if self.is_shake == false then
				break
			end
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield(nil)
		end
		if self.is_shake == false then
			break
		end

		if self.rock_effect ~= nil then
			self.rock_effect:Dispose()
		end
		local rand_x = unity_class.random.Range(-100, 200)
		local rand_z = unity_class.random.Range(-200, 700)
		rand_x = rand_x /100
		if rand_x < 0.75 and rand_x > 0.25 then
			if rand_x > 0.5 then
				rand_x = 2
			else
				rand_x = -1
			end
		end
		rand_z = rand_z /100

		music_player_util.play_sfx(
				{ sfx_name = '01_earthquake_02', volume = 0.35, type_priority = 'event', player_priority = 'object' })

		self.rock_effect = self:get_rock_effect():Instantiate(vector(rand_x, 0, user_party.Leader.Position.z + rand_z))


		camera_util.shake(0.1, 1)
		while time_passed < 4 do
			if self.is_shake == false then
				break
			end
			time_passed = time_passed + unity_class.time.deltaTime
			coroutine.yield(nil)
		end
	end
end

function local_class:lobby_setting()
	local main_quest_id = 258
	local police_quest_id = 259
	local teatime_quest_id = 262
	local beth_quest_id = 264
	local beautiful_quest_id = 265
	local nobody_quest_id = 267
	local onigirl_quest_id = 268
	local diehard_quest_id = 269
	local vlog_quest_id = 273

	-- 메인 퀘스트 section 체크
	local quest = user_progress:GetStartedQuest(main_quest_id)
	if (quest == nil or quest.InnerProgress < 21) and not self.section_check then
		return
	end

	-- 기본 NPC 배치
	for i = 1, 22 do
		local npc = get_character('lobby_setting_npc_'..i)
		local pos = field:GetMarker('lobby_pos_'..(i + 20)).position
		character_util.set_position(npc, pos)

		if i == 4 then
			character_util.set_position(get_character('lobby_setting_npc_4_1'), pos + vector(1,0,0))
		end

		if i >= 20 then
			npc.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
		end
	end



	-- 경관
	quest = user_progress:GetStartedQuest(police_quest_id)
	if quest ~= nil and quest.IsComplete and quest.Grade == 0 then
		local lobby_pos_1 = field:GetMarker('lobby_pos_1').position
		local lobby_pos_2 = field:GetMarker('lobby_pos_2').position

		local police = get_character('lobby_police')
		character_util.set_anim_and_emotion(police, { name = 'idle' }, { name = 'smile' })
		character_util.set_position(police, lobby_pos_1)
		police.Interactable.Talk = 'lilithtower_main_end_lobby_1'

		local kid = get_character('lobby_kid')
		character_util.set_anim_and_emotion(kid,{ name = 'idle' }, { name = 'awesome' })
		character_util.set_position(kid, lobby_pos_2)
		kid.Interactable.Talk = 'lilithtower_main_end_lobby_2'
	end

	-- 티타임 할머니
	quest = user_progress:GetStartedQuest(teatime_quest_id)
	if quest ~= nil and quest.IsComplete and quest.Grade == 1 then
		local lobby_pos = field:GetMarker('lobby_pos_12').position

		local grandmother = get_character('lobby_grandmother')
		character_util.set_position(grandmother, lobby_pos)
		grandmother.Interactable.Talk = 'lilithtower_main_end_lobby_19'
	end

	-- 베스
	quest = user_progress:GetStartedQuest(beth_quest_id)
	if quest ~= nil and quest.IsComplete then
		local lobby_pos_1 = field:GetMarker('lobby_pos_3').position
		local lobby_pos_2 = field:GetMarker('lobby_pos_4').position
		local lobby_pos_3 = field:GetMarker('lobby_pos_5').position

		local lobby_janitor_1 = get_character('lobby_janitor_1')
		character_util.set_anim_and_emotion(lobby_janitor_1,{ name = 'idle' }, { name = 'tired' })
		character_util.set_position(lobby_janitor_1, lobby_pos_1)

		local lobby_beth = get_character('lobby_beth')
		character_util.set_anim_and_emotion(lobby_beth,{ name = 'idle' }, { name = 'tired' })
		character_util.set_position(lobby_beth, lobby_pos_2)

		local lobby_janitor_2 = get_character('lobby_janitor_2')
		character_util.set_anim_and_emotion(lobby_janitor_2,{ name = 'idle' }, { name = 'smile' })
		character_util.set_position(lobby_janitor_2, lobby_pos_3)
	else
		self.show_lobby_zone[3] = true
	end

	-- 인생은 아름다워 남매
	quest = user_progress:GetStartedQuest(beautiful_quest_id)
	if quest ~= nil and quest.IsComplete then
		local lobby_pos_1 = field:GetMarker('lobby_pos_14').position
		local lobby_pos_2 = field:GetMarker('lobby_pos_13').position
		local lobby_pos_3 = field:GetMarker('lobby_pos_16').position
		local lobby_pos_4 = field:GetMarker('lobby_pos_15').position

		local lobby_sister_1 = get_character('lobby_sister_1')
		character_util.set_position(lobby_sister_1, lobby_pos_1)
		lobby_sister_1.Interactable.Talk = 'lilithtower_main_end_lobby_20'

		local lobby_sister_2 = get_character('lobby_sister_2')
		character_util.set_position(lobby_sister_2, lobby_pos_2)
		lobby_sister_2.Interactable.Talk = 'lilithtower_main_end_lobby_21'

		local lobby_sister_3 = get_character('lobby_sister_3')
		character_util.set_position(lobby_sister_3, lobby_pos_3)
		lobby_sister_3.Interactable.Talk = 'lilithtower_main_end_lobby_22'

		local lobby_brother = get_character('lobby_brother')
		character_util.set_emotion(lobby_brother, { name = 'awesome' })
		character_util.set_position(lobby_brother, lobby_pos_4)
		lobby_brother.Interactable.Talk = 'lilithtower_main_end_lobby_23'
		lobby_brother.Interactable.TalkSfx = '03_dialogue_positive_01'
	end

	-- 아무것도 아닌 할아버지
	quest = user_progress:GetStartedQuest(nobody_quest_id)
	if quest ~= nil and quest.IsComplete then
		local lobby_pos_1 = field:GetMarker('lobby_pos_6').position
		local lobby_pos_2 = field:GetMarker('lobby_pos_7').position
		local lobby_pos_3 = field:GetMarker('lobby_pos_8').position

		local lobby_nobody_old_man = get_character('lobby_nobody_old_man')
		character_util.set_position(lobby_nobody_old_man, lobby_pos_1)

		local lobby_nobody_man = get_character('lobby_nobody_man')
		character_util.set_position(lobby_nobody_man, lobby_pos_2)

		local lobby_nobody_woman = get_character('lobby_nobody_woman')
		character_util.set_position(lobby_nobody_woman, lobby_pos_3)
	else
		self.show_lobby_zone[1] = true
	end

	-- 다이하드
	quest = user_progress:GetStartedQuest(diehard_quest_id)
	if quest ~= nil and (quest.IsComplete or quest.InnerProgress == 3) then
		local lobby_pos_1 = field:GetMarker('lobby_pos_10').position
		local lobby_pos_2 = field:GetMarker('lobby_pos_11').position

		local lobby_diehard_maclaine = get_character('lobby_diehard_maclaine')
		character_util.set_position(lobby_diehard_maclaine, lobby_pos_1)

		local lobby_diehard_wife = get_character('lobby_diehard_wife')
		character_util.set_position(lobby_diehard_wife, lobby_pos_2)
	elseif quest ~= nil and quest.InnerProgress == 1 then
		local lobby_pos_1 = field:GetMarker('lobby_pos_10').position

		local lobby_diehard_maclaine = get_character('lobby_diehard_maclaine')
		character_util.set_position(lobby_diehard_maclaine, lobby_pos_1)
		character_util.set_anim_and_emotion(lobby_diehard_maclaine, { name = 'idle' }, { name = 'attack' })
		lobby_diehard_maclaine.Interactable.Talk = 'lilithtower_diehard_15'
		lobby_diehard_maclaine.Interactable.TalkSfx = '01_beep_01'

		self.show_lobby_zone[4] = true
	elseif quest ~= nil and quest.InnerProgress == 2 then
		local lobby_pos_2 = field:GetMarker('lobby_pos_11').position

		local lobby_diehard_wife = get_character('lobby_diehard_wife')
		character_util.set_position(lobby_diehard_wife, lobby_pos_2)
		character_util.set_anim_and_emotion(lobby_diehard_wife, { name = 'seat' }, { name = 'tired' })
		lobby_diehard_wife.Interactable.Talk = 'lilithtower_diehard_21'

		self.show_lobby_zone[4] = true
	else
		self.show_lobby_zone[4] = true
	end

	-- 라나
	quest = user_progress:GetStartedQuest(onigirl_quest_id)
	if quest ~= nil and quest.IsComplete and not self.onigirl_routine then
		self.onigirl_routine = true

		local lobby_pos_1 = field:GetMarker('lobby_pos_19').position

		local lobby_onigirl = get_character('lobby_onigirl')
		lobby_onigirl.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		character_util.set_position(lobby_onigirl, lobby_pos_1)

		local lobby_run_kid_1 = get_character('lobby_run_kid_1')
		lobby_run_kid_1.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		character_util.set_position(lobby_run_kid_1, lobby_pos_1 - vector(1,0,0))

		local lobby_run_kid_2 = get_character('lobby_run_kid_2')
		lobby_run_kid_2.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
		character_util.set_position(lobby_run_kid_2, lobby_pos_1 - vector(2,0,0))

		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.looby_run_routine, self))
	end

	-- 큐블리
	quest = user_progress:GetStartedQuest(vlog_quest_id)
	if quest ~= nil and quest.IsComplete then
		local lobby_pos_1 = field:GetMarker('lobby_pos_9').position

		local lobby_vloger = get_character('lobby_vloger')
		lobby_vloger.SpineController:SetAttachment('[base]weapon1', 'selfie_stick')
		character_util.set_anim_and_emotion(lobby_vloger, { name = 'sword_idle'}, { name = 'awesome' })
		character_util.set_position(lobby_vloger, lobby_pos_1)
	else
		self.show_lobby_zone[2] = true
	end

	-- 수상한 청년
	quest = user_progress:GetStartedQuest(main_quest_id)
	if quest ~= nil and quest_util.get_custom_state(quest, 'safe_fishy_youth') == 1 then
		for i = 1, 8 do
			local swat = get_character('lobby_swat_'..i)
			local pos = field:GetMarker('lobby_youth_pos_'..i).position

			character_util.set_position(swat, pos)
			swat.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance

			if i <= 4 then
				character_util.set_direction(swat, 'left')
			elseif i <= 5 then
				character_util.set_direction(swat, 'up')
			elseif i <= 7 then
				character_util.set_direction(swat, 'right')
			else
				character_util.set_direction(swat, 'down')
			end
		end

		get_field_object('lobby_plasticboard_1').ActiveState = active_state('disabled')
		get_field_object('lobby_plasticboard_2').ActiveState = active_state('disabled')

		local man = get_character('lobby_fishy_youth')
		character_util.set_position(man, field:GetMarker('lobby_youth_pos_2').position - vector(1,0,0))
		character_util.set_direction(man, 'right')
		character_util.set_anim(man, { name = 'seat' })
	else
		self.show_lobby_zone[6] = true
		get_field_object('lobby_plasticboard_1').ActiveState = active_state('enabled')
		get_field_object('lobby_plasticboard_2').ActiveState = active_state('enabled')
	end

end

function local_class:show_lobby_event(zone_name)
	if zone_name == 'lobby_event_1' then
		local lobby_nobody_old_man = get_character('lobby_nobody_old_man')
		local lobby_nobody_man = get_character('lobby_nobody_man')
		local lobby_nobody_woman = get_character('lobby_nobody_woman')

		-- 할아버지(attack) : 이 정도 난동쯤이야 어린애들 장난 수준이란 말이야!
		character_util.set_emotion(lobby_nobody_old_man, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_old_man, {key = 'lilithtower_main_end_lobby_8' })

		--할아버지(idle) : 약해 빠진 놈들… 떼잉!
		character_util.set_emotion(lobby_nobody_old_man, { name = 'idle' })
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_old_man, {key = 'lilithtower_main_end_lobby_9' })

		--할아버지(idle) : 그런 종잇장 같은 몸으로 테러니, 뭐니…
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_old_man, {key = 'lilithtower_main_end_lobby_10' })

		--할아버지(attack) : 나 때는 저런 놈들이 반동을 일으키면 얄짤 없었어!
		music_player_util.play_sfx({ sfx_name = '02_boss_sapa_shout_01', parent = lobby_nobody_old_man })
		character_util.set_emotion(lobby_nobody_old_man, { name = 'attack' })
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_old_man, {key = 'lilithtower_main_end_lobby_11' })

		--할아버지랑 같이 있던 남자(tired) : 에이… 껌을 아무리 씹어도 할아버지처럼은 안 되네.
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_man, {key = 'lilithtower_main_end_lobby_12' })

		--할아버지랑 같이 있던 여자(love, sing) :  할아버지~ 커피 한잔해요!
		music_player_util.play_sfx({ sfx_name = '01_gatcha_point_01', parent = lobby_nobody_woman })
		speech_bubble_util.show_speech_bubble_async(lobby_nobody_woman, {key = 'lilithtower_main_end_lobby_13' })

		lobby_nobody_old_man.Interactable.Talk = 'lilithtower_main_end_lobby_11'
		lobby_nobody_man.Interactable.Talk = 'lilithtower_main_end_lobby_12'
		lobby_nobody_woman.Interactable.Talk = 'lilithtower_main_end_lobby_13'

	elseif zone_name == 'lobby_event_2' then
		local lobby_vloger = get_character('lobby_vloger')

		-- 큐블리 (asesome)  : 여러분~ 안녕! 뉴튜버 큐블리에요!
		music_player_util.play_sfx({ sfx_name = '01_bad_fairy_01', parent = lobby_vloger })
		character_util.set_emotion(lobby_vloger, { name = 'awesome' })
		speech_bubble_util.show_speech_bubble_async(lobby_vloger, {key = 'lilithtower_main_end_lobby_14' })

		-- 큐블리 (smile) : 지금은 붕괴 현장 속에 있던 큐블리의 생존담 특집으로 방송을 켰어요~
		character_util.set_emotion(lobby_vloger, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(lobby_vloger, {key = 'lilithtower_main_end_lobby_15' })

		-- 큐블리 (surprise) : 헉! 시청자 수… 2.7만 명?
		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_02', parent = lobby_vloger })
		character_util.set_emotion(lobby_vloger, { name = 'surprise' })
		speech_bubble_util.show_speech_bubble_async(lobby_vloger, {key = 'lilithtower_main_end_lobby_16' })

		-- 큐블리 (smile) : 이거 구독비 정산되면 엄마한테 스카프도 사드릴 수 있겠는데요?
		character_util.set_emotion(lobby_vloger, { name = 'smile' })
		speech_bubble_util.show_speech_bubble_async(lobby_vloger, {key = 'lilithtower_main_end_lobby_17' })

		-- 큐블리 (smile)  : 헤헤~  다들 고마워요!
		speech_bubble_util.show_speech_bubble_async(lobby_vloger, {key = 'lilithtower_main_end_lobby_18' })

		lobby_vloger.Interactable.Talk = 'lilithtower_main_end_lobby_18'

	elseif zone_name == 'lobby_event_3' then
		local lobby_janitor_1 = get_character('lobby_janitor_1')
		local lobby_janitor_2 = get_character('lobby_janitor_2')
		local lobby_beth = get_character('lobby_beth')

		-- 미화원1 : 아이고 허리야… 타워 재건 청소가 이리 힘들 줄이야.
		music_player_util.play_sfx({ sfx_name = '03_dialogue_tipsy_01', parent = lobby_janitor_1 })
		speech_bubble_util.show_speech_bubble_async(lobby_janitor_1, {key = 'lilithtower_main_end_lobby_24' })
		--미화원2 : 그래도 특별 수당 챙겨 주니 괜찮지, 뭐.
		speech_bubble_util.show_speech_bubble_async(lobby_janitor_2, {key = 'lilithtower_main_end_lobby_25' })
		--미화원2 : 아가씨! 수당으로 술 사 먹으면 안 돼!
		speech_bubble_util.show_speech_bubble_async(lobby_janitor_2, {key = 'lilithtower_main_end_lobby_26' })
		--베스 : …
		speech_bubble_util.show_speech_bubble_async(lobby_beth, {key = 'lilithtower_main_end_lobby_27' })

		lobby_janitor_1.Interactable.Talk = 'lilithtower_main_end_lobby_24'
		lobby_janitor_2.Interactable.Talk = 'lilithtower_main_end_lobby_26'
		lobby_beth.Interactable.Talk = 'lilithtower_main_end_lobby_27'
	elseif zone_name == 'lobby_event_4' then
		local lobby_diehard_maclaine = get_character('lobby_diehard_maclaine')
		local lobby_diehard_wife = get_character('lobby_diehard_wife')

		while lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
			coroutine.yield()
		end
		--션 : 이번 역경도 당신이 있었기에 헤쳐나갈 수 있었어…
		speech_bubble_util.show_speech_bubble_async(lobby_diehard_maclaine, {key = 'lilithtower_main_end_lobby_5' })
		while lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
			coroutine.yield()
		end

		--아내 (tired) : 션! 우리 다시는 헤어지지 말아요.
		speech_bubble_util.show_speech_bubble_async(lobby_diehard_wife, {key = 'lilithtower_main_end_lobby_6' })
		while lua_helper.type_compare(user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) do
			coroutine.yield()
		end

		--션 : 물론이지, 귀여운 우리 아기 새.
		speech_bubble_util.show_speech_bubble_async(lobby_diehard_maclaine, {key = 'lilithtower_main_end_lobby_7' })

		lobby_diehard_maclaine.Interactable.Talk = 'lilithtower_main_end_lobby_7'
		lobby_diehard_wife.Interactable.Talk = 'lilithtower_main_end_lobby_6'
	elseif zone_name == 'lobby_event_5' then
		local npc_1 = get_character('lobby_setting_npc_7')
		local npc_2 = get_character('lobby_setting_npc_8')

		speech_bubble_util.show_speech_bubble_async(npc_1, {key = 'lilithtower_main_5_lobby_npc_5' })
		character_util.set_animation_n_times(npc_2, { name = 'nod', count = 2 })
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = npc_2 })
		speech_bubble_util.show_speech_bubble_async(npc_2, {key = 'lilithtower_main_5_lobby_npc_6' })

		npc_1.Interactable.Talk = 'lilithtower_main_5_lobby_npc_5'
		npc_2.Interactable.Talk = 'lilithtower_main_5_lobby_npc_6'
	elseif zone_name == 'lobby_event_6' then
		music_player_util.play_sfx({ sfx_name = '03_dialogue_negative_01', parent = get_character('lobby_swat_7') })
		speech_bubble_util.show_speech_bubble_async(get_character('lobby_swat_3'),
				{key = 'lilithtower_main_5_lobby_npc_13', bubble_type = 'shout' })

		speech_bubble_util.show_speech_bubble_async(get_character('lobby_swat_5'),
				{key = 'lilithtower_main_5_lobby_npc_14' })

		character_util.set_direction(get_character('lobby_swat_1'), 'right')
		character_util.set_direction(get_character('lobby_swat_2'), 'right')
		character_util.set_direction(get_character('lobby_swat_3'), 'right')
		character_util.set_direction(get_character('lobby_swat_4'), 'right')
	elseif zone_name == 'lobby_event_7' then
		local pickpocket = get_character('lobby_setting_npc_4')
		local engineer = get_character('lobby_setting_npc_4_1')

		-- 기술자 : {0}... 이번 안드로이드의 모델이 돼 주지 않으려나…
		speech_bubble_util.show_speech_bubble_async(engineer,
				{key = { 'lilithtower_main_5_lobby_npc_15', user.Name } })

		-- 기술자 : 영감이 떠올랐을 때 바로 만들어야 따끈한 안드로이드가 나오는데…
		speech_bubble_util.show_speech_bubble_async(engineer, {key = 'lilithtower_main_5_lobby_npc_16' })

		-- 기술자 question
		character_util.set_anim(engineer, { name = 'question', loop = false })
		music_player_util.play_sfx({ sfx_name = '01_rustle_01', parent = engineer })

		-- 기술자(nodx2) : 그 해실한 얼굴도 완벽하게 복제해서 줘야지. 헤헤…
		speech_bubble_util.show_speech_bubble_async(engineer, {key = 'lilithtower_main_5_lobby_npc_17' })

		-- 소매치기(smile, release)  : 나처럼 귀여운 소녀 안드로이드를 만들어 보는 건 어때? (대화 마친 후 smile, cast)
		music_player_util.play_sfx({ sfx_name = '03_dialogue_emphasize_01', parent = pickpocket })
		character_util.set_anim(pickpocket, { name = 'release', sfx_name = '01_swing_01' })
		speech_bubble_util.show_speech_bubble_async(pickpocket, {key = 'lilithtower_main_5_lobby_npc_18' })

		character_util.set_anim(pickpocket, { name = 'cast' })

		pickpocket.Interactable.Talk = 'lilithtower_main_5_lobby_npc_18'
		engineer.Interactable.Talk = 'lilithtower_main_5_lobby_npc_17'
	end
end

function local_class:looby_run_routine()
	self.run_loop = true

	local run_func = function(fo, speech)
		local i = 1
		local pos = { field:GetMarker('lobby_pos_19').position,
					  field:GetMarker('lobby_pos_18').position,
					  field:GetMarker('lobby_pos_17').position,
					  field:GetMarker('lobby_pos_20').position,
					  field:GetMarker('lobby_pos_19').position }

		character_util.remove_anim(fo)
		character_util.set_emotion(fo, { name = 'smile' })

		local lobby_onigirl = get_character('lobby_onigirl')
		local lobby_run_kid_1 = get_character('lobby_run_kid_1')
		local lobby_run_kid_2 = get_character('lobby_run_kid_2')

		while self.run_loop do
			character_util.move_waypoint_async(fo, pos, 5, true,
					nil, nil, nil, false)

			if not self.run_loop then
				character_util.stop(fo)
				break
			end

			if lua_helper.reference_equals(fo, lobby_onigirl) then
				character_util.set_position(lobby_onigirl, pos[1])
				character_util.set_position(lobby_run_kid_1, pos[1] - vector(1,0,0))
				character_util.set_position(lobby_run_kid_2, pos[1] - vector(2,0,0))
			end

			if speech and i % 3 == 1 and not lua_helper.type_compare(
					user_party.Leader.FieldObjectController.CurrentState, CS.Oak.CharacterControllerScreenplayState) then
				speech_bubble_util.show_speech_bubble(fo, { key = 'lilithtower_main_end_lobby_4' })
			end

			i = i + 1

			coroutine.yield()
		end
	end

	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(run_func, get_character('lobby_onigirl'), false))
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(run_func, get_character('lobby_run_kid_1'), false))
	coroutine_manager:StartCoroutine(stage.StageGameObject,
			util.cs_generator(run_func, get_character('lobby_run_kid_2'), true))
end


function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.QuestProgressedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))

	self.run_loop = false

	if self.rock_effect ~= nil then
		self.rock_effect:Dispose()
		self.rock_effect = nil
	end

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
