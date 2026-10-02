local local_class = newclass('NightmareFutureCastle1Controller')

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	self.main_quest_id = 208
	self.check_camp_grid = false

	self.soldier_key = 15
	self.saw_solider = false
	self.get_soldier = function(num) return get_character('soldier_'..num) end
	self.get_soldier_change = function(num) return get_character('soldier_change_'..num) end

	self.check_battle_grid = false
	self.get_male = function(num) return get_character('battle_zone_stteampunk_male_'..num) end
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_start_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridEnterEvent), 'on_camera_grid_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.CameraGridLeaveEvent), 'on_camera_grid_leave_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
end

function local_class:need_on_launch()
	-- 메인퀘스트 진행도에 따라 launch를 빼앗아 온다.
	return user_progress:GetStartedQuest(self.main_quest_id).InnerProgress == 0 and
		not user_progress:ClearedQuest(self.main_quest_id)
end

function local_class:on_launch(start_point_name)
	message_system:Publish(CS.Oak.StageStartEvent.Instance)
	message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
end

function local_class:dispose()
	character_util.remove_relate_event(self.get_soldier(1), self.cs_controller)
	character_util.remove_relate_event(self.get_soldier(2), self.cs_controller)

	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CameraGridLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))

	self.cs_controller = nil
end

--region event
function local_class:on_event(e)

	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		if not self.saw_solider and (lua_helper.reference_equals(e.Target, self.get_soldier(1)) or
				lua_helper.reference_equals(e.Target, self.get_soldier(2))) then
			sp_util.play_normal_screenplay(self.talk_soldier, self)
		end
		return true
	end
	return false
end

function local_class:on_start_event(_)
	-- 스팀펑크 뒷 배경 까맣게
	if user_progress:GetStartedQuest(self.main_quest_id).InnerProgress ~= 0 then
		message_system:Publish(CS.Oak.SetBackgroundColorEvent.Create(CS.UnityEngine.Color32(0, 0, 0, 255), 0))
	end

	-- 열차 그림자 제거
	local train = get_character('train_1')
	train.SpineController.IsShadowActive = false

	-- gate door 문 열기
	local gate_door = get_field_object('gate_door')
	gate_door.CrashBehaviour = CS.Oak.EtherealCrashBehaviour.Instance
	local gate_animator = gate_door:GetComponent(typeof(CS.UnityEngine.Animator))
	gate_animator:Play('open')

	-- 후일담 npc 세팅
	local steampunk_passionate_guy = get_character('steampunk_passionate_guy')
	local steampunk_tear_traveler = get_character('steampunk_tear_traveler')
	local steampunk_prince = get_character('steampunk_prince')
	local steampunk_citizen_male = get_character('steampunk_citizen_male')
	local snowman_male = get_character('snowman_male')
	local steampunk_officer_1 = get_character('steampunk_officer_1')
	local steampunk_officer_2 = get_character('steampunk_officer_2')

	steampunk_tear_traveler.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
	steampunk_prince.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
	steampunk_citizen_male.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')
	snowman_male.SpineController:SetAttachment('[base]weapon1', 'pickaxe_bronze_sword')

	steampunk_passionate_guy.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_1'
	steampunk_tear_traveler.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_2'
	steampunk_prince.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_3'
	steampunk_citizen_male.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_4'
	snowman_male.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_5'
	steampunk_officer_1.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_6'
	steampunk_officer_2.Interactable.Talk = 'nightmare_futurecastle_1stage_talk_7'

	character_util.remove_anim(steampunk_tear_traveler)
	character_util.remove_anim(steampunk_prince)
	character_util.remove_anim(steampunk_citizen_male)
	character_util.remove_anim(snowman_male)
	character_util.set_emotion(snowman_male, { name = 'doyagao' })

	-- 켄터베리 난민 세팅
	if not stage_progress:GetCustomData(self.soldier_key) then
		character_util.add_listener(self.get_soldier(1), self.cs_controller)
		character_util.add_listener(self.get_soldier(2), self.cs_controller)
	else
		self.saw_solider = true
		self.get_soldier(1).Interactable.Talk = 'nightmare_futurecastle_1_soldier_13'
		self.get_soldier(2).Interactable.Talk = 'nightmare_futurecastle_1_soldier_14'
	end

	-- 축구 병사들 세팅
	for i = 1, 6 do
		local male = self.get_male(i)
		character_util.set_anim(male, { name = 'success', scale = 1 - random_util.get_random_value() * 0.1 })
	end

	local officer = get_character('battle_zone_steampunk_officer')
	character_util.set_anim(officer, {name = 'hold', loop = false, upper = true})
	local soccer_ball = get_field_object('soccer_ball')
	soccer_ball.Position = officer.Position + vector(0,1,0)
	return true
