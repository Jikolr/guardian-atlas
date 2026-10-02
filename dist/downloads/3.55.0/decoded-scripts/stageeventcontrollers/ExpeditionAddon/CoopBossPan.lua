local local_class = newclass("CoopBossPan")

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
	self.camera_duration = params.camera_duration
	self.shake_time = params.shake_time

	self.knockback_time = params.knockback_time
	self.knockback_force = params.knockback_force

	self.reset_duration = params.reset_duration

	self.fx_npc_appear_pool = unity_object_pool.GetOrCreate(params.fx_npc_appear_name)
	self.fx_pan_appear_pool = unity_object_pool.GetOrCreate(params.fx_pan_appear)

	-- sfx
	self.sfx_appear_1 = '01_rustle_02'
	music_player:PreloadSfx(self.sfx_appear)

	self.sfx_dead = '01_trip_02'
	music_player:PreloadSfx(self.sfx_dead)

	self.sfx_appear_2_1 = '02_pan_boss_event_01'
	music_player:PreloadSfx(self.sfx_appear_2_1)

	self.sfx_appear_2_2 = '02_pan_boss_event_02'
	music_player:PreloadSfx(self.sfx_appear_2_2)

	self.sfx_dead_2 = '02_pan_boss_event_03'
	music_player:PreloadSfx(self.sfx_dead_2)
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

	self:set_boss_phase(1)
	character_util.set_anim(self.current_boss, { name = 'appear_loop', loop = true })
end

function local_class:on_launch_routine()
	character_util.remove_anim(self.current_boss)
	character_util.set_anim(self.current_boss, { name = 'appear', loop = false })
	music_player_util.play_sfx({ sfx_name = self.sfx_appear_1 })

	local fx_npc_pos = field:GetMarker('npc_spawn_0').position
	object_pool_extensions.Instantiate(self.fx_npc_appear_pool, fx_npc_pos)
	wait_for_sec(2.0)

	if self.is_coop_end then return	end

	character_util.remove_anim(self.current_boss)
	character_util.set_anim(self.current_boss, { name = 'idle' })

	local target = self:get_target()
	if target ~= nil then
		message_system:Publish(CS.Oak.MonsterNoticeEvent.Create(self.current_boss, target, CS.Oak.MonsterNoticeLevel.Battle))
	end
end

function local_class:post_launch_routine()
	character_util.remove_anim(self.current_boss)

	self:set_hp_bar()
	user_party:ResetControllers()

	local boss = stage:GetCharacter('boss_phase1')
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'activate_auto_generate'
	}))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'generate_npc'
	}))
end

function local_class:phase_change()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.phase_change_routine, self))
end

function local_class:phase_change_routine()
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

	character_util.set_direction(self.current_boss, 'down')
	character_util.set_anim(self.current_boss, { name = 'dead', loop = false })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead })
	wait_for_sec(1.0)

	if self.is_coop_end then return	end

	screen_util.fade_out_async(1.0, unity_class.color.black, 'linear')
	wait_for_sec(1.0)

	if self.is_coop_end then return	end

	character_util.set_active_state(self.current_boss, 'disabled')
	character_util.remove_anim(self.current_boss)

	self:set_boss_phase(self.phase_count + 1)
	self:set_character_pos_phase_2()

	-- 카메라 size, target 변경
	camera_util.move(self.current_boss.Position, 0)
	camera_util.resize_to(self.camera_size, 0)

	screen_util.fade_in_async(1.0, unity_class.color.black, 'linear')
	wait_for_sec(1.0)

	if self.is_coop_end then return	end

	-- 이후 연출 총 3초 정도
	local total_act_time = 3.0
	local remain_act_time = total_act_time

	character_util.set_anim(self.current_boss, { name = 'appear', loop = false })
	object_pool_extensions.Instantiate(self.fx_pan_appear_pool, self.current_boss.Bounds.center)
	music_player_util.play_sfx({ sfx_name = self.sfx_appear_2_1 })

	wait_for_sec(self.shake_time)
	remain_act_time = remain_act_time - self.shake_time
	camera_util.shake(self.camera_magnitude, self.camera_duration)

	if self.is_coop_end then return	end

	wait_for_sec(self.knockback_time)
	remain_act_time = remain_act_time - self.knockback_time

	--- 모든 아군 넉백 연출
	local knock_back_routines = {}
	local model = CS.Oak.CoopClient.Instance.CoopModel
	for _, member in pairs(party_manager.UserParty) do
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, member)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) then
			table.insert(knock_back_routines, character_util.physics_knock_back_routine(member, vector(0, 0, -1), 15000, 0.05))
		end
	end

	music_player_util.play_sfx({ sfx_name = self.sfx_appear_2_2 })

	if self.is_coop_end then return	end

	--- 아군 넉백 연출이 끝날 때 까지 기다린다.
	wait_all(knock_back_routines)

	if self.is_coop_end then return	end

	character_util.remove_anim(self.current_boss)

	local my_char = CS.Oak.CoopClient.Instance.MyCharacter
	camera_util.move_async(my_char.Position, self.reset_duration, {end_target = my_char})
	camera_util.resize_to_default(self.reset_duration)

	self:set_hp_bar()
	self:reset_controllers()

	-- 너무 바로 시작하니 약간 텀 주자
	wait_for_sec(0.1)

	if self.is_coop_end then return	end

	local target = self.most_aggro_fo
	local model = CS.Oak.CoopClient.Instance.CoopModel
	local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, target)
	-- GT-2333 방어, 소환수가 타겟이라면 예외처리
	local is_summon = lua_helper.type_compare(target, CS.Oak.OptionCharacter)
	if (slot_id == -1 or CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) == false or is_summon) then
		target = self:get_target()
	end

	message_system:Publish(CS.Oak.MonsterNoticeEvent.Create(self.current_boss, target, CS.Oak.MonsterNoticeLevel.Battle))

	--협동 원정대 보스 기믹용 임시 이벤트
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.current_boss, {
		'enhance_auto_generate'
	}))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(self.current_boss, {
		'generate_storm_curtain'
	}))
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
		character_util.set_direction(self.current_boss, 'down')
	end

	character_util.set_anim(self.current_boss, { name = 'dead', loop = false })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead_2 })

	wait_for_sec(1.5)

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
