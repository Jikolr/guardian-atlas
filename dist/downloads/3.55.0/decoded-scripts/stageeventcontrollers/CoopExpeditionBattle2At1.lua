local local_class = newclass('CoopExpeditionBattle2At1Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320020001

	-- 동적 npc
	self.civilian_npc_key = 'co_exp_civilian_'
	self.dynamic_npc = setmetatable({
		key = self.civilian_npc_key,
		count = 12,
		container = nil,
		specs = {
			[self.civilian_npc_key .. 1] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 2] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 3] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 4] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 5] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 6] = 'co_exp_season1_civilian_male',
			[self.civilian_npc_key .. 7] = 'co_exp_season1_civilian_female',
			[self.civilian_npc_key .. 8] = 'co_exp_season1_civilian_female',
			[self.civilian_npc_key .. 9] = 'co_exp_season1_civilian_female',
			[self.civilian_npc_key .. 10] = 'co_exp_season1_civilian_female',
			[self.civilian_npc_key .. 11] = 'co_exp_season1_civilian_female',
			[self.civilian_npc_key .. 12] = 'co_exp_season1_civilian_female',
		},
	}, {
		__index = {
			get = function(this, index)
				return this.container[this.key .. index]
			end,
			load_async = function(this)
				if this.container == nil then
					this.container = load_util.create_dynamic_npcs_async(this.specs)
				end
			end,
			dispose = function(this)
				if this.container ~= nil then
					load_util.dispose_dynamic_npcs(this.container)
					this.container = nil
				end
			end,
		}
	})
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

	self.dynamic_npc:dispose()
	self.dynamic_npc = nil

	self.cs_controller = nil
	self.scene = nil
end

function local_class:start_first_clear_event()
	field_ui_manager:Hide()
	party_util.stop_and_disable_control()

	local leader = get_party_leader()
	local miya = get_character('npc_miya')
	local civilian_group = {}
	local leader_pos = field_util.get_marker_pos('coop_expedition_1_narrative_manual')
	local camera_pos = leader_pos + vector(0.5, 0, 0)
	local move_end_key = 'move_end'

	-- 1초 간 circle fade out
	music_player_util.play_stage_music({ state = 'muted', mix = 4 })
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

	-- npc 세팅
	self.dynamic_npc:load_async()

	for i = 1, self.dynamic_npc.count do
		table.insert(civilian_group, self.dynamic_npc:get(i))
	end

	local npc_marker_pre_pix = 'co_exp_civilian_pos_'
	local npc_dir = { 'right', 'left', 'left', 'right', 'right', 'left',
					  'right', 'right', 'left', 'right', 'left', 'left' }

	for i, npc in ipairs(civilian_group) do
		character_util.set_position(npc, field_util.get_marker_pos(npc_marker_pre_pix .. i))
		character_util.set_direction(npc, npc_dir[i])
		character_util.set_anim_and_emotion(npc, { name = 'prostrate' }, { name = 'damaged' })
		character_util.add_color(npc, npc.Name, unity_class.color.black, 0.5, 0)
	end

	wait_for_sec(1)

	--플레이어, 미야 2초동안 walk 자세로 위쪽으로 3칸 이동.
	wp_util.move_with_end_callback(miya, miya.Position + vector(0, 0, 3), nil
	, 2, self, move_end_key)
	wp_util.move_with_end_callback(leader, leader.Position + vector(0, 0, 3), nil
	, 2, self, move_end_key)

	camera_pos = camera_pos + vector(0, 0, 3)
	camera_util.move(camera_pos, 2)

	local wind_sfx = music_player_util.play_sfx({ sfx_name = '01_blizzard_04', loop = true, fade_in_time = 4 })
	--이동을 시작한 동시에 화면 1초동안 일반 페이드 인.
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	wp_util.wait_move_end(self, move_end_key)

	--미야 캐릭터 idle 자세로 jump와 동시에 머리 위에 (notice) 이모티콘 표시.
	music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
	character_util.group_normal_jump({ leader, miya }, '01_jump_01')
	character_util.show_emoticon(leader, nil, 'notice')
	character_util.show_emoticon_async(miya, nil, 'notice')

	--플레이어, 미야 캐릭터 1초동안 run 자세로 위쪽으로 3칸 이동.
	camera_util.move(camera_pos + vector(0, 0, 3), 1)
	wp_util.move_with_end_callback(miya, miya.Position + vector(0, 0, 3), nil
	, 1, self, move_end_key)
	wp_util.move_with_end_callback(leader, leader.Position + vector(0, 0, 3), nil
	, 1, self, move_end_key)

	wp_util.wait_move_end(self, move_end_key)

	--두 캐릭터 이동을 완료한 후 1초에 걸쳐 화면 위쪽으로 2칸 이동.
	do
		local camera_pos = leader.Position + vector(0.5, 0, 2)

		camera_util.move_async(camera_pos, 1)
	end

	--대기 0.5초
	wait_for_sec(0.5)

	--미야 캐릭터 2초에 걸쳐 위쪽으로 2칸 walk 자세로 이동.
	wp_util.move_async(miya, miya.Position + vector(0, 0, 2), nil, 2)

	--0.2초 대기
	wait_for_sec(0.2)

	--미야 캐릭터 up 방향 바라본 채로 0.03값 shake 1초.
	scene_util.shake(miya, 0.03, 2)

	--플레이어 (right, tired, cast) 자세 전환.
	character_util.set_direction(leader, 'right')
	character_util.set_anim_and_emotion(leader, { name = 'cast' }, { name = 'tired' })

	--대기 0.8초
	wait_for_sec(0.8)

	--1초에 걸쳐 화면 일반 페이드 아웃.
	music_player_util.fade_out_sfx(wind_sfx, 3)
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

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