end

function local_class:on_camera_grid_enter_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == 'grid_1' and not self.check_camp_grid then
		self:pickaxe_event_shake_rock()
		return true
	elseif grid_name == 'grid_2' and not self.check_battle_grid then
		self:battle_after_routine()
		return true
	end

	return false
end

function local_class:on_camera_grid_leave_event(e)
	if not lua_helper.reference_equals(e.FieldObject, user_party.Leader) and
			not lua_helper.reference_equals(e.FieldObject, user_party) then return false end

	local grid_name = e.CameraGrid.name

	if grid_name == 'grid_1' then
		self.check_camp_grid = false
		return true
	elseif grid_name == 'grid_2' then
		self.check_battle_grid = false
		return true
	end

	return false
end
--endregion

function local_class:pickaxe_event_shake_rock()
	local npc_list = {}
	table.insert(npc_list, get_character('steampunk_tear_traveler'))
	table.insert(npc_list, get_character('steampunk_prince'))
	table.insert(npc_list, get_character('steampunk_citizen_male'))
	table.insert(npc_list, get_character('snowman_male'))

	local rock_list = {}
	table.insert(rock_list, get_field_object('crystal_1'))
	table.insert(rock_list, get_field_object('crystal_2'))
	table.insert(rock_list, get_field_object('crystal_3'))
	table.insert(rock_list, get_field_object('crystal_4'))

	local duration = CS.Oak.SpineControllerExtensions.GetAnimationDuration(npc_list[1].SpineController, "twohand_attack")
	local duration2 = CS.Oak.SpineControllerExtensions.GetAnimationDuration(npc_list[4].SpineController, "twohand_attack")

	character_util.set_anim(npc_list[1], { name = 'twohand_attack', sfx_name = '01_mining_01' })
	character_util.set_anim(npc_list[2], { name = 'twohand_attack', sfx_name = '01_mining_01' })
	character_util.set_anim(npc_list[3], { name = 'twohand_attack', sfx_name = '01_mining_01' })
	character_util.set_anim(npc_list[4], { name = 'twohand_attack', scale = 0.5, sfx_name = '01_mining_01' })

	self.check_camp_grid = true

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local time_passed = duration * 0.5
		while self.check_camp_grid do
			time_passed = time_passed + unity_class.time.deltaTime
			if time_passed >= duration then
				time_passed = 0
				for i = 1, #rock_list - 1 do
					rock_list[i]:Shake(0.04, 0.3)
				end
			end
			coroutine.yield()
		end

		for i = 1, #npc_list do
			character_util.remove_anim(npc_list[i])
		end
	end))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local time_passed = duration2 * 1.3
		while self.check_camp_grid do
			time_passed = time_passed + unity_class.time.deltaTime
			if time_passed >= duration2 * 2 then
				time_passed = 0
				rock_list[4]:Shake(0.04, 0.3)
			end
			coroutine.yield()
		end
	end))
end

