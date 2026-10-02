local local_class = newclass('QueenCastle3Controller')

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.scene_version = scene_util.default_version

	self.get_mural = function(number)
		return get_field_object('mural_' .. number)
	end

	self.get_exit_passage = function()
		return get_field_object('exit_passage_16_5')
	end

	self.get_exit_lobby = function()
		return get_field_object('exit_lobby')
	end

	self.party_switching_complete = false
	self.main_s9_mural_scene_finished_key = 'main_s9_mural_scene_finished'

	--mural cs_controller
	self.mural = nil
	self.main_quest_progress = nil

	--res_holder
	self.iron_teatans = nil
	self.res_holder = nil

	--region 챔피언 후일담

	self.get_fx_hit = function() return unity_object_pool.GetOrCreate('FX_hit') end

	self.get_teatan_hero = function() return get_character('teatan') end
	self.get_desert_slave = function() return get_character('desert_slave') end
	self.get_tanker = function() return get_character('tanker') end
	self.get_innuit = function() return get_character('innuit') end

	self.teatan_hero_key = 'stage_3_show_teatan_hero_event'
	self.desert_slave_key = 'stage_3_show_desert_slave_event'
	self.tanker_key = 'stage_3_show_tanker_event'
	self.innuit_key = 'stage_3_show_innuit_event'

	self.is_show_teatan_hero_event = false
	self.is_show_desert_slave_event = false
	self.is_show_tanker_event = false
	self.is_show_innuit_event = false

	--endregion
end

function local_class:dispose()
	message_system:Unsubscribe(self, typeof(CS.Oak.InteractEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneEnterEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.ZoneLeaveEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.StageEndEvent))

	if self.res_holder ~= nil then
		self.res_holder:Dispose()
	end
	self.res_holder = nil

	if not is_unity_null(self.iron_teatans) then
		CS.UnityEngine.Object.Destroy(self.iron_teatans)
	end
	self.iron_teatans = nil

	self.mural = nil
	self.main_quest_progress = nil

	self.cs_controller = nil
	self.scene = nil
end

--region load_resource
function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.InteractEvent), 'on_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneEnterEvent), 'on_zone_enter_event')
	message_system:Subscribe(self, typeof(CS.Oak.ZoneLeaveEvent), 'on_zone_leave_event')
	message_system:SubscribeOnce(self, typeof(CS.Oak.StageEndEvent), 'on_stage_end_event')

	return util.cs_generator(self.on_load_resource, self)
end

function local_class:on_load_resource()
	self.mural = get_or_create_global_table('Quest/Main/QueenCastle/Common/MuralTheatreController')
	self.mural:load_async()

	self.get_fx_hit()

	local obelisk_controller = get_or_create_global_table('Quest/Main/QueenCastle/Common/SectorObeliskController')
	obelisk_controller:refresh_obelisk_state(self)
end
--endregion

--region launch
-- launch를 이 컨트롤러에서 컨트롤 할 것인가. true로 변경하면 컨트롤 가능
function local_class:need_on_launch()
	return true
end

-- need_on_lunch가 true일 경우 이리로 들어옴
function local_class:on_launch(start_point_name)
	start_coroutine(self.setting_by_progress, self)
end
--endregion

--region event
function local_class:on_event(e)
	if lua_helper.type_compare(e, CS.Oak.InteractEvent) then
		return self:on_interact_event(e)
	end

	return false
end

function local_class:on_interact_event(e)
	--각 서브 퀘스트 클리어 시에만 인터렉트 이벤트 들어올 수 있음
	if lua_helper.reference_equals(e.Target, self.get_mural(1)) then
		sp_util.start_scene(self.mural_routine, self, 'first_mural', true)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mural(2)) then
		sp_util.start_scene(self.mural_routine, self, 'second_mural')
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mural(3)) then
		sp_util.start_scene(self.mural_routine, self, 'third_mural')
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mural(4)) then
		sp_util.start_scene(self.mural_routine, self, 'fourth_mural')
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mural(5)) then
		sp_util.start_scene(self.mural_routine, self, 'fifth_mural')
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_mural(6)) then
		sp_util.start_scene(self.mural_routine, self, 'sixth_mural', true)
		return true
	end

	if lua_helper.reference_equals(e.Target, self.get_teatan_hero())
			and not self.is_show_teatan_hero_event then
		self.is_show_teatan_hero_event = true
		sp_util.start_scene(self.interact_teatan_hero, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_desert_slave())
			and not self.is_show_desert_slave_event then
		self.is_show_desert_slave_event = true
		sp_util.start_scene(self.interact_desert_slave, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_tanker())
			and not self.is_show_tanker_event then
		self.is_show_tanker_event = true
		sp_util.start_scene(self.interact_tanker, self)
		return true
	elseif lua_helper.reference_equals(e.Target, self.get_innuit())
			and not self.is_show_innuit_event then
		self.is_show_innuit_event = true
		sp_util.start_scene(self.interact_innuit, self)
		return true
	end

	return false
