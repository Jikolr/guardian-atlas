local local_class = newclass("AfterWorldChallengeHotSpringExorcismController")

function local_class:init(cs_controller)
	self.cs_controller = cs_controller

	-- 미니게임 시작 해주는 npc 이름
	self.get_mini_game_starter = function() return get_character('mini_game_starter') end

	self.knight_male_name = 'knight_male'
	self.knight_female_name = 'knight_female'

	-- 미니게임 이름
	self.mini_game_name = 'HotSpringExorcismGame'

	-- 스트링 키
	self.string_key = 'hot_spring_ticket_seller_'

	-- 스테이지 이름
	self.stage_name = 'substage_afterworld_3'

	-- 클리어 플래그 쪽 가기 위한 문
	self.door_name = 'exit_door'

	-- 한번 클리어 하였는지?
	self.is_once_clear = false

	-- 물 환경음
	self.water_loop_sfx = nil
end

function local_class:load_resource()
	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.StageStartEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_event')
end

function local_class:need_on_launch()
	local leader, character_spec_id = nil

	if user_util.has_knight_male() then
		character_spec_id = 2
		leader = get_character(self.knight_male_name)
	else
		character_spec_id = 1
		leader = get_character(self.knight_female_name)
	end

	character_util.convert_to_manual_character(leader)
	get_party_leader().CharacterInfo = CS.Oak.CharacterInfo.CreateDummyCharacterInfo(
			user_party_leader.CharacterInfo.User, character_spec_id)

	return false
end

function local_class:on_launch()
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageStartEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))

	self:dispose_water_loop_sfx(0)

	-- 스타터 리스너 구독 해지
	local starter = self.get_mini_game_starter()
	character_util.remove_relate_event(starter, self)

	self.cs_controller = nil
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.StageLoadedEvent) then
		return self:on_stage_loaded_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.StageStartEvent) then
		return self:on_stage_start_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	elseif lua_helper.type_compare(e, CS.Oak.MiniGameEndEvent) then
		return self:on_mini_game_end_event(e)
	end

	return false
end

function local_class:on_stage_loaded_event(_)
	-- 스타터 리스너 구독
	local starter = self.get_mini_game_starter()
	character_util.add_listener(starter, self)

	-- 온천 메터리얼 알파값 낮추기
	local pipe = get_field_object('spa_1')
	local mesh = CS.Utils.FindChildRecursively(pipe.Transform, 'add')
	local renderer = mesh:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
	renderer.sharedMaterial:SetColor("_TintColor", CS.UnityEngine.Color(0.9339, 0.5874, 0.1806, 0.1176))

	-- 코스튬 먹었을 때 sns 안 뜨도록
	message_system:Publish(CS.Oak.SNSSetEquipmentRecommendationEvent.Create(false))

	return false
end

function local_class:on_stage_start_event(_)
	field_ui_manager:RemoveUI(user_party.Leader, CS.Oak.FieldUiType.SkillButton)
	return false
end

function local_class:on_interact_event(e)
	local starter = self.get_mini_game_starter()

	-- 게임 시작 전에 스타터랑 상호작용 했을 때
	if lua_helper.reference_equals(e.Target, starter) then
		sp_util.play_normal_screenplay(self.interact_mini_game_starter, self, starter)
		return true
	end

	return false
end

function local_class:on_mini_game_end_event(e)
	-- 미니게임 종료
	if e.Name == self.mini_game_name then
		coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.end_mini_game, self, e.Success))
		return true
	end

	return false
end

function local_class:interact_mini_game_starter(starter_npc)
	-- 주최자 아래로 정렬
	party_util.align_party(starter_npc.Position, 'down', 0.5, 'arc')

	-- 온천에 악령이 많아 악령 퇴치 의뢰 받는 대사
	speech_bubble_util.show_speech_bubble_async(starter_npc, { key = self.string_key .. 1, skip = true })

	-- 온천에 입장 하시겠습니까?
	speech_bubble_util.show_speech_bubble_async(starter_npc, { key = self.string_key .. 2, skip = true })

	local choose_result = choose_util.play_choose_event(
			{ { self.string_key .. 3, 'mercy' }, { self.string_key .. 4, 'normal' } })

	if choose_result == 1 then
		self:play_mini_game()
	end
