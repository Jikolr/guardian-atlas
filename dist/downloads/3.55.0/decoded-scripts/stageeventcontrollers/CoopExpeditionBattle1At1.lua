local local_class = newclass('CoopExpeditionBattle1At1Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320010001
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
	local flower_girl = get_character('npc_bari')

	-- 1초 간 circle fade out
	music_player_util.play_stage_music({ state = 'muted', mix = 6 })
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 리더 죽어 있는 상태라면 살림
	if leader.CharacterStatsBehaviour.IsDead then
		self:revive_character(leader)
	end

	-- 바리 꽃 생성
	local hair_pin_item = drop_item_util.create_item({
		pos = field_util.get_marker_pos('coop_expedition_1_narrative_item'),
		itemid = 21141,
		notforinven = true,
		lootstate = 'dontfindlooter'
	})

	-- 해당 마커 위치에 매뉴얼 캐릭터 위치시킴
	-- 마커 : coop_expedition_1_narrative_manual
	local leader_pos = field_util.get_marker_pos('coop_expedition_1_narrative_manual')

	character_util.hide_weapon(leader, true)
	character_util.remove_anim_and_emotion(leader)
	character_util.set_direction(leader, 'right')
	character_util.set_position(leader, leader_pos)

	wait_for_sec(1)

	local move_end_key = 'move_end'

	-- 1초 간 circle fade in 과 동시에 아래 emotion으로 좌에서 우측으로 5칸 이동
	wp_util.move_with_end_callback(flower_girl, flower_girl.Position + vector(7, 0, 0), 4
	, nil, self, move_end_key)
	wp_util.move_with_end_callback(leader, leader.Position + vector(7, 0, 0), 4
	, nil, self, move_end_key)
	coroutine.yield(nil)

	local amb_sfx = music_player_util.play_sfx({ sfx_name = '01_amb_ship_01', loop = true, fade_in_time = 4 })
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	-- 이동 완료 대기
	wp_util.wait_move_end(self, move_end_key)

	-- 매뉴얼 캐릭터(right, surprised, idle)
	character_util.set_group_emotion({ leader, flower_girl }, { name = 'surprise' })

	-- 바리(right, surprised, jump 1회)
	-- emoticon bubble : emoticon_bubble_exclamation
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.normal_jump(flower_girl, '01_small_jump_01')
	character_util.show_emoticon_async(flower_girl, nil, 'notice')

	wp_util.move_with_end_callback(leader, leader.Position + vector(3, 0, 0), 4
	, nil, self, move_end_key)
	wp_util.move_with_end_callback(flower_girl, flower_girl.Position + vector(4, 0, 0), 7
	, nil, self, move_end_key, { run = true, play_sfx = true, last_direction = 'up'
			, end_callback = function()
					music_player_util.play_sfx_one_shot('01_swing_01')
				end })

	-- 이동을 시작한 지 0.25초 뒤, 1초 간 circle fade out
	wait_for_sec(0.25)

	amb_sfx:FadeOut(3)

	-- 1초 간 circle fade out
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 머리핀 제거
	hair_pin_item:ConsumeComplete()

	-- 이동 대기
	wp_util.wait_move_end(self, move_end_key)

	-- 카메라 화면 밖으로 보냄
	camera_util.move_async(vector(3000, 0, 3000), 0)
	wait_for_sec(0.5)

	-- 클리어 UI 보여야해서 fade in
	screen_util.fade_in_async(0, unity_class.color.black, 'linear')

	amb_sfx = nil

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