end

function local_class:on_zone_enter_event(e)
	if type_util.is_zone_full_enter(e, get_party_leader(), 'mural_room') and
			self.main_quest_progress.InnerProgress > 7 then
		start_coroutine(self.switch_stage_music, self, true)
	end
end

function local_class:on_zone_leave_event(e)
	if type_util.is_zone_full_leave(e, get_party_leader(), 'mural_room') and
			self.main_quest_progress.InnerProgress > 7 then
		start_coroutine(self.switch_stage_music, self, false)
	end
end

function local_class:on_stage_end_event(e)
	if not self.is_show_teatan_hero_event then
		character_util.remove_relate_event(self.get_teatan_hero(), self)
	end

	if not self.is_show_desert_slave_event then
		character_util.remove_relate_event(self.get_desert_slave(), self)
	end

	if not self.is_show_tanker_event then
		character_util.remove_relate_event(self.get_tanker(), self)
	end

	if not self.is_show_innuit_event then
		character_util.remove_relate_event(self.get_innuit(), self)
	end
end

function local_class:on_complete_switching_party_member_event(_)
	--self.party_switching_complete = true
	return true
end

--endregion

--region late_update_frame
-- late_update_frame 사용 여부. true로 변경하면 사용가능
function local_class:use_late_update_frame()
	return false
end

-- late_update_frame의 priority. callback등록 시 이 값을 참조한다.
function local_class:late_update_frame_priority()
	return CS.Oak.UpdatePriorities.StageEvent
end

function local_class:late_update_frame(dt)
end
--endregion

--
function local_class:setting_by_progress()
	local main_quest_id = 330
	self.main_quest_progress = user_progress:GetStartedQuest(main_quest_id)
	local s9_screen_play = self:s9_progress_setting()

	--메인 10섹션 이전일 경우 exit 교체
	if self.main_quest_progress ~= nil and self.main_quest_progress.InnerProgress < 9 then
		self.get_exit_lobby().Position = self.get_exit_passage().Position
		self.get_exit_passage().Position = vector(500, 0, 500)
		local socket = get_field_object('obelisk_socket')
		local socket_glow = CS.Utils.FindChildRecursively(socket.Transform, '[gimmick]obelisk_socket_glow')
		socket_glow.gameObject:SetActive(false)
	end

	-- 시작 연출 관리
	if self.main_quest_progress == nil or self.main_quest_progress.IsComplete then
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	elseif self.main_quest_progress.InnerProgress == 7 then
		message_system:Publish(CS.Oak.StageStartEvent.Instance)
	elseif self.main_quest_progress.InnerProgress == 8 then
		if s9_screen_play then
			message_system:Publish(CS.Oak.StageStartEvent.Instance)
		else
			stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
		end
	else
		stage_launch_util.play_launch_stage('right', field:GetMarker('default_start').position, true, true)
	end
end

--신전 클리어 여부에 따른 스테이지 셋팅
--9섹션 스크린플레이 할지 boolean 리턴
function local_class:s9_progress_setting()
	local s9_screen_play = false

	local s9_progress_info = {
		innuit = {
			quest_id = 331,
			finished_key = 'main_s9_innuit_scan_finished',
			npc_setting = self.innuit_setting,
			event_state_key = self.innuit_key,
		},
		desert_slave = {
			quest_id = 332,
			finished_key = 'main_s9_desert_slave_scan_finished',
			npc_setting = self.desert_slave_setting,
			event_state_key = self.desert_slave_key,
		},
		teatan_hero = {
			quest_id = 338,
			finished_key = 'main_s9_teatan_scan_finished',
			npc_setting = self.teatan_setting,
			event_state_key = self.teatan_hero_key,
		},
		tanker = {
			quest_id = 336,
			finished_key = 'main_s9_tanker_scan_finished',
			npc_setting = self.tanker_setting,
			event_state_key = self.tanker_key,
		},
	}

	--신전 별 클리어 여부 확인 후 셋팅
	for _, info in pairs(s9_progress_info) do
		local progress = user_progress:GetStartedQuest(info.quest_id)
		if progress ~= nil and progress.IsComplete then
			--스캔 이벤트 시청 여부
			local state = quest_util.get_custom_state(self.main_quest_progress, info.finished_key)
			if state ~= 1 then
				s9_screen_play = true
			end

			--클리어 시 스테이지 셋팅
			local is_show_event = quest_util.get_custom_state(self.main_quest_progress, info.event_state_key)
			info.npc_setting(self, is_show_event > 0)
		end
	end

	return s9_screen_play
