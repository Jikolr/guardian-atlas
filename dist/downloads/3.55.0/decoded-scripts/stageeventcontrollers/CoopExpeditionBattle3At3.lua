local local_class = newclass('CoopExpeditionBattle3At3Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320030003

	-- 동적 npc
	self.co_exp_season2_npc_key = 'co_exp_season2_'
	self.dynamic_npc = setmetatable({
		key = self.civilian_npc_key,
		count = 2,
		container = nil,
		specs = {
			[self.co_exp_season2_npc_key .. 1] = 'co_exp_season2_miya',
			[self.co_exp_season2_npc_key .. 2] = 'co_exp_season2_tasha',
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
	sp_util.enter_scene({wait_alive = false})
	local player = get_party_leader()

	music_player_util.play_stage_music({ state = 'muted', mix = 6})

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 리더 죽어 있는 상태라면 살림
	if player.CharacterStatsBehaviour.IsDead then
		self:revive_character(player)
	end

	self.dynamic_npc:load_async()

	local miya = self.dynamic_npc.container[self.co_exp_season2_npc_key .. 1]
	local tasha = self.dynamic_npc.container[self.co_exp_season2_npc_key .. 2]

	local pivot = field_util.get_marker_pos('clear_scene_pivot')

	local set_table = {
		player = {
			offset = vector(-0.5, 0, 0.5),
		},
		miya = {
			offset = vector(0, 0, -0.5),
		},
		tasha = {
			offset = vector(0.5,0,0.5)
		}
	}

	--최초 NPC는 다음과 같이 배치.
	--미야 (up, idle, idle)
	--타샤 (up, idle, idle)
	--플레이어 (up, idle, idle)
	do
		character_util.set_position(player, pivot + set_table.player.offset)
		scene_util.set_direction(player, 'up', false)
		character_util.remove_anim_and_emotion(player)

		character_util.set_position(miya, pivot + set_table.miya.offset)
		scene_util.set_direction(miya, 'up', false)
		character_util.remove_anim_and_emotion(miya)

		character_util.set_position(tasha, pivot + set_table.tasha.offset)
		scene_util.set_direction(tasha, 'up', false)
		character_util.remove_anim_and_emotion(tasha)
	end

	--최초 카메라는 ●지점 포커싱중.
	camera_util.set_position(pivot)

	wait_for_sec(1)

	--플레이어, 타샤, 미야 2.5초동안 run 자세로 위쪽으로 11칸 이동, 동시에 화면도 2.5초동안 위쪽으로 11칸 이동.
	do
		local duration = 2.5
		local move_diff = vector(0,0,11)

		camera_util.move(pivot + move_diff, duration)

		wp_util.move(player, player.Position + move_diff, nil, duration, {run = true, play_sfx = true})
		wp_util.move(miya, miya.Position + move_diff, nil, duration, {run = true, play_sfx = true})
		wp_util.move(tasha, tasha.Position + move_diff, nil, duration, {run = true, play_sfx = true})
	end

	camera_util.resize_to(5, 0)

	wait_for_sec(0.5)

	--이동을 시작한 동시에 화면 1초동안 일반 페이드 인.
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	wait_for_sec(1)

	--플레이어, 미야, 타샤 캐릭터 idle 자세로 jump와 동시에 플레이어 머리 위에만 (notice) 이모티콘 표시.
	wait_all_lua(
			function()
				character_util.normal_jump(player, '01_jump_01')
				character_util.normal_jump(miya, '01_jump_01')
				character_util.normal_jump_async(tasha, '01_jump_01')
			end,
			function()
				music_player_util.play_sfx_one_shot('03_dialogue_notice_01')
				character_util.show_emoticon_async(player, nil, 'notice')
			end
	)

	--화면 1.5초에 걸쳐 위쪽으로 3칸 이동.
	do
		local pos = miya.Position + vector(0,0,3.5)

		camera_util.move_async(pos, 1.5)
	end

	--대기 0.5초
	wait_for_sec(0.5)

	--[gimmick]season1_in_big_entrance 오브젝트의 [gimmick]big_entrance 애니메이션 출력
	local animator = get_field_object('big_door_1'):GetComponent(typeof(CS.UnityEngine.Animator))

	music_player_util.play_sfx_one_shot('02_magic_change_01')
	music_player_util.play_sfx_one_shot('01_impact_02')

	animator:Play('big_open')

	wait_for_sec(0.5)

	music_player_util.play_sfx_one_shot('01_gate_open_01')

	wait_for_sec(2.5)

	--거대한 문 열리는 애니메이션이 완료된 후

	--플레이어, 미야, 타샤 2초에 걸쳐 walk 자세로 위쪽으로 3칸 이동.
	do
		local move_diff = vector(0,0,3.5)
		local duration = 2.5

		wp_util.move(player, player.Position + move_diff, nil, duration)
		wp_util.move(miya, miya.Position + move_diff, nil, duration)
		wp_util.move(tasha, tasha.Position + move_diff, nil, duration)
	end

	wait_for_sec(1)

	--위쪽으로 2칸 이동했을 때 0.5초에 걸쳐 세 캐릭터의 알파값 0으로 페이드 아웃.
	do
		local duration = 1

		character_util.spine_set_alpha_fade_v2(player, 0, duration)
		character_util.spine_set_alpha_fade_v2(miya, 0, duration)
		character_util.spine_set_alpha_fade_v2(tasha, 0, duration)

		wait_for_sec(duration)
	end

	--플레이어, 미야, 타샤 캐릭터 페이드 아웃 완료된 후 0.6초 대기
	wait_for_sec(0.6)

	--화면 1초에 걸쳐 일반 페이드 아웃.
	screen_util.fade_out_async(1, unity_class.color.black, 'linear')


	camera_util.set_position(pivot + vector(-40,0,0))

	--결과창 출력
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

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
