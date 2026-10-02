local local_class = newclass("CoopBossSelector")

function local_class:init(cs_controller, scene)
	self.cs_controller = cs_controller
	if scene ~= nil then
		self.scene = scene()
	end

	self.resource_holder = CS.Foundations.ResourceHolder()

	self.boss_list = {}
	self.boss_id_list = {}

	self.current_boss_id = nil
	self.current_boss = nil
	self.phase_count = nil

	self.is_coop_end = false
end

function local_class:on_load_resource_routine(params)
	message_system:Subscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent), 'on_fo_destroyed_event')
	message_system:Subscribe(self, typeof(CS.Oak.CoopEndEvent), 'on_coop_end_event')
	message_system:Subscribe(self, typeof(CS.Oak.MostAggroChangedEvent), 'on_target_change_event')

	self.boss_id_list = params.bosses

	self.top_hp_bar = CS.Oak.UI.CoopExpeditionBossHpBar.Instance

	self.camera_size = params.camera_size
	self.camera_magnitude = params.camera_magnitude
	self.camera_magnitude1 = params.camera_magnitude1
	self.camera_duration = params.camera_duration
	self.shake_time = params.shake_time
	self.camera_zoom_size = params.camera_zoom_size

	self.knockback_time = params.knockback_time
	self.knockback_force = params.knockback_force

	self.reset_duration = params.reset_duration

	self.fx_teleport = unity_object_pool.GetOrCreate(params.fx_teleport)
	self.fx_teleport_end = unity_object_pool.GetOrCreate(params.fx_teleport_end)
	self.fx_phase2_phase_shift = unity_object_pool.GetOrCreate(params.fx_phase2_phase_shift)
	self.fx_phase2_shout = unity_object_pool.GetOrCreate(params.fx_phase2_shout)

	-- 라이트 변경
	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create(params.visual_template))

	-- sfx
	self.sfx_appear_1 = '02_bossselecter_intro_01'
	music_player:PreloadSfx(self.sfx_appear_1)

	self.sfx_phase_shift = '02_bossselecter_2nd_phase_01'
	music_player:PreloadSfx(self.sfx_phase_shift)

	self.sfx_phase_shift_2 = '02_bossselecter_2nd_phase_02'
	music_player:PreloadSfx(self.sfx_phase_shift_2)

	self.sfx_dead_2 = '02_bossselecter_dead_01'
	music_player:PreloadSfx(self.sfx_dead_2)

	self.dissolver = get_or_create_global_table('utils/SpineCharacterDissolver')

	self.dissolver:load_async('ondemand/coop_expedition/boss_yaksha',
			'fx_oni_phase2_character_dissolver')
end

function local_class:pre_launch_routine()
	user_party:StopAndDisableControl()

	local monsters = character_manager:GetAllMonsters()
	for i, boss_id in pairs(self.boss_id_list) do
		for _, monster in pairs(monsters) do
			if boss_id == monster.CharacterStatsBehaviour.CharacterSpec.Id then
				self.boss_list[boss_id] = monster
				character_util.set_active_state(monster, 'disabled')
				local spawn_marker = field:GetMarker('boss_Spawn_' .. i)
				character_util.set_position(monster, spawn_marker.position)

				-- 본래 사망 에니메이션은 side로 작업해야 한다. 일단 사파식으로
				monster.DamagedBehaviour.DeathType = CS.Oak.DeathType.None
			end
		end
	end
	-- 승리사운드 / 보이스 제거
	stage.BattleManager.PlayBattleVoiceAndFanfare = false
	-- 종료 연출 제거
	stage.BattleManager.PlayBattleEndEffect = false

	--- bgm 꺼버림
	music_player_util.change_stage_music_volume('field', 0, 0)

	self:set_boss_phase(1)

	--- appear 애니메이션
	character_util.set_anim(self.current_boss, { name = 'appear', loop = false })

	--- 등장 사운드
	music_player_util.play_sfx({ sfx_name = self.sfx_appear_1, type_priority = 'event', player_priority = 'boss' })
end