end

function local_class:innuit_setting(is_show_event)
	self.is_show_innuit_event = is_show_event

	local innuit = self.get_innuit()
	scene_util.hide_weapon(innuit)
	character_util.set_position(innuit, field_util.get_marker_pos('innuit_pos'))
	scene_util.set_direction(innuit, 'right', false)

	if self.is_show_innuit_event then
		innuit.Interactable.Talk = 'qc_champion_later_story_4_12'
	else
		character_util.add_listener(innuit, self)
	end
end

function local_class:desert_slave_setting(is_show_event)
	self.is_show_desert_slave_event = is_show_event

	--마빈 셋팅
	local desert_slave = self.get_desert_slave()
	scene_util.hide_weapon(desert_slave)
	character_util.set_position(desert_slave, field_util.get_marker_pos('desert_slave_pos'))
	scene_util.set_direction(desert_slave, 'right', false)

	if self.is_show_desert_slave_event then
		desert_slave.Interactable.Talk = 'qc_champion_later_story_2_14'
	else
		character_util.add_listener(desert_slave, self)
	end
end

function local_class:teatan_setting(is_show_event)
	self.is_show_teatan_hero_event = is_show_event

	local teatan_hero = self.get_teatan_hero()
	scene_util.hide_weapon(teatan_hero)
	character_util.set_position(teatan_hero, field_util.get_marker_pos('teatan_hero_pos'))
	scene_util.set_direction(teatan_hero, 'right', false)
	scene_util.set_anim(teatan_hero, self, 'eat')
	self:load_iron_teatan()

	if self.is_show_teatan_hero_event then
		teatan_hero.Interactable.Talk = 'qc_champion_later_story_1_18'
	else
		character_util.add_listener(teatan_hero, self)
	end
end

function local_class:tanker_setting(is_show_event)
	self.is_show_tanker_event = is_show_event

	local tanker = self.get_tanker()
	scene_util.hide_weapon(tanker)
	character_util.set_position(tanker, field_util.get_marker_pos('tanker_pos'))
	scene_util.set_direction(tanker, 'left', false)

	if self.is_show_tanker_event then
		tanker.Interactable.Talk = 'qc_champion_later_story_3_13'
	else
		character_util.add_listener(tanker, self)
	end
end