function local_class:talk_soldier()
	self.saw_solider = true

	local soldier_1 = self.get_soldier(1)
	local soldier_2 = self.get_soldier(2)
	local soldier_change_1 = self.get_soldier_change(1)
	local soldier_change_2 = self.get_soldier_change(2)

	party_util.align_party(soldier_1.Position + vector(0,0,-0.5), 'right', 1, 'linear')

	character_util.set_emotion(soldier_1, { name = 'surprise' })
	character_util.set_emotion(soldier_2, { name = 'surprise' })
	character_util.normal_jump(soldier_1)
	character_util.normal_jump(soldier_2)

	music_player_util.play_sfx_one_shot('01_jump_01')
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	-- 앗! 공주님!!!
	speech_bubble_util.show_speech_bubble_async(soldier_1, { key = 'nightmare_futurecastle_1_soldier_2', skip = true })

	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_anim(user_party.Leader, { name = 'question', loop = false })
	character_util.show_emoticon_async(user_party.Leader, nil, 'question')

	-- 아이샤는 공주가 아니라 황녀야!
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	character_util.set_animation_n_times(user_party.Leader, {name = 'release', count = 4, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_1_soldier_3', skip = true })

	character_util.remove_emotion(soldier_1)
	character_util.remove_emotion(soldier_2)

	music_player_util.play_sfx_one_shot('03_dialogue_negative_02')
	character_util.set_anim(user_party.Leader, { name = 'cross_arm', loop = false })
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_1_soldier_4', skip = true })

	character_util.remove_anim_and_emotion(user_party.Leader)

	-- 아니… 그게 아니라…
	character_util.set_emotion(soldier_1, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(soldier_1, { key = 'nightmare_futurecastle_1_soldier_5', skip = true })

	local equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true,
													   type_priority = 'loop', player_priority = 'npc'})
	character_util.set_direction(soldier_1, 'left')
	character_util.set_direction(soldier_2, 'left')
	character_util.set_anim_and_emotion(soldier_1, { name = 'eat' }, { name = 'idle' })
	character_util.set_anim_and_emotion(soldier_2, { name = 'eat' }, { name = 'idle' })
	wait_for_sec(1)
	equipping_sfx:Stop()

	music_player_util.play_sfx_one_shot('02_wolf_boss_bomb_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(soldier_1.Position)
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(soldier_2.Position)

	character_util.set_position(soldier_change_1, soldier_1.Position)
	character_util.set_position(soldier_change_2, soldier_2.Position)
	character_util.set_position(soldier_1, vector(999,0,999))
	character_util.set_position(soldier_2, vector(999,0,999))

	character_util.set_direction(soldier_change_1, 'right')
	character_util.set_direction(soldier_change_2, 'right')
	character_util.remove_anim(soldier_change_1)
	character_util.remove_anim(soldier_change_2)

	character_util.set_emotion(user_party.Leader, { name = 'surprise' })
	wait_for_sec(1)

	-- 캔터베리 사람들이었네!
	character_util.normal_jump(user_party.Leader, true)
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_1_soldier_6', skip = true })

	-- 공주님! 다시 봬서 너무 반갑습니다!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	character_util.set_emotion(user_party.Leader, { name = 'smile' })
	character_util.set_emotion(soldier_change_1, { name = 'smile' })
	character_util.set_emotion(soldier_change_2, { name = 'smile' })
	speech_bubble_util.show_speech_bubble_async(soldier_change_1, { key = 'nightmare_futurecastle_1_soldier_7', skip = true })

	-- 그때 공주님과 여왕님이 아니었다면…
	character_util.set_animation_n_times(soldier_change_1, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(soldier_change_1, { key = 'nightmare_futurecastle_1_soldier_8', skip = true })

	-- 라 제국에 처음 왔을 땐 수용소에서 힘들었지만 황녀님의 배려로 정규군으로 소속됐어요!
	speech_bubble_util.show_speech_bubble_async(soldier_change_2, { key = 'nightmare_futurecastle_1_soldier_9', skip = true })

	-- 고마워, 아이샤…
	music_player_util.play_sfx_one_shot('01_rustle_01')
	local aisha = get_character('steam_princess')
	character_util.look_at(user_party.Leader, aisha)
	character_util.set_emotion(user_party.Leader, { name = 'cry' })
	character_util.set_emotion(aisha, { name = 'blush' })

	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_1_soldier_10', skip = true })
	character_util.remove_emotion(aisha)

	-- 내가 꼭 캔터베리를 되찾아올게… 조금만 기다려 줘!
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	character_util.look_at(user_party.Leader, soldier_change_1)
	character_util.set_emotion(user_party.Leader, { name = 'attack' })
	character_util.normal_double_jump(user_party.Leader, true)
	speech_bubble_util.show_speech_bubble_async(user_party.Leader, { key = 'nightmare_futurecastle_1_soldier_11', skip = true })
	character_util.remove_emotion(user_party.Leader)

	-- 네, 공주님! 그날을 기다리고 있겠습니다!
	music_player_util.play_sfx_one_shot('01_coop_mvp_01')
	character_util.set_animation_n_times(soldier_change_1, { name = 'release', count = 2, sfx = '01_swing_01' })
	speech_bubble_util.show_speech_bubble_async(soldier_change_1, { key = 'nightmare_futurecastle_1_soldier_12', skip = true })

	equipping_sfx = music_player_util.play_sfx({ sfx_name = '03_equipping_01', loop = true,
												 type_priority = 'loop', player_priority = 'npc'})
	character_util.set_direction(soldier_change_1, 'left')
	character_util.set_direction(soldier_change_2, 'left')
	character_util.set_anim(soldier_change_1, { name = 'eat' })
	character_util.set_anim(soldier_change_2, { name = 'eat' })
	wait_for_sec(1)
	equipping_sfx:Stop()

	music_player_util.play_sfx_one_shot('02_wolf_boss_bomb_01')
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(soldier_change_1.Position)
	unity_object_pool.GetOrCreate('FX_dead'):Instantiate(soldier_change_2.Position)

	character_util.set_position(soldier_1, soldier_change_1.Position)
	character_util.set_position(soldier_2, soldier_change_2.Position)
	character_util.set_position(soldier_change_1, vector(999,0,999))
	character_util.set_position(soldier_change_2, vector(999,0,999))
	character_util.set_direction(soldier_1, 'right')
	character_util.set_direction(soldier_2, 'right')
	character_util.remove_anim_and_emotion(soldier_1)
	character_util.remove_anim_and_emotion(soldier_2)

	character_util.remove_relate_event(soldier_1, self.cs_controller)
	character_util.remove_relate_event(soldier_2, self.cs_controller)

	soldier_1.Interactable.Talk = 'nightmare_futurecastle_1_soldier_13'
	soldier_2.Interactable.Talk = 'nightmare_futurecastle_1_soldier_14'

	local stage_custom = stage_progress:SetCustomData(self.soldier_key, true)
	local req = api_connection:SendSetCustom(stage.StageId, stage_custom)
	coroutine.yield(req)
end

-- 재상과의 전투 후 구역 grid
function local_class:battle_after_routine()
	self.check_battle_grid = true

	local officer = get_character('battle_zone_steampunk_officer')


	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local clap_sfx = music_player_util.play_sfx({ sfx_name = "01_crowd_clap_01"
		, parent = officer, loop = true, type_priority = "event", player_priority = "npc", max_distance = 8 })

		local talk_passed = 4
		while self.check_battle_grid do
			talk_passed = talk_passed + unity_class.time.deltaTime

			-- 드디어 5년만에 조기축구회 우승이다!
			if talk_passed >= 6 then
				talk_passed = 0
				speech_bubble_util.show_speech_bubble(officer, { key = 'nightmare_futurecastle_1_battle_zone_6' })
			end

			coroutine.yield()
		end

		clap_sfx:FadeOut(1)
	end))

	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(function()
		local talk_passed = 0
		while self.check_battle_grid do
			talk_passed = talk_passed + unity_class.time.deltaTime

			if talk_passed >= 2 then
				talk_passed = 0
				-- 만세!
				-- 라 제국군 만세!
				-- 이야아아!!!
				speech_bubble_util.show_speech_bubble(self.get_male(random_util.get_random_int(1,6)),
						{ key = 'nightmare_futurecastle_1_battle_zone_'..random_util.get_random_int(3,5) })
			end
			coroutine.yield()
		end
	end))


end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
