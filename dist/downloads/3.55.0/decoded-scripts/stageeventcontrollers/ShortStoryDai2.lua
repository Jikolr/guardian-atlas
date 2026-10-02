local local_class = newclass('ShortStoryDai2Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller
	self.main_quest_id = 7001401

	self.party_switching_complete = false

	-- 섹션 내 스테이트 Enum
	self.main_quest_inner_progress = {
		inner_progress_7 = 7,
		inner_progress_8 = 8,
	}

	self.get_princess_bat = function() return get_character('princess_bat') end
	self.get_princess = function() return get_character('princess') end
	self.get_lorain = function() return get_character('lorain') end
	self.get_dai = function() return get_character('dai') end
	self.get_popp = function() return get_character('popp') end
	self.get_maam = function() return get_character('maam') end
	self.get_leona = function() return get_character('leona') end
	self.get_gome = function() return get_character('gome') end

	self.get_magician = function() return get_character('dolf') end
	self.get_maid = function() return get_character('amy') end

	-- marker
	-- 섹션 7, 8, 9 - 공주 위치
	self.get_cocktail_bar_princess_pos = function()
		return field:GetMarker('cocktail_bar_princess_pos').position
	end

	-- 섹션 7, 8, 9 - 로레인 위치
	self.get_cocktail_bar_lorain_pos = function()
		return field:GetMarker('cocktail_bar_lorain_pos').position
	end

	--  섹션 7, 8, 9 - 돌프 초기 위치
	self.get_s8_dolf_start_pos = function()
		return field:GetMarker('s8_dolf_start_pos').position
	end

	--  섹션 7, 8, 9 - 에이미 초기 위치
	self.get_s8_amy_start_pos = function()
		return field:GetMarker('s8_amy_start_pos').position
	end

	-- 각 섹션 별 전투 존, 몬스터 수 정보 저장
	self.section_battle_count_info = nil

	self.playable_minigame = false

	self.already_interact_princess = false

	--region 라나 서브 이벤트
	self.oneline_oni_girl_data = {
		oni_girl_racing_n0_1 = {
			dir = 'right',
			anim = 'cast',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_01',
			talksfx = '01_bad_fairy_01'
		},
		oni_girl_racing_n0_2 = {
			dir = 'left',
			anim = 'idle',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_02',
			talksfx ='03_dialogue_positive_01'
		},
		oni_girl_racing_n0_3 = {
			dir = 'right',
			anim = 'dagger_idle',
			emo = 'attack',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_03',
			talksfx = '03_dialogue_tipsy_01'
		},
		oni_girl_racing_n0_4 = {
			dir = 'left',
			anim = 'bomb_idle',
			emo = 'tired',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_04',
			talksfx = '03_dialogue_negative_02'
		},
		oni_girl_racing_n1 = {
			dir = 'left',
			anim = 'seat',
			emo = 'cry',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_1',
			talksfx = '03_dialogue_sadness_02'
		},
		oni_girl_racing_n3 = {
			dir = 'down',
			anim = 'cast',
			emo = 'tired',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_2',
			talksfx = '03_dialogue_tipsy_01'
		},
		oni_girl_racing_n6 = {
			dir = 'left',
			anim = 'idle',
			emo = 'mad',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_3',
			talksfx = '03_dialogue_negative_01'
		},
		oni_girl_racing_n7 = {
			dir = 'right',
			anim = 'idle',
			emo = 'tired',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_4',
			talksfx= '03_dialogue_tipsy_01'
		},
		oni_girl_racing_n9 = {
			dir = 'down',
			anim = 'clap',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_5',
			talksfx = '01_clap_02'
		},
		oni_girl_racing_n10 = {
			dir = 'down',
			anim = 'success',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_6',
			talksfx = '03_dialogue_emphasize_01'
		},
		oni_girl_racing_n11 = {
			dir = 'down',
			anim = 'rifle_shoot',
			emo = 'mad',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_7',
			talksfx = '03_dialogue_angry_01'
		},
		oni_girl_racing_n12 = {
			dir = 'down',
			anim = 'clap',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_8',
			talksfx = '01_clap_02'
		},
		oni_girl_racing_n13 = {
			dir = 'down',
			anim = 'clap',
			emo = 'smile',
			talk = 'short_story_dai_oni_girl_racing_key_oneline_9',
			talksfx = '01_clap_02'
		},
	}

	self.oni_girl_is_patrol = false
	self.slime_is_patrol = false

	--endregion

	--region 아라 서브 이벤트
	self.get_hold_object = function(number)
		return get_field_object('sea_witch_box_' .. number)
	end
	--endregion
end

function local_class:load_resource()
	message_system:SubscribeOnce(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent),
			'on_complete_switching_party_member_event')
	message_system:Subscribe(self, typeof(CS.Oak.CustomStageEvent), 'on_custom_stage_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.pre_setting, self)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.CompleteSwitchingPartyMemberEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MiniGameEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CustomStageEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))

	self.cs_controller = nil

	--region 라나 서브 이벤트
	self.oni_girl_is_patrol = false
	--endregion
end

function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		self:on_interact_event(e)
	end
	return false
end

function local_class:on_complete_switching_party_member_event(_)
	self.party_switching_complete = true

	return true
end

function local_class:on_interact_event(e)
	if lua_helper.reference_equals(e.Target, self.get_princess()) then
		start_coroutine(self.play_cocktail_minigame, self)
	end
end

function local_class:on_mini_game_end_event(e)
	if e.Name ~= 'CocktailMiniGame' then
		return false
	end
	start_coroutine(self.cocktail_minigame_end, self)
end

function local_class:on_custom_stage_event(e)
	if e.Params ~= nil and e.Params.Length == 1 then
		if e.Params[0] == 'oni_girl_quest_clear' then
			start_coroutine(self.oni_girl_patrol_setting, self)
		elseif e.Params[0] == 'stop_slime_patrol' then
			start_coroutine(self.stop_slime_patrol, self)
		elseif e.Params[0] == 'oni_girl_tutorial' then
			start_coroutine(self.slime_patrol_setting, self)
		end
	end
end

function local_class:on_zone_leave_event(e)
	local obj_count = 3
	for i = 1, obj_count do
		local hold_box = self.get_hold_object(i)
		if type_util.is_zone_full_leave(e, hold_box, 'sea_witch_leave_zone') then
			message_system:Send(hold_box, CS.Oak.GimmickResetEvent.Instance)
			return true
		end
	end

	return false
end

function local_class:npc_setting(main_quest_progress)
	if main_quest_progress == nil or main_quest_progress.IsComplete then
	elseif main_quest_progress.InnerProgress == 6 then
		self:set_npc_pos_dir(self.get_princess(), self.get_cocktail_bar_princess_pos(), 'down')
		self:set_npc_pos_dir(self.get_lorain(), self.get_cocktail_bar_lorain_pos(), 'down')
		self:set_npc_pos_dir(self.get_magician(), self.get_s8_dolf_start_pos(), 'left')
		self:set_npc_pos_dir(self.get_maid(), self.get_s8_amy_start_pos(), 'left')
	elseif main_quest_progress.InnerProgress == 7 then
		self:set_npc_pos_dir(self.get_princess(), self.get_cocktail_bar_princess_pos(), 'down')
		self:set_npc_pos_dir(self.get_lorain(), self.get_cocktail_bar_lorain_pos(), 'down')
		self:set_npc_pos_dir(self.get_magician(), self.get_s8_dolf_start_pos(), 'left')
		self:set_npc_pos_dir(self.get_maid(), self.get_s8_amy_start_pos(), 'left')
	elseif main_quest_progress.InnerProgress == 8 then
		self:set_npc_pos_dir(self.get_princess(), self.get_cocktail_bar_princess_pos(), 'down')
		self:set_npc_pos_dir(self.get_lorain(), self.get_cocktail_bar_lorain_pos(), 'down')
	end
end

-- 각 섹션 별 전투 존, 몬스터 수 정보 저장
function local_class:set_section_monster_info()
	self.section_battle_count_info = {}

	-- section 8
	self.section_battle_count_info[self.main_quest_inner_progress.inner_progress_7] = {
		zone_couont = 2,
		monster_count = 6,
	}

	-- section 9
	self.section_battle_count_info[self.main_quest_inner_progress.inner_progress_8] = {
		zone_couont = 2,
		monster_count = 8,
	}
end

function local_class:set_npc_pos_dir(npc, pos, dir)
	character_util.set_position(npc, pos)
	character_util.set_direction(npc, dir)
end

function local_class:pre_setting()
	-- FIXME : 여기서 self.party_switching_complete를 대기해야 하는가?

	-- FIXME : PS-11337 "임시 처리!!!!"
	-- 루 디버프 이펙트가 남아있어 섹션 1 전투 시작 시 디버프 이펙트가 남아있는 현상 수정
	-- 기존 파티원들을 멀리 보내서 이펙트가 보이지 않도록 임시로 수정
	local origin_party = party_util.get_origin_party()

	for i = 1, #origin_party do
		character_util.set_position(origin_party[i], vector(999, 0, 999))
	end

	local main_quest_progress = user_progress:GetStartedQuest(self.main_quest_id)

	self:set_section_monster_info()

	-- 리더 교체
	local change_leader_character = function(leader, party_member)
		character_util.set_active_state(leader, 'enabled')
		local param = CS.Oak.CharacterConvertParam:ManualDefault()
		character_util.convert_to_manual_character(leader, param, true)

		-- 시작할 때 파티멤버로 추가해줘야할 npc들이 있다면 넣어줌.
		if party_member ~= nil then
			for i = 1, #party_member do
				character_util.set_active_state(party_member[i], 'enabled')
				character_util.convert_to_party_member(party_member[i], user_party, true)
			end
		end
	end

	-- 리더를 시작 위치로 옮기고 스테이지 시작 함수
	local start_stage_event = function(dir, pos, directional_stage_entry, play_stage_music)
		-- 리더를 시작 좌표로 이동
		local leader = user_party.Leader
		leader.Position = pos
		character_util.set_direction(leader, dir)

		-- 시작 연출을 한다면 연출
		if directional_stage_entry then
			screen_util.fade_in(0, unity_class.color.black, CS.Oak.Interpolations.Linear)
			screen_util.fade_in_circular(1, 'linear')
			coroutine.yield(CS.Oak.CommonScreenplay.DirectionalStageEntry(leader.Position,
					leader.Direction, game_string:GetString(stage.Name)))
			message_system:Publish(CS.Oak.StageControlStartEvent.Instance)
		end

		if play_stage_music then
			music_player_util.play_stage_music({ state = 'field' })
		end

		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	end

	if main_quest_progress == nil or main_quest_progress.IsComplete then

		-- 클리어 후 칵테일 미니게임 세팅
		self:set_cocktail_minigame()
		self:remove_rock()

		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	elseif main_quest_progress.InnerProgress == 6 then

		start_stage_event('right', field:GetMarker('default_start').position, false, false)

		self:npc_setting(main_quest_progress)

		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_7)
		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_8)

	elseif main_quest_progress.InnerProgress == 7 then

		start_stage_event('right', field:GetMarker('default_start').position, false, false)

		self:npc_setting(main_quest_progress)

		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_8)

	elseif main_quest_progress.InnerProgress == 8 then

		start_stage_event('right', field:GetMarker('default_start').position, false, false)

		self:npc_setting(main_quest_progress)

		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_7)

	elseif main_quest_progress.InnerProgress == 9 then
		self:remove_rock()
		start_stage_event('right', field:GetMarker('s10_dai_start_pos').position, false, true)
	elseif main_quest_progress.InnerProgress == 10 then
		self:remove_rock()
		start_stage_event('right', field:GetMarker('default_start').position, false, false)
	elseif main_quest_progress.InnerProgress == 11 then
		self:remove_rock()
		start_stage_event('right', field:GetMarker('default_start').position, false, true)
	else
		start_stage_event('right', field:GetMarker('default_start').position, true, true)
	end

	-- 섹션 9 이후에는 섹션 8, 9에서 사용되었던 배틀 몬스터 배활성화시킴
	if main_quest_progress.InnerProgress > 8 then
		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_7)
		self:disabled_select_section_event_battle_monster(main_quest_progress.InnerProgress,
				self.main_quest_inner_progress.inner_progress_8)
	end

	--region 라나 서브 이벤트
	self:set_npc_by_data(self.oneline_oni_girl_data)

	--라나 서브 클리어 시 처리
	local oni_girl_quest_id = 7001406
	local sub_quest_progress = user_progress:GetStartedQuest(oni_girl_quest_id)

	if sub_quest_progress ~= nil then
		if sub_quest_progress.IsComplete then
			start_coroutine(self.oni_girl_patrol_setting, self)
		else
			start_coroutine(self.slime_patrol_setting, self)
		end
	end

	--endregion
