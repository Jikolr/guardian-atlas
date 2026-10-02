local local_class = newclass("CoopBossYaksha")

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

	self.fx_saya_stone_smoke_pool = unity_object_pool.GetOrCreate(params.fx_saya_sealstone_smoke)
	self.fx_saya_stone_attack_pool = unity_object_pool.GetOrCreate(params.fx_saya_sealstone_attack)
	self.fx_phase2_start_pool = unity_object_pool.GetOrCreate(params.fx_oni_phase2_start)
	self.fx_phase2_end_pool = unity_object_pool.GetOrCreate(params.fx_oni_phase2_end)
	self.fx_oni_teleport = unity_object_pool.GetOrCreate(params.fx_oni_teleport)
	self.fx_chain = unity_object_pool.GetOrCreate('fx_oni_phase2_chain')
	self.fx_dissolve = unity_object_pool.GetOrCreate('fx_oni_phase2_dissolve')
	self.fx_chain_break = unity_object_pool.GetOrCreate('fx_oni_phase2_chain_break')
	self.fx_saya_sealstone_explosion = unity_object_pool.GetOrCreate('fx_saya_sealstone_explosion')

	self.marker_name = params.saya_marker_name
	self.marker_count = params.saya_marker_count
	self.saya_stone_height = params.saya_stone_height
	self.saya_stone_speed = params.saya_stone_drop_speed

	self.saya_stone_fo_list = {}
	for i = 1, params.saya_marker_count do
		local name = params.saya_stone_name .. i
		local stone = get_field_object(name)
		table.insert(self.saya_stone_fo_list, stone)
	end

	-- sfx
	self.sfx_appear_1 = '01_rustle_02'
	music_player:PreloadSfx(self.sfx_appear)

	self.sfx_dead = '01_trip_02'
	music_player:PreloadSfx(self.sfx_dead)

	self.sfx_dead2 = '02_die_hulk_01'
	music_player:PreloadSfx(self.sfx_dead2)

	self.sfx_dissolve = '01_event_ex_02'
	music_player:PreloadSfx(self.sfx_dissolve)

	self.sfx_saya_stone_down = '03_mech_stomp_01'
	music_player:PreloadSfx(self.sfx_saya_stone_down)

	self.sfx_saya_stone_down2 = '01_firefly_01'
	music_player:PreloadSfx(self.sfx_saya_stone_down2)

	self.sfx_saya_stone_expoision = '03_rock_break_05'
	music_player:PreloadSfx(self.sfx_saya_stone_expoision)

	self.sfx_saya_stone_expoision2 = '01_firefly_04'
	music_player:PreloadSfx(self.sfx_saya_stone_expoision2)

	self.sfx_dead_2 = '02_pan_boss_event_03'
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

	self:set_boss_phase(1)
	character_util.set_anim(self.current_boss, { name = 'wake', loop = false })
end

function local_class:on_launch_routine()

	music_player_util.play_sfx({ sfx_name = self.sfx_appear_1 })

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
		'activate_auto_generate'
	}))
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'generate_npc'
	}))

	--협동 원정대 보스 사야봉인석 기믹 시작
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'start_saya_stone_event'
	}))
end

function local_class:phase_change()
	coroutine_manager:StartCoroutine(stage.StageGameObject, util.cs_generator(self.phase_change_routine, self))
end

