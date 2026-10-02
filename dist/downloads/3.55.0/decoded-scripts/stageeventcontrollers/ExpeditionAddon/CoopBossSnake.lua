local local_class = newclass("CoopBossSnake")

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

	self.fx_phase2_start_pool = unity_object_pool.GetOrCreate(params.fx_phase2_start)
	self.fx_phase2_screen_pool = unity_object_pool.GetOrCreate(params.fx_phase2_screen)
	self.fx_phase2_end_pool = unity_object_pool.GetOrCreate(params.fx_oni_phase2_end)
	self.fx_phase2_aura_pool = unity_object_pool.GetOrCreate(params.fx_phase2_aura)
	self.fx_phase2_camera_pool = unity_object_pool.GetOrCreate(params.fx_phase2_camera)

	-- 라이트 변경
	message_system:Publish(CS.Oak.ChangeTilemapVisualEvent.Create(params.visual_template))

	-- sfx
	self.sfx_dead = '02_bosssnake_portal_01'
	music_player:PreloadSfx(self.sfx_dead)

	self.sfx_appear = '02_bosssnake_scream_01'
	music_player:PreloadSfx(self.sfx_appear)

	self.sfx_appear_1 = '01_rustle_02'
	music_player:PreloadSfx(self.sfx_appear_1)

	self.sfx_dead_2 = '02_pan_boss_event_03'
	music_player:PreloadSfx(self.sfx_dead_2)

	self.snow_wind_sfx_name = params.fx_phase2_sfx
	self.snow_wind_sfx_volume = params.fx_phase2_sfx_volume
	music_player:PreloadSfx(self.snow_wind_sfx_name)

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

	self:set_boss_phase(1)
	character_util.set_anim(self.current_boss, { name = 'wake', loop = false })
end

function local_class:on_launch_routine()

	music_player_util.play_sfx({ sfx_name = self.sfx_appear_1, type_priority = 'event', player_priority = 'boss' })

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

	camera_util.move(self.current_boss.Bounds.center, 0.3)
	camera_util.shake(self.camera_magnitude1, 0.5)

	character_util.set_anim(self.current_boss, { name = 'dead', loop = false, next_anim = 'dead_loop'  })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead, type_priority = 'event', player_priority = 'boss' })

	wait_for_sec(1.3)

	character_util.set_direction(self.current_boss, 'down')

	music_player_util.change_stage_music_volume('field', 0.3)

	local phase_effect_pos = self.current_boss.Bounds.center
	local start_effect = self.fx_phase2_start_pool:Instantiate(phase_effect_pos)

	wait_for_sec(0.1)

	camera_util.resize_to(10, 0.1)

	wait_for_sec(1)

	self.fx_phase2_screen_pool:Instantiate(phase_effect_pos)
	camera_util.shake(self.camera_magnitude1, 2)

	wait_for_sec(0.1)

	camera_util.resize_to(7, 0.4)

	wait_for_sec(0.4)

	camera_util.resize_to(1, 0.4)

	--화면 페이드 아웃.
	screen_util.fade_out_async(0.5, unity_class.color.black)

	wait_for_sec(0.4)

	wait_for_sec(1)

	if is_unity_null(start_effect) then
		start_effect:Dispose()
		start_effect = nil
	end

	camera_util.resize_to(5, 0)

	self:set_boss_phase(self.phase_count + 1)

	self:set_character_pos_phase_2()

	-- 카메라 포지션 셋
	camera_util.move(self.current_boss.Bounds.center + unity_class.vector3.forward * 1.5, 0)

	-- 눈보라
	self.snow_fx = self.fx_phase2_camera_pool:Instantiate(stage_camera.LookAtPosition,
			unity_class.quaternion.identity, stage_camera.transform)

	-- 눈보라 sfx
	self.snow_sfx = music_player_util.play_sfx({sfx_name = self.snow_wind_sfx_name, fade_in_time = 4, loop = true,
												type_priority = 'loop', volume = self.snow_wind_sfx_volume})

	--화면 페이드 인.
	screen_util.fade_in_async(0.5, unity_class.color.black, 'linear')

	wait_for_sec(0.5)
	if self.is_coop_end then return	end

	character_util.set_anim(self.current_boss, { name = 'appear', loop = false})

	music_player_util.play_sfx({ sfx_name = self.sfx_appear, type_priority = 'event', player_priority = 'boss' })

	-- 줌 아웃
	camera_util.resize_to(10, 0.35)

	self.fx_phase2_end_pool:Instantiate(self.current_boss.Bounds.center + vector(-0.5, 1.3, 0))

	wait_for_sec(0.2)
	if self.is_coop_end then return	end

	camera_util.shake(0.8, 1)

	--- 모든 아군 넉백 연출
	local knock_back_routines = {}
	local model = CS.Oak.CoopClient.Instance.CoopModel
	for _, member in pairs(party_manager.UserParty) do
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, member)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) then
			table.insert(knock_back_routines, character_util.physics_knock_back_routine(member, vector(0, 0, -1), 25000, 0.05))
		end
	end

	--- 아군 넉백 연출이 끝날 때 까지 기다린다.
	wait_all(knock_back_routines)

	if self.is_coop_end then return	end

	self.aura_effect = self.fx_phase2_aura_pool:Instantiate(self.current_boss.Position)
	self.aura_effect.transform.parent = self.current_boss.transform
	character_util.remove_anim(self.current_boss)

	local my_char = CS.Oak.CoopClient.Instance.MyCharacter
	camera_util.move_async(my_char.Position, self.reset_duration, {end_target = my_char})
	camera_util.resize_to_default(self.reset_duration)

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
		character_util.set_direction(self.current_boss, 'down')
	end

	character_util.set_anim(self.current_boss, { name = 'dead', loop = false, next_anim = 'groggy_loop' })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead_2, type_priority = 'event', player_priority = 'boss' })

	if self.aura_effect ~= nil then
		self.aura_effect:Dispose()
		self.aura_effect = nil
	end

	wait_for_sec(0.9)

	self.dissolver:set_dissolve_material(self.current_boss)
	self.current_boss.SpineController:AddColor('dissolve', unity_class.color.black, 1, 0)

	local time_passed = 0
	while time_passed < 0.8 do
		time_passed = time_passed + unity_class.time.deltaTime
		self.dissolver:set_dissolve_progress(self.current_boss, time_passed / 0.8)
		coroutine.yield(nil)
	end

	wait_for_sec(1.5)

	message_system:Publish(CS.Oak.DyingEndEvent.Create(self.current_boss))
end

function local_class:on_fo_destroyed_event(e)
	if lua_helper.reference_equals(e.FieldObject, self.current_boss) then
		self.top_hp_bar:Hide()

		if self.phase_count < #self.boss_id_list then
			self:phase_change()
		elseif self.phase_count == #self.boss_id_list then

			if is_unity_null(self.aura_effect) then
				self.aura_effect:Dispose()
				self.aura_effect = nil
			end
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

	if self.snow_fx then
		self.snow_fx:Dispose()
	end
	self.snow_fx = nil
	self.snow_sfx = nil

	self.fx_phase2_start_pool = nil
	self.fx_phase2_screen_pool = nil
	self.fx_phase2_end_pool = nil
	self.fx_phase2_aura_pool = nil
	self.fx_phase2_camera_pool = nil

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