end

function local_class:disabled_select_section_event_battle_monster(cur_inner_progress, select_inner_progress)
	local info = self.section_battle_count_info[select_inner_progress]
	if info ~= nil then
		for i = 1, info.zone_couont do
			for j = 1, info.monster_count do
				local enemy = get_character('s' .. (select_inner_progress + 1) .. '_battle_' .. i .. '_monster_' .. j)
				if enemy ~= nil then
					character_util.set_active_state(enemy, 'disabled')
					if cur_inner_progress > select_inner_progress then
						message_system:Publish(CS.Oak.FieldObjectDestroyedEvent.Create(enemy, enemy.Position, enemy.Hitbox))
					end
				end
			end
		end
	end
end

function local_class:set_cocktail_minigame()
	local princess = self.get_princess()
	local princess_marker = field:GetMarker('post_princess_pos')
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.MiniGameEndEvent), 'on_mini_game_end_event')

	character_util.set_position(princess, princess_marker.position)
	character_util.set_direction(princess, princess_marker.direction)
	character_util.add_listener(princess, self.cs_controller)

	self.playable_minigame = true
end

function local_class:play_cocktail_minigame()
	local dai = self.get_dai()
	local princess = self.get_princess()

	local game_name = 'CocktailMiniGame'
	local game_key = 'master'

	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local dai_party = { dai = self.get_dai(), popp = self.get_popp(), maam = self.get_maam(),
	                          leona = self.get_leona(), gome = self.get_gome() }

	local align_pos =  princess.Position + vector(1, 0, 0)
	local party_align_pos = { dai = align_pos, popp = align_pos + vector(1, 0, 0), maam = align_pos + vector(1, 0 , -1),
	                          leona = align_pos + vector(0, 0 , -1), gome = align_pos + vector(-1, 0, -1) }

	for key in pairs(dai_party) do
		local party_member = dai_party[key]
		local pos = party_align_pos[key]
		wp_util.move(party_member, pos, 4, nil, { last_direction = 'left' })
	end

	character_util.set_direction(princess, 'right')
	wait_for_sec(1)

	character_util.set_emotion(princess, { name = 'smile' })
	character_util.normal_jump(princess, true)

	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	if not self.already_interact_princess then
		self.already_interact_princess = true
		--그럼 이제 영업 시작해볼까?
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'short_story_dai_post_1', skip = true })
	else
		-- 다들 준비 됐어?
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'short_story_dai_post_3', skip = true })
	end

	-- 가게 오픈!
	-- 아직 준비할 게 있어.
	local choose_result = choose_util.play_choose_event({
		{ 'short_story_dai_post_choose_1', 'mercy' },
		{ 'short_story_dai_post_choose_2', 'normal' }
	})

	if choose_result == 1 then
		music_player_util.play_sfx_one_shot('01_stage_intro_jump_01')
		character_util.set_emotion(dai, { name = 'smile' })
		character_util.set_anim(dai, { name = 'victory_get', loop = false })
		wait_for_sec(1.3)

		--미니 게임 생성
		mini_game_manager:GetOrCreate(game_name)

		local is_mini_game_load_complete = false

		--리소스 완료 시 까지 대기
		mini_game_manager:LoadResource(game_name, game_key, function()
			is_mini_game_load_complete = true
		end)

		while not is_mini_game_load_complete do
			coroutine.yield(nil)
		end
		character_util.remove_anim_and_emotion(dai)

		--리소스 로드 완료 시 실행
		mini_game_manager:StartMiniGame(game_name)
	else
		character_util.remove_emotion(princess)
		character_util.normal_jump(princess, true)
		-- 알았어! 준비되면 알려줘!
		speech_bubble_util.show_speech_bubble_async(princess, { key = 'short_story_dai_post_2', skip = true })
		character_util.set_direction(princess, 'down')

		field_ui_manager:Show()
		user_party:ResetControllers()
	end