function local_class:interact_teatan_hero()
	local leader = get_party_leader()
	local teatan_hero = self.get_teatan_hero()
	local string_key = 'qc_champion_later_story_1_'

	-- 노란원(마리안) (right,idle,eat) 중 인터랙트 시 마리안 기준 좌측으로 정렬
	party_util.align_party(teatan_hero, 'left', 0.5, 'linear')

	-- 마리안(left,smile,idle)(jump1회): 아! $name, 왔구나!
	character_util.remove_anim_and_emotion(teatan_hero)
	character_util.normal_jump(teatan_hero, true)
	scene_util.play_normal_speech_action(teatan_hero, self, 'left', nil, 'smile', string_key .. 1)

	-- 마리안(left,idle,idle): 내가 어떻게든 해보려고 했는데…
	scene_util.show_normal_speech_async(teatan_hero, string_key .. 2)

	-- 마리안(left,tired,cross_arm): 아이언 티탄의 부피와 질량그리고 현재 에너지 량을 고려해 봤을때…
	scene_util.play_normal_speech_action(teatan_hero, self, nil, 'cross_arm', 'tired', string_key .. 3)

	-- 마리안(left,tired,nod1회): 아쉽지만… 아이언 티탄을 지금 당장 이 위로 보내기는 힘들 것 같아…
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	scene_util.play_normal_speech_action(teatan_hero, self, nil, { name = 'nod', count = 1 }
	, 'tired', string_key .. 4)

	local offset = vector(-2, 0, 2.5)

	-- 이때 마리안(right,idle,idle)
	-- 아이언티탄:<color=#AE8319>괜찮습니다. 주인님. 이곳에서 주인님을 응원하겠습니다.</color>
	music_player_util.play_sfx_one_shot('03_dialogue_worker_05')
	scene_util.set_direction(teatan_hero, 'right')
	character_util.remove_anim_and_emotion(teatan_hero)
	speech_bubble_util.show_speech_bubble_async(teatan_hero, { key = string_key .. 5
	, speaker_transform = self.iron_teatans.transform, skip = true, offset = offset, bubble_direction = 'lt'})

	-- 마리안(right,smile,idle) : 고마워, 아이언 티탄!
	music_player_util.play_sfx_one_shot('03_dialogue_positive_01')
	scene_util.play_normal_speech_action(teatan_hero, self, nil, nil
	, 'smile', string_key .. 6)

	-- 마리안(left,smile,idle) : 내가 평생을 바친 로봇과 대화해보다니… 살다보니 이런 경험을 다 해보네!
	scene_util.play_normal_speech_action(teatan_hero, self, 'left', nil
	, 'smile', string_key .. 7)

	-- 마리안(left,idle,idle)(shake0.03)
	music_player_util.play_sfx_one_shot('01_rustle_01')
	character_util.shake(teatan_hero, 0.03, 0.3)
	wait_for_sec(0.3)

	-- 마리안(left,tired,idle): 이럴때… 그 친구가 있었으면, 정말 좋아했을 텐데…
	scene_util.play_normal_speech_action(teatan_hero, self, nil, nil
	, { name = 'tired', keep = true }, string_key .. 8)

	-- 아이언티탄:<color=#AE8319>주인님…</color>
	music_player_util.play_sfx_one_shot('03_dialogue_sadness_01')
	speech_bubble_util.show_speech_bubble_async(teatan_hero, { key = string_key .. 9
	, speaker_transform = self.iron_teatans.transform, skip = true, offset = offset, bubble_direction = 'lt'})

	-- 가디언 선택지) 1. 마티? (초록) / 2. 소히? (빨강)
	local choose_result = choose_util.play_choose_event({
		{ string_key .. 10, 'mercy' }, { string_key .. 11, 'brutal' } })

	scene_util.set_emotion(leader, self, 'tired')
	if choose_result == 1 then
		-- 가디언(right,tired,release)1초
		scene_util.set_anim(leader, self, 'release')
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(leader)

		-- 마리안(left,sleep_deep,idle)(shake0.03) 1초
		music_player_util.play_sfx_one_shot('01_rustle_01')
		scene_util.set_emotion(teatan_hero, self, 'sleep_deep')
		character_util.shake(teatan_hero, 0.03, 1)
		wait_for_sec(1)

		-- 마리안(left,idle,idle): 이럴때 이런 생각하면 안되지.
		character_util.remove_anim_and_emotion(teatan_hero)
		scene_util.show_normal_speech_async(teatan_hero, string_key .. 12)

		-- 마리안(left,smile,idle)(jump1회): 그 친구가 이런 모습을 봤으면 실망해 할테니까.
		scene_util.play_normal_speech_action(teatan_hero, self, nil, nil
		, 'smile', string_key .. 13)
	else
		-- 가디언(right,tired,bomb_idle)
		scene_util.set_anim(leader, self, 'bomb_idle')
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(leader)

		-- 마리안(left,mad,idle)(jump1회): 내가 그런애를 지금 왜 생각해!
		character_util.normal_jump(teatan_hero, '01_player_jump_01')
		scene_util.play_normal_speech_action(teatan_hero, self, nil, nil
		, 'mad', string_key .. 14)

		-- 마리안(left,idle,idle): 뭐, 걔는 어디있던 제멋대로 사는애니까.
		scene_util.show_normal_speech_async(teatan_hero, string_key .. 15)

		-- 마리안(left,idle,nod1회): 알아서 잘 살아남고 있겠지.
		scene_util.play_normal_speech_action(teatan_hero, self, nil, { name = 'nod', count = 1 }
		, nil, string_key .. 16)
	end

	-- 마리안(left,attack,release): 빨리 공주님을 구하러 가자고!
	music_player_util.play_sfx_one_shot('03_dialogue_emphasize_01')
	scene_util.play_normal_speech_action(teatan_hero, self, nil, 'release'
	, 'attack', string_key .. 17)

	-- 마리안(right,idle,eat): 떠나기 전에 이 기름칠은 마치고 가야겠어.
	scene_util.set_direction(teatan_hero, 'right', false)
	scene_util.play_normal_speech_action(teatan_hero, self, 'right', { name = 'eat', keep = true }
	, nil, string_key .. 18)

	-- 이 후 상단 대사 원라인
	character_util.remove_relate_event(teatan_hero, self)
	teatan_hero.Interactable.Talk = string_key .. 18
	quest_util.set_custom_state(self.main_quest_progress, self.teatan_hero_key, 1)
