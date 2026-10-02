local local_class = newclass('ExpeditionHiddenSanctuaryController')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	self.section_state = {
		none = 1,
		enter_battle_zone = 2,
		after_battle = 3,
		ending = 4,
	}
	self.current_section_state = self.section_state.none

	-- 스테이지 id
	self.stage_id = 250014008

	-- 스테이지 클리어 여부
	self.is_stage_clear = false

	-- battle group 이름
	self.battle_group_name = 'hidden_sanctuary_battle'

	-- effect
	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end

	-- 베로니카
	self.get_boss_priestess = function() return get_character('boss_exp_veronica') end
	self.get_priestess = function() return get_character('priestess') end

	-- 돌로레스
	self.get_dolores = function() return get_character('dolores') end

	-- 연출용 카메라 기본 사이즈
	self.default_camera_size = 4

	-- 이벤트용 마커 이름
	self.marker_name = 'event_pos_'

	self.special_collectible_item_id = 4

	self.is_already_get_collectible_item = false
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.StageLoadedEvent), 'on_stage_loaded_event')
end

--- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return false
end

--- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
end

--region Event

function local_class:on_event(e)
	return false
end

function local_class:on_stage_loaded_event(e)
	local user_expedition = CS.Oak.UserExpedition.Me

	-- 스테이지 클리어 시에는 세팅 안함
	self.is_stage_clear = CS.Oak.UserExpeditionExtensions.IsExpeditionStageCleared(user_expedition, self.stage_id)
	if self.is_stage_clear then
		return false
	end

	-- 기록물을 이미 먹었는 지 체크
	local special_collectibles = CS.Oak.UserExpeditionExtensions.GetSpecialCollectibles(user_expedition)
	if special_collectibles ~= nil then
		for i = 0, special_collectibles.Count - 1 do
			if special_collectibles[i] == self.special_collectible_item_id then
				self.is_already_get_collectible_item = true
				break
			end
		end
	end

	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent), 'on_battle_group_eliminated_event')
	message_system:Subscribe(self, typeof(CS.Oak.ExpeditionCollectibleItemGetEvent), 'on_ex_collectible_item_get_event')

	self.default_camera_size = CS.Oak.StageCamera.DefaultCameraSize

	self.get_fx_hit()
	self:set_hidden_event()
end

function local_class:on_zone_enter_event(e)
	if self.current_section_state <= self.section_state.none and
			type_util.is_zone_full_enter(e, get_party_leader(), self.battle_group_name) then

		-- 용사교 성소 이벤트 존 입장
		self.current_section_state = self.section_state.enter_battle_zone
		sp_util.start_scene(self.enter_hidden_sanctuary, self)

		return true
	end

	return false
end

function local_class:on_battle_group_eliminated_event(e)
	if self.current_section_state <= self.section_state.enter_battle_zone
			and e.BattleGroupName == self.battle_group_name then
		if self.is_already_get_collectible_item then
			-- 이미 기록물 먹었으면 바로 엔딩
			self.current_section_state = self.section_state.ending
			music_player_util.play_stage_music({ state = 'muted' })
			sp_util.start_scene(self.collectibles_get_event, self)
		else
			-- 베로니카와의 전투 종료(아이템 먹힐 때까지 대기)
			self.current_section_state = self.section_state.after_battle
			self:eliminated_priestess()
		end

		return true
	end

	return false
end

function local_class:on_ex_collectible_item_get_event(e)
	if e.CollectibleItemId == self.special_collectible_item_id then
		-- 수집품 획득 후
		self.current_section_state = self.section_state.ending
		sp_util.start_scene(self.collectibles_get_event, self)

		return true
	end

	return false
end

--endregion

--- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

--- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.StageLoadedEvent))

	if not self.is_stage_clear then
		message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.BattleGroupEliminatedEvent))
		message_system:Unsubscribe(self, typeof(CS.Oak.ExpeditionCollectibleItemGetEvent))
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:set_hidden_event()
	-- 베로니카 세팅
	local boss_priestess = self.get_boss_priestess()
	character_util.set_position(boss_priestess, field_util.get_marker_pos(self.marker_name .. 2))
	character_util.set_direction(boss_priestess, 'left')
	character_util.set_active_state(boss_priestess, 'enabled')

	-- 돌로레스 세팅
	local dolores = self.get_dolores()
	character_util.set_position(dolores, field_util.get_marker_pos(self.marker_name .. 1))
	character_util.set_direction(dolores, 'right')
	character_util.set_active_state(dolores, 'enabled')
	scene_util.set_emotion(dolores, self, 'tired')
end

-- 베로니카와 조우 및 전투
function local_class:enter_hidden_sanctuary()
	local boss_priestess = self.get_boss_priestess()
	local dolores = self.get_dolores()
	local leader = get_party_leader()

	music_player_util.change_stage_music_volume('field', 0.5)

	camera_util.move(field_util.get_marker_pos(self.marker_name .. 1) + vector(0.5, 0, -1), 1)
	camera_util.resize_to(self:get_camera_size_by_ratio(4), 1)
	party_util.align_party(vector(0.5, 0, 21), 'down', 1, 'arc')
	wait_for_sec(0.25)

	-- 돌로레스: (idle, tired, right) 분명 모든 시련을 통과하였는데… 어째서 그 분이 용사가 아닌 것입니까, 교주님…
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_1')

	-- 돌로레스: (idle, tired, right) 저는…
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_2')

	-- 베로니카: (idle, idle, left) 계시록에 의문을 품으시는 건가요?
	scene_util.set_emotion(boss_priestess, self, 'tired')
	scene_util.show_normal_speech_async(boss_priestess, 'ex_hidden_sanctuary_3')
	character_util.remove_emotion(boss_priestess)

	-- 돌로레스: (idle, surprise, right) 아닙니다…!
	scene_util.play_normal_speech_action(dolores, self, nil, nil, 'surprise'
	, 'ex_hidden_sanctuary_4')
	scene_util.set_emotion(dolores, self, 'tired')

	-- 베로니카: (cross_arm, sleep_deep, left) 시련은 용사님을 찾기 위한 수단 중의 하나일 뿐…
	scene_util.play_normal_speech_action(boss_priestess, self, nil, 'cross_arm'
	, 'sleep_deep', 'ex_hidden_sanctuary_5')

	-- 베로니카: (cross_arm, idle, left) 진정한 용사님을 찾기 위한 저희의 길은 아직 끝나지 않았어요!
	music_player_util.play_sfx_one_shot('01_gatcha_point_01')
	scene_util.play_normal_speech_action(boss_priestess, self, nil, 'sing'
	, { name = 'smile', keep = true }, 'ex_hidden_sanctuary_6')

	-- 베로니카: (victory_get, smile, left) / 돌로레스: (idle, tired, right) (따라하지 않음)
	scene_util.set_anim(boss_priestess, self, 'victory_get')
	wait_for_sec(2)

	-- 돌로레스: (idle, idle, right → front) (… 말풍선, 침묵 후 입구 쪽으로 돌아서고, 입구에 있는 가디언을 발견)
	character_util.remove_emotion(dolores)
	character_util.show_emoticon_async(dolores, nil, 'silence')
	character_util.remove_anim_and_emotion(boss_priestess)

	wp_util.move_async(dolores, dolores.Position - vector(0, 0, 1.5), 1.5, nil,
			{ last_direction = 'down' })

	-- 돌로레스: (idle, idle, front) (깜짝 놀라는 말풍선)
	character_util.normal_jump(dolores, true)
	character_util.remove_emotion(dolores)
	character_util.show_emoticon_async(dolores, nil, 'notice')

	-- 베로니카: (idle, idle, front) (베로니카도 가디언을 돌아보고 놀람 말풍선)
	scene_util.set_direction(boss_priestess, 'down')
	wait_for_sec(0.5)

	character_util.normal_jump(boss_priestess, true)
	scene_util.set_emotion(boss_priestess, self, 'attack')
	character_util.show_emoticon_async(boss_priestess, nil, 'notice')

	-- 베로니카: (idle, attack, front) 불신자들이 여기까지!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.show_shout_speech_async(boss_priestess, 'ex_hidden_sanctuary_7')

	-- 베로니카: (idle, attack,down) 돌로레스, 잠깐 물러나 계세요.
	character_util.set_animation_n_times(boss_priestess, { name = 'release', count = 2, sfx = '01_swing_01' })
	scene_util.show_normal_speech_async(boss_priestess, 'ex_hidden_sanctuary_8')

	-- 선택지: 1) (긍정) 비켜줘 돌로레스. / 2) (부정) 교주님 말에 따르세요.
	choose_util.play_choose_event({ { 'ex_hidden_sanctuary_9', 'mercy' }, { 'ex_hidden_sanctuary_10', 'brutal' } })

	-- 이후 모션 진행 (release, idle, up)
	character_util.set_animation_n_times_async(leader, { name = 'release', count = 2, sfx = '01_swing_01' })
	wait_for_sec(0.5)

	-- 선택지 모션 진행 후 돌로레스가 베로니카, 플레이어를 번갈아 바라보는 것 2회씩 진행 후 1회 쉐이크 후 퇴장
	scene_util.set_emotion(dolores, self, 'tired')
	local look_around_count = 2
	for _ = 1, look_around_count do
		scene_util.set_direction(dolores, 'right')
		wait_for_sec(0.75)

		scene_util.set_direction(dolores, 'down')
		wait_for_sec(0.75)
	end

	scene_util.set_emotion(dolores, self, 'damaged')
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.shake(dolores, 0.03, 0.5)
	wait_for_sec(1)

	character_util.remove_anim_and_emotion(dolores)

	-- 돌로레스 퇴장
	local dolores_move_key = 'dolores_move'
	wp_util.move_with_end_callback(dolores, field_util.get_marker_pos(self.marker_name .. 3)
	, 7, nil, self, dolores_move_key,
			{
				last_direction = 'down',
				run = true,
				play_sfx = true
			})
	wait_for_sec(0.3)

	-- 베로니카 가운데로 이동
	local priestess_move_key = 'priestess_move'
	wp_util.move_with_end_callback(boss_priestess, boss_priestess.Position - vector(0.5, 0, 0)
	, 1, nil, self, priestess_move_key,
			{
				last_direction = 'down'
			})

	camera_util.resize_to_default(1)
	camera_util.return_to_leader(1)

	-- 이동 완료 대기
	wp_util.wait_move_end(self, dolores_move_key)
	wp_util.wait_move_end(self, priestess_move_key)

	character_util.set_active_state(dolores, 'disabled')

	-- 빵빠레 안나오게
	stage.BattleManager.PlayBattleVoiceAndFanfare = false

	-- 베로니카 몬스터로 변경
	character_util.remove_anim_and_emotion(boss_priestess)
	character_util.convert_to_monster(boss_priestess, self.battle_group_name, self.battle_group_name)
	character_util.set_death_type(boss_priestess, 'prostrate')
	command_util.execute_monster_notice(boss_priestess, user_party.Leader, 'battle')