end

function local_class:cocktail_minigame_end()
	local princess = self.get_princess()

	mini_game_manager:DisposeMiniGame('CocktailMiniGame')

	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')
	screen_util.fade_in_circular_async(1, 'linear')

	character_util.set_emotion(princess, { name = 'smile' })
	-- 다들 이번 영업도 고생 많았어!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	speech_bubble_util.show_speech_bubble_async(princess, { key = 'short_story_dai_post_4', skip = true })
	character_util.remove_emotion(princess)
	character_util.set_direction(princess, 'down')

	field_ui_manager:Show()
	user_party:ResetControllers()
end

function local_class:set_npc_by_data(npcs_data)
	for npc_name, data in pairs(npcs_data) do
		local npc = get_character(npc_name)

		if npc ~= nil then
			character_util.set_active_state(npc, 'enabled')
			scene_util.set_direction(npc, data.dir)
			scene_util.set_anim_loop(npc, data.anim)
			scene_util.set_emotion_loop(npc, data.emo)
			npc.Interactable.Talk = data.talk
			if  data.talksfx ~= nil then
				npc.Interactable.TalkSfx = data.talksfx
			end
		end
	end
end

function local_class:oni_girl_patrol_setting()
	local oni_girl = get_character('oni_girl')
	local s_lana = get_character('oni_girl_slime')
	local s_lana_pos = field_util.get_marker_pos('oni_girl_extra_pos')
	local oni_girl_pos = s_lana_pos + vector(0, 0, 1)
	local s_lana_end_pos = field_util.get_marker_pos('oni_girl_extra_end_pos')
	local oni_girl_end_pos = s_lana_end_pos + vector(0, 0, 1)
	local slime = get_character('oni_girl_racing_n14')

	--기존 슬라임 패트롤 진행시 멈춤
	if self.slime_is_patrol then
		self.slime_is_patrol = false
		character_util.stop(slime)
		coroutine.yield(nil)
	end

	character_util.set_position(slime, vector(999, 0, 999))
	character_util.set_position(oni_girl, oni_girl_pos)
	character_util.set_position(s_lana, s_lana_pos)
	scene_util.set_anim_loop(oni_girl, 'run')
	scene_util.set_emotion_loop(oni_girl, 'smile')
	self.oni_girl_is_patrol = true

	stage.SmokeManager:SetCharacterSmoke(oni_girl)
	stage.SmokeManager:SetCharacterSmoke(s_lana)

	while self.oni_girl_is_patrol do
		scene_util.set_anim_loop(s_lana, 'walk_left')
		wp_util.move(oni_girl, oni_girl_pos, 7,nil, { run = true })
		wp_util.move_async(s_lana, s_lana_pos, 7, nil, { run = true })

		if not self.oni_girl_is_patrol then
			break
		end

		scene_util.set_anim_loop(s_lana, 'walk_right')
		wp_util.move(oni_girl, oni_girl_end_pos, 7, nil, { run = true })
		wp_util.move_async(s_lana, s_lana_end_pos, 7, nil, { run = true })

		if not self.oni_girl_is_patrol then
			break
		end

		coroutine.yield(nil)
	end

	character_util.stop(oni_girl)
	character_util.stop(s_lana)
