local local_class = newclass('CoopExpeditionBattle2At3Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320020003
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CoopExpeditionIngameSequenceStartEvent), 'on_coop_ex_sequence_start_event')
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

function local_class:on_coop_ex_sequence_start_event(e)
	-- 연출 시작
	start_coroutine(self.start_first_clear_event, self)

	return true
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
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopExpeditionIngameSequenceStartEvent))

	self.cs_controller = nil
	self.scene = nil
end

function local_class:start_first_clear_event()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local leader = get_party_leader()
	local saya = get_character('npc_saya')
	local door = get_field_object('narrative_door')
	local leader_pos = field_util.get_marker_pos('coop_expedition_1_narrative_manual')
	local camera_pos = leader_pos + vector(0.5, 0, 0)

	-- 1초 간 circle fade out
	music_player_util.play_stage_music({ state = 'muted', mix = 6 })
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 리더 죽어 있는 상태라면 살림
	if leader.CharacterStatsBehaviour.IsDead then
		self:revive_character(leader)
	end

	-- 리더 세팅
	character_util.hide_weapon(leader, true)
	character_util.remove_anim_and_emotion(leader)

	character_util.set_direction(leader, 'up')
	character_util.set_position(leader, leader_pos)
	camera_util.move_async(camera_pos, 0)
	camera_util.resize_to_default(0)

	wait_for_sec(1)

	--플레이어, 사야 2.5초동안 run 자세로 위쪽으로 12칸 이동.
	wp_util.move_with_end_callback(leader, leader.Position + vector(0, 0, 12), nil
	, 2.5, self, move_end_key, { run = true, play_sfx = true })

	wp_util.move_with_end_callback(saya, saya.Position + vector(0, 0, 12), nil
	, 2.5, self, move_end_key, { run = true, play_sfx = true })

	camera_util.move(camera_pos + vector(0, 0, 12), 2.5)

	--이동을 시작한 동시에 화면 1초동안 일반 페이드 인.
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	wp_util.wait_move_end(self, move_end_key)

	--플레이어, 사야 캐릭터 idle 자세로 jump와 동시에 플레이어 머리 위에만 (notice) 이모티콘 표시.
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.group_normal_jump({ leader, saya }, '01_small_jump_01')
	character_util.show_emoticon_async(leader, nil, 'notice')

	--화면 1.5초에 걸쳐 위쪽으로 3칸 이동.
	music_player_util.play_sfx_one_shot('01_event_ex_01')
	camera_util.move_async(leader.Position + vector(0.5, 0, 3), 1.5)

	--대기 0.5초
	wait_for_sec(0.5)

	--거대한 문 열리는 애니메이션 출력.
	local animator = door:GetComponent(typeof(CS.UnityEngine.Animator))
	animator:Play('[gimmick]big_entrance')

	--거대한 문 열리는 애니메이션 완료까지 대기
	wait_for_sec(3.5)

	--플레이어, 사야 2초에 걸쳐 walk 자세로 위쪽으로 3칸 이동.
	wp_util.move(leader, leader.Position + vector(0, 0, 3), nil, 2)
	wp_util.move(saya, saya.Position + vector(0, 0, 3), nil, 2)

	--위쪽으로 1.5칸 이동했을 때 0.5초에 걸쳐 두 캐릭터 알파값 0으로 페이드 아웃.
	wait_for_sec(1.5)

	character_util.spine_set_alpha_fade(leader, 0, 0.5)
	character_util.spine_set_alpha_fade(saya, 0, 0.5)

	--플레이어, 사야 캐릭터 페이드 아웃 완료된 후 0.6초 대기
	wait_for_sec(1.1)

	--화면 1초에 걸쳐 일반 페이드 아웃.
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	character_util.stop(leader)
	character_util.stop(saya)

	-- 카메라 화면 밖으로 보냄
	camera_util.move_async(vector(3000, 0, 3000), 0)
	wait_for_sec(0.5)

	-- 클리어 UI 보여야해서 fade in
	screen_util.fade_in_async(0, unity_class.color.black, 'linear')

	-- 연출 시퀀스 끝
	message_system:Publish(CS.Oak.CoopExpeditionIngameSequenceEndEvent.Create())
end

function local_class:revive_character(character)
	local heal_info = CS.Oak.HealInfo()
	heal_info.sender = character
	heal_info.target = character
	heal_info.heal = character.CharacterStatsBehaviour.MaxHP
	heal_info.skipEffect = true
	heal_info.isRevive = true

	command_util.publish_heal(heal_info)
	message_system:SendSync(character.CharacterBehaviour, CS.Oak.StateResetEvent.Instance)
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene)
	end
}