end

function local_class:play_mini_game()
	-- 페이드 아웃
	music_player_util.play_sfx_one_shot('01_stage_in_teleport_01')
	music_player_util.play_stage_music({ state = 'muted' })
	screen_util.fade_out_circular_async(1, 'linear')
	screen_util.fade_out_async(0, unity_class.color.black, 'linear')

	-- 미니게임 불러옴
	mini_game_manager:GetOrCreate(self.mini_game_name)

	local is_mini_game_load_complete = false
	mini_game_manager:LoadResource(self.mini_game_name, self.stage_name, function()
		is_mini_game_load_complete = true
	end)

	-- 미니게임이 로드 다되면
	while not is_mini_game_load_complete do
		coroutine.yield(nil)
	end
	coroutine.yield(nil)

	-- 미니게임 로드 이후에 카메라 사이즈 변경
	camera_util.resize_to(6.5, 0)

	-- 환경음 재생
	self.water_loop_sfx = music_player_util.play_sfx(
			{ sfx_name = "01_water_loop_02", loop = true, type_priority = 'loop' })

	-- 페이드 인
	screen_util.fade_in(0, unity_class.color.black, 'linear')
	screen_util.fade_in_circular_async(1, 'linear')

	-- 미니게임 시작
	mini_game_manager:StartMiniGame(self.mini_game_name)
end

-- 미니게임 끝난 이후
function local_class:end_mini_game(is_success)
	-- 환경음 종료
	self:dispose_water_loop_sfx(2)

	-- Fade Out
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 카메라 원복
	camera_util.resize_to_default(0)

	-- 미니게임 시작해주는 npc 앞으로 이동
	character_util.remove_anim_and_emotion(user_party.Leader)
	local starter = self.get_mini_game_starter()
	party_util.align_party(starter.Position, 'down', 0, 'arc')

	-- Fade In
	music_player_util.play_stage_music({ state = 'field', mix = 1 })
	wait_for_sec(0.25)
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	if is_success then
		self:success_mini_game(starter)
	else
		self:fail_mini_game(starter)
	end

	party_util.reset_controllers()
	field_ui_manager:Show()
end

function local_class:fail_mini_game(starter_npc)
	character_util.set_emotion(starter_npc, { name = 'tired' })
	speech_bubble_util.show_speech_bubble_async(starter_npc, { key = self.string_key .. 5, skip = true })
	character_util.remove_anim_and_emotion(starter_npc)
end

function local_class:success_mini_game(starter_npc)
	music_player_util.play_sfx_one_shot('01_clap_02')
	music_player_util.play_sfx_one_shot('01_coop_mvp_01')

	character_util.set_emotion(starter_npc, { name = 'smile' })
	character_util.set_anim(starter_npc, { name = 'clap' })
	speech_bubble_util.show_speech_bubble_async(starter_npc, { key = self.string_key .. 6, skip = true })

	-- 스테이지 입장 후 첫 클리어라면 문을 열어 준다.
	if not self.is_once_clear then
		-- 카메라가 문쪽으로 이동
		local door = get_field_object(self.door_name)
		camera_util.move_async(door.Position, 0.75)

		-- 문을 열어준다.
		message_system:Publish(CS.Oak.DoorOpenEvent.Create(self.door_name, false))
		wait_for_sec(2)

		-- 돌아온다.
		camera_util.return_to_leader(0.75)

		self.is_once_clear = true
	end
	character_util.remove_relate_event(starter_npc, self)
	character_util.remove_anim(starter_npc)

	starter_npc.Interactable = CS.Oak.NPCInteractable.Create()
	starter_npc.Interactable.Talk = self.string_key .. 6
end

function local_class:dispose_water_loop_sfx(fade_time)
	if self.water_loop_sfx == nil then
		return
	end

	self.water_loop_sfx:FadeOut()
	self.water_loop_sfx = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