end

function local_class:slime_patrol_setting()
	local slime = get_character('oni_girl_racing_n14')
	local slime_pos = field_util.get_marker_pos('oni_girl_extra_pos')
	local slime_end_pos = field_util.get_marker_pos('oni_girl_extra_end_pos')

	--이미 슬라임 패트롤 상태 일 경우 코루틴 종류 후 재실행
	if self.slime_is_patrol then
		character_util.stop(slime)
		character_util.set_position(slime, vector(999, 0, 999))
		self.slime_is_patrol = false
		wait_for_sec(2)
	end

	character_util.set_position(slime, slime_pos)
	self.slime_is_patrol = true

	while self.slime_is_patrol do
		scene_util.set_anim_loop(slime, 'walk_left')
		wp_util.move_async(slime, slime_pos, 7)

		if not self.slime_is_patrol then
			break
		end

		scene_util.set_anim_loop(slime, 'walk_right')
		wp_util.move_async(slime, slime_end_pos, 7)

		if not self.slime_is_patrol then
			break
		end

		coroutine.yield(nil)
	end

	character_util.stop(slime)
end

function local_class:stop_slime_patrol()
	local slime = get_character('oni_girl_racing_n14')
	--기존 슬라임 패트롤 진행시 멈춤
	if self.slime_is_patrol then
		self.slime_is_patrol = false
		character_util.stop(slime)
		coroutine.yield(nil)
	end

	character_util.set_position(slime, vector(999, 0, 999))
end

function local_class:remove_rock()
	-- 길막용 돌 치우기
	get_field_object('rock_1').Position = vector(999, 0, 999)
	get_field_object('rock_2').Position = vector(999, 0, 999)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