end

function local_class:eliminated_priestess()
	music_player_util.play_stage_music({ state = 'muted' })

	sp_util.enter_scene(nil)
end

-- 베로니카를 무찌르고 난 뒤
function local_class:collectibles_get_event()
	local boss_priestess = self.get_boss_priestess()
	local priestess = self.get_priestess()
	local dolores = self.get_dolores()
	local leader = get_party_leader()

	screen_util.fade_out_async(1.5, unity_class.color.black, 'linear')

	-- 보스 베로니카 비활성화
	character_util.remove_anim_and_emotion(boss_priestess)
	character_util.convert_to_npc(boss_priestess)
	character_util.set_active_state(boss_priestess, 'disabled')
	character_util.set_position(boss_priestess, vector(999, 0, 999))

	-- 베로니카 세팅
	local target_pos = field_util.get_marker_pos(self.marker_name .. 2)
	character_util.set_anim_and_emotion(priestess, { name = 'prostrate' }, { name = 'damaged' })
	character_util.set_position(priestess, target_pos + vector(0.25, 0, 0))
	character_util.set_direction(priestess, 'left')
	character_util.set_active_state(priestess, 'enabled')

	-- 돌로레스
	character_util.set_active_state(dolores, 'enabled')
	character_util.set_position(dolores, field_util.get_marker_pos(self.marker_name .. 3) + vector(0.25, 0, -1))

	-- 파티 정렬
	party_util.align_party(target_pos - vector(0.5, 0, 0), 'left', 0, 'arc')

	camera_util.resize_to(self:get_camera_size_by_ratio(4), 1)

	camera_util.move_async(target_pos - vector(0.5, 0, 0), 1)

	music_player_util.play_stage_music({ state = 'field', volume = 0.5 })
	screen_util.fade_in_async(1.5, unity_class.color.black, 'linear')

	-- 베로니카 처치 시 기록물 ‘낡은 디스크’ 드랍
	-- 베로니카 사망 모션= dead
	-- ‘낡은 디스크’ 획득 연출 이후 암전

	-- 베로니카: (prostrate, damaged, left) (1회 꿈틀거림)
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.shake(priestess, 0.04, 0.5)
	wait_for_sec(1)

	character_util.remove_emotion(priestess)
	character_util.set_anim(priestess, { name = 'idle', mix_duration = 0.5 })
	wait_for_sec(0.75)

	-- 베로니카: (prostrate, damaged, left) 불신자, 가짜 용사 주제에 이 힘만은…
	scene_util.show_normal_speech_async(priestess, 'ex_hidden_sanctuary_11')

	-- 베로니카: (prostrate, damaged, left) (…말풍선, 침묵)
	character_util.show_emoticon_async(priestess, nil, 'silence')

	-- 베로니카: (idle, question, left) 아직 본인의 사명을 자각하지 못한 용사님이신 걸까요?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(priestess, self, nil
	, 'question', 'sleep_deep', 'ex_hidden_sanctuary_12')

	-- 베로니카: (idle, doyagao, left) 그런 거라면, 본인의 사명을 깨달을 수 있는 시련도 준비해 볼 필요가 있겠어요.
	music_player_util.play_sfx_one_shot('01_fade_out_03')
	scene_util.play_normal_speech_action(priestess, self, nil
	, 'bomb_idle', { name = 'doyagao', keep = true }, 'ex_hidden_sanctuary_13')

	-- 베로니카: (idle, doyagao, left) 후후, 후후후…
	scene_util.play_normal_speech_action(priestess, self, nil
	, nil, nil, 'ex_hidden_sanctuary_14')

	-- (단일 선택지) :(초록색 버튼) 베로니카를 붙잡는다 
	choose_util.play_choose_event({ { 'ex_hidden_sanctuary_15', 'mercy' } })

	camera_util.resize_to(self:get_camera_size_by_ratio(3), 1)
	camera_util.move(target_pos, 1)

	-- 선택지 선택 시 다음 연출 진행
	-- 메뉴얼 캐릭터가 점프하여 베로니카를 공격 시도 (슬로우 모션) (표정: attack)
	music_player_util.play_sfx_one_shot('01_qte_action_wind_02')
	music_player_util.play_sfx_one_shot('02_twohand_stomp_jump_01')
	character_util.set_anim_and_emotion(leader, { name = 'twohand_attack4', scale = 2.5, loop = false }
	, { name = 'attack' })
	character_util.jump_move(leader, leader.Position + vector(0.75, 0, 0), 1.5, 1
	, false, 'right')

	wait_for_sec(0.1)
	local mod_key = 'leader_jump_attack'

	time_util.mod(mod_key, 0.2)
	wait_for_sec(0.1)

	-- 교주님!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	character_util.set_locked_dir(dolores, 'left')
	character_util.set_anim_and_emotion(dolores, { name = 'prostrate' }, { name = 'attack' })
	speech_bubble_util.show_speech_bubble(dolores, { key = 'ex_hidden_sanctuary_16', scale = 1.25
	, viewport_pos = vector(0.55, 0.75), bubble_type = 'shout' })

	character_util.jump_move(dolores, target_pos - vector(0.25, 0, 0)
	, 20, 1.25, true, 'left')
	time_util.unmod(mod_key)

	camera_util.shake(0.2, 0.5)

	music_player_util.play_sfx_one_shot('02_hit_big_01')
	music_player_util.play_sfx_one_shot('01_trip_01')
	self.get_fx_hit():Instantiate(leader.Position + vector(0.25, 0.1, 0))

	character_util.normal_jump(dolores)
	character_util.spine_damage_red_pulse(dolores)
	character_util.spine_damage_squish_default(dolores)
	scene_util.set_emotion(dolores, self, 'damaged')

	character_util.normal_jump(priestess)
	character_util.set_anim_and_emotion(priestess, { name = 'prostrate' }, { name = 'damaged' })
	character_util.spine_damage_red_pulse(priestess)
	character_util.spine_damage_squish_default(priestess)

	-- 돌로레스가 뛰어들어 공격을 대신 맞고 쓰러진다.
	wp_util.move(dolores, target_pos + vector(0.5, 0, 0), 4, nil, { locked_dir = 'left' })
	wp_util.move_async(priestess, priestess.Position + vector(1.25, 0, 0)
	, 4, nil, { locked_dir = 'left' })
	wait_for_sec(0.1)

	-- 메뉴얼 캐릭터: (idle, surprise, right) (당황)
	character_util.normal_jump(leader, true)
	scene_util.set_emotion(leader, self, 'surprise')
	character_util.remove_anim(leader)
	wait_for_sec(0.25)

	-- 베로니카는 고개를 끄덕이고 다시 도망, 화면 밖으로 퇴장
	-- 베로니카 도주 후 기사 기본 모션 후 돌로레스 대화 이어짐
	music_player_util.play_sfx_one_shot('01_land_01')
	character_util.remove_emotion(priestess)
	character_util.set_anim(priestess, { name = 'idle', mix_duration = 0.25 })
	wait_for_sec(1)
	speech_bubble_util.remove_bubble(dolores)

	scene_util.set_emotion(priestess, self, 'attack')
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.set_animation_n_times_async(priestess, { name = 'nod', count = 1 })
	wait_for_sec(0.5)

	wp_util.move_async(priestess, priestess.Position + vector(6, 0, 0)
	, 6, nil, { run = true, play_sfx = true })
	character_util.set_active_state(priestess, 'disabled')

	-- 돌로레스: (prostrate, tired, left) 가짜 용사님…
	scene_util.set_emotion(dolores, self, 'tired')
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_17')

	--(단일 선택지): (노란색 버튼) 왜 방해를?
	character_util.remove_emotion(leader)
	choose_util.play_choose_event({ { 'ex_hidden_sanctuary_18', 'intellect' } })

	-- 선택지 선택 시 메뉴얼 캐릭터 모션 진행 (release, tired, right)
	scene_util.set_emotion(leader, self, 'tired')
	character_util.set_animation_n_times_async(leader, { name = 'release', count = 2, sfx = '01_swing_01' })

	-- 돌로레스: (prostrate, tired, left) 교주님이 진짜 용사를 찾아, 세상을 구원하실 거에요…
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_19')

	-- 돌로레스: (prostrate, tired, left) 저는 믿습니다… 구원을…
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_20')

	-- 돌로레스: (prostrate, tired, left) 제게 이제 믿음 외에는 아무 것도…
	scene_util.show_normal_speech_async(dolores, 'ex_hidden_sanctuary_21')

	music_player_util.play_stage_music({ state = 'muted', mix = 2 })
	screen_util.fade_out_async(2, unity_class.color.black, 'linear')

	-- 히든 스테이지 클리어 처리 
	local expedition_system = CS.Oak.Game:GetCurrentSubSystem()
	if not is_unity_null(expedition_system) then
		yield_return(expedition_system, 'ClearHiddenStage')
	end

	-- 스테이지 나가기
	CS.Oak.Game.Instance:ExpeditionStageToLobby()
end

function local_class:get_camera_size_by_ratio(camera_size)
	return camera_size * self.default_camera_size / 4
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
