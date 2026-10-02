local local_class = newclass('CoopExpeditionBattle3At1Controller')

function local_class:init(cs_controller, _)
	self.cs_controller = cs_controller

	-- scene_util 버전. 버전 올라갈 때 + N 해서 사용
	self.scene_version = scene_util.default_version

	-- 스테이지 id
	self.stage_id = 320030001

	self.nowhere = vector(999,0,999)

	-- 동적 npc
	self.co_exp_season2_npc_key = 'co_exp_season2_npc_'
	self.dynamic_npc = setmetatable({
		key = self.co_exp_season2_npc_key,
		count = 8,
		container = nil,
		specs = {
			[self.co_exp_season2_npc_key .. 1] = 'co_exp_season2_miya',
			[self.co_exp_season2_npc_key .. 2] = 'co_exp_season2_tasha',
			[self.co_exp_season2_npc_key .. 3] = 'co_exp_season2_tasha_spirit',
			[self.co_exp_season2_npc_key .. 4] = 'co_exp_season2_shaman_male',
			[self.co_exp_season2_npc_key .. 5] = 'co_exp_season2_shaman_male',
			[self.co_exp_season2_npc_key .. 6] = 'co_exp_season2_shaman_male',
			[self.co_exp_season2_npc_key .. 7] = 'co_exp_season2_shaman_female',
			[self.co_exp_season2_npc_key .. 8] = 'co_exp_season2_shaman_female'
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

	self.fx = setmetatable({
		shockwave = function()
			return unity_object_pool.GetOrCreate('FX_shockwave')
		end
	}, {
		__index = {
			create_all = function(this)
				for _, func in pairs(this) do
					func()
				end
			end
		}
	})
end

function local_class:load_resource()
	message_system:Subscribe(self, typeof(CS.Oak.CoopExpeditionIngameSequenceStartEvent), 'on_coop_ex_sequence_start_event')

	self.fx:create_all()
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

	if self.dynamic_npc ~= nil then
		self.dynamic_npc:dispose()
		self.dynamic_npc = nil
	end

	self.cs_controller = nil
	self.scene = nil
end

function local_class:start_first_clear_event()
	sp_util.enter_scene({wait_alive = false})
	local player = get_party_leader()

	screen_util.fade_out_async(1, unity_class.color.black, 'linear')

	-- 리더 죽어 있는 상태라면 살림
	if player.CharacterStatsBehaviour.IsDead then
		self:revive_character(player)
	end

	self.dynamic_npc:load_async()

	local miya = self.dynamic_npc.container[self.co_exp_season2_npc_key .. 1]
	local tasha = self.dynamic_npc.container[self.co_exp_season2_npc_key .. 2]
	local spirit = self.dynamic_npc.container[self.co_exp_season2_npc_key .. 3]

	local pivot = field_util.get_marker_pos('clear_scene_pivot')

	local set_table = {
		player = {
			offset = vector(2.5, 0, -0.5),
			dir = 'left'
		},
		miya = {
			offset = vector(2.5, 0, 0.5),
			dir = 'left'
		},
		[self.co_exp_season2_npc_key .. 4] = {
			offset = vector(-1.5, 0, 0),
			dir = 'right'
		},
		[self.co_exp_season2_npc_key .. 5] = {
			offset = vector(-3.5, 0, 0.5),
			dir = 'right'
		},
		[self.co_exp_season2_npc_key .. 6] = {
			offset = vector(-2, 0, -1.5),
			dir = 'right'
		},
		[self.co_exp_season2_npc_key .. 7] = {
			offset = vector(-2, 0, 1.5),
			dir = 'right'
		},
		[self.co_exp_season2_npc_key .. 8] = {
			offset = vector(-3.5, 0, -1),
			dir = 'right'
		}
	}

	local function npc_action_table(npc_table, func)
		for index = 4, npc_table.count do
			local npc = self.dynamic_npc.container[self.co_exp_season2_npc_key .. index]

			func(npc)
		end
	end

	--※ 1스테이지 클리어 이후, 초회 보상을 받지 않은 유저에 한해 플레이어 캐릭터를 상단의 이미지 위치로 이동시키고, 플레이어 캐릭터를 중심으로 카메라 변경
	--클리어 직전 플레이어 캐릭터가 사망한 경우라도 리바이브 시킨 뒤 출력
	--
	--최초 NPC는 다음과 같이 배치.
	--미야 (left, idle, idle)
	--플레이어 (left, idle, idle)
	--퇴마사 남자1 (right, idle, prostrate)
	--퇴마사 남자2 (right, idle, prostrate)
	--퇴마사 남자3 (right, idle, prostrate)
	--퇴마사 여자1 (right, idle, prostrate)
	--퇴마사 여자2 (right, idle, prostrate)
	do
		character_util.set_position(player, pivot + set_table.player.offset)
		scene_util.set_direction(player, set_table.player.dir, false)
		character_util.remove_anim_and_emotion(player)

		character_util.set_position(miya, pivot + set_table.miya.offset)
		scene_util.set_direction(miya, set_table.miya.dir, false)
		character_util.remove_anim_and_emotion(miya)

		npc_action_table(self.dynamic_npc, function(npc)
			character_util.remove_anim_and_emotion(npc)
			field_object_util.set_active_state(npc, active_state_type.enabled)

			character_util.set_position(npc, pivot + set_table[npc.name].offset)

			scene_util.set_direction(npc, set_table[npc.name].dir, false)
			scene_util.set_anim(npc, self, 'prostrate')
		end)
	end

	--최초 카메라는 ●지점 포커싱중.
	camera_util.move_async(pivot, 0)

	--최초 Stage Camera 값은 4
	camera_util.resize_to( 4,0)

	--최초 페이드 아웃 된 상태로 1초 대기
	--이후 1초에 걸쳐 화면 일반 페이드 인.
	wait_for_sec(1)

	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

	--대기 0.5초
	wait_for_sec(0.5)

	--남자 1,2,3 여자1,2 NPC들 동시에 (right, idle, prostrate) 자세로 0.03값 shake 0.5초
	--이후 5명 NPC 모두 동시에 (right, idle, idle mix duration 1초)
	do
		npc_action_table(self.dynamic_npc, function(npc)
			scene_util.shake(npc, 0.03, 0.5)
		end)

		wait_for_sec(0.5)

		npc_action_table(self.dynamic_npc, function(npc)
			scene_util.set_anim(npc, self, { name = 'idle', mix_duration = 1 })
		end)

		wait_for_sec(0.6)
	end

	--idle mix duration 한지 0.6초가 지났을 때 미야, 플레이어 동시에 (left, attack, idle 자세로 jump 1회)
	scene_util.set_emotion(player, self, 'attack')
	scene_util.set_emotion(miya, self, 'attack')

	character_util.normal_jump(player, '01_jump_01')
	character_util.normal_jump_async(miya, '01_jump_01')

	--idle mix duration 이 끝난 이후 0.7초 대기 이후 하단의 이벤트 진행.
	wait_for_sec(0.7)

	npc_action_table(self.dynamic_npc, function(npc)
		character_util.remove_anim_and_emotion(npc)
	end)

	--미야 (left, attack, idle) : $name님…! 이 사람들은 모두 죽어있는 상태로 조종 당하고 있어요.
	scene_util.play_normal_speech_action(
			miya,
			self,
			nil,
			nil,
			nil,
			'co_exp_season2_s1_ending_1'
	)

	--미야 (left, attack, idle) : 분명 시신을 조종하는 괴뢰술은 금지되어있을텐데…!
	scene_util.play_normal_speech_action(
			miya,
			self,
			nil,
			nil,
			nil,
			'co_exp_season2_s1_ending_2'
	)

	--1초에 걸쳐 Stage Camera 값 3으로 줌인 하는 동시에,
	--남자1,2,3 여자1,2 NPC 5명 모두 이동속도 값 1로 right 방향 0.5칸 이동 후 0.8초 대기
	do
		camera_util.resize_to(3, 1)

		local move_diff = unity_class.vector3.right * 0.5
		local move_key = 'npc_move_wait'

		npc_action_table(self.dynamic_npc, function(npc)
			wp_util.move_with_end_callback(
					npc,
					npc.Position + move_diff,
					1,
					nil,
					self,
					move_key
			)
		end)

		wp_util.wait_move_end(self, move_key)

		wait_for_sec(0.8)
	end


	--남자1,2,3 여자1,2 NPC 5명 모두 이동속도 값 1로 right 방향 0.5칸 이동.
	do
		local move_diff = unity_class.vector3.right * 0.5
		local move_key = 'npc_move_wait'

		npc_action_table(self.dynamic_npc, function(npc)
			wp_util.move_with_end_callback(
					npc,
					npc.Position + move_diff,
					1,
					nil,
					self,
					move_key
			)
		end)

		wp_util.wait_move_end(self, move_key)
	end

	--NPC 5명이 이동을 완료한 이후에, ■타일 지점에서 공중(y값 7)에서 타샤의 소환수 npc 생성한 뒤 0.2초에 걸쳐 타샤의 소환수 (left, idle, idle) 자세로 떨어짐.
	--소환수가 바닥에 착지하는 동시에 fx_shockwave 이펙트 출력되며 카메라 0.3값으로 0.5초 shake.
	do
		local pos = pivot + vector(1, 7, 0)

		character_util.set_position(spirit, pos)
		scene_util.set_direction(spirit, 'left', false)
		field_object_util.set_active_state(spirit, active_state_type.enabled)

		scene_util.set_anim(spirit, self, 'idle')

		local move_diff = vector(0, 7, 0)
		wp_util.move_async(spirit, pos - move_diff, nil, 0.2, { locked_dir = 'left' })

		character_util.remove_anim_and_emotion(spirit)

		camera_util.shake(0.3, 0.5)
		self.fx.shockwave():Instantiate(spirit.Position)
		music_player_util.play_sfx_one_shot('02_stomp_01')
	end

	wait_for_sec(0.5)

	--이후 소환수 (left, idle, attack1) 자세와 동시에 미야 NPC와 플레이어 (left, surprise, idle 자세로 jump 1회)
	--와 동시에 플레이어 캐릭터 머리 위에 (notice) 이모티콘 표시.
	music_player_util.play_sfx_one_shot('02_bakeneko_claw_02')
	scene_util.set_anim(spirit, self, {name = 'jade_spirit/attack1', count = 1})

	scene_util.set_emotion(player, self, 'surprise')
	scene_util.set_emotion(miya, self, 'surprise')

	wait_all_lua(
			function()
				character_util.show_emoticon(player, nil, 'notice')
				character_util.show_emoticon_async(miya, nil, 'notice')
			end,
			function()
				music_player_util.play_sfx_one_shot('03_dialogue_notice_01')

				character_util.normal_jump(player, '01_jump_01')
				character_util.normal_jump_async(miya, '01_jump_01')
			end
	)

	--화면에 말풍선 출력 (x : 0.8 / y : 0.5)
	--타샤 : [shout]이쪽이야!
	music_player_util.play_sfx_one_shot('03_dialogue_negative_01')
	scene_util.play_shout_speech_action(
			tasha,
			self,
			nil,
			nil,
			nil,
			{ key = 'co_exp_season2_s1_ending_3', viewport_pos = vector(0.9, 0.5) }
	)

	--미야, 플레이어 캐릭터 둘다 (right, attack, idle) 자세로 전환됨과 동시에 1.5초에 걸쳐 카메라 오른쪽으로 6칸 이동.
	--동시에 타샤 캐릭터가 attack 표정으로 이미지에 표시된 지점에 생성되고 1.5초에 걸쳐 왼쪽으로 6칸 run 자세로 이동.
	do
		local duration = 1.5
		wait_all_lua(
			function()
				scene_util.set_emotion(player, self, 'attack')
				scene_util.set_emotion(miya, self, 'attack')

				scene_util.set_direction(player, 'right', false)
				scene_util.set_direction(miya, 'right', false)

				local pos = pivot + vector(6, 0, 0)
				camera_util.move_async(pos, duration)
			end,
			function()
				local pos = pivot + vector(15, 0, 0)
				local move_diff = vector(-6, 0, 0)

				field_object_util.set_active_state(tasha, active_state_type.enabled)
				character_util.set_position(tasha, pos)
				scene_util.set_emotion(tasha, self, 'attack')

				wait_for_sec(0.1)

				wp_util.move_async(tasha, pos + move_diff, nil, duration, { run = true, play_sfx = true })
			end
		)
	end

	--타샤 (left, attack, idle) : 계속 싸워봤자 힘만 뺄 뿐이야!
	scene_util.play_normal_speech_action(
			tasha,
			self,
			nil,
			nil,
			nil,
			'co_exp_season2_s1_ending_4'
	)

	--타샤 (left, attack, release) : 이 틈에 어서 도망쳐!
	scene_util.play_normal_speech_action(
			tasha,
			self,
			nil,
			'release',
			nil,
			'co_exp_season2_s1_ending_5'
	)

	--타샤 이동속도 6값 run 자세로 right 방향으로 8칸 이동하며 화면에서 사라짐.
	do
		local move_diff = vector(8, 0, 0)

		wp_util.move_async(tasha, tasha.Position + move_diff, 6, nil, { run = true, play_sfx = true })

		character_util.set_position(tasha, self.nowhere)
		field_object_util.set_active_state(tasha, active_state_type.disabled)
	end

	--타샤가 화면에서 사라진 이후, 미야 NPC 는 down 방향 전환하며 동시에 플레이어는 up 방향 전환.
	scene_util.set_direction(miya, 'down')
	scene_util.set_direction(player, 'up')

	--0.5초 대기
	wait_for_sec(0.5)

	--미야 npc와 플레이어 동시에 nod 1회.
	scene_util.set_anim(miya, self, {name = 'nod', count = 1})
	scene_util.set_anim_async(player, self, {name = 'nod', count = 1})

	--0.3초 대기
	wait_for_sec(0.3)

	--미야, 플레이어 동시에 이동속도 6값 run 자세로 right 방향으로 8칸 이동하는 동시에 1초에 걸쳐 화면 일반 페이드 아웃.
	do
		local move_diff = vector(8,0,0)

		wp_util.move(player, player.Position + move_diff, 6,nil, {run = true, play_sfx = true})
		wp_util.move(miya, miya.Position + move_diff, 6, nil, {run = true, play_sfx = true})

		screen_util.fade_out_async(1, unity_class.color.black, 'linear')
	end

	self.dynamic_npc:dispose()
	self.dynamic_npc = nil

	camera_util.set_position(pivot + vector(0,0,-30))
	screen_util.fade_in_async(1, unity_class.color.black, 'linear')

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