end

function local_class:interact_desert_slave()
	local leader = get_party_leader()
	local desert_slave = self.get_desert_slave()
	local string_key = 'qc_champion_later_story_2_'

	-- 초록1 마빈(right,idle,idle) 말걸면 바로 우측에 정렬
	party_util.align_party(desert_slave, 'right', 0.5, 'linear')

	-- 마빈 (right,idle,question): 내가 얼마나 오랫동안 이러고 있었던 거지?
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(desert_slave, self, nil, 'question'
	, nil, string_key .. 1)

	-- 마빈 (right,idle,bomb_idle): 전혀… 기억이 나지 않는군.
	scene_util.play_normal_speech_action(desert_slave, self, nil, 'bomb_idle'
	, nil, string_key .. 2)

	-- 마빈 (right,idle,nod2회): 그래도 네 헤실한 얼굴을 보니 조금은 마음이 놓인다.
	scene_util.play_normal_speech_action(desert_slave, self, nil, 'nod'
	, nil, string_key .. 3)

	-- 마빈(right,idle,idle): 오랜만에 바람이 쐬고 싶어… 이상한 신전 바람이 아니라.
	scene_util.show_normal_speech_async(desert_slave, string_key .. 4)

	-- 마빈(right,idle,idle): 라일라는… 잘 있겠지.
	scene_util.show_normal_speech_async(desert_slave, string_key .. 5)

	-- 가디언 선택지) 1. 잘 살고있어! (초록) / 2. 나도 잘 몰라. (빨강)
	local choose_result = choose_util.play_choose_event({
		{ string_key .. 6, 'mercy' }, { string_key .. 7, 'brutal' } })

	if choose_result == 1 then
		-- 가디언(left,smile,sing)1초
		scene_util.set_emotion(leader, self, 'smile')
		scene_util.set_anim(leader, self, 'sing')
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(leader)

		-- 마빈(right,idle,bomb_idle): 네가 그렇게 말해주니… 안심이 되는 군.
		scene_util.play_normal_speech_action(desert_slave, self, nil, 'bomb_idle'
		, nil, string_key .. 8)
	else
		-- 가디언(left,tired,bomb_idle)1초
		scene_util.set_emotion(leader, self, 'tired')
		scene_util.set_anim(leader, self, 'bomb_idle')
		wait_for_sec(1)
		character_util.remove_anim_and_emotion(leader)

		-- 마빈(right,idle,idle): 라일라는… 내가 끝까지 지켜줄 거다.
		scene_util.show_normal_speech_async(desert_slave, string_key .. 9)
	end

	-- 마빈(right,idle,dagger_idle): 라일라를 위해서라도… 일단 이 상황부터 헤쳐 나가야겠지.
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	scene_util.play_normal_speech_action(desert_slave, self, nil, 'dagger_idle'
	, nil, string_key .. 10)

	-- 마빈(right,idle,idle): 그럼, 일단 날 속인 그 여왕녀석을 묵사발을 내버리고!
	scene_util.show_normal_speech_async(desert_slave, string_key .. 11)

	-- 마빈(right,attack,victory_get): 공주를 구해내는 거다!
	scene_util.play_normal_speech_action(desert_slave, self, nil, 'victory_get'
	, 'attack', string_key .. 12)

	-- 마빈(right,mad,jingak): 만약에 네가 그 여왕녀석을 끝장내는 데 망설임이 생기면 내게 맡기라고!
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	scene_util.play_normal_speech_action(desert_slave, self, nil
	, { name = 'jingak', sfx_name = '03_mech_stomp_02' }, 'mad', string_key .. 13)

	-- 마빈(right,idle,idle): 아주 형체도 못 알아볼 정도로 흠씬 두들겨 패주마!
	scene_util.show_normal_speech_async(desert_slave, string_key .. 14)

	-- 이 후 상단 원라인 대사
	character_util.remove_relate_event(desert_slave, self)
	desert_slave.Interactable.Talk = string_key .. 14
	quest_util.set_custom_state(self.main_quest_progress, self.desert_slave_key, 1)