function local_class:phase_change_routine()
	--사야의 봉인석 모든 마커위치에 Y축 올려서 소환 후 떨어지도록
	--marker_name
	local saya_stone_list = {}
	for i = 1, self.marker_count do
		local name = self.marker_name .. i
		local marker = field:GetMarker(name)
		local start_pos = marker.position + vector(-0.5, 20, -0.5)
		local saya_fo = self.saya_stone_fo_list[i]
		table.insert(saya_stone_list,
				{
					is_actvie = true,
					saya_fo = saya_fo,
					start_pos = start_pos,
					current_pos = start_pos,
					dest_pos = marker.position + vector(-0.5, 0, -0.5)
				})
	end

	message_system:PublishSync(CS.Oak.CustomStageEvent.Create(nil, {
		'change_boss',
		'boss_phase_2'
	}))

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
	character_util.set_anim(self.current_boss, { name = 'groggy', loop = false, next_anim = 'groggy_loop'  })

	music_player_util.change_stage_music_volume('field', 0.3)

	music_player_util.play_sfx({ sfx_name = self.sfx_dead })
	music_player_util.play_sfx({ sfx_name = self.sfx_dead2 })

	wait_for_sec(1.0)

	camera_util.resize_to(self.camera_size, 1)
	self.fx_dissolve:Instantiate(self.current_boss.Bounds.center)

	music_player_util.play_sfx({ sfx_name = self.sfx_dissolve })

	self.dissolver:set_dissolve_material(self.current_boss)
	self.current_boss.SpineController:AddColor('dissolve', unity_class.color.black, 1, 0)

	local time_passed = 0
	while time_passed < 0.7 do
		if self.is_coop_end then return	end

		time_passed = time_passed + unity_class.time.deltaTime
		self.dissolver:set_dissolve_progress(self.current_boss, time_passed / 0.7)
		coroutine.yield(nil)
	end
	camera_util.move(field:GetMarker('boss_Spawn_2').position, 1)

	character_util.set_active_state(self.current_boss, 'disabled')
	character_util.remove_anim(self.current_boss)
	self.dissolver:remove_dissolve_material(self.current_boss)
	self.current_boss.SpineController:RemoveColor('dissolve', 0)

	self:set_boss_phase(self.phase_count + 1)

	character_util.set_anim(self.current_boss, { name = 'groggy_loop', loop = true  })
	self.fx_dissolve:Instantiate(self.current_boss.Bounds.center)
	self.dissolver:set_dissolve_material(self.current_boss)
	self.current_boss.SpineController:AddColor('dissolve', unity_class.color.black, 1, 0)
	self.dissolver:set_dissolve_progress(self.current_boss, 1)

	time_passed = 0

	while time_passed < 0.7 do
		if self.is_coop_end then return	end

		time_passed = time_passed + unity_class.time.deltaTime
		self.dissolver:set_dissolve_progress(self.current_boss, (0.7 - time_passed) / 0.7)
		coroutine.yield(nil)
	end

	wait_for_sec(0.5)
	if self.is_coop_end then return	end

	while true do
		if self.is_coop_end then return	end

		local run_count = 0
		for _,v in pairs(saya_stone_list) do
			if v.is_actvie then
				local move_pos = v.current_pos + unity_class.vector3.down * 100 * unity_class.time.deltaTime
				v.saya_fo.Position = move_pos
				v.current_pos = move_pos

				if v.current_pos.y < v.dest_pos.y then
					v.saya_fo.Position = v.dest_pos
					v.is_actvie = false
					object_pool_extensions.Instantiate(self.fx_saya_stone_smoke_pool, v.dest_pos + vector(0.5, 0, 0.5))
				else
					run_count = run_count + 1
				end
			end
		end

		if run_count == 0 then
			break
		end

		coroutine.yield(nil)
	end

	local chain =  self.fx_chain:Instantiate(self.current_boss.Position)
	camera_util.shake(0.5, 0.5)

	wait_for_sec(1.5)
	if self.is_coop_end then return	end
	--페이즈 전환 이펙트 생성
	local start_effect = object_pool_extensions.Instantiate(self.fx_phase2_start_pool, self.current_boss.Position)

	wait_for_sec(2)

	if self.is_coop_end then return	end

	self:set_character_pos_phase_2()
	character_util.set_anim(self.current_boss, { name = 'oni_wisp_cast', loop = false, next_anim = 'oni_wisp_cast_loop' })

	wait_for_sec(0.1)
	if self.is_coop_end then return	end

	chain:Dispose()
	start_effect:Dispose()
	start_effect = nil

	self.fx_chain_break:Instantiate(self.current_boss.Position)

	local end_effect = object_pool_extensions.Instantiate(self.fx_phase2_end_pool, self.current_boss.Position)
	self.dissolver:remove_dissolve_material(self.current_boss)
	self.current_boss.SpineController:RemoveColor('dissolve', 0)

	camera_util.shake(self.camera_magnitude, self.camera_duration)

	--사야봉인석 제거
	for _,v in pairs(saya_stone_list) do
		self.fx_saya_sealstone_explosion:Instantiate(v.saya_fo.Position + vector(0.5, 0, 0.5))
		v.saya_fo.Position = vector(999, 0, 999)
		--object_pool_extensions.Instantiate(self.fx_saya_stone_attack_pool, v.current_pos)
	end

	--- 모든 아군 넉백 연출
	local knock_back_routines = {}
	local model = CS.Oak.CoopClient.Instance.CoopModel
	for _, member in pairs(party_manager.UserParty) do
		local slot_id = CS.Oak.ClientCoopExtensions.GetSlotIdByICharacter(model, member)

		if slot_id ~= -1 and CS.Oak.CoopClient.Instance:IsAliveCoopPlayer(slot_id) then
			table.insert(knock_back_routines, character_util.physics_knock_back_routine(member, vector(0, 0, -1), 15000, 0.05))
		end
	end

	--- 아군 넉백 연출이 끝날 때 까지 기다린다.
	wait_all(knock_back_routines)

	character_util.set_anim(self.current_boss, { name = 'oni_firebounce_attack', loop = false })

	wait_for_sec(2)

	if self.is_coop_end then return	end

	end_effect:Dispose()
	end_effect = nil

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

	--협동 원정대 보스 곡옥장판 기믹 시작
	message_system:Publish(CS.Oak.CustomStageEvent.Create(boss, {
		'start_magatama_event'
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

	character_util.set_anim(self.current_boss, { name = 'groggy', loop = false, next_anim = 'groggy_loop' })
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