function local_class:on_launch_routine()

	wait_for_sec(1.5)

	if self.is_coop_end then return	end

	character_util.remove_anim(self.current_boss)
	character_util.set_anim(self.current_boss, { name = 'idle' })

	local target = self:get_target()
	if target ~= nil then
		command_util.publish_monster_notice(self.current_boss, target, 'battle')
	end
end

function local_class:post_launch_routine()
	character_util.remove_anim(self.current_boss)

	music_player_util.change_stage_music_volume('field', 1)
	self:set_hp_bar()
	user_party:ResetControllers()

	local boss = stage:GetCharacter('boss_phase1')
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'generate_npc'
	}))
end

function local_class:phase_change()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.phase_change_routine, self))
end

function local_class:phase_change_routine()
	-- 전투 종료 이벤트 처리 대기
	coroutine.yield(nil)

	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, {
		'change_boss',
		'boss_phase_2'
	}))

	coroutine.yield(nil)

	local spawn_marker = field:GetMarker('boss_Spawn_' .. self.phase_count)

	--- 애니메이션 지움
	character_util.remove_anim(self.current_boss)

	user_party:StopAndDisableControl()

	stage.ProjectileManager:ClearProjectiles()
	stage.AreaOfEffectManager:ClearAllAoe()
	for _, c in pairs(party_manager.UserParty) do
		local model = CS.Oak.CoopClient.Instance.CoopModel
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, c)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) and not c.FieldObjectStatsBehaviour.IsDead then
			c.CharacterBehaviour:CancelAllBattleActions(true)
		end
	end

	character_util.set_direction(self.current_boss, 'right')

	music_player_util.change_stage_music_volume('field', 0)

	character_util.set_anim(self.current_boss, { name = 'groggy_start', loop = false, next_anim = 'groggy', scale = 0.8})

	--- 등장 사운드
	music_player_util.play_sfx({ sfx_name = self.sfx_phase_shift, type_priority = 'event', player_priority = 'boss' })

	if self.is_coop_end then return	end

	wait_for_sec(0.9)

	--- 1초 ~ 2초
	--- dead 상태의 보스를 텔레포트 이펙트를 출력하며 삭제
	local phase_effect_pos = self.current_boss.Bounds.center
	self.fx_teleport:Instantiate(phase_effect_pos + vector(2.8, 0, -2))

	wait_for_sec(0.1)

	--- 숨김
	character_util.spine_set_alpha_fade(self.current_boss, 0, 0)

	wait_for_sec(0.2)

	--- 1.5초 ~ 2.5초
	--- 카메라를 맵 중앙으로 변경
	--- 카메라 줌아웃 = 8.5 → 9.5
	camera_util.move(spawn_marker.position, 0.5)
	camera_util.resize_to(9.5, 1)

	wait_for_sec(0.3)

	--- 2초 ~ 3초
	--- leap_loop (scale = 0.35) 상태의 보스를 텔레포트 이펙트를 출력하며 맵 중앙에 소환
	self.fx_teleport_end:Instantiate(spawn_marker.position)

	--- 보스 다시 켜줌
	character_util.spine_set_alpha_fade(self.current_boss, 1, 0)
	character_util.set_position(self.current_boss, spawn_marker.position)
	character_util.set_direction(self.current_boss, 'down')
	character_util.set_anim(self.current_boss, { name = 'appear_phase_shift', loop = false, scale = 0.7, next_anim = 'idle'})

	wait_for_sec(1)
	if self.is_coop_end then return	end

	--- 3초 ~ 4초
	--- 보스 위치로 카메라 줌인 = 9.5 → 6
	camera_util.resize_to(6, 0.5)

	--- 등장 사운드
	music_player_util.play_sfx({ sfx_name = self.sfx_phase_shift_2, type_priority = 'event', player_priority = 'boss' })

	self.fx_phase2_phase_shift:Instantiate(vector(0, 0, 0))

	wait_for_sec(2)

	--- 이때 보스 완전 제거
	character_util.set_active_state(self.current_boss, 'disabled')
	character_util.remove_anim(self.current_boss)

	--- 이때 보스 페이즈 전환
	self:set_boss_phase(self.phase_count + 1)

	--- 유저 캐릭터들 다시 재배치
	self:set_character_pos_phase_2()

	--- 카메라 위치 세팅
	camera_util.move(spawn_marker.position + vector(0, 0, 7), 0)

	--- 미리 눈 애니메이션 시작
	character_util.set_emotion(self.current_boss, { name = 'eye_ready_loop', loop = false })

	if self.is_coop_end then return	end

	wait_for_sec(1)

	--- 페이드 아웃 처리
	camera_util.resize_to(8.5, 1)

	wait_for_sec(0.5)

	--- 감정표현 : [emo]eye_phase_shift 출력
	self.current_boss:SetEmotion(CS.Oak.AnimationRequest('eye_phase_shift', CS.Oak.AnimationPriorities.Custom, true, 0.75))

	wait_for_sec(1.5)
	if self.is_coop_end then return	end

	--- 보스가 포효 애니메이션을 출력
	--- 포효 애니메이션에 맞춰서 카메라 쉐이크
	--- 스테이지 카메라를 원래 값으로 줌아웃
	--- 파티원 전체 맵 바깥쪽으로 넉백
	character_util.set_anim(self.current_boss, { name = 'phase_shift', loop = false, scale = 1.2})
	character_util.remove_emotion(self.current_boss)

	wait_for_sec(0.4)

	self.fx_phase2_shout:Instantiate(self.current_boss.Position + vector(0, 7, 0))
	camera_util.shake(1.4, 0.8)

	--- 모든 아군 넉백 연출
	self:publish_knockback()

	wait_for_sec(1.1)

	if self.is_coop_end then return	end

	character_util.remove_anim(self.current_boss)

	local my_char = CS.Oak.CoopClient.Instance.MyCharacter
	camera_util.move_async(my_char.Position, self.reset_duration, {end_target = my_char})
	camera_util.resize_to_default(self.reset_duration)

	music_player_util.change_stage_music_volume('field', 1)

	self:set_hp_bar()
	self:reset_controllers()

	-- 너무 바로 시작하니 약간 텀 주자
	wait_for_sec(0.1)

	music_player_util.change_stage_music_volume('field', 1)

	if self.is_coop_end then return	end

	local target = self.most_aggro_fo
	local model = CS.Oak.CoopClient.Instance.CoopModel
	local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, target)
	-- GT-2333 방어, 소환수가 타겟이라면 예외처리
	local is_summon = lua_helper.type_compare(target, CS.Oak.OptionCharacter)
	if (slot_id == -1 or CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) == false or is_summon)  or target == nil or target.FieldObjectStatsBehaviour.IsDead then
		target = self:get_target()
	end

	command_util.publish_monster_notice(self.current_boss, target, 'battle')