end

function local_class:interact_tanker()
	local leader = get_party_leader()
	local tanker = self.get_tanker()
	local string_key = 'qc_champion_later_story_3_'

	-- 붉은점 크레이그(left, idle, idle) 배치 인터랙트 시 좌측 정렬
	party_util.align_party(tanker, 'left', 0.5, 'linear')

	-- 크레이그(left,tired,idle): $name… 네게 정말 미안한 일을 한 것 같군.
	scene_util.play_normal_speech_action(tanker, self, nil, nil
	, 'tired', string_key .. 1)

	-- 크레이그(left,idle,bomb_idle): 버팀목이 되어주긴 커녕… 방해만 했으니.
	scene_util.play_normal_speech_action(tanker, self, nil, 'bomb_idle'
	, nil, string_key .. 2)

	-- 크레이그(left,idle,idle): 에일리가 보면 참 실망했을 거야.
	scene_util.show_normal_speech_async(tanker, string_key .. 3)

	-- 크레이그(left,smile,clap): 그것보다 정말 대단한 전략이었네!
	scene_util.play_normal_speech_action(tanker, self, nil, 'clap'
	, 'smile', string_key .. 4)

	-- 크레이그(left,attack,release): 그 짧은 순간에 안드로이드로 변장 할 생각을 하다니!
	scene_util.play_normal_speech_action(tanker, self, nil, 'release'
	, 'attack', string_key .. 5)

	-- 크레이그(left,sleep_deep,question): 나도… 조금은 본받아야 싶긴 하네.
	music_player_util.play_sfx_one_shot('01_rustle_01')
	scene_util.play_normal_speech_action(tanker, self, nil, { name = 'question', keep = true }
	, { name = 'sleep_deep', keep = true }, string_key .. 6)

	-- 가디언 선택지 1) 제발 넌 하지마! (빨강) / 2) 좋아! 같이 하자! (초록)
	local choose_result = choose_util.play_choose_event({
		{ string_key .. 7, 'brutal' }, { string_key .. 8, 'mercy' } })

	character_util.remove_anim_and_emotion(tanker)
	if choose_result == 1 then
		-- 가디언(right,mad,release2회)
		camera_util.shake(0.3, 0.15)
		music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
		scene_util.set_emotion(leader, self, 'mad')
		character_util.set_animation_n_times_async(leader, { name = 'release', count = 2, sfx = '01_swing_01' })
		character_util.remove_anim(leader)

		-- 크레이그(left,tired,bomb_idle): 그… 그렇게 까지 말할 건 없지 않나.
		music_player_util.play_sfx_one_shot('03_dialogue_tipsy_01')
		scene_util.play_normal_speech_action(tanker, self, nil, 'bomb_idle'
		, 'tired', string_key .. 9)
	else
		-- 가디언(right,smile,success)
		scene_util.set_emotion(leader, self, 'smile')
		scene_util.set_anim(leader, self, 'success')
		wait_for_sec(1.5)

		-- 크레이그(left,smile,idle): 뭐, 당장은 아니지!
		scene_util.play_normal_speech_action(tanker, self, nil, nil
		, 'smile', string_key .. 10)
	end
	character_util.remove_anim_and_emotion(leader)

	-- 크레이그(left,idle,idle): 빨리 공주를 구출하러 가야겠어.
	scene_util.show_normal_speech_async(tanker, string_key .. 11)

	-- 크레이그(left,idle,bomb): 그렇지 않고서야… 내 행보들이 부끄러워서 고개를 들 수 없군.
	scene_util.play_normal_speech_action(tanker, self, nil, 'bomb_idle'
	, nil, string_key .. 12)

	-- 크레이그(left,idle,idle): $name! 나만 믿어. 너의 방패가 된 이상 절대 실망시키지 않을 거라고!
	music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
	scene_util.show_normal_speech_async(tanker, string_key .. 13)

	-- 이 후 상단 대사 원라인 상태
	character_util.remove_relate_event(tanker, self)
	tanker.Interactable.Talk = string_key .. 13
	quest_util.set_custom_state(self.main_quest_progress, self.tanker_key, 1)