end

function local_class:publish_knockback()
	for _, c in pairs(party_manager.UserParty) do
		local model = CS.Oak.CoopClient.Instance.CoopModel
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, c)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) then
			local knockback_info = character_util.knockback_info('physics', true, {0, 0, -1},
					15000, 0.05, CS.Oak.Constants.DefaultFrictionCoefficient)
			command_util.publish_knock_back(c.Owner, c, knockback_info, c.Position)
		end
	end
end

function local_class:reset_controllers()
	user_party:ResetControllers()

	for _, c in pairs(party_manager.UserParty) do
		local model = CS.Oak.CoopClient.Instance.CoopModel
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, c)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id)
				and c.FieldObjectStatsBehaviour.IsDead and CS.Oak.IFieldObjectExtensions.IsManualLocal(c) then
			message_system:SendSync(c.FieldObjectController,
					CS.Oak.StateChangeEvent.Create(
							CS.Oak.ManualTouchRaidCoffinControllerState.Create(c, CS.Oak.FieldUiType.DPad | CS.Oak.FieldUiType.ActionButton)))
			message_system:SendSync(c.CharacterBehaviour,
					CS.Oak.StateChangeEvent.Create(CS.Oak.CharacterAnalogueState.Create(c)))
		end
	end
end

function local_class:set_character_pos_phase_2()
	for _, c in pairs(party_manager.UserParty) do
		local model = CS.Oak.CoopClient.Instance.CoopModel
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, c)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) then
			local marker = field:GetMarker('spawn_p2_' .. slot_id);
			character_util.set_position(c, marker.position)
			character_util.set_direction(c, marker.direction)
		end
	end