end

function local_class:interact_innuit()
	local leader = get_party_leader()
	local innuit = self.get_innuit()
	local string_key = 'qc_champion_later_story_4_'

	-- 파랑점 코코(right, idle, idle) 배치 이후 인터랙트시 우측 정렬
	party_util.align_party(innuit, 'right', 0.5, 'linear')

	-- 코코(right,idle,idle): $name…
	scene_util.show_normal_speech_async(innuit, string_key .. 1)

	-- 코코(right,tired,idle): 솔직히 말하자면… 난 아직도 지금 이 상황이 믿기지 않아.
	scene_util.play_normal_speech_action(innuit, self, nil, nil
	, 'tired', string_key .. 2)

	-- 코코(right,idle,idle): 사실은… 사실은 지금조차도 난 속고있을지도 모른다는 불안감에…
	scene_util.show_normal_speech_async(innuit, string_key .. 3)

	-- 가디언 선택지) 1. 코코 때리기. (빨강) / 2. 위로하기.
	local choose_result = choose_util.play_choose_event({
		{ string_key .. 4, 'brutal' }, { string_key .. 5, 'mercy' } })

	if choose_result == 1 then
		-- 가디언(left,mad,cast2)
		music_player_util.play_sfx_one_shot('03_dialogue_ready_01')
		scene_util.set_emotion(leader, self, 'mad')
		scene_util.set_anim(leader, self, { name = 'cast2', upper = true })
		wait_for_sec(0.75)

		-- 가디언(left)방향 0.5칸 이동 후 (left,attack,twohand_attack4) 후 (right)방향 0.5칸 뒷걸음질
		wp_util.move_async(leader, leader.Position - vector(0.75, 0, 0), 2, nil)
		character_util.remove_anim(leader, true)
		scene_util.set_anim(leader, self, { name = 'attack', loop = false, next_anim = 'idle' })
		wait_for_sec(0.35)

		-- 코코 피격과 동시에 (right,damaged,damaged) fx_hit와 피격효과 (빨간틴트+스쿼시)
		camera_util.shake(0.2, 0.2)
		music_player_util.play_sfx_one_shot('02_hit_big_01')
		self.get_fx_hit():Instantiate(innuit.Position + vector(0, 0.2, 0))
		scene_util.set_emotion(innuit, self, 'damaged')
		scene_util.set_anim(innuit, self, 'damaged')
		character_util.spine_damage_squish_default(innuit)
		character_util.spine_damage_red_pulse(innuit)
		wait_for_sec(0.4)

		character_util.remove_anim(leader)
		wp_util.move_async(leader, leader.Position + vector(0.75, 0, 0), 2, nil
		, { locked_dir = 'left' })

		-- 코코(right,tired,idle): 아… 알았어. 이미 너한테는 충분히 맞았다고.
		scene_util.set_emotion(leader, self, 'attack')
		character_util.remove_anim_and_emotion(innuit)
		scene_util.play_normal_speech_action(innuit, self, nil, nil
		, 'tired', string_key .. 6)
	else
		--가디언(right,tired,nod2회)
		scene_util.set_emotion(leader, self, 'tired')
		scene_util.set_anim_async(leader, self, 'nod')

		-- 가디언(left)방향 0.5칸 이동 후 (left,smile,dualgun_attack_left) 후 (right)방향 0.5칸 뒷걸음질
		wp_util.move_async(leader, leader.Position - vector(0.75, 0, 0), 2, nil)
		character_util.set_anim(leader, { name = 'dualgun_attack_left', loop = false })
		wait_for_sec(1.5)

		character_util.remove_anim(leader)
		wp_util.move_async(leader, leader.Position + vector(0.75, 0, 0), 2, nil
		, { locked_dir = 'left' })

		-- 코코(right,tired,idle): … 고마워.
		scene_util.play_normal_speech_action(innuit, self, nil, nil
		, 'tired', string_key .. 7)
	end
	character_util.remove_anim_and_emotion(leader)

	-- 코코(right,idle,idle): 그래도 이제 나한테 어떤 의문점도 망설임도 없어.
	scene_util.show_normal_speech_async(innuit, string_key .. 8)

	-- 코코(right,sleep_deep,idle): 널 믿을 거야.
	scene_util.play_normal_speech_action(innuit, self, nil, nil
	, 'sleep_deep', string_key .. 9)

	-- 코코(right,idle,idle): 네가 선이여도 악이여도 너를 따라 갈게.
	scene_util.show_normal_speech_async(innuit, string_key .. 10)

	-- 코코(right,smile,idle): 나를 믿어주는… 너를 믿기로 했으니까.
	scene_util.play_normal_speech_action(innuit, self, nil, nil
	, 'smile', string_key .. 11)

	-- 코코(right,idle,idle) 잘 부탁해. $name.
	scene_util.show_normal_speech_async(innuit, string_key .. 12)

	-- 이 후 상단 대사 원라인 상태
	character_util.remove_relate_event(innuit, self)
	innuit.Interactable.Talk = string_key .. 12
	quest_util.set_custom_state(self.main_quest_progress, self.innuit_key, 1)
end

--5번째 벽화만 9섹션에 대사가 존재함
function local_class:mural_routine(mural_name, show_dialogue)
	show_dialogue = lua_helper.get_or_default(show_dialogue, false)

	--9섹션 특정 시점 이후로는 텍스트 강제 출력
	local state = quest_util.get_custom_state(self.main_quest_progress, self.main_s9_mural_scene_finished_key)

	music_player_util.change_stage_music_volume('event', 0.6, 4)

	music_player_util.play_sfx_one_shot('01_walk_03')

	if state == 2 then
		self.mural:show_theatre_async(mural_name, true)
	else
		--특점 시점이 아닐지라도 show_dialogue가 true일 경우 텍스트 출력
		self.mural:show_theatre_async(mural_name, show_dialogue)
	end

	music_player_util.change_stage_music_volume('event', 1, 4)

	--9섹션인 경우 fourth_mural 추가 연출
	if self.main_quest_progress.InnerProgress == 8 and mural_name == 'fourth_mural' then
		local kai = get_character('hero_ai')
		scene_util.set_direction(kai, 'up')
		--카이(up, idle): …그림이 이상하게 바뀌지 않았나요?
		scene_util.show_normal_speech_async(kai, 'qc_main_s9_narration_15')
		--카이(up, idle): 저스티스 스캔은 이상 없었는데 이상하네요….
		scene_util.show_normal_speech_async(kai, 'qc_main_s9_narration_16')
	end
end

--티탄 로봇 로드
function local_class:load_iron_teatan()
	if self.res_holder == nil then
		self.res_holder = CS.Foundations.ResourceHolder()
	end

	yield_return_func(CS.Foundations.IResourceHolderExtensions.LoadPrefabAsync, self.res_holder,
			'theatres/iron_teatans', 'iron_teatans', function(prefab)
				local obj = CS.UnityEngine.GameObject.Instantiate(prefab)
				self.iron_teatans = obj:AddComponent(typeof(CS.Oak.IronTeatans))
				self.iron_teatans.Name = 'iron_teatan_1'
				self.iron_teatans.Hitbox = CS.Oak.Hitbox(vector(0.5, 0, 0.5), vector(2.5, 1, 2.5))
				self.iron_teatans.transform.localScale = vector(1, 1, 1)
				self.iron_teatans.Holdable = CS.Oak.NonHoldable.Instance
				self.iron_teatans.FieldObjectBehaviour = CS.Oak.NullFieldObjectBehaviour()
				self.iron_teatans.CrashBehaviour = CS.Oak.WallCrashBehaviour.Instance
				self.iron_teatans.ActiveState = active_state('enabled')
				self.iron_teatans:Init()
				self.iron_teatans.Position = field_util.get_marker_pos('iron_teatan_pos')
				self.iron_teatans.transform.localRotation = unity_class.quaternion.Euler(0, 270, 0)
				self.iron_teatans_script = self.iron_teatans:GetComponent(typeof(CS.Oak.IronTeatans))
			end)
end

function local_class:switch_stage_music(is_mural_room)
	if is_mural_room then
		music_player_util.play_stage_music({ name = 'ondemand/v2_65_queencastle/audio:bgm_queencastle_wall', state = 'event', mix = 4 })
	else
		music_player_util.play_stage_music({ state = 'field', mix = 4 })
	end
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