end

function local_class:get_target()
	local target, lowest_num
	for _, c in pairs(party_manager.UserParty) do
		local model = CS.Oak.CoopClient.Instance.CoopModel
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, c)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) and c.FieldObjectStatsBehaviour.IsDead == false then
			if lowest_num == nil or lowest_num > slot_id then
				lowest_num = slot_id
				target = c
			end
		end
	end

	return target
end

function local_class:set_boss_phase(phase_count)
	if self.phase_count ~= nil and self.phase_count >= phase_count then
		return
	end

	self.phase_count = phase_count

	self.current_boss_id = self.boss_id_list[phase_count]
	self.current_boss = self.boss_list[self.current_boss_id]

	-- 혹시 모르니 다시 한번 위치 셋
	local spawn_marker = field:GetMarker('boss_Spawn_' .. self.phase_count)
	character_util.set_position(self.current_boss, spawn_marker.position)
	character_util.set_direction(self.current_boss, spawn_marker.direction)
	character_util.set_active_state(self.current_boss, 'enabled')
end

function local_class:set_hp_bar()
	self.top_hp_bar:Init(self.current_boss)
	self.top_hp_bar:Show()
end

function local_class:boss_dying_ani()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.boss_dying_ani_routine, self))
end

function local_class:boss_dying_ani_routine()
	if self.current_boss.Direction == CS.Oak.Direction.Up then
		character_util.set_direction(self.current_boss, 'right')
	elseif self.current_boss.Direction == CS.Oak.Direction.Down then
		character_util.set_direction(self.current_boss, 'left')
	end

	character_util.set_anim(self.current_boss, { name = 'groggy_start', scale = 0.66, loop = false, next_anim = 'groggy_loop' })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead_2, type_priority = 'event', player_priority = 'boss' })

	wait_for_sec(1.3)

	self.dissolver:set_dissolve_material(self.current_boss)
	self.current_boss.SpineController:AddColor('dissolve', unity_class.color.black, 1, 0)

	local time_passed = 0
	while time_passed < 1.1 do
		time_passed = time_passed + unity_class.time.deltaTime
		self.dissolver:set_dissolve_progress(self.current_boss, time_passed / 0.8)
		coroutine.yield(nil)
	end

	wait_for_sec(1.3)

	message_system:Publish(CS.Oak.DyingEndEvent.Create(self.current_boss))
end

function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.current_boss) then
		self.top_hp_bar:Hide()

		if self.phase_count < #self.boss_id_list then
			self:phase_change()
		elseif self.phase_count == #self.boss_id_list then
			self:boss_dying_ani()
		end
	end
end

function local_class:on_coop_end_event(e)
	if self.top_hp_bar ~= nil then
		self.top_hp_bar:Hide()
	end

	self.is_coop_end = true

	if self.snow_sfx then
		self.snow_sfx:FadeOut(3)
	end
end

function local_class:on_target_change_event(e)
	if lua_helper.reference_equals(e.Subject, self.current_boss) == false then
		return
	end

	self.most_aggro_fo = e.Target
end

function local_class:dispose()
	-- 이벤트 리스너 해제
	message_system:Unsubscribe(self, typeof(CS.Oak.FieldObjectDestroyedEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.CoopEndEvent))
	message_system:Unsubscribe(self, typeof(CS.Oak.MostAggroChangedEvent))

	self.snow_sfx = nil

	self.fx_teleport = nil
	self.fx_teleport_end = nil
	self.fx_phase2_phase_shift = nil
	self.fx_phase2_shout = nil

	-- 승리사운드 / 보이스 복구
	stage.BattleManager.PlayBattleVoiceAndFanfare = true
	-- 종료 연출 복구
	stage.BattleManager.PlayBattleEndEffect = true

	self.cs_controller = nil
end

return {
	create = function(cs_controller, scene)
		return local_class(cs_controller, scene);
	end
}
